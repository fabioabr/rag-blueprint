---
id: ADR-D04
doc_type: adr
title: "Checklist de Deploy por Trilha"
system: RAG Corporativo
module: Deploy por Trilha
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - checklist deploy
  - deploy trilha cloud
  - deploy trilha on premise
  - deploy trilha híbrida
  - pré requisitos deploy
  - base vetorial managed
  - base vetorial self hosted
  - docker compose
  - neo4j community edition
  - neo4j docker
  - constraints índices
  - vector index criação
  - pipeline ingestão
  - embedding openai
  - embedding bge m3
  - llm claude deploy
  - llm ollama deploy
  - llm vllm deploy
  - reranking cohere deploy
  - reranking bge reranker deploy
  - validação pós deploy
  - golden set queries
  - latência p95
  - api keys vault
  - billing configuração
  - tier volume
  - rede firewall
  - tls certificados
  - gpu drivers cuda
  - nvidia container toolkit
  - nvidia smi verificação
  - air gapped servidor
  - cross instância integração
  - merge resultados scores
  - controle acesso permissões
  - pre retrieval filter
  - rollback base vetorial
  - rollback modelo llm
  - rollback modelo embedding
  - re indexação chunks
  - fases implementação
  - mvp fase 1
  - reranking fase 2
  - trilha b fase 3
  - híbrida fase 4
  - definition of done
  - precision at 10 melhoria
  - system prompt citação
  - português brasileiro
  - backup restore
  - neo4j admin dump
  - tensor parallel size
  - gpu memory utilization
  - awq quantização
  - gguf quantização
  - flagembedding python
  - fastapi uvicorn
  - prometheus métricas
  - temperatura alertas
  - disco alertas
  - dns firewall saída
aliases:
  - "ADR-D04"
  - "Checklist Deploy Trilha"
  - "Checklist de Deploy por Trilha"
  - "Runbook de Deploy RAG"
  - "Procedimento de Deploy Pipeline RAG"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/beta/ADR-D04_checklist_deploy_por_trilha.beta.md"
source_beta_ids:
  - "BETA-D04"
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

# ADR-D04 — Checklist de Deploy por Trilha

| Campo       | Valor                                                         |
|-------------|---------------------------------------------------------------|
| **Status**  | Accepted                                                      |
| **Data**    | 23/03/2026                                                    |
| **Decisor** | fabio (arquitetura)                                           |
| **Escopo**  | Runbook de deploy e validação para cada trilha do pipeline RAG, com checklists pré-deploy, procedimentos de instalação e validação pós-deploy |

**Referências cruzadas:**

- [[ADR-002]]: Soberania de Dados — Cloud vs On-Premise
- [[ADR-001]]: Pipeline de Geração de Conhecimento em 4 Fases
- [[ADR-003]]: Modelo de Dados da Base Vetorial (constraints e índices)
- [[ADR-D03]]: Capacity Planning e Dimensionamento de Infraestrutura

## Introdução

Runbook de deploy e validação para cada trilha do pipeline RAG, conforme definido na [[ADR-002]]. Cobre checklists pré-deploy, procedimentos de instalação, configuração de componentes e validação pós-deploy.

Cada trilha possui seu próprio checklist completo. A Trilha Híbrida requer a execução de AMBOS os checklists (A e B) mais validações adicionais de integração.

## Trilha A (Cloud) — Checklist de Deploy

### Pré-requisitos

- [ ] Contas criadas nos provedores:
  - [ ] OpenAI — conta ativa com billing configurado
  - [ ] Anthropic — conta ativa com billing configurado
  - [ ] Cohere — conta ativa com billing configurado
  - [ ] Provedor de base vetorial — conta ativa

- [ ] API keys geradas e armazenadas em vault seguro:
  - [ ] `OPENAI_API_KEY`
  - [ ] `ANTHROPIC_API_KEY`
  - [ ] `COHERE_API_KEY`
  - [ ] `NEO4J_URI` (ou equivalente do provedor)
  - [ ] `NEO4J_USER`
  - [ ] `NEO4J_PASSWORD`

- [ ] Tier contratado suporta volume estimado:
  - [ ] OpenAI: verificar TPM e RPM do tier
  - [ ] Anthropic: verificar limites de tokens/minuto
  - [ ] Cohere: verificar limites de buscas/minuto

- [ ] Rede e conectividade:
  - [ ] Acesso HTTPS para APIs externas liberado no firewall
  - [ ] DNS resolvendo corretamente endpoints dos provedores
  - [ ] Certificados TLS válidos

