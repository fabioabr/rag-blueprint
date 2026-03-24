---
id: ADR-010
doc_type: adr
title: "Git Flow da Base de Conhecimento"
system: RAG Corporativo
module: Git Flow
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-21
tags:
  - git flow
  - release based flow
  - branching
  - versionamento semântico
  - semver
  - staging
  - produção
  - ambientes
  - rollback
  - hotfix
  - tag release
  - pipeline promoção
  - rag workspace
  - rag knowledge base
  - base vetorial
  - pull request
  - review obrigatório
  - curador
  - contribuidores
  - service account
  - merge
  - branch protection
  - release tag
  - consolidação
  - qa score
  - compliance
  - auditabilidade
  - rastreabilidade
  - trunk based development
  - github flow
  - gitlab flow
  - git flow driessen
  - nomenclatura branches
  - release patch
  - rebuild completo
  - idempotência
  - pipeline ingestão
  - front matter
  - golden set
  - smoke test
  - ci cd
  - lead time
  - cycle time
  - infraestrutura
  - deploy
  - aprovação manual
  - gate humano
  - base conhecimento
  - documentos markdown
  - versionamento releases
  - fluxo promoção
  - ambientes segregados
  - tags sincronizadas
  - branches arquivadas
  - checkout release
aliases:
  - ADR-010
  - Release-Based Flow
  - Git Flow Base Conhecimento
  - Modelo de Branching RAG
  - Versionamento Semântico KB
  - ADR Git Flow
superseded_by: null
source_format: txt
source_repo: Rag
source_path:
  - "src/kb/rag-blueprint-adrs-draft/draft/ADR-010_git_flow_base_conhecimento.txt"
source_beta_ids:
  - BETA-010
conversion_pipeline: promotion-pipeline-v2
conversion_quality: 95
converted_at: 2026-03-23
qa_score: null
qa_date: null
qa_status: pending
created_at: 2026-03-21
updated_at: 2026-03-23
valid_from: 2026-03-21
valid_until: null
---

# ADR-010 — Git Flow da Base de Conhecimento

## Sumário

Esta ADR define o modelo de branching, versionamento semântico e estratégia de ambientes (staging + produção) para os 2 repositórios da base de conhecimento (`rag-workspace` e `rag-knowledge-base`).

**Decisão central:** adotar **Release-Based Flow** — modelo simplificado orientado a releases, com branches organizadas por versão, TAGs semânticas como gatilho de pipelines, 2 ambientes com Base Vetorial (staging + produção), rollback por re-implantação de TAG anterior e hotfix como release patch.

## Contexto

### Por que esta ADR existe

O [[ADR-001]] estabeleceu a separação física em 2 repositórios:

| Repositório | Propósito |
|-------------|-----------|
| `rag-workspace` | `.beta.md` em trabalho, fontes brutas, logs do processo. Editável por humanos (Obsidian) e IA (pipeline) |
| `rag-knowledge-base` | `.md` finais (fonte da verdade), apresentações, releases. Write apenas via pipeline (service account) + PR |

O [[ADR-001]] também definiu que:

- A promoção de `.beta.md` para `.md` é sob demanda, controlada por tags/releases
- TAGs no knowledge-base triggeram o pipeline de ingestão na Base Vetorial
- A versão da release é registrada nos dados da Base Vetorial
- Aprovação via PR (PO + Arquiteto) é obrigatória na Fase 3

Porém, o [[ADR-001]] **NÃO** definiu:

- Qual modelo de branching usar em cada repositório
- Como versionar semanticamente as releases
- Como organizar trabalho paralelo de múltiplas pessoas
- Quais ambientes existem (staging, produção) e como promover entre eles
- Como fazer rollback para uma versão anterior
- Como tratar hotfixes urgentes em produção
- Como garantir rastreabilidade completa (quem mudou o quê, quando)

Essas lacunas precisam ser resolvidas **ANTES** da implementação, pois:

