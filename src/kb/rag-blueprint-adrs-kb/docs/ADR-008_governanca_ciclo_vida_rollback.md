---
id: ADR-008
doc_type: adr
title: "Governança: Papéis, Ciclo de Vida do Documento e Rollback"
system: RAG Corporativo
module: Governança e Ciclo de Vida
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-21
tags:
  - governanca
  - papeis
  - raci
  - matriz responsabilidade
  - ciclo vida documento
  - rollback
  - pii
  - lgpd
  - bacen
  - quality gates
  - curadoria
  - capacity planning
  - maquina estados
  - transicao fases
  - criterios mensuraveis
  - auto deprecacao
  - incidente seguranca
  - runbook pii
  - contencao dados
  - remocao base vetorial
  - anonimizacao
  - compliance officer
  - arquiteto
  - curador conhecimento
  - engenheiro pipeline
  - dev api
  - operacoes
  - owner documento
  - segregacao funcoes
  - acumulo papeis
  - recall golden set
  - health check pipeline
  - chunks orfaos
  - consistencia repo
  - auditoria acesso
  - classificacao dados
  - escalonamento capacidade
  - projecao crescimento
  - storage estimado
  - ram recomendada
  - drill rollback
  - teste restore backup
  - calendario curadoria
  - cadencia semanal
  - cadencia mensal
  - cadencia trimestral
  - cadencia semestral
  - roadmap
  - anpd
  - root cause analysis
  - blocklist
  - scanner pii
aliases:
  - "ADR-008"
  - "Governança RAG"
  - "Ciclo de Vida do Documento"
  - "Rollback e Recuperação"
  - "RAG Governance and Document Lifecycle"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/beta/ADR-008_governanca_ciclo_vida_rollback.beta.md"
source_beta_ids:
  - "BETA-008"
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

# ADR-008 — Governança: Papéis, Ciclo de Vida do Documento e Rollback

## Referências Cruzadas

- **Depende de:** [[ADR-001]], [[ADR-004]], [[ADR-006]]
- **Relaciona-se:** [[ADR-002]], [[ADR-007]], [[ADR-009]]

## Contexto

### Por que esta ADR existe

A base de conhecimento corporativa com Base Vetorial é um sistema vivo: documentos são criados, editados, promovidos, consumidos e descontinuados. Sem governança explícita, surgem problemas previsíveis:

- **Ninguém sabe quem é responsável por quê** — documentos desatualizados ficam meses na base; PII vaza porque ninguém sabia que compliance deveria aprovar
- **Documentos ficam num limbo de maturidade** — rascunhos entram na Base Vetorial sem gate; documentos aprovados nunca são revisados
- **Sem procedimento claro para incidentes** — lote de ingestão com dados errados, PII indexada, Base Vetorial corrompida
- **Transição entre fases é subjetiva** — sem critérios mensuráveis, depende de "sentimento"

### Contexto Regulatório

- **LGPD (Lei 13.709/2018)**: dados pessoais ingeridos precisam de base legal; incidentes de PII exigem contenção e reporte em prazo legal (art. 48: comunicação à ANPD em 2 dias úteis)
- **BACEN (Resolução 4.893/2021)**: rastreabilidade, controle de acesso e auditoria para setor financeiro; retenção de logs mínimo 5 anos
- **SOX / Controles internos**: segregação de funções (quem aprova != quem executa)

### Interfaces com Outras Decisões

- [[ADR-001]] define o pipeline em 4 fases; este ADR define **QUEM** opera cada fase, **COMO** documentos transitam e **O QUE** fazer quando algo dá errado
- [[ADR-004]] define controles de segurança; este ADR define os **PROCEDIMENTOS** quando esses controles falham
- [[ADR-006]] define o pipeline de ingestão; este ADR depende da **idempotência** para rollbacks seguros

### Premissas

- Git é a fonte da verdade; a Base Vetorial é uma projeção regenerável
- Todo documento tem um owner identificável
- Pipeline de ingestão é idempotente ([[ADR-006]])
- Equipe pequena nas fases iniciais (1-3 pessoas); acúmulo de papéis é esperado e aceitável na Fase 1

## Decisão — 4 Pilares

A governança se apoia em 4 pilares complementares:

1. **Pilar 1 — Papéis e RACI** (QUEM faz O QUÊ)
2. **Pilar 2 — Ciclo de Vida do Documento** (COMO documentos evoluem)
3. **Pilar 3 — Rollback** (O QUE fazer quando algo dá errado)
4. **Pilar 4 — Critérios de Transição entre Fases** (QUANDO avançar no roadmap)

## Pilar 1 — Papéis e RACI

### Definição dos 7 Papéis

| Papel | Descrição | Responsabilidades-chave | Limites |
|-------|-----------|------------------------|---------|
| **Arquiteto** | Visão técnica do pipeline, schemas, ADRs | Definir schemas de front matter, projetar grafo, estratégias de chunking, aprovar mudanças estruturais | NÃO faz infra, conteúdo de domínio, nem opera pipeline em produção |
| **Curador de Conhecimento** | Especialista de domínio que edita e valida `.beta.md` | Editar `.beta.md`, validar conteúdo gerado por IA, curar glossário, submeter para revisão | NÃO edita knowledge-base repo, não opera pipeline |
| **Engenheiro de Pipeline** | Implementação e manutenção do pipeline de ingestão | Implementar/manter etapas do pipeline, executar ingestões, rollbacks, re-indexação | NÃO define arquitetura, não valida conteúdo |
| **Dev API/Consumo** | Camada de consumo: APIs, MCP server, agentes | Endpoints de busca, MCP server, agentes de IA, filtros pré-retrieval, reranking | NÃO opera pipeline, não define schemas |
| **Operações (Ops)** | Infraestrutura, monitoramento, backup | Provisionar infra, monitoramento, backups, resposta a incidentes, capacity planning | NÃO define arquitetura, não valida conteúdo |
| **Owner de Documento** | Responsável pela precisão de documentos específicos | Garantir atualização, responder alertas de auto-deprecação, aprovar mudanças | Atua SOMENTE sobre seus documentos |
| **Compliance Officer** | Conformidade com LGPD, BACEN, políticas internas | Classificação de dados, aprovar fontes sensíveis, liderar incidentes de PII, auditoria | NÃO define arquitetura, NÃO opera pipeline, pode VETAR conteúdo |

<!-- LOCKED:START autor=fabio data=2026-03-23 -->

### Matriz RACI

Legenda: **ARQ** = Arquiteto, **CUR** = Curador, **ENG** = Engenheiro de Pipeline, **DEV** = Dev API/Consumo, **OPS** = Operações, **OWN** = Owner de Documento, **CMP** = Compliance Officer

| Atividade | ARQ | CUR | ENG | DEV | OPS | OWN | CMP |
|-----------|-----|-----|-----|-----|-----|-----|-----|
| Ingestão de nova fonte | **A** | C | **R** | I | I | I | C |
| Edição de `.beta.md` | I | **R** | I | - | - | **A** | - |
| Promoção beta -> md | **A** | **R** | C | I | - | C | C |
| Release para Base Vetorial | C | I | **R** | I | **A** | - | I |
| Rollback urgente (PII) | I | I | **R** | C | **R** | I | **A** |
| Re-indexação completa | **A** | I | **R** | I | C | - | I |
| Curadoria de glossário | C | **A** | - | I | - | **R** | - |
| Definição de schema/front matter | **R** | C | C | I | - | I | C |
| Aprovação de fase (ex: Fase1->2) | **A** | C | C | C | C | - | C |
| Auditoria de acesso | I | - | I | I | **R** | - | **A** |
| Backup da Base Vetorial | I | - | - | - | **R** | - | **A** |
| Resposta a incidente de segurança | C | I | **R** | C | **R** | I | **A** |

**R** = Responsible (executa) / **A** = Accountable (responde pelo resultado) / **C** = Consulted / **I** = Informed

**Justificativas-chave:**

- **Ingestão**: Engenheiro executa, Arquiteto é accountable (nova fonte pode impactar schema/chunking/retrieval), Compliance consultado (dados sensíveis)
- **Promoção beta -> md**: Curador executa, Arquiteto é accountable (afeta fonte da verdade)
- **Rollback urgente PII**: Engenheiro E Operações ambos executam em paralelo (Ops contém APIs, Eng remove chunks), Compliance é accountable (implicações regulatórias)
- **Curadoria de glossário**: Owner executa (conhece definição do domínio), Curador é accountable (consistência global)