### Deploy — Base Vetorial Managed

- [ ] Instância provisionada no provedor cloud
- [ ] Região selecionada (preferencialmente próxima aos usuários)
- [ ] Credenciais de acesso configuradas
- [ ] Constraints criados:
  - [ ] `CONSTRAINT unique_document_id ON (d:Document) ASSERT d.document_id IS UNIQUE`
  - [ ] `CONSTRAINT unique_chunk_id ON (c:Chunk) ASSERT c.chunk_id IS UNIQUE`
- [ ] Índices criados:
  - [ ] `INDEX idx_doc_path FOR (d:Document) ON (d.path)`
  - [ ] `INDEX idx_doc_type FOR (d:Document) ON (d.doc_type)`
  - [ ] `INDEX idx_doc_system FOR (d:Document) ON (d.system)`
  - [ ] `INDEX idx_doc_module FOR (d:Document) ON (d.module)`
  - [ ] `INDEX idx_doc_confidentiality FOR (d:Document) ON (d.confidentiality)`
- [ ] Vector index criado:
  - [ ] `CREATE VECTOR INDEX chunk_embedding FOR (c:Chunk) ON (c.embedding) OPTIONS {indexConfig: {vector.dimensions: 1536, vector.similarity_function: 'cosine'}}`
- [ ] Backup automatizado habilitado
- [ ] Teste de conexão bem-sucedido

### Deploy — Pipeline de Ingestão (Trilha A)

- [ ] Pipeline configurado para filtrar `confidentiality = public | internal`
- [ ] Endpoint de embedding apontando para OpenAI text-embedding-3-small
- [ ] Dimensão do embedding = 1536
- [ ] Teste de ingestão com 10 documentos de amostra:
  - [ ] Front matter parseado corretamente
  - [ ] Chunks gerados dentro da faixa 300-800 tokens
  - [ ] Embeddings gerados com 1536 dimensões
  - [ ] Nodes Document e Chunk criados na base
  - [ ] Relação PART_OF criada entre Chunk e Document
  - [ ] Metadados do chunk incluem `embedding_model` e `embedding_date`

### Deploy — LLM (Claude)

- [ ] API key Anthropic configurada no serviço de geração
- [ ] Modelo selecionado:
  - [ ] Claude Sonnet para respostas RAG
  - [ ] Claude Opus para mineração complexa (Fases 2/3)
- [ ] System prompt configurado com instruções de citação de fontes
- [ ] Teste de geração:
  - [ ] Enviar query de teste
  - [ ] Resposta gerada em < 5s
  - [ ] Resposta cita fontes (document_id, título)
  - [ ] Resposta em português brasileiro

### Deploy — Reranking (Cohere)

- [ ] API key Cohere configurada
- [ ] Endpoint apontando para Rerank v3
- [ ] Teste de reranking:
  - [ ] Enviar 50 candidatos com query de teste
  - [ ] Resultado reordenado retornado em < 200ms
  - [ ] Ordem dos resultados é diferente da busca vetorial pura
  - [ ] precision@10 melhora >= 15% com reranking (medir com golden set)

### Validação Pós-Deploy — Trilha A

- [ ] Busca vetorial retorna resultados corretos para 10 queries do golden set
- [ ] LLM gera respostas com citação de fontes
- [ ] Nenhum documento restricted/confidential foi ingerido (verificar logs)
- [ ] Latência end-to-end p95 < 3s
- [ ] Métricas de custo sendo coletadas
- [ ] Alertas de rate-limiting configurados
- [ ] Dashboard operacional acessível

## Trilha B (On-Premise) — Checklist de Deploy

### Pré-requisitos de Hardware

- [ ] Servidor provisionado:
  - [ ] CPU: 8+ cores
  - [ ] RAM: 64GB+ DDR5
  - [ ] Storage: NVMe 1TB+
  - [ ] Fonte: 1000W+ (80+ Gold)

- [ ] GPUs instaladas:
  - [ ] GPU 1: RTX 4090 24GB (ou equivalente) — para LLM
  - [ ] GPU 2: RTX 4090 24GB (ou equivalente) — para LLM (segunda GPU)
  - [ ] (Opcional) GPU 3: RTX 3060 8GB — dedicada para embedding/reranker

- [ ] Drivers e runtime:
  - [ ] NVIDIA Driver instalado (versão 535+ recomendada)
  - [ ] CUDA Toolkit instalado (12.x)
  - [ ] nvidia-smi retorna informações de ambas as GPUs
  - [ ] Docker instalado com NVIDIA Container Toolkit
  - [ ] nvidia-docker funcional (`docker run --gpus all nvidia/cuda nvidia-smi`)

