---
id: BETA-003
title: "Modelo de Dados da Base Vetorial"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-003_modelo_dados_base_vetorial.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags: [modelo de dados, base vetorial, graphrag, grafo de conhecimento, chunking, embeddings, neo4j, vector index, document, chunk, system, module, owner, team, task, adr, glossary term, document family, relacoes, constraints, indices, busca semantica, expansao por grafo, filtro pre retrieval, temporalidade, rastreabilidade, governanca, dependencias, versionamento, supersedes, version of, part of, belongs to, owned by, member of, relates to task, references, uses term, decides, depends on, implements, desnormalizacao, metadata inherited, heading path, cosine similarity, embedding model, chunking por heading, chunking semantico, analise de impacto, full text index]
aliases:
  - "ADR-003"
  - "Modelo de Grafo"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## Sumario

Este ADR define o modelo de dados completo da base vetorial que suporta o RAG Corporativo. O modelo combina duas capacidades na mesma engine:

1. **Grafo de Conhecimento** — nos e relacoes que representam a estrutura organizacional do conhecimento (quem escreveu, para qual sistema, de qual modulo, com que relacoes)
2. **Busca Vetorial** — embeddings armazenados nos chunks para busca semantica (encontrar trechos relevantes por similaridade de significado, nao por keywords)

A combinacao dessas duas capacidades e o que torna o projeto um GraphRAG e nao apenas um RAG convencional. O grafo amplia o contexto recuperado pela busca vetorial — quando o usuario pergunta algo, o sistema nao retorna apenas chunks similares, mas tambem navega o grafo para trazer contexto relacionado (outros documentos do mesmo sistema, decisoes que impactam o modulo, responsaveis, glossario).

**Relaciona-se com:** [[BETA-001]] (Pipeline 4 Fases), [[BETA-002]] (Soberania de Dados)

## 1. Contexto

### 1.1. O que a Base Vetorial precisa suportar

O pipeline de 4 fases da [[BETA-001]] produz, na Fase 4, dados que precisam ser armazenados e consultados pela base vetorial:

- **Documentos .md** (Fase 3): arquivos Markdown com front matter rico contendo metadados de governanca (sistema, modulo, owner, team, confidentiality, status, temporalidade)
- **Chunks**: fragmentos semanticos dos documentos, cada um com seu embedding vetorial — unidade basica de busca
- **Entidades organizacionais**: sistemas, modulos, times, responsaveis, termos de glossario, tarefas, ADRs — formam o esqueleto do grafo
- **Relacoes**: conexoes tipadas entre entidades (documento pertence a modulo, modulo pertence a sistema, documento referencia outro documento, etc.)
- **Versionamento temporal**: rastreabilidade de versoes com valid_from/valid_until (qual era a versao vigente em uma data especifica?)

### 1.2. Escopo do modelo

Este modelo cobre **apenas** os artefatos da Fase 3 (.md final) e Fase 4 (Base Vetorial) do pipeline definido na [[BETA-001]]. O `.beta.md` (Fase 2) reside exclusivamente no repositorio rag-workspace e **nao** e modelado na Base Vetorial. Essa exclusao e deliberada: o `.beta.md` e um artefato de trabalho, nao uma fonte da verdade. Apenas o .md final (promovido pela Fase 3) e ingerido na Base Vetorial.

### 1.3. Mapeamento aos 8 pilares da ADR-001

| Pilar | Descricao (ADR-001) | Como o modelo atende |
|-------|---------------------|----------------------|
| A | Segregacao de responsabilidades | Owner, Team, OWNED_BY, MEMBER_OF identificam quem e responsavel por cada artefato |
| B | Desacoplamento de etapas | Cada label e independente (Document existe sem Chunk, System sem Module) |
| C | Metodo garantidor de qualidade | conversion_quality no Document, token_count no Chunk (faixa 300-800), chunk_count para deteccao de anomalias |
| D | Observabilidade e Governanca | created_at/updated_at em todos os nos, chunk_count, version_count, status. Metricas na secao 4.4 |
| E | Clareza da informacao | heading_path preserva hierarquia semantica, GlossaryTerm + USES_TERM desambiguam termos |
| F | Versionamento | DocumentFamily + VERSION_OF + SUPERSEDES + valid_from/valid_until |
| G | Rastreabilidade de origem | git_commit_hash, source_repo, path, git_branch, source_format, conversion_quality |
| H | Reprodutibilidade | embedding_model + embedding_version permitem saber exatamente como cada embedding foi gerado; git_commit_hash permite reconstruir o documento |

