---
description: "Schema centralizado de validação do front matter — valores válidos por campo para todas as skills de escrita"
---

# Schema de Validação do Front Matter

Todas as skills que geram `.md` formal (doc-writer, adr-writer, gls-writer, rnb-writer) DEVEM consultar este arquivo para validar os valores do front matter antes de gerar o documento.

**Regra:** valores fora das opções listadas são **bloqueantes** — a skill deve reportar o erro e não gerar o arquivo até que o valor seja corrigido.

---

## Campos de Identificação

### `id`
- **Formato:** `{PREFIXO}-{CÓDIGO}`
- **Opções de prefixo:**
  - `RAG-B{NN}` — documentos do blueprint (ex: `RAG-B00`, `RAG-B16`)
  - `ADR-{NNN}` — Architecture Decision Records (ex: `ADR-001`)
  - `GLS-{NNN}` — entradas de glossário (ex: `GLS-001`)
  - `RNB-{NNN}` — runbooks operacionais (ex: `RNB-001`)
  - `DOC-{NNNNNN}` — documentos genéricos (ex: `DOC-000123`)
- **Validação:** deve ser único em todo o repositório

### `doc_type`
- **Opções válidas:**
  - `system-doc` — documentação de sistema
  - `adr` — Architecture Decision Record
  - `runbook` — procedimento operacional
  - `glossary` — entrada de glossário
  - `task-doc` — documentação de tarefa
  - `architecture-doc` — documento de arquitetura
  - `review` — relatório de revisão/análise
- **Bloqueante se inválido:** sim

### `title`
- **Formato:** string livre em pt-BR
- **Validação:** não pode ser vazio, não pode conter apenas espaços

---

## Campos de Classificação

### `system`
- **Formato:** string livre
- **Opções frequentes (não exaustivas):**
  - `RAG Corporativo`
  - (expandir conforme novos sistemas forem documentados)
- **Bloqueante se vazio:** sim

### `module`
- **Formato:** string livre descrevendo o módulo funcional
- **Exemplos:** `Ingestão`, `Busca`, `API`, `Segurança`, `Governança`, `Pipeline`, `Infraestrutura`
- **Bloqueante se vazio:** sim

### `domain`
- **Opções válidas:**
  - `Arquitetura`
  - `Estratégico`
  - `Operacional`
  - `Técnico`
  - `Financeiro`
  - `Comercial`
  - `Regulatório`
- **Bloqueante se inválido:** sim — usar exclusivamente valores da taxonomia corporativa (ver B08, Pendência 9)

### `owner`
- **Formato:** string (username ou nome do responsável)
- **Bloqueante se vazio:** sim

### `team`
- **Opções válidas:**
  - `arquitetura`
  - `engenharia`
  - `dados`
  - `segurança`
  - `operações`
  - `negócios`
  - `compliance`
- **Bloqueante se inválido:** não — novos times podem ser adicionados, mas gerar warning

---

## Campos de Status e Governança

### `status`
- **Opções válidas:**
  - `draft` — rascunho inicial
  - `in-review` — em revisão
  - `approved` — aprovado
  - `deprecated` — descontinuado
- **Bloqueante se inválido:** sim
- **Regra:** documentos recém-convertidos pelo doc-writer DEVEM ter `status: in-review`

### `confidentiality`
- **Opções válidas:**
  - `public` — acesso livre
  - `internal` — uso interno
  - `restricted` — acesso restrito
  - `confidential` — altamente confidencial
- **Bloqueante se inválido:** sim
- **Regra:** impacta diretamente os filtros pré-retrieval no Neo4j

---

## Campos de QA (gerados pelo doc-writer)

### `qa_score`
- **Formato:** inteiro 0-100
- **Origem:** extraído da seção `📊 QUALITY ASSURANCE` do draft
- **Regra:** mínimo 80 para conversão

### `qa_date`
- **Formato:** `AAAA-MM-DD`
- **Origem:** data da última revisão do drf-reviewer

### `qa_status`
- **Opções válidas:**
  - `passed` — QA >= 90%
  - `warning` — QA 80-89% ou links quebrados detectados
  - `not_reviewed` — sem seção QA no draft
- **Bloqueante se inválido:** sim

---

## Campos de Descoberta e Busca

### `tags`
- **Formato:** array de strings
- **Validação:** mínimo 5 tags por documento
- **Tags obrigatórias:** `rag`, `blueprint` (para docs do blueprint)
- **Bloqueante se < 5:** sim

### `aliases`
- **Formato:** array de strings
- **Validação:** mínimo 5 aliases por documento
- **Incluir:** nome curto, código, variações com/sem acento, abreviações
- **Bloqueante se < 5:** sim

---

## Campos de Linhagem

### `source_format`
- **Opções válidas:**
  - `txt` — draft de texto
  - `markdown` — .md nativo (conversion_quality: 100)
  - `pdf` — documento PDF
  - `docx` — documento Word
  - `xlsx` — planilha Excel
  - `eml` — e-mail
  - `json` — dados estruturados (tickets, APIs)
  - `transcript` — transcrição de áudio/vídeo
  - `original` — criado diretamente (ADR, glossário, runbook)
- **Bloqueante se inválido:** sim

### `conversion_quality`
- **Formato:** inteiro 0-100
- **Regra:** 100 para .md nativos e docs criados diretamente

### `conversion_pipeline`
- **Opções válidas:**
  - `manual-v1` — conversão manual via doc-writer
  - `adr-writer-v1` — criação direta via adr-writer
  - `gls-writer-v1` — criação direta via gls-writer
  - `rnb-writer-v1` — criação direta via rnb-writer
  - `automated-v1` — pipeline automatizado (futuro)
- **Bloqueante se inválido:** não — novos pipelines podem surgir

---

## Campos Operacionais (apenas runbooks)

### `severity`
- **Opções válidas:**
  - `low` — baixa severidade
  - `medium` — média severidade
  - `high` — alta severidade
  - `critical` — severidade crítica
- **Bloqueante se inválido:** sim (apenas para `doc_type: runbook`)

### `automation_status`
- **Opções válidas:**
  - `manual` — totalmente manual
  - `partial` — parcialmente automatizado
  - `automated` — totalmente automatizado
- **Bloqueante se inválido:** sim (apenas para `doc_type: runbook`)

### `requires_downtime`
- **Formato:** booleano (`true` ou `false`)
- **Bloqueante se inválido:** sim (apenas para `doc_type: runbook`)

---

## Campos ADR (apenas ADRs)

### `superseded_by`
- **Formato:** ID de outro ADR (ex: `ADR-002`) ou vazio
- **Regra:** se preenchido, o status DEVE ser `deprecated`

### `date_decided`
- **Formato:** `AAAA-MM-DD`
- **Regra:** obrigatório para ADRs com status `approved`

---

## Campos de Data

### `created_at`
- **Formato:** `AAAA-MM-DD`
- **Bloqueante se vazio:** sim

### `updated_at`
- **Formato:** `AAAA-MM-DD`
- **Regra:** deve ser >= `created_at`
- **Bloqueante se vazio:** sim
