---
id: ADR-D03
doc_type: adr
title: "Capacity Planning e Dimensionamento de Infraestrutura"
system: RAG Corporativo
module: Capacity Planning
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - capacity planning
  - dimensionamento infraestrutura
  - custo mensal cloud
  - custo opex on premise
  - capex investimento
  - break even análise
  - projeção crescimento
  - trilha cloud custos
  - trilha on premise custos
  - trilha híbrida custos
  - cenário pequeno
  - cenário médio
  - cenário grande
  - cenário crítico
  - openai pricing
  - anthropic pricing
  - cohere pricing
  - dbaas custo instância
  - embedding indexação custo
  - embedding query custo
  - llm respostas custo
  - reranking custo
  - gpu rtx 4090
  - servidor dedicado
  - energia elétrica
  - operação fte
  - community edition
  - open source custo zero
  - hardware especificação
  - cpu cores ram
  - nvme storage
  - fonte alimentação
  - refrigeração térmica
  - throughput llm
  - batching vllm
  - requests simultâneos
  - embedding throughput
  - reranking throughput
  - gatilho escala
  - vram limite
  - disco livre
  - temperatura gpu
  - rate limiting provedor
  - latência rede
  - soberania dados
  - migração trilha
  - regulatório mudança
  - air gapped ambiente
  - logs imutáveis
  - criptografia at rest
  - caching otimização
  - redução contexto
  - amortização capex
  - duas instâncias base vetorial
  - cross instância retriever
  - merge resultados
  - controle acesso usuário
  - escalabilidade horizontal
  - escalabilidade vertical
aliases:
  - "ADR-D03"
  - "Capacity Planning Infra"
  - "Dimensionamento de Infraestrutura"
  - "Capacity Planning Infraestrutura RAG"
  - "Planejamento de Capacidade"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/beta/ADR-D03_capacity_planning_infraestrutura.beta.md"
source_beta_ids:
  - "BETA-D03"
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

# ADR-D03 — Capacity Planning e Dimensionamento de Infraestrutura

| Campo       | Valor                                                         |
|-------------|---------------------------------------------------------------|
| **Status**  | Accepted                                                      |
| **Data**    | 23/03/2026                                                    |
| **Decisor** | fabio (arquitetura)                                           |
| **Escopo**  | Planejamento de capacidade e dimensionamento de infraestrutura para o pipeline RAG, cobrindo custos, hardware e gatilhos de escalabilidade |

**Referências cruzadas:**

- [[ADR-002]]: Soberania de Dados — Cloud vs On-Premise (seção Custos)
- [[ADR-001]]: Pipeline de Geração de Conhecimento em 4 Fases
- [[ADR-D04]]: Checklist de Deploy por Trilha

## Introdução

Este documento consolida o planejamento de capacidade e dimensionamento de infraestrutura para o pipeline RAG, conforme definido na [[ADR-002]]. Cobre custos, hardware, limites e gatilhos de escalabilidade para as três configurações possíveis: Trilha A (Cloud), Trilha B (On-Premise) e Trilha Híbrida.

**Cenário de referência utilizado nos cálculos:**
- 10.000 documentos Markdown
- Média de 5 chunks por documento = 50.000 chunks total
- 50 usuários ativos
- 20 buscas por usuário por dia útil
- 22 dias úteis por mês
- Total de queries/mês: 50 x 20 x 22 = 22.000 queries/mês

## Trilha A (Cloud) — Dimensionamento e Custos

### Custo Mensal Detalhado

| Componente | Custo | Cálculo |
|---|---|---|
| Embedding (indexação) | ~$0,50 | 25M tokens x $0,02/1M (única vez, amortizado no primeiro mês) |
| Embedding (query) | ~$2,00 | 22K queries x ~100 tokens/query x $0,02/1M tokens |
| Base Vetorial (DBaaS) | ~$65,00 | Instância básica managed |
| LLM — respostas (Claude) | ~$150,00 | 22K queries x ~2K tokens output x preço/token Sonnet |
| Reranking (Cohere) | ~$44,00 | 22K buscas x $2,00/1K buscas |
| **TOTAL MENSAL** | **~$261,50** | |

### Projeção de Crescimento — Trilha A

O custo da Trilha A escala linearmente com volume de queries e documentos.

| Cenário | 10K docs / 50 users | 25K docs / 100 users | 50K docs / 200 users | 100K docs / 500 users |
|---|---|---|---|---|
| Embedding idx | $0,50 | $1,25 | $2,50 | $5,00 |
| Embedding qry | $2,00 | $8,00 | $32,00 | $200,00 |
| Base Vetorial | $65,00 | $130,00 | $250,00 | $500,00 |
| LLM | $150,00 | $600,00 | $2.400 | $15.000 |
| Reranking | $44,00 | $176,00 | $704,00 | $4.400 |
| **TOTAL/mês** | **~$262** | **~$915** | **~$3.389** | **~$20.105** |

> **Nota:** o LLM é o componente que mais escala. Otimizações como caching de respostas frequentes e redução de tokens de contexto podem reduzir em até 40% o custo de LLM.

### Limites da Trilha A

