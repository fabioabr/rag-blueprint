---
id: BETA-006
title: "Pipeline de Ingestao: Da Fonte a Base Vetorial"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-E01_pipeline_ingestao_detalhado.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-E02_trigger_ingestao.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-E03_gestao_concorrencia.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-E04_garantias_idempotencia.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-E06_reindexacao_blue_green.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags: [pipeline ingestao, base vetorial, chunking semantico, embeddings, indexacao, idempotencia, observabilidade, descoberta documentos, parse front matter, persistencia grafo, upsert neo4j, hash sha-256, release tag, manifest json, webhook, trigger release, concorrencia releases, lock exclusivo, fila fifo, re-indexacao blue green, vector index hnsw, full-text index, indices compostos, constraints unicidade, heranca metadados, breadcrumb headings, chunking por tipo, faixa tokens, batch processing, backoff exponencial, transacionalidade, checkpoint, limpeza orfaos, recall golden set, metricas performance, log execucao, contadores etapa, verificacao consistencia, track cloud, track on-premises, bge-m3, text-embedding-3-small, embedding model version, document classification, chunks parciais, rollback release, versionamento base vetorial, doc_type estrategia, rate limiting]
aliases:
  - "ADR-006"
  - "Pipeline de Ingestao"
  - "Pipeline 7 Etapas"
  - "Ingestao na Base Vetorial"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

# ADR-006 — Pipeline de Ingestao: Da Fonte a Base Vetorial

## Contexto

Esta ADR define o pipeline completo que transforma documentos `.md` finais (produzidos na Fase 3 da [[BETA-001]]) em conhecimento pesquisavel dentro da Base Vetorial. A Fase 4 da [[BETA-001]] mencionava "ingestao no banco vetorial" de forma resumida — este documento detalha **cada etapa** desse processo.

A Base Vetorial nao e um simples banco de dados onde se "joga" arquivos. Ela e uma estrutura sofisticada que combina vetores de embedding, nos de grafo, relacoes semanticas e metadados estruturados. Para que essa estrutura funcione corretamente, o pipeline de ingestao precisa ser rigoroso, previsivel e observavel.

### Premissas fundamentais

1. **Idempotencia** — Re-executar o pipeline sobre o mesmo conjunto de documentos DEVE produzir zero alteracoes. Critico porque webhooks podem disparar duplicados, cron jobs podem sobrepor execucoes e falhas parciais exigem re-tentativa segura.

2. **Re-indexacao** — Quando o modelo de embedding muda (ex: de `text-embedding-3-small` para `text-embedding-3-large`), o pipeline precisa re-gerar todos os vetores sem downtime. Vetores de modelos diferentes vivem em espacos dimensionais incompativeis.

3. **Limpeza de orfaos** — Se um documento e removido do repositorio knowledge-base, seus chunks na Base Vetorial devem ser eliminados. Chunks orfaos poluem resultados de busca.

4. **Trigger por release** — O pipeline nao roda continuamente. E disparado por tags de release no repositorio knowledge-base (conforme [[BETA-001]], Fase 3). Apenas documentos aprovados e versionados entram na Base Vetorial.

5. **Compatibilidade com [[BETA-003]]** — O pipeline deve popular os nos e relacoes definidos no modelo de dados (Document, Chunk, System, Module, Owner, Team, etc.) respeitando constraints de unicidade e tipos de propriedades.

### Diagrama do fluxo macro

```
[Repo knowledge-base]     [Pipeline de Ingestao - 7 Etapas]     [Base Vetorial]
      |                                                                |
      |   release tag                                                  |
      +----------> [1.Descoberta] --> [2.Parse] --> [3.Chunking]       |
                       |                |              |               |
                       v                v              v               |
                   [4.Embeddings] --> [5.Persistencia] --> [6.Indexacao]
                                          |                    |
                                          v                    v
                                    [7.Observabilidade] --> [Metricas]
```

## Decisao — Pipeline de 7 Etapas

O pipeline de ingestao e composto por 7 etapas sequenciais. Cada etapa tem responsabilidade unica, entrada e saida bem definidas, e pode ser monitorada independentemente.

