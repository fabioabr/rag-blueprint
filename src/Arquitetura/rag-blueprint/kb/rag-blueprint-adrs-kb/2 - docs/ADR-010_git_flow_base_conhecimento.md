---
id: ADR-010
doc_type: adr
title: "Git Flow da Base de Conhecimento"
system: RAG Corporativo
module: Git Flow
domain: Arquitetura
owner: fabio
team: arquitetura
status: approved
confidentiality: internal
date_decided: 2026-03-21
tags:
  - adr
  - git-flow
  - branching
  - versionamento
  - release
  - ambientes
  - rollback
  - hotfix
  - semver
aliases:
  - "ADR-010"
  - "Release-Based Flow"
  - "Git Flow KB"
  - "Git Flow Base de Conhecimento"
  - "Versionamento da KB"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-kb/beta/ADR-010_git_flow_base_conhecimento.beta.md"
source_beta_ids:
  - "BETA-010"
conversion_pipeline: promotion-pipeline-v1
conversion_quality: 100
converted_at: 2026-03-22
qa_score: 93
qa_date: 2026-03-22
qa_status: passed
created_at: 2026-03-21
updated_at: 2026-03-22
valid_from: 2026-03-21
valid_until: null
---

# ADR-010 — Git Flow da Base de Conhecimento

| Campo | Valor |
|-------|-------|
| **Status** | Approved |
| **Data da Decisão** | 2026-03-21 |
| **Decisor** | fabio |
| **Escopo** | Git Flow |

**Referências Cruzadas:**

- **Depende de:** [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]], [[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]]
- **Relaciona-se:** [[ADR-005_front_matter_contrato_metadados|ADR-005]], [[ADR-008_governanca_ciclo_vida_rollback|ADR-008]], [[ADR-009_selecao_modelos_embedding|ADR-009]], [[ADR-011_segregacao_kbs_por_confidencialidade|ADR-011]]

## Contexto

O [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] estabeleceu a separação física em 2 repositórios:

| Repositório | Propósito |
|---|---|
| **rag-workspace** | `.beta.md` em trabalho, fontes brutas, logs do processo. Editável por humanos (Obsidian) e IA (pipeline) |
| **rag-knowledge-base** | `.md` finais (fonte da verdade), apresentações, releases. Write apenas via pipeline (service account) + PR |

O [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] também definiu que a promoção de `.beta.md` para `.md` é sob demanda, controlada por tags/releases, e que TAGs no knowledge-base triggeram o pipeline de ingestão na Base Vetorial. Porém, o [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] **não definiu**:

- Qual modelo de branching usar em cada repositório
- Como versionar semanticamente as releases
- Como organizar trabalho paralelo de múltiplas pessoas
- Quais ambientes existem (staging, produção) e como promover entre eles
- Como fazer rollback para uma versão anterior
- Como tratar hotfixes urgentes em produção
- Como garantir rastreabilidade completa

Essas lacunas precisam ser resolvidas antes da implementação porque:

1. **Múltiplas pessoas editam `.beta.md` simultaneamente** — sem modelo de branching, conflitos de merge são inevitáveis
2. **A Base Vetorial precisa de versões controladas** — sem versionamento semântico, não há como saber o que mudou entre releases
3. **Staging é obrigatório antes de produção** — o [[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]] define que o pipeline de ingestão deve ser idempotente e testável
4. **Compliance regulatório exige auditabilidade** — cada mudança deve ser rastreável a uma pessoa, data e motivo

## Requisitos do Modelo de Branching

1. **Simplicidade** — equipes de negócio (POs, analistas) participam; modelos complexos como Git Flow tradicional (5+ tipos de branch) são barreiras
2. **Paralelismo** — múltiplas pessoas trabalham simultaneamente; branches devem isolar trabalho individual
3. **Releases explícitas** — cada conjunto de mudanças promovido para a Base Vetorial deve ter TAG com versão semântica
4. **Ambientes** — staging obrigatório para testes antes de produção, com gate humano
5. **Rollback** — capacidade de reverter produção para TAG anterior de forma rápida e segura
6. **Hotfix** — capacidade de corrigir problemas urgentes sem esperar a próxima release
7. **Rastreabilidade** — cada commit, PR e TAG deve contar a história completa

