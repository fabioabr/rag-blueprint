---
id: ADR-G01
doc_type: adr
title: "Estratégias de Busca (Vetor, Keyword, Grafo)"
system: RAG Corporativo
module: Estratégias de Busca
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
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
  - busca hibrida
  - tres buscas paralelas
aliases:
  - "ADR-G01"
  - "Estratégias de Busca"
  - "Busca Vetorial, Keyword e Grafo"
  - "Três Buscas Paralelas"
  - "Mecanismos de Retrieval"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/draft/ADR-G01_estrategias_busca.txt"
source_beta_ids:
  - "BETA-G01"
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

# ADR-G01 — Estratégias de Busca (Vetor, Keyword, Grafo)

| Campo | Valor |
|-------|-------|
| **Status** | Accepted |
| **Data da Decisão** | 2026-03-23 |
| **Decisor** | fabio |
| **Escopo** | Estratégias de Busca |

**Referências Cruzadas:**

- **Depende de:** [[ADR-007]]
- **Relaciona-se:** [[ADR-009]], [[ADR-003]], [[ADR-004]]

## Objetivo

Detalhar o mecanismo de cada uma das 3 buscas paralelas que compõem o retrieval híbrido do RAG Corporativo: Vector Search (semântica), Keyword Search (BM25/full-text) e Graph Search (navegação relacional). Para cada estratégia, descrever como funciona, seus parâmetros, pontos fortes, pontos fracos e cenários ideais de uso.

## 1. Busca Vetorial (Vector Search — Similaridade Cosseno)

### 1.1 Como Funciona

a) Recebe a query do usuário em linguagem natural
b) Gera embedding da query usando o MESMO modelo dos chunks (crítico: modelos diferentes = espaços vetoriais incompatíveis)
c) Busca os top-K chunks mais próximos no índice vetorial HNSW por similaridade cosseno
d) Retorna lista de chunks com score de similaridade (0.0 a 1.0)

A similaridade cosseno mede o ângulo entre dois vetores no espaço de 1024 dimensões. Quanto mais próximo de 1.0, mais semanticamente similar o chunk é à query.

### 1.2 Parâmetros

| Parâmetro | Valor padrão | Descrição |
|---|---|---|
| K (top resultados) | 20 | Número de chunks retornados (configurável) |
| similaridade_minima | 0.5 | Score abaixo disso é descartado |
| ef_search | 100 | Qualidade da busca HNSW (maior = melhor, mais lento) |
| modelo_embedding | BGE-M3 | Obrigatório: mesmo modelo de indexação e query |
| prefixo_query | sim | Prefixo de instrução para busca assimétrica |

### 1.3 Pontos Fortes

- Entende SEMÂNTICA: "política de cobrança" encontra "regras de faturamento"
- Tolera SINÔNIMOS: "cancelar" encontra "estornar", "revogar"
- Tolera ERROS de digitação (parcialmente): embeddings são robustos a typos leves
- Suporte MULTILINGUAL: query em português encontra chunk com termos em inglês
- Eficiente para perguntas conceituais e exploratórias
- Latência baixa: ~10-50ms para 50K chunks com HNSW

### 1.4 Pontos Fracos

- NÃO garante match de TERMOS EXATOS: buscar "BACEN 4893" pode retornar resultados sobre regulamentação bancária genérica em vez do número específico
- TENDE A GENERALIZAR: termos técnicos específicos podem ser "diluídos" no espaço vetorial
- CÓDIGOS e SIGLAS: embeddings tratam "SKU-12345" como texto genérico
- NÃO NAVEGA relações: não descobre dependências entre módulos
- Sensível à qualidade do modelo de embedding

### 1.5 Cenários Ideais

- "Como funciona o processo de cobrança?"
- "Quais são as regras de cancelamento de boleto?"
- "Explique a arquitetura do módulo financeiro"
- Perguntas abertas, conceituais, exploratórias

## 2. Busca por Palavra-Chave (Keyword Search — BM25 / Full-Text)

### 2.1 Como Funciona

