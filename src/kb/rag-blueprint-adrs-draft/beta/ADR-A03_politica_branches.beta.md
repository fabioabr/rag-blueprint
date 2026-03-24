---
id: BETA-A03
title: "Política de Branches"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-A03_politica_branches.txt"
    captured_at: "2026-03-23"
    conversion_quality: 96
tags: [politica-branches, release-based-flow, protecao-branch, retencao-branch, nomenclatura-branch, rag-workspace, rag-knowledge-base, branch-consolidacao, branch-trabalho, semver, hotfix, tag-release, pipeline-promocao, service-account, curador, pull-request, status-checks, force-push, aprovacao, merge, ciclo-vida-release, staging, qa-score, limpeza-automatica, branches-abandonadas, auditabilidade, git-flow, trunk-based, github-flow, gitlab-flow, base-vetorial, compliance, producao, changelog, release-notes, branch-main, push-direto, contribuidor, po, arquiteto, sincronizacao-tags, dessincronizacao, fast-track, correcao-urgente, release-patch, lowercase, ci-cd, validacao, historico-permanente]
aliases:
  - "ADR-A03"
  - "Politica Branches"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## 1. Visão Geral

Este documento define as regras de proteção, retenção e nomenclatura de branches para os dois repositórios do projeto RAG Corporativo. O modelo adotado é o **Release-Based Flow**, conforme decisão da ADR-010.

O modelo utiliza apenas 2 tipos de branch, priorizando simplicidade para que equipes de negócio (POs, analistas) possam participar sem barreira técnica.

## 2. Modelo de Branching: Release-Based Flow

### 2.1 Tipos de Branch

| Tipo | Propósito |
|---|---|
| `release/v{MAJOR}.{MINOR}.{PATCH}/main` | Branch de consolidação da versão |
| `release/v{MAJOR}.{MINOR}.{PATCH}/{user}/{task}` | Branch de trabalho individual |

Não existem branches `main`, `develop`, `feature/*` ou `hotfix/*` no sentido do Git Flow tradicional. Toda organização de trabalho é feita dentro da árvore de release.

### 2.2 Padrão de Nomenclatura

**Branch de consolidação:**

```
release/v{MAJOR}.{MINOR}.{PATCH}/main
```

**Branch de trabalho:**

```
release/v{MAJOR}.{MINOR}.{PATCH}/{username}/{task-name}
```

**Exemplos:**

```
release/v1.2.0/main
release/v1.2.0/fabio/doc-conciliacao-bancaria
release/v1.2.0/maria/glossario-financeiro
release/v1.2.1/main                          (hotfix)
release/v1.2.1/fabio/fix-pii-doc-financeiro  (hotfix)
```

**Regras de nomenclatura:**

- Tudo em lowercase
- `username` = identificador do contribuidor (sem espaços)
- `task-name` = descrição curta da tarefa com hífens
- CI/CD valida nome da branch no push — rejeita se fora do padrão

## 3. Regras de Proteção

### 3.1 Repositório rag-workspace

**Branch `release/*/main`:**

- Merge apenas via Pull Request
- Mínimo 1 aprovação obrigatória
- Status checks obrigatórios devem passar
- Push direto **PROIBIDO**
- Force push **PROIBIDO**
- Delete **PROIBIDO**
- TAGs criadas apenas pelo Curador (papel definido na ADR-008)

**Branches de trabalho (`release/*/{user}/{task}`):**

- Sem restrição de push (o contribuidor trabalha livremente)
- Merge para `release/*/main` apenas via PR com review

### 3.2 Repositório rag-knowledge-base

**Branch `main` (única branch):**

- Merge apenas via Pull Request
- Mínimo 2 aprovações obrigatórias (PO + Arquiteto)
- Status checks obrigatórios devem passar
- Push direto **PROIBIDO**
- Force push **PROIBIDO**
- Write apenas via service account (pipeline)
- Nenhum humano faz commit direto neste repositório

### 3.3 Resumo Comparativo

