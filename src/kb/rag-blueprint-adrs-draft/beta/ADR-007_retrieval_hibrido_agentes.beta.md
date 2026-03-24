---
id: BETA-007
title: "Retrieval Hibrido e Agentes Especializados"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-G01_estrategias_busca.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-G02_pipeline_query.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-G03_catalogo_agentes.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-G04_feedback_loop.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags: [retrieval hibrido, busca vetorial, busca keyword, busca grafo, rrf, reciprocal rank fusion, reranking, cross-encoder, agentes especializados, dispatcher, classificacao intencao, query rewriting, query expansion, query decomposition, filtro seguranca, filtragem temporal, similaridade coseno, bm25 full-text, graph search, navegacao relacional, hnsw, architecture agent, operations agent, business agent, feedback loop, gap conhecimento, golden set, recall, metricas qualidade, dashboard semanal, perfis consumo, dual track, cohere rerank, bge-reranker, system prompt, few-shot examples, filtro confidencialidade, fail-closed, stemming portugues, sinonimos glossario, chunks ranqueados, latencia busca, fallback ambiguous, melhoria continua, deteccao gaps, causa raiz, triagem automatica, auditoria query, privacidade feedback, ciclo curadoria, ndcg, score unificado, contexto llm]
aliases:
  - "ADR-007"
  - "Retrieval Hibrido"
  - "Busca Hibrida"
  - "Agentes Especializados"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

# ADR-007 — Retrieval Hibrido e Agentes Especializados

## Referencias Cruzadas

- **Depende de:** [[BETA-001]], [[BETA-002]], [[BETA-003]], [[BETA-004]]
- **Relaciona-se:** [[BETA-005]], [[BETA-006]], [[BETA-009]]

## Contexto

### Posicao no Pipeline de 4 Fases

Esta ADR atua na **Fase 4 — Geracao do RAG (Camada Ouro)**. O pipeline de 4 fases definido na [[BETA-001]] estabelece:

- Fase 1: Selecao de insumos
- Fase 2: Mineracao e edicao (`.beta.md` no rag-workspace)
- Fase 3: Promocao para `.md` final (rag-knowledge-base, imutavel)
- Fase 4: Ingestao na Base Vetorial e CONSUMO via retrieval

Este ADR define COMO o conhecimento ingerido na Fase 4 e recuperado e entregue aos consumidores (humanos e agentes de IA). O `.md` final gerado na Fase 3 (fonte da verdade, nunca editado manualmente) e a origem dos dados que a busca hibrida consulta.

### Por que Busca Vetorial Simples NAO e Suficiente

A Base Vetorial, populada pelo pipeline definido na [[BETA-006]], contem nos `:Document` com metadados ricos, nos `:Chunk` com embeddings vetoriais e conteudo textual, grafo de relacoes e indices vetoriais, full-text e compostos.

A busca vetorial (similaridade coseno) e excelente para perguntas conceituais e semanticas, porem tem limitacoes criticas em ambiente corporativo:

1. **Termos exatos**: nao garante match de termos literais como "BACEN 4893" ou "SKU-12345"
2. **Relacoes estruturais**: nao navega relacoes `DEPENDS_ON` entre modulos
3. **Codigos e siglas**: embeddings tratam codigos como texto generico, sem discriminacao fina
4. **Contexto organizacional**: perguntas como "quem e responsavel pelo sistema X?" sao de GRAFO, nao de similaridade textual

### Perfis de Consumo

| Perfil | Necessidade | Tipo de resposta |
|--------|-------------|------------------|
| Desenvolvedores | Detalhes tecnicos, APIs, dependencias | Precisa, com links para fonte |
| Tech Leads / Arquitetos | Decisoes (ADRs), trade-offs, dependencias | Contexto amplo |
| Gestores / Executivos | Visao macro, status, responsaveis | Resumida e confiante |
| Agentes de IA | Chunks bem ranqueados e contextualizados | Estruturada para LLM |

<!-- LOCKED:START autor=fabio data=2026-03-23 -->

## Decisao — Busca Hibrida (3 Buscas Paralelas + RRF)

A estrategia de retrieval combina **3 tipos de busca executados em PARALELO**, cujos resultados sao fundidos via **Reciprocal Rank Fusion (RRF)** e re-ranqueados por cross-encoder para produzir a lista final de chunks mais relevantes.

