---
id: BETA-D01
title: "Catalogo de Componentes por Trilha (Cloud vs On-Premise)"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-D01_catalogo_componentes_por_trilha.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags:
  - catalogo componentes
  - trilha cloud
  - trilha on-premise
  - trilha hibrida
  - modelo embedding
  - openai text-embedding-3-small
  - bge-m3 baai
  - base vetorial
  - dbaas managed cloud
  - self-hosted docker
  - llm modelo linguagem
  - claude anthropic
  - llama 3.1 70b
  - qwen 2.5 72b
  - reranking modelo
  - cohere rerank v3
  - bge-reranker-v2-m3
  - bi-encoder
  - cross-encoder
  - colbert interacao
  - busca densa
  - busca lexical sparse
  - embeddings incompativeis
  - dimensao 1536
  - dimensao 1024
  - gpu vram requisitos
  - ollama desenvolvimento
  - vllm producao
  - quantizacao q4
  - fp16 inferencia
  - community edition
  - soberania dados
  - confidentiality campo
  - componente restritivo regra
  - busca cross-instancia
  - merge resultados
  - custo por token
  - latencia inferencia
  - mteb benchmark
  - multilingue portugues
  - janela contexto 200k
  - instruction following
  - mineracao beta md
  - geracao front matter
  - citacao fontes
  - rate limits tier
  - mit licenca
  - apache licenca
  - llama community license
  - tensor parallel
  - batching otimizado
  - gpu compartilhamento
  - rtx 4090
  - open source modelos
aliases:
  - "ADR-D01"
  - "Catalogo Componentes Trilha"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## 1. Introducao

Este documento especifica cada componente do pipeline RAG segregado por trilha de execucao, conforme decidido na ADR-002. A trilha e determinada pelo campo `confidentiality` do front matter do documento:

- **Trilha A (Cloud):** dados `public` e `internal`
- **Trilha B (On-Premise):** dados `restricted` e `confidential`
- **Trilha Hibrida:** ambas simultaneamente, com merge controlado

A especificacao cobre quatro componentes obrigatorios:
1. Modelo de Embedding
2. Base Vetorial (armazenamento de grafos + vetores)
3. LLM (modelo de linguagem para geracao)
4. Modelo de Reranking

## 2. Trilha A (Cloud) — Componentes Detalhados

### 2.1 Modelo de Embedding — OpenAI text-embedding-3-small

| Atributo | Valor |
|---|---|
| Fornecedor | OpenAI |
| Modelo | text-embedding-3-small |
| Dimensao padrao | 1536 |
| Dimensoes ajustaveis | 512, 1024, 3072 (via parametro dimensions) |
| Custo | US$ 0,02 por 1 milhao de tokens |
| Latencia tipica | ~100ms para batch de 100 chunks (via API) |
| Suporte pt-BR | Excelente (benchmarks MTEB multilingues) |
| Tipo | Bi-encoder (query e documento codificados separadamente) |
| Autenticacao | API key OpenAI |
| Rate limits | Consultar tier da organizacao (TPM e RPM) |

**Notas:**
- Referencia de mercado em benchmarks MTEB multilingues
- Dimensao ajustavel permite trade-off entre qualidade e custo de storage
- Para o projeto, usar 1536 (padrao) salvo justificativa tecnica

### 2.2 Base Vetorial — Managed Cloud (DBaaS)

| Atributo | Valor |
|---|---|
| Tipo | Instancia gerenciada pelo provedor (DBaaS) |
| Custo estimado | A partir de ~US$ 65/mes para instancias basicas |
| SLA tipico | 99,9% |
| Backup | Automatizado pelo provedor |
| Funcionalidades | Grafo completo, vector index, full-text index, constraints |
| Escalabilidade | Vertical (upgrade de instancia) ou horizontal (read replicas) |

**Notas:**
- Provisionamento rapido (minutos)
- Sem necessidade de equipe de infra dedicada
- Custo escala com volume de dados e queries

### 2.3 LLM — Claude (Anthropic)

| Atributo | Valor |
|---|---|
| Fornecedor | Anthropic |
| Modelos | Claude Sonnet (RAG), Claude Opus (mineracao complexa, Fases 2 e 3) |
| Janela de contexto | 200K tokens |
| Qualidade pt-BR | Excelente |
| Instruction following | Melhor do mercado (referencia em benchmarks de seguimento) |
| Autenticacao | API key Anthropic |

