---
id: ADR-F01
doc_type: adr
title: "Procedimento de Benchmark de Modelos de Embedding"
system: RAG Corporativo
module: Benchmark Embeddings
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
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
  - bge m3
  - multilingual e5 large instruct
  - nomic embed text
  - all minilm l6 v2
  - sentence transformers
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
  - system doc
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
aliases:
  - "ADR-F01"
  - "Benchmark de Embeddings"
  - "Procedimento de Benchmark"
  - "Avaliação de Modelos de Embedding"
  - "Benchmark de Modelos"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/draft/ADR-F01_procedimento_benchmark_embeddings.txt"
source_beta_ids:
  - "BETA-F01"
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

# ADR-F01 — Procedimento de Benchmark de Modelos de Embedding

| Campo | Valor |
|-------|-------|
| **Status** | Accepted |
| **Data da Decisão** | 2026-03-23 |
| **Decisor** | fabio |
| **Escopo** | Benchmark Embeddings |

**Referências Cruzadas:**

- **Depende de:** [[ADR-009]]
- **Relaciona-se:** [[ADR-007]], [[ADR-008]], [[ADR-006]]

## Objetivo

Definir o procedimento padrão, em 5 etapas, para avaliar e comparar modelos de embedding candidatos antes de adotá-los no pipeline de ingestão do RAG Corporativo. O benchmark deve produzir evidências quantitativas que suportem a decisão de seleção (ou troca) de modelo.

Este procedimento é obrigatório ANTES de:
- Adotar um novo modelo de embedding
- Trocar o modelo em produção
- Validar upgrade de versão de um modelo existente

## Etapa 1 — Preparação

### 1.1 Golden Set

O golden set é o alicerce de todo benchmark. Sem ele, nenhuma métrica é confiável.

Requisitos mínimos:
- Mínimo 50 pares query-documento (ideal: 200+)
- Distribuição equilibrada por domínio (financeiro, arquitetura, operações)
- Incluir queries difíceis: ambíguas, com siglas, code-switching pt-BR/en
- Incluir queries com termos exatos (códigos, identificadores, nomes próprios)
- Todas as queries em português brasileiro; incluir variantes em inglês
- Curadoria HUMANA obrigatória — não gerar pares por IA
- Cada par deve ter grau de relevância (0 = irrelevante, 1 = parcial, 2 = relevante)

Formato sugerido:

| query_id | query_text | relevant_chunk_ids | relevance_grade |
|----------|-----------|-------------------|----------------|
| Q001 | "Como funciona a cobrança via boleto?" | [C-042, C-043] | [2, 1] |

### 1.2 Chunks Gerados

- Chunks já processados pelo pipeline de chunking ([[ADR-006]])
- Mínimo 1.000 chunks para benchmark significativo
- Incluir chunks de todos os doc_types (system-doc, adr, runbook, glossary)

### 1.3 Modelos Candidatos

Lista recomendada para benchmark comparativo:
- **BGE-M3 (BAAI)** — modelo primário proposto
- **multilingual-e5-large-instruct** — alternativa para ambientes sem GPU
- **nomic-embed-text** — candidato open-source emergente
- **all-MiniLM-L6-v2** — baseline (modelo simples, referência inferior)

Para cada modelo, registrar:
- Nome e versão (hash do HuggingFace)
- Dimensão do vetor gerado
- Número de parâmetros
- Requisitos de hardware (VRAM, RAM)

## Etapa 2 — Geração de Embeddings

Para CADA modelo candidato:

### 2.1 Gerar embeddings de todos os chunks do corpus de teste

- Registrar: modelo, versão, batch_size, device (GPU/CPU), precision (fp16/fp32)
- Normalizar embeddings (`normalize_embeddings=True`) para similaridade cosseno

### 2.2 Gerar embeddings de todas as queries do golden set

- Usar prefixo de instrução quando aplicável (ex: BGE-M3 usa prefixo para queries)
- Registrar se prefixo foi usado e qual

### 2.3 Medir throughput de indexação

- Chunks por segundo em GPU
- Chunks por segundo em CPU (fallback)
- Tempo total para processar corpus completo

### 2.4 Medir consumo de recursos

- VRAM utilizada (pico)
- RAM utilizada (pico)
- Temperatura GPU (pico)

## Etapa 3 — Avaliação (Métricas)

