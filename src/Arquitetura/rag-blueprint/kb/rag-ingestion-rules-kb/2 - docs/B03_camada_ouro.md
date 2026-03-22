---
id: RAG-B03
doc_type: architecture-doc
title: "Camada Ouro — Pipeline de Ingestão Neo4j, Modelo de Dados e Busca"
system: RAG Corporativo
module: Camada Ouro
domain: Arquitetura
owner: fabio
team: arquitetura
status: in-review
confidentiality: internal
tags: [rag, blueprint, ouro, neo4j, ingestao, modelo-dados, busca]
aliases: ["Camada Ouro", "Ouro", "B03", "Pipeline de Ingestão", "Fase 1"]
source_format: txt
source_repo: banco-patria
source_path: Arquitetura/rag-blueprint/1 - draft/B03_camada_ouro.txt
conversion_pipeline: manual-v1
conversion_quality: 100
converted_at: 2026-03-18
created_at: 2026-03-18
updated_at: 2026-03-18
---

# 🥇 Camada Ouro — Pipeline de Ingestão Neo4j, Modelo de Dados e Busca

| | |
|---|---|
| 📂 Série | RAG Blueprint Series |
| 📌 Documento | B3 — Camada Ouro |
| 📅 Data | 17/03/2026 |
| 📋 Versão | 1.1 |

---

## 📌 O.1 — Pipeline de Ingestão Prata → Ouro (Neo4j)

7 etapas sequenciais. Este pipeline lê exclusivamente `.md` da [[B02_camada_prata|Camada Prata]]. A Camada Ouro é o coração da Fase 1 do [[B16_roadmap_implementacao|Roadmap]].

#camada/ouro #fase/1

### Etapa P→O.1 — Descoberta

- 🔸 Ler repositório prata (Git)
- 🔸 Identificar arquivos `.md` (excluir `node_modules`, `vendor`, etc.)
- 🔸 Para cada `.md` capturar:
  - `path` (caminho relativo no repo)
  - `repo` (nome do repositório)
  - `branch` (branch monitorada)
  - `commit_hash` (último commit que alterou o arquivo)
- 🔸 Comparar hash com versão indexada para detectar mudanças
- 🔸 Filtrar apenas arquivos novos ou alterados (P.7)

### Etapa P→O.2 — Parse

- 🔸 Extrair front matter YAML → metadados estruturados
- 🔸 Extrair headings (h1, h2, h3...) → estrutura do documento
- 🔸 Extrair links internos → referências entre documentos
- 🔸 Validar schema mínimo do front matter:
  - `id`, `doc_type`, `title` obrigatórios
  - Rejeitar/sinalizar documentos sem front matter válido
- 🔸 Calcular checksum do conteúdo

### Etapa P→O.3 — Chunking

- 🔸 Quebrar documento por headings (h1, h2, h3)
- 🔸 Cada chunk herda metadados do documento
- 🔸 Preservar `heading_path` (ex: "Módulo > Cobrança > Regras")
- 🔸 Faixa de tamanho: 300 a 800 tokens por chunk
- 🔸 Chunks muito grandes: subdividir por parágrafos
- 🔸 Chunks muito pequenos: agrupar seções consecutivas

**Estratégia por tipo de documento:**

| Tipo | Estratégia de chunking |
|------|----------------------|
| ADR | chunks menores e precisos |
| Runbook | chunk por procedimento/passo operacional |
| Documento arquitetural | chunk por módulo/fluxo/decisão |
| Glossário | chunk quase atômico por termo |
| Documento de task | chunk por contexto/escopo/aceite |

> 🚫 **NUNCA** indexar o `.md` inteiro como uma única entrada vetorial

### Etapa P→O.4 — Embeddings

- 🔸 Gerar embedding (vetor numérico) para cada chunk
- 🔸 Registrar modelo e versão do embedding utilizado
- 🔸 Armazenar o vetor no campo `embedding` do Chunk

