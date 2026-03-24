---
id: ADR-J02
doc_type: adr
title: "Rollback de Release — Procedimento de Re-Implantação de TAG Anterior na Base de Conhecimento"
system: RAG Corporativo
module: Rollback
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - rollback
  - release
  - re implantação
  - tag anterior
  - rebuild completo
  - base vetorial
  - pipeline de ingestão
  - idempotência
  - decisão de rollback
  - tag alvo
  - validação pós rollback
  - smoke test
  - golden set
  - recall
  - release version
  - registro de rollback
  - curador
  - arquiteto
  - operações
  - stakeholders
  - notificação
  - multi kb
  - segregação por confidencialidade
  - rollback independente
  - rollback urgente
  - pii
  - vazamento
  - lgpd
  - anpd
  - contenção
  - blocklist
  - compliance
  - root cause analysis
  - rca
  - prevenção
  - qa score
  - staging
  - gate humano
  - monitoramento
  - blue green deployment
  - indisponibilidade
  - manutenção
  - mcp
  - hotfix
  - tempo de rebuild
  - manifesto
  - integridade
  - chunks
  - documentos
  - embedding
  - índices vetoriais
  - relações
  - grafo
  - drill trimestral
  - latência
  - p95
  - procedimento operacional
  - cenário de falha
aliases:
  - "ADR-J02"
  - "Rollback de Release"
  - "Rollback da Base de Conhecimento"
  - "Procedimento de Rollback"
  - "Re-implantação de TAG"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/beta/ADR-J02_rollback_release.beta.md"
source_beta_ids:
  - "BETA-J02"
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

# ADR-J02 — Rollback de Release — Procedimento de Re-Implantação de TAG Anterior na Base de Conhecimento

| Campo       | Valor                                                         |
|-------------|---------------------------------------------------------------|
| **Status**  | Accepted                                                      |
| **Data**    | 23/03/2026                                                    |
| **Decisor** | fabio (arquitetura)                                           |
| **Escopo**  | Procedimento operacional de rollback de release na base de conhecimento, incluindo quando usar, como executar, e reconstrução da Base Vetorial a partir de TAG anterior |

**Referências cruzadas:**

- [[ADR-010]]: Git Flow (rollback por re-implantação de TAG, registro)
- [[ADR-008]]: Governança (cenários A-D de rollback, SLAs, RACI)
- [[ADR-006]]: Pipeline de Ingestão (idempotência, rebuild completo)
- [[ADR-011]]: Segregação de KBs (rollback independente por KB)
- [[ADR-J01]]: Promoção Staging → Produção (prevenção de rollback)
- [[ADR-J03]]: Hotfix (alternativa a rollback para erros pontuais)

---

## Contexto

Em cenários de falha significativa em uma release da base de conhecimento, é necessário um procedimento claro e seguro de rollback. O pipeline de ingestão é idempotente ([[ADR-006]]), o que significa que mesma TAG = mesmo resultado, garantindo previsibilidade na reversão.

## Decisão

Documentar o procedimento operacional de rollback de release na base de conhecimento, incluindo quando usar, como executar, e como reconstruir a Base Vetorial a partir de uma TAG anterior.

## Definição

Rollback = re-implantar uma TAG anterior em produção, fazendo rebuild completo da Base Vetorial.

O rebuild completo é preferido ao rollback parcial porque o pipeline de ingestão é IDEMPOTENTE ([[ADR-006]]): mesmo input (mesma TAG) = mesmo output (mesma Base Vetorial). O custo é tempo de execução (minutos a horas, dependendo do volume), mas a segurança e previsibilidade compensam.

## Quando Usar Rollback

