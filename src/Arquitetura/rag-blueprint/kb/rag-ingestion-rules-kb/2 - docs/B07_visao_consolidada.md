---
id: RAG-B7
doc_type: architecture-doc
title: "Visão Consolidada — Evolução por Fase"
system: RAG Corporativo
module: Visão Consolidada
domain: Arquitetura
owner: fabio
team: arquitetura
status: in-review
confidentiality: internal
tags: [rag, blueprint, consolidado, evolucao, fases]
aliases: ["Visão Consolidada", "B07", "Evolução por Fase"]
source_format: txt
source_repo: banco-patria
source_path: Arquitetura/rag-blueprint/1 - draft/B07_visao_consolidada.txt
conversion_pipeline: manual-v1
conversion_quality: 100
converted_at: 2026-03-18
created_at: 2026-03-18
updated_at: 2026-03-18
---

# 📊 Visão Consolidada — Evolução por Fase

| | |
|---|---|
| **Série** | RAG Blueprint Series |
| **Documento** | B7 — Visão Consolidada |
| **Data** | 18/03/2026 |
| **Versão** | 1.2 |

## 🎯 Tabela Mestra — Todas as Capacidades por Fase

> [!info] Documento consolidador
> Este documento é uma **visão transversal** de todo o blueprint. Cada linha resume uma capacidade e como ela evolui da Fase 1 (MVP) à Fase 4 (GraphRAG). As referências detalhadas estão nos documentos individuais de cada bloco.

Esta tabela consolida a evolução de TODAS as capacidades do RAG corporativo, incluindo camadas de dados ([[B01_camada_bronze|B1]]-[[B03_camada_ouro|B3]]), fases de maturidade ([[B04_metadados_governanca|B4]]-[[B06_graphrag_maturidade|B6]]), API e consumo ([[B10_api_interface_acesso|B10]]), infraestrutura ([[B11_deployment_infraestrutura|B11]]), qualidade ([[B12_testes_validacao_slas|B12]]), operações ([[B13_operacoes|B13]]) e segurança ([[B14_seguranca_soberania_dados|B14]]).

### Dados ([[B01_camada_bronze|B1]]-[[B03_camada_ouro|B3]])

| Capacidade | Fase 1 — MVP | Fase 2 — Metadados | Fase 3 — KG | Fase 4 — GraphRAG |
|---|---|---|---|---|
| **Fontes** | Git .md + PDF + DOCX | Git .md + PDF + DOCX | + PDFs + Tickets + APIs | Todas prioritárias |
| **Camada Bronze** | Ativo (MD, PDF, DOCX) | Ativo (idem) | Ativo (1a e 2a onda) | Ativo (todas as ondas) |
| **Pipeline Bronze→Prata** | Operando (MD, PDF, DOCX) | Operando (idem + validação) | Operando (+ JSON, XLSX) | Operando (todos formatos) |
| **Enriquecimento** | Front matter | Front matter | + NER + Class. | + Resumos + Relac. |
| **Nós no Neo4j** | Doc, Chunk | Doc, Chunk | + System + Module + Owner + Team + Task + ADR + Gloss. | 9 nós (ver [[B05_knowledge_graph|B5]]) |
| **Relações** | PART_OF | PART_OF | 11 relações (ver [[B05_knowledge_graph|B5]]) | 11 relações (ver [[B05_knowledge_graph|B5]]) |

### Busca e Consumo ([[B04_metadados_governanca|B4]]-[[B06_graphrag_maturidade|B6]])

| Capacidade | Fase 1 — MVP | Fase 2 — Metadados | Fase 3 — KG | Fase 4 — GraphRAG |
|---|---|---|---|---|
| **Busca** | Vector simples | Vector + filtros | Vector + filtros + grafo | Hybrid (V+K+G) + rerank |
| **Retroalimentação** | — | — | — | Completa |
| **Agentes** | — | — | — | Por domínio |

### API e Interface ([[B10_api_interface_acesso|B10]])

| Capacidade | Fase 1 — MVP | Fase 2 — Metadados | Fase 3 — KG | Fase 4 — GraphRAG |
|---|---|---|---|---|
| **API REST** | /search /health | /search + filtros | + /ask + /feedback | + /admin + stats |
| **Autenticação** | API Key | API Key | JWT/IdP | JWT/IdP |
| **MCP Server** | — | — | Básico | Completo |
| **Chat UI** | — | — | — | Avaliar |
| **Citações** | chunk_id no JSON | + heading path | + link ao doc | + click no chat |

### Infraestrutura ([[B11_deployment_infraestrutura|B11]])

| Capacidade | Fase 1 — MVP | Fase 2 — Metadados | Fase 3 — KG | Fase 4 — GraphRAG |
|---|---|---|---|---|
| **Containers** | Neo4j + API + pipeline | idem | idem | + MCP server |
| **Orquestração** | Docker Compose | Docker Compose | Docker Compose | Avaliar K8s se escalar |
| **Triggers ingestão** | Manual + CLI | Manual + cron | + Webhook + cron | + Cron + events |
| **HTTPS** | Não (local) | Sim | Sim | Sim |
| **Secrets** | .env | .env | Vault | Vault |