- [ ] Rede:
  - [ ] Servidor NÃO possui acesso à internet (air-gapped para dados confidential)
  - [ ] Rede interna acessível para usuários autorizados
  - [ ] Firewall bloqueando tráfego de saída

### Deploy — Base Vetorial Self-Hosted (Docker)

**Procedimento:**

1. Criar diretório de dados:

```bash
mkdir -p /opt/neo4j/data /opt/neo4j/logs /opt/neo4j/conf
```

2. Docker Compose para base vetorial:

```yaml
# docker-compose-neo4j.yml
version: '3.8'
services:
  neo4j:
    image: neo4j:5.18-community
    container_name: neo4j-rag-onprem
    ports:
      - "7474:7474"   # HTTP / Browser
      - "7687:7687"   # Bolt
    volumes:
      - /opt/neo4j/data:/data
      - /opt/neo4j/logs:/logs
      - /opt/neo4j/conf:/conf
    environment:
      - NEO4J_AUTH=neo4j/SenhaSeguraAqui123!
      - NEO4J_PLUGINS=["apoc"]
      - NEO4J_server_memory_heap_initial__size=4g
      - NEO4J_server_memory_heap_max__size=8g
      - NEO4J_server_memory_pagecache_size=4g
      - NEO4J_dbms_security_procedures_unrestricted=apoc.*
    restart: unless-stopped
```

3. Subir container:

```bash
docker compose -f docker-compose-neo4j.yml up -d
```

4. Verificar:

```bash
docker logs neo4j-rag-onprem --tail 50
# Deve mostrar "Started." sem erros
```

**Checklist pós-instalação:**
- [ ] Container rodando e saudável (`docker ps`)
- [ ] Porta 7474 acessível (browser)
- [ ] Porta 7687 acessível (bolt)
- [ ] Constraints e índices criados (mesmos da seção anterior, exceto vector index com dimensão 1024 ao invés de 1536):
  - [ ] `CREATE VECTOR INDEX chunk_embedding FOR (c:Chunk) ON (c.embedding) OPTIONS {indexConfig: {vector.dimensions: 1024, vector.similarity_function: 'cosine'}}`
- [ ] Backup manual testado (`neo4j-admin dump`)

### Deploy — Modelo de Embedding (BGE-M3 via serviço local)

**Opção A — Via script Python dedicado:**

```python
# Requer: pip install FlagEmbedding torch
from FlagEmbedding import BGEM3FlagModel
model = BGEM3FlagModel('BAAI/bge-m3', use_fp16=True)
embeddings = model.encode(['texto de teste'])['dense_vecs']
print(f"Dimensão: {embeddings.shape[1]}")  # Deve ser 1024
```

**Opção B — Via API local (recomendado para produção):**
Usar framework como FastAPI + uvicorn expondo endpoint `/embed`. Carregar modelo uma vez na inicialização. Expor endpoint POST `/embed` que recebe textos e retorna vetores.

**Checklist:**
- [ ] Modelo BGE-M3 baixado (~2.4GB)
- [ ] Modelo carregado na GPU (verificar nvidia-smi: ~4-6GB VRAM ocupada)
- [ ] Teste de embedding:
  - [ ] Enviar texto em português
  - [ ] Retorna vetor de 1024 dimensões
  - [ ] Tempo < 50ms para texto único
- [ ] Serviço de embedding acessível na rede interna

### Deploy — LLM via Ollama (Desenvolvimento/Teste)

**Procedimento:**

1. Instalar Ollama:

```bash
curl -fsSL https://ollama.ai/install.sh | sh
```

2. Baixar modelo:

```bash
ollama pull llama3.1:70b-instruct-q4_K_M

# Alternativa Qwen:
# ollama pull qwen2.5:72b-instruct-q4_K_M
```

3. Verificar:

```bash
ollama list
# Deve mostrar o modelo com ~40GB de tamanho
```

4. Testar:

```bash
ollama run llama3.1:70b-instruct-q4_K_M "Responda em português: o que é RAG?"
```

