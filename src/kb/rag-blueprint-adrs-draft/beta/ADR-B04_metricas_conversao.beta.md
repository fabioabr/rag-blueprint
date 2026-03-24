---
id: BETA-B04
title: "Métricas de Conversão (conversion_quality)"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-B04_metricas_conversao.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags: [conversion quality, metricas conversao, score qualidade, formula calculo, media ponderada, penalidade erro critico, consolidacao min, sinais formato, pdf texto, pdf escaneado, ocr, docx, xlsx, pptx, email, transcricao, confluence, web, json ticket, csv, image, manual, thresholds decisao, gates qualidade, ingestao automatica, revisao humana, rejeicao fonte, pipeline fase 2, qa score, per-source, score consolidado, caracteres reconhecidos, headings preservados, tabelas convertidas, links preservados, ocr confidence, resolucao dpi, word error rate, identificacao falantes, timestamps, estilos preservados, imagens alt text, formulas identificadas, merges resolvidos, slides convertidos, notas apresentador, headers email, thread preservada, macros confluence, html markdown, navegacao removida, campos extraidos, historico preservado, delimitador detectado, vlm descricao]
aliases:
  - "ADR-B04"
  - "Metricas Conversion Quality"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## 1. Visão Geral

O campo `conversion_quality` expressa a confiança na fidelidade da conversão da fonte original para o formato `.md`. Score de 0 a 100% calculado pelo pipeline de conversão na Fase 2 (ADR-001).

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

Ou seja, o pior score entre todas as fontes determina o score final. Isso garante que uma fonte de baixa qualidade não seja mascarada por outras de alta qualidade.

## 3. Sinais por Formato de Origem

### 3.1 MD nativo

- **Score:** 100% automático (sem conversão, apenas validação)
- **Sinais:** nenhum — não há conversão

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

Score definido pelo humano (100% do peso). O autor atribui manualmente o score de qualidade.

## 4. Thresholds de Decisão (Gates)

### 4.1 Ingestão automática (>= 80%)

- **Score:** >= 80%
- **Ação:** `.beta.md` gerado e processado sem intervenção humana
- **Status:** `draft` (no `.beta.md`)
- **Pipeline:** continua automaticamente

### 4.2 Revisão humana obrigatória (30% a 79%)

- **Score:** 30% a 79%
- **Ação:** `.beta.md` gerado com flag `requires_human_review`
- **Status:** `draft` (no `.beta.md`)
- **Pipeline:** emite warning com sinais de score baixo
- **Humano:** deve revisar e validar antes de promover

### 4.3 Rejeição (< 30%)

- **Score:** < 30%
- **Ação:** `.beta.md` NÃO gerado
- **Status:** fonte rejeitada
- **Pipeline:** registra log com detalhes dos sinais
- **Humano:** deve providenciar fonte melhor ou conversão manual

### 4.4 Configurabilidade

Os thresholds (80% e 30%) são configuráveis por organização via config do pipeline. Cada organização pode ajustar conforme seu nível de tolerância a risco.

## 5. Relação entre conversion_quality e QA

**conversion_quality:**

- Calculado na Fase 2 (conversão de fonte para `.beta.md`)
- Mede fidelidade da EXTRAÇÃO (fonte original -> markdown)
- Per-source no `.beta.md`, consolidado no `.md` final

**qa_score:**

- Calculado na Fase 3 (promoção de `.beta.md` para `.md`)
- Mede qualidade do CONTEÚDO (completude, clareza, estrutura)
- Aplicado ao documento como um todo

São métricas complementares:

- Um documento pode ter `conversion_quality` alto (boa extração) mas `qa_score` baixo (conteúdo incompleto ou mal estruturado)
- Um documento pode ter `conversion_quality` baixo (extração ruim) mas `qa_score` alto (humano corrigiu e enriqueceu tudo)

## 6. Exemplos Práticos

### 6.1 PDF texto de boa qualidade

```yaml
sources:
  - type: "pdf"
    origin: "sharepoint://financeiro/manual_cobranca_v3.pdf"
    captured_at: "2026-03-15"
    conversion_quality: 92
```

Sinais: 95% chars reconhecidos, headings 100%, tabelas 85%, links 80%

Score: `0.95*0.4 + 1.0*0.3 + 0.85*0.2 + 0.80*0.1 = 0.38+0.30+0.17+0.08 = 93`

Nenhum erro crítico -> score final = 92 (arredondamento)

Gate: >= 80% -> ingestão automática

### 6.2 Transcrição de reunião com ruído

```yaml
sources:
  - type: "transcription"
    origin: "teams://recordings/2026-03-12_reuniao.mp4"
    captured_at: "2026-03-12"
    conversion_quality: 67
```

Sinais: WER 25% (ruim), falantes 80%, timestamps 90%, sobreposição 40%

Score: `0.75*0.4 + 0.80*0.25 + 0.90*0.15 + 0.40*0.20 = 0.30+0.20+0.135+0.08 = 71.5`

Penalidade por WER alto -> score final = 67

Gate: 30-79% -> revisão humana obrigatória

### 6.3 Consolidação para .md final (múltiplas fontes)

```yaml
sources:
  - type: "pdf"    -> conversion_quality: 92
  - type: "transcription" -> conversion_quality: 67
```

`conversion_quality_final = min(92, 67) = 67`

A pior fonte determina o score consolidado.

<!-- conversion_quality: 95 -->
