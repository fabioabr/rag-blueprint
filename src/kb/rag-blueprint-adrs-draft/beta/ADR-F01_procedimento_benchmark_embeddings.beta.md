---
id: BETA-F01
title: "Procedimento de Benchmark de Modelos de Embedding"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-F01_procedimento_benchmark_embeddings.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags:
  - benchmark de embeddings
  - modelos de embedding
  - golden set
  - recall at 10
  - precision at 10
  - mrr mean reciprocal rank
  - ndcg at 10
  - latencia por query
  - avaliacao de modelos
  - comparacao consolidada
  - selecao de modelo
  - thresholds minimos
  - bge-m3
  - multilingual-e5-large-instruct
  - nomic-embed-text
  - all-minilm-l6-v2
  - sentence-transformers
  - similaridade coseno
  - throughput de indexacao
  - consumo de recursos
  - vram utilizada
  - ram utilizada
  - temperatura gpu
  - chunks por segundo
  - curadoria humana
  - grau de relevancia
  - distribuicao por dominio
  - queries dificeis
  - code switching
  - siglas
  - termos exatos
  - portugues brasileiro
  - pipeline de ingestao
  - pipeline de chunking
  - doc types
  - system-doc
  - adr
  - runbook
  - glossary
  - normalizacao de embeddings
  - prefixo de instrucao
  - busca assimetrica
  - analise de erros
  - vieses sistematicos
  - fase 1 mvp
  - fase 2 meta
  - fase 3 prod
  - hardware disponivel
  - gtx 1070
  - licenca mit
  - periodicidade trimestral
  - benchmark emergencial
  - mteb leaderboard
  - miracl benchmark
  - adr-009
  - adr-007
  - adr-008
aliases:
  - "ADR-F01"
  - "Benchmark de Embeddings"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## Objetivo

Definir o procedimento padrao, em 5 etapas, para avaliar e comparar modelos de embedding candidatos antes de adota-los no pipeline de ingestao do RAG Corporativo. O benchmark deve produzir evidencias quantitativas que suportem a decisao de selecao (ou troca) de modelo.

Este procedimento e obrigatorio ANTES de:
- Adotar um novo modelo de embedding
- Trocar o modelo em producao
- Validar upgrade de versao de um modelo existente

## Etapa 1 -- Preparacao

### 1.1 Golden Set

O golden set e o alicerce de todo benchmark. Sem ele, nenhuma metrica e confiavel.

Requisitos minimos:
- Minimo 50 pares query-documento (ideal: 200+)
- Distribuicao equilibrada por dominio (financeiro, arquitetura, operacoes)
- Incluir queries dificeis: ambiguas, com siglas, code-switching pt-BR/en
- Incluir queries com termos exatos (codigos, identificadores, nomes proprios)
- Todas as queries em portugues brasileiro; incluir variantes em ingles
- Curadoria HUMANA obrigatoria — nao gerar pares por IA
- Cada par deve ter grau de relevancia (0 = irrelevante, 1 = parcial, 2 = relevante)

Formato sugerido:

| query_id | query_text | relevant_chunk_ids | relevance_grade |
|----------|-----------|-------------------|----------------|
| Q001 | "Como funciona a cobranca via boleto?" | [C-042, C-043] | [2, 1] |

### 1.2 Chunks Gerados

- Chunks ja processados pelo pipeline de chunking (ADR-006)
- Minimo 1.000 chunks para benchmark significativo
- Incluir chunks de todos os doc_types (system-doc, adr, runbook, glossary)

### 1.3 Modelos Candidatos

Lista recomendada para benchmark comparativo:
- **BGE-M3 (BAAI)** — modelo primario proposto
- **multilingual-e5-large-instruct** — alternativa para ambientes sem GPU
- **nomic-embed-text** — candidato open-source emergente
- **all-MiniLM-L6-v2** — baseline (modelo simples, referencia inferior)

Para cada modelo, registrar:
- Nome e versao (hash do HuggingFace)
- Dimensao do vetor gerado
- Numero de parametros
- Requisitos de hardware (VRAM, RAM)

## Etapa 2 -- Geracao de Embeddings

Para CADA modelo candidato:

### 2.1 Gerar embeddings de todos os chunks do corpus de teste

- Registrar: modelo, versao, batch_size, device (GPU/CPU), precision (fp16/fp32)
- Normalizar embeddings (`normalize_embeddings=True`) para similaridade coseno

### 2.2 Gerar embeddings de todas as queries do golden set

- Usar prefixo de instrucao quando aplicavel (ex: BGE-M3 usa prefixo para queries)
- Registrar se prefixo foi usado e qual

### 2.3 Medir throughput de indexacao

