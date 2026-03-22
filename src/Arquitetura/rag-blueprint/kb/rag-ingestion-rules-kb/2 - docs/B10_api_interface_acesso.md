---
id: RAG-B10
doc_type: architecture-doc
title: "API e Interface de Acesso — Como Consumidores Interagem com o RAG"
system: RAG Corporativo
module: API e Interface
domain: Arquitetura
owner: fabio
team: arquitetura
status: in-review
confidentiality: internal
tags: [rag, blueprint, api, rest, mcp, autenticacao, citacoes]
aliases: ["API", "Interface de Acesso", "B10"]
source_format: txt
source_repo: banco-patria
source_path: Arquitetura/rag-blueprint/1 - draft/B10_api_interface_acesso.txt
conversion_pipeline: manual-v1
conversion_quality: 100
converted_at: 2026-03-18
created_at: 2026-03-18
updated_at: 2026-03-18
---

# API e Interface de Acesso

**Como Consumidores Interagem com o RAG**

| | |
|---|---|
| **Série** | RAG Blueprint Series |
| **Documento** | B10 — API e Interface de Acesso |
| **Data** | 18/03/2026 |
| **Versão** | 1.0 |
| **Base** | B3 (Camada Ouro), B5 (Knowledge Graph), B6 (GraphRAG) |

---

## 🎯 Objetivo

Definir como agentes, aplicações e usuários acessam o RAG corporativo. O pipeline de ingestão ([[B01_camada_bronze|B1]]→[[B02_camada_prata|B2]]→[[B03_camada_ouro|B3]]) produz o conhecimento; este documento define como esse conhecimento é consumido.

**Princípios:**

- 🔸 Uma API, múltiplos consumidores
- 🔸 Autenticação obrigatória em toda chamada
- 🔸 Filtros de acesso aplicados antes da busca — ver [[B06_graphrag_maturidade|B06 — GraphRAG]]
- 🔸 Respostas sempre com citação de fonte

> [!info] Contexto na série
> Este documento define a **camada de consumo** do RAG. Depende de [[B03_camada_ouro]], [[B05_knowledge_graph]] e [[B06_graphrag_maturidade]], e habilita [[B11_deployment_infraestrutura]] e [[B12_testes_validacao_slas]].

#api #interface-acesso

---

## 📌 10.1 — Arquitetura de Acesso