<!-- LOCKED:END -->

### Acúmulo de Papéis na Fase 1

**Combinações aceitáveis:**

- Arquiteto + Engenheiro de Pipeline (1 pessoa)
- Curador + Owner de Documento (1 pessoa)
- Dev API/Consumo + Operações (1 pessoa)

**Combinação PROIBIDA (mesmo na Fase 1):**

- Compliance Officer + qualquer papel operacional (segregação de funções obrigatória)

**Regras de transição:**

- A partir da Fase 2: desacoplar Arquiteto + Engenheiro
- A partir da Fase 3: cada papel com pelo menos 1 pessoa dedicada

## Pilar 2 — Ciclo de Vida do Documento

### Máquina de Estados

```
DRAFT -> IN-REVIEW -> APPROVED -> DEPRECATED
  ^         |                       |
  +─────────+ (rejeição)            |
  ^                                 |
  +─────────────────────────────────+ (reativação)
```

**Não existem atalhos** — um documento não pode ir de DRAFT direto para APPROVED.

### Transições Detalhadas

| Transição | Quem dispara | Pré-condições | Mecanismo |
|-----------|-------------|---------------|-----------|
| DRAFT -> IN-REVIEW | Curador/Owner | Front matter completo, sem TODOs, revisado pelo autor | Alterar status + criar PR no workspace |
| IN-REVIEW -> APPROVED | Arquiteto/PO | Revisão técnica + conteúdo + segurança | Aprovar PR -> merge -> promoção para knowledge-base |
| IN-REVIEW -> DRAFT | Arquiteto/PO | Problemas identificados na revisão | Solicitar mudanças no PR (rejeição sem justificativa é proibida) |
| APPROVED -> DEPRECATED | Owner (manual) ou Sistema (automático) | Manual: decisão do owner. Automático: 12 meses sem atualização | Alterar status + deprecated_reason. Auto: notifica owner, 30 dias para confirmar |
| DEPRECATED -> DRAFT | Owner/Curador | Justificativa + comprometimento de atualização. Aprovação do Arquiteto | Volta como DRAFT para re-validação integral |

### Impacto do Estado na Base Vetorial

| Estado | Indexação | Comportamento no retrieval |
|--------|-----------|---------------------------|
| DRAFT | NÃO indexado | Invisível |
| IN-REVIEW | NÃO indexado (padrão) | Invisível (opcionalmente visível apenas para reviewers com banner "[EM REVISÃO]") |
| APPROVED | Totalmente indexado | Plenamente pesquisável (com filtros de confidencialidade) |
| DEPRECATED | Indexado com flag `deprecated=true` | Pesquisável com rank reduzido (score x 0.5), warning na resposta, não aparece se há alternativa APPROVED |

**Por que DEPRECATED não é removido**: pode ser única fonte sobre sistema legado, contém contexto histórico, chunks já existem (economia de reprocessamento).

### RACI por Transição

| Transição | ARQ | CUR | ENG | DEV | OPS | OWN | CMP |
|-----------|-----|-----|-----|-----|-----|-----|-----|
| DRAFT -> IN-REVIEW | I | **R** | - | - | - | **A** | - |
| IN-REVIEW -> APPROVED | **A** | C | I | I | - | C | C* |
| IN-REVIEW -> DRAFT | **R** | I | - | - | - | I | - |
| APPROVED -> DEPRECATED | I | I | I | I | - | **R** | I |
| DEPRECATED -> DRAFT | **A** | C | - | - | - | **R** | - |

*CMP consultado apenas para docs restricted/confidential.

## Pilar 3 — Rollback

A premissa fundamental: a **idempotência** do pipeline ([[ADR-006]]) garante que re-processar um documento com o mesmo conteúdo produz exatamente o mesmo resultado na Base Vetorial.

### Cenário A — Rollback Granular (1 documento)