Para cada query do golden set, buscar os top-K chunks mais próximos por similaridade cosseno e calcular as seguintes métricas:

### 3.1 Recall@K (K=10)

- Dos chunks relevantes conhecidos, quantos foram encontrados nos top-K?
- Fórmula: `|relevantes_encontrados| / |relevantes_totais|`
- Principal métrica: mede se o modelo ENCONTRA os documentos certos

### 3.2 Precision@K (K=10)

- Dos top-K retornados, quantos são de fato relevantes?
- Fórmula: `|relevantes_no_topK| / K`
- Mede a "limpeza" dos resultados (poucos falsos positivos)

### 3.3 MRR (Mean Reciprocal Rank)

- Posição média do PRIMEIRO documento relevante
- Fórmula: `média de (1 / posição_primeiro_relevante) sobre todas as queries`
- Mede a rapidez com que o usuário encontra algo útil

### 3.4 nDCG@K (K=10)

- Qualidade do ranking com relevância graduada
- Considera que documentos mais relevantes devem aparecer mais acima
- Usa os graus de relevância do golden set (0, 1, 2)

### 3.5 Latência por Query

- Tempo médio para gerar embedding da query
- Tempo médio para busca cosseno no índice (1K, 10K, 50K chunks)

## Etapa 4 — Comparação Consolidada

Montar tabela consolidada com todos os modelos e métricas:

| Modelo | Recall@10 | Precision@10 | MRR | nDCG@10 | Throughput | VRAM |
|--------|----------|-------------|-----|---------|-----------|------|
| BGE-M3 (GPU) | -- | -- | -- | -- | -- c/s | -- GB |
| E5-large (CPU) | -- | -- | -- | -- | -- c/s | -- GB |
| nomic-embed | -- | -- | -- | -- | -- c/s | -- GB |
| MiniLM (baseline) | -- | -- | -- | -- | -- c/s | -- GB |

Análises complementares:
- Comparar performance por domínio (queries financeiras vs técnicas vs operacionais)
- Comparar performance por idioma (pt-BR puro vs inglês vs code-switching)
- Identificar queries onde cada modelo falha (análise de erros)
- Verificar se algum modelo tem vieses sistemáticos (ex: favorece docs longos)

## Etapa 5 — Decisão

Critérios de seleção (em ordem de prioridade):

### 5.1 Thresholds mínimos obrigatórios por fase

| Métrica | Fase 1 MVP | Fase 2 Meta | Fase 3 Prod |
|---------|-----------|------------|------------|
| Recall@10 | >= 70% | >= 80% | >= 85% |
| Precision@10 | >= 50% | >= 60% | >= 70% |
| MRR | >= 0.50 | >= 0.65 | >= 0.75 |

Modelo que NÃO atinge os thresholds da fase atual é ELIMINADO.

### 5.2 Equilíbrio qualidade / throughput / hardware

- Modelo deve caber no hardware disponível (GTX 1070 = 8 GB VRAM)
- Throughput mínimo aceitável: 30 chunks/s em GPU para re-embedding viável
- Preferir modelo com melhor Recall@10 quando empate em outros critérios

### 5.3 Compatibilidade com pipeline

- Modelo deve ser suportado por sentence-transformers
- Licença MIT ou equivalente (uso comercial irrestrito)
- Suporte a normalização de embeddings

### 5.4 Registro da decisão

- Documentar modelo selecionado, versão, métricas obtidas
- Documentar modelos descartados e motivos
- Arquivar golden set e resultados para reprodutibilidade
- Definir data de próximo benchmark (recomendado: trimestral)

## Periodicidade

- Benchmark **OBRIGATÓRIO**: antes de adotar ou trocar modelo
- Benchmark **RECOMENDADO**: trimestral (novos modelos surgem frequentemente)
- Benchmark **EMERGENCIAL**: quando golden set semanal indicar degradação de métricas

## Referências

- [[ADR-009]]: Seleção de Modelos de Embedding (Trilha On-Premises)
- [[ADR-007]]: Retrieval Híbrido e Agentes Especializados
- [[ADR-008]]: Governança — Papéis, ciclo de vida e rollback
- [MTEB Leaderboard](https://huggingface.co/spaces/mteb/leaderboard)
- [MIRACL Benchmark](https://project-miracl.github.io/)

<!-- conversion_quality: 95 -->