Cada tipo de busca tem forcas e fraquezas complementares. Nenhuma isoladamente cobre todos os cenarios de perguntas corporativas. A combinacao das 3 buscas maximiza o recall sem sacrificar excessivamente a precisao.

**Tratamento de falhas**: se uma das 3 buscas falhar (timeout, erro de indice, indisponibilidade), o sistema DEVE continuar com as buscas restantes. O RRF opera sobre 2 listas em vez de 3 — a qualidade degrada graciosamente. Se TODAS as 3 buscas falharem, retornar erro explicito ao usuario. Cada falha e registrada em log.

### Busca 1 — Vector Search (Semantica)

**Como funciona**:

1. Recebe a query do usuario em linguagem natural
2. Gera embedding da query usando o **mesmo modelo** dos chunks (critico: modelos diferentes = espacos incompativeis)
3. Busca os top-K chunks mais proximos por similaridade coseno no indice vetorial HNSW
4. Retorna lista de chunks com score de similaridade (0.0 a 1.0)

A similaridade coseno mede o angulo entre dois vetores no espaco de 1024 dimensoes. Quanto mais proximo de 1.0, mais semanticamente similar.

**Parametros**:

| Parametro | Valor padrao | Descricao |
|---|---|---|
| K (top resultados) | 20 | Numero de chunks retornados (configuravel) |
| similaridade_minima | 0.5 | Score abaixo disso e descartado |
| ef_search | 100 | Qualidade da busca HNSW (maior = melhor, mais lento) |
| modelo_embedding | BGE-M3 | Obrigatorio: mesmo modelo de indexacao e query |
| prefixo_query | sim | Prefixo de instrucao para busca assimetrica |

**Pontos fortes**: entende semantica, sinonimos, tolera erros de digitacao, suporte multilingual, eficiente para perguntas conceituais, latencia ~10-50ms para 50K chunks com HNSW.

**Pontos fracos**: nao garante match de termos exatos ("BACEN 4893"), tende a generalizar, codigos e siglas tratados como texto generico, nao navega relacoes, sensivel a qualidade do modelo.

**Cenarios ideais**: perguntas conceituais, exploratorias, sobre processos e regras.

### Busca 2 — Keyword Search (Full-Text / BM25)

**Como funciona**:

1. Executa busca full-text no indice de `Chunk.content`
2. Usa analisador com suporte a portugues: tokenizacao, stemming ("cobrancas" -> "cobranc"), stopwords
3. Ranqueia resultados pelo algoritmo BM25 (frequencia do termo, IDF, normalizacao por comprimento)
4. Retorna chunks ordenados por relevancia BM25

**Parametros**:

| Parametro | Valor padrao | Descricao |
|---|---|---|
| max_resultados | 20 | Numero maximo de chunks retornados |
| operador | OR | OR entre termos, com boost para AND |
| analisador | pt-BR | Analisador com stemming portugues |
| boost_AND | 2.0 | Multiplicador para match de todos os termos |
| min_score | 0.1 | Score BM25 minimo para inclusao |

**Pontos fortes**: match exato de termos, codigos, identificadores ("SKU-12345", "CU-4567"), nomes proprios, siglas tecnicas ("LGPD", "PIX"), deterministico, rapido (< 10ms).

**Pontos fracos**: nao entende semantica ("cancelar" NAO encontra "estornar"), nao tolera erros de digitacao, sensivel a vocabulario, nao entende contexto ("banco" financeiro vs "banco" de dados).

**Cenarios ideais**: buscas com codigos, IDs, nomes exatos, siglas, resolucoes regulatorias.

### Busca 3 — Graph Search (Navegacao Relacional)

**Como funciona**:

1. Identifica **entidades** mencionadas na query: sistemas (System), modulos (Module), pessoas (Owner), times (Team), termos (GlossaryTerm), tarefas (Task)
2. Navega o grafo a partir das entidades identificadas, seguindo relacoes: `BELONGS_TO`, `DEPENDS_ON`, `OWNED_BY`, `MEMBER_OF`, `REFERENCES`, `SUPERSEDES`, `IMPLEMENTS`, `DECIDES`, `USES_TERM`
3. Coleta chunks dos documentos encontrados via navegacao
4. Retorna chunks com contexto relacional (qual caminho levou ao chunk)

**Parametros**:

| Parametro | Valor padrao | Descricao |
|---|---|---|
| profundidade | 2 hops | Distancia maxima de navegacao no grafo |
| max_docs_por_navegacao | 10 | Maximo de documentos coletados por caminho |
| relacoes_priorizadas | depende do agente | Quais relacoes seguir (configuravel) |
| timeout | 500ms | Timeout para evitar travessias longas |

**Pontos fortes**: descobre relacoes estruturais ("quais modulos dependem do Cobranca?"), contexto organizacional, versionamento, impacto de mudancas, respostas com rastreabilidade (caminho no grafo).

**Pontos fracos**: depende de entidades existentes no grafo, mais lento que vetorial e BM25, qualidade depende da completude do grafo, identificacao de entidades pode falhar (NER imperfeito), profundidade > 2 hops pode gerar ruido.

**Cenarios ideais**: perguntas sobre estrutura, dependencias, responsabilidades, versionamento, impacto.

### Complementaridade das 3 Buscas

| Tipo de pergunta | Vetor | Keyword | Grafo |
|---|---|---|---|
| Conceitual/semantica | +++ | - | + |
| Termo exato/codigo | - | +++ | + |
| Relacao estrutural | - | - | +++ |
| Sinonimos | +++ | - | - |
| Nomes proprios | + | +++ | ++ |
| Dependencias entre modulos | - | - | +++ |
| Pergunta mista | ++ | ++ | ++ |

### Fusao — Reciprocal Rank Fusion (RRF)

As 3 buscas retornam listas com sistemas de scoring incompativeis (coseno 0-1, BM25 0-infinito, grafo sem score). O RRF converte **posicoes em ranking** em score unificado:

```
score_RRF(d) = SUM( 1 / (k + rank_i(d)) )  para cada busca i
```

Onde `k=60` (constante de suavizacao do paper original de Cormack, Clarke e Buettcher, 2009). Se o documento nao aparece na lista `i`, `rank_i(d) = infinito` (contribuicao zero).

**Exemplo**: Chunk C-042 aparece na posicao 3 na busca vetorial (`1/(60+3) = 0.0159`), posicao 1 na keyword (`1/(60+1) = 0.0164`), nao aparece no grafo (0). Score RRF = 0.0323.

**Vantagens**: nao requer normalizacao de scores, agnostico ao tipo de busca, robusto com 1-3 listas, sem parametros de peso.

**Saida**: lista unificada de chunks ordenados por score_RRF decrescente. Os top ~50 candidatos seguem para Reranking.

### Reranking (Cross-Encoder)

Um cross-encoder recebe query E chunk como entrada UNICA e produz score de relevancia com atencao cruzada token a token. Diferente do bi-encoder (vetores separados comparados por coseno), o cross-encoder processa query+chunk juntos, capturando negacoes, contexto condicional e parafrases precisas.

**Fluxo**: top ~50 candidatos do RRF -> cross-encoder -> re-ordenacao -> top-K final (K=5 a K=10).

**Dual-track** (conforme [[BETA-002]] e [[BETA-009]]):

| Track | Modelo | Custo | Latencia | Restricao |
|-------|--------|-------|----------|-----------|
| A — Cloud | Cohere Rerank v3 | ~$2/1.000 buscas | ~200ms/batch 50 | Apenas public/internal |
| B — On-premises | BGE-Reranker-v2-m3 | Zero | ~500ms GPU, ~2s CPU | Obrigatorio para restricted/confidential |

**Ganho esperado**: melhora qualidade do top-K em 10-30% (medido por nDCG@10).

<!-- LOCKED:END -->

## Pipeline de Processamento de Query

Antes das 3 buscas, a query passa por pre-processamento em 9 etapas:

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
(7) Fusao via RRF
     |
(8) Reranking (cross-encoder)
     |
(9) Montagem de contexto para o LLM
     |
