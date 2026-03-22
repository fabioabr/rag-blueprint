---
id: RAG-B12
doc_type: architecture-doc
title: "Testes, Validação e SLAs"
system: RAG Corporativo
module: Testes e SLAs
domain: Arquitetura
owner: fabio
team: arquitetura
status: in-review
confidentiality: internal
tags: [rag, blueprint, testes, validacao, sla, golden-set, qualidade]
aliases: ["Testes", "Validação", "SLAs", "B12"]
source_format: txt
source_repo: banco-patria
source_path: Arquitetura/rag-blueprint/1 - draft/B12_testes_validacao_slas.txt
conversion_pipeline: manual-v1
conversion_quality: 100
converted_at: 2026-03-18
created_at: 2026-03-18
updated_at: 2026-03-18
---

# ✅ Testes, Validação e SLAs

**Como Saber que o Pipeline Funciona Corretamente**

- 📂 Série: RAG Blueprint Series
- 📌 Documento: B12 — Testes, Validação e SLAs
- 📅 Data: 18/03/2026
- 📋 Versão: 1.0
- 🔗 Base: [[B02_camada_prata|B02 — Pipeline Bronze→Prata]], [[B03_camada_ouro|B03 — Pipeline Prata→Ouro]], [[B10_api_interface_acesso|B10 — API]]

## 🎯 Objetivo

Definir como validar cada etapa do RAG: da conversão de fontes até a qualidade das respostas. Estabelecer metas de performance (SLAs) para cada componente.

> [!info] Escopo transversal
> Este documento acompanha **todas as fases** do rollout. O golden set de testes cresce de 20 perguntas (Fase 1) a 200+ (Fase 4), validando cada nova capacidade introduzida pelos demais módulos.

## 📌 12.1 — Testes do Pipeline Bronze→Prata

### 🔹 Testes unitários dos parsers

Para cada formato suportado ([[B01_camada_bronze|B01]], §B.2), um conjunto de fixtures:

| Formato | Fixture | Validação |
|---------|---------|-----------|
| MD | .md com front matter | Front matter preservado |
| MD | .md sem front matter | Front matter gerado |
| PDF | PDF com texto selecionável | Texto extraído ~100% |
| PDF | PDF escaneado (OCR) | Texto extraído > 70% |
| PDF | PDF com tabelas | Tabelas → Markdown |
| DOCX | DOCX com headings | Headings preservados |
| DOCX | DOCX com tabelas | Tabelas → Markdown |
| XLSX | Planilha simples | Dados extraídos |
| XLSX | Planilha com merge cells | Dados extraídos (warn) |
| EML | E-mail com corpo texto | Headers + corpo ok |
| EML | E-mail com anexo | Anexo processado |
| JSON | Export ClickUp/Jira | Campos extraídos |

### 🔹 Testes de qualidade de conversão

- 🔸 Para cada fixture: comparar .md gerado com expected output
- 🔸 Validar conversion_quality calculado (está coerente?)
- 🔸 Validar campos de linhagem (source_format, source_hash, etc.)
- 🔸 Validar threshold: quality >= 80% → in-review, < 30% → rejeitado

### 🔹 Testes de idempotência

> [!tip] Idempotência como requisito fundamental
> A idempotência garante que re-execuções do pipeline não geram efeitos colaterais. Isso é essencial para rollbacks seguros (ver [[B15_governanca_capacidade_rollback|B15 — Governança e Rollback]]).

- 🔸 Executar pipeline 2x sobre o mesmo bronze
- 🔸 Resultado: 0 arquivos alterados na segunda execução
- 🔸 Nenhum commit duplicado no repo prata

## 📌 12.2 — Testes do Pipeline Prata→Ouro

> [!info] Referência
> Os testes desta seção validam o pipeline descrito em [[B03_camada_ouro|B03 — Camada Ouro]], incluindo parse, chunking, embedding e persistência no grafo.

### 🔹 Testes de parse e validação

- 🔸 .md com front matter válido → Document criado no Neo4j
- 🔸 .md com front matter inválido → rejeitado com log
- 🔸 .md sem front matter → rejeitado com log
- 🔸 Campos obrigatórios ausentes → sinalizado no relatório

### 🔹 Testes de chunking

- 🔸 Documento com múltiplos headings → chunks separados por heading
- 🔸 Seção muito longa (> 800 tokens) → subdividida
- 🔸 Seção muito curta (< 300 tokens) → agrupada com adjacente
- 🔸 Cada chunk herda heading_path correto
- 🔸 Token count registrado e dentro da faixa

### 🔹 Testes de embedding

