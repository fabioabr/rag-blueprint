---
id: BETA-I01
title: "Calendario de Curadoria"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-I01_calendario_curadoria.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags:
  - calendario de curadoria
  - curadoria
  - cadencia continua
  - cadencia semanal
  - cadencia mensal
  - cadencia trimestral
  - cadencia semestral
  - health check
  - chunks orfaos
  - consistencia
  - golden set
  - recall
  - glossario
  - documentos deprecated
  - auto deprecacao
  - front matter
  - ciclo de vida
  - governanca
  - papeis e responsabilidades
  - owner de documento
  - engenheiro de pipeline
  - arquiteto
  - curador de conhecimento
  - compliance officer
  - operacoes
  - auditoria de acesso
  - auditoria de classificacao
  - capacity planning
  - drill de rollback
  - teste de restore
  - transicao de fase
  - roadmap
  - revisao de adrs
  - modelos de embedding
  - base vetorial
  - neo4j
  - mcp
  - pipeline de ingestao
  - qualidade
  - metricas
  - threshold
  - alerta
  - monitoramento
  - dominio
  - cobertura
  - distribuicao de chunks
  - rbac
  - audit logging
  - raci
  - entregavel
aliases:
  - "ADR-I01"
  - "Calendario de Curadoria"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## ADR-I01 -- Calendario de Curadoria

**Tipo:** ADR
**Origem:** ADR-008
**Data:** 23/03/2026

## 1. Objetivo

Detalhar o calendario de curadoria da base de conhecimento, com cadencias definidas (continua, semanal, mensal, trimestral, semestral), responsaveis por cada atividade e criterios de execucao. Extraido da secao "Cadencia de Curadoria" e complementado pelos Pilares 2 e 4 do ADR-008.

## 2. Principios

- A base de conhecimento e um sistema vivo: documentos sao criados, editados, promovidos, consumidos e descontinuados.
- Sem curadoria explicita, documentos desatualizados ficam meses na base, o glossario diverge, e a qualidade do retrieval degrada.
- A curadoria e responsabilidade compartilhada entre papeis (ADR-008 Pilar 1), nao de uma unica pessoa.
- As cadencias se complementam: atividades continuas tratam o dia a dia, cadencias mais longas tratam tendencias e melhorias estruturais.

## 3. Cadencia Continua

**Responsavel:** Owner de Documento

**Atividades:**
- Atualizar documentos quando processo, sistema ou regulacao muda.
- Responder alertas de auto-deprecacao (documentos sem atualizacao ha 12 meses recebem alerta automatico; Owner tem 30 dias para confirmar se o documento ainda e valido ou deve ser deprecado).
- Manter front matter atualizado (status, tags, owner, datas).
- Reportar inconsistencias encontradas durante uso dos documentos.

**Gatilhos:**
- Mudanca em sistema documentado (deploy, nova versao, nova feature)
- Mudanca regulatoria (nova resolucao BACEN, atualizacao LGPD)
- Mudanca de processo (novo fluxo operacional, nova politica interna)
- Alerta automatico de auto-deprecacao (12 meses sem atualizacao)
- Feedback de usuarios reportando informacao desatualizada

**Criterios de qualidade:**
- Documento atualizado dentro de 5 dias uteis apos mudanca no sistema
- Alertas de auto-deprecacao respondidos dentro de 30 dias
- Front matter consistente com conteudo do documento

## 4. Cadencia Semanal

**Responsavel:** Engenheiro de Pipeline

**Dia sugerido:** Segunda-feira (inicio da semana)
**Duracao estimada:** 1-2 horas

**Atividades:**

### 4.1 Health check do pipeline

- Verificar se pipeline executou com sucesso na semana anterior
- Revisar logs de erro e warnings
- Verificar taxa de falha de ingestao (threshold: < 5%)
- Confirmar que batch_id esta sendo registrado corretamente

### 4.2 Detectar chunks orfaos

- Chunks na Base Vetorial cujo documento de origem foi removido ou alterado significativamente no Git
- Executar query de consistencia: chunks sem document_id valido
- Remover orfaos ou marcar para re-ingestao

