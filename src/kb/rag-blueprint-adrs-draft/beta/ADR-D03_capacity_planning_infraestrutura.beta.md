---
id: BETA-D03
title: "Capacity Planning e Dimensionamento de Infraestrutura"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-D03_capacity_planning_infraestrutura.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags:
  - capacity planning
  - dimensionamento infraestrutura
  - custo mensal cloud
  - custo opex on-premise
  - capex investimento
  - break-even analise
  - projecao crescimento
  - trilha cloud custos
  - trilha on-premise custos
  - trilha hibrida custos
  - cenario pequeno
  - cenario medio
  - cenario grande
  - cenario critico
  - openai pricing
  - anthropic pricing
  - cohere pricing
  - dbaas custo instancia
  - embedding indexacao custo
  - embedding query custo
  - llm respostas custo
  - reranking custo
  - gpu rtx 4090
  - servidor dedicado
  - energia eletrica
  - operacao fte
  - community edition
  - open source custo zero
  - hardware especificacao
  - cpu cores ram
  - nvme storage
  - fonte alimentacao
  - refrigeracao termica
  - throughput llm
  - batching vllm
  - requests simultaneos
  - embedding throughput
  - reranking throughput
  - gatilho escala
  - vram limite
  - disco livre
  - temperatura gpu
  - rate limiting provedor
  - latencia rede
  - soberania dados
  - migracao trilha
  - regulatorio mudanca
  - air-gapped ambiente
  - logs imutaveis
  - criptografia at-rest
  - caching otimizacao
  - reducao contexto
  - amortizacao capex
  - duas instancias base vetorial
  - cross-instancia retriever
  - merge resultados
  - controle acesso usuario
  - escalabilidade horizontal
  - escalabilidade vertical
aliases:
  - "ADR-D03"
  - "Capacity Planning Infra"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## 1. Introducao

Este documento consolida o planejamento de capacidade e dimensionamento de infraestrutura para o pipeline RAG, conforme definido na ADR-002. Cobre custos, hardware, limites e gatilhos de escalabilidade para as tres configuracoes possiveis: Trilha A (Cloud), Trilha B (On-Premise) e Trilha Hibrida.

**Cenario de referencia utilizado nos calculos:**
- 10.000 documentos Markdown
- Media de 5 chunks por documento = 50.000 chunks total
- 50 usuarios ativos
- 20 buscas por usuario por dia util
- 22 dias uteis por mes
- Total de queries/mes: 50 x 20 x 22 = 22.000 queries/mes

## 2. Trilha A (Cloud) — Dimensionamento e Custos

### 2.1 Custo Mensal Detalhado

| Componente | Custo | Calculo |
|---|---|---|
| Embedding (indexacao) | ~$0,50 | 25M tokens x $0,02/1M (unica vez, amortizado no primeiro mes) |
| Embedding (query) | ~$2,00 | 22K queries x ~100 tokens/query x $0,02/1M tokens |
| Base Vetorial (DBaaS) | ~$65,00 | Instancia basica managed |
| LLM — respostas (Claude) | ~$150,00 | 22K queries x ~2K tokens output x preco/token Sonnet |
| Reranking (Cohere) | ~$44,00 | 22K buscas x $2,00/1K buscas |
| **TOTAL MENSAL** | **~$261,50** | |

### 2.2 Projecao de Crescimento — Trilha A

O custo da Trilha A escala linearmente com volume de queries e documentos.

| Cenario | 10K docs / 50 users | 25K docs / 100 users | 50K docs / 200 users | 100K docs / 500 users |
|---|---|---|---|---|
| Embedding idx | $0,50 | $1,25 | $2,50 | $5,00 |
| Embedding qry | $2,00 | $8,00 | $32,00 | $200,00 |
| Base Vetorial | $65,00 | $130,00 | $250,00 | $500,00 |
| LLM | $150,00 | $600,00 | $2.400 | $15.000 |
| Reranking | $44,00 | $176,00 | $704,00 | $4.400 |
| **TOTAL/mes** | **~$262** | **~$915** | **~$3.389** | **~$20.105** |

> **Nota:** o LLM e o componente que mais escala. Otimizacoes como caching de respostas frequentes e reducao de tokens de contexto podem reduzir em ate 40% o custo de LLM.

### 2.3 Limites da Trilha A

- Rate limits por provedor (TPM, RPM) — consultar tier contratado
- Latencia minima limitada pela rede ate a API (~50-200ms por hop)
- Dependencia de disponibilidade de terceiros
- Dados restricted/confidential NAO podem usar esta trilha

## 3. Trilha B (On-Premise) — Dimensionamento e Custos

### 3.1 Investimento Inicial (CAPEX)

