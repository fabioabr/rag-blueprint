---
id: ADR-J03
doc_type: adr
title: "Hotfix — Procedimento Operacional de 6 Passos para Correção Urgente em Produção"
system: RAG Corporativo
module: Hotfix
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - hotfix
  - correção urgente
  - patch
  - versionamento semântico
  - release patch
  - produção
  - staging
  - fast track
  - qa rápido
  - aprovação
  - gate humano
  - pipeline de promoção
  - pipeline de ingestão
  - tag
  - branch de hotfix
  - pr
  - escopo mínimo
  - beta md
  - md final
  - front matter
  - confidentiality
  - pii
  - vazamento
  - lgpd
  - rollback
  - rebuild completo
  - idempotência
  - smoke test
  - testes focados
  - golden set
  - integridade
  - release version
  - rag workspace
  - rag knowledge base
  - curador
  - arquiteto
  - manager
  - director
  - compliance
  - multi kb
  - segregação por confidencialidade
  - kb pública
  - kb restrita
  - kb confidencial
  - integração com release
  - merge
  - conflitos
  - timeline
  - métricas de hotfix
  - frequência
  - taxa de sucesso
  - checklist
  - stakeholders
  - notificação
  - incidente
  - anonimização
  - contenção
  - procedimento operacional
  - correção pontual
aliases:
  - "ADR-J03"
  - "Hotfix"
  - "Procedimento de Hotfix"
  - "Correção Urgente em Produção"
  - "Hotfix da Base de Conhecimento"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/beta/ADR-J03_hotfix.beta.md"
source_beta_ids:
  - "BETA-J03"
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

# ADR-J03 — Hotfix — Procedimento Operacional de 6 Passos para Correção Urgente em Produção

| Campo       | Valor                                                         |
|-------------|---------------------------------------------------------------|
| **Status**  | Accepted                                                      |
| **Data**    | 23/03/2026                                                    |
| **Decisor** | fabio (arquitetura)                                           |
| **Escopo**  | Procedimento operacional de 6 passos para aplicar hotfix na base de conhecimento em produção, sem esperar a próxima release planejada |

**Referências cruzadas:**

- [[ADR-010]]: Git Flow (hotfix 6 passos, métricas, cenários)
- [[ADR-008]]: Governança (cenário C PII, rollback, papéis RACI)
- [[ADR-006]]: Pipeline de Ingestão (idempotência, rebuild)
- [[ADR-011]]: Segregação de KBs (hotfix independente por KB)
- [[ADR-J01]]: Promoção Staging → Produção (fluxo normal de referência)
- [[ADR-J02]]: Rollback de Release (quando hotfix não é suficiente)

---

## Contexto

Em situações de erro pontual em produção (1-3 documentos, erro de front matter, informação incorreta), um rollback completo seria desproporcional. O hotfix oferece um caminho rápido e controlado para correção sem esperar a próxima release planejada.

## Decisão

Documentar o procedimento operacional de 6 passos para aplicar hotfix (correção urgente) na base de conhecimento em produção, sem esperar a próxima release planejada.

## Definição

Hotfix é uma correção urgente em produção que não pode esperar a próxima release. Gera uma release PATCH dedicada (incremento do terceiro dígito do versionamento semântico: vX.Y.Z → vX.Y.Z+1).

Tempo total esperado: 1 a 4 horas (da detecção à produção).

## Quando Usar Hotfix (vs. Rollback)

| Cenário | Ação |
|---|---|
| 1-3 documentos com erro pontual | HOTFIX |
| Erro de front matter causando filtro incorreto | HOTFIX |
| Informação sensível vazou (PII/LGPD) | ROLLBACK imediato + HOTFIX |
| Muitos documentos com erro | ROLLBACK ([[ADR-J02]]) |
| Embedding model corrompeu vetores | ROLLBACK ([[ADR-J02]]) |
| Recall@10 caiu significativamente | ROLLBACK ([[ADR-J02]]) |

**Regra prática:**
- Problema PONTUAL (1-3 documentos, erro conhecido) → HOTFIX
- Problema AMPLO (muitos documentos, causa incerta) → ROLLBACK
- PII/vazamento → ROLLBACK imediato para conter, depois HOTFIX para corrigir na versão definitiva

## Procedimento de Hotfix — 6 Passos

### Passo 1 — Criar Release de Hotfix

**Pré-condições:**
- Problema identificado e documentado
- TAG atual em produção conhecida (ex: v1.2.0)
- Decisão de usar hotfix (vs. rollback) tomada