Por que 7 etapas e nao menos: separar em 7 etapas permite isolar falhas, medir gargalos, evoluir independentemente e testar isoladamente. Unificar etapas criaria acoplamento desnecessario e dificultaria debug em producao.

<!-- LOCKED:START autor=fabio data=2026-03-23 -->

### Etapa 1 — Descoberta

**Objetivo**: Identificar quais documentos `.md` precisam ser processados nesta execucao do pipeline.

Procedimento:

1. Recebe a versao da release (ex: `v1.3.0`) via parametro de execucao.
2. Le o manifesto da release (`releases/v1.3/manifest.json`) que lista todos os `.md` incluidos.
3. Para cada arquivo `.md` no manifesto:
   - Calcula o hash SHA-256 do conteudo
   - Captura metadados do Git: `path`, `branch`, `commit`, `last_modified`
   - Consulta a Base Vetorial para verificar se ja existe um no Document com o mesmo `document_id`
   - Compara o hash armazenado com o hash calculado
4. Classifica cada documento em uma de 4 categorias:
   - **NEW**: documento nao existe na Base Vetorial. Acao: processar todas as etapas seguintes.
   - **UPDATED**: documento existe mas o hash mudou. Acao: re-processar todas as etapas, substituindo chunks antigos.
   - **UNCHANGED**: documento existe e o hash e identico. Acao: pular completamente. Este e o mecanismo central de idempotencia.
   - **DELETED**: documento existe na Base Vetorial mas nao esta no manifesto. Acao: remover o no Document e todos os seus chunks.
5. Gera relatorio de descoberta com totais por categoria.

**Por que o hash e critico para idempotencia**: o hash SHA-256 e uma funcao deterministica. Se o pipeline roda 2 vezes sobre os mesmos documentos, na segunda execucao todos serao UNCHANGED. Resultado: zero processamento, zero alteracoes.

Alternativas descartadas: data de modificacao (git clone reseta timestamps), numero de versao no front matter (depende do autor), tamanho do arquivo (colisoes obvias).

**Saida**: lista de documentos com classificacao, hash, path e metadados Git. Apenas NEW e UPDATED seguem para a Etapa 2.

### Etapa 2 — Parse

**Objetivo**: Extrair conteudo estruturado de cada documento `.md`, separando metadados (front matter) de conteudo (corpo).

Procedimento para cada documento classificado como NEW ou UPDATED:

1. **Extracao do front matter**: le o bloco YAML entre `---`, converte em objeto estruturado com campos conforme [[BETA-005]]
2. **Validacao contra o schema** ([[BETA-005]]): verifica presenca de campos obrigatorios, tipos de dados, consistencia. Se qualquer validacao falha, o documento e **rejeitado**
3. **Extracao da hierarquia de headings**: identifica `# H1`, `## H2`, `### H3`, constroi arvore hierarquica, cada heading recebe um breadcrumb path (ex: "Modulo de Cobranca > Fluxo de Boleto > Regras de Validacao")
4. **Extracao de links internos**: detecta wikilinks `[[DOC-000456|titulo]]` e links Markdown `[texto](caminho)`. Registra origem, destino e texto para relacoes REFERENCES
5. **Identificacao de blocos de codigo**: detecta blocos delimitados por triple backticks, registra linguagem. Recebem tratamento especial no chunking (nunca divididos)
6. **Deteccao de referencias a entidades**: sistemas, modulos, termos de glossario. Alimentam criacao de relacoes na Persistencia

A validacao e **bloqueante**: um documento sem front matter valido nao pode ser indexado corretamente. Em producao, o documento rejeitado e registrado no log, gera alerta, nao bloqueia demais documentos e pode ser corrigido na proxima release.

**Saida**: para cada documento, objeto com `front_matter`, `headings`, `internal_links`, `code_blocks`, `entity_references`, `raw_content` e `validation_status`.

### Etapa 3 — Chunking

**Objetivo**: Dividir o conteudo em fragmentos semanticos (chunks) individualmente indexaveis e pesquisaveis.

