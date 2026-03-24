---
id: ADR-006
doc_type: adr
title: "Pipeline de Ingestão: Da Fonte à Base Vetorial"
system: RAG Corporativo
module: Pipeline de Ingestão
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-21
tags:
  - pipeline ingestão
  - base vetorial
  - chunking semântico
  - embeddings
  - indexação
  - idempotência
  - observabilidade
  - descoberta documentos
  - parse front matter
  - persistência grafo
  - upsert neo4j
  - hash sha 256
  - release tag
  - manifest json
  - webhook
  - trigger release
  - concorrência releases
  - lock exclusivo
  - fila fifo
  - reindexação blue green
  - vector index hnsw
  - full text index
  - índices compostos
  - constraints unicidade
  - herança metadados
  - breadcrumb headings
  - chunking por tipo
  - faixa tokens
  - batch processing
  - backoff exponencial
  - transacionalidade
  - checkpoint
  - limpeza órfãos
  - recall golden set
  - métricas performance
  - log execução
  - contadores etapa
  - verificação consistência
  - track cloud
  - track on premises
  - bge m3
  - text embedding 3 small
  - embedding model version
  - document classification
  - chunks parciais
  - rollback release
  - versionamento base vetorial
  - doc type estratégia
  - rate limiting
  - pipeline 7 etapas
  - ingestão vetorial
  - neo4j grafo
  - semver
aliases:
  - ADR-006
  - Pipeline de Ingestão
  - Pipeline 7 Etapas
  - Ingestão na Base Vetorial
  - Pipeline de Ingestão Vetorial
  - ADR Pipeline Ingestão
superseded_by: null
source_format: txt
source_repo: Rag
source_path:
  - "src/kb/rag-blueprint-adrs-draft/draft/ADR-E01_pipeline_ingestao_detalhado.txt"
  - "src/kb/rag-blueprint-adrs-draft/draft/ADR-E02_trigger_ingestao.txt"
  - "src/kb/rag-blueprint-adrs-draft/draft/ADR-E03_gestao_concorrencia.txt"
  - "src/kb/rag-blueprint-adrs-draft/draft/ADR-E04_garantias_idempotencia.txt"
  - "src/kb/rag-blueprint-adrs-draft/draft/ADR-E06_reindexacao_blue_green.txt"
source_beta_ids:
  - BETA-006
conversion_pipeline: promotion-pipeline-v2
conversion_quality: 95
converted_at: 2026-03-23
qa_score: null
qa_date: null
qa_status: pending
created_at: 2026-03-21
updated_at: 2026-03-23
valid_from: 2026-03-21
valid_until: null
---

# ADR-006 — Pipeline de Ingestão: Da Fonte à Base Vetorial

## Contexto

Esta ADR define o pipeline completo que transforma documentos `.md` finais (produzidos na Fase 3 da [[ADR-001]]) em conhecimento pesquisável dentro da Base Vetorial. A Fase 4 da [[ADR-001]] mencionava "ingestão no banco vetorial" de forma resumida — este documento detalha **cada etapa** desse processo.

A Base Vetorial não é um simples banco de dados onde se "joga" arquivos. Ela é uma estrutura sofisticada que combina vetores de embedding, nós de grafo, relações semânticas e metadados estruturados. Para que essa estrutura funcione corretamente, o pipeline de ingestão precisa ser rigoroso, previsível e observável.

### Premissas fundamentais

1. **Idempotência** — Re-executar o pipeline sobre o mesmo conjunto de documentos DEVE produzir zero alterações. Crítico porque webhooks podem disparar duplicados, cron jobs podem sobrepor execuções e falhas parciais exigem re-tentativa segura.

2. **Re-indexação** — Quando o modelo de embedding muda (ex: de `text-embedding-3-small` para `text-embedding-3-large`), o pipeline precisa re-gerar todos os vetores sem downtime. Vetores de modelos diferentes vivem em espaços dimensionais incompatíveis.

3. **Limpeza de órfãos** — Se um documento é removido do repositório knowledge-base, seus chunks na Base Vetorial devem ser eliminados. Chunks órfãos poluem resultados de busca.

