---
id: BETA-009
title: "Selecao de Modelos de Embedding (Trilha On-Premises)"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-009_selecao_modelos_embedding.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags: [embedding, bge-m3, reranker, on-premises, soberania-dados, modelo-embedding, base-vetorial, retrieval-hibrido, sentence-transformers, trilha-b, busca-vetorial, cross-encoder, bge-reranker-v2-m3, multilingual-e5-large-instruct, gpu-inferencia, gtx-1070, cuda, dimensao-vetor, 1024-dimensoes, cosine-similarity, hnsw, indice-vetorial, re-embedding, modo-denso, modo-esparso, colbert, bi-encoder, busca-assimetrica, float32, fp16, vram, throughput, batch-processing, golden-set, benchmark, ndcg, recall, precision, mrr, mteb, miracl, portugues-tecnico, multilingual, code-switching, soberania-regulatoria, bacen, lgpd, cvm, licenca-mit, fallback-cpu, idempotencia, capacity-planning, pipeline-ingestao]
aliases:
  - "ADR-009"
  - "Selecao de Embedding"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## Identificacao

- **ID:** ADR-009
- **Tipo:** ADR (Architecture Decision Record)
- **Sistema:** RAG Corporativo
- **Modulo:** Embedding e Representacao Vetorial
- **Dominio:** Arquitetura
- **Owner:** fabio
- **Time:** arquitetura
- **Confidencialidade:** internal
- **Versao:** 2.0
- **Escopo:** RAG Corporativo -- Selecao e configuracao de modelos de embedding para a Trilha B (On-Premises) do pipeline de ingestao
- **Supersede:** (nenhum)

## Referencias Cruzadas

- **Depende de:**
  - ADR-001: Pipeline de geracao de conhecimento em 4 fases
  - ADR-002: Soberania de dados -- Trilha Cloud vs. On-Premises
- **Relaciona-se:**
  - ADR-006: Pipeline de ingestao -- Da fonte a Base Vetorial
  - ADR-007: Retrieval hibrido e agentes especializados
  - ADR-008: Governanca -- Papeis, ciclo de vida e rollback

## Documentos Extraidos

Os seguintes conteudos procedimentais e operacionais foram extraidos deste ADR e vivem como documentos autonomos:

- **SPEC-F01:** Procedimento de Benchmark Embeddings (golden set, metricas, processo de benchmark comparativo em 5 etapas, thresholds progressivos por fase)
- **DOC-F02:** Guia de Deploy de Embeddings (instalacao CUDA, download de modelos, Dockerfile, otimizacao de batch para GTX 1070, fallback CPU, parametros sentence-transformers/Ollama)
- **DOC-F03:** Capacity Planning Vetorial (calculo de dimensao, tabelas de impacto no indice por volume de chunks, comparacao Trilha A vs Trilha B, custo de re-embedding)

## 1. Sumario

Este ADR define a selecao dos modelos de embedding para a **Trilha B (On-Premises)** do RAG Corporativo. A Trilha B, estabelecida pela ADR-002, e obrigatoria para documentos classificados como "restricted" ou "confidential" -- dados que **NAO PODEM** sair da infraestrutura controlada pela organizacao.

A decisao central e: **QUAL MODELO** de embedding executar localmente, com qual estrategia, para gerar vetores que alimentam a Base Vetorial com qualidade competitiva em relacao a opcoes cloud.

Esta decisao impacta diretamente:

- A qualidade de toda busca semantica no RAG (retrieval quality)
- O tamanho e custo de armazenamento dos indices vetoriais
- A viabilidade de rodar o pipeline no hardware disponivel
- O custo de re-indexacao futura (se o modelo precisar mudar)

## 2. Contexto

### 2.1. Por que a selecao do modelo de embedding e critica

O modelo de embedding e o componente mais determinante da qualidade de um sistema RAG. Ele transforma texto em vetores numericos que capturam o significado semantico -- e toda busca vetorial subsequente depende da qualidade dessa transformacao.