- **a)** Múltiplas pessoas editam `.beta.md` simultaneamente. Sem modelo de branching, conflitos de merge são inevitáveis. Branches desorganizadas dificultam rastreabilidade.
- **b)** A Base Vetorial precisa de versões controladas. Sem versionamento semântico, não há como saber o que mudou entre releases. Rollback depende de TAGs bem definidas ([[ADR-008]] menciona rollback, mas não define o mecanismo Git que o suporta).
- **c)** Staging é obrigatório antes de produção. O [[ADR-006]] define que o pipeline de ingestão deve ser idempotente e testável. Sem ambiente de staging, testes acontecem em produção. O [[ADR-008]] define golden set e testes de qualidade — eles precisam rodar em algum lugar antes de produção.
- **d)** Compliance regulatório exige auditabilidade. Cada mudança na base de conhecimento deve ser rastreável a uma pessoa, uma data e um motivo. O Git provê isso nativamente, mas apenas se o modelo de branching for disciplinado.

### Requisitos do modelo de branching

O modelo ideal para a base de conhecimento deve atender:

1. **SIMPLICIDADE** — Equipes de negócio (POs, analistas) participam do processo. Modelos complexos como Git Flow tradicional (5+ tipos de branch) são barreiras. Precisamos de algo que caiba em um diagrama de 1 página.
2. **PARALELISMO** — Múltiplas pessoas trabalham simultaneamente em documentos diferentes (ou até no mesmo documento). Branches devem isolar trabalho individual sem bloquear os demais.
3. **RELEASES EXPLÍCITAS** — Cada conjunto de mudanças promovido para a Base Vetorial deve ter uma TAG com versão semântica. Não se aceita "deploy contínuo" de documentos — cada release é um pacote auditável.
4. **AMBIENTES** — Staging obrigatório para testes antes de produção. Produção com gate humano (aprovação manual do PO + Arquiteto).
5. **ROLLBACK** — Capacidade de reverter produção para uma TAG anterior de forma rápida e segura, sem necessidade de "desfazer commits".
6. **HOTFIX** — Capacidade de corrigir problemas urgentes em produção sem esperar a próxima release planejada.
7. **RASTREABILIDADE** — Cada commit, PR e TAG deve contar a história completa: quem mudou, o que mudou, por que mudou, quando mudou, e qual release carrega essa mudança.

### Por que Git Flow tradicional não serve

O Git Flow (Driessen, 2010) define 5 tipos de branch: `main`, `develop`, `feature/*`, `release/*`, `hotfix/*`

Para código de aplicação, funciona bem. Para base de conhecimento, não:

- `develop` é conceito de integração contínua — não faz sentido para documentos que são promovidos sob demanda.
- `main` como "o que está em produção" cria ambiguidade: o que está em produção é a Base Vetorial, não um branch do Git.
- `feature/*` para cada documento é granulação excessiva.
- O fluxo `develop -> release -> main` é linear demais para o pipeline de 4 fases do [[ADR-001]], que tem etapas paralelas (QA, promoção, staging).

O modelo que adotamos — **Release-Based Flow** — é uma simplificação orientada a releases, onde a unidade de trabalho é a versão, não a feature.

## Decisão

Adotar modelo de branching **Release-Based Flow** com:

- Branches organizadas por release (`release/vX.Y.Z/*`)
- Versionamento semântico (`MAJOR.MINOR.PATCH`)
- 2 ambientes com Base Vetorial (staging + produção)
- Fluxo de promoção em 4 passos (consolidação, TAG, staging, produção)
- Rollback por re-implantação de TAG anterior
- Hotfix como release patch dedicada

### Modelo de Branching: Release-Based Flow

**Princípio central:** TODA versão da base de conhecimento começa com uma branch de release. Não existe branch "develop" ou "main" no sentido tradicional.

**Estrutura de branches:**

```
release/v{MAJOR}.{MINOR}.{PATCH}/main
    Branch de consolidação da versão.
    Aqui se faz o merge de todas as branches de trabalho.
    É o ponto de partida para a TAG de release.

release/v{MAJOR}.{MINOR}.{PATCH}/{username}/{task-name}
    Branch de trabalho individual.
    Cada pessoa trabalha na sua branch.
    Merge para o /main da release via PR com review.
```

**Regras:**

