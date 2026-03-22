---
id: RAG-B16
doc_type: architecture-doc
title: "Roadmap de Implementação — Sequência, Dependências e Marcos"
system: RAG Corporativo
module: Roadmap
domain: Arquitetura
owner: fabio
team: arquitetura
status: in-review
confidentiality: internal
tags: [rag, blueprint, roadmap, marcos, dependencias, timeline, implementacao]
aliases: ["Roadmap", "B16", "Implementação", "Marcos"]
source_format: txt
source_repo: banco-patria
source_path: Arquitetura/rag-blueprint/1 - draft/B16_roadmap_implementacao.txt
conversion_pipeline: manual-v1
conversion_quality: 100
converted_at: 2026-03-18
created_at: 2026-03-18
updated_at: 2026-03-18
---

# 🗺️ Roadmap de Implementação

**Sequência Sugerida, Dependências e Marcos de Evolução**

- 📂 **Série:** RAG Blueprint Series
- 📌 **Documento:** B16 — Roadmap de Implementação
- 📅 **Data:** 18/03/2026
- 📋 **Versão:** 1.0
- 🔗 **Base:** Todos os documentos da série ([[B00_introducao|B00]]–[[B15_governanca_capacidade_rollback|B15]])

---

## 🎯 Objetivo

Os documentos B00-B15 descrevem capacidades de forma temática: camadas de dados, modelo de grafo, API, segurança, operações, etc.

Este documento responde à pergunta:

> 👉 "Em que ORDEM implementar tudo isso?"

Ele define um roadmap em 4 marcos de evolução, mostrando quais documentos (e quais seções de cada documento) são ativados em cada marco, quais são os pré-requisitos e quais são as entregas esperadas.

**Princípio:** evolução incremental — cada marco entrega valor e serve de fundação para o próximo.

---

## 📌 16.1 — Mapa de Dependências entre Documentos

Nem todos os documentos são independentes. Alguns só fazem sentido depois que outros estão implementados.

**Legenda:** A → B significa "A é pré-requisito de B"

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│  B01 (Bronze) ──→ B02 (Prata) ──→ B03 (Ouro)                     │
│       │                │                │                           │
│       │                │                ├──→ B04 (Metadados)       │
│       │                │                ├──→ B05 (Knowledge Graph) │
│       │                │                └──→ B06 (GraphRAG)        │
│       │                │                                            │
│       │                │           B03 ──→ B10 (API)               │
│       │                │                     │                      │
│       │                │                     ├──→ B06 (Agentes)    │
│       │                │                     └──→ MCP Server       │
│       │                │                                            │
│       └────────────────┴──→ B11 (Deploy)                           │
│                                                                     │
│  B08 (Pendências) ──→ Decisões bloqueantes antes do Marco 1       │
│                                                                     │
│  B12 (Testes) ──→ Acompanha todos os marcos                        │
│  B13 (Operações) ──→ Cresce com cada marco                        │
│  B14 (Segurança) ──→ Checklist por marco                          │
│  B15 (Governança) ──→ RACI desde o Marco 1                        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Documentos TRANSVERSAIS** (acompanham todos os marcos):

- 🔸 **[[B07_visao_consolidada|B07]]** — Visão Consolidada (tabela de referência rápida)
- 🔸 **[[B08_pendencias|B08]]** — Pendências (decisões que desbloqueiam marcos)
- 🔸 **[[B09_referencias|B09]]** — Referências
- 🔸 **[[B12_testes_validacao_slas|B12]]** — Testes (golden set cresce a cada marco)
- 🔸 **[[B13_operacoes|B13]]** — Operações (controles incrementais)
- 🔸 **[[B14_seguranca_soberania_dados|B14]]** — Segurança (checklist por marco)
- 🔸 **[[B15_governanca_capacidade_rollback|B15]]** — Governança (papéis e capacidade)

---

## 📌 16.2 — Marco 1: MVP — Busca Semântica Funcional