**Ações:**
a) Partir da TAG atualmente em produção no rag-workspace:
```bash
git checkout v1.2.0
```
b) Criar branch de consolidação do hotfix:
```bash
git checkout -b release/v1.2.1/main
```
c) Criar branch de trabalho para a correção:
```bash
git checkout -b release/v1.2.1/{username}/fix-{descricao}
```

**Convenção de versionamento:**
- Hotfix SEMPRE incrementa PATCH: v1.2.0 → v1.2.1
- Se já existe v1.2.1 (hotfix anterior), incrementar: v1.2.2
- NUNCA incrementar MINOR ou MAJOR em hotfix

### Passo 2 — Aplicar Correção

**Ações:**
a) Editar os .beta.md necessários no branch de trabalho
b) Correções típicas:
   - Conteúdo factualmente incorreto → corrigir texto
   - Front matter inválido → corrigir campo
   - Documento com classificação errada → ajustar confidentiality
   - Link quebrado → corrigir referência
   - PII detectado → anonimizar ou remover seção
c) Commit com mensagem clara:
```bash
git commit -m "hotfix: {descrição do problema corrigido}"
```
d) Criar PR para release/v1.2.1/main
   - Descrição do PR deve incluir: problema, causa, correção aplicada
   - Referenciar task ID ou incidente quando aplicável

**Regras:**
- Escopo MÍNIMO: corrigir apenas o problema identificado
- NÃO adicionar novos documentos em hotfix
- NÃO fazer refatorações ou melhorias "aproveitando a oportunidade"
- Se a correção exige mudanças amplas → não é hotfix, é nova release

### Passo 3 — QA Rápido

**Ações:**
a) QA score calculado APENAS nos documentos alterados (não precisa re-validar toda a base)
b) Front matter validado nos documentos alterados
c) Revisão focada no PR:
   - Verificar que a correção resolve o problema
   - Verificar que não introduz novos problemas
   - Verificar que escopo é mínimo (sem mudanças extras)
d) Aprovar PR (mínimo 1 aprovação — fast-track)

**Diferença em relação à release normal:**
- Release normal: QA em TODOS os documentos, 2 aprovações no PR
- Hotfix: QA apenas nos documentos ALTERADOS, 1 aprovação no PR
- Justificativa: urgência do hotfix justifica fast-track, porém staging é obrigatório (Passo 5)

### Passo 4 — TAG e Promoção

**Ações:**
a) Curador cria TAG no rag-workspace:
```bash
git tag -a v1.2.1 -m "Hotfix v1.2.1 — {descrição}"
```
b) TAG dispara pipeline de promoção:
   - Lê .beta.md da TAG v1.2.1
   - Remove marcadores LOCKED
   - Enriquece front matter
   - Gera .md finais
c) PR automático no rag-knowledge-base:
   - FAST-TRACK: 1 aprovação (em vez de 2 na release normal)
   - Aprovador verifica que apenas os documentos corrigidos mudaram
d) Após aprovação:
   - Merge no main do rag-knowledge-base
   - TAG v1.2.1 espelhada no rag-knowledge-base

### Passo 5 — Staging

**Ações:**
a) TAG v1.2.1 dispara pipeline de ingestão na Base Vetorial de staging
b) Testes FOCADOS (não precisa rodar suite completa):
   - Golden set: subset relevante para os documentos corrigidos
   - Verificação específica do fix: busca que reproduzia o problema agora retorna resultado correto
   - Teste de integridade: contagem de documentos e chunks confere
   - Teste de confidencialidade: se correção envolveu classificação

Se teste falha:
- Investigar, corrigir, incrementar patch (v1.2.2)
- Repetir a partir do Passo 2

### Passo 6 — Produção

**Ações:**
a) Aprovação manual obrigatória:
   - Mesmo em hotfix, gate humano é OBRIGATÓRIO
   - 1 aprovação (Curador ou Arquiteto)
b) Implantação manual em produção:
   - Pipeline usa TAG v1.2.1 (a mesma que passou em staging)
   - Rebuild completo (idempotente)
c) Pós-implantação:
   - Smoke test de produção
   - Verificação específica: problema original resolvido
   - release_version atualizada para v1.2.1
   - Notificação para stakeholders (versão, correção aplicada)

Tempo esperado do Passo 6: 30-60 minutos

## Timeline Completa de Hotfix