1. O branch `release/vX.Y.Z/main` é **CRIADO** pelo Curador (papel definido no [[ADR-008]]) quando decide iniciar uma nova versão.
2. O branch `release/vX.Y.Z/main` é criado a partir da TAG da versão anterior (ex: `release/v1.1.0/main` é criado a partir de TAG `v1.0.0`). Na primeira release, é criado a partir do commit inicial do repo.
3. Branches de trabalho são criadas a partir de `release/vX.Y.Z/main`. Cada contribuidor cria sua branch com o padrão: `release/vX.Y.Z/{username}/{task-name}`
4. Merges de branches de trabalho para `release/vX.Y.Z/main` são feitos via **Pull Request com review obrigatório** (mínimo 1 aprovação).
5. Quando TODAS as branches de trabalho estão mergeadas e o QA está aprovado, o Curador cria a TAG `vX.Y.Z` no branch `release/vX.Y.Z/main`.
6. Após a TAG ser criada e implantada em produção, o branch `release/vX.Y.Z/main` pode ser arquivado (mas **NUNCA** deletado).
7. **NÃO** é permitido commit direto no `release/vX.Y.Z/main`. Todo commit passa por branch de trabalho + PR.

**Diagrama visual do fluxo:**

```
TAG v0.9.0 (anterior)
    |
    +--- release/v1.0.0/main <-------------------------------------+
    |       |                                                       |
    |       +-- release/v1.0.0/fabio/corrigir-glossario --- PR --->|
    |       |                                                       |
    |       +-- release/v1.0.0/maria/novo-modulo-cobranca - PR --->|
    |       |                                                       |
    |       +-- release/v1.0.0/joao/atualizar-adr-003 ---- PR --->|
    |                                                               |
    |                                                     TAG v1.0.0
    |                                                         |
    |                                                         v
    |                                                [Pipeline Promoção]
    |                                                         |
    |                                                         v
    |                                                [Staging -> Prod]
    |
    +--- release/v1.1.0/main (próxima versão, criada a partir de TAG v1.0.0)
```

### Versionamento Semântico

O versionamento segue o padrão **Semantic Versioning (SemVer)**, adaptado para base de conhecimento:

```
v{MAJOR}.{MINOR}.{PATCH}[.{BUILD}]
```

| Componente | Quando incrementar | Exemplos |
|------------|-------------------|----------|
| **MAJOR** | Mudança estrutural na KB: novo domínio de negócio, reestruturação de pastas/categorias, mudança no modelo de dados (ex: novo label), migração de modelo de embedding (re-indexação) | v1.0.0 -> v2.0.0 |
| **MINOR** | Novos documentos ou atualizações significativas: novo documento adicionado, atualização de conteúdo substancial (>30% do doc), novo módulo documentado, novo ADR incorporado | v1.0.0 -> v1.1.0 |
| **PATCH** | Correções pontuais: typos, erros de digitação, ajustes de front matter (tags, owner, etc.), links quebrados corrigidos, formatação e padronização | v1.1.0 -> v1.1.1 |
| **BUILD** | Automático, incremental por CI (opcional): identificador único de build do pipeline. Útil para rastrear exatamente qual execução gerou o artefato. NÃO faz parte da TAG — é metadado do pipeline | v1.1.1.1561 |

**Regras de incremento:**

- MAJOR reseta MINOR e PATCH para 0 (ex: v1.3.2 -> v2.0.0)
- MINOR reseta PATCH para 0 (ex: v1.3.2 -> v1.4.0)
- A primeira release é `v1.0.0` (não v0.x — a base nasce com intenção de produção)
- Pre-releases NÃO são usadas (sem `-alpha`, `-beta`, `-rc`). O staging serve como ambiente de validação pré-produção.

**Formato da TAG Git:**

```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z — {descrição breve da release}"
```

A mensagem da TAG deve ser descritiva o suficiente para que, ao listar TAGs, qualquer pessoa entenda o que cada release contém.

### Fluxo de Promoção (Staging -> Produção)

O fluxo de promoção tem **4 passos sequenciais:**

**Passo 1 — Consolidação**
Todas as branches de trabalho mergeadas, QA score >= 90%, relatório de release gerado. Curador aprova formalmente.

**Passo 2 — TAG Release**
TAG `vX.Y.Z` criada no workspace. Dispara pipeline de promoção (`.beta.md` -> `.md`). PR automático no knowledge-base com aprovação de PO + Arquiteto. TAG espelhada no knowledge-base.

**Passo 3 — Staging**
TAG no knowledge-base dispara ingestão na Base Vetorial de staging. Testes automatizados: golden set, acesso por confidencialidade, integridade, smoke tests dos agentes.

