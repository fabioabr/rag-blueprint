---
id: ADR-D02
doc_type: adr
title: "Métricas de Observabilidade por Trilha"
system: RAG Corporativo
module: Observabilidade
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - métricas observabilidade
  - monitoramento pipeline
  - latência end-to-end
  - taxa erro ingestão
  - volume chunks ingeridos
  - precisão busca
  - precision at 10
  - mrr mean reciprocal rank
  - consistência base repositório
  - custo acumulado mensal
  - latência api provedor
  - rate limiting throttling
  - disponibilidade percebida
  - gpu vram uso
  - gpu utilização percentual
  - gpu temperatura
  - ram cpu servidor
  - espaço disco
  - throughput inferência
  - tokens por segundo
  - chunks por segundo
  - dashboard executivo
  - dashboard operacional
  - dashboard qualidade
  - alertas consolidados
  - trilha cloud métricas
  - trilha on-premise métricas
  - openai custo
  - anthropic custo
  - cohere custo
  - dbaas custo
  - nvidia-smi coleta
  - nvml programático
  - prometheus node exporter
  - golden set avaliação
  - baseline degradação
  - reconciliação periódica
  - armazenamento métricas
  - retenção dados
  - json formato
  - prometheus exposition format
  - grafana visualização
  - p50 p95 p99
  - http 429 too many requests
  - oom risco vram
  - throttling térmico
  - load average
  - vllm métricas
  - ollama métricas
  - série temporal
  - atualização tempo real
  - público gestão
  - público engenharia
  - público infraestrutura
  - agregação horária diária
aliases:
  - "ADR-D02"
  - "Métricas Observabilidade Trilha"
  - "Observabilidade do Pipeline RAG"
  - "Monitoramento por Trilha Cloud e On-Premise"
  - "Dashboards e Alertas RAG"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-D02_metricas_observabilidade.beta.md"
source_beta_ids:
  - "BETA-D02"
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

# ADR-D02 — Métricas de Observabilidade por Trilha

## 1. Introdução

Este documento detalha as métricas de observabilidade definidas na [[ADR-002]], alinhadas ao Pilar D (Observabilidade e Governança) da [[ADR-001]]. Cada trilha possui métricas específicas além das métricas comuns compartilhadas.

O objetivo é garantir que o pipeline RAG seja monitorável em ambas as trilhas, com dashboards e alertas adequados ao tipo de infraestrutura (cloud vs local).

Armazenamento de métricas: pasta `process/metrics/` no rag-workspace, conforme estrutura definida na [[ADR-001]].

## 2. Métricas Comuns (Ambas as Trilhas)

Estas métricas se aplicam independentemente de a execução ser Cloud ou On-Premise. São as métricas fundamentais do pipeline.

### 2.1 Latência End-to-End

| Atributo | Valor |
|---|---|
| Descrição | Tempo total desde o recebimento da query até a entrega da resposta ao usuário |
| Pontos | p50, p95, p99 |
| Meta | p95 < 3s (Trilha A), p95 < 5s (Trilha B) |
| Coleta | Timer no ponto de entrada (API gateway ou endpoint do agente) |
| Granularidade | Por request |
| Alerta | p95 > meta por 5 minutos consecutivos |

### 2.2 Taxa de Erro de Ingestão

| Atributo | Valor |
|---|---|
| Descrição | Razão entre chunks rejeitados e total de chunks processados na ingestão |
| Fórmula | `chunks_rejeitados / chunks_total * 100` |
| Meta | < 2% |
| Coleta | Contadores no pipeline de ingestão (Fase 4) |
| Granularidade | Por execução de ingestão |
| Alerta | Taxa > 5% em qualquer execução |

### 2.3 Volume de Chunks Ingeridos

| Atributo | Valor |
|---|---|
| Descrição | Total de chunks adicionados, atualizados ou removidos da base vetorial |
| Métricas | chunks_criados, chunks_atualizados, chunks_removidos (órfãos) |
| Coleta | Contadores no pipeline de persistência |
| Granularidade | Por dia e por semana |
| Dashboard | Gráfico de barras empilhadas (criados vs atualizados vs removidos) |

### 2.4 Precisão da Busca (Amostral)

| Atributo | Valor |
|---|---|
| Descrição | Qualidade dos resultados retornados pela busca vetorial |
| Métricas | precision@10 (proporção de resultados relevantes nos top 10), MRR (Mean Reciprocal Rank — posição média do primeiro resultado relevante) |
| Coleta | Avaliação periódica via golden set (conjunto de queries com respostas esperadas conhecidas) |
| Frequência | Semanal (automatizado) ou após mudança de modelo |
| Meta | precision@10 >= 0.7, MRR >= 0.6 |
| Alerta | Degradação > 10% em relação à baseline |

### 2.5 Consistência Base vs Repositório