4. **Trigger por release** — O pipeline não roda continuamente. É disparado por tags de release no repositório knowledge-base (conforme [[ADR-001]], Fase 3). Apenas documentos aprovados e versionados entram na Base Vetorial.

5. **Compatibilidade com [[ADR-003]]** — O pipeline deve popular os nós e relações definidos no modelo de dados (Document, Chunk, System, Module, Owner, Team, etc.) respeitando constraints de unicidade e tipos de propriedades.

### Diagrama do fluxo macro

```
[Repo knowledge-base]     [Pipeline de Ingestão - 7 Etapas]     [Base Vetorial]
      |                                                                |
      |   release tag                                                  |
      +----------> [1.Descoberta] --> [2.Parse] --> [3.Chunking]       |
                       |                |              |               |
                       v                v              v               |
                   [4.Embeddings] --> [5.Persistência] --> [6.Indexação]
                                          |                    |
                                          v                    v
                                    [7.Observabilidade] --> [Métricas]
```

## Decisão — Pipeline de 7 Etapas

O pipeline de ingestão é composto por 7 etapas sequenciais. Cada etapa tem responsabilidade única, entrada e saída bem definidas, e pode ser monitorada independentemente.

Por que 7 etapas e não menos: separar em 7 etapas permite isolar falhas, medir gargalos, evoluir independentemente e testar isoladamente. Unificar etapas criaria acoplamento desnecessário e dificultaria debug em produção.

### Etapa 1 — Descoberta

**Objetivo**: Identificar quais documentos `.md` precisam ser processados nesta execução do pipeline.

Procedimento:

1. Recebe a versão da release (ex: `v1.3.0`) via parâmetro de execução.
2. Lê o manifesto da release (`releases/v1.3/manifest.json`) que lista todos os `.md` incluídos.
3. Para cada arquivo `.md` no manifesto:
   - Calcula o hash SHA-256 do conteúdo
   - Captura metadados do Git: `path`, `branch`, `commit`, `last_modified`
   - Consulta a Base Vetorial para verificar se já existe um nó Document com o mesmo `document_id`
   - Compara o hash armazenado com o hash calculado
4. Classifica cada documento em uma de 4 categorias:
   - **NEW**: documento não existe na Base Vetorial. Ação: processar todas as etapas seguintes.
   - **UPDATED**: documento existe mas o hash mudou. Ação: re-processar todas as etapas, substituindo chunks antigos.
   - **UNCHANGED**: documento existe e o hash é idêntico. Ação: pular completamente. Este é o mecanismo central de idempotência.
   - **DELETED**: documento existe na Base Vetorial mas não está no manifesto. Ação: remover o nó Document e todos os seus chunks.
5. Gera relatório de descoberta com totais por categoria.

**Por que o hash é crítico para idempotência**: o hash SHA-256 é uma função determinística. Se o pipeline roda 2 vezes sobre os mesmos documentos, na segunda execução todos serão UNCHANGED. Resultado: zero processamento, zero alterações.

Alternativas descartadas: data de modificação (git clone reseta timestamps), número de versão no front matter (depende do autor), tamanho do arquivo (colisões óbvias).

**Saída**: lista de documentos com classificação, hash, path e metadados Git. Apenas NEW e UPDATED seguem para a Etapa 2.

### Etapa 2 — Parse

**Objetivo**: Extrair conteúdo estruturado de cada documento `.md`, separando metadados (front matter) de conteúdo (corpo).

Procedimento para cada documento classificado como NEW ou UPDATED:

1. **Extração do front matter**: lê o bloco YAML entre `---`, converte em objeto estruturado com campos conforme [[ADR-005]]
2. **Validação contra o schema** ([[ADR-005]]): verifica presença de campos obrigatórios, tipos de dados, consistência. Se qualquer validação falha, o documento é **rejeitado**
3. **Extração da hierarquia de headings**: identifica `# H1`, `## H2`, `### H3`, constrói árvore hierárquica, cada heading recebe um breadcrumb path (ex: "Módulo de Cobrança > Fluxo de Boleto > Regras de Validação")
4. **Extração de links internos**: detecta wikilinks `[[DOC-000456|título]]` e links Markdown `[texto](caminho)`. Registra origem, destino e texto para relações REFERENCES
5. **Identificação de blocos de código**: detecta blocos delimitados por triple backticks, registra linguagem. Recebem tratamento especial no chunking (nunca divididos)
6. **Detecção de referências a entidades**: sistemas, módulos, termos de glossário. Alimentam criação de relações na Persistência

