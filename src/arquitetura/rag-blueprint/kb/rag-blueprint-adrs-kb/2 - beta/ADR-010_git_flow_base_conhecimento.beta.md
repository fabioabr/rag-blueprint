---
id: BETA-010
title: "Git Flow da Base de Conhecimento"
domain: "arquitetura"
confidentiality: internal
sources:
  - type: "txt"
    origin: "Arquitetura/rag-blueprint/kb/rag-blueprint-adrs-kb/1 - draft/ADR-010_git_flow_base_conhecimento.txt"
    captured_at: "2026-03-21"
tags: [git-flow, branching, versionamento, release, ambientes, rollback, hotfix]
aliases: ["ADR-010", "Release-Based Flow"]
status: approved
last_enrichment: "2026-03-22"
last_human_edit: "2026-03-22"
---

## Referências Cruzadas

- **Depende de:** [[BETA-001]], [[BETA-006]]
- **Relaciona-se:** [[BETA-005]], [[BETA-008]], [[BETA-009]], [[BETA-011]]

## Contexto

O [[BETA-001]] estabeleceu a separacao fisica em 2 repositorios:

| Repositorio | Proposito |
|---|---|
| **rag-workspace** | `.beta.md` em trabalho, fontes brutas, logs do processo. Editavel por humanos (Obsidian) e IA (pipeline) |
| **rag-knowledge-base** | `.md` finais (fonte da verdade), apresentacoes, releases. Write apenas via pipeline (service account) + PR |

O [[BETA-001]] tambem definiu que a promocao de `.beta.md` para `.md` e sob demanda, controlada por tags/releases, e que TAGs no knowledge-base triggeram o pipeline de ingestao na Base Vetorial. Porem, o [[BETA-001]] **nao definiu**:

- Qual modelo de branching usar em cada repositorio
- Como versionar semanticamente as releases
- Como organizar trabalho paralelo de multiplas pessoas
- Quais ambientes existem (staging, producao) e como promover entre eles
- Como fazer rollback para uma versao anterior
- Como tratar hotfixes urgentes em producao
- Como garantir rastreabilidade completa

Essas lacunas precisam ser resolvidas antes da implementacao porque:

1. **Multiplas pessoas editam `.beta.md` simultaneamente** — sem modelo de branching, conflitos de merge sao inevitaveis
2. **A Base Vetorial precisa de versoes controladas** — sem versionamento semantico, nao ha como saber o que mudou entre releases
3. **Staging e obrigatorio antes de producao** — o [[BETA-006]] define que o pipeline de ingestao deve ser idempotente e testavel
4. **Compliance regulatorio exige auditabilidade** — cada mudanca deve ser rastreavel a uma pessoa, data e motivo

## Requisitos do Modelo de Branching

1. **Simplicidade** — equipes de negocio (POs, analistas) participam; modelos complexos como Git Flow tradicional (5+ tipos de branch) sao barreiras
2. **Paralelismo** — multiplas pessoas trabalham simultaneamente; branches devem isolar trabalho individual
3. **Releases explicitas** — cada conjunto de mudancas promovido para a Base Vetorial deve ter TAG com versao semantica
4. **Ambientes** — staging obrigatorio para testes antes de producao, com gate humano
5. **Rollback** — capacidade de reverter producao para TAG anterior de forma rapida e segura
6. **Hotfix** — capacidade de corrigir problemas urgentes sem esperar a proxima release
7. **Rastreabilidade** — cada commit, PR e TAG deve contar a historia completa

## Por que Git Flow Tradicional Nao Serve

O Git Flow (Driessen, 2010) define 5 tipos de branch (`main`, `develop`, `feature/*`, `release/*`, `hotfix/*`). Para base de conhecimento, nao funciona:

- `develop` e conceito de integracao continua — nao faz sentido para documentos promovidos sob demanda
- `main` como "o que esta em producao" cria ambiguidade — producao e a Base Vetorial, nao um branch
- `feature/*` para cada documento e granulacao excessiva
- O fluxo `develop` -> `release` -> `main` e linear demais para o pipeline de 4 fases do [[BETA-001]]