### 1.4. Requisitos do modelo

- **R1 — Busca semantica**: suportar vector index nos embeddings dos chunks para busca por similaridade (cosine similarity, >0.7 threshold)
- **R2 — Expansao por grafo**: a partir de um chunk encontrado, navegar o grafo para contexto relacionado (outros chunks do mesmo documento, documentos do mesmo sistema, ADRs que decidem sobre o modulo, etc.)
- **R3 — Filtros pre-retrieval**: filtrar por confidentiality, system, module, status, domain ANTES da busca vetorial
- **R4 — Temporalidade**: consultar "como era X na data Y?" usando valid_from/valid_until e cadeia SUPERSEDES
- **R5 — Rastreabilidade**: de qualquer chunk, rastrear ate a fonte original (documento, repositorio, commit, autor)
- **R6 — Governanca**: owner, team, status, tags para filtros gerenciais
- **R7 — Glossario**: termos de negocio controlados vinculados aos documentos
- **R8 — Dependencias**: relacoes DEPENDS_ON e IMPLEMENTS para analise de impacto

## 2. Decisao

Adotar modelo de grafo com **10 tipos de no (labels)**, **13 tipos de relacao**, constraints de unicidade, indices compostos e vector index. O modelo suporta versionamento temporal via DocumentFamily + relacoes SUPERSEDES/VERSION_OF com campos valid_from/valid_until.

### 2.1. Nos (Labels) — 10 Tipos

<!-- LOCKED:START autor=fabio data=2026-03-22 -->

| # | Label | Descricao | ID Unico | Propriedades-chave |
|---|-------|-----------|----------|--------------------|
| 1 | **Document** | Arquivo .md ingerido na base vetorial. No central do grafo. Cada arquivo .md gera exatamente um no Document. | `document_id` (DOC-NNNNNN) | title, doc_type, system, module, domain, owner, team, status, confidentiality, tags, path, source_repo, git_commit_hash, git_branch, valid_from, valid_until, superseded_by, conversion_quality, source_format, created_at, updated_at, chunk_count |
| 2 | **Chunk** | Fragmento semantico de um Document. Unidade atomica de busca vetorial. O embedding e gerado por chunk, nao por documento. Um Document gera N chunks (tipicamente 3-20). | `chunk_id` ({document_id}_chunk_{NNN}) | content, embedding, embedding_model, embedding_version, token_count, chunk_index, heading_path, metadata_inherited, created_at |
| 3 | **System** | Sistema corporativo (software, plataforma, servico). Nivel mais alto de agrupamento organizacional do conhecimento. | `system_id` (SYS-XXX) | name, description, domain, status, created_at, updated_at |
| 4 | **Module** | Modulo funcional de um sistema. Subdivisao logica (ex: Sistema de Cobranca → Modulo de Boleto, Modulo de Remessa). | `module_id` (MOD-XXX) | name, description, status, created_at, updated_at |
| 5 | **Owner** | Responsavel por conteudo, sistema ou modulo (pessoa ou service account). | `owner_id` | display_name, email, type (person/service-account), created_at |
| 6 | **Team** | Time, squad, chapter, diretoria ou area organizacional. Agrupa Owners. | `team_id` | name, type (squad/chapter/directorate/area), parent_team_id, created_at |
| 7 | **Task** | Tarefa de ferramenta de gestao (ClickUp, Jira, Azure DevOps). Vincula conhecimento a acoes concretas. | `task_id` (CU-XXXX, JIRA-XXXX) | title, source_tool, status, url, created_at |
| 8 | **ADR** | Registro de Decisao Arquitetural. Double-labeling com Document (:ADR:Document). Tem relacoes semanticas proprias (DECIDES). | `adr_id` (ADR-NNN) | decision_status (proposed/accepted/deprecated/superseded), date_decided, deciders + todas propriedades de Document |
| 9 | **GlossaryTerm** | Termo de negocio controlado com definicao oficial. Desambiguacao e consistencia terminologica. | `term_id` (TERM-XXX) | term, definition, synonyms, domain, created_at, updated_at |
| 10 | **DocumentFamily** | Agrupa todas as versoes de um mesmo documento conceitual ao longo do tempo. Viabiliza consultas temporais. | `family_id` (FAM-XXX) | title, current_version_id, version_count, domain, created_at, updated_at |

