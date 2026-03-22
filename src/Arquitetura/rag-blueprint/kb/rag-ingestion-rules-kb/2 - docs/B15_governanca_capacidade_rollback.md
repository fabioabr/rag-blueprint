---
id: RAG-B15
doc_type: architecture-doc
title: "Governança, Capacidade e Rollback"
system: RAG Corporativo
module: Governança
domain: Arquitetura
owner: fabio
team: arquitetura
status: in-review
confidentiality: internal
tags: [rag, blueprint, governanca, raci, rollback, capacidade, curadoria]
aliases: ["Governança", "Rollback", "B15", "Capacidade"]
source_format: txt
source_repo: banco-patria
source_path: Arquitetura/rag-blueprint/1 - draft/B15_governanca_capacidade_rollback.txt
conversion_pipeline: manual-v1
conversion_quality: 100
converted_at: 2026-03-18
created_at: 2026-03-18
updated_at: 2026-03-18
---

# 🏛️ Governança, Capacidade e Rollback

**Papéis, Responsabilidades, Projeção de Crescimento e Reversão**

- 📂 Série: RAG Blueprint Series
- 📌 Documento: B15 — Governança, Capacidade e Rollback
- 📅 Data: 18/03/2026
- 📋 Versão: 1.0
- 🔗 Base: [[B03_camada_ouro|B03 (Ouro)]], [[B06_graphrag_maturidade|B06 (Retroalimentação)]], [[B08_pendencias|B08 (Pendências)]], [[B13_operacoes|B13 (Operações)]]

## 🎯 Objetivo

Definir quem é responsável por cada aspecto do RAG corporativo (RACI), como reverter ingestões incorretas (rollback granular) e como planejar o crescimento da base de conhecimento (capacity planning).

## 📌 15.1 — Papéis do RAG Corporativo

O RAG não é um sistema que "roda sozinho". Mesmo automatizado, precisa de pessoas com responsabilidades claras.

### 🔹 Papéis definidos

| Papel | Responsabilidade |
|-------|-----------------|
| **Arquiteto do RAG** | Decisões de arquitetura e evolução. Definir fases e critérios de transição. Aprovar mudanças no modelo de dados. Aprovar mudanças em modelo de embedding |
| **Curador de conhecimento** | Qualidade do conteúdo na prata. Aprovar documentos (draft → approved). Deprecar documentos obsoletos. Manter glossário atualizado. Revisar documentos com baixo quality |
| **Engenheiro de dados / Pipeline** | Pipeline Bronze→Prata→Ouro. Manter parsers e conectores. Monitorar ingestão e corrigir falhas. Implementar novos formatos |
| **Desenvolvedor da API / Consumo** | API de retrieval e MCP Server. Integração com consumidores. Manter endpoints e contratos |
| **Operações / Infra** | Servidores, Docker, Neo4j, backups. Monitoramento e alertas. Rotação de credenciais. Disaster recovery |
| **Owner do documento** (campo owner no front matter) | Responsável pelo conteúdo de um doc. Aprovar/deprecar seu próprio documento. Responder a candidatos de obsolescência |
| **Compliance / Segurança** | Validar conformidade (LGPD, BACEN). Aprovar classificação de documentos. Revisar acessos e auditoria. Aprovar inclusão de dados sensíveis |

> [!warning] Fase 1 (MVP)
> Na Fase 1, uma pessoa pode acumular vários papéis. Conforme o RAG amadurece, os papéis devem ser separados.

## 📌 15.2 — Matriz RACI

- **R** = Responsável (executa)
- **A** = Accountable (aprova / responde)
- **C** = Consultado
- **I** = Informado

### Decisões Arquiteturais

| Atividade | Arquit. RAG | Curad. Conhec. | Eng. Pipeline | Dev API | Ops Infra | Compl. Segur. |
|-----------|:-----------:|:--------------:|:-------------:|:-------:|:---------:|:-------------:|
| Definir modelo de dados | A | C | R | C | I | I |
| Escolher embedding model | A | I | R | I | C | C |
| Definir stack tecnológica | A | I | C | C | C | I |
| Evoluir de fase (1→2→3→4) | A | C | C | C | C | C |
| Aprovar ADRs | A | C | R | C | I | I |

### Curadoria de Conteúdo

| Atividade | Arquit. RAG | Curad. Conhec. | Eng. Pipeline | Dev API | Ops Infra | Compl. Segur. |
|-----------|:-----------:|:--------------:|:-------------:|:-------:|:---------:|:-------------:|
| Aprovar doc (→ approved) | I | A | I | I | I | C* |
| Deprecar documento | I | A | I | I | I | I |
| Manter glossário | I | A/R | I | I | I | I |
| Revisar docs baixo qualit. | I | R | C | I | I | I |
| Classificar confidential. | C | R | I | I | I | A |