🎯 **Objetivo:** provar que o pipeline funciona de ponta a ponta. Um repositório, busca vetorial simples, resultado via API.

### Entregas do Marco 1

- 🔸 **Repositório bronze configurado ([[B01_camada_bronze|B01]])**
  - Estrutura de pastas definida
  - Git LFS ativo para binários
  - Primeiros documentos (.md, PDF, DOCX) capturados

- 🔸 **Pipeline Bronze→Prata operando ([[B02_camada_prata|B02]])**
  - Parsers para MD, PDF e DOCX funcionais
  - Front matter gerado automaticamente
  - Conversion quality calculado
  - Repositório prata com primeiros .md normalizados

- 🔸 **Pipeline Prata→Ouro operando ([[B03_camada_ouro|B03]])**
  - 7 etapas implementadas (descoberta → observabilidade)
  - Modelo de dados: Document + Chunk no Neo4j
  - Embeddings gerados e indexados
  - Busca vetorial simples retornando resultados

- 🔸 **API mínima ([[B10_api_interface_acesso|B10]], §10.2)**
  - Endpoint POST /v1/search funcional
  - Endpoint GET /v1/health funcional
  - Autenticação por API Key

- 🔸 **Infraestrutura básica ([[B11_deployment_infraestrutura|B11]])**
  - Docker Compose com Neo4j + API + pipelines
  - Variáveis de ambiente configuradas
  - Trigger manual (CLI) para ingestão

- 🔸 **Testes mínimos ([[B12_testes_validacao_slas|B12]], §12.1-12.3)**
  - Testes unitários dos parsers
  - Testes de chunking
  - Golden set inicial (20 perguntas)

- 🔸 **Segurança mínima ([[B14_seguranca_soberania_dados|B14]], §14.12 — Checklist Fase 1)**
  - Neo4j com autenticação, não exposto
  - API com autenticação
  - Filtro de confidencialidade server-side
  - Secrets em .env fora do Git

- 🔸 **Governança inicial ([[B15_governanca_capacidade_rollback|B15]])**
  - Papéis definidos (mesmo que 1 pessoa acumule)
  - Rollback manual documentado
  - Sizing inicial calculado

### Pré-requisitos (decisões bloqueantes do [[B08_pendencias|B08]])

- ✅ Pendência 1 — Modelo de embedding definido
- ✅ Pendência 2 — Backend (Neo4j) confirmado
- ✅ Pendência 3 — Infra Neo4j provisionada
- ✅ Pendência 4 — Stack/linguagem escolhida
- ✅ Pendência 5 — Repositório alvo definido

### Critério de conclusão

- ✅ Busca vetorial retornando chunks relevantes via API
- ✅ Golden set com Recall@10 >= 70%
- ✅ Pipeline executável de ponta a ponta sem intervenção manual

---

## 📌 16.3 — Marco 2: Metadados e Governança

🎯 **Objetivo:** transformar a busca simples em busca inteligente com filtros por metadados. Adicionar governança e rastreabilidade.

### Entregas do Marco 2

- 🔸 **Metadados fortes ([[B04_metadados_governanca|B04]])**
  - Validação rigorosa do front matter
  - Relatório de conformidade por repositório
  - Busca filtrada por sistema + módulo + confidencialidade
  - Full-text index criado (preparação para keyword search)
  - Modelo de metadados unificado e documentado

- 🔸 **Pipeline Bronze→Prata ampliado ([[B02_camada_prata|B02]])**
  - Validação mais rigorosa na conversão
  - Threshold de quality refinado com dados reais

- 🔸 **Pipeline Prata→Ouro evoluído ([[B03_camada_ouro|B03]] + [[B04_metadados_governanca|B04]])**
  - Parse com validação rigorosa do front matter
  - Índice composto para filtros frequentes
  - Histórico de ingestões mantido

- 🔸 **API com filtros ([[B10_api_interface_acesso|B10]])**
  - POST /v1/search com filtros de metadados
  - Rate limiting por API key