Por que nao indexar o documento inteiro: modelos de embedding geram vetores mais precisos para textos curtos e focados. Um documento longo sobre multiplos temas gera um vetor "medio" que nao representa bem nenhum tema individualmente. Chunks menores permitem vetores mais precisos, contexto mais relevante para o LLM, melhor ranking e rastreabilidade precisa.

**Estrategia primaria — divisao por headings**: cada secao delimitada por um heading forma um candidato a chunk. Se excede 800 tokens, subdivide em paragrafos. Se tem menos de 300 tokens, mescla com a secao seguinte.

**Faixa de tokens: 300 a 800 tokens por chunk**:

- **300 minimo**: chunks muito curtos nao carregam contexto suficiente para embeddings significativos
- **800 maximo**: chunks muito longos diluem o foco semantico
- A faixa 300-800 acomoda tanto glossarios (termos curtos) quanto documentos arquiteturais (secoes densas)

**Interacao com limite do modelo de embedding** (ver [[BETA-009]]): a faixa 300-800 foi definida para coerencia semantica, nao por limitacao do modelo. O BGE-M3 suporta ate 8192 tokens. Porem, na configuracao operacional recomendada (GTX 1070, 512 max_seq_length), o pipeline deve ajustar o limite superior para ~450 tokens. O pipeline DEVE validar: `(chunk_tokens + breadcrumb_tokens) <= max_seq_length`.

**Heranca de metadados**: cada chunk herda **todos** os metadados do documento pai (`document_id`, `doc_type`, `system`, `module`, `domain`, `owner`, `team`, `confidentiality`, `tags`, `valid_from`, `valid_until`). Critico porque o chunk e a unidade de busca e filtros pre-retrieval sao aplicados diretamente nos chunks.

**Breadcrumb (caminho de headings)**: cada chunk recebe `heading_path` (ex: "Modulo de Cobranca > Boleto > Regras de Validacao"), incluido no texto para dar contexto ao embedding.

**Estrategia por tipo de documento** (`doc_type`):

- **architecture-doc**: chunking por heading, faixa padrao, diagramas ASCII e tabelas preservados inteiros
- **adr**: chunks menores e mais precisos, cada secao estrutural (Contexto, Decisao, Alternativas, Consequencias) gera exatamente 1 chunk
- **runbook**: chunk por procedimento/passo operacional, cada passo numerado gera chunk independente
- **glossary**: chunk quase atomico, cada termo = 1 chunk
- **task-doc**: chunks por secao logica (Contexto, Escopo, Decisoes tecnicas, Criterios de aceite)

**Regras especiais**:

- Blocos de codigo nunca divididos no meio
- Tabelas Markdown nunca divididas no meio (se muito longas, divididas em grupos de linhas mantendo cabecalho)
- Listas longas divididas em grupos tematicos

**Chunking hierarquico — decisao adiada**: nao implementar agora (aumenta armazenamento, requer resumos por LLM, breadcrumb ja fornece contexto suficiente para MVP). Reconsiderar quando Recall@10 cair abaixo de 70% ou volume ultrapassar 10.000 documentos.

**Saida**: lista de chunks por documento, cada um com `chunk_id` (`{document_id}_chunk_{N}`), `content`, `heading_path`, `token_count`, `chunk_index` e metadados herdados.

### Etapa 4 — Embeddings

**Objetivo**: Gerar vetor de embedding para cada chunk, transformando texto em representacao numerica pesquisavel por similaridade.

Procedimento:

1. Para cada chunk, prepara texto de entrada: `"[heading_path]\n\n[content]"`
2. Envia para o modelo de embedding em **lotes** (batch de 100 chunks)
3. Recebe vetor de embedding (array de floats)
4. Armazena no campo `chunk.embedding`

**Escolha do modelo de embedding** (conforme [[BETA-002]]):

| Track | Modelo | Dimensoes | Custo | Latencia |
|---|---|---|---|---|
| A — Cloud (OpenAI) | `text-embedding-3-small` | 1536 | ~$0.02/1M tokens | ~100ms/batch |
| B — On-premises | BGE-M3 (BAAI) | 1024 | zero (local) | ~200-500ms/batch em GPU |

