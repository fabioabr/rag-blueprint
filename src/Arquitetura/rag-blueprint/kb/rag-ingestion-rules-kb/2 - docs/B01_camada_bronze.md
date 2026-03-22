---
id: RAG-B01
doc_type: architecture-doc
title: "Camada Bronze — Captura de Fontes Originais"
system: RAG Corporativo
module: Camada Bronze
domain: Arquitetura
owner: fabio
team: arquitetura
status: in-review
confidentiality: internal
tags: [rag, blueprint, bronze, fontes, formatos, ingestao]
aliases: ["Camada Bronze", "Bronze", "B01", "Fontes Originais"]
source_format: txt
source_repo: banco-patria
source_path: Arquitetura/rag-blueprint/1 - draft/B01_camada_bronze.txt
conversion_pipeline: manual-v1
conversion_quality: 100
converted_at: 2026-03-18
created_at: 2026-03-18
updated_at: 2026-03-18
---

# 🥉 Camada Bronze — Captura de Fontes Originais

| | |
|---|---|
| 📂 Série | RAG Blueprint Series |
| 📌 Documento | B1 — Camada Bronze |
| 📅 Data | 17/03/2026 |
| 📋 Versão | 1.1 |

---

## 📌 B.1 — Repositório Bronze

O repositório bronze armazena arquivos em seus formatos originais, sem qualquer transformação. É a camada de captura e preservação. Faz parte do modelo [[B00_introducao#Modelo de Camadas|Bronze/Prata/Ouro]] definido em [[ADR-001_pipeline_geracao_conhecimento_4_fases]].

#camada/bronze #fase/1

**Repositório:** `banco-xpto-bronze` (Git + Git LFS para binários)

### Estrutura sugerida

```
banco-xpto-bronze/
├── markdown/           (.md de repositórios Git corporativos)
├── documents/
│   ├── pdf/
│   ├── docx/
│   └── xlsx/
├── tickets/            (exports JSON de ClickUp, Jira)
├── transcripts/        (txt, vtt, srt)
├── emails/             (eml)
└── manifests/          (manifestos de lote)
```

### Requisitos por arquivo

Cada arquivo no bronze deve ter:

- 🔸 Formato original preservado (imutável — nunca editar o original)
- 🔸 Manifesto associado com metadados de captura:

```json
{
  "manifest_id": "MAN-000001",
  "source": "sharepoint | clickup | email | upload-manual",
  "captured_at": "2026-03-18",
  "captured_by": "pipeline-v1 | fabio (manual)",
  "batch_id": "BATCH-2026-03-18-001",
  "file_checksum": "sha256:...",
  "file_format": "pdf",
  "file_size_bytes": 245000,
  "original_path": "\\\\server\\docs\\cobranca\\manual.pdf"
}
```

### Git LFS

- 🔸 Ativar para extensões: `*.pdf`, `*.docx`, `*.xlsx`, `*.pptx`, `*.eml`
- 🔸 Mantém o repo leve enquanto preserva binários grandes

### Princípios da camada bronze

- 🔸 **Imutabilidade** — o original nunca é alterado
- 🔸 **Rastreabilidade** — saber de onde veio, quando e como
- 🔸 **Completude** — tudo que entra no pipeline passa por aqui
- 🔸 **Atenção** — inclusive arquivos `.md` devem passar pela bronze, para que sejam enriquecidos com os metadados necessários

---

## 📌 B.2 — Formatos Suportados

O pipeline de conversão deve suportar os seguintes formatos:

### 📄 MD (Markdown)

- 🔸 Documentação nativa de repositórios Git corporativos
- 🔸 Já é o formato alvo — o pipeline valida, enriquece front matter e encaminha para a [[B02_camada_prata|prata]] (sem etapa de conversão, pula direto para validação/enriquecimento)
- 🔸 `conversion_quality`: 100% (sem conversão de formato)
- 🔸 `source_format`: markdown

### 📄 PDF

- 🔸 Documentação técnica existente, manuais, políticas, contratos
- 🔸 Parser: extração de texto + estrutura (headings, tabelas)
- 🔸 `conversion_quality` esperado: 70-100% (texto nativo), 30-80% (OCR)

### 📝 DOCX

- 🔸 Documentos Word corporativos
- 🔸 Parser: conversão determinística de estrutura
- 🔸 `conversion_quality` esperado: 90-100%

### 📊 XLSX

- 🔸 Planilhas com dados tabulares, relatórios
- 🔸 Parser: extração de tabelas → Markdown tables
- 🔸 `conversion_quality` esperado: 60-95% (depende de complexidade)

### 📧 EML (E-mail)

- 🔸 E-mails corporativos com contexto de decisões
- 🔸 Parser: extrair headers, corpo, anexos
- 🔸 `conversion_quality` esperado: 80-95%
- 🔸 Atenção: LGPD, dados pessoais, ruído — ver [[B14_seguranca_soberania_dados]]

### 🎙️ Transcrições (TXT, VTT, SRT)

- 🔸 Transcrições de reuniões via STT (Speech-to-Text)
- 🔸 Parser: normalizar formato, identificar falantes
- 🔸 `conversion_quality` esperado: 30-90% (depende da qualidade do áudio)

### 📋 JSON (Tickets)

- 🔸 Exports de ClickUp, Jira e ferramentas de gestão
- 🔸 Parser: extrair campos relevantes (título, descrição, resolução)
- 🔸 `conversion_quality` esperado: 85-100% (dados estruturados)

> [!tip] Ver também
> O campo `conversion_quality` e seu cálculo por formato são detalhados em [[B00_introducao#Campo conversion_quality|B00 — Introdução]]. O pipeline de conversão Bronze→Prata está em [[B02_camada_prata]].

> [!warning] Decisão pendente
> Os repositórios alvo para ingestão ainda não foram definidos — ver [[B08_pendencias#✅ Pendencia 5 — Repositorios Alvo|P5 — Repositórios Alvo]].

---

## Documentos relacionados

### Habilita
- [[B02_camada_prata]] — arquivos bronze são a entrada do pipeline de conversão

### Relacionados
- [[B00_introducao]] — define o modelo Bronze/Prata/Ouro (ADR-001)
- [[B03_camada_ouro]] — destino final dos dados após conversão pela prata
- [[B05_knowledge_graph]] — fontes expandidas (PDFs, tickets) passam pela bronze
- [[B08_pendencias]] — P5 (repositórios alvo) e P7 (fontes prioritárias)
- [[B11_deployment_infraestrutura]] — containeriza o pipeline de captura
- [[B14_seguranca_soberania_dados]] — preservação e auditoria de fontes originais
