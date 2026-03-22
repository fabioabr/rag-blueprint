---
id: BETA-007
title: "Retrieval Híbrido e Agentes Especializados"
domain: "arquitetura"
confidentiality: internal
sources:
  - type: "txt"
    origin: "Arquitetura/rag-blueprint/kb/rag-blueprint-adrs-kb/1 - draft/ADR-007_retrieval_hibrido_agentes.txt"
    captured_at: "2026-03-21"
tags: [retrieval, busca-hibrida, agentes, reranking, rrf, seguranca, filtragem-temporal, query-processing, feedback-loop, rag, base-vetorial]
aliases: ["ADR-007", "Retrieval Híbrido"]
status: approved
last_enrichment: "2026-03-22"
last_human_edit: "2026-03-22"
---

# ADR-007 — Retrieval Híbrido e Agentes Especializados

## Referências Cruzadas

- **Depende de:** [[BETA-001]], [[BETA-002]], [[BETA-003]], [[BETA-004]]
- **Relaciona-se:** [[BETA-005]], [[BETA-006]], [[BETA-009]]

## Contexto

### Posição no Pipeline de 4 Fases

Esta ADR atua na **Fase 4 — Geração do RAG (Camada Ouro)**. O pipeline de 4 fases definido na [[BETA-001]] estabelece:

- Fase 1: Seleção de insumos
- Fase 2: Mineração e edição (.beta.md no rag-workspace)
- Fase 3: Promoção para .md final (rag-knowledge-base, imutável)
- Fase 4: Ingestão na Base Vetorial e CONSUMO via retrieval

Este ADR define COMO o conhecimento ingerido na Fase 4 é recuperado e entregue aos consumidores (humanos e agentes de IA). O .md final gerado na Fase 3 (fonte da verdade, nunca editado manualmente) é a origem dos dados que a busca híbrida consulta.

### Por que Busca Vetorial Simples NÃO é Suficiente

A Base Vetorial, populada pelo pipeline definido na [[BETA-006]], contém nós :Document com metadados ricos, nós :Chunk com embeddings vetoriais e conteúdo textual, grafo de relações e índices vetoriais, full-text e compostos.

A busca vetorial (similaridade coseno) é excelente para perguntas conceituais e semânticas, porém tem limitações críticas em ambiente corporativo:

1. **Termos exatos:** não garante match de termos literais como "BACEN 4893" ou "SKU-12345"
2. **Relações estruturais:** não navega relações DEPENDS_ON entre módulos
3. **Códigos e siglas:** embeddings tratam códigos como texto genérico, sem discriminação fina
4. **Contexto organizacional:** perguntas como "quem é responsável pelo sistema X?" são de GRAFO, não de similaridade textual

### Perfis de Consumo

| Perfil | Necessidade | Tipo de resposta |
|--------|-------------|------------------|
| Desenvolvedores | Detalhes técnicos, APIs, dependências | Precisa, com links para fonte |
| Tech Leads / Arquitetos | Decisões (ADRs), trade-offs, dependências | Contexto amplo |
| Gestores / Executivos | Visão macro, status, responsáveis | Resumida e confiante |
| Agentes de IA | Chunks bem ranqueados e contextualizados | Estruturada para LLM |

<!-- LOCKED:START autor=fabio data=2026-03-22 -->
## Decisão — Busca Híbrida (3 Buscas Paralelas + RRF)

A estratégia de retrieval combina **3 tipos de busca executados em PARALELO**, cujos resultados são fundidos via **Reciprocal Rank Fusion (RRF)** e re-ranqueados por cross-encoder para produzir a lista final de chunks mais relevantes.

Cada tipo de busca tem forças e fraquezas complementares. Nenhuma isoladamente cobre todos os cenários de perguntas corporativas. A combinação das 3 buscas maximiza o recall sem sacrificar excessivamente a precisão.

**Tratamento de falhas:** se uma das 3 buscas falhar (timeout, erro de índice, indisponibilidade), o sistema DEVE continuar com as buscas restantes. O RRF opera sobre 2 listas em vez de 3 — a qualidade degrada graciosamente. Se TODAS as 3 buscas falharem, retornar erro explícito ao usuário. Cada falha é registrada em log para observabilidade.

### Busca 1 — Vector Search (Semântica)

