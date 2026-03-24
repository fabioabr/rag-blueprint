---
id: ADR-B02
doc_type: adr
title: "Schema do Front Matter Rico (.md final)"
system: RAG Corporativo
module: Front Matter Rico
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - front matter rico
  - schema yaml
  - md final
  - pipeline promocao
  - campos identificacao
  - campos classificacao
  - campos governanca
  - campos temporais
  - campos qa
  - campos descoberta
  - campos linhagem
  - campos versionamento
  - doc type
  - system
  - module
  - owner
  - team
  - valid from
  - valid until
  - supersedes
  - superseded by
  - qa score
  - qa date
  - qa status
  - qa notes
  - source format
  - source repo
  - source path
  - source beta ids
  - conversion pipeline
  - conversion quality
  - converted at
  - created at
  - updated at
  - release version
  - tags semanticas
  - aliases
  - status deprecated
  - confidentiality
  - base vetorial
  - grafo neo4j
  - chunking estrategia
  - filtro retrieval
  - rastreabilidade
  - semver
  - document family
  - promocao fase 3
  - ingestao fase 4
  - enum doc type
  - enum source format
  - ranking reduzido
aliases:
  - "ADR-B02"
  - "Schema Front Matter Rico"
  - "Front Matter Rico Especificação"
  - "Contrato Metadados MD Final"
  - "Schema Completo Governança"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-B02_schema_front_matter_rico.beta.md"
source_beta_ids:
  - "BETA-B02"
conversion_pipeline: promotion-pipeline-v2
conversion_quality: 96
converted_at: 2026-03-23
qa_score: null
qa_date: null
qa_status: pending
created_at: 2026-03-23
updated_at: 2026-03-23
valid_from: 2026-03-23
valid_until: null
---

# ADR-B02 — Schema do Front Matter Rico (.md final)

## 1. Visão Geral

O front matter rico é o contrato COMPLETO que o `.md` final carrega no repositório rag-knowledge-base. É gerado pelo pipeline de promoção (Fase 3) a partir do front matter leve com enriquecimento de campos de governança, classificação e qualidade.

Os campos são organizados em **8 GRUPOS LÓGICOS**.

## 2. Grupo 1 — Identificação

### 2.1 id

- **Tipo:** string
- **Formato:** `DOC-{NNNNNN}` (6 dígitos, zero-padded)
- **Regex:** `^DOC-\d{6}$`
- **Obrigatório:** sim (bloqueante)

**Por que existe:**
Identificador único e definitivo na base de conhecimento. Permanente, referenciado pela Base Vetorial, chunks, relações e agentes.

### 2.2 doc_type

- **Tipo:** string (enum)
- **Valores:** `system-doc` | `adr` | `runbook` | `glossary` | `task-doc` | `architecture-doc` | `policy` | `meeting-notes` | `onboarding` | `postmortem`
- **Obrigatório:** sim (bloqueante)

**Por que existe:**
Determina a estratégia de chunking na ingestão, o template de resposta do agente e o filtro de busca.

### 2.3 title

- **Tipo:** string
- **Formato:** herdado do front matter leve
- **Obrigatório:** sim (bloqueante)

## 3. Grupo 2 — Classificação

### 3.1 system

- **Tipo:** string
- **Formato:** nome do sistema corporativo (cadastrado)
- **Obrigatório:** sim (bloqueante)

**Por que existe:**
Gera nó `:System` na Base Vetorial. Permite filtro por sistema no retrieval e organização do grafo de conhecimento.

### 3.2 module

- **Tipo:** string
- **Formato:** módulo funcional do sistema indicado
- **Obrigatório:** sim (bloqueante)

**Por que existe:**
Gera nó `:Module` na Base Vetorial e relação `BELONGS_TO` com System.

### 3.3 domain

- **Tipo:** string
- **Formato:** herdado do front matter leve (lowercase, sem espaços)
- **Obrigatório:** sim (bloqueante)

### 3.4 owner

- **Tipo:** string
- **Formato:** usuário cadastrado (identificador único)
- **Obrigatório:** sim (bloqueante)

### 3.5 team

- **Tipo:** string
- **Formato:** time, squad, chapter ou diretoria (cadastrado)
- **Obrigatório:** sim (bloqueante)

## 4. Grupo 3 — Status e Governança

### 4.1 status

- **Tipo:** string (enum)
- **Valores:** `draft` | `in-review` | `approved` | `deprecated`
- **Obrigatório:** sim (bloqueante)

Regras:
- Somente `approved` é ingerido na Base Vetorial
- `deprecated` é mantido com ranking reduzido
- Quando deprecated, campo `superseded_by` é obrigatório

### 4.2 confidentiality

- **Tipo:** string (enum)
- **Valores:** `public` | `internal` | `restricted` | `confidential`
- **Obrigatório:** sim (bloqueante)

## 5. Grupo 4 — Temporal

