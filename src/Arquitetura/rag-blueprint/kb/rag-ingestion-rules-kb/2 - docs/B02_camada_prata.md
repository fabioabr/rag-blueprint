---
id: RAG-B02
doc_type: architecture-doc
title: "Camada Prata — Pipeline de Conversão e Markdown Normalizado"
system: RAG Corporativo
module: Camada Prata
domain: Arquitetura
owner: fabio
team: arquitetura
status: in-review
confidentiality: internal
tags: [rag, blueprint, prata, conversao, pipeline, front-matter]
aliases: ["Camada Prata", "Prata", "B02", "Pipeline de Conversão"]
source_format: txt
source_repo: banco-patria
source_path: Arquitetura/rag-blueprint/1 - draft/B02_camada_prata.txt
conversion_pipeline: manual-v1
conversion_quality: 100
converted_at: 2026-03-18
created_at: 2026-03-18
updated_at: 2026-03-18
---

# 🥈 Camada Prata — Pipeline de Conversão e Markdown Normalizado

| | |
|---|---|
| 📂 Série | RAG Blueprint Series |
| 📌 Documento | B2 — Camada Prata |
| 📅 Data | 17/03/2026 |
| 📋 Versão | 1.1 |

---

## 📌 P.1 — Pipeline de Conversão Bronze → Prata

O pipeline de conversão transforma fontes da [[B01_camada_bronze|Camada Bronze]] em `.md` padronizado na prata. É o ponto de normalização: formatos diversos entram, Markdown estruturado sai. Após normalização, os `.md` alimentam a [[B03_camada_ouro|Camada Ouro]].

#camada/prata #fase/1

### Etapa B→P.1 — Descoberta de Fontes

- 🔸 Monitorar repositório bronze por arquivos novos/alterados
- 🔸 Ler manifestos para identificar formato e origem
- 🔸 Filtrar por formatos suportados pelo pipeline
- 🔸 Comparar checksum com última conversão para evitar retrabalho

### Etapa B→P.2 — Extração de Conteúdo

- 🔸 **MD**: validar estrutura, preservar conteúdo original
- 🔸 **PDF**: extrair texto, headings, tabelas, imagens (se aplicável)
- 🔸 **DOCX**: converter estrutura Word → Markdown
- 🔸 **XLSX**: extrair tabelas → Markdown tables
- 🔸 **EML**: extrair headers, corpo, processar anexos
- 🔸 **Transcrições**: normalizar formato, identificar falantes
- 🔸 **JSON/Tickets**: extrair campos relevantes
- 🔸 Preservar hierarquia de seções (h1, h2, h3)
- 🔸 Converter tabelas para formato Markdown
- 🔸 Registrar avisos de extração (caracteres ilegíveis, etc.)

### Etapa B→P.3 — Geração de Front Matter

- 🔸 Gerar front matter padrão com campos obrigatórios:
  - `id`, `doc_type`, `title`, `status`, `confidentiality`, etc.
- 🔸 Inferir campos quando possível (título do PDF, autor, etc.)
- 🔸 Adicionar campos de linhagem obrigatórios:
  - `source_format`, `source_repo`, `source_path`, `source_hash`
  - `conversion_pipeline`, `conversion_model` (se usou LLM)
  - `conversion_quality` (0-100%)
  - `converted_at`
- 🔸 Documentos com quality < threshold → `status: draft` (requerem revisão humana antes de serem ingeridos na ouro)

### Etapa B→P.4 — Cálculo de conversion_quality (0-100%)

Score contínuo (0-100%) que expressa confiança na fidelidade da conversão.

**Fórmula:** média ponderada dos sinais aplicáveis ao formato. Cada sinal produz um score parcial 0-100%. O score final é `min(média_dos_sinais, penalidade_por_erro_crítico)` — ou seja, um erro crítico (ex: encoding corrompido) derruba o score mesmo que os outros sinais estejam bons.

Para MVP, a implementação pode ser simplificada: score binário por sinal (0 ou 100%) com média simples. Refinamento com pesos em Fase 2.

**Sinais por formato:**

| Formato | Sinais |
|---------|--------|
| 📄 MD | 100% (validação de estrutura) |
| 📄 PDF texto | % caracteres reconhecidos, estrutura ok |
| 📄 PDF OCR | confidence do OCR, resolução da imagem |
| 📝 DOCX | ~100% (conversão determinística) |
| 📊 XLSX | complexidade fórmulas/merges, % tabelas |
| 📧 EML | completude headers, anexos processados |
| 🎙️ Transcrição | word error rate, sobreposição falantes |
| 📋 JSON/Ticket | completude dos campos extraídos |