```
┌──────────────────────────────────────────────────────────────────────┐
│                        CONSUMIDORES                                  │
│                                                                      │
│  🤖 Agentes IA    📱 Chat UI    🔧 CLI    🔗 MCP Server    📊 API  │
│     (por domínio)   (web app)   (devs)    (Claude Code)   (sistemas)│
└──────────────────────┬───────────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    API GATEWAY / RAG API                              │
│                                                                      │
│  🔸 Autenticação (JWT / API Key)                                     │
│  🔸 Rate limiting                                                    │
│  🔸 Resolução de permissões (RBAC → níveis de confidentiality)      │
│  🔸 Logging de requisições                                           │
└──────────────────────┬───────────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    RETRIEVAL ENGINE                                   │
│                                                                      │
│  🔸 Pré-processamento da query                                      │
│  🔸 Filtros pré-retrieval (confidentiality, sistema, módulo)        │
│  🔸 Busca vetorial / keyword / grafo (conforme fase)                │
│  🔸 Reranking                                                        │
│  🔸 Construção de contexto                                           │
└──────────────────────┬───────────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    LLM (opcional)                                     │
│                                                                      │
│  🔸 Geração de resposta com citações                                 │
│  🔸 Ou retorno direto de chunks (modo "retrieve-only")              │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 📌 10.2 — API REST

A API REST é a camada de contrato entre o RAG e seus consumidores. Deve expor endpoints padronizados (OpenAPI/Swagger), suportar chamadas assíncronas a Neo4j e ao LLM, e garantir tipagem forte nos contratos de request/response.

A escolha de framework/stack é uma decisão de implementação — qualquer opção que atenda aos requisitos acima é válida:

### Opções de Stack para a API

| Stack | Características |
|-------|----------------|
| 🅰️ **Python + FastAPI** | Async nativo — bom para chamadas a Neo4j e LLM. Documentação automática (OpenAPI/Swagger). Tipagem com Pydantic — contratos claros. Mesmo ecossistema do pipeline de ingestão (se Python). |
| 🅱️ **.NET Core + ASP.NET** | Enterprise-grade, forte em ambientes corporativos. Tipagem estática robusta — contratos bem definidos. Neo4j .NET Driver maduro e bem mantido. Bom suporte a async/await e alta performance (Kestrel). |
| 🅲 **Node.js + Express/Fastify** | Async nativo (event loop) — ideal para I/O-bound. Prototipagem rápida, ecossistema leve. Neo4j JavaScript Driver oficial disponível. Boa opção para MVP com equipe familiarizada. |

> [!warning] Decisão pendente
> A decisão de stack será tomada na implementação — ver [[B08_pendencias#✅ Pendencia 4 — Stack Tecnologica|P4 — Stack Tecnológica]]. Os contratos de endpoint abaixo são agnósticos de tecnologia.

### Endpoints principais

#### POST /v1/search

Busca semântica com filtros. Retorna chunks rankeados.

**Request:**

```json
{
  "query": "Como funciona o módulo de cobrança?",
  "filters": {
    "system": "Sistema Exemplo",
    "module": null,
    "doc_type": null
  },
  "top_k": 10,
  "mode": "hybrid"    // "vector" | "keyword" | "hybrid"
}
```

**Response:**

```json
{
  "results": [
    {
      "chunk_id": "DOC-000123_003",
      "content": "O módulo de cobrança...",
      "score": 0.87,
      "heading_path": "Cobrança > Regras de Negócio",
      "document": {
        "document_id": "DOC-000123",
        "title": "Módulo de Cobrança",
        "system": "Sistema Exemplo",
        "path": "financeiro/cobranca.md"
      }
    }
  ],
  "query_id": "q-abc123",
  "total_results": 10,
  "search_mode": "hybrid",
  "latency_ms": 142
}
```

#### POST /v1/ask

Busca + geração de resposta via LLM. Retorna resposta formatada com citações de fontes.

**Request:**

```json
{
  "question": "Como funciona o módulo de cobrança?",
  "agent": "arquitetura",
  "filters": { "..." : "..." },
  "top_k": 10,
  "include_sources": true
}
```

**Response:**

```json
{
  "answer": "O módulo de cobrança do Sistema Exemplo...",
  "sources": [
    {
      "document_id": "DOC-000123",
      "title": "Módulo de Cobrança",
      "path": "financeiro/cobranca.md",
      "chunk_heading": "Regras de Negócio"
    }
  ],
  "query_id": "q-abc456",
  "agent": "arquitetura",
  "model": "claude-sonnet-4-5-20250514",
  "latency_ms": 1850
}
```

#### POST /v1/feedback

Feedback do usuário sobre uma resposta (retroalimentação — [[B06_graphrag_maturidade|B06]]).

**Request:**

```json
{
  "query_id": "q-abc456",
  "rating": "positive",
  "comment": "Resposta precisa, mas faltou mencionar..."
}
```

#### GET /v1/health

Health check da API, Neo4j e serviços dependentes.

**Response:**

```json
{
  "status": "healthy",
  "neo4j": "connected",
  "documents_count": 342,
  "chunks_count": 4821,
  "last_ingestion": "2026-03-18T14:30:00Z"
}
```

> [!info] SLAs de latência
> Os valores de `latency_ms` nos exemplos acima são ilustrativos. Para SLAs formais por endpoint, ver [[B12_testes_validacao_slas#🔹 SLAs por componente|B12, §12.5 — SLAs]].

### Endpoints administrativos (autenticação elevada)

| Endpoint | Descrição |
|----------|-----------|
| `POST /v1/admin/ingest` | Dispara ingestão manual |
| `GET /v1/admin/stats` | Métricas da base |
| `GET /v1/admin/audit` | Log de acessos |

---

## 📌 10.3 — MCP Server (Claude Code / Agentes)

Para integração com Claude Code e agentes MCP-compatíveis:

- 🔸 Expor as mesmas capacidades da API REST como ferramentas MCP:
  - **search** — busca semântica com filtros
  - **ask** — pergunta com resposta gerada
  - **feedback** — registrar avaliação
- 🔸 O MCP Server é um wrapper leve sobre a mesma Retrieval Engine
- 🔸 Protocolo: stdio ou SSE (conforme ambiente)
- 🔸 Pode ser implementado em qualquer stack escolhido para a API (§10.2)

**SDKs MCP disponíveis:**

- Python — SDK oficial MCP para Python (modelcontextprotocol)
- C# / .NET — SDK oficial MCP para C# (Microsoft.Extensions.AI)
- TypeScript — SDK oficial MCP para TypeScript (modelcontextprotocol)

**Benefício:** Claude Code pode consultar a base de conhecimento diretamente durante sessões de desenvolvimento, sem sair do terminal.

---

## 📌 10.4 — Interface de Chat (Futura)

Para usuários não-técnicos, uma interface web de chat:

- 🔸 Frontend leve (React ou similar)
- 🔸 Consome a API /v1/ask
- 🔸 Exibe citações de fonte clicáveis
- 🔸 Permite selecionar agente/domínio
- 🔸 Histórico de conversas (local ou persistido)

> [!tip] Prioridade
> Não é prioridade para o MVP — API + CLI são suficientes no início. Avaliar na Fase 3-4 quando houver usuários não-técnicos consumindo. Ver [[B16_roadmap_implementacao|roadmap]] para sequenciamento.

---

## 📌 10.5 — Autenticação e Autorização

### Opção A — API Key (MVP)

- 🔸 Cada consumidor (agente, app, usuário) recebe uma API Key
- 🔸 A key está associada a um perfil de acesso (role)
- 🔸 Header: `Authorization: Bearer <api-key>`
- 🔸 Simples de implementar, suficiente para Fases 1-2

### Opção B — JWT via IdP (Fase 3+)

- 🔸 Integração com Identity Provider corporativo (AD, Okta, etc.)
- 🔸 JWT contém claims: user_id, roles, tenant_id
- 🔸 Roles mapeiam para níveis de confidentiality — ver [[B05_knowledge_graph|B5, §3.5]]
- 🔸 Token refresh automático

### Mapeamento de roles para acesso (reutiliza RBAC do B5)

| Role | Acesso a confidentiality |
|------|--------------------------|
| `analyst` | public, internal |
| `manager` | public, internal, restricted |
| `director` | public, internal, restricted, confidential |
| `agent-<x>` | nível configurável por agente |

---

## 📌 10.6 — Formato de Citações

Toda resposta gerada pelo LLM DEVE incluir citações rastreáveis.

**Formato padrão:**

> "O módulo de cobrança utiliza remessa bancária CNAB 240 para processamento de boletos [DOC-000123, §Regras de Negócio]."

**Estrutura da citação:**

- 🔸 `[document_id, §heading_path]` — identificação do chunk fonte
- 🔸 No response JSON: array "sources" com metadados completos
- 🔸 Na interface de chat: link clicável para o documento original

**Regras para o LLM:**

- 🔸 Toda afirmação factual deve ter citação
- 🔸 Se não há chunk que suporte a afirmação → dizer "não encontrei"
- 🔸 Nunca inventar informação além do contexto fornecido

---

## 📌 10.7 — Evolução por Fase

| Capacidade | Fase 1 | Fase 2 | Fase 3 | Fase 4 |
|------------|--------|--------|--------|--------|
| **API REST** | /search, /health | + filtros | + /ask, + /feedback | + /admin, + stats |
| **Autenticação** | API Key | API Key | JWT/IdP | JWT/IdP |
| **MCP Server** | — | — | Básico | Completo |
| **Chat UI** | — | — | — | Avaliar |
| **Citações** | chunk_id no JSON | + heading path | + link ao doc | + click no chat |
| **Rate limiting** | Básico | Por role | Por role + agente | Por role + tenant |

> [!info] Segurança
> Antes de implementar, consultar checklist de segurança da fase correspondente em [[B14_seguranca_soberania_dados]] (autenticação de API, filtros pré-retrieval, proteção contra prompt injection).

---

## Documentos relacionados

### Depende de
- [[B03_camada_ouro]] — modelo de dados e busca vetorial base
- [[B05_knowledge_graph]] — grafo e relações para expansão de contexto
- [[B06_graphrag_maturidade]] — retrieval híbrido, reranking e agentes

### Habilita
- [[B11_deployment_infraestrutura]] — infraestrutura para expor a API
- [[B12_testes_validacao_slas]] — golden set e SLAs dos endpoints

### Relacionados
- [[B08_pendencias]] — P4 (stack tecnológica) e P6 (LLM para geração)
- [[B15_governanca_capacidade_rollback]] — governança, capacidade e auditoria
