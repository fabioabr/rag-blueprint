---
id: BETA-009
title: "Seleção de Modelos de Embedding (Trilha On-Premises)"
domain: "arquitetura"
confidentiality: internal
sources:
  - type: "txt"
    origin: "Arquitetura/rag-blueprint/kb/rag-blueprint-adrs-kb/1 - draft/ADR-009_selecao_modelos_embedding.txt"
    captured_at: "2026-03-21"
tags: [embedding, bge-m3, reranker, on-premises, soberania, trilha-b, sentence-transformers, base-vetorial, retrieval, multilingual]
aliases: ["ADR-009", "Seleção de Embedding"]
status: approved
last_enrichment: "2026-03-22"
last_human_edit: "2026-03-22"
---

## Referências Cruzadas

- **Depende de:** [[BETA-001]], [[BETA-002]]
- **Relaciona-se:** [[BETA-006]], [[BETA-007]], [[BETA-008]]

## Sumário

Este ADR define a seleção, configuração e operação dos modelos de embedding para a **Trilha B (On-Premises)** do RAG Corporativo. A Trilha B, estabelecida pela [[BETA-002]], é obrigatória para documentos classificados como "restricted" ou "confidential" — dados que NÃO PODEM sair da infraestrutura controlada pela organização.

A decisão impacta diretamente: qualidade de toda busca semântica (retrieval quality), tamanho e custo de armazenamento dos índices vetoriais, viabilidade no hardware disponível e custo de re-indexação futura.

## Contexto

### Por que a Seleção do Modelo é Crítica

O modelo de embedding é o componente mais determinante da qualidade de um sistema RAG. Se o modelo não "entende" bem português técnico, gera vetores que produzem falsos positivos e falsos negativos. **Nenhum reranker ou prompt engineering corrige um embedding ruim na origem.**

O modelo define:

- **Dimensão do vetor:** impacta tamanho do índice, latência de busca e capacidade expressiva
- **Qualidade semântica:** capacidade de capturar significado em português técnico-corporativo
- **Custo de re-embedding:** se o modelo mudar, TODOS os chunks precisam ser reprocessados (vetores de modelos diferentes são incompatíveis)
- **Tamanho do índice:** `num_chunks × dimensão × 4 bytes (float32)`
- **Compatibilidade com retrieval:** deve ser compatível com a estratégia híbrida da [[BETA-007]]

### Requisito de Soberania ([[BETA-002]], Trilha B)

Para documentos restricted/confidential:
- Modelo DEVE rodar localmente (on-premises)
- Textos dos chunks NUNCA podem ser enviados para APIs externas
- Pesos do modelo armazenados em disco local
- Inferência em GPU/CPU local

Para instituição financeira regulada por BACEN, CVM e sujeita a LGPD, isso é **obrigação regulatória**.

### Hardware do Ambiente-Alvo

| Componente | Especificação |
|------------|--------------|
| CPU | Multi-core (8+ cores) |
| RAM | 64 GB DDR4 |
| GPU | NVIDIA GeForce GTX 1070 (8 GB VRAM, Pascal, CUDA CC 6.1) |
| Disco | SSD (500+ GB livres) |

**Implicações da GTX 1070:**
- Não suporta modelos >~7B parâmetros
- BGE-M3 (~568M params) cabe com folga (~2GB VRAM em inferência)
- Batch size máximo: 16-32 para sequências de 512 tokens
- Não suporta bf16 nativamente (sem Tensor Cores), mas suporta fp16 via CUDA
- Throughput estimado: ~50-100 chunks/segundo

### Requisitos de Idioma

Modelo deve ter:
- **Excelente** suporte a português brasileiro
- **Bom** suporte a inglês (termos técnicos misturados)
- Capacidade de lidar com code-switching (mistura de idiomas)
- Reconhecimento de siglas e termos técnicos

<!-- LOCKED:START autor=fabio data=2026-03-22 -->
## Decisão — Estratégia em Camadas (Tiered)

### Componentes

| Componente | Modelo | Função |
|------------|--------|--------|
| **Modelo primário de indexação** | BGE-M3 (BAAI) | Gera embeddings densos (1024d) para todos os chunks. Roda na GTX 1070 com ~2GB VRAM |
| **Modelo de query** | BGE-M3 (mesmo modelo) | Busca assimétrica via prefixo de instrução |
| **Reranker** | BGE-Reranker-v2-m3 (BAAI) | Cross-encoder para re-ordenar top-K resultados. Roda em CPU ou GPU |
| **Modelo alternativo (baixo recurso)** | multilingual-e5-large-instruct | Para ambientes sem GPU ou como fallback |