5. API local (padrão porta 11434):

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.1:70b-instruct-q4_K_M",
  "prompt": "O que é GraphRAG?",
  "stream": false
}'
```

**Checklist Ollama:**
- [ ] Ollama instalado e rodando como serviço
- [ ] Modelo 70B Q4 baixado
- [ ] Ambas as GPUs sendo utilizadas (nvidia-smi mostra VRAM em uso)
- [ ] Resposta gerada em < 30s para prompt médio
- [ ] API acessível em localhost:11434

### Deploy — LLM via vLLM (Produção)

**Procedimento:**

1. Docker Compose para vLLM:

```yaml
# docker-compose-vllm.yml
version: '3.8'
services:
  vllm:
    image: vllm/vllm-openai:latest
    container_name: vllm-rag-onprem
    ports:
      - "8000:8000"
    volumes:
      - /opt/models:/models
    environment:
      - CUDA_VISIBLE_DEVICES=0,1
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 2
              capabilities: [gpu]
    command: >
      --model /models/llama-3.1-70b-instruct-awq
      --quantization awq
      --tensor-parallel-size 2
      --max-model-len 8192
      --gpu-memory-utilization 0.90
      --api-key token-local-seguro
    restart: unless-stopped
```

2. Subir:

```bash
docker compose -f docker-compose-vllm.yml up -d
```

3. Verificar:

```bash
curl http://localhost:8000/v1/models
# Deve listar o modelo carregado
```

4. Testar (API compatível com OpenAI):

```bash
curl http://localhost:8000/v1/chat/completions -H "Content-Type: application/json" \
  -H "Authorization: Bearer token-local-seguro" \
  -d '{
    "model": "llama-3.1-70b-instruct-awq",
    "messages": [{"role": "user", "content": "O que é RAG?"}],
    "max_tokens": 500
  }'
