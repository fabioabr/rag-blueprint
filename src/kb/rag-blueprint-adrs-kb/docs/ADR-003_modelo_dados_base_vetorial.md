---
# === IDENTIFICAÇÃO ===
id: ADR-003
doc_type: adr
title: "Modelo de Dados da Base Vetorial (GraphRAG)"

# === CLASSIFICAÇÃO ===
system: RAG Corporativo
module: Modelo de Dados
domain: Arquitetura
owner: fabio
team: arquitetura

# === STATUS E GOVERNANÇA ===
status: accepted
confidentiality: internal
date_decided: 2026-03-21

# === TEMPORAL ===
valid_from: "2026-03-21"
valid_until: null
supersedes: null
superseded_by: null

# === DESCOBERTA ===
tags: [modelo de dados, base vetorial, graphrag, grafo de conhecimento, chunking, embeddings, neo4j, vector index, document, chunk, system, module, owner, team, task, adr, glossary term, document family, relações, constraints, índices, busca semântica, expansão por grafo, filtro pre retrieval, temporalidade, rastreabilidade, governança, dependências, versionamento, supersedes, version of, part of, belongs to, owned by, member of, relates to task, references, uses term, decides, depends on, implements, desnormalização, metadata inherited, heading path, cosine similarity, embedding model, chunking por heading, chunking semântico, análise de impacto, full text index, document id, chunk id, family id, system id, module id, owner id, team id, task id, term id, adr id]
aliases:
  - "ADR-003"
  - "Modelo de Grafo"
  - "Modelo de Dados Base Vetorial"
  - "GraphRAG Data Model"
  - "Schema do Grafo de Conhecimento"

# === LINHAGEM ===
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/draft/ADR-003_modelo_dados_base_vetorial.txt"
source_beta_ids: ["BETA-003"]
conversion_pipeline: promotion-pipeline-v2
conversion_quality: 95
converted_at: "2026-03-23"

# === QA ===
qa_score: null
qa_date: null
qa_status: pending

# === DATAS ===
created_at: "2026-03-21"
updated_at: "2026-03-23"
---

# ADR-003 — Modelo de Dados da Base Vetorial (GraphRAG)

## Sumário

Este ADR define o modelo de dados completo da base vetorial que suporta o RAG Corporativo. O modelo combina duas capacidades na mesma engine:

1. **Grafo de Conhecimento** — nós e relações que representam a estrutura organizacional do conhecimento (quem escreveu, para qual sistema, de qual módulo, com que relações)
2. **Busca Vetorial** — embeddings armazenados nos chunks para busca semântica (encontrar trechos relevantes por similaridade de significado, não por keywords)

A combinação dessas duas capacidades é o que torna o projeto um GraphRAG e não apenas um RAG convencional. O grafo amplia o contexto recuperado pela busca vetorial — quando o usuário pergunta algo, o sistema não retorna apenas chunks similares, mas também navega o grafo para trazer contexto relacionado (outros documentos do mesmo sistema, decisões que impactam o módulo, responsáveis, glossário).

**Relaciona-se com:** [[ADR-001]] (Pipeline 4 Fases), [[ADR-002]] (Soberania de Dados)

## 1. Contexto

### 1.1. O que a Base Vetorial precisa suportar

O pipeline de 4 fases da [[ADR-001]] produz, na Fase 4, dados que precisam ser armazenados e consultados pela base vetorial:

- **Documentos .md** (Fase 3): arquivos Markdown com front matter rico contendo metadados de governança (sistema, módulo, owner, team, confidentiality, status, temporalidade)
- **Chunks**: fragmentos semânticos dos documentos, cada um com seu embedding vetorial — unidade básica de busca
- **Entidades organizacionais**: sistemas, módulos, times, responsáveis, termos de glossário, tarefas, ADRs — formam o esqueleto do grafo
- **Relações**: conexões tipadas entre entidades (documento pertence a módulo, módulo pertence a sistema, documento referencia outro documento, etc.)
- **Versionamento temporal**: rastreabilidade de versões com valid_from/valid_until (qual era a versão vigente em uma data específica?)