**Todos os modelos rodam 100% on-premises, via sentence-transformers.**

### Modelo Primário — BGE-M3

O BGE-M3 (Multi-Functionality, Multi-Linguality, Multi-Granularity) é o melhor modelo de embedding open-source para cenários multilíngues on-premises (março 2026). Desenvolvido pelo BAAI, licença MIT.

**Por que BGE-M3:**

1. **Multilingual de alta qualidade:** treinado em 100+ idiomas com corpus balanceado. Performance em pt-BR comparável ou superior a modelos exclusivamente em português. MTEB: ~65-68 nDCG@10 (vs OpenAI text-embedding-3-small ~68-70, diferença aceitável para 100% local).

2. **Três modos de embedding:**
   - **Modo Denso** (1024d): vetor único por texto, busca por similaridade coseno — modo padrão
   - **Modo Esparso:** vetor com pesos por token (similar a BM25 aprendido), excelente para termos exatos
   - **Modo ColBERT:** vetor por token (multi-vector), interação tardia, qualidade superior para retrieval
   - **Recomendação Fase Inicial:** usar apenas modo denso. Modos esparso e ColBERT para fases subsequentes.

3. **Dimensão ótima (1024d):** equilíbrio entre qualidade e custo. Na Base Vetorial: 4 KB por chunk, 50.000 chunks = ~200 MB.

4. **Cabe na GTX 1070:** ~2.2 GB (fp16), sobram ~5.5 GB VRAM. Batch size recomendado: 16-24. Throughput: 50-100 chunks/s.

5. **Licença MIT:** uso comercial irrestrito, sem lock-in.

6. **Ecossistema maduro:** suportado por sentence-transformers, Ollama, LangChain, LlamaIndex, Haystack.
<!-- LOCKED:END -->

### Modelo Alternativo — multilingual-e5-large-instruct

Para cenários sem GPU disponível ou GPU ocupada:

- **Dimensão:** 1024 (compatível com índice do BGE-M3 em dimensão, mas vetores INCOMPATÍVEIS)
- **Parâmetros:** ~560M
- **CPU:** ~10-20 chunks/segundo (8 cores, 64GB RAM)
- **Qualidade:** ~2-3 pontos abaixo do BGE-M3 no MTEB
- **Modos:** apenas denso (sem esparso/ColBERT)
- **Licença:** MIT

**IMPORTANTE:** vetores do E5 são INCOMPATÍVEIS com vetores do BGE-M3. NÃO misturar no mesmo índice. Chunks processados por E5 devem ser re-embeddados com BGE-M3 quando GPU estiver disponível.

**Rastreabilidade obrigatória por chunk:**
- `embedding_model`: nome do modelo usado
- `embedding_model_version`: hash/tag do modelo no HuggingFace
- `embedding_timestamp`: data/hora da geração

### Modelo de Query — BGE-M3 (Busca Assimétrica)

Mesmo modelo para indexação e query (obrigatório: vetores no mesmo espaço dimensional).

- **Indexação (chunks):** sem prefixo, texto direto
- **Query (busca):** prefixo `"Represent this sentence for searching relevant passages: "`
- Ganho de 1-3 pontos em recall@10 com prefixo
- **Ação de validação:** testar prefixo pt-BR vs en no golden set (Fase 1)

### Reranker — BGE-Reranker-v2-m3

| Aspecto | Valor |
|---------|-------|
| Tipo | Cross-encoder multilíngue |
| Suporte pt-BR | Excelente |
| Tamanho | ~1.1 GB (fp16) |
| CPU | ~500ms para 50 passagens |
| GPU | ~50ms para 50 passagens |
| VRAM | ~1.5 GB (cabe na GTX 1070 junto com BGE-M3) |
| Licença | MIT |
| Qualidade | Comparável ao Cohere Rerank v3 (1-2 pontos diferença) |

**Integração no pipeline de retrieval ([[BETA-007]]):**
Query → Embedding BGE-M3 → Busca vetorial (top-50) → Filtros de metadados → BGE-Reranker-v2-m3 (top-10) → LLM

