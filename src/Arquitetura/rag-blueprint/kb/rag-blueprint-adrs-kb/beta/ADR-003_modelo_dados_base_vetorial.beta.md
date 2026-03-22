---
id: BETA-003
title: "Modelo de Dados da Base Vetorial"
domain: "arquitetura"
confidentiality: internal
sources:
  - type: "txt"
    origin: "Arquitetura/rag-blueprint/kb/rag-blueprint-adrs-kb/1 - draft/ADR-003_modelo_dados_base_vetorial.txt"
    captured_at: "2026-03-21"
tags: [modelo-dados, base-vetorial, graphrag, grafo-conhecimento, chunking, embeddings]
aliases: ["ADR-003", "Modelo de Grafo", "Schema da Base Vetorial"]
status: approved
last_enrichment: "2026-03-22"
last_human_edit: "2026-03-22"
---

## Sumario

Este ADR define o modelo de dados completo da base vetorial que suporta o RAG Corporativo. O modelo combina duas capacidades na mesma engine:

1. **Grafo de Conhecimento** — nos e relacoes que representam a estrutura organizacional do conhecimento (quem escreveu, para qual sistema, de qual modulo, com que relacoes)
2. **Busca Vetorial** — embeddings armazenados nos chunks para busca semantica (encontrar trechos relevantes por similaridade de significado)

A combinacao dessas duas capacidades torna o projeto um GraphRAG, e nao apenas um RAG convencional. O grafo amplia o contexto recuperado pela busca vetorial — quando o usuario pergunta algo, o sistema retorna chunks similares e tambem navega o grafo para trazer contexto relacionado (outros documentos do mesmo sistema, decisoes que impactam o modulo, responsaveis, glossario).

**Relaciona-se com:** [[BETA-001]] (Pipeline 4 Fases), [[BETA-002]] (Soberania de Dados)

## 1. Contexto

### 1.1. O que a Base Vetorial precisa suportar

O pipeline de 4 fases da [[BETA-001]] produz, na Fase 4, dados que precisam ser armazenados e consultados pela base vetorial:

- **Documentos .md** (Fase 3): arquivos Markdown com front matter rico contendo metadados de governanca
- **Chunks**: fragmentos semanticos dos documentos, cada um com seu embedding vetorial — unidade basica de busca
- **Entidades organizacionais**: sistemas, modulos, times, responsaveis, termos de glossario, tarefas, ADRs
- **Relacoes**: conexoes tipadas entre entidades
- **Versionamento temporal**: rastreabilidade de versoes com valid_from/valid_until

### 1.2. Escopo do modelo

O modelo cobre **apenas** os artefatos da Fase 3 (.md final) e Fase 4 (Base Vetorial) do pipeline definido na [[BETA-001]]. O `.beta.md` (Fase 2) reside exclusivamente no repositorio rag-workspace e **nao** e modelado na Base Vetorial. Essa exclusao e deliberada: o `.beta.md` e um artefato de trabalho, nao uma fonte da verdade.

### 1.3. Mapeamento aos 8 pilares da ADR-001

| Pilar | Descricao (ADR-001) | Como o modelo atende |
|-------|---------------------|----------------------|
| A | Segregacao de responsabilidades | Owner, Team, OWNED_BY, MEMBER_OF |
| B | Desacoplamento de etapas | Cada label e independente (Document existe sem Chunk, System sem Module) |
| C | Metodo garantidor de qualidade | conversion_quality no Document, token_count no Chunk (faixa 300-800) |
| D | Observabilidade e Governanca | created_at/updated_at em todos os nos, chunk_count, version_count, status |
| E | Clareza da informacao | heading_path preserva hierarquia semantica, GlossaryTerm + USES_TERM |
| F | Versionamento | DocumentFamily + VERSION_OF + SUPERSEDES + valid_from/valid_until |
| G | Rastreabilidade de origem | git_commit_hash, source_repo, path, git_branch, source_format |
| H | Reprodutibilidade | embedding_model + embedding_version + git_commit_hash |

### 1.4. Requisitos do modelo

