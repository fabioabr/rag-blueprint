---
id: ADR-J01
doc_type: adr
title: "Promoção de Staging para Produção — Procedimento Operacional de 4 Passos"
system: RAG Corporativo
module: Promoção para Produção
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - promoção staging produção
  - release
  - deploy
  - consolidação
  - tag release
  - staging
  - produção
  - pipeline de promoção
  - pipeline de ingestão
  - qa score
  - gate humano
  - aprovação manual
  - pr automático
  - merge
  - rag workspace
  - rag knowledge base
  - base vetorial
  - golden set
  - recall
  - smoke test
  - testes automatizados
  - testes de acesso
  - confidencialidade
  - integridade
  - contagem de documentos
  - contagem de chunks
  - agentes de ia
  - mcp
  - curador
  - arquiteto
  - po
  - operações
  - wikilinks
  - front matter
  - changelog
  - release notes
  - beta md
  - md final
  - blocos locked
  - versionamento semântico
  - idempotência
  - release version
  - monitoramento
  - latência
  - rollback
  - hotfix
  - staging failed
  - patch
  - checklist
  - stakeholders
  - notificação
  - tempos de referência
  - fluxo de 4 passos
  - critérios de saída
  - pré condições
aliases:
  - "ADR-J01"
  - "Promoção Staging Produção"
  - "Promoção de Staging para Produção"
  - "Deploy para Produção"
  - "Release para Produção KB"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/beta/ADR-J01_promocao_staging_producao.beta.md"
source_beta_ids:
  - "BETA-J01"
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

# ADR-J01 — Promoção de Staging para Produção — Procedimento Operacional de 4 Passos

| Campo       | Valor                                                         |
|-------------|---------------------------------------------------------------|
| **Status**  | Accepted                                                      |
| **Data**    | 23/03/2026                                                    |
| **Decisor** | fabio (arquitetura)                                           |
| **Escopo**  | Procedimento operacional de 4 passos para promover uma release de staging para produção na base de conhecimento |

**Referências cruzadas:**

- [[ADR-010]]: Git Flow (Release-Based Flow, 4 passos de promoção)
- [[ADR-006]]: Pipeline de Ingestão (7 etapas, idempotência)
- [[ADR-008]]: Governança (Pilar 4 critérios, golden set, papéis)
- [[ADR-001]]: Pipeline 4 Fases (promoção .beta.md → .md, TAGs)
- [[ADR-J02]]: Rollback de Release (quando staging ou produção falha)
- [[ADR-J03]]: Hotfix (correção urgente sem esperar próxima release)

---

## Contexto

O [[ADR-010]] define o Release-Based Flow para a base de conhecimento. Este ADR documenta o procedimento operacional detalhado para cada um dos 4 passos de promoção, desde a consolidação até a implantação em produção.

## Decisão

Documentar o procedimento operacional de 4 passos para promover uma release de staging para produção na base de conhecimento, incluindo pré-condições, ações detalhadas e critérios de saída para cada passo.

**REGRA FUNDAMENTAL:** nenhum dado chega em produção sem passar por staging. A implantação em produção é SEMPRE manual (gate humano obrigatório).

## Visão Geral do Fluxo

```
Passo 1: Consolidação (branches mergeadas, QA aprovado)
    |
    v
Passo 2: TAG Release (TAG no workspace, pipeline gera .md, PR no KB)
    |
    v
Passo 3: Staging (ingestão na Base Vetorial staging, testes)
    |
    v
Passo 4: Produção (aprovação manual, implantação, smoke test)
```

## Passo 1 — Consolidação

**Pré-condições:**
- Todas as branches de trabalho mergeadas em release/vX.Y.Z/main
- Nenhum Pull Request pendente no release/vX.Y.Z/
- Zero alertas `<!-- CONFLICT -->` não resolvidos nos .beta.md
- Zero alertas `<!-- LOCKED-CONFLICT -->` não resolvidos

**Ações:**

### Curador revisa estado consolidado do release/vX.Y.Z/main