| Atributo | Valor |
|---|---|
| Descrição | Comparação entre total de chunks na base vetorial e total de documentos no repositório Git |
| Fórmula | Contar Documents na base vs contar `.md` no repo |
| Meta | Diferença = 0 (após ingestão completa) |
| Coleta | Job de reconciliação periódico |
| Frequência | Diária |
| Alerta | Diferença > 0 por mais de 24 horas |

## 3. Métricas Específicas — Trilha A (Cloud)

Métricas exclusivas da Trilha A, focadas em custo, disponibilidade de APIs externas e rate limiting.

### 3.1 Custo Acumulado Mensal

| Atributo | Valor |
|---|---|
| Descrição | Custo total dos serviços cloud consumidos no mês |
| Componentes | Embedding (OpenAI): tokens consumidos x preço/token; LLM (Anthropic): tokens in + tokens out x preço/token; Reranking (Cohere): número de buscas x preço/busca; Base Vetorial (DBaaS): custo fixo + custo variável |
| Coleta | APIs de billing dos provedores + contadores internos |
| Granularidade | Diária (acumulado) e mensal (consolidado) |
| Dashboard | Gráfico de área empilhada por componente |
| Alerta | Custo diário > 120% da média dos últimos 30 dias |
| Alerta crítico | Custo mensal > budget definido |

**Detalhamento de custos esperados (cenário referência 10K docs, 50 usuários):**
- Embedding indexação: ~US$ 0,50 (única vez)
- Embedding query: ~US$ 2,00/mês
- Base Vetorial: ~US$ 65,00/mês
- LLM respostas: ~US$ 150,00/mês
- Reranking: ~US$ 44,00/mês
- **Total estimado: ~US$ 261,50/mês**

### 3.2 Latência de API por Provedor

| Atributo | Valor |
|---|---|
| Descrição | Tempo de resposta de cada API externa |
| Provedores | OpenAI (embedding), Anthropic (LLM), Cohere (reranking) |
| Pontos | p50, p95, p99 por provedor |
| Coleta | Timer por chamada de API |
| Granularidade | Por request, agregado por hora |
| Dashboard | Gráfico de linha com p50/p95 por provedor |
| Alerta | p95 de qualquer provedor > 5s por 10 minutos |

### 3.3 Taxa de Rate-Limiting / Throttling

| Atributo | Valor |
|---|---|
| Descrição | Porcentagem de requests que receberam HTTP 429 (Too Many Requests) |
| Fórmula | `requests_429 / requests_total * 100` |
| Por provedor | OpenAI, Anthropic, Cohere (separados) |
| Meta | < 1% |
| Coleta | Interceptor HTTP no client de cada API |
| Alerta | Taxa > 5% em janela de 15 minutos |

### 3.4 Disponibilidade Percebida

| Atributo | Valor |
|---|---|
| Descrição | Porcentagem de requests que completaram com sucesso |
| Fórmula | `requests_sucesso / requests_total * 100` |
| Inclui | HTTP 2xx como sucesso; 4xx (exceto 429) como erro do cliente; 5xx e timeouts como indisponibilidade |
| Meta | >= 99,5% |
| Coleta | Interceptor HTTP |
| Granularidade | Por hora, por dia |
| Alerta | Disponibilidade < 99% em janela de 1 hora |

## 4. Métricas Específicas — Trilha B (On-Premise)

Métricas exclusivas da Trilha B, focadas em hardware, GPU e throughput de inferência local.

### 4.1 Uso de GPU — VRAM

| Atributo | Valor |
|---|---|
| Descrição | Porcentagem de VRAM utilizada em cada GPU |
| Coleta | nvidia-smi ou NVML (programático) |
| Granularidade | A cada 30 segundos |
| Dashboard | Gauge por GPU + gráfico de linha histórico |
| Alerta | VRAM > 90% por mais de 5 minutos (risco de OOM) |

### 4.2 Utilização de GPU (%)

| Atributo | Valor |
|---|---|
| Descrição | Porcentagem de utilização do compute da GPU |
| Coleta | nvidia-smi (GPU Utilization %) |
| Granularidade | A cada 30 segundos |
| Dashboard | Gráfico de linha por GPU |
| Alerta | Utilização < 5% por 1 hora (GPU ociosa — desperdício) |
| Alerta | Utilização > 95% sustentada por 30 min (gargalo) |

### 4.3 Temperatura da GPU

| Atributo | Valor |
|---|---|
| Descrição | Temperatura do chip GPU em graus Celsius |
| Coleta | nvidia-smi |
| Granularidade | A cada 30 segundos |
| Meta | < 80°C em operação normal |
| Alerta | Temperatura > 85°C (risco de throttling térmico) |
| Alerta crítico | Temperatura > 90°C (risco de dano) |