- Rate limits por provedor (TPM, RPM) — consultar tier contratado
- Latência mínima limitada pela rede até a API (~50-200ms por hop)
- Dependência de disponibilidade de terceiros
- Dados restricted/confidential NÃO podem usar esta trilha

## Trilha B (On-Premise) — Dimensionamento e Custos

### Investimento Inicial (CAPEX)

| Item | Custo | Especificação |
|---|---|---|
| GPU para LLM (2x) | ~$3.000 | 2x RTX 4090 24GB VRAM (ou 2x A5000 24GB) |
| Servidor | ~$2.000 | 64GB RAM DDR5, CPU 8+ cores, NVMe 1TB, fonte 1000W+ |
| GPU para embedding/reranker | (inclusa) | Compartilha com LLM ou usa GPU existente (8GB+ VRAM) |
| Rede/switch | ~$200 | Rede interna, sem saída para internet (air-gapped) |
| **TOTAL CAPEX** | **~$5.200** | |

### Custo Operacional Mensal (OPEX)

| Item | Custo | Cálculo |
|---|---|---|
| Energia elétrica | ~$50 | ~500W médio x 24/7 x tarifa industrial |
| Operação (fração de FTE) | ~$500 | Fração do tempo de equipe de infra/ops |
| Base Vetorial | $0 | Community Edition |
| Modelos (embedding, LLM, rr) | $0 | Open-source, sem licença |
| **TOTAL OPEX/mês** | **~$550** | |

### Análise de Break-Even (Trilha B vs Trilha A)

**Premissas:**
- Trilha A: ~$262/mês (cenário referência)
- Trilha B: ~$5.200 CAPEX + ~$550/mês OPEX

**Cálculo simplificado:**

| Mês | Trilha A (acumulado) | Trilha B (acumulado) |
|---|---|---|
| Mês 1 | $262 | $5.750 |
| Mês 6 | $1.572 | $8.500 |
| Mês 12 | $3.144 | $11.800 |
| Mês 18 | $4.716 | $15.100 |
| Mês 24 | $6.288 | $18.400 |

No cenário referência (10K docs, 50 users), Trilha A permanece mais barata. O break-even só ocorre em cenários maiores:

- 25K docs, 100 users: break-even ~12 meses
- 50K docs, 200 users: break-even ~3 meses
- 100K docs, 500 users: break-even ~1 mês

> **IMPORTANTE:** o custo NÃO é a razão de escolha da Trilha B. A razão é soberania de dados. Organizações que precisam da Trilha B não têm opção de usar a Trilha A para dados restritos.

### Requisitos de Hardware — Detalhamento

**SERVIDOR PRINCIPAL (LLM + Embedding + Reranker):**

| Componente | Especificação |
|---|---|
| CPU | 8+ cores (AMD Ryzen 9 / Intel i9 ou Xeon equivalente) |
| RAM | 64GB DDR5 (mínimo) — 128GB recomendado para cenários > 50K docs |
| GPU 1 | RTX 4090 24GB (LLM — primeira GPU) |
| GPU 2 | RTX 4090 24GB (LLM — segunda GPU, para modelo 70B Q4) |
| Storage | NVMe 1TB (SO + modelos + cache) |
| Fonte | 1000W+ (80+ Gold) — duas GPUs de alto consumo |
| Refrigeração | Adequada para carga térmica de ~500W contínua |

> **Nota:** BGE-M3 e BGE-Reranker podem compartilhar uma das GPUs com o LLM via time-sharing, ou usar GPU dedicada menor (RTX 3060 8GB).

**SERVIDOR DA BASE VETORIAL (pode ser o mesmo ou separado):**

| Componente | Mínimo | Recomendado |
|---|---|---|
| CPU | 4+ vCPU | 8+ vCPU |
| RAM | 16GB | 32GB |
| Storage | 100GB SSD | 500GB NVMe |

> **Nota:** para cenários > 100K chunks, recomenda-se servidor separado para a base vetorial.

### Limites e Escalabilidade — Trilha B

**Limites de GPU (modelo 70B Q4 em 2x RTX 4090):**
- Throughput LLM: ~15-25 tokens/s (single user)
- Com batching (vLLM): ~50-100 tokens/s agregado
- Máximo de requests simultâneos: ~5-10 (com batching)

**Limites de embedding (BGE-M3 em GPU 16GB):**
- Throughput: ~50-100 chunks/s
- Indexação de 50K chunks: ~8-16 minutos

**Limites de reranking (BGE-Reranker em GPU 8GB):**
- Throughput: ~200-500 pares/s
- 50 candidatos por query: ~100ms

**Gatilhos de escalabilidade:**
- Throughput LLM < 10 tokens/s sustentado → adicionar GPU ou migrar para modelo menor como fallback
- Fila de requests > 20 pendentes → escalar horizontalmente (segundo servidor com vLLM)
- VRAM > 90% → não é possível carregar modelos maiores; considerar quantização mais agressiva ou upgrade de GPU
- Disco < 20% livre → expandir storage ou arquivar logs antigos

## Trilha Híbrida — Dimensionamento Combinado

