---
id: ADR-I02
doc_type: adr
title: "Capacity Planning da Base de Conhecimento — Thresholds, Projeções e Escalonamento"
system: RAG Corporativo
module: Capacity Planning KB
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - capacity planning
  - dimensionamento
  - threshold de ação
  - gatilhos
  - ram
  - disco
  - latência
  - chunks
  - documentos
  - storage
  - embedding
  - hnsw
  - vector index
  - neo4j
  - base vetorial
  - monitoramento
  - métricas
  - dashboard
  - projeção de crescimento
  - fases de rollout
  - mvp
  - scale up
  - scale out
  - particionamento
  - sharding
  - otimização de índices
  - paralelização
  - pipeline de ingestão
  - re indexação
  - batch size
  - workers
  - taxa de falha
  - tempo de rollback
  - tamanho de backup
  - heurística
  - estimativa de storage
  - estimativa de ram
  - estimativa de tempo
  - multi kb
  - segregação por confidencialidade
  - escalonamento
  - procedimento
  - nível de escalonamento
  - engenheiro de pipeline
  - arquiteto
  - operações
  - trimestral
  - tendência
  - cache
  - recall
  - golden set
  - p95
  - p99
  - indicadores visuais
  - crescimento mensal
aliases:
  - "ADR-I02"
  - "Capacity Planning KB"
  - "Capacity Planning da Base de Conhecimento"
  - "Dimensionamento KB"
  - "Planejamento de Capacidade"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/beta/ADR-I02_capacity_planning_kb.beta.md"
source_beta_ids:
  - "BETA-I02"
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

# ADR-I02 — Capacity Planning da Base de Conhecimento — Thresholds, Projeções e Escalonamento

| Campo       | Valor                                                         |
|-------------|---------------------------------------------------------------|
| **Status**  | Accepted                                                      |
| **Data**    | 23/03/2026                                                    |
| **Decisor** | fabio (arquitetura)                                           |
| **Escopo**  | Thresholds de ação, heurísticas de crescimento, métricas de monitoramento e procedimentos de escalonamento para o capacity planning da base de conhecimento |

**Referências cruzadas:**

- [[ADR-008]]: Governança (Capacity Planning, gatilhos de ação, projeção)
- [[ADR-006]]: Pipeline de Ingestão (7 etapas, idempotência)
- [[ADR-011]]: Segregação de KBs (multi-instância, escalonamento por KB)
- [[ADR-I01]]: Calendário de Curadoria (cadência trimestral de capacity)

---

## Contexto

À medida que a base de conhecimento cresce, é necessário monitorar e planejar a capacidade da infraestrutura para garantir desempenho aceitável e evitar degradação do serviço.

## Decisão

Documentar os thresholds de ação, heurísticas de crescimento, métricas de monitoramento e procedimentos de escalonamento para o capacity planning da base de conhecimento. Extraído da seção "Capacity Planning" do [[ADR-008]] e complementado pelas projeções de crescimento por fase.

## Gatilhos de Ação

Os thresholds a seguir determinam quando uma ação preventiva ou corretiva deve ser iniciada. Monitoramento contínuo é obrigatório.

| Métrica | Threshold | Ação |
|---|---|---|
| Uso de RAM (Base Vetorial) | > 80% | Investigar consumo. Avaliar: queries pesadas, índices não otimizados, cache excessivo. Se persistente: planejar scale-up de memória. |
| Uso de disco | > 70% | Planejar expansão para os próximos 6 meses. Calcular taxa de crescimento mensal e projetar quando atinge 90%. Provisionar antes. |
| Latência p95 de busca | > 500ms | Otimizar índices da Base Vetorial. Avaliar cache de queries frequentes. Verificar se volume de chunks ultrapassou limiar. Considerar particionamento. |
| Total de chunks | > 500.000 | Avaliar particionamento da Base Vetorial. Considerar segregação por domínio ou por KB. Medir impacto na latência. |
| Taxa de falha de ingestão | > 5% | Investigar pipeline e dados de entrada. Causas comuns: front matter inválido, fonte corrompida, timeout de embedding API. |
| Tempo de re-indexação completa | > 4 horas | Paralelizar workers do pipeline. Avaliar batch size. Considerar re-indexação incremental. |
| Tempo de rollback | > 1 hora | Otimizar script de rebuild. Avaliar backup mais recente. Considerar blue-green deployment. |
| Tamanho de backup | Crescimento > 50% em 1 mês | Investigar: novos documentos ou duplicação? Ajustar retenção se necessário. |

## Projeção de Crescimento por Fase

As estimativas a seguir são baseadas no pipeline de 4 fases ([[ADR-001]]) e nas métricas de chunking (média de 10 chunks por documento, faixa de 300-800 tokens por chunk).

| Fase | Documentos | Chunks | Storage Estimado | RAM Recomendada |
|---|---|---|---|---|
| Fase 1 | 20-100 | 200-1.000 | 2-10 MB | 2-4 GB |
| Fase 2 | 100-500 | 1K-5K | 10-50 MB | 4-8 GB |
| Fase 3 | 500-2.000 | 5K-20K | 50-200 MB | 8-16 GB |
| Fase 4 | 2.000-10K | 20K-100K | 200 MB - 1 GB | 16-32 GB |
| Escala | 10K-50K | 100K-500K | 1-5 GB | 32-64 GB |