- **R1 — Busca semantica**: vector index nos embeddings dos chunks (cosine similarity, >0.7 threshold)
- **R2 — Expansao por grafo**: navegar o grafo a partir de um chunk encontrado para contexto relacionado
- **R3 — Filtros pre-retrieval**: filtrar por confidentiality, system, module, status, domain ANTES da busca vetorial
- **R4 — Temporalidade**: consultar "como era X na data Y?" via valid_from/valid_until e cadeia SUPERSEDES
- **R5 — Rastreabilidade**: de qualquer chunk ate a fonte original (documento, repositorio, commit, autor)
- **R6 — Governanca**: owner, team, status, tags para filtros gerenciais
- **R7 — Glossario**: termos de negocio controlados vinculados aos documentos
- **R8 — Dependencias**: relacoes DEPENDS_ON e IMPLEMENTS para analise de impacto

## 2. Decisao

Adotar modelo de grafo com **10 tipos de no (labels)**, **13 tipos de relacao**, constraints de unicidade, indices compostos e vector index. O modelo suporta versionamento temporal via DocumentFamily + relacoes SUPERSEDES/VERSION_OF com campos valid_from/valid_until.

### 2.1. Nos (Labels) — 10 Tipos

<!-- LOCKED:START autor=fabio data=2026-03-22 -->

| # | Label | Descricao | ID Unico | Propriedades-chave |
|---|-------|-----------|----------|--------------------|
| 1 | **Document** | Arquivo .md ingerido na base vetorial. No central do grafo. | `document_id` (DOC-NNNNNN) | title, doc_type, system, module, domain, owner, team, status, confidentiality, tags, path, source_repo, git_commit_hash, git_branch, valid_from, valid_until, superseded_by, conversion_quality, source_format, created_at, updated_at, chunk_count |
| 2 | **Chunk** | Fragmento semantico de um Document. Unidade atomica de busca vetorial. | `chunk_id` ({document_id}_chunk_{NNN}) | content, embedding, embedding_model, embedding_version, token_count, chunk_index, heading_path, metadata_inherited, created_at |
| 3 | **System** | Sistema corporativo (software, plataforma, servico). | `system_id` (SYS-XXX) | name, description, domain, status, created_at, updated_at |
| 4 | **Module** | Modulo funcional de um sistema. | `module_id` (MOD-XXX) | name, description, status, created_at, updated_at |
| 5 | **Owner** | Responsavel por conteudo, sistema ou modulo (pessoa ou service account). | `owner_id` | display_name, email, type (person/service-account), created_at |
| 6 | **Team** | Time, squad, chapter, diretoria ou area organizacional. | `team_id` | name, type (squad/chapter/directorate/area), parent_team_id, created_at |
| 7 | **Task** | Tarefa de ferramenta de gestao (ClickUp, Jira, Azure DevOps). | `task_id` (CU-XXXX, JIRA-XXXX) | title, source_tool, status, url, created_at |
| 8 | **ADR** | Registro de Decisao Arquitetural. Double-labeling com Document (:ADR:Document). | `adr_id` (ADR-NNN) | decision_status (proposed/accepted/deprecated/superseded), date_decided, deciders + todas propriedades de Document |
| 9 | **GlossaryTerm** | Termo de negocio controlado com definicao oficial. | `term_id` (TERM-XXX) | term, definition, synonyms, domain, created_at, updated_at |
| 10 | **DocumentFamily** | Agrupa todas as versoes de um mesmo documento conceitual ao longo do tempo. | `family_id` (FAM-XXX) | title, current_version_id, version_count, domain, created_at, updated_at |

<!-- LOCKED:END -->

**Nota sobre desnormalizacao:** o campo `metadata_inherited` no Chunk duplica dados do Document pai (system, module, domain, confidentiality). Isso e **intencional** — a busca vetorial com filtro precisa acessar o campo de filtro e o embedding no mesmo no. Sem isso, toda busca vetorial precisaria de JOIN (Chunk→Document), degradando performance significativamente.

### 2.2. Relacoes — 13 Tipos