- Navegar pelos .beta.md alterados nesta release
- Verificar que conteúdo está completo e coerente
- Confirmar que todos os blocos LOCKED estão intactos

### QA automatizado executa

- Validação de front matter em todos os .beta.md (schema completo)
- Cálculo de QA score por documento
- Verificação de wikilinks (todos apontam para documentos existentes)
- Verificação de consistência de tags e glossário

### Curador gera relatório de release (changelog)

- Lista de documentos novos nesta release
- Lista de documentos atualizados (com resumo das mudanças)
- Lista de documentos depreciados
- QA score consolidado

**Critérios de saída:**
- [ ] QA score >= 90% em todos os documentos (ou 80-89% com qa_notes documentado no front matter)
- [ ] Abaixo de 80% é BLOQUEANTE — retorna para edição
- [ ] Relatório de release gerado e revisado pelo Curador
- [ ] Zero conflitos não resolvidos
- [ ] Todos os wikilinks válidos

**Responsável:** Curador (R), Arquiteto (A)

## Passo 2 — TAG Release

**Pré-condições:**
- Passo 1 concluído e aprovado
- QA score dentro do threshold

**Ações:**

### Curador cria TAG vX.Y.Z no branch release/vX.Y.Z/main do rag-workspace

```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z — {descrição breve}"
```

### TAG dispara automaticamente pipeline de promoção

a) Lê .beta.md do rag-workspace (TAG vX.Y.Z)
b) Remove marcadores LOCKED (conteúdo preservado, marcadores removidos)
c) Enriquece front matter: adiciona campos de governança (system, module, owner, team, QA score, qa_notes)
d) Gera .md final (fonte da verdade)
e) Cria PR automático no rag-knowledge-base com os .md gerados

### PR no rag-knowledge-base requer 2 aprovações

- PO: valida conteúdo (correto, completo, alinhado com negócio)
- Arquiteto: valida integridade técnica (front matter, schema, wikilinks, estrutura)

### Após aprovação do PR

- Merge no main do rag-knowledge-base
- TAG vX.Y.Z espelhada no rag-knowledge-base
- Verificar sincronização de TAGs entre os 2 repos

**Critérios de saída:**
- [ ] TAG vX.Y.Z criada no rag-workspace
- [ ] Pipeline de promoção executou com sucesso
- [ ] .md finais gerados com front matter rico
- [ ] PR criado no rag-knowledge-base
- [ ] PR aprovado por PO + Arquiteto (2 aprovações)
- [ ] TAG vX.Y.Z espelhada no rag-knowledge-base

**Responsável:** Curador (TAG), Pipeline (promoção), PO + Arquiteto (aprovação)

## Passo 3 — Staging

**Pré-condições:**
- TAG vX.Y.Z criada no rag-knowledge-base
- Base Vetorial de staging disponível e limpa (ou pronta para rebuild)

**Ações:**

### TAG dispara automaticamente pipeline de ingestão na Base Vetorial de staging

Seguindo as 7 etapas do [[ADR-006]]:
a) Descoberta: identificar .md na TAG
b) Parse: extrair front matter, headings, links internos
c) Chunking: quebrar por headings, herdar metadados
d) Embeddings: gerar embedding por chunk
e) Persistência: upsert Document/Chunk, criar relações
f) Indexação: vector index + índices auxiliares
g) Observabilidade: métricas de volume, falhas, latência

### Testes automatizados executam

a) **Golden Set:** executar pares pergunta/resposta contra staging
   - Recall@10 >= threshold da fase atual ([[ADR-008]] Pilar 4)
   - Comparar com resultado anterior (não pode ter regressão significativa)

b) **Testes de acesso por confidencialidade:**
   - Documento public acessível via MCP público
   - Documento restricted NÃO acessível via MCP público
   - Filtros pré-retrieval funcionando

c) **Testes de integridade:**
   - Contagem de documentos na Base Vetorial confere com .md no Git
   - Contagem de chunks dentro da faixa esperada
   - Índices vetoriais funcionais (busca retorna resultados)