- **Urgência**: BAIXA a MÉDIA | **SLA**: 24 horas úteis
- **Procedimento**: Identificar problema -> Corrigir no repositório (editar `.beta.md` ou `git revert`) -> Re-executar pipeline para esse documento -> Validar via busca semântica
- **Responsável**: Engenheiro (R), Owner (A)

### Cenário B — Rollback de Lote (múltiplos documentos)

- **Urgência**: MÉDIA | **SLA**: 48 horas úteis
- **Procedimento**: Identificar lote via `batch_id` -> Avaliar estratégia (correção em docs vs pipeline) -> Corrigir -> Re-executar pipeline em batch -> Validar -> Registrar incidente
- **Responsável**: Engenheiro (R), Arquiteto (A)

**Tracking de lotes obrigatório**: cada execução registra `batch_id`, timestamps, documentos processados (sucesso/falha), trigger e `triggered_by`.

### Cenário C — Rollback Urgente (PII / Vazamento)

- **Urgência**: CRÍTICA | **SLA**: Contenção em 1 hora, remoção completa em 4 horas
- **Ativação**: qualquer pessoa pode ativar sem aprovação prévia. Compliance notificado nos primeiros 15 minutos.

**Classificação de severidade**:

| Severidade | Critério | SLA contenção | SLA remoção | Notificação |
|---|---|---|---|---|
| CRÍTICO | PII servida a usuário não autorizado | 15 min | 4 horas | Compliance imediata, possível reporte ANPD (2 dias úteis) |
| ALTO | PII indexada sem evidência de acesso | 1 hora | 4 horas | Compliance em até 1 hora |
| MÉDIO | PII detectada pré-ingestão | 4 horas | 24 horas | Compliance em até 4 horas |

**Os 5 Passos Urgentes**:

| Passo | SLA | Quem | Ações |
|-------|-----|------|-------|
| 1 — CONTER | 15 min | Ops/Eng (quem detectar) | Verificar se dados foram servidos (logs últimos 7 dias); adicionar doc à blocklist OU parar API; notificar Compliance; registrar no canal de incidentes. **NÃO tentar corrigir — apenas conter.** |
| 2 — Remover da Base Vetorial | 1 hora | Engenheiro | Identificar TODOS os chunks; exportar para evidência forense; deletar chunks, documento, índices, caches; verificar remoção (buscar por ID e semântica) |
| 3 — Remover do knowledge-base repo | 2 horas | Engenheiro | Deletar ou anonimizar `.md`; avaliar remoção do histórico Git (`git filter-branch` / BFG); commit "INCIDENTE-PII" |
| 4 — Verificar workspace repo | 3 horas | Curador + Engenheiro | Anonimizar/deletar `.beta.md`; verificar fontes brutas (`sources/`); buscar referências em outros documentos |
| 5 — Verificar logs | 4 horas | Ops + Compliance | Consultar logs de retrieval e resposta LLM; classificar impacto (PII não servida / servida a autorizados / servida a não autorizados); decidir sobre reporte ANPD |

**Opções de contenção (Passo 1)**:

- **Opção A — Blocklist**: documento não aparece em buscas mas permanece na base (1-2 min). Usar se blocklist implementada e testada.
- **Opção B — Parar API**: nenhum usuário consegue fazer queries (1-5 min). Usar se blocklist indisponível, múltiplos documentos afetados ou severidade CRÍTICA com evidência de acesso.

**Matriz de escalação**:

| Tempo desde detecção | Escalar para |
|---|---|
| 15 min | Compliance Officer |
| 30 min | Arquiteto + Gerente de Engenharia |
| 1 hora | DPO (Data Protection Officer) |
| 2 horas | Diretor de Tecnologia |
| 4 horas | Comitê de Crise (se PII servida) |

**REGRA**: nunca incluir a PII real nas comunicações de escalação. Referenciar por `document_id` e tipo de dado apenas.

**Pós-incidente (até 5 dias úteis)**:

- **Root Cause Analysis**: timeline completa, causa raiz (como PII entrou sem anonimização), impacto (titulares, tipo de dados, duração), eficácia da resposta, ações corretivas com responsável e prazo
- **Ações preventivas**: atualizar modelos NER/regex, implementar scanner PII pré-ingestão, expandir blocklist, treinamento para Curadores, adicionar caso ao golden set, revisar validação de output da LLM
- **Documentação**: RCA no knowledge-base repo (sem PII), atualização deste runbook, registro no log de incidentes (retenção 5 anos — BACEN)

