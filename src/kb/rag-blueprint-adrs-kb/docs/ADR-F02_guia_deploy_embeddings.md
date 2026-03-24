---
id: ADR-F02
doc_type: adr
title: "Guia de Deploy do Modelo de Embedding (On-Premises)"
system: RAG Corporativo
module: Deploy Embeddings
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - guia de deploy
  - modelo de embedding
  - on premises
  - bge m3
  - bge reranker v2 m3
  - sentence transformers
  - docker
  - gpu gtx 1070
  - cuda
  - nvidia driver
  - nvidia container toolkit
  - pytorch
  - python
  - health check
  - vram
  - fp16
  - batch size
  - max seq length
  - normalize embeddings
  - fallback cpu
  - throughput
  - busca assimetrica
  - prefixo de instrucao
  - cross encoder
  - reranker
  - reranking
  - multilingual e5 large
  - huggingface
  - download de modelos
  - armazenamento de modelos
  - versionamento de modelos
  - rastreabilidade por chunk
  - embedding model
  - embedding model version
  - embedding timestamp
  - embedding device
  - embedding batch id
  - out of memory
  - oom
  - thermal throttling
  - batch processing
  - checkpoint
  - otimizacao de gpu
  - dockerfile
  - docker run
  - endpoint de health
  - verificacao de consistencia
  - similaridade coseno
  - norma l2
  - pascal cuda cc 6.1
  - bf16
  - tensor cores
  - ssd
  - ram 64 gb
  - cpu 8 cores
  - swap atomico
  - rollback de modelo
  - ingestao em massa
aliases:
  - "ADR-F02"
  - "Deploy de Embeddings"
  - "Guia de Deploy On-Premises"
  - "Deploy BGE-M3"
  - "Configuração de Embedding On-Premises"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/draft/ADR-F02_guia_deploy_embeddings.txt"
source_beta_ids:
  - "BETA-F02"
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

# ADR-F02 — Guia de Deploy do Modelo de Embedding (On-Premises)

| Campo | Valor |
|-------|-------|
| **Status** | Accepted |
| **Data da Decisão** | 2026-03-23 |
| **Decisor** | fabio |
| **Escopo** | Deploy Embeddings |

**Referências Cruzadas:**

- **Depende de:** [[ADR-009]], [[ADR-002]]
- **Relaciona-se:** [[ADR-006]], [[ADR-F01]]

## Objetivo

Guia prático para instalação, configuração e operação do modelo de embedding BGE-M3 e do reranker BGE-Reranker-v2-m3 em ambiente on-premises, usando sentence-transformers como framework principal. Inclui configuração Docker, otimização para GPU GTX 1070 e procedimentos de health check.

## 1. Pré-requisitos

### 1.1 Hardware Mínimo

| Componente | Especificação |
|-----------|--------------|
| CPU | Multi-core (8+ cores) |
| RAM | 64 GB DDR4 |
| GPU | NVIDIA GeForce GTX 1070 (8 GB VRAM, Pascal, CUDA CC 6.1) |
| Disco | SSD com 500+ GB livres |

### 1.2 Software Base

- NVIDIA Driver compatível com CUDA 12.6
- Docker com suporte a `--gpus` (nvidia-container-toolkit)
- Python 3.10+ (se execução fora do Docker)

### 1.3 Modelos (download prévio obrigatório)

| Modelo | Tamanho | Função |
|--------|---------|--------|
| BGE-M3 (fp16) | ~2.2 GB | Embedding primário (indexação e query) |
| BGE-Reranker-v2-m3 (fp16) | ~1.1 GB | Cross-encoder para reranking |
| multilingual-e5-large (fp16) | ~2.1 GB | Fallback para ambientes sem GPU |
| **TOTAL** | **~5.4 GB** | |

**IMPORTANTE:** baixar modelos UMA VEZ e armazenar em diretório fixo (`/opt/models/`). Máquina on-premises pode não ter acesso à internet. Não depender de download automático do HuggingFace em runtime.

Procedimento de download (máquina com internet):

