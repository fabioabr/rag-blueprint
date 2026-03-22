# CLAUDE.md

Este arquivo orienta o Claude Code ao trabalhar neste repositório.

## Idioma

Toda documentação e comunicação neste repositório é em **português brasileiro (pt-BR)**.

## Visão Geral do Projeto

Repositório de **arquitetura e planejamento** do projeto RAG. Não contém código de aplicação — apenas blueprints, documentos de design e decisões arquiteturais para construção de uma **base de conhecimento corporativa com GraphRAG**.

Premissa central:
- **Git** = origem da verdade (documentos Markdown com front matter estruturado)
- **Neo4j** = projeção operacional (grafo + vetor + metadados)
- **Agentes de IA** = consumidores controlados via recuperação híbrida

## Estrutura de Pastas

```
./
├── CLAUDE.md                  # Este arquivo
├── c.bat                      # Atalho para iniciar Claude Code
├── .claude/
│   └── behavior/
│       └── ui_ux/
│           ├── design_system.md           # Design System padrão (cores, tipografia, componentes)
│           └── template_relatorio_html.md # Template OBRIGATÓRIO para relatórios HTML
└── Arquitetura/
    └── rag-blueprint/                     # Blueprint da base de conhecimento GraphRAG
        ├── 1 - draft/                    # Rascunhos (.txt) — escrita livre, iteração rápida
        │   ├── blueprint_base_conhecimento_neo4j.txt
        │   ├── blueprint_rag_corporativo_detalhado.txt
        │   └── B00_introducao.txt … B16_roadmap_implementacao.txt  # Blueprint modularizado (17 docs)
        ├── 2 - docs/                     # Documentação formal (.md) — base de conhecimento
        ├── 3 - presentation/            # Apresentações (.html standalone) — visualização
        ├── kb/                          # Knowledge Bases temáticas
        │   ├── rag-blueprint-adrs-kb/           # ADRs como KB (draft .txt → docs .md)
        │   ├── rag-ingestion-rules-kb/          # Regras do processo de ingestão
        │   ├── financial-department-rules-kb/    # Regras do departamento financeiro
        │   └── human-ressource-rules-kb/        # Regras de recursos humanos
        └── pendings/                    # Itens pendentes de processamento
```

- A pasta `Arquitetura/` agrupa blueprints por tema (ex: `rag-blueprint/`), cada um com um pipeline de maturidade:
  - `1 - draft/` — rascunhos em `.txt`, escrita livre e iteração rápida
  - `2 - docs/` — documentos formais em `.md`, gerados a partir dos drafts — servem como **base de conhecimento**
  - `3 - presentation/` — arquivos `.html` standalone gerados para **apresentações**
  - `kb/` — Knowledge Bases temáticas, cada uma com seu próprio pipeline (`1 - draft/` .txt → `2 - docs/` .md)
  - `pendings/` — itens pendentes de processamento
- A pasta `.claude/behavior/` contém diretrizes comportamentais (ex: design system em `ui_ux/`).

## Regras de Geração de Materiais

### Relatórios HTML — OBRIGATÓRIO

Ao gerar qualquer arquivo HTML (relatórios, dashboards, painéis de status, acompanhamentos), **SEMPRE** seguir o template definido em `.claude/behavior/ui_ux/template_relatorio_html.md`. Regras principais:

- **Mínimo 3 abas obrigatórias:**
  - **1a aba "Visão Macro"** — KPIs, roadmap, progresso geral, alertas (visão executiva/estratégica)
  - **2a aba "Visão Técnica"** — detalhamento item a item, status granular, pendências (visão para devs/tech leads)
  - **3a aba "Quality Assurance"** — score geral, breakdown por critério, pontos fortes, sugestões de melhoria, justificativa de por que não é 100%
  - **4a+ abas customizadas** — conforme necessidade do relatório
- Tema escuro como padrão, com toggle para tema claro
- Tipografia: **Poppins** (Google Fonts) — nenhuma outra
- Ícones: **Remix Icon** (CDN) — nenhuma outra biblioteca
- CSS e JS **inline** no próprio arquivo (self-contained, sem frameworks externos)
- Usar **exclusivamente os design tokens** definidos no template (variáveis CSS `var(--*)`)
- Estrutura: Header com gradiente → Tabs → Stats Grid → Cards → Sections → Footer
- Incluir responsividade e suporte a impressão
- Conteúdo em pt-BR

### Outros materiais visuais

Consultar o Design System em `.claude/behavior/ui_ux/design_system.md` para cores, tipografia, componentes e diretrizes de geração de apresentações, documentos, diagramas e interfaces.

## Blueprint Principal

Arquivo original: `Arquitetura/rag-blueprint/1 - draft/blueprint_base_conhecimento_neo4j.txt`
Versão modularizada: `Arquitetura/rag-blueprint/1 - draft/B0_introducao.txt` a `B9_referencias.txt`

### Arquitetura Macro

```
[Git Repos .md] → [Pipeline de Ingestão] → [Parser + Chunking] → [Embeddings] → [Neo4j] → [Retriever Híbrido] → [Agentes/MCP/RAG]
```

### Pipeline de Ingestão (7 etapas)

