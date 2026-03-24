---
id: ADR-E01
doc_type: adr
title: "Pipeline de Ingestão Detalhado (7 Etapas)"
system: RAG Corporativo
module: Pipeline de Ingestão
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - pipeline de ingestao
  - etapas do pipeline
  - descoberta de documentos
  - parse de markdown
  - chunking semantico
  - embeddings
  - persistencia de dados
  - indexacao vetorial
  - observabilidade
  - hash sha 256
  - idempotencia
  - front matter
  - validacao de schema
  - hierarquia de headings
  - breadcrumb
  - links internos
  - blocos de codigo
  - heranca de metadados
  - faixa de tokens
  - chunking por heading
  - upsert
  - neo4j
  - base vetorial
  - indice hnsw
  - full text index
  - constraints de unicidade
  - metricas de execucao
  - recall at 10
  - golden set
  - verificacao de consistencia
  - log de execucao
  - contadores por etapa
  - latencia de embedding
  - throughput
  - tratamento de erros
  - retry com backoff
  - transacionalidade
  - batching transacional
  - checkpoint
  - release version
  - manifesto de release
  - classificacao de documentos
  - remocao de orfaos
  - chunks parcialmente falhados
  - deteccao de entidades
  - wikilinks
  - doc type
  - estrategia de chunking
  - monitoramento
  - pipeline run id
  - etapa de parse
  - etapa de persistencia
  - indice vetorial hnsw
  - metricas de qualidade
aliases:
  - "ADR-E01"
  - "Pipeline 7 Etapas"
  - "Pipeline de Ingestão Detalhado"
  - "Sete Etapas do Pipeline"
  - "Pipeline de Ingestão 7 Etapas"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/draft/ADR-E01_pipeline_ingestao_detalhado.txt"
source_beta_ids:
  - "BETA-E01"
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

# ADR-E01 — Pipeline de Ingestão Detalhado (7 Etapas)

| Campo | Valor |
|-------|-------|
| **Status** | Accepted |
| **Data da Decisão** | 2026-03-23 |
| **Decisor** | fabio |
| **Escopo** | Pipeline de Ingestão |

**Referências Cruzadas:**

- **Depende de:** [[ADR-006]]
- **Relaciona-se:** [[ADR-005]], [[ADR-002]], [[ADR-007]], [[ADR-009]]

## Sumário

Este documento extrai e detalha as 7 etapas do pipeline de ingestão definido na [[ADR-006]]. Cada etapa possui responsabilidade única, entrada e saída bem definidas, e pode ser monitorada independentemente.

Por que 7 etapas e não menos: separar em 7 etapas permite isolar falhas, medir gargalos, evoluir independentemente e testar isoladamente. Unificar etapas criaria acoplamento desnecessário e dificultaria debug em produção.

Fluxo macro:

```
[Repo knowledge-base] --> release tag -->
  [1.Descoberta] --> [2.Parse] --> [3.Chunking] -->
  [4.Embeddings] --> [5.Persistência] --> [6.Indexação] -->
  [7.Observabilidade] --> [Métricas]
```

## Etapa 1 — Descoberta

Objetivo: Identificar quais documentos .md precisam ser processados nesta execução do pipeline.

### Procedimento

1. Recebe a versão da release (ex: v1.3.0) via parâmetro de execução.

2. Lê o manifesto da release (releases/v1.3/manifest.json) que lista todos os .md incluídos.

3. Para cada arquivo .md no manifesto:
   - Calcula o hash SHA-256 do conteúdo.
   - Captura metadados do Git: path, branch, commit, last_modified.
   - Consulta a Base Vetorial para verificar se já existe um nó Document com o mesmo document_id.
   - Compara o hash armazenado com o hash calculado.

4. Classifica cada documento em uma de 4 categorias:

   - **NEW** — Documento não existe na Base Vetorial. Ação: processar todas as etapas seguintes.
   - **UPDATED** — Documento existe mas o hash mudou. Ação: re-processar todas as etapas, substituindo chunks antigos.
   - **UNCHANGED** — Documento existe e o hash é idêntico. Ação: pular completamente. Este é o mecanismo central de idempotência.
   - **DELETED** — Documento existe na Base Vetorial mas não está no manifesto. Ação: remover o nó Document e todos os seus chunks.

5. Gera relatório de descoberta com totais por categoria.

### Por que o hash é crítico para idempotência

O hash SHA-256 é uma função determinística. Se o pipeline roda 2 vezes sobre os mesmos documentos, na segunda execução todos serão UNCHANGED. Resultado: zero processamento, zero alterações.

### Alternativas descartadas

- Data de modificação (git clone reseta timestamps)
- Número de versão no front matter (depende do autor)
- Tamanho do arquivo (colisões óbvias)

