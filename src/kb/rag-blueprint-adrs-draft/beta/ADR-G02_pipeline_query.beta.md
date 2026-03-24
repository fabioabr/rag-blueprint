---
id: BETA-G02
title: "Pipeline de Processamento de Query"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-G02_pipeline_query.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
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
aliases:
  - "ADR-G02"
  - "Pipeline de Query"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## ADR-G02 -- Pipeline de Processamento de Query

**Tipo:** ADR
**Origem:** ADR-007
**Data:** 23/03/2026

## Objetivo

Especificar o pipeline completo de processamento de uma query desde a entrada do usuario ate a montagem do contexto final para o LLM. Cada etapa e detalhada com seu mecanismo, parametros, criterios de ativacao e metricas.

## Visao Geral do Pipeline

A query do usuario percorre as seguintes etapas em sequencia:

```
[Query do usuario]
     |
(1) Classificacao de intencao (Dispatcher)
     |
(2) Filtro de seguranca pre-retrieval
     |
(3) Query Rewriting (reformulacao)
     |
(4) Query Expansion (expansao de sinonimos)
     |
(5) Query Decomposition (decomposicao, se complexa)
     |
(6) 3 Buscas Paralelas (vetor + keyword + grafo)
     |
(7) Fusao via RRF (Reciprocal Rank Fusion)
     |
(8) Reranking (cross-encoder)
     |
(9) Montagem de contexto para o LLM
     |
[Resposta ao usuario]
```

## Etapa 1 -- Classificacao de Intencao (Dispatcher)

### 1.1 Mecanismo

Um LLM leve classifica a intencao da query para direcionar ao agente especializado correto. A classificacao usa few-shot examples.

### 1.2 Categorias de Intencao

| Intencao | Agente destino | Exemplos |
|---|---|---|
| architecture | Architecture Agent | "Qual ADR decidiu sobre o banco?" |
| operations | Operations Agent | "Como fazer deploy do modulo X?" |
| business | Business Agent | "Quem e responsavel pela cobranca?" |
| ambiguous | Fallback (todos) | "Me fale sobre o sistema SAP" |

### 1.3 Parametros

- Modelo: LLM leve (ex: GPT-4o-mini ou Llama 3.1 8B local)
- Latencia alvo: < 100ms
- Cache: 5 minutos para queries identicas
- Confidence threshold: se confianca < 0.7, classificar como "ambiguous"

### 1.4 Fallback (ambiguous)

Quando a intencao e ambigua:
- Acionar TODOS os agentes em paralelo
- Cada agente retorna seus top-K resultados
- Resultados de todos os agentes sao fundidos via RRF adicional
- Custo: ~3x latencia (aceitavel para queries ambiguas)

## Etapa 2 -- Filtro de Seguranca Pre-Retrieval

### 2.1 Mecanismo

ANTES de qualquer busca, o sistema aplica filtros de confidencialidade baseados no perfil do usuario autenticado.

### 2.2 Regras

- Determinar nivel maximo de acesso do usuario
- Construir clausula de filtro: confidentiality IN [niveis_permitidos]
- Aplicar filtro em TODAS as 3 buscas subsequentes
- Se filtro falhar: retornar ZERO resultados (fail-closed)

### 2.3 Niveis

- **public** -> todos
- **internal** -> usuarios autenticados
- **restricted** -> usuarios com role "restricted" OU membros do team owner
- **confidential** -> usuarios explicitamente no access_list

### 2.4 Auditoria

Toda query e logada com:
- user_id
- niveis solicitados e efetivamente aplicados
- quantidade de chunks filtrados (removidos por seguranca)
- timestamp

## Etapa 3 -- Query Rewriting (Reformulacao)

### 3.1 Mecanismo

Reformula queries vagas ou mal formuladas em versoes mais precisas e buscaveis. Duas abordagens complementares:

**Abordagem 1 -- Regras (sempre executa primeiro):**
- Expandir siglas conhecidas do glossario (ex: "BACEN" -> "Banco Central do Brasil (BACEN)")
- Adicionar sinonimos do GlossaryTerm (ex: "boleto" + "titulo de cobranca")
- Latencia: < 10ms
- Cobertura: resolve >70% das queries

**Abordagem 2 -- LLM (acionado sob demanda):**
- Ativado quando resultados da busca com regras sao insuficientes (< 3 resultados com score > 0.5)
- Track A (Cloud): GPT-4o-mini ou equivalente (< 200ms)
- Track B (On-prem): Llama 3.1 8B ou Qwen via Ollama
- Timeout: 5 segundos
- Meta: < 30% das queries precisam de LLM