| # | Relacao | Direcao | Propriedades | Finalidade |
|---|---------|---------|-------------|------------|
| 1 | **PART_OF** | Chunk → Document | created_at | Vincula chunk ao documento de origem |
| 2 | **BELONGS_TO** | Document → Module | role (primary/supplementary/reference), created_at | Vincula documento ao modulo funcional |
| 3 | **BELONGS_TO** | Module → System | created_at | Hierarquia organizacional |
| 4 | **OWNED_BY** | Document → Owner | since, created_at | Responsabilidade e autoria |
| 5 | **MEMBER_OF** | Owner → Team | role (lead/member/contributor), since, created_at | Estrutura organizacional |
| 6 | **RELATES_TO_TASK** | Document → Task | relationship_type (documents/references/created_by), created_at | Conecta conhecimento a execucao |
| 7 | **REFERENCES** | Document → Document | reference_type (wikilink/citation/see-also), context, created_at | Rede de conhecimento |
| 8 | **USES_TERM** | Document → GlossaryTerm | frequency, created_at | Desambiguacao terminologica |
| 9 | **DECIDES** | ADR → System | scope (architecture/infra/process/security), created_at | Rastreabilidade de decisoes |
| 10 | **DEPENDS_ON** | Module → Module | dependency_type (runtime/build/data/api), strength (hard/soft), created_at | Analise de impacto |
| 11 | **IMPLEMENTS** | Task → Module | contribution_type (new-feature/bugfix/refactoring/documentation), created_at | Rastreabilidade de execucao |
| 12 | **SUPERSEDES** | Document → Document | effective_date, reason, created_at | Versionamento temporal (cadeia linear) |
| 13 | **VERSION_OF** | Document → DocumentFamily | version_number, version_label, is_current, created_at | Agrupamento de versoes (estrela) |

### 2.3. Constraints e Indices

#### 2.3.1. Constraints de unicidade

Todos os 10 tipos de no possuem constraint de unicidade no seu identificador:

1. `Document.document_id` — UNIQUE
2. `Chunk.chunk_id` — UNIQUE
3. `DocumentFamily.family_id` — UNIQUE
4. `System.system_id` — UNIQUE
5. `Module.module_id` — UNIQUE
6. `Owner.owner_id` — UNIQUE
7. `Team.team_id` — UNIQUE
8. `Task.task_id` — UNIQUE
9. `GlossaryTerm.term_id` — UNIQUE
10. `ADR.adr_id` — UNIQUE

#### 2.3.2. Vector Index

- **Alvo**: `Chunk.embedding`
- **Dimensao**: 1536 (Trilha A) ou 1024 (Trilha B) — conforme [[BETA-002]]
- **Similaridade**: cosine
- Instancias de trilhas diferentes **nao podem** compartilhar o mesmo vector index

#### 2.3.3. Indices auxiliares

| # | Indice | Justificativa |
|---|--------|---------------|
| 1 | `Document.doc_type` | Filtro por tipo (ADRs, runbooks) |
| 2 | `Document.system` | Filtro de escopo por sistema |
| 3 | `Document.module` | Refinamento de escopo |
| 4 | `Document.confidentiality` | **Filtro critico de seguranca** — aplicado em toda busca |
| 5 | `Document.status` | Filtro draft/approved/deprecated |
| 6 | `Document.domain` | Filtro por area de negocio |
| 7 | `Document.path` | Lookup rapido por caminho de arquivo |
| 8 | `Document.valid_from` + `Document.valid_until` | Consultas temporais (composto) |
| 9 | `Chunk.metadata_inherited.confidentiality` | Filtro de seguranca direto no chunk |
| 10 | `GlossaryTerm.term` | Lookup rapido por termo |
| FT-1 | `Document.title` (full-text) | Busca por titulo com parcial matching |
| FT-2 | `GlossaryTerm.term` + `GlossaryTerm.synonyms` (full-text) | Busca fuzzy por termos e sinonimos |

### 2.4. Estrategia de Chunking por Tipo de Documento

