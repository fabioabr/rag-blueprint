---
id: ADR-B03
doc_type: adr
title: "Regras de Validação do Front Matter"
system: RAG Corporativo
module: Validação Front Matter
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - validacao front matter
  - schema executavel
  - bloqueante
  - nao bloqueante
  - warning
  - rejeicao explicita
  - pipeline fase 2
  - pipeline fase 3
  - campo obrigatorio
  - campo opcional
  - regex pattern
  - enum validacao
  - beta md validacao
  - md final validacao
  - id beta formato
  - id doc formato
  - domain regex
  - status enum
  - confidentiality enum
  - sources validacao
  - captured at formato
  - conversion quality range
  - doc type enum
  - source format enum
  - qa status enum
  - tags minimo
  - aliases minimo
  - valid from validacao
  - updated at validacao
  - superseded by condicional
  - qa notes condicional
  - mensagem erro
  - log erro
  - notificacao responsavel
  - relatorio pendentes
  - relatorio alertas
  - skip silencioso
  - campo invalido
  - campo ausente
  - sugestao correcao
  - promocao bloqueio
  - enriquecimento validacao
  - front matter leve regras
  - front matter rico regras
  - campos condicionais
  - comportamento falha
  - source type enum
  - valores validos enums
  - regex consolidado
  - validacao schema
  - pipeline executavel
aliases:
  - "ADR-B03"
  - "Regras Validacao Front Matter"
  - "Schema Executável de Validação"
  - "Validação de Metadados"
  - "Regras Bloqueantes Front Matter"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-B03_regras_validacao_front_matter.beta.md"
source_beta_ids:
  - "BETA-B03"
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

# ADR-B03 — Regras de Validação do Front Matter

## 1. Visão Geral

O schema de validação é um componente **EXECUTÁVEL** do pipeline — não apenas documentação. Ele roda em dois momentos:

1. **Na Fase 2 (enriquecimento):** valida o front matter leve do `.beta.md`
2. **Na Fase 3 (promoção):** valida o front matter rico do `.md` final

**REGRA FUNDAMENTAL:** rejeição EXPLÍCITA, nunca skip silencioso.

## 2. Classificação: Bloqueante vs Não-Bloqueante

**Bloqueante:**
Documento é REJEITADO se o campo está ausente ou inválido. Pipeline para, registra erro, notifica responsável.

**Não-bloqueante (warning):**
Documento é ACEITO, mas alerta é registrado no log. Documento aparece em relatório de "documentos com alertas".

## 3. Regras de Validação — Front Matter Leve (.beta.md)

### 3.1 Campos bloqueantes

| Campo | Regra | Regex/Formato | Mensagem de erro |
|-------|-------|---------------|------------------|
| `id` | Presente, formato válido, único | `^BETA-\d{3,}$` | `"Campo 'id' ausente ou formato inválido"` |
| `title` | Presente, 10-200 chars, não genérico | `len >= 10 AND len <= 200` | `"Campo 'title' ausente ou muito curto"` |
| `domain` | Presente, >= 2 chars, lowercase, sem espaço | `^[a-z][a-z0-9-]*$`, `len >= 2` | `"Campo 'domain' ausente ou formato inválido"` |
| `sources` | Presente, array >= 1 elem, sub-campos ok | array, each: `type+origin+cap` | `"Campo 'sources' ausente ou incompleto"` |
| `status` | Presente, enum válido | `^(draft\|in-review\|approved)$` | `"Campo 'status' ausente ou valor inválido"` |
| `confidentiality` | Presente, enum válido | `^(public\|internal\|restricted\|confidential)$` | `"Campo 'confidentiality' ausente ou valor inválido"` |

### 3.2 Campos com warning (não-bloqueante)

| Campo | Regra | Warning |
|-------|-------|---------|
| `tags` | Array >= 3 elementos | `"tags: menos de 3 tags. Adicione mais para melhor descoberta."` |
| `last_enrichment` | Data válida se presente | `"last_enrichment não preenchido."` |
| `last_human_edit` | Data válida se presente | `"last_human_edit não preenchido."` |
| `aliases` | Array sem duplicatas | (sem warning específico) |