### 4.3 Verificar consistencia repo <-> Base Vetorial

- Comparar lista de documentos no rag-knowledge-base com documentos indexados na Base Vetorial
- Identificar: documentos no Git sem chunks na Base Vetorial, chunks na Base Vetorial sem documento no Git
- Registrar divergencias e agendar correcao

### 4.4 Verificar alertas de monitoramento

- Revisar dashboards de observabilidade
- Tratar alertas pendentes (latencia, uso de recursos, falhas)

**Entregavel semanal:**
- Checklist preenchido (health check OK / NOK com detalhes)
- Lista de orfaos detectados e acao tomada
- Lista de divergencias repo <-> Base Vetorial

## 5. Cadencia Mensal

**Responsaveis:** Arquiteto + Curador de Conhecimento

**Periodo:** primeira semana do mes
**Duracao estimada:** 4-6 horas

**Atividades:**

### 5.1 Avaliacao do Golden Set

- Executar golden set completo contra a Base Vetorial de producao
- Medir Recall@10 (threshold conforme fase do projeto -- ADR-008 Pilar 4: Fase 1 >= 70%, Fase 2 >= 80%, Fase 3 >= 85%)
- Comparar com resultado do mes anterior (tendencia)
- Se Recall caiu: investigar causa (novos documentos sem cobertura, embeddings desatualizados, chunks mal formados)
- Adicionar novos pares pergunta/resposta ao golden set conforme novos dominios sao cobertos

### 5.2 Revisao do glossario

- Verificar se termos do glossario estao atualizados
- Identificar termos novos que surgiram em documentos recentes
- Verificar consistencia: mesmo termo definido de formas diferentes em documentos diferentes
- Curador propoe adicoes/alteracoes; Owner de dominio valida

### 5.3 Avaliar documentos deprecated > 3 meses

- Listar documentos com status DEPRECATED ha mais de 3 meses
- Para cada documento: decidir se deve ser mantido (contexto historico), reativado (DEPRECATED -> DRAFT) ou arquivado
- Documentos deprecated que sao unica fonte sobre sistema legado devem ser mantidos com nota explicativa

### 5.4 Revisar metricas de qualidade

- Taxa de documentos com front matter completo e valido
- Taxa de documentos APPROVED vs DRAFT vs IN-REVIEW
- Volume de chunks por dominio (distribuicao equilibrada?)
- Tempo medio de permanencia em cada estado do ciclo de vida

**Entregavel mensal:**
- Relatorio de Recall@10 com tendencia
- Lista de acoes no glossario
- Decisoes sobre documentos deprecated
- Dashboard de metricas de qualidade atualizado

## 6. Cadencia Trimestral

**Responsaveis:** Arquiteto + Operacoes + Compliance Officer

**Periodo:** primeira quinzena do trimestre
**Duracao estimada:** 1-2 dias

**Atividades:**

### 6.1 Auditoria de acesso

- Revisar quem tem acesso a qual MCP (ADR-011)
- Verificar se perfis estao corretos (Analyst, Manager, Director)
- Identificar acessos indevidos ou excessivos
- Revogar acessos desnecessarios
- Compliance Officer valida e assina relatorio

### 6.2 Auditoria de classificacao

- Amostragem de documentos por nivel de confidencialidade
- Verificar se classificacao (public, internal, restricted, confidential) esta correta
- Identificar documentos potencialmente subclassificados (ex: documento com dados sensiveis marcado como public)
- Quality gate: scanner automatico de keywords sensiveis

### 6.3 Limpeza de deprecated > 6 meses

- Documentos deprecated ha mais de 6 meses sem justificativa de manutencao devem ser candidatos a arquivamento
- Arquivamento: remover da Base Vetorial, manter no Git (historico preservado)
- Decisao registrada com justificativa

### 6.4 Capacity planning

- Verificar metricas contra thresholds (ADR-008):
  - RAM Base Vetorial > 80% -> investigar consumo
  - Disco > 70% -> planejar expansao para 6 meses
  - Latencia p95 > 500ms -> otimizar indices / avaliar cache
  - Total chunks > 500.000 -> avaliar particionamento
  - Taxa falha ingestao > 5% -> investigar pipeline/dados
  - Re-indexacao completa > 4 horas -> paralelizar workers