| doc_type | Estrategia | Faixa de tokens | Detalhes |
|----------|-----------|-----------------|----------|
| **system-doc** | Chunking por heading (H1, H2, H3) | 300-800 | Mesma base do architecture-doc. Secoes de configuracao/integracao/operacao sao chunks separados mesmo se curtos |
| **architecture-doc** | Chunking por heading (H1, H2, H3) | 300-800 | Cada heading inicia novo chunk. Excedentes >800 tokens subdivididos por paragrafo. <300 tokens agrupados com proximo heading |
| **adr** | Chunks menores e precisos por secao | 200-500 | Secoes separadas: Contexto, Decisao, Alternativas (uma por alternativa), Consequencias. Decisao nunca subdivida |
| **runbook** | Chunk por procedimento/passo | 200-600 | Cada procedimento = 1 chunk. Pre-requisitos e Troubleshooting em chunks separados. Passos individuais NAO separados |
| **glossary** | Chunk quase atomico por termo | 50-200 | Cada termo = 1 chunk (termo + definicao + sinonimos + exemplo). Termos relacionados linkados via USES_TERM |
| **task-doc** | Chunk por contexto, escopo, decisao e aceite | 300-600 | Secoes separadas: Contexto, Escopo/Requisitos, Decisoes Tecnicas (1 por decisao), Criterios de Aceite, Observacoes/Riscos |

### 2.5. Modelo Temporal — DocumentFamily + SUPERSEDES + VERSION_OF

O modelo temporal opera em tres camadas:

1. **Front matter do .md**: campos `valid_from`, `valid_until`, `superseded_by`, `supersedes`
2. **Grafo (relacoes e nos)**: Document → VERSION_OF → DocumentFamily + cadeia SUPERSEDES
3. **Retrieval (filtros temporais)**: deteccao de contexto temporal na query ("como era X em 2024?" → filtrar valid_from/valid_until)

### 2.6. Exemplos de Queries

**Query 1 — Busca semantica com filtro de confidencialidade:**

```
// Pseudocodigo — sintaxe pode variar conforme a Base Vetorial
CALL db.index.vector.queryNodes(
  'chunk_embedding_index', 10, $query_embedding
) YIELD node AS chunk, score
WHERE chunk.metadata_inherited.confidentiality IN ['public', 'internal']
  AND score > 0.7
RETURN chunk.chunk_id, chunk.content, chunk.heading_path, score
ORDER BY score DESC;
```

**Query 2 — Expansao de contexto via grafo:**

A partir de um chunk encontrado, expandir para o documento pai, chunks adjacentes, documentos referenciados e glossario.

**Query 3 — Consulta temporal:**

Filtrar por `valid_from <= data_alvo` e `valid_until IS NULL OR valid_until >= data_alvo` para encontrar versao vigente em data especifica.

**Query 4 — Analise de impacto:**

A partir de um modulo, navegar DEPENDS_ON, BELONGS_TO, DECIDES e IMPLEMENTS para mapear todos os artefatos impactados.

## 3. Alternativas Descartadas

### 3.1. Modelo relacional (SQL) com extensao vetorial

- **Descricao**: PostgreSQL com pgvector para vetores + tabelas relacionais para metadados
- **Rejeicao**: nao suporta traversal de grafo eficiente. Queries de expansao de contexto requerem 4+ JOINs em SQL. A expansao via grafo e o diferencial do GraphRAG

### 3.2. Dois bancos separados (SQL + Grafo)

- **Descricao**: PostgreSQL + pgvector para vetores, banco de grafo separado para relacoes
- **Rejeicao**: duplicacao de dados, sincronizacao entre bancos, latencia de rede, complexidade operacional dobrada. Bases vetoriais modernas suportam vector index + graph traversal na mesma engine

### 3.3. Modelo sem DocumentFamily

- **Descricao**: versionamento apenas por cadeia SUPERSEDES, sem no DocumentFamily
- **Rejeicao**: para encontrar todas as versoes seria necessario navegar cadeia inteira (O(n) hops). Com DocumentFamily, uma unica query resolve. Alem disso, sem DocumentFamily nao ha local para current_version_id

### 3.4. Embedding no documento inteiro (sem chunks)

- **Descricao**: um unico embedding por documento, sem chunking
- **Rejeicao**: documentos longos geram embeddings diluidos; janela de contexto do LLM desperdicada com documentos inteiros; precisao de busca cai drasticamente