- 🔸 Embedding gerado → vetor com dimensão correta (conforme modelo escolhido — ver [[B08_pendencias#✅ Pendência 1 — Modelo de Embedding|P1]])
- 🔸 Embedding não é vetor zero
- 🔸 Chunks similares → embeddings com alta similaridade cosseno
- 🔸 Chunks de domínios diferentes → baixa similaridade

### 🔹 Testes de persistência

- 🔸 Novo documento → nó Document criado + Chunks + relação PART_OF
- 🔸 Documento alterado → nó atualizado, chunks antigos removidos, novos criados
- 🔸 Documento removido do repo → nó e chunks removidos do Neo4j
- 🔸 Reexecução → nenhuma alteração (idempotência)

### 🔹 Testes de integridade do grafo

> [!tip] Queries Cypher de validação
> Estes testes podem ser implementados como queries Cypher agendadas (ver [[B13_operacoes|B13 — Operações]]) que alimentam dashboards de saúde do grafo.

- 🔸 Todo Chunk tem exatamente 1 relação PART_OF para 1 Document
- 🔸 Nenhum Chunk órfão (sem Document pai)
- 🔸 Nenhum Document com 0 Chunks
- 🔸 Constraints de unicidade respeitadas (document_id, chunk_id)

## 📌 12.3 — Testes de Retrieval

### 🔹 Golden set de perguntas e respostas

Manter um conjunto de perguntas com respostas esperadas:

| Pergunta | Chunks Esperados |
|----------|-----------------|
| "Como funciona o módulo de cobrança?" | DOC-000123_003, DOC-000123_004 |
| "Qual a política de confidencialidade de dados?" | DOC-000045_001 |
| "Quais ADRs impactam o Sistema Exemplo?" | ADR-001, ADR-003 |

- 🔸 Mínimo 20 perguntas no golden set
- 🔸 Cobrir diferentes domínios, doc_types e níveis de dificuldade
- 🔸 Atualizar conforme a base cresce

### 🔹 Métricas de qualidade de retrieval

- 🔸 **Recall@K** — dos chunks esperados, quantos aparecem no top-K?
  - Meta por fase: Recall@10 >= 70% (Fase 1), >= 80% (Fase 2), >= 85% (Fase 3-4)
- 🔸 **Precision@K** — dos K chunks retornados, quantos são relevantes?
  - Meta: Precision@10 >= 60%
- 🔸 **MRR** (Mean Reciprocal Rank) — posição média do primeiro chunk relevante
  - Meta: MRR >= 0.7
- 🔸 Execução: rodar golden set após cada mudança de embedding, chunking ou modelo de reranking

### 🔹 Testes de filtro de acesso

> [!info] Segurança como pré-requisito
> Os filtros de acesso são aplicados **pré-retrieval**, conforme definido em [[B14_seguranca_soberania_dados|B14 — Segurança e Soberania de Dados]]. Estes testes garantem que nenhum chunk confidencial vaze para usuários sem permissão.

- 🔸 Usuário com role "analyst" → NÃO vê chunks restricted/confidential
- 🔸 Usuário com role "director" → vê tudo
- 🔸 Agente com nível configurado → respeita limite
- 🔸 Query sem autenticação → rejeitada (401)

## 📌 12.4 — Testes da API

> [!info] Referência de endpoints
> Os endpoints testados aqui estão definidos em [[B10_api_interface_acesso|B10 — API e Interface de Acesso]]. O contrato OpenAPI é a fonte de verdade para schemas de request/response.

### 🔹 Testes funcionais

- 🔸 `POST /v1/search` com query válida → 200 + resultados
- 🔸 `POST /v1/search` sem autenticação → 401
- 🔸 `POST /v1/search` com filtro inválido → 422
- 🔸 `POST /v1/ask` com query → 200 + resposta com citações
- 🔸 `POST /v1/feedback` com query_id válido → 200
- 🔸 `GET /v1/health` → 200 + status dos serviços

### 🔹 Testes de carga (Fase 2+)

> [!tip] Ambiente de carga
> Os testes de carga devem ser executados no ambiente de staging descrito em [[B11_deployment_infraestrutura|B11 — Deployment e Infraestrutura]], nunca diretamente em produção.

- 🔸 Ferramenta: locust ou k6
- 🔸 Cenário: N usuários simultâneos fazendo buscas
- 🔸 Validar: latência se mantém dentro dos SLAs sob carga

### 🔹 Testes de contrato

- 🔸 Response schema validado contra OpenAPI spec
- 🔸 Garantir que mudanças na API não quebram consumidores

## 📌 12.5 — SLAs (Service Level Agreements)

Metas de performance por componente:

| Componente | Métrica | Meta |
|------------|---------|------|
| Pipeline Bronze→Prata | Tempo por doc | < 30s (PDF/DOCX), < 5s (MD) |
| Pipeline Bronze→Prata | Taxa de sucesso | >= 95% |
| Pipeline Prata→Ouro | Tempo por doc | < 10s (incl. embed) |
| Pipeline Prata→Ouro | Taxa de sucesso | >= 99% |
| Pipeline Prata→Ouro | Full sync | < 30 min (1000 docs) |
| API /v1/search | Latência p50 | < 200ms |
| API /v1/search | Latência p95 | < 500ms |
| API /v1/search | Latência p99 | < 1000ms |
| API /v1/ask (com geração LLM) | Latência p50 | < 3s (inclui LLM) |
| API /v1/ask (com geração LLM) | Latência p95 | < 8s |
| Retrieval quality | Recall@10 | >= 70% (Fase 1), >= 80% (Fase 2), >= 85% (Fase 3-4) |
| Retrieval quality | Precision@10 | >= 60% |
| Retrieval quality | MRR | >= 0.7 |
| Disponibilidade (Fase 2+) | API uptime | >= 99% (mensal) |
| Disponibilidade (Fase 2+) | Neo4j uptime | >= 99.5% (mensal) |

**Notas:**

- 🔸 SLAs da Fase 1 são indicativos (não há enforcement formal)
- 🔸 A partir da Fase 2, medir e publicar métricas no dashboard HTML
- 🔸 Latência do /v1/ask depende do LLM escolhido (cloud vs. local)
- 🔸 Se SLA de busca for violado → investigar: volume de chunks, complexidade dos filtros, performance do Neo4j

> [!tip] Dashboard de SLAs
> A partir da Fase 2, publicar métricas de SLA no dashboard de [[B13_operacoes|B13 — Operações]] para visibilidade contínua. Violações devem gerar alertas automáticos.

## 📌 12.6 — Estratégia de Execução de Testes

| Quando | O que Rodar |
|--------|-------------|
| A cada commit no pipeline | Testes unitários dos parsers, Testes de chunking, Testes de persistência |
| A cada deploy da API | Testes funcionais da API, Testes de contrato |
| Semanal (ou após mudança de embedding/chunking) | Golden set de retrieval, Métricas de qualidade (Recall, Precision, MRR) |
| Mensal | Testes de carga, Revisão de SLAs vs. métricas reais |

**Ferramentas de teste (conforme stack escolhida):**

- 🔸 a) Python: pytest + httpx (API) + locust (carga)
- 🔸 b) .NET: xUnit/NUnit + HttpClient + NBomber (carga)
- 🔸 c) Node.js: Jest/Vitest + supertest (API) + k6 (carga)
- 🔸 d) Agnóstico: k6 (carga), Postman/Newman (API contracts)

