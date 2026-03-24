---
id: ADR-I01
doc_type: adr
title: "Calendário de Curadoria — Cadências Contínua, Semanal, Mensal, Trimestral e Semestral"
system: RAG Corporativo
module: Curadoria
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - calendário de curadoria
  - curadoria
  - cadência contínua
  - cadência semanal
  - cadência mensal
  - cadência trimestral
  - cadência semestral
  - health check
  - chunks órfãos
  - consistência
  - golden set
  - recall
  - glossário
  - documentos deprecated
  - auto depreciação
  - front matter
  - ciclo de vida
  - governança
  - papéis e responsabilidades
  - owner de documento
  - engenheiro de pipeline
  - arquiteto
  - curador de conhecimento
  - compliance officer
  - operações
  - auditoria de acesso
  - auditoria de classificação
  - capacity planning
  - drill de rollback
  - teste de restore
  - transição de fase
  - roadmap
  - revisão de adrs
  - modelos de embedding
  - base vetorial
  - neo4j
  - mcp
  - pipeline de ingestão
  - qualidade
  - métricas
  - threshold
  - alerta
  - monitoramento
  - domínio
  - cobertura
  - distribuição de chunks
  - rbac
  - audit logging
  - raci
  - entregável
  - calendário consolidado
  - atividades periódicas
aliases:
  - "ADR-I01"
  - "Calendário de Curadoria"
  - "Cadências de Curadoria"
  - "Curadoria da Base de Conhecimento"
  - "Ciclo de Curadoria KB"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/beta/ADR-I01_calendario_curadoria.beta.md"
source_beta_ids:
  - "BETA-I01"
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

# ADR-I01 — Calendário de Curadoria — Cadências Contínua, Semanal, Mensal, Trimestral e Semestral

| Campo       | Valor                                                         |
|-------------|---------------------------------------------------------------|
| **Status**  | Accepted                                                      |
| **Data**    | 23/03/2026                                                    |
| **Decisor** | fabio (arquitetura)                                           |
| **Escopo**  | Calendário de curadoria com cadências definidas, responsáveis por cada atividade e critérios de execução |

**Referências cruzadas:**

- [[ADR-008]]: Governança (cadência de curadoria, Pilar 4 critérios de fase)
- [[ADR-011]]: Segregação de KBs (auditoria de acesso por MCP)
- [[ADR-H03]]: Política de Backup (teste de restore)

---

## Contexto

A base de conhecimento é um sistema vivo: documentos são criados, editados, promovidos, consumidos e descontinuados. Sem curadoria explícita, documentos desatualizados ficam meses na base, o glossário diverge, e a qualidade do retrieval degrada.

## Decisão

Detalhar o calendário de curadoria da base de conhecimento, com cadências definidas (contínua, semanal, mensal, trimestral, semestral), responsáveis por cada atividade e critérios de execução. Extraído da seção "Cadência de Curadoria" e complementado pelos Pilares 2 e 4 do [[ADR-008]].

## Princípios

- A base de conhecimento é um sistema vivo: documentos são criados, editados, promovidos, consumidos e descontinuados.
- Sem curadoria explícita, documentos desatualizados ficam meses na base, o glossário diverge, e a qualidade do retrieval degrada.
- A curadoria é responsabilidade compartilhada entre papéis ([[ADR-008]] Pilar 1), não de uma única pessoa.
- As cadências se complementam: atividades contínuas tratam o dia a dia, cadências mais longas tratam tendências e melhorias estruturais.

## Cadência Contínua

**Responsável:** Owner de Documento

**Atividades:**
- Atualizar documentos quando processo, sistema ou regulação muda.
- Responder alertas de auto-depreciação (documentos sem atualização há 12 meses recebem alerta automático; Owner tem 30 dias para confirmar se o documento ainda é válido ou deve ser depreciado).
- Manter front matter atualizado (status, tags, owner, datas).
- Reportar inconsistências encontradas durante uso dos documentos.

**Gatilhos:**
- Mudança em sistema documentado (deploy, nova versão, nova feature)
- Mudança regulatória (nova resolução BACEN, atualização LGPD)
- Mudança de processo (novo fluxo operacional, nova política interna)
- Alerta automático de auto-depreciação (12 meses sem atualização)
- Feedback de usuários reportando informação desatualizada