**Requisitos legais de referência**:

- **LGPD art. 48**: comunicação à ANPD em 2 dias úteis, conteúdo: natureza dos dados, titulares, medidas técnicas, riscos, medidas de mitigação
- **LGPD art. 18 VI**: direito à eliminação dos dados pessoais
- **BACEN 4.893/2021**: rastreabilidade, auditoria, retenção de logs 5 anos
- **CVM 358/2002**: se PII inclui MNPI, notificar Compliance de mercado de capitais

### Cenário D — Rollback Completo (Restauração de backup)

- **Urgência**: ALTA | **SLA**: 8 horas
- **Procedimento**: Avaliar dano (parcial <20% -> cenário B; amplo >20% -> restore) -> Restaurar backup -> Re-indexar a partir do knowledge-base repo -> Validar integridade
- **Responsável**: Operações (R), Arquiteto (A), Engenheiro (C)

**Estimativa de tempo de recuperação:**

| Volume | Tempo estimado |
|--------|---------------|
| 50 documentos | ~5 minutos |
| 200 documentos | ~15 minutos |
| 1.000 documentos | ~30-45 minutos |
| 10.000+ documentos | ~4-8 horas |

## Pilar 4 — Critérios de Transição entre Fases

A transição entre fases NÃO é baseada em cronograma — é baseada em **critérios mensuráveis**.

### Fase 1 -> Fase 2 (MVP -> Metadados)

| Critério | Métrica |
|----------|---------|
| C1: Pipeline funcional end-to-end | 10 ingestões consecutivas sem falha |
| C2: Golden set mínimo | 20 pares pergunta/resposta, 3+ domínios |
| C3: Recall@10 >= 70% | Medido no golden set |
| C4: Front matter válido em 100% dos docs | 0 erros de parsing |
| C5: Monitoramento básico | Dashboard acessível com dados atualizados |

**Aprovação**: Arquiteto + PO, conjuntamente.

### Fase 2 -> Fase 3 (Metadados -> Knowledge Graph)

| Critério | Métrica |
|----------|---------|
| C1: Front matter validado (vocabulários controlados) | 0 warnings de validação |
| C2: Golden set expandido | 50 pares, 5+ domínios |
| C3: Recall@10 >= 80% | Medido no golden set expandido |
| C4: Filtros de confidencialidade testados | 100% cobertura, nenhum vazamento |
| C5: Backup operacional | Pelo menos 1 restore de teste bem-sucedido |

**Aprovação**: Arquiteto + PO, conjuntamente.

### Fase 3 -> Fase 4 (Knowledge Graph -> GraphRAG Corporativo)

| Critério | Métrica |
|----------|---------|
| C1: Knowledge graph com 5+ tipos de entidade | COUNT(DISTINCT labels) >= 7 |
| C2: Pelo menos 1 fonte não-.md integrada | >0 documentos de fonte não-.md |
| C3: Golden set robusto | 100 pares, 20 exigindo traversal |
| C4: Recall@10 >= 85% | Medido no golden set completo |
| C5: RBAC implementado | Testes cobrindo 3+ papéis com escopos diferentes |
| C6: Audit logging operacional | Logs pesquisáveis, retidos 90+ dias |

**Aprovação**: Arquiteto + PO + Compliance Officer, conjuntamente.

## Cadência de Curadoria

| Frequência | Quem | Duração | Atividades |
|------------|------|---------|------------|
| **Contínua** | Owner | Variável | Atualizar docs quando processo/sistema/regulação muda; responder alertas de auto-deprecação (12 meses sem atualização -> alerta, 30 dias para confirmar); manter front matter atualizado |
| **Semanal** | Engenheiro | 1-2h | Health check do pipeline (taxa falha < 5%); detectar chunks órfãos; verificar consistência repo <-> Base Vetorial; revisar alertas de monitoramento |
| **Mensal** | Arquiteto + Curador | 4-6h | Avaliação do golden set (Recall@10 com tendência); revisão do glossário (termos novos, consistência); avaliar docs deprecated > 3 meses; métricas de qualidade (front matter, status, distribuição chunks) |
| **Trimestral** | Arquiteto + Ops + Compliance | 1-2 dias | Auditoria de acesso (perfis, acessos indevidos); auditoria de classificação (amostragem por confidencialidade); limpeza deprecated > 6 meses; capacity planning (thresholds); drill de rollback (simulação); teste de restore de backup |
| **Semestral** | Todos os papéis | 2-3 dias | Revisão abrangente da base (cobertura por domínio, qualidade geral); avaliação de transição de fase (critérios Pilar 4); revisão de ADRs e tecnologias; roadmap para os próximos 6 meses |