### 3.5. Chunking por tamanho fixo

- **Descricao**: ignorar estrutura do documento e chunkar por tamanho fixo (ex: 512 tokens)
- **Rejeicao**: corta no meio de frases e conceitos, heading_path se perde, embedding resultante ruidoso. Chunking semantico por heading gera embeddings mais precisos (~10-20% maior precision@10)

## 4. Consequencias

### 4.1. Positivas

- **GraphRAG completo**: busca semantica + expansao de contexto na mesma engine
- **Governanca nativa**: owner, team, status, confidentiality como propriedades diretas dos nos
- **Temporalidade**: DocumentFamily + SUPERSEDES + valid_from/valid_until para consultas historicas
- **Analise de impacto**: relacoes DEPENDS_ON, IMPLEMENTS, DECIDES para traversal em milissegundos
- **Desambiguacao**: GlossaryTerm + USES_TERM para expansao de sinonimos
- **Rastreabilidade completa**: de qualquer chunk ate arquivo original, commit, repositorio, autor
- **Chunking otimizado**: estrategias diferenciadas por tipo de documento

### 4.2. Negativas / Trade-offs

- **Complexidade do modelo**: 10 tipos de no e 13 relacoes exigem curva de aprendizado
- **Desnormalizacao**: metadata_inherited no Chunk duplica dados (risco de inconsistencia)
- **Custo de manutencao**: evolucao do modelo requer migracao cuidadosa em producao
- **Overhead de ingestao**: pipeline precisa criar nos de System, Module, Owner, Team, Task, GlossaryTerm alem de Document e Chunk

### 4.3. Riscos e Mitigacoes

| Risco | Descricao | Mitigacao |
|-------|-----------|-----------|
| Chunks orfaos | Na re-ingestao, chunks antigos podem nao ser removidos se o pipeline falhar | Cleanup job que detecta chunks sem PART_OF e os remove |
| Inconsistencia metadata_inherited | Document muda confidentiality mas chunks ficam com valor antigo | Na atualizacao de Document, SEMPRE propagar para chunks |
| DocumentFamily desatualizada | current_version_id aponta para versao errada | Atualizar atomicamente na mesma transacao de criacao de nova versao |
| Performance de vector index | Filtros pre-retrieval podem degradar performance | Indices compostos nos campos de filtro mais usados |

### 4.4. Metricas de Observabilidade

| # | Metrica | Alerta se |
|---|---------|-----------|
| M1 | Total de nos por label | Queda >20% entre ingestoes |
| M2 | Chunks orfaos (sem PART_OF) | > 0 |
| M3 | Documents sem OWNED_BY | > 0 |
| M4 | DocumentFamilies com current_version_id invalido | > 0 |
| M5 | Chunks com token_count fora da faixa (<100 ou >1000) | > 10% do total |
| M6 | Documents com chunk_count = 0 | > 0 |
| M7 | Tempo medio de query vetorial (p95) | > 500ms |
| M8 | Documents com status=draft na Base Vetorial | > 0 |
| M9 | Inconsistencia metadata_inherited vs. Document pai | > 0 |
| M10 | Embeddings com modelo diferente do vigente | > 0 |

## 5. Implementacao

| Fase | Entrega | DOD |
|------|---------|-----|
| **MVP** | Document + Chunk + PART_OF + vector index + busca semantica simples | Constraints 1-2, vector index funcional, query com score >0.7, filtro por confidentiality |
| **Metadados** | + System, Module, Owner, Team + relacoes BELONGS_TO, OWNED_BY, MEMBER_OF | Constraints 3-10, indices 1-7, filtros pre-retrieval por system/module/status |
| **KG** | + Task, ADR, GlossaryTerm, DocumentFamily + todas relacoes restantes | 13 relacoes, expansao de contexto via grafo, analise de impacto |
| **GraphRAG** | + Retrieval hibrido, temporalidade, reranking, seguranca por escopo | Consultas temporais, metricas M1-M10, benchmark de busca validado |

## 6. Diagrama do Modelo

