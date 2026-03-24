---
id: ADR-007
doc_type: adr
title: "Retrieval Híbrido e Agentes Especializados"
system: RAG Corporativo
module: Retrieval e Agentes
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-21
tags:
  - retrieval hibrido
  - busca vetorial
  - busca keyword
  - busca grafo
  - rrf
  - reciprocal rank fusion
  - reranking
  - cross encoder
  - agentes especializados
  - dispatcher
  - classificacao intencao
  - query rewriting
  - query expansion
  - query decomposition
  - filtro seguranca
  - filtragem temporal
  - similaridade coseno
  - bm25 full text
  - graph search
  - navegacao relacional
  - hnsw
  - architecture agent
  - operations agent
  - business agent
  - feedback loop
  - gap conhecimento
  - golden set
  - recall
  - metricas qualidade
  - dashboard semanal
  - perfis consumo
  - dual track
  - cohere rerank
  - bge reranker
  - system prompt
  - few shot examples
  - filtro confidencialidade
  - fail closed
  - stemming portugues
  - sinonimos glossario
  - chunks ranqueados
  - latencia busca
  - fallback ambiguous
  - melhoria continua
  - deteccao gaps
  - causa raiz
  - triagem automatica
  - auditoria query
  - privacidade feedback
  - ciclo curadoria
  - ndcg
  - score unificado
  - contexto llm
aliases:
  - "ADR-007"
  - "Retrieval Híbrido"
  - "Busca Híbrida RAG"
  - "Agentes Especializados"
  - "Hybrid Retrieval and Specialized Agents"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/beta/ADR-007_retrieval_hibrido_agentes.beta.md"
source_beta_ids:
  - "BETA-007"
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

# ADR-007 — Retrieval Híbrido e Agentes Especializados

## Referências Cruzadas

- **Depende de:** [[ADR-001]], [[ADR-002]], [[ADR-003]], [[ADR-004]]
- **Relaciona-se:** [[ADR-005]], [[ADR-006]], [[ADR-009]]

## Contexto

### Posição no Pipeline de 4 Fases

Esta ADR atua na **Fase 4 — Geração do RAG (Camada Ouro)**. O pipeline de 4 fases definido na [[ADR-001]] estabelece:

- Fase 1: Seleção de insumos
- Fase 2: Mineração e edição (`.beta.md` no rag-workspace)
- Fase 3: Promoção para `.md` final (rag-knowledge-base, imutável)
- Fase 4: Ingestão na Base Vetorial e CONSUMO via retrieval

Este ADR define COMO o conhecimento ingerido na Fase 4 é recuperado e entregue aos consumidores (humanos e agentes de IA). O `.md` final gerado na Fase 3 (fonte da verdade, nunca editado manualmente) é a origem dos dados que a busca híbrida consulta.

### Por que Busca Vetorial Simples NÃO é Suficiente

A Base Vetorial, populada pelo pipeline definido na [[ADR-006]], contém nós `:Document` com metadados ricos, nós `:Chunk` com embeddings vetoriais e conteúdo textual, grafo de relações e índices vetoriais, full-text e compostos.

A busca vetorial (similaridade coseno) é excelente para perguntas conceituais e semânticas, porém tem limitações críticas em ambiente corporativo:

1. **Termos exatos**: não garante match de termos literais como "BACEN 4893" ou "SKU-12345"
2. **Relações estruturais**: não navega relações `DEPENDS_ON` entre módulos
3. **Códigos e siglas**: embeddings tratam códigos como texto genérico, sem discriminação fina
4. **Contexto organizacional**: perguntas como "quem é responsável pelo sistema X?" são de GRAFO, não de similaridade textual

### Perfis de Consumo

| Perfil | Necessidade | Tipo de resposta |
|--------|-------------|------------------|
| Desenvolvedores | Detalhes técnicos, APIs, dependências | Precisa, com links para fonte |
| Tech Leads / Arquitetos | Decisões (ADRs), trade-offs, dependências | Contexto amplo |
| Gestores / Executivos | Visão macro, status, responsáveis | Resumida e confiante |
| Agentes de IA | Chunks bem ranqueados e contextualizados | Estruturada para LLM |

<!-- LOCKED:START autor=fabio data=2026-03-23 -->

## Decisão — Busca Híbrida (3 Buscas Paralelas + RRF)