```bash
pip install huggingface_hub
huggingface-cli download BAAI/bge-m3 --local-dir /opt/models/bge-m3
huggingface-cli download BAAI/bge-reranker-v2-m3 --local-dir /opt/models/bge-reranker-v2-m3
huggingface-cli download intfloat/multilingual-e5-large-instruct --local-dir /opt/models/e5-large
```

Transferir `/opt/models/` para a máquina on-premises via SCP, rsync ou mídia física.

## 2. Configuração Docker

### 2.1 Dockerfile

```dockerfile
FROM pytorch/pytorch:2.6.0-cuda12.6-cudnn9-runtime
RUN pip install sentence-transformers==3.4.0
```

Construir imagem:

```bash
docker build -t rag-embedding:1.0 .
```

### 2.2 Execução com GPU

```bash
docker run --gpus all \
  -v /opt/models:/opt/models \
  -v /data/embeddings:/data/embeddings \
  -p 8080:8080 \
  rag-embedding:1.0
```

Flags importantes:
- `--gpus all` — Expõe todas as GPUs para o container
- `-v /opt/models` — Monta diretório dos modelos (somente leitura recomendado)
- `-v /data/embeddings` — Diretório de saída para embeddings gerados

### 2.3 Verificação pós-deploy

Dentro do container:

```python
python -c "import torch; print(torch.cuda.is_available())"
# Deve imprimir: True

python -c "import torch; print(torch.cuda.get_device_name(0))"
# Deve imprimir: NVIDIA GeForce GTX 1070
```

## 3. Código de Referência — sentence-transformers

### 3.1 Carregamento do Modelo de Embedding

```python
from sentence_transformers import SentenceTransformer

model = SentenceTransformer('/opt/models/bge-m3', device='cuda')

# Indexação de chunks (sem prefixo)
embeddings = model.encode(
    chunks,
    batch_size=16,
    normalize_embeddings=True,
    show_progress_bar=True
)
```

### 3.2 Embedding de Queries (busca assimétrica)

```python
# Queries usam prefixo de instrução para busca assimétrica
prefix = "Represent this sentence for searching relevant passages: "
query_with_prefix = prefix + query_text

query_embedding = model.encode(
    [query_with_prefix],
    normalize_embeddings=True
)
```

**NOTA:** validar se prefixo em pt-BR oferece ganho vs prefixo em inglês. Testar ambos no golden set durante Fase 1.

### 3.3 Carregamento e Uso do Reranker

```python
from sentence_transformers import CrossEncoder

reranker = CrossEncoder('/opt/models/bge-reranker-v2-m3', device='cuda')

# Reranking de passagens candidatas
pairs = [(query_text, passage) for passage in candidate_passages]
scores = reranker.predict(pairs)

# Ordenar por score decrescente
ranked_indices = scores.argsort()[::-1]
top_passages = [candidate_passages[i] for i in ranked_indices[:10]]
```

### 3.4 Fallback Automático para CPU

```python
import torch

device = 'cuda' if torch.cuda.is_available() else 'cpu'
model = SentenceTransformer('/opt/models/bge-m3', device=device)

# Throughput esperado:
#   GPU (GTX 1070): ~50-100 chunks/segundo
#   CPU (8 cores):  ~10-20 chunks/segundo
```

Se CUDA não disponível, logar warning e prosseguir em CPU. Throughput em CPU é aceitável para processamento offline.

## 4. Otimização para GTX 1070

### 4.1 Parâmetros Recomendados

| Parâmetro | Valor | Justificativa |
|-----------|-------|--------------|
| batch_size | 16 | Equilíbrio throughput/VRAM na GTX 1070 |
| max_seq_length | 512 | Padrão do BGE-M3, máximo suportado |
| precision | fp16 | Metade da VRAM, qualidade idêntica |
| normalize_embeddings | True | Necessário para similaridade cosseno |
| device | cuda | GPU quando disponível |

### 4.2 Uso de VRAM Esperado

| Componente | VRAM |
|-----------|------|
| BGE-M3 (fp16) | ~2.2 GB |
| BGE-Reranker-v2-m3 (fp16) | ~1.5 GB |
| Ambos carregados | ~3.7 GB |
| Sobra na GTX 1070 (8 GB) | ~4.3 GB |