```
                        [Team]
                       (team_id)
                          ^
                          |
                       MEMBER_OF
                          |
[Task] <--RELATES_TO-- [Document] --OWNED_BY--> [Owner]
(task_id)            (document_id)             (owner_id)
  |                      |     |
  |                      |     +--BELONGS_TO--> [Module] --BELONGS_TO--> [System]
  |                      |                     (module_id)              (system_id)
  +--IMPLEMENTS--------->+                       ^    |                    ^
                         |                       |  DEPENDS_ON            |
                         |                       +----+               DECIDES
                         |                                              |
                         +--REFERENCES--> [Document]                  [ADR]
                         |                                           (adr_id)
                         +--USES_TERM--> [GlossaryTerm]
                         |              (term_id)
                         +--SUPERSEDES--> [Document]
                         +--VERSION_OF--> [DocumentFamily]
                         |               (family_id)
                         v
                      [Chunk] --PART_OF--> [Document]
                     (chunk_id)
                     (embedding) <-- vector index
```

## 7. Referencias

**Decisoes relacionadas:**

- [[BETA-001]] — Pipeline de Geracao de Conhecimento em 4 Fases
- [[BETA-002]] — Soberania de Dados: Cloud vs. On-Premise

**Documentos do blueprint:**

- B05 — Knowledge Graph (modelo de grafo original)
- B03 — Camada Ouro (pipeline de ingestao)
- B04 — Metadados e Governanca (front matter)

---

<!-- QA-BETA: inicio -->
## Quality Assurance — .beta.md

| Critério | Peso | Nota | Comentário |
|----------|------|------|------------|
| Front matter leve | 25% | 100% | id BETA-003 valido, title descritivo (37 chars), domain lowercase, confidentiality enum valido, sources com type/origin/captured_at (conversion_quality ausente mas opcional), 6 tags, status approved, aliases array (3), datas ISO validas. Nenhum campo de governanca presente no front matter (campos system/module/owner/doc_type aparecem apenas dentro de tabelas descrevendo o modelo de dados, nao no YAML). |
| Completude de conteudo | 25% | 88% | Secoes principais preservadas: Sumario, Contexto (1.1-1.4), Decisao (nos, relacoes, constraints, indices, chunking, temporal, queries), Alternativas (5), Consequencias (positivas/negativas/riscos/metricas), Implementacao, Diagrama, Referencias. Porem: o .txt de 2259 linhas possui detalhamento significativamente maior — cada um dos 10 nos tem descricao expandida (~50 linhas cada), cada relacao tem exemplos Cypher, secao 2.6 com queries completas em pseudocodigo (4 queries detalhadas). A versao beta condensou para tabelas e pseudocodigo resumido. |
| Blocos LOCKED | 15% | 100% | Bloco LOCKED presente (linhas 74-89) protegendo a tabela dos 10 tipos de no — a decisao mais critica do modelo de dados. Corretamente aberto e fechado. |
| Wikilinks | 10% | 100% | Usa formato [[BETA-001]], [[BETA-002]] corretamente. Sem wikilinks no front matter. |
| Compatibilidade Obsidian | 10% | 100% | YAML entre --- valido, tags como array YAML, aliases como array YAML. |
| Clareza e estrutura | 15% | 93% | Boa organizacao com numeracao hierarquica (1., 1.1., 2., 2.1., etc.), tabelas para nos/relacoes/constraints/indices/chunking/metricas, diagrama ASCII do modelo. Code blocks para queries. Ponto de atencao: algumas tabelas sao muito largas e podem nao renderizar bem em telas menores. |

**Score:** 95.5% — APROVADO para promocao

**Por que nao e 100%:** (1) Completude: o .txt original (2259 linhas) possui detalhamento expandido para cada no (propriedades, justificativas, exemplos), cada relacao (exemplos Cypher) e queries completas na secao 2.6 — a versao beta condensou significativamente. (2) Diagrama ASCII pode ser difícil de ler sem contexto. (3) conversion_quality ausente no sources (opcional, mas presente nos outros 3 betas — inconsistencia menor).
<!-- QA-BETA: fim -->
