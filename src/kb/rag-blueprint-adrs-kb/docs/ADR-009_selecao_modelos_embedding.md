---
id: ADR-009
doc_type: adr
title: "Seleção de Modelos de Embedding (Trilha On-Premises)"
system: RAG Corporativo
module: Modelos de Embedding
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-21
tags:
  - embedding
  - bge m3
  - reranker
  - on premises
  - soberania dados
  - modelo embedding
  - base vetorial
  - retrieval hibrido
  - sentence transformers
  - trilha b
  - busca vetorial
  - cross encoder
  - bge reranker v2 m3
  - multilingual e5 large instruct
  - gpu inferencia
  - gtx 1070
  - cuda
  - dimensao vetor
  - 1024 dimensoes
  - cosine similarity
  - hnsw
  - indice vetorial
  - re embedding
  - modo denso
  - modo esparso
  - colbert
  - bi encoder
  - busca assimetrica
  - float32
  - fp16
  - vram
  - throughput
  - batch processing
  - golden set
  - benchmark
  - ndcg
  - recall
  - precision
  - mrr
  - mteb
  - miracl
  - portugues tecnico
  - multilingual
  - code switching
  - soberania regulatoria
  - bacen
  - lgpd
  - cvm
  - licenca mit
  - fallback cpu
  - idempotencia
  - capacity planning
  - pipeline ingestao
aliases:
  - "ADR-009"
  - "Seleção de Embedding"
  - "Modelos de Embedding On-Premises"
  - "BGE-M3 Embedding Strategy"
  - "Embedding Model Selection"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/beta/ADR-009_selecao_modelos_embedding.beta.md"
source_beta_ids:
  - "BETA-009"
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

# ADR-009 — Seleção de Modelos de Embedding (Trilha On-Premises)

## Referências Cruzadas

- **Depende de:**
  - [[ADR-001]]: Pipeline de geração de conhecimento em 4 fases
  - [[ADR-002]]: Soberania de dados — Trilha Cloud vs. On-Premises
- **Relaciona-se:**
  - [[ADR-006]]: Pipeline de ingestão — Da fonte à Base Vetorial
  - [[ADR-007]]: Retrieval híbrido e agentes especializados
  - [[ADR-008]]: Governança — Papéis, ciclo de vida e rollback

## Documentos Extraídos

Os seguintes conteúdos procedimentais e operacionais foram extraídos deste ADR e vivem como documentos autônomos:

- **SPEC-F01:** Procedimento de Benchmark Embeddings (golden set, métricas, processo de benchmark comparativo em 5 etapas, thresholds progressivos por fase)
- **DOC-F02:** Guia de Deploy de Embeddings (instalação CUDA, download de modelos, Dockerfile, otimização de batch para GTX 1070, fallback CPU, parâmetros sentence-transformers/Ollama)
- **DOC-F03:** Capacity Planning Vetorial (cálculo de dimensão, tabelas de impacto no índice por volume de chunks, comparação Trilha A vs Trilha B, custo de re-embedding)

## 1. Sumário

Este ADR define a seleção dos modelos de embedding para a **Trilha B (On-Premises)** do RAG Corporativo. A Trilha B, estabelecida pela [[ADR-002]], é obrigatória para documentos classificados como "restricted" ou "confidential" — dados que **NÃO PODEM** sair da infraestrutura controlada pela organização.

A decisão central é: **QUAL MODELO** de embedding executar localmente, com qual estratégia, para gerar vetores que alimentam a Base Vetorial com qualidade competitiva em relação a opções cloud.

Esta decisão impacta diretamente:

- A qualidade de toda busca semântica no RAG (retrieval quality)
- O tamanho e custo de armazenamento dos índices vetoriais
- A viabilidade de rodar o pipeline no hardware disponível
- O custo de re-indexação futura (se o modelo precisar mudar)

## 2. Contexto

### 2.1. Por que a seleção do modelo de embedding é crítica

O modelo de embedding é o componente mais determinante da qualidade de um sistema RAG. Ele transforma texto em vetores numéricos que capturam o significado semântico — e toda busca vetorial subsequente depende da qualidade dessa transformação.

Se o modelo não "entende" bem português técnico, gera vetores que colocam termos distintos próximos no espaço vetorial (falsos positivos) ou termos relacionados distantes (falsos negativos). **Nenhum reranker ou prompt engineering corrige um embedding ruim na origem.**