Notas:
- Storage inclui dados, índices, embeddings e metadados.
- Embeddings representam ~70% do storage (vetores de 768-1536 dimensões).
- RAM recomendada considera Base Vetorial + índices + cache.
- Para multi-KB ([[ADR-011]]), multiplicar por número de KBs ativas, porém KB restricted e confidential tendem a ter volume muito menor que KB public-internal.

## Heurísticas de Dimensionamento

### Estimativa de Storage por Documento

| Componente | Tamanho Médio |
|---|---|
| Documento .md (texto) | 5-20 KB |
| Chunks (10 por doc, média) | 500 bytes - 2 KB cada |
| Embedding por chunk | 3-6 KB (768-1536 dim * float32) |
| Metadados (front matter) | 500 bytes - 1 KB |
| Índices | ~20% do total de dados |

Estimativa: ~50-100 KB por documento indexado (incluindo embeddings e índices).

### Estimativa de RAM

Regra prática para Neo4j com vector index:
- Base: 2 GB (overhead do sistema)
- Por 10.000 chunks: +1 GB (dados + índices)
- Por 10.000 vetores (embedding): +500 MB (HNSW index in-memory)
- Cache de queries: +1-2 GB (configurável)

### Estimativa de Tempo de Ingestão

| Volume de Documentos | Tempo Estimado de Ingestão |
|---|---|
| 50 documentos | ~5 minutos |
| 200 documentos | ~15 minutos |
| 1.000 documentos | ~30-45 minutos |
| 10.000+ documentos | ~4-8 horas |

Fatores que influenciam: modelo de embedding (local vs API), complexidade do chunking, velocidade de persistência na Base Vetorial, número de workers paralelos.

## Monitoramento — Métricas de Capacity

As métricas a seguir devem ser coletadas e visualizadas em dashboard:

| Métrica | Fonte | Frequência |
|---|---|---|
| RAM utilizada (%) | Neo4j / SO | Tempo real |
| Disco utilizado (%) | Neo4j / SO | Tempo real |
| Latência de busca (p50/p95/p99) | MCP Server | Tempo real |
| Total de chunks | Neo4j | Diária |
| Total de documentos | Neo4j | Diária |
| Taxa de falha de ingestão (%) | Pipeline | Por execução |
| Tempo de ingestão (por batch) | Pipeline | Por execução |
| Tempo de re-indexação completa | Pipeline | Por execução |
| Tamanho do backup | Backup service | Diária |
| Recall@10 (golden set) | QA | Mensal |

Dashboard deve incluir:
- Visão por KB (separada) e visão consolidada
- Tendência dos últimos 30/90/180 dias
- Indicadores visuais de threshold (verde/amarelo/vermelho)
- Projeção de quando threshold será atingido (baseado em tendência)

## Procedimento de Escalonamento

Quando um threshold é atingido, o seguinte fluxo se aplica:

**Nível 1 — Investigação (Engenheiro de Pipeline)**
- Identificar causa raiz do threshold atingido
- Verificar se é pico temporário ou tendência
- Documentar findings

**Nível 2 — Plano de ação (Arquiteto + Operações)**
- Definir ação corretiva (otimização, scale-up, particionamento)
- Estimar custo e prazo
- Priorizar em relação a outras demandas

**Nível 3 — Execução (Operações)**
- Implementar ação aprovada
- Validar que threshold voltou a nível aceitável
- Atualizar projeções de crescimento

**Nível 4 — Revisão (trimestral, no calendário de curadoria)**
- Revisar todos os thresholds atingidos no trimestre
- Ajustar thresholds se necessário (ex: se a base cresceu, 500ms pode não ser mais realista para p95)
- Atualizar projeções de crescimento para o próximo trimestre

## Cenários de Escalonamento

### Scale-Up Vertical

- **Quando:** RAM ou disco próximo do limite em única instância
- **Ação:** aumentar recursos do servidor/container
- **Aplicável:** Fases 1-3, volumes menores

### Scale-Out Horizontal (por KB)

- **Quando:** volume justifica particionamento ou sharding
- **Ação:** distribuir chunks entre múltiplas instâncias por domínio
- **Aplicável:** Fase 4+, volumes maiores
- **Nota:** o modelo multi-KB do [[ADR-011]] já é uma forma de scale-out natural por nível de confidencialidade

### Otimização de Índices

- **Quando:** latência p95 > 500ms sem aumento proporcional de volume
- **Ação:** revisar configuração do vector index (HNSW parameters), adicionar índices auxiliares, avaliar cache
- **Aplicável:** qualquer fase

### Paralelização de Pipeline

- **Quando:** tempo de re-indexação > 4 horas
- **Ação:** aumentar número de workers, otimizar batch size, considerar ingestão incremental
- **Aplicável:** Fase 3+

## Referências

- [[ADR-008]]: Governança (Capacity Planning, gatilhos de ação, projeção)
- [[ADR-008]]: Pilar 3 (estimativa de tempo de recuperação)
- [[ADR-008]]: Pilar 4 (critérios de transição por fase)
- [[ADR-006]]: Pipeline de Ingestão (7 etapas, idempotência)
- [[ADR-011]]: Segregação de KBs (multi-instância, escalonamento por KB)
- [[ADR-I01]]: Calendário de Curadoria (cadência trimestral de capacity)

<!-- conversion_quality: 95 -->