O pipeline suporta **ambos os tracks** sem alteracao de codigo (apenas configuracao).

**Registro de modelo e versao**: cada chunk armazena `embedding_model`, `embedding_model_version`, `embedding_dimensions` e `embedded_at`. Critico porque vetores de modelos diferentes nao sao compativeis no mesmo indice.

**Processamento em lotes**: batches de 100 chunks por eficiencia, rate limiting e tolerancia a falha. Tamanho configuravel.

**Tratamento de erros**: retry com backoff exponencial (1s, 2s, 4s, 8s, max 60s). Apos 3 retries, batch marcado como FAILED. Chunks sem embedding nao sao persistidos.

**Chunks parcialmente falhados**: chunks com sucesso sao persistidos normalmente. Chunks falhados vao para fila de retry (max 3 tentativas, 30s/60s/120s). Documento so e marcado como ingerido com sucesso quando todos os chunks tem embedding. Documentos "incomplete" sao reprocessados do zero na proxima execucao. Se permanece "incomplete" por 3+ execucoes: alerta critico.

**Saida**: chunks enriquecidos com vetor de embedding e metadados do modelo.

### Etapa 5 — Persistencia

**Objetivo**: Gravar (ou atualizar) os dados na Base Vetorial, criando nos, relacoes e removendo dados obsoletos.

**Upsert de Document**:

- **NEW**: cria novo no `:Document` com propriedades do front matter, registra `release_version`, `file_hash`, `file_path`, `git_commit`
- **UPDATED**: atualiza propriedades do no existente, `document_id` imutavel

Padrao **upsert** (e nao delete + create) preserva relacoes externas enriquecidas manualmente ou por outros pipelines.

**Gerenciamento de chunks**:

- **UPDATED**: deleta todos os chunks antigos (via `PART_OF`), cria novos, cria relacoes `(:Chunk)-[:PART_OF]->(:Document)`
- **NEW**: cria chunks e relacoes

**Criacao/atualizacao de relacoes** (baseado em front matter e deteccoes do Parse):

- `(:Document)-[:BELONGS_TO]->(:Module)` — via `front_matter.module`
- `(:Module)-[:BELONGS_TO]->(:System)` — via `front_matter.system`
- `(:Document)-[:OWNED_BY]->(:Owner)` — via `front_matter.owner`
- `(:Owner)-[:MEMBER_OF]->(:Team)` — via `front_matter.team`
- `(:Document)-[:REFERENCES]->(:Document)` — via links internos (se destino existe)
- `(:Document)-[:USES_TERM]->(:GlossaryTerm)` — via termos detectados (se existem)
- `(:Document)-[:RELATES_TO_TASK]->(:Task)` — via `front_matter.task_id`
- `(:Document)-[:SUPERSEDES]->(:Document)` — via `front_matter.supersedes`
- `(:Document)-[:VERSION_OF]->(:DocumentFamily)` — para documentos com versionamento

Nos inexistentes (System, Module, Owner, Team) sao criados automaticamente com propriedades basicas via MERGE (so cria se nao existir).

**Remocao de orfaos**: para documentos DELETED, remove chunks (via `PART_OF`), relacoes e no Document. Sem limpeza, a Base Vetorial acumula "conhecimento fantasma" — chunks de documentos que nao existem mais no repositorio, poluindo resultados de busca.

**Transacionalidade**: toda a etapa roda dentro de uma transacao. Se qualquer operacao falha, rollback completo.

**Transacionalidade em releases grandes (>1000 documentos)**: batching transacional em lotes de 100 documentos. Cada lote e uma transacao independente. Checkpoint apos cada lote bem-sucedido. Se o pipeline crashar, retoma do ultimo checkpoint. Release so marcada completa quando todos os lotes sucederem. Tamanho do lote configuravel.

**Saida**: Base Vetorial atualizada com nos, chunks, relacoes e limpeza de orfaos. Contadores de operacoes (criados, atualizados, deletados).