<!-- LOCKED:END -->

**Nota sobre desnormalizacao:** o campo `metadata_inherited` no Chunk duplica dados do Document pai (system, module, domain, confidentiality). Isso e **intencional** — a busca vetorial com filtro precisa acessar o campo de filtro e o embedding no mesmo no. Sem isso, toda busca vetorial precisaria de JOIN (Chunk→Document), degradando performance significativamente em vector indexes.

### 2.2. Relacoes — 13 Tipos

| # | Relacao | Direcao | Propriedades | Finalidade |
|---|---------|---------|-------------|------------|
| 1 | **PART_OF** | Chunk → Document | created_at | Vincula chunk ao documento de origem. Relacao mais fundamental — sem ela, chunks sao fragmentos orfaos |
| 2 | **BELONGS_TO** | Document → Module | role (primary/supplementary/reference), created_at | Vincula documento ao modulo funcional |
| 3 | **BELONGS_TO** | Module → System | created_at | Hierarquia organizacional (System → Modules → Documents) |
| 4 | **OWNED_BY** | Document → Owner | since, created_at | Responsabilidade e autoria. Todo documento tem um dono |
| 5 | **MEMBER_OF** | Owner → Team | role (lead/member/contributor), since, created_at | Estrutura organizacional. Viabiliza governanca por grupo |
| 6 | **RELATES_TO_TASK** | Document → Task | relationship_type (documents/references/created_by), created_at | Conecta conhecimento a execucao |
| 7 | **REFERENCES** | Document → Document | reference_type (wikilink/citation/see-also), context, created_at | Rede de conhecimento. Viabiliza expansao de contexto e analise de impacto |
| 8 | **USES_TERM** | Document → GlossaryTerm | frequency, created_at | Desambiguacao terminologica. Expansao de busca por sinonimos |
| 9 | **DECIDES** | ADR → System | scope (architecture/infra/process/security), created_at | Rastreabilidade de decisoes arquiteturais |
| 10 | **DEPENDS_ON** | Module → Module | dependency_type (runtime/build/data/api), strength (hard/soft), created_at | Analise de impacto e arquitetura |
| 11 | **IMPLEMENTS** | Task → Module | contribution_type (new-feature/bugfix/refactoring/documentation), created_at | Rastreabilidade de execucao |
| 12 | **SUPERSEDES** | Document → Document | effective_date, reason, created_at | Versionamento temporal (cadeia linear: v2026 SUPERSEDES v2025 SUPERSEDES v2024) |
| 13 | **VERSION_OF** | Document → DocumentFamily | version_number, version_label, is_current, created_at | Agrupamento de versoes (estrela: todas as versoes conectadas a um ponto central) |

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

Exemplo de criacao (Cypher como referencia — sintaxe pode variar conforme a Base Vetorial adotada):

```cypher
CREATE CONSTRAINT doc_unique_id FOR (d:Document) REQUIRE d.document_id IS UNIQUE;
CREATE CONSTRAINT chunk_unique_id FOR (c:Chunk) REQUIRE c.chunk_id IS UNIQUE;
CREATE CONSTRAINT family_unique_id FOR (f:DocumentFamily) REQUIRE f.family_id IS UNIQUE;
CREATE CONSTRAINT system_unique_id FOR (s:System) REQUIRE s.system_id IS UNIQUE;
CREATE CONSTRAINT module_unique_id FOR (m:Module) REQUIRE m.module_id IS UNIQUE;
CREATE CONSTRAINT owner_unique_id FOR (o:Owner) REQUIRE o.owner_id IS UNIQUE;
CREATE CONSTRAINT team_unique_id FOR (t:Team) REQUIRE t.team_id IS UNIQUE;
CREATE CONSTRAINT task_unique_id FOR (tk:Task) REQUIRE tk.task_id IS UNIQUE;
CREATE CONSTRAINT glossary_unique_id FOR (g:GlossaryTerm) REQUIRE g.term_id IS UNIQUE;
CREATE CONSTRAINT adr_unique_id FOR (a:ADR) REQUIRE a.adr_id IS UNIQUE;
```

