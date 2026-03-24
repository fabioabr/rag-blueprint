---
id: ADR-D01
doc_type: adr
title: "Catálogo de Componentes por Trilha (Cloud vs On-Premise)"
system: RAG Corporativo
module: Componentes por Trilha
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - catálogo componentes
  - trilha cloud
  - trilha on-premise
  - trilha híbrida
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
  - colbert interação
  - busca densa
  - busca lexical sparse
  - embeddings incompatíveis
  - dimensão 1536
  - dimensão 1024
  - gpu vram requisitos
  - ollama desenvolvimento
  - vllm produção
  - quantização q4
  - fp16 inferência
  - community edition
  - soberania dados
  - confidentiality campo
  - componente restritivo regra
  - busca cross-instância
  - merge resultados
  - custo por token
  - latência inferência
  - mteb benchmark
  - multilíngue português
  - janela contexto 200k
  - instruction following
  - mineração beta md
  - geração front matter
  - citação fontes
  - rate limits tier
  - mit licença
  - apache licença
  - llama community license
  - tensor parallel
  - batching otimizado
  - gpu compartilhamento
  - rtx 4090
  - open source modelos
aliases:
  - "ADR-D01"
  - "Catálogo Componentes Trilha"
  - "Componentes Cloud vs On-Premise"
  - "Especificação de Componentes RAG"
  - "Stack Técnico por Trilha"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-D01_catalogo_componentes_por_trilha.beta.md"
source_beta_ids:
  - "BETA-D01"
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

# ADR-D01 — Catálogo de Componentes por Trilha (Cloud vs On-Premise)

## 1. Introdução

Este documento especifica cada componente do pipeline RAG segregado por trilha de execução, conforme decidido na [[ADR-002]]. A trilha é determinada pelo campo `confidentiality` do front matter do documento:

- **Trilha A (Cloud):** dados `public` e `internal`
- **Trilha B (On-Premise):** dados `restricted` e `confidential`
- **Trilha Híbrida:** ambas simultaneamente, com merge controlado

A especificação cobre quatro componentes obrigatórios:
1. Modelo de Embedding
2. Base Vetorial (armazenamento de grafos + vetores)
3. LLM (modelo de linguagem para geração)
4. Modelo de Reranking

## 2. Trilha A (Cloud) — Componentes Detalhados

### 2.1 Modelo de Embedding — OpenAI text-embedding-3-small

| Atributo | Valor |
|---|---|
| Fornecedor | OpenAI |
| Modelo | text-embedding-3-small |
| Dimensão padrão | 1536 |
| Dimensões ajustáveis | 512, 1024, 3072 (via parâmetro dimensions) |
| Custo | US$ 0,02 por 1 milhão de tokens |
| Latência típica | ~100ms para batch de 100 chunks (via API) |
| Suporte pt-BR | Excelente (benchmarks MTEB multilíngues) |
| Tipo | Bi-encoder (query e documento codificados separadamente) |
| Autenticação | API key OpenAI |
| Rate limits | Consultar tier da organização (TPM e RPM) |

**Notas:**
- Referência de mercado em benchmarks MTEB multilíngues
- Dimensão ajustável permite trade-off entre qualidade e custo de storage
- Para o projeto, usar 1536 (padrão) salvo justificativa técnica

### 2.2 Base Vetorial — Managed Cloud (DBaaS)

| Atributo | Valor |
|---|---|
| Tipo | Instância gerenciada pelo provedor (DBaaS) |
| Custo estimado | A partir de ~US$ 65/mês para instâncias básicas |
| SLA típico | 99,9% |
| Backup | Automatizado pelo provedor |
| Funcionalidades | Grafo completo, vector index, full-text index, constraints |
| Escalabilidade | Vertical (upgrade de instância) ou horizontal (read replicas) |

**Notas:**
- Provisionamento rápido (minutos)
- Sem necessidade de equipe de infra dedicada
- Custo escala com volume de dados e queries

### 2.3 LLM — Claude (Anthropic)

| Atributo | Valor |
|---|---|
| Fornecedor | Anthropic |
| Modelos | Claude Sonnet (RAG), Claude Opus (mineração complexa, Fases 2 e 3) |
| Janela de contexto | 200K tokens |
| Qualidade pt-BR | Excelente |
| Instruction following | Melhor do mercado (referência em benchmarks de seguimento) |
| Autenticação | API key Anthropic |

