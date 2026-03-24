---
id: BETA-008
title: "Governanca: Papeis, Ciclo de Vida do Documento e Rollback"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-C05_incidente_pii.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-I01_calendario_curadoria.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-I02_capacity_planning_kb.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags: [governanca, papeis, raci, matriz responsabilidade, ciclo vida documento, rollback, pii, lgpd, bacen, quality gates, curadoria, capacity planning, maquina estados, transicao fases, criterios mensuraveis, auto-deprecacao, incidente seguranca, runbook pii, contencao dados, remocao base vetorial, anonimizacao, compliance officer, arquiteto, curador conhecimento, engenheiro pipeline, dev api, operacoes, owner documento, segregacao funcoes, acumulo papeis, recall golden set, health check pipeline, chunks orfaos, consistencia repo, auditoria acesso, classificacao dados, escalonamento capacidade, projecao crescimento, storage estimado, ram recomendada, drill rollback, teste restore backup, calendario curadoria, cadencia semanal, cadencia mensal, cadencia trimestral, cadencia semestral, roadmap, anpd, root cause analysis, blocklist, scanner pii]
aliases:
  - "ADR-008"
  - "Governanca RAG"
  - "Ciclo de Vida do Documento"
  - "Rollback e Recuperacao"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

# ADR-008 — Governanca: Papeis, Ciclo de Vida do Documento e Rollback

## Referencias Cruzadas

- **Depende de:** [[BETA-001]], [[BETA-004]], [[BETA-006]]
- **Relaciona-se:** [[BETA-002]], [[BETA-007]], [[BETA-009]]

## Contexto

### Por que esta ADR existe

A base de conhecimento corporativa com Base Vetorial e um sistema vivo: documentos sao criados, editados, promovidos, consumidos e descontinuados. Sem governanca explicita, surgem problemas previsiveis:

- **Ninguem sabe quem e responsavel por que** — documentos desatualizados ficam meses na base; PII vaza porque ninguem sabia que compliance deveria aprovar
- **Documentos ficam num limbo de maturidade** — rascunhos entram na Base Vetorial sem gate; documentos aprovados nunca sao revisados
- **Sem procedimento claro para incidentes** — lote de ingestao com dados errados, PII indexada, Base Vetorial corrompida
- **Transicao entre fases e subjetiva** — sem criterios mensuraveis, depende de "sentimento"

### Contexto Regulatorio

- **LGPD (Lei 13.709/2018)**: dados pessoais ingeridos precisam de base legal; incidentes de PII exigem contencao e reporte em prazo legal (art. 48: comunicacao a ANPD em 2 dias uteis)
- **BACEN (Resolucao 4.893/2021)**: rastreabilidade, controle de acesso e auditoria para setor financeiro; retencao de logs minimo 5 anos
- **SOX / Controles internos**: segregacao de funcoes (quem aprova != quem executa)

### Interfaces com Outras Decisoes

- [[BETA-001]] define o pipeline em 4 fases; este ADR define **QUEM** opera cada fase, **COMO** documentos transitam e **O QUE** fazer quando algo da errado
- [[BETA-004]] define controles de seguranca; este ADR define os **PROCEDIMENTOS** quando esses controles falham
- [[BETA-006]] define o pipeline de ingestao; este ADR depende da **idempotencia** para rollbacks seguros

### Premissas

- Git e a fonte da verdade; a Base Vetorial e uma projecao regeneravel
- Todo documento tem um owner identificavel
- Pipeline de ingestao e idempotente ([[BETA-006]])
- Equipe pequena nas fases iniciais (1-3 pessoas); acumulo de papeis e esperado e aceitavel na Fase 1

## Decisao — 4 Pilares

A governanca se apoia em 4 pilares complementares:

1. **Pilar 1 — Papeis e RACI** (QUEM faz O QUE)
2. **Pilar 2 — Ciclo de Vida do Documento** (COMO documentos evoluem)
3. **Pilar 3 — Rollback** (O QUE fazer quando algo da errado)
4. **Pilar 4 — Criterios de Transicao entre Fases** (QUANDO avancar no roadmap)

## Pilar 1 — Papeis e RACI

### Definicao dos 7 Papeis

