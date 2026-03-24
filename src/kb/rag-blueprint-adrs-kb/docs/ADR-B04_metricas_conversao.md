---
id: ADR-B04
doc_type: adr
title: "Métricas de Conversão (conversion_quality)"
system: RAG Corporativo
module: Métricas de Conversão
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - conversion quality
  - metricas conversao
  - score qualidade
  - formula calculo
  - media ponderada
  - penalidade erro critico
  - consolidacao min
  - sinais formato
  - pdf texto
  - pdf escaneado
  - ocr
  - docx
  - xlsx
  - pptx
  - email
  - transcricao
  - confluence
  - web
  - json ticket
  - csv
  - image
  - manual
  - thresholds decisao
  - gates qualidade
  - ingestao automatica
  - revisao humana
  - rejeicao fonte
  - pipeline fase 2
  - qa score
  - per source
  - score consolidado
  - caracteres reconhecidos
  - headings preservados
  - tabelas convertidas
  - links preservados
  - ocr confidence
  - resolucao dpi
  - word error rate
  - identificacao falantes
  - timestamps
  - estilos preservados
  - imagens alt text
  - formulas identificadas
  - merges resolvidos
  - slides convertidos
  - notas apresentador
  - headers email
  - thread preservada
  - macros confluence
  - html markdown
  - navegacao removida
  - campos extraidos
  - historico preservado
  - delimitador detectado
  - vlm descricao
aliases:
  - "ADR-B04"
  - "Metricas Conversion Quality"
  - "Qualidade de Conversão"
  - "Score de Fidelidade Conversão"
  - "Gates de Qualidade Pipeline"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-B04_metricas_conversao.beta.md"
source_beta_ids:
  - "BETA-B04"
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

# ADR-B04 — Métricas de Conversão (conversion_quality)

## 1. Visão Geral

O campo `conversion_quality` expressa a confiança na fidelidade da conversão da fonte original para o formato `.md`. Score de 0 a 100% calculado pelo pipeline de conversão na Fase 2 ([[ADR-001]]).

Dois níveis de registro:

- No `.beta.md`: `conversion_quality` é **PER-SOURCE** (dentro de `sources[]`)
- No `.md` final: `conversion_quality` é **CONSOLIDADO** via `min(sources[].conversion_quality)`

## 2. Fórmula de Cálculo

```
conversion_quality = min(
    media_ponderada(sinais_do_formato),
    penalidade_por_erro_critico
)
```

A função `min()` garante que um erro crítico **SEMPRE** reduz o score, mesmo que os outros sinais sejam bons.

**Consolidação para `.md` final:**

```
conversion_quality_final = min(sources[].conversion_quality)
```

## 3. Sinais por Formato de Origem

### 3.1 MD nativo

- **Score:** 100% automático (sem conversão, apenas validação)

### 3.2 PDF texto

| Sinal | Peso |
|-------|------|
| % caracteres reconhecidos | 40% |
| Headings preservados | 30% |
| Tabelas convertidas | 20% |
| Links preservados | 10% |

### 3.3 PDF escaneado (OCR)

| Sinal | Peso |
|-------|------|
| Confidence do OCR | 50% |
| Resolução DPI | 20% |
| % texto reconhecido | 20% |
| Idioma detectado corretamente | 10% |

### 3.4 DOCX

| Sinal | Peso |
|-------|------|
| Conversão determinística | 30% |
| Estilos preservados | 30% |
| Tabelas convertidas | 20% |
| Imagens com alt text | 20% |

### 3.5 XLSX

| Sinal | Peso |
|-------|------|
| Tabelas convertidas | 40% |
| Fórmulas identificadas | 20% |
| Merges resolvidos | 20% |
| Abas processadas | 20% |

### 3.6 PPTX

| Sinal | Peso |
|-------|------|
| Slides convertidos | 30% |
| Notas do apresentador | 25% |
| Imagens descritas | 25% |
| Ordem lógica preservada | 20% |

### 3.7 Email

| Sinal | Peso |
|-------|------|
| Headers completos | 30% |
| Corpo HTML->MD | 30% |
| Anexos processados | 25% |
| Thread preservada | 15% |

### 3.8 Transcrição (audio/video)

| Sinal | Peso |
|-------|------|
| WER do STT (Word Error Rate) | 40% |
| Identificação de falantes | 25% |
| Timestamps preservados | 15% |
| Sobreposição de falantes | 20% |

### 3.9 Confluence

| Sinal | Peso |
|-------|------|
| Estrutura HTML preservada | 30% |
| Macros expandidas | 25% |
| Links internos resolvidos | 25% |
| Anexos processados | 20% |

### 3.10 Web

| Sinal | Peso |
|-------|------|
| HTML->MD com estrutura | 35% |
| Navegação removida | 25% |
| Imagens com alt text | 20% |
| Links resolvidos | 20% |

### 3.11 JSON / Ticket (Jira, ClickUp)

| Sinal | Peso |
|-------|------|
| Campos extraídos | 40% |
| Histórico preservado | 25% |
| Comentários extraídos | 20% |
| Anexos processados | 15% |

### 3.12 CSV

| Sinal | Peso |
|-------|------|
| Headers identificados | 30% |
| Tipos inferidos | 25% |
| Encoding correto | 25% |
| Delimitador detectado | 20% |

### 3.13 Image

| Sinal | Peso |
|-------|------|
| OCR confidence | 50% |
| Descrição por VLM | 30% |
| Resolução suficiente | 20% |

### 3.14 Manual

Score definido pelo humano (100% do peso).

## 4. Thresholds de Decisão (Gates)

| Score | Ação |
|-------|------|
| >= 80% | Ingestão automática. `.beta.md` gerado sem intervenção humana. |
| 30% a 79% | Revisão humana obrigatória. `.beta.md` gerado com flag. |
| < 30% | Rejeição. `.beta.md` NÃO gerado. Fonte rejeitada. |

Thresholds configuráveis por organização.

## 5. Relação entre conversion_quality e QA

- **conversion_quality:** calculado na Fase 2, mede fidelidade da EXTRAÇÃO
- **qa_score:** calculado na Fase 3, mede qualidade do CONTEÚDO

São métricas complementares — um documento pode ter boa extração mas conteúdo incompleto, ou vice-versa.

<!-- conversion_quality: 95 -->