**Passo 4 — Produção**
Aprovação **MANUAL** obrigatória (PO + Arquiteto). Implantação manual em produção. Smoke test e monitoramento intensivo.

**Diagrama do fluxo de promoção:**

```
rag-workspace                          rag-knowledge-base
-------------                          ------------------

release/vX.Y.Z/main
     |
     |  [Passo 1: Consolidação]
     |  QA score >= 90%
     |
     v
TAG vX.Y.Z --------------------> Pipeline de Promoção
(workspace)                         .beta.md -> .md
                                         |
                                         v
                                    PR automático
                                    no knowledge-base
                                         |
                                    [PO + Arquiteto aprovam]
                                         |
                                         v
                                    TAG vX.Y.Z -----------> Pipeline de
                                    (knowledge-base)          Ingestão
                                                                |
                                                                v
                                                          [Passo 3: Staging]
                                                                |
                                                          Testes OK + Aprovação
                                                                |
                                                                v
                                                          [Passo 4: Produção]
```

### Ambientes

A base de conhecimento opera em **2 ambientes** com Base Vetorial:

| Ambiente | Base Vetorial | Dados | Acesso |
|----------|---------------|-------|--------|
| **Staging** | Instância dedicada (mesma tecnologia de produção) | Dados reais (mesma TAG que irá para prod) | Time de QA, Curador, Arquiteto |
| **Produção** | Instância principal | Dados reais (TAG aprovada) | Todos os consumidores (via MCPs) |

**Trigger:**
- Staging -> Automático por TAG no `rag-knowledge-base`
- Produção -> Manual após aprovação de PO + Arquiteto

**NÃO** há ambiente de "desenvolvimento" com Base Vetorial. Desenvolvimento acontece nos `.beta.md` via Obsidian (`rag-workspace`). A PRIMEIRA vez que dados chegam em uma Base Vetorial é no **STAGING**.

**Justificativa para ausência de ambiente dev:**
- Base Vetorial de dev seria desperdício (edição é em Markdown)
- Testes de retrieval só fazem sentido com dados consolidados (pós-QA)
- Custo de manter 3 instâncias de Base Vetorial não se justifica
- O pipeline de ingestão é idempotente — staging é suficiente para validar

### Rollback

Rollback é a capacidade de reverter a Base Vetorial de produção para uma versão anterior. O mecanismo é simples por design:

> **Rollback = re-implantar uma TAG anterior em produção**

O pipeline de ingestão faz **REBUILD COMPLETO** da Base Vetorial de produção: limpa todos os dados existentes, re-ingere todos os documentos da TAG alvo, re-gera todos os embeddings, re-cria todas as relações.

**Justificativa do rebuild completo (em vez de rollback parcial):**

- **Simples:** mesma lógica do pipeline normal
- **Previsível:** mesmo input = mesmo output (pilar H do [[ADR-001]], idempotência)
- **Validável:** basta comparar com os dados do staging da TAG anterior
- Rollback parcial (desfazer apenas o delta) é mais complexo de implementar, propenso a erros e difícil de validar
- O custo é tempo de execução (minutos), mas a segurança compensa

Todo rollback deve ser registrado com: data/hora, TAG de origem e TAG destino, motivo, quem autorizou, tempo de execução e resultado do smoke test.

### Hotfix

Hotfix é uma correção urgente em produção que não pode esperar a próxima release planejada. É tratado como uma **release de patch dedicada**.

**Critérios de escolha entre rollback e hotfix:**

| Cenário | Ação |
|---------|------|
| Muitos documentos com erro | Rollback para TAG anterior |
| 1-3 documentos com erro pontual | Hotfix |
| Informação sensível vazou (PII/LGPD) | Rollback IMEDIATO + hotfix |
| Erro de front matter causando filtro incorreto | Hotfix |
| Embedding model corrompeu vetores | Rollback + re-indexação |

O hotfix segue o mesmo Release-Based Flow, com QA simplificado (apenas documentos alterados) e aprovação fast-track (mínimo 1 aprovação no PR, em vez de 2). Staging e smoke test continuam obrigatórios.

### Aplicação nos 2 Repositórios

O Release-Based Flow é aplicado nos 2 repositórios, com papéis diferentes:

**rag-workspace (editável):**
- **Conteúdo:** `.beta.md`, fontes brutas, logs do processo
- **Branches:** `release/vX.Y.Z/main` (consolidação) e `release/vX.Y.Z/{user}/{task}` (trabalho individual)
- **TAGs:** `vX.Y.Z` dispara pipeline de promoção
- **Quem trabalha:** POs, analistas, especialistas (Obsidian), IA (pipeline), Curador (gestão de releases)
- **Permissões:** read-write para times de conhecimento; branches `release/*/main` protegidas (merge apenas via PR); TAGs criadas apenas pelo Curador

**rag-knowledge-base (imutável):**
- **Conteúdo:** `.md` finais (fonte da verdade), release notes, manifests
- **Branches:** `main` (única) — NÃO há branches de release ou feature
- **TAGs:** `vX.Y.Z` (espelho do workspace) dispara pipeline de ingestão
- **Quem trabalha:** NINGUÉM edita diretamente; pipeline (service account) é o único que faz commits; PO + Arquiteto aprovam PRs
- **Permissões:** read-only para todos os times; write APENAS via service account; branch main protegida (merge via PR, 2 aprovações)

**Sincronização de TAGs:** as TAGs **DEVEM** estar sincronizadas entre os 2 repositórios. Se uma TAG existir no workspace mas não no knowledge-base, significa que a promoção falhou ou está em andamento. O pipeline deve alertar sobre TAGs dessincronizadas com mais de 24h de diferença.

## Alternativas Descartadas

### Git Flow Tradicional (Driessen)