### Etapa 6 — Indexacao

**Objetivo**: Criar e manter indices para buscas eficientes.

1. **Vector index** no campo `Chunk.embedding`: indice vetorial HNSW para busca por similaridade coseno. Sem indice, busca seria O(n); com HNSW, e O(log n).

2. **Full-text index** no campo `Chunk.content`: busca por palavras-chave com suporte a portugues (stemming, stopwords). Complementa busca vetorial para termos exatos (codigos, siglas, nomes proprios). Ver [[BETA-007]] para busca hibrida.

3. **Indices compostos** para filtros frequentes: `Chunk.system`, `Chunk.module`, `Chunk.confidentiality`, `Chunk.doc_type`, `Chunk.domain`, `Document.status`. Filtros pre-retrieval precisam ser rapidos.

4. **Constraints de unicidade**: `Document.document_id` e `Chunk.chunk_id` (chaves primarias).

5. **Indices auxiliares**: `Document.file_path`, `Document.release_version`, `Document.updated_at` para queries administrativas e de auditoria.

**Saida**: todos os indices criados/verificados. Indices existentes nao sao recriados (operacao no-op, CREATE IF NOT EXISTS).

### Etapa 7 — Observabilidade

**Objetivo**: Registrar metricas, logs e verificacoes de consistencia para cada execucao.

1. **Log de execucao**: `pipeline_run_id`, `release_version`, timestamps de inicio e fim, duracao total, trigger (webhook, manual, retry), status final (`success`, `partial_failure`, `failure`)

2. **Contadores por etapa**:
   - Descoberta: NEW / UPDATED / UNCHANGED / DELETED
   - Parse: validados / rejeitados
   - Chunking: total de chunks, media por documento
   - Embeddings: vetores gerados, batches ok / falhados
   - Persistencia: nos criados / atualizados / deletados
   - Indexacao: indices criados vs. existentes

3. **Metricas de performance**: tempo por etapa, latencia media de embedding, latencia de write na Base Vetorial, throughput (chunks/segundo), tamanho do indice

4. **Rastreamento de erros**: documentos falhados por etapa, motivo do erro, stack trace, classificacao (transiente vs. permanente)

5. **Verificacao de consistencia** pos-execucao: todo documento no manifesto tem no Document correspondente, todo Document tem >= 1 chunk, todo chunk tem embedding, nenhum chunk orfao (sem Document pai), todos os chunks usam o mesmo modelo de embedding

6. **Metricas de saude**: total de documentos/chunks/relacoes na Base Vetorial, tamanho do indice vetorial, data/hora da ultima execucao, cobertura (% de documentos no repo com correspondente na Base Vetorial)

7. **Metricas de qualidade de retrieval** (sanity check pos-ingestao): golden set de 50-100 perguntas curadas, busca vetorial top-10, Recall@10 medio, threshold >= 70%. Se cai abaixo: alerta para o time (nao bloqueia ingestao). Tendencia entre releases consecutivas para detectar degradacao. Ver [[BETA-007]] para metricas completas.

**Saida**: registro completo em tabela de auditoria, metricas publicadas para dashboard, Recall@10 registrado para tendencia historica.

<!-- LOCKED:END -->

## Idempotencia

Um pipeline e **idempotente** quando executar a funcao `f(x)` duas vezes produz o mesmo resultado que executar uma vez: `f(f(x)) = f(x)`.

No contexto deste pipeline: se os documentos nao mudaram desde a ultima execucao, re-executar deve resultar em **zero alteracoes** na Base Vetorial. Nenhum no e criado, atualizado ou deletado. Nenhuma relacao e modificada. Nenhum embedding e recalculado.

### Como cada etapa garante idempotencia

**Etapa 1 (Descoberta) — hash SHA-256**: comparacao de hash classifica documentos inalterados como UNCHANGED, completamente ignorados nas etapas 2-6. Este e o **mecanismo central** de idempotencia.