## 4. Regras de Validação — Front Matter Rico (.md final)

### 4.1 Campos bloqueantes adicionais

| Campo | Regra |
|-------|-------|
| `id` | Formato `DOC-{NNNNNN}`, regex `^DOC-\d{6}$`, único |
| `doc_type` | Enum válido |
| `system` | String não vazia |
| `module` | String não vazia |
| `owner` | String não vazia |
| `team` | String não vazia |
| `valid_from` | Data válida, não futura* |
| `tags` | Array >= 5 elementos |
| `aliases` | Array >= 5 elementos |
| `source_format` | Enum válido |
| `source_repo` | String não vazia |
| `source_path` | String não vazia |
| `source_beta_ids` | Array de strings formato `BETA-{NNN}` |
| `conversion_pipeline` | String não vazia |
| `conversion_quality` | Integer 0-100 |
| `created_at` | Data válida |
| `updated_at` | Data válida, >= `created_at` |
| `converted_at` | Timestamp ISO 8601 válido |
| `qa_score` | Integer 0-100 |
| `qa_date` | Data válida |
| `qa_status` | Enum válido |

### 4.2 Campos condicionalmente obrigatórios

| Campo | Condição | Regra |
|-------|----------|-------|
| `superseded_by` | `status = deprecated` | `DOC-{NNNNNN}` obrigatório |
| `qa_notes` | `qa_status = warning` | String não vazia obrigatória |

## 5. Comportamento Quando Validação Falha

### 5.1 Campo BLOQUEANTE inválido

1. Documento é REJEITADO
2. Mensagem de erro registrada no log com: identificador, campo, valor encontrado, valor esperado, sugestão de correção
3. Notificação enviada ao responsável
4. Documento aparece em relatório de "documentos pendentes"

### 5.2 Campo com WARNING inválido

1. Documento é ACEITO (processamento continua)
2. Warning registrado no log
3. Documento aparece em relatório de "documentos com alertas"

### 5.3 Princípio fundamental

**NUNCA** aceitar silenciosamente dados incompletos ou inválidos.

## 6. Valores Válidos para Enums

### 6.1 doc_type

`system-doc` | `adr` | `runbook` | `glossary` | `task-doc` | `architecture-doc` | `policy` | `meeting-notes` | `onboarding` | `postmortem`

### 6.2 status (.beta.md)

`draft` | `in-review` | `approved`

### 6.3 status (.md final)

`draft` | `in-review` | `approved` | `deprecated`

### 6.4 confidentiality

`public` | `internal` | `restricted` | `confidential`

### 6.5 source_format

`original` | `pdf` | `docx` | `xlsx` | `pptx` | `email` | `confluence` | `sharepoint` | `jira` | `clickup` | `transcription` | `web` | `json` | `csv` | `image` | `video` | `audio` | `manual`

### 6.6 qa_status

`pending` | `passed` | `failed` | `skipped`

### 6.7 source type (array sources[] do .beta.md)

`pdf` | `docx` | `xlsx` | `pptx` | `email` | `confluence` | `sharepoint` | `jira` | `clickup` | `transcription` | `web` | `manual` | `md` | `json` | `csv` | `image` | `video` | `audio`

## 7. Regex Patterns — Resumo Consolidado

| Campo | Pattern |
|-------|---------|
| `id` (`.beta.md`) | `^BETA-\d{3,}$` |
| `id` (`.md` final) | `^DOC-\d{6}$` |
| `domain` | `^[a-z][a-z0-9-]*$` (mínimo 2 chars) |
| `status` (`.beta.md`) | `^(draft\|in-review\|approved)$` |
| `status` (`.md`) | `^(draft\|in-review\|approved\|deprecated)$` |
| `confidentiality` | `^(public\|internal\|restricted\|confidential)$` |
| `captured_at` | `^\d{4}-\d{2}-\d{2}$` |
| `conversion_quality` | `^\d{1,3}$` (0-100) |

<!-- conversion_quality: 95 -->
