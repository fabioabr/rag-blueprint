---
id: ADR-G02
doc_type: adr
title: "Pipeline de Processamento de Query"
system: RAG Corporativo
module: Pipeline de Query
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - pipeline de query
  - processamento de query
  - classificacao de intencao
  - dispatcher
  - filtro de seguranca
  - pre retrieval
  - query rewriting
  - reformulacao
  - query expansion
  - expansao de sinonimos
  - query decomposition
  - decomposicao
  - busca paralela
  - vector search
  - keyword search
  - graph search
  - reciprocal rank fusion
  - rrf
  - reranking
  - cross encoder
  - montagem de contexto
  - llm
  - prompt
  - bm25
  - hnsw
  - bge m3
  - cohere rerank
  - bge reranker
  - ndcg
  - recall
  - latencia
  - metricas
  - few shot
  - glossary term
  - sinonimos
  - stemming
  - filtragem temporal
  - confidencialidade
  - agente especializado
  - architecture agent
  - operations agent
  - business agent
  - fallback
  - cache
  - dual track
  - cloud
  - on premises
  - bi encoder
  - negacoes
  - parafrase
  - etapas do pipeline de query
  - fusao de resultados
aliases:
  - "ADR-G02"
  - "Pipeline de Query"
  - "Processamento de Query"
  - "Pipeline de Retrieval"
  - "Fluxo de Query do RAG"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/draft/ADR-G02_pipeline_query.txt"
source_beta_ids:
  - "BETA-G02"
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

# ADR-G02 — Pipeline de Processamento de Query

| Campo | Valor |
|-------|-------|
| **Status** | Accepted |
| **Data da Decisão** | 2026-03-23 |
| **Decisor** | fabio |
| **Escopo** | Pipeline de Query |

**Referências Cruzadas:**

- **Depende de:** [[ADR-007]]
- **Relaciona-se:** [[ADR-009]], [[ADR-002]], [[ADR-004]], [[ADR-G01]], [[ADR-G03]]

## Objetivo

Especificar o pipeline completo de processamento de uma query desde a entrada do usuário até a montagem do contexto final para o LLM. Cada etapa é detalhada com seu mecanismo, parâmetros, critérios de ativação e métricas.

## Visão Geral do Pipeline

A query do usuário percorre as seguintes etapas em sequência:

```
[Query do usuário]
     |
(1) Classificação de intenção (Dispatcher)
     |
(2) Filtro de segurança pré-retrieval
     |
(3) Query Rewriting (reformulação)
     |
(4) Query Expansion (expansão de sinônimos)
     |
(5) Query Decomposition (decomposição, se complexa)
     |
(6) 3 Buscas Paralelas (vetor + keyword + grafo)
     |
(7) Fusão via RRF (Reciprocal Rank Fusion)
     |
(8) Reranking (cross-encoder)
     |
(9) Montagem de contexto para o LLM
     |
[Resposta ao usuário]
```

## Etapa 1 — Classificação de Intenção (Dispatcher)

### 1.1 Mecanismo

Um LLM leve classifica a intenção da query para direcionar ao agente especializado correto. A classificação usa few-shot examples.

### 1.2 Categorias de Intenção

| Intenção | Agente destino | Exemplos |
|---|---|---|
| architecture | Architecture Agent | "Qual ADR decidiu sobre o banco?" |
| operations | Operations Agent | "Como fazer deploy do módulo X?" |
| business | Business Agent | "Quem é responsável pela cobrança?" |
| ambiguous | Fallback (todos) | "Me fale sobre o sistema SAP" |

### 1.3 Parâmetros

- Modelo: LLM leve (ex: GPT-4o-mini ou Llama 3.1 8B local)
- Latência alvo: < 100ms
- Cache: 5 minutos para queries idênticas
- Confidence threshold: se confiança < 0.7, classificar como "ambiguous"

### 1.4 Fallback (ambiguous)

Quando a intenção é ambígua:
- Acionar TODOS os agentes em paralelo
- Cada agente retorna seus top-K resultados
- Resultados de todos os agentes são fundidos via RRF adicional
- Custo: ~3x latência (aceitável para queries ambíguas)

## Etapa 2 — Filtro de Segurança Pré-Retrieval

### 2.1 Mecanismo

ANTES de qualquer busca, o sistema aplica filtros de confidencialidade baseados no perfil do usuário autenticado.

### 2.2 Regras

- Determinar nível máximo de acesso do usuário
- Construir cláusula de filtro: confidentiality IN [níveis_permitidos]
- Aplicar filtro em TODAS as 3 buscas subsequentes
- Se filtro falhar: retornar ZERO resultados (fail-closed)

### 2.3 Níveis

- **public** -> todos
- **internal** -> usuários autenticados
- **restricted** -> usuários com role "restricted" OU membros do team owner
- **confidential** -> usuários explicitamente no access_list

