---
id: ADR-E02
doc_type: adr
title: "Trigger de Ingestão (Mecanismo de Disparo do Pipeline)"
system: RAG Corporativo
module: Trigger de Ingestão
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - trigger de ingestao
  - mecanismo de disparo
  - release tag
  - webhook
  - manifest json
  - pipeline de ingestao
  - versionamento de release
  - release version
  - rollback
  - base vetorial
  - snapshot do repositorio
  - fluxo de disparo
  - service account
  - schema do manifesto
  - document id
  - classificacao de mudanca
  - hash sha 256
  - integridade de dados
  - gate de qualidade
  - aprovacao de documentos
  - pipeline de promocao
  - rastreabilidade
  - auditoria
  - http 202
  - post admin ingest
  - handler de webhook
  - plataforma git
  - github
  - gitlab
  - repositorio knowledge base
  - no document
  - campos persistidos
  - file hash
  - file path
  - git commit
  - versao semantica
  - timestamp iso 8601
  - created by
  - action new
  - action updated
  - action deleted
  - action unchanged
  - commits intermediarios
  - documentos aprovados
  - pr review
  - rollback seletivo
  - queries administrativas
  - etapa 5 persistencia
  - neo4j
  - versionamento de estado
  - disparo por release
  - manifesto automatico
aliases:
  - "ADR-E02"
  - "Trigger de Ingestão"
  - "Mecanismo de Disparo do Pipeline"
  - "Disparo por Release Tag"
  - "Trigger por Release"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/draft/ADR-E02_trigger_ingestao.txt"
source_beta_ids:
  - "BETA-E02"
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

# ADR-E02 — Trigger de Ingestão (Mecanismo de Disparo do Pipeline)

| Campo | Valor |
|-------|-------|
| **Status** | Accepted |
| **Data da Decisão** | 2026-03-23 |
| **Decisor** | fabio |
| **Escopo** | Trigger de Ingestão |

**Referências Cruzadas:**

- **Depende de:** [[ADR-006]], [[ADR-001]]
- **Relaciona-se:** [[ADR-E01]]

## Sumário

Este documento detalha o mecanismo de disparo (trigger) do pipeline de ingestão, incluindo o fluxo de webhook, o schema do manifest.json e as razões para usar release tags em vez de commits individuais.

## 1. Princípio: Trigger por Release

O pipeline é disparado EXCLUSIVAMENTE por eventos de release no repositório knowledge-base. Não existe processamento contínuo, cron job ou disparo manual em produção.

O trigger por release garante que:
- Apenas documentos aprovados e versionados entram na Base Vetorial.
- Cada execução do pipeline corresponde a um snapshot coerente do repo.
- A versão da release é registrada na Base Vetorial, viabilizando rollback.

## 2. Fluxo de Disparo

Sequência completa:

1. Mantenedor (humano ou pipeline de promoção) cria release tag no repositório knowledge-base (ex: v1.3.0).
2. Plataforma Git envia webhook para o serviço de ingestão.
3. Handler do webhook valida o evento e envia: `POST /admin/ingest` com o payload contendo a versão da release.
4. Pipeline lê o manifesto (manifest.json) correspondente à release.
5. Pipeline inicia as 7 etapas de ingestão.

### Diagrama

```
[Mantenedor]
    |
    | cria release tag v1.3.0
    v
[Plataforma Git (GitHub/GitLab)]
    |
    | webhook POST
    v
[Serviço de Ingestão - Handler]
    |
    | POST /admin/ingest {version: "1.3.0"}
    v
[Pipeline 7 Etapas]
    |
    | lê releases/v1.3/manifest.json
    v
[Execução: Descoberta -> Parse -> ... -> Observabilidade]
```

## 3. Manifest.json — Schema e Geração

### Quem gera o manifest.json

Gerado AUTOMATICAMENTE pelo pipeline de promoção (Fase 3, [[ADR-001]]) no momento da criação da release tag. Não é um arquivo editado manualmente.

Assinado pela service account do pipeline de promoção.

### Conteúdo do manifesto

Para cada arquivo .md incluído na release, o manifesto registra:
- `path`: caminho relativo no repositório
- `document_id`: identificador único do documento
- `action`: classificação da mudança (new, updated, deleted, unchanged)
- `hash SHA-256`: para verificação de integridade na Etapa 1 (Descoberta)
- `doc_type`: tipo do documento
- `last_modified`: data da última modificação

### Estrutura do JSON

```json
{
  "version": "1.3.0",
  "created_at": "2026-03-21T10:00:00Z",
  "created_by": "pipeline-service-account",
  "documents": [
    {
      "path": "docs/financeiro/modulo-cobranca.md",
      "document_id": "DOC-000123",
      "action": "updated"
    },
    {
      "path": "docs/financeiro/modulo-pagamentos.md",
      "document_id": "DOC-000124",
      "action": "new"
    },
    {
      "path": "docs/rh/politica-ferias.md",
      "document_id": "DOC-000089",
      "action": "deleted"
    }
  ]
}
```

### Campos do manifesto

| Campo | Descrição |
|-------|-----------|
| `version` | Versão semântica da release (ex: "1.3.0") |
| `created_at` | Timestamp ISO 8601 da geração do manifesto |
| `created_by` | Identidade da service account que gerou |
| `documents[]` | Array de objetos, um por documento .md |
| `documents[].path` | Caminho relativo do arquivo no repo |
| `documents[].document_id` | ID único do documento (ex: "DOC-000123") |
| `documents[].action` | Classificação: new / updated / deleted / unchanged |

## 4. Por que Release e não Commit

Razões para usar release tag como trigger (e não commits individuais):

1. **Nem todo commit é "pronto":** Commits intermediários podem conter documentos incompletos, em revisão ou com erros. Uma release representa um conjunto curado e aprovado.

2. **Releases representam conjuntos aprovados:** A release tag é criada após o processo de aprovação (PR review por PO + Arquiteto, conforme Fase 3 da [[ADR-001]]). O trigger por release garante que só documentos que passaram pelo gate de qualidade entram na Base Vetorial.

3. **Versionamento do estado da Base Vetorial:** A release tag permite versionar o estado completo da Base Vetorial. Campo `release_version` é armazenado em cada nó Document, permitindo saber exatamente qual release gerou aquele estado.

4. **Facilita rollback:** Se uma release introduz problemas, é possível re-executar o pipeline com a release anterior para restaurar o estado. O versionamento por release torna o rollback previsível e auditável.

## 5. Armazenamento da release_version

O campo `release_version` é registrado em cada nó Document na Base Vetorial durante a Etapa 5 (Persistência). Isso permite:

- Rastrear qual release gerou cada documento na Base Vetorial.
- Identificar documentos de releases específicas para auditoria.
- Facilitar rollback seletivo ou completo.
- Queries administrativas (ex: "quais documentos entraram na v1.3.0?").

Campos relacionados persistidos no nó Document:
- `release_version`: versão da release (ex: "1.3.0")
- `file_hash`: SHA-256 do conteúdo no momento da ingestão
- `file_path`: caminho do arquivo no repositório
- `git_commit`: hash do commit associado

<!-- conversion_quality: 95 -->