#### 2.3.2. Vector Index

- **Alvo**: `Chunk.embedding`
- **Dimensao**: 1536 (Trilha A) ou 1024 (Trilha B) — conforme [[BETA-002]]
- **Similaridade**: cosine
- Instancias de trilhas diferentes **nao podem** compartilhar o mesmo vector index (reforça a separacao de instancias definida na [[BETA-002]])

Exemplo de criacao:

```cypher
-- Trilha A (OpenAI, 1536 dimensoes)
CREATE VECTOR INDEX chunk_embedding_index FOR (c:Chunk)
ON (c.embedding)
OPTIONS {indexConfig: {
  `vector.dimensions`: 1536,
  `vector.similarity_function`: 'cosine'
}};

-- Trilha B (BGE-M3, 1024 dimensoes)
CREATE VECTOR INDEX chunk_embedding_index FOR (c:Chunk)
ON (c.embedding)
OPTIONS {indexConfig: {
  `vector.dimensions`: 1024,
  `vector.similarity_function`: 'cosine'
}};
```

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
| **system-doc** | Chunking por heading (H1, H2, H3) | 300-800 | Mesma base do architecture-doc. Secoes de configuracao/integracao/operacao sao chunks separados mesmo se curtos, pois sao consultados individualmente por diferentes personas (dev, ops, suporte) |
| **architecture-doc** | Chunking por heading (H1, H2, H3) | 300-800 | Cada heading inicia novo chunk. Excedentes >800 tokens subdivididos por paragrafo. <300 tokens agrupados com proximo heading. heading_path preservado como contexto |
| **adr** | Chunks menores e precisos por secao | 200-500 | Secoes separadas: Contexto, Decisao, Alternativas (uma por alternativa), Consequencias. Decisao nunca subdividida |
| **runbook** | Chunk por procedimento/passo | 200-600 | Cada procedimento = 1 chunk. Pre-requisitos e Troubleshooting em chunks separados. Passos individuais NAO separados (procedimento com 5 passos = 1 chunk) |
| **glossary** | Chunk quase atomico por termo | 50-200 | Cada termo = 1 chunk (termo + definicao + sinonimos + exemplo). Termos relacionados linkados via USES_TERM |
| **task-doc** | Chunk por contexto, escopo, decisao e aceite | 300-600 | Secoes separadas: Contexto, Escopo/Requisitos, Decisoes Tecnicas (1 por decisao), Criterios de Aceite, Observacoes/Riscos |

### 2.5. Modelo Temporal — DocumentFamily + SUPERSEDES + VERSION_OF

O modelo temporal opera em tres camadas (conforme [[BETA-001]] secao 2.6):

**Camada 1 — Front matter do .md:**

```yaml
---
valid_from: "2026-01-01"
valid_until: null               # null = vigente
superseded_by: "DOC-000456"     # ID do doc que substitui
supersedes: "DOC-000123"        # ID do doc anterior
---
```

**Camada 2 — Grafo (relacoes e nos):**

```
(:Document {document_id: "DOC-000789", valid_from: "2026-01-01"})
  -[:VERSION_OF {version_number: 3, is_current: true}]->
(:DocumentFamily {family_id: "FAM-POLITICA-PRIVACIDADE",
                  current_version_id: "DOC-000789"})

(:Document "DOC-000789")-[:SUPERSEDES]->(:Document "DOC-000456")
(:Document "DOC-000456")-[:SUPERSEDES]->(:Document "DOC-000123")
```

**Camada 3 — Retrieval (filtros temporais):**

- "Como era a Politica de Privacidade em 2024?" → filtrar valid_from <= 2024 E valid_until >= 2024 (ou null)
- "Qual a Politica de Privacidade atual?" → filtrar valid_until IS NULL
- Sem contexto temporal → assumir data atual (valid_until IS NULL)

### 2.6. Exemplos de Queries

**Nota sobre sintaxe:** os exemplos abaixo utilizam sintaxe Cypher como linguagem de referencia. A sintaxe especifica pode variar conforme a Base Vetorial adotada. O importante e o modelo (nos, propriedades, relacoes), nao a sintaxe.