A estratégia de retrieval combina **3 tipos de busca executados em PARALELO**, cujos resultados são fundidos via **Reciprocal Rank Fusion (RRF)** e re-ranqueados por cross-encoder para produzir a lista final de chunks mais relevantes.

Cada tipo de busca tem forças e fraquezas complementares. Nenhuma isoladamente cobre todos os cenários de perguntas corporativas. A combinação das 3 buscas maximiza o recall sem sacrificar excessivamente a precisão.

**Tratamento de falhas**: se uma das 3 buscas falhar (timeout, erro de índice, indisponibilidade), o sistema DEVE continuar com as buscas restantes. O RRF opera sobre 2 listas em vez de 3 — a qualidade degrada graciosamente. Se TODAS as 3 buscas falharem, retornar erro explícito ao usuário. Cada falha é registrada em log.

### Busca 1 — Vector Search (Semântica)

**Como funciona**:

1. Recebe a query do usuário em linguagem natural
2. Gera embedding da query usando o **mesmo modelo** dos chunks (crítico: modelos diferentes = espaços incompatíveis)
3. Busca os top-K chunks mais próximos por similaridade coseno no índice vetorial HNSW
4. Retorna lista de chunks com score de similaridade (0.0 a 1.0)

A similaridade coseno mede o ângulo entre dois vetores no espaço de 1024 dimensões. Quanto mais próximo de 1.0, mais semanticamente similar.

**Parâmetros**:

| Parâmetro | Valor padrão | Descrição |
|---|---|---|
| K (top resultados) | 20 | Número de chunks retornados (configurável) |
| similaridade_minima | 0.5 | Score abaixo disso é descartado |
| ef_search | 100 | Qualidade da busca HNSW (maior = melhor, mais lento) |
| modelo_embedding | BGE-M3 | Obrigatório: mesmo modelo de indexação e query |
| prefixo_query | sim | Prefixo de instrução para busca assimétrica |

**Pontos fortes**: entende semântica, sinônimos, tolera erros de digitação, suporte multilingual, eficiente para perguntas conceituais, latência ~10-50ms para 50K chunks com HNSW.

**Pontos fracos**: não garante match de termos exatos ("BACEN 4893"), tende a generalizar, códigos e siglas tratados como texto genérico, não navega relações, sensível à qualidade do modelo.

**Cenários ideais**: perguntas conceituais, exploratórias, sobre processos e regras.

### Busca 2 — Keyword Search (Full-Text / BM25)

**Como funciona**:

1. Executa busca full-text no índice de `Chunk.content`
2. Usa analisador com suporte a português: tokenização, stemming ("cobranças" -> "cobranç"), stopwords
3. Ranqueia resultados pelo algoritmo BM25 (frequência do termo, IDF, normalização por comprimento)
4. Retorna chunks ordenados por relevância BM25

**Parâmetros**:

| Parâmetro | Valor padrão | Descrição |
|---|---|---|
| max_resultados | 20 | Número máximo de chunks retornados |
| operador | OR | OR entre termos, com boost para AND |
| analisador | pt-BR | Analisador com stemming português |
| boost_AND | 2.0 | Multiplicador para match de todos os termos |
| min_score | 0.1 | Score BM25 mínimo para inclusão |

**Pontos fortes**: match exato de termos, códigos, identificadores ("SKU-12345", "CU-4567"), nomes próprios, siglas técnicas ("LGPD", "PIX"), determinístico, rápido (< 10ms).

**Pontos fracos**: não entende semântica ("cancelar" NÃO encontra "estornar"), não tolera erros de digitação, sensível a vocabulário, não entende contexto ("banco" financeiro vs "banco" de dados).

**Cenários ideais**: buscas com códigos, IDs, nomes exatos, siglas, resoluções regulatórias.

### Busca 3 — Graph Search (Navegação Relacional)

**Como funciona**:

1. Identifica **entidades** mencionadas na query: sistemas (System), módulos (Module), pessoas (Owner), times (Team), termos (GlossaryTerm), tarefas (Task)
2. Navega o grafo a partir das entidades identificadas, seguindo relações: `BELONGS_TO`, `DEPENDS_ON`, `OWNED_BY`, `MEMBER_OF`, `REFERENCES`, `SUPERSEDES`, `IMPLEMENTS`, `DECIDES`, `USES_TERM`
3. Coleta chunks dos documentos encontrados via navegação
4. Retorna chunks com contexto relacional (qual caminho levou ao chunk)