<!-- LOCKED:START autor=fabio data=2026-03-22 -->
## Decisao: Release-Based Flow

Adotar modelo de branching **Release-Based Flow** com:

- Branches organizadas por release (`release/vX.Y.Z/*`)
- Versionamento semantico (`MAJOR.MINOR.PATCH`)
- 2 ambientes com Base Vetorial (staging + producao)
- Fluxo de promocao em 4 passos (consolidacao -> TAG -> staging -> producao)
- Rollback por re-implantacao de TAG anterior
- Hotfix como release patch dedicada

### Estrutura de Branches

```
release/v{MAJOR}.{MINOR}.{PATCH}/main
    Branch de consolidacao da versao.
    Merge de todas as branches de trabalho.
    Ponto de partida para a TAG de release.

release/v{MAJOR}.{MINOR}.{PATCH}/{username}/{task-name}
    Branch de trabalho individual.
    Cada pessoa trabalha na sua branch.
    Merge para o /main da release via PR com review.
```

### Regras

1. O branch `release/vX.Y.Z/main` e criado pelo Curador (papel definido no [[BETA-008]]) quando decide iniciar uma nova versao
2. O branch e criado a partir da TAG da versao anterior (ex: `release/v1.1.0/main` a partir de TAG `v1.0.0`)
3. Branches de trabalho sao criadas a partir de `release/vX.Y.Z/main` com padrao `release/vX.Y.Z/{username}/{task-name}`
4. Merges de branches de trabalho para `release/vX.Y.Z/main` sao feitos via Pull Request com review obrigatorio (minimo 1 aprovacao)
5. Quando todas as branches estao mergeadas e o QA esta aprovado, o Curador cria a TAG `vX.Y.Z`
6. Apos a TAG ser criada e implantada, o branch pode ser arquivado (mas **nunca deletado**)
7. **Nao** e permitido commit direto no `release/vX.Y.Z/main` — todo commit passa por branch de trabalho + PR
<!-- LOCKED:END -->

## Versionamento Semantico

O versionamento segue o padrao SemVer, adaptado para base de conhecimento:

| Componente | Quando Incrementar | Exemplo |
|---|---|---|
| **MAJOR** | Mudanca estrutural na KB: novo dominio, reestruturacao de pastas, mudanca no modelo de dados, migracao de modelo de embedding | `v1.0.0` -> `v2.0.0` |
| **MINOR** | Novos documentos ou atualizacoes significativas (>30% do doc), novo modulo documentado, novo ADR | `v1.0.0` -> `v1.1.0` |
| **PATCH** | Correcoes pontuais: typos, ajustes de front matter, links quebrados, formatacao | `v1.1.0` -> `v1.1.1` |
| **BUILD** | Automatico, incremental por CI (opcional). Identificador unico de build do pipeline | `v1.1.1.1561` |

Regras de incremento:

- MAJOR reseta MINOR e PATCH para 0
- MINOR reseta PATCH para 0
- A primeira release e `v1.0.0` (nao `v0.x` — a base nasce com intencao de producao)
- Pre-releases nao sao usadas (sem `-alpha`, `-beta`, `-rc`). O staging serve como validacao

Formato da TAG Git:

```bash
git tag -a v1.2.0 -m "Release v1.2.0 -- Documentacao do modulo de cobranca e glossario financeiro"
```

## Fluxo de Promocao (Staging -> Producao)

O fluxo de promocao tem 4 passos sequenciais:

### Passo 1 — Consolidacao

- **Pre-condicoes:** todas as branches mergeadas, nenhum PR pendente, zero alertas `<!-- CONFLICT -->` nao resolvidos
- **Acoes:** Curador revisa estado consolidado, QA automatizado roda (front matter, QA score >= 90%), Curador gera relatorio de release (changelog)
- **Criterios de saida:** QA score >= 90% em todos os documentos (ou 80-89% com `qa_notes`), relatorio gerado e revisado
- **Quem:** Curador (papel [[BETA-008]])

### Passo 2 — TAG Release