### Entregáveis por cadência

- **Semanal**: checklist de saúde, lista de órfãos, divergências repo <-> Base Vetorial
- **Mensal**: relatório de Recall@10 com tendência, ações no glossário, decisões sobre deprecated, dashboard de métricas
- **Trimestral**: relatório de auditoria (acesso + classificação), lista de arquivados, relatório de capacity planning, registro de drill de rollback, registro de teste de restore
- **Semestral**: relatório semestral, decisão de transição de fase, plano de ação para ADRs, roadmap atualizado

## Capacity Planning

### Gatilhos de Ação

| Métrica | Threshold | Ação |
|---------|-----------|------|
| Uso de RAM (Base Vetorial) | > 80% | Investigar consumo (queries pesadas, índices não otimizados, cache excessivo). Se persistente: scale-up de memória |
| Uso de disco | > 70% | Planejar expansão para 6 meses. Calcular taxa de crescimento mensal, projetar quando atinge 90% |
| Latência p95 de busca | > 500ms | Otimizar índices, avaliar cache, verificar volume de chunks, considerar particionamento |
| Total de chunks | > 500.000 | Avaliar particionamento por domínio ou por KB, medir impacto na latência |
| Taxa de falha de ingestão | > 5% | Investigar pipeline e dados (front matter inválido, fonte corrompida, timeout embedding) |
| Tempo de re-indexação completa | > 4 horas | Paralelizar workers, otimizar batch size, considerar re-indexação incremental |
| Tempo de rollback | > 1 hora | Otimizar script de rebuild, avaliar backup mais recente, considerar blue-green |
| Tamanho de backup | Crescimento > 50% em 1 mês | Investigar: novos documentos ou duplicação? Ajustar retenção |

### Projeção de Crescimento

| Fase | Documentos | Chunks | Storage estimado | RAM recomendada |
|------|-----------|--------|-----------------|-----------------|
| Fase 1 | 20-100 | 200-1.000 | 2-10 MB | 2-4 GB |
| Fase 2 | 100-500 | 1K-5K | 10-50 MB | 4-8 GB |
| Fase 3 | 500-2.000 | 5K-20K | 50-200 MB | 8-16 GB |
| Fase 4 | 2.000-10K | 20K-100K | 200 MB - 1 GB | 16-32 GB |
| Escala | 10K-50K | 100K-500K | 1-5 GB | 32-64 GB |

**Notas**: storage inclui dados, índices, embeddings e metadados. Embeddings representam ~70% do storage. RAM considera Base Vetorial + índices + cache. Para multi-KB ([[ADR-011]]), multiplicar por número de KBs ativas.

### Heurísticas de Dimensionamento

**Estimativa de storage por documento:**

| Componente | Tamanho médio |
|---|---|
| Documento `.md` (texto) | 5-20 KB |
| Chunks (10 por doc, média) | 500 bytes - 2 KB cada |
| Embedding por chunk | 3-6 KB (768-1536 dim x float32) |
| Metadados (front matter) | 500 bytes - 1 KB |
| Índices | ~20% do total de dados |
| **Total por documento indexado** | **~50-100 KB** |

**Estimativa de RAM (Neo4j com vector index):**

- Base: 2 GB (overhead do sistema)
- Por 10.000 chunks: +1 GB (dados + índices)
- Por 10.000 vetores (embedding): +500 MB (HNSW index in-memory)
- Cache de queries: +1-2 GB (configurável)

### Procedimento de Escalonamento