*C\* = Compliance é consultado quando confidentiality = restricted ou confidential*

### Pipeline e Ingestão

| Atividade | Arquit. RAG | Curad. Conhec. | Eng. Pipeline | Dev API | Ops Infra | Compl. Segur. |
|-----------|:-----------:|:--------------:|:-------------:|:-------:|:---------:|:-------------:|
| Desenvolver/manter parser | I | I | A/R | I | I | I |
| Executar ingestão full | I | I | R | I | C | I |
| Investigar falhas pipeline | I | I | R | I | C | I |
| Adicionar nova fonte | A | C | R | I | C | C |
| Re-indexação (embedding) | A | I | R | C | C | I |

### API e Consumo

| Atividade | Arquit. RAG | Curad. Conhec. | Eng. Pipeline | Dev API | Ops Infra | Compl. Segur. |
|-----------|:-----------:|:--------------:|:-------------:|:-------:|:---------:|:-------------:|
| Desenvolver/manter API | C | I | I | A/R | I | I |
| Desenvolver MCP Server | C | I | I | A/R | I | I |
| Configurar agentes | A | C | I | R | I | C |
| Definir prompts de agente | C | C | I | R | I | I |

### Operações e Infra

| Atividade | Arquit. RAG | Curad. Conhec. | Eng. Pipeline | Dev API | Ops Infra | Compl. Segur. |
|-----------|:-----------:|:--------------:|:-------------:|:-------:|:---------:|:-------------:|
| Manter Neo4j | I | I | I | I | A/R | I |
| Backups e DR | I | I | I | I | A/R | I |
| Rotação de credenciais | I | I | I | I | A/R | C |
| Monitoramento / alertas | I | I | C | C | A/R | I |

### Segurança e Compliance

| Atividade | Arquit. RAG | Curad. Conhec. | Eng. Pipeline | Dev API | Ops Infra | Compl. Segur. |
|-----------|:-----------:|:--------------:|:-------------:|:-------:|:---------:|:-------------:|
| Auditoria de acessos | I | I | I | I | R | A |
| Resposta a incidentes | C | I | C | C | R | A |
| Aprovar dados sensíveis | C | C | I | I | I | A |
| DPIA (LGPD) | C | C | I | I | I | A/R |
| Conformidade BACEN | C | I | I | I | C | A/R |

**Nota sobre Fase 1:** Na prática, o Arquiteto do RAG e o Engenheiro de Pipeline podem ser a mesma pessoa. O Curador de Conhecimento pode ser qualquer membro da equipe que revisa conteúdo. Formalizar papéis a partir da Fase 2.

## 📌 15.3 — Rollback de Conhecimento

Se dados incorretos, desatualizados ou sensíveis forem ingeridos no Neo4j, como reverter de forma controlada?

### 🔹 Cenários de rollback

| Cenário | Gravidade | Ação |
|---------|-----------|------|
| 1 documento errado ingerido | 🟢 Baixa | Rollback granular |
| Conversão com falha aceita | 🟢 Baixa | Rollback granular |
| Lote inteiro com problema | 🟡 Média | Rollback de lote |
| Modelo de embedding trocado | 🟡 Média | Re-indexação B/G |
| Dados sensíveis ingeridos sem anonimização | 🔴 Alta | Rollback urgente + incidente B14 |
| Base inteira corrompida | 🔴 Crítica | Restore completo |

### 🔹 Rollback granular (1 documento)

Situação: um documento específico foi ingerido com conteúdo errado.

**Procedimento:**

**1. IDENTIFICAR**

- 🔸 Localizar o document_id no Neo4j
- 🔸 Confirmar qual versão está indexada (checksum, commit_hash)
- 🔸 Identificar todos os chunks vinculados

**2. REMOVER DO OURO**

```cypher
MATCH (c:Chunk)-[:PART_OF]->(d:Document {document_id: $docId})
DETACH DELETE c
DETACH DELETE d
```

- 🔸 Isso remove o documento E todos os seus chunks do Neo4j
- 🔸 Relações com outros nós (Module, System, etc.) são removidas automaticamente pelo DETACH DELETE

**3. CORRIGIR NA PRATA**

- 🔸 Se o .md na prata está errado: corrigir e commitar
- 🔸 Se o .md não deveria existir: remover e commitar
- 🔸 Se o original no bronze está errado: corrigir no bronze primeiro, depois regenerar na prata