**Query 1 — Busca semantica com filtro de confidencialidade:**

```cypher
CALL db.index.vector.queryNodes(
  'chunk_embedding_index', 10, $query_embedding
) YIELD node AS chunk, score
WHERE chunk.metadata_inherited.confidentiality IN ['public', 'internal']
  AND score > 0.7
RETURN chunk.chunk_id, chunk.content, chunk.heading_path, score
ORDER BY score DESC;
```

**Query 2 — Expansao de contexto via grafo:**

```cypher
MATCH (chunk:Chunk {chunk_id: $found_chunk_id})-[:PART_OF]->(doc:Document)
OPTIONAL MATCH (sibling:Chunk)-[:PART_OF]->(doc)
WHERE sibling.chunk_index IN [chunk.chunk_index - 1, chunk.chunk_index + 1]
OPTIONAL MATCH (doc)-[:REFERENCES]->(related:Document)
OPTIONAL MATCH (doc)-[:USES_TERM]->(term:GlossaryTerm)
RETURN doc.title, doc.system, doc.module,
       collect(DISTINCT sibling.content) AS contexto_adjacente,
       collect(DISTINCT related.title) AS docs_relacionados,
       collect(DISTINCT {termo: term.term, definicao: term.definition}) AS glossario;
```

**Query 3 — Consulta temporal:**

```cypher
MATCH (doc:Document)-[:VERSION_OF]->(family:DocumentFamily {
  family_id: "FAM-POLITICA-PRIVACIDADE"
})
WHERE doc.valid_from <= date("2025-07-15")
  AND (doc.valid_until IS NULL OR doc.valid_until >= date("2025-07-15"))
MATCH (chunk:Chunk)-[:PART_OF]->(doc)
RETURN doc.document_id, doc.title, doc.valid_from, doc.valid_until,
       collect(chunk.content) AS conteudo
ORDER BY doc.valid_from DESC
LIMIT 1;
```

**Query 4 — Analise de impacto:**

```cypher
MATCH (mod:Module {module_id: "MOD-BOLETO"})
OPTIONAL MATCH (dependent:Module)-[:DEPENDS_ON]->(mod)
OPTIONAL MATCH (doc:Document)-[:BELONGS_TO]->(mod)
OPTIONAL MATCH (mod)-[:BELONGS_TO]->(sys:System)<-[:DECIDES]-(adr:ADR)
OPTIONAL MATCH (task:Task)-[:IMPLEMENTS]->(mod)
RETURN mod.name,
       collect(DISTINCT dependent.name) AS modulos_dependentes,
       collect(DISTINCT doc.title) AS documentos,
       collect(DISTINCT adr.adr_id) AS adrs_relacionadas,
       collect(DISTINCT {task: task.task_id, status: task.status}) AS tasks;
```

**Query 5 — Grafo de conhecimento completo de um sistema:**

```cypher
MATCH (sys:System {system_id: "SYS-COBRANCA"})
OPTIONAL MATCH (mod:Module)-[:BELONGS_TO]->(sys)
OPTIONAL MATCH (doc:Document)-[:BELONGS_TO]->(mod)
OPTIONAL MATCH (doc)-[:OWNED_BY]->(owner:Owner)
OPTIONAL MATCH (owner)-[:MEMBER_OF]->(team:Team)
OPTIONAL MATCH (adr:ADR)-[:DECIDES]->(sys)
RETURN sys, mod, doc, owner, team, adr;
```

**Exemplo — No Document com todas as propriedades:**

```cypher
(:Document {
  document_id: "DOC-000123",
  title: "Modulo de Cobranca — Geracao de Boletos",
  doc_type: "system-doc",
  system: "Sistema de Cobranca",
  module: "Boleto",
  domain: "Financeiro",
  owner: "fabio",
  team: "arquitetura",
  status: "approved",
  confidentiality: "internal",
  tags: ["boleto", "remessa", "cobranca", "cnab240"],
  path: "docs/financeiro/cobranca/geracao-boletos.md",
  source_repo: "rag-knowledge-base",
  git_commit_hash: "a1b2c3d4e5f6789012345678901234567890abcd",
  git_branch: "main",
  valid_from: date("2026-01-15"),
  valid_until: null,
  superseded_by: null,
  conversion_quality: 95.0,
  source_format: "confluence",
  created_at: datetime("2026-01-15T10:30:00Z"),
  updated_at: datetime("2026-03-21T14:00:00Z"),
  chunk_count: 7
})
```