A validação é **bloqueante**: um documento sem front matter válido não pode ser indexado corretamente. Em produção, o documento rejeitado é registrado no log, gera alerta, não bloqueia demais documentos e pode ser corrigido na próxima release.

**Saída**: para cada documento, objeto com `front_matter`, `headings`, `internal_links`, `code_blocks`, `entity_references`, `raw_content` e `validation_status`.

### Etapa 3 — Chunking

**Objetivo**: Dividir o conteúdo em fragmentos semânticos (chunks) individualmente indexáveis e pesquisáveis.

Por que não indexar o documento inteiro: modelos de embedding geram vetores mais precisos para textos curtos e focados. Um documento longo sobre múltiplos temas gera um vetor "médio" que não representa bem nenhum tema individualmente. Chunks menores permitem vetores mais precisos, contexto mais relevante para o LLM, melhor ranking e rastreabilidade precisa.

**Estratégia primária — divisão por headings**: cada seção delimitada por um heading forma um candidato a chunk. Se excede 800 tokens, subdivide em parágrafos. Se tem menos de 300 tokens, mescla com a seção seguinte.

**Faixa de tokens: 300 a 800 tokens por chunk**:

- **300 mínimo**: chunks muito curtos não carregam contexto suficiente para embeddings significativos
- **800 máximo**: chunks muito longos diluem o foco semântico
- A faixa 300-800 acomoda tanto glossários (termos curtos) quanto documentos arquiteturais (seções densas)

**Interação com limite do modelo de embedding** (ver [[ADR-009]]): a faixa 300-800 foi definida para coerência semântica, não por limitação do modelo. O BGE-M3 suporta até 8192 tokens. Porém, na configuração operacional recomendada (GTX 1070, 512 max_seq_length), o pipeline deve ajustar o limite superior para ~450 tokens. O pipeline DEVE validar: `(chunk_tokens + breadcrumb_tokens) <= max_seq_length`.

**Herança de metadados**: cada chunk herda **todos** os metadados do documento pai (`document_id`, `doc_type`, `system`, `module`, `domain`, `owner`, `team`, `confidentiality`, `tags`, `valid_from`, `valid_until`). Crítico porque o chunk é a unidade de busca e filtros pré-retrieval são aplicados diretamente nos chunks.

**Breadcrumb (caminho de headings)**: cada chunk recebe `heading_path` (ex: "Módulo de Cobrança > Boleto > Regras de Validação"), incluído no texto para dar contexto ao embedding.

**Estratégia por tipo de documento** (`doc_type`):

- **architecture-doc**: chunking por heading, faixa padrão, diagramas ASCII e tabelas preservados inteiros
- **adr**: chunks menores e mais precisos, cada seção estrutural (Contexto, Decisão, Alternativas, Consequências) gera exatamente 1 chunk
- **runbook**: chunk por procedimento/passo operacional, cada passo numerado gera chunk independente
- **glossary**: chunk quase atômico, cada termo = 1 chunk
- **task-doc**: chunks por seção lógica (Contexto, Escopo, Decisões técnicas, Critérios de aceite)

**Regras especiais**:

- Blocos de código nunca divididos no meio
- Tabelas Markdown nunca divididas no meio (se muito longas, divididas em grupos de linhas mantendo cabeçalho)
- Listas longas divididas em grupos temáticos

**Chunking hierárquico — decisão adiada**: não implementar agora (aumenta armazenamento, requer resumos por LLM, breadcrumb já fornece contexto suficiente para MVP). Reconsiderar quando Recall@10 cair abaixo de 70% ou volume ultrapassar 10.000 documentos.

**Saída**: lista de chunks por documento, cada um com `chunk_id` (`{document_id}_chunk_{N}`), `content`, `heading_path`, `token_count`, `chunk_index` e metadados herdados.

### Etapa 4 — Embeddings

**Objetivo**: Gerar vetor de embedding para cada chunk, transformando texto em representação numérica pesquisável por similaridade.