**Critérios de qualidade:**
- Documento atualizado dentro de 5 dias úteis após mudança no sistema
- Alertas de auto-depreciação respondidos dentro de 30 dias
- Front matter consistente com conteúdo do documento

## Cadência Semanal

**Responsável:** Engenheiro de Pipeline

**Dia sugerido:** Segunda-feira (início da semana)
**Duração estimada:** 1-2 horas

**Atividades:**

### Health check do pipeline

- Verificar se pipeline executou com sucesso na semana anterior
- Revisar logs de erro e warnings
- Verificar taxa de falha de ingestão (threshold: < 5%)
- Confirmar que batch_id está sendo registrado corretamente

### Detectar chunks órfãos

- Chunks na Base Vetorial cujo documento de origem foi removido ou alterado significativamente no Git
- Executar query de consistência: chunks sem document_id válido
- Remover órfãos ou marcar para re-ingestão

### Verificar consistência repo <-> Base Vetorial

- Comparar lista de documentos no rag-knowledge-base com documentos indexados na Base Vetorial
- Identificar: documentos no Git sem chunks na Base Vetorial, chunks na Base Vetorial sem documento no Git
- Registrar divergências e agendar correção

### Verificar alertas de monitoramento

- Revisar dashboards de observabilidade
- Tratar alertas pendentes (latência, uso de recursos, falhas)

**Entregável semanal:**
- Checklist preenchido (health check OK / NOK com detalhes)
- Lista de órfãos detectados e ação tomada
- Lista de divergências repo <-> Base Vetorial

## Cadência Mensal

**Responsáveis:** Arquiteto + Curador de Conhecimento

**Período:** primeira semana do mês
**Duração estimada:** 4-6 horas

**Atividades:**

### Avaliação do Golden Set

- Executar golden set completo contra a Base Vetorial de produção
- Medir Recall@10 (threshold conforme fase do projeto — [[ADR-008]] Pilar 4: Fase 1 >= 70%, Fase 2 >= 80%, Fase 3 >= 85%)
- Comparar com resultado do mês anterior (tendência)
- Se Recall caiu: investigar causa (novos documentos sem cobertura, embeddings desatualizados, chunks mal formados)
- Adicionar novos pares pergunta/resposta ao golden set conforme novos domínios são cobertos

### Revisão do glossário

- Verificar se termos do glossário estão atualizados
- Identificar termos novos que surgiram em documentos recentes
- Verificar consistência: mesmo termo definido de formas diferentes em documentos diferentes
- Curador propõe adições/alterações; Owner de domínio valida

### Avaliar documentos deprecated > 3 meses

- Listar documentos com status DEPRECATED há mais de 3 meses
- Para cada documento: decidir se deve ser mantido (contexto histórico), reativado (DEPRECATED → DRAFT) ou arquivado
- Documentos deprecated que são única fonte sobre sistema legado devem ser mantidos com nota explicativa

### Revisar métricas de qualidade

- Taxa de documentos com front matter completo e válido
- Taxa de documentos APPROVED vs DRAFT vs IN-REVIEW
- Volume de chunks por domínio (distribuição equilibrada?)
- Tempo médio de permanência em cada estado do ciclo de vida

**Entregável mensal:**
- Relatório de Recall@10 com tendência
- Lista de ações no glossário
- Decisões sobre documentos deprecated
- Dashboard de métricas de qualidade atualizado

## Cadência Trimestral

**Responsáveis:** Arquiteto + Operações + Compliance Officer

**Período:** primeira quinzena do trimestre
**Duração estimada:** 1-2 dias

**Atividades:**

### Auditoria de acesso

- Revisar quem tem acesso a qual MCP ([[ADR-011]])
- Verificar se perfis estão corretos (Analyst, Manager, Director)
- Identificar acessos indevidos ou excessivos
- Revogar acessos desnecessários
- Compliance Officer valida e assina relatório

### Auditoria de classificação

- Amostragem de documentos por nível de confidencialidade
- Verificar se classificação (public, internal, restricted, confidential) está correta
- Identificar documentos potencialmente subclassificados (ex: documento com dados sensíveis marcado como public)
- Quality gate: scanner automático de keywords sensíveis

### Limpeza de deprecated > 6 meses

- Documentos deprecated há mais de 6 meses sem justificativa de manutenção devem ser candidatos a arquivamento
- Arquivamento: remover da Base Vetorial, manter no Git (histórico preservado)
- Decisão registrada com justificativa