- 🔸 **Infraestrutura ([[B11_deployment_infraestrutura|B11]])**
  - HTTPS na API
  - Cron job para ingestão diária

- 🔸 **Testes ampliados ([[B12_testes_validacao_slas|B12]])**
  - Golden set: 50 perguntas (com filtros)
  - Testes de carga básicos
  - SLAs medidos e publicados

- 🔸 **Operações ([[B13_operacoes|B13]])**
  - Backup Neo4j automatizado (cron diário)
  - Retry com backoff nos pipelines
  - Status no front matter (ciclo de vida básico)

- 🔸 **Segurança ([[B14_seguranca_soberania_dados|B14]], §14.12 — Checklist Fase 2)**
  - TLS no Bolt
  - Sanitização de input
  - Full disk encryption
  - Rotação de credenciais (90 dias)

- 🔸 **Governança ([[B15_governanca_capacidade_rollback|B15]])**
  - Papéis RACI formalizados em documento
  - Rollback granular (por documento)
  - Monitoramento de uso real (capacity)

- 🔸 **Decisões pendentes resolvidas ([[B08_pendencias|B08]])**
  - Pendência 9 — Taxonomia corporativa
  - Pendência 10 — Landing zone
  - Pendência 12 — Observabilidade

### Pré-requisitos

- ✅ Marco 1 concluído e estável
- ✅ Pelo menos 50 documentos ingeridos com sucesso
- ✅ Golden set com Recall@10 >= 70%

### Critério de conclusão

- ✅ 100% dos .md ingeridos com front matter válido (ou sinalizados)
- ✅ Busca filtrada funcional
- ✅ Golden set com Recall@10 >= 80%
- ✅ Métricas de conformidade publicadas

---

## 📌 16.4 — Marco 3: Knowledge Graph

🎯 **Objetivo:** transformar o índice vetorial em um grafo de conhecimento real. Expandir fontes e adicionar segurança real.

### Entregas do Marco 3

- 🔸 **Knowledge Graph ([[B05_knowledge_graph|B05]])**
  - Nós System, Module, Owner, Team, Task, ADR, GlossaryTerm
  - 11 relações explícitas criadas e navegáveis
  - Busca com expansão por grafo funcional

- 🔸 **Fontes expandidas ([[B05_knowledge_graph|B05]], §5.3)**
  - Pelo menos 1 fonte não-.md integrada (PDF ou tickets)
  - Pipeline Bronze→Prata com parser dedicado
  - Enriquecimento semântico (NER, classificação)

- 🔸 **Governança de acesso real ([[B05_knowledge_graph|B05]], §5.5 + [[B14_seguranca_soberania_dados|B14]])**
  - RBAC + ABAC implementados
  - JWT via Identity Provider corporativo
  - Auditoria completa de acessos

- 🔸 **API completa ([[B10_api_interface_acesso|B10]])**
  - POST /v1/ask (busca + geração LLM)
  - POST /v1/feedback (retroalimentação)
  - MCP Server básico

- 🔸 **Decisões pendentes resolvidas ([[B08_pendencias|B08]])**
  - Pendência 6 — LLM para geração de respostas
  - Pendência 7 — Fontes prioritárias mapeadas

- 🔸 **Testes ([[B12_testes_validacao_slas|B12]])**
  - Golden set: 100 perguntas (com grafo)
  - Testes de integração com RBAC

- 🔸 **Operações ([[B13_operacoes|B13]])**
  - Dead letter queue implementada
  - Re-indexação blue/green
  - Detecção de obsolescência
  - Glossário com curador definido

- 🔸 **Segurança ([[B14_seguranca_soberania_dados|B14]], §14.12 — Checklist Fase 3)**
  - Secret manager (Vault ou equivalente)
  - Container hardening
  - Anonimização no pipeline (se dados pessoais)
  - Dependency scanning
  - Dashboard de segurança

- 🔸 **Governança ([[B15_governanca_capacidade_rollback|B15]])**
  - Papéis RACI publicados e com treinamento
  - Rollback automatizado com auditoria
  - Projeção de crescimento publicada