Procedimento:

1. Para cada chunk, prepara texto de entrada: `"[heading_path]\n\n[content]"`
2. Envia para o modelo de embedding em **lotes** (batch de 100 chunks)
3. Recebe vetor de embedding (array de floats)
4. Armazena no campo `chunk.embedding`

**Escolha do modelo de embedding** (conforme [[ADR-002]]):

| Track | Modelo | Dimensões | Custo | Latência |
|---|---|---|---|---|
| A — Cloud (OpenAI) | `text-embedding-3-small` | 1536 | ~$0.02/1M tokens | ~100ms/batch |
| B — On-premises | BGE-M3 (BAAI) | 1024 | zero (local) | ~200-500ms/batch em GPU |

O pipeline suporta **ambos os tracks** sem alteração de código (apenas configuração).

**Registro de modelo e versão**: cada chunk armazena `embedding_model`, `embedding_model_version`, `embedding_dimensions` e `embedded_at`. Crítico porque vetores de modelos diferentes não são compatíveis no mesmo índice.

**Processamento em lotes**: batches de 100 chunks por eficiência, rate limiting e tolerância a falha. Tamanho configurável.

**Tratamento de erros**: retry com backoff exponencial (1s, 2s, 4s, 8s, max 60s). Após 3 retries, batch marcado como FAILED. Chunks sem embedding não são persistidos.

**Chunks parcialmente falhados**: chunks com sucesso são persistidos normalmente. Chunks falhados vão para fila de retry (max 3 tentativas, 30s/60s/120s). Documento só é marcado como ingerido com sucesso quando todos os chunks têm embedding. Documentos "incomplete" são reprocessados do zero na próxima execução. Se permanece "incomplete" por 3+ execuções: alerta crítico.

**Saída**: chunks enriquecidos com vetor de embedding e metadados do modelo.

### Etapa 5 — Persistência

**Objetivo**: Gravar (ou atualizar) os dados na Base Vetorial, criando nós, relações e removendo dados obsoletos.

**Upsert de Document**:

- **NEW**: cria novo nó `:Document` com propriedades do front matter, registra `release_version`, `file_hash`, `file_path`, `git_commit`
- **UPDATED**: atualiza propriedades do nó existente, `document_id` imutável

Padrão **upsert** (e não delete + create) preserva relações externas enriquecidas manualmente ou por outros pipelines.

**Gerenciamento de chunks**:

- **UPDATED**: deleta todos os chunks antigos (via `PART_OF`), cria novos, cria relações `(:Chunk)-[:PART_OF]->(:Document)`
- **NEW**: cria chunks e relações

**Criação/atualização de relações** (baseado em front matter e detecções do Parse):

- `(:Document)-[:BELONGS_TO]->(:Module)` — via `front_matter.module`
- `(:Module)-[:BELONGS_TO]->(:System)` — via `front_matter.system`
- `(:Document)-[:OWNED_BY]->(:Owner)` — via `front_matter.owner`
- `(:Owner)-[:MEMBER_OF]->(:Team)` — via `front_matter.team`
- `(:Document)-[:REFERENCES]->(:Document)` — via links internos (se destino existe)
- `(:Document)-[:USES_TERM]->(:GlossaryTerm)` — via termos detectados (se existem)
- `(:Document)-[:RELATES_TO_TASK]->(:Task)` — via `front_matter.task_id`
- `(:Document)-[:SUPERSEDES]->(:Document)` — via `front_matter.supersedes`
- `(:Document)-[:VERSION_OF]->(:DocumentFamily)` — para documentos com versionamento

Nós inexistentes (System, Module, Owner, Team) são criados automaticamente com propriedades básicas via MERGE (só cria se não existir).

**Remoção de órfãos**: para documentos DELETED, remove chunks (via `PART_OF`), relações e nó Document. Sem limpeza, a Base Vetorial acumula "conhecimento fantasma" — chunks de documentos que não existem mais no repositório, poluindo resultados de busca.

**Transacionalidade**: toda a etapa roda dentro de uma transação. Se qualquer operação falha, rollback completo.

