---
id: ADR-A01
doc_type: adr
title: "Guia de Estrutura de Pastas do Repositório"
system: RAG Corporativo
module: Estrutura de Pastas
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - estrutura de pastas
  - repositorio
  - rag workspace
  - rag knowledge base
  - segregacao confidencialidade
  - base vetorial
  - mcp server
  - pipeline ingestao
  - knowledge base
  - front matter
  - beta md
  - release
  - nomenclatura
  - compliance
  - lgpd
  - bacen
  - service account
  - workspace
  - sources
  - manifesto
  - dominio negocio
  - wikilinks
  - cross ref
  - semver
  - tag release
  - public internal
  - restricted
  - confidential
  - instancia vetorial
  - docs
  - presentations
  - releases
  - manifest yaml
  - changelog
  - release notes
  - fase 1
  - fase 2
  - fase 3
  - fase 4
  - insumos brutos
  - sharepoint
  - confluence
  - transcricoes
  - tickets
  - pipeline promocao
  - segregacao fisica
  - auditabilidade
  - governanca
  - kb nivel 1
  - kb nivel 2
  - kb nivel 3
  - pasta sources
  - pasta beta
aliases:
  - "ADR-A01"
  - "Guia Estrutura Pastas"
  - "Estrutura de Pastas RAG"
  - "Organizacao de Diretorios"
  - "Layout Repositorios RAG"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-A01_guia_estrutura_pastas.beta.md"
source_beta_ids:
  - "BETA-A01"
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

# ADR-A01 — Guia de Estrutura de Pastas do Repositório

## 1. Visão Geral

O projeto RAG Corporativo utiliza dois repositórios Git fisicamente separados, cada um com propósito distinto. A separação física é motivada por compliance regulatório (BACEN, LGPD) e pela necessidade de controlar quem edita o quê.

| Repositório | Propósito |
|---|---|
| rag-workspace | `.beta.md` em trabalho, fontes brutas, logs |
| rag-knowledge-base | `.md` finais (fonte da verdade), apresentações, releases |

**Regra fundamental:** humanos editam no workspace, o pipeline gera no knowledge-base. Ninguém edita manualmente o knowledge-base — todo commit é feito por service account.

## 2. Estrutura do rag-workspace

O workspace é o repositório editável. Aqui ficam os insumos brutos (Fase 1), os `.beta.md` editáveis (Fase 2) e os logs/métricas do processo.

```
rag-workspace/
|-- sources/                          # FASE 1 -- Insumos brutos
|   |-- manifesto.json
|   |-- external/
|   |   |-- regulations/
|   |   |-- vendor-docs/
|   |   +-- web/
|   +-- internal/
|       |-- sharepoint/
|       |-- confluence/
|       |-- emails/
|       |-- transcriptions/
|       |-- documents/
|       +-- tickets/
|-- beta/                             # FASE 2 -- .beta.md editáveis
|   |-- public-internal/              # -> KB Nível 1
|   |   |-- arquitetura/
|   |   |-- operacional/
|   |   |-- glossary/
|   |   |-- apis/
|   |   |-- onboarding/
|   |   +-- faq/
|   |-- restricted/                   # -> KB Nível 2
|   |   |-- financeiro/
|   |   |-- gestao/
|   |   |-- compliance/
|   |   |-- seguranca/
|   |   +-- estrategia/
|   +-- confidential/                 # -> KB Nível 3
|       |-- contratos/
|       |-- estrategia-corporativa/
|       |-- juridico/
|       |-- remuneracao/
|       +-- continuidade/
|-- manifests/
|   |-- public-internal.manifest.yaml
|   |-- restricted.manifest.yaml
|   +-- confidential.manifest.yaml
|-- process/                          # Logs e métricas do processo
|   |-- logs/
|   |-- metrics/
|   +-- reports/
+-- .pipeline/                        # Configuração do pipeline
    |-- templates/
    |-- schemas/
    +-- config.json
```

### 2.1 Pasta sources/

Armazena os insumos brutos da Fase 1 (seleção de fontes). Separada em:

- **external/** — fontes externas (regulações, docs de fornecedores, conteúdo web)
- **internal/** — fontes internas (Sharepoint, Confluence, e-mails, transcrições, documentos diversos, tickets de Jira/ClickUp)

O arquivo `manifesto.json` registra cada fonte com: origem, formato, data de captura, responsável e nível de confidencialidade.

### 2.2 Pasta beta/

Armazena os `.beta.md` editáveis da Fase 2. Organizada em 3 subpastas por nível de confidencialidade (conforme [[ADR-011]]):

- **public-internal/** — documentos PUBLIC e INTERNAL (KB Nível 1)
- **restricted/** — documentos RESTRICTED (KB Nível 2)
- **confidential/** — documentos CONFIDENTIAL (KB Nível 3)

Dentro de cada subpasta, os documentos são organizados por domínio de negócio (ex: `arquitetura/`, `financeiro/`, `operacional/`).

**Regras:**

- Cada documento vive em exatamente uma subpasta de confidencialidade
- A subpasta determina o nível — o front matter deve ser consistente
- Inconsistência entre pasta e front matter = erro de ingestão
- Documentos não podem estar em mais de uma pasta (exceto via `cross_ref`)

### 2.3 Pasta process/

Armazena logs de execução do pipeline, métricas de observabilidade e relatórios de ingestão. Não contém documentos de conhecimento.

### 2.4 Pasta .pipeline/

Configuração do pipeline: templates de front matter, schemas de validação e arquivo de configuração central (`config.json`).

## 3. Estrutura do rag-knowledge-base

O knowledge-base é o repositório imutável. Aqui ficam os `.md` finais (Fase 3) e os snapshots de release (Fase 4). Ninguém edita diretamente — todo commit é feito por pipeline via service account.

```
rag-knowledge-base/
|-- public-internal/                  # -> alimenta Base Vetorial A
|   |-- docs/
|   |-- presentations/
|   +-- releases/
|       +-- v{N.N}/
|           |-- release-notes.md
|           +-- manifest.json
|-- restricted/                       # -> alimenta Base Vetorial B
|   |-- docs/
|   |-- presentations/
|   +-- releases/
+-- confidential/                     # -> alimenta Base Vetorial C
    |-- docs/
    |-- presentations/
    +-- releases/
```

### 3.1 Segregação por Confidencialidade

Replica a mesma estrutura de segregação do workspace:

| Subpasta | Confidencialidade | Base Vetorial |
|---|---|---|
| public-internal/ | PUBLIC + INTERNAL | Instância A |
| restricted/ | RESTRICTED | Instância B |
| confidential/ | CONFIDENTIAL | Instância C |

O pipeline de promoção lê de cada pasta e envia para a Base Vetorial correspondente. Um `.md` em `restricted/docs/` **NUNCA** é enviado para a Base Vetorial A.

### 3.2 Subpastas por KB

Cada subpasta de confidencialidade contém:

- **docs/** — documentos `.md` finais (fonte da verdade)
- **presentations/** — arquivos `.html` standalone gerados a partir dos `.md`
- **releases/** — snapshots de release com `release-notes.md` e `manifest.json`

### 3.3 Releases

Cada release gera um diretório em `releases/` com:

- `release-notes.md` — changelog da versão
- `manifest.json` — lista de documentos incluídos, versão, hash

Releases são independentes por KB ([[ADR-011]]):

- `kb-public-internal@v1.2.0`
- `kb-restricted@v1.0.3`
- `kb-confidential@v1.0.1`

## 4. Convenções de Nomenclatura

### 4.1 Arquivos .beta.md (workspace)

**Formato:** `{dominio}/{nome_descritivo}.beta.md`
**Exemplo:** `beta/public-internal/arquitetura/conciliacao_bancaria.beta.md`

- Nomes em lowercase
- Palavras separadas por underscore
- Extensão sempre `.beta.md`
- Domínio como subpasta

### 4.2 Arquivos .md (knowledge-base)

**Formato:** `{confidencialidade}/docs/{dominio}/{nome_descritivo}.md`
**Exemplo:** `public-internal/docs/arquitetura/conciliacao_bancaria.md`

### 4.3 Identificadores

- `.beta.md`: id no formato `BETA-{NNN}` (ex: BETA-001, BETA-042)
- `.md` final: id no formato `DOC-{NNNNNN}` (ex: DOC-000042)

### 4.4 TAGs de Release

**Formato SemVer:** `v{MAJOR}.{MINOR}.{PATCH}`
**Exemplos:** v1.0.0, v1.2.0, v1.2.1

Para TAGs por KB: `{kb-id}@v{MAJOR}.{MINOR}.{PATCH}`
**Exemplos:** `kb-public-internal@v1.2.0`, `kb-restricted@v1.0.3`

## 5. Mapeamento Pasta -> Base Vetorial -> MCP

| Pasta (workspace) | Pasta (kb) | Base Vetorial | MCP Server |
|---|---|---|---|
| beta/public-internal/ | public-internal/ | Instância A | mcp-knowledge-public |
| beta/restricted/ | restricted/ | Instância B | mcp-knowledge-restricted |
| beta/confidential/ | confidential/ | Instância C | mcp-knowledge-confidential |

## 6. Regras Gerais

- Documentos não podem migrar entre subpastas de confidencialidade sem revisão humana e atualização do front matter
- Wikilinks cross-KB são **PROIBIDOS** (revelam existência de informação restrita)
- Para referências cruzadas entre KBs, usar campo `cross_ref` no front matter
- Inconsistência entre pasta e campo `confidentiality` do front matter é tratada como erro de ingestão (documento rejeitado)
- A pasta `sources/` não possui segregação por confidencialidade — a classificação é feita na geração do `.beta.md` (Fase 2)
- Manifests por KB ficam em `manifests/` no workspace, um por nível

## 7. Referências

- [[ADR-001]] — Pipeline de Geração de Conhecimento em 4 Fases (define estrutura original de pastas e separação em 2 repositórios)
- [[ADR-011]] — Segregação de KBs por Confidencialidade (supercede estrutura de pastas da [[ADR-001]], adicionando camada por nível)
- [[ADR-005]] — Front Matter como Contrato de Metadados (define campos que devem ser consistentes com a pasta)

<!-- conversion_quality: 95 -->