### Pré-requisitos

- ✅ Marco 2 concluído e estável
- ✅ Pelo menos 200 documentos na base
- ✅ Golden set com Recall@10 >= 80%
- ✅ LLM para geração definido (Pendência 6)

### Critério de conclusão

- ✅ Pelo menos 5 dos 7 tipos de entidade populados
- ✅ Relações explícitas navegáveis
- ✅ Pelo menos 1 fonte não-.md integrada
- ✅ RBAC + ABAC operando
- ✅ Golden set com Recall@10 >= 85%

---

## 📌 16.5 — Marco 4: GraphRAG Corporativo

🎯 **Objetivo:** maturidade plena. Hybrid search, agentes por domínio, retroalimentação contínua e curadoria ativa.

### Entregas do Marco 4

- 🔸 **GraphRAG completo ([[B06_graphrag_maturidade|B06]])**
  - Hybrid search: vector + keyword + graph (em paralelo)
  - Reranking implementado
  - Query rewriting / expansion / decomposition

- 🔸 **Agentes especializados ([[B06_graphrag_maturidade|B06]], §6.2)**
  - Pelo menos 2 agentes por domínio operando
  - System prompts especializados
  - Filtros pré-configurados por agente
  - Métricas individuais por agente

- 🔸 **Retroalimentação ([[B06_graphrag_maturidade|B06]], §6.3)**
  - Feedback loop capturando avaliações
  - Detecção de lacunas na base
  - Curadoria contínua (automática + humana + assistida por IA)
  - Métricas de saúde da base publicadas

- 🔸 **Todas as fontes prioritárias integradas ([[B08_pendencias|B08]], Pendência 7)**
  - PDFs, tickets, APIs documentadas
  - Pipeline Bronze→Prata para todos os formatos

- 🔸 **API e consumo ([[B10_api_interface_acesso|B10]])**
  - Endpoints admin (/stats, /audit)
  - MCP Server completo
  - Avaliar interface de chat

- 🔸 **Decisões pendentes resolvidas ([[B08_pendencias|B08]])**
  - Pendência 8 — Modelo de reranking
  - Pendência 11 — Chunking hierárquico (avaliar necessidade)
  - Pendência 13 — Multi-tenant (se necessário)

- 🔸 **Testes ([[B12_testes_validacao_slas|B12]])**
  - Golden set: 200+ perguntas (com agentes)
  - Testes de carga completos
  - SLAs enforced

- 🔸 **Operações ([[B13_operacoes|B13]])**
  - Ingestão contínua (webhooks, cron, eventos)
  - Alertas formais (integração com alerting)
  - Auto-deprecation de documentos obsoletos
  - Glossário com NER automático

- 🔸 **Segurança ([[B14_seguranca_soberania_dados|B14]], §14.12 — Checklist Fase 4)**
  - Pen test realizado
  - DPIA concluído
  - Plano de resposta a incidentes testado
  - Anti-exfiltração operando

- 🔸 **Governança ([[B15_governanca_capacidade_rollback|B15]])**
  - RACI revisado trimestralmente
  - Capacity planning com auto-scaling
  - Cadência completa de curadoria

### Pré-requisitos

- ✅ Marco 3 concluído e estável
- ✅ Pelo menos 500 documentos na base
- ✅ Golden set com Recall@10 >= 85%
- ✅ Reranking definido (Pendência 8)

### Critério de conclusão

- ✅ Hybrid search funcional
- ✅ Pelo menos 2 agentes especializados operando
- ✅ Feedback loop capturando avaliações
- ✅ Dashboard de métricas de saúde publicado
- ✅ Todas as fontes prioritárias integradas
- ✅ Auditoria completa de acessos e respostas

---

## 📌 16.6 — Visão de Timeline

Cada organização terá velocidades diferentes. Esta seção apresenta uma estimativa ILUSTRATIVA para uma equipe de 2-3 pessoas.

