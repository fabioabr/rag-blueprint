---
id: BETA-I02
title: "Capacity Planning da Base de Conhecimento"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-I02_capacity_planning_kb.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags:
  - capacity planning
  - dimensionamento
  - threshold de acao
  - gatilhos
  - ram
  - disco
  - latencia
  - chunks
  - documentos
  - storage
  - embedding
  - hnsw
  - vector index
  - neo4j
  - base vetorial
  - monitoramento
  - metricas
  - dashboard
  - projecao de crescimento
  - fases de rollout
  - mvp
  - scale up
  - scale out
  - particionamento
  - sharding
  - otimizacao de indices
  - paralelizacao
  - pipeline de ingestao
  - re indexacao
  - batch size
  - workers
  - taxa de falha
  - tempo de rollback
  - tamanho de backup
  - heuristica
  - estimativa de storage
  - estimativa de ram
  - estimativa de tempo
  - multi kb
  - segregacao por confidencialidade
  - escalonamento
  - procedimento
  - nivel de escalonamento
  - engenheiro de pipeline
  - arquiteto
  - operacoes
  - trimestral
  - tendencia
  - cache
  - recall
  - golden set
  - p95
  - p99
aliases:
  - "ADR-I02"
  - "Capacity Planning KB"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## ADR-I02 -- Capacity Planning da Base de Conhecimento

**Tipo:** ADR
**Origem:** ADR-008
**Data:** 23/03/2026

## 1. Objetivo

Documentar os thresholds de acao, heuristicas de crescimento, metricas de monitoramento e procedimentos de escalonamento para o capacity planning da base de conhecimento. Extraido da secao "Capacity Planning" do ADR-008 e complementado pelas projecoes de crescimento por fase.

## 2. Gatilhos de Acao

Os thresholds a seguir determinam quando uma acao preventiva ou corretiva deve ser iniciada. Monitoramento continuo e obrigatorio.

| Metrica | Threshold | Acao |
|---|---|---|
| Uso de RAM (Base Vetorial) | > 80% | Investigar consumo. Avaliar: queries pesadas, indices nao otimizados, cache excessivo. Se persistente: planejar scale-up de memoria. |
| Uso de disco | > 70% | Planejar expansao para os proximos 6 meses. Calcular taxa de crescimento mensal e projetar quando atinge 90%. Provisionar antes. |
| Latencia p95 de busca | > 500ms | Otimizar indices da Base Vetorial. Avaliar cache de queries frequentes. Verificar se volume de chunks ultrapassou limiar. Considerar particionamento. |
| Total de chunks | > 500.000 | Avaliar particionamento da Base Vetorial. Considerar segregacao por dominio ou por KB. Medir impacto na latencia. |
| Taxa de falha de ingestao | > 5% | Investigar pipeline e dados de entrada. Causas comuns: front matter invalido, fonte corrompida, timeout de embedding API. |
| Tempo de re-indexacao completa | > 4 horas | Paralelizar workers do pipeline. Avaliar batch size. Considerar re-indexacao incremental. |
| Tempo de rollback | > 1 hora | Otimizar script de rebuild. Avaliar backup mais recente. Considerar blue-green deployment. |
| Tamanho de backup | Crescimento > 50% em 1 mes | Investigar: novos documentos ou duplicacao? Ajustar retencao se necessario. |

## 3. Projecao de Crescimento por Fase

As estimativas a seguir sao baseadas no pipeline de 4 fases (ADR-001) e nas metricas de chunking (media de 10 chunks por documento, faixa de 300-800 tokens por chunk).

| Fase | Documentos | Chunks | Storage Estimado | RAM Recomendada |
|---|---|---|---|---|
| Fase 1 | 20-100 | 200-1.000 | 2-10 MB | 2-4 GB |
| Fase 2 | 100-500 | 1K-5K | 10-50 MB | 4-8 GB |
| Fase 3 | 500-2.000 | 5K-20K | 50-200 MB | 8-16 GB |
| Fase 4 | 2.000-10K | 20K-100K | 200 MB - 1 GB | 16-32 GB |
| Escala | 10K-50K | 100K-500K | 1-5 GB | 32-64 GB |

Notas:
- Storage inclui dados, indices, embeddings e metadados.
- Embeddings representam ~70% do storage (vetores de 768-1536 dimensoes).
- RAM recomendada considera Base Vetorial + indices + cache.
- Para multi-KB (ADR-011), multiplicar por numero de KBs ativas, porem KB restricted e confidential tendem a ter volume muito menor que KB public-internal.

## 4. Heuristicas de Dimensionamento

### 4.1 Estimativa de Storage por Documento

| Componente | Tamanho Medio |
|---|---|
| Documento .md (texto) | 5-20 KB |
| Chunks (10 por doc, media) | 500 bytes - 2 KB cada |
| Embedding por chunk | 3-6 KB (768-1536 dim * float32) |
| Metadados (front matter) | 500 bytes - 1 KB |
| Indices | ~20% do total de dados |