### Infraestrutura Necessária

A Trilha Híbrida requer TODA a infraestrutura da Trilha B mais os serviços cloud da Trilha A. Na prática:

**Cloud (Trilha A):**
- Contas ativas: OpenAI, Anthropic, Cohere
- Base vetorial managed (instância para dados public/internal)

**On-Premise (Trilha B):**
- Servidor com GPU(s) conforme seção de requisitos de hardware
- Base vetorial self-hosted (instância para dados restricted/confidential)

**Adicional (Híbrido):**
- Retriever cross-instância (executa busca em paralelo nas duas bases)
- Merge de resultados antes do reranking
- Controle de acesso por usuário (quem pode ver resultados de qual nível)

### Custo Mensal Combinado

| Componente | Custo |
|---|---|
| Trilha A (cloud) | ~$262/mês |
| Trilha B (on-premise OPEX) | ~$550/mês |
| CAPEX amortizado (36 meses) | ~$144/mês |
| **TOTAL MENSAL COMBINADO** | **~$956/mês** |

> **Nota:** o custo híbrido não é a soma simples porque parte dos documentos vai para cada trilha. Se 70% dos docs são public/internal e 30% são restricted/confidential, o custo de LLM na Trilha A reduz proporcionalmente.

### Duas Instâncias da Base Vetorial

A Trilha Híbrida opera DUAS instâncias separadas:

**Instância Cloud:**
- Dados: chunks de documentos public e internal
- Embeddings: OpenAI 1536 dimensões
- Localização: managed cloud

**Instância On-Premise:**
- Dados: chunks de documentos restricted e confidential
- Embeddings: BGE-M3 1024 dimensões
- Localização: servidor local

Os embeddings são INCOMPATÍVEIS entre si. Busca cross-instância executa queries em paralelo e faz merge textual antes do reranking.

## Cenários de Dimensionamento

### Cenário Pequeno (startup, equipe técnica)

- **Docs:** 1.000-5.000
- **Usuários:** 10-20
- **Confidencialidade:** 100% public/internal
- **Recomendação:** Trilha A apenas
- **Custo estimado:** ~$100-180/mês
- **Hardware:** nenhum (tudo cloud)

### Cenário Médio (empresa média, dados mistos)

- **Docs:** 5.000-25.000
- **Usuários:** 20-100
- **Confidencialidade:** ~70% public/internal, ~30% restricted
- **Recomendação:** Trilha Híbrida
- **Custo estimado:** ~$500-1.500/mês + CAPEX ~$5.000
- **Hardware:** 1 servidor com 2 GPUs

### Cenário Grande (corporação, regulado)

- **Docs:** 25.000-100.000
- **Usuários:** 100-500
- **Confidencialidade:** >50% restricted/confidential
- **Recomendação:** Trilha B predominante (ou 100% on-premise)
- **Custo estimado:** ~$2.000-5.000/mês OPEX + CAPEX ~$15.000-30.000
- **Hardware:** 2-4 servidores, 4-8 GPUs, cluster de base vetorial

### Cenário Crítico (governo, defesa, saúde)

- **Docs:** qualquer volume
- **Usuários:** qualquer número
- **Confidencialidade:** 100% confidential
- **Recomendação:** Trilha B apenas, air-gapped
- **Custo estimado:** variável (infra dedicada)
- **Hardware:** infra isolada, sem conexão externa, certificada
- **Requisitos adicionais:** auditoria, logs imutáveis, criptografia at-rest

## Gatilhos de Escala e Decisão

### Quando escalar Trilha A

- Custo mensal > budget aprovado → otimizar (caching, redução de contexto) ou migrar parte para Trilha B
- Rate limiting frequente (> 5%) → upgrade de tier no provedor
- Latência p95 > 5s → verificar provedor, considerar região mais próxima

### Quando escalar Trilha B

- Throughput LLM insuficiente → adicionar GPUs ou segundo servidor vLLM
- VRAM > 90% → upgrade GPU ou quantização mais agressiva
- Disco < 20% → expandir NVMe ou migrar para storage externo
- Temperatura GPU > 85°C → melhorar refrigeração ou reduzir carga

### Quando migrar de Trilha A para Trilha B

- Mudança regulatória que reclassifica dados como restricted
- Custo cloud excede OPEX on-premise + CAPEX amortizado
- Requisito de latência que API externa não atende
- Decisão estratégica de soberania de dados

### Quando migrar de Trilha B para Trilha A

- Reclassificação de dados para public/internal
- Hardware on-premise obsoleto e sem orçamento para renovação
- Equipe de infra indisponível para operar modelos locais

## Referências

- [[ADR-002]]: Soberania de Dados — Cloud vs On-Premise (seção Custos)
- [[ADR-001]]: Pipeline de Geração de Conhecimento em 4 Fases
- OpenAI Pricing: <https://openai.com/pricing>
- Anthropic Pricing: <https://anthropic.com/pricing>
- Cohere Pricing: <https://cohere.com/pricing>
- Ollama: <https://ollama.ai>
- vLLM: <https://github.com/vllm-project/vllm>

<!-- conversion_quality: 95 -->
