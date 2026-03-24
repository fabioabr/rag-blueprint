---
id: BETA-B02
title: "Schema do Front Matter Rico (.md final)"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-B02_schema_front_matter_rico.txt"
    captured_at: "2026-03-23"
    conversion_quality: 96
tags: [front matter rico, schema yaml, md final, pipeline promocao, campos identificacao, campos classificacao, campos governanca, campos temporais, campos qa, campos descoberta, campos linhagem, campos versionamento, doc type, system, module, owner, team, valid from, valid until, supersedes, superseded by, qa score, qa date, qa status, qa notes, source format, source repo, source path, source beta ids, conversion pipeline, conversion quality, converted at, created at, updated at, release version, tags semanticas, aliases, status deprecated, confidentiality, base vetorial, grafo neo4j, chunking estrategia, filtro retrieval, rastreabilidade, semver, document family, promocao fase 3, ingestao fase 4, enum doc type, enum source format, enum qa status, ranking reduzido]
aliases:
  - "ADR-B02"
  - "Schema Front Matter Rico"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## 1. Visão Geral

O front matter rico é o contrato COMPLETO que o `.md` final carrega no repositório rag-knowledge-base. É gerado pelo pipeline de promoção (Fase 3) a partir do front matter leve com enriquecimento de campos de governança, classificação e qualidade.

Os campos são organizados em **8 GRUPOS LÓGICOS**.

## 2. Grupo 1 — Identificação

### 2.1 id

- **Tipo:** string
- **Formato:** `DOC-{NNNNNN}` (6 dígitos, zero-padded)
- **Regex:** `^DOC-\d{6}$`
- **Exemplo:** `id: DOC-000042`
- **Obrigatório:** sim (bloqueante)

**Por que existe:**
Identificador único e definitivo na base de conhecimento. Permanente, referenciado pela Base Vetorial, chunks, relações e agentes. Diferente do `BETA-{NNN}` que é temporário no workspace.

### 2.2 doc_type

- **Tipo:** string (enum)
- **Valores:** `system-doc` | `adr` | `runbook` | `glossary` | `task-doc` | `architecture-doc` | `policy` | `meeting-notes` | `onboarding` | `postmortem`
- **Exemplo:** `doc_type: system-doc`
- **Obrigatório:** sim (bloqueante)

**Por que existe:**
Determina a estratégia de chunking na ingestão, o template de resposta do agente e o filtro de busca. Cada tipo tem comportamento diferente.

### 2.3 title

- **Tipo:** string
- **Formato:** herdado do front matter leve
- **Exemplo:** `title: "Processo de conciliação bancária do módulo Cobrança"`
- **Obrigatório:** sim (bloqueante)

## 3. Grupo 2 — Classificação

### 3.1 system

- **Tipo:** string
- **Formato:** nome do sistema corporativo (cadastrado)
- **Exemplo:** `system: Cobranca`
- **Obrigatório:** sim (bloqueante)

**Por que existe:**
Gera nó `:System` na Base Vetorial. Permite filtro por sistema no retrieval e organização do grafo de conhecimento.

### 3.2 module

- **Tipo:** string
- **Formato:** módulo funcional do sistema indicado
- **Exemplo:** `module: Conciliacao`
- **Obrigatório:** sim (bloqueante)

**Por que existe:**
Gera nó `:Module` na Base Vetorial e relação `BELONGS_TO` com System.

### 3.3 domain

- **Tipo:** string
- **Formato:** herdado do front matter leve (lowercase, sem espaços)
- **Exemplo:** `domain: financeiro`
- **Obrigatório:** sim (bloqueante)

### 3.4 owner

- **Tipo:** string
- **Formato:** usuário cadastrado (identificador único)
- **Exemplo:** `owner: maria.silva`
- **Obrigatório:** sim (bloqueante)

**Por que existe:**
Gera nó `:Owner` e relação `OWNED_BY` na Base Vetorial. Permite rastreabilidade de responsabilidade.

### 3.5 team

- **Tipo:** string
- **Formato:** time, squad, chapter ou diretoria (cadastrado)
- **Exemplo:** `team: squad-pagamentos`
- **Obrigatório:** sim (bloqueante)

**Por que existe:**
Gera nó `:Team` e relação `MEMBER_OF` na Base Vetorial. Permite filtro por equipe e responsabilidade organizacional.

## 4. Grupo 3 — Status e Governança

### 4.1 status