**Descrição:** Modelo com 5 tipos de branch: `main`, `develop`, `feature/*`, `release/*`, `hotfix/*`. O develop é o branch de integração contínua. Features são mergeadas no develop. Quando o develop está estável, cria-se uma release/* que, após testes, é mergeada no main e taggeada.

**Prós:**
- Modelo maduro e amplamente documentado
- Separação clara entre desenvolvimento e produção
- Suporte nativo a hotfixes
- Ferramentas de suporte (git-flow CLI)

**Contras:**
- 5 tipos de branch é complexo para times não-técnicos (POs, analistas)
- Branch develop é conceito de integração contínua — base de conhecimento não tem "build" nem "deploy contínuo"
- Merge develop -> release -> main é redundante para documentos
- O conceito de "feature" não se aplica bem a documentos
- Overhead de manutenção: manter develop e main sincronizados

**Motivo da rejeição:** Over-engineering para base de conhecimento. O Release-Based Flow mantém o conceito de release (que é útil) mas elimina develop e feature como tipos de branch, simplificando significativamente o fluxo.

### Trunk-Based Development

**Descrição:** Todos trabalham no branch main (trunk). Commits são feitos diretamente ou via branches de vida curta (< 1 dia). Deploy contínuo a cada commit no main. Releases são TAGs no main.

**Prós:**
- Extremamente simples: 1 branch principal
- Sem overhead de merges complexos
- Feedback rápido: cada commit é "deployável"
- Ideal para equipes maduras com CI/CD robusto

**Contras:**
- Risco alto de conflitos: todos escrevem no mesmo branch
- Sem staging explícito: cada commit vai direto para "produção"
- Não suporta QA score de documentos antes da promoção ([[ADR-001]])
- Rollback é reverter commits no main — perigoso e não-atômico
- Não funciona com o modelo de 2 repositórios do [[ADR-001]] (o knowledge-base NÃO aceita commits humanos)
- Sem release explícita: difícil rastrear "o que entrou na versão X"

**Motivo da rejeição:** Incompatível com o pipeline de 4 fases do [[ADR-001]]. A ausência de release explícita e staging inviabiliza a validação de qualidade antes da ingestão na Base Vetorial.

### GitHub Flow

**Descrição:** Main é o branch de produção. Para cada mudança, cria-se uma branch feature/* a partir de main. Ao finalizar, PR para main com review. Após merge, deploy automático. Sem release explícita.

**Prós:**
- Simples: main + feature branches
- PR como gate de qualidade
- Funciona bem para projetos com deploy contínuo

**Contras:**
- Sem release explícita: não há versionamento semântico
- Sem staging: cada merge em main é "produção"
- Agrupamento de mudanças em releases requer disciplina manual
- Rollback é reverter merge em main — pode gerar conflitos
- Não se integra naturalmente com o fluxo de TAG do [[ADR-001]]

**Motivo da rejeição:** A ausência de releases explícitas é incompatível com o modelo de promoção por TAG do [[ADR-001]]. O Release-Based Flow é essencialmente um GitHub Flow agrupado por release, o que endereça essa lacuna.

### GitLab Flow (Environment Branches)

**Descrição:** Extensão do GitHub Flow com branches por ambiente: `main -> staging -> production`. Cada ambiente tem seu branch. Promoção é merge entre branches de ambiente.

**Prós:**
- Suporte nativo a staging e produção
- Branches por ambiente facilitam rastreabilidade
- Cherry-pick entre ambientes é possível

**Contras:**
- Branches de ambiente acumulam histórico divergente
- Merge staging -> production pode conflitar com merges anteriores
- NÃO funciona bem com rebuild completo da Base Vetorial (nosso modelo rebuilda a partir de TAG, não de branch)
- Complexidade de manter 3+ branches permanentes sincronizadas
- Para base de conhecimento, "staging" e "produção" são ambientes da Base Vetorial, não branches Git

**Motivo da rejeição:** O modelo de ambiente da Base Vetorial é por TAG (rebuild completo a partir de uma versão específica), não por branch. Branches de ambiente adicionam complexidade sem benefício real no nosso contexto.

## Consequências

### Positivas

- **Simplicidade:** apenas 2 tipos de branch (`release/*/main` e `release/*/user/task`)
- **Paralelismo:** múltiplas pessoas trabalham em branches isoladas sem conflito
- **Versionamento:** cada release tem versão semântica rastreável
- **Auditabilidade:** TAGs + PRs + commits convencionados = trilha completa
- **Rollback simples:** re-implantar TAG anterior (rebuild idempotente)
- **Hotfix rápido:** release patch dedicada com fluxo simplificado
- **Integração natural com [[ADR-001]]:** TAGs triggeram pipeline de promoção
- **Staging obrigatório:** nenhum dado chega em produção sem passar por testes
- **Gate humano em produção:** implantação manual garante controle total
- **Compatível com Obsidian:** contribuidores editam `.beta.md` normalmente

### Negativas / Trade-offs

- **a) Nomenclatura de branches é longa:** `release/v1.2.0/fabio/corrigir-glossario` é verboso comparado a `fix/glossario`. Trade-off aceito: a nomenclatura carrega contexto (versão + pessoa + tarefa) que facilita rastreabilidade.
- **b) Branches release/*/main acumulam ao longo do tempo:** Após 50 releases, haverá 50 branches `release/*/main` no repositório. Mitigação: branches são apenas referências no Git (custo zero de armazenamento) e podem ser "arquivadas" visualmente com prefixo (ex: `archive/release/v1.0.0/main`).
- **c) Cada release exige uma nova árvore de branches:** Mais overhead operacional que trunk-based development. Trade-off aceito: a clareza de "tudo que pertence a v1.2.0 está em release/v1.2.0/*" compensa o overhead.
- **d) Staging rebuilda a Base Vetorial a cada TAG:** Custo computacional de re-ingestão completa a cada release. Trade-off aceito: idempotência e previsibilidade compensam ([[ADR-006]]).
- **e) Não há ambiente de dev com Base Vetorial:** Desenvolvedores não podem testar retrieval durante desenvolvimento. Mitigação: scripts locais de teste com subset de dados podem ser usados para validações informais, mas não substituem staging.

### Riscos