**Uso no pipeline:**
- Fase 2: mineracao e geracao de `.beta.md`
- Fase 3: geracao do `.md` final com front matter completo
- Fase 4: respostas RAG com citacao de fontes

**Notas:**
- Regra de roteamento por confidentiality aplica-se desde a Fase 2
- Dados restricted/confidential NAO podem ser enviados para Claude

### 2.4 Modelo de Reranking — Cohere Rerank v3

| Atributo | Valor |
|---|---|
| Fornecedor | Cohere |
| Modelo | Rerank v3 |
| Custo | US$ 2,00 por 1.000 buscas |
| Latencia tipica | ~150ms para reranking de 50 candidatos |
| Qualidade | Referencia de mercado para reranking multilingue |
| Tipo | Cross-encoder (recebe query + documento juntos) |
| Autenticacao | API key Cohere |

**Notas:**
- Cross-encoder: mais preciso que bi-encoder, porem mais lento
- Aplicado apos busca vetorial para reordenar top-K candidatos
- Funciona com texto (nao com embeddings), portanto agnostico ao modelo de embedding

## 3. Trilha B (On-Premise) — Componentes Detalhados

### 3.1 Modelo de Embedding — BGE-M3 (BAAI)

| Atributo | Valor |
|---|---|
| Fornecedor | BAAI (Beijing Academy of Artificial Intelligence) |
| Modelo | BGE-M3 |
| Dimensao | 1024 (padrao) |
| Custo por token | Zero (modelo open-source, custo e de hardware) |
| Modo hibrido | Nativo — gera 3 representacoes simultaneamente: Dense (1024d), Sparse (lexical, estilo BM25 neural), ColBERT (interacao token-a-token tardia) |
| Qualidade | 95%+ da qualidade do OpenAI em benchmarks multilingues |
| Suporte pt-BR | Excelente (modelo multilingue treinado em 100+ idiomas) |
| Tipo | Bi-encoder com extensoes sparse e ColBERT |
| Licenca | MIT |

**Requisitos de hardware:**
- Minimo: 1x GPU com 8GB VRAM (RTX 3060, RTX 4060, T4)
- Recomendado: 1x GPU com 16GB+ VRAM (RTX 4070 Ti, A10G, L4)

**Notas:**
- Modo hibrido nativo e diferencial: permite busca densa + lexical sem modelo adicional
- Mesma familia do BGE-Reranker, podendo compartilhar GPU
- Para quantizacao, usar FP16 (padrao) — nao quantizar para INT8 sem validar impacto em qualidade

### 3.2 Base Vetorial — Self-Hosted (Community Edition)

| Atributo | Valor |
|---|---|
| Tipo | Instalacao via Docker / Kubernetes em infra propria |
| Custo de licenca | Zero (Community Edition) |
| Custo de hardware | Servidor dedicado |
| Funcionalidades | Grafo completo, vector index, full-text index, constraints |
| Backup | Responsabilidade da equipe de infra |

**Requisitos de hardware:**
- Minimo: 4 vCPU, 16GB RAM, 100GB SSD
- Recomendado: 8 vCPU, 32GB RAM, 500GB NVMe

**Notas:**
- Community Edition possui todas as funcionalidades necessarias para o projeto
- Requer equipe capaz de operar Docker/K8s e monitorar a instancia
- Backup e restore devem ser configurados manualmente

### 3.3 LLM — Llama 3.1 70B ou Qwen 2.5 72B

**Opcao primaria:**

| Atributo | Valor |
|---|---|
| Modelo | Llama 3.1 70B (Meta) |
| Licenca | Llama Community License |
| Qualidade | ~85-90% da qualidade do Claude em tarefas de RAG |
| Ecossistema | Maior ecossistema de tooling e fine-tuning |

**Opcao alternativa:**

| Atributo | Valor |
|---|---|
| Modelo | Qwen 2.5 72B (Alibaba) |
| Licenca | Apache 2.0 |
| Qualidade | Comparavel ao Llama, com vantagem em multilingue |
| Recomendacao | Migrar para Qwen se desempenho em portugues nao for satisfatorio com Llama |

**Hosting:**
- Desenvolvimento: Ollama (setup simples, single-node)
- Producao: vLLM (batching otimizado, multi-GPU, metricas)

**Requisitos de hardware (ambos modelos):**
- Quantizacao: Q4 (4-bit) via GGUF ou AWQ
- GPU: 2x GPU com 24GB VRAM cada (ex: 2x RTX 4090, 2x A5000)
- RAM: 64GB+ sistema
- Storage: 50GB+ para pesos do modelo

