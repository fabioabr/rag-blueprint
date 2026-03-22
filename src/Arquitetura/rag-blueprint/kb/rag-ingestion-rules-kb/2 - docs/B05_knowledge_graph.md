---
id: RAG-B5
doc_type: architecture-doc
title: "Fase 3 — Knowledge Graph: Relações + Fontes Expandidas"
system: RAG Corporativo
module: Fase 3 — Knowledge Graph
domain: Arquitetura
owner: fabio
team: arquitetura
status: in-review
confidentiality: internal
tags: [rag, blueprint, fase3, knowledge-graph, relacoes, fontes, rbac]
aliases: ["Knowledge Graph", "Fase 3", "B05", "Grafo de Conhecimento"]
source_format: txt
source_repo: banco-patria
source_path: Arquitetura/rag-blueprint/1 - draft/B05_knowledge_graph.txt
conversion_pipeline: manual-v1
conversion_quality: 100
converted_at: 2026-03-18
created_at: 2026-03-18
updated_at: 2026-03-18
---

# 🕸️ Fase 3 — Knowledge Graph

**Relações + Fontes Expandidas**

| | |
|---|---|
| **Série** | RAG Blueprint Series |
| **Documento** | B5 — Fase 3 |
| **Data** | 17/03/2026 |
| **Versão** | 1.1 |

## 🎯 Objetivo da Fase 3

Transformar o índice vetorial em um Knowledge Graph real. Adicionar entidades, relações e expandir para fontes além de Git/Markdown. Esta fase evolui [[B04_metadados_governanca|B04 — Metadados e Governança]] e habilita [[B06_graphrag_maturidade|B06 — GraphRAG e Maturidade]].

> [!info] Fase 3
> Fase 3 do roadmap — ver [[B16_roadmap_implementacao]] para marcos e sequenciamento. Depende da conclusão das Fases 1 e 2.

#fase/3

- ✅ Nós: System, Module, Task, Owner, Team, GlossaryTerm, ADR
- ✅ Relações explícitas entre entidades
- ✅ Expansão de contexto via grafo (graph traversal)
- ✅ Fontes expandidas via modelo Bronze/Prata/Ouro
- ✅ Enriquecimento semântico para novas fontes
- ✅ RBAC + ABAC implementados

## 📌 3.1 — Modelo de Dados Expandido

Nós adicionados:

### :System

| Propriedade | |
|---|---|
| `system_id` | Identificador |
| `name` | Nome |
| `description` | Descrição |
| `status` | Status |

Representa um sistema corporativo (Sistema Exemplo, etc.)

### :Module

| Propriedade | |
|---|---|
| `module_id` | Identificador |
| `name` | Nome |
| `description` | Descrição |
| `system_id` | Vínculo ao sistema |

Módulo funcional de um sistema (Cobrança, Cadastro)

### :Owner

| Propriedade | |
|---|---|
| `owner_id` | Identificador |
| `name` | Nome |
| `email` | E-mail |
| `role` | Papel |

Responsável por conteúdo, sistema ou módulo

### :Team

| Propriedade | |
|---|---|
| `team_id` | Identificador |
| `name` | Nome |
| `type` | squad, chapter, diretoria |

Time, squad, chapter ou diretoria

### :Task

| Propriedade | |
|---|---|
| `task_id` | Identificador |
| `title` | Título |
| `external_id` | ID externo |
| `source` | ClickUp, Jira |

Tarefa de ferramentas externas

### :ADR

| Propriedade | |
|---|---|
| `adr_id` | Identificador |
| `title` | Título |
| `status` | Status |
| `decision_date` | Data da decisão |

Registro de decisão arquitetural

### :GlossaryTerm

| Propriedade | |
|---|---|
| `term_id` | Identificador |
| `term` | Termo |
| `definition` | Definição |
| `domain` | Domínio |

Termo de negócio controlado

## 📌 3.2 — Relações do Grafo

Relações entre entidades:

```
(:Chunk)-[:PART_OF]->(:Document)
(:Document)-[:BELONGS_TO]->(:Module)
(:Module)-[:BELONGS_TO]->(:System)
(:Document)-[:OWNED_BY]->(:Owner)
(:Owner)-[:MEMBER_OF]->(:Team)
(:Document)-[:RELATES_TO_TASK]->(:Task)
(:Document)-[:REFERENCES]->(:Document)
(:Document)-[:USES_TERM]->(:GlossaryTerm)
(:ADR)-[:DECIDES]->(:System)
(:Module)-[:DEPENDS_ON]->(:Module)
(:Task)-[:IMPLEMENTS]->(:Module)
```

Essas relações habilitam perguntas como:

> [!example] Perguntas habilitadas pelo Knowledge Graph
> - Quais ADRs impactam o módulo de Cobrança?
> - Quais documentos referenciam o Sistema Exemplo?
> - Quem é responsável pelos runbooks do módulo X?
> - Quais módulos dependem do módulo Y?
> - Qual tarefa originou esta documentação?

#fase/3 #camada/ouro

## 📌 3.3 — Fontes Expandidas (via modelo Bronze/Prata/Ouro)

Todas as fontes seguem o fluxo [[B01_camada_bronze|Bronze]]→[[B02_camada_prata|Prata]]→[[B03_camada_ouro|Ouro]] (ADR-001):

1. Arquivo original entra no repositório bronze
2. Pipeline de conversão gera .md na prata com campos de linhagem
3. Pipeline de ingestão existente processa o .md para Neo4j (ouro)

### Prioridade de expansão (alto valor + fácil ingestão)

**🥇 Primeira onda:**

- 🔸 PDFs de documentação técnica existente
- 🔸 Tickets de suporte resolvidos (com resolução documentada)
- 🔸 Documentação de APIs (Swagger/OpenAPI)

**🥈 Segunda onda:**

- 🔸 Políticas internas (Word/PDF)
- 🔸 Runbooks e playbooks fora do Git
- 🔸 ADRs em outros formatos

**🥉 Terceira onda (avaliar após estabilização):**

- 🔸 E-mails — valor alto mas complexidade enorme (ruído, LGPD)
- 🔸 Transcrições de reuniões — depende de qualidade do STT
- 🔸 Mensagens de Slack — muito ruído, requer curadoria pesada