## 📌 12.7 — Evolução por Fase

| Capacidade | Fase 1 | Fase 2 | Fase 3 | Fase 4 |
|------------|--------|--------|--------|--------|
| Testes unitários | Parsers + chunk | + valid. front mt | + NER + enriq. | Todos |
| Testes integr. | Pipeline end-to-e | + filtros | + grafo + RBAC | + hybrid + rerank |
| Golden set | 20 perg. | 50 perg. + filtros | 100 perg. + grafo | 200+ + agents |
| Testes de carga | — | Básico | Médio | Completo |
| SLAs | Indicat. | Medidos | Publicad. | Enforced |

> [!info] Segurança
> Incluir testes de filtro de acesso por `confidentiality` e validação de RBAC no golden set. Consultar checklist de segurança da fase correspondente em [[B14_seguranca_soberania_dados]].

## Documentos relacionados

### Depende de

- [[B02_camada_prata|B02 — Camada Prata]] — Pipeline Bronze→Prata, front matter, conversão de formatos
- [[B03_camada_ouro|B03 — Camada Ouro]] — Pipeline Prata→Ouro, persistência no grafo, embeddings
- [[B10_api_interface_acesso|B10 — API e Interface de Acesso]] — Endpoints testados, contrato OpenAPI
- [[B11_deployment_infraestrutura|B11 — Deployment e Infraestrutura]] — Ambiente de testes, CI/CD, staging

### Habilita

- [[B13_operacoes|B13 — Operações]] — Monitoramento contínuo, alertas baseados em SLAs
- [[B15_governanca_capacidade_rollback|B15 — Governança, Capacidade e Rollback]] — Compliance, auditoria de qualidade

### Relacionados

- [[B00_introducao|B00 — Introdução]] — Visão geral das fases e roadmap
- [[B01_camada_bronze|B01 — Camada Bronze]] — Fontes e formatos de fixture para testes de parser
- [[B04_metadados_governanca|B04 — Metadados e Governança]] — Validação de front matter obrigatório
- [[B05_knowledge_graph|B05 — Knowledge Graph]] — Testes de integridade do grafo (Fase 3)
- [[B06_graphrag_maturidade|B06 — GraphRAG e Maturidade]] — Métricas de retrieval, reranking (Fase 4)
- [[B07_visao_consolidada|B07 — Visão Consolidada]] — Acompanhamento cross-fase
- [[B08_pendencias|B08 — Pendências]] — Backlog de melhorias em testes
- [[B09_referencias|B09 — Referências]] — Ferramentas e benchmarks de qualidade
- [[B14_seguranca_soberania_dados|B14 — Segurança e Soberania de Dados]] — Testes de filtro de acesso e RBAC