a) Recebe a query do usuário (ou versão expandida pelo query rewriting)
b) Executa busca full-text no índice de texto dos chunks (Chunk.content)
c) Usa analisador com suporte a português:
   - Tokenização: quebra texto em tokens
   - Stemming: reduz palavras a radicais ("cobranças" -> "cobranç")
   - Stopwords: remove palavras comuns ("de", "para", "o", "a")
d) Ranqueia resultados pelo algoritmo BM25
e) Retorna chunks ordenados por relevância BM25

O BM25 (Best Matching 25) calcula relevância baseado em:
- Frequência do termo no documento (TF)
- Frequência inversa no corpus (IDF) — termos raros valem mais
- Comprimento do documento (normalização)

### 2.2 Parâmetros

| Parâmetro | Valor padrão | Descrição |
|---|---|---|
| max_resultados | 20 | Número máximo de chunks retornados |
| operador | OR | OR entre termos, com boost para AND |
| analisador | pt-BR | Analisador com stemming português |
| boost_AND | 2.0 | Multiplicador para match de todos os termos |
| min_score | 0.1 | Score BM25 mínimo para inclusão |

### 2.3 Pontos Fortes

- Match EXATO de termos: "BACEN 4893" encontra exatamente esse termo
- CÓDIGOS e IDENTIFICADORES: "SKU-12345", "CU-4567", "DOC-000123"
- NOMES PRÓPRIOS: "Fábio", "Squad Financeiro"
- SIGLAS técnicas: "LGPD", "CVM", "PIX"
- Determinístico: mesma query sempre retorna mesmos resultados
- Rápido: BM25 é altamente otimizado, latência < 10ms

### 2.4 Pontos Fracos

- NÃO entende SEMÂNTICA: "cancelar" NÃO encontra "estornar"
- NÃO tolera ERROS de digitação: "cobranssa" não encontra "cobrança"
- Sensível a VOCABULÁRIO: usuário deve usar os mesmos termos do documento
- NÃO entende CONTEXTO: "banco" (financeiro) vs "banco" (dados)
- Stemming pode causar falsos positivos (radicais ambíguos)

### 2.5 Cenários Ideais

- "Qual é a resolução BACEN 4893?"
- "Status da task CU-4567"
- "Documentos do módulo Cobrança"
- "Quem é o owner do sistema SAP?"
- Buscas com códigos, IDs, nomes exatos, siglas

## 3. Busca por Grafo (Graph Search — Navegação Relacional)

### 3.1 Como Funciona

a) Identifica ENTIDADES mencionadas na query:
   - Sistemas (System): "SAP", "sistema de cobrança"
   - Módulos (Module): "módulo de boletos", "API de pagamentos"
   - Pessoas (Owner): "Fábio", "time de arquitetura"
   - Times (Team): "squad financeiro", "chapter backend"
   - Termos (GlossaryTerm): "remessa", "liquidação"
   - Tarefas (Task): "CU-4567"

b) Navega o grafo a partir das entidades identificadas, seguindo relações:
   - BELONGS_TO: de módulo para sistema, de documento para módulo
   - DEPENDS_ON: dependências entre módulos
   - OWNED_BY: responsáveis por documentos/sistemas
   - MEMBER_OF: membros de times
   - REFERENCES: referências entre documentos
   - SUPERSEDES: versionamento de documentos
   - IMPLEMENTS: tarefas que implementam módulos
   - DECIDES: ADRs que decidem sobre sistemas
   - USES_TERM: documentos que usam termos do glossário

c) Coleta chunks dos documentos encontrados via navegação
d) Retorna chunks com contexto relacional (qual caminho levou ao chunk)

### 3.2 Parâmetros

| Parâmetro | Valor padrão | Descrição |
|---|---|---|
| profundidade | 2 hops | Distância máxima de navegação no grafo |
| max_docs_por_navegacao | 10 | Máximo de documentos coletados por caminho |
| relacoes_priorizadas | depende agente | Quais relações seguir (configurável) |
| timeout | 500ms | Timeout para evitar travessias longas |