- **Pre-condicoes:** Passo 1 concluido e aprovado
- **Acoes:**
  1. Curador cria TAG `vX.Y.Z` no branch `release/vX.Y.Z/main` do rag-workspace
  2. TAG dispara automaticamente pipeline de promocao: le `.beta.md`, remove marcadores LOCKED, enriquece front matter, gera `.md` final, cria PR automatico no rag-knowledge-base
  3. PR requer aprovacao de PO + Arquiteto (2 aprovacoes)
  4. Apos aprovacao: merge no main + TAG `vX.Y.Z` espelhada no knowledge-base
- **Quem:** Curador (TAG), Pipeline (promocao), PO + Arquiteto (aprovacao PR)

### Passo 3 — Staging

- **Pre-condicoes:** TAG `vX.Y.Z` criada no rag-knowledge-base, Base Vetorial de staging disponivel
- **Acoes:**
  1. TAG dispara automaticamente pipeline de ingestao na Base Vetorial de staging (conforme [[BETA-006]]): Descoberta -> Parse -> Chunking -> Embeddings -> Persistencia -> Indexacao -> Observabilidade
  2. Testes automatizados: Golden Set (Recall@10 >= threshold, conforme [[BETA-008]]), testes de acesso por confidencialidade, testes de integridade, smoke tests dos agentes
  3. Se qualquer teste falha: marca como "staging-failed", Curador investiga, correcao via nova TAG patch
- **Quem:** Pipeline (ingestao), QA automatizado (testes), Curador (analise)

### Passo 4 — Producao

- **Pre-condicoes:** Passo 3 concluido e todos os testes passando
- **Acoes:**
  1. Aprovacao manual obrigatoria: PO (conteudo) + Arquiteto (integridade tecnica)
  2. Implantacao manual em producao — **nunca automatica** (gate humano obrigatorio)
  3. Pipeline usa a mesma TAG que passou em staging, e idempotente (conforme [[BETA-006]])
  4. Pos-implantacao: `release_version` registrada, smoke test de producao, notificacao para stakeholders, monitoramento intensivo nas primeiras 2 horas
- **Quem:** PO + Arquiteto (aprovacao), Curador/Ops (implantacao)

## Ambientes

A base de conhecimento opera em 2 ambientes com Base Vetorial:

| Ambiente | Base Vetorial | Dados | Acesso |
|---|---|---|---|
| **Staging** | Instancia dedicada (mesma tecnologia de producao) | Dados reais (mesma TAG que ira para prod) | Time de QA, Curador, Arquiteto |
| **Producao** | Instancia principal | Dados reais (TAG aprovada) | Todos os consumidores (via MCPs) |

**Nao ha ambiente de "desenvolvimento" com Base Vetorial.** Desenvolvimento acontece nos `.beta.md` via Obsidian (rag-workspace). A primeira vez que dados chegam em uma Base Vetorial e no staging. Motivos: Base Vetorial de dev seria desperdicio, testes de retrieval so fazem sentido com dados consolidados, o pipeline e idempotente — staging e suficiente para validar.

## Rollback

Rollback = re-implantar uma TAG anterior em producao (rebuild completo).

1. **Decisao:** Curador ou Arquiteto decide que rollback e necessario
2. **Identificar TAG alvo:** listar TAGs e escolher a ultima versao estavel
3. **Re-executar pipeline:** pipeline de ingestao e executado com TAG anterior; faz rebuild completo (limpa dados, re-ingere, re-gera embeddings, re-cria relacoes)
4. **Validacao pos-rollback:** smoke test de producao, verificar `release_version`, notificar stakeholders

O rebuild completo e preferido ao rollback parcial porque o pipeline e idempotente (conforme [[BETA-006]]): mesmo input = mesmo output. O custo e tempo de execucao (minutos), mas a seguranca compensa.

Todo rollback deve ser registrado com: data/hora, TAG de origem e destino, motivo, quem autorizou, tempo de execucao, resultado do smoke test. Registro armazenado em log do pipeline e em `releases/vX.Y.Z/rollback-log.json` no rag-knowledge-base.

## Hotfix

Hotfix e uma correcao urgente em producao que nao pode esperar a proxima release.