| Configuração | workspace release/*/main | knowledge-base main |
|---|---|---|
| Merge via PR | Sim | Sim |
| Aprovações mínimas | 1 | 2 (PO + Arquiteto) |
| Status checks | Obrigatórios | Obrigatórios |
| Push direto | Proibido | Proibido |
| Force push | Proibido | Proibido |
| Delete | Proibido | Proibido |
| Quem pode fazer write | Times de conhecimento | Service account |

## 4. Política de Retenção

### 4.1 Regras por Tipo de Branch

| Tipo de Branch | Retenção |
|---|---|
| `release/vX.Y.Z/main` | **PERMANENTE** (nunca deletar) |
| `release/vX.Y.Z/{user}/{task}` | Deletar após merge + 30 dias |

### 4.2 Automação de Limpeza

- Branches de trabalho mergeadas há mais de 30 dias são deletadas automaticamente
- Alerta automático para branches não-mergeadas há mais de 14 dias (possível branch abandonada)
- Branches `release/*/main` **NUNCA** são deletadas, mesmo após a release ser implantada (histórico permanente)

### 4.3 Justificativa

A retenção permanente de branches `release/*/main` garante:

- Auditabilidade completa (qualquer versão pode ser inspecionada)
- Custo zero de armazenamento no Git (branches são ponteiros)
- Possibilidade de comparação entre releases

A limpeza de branches de trabalho após 30 dias evita:

- Poluição visual na listagem de branches
- Confusão sobre branches ativas vs inativas

## 5. Ciclo de Vida de uma Release

### 5.1 Criação

1. Curador decide iniciar nova versão
2. Curador cria `release/vX.Y.Z/main` a partir da TAG da versão anterior (Exemplo: `release/v1.1.0/main` criado a partir de TAG `v1.0.0`)
3. Contribuidores criam branches de trabalho a partir de `release/vX.Y.Z/main`

### 5.2 Trabalho

4. Cada contribuidor trabalha na sua branch isolada
5. Commits seguem convenções (`tipo: descrição`)
6. PRs abertos para `release/vX.Y.Z/main` com review obrigatório

### 5.3 Consolidação

7. Todas as branches de trabalho mergeadas
8. QA automatizado roda (front matter, QA score >= 90%)
9. Curador gera relatório de release (changelog)

### 5.4 TAG e Promoção

10. Curador cria TAG `vX.Y.Z` no branch `release/vX.Y.Z/main`
11. TAG dispara pipeline de promoção (`.beta.md` -> `.md`)
12. PR automático criado no knowledge-base
13. PO + Arquiteto aprovam
14. Merge no main + TAG espelhada no knowledge-base

### 5.5 Pós-Release

15. Branch `release/vX.Y.Z/main` permanece (retenção permanente)
16. Branches de trabalho são deletadas após 30 dias
17. Nova release começa a partir da TAG recém-criada

## 6. Hotfix: Branch de Correção Urgente

Hotfix segue o mesmo modelo, com release PATCH:

1. Criar `release/vX.Y.Z+1/main` a partir da TAG em produção
2. Criar branch de trabalho `release/vX.Y.Z+1/{user}/{fix}`
3. Aplicar correção, PR com review
4. QA rápido (apenas documentos alterados)
5. TAG e promoção (fast-track: 1 aprovação no knowledge-base)

**Tempo total esperado: 1-4 horas.**

## 7. Sincronização de TAGs entre Repositórios

TAGs devem estar sincronizadas entre rag-workspace e rag-knowledge-base.

- Alerta automático para TAGs dessincronizadas com mais de 24 horas
- TAG no workspace dispara pipeline que cria TAG correspondente no knowledge-base
- Métrica de acompanhamento: TAGs dessincronizadas = 0 (meta)

## 8. Por Que Não Git Flow Tradicional

O Git Flow (Driessen, 2010) define 5 tipos de branch (`main`, `develop`, `feature/*`, `release/*`, `hotfix/*`). Para base de conhecimento, não funciona:

- `develop` é conceito de integração contínua — não faz sentido para documentos promovidos sob demanda
- `main` como "o que está em produção" cria ambiguidade — produção é a Base Vetorial, não um branch
- `feature/*` para cada documento é granulação excessiva
- O fluxo `develop -> release -> main` é linear demais para o pipeline de 4 fases

**Outras alternativas descartadas:**

- **Trunk-Based Development** — sem staging explícito, sem release explícita
- **GitHub Flow** — ausência de releases explícitas
- **GitLab Flow (Environment Branches)** — ambiente da Base Vetorial é por TAG, não por branch

## 9. Referências

- ADR-010 (BETA-010) — Git Flow da Base de Conhecimento (fonte primária: define Release-Based Flow, retenção e proteção)
- ADR-001 (BETA-001) — Pipeline de Geração de Conhecimento em 4 Fases (define separação em 2 repositórios)
- ADR-008 (BETA-008) — Governança: Papéis, Ciclo de Vida e Rollback (define papel do Curador)

<!-- conversion_quality: 96 -->