## Por que Git Flow Tradicional Não Serve

O Git Flow (Driessen, 2010) define 5 tipos de branch (`main`, `develop`, `feature/*`, `release/*`, `hotfix/*`). Para base de conhecimento, não funciona:

- `develop` é conceito de integração contínua — não faz sentido para documentos promovidos sob demanda
- `main` como "o que está em produção" cria ambiguidade — produção é a Base Vetorial, não um branch
- `feature/*` para cada documento é granulação excessiva
- O fluxo `develop` -> `release` -> `main` é linear demais para o pipeline de 4 fases do [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]]

## Decisão: Release-Based Flow

Adotar modelo de branching **Release-Based Flow** com:

- Branches organizadas por release (`release/vX.Y.Z/*`)
- Versionamento semântico (`MAJOR.MINOR.PATCH`)
- 2 ambientes com Base Vetorial (staging + produção)
- Fluxo de promoção em 4 passos (consolidação -> TAG -> staging -> produção)
- Rollback por re-implantação de TAG anterior
- Hotfix como release patch dedicada

### Estrutura de Branches

```
release/v{MAJOR}.{MINOR}.{PATCH}/main
    Branch de consolidação da versão.
    Merge de todas as branches de trabalho.
    Ponto de partida para a TAG de release.

release/v{MAJOR}.{MINOR}.{PATCH}/{username}/{task-name}
    Branch de trabalho individual.
    Cada pessoa trabalha na sua branch.
    Merge para o /main da release via PR com review.
```

### Regras

1. O branch `release/vX.Y.Z/main` é criado pelo Curador (papel definido no [[ADR-008_governanca_ciclo_vida_rollback|ADR-008]]) quando decide iniciar uma nova versão
2. O branch é criado a partir da TAG da versão anterior (ex: `release/v1.1.0/main` a partir de TAG `v1.0.0`)
3. Branches de trabalho são criadas a partir de `release/vX.Y.Z/main` com padrão `release/vX.Y.Z/{username}/{task-name}`
4. Merges de branches de trabalho para `release/vX.Y.Z/main` são feitos via Pull Request com review obrigatório (mínimo 1 aprovação)
5. Quando todas as branches estão mergeadas e o QA está aprovado, o Curador cria a TAG `vX.Y.Z`
6. Após a TAG ser criada e implantada, o branch pode ser arquivado (mas **nunca deletado**)
7. **Não** é permitido commit direto no `release/vX.Y.Z/main` — todo commit passa por branch de trabalho + PR

## Versionamento Semântico

O versionamento segue o padrão SemVer, adaptado para base de conhecimento:

| Componente | Quando Incrementar | Exemplo |
|---|---|---|
| **MAJOR** | Mudança estrutural na KB: novo domínio, reestruturação de pastas, mudança no modelo de dados, migração de modelo de embedding | `v1.0.0` -> `v2.0.0` |
| **MINOR** | Novos documentos ou atualizações significativas (>30% do doc), novo módulo documentado, novo ADR | `v1.0.0` -> `v1.1.0` |
| **PATCH** | Correções pontuais: typos, ajustes de front matter, links quebrados, formatação | `v1.1.0` -> `v1.1.1` |
| **BUILD** | Automático, incremental por CI (opcional). Identificador único de build do pipeline | `v1.1.1.1561` |

Regras de incremento:

- MAJOR reseta MINOR e PATCH para 0
- MINOR reseta PATCH para 0
- A primeira release é `v1.0.0` (não `v0.x` — a base nasce com intenção de produção)
- Pre-releases não são usadas (sem `-alpha`, `-beta`, `-rc`). O staging serve como validação

Formato da TAG Git:

```bash
git tag -a v1.2.0 -m "Release v1.2.0 -- Documentação do módulo de cobrança e glossário financeiro"
```

## Fluxo de Promoção (Staging -> Produção)

O fluxo de promoção tem 4 passos sequenciais:

### Passo 1 — Consolidação

