---
id: ADR-B05
doc_type: adr
title: "Conversão de Formatos RAW para Markdown"
system: RAG Corporativo
module: Conversão de Formatos
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - conversao formatos
  - raw para markdown
  - pipeline fase 2
  - md nativo
  - pdf texto
  - pdf escaneado
  - ocr
  - docx
  - xlsx
  - pptx
  - email
  - transcricao audio
  - transcricao video
  - confluence
  - web scraping
  - json ticket
  - jira
  - clickup
  - csv
  - image
  - manual
  - estrategia conversao
  - qualidade conversao
  - sinais formato
  - gates qualidade
  - thresholds
  - ingestao automatica
  - revisao humana
  - rejeicao fonte
  - pymupdf
  - pdfplumber
  - tesseract
  - azure ai vision
  - pandoc
  - python docx
  - whisper
  - azure speech
  - speech to text
  - diarizacao
  - vlm vision language model
  - readability
  - html markdown
  - ocr confidence
  - resolucao dpi
  - word error rate
  - estilos preservados
  - tabelas convertidas
  - formulas identificadas
  - macros confluence
  - headers email
  - thread email
  - encoding utf 8
  - delimitador csv
  - smartart
  - text boxes
  - iframes
  - paywalls
  - boas praticas
aliases:
  - "ADR-B05"
  - "Conversao Formatos RAW Markdown"
  - "Estratégias de Conversão"
  - "Pipeline de Extração"
  - "Formatos Suportados Pipeline"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-B05_conversao_formatos_raw.beta.md"
source_beta_ids:
  - "BETA-B05"
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

# ADR-B05 — Conversão de Formatos RAW para Markdown

## 1. Visão Geral

Na Fase 2 do pipeline ([[ADR-001]]), fontes diversas são convertidas para `.beta.md`. Cada formato de origem possui características próprias que afetam a qualidade da conversão e exigem estratégias diferentes.

Este documento detalha como converter cada formato RAW para Markdown, quais sinais medem a qualidade da conversão e quais expectativas de fidelidade são realistas.

## 2. Tabela de Conversão por Formato

### 2.1 MD nativo

- **Estratégia:** Sem conversão necessária. Apenas validação de YAML front matter e estrutura.
- **Qualidade:** 100% (automático)

### 2.2 PDF texto (texto selecionável)

- **Estratégia:** Extração de texto via parser PDF (ex: PyMuPDF, pdfplumber). Reconstrução de headings por análise de fonte/tamanho. Conversão de tabelas para formato Markdown. Resolução de links internos.
- **Qualidade:** Tipicamente 80-95%
- **Riscos:** Colunas duplas, headers/footers repetidos, tabelas complexas com merges, watermarks.

### 2.3 PDF escaneado (OCR)

- **Estratégia:** OCR via Tesseract, Azure AI Vision ou similar. Pré-processamento de imagem (deskew, binarização). Pós-processamento linguístico para corrigir erros.
- **Qualidade:** Tipicamente 50-85%
- **Riscos:** Baixa resolução, documentos manuscritos, ruído na imagem, múltiplos idiomas.

### 2.4 DOCX (Microsoft Word)

- **Estratégia:** Conversão determinística via pandoc ou python-docx. Mapeamento de estilos Word para headings Markdown. Extração de tabelas, imagens (com alt text).
- **Qualidade:** Tipicamente 90-100%
- **Riscos:** Estilos customizados não mapeados, text boxes, SmartArt, equações complexas, macros.

### 2.5 XLSX (Microsoft Excel)

- **Estratégia:** Cada aba vira uma seção Markdown com tabela. Fórmulas são registradas como comentários. Células mescladas são resolvidas (expandidas).
- **Qualidade:** Tipicamente 70-90%
- **Riscos:** Fórmulas complexas, gráficos (perdem-se), macros VBA, formatação condicional.

### 2.6 PPTX (Microsoft PowerPoint)

- **Estratégia:** Cada slide vira uma seção Markdown. Notas do apresentador preservadas como blockquotes. Imagens descritas por VLM. Ordem lógica reconstruída.
- **Qualidade:** Tipicamente 60-85%
- **Riscos:** Slides muito visuais (diagramas, infográficos), animações, slides ocultos.

### 2.7 Email

- **Estratégia:** Extração de headers (From, To, Date, Subject). Conversão do corpo HTML para Markdown. Processamento de anexos. Preservação da thread.
- **Qualidade:** Tipicamente 75-90%
- **Riscos:** HTML complexo, imagens inline (base64), assinaturas confundidas com conteúdo.

### 2.8 Transcrição (audio/video)

- **Estratégia:** Speech-to-text via Whisper, Azure Speech, etc. Identificação de falantes (diarization). Inserção de timestamps. Tratamento de sobreposição de falas.
- **Qualidade:** Tipicamente 50-80%
- **Riscos:** Ruído de fundo, múltiplos falantes simultâneos, sotaques, jargão técnico.

### 2.9 Confluence

- **Estratégia:** Extração via API ou export HTML. Conversão HTML->Markdown preservando estrutura. Expansão de macros Confluence. Resolução de links internos.
- **Qualidade:** Tipicamente 75-90%
- **Riscos:** Macros customizadas, plugins de terceiros, páginas com iframes.

### 2.10 Web (páginas da internet)

- **Estratégia:** Extração de conteúdo principal (readability). Remoção de navegação, sidebar, footer, ads. Conversão HTML->Markdown. Resolução de links relativos para absolutos.
- **Qualidade:** Tipicamente 70-90%
- **Riscos:** SPAs, conteúdo carregado via JavaScript, paywalls, captchas.

### 2.11 JSON / Ticket (Jira, ClickUp)

- **Estratégia:** Extração de campos estruturados. Preservação de histórico de mudanças. Extração de comentários com autor e data. Processamento de anexos.
- **Qualidade:** Tipicamente 85-95%
- **Riscos:** Custom fields não mapeados, rich text em descrições, limites de API.

### 2.12 CSV

- **Estratégia:** Detecção de delimitador e encoding. Conversão para tabela Markdown. Inferência de tipos de dados.
- **Qualidade:** Tipicamente 80-95%
- **Riscos:** Campos com quebra de linha, encoding misto, CSVs sem header.

### 2.13 Image

- **Estratégia:** OCR para texto em imagens. Descrição por VLM para diagramas e infográficos. Validação de resolução mínima.
- **Qualidade:** Tipicamente 40-75%
- **Riscos:** Imagens de baixa resolução, diagramas complexos, screenshots de código.

### 2.14 Manual (humano)

- **Estratégia:** Score definido pelo humano (100% do peso).
- **Qualidade:** Definida pelo autor (tipicamente 90-100%)

## 3. Gates de Qualidade (Thresholds)

| Score | Ação |
|-------|------|
| >= 80% | Ingestão automática. `.beta.md` gerado sem intervenção humana. |
| 30% a 79% | Revisão humana obrigatória. `.beta.md` gerado com flag. |
| < 30% | Rejeição. `.beta.md` NÃO gerado. Fonte rejeitada. |

## 4. Boas Práticas para Maximizar Qualidade

- Preferir fontes em formato nativo (MD, DOCX) sempre que possível
- Para PDFs, preferir PDFs com texto selecionável (não escaneados)
- Para transcrições, usar microfones de qualidade e gravar em ambientes silenciosos
- Para imagens, garantir resolução mínima de 300 DPI
- Para CSVs, usar UTF-8 como encoding padrão
- Documentar manualmente `conversion_quality` quando a fonte é "manual"

<!-- conversion_quality: 95 -->