Ambos os modelos cabem simultaneamente na GPU com folga.

### 4.3 Procedimento em Caso de OOM (Out of Memory)

Ordem de ações se ocorrer erro de CUDA Out of Memory:

1. Reduzir batch_size: 16 -> 8 -> 4
2. Reduzir max_seq_length: 512 -> 256 (aceitar truncamento de chunks longos)
3. Descarregar reranker da GPU (usar CPU para reranking)
4. Fallback completo para CPU

**NOTA:** GTX 1070 não suporta bf16 nativamente (sem Tensor Cores). Usar fp16 via CUDA, que é suportado.

### 4.4 Batch Processing para Ingestão em Massa

Estimativa para 50.000 chunks na GTX 1070:
- Throughput: ~50-80 chunks/segundo
- Tempo total: ~10-17 minutos
- Recomendação: processar em horário de baixa demanda

Processar em lotes com checkpoint:
- Salvar progresso a cada 1.000 chunks
- Em caso de falha, retomar do último checkpoint
- Registrar metadados por chunk: chunk_id, modelo, versão, timestamp

## 5. Health Checks

### 5.1 Verificação de GPU

- `torch.cuda.is_available() == True`
- `torch.cuda.get_device_name(0)` retorna nome esperado
- `torch.cuda.mem_get_info()` retorna VRAM livre suficiente (>= 3 GB)

### 5.2 Verificação de Modelo

- Modelo carrega sem erro
- Embedding de texto de teste retorna vetor com dimensão 1024
- Embedding normalizado (norma L2 ~= 1.0)

### 5.3 Verificação de Throughput

- Processar 100 chunks de teste
- Throughput >= 30 chunks/s em GPU (threshold mínimo)
- Throughput >= 5 chunks/s em CPU (threshold mínimo)
- Se abaixo do threshold, gerar alerta

### 5.4 Verificação de Consistência

- Gerar embedding do mesmo texto 2 vezes
- Similaridade cosseno entre os dois vetores deve ser >= 0.9999
- Se não, modelo pode estar corrompido ou com problema de precisão

### 5.5 Endpoint de Health (se exposto como serviço)

```
GET /health
```

Retorna:
- `status`: "ok" ou "degraded" ou "error"
- `device`: "cuda" ou "cpu"
- `model_loaded`: true/false
- `reranker_loaded`: true/false
- `vram_free_gb`: X.X
- `last_embedding_timestamp`: ISO 8601

## 6. Armazenamento e Versionamento de Modelos

Estrutura de diretórios:

```
/opt/models/
  bge-m3/                    # Modelo primário
  bge-reranker-v2-m3/        # Reranker
  e5-large/                  # Fallback
```

Regras:
- Nunca sobrescrever modelo em produção diretamente
- Para upgrade: baixar em diretório temporário, validar com golden set, swap atômico (renomear diretórios)
- Manter versão anterior por pelo menos 30 dias (rollback)
- Registrar hash do modelo no HuggingFace para reprodutibilidade

## 7. Rastreabilidade por Chunk

Todo chunk processado DEVE registrar:

| Campo | Exemplo |
|-------|---------|
| `embedding_model` | BAAI/bge-m3 |
| `embedding_model_version` | commit hash do HuggingFace |
| `embedding_timestamp` | 2026-03-23T14:30:00Z |
| `embedding_device` | cuda (ou cpu) |
| `embedding_batch_id` | UUID da execução de batch |

Estes campos são OBRIGATÓRIOS para:
- Identificar chunks que precisam de re-embedding ao trocar modelo
- Auditar consistência do índice vetorial
- Diagnosticar problemas de qualidade

## Referências

- [[ADR-009]]: Seleção de Modelos de Embedding (Trilha On-Premises)
- [[ADR-002]]: Soberania de Dados — Trilha Cloud vs. On-Premises
- [[ADR-006]]: Pipeline de Ingestão
- [sentence-transformers](https://sbert.net/docs/)
- [BAAI/bge-m3](https://huggingface.co/BAAI/bge-m3)
- [BAAI/bge-reranker-v2-m3](https://huggingface.co/BAAI/bge-reranker-v2-m3)

<!-- conversion_quality: 95 -->