O modelo de embedding define:

- **a) DIMENSÃO DO VETOR** — impacta tamanho do índice, latência de busca e capacidade expressiva (ver DOC-F03 para cálculos detalhados)
- **b) QUALIDADE SEMÂNTICA** — capacidade de capturar significado em português técnico-corporativo, incluindo jargão financeiro, regulatório e técnico
- **c) CUSTO DE RE-EMBEDDING** — se o modelo mudar, TODOS os chunks existentes precisam ser re-processados (vetores de modelos diferentes vivem em espaços dimensionais incompatíveis)
- **d) COMPATIBILIDADE COM O PIPELINE DE RETRIEVAL** — deve ser compatível com a estratégia de retrieval híbrido da [[ADR-007]], idealmente suportando múltiplos modos de busca (densa, esparsa, ColBERT)

### 2.2. Requisito de soberania de dados ([[ADR-002]], Trilha B)

A [[ADR-002]] estabeleceu que documentos com confidencialidade "restricted" ou "confidential" **DEVEM** ser processados exclusivamente em infraestrutura controlada pela organização:

- O modelo de embedding **DEVE** rodar localmente (on-premises)
- Os textos dos chunks **NUNCA** podem ser enviados para APIs externas
- Os pesos do modelo devem estar armazenados em disco local
- A inferência deve acontecer em GPU/CPU local

Para uma instituição financeira regulada por BACEN, CVM e sujeita à LGPD, isso é uma **OBRIGAÇÃO REGULATÓRIA**. Documentos que contêm dados de clientes, informações privilegiadas de mercado ou detalhes de operações financeiras DEVEM permanecer dentro do perímetro da organização durante TODO o processamento, incluindo a geração de embeddings.

### 2.3. Posição no pipeline ([[ADR-001]], Fase 4)

Este ADR impacta a Fase 4 (Base Vetorial) do pipeline de 4 fases do [[ADR-001]], especificamente a etapa 4 (Embeddings) do pipeline de ingestão da [[ADR-006]]:

```
[1.Descoberta] -> [2.Parse] -> [3.Chunking] -> [4.Embeddings] -> [5.Persistência] -> [6.Indexação] -> [7.Observabilidade]
```

O modelo escolhido também impacta a [[ADR-007]] (Retrieval Híbrido), porque a busca vetorial usa os embeddings gerados por este modelo e o reranker (também definido neste ADR) atua após a busca vetorial.

### 2.4. Hardware do ambiente-alvo

| Componente | Especificação |
|------------|---------------|
| CPU | Processador multi-core (8+ cores) |
| RAM | 64 GB DDR4 |
| GPU | NVIDIA GeForce GTX 1070 (8 GB VRAM, Pascal, CUDA CC 6.1) |
| Disco | SSD (500+ GB livres) |

A GTX 1070 é uma GPU consumer de 2016, **SUFICIENTE** para embedding batch (processamento offline), mas **NÃO** ideal para inferência de LLM em tempo real. Detalhes de otimização de batch e fallback para CPU estão no DOC-F02.

### 2.5. Requisitos de idioma

Base predominantemente em pt-BR, com cenários multilíngues:

- Documentos técnicos misturam português com termos em inglês
- Siglas regulatórias (BACEN, CVM, LGPD) devem ser reconhecidas como entidades distintas
- ADRs podem conter trechos de código e configurações em inglês

Portanto, o modelo deve ter excelente suporte a pt-BR, bom suporte a inglês, e capacidade de lidar com code-switching.

## 3. Decisão

Adotar uma **ESTRATÉGIA EM CAMADAS (tiered)** com 3 componentes:

| Componente | Modelo | Função |
|------------|--------|--------|
| **1. Modelo primário de indexação** | BGE-M3 (BAAI) | Gera embeddings densos (1024d) para todos os chunks. Roda na GTX 1070 com ~2GB VRAM |
| **2. Modelo de query** | BGE-M3 (mesmo modelo) | Busca assimétrica via prefixo de instrução |
| **3. Reranker** | BGE-Reranker-v2-m3 (BAAI) | Cross-encoder para re-ordenar top-K resultados da busca. Roda em CPU ou GPU |
| **Modelo alternativo (baixo recurso)** | multilingual-e5-large-instruct | Para ambientes sem GPU ou como fallback |