### 1.2. Escopo do modelo

Este modelo cobre **apenas** os artefatos da Fase 3 (.md final) e Fase 4 (Base Vetorial) do pipeline definido na [[ADR-001]]. O `.beta.md` (Fase 2) reside exclusivamente no repositório rag-workspace e **não** é modelado na Base Vetorial. Essa exclusão é deliberada: o `.beta.md` é um artefato de trabalho, não uma fonte da verdade. Apenas o .md final (promovido pela Fase 3) é ingerido na Base Vetorial.

### 1.3. Mapeamento aos 8 pilares da ADR-001

| Pilar | Descrição (ADR-001) | Como o modelo atende |
|-------|---------------------|----------------------|
| A | Segregação de responsabilidades | Owner, Team, OWNED_BY, MEMBER_OF identificam quem é responsável por cada artefato |
| B | Desacoplamento de etapas | Cada label é independente (Document existe sem Chunk, System sem Module) |
| C | Método garantidor de qualidade | conversion_quality no Document, token_count no Chunk (faixa 300-800), chunk_count para detecção de anomalias |
| D | Observabilidade e Governança | created_at/updated_at em todos os nós, chunk_count, version_count, status. Métricas na seção 4.4 |
| E | Clareza da informação | heading_path preserva hierarquia semântica, GlossaryTerm + USES_TERM desambiguam termos |
| F | Versionamento | DocumentFamily + VERSION_OF + SUPERSEDES + valid_from/valid_until |
| G | Rastreabilidade de origem | git_commit_hash, source_repo, path, git_branch, source_format, conversion_quality |
| H | Reprodutibilidade | embedding_model + embedding_version permitem saber exatamente como cada embedding foi gerado; git_commit_hash permite reconstruir o documento |

### 1.4. Requisitos do modelo

- **R1 — Busca semântica**: suportar vector index nos embeddings dos chunks para busca por similaridade (cosine similarity, >0.7 threshold)
- **R2 — Expansão por grafo**: a partir de um chunk encontrado, navegar o grafo para contexto relacionado (outros chunks do mesmo documento, documentos do mesmo sistema, ADRs que decidem sobre o módulo, etc.)
- **R3 — Filtros pré-retrieval**: filtrar por confidentiality, system, module, status, domain ANTES da busca vetorial
- **R4 — Temporalidade**: consultar "como era X na data Y?" usando valid_from/valid_until e cadeia SUPERSEDES
- **R5 — Rastreabilidade**: de qualquer chunk, rastrear até a fonte original (documento, repositório, commit, autor)
- **R6 — Governança**: owner, team, status, tags para filtros gerenciais
- **R7 — Glossário**: termos de negócio controlados vinculados aos documentos
- **R8 — Dependências**: relações DEPENDS_ON e IMPLEMENTS para análise de impacto

## 2. Decisão

Adotar modelo de grafo com **10 tipos de nó (labels)**, **13 tipos de relação**, constraints de unicidade, índices compostos e vector index. O modelo suporta versionamento temporal via DocumentFamily + relações SUPERSEDES/VERSION_OF com campos valid_from/valid_until.

### 2.1. Nós (Labels) — 10 Tipos

<!-- LOCKED:START autor=fabio data=2026-03-22 -->