## Requisitos de Hardware

| Perfil | Hardware | Modelo | Throughput |
|--------|----------|--------|-----------|
| MÍNIMO (sem GPU) | 16 GB RAM, 4+ cores, SSD 256 GB | E5-large-instruct (CPU) | ~10-15 chunks/s |
| RECOMENDADO (GPU básica) | 32 GB RAM, 8+ cores, GPU 8 GB VRAM, SSD 512 GB | BGE-M3 (GPU) | ~50-80 chunks/s |
| IDEAL (GPU moderna) | 64+ GB RAM, 16+ cores, GPU 16+ GB VRAM, SSD 1 TB | BGE-M3 otimizado | ~100-200 chunks/s |

**Avaliação do ambiente-alvo (64 GB RAM + GTX 1070):** entre RECOMENDADO e IDEAL. Processamento de 50.000 chunks: ~14 minutos em GPU.

## Estratégia de Execução

### Framework Principal — sentence-transformers

Razões: maturidade, suporte nativo a BGE-M3 (3 modos), controle total (batch size, device, precisão), sem servidor adicional, compatibilidade PyTorch/CUDA/ONNX.

```python
from sentence_transformers import SentenceTransformer, CrossEncoder

# Embedding
model = SentenceTransformer('/opt/models/bge-m3', device='cuda')
embeddings = model.encode(chunks, batch_size=16, normalize_embeddings=True)

# Reranking
reranker = CrossEncoder('/opt/models/bge-reranker-v2-m3', device='cuda')
scores = reranker.predict([(query, p) for p in passages])
```

### Otimização para GTX 1070

| Parâmetro | Valor | Justificativa |
|-----------|-------|---------------|
| batch_size | 16 | Equilíbrio throughput/VRAM |
| max_seq_length | 512 tokens | Padrão BGE-M3 |
| precision | fp16 | Metade da VRAM, qualidade idêntica |
| normalize_embeddings | True | Necessário para cosine similarity |
| device | 'cuda' | GPU quando disponível |

**Se OOM:** reduzir batch_size (16→8→4), reduzir max_seq_length (512→256), fallback CPU.

### Fallback para CPU

Detecção automática de CUDA. Throughput CPU: ~10-20 chunks/s (50.000 chunks em ~40-80 min). Aceitável para processamento offline.

### Ambiente Docker

```dockerfile
FROM pytorch/pytorch:2.6.0-cuda12.6-cudnn9-runtime
RUN pip install sentence-transformers==3.4.0
```

Execução: `docker run --gpus all -v /opt/models:/opt/models ...`

### Armazenamento de Modelos

| Modelo | Tamanho |
|--------|---------|
| BGE-M3 (fp16) | ~2.2 GB |
| E5-large-instruct (fp16) | ~2.1 GB |
| BGE-Reranker-v2-m3 (fp16) | ~1.1 GB |
| **Total** | **~5.4 GB** |

**Recomendação:** baixar UMA VEZ e armazenar em diretório fixo (`/opt/models/`). NÃO depender de download automático (máquina on-premises pode não ter internet).

## Dimensão do Vetor e Impacto na Base Vetorial

### Tamanho do Índice (1024d, float32)

| Num. chunks | Índice puro | Com overhead (30%) | Com 2 réplicas |
|-------------|------------|-------------------|----------------|
| 1.000 | 4 MB | 5.2 MB | 15.6 MB |
| 10.000 | 40 MB | 52 MB | 156 MB |
| 50.000 | 200 MB | 260 MB | 780 MB |
| 100.000 | 400 MB | 520 MB | 1.56 GB |

### Comparação Trilha B vs Trilha A

| Aspecto | Trilha B (BGE-M3) | Trilha A (OpenAI) |
|---------|-------------------|-------------------|
| Dimensão | 1024 | 1536 |
| Bytes por vetor | 4.096 | 6.144 |
| Índice (50k chunks) | 200 MB | 300 MB |
| Qualidade (MTEB avg) | ~65-68 nDCG@10 | ~68-70 nDCG@10 |
| Custo por embedding | Zero (local) | US$ 0.02/1M tokens |
| Soberania | Total | Nenhuma |

**Vetores das duas trilhas são INCOMPATÍVEIS.** Índices separados por trilha, conforme [[BETA-002]].

### Custo de Re-embedding