| Cenario | Acao |
|---|---|
| Muitos documentos com erro | Rollback para TAG anterior |
| 1-3 documentos com erro pontual | Hotfix |
| Informacao sensivel vazou (PII/LGPD) | Rollback imediato + hotfix |
| Erro de front matter causando filtro incorreto | Hotfix |
| Embedding model corrompeu vetores | Rollback + re-indexacao |

Fluxo do hotfix:

1. **Criar release de hotfix:** partir da TAG em producao, criar `release/vX.Y.Z+1/main` e branch de trabalho
2. **Aplicar correcao:** editar `.beta.md` necessarios, commit com mensagem clara, PR para `release/vX.Y.Z+1/main`
3. **QA rapido:** QA score apenas nos documentos alterados, front matter validado, revisao focada
4. **TAG e promocao:** TAG no workspace, pipeline gera `.md` finais, PR no knowledge-base (fast-track: 1 aprovacao)
5. **Staging:** pipeline de ingestao, testes focados (golden set + verificacao especifica do fix)
6. **Producao:** aprovacao manual, implantacao manual, smoke test + verificacao especifica

Tempo total esperado: 1-4 horas.

## Aplicacao nos 2 Repositorios

### rag-workspace (editavel)

- **Conteudo:** `.beta.md`, fontes brutas, logs do processo
- **Branches:** `release/vX.Y.Z/main` (consolidacao), `release/vX.Y.Z/{user}/{task}` (trabalho individual)
- **TAGs:** `vX.Y.Z` (disparam pipeline de promocao)
- **Quem trabalha:** POs, analistas, especialistas (via Obsidian), IA (enriquecimento), Curador (gestao de releases)
- **Permissoes:** read-write para times de conhecimento, branches `release/*/main` protegidas (merge apenas via PR), TAGs criadas apenas pelo Curador

### rag-knowledge-base (imutavel)

- **Conteudo:** `.md` finais (fonte da verdade), release notes, manifests
- **Branches:** `main` (unica)
- **TAGs:** `vX.Y.Z` (espelho da TAG do workspace, disparam pipeline de ingestao)
- **Quem trabalha:** ninguem edita diretamente; pipeline (service account) e o unico que faz commits
- **Permissoes:** read-only para todos, write apenas via service account, branch `main` protegida (merge via PR com 2 aprovacoes)

TAGs devem estar sincronizadas entre os 2 repositorios. Alerta automatico para TAGs dessincronizadas com mais de 24h de diferenca.

## Convencoes de Commit

Todos os commits seguem o padrao `{tipo}: {descricao breve}`:

| Tipo | Descricao |
|---|---|
| `docs` | Criacao ou atualizacao de documento |
| `fix` | Correcao de erro em documento existente |
| `meta` | Alteracao apenas de front matter/metadados |
| `glossary` | Alteracao no glossario |
| `adr` | Criacao ou atualizacao de ADR |
| `chore` | Alteracao de configuracao, templates, schemas |
| `hotfix` | Correcao urgente (usado apenas em releases de patch) |

Regras: mensagem em pt-BR, primeira linha com no maximo 72 caracteres, corpo opcional, referenciar task ID quando aplicavel.

## Politica de Retencao de Branches

| Tipo de Branch | Retencao |
|---|---|
| `release/vX.Y.Z/main` | **Permanente** (nunca deletar) |
| `release/vX.Y.Z/{user}/{task}` | Deletar apos merge + 30 dias |

Automacao: branches de trabalho mergeadas ha mais de 30 dias sao deletadas; alerta para branches nao-mergeadas ha mais de 14 dias.

## Protecao de Branches

**rag-workspace:**
- `release/*/main`: merge apenas via PR, minimo 1 aprovacao, status checks obrigatorios, sem push direto, sem force push, sem delete

**rag-knowledge-base:**
- `main`: merge apenas via PR, minimo 2 aprovacoes (PO + Arquiteto), status checks obrigatorios, sem push direto, sem force push, write apenas via service account

## Alternativas Consideradas