| Papel | Descricao | Responsabilidades-chave | Limites |
|-------|-----------|------------------------|---------|
| **Arquiteto** | Visao tecnica do pipeline, schemas, ADRs | Definir schemas de front matter, projetar grafo, estrategias de chunking, aprovar mudancas estruturais | NAO faz infra, conteudo de dominio, nem opera pipeline em producao |
| **Curador de Conhecimento** | Especialista de dominio que edita e valida `.beta.md` | Editar `.beta.md`, validar conteudo gerado por IA, curar glossario, submeter para revisao | NAO edita knowledge-base repo, nao opera pipeline |
| **Engenheiro de Pipeline** | Implementacao e manutencao do pipeline de ingestao | Implementar/manter etapas do pipeline, executar ingestoes, rollbacks, re-indexacao | NAO define arquitetura, nao valida conteudo |
| **Dev API/Consumo** | Camada de consumo: APIs, MCP server, agentes | Endpoints de busca, MCP server, agentes de IA, filtros pre-retrieval, reranking | NAO opera pipeline, nao define schemas |
| **Operacoes (Ops)** | Infraestrutura, monitoramento, backup | Provisionar infra, monitoramento, backups, resposta a incidentes, capacity planning | NAO define arquitetura, nao valida conteudo |
| **Owner de Documento** | Responsavel pela precisao de documentos especificos | Garantir atualizacao, responder alertas de auto-deprecacao, aprovar mudancas | Atua SOMENTE sobre seus documentos |
| **Compliance Officer** | Conformidade com LGPD, BACEN, politicas internas | Classificacao de dados, aprovar fontes sensiveis, liderar incidentes de PII, auditoria | NAO define arquitetura, NAO opera pipeline, pode VETAR conteudo |

<!-- LOCKED:START autor=fabio data=2026-03-23 -->

### Matriz RACI

Legenda: **ARQ** = Arquiteto, **CUR** = Curador, **ENG** = Engenheiro de Pipeline, **DEV** = Dev API/Consumo, **OPS** = Operacoes, **OWN** = Owner de Documento, **CMP** = Compliance Officer

| Atividade | ARQ | CUR | ENG | DEV | OPS | OWN | CMP |
|-----------|-----|-----|-----|-----|-----|-----|-----|
| Ingestao de nova fonte | **A** | C | **R** | I | I | I | C |
| Edicao de `.beta.md` | I | **R** | I | - | - | **A** | - |
| Promocao beta -> md | **A** | **R** | C | I | - | C | C |
| Release para Base Vetorial | C | I | **R** | I | **A** | - | I |
| Rollback urgente (PII) | I | I | **R** | C | **R** | I | **A** |
| Re-indexacao completa | **A** | I | **R** | I | C | - | I |
| Curadoria de glossario | C | **A** | - | I | - | **R** | - |
| Definicao de schema/front matter | **R** | C | C | I | - | I | C |
| Aprovacao de fase (ex: Fase1->2) | **A** | C | C | C | C | - | C |
| Auditoria de acesso | I | - | I | I | **R** | - | **A** |
| Backup da Base Vetorial | I | - | - | - | **R** | - | **A** |
| Resposta a incidente de seguranca | C | I | **R** | C | **R** | I | **A** |

**R** = Responsible (executa) / **A** = Accountable (responde pelo resultado) / **C** = Consulted / **I** = Informed

**Justificativas-chave:**

- **Ingestao**: Engenheiro executa, Arquiteto e accountable (nova fonte pode impactar schema/chunking/retrieval), Compliance consultado (dados sensiveis)
- **Promocao beta -> md**: Curador executa, Arquiteto e accountable (afeta fonte da verdade)
- **Rollback urgente PII**: Engenheiro E Operacoes ambos executam em paralelo (Ops contem APIs, Eng remove chunks), Compliance e accountable (implicacoes regulatorias)
- **Curadoria de glossario**: Owner executa (conhece definicao do dominio), Curador e accountable (consistencia global)

<!-- LOCKED:END -->

### Acumulo de Papeis na Fase 1

**Combinacoes aceitaveis:**

- Arquiteto + Engenheiro de Pipeline (1 pessoa)
- Curador + Owner de Documento (1 pessoa)
- Dev API/Consumo + Operacoes (1 pessoa)

