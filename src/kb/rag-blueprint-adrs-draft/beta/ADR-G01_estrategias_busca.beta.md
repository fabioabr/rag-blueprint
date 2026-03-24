---
id: BETA-G01
title: "Estrategias de Busca (Vetor, Keyword, Grafo)"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-G01_estrategias_busca.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags:
  - busca vetorial
  - vector search
  - similaridade coseno
  - keyword search
  - bm25
  - full text search
  - graph search
  - busca por grafo
  - retrieval hibrido
  - hnsw
  - embedding
  - indice vetorial
  - navegacao relacional
  - busca semantica
  - busca por palavra chave
  - stemming
  - tokenizacao
  - stopwords
  - relevancia
  - ranking
  - score de similaridade
  - neo4j
  - base vetorial
  - chunk
  - document
  - filtro de seguranca
  - confidencialidade
  - fail closed
  - tratamento de falhas
  - degradacao graciosa
  - complementaridade
  - sinonimos
  - termos exatos
  - codigos
  - siglas
  - nomes proprios
  - relacoes estruturais
  - dependencias
  - entidades
  - grafo de conhecimento
  - system
  - module
  - owner
  - team
  - glossary term
  - task
  - adr
  - ef search
  - top k
  - latencia
  - espaco vetorial
  - bge m3
aliases:
  - "ADR-G01"
  - "Estrategias de Busca"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## ADR-G01 -- Estrategias de Busca (Vetor, Keyword, Grafo)

**Tipo:** ADR
**Origem:** ADR-007
**Data:** 23/03/2026

## Objetivo

Detalhar o mecanismo de cada uma das 3 buscas paralelas que compoem o retrieval hibrido do RAG Corporativo: Vector Search (semantica), Keyword Search (BM25/full-text) e Graph Search (navegacao relacional). Para cada estrategia, descrever como funciona, seus parametros, pontos fortes, pontos fracos e cenarios ideais de uso.

## 1. Busca Vetorial (Vector Search -- Similaridade Coseno)

### 1.1 Como Funciona

a) Recebe a query do usuario em linguagem natural
b) Gera embedding da query usando o MESMO modelo dos chunks (critico: modelos diferentes = espacos vetoriais incompativeis)
c) Busca os top-K chunks mais proximos no indice vetorial HNSW por similaridade coseno
d) Retorna lista de chunks com score de similaridade (0.0 a 1.0)

A similaridade coseno mede o angulo entre dois vetores no espaco de 1024 dimensoes. Quanto mais proximo de 1.0, mais semanticamente similar o chunk e a query.

### 1.2 Parametros

| Parametro | Valor padrao | Descricao |
|---|---|---|
| K (top resultados) | 20 | Numero de chunks retornados (configuravel) |
| similaridade_minima | 0.5 | Score abaixo disso e descartado |
| ef_search | 100 | Qualidade da busca HNSW (maior = melhor, mais lento) |
| modelo_embedding | BGE-M3 | Obrigatorio: mesmo modelo de indexacao e query |
| prefixo_query | sim | Prefixo de instrucao para busca assimetrica |

### 1.3 Pontos Fortes

- Entende SEMANTICA: "politica de cobranca" encontra "regras de faturamento"
- Tolera SINONIMOS: "cancelar" encontra "estornar", "revogar"
- Tolera ERROS de digitacao (parcialmente): embeddings sao robustos a typos leves
- Suporte MULTILINGUAL: query em portugues encontra chunk com termos em ingles
- Eficiente para perguntas conceituais e exploratorias
- Latencia baixa: ~10-50ms para 50K chunks com HNSW

### 1.4 Pontos Fracos

- NAO garante match de TERMOS EXATOS: buscar "BACEN 4893" pode retornar resultados sobre regulamentacao bancaria generica em vez do numero especifico
- TENDE A GENERALIZAR: termos tecnicos especificos podem ser "diluidos" no espaco vetorial
- CODIGOS e SIGLAS: embeddings tratam "SKU-12345" como texto generico
- NAO NAVEGA relacoes: nao descobre dependencias entre modulos
- Sensivel a qualidade do modelo de embedding

### 1.5 Cenarios Ideais