Se o modelo nao "entende" bem portugues tecnico, gera vetores que colocam termos distintos proximos no espaco vetorial (falsos positivos) ou termos relacionados distantes (falsos negativos). **Nenhum reranker ou prompt engineering corrige um embedding ruim na origem.**

O modelo de embedding define:

- **a) DIMENSAO DO VETOR** -- impacta tamanho do indice, latencia de busca e capacidade expressiva (ver DOC-F03 para calculos detalhados)
- **b) QUALIDADE SEMANTICA** -- capacidade de capturar significado em portugues tecnico-corporativo, incluindo jargao financeiro, regulatorio e tecnico
- **c) CUSTO DE RE-EMBEDDING** -- se o modelo mudar, TODOS os chunks existentes precisam ser re-processados (vetores de modelos diferentes vivem em espacos dimensionais incompativeis)
- **d) COMPATIBILIDADE COM O PIPELINE DE RETRIEVAL** -- deve ser compativel com a estrategia de retrieval hibrido da ADR-007, idealmente suportando multiplos modos de busca (densa, esparsa, ColBERT)

### 2.2. Requisito de soberania de dados (ADR-002, Trilha B)

A ADR-002 estabeleceu que documentos com confidencialidade "restricted" ou "confidential" **DEVEM** ser processados exclusivamente em infraestrutura controlada pela organizacao:

- O modelo de embedding **DEVE** rodar localmente (on-premises)
- Os textos dos chunks **NUNCA** podem ser enviados para APIs externas
- Os pesos do modelo devem estar armazenados em disco local
- A inferencia deve acontecer em GPU/CPU local

Para uma instituicao financeira regulada por BACEN, CVM e sujeita a LGPD, isso e uma **OBRIGACAO REGULATORIA**. Documentos que contem dados de clientes, informacoes privilegiadas de mercado ou detalhes de operacoes financeiras DEVEM permanecer dentro do perimetro da organizacao durante TODO o processamento, incluindo a geracao de embeddings.

### 2.3. Posicao no pipeline (ADR-001, Fase 4)

Este ADR impacta a Fase 4 (Base Vetorial) do pipeline de 4 fases do ADR-001, especificamente a etapa 4 (Embeddings) do pipeline de ingestao da ADR-006:

```
[1.Descoberta] -> [2.Parse] -> [3.Chunking] -> [4.Embeddings] -> [5.Persistencia] -> [6.Indexacao] -> [7.Observabilidade]
```

O modelo escolhido tambem impacta a ADR-007 (Retrieval Hibrido), porque a busca vetorial usa os embeddings gerados por este modelo e o reranker (tambem definido neste ADR) atua apos a busca vetorial.

### 2.4. Hardware do ambiente-alvo

| Componente | Especificacao |
|------------|---------------|
| CPU | Processador multi-core (8+ cores) |
| RAM | 64 GB DDR4 |
| GPU | NVIDIA GeForce GTX 1070 (8 GB VRAM, Pascal, CUDA CC 6.1) |
| Disco | SSD (500+ GB livres) |

A GTX 1070 e uma GPU consumer de 2016, **SUFICIENTE** para embedding batch (processamento offline), mas **NAO** ideal para inferencia de LLM em tempo real. Detalhes de otimizacao de batch e fallback para CPU estao no DOC-F02.

### 2.5. Requisitos de idioma

Base predominantemente em pt-BR, com cenarios multilingues:

- Documentos tecnicos misturam portugues com termos em ingles
- Siglas regulatorias (BACEN, CVM, LGPD) devem ser reconhecidas como entidades distintas
- ADRs podem conter trechos de codigo e configuracoes em ingles

Portanto, o modelo deve ter excelente suporte a pt-BR, bom suporte a ingles, e capacidade de lidar com code-switching.

## 3. Decisao

Adotar uma **ESTRATEGIA EM CAMADAS (tiered)** com 3 componentes:

| Componente | Modelo | Funcao |
|------------|--------|--------|
| **1. Modelo primario de indexacao** | BGE-M3 (BAAI) | Gera embeddings densos (1024d) para todos os chunks. Roda na GTX 1070 com ~2GB VRAM |
| **2. Modelo de query** | BGE-M3 (mesmo modelo) | Busca assimetrica via prefixo de instrucao |
| **3. Reranker** | BGE-Reranker-v2-m3 (BAAI) | Cross-encoder para re-ordenar top-K resultados da busca. Roda em CPU ou GPU |
| **Modelo alternativo (baixo recurso)** | multilingual-e5-large-instruct | Para ambientes sem GPU ou como fallback |

