---
id: BETA-F03
title: "Capacity Planning Vetorial (Armazenamento e Recursos)"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-F03_capacity_planning_vetorial.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags:
  - capacity planning
  - indice vetorial
  - dimensionamento
  - armazenamento
  - recursos computacionais
  - bge-m3
  - embedding 1024 dimensoes
  - float32
  - neo4j
  - hnsw
  - vector index
  - ram
  - disco ssd
  - projecao de crescimento
  - infraestrutura
  - chunks
  - overhead de indice
  - metadados
  - memoria
  - re-embedding
  - custo de reprocessamento
  - throughput
  - gpu gtx 1070
  - cpu fallback
  - swap atomico
  - rollback de indice
  - thresholds de escala
  - vram
  - latencia de busca
  - cenarios de crescimento
  - fases de rollout
  - trilha b
  - trilha a
  - openai
  - soberania de dados
  - similaridade coseno
  - ef construction
  - ef search
  - parametro m
  - grafo de proximidade
  - fragmentacao de memoria
  - batch size
  - janela de manutencao
  - golden set
  - metricas de qualidade
  - replica de indice
  - backup
  - observabilidade
  - logs
  - thermal throttling
  - smart disco
  - storage distribuido
  - rag corporativo
  - planejamento de capacidade
aliases:
  - "ADR-F03"
  - "Capacity Planning Vetorial"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## ADR-F03 -- Capacity Planning Vetorial (Armazenamento e Recursos)

| Campo   | Valor     |
|---------|-----------|
| Tipo    | ADR       |
| Origem  | ADR-009   |
| Data    | 23/03/2026 |

## Objetivo

Documentar os calculos de dimensionamento de armazenamento e recursos
computacionais para o indice vetorial do RAG Corporativo, considerando o
modelo BGE-M3 (1024 dimensoes) e projecoes de crescimento. Este documento
subsidia decisoes de infraestrutura e planejamento de capacidade.

## 1. Formula Base de Calculo

Tamanho do indice vetorial puro:

```
tamanho_bytes = num_chunks x dimensao x bytes_por_float
```

Para BGE-M3 com float32:

```
tamanho_bytes = num_chunks x 1024 x 4
```

Cada vetor de 1024 dimensoes em float32 ocupa exatamente 4.096 bytes (4 KB).

## 2. Projecao de Tamanho do Indice

### 2.1 Indice Puro (somente vetores, float32, 1024d)

| Num. chunks | Indice puro | Com overhead (30%) | Com 2 replicas |
|-------------|-------------|--------------------|----------------|
| 1.000       | 4 MB        | 5.2 MB             | 15.6 MB        |
| 10.000      | 40 MB       | 52 MB              | 156 MB         |
| 50.000      | 200 MB      | 260 MB             | 780 MB         |
| 100.000     | 400 MB      | 520 MB             | 1.56 GB        |

O overhead de 30% inclui:
- Estrutura do indice HNSW (grafos de proximidade)
- Metadados internos (IDs, ponteiros)
- Fragmentacao de memoria

### 2.2 Armazenamento Total (vetores + texto + metadados)

Alem do indice vetorial, cada chunk armazena:
- Texto do chunk (media ~500 bytes por chunk)
- Metadados (embedding_model, versao, timestamp, chunk_id, doc_id, etc.)
- Estimativa de metadados: ~200 bytes por chunk

| Num. chunks | Vetores  | Texto   | Metadados | Total estimado |
|-------------|----------|---------|-----------|----------------|
| 1.000       | 4 MB     | 0.5 MB  | 0.2 MB    | ~6 MB          |
| 10.000      | 40 MB    | 5 MB    | 2 MB      | ~61 MB         |
| 50.000      | 200 MB   | 25 MB   | 10 MB     | ~305 MB        |
| 100.000     | 400 MB   | 50 MB   | 20 MB     | ~610 MB        |

## 3. Requisitos de RAM

### 3.1 Indice Vetorial em Memoria

Para busca eficiente, o indice HNSW deve residir em RAM.

Regra pratica: RAM necessaria para indice = 2x tamanho em disco
(inclui estruturas auxiliares de busca e cache)