| # | Label | Descrição | ID Único | Propriedades-chave |
|---|-------|-----------|----------|--------------------|
| 1 | **Document** | Arquivo .md ingerido na base vetorial. Nó central do grafo. Cada arquivo .md gera exatamente um nó Document. | `document_id` (DOC-NNNNNN) | title, doc_type, system, module, domain, owner, team, status, confidentiality, tags, path, source_repo, git_commit_hash, git_branch, valid_from, valid_until, superseded_by, conversion_quality, source_format, created_at, updated_at, chunk_count |
| 2 | **Chunk** | Fragmento semântico de um Document. Unidade atômica de busca vetorial. O embedding é gerado por chunk, não por documento. Um Document gera N chunks (tipicamente 3-20). | `chunk_id` ({document_id}_chunk_{NNN}) | content, embedding, embedding_model, embedding_version, token_count, chunk_index, heading_path, metadata_inherited, created_at |
| 3 | **System** | Sistema corporativo (software, plataforma, serviço). Nível mais alto de agrupamento organizacional do conhecimento. | `system_id` (SYS-XXX) | name, description, domain, status, created_at, updated_at |
| 4 | **Module** | Módulo funcional de um sistema. Subdivisão lógica (ex: Sistema de Cobrança → Módulo de Boleto, Módulo de Remessa). | `module_id` (MOD-XXX) | name, description, status, created_at, updated_at |
| 5 | **Owner** | Responsável por conteúdo, sistema ou módulo (pessoa ou service account). | `owner_id` | display_name, email, type (person/service-account), created_at |
| 6 | **Team** | Time, squad, chapter, diretoria ou área organizacional. Agrupa Owners. | `team_id` | name, type (squad/chapter/directorate/area), parent_team_id, created_at |
| 7 | **Task** | Tarefa de ferramenta de gestão (ClickUp, Jira, Azure DevOps). Vincula conhecimento a ações concretas. | `task_id` (CU-XXXX, JIRA-XXXX) | title, source_tool, status, url, created_at |
| 8 | **ADR** | Registro de Decisão Arquitetural. Double-labeling com Document (:ADR:Document). Tem relações semânticas próprias (DECIDES). | `adr_id` (ADR-NNN) | decision_status (proposed/accepted/deprecated/superseded), date_decided, deciders + todas propriedades de Document |
| 9 | **GlossaryTerm** | Termo de negócio controlado com definição oficial. Desambiguação e consistência terminológica. | `term_id` (TERM-XXX) | term, definition, synonyms, domain, created_at, updated_at |
| 10 | **DocumentFamily** | Agrupa todas as versões de um mesmo documento conceitual ao longo do tempo. Viabiliza consultas temporais. | `family_id` (FAM-XXX) | title, current_version_id, version_count, domain, created_at, updated_at |

<!-- LOCKED:END -->

**Nota sobre desnormalização:** o campo `metadata_inherited` no Chunk duplica dados do Document pai (system, module, domain, confidentiality). Isso é **intencional** — a busca vetorial com filtro precisa acessar o campo de filtro e o embedding no mesmo nó. Sem isso, toda busca vetorial precisaria de JOIN (Chunk→Document), degradando performance significativamente em vector indexes.

### 2.2. Relações — 13 Tipos

| # | Relação | Direção | Propriedades | Finalidade |
|---|---------|---------|-------------|------------|
| 1 | **PART_OF** | Chunk → Document | created_at | Vincula chunk ao documento de origem. Relação mais fundamental — sem ela, chunks são fragmentos órfãos |
| 2 | **BELONGS_TO** | Document → Module | role (primary/supplementary/reference), created_at | Vincula documento ao módulo funcional |
| 3 | **BELONGS_TO** | Module → System | created_at | Hierarquia organizacional (System → Modules → Documents) |
| 4 | **OWNED_BY** | Document → Owner | since, created_at | Responsabilidade e autoria. Todo documento tem um dono |
| 5 | **MEMBER_OF** | Owner → Team | role (lead/member/contributor), since, created_at | Estrutura organizacional. Viabiliza governança por grupo |
| 6 | **RELATES_TO_TASK** | Document → Task | relationship_type (documents/references/created_by), created_at | Conecta conhecimento a execução |
| 7 | **REFERENCES** | Document → Document | reference_type (wikilink/citation/see-also), context, created_at | Rede de conhecimento. Viabiliza expansão de contexto e análise de impacto |
| 8 | **USES_TERM** | Document → GlossaryTerm | frequency, created_at | Desambiguação terminológica. Expansão de busca por sinônimos |
| 9 | **DECIDES** | ADR → System | scope (architecture/infra/process/security), created_at | Rastreabilidade de decisões arquiteturais |
| 10 | **DEPENDS_ON** | Module → Module | dependency_type (runtime/build/data/api), strength (hard/soft), created_at | Análise de impacto e arquitetura |
| 11 | **IMPLEMENTS** | Task → Module | contribution_type (new-feature/bugfix/refactoring/documentation), created_at | Rastreabilidade de execução |
| 12 | **SUPERSEDES** | Document → Document | effective_date, reason, created_at | Versionamento temporal (cadeia linear: v2026 SUPERSEDES v2025 SUPERSEDES v2024) |
| 13 | **VERSION_OF** | Document → DocumentFamily | version_number, version_label, is_current, created_at | Agrupamento de versões (estrela: todas as versões conectadas a um ponto central) |

