---
id: BETA-D02
title: "Metricas de Observabilidade por Trilha"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-D02_metricas_observabilidade.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags:
  - metricas observabilidade
  - monitoramento pipeline
  - latencia end-to-end
  - taxa erro ingestao
  - volume chunks ingeridos
  - precisao busca
  - precision at 10
  - mrr mean reciprocal rank
  - consistencia base repositorio
  - custo acumulado mensal
  - latencia api provedor
  - rate limiting throttling
  - disponibilidade percebida
  - gpu vram uso
  - gpu utilizacao percentual
  - gpu temperatura
  - ram cpu servidor
  - espaco disco
  - throughput inferencia
  - tokens por segundo
  - chunks por segundo
  - dashboard executivo
  - dashboard operacional
  - dashboard qualidade
  - alertas consolidados
  - trilha cloud metricas
  - trilha on-premise metricas
  - openai custo
  - anthropic custo
  - cohere custo
  - dbaas custo
  - nvidia-smi coleta
  - nvml programatico
  - prometheus node exporter
  - golden set avaliacao
  - baseline degradacao
  - reconciliacao periodica
  - armazenamento metricas
  - retencao dados
  - json formato
  - prometheus exposition format
  - grafana visualizacao
  - p50 p95 p99
  - http 429 too many requests
  - oom risco vram
  - throttling termico
  - load average
  - vllm metricas
  - ollama metricas
  - serie temporal
  - atualizacao tempo real
  - publico gestao
  - publico engenharia
  - publico infraestrutura
  - agregacao horaria diaria
aliases:
  - "ADR-D02"
  - "Metricas Observabilidade Trilha"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## 1. Introducao

Este documento detalha as metricas de observabilidade definidas na ADR-002, alinhadas ao Pilar D (Observabilidade e Governanca) da ADR-001. Cada trilha possui metricas especificas alem das metricas comuns compartilhadas.

O objetivo e garantir que o pipeline RAG seja monitoravel em ambas as trilhas, com dashboards e alertas adequados ao tipo de infraestrutura (cloud vs local).

Armazenamento de metricas: pasta `process/metrics/` no rag-workspace, conforme estrutura definida na ADR-001.

## 2. Metricas Comuns (Ambas as Trilhas)

Estas metricas se aplicam independentemente de a execucao ser Cloud ou On-Premise. Sao as metricas fundamentais do pipeline.

### 2.1 Latencia End-to-End

| Atributo | Valor |
|---|---|
| Descricao | Tempo total desde o recebimento da query ate a entrega da resposta ao usuario |
| Pontos | p50, p95, p99 |
| Meta | p95 < 3s (Trilha A), p95 < 5s (Trilha B) |
| Coleta | Timer no ponto de entrada (API gateway ou endpoint do agente) |
| Granularidade | Por request |
| Alerta | p95 > meta por 5 minutos consecutivos |

### 2.2 Taxa de Erro de Ingestao

| Atributo | Valor |
|---|---|
| Descricao | Razao entre chunks rejeitados e total de chunks processados na ingestao |
| Formula | `chunks_rejeitados / chunks_total * 100` |
| Meta | < 2% |
| Coleta | Contadores no pipeline de ingestao (Fase 4) |
| Granularidade | Por execucao de ingestao |
| Alerta | Taxa > 5% em qualquer execucao |

### 2.3 Volume de Chunks Ingeridos

| Atributo | Valor |
|---|---|
| Descricao | Total de chunks adicionados, atualizados ou removidos da base vetorial |
| Metricas | chunks_criados, chunks_atualizados, chunks_removidos (orfaos) |
| Coleta | Contadores no pipeline de persistencia |
| Granularidade | Por dia e por semana |
| Dashboard | Grafico de barras empilhadas (criados vs atualizados vs removidos) |

### 2.4 Precisao da Busca (Amostral)

| Atributo | Valor |
|---|---|
| Descricao | Qualidade dos resultados retornados pela busca vetorial |
| Metricas | precision@10 (proporcao de resultados relevantes nos top 10), MRR (Mean Reciprocal Rank — posicao media do primeiro resultado relevante) |
| Coleta | Avaliacao periodica via golden set (conjunto de queries com respostas esperadas conhecidas) |
| Frequencia | Semanal (automatizado) ou apos mudanca de modelo |
| Meta | precision@10 >= 0.7, MRR >= 0.6 |
| Alerta | Degradacao > 10% em relacao a baseline |

### 2.5 Consistencia Base vs Repositorio

| Atributo | Valor |
|---|---|
| Descricao | Comparacao entre total de chunks na base vetorial e total de documentos no repositorio Git |
| Formula | Contar Documents na base vs contar `.md` no repo |
| Meta | Diferenca = 0 (apos ingestao completa) |
| Coleta | Job de reconciliacao periodico |
| Frequencia | Diaria |
| Alerta | Diferenca > 0 por mais de 24 horas |

