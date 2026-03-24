---
id: BETA-B01
title: "Schema do Front Matter Leve (.beta.md)"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-B01_schema_front_matter_leve.txt"
    captured_at: "2026-03-23"
    conversion_quality: 96
tags: [front matter leve, schema yaml, beta-md, campos obrigatorios, campos opcionais, validacao bloqueante, validacao warning, id beta, title, domain, sources array, tags semanticas, status ciclo vida, confidentiality, last enrichment, last human edit, aliases obsidian, conversion quality, pipeline fase 2, obsidian compatibilidade, wikilinks, carga cognitiva, enriquecimento automatico, template obsidian, yaml marcadores, regex validacao, enum status, draft, in-review, approved, public, internal, restricted, confidential, rastreabilidade fonte, linhagem dados, captured at, source type, tags manuais, tags geradas ia, ordenacao relevancia, indice semantico, descoberta facetas, retrieval hibrido, grafo conhecimento, filtro pre-retrieval, campos governanca, promocao fase 3, campo doc type, campo system, campo module, campo owner, campo team]
aliases:
  - "ADR-B01"
  - "Schema Front Matter Leve"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

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
Domínio de negócio ao qual o documento pertence. Fundamental para filtro pré-retrieval (ADR-004), organização do conhecimento, roteamento de agentes e responsabilidade por área.

### 2.4 sources (obrigatório, bloqueante)

- **Tipo:** array de objetos
- **Formato:** YAML array, mínimo 1 elemento
- **Sub-campos:**
  - **type** (obrigatório): formato da fonte original. Valores válidos: `pdf`, `docx`, `xlsx`, `pptx`, `email`, `confluence`, `sharepoint`, `jira`, `clickup`, `transcription`, `web`, `manual`, `md`, `json`, `csv`, `image`, `video`, `audio`
  - **origin** (obrigatório): caminho ou URL da fonte original. Formato livre.
  - **captured_at** (obrigatório): data de captura, formato AAAA-MM-DD.
  - **conversion_quality** (opcional): score 0-100 calculado pelo pipeline na Fase 2.
- **Exemplo:**

```yaml
sources:
  - type: "pdf"
    origin: "sharepoint://financeiro/docs/conciliacao_v3.pdf"
    captured_at: "2026-03-15"
    conversion_quality: 92
  - type: "transcription"
    origin: "teams://recordings/2026-03-12_reuniao.mp4"
    captured_at: "2026-03-12"
    conversion_quality: 67
```

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
  - **b) Tags semânticas (geradas por IA):** exatamente 50 termos, gerados automaticamente na promoção `.txt` -> `.beta.md`. Extraídos do conteúdo do documento, priorizando termos técnicos e de domínio com maior proximidade ao contexto específico. Termos genéricos (ex: "sistema", "processo", "dados") devem ser evitados salvo quando centrais ao doc.
- **Exemplo:** `tags: [pipeline ingestao, chunking semantico, neo4j, embedding, busca vetorial, filtro pre-retrieval, front matter, upsert, idempotencia, grafo conhecimento, ...]`
- **Validação:** warning se menos de 3 tags manuais, mínimo 3 tags para promoção (bloqueante na Fase 3), tags semânticas geradas automaticamente (não bloqueante)
- **Warning:** `"tags: menos de 3 tags manuais. Adicione mais para descoberta."`

**Por que existe:**
Permite busca por facetas, categorização e descoberta no Obsidian e no retrieval. As tags manuais capturam a intenção do autor; as 50 tags semânticas formam um índice de relevância que alimenta o grafo e melhora a precisão do retrieval híbrido. A ordenação por relevância permite que consumidores usem as top-N tags conforme necessidade (ex: top-10 para preview, top-50 para indexação completa).

**Regra de geração das 50 tags semânticas:**

1. Analisar o conteúdo completo do documento
2. Identificar termos técnicos, conceitos de domínio e nomes próprios
3. Incluir termos compostos quando o significado exige (ex: "base vetorial")
4. Ordenar por relevância ao contexto específico do documento
5. Descartar termos excessivamente genéricos
6. Garantir exatamente 50 termos no array de tags semânticas
7. Manter as tags manuais do autor nas primeiras posições
8. Persistir em todos os formatos: `.beta.md`, `.md`, `.html`

### 2.6 status (obrigatório, bloqueante)

- **Tipo:** string (enum)
- **Valores:** `draft` | `in-review` | `approved`
- **Transições:** `draft` -> `in-review` -> `approved`. Retorno: `approved` -> `draft`.
- **Validação:** obrigatório (bloqueante), deve ser um dos 3 valores válidos
- **Mensagem:** `"Campo 'status' ausente ou valor inválido"`

**Por que existe:**
Controla o ciclo de vida do `.beta.md`. Somente status `approved` pode ser promovido a `.md` final.

### 2.7 confidentiality (obrigatório, bloqueante)

- **Tipo:** string (enum)
- **Valores:** `public` | `internal` | `restricted` | `confidential`
- **Default:** `internal`
- **Validação:** obrigatório (bloqueante), deve ser um dos 4 valores válidos
- **Mensagem:** `"Campo 'confidentiality' ausente ou valor inválido"`

**Por que existe:**
Nível de classificação de dados conforme ADR-004. Determina onde o documento pode ser processado (cloud vs on-premise, conforme ADR-002) e quem pode acessá-lo.

**EXCEÇÃO** ao princípio "governança só no `.md` final": necessário desde a Fase 2 porque ADR-002 usa `confidentiality` para rotear o documento pela trilha correta e ADR-004 exige classificação antes de qualquer processamento automatizado.

### 2.8 last_enrichment (opcional, não-bloqueante)

- **Tipo:** string (data ISO 8601), formato AAAA-MM-DD
- **Exemplo:** `last_enrichment: "2026-03-18"`
- **Validação:** data válida se presente
- **Warning:** `"last_enrichment não preenchido. Será atualizado no próximo enriquecimento."`

**Por que existe:**
Registra a data da última vez que o pipeline de IA enriqueceu o documento. Permite identificar documentos que nunca foram enriquecidos ou estagnados.

### 2.9 last_human_edit (opcional, não-bloqueante)

- **Tipo:** string (data ISO 8601), formato AAAA-MM-DD
- **Exemplo:** `last_human_edit: "2026-03-20"`
- **Validação:** data válida se presente
- **Warning:** `"last_human_edit não preenchido. Revisão humana recomendada."`

**Por que existe:**
Registra a data da última edição humana. Permite priorizar documentos para revisão e medir engajamento humano na curadoria.

### 2.10 aliases (opcional, não-bloqueante)

- **Tipo:** array de strings
- **Formato:** cada alias de 3-100 caracteres, sem duplicatas
- **Exemplo:** `aliases: ["Conciliação Bancária", "Retorno CNAB"]`
- **Validação:** opcional, se presente deve ser array de strings sem duplicatas

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

(corpo do documento aqui)

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