1. Recebe a query do usuário em linguagem natural
2. Gera embedding da query usando o **mesmo modelo** dos chunks (crítico: modelos diferentes = espaços incompatíveis)
3. Busca os top-K chunks mais próximos por similaridade coseno no índice vetorial
4. Retorna lista de chunks com score de similaridade (0.0 a 1.0)

**Parâmetros:** K=20 (configurável), similaridade mínima=0.5

**Pontos fortes:** entende semântica, sinônimos, tolera erros de digitação, suporte multilingual.
**Pontos fracos:** não garante match de termos exatos, tende a generalizar.

### Busca 2 — Keyword Search (Full-Text / BM25)

1. Executa busca full-text no índice de Chunk.content
2. Usa analisador com suporte a português (stemming, stopwords, tokenização)
3. Retorna chunks ranqueados por relevância BM25

**Parâmetros:** 20 resultados, operador OR com boost para AND, analisador pt-BR.

**Pontos fortes:** match exato de termos, códigos, identificadores, nomes próprios.
**Pontos fracos:** não entende semântica, não tolera erros, sensível a vocabulário.

### Busca 3 — Graph Search (Navegação Relacional)

1. Identifica entidades mencionadas na query (sistemas, módulos, pessoas, times, termos, tarefas)
2. Navega o grafo a partir das entidades identificadas (BELONGS_TO, DEPENDS_ON, OWNED_BY, MEMBER_OF, REFERENCES, SUPERSEDES)
3. Coleta chunks dos documentos encontrados via navegação

**Parâmetros:** profundidade=2 hops (configurável), máximo 10 documentos por navegação.

**Pontos fortes:** descobre relações estruturais, contexto organizacional, versionamento.
**Pontos fracos:** depende de entidades existentes no grafo, mais lento.

### Fusão — Reciprocal Rank Fusion (RRF)

As 3 buscas retornam listas com sistemas de scoring incompatíveis (coseno 0-1, BM25 0-∞, grafo sem score). O RRF converte **posições em ranking** em score unificado:

```
score_RRF(d) = SUM( 1 / (k + rank_i(d)) )  para cada busca i
```

Onde k=60 (constante de suavização do paper original de Cormack, Clarke e Buettcher, 2009).

**Saída:** lista unificada de chunks ordenados por score_RRF decrescente. Os top ~50 candidatos seguem para Reranking.

### Reranking (Cross-Encoder)

Um cross-encoder recebe query E chunk como entrada ÚNICA e produz score de relevância com atenção cruzada token a token. Captura negações, contexto condicional e paráfrases precisas.

**Fluxo:** top ~50 candidatos do RRF → cross-encoder → re-ordenação → top-K final (K=5 a K=10).

**Dual-track (conforme [[BETA-002]] e [[BETA-009]]):**

| Track | Modelo | Custo | Latência | Restrição |
|-------|--------|-------|----------|-----------|
| A — Cloud | Cohere Rerank v3 | ~$2/1.000 buscas | ~200ms/batch 50 | Apenas public/internal |
| B — On-premises | BGE-Reranker-v2-m3 | Zero | ~500ms GPU, ~2s CPU | Obrigatório para restricted/confidential |
<!-- LOCKED:END -->

## Filtragem Temporal

O conhecimento corporativo muda ao longo do tempo. O sistema suporta consultas históricas através de:

1. **Detecção de contexto temporal na query:** datas explícitas, palavras-chave temporais ("anterior", "histórico", "antes de"), comparações
2. **Aplicação do filtro:** `valid_from <= data_referência` e `valid_until >= data_referência OU IS NULL`
3. **Instrução ao agente:** sempre citar período de vigência, mencionar versões anteriores, alertar sobre expiração
4. **Sem contexto temporal detectado:** assume data atual, exclui documentos deprecated

## Filtro de Segurança Pré-Retrieval

O filtro de segurança **SEMPRE** é aplicado **ANTES** de qualquer busca. NUNCA confiar no prompt ou no pós-processamento para filtrar informação confidencial.

**Níveis de confidencialidade (conforme [[BETA-004]]):**

| Nível | Acesso |
|-------|--------|
| public | Todos os usuários |
| internal | Usuários autenticados |
| restricted | Usuários com role "restricted" OU do team owner |
| confidential | Usuários explicitamente listados no access_list |