## 3. Metricas Especificas — Trilha A (Cloud)

Metricas exclusivas da Trilha A, focadas em custo, disponibilidade de APIs externas e rate limiting.

### 3.1 Custo Acumulado Mensal

| Atributo | Valor |
|---|---|
| Descricao | Custo total dos servicos cloud consumidos no mes |
| Componentes | Embedding (OpenAI): tokens consumidos x preco/token; LLM (Anthropic): tokens in + tokens out x preco/token; Reranking (Cohere): numero de buscas x preco/busca; Base Vetorial (DBaaS): custo fixo + custo variavel |
| Coleta | APIs de billing dos provedores + contadores internos |
| Granularidade | Diaria (acumulado) e mensal (consolidado) |
| Dashboard | Grafico de area empilhada por componente |
| Alerta | Custo diario > 120% da media dos ultimos 30 dias |
| Alerta critico | Custo mensal > budget definido |

**Detalhamento de custos esperados (cenario referencia 10K docs, 50 usuarios):**
- Embedding indexacao: ~US$ 0,50 (unica vez)
- Embedding query: ~US$ 2,00/mes
- Base Vetorial: ~US$ 65,00/mes
- LLM respostas: ~US$ 150,00/mes
- Reranking: ~US$ 44,00/mes
- **Total estimado: ~US$ 261,50/mes**

### 3.2 Latencia de API por Provedor

| Atributo | Valor |
|---|---|
| Descricao | Tempo de resposta de cada API externa |
| Provedores | OpenAI (embedding), Anthropic (LLM), Cohere (reranking) |
| Pontos | p50, p95, p99 por provedor |
| Coleta | Timer por chamada de API |
| Granularidade | Por request, agregado por hora |
| Dashboard | Grafico de linha com p50/p95 por provedor |
| Alerta | p95 de qualquer provedor > 5s por 10 minutos |

### 3.3 Taxa de Rate-Limiting / Throttling

| Atributo | Valor |
|---|---|
| Descricao | Porcentagem de requests que receberam HTTP 429 (Too Many Requests) |
| Formula | `requests_429 / requests_total * 100` |
| Por provedor | OpenAI, Anthropic, Cohere (separados) |
| Meta | < 1% |
| Coleta | Interceptor HTTP no client de cada API |
| Alerta | Taxa > 5% em janela de 15 minutos |

### 3.4 Disponibilidade Percebida

| Atributo | Valor |
|---|---|
| Descricao | Porcentagem de requests que completaram com sucesso |
| Formula | `requests_sucesso / requests_total * 100` |
| Inclui | HTTP 2xx como sucesso; 4xx (exceto 429) como erro do cliente; 5xx e timeouts como indisponibilidade |
| Meta | >= 99,5% |
| Coleta | Interceptor HTTP |
| Granularidade | Por hora, por dia |
| Alerta | Disponibilidade < 99% em janela de 1 hora |

## 4. Metricas Especificas — Trilha B (On-Premise)

Metricas exclusivas da Trilha B, focadas em hardware, GPU e throughput de inferencia local.

### 4.1 Uso de GPU — VRAM

| Atributo | Valor |
|---|---|
| Descricao | Porcentagem de VRAM utilizada em cada GPU |
| Coleta | nvidia-smi ou NVML (programatico) |
| Granularidade | A cada 30 segundos |
| Dashboard | Gauge por GPU + grafico de linha historico |
| Alerta | VRAM > 90% por mais de 5 minutos (risco de OOM) |

### 4.2 Utilizacao de GPU (%)

| Atributo | Valor |
|---|---|
| Descricao | Porcentagem de utilizacao do compute da GPU |
| Coleta | nvidia-smi (GPU Utilization %) |
| Granularidade | A cada 30 segundos |
| Dashboard | Grafico de linha por GPU |
| Alerta | Utilizacao < 5% por 1 hora (GPU ociosa — desperdicio) |
| Alerta | Utilizacao > 95% sustentada por 30 min (gargalo) |

### 4.3 Temperatura da GPU

| Atributo | Valor |
|---|---|
| Descricao | Temperatura do chip GPU em graus Celsius |
| Coleta | nvidia-smi |
| Granularidade | A cada 30 segundos |
| Meta | < 80C em operacao normal |
| Alerta | Temperatura > 85C (risco de throttling termico) |
| Alerta critico | Temperatura > 90C (risco de dano) |

### 4.4 Uso de RAM e CPU do Servidor