> [!warning] Decisão pendente — Modelo de embedding
> Duas trilhas conforme política de dados (ver [[B08_pendencias#✅ Pendência 1 — Modelo de Embedding|P1 — Modelo de Embedding]]):
> - **Trilha A (cloud):** OpenAI text-embedding-3-small (1536 dims) — melhor custo-benefício
> - **Trilha B (on-prem):** BGE-M3 (BAAI) via sentence-transformers — dados não saem do domínio
>
> Recomendação para MVP: começar com o modelo da trilha escolhida e reavaliar em Fase 2.

### Etapa P→O.5 — Persistência

- 🔸 Upsert de Document no Neo4j:
  - Se `document_id` existe: atualizar campos alterados
  - Se `document_id` não existe: criar novo nó
- 🔸 Upsert de Chunks:
  - Remover chunks antigos do documento alterado
  - Criar novos chunks com embeddings
- 🔸 Criar relação `(:Chunk)-[:PART_OF]->(:Document)`
- 🔸 Remover chunks órfãos (documento removido do repo prata)
- 🔸 Remover Documents cujo arquivo não existe mais na prata

**Campos de linhagem preservados no nó Document:**

- `source_format`, `source_repo`, `source_path`
- `conversion_quality` (0-100%)

### Etapa P→O.6 — Indexação

- 🔸 Garantir vector index em `Chunk.embedding`
- 🔸 Criar/manter índices auxiliares para filtros:
  - `Document.path`
  - `Document.doc_type`
  - `Document.system`
  - `Document.module`
  - `Document.confidentiality`
- 🔸 Constraints de unicidade:
  - `Document.document_id` UNIQUE
  - `Chunk.chunk_id` UNIQUE

### Etapa P→O.7 — Observabilidade

Métricas do pipeline Prata→Ouro:

- 🔸 Documentos ingeridos por execução
- 🔸 Chunks gerados por execução
- 🔸 Falhas de parse (front matter inválido, encoding, etc.)
- 🔸 Latência de geração de embeddings
- 🔸 Total de documentos e chunks no Neo4j
- 🔸 Documentos por `source_format`
- 🔸 Distribuição de `conversion_quality`

---

## 📌 O.2 — Modelo de Dados no Neo4j

### :Document

| Campo | Tipo | Restrição | Descrição |
|-------|------|-----------|-----------|
| `document_id` | STRING | UNIQUE | = id do front matter |
| `repo` | STRING | | nome do repositório |
| `branch` | STRING | | branch monitorada |
| `commit_hash` | STRING | | último commit |
| `path` | STRING | INDEX | caminho no repo |
| `title` | STRING | | título do documento |
| `doc_type` | STRING | INDEX | system-doc, adr, etc. |
| `status` | STRING | | draft, approved, etc. |
| `system` | STRING | INDEX | sistema corporativo |
| `module` | STRING | INDEX | módulo funcional |
| `domain` | STRING | | domínio de negócio |
| `owner` | STRING | | responsável |
| `team` | STRING | | equipe |
| `confidentiality` | STRING | INDEX | public, internal, etc. |
| `tags` | STRING[] | | tags livres |
| `created_at` | DATE | | data de criação |
| `updated_at` | DATE | | última atualização |
| `checksum` | STRING | | hash do conteúdo |
| **— Campos de linhagem —** | | | **todo documento passa pelo bronze** |
| `source_format` | STRING | | md, pdf, docx, etc. |
| `source_repo` | STRING | | repo bronze de origem |
| `source_path` | STRING | | caminho no bronze |
| `source_hash` | STRING | | checksum do original |
| `conv_pipeline` | STRING | | versão do pipeline |
| `conv_quality` | FLOAT | | 0-100%, confiança |
| `converted_at` | DATE | | data da conversão |

### Relação: `(:Chunk)-[:PART_OF]->(:Document)`

### :Chunk

| Campo | Tipo | Restrição | Descrição |
|-------|------|-----------|-----------|
| `chunk_id` | STRING | UNIQUE | document_id + "_" + seq |
| `document_id` | STRING | | referência ao Document |
| `seq` | INTEGER | | posição no documento |
| `heading` | STRING | | título da seção |
| `heading_path` | STRING | | caminho: "H1 > H2 > H3" |
| `content` | STRING | | texto do chunk |
| `token_count` | INTEGER | | contagem de tokens |
| `embedding` | FLOAT[] | | vetor do embedding |
| `embedding_model` | STRING | | modelo utilizado |
| `confidentiality` | STRING | | herdado do Document |
| `updated_at` | DATE | | data de processamento |

---

## 📌 O.3 — Busca Semântica

### Fluxo de busca vetorial simples

```
Pergunta do usuário
      ↓
Gerar embedding da pergunta (mesmo modelo dos chunks)
      ↓
Vector search no Neo4j (Top-K chunks por similaridade)
      ↓
Retornar chunks + metadados do Document pai
      ↓
(Opcionalmente) enviar para LLM com contexto
```

### Cypher conceitual

```cypher
CALL db.index.vector.queryNodes('chunk_embedding_index', 10, $queryVector)
YIELD node AS chunk, score
MATCH (chunk)-[:PART_OF]->(doc:Document)
RETURN chunk.content, chunk.heading_path, doc.title, doc.system, score
ORDER BY score DESC
```

> [!tip] Ver também
> A busca evolui nas fases seguintes: [[B04_metadados_governanca|Fase 2]] adiciona filtros por metadados, [[B05_knowledge_graph|Fase 3]] adiciona expansão por grafo, e [[B06_graphrag_maturidade|Fase 4]] adiciona reranking e agentes.

---

## Documentos relacionados

### Depende de
- [[B02_camada_prata]] — fornece os `.md` normalizados para ingestão

### Habilita
- [[B04_metadados_governanca]] — Fase 2: filtros e governança sobre o modelo de dados
- [[B10_api_interface_acesso]] — camada de acesso consome o Neo4j

### Relacionados
- [[B00_introducao]] — define o modelo Bronze/Prata/Ouro (ADR-001)
- [[B01_camada_bronze]] — origem das fontes
- [[B05_knowledge_graph]] — Fase 3: expande o modelo com entidades e relações
- [[B08_pendencias]] — P1 (embedding) e P2 (backend Neo4j)
- [[B11_deployment_infraestrutura]] — containeriza Neo4j e pipeline de ingestão
- [[B12_testes_validacao_slas]] — golden set e validação de qualidade da busca