**Todos os modelos rodam 100% on-premises, via sentence-transformers.**

### 3.1. Modelo primário — BGE-M3 (BAAI/bge-m3)

O BGE-M3 (Multi-Functionality, Multi-Linguality, Multi-Granularity) é, em março de 2026, o melhor modelo de embedding open-source para cenários multilíngues on-premises. Licença MIT.

**Justificativas:**

**a) MULTILINGUAL DE ALTA QUALIDADE**
- Treinado em 100+ idiomas com corpus balanceado
- Performance em pt-BR: comparável ou superior a modelos treinados exclusivamente em português
- No MTEB: ~65-68 nDCG@10 em benchmarks multilíngues (OpenAI text-embedding-3-small alcança ~68-70 — diferença de 2-5 pp, aceitável considerando execução 100% local)

**b) TRÊS MODOS DE EMBEDDING (Multi-Functionality)**
1. **MODO DENSO** — vetor único de 1024d, busca por similaridade coseno (modo padrão para fase inicial)
2. **MODO ESPARSO** — vetor esparso com pesos por token, excelente para termos exatos, siglas e códigos (resolve problemas #1 e #3 da [[ADR-007]])
3. **MODO ColBERT** — vetor por token, interação tardia, qualidade superior mas requer mais armazenamento

**RECOMENDAÇÃO PARA FASE INICIAL:** usar apenas MODO DENSO (1024d). Modos esparso e ColBERT podem ser ativados em fases subsequentes.

**c) DIMENSÃO ÓTIMA (1024 dimensões)**
- Equilíbrio entre qualidade e custo de armazenamento
- 4 KB por chunk (1024 x 4 bytes float32)
- 50.000 chunks = ~200 MB de índice vetorial puro
- (detalhamento completo de capacity planning em DOC-F03)

**d) CABE NA GTX 1070**
- Tamanho do modelo: ~2.2 GB (fp16)
- VRAM em inferência: ~2.0-2.5 GB
- Throughput estimado: 50-100 chunks/segundo (inferência batch)
- (parâmetros de otimização em DOC-F02)

**e) LICENÇA ABERTA**
- MIT: uso comercial irrestrito, sem royalties, sem restrições
- Sem risco de lock-in ou mudança unilateral de termos

**f) ECOSSISTEMA MADURO**
- Suportado por sentence-transformers, Ollama, LangChain, LlamaIndex, Haystack

### 3.2. Modelo alternativo — multilingual-e5-large-instruct

Para cenários onde a GPU não está disponível ou está ocupada, o modelo alternativo é o multilingual-e5-large-instruct (intfloat).

- **Dimensão:** 1024 (compatível com índice do BGE-M3)
- **Parâmetros:** ~560M
- **Roda em CPU:** ~10-20 chunks/segundo (8 cores, 64GB RAM)
- **Qualidade:** ~2-3 pontos abaixo do BGE-M3 no MTEB
- **Suporta busca assimétrica** via prefixo `"query:"` / `"passage:"`
- **Licença:** MIT

**Trade-offs:**

- **VANTAGEM:** funciona em CPU (fallback quando GPU indisponível)
- **DESVANTAGEM:** qualidade inferior, especialmente em textos longos
- **DESVANTAGEM:** suporta apenas modo denso (sem esparso ou ColBERT)

**IMPORTANTE:** vetores do E5 são **INCOMPATÍVEIS** com vetores do BGE-M3 — NÃO se pode misturar no mesmo índice. Chunks processados por E5 durante fallback DEVEM ser re-embeddados com BGE-M3 assim que a GPU estiver disponível.

**RASTREABILIDADE POR CHUNK:** cada chunk persistido na Base Vetorial DEVE conter os seguintes metadados obrigatórios:

- `embedding_model`: nome do modelo (ex: `"BAAI/bge-m3"`)
- `embedding_model_version`: hash do commit ou tag no HuggingFace
- `embedding_timestamp`: data/hora da geração do embedding

Isso permite identificar automaticamente chunks que precisam ser re-processados e é fundamental para a premissa de idempotência da [[ADR-006]].

### 3.3. Modelo de query — BGE-M3 (busca assimétrica)

