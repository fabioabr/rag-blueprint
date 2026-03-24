---
id: BETA-E03
title: "Gestao de Concorrencia de Releases"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-E03_gestao_concorrencia.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
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
  - adr-006
  - adr-e04
  - modelo sequencial
  - seguranca de dados
aliases:
  - "ADR-E03"
  - "Concorrencia de Releases"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## Sumario

Este documento detalha o mecanismo de controle de concorrencia para o pipeline de ingestao: como evitar que duas execucoes rodem simultaneamente contra a mesma Base Vetorial, e como releases concorrentes sao enfileiradas.

## 1. Problema: Releases Concorrentes

Cenario: uma nova release e criada enquanto o pipeline da release anterior ainda esta em execucao. Se ambas rodassem simultaneamente, haveria risco de:

- **Corrupcao de dados:** dois pipelines fazendo upsert nos mesmos nos simultaneamente.
- **Deadlocks:** transacoes concorrentes travando recursos no Neo4j.
- **Verificacao de consistencia invalida:** Etapa 7 (Observabilidade) mediria um estado intermediario misturado de duas releases.
- **Resultados imprevisiveis:** a ordem de operacoes entre dois pipelines nao e deterministica.

**REGRA ABSOLUTA: NUNCA rodar dois pipelines simultaneamente contra a mesma Base Vetorial.**

## 2. Mecanismo de Lock Exclusivo

Antes de iniciar a Etapa 1 (Descoberta), o pipeline adquire um lock exclusivo. O lock e implementado como um registro na Base Vetorial ou em um servico de coordenacao.

Dados registrados no lock:
- `pipeline_run_id`: identificador unico desta execucao
- `release_version`: versao da release sendo processada
- `started_at`: timestamp de inicio
- `PID`: identificador do processo

### Fluxo de aquisicao

1. Pipeline tenta adquirir o lock.
2. Se lock esta livre: adquire, registra dados, inicia execucao.
3. Se lock ja existe (outro pipeline em execucao): nao executa. A nova release e enfileirada para processamento posterior.

## 3. Comportamento de Fila (FIFO)

Quando o lock ja esta ocupado:

1. A nova release e adicionada a uma fila (FIFO — First In, First Out).
2. O handler do webhook retorna HTTP 202 (Accepted) para o chamador, indicando que a requisicao foi recebida e sera processada posteriormente.
3. A ordem de processamento e cronologica: a primeira release enfileirada sera processada primeiro.
4. Ao terminar a execucao corrente, o pipeline verifica se ha releases na fila e processa a proxima automaticamente.

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

### Liberacao normal

O lock e liberado automaticamente ao terminar a execucao do pipeline, independente de o resultado ser success, partial_failure ou failure.

### Timeout para processos crashados

Se o processo do pipeline crashar (OOM, kill, falha de infra), o lock ficaria preso indefinidamente. Para evitar isso:

- **Timeout de 4 horas:** se o lock existe ha mais de 4 horas sem heartbeat, e considerado abandonado e pode ser liberado.
- O proximo pipeline que tentar adquirir o lock verifica o timestamp e o libera se expirado.
- Um alerta e gerado quando um lock precisa ser liberado por timeout, pois indica que a execucao anterior falhou sem cleanup adequado.

### Por que 4 horas

Releases grandes (>1000 documentos) podem levar horas para processar, especialmente na Etapa 4 (Embeddings) com processamento em batch. 4 horas e um limite conservador que acomoda releases grandes sem risco de liberar o lock prematuramente.

## 5. Por que Nunca Executar 2 Pipelines Simultaneamente

Justificativas detalhadas:

1. **Corrupcao de dados:** Dois pipelines podem tentar criar/atualizar o mesmo no Document simultaneamente. O resultado depende da ordem de execucao das transacoes, que e nao-deterministica.

2. **Deadlocks no Neo4j:** Transacoes concorrentes competindo pelos mesmos nos e relacoes podem causar deadlocks, exigindo retry ou abort.

3. **Verificacao de consistencia invalida:** A Etapa 7 (Observabilidade) verifica que todo documento no manifesto tem no correspondente na Base Vetorial. Se duas releases rodam juntas, a verificacao de uma pode ver dados parciais da outra.

4. **Idempotencia comprometida:** A classificacao UNCHANGED da Etapa 1 depende do estado estavel da Base Vetorial. Se outro pipeline esta modificando dados simultaneamente, a comparacao de hash pode dar resultados inconsistentes.

5. **Rollback impossivel:** Com duas releases misturadas, nao ha como fazer rollback seletivo para o estado anterior a uma delas.

6. **Simplicidade e previsibilidade:** O modelo sequencial (uma release por vez) e mais simples de implementar, testar, debugar e explicar. A complexidade de processamento paralelo nao se justifica dado o volume esperado de releases (poucas por dia/semana).

<!-- conversion_quality: 95 -->