| Cenário | Ação Recomendada |
|---|---|
| Muitos documentos com erro na release | ROLLBACK para TAG anterior |
| Recall@10 caiu significativamente | ROLLBACK + investigação |
| Embedding model corrompeu vetores | ROLLBACK + re-indexação |
| Informação sensível vazou (PII/LGPD) | ROLLBACK imediato + hotfix |
| Base Vetorial corrompida (> 20% dos dados) | ROLLBACK (restore backup ou rebuild de TAG) |
| 1-3 documentos com erro pontual | NÃO usar rollback; usar HOTFIX ([[ADR-J03]]) |
| Erro de front matter em poucos docs | NÃO usar rollback; usar HOTFIX ([[ADR-J03]]) |

**Regra prática:** se o problema afeta mais de 3 documentos ou impacta a integridade geral da Base Vetorial, usar rollback. Se é pontual, usar hotfix.

## Procedimento de Rollback — 4 Passos

### Passo 1 — Decisão

**Quem decide:** Curador ou Arquiteto

**Critérios para decidir:**
- Problema identificado e confirmado (não é falso positivo)
- Impacto avaliado (quantos documentos, quantos usuários afetados)
- Alternativas descartadas (hotfix não resolve, correção in-place não é viável)

**Registro:**
- Data/hora da decisão
- Quem autorizou
- Motivo do rollback (descrição clara do problema)
- TAG de origem (versão atual com problema)
- TAG de destino (versão estável para qual voltar)

### Passo 2 — Identificar TAG Alvo

**Ações:**
a) Listar TAGs disponíveis no rag-knowledge-base:
```bash
git tag -l --sort=-version:refname
```
b) Identificar a última versão estável (TAG que estava em produção antes da versão problemática)
c) Confirmar que a TAG alvo existe em ambos os repositórios (rag-workspace e rag-knowledge-base)
d) Se necessário, consultar histórico de releases para confirmar qual TAG era a última estável

**Validação:**
- TAG alvo existe e está acessível
- .md finais na TAG alvo estão íntegros (spot check)
- TAG não possui problemas conhecidos anteriores

### Passo 3 — Re-executar Pipeline

**Ações:**
a) Pipeline de ingestão é executado com a TAG anterior
b) O pipeline faz REBUILD COMPLETO:
   - Limpa dados da Base Vetorial de produção
   - Re-ingere todos os .md da TAG alvo
   - Re-gera embeddings para todos os chunks
   - Re-cria todas as relações no grafo
   - Re-cria índices vetoriais e auxiliares
c) O pipeline é o MESMO que foi usado no staging da TAG original (idempotência garantida pelo [[ADR-006]])

**Tempos estimados de rebuild (referência [[ADR-008]]):**

| Volume | Tempo Estimado |
|---|---|
| 50 documentos | ~5 minutos |
| 200 documentos | ~15 minutos |
| 1.000 documentos | ~30-45 minutos |
| 10.000+ documentos | ~4-8 horas |

**Meta de tempo de rollback:** < 1 hora ([[ADR-010]])

**Nota:** durante o rebuild, a Base Vetorial de produção está INDISPONÍVEL. Os MCPs devem retornar mensagem de manutenção. Para volumes muito grandes, considerar blue-green deployment (rebuild em instância paralela, switch após conclusão).

### Passo 4 — Validação Pós-Rollback

**Ações:**
a) Smoke test de produção:
   - Busca semântica retorna resultados
   - Agentes de IA conseguem consultar via MCP
   - Latência dentro do esperado (p95 < 500ms)

b) Verificar release_version:
   - Confirmar que a Base Vetorial agora registra a TAG alvo como release_version

c) Verificar contagem de documentos e chunks:
   - Conferir com manifesto da TAG alvo
   - Nenhum documento faltando, nenhum chunk órfão

d) Executar golden set (se tempo permitir):
   - Recall@10 >= threshold da fase atual

e) Notificar stakeholders:
   - Versão revertida, motivo, versão atual em produção
   - Estimativa de quando a próxima release corrigida será disponibilizada

## Registro do Rollback

Todo rollback deve ser registrado com os seguintes campos:

| Campo | Descrição |
|---|---|
| data_hora | Timestamp do início do rollback |
| tag_origem | TAG da versão problemática (ex: v1.2.0) |
| tag_destino | TAG da versão estável (ex: v1.1.0) |
| motivo | Descrição clara do problema que motivou |
| quem_autorizou | Nome do Curador ou Arquiteto que decidiu |
| quem_executou | Nome do operador que executou |
| tempo_execucao | Duração total do rollback (minutos) |
| resultado_smoke_test | OK / NOK (com detalhes se NOK) |
| release_version_final | TAG registrada na Base Vetorial após rollback |
| acoes_futuras | Plano para corrigir o problema e releasar |

Arquivo de registro: `releases/vX.Y.Z/rollback-log.json` no rag-knowledge-base

## Rollback em Contexto Multi-KB ([[ADR-011]])

Quando o modelo de segregação em 3 KBs está ativo:

- Rollback é INDEPENDENTE por KB.
- Erro na KB pública NÃO afeta KB restrita nem confidencial.
- Cada KB tem seu próprio ciclo de release e TAG:
  - kb-public-internal@v1.2.0 → rollback para @v1.1.0
  - kb-restricted@v1.0.3 → sem rollback (não afetada)
  - kb-confidential@v1.0.1 → sem rollback (não afetada)
- O orquestrador cross-KB ([[ADR-H01]]) continua funcionando com a KB afetada temporariamente indisponível.

## Rollback Urgente (PII / Vazamento)

Para cenários de PII ou vazamento de dados sensíveis, o procedimento de rollback é combinado com o cenário C do [[ADR-008]]:

| Passo | SLA | Quem | Ação |
|---|---|---|---|
| 1 | 15 min | Ops/Eng | CONTER: blocklist do doc OU parar API. Notificar Compliance. |
| 2 | 1 hora | Engenheiro | Remover chunks da Base Vetorial (exportar para evidência antes). |
| 3 | 2 horas | Engenheiro | Remover/anonimizar .md do knowledge-base repo. Avaliar git filter-branch. |
| 4 | 3 horas | Curador + Eng | Verificar/anonimizar .beta.md no workspace repo. |
| 5 | 4 horas | Ops + Compliance | Verificar logs de retrieval. Se PII foi servido → procedimento ANPD. |

**Ativação:** qualquer pessoa pode ativar SEM aprovação prévia. Compliance notificado nos primeiros 15 minutos.

**Pós-incidente (até 5 dias úteis):**
- Root Cause Analysis (RCA)
- Ações preventivas (scanner PII, blocklist, treinamento)
- Documentar RCA no knowledge-base repo

Após contenção: executar rollback completo para TAG estável (Passos 1-4 deste documento).

## Prevenção de Rollbacks

Medidas para reduzir a necessidade de rollback:

- QA score >= 90% obrigatório antes de TAG (Passo 1 do [[ADR-J01]])
- Staging obrigatório com golden set (Passo 3 do [[ADR-J01]])
- Gate humano em produção (Passo 4 do [[ADR-J01]] — nunca automático)
- Releases menores e mais frequentes (menos mudanças por release)
- Monitoramento intensivo nas primeiras 2 horas pós-implantação
- Drill de rollback trimestral ([[ADR-I01]] cadência trimestral)

**Meta:** < 2 rollbacks por mês ([[ADR-010]] métricas de acompanhamento)

## Referências

- [[ADR-010]]: Git Flow (rollback por re-implantação de TAG, registro)
- [[ADR-008]]: Governança (cenários A-D de rollback, SLAs, RACI)
- [[ADR-006]]: Pipeline de Ingestão (idempotência, rebuild completo)
- [[ADR-011]]: Segregação de KBs (rollback independente por KB)
- [[ADR-J01]]: Promoção Staging → Produção (prevenção de rollback)
- [[ADR-J03]]: Hotfix (alternativa a rollback para erros pontuais)

<!-- conversion_quality: 95 -->