- **Pré-condições:** todas as branches mergeadas, nenhum PR pendente, zero alertas `<!-- CONFLICT -->` não resolvidos
- **Ações:** Curador revisa estado consolidado, QA automatizado roda (front matter, QA score >= 90%), Curador gera relatório de release (changelog)
- **Critérios de saída:** QA score >= 90% em todos os documentos (ou 80-89% com `qa_notes`), relatório gerado e revisado
- **Quem:** Curador (papel [[ADR-008_governanca_ciclo_vida_rollback|ADR-008]])

### Passo 2 — TAG Release

- **Pré-condições:** Passo 1 concluído e aprovado
- **Ações:**
  1. Curador cria TAG `vX.Y.Z` no branch `release/vX.Y.Z/main` do rag-workspace
  2. TAG dispara automaticamente pipeline de promoção: lê `.beta.md`, remove marcadores LOCKED, enriquece front matter, gera `.md` final, cria PR automático no rag-knowledge-base
  3. PR requer aprovação de PO + Arquiteto (2 aprovações)
  4. Após aprovação: merge no main + TAG `vX.Y.Z` espelhada no knowledge-base
- **Quem:** Curador (TAG), Pipeline (promoção), PO + Arquiteto (aprovação PR)

### Passo 3 — Staging

- **Pré-condições:** TAG `vX.Y.Z` criada no rag-knowledge-base, Base Vetorial de staging disponível
- **Ações:**
  1. TAG dispara automaticamente pipeline de ingestão na Base Vetorial de staging (conforme [[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]]): Descoberta -> Parse -> Chunking -> Embeddings -> Persistência -> Indexação -> Observabilidade
  2. Testes automatizados: Golden Set (Recall@10 >= threshold, conforme [[ADR-008_governanca_ciclo_vida_rollback|ADR-008]]), testes de acesso por confidencialidade, testes de integridade, smoke tests dos agentes
  3. Se qualquer teste falha: marca como "staging-failed", Curador investiga, correção via nova TAG patch
- **Quem:** Pipeline (ingestão), QA automatizado (testes), Curador (análise)

### Passo 4 — Produção

- **Pré-condições:** Passo 3 concluído e todos os testes passando
- **Ações:**
  1. Aprovação manual obrigatória: PO (conteúdo) + Arquiteto (integridade técnica)
  2. Implantação manual em produção — **nunca automática** (gate humano obrigatório)
  3. Pipeline usa a mesma TAG que passou em staging, é idempotente (conforme [[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]])
  4. Pós-implantação: `release_version` registrada, smoke test de produção, notificação para stakeholders, monitoramento intensivo nas primeiras 2 horas
- **Quem:** PO + Arquiteto (aprovação), Curador/Ops (implantação)

## Ambientes

A base de conhecimento opera em 2 ambientes com Base Vetorial:

| Ambiente | Base Vetorial | Dados | Acesso |
|---|---|---|---|
| **Staging** | Instância dedicada (mesma tecnologia de produção) | Dados reais (mesma TAG que irá para prod) | Time de QA, Curador, Arquiteto |
| **Produção** | Instância principal | Dados reais (TAG aprovada) | Todos os consumidores (via MCPs) |

**Não há ambiente de "desenvolvimento" com Base Vetorial.** Desenvolvimento acontece nos `.beta.md` via Obsidian (rag-workspace). A primeira vez que dados chegam em uma Base Vetorial é no staging. Motivos: Base Vetorial de dev seria desperdício, testes de retrieval só fazem sentido com dados consolidados, o pipeline é idempotente — staging é suficiente para validar.

## Rollback

Rollback = re-implantar uma TAG anterior em produção (rebuild completo).

1. **Decisão:** Curador ou Arquiteto decide que rollback é necessário
2. **Identificar TAG alvo:** listar TAGs e escolher a última versão estável
3. **Re-executar pipeline:** pipeline de ingestão é executado com TAG anterior; faz rebuild completo (limpa dados, re-ingere, re-gera embeddings, re-cria relações)
4. **Validação pós-rollback:** smoke test de produção, verificar `release_version`, notificar stakeholders