**Transacionalidade em releases grandes (>1000 documentos)**: batching transacional em lotes de 100 documentos. Cada lote é uma transação independente. Checkpoint após cada lote bem-sucedido. Se o pipeline crashar, retoma do último checkpoint. Release só marcada completa quando todos os lotes sucederem. Tamanho do lote configurável.

**Saída**: Base Vetorial atualizada com nós, chunks, relações e limpeza de órfãos. Contadores de operações (criados, atualizados, deletados).

### Etapa 6 — Indexação

**Objetivo**: Criar e manter índices para buscas eficientes.

1. **Vector index** no campo `Chunk.embedding`: índice vetorial HNSW para busca por similaridade coseno. Sem índice, busca seria O(n); com HNSW, é O(log n).

2. **Full-text index** no campo `Chunk.content`: busca por palavras-chave com suporte a português (stemming, stopwords). Complementa busca vetorial para termos exatos (códigos, siglas, nomes próprios). Ver [[ADR-007]] para busca híbrida.

3. **Índices compostos** para filtros frequentes: `Chunk.system`, `Chunk.module`, `Chunk.confidentiality`, `Chunk.doc_type`, `Chunk.domain`, `Document.status`. Filtros pré-retrieval precisam ser rápidos.

4. **Constraints de unicidade**: `Document.document_id` e `Chunk.chunk_id` (chaves primárias).

5. **Índices auxiliares**: `Document.file_path`, `Document.release_version`, `Document.updated_at` para queries administrativas e de auditoria.

**Saída**: todos os índices criados/verificados. Índices existentes não são recriados (operação no-op, CREATE IF NOT EXISTS).

### Etapa 7 — Observabilidade

**Objetivo**: Registrar métricas, logs e verificações de consistência para cada execução.

1. **Log de execução**: `pipeline_run_id`, `release_version`, timestamps de início e fim, duração total, trigger (webhook, manual, retry), status final (`success`, `partial_failure`, `failure`)

2. **Contadores por etapa**:
   - Descoberta: NEW / UPDATED / UNCHANGED / DELETED
   - Parse: validados / rejeitados
   - Chunking: total de chunks, média por documento
   - Embeddings: vetores gerados, batches ok / falhados
   - Persistência: nós criados / atualizados / deletados
   - Indexação: índices criados vs. existentes

3. **Métricas de performance**: tempo por etapa, latência média de embedding, latência de write na Base Vetorial, throughput (chunks/segundo), tamanho do índice

4. **Rastreamento de erros**: documentos falhados por etapa, motivo do erro, stack trace, classificação (transiente vs. permanente)

5. **Verificação de consistência** pós-execução: todo documento no manifesto tem nó Document correspondente, todo Document tem >= 1 chunk, todo chunk tem embedding, nenhum chunk órfão (sem Document pai), todos os chunks usam o mesmo modelo de embedding

6. **Métricas de saúde**: total de documentos/chunks/relações na Base Vetorial, tamanho do índice vetorial, data/hora da última execução, cobertura (% de documentos no repo com correspondente na Base Vetorial)

7. **Métricas de qualidade de retrieval** (sanity check pós-ingestão): golden set de 50-100 perguntas curadas, busca vetorial top-10, Recall@10 médio, threshold >= 70%. Se cai abaixo: alerta para o time (não bloqueia ingestão). Tendência entre releases consecutivas para detectar degradação. Ver [[ADR-007]] para métricas completas.

**Saída**: registro completo em tabela de auditoria, métricas publicadas para dashboard, Recall@10 registrado para tendência histórica.

## Idempotência

Um pipeline é **idempotente** quando executar a função `f(x)` duas vezes produz o mesmo resultado que executar uma vez: `f(f(x)) = f(x)`.

No contexto deste pipeline: se os documentos não mudaram desde a última execução, re-executar deve resultar em **zero alterações** na Base Vetorial. Nenhum nó é criado, atualizado ou deletado. Nenhuma relação é modificada. Nenhum embedding é recalculado.

### Como cada etapa garante idempotência

**Etapa 1 (Descoberta) — hash SHA-256**: comparação de hash classifica documentos inalterados como UNCHANGED, completamente ignorados nas etapas 2-6. Este é o **mecanismo central** de idempotência.