**Notas:**
- Modelos de 70B+ sao necessarios para tarefas complexas (geracao de `.beta.md` com front matter, respeito a blocos LOCKED, citacao de fontes)
- Modelos menores (7B-13B) foram descartados: falham em geracao estruturada
- Quantizacao Q4 tem variacao minima — mitigar fixando seed e versao exata
- Para Fase 4 simples (respostas curtas), um 13B pode ser fallback

### 3.4 Modelo de Reranking — BGE-Reranker-v2-m3 (BAAI)

| Atributo | Valor |
|---|---|
| Fornecedor | BAAI |
| Modelo | BGE-Reranker-v2-m3 |
| Qualidade | ~90-95% do Cohere Rerank v3 |
| Latencia tipica | ~100ms para reranking de 50 candidatos em GPU |
| Tipo | Cross-encoder |
| Licenca | MIT |

**Requisitos de hardware:**
- Minimo: 1x GPU com 4GB+ VRAM
- Recomendado: Compartilhar GPU com BGE-M3 (mesma familia)

**Notas:**
- Cross-encoder: recebe texto da query e texto do chunk (nao embeddings)
- Funciona corretamente independente de qual modelo gerou os embeddings
- Sinergia com BGE-M3: mesma familia, mesma GPU pode servir ambos
- No cenario hibrido, o reranker local DEVE ser usado quando chunks restricted/confidential estao presentes no conjunto de candidatos

## 4. Tabela Consolidada — Visao Comparativa

| Componente | Trilha A (Cloud) | Trilha B (On-Premise) |
|---|---|---|
| **Embedding** | OpenAI text-embedding-3-small, 1536d, US$ 0,02/1M tokens, ~100ms/100 chunks | BGE-M3 (BAAI), 1024d, GPU 8GB+ VRAM (custo zero/token) |
| **Base Vetorial** | Managed Cloud (DBaaS), ~US$ 65+/mes, SLA 99,9% | Self-hosted Docker, Community Edition (gratis), 4 vCPU, 16GB+ RAM, 100GB SSD |
| **LLM** | Claude (Anthropic), Sonnet/Opus, 200K tokens contexto | Llama 3.1 70B ou Qwen 2.5 72B, 2x GPU 24GB VRAM, Ollama (dev) / vLLM (prod) |
| **Reranking** | Cohere Rerank v3, US$ 2,00/1K buscas, ~150ms/50 candidatos | BGE-Reranker-v2-m3, GPU 4GB+ VRAM, ~100ms/50 candidatos |

## 5. Incompatibilidades e Restricoes

### 5.1 Embeddings incompativeis entre trilhas

Os vetores gerados pela OpenAI (1536d) e pelo BGE-M3 (1024d) NAO sao compativeis. Um chunk indexado com OpenAI so pode ser buscado com embedding de query gerado pela OpenAI. Isso reforca a necessidade de duas instancias separadas da base vetorial na Trilha Hibrida.

### 5.2 Regra do componente mais restritivo

Quando resultados de ambas as instancias sao mesclados (busca cross-instancia), o reranking e a geracao de resposta DEVEM usar componentes on-premise, pois chunks restricted/confidential estao presentes no conjunto.

**Regra:** o componente mais restritivo determina a trilha para reranking e LLM.

### 5.3 Cross-encoder e agnostico a embeddings

O BGE-Reranker-v2-m3 e um cross-encoder — recebe texto da query e texto do chunk, NAO os embeddings. Portanto, funciona corretamente para reranking de chunks vindos de qualquer modelo de embedding.

## 6. Referencias

- ADR-002: Soberania de Dados — Cloud vs On-Premise (decisao macro)
- ADR-001: Pipeline de Geracao de Conhecimento em 4 Fases
- ADR-003: Modelo de Dados da Base Vetorial
- OpenAI Embeddings: <https://platform.openai.com/docs/guides/embeddings>
- BGE-M3 (BAAI): <https://huggingface.co/BAAI/bge-m3>
- BGE-Reranker-v2-m3: <https://huggingface.co/BAAI/bge-reranker-v2-m3>
- Cohere Rerank: <https://docs.cohere.com/docs/rerank-2>
- Ollama: <https://ollama.ai>
- vLLM: <https://github.com/vllm-project/vllm>

<!-- conversion_quality: 95 -->
