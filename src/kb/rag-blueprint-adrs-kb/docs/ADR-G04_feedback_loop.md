---
id: ADR-G04
doc_type: adr
title: "Feedback Loop e Melhoria Contínua do Retrieval"
system: RAG Corporativo
module: Feedback Loop
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - feedback loop
  - melhoria contínua
  - coleta de feedback
  - avaliação de resposta
  - gap de conhecimento
  - detecção de gaps
  - revisão de respostas
  - causa raiz
  - triagem automática
  - dashboard de métricas
  - golden set
  - recall
  - satisfação do usuário
  - rating
  - comentário livre
  - retrieval
  - reranking
  - dispatcher
  - agente especializado
  - observabilidade
  - alerta automático
  - cadência de revisão
  - ciclo de curadoria
  - governança
  - pipeline de maturidade
  - qualidade de resposta
  - relevância de chunks
  - rrf
  - cross encoder
  - system prompt
  - classificação de intenção
  - documento desatualizado
  - fora de escopo
  - privacidade
  - ética
  - anonimização
  - user id
  - chunk id
  - query rewriting
  - latência
  - degradação
  - incidente
  - clickup
  - jira
  - sla
  - retenção de feedback
  - tendência semanal
  - distribuição por agente
  - registro de melhorias
  - acurácia
  - pipeline de query
  - métricas obrigatórias
  - rollback
  - benchmark de embeddings
aliases:
  - "ADR-G04"
  - "Feedback Loop"
  - "Feedback Loop do RAG"
  - "Melhoria Contínua do Retrieval"
  - "Ciclo de Feedback"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/draft/ADR-G04_feedback_loop.txt"
source_beta_ids:
  - "BETA-G04"
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

# ADR-G04 — Feedback Loop e Melhoria Contínua do Retrieval

| Campo | Valor |
|-------|-------|
| **Status** | Accepted |
| **Data da Decisão** | 2026-03-23 |
| **Decisor** | fabio |
| **Escopo** | Feedback Loop |

**Referências Cruzadas:**

- **Depende de:** [[ADR-007]]
- **Relaciona-se:** [[ADR-008]], [[ADR-004]], [[ADR-001]], [[ADR-F01]]

## Objetivo

Definir o processo operacional de coleta de feedback dos usuários, detecção de gaps de conhecimento, revisão de respostas mal avaliadas e ciclo de melhoria contínua do sistema de retrieval do RAG Corporativo.

## 1. Coleta de Feedback do Usuário

### 1.1 Mecanismo de Avaliação

Após cada resposta gerada pelo sistema, o usuário pode fornecer:

a) **Avaliação rápida:** polegar para cima / polegar para baixo
   - Obrigatória para toda interação
   - Binária: útil (1) ou não útil (0)
   - Latência zero para o usuário (um clique)

b) **Comentário livre (opcional):**
   - Campo de texto aberto
   - Permite descrever o que estava errado ou incompleto
   - Exemplos: "A resposta não mencionou a versão mais recente", "O documento citado está desatualizado", "Não encontrou nada sobre o módulo de PIX"

### 1.2 Dados Armazenados por Avaliação

| Campo | Descrição |
|---|---|
| feedback_id | Identificador único da avaliação |
| query | Texto original da query do usuário |
| query_rewritten | Query após rewriting (se aplicável) |
| agent_used | Agente que processou (architecture/operations/business) |
| dispatcher_intent | Intenção classificada pelo dispatcher |
| chunks_returned | Lista de chunk_ids retornados ao LLM |
| chunks_scores | Scores RRF e reranking de cada chunk |
| response_text | Resposta gerada pelo LLM |
| rating | 1 (positivo) ou 0 (negativo) |
| comment | Comentário livre do usuário (se fornecido) |
| user_id | Identificador do usuário (para análise por perfil) |
| timestamp | Data/hora da avaliação |

### 1.3 Armazenamento