**Uso no pipeline:**
- Fase 2: mineração e geração de `.beta.md`
- Fase 3: geração do `.md` final com front matter completo
- Fase 4: respostas RAG com citação de fontes

**Notas:**
- Regra de roteamento por confidentiality aplica-se desde a Fase 2
- Dados restricted/confidential NÃO podem ser enviados para Claude

### 2.4 Modelo de Reranking — Cohere Rerank v3

| Atributo | Valor |
|---|---|
| Fornecedor | Cohere |
| Modelo | Rerank v3 |
| Custo | US$ 2,00 por 1.000 buscas |
| Latência típica | ~150ms para reranking de 50 candidatos |
| Qualidade | Referência de mercado para reranking multilíngue |
| Tipo | Cross-encoder (recebe query + documento juntos) |
| Autenticação | API key Cohere |

**Notas:**
- Cross-encoder: mais preciso que bi-encoder, porém mais lento
- Aplicado após busca vetorial para reordenar top-K candidatos
- Funciona com texto (não com embeddings), portanto agnóstico ao modelo de embedding

## 3. Trilha B (On-Premise) — Componentes Detalhados

### 3.1 Modelo de Embedding — BGE-M3 (BAAI)

| Atributo | Valor |
|---|---|
| Fornecedor | BAAI (Beijing Academy of Artificial Intelligence) |
| Modelo | BGE-M3 |
| Dimensão | 1024 (padrão) |
| Custo por token | Zero (modelo open-source, custo é de hardware) |
| Modo híbrido | Nativo — gera 3 representações simultaneamente: Dense (1024d), Sparse (lexical, estilo BM25 neural), ColBERT (interação token-a-token tardia) |
| Qualidade | 95%+ da qualidade do OpenAI em benchmarks multilíngues |
| Suporte pt-BR | Excelente (modelo multilíngue treinado em 100+ idiomas) |
| Tipo | Bi-encoder com extensões sparse e ColBERT |
| Licença | MIT |

**Requisitos de hardware:**
- Mínimo: 1x GPU com 8GB VRAM (RTX 3060, RTX 4060, T4)
- Recomendado: 1x GPU com 16GB+ VRAM (RTX 4070 Ti, A10G, L4)

**Notas:**
- Modo híbrido nativo é diferencial: permite busca densa + lexical sem modelo adicional
- Mesma família do BGE-Reranker, podendo compartilhar GPU
- Para quantização, usar FP16 (padrão) — não quantizar para INT8 sem validar impacto em qualidade

### 3.2 Base Vetorial — Self-Hosted (Community Edition)

| Atributo | Valor |
|---|---|
| Tipo | Instalação via Docker / Kubernetes em infra própria |
| Custo de licença | Zero (Community Edition) |
| Custo de hardware | Servidor dedicado |
| Funcionalidades | Grafo completo, vector index, full-text index, constraints |
| Backup | Responsabilidade da equipe de infra |

**Requisitos de hardware:**
- Mínimo: 4 vCPU, 16GB RAM, 100GB SSD
- Recomendado: 8 vCPU, 32GB RAM, 500GB NVMe

**Notas:**
- Community Edition possui todas as funcionalidades necessárias para o projeto
- Requer equipe capaz de operar Docker/K8s e monitorar a instância
- Backup e restore devem ser configurados manualmente

### 3.3 LLM — Llama 3.1 70B ou Qwen 2.5 72B

**Opção primária:**

| Atributo | Valor |
|---|---|
| Modelo | Llama 3.1 70B (Meta) |
| Licença | Llama Community License |
| Qualidade | ~85-90% da qualidade do Claude em tarefas de RAG |
| Ecossistema | Maior ecossistema de tooling e fine-tuning |

**Opção alternativa:**

| Atributo | Valor |
|---|---|
| Modelo | Qwen 2.5 72B (Alibaba) |
| Licença | Apache 2.0 |
| Qualidade | Comparável ao Llama, com vantagem em multilíngue |
| Recomendação | Migrar para Qwen se desempenho em português não for satisfatório com Llama |

**Hosting:**
- Desenvolvimento: Ollama (setup simples, single-node)
- Produção: vLLM (batching otimizado, multi-GPU, métricas)

**Requisitos de hardware (ambos modelos):**
- Quantização: Q4 (4-bit) via GGUF ou AWQ
- GPU: 2x GPU com 24GB VRAM cada (ex: 2x RTX 4090, 2x A5000)
- RAM: 64GB+ sistema
- Storage: 50GB+ para pesos do modelo