- **Tipo:** string (enum)
- **Valores:** `draft` | `in-review` | `approved` | `deprecated`
- **Exemplo:** `status: approved`
- **Obrigatório:** sim (bloqueante)

Diferença do `.beta.md`: adiciona `deprecated` ao ciclo de vida.

Regras:
- Somente `approved` é ingerido na Base Vetorial
- `deprecated` é mantido com ranking reduzido
- Quando deprecated, campo `superseded_by` é obrigatório

### 4.2 confidentiality

- **Tipo:** string (enum)
- **Valores:** `public` | `internal` | `restricted` | `confidential`
- **Formato:** herdado do front matter leve
- **Obrigatório:** sim (bloqueante)

## 5. Grupo 4 — Temporal

### 5.1 valid_from

- **Tipo:** string (data ISO 8601), formato AAAA-MM-DD
- **Exemplo:** `valid_from: "2026-01-15"`
- **Obrigatório:** sim (bloqueante)
- **Validação:** data válida, não futura (exceção: políticas programadas)

**Por que existe:**
Permite consultas temporais no retrieval. Agentes podem filtrar documentos vigentes em uma data específica.

### 5.2 valid_until

- **Tipo:** string (data ISO 8601) ou null
- **Exemplo:** `valid_until: null` (vigente indefinidamente)
- **Obrigatório:** não

**Por que existe:**
Define fim de vigência. `null` = documento vigente sem prazo. Quando preenchido, o documento deixa de ser retornado como vigente após a data.

### 5.3 supersedes

- **Tipo:** string
- **Formato:** `DOC-{NNNNNN}` do documento anterior que este substitui
- **Exemplo:** `supersedes: "DOC-000023"`
- **Obrigatório:** não

**Por que existe:**
Gera relação `SUPERSEDES` na Base Vetorial. Permite navegação na cadeia de versões de um documento.

### 5.4 superseded_by

- **Tipo:** string
- **Formato:** `DOC-{NNNNNN}` do documento que substitui este
- **Exemplo:** `superseded_by: "DOC-000456"`
- **Obrigatório:** sim quando `status = deprecated`

**Por que existe:**
Complemento do `supersedes`. Obrigatório quando o documento é deprecado, garantindo que sempre haja um ponteiro para a versão corrente.

## 6. Grupo 5 — QA (Quality Assurance)

### 6.1 qa_score

- **Tipo:** integer 0-100
- **Exemplo:** `qa_score: 85`
- **Obrigatório:** sim (bloqueante)

**Por que existe:**
Score de qualidade calculado pelo pipeline de QA. Determina se o documento pode ser promovido.

### 6.2 qa_date

- **Tipo:** string (data ISO 8601), formato AAAA-MM-DD
- **Exemplo:** `qa_date: "2026-03-21"`
- **Obrigatório:** sim (bloqueante)

**Por que existe:**
Data da última execução do QA. Permite identificar documentos com QA desatualizado.

### 6.3 qa_status

- **Tipo:** string (enum)
- **Valores:** `passed` (>= 90%) | `warning` (80-89%) | `not_reviewed`
- **Exemplo:** `qa_status: warning`
- **Obrigatório:** sim (bloqueante)

### 6.4 qa_notes

- **Tipo:** string (texto livre)
- **Exemplo:** `qa_notes: "Score 85% -- inferências sobre custos cloud não verificadas. Aprovado com ressalva pelo PO em 21/03/2026."`
- **Obrigatório:** sim quando `qa_status = warning`

**Por que existe:**
Documenta os motivos de um QA com ressalva e a decisão de promover mesmo assim. Rastreabilidade de decisões de qualidade.

## 7. Grupo 6 — Descoberta

### 7.1 tags

- **Tipo:** array de strings
- **Formato:** mínimo 5 manuais + 50 semânticas (total ~55+), lowercase, sem acentos; termos compostos separados por espaço (ex: `"busca vetorial"`)
- **Ordenação:** por relevância decrescente — índice 0 = mais relevante ao contexto
- **Composição:** tags manuais do autor (primeiras posições) + 50 tags semânticas geradas por IA na promoção `.txt` -> `.beta.md` e mantidas na promoção `.beta.md` -> `.md`. As tags semânticas são termos técnicos e de domínio extraídos do conteúdo, ordenados por proximidade ao contexto.
- **Exemplo:** `tags: [conciliacao, cobranca, bancaria, boleto, retorno, cnab, pipeline ingestao, chunking semantico, front matter, neo4j, ...]`
- **Obrigatório:** sim (bloqueante, mínimo 5 manuais)