Feedbacks são armazenados em coleção/tabela dedicada, separada do índice vetorial principal. Retenção mínima: 12 meses. Não excluir feedbacks negativos (são os mais valiosos para melhoria).

## 2. Detecção de Gaps de Conhecimento

### 2.1 Definição de Gap

Um gap de conhecimento é uma pergunta legítima do usuário para a qual o sistema não possui documentação adequada na base.

### 2.2 Critérios de Detecção

**Critério 1 — Zero resultados:**
- Query retorna 0 chunks após todas as 3 buscas
- Ou todos os chunks retornados têm score RRF < threshold mínimo

**Critério 2 — Resultados de baixa qualidade:**
- Top-K chunks têm score de reranking muito baixo (< 0.3)
- Nenhum chunk do top-5 é relevante (baseado em feedback)

**Critério 3 — Feedback negativo recorrente:**
- A mesma query (ou queries semanticamente similares) recebe avaliação negativa 3+ vezes

### 2.3 Classificação de Gaps

| Nível | Critério | Ação |
|---|---|---|
| Suspeito | 1 ocorrência de zero resultado | Registrar para monitoramento |
| Provável | 2 ocorrências ou feedback negativo | Adicionar à fila de revisão |
| Confirmado | 3+ ocorrências da mesma query com zero/baixo resultado | Alerta ao time de governança |

### 2.4 Promoção de Gap

Quando um gap é classificado como "confirmado":
- Gerar alerta automático para o time de governança (email/Slack/ClickUp)
- Incluir: query original, frequência, perfis de usuários afetados
- O time decide: criar novo documento, expandir existente, ou marcar como "fora de escopo"

## 3. Revisão de Respostas Mal Avaliadas

### 3.1 Triagem Automática

Para cada feedback negativo, o sistema executa verificação automática:

**Verificação 1 — Relevância dos chunks:**
- Os chunks retornados são de fato relevantes para a query?
- Métrica: se golden set existir para query similar, comparar recall

**Verificação 2 — Recall de chunks existentes:**
- Existem chunks na base que DEVERIAM ter sido retornados mas não foram?
- Métrica: busca exaustiva (sem HNSW, força bruta) para verificar

**Verificação 3 — Dispatch correto:**
- O dispatcher classificou a intenção corretamente?
- Se não, a query deveria ter ido para outro agente?

**Verificação 4 — Reranking:**
- O reranker posicionou os chunks relevantes no top-K?
- Comparar posição antes e depois do reranking

### 3.2 Classificação de Causa Raiz (por humano)

Após triagem automática, um revisor humano classifica a causa raiz:

| Causa raiz | Descrição | Ação corretiva |
|---|---|---|
| Gap de conhecimento | Documento não existe na base | Criar documento |
| Problema de retrieval | Chunks existem mas não foram encontrados pela busca | Ajustar parâmetros de busca |
| Problema de reranking | Chunks encontrados mas mal posicionados | Ajustar reranker ou golden set |
| Problema de prompt | Chunks corretos mas LLM gerou resposta ruim | Ajustar system prompt do agente |
| Dispatch incorreto | Query direcionada para agente errado | Adicionar few-shot example ao dispatcher |
| Documento desatualizado | Documento existe mas conteúdo está obsoleto | Atualizar documento na fonte (Git) |
| Fora de escopo | Pergunta não faz parte do domínio coberto pela base | Documentar como fora de escopo |

### 3.3 Fluxo de Revisão

1. Feedback negativo chega
2. Triagem automática classifica tipo provável (< 1 min)
3. Revisor humano confirma causa raiz (SLA: 48 horas úteis)
4. Ação corretiva é criada como task (ClickUp/Jira)
5. Após correção, re-executar query e verificar se feedback seria positivo
6. Fechar ciclo com registro de resolução

## 4. Dashboard de Métricas (Semanal)

### 4.1 Métricas Obrigatórias