50.000 chunks na GTX 1070: ~14 minutos. Procedimento: criar índice temporário → processar com novo modelo → validar com golden set → swap atômico → remover índice antigo.

## Benchmarks e Validação

### Golden Set

- **Mínimo:** 50 pares query-documentos
- **Ideal:** 200+ pares
- Distribuição equilibrada por domínio, incluir queries difíceis, em pt-BR/en/mistas
- Curadoria por especialistas (não gerado por IA)

### Métricas de Avaliação

- **Recall@K:** dos relevantes, quantos foram encontrados nos top-K?
- **Precision@K:** dos top-K retornados, quantos são relevantes?
- **MRR:** posição média do primeiro documento relevante
- **nDCG@K:** qualidade do ranking com relevância graduada

### Thresholds por Fase (alinhados com [[BETA-008]])

| Métrica | Fase 1 MVP | Fase 2 Meta | Fase 3 Prod |
|---------|-----------|-------------|-------------|
| Recall@10 | >= 70% | >= 80% | >= 85% |
| Precision@10 | >= 50% | >= 60% | >= 70% |
| MRR | >= 0.50 | >= 0.65 | >= 0.75 |

### Processo de Benchmark Comparativo

1. **Preparação:** golden set (50+), chunks gerados, modelos candidatos (BGE-M3, E5, nomic-embed-text, MiniLM como baseline)
2. **Embedding:** para cada modelo, gerar embeddings de todos os chunks e queries
3. **Avaliação:** para cada query, buscar top-10 por coseno, calcular métricas
4. **Comparação:** tabela consolidada
5. **Decisão:** modelo que atinge thresholds com melhor equilíbrio qualidade/throughput/hardware

## Alternativas Descartadas

| Alternativa | Motivo |
|-------------|--------|
| OpenAI text-embedding-3-small/large | Cloud-only, viola soberania ([[BETA-002]]) para restricted/confidential |
| all-MiniLM-L6/L12-v2 | Performance fraca em português (8-15 pontos abaixo no MTEB) |
| nomic-embed-text | Inferior ao BGE-M3 em benchmarks multilíngues (5-8 pontos), sem esparso/ColBERT |
| Modelos >10B params (E5-Mistral-7B) | Não cabem na GTX 1070 (8 GB VRAM); quantização degrada embeddings |
| Rerankers cloud-only (Cohere, Voyage) | Mesma restrição de soberania para Trilha B |
| Fine-tuning (fase inicial) | Complexidade prematura; BGE-M3 pré-treinado suficiente para fases 1-2 |

## Consequências

### Positivas

- **Soberania total:** nenhum texto sai da infraestrutura local
- **Custo zero por token:** viabiliza re-embedding, experimentação e CI/CD
- **Controle total do modelo:** sem risco de descontinuação, mudança de preço ou degradação silenciosa
- **Latência previsível:** sem dependência de congestionamento de API
- **Ecossistema unificado:** BGE-M3 + BGE-Reranker-v2-m3 do mesmo grupo (BAAI)

### Negativas

- **Teto de qualidade inferior ao cloud:** 2-5 pontos percentuais abaixo de modelos proprietários (aceitável)
- **Manutenção de GPU:** drivers, temperatura, backup, eventual substituição
- **Atualizações manuais:** download, benchmark, re-embedding, deploy coordenado
- **Capacidade limitada:** GTX 1070 ~60 chunks/s; 500K+ chunks requer upgrade ou paralelismo

### Riscos e Mitigações

| Risco | Mitigação |
|-------|-----------|
| GTX 1070 falha | Fallback CPU (5x menor mas funcional); planejar substituição |
| BGE-M3 descontinuado | Open-source MIT, pesos locais, comunidade pode manter forks, alternativa E5 |
| Qualidade insuficiente para domínio financeiro | Benchmark com golden set ANTES de produção; considerar fine-tuning |
| VRAM insuficiente para batch grande | Reduzir batch_size; monitorar VRAM com alertas |
| Incompatibilidade de vetores entre modelos | NUNCA misturar; registro de modelo por chunk; re-embedding completo ao trocar |
| Driver CUDA incompatível | Fixar versão no Dockerfile; testar em staging |

## Implementação — Fases

### Fase 1 — Instalação e Benchmark (Semana 1-2)

