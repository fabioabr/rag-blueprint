---
id: ADR-E03
doc_type: adr
title: "Gestão de Concorrência de Releases"
system: RAG Corporativo
module: Concorrência
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - gestao de concorrencia
  - releases concorrentes
  - lock exclusivo
  - fila fifo
  - pipeline de ingestao
  - base vetorial
  - corrupcao de dados
  - deadlock
  - neo4j
  - transacoes concorrentes
  - verificacao de consistencia
  - idempotencia
  - rollback
  - timeout de lock
  - heartbeat
  - pipeline run id
  - release version
  - processo crashado
  - out of memory
  - http 202
  - webhook handler
  - processamento sequencial
  - controle de concorrencia
  - upsert simultaneo
  - observabilidade
  - etapa 7
  - etapa 1 descoberta
  - classificacao unchanged
  - ordem cronologica
  - liberacao de lock
  - lock abandonado
  - alerta de timeout
  - releases grandes
  - etapa 4 embeddings
  - batch processing
  - pid do processo
  - started at
  - regra absoluta
  - simplicidade operacional
  - previsibilidade
  - estado intermediario
  - resultados imprevisiveis
  - ordem de operacoes
  - determinismo
  - processamento paralelo
  - volume de releases
  - modelo sequencial
  - seguranca de dados
  - aquisicao de lock
  - lock exclusivo distribuido
  - servico de coordenacao
aliases:
  - "ADR-E03"
  - "Concorrência de Releases"
  - "Gestão de Concorrência"
  - "Lock Exclusivo de Pipeline"
  - "Controle de Concorrência do Pipeline"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/draft/ADR-E03_gestao_concorrencia.txt"
source_beta_ids:
  - "BETA-E03"
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

# ADR-E03 — Gestão de Concorrência de Releases

| Campo | Valor |
|-------|-------|
| **Status** | Accepted |
| **Data da Decisão** | 2026-03-23 |
| **Decisor** | fabio |
| **Escopo** | Concorrência |

**Referências Cruzadas:**

- **Depende de:** [[ADR-006]]
- **Relaciona-se:** [[ADR-E04]], [[ADR-E01]]

## Sumário

Este documento detalha o mecanismo de controle de concorrência para o pipeline de ingestão: como evitar que duas execuções rodem simultaneamente contra a mesma Base Vetorial, e como releases concorrentes são enfileiradas.

## 1. Problema: Releases Concorrentes

Cenário: uma nova release é criada enquanto o pipeline da release anterior ainda está em execução. Se ambas rodassem simultaneamente, haveria risco de:

- **Corrupção de dados:** dois pipelines fazendo upsert nos mesmos nós simultaneamente.
- **Deadlocks:** transações concorrentes travando recursos no Neo4j.
- **Verificação de consistência inválida:** Etapa 7 (Observabilidade) mediria um estado intermediário misturado de duas releases.
- **Resultados imprevisíveis:** a ordem de operações entre dois pipelines não é determinística.

**REGRA ABSOLUTA: NUNCA rodar dois pipelines simultaneamente contra a mesma Base Vetorial.**

## 2. Mecanismo de Lock Exclusivo

Antes de iniciar a Etapa 1 (Descoberta), o pipeline adquire um lock exclusivo. O lock é implementado como um registro na Base Vetorial ou em um serviço de coordenação.

Dados registrados no lock:
- `pipeline_run_id`: identificador único desta execução
- `release_version`: versão da release sendo processada
- `started_at`: timestamp de início
- `PID`: identificador do processo

### Fluxo de aquisição

1. Pipeline tenta adquirir o lock.
2. Se lock está livre: adquire, registra dados, inicia execução.
3. Se lock já existe (outro pipeline em execução): não executa. A nova release é enfileirada para processamento posterior.

## 3. Comportamento de Fila (FIFO)

Quando o lock já está ocupado:

1. A nova release é adicionada a uma fila (FIFO — First In, First Out).
2. O handler do webhook retorna HTTP 202 (Accepted) para o chamador, indicando que a requisição foi recebida e será processada posteriormente.
3. A ordem de processamento é cronológica: a primeira release enfileirada será processada primeiro.
4. Ao terminar a execução corrente, o pipeline verifica se há releases na fila e processa a próxima automaticamente.

### Diagrama

```
Release v1.3.0 chega -> Lock livre -> Adquire lock -> Executa pipeline
Release v1.4.0 chega -> Lock ocupado -> Enfileira -> HTTP 202
Release v1.5.0 chega -> Lock ocupado -> Enfileira -> HTTP 202

v1.3.0 termina -> Libera lock -> Processa v1.4.0 da fila
v1.4.0 termina -> Libera lock -> Processa v1.5.0 da fila
v1.5.0 termina -> Libera lock -> Fila vazia -> Aguarda
```

## 4. Limpeza e Timeout do Lock

### Liberação normal

O lock é liberado automaticamente ao terminar a execução do pipeline, independente de o resultado ser success, partial_failure ou failure.

### Timeout para processos crashados

Se o processo do pipeline crashar (OOM, kill, falha de infra), o lock ficaria preso indefinidamente. Para evitar isso:

- **Timeout de 4 horas:** se o lock existe há mais de 4 horas sem heartbeat, é considerado abandonado e pode ser liberado.
- O próximo pipeline que tentar adquirir o lock verifica o timestamp e o libera se expirado.
- Um alerta é gerado quando um lock precisa ser liberado por timeout, pois indica que a execução anterior falhou sem cleanup adequado.

### Por que 4 horas

Releases grandes (>1000 documentos) podem levar horas para processar, especialmente na Etapa 4 (Embeddings) com processamento em batch. 4 horas é um limite conservador que acomoda releases grandes sem risco de liberar o lock prematuramente.

## 5. Por que Nunca Executar 2 Pipelines Simultaneamente

Justificativas detalhadas:

1. **Corrupção de dados:** Dois pipelines podem tentar criar/atualizar o mesmo nó Document simultaneamente. O resultado depende da ordem de execução das transações, que é não-determinística.

2. **Deadlocks no Neo4j:** Transações concorrentes competindo pelos mesmos nós e relações podem causar deadlocks, exigindo retry ou abort.

3. **Verificação de consistência inválida:** A Etapa 7 (Observabilidade) verifica que todo documento no manifesto tem nó correspondente na Base Vetorial. Se duas releases rodam juntas, a verificação de uma pode ver dados parciais da outra.

4. **Idempotência comprometida:** A classificação UNCHANGED da Etapa 1 depende do estado estável da Base Vetorial. Se outro pipeline está modificando dados simultaneamente, a comparação de hash pode dar resultados inconsistentes.

5. **Rollback impossível:** Com duas releases misturadas, não há como fazer rollback seletivo para o estado anterior a uma delas.

6. **Simplicidade e previsibilidade:** O modelo sequencial (uma release por vez) é mais simples de implementar, testar, debugar e explicar. A complexidade de processamento paralelo não se justifica dado o volume esperado de releases (poucas por dia/semana).

<!-- conversion_quality: 95 -->
