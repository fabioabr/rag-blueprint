---
id: BETA-H01
title: "Orquestrador Cross-KB"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-H01_orquestrador_cross_kb.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags:
  - orquestrador cross kb
  - multi kb
  - knowledge base
  - segregacao por confidencialidade
  - mcp server
  - busca simultanea
  - fusao de resultados
  - reciprocal rank fusion
  - rrf
  - reranking
  - cross encoder
  - classificacao de resposta
  - confidencialidade
  - public
  - internal
  - restricted
  - confidential
  - perfil de acesso
  - analyst
  - manager
  - director
  - agente ia
  - token de autenticacao
  - delegacao de credencial
  - stateless
  - fail closed
  - degradacao graciosa
  - timeout
  - deduplicacao
  - document id
  - chunk id
  - base vetorial
  - neo4j
  - instancia dedicada
  - isolamento fisico
  - seguranca
  - pen test
  - prompt injection
  - siem
  - auditoria
  - rastreabilidade
  - latencia
  - observabilidade
  - resultado parcial
  - erro 403
  - erro 503
  - citacao de origem
  - montagem de prompt
  - top k
aliases:
  - "ADR-H01"
  - "Orquestrador Cross-KB"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## ADR-H01 -- Orquestrador Cross-KB

**Tipo:** ADR
**Origem:** ADR-011
**Data:** 23/03/2026

## 1. Objetivo

Especificar o fluxo de 8 passos do agente orquestrador que realiza buscas simultaneas em multiplas Knowledge Bases (KBs) segregadas por nivel de confidencialidade, fundindo resultados de forma segura e rastreavel.

O ADR-011 estabeleceu 3 KBs fisicamente separadas:
- **kb-public-internal** (Instancia A) -- PUBLIC + INTERNAL
- **kb-restricted** (Instancia B) -- RESTRICTED
- **kb-confidential** (Instancia C) -- CONFIDENTIAL

Cada KB possui seu proprio MCP Server dedicado. Usuarios com perfil elevado (Manager, Director) precisam consultar mais de uma KB simultaneamente. O orquestrador resolve esse problema sem violar o isolamento fisico.

## 2. Pre-Condicoes

- Cada KB opera com Base Vetorial dedicada e MCP Server dedicado.
- O perfil do usuario esta autenticado e mapeado para os MCPs autorizados.
- O orquestrador NAO possui credenciais proprias -- roda exclusivamente com o perfil (token) do usuario solicitante.
- O orquestrador e stateless: nao armazena queries, resultados ou tokens entre execucoes.

## 3. Fluxo de 8 Passos

### Passo 1 -- Receber a pergunta do usuario

- Entrada: query em linguagem natural + token de autenticacao do usuario.
- O orquestrador registra timestamp de recebimento e request_id unico.

### Passo 2 -- Identificar MCPs autorizados

Com base no perfil do usuario (extraido do token), determinar quais MCP Servers o usuario tem direito de acessar.

Mapeamento de perfis:

| Perfil | MCPs Acessiveis |
|---|---|
| Analyst | mcp-knowledge-public |
| Manager | mcp-knowledge-public + mcp-knowledge-restricted |
| Director | mcp-knowledge-public + mcp-knowledge-restricted + mcp-knowledge-confidential |
| Agente IA generico | mcp-knowledge-public |
| Agente IA de dominio | mcp-knowledge-public + mcp-knowledge-restricted (dominio especifico) |
| Agente IA dedicado | mcp-knowledge-confidential (com aprovacao) |

Se o usuario nao tem acesso a nenhum MCP, retornar erro 403.

### Passo 3 -- Enviar query para cada MCP autorizado em paralelo

- A mesma query e enviada simultaneamente para todos os MCPs autorizados.
- Cada chamada inclui o token do usuario (delegacao de credencial).
- Timeout individual por MCP: configuravel (default 5 segundos).
- Se um MCP nao responder dentro do timeout, o orquestrador continua com os resultados parciais dos demais (degradacao graciosa).

### Passo 4 -- Receber resultados de cada MCP

- Cada MCP retorna uma lista de chunks ranqueados por relevancia (score de similaridade vetorial).
- Cada chunk carrega: chunk_id, document_id, score, confidentiality, domain, snippet.
- O orquestrador registra: MCP de origem, quantidade de chunks retornados, latencia de cada MCP.

### Passo 5 -- Fundir resultados usando RRF (Reciprocal Rank Fusion)