O mesmo BGE-M3 é usado para queries (mesmo espaço vetorial). Suporta busca assimétrica via prefixo de instrução:

- **Para INDEXAÇÃO (chunks):** nenhum prefixo necessário
- **Para QUERY (busca):** prefixo `"Represent this sentence for searching relevant passages: "` — ganho de 1-3 pontos em recall@10

**AÇÃO DE VALIDAÇÃO:** o prefixo recomendado é em inglês (conforme paper original). Para corpus em pt-BR, validar via benchmark (SPEC-F01, golden set) se o prefixo em inglês produz resultados equivalentes ou superiores a um prefixo em português.

### 3.4. Reranker — BGE-Reranker-v2-m3

O reranker atua **DEPOIS** da busca vetorial, recebendo os top-K resultados e re-ordenando-os com análise mais profunda da relação query-documento.

**Por que é essencial:**

- **Busca vetorial (bi-encoder):** rápida mas imprecisa — codifica query e documento SEPARADAMENTE
- **Reranker (cross-encoder):** lento mas preciso — processa query e documento JUNTOS com atenção cruzada token a token
- **Ganho típico:** 5-10 pontos em nDCG@10

**Características do BGE-Reranker-v2-m3:**

| Aspecto | Valor |
|---------|-------|
| Tipo | Cross-encoder multilíngue, excelente suporte a pt-BR |
| Tamanho | ~1.1 GB (fp16) |
| CPU | ~500ms para re-ranquear 50 passagens |
| GPU | ~50ms para re-ranquear 50 passagens |
| VRAM | ~1.5 GB (cabe na GTX 1070 junto com BGE-M3) |
| Licença | MIT |
| Qualidade | Comparável ao Cohere Rerank v3 (diferença de 1-2 pontos em nDCG@10) |

**Integração no pipeline de retrieval ([[ADR-007]]):**

1. Query embeddada com BGE-M3 (modo query)
2. Busca vetorial retorna top-50 chunks
3. Filtragem por metadados (confidencialidade, sistema, módulo)
4. BGE-Reranker-v2-m3 re-ordena os chunks filtrados
5. Top-10 re-ranqueados são enviados ao LLM como contexto

O reranker é usado **APENAS** no momento da busca (online), NÃO na indexação.

## 4. Alternativas Descartadas

### 4.1. OpenAI text-embedding-3-small / text-embedding-3-large

- **Status:** DESCARTADO para Trilha B
- **Razão:** CLOUD-ONLY — dados são enviados para servidores da OpenAI

Qualidade excelente e custo baixo, mas **VIOLA** a soberania de dados ([[ADR-002]]) para documentos restricted e confidential. Regulação BACEN e LGPD exige que dados NEM SEQUER TRANSITEM por infraestrutura não controlada. Continua disponível e RECOMENDADO para a Trilha A (documentos public e internal).

### 4.2. all-MiniLM-L6-v2 / all-MiniLM-L12-v2

- **Status:** DESCARTADO como modelo principal
- **Razão:** PERFORMANCE FRACA EM PORTUGUÊS

Modelo popular e leve (384d, ~90 MB), excelente para inglês. Porém, 8-15 pontos abaixo do BGE-M3 em MTEB para pt-BR. Termos financeiros como "cobrança", "compensação", "liquidação" têm nuances que o MiniLM não captura. Pode ser usado apenas como baseline de benchmark (SPEC-F01).

### 4.3. nomic-embed-text (nomic-ai/nomic-embed-text-v1.5)

- **Status:** DESCARTADO como modelo principal
- **Razão:** INFERIOR AO BGE-M3 EM BENCHMARKS MULTILÍNGUES

Boa qualidade com contexto longo (8192 tokens), dimensão 768, Apache 2.0. Porém: BGE-M3 supera por 5-8 pontos em nDCG@10 (MIRACL, Mr-TyDi). Contexto longo não é vantagem pois chunks são limitados a 300-800 tokens. Não suporta modos esparso e ColBERT.

### 4.4. Modelos com mais de 10B parâmetros (E5-Mistral-7B, etc.)

- **Status:** DESCARTADO
- **Razão:** NÃO CABEM NA GTX 1070 (8 GB VRAM)