**Combinacao PROIBIDA (mesmo na Fase 1):**

- Compliance Officer + qualquer papel operacional (segregacao de funcoes obrigatoria)

**Regras de transicao:**

- A partir da Fase 2: desacoplar Arquiteto + Engenheiro
- A partir da Fase 3: cada papel com pelo menos 1 pessoa dedicada

## Pilar 2 — Ciclo de Vida do Documento

### Maquina de Estados

```
DRAFT -> IN-REVIEW -> APPROVED -> DEPRECATED
  ^         |                       |
  +─────────+ (rejeicao)            |
  ^                                 |
  +─────────────────────────────────+ (reativacao)
```

**Nao existem atalhos** — um documento nao pode ir de DRAFT direto para APPROVED.

### Transicoes Detalhadas

| Transicao | Quem dispara | Pre-condicoes | Mecanismo |
|-----------|-------------|---------------|-----------|
| DRAFT -> IN-REVIEW | Curador/Owner | Front matter completo, sem TODOs, revisado pelo autor | Alterar status + criar PR no workspace |
| IN-REVIEW -> APPROVED | Arquiteto/PO | Revisao tecnica + conteudo + seguranca | Aprovar PR -> merge -> promocao para knowledge-base |
| IN-REVIEW -> DRAFT | Arquiteto/PO | Problemas identificados na revisao | Solicitar mudancas no PR (rejeicao sem justificativa e proibida) |
| APPROVED -> DEPRECATED | Owner (manual) ou Sistema (automatico) | Manual: decisao do owner. Automatico: 12 meses sem atualizacao | Alterar status + deprecated_reason. Auto: notifica owner, 30 dias para confirmar |
| DEPRECATED -> DRAFT | Owner/Curador | Justificativa + comprometimento de atualizacao. Aprovacao do Arquiteto | Volta como DRAFT para re-validacao integral |

### Impacto do Estado na Base Vetorial

| Estado | Indexacao | Comportamento no retrieval |
|--------|-----------|---------------------------|
| DRAFT | NAO indexado | Invisivel |
| IN-REVIEW | NAO indexado (padrao) | Invisivel (opcionalmente visivel apenas para reviewers com banner "[EM REVISAO]") |
| APPROVED | Totalmente indexado | Plenamente pesquisavel (com filtros de confidencialidade) |
| DEPRECATED | Indexado com flag `deprecated=true` | Pesquisavel com rank reduzido (score x 0.5), warning na resposta, nao aparece se ha alternativa APPROVED |

**Por que DEPRECATED nao e removido**: pode ser unica fonte sobre sistema legado, contem contexto historico, chunks ja existem (economia de reprocessamento).

### RACI por Transicao

| Transicao | ARQ | CUR | ENG | DEV | OPS | OWN | CMP |
|-----------|-----|-----|-----|-----|-----|-----|-----|
| DRAFT -> IN-REVIEW | I | **R** | - | - | - | **A** | - |
| IN-REVIEW -> APPROVED | **A** | C | I | I | - | C | C* |
| IN-REVIEW -> DRAFT | **R** | I | - | - | - | I | - |
| APPROVED -> DEPRECATED | I | I | I | I | - | **R** | I |
| DEPRECATED -> DRAFT | **A** | C | - | - | - | **R** | - |

*CMP consultado apenas para docs restricted/confidential.

## Pilar 3 — Rollback

A premissa fundamental: a **idempotencia** do pipeline ([[BETA-006]]) garante que re-processar um documento com o mesmo conteudo produz exatamente o mesmo resultado na Base Vetorial.

### Cenario A — Rollback Granular (1 documento)

- **Urgencia**: BAIXA a MEDIA | **SLA**: 24 horas uteis
- **Procedimento**: Identificar problema -> Corrigir no repositorio (editar `.beta.md` ou `git revert`) -> Re-executar pipeline para esse documento -> Validar via busca semantica
- **Responsavel**: Engenheiro (R), Owner (A)

### Cenario B — Rollback de Lote (multiplos documentos)