### 7.2 aliases

- **Tipo:** array de strings
- **Formato:** mínimo 5 aliases
- **Exemplo:** `aliases: ["Conciliação Bancária", "Retorno CNAB", "Arquivo de Retorno", "Conciliação de Cobrança", "Processamento CNAB 240"]`
- **Obrigatório:** sim (bloqueante, mínimo 5)

**Por que existe:**
Permite busca e descoberta por múltiplos nomes. No `.md` final, o requisito é mais rigoroso (5+) para maximizar a descoberta na Base Vetorial.

## 8. Grupo 7 — Linhagem

### 8.1 source_format

- **Tipo:** string (enum)
- **Valores:** `original` | `pdf` | `docx` | `xlsx` | `pptx` | `email` | `confluence` | `sharepoint` | `jira` | `clickup` | `transcription` | `web` | `json` | `csv` | `image` | `video` | `audio` | `manual` | `multiple`
- **Exemplo:** `source_format: pdf`
- **Obrigatório:** sim (bloqueante)

**Por que existe:**
Formato principal da fonte. Permite análises de qualidade por formato e estratégias de reconversão.

### 8.2 source_repo

- **Tipo:** string
- **Formato:** nome do repositório Git de origem
- **Exemplo:** `source_repo: rag-workspace`
- **Obrigatório:** sim (bloqueante)

### 8.3 source_path

- **Tipo:** string
- **Formato:** caminho do `.beta.md` no workspace
- **Exemplo:** `source_path: "beta/financeiro/conciliacao_bancaria.beta.md"`
- **Obrigatório:** sim (bloqueante)

### 8.4 source_beta_ids

- **Tipo:** array de strings
- **Formato:** `BETA-{NNN}` que originaram este `.md`
- **Exemplo:** `source_beta_ids: ["BETA-042", "BETA-043"]`
- **Obrigatório:** sim (bloqueante)

**Por que existe:**
Rastreabilidade completa: de qual(is) `.beta.md` este `.md` foi gerado. Permite navegação reversa.

### 8.5 conversion_pipeline

- **Tipo:** string
- **Formato:** identificador do pipeline que gerou o `.md`
- **Exemplo:** `conversion_pipeline: promotion-pipeline-v1`
- **Obrigatório:** sim (bloqueante, string não vazia)

### 8.6 conversion_quality

- **Tipo:** integer 0-100
- **Formato:** score consolidado via `min(sources[].conversion_quality)`
- **Exemplo:** `conversion_quality: 82`
- **Obrigatório:** sim (bloqueante)

**Por que existe:**
Score consolidado de confiança na fidelidade da conversão. Usa a função `min()` para garantir que a pior fonte determine o score final.

### 8.7 converted_at

- **Tipo:** string (timestamp ISO 8601)
- **Formato:** AAAA-MM-DDTHH:MM:SSZ
- **Exemplo:** `converted_at: "2026-03-21T14:30:00Z"`
- **Obrigatório:** sim (bloqueante)

## 9. Grupo 8 — Datas e Versionamento

### 9.1 created_at

- **Tipo:** string (data ISO 8601), formato AAAA-MM-DD
- **Exemplo:** `created_at: "2026-03-21"`
- **Obrigatório:** sim (bloqueante)
- **Validação:** data válida

### 9.2 updated_at

- **Tipo:** string (data ISO 8601), formato AAAA-MM-DD
- **Exemplo:** `updated_at: "2026-03-21"`
- **Obrigatório:** sim (bloqueante)
- **Validação:** data válida, >= `created_at`

### 9.3 release_version

- **Tipo:** string
- **Formato:** semver `vN.N.N`
- **Exemplo:** `release_version: "v1.3.0"`
- **Obrigatório:** sim (preenchido automaticamente pelo pipeline de ingestão)

**Por que existe:**
Versão da release que disparou a ingestão na Base Vetorial. Permite rastrear qual versão do conhecimento está ativa.

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
qa_notes: "Score 85% -- inferências sobre custos cloud não verificadas. Aprovado com ressalva pelo PO em 21/03/2026."

# === DESCOBERTA ===
tags: [conciliacao, cobranca, bancaria, boleto, retorno, cnab, financeiro, banco-do-brasil, arquivo-retorno, cnab-240]
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

(corpo do documento aqui)

<!-- conversion_quality: 96 -->
