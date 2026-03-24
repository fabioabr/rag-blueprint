---
id: ADR-B01
doc_type: adr
title: "Schema do Front Matter Leve (.beta.md)"
system: RAG Corporativo
module: Front Matter Leve
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - front matter leve
  - schema yaml
  - beta md
  - campos obrigatorios
  - campos opcionais
  - validacao bloqueante
  - validacao warning
  - id beta formato
  - title
  - domain
  - sources array
  - tags semanticas
  - status ciclo vida
  - confidentiality
  - last enrichment
  - last human edit
  - aliases obsidian
  - conversion quality
  - pipeline fase 2
  - obsidian compatibilidade
  - wikilinks
  - carga cognitiva
  - enriquecimento automatico
  - template obsidian
  - yaml marcadores
  - regex validacao
  - enum status
  - draft
  - in review
  - approved
  - public
  - internal
  - restricted
  - confidential
  - rastreabilidade fonte
  - linhagem dados
  - captured at
  - source type
  - tags manuais
  - tags geradas ia
  - ordenacao relevancia
  - indice semantico
  - descoberta facetas
  - retrieval hibrido
  - grafo conhecimento
  - filtro pre retrieval
  - campos governanca
  - promocao fase 3
  - campo doc type
  - campo system
  - campo module
  - campo owner
  - campo team
aliases:
  - "ADR-B01"
  - "Schema Front Matter Leve"
  - "Front Matter Leve Especificacao"
  - "Contrato Metadados Beta"
  - "Schema YAML Beta MD"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-B01_schema_front_matter_leve.beta.md"
source_beta_ids:
  - "BETA-B01"
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

# ADR-B01 — Schema do Front Matter Leve (.beta.md)

## 1. Visão Geral

O front matter leve é o contrato de metadados para arquivos `.beta.md` no repositório rag-workspace. Projetado para ser simples o suficiente para que analistas de negócio, POs e especialistas de domínio consigam preencher sem treinamento extenso, usando o Obsidian como editor.

Filosofia: conter o **MÍNIMO NECESSÁRIO** para que o pipeline funcione. Tudo que pode ser inferido ou enriquecido depois fica fora — reduzindo a carga cognitiva do autor humano.

Formato: YAML entre marcadores `---` no início do arquivo (compatível Obsidian).

## 2. Campos — Definição Completa

### 2.1 id (obrigatório, bloqueante)

- **Tipo:** string
- **Formato:** `BETA-{NNN}` (numérico sequencial, 3+ dígitos)
- **Regex:** `^BETA-\d{3,}$`
- **Exemplos:** `id: BETA-001` | `id: BETA-042` | `id: BETA-1337`
- **Validação:** obrigatório (bloqueante), regex, único no repositório workspace
- **Mensagem:** `"Campo 'id' ausente ou formato inválido"`

**Por que existe:**
Identificador único do documento no workspace. Necessário para rastreabilidade, referência cruzada, histórico de enriquecimento e linkagem no Obsidian via `[[BETA-001]]`.

### 2.2 title (obrigatório, bloqueante)

- **Tipo:** string, max 200 caracteres
- **Formato:** texto livre, min 10 chars, max 200 chars
- **Exemplo:** `title: "Processo de conciliação bancária do módulo Cobrança"`
- **Validação:** obrigatório (bloqueante), mínimo 10 caracteres, máximo 200 caracteres, não aceitar títulos genéricos
- **Mensagem:** `"Campo 'title' ausente ou muito curto"`

**Por que existe:**
Título legível do documento. Usado para exibição no Obsidian, contexto para a LLM durante retrieval, identificação humana rápida e resultado de busca.

### 2.3 domain (obrigatório, bloqueante)

- **Tipo:** string, enum aberto (sem lista fixa, com recomendações)
- **Formato:** lowercase, sem espaços (usar hífen), mínimo 2 caracteres
- **Exemplos:** `domain: "financeiro"` | `domain: "tecnologia"` | `domain: "rh"`
- **Validação:** obrigatório (bloqueante), mínimo 2 caracteres, lowercase, sem espaços (usar hífen)
- **Mensagem:** `"Campo 'domain' ausente ou formato inválido"`

**Por que existe:**
Domínio de negócio ao qual o documento pertence. Fundamental para filtro pré-retrieval ([[ADR-004]]), organização do conhecimento, roteamento de agentes e responsabilidade por área.

### 2.4 sources (obrigatório, bloqueante)

- **Tipo:** array de objetos
- **Formato:** YAML array, mínimo 1 elemento
- **Sub-campos:**
  - **type** (obrigatório): formato da fonte original. Valores válidos: `pdf`, `docx`, `xlsx`, `pptx`, `email`, `confluence`, `sharepoint`, `jira`, `clickup`, `transcription`, `web`, `manual`, `md`, `json`, `csv`, `image`, `video`, `audio`
  - **origin** (obrigatório): caminho ou URL da fonte original. Formato livre.
  - **captured_at** (obrigatório): data de captura, formato AAAA-MM-DD.
  - **conversion_quality** (opcional): score 0-100 calculado pelo pipeline na Fase 2.
- **Validação:** obrigatório (bloqueante), array >= 1, cada elemento deve ter `type`, `origin` e `captured_at` válidos
- **Mensagem:** `"Campo 'sources' ausente ou incompleto"`

**Por que existe:**
Registra a linhagem de cada fonte que originou o documento. Permite rastreabilidade completa e cálculo de qualidade de conversão. No `.beta.md`, `conversion_quality` é per-source (dentro de `sources[]`). No `.md` final, é consolidado via `min(sources[].conversion_quality)`.