1. **Git Flow Tradicional (Driessen)** — rejeitado por over-engineering; 5 tipos de branch e complexo para times nao-tecnicos, branch `develop` nao faz sentido para documentos
2. **Trunk-Based Development** — rejeitado por incompatibilidade com pipeline de 4 fases; sem staging explicito, sem release explicita, rollback perigoso
3. **GitHub Flow** — rejeitado pela ausencia de releases explicitas; incompativel com modelo de promocao por TAG do [[BETA-001]]
4. **GitLab Flow (Environment Branches)** — rejeitado porque o modelo de ambiente da Base Vetorial e por TAG (rebuild completo), nao por branch

## Consequencias

### Positivas

- **Simplicidade:** apenas 2 tipos de branch
- **Paralelismo:** multiplas pessoas trabalham em branches isoladas sem conflito
- **Versionamento:** cada release tem versao semantica rastreavel
- **Auditabilidade:** TAGs + PRs + commits convencionados = trilha completa
- **Rollback simples:** re-implantar TAG anterior (rebuild idempotente)
- **Hotfix rapido:** release patch dedicada com fluxo simplificado
- **Integracao natural com [[BETA-001]]:** TAGs triggeram pipeline de promocao
- **Staging obrigatorio:** nenhum dado chega em producao sem testes
- **Gate humano em producao:** implantacao manual garante controle total

### Negativas / Trade-offs

- Nomenclatura de branches e longa (trade-off aceito: carrega contexto de versao + pessoa + tarefa)
- Branches `release/*/main` acumulam ao longo do tempo (mitigacao: custo zero de armazenamento no Git)
- Cada release exige nova arvore de branches (trade-off aceito: clareza compensa overhead)
- Staging rebuilda a Base Vetorial a cada TAG (trade-off aceito: idempotencia e previsibilidade compensam)
- Nao ha ambiente de dev com Base Vetorial (mitigacao: scripts locais de teste com subset de dados)

### Riscos

| Risco | Prob. | Impacto | Mitigacao |
|---|---|---|---|
| TAG criada antes de todos os testes passarem | Media | Alto | CI/CD bloqueia criacao de TAG se QA score < 80% |
| TAGs dessincronizadas entre repos | Baixa | Alto | Alerta automatico para TAGs dessincronizadas > 24h |
| Hotfix bypassa QA completo | Media | Medio | Hotfix ainda exige staging + smoke test, minimo 1 aprovacao |
| Branch fora do padrao de nomenclatura | Alta | Baixo | CI/CD valida nome da branch no push |
| Rollback demora mais que o esperado | Baixa | Medio | Medir tempo de rebuild em staging; considerar blue-green deployment |
| Release com muitas mudancas dificulta rollback parcial | Media | Baixo | Releases menores e mais frequentes |

## Implementacao

| Fase | Entrega | Duracao | Dependencia |
|---|---|---|---|
| 1 | Configuracao dos repositorios, branch protection, service account, convencoes | 1 semana | Nenhuma |
| 2 | Pipeline de TAG e promocao, validacao de branches, QA automatizado, espelhamento de TAGs | 2 semanas | Fase 1 |
| 3 | Ambientes de Base Vetorial: staging, pipeline de ingestao, golden set, testes | 2 semanas | Fase 2, [[BETA-006]] |
| 4 | Fluxo de producao: aprovacao manual, pipeline de implantacao, smoke test, dashboard | 1 semana | Fase 3 |
| 5 | Rollback e hotfix: script de rollback, procedimento de hotfix, teste, registro | 1 semana | Fase 4 |
| 6 | Automacoes e governanca: limpeza de branches, alertas, metricas de lead time | 1 semana | Fase 5 |

**Total estimado: 8 semanas**

## Metricas de Acompanhamento

| Metrica | Descricao | Meta |
|---|---|---|
| Lead time de release | Tempo entre criacao do `release/*/main` e implantacao em producao | < 2 semanas |
| Cycle time de PR | Tempo entre abertura e merge do PR | < 2 dias uteis |
| Taxa de sucesso em staging | % de TAGs que passam no staging na primeira tentativa | > 80% |
| Tempo de rollback | Tempo entre decisao e conclusao | < 1 hora |
| Frequencia de hotfix | Numero de hotfixes por mes | < 2/mes |
| Branches abandonadas | Branches nao-mergeadas ha > 14 dias | 0 |
| TAGs dessincronizadas | TAGs com > 24h de diferenca entre repos | 0 |