| Passo | Tempo Típico | Acumulado |
|---|---|---|
| 1. Criar release | 5-10 min | 10 min |
| 2. Aplicar correção | 15-30 min | 40 min |
| 3. QA rápido + aprovação PR | 15-30 min | 1h 10min |
| 4. TAG + promoção + PR KB | 20-40 min | 1h 50min |
| 5. Staging + testes focados | 30-60 min | 2h 50min |
| 6. Produção + smoke test | 30-60 min | 3h 50min |

**Total típico:** 2 a 4 horas

## Integração com Próxima Release

Após o hotfix ser implantado em produção:

a) As correções do hotfix DEVEM ser incorporadas na próxima release.
b) O branch release/v1.3.0/main (próxima release) deve fazer merge das correções do hotfix:
```bash
git merge release/v1.2.1/main
```
c) Se a próxima release já estava em andamento, verificar conflitos e resolver.
d) NÃO é aceitável que a próxima release "perca" as correções do hotfix.

## Hotfix em Contexto Multi-KB ([[ADR-011]])

Quando o modelo de segregação em 3 KBs está ativo:

- Hotfix é aplicado na KB específica afetada.
- Exemplo: erro em documento da KB restrita
  - kb-restricted@v1.0.3 → hotfix → kb-restricted@v1.0.4
  - kb-public-internal@v1.2.0 → não afetada
  - kb-confidential@v1.0.1 → não afetada
- Cada KB tem seu próprio ciclo, então hotfix em uma não impacta as demais.
- Pipeline de deploy por KB:
  - KB pública: hotfix pode ser fast-track (1 aprovação)
  - KB restrita: hotfix requer aprovação de Manager
  - KB confidencial: hotfix requer aprovação de Director + Compliance

## Hotfix para Incidente de PII

Quando o hotfix é motivado por vazamento de PII ou dado sensível:

**Sequência:**
1. **PRIMEIRO:** rollback imediato para TAG estável ([[ADR-J02]]) → contém o vazamento em minutos
2. **DEPOIS:** hotfix para corrigir o problema na versão definitiva → anonimizar/remover dado sensível no .beta.md → gerar nova TAG patch → promover via staging → produção
3. **PARALELO:** procedimento de incidente PII ([[ADR-008]] cenário C) → contenção, remoção, verificação de logs, ANPD se necessário

O rollback contém o problema RAPIDAMENTE. O hotfix corrige DEFINITIVAMENTE. Ambos são necessários.

## Checklist Rápido de Hotfix

- [ ] Problema identificado e documentado
- [ ] Decisão: hotfix (não rollback)
- [ ] Branch release/vX.Y.Z+1/main criado a partir da TAG em produção
- [ ] Correção aplicada (escopo mínimo)
- [ ] Commit com mensagem "hotfix: {descrição}"
- [ ] PR aprovado (1 aprovação, fast-track)
- [ ] TAG criada no workspace
- [ ] Pipeline de promoção gerou .md finais
- [ ] PR no knowledge-base aprovado (1 aprovação, fast-track)
- [ ] Staging: testes focados passaram
- [ ] Produção: aprovação manual obtida
- [ ] Produção: implantação + smoke test OK
- [ ] Problema original verificado como resolvido
- [ ] Stakeholders notificados
- [ ] Correções integradas na próxima release

## Métricas de Hotfix

| Métrica | Meta ([[ADR-010]]) |
|---|---|
| Frequência de hotfixes | < 2 por mês |
| Tempo total de hotfix | < 4 horas |
| Taxa de sucesso em staging | > 90% na primeira tentativa |
| Hotfixes que exigiram rollback | 0 (hotfix não deve piorar) |

Se a frequência de hotfixes exceder 2/mês consistentemente:
- Investigar causa raiz (QA insuficiente? staging fraco? processo?)
- Reforçar QA no Passo 1 do [[ADR-J01]] (release normal)
- Expandir golden set

## Referências

- [[ADR-010]]: Git Flow (hotfix 6 passos, métricas, cenários)
- [[ADR-008]]: Governança (cenário C PII, rollback, papéis RACI)
- [[ADR-006]]: Pipeline de Ingestão (idempotência, rebuild)
- [[ADR-011]]: Segregação de KBs (hotfix independente por KB)
- [[ADR-J01]]: Promoção Staging → Produção (fluxo normal de referência)
- [[ADR-J02]]: Rollback de Release (quando hotfix não é suficiente)

<!-- conversion_quality: 95 -->