**Todos os modelos rodam 100% on-premises, via sentence-transformers.**

### 3.1. Modelo primario -- BGE-M3 (BAAI/bge-m3)

O BGE-M3 (Multi-Functionality, Multi-Linguality, Multi-Granularity) e, em marco de 2026, o melhor modelo de embedding open-source para cenarios multilingues on-premises. Licenca MIT.

**Justificativas:**

**a) MULTILINGUAL DE ALTA QUALIDADE**
- Treinado em 100+ idiomas com corpus balanceado
- Performance em pt-BR: comparavel ou superior a modelos treinados exclusivamente em portugues
- No MTEB: ~65-68 nDCG@10 em benchmarks multilingues (OpenAI text-embedding-3-small alcanca ~68-70 -- diferenca de 2-5 pp, aceitavel considerando execucao 100% local)

**b) TRES MODOS DE EMBEDDING (Multi-Functionality)**
1. **MODO DENSO** -- vetor unico de 1024d, busca por similaridade coseno (modo padrao para fase inicial)
2. **MODO ESPARSO** -- vetor esparso com pesos por token, excelente para termos exatos, siglas e codigos (resolve problemas #1 e #3 da ADR-007)
3. **MODO ColBERT** -- vetor por token, interacao tardia, qualidade superior mas requer mais armazenamento

**RECOMENDACAO PARA FASE INICIAL:** usar apenas MODO DENSO (1024d). Modos esparso e ColBERT podem ser ativados em fases subsequentes.

**c) DIMENSAO OTIMA (1024 dimensoes)**
- Equilibrio entre qualidade e custo de armazenamento
- 4 KB por chunk (1024 x 4 bytes float32)
- 50.000 chunks = ~200 MB de indice vetorial puro
- (detalhamento completo de capacity planning em DOC-F03)

**d) CABE NA GTX 1070**
- Tamanho do modelo: ~2.2 GB (fp16)
- VRAM em inferencia: ~2.0-2.5 GB
- Throughput estimado: 50-100 chunks/segundo (inferencia batch)
- (parametros de otimizacao em DOC-F02)

**e) LICENCA ABERTA**
- MIT: uso comercial irrestrito, sem royalties, sem restricoes
- Sem risco de lock-in ou mudanca unilateral de termos

**f) ECOSSISTEMA MADURO**
- Suportado por sentence-transformers, Ollama, LangChain, LlamaIndex, Haystack

### 3.2. Modelo alternativo -- multilingual-e5-large-instruct

Para cenarios onde a GPU nao esta disponivel ou esta ocupada, o modelo alternativo e o multilingual-e5-large-instruct (intfloat).

- **Dimensao:** 1024 (compativel com indice do BGE-M3)
- **Parametros:** ~560M
- **Roda em CPU:** ~10-20 chunks/segundo (8 cores, 64GB RAM)
- **Qualidade:** ~2-3 pontos abaixo do BGE-M3 no MTEB
- **Suporta busca assimetrica** via prefixo `"query:"` / `"passage:"`
- **Licenca:** MIT

**Trade-offs:**

- **VANTAGEM:** funciona em CPU (fallback quando GPU indisponivel)
- **DESVANTAGEM:** qualidade inferior, especialmente em textos longos
- **DESVANTAGEM:** suporta apenas modo denso (sem esparso ou ColBERT)

**IMPORTANTE:** vetores do E5 sao **INCOMPATIVEIS** com vetores do BGE-M3 -- NAO se pode misturar no mesmo indice. Chunks processados por E5 durante fallback DEVEM ser re-embeddados com BGE-M3 assim que a GPU estiver disponivel.

**RASTREABILIDADE POR CHUNK:** cada chunk persistido na Base Vetorial DEVE conter os seguintes metadados obrigatorios:

- `embedding_model`: nome do modelo (ex: `"BAAI/bge-m3"`)
- `embedding_model_version`: hash do commit ou tag no HuggingFace
- `embedding_timestamp`: data/hora da geracao do embedding

Isso permite identificar automaticamente chunks que precisam ser re-processados e e fundamental para a premissa de idempotencia da ADR-006.

### 3.3. Modelo de query -- BGE-M3 (busca assimetrica)

O mesmo BGE-M3 e usado para queries (mesmo espaco vetorial). Suporta busca assimetrica via prefixo de instrucao:

- **Para INDEXACAO (chunks):** nenhum prefixo necessario
- **Para QUERY (busca):** prefixo `"Represent this sentence for searching relevant passages: "` -- ganho de 1-3 pontos em recall@10

**ACAO DE VALIDACAO:** o prefixo recomendado e em ingles (conforme paper original). Para corpus em pt-BR, validar via benchmark (SPEC-F01, golden set) se o prefixo em ingles produz resultados equivalentes ou superiores a um prefixo em portugues.

### 3.4. Reranker -- BGE-Reranker-v2-m3

O reranker atua **DEPOIS** da busca vetorial, recebendo os top-K resultados e re-ordenando-os com analise mais profunda da relacao query-documento.

**Por que e essencial:**

- **Busca vetorial (bi-encoder):** rapida mas imprecisa -- codifica query e documento SEPARADAMENTE
- **Reranker (cross-encoder):** lento mas preciso -- processa query e documento JUNTOS com atencao cruzada token a token
- **Ganho tipico:** 5-10 pontos em nDCG@10

**Caracteristicas do BGE-Reranker-v2-m3:**

| Aspecto | Valor |
|---------|-------|
| Tipo | Cross-encoder multilingue, excelente suporte a pt-BR |
| Tamanho | ~1.1 GB (fp16) |
| CPU | ~500ms para re-ranquear 50 passagens |
| GPU | ~50ms para re-ranquear 50 passagens |
| VRAM | ~1.5 GB (cabe na GTX 1070 junto com BGE-M3) |
| Licenca | MIT |
| Qualidade | Comparavel ao Cohere Rerank v3 (diferenca de 1-2 pontos em nDCG@10) |

**Integracao no pipeline de retrieval (ADR-007):**

1. Query embeddada com BGE-M3 (modo query)
2. Busca vetorial retorna top-50 chunks
3. Filtragem por metadados (confidencialidade, sistema, modulo)
4. BGE-Reranker-v2-m3 re-ordena os chunks filtrados
5. Top-10 re-ranqueados sao enviados ao LLM como contexto

O reranker e usado **APENAS** no momento da busca (online), NAO na indexacao.

## 4. Alternativas Descartadas

### 4.1. OpenAI text-embedding-3-small / text-embedding-3-large

- **Status:** DESCARTADO para Trilha B
- **Razao:** CLOUD-ONLY -- dados sao enviados para servidores da OpenAI

Qualidade excelente e custo baixo, mas **VIOLA** a soberania de dados (ADR-002) para documentos restricted e confidential. Regulacao BACEN e LGPD exige que dados NEM SEQUER TRANSITEM por infraestrutura nao controlada. Continua disponivel e RECOMENDADO para a Trilha A (documentos public e internal).

### 4.2. all-MiniLM-L6-v2 / all-MiniLM-L12-v2

- **Status:** DESCARTADO como modelo principal
- **Razao:** PERFORMANCE FRACA EM PORTUGUES

Modelo popular e leve (384d, ~90 MB), excelente para ingles. Porem, 8-15 pontos abaixo do BGE-M3 em MTEB para pt-BR. Termos financeiros como "cobranca", "compensacao", "liquidacao" tem nuances que o MiniLM nao captura. Pode ser usado apenas como baseline de benchmark (SPEC-F01).

### 4.3. nomic-embed-text (nomic-ai/nomic-embed-text-v1.5)

- **Status:** DESCARTADO como modelo principal
- **Razao:** INFERIOR AO BGE-M3 EM BENCHMARKS MULTILINGUES