### Capacity planning

- Verificar métricas contra thresholds ([[ADR-008]]):
  - RAM Base Vetorial > 80% → investigar consumo
  - Disco > 70% → planejar expansão para 6 meses
  - Latência p95 > 500ms → otimizar índices / avaliar cache
  - Total chunks > 500.000 → avaliar particionamento
  - Taxa falha ingestão > 5% → investigar pipeline/dados
  - Re-indexação completa > 4 horas → paralelizar workers
- Projetar crescimento para o próximo trimestre
- Recomendar ações preventivas

### Drill de rollback

- Executar simulação de rollback (cenário A ou B do [[ADR-008]])
- Medir tempo de execução
- Validar que procedimento documentado funciona
- Atualizar procedimento se necessário
- Registrar resultado do drill

### Teste de restore de backup

- Executar restore de backup em ambiente isolado
- Validar integridade (contagem de documentos/chunks)
- Medir tempo de restauração
- Registrar resultado ([[ADR-H03]])

**Entregável trimestral:**
- Relatório de auditoria de acesso (assinado por Compliance)
- Relatório de auditoria de classificação
- Lista de documentos arquivados
- Relatório de capacity planning com projeções
- Registro do drill de rollback
- Registro do teste de restore

## Cadência Semestral

**Responsáveis:** Todos os papéis (ARQ, CUR, ENG, DEV, OPS, OWN, CMP)

**Período:** Janeiro e Julho (ou conforme calendário corporativo)
**Duração estimada:** 2-3 dias

**Atividades:**

### Revisão abrangente da base de conhecimento

- Avaliar cobertura por domínio: quais domínios estão bem cobertos, quais têm lacunas
- Verificar qualidade geral: distribuição de scores QA, tendência de Recall ao longo dos 6 meses
- Identificar domínios prioritários para os próximos 6 meses

### Avaliação de transição de fase

- Verificar critérios mensuráveis do [[ADR-008]] Pilar 4:
  - Fase 1→2: pipeline funcional, golden set 20 pares, Recall >= 70%, front matter 100% válido
  - Fase 2→3: vocabulários controlados, golden set 50 pares, Recall >= 80%, filtros testados, restore OK
  - Fase 3→4: 5+ tipos entidade, fonte não-.md, golden set 100 pares, Recall >= 85%, RBAC, audit logging
- Se critérios atendidos: propor transição para próximo nível
- Aprovação: Arquiteto + PO (+ Compliance na Fase 3→4)

### Revisão de ADRs e tecnologias

- Todas as ADRs da série: ainda válidas? precisam de atualização?
- Modelos de embedding: avaliar se há modelos melhores disponíveis
- Base Vetorial: avaliar evolução do Neo4j e alternativas
- Pipeline: avaliar ferramentas e otimizações

### Roadmap para os próximos 6 meses

- Definir prioridades de conteúdo (domínios, tipos de documento)
- Definir melhorias técnicas (pipeline, retrieval, observabilidade)
- Alinhar com roadmap de produto e expectativas de stakeholders
- Documentar decisões e responsáveis

**Entregável semestral:**
- Relatório semestral da base de conhecimento
- Decisão de transição de fase (se aplicável)
- Plano de ação para ADRs e tecnologias
- Roadmap atualizado para os próximos 6 meses

## Calendário Consolidado

| Frequência | Quem | Duração | Entregável |
|---|---|---|---|
| Contínua | Owner | Variável | Docs atualizados |
| Semanal | Engenheiro | 1-2h | Checklist saúde |
| Mensal | Arquiteto + Curador | 4-6h | Relatório Recall |
| Trimestral | Arquiteto + Ops + Compliance | 1-2 dias | Auditoria + drills |
| Semestral | Todos os papéis | 2-3 dias | Revisão + roadmap |

## Referências

- [[ADR-008]]: Governança (cadência de curadoria, Pilar 4 critérios de fase)
- [[ADR-008]]: Pilar 1 (papéis e RACI)
- [[ADR-008]]: Pilar 2 (ciclo de vida, auto-depreciação 12 meses)
- [[ADR-008]]: Pilar 3 (rollback, drill trimestral)
- [[ADR-011]]: Segregação de KBs (auditoria de acesso por MCP)
- [[ADR-H03]]: Política de Backup (teste de restore)

<!-- conversion_quality: 95 -->