**Parâmetros**:

| Parâmetro | Valor padrão | Descrição |
|---|---|---|
| profundidade | 2 hops | Distância máxima de navegação no grafo |
| max_docs_por_navegacao | 10 | Máximo de documentos coletados por caminho |
| relacoes_priorizadas | depende do agente | Quais relações seguir (configurável) |
| timeout | 500ms | Timeout para evitar travessias longas |

**Pontos fortes**: descobre relações estruturais ("quais módulos dependem do Cobrança?"), contexto organizacional, versionamento, impacto de mudanças, respostas com rastreabilidade (caminho no grafo).

**Pontos fracos**: depende de entidades existentes no grafo, mais lento que vetorial e BM25, qualidade depende da completude do grafo, identificação de entidades pode falhar (NER imperfeito), profundidade > 2 hops pode gerar ruído.

**Cenários ideais**: perguntas sobre estrutura, dependências, responsabilidades, versionamento, impacto.

### Complementaridade das 3 Buscas

| Tipo de pergunta | Vetor | Keyword | Grafo |
|---|---|---|---|
| Conceitual/semântica | +++ | - | + |
| Termo exato/código | - | +++ | + |
| Relação estrutural | - | - | +++ |
| Sinônimos | +++ | - | - |
| Nomes próprios | + | +++ | ++ |
| Dependências entre módulos | - | - | +++ |
| Pergunta mista | ++ | ++ | ++ |

### Fusão — Reciprocal Rank Fusion (RRF)

As 3 buscas retornam listas com sistemas de scoring incompatíveis (coseno 0-1, BM25 0-infinito, grafo sem score). O RRF converte **posições em ranking** em score unificado:

```
score_RRF(d) = SUM( 1 / (k + rank_i(d)) )  para cada busca i
```

Onde `k=60` (constante de suavização do paper original de Cormack, Clarke e Buettcher, 2009). Se o documento não aparece na lista `i`, `rank_i(d) = infinito` (contribuição zero).

**Exemplo**: Chunk C-042 aparece na posição 3 na busca vetorial (`1/(60+3) = 0.0159`), posição 1 na keyword (`1/(60+1) = 0.0164`), não aparece no grafo (0). Score RRF = 0.0323.

**Vantagens**: não requer normalização de scores, agnóstico ao tipo de busca, robusto com 1-3 listas, sem parâmetros de peso.

**Saída**: lista unificada de chunks ordenados por score_RRF decrescente. Os top ~50 candidatos seguem para Reranking.

### Reranking (Cross-Encoder)

Um cross-encoder recebe query E chunk como entrada ÚNICA e produz score de relevância com atenção cruzada token a token. Diferente do bi-encoder (vetores separados comparados por coseno), o cross-encoder processa query+chunk juntos, capturando negações, contexto condicional e paráfrases precisas.

**Fluxo**: top ~50 candidatos do RRF -> cross-encoder -> re-ordenação -> top-K final (K=5 a K=10).

**Dual-track** (conforme [[ADR-002]] e [[ADR-009]]):

| Track | Modelo | Custo | Latência | Restrição |
|-------|--------|-------|----------|-----------|
| A — Cloud | Cohere Rerank v3 | ~$2/1.000 buscas | ~200ms/batch 50 | Apenas public/internal |
| B — On-premises | BGE-Reranker-v2-m3 | Zero | ~500ms GPU, ~2s CPU | Obrigatório para restricted/confidential |

**Ganho esperado**: melhora qualidade do top-K em 10-30% (medido por nDCG@10).

<!-- LOCKED:END -->

## Pipeline de Processamento de Query

Antes das 3 buscas, a query passa por pré-processamento em 9 etapas:

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
(7) Fusão via RRF
     |
(8) Reranking (cross-encoder)
     |
(9) Montagem de contexto para o LLM
     |