### 2.4 Auditoria

Toda query é logada com:
- user_id
- níveis solicitados e efetivamente aplicados
- quantidade de chunks filtrados (removidos por segurança)
- timestamp

## Etapa 3 — Query Rewriting (Reformulação)

### 3.1 Mecanismo

Reformula queries vagas ou mal formuladas em versões mais precisas e buscáveis. Duas abordagens complementares:

**Abordagem 1 — Regras (sempre executa primeiro):**
- Expandir siglas conhecidas do glossário (ex: "BACEN" -> "Banco Central do Brasil (BACEN)")
- Adicionar sinônimos do GlossaryTerm (ex: "boleto" + "título de cobrança")
- Latência: < 10ms
- Cobertura: resolve >70% das queries

**Abordagem 2 — LLM (acionado sob demanda):**
- Ativado quando resultados da busca com regras são insuficientes (< 3 resultados com score > 0.5)
- Track A (Cloud): GPT-4o-mini ou equivalente (< 200ms)
- Track B (On-prem): Llama 3.1 8B ou Qwen via Ollama
- Timeout: 5 segundos
- Meta: < 30% das queries precisam de LLM

### 3.2 Preservação

A query ORIGINAL e a query REFORMULADA são ambas usadas nas buscas. Isso evita perda de informação caso o rewriting introduza distorção.

### 3.3 Métricas

- % queries resolvidas por regras (alvo: > 70%)
- % queries com fallback LLM (alvo: < 30%)
- Latência média do rewriting (alvo: < 50ms para regras, < 2s para LLM)
- Recall antes vs depois do rewriting (medir ganho)

## Etapa 4 — Query Expansion (Expansão)

### 4.1 Mecanismo

Gera 2-3 variações da query cobrindo sinônimos e reformulações alternativas para aumentar recall.

Exemplo:
- Query original: "regras de cobrança de boleto"
- Expansões:
  - "política de faturamento e emissão de boletos bancários"
  - "normas para geração de títulos de cobrança"

### 4.2 Implementação

- Fonte primária: GlossaryTerm do grafo (sinônimos controlados)
- Fonte secundária: LLM para gerar paráfrase (se necessário)
- Máximo de expansões: 3 (evitar explosão de buscas)

### 4.3 Uso nas Buscas

Cada expansão é usada como query adicional na busca vetorial. Resultados de todas as expansões são incluídos na fusão RRF.

## Etapa 5 — Query Decomposition (Decomposição)

### 5.1 Mecanismo

Decompõe queries complexas com múltiplas sub-perguntas em sub-queries atômicas que são processadas independentemente.

### 5.2 Critérios de Ativação

A decomposição é ativada quando:
- Query tem > 20 tokens
- Contém "e"/"ou" conectando temas distintos
- Pede informações de naturezas diferentes (ex: "Quem é o responsável pelo módulo X E quais ADRs foram decididas?")

### 5.3 Exemplo

Query: "Quem é o responsável pelo módulo de cobrança e quais dependências ele tem?"
Sub-queries:
1. "Quem é o responsável pelo módulo de cobrança?"
2. "Quais são as dependências do módulo de cobrança?"

Cada sub-query percorre o pipeline de buscas independentemente. Resultados são reunidos na resposta final.

## Etapa 6 — 3 Buscas Paralelas

As 3 buscas executam em PARALELO (não sequencialmente):

### 6.1 Busca Vetorial (Vector Search)

- Gera embedding da query (e expansões) com BGE-M3
- Busca top-20 por similaridade cosseno no índice HNSW
- Filtro de segurança aplicado
- Timeout: 500ms

### 6.2 Busca por Palavra-chave (Keyword Search / BM25)

- Busca full-text no Chunk.content
- Analisador pt-BR (stemming + stopwords)
- Operador OR com boost para AND
- Top-20 resultados, timeout: 500ms

### 6.3 Busca por Grafo (Graph Search)

- Identifica entidades na query
- Navega relações (profundidade 2 hops)
- Coleta chunks dos documentos encontrados
- Max 10 documentos por navegação, timeout: 500ms

### 6.4 Tratamento de Falhas

- Se 1 busca falhar: continuar com as 2 restantes
- Se 2 buscas falharem: continuar com a 1 restante (qualidade degradada)
- Se TODAS falharem: erro explícito ao usuário
- Cada falha logada para observabilidade

## Etapa 7 — Fusão via RRF (Reciprocal Rank Fusion)

### 7.1 Problema

As 3 buscas retornam listas com scores INCOMPATÍVEIS:
- Busca vetorial: cosseno 0.0 a 1.0
- Busca keyword: BM25 0 a infinito
- Busca grafo: sem score numérico (baseado em proximidade relacional)

NÃO é possível comparar ou somar esses scores diretamente.

### 7.2 Solução: RRF