E5-Mistral-7B-Instruct (~14 GB em fp16) requer 16+ GB de VRAM. Quantização 4-bit causa degradação significativa em embeddings (mais sensíveis que LLMs generativos). Viabilizar requer upgrade de GPU (fora do escopo atual).

### 4.5. Rerankers cloud-only (Cohere Rerank, Voyage Reranker)

- **Status:** DESCARTADO para Trilha B
- **Razão:** CLOUD-ONLY — mesma restrição de soberania

Cohere Rerank v3 é o melhor reranker do mercado, mas requer envio de texto para API externa. Para Trilha B, texto de chunks restricted/confidential NÃO pode ser enviado para rerankers cloud. BGE-Reranker-v2-m3 é a alternativa local com qualidade comparável (1-2 pontos de diferença). Cohere/Voyage continuam disponíveis para Trilha A.

### 4.6. Fine-tuning de modelo genérico com dados do domínio

- **Status:** DESCARTADO PARA A FASE INICIAL (possível em fases futuras)
- **Razão:** COMPLEXIDADE PREMATURA

Fine-tuning poderia melhorar qualidade em 3-5 pontos, mas requer dataset curado, conhecimento de contrastive learning, pipeline de treinamento e avaliação rigorosa. O BGE-M3 pré-treinado já oferece qualidade suficiente para as fases iniciais. Pode ser considerado na Fase 3/4 se thresholds não forem atingidos.

## 5. Consequências

### 5.1. Consequências positivas

- **a) SOBERANIA TOTAL DOS DADOS** — Nenhum texto sai da infraestrutura local durante o embedding. Conformidade total com BACEN, CVM, LGPD e políticas internas.
- **b) CUSTO ZERO POR TOKEN** — Após a aquisição do hardware (já disponível), custo marginal de embedding é zero. Viabiliza re-embedding, experimentação livre e pipeline de CI/CD que re-processa toda a base em cada release.
- **c) CONTROLE TOTAL DO MODELO** — A organização decide quando atualizar, qual versão usar, e pode reverter a qualquer momento. Sem risco de descontinuação, mudança unilateral de preços ou degradação silenciosa de qualidade.
- **d) LATÊNCIA PREVISÍVEL** — Depende apenas do hardware local, sem congestionamento de API, rate limits ou dependência de internet.
- **e) ECOSSISTEMA UNIFICADO** — BGE-M3 + BGE-Reranker-v2-m3 são do mesmo grupo (BAAI), treinados com objetivos complementares e compatibilidade testada.

### 5.2. Consequências negativas

- **a) TETO DE QUALIDADE INFERIOR AO CLOUD** — BGE-M3 é 2-5 pp abaixo do text-embedding-3-large da OpenAI. Diferença aceitável mas real.
- **b) MANUTENÇÃO DE GPU E INFRAESTRUTURA** — Drivers CUDA, monitoramento de temperatura, backup em caso de falha de hardware, eventual substituição de GPU consumer.
- **c) ATUALIZAÇÕES DE MODELO SÃO MANUAIS** — Novos modelos requerem download, benchmark, re-embedding, validação e deploy coordenado (vs. APIs cloud com atualização transparente).
- **d) CAPACIDADE DE PROCESSAMENTO LIMITADA** — GTX 1070 processa ~60 chunks/segundo. Para bases de 500.000+ chunks, re-embedding levaria ~2.3 horas. Para 1M+ chunks, seria necessário upgrade de GPU ou paralelismo.

### 5.3. Riscos e mitigações

| Risco | Mitigação |
|-------|-----------|
| GTX 1070 falha (hardware) | Fallback para CPU (E5 ou BGE-M3 em CPU). Throughput 5x menor mas funcional. Planejar substituição por GPU moderna. |
| BGE-M3 descontinuado pelo BAAI | Modelo open-source (MIT). Pesos já baixados localmente. Comunidade pode manter forks. Alternativa E5 disponível. |
| Qualidade insuficiente para domínio financeiro específico | Benchmark com golden set ANTES de produção (SPEC-F01). Se thresholds não forem atingidos, considerar fine-tuning ou modelo alternativo. |
| VRAM insuficiente para batch grande | Reduzir batch_size (16->8->4). Em último caso, usar CPU. Monitorar VRAM com alertas. |
| Incompatibilidade de vetores entre modelos | NUNCA misturar vetores de modelos diferentes no mesmo índice. Manter registro do modelo por chunk. Re-embedding completo ao trocar. |
| Driver CUDA incompatível com nova versão do PyTorch | Fixar versão do CUDA no container. Testar atualizações em staging antes de produção. |

