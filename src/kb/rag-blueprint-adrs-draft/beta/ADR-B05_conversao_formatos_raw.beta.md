---
id: BETA-B05
title: "Conversão de Formatos RAW para Markdown"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-B05_conversao_formatos_raw.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags: [conversao formatos, raw para markdown, pipeline fase 2, md nativo, pdf texto, pdf escaneado, ocr, docx, xlsx, pptx, email, transcricao audio, transcricao video, confluence, web scraping, json ticket, jira, clickup, csv, image, manual, estrategia conversao, qualidade conversao, sinais formato, gates qualidade, thresholds, ingestao automatica, revisao humana, rejeicao fonte, pymupdf, pdfplumber, tesseract, azure ai vision, pandoc, python-docx, whisper, azure speech, speech-to-text, diarizacao, vlm vision language model, readability, html markdown, ocr confidence, resolucao dpi, word error rate, estilos preservados, tabelas convertidas, formulas identificadas, macros confluence, headers email, thread email, encoding utf-8, delimitador csv, smartart, text boxes, iframes, paywalls, boas praticas]
aliases:
  - "ADR-B05"
  - "Conversao Formatos RAW Markdown"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## 1. Visão Geral

Na Fase 2 do pipeline (ADR-001), fontes diversas são convertidas para `.beta.md`. Cada formato de origem possui características próprias que afetam a qualidade da conversão e exigem estratégias diferentes.

Este documento detalha como converter cada formato RAW para Markdown, quais sinais medem a qualidade da conversão e quais expectativas de fidelidade são realistas.

## 2. Tabela de Conversão por Formato

### 2.1 MD nativo

- **Estratégia:** Sem conversão necessária. Apenas validação de YAML front matter e estrutura.
- **Qualidade:** 100% (automático)
- **Observações:** Formato ideal. Se a fonte já é Markdown, o pipeline apenas valida e adiciona front matter leve.

### 2.2 PDF texto (texto selecionável)

- **Estratégia:** Extração de texto via parser PDF (ex: PyMuPDF, pdfplumber). Reconstrução de headings por análise de fonte/tamanho. Conversão de tabelas para formato Markdown. Resolução de links internos.
- **Qualidade:** Tipicamente 80-95%
- **Sinais:**
  - % caracteres reconhecidos (peso 40%)
  - Headings preservados (peso 30%)
  - Tabelas convertidas corretamente (peso 20%)
  - Links preservados (peso 10%)
- **Riscos:** Colunas duplas (layout de 2 colunas), headers/footers repetidos, tabelas complexas com merges, watermarks.

### 2.3 PDF escaneado (OCR)

- **Estratégia:** OCR via Tesseract, Azure AI Vision ou similar. Pré-processamento de imagem (deskew, binarização). Pós-processamento linguístico para corrigir erros.
- **Qualidade:** Tipicamente 50-85% (depende da resolução e qualidade)
- **Sinais:**
  - Confidence do OCR (peso 50%)
  - Resolução DPI — mínimo 300 DPI recomendado (peso 20%)
  - % texto reconhecido vs área de imagem (peso 20%)
  - Idioma detectado corretamente (peso 10%)
- **Riscos:** Baixa resolução, documentos manuscritos, ruído na imagem, múltiplos idiomas no mesmo documento.

### 2.4 DOCX (Microsoft Word)

- **Estratégia:** Conversão determinística via pandoc ou python-docx. Mapeamento de estilos Word para headings Markdown. Extração de tabelas, imagens (com alt text).
- **Qualidade:** Tipicamente 90-100% (conversão mais confiável)
- **Sinais:**
  - Conversão determinística (peso 30%)
  - Estilos preservados (peso 30%)
  - Tabelas convertidas (peso 20%)
  - Imagens com alt text (peso 20%)
- **Riscos:** Estilos customizados não mapeados, text boxes, SmartArt, equações complexas, macros.

### 2.5 XLSX (Microsoft Excel)

- **Estratégia:** Cada aba vira uma seção Markdown com tabela. Fórmulas são registradas como comentários ou notas. Células mescladas são resolvidas (expandidas).
- **Qualidade:** Tipicamente 70-90%
- **Sinais:**
  - Tabelas convertidas corretamente (peso 40%)
  - Fórmulas identificadas e documentadas (peso 20%)
  - Merges resolvidos (peso 20%)
  - Todas as abas processadas (peso 20%)
- **Riscos:** Fórmulas complexas, gráficos (perdem-se), macros VBA, formatação condicional, tabelas dinâmicas.

### 2.6 PPTX (Microsoft PowerPoint)

- **Estratégia:** Cada slide vira uma seção Markdown (heading + conteúdo). Notas do apresentador são preservadas como blockquotes. Imagens descritas por VLM (Vision Language Model). Ordem lógica reconstruída.
- **Qualidade:** Tipicamente 60-85%
- **Sinais:**
  - Slides convertidos (peso 30%)
  - Notas do apresentador extraídas (peso 25%)
  - Imagens descritas (peso 25%)
  - Ordem lógica preservada (peso 20%)
- **Riscos:** Slides muito visuais (diagramas, infográficos), animações, slides ocultos, master slides com conteúdo.

### 2.7 Email

- **Estratégia:** Extração de headers (From, To, Date, Subject). Conversão do corpo HTML para Markdown. Processamento de anexos (cada um como sub-fonte). Preservação da thread (encadeamento de respostas).
- **Qualidade:** Tipicamente 75-90%
- **Sinais:**
  - Headers completos (peso 30%)
  - Corpo HTML->MD com estrutura (peso 30%)
  - Anexos processados (peso 25%)
  - Thread preservada (peso 15%)