| Item | Custo | Especificacao |
|---|---|---|
| GPU para LLM (2x) | ~$3.000 | 2x RTX 4090 24GB VRAM (ou 2x A5000 24GB) |
| Servidor | ~$2.000 | 64GB RAM DDR5, CPU 8+ cores, NVMe 1TB, fonte 1000W+ |
| GPU para embedding/reranker | (inclusa) | Compartilha com LLM ou usa GPU existente (8GB+ VRAM) |
| Rede/switch | ~$200 | Rede interna, sem saida para internet (air-gapped) |
| **TOTAL CAPEX** | **~$5.200** | |

### 3.2 Custo Operacional Mensal (OPEX)

| Item | Custo | Calculo |
|---|---|---|
| Energia eletrica | ~$50 | ~500W medio x 24/7 x tarifa industrial |
| Operacao (fracao de FTE) | ~$500 | Fracao do tempo de equipe de infra/ops |
| Base Vetorial | $0 | Community Edition |
| Modelos (embedding, LLM, rr) | $0 | Open-source, sem licenca |
| **TOTAL OPEX/mes** | **~$550** | |

### 3.3 Analise de Break-Even (Trilha B vs Trilha A)

**Premissas:**
- Trilha A: ~$262/mes (cenario referencia)
- Trilha B: ~$5.200 CAPEX + ~$550/mes OPEX

**Calculo simplificado:**

| Mes | Trilha A (acumulado) | Trilha B (acumulado) |
|---|---|---|
| Mes 1 | $262 | $5.750 |
| Mes 6 | $1.572 | $8.500 |
| Mes 12 | $3.144 | $11.800 |
| Mes 18 | $4.716 | $15.100 |
| Mes 24 | $6.288 | $18.400 |

No cenario referencia (10K docs, 50 users), Trilha A permanece mais barata. O break-even so ocorre em cenarios maiores:

- 25K docs, 100 users: break-even ~12 meses
- 50K docs, 200 users: break-even ~3 meses
- 100K docs, 500 users: break-even ~1 mes

> **IMPORTANTE:** o custo NAO e a razao de escolha da Trilha B. A razao e soberania de dados. Organizacoes que precisam da Trilha B nao tem opcao de usar a Trilha A para dados restritos.

### 3.4 Requisitos de Hardware — Detalhamento

**SERVIDOR PRINCIPAL (LLM + Embedding + Reranker):**

| Componente | Especificacao |
|---|---|
| CPU | 8+ cores (AMD Ryzen 9 / Intel i9 ou Xeon equivalente) |
| RAM | 64GB DDR5 (minimo) — 128GB recomendado para cenarios > 50K docs |
| GPU 1 | RTX 4090 24GB (LLM — primeira GPU) |
| GPU 2 | RTX 4090 24GB (LLM — segunda GPU, para modelo 70B Q4) |
| Storage | NVMe 1TB (SO + modelos + cache) |
| Fonte | 1000W+ (80+ Gold) — duas GPUs de alto consumo |
| Refrigeracao | Adequada para carga termica de ~500W continua |

> **Nota:** BGE-M3 e BGE-Reranker podem compartilhar uma das GPUs com o LLM via time-sharing, ou usar GPU dedicada menor (RTX 3060 8GB).

**SERVIDOR DA BASE VETORIAL (pode ser o mesmo ou separado):**

| Componente | Minimo | Recomendado |
|---|---|---|
| CPU | 4+ vCPU | 8+ vCPU |
| RAM | 16GB | 32GB |
| Storage | 100GB SSD | 500GB NVMe |

> **Nota:** para cenarios > 100K chunks, recomenda-se servidor separado para a base vetorial.

### 3.5 Limites e Escalabilidade — Trilha B

**Limites de GPU (modelo 70B Q4 em 2x RTX 4090):**
- Throughput LLM: ~15-25 tokens/s (single user)
- Com batching (vLLM): ~50-100 tokens/s agregado
- Maximo de requests simultaneos: ~5-10 (com batching)

**Limites de embedding (BGE-M3 em GPU 16GB):**
- Throughput: ~50-100 chunks/s
- Indexacao de 50K chunks: ~8-16 minutos

**Limites de reranking (BGE-Reranker em GPU 8GB):**
- Throughput: ~200-500 pares/s
- 50 candidatos por query: ~100ms

**Gatilhos de escalabilidade:**
- Throughput LLM < 10 tokens/s sustentado -> adicionar GPU ou migrar para modelo menor como fallback
- Fila de requests > 20 pendentes -> escalar horizontalmente (segundo servidor com vLLM)
- VRAM > 90% -> nao e possivel carregar modelos maiores; considerar quantizacao mais agressiva ou upgrade de GPU
- Disco < 20% livre -> expandir storage ou arquivar logs antigos

## 4. Trilha Hibrida — Dimensionamento Combinado

### 4.1 Infraestrutura Necessaria

A Trilha Hibrida requer TODA a infraestrutura da Trilha B mais os servicos cloud da Trilha A. Na pratica:

**Cloud (Trilha A):**
- Contas ativas: OpenAI, Anthropic, Cohere
- Base vetorial managed (instancia para dados public/internal)