| Marco | Foco Principal | Duração Estimada | Docs Base |
|-------|---------------|------------------|-----------|
| Marco 1 — MVP | Pipeline + busca vetorial | 4-6 sem | B01, B02, B03, B10, B11 |
| Marco 2 — Metadados | Metadados + governança | 3-4 sem | B04, B12, B13 |
| Marco 3 — KG | Knowledge Graph + RBAC + fontes expandidas | 6-8 sem | B05, B14 |
| Marco 4 — GraphRAG | Hybrid search + agentes + retroalimentação | 6-8 sem | B06, B15 |

**Total estimado:** ~5-6 meses para os 4 marcos.

⚠️ **Estimativas são ILUSTRATIVAS.** Fatores que aceleram:

- 🔸 Equipe maior
- 🔸 Documentação já em .md com front matter
- 🔸 Decisões de stack já tomadas
- 🔸 Infra já disponível

⚠️ **Fatores que atrasam:**

- 🔸 Muitas fontes em formatos diversos (PDFs complexos, OCR)
- 🔸 Necessidade de infra on-premise com GPU
- 🔸 Processo de aprovação longo (compliance, BACEN)
- 🔸 Documentação inexistente (precisa criar antes de ingerir)

---

## 📌 16.7 — Diagrama de Fluxo: Como Tudo se Conecta

Visão de como os 17 documentos (B00-B16) se relacionam:

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│  B00 (Introdução)                                                   │
│    └─→ Define premissas, princípios e modelo Bronze/Prata/Ouro     │
│                                                                     │
│  B01 (Bronze) → B02 (Prata) → B03 (Ouro)                          │
│    └─→ Pipeline de dados: captura → normalização → Neo4j           │
│                                                                     │
│  B04 (Metadados) ← depende de B03                                  │
│    └─→ Adiciona governança de metadados sobre o pipeline           │
│                                                                     │
│  B05 (Knowledge Graph) ← depende de B03 + B04                     │
│    └─→ Expande o modelo de dados com entidades e relações          │
│                                                                     │
│  B06 (GraphRAG) ← depende de B05 + B10                            │
│    └─→ Busca híbrida, agentes, retroalimentação                    │
│                                                                     │
│  B10 (API) ← depende de B03                                        │
│    └─→ Camada de acesso para consumidores                          │
│                                                                     │
│  ────────── DOCUMENTOS TRANSVERSAIS ──────────                     │
│                                                                     │
│  B07 (Visão Consolidada)                                            │
│    └─→ Tabela mestra — referência rápida de todas as capacidades   │
│                                                                     │
│  B08 (Pendências)                                                   │
│    └─→ Decisões que desbloqueiam marcos                            │
│                                                                     │
│  B09 (Referências)                                                  │
│    └─→ Histórico e fontes externas                                 │
│                                                                     │
│  B11 (Deploy) — onde tudo roda                                     │
│  B12 (Testes) — como saber que funciona                            │
│  B13 (Operações) — como manter rodando                             │
│  B14 (Segurança) — como proteger                                   │
│  B15 (Governança) — quem faz o quê                                 │
│  B16 (Roadmap) — em que ordem fazer (este documento)               │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📌 16.8 — Decisões Bloqueantes por Marco

Quais decisões do B08 devem ser tomadas ANTES de cada marco:

| Marco | Decisões Necessárias (B08) |
|-------|---------------------------|
| **Marco 1 — MVP** | ✅ P1 — Modelo de embedding |
| | ✅ P2 — Backend (Neo4j) |
| | ✅ P3 — Infra Neo4j |
| | ✅ P4 — Stack/linguagem |
| | ✅ P5 — Repositório alvo |
| | 👉 DECISÃO MACRO: Trilha A (cloud) ou B (on-prem)? Resolve P1, P3, P6 e P8 de uma vez. |
| **Marco 2 — Metadados** | ✅ P9 — Taxonomia corporativa |
| | ✅ P10 — Landing zone |
| | ✅ P12 — Observabilidade |
| **Marco 3 — KG** | ✅ P6 — LLM para geração de respostas |
| | ✅ P7 — Fontes prioritárias mapeadas |
| **Marco 4 — GraphRAG** | ✅ P8 — Modelo de reranking |
| | ⏸️ P11 — Chunking hierárquico (avaliar) |
| | ⏸️ P13 — Multi-tenant (se necessário) |

