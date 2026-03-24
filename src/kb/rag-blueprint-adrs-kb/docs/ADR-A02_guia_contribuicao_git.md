---
id: ADR-A02
doc_type: adr
title: "Guia de Contribuição Git"
system: RAG Corporativo
module: Contribuição Git
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - contribuicao git
  - pull request
  - commit
  - convencoes commit
  - review
  - rag workspace
  - rag knowledge base
  - service account
  - release
  - branch
  - merge
  - aprovacao
  - status checks
  - hotfix
  - fast track
  - curador
  - po
  - arquiteto
  - revisor
  - contribuidor
  - front matter
  - qa score
  - beta md
  - wikilinks
  - locked blocks
  - pipeline promocao
  - tag release
  - cycle time
  - lead time
  - staging
  - squash
  - atomico
  - pt br
  - task id
  - clickup
  - docs
  - fix
  - meta
  - glossary
  - adr
  - chore
  - retrocompatibilidade
  - governanca
  - auditabilidade
  - rastreabilidade
  - branches abandonadas
  - release based flow
  - pr automatico
  - knowledge base
  - pipeline
aliases:
  - "ADR-A02"
  - "Guia Contribuicao Git"
  - "Convenções de Commit RAG"
  - "Regras de Pull Request"
  - "Processo de Revisão Git"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-A02_guia_contribuicao_git.beta.md"
source_beta_ids:
  - "BETA-A02"
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

# ADR-A02 — Guia de Contribuição Git

## 1. Visão Geral

Este guia define as convenções de commit, regras de Pull Request e processo de revisão para os dois repositórios do projeto RAG Corporativo:

- **rag-workspace** — editável por humanos e pipeline
- **rag-knowledge-base** — editável apenas por pipeline (service account)

As convenções foram definidas na [[ADR-010]] (Git Flow da Base de Conhecimento) com foco em simplicidade, rastreabilidade e auditabilidade.

## 2. Convenções de Commit

### 2.1 Formato da Mensagem

Todos os commits seguem o padrão:

```
{tipo}: {descrição breve}
```

**Regras:**

- Mensagem em pt-BR
- Primeira linha com no máximo 72 caracteres
- Corpo opcional (separado por linha em branco)
- Referenciar task ID quando aplicável (ex: CU-1234)

### 2.2 Tipos de Commit

| Tipo | Descrição | Exemplo |
|---|---|---|
| docs | Criação ou atualização de documento | `docs: adicionar doc de conciliação bancária` |
| fix | Correção de erro em documento existente | `fix: corrigir referência cruzada no glossário` |
| meta | Alteração apenas de front matter/metadados | `meta: atualizar tags do doc de cobrança` |
| glossary | Alteração no glossário | `glossary: adicionar termo soberania de dados` |
| adr | Criação ou atualização de ADR | `adr: criar ADR-012 estratégia de chunking` |
| chore | Alteração de configuração, templates, schemas | `chore: atualizar schema de validação do front matter` |
| hotfix | Correção urgente (apenas em releases de patch) | `hotfix: remover PII do doc financeiro` |

### 2.3 Boas Práticas

- **Commits atômicos:** cada commit deve representar uma única alteração lógica
- Evitar commits tipo "ajustes diversos" ou "WIP" no branch de release
- Se necessário WIP durante trabalho local, fazer squash antes do PR
- Sempre descrever **o que** mudou e **por que** (quando não for óbvio)

## 3. Regras de Pull Request

### 3.1 PR no rag-workspace

Todo merge para o branch `release/vX.Y.Z/main` é feito via Pull Request.

**Requisitos:**

- Mínimo 1 aprovação (review obrigatório)
- Status checks obrigatórios devem passar (validação de front matter, QA)
- Não é permitido commit direto no `release/vX.Y.Z/main`
- Título do PR deve seguir o padrão de commit (`tipo: descrição`)

### 3.2 PR no rag-knowledge-base

PRs no knowledge-base são criados automaticamente pelo pipeline de promoção.

**Requisitos:**

- Mínimo 2 aprovações: PO (conteúdo) + Arquiteto (integridade técnica)
- Status checks obrigatórios devem passar
- Branch main protegida — merge apenas via PR
- Write apenas via service account (pipeline)

### 3.3 PR de Hotfix (Fast-Track)

Para correções urgentes em produção:

- Mínimo 1 aprovação (reduzido de 2 para agilizar)
- Escopo restrito: apenas documentos afetados pelo problema
- QA focado: validação apenas nos documentos alterados
- Tempo esperado total (do início à produção): **1-4 horas**

## 4. Processo de Revisão

### 4.1 O Que Verificar em um Review

**Para documentos (.beta.md):**

- Front matter completo e válido (campos obrigatórios presentes)
- Nível de confidencialidade correto e consistente com a pasta
- Conteúdo claro, sem ambiguidade, em pt-BR
- Wikilinks válidos (formato `[[BETA-NNN]]` para `.beta.md`)
- Blocos LOCKED respeitados (não alterar conteúdo dentro de LOCKED)
- Tags relevantes e em quantidade suficiente (mínimo 3)

**Para configuração (schemas, templates):**

- Retrocompatibilidade com documentos existentes
- Validação de enums e formatos

### 4.2 Papéis no Review

| Papel | Responsabilidade no Review |
|---|---|
| Contribuidor | Criar branch de trabalho, fazer commits, abrir PR |
| Revisor | Aprovar ou solicitar mudanças no PR (min 1 no workspace) |
| Curador | Gerenciar releases, criar TAGs, aprovar promoção |
| PO | Aprovar conteúdo no knowledge-base |
| Arquiteto | Aprovar integridade técnica no knowledge-base |

### 4.3 Fluxo Completo de Contribuição

1. Curador cria branch `release/vX.Y.Z/main` a partir da TAG anterior
2. Contribuidor cria branch `release/vX.Y.Z/{username}/{task-name}`
3. Contribuidor edita `.beta.md` (via Obsidian ou editor de preferência)
4. Contribuidor faz commits seguindo convenções (`tipo: descrição`)
5. Contribuidor abre PR para `release/vX.Y.Z/main`
6. Revisor analisa e aprova (ou solicita mudanças)
7. Merge do PR após aprovação + status checks
8. Repetir para todos os contribuidores da release
9. Curador verifica estado consolidado e QA score
10. Curador cria TAG `vX.Y.Z` quando tudo está aprovado
11. Pipeline gera `.md` finais e cria PR automático no knowledge-base
12. PO + Arquiteto aprovam PR no knowledge-base
13. Merge e TAG espelhada no knowledge-base

## 5. Métricas de Acompanhamento

| Métrica | Descrição | Meta |
|---|---|---|
| Cycle time de PR | Tempo entre abertura e merge do PR | < 2 dias úteis |
| Lead time de release | Tempo entre criação do release/*/main e prod | < 2 semanas |
| Taxa de sucesso em staging | % de TAGs que passam na primeira tentativa | > 80% |
| Branches abandonadas | Branches não-mergeadas há > 14 dias | 0 |

## 6. Referências

- [[ADR-010]] — Git Flow da Base de Conhecimento (define modelo Release-Based Flow, convenções de commit e regras de PR)
- [[ADR-001]] — Pipeline de Geração de Conhecimento em 4 Fases (define separação em 2 repositórios)
- [[ADR-008]] — Governança: Papéis, Ciclo de Vida e Rollback (define papel do Curador e fluxo de aprovação)

<!-- conversion_quality: 95 -->