**Etapa 5 (Persistência) — upsert (MERGE no Cypher)**: se um documento NEW for re-processado por qualquer razão, o upsert atualiza com os mesmos valores — resultado idêntico. Aplica-se também a nós auxiliares (System, Module, Owner, Team).

**Etapa 6 (Indexação) — CREATE IF NOT EXISTS**: índices existentes não são recriados. Nenhum erro é gerado. O índice existente permanece intacto.

### Fluxo completo de idempotência

- **Execução 1**: classifica documentos como NEW, processa tudo (etapas 1-7).
- **Execução 2 (mesmos documentos, sem mudanças)**: calcula hash -> idêntico ao armazenado -> UNCHANGED para TODOS. Etapas 2-6 NÃO EXECUTADAS. Base Vetorial idêntica.

### Por que idempotência é crítica

- **Webhooks duplicados**: plataformas Git podem enviar o mesmo webhook mais de uma vez. Com idempotência, segundo disparo classifica tudo como UNCHANGED. Seguro.
- **Cron overlap**: execuções simultâneas sobre os mesmos dados resultam em no-op na segunda (lock exclusivo impede simultaneidade, mas idempotência garante segurança mesmo se lock falhar).
- **Retries seguros**: documentos já processados são classificados como UNCHANGED e pulados.
- **Testabilidade**: rodar 2 vezes e comparar diff da Base Vetorial (deve ser vazio). Automatizável em CI/CD.

### Propriedades derivadas

- **Reprodutibilidade**: mesma entrada = mesma saída
- **Segurança de retry**: qualquer etapa pode ser re-executada sem risco
- **Debugging simplificado**: re-executar pipeline com release correta restaura estado esperado
- **Rollback previsível**: re-executar com release anterior restaura estado correspondente

## Re-indexação Blue/Green

Quando o modelo de embedding muda, todos os chunks precisam ser re-embedded. Não se pode sobrescrever vetores diretamente porque durante a re-embedding o sistema ficaria com vetores misturados, falha no meio deixaria estado corrompido e não haveria rollback.

**Conceito**: "Blue" = índice atual (em produção), "Green" = índice novo (sendo preparado). Inspirado no deploy Blue/Green de infraestrutura.

**Solução em 5 Passos**:

1. **Criar novo índice** ("Green" / "v2") com dimensões do novo modelo. Índice "v1" continua ativo. Zero downtime. Registrar metadados: nome do índice, modelo associado, dimensões, status "building".

2. **Re-embed todos os chunks**: gerar novos embeddings em campo temporário (`embedding_v2`). Processamento em batch de 100 chunks com retry. Campo `embedding` original (v1) NÃO é alterado. Ambos coexistem. Processo pode levar horas sem impactar serviço.

3. **Validação de qualidade**: executar golden set no v1 e v2, comparar Recall@10. Se novo modelo é pior: abortar, deletar v2, manter v1, alertar time. Verificar também: todos os chunks têm `embedding_v2`, dimensões consistentes, nenhum vetor anômalo (NaN, infinito, zeros).

4. **Switch atômico**: mover `embedding_v2` para `embedding`, atualizar `embedding_model`, `embedding_model_version`, `embedding_dimensions`, `embedded_at`. Dropar índice v1, reconfigurar v2 como principal. Zero downtime.

5. **Cleanup**: manter v1 por 24-48h para rollback rápido. Monitorar Recall@10, latência e feedback em produção. Se problemas: rollback restaurando embedding original. Após 48h sem problemas: deletar v1 e campos temporários.

**Requisitos de espaço**: aproximadamente o DOBRO do armazenamento normal durante o processo (dois campos de embedding e dois índices simultâneos).

**Frequência esperada**: poucas vezes por ano. Operação de manutenção crítica, planejada e monitorada.

## Trigger

O pipeline é disparado **exclusivamente** por eventos de release no repositório knowledge-base.

**Fluxo**: mantenedor cria release tag -> webhook para serviço de ingestão -> handler envia `POST /admin/ingest` -> pipeline lê manifesto e inicia 7 etapas.