### 3.2 Preservacao

A query ORIGINAL e a query REFORMULADA sao ambas usadas nas buscas. Isso evita perda de informacao caso o rewriting introduza distorcao.

### 3.3 Metricas

- % queries resolvidas por regras (alvo: > 70%)
- % queries com fallback LLM (alvo: < 30%)
- Latencia media do rewriting (alvo: < 50ms para regras, < 2s para LLM)
- Recall antes vs depois do rewriting (medir ganho)

## Etapa 4 -- Query Expansion (Expansao)

### 4.1 Mecanismo

Gera 2-3 variacoes da query cobrindo sinonimos e reformulacoes alternativas para aumentar recall.

Exemplo:
- Query original: "regras de cobranca de boleto"
- Expansoes:
  - "politica de faturamento e emissao de boletos bancarios"
  - "normas para geracao de titulos de cobranca"

### 4.2 Implementacao

- Fonte primaria: GlossaryTerm do grafo (sinonimos controlados)
- Fonte secundaria: LLM para gerar parafrase (se necessario)
- Maximo de expansoes: 3 (evitar explosao de buscas)

### 4.3 Uso nas Buscas

Cada expansao e usada como query adicional na busca vetorial. Resultados de todas as expansoes sao incluidos na fusao RRF.

## Etapa 5 -- Query Decomposition (Decomposicao)

### 5.1 Mecanismo

Decompoe queries complexas com multiplas sub-perguntas em sub-queries atomicas que sao processadas independentemente.

### 5.2 Criterios de Ativacao

A decomposicao e ativada quando:
- Query tem > 20 tokens
- Contem "e"/"ou" conectando temas distintos
- Pede informacoes de naturezas diferentes (ex: "Quem e o responsavel pelo modulo X E quais ADRs foram decididas?")

### 5.3 Exemplo

Query: "Quem e o responsavel pelo modulo de cobranca e quais dependencias ele tem?"
Sub-queries:
1. "Quem e o responsavel pelo modulo de cobranca?"
2. "Quais sao as dependencias do modulo de cobranca?"

Cada sub-query percorre o pipeline de buscas independentemente. Resultados sao reunidos na resposta final.

## Etapa 6 -- 3 Buscas Paralelas

As 3 buscas executam em PARALELO (nao sequencialmente):

### 6.1 Busca Vetorial (Vector Search)

- Gera embedding da query (e expansoes) com BGE-M3
- Busca top-20 por similaridade coseno no indice HNSW
- Filtro de seguranca aplicado
- Timeout: 500ms

### 6.2 Busca por Palavra-chave (Keyword Search / BM25)

- Busca full-text no Chunk.content
- Analisador pt-BR (stemming + stopwords)
- Operador OR com boost para AND
- Top-20 resultados, timeout: 500ms

### 6.3 Busca por Grafo (Graph Search)

- Identifica entidades na query
- Navega relacoes (profundidade 2 hops)
- Coleta chunks dos documentos encontrados
- Max 10 documentos por navegacao, timeout: 500ms

### 6.4 Tratamento de Falhas

- Se 1 busca falhar: continuar com as 2 restantes
- Se 2 buscas falharem: continuar com a 1 restante (qualidade degradada)
- Se TODAS falharem: erro explicito ao usuario
- Cada falha logada para observabilidade

## Etapa 7 -- Fusao via RRF (Reciprocal Rank Fusion)

### 7.1 Problema

As 3 buscas retornam listas com scores INCOMPATIVEIS:
- Busca vetorial: coseno 0.0 a 1.0
- Busca keyword: BM25 0 a infinito
- Busca grafo: sem score numerico (baseado em proximidade relacional)

NAO e possivel comparar ou somar esses scores diretamente.

### 7.2 Solucao: RRF

O RRF converte POSICOES EM RANKING em score unificado:

```
score_RRF(d) = SUM( 1 / (k + rank_i(d)) )  para cada busca i
```

Onde:
- d = documento (chunk)
- k = 60 (constante de suavizacao, paper original de Cormack et al. 2009)
- rank_i(d) = posicao do documento na lista da busca i (1 = primeiro)
- Se o documento nao aparece na lista i, rank_i(d) = infinito (contribuicao zero)

### 7.3 Exemplo