- "Como funciona o processo de cobranca?"
- "Quais sao as regras de cancelamento de boleto?"
- "Explique a arquitetura do modulo financeiro"
- Perguntas abertas, conceituais, exploratorias

## 2. Busca por Palavra-Chave (Keyword Search -- BM25 / Full-Text)

### 2.1 Como Funciona

a) Recebe a query do usuario (ou versao expandida pelo query rewriting)
b) Executa busca full-text no indice de texto dos chunks (Chunk.content)
c) Usa analisador com suporte a portugues:
   - Tokenizacao: quebra texto em tokens
   - Stemming: reduz palavras a radicais ("cobrancas" -> "cobranc")
   - Stopwords: remove palavras comuns ("de", "para", "o", "a")
d) Ranqueia resultados pelo algoritmo BM25
e) Retorna chunks ordenados por relevancia BM25

O BM25 (Best Matching 25) calcula relevancia baseado em:
- Frequencia do termo no documento (TF)
- Frequencia inversa no corpus (IDF) -- termos raros valem mais
- Comprimento do documento (normalizacao)

### 2.2 Parametros

| Parametro | Valor padrao | Descricao |
|---|---|---|
| max_resultados | 20 | Numero maximo de chunks retornados |
| operador | OR | OR entre termos, com boost para AND |
| analisador | pt-BR | Analisador com stemming portugues |
| boost_AND | 2.0 | Multiplicador para match de todos os termos |
| min_score | 0.1 | Score BM25 minimo para inclusao |

### 2.3 Pontos Fortes

- Match EXATO de termos: "BACEN 4893" encontra exatamente esse termo
- CODIGOS e IDENTIFICADORES: "SKU-12345", "CU-4567", "DOC-000123"
- NOMES PROPRIOS: "Fabio", "Squad Financeiro"
- SIGLAS tecnicas: "LGPD", "CVM", "PIX"
- Deterministico: mesma query sempre retorna mesmos resultados
- Rapido: BM25 e altamente otimizado, latencia < 10ms

### 2.4 Pontos Fracos

- NAO entende SEMANTICA: "cancelar" NAO encontra "estornar"
- NAO tolera ERROS de digitacao: "cobranssa" nao encontra "cobranca"
- Sensivel a VOCABULARIO: usuario deve usar os mesmos termos do documento
- NAO entende CONTEXTO: "banco" (financeiro) vs "banco" (dados)
- Stemming pode causar falsos positivos (radicais ambiguos)

### 2.5 Cenarios Ideais

- "Qual e a resolucao BACEN 4893?"
- "Status da task CU-4567"
- "Documentos do modulo Cobranca"
- "Quem e o owner do sistema SAP?"
- Buscas com codigos, IDs, nomes exatos, siglas

## 3. Busca por Grafo (Graph Search -- Navegacao Relacional)

### 3.1 Como Funciona

a) Identifica ENTIDADES mencionadas na query:
   - Sistemas (System): "SAP", "sistema de cobranca"
   - Modulos (Module): "modulo de boletos", "API de pagamentos"
   - Pessoas (Owner): "Fabio", "time de arquitetura"
   - Times (Team): "squad financeiro", "chapter backend"
   - Termos (GlossaryTerm): "remessa", "liquidacao"
   - Tarefas (Task): "CU-4567"

b) Navega o grafo a partir das entidades identificadas, seguindo relacoes:
   - BELONGS_TO: de modulo para sistema, de documento para modulo
   - DEPENDS_ON: dependencias entre modulos
   - OWNED_BY: responsaveis por documentos/sistemas
   - MEMBER_OF: membros de times
   - REFERENCES: referencias entre documentos
   - SUPERSEDES: versionamento de documentos
   - IMPLEMENTS: tarefas que implementam modulos
   - DECIDES: ADRs que decidem sobre sistemas
   - USES_TERM: documentos que usam termos do glossario

c) Coleta chunks dos documentos encontrados via navegacao
d) Retorna chunks com contexto relacional (qual caminho levou ao chunk)

### 3.2 Parametros