## 6. Implementação (alto nível)

A implementação está organizada em 4 fases. Detalhes procedimentais estão nos documentos extraídos (SPEC-F01, DOC-F02, DOC-F03).

### Fase 1 — Validação e benchmark inicial

- Preparar ambiente com CUDA e sentence-transformers
- Baixar modelos para diretório local fixo (operação offline)
- Validar carregamento na GPU e dimensão de saída (1024)
- Montar golden set inicial (50+ pares query-documento)
- Executar benchmark comparativo (conforme SPEC-F01)
- Validar prefixo de query pt-BR vs en
- **Entregável:** Relatório de benchmark com recomendação final

### Fase 2 — Pipeline de batch processing

- Implementar módulo EmbeddingService (`embed_chunks`, `embed_query`)
- Fallback automático para CPU se GPU indisponível
- Observabilidade: métricas por batch e por execução (JSON estruturado)
- Testes automatizados (unitário, integração, fallback, idempotência)
- **Entregável:** Módulo integrado ao pipeline ([[ADR-006]], etapa 4)

### Fase 3 — Integração com Base Vetorial

- Persistência com upsert (chunk_id, embedding, texto, metadados)
- Índice vetorial HNSW (1024d, cosine, M=16, ef_construction=200)
- Registro de modelo por chunk (`embedding_model`, `version`, `timestamp`)
- Registro de execução (modelo, dimensão, totais, duração)
- Validação pós-ingestão com golden set
- **Entregável:** Pipeline integrado com índice vetorial funcional

### Fase 4 — Reranker no pipeline de retrieval

- Implementar módulo RerankerService (rerank com CrossEncoder)
- Integrar ao fluxo: busca vetorial (top-50) -> rerank -> top-10 -> LLM
- Benchmark do impacto do reranker (ganho esperado: 5-10 pp em nDCG@10)
- Otimização de latência (GPU ~50ms, CPU ~500ms para 50 passagens)
- **Entregável:** Pipeline de retrieval completo com reranking

**Thresholds de qualidade progressivos (alinhados com [[ADR-008]]):**

| Métrica | Fase 1 MVP | Fase 2 Meta | Fase 3 Prod |
|---------|-----------|-------------|-------------|
| Recall@10 | >= 70% | >= 80% | >= 85% |
| Precision@10 | >= 50% | >= 60% | >= 70% |
| MRR | >= 0.50 | >= 0.65 | >= 0.75 |

## 7. Referências

### 7.1. ADRs relacionadas

- [[ADR-001]]: Pipeline de geração de conhecimento em 4 fases
- [[ADR-002]]: Soberania de dados — Trilha Cloud vs. On-Premises
- [[ADR-006]]: Pipeline de ingestão — Da fonte à Base Vetorial
- [[ADR-007]]: Retrieval híbrido e agentes especializados
- [[ADR-008]]: Governança — Papéis, ciclo de vida e rollback

### 7.2. Documentos extraídos deste ADR

- SPEC-F01: Procedimento de Benchmark Embeddings
- DOC-F02: Guia de Deploy de Embeddings
- DOC-F03: Capacity Planning Vetorial

### 7.3. Modelos e frameworks

- [BAAI/bge-m3](https://huggingface.co/BAAI/bge-m3)
- [BAAI/bge-reranker-v2-m3](https://huggingface.co/BAAI/bge-reranker-v2-m3)
- [intfloat/multilingual-e5-large-instruct](https://huggingface.co/intfloat/multilingual-e5-large-instruct)
- [sentence-transformers](https://sbert.net/docs/)
- [Ollama (embeddings)](https://ollama.ai/blog/embedding-models)

### 7.4. Benchmarks e leaderboards

- [MTEB](https://huggingface.co/spaces/mteb/leaderboard)
- [MIRACL](https://project-miracl.github.io/)
- [Mr-TyDi](https://github.com/castorini/mr.tydi)

### 7.5. Infraestrutura

- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/)
- [PyTorch CUDA Compatibility](https://pytorch.org/get-started/locally/)

<!-- conversion_quality: 95 -->