| Atributo | Valor |
|---|---|
| Descricao | Recursos do servidor que hospeda a base vetorial e/ou modelos |
| Metricas | RAM utilizada (%) e absoluta (GB); CPU utilizado (%) — media e pico; Load average (1min, 5min, 15min) |
| Coleta | Prometheus node_exporter ou equivalente |
| Granularidade | A cada 15 segundos |
| Alerta RAM | > 85% por 10 minutos |
| Alerta CPU | Load average > numero de cores por 15 minutos |

### 4.5 Espaco em Disco

| Atributo | Valor |
|---|---|
| Descricao | Espaco disponivel nos volumes de dados |
| Volumes | Volume da base vetorial (dados + indices); Volume de modelos (pesos do LLM, embedding, reranker); Volume de logs |
| Coleta | Prometheus node_exporter ou df |
| Granularidade | A cada 5 minutos |
| Alerta | Espaco livre < 20% |
| Alerta critico | Espaco livre < 10% |

### 4.6 Throughput de Inferencia

| Atributo | Valor |
|---|---|
| Descricao | Velocidade de processamento dos modelos locais |
| Metricas | LLM: tokens/segundo (geracao); Embedding: chunks/segundo (indexacao); Reranker: pares/segundo (reranking) |
| Coleta | Metricas expostas por Ollama/vLLM (LLM) e servico de embedding |
| Granularidade | Por request, agregado por minuto |
| Dashboard | Grafico de linha com throughput medio |

**Baseline esperada:**
- LLM 70B Q4: ~15-25 tokens/s por GPU (vLLM com batching)
- Embedding BGE-M3: ~50-100 chunks/s (GPU 16GB)
- Reranker: ~200-500 pares/s (GPU 8GB)

## 5. Dashboards Recomendados

### 5.1 Dashboard Executivo (ambas as trilhas)

- **Metricas:** Latencia end-to-end (p50, p95); Volume de chunks na base (total); Precisao da busca (precision@10 mais recente); Custo mensal acumulado (Trilha A) ou uptime (Trilha B)
- **Atualizacao:** A cada 5 minutos
- **Publico:** Gestao, Product Owner

### 5.2 Dashboard Operacional — Trilha A

- **Metricas:** Custo por componente (grafico de area); Latencia por provedor (p50, p95); Rate limiting (taxa por provedor); Disponibilidade percebida; Erros de ingestao
- **Atualizacao:** Tempo real (15s)
- **Publico:** Engenharia de Dados

### 5.3 Dashboard Operacional — Trilha B

- **Metricas:** GPU: VRAM, utilizacao, temperatura (por GPU); Servidor: RAM, CPU, disco; Throughput: tokens/s, chunks/s; Erros de ingestao; Latencia end-to-end
- **Atualizacao:** Tempo real (15s)
- **Publico:** Infraestrutura / Ops

### 5.4 Dashboard de Qualidade (ambas as trilhas)

- **Metricas:** precision@10 (serie temporal); MRR (serie temporal); Consistencia base vs repo; Taxa de erro de ingestao (serie temporal)
- **Atualizacao:** Diaria
- **Publico:** Tech Lead, QA

## 6. Alertas — Resumo Consolidado

| Alerta | Trilha A | Trilha B | Ambas |
|---|---|---|---|
| Latencia p95 > meta | | | X |
| Taxa erro ingestao > 5% | | | X |
| Precisao degradou > 10% | | | X |
| Consistencia base vs repo != 0 | | | X |
| Custo diario > 120% media | X | | |
| Custo mensal > budget | X | | |
| Latencia API > 5s (p95) | X | | |
| Rate limiting > 5% | X | | |
| Disponibilidade < 99% | X | | |
| VRAM > 90% | | X | |
| GPU temperatura > 85C | | X | |
| RAM > 85% | | X | |
| CPU load > cores | | X | |
| Disco livre < 20% | | X | |
| GPU ociosa > 1h | | X | |

## 7. Armazenamento e Retencao

| Atributo | Valor |
|---|---|
| Local | `process/metrics/` no rag-workspace |
| Formato | JSON ou Prometheus exposition format |
| Retencao Raw (15s) | 7 dias |
| Retencao Agregado (1h) | 90 dias |
| Retencao Agregado (1d) | 1 ano |
| Backup | Junto com backup geral do workspace |

## 8. Referencias

- ADR-002: Soberania de Dados — Cloud vs On-Premise (secao Observabilidade)
- ADR-001: Pipeline de Geracao de Conhecimento (Pilar D — Observabilidade)
- nvidia-smi: <https://developer.nvidia.com/nvidia-system-management-interface>
- Prometheus: <https://prometheus.io>
- vLLM metrics: <https://github.com/vllm-project/vllm>

<!-- conversion_quality: 95 -->