| # | Risco | Probabilidade | Impacto | Mitigação |
|---|-------|--------------|---------|-----------|
| 1 | TAG criada antes de todos os testes de consolidação passarem | MÉDIA | ALTO | CI/CD bloqueia criação de TAG se QA score < 80% ou se houver PRs pendentes no release/*/main |
| 2 | TAGs dessincronizadas entre workspace e knowledge-base | BAIXA | ALTO | Alerta automático para TAGs dessincronizadas há mais de 24h. Dashboard de status mostrando TAGs em cada repo + ambiente |
| 3 | Hotfix bypassa QA completo | MÉDIA | MÉDIO | Hotfix AINDA exige staging e smoke test. O QA é simplificado (apenas documentos alterados), mas NUNCA eliminado |
| 4 | Contribuidor cria branch fora do padrão de nomenclatura | ALTA | BAIXO | CI/CD valida nome da branch no push. Templates de branch. Documentação clara com exemplos |
| 5 | Rollback demora mais que o esperado (volume grande de documentos) | BAIXA | MÉDIO | Medir tempo de rebuild em staging para cada release. Se rebuild > 1h, considerar blue-green deployment |
| 6 | Release com muitas mudanças dificulta rollback parcial | MÉDIA | BAIXO | Releases menores e mais frequentes. Releases grandes devem ser divididas em MINOR incrementais |

## Implementação

### Faseamento

| Fase | Entrega | Duração | Dependência |
|------|---------|---------|-------------|
| 1 | Configuração dos repositórios: criar `rag-workspace` e `rag-knowledge-base`, configurar branch protection rules, configurar service account para pipeline | 1 semana | Nenhuma |
| 2 | Pipeline de TAG e promoção: CI/CD para validação de branch names, CI/CD para QA score automatizado, pipeline de promoção (`.beta.md` -> `.md`), espelhamento automático de TAGs | 2 semanas | Fase 1 |
| 3 | Ambientes de Base Vetorial: provisionar instância de staging, configurar pipeline de ingestão por TAG, implementar golden set e testes | 2 semanas | Fase 2, [[ADR-006]] |
| 4 | Fluxo de produção: fluxo de aprovação manual, pipeline de implantação em produção, dashboard de status (TAGs, ambientes, releases) | 1 semana | Fase 3 |
| 5 | Rollback e hotfix: script de rollback (re-implantação de TAG anterior), teste de rollback em staging | 1 semana | Fase 4 |
| 6 | Automações e governança: limpeza automática de branches mergeadas (30 dias), alertas de branches e TAGs, métricas de lead time | 1 semana | Fase 5 |

**TOTAL ESTIMADO: 8 semanas**

### Responsabilidades

| Papel | Responsabilidade no Git Flow |
|-------|------------------------------|
| **Curador ([[ADR-008]])** | Criar branches `release/*/main`, gerenciar QA, criar TAGs, decidir rollback/hotfix |
| **Contribuidores (POs, Analistas)** | Criar branches de trabalho, editar `.beta.md`, fazer commits, abrir PRs |
| **Arquiteto** | Aprovar PRs no knowledge-base, aprovar implantação em produção, definir thresholds de golden set |
| **PO (Product Owner)** | Aprovar PRs no knowledge-base, aprovar implantação em produção, validar conteúdo da release |
| **Engenharia / Ops** | Implementar pipelines de CI/CD, provisionar ambientes, manter service account e permissões |
| **Pipeline (SA)** | Executar promoção, criar PRs no knowledge-base, espelhar TAGs, executar ingestão, rodar testes |

### Métricas de Acompanhamento

| Métrica | Meta |
|---------|------|
| Lead time de release | < 2 semanas |
| Cycle time de PR | < 2 dias úteis |
| Taxa de sucesso em staging | > 80% |
| Tempo de rollback | < 1 hora |
| Frequência de hotfix | < 2/mês |
| Branches abandonadas (>14 dias) | 0 |
| TAGs dessincronizadas (>24h) | 0 |

## Referências

### ADRs relacionadas

- [[ADR-001]] — Pipeline de Geração de Conhecimento em 4 Fases (As 4 fases; Dois repositórios; Fase 3: Gate de qualidade)
- [[ADR-005]] — Front Matter: Contrato de Metadados (validação de front matter no Passo 1)
- [[ADR-006]] — Pipeline de Ingestão: Da Fonte à Base Vetorial (idempotência, re-indexação, trigger por TAG)
- [[ADR-008]] — Governança: Papéis, Ciclo de Vida e Rollback (Curador, golden set, testes pré-produção)
- [[ADR-009]] — Seleção de Modelos de Embedding (MAJOR version quando modelo muda)
- [[ADR-011]] — Segregação por Confidencialidade (testes de acesso no staging)

### Referências externas

- [Semantic Versioning 2.0.0](https://semver.org/)
- [Git Flow (Driessen, 2010)](https://nvie.com/posts/a-successful-git-branching-model/)
- [GitHub Flow](https://docs.github.com/en/get-started/using-github/github-flow)
- [GitLab Flow](https://about.gitlab.com/topics/version-control/what-is-gitlab-flow/)
- [Trunk-Based Development](https://trunkbaseddevelopment.com/)

<!-- conversion_quality: 95 -->