- **Urgencia**: MEDIA | **SLA**: 48 horas uteis
- **Procedimento**: Identificar lote via `batch_id` -> Avaliar estrategia (correcao em docs vs pipeline) -> Corrigir -> Re-executar pipeline em batch -> Validar -> Registrar incidente
- **Responsavel**: Engenheiro (R), Arquiteto (A)

**Tracking de lotes obrigatorio**: cada execucao registra `batch_id`, timestamps, documentos processados (sucesso/falha), trigger e `triggered_by`.

### Cenario C — Rollback Urgente (PII / Vazamento)

- **Urgencia**: CRITICA | **SLA**: Contencao em 1 hora, remocao completa em 4 horas
- **Ativacao**: qualquer pessoa pode ativar sem aprovacao previa. Compliance notificado nos primeiros 15 minutos.

**Classificacao de severidade**:

| Severidade | Criterio | SLA contencao | SLA remocao | Notificacao |
|---|---|---|---|---|
| CRITICO | PII servida a usuario nao autorizado | 15 min | 4 horas | Compliance imediata, possivel reporte ANPD (2 dias uteis) |
| ALTO | PII indexada sem evidencia de acesso | 1 hora | 4 horas | Compliance em ate 1 hora |
| MEDIO | PII detectada pre-ingestao | 4 horas | 24 horas | Compliance em ate 4 horas |

**Os 5 Passos Urgentes**:

| Passo | SLA | Quem | Acoes |
|-------|-----|------|-------|
| 1 — CONTER | 15 min | Ops/Eng (quem detectar) | Verificar se dados foram servidos (logs ultimos 7 dias); adicionar doc a blocklist OU parar API; notificar Compliance; registrar no canal de incidentes. **NAO tentar corrigir — apenas conter.** |
| 2 — Remover da Base Vetorial | 1 hora | Engenheiro | Identificar TODOS os chunks; exportar para evidencia forense; deletar chunks, documento, indices, caches; verificar remocao (buscar por ID e semantica) |
| 3 — Remover do knowledge-base repo | 2 horas | Engenheiro | Deletar ou anonimizar `.md`; avaliar remocao do historico Git (`git filter-branch` / BFG); commit "INCIDENTE-PII" |
| 4 — Verificar workspace repo | 3 horas | Curador + Engenheiro | Anonimizar/deletar `.beta.md`; verificar fontes brutas (`sources/`); buscar referencias em outros documentos |
| 5 — Verificar logs | 4 horas | Ops + Compliance | Consultar logs de retrieval e resposta LLM; classificar impacto (PII nao servida / servida a autorizados / servida a nao autorizados); decidir sobre reporte ANPD |

**Opcoes de contencao (Passo 1)**:

- **Opcao A — Blocklist**: documento nao aparece em buscas mas permanece na base (1-2 min). Usar se blocklist implementada e testada.
- **Opcao B — Parar API**: nenhum usuario consegue fazer queries (1-5 min). Usar se blocklist indisponivel, multiplos documentos afetados ou severidade CRITICA com evidencia de acesso.

**Matriz de escalacao**:

| Tempo desde deteccao | Escalar para |
|---|---|
| 15 min | Compliance Officer |
| 30 min | Arquiteto + Gerente de Engenharia |
| 1 hora | DPO (Data Protection Officer) |
| 2 horas | Diretor de Tecnologia |
| 4 horas | Comite de Crise (se PII servida) |

**REGRA**: nunca incluir a PII real nas comunicacoes de escalacao. Referenciar por `document_id` e tipo de dado apenas.

**Pos-incidente (ate 5 dias uteis)**:

- **Root Cause Analysis**: timeline completa, causa raiz (como PII entrou sem anonimizacao), impacto (titulares, tipo de dados, duracao), eficacia da resposta, acoes corretivas com responsavel e prazo
- **Acoes preventivas**: atualizar modelos NER/regex, implementar scanner PII pre-ingestao, expandir blocklist, treinamento para Curadores, adicionar caso ao golden set, revisar validacao de output da LLM
- **Documentacao**: RCA no knowledge-base repo (sem PII), atualizacao deste runbook, registro no log de incidentes (retencao 5 anos — BACEN)

**Requisitos legais de referencia**:

- **LGPD art. 48**: comunicacao a ANPD em 2 dias uteis, conteudo: natureza dos dados, titulares, medidas tecnicas, riscos, medidas de mitigacao
- **LGPD art. 18 VI**: direito a eliminacao dos dados pessoais
- **BACEN 4.893/2021**: rastreabilidade, auditoria, retencao de logs 5 anos
- **CVM 358/2002**: se PII inclui MNPI, notificar Compliance de mercado de capitais

### Cenario D — Rollback Completo (Restauracao de backup)

- **Urgencia**: ALTA | **SLA**: 8 horas
- **Procedimento**: Avaliar dano (parcial <20% -> cenario B; amplo >20% -> restore) -> Restaurar backup -> Re-indexar a partir do knowledge-base repo -> Validar integridade
- **Responsavel**: Operacoes (R), Arquiteto (A), Engenheiro (C)

**Estimativa de tempo de recuperacao:**

| Volume | Tempo estimado |
|--------|---------------|
| 50 documentos | ~5 minutos |
| 200 documentos | ~15 minutos |
| 1.000 documentos | ~30-45 minutos |
| 10.000+ documentos | ~4-8 horas |

## Pilar 4 — Criterios de Transicao entre Fases

A transicao entre fases NAO e baseada em cronograma — e baseada em **criterios mensuraveis**.

### Fase 1 -> Fase 2 (MVP -> Metadados)

| Criterio | Metrica |
|----------|---------|
| C1: Pipeline funcional end-to-end | 10 ingestoes consecutivas sem falha |
| C2: Golden set minimo | 20 pares pergunta/resposta, 3+ dominios |
| C3: Recall@10 >= 70% | Medido no golden set |
| C4: Front matter valido em 100% dos docs | 0 erros de parsing |
| C5: Monitoramento basico | Dashboard acessivel com dados atualizados |

**Aprovacao**: Arquiteto + PO, conjuntamente.

### Fase 2 -> Fase 3 (Metadados -> Knowledge Graph)

| Criterio | Metrica |
|----------|---------|
| C1: Front matter validado (vocabularios controlados) | 0 warnings de validacao |
| C2: Golden set expandido | 50 pares, 5+ dominios |
| C3: Recall@10 >= 80% | Medido no golden set expandido |
| C4: Filtros de confidencialidade testados | 100% cobertura, nenhum vazamento |
| C5: Backup operacional | Pelo menos 1 restore de teste bem-sucedido |

**Aprovacao**: Arquiteto + PO, conjuntamente.

### Fase 3 -> Fase 4 (Knowledge Graph -> GraphRAG Corporativo)

| Criterio | Metrica |
|----------|---------|
| C1: Knowledge graph com 5+ tipos de entidade | COUNT(DISTINCT labels) >= 7 |
| C2: Pelo menos 1 fonte nao-.md integrada | >0 documentos de fonte nao-.md |
| C3: Golden set robusto | 100 pares, 20 exigindo traversal |
| C4: Recall@10 >= 85% | Medido no golden set completo |
| C5: RBAC implementado | Testes cobrindo 3+ papeis com escopos diferentes |
| C6: Audit logging operacional | Logs pesquisaveis, retidos 90+ dias |

**Aprovacao**: Arquiteto + PO + Compliance Officer, conjuntamente.

## Cadencia de Curadoria

| Frequencia | Quem | Duracao | Atividades |
|------------|------|---------|------------|
| **Continua** | Owner | Variavel | Atualizar docs quando processo/sistema/regulacao muda; responder alertas de auto-deprecacao (12 meses sem atualizacao -> alerta, 30 dias para confirmar); manter front matter atualizado |
| **Semanal** | Engenheiro | 1-2h | Health check do pipeline (taxa falha < 5%); detectar chunks orfaos; verificar consistencia repo <-> Base Vetorial; revisar alertas de monitoramento |
| **Mensal** | Arquiteto + Curador | 4-6h | Avaliacao do golden set (Recall@10 com tendencia); revisao do glossario (termos novos, consistencia); avaliar docs deprecated > 3 meses; metricas de qualidade (front matter, status, distribuicao chunks) |
| **Trimestral** | Arquiteto + Ops + Compliance | 1-2 dias | Auditoria de acesso (perfis, acessos indevidos); auditoria de classificacao (amostragem por confidencialidade); limpeza deprecated > 6 meses; capacity planning (thresholds); drill de rollback (simulacao); teste de restore de backup |
| **Semestral** | Todos os papeis | 2-3 dias | Revisao abrangente da base (cobertura por dominio, qualidade geral); avaliacao de transicao de fase (criterios Pilar 4); revisao de ADRs e tecnologias; roadmap para os proximos 6 meses |