### 5.1 valid_from

- **Tipo:** string (data ISO 8601), formato AAAA-MM-DD
- **Obrigatório:** sim (bloqueante)

### 5.2 valid_until

- **Tipo:** string (data ISO 8601) ou null
- **Obrigatório:** não

### 5.3 supersedes

- **Tipo:** string
- **Formato:** `DOC-{NNNNNN}` do documento anterior que este substitui
- **Obrigatório:** não

### 5.4 superseded_by

- **Tipo:** string
- **Formato:** `DOC-{NNNNNN}` do documento que substitui este
- **Obrigatório:** sim quando `status = deprecated`

## 6. Grupo 5 — QA (Quality Assurance)

### 6.1 qa_score

- **Tipo:** integer 0-100
- **Obrigatório:** sim (bloqueante)

### 6.2 qa_date

- **Tipo:** string (data ISO 8601)
- **Obrigatório:** sim (bloqueante)

### 6.3 qa_status

- **Tipo:** string (enum)
- **Valores:** `passed` (>= 90%) | `warning` (80-89%) | `not_reviewed`
- **Obrigatório:** sim (bloqueante)

### 6.4 qa_notes

- **Tipo:** string (texto livre)
- **Obrigatório:** sim quando `qa_status = warning`

## 7. Grupo 6 — Descoberta

### 7.1 tags

- **Tipo:** array de strings
- **Formato:** mínimo 5 manuais + 50 semânticas (total ~55+), lowercase, sem acentos
- **Ordenação:** por relevância decrescente
- **Obrigatório:** sim (bloqueante, mínimo 5 manuais)

### 7.2 aliases

- **Tipo:** array de strings
- **Formato:** mínimo 5 aliases
- **Obrigatório:** sim (bloqueante, mínimo 5)

## 8. Grupo 7 — Linhagem

### 8.1 source_format

- **Tipo:** string (enum)
- **Obrigatório:** sim (bloqueante)

### 8.2 source_repo

- **Tipo:** string
- **Obrigatório:** sim (bloqueante)

### 8.3 source_path

- **Tipo:** string
- **Obrigatório:** sim (bloqueante)

### 8.4 source_beta_ids

- **Tipo:** array de strings
- **Formato:** `BETA-{NNN}` que originaram este `.md`
- **Obrigatório:** sim (bloqueante)

### 8.5 conversion_pipeline

- **Tipo:** string
- **Obrigatório:** sim (bloqueante, string não vazia)

### 8.6 conversion_quality

- **Tipo:** integer 0-100
- **Formato:** score consolidado via `min(sources[].conversion_quality)`
- **Obrigatório:** sim (bloqueante)

### 8.7 converted_at

- **Tipo:** string (timestamp ISO 8601)
- **Obrigatório:** sim (bloqueante)

## 9. Grupo 8 — Datas e Versionamento

### 9.1 created_at

- **Tipo:** string (data ISO 8601)
- **Obrigatório:** sim (bloqueante)

### 9.2 updated_at

- **Tipo:** string (data ISO 8601)
- **Obrigatório:** sim (bloqueante)

### 9.3 release_version

- **Tipo:** string
- **Formato:** semver `vN.N.N`
- **Obrigatório:** sim (preenchido automaticamente pelo pipeline de ingestão)

## 10. Exemplo Completo de .md Final com Front Matter Rico

```yaml
---
# === IDENTIFICAÇÃO ===
id: DOC-000042
doc_type: system-doc
title: "Processo de conciliação bancária do módulo Cobrança"

# === CLASSIFICAÇÃO ===
system: Cobranca
module: Conciliacao
domain: financeiro
owner: maria.silva
team: squad-pagamentos

# === STATUS E GOVERNANÇA ===
status: approved
confidentiality: internal

# === TEMPORAL ===
valid_from: "2026-01-15"
valid_until: null
supersedes: "DOC-000023"
superseded_by: null

# === QA ===
qa_score: 85
qa_date: "2026-03-21"
qa_status: warning
qa_notes: "Score 85% -- inferências sobre custos cloud não verificadas."

# === DESCOBERTA ===
tags: [conciliacao, cobranca, bancaria, boleto, retorno, cnab]
aliases: ["Conciliação Bancária", "Retorno CNAB", "Arquivo de Retorno", "Conciliação de Cobrança", "Processamento CNAB 240"]

# === LINHAGEM ===
source_format: pdf
source_repo: rag-workspace
source_path: "beta/financeiro/conciliacao_bancaria.beta.md"
source_beta_ids: ["BETA-042", "BETA-043"]
conversion_pipeline: promotion-pipeline-v1
conversion_quality: 82
converted_at: "2026-03-21T14:30:00Z"

# === DATAS E VERSIONAMENTO ===
created_at: "2026-03-21"
updated_at: "2026-03-21"
release_version: "v1.3.0"
---
```

<!-- conversion_quality: 96 -->