```
[Mantenedor]
    |
    | cria release tag v1.3.0
    v
[Plataforma Git (GitHub/GitLab)]
    |
    | webhook POST
    v
[Serviço de Ingestão - Handler]
    |
    | POST /admin/ingest {version: "1.3.0"}
    v
[Pipeline 7 Etapas]
    |
    | lê releases/v1.3/manifest.json
    v
[Execução: Descoberta -> Parse -> ... -> Observabilidade]
```

**Quem gera o manifest.json**: gerado automaticamente pelo pipeline de promoção (Fase 3, [[ADR-001]]) no momento da criação da release tag. Não é editado manualmente. Assinado pela service account do pipeline.

Conteúdo do manifesto para cada `.md`:

- `path`: caminho relativo no repositório
- `document_id`: identificador único
- `action`: classificação (new/updated/deleted/unchanged)
- `hash SHA-256`: verificação de integridade
- `doc_type`: tipo do documento
- `last_modified`: data da última modificação

Estrutura do manifesto:

```json
{
  "version": "1.3.0",
  "created_at": "2026-03-21T10:00:00Z",
  "created_by": "pipeline-service-account",
  "documents": [
    {"path": "docs/financeiro/modulo-cobranca.md", "document_id": "DOC-000123", "action": "updated"},
    {"path": "docs/financeiro/modulo-pagamentos.md", "document_id": "DOC-000124", "action": "new"},
    {"path": "docs/rh/politica-ferias.md", "document_id": "DOC-000089", "action": "deleted"}
  ]
}
```

**Por que trigger por release e não por commit**:

1. Nem todo commit é "pronto" — commits intermediários podem conter documentos incompletos
2. Releases representam conjuntos aprovados (pós-PR review por PO + Arquiteto)
3. A release tag permite versionar o estado completo da Base Vetorial (`release_version` em cada Document)
4. Facilita rollback — re-executar pipeline com release anterior restaura o estado

**Armazenamento da release_version**: registrado em cada nó Document na Etapa 5 (Persistência), junto com `file_hash`, `file_path` e `git_commit`.

## Concorrência de Releases

Se uma nova release é criada enquanto o pipeline da anterior ainda roda:

**REGRA ABSOLUTA**: NUNCA rodar dois pipelines simultaneamente contra a mesma Base Vetorial (risco de corrupção, deadlocks, verificação de consistência inválida, idempotência comprometida, rollback impossível).

**Mecanismo de lock exclusivo**:

1. Pipeline adquire lock antes da Etapa 1, registrando `pipeline_run_id`, `release_version`, `started_at`, PID
2. **Se lock existe**: nova release é enfileirada (FIFO). Handler retorna HTTP 202 (Accepted).
3. Ao terminar execução corrente, pipeline processa próxima da fila automaticamente.
4. **Cleanup do lock**: liberado automaticamente ao terminar (success, partial_failure ou failure). Timeout de 4h se processo crashar (acomoda releases grandes >1000 documentos).
5. **Ordem**: FIFO cronológico.

```
Release v1.3.0 chega -> Lock livre -> Adquire lock -> Executa pipeline
Release v1.4.0 chega -> Lock ocupado -> Enfileira -> HTTP 202
Release v1.5.0 chega -> Lock ocupado -> Enfileira -> HTTP 202

v1.3.0 termina -> Libera lock -> Processa v1.4.0 da fila
v1.4.0 termina -> Libera lock -> Processa v1.5.0 da fila
v1.5.0 termina -> Libera lock -> Fila vazia -> Aguarda
```

**Justificativas detalhadas para execução sequencial**:

- Corrupção de dados: upserts concorrentes no mesmo nó são não-determinísticos
- Deadlocks no Neo4j: transações concorrentes competindo pelos mesmos recursos
- Verificação de consistência inválida: Etapa 7 mediria estado intermediário
- Simplicidade: modelo sequencial é mais simples de implementar, testar e debugar

## Alternativas Descartadas

### Pipeline em streaming (processamento contínuo)

Cada commit dispara processamento imediato. Rejeitada porque commits intermediários geram ingestões parciais, impossibilita rollback coerente e gera excesso de re-processamento.

### Pipeline batch diário (cron)

Cron roda 1x por dia. Rejeitada porque re-processa documentos inalterados, latência alta e sem vínculo com release.

