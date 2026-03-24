---
id: ADR-H01
doc_type: adr
title: "Orquestrador Cross-KB — Fluxo de 8 Passos para Busca Simultânea em Múltiplas Knowledge Bases"
system: RAG Corporativo
module: Orquestrador Cross-KB
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - orquestrador cross kb
  - multi kb
  - knowledge base
  - segregação por confidencialidade
  - mcp server
  - busca simultânea
  - fusão de resultados
  - reciprocal rank fusion
  - rrf
  - reranking
  - cross encoder
  - classificação de resposta
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
  - token de autenticação
  - delegação de credencial
  - stateless
  - fail closed
  - degradação graciosa
  - timeout
  - deduplicação
  - document id
  - chunk id
  - base vetorial
  - neo4j
  - instância dedicada
  - isolamento físico
  - segurança
  - pen test
  - prompt injection
  - siem
  - auditoria
  - rastreabilidade
  - latência
  - observabilidade
  - resultado parcial
  - erro 403
  - erro 503
  - citação de origem
  - montagem de prompt
  - top k
  - pipeline de busca
  - busca vetorial
  - similaridade semântica
  - controle de acesso
  - roteamento de queries
  - fusão de rankings
  - score de relevância
  - modelo de reranking
aliases:
  - "ADR-H01"
  - "Orquestrador Cross-KB"
  - "Orquestrador Multi-KB"
  - "Cross-KB Orchestrator"
  - "Busca Simultânea Multi-KB"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/beta/ADR-H01_orquestrador_cross_kb.beta.md"
source_beta_ids:
  - "BETA-H01"
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

# ADR-H01 — Orquestrador Cross-KB — Fluxo de 8 Passos para Busca Simultânea em Múltiplas Knowledge Bases

| Campo       | Valor                                                         |
|-------------|---------------------------------------------------------------|
| **Status**  | Accepted                                                      |
| **Data**    | 23/03/2026                                                    |
| **Decisor** | fabio (arquitetura)                                           |
| **Escopo**  | Fluxo de 8 passos do agente orquestrador para busca simultânea em múltiplas KBs segregadas por confidencialidade |

**Referências cruzadas:**

- [[ADR-011]]: Segregação de KBs por Confidencialidade (modelo de 3 KBs)
- [[ADR-007]]: Retrieval Híbrido e Agentes (RRF, reranking)
- [[ADR-004]]: Segurança, Classificação de Dados (níveis de confidencialidade)
- [[ADR-008]]: Governança (papéis e perfis de acesso)
- [[ADR-H02]]: Guia de Deploy Multi-KB

---

## Contexto

O [[ADR-011]] estabeleceu 3 KBs fisicamente separadas:
- **kb-public-internal** (Instância A) — PUBLIC + INTERNAL
- **kb-restricted** (Instância B) — RESTRICTED
- **kb-confidential** (Instância C) — CONFIDENTIAL

Cada KB possui seu próprio MCP Server dedicado. Usuários com perfil elevado (Manager, Director) precisam consultar mais de uma KB simultaneamente. O orquestrador resolve esse problema sem violar o isolamento físico.

## Decisão

Especificar o fluxo de 8 passos do agente orquestrador que realiza buscas simultâneas em múltiplas Knowledge Bases (KBs) segregadas por nível de confidencialidade, fundindo resultados de forma segura e rastreável.

## Pré-Condições

- Cada KB opera com Base Vetorial dedicada e MCP Server dedicado.
- O perfil do usuário está autenticado e mapeado para os MCPs autorizados.
- O orquestrador NÃO possui credenciais próprias — roda exclusivamente com o perfil (token) do usuário solicitante.
- O orquestrador é stateless: não armazena queries, resultados ou tokens entre execuções.

## Fluxo de 8 Passos

### Passo 1 — Receber a pergunta do usuário

- Entrada: query em linguagem natural + token de autenticação do usuário.
- O orquestrador registra timestamp de recebimento e request_id único.

### Passo 2 — Identificar MCPs autorizados

Com base no perfil do usuário (extraído do token), determinar quais MCP Servers o usuário tem direito de acessar.

Mapeamento de perfis:

| Perfil | MCPs Acessíveis |
|---|---|
| Analyst | mcp-knowledge-public |
| Manager | mcp-knowledge-public + mcp-knowledge-restricted |
| Director | mcp-knowledge-public + mcp-knowledge-restricted + mcp-knowledge-confidential |
| Agente IA genérico | mcp-knowledge-public |
| Agente IA de domínio | mcp-knowledge-public + mcp-knowledge-restricted (domínio específico) |
| Agente IA dedicado | mcp-knowledge-confidential (com aprovação) |

Se o usuário não tem acesso a nenhum MCP, retornar erro 403.

### Passo 3 — Enviar query para cada MCP autorizado em paralelo

- A mesma query é enviada simultaneamente para todos os MCPs autorizados.
- Cada chamada inclui o token do usuário (delegação de credencial).
- Timeout individual por MCP: configurável (default 5 segundos).
- Se um MCP não responder dentro do timeout, o orquestrador continua com os resultados parciais dos demais (degradação graciosa).