- Chunks por segundo em GPU
- Chunks por segundo em CPU (fallback)
- Tempo total para processar corpus completo

### 2.4 Medir consumo de recursos

- VRAM utilizada (pico)
- RAM utilizada (pico)
- Temperatura GPU (pico)

## Etapa 3 -- Avaliacao (Metricas)

Para cada query do golden set, buscar os top-K chunks mais proximos por similaridade coseno e calcular as seguintes metricas:

### 3.1 Recall@K (K=10)

- Dos chunks relevantes conhecidos, quantos foram encontrados nos top-K?
- Formula: `|relevantes_encontrados| / |relevantes_totais|`
- Principal metrica: mede se o modelo ENCONTRA os documentos certos

### 3.2 Precision@K (K=10)

- Dos top-K retornados, quantos sao de fato relevantes?
- Formula: `|relevantes_no_topK| / K`
- Mede a "limpeza" dos resultados (poucos falsos positivos)

### 3.3 MRR (Mean Reciprocal Rank)

- Posicao media do PRIMEIRO documento relevante
- Formula: `media de (1 / posicao_primeiro_relevante) sobre todas as queries`
- Mede a rapidez com que o usuario encontra algo util

### 3.4 nDCG@K (K=10)

- Qualidade do ranking com relevancia graduada
- Considera que documentos mais relevantes devem aparecer mais acima
- Usa os graus de relevancia do golden set (0, 1, 2)

### 3.5 Latencia por Query

- Tempo medio para gerar embedding da query
- Tempo medio para busca coseno no indice (1K, 10K, 50K chunks)

## Etapa 4 -- Comparacao Consolidada

Montar tabela consolidada com todos os modelos e metricas:

| Modelo | Recall@10 | Precision@10 | MRR | nDCG@10 | Throughput | VRAM |
|--------|----------|-------------|-----|---------|-----------|------|
| BGE-M3 (GPU) | -- | -- | -- | -- | -- c/s | -- GB |
| E5-large (CPU) | -- | -- | -- | -- | -- c/s | -- GB |
| nomic-embed | -- | -- | -- | -- | -- c/s | -- GB |
| MiniLM (baseline) | -- | -- | -- | -- | -- c/s | -- GB |

Analises complementares:
- Comparar performance por dominio (queries financeiras vs tecnicas vs operacionais)
- Comparar performance por idioma (pt-BR puro vs ingles vs code-switching)
- Identificar queries onde cada modelo falha (analise de erros)
- Verificar se algum modelo tem vieses sistematicos (ex: favorece docs longos)

## Etapa 5 -- Decisao

Criterios de selecao (em ordem de prioridade):

### 5.1 Thresholds minimos obrigatorios por fase

| Metrica | Fase 1 MVP | Fase 2 Meta | Fase 3 Prod |
|---------|-----------|------------|------------|
| Recall@10 | >= 70% | >= 80% | >= 85% |
| Precision@10 | >= 50% | >= 60% | >= 70% |
| MRR | >= 0.50 | >= 0.65 | >= 0.75 |

Modelo que NAO atinge os thresholds da fase atual e ELIMINADO.

### 5.2 Equilibrio qualidade / throughput / hardware

- Modelo deve caber no hardware disponivel (GTX 1070 = 8 GB VRAM)
- Throughput minimo aceitavel: 30 chunks/s em GPU para re-embedding viavel
- Preferir modelo com melhor Recall@10 quando empate em outros criterios

### 5.3 Compatibilidade com pipeline

- Modelo deve ser suportado por sentence-transformers
- Licenca MIT ou equivalente (uso comercial irrestrito)
- Suporte a normalizacao de embeddings

### 5.4 Registro da decisao

- Documentar modelo selecionado, versao, metricas obtidas
- Documentar modelos descartados e motivos
- Arquivar golden set e resultados para reprodutibilidade
- Definir data de proximo benchmark (recomendado: trimestral)

## Periodicidade

- Benchmark **OBRIGATORIO**: antes de adotar ou trocar modelo
- Benchmark **RECOMENDADO**: trimestral (novos modelos surgem frequentemente)
- Benchmark **EMERGENCIAL**: quando golden set semanal indicar degradacao de metricas

## Referencias

- ADR-009: Selecao de Modelos de Embedding (Trilha On-Premises)
- ADR-007: Retrieval Hibrido e Agentes Especializados
- ADR-008: Governanca — Papeis, ciclo de vida e rollback
- [MTEB Leaderboard](https://huggingface.co/spaces/mteb/leaderboard)
- [MIRACL Benchmark](https://project-miracl.github.io/)

<!-- conversion_quality: 95 -->