Boa qualidade com contexto longo (8192 tokens), dimensao 768, Apache 2.0. Porem: BGE-M3 supera por 5-8 pontos em nDCG@10 (MIRACL, Mr-TyDi). Contexto longo nao e vantagem pois chunks sao limitados a 300-800 tokens. Nao suporta modos esparso e ColBERT.

### 4.4. Modelos com mais de 10B parametros (E5-Mistral-7B, etc.)

- **Status:** DESCARTADO
- **Razao:** NAO CABEM NA GTX 1070 (8 GB VRAM)

E5-Mistral-7B-Instruct (~14 GB em fp16) requer 16+ GB de VRAM. Quantizacao 4-bit causa degradacao significativa em embeddings (mais sensiveis que LLMs generativos). Viabilizar requer upgrade de GPU (fora do escopo atual).

### 4.5. Rerankers cloud-only (Cohere Rerank, Voyage Reranker)

- **Status:** DESCARTADO para Trilha B
- **Razao:** CLOUD-ONLY -- mesma restricao de soberania

Cohere Rerank v3 e o melhor reranker do mercado, mas requer envio de texto para API externa. Para Trilha B, texto de chunks restricted/confidential NAO pode ser enviado para rerankers cloud. BGE-Reranker-v2-m3 e a alternativa local com qualidade comparavel (1-2 pontos de diferenca). Cohere/Voyage continuam disponiveis para Trilha A.

### 4.6. Fine-tuning de modelo generico com dados do dominio

- **Status:** DESCARTADO PARA A FASE INICIAL (possivel em fases futuras)
- **Razao:** COMPLEXIDADE PREMATURA

Fine-tuning poderia melhorar qualidade em 3-5 pontos, mas requer dataset curado, conhecimento de contrastive learning, pipeline de treinamento e avaliacao rigorosa. O BGE-M3 pre-treinado ja oferece qualidade suficiente para as fases iniciais. Pode ser considerado na Fase 3/4 se thresholds nao forem atingidos.

## 5. Consequencias

### 5.1. Consequencias positivas

- **a) SOBERANIA TOTAL DOS DADOS** -- Nenhum texto sai da infraestrutura local durante o embedding. Conformidade total com BACEN, CVM, LGPD e politicas internas.
- **b) CUSTO ZERO POR TOKEN** -- Apos a aquisicao do hardware (ja disponivel), custo marginal de embedding e zero. Viabiliza re-embedding, experimentacao livre e pipeline de CI/CD que re-processa toda a base em cada release.
- **c) CONTROLE TOTAL DO MODELO** -- A organizacao decide quando atualizar, qual versao usar, e pode reverter a qualquer momento. Sem risco de descontinuacao, mudanca unilateral de precos ou degradacao silenciosa de qualidade.
- **d) LATENCIA PREVISIVEL** -- Depende apenas do hardware local, sem congestionamento de API, rate limits ou dependencia de internet.
- **e) ECOSSISTEMA UNIFICADO** -- BGE-M3 + BGE-Reranker-v2-m3 sao do mesmo grupo (BAAI), treinados com objetivos complementares e compatibilidade testada.

### 5.2. Consequencias negativas

- **a) TETO DE QUALIDADE INFERIOR AO CLOUD** -- BGE-M3 e 2-5 pp abaixo do text-embedding-3-large da OpenAI. Diferenca aceitavel mas real.
- **b) MANUTENCAO DE GPU E INFRAESTRUTURA** -- Drivers CUDA, monitoramento de temperatura, backup em caso de falha de hardware, eventual substituicao de GPU consumer.
- **c) ATUALIZACOES DE MODELO SAO MANUAIS** -- Novos modelos requerem download, benchmark, re-embedding, validacao e deploy coordenado (vs. APIs cloud com atualizacao transparente).
- **d) CAPACIDADE DE PROCESSAMENTO LIMITADA** -- GTX 1070 processa ~60 chunks/segundo. Para bases de 500.000+ chunks, re-embedding levaria ~2.3 horas. Para 1M+ chunks, seria necessario upgrade de GPU ou paralelismo.

### 5.3. Riscos e mitigacoes

