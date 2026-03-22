---
id: RAG-B6
doc_type: architecture-doc
title: "Fase 4 — GraphRAG Corporativo: Maturidade Completa"
system: RAG Corporativo
module: Fase 4 — GraphRAG
domain: Arquitetura
owner: fabio
team: arquitetura
status: in-review
confidentiality: internal
tags: [rag, blueprint, fase4, graphrag, hybrid-search, agentes, retroalimentacao]
aliases: ["GraphRAG", "Fase 4", "B06", "Maturidade Completa", "Hybrid Search"]
source_format: txt
source_repo: banco-patria
source_path: Arquitetura/rag-blueprint/1 - draft/B06_graphrag_maturidade.txt
conversion_pipeline: manual-v1
conversion_quality: 100
converted_at: 2026-03-18
created_at: 2026-03-18
updated_at: 2026-03-18
---

# 🧠 Fase 4 — GraphRAG Corporativo

**Maturidade Completa**

| | |
|---|---|
| **Série** | RAG Blueprint Series |
| **Documento** | B6 — Fase 4 |
| **Data** | 17/03/2026 |
| **Versão** | 1.1 |

## 🎯 Objetivo da Fase 4

Atingir maturidade plena do RAG corporativo: retrieval híbrido completo, agentes especializados, retroalimentação contínua e curadoria ativa. Esta fase evolui [[B05_knowledge_graph|Fase 3 — Knowledge Graph]] e representa o estado final da arquitetura.

> [!info] Fase 4
> Fase 4 (final) do roadmap — ver [[B16_roadmap_implementacao]] para marcos e sequenciamento.

#fase/4

- ✅ Hybrid search (vector + keyword + graph)
- ✅ Reranking inteligente
- ✅ Segurança por escopo (multi-tenant quando necessário)
- ✅ Agentes especializados por domínio
- ✅ Retroalimentação e curadoria contínua
- ✅ Métricas de saúde da base
- ✅ Todas as fontes prioritárias integradas

## 📌 4.1 — Hybrid Search

Três tipos de busca executados em paralelo:

```
Pergunta do usuário
      ↓
Pré-processamento da query:
   🔸 Reformulação (query rewriting)
   🔸 Expansão (query expansion — variações da pergunta)
   🔸 Decomposição (query decomposition — subperguntas)
      ↓
Execução paralela:
   ┌─────────────────────────────────────────────┐
   │  🔸 7.1 Vector Search                       │
   │     Embedding da pergunta vs chunks          │
   │     → resultados semânticos                  │
   ├─────────────────────────────────────────────┤
   │  🔸 7.2 Keyword Search                      │
   │     Full-text search por termos exatos       │
   │     → nomes, códigos, siglas, SKUs           │
   ├─────────────────────────────────────────────┤
   │  🔸 7.3 Graph Search                        │
   │     Navegação por relações no grafo          │
   │     → contexto relacional expandido          │
   └─────────────────────────────────────────────┘
      ↓
Fusão de resultados:
   🔸 Algoritmo: Reciprocal Rank Fusion (RRF)
   🔸 Combina rankings das 3 buscas sem necessidade de normalizar scores
   🔸 Fórmula: score(d) = Σ 1/(k + rank_i(d)), onde k=60 (padrão)
   🔸 Simples, robusto, padrão da indústria (usado por Elasticsearch, etc.)
      ↓
Reranking (modelo cross-encoder — ver [[B08_pendencias#✅ Pendência 8 — Modelo de Reranking|P8]])
      ↓
Top-K chunks mais relevantes
      ↓
Filtragem por permissões (RBAC + ABAC)
      ↓
Construção do prompt:
   system prompt + chunks rankeados + metadados + pergunta
      ↓
Envio para LLM
      ↓
Resposta com citação de fontes (document_id, title, path)
      ↓
Registro de auditoria + captura de feedback
```

## 📌 4.2 — Agentes Especializados por Domínio

**Roteamento:** um dispatcher classifica a pergunta e encaminha para o agente adequado:
- **Estratégia recomendada:** LLM classifica a intenção da query (ex: "pergunta técnica sobre arquitetura" → Agente de Arquitetura). Classificação leve com LLM rápido (Haiku/GPT-4o-mini) ou regras simples baseadas em keywords/domínio.
- **Fallback:** se a classificação for ambígua, executar busca em todos os agentes e fundir resultados via RRF.

Cada agente opera sobre um subconjunto do conhecimento:

### 🤖 Agente de Arquitetura