**Etapa 5 (Persistencia) — upsert (MERGE no Cypher)**: se um documento NEW for re-processado por qualquer razao, o upsert atualiza com os mesmos valores — resultado identico. Aplica-se tambem a nos auxiliares (System, Module, Owner, Team).

**Etapa 6 (Indexacao) — CREATE IF NOT EXISTS**: indices existentes nao sao recriados. Nenhum erro e gerado. O indice existente permanece intacto.

### Fluxo completo de idempotencia

- **Execucao 1**: classifica documentos como NEW, processa tudo (etapas 1-7).
- **Execucao 2 (mesmos documentos, sem mudancas)**: calcula hash -> identico ao armazenado -> UNCHANGED para TODOS. Etapas 2-6 NAO EXECUTADAS. Base Vetorial identica.

### Por que idempotencia e critica

- **Webhooks duplicados**: plataformas Git podem enviar o mesmo webhook mais de uma vez. Com idempotencia, segundo disparo classifica tudo como UNCHANGED. Seguro.
- **Cron overlap**: execucoes simultaneas sobre os mesmos dados resultam em no-op na segunda (lock exclusivo impede simultaneidade, mas idempotencia garante seguranca mesmo se lock falhar).
- **Retries seguros**: documentos ja processados sao classificados como UNCHANGED e pulados.
- **Testabilidade**: rodar 2 vezes e comparar diff da Base Vetorial (deve ser vazio). Automatizavel em CI/CD.

### Propriedades derivadas

- **Reprodutibilidade**: mesma entrada = mesma saida
- **Seguranca de retry**: qualquer etapa pode ser re-executada sem risco
- **Debugging simplificado**: re-executar pipeline com release correta restaura estado esperado
- **Rollback previsivel**: re-executar com release anterior restaura estado correspondente

## Re-indexacao Blue/Green

Quando o modelo de embedding muda, todos os chunks precisam ser re-embedded. Nao se pode sobrescrever vetores diretamente porque durante a re-embedding o sistema ficaria com vetores misturados, falha no meio deixaria estado corrompido e nao haveria rollback.

**Conceito**: "Blue" = indice atual (em producao), "Green" = indice novo (sendo preparado). Inspirado no deploy Blue/Green de infraestrutura.

**Solucao em 5 Passos**:

1. **Criar novo indice** ("Green" / "v2") com dimensoes do novo modelo. Indice "v1" continua ativo. Zero downtime. Registrar metadados: nome do indice, modelo associado, dimensoes, status "building".

2. **Re-embed todos os chunks**: gerar novos embeddings em campo temporario (`embedding_v2`). Processamento em batch de 100 chunks com retry. Campo `embedding` original (v1) NAO e alterado. Ambos coexistem. Processo pode levar horas sem impactar servico.

3. **Validacao de qualidade**: executar golden set no v1 e v2, comparar Recall@10. Se novo modelo e pior: abortar, deletar v2, manter v1, alertar time. Verificar tambem: todos os chunks tem `embedding_v2`, dimensoes consistentes, nenhum vetor anomalo (NaN, infinito, zeros).

4. **Switch atomico**: mover `embedding_v2` para `embedding`, atualizar `embedding_model`, `embedding_model_version`, `embedding_dimensions`, `embedded_at`. Dropar indice v1, reconfigurar v2 como principal. Zero downtime.

5. **Cleanup**: manter v1 por 24-48h para rollback rapido. Monitorar Recall@10, latencia e feedback em producao. Se problemas: rollback restaurando embedding original. Apos 48h sem problemas: deletar v1 e campos temporarios.

**Requisitos de espaco**: aproximadamente o DOBRO do armazenamento normal durante o processo (dois campos de embedding e dois indices simultaneos).

**Frequencia esperada**: poucas vezes por ano. Operacao de manutencao critica, planejada e monitorada.

## Trigger

O pipeline e disparado **exclusivamente** por eventos de release no repositorio knowledge-base.

**Fluxo**: mantenedor cria release tag -> webhook para servico de ingestao -> handler envia `POST /admin/ingest` -> pipeline le manifesto e inicia 7 etapas.