| Num. chunks | RAM para indice | RAM total sistema (OS + app + indice) |
|-------------|-----------------|---------------------------------------|
| 10.000      | ~104 MB         | ~4 GB                                 |
| 50.000      | ~520 MB         | ~5 GB                                 |
| 100.000     | ~1.04 GB        | ~6 GB                                 |
| 500.000     | ~5.2 GB         | ~12 GB                                |

### 3.2 Ambiente-Alvo (64 GB RAM)

Com 64 GB RAM disponivel:
- OS e servicos base: ~8 GB
- Neo4j heap + cache: ~16 GB (configuravel)
- Modelo BGE-M3 em CPU (fallback): ~4 GB
- Disponivel para indices: ~36 GB
- Capacidade maxima estimada: ~3.5 milhoes de chunks

**CONCLUSAO:** 64 GB de RAM suportam com folga o cenario de 50.000 a
100.000 chunks previsto para as primeiras fases. Escala confortavel
ate ~500.000 chunks sem necessidade de upgrade.

## 4. Requisitos de Disco (SSD)

### 4.1 Armazenamento de Dados

| Componente                          | Tamanho                      |
|-------------------------------------|------------------------------|
| Modelos de embedding (3 modelos)    | ~5.4 GB                      |
| Indice vetorial (50K chunks)        | ~305 MB                      |
| Indice vetorial (100K chunks)       | ~610 MB                      |
| Banco Neo4j (grafo + propriedades)  | ~2-5 GB (50K-100K docs)      |
| Logs e observabilidade              | ~1-5 GB (retencao 90 dias)   |
| Backups (ultimo + anterior)         | ~2x indice                   |
| **TOTAL estimado (100K chunks)**    | **~15-20 GB**                |

### 4.2 Ambiente-Alvo (500 GB SSD)

Capacidade amplamente suficiente para cenarios previstos.
Recomendacao: reservar 50 GB para o RAG; restante livre para OS e outros.

## 5. Comparacao Trilha B vs Trilha A

| Aspecto                | Trilha B (BGE-M3) | Trilha A (OpenAI)      |
|------------------------|--------------------|------------------------|
| Dimensao               | 1024               | 1536                   |
| Bytes por vetor        | 4.096              | 6.144                  |
| Indice (50K chunks)    | 200 MB             | 300 MB                 |
| Indice (100K chunks)   | 400 MB             | 600 MB                 |
| Qualidade (MTEB avg)   | ~65-68 nDCG@10     | ~68-70 nDCG@10         |
| Custo por embedding    | Zero (local)       | US$ 0.02 / 1M tokens   |
| Soberania              | Total              | Nenhuma                |

**IMPORTANTE:** vetores das duas trilhas sao INCOMPATIVEIS.
Indices obrigatoriamente separados por trilha, conforme ADR-002.
Chunks processados por um modelo NAO podem ser misturados com
chunks de outro modelo no mesmo indice.

## 6. Parametros do Indice HNSW

Configuracao recomendada para Neo4j Vector Index:

| Parametro       | Valor  | Descricao                                         |
|-----------------|--------|----------------------------------------------------|
| dimensao        | 1024   | Dimensao do vetor BGE-M3                           |
| metrica         | cosine | Similaridade coseno (requer normalizacao)          |
| M               | 16     | Conexoes por no no grafo HNSW                      |
| ef_construction | 200    | Qualidade da construcao do indice                  |
| ef_search       | 100    | Qualidade da busca (trade-off com latencia)        |

Notas:
- M=16 e bom equilibrio entre qualidade e uso de memoria
- ef_construction=200 gera indice de alta qualidade (custo de tempo na construcao)
- ef_search=100 pode ser ajustado em runtime (maior = melhor recall, mais lento)

## 7. Custo de Re-embedding

Ao trocar modelo de embedding, TODOS os chunks precisam ser reprocessados
(vetores de modelos diferentes sao incompativeis).

### 7.1 Estimativa de Tempo (GTX 1070)

