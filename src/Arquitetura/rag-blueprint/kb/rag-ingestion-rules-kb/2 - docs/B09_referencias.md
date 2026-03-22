---
id: RAG-B09
doc_type: architecture-doc
title: "Referências e Histórico de Versões"
system: RAG Corporativo
module: Referências
domain: Arquitetura
owner: fabio
team: arquitetura
status: in-review
confidentiality: internal
tags: [rag, blueprint, referencias, historico, versoes]
aliases: ["Referências", "B09", "Histórico de Versões"]
source_format: txt
source_repo: banco-patria
source_path: Arquitetura/rag-blueprint/1 - draft/B09_referencias.txt
conversion_pipeline: manual-v1
conversion_quality: 100
converted_at: 2026-03-18
created_at: 2026-03-18
updated_at: 2026-03-18
---

# Referências e Histórico de Versões

| | |
|---|---|
| **Série** | RAG Blueprint Series |
| **Documento** | B9 — Referências |
| **Data** | 17/03/2026 |
| **Versão** | 1.1 |

---

## 📚 Documentos Fonte

- 🔸 B0.1 — Corporate RAG Blueprint (v4.0, 13/03/2026)
- 🔸 B0.2 — Mapa da Arquitetura de Conhecimento (v2.1, 13/03/2026)
- 🔸 B1.1 — Fontes de Conhecimento (v1.0, 13/03/2026)
- 🔸 blueprint_base_conhecimento_neo4j (17/03/2026)
- 🔸 ADR-001 — Modelo Bronze/Prata/Ouro (17/03/2026)

---

## 🔗 Referências Técnicas

### Neo4j

- 🔸 **Neo4j Vector Indexes** — neo4j.com/docs/cypher-manual/current/indexes/semantic-indexes/vector-indexes/
- 🔸 **Neo4j GraphRAG for Python** — neo4j.com/docs/neo4j-graphrag-python/current/
- 🔸 **Neo4j Vector Search with Filters** — neo4j.com/blog/genai/vector-search-with-filters-in-neo4j-v2026-01-preview/
- 🔸 **Neo4j Python Driver** — neo4j.com/docs/python-manual/current/
- 🔸 **Neo4j Cypher Manual** — neo4j.com/docs/cypher-manual/current/

### Modelos de Embedding (Pendência 1)

- 🔸 **OpenAI Embeddings** — platform.openai.com/docs/guides/embeddings
- 🔸 **BGE-M3 (BAAI)** — huggingface.co/BAAI/bge-m3
- 🔸 **Sentence Transformers** — sbert.net/docs/
- 🔸 **MTEB Benchmark** — huggingface.co/spaces/mteb/leaderboard

### Reranking (Pendência 8)

- 🔸 **Cohere Rerank** — docs.cohere.com/docs/rerank
- 🔸 **BGE-Reranker-v2-m3** — huggingface.co/BAAI/bge-reranker-v2-m3

### LLM (Pendência 6)

- 🔸 **Claude API (Anthropic)** — docs.anthropic.com/
- 🔸 **Ollama** — ollama.com/library (para LLMs locais)

### Infraestrutura

- 🔸 **Docker Compose** — docs.docker.com/compose/
- 🔸 **MinIO** — min.io/docs/minio/linux/index.html

### Parsing e Chunking

- 🔸 **Unstructured.io** — docs.unstructured.io/ (parser multi-formato)
- 🔸 **python-frontmatter** — pypi.org/project/python-frontmatter/

### Retrieval e Fusão

- 🔸 **Reciprocal Rank Fusion (RRF)** — plg.uwaterloo.ca/~gvcormac/cormacksigir09-rrf.pdf

---

## 📋 Histórico de Versões

### v1.0 — 17/03/2026

Blueprint detalhado fase a fase, consolidando 4 documentos de draft. Inclui modelo de dados, pipeline detalhado por etapa, busca evolutiva, governança incremental e 13 pendências categorizadas por prazo.

### v1.1 — 18/03/2026

Incorporação do modelo Bronze/Prata/Ouro (ADR-001). Todo documento (inclusive .md) passa pela camada bronze. Separação do documento monolítico em série de 10 documentos (B0-B9). Adição de formatos suportados completos (MD, PDF, DOCX, XLSX, EML, transcrições, JSON/tickets). Tabela consolidada atualizada com camada Bronze desde a Fase 1.

### v1.2 — 18/03/2026

Expansão da série com 4 novos documentos (B10-B13):

- **B10** — API e Interface de Acesso (endpoints, autenticação, citações, MCP)
- **B11** — Deployment e Infraestrutura (Docker, triggers, variáveis, topologia)
- **B12** — Testes, Validação e SLAs (unitários, integração, golden set, metas)
- **B13** — Operações (backup/DR, error handling, re-indexação, ciclo de vida, glossário, alertas)
- **B14** — Segurança e Soberania de Dados (mapa de riscos por camada, classificação de dados, Plano A cloud com controles, Plano B full on-premise, prompt injection, LGPD, BACEN/CVM, criptografia, auditoria, gestão de secrets, checklist por fase, resposta a incidentes)
- **B15** — Governança, Capacidade e Rollback (papéis, RACI, rollback granular/lote/urgente, capacity planning, critérios de transição entre fases, cadência de curadoria)

Blueprints monolíticos originais marcados como supersedidos. B7 (Visão Consolidada) atualizado com capacidades dos B10-B15.

---

## Documentos relacionados

- **Relacionados:**
  - [[B00_introducao]] — Introdução (referencia toda a série)
  - [[B07_visao_consolidada]] — Visão Consolidada (evolução por fase)
  - [[B16_roadmap_implementacao]] — Roadmap (sequenciamento e marcos)