```

**Checklist vLLM:**
- [ ] Container vLLM rodando
- [ ] Modelo carregado nas 2 GPUs (tensor parallel)
- [ ] API compatível com OpenAI acessível em :8000
- [ ] Throughput: >= 15 tokens/s (medir com benchmark)
- [ ] Batching funcional: múltiplas requests simultâneas processadas
- [ ] Métricas expostas em `/metrics` (Prometheus format)

### Deploy — Modelo de Reranking (BGE-Reranker-v2-m3)

Procedimento similar ao embedding (seção de deploy BGE-M3):

```python
# Requer: pip install FlagEmbedding torch
from FlagEmbedding import FlagReranker
reranker = FlagReranker('BAAI/bge-reranker-v2-m3', use_fp16=True)
scores = reranker.compute_score([
    ['query de teste', 'passagem candidata 1'],
    ['query de teste', 'passagem candidata 2']
])
print(scores)  # Lista de scores, maior = mais relevante
```

**Checklist:**
- [ ] Modelo BGE-Reranker-v2-m3 baixado (~1.2GB)
- [ ] Modelo carregado na GPU (~2-4GB VRAM)
- [ ] Teste de reranking:
  - [ ] 50 pares query-passagem
  - [ ] Retorna scores em < 150ms
  - [ ] Ordem faz sentido semanticamente
- [ ] Serviço acessível na rede interna

### Validação Pós-Deploy — Trilha B

- [ ] GPU(s) instalada(s) e CUDA funcionando
- [ ] Base vetorial self-hosted rodando via Docker
- [ ] BGE-M3 carregado e gerando embeddings de 1024 dimensões
- [ ] Llama/Qwen servido via Ollama ou vLLM
- [ ] BGE-Reranker carregado e funcionando
- [ ] Pipeline de ingestão filtra `confidentiality = restricted | confidential`
- [ ] Busca vetorial retorna resultados corretos para 10 queries do golden set
- [ ] Nenhum dado restricted/confidential sai da rede local:
  - [ ] Verificar logs de rede (nenhuma conexão externa)
  - [ ] Verificar firewall (saída bloqueada)
  - [ ] Verificar DNS (não resolve domínios externos)
- [ ] Latência end-to-end p95 < 5s (busca + reranking + geração)
- [ ] Métricas de GPU sendo coletadas (nvidia-smi ou NVML)
- [ ] Alertas de temperatura e disco configurados
- [ ] Dashboard operacional acessível

## Trilha Híbrida — Checklist Adicional

Além de completar TODOS os itens das seções de Trilha A e Trilha B acima:

### Integração Cross-Instância

- [ ] Retriever configurado para buscar em AMBAS as instâncias em paralelo
- [ ] Timeout configurado para cada instância (evitar bloqueio se uma cair)
- [ ] Merge de resultados implementado:
  - [ ] Resultados textuais (não embeddings) mesclados
  - [ ] Scores normalizados entre instâncias (escalas diferentes)
- [ ] Reranking local (BGE-Reranker) aplicado ao conjunto mesclado:
  - [ ] Regra: se chunks restricted/confidential estão no conjunto, reranking DEVE ser local (Trilha B)
  - [ ] Regra: se apenas chunks public/internal, reranking pode ser cloud (Cohere) ou local
- [ ] LLM para geração de resposta:
  - [ ] Regra: se contexto inclui chunks restricted/confidential, LLM DEVE ser local (Llama/Qwen)
  - [ ] Regra: se contexto é apenas public/internal, LLM pode ser cloud (Claude) ou local

### Controle de Acesso

- [ ] Sistema de permissões implementado:
  - [ ] Usuário com nível public: vê apenas resultados public
  - [ ] Usuário com nível internal: vê public + internal
  - [ ] Usuário com nível restricted: vê public + internal + restricted
  - [ ] Usuário com nível confidential: vê todos
- [ ] Permissões verificadas ANTES da busca (pre-retrieval filter)
- [ ] Logs de acesso registrando usuário, nível, queries e resultados

### Validação Pós-Deploy — Híbrida

- [ ] Busca cross-instância retorna resultados de ambas as bases
- [ ] Reranking local funciona com chunks de ambas as trilhas
- [ ] Controle de acesso funcional (testar com usuários de níveis diferentes)
- [ ] Resposta final não vaza dados restricted para usuários sem permissão
- [ ] Latência end-to-end p95 < 5s (inclui busca paralela + merge + reranking)

## Procedimentos de Rollback

### Rollback — Base Vetorial

**Cloud:**
- Restaurar snapshot/backup automático do provedor
- Tempo estimado: 5-15 minutos

**On-Premise:**
- `neo4j-admin database load --from-path=/backups/neo4j-YYYYMMDD`
- Tempo estimado: 10-30 minutos dependendo do volume

### Rollback — Modelo de LLM

**Ollama:**

```bash
ollama rm llama3.1:70b-instruct-q4_K_M
ollama pull llama3.1:70b-instruct-q4_K_M   # Re-download da versão anterior
```

**vLLM:**

```bash
# Alterar --model no docker-compose para versão anterior
docker compose -f docker-compose-vllm.yml down
docker compose -f docker-compose-vllm.yml up -d
```

### Rollback — Modelo de Embedding

> **ATENÇÃO:** trocar o modelo de embedding requer RE-INDEXAR todos os chunks, pois os vetores são incompatíveis entre versões/modelos diferentes.

**Procedimento:**
1. Restaurar modelo anterior
2. Limpar todos os embeddings na base (`DELETE c.embedding` para todos Chunks)
3. Re-executar pipeline de ingestão completo
4. Tempo estimado: proporcional ao número de chunks (50K chunks ~= 15-30 min)

## Ordem de Implementação (Fases)

Conforme definido na [[ADR-002]]:

**Fase 1 — MVP:**
- Escopo: Trilha A apenas (public/internal)
- Deploy: Base vetorial managed + OpenAI embedding + Claude LLM
- Sem reranking
- DOD: Busca vetorial retorna resultados corretos para 10 queries; LLM gera respostas com citação de fonte

**Fase 2 — Reranking + Qualidade:**
- Escopo: Adicionar Cohere Rerank v3 na Trilha A
- DOD: precision@10 melhora >= 15% com reranking

**Fase 3 — Trilha B:**
- Escopo: Provisionar hardware, instalar base vetorial self-hosted, BGE-M3, Llama/Qwen via Ollama/vLLM, BGE-Reranker
- DOD: Checklist Trilha B completo; Nenhum dado restricted/confidential trafega por rede externa; Latência < 2s

**Fase 4 — Trilha Híbrida:**
- Escopo: Retriever cross-instância, merge de resultados, controle de acesso por usuário
- DOD: Busca cross-instância correta; Controle de acesso funcional; Reranking local com chunks de ambas as trilhas

## Referências

- [[ADR-002]]: Soberania de Dados — Cloud vs On-Premise
- [[ADR-001]]: Pipeline de Geração de Conhecimento em 4 Fases
- [[ADR-003]]: Modelo de Dados da Base Vetorial (constraints e índices)
- Neo4j Docker: <https://neo4j.com/docs/operations-manual/current/docker/>
- Ollama: <https://ollama.ai>
- vLLM Docker: <https://docs.vllm.ai/en/latest/serving/deploying_with_docker.html>
- BGE-M3: <https://huggingface.co/BAAI/bge-m3>
- BGE-Reranker-v2-m3: <https://huggingface.co/BAAI/bge-reranker-v2-m3>
- NVIDIA Container Toolkit: <https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/>

<!-- conversion_quality: 95 -->