**Exemplo — No Chunk com embedding:**

```cypher
(:Chunk {
  chunk_id: "DOC-000123_chunk_003",
  content: "O modulo de geracao de boletos utiliza o padrao CNAB 240...",
  embedding: [0.0123, -0.0456, 0.0789, ...],   // 1536 floats (Trilha A)
  embedding_model: "openai/text-embedding-3-small",
  embedding_version: "2026-01",
  token_count: 487,
  chunk_index: 2,
  heading_path: "Modulo de Cobranca > Geracao de Boletos > Arquivo de Remessa",
  metadata_inherited: {
    system: "Sistema de Cobranca",
    module: "Boleto",
    domain: "Financeiro",
    confidentiality: "internal"
  },
  created_at: datetime("2026-01-15T10:30:05Z")
})
```

**Exemplo — DocumentFamily para versionamento temporal:**

```cypher
// Familia
(:DocumentFamily {
  family_id: "FAM-POLITICA-PRIVACIDADE",
  title: "Politica de Privacidade Corporativa",
  current_version_id: "DOC-000789",
  version_count: 3,
  domain: "Juridico"
})

// Versao 1 (2024), Versao 2 (2025), Versao 3 (2026 — vigente)
// Cada uma conectada via VERSION_OF e cadeia SUPERSEDES
(:Document "DOC-000789")-[:SUPERSEDES]->(:Document "DOC-000456")
(:Document "DOC-000456")-[:SUPERSEDES]->(:Document "DOC-000123")
```

**Exemplo — ADR com double-labeling:**

```cypher
CREATE (a:ADR:Document {
  document_id: "DOC-000050",
  title: "Pipeline de Geracao de Conhecimento em 4 Fases",
  doc_type: "adr",
  adr_id: "ADR-001",
  decision_status: "accepted",
  date_decided: date("2026-03-21"),
  deciders: ["fabio"],
  // + todas as demais propriedades de Document
});

MATCH (a:ADR {adr_id: "ADR-001"}), (s:System {system_id: "SYS-RAG"})
CREATE (a)-[:DECIDES {scope: "architecture"}]->(s);
```

## 3. Alternativas Descartadas

### 3.1. Modelo relacional (SQL) com extensao vetorial

- **Descricao**: PostgreSQL com pgvector para vetores + tabelas relacionais para metadados
- **Pros**: SQL amplamente conhecido; PostgreSQL robusto e maduro; pgvector suporta busca vetorial; menor curva de aprendizado
- **Rejeicao**: nao suporta traversal de grafo eficiente. Queries de expansao de contexto requerem 4+ JOINs em SQL, com performance degradada. Em grafo, e um MATCH com 4 hops em milissegundos. A expansao via grafo e o diferencial do GraphRAG

### 3.2. Dois bancos separados (SQL + Grafo)

- **Descricao**: PostgreSQL + pgvector para busca vetorial, banco de grafo separado para relacoes
- **Pros**: cada banco faz o que faz melhor
- **Rejeicao**: duplicacao de dados, sincronizacao entre bancos, latencia de rede, complexidade operacional dobrada, transacoes distribuidas. Bases vetoriais modernas suportam vector index + graph traversal na mesma engine

### 3.3. Modelo sem DocumentFamily

- **Descricao**: versionamento apenas por cadeia SUPERSEDES, sem no DocumentFamily
- **Pros**: modelo mais simples, menos nos e relacoes
- **Rejeicao**: para encontrar todas as versoes seria necessario navegar cadeia inteira (O(n) hops). Com DocumentFamily, uma unica query resolve. Alem disso, sem DocumentFamily nao ha local para current_version_id

### 3.4. Embedding no documento inteiro (sem chunks)

- **Descricao**: um unico embedding por documento, sem chunking
- **Pros**: modelo mais simples, embedding captura contexto completo
- **Rejeicao**: documentos longos (>2000 tokens) geram embeddings diluidos; janela de contexto do LLM desperdicada com documentos inteiros; precisao de busca cai drasticamente

### 3.5. Chunking por tamanho fixo