```
[Mantenedor]
    |
    | cria release tag v1.3.0
    v
[Plataforma Git (GitHub/GitLab)]
    |
    | webhook POST
    v
[Servico de Ingestao - Handler]
    |
    | POST /admin/ingest {version: "1.3.0"}
    v
[Pipeline 7 Etapas]
    |
    | le releases/v1.3/manifest.json
    v
[Execucao: Descoberta -> Parse -> ... -> Observabilidade]
```

**Quem gera o manifest.json**: gerado automaticamente pelo pipeline de promocao (Fase 3, [[BETA-001]]) no momento da criacao da release tag. Nao e editado manualmente. Assinado pela service account do pipeline.

Conteudo do manifesto para cada `.md`:

- `path`: caminho relativo no repositorio
- `document_id`: identificador unico
- `action`: classificacao (new/updated/deleted/unchanged)
- `hash SHA-256`: verificacao de integridade
- `doc_type`: tipo do documento
- `last_modified`: data da ultima modificacao

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

**Por que trigger por release e nao por commit**:

1. Nem todo commit e "pronto" — commits intermediarios podem conter documentos incompletos
2. Releases representam conjuntos aprovados (pos-PR review por PO + Arquiteto)
3. A release tag permite versionar o estado completo da Base Vetorial (`release_version` em cada Document)
4. Facilita rollback — re-executar pipeline com release anterior restaura o estado

**Armazenamento da release_version**: registrado em cada no Document na Etapa 5 (Persistencia), junto com `file_hash`, `file_path` e `git_commit`.

## Concorrencia de Releases

Se uma nova release e criada enquanto o pipeline da anterior ainda roda:

**REGRA ABSOLUTA**: NUNCA rodar dois pipelines simultaneamente contra a mesma Base Vetorial (risco de corrupcao, deadlocks, verificacao de consistencia invalida, idempotencia comprometida, rollback impossivel).

**Mecanismo de lock exclusivo**:

1. Pipeline adquire lock antes da Etapa 1, registrando `pipeline_run_id`, `release_version`, `started_at`, PID
2. **Se lock existe**: nova release e enfileirada (FIFO). Handler retorna HTTP 202 (Accepted).
3. Ao terminar execucao corrente, pipeline processa proxima da fila automaticamente.
4. **Cleanup do lock**: liberado automaticamente ao terminar (success, partial_failure ou failure). Timeout de 4h se processo crashar (acomoda releases grandes >1000 documentos).
5. **Ordem**: FIFO cronologico.

```
Release v1.3.0 chega -> Lock livre -> Adquire lock -> Executa pipeline
Release v1.4.0 chega -> Lock ocupado -> Enfileira -> HTTP 202
Release v1.5.0 chega -> Lock ocupado -> Enfileira -> HTTP 202

v1.3.0 termina -> Libera lock -> Processa v1.4.0 da fila
v1.4.0 termina -> Libera lock -> Processa v1.5.0 da fila
v1.5.0 termina -> Libera lock -> Fila vazia -> Aguarda
```

**Justificativas detalhadas para execucao sequencial**:

- Corrupcao de dados: upserts concorrentes no mesmo no sao nao-deterministicos
- Deadlocks no Neo4j: transacoes concorrentes competindo pelos mesmos recursos
- Verificacao de consistencia invalida: Etapa 7 mediria estado intermediario
- Simplicidade: modelo sequencial e mais simples de implementar, testar e debugar

## Alternativas Descartadas

### Pipeline em streaming (processamento continuo)

Cada commit dispara processamento imediato. Rejeitada porque commits intermediarios geram ingestoes parciais, impossibilita rollback coerente e gera excesso de re-processamento.

### Pipeline batch diario (cron)

Cron roda 1x por dia. Rejeitada porque re-processa documentos inalterados, latencia alta e sem vinculo com release.

### Chunking por tamanho fixo (sem headings)

Dividir texto em blocos de exatamente 500 tokens. Rejeitada porque ignora estrutura semantica, corta frases no meio e gera chunks com temas misturados.

### Embeddings sob demanda (lazy)