[Resposta ao usuario]
```

### Query Rewriting (Reformulacao)

Um LLM reformula queries vagas em versoes mais precisas. Duas abordagens complementares:

**Abordagem 1 — Regras (sempre executa primeiro)**:
- Expandir siglas conhecidas do glossario (ex: "BACEN" -> "Banco Central do Brasil (BACEN)")
- Adicionar sinonimos do GlossaryTerm (ex: "boleto" + "titulo de cobranca")
- Latencia: < 10ms
- Cobertura: resolve >70% das queries

**Abordagem 2 — LLM (acionado sob demanda)**:
- Ativado quando resultados da busca com regras sao insuficientes (< 3 resultados com score > 0.5)
- Track A (Cloud): GPT-4o-mini ou equivalente (< 200ms)
- Track B (On-prem): Llama 3.1 8B ou Qwen via Ollama (timeout 5s)
- Meta: < 30% das queries precisam de LLM

A query original E a reformulada sao ambas usadas nas buscas (evita perda por distorcao).

**Metricas-alvo**: >70% queries resolvidas por regras, <30% com fallback LLM, latencia media <50ms (regras) / <2s (LLM).

### Query Expansion (Expansao)

Gera 2-3 variacoes da query cobrindo sinonimos e reformulacoes alternativas para aumentar recall:

- Fonte primaria: GlossaryTerm do grafo (sinonimos controlados)
- Fonte secundaria: LLM para gerar parafrase (se necessario)
- Maximo de expansoes: 3 (evitar explosao de buscas)
- Cada expansao e usada como query adicional na busca vetorial, resultados incluidos na fusao RRF

### Query Decomposition (Decomposicao)

Decompoe queries complexas com multiplas sub-perguntas em sub-queries atomicas processadas independentemente.

**Criterios de ativacao**: query >20 tokens, contem "e"/"ou" conectando temas distintos, pede informacoes de natureza diferente.

**Exemplo**: "Quem e o responsavel pelo modulo de cobranca e quais dependencias ele tem?" -> sub-query 1: "Quem e o responsavel pelo modulo de cobranca?" + sub-query 2: "Quais sao as dependencias do modulo de cobranca?"

## Filtragem Temporal

O conhecimento corporativo muda ao longo do tempo. O sistema suporta consultas historicas:

1. **Deteccao de contexto temporal na query**: datas explicitas, palavras-chave temporais ("anterior", "historico", "antes de"), comparacoes
2. **Aplicacao do filtro**: `valid_from <= data_referencia` e `valid_until >= data_referencia OU IS NULL`
3. **Instrucao ao agente**: sempre citar periodo de vigencia, mencionar versoes anteriores, alertar sobre expiracao
4. **Sem contexto temporal detectado**: assume data atual, exclui documentos deprecated

## Filtro de Seguranca Pre-Retrieval

O filtro de seguranca **SEMPRE** e aplicado **ANTES** de qualquer busca. NUNCA confiar no prompt ou no pos-processamento para filtrar informacao confidencial.

**Niveis de confidencialidade** (conforme [[BETA-004]]):

| Nivel | Acesso |
|-------|--------|
| public | Todos os usuarios |
| internal | Usuarios autenticados |
| restricted | Usuarios com role "restricted" OU do team owner |
| confidential | Usuarios explicitamente listados no access_list |

**Regra de Ouro**: "Se o filtro de seguranca falhar, o sistema DEVE retornar **ZERO resultados** — NUNCA resultados sem filtro." Fail-closed, nao fail-open.

O filtro e aplicado em TODAS as 3 buscas. Na Graph Search, documentos com confidencialidade acima do nivel do usuario sao tratados como **inexistentes** (nao navegaveis, relacoes cortadas). O usuario nao sabe que o documento existe.

**Auditoria**: toda query e logada com `user_id`, niveis solicitados/aplicados, quantidade de chunks filtrados e timestamp.

## Montagem de Contexto para o LLM

Os top-K chunks (5-10) apos reranking compoe o contexto do prompt:

- Texto do chunk com origem (documento, sistema, modulo)
- Score de relevancia (para transparencia)
- Caminho no grafo (se encontrado via Graph Search)
- Instrucoes ao LLM: citar origem documental, indicar nivel de confianca, alertar sobre informacao desatualizada, nao inventar alem do contexto

Se contexto temporal presente: filtrar por `valid_from`/`valid_until`, instruir LLM a citar periodo de vigencia. Sem contexto temporal: assumir data atual, excluir deprecated.

**Metricas do pipeline**:

| Metrica | Alvo |
|---|---|
| Latencia end-to-end | < 2 segundos |
| Latencia dispatcher | < 100ms |
| Latencia query rewriting | < 50ms (regras), < 2s (LLM) |
| Latencia buscas paralelas | < 500ms (timeout por busca) |
| Latencia RRF | < 10ms |
| Latencia reranking | < 500ms GPU, < 2s CPU |
| Recall@10 (golden set) | >= 70% (MVP), >= 85% (Prod) |

## Agentes Especializados

### Architecture Agent

- **Proposito**: responder perguntas sobre decisoes arquiteturais, trade-offs, dependencias entre sistemas/modulos, evolucao tecnica
- **Publico**: desenvolvedores, tech leads, arquitetos
- **Filtros**: `doc_type IN ["architecture-doc", "adr", "system-doc"]`
- **Relacoes priorizadas**: `DEPENDS_ON`, `BELONGS_TO`, `DECIDES`, `REFERENCES`, `SUPERSEDES`
- **System prompt**: arquiteto de software senior, profundidade tecnica, citar ADRs, trade-offs, dependencias e impactos, versoes anteriores. Nunca inventar informacao, citar origem, alertar sobre deprecated.
- **Exemplos de queries**: "Qual ADR decidiu sobre o banco?", "Quais modulos dependem do autenticacao?", "Trade-offs do Neo4j?"

### Operations Agent

- **Proposito**: responder perguntas operacionais — procedimentos, comandos, deploy, incidentes
- **Publico**: engenheiros de operacoes, SREs, desenvolvedores em contexto de incidente
- **Filtros**: `doc_type IN ["runbook", "glossary", "task-doc", "system-doc"]`
- **Relacoes priorizadas**: `BELONGS_TO` (modulo), `IMPLEMENTS`, `RELATES_TO_TASK`
- **System prompt**: engenheiro de operacoes senior, passos numerados, comandos exatos, avisos de seguranca, pre-requisitos, rollback. Nunca sugerir comandos nao encontrados na documentacao.
- **Exemplos de queries**: "Como fazer deploy do modulo X?", "Procedimento de rollback?", "O que significa 'liquidacao'?"

### Business Agent

- **Proposito**: responder perguntas de negocio — responsabilidades, regras vigentes, glossario, estrutura organizacional
- **Publico**: gestores, analistas de negocio, executivos
- **Filtros**: `domain` filtrado conforme query (filtra por DOMINIO em vez de `doc_type`)
- **Relacoes priorizadas**: `OWNED_BY`, `MEMBER_OF`, `USES_TERM`, `BELONGS_TO`
- **System prompt**: analista de negocios senior, linguagem acessivel, regras com vigencia, responsaveis, glossario corporativo. Nunca inventar regras, citar fonte, apresentar ambas versoes em caso de conflito.
- **Exemplos de queries**: "Quem cuida do sistema de pagamentos?", "O que significa 'remessa bancaria'?", "Regras de cancelamento de boleto?"

### Tabela consolidada dos agentes

| Aspecto | Architecture | Operations | Business |
|---|---|---|---|
| Publico | Devs, Arquitetos | SREs, Ops | Gestores, Analistas |
| Filtro | arch-doc, adr, sys-doc | runbook, glossary, task-doc, sys-doc | (por dominio) |
| Relacoes prio | DEPENDS_ON, DECIDES, REFERENCES | BELONGS_TO, IMPLEMENTS, RELATES_TO_TASK | OWNED_BY, MEMBER_OF, USES_TERM |
| Tom | Tecnico | Direto/executavel | Acessivel |
| Formato | Analise + refs | Passos numerados | Resumo + contexto |

### Dispatcher (Roteador)

Classifica a intencao da query via LLM com few-shot examples:

| Intencao | Criterios | Agente |
|---|---|---|
| architecture | ADR, decisao, trade-off, dependencia, arquitetura, tecnologia | Architecture Agent |
| operations | deploy, procedimento, comando, restart, rollback, incidente, runbook | Operations Agent |
| business | responsavel, dono, time, regra de negocio, glossario, organizacao | Business Agent |
| ambiguous | nao se encaixa claramente OU confianca < 0.7 | Todos (fallback) |

**Configuracao**: LLM leve (GPT-4o-mini ou Llama 3.1 8B), latencia <100ms, cache de 5 minutos, confidence threshold 0.7, minimo 5 few-shot examples por categoria.

**Fallback (ambiguous)**: acionar TODOS os agentes em paralelo, fusao via RRF adicional. Trade-off: ~3x latencia, mas evita perda por classificacao incorreta.

**Metricas**: acuracia de classificacao >85%, % fallback <20%, latencia media <100ms, cache hit rate >30%.

### Evolucao futura

Novos agentes podem ser adicionados conforme a base cresce:

| Agente potencial | Dominio | Gatilho |
|---|---|---|
| Compliance Agent | Regulatorio (BACEN, CVM, LGPD) | Docs de compliance ingeridos |
| Onboarding Agent | Integracao de novos colaboradores | Cobertura de processos > 80% |
| Incident Agent | Post-mortem e troubleshooting | Runbooks de incidentes catalogados |

## Feedback Loop

### Avaliacao do Usuario

Apos cada resposta: polegar cima/baixo (obrigatorio, binario) + comentario livre (opcional). Cada avaliacao armazena: `feedback_id`, `query`, `query_rewritten`, `agent_used`, `dispatcher_intent`, `chunks_returned`, `chunks_scores`, `response_text`, `rating`, `comment`, `user_id`, `timestamp`.

Armazenamento em colecao dedicada, separada do indice vetorial. Retencao minima: 12 meses. Nao excluir feedbacks negativos.

### Deteccao de Gaps de Conhecimento

**Criterios de deteccao**:

1. **Zero resultados**: query retorna 0 chunks ou score RRF abaixo do threshold minimo
2. **Resultados de baixa qualidade**: top-K chunks com score de reranking < 0.3
3. **Feedback negativo recorrente**: mesma query recebe avaliacao negativa 3+ vezes

**Classificacao**:

| Nivel | Criterio | Acao |
|---|---|---|
| Suspeito | 1 ocorrencia de zero resultado | Registrar para monitoramento |
| Provavel | 2 ocorrencias ou feedback negativo | Adicionar a fila de revisao |
| Confirmado | 3+ ocorrencias da mesma query | Alerta ao time de governanca |

**Promocao de gap confirmado**: gerar alerta automatico (email/Slack/ClickUp) com query original, frequencia, perfis afetados. Time decide: criar documento, expandir existente ou marcar "fora de escopo".

### Revisao de Respostas Mal Avaliadas

**Triagem automatica** (para cada feedback negativo):

1. Relevancia dos chunks retornados
2. Recall de chunks existentes (busca exaustiva sem HNSW para comparar)
3. Dispatch correto (intencao classificada corretamente?)
4. Reranking (chunks relevantes no top-K?)

**Classificacao de causa raiz** (por humano, SLA: 48 horas uteis):

| Causa raiz | Descricao | Acao corretiva |
|---|---|---|
| Gap de conhecimento | Documento nao existe | Criar documento |
| Problema de retrieval | Chunks existem mas nao encontrados | Ajustar parametros de busca |
| Problema de reranking | Chunks encontrados mas mal posicionados | Ajustar reranker ou golden set |
| Problema de prompt | Chunks corretos mas LLM gerou resposta ruim | Ajustar system prompt |
| Dispatch incorreto | Query para agente errado | Adicionar few-shot example |
| Documento desatualizado | Conteudo obsoleto | Atualizar na fonte (Git) |
| Fora de escopo | Pergunta fora do dominio coberto | Documentar como fora de escopo |

### Metricas de Qualidade

Dashboard semanal obrigatorio:

| Metrica | Meta |
|---|---|
| % respostas com feedback positivo | > 80% |
| Taxa de gaps confirmados (por semana) | < 5 novos gaps |
| Recall@10 no golden set | >= threshold da fase atual |
| Latencia end-to-end (p95) | < 3 segundos |
| Distribuicao por agente | Monitorar desbalanceamento |

Metricas detalhadas: top-10 queries mais frequentes, top-10 queries com pior avaliacao, top-10 gaps pendentes, distribuicao por agente e perfil, tendencia semanal de satisfacao, tempo medio de resolucao de gaps.

**Alertas automaticos**: degradacao de satisfacao (<70%), pico de gaps (>10/semana), degradacao de recall, latencia p95 >5s, agente com <60% positivos.

### Ciclo de Melhoria Continua

- **Diario**: monitorar dashboard, triagem automatica de feedbacks negativos
- **Semanal**: reuniao de revisao (15 min), priorizar acoes corretivas, atualizar golden set
- **Mensal**: analise de tendencias, revisar parametros do pipeline
- **Trimestral**: benchmark de modelos, revisao completa do golden set

**Atualizacao do golden set**: artefato vivo, crescer ~10-20 pares/mes ate 200+. Incluir queries reais com feedback negativo, novos dominios, gaps resolvidos.

### Integracao com Governanca

O feedback loop alimenta diretamente o processo de governanca ([[BETA-008]]): feedback negativo -> deteccao de gap -> alerta -> criar/atualizar documento -> pipeline de maturidade (.txt -> .beta.md -> .md -> ingestao) -> re-execucao da query -> ciclo fechado. O feedback e a principal fonte de DEMANDA para novos documentos.

### Privacidade e Etica

- Feedbacks associados a `user_id` para analise por perfil, mas NUNCA expostos individualmente (apenas agregados)
- Comentarios podem conter dados sensiveis: aplicar mesma politica de confidencialidade
- Nao usar feedback para avaliacao de desempenho individual
- Anonimizar dados em relatorios compartilhados externamente

## Alternativas Descartadas

| Alternativa | Motivo da rejeicao |
|-------------|-------------------|
| Busca vetorial pura | Falha para termos exatos, nao navega relacoes |
| Busca keyword pura (BM25) | Nao entende semantica, nao tolera sinonimos |
| Reranking com LLM generativo | Latencia 2-5s vs 200ms do cross-encoder |
| Agente unico generalista | Resultados diluidos, instrucoes genericas |
| Fusao por weighted average | Normalizacao fragil, pesos fixos |
| Query rewriting sem expansion | Melhora precisao mas nao recall |

## Consequencias

### Positivas

- Retrieval hibrido cobre todos os tipos de perguntas (semanticas, exatas, relacionais)
- RRF combina resultados sem necessidade de normalizacao de scores
- Reranking melhora qualidade do top-K em 10-30%
- Filtragem temporal permite consultas historicas
- Seguranca pre-retrieval garante zero vazamento de dados confidenciais
- Agentes especializados maximizam precisao por dominio
- Feedback loop identifica gaps e permite melhoria continua

### Negativas / Trade-offs

- **Latencia**: ~500-1000ms (hibrido completo) vs ~50ms (vetorial pura) — trade-off aceito: qualidade >>> velocidade
- **Complexidade**: 3 buscas + fusao + reranking + 3 agentes + dispatcher
- **Custo**: reranking cloud (Track A) tem custo por query; local (Track B) exige GPU
- **Dispatcher pode errar**: classificacao incorreta direciona para agente errado; fallback mitiga

### Riscos

- **Modelo de embedding degrada**: mitigacao via golden set semanal com alerta
- **Grafo incompleto**: mitigacao via verificacao de consistencia ([[BETA-006]], Etapa 7)
- **Feedback enviesado**: mitigacao via revisao humana de amostra + golden set
- **Latencia em pico**: mitigacao via timeout por busca (500ms) + resultados parciais

## Implementacao (Faseamento)

| Fase | Entregas |
|------|----------|
| Fase 1 (MVP) | Busca vetorial simples, sem reranking, sem agentes, filtro de seguranca basico |
| Fase 2 (Metadados) | Filtros por system/module/domain, seguranca completa (4 niveis), filtragem temporal basica |
| Fase 3 (Knowledge Graph) | Busca por grafo, RRF (vetor + grafo), query rewriting basico |
| Fase 4 (GraphRAG Corporativo) | Busca keyword, RRF completo, reranking, agentes + dispatcher, feedback loop, dashboard |

## Referencias

- [[BETA-001]]: Pipeline de Geracao de Conhecimento em 4 Fases
- [[BETA-002]]: Soberania de Dados (Track A/B)
- [[BETA-003]]: Modelo de Dados da Base Vetorial
- [[BETA-004]]: Seguranca e Classificacao de Dados
- [[BETA-005]]: Front Matter Obrigatorio
- [[BETA-006]]: Pipeline de Ingestao
- [[BETA-008]]: Governanca (ciclo de vida, feedback loop)
- [[BETA-009]]: Selecao de Modelos de Embedding e Reranking
- Cormack, Clarke, Buettcher (2009). "Reciprocal Rank Fusion outperforms Condorcet and individual Rank Learning Methods"
- Nogueira, Cho (2019). "Passage Re-ranking with BERT"
- Malkov, Yashunin (2018). "Efficient and robust approximate nearest neighbor search using HNSW graphs"
- Robertson, Zaragoza (2009). "The Probabilistic Relevance Framework: BM25 and Beyond"

<!-- conversion_quality: 95 -->