- **Descricao**: ignorar estrutura do documento e chunkar por tamanho fixo (ex: 512 tokens)
- **Pros**: implementacao trivial, chunks uniformes
- **Rejeicao**: corta no meio de frases e conceitos, heading_path se perde, embedding resultante ruidoso. Chunking semantico por heading gera embeddings mais precisos (~10-20% maior precision@10 em benchmarks internos)

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
- **Desnormalizacao**: metadata_inherited no Chunk duplica dados (risco de inconsistencia se atualizacao nao for atomica)
- **Custo de manutencao**: evolucao do modelo requer migracao cuidadosa em producao
- **Overhead de ingestao**: pipeline precisa criar nos de System, Module, Owner, Team, Task, GlossaryTerm alem de Document e Chunk

### 4.3. Riscos e Mitigacoes

| Risco | Descricao | Mitigacao |
|-------|-----------|-----------|
| Chunks orfaos | Na re-ingestao, chunks antigos podem nao ser removidos se o pipeline falhar | Cleanup job que detecta chunks sem PART_OF e os remove |
| Inconsistencia metadata_inherited | Document muda confidentiality mas chunks ficam com valor antigo | Na atualizacao de Document, SEMPRE propagar para chunks (upsert transacional) |
| DocumentFamily desatualizada | current_version_id aponta para versao errada | Atualizar atomicamente na mesma transacao de criacao de nova versao |
| Performance de vector index | Filtros pre-retrieval podem degradar performance | Indices compostos nos campos de filtro mais usados. Monitorar query plans |

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
| M8 | Documents com status=draft na Base Vetorial | > 0 (nao devem existir) |
| M9 | Inconsistencia metadata_inherited vs. Document pai | > 0 |
| M10 | Embeddings com modelo diferente do vigente | > 0 (indica migracao incompleta) |

## 5. Implementacao

| Fase | Entrega | DOD |
|------|---------|-----|
| **MVP** | Document + Chunk + PART_OF + vector index + busca semantica simples | Constraints 1-2, vector index funcional, query com score >0.7, filtro por confidentiality |
| **Metadados** | + System, Module, Owner, Team + relacoes BELONGS_TO, OWNED_BY, MEMBER_OF | Constraints 3-10, indices 1-7, filtros pre-retrieval por system/module/status |
| **KG** | + Task, ADR, GlossaryTerm, DocumentFamily + todas relacoes restantes | 13 relacoes, expansao de contexto via grafo, analise de impacto |
| **GraphRAG** | + Retrieval hibrido, temporalidade, reranking, seguranca por escopo | Consultas temporais, metricas M1-M10, benchmark de busca validado |

**Responsaveis:** Arquiteto (definicao do modelo, constraints, indices, validacao), Engenharia de Dados (implementacao de constraints, indices, pipeline de ingestao), Engenharia de Software (queries de retrieval, expansao de contexto), Ops/DBA (monitoramento, metricas M1-M10, backup, performance tuning).

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

- [[BETA-001]] — Pipeline de Geracao de Conhecimento em 4 Fases (define as 4 fases cujos artefatos este modelo armazena)
- [[BETA-002]] — Soberania de Dados: Cloud vs. On-Premise (define as trilhas que impactam dimensao do embedding e instancias)

**Documentos do blueprint:**

- B05 — Knowledge Graph (modelo de grafo original)
- B03 — Camada Ouro (pipeline de ingestao que cria estes nos)
- B04 — Metadados e Governanca (front matter que popula as propriedades)

**Referencias tecnicas:**

- Vector Indexes na base vetorial: documentacao oficial de indices vetoriais
- GraphRAG for Python: biblioteca oficial de GraphRAG
- Chunking Best Practices: "Chunk Wisely" — pesquisas sobre estrategias de chunking
- MTEB Benchmark: avaliacao de modelos de embedding multilingue

**Documentos relacionados:**

- Depende de: ADR-001 (Pipeline 4 Fases), ADR-002 (Soberania de Dados)
- Impacta: B03 (Camada Ouro), B04 (Metadados e Governanca), B05 (Knowledge Graph)
- Relacionados: B14 (Seguranca e Soberania), B15 (Governanca), B16 (Roadmap de Implementacao)

<!-- conversion_quality: 95 -->
