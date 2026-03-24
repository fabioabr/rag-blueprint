---
id: BETA-J02
title: "Rollback de Release"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-J02_rollback_release.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags:
  - rollback
  - release
  - re implantacao
  - tag anterior
  - rebuild completo
  - base vetorial
  - pipeline de ingestao
  - idempotencia
  - decisao de rollback
  - tag alvo
  - validacao pos rollback
  - smoke test
  - golden set
  - recall
  - release version
  - registro de rollback
  - curador
  - arquiteto
  - operacoes
  - stakeholders
  - notificacao
  - multi kb
  - segregacao por confidencialidade
  - rollback independente
  - rollback urgente
  - pii
  - vazamento
  - lgpd
  - anpd
  - contencao
  - blocklist
  - compliance
  - root cause analysis
  - rca
  - prevencao
  - qa score
  - staging
  - gate humano
  - monitoramento
  - blue green deployment
  - indisponibilidade
  - manutencao
  - mcp
  - hotfix
  - tempo de rebuild
  - manifesto
  - integridade
  - chunks
  - documentos
  - embedding
  - indices vetoriais
  - relacoes
  - grafo
  - drill trimestral
  - latencia
  - p95
aliases:
  - "ADR-J02"
  - "Rollback de Release"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## ADR-J02 -- Rollback de Release

**Tipo:** ADR
**Origem:** ADR-010
**Data:** 23/03/2026

## 1. Objetivo

Documentar o procedimento operacional de rollback de release na base de conhecimento, incluindo quando usar, como executar, e como reconstruir a Base Vetorial a partir de uma TAG anterior. Extraido das secoes "Rollback" do ADR-010 (Git Flow) e complementado pelos cenarios de rollback do ADR-008 (Governanca).

## 2. Definicao

Rollback = re-implantar uma TAG anterior em producao, fazendo rebuild completo da Base Vetorial.

O rebuild completo e preferido ao rollback parcial porque o pipeline de ingestao e IDEMPOTENTE (ADR-006): mesmo input (mesma TAG) = mesmo output (mesma Base Vetorial). O custo e tempo de execucao (minutos a horas, dependendo do volume), mas a seguranca e previsibilidade compensam.

## 3. Quando Usar Rollback

| Cenario | Acao Recomendada |
|---|---|
| Muitos documentos com erro na release | ROLLBACK para TAG anterior |
| Recall@10 caiu significativamente | ROLLBACK + investigacao |
| Embedding model corrompeu vetores | ROLLBACK + re-indexacao |
| Informacao sensivel vazou (PII/LGPD) | ROLLBACK imediato + hotfix |
| Base Vetorial corrompida (> 20% dos dados) | ROLLBACK (restore backup ou rebuild de TAG) |
| 1-3 documentos com erro pontual | NAO usar rollback; usar HOTFIX (ADR-J03) |
| Erro de front matter em poucos docs | NAO usar rollback; usar HOTFIX (ADR-J03) |

**Regra pratica:** se o problema afeta mais de 3 documentos ou impacta a integridade geral da Base Vetorial, usar rollback. Se e pontual, usar hotfix.

## 4. Procedimento de Rollback -- 4 Passos

### Passo 1 -- Decisao

**Quem decide:** Curador ou Arquiteto

**Criterios para decidir:**
- Problema identificado e confirmado (nao e falso positivo)
- Impacto avaliado (quantos documentos, quantos usuarios afetados)
- Alternativas descartadas (hotfix nao resolve, correcao in-place nao e viavel)

**Registro:**
- Data/hora da decisao
- Quem autorizou
- Motivo do rollback (descricao clara do problema)
- TAG de origem (versao atual com problema)
- TAG de destino (versao estavel para qual voltar)

### Passo 2 -- Identificar TAG Alvo

**Acoes:**
a) Listar TAGs disponiveis no rag-knowledge-base:
```bash
git tag -l --sort=-version:refname
```
b) Identificar a ultima versao estavel (TAG que estava em producao antes da versao problematica)
c) Confirmar que a TAG alvo existe em ambos os repositorios (rag-workspace e rag-knowledge-base)
d) Se necessario, consultar historico de releases para confirmar qual TAG era a ultima estavel

**Validacao:**
- TAG alvo existe e esta acessivel
- .md finais na TAG alvo estao integros (spot check)
- TAG nao possui problemas conhecidos anteriores

### Passo 3 -- Re-executar Pipeline

**Acoes:**
a) Pipeline de ingestao e executado com a TAG anterior
b) O pipeline faz REBUILD COMPLETO:
   - Limpa dados da Base Vetorial de producao
   - Re-ingere todos os .md da TAG alvo
   - Re-gera embeddings para todos os chunks
   - Re-cria todas as relacoes no grafo
   - Re-cria indices vetoriais e auxiliares
c) O pipeline e o MESMO que foi usado no staging da TAG original (idempotencia garantida pelo ADR-006)

**Tempos estimados de rebuild (referencia ADR-008):**

| Volume | Tempo Estimado |
|---|---|
| 50 documentos | ~5 minutos |
| 200 documentos | ~15 minutos |
| 1.000 documentos | ~30-45 minutos |
| 10.000+ documentos | ~4-8 horas |