### 2.5 tags (obrigatório, não-bloqueante)

- **Tipo:** array de strings, mínimo 3 manuais + 50 semânticas (total ~53+)
- **Formato:** cada tag lowercase, sem acentos; termos compostos separados por espaço (ex: `"busca vetorial"`, `"filtro pre-retrieval"`)
- **Ordenação:** por relevância decrescente — índice 0 = mais relevante ao contexto específico do documento
- **Composição:**
  - **a) Tags manuais (autor humano):** mínimo 3, inseridas pelo autor ou curador. Focam em categorização de alto nível e descoberta.
  - **b) Tags semânticas (geradas por IA):** exatamente 50 termos, gerados automaticamente na promoção `.txt` -> `.beta.md`. Extraídos do conteúdo do documento, priorizando termos técnicos e de domínio com maior proximidade ao contexto específico.
- **Validação:** warning se menos de 3 tags manuais, mínimo 3 tags para promoção (bloqueante na Fase 3)

**Por que existe:**
Permite busca por facetas, categorização e descoberta no Obsidian e no retrieval. As tags manuais capturam a intenção do autor; as 50 tags semânticas formam um índice de relevância que alimenta o grafo e melhora a precisão do retrieval híbrido.

### 2.6 status (obrigatório, bloqueante)

- **Tipo:** string (enum)
- **Valores:** `draft` | `in-review` | `approved`
- **Transições:** `draft` -> `in-review` -> `approved`. Retorno: `approved` -> `draft`.
- **Validação:** obrigatório (bloqueante), deve ser um dos 3 valores válidos

**Por que existe:**
Controla o ciclo de vida do `.beta.md`. Somente status `approved` pode ser promovido a `.md` final.

### 2.7 confidentiality (obrigatório, bloqueante)

- **Tipo:** string (enum)
- **Valores:** `public` | `internal` | `restricted` | `confidential`
- **Default:** `internal`
- **Validação:** obrigatório (bloqueante), deve ser um dos 4 valores válidos

**Por que existe:**
Nível de classificação de dados conforme [[ADR-004]]. Determina onde o documento pode ser processado (cloud vs on-premise, conforme [[ADR-002]]) e quem pode acessá-lo.

**EXCEÇÃO** ao princípio "governança só no `.md` final": necessário desde a Fase 2 porque [[ADR-002]] usa `confidentiality` para rotear o documento pela trilha correta e [[ADR-004]] exige classificação antes de qualquer processamento automatizado.

### 2.8 last_enrichment (opcional, não-bloqueante)

- **Tipo:** string (data ISO 8601), formato AAAA-MM-DD
- **Exemplo:** `last_enrichment: "2026-03-18"`

**Por que existe:**
Registra a data da última vez que o pipeline de IA enriqueceu o documento.

### 2.9 last_human_edit (opcional, não-bloqueante)

- **Tipo:** string (data ISO 8601), formato AAAA-MM-DD
- **Exemplo:** `last_human_edit: "2026-03-20"`

**Por que existe:**
Registra a data da última edição humana. Permite priorizar documentos para revisão.

### 2.10 aliases (opcional, não-bloqueante)

- **Tipo:** array de strings
- **Formato:** cada alias de 3-100 caracteres, sem duplicatas
- **Exemplo:** `aliases: ["Conciliação Bancária", "Retorno CNAB"]`

**Por que existe:**
Nomes alternativos reconhecidos nativamente pelo Obsidian para busca e descoberta (quick switcher via Ctrl+O).

## 3. Campos Intencionalmente Ausentes

Os seguintes campos **NÃO** estão no front matter leve:

- **system, module, owner, team:** Campos de governança que exigem conhecimento da estrutura organizacional. Preenchidos na Fase 3 pelo pipeline.
- **valid_from, valid_until, supersedes, superseded_by:** Campos temporais definidos na promoção.
- **qa_score, qa_date, qa_status:** QA só se aplica ao `.md` final.
- **doc_type:** Definido na promoção, pois o conteúdo pode mudar de natureza durante a elaboração.

## 4. Exemplo Completo de .beta.md com Front Matter Leve

```yaml
---
id: BETA-042
title: "Processo de conciliação bancária do módulo Cobrança"
domain: "financeiro"
confidentiality: internal
sources:
  - type: "pdf"
    origin: "sharepoint://financeiro/docs/conciliacao_v3.pdf"
    captured_at: "2026-03-15"
  - type: "transcription"
    origin: "teams://recordings/2026-03-12_reuniao_cobranca.mp4"
    captured_at: "2026-03-12"
tags: [conciliacao, cobranca, bancaria, boleto, retorno, cnab]
aliases: ["Conciliação Bancária", "Retorno CNAB"]
status: in-review
last_enrichment: "2026-03-18"
last_human_edit: "2026-03-20"
---
```

## 5. Template Obsidian Recomendado

```yaml
---
id: BETA-
title: ""
domain: ""
confidentiality: internal
sources:
  - type: ""
    origin: ""
    captured_at: ""
tags: []
aliases: []
status: draft
last_enrichment:
last_human_edit:
---
```

## 6. Regras de Compatibilidade Obsidian

- YAML entre marcadores `---` no início do arquivo
- Tags como array YAML (`tags: [a, b, c]`), NÃO usar sintaxe `#tag` no front matter
- No corpo do documento, tags `#tag` podem ser usadas normalmente
- Wikilinks (`[[BETA-001]]`) apenas no CORPO, nunca no front matter
- Campos personalizados são exibidos no painel Properties sem config adicional
- Não é necessário plugin especial

<!-- conversion_quality: 96 -->