- Projetar crescimento para o proximo trimestre
- Recomendar acoes preventivas

### 6.5 Drill de rollback

- Executar simulacao de rollback (cenario A ou B do ADR-008)
- Medir tempo de execucao
- Validar que procedimento documentado funciona
- Atualizar procedimento se necessario
- Registrar resultado do drill

### 6.6 Teste de restore de backup

- Executar restore de backup em ambiente isolado
- Validar integridade (contagem de documentos/chunks)
- Medir tempo de restauracao
- Registrar resultado (ADR-H03)

**Entregavel trimestral:**
- Relatorio de auditoria de acesso (assinado por Compliance)
- Relatorio de auditoria de classificacao
- Lista de documentos arquivados
- Relatorio de capacity planning com projecoes
- Registro do drill de rollback
- Registro do teste de restore

## 7. Cadencia Semestral

**Responsaveis:** Todos os papeis (ARQ, CUR, ENG, DEV, OPS, OWN, CMP)

**Periodo:** Janeiro e Julho (ou conforme calendario corporativo)
**Duracao estimada:** 2-3 dias

**Atividades:**

### 7.1 Revisao abrangente da base de conhecimento

- Avaliar cobertura por dominio: quais dominios estao bem cobertos, quais tem lacunas
- Verificar qualidade geral: distribuicao de scores QA, tendencia de Recall ao longo dos 6 meses
- Identificar dominios prioritarios para os proximos 6 meses

### 7.2 Avaliacao de transicao de fase

- Verificar criterios mensuraveis do ADR-008 Pilar 4:
  - Fase 1->2: pipeline funcional, golden set 20 pares, Recall >= 70%, front matter 100% valido
  - Fase 2->3: vocabularios controlados, golden set 50 pares, Recall >= 80%, filtros testados, restore OK
  - Fase 3->4: 5+ tipos entidade, fonte nao-.md, golden set 100 pares, Recall >= 85%, RBAC, audit logging
- Se criterios atendidos: propor transicao para proximo nivel
- Aprovacao: Arquiteto + PO (+ Compliance na Fase 3->4)

### 7.3 Revisao de ADRs e tecnologias

- Todas as ADRs da serie: ainda validas? precisam de atualizacao?
- Modelos de embedding: avaliar se ha modelos melhores disponiveis
- Base Vetorial: avaliar evolucao do Neo4j e alternativas
- Pipeline: avaliar ferramentas e otimizacoes

### 7.4 Roadmap para os proximos 6 meses

- Definir prioridades de conteudo (dominios, tipos de documento)
- Definir melhorias tecnicas (pipeline, retrieval, observabilidade)
- Alinhar com roadmap de produto e expectativas de stakeholders
- Documentar decisoes e responsaveis

**Entregavel semestral:**
- Relatorio semestral da base de conhecimento
- Decisao de transicao de fase (se aplicavel)
- Plano de acao para ADRs e tecnologias
- Roadmap atualizado para os proximos 6 meses

## 8. Calendario Consolidado

| Frequencia | Quem | Duracao | Entregavel |
|---|---|---|---|
| Continua | Owner | Variavel | Docs atualizados |
| Semanal | Engenheiro | 1-2h | Checklist saude |
| Mensal | Arquiteto + Curador | 4-6h | Relatorio Recall |
| Trimestral | Arquiteto + Ops + Compliance | 1-2 dias | Auditoria + drills |
| Semestral | Todos os papeis | 2-3 dias | Revisao + roadmap |

## 9. Referencias

- ADR-008: Governanca (cadencia de curadoria, Pilar 4 criterios de fase)
- ADR-008: Pilar 1 (papeis e RACI)
- ADR-008: Pilar 2 (ciclo de vida, auto-deprecacao 12 meses)
- ADR-008: Pilar 3 (rollback, drill trimestral)
- ADR-011: Segregacao de KBs (auditoria de acesso por MCP)
- ADR-H03: Politica de Backup (teste de restore)

<!-- conversion_quality: 95 -->
