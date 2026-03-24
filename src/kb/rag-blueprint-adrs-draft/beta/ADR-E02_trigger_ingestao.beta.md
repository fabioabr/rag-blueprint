---
id: BETA-E02
title: "Trigger de Ingestao (Mecanismo de Disparo do Pipeline)"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-E02_trigger_ingestao.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
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
  - hash sha-256
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
  - fase 3
  - adr-001
  - adr-006
  - neo4j
aliases:
  - "ADR-E02"
  - "Trigger de Ingestao"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## Sumario

Este documento detalha o mecanismo de disparo (trigger) do pipeline de ingestao, incluindo o fluxo de webhook, o schema do manifest.json e as razoes para usar release tags em vez de commits individuais.

## 1. Principio: Trigger por Release

O pipeline e disparado EXCLUSIVAMENTE por eventos de release no repositorio knowledge-base. Nao existe processamento continuo, cron job ou disparo manual em producao.

O trigger por release garante que:
- Apenas documentos aprovados e versionados entram na Base Vetorial.
- Cada execucao do pipeline corresponde a um snapshot coerente do repo.
- A versao da release e registrada na Base Vetorial, viabilizando rollback.

## 2. Fluxo de Disparo

Sequencia completa:

1. Mantenedor (humano ou pipeline de promocao) cria release tag no repositorio knowledge-base (ex: v1.3.0).
2. Plataforma Git envia webhook para o servico de ingestao.
3. Handler do webhook valida o evento e envia: `POST /admin/ingest` com o payload contendo a versao da release.
4. Pipeline le o manifesto (manifest.json) correspondente a release.
5. Pipeline inicia as 7 etapas de ingestao.

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
[Servico de Ingestao - Handler]
    |
    | POST /admin/ingest {version: "1.3.0"}
    v
[Pipeline 7 Etapas]
    |
    | le releases/v1.3/manifest.json
    v
[Execucao: Descoberta -> Parse -> ... -> Observabilidade]
```

## 3. Manifest.json -- Schema e Geracao

### Quem gera o manifest.json

Gerado AUTOMATICAMENTE pelo pipeline de promocao (Fase 3, ADR-001) no momento da criacao da release tag. Nao e um arquivo editado manualmente.

Assinado pela service account do pipeline de promocao.

### Conteudo do manifesto

Para cada arquivo .md incluido na release, o manifesto registra:
- `path`: caminho relativo no repositorio
- `document_id`: identificador unico do documento
- `action`: classificacao da mudanca (new, updated, deleted, unchanged)
- `hash SHA-256`: para verificacao de integridade na Etapa 1 (Descoberta)
- `doc_type`: tipo do documento
- `last_modified`: data da ultima modificacao

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

| Campo | Descricao |
|-------|-----------|
| `version` | Versao semantica da release (ex: "1.3.0") |
| `created_at` | Timestamp ISO 8601 da geracao do manifesto |
| `created_by` | Identidade da service account que gerou |
| `documents[]` | Array de objetos, um por documento .md |
| `documents[].path` | Caminho relativo do arquivo no repo |
| `documents[].document_id` | ID unico do documento (ex: "DOC-000123") |
| `documents[].action` | Classificacao: new / updated / deleted / unchanged |

## 4. Por que Release e nao Commit

Razoes para usar release tag como trigger (e nao commits individuais):

1. **Nem todo commit e "pronto":** Commits intermediarios podem conter documentos incompletos, em revisao ou com erros. Uma release representa um conjunto curado e aprovado.

2. **Releases representam conjuntos aprovados:** A release tag e criada apos o processo de aprovacao (PR review por PO + Arquiteto, conforme Fase 3 da ADR-001). O trigger por release garante que so documentos que passaram pelo gate de qualidade entram na Base Vetorial.

3. **Versionamento do estado da Base Vetorial:** A release tag permite versionar o estado completo da Base Vetorial. Campo `release_version` e armazenado em cada no Document, permitindo saber exatamente qual release gerou aquele estado.

4. **Facilita rollback:** Se uma release introduz problemas, e possivel re-executar o pipeline com a release anterior para restaurar o estado. O versionamento por release torna o rollback previsivel e auditavel.

## 5. Armazenamento da release_version

O campo `release_version` e registrado em cada no Document na Base Vetorial durante a Etapa 5 (Persistencia). Isso permite:

- Rastrear qual release gerou cada documento na Base Vetorial.
- Identificar documentos de releases especificas para auditoria.
- Facilitar rollback seletivo ou completo.
- Queries administrativas (ex: "quais documentos entraram na v1.3.0?").

Campos relacionados persistidos no no Document:
- `release_version`: versao da release (ex: "1.3.0")
- `file_hash`: SHA-256 do conteudo no momento da ingestao
- `file_path`: caminho do arquivo no repositorio
- `git_commit`: hash do commit associado

<!-- conversion_quality: 95 -->