### Passo 4 — Receber resultados de cada MCP

- Cada MCP retorna uma lista de chunks ranqueados por relevância (score de similaridade vetorial).
- Cada chunk carrega: chunk_id, document_id, score, confidentiality, domain, snippet.
- O orquestrador registra: MCP de origem, quantidade de chunks retornados, latência de cada MCP.

### Passo 5 — Fundir resultados usando RRF (Reciprocal Rank Fusion)

- Aplicar RRF (conforme [[ADR-007]]) para combinar os rankings de múltiplos MCPs em um ranking único.
- Fórmula RRF: `score_final(d) = SUM(1 / (k + rank_i(d)))` onde k = 60 (constante padrão) e rank_i é a posição do chunk no ranking do MCP i.
- Chunks que aparecem em mais de um MCP (por cross_ref ou duplicação) são deduplicados por document_id — o de maior score prevalece.

### Passo 6 — Aplicar reranking no conjunto fundido

- Após a fusão RRF, aplicar modelo de reranking (cross-encoder) no top-N chunks (default N=20).
- O reranking avalia relevância semântica da query em relação ao conteúdo completo do chunk (não apenas embedding).
- Resultado: lista reordenada com scores de reranking.

### Passo 7 — Montar prompt com chunks ordenados por relevância

- Selecionar top-K chunks (default K=5) após reranking.
- Para cada chunk incluído, indicar:
  - Classificação de confidencialidade do chunk
  - Documento de origem (document_id, title)
  - MCP de origem
- Regra de classificação da resposta:
  - Se qualquer chunk CONFIDENTIAL foi usado → resposta inteira é classificada como CONFIDENTIAL.
  - Se qualquer chunk RESTRICTED foi usado (sem CONFIDENTIAL) → resposta classificada como RESTRICTED.
  - Caso contrário → resposta classificada como INTERNAL.
- Chunks de níveis diferentes NUNCA são misturados sem indicação explícita da classificação de cada um.

### Passo 8 — Gerar resposta

- O LLM gera a resposta usando o prompt montado no Passo 7.
- A resposta inclui:
  - Classificação de confidencialidade (calculada no Passo 7)
  - Citações de origem (document_id, title, chunk_id)
  - Indicação de quais MCPs contribuíram para a resposta
- O orquestrador registra: request_id, MCPs consultados, chunks utilizados, classificação da resposta, latência total.

## Regras de Segurança do Orquestrador

**R1:** O orquestrador roda com o PERFIL DO USUÁRIO — só acessa os MCPs que o usuário tem direito. Nunca usa credencial de serviço própria.

**R2:** Nunca mistura chunks de níveis diferentes sem INDICAR A CLASSIFICAÇÃO de cada chunk no prompt e na resposta.

**R3:** Se chunks CONFIDENTIAL foram usados, a resposta inteira é classificada como CONFIDENTIAL. Não existe "resposta parcialmente confidencial".

**R4:** O orquestrador é STATELESS — não armazena queries, resultados nem tokens entre execuções. Logs de auditoria são escritos em serviço externo (SIEM).

**R5:** Pen test específico deve cobrir cenários de:
- Tentativa de acessar MCP não autorizado
- Token expirado ou inválido
- Prompt injection tentando bypassar roteamento
- Timeout de MCP com resultado parcial

## Controle de Acesso — Tabela de Referência

| Perfil | MCPs Acessíveis | Bases Vetoriais |
|---|---|---|
| Analyst | mcp-knowledge-public | A |
| Manager | mcp-knowledge-public + mcp-knowledge-restricted | A, B |
| Director | mcp-knowledge-public + mcp-knowledge-restricted + mcp-knowledge-confidential | A, B, C |
| Agente IA genérico | mcp-knowledge-public | A |
| Agente IA de domínio | mcp-knowledge-public + mcp-knowledge-restricted | A, B |
| Agente IA dedicado | mcp-knowledge-confidential | C |

## Tratamento de Falhas

- **MCP não responde (timeout):** continuar com resultados parciais. Incluir aviso na resposta: "Resultados parciais — KB [nome] não respondeu."
- **Nenhum MCP responde:** retornar erro 503 com mensagem clara.
- **Nenhum chunk relevante encontrado:** retornar resposta indicando ausência de resultados, sem inventar conteúdo.
- **Erro de autenticação em MCP específico:** logar erro, continuar com demais MCPs, incluir aviso na resposta.

## Métricas de Observabilidade

- Latência total do orquestrador (p50, p95, p99)
- Latência por MCP individual
- Taxa de timeout por MCP
- Número de chunks retornados por MCP (média, max)
- Taxa de deduplicação (chunks removidos por cross_ref)
- Distribuição de classificação das respostas
- Taxa de respostas com resultado parcial (algum MCP falhou)

## Referências

- [[ADR-011]]: Segregação de KBs por Confidencialidade (modelo de 3 KBs)
- [[ADR-007]]: Retrieval Híbrido e Agentes (RRF, reranking)
- [[ADR-004]]: Segurança, Classificação de Dados (níveis de confidencialidade)
- [[ADR-008]]: Governança (papéis e perfis de acesso)

<!-- conversion_quality: 95 -->