**4. RE-INGERIR (se aplicável)**

- 🔸 Se o documento foi corrigido: rodar pipeline Prata→Ouro apenas para esse documento
- 🔸 Se o documento foi removido: nada a fazer (já deletado)

**5. VALIDAR**

- 🔸 Buscar pelo document_id no Neo4j — não deve retornar
- 🔸 Ou: buscar e confirmar que a versão correta está indexada
- 🔸 Registrar rollback no log de operações

### 🔹 Rollback de lote (múltiplos documentos)

Situação: uma execução do pipeline ingeriu um lote com problemas (ex: parser bugado gerou chunks incorretos para 50 documentos).

**Procedimento:**

**1. IDENTIFICAR o lote**

- 🔸 Usar batch_id ou timestamp da execução para encontrar docs
- 🔸 Query: documentos onde updated_at = data da execução problemática

**2. REMOVER o lote do Ouro**

```cypher
MATCH (c:Chunk)-[:PART_OF]->(d:Document)
WHERE d.updated_at = $problematicDate
  AND d.commit_hash = $problematicCommit
DETACH DELETE c
DETACH DELETE d
```

**3. REVERTER na Prata (se necessário)**

- 🔸 Git revert do commit que introduziu o lote
- 🔸 Ou: re-executar pipeline Bronze→Prata com parser corrigido

**4. RE-INGERIR o lote corrigido**

- 🔸 Pipeline Prata→Ouro detecta docs ausentes e re-cria

**5. VALIDAR**

- 🔸 Conferir contagem de docs e chunks no Neo4j
- 🔸 Rodar golden set ([[B12_testes_validacao_slas|B12]]) para validar qualidade

### 🔹 Rollback urgente (dados sensíveis)

Situação: dados pessoais ou confidenciais foram ingeridos sem anonimização. Tempo é crítico — seguir protocolo de incidente ([[B14_seguranca_soberania_dados|B14]]).

**Responsável pela ativação:** quem detectar o problema (Ops ou Pipeline) aciona imediatamente. Compliance ([[B14_seguranca_soberania_dados|B14, §14.13]]) é notificado em paralelo.
**SLA:** contenção em até 1h, remoção completa em até 4h. Comunicação a compliance no momento da detecção.

**Procedimento:**

**1. CONTER IMEDIATAMENTE**

- 🔸 Se dados já foram retornados em queries:
  - Parar a API (`docker compose down rag-api`)
  - Impedir mais acessos enquanto resolve
- 🔸 Se dados não foram consultados (pipeline acabou de rodar):
  - Prosseguir com remoção sem parar a API

**2. REMOVER do Ouro** — mesmo procedimento do rollback granular

- 🔸 Prioridade máxima — remover chunks que contêm PII

**3. REMOVER da Prata**

- 🔸 Deletar ou anonimizar o .md que contém dados sensíveis
- 🔸 Git commit com mensagem explícita

**4. VERIFICAR Bronze**

- 🔸 O original no bronze provavelmente contém os dados
- 🔸 Anonimizar no bronze se necessário
- 🔸 Ou: mover para quarentena até resolver

**5. VERIFICAR LOGS**