### 2.3. Constraints e Índices

#### 2.3.1. Constraints de unicidade

Todos os 10 tipos de nó possuem constraint de unicidade no seu identificador:

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

Exemplo de criação (Cypher como referência — sintaxe pode variar conforme a Base Vetorial adotada):

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
- **Dimensão**: 1536 (Trilha A) ou 1024 (Trilha B) — conforme [[ADR-002]]
- **Similaridade**: cosine
- Instâncias de trilhas diferentes **não podem** compartilhar o mesmo vector index (reforça a separação de instâncias definida na [[ADR-002]])

Exemplo de criação:

```cypher
-- Trilha A (OpenAI, 1536 dimensões)
CREATE VECTOR INDEX chunk_embedding_index FOR (c:Chunk)
ON (c.embedding)
OPTIONS {indexConfig: {
  `vector.dimensions`: 1536,
  `vector.similarity_function`: 'cosine'
}};

-- Trilha B (BGE-M3, 1024 dimensões)
CREATE VECTOR INDEX chunk_embedding_index FOR (c:Chunk)
ON (c.embedding)
OPTIONS {indexConfig: {
  `vector.dimensions`: 1024,
  `vector.similarity_function`: 'cosine'
}};
```

#### 2.3.3. Índices auxiliares

| # | Índice | Justificativa |
|---|--------|---------------|
| 1 | `Document.doc_type` | Filtro por tipo (ADRs, runbooks) |
| 2 | `Document.system` | Filtro de escopo por sistema |
| 3 | `Document.module` | Refinamento de escopo |
| 4 | `Document.confidentiality` | **Filtro crítico de segurança** — aplicado em toda busca |
| 5 | `Document.status` | Filtro draft/approved/deprecated |
| 6 | `Document.domain` | Filtro por área de negócio |
| 7 | `Document.path` | Lookup rápido por caminho de arquivo |
| 8 | `Document.valid_from` + `Document.valid_until` | Consultas temporais (composto) |
| 9 | `Chunk.metadata_inherited.confidentiality` | Filtro de segurança direto no chunk |
| 10 | `GlossaryTerm.term` | Lookup rápido por termo |
| FT-1 | `Document.title` (full-text) | Busca por título com parcial matching |
| FT-2 | `GlossaryTerm.term` + `GlossaryTerm.synonyms` (full-text) | Busca fuzzy por termos e sinônimos |

### 2.4. Estratégia de Chunking por Tipo de Documento

| doc_type | Estratégia | Faixa de tokens | Detalhes |
|----------|-----------|-----------------|----------|
| **system-doc** | Chunking por heading (H1, H2, H3) | 300-800 | Mesma base do architecture-doc. Seções de configuração/integração/operação são chunks separados mesmo se curtos, pois são consultados individualmente por diferentes personas (dev, ops, suporte) |
| **architecture-doc** | Chunking por heading (H1, H2, H3) | 300-800 | Cada heading inicia novo chunk. Excedentes >800 tokens subdivididos por parágrafo. <300 tokens agrupados com próximo heading. heading_path preservado como contexto |
| **adr** | Chunks menores e precisos por seção | 200-500 | Seções separadas: Contexto, Decisão, Alternativas (uma por alternativa), Consequências. Decisão nunca subdividida |
| **runbook** | Chunk por procedimento/passo | 200-600 | Cada procedimento = 1 chunk. Pré-requisitos e Troubleshooting em chunks separados. Passos individuais NÃO separados (procedimento com 5 passos = 1 chunk) |
| **glossary** | Chunk quase atômico por termo | 50-200 | Cada termo = 1 chunk (termo + definição + sinônimos + exemplo). Termos relacionados linkados via USES_TERM |
| **task-doc** | Chunk por contexto, escopo, decisão e aceite | 300-600 | Seções separadas: Contexto, Escopo/Requisitos, Decisões Técnicas (1 por decisão), Critérios de Aceite, Observações/Riscos |