### Qualidade ([[B12_testes_validacao_slas|B12]])

| Capacidade | Fase 1 — MVP | Fase 2 — Metadados | Fase 3 — KG | Fase 4 — GraphRAG |
|---|---|---|---|---|
| **Testes unitários** | Parsers + chunk | + valid. front matter | + NER + enriq. | Todos |
| **Testes integração** | Pipeline end-to-end | + filtros | + grafo + RBAC | + hybrid + rerank |
| **Golden set** | 20 perg. | 50 perg. + filtros | 100 perg. + grafo | 200+ + agents |
| **Testes de carga** | — | Básico | Médio | Completo |
| **SLAs** | Indicativos | Medidos | Publicados | Enforced |

### Operações ([[B13_operacoes|B13]])

| Capacidade | Fase 1 — MVP | Fase 2 — Metadados | Fase 3 — KG | Fase 4 — GraphRAG |
|---|---|---|---|---|
| **Backup Neo4j** | Manual | Cron diário | Cron diário | Cron + alertas |
| **Backup Git** | Remote (push) | Remote (push) | Remote (push) | Remote + mirror |
| **Error handling** | Log + skip | + retry backoff | + dead letter | + alertas automát. |
| **Re-indexação** | Manual (full) | Manual (full) | Blue/green | Blue/green |
| **Ciclo de vida** | Manual | Status no front matter | + detect. obsolesc. | + auto deprec. |
| **Glossário** | — | — | Manual + curador | + NER + auto |
| **Alertas** | Log | E-mail | Slack | Alerting formal |

### Segurança ([[B14_seguranca_soberania_dados|B14]])

| Capacidade | Fase 1 — MVP | Fase 2 — Metadados | Fase 3 — KG | Fase 4 — GraphRAG |
|---|---|---|---|---|
| **Governança de acesso** | Campo conf. (sem enforce) | Filtro pré-retr. | RBAC + ABAC + audit. básica | RBAC + ABAC + multi-tenant |
| **Criptografia** | HTTPS (se exp.) | + TLS Bolt | + FDE disco | + campo (se nec.) |
| **Auditoria** | Logs básicos | + acessos | + anom. detect. | + dashb. segurança |
| **Anti-injection** | — | Sanitiz. input | + detect. padrões | + testes validados |
| **LGPD** | — | — | Anonimiz. pipeline | + DPIA completo |
| **Resposta a incidentes** | — | — | Proced. definido | Testado e validado |

### Governança do Projeto ([[B15_governanca_capacidade_rollback|B15]])

| Capacidade | Fase 1 — MVP | Fase 2 — Metadados | Fase 3 — KG | Fase 4 — GraphRAG |
|---|---|---|---|---|
| **Papéis (RACI)** | Informal | Definido | Publicado | Revisado |
| **Rollback conhecimento** | Manual (full) | Por doc (granul.) | Automát. + audit | Automát. + audit |
| **Capacity plan** | Sizing inicial | + monitor uso real | + projeç. crescim. | + auto scaling |

## 📌 Como Ler Esta Tabela

> [!tip] Convenção de leitura
> Cada linha mostra uma capacidade e como ela evolui da Fase 1 à 4. O símbolo **"+"** indica incremento sobre a fase anterior. O símbolo **"—"** indica que a capacidade não existe nessa fase.

Referências por bloco:

- 🔸 **Dados:** [[B01_camada_bronze|B1]] (Bronze), [[B02_camada_prata|B2]] (Prata), [[B03_camada_ouro|B3]] (Ouro)
- 🔸 **Busca/Consumo:** [[B04_metadados_governanca|B4]] (Fase 2), [[B05_knowledge_graph|B5]] (Fase 3), [[B06_graphrag_maturidade|B6]] (Fase 4)
- 🔸 **API:** [[B10_api_interface_acesso|B10]]
- 🔸 **Infra:** [[B11_deployment_infraestrutura|B11]]
- 🔸 **Qualidade:** [[B12_testes_validacao_slas|B12]]
- 🔸 **Operações:** [[B13_operacoes|B13]]
- 🔸 **Segurança:** [[B14_seguranca_soberania_dados|B14]]
- 🔸 **Governança:** [[B15_governanca_capacidade_rollback|B15]]

---

## Documentos relacionados

### Depende de
- (nenhum — documento consolidador)

### Habilita
- (nenhum — documento consolidador)

### Relacionados
- [[B01_camada_bronze]] — ingestão e fontes
- [[B02_camada_prata]] — parsing e chunking
- [[B03_camada_ouro]] — embeddings e busca vetorial
- [[B04_metadados_governanca]] — front matter e filtros
- [[B05_knowledge_graph]] — grafo e relações
- [[B06_graphrag_maturidade]] — hybrid search e agentes
- [[B10_api_interface_acesso]] — endpoints e consumo
- [[B11_deployment_infraestrutura]] — containers e deploy
- [[B12_testes_validacao_slas]] — qualidade e golden set
- [[B13_operacoes]] — backup, alertas, curadoria
- [[B14_seguranca_soberania_dados]] — RBAC, ABAC, LGPD
- [[B15_governanca_capacidade_rollback]] — RACI, rollback, capacity