### Entregaveis por cadencia

- **Semanal**: checklist de saude, lista de orfaos, divergencias repo <-> Base Vetorial
- **Mensal**: relatorio de Recall@10 com tendencia, acoes no glossario, decisoes sobre deprecated, dashboard de metricas
- **Trimestral**: relatorio de auditoria (acesso + classificacao), lista de arquivados, relatorio de capacity planning, registro de drill de rollback, registro de teste de restore
- **Semestral**: relatorio semestral, decisao de transicao de fase, plano de acao para ADRs, roadmap atualizado

## Capacity Planning

### Gatilhos de Acao

| Metrica | Threshold | Acao |
|---------|-----------|------|
| Uso de RAM (Base Vetorial) | > 80% | Investigar consumo (queries pesadas, indices nao otimizados, cache excessivo). Se persistente: scale-up de memoria |
| Uso de disco | > 70% | Planejar expansao para 6 meses. Calcular taxa de crescimento mensal, projetar quando atinge 90% |
| Latencia p95 de busca | > 500ms | Otimizar indices, avaliar cache, verificar volume de chunks, considerar particionamento |
| Total de chunks | > 500.000 | Avaliar particionamento por dominio ou por KB, medir impacto na latencia |
| Taxa de falha de ingestao | > 5% | Investigar pipeline e dados (front matter invalido, fonte corrompida, timeout embedding) |
| Tempo de re-indexacao completa | > 4 horas | Paralelizar workers, otimizar batch size, considerar re-indexacao incremental |
| Tempo de rollback | > 1 hora | Otimizar script de rebuild, avaliar backup mais recente, considerar blue-green |
| Tamanho de backup | Crescimento > 50% em 1 mes | Investigar: novos documentos ou duplicacao? Ajustar retencao |

### Projecao de Crescimento

| Fase | Documentos | Chunks | Storage estimado | RAM recomendada |
|------|-----------|--------|-----------------|-----------------|
| Fase 1 | 20-100 | 200-1.000 | 2-10 MB | 2-4 GB |
| Fase 2 | 100-500 | 1K-5K | 10-50 MB | 4-8 GB |
| Fase 3 | 500-2.000 | 5K-20K | 50-200 MB | 8-16 GB |
| Fase 4 | 2.000-10K | 20K-100K | 200 MB - 1 GB | 16-32 GB |
| Escala | 10K-50K | 100K-500K | 1-5 GB | 32-64 GB |

**Notas**: storage inclui dados, indices, embeddings e metadados. Embeddings representam ~70% do storage. RAM considera Base Vetorial + indices + cache. Para multi-KB ([[BETA-011]]), multiplicar por numero de KBs ativas.

### Heuristicas de Dimensionamento

**Estimativa de storage por documento:**

| Componente | Tamanho medio |
|---|---|
| Documento `.md` (texto) | 5-20 KB |
| Chunks (10 por doc, media) | 500 bytes - 2 KB cada |
| Embedding por chunk | 3-6 KB (768-1536 dim x float32) |
| Metadados (front matter) | 500 bytes - 1 KB |
| Indices | ~20% do total de dados |
| **Total por documento indexado** | **~50-100 KB** |

**Estimativa de RAM (Neo4j com vector index):**

- Base: 2 GB (overhead do sistema)
- Por 10.000 chunks: +1 GB (dados + indices)
- Por 10.000 vetores (embedding): +500 MB (HNSW index in-memory)
- Cache de queries: +1-2 GB (configuravel)

### Procedimento de Escalonamento