### 3.3 Pontos Fortes

- Descobre RELAÇÕES ESTRUTURAIS: "quais módulos dependem do Cobrança?"
- CONTEXTO ORGANIZACIONAL: "quem é responsável pelo sistema X?"
- VERSIONAMENTO: "qual era a versão anterior desta ADR?"
- IMPACTO: "o que é afetado se o módulo Y mudar?"
- Complementa buscas semânticas com contexto que vetores não capturam
- Respostas com RASTREABILIDADE: mostra o caminho no grafo

### 3.4 Pontos Fracos

- Depende de ENTIDADES EXISTENTES no grafo (se a entidade não está cadastrada, a busca não encontra nada)
- MAIS LENTO que busca vetorial e BM25 (navegação de grafo é iterativa)
- QUALIDADE depende da completude do grafo (relações ausentes = gaps)
- IDENTIFICAÇÃO de entidades na query pode falhar (NER imperfeito)
- Profundidade > 2 hops pode gerar ruído (resultados distantes demais)

### 3.5 Cenários Ideais

- "Quais sistemas dependem do módulo de cobrança?"
- "Quem é o responsável pelo sistema de pagamentos?"
- "Quais ADRs foram tomadas sobre o sistema SAP?"
- "Quais tarefas implementam o módulo de boletos?"
- "Qual a versão anterior do documento X?"
- Perguntas sobre estrutura, dependências, responsabilidades

## 4. Complementaridade das 3 Buscas

As 3 buscas cobrem cenários complementares. Nenhuma isoladamente resolve todos os tipos de perguntas corporativas:

| Tipo de pergunta | Vetor | Keyword | Grafo |
|---|---|---|---|
| Conceitual/semântica | +++ | - | + |
| Termo exato/código | - | +++ | + |
| Relação estrutural | - | - | +++ |
| Sinônimos | +++ | - | - |
| Nomes próprios | + | +++ | ++ |
| Dependências entre módulos | - | - | +++ |
| Pergunta mista | ++ | ++ | ++ |

**Legenda:** +++ excelente, ++ bom, + parcial, - fraco

## 5. Tratamento de Falhas

Se uma das 3 buscas falhar (timeout, erro de índice, indisponibilidade):

- O sistema DEVE continuar com as buscas restantes
- O RRF opera sobre 2 listas em vez de 3
- A qualidade degrada GRACIOSAMENTE (perde cobertura daquele tipo)
- Cada falha é registrada em log com: tipo de busca, erro, timestamp, query

Se TODAS as 3 buscas falharem:
- Retornar erro explícito ao usuário
- NÃO tentar gerar resposta sem chunks de suporte
- Registrar incidente para investigação

## 6. Filtro de Segurança

O filtro de segurança é aplicado em TODAS as 3 buscas, ANTES da execução:

| Nível | Acesso |
|---|---|
| public | Todos os usuários |
| internal | Usuários autenticados |
| restricted | Usuários com role "restricted" OU do team owner |
| confidential | Usuários explicitamente listados no access_list |

**Regra de Ouro:** "Se o filtro de segurança falhar, o sistema DEVE retornar ZERO resultados — NUNCA resultados sem filtro." Fail-closed, não fail-open.

Na Graph Search especificamente: documentos com confidencialidade acima do nível do usuário são tratados como INEXISTENTES (não navegáveis, relações cortadas). O usuário não sabe que o documento existe.

## Referências

- [[ADR-007]]: Retrieval Híbrido e Agentes Especializados
- [[ADR-009]]: Seleção de Modelos de Embedding (Trilha On-Premises)
- [[ADR-003]]: Modelo de Dados da Base Vetorial
- [[ADR-004]]: Segurança e Classificação de Dados
- Robertson, Zaragoza (2009). "The Probabilistic Relevance Framework: BM25 and Beyond"
- Malkov, Yashunin (2018). "Efficient and robust approximate nearest neighbor search using HNSW graphs"

<!-- conversion_quality: 95 -->