1. **Descoberta** — identificar `.md` nos repos, capturar hash/branch/commit/path
2. **Parse** — extrair front matter, headings, links internos; validar schema mínimo
3. **Chunking** — quebrar por headings, herdar metadados, faixa de 300-800 tokens
4. **Embeddings** — gerar embedding por chunk, registrar modelo e versão
5. **Persistência** — upsert de Document/Chunk, criar/atualizar relações, remover chunks órfãos
6. **Indexação** — vector index para embeddings, índices auxiliares para filtros
7. **Observabilidade** — medir volumes, falhas, latência, consistência

### Modelo de Grafo (Neo4j)

**Nós (Labels):**
| Label | Descrição |
|-------|-----------|
| `Document` | Arquivo Markdown ingerido |
| `Chunk` | Fragmento semântico de um Document |
| `System` | Sistema corporativo |
| `Module` | Módulo funcional de um sistema |
| `ADR` | Registro de decisão arquitetural |
| `Task` | Tarefa (ClickUp, Jira, etc.) |
| `Owner` | Responsável por conteúdo/sistema/módulo |
| `Team` | Time, squad, chapter ou diretoria |
| `GlossaryTerm` | Termo de negócio controlado |

**Relações principais:**
- `(:Chunk)-[:PART_OF]->(:Document)`
- `(:Document)-[:BELONGS_TO]->(:Module)`
- `(:Module)-[:BELONGS_TO]->(:System)`
- `(:Document)-[:OWNED_BY]->(:Owner)`
- `(:Owner)-[:MEMBER_OF]->(:Team)`
- `(:Document)-[:RELATES_TO_TASK]->(:Task)`
- `(:Document)-[:REFERENCES]->(:Document)`
- `(:Document)-[:USES_TERM]->(:GlossaryTerm)`
- `(:ADR)-[:DECIDES]->(:System)`
- `(:Module)-[:DEPENDS_ON]->(:Module)`
- `(:Task)-[:IMPLEMENTS]->(:Module)`

### Front Matter Obrigatório

Todo `.md` corporativo deve conter:

```yaml
---
id: DOC-000123
doc_type: system-doc          # Tipos: system-doc, adr, runbook, glossary, task-doc, architecture-doc
title: Módulo de Cobrança
system: Sistema Exemplo
module: Cobranca
domain: Financeiro
owner: fabio
team: arquitetura
status: approved              # draft | in-review | approved | deprecated
confidentiality: internal     # public | internal | restricted | confidential
tags: [boleto, remessa, cobranca]
clickup_task_id: CU-4567
created_at: 2026-03-17
updated_at: 2026-03-17
---
```

### Estratégia de Chunking por Tipo de Documento

- **ADR** — chunks menores e precisos
- **Runbook** — chunk por procedimento/passo operacional
- **Documento arquitetural** — chunk por módulo, fluxo ou decisão
- **Glossário** — chunk quase atômico por termo
- **Documento de task** — chunk por contexto, escopo, decisão e aceite

### Segurança e Governança

Níveis de confidencialidade aplicados como **filtro pré-retrieval**:
- `public` — acesso livre
- `internal` — uso interno
- `restricted` — acesso restrito
- `confidential` — altamente confidencial

Regra: nunca confiar apenas em prompt para segurança. Filtros devem ser aplicados antes da busca vetorial.

Para ambientes multi-tenant, considerar: `tenant_id`, `business_unit`, `data_scope`.

### Fluxo de Recuperação para Agentes

1. Interpretar intenção da pergunta
2. Aplicar filtro de acesso e domínio
3. Busca vetorial nos chunks
4. Expansão de contexto via grafo
5. Reranking do contexto recuperado
6. Montar prompt com evidências
7. Responder citando origem documental

### Constraints e Índices no Neo4j

- Unicidade: `Document.document_id`, `Chunk.chunk_id`
- Índices: `Document.path`, `Document.doc_type`, `Document.system`, `Document.module`, `Document.confidentiality`
- Vector index: `Chunk.embedding`

## Fases de Rollout

| Fase | Foco | Entregas |
|------|------|----------|
| **1 — MVP** | Valor rápido | Ingestão .md → Document/Chunk → embeddings → vector index → busca semântica simples |
| **2 — Metadados** | Governança | Front matter padronizado, filtros por sistema/módulo/confidencialidade, rastreio de commits |
| **3 — Knowledge Graph** | Relações | Nós System, Module, Task, Owner, GlossaryTerm + relações explícitas |
| **4 — GraphRAG Corporativo** | Maturidade | Retrieval híbrido completo, reranking, segurança por escopo, agentes por domínio |

## Referências Técnicas

- [Neo4j Vector Indexes](https://neo4j.com/docs/cypher-manual/current/indexes/semantic-indexes/vector-indexes/)
- [Neo4j GraphRAG for Python](https://neo4j.com/docs/neo4j-graphrag-python/current/)
- [Neo4j Vector Search with Filters](https://neo4j.com/blog/genai/vector-search-with-filters-in-neo4j-v2026-01-preview/)

## Convenções para Contribuição

- Documentos sempre em pt-BR
- Novos documentos de arquitetura devem ir em `Arquitetura/<tema>/` (ex: `rag-blueprint/`)
- Pipeline de maturidade: rascunhos `.txt` em `1 - draft/` → documentos `.md` em `2 - docs/` → apresentações `.html` em `3 - presentation/`
- Usar front matter completo em qualquer `.md` corporativo (pasta `2 - docs/`)
- Ao criar novos blueprints, seguir o mesmo formato e nível de detalhe do blueprint principal
- ADRs (`.md`) devem ir na pasta `2 - docs/` do tema correspondente