### Chunking por tamanho fixo (sem headings)

Dividir texto em blocos de exatamente 500 tokens. Rejeitada porque ignora estrutura semântica, corta frases no meio e gera chunks com temas misturados.

### Embeddings sob demanda (lazy)

Gerar embedding apenas quando chunk é buscado pela primeira vez. Rejeitada porque primeira busca seria lenta, HNSW precisa de vetores pré-computados e complexidade de cache invalidation.

### Delete + Recreate (em vez de Upsert)

A cada execução, deletar tudo e recriar. Rejeitada porque perde relações externas, downtime durante reprocessamento e sem idempotência.

## Consequências

### Positivas

- Pipeline previsível e reprodutível (mesma entrada = mesma saída)
- Idempotência elimina riscos de re-execução
- Observabilidade completa de cada execução
- Re-indexação sem downtime (Blue/Green)
- Suporte a múltiplos modelos de embedding (Track A e B da [[ADR-002]])
- Limpeza automática de órfãos mantendo Base Vetorial limpa
- Trigger por release garante que só conhecimento aprovado é indexado
- Chunking adaptativo por tipo de documento maximiza qualidade de retrieval
- Herança de metadados nos chunks viabiliza filtros pré-retrieval

### Negativas / Trade-offs

- Complexidade de implementação (7 etapas com lógica própria)
- Re-indexação Blue/Green requer espaço temporário (2 índices simultâneos)
- Validação bloqueante pode rejeitar documentos com problemas menores (trade-off consciente)
- Processamento em batch pode ter latência de horas para releases grandes (>1000 documentos)
- Chunking por tipo de documento requer manutenção das estratégias conforme novos `doc_types` são adicionados

### Riscos

- Hash collision (SHA-256): probabilidade negligível (2^128)
- Embedding model deprecated: fornecedor descontinua modelo sem aviso (mitigação: Track B como fallback)
- Manifesto desatualizado: release criada sem atualizar `manifest.json` (mitigação: validação automática no PR)
- Base Vetorial indisponível durante persistência (mitigação: retry com backoff, alertas)

## Implementação

| Fase | Foco | Entregas |
|---|---|---|
| 1 (MVP) | Funcionalidade básica | Etapas 1-5, chunking por headings, um modelo de embedding, índices básicos, observabilidade mínima |
| 2 (Metadados) | Governança | Validação de front matter ([[ADR-005]]), herança completa de metadados, índices compostos, full-text index |
| 3 (Knowledge Graph) | Relações | Criação de relações (System, Module, Owner, etc.), detecção de referências, DocumentFamily |
| 4 (GraphRAG Corporativo) | Maturidade | Chunking adaptativo por `doc_type`, Blue/Green, observabilidade completa, verificação de consistência |

## Referências

### ADRs relacionadas

- [[ADR-001]] — Pipeline de Geração de Conhecimento em 4 Fases (este ADR detalha a Fase 4)
- [[ADR-002]] — Soberania de Dados (define Track A/B para modelo de embedding)
- [[ADR-003]] — Modelo de Dados da Base Vetorial (define nós, relações e propriedades que este pipeline popula)
- [[ADR-005]] — Front Matter como Contrato de Metadados (define schema que a Etapa 2 valida)
- [[ADR-007]] — Retrieval Híbrido e Agentes (consome a Base Vetorial populada por este pipeline)
- [[ADR-009]] — Seleção de Modelos de Embedding (define BGE-M3, limites de tokens e configuração operacional)

### Blueprints relacionados

- B03 — Camada Ouro: pipeline de ingestão original (substituído por este ADR)
- B04 — Metadados e Governança: front matter e filtros
- B05 — Knowledge Graph: modelo de grafo

### Referências técnicas

- HNSW (Hierarchical Navigable Small World) — algoritmo de índice vetorial
- Reciprocal Rank Fusion (RRF) — ver [[ADR-007]]
- [OpenAI Embeddings API](https://platform.openai.com/docs/guides/embeddings)
- [BGE-M3](https://huggingface.co/BAAI/bge-m3)
- [SHA-256](https://en.wikipedia.org/wiki/SHA-2)

<!-- conversion_quality: 95 -->