1. **Nível 1 — Investigação** (Engenheiro): identificar causa raiz, verificar se é pico ou tendência
2. **Nível 2 — Plano de ação** (Arquiteto + Ops): definir ação corretiva, estimar custo e prazo
3. **Nível 3 — Execução** (Operações): implementar, validar que threshold voltou a nível aceitável
4. **Nível 4 — Revisão** (trimestral): revisar thresholds atingidos, ajustar se necessário, atualizar projeções

### Cenários de Escalonamento

- **Scale-up vertical**: aumentar recursos do servidor (Fases 1-3, volumes menores)
- **Scale-out horizontal por KB**: distribuir chunks entre instâncias por domínio (Fase 4+); modelo multi-KB do [[ADR-011]] já é forma natural de scale-out
- **Otimização de índices**: revisar HNSW parameters, índices auxiliares, cache (qualquer fase)
- **Paralelização de pipeline**: aumentar workers, otimizar batch size (Fase 3+)

## Alternativas Descartadas

| Alternativa | Motivo da rejeição |
|-------------|-------------------|
| Sem papéis formais ("todo mundo faz tudo") | Viola segregação de funções; sem accountability |
| Ciclo de vida binário (só APPROVED/DEPRECATED) | Sem quality gate; risco de indexar conteúdo não-validado |
| Rollback manual sem procedimentos | Sob pressão leva a erros; LGPD exige plano de resposta |
| Transição de fase por cronograma | Pressão para avançar sem fundações; dívida técnica |
| Auto-deprecação em 6 meses | Fadiga de re-validação para docs estáveis (ADRs); 12 meses é equilíbrio |

## Consequências

### Positivas

- Accountability clara para cada atividade
- Quality gates impedem conteúdo não-validado na Base Vetorial
- Rollback previsível com procedimento documentado para cada cenário
- Transições baseadas em evidência (métricas, não cronograma)
- Conformidade regulatória (LGPD, BACEN, controles internos)
- Escalabilidade organizacional (acúmulo na Fase 1, separação na Fase 3+)
- Procedimento de incidente PII com SLAs claros e checklist operacional

### Negativas / Trade-offs

- **Overhead de processo**: revisão IN-REVIEW adiciona latência (mitigação: fast-track com registro posterior)
- **Complexidade para equipes pequenas**: 7 papéis é excessivo para 1-2 pessoas (mitigação: acúmulo documentado)
- **Auto-deprecação pode ser agressiva**: threshold customizável por `doc_type`
- **Rollback urgente depende de logging**: mitigação via meta-monitoramento
- **Critérios podem atrasar projeto**: revisáveis semestralmente com justificativa

## Implementação (Faseamento)

### Fase 1 — Implementação Imediata

- **Semana 1**: documentar papéis, implementar campo `status` no front matter, validação de front matter, golden set inicial (20 perguntas)
- **Semana 2-3**: `batch_id` no pipeline, rollback granular, backup diário, dashboard mínimo
- **Semana 4**: documentar/drill rollback urgente PII, medir Recall@10, avaliar critérios Fase 1->2

### Fase 2 — Implementação Progressiva

- Máquina de estados no pipeline, rollback de lote, auto-deprecação (12 meses), notificações para Owners, expandir golden set (50), filtros de confidencialidade, testar restore

### Fase 3 — Maturidade

- Separar papéis, RBAC, audit logging, scanner PII, blocklist para rollback cirúrgico, golden set (100 com traversal), cadência formal de curadoria

## Referências

- [[ADR-001]]: Pipeline de geração de conhecimento em 4 fases
- [[ADR-002]]: Soberania de Dados
- [[ADR-004]]: Segurança, controle de acesso e conformidade
- [[ADR-006]]: Pipeline de ingestão (idempotência)
- [[ADR-007]]: Retrieval híbrido e agentes (feedback loop)
- [[ADR-009]]: Seleção de modelos de embedding
- [[ADR-011]]: Segregação de KBs (auditoria de acesso por MCP, multi-instância)
- LGPD (Lei 13.709/2018) — art. 48, art. 18
- BACEN Resolução 4.893/2021
- CVM Instrução 358/2002
- RACI Model (PMI)
- ANPD — Regulamento de Comunicação de Incidentes de Segurança

<!-- conversion_quality: 95 -->