**Notas:**
- Modelos de 70B+ são necessários para tarefas complexas (geração de `.beta.md` com front matter, respeito a blocos LOCKED, citação de fontes)
- Modelos menores (7B-13B) foram descartados: falham em geração estruturada
- Quantização Q4 tem variação mínima — mitigar fixando seed e versão exata
- Para Fase 4 simples (respostas curtas), um 13B pode ser fallback

### 3.4 Modelo de Reranking — BGE-Reranker-v2-m3 (BAAI)

| Atributo | Valor |
|---|---|
| Fornecedor | BAAI |
| Modelo | BGE-Reranker-v2-m3 |
| Qualidade | ~90-95% do Cohere Rerank v3 |
| Latência típica | ~100ms para reranking de 50 candidatos em GPU |
| Tipo | Cross-encoder |
| Licença | MIT |

**Requisitos de hardware:**
- Mínimo: 1x GPU com 4GB+ VRAM
- Recomendado: Compartilhar GPU com BGE-M3 (mesma família)

**Notas:**
- Cross-encoder: recebe texto da query e texto do chunk (não embeddings)
- Funciona corretamente independente de qual modelo gerou os embeddings
- Sinergia com BGE-M3: mesma família, mesma GPU pode servir ambos
- No cenário híbrido, o reranker local DEVE ser usado quando chunks restricted/confidential estão presentes no conjunto de candidatos

## 4. Tabela Consolidada — Visão Comparativa

| Componente | Trilha A (Cloud) | Trilha B (On-Premise) |
|---|---|---|
| **Embedding** | OpenAI text-embedding-3-small, 1536d, US$ 0,02/1M tokens, ~100ms/100 chunks | BGE-M3 (BAAI), 1024d, GPU 8GB+ VRAM (custo zero/token) |
| **Base Vetorial** | Managed Cloud (DBaaS), ~US$ 65+/mês, SLA 99,9% | Self-hosted Docker, Community Edition (grátis), 4 vCPU, 16GB+ RAM, 100GB SSD |
| **LLM** | Claude (Anthropic), Sonnet/Opus, 200K tokens contexto | Llama 3.1 70B ou Qwen 2.5 72B, 2x GPU 24GB VRAM, Ollama (dev) / vLLM (prod) |
| **Reranking** | Cohere Rerank v3, US$ 2,00/1K buscas, ~150ms/50 candidatos | BGE-Reranker-v2-m3, GPU 4GB+ VRAM, ~100ms/50 candidatos |

## 5. Incompatibilidades e Restrições

### 5.1 Embeddings incompatíveis entre trilhas

Os vetores gerados pela OpenAI (1536d) e pelo BGE-M3 (1024d) NÃO são compatíveis. Um chunk indexado com OpenAI só pode ser buscado com embedding de query gerado pela OpenAI. Isso reforça a necessidade de duas instâncias separadas da base vetorial na Trilha Híbrida.

### 5.2 Regra do componente mais restritivo

Quando resultados de ambas as instâncias são mesclados (busca cross-instância), o reranking e a geração de resposta DEVEM usar componentes on-premise, pois chunks restricted/confidential estão presentes no conjunto.

**Regra:** o componente mais restritivo determina a trilha para reranking e LLM.

### 5.3 Cross-encoder é agnóstico a embeddings

O BGE-Reranker-v2-m3 é um cross-encoder — recebe texto da query e texto do chunk, NÃO os embeddings. Portanto, funciona corretamente para reranking de chunks vindos de qualquer modelo de embedding.

## 6. Referências

- [[ADR-002]] — Soberania de Dados: Cloud vs On-Premise (decisão macro)
- [[ADR-001]] — Pipeline de Geração de Conhecimento em 4 Fases
- [[ADR-003]] — Modelo de Dados da Base Vetorial
- OpenAI Embeddings: <https://platform.openai.com/docs/guides/embeddings>
- BGE-M3 (BAAI): <https://huggingface.co/BAAI/bge-m3>
- BGE-Reranker-v2-m3: <https://huggingface.co/BAAI/bge-reranker-v2-m3>
- Cohere Rerank: <https://docs.cohere.com/docs/rerank-2>
- Ollama: <https://ollama.ai>
- vLLM: <https://github.com/vllm-project/vllm>

<!-- conversion_quality: 95 -->