Estimativa: ~50-100 KB por documento indexado (incluindo embeddings e indices).

### 4.2 Estimativa de RAM

Regra pratica para Neo4j com vector index:
- Base: 2 GB (overhead do sistema)
- Por 10.000 chunks: +1 GB (dados + indices)
- Por 10.000 vetores (embedding): +500 MB (HNSW index in-memory)
- Cache de queries: +1-2 GB (configuravel)

### 4.3 Estimativa de Tempo de Ingestao

| Volume de Documentos | Tempo Estimado de Ingestao |
|---|---|
| 50 documentos | ~5 minutos |
| 200 documentos | ~15 minutos |
| 1.000 documentos | ~30-45 minutos |
| 10.000+ documentos | ~4-8 horas |

Fatores que influenciam: modelo de embedding (local vs API), complexidade do chunking, velocidade de persistencia na Base Vetorial, numero de workers paralelos.

## 5. Monitoramento -- Metricas de Capacity

As metricas a seguir devem ser coletadas e visualizadas em dashboard:

| Metrica | Fonte | Frequencia |
|---|---|---|
| RAM utilizada (%) | Neo4j / SO | Tempo real |
| Disco utilizado (%) | Neo4j / SO | Tempo real |
| Latencia de busca (p50/p95/p99) | MCP Server | Tempo real |
| Total de chunks | Neo4j | Diaria |
| Total de documentos | Neo4j | Diaria |
| Taxa de falha de ingestao (%) | Pipeline | Por execucao |
| Tempo de ingestao (por batch) | Pipeline | Por execucao |
| Tempo de re-indexacao completa | Pipeline | Por execucao |
| Tamanho do backup | Backup service | Diaria |
| Recall@10 (golden set) | QA | Mensal |

Dashboard deve incluir:
- Visao por KB (separada) e visao consolidada
- Tendencia dos ultimos 30/90/180 dias
- Indicadores visuais de threshold (verde/amarelo/vermelho)
- Projecao de quando threshold sera atingido (baseado em tendencia)

## 6. Procedimento de Escalonamento

Quando um threshold e atingido, o seguinte fluxo se aplica:

**Nivel 1 -- Investigacao (Engenheiro de Pipeline)**
- Identificar causa raiz do threshold atingido
- Verificar se e pico temporario ou tendencia
- Documentar findings

**Nivel 2 -- Plano de acao (Arquiteto + Operacoes)**
- Definir acao corretiva (otimizacao, scale-up, particionamento)
- Estimar custo e prazo
- Priorizar em relacao a outras demandas

**Nivel 3 -- Execucao (Operacoes)**
- Implementar acao aprovada
- Validar que threshold voltou a nivel aceitavel
- Atualizar projecoes de crescimento

**Nivel 4 -- Revisao (trimestral, no calendario de curadoria)**
- Revisar todos os thresholds atingidos no trimestre
- Ajustar thresholds se necessario (ex: se a base cresceu, 500ms pode nao ser mais realista para p95)
- Atualizar projecoes de crescimento para o proximo trimestre

## 7. Cenarios de Escalonamento

### 7.1 Scale-Up Vertical

- **Quando:** RAM ou disco proximo do limite em unica instancia
- **Acao:** aumentar recursos do servidor/container
- **Aplicavel:** Fases 1-3, volumes menores

### 7.2 Scale-Out Horizontal (por KB)

- **Quando:** volume justifica particionamento ou sharding
- **Acao:** distribuir chunks entre multiplas instancias por dominio
- **Aplicavel:** Fase 4+, volumes maiores
- **Nota:** o modelo multi-KB do ADR-011 ja e uma forma de scale-out natural por nivel de confidencialidade

### 7.3 Otimizacao de Indices

- **Quando:** latencia p95 > 500ms sem aumento proporcional de volume
- **Acao:** revisar configuracao do vector index (HNSW parameters), adicionar indices auxiliares, avaliar cache
- **Aplicavel:** qualquer fase

### 7.4 Paralelizacao de Pipeline

- **Quando:** tempo de re-indexacao > 4 horas
- **Acao:** aumentar numero de workers, otimizar batch size, considerar ingestao incremental
- **Aplicavel:** Fase 3+

## 8. Referencias

- ADR-008: Governanca (Capacity Planning, gatilhos de acao, projecao)
- ADR-008: Pilar 3 (estimativa de tempo de recuperacao)
- ADR-008: Pilar 4 (criterios de transicao por fase)
- ADR-006: Pipeline de Ingestao (7 etapas, idempotencia)
- ADR-011: Segregacao de KBs (multi-instancia, escalonamento por KB)
- ADR-I01: Calendario de Curadoria (cadencia trimestral de capacity)

<!-- conversion_quality: 95 -->