1. **Nivel 1 — Investigacao** (Engenheiro): identificar causa raiz, verificar se e pico ou tendencia
2. **Nivel 2 — Plano de acao** (Arquiteto + Ops): definir acao corretiva, estimar custo e prazo
3. **Nivel 3 — Execucao** (Operacoes): implementar, validar que threshold voltou a nivel aceitavel
4. **Nivel 4 — Revisao** (trimestral): revisar thresholds atingidos, ajustar se necessario, atualizar projecoes

### Cenarios de Escalonamento

- **Scale-up vertical**: aumentar recursos do servidor (Fases 1-3, volumes menores)
- **Scale-out horizontal por KB**: distribuir chunks entre instancias por dominio (Fase 4+); modelo multi-KB do [[BETA-011]] ja e forma natural de scale-out
- **Otimizacao de indices**: revisar HNSW parameters, indices auxiliares, cache (qualquer fase)
- **Paralelizacao de pipeline**: aumentar workers, otimizar batch size (Fase 3+)

## Alternativas Descartadas

| Alternativa | Motivo da rejeicao |
|-------------|-------------------|
| Sem papeis formais ("todo mundo faz tudo") | Viola segregacao de funcoes; sem accountability |
| Ciclo de vida binario (so APPROVED/DEPRECATED) | Sem quality gate; risco de indexar conteudo nao-validado |
| Rollback manual sem procedimentos | Sob pressao leva a erros; LGPD exige plano de resposta |
| Transicao de fase por cronograma | Pressao para avancar sem fundacoes; divida tecnica |
| Auto-deprecacao em 6 meses | Fadiga de re-validacao para docs estaveis (ADRs); 12 meses e equilibrio |

## Consequencias

### Positivas

- Accountability clara para cada atividade
- Quality gates impedem conteudo nao-validado na Base Vetorial
- Rollback previsivel com procedimento documentado para cada cenario
- Transicoes baseadas em evidencia (metricas, nao cronograma)
- Conformidade regulatoria (LGPD, BACEN, controles internos)
- Escalabilidade organizacional (acumulo na Fase 1, separacao na Fase 3+)
- Procedimento de incidente PII com SLAs claros e checklist operacional

### Negativas / Trade-offs

- **Overhead de processo**: revisao IN-REVIEW adiciona latencia (mitigacao: fast-track com registro posterior)
- **Complexidade para equipes pequenas**: 7 papeis e excessivo para 1-2 pessoas (mitigacao: acumulo documentado)
- **Auto-deprecacao pode ser agressiva**: threshold customizavel por `doc_type`
- **Rollback urgente depende de logging**: mitigacao via meta-monitoramento
- **Criterios podem atrasar projeto**: revisaveis semestralmente com justificativa

## Implementacao (Faseamento)

### Fase 1 — Implementacao Imediata

- **Semana 1**: documentar papeis, implementar campo `status` no front matter, validacao de front matter, golden set inicial (20 perguntas)
- **Semana 2-3**: `batch_id` no pipeline, rollback granular, backup diario, dashboard minimo
- **Semana 4**: documentar/drill rollback urgente PII, medir Recall@10, avaliar criterios Fase 1->2

### Fase 2 — Implementacao Progressiva

- Maquina de estados no pipeline, rollback de lote, auto-deprecacao (12 meses), notificacoes para Owners, expandir golden set (50), filtros de confidencialidade, testar restore

### Fase 3 — Maturidade

- Separar papeis, RBAC, audit logging, scanner PII, blocklist para rollback cirurgico, golden set (100 com traversal), cadencia formal de curadoria

## Referencias

- [[BETA-001]]: Pipeline de geracao de conhecimento em 4 fases
- [[BETA-002]]: Soberania de Dados
- [[BETA-004]]: Seguranca, controle de acesso e conformidade
- [[BETA-006]]: Pipeline de ingestao (idempotencia)
- [[BETA-007]]: Retrieval hibrido e agentes (feedback loop)
- [[BETA-009]]: Selecao de modelos de embedding
- [[BETA-011]]: Segregacao de KBs (auditoria de acesso por MCP, multi-instancia)
- LGPD (Lei 13.709/2018) — art. 48, art. 18
- BACEN Resolucao 4.893/2021
- CVM Instrucao 358/2002
- RACI Model (PMI)
- ANPD — Regulamento de Comunicacao de Incidentes de Seguranca

<!-- conversion_quality: 95 -->