- **Riscos:** Emails com HTML complexo, imagens inline (base64), assinaturas confundidas com conteúdo, threads longas com duplicação de texto.

### 2.8 Transcrição (audio/video)

- **Estratégia:** Speech-to-text (STT) via Whisper, Azure Speech, etc. Identificação de falantes (diarization). Inserção de timestamps a cada N segundos ou por turno. Tratamento de sobreposição de falas.
- **Qualidade:** Tipicamente 50-80% (muito dependente de áudio)
- **Sinais:**
  - WER do STT — Word Error Rate (peso 40%)
  - Identificação de falantes (peso 25%)
  - Timestamps preservados (peso 15%)
  - Sobreposição tratada (peso 20%)
- **Riscos:** Ruído de fundo, múltiplos falantes simultâneos, sotaques, jargão técnico, áudio de baixa qualidade, reuniões longas (>1h).

### 2.9 Confluence

- **Estratégia:** Extração via API ou export HTML. Conversão HTML->Markdown preservando estrutura. Expansão de macros Confluence (code blocks, info panels). Resolução de links internos para referências.
- **Qualidade:** Tipicamente 75-90%
- **Sinais:**
  - Estrutura HTML preservada (peso 30%)
  - Macros expandidas (peso 25%)
  - Links internos resolvidos (peso 25%)
  - Anexos processados (peso 20%)
- **Riscos:** Macros customizadas, plugins de terceiros, páginas com iframes, conteúdo dinâmico, restrições de acesso.

### 2.10 Web (páginas da internet)

- **Estratégia:** Extração de conteúdo principal (readability). Remoção de navegação, sidebar, footer, ads. Conversão HTML->Markdown. Resolução de links relativos para absolutos.
- **Qualidade:** Tipicamente 70-90%
- **Sinais:**
  - HTML->MD com estrutura preservada (peso 35%)
  - Navegação/chrome removido (peso 25%)
  - Imagens com alt text (peso 20%)
  - Links resolvidos (peso 20%)
- **Riscos:** SPAs (Single Page Applications), conteúdo carregado via JavaScript, paywalls, captchas, sites com estrutura não-semântica.

### 2.11 JSON / Ticket (Jira, ClickUp)

- **Estratégia:** Extração de campos estruturados (título, descrição, status, prioridade, assignee, labels). Preservação de histórico de mudanças. Extração de comentários com autor e data. Processamento de anexos.
- **Qualidade:** Tipicamente 85-95% (dados estruturados)
- **Sinais:**
  - Campos extraídos completamente (peso 40%)
  - Histórico preservado (peso 25%)
  - Comentários extraídos (peso 20%)
  - Anexos processados (peso 15%)
- **Riscos:** Custom fields não mapeados, rich text em descrições, workflows customizados, limites de API.

### 2.12 CSV

- **Estratégia:** Detecção de delimitador (vírgula, ponto-e-vírgula, tab). Detecção de encoding (UTF-8, Latin-1, etc.). Conversão para tabela Markdown. Inferência de tipos de dados.
- **Qualidade:** Tipicamente 80-95%
- **Sinais:**
  - Headers identificados (peso 30%)
  - Tipos inferidos (peso 25%)
  - Encoding correto (peso 25%)
  - Delimitador detectado (peso 20%)
- **Riscos:** Campos com quebra de linha, encoding misto, CSVs sem header, delimitadores ambíguos, arquivos muito grandes (> 10MB).

### 2.13 Image

- **Estratégia:** OCR para texto em imagens. Descrição por VLM (Vision Language Model) para diagramas e infográficos. Validação de resolução mínima.
- **Qualidade:** Tipicamente 40-75%
- **Sinais:**
  - OCR confidence (peso 50%)
  - Descrição por VLM (peso 30%)
  - Resolução suficiente (peso 20%)
- **Riscos:** Imagens de baixa resolução, diagramas complexos, screenshots de código, textos curvos ou rotacionados.

### 2.14 Manual (humano)

- **Estratégia:** Score definido pelo humano (100% do peso). O autor escreve diretamente em Markdown e atribui manualmente o score de qualidade.
- **Qualidade:** Definida pelo autor (tipicamente 90-100%)
- **Sinais:**
  - Julgamento humano (peso 100%)
- **Riscos:** Subjetividade, inflação de score, falta de calibração.

## 3. Gates de Qualidade (Thresholds)

| Score | Ação |
|-------|------|
| >= 80% | Ingestão automática. `.beta.md` gerado sem intervenção humana. |
| 30% a 79% | Revisão humana obrigatória. `.beta.md` gerado com flag. |
| < 30% | Rejeição. `.beta.md` NÃO gerado. Fonte rejeitada. |

Thresholds configuráveis por organização.

## 4. Boas Práticas para Maximizar Qualidade

- Preferir fontes em formato nativo (MD, DOCX) sempre que possível
- Para PDFs, preferir PDFs com texto selecionável (não escaneados)
- Para transcrições, usar microfones de qualidade e gravar em ambientes silenciosos
- Para imagens, garantir resolução mínima de 300 DPI
- Para CSVs, usar UTF-8 como encoding padrão
- Documentar manualmente `conversion_quality` quando a fonte é "manual"

<!-- conversion_quality: 95 -->