| Métrica | Meta |
|---|---|
| % respostas com feedback positivo | > 80% |
| Taxa de gaps confirmados (por semana) | < 5 novos gaps |
| Recall@10 no golden set | >= threshold da fase atual |
| Latência end-to-end (p95) | < 3 segundos |
| Distribuição por agente | Monitorar desbalanceamento |

### 4.2 Métricas Detalhadas

- Top-10 queries mais frequentes (volume)
- Top-10 queries com pior avaliação (qualidade)
- Top-10 gaps confirmados (pendentes de resolução)
- Distribuição de feedback por agente (architecture/operations/business)
- Distribuição de feedback por perfil de usuário
- Tendência semanal de satisfação (positivos / total)
- Tempo médio de resolução de gaps

### 4.3 Alertas Automáticos

| Alerta | Condição | Destinatário |
|---|---|---|
| Degradação de satisfação | % positivos < 70% | Time de governança |
| Pico de gaps | > 10 gaps/semana | Time de governança |
| Degradação de recall | Golden set < threshold | Time de engenharia |
| Latência elevada | p95 > 5 segundos | Time de engenharia |
| Agente com feedback ruim | < 60% positivos | Owner do agente |

## 5. Ciclo de Melhoria Contínua

### 5.1 Cadência

**Diário:**
- Monitorar dashboard (alertas automáticos)
- Triagem automática de feedbacks negativos

**Semanal:**
- Reunião de revisão (15 min): analisar top gaps e feedbacks negativos
- Priorizar ações corretivas
- Atualizar golden set com novas queries relevantes

**Mensal:**
- Análise de tendências (satisfação, gaps, distribuição)
- Revisar parâmetros do pipeline (thresholds, K, timeout)
- Avaliar necessidade de novos agentes ou ajuste de existentes

**Trimestral:**
- Benchmark de modelos de embedding ([[ADR-F01]])
- Revisão completa do golden set
- Planejamento de evolução (novos domínios, novos tipos de documento)

### 5.2 Atualização do Golden Set

O golden set é um artefato VIVO. Deve ser atualizado com base em:
- Queries reais que geraram feedback negativo (adicionar como caso de teste)
- Novos documentos ingeridos na base (cobrir novos domínios)
- Gaps resolvidos (verificar que a correção funciona)

Meta: golden set crescer ~10-20 pares por mês até atingir 200+ pares.

### 5.3 Registro de Melhorias

Toda melhoria implementada deve ser documentada:
- Data da melhoria
- Causa raiz que motivou
- O que foi alterado (parâmetro, prompt, documento, modelo)
- Resultado antes vs depois (métricas comparativas)
- Responsável pela implementação

## 6. Integração com Governança

O feedback loop alimenta diretamente o processo de governança ([[ADR-008]]):

```
Feedback negativo
  -> Detecção de gap
    -> Alerta ao time de governança
      -> Decisão: criar/atualizar documento
        -> Documento passa pelo pipeline de maturidade:
           .txt (draft) -> .beta.md (beta) -> .md (final) -> ingestão
          -> Re-execução da query para validação
            -> Ciclo fechado
```

O feedback é a principal fonte de DEMANDA para novos documentos. Sem feedback, a base de conhecimento estagna.

## 7. Privacidade e Ética

- Feedbacks são associados a user_id para análise por perfil, mas NUNCA expostos individualmente (apenas agregados)
- Comentários livres podem conter dados sensíveis: aplicar mesma política de confidencialidade dos documentos
- Não usar feedback para avaliação de desempenho individual de usuários
- Anonimizar dados em relatórios compartilhados externamente

## Referências

- [[ADR-007]]: Retrieval Híbrido e Agentes Especializados
- [[ADR-008]]: Governança — Papéis, Ciclo de Vida e Rollback
- [[ADR-004]]: Segurança e Classificação de Dados
- [[ADR-001]]: Pipeline de Geração de Conhecimento em 4 Fases

<!-- conversion_quality: 95 -->