> [!warning] Decisão pendente
> A priorização de fontes depende de [[B08_pendencias#✅ Pendencia 7 — Fontes Prioritarias para Expansao|P7 — Fontes Prioritárias]].

### Para cada nova fonte

- 🔸 Conector de captura para o repositório bronze
- 🔸 Parser dedicado no pipeline de conversão Bronze→Prata
- 🔸 Cálculo de `conversion_quality` específico para o formato
- 🔸 Enriquecimento semântico (classificação, NER, resumos)
- 🔸 Chunking adequado ao tipo de documento

## 📌 3.4 — Enriquecimento Semântico

Para fontes que NÃO possuem front matter (PDFs, tickets, etc.):

### Classificação automática

- 🔸 `doc_type` (inferido pelo conteúdo)
- 🔸 `system` / `module` (quando identificável)
- 🔸 `confidentiality` (por regras ou classificação por LLM)
- 🔸 `domain` / área de negócio

**Abordagem técnica:** LLM via API (Claude Haiku ou equivalente) com prompt estruturado e few-shot examples. Classificador baseado em LLM é preferível a modelo treinado nesta fase — mais flexível, sem necessidade de dataset rotulado. Se latência ou custo forem problema, considerar cache de classificações por doc_type + domínio.

### Extração de entidades (NER)

- 🔸 Pessoas, sistemas, módulos, termos de glossário

**Abordagem técnica:** duas opções conforme stack (ver [[B08_pendencias#✅ Pendência 4 — Linguagem e Stack do Pipeline|P4]]):
- **Python:** spaCy com modelo pt-BR (`pt_core_news_lg`) para NER genérica + dicionário customizado de termos corporativos (sistemas, módulos). Complementar com LLM para entidades complexas.
- **Alternativa stack-agnostica:** LLM com prompt de extração estruturada (JSON output) — mais caro por chamada, mas zero setup de modelo.

### Resumos automáticos

- 🔸 Resumo curto (1-2 frases) gerado por LLM

### Detecção de qualidade

- 🔸 Documentos com pouco conteúdo
- 🔸 Possíveis duplicatas
- 🔸 Documentos potencialmente desatualizados

## 📌 3.5 — Governança (RBAC + ABAC)

Implementação de controle de acesso real:

### ABAC (Attribute-Based Access Control)

- Baseado nos 4 níveis de `confidentiality` do documento: public, internal, restricted, confidential
- Filtro obrigatório pré-retrieval em toda busca — ver [[B14_seguranca_soberania_dados]]

> [!danger] Segurança
> Nunca confiar apenas em prompt para segurança. Filtros devem ser aplicados antes da busca vetorial. Ver [[B14_seguranca_soberania_dados]] para detalhes.

### RBAC (Role-Based Access Control)

Perfis de acesso por cargo/função:

- 🔸 **Analista** → public + internal
- 🔸 **Gestor** → public + internal + restricted
- 🔸 **Diretoria** → todos os níveis
- 🔸 **Agente de IA** → nível configurável por agente

**Integração com IdP corporativo:** o mapeamento usuário → perfil deve vir de um Identity Provider externo, não ser gerenciado manualmente na aplicação.
- **Fase 3 (MVP de RBAC):** JWT com claims de role/grupo emitido pelo IdP corporativo (OIDC/SAML). A API valida o token e extrai o perfil para filtrar `confidentiality`. Mapeamento simples: grupo AD/LDAP → perfil RAG.
- **Se IdP não estiver disponível:** tabela local de mapeamento (usuário → perfil) como fallback temporário — migrar para OIDC assim que possível.
- Ver [[B14_seguranca_soberania_dados]] para detalhes de autenticação por fase.

### Auditoria básica

- Registro de buscas realizadas (quem, quando, query, filtros aplicados)
- Registro de chunks retornados (IDs, scores)
- Granularidade: por query individual (não agregado)

## 📌 3.6 — Busca com Expansão por Grafo

Evolução da busca: vetorial + filtros + grafo

```
Pergunta do usuário
      ↓
Aplicar filtros de acesso (RBAC + ABAC)
      ↓
Vector search com filtros de metadados
      ↓
Para cada chunk retornado, expandir via grafo:
   → Chunk → Document → Module → System
   → Document → referências a outros Documents
   → Document → ADRs relacionados
   → Document → Tasks vinculadas
      ↓
Montar contexto expandido
      ↓
Enviar para LLM
```

## 📌 3.7 — Critérios de Conclusão da Fase 3

- ✅ Pelo menos 5 das 7 entidades do Knowledge Graph populadas
- ✅ Relações explícitas criadas e navegáveis
- ✅ Pelo menos 1 fonte não-.md integrada ao pipeline via Bronze→Prata→Ouro
- ✅ Enriquecimento semântico operando para novas fontes
- ✅ RBAC + ABAC implementados e aplicados nas buscas
- ✅ Auditoria básica de acessos operando
- ✅ Busca com expansão por grafo funcional

> [!tip] Ver também
> Os critérios de conclusão são detalhados em [[B12_testes_validacao_slas]] e medidos conforme [[B07_visao_consolidada|B07 — Visão Consolidada]].

---

## Documentos relacionados

### Depende de
- [[B04_metadados_governanca]] — front matter e filtros por metadados são pré-requisito para o grafo

### Evolui
- [[B04_metadados_governanca]] — adiciona entidades (System, Module, Owner, etc.) e relações ao modelo de metadados

### Habilita
- [[B06_graphrag_maturidade]] — grafo completo habilita retrieval híbrido com agentes por domínio

### Relacionados
- [[B01_camada_bronze]] — fontes expandidas seguem o modelo bronze
- [[B02_camada_prata]] — conversão de novas fontes para .md normalizado
- [[B03_camada_ouro]] — ingestão e indexação vetorial dos chunks
- [[B07_visao_consolidada]] — tabela mestre de evolução por fase
- [[B08_pendencias]] — P7 (fontes prioritárias) e P2 (backend Neo4j)
- [[B10_api_interface_acesso]] — grafo consumido pela camada de acesso
- [[B12_testes_validacao_slas]] — golden set e validação de qualidade do grafo
- [[B14_seguranca_soberania_dados]] — RBAC + ABAC implementados nesta fase