**Meta de tempo de rollback:** < 1 hora (ADR-010)

**Nota:** durante o rebuild, a Base Vetorial de producao esta INDISPONIVEL. Os MCPs devem retornar mensagem de manutencao. Para volumes muito grandes, considerar blue-green deployment (rebuild em instancia paralela, switch apos conclusao).

### Passo 4 -- Validacao Pos-Rollback

**Acoes:**
a) Smoke test de producao:
   - Busca semantica retorna resultados
   - Agentes de IA conseguem consultar via MCP
   - Latencia dentro do esperado (p95 < 500ms)

b) Verificar release_version:
   - Confirmar que a Base Vetorial agora registra a TAG alvo como release_version

c) Verificar contagem de documentos e chunks:
   - Conferir com manifesto da TAG alvo
   - Nenhum documento faltando, nenhum chunk orfao

d) Executar golden set (se tempo permitir):
   - Recall@10 >= threshold da fase atual

e) Notificar stakeholders:
   - Versao revertida, motivo, versao atual em producao
   - Estimativa de quando a proxima release corrigida sera disponibilizada

## 5. Registro do Rollback

Todo rollback deve ser registrado com os seguintes campos:

| Campo | Descricao |
|---|---|
| data_hora | Timestamp do inicio do rollback |
| tag_origem | TAG da versao problematica (ex: v1.2.0) |
| tag_destino | TAG da versao estavel (ex: v1.1.0) |
| motivo | Descricao clara do problema que motivou |
| quem_autorizou | Nome do Curador ou Arquiteto que decidiu |
| quem_executou | Nome do operador que executou |
| tempo_execucao | Duracao total do rollback (minutos) |
| resultado_smoke_test | OK / NOK (com detalhes se NOK) |
| release_version_final | TAG registrada na Base Vetorial apos rollback |
| acoes_futuras | Plano para corrigir o problema e releasar |

Arquivo de registro: `releases/vX.Y.Z/rollback-log.json` no rag-knowledge-base

## 6. Rollback em Contexto Multi-KB (ADR-011)

Quando o modelo de segregacao em 3 KBs esta ativo:

- Rollback e INDEPENDENTE por KB.
- Erro na KB publica NAO afeta KB restrita nem confidencial.
- Cada KB tem seu proprio ciclo de release e TAG:
  - kb-public-internal@v1.2.0 -> rollback para @v1.1.0
  - kb-restricted@v1.0.3 -> sem rollback (nao afetada)
  - kb-confidential@v1.0.1 -> sem rollback (nao afetada)
- O orquestrador cross-KB (ADR-H01) continua funcionando com a KB afetada temporariamente indisponivel.

## 7. Rollback Urgente (PII / Vazamento)

Para cenarios de PII ou vazamento de dados sensiveis, o procedimento de rollback e combinado com o cenario C do ADR-008:

| Passo | SLA | Quem | Acao |
|---|---|---|---|
| 1 | 15 min | Ops/Eng | CONTER: blocklist do doc OU parar API. Notificar Compliance. |
| 2 | 1 hora | Engenheiro | Remover chunks da Base Vetorial (exportar para evidencia antes). |
| 3 | 2 horas | Engenheiro | Remover/anonimizar .md do knowledge-base repo. Avaliar git filter-branch. |
| 4 | 3 horas | Curador + Eng | Verificar/anonimizar .beta.md no workspace repo. |
| 5 | 4 horas | Ops + Compliance | Verificar logs de retrieval. Se PII foi servido -> procedimento ANPD. |

**Ativacao:** qualquer pessoa pode ativar SEM aprovacao previa. Compliance notificado nos primeiros 15 minutos.

**Pos-incidente (ate 5 dias uteis):**
- Root Cause Analysis (RCA)
- Acoes preventivas (scanner PII, blocklist, treinamento)
- Documentar RCA no knowledge-base repo

Apos contencao: executar rollback completo para TAG estavel (Passos 1-4 da secao 4 deste documento).

## 8. Prevencao de Rollbacks

Medidas para reduzir a necessidade de rollback:

- QA score >= 90% obrigatorio antes de TAG (Passo 1 do ADR-J01)
- Staging obrigatorio com golden set (Passo 3 do ADR-J01)
- Gate humano em producao (Passo 4 do ADR-J01 -- nunca automatico)
- Releases menores e mais frequentes (menos mudancas por release)
- Monitoramento intensivo nas primeiras 2 horas pos-implantacao
- Drill de rollback trimestral (ADR-I01 cadencia trimestral)

**Meta:** < 2 rollbacks por mes (ADR-010 metricas de acompanhamento)

## 9. Referencias

- ADR-010: Git Flow (rollback por re-implantacao de TAG, registro)
- ADR-008: Governanca (cenarios A-D de rollback, SLAs, RACI)
- ADR-006: Pipeline de Ingestao (idempotencia, rebuild completo)
- ADR-011: Segregacao de KBs (rollback independente por KB)
- ADR-J01: Promocao Staging -> Producao (prevencao de rollback)
- ADR-J03: Hotfix (alternativa a rollback para erros pontuais)

<!-- conversion_quality: 95 -->