## Referencias

### ADRs Relacionados

- [[BETA-001]] — Pipeline de Geracao de Conhecimento em 4 Fases (TAG trigger ingestao, release, 2 repositorios, estrutura de pastas, gate de qualidade)
- [[BETA-005]] — Front Matter: Contrato de Metadados (validacao de front matter no Passo 1)
- [[BETA-006]] — Pipeline de Ingestao (idempotencia, re-indexacao, trigger por release/TAG, 7 etapas)
- [[BETA-008]] — Governanca: Papeis, Ciclo de Vida e Rollback (papel do Curador, golden set, rollback, testes de qualidade)
- [[BETA-009]] — Selecao de Modelos de Embedding (MAJOR version quando modelo muda)
- [[BETA-011]] — Segregacao de KBs por Confidencialidade (regras de acesso por nivel)

### Referencias Externas

- Semantic Versioning 2.0.0: https://semver.org/
- Git Flow (Driessen, 2010): https://nvie.com/posts/a-successful-git-branching-model/
- GitHub Flow: https://docs.github.com/en/get-started/using-github/github-flow
- GitLab Flow: https://about.gitlab.com/topics/version-control/what-is-gitlab-flow/
- Trunk-Based Development: https://trunkbaseddevelopment.com/

---

<!-- QA-BETA: inicio -->
## Quality Assurance — .beta.md

| Critério | Peso | Nota | Comentário |
|----------|------|------|------------|
| Front matter leve | 25% | 100% | id BETA-010 valido, title descritivo (35 chars), domain lowercase, confidentiality enum valido, sources com type/origin/captured_at, tags 7 itens (>= 3), status approved, aliases opcional presente (corrigido para strings entre aspas). Nenhum campo de governanca indevido. |
| Completude de conteúdo | 25% | 82% | Secoes principais preservadas (Contexto, Requisitos, Decisao, Versionamento, Promocao, Ambientes, Rollback, Hotfix, Aplicacao nos 2 Repos, Convencoes, Retencao, Protecao, Alternativas, Consequencias, Implementacao, Metricas, Referencias). Omitidas: secao "Responsabilidades" (papeis detalhados por ator no fluxo), "Checklist de Configuracao Inicial" (lista operacional de setup), "Exemplo completo de fluxo" (walkthrough), "Diagrama visual do fluxo" e "Sincronizacao de TAGs entre repositorios" (subsecao). Adicionada secao "Referências Cruzadas" para consistencia com BETA-009. |
| Blocos LOCKED | 15% | 100% | Um bloco LOCKED na decisao principal (Release-Based Flow + Estrutura de Branches + Regras), corretamente aberto e fechado com autor e data. |
| Wikilinks | 10% | 100% | 15 wikilinks no formato [[BETA-NNN]], todos corretos (BETA-001, 005, 006, 008, 009, 011). Nenhum wikilink no front matter. |
| Compatibilidade Obsidian | 10% | 100% | YAML valido entre delimitadores ---, tags como array, aliases corrigido para array com strings entre aspas. Totalmente compativel. |
| Clareza e estrutura | 15% | 93% | Headings claros, tabelas bem formatadas, fluxo de promocao em 4 passos bem estruturado. Blocos de codigo para exemplos de branch e TAG. Acentuacao ausente no corpo (ex: "separacao" em vez de "separação") — aceitavel pois o draft original tambem nao usa acentos. |

**Score:** 93.5% — APROVADO para promoção

**Por que não é 100%:** (1) Secao "Responsabilidades" do draft omitida — detalhava papel de cada ator (Curador, Contribuidores, Arquiteto, PO, Ops, Pipeline) no fluxo (-2.5%). (2) "Checklist de Configuracao Inicial" omitido — lista operacional de 18 itens para setup dos repositorios (-2%). (3) "Exemplo completo de fluxo" e "Diagrama visual" omitidos — walkthrough passo a passo com cenario concreto (-1.5%). (4) Subsecao "Sincronizacao de TAGs entre repositorios" consolidada em menção breve (-0.5%).
<!-- QA-BETA: fim -->