O RRF converte POSIÇÕES EM RANKING em score unificado:

```
score_RRF(d) = SUM( 1 / (k + rank_i(d)) )  para cada busca i
```

Onde:
- d = documento (chunk)
- k = 60 (constante de suavização, paper original de Cormack et al. 2009)
- rank_i(d) = posição do documento na lista da busca i (1 = primeiro)
- Se o documento não aparece na lista i, rank_i(d) = infinito (contribuição zero)

### 7.3 Exemplo

Chunk C-042 aparece:
- Posição 3 na busca vetorial: 1/(60+3) = 0.0159
- Posição 1 na busca keyword: 1/(60+1) = 0.0164
- Não aparece na busca grafo: 0

score_RRF(C-042) = 0.0159 + 0.0164 + 0 = 0.0323

### 7.4 Saída

Lista unificada de chunks ordenados por score_RRF decrescente. Os top ~50 candidatos seguem para a etapa de reranking.

### 7.5 Vantagens do RRF

- Não requer normalização de scores
- Agnóstico ao tipo de busca
- Robusto: funciona com 1, 2 ou 3 listas
- Sem parâmetros de peso (ao contrário de weighted average)

## Etapa 8 — Reranking (Cross-Encoder)

### 8.1 Mecanismo

Um cross-encoder recebe query E chunk como entrada ÚNICA e produz score de relevância com atenção cruzada token a token.

Diferença do embedding (bi-encoder):
- Bi-encoder: gera vetores separados para query e chunk, compara por cosseno
- Cross-encoder: processa query+chunk juntos, captura interações finas

Vantagens do cross-encoder:
- Captura NEGAÇÕES ("não usar boleto" vs "usar boleto")
- Captura CONTEXTO CONDICIONAL ("se o sistema estiver em manutenção")
- Paráfrases PRECISAS
- Qualidade superior ao bi-encoder para ranking fino

### 8.2 Fluxo

Top ~50 candidatos do RRF -> Cross-encoder processa cada par (query, chunk) -> Re-ordena por score de relevância -> Retorna top-K final (K = 5 a 10, configurável)

### 8.3 Dual-Track (conforme [[ADR-002]] e [[ADR-009]])

| Track | Modelo | Custo | Latência |
|---|---|---|---|
| A Cloud | Cohere Rerank v3 | ~$2/1.000 buscas | ~200ms/batch 50 |
| B Local | BGE-Reranker-v2-m3 | Zero | ~500ms GPU, ~2s CPU |

Track B é OBRIGATÓRIO para documentos restricted/confidential. Track A é opcional para documentos public/internal.

### 8.4 Ganho Esperado

O reranking melhora a qualidade do top-K em 10-30% (medido por nDCG@10).

## Etapa 9 — Montagem de Contexto para o LLM

### 9.1 Seleção Final

Os top-K chunks (5-10) após reranking são selecionados para compor o contexto do prompt enviado ao LLM.

### 9.2 Estrutura do Contexto

Para cada chunk incluído:
- Texto do chunk
- Origem: documento, sistema, módulo
- Score de relevância (para transparência)
- Caminho no grafo (se encontrado via Graph Search)

### 9.3 Instruções ao LLM

O prompt inclui instruções para:
- Citar a origem documental de cada afirmação
- Indicar nível de confiança
- Alertar quando informação pode estar desatualizada
- Não inventar informação além do contexto fornecido

### 9.4 Filtragem Temporal

Se a query contém contexto temporal:
- Filtrar chunks por valid_from/valid_until
- Instruir LLM a citar período de vigência
- Mencionar versões anteriores quando existirem
- Alertar sobre documentos próximos de expiração

Se NÃO contém contexto temporal:
- Assumir data atual
- Excluir documentos com status "deprecated"

## Métricas do Pipeline

| Métrica | Alvo |
|---|---|
| Latência end-to-end | < 2 segundos (pipeline completo) |
| Latência dispatcher | < 100ms |
| Latência query rewriting | < 50ms (regras), < 2s (LLM) |
| Latência buscas paralelas | < 500ms (timeout por busca) |
| Latência RRF | < 10ms |
| Latência reranking | < 500ms GPU, < 2s CPU |
| Recall@10 (golden set) | >= 70% (MVP), >= 85% (Prod) |

## Referências

- [[ADR-007]]: Retrieval Híbrido e Agentes Especializados
- [[ADR-009]]: Seleção de Modelos de Embedding (Trilha On-Premises)
- [[ADR-002]]: Soberania de Dados — Trilha Cloud vs. On-Premises
- [[ADR-004]]: Segurança e Classificação de Dados
- Cormack, Clarke, Buettcher (2009). "Reciprocal Rank Fusion outperforms Condorcet and individual Rank Learning Methods"
- Nogueira, Cho (2019). "Passage Re-ranking with BERT"

<!-- conversion_quality: 95 -->
