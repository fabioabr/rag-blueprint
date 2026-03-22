---
id: RAG-B11
doc_type: architecture-doc
title: "Deployment e Infraestrutura de Execução — Como os Componentes Rodam na Prática"
system: RAG Corporativo
module: Deployment
domain: Arquitetura
owner: fabio
team: arquitetura
status: in-review
confidentiality: internal
tags: [rag, blueprint, deployment, docker, infraestrutura, triggers]
aliases: ["Deployment", "Infraestrutura", "B11"]
source_format: txt
source_repo: banco-patria
source_path: Arquitetura/rag-blueprint/1 - draft/B11_deployment_infraestrutura.txt
conversion_pipeline: manual-v1
conversion_quality: 100
converted_at: 2026-03-18
created_at: 2026-03-18
updated_at: 2026-03-18
---

# Deployment e Infraestrutura de Execução

**Como os Componentes Rodam na Prática**

| | |
|---|---|
| **Série** | RAG Blueprint Series |
| **Documento** | B11 — Deployment e Infraestrutura |
| **Data** | 18/03/2026 |
| **Versão** | 1.0 |
| **Base** | B3 (Pipeline Ouro), B8 (Pendências 3, 4, 10), B10 (API) |

---

## 🎯 Objetivo

Definir como os componentes do RAG são empacotados, deployados e executados. Cobrir: containerização, orquestração de pipelines, triggers de ingestão e topologia de rede.

> [!info] Contexto
> Este documento detalha a infraestrutura de execução dos pipelines definidos em [[B01_camada_bronze|B01]], [[B02_camada_prata|B02]] e [[B03_camada_ouro|B03]], e da API especificada em [[B10_api_interface_acesso|B10]].

#deployment #docker #infraestrutura

---

## 📌 11.1 — Componentes e Responsabilidades

O sistema é composto por 4 componentes principais:

### Componente 1 — Pipeline Bronze→Prata

- 🔸 Job batch que converte fontes originais em .md padronizado
- 🔸 Roda sob demanda ou agendado
- 🔸 Lê: repo Bronze (Git)
- 🔸 Escreve: repo Prata (Git)
- 🔸 Dependências: parsers (PDF, DOCX, etc.), LLM (opcional)

### Componente 2 — Pipeline Prata→Ouro

- 🔸 Job batch que ingere .md no Neo4j
- 🔸 Roda sob demanda, agendado ou por webhook (novo commit)
- 🔸 Lê: repo Prata (Git)
- 🔸 Escreve: Neo4j
- 🔸 Dependências: API de embedding, Neo4j

### Componente 3 — RAG API

- 🔸 Serviço HTTP (API de retrieval) — sempre rodando
- 🔸 Recebe queries, executa retrieval, retorna resultados
- 🔸 Lê: Neo4j
- 🔸 Chama: API de embedding (para query), LLM (para /ask)

### Componente 4 — Neo4j