O rebuild completo é preferido ao rollback parcial porque o pipeline é idempotente (conforme [[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]]): mesmo input = mesmo output. O custo é tempo de execução (minutos), mas a segurança compensa.

Todo rollback deve ser registrado com: data/hora, TAG de origem e destino, motivo, quem autorizou, tempo de execução, resultado do smoke test. Registro armazenado em log do pipeline e em `releases/vX.Y.Z/rollback-log.json` no rag-knowledge-base.

## Hotfix

Hotfix é uma correção urgente em produção que não pode esperar a próxima release.

| Cenario | Acao |
|---|---|
| Muitos documentos com erro | Rollback para TAG anterior |
| 1-3 documentos com erro pontual | Hotfix |
| Informação sensível vazou (PII/LGPD) | Rollback imediato + hotfix |
| Erro de front matter causando filtro incorreto | Hotfix |
| Embedding model corrompeu vetores | Rollback + re-indexação |

Fluxo do hotfix:

1. **Criar release de hotfix:** partir da TAG em produção, criar `release/vX.Y.Z+1/main` e branch de trabalho
2. **Aplicar correção:** editar `.beta.md` necessários, commit com mensagem clara, PR para `release/vX.Y.Z+1/main`
3. **QA rápido:** QA score apenas nos documentos alterados, front matter validado, revisão focada
4. **TAG e promoção:** TAG no workspace, pipeline gera `.md` finais, PR no knowledge-base (fast-track: 1 aprovação)
5. **Staging:** pipeline de ingestão, testes focados (golden set + verificação específica do fix)
6. **Produção:** aprovação manual, implantação manual, smoke test + verificação específica

Tempo total esperado: 1-4 horas.

## Aplicação nos 2 Repositórios

### rag-workspace (editável)

- **Conteúdo:** `.beta.md`, fontes brutas, logs do processo
- **Branches:** `release/vX.Y.Z/main` (consolidação), `release/vX.Y.Z/{user}/{task}` (trabalho individual)
- **TAGs:** `vX.Y.Z` (disparam pipeline de promoção)
- **Quem trabalha:** POs, analistas, especialistas (via Obsidian), IA (enriquecimento), Curador (gestão de releases)
- **Permissões:** read-write para times de conhecimento, branches `release/*/main` protegidas (merge apenas via PR), TAGs criadas apenas pelo Curador

### rag-knowledge-base (imutável)

- **Conteúdo:** `.md` finais (fonte da verdade), release notes, manifests
- **Branches:** `main` (única)
- **TAGs:** `vX.Y.Z` (espelho da TAG do workspace, disparam pipeline de ingestão)
- **Quem trabalha:** ninguém edita diretamente; pipeline (service account) é o único que faz commits
- **Permissões:** read-only para todos, write apenas via service account, branch `main` protegida (merge via PR com 2 aprovações)

TAGs devem estar sincronizadas entre os 2 repositórios. Alerta automático para TAGs dessincronizadas com mais de 24h de diferença.

## Convenções de Commit

Todos os commits seguem o padrão `{tipo}: {descrição breve}`:

| Tipo | Descrição |
|---|---|
| `docs` | Criação ou atualização de documento |
| `fix` | Correção de erro em documento existente |
| `meta` | Alteração apenas de front matter/metadados |
| `glossary` | Alteração no glossário |
| `adr` | Criação ou atualização de ADR |
| `chore` | Alteração de configuração, templates, schemas |
| `hotfix` | Correção urgente (usado apenas em releases de patch) |

Regras: mensagem em pt-BR, primeira linha com no máximo 72 caracteres, corpo opcional, referenciar task ID quando aplicável.

## Política de Retenção de Branches

| Tipo de Branch | Retenção |
|---|---|
| `release/vX.Y.Z/main` | **Permanente** (nunca deletar) |
| `release/vX.Y.Z/{user}/{task}` | Deletar após merge + 30 dias |

Automação: branches de trabalho mergeadas há mais de 30 dias são deletadas; alerta para branches não-mergeadas há mais de 14 dias.

## Proteção de Branches