| Risco | Mitigacao |
|-------|-----------|
| GTX 1070 falha (hardware) | Fallback para CPU (E5 ou BGE-M3 em CPU). Throughput 5x menor mas funcional. Planejar substituicao por GPU moderna. |
| BGE-M3 descontinuado pelo BAAI | Modelo open-source (MIT). Pesos ja baixados localmente. Comunidade pode manter forks. Alternativa E5 disponivel. |
| Qualidade insuficiente para dominio financeiro especifico | Benchmark com golden set ANTES de producao (SPEC-F01). Se thresholds nao forem atingidos, considerar fine-tuning ou modelo alternativo. |
| VRAM insuficiente para batch grande | Reduzir batch_size (16->8->4). Em ultimo caso, usar CPU. Monitorar VRAM com alertas. |
| Incompatibilidade de vetores entre modelos | NUNCA misturar vetores de modelos diferentes no mesmo indice. Manter registro do modelo por chunk. Re-embedding completo ao trocar. |
| Driver CUDA incompativel com nova versao do PyTorch | Fixar versao do CUDA no container. Testar atualizacoes em staging antes de producao. |

## 6. Implementacao (alto nivel)

A implementacao esta organizada em 4 fases. Detalhes procedimentais estao nos documentos extraidos (SPEC-F01, DOC-F02, DOC-F03).

### Fase 1 -- Validacao e benchmark inicial

- Preparar ambiente com CUDA e sentence-transformers
- Baixar modelos para diretorio local fixo (operacao offline)
- Validar carregamento na GPU e dimensao de saida (1024)
- Montar golden set inicial (50+ pares query-documento)
- Executar benchmark comparativo (conforme SPEC-F01)
- Validar prefixo de query pt-BR vs en
- **Entregavel:** Relatorio de benchmark com recomendacao final

### Fase 2 -- Pipeline de batch processing

- Implementar modulo EmbeddingService (`embed_chunks`, `embed_query`)
- Fallback automatico para CPU se GPU indisponivel
- Observabilidade: metricas por batch e por execucao (JSON estruturado)
- Testes automatizados (unitario, integracao, fallback, idempotencia)
- **Entregavel:** Modulo integrado ao pipeline (ADR-006, etapa 4)

### Fase 3 -- Integracao com Base Vetorial

- Persistencia com upsert (chunk_id, embedding, texto, metadados)
- Indice vetorial HNSW (1024d, cosine, M=16, ef_construction=200)
- Registro de modelo por chunk (`embedding_model`, `version`, `timestamp`)
- Registro de execucao (modelo, dimensao, totais, duracao)
- Validacao pos-ingestao com golden set
- **Entregavel:** Pipeline integrado com indice vetorial funcional

### Fase 4 -- Reranker no pipeline de retrieval

- Implementar modulo RerankerService (rerank com CrossEncoder)
- Integrar ao fluxo: busca vetorial (top-50) -> rerank -> top-10 -> LLM
- Benchmark do impacto do reranker (ganho esperado: 5-10 pp em nDCG@10)
- Otimizacao de latencia (GPU ~50ms, CPU ~500ms para 50 passagens)
- **Entregavel:** Pipeline de retrieval completo com reranking

**Thresholds de qualidade progressivos (alinhados com ADR-008):**

| Metrica | Fase 1 MVP | Fase 2 Meta | Fase 3 Prod |
|---------|-----------|-------------|-------------|
| Recall@10 | >= 70% | >= 80% | >= 85% |
| Precision@10 | >= 50% | >= 60% | >= 70% |
| MRR | >= 0.50 | >= 0.65 | >= 0.75 |

## 7. Referencias

### 7.1. ADRs relacionadas

- ADR-001: Pipeline de geracao de conhecimento em 4 fases
- ADR-002: Soberania de dados -- Trilha Cloud vs. On-Premises
- ADR-006: Pipeline de ingestao -- Da fonte a Base Vetorial
- ADR-007: Retrieval hibrido e agentes especializados
- ADR-008: Governanca -- Papeis, ciclo de vida e rollback

### 7.2. Documentos extraidos deste ADR

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