- Aplicar RRF (conforme ADR-007) para combinar os rankings de multiplos MCPs em um ranking unico.
- Formula RRF: `score_final(d) = SUM(1 / (k + rank_i(d)))` onde k = 60 (constante padrao) e rank_i e a posicao do chunk no ranking do MCP i.
- Chunks que aparecem em mais de um MCP (por cross_ref ou duplicacao) sao deduplicados por document_id -- o de maior score prevalece.

### Passo 6 -- Aplicar reranking no conjunto fundido

- Apos a fusao RRF, aplicar modelo de reranking (cross-encoder) no top-N chunks (default N=20).
- O reranking avalia relevancia semantica da query em relacao ao conteudo completo do chunk (nao apenas embedding).
- Resultado: lista reordenada com scores de reranking.

### Passo 7 -- Montar prompt com chunks ordenados por relevancia

- Selecionar top-K chunks (default K=5) apos reranking.
- Para cada chunk incluido, indicar:
  - Classificacao de confidencialidade do chunk
  - Documento de origem (document_id, title)
  - MCP de origem
- Regra de classificacao da resposta:
  - Se qualquer chunk CONFIDENTIAL foi usado -> resposta inteira e classificada como CONFIDENTIAL.
  - Se qualquer chunk RESTRICTED foi usado (sem CONFIDENTIAL) -> resposta classificada como RESTRICTED.
  - Caso contrario -> resposta classificada como INTERNAL.
- Chunks de niveis diferentes NUNCA sao misturados sem indicacao explicita da classificacao de cada um.

### Passo 8 -- Gerar resposta

- O LLM gera a resposta usando o prompt montado no Passo 7.
- A resposta inclui:
  - Classificacao de confidencialidade (calculada no Passo 7)
  - Citacoes de origem (document_id, title, chunk_id)
  - Indicacao de quais MCPs contribuiram para a resposta
- O orquestrador registra: request_id, MCPs consultados, chunks utilizados, classificacao da resposta, latencia total.

## 4. Regras de Seguranca do Orquestrador

**R1:** O orquestrador roda com o PERFIL DO USUARIO -- so acessa os MCPs que o usuario tem direito. Nunca usa credencial de servico propria.

**R2:** Nunca mistura chunks de niveis diferentes sem INDICAR A CLASSIFICACAO de cada chunk no prompt e na resposta.

**R3:** Se chunks CONFIDENTIAL foram usados, a resposta inteira e classificada como CONFIDENTIAL. Nao existe "resposta parcialmente confidencial".

**R4:** O orquestrador e STATELESS -- nao armazena queries, resultados nem tokens entre execucoes. Logs de auditoria sao escritos em servico externo (SIEM).

**R5:** Pen test especifico deve cobrir cenarios de:
- Tentativa de acessar MCP nao autorizado
- Token expirado ou invalido
- Prompt injection tentando bypassar roteamento
- Timeout de MCP com resultado parcial

## 5. Controle de Acesso -- Tabela de Referencia

| Perfil | MCPs Acessiveis | Bases Vetoriais |
|---|---|---|
| Analyst | mcp-knowledge-public | A |
| Manager | mcp-knowledge-public + mcp-knowledge-restricted | A, B |
| Director | mcp-knowledge-public + mcp-knowledge-restricted + mcp-knowledge-confidential | A, B, C |
| Agente IA generico | mcp-knowledge-public | A |
| Agente IA de dominio | mcp-knowledge-public + mcp-knowledge-restricted | A, B |
| Agente IA dedicado | mcp-knowledge-confidential | C |

## 6. Tratamento de Falhas

- **MCP nao responde (timeout):** continuar com resultados parciais. Incluir aviso na resposta: "Resultados parciais -- KB [nome] nao respondeu."
- **Nenhum MCP responde:** retornar erro 503 com mensagem clara.
- **Nenhum chunk relevante encontrado:** retornar resposta indicando ausencia de resultados, sem inventar conteudo.
- **Erro de autenticacao em MCP especifico:** logar erro, continuar com demais MCPs, incluir aviso na resposta.

## 7. Metricas de Observabilidade

- Latencia total do orquestrador (p50, p95, p99)
- Latencia por MCP individual
- Taxa de timeout por MCP
- Numero de chunks retornados por MCP (media, max)
- Taxa de deduplicacao (chunks removidos por cross_ref)
- Distribuicao de classificacao das respostas
- Taxa de respostas com resultado parcial (algum MCP falhou)

## 8. Referencias

- ADR-011: Segregacao de KBs por Confidencialidade (modelo de 3 KBs)
- ADR-007: Retrieval Hibrido e Agentes (RRF, reranking)
- ADR-004: Seguranca, Classificacao de Dados (niveis de confidencialidade)
- ADR-008: Governanca (papeis e perfis de acesso)

<!-- conversion_quality: 95 -->