| Parametro | Valor padrao | Descricao |
|---|---|---|
| profundidade | 2 hops | Distancia maxima de navegacao no grafo |
| max_docs_por_navegacao | 10 | Maximo de documentos coletados por caminho |
| relacoes_priorizadas | depende agente | Quais relacoes seguir (configuravel) |
| timeout | 500ms | Timeout para evitar travessias longas |

### 3.3 Pontos Fortes

- Descobre RELACOES ESTRUTURAIS: "quais modulos dependem do Cobranca?"
- CONTEXTO ORGANIZACIONAL: "quem e responsavel pelo sistema X?"
- VERSIONAMENTO: "qual era a versao anterior desta ADR?"
- IMPACTO: "o que e afetado se o modulo Y mudar?"
- Complementa buscas semanticas com contexto que vetores nao capturam
- Respostas com RASTREABILIDADE: mostra o caminho no grafo

### 3.4 Pontos Fracos

- Depende de ENTIDADES EXISTENTES no grafo (se a entidade nao esta cadastrada, a busca nao encontra nada)
- MAIS LENTO que busca vetorial e BM25 (navegacao de grafo e iterativa)
- QUALIDADE depende da completude do grafo (relacoes ausentes = gaps)
- IDENTIFICACAO de entidades na query pode falhar (NER imperfeito)
- Profundidade > 2 hops pode gerar ruido (resultados distantes demais)

### 3.5 Cenarios Ideais

- "Quais sistemas dependem do modulo de cobranca?"
- "Quem e o responsavel pelo sistema de pagamentos?"
- "Quais ADRs foram tomadas sobre o sistema SAP?"
- "Quais tarefas implementam o modulo de boletos?"
- "Qual a versao anterior do documento X?"
- Perguntas sobre estrutura, dependencias, responsabilidades

## 4. Complementaridade das 3 Buscas

As 3 buscas cobrem cenarios complementares. Nenhuma isoladamente resolve todos os tipos de perguntas corporativas:

| Tipo de pergunta | Vetor | Keyword | Grafo |
|---|---|---|---|
| Conceitual/semantica | +++ | - | + |
| Termo exato/codigo | - | +++ | + |
| Relacao estrutural | - | - | +++ |
| Sinonimos | +++ | - | - |
| Nomes proprios | + | +++ | ++ |
| Dependencias entre modulos | - | - | +++ |
| Pergunta mista | ++ | ++ | ++ |

**Legenda:** +++ excelente, ++ bom, + parcial, - fraco

## 5. Tratamento de Falhas

Se uma das 3 buscas falhar (timeout, erro de indice, indisponibilidade):

- O sistema DEVE continuar com as buscas restantes
- O RRF opera sobre 2 listas em vez de 3
- A qualidade degrada GRACIOSAMENTE (perde cobertura daquele tipo)
- Cada falha e registrada em log com: tipo de busca, erro, timestamp, query

Se TODAS as 3 buscas falharem:
- Retornar erro explicito ao usuario
- NAO tentar gerar resposta sem chunks de suporte
- Registrar incidente para investigacao

## 6. Filtro de Seguranca

O filtro de seguranca e aplicado em TODAS as 3 buscas, ANTES da execucao:

| Nivel | Acesso |
|---|---|
| public | Todos os usuarios |
| internal | Usuarios autenticados |
| restricted | Usuarios com role "restricted" OU do team owner |
| confidential | Usuarios explicitamente listados no access_list |

**Regra de Ouro:** "Se o filtro de seguranca falhar, o sistema DEVE retornar ZERO resultados -- NUNCA resultados sem filtro." Fail-closed, nao fail-open.

Na Graph Search especificamente: documentos com confidencialidade acima do nivel do usuario sao tratados como INEXISTENTES (nao navegaveis, relacoes cortadas). O usuario nao sabe que o documento existe.

## Referencias

- ADR-007: Retrieval Hibrido e Agentes Especializados
- ADR-009: Selecao de Modelos de Embedding (Trilha On-Premises)
- ADR-003: Modelo de Dados da Base Vetorial
- ADR-004: Seguranca e Classificacao de Dados
- Robertson, Zaragoza (2009). "The Probabilistic Relevance Framework: BM25 and Beyond"
- Malkov, Yashunin (2018). "Efficient and robust approximate nearest neighbor search using HNSW graphs"

<!-- conversion_quality: 95 -->