- 🔸 Alguém consultou esses dados antes da remoção?
- 🔸 Se sim: seguir procedimento de incidente completo ([[B14_seguranca_soberania_dados#14.13|B14, §14.13]])
- 🔸 Logs de query podem conter os dados nos resultados → Sanitizar logs se necessário

**6. COMUNICAR**

- 🔸 Registrar incidente
- 🔸 Notificar compliance ([[B14_seguranca_soberania_dados|B14]])

### 🔹 Restore completo (base corrompida)

Situação: Neo4j corrompido ou inconsistente de forma irrecuperável.

Procedimento (já detalhado em [[B13_operacoes#13.1|B13, §13.1]]):

1. Restaurar backup mais recente do Neo4j
2. Ou: recriar banco vazio e executar pipeline Prata→Ouro full
3. Tempo estimado: ~30 min para 1000 docs (SLA em [[B12_testes_validacao_slas|B12]])

### 🔹 Rastreabilidade para rollback

Para que rollbacks sejam possíveis, o pipeline deve manter:

- 🔸 **batch_id** — identificador de cada execução do pipeline
- 🔸 **ingested_at** — timestamp de ingestão de cada documento
- 🔸 **commit_hash** — commit que originou a versão indexada
- 🔸 **pipeline_version** — versão do pipeline que processou

Com esses campos, é possível:
- "Desfazer tudo que o pipeline v1.3 ingeriu ontem"
- "Reverter todos os docs do commit abc123"
- "Remover tudo que entrou no batch BATCH-2026-03-18-002"

## 📌 15.4 — Capacity Planning

### 🔹 Variáveis que definem o tamanho da base

| Variável | Impacto |
|----------|---------|
| Número de documentos na prata | Nós :Document no Neo4j |
| Tamanho médio dos documentos | Número de chunks por documento |
| Dimensão do embedding | Tamanho do vector index |
| Número de entidades (KG) | Nós de System, Module, etc. |
| Número de relações | Edges no grafo |
| Frequência de ingestão | I/O e processamento |
| Número de queries por dia | CPU e RAM para retrieval |

### 🔹 Estimativas por escala

| Escala | Docs | Chunks | Index | RAM Neo4j |
|--------|------|--------|-------|-----------|
| MVP (Fase 1) | ~50 | ~500 | ~50 MB | 2-4 GB |
| Pequena (Fase 2) | ~500 | ~5.000 | ~500 MB | 4-8 GB |
| Média (Fase 3) | ~2.000 | ~20.000 | ~2 GB | 8-16 GB |
| Grande (Fase 4) | ~10.000 | ~100.000 | ~10 GB | 16-32 GB |
| Muito grande | ~50.000 | ~500.000 | ~50 GB | 32-64 GB |

**Premissas:**

- 🔸 ~10 chunks por documento (média)
- 🔸 Embedding com N dimensões — depende do modelo escolhido (ver [[B08_pendencias#✅ Pendência 1 — Modelo de Embedding|P1]]). Referência: 1536d = 6 KB/vetor, 1024d = 4 KB/vetor, 768d = 3 KB/vetor
- 🔸 Metadados e texto: ~2 KB por chunk
- 🔸 Index size ≈ chunks x 8 KB (vetor + overhead)

### 🔹 Projeção de crescimento

Para planejar, estimar:

- 🔸 Quantos documentos NOVOS entram por mês? → Considerar: commits no Git, tickets resolvidos, PDFs novos
- 🔸 Quantos documentos são ATUALIZADOS por mês? → Cada atualização gera re-chunking e re-embedding
- 🔸 Taxa de obsolescência (documentos que saem do índice)? → Compensa parcialmente o crescimento

**Exemplo de projeção:**

| Mês | Docs | Chunks | Index | Observação |
|-----|------|--------|-------|------------|
| Mês 1 | 50 | 500 | 50 MB | MVP — repo de arquit. |
| Mês 3 | 200 | 2.000 | 200 MB | + 2 repos adicionais |
| Mês 6 | 500 | 5.000 | 500 MB | + PDFs ingeridos |
| Mês 12 | 1.500 | 15.000 | 1.5 GB | + tickets + APIs |
| Mês 18 | 3.000 | 30.000 | 3 GB | Fase 3 consolidada |
| Mês 24 | 5.000 | 50.000 | 5 GB | GraphRAG maduro |

> [!tip] Projeções ilustrativas
> Esses números são ILUSTRATIVOS. Cada organização terá um perfil diferente. O importante é medir e projetar com dados reais.

### 🔹 Gatilhos de escalonamento

Quando escalar a infraestrutura:

| Métrica | Gatilho | Ação |
|---------|---------|------|
| RAM do Neo4j > 80% do alocado | Alerta | Aumentar RAM |
| Disco > 70% ocupado | Alerta | Expandir SSD |
| Latência p95 busca > 500ms | Violação SLA ([[B12_testes_validacao_slas|B12]]) | Investigar: index? RAM? queries? |
| Chunks > 500.000 | Limite prático Neo4j vetorial | Avaliar multi backend ([[B08_pendencias|B08]]) |
| Pipeline full > 2h | Impacto oper. | Paralelizar ou particionar |
| Queries/dia > 10.000 | Carga alta | Avaliar cache ou réplica |

### 🔹 Monitoramento de capacidade

Métricas a coletar continuamente:

- 🔸 Total de documentos e chunks no Neo4j (query diária)
- 🔸 Tamanho do vector index em disco
- 🔸 Uso de RAM do Neo4j (heap + page cache)
- 🔸 Uso de disco (dados + logs + backups)
- 🔸 Latência de busca (p50, p95, p99) — comparar com SLA
- 🔸 Tempo de execução do pipeline (tendência)
- 🔸 Crescimento mensal (docs novos - docs deprecados)

**Relatório mensal de capacidade (dashboard HTML — padrão do projeto):**

- 🔸 Gráfico de crescimento da base
- 🔸 Projeção: "a esse ritmo, atingimos X chunks em Y meses"
- 🔸 Alertas de gatilho próximos
- 🔸 Recomendações de ação

## 📌 15.5 — Decisões e Critérios de Transição entre Fases

Quando evoluir de uma fase para a próxima?

### 🔹 Fase 1 → Fase 2 (MVP → Metadados)

**Pré-requisitos:**

- ✅ Pipeline Prata→Ouro operando de forma estável
- ✅ Pelo menos 50 documentos ingeridos com sucesso
- ✅ Busca vetorial retornando resultados relevantes
- ✅ Golden set com Recall@10 >= 70%
- ✅ Decisão de stack tomada e primeiro repo integrado

Quem decide: Arquiteto do RAG
Quem é consultado: Engenheiro de Pipeline, Curador

### 🔹 Fase 2 → Fase 3 (Metadados → Knowledge Graph)

**Pré-requisitos:**

- ✅ 100% dos documentos com front matter válido (ou sinalizados)
- ✅ Busca filtrada por sistema + módulo + confidencialidade operando
- ✅ Full-text index criado
- ✅ Métricas de conformidade e distribuição publicadas
- ✅ Pelo menos 200 documentos na base
- ✅ Golden set com Recall@10 >= 80%

Quem decide: Arquiteto do RAG
Quem é consultado: Curador, Compliance

### 🔹 Fase 3 → Fase 4 (Knowledge Graph → GraphRAG)

**Pré-requisitos:**

- ✅ Pelo menos 5 dos 7 tipos de entidade populados no grafo
- ✅ Relações explícitas navegáveis
- ✅ Pelo menos 1 fonte não-.md integrada via Bronze→Prata→Ouro
- ✅ RBAC + ABAC implementados
- ✅ Busca com expansão por grafo funcional
- ✅ Pelo menos 500 documentos na base
- ✅ Golden set com Recall@10 >= 85%

Quem decide: Arquiteto do RAG
Quem é consultado: todos os papéis

## 📌 15.6 — Processo de Curadoria Contínua

A curadoria não é um evento — é um processo contínuo.

### 🔹 Cadência

| Frequência | Atividade |
|------------|-----------|
| **Contínuo** (automático) | Pipeline automático ingere novos docs. Detecção de documentos alterados por checksum. Alertas de falha de pipeline |
| **Semanal** | Curador revisa documentos com status: draft. Curador revisa dead letter do pipeline. Engenheiro verifica métricas de ingestão |
| **Mensal** | Relatório de capacidade (§15.4). Revisão de SLAs vs. métricas reais ([[B12_testes_validacao_slas|B12]]). Revisão de documentos candidatos a deprecated |
| **Trimestral** | Revisão de glossário (termos novos/obsoletos). Revisão de acessos e permissões. Atualização de golden set de testes. Revisão de papéis RACI (ainda adequados?) |
| **Semestral** | Avaliação de transição de fase (§15.5). Revisão de política de segurança ([[B14_seguranca_soberania_dados|B14]]). Avaliar se modelo de embedding precisa de update |

## 📌 15.7 — Evolução por Fase

| Capacidade | Fase 1 | Fase 2 | Fase 3 | Fase 4 |
|------------|--------|--------|--------|--------|
| Papéis (RACI) | Informal (acumula) | Definido no doc | Publicad. + treino | Revisado trimest. |
| Rollback conhecimento | Manual (full) | Por doc (granul.) | Automát. + audit | Automát. + audit |
| Capacity plan | Sizing inicial | + monitor uso real | + projeç. crescim. | + auto scaling |
| Transição fase | Critérios definidos | Critérios medidos | Critérios enforced | Revisão contínua |
| Cadência curad. | Semanal (manual) | + mensal relatór. | + trimes. glossário | Completa |

---

## Documentos relacionados

### Depende de
- [[B13_operacoes]] — backups, disaster recovery, monitoramento que a governança supervisiona
- [[B14_seguranca_soberania_dados]] — compliance, resposta a incidentes, LGPD/BACEN

### Habilita
- [[B16_roadmap_implementacao]] — papéis RACI e critérios de transição alimentam o roadmap

### Relacionados
- [[B00_introducao]] — modelo Bronze/Prata/Ouro e fases de rollout
- [[B03_camada_ouro]] — rollback opera sobre Document/Chunk no Neo4j
- [[B06_graphrag_maturidade]] — retroalimentação e curadoria contínua
- [[B08_pendencias]] — decisões bloqueantes por fase
- [[B12_testes_validacao_slas]] — golden set e critérios de transição entre fases