- 🔸 Banco de dados (grafo + vetor)
- 🔸 Sempre rodando
- 🔸 Acessado pelos componentes 2 e 3
- 🔸 Conforme [[B08_pendencias#✅ Pendencia 3 — Infraestrutura Neo4j|B08 Pendência 3]]: Aura (cloud) ou Docker (on-prem)

---

## 📌 11.2 — Containerização (Docker)

Todos os componentes (exceto Neo4j Aura) rodam em containers Docker.

Containers por PAPEL (runtime depende da stack escolhida):

### pipeline-bronze — Pipeline Bronze→Prata

- **Papel:** converte fontes originais em .md padronizado
- **Deps:** parsers (PDF, DOCX, XLSX), acesso Git
- **Execução:** entrypoint CLI (job batch)
- **Imagem base conforme stack:**
  - Python: `python:3.12-slim` + pdfplumber, python-docx, gitpython
  - .NET: `mcr.microsoft.com/dotnet/aspnet:9.0` + libs equivalentes
  - Node: `node:22-slim` + pdf-parse, docx, etc.

### pipeline-ouro — Pipeline Prata→Ouro

- **Papel:** ingere .md no Neo4j (chunking, embedding, upsert)
- **Deps:** driver Neo4j, API de embedding (se cloud) ou modelo local
- **Execução:** entrypoint CLI (job batch)
- **Imagem base conforme stack:**
  - Python: `python:3.12-slim` + neo4j-graphrag-python
  - .NET: `mcr.microsoft.com/dotnet/aspnet:9.0` + Neo4j.Driver
  - Node: `node:22-slim` + neo4j-driver

### rag-api — API de retrieval

- **Papel:** serviço HTTP sempre rodando, recebe queries e retorna resultados
- **Deps:** driver Neo4j, API de embedding, API de LLM
- **Execução:** servidor HTTP na porta 8000
- **Imagem base conforme stack:**
  - Python: `python:3.12-slim` + fastapi + uvicorn
  - .NET: `mcr.microsoft.com/dotnet/aspnet:9.0` (Kestrel nativo)
  - Node: `node:22-slim` + express ou fastify

### neo4j (oficial) — Neo4j Community ou Enterprise

- **Imagem:** `neo4j:5.26-community` (ou versão compatível com vector index)
- **Volumes:** /data, /logs, /backups

---

## 📌 11.3 — Docker Compose (Ambiente Local / On-Prem)

Topologia para ambiente self-hosted:

```yaml
# docker-compose.yml

services:

  neo4j:
    image: neo4j:5.26-community
    ports: 7474 (browser), 7687 (bolt)
    volumes: neo4j-data, neo4j-logs, neo4j-backups
    env: NEO4J_AUTH, NEO4J_PLUGINS=["apoc"]
    restart: unless-stopped

  rag-api:
    image: <imagem conforme stack escolhida>
    ports: 8000
    env: NEO4J_URI, EMBEDDING_API_KEY, LLM_API_KEY
    depends_on: neo4j
    restart: unless-stopped

  pipeline-ouro:      # roda sob demanda, não always-on
    image: <imagem conforme stack escolhida>
    profiles: ["jobs"]
    env: NEO4J_URI, EMBEDDING_API_KEY, SILVER_REPO_PATH
    volumes: repos locais montados read-only

  pipeline-bronze:    # roda sob demanda, não always-on
    image: <imagem conforme stack escolhida>
    profiles: ["jobs"]
    env: BRONZE_REPO_PATH, SILVER_REPO_PATH, LLM_API_KEY
    volumes: repos locais montados

volumes:
  neo4j-data:
  neo4j-logs:
  neo4j-backups:
```

**Serviços always-on:** neo4j, rag-api

**Jobs sob demanda:** pipeline-bronze, pipeline-ouro

Executar via: `docker compose --profile jobs run pipeline-ouro`

---

## 📌 11.4 — Triggers de Ingestão

Quando os pipelines devem rodar:

> [!tip] Idempotência
> Todos os triggers são seguros para re-execução — os pipelines comparam checksum/hash antes de processar.

| Trigger | Pipeline | Como |
|---------|----------|------|
| Novo commit na prata | Prata→Ouro | Webhook Git → API `POST /v1/admin/ingest` |
| Novo arquivo no bronze | Bronze→Prata | Webhook Git ou cron (verifica a cada 1h) |
| Agendamento diário (full sync) | Ambos | Cron job: 02:00 UTC — Garante consistência |
| Manual | Ambos | CLI ou endpoint admin — Para testes / forçar |

### Lógica de idempotência

- 🔸 Ambos os pipelines comparam checksum/hash antes de processar
- 🔸 Executar o mesmo pipeline 2x sobre os mesmos dados = noop
- 🔸 Seguro rodar trigger + cron sem duplicar trabalho

---

## 📌 11.5 — Variáveis de Ambiente

Configuração externalizada via variáveis de ambiente:

| Variável | Descrição |
|----------|-----------|
| `NEO4J_URI` | bolt://neo4j:7687 ou bolt+s://aura... |
| `NEO4J_USER` | neo4j |
| `NEO4J_PASSWORD` | (secret) |
| `EMBEDDING_PROVIDER` | "openai" ou "local" |
| `EMBEDDING_MODEL` | "text-embedding-3-small" ou "bge-m3" |
| `EMBEDDING_API_KEY` | (secret, se cloud) |
| `LLM_PROVIDER` | "anthropic" ou "local" |
| `LLM_MODEL` | "claude-sonnet-4-5-20250514" etc. |
| `LLM_API_KEY` | (secret, se cloud) |
| `SILVER_REPO_PATH` | /repos/banco-xpto-prata |
| `BRONZE_REPO_PATH` | /repos/banco-xpto-bronze |
| `LOG_LEVEL` | INFO \| DEBUG \| WARNING |
| `API_PORT` | 8000 |
| `CHUNK_MIN_TOKENS` | 300 |
| `CHUNK_MAX_TOKENS` | 800 |
| `VECTOR_INDEX_NAME` | chunk_embedding_index |
| `QUALITY_THRESHOLD` | 80 (conversion_quality mínimo) |

### Secrets

- 🔸 Nunca em código ou docker-compose.yml
- 🔸 Via .env (dev) ou secret manager (prod)
- 🔸 Docker secrets ou Vault para ambientes corporativos

> [!warning] Segurança de secrets
> Secrets nunca devem ser commitados em repositórios. Ver [[B14_seguranca_soberania_dados]] para políticas completas de gestão de segredos.

---

## 📌 11.6 — Topologia de Rede

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│  [Internet / Rede Corporativa]                                      │
│          │                                                          │
│          ▼                                                          │
│  ┌──────────────┐                                                   │
│  │  rag-api     │ ← porta 8000 (exposta)                           │
│  │  (HTTP API)  │                                                   │
│  └──────┬───────┘                                                   │
│         │                                                           │
│         ▼                                                           │
│  ┌──────────────┐     ┌──────────────────┐                         │
│  │  Neo4j       │     │  APIs Externas   │                         │
│  │  (bolt:7687) │     │  (Embedding, LLM)│                         │
│  │  (http:7474) │     │  (se cloud)      │                         │
│  └──────────────┘     └──────────────────┘                         │
│   ↑ rede interna        ↑ rede externa                             │
│   (não exposto)         (HTTPS)                                     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Regras de rede

- 🔸 Neo4j: acessível apenas pela rede interna Docker (não expor 7687)
- 🔸 Neo4j Browser (7474): acesso restrito à equipe de dev/ops
- 🔸 rag-api: única porta exposta para consumidores
- 🔸 Pipelines: acesso à rede interna (Neo4j) + externa (APIs)
- 🔸 HTTPS obrigatório em produção (reverse proxy: nginx ou traefik)

> [!warning] Rede em produção
> Neo4j nunca deve ser exposto externamente. Apenas a `rag-api` é ponto de entrada para consumidores. Ver [[B14_seguranca_soberania_dados]] para regras de network isolation.

---

## 📌 11.7 — Evolução por Fase

| Capacidade | Fase 1 | Fase 2 | Fase 3 | Fase 4 |
|------------|--------|--------|--------|--------|
| **Containers** | Neo4j + API + pipeline | idem | idem | + MCP server |
| **Orquestração** | Docker Compose | Docker Compose | Docker Compose | Avaliar K8s se escalar |
| **Triggers** | Manual + CLI | Manual + cron | + Webhook + cron | + Cron + events |
| **HTTPS** | Não (local) | Sim (nginx) | Sim (nginx) | Sim (nginx) |
| **Secrets** | .env | .env | Vault | Vault |

> [!abstract] Evolução progressiva
> A infraestrutura cresce com as fases do [[B16_roadmap_implementacao|roadmap]]. Decisões sobre stack ([[B08_pendencias#✅ Pendencia 4 — Stack Tecnologica|P4]]) e landing zone ([[B08_pendencias#✅ Pendencia 10 — Landing Zone|P10]]) impactam diretamente este documento.

> [!info] Segurança
> Antes de implementar, consultar checklist de segurança da fase correspondente em [[B14_seguranca_soberania_dados]] (hardening de containers, TLS, gestão de secrets, network isolation).

---

## Documentos relacionados

### Depende de
- [[B01_camada_bronze]] — fontes do pipeline Bronze→Prata
- [[B02_camada_prata]] — .md normalizados consumidos pelo pipeline Prata→Ouro
- [[B03_camada_ouro]] — pipeline de ingestão no Neo4j
- [[B10_api_interface_acesso]] — serviço HTTP que é deployado como container

### Habilita
- [[B12_testes_validacao_slas]] — ambiente de execução necessário para testes end-to-end
- [[B13_operacoes]] — infraestrutura operacional (logs, backups, monitoramento)

### Relacionados
- [[B08_pendencias]] — P3 (infra Neo4j), P4 (stack tecnológica), P10 (landing zone)
- [[B14_seguranca_soberania_dados]] — HTTPS, secrets, network isolation
- [[B15_governanca_capacidade_rollback]] — rollback, capacidade, DR
- [[B16_roadmap_implementacao]] — sequenciamento de deploy por fase