**Regra de Ouro:** "Se o filtro de segurança falhar, o sistema DEVE retornar **ZERO resultados** — NUNCA resultados sem filtro." Fail-closed, não fail-open.

O filtro é aplicado em TODAS as 3 buscas. Na Graph Search, documentos com confidencialidade acima do nível do usuário são tratados como **inexistentes** (não navegáveis, relações cortadas).

Toda query é logada com user_id, níveis solicitados/aplicados e quantidade de chunks filtrados.

## Processamento de Query

Antes das 3 buscas, a query passa por pré-processamento:

### Query Rewriting (Reformulação)

Um LLM reformula queries vagas em versões mais precisas. Respeita a [[BETA-002]] (soberania):
- **Track A (Cloud):** GPT-4o-mini ou equivalente (<200ms)
- **Track B (On-prem):** Llama 3.1 8B ou Qwen via Ollama

A query original E a reformulada são usadas nas buscas.

**Implementação híbrida (Track B):**
1. Regras sempre executam primeiro (expandir siglas, adicionar sinônimos do glossário, <10ms)
2. Busca vetorial com query expandida
3. Se resultados < 3 com score > 0.5: acionar LLM para rewriting (timeout 5s)
4. Fusão de resultados via RRF

**Métricas-alvo:** >70% queries resolvidas por regras, <30% com fallback LLM.

### Query Expansion (Expansão)

Gera 2-3 variações da query cobrindo sinônimos e reformulações alternativas para aumentar recall.

### Query Decomposition (Decomposição)

Decompõe queries complexas com múltiplas sub-perguntas em sub-queries atômicas processadas independentemente. Gatilho: query >20 tokens, contém "e"/"ou" conectando temas distintos, pede informações de natureza diferente.

## Agentes Especializados

### Architecture Agent

- **Filtros:** doc_type IN ["architecture-doc", "adr", "system-doc"]
- **Relações priorizadas:** DEPENDS_ON, BELONGS_TO, DECIDES, REFERENCES, SUPERSEDES
- **System prompt:** arquiteto de software sênior, profundidade técnica, citar ADRs, trade-offs

### Operations Agent

- **Filtros:** doc_type IN ["runbook", "glossary", "task-doc", "system-doc"]
- **Relações priorizadas:** BELONGS_TO (módulo), IMPLEMENTS, RELATES_TO_TASK
- **System prompt:** engenheiro de operações, passos numerados, comandos exatos, avisos de segurança

### Business Agent

- **Filtros:** domain filtrado conforme query
- **Relações priorizadas:** OWNED_BY, MEMBER_OF, USES_TERM, BELONGS_TO
- **System prompt:** analista de negócios, linguagem acessível, citar regras com vigência

### Dispatcher (Roteador)

Classifica a intenção da query via LLM com few-shot examples:
- "architecture" → Architecture Agent
- "operations" → Operations Agent
- "business" → Business Agent
- "ambiguous" → Fallback (todos os agentes, fusão via RRF)

**Configuração:** LLM leve, latência <100ms, cache de 5 minutos para queries idênticas.

## Feedback Loop

### Avaliação do Usuário

Após cada resposta: polegar cima/baixo + comentário livre. Cada avaliação armazena query, chunks usados, agente, timestamp e user_id.

### Detecção de Gaps de Conhecimento

Queries com zero resultados (ou score RRF muito baixo) são sinalizadas. Se a mesma query aparece 3+ vezes, é promovida a "gap confirmado" com alerta ao time de governança.

### Revisão de Respostas Mal Avaliadas

1. **Automática:** verificar relevância dos chunks, recall de chunks existentes, dispatch correto
2. **Por humano:** classificar causa raiz (gap, problema de retrieval, reranking ou prompt)

### Métricas de Qualidade

Dashboard semanal: % respostas positivas, taxa de gaps, Recall@10 (golden set), latência end-to-end, distribuição por agente, top-10 queries/gaps.

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

- **Latência:** ~500-1000ms (híbrido completo) vs ~50ms (vetorial pura) — trade-off aceito: qualidade >>> velocidade
- **Complexidade:** 3 buscas + fusão + reranking + 3 agentes + dispatcher
- **Custo:** reranking cloud (Track A) tem custo por query; local (Track B) exige GPU
- **Dispatcher pode errar:** classificação incorreta direciona para agente errado; fallback mitiga

### Riscos