- Preparar ambiente (CUDA, Python, dependências)
- Baixar modelos (BGE-M3, BGE-Reranker, E5)
- Validar carregamento na GPU (~2-2.5 GB VRAM, dimensão 1024)
- Montar golden set inicial (50 queries)
- Executar benchmark comparativo (4 modelos), gerar relatório

### Fase 2 — Pipeline de Batch Processing (Semana 3-4)

- Implementar EmbeddingService (embed_chunks, embed_query, fallback CPU, logging)
- Processamento em batches com metadados (chunk_id, modelo, versão, timestamp)
- Observabilidade (métricas por batch e execução)
- Testes automatizados (unitário, integração, fallback, idempotência)

### Fase 3 — Integração com Base Vetorial (Semana 5-6)

- Formato de persistência (upsert com embedding + texto + metadados)
- Índice vetorial HNSW: dimensão 1024, métrica cosine, M=16, ef_construction=200, ef_search=100
- Registro de modelo por chunk e por execução
- Validação pós-ingestão com golden set

### Fase 4 — Reranker no Pipeline de Retrieval (Semana 7-8)

- Implementar RerankerService (rerank com CrossEncoder)
- Integrar ao pipeline: busca vetorial (top-50) → filtros → reranking (top-10) → LLM
- Benchmark do reranker (ganho esperado: 5-10 pontos nDCG@10)
- Otimização de latência (GPU ~50ms, CPU ~500ms para 50 passagens)

## Referências

- [[BETA-001]]: Pipeline de geração de conhecimento em 4 fases
- [[BETA-002]]: Soberania de dados — Trilha Cloud vs. On-Premises
- [[BETA-006]]: Pipeline de ingestão
- [[BETA-007]]: Retrieval híbrido e agentes especializados
- [[BETA-008]]: Governança — Papéis, ciclo de vida e rollback
- [BAAI/bge-m3](https://huggingface.co/BAAI/bge-m3)
- [BAAI/bge-reranker-v2-m3](https://huggingface.co/BAAI/bge-reranker-v2-m3)
- [intfloat/multilingual-e5-large-instruct](https://huggingface.co/intfloat/multilingual-e5-large-instruct)
- [sentence-transformers](https://sbert.net/docs/)
- [MTEB Leaderboard](https://huggingface.co/spaces/mteb/leaderboard)
- [MIRACL Benchmark](https://project-miracl.github.io/)

---

<!-- QA-BETA: inicio -->
## Quality Assurance — .beta.md

| Critério | Peso | Nota | Comentário |
|----------|------|------|------------|
| Front matter leve | 25% | 100% | id BETA-009 valido, title descritivo (53 chars), domain lowercase, confidentiality enum valido, sources com type/origin/captured_at, tags 10 itens (>= 3), status approved, aliases opcional presente. Nenhum campo de governanca indevido. |
| Completude de conteúdo | 25% | 88% | Todas as secoes principais preservadas (Contexto, Decisao, Hardware, Execucao, Dimensao do Vetor, Benchmarks, Alternativas, Consequencias, Implementacao, Referencias). Omitida secao "Framework alternativo — Ollama" (4.2 do draft) e subsecao "Posicao no pipeline" (1.3 do draft). Conteudo essencial intacto. |
| Blocos LOCKED | 15% | 100% | Um bloco LOCKED na decisao principal (Estrategia em Camadas + BGE-M3), corretamente aberto e fechado com autor e data. |
| Wikilinks | 10% | 100% | 9 wikilinks no formato [[BETA-NNN]], todos corretos (BETA-001, 002, 006, 007, 008). Nenhum wikilink no front matter. |
| Compatibilidade Obsidian | 10% | 100% | YAML valido entre delimitadores ---, tags como array, aliases como array com strings entre aspas. Totalmente compativel. |
| Clareza e estrutura | 15% | 95% | Headings claros e hierarquicos, tabelas bem formatadas, codigo Python com syntax highlight, fluxo de retrieval legivel. Estrutura de facil navegacao. |

**Score:** 95.5% — APROVADO para promoção

**Por que não é 100%:** (1) Secao "Framework alternativo — Ollama" do draft omitida no beta — conteudo complementar sobre alternativa de execucao sem Python (-3%). (2) Subsecao "Posicao no pipeline" (1.3 do draft) omitida — contextualizava onde o embedding se encaixa nas 7 etapas do pipeline (-1.5%).
<!-- QA-BETA: fim -->