---

## 📌 16.9 — Checklist Resumido por Marco

### ✅ Marco 1 — MVP

- [ ] Decisões bloqueantes tomadas (P1-P5)
- [ ] Repo bronze com primeiros documentos
- [ ] Pipeline Bronze→Prata: MD + PDF + DOCX
- [ ] Pipeline Prata→Ouro: 7 etapas operando
- [ ] Neo4j com Document + Chunk + embeddings
- [ ] API /v1/search + /v1/health
- [ ] Docker Compose funcional
- [ ] Golden set 20 perguntas, Recall@10 >= 70%
- [ ] Checklist segurança Fase 1 completo
- [ ] Papéis RACI definidos

### ✅ Marco 2 — Metadados e Governança

- [ ] Front matter validado em 100% dos docs
- [ ] Busca filtrada (sistema + módulo + confidencialidade)
- [ ] Full-text index criado
- [ ] HTTPS na API + cron de ingestão
- [ ] Backup Neo4j automatizado
- [ ] Golden set 50 perguntas, Recall@10 >= 80%
- [ ] Checklist segurança Fase 2 completo
- [ ] RACI formalizado + rollback granular

### ✅ Marco 3 — Knowledge Graph

- [ ] 5+ tipos de entidade no grafo
- [ ] 11 relações navegáveis
- [ ] 1+ fonte não-.md integrada
- [ ] RBAC + ABAC + JWT operando
- [ ] API /v1/ask + /v1/feedback + MCP básico
- [ ] Dead letter + re-indexação blue/green
- [ ] Golden set 100 perguntas, Recall@10 >= 85%
- [ ] Checklist segurança Fase 3 completo
- [ ] Glossário com curador

### ✅ Marco 4 — GraphRAG Corporativo

- [ ] Hybrid search (vector + keyword + graph)
- [ ] Reranking implementado
- [ ] 2+ agentes especializados operando
- [ ] Feedback loop + curadoria contínua
- [ ] Todas as fontes prioritárias integradas
- [ ] MCP completo + endpoints admin
- [ ] Golden set 200+ perguntas
- [ ] Pen test + DPIA + resposta a incidentes testada
- [ ] Cadência completa de curadoria

---

## Documentos relacionados

### Depende de
- Todos os documentos anteriores ([[B00_introducao|B00]]–[[B15_governanca_capacidade_rollback|B15]]) — este documento consolida a sequência de implementação de todas as capacidades da série

### Habilita
- (nenhum — B16 é o último documento da série)

### Relacionados
- [[B00_introducao]] — premissas, princípios e modelo de camadas
- [[B01_camada_bronze]] — captura de fontes originais
- [[B02_camada_prata]] — normalização e conversão
- [[B03_camada_ouro]] — Neo4j, embeddings, pipeline 7 etapas
- [[B04_metadados_governanca]] — metadados e governança de front matter
- [[B05_knowledge_graph]] — entidades e relações
- [[B06_graphrag_maturidade]] — busca híbrida, agentes, retroalimentação
- [[B07_visao_consolidada]] — tabela mestra de capacidades
- [[B08_pendencias]] — decisões bloqueantes por marco
- [[B09_referencias]] — histórico e fontes externas
- [[B10_api_interface_acesso]] — API e interface de acesso
- [[B11_deployment_infraestrutura]] — deployment e infraestrutura
- [[B12_testes_validacao_slas]] — testes, validação e SLAs
- [[B13_operacoes]] — monitoramento, ciclo de vida
- [[B14_seguranca_soberania_dados]] — segurança e soberania de dados
- [[B15_governanca_capacidade_rollback]] — papéis RACI, capacidade e rollback