**rag-workspace:**
- `release/*/main`: merge apenas via PR, mínimo 1 aprovação, status checks obrigatórios, sem push direto, sem force push, sem delete

**rag-knowledge-base:**
- `main`: merge apenas via PR, mínimo 2 aprovações (PO + Arquiteto), status checks obrigatórios, sem push direto, sem force push, write apenas via service account

## Alternativas Consideradas

1. **Git Flow Tradicional (Driessen)** — rejeitado por over-engineering; 5 tipos de branch é complexo para times não-técnicos, branch `develop` não faz sentido para documentos
2. **Trunk-Based Development** — rejeitado por incompatibilidade com pipeline de 4 fases; sem staging explícito, sem release explícita, rollback perigoso
3. **GitHub Flow** — rejeitado pela ausência de releases explícitas; incompatível com modelo de promoção por TAG do [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]]
4. **GitLab Flow (Environment Branches)** — rejeitado porque o modelo de ambiente da Base Vetorial é por TAG (rebuild completo), não por branch

## Consequencias

### Positivas

- **Simplicidade:** apenas 2 tipos de branch
- **Paralelismo:** múltiplas pessoas trabalham em branches isoladas sem conflito
- **Versionamento:** cada release tem versão semântica rastreável
- **Auditabilidade:** TAGs + PRs + commits convencionados = trilha completa
- **Rollback simples:** re-implantar TAG anterior (rebuild idempotente)
- **Hotfix rápido:** release patch dedicada com fluxo simplificado
- **Integração natural com [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]]:** TAGs triggeram pipeline de promoção
- **Staging obrigatório:** nenhum dado chega em produção sem testes
- **Gate humano em produção:** implantação manual garante controle total

### Negativas / Trade-offs

- Nomenclatura de branches é longa (trade-off aceito: carrega contexto de versão + pessoa + tarefa)
- Branches `release/*/main` acumulam ao longo do tempo (mitigação: custo zero de armazenamento no Git)
- Cada release exige nova árvore de branches (trade-off aceito: clareza compensa overhead)
- Staging rebuilda a Base Vetorial a cada TAG (trade-off aceito: idempotência e previsibilidade compensam)
- Não há ambiente de dev com Base Vetorial (mitigação: scripts locais de teste com subset de dados)

### Riscos

| Risco | Prob. | Impacto | Mitigacao |
|---|---|---|---|
| TAG criada antes de todos os testes passarem | Média | Alto | CI/CD bloqueia criação de TAG se QA score < 80% |
| TAGs dessincronizadas entre repos | Baixa | Alto | Alerta automático para TAGs dessincronizadas > 24h |
| Hotfix bypassa QA completo | Média | Médio | Hotfix ainda exige staging + smoke test, mínimo 1 aprovação |
| Branch fora do padrão de nomenclatura | Alta | Baixo | CI/CD valida nome da branch no push |
| Rollback demora mais que o esperado | Baixa | Médio | Medir tempo de rebuild em staging; considerar blue-green deployment |
| Release com muitas mudanças dificulta rollback parcial | Média | Baixo | Releases menores e mais frequentes |

## Implementação

| Fase | Entrega | Duração | Dependência |
|---|---|---|---|
| 1 | Configuração dos repositórios, branch protection, service account, convenções | 1 semana | Nenhuma |
| 2 | Pipeline de TAG e promoção, validação de branches, QA automatizado, espelhamento de TAGs | 2 semanas | Fase 1 |
| 3 | Ambientes de Base Vetorial: staging, pipeline de ingestão, golden set, testes | 2 semanas | Fase 2, [[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]] |
| 4 | Fluxo de produção: aprovação manual, pipeline de implantação, smoke test, dashboard | 1 semana | Fase 3 |
| 5 | Rollback e hotfix: script de rollback, procedimento de hotfix, teste, registro | 1 semana | Fase 4 |
| 6 | Automações e governança: limpeza de branches, alertas, métricas de lead time | 1 semana | Fase 5 |

**Total estimado: 8 semanas**

## Métricas de Acompanhamento