**On-Premise (Trilha B):**
- Servidor com GPU(s) conforme secao 3.4
- Base vetorial self-hosted (instancia para dados restricted/confidential)

**Adicional (Hibrido):**
- Retriever cross-instancia (executa busca em paralelo nas duas bases)
- Merge de resultados antes do reranking
- Controle de acesso por usuario (quem pode ver resultados de qual nivel)

### 4.2 Custo Mensal Combinado

| Componente | Custo |
|---|---|
| Trilha A (cloud) | ~$262/mes |
| Trilha B (on-premise OPEX) | ~$550/mes |
| CAPEX amortizado (36 meses) | ~$144/mes |
| **TOTAL MENSAL COMBINADO** | **~$956/mes** |

> **Nota:** o custo hibrido nao e a soma simples porque parte dos documentos vai para cada trilha. Se 70% dos docs sao public/internal e 30% sao restricted/confidential, o custo de LLM na Trilha A reduz proporcionalmente.

### 4.3 Duas Instancias da Base Vetorial

A Trilha Hibrida opera DUAS instancias separadas:

**Instancia Cloud:**
- Dados: chunks de documentos public e internal
- Embeddings: OpenAI 1536 dimensoes
- Localizacao: managed cloud

**Instancia On-Premise:**
- Dados: chunks de documentos restricted e confidential
- Embeddings: BGE-M3 1024 dimensoes
- Localizacao: servidor local

Os embeddings sao INCOMPATIVEIS entre si. Busca cross-instancia executa queries em paralelo e faz merge textual antes do reranking.

## 5. Cenarios de Dimensionamento

### 5.1 Cenario Pequeno (startup, equipe tecnica)

- **Docs:** 1.000-5.000
- **Usuarios:** 10-20
- **Confidencialidade:** 100% public/internal
- **Recomendacao:** Trilha A apenas
- **Custo estimado:** ~$100-180/mes
- **Hardware:** nenhum (tudo cloud)

### 5.2 Cenario Medio (empresa media, dados mistos)

- **Docs:** 5.000-25.000
- **Usuarios:** 20-100
- **Confidencialidade:** ~70% public/internal, ~30% restricted
- **Recomendacao:** Trilha Hibrida
- **Custo estimado:** ~$500-1.500/mes + CAPEX ~$5.000
- **Hardware:** 1 servidor com 2 GPUs

### 5.3 Cenario Grande (corporacao, regulado)

- **Docs:** 25.000-100.000
- **Usuarios:** 100-500
- **Confidencialidade:** >50% restricted/confidential
- **Recomendacao:** Trilha B predominante (ou 100% on-premise)
- **Custo estimado:** ~$2.000-5.000/mes OPEX + CAPEX ~$15.000-30.000
- **Hardware:** 2-4 servidores, 4-8 GPUs, cluster de base vetorial

### 5.4 Cenario Critico (governo, defesa, saude)

- **Docs:** qualquer volume
- **Usuarios:** qualquer numero
- **Confidencialidade:** 100% confidential
- **Recomendacao:** Trilha B apenas, air-gapped
- **Custo estimado:** variavel (infra dedicada)
- **Hardware:** infra isolada, sem conexao externa, certificada
- **Requisitos adicionais:** auditoria, logs imutaveis, criptografia at-rest

## 6. Gatilhos de Escala e Decisao

### 6.1 Quando escalar Trilha A

- Custo mensal > budget aprovado -> otimizar (caching, reducao de contexto) ou migrar parte para Trilha B
- Rate limiting frequente (> 5%) -> upgrade de tier no provedor
- Latencia p95 > 5s -> verificar provedor, considerar regiao mais proxima

### 6.2 Quando escalar Trilha B

- Throughput LLM insuficiente -> adicionar GPUs ou segundo servidor vLLM
- VRAM > 90% -> upgrade GPU ou quantizacao mais agressiva
- Disco < 20% -> expandir NVMe ou migrar para storage externo
- Temperatura GPU > 85C -> melhorar refrigeracao ou reduzir carga

### 6.3 Quando migrar de Trilha A para Trilha B

- Mudanca regulatoria que reclassifica dados como restricted
- Custo cloud excede OPEX on-premise + CAPEX amortizado
- Requisito de latencia que API externa nao atende
- Decisao estrategica de soberania de dados

### 6.4 Quando migrar de Trilha B para Trilha A

- Reclassificacao de dados para public/internal
- Hardware on-premise obsoleto e sem orcamento para renovacao
- Equipe de infra indisponivel para operar modelos locais

## 7. Referencias

- ADR-002: Soberania de Dados — Cloud vs On-Premise (secao Custos)
- ADR-001: Pipeline de Geracao de Conhecimento em 4 Fases
- OpenAI Pricing: <https://openai.com/pricing>
- Anthropic Pricing: <https://anthropic.com/pricing>
- Cohere Pricing: <https://cohere.com/pricing>
- Ollama: <https://ollama.ai>
- vLLM: <https://github.com/vllm-project/vllm>

<!-- conversion_quality: 95 -->