Chunk C-042 aparece:
- Posicao 3 na busca vetorial: 1/(60+3) = 0.0159
- Posicao 1 na busca keyword: 1/(60+1) = 0.0164
- Nao aparece na busca grafo: 0

score_RRF(C-042) = 0.0159 + 0.0164 + 0 = 0.0323

### 7.4 Saida

Lista unificada de chunks ordenados por score_RRF decrescente. Os top ~50 candidatos seguem para a etapa de reranking.

### 7.5 Vantagens do RRF

- Nao requer normalizacao de scores
- Agnostico ao tipo de busca
- Robusto: funciona com 1, 2 ou 3 listas
- Sem parametros de peso (ao contrario de weighted average)

## Etapa 8 -- Reranking (Cross-Encoder)

### 8.1 Mecanismo

Um cross-encoder recebe query E chunk como entrada UNICA e produz score de relevancia com atencao cruzada token a token.

Diferenca do embedding (bi-encoder):
- Bi-encoder: gera vetores separados para query e chunk, compara por coseno
- Cross-encoder: processa query+chunk juntos, captura interacoes finas

Vantagens do cross-encoder:
- Captura NEGACOES ("nao usar boleto" vs "usar boleto")
- Captura CONTEXTO CONDICIONAL ("se o sistema estiver em manutencao")
- Parafrases PRECISAS
- Qualidade superior ao bi-encoder para ranking fino

### 8.2 Fluxo

Top ~50 candidatos do RRF -> Cross-encoder processa cada par (query, chunk) -> Re-ordena por score de relevancia -> Retorna top-K final (K = 5 a 10, configuravel)

### 8.3 Dual-Track (conforme ADR-002 e ADR-009)

| Track | Modelo | Custo | Latencia |
|---|---|---|---|
| A Cloud | Cohere Rerank v3 | ~$2/1.000 buscas | ~200ms/batch 50 |
| B Local | BGE-Reranker-v2-m3 | Zero | ~500ms GPU, ~2s CPU |

Track B e OBRIGATORIO para documentos restricted/confidential. Track A e opcional para documentos public/internal.

### 8.4 Ganho Esperado

O reranking melhora a qualidade do top-K em 10-30% (medido por nDCG@10).

## Etapa 9 -- Montagem de Contexto para o LLM

### 9.1 Selecao Final

Os top-K chunks (5-10) apos reranking sao selecionados para compor o contexto do prompt enviado ao LLM.

### 9.2 Estrutura do Contexto

Para cada chunk incluido:
- Texto do chunk
- Origem: documento, sistema, modulo
- Score de relevancia (para transparencia)
- Caminho no grafo (se encontrado via Graph Search)

### 9.3 Instrucoes ao LLM

O prompt inclui instrucoes para:
- Citar a origem documental de cada afirmacao
- Indicar nivel de confianca
- Alertar quando informacao pode estar desatualizada
- Nao inventar informacao alem do contexto fornecido

### 9.4 Filtragem Temporal

Se a query contem contexto temporal:
- Filtrar chunks por valid_from/valid_until
- Instruir LLM a citar periodo de vigencia
- Mencionar versoes anteriores quando existirem
- Alertar sobre documentos proximos de expiracao

Se NAO contem contexto temporal:
- Assumir data atual
- Excluir documentos com status "deprecated"

## Metricas do Pipeline

| Metrica | Alvo |
|---|---|
| Latencia end-to-end | < 2 segundos (pipeline completo) |
| Latencia dispatcher | < 100ms |
| Latencia query rewriting | < 50ms (regras), < 2s (LLM) |
| Latencia buscas paralelas | < 500ms (timeout por busca) |
| Latencia RRF | < 10ms |
| Latencia reranking | < 500ms GPU, < 2s CPU |
| Recall@10 (golden set) | >= 70% (MVP), >= 85% (Prod) |

## Referencias

- ADR-007: Retrieval Hibrido e Agentes Especializados
- ADR-009: Selecao de Modelos de Embedding (Trilha On-Premises)
- ADR-002: Soberania de Dados -- Trilha Cloud vs. On-Premises
- ADR-004: Seguranca e Classificacao de Dados
- Cormack, Clarke, Buettcher (2009). "Reciprocal Rank Fusion outperforms Condorcet and individual Rank Learning Methods"
- Nogueira, Cho (2019). "Passage Re-ranking with BERT"

<!-- conversion_quality: 95 -->
