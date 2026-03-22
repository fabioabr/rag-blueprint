---
id: RAG-B4
doc_type: architecture-doc
title: "Fase 2 — Metadados Fortes: Governança e Filtragem"
system: RAG Corporativo
module: Fase 2 — Metadados
domain: Arquitetura
owner: fabio
team: arquitetura
status: in-review
confidentiality: internal
tags: [rag, blueprint, fase2, metadados, governanca, filtragem]
aliases: ["Metadados Fortes", "Fase 2", "B04", "Governança e Filtragem"]
source_format: txt
source_repo: banco-patria
source_path: Arquitetura/rag-blueprint/1 - draft/B04_metadados_governanca.txt
conversion_pipeline: manual-v1
conversion_quality: 100
converted_at: 2026-03-18
created_at: 2026-03-18
updated_at: 2026-03-18
---

# 🏷️ Fase 2 — Metadados Fortes

**Governança e Filtragem**

| | |
|---|---|
| **Série** | RAG Blueprint Series |
| **Documento** | B4 — Fase 2 |
| **Data** | 17/03/2026 |
| **Versão** | 1.1 |

## 🎯 Objetivo da Fase 2

Adicionar governança, filtragem e rastreabilidade ao pipeline construído na [[B03_camada_ouro|Fase 1]]. Transformar a busca semântica pura em busca filtrada por metadados. Esta fase habilita [[B05_knowledge_graph|Fase 3 — Knowledge Graph]].

> [!info] Fase 2
> Fase 2 do roadmap — ver [[B16_roadmap_implementacao]] para marcos e sequenciamento.

#fase/2

- ✅ Front matter padronizado e validado em todos os .md
- ✅ Filtros pré-retrieval por sistema, módulo, confidencialidade
- ✅ Rastreio completo de commit e origem
- ✅ Métricas de qualidade da base

## 📌 2.1 — Incremento no Pipeline

O pipeline Prata→Ouro recebe as seguintes evoluções:

### Etapa P→O.2 (Parse) — melhorias

- 🔸 Validação rigorosa do front matter:
  - Todos os campos obrigatórios presentes
  - `doc_type` dentro dos valores válidos
  - `status` dentro dos valores válidos
  - `confidentiality` dentro dos valores válidos
- 🔸 Relatório de conformidade por repositório
- 🔸 Rejeição com log de documentos não-conformes

### Etapa P→O.5 (Persistência) — melhorias

- 🔸 Atualizar `document_id` apenas quando checksum muda
- 🔸 Manter histórico de ingestões (timestamp, commit_hash anterior)

### Etapa P→O.6 (Indexação) — melhorias

- 🔸 Índice composto para filtros frequentes:
  - `(system, module, confidentiality)`
- 🔸 Full-text index em `Document.title` e `Chunk.content` (preparação para keyword search)

### Etapa P→O.7 (Observabilidade) — melhorias

- 🔸 Documentos sem front matter válido (% de conformidade)
- 🔸 Distribuição de documentos por `doc_type`, `system`, `module`
- 🔸 Divergência entre Git e Neo4j (docs no Git que não estão no Neo4j)
- 🔸 Latência de retrieval (tempo da busca)

## 📌 2.2 — Busca Filtrada

Evolução da busca: vetorial + filtros por metadados

```
Pergunta do usuário
      ↓
Identificar filtros aplicáveis:
   → sistema, módulo, tipo de doc, confidencialidade
      ↓
Aplicar filtro de confidencialidade (P.6 — pré-retrieval)
      ↓
Vector search com filtros (WHERE doc.system = X AND ...)
      ↓
Retornar chunks + metadados
      ↓
Enviar para LLM com contexto filtrado
```

Cypher conceitual (com filtros):

```cypher
CALL db.index.vector.queryNodes('chunk_embedding_index', 20, $queryVector)
YIELD node AS chunk, score
MATCH (chunk)-[:PART_OF]->(doc:Document)
WHERE doc.confidentiality IN $allowedLevels
  AND doc.system = $targetSystem
RETURN chunk.content, chunk.heading_path, doc.title, score
ORDER BY score DESC
LIMIT 10
```

## 📌 2.3 — Modelo de Metadados Unificado

Definição do modelo de metadados que será usado em todas as fases:

### Campos obrigatórios (todo documento, toda fonte)

- 🔸 `id` — identificador único
- 🔸 `title` — título
- 🔸 `system` — sistema corporativo de origem
- 🔸 `doc_type` — tipo do documento
- 🔸 `author` / `owner` — responsável
- 🔸 `team` — equipe
- 🔸 `created_at` — data de criação
- 🔸 `updated_at` — última atualização
- 🔸 `status` — draft, in-review, approved, deprecated
- 🔸 `confidentiality` — public, internal, restricted, confidential
- 🔸 `tags` — tags livres

### Campos opcionais (quando aplicável)

- 🔸 `module` — módulo funcional
- 🔸 `domain` — domínio de negócio
- 🔸 `version` — versão do documento
- 🔸 `classification` — categoria da taxonomia
- 🔸 `clickup_task_id` — vínculo com tasks
- 🔸 `repo`, `branch`, `commit_hash`, `path`, `checksum` — rastreio Git
- 🔸 `valid_from`, `valid_until` — vigência temporal

## 📌 2.4 — Critérios de Conclusão da Fase 2

- ✅ 100% dos .md ingeridos possuem front matter válido (ou estão sinalizados)
- ✅ Busca filtrada por sistema + módulo + confidencialidade funcionando
- ✅ Métricas de conformidade e distribuição operando
- ✅ Modelo de metadados unificado documentado e aprovado
- ✅ Full-text index criado (preparação para keyword search)

> [!tip] Ver também
> Os critérios de conclusão são validados em [[B12_testes_validacao_slas]] e medidos conforme [[B07_visao_consolidada|B07 — Visão Consolidada]]. A taxonomia corporativa é definida em [[B08_pendencias#✅ Pendencia 9 — Taxonomia Corporativa|P9 — Taxonomia]].

---

## Documentos relacionados

### Depende de
- [[B03_camada_ouro]] — modelo de dados e pipeline são pré-requisito

### Evolui
- [[B03_camada_ouro]] — adiciona filtros e validação rigorosa ao pipeline existente

### Habilita
- [[B05_knowledge_graph]] — metadados validados habilitam o Knowledge Graph

### Relacionados
- [[B02_camada_prata]] — front matter gerado no pipeline de conversão
- [[B06_graphrag_maturidade]] — busca filtrada evolui para hybrid search
- [[B08_pendencias]] — P9 (taxonomia corporativa)
- [[B10_api_interface_acesso]] — filtros disponíveis na camada de acesso
- [[B14_seguranca_soberania_dados]] — confidencialidade como filtro pré-retrieval