| Num. chunks | Throughput estimado | Tempo total   |
|-------------|---------------------|---------------|
| 10.000      | ~60 chunks/s        | ~3 minutos    |
| 50.000      | ~60 chunks/s        | ~14 minutos   |
| 100.000     | ~60 chunks/s        | ~28 minutos   |
| 500.000     | ~60 chunks/s        | ~2.3 horas    |

### 7.2 Procedimento de Re-embedding Seguro

1. Criar indice vetorial temporario (nao afetar producao)
2. Processar todos os chunks com novo modelo
3. Validar com golden set (metricas devem atingir thresholds)
4. Swap atomico: renomear indice temporario para producao
5. Manter indice antigo por 30 dias (rollback)
6. Remover indice antigo apos confirmacao

### 7.3 Custo em CPU (fallback)

| Num. chunks | Throughput estimado | Tempo total   |
|-------------|---------------------|---------------|
| 10.000      | ~15 chunks/s        | ~11 minutos   |
| 50.000      | ~15 chunks/s        | ~55 minutos   |
| 100.000     | ~15 chunks/s        | ~1.8 horas    |
| 500.000     | ~15 chunks/s        | ~9.3 horas    |

Aceitavel para processamento offline em janela de manutencao.

## 8. Thresholds de Escala

Indicadores para quando considerar upgrade de infraestrutura:

### 8.1 GPU

| Sinal de alerta                          | Acao                                                   |
|------------------------------------------|--------------------------------------------------------|
| Throughput < 30 chunks/s                 | Investigar; pode ser OOM ou thermal throttling         |
| VRAM livre < 1 GB durante processamento  | Reduzir batch_size ou descarregar reranker             |
| Re-embedding de 100K+ chunks > 1 hora   | Considerar GPU com mais VRAM (RTX 3060+)               |
| Necessidade de >500K chunks              | Upgrade para RTX 3090/4090 ou paralelismo              |

### 8.2 RAM

| Sinal de alerta                          | Acao                                                   |
|------------------------------------------|--------------------------------------------------------|
| Indice vetorial > 50% da RAM disponivel  | Planejar upgrade de RAM                                |
| Swap ativo durante buscas                | Urgente: adicionar RAM ou reduzir indice               |
| Latencia de busca > 500ms (50K chunks)   | Verificar se indice esta em RAM                        |

### 8.3 Disco

| Sinal de alerta                          | Acao                                                   |
|------------------------------------------|--------------------------------------------------------|
| Espaco livre < 20% do SSD               | Limpeza de logs/backups antigos                        |
| Latencia de leitura > 5ms (SSD)          | Verificar saude do SSD (SMART)                         |
| Necessidade de mais de 2 replicas        | Considerar storage distribuido                         |

## 9. Cenarios de Crescimento

| Cenario       | Chunks   | Indice  | RAM indice | Re-embed (GPU) |
|---------------|----------|---------|------------|----------------|
| Fase 1 MVP    | ~5.000   | ~25 MB  | ~50 MB     | ~1.5 min       |
| Fase 2        | ~20.000  | ~100 MB | ~200 MB    | ~5.5 min       |
| Fase 3        | ~50.000  | ~260 MB | ~520 MB    | ~14 min        |
| Fase 4        | ~100.000 | ~520 MB | ~1 GB      | ~28 min        |
| Escala futura | ~500.000 | ~2.6 GB | ~5.2 GB    | ~2.3 horas     |

O ambiente-alvo (64 GB RAM + GTX 1070 + SSD 500 GB) suporta
confortavelmente ate a Fase 4. Para escala futura (500K+ chunks),
planejar upgrade de GPU e avaliar necessidade de RAM adicional.

## Referencias

- ADR-009: Selecao de Modelos de Embedding (Trilha On-Premises)
- ADR-002: Soberania de Dados -- Trilha Cloud vs. On-Premises
- ADR-003: Modelo de Dados da Base Vetorial
- Neo4j Vector Indexes: https://neo4j.com/docs/cypher-manual/current/indexes/semantic-indexes/vector-indexes/
- HNSW: Malkov, Yashunin (2018). "Efficient and robust approximate nearest neighbor search using HNSW graphs"

<!-- conversion_quality: 95 -->