### 4.4 Uso de RAM e CPU do Servidor

| Atributo | Valor |
|---|---|
| Descrição | Recursos do servidor que hospeda a base vetorial e/ou modelos |
| Métricas | RAM utilizada (%) e absoluta (GB); CPU utilizado (%) — média e pico; Load average (1min, 5min, 15min) |
| Coleta | Prometheus node_exporter ou equivalente |
| Granularidade | A cada 15 segundos |
| Alerta RAM | > 85% por 10 minutos |
| Alerta CPU | Load average > número de cores por 15 minutos |

### 4.5 Espaço em Disco

| Atributo | Valor |
|---|---|
| Descrição | Espaço disponível nos volumes de dados |
| Volumes | Volume da base vetorial (dados + índices); Volume de modelos (pesos do LLM, embedding, reranker); Volume de logs |
| Coleta | Prometheus node_exporter ou df |
| Granularidade | A cada 5 minutos |
| Alerta | Espaço livre < 20% |
| Alerta crítico | Espaço livre < 10% |

### 4.6 Throughput de Inferência

| Atributo | Valor |
|---|---|
| Descrição | Velocidade de processamento dos modelos locais |
| Métricas | LLM: tokens/segundo (geração); Embedding: chunks/segundo (indexação); Reranker: pares/segundo (reranking) |
| Coleta | Métricas expostas por Ollama/vLLM (LLM) e serviço de embedding |
| Granularidade | Por request, agregado por minuto |
| Dashboard | Gráfico de linha com throughput médio |

**Baseline esperada:**
- LLM 70B Q4: ~15-25 tokens/s por GPU (vLLM com batching)
- Embedding BGE-M3: ~50-100 chunks/s (GPU 16GB)
- Reranker: ~200-500 pares/s (GPU 8GB)

## 5. Dashboards Recomendados

### 5.1 Dashboard Executivo (ambas as trilhas)

- **Métricas:** Latência end-to-end (p50, p95); Volume de chunks na base (total); Precisão da busca (precision@10 mais recente); Custo mensal acumulado (Trilha A) ou uptime (Trilha B)
- **Atualização:** A cada 5 minutos
- **Público:** Gestão, Product Owner

### 5.2 Dashboard Operacional — Trilha A

- **Métricas:** Custo por componente (gráfico de área); Latência por provedor (p50, p95); Rate limiting (taxa por provedor); Disponibilidade percebida; Erros de ingestão
- **Atualização:** Tempo real (15s)
- **Público:** Engenharia de Dados

### 5.3 Dashboard Operacional — Trilha B

- **Métricas:** GPU: VRAM, utilização, temperatura (por GPU); Servidor: RAM, CPU, disco; Throughput: tokens/s, chunks/s; Erros de ingestão; Latência end-to-end
- **Atualização:** Tempo real (15s)
- **Público:** Infraestrutura / Ops

### 5.4 Dashboard de Qualidade (ambas as trilhas)

- **Métricas:** precision@10 (série temporal); MRR (série temporal); Consistência base vs repo; Taxa de erro de ingestão (série temporal)
- **Atualização:** Diária
- **Público:** Tech Lead, QA

## 6. Alertas — Resumo Consolidado

| Alerta | Trilha A | Trilha B | Ambas |
|---|---|---|---|
| Latência p95 > meta | | | X |
| Taxa erro ingestão > 5% | | | X |
| Precisão degradou > 10% | | | X |
| Consistência base vs repo != 0 | | | X |
| Custo diário > 120% média | X | | |
| Custo mensal > budget | X | | |
| Latência API > 5s (p95) | X | | |
| Rate limiting > 5% | X | | |
| Disponibilidade < 99% | X | | |
| VRAM > 90% | | X | |
| GPU temperatura > 85°C | | X | |
| RAM > 85% | | X | |
| CPU load > cores | | X | |
| Disco livre < 20% | | X | |
| GPU ociosa > 1h | | X | |

## 7. Armazenamento e Retenção

| Atributo | Valor |
|---|---|
| Local | `process/metrics/` no rag-workspace |
| Formato | JSON ou Prometheus exposition format |
| Retenção Raw (15s) | 7 dias |
| Retenção Agregado (1h) | 90 dias |
| Retenção Agregado (1d) | 1 ano |
| Backup | Junto com backup geral do workspace |

## 8. Referências

- [[ADR-002]] — Soberania de Dados: Cloud vs On-Premise (seção Observabilidade)
- [[ADR-001]] — Pipeline de Geração de Conhecimento (Pilar D — Observabilidade)
- nvidia-smi: <https://developer.nvidia.com/nvidia-system-management-interface>
- Prometheus: <https://prometheus.io>
- vLLM metrics: <https://github.com/vllm-project/vllm>

<!-- conversion_quality: 95 -->