- **Filtro:** `doc_type IN [architecture-doc, adr, system-doc]`
- **Expande via:** System, Module, DEPENDS_ON
- **Público:** desenvolvedores, tech leads

### 🤖 Agente Operacional

- **Filtro:** `doc_type IN [runbook, glossary]`
- **Expande via:** Module, Task
- **Público:** operação, SRE, suporte

### 🤖 Agente de Negócio

- **Filtro:** `domain = 'Financeiro'` (ou outro domínio)
- **Expande via:** Owner, Team, GlossaryTerm
- **Público:** gestores, analistas

### Configuração por agente

Cada agente possui:

- 🔸 System prompt especializado
- 🔸 Filtros pré-configurados
- 🔸 Nível de confidencialidade máximo configurável
- 🔸 Métricas de uso individuais

## 📌 4.3 — Retroalimentação e Curadoria Contínua

### Ingestão contínua

- 🔸 Triggers automáticos: novo commit, novo documento, ticket resolvido
- 🔸 Frequência por tipo:
  - Real-time: commits no Git (webhook)
  - Diário: tickets resolvidos, e-mails
  - Semanal: PDFs e documentos não-versionados
  - Sob demanda: manuais, políticas
- 🔸 Detecção de mudanças por checksum/hash (P.7)

### Feedback loop

- 🔸 Respostas sem resultado → sinalizar lacuna na base
- 🔸 Respostas avaliadas negativamente → revisar parsing/chunking
- 🔸 Perguntas frequentes → priorizar curadoria dessas áreas
- 🔸 Detecção de alucinações → expandir conhecimento

### Ciclo de vida do conhecimento

- 🔸 Criação → Vigência → Revisão → Obsolescência → Descarte
- 🔸 Documentos deprecated removidos do índice ativo
- 🔸 Preservados no bronze para auditoria

### Curadoria

- 🔸 **Automática:** duplicatas, expirados, re-embedding, reclassificação
- 🔸 **Humana:** docs sensíveis, conflitos entre documentos, remoções
- 🔸 **Assistida por IA:** LLM sugere ações, humano aprova

### Métricas de saúde da base

- 🔸 Idade média dos documentos indexados
- 🔸 Miss rate (% de perguntas sem chunks relevantes)
- 🔸 Taxa de feedback negativo
- 🔸 Cobertura por área/departamento/sistema
- 🔸 Volume de documentos obsoletos no índice
- 🔸 Frequência de ingestão efetiva
- 🔸 Divergência entre fontes e Neo4j

## 📌 4.4 — Segurança Multi-Tenant (se necessário)

Se o RAG atender múltiplas unidades de negócio ou contextos:

- 🔸 `tenant_id` — identificador do tenant
- 🔸 `business_unit` — unidade de negócio
- 🔸 `data_scope` — escopo de dados visível

Filtro obrigatório em toda busca:

```cypher
WHERE doc.tenant_id = $currentTenant
  AND doc.confidentiality IN $allowedLevels
```

## 📌 4.5 — Critérios de Conclusão da Fase 4

- ✅ Hybrid search (vector + keyword + graph) funcional
- ✅ Reranking implementado e melhorando precisão
- ✅ Pelo menos 2 agentes especializados operando
- ✅ Feedback loop capturando avaliações de usuários
- ✅ Curadoria contínua operando (automática + humana)
- ✅ Dashboard de métricas de saúde da base
- ✅ Todas as fontes prioritárias integradas
- ✅ Auditoria completa de acessos e respostas

> [!warning] Decisões pendentes
> O modelo de reranking depende de [[B08_pendencias#✅ Pendencia 8 — Modelo de Reranking|P8 — Reranking]] e o LLM de [[B08_pendencias#✅ Pendencia 6 — LLM para Geracao de Respostas|P6 — LLM]].

---

## Documentos relacionados

### Depende de
- [[B05_knowledge_graph]] — grafo completo é pré-requisito

### Evolui
- [[B05_knowledge_graph]] — adiciona hybrid search, reranking e agentes

### Habilita
- [[B10_api_interface_acesso]] — agentes consomem a API de acesso

### Relacionados
- [[B03_camada_ouro]] — busca vetorial base (Fase 1)
- [[B07_visao_consolidada]] — tabela mestre de evolução por fase
- [[B08_pendencias]] — P6 (LLM) e P8 (reranking)
- [[B12_testes_validacao_slas]] — golden set para validar hybrid search
- [[B13_operacoes]] — retroalimentação e curadoria contínua
- [[B14_seguranca_soberania_dados]] — RBAC + ABAC + multi-tenant
- [[B15_governanca_capacidade_rollback]] — rollback e capacidade