[Resposta ao usuário]
```

### Query Rewriting (Reformulação)

Um LLM reformula queries vagas em versões mais precisas. Duas abordagens complementares:

**Abordagem 1 — Regras (sempre executa primeiro)**:
- Expandir siglas conhecidas do glossário (ex: "BACEN" -> "Banco Central do Brasil (BACEN)")
- Adicionar sinônimos do GlossaryTerm (ex: "boleto" + "título de cobrança")
- Latência: < 10ms
- Cobertura: resolve >70% das queries

**Abordagem 2 — LLM (acionado sob demanda)**:
- Ativado quando resultados da busca com regras são insuficientes (< 3 resultados com score > 0.5)
- Track A (Cloud): GPT-4o-mini ou equivalente (< 200ms)
- Track B (On-prem): Llama 3.1 8B ou Qwen via Ollama (timeout 5s)
- Meta: < 30% das queries precisam de LLM

A query original E a reformulada são ambas usadas nas buscas (evita perda por distorção).

**Métricas-alvo**: >70% queries resolvidas por regras, <30% com fallback LLM, latência média <50ms (regras) / <2s (LLM).

### Query Expansion (Expansão)

Gera 2-3 variações da query cobrindo sinônimos e reformulações alternativas para aumentar recall:

- Fonte primária: GlossaryTerm do grafo (sinônimos controlados)
- Fonte secundária: LLM para gerar paráfrase (se necessário)
- Máximo de expansões: 3 (evitar explosão de buscas)
- Cada expansão é usada como query adicional na busca vetorial, resultados incluídos na fusão RRF

### Query Decomposition (Decomposição)

Decompõe queries complexas com múltiplas sub-perguntas em sub-queries atômicas processadas independentemente.

**Critérios de ativação**: query >20 tokens, contém "e"/"ou" conectando temas distintos, pede informações de natureza diferente.

**Exemplo**: "Quem é o responsável pelo módulo de cobrança e quais dependências ele tem?" -> sub-query 1: "Quem é o responsável pelo módulo de cobrança?" + sub-query 2: "Quais são as dependências do módulo de cobrança?"

## Filtragem Temporal

O conhecimento corporativo muda ao longo do tempo. O sistema suporta consultas históricas:

1. **Detecção de contexto temporal na query**: datas explícitas, palavras-chave temporais ("anterior", "histórico", "antes de"), comparações
2. **Aplicação do filtro**: `valid_from <= data_referencia` e `valid_until >= data_referencia OU IS NULL`
3. **Instrução ao agente**: sempre citar período de vigência, mencionar versões anteriores, alertar sobre expiração
4. **Sem contexto temporal detectado**: assume data atual, exclui documentos deprecated

## Filtro de Segurança Pré-Retrieval

O filtro de segurança **SEMPRE** é aplicado **ANTES** de qualquer busca. NUNCA confiar no prompt ou no pós-processamento para filtrar informação confidencial.

**Níveis de confidencialidade** (conforme [[ADR-004]]):

| Nível | Acesso |
|-------|--------|
| public | Todos os usuários |
| internal | Usuários autenticados |
| restricted | Usuários com role "restricted" OU do team owner |
| confidential | Usuários explicitamente listados no access_list |

**Regra de Ouro**: "Se o filtro de segurança falhar, o sistema DEVE retornar **ZERO resultados** — NUNCA resultados sem filtro." Fail-closed, não fail-open.

O filtro é aplicado em TODAS as 3 buscas. Na Graph Search, documentos com confidencialidade acima do nível do usuário são tratados como **inexistentes** (não navegáveis, relações cortadas). O usuário não sabe que o documento existe.

**Auditoria**: toda query é logada com `user_id`, níveis solicitados/aplicados, quantidade de chunks filtrados e timestamp.

## Montagem de Contexto para o LLM

Os top-K chunks (5-10) após reranking compõem o contexto do prompt:

- Texto do chunk com origem (documento, sistema, módulo)
- Score de relevância (para transparência)
- Caminho no grafo (se encontrado via Graph Search)
- Instruções ao LLM: citar origem documental, indicar nível de confiança, alertar sobre informação desatualizada, não inventar além do contexto

Se contexto temporal presente: filtrar por `valid_from`/`valid_until`, instruir LLM a citar período de vigência. Sem contexto temporal: assumir data atual, excluir deprecated.

**Métricas do pipeline**:

| Métrica | Alvo |
|---|---|
| Latência end-to-end | < 2 segundos |
| Latência dispatcher | < 100ms |
| Latência query rewriting | < 50ms (regras), < 2s (LLM) |
| Latência buscas paralelas | < 500ms (timeout por busca) |
| Latência RRF | < 10ms |
| Latência reranking | < 500ms GPU, < 2s CPU |
| Recall@10 (golden set) | >= 70% (MVP), >= 85% (Prod) |

## Agentes Especializados

### Architecture Agent

- **Propósito**: responder perguntas sobre decisões arquiteturais, trade-offs, dependências entre sistemas/módulos, evolução técnica
- **Público**: desenvolvedores, tech leads, arquitetos
- **Filtros**: `doc_type IN ["architecture-doc", "adr", "system-doc"]`
- **Relações priorizadas**: `DEPENDS_ON`, `BELONGS_TO`, `DECIDES`, `REFERENCES`, `SUPERSEDES`
- **System prompt**: arquiteto de software sênior, profundidade técnica, citar ADRs, trade-offs, dependências e impactos, versões anteriores. Nunca inventar informação, citar origem, alertar sobre deprecated.
- **Exemplos de queries**: "Qual ADR decidiu sobre o banco?", "Quais módulos dependem do autenticação?", "Trade-offs do Neo4j?"

### Operations Agent

- **Propósito**: responder perguntas operacionais — procedimentos, comandos, deploy, incidentes
- **Público**: engenheiros de operações, SREs, desenvolvedores em contexto de incidente
- **Filtros**: `doc_type IN ["runbook", "glossary", "task-doc", "system-doc"]`
- **Relações priorizadas**: `BELONGS_TO` (módulo), `IMPLEMENTS`, `RELATES_TO_TASK`
- **System prompt**: engenheiro de operações sênior, passos numerados, comandos exatos, avisos de segurança, pré-requisitos, rollback. Nunca sugerir comandos não encontrados na documentação.
- **Exemplos de queries**: "Como fazer deploy do módulo X?", "Procedimento de rollback?", "O que significa 'liquidação'?"

### Business Agent

- **Propósito**: responder perguntas de negócio — responsabilidades, regras vigentes, glossário, estrutura organizacional
- **Público**: gestores, analistas de negócio, executivos
- **Filtros**: `domain` filtrado conforme query (filtra por DOMÍNIO em vez de `doc_type`)
- **Relações priorizadas**: `OWNED_BY`, `MEMBER_OF`, `USES_TERM`, `BELONGS_TO`
- **System prompt**: analista de negócios sênior, linguagem acessível, regras com vigência, responsáveis, glossário corporativo. Nunca inventar regras, citar fonte, apresentar ambas versões em caso de conflito.
- **Exemplos de queries**: "Quem cuida do sistema de pagamentos?", "O que significa 'remessa bancária'?", "Regras de cancelamento de boleto?"

### Tabela consolidada dos agentes

| Aspecto | Architecture | Operations | Business |
|---|---|---|---|
| Público | Devs, Arquitetos | SREs, Ops | Gestores, Analistas |
| Filtro | arch-doc, adr, sys-doc | runbook, glossary, task-doc, sys-doc | (por domínio) |
| Relações prio | DEPENDS_ON, DECIDES, REFERENCES | BELONGS_TO, IMPLEMENTS, RELATES_TO_TASK | OWNED_BY, MEMBER_OF, USES_TERM |
| Tom | Técnico | Direto/executável | Acessível |
| Formato | Análise + refs | Passos numerados | Resumo + contexto |

### Dispatcher (Roteador)

Classifica a intenção da query via LLM com few-shot examples:

| Intenção | Critérios | Agente |
|---|---|---|
| architecture | ADR, decisão, trade-off, dependência, arquitetura, tecnologia | Architecture Agent |
| operations | deploy, procedimento, comando, restart, rollback, incidente, runbook | Operations Agent |
| business | responsável, dono, time, regra de negócio, glossário, organização | Business Agent |
| ambiguous | não se encaixa claramente OU confiança < 0.7 | Todos (fallback) |

**Configuração**: LLM leve (GPT-4o-mini ou Llama 3.1 8B), latência <100ms, cache de 5 minutos, confidence threshold 0.7, mínimo 5 few-shot examples por categoria.

**Fallback (ambiguous)**: acionar TODOS os agentes em paralelo, fusão via RRF adicional. Trade-off: ~3x latência, mas evita perda por classificação incorreta.

**Métricas**: acurácia de classificação >85%, % fallback <20%, latência média <100ms, cache hit rate >30%.

### Evolução futura

Novos agentes podem ser adicionados conforme a base cresce:

| Agente potencial | Domínio | Gatilho |
|---|---|---|
| Compliance Agent | Regulatório (BACEN, CVM, LGPD) | Docs de compliance ingeridos |
| Onboarding Agent | Integração de novos colaboradores | Cobertura de processos > 80% |
| Incident Agent | Post-mortem e troubleshooting | Runbooks de incidentes catalogados |

## Feedback Loop

### Avaliação do Usuário

Após cada resposta: polegar cima/baixo (obrigatório, binário) + comentário livre (opcional). Cada avaliação armazena: `feedback_id`, `query`, `query_rewritten`, `agent_used`, `dispatcher_intent`, `chunks_returned`, `chunks_scores`, `response_text`, `rating`, `comment`, `user_id`, `timestamp`.

Armazenamento em coleção dedicada, separada do índice vetorial. Retenção mínima: 12 meses. Não excluir feedbacks negativos.

### Detecção de Gaps de Conhecimento

**Critérios de detecção**:

1. **Zero resultados**: query retorna 0 chunks ou score RRF abaixo do threshold mínimo
2. **Resultados de baixa qualidade**: top-K chunks com score de reranking < 0.3
3. **Feedback negativo recorrente**: mesma query recebe avaliação negativa 3+ vezes

**Classificação**:

| Nível | Critério | Ação |
|---|---|---|
| Suspeito | 1 ocorrência de zero resultado | Registrar para monitoramento |
| Provável | 2 ocorrências ou feedback negativo | Adicionar à fila de revisão |
| Confirmado | 3+ ocorrências da mesma query | Alerta ao time de governança |

**Promoção de gap confirmado**: gerar alerta automático (email/Slack/ClickUp) com query original, frequência, perfis afetados. Time decide: criar documento, expandir existente ou marcar "fora de escopo".

### Revisão de Respostas Mal Avaliadas

**Triagem automática** (para cada feedback negativo):

1. Relevância dos chunks retornados
2. Recall de chunks existentes (busca exaustiva sem HNSW para comparar)
3. Dispatch correto (intenção classificada corretamente?)
4. Reranking (chunks relevantes no top-K?)

**Classificação de causa raiz** (por humano, SLA: 48 horas úteis):

| Causa raiz | Descrição | Ação corretiva |
|---|---|---|
| Gap de conhecimento | Documento não existe | Criar documento |
| Problema de retrieval | Chunks existem mas não encontrados | Ajustar parâmetros de busca |
| Problema de reranking | Chunks encontrados mas mal posicionados | Ajustar reranker ou golden set |
| Problema de prompt | Chunks corretos mas LLM gerou resposta ruim | Ajustar system prompt |
| Dispatch incorreto | Query para agente errado | Adicionar few-shot example |
| Documento desatualizado | Conteúdo obsoleto | Atualizar na fonte (Git) |
| Fora de escopo | Pergunta fora do domínio coberto | Documentar como fora de escopo |

### Métricas de Qualidade

Dashboard semanal obrigatório:

| Métrica | Meta |
|---|---|
| % respostas com feedback positivo | > 80% |
| Taxa de gaps confirmados (por semana) | < 5 novos gaps |
| Recall@10 no golden set | >= threshold da fase atual |
| Latência end-to-end (p95) | < 3 segundos |
| Distribuição por agente | Monitorar desbalanceamento |

Métricas detalhadas: top-10 queries mais frequentes, top-10 queries com pior avaliação, top-10 gaps pendentes, distribuição por agente e perfil, tendência semanal de satisfação, tempo médio de resolução de gaps.

**Alertas automáticos**: degradação de satisfação (<70%), pico de gaps (>10/semana), degradação de recall, latência p95 >5s, agente com <60% positivos.

### Ciclo de Melhoria Contínua

- **Diário**: monitorar dashboard, triagem automática de feedbacks negativos
- **Semanal**: reunião de revisão (15 min), priorizar ações corretivas, atualizar golden set
- **Mensal**: análise de tendências, revisar parâmetros do pipeline
- **Trimestral**: benchmark de modelos, revisão completa do golden set

**Atualização do golden set**: artefato vivo, crescer ~10-20 pares/mês até 200+. Incluir queries reais com feedback negativo, novos domínios, gaps resolvidos.

### Integração com Governança

O feedback loop alimenta diretamente o processo de governança ([[ADR-008]]): feedback negativo -> detecção de gap -> alerta -> criar/atualizar documento -> pipeline de maturidade (.txt -> .beta.md -> .md -> ingestão) -> re-execução da query -> ciclo fechado. O feedback é a principal fonte de DEMANDA para novos documentos.

### Privacidade e Ética

- Feedbacks associados a `user_id` para análise por perfil, mas NUNCA expostos individualmente (apenas agregados)
- Comentários podem conter dados sensíveis: aplicar mesma política de confidencialidade
- Não usar feedback para avaliação de desempenho individual
- Anonimizar dados em relatórios compartilhados externamente

## Alternativas Descartadas

| Alternativa | Motivo da rejeição |
|-------------|-------------------|
| Busca vetorial pura | Falha para termos exatos, não navega relações |
| Busca keyword pura (BM25) | Não entende semântica, não tolera sinônimos |
| Reranking com LLM generativo | Latência 2-5s vs 200ms do cross-encoder |
| Agente único generalista | Resultados diluídos, instruções genéricas |
| Fusão por weighted average | Normalização frágil, pesos fixos |
| Query rewriting sem expansion | Melhora precisão mas não recall |

## Consequências

### Positivas

- Retrieval híbrido cobre todos os tipos de perguntas (semânticas, exatas, relacionais)
- RRF combina resultados sem necessidade de normalização de scores
- Reranking melhora qualidade do top-K em 10-30%
- Filtragem temporal permite consultas históricas
- Segurança pré-retrieval garante zero vazamento de dados confidenciais
- Agentes especializados maximizam precisão por domínio
- Feedback loop identifica gaps e permite melhoria contínua

### Negativas / Trade-offs

- **Latência**: ~500-1000ms (híbrido completo) vs ~50ms (vetorial pura) — trade-off aceito: qualidade >>> velocidade
- **Complexidade**: 3 buscas + fusão + reranking + 3 agentes + dispatcher
- **Custo**: reranking cloud (Track A) tem custo por query; local (Track B) exige GPU
- **Dispatcher pode errar**: classificação incorreta direciona para agente errado; fallback mitiga

### Riscos

- **Modelo de embedding degrada**: mitigação via golden set semanal com alerta
- **Grafo incompleto**: mitigação via verificação de consistência ([[ADR-006]], Etapa 7)
- **Feedback enviesado**: mitigação via revisão humana de amostra + golden set
- **Latência em pico**: mitigação via timeout por busca (500ms) + resultados parciais

## Implementação (Faseamento)

| Fase | Entregas |
|------|----------|
| Fase 1 (MVP) | Busca vetorial simples, sem reranking, sem agentes, filtro de segurança básico |
| Fase 2 (Metadados) | Filtros por system/module/domain, segurança completa (4 níveis), filtragem temporal básica |
| Fase 3 (Knowledge Graph) | Busca por grafo, RRF (vetor + grafo), query rewriting básico |
| Fase 4 (GraphRAG Corporativo) | Busca keyword, RRF completo, reranking, agentes + dispatcher, feedback loop, dashboard |

## Referências

- [[ADR-001]]: Pipeline de Geração de Conhecimento em 4 Fases
- [[ADR-002]]: Soberania de Dados (Track A/B)
- [[ADR-003]]: Modelo de Dados da Base Vetorial
- [[ADR-004]]: Segurança e Classificação de Dados
- [[ADR-005]]: Front Matter Obrigatório
- [[ADR-006]]: Pipeline de Ingestão
- [[ADR-008]]: Governança (ciclo de vida, feedback loop)
- [[ADR-009]]: Seleção de Modelos de Embedding e Reranking
- Cormack, Clarke, Buettcher (2009). "Reciprocal Rank Fusion outperforms Condorcet and individual Rank Learning Methods"
- Nogueira, Cho (2019). "Passage Re-ranking with BERT"
- Malkov, Yashunin (2018). "Efficient and robust approximate nearest neighbor search using HNSW graphs"
- Robertson, Zaragoza (2009). "The Probabilistic Relevance Framework: BM25 and Beyond"

<!-- conversion_quality: 95 -->