d) **Smoke tests dos agentes:**
   - Agentes de IA conseguem consultar via MCP
   - Respostas incluem citações de origem

### Se qualquer teste falha

- Marcar como "staging-failed"
- Curador investiga causa raiz
- Correção via nova TAG patch (vX.Y.Z+1)
- Repetir a partir do Passo 1 (para patch)

**Critérios de saída:**
- [ ] Pipeline de ingestão executou com sucesso em staging
- [ ] Golden Set Recall@10 >= threshold
- [ ] Testes de confidencialidade passaram (zero vazamentos)
- [ ] Testes de integridade passaram
- [ ] Smoke tests dos agentes passaram
- [ ] Zero testes falhando

**Responsável:** Pipeline (ingestão), QA automatizado (testes), Curador (análise)

## Passo 4 — Produção

**Pré-condições:**
- Passo 3 concluído e TODOS os testes passando
- Nenhum teste em estado "staging-failed"

**Ações:**

### Aprovação manual OBRIGATÓRIA

- PO aprova conteúdo (valida que o que está em staging é o esperado)
- Arquiteto aprova integridade técnica
- Ambas aprovações registradas com timestamp e responsável

### Implantação manual em produção

- NUNCA automática (gate humano obrigatório)
- Operador executa pipeline usando a MESMA TAG que passou em staging
- Pipeline é idempotente ([[ADR-006]]): mesma TAG = mesmo resultado
- Base Vetorial de produção é reconstruída (rebuild completo)

### Pós-implantação

a) release_version registrada na Base Vetorial (metadado que identifica qual TAG está em produção)

b) Smoke test de produção:
   - Busca semântica funciona
   - Agentes retornam resultados com citações
   - Latência dentro do esperado (p95 < 500ms)

c) Notificação para stakeholders:
   - E-mail ou mensagem com: versão implantada, changelog resumido, responsável pela implantação

d) Monitoramento intensivo nas primeiras 2 horas:
   - Observar latência, taxa de erro, volume de queries
   - Qualquer anomalia: avaliar rollback ([[ADR-J02]])

**Critérios de saída:**
- [ ] Aprovação de PO + Arquiteto registrada
- [ ] Pipeline de produção executou com sucesso
- [ ] release_version registrada
- [ ] Smoke test de produção passou
- [ ] Stakeholders notificados
- [ ] Monitoramento de 2 horas concluído sem anomalias

**Responsável:** PO + Arquiteto (aprovação), Curador/Ops (implantação)

## Tempos de Referência

| Passo | Tempo Típico |
|---|---|
| Passo 1 (Consolidação) | 1-2 horas |
| Passo 2 (TAG + PR) | 2-4 horas (inclui aprovações) |
| Passo 3 (Staging + testes) | 1-4 horas (depende do volume) |
| Passo 4 (Produção) | 1-3 horas (inclui monitoramento) |
| **Total** | **5-13 horas (tipicamente 1 dia útil)** |

## Checklist Rápido para o Curador

- [ ] Todas branches mergeadas, zero PRs pendentes
- [ ] QA score >= 90% (ou 80-89% com qa_notes)
- [ ] Zero conflitos não resolvidos
- [ ] TAG criada no workspace
- [ ] PR aprovado no knowledge-base (PO + Arquiteto)
- [ ] Staging: todos os testes passaram
- [ ] Produção: aprovação manual obtida
- [ ] Produção: implantação concluída + smoke test OK
- [ ] Stakeholders notificados
- [ ] 2 horas de monitoramento sem anomalias

## Referências

- [[ADR-010]]: Git Flow (Release-Based Flow, 4 passos de promoção)
- [[ADR-006]]: Pipeline de Ingestão (7 etapas, idempotência)
- [[ADR-008]]: Governança (Pilar 4 critérios, golden set, papéis)
- [[ADR-001]]: Pipeline 4 Fases (promoção .beta.md → .md, TAGs)
- [[ADR-J02]]: Rollback de Release (quando staging ou produção falha)
- [[ADR-J03]]: Hotfix (correção urgente sem esperar próxima release)

<!-- conversion_quality: 95 -->