**Regras de threshold:**

| Faixa | Ação |
|-------|------|
| >= 80% | `status: in-review` (ingestão automática) |
| 30-79% | `status: draft` (revisão humana obrigatória) |
| < 30% | Rejeitado (log de erro, não gera `.md`) |

### Etapa B→P.5 — Persistência na Prata

- 🔸 Salvar `.md` no repositório prata com front matter completo
- 🔸 Organizar por domínio/sistema (espelhando estrutura bronze)
- 🔸 Commit automático com referência ao `batch_id` e `source_hash`
- 🔸 Log de conversão: formato, quality, warnings

### Observabilidade do pipeline Bronze→Prata

- 🔸 Arquivos processados por execução (por formato)
- 🔸 Taxa de sucesso/falha de conversão
- 🔸 Distribuição de `conversion_quality` por formato
- 🔸 Arquivos rejeitados (quality < 30%)
- 🔸 Arquivos encaminhados para revisão humana

---

## 📌 P.2 — Repositório Prata e Front Matter

O repositório prata contém exclusivamente `.md` com front matter padronizado. É a camada de normalização — o contrato entre as fontes diversas e o pipeline de ingestão para o Neo4j (ver [[B03_camada_ouro]]).

Toda fonte — independente do formato original — passa pelo bronze e é convertida para `.md` antes de chegar aqui.

### Front matter obrigatório

Todo `.md` na prata deve conter:

```json
{
  "id": "DOC-000123",
  "doc_type": "system-doc",
  "title": "Módulo de Cobrança",
  "system": "Sistema Exemplo",
  "module": "Cobranca",
  "domain": "Financeiro",
  "owner": "fabio",
  "team": "arquitetura",
  "status": "approved",
  "confidentiality": "internal",
  "tags": ["boleto", "remessa", "cobranca"],
  "created_at": "2026-03-17",
  "updated_at": "2026-03-17"
}
```

### Campos de linhagem (obrigatórios — todo documento passa pelo bronze)

```json
{
  "source_format": "pdf",
  "source_repo": "banco-xpto-bronze",
  "source_path": "documents/pdf/cobranca/manual.pdf",
  "source_hash": "sha256:abc123...",
  "conversion_pipeline": "v1.0",
  "conversion_model": "gpt-4o",
  "conversion_quality": 92.5,
  "converted_at": "2026-03-17"
}
```

### Tipos válidos para doc_type

- 🔸 `system-doc`
- 🔸 `adr`
- 🔸 `runbook`
- 🔸 `glossary`
- 🔸 `task-doc`
- 🔸 `architecture-doc`

### Status válidos

- 🔸 `draft` — rascunho ou conversão de baixa confiança
- 🔸 `in-review` — aguardando revisão
- 🔸 `approved` — aprovado para uso
- 🔸 `deprecated` — descontinuado

### Níveis de confidencialidade

- 🔸 `public` — acesso livre
- 🔸 `internal` — uso interno
- 🔸 `restricted` — acesso restrito
- 🔸 `confidential` — altamente confidencial

> [!warning] Decisão pendente
> A linguagem/stack do pipeline de conversão ainda não foi definida — ver [[B08_pendencias#✅ Pendencia 4 — Linguagem e Stack do Pipeline|P4 — Stack do Pipeline]].

> [!tip] Ver também
> O front matter é validado e expandido na [[B04_metadados_governanca|Fase 2 — Metadados Fortes]]. Os níveis de confidencialidade são detalhados em [[B14_seguranca_soberania_dados]].

---

## Documentos relacionados

### Depende de
- [[B01_camada_bronze]] — fornece as fontes originais para conversão

### Habilita
- [[B03_camada_ouro]] — o `.md` normalizado é a entrada do pipeline de ingestão

### Relacionados
- [[B00_introducao]] — define o modelo Bronze/Prata/Ouro (ADR-001)
- [[B04_metadados_governanca]] — valida e expande o front matter gerado nesta camada
- [[B08_pendencias]] — P4 (stack do pipeline de conversão)
- [[B11_deployment_infraestrutura]] — containeriza o pipeline de conversão
- [[B13_operacoes]] — ciclo de vida dos documentos prata
