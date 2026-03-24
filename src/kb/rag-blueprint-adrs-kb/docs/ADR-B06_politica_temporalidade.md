---
id: ADR-B06
doc_type: adr
title: "Política de Temporalidade do Conhecimento"
system: RAG Corporativo
module: Temporalidade
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - temporalidade conhecimento
  - valid from
  - valid until
  - supersedes
  - superseded by
  - camadas temporais
  - front matter temporal
  - base vetorial relacoes
  - retrieval filtro temporal
  - deprecacao documento
  - document family
  - version of
  - ranking reduzido
  - cadeia supersedes
  - versionamento semantico
  - politica programada
  - vigencia documento
  - consulta historica
  - filtro pre retrieval
  - agente temporal
  - pipeline promocao
  - pipeline ingestao
  - neo4j relacoes
  - effective date
  - current version
  - status deprecated
  - regras deprecacao
  - validacao temporal
  - data iso 8601
  - md final temporal
  - beta md campos ausentes
  - knowledge base
  - grafo conhecimento
  - diff semantico
  - documento vigente
  - documento historico
  - regulacao
  - lgpd
  - bacen
  - rollback
  - release tag
  - rebuild base vetorial
  - idempotencia
  - contexto temporal
  - reranking penalidade
  - auditoria
  - rastreabilidade
  - navegacao versoes
  - familia documento
  - promocao fase 3
  - ingestao fase 4
aliases:
  - "ADR-B06"
  - "Politica Temporalidade Conhecimento"
  - "Vigência de Documentos"
  - "Versionamento Temporal"
  - "Ciclo de Vida Temporal"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-B06_politica_temporalidade.beta.md"
source_beta_ids:
  - "BETA-B06"
conversion_pipeline: promotion-pipeline-v2
conversion_quality: 95
converted_at: 2026-03-23
qa_score: null
qa_date: null
qa_status: pending
created_at: 2026-03-23
updated_at: 2026-03-23
valid_from: 2026-03-23
valid_until: null
---

# ADR-B06 — Política de Temporalidade do Conhecimento

## 1. Visão Geral

O conhecimento corporativo não é estático. Leis mudam, regulações são atualizadas, políticas internas evoluem, sistemas são substituídos. O pipeline de conhecimento precisa representar essa temporalidade de forma explícita.

[[ADR-001]] define um modelo em **3 CAMADAS** para versionamento semântico do conhecimento, garantindo que agentes possam responder tanto sobre o estado atual quanto sobre estados históricos.

## 2. Campos Temporais no Front Matter (.md final)

### 2.1 valid_from

- **Tipo:** string (data ISO 8601), formato AAAA-MM-DD
- **Obrigatório:** sim (bloqueante no `.md` final)
- Define a data a partir da qual o documento passa a ser considerado **VIGENTE**.

### 2.2 valid_until

- **Tipo:** string (data ISO 8601) ou null
- `null` significa vigente por tempo indeterminado.

### 2.3 supersedes

- **Tipo:** string (`DOC-{NNNNNN}`)
- Identificador do documento ANTERIOR que este documento substitui.

### 2.4 superseded_by

- **Tipo:** string (`DOC-{NNNNNN}`)
- **Obrigatório:** sim quando `status = deprecated`

## 3. As 3 Camadas de Temporalidade

### 3.1 Camada 1 — No .md (front matter)

Campos `valid_from`, `valid_until`, `supersedes`, `superseded_by` no front matter YAML do `.md` final. Pipeline de promoção (Fase 3) preenche estes campos.

### 3.2 Camada 2 — Na Base Vetorial (relações temporais)

**Relações:**

- `(:Document)-[:SUPERSEDES {effective_date}]->(:Document)`
- `(:Document)-[:VERSION_OF]->(:DocumentFamily)`

**Nó específico:**

- `:DocumentFamily` — Atributos: `family_id`, `title`, `current_version`. Agrupa todas as versões de um mesmo documento conceitual.

### 3.3 Camada 3 — No retrieval (filtro temporal)

**Regras:**

1. Detectar contexto temporal na pergunta do usuário
2. Filtrar por `valid_from`/`valid_until` ANTES da busca vetorial
3. Se não houver contexto temporal explícito, assumir **DATA ATUAL**
4. Agentes instruídos a citar vigência e versões anteriores nas respostas

## 4. Regras de Deprecação

### 4.1 Processo de deprecação

1. Criar novo documento com `supersedes` apontando para o antigo
2. No documento antigo, preencher: `status: deprecated`, `superseded_by`, `valid_until`
3. Na Base Vetorial: criar relação `SUPERSEDES`, atualizar `current_version` no DocumentFamily, manter documento deprecated com **RANKING REDUZIDO**

### 4.2 Ranking de documentos deprecated

Documentos deprecated **NÃO** são removidos da Base Vetorial. São mantidos com ranking reduzido para consultas históricas, rastreabilidade e contexto.

## 5. Cadeia Supersedes

```
DOC-000001 (v1, deprecated)
  superseded_by: DOC-000023
    |
    v
DOC-000023 (v2, deprecated)
  supersedes: DOC-000001
  superseded_by: DOC-000042
    |
    v
DOC-000042 (v3, approved, vigente)
  supersedes: DOC-000023
  superseded_by: null
```

## 6. Regras de Validação Temporal

| Regra | Tipo |
|-------|------|
| `valid_from` obrigatório no `.md` final | Bloqueante |
| `valid_from` não futura (exceto políticas) | Bloqueante |
| `valid_until` > `valid_from` (se presente) | Bloqueante |
| `superseded_by` obrigatório se deprecated | Bloqueante |
| `supersedes` referencia documento existente | Bloqueante |
| `valid_until` preenchido se `superseded_by` presente | Bloqueante |

## 7. Campos Ausentes no .beta.md

Os campos temporais **NÃO** existem no front matter leve do `.beta.md`. São preenchidos exclusivamente na Fase 3 (promoção) pelo pipeline.

<!-- conversion_quality: 95 -->