### Saída

Lista de documentos com classificação, hash, path e metadados Git. Apenas NEW e UPDATED seguem para a Etapa 2.

## Etapa 2 — Parse

Objetivo: Extrair conteúdo estruturado de cada documento .md, separando metadados (front matter) de conteúdo (corpo).

### Procedimento para cada documento classificado como NEW ou UPDATED

1. **Extração do front matter:**
   - Lê o bloco YAML entre delimitadores `---`.
   - Converte em objeto estruturado com campos conforme [[ADR-005]] (Front Matter como Contrato de Metadados).

2. **Validação contra o schema ([[ADR-005]]):**
   - Verifica presença de campos obrigatórios.
   - Verifica tipos de dados.
   - Verifica consistência entre campos.
   - Se qualquer validação falha, o documento é REJEITADO.

3. **Extração da hierarquia de headings:**
   - Identifica `# H1`, `## H2`, `### H3`.
   - Constrói árvore hierárquica.
   - Cada heading recebe um breadcrumb path. Exemplo: "Módulo de Cobrança > Fluxo de Boleto > Regras de Validação"

4. **Extração de links internos:**
   - Detecta wikilinks `[[DOC-000456|título]]`.
   - Detecta links Markdown `[texto](caminho)`.
   - Registra origem, destino e texto para relações REFERENCES.

5. **Identificação de blocos de código:**
   - Detecta blocos delimitados por triple backticks.
   - Registra linguagem declarada.
   - Recebem tratamento especial no chunking (nunca divididos).

6. **Detecção de referências a entidades:**
   - Sistemas, módulos, termos de glossário mencionados no texto.
   - Alimentam criação de relações na etapa de Persistência.

### Validação bloqueante

Um documento sem front matter válido não pode ser indexado corretamente. Em produção, o documento rejeitado é:
- Registrado no log.
- Gera alerta.
- Não bloqueia demais documentos do mesmo batch.
- Pode ser corrigido na próxima release.

### Saída

Para cada documento, objeto com:
- `front_matter`
- `headings` (árvore hierárquica)
- `internal_links`
- `code_blocks`
- `entity_references`
- `raw_content`
- `validation_status`

## Etapa 3 — Chunking

Objetivo: Dividir o conteúdo em fragmentos semânticos (chunks) individualmente indexáveis e pesquisáveis.

### Por que não indexar o documento inteiro

Modelos de embedding geram vetores mais precisos para textos curtos e focados. Um documento longo sobre múltiplos temas gera um vetor "médio" que não representa bem nenhum tema individualmente. Chunks menores permitem:
- Vetores mais precisos
- Contexto mais relevante para o LLM
- Melhor ranking
- Rastreabilidade precisa

### Estratégia primária: divisão por headings

Cada seção delimitada por um heading forma um candidato a chunk.
- Se excede 800 tokens: subdivide em parágrafos.
- Se tem menos de 300 tokens: mescla com a seção seguinte.

### Faixa de tokens: 300 a 800 tokens por chunk

- **300 mínimo:** Chunks muito curtos não carregam contexto suficiente para embeddings significativos.
- **800 máximo:** Chunks muito longos diluem o foco semântico.
- A faixa 300-800 acomoda tanto glossários (termos curtos) quanto documentos arquiteturais (seções densas).

### Interação com limite do modelo de embedding ([[ADR-009]])

A faixa 300-800 foi definida para coerência semântica, não por limitação do modelo. O BGE-M3 suporta até 8192 tokens. Porém, na configuração operacional recomendada (GTX 1070, 512 max_seq_length), o pipeline deve ajustar o limite superior para ~450 tokens.

Regra obrigatória: `(chunk_tokens + breadcrumb_tokens) <= max_seq_length`

### Herança de metadados

Cada chunk herda TODOS os metadados do documento pai: `document_id`, `doc_type`, `system`, `module`, `domain`, `owner`, `team`, `confidentiality`, `tags`, `valid_from`, `valid_until`.

Crítico porque o chunk é a unidade de busca e filtros pré-retrieval são aplicados diretamente nos chunks.

### Breadcrumb (caminho de headings)

Cada chunk recebe `heading_path`. Exemplo: "Módulo de Cobrança > Boleto > Regras de Validação". Incluído no texto para dar contexto ao embedding.

### Estratégia por tipo de documento (doc_type)

- **architecture-doc:** Chunking por heading, faixa padrão. Diagramas ASCII e tabelas preservados inteiros.
- **adr:** Chunks menores e mais precisos. Cada seção estrutural (Contexto, Decisão, Alternativas, Consequências) gera exatamente 1 chunk.
- **runbook:** Chunk por procedimento/passo operacional. Cada passo numerado gera chunk independente.
- **glossary:** Chunk quase atômico. Cada termo = 1 chunk.
- **task-doc:** Chunks por seção lógica (Contexto, Escopo, Decisões técnicas, Critérios de aceite).

