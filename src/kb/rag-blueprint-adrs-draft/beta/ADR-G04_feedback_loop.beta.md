---
id: BETA-G04
title: "Feedback Loop e Melhoria Continua do Retrieval"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-G04_feedback_loop.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags:
  - feedback loop
  - melhoria continua
  - coleta de feedback
  - avaliacao de resposta
  - gap de conhecimento
  - deteccao de gaps
  - revisao de respostas
  - causa raiz
  - triagem automatica
  - dashboard de metricas
  - golden set
  - recall
  - satisfacao do usuario
  - rating
  - comentario livre
  - retrieval
  - reranking
  - dispatcher
  - agente especializado
  - observabilidade
  - alerta automatico
  - cadencia de revisao
  - ciclo de curadoria
  - governanca
  - pipeline de maturidade
  - qualidade de resposta
  - relevancia de chunks
  - rrf
  - cross encoder
  - system prompt
  - classificacao de intencao
  - documento desatualizado
  - fora de escopo
  - privacidade
  - etica
  - anonimizacao
  - user id
  - chunk id
  - query rewriting
  - latencia
  - degradacao
  - incidente
  - clickup
  - jira
  - sla
  - retencao de feedback
  - tendencia semanal
  - distribuicao por agente
  - registro de melhorias
aliases:
  - "ADR-G04"
  - "Feedback Loop"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## ADR-G04 -- Feedback Loop e Melhoria Continua do Retrieval

**Tipo:** ADR
**Origem:** ADR-007
**Data:** 23/03/2026

## Objetivo

Definir o processo operacional de coleta de feedback dos usuarios, deteccao de gaps de conhecimento, revisao de respostas mal avaliadas e ciclo de melhoria continua do sistema de retrieval do RAG Corporativo.

## 1. Coleta de Feedback do Usuario

### 1.1 Mecanismo de Avaliacao

Apos cada resposta gerada pelo sistema, o usuario pode fornecer:

a) **Avaliacao rapida:** polegar para cima / polegar para baixo
   - Obrigatoria para toda interacao
   - Binaria: util (1) ou nao util (0)
   - Latencia zero para o usuario (um clique)

b) **Comentario livre (opcional):**
   - Campo de texto aberto
   - Permite descrever o que estava errado ou incompleto
   - Exemplos: "A resposta nao mencionou a versao mais recente", "O documento citado esta desatualizado", "Nao encontrou nada sobre o modulo de PIX"

### 1.2 Dados Armazenados por Avaliacao

| Campo | Descricao |
|---|---|
| feedback_id | Identificador unico da avaliacao |
| query | Texto original da query do usuario |
| query_rewritten | Query apos rewriting (se aplicavel) |
| agent_used | Agente que processou (architecture/operations/business) |
| dispatcher_intent | Intencao classificada pelo dispatcher |
| chunks_returned | Lista de chunk_ids retornados ao LLM |
| chunks_scores | Scores RRF e reranking de cada chunk |
| response_text | Resposta gerada pelo LLM |
| rating | 1 (positivo) ou 0 (negativo) |
| comment | Comentario livre do usuario (se fornecido) |
| user_id | Identificador do usuario (para analise por perfil) |
| timestamp | Data/hora da avaliacao |

### 1.3 Armazenamento

Feedbacks sao armazenados em colecao/tabela dedicada, separada do indice vetorial principal. Retencao minima: 12 meses. Nao excluir feedbacks negativos (sao os mais valiosos para melhoria).

## 2. Deteccao de Gaps de Conhecimento

### 2.1 Definicao de Gap

Um gap de conhecimento e uma pergunta legitima do usuario para a qual o sistema nao possui documentacao adequada na base.

### 2.2 Criterios de Deteccao

**Criterio 1 -- Zero resultados:**
- Query retorna 0 chunks apos todas as 3 buscas
- Ou todos os chunks retornados tem score RRF < threshold minimo

**Criterio 2 -- Resultados de baixa qualidade:**
- Top-K chunks tem score de reranking muito baixo (< 0.3)
- Nenhum chunk do top-5 e relevante (baseado em feedback)

**Criterio 3 -- Feedback negativo recorrente:**
- A mesma query (ou queries semanticamente similares) recebe avaliacao negativa 3+ vezes

### 2.3 Classificacao de Gaps

| Nivel | Criterio | Acao |
|---|---|---|
| Suspeito | 1 ocorrencia de zero resultado | Registrar para monitoramento |
| Provavel | 2 ocorrencias ou feedback negativo | Adicionar a fila de revisao |
| Confirmado | 3+ ocorrencias da mesma query com zero/baixo resultado | Alerta ao time de governanca |

### 2.4 Promocao de Gap

Quando um gap e classificado como "confirmado":
- Gerar alerta automatico para o time de governanca (email/Slack/ClickUp)
- Incluir: query original, frequencia, perfis de usuarios afetados
- O time decide: criar novo documento, expandir existente, ou marcar como "fora de escopo"

## 3. Revisao de Respostas Mal Avaliadas

### 3.1 Triagem Automatica

Para cada feedback negativo, o sistema executa verificacao automatica:

**Verificacao 1 -- Relevancia dos chunks:**
- Os chunks retornados sao de fato relevantes para a query?
- Metrica: se golden set existir para query similar, comparar recall

**Verificacao 2 -- Recall de chunks existentes:**
- Existem chunks na base que DEVERIAM ter sido retornados mas nao foram?
- Metrica: busca exaustiva (sem HNSW, forca bruta) para verificar

**Verificacao 3 -- Dispatch correto:**
- O dispatcher classificou a intencao corretamente?
- Se nao, a query deveria ter ido para outro agente?