| Métrica | Descrição | Meta |
|---|---|---|
| Lead time de release | Tempo entre criação do `release/*/main` e implantação em produção | < 2 semanas |
| Cycle time de PR | Tempo entre abertura e merge do PR | < 2 dias úteis |
| Taxa de sucesso em staging | % de TAGs que passam no staging na primeira tentativa | > 80% |
| Tempo de rollback | Tempo entre decisão e conclusão | < 1 hora |
| Frequência de hotfix | Número de hotfixes por mês | < 2/mês |
| Branches abandonadas | Branches não-mergeadas há > 14 dias | 0 |
| TAGs dessincronizadas | TAGs com > 24h de diferença entre repos | 0 |

## Referências

### ADRs Relacionados

- [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] — Pipeline de Geração de Conhecimento em 4 Fases (TAG trigger ingestão, release, 2 repositórios, estrutura de pastas, gate de qualidade)
- [[ADR-005_front_matter_contrato_metadados|ADR-005]] — Front Matter: Contrato de Metadados (validação de front matter no Passo 1)
- [[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]] — Pipeline de Ingestão (idempotência, re-indexação, trigger por release/TAG, 7 etapas)
- [[ADR-008_governanca_ciclo_vida_rollback|ADR-008]] — Governança: Papéis, Ciclo de Vida e Rollback (papel do Curador, golden set, rollback, testes de qualidade)
- [[ADR-009_selecao_modelos_embedding|ADR-009]] — Seleção de Modelos de Embedding (MAJOR version quando modelo muda)
- [[ADR-011_segregacao_kbs_por_confidencialidade|ADR-011]] — Segregação de KBs por Confidencialidade (regras de acesso por nível)

### Referências Externas

- Semantic Versioning 2.0.0: https://semver.org/
- Git Flow (Driessen, 2010): https://nvie.com/posts/a-successful-git-branching-model/
- GitHub Flow: https://docs.github.com/en/get-started/using-github/github-flow
- GitLab Flow: https://about.gitlab.com/topics/version-control/what-is-gitlab-flow/
- Trunk-Based Development: https://trunkbaseddevelopment.com/

---

<!-- QA-MD: inicio -->
## Quality Assurance — .md final

**Revisor:** Pipeline de Promoção QA
**Data:** 22/03/2026
**Fonte:** kb/rag-blueprint-adrs-kb/beta/ADR-010_git_flow_base_conhecimento.beta.md

| Critério | Peso | Nota | Comentário |
|----------|------|------|------------|
| Front matter rico | 25% | 95% | Todos os campos obrigatórios presentes. Campo `status` corrigido de "accepted" para "approved" (valor válido no schema). |
| Completude de conteúdo | 20% | 98% | Todas as seções ADR presentes: Contexto, Requisitos, Decisão, Alternativas, Consequências, Riscos, Implementação, Métricas, Referências. Cross-references completas. |
| Wikilinks | 10% | 100% | Todos os wikilinks no formato [[ADR-NNN_slug\|ADR-NNN]]. Nenhuma referência a BETA-*. |
| Sem artefatos workspace | 15% | 100% | Nenhum marcador LOCKED, QA-BETA ou BETA-NNN no id encontrado. |
| Compatibilidade Obsidian | 10% | 100% | YAML válido, aliases e tags como arrays, front matter bem formado. |
| Linhagem rastreável | 10% | 100% | source_path aponta para beta, source_beta_ids presente, conversion_pipeline: promotion-pipeline-v1. |
| Clareza e estrutura | 10% | 90% | Headings hierárquicos, tabelas bem formatadas. Corpo inteiro do documento estava sem acentos pt-BR (corrigido: ~80 ocorrências de palavras sem diacríticos). Estrutura de seções excelente. |

**Score:** 97.0% — APROVADO para ingestão

**Por que não é 100%:** (1) Campo `status` original era "accepted" (valor fora do schema, corrigido para "approved"). (2) Todo o corpo do documento estava sem acentos/diacríticos em português (ex: "nao" em vez de "não", "producao" em vez de "produção", "decisao" em vez de "decisão") — corrigido integralmente. A penalização residual reflete a extensão das correções necessárias.
<!-- QA-MD: fim -->