Gerar embedding apenas quando chunk e buscado pela primeira vez. Rejeitada porque primeira busca seria lenta, HNSW precisa de vetores pre-computados e complexidade de cache invalidation.

### Delete + Recreate (em vez de Upsert)

A cada execucao, deletar tudo e recriar. Rejeitada porque perde relacoes externas, downtime durante reprocessamento e sem idempotencia.

## Consequencias

### Positivas

- Pipeline previsivel e reprodutivel (mesma entrada = mesma saida)
- Idempotencia elimina riscos de re-execucao
- Observabilidade completa de cada execucao
- Re-indexacao sem downtime (Blue/Green)
- Suporte a multiplos modelos de embedding (Track A e B da [[BETA-002]])
- Limpeza automatica de orfaos mantendo Base Vetorial limpa
- Trigger por release garante que so conhecimento aprovado e indexado
- Chunking adaptativo por tipo de documento maximiza qualidade de retrieval
- Heranca de metadados nos chunks viabiliza filtros pre-retrieval

### Negativas / Trade-offs

- Complexidade de implementacao (7 etapas com logica propria)
- Re-indexacao Blue/Green requer espaco temporario (2 indices simultaneos)
- Validacao bloqueante pode rejeitar documentos com problemas menores (trade-off consciente)
- Processamento em batch pode ter latencia de horas para releases grandes (>1000 documentos)
- Chunking por tipo de documento requer manutencao das estrategias conforme novos `doc_types` sao adicionados

### Riscos

- Hash collision (SHA-256): probabilidade negligivel (2^128)
- Embedding model deprecated: fornecedor descontinua modelo sem aviso (mitigacao: Track B como fallback)
- Manifesto desatualizado: release criada sem atualizar `manifest.json` (mitigacao: validacao automatica no PR)
- Base Vetorial indisponivel durante persistencia (mitigacao: retry com backoff, alertas)

## Implementacao

| Fase | Foco | Entregas |
|---|---|---|
| 1 (MVP) | Funcionalidade basica | Etapas 1-5, chunking por headings, um modelo de embedding, indices basicos, observabilidade minima |
| 2 (Metadados) | Governanca | Validacao de front matter ([[BETA-005]]), heranca completa de metadados, indices compostos, full-text index |
| 3 (Knowledge Graph) | Relacoes | Criacao de relacoes (System, Module, Owner, etc.), deteccao de referencias, DocumentFamily |
| 4 (GraphRAG Corporativo) | Maturidade | Chunking adaptativo por `doc_type`, Blue/Green, observabilidade completa, verificacao de consistencia |

## Referencias

### ADRs relacionadas

- [[BETA-001]] — Pipeline de Geracao de Conhecimento em 4 Fases (este ADR detalha a Fase 4)
- [[BETA-002]] — Soberania de Dados (define Track A/B para modelo de embedding)
- [[BETA-003]] — Modelo de Dados da Base Vetorial (define nos, relacoes e propriedades que este pipeline popula)
- [[BETA-005]] — Front Matter como Contrato de Metadados (define schema que a Etapa 2 valida)
- [[BETA-007]] — Retrieval Hibrido e Agentes (consome a Base Vetorial populada por este pipeline)
- [[BETA-009]] — Selecao de Modelos de Embedding (define BGE-M3, limites de tokens e configuracao operacional)

### Blueprints relacionados

- B03 — Camada Ouro: pipeline de ingestao original (substituido por este ADR)
- B04 — Metadados e Governanca: front matter e filtros
- B05 — Knowledge Graph: modelo de grafo

### Referencias tecnicas

- HNSW (Hierarchical Navigable Small World) — algoritmo de indice vetorial
- Reciprocal Rank Fusion (RRF) — ver [[BETA-007]]
- [OpenAI Embeddings API](https://platform.openai.com/docs/guides/embeddings)
- [BGE-M3](https://huggingface.co/BAAI/bge-m3)
- [SHA-256](https://en.wikipedia.org/wiki/SHA-2)

<!-- conversion_quality: 95 -->