**Verificacao 4 -- Reranking:**
- O reranker posicionou os chunks relevantes no top-K?
- Comparar posicao antes e depois do reranking

### 3.2 Classificacao de Causa Raiz (por humano)

Apos triagem automatica, um revisor humano classifica a causa raiz:

| Causa raiz | Descricao | Acao corretiva |
|---|---|---|
| Gap de conhecimento | Documento nao existe na base | Criar documento |
| Problema de retrieval | Chunks existem mas nao foram encontrados pela busca | Ajustar parametros de busca |
| Problema de reranking | Chunks encontrados mas mal posicionados | Ajustar reranker ou golden set |
| Problema de prompt | Chunks corretos mas LLM gerou resposta ruim | Ajustar system prompt do agente |
| Dispatch incorreto | Query direcionada para agente errado | Adicionar few-shot example ao dispatcher |
| Documento desatualizado | Documento existe mas conteudo esta obsoleto | Atualizar documento na fonte (Git) |
| Fora de escopo | Pergunta nao faz parte do dominio coberto pela base | Documentar como fora de escopo |

### 3.3 Fluxo de Revisao

1. Feedback negativo chega
2. Triagem automatica classifica tipo provavel (< 1 min)
3. Revisor humano confirma causa raiz (SLA: 48 horas uteis)
4. Acao corretiva e criada como task (ClickUp/Jira)
5. Apos correcao, re-executar query e verificar se feedback seria positivo
6. Fechar ciclo com registro de resolucao

## 4. Dashboard de Metricas (Semanal)

### 4.1 Metricas Obrigatorias

| Metrica | Meta |
|---|---|
| % respostas com feedback positivo | > 80% |
| Taxa de gaps confirmados (por semana) | < 5 novos gaps |
| Recall@10 no golden set | >= threshold da fase atual |
| Latencia end-to-end (p95) | < 3 segundos |
| Distribuicao por agente | Monitorar desbalanceamento |

### 4.2 Metricas Detalhadas

- Top-10 queries mais frequentes (volume)
- Top-10 queries com pior avaliacao (qualidade)
- Top-10 gaps confirmados (pendentes de resolucao)
- Distribuicao de feedback por agente (architecture/operations/business)
- Distribuicao de feedback por perfil de usuario
- Tendencia semanal de satisfacao (positivos / total)
- Tempo medio de resolucao de gaps

### 4.3 Alertas Automaticos

| Alerta | Condicao | Destinatario |
|---|---|---|
| Degradacao de satisfacao | % positivos < 70% | Time de governanca |
| Pico de gaps | > 10 gaps/semana | Time de governanca |
| Degradacao de recall | Golden set < threshold | Time de engenharia |
| Latencia elevada | p95 > 5 segundos | Time de engenharia |
| Agente com feedback ruim | < 60% positivos | Owner do agente |

## 5. Ciclo de Melhoria Continua

### 5.1 Cadencia

**Diario:**
- Monitorar dashboard (alertas automaticos)
- Triagem automatica de feedbacks negativos

**Semanal:**
- Reuniao de revisao (15 min): analisar top gaps e feedbacks negativos
- Priorizar acoes corretivas
- Atualizar golden set com novas queries relevantes

**Mensal:**
- Analise de tendencias (satisfacao, gaps, distribuicao)
- Revisar parametros do pipeline (thresholds, K, timeout)
- Avaliar necessidade de novos agentes ou ajuste de existentes

**Trimestral:**
- Benchmark de modelos de embedding (ADR-F01)
- Revisao completa do golden set
- Planejamento de evolucao (novos dominios, novos tipos de documento)

### 5.2 Atualizacao do Golden Set

O golden set e um artefato VIVO. Deve ser atualizado com base em:
- Queries reais que geraram feedback negativo (adicionar como caso de teste)
- Novos documentos ingeridos na base (cobrir novos dominios)
- Gaps resolvidos (verificar que a correcao funciona)

Meta: golden set crescer ~10-20 pares por mes ate atingir 200+ pares.

### 5.3 Registro de Melhorias

Toda melhoria implementada deve ser documentada:
- Data da melhoria
- Causa raiz que motivou
- O que foi alterado (parametro, prompt, documento, modelo)
- Resultado antes vs depois (metricas comparativas)
- Responsavel pela implementacao

## 6. Integracao com Governanca

O feedback loop alimenta diretamente o processo de governanca (ADR-008):

```
Feedback negativo
  -> Deteccao de gap
    -> Alerta ao time de governanca
      -> Decisao: criar/atualizar documento
        -> Documento passa pelo pipeline de maturidade:
           .txt (draft) -> .beta.md (beta) -> .md (final) -> ingestao
          -> Re-execucao da query para validacao
            -> Ciclo fechado
```

O feedback e a principal fonte de DEMANDA para novos documentos. Sem feedback, a base de conhecimento estagna.

## 7. Privacidade e Etica

- Feedbacks sao associados a user_id para analise por perfil, mas NUNCA expostos individualmente (apenas agregados)
- Comentarios livres podem conter dados sensiveis: aplicar mesma politica de confidencialidade dos documentos
- Nao usar feedback para avaliacao de desempenho individual de usuarios
- Anonimizar dados em relatorios compartilhados externamente

## Referencias

- ADR-007: Retrieval Hibrido e Agentes Especializados
- ADR-008: Governanca -- Papeis, ciclo de vida e rollback
- ADR-004: Seguranca e Classificacao de Dados
- ADR-001: Pipeline de Geracao de Conhecimento em 4 Fases

<!-- conversion_quality: 95 -->