### 2.5. Modelo Temporal — DocumentFamily + SUPERSEDES + VERSION_OF

O modelo temporal opera em três camadas (conforme [[ADR-001]] seção 2.6):

**Camada 1 — Front matter do .md:**

```yaml
---
valid_from: "2026-01-01"
valid_until: null               # null = vigente
superseded_by: "DOC-000456"     # ID do doc que substitui
supersedes: "DOC-000123"        # ID do doc anterior
---
```

**Camada 2 — Grafo (relações e nós):**

```
(:Document {document_id: "DOC-000789", valid_from: "2026-01-01"})
  -[:VERSION_OF {version_number: 3, is_current: true}]->
(:DocumentFamily {family_id: "FAM-POLITICA-PRIVACIDADE",
                  current_version_id: "DOC-000789"})

(:Document "DOC-000789")-[:SUPERSEDES]->(:Document "DOC-000456")
(:Document "DOC-000456")-[:SUPERSEDES]->(:Document "DOC-000123")
```

**Camada 3 — Retrieval (filtros temporais):**

- "Como era a Política de Privacidade em 2024?" → filtrar valid_from <= 2024 E valid_until >= 2024 (ou null)
- "Qual a Política de Privacidade atual?" → filtrar valid_until IS NULL
- Sem contexto temporal → assumir data atual (valid_until IS NULL)

### 2.6. Exemplos de Queries

**Nota sobre sintaxe:** os exemplos abaixo utilizam sintaxe Cypher como linguagem de referência. A sintaxe específica pode variar conforme a Base Vetorial adotada. O importante é o modelo (nós, propriedades, relações), não a sintaxe.

**Query 1 — Busca semântica com filtro de confidencialidade:**

```cypher
CALL db.index.vector.queryNodes(
  'chunk_embedding_index', 10, $query_embedding
) YIELD node AS chunk, score
WHERE chunk.metadata_inherited.confidentiality IN ['public', 'internal']
  AND score > 0.7
RETURN chunk.chunk_id, chunk.content, chunk.heading_path, score
ORDER BY score DESC;
```

**Query 2 — Expansão de contexto via grafo:**

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

**Query 4 — Análise de impacto:**

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

**Exemplo — Nó Document com todas as propriedades:**

```cypher
(:Document {
  document_id: "DOC-000123",
  title: "Módulo de Cobrança — Geração de Boletos",
  doc_type: "system-doc",
  system: "Sistema de Cobrança",
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

**Exemplo — Nó Chunk com embedding:**

```cypher
(:Chunk {
  chunk_id: "DOC-000123_chunk_003",
  content: "O módulo de geração de boletos utiliza o padrão CNAB 240...",
  embedding: [0.0123, -0.0456, 0.0789, ...],   // 1536 floats (Trilha A)
  embedding_model: "openai/text-embedding-3-small",
  embedding_version: "2026-01",
  token_count: 487,
  chunk_index: 2,
  heading_path: "Módulo de Cobrança > Geração de Boletos > Arquivo de Remessa",
  metadata_inherited: {
    system: "Sistema de Cobrança",
    module: "Boleto",
    domain: "Financeiro",
    confidentiality: "internal"
  },
  created_at: datetime("2026-01-15T10:30:05Z")
})
```

**Exemplo — DocumentFamily para versionamento temporal:**

```cypher
// Família
(:DocumentFamily {
  family_id: "FAM-POLITICA-PRIVACIDADE",
  title: "Política de Privacidade Corporativa",
  current_version_id: "DOC-000789",
  version_count: 3,
  domain: "Jurídico"
})