### Regras especiais

- Blocos de código nunca divididos no meio.
- Tabelas Markdown nunca divididas no meio. Se muito longas: divididas em grupos de linhas mantendo cabeçalho.
- Listas longas divididas em grupos temáticos.

### Chunking hierárquico (decisão adiada)

Não implementar agora. Motivos:
- Aumenta armazenamento.
- Requer resumos por LLM.
- Breadcrumb já fornece contexto suficiente para MVP.

Reconsiderar quando:
- Recall@10 cair abaixo de 70%.
- Volume ultrapassar 10.000 documentos.

### Saída

Lista de chunks por documento, cada um com:
- `chunk_id` (`{document_id}_chunk_{N}`)
- `content`
- `heading_path`
- `token_count`
- `chunk_index`
- Metadados herdados do documento pai

## Etapa 4 — Embeddings

Objetivo: Gerar vetor de embedding para cada chunk, transformando texto em representação numérica pesquisável por similaridade.

### Procedimento

1. Para cada chunk, prepara texto de entrada: `"[heading_path]\n\n[content]"`
2. Envia para o modelo de embedding em lotes (batch de 100 chunks).
3. Recebe vetor de embedding (array de floats).
4. Armazena no campo `chunk.embedding`.

### Escolha do modelo de embedding (conforme [[ADR-002]])

**Track A — Cloud (OpenAI):**
- Modelo: text-embedding-3-small
- Dimensões: 1536
- Custo: ~$0.02/1M tokens
- Latência: ~100ms/batch

**Track B — On-premises:**
- Modelo: BGE-M3 (BAAI)
- Dimensões: 1024
- Custo: zero (local)
- Latência: ~200-500ms/batch em GPU

O pipeline suporta ambos os tracks sem alteração de código (apenas configuração).

### Registro de modelo e versão

Cada chunk armazena:
- `embedding_model`
- `embedding_model_version`
- `embedding_dimensions`
- `embedded_at`

Crítico porque vetores de modelos diferentes não são compatíveis no mesmo índice.

### Processamento em lotes

Batches de 100 chunks por eficiência, rate limiting e tolerância a falha. Tamanho configurável.

### Tratamento de erros

Retry com backoff exponencial: 1s, 2s, 4s, 8s, max 60s. Após 3 retries, batch marcado como FAILED. Chunks sem embedding não são persistidos.

### Chunks parcialmente falhados

- Chunks com sucesso são persistidos normalmente.
- Chunks falhados vão para fila de retry (max 3 tentativas: 30s, 60s, 120s).
- Documento só é marcado como ingerido com sucesso quando TODOS os chunks têm embedding.
- Documentos "incomplete" são reprocessados do zero na próxima execução.
- Se permanece "incomplete" por 3+ execuções: alerta crítico.

### Saída

Chunks enriquecidos com vetor de embedding e metadados do modelo.

## Etapa 5 — Persistência

Objetivo: Gravar (ou atualizar) os dados na Base Vetorial, criando nós, relações e removendo dados obsoletos.

### Upsert de Document

- **NEW:** Cria novo nó `:Document` com propriedades do front matter. Registra `release_version`, `file_hash`, `file_path`, `git_commit`.
- **UPDATED:** Atualiza propriedades do nó existente. `document_id` é imutável.

Padrão upsert (e não delete + create) preserva relações externas enriquecidas manualmente ou por outros pipelines.

### Gerenciamento de chunks

**UPDATED:**
1. Deleta todos os chunks antigos (via relação PART_OF).
2. Cria novos chunks.
3. Cria relações `(:Chunk)-[:PART_OF]->(:Document)`.

**NEW:**
1. Cria chunks.
2. Cria relações `(:Chunk)-[:PART_OF]->(:Document)`.

### Criação/atualização de relações

Baseado em front matter e detecções do Parse:

- `(:Document)-[:BELONGS_TO]->(:Module)` via `front_matter.module`
- `(:Module)-[:BELONGS_TO]->(:System)` via `front_matter.system`
- `(:Document)-[:OWNED_BY]->(:Owner)` via `front_matter.owner`
- `(:Owner)-[:MEMBER_OF]->(:Team)` via `front_matter.team`
- `(:Document)-[:REFERENCES]->(:Document)` via links internos (se destino existe)
- `(:Document)-[:USES_TERM]->(:GlossaryTerm)` via termos detectados (se existem)
- `(:Document)-[:RELATES_TO_TASK]->(:Task)` via `front_matter.task_id`
- `(:Document)-[:SUPERSEDES]->(:Document)` via `front_matter.supersedes`
- `(:Document)-[:VERSION_OF]->(:DocumentFamily)` para docs com versionamento