- **Modelo de embedding degrada:** mitigação via golden set semanal com alerta
- **Grafo incompleto:** mitigação via verificação de consistência ([[BETA-006]], Etapa 7)
- **Feedback enviesado:** mitigação via revisão humana de amostra + golden set
- **Latência em pico:** mitigação via timeout por busca (500ms) + resultados parciais

## Implementação (Faseamento)

| Fase | Entregas |
|------|----------|
| Fase 1 (MVP) | Busca vetorial simples, sem reranking, sem agentes, filtro de segurança básico |
| Fase 2 (Metadados) | Filtros por system/module/domain, segurança completa (4 níveis), filtragem temporal básica |
| Fase 3 (Knowledge Graph) | Busca por grafo, RRF (vetor + grafo), query rewriting básico |
| Fase 4 (GraphRAG Corporativo) | Busca keyword, RRF completo, reranking, agentes + dispatcher, feedback loop, dashboard |

## Referências

- [[BETA-001]]: Pipeline de Geração de Conhecimento em 4 Fases
- [[BETA-002]]: Soberania de Dados (Track A/B)
- [[BETA-003]]: Modelo de Dados da Base Vetorial
- [[BETA-004]]: Segurança e Classificação de Dados
- [[BETA-005]]: Front Matter Obrigatório
- [[BETA-006]]: Pipeline de Ingestão
- [[BETA-009]]: Seleção de Modelos de Embedding e Reranking
- Cormack, Clarke, Buettcher (2009). "Reciprocal Rank Fusion outperforms Condorcet and individual Rank Learning Methods"
- Nogueira, Cho (2019). "Passage Re-ranking with BERT"
- Malkov, Yashunin (2018). "Efficient and robust approximate nearest neighbor search using HNSW graphs"
- Robertson, Zaragoza (2009). "The Probabilistic Relevance Framework: BM25 and Beyond"

---

<!-- QA-BETA: inicio -->
## Quality Assurance — .beta.md

| Critério | Peso | Nota | Comentário |
|----------|------|------|------------|
| Front matter leve | 25% | 95% | Campos obrigatórios presentes e válidos. id BETA-007 (regex ok), title 48 chars, domain lowercase, confidentiality enum válido, sources com type/origin/captured_at, 11 tags lowercase, status approved, datas válidas. Aliases com apenas 2 elementos (abaixo do recomendado de 3+, porém não-bloqueante no .beta.md). Nenhum campo de governança indevido. |
| Completude de conteúdo | 25% | 96% | Seções principais preservadas: Contexto (posição no pipeline, justificativa de busca híbrida, perfis de consumo), Decisão (3 buscas + RRF + Reranking), Filtragem Temporal, Filtro de Segurança, Processamento de Query (Rewriting, Expansion, Decomposition), Agentes Especializados (3 + Dispatcher), Feedback Loop, Alternativas, Consequências, Implementação, Referências. Condensação de detalhes em relação ao draft (ex: exemplos de queries e justificativas expandidas). |
| Blocos LOCKED | 15% | 100% | Bloco LOCKED presente (linhas 55-122) protegendo a decisão central: 3 buscas paralelas + RRF + Reranking com dual-track. Corretamente aberto e fechado. |
| Wikilinks | 10% | 100% | Referências em formato [[BETA-NNN]]: BETA-001, BETA-002, BETA-003, BETA-004, BETA-005, BETA-006, BETA-009. Todas pertinentes. Nenhum wikilink no front matter. |
| Compatibilidade Obsidian | 10% | 100% | YAML válido entre marcadores ---. Tags e aliases como arrays. Campos tipados corretamente. |
| Clareza e estrutura | 15% | 95% | H1 adicionado na revisão QA (estava ausente). Headings hierárquicos claros. Tabelas bem formatadas (perfis de consumo, alternativas, dual-track, implementação). Seções logicamente organizadas. |

**Score:** 96.8% — APROVADO para promoção

**Por que não é 100%:** (1) Aliases com apenas 2 elementos — recomendado adicionar pelo menos mais 1 (ex: "Busca Híbrida", "Agentes Especializados"). (2) H1 estava ausente e foi adicionado durante a revisão QA. (3) Condensação natural do draft: exemplos detalhados de queries por perfil e justificativas expandidas de cada alternativa descartada foram resumidos.
<!-- QA-BETA: fim -->