// Versão 1 (2024), Versão 2 (2025), Versão 3 (2026 — vigente)
// Cada uma conectada via VERSION_OF e cadeia SUPERSEDES
(:Document "DOC-000789")-[:SUPERSEDES]->(:Document "DOC-000456")
(:Document "DOC-000456")-[:SUPERSEDES]->(:Document "DOC-000123")
```

**Exemplo — ADR com double-labeling:**

```cypher
CREATE (a:ADR:Document {
  document_id: "DOC-000050",
  title: "Pipeline de Geração de Conhecimento em 4 Fases",
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

### 3.1. Modelo relacional (SQL) com extensão vetorial

- **Descrição**: PostgreSQL com pgvector para vetores + tabelas relacionais para metadados
- **Prós**: SQL amplamente conhecido; PostgreSQL robusto e maduro; pgvector suporta busca vetorial; menor curva de aprendizado
- **Rejeição**: não suporta traversal de grafo eficiente. Queries de expansão de contexto requerem 4+ JOINs em SQL, com performance degradada. Em grafo, é um MATCH com 4 hops em milissegundos. A expansão via grafo é o diferencial do GraphRAG

### 3.2. Dois bancos separados (SQL + Grafo)

- **Descrição**: PostgreSQL + pgvector para busca vetorial, banco de grafo separado para relações
- **Prós**: cada banco faz o que faz melhor
- **Rejeição**: duplicação de dados, sincronização entre bancos, latência de rede, complexidade operacional dobrada, transações distribuídas. Bases vetoriais modernas suportam vector index + graph traversal na mesma engine

### 3.3. Modelo sem DocumentFamily

- **Descrição**: versionamento apenas por cadeia SUPERSEDES, sem nó DocumentFamily
- **Prós**: modelo mais simples, menos nós e relações
- **Rejeição**: para encontrar todas as versões seria necessário navegar cadeia inteira (O(n) hops). Com DocumentFamily, uma única query resolve. Além disso, sem DocumentFamily não há local para current_version_id

### 3.4. Embedding no documento inteiro (sem chunks)

- **Descrição**: um único embedding por documento, sem chunking
- **Prós**: modelo mais simples, embedding captura contexto completo
- **Rejeição**: documentos longos (>2000 tokens) geram embeddings diluídos; janela de contexto do LLM desperdiçada com documentos inteiros; precisão de busca cai drasticamente

### 3.5. Chunking por tamanho fixo

- **Descrição**: ignorar estrutura do documento e chunkar por tamanho fixo (ex: 512 tokens)
- **Prós**: implementação trivial, chunks uniformes
- **Rejeição**: corta no meio de frases e conceitos, heading_path se perde, embedding resultante ruidoso. Chunking semântico por heading gera embeddings mais precisos (~10-20% maior precision@10 em benchmarks internos)

## 4. Consequências

### 4.1. Positivas

- **GraphRAG completo**: busca semântica + expansão de contexto na mesma engine
- **Governança nativa**: owner, team, status, confidentiality como propriedades diretas dos nós
- **Temporalidade**: DocumentFamily + SUPERSEDES + valid_from/valid_until para consultas históricas
- **Análise de impacto**: relações DEPENDS_ON, IMPLEMENTS, DECIDES para traversal em milissegundos
- **Desambiguação**: GlossaryTerm + USES_TERM para expansão de sinônimos
- **Rastreabilidade completa**: de qualquer chunk até arquivo original, commit, repositório, autor
- **Chunking otimizado**: estratégias diferenciadas por tipo de documento

### 4.2. Negativas / Trade-offs

- **Complexidade do modelo**: 10 tipos de nó e 13 relações exigem curva de aprendizado
- **Desnormalização**: metadata_inherited no Chunk duplica dados (risco de inconsistência se atualização não for atômica)
- **Custo de manutenção**: evolução do modelo requer migração cuidadosa em produção
- **Overhead de ingestão**: pipeline precisa criar nós de System, Module, Owner, Team, Task, GlossaryTerm além de Document e Chunk

### 4.3. Riscos e Mitigações

| Risco | Descrição | Mitigação |
|-------|-----------|-----------|
| Chunks órfãos | Na re-ingestão, chunks antigos podem não ser removidos se o pipeline falhar | Cleanup job que detecta chunks sem PART_OF e os remove |
| Inconsistência metadata_inherited | Document muda confidentiality mas chunks ficam com valor antigo | Na atualização de Document, SEMPRE propagar para chunks (upsert transacional) |
| DocumentFamily desatualizada | current_version_id aponta para versão errada | Atualizar atomicamente na mesma transação de criação de nova versão |
| Performance de vector index | Filtros pré-retrieval podem degradar performance | Índices compostos nos campos de filtro mais usados. Monitorar query plans |

### 4.4. Métricas de Observabilidade

| # | Métrica | Alerta se |
|---|---------|-----------|
| M1 | Total de nós por label | Queda >20% entre ingestões |
| M2 | Chunks órfãos (sem PART_OF) | > 0 |
| M3 | Documents sem OWNED_BY | > 0 |
| M4 | DocumentFamilies com current_version_id inválido | > 0 |
| M5 | Chunks com token_count fora da faixa (<100 ou >1000) | > 10% do total |
| M6 | Documents com chunk_count = 0 | > 0 |
| M7 | Tempo médio de query vetorial (p95) | > 500ms |
| M8 | Documents com status=draft na Base Vetorial | > 0 (não devem existir) |
| M9 | Inconsistência metadata_inherited vs. Document pai | > 0 |
| M10 | Embeddings com modelo diferente do vigente | > 0 (indica migração incompleta) |

## 5. Implementação

| Fase | Entrega | DOD |
|------|---------|-----|
| **MVP** | Document + Chunk + PART_OF + vector index + busca semântica simples | Constraints 1-2, vector index funcional, query com score >0.7, filtro por confidentiality |
| **Metadados** | + System, Module, Owner, Team + relações BELONGS_TO, OWNED_BY, MEMBER_OF | Constraints 3-10, índices 1-7, filtros pré-retrieval por system/module/status |
| **KG** | + Task, ADR, GlossaryTerm, DocumentFamily + todas relações restantes | 13 relações, expansão de contexto via grafo, análise de impacto |
| **GraphRAG** | + Retrieval híbrido, temporalidade, reranking, segurança por escopo | Consultas temporais, métricas M1-M10, benchmark de busca validado |

**Responsáveis:** Arquiteto (definição do modelo, constraints, índices, validação), Engenharia de Dados (implementação de constraints, índices, pipeline de ingestão), Engenharia de Software (queries de retrieval, expansão de contexto), Ops/DBA (monitoramento, métricas M1-M10, backup, performance tuning).

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

## 7. Referências

**Decisões relacionadas:**

- [[ADR-001]] — Pipeline de Geração de Conhecimento em 4 Fases (define as 4 fases cujos artefatos este modelo armazena)
- [[ADR-002]] — Soberania de Dados: Cloud vs. On-Premise (define as trilhas que impactam dimensão do embedding e instâncias)

**Documentos do blueprint:**

- B05 — Knowledge Graph (modelo de grafo original)
- B03 — Camada Ouro (pipeline de ingestão que cria estes nós)
- B04 — Metadados e Governança (front matter que popula as propriedades)

**Referências técnicas:**

- Vector Indexes na base vetorial: documentação oficial de índices vetoriais
- GraphRAG for Python: biblioteca oficial de GraphRAG
- Chunking Best Practices: "Chunk Wisely" — pesquisas sobre estratégias de chunking
- MTEB Benchmark: avaliação de modelos de embedding multilíngue

**Documentos relacionados:**

- Depende de: [[ADR-001]] (Pipeline 4 Fases), [[ADR-002]] (Soberania de Dados)
- Impacta: B03 (Camada Ouro), B04 (Metadados e Governança), B05 (Knowledge Graph)
- Relacionados: B14 (Segurança e Soberania), B15 (Governança), B16 (Roadmap de Implementação)

<!-- conversion_quality: 95 -->