Nós inexistentes (System, Module, Owner, Team) são criados automaticamente com propriedades básicas.

### Remoção de órfãos

Para documentos DELETED:
1. Remove chunks (via PART_OF).
2. Remove relações do Document.
3. Remove o nó Document.

Sem limpeza, a Base Vetorial acumula "conhecimento fantasma" — chunks de documentos que não existem mais no repositório, poluindo resultados de busca.

### Transacionalidade

Toda a etapa roda dentro de uma transação. Se qualquer operação falha: rollback completo.

### Transações em releases grandes (>1000 documentos)

Batching transacional em lotes de 100 documentos:
- Cada lote é uma transação independente.
- Checkpoint após cada lote bem-sucedido.
- Se o pipeline crashar, retoma do último checkpoint.
- Release só é marcada completa quando todos os lotes sucederem.
- Tamanho do lote é configurável.

### Saída

Base Vetorial atualizada com nós, chunks, relações e limpeza de órfãos. Contadores de operações (criados, atualizados, deletados).

## Etapa 6 — Indexação

Objetivo: Criar e manter índices para buscas eficientes.

1. **Vector index** no campo `Chunk.embedding`: Índice vetorial HNSW para busca por similaridade cosseno. Sem índice, busca seria O(n). Com HNSW, é O(log n).

2. **Full-text index** no campo `Chunk.content`: Busca por palavras-chave com suporte a português (stemming, stopwords). Complementa busca vetorial para termos exatos (códigos, siglas, nomes próprios). Ver [[ADR-007]] para busca híbrida.

3. **Índices compostos** para filtros frequentes:
   - `Chunk.system`
   - `Chunk.module`
   - `Chunk.confidentiality`
   - `Chunk.doc_type`
   - `Chunk.domain`
   - `Document.status`
   Filtros pré-retrieval precisam ser rápidos.

4. **Constraints de unicidade:**
   - `Document.document_id` (chave primária)
   - `Chunk.chunk_id` (chave primária)

5. **Índices auxiliares:**
   - `Document.file_path`
   - `Document.release_version`
   - `Document.updated_at`
   Para queries administrativas e de auditoria.

### Saída

Todos os índices criados/verificados. Índices existentes não são recriados (operação no-op, CREATE IF NOT EXISTS).

## Etapa 7 — Observabilidade

Objetivo: Registrar métricas, logs e verificações de consistência para cada execução do pipeline.

### Log de execução

- `pipeline_run_id` (identificador único da execução)
- `release_version`
- Timestamps de início e fim
- Duração total
- Trigger (webhook, manual, retry)
- Status final: `success`, `partial_failure`, `failure`

### Contadores por etapa

| Etapa | Contadores |
|-------|-----------|
| Descoberta | NEW / UPDATED / UNCHANGED / DELETED |
| Parse | validados / rejeitados |
| Chunking | total de chunks, média por documento |
| Embeddings | vetores gerados, batches ok / falhados |
| Persistência | nós criados / atualizados / deletados |
| Indexação | índices criados vs. existentes |

### Métricas de performance

- Tempo por etapa
- Latência média de embedding
- Latência de write na Base Vetorial
- Throughput (chunks/segundo)
- Tamanho do índice

### Rastreamento de erros

- Documentos falhados por etapa
- Motivo do erro
- Stack trace
- Classificação: transiente vs. permanente

### Verificação de consistência pós-execução

- Todo documento no manifesto tem nó Document correspondente.
- Todo Document tem >= 1 chunk.
- Todo chunk tem embedding.
- Nenhum chunk órfão (sem Document pai).
- Todos os chunks usam o mesmo modelo de embedding.

### Métricas de saúde

- Total de documentos na Base Vetorial
- Total de chunks
- Total de relações
- Tamanho do índice vetorial
- Data/hora da última execução
- Cobertura: % de documentos no repo com correspondente na Base Vetorial

### Métricas de qualidade de retrieval (sanity check pós-ingestão)

- Golden set de 50-100 perguntas curadas.
- Busca vetorial top-10 para cada pergunta.
- Cálculo do Recall@10 médio.
- Threshold: >= 70%.
- Se cai abaixo do threshold: alerta para o time (não bloqueia ingestão).
- Tendência entre releases consecutivas para detectar degradação.
- Ver [[ADR-007]] para métricas completas de retrieval.

### Saída

Registro completo em tabela de auditoria, métricas publicadas para dashboard, Recall@10 registrado para tendência histórica.

<!-- conversion_quality: 95 -->
