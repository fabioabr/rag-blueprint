---
id: ADR-008
doc_type: adr
title: "Governança: Papéis, Ciclo de Vida do Documento e Rollback"
system: RAG Corporativo
module: Governança e Operações
domain: Arquitetura
owner: fabio
team: arquitetura
status: approved
confidentiality: internal
date_decided: 2026-03-21
tags:
  - adr
  - governanca
  - papeis
  - raci
  - ciclo-de-vida
  - rollback
  - pii
  - lgpd
  - bacen
  - quality-gates
  - capacity-planning
  - curadoria
  - backup
  - incidente
aliases:
  - ADR-008
  - Governança RAG
  - Ciclo de Vida do Documento
  - Rollback Base Vetorial
  - RACI RAG Corporativo
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-kb/beta/ADR-008_governanca_ciclo_vida_rollback.beta.md"
source_beta_ids:
  - "BETA-008"
conversion_pipeline: promotion-pipeline-v1
conversion_quality: 100
converted_at: 2026-03-22
qa_score: 97
qa_date: 2026-03-22
qa_status: passed
created_at: 2026-03-21
updated_at: 2026-03-22
valid_from: 2026-03-21
valid_until: null
---

# ADR-008 — Governança: Papéis, Ciclo de Vida do Documento e Rollback

| Campo       | Valor                                                         |
|-------------|---------------------------------------------------------------|
| **Status**  | Accepted                                                      |
| **Data**    | 21/03/2026                                                    |
| **Decisor** | fabio (arquitetura)                                           |
| **Escopo**  | Papéis, ciclo de vida, rollback e critérios de transição de fases |

**Referências cruzadas:**

- [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]]: Pipeline de geração de conhecimento em 4 fases
- [[ADR-002_soberania_dados_cloud_vs_onprem|ADR-002]]: Soberania de dados
- [[ADR-004_seguranca_classificacao_dados|ADR-004]]: Segurança, controle de acesso e conformidade
- [[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]]: Pipeline de ingestão (idempotência)
- [[ADR-007_retrieval_hibrido_agentes|ADR-007]]: Retrieval híbrido e agentes
- [[ADR-009_selecao_modelos_embedding|ADR-009]]: Seleção de modelos de embedding

---

## Contexto

### Por que esta ADR existe

A base de conhecimento corporativa com Base Vetorial é um sistema vivo: documentos são criados, editados, promovidos, consumidos e descontinuados. Sem governança explícita, surgem problemas previsíveis:

- **Ninguém sabe quem é responsável por quê** — documentos desatualizados ficam meses na base; PII vaza porque ninguém sabia que compliance deveria aprovar
- **Documentos ficam num limbo de maturidade** — rascunhos entram na Base Vetorial sem gate; documentos aprovados nunca são revisados
- **Sem procedimento claro para incidentes** — lote de ingestão com dados errados, PII indexada, Base Vetorial corrompida
- **Transição entre fases é subjetiva** — sem critérios mensuráveis, depende de "sentimento"

### Contexto Regulatório

- **LGPD:** dados pessoais ingeridos precisam de base legal; incidentes de PII exigem contenção e reporte em prazo legal
- **BACEN (Resolução 4.893/2021):** rastreabilidade, controle de acesso e auditoria para setor financeiro
- **SOX / Controles internos:** segregação de funções (quem aprova ≠ quem executa)

### Interfaces com Outras Decisões

- [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] define o pipeline em 4 fases; este ADR define **QUEM** opera cada fase, **COMO** documentos transitam e **O QUE** fazer quando algo dá errado
- [[ADR-004_seguranca_classificacao_dados|ADR-004]] define controles de segurança; este ADR define os **PROCEDIMENTOS** quando esses controles falham
- [[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]] define o pipeline de ingestão; este ADR depende da **idempotência** para rollbacks seguros

### Premissas

- Git é a fonte da verdade; a Base Vetorial é uma projeção regenerável
- Todo documento tem um owner identificável
- Pipeline de ingestão é idempotente ([[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]])
- Equipe pequena nas fases iniciais (1-3 pessoas); acúmulo de papéis é esperado e aceitável na Fase 1

## Decisão — 4 Pilares

A governança se apoia em 4 pilares complementares:

1. **Pilar 1 — Papéis e RACI** (QUEM faz O QUÊ)
2. **Pilar 2 — Ciclo de Vida do Documento** (COMO documentos evoluem)
3. **Pilar 3 — Rollback** (O QUE fazer quando algo dá errado)
4. **Pilar 4 — Critérios de Transição entre Fases** (QUANDO avançar no roadmap)

## Pilar 1 — Papéis e RACI

### Definição dos 7 Papéis

| Papel | Descrição | Responsabilidades-chave | Limites |
|-------|-----------|------------------------|---------|
| **Arquiteto** | Visão técnica do pipeline, schemas, ADRs | Definir schemas de front matter, projetar grafo, estratégias de chunking, aprovar mudanças estruturais | NÃO faz infra, conteúdo de domínio, nem opera pipeline em produção |
| **Curador de Conhecimento** | Especialista de domínio que edita e valida .beta.md | Editar .beta.md, validar conteúdo gerado por IA, curar glossário, submeter para revisão | NÃO edita knowledge-base repo, não opera pipeline |
| **Engenheiro de Pipeline** | Implementação e manutenção do pipeline de ingestão | Implementar/manter etapas do pipeline, executar ingestões, rollbacks, re-indexação | NÃO define arquitetura, não valida conteúdo |
| **Dev API/Consumo** | Camada de consumo: APIs, MCP server, agentes | Endpoints de busca, MCP server, agentes de IA, filtros pré-retrieval, reranking | NÃO opera pipeline, não define schemas |
| **Operações (Ops)** | Infraestrutura, monitoramento, backup | Provisionar infra, monitoramento, backups, resposta a incidentes, capacity planning | NÃO define arquitetura, não valida conteúdo |
| **Owner de Documento** | Responsável pela precisão de documentos específicos | Garantir atualização, responder alertas de auto-deprecação, aprovar mudanças | Atua SOMENTE sobre seus documentos |
| **Compliance Officer** | Conformidade com LGPD, BACEN, políticas internas | Classificação de dados, aprovar fontes sensíveis, liderar incidentes de PII, auditoria | NÃO define arquitetura, NÃO opera pipeline, pode VETAR conteúdo |

### Matriz RACI

Legenda: **ARQ** = Arquiteto, **CUR** = Curador, **ENG** = Engenheiro de Pipeline, **DEV** = Dev API/Consumo, **OPS** = Operações, **OWN** = Owner de Documento, **CMP** = Compliance Officer

| Atividade | ARQ | CUR | ENG | DEV | OPS | OWN | CMP |
|-----------|-----|-----|-----|-----|-----|-----|-----|
| Ingestão de nova fonte | **A** | C | **R** | I | I | I | C |
| Edição de .beta.md | I | **R** | I | - | - | **A** | - |
| Promoção beta → md | **A** | **R** | C | I | - | C | C |
| Release para Base Vetorial | C | I | **R** | I | **A** | - | I |
| Rollback urgente (PII) | I | I | **R** | C | **R** | I | **A** |
| Re-indexação completa | **A** | I | **R** | I | C | - | I |
| Curadoria de glossário | C | **A** | - | I | - | **R** | - |
| Definição de schema/front matter | **R** | C | C | I | - | I | C |
| Aprovação de fase (ex: Fase1→2) | **A** | C | C | C | C | - | C |
| Auditoria de acesso | I | - | I | I | **R** | - | **A** |
| Backup da Base Vetorial | I | - | - | - | **R** | - | **A** |
| Resposta a incidente de segurança | C | I | **R** | C | **R** | I | **A** |

**R** = Responsible (executa) · **A** = Accountable (responde pelo resultado) · **C** = Consulted · **I** = Informed

**Justificativas-chave:**
- **Ingestão:** Engenheiro executa, Arquiteto é accountable (nova fonte pode impactar schema/chunking/retrieval), Compliance consultado (dados sensíveis)
- **Promoção beta → md:** Curador executa, Arquiteto é accountable (afeta fonte da verdade)
- **Rollback urgente PII:** Engenheiro E Operações ambos executam em paralelo (Ops contém APIs, Eng remove chunks), Compliance é accountable (implicações regulatórias)
- **Curadoria de glossário:** Owner executa (conhece definição do domínio), Curador é accountable (consistência global)

### Acúmulo de Papéis na Fase 1

**Combinações aceitáveis:**
- Arquiteto + Engenheiro de Pipeline (1 pessoa)
- Curador + Owner de Documento (1 pessoa)
- Dev API/Consumo + Operações (1 pessoa)

**Combinação PROIBIDA (mesmo na Fase 1):**
- Compliance Officer + qualquer papel operacional (segregação de funções obrigatória)

**Regras de transição:**
- A partir da Fase 2: desacoplar Arquiteto + Engenheiro
- A partir da Fase 3: cada papel com pelo menos 1 pessoa dedicada

## Pilar 2 — Ciclo de Vida do Documento

### Máquina de Estados

```
DRAFT → IN-REVIEW → APPROVED → DEPRECATED
  ↑         │                       │
  └─────────┘ (rejeição)            │
  ↑                                 │
  └─────────────────────────────────┘ (reativação)
```

**Não existem atalhos** — um documento não pode ir de DRAFT direto para APPROVED.

### Transições Detalhadas

| Transição | Quem dispara | Pré-condições | Mecanismo |
|-----------|-------------|---------------|-----------|
| DRAFT → IN-REVIEW | Curador/Owner | Front matter completo, sem TODOs, revisado pelo autor | Alterar status + criar PR no workspace |
| IN-REVIEW → APPROVED | Arquiteto/PO | Revisão técnica + conteúdo + segurança | Aprovar PR → merge → promoção para knowledge-base |
| IN-REVIEW → DRAFT | Arquiteto/PO | Problemas identificados na revisão | Solicitar mudanças no PR (rejeição sem justificativa é proibida) |
| APPROVED → DEPRECATED | Owner (manual) ou Sistema (automático) | Manual: decisão do owner. Automático: 12 meses sem atualização | Alterar status + deprecated_reason. Auto: notifica owner, 30 dias para confirmar |
| DEPRECATED → DRAFT | Owner/Curador | Justificativa + comprometimento de atualização. Aprovação do Arquiteto | Volta como DRAFT para re-validação integral |

### Impacto do Estado na Base Vetorial

| Estado | Indexação | Comportamento no retrieval |
|--------|-----------|---------------------------|
| DRAFT | NÃO indexado | Invisível |
| IN-REVIEW | NÃO indexado (padrão) | Invisível (opcionalmente visível apenas para reviewers com banner "[EM REVISÃO]") |
| APPROVED | Totalmente indexado | Plenamente pesquisável (com filtros de confidencialidade) |
| DEPRECATED | Indexado com flag deprecated=true | Pesquisável com rank reduzido (score × 0.5), warning na resposta, não aparece se há alternativa APPROVED |

**Por que DEPRECATED não é removido:** pode ser única fonte sobre sistema legado, contém contexto histórico, chunks já existem (economia de reprocessamento).

### RACI por Transição

| Transição | ARQ | CUR | ENG | DEV | OPS | OWN | CMP |
|-----------|-----|-----|-----|-----|-----|-----|-----|
| DRAFT → IN-REVIEW | I | **R** | - | - | - | **A** | - |
| IN-REVIEW → APPROVED | **A** | C | I | I | - | C | C* |
| IN-REVIEW → DRAFT | **R** | I | - | - | - | I | - |
| APPROVED → DEPRECATED | I | I | I | I | - | **R** | I |
| DEPRECATED → DRAFT | **A** | C | - | - | - | **R** | - |

*CMP consultado apenas para docs restricted/confidential.

## Pilar 3 — Rollback

A premissa fundamental: a **idempotência** do pipeline ([[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]]) garante que re-processar um documento com o mesmo conteúdo produz exatamente o mesmo resultado na Base Vetorial.

### Cenário A — Rollback Granular (1 documento)

- **Urgência:** BAIXA a MÉDIA | **SLA:** 24 horas úteis
- **Procedimento:** Identificar problema → Corrigir no repositório (editar .beta.md ou git revert) → Re-executar pipeline para esse documento → Validar via busca semântica
- **Responsável:** Engenheiro (R), Owner (A)

### Cenário B — Rollback de Lote (múltiplos documentos)

- **Urgência:** MÉDIA | **SLA:** 48 horas úteis
- **Procedimento:** Identificar lote via batch_id → Avaliar estratégia (correção em docs vs pipeline) → Corrigir → Re-executar pipeline em batch → Validar → Registrar incidente
- **Responsável:** Engenheiro (R), Arquiteto (A)

**Tracking de lotes obrigatório:** cada execução registra batch_id, timestamps, documentos processados (sucesso/falha), trigger e triggered_by.

### Cenário C — Rollback Urgente (PII / Vazamento)

- **Urgência:** CRÍTICA | **SLA:** Contenção em 1 hora, remoção completa em 4 horas

**Procedimento detalhado:**

| Passo | SLA | Quem | Ações |
|-------|-----|------|-------|
| 1 — CONTER | 15 min | Ops/Eng (quem detectar) | Verificar se dados foram servidos; adicionar doc à blocklist OU parar API; notificar Compliance imediatamente |
| 2 — Remover da Base Vetorial | 1 hora | Engenheiro | Identificar chunks, exportar para evidência forense, deletar chunks e documento, verificar remoção do índice |
| 3 — Remover do knowledge-base repo | 2 horas | Engenheiro | Deletar ou anonimizar .md; avaliar remoção do histórico Git (git filter-branch / BFG) |
| 4 — Verificar workspace repo | 3 horas | Curador + Engenheiro | Anonimizar/deletar .beta.md, verificar referências e fontes brutas |
| 5 — Verificar logs | 4 horas | Ops + Compliance | Consultar logs de retrieval; se PII foi servido → incidente confirmado → procedimento ANPD |

**Ativação:** qualquer pessoa pode ativar sem aprovação prévia. Compliance notificado nos primeiros 15 minutos.

**Pós-incidente (até 5 dias úteis):** Root Cause Analysis, ações preventivas (scanner PII, blocklist, treinamento), documentar RCA no knowledge-base repo.

### Cenário D — Rollback Completo (Restauração de backup)

- **Urgência:** ALTA | **SLA:** 8 horas
- **Procedimento:** Avaliar dano (parcial <20% → cenário B; amplo >20% → restore) → Restaurar backup → Re-indexar a partir do knowledge-base repo → Validar integridade

**Estimativa de tempo de recuperação:**

| Volume | Tempo estimado |
|--------|---------------|
| 50 documentos | ~5 minutos |
| 200 documentos | ~15 minutos |
| 1.000 documentos | ~30-45 minutos |
| 10.000+ documentos | ~4-8 horas |

**Responsável:** Operações (R), Arquiteto (A), Engenheiro (C)

## Pilar 4 — Critérios de Transição entre Fases

A transição entre fases NÃO é baseada em cronograma — é baseada em **critérios mensuráveis**.

### Fase 1 → Fase 2 (MVP → Metadados)

| Critério | Métrica |
|----------|---------|
| C1: Pipeline funcional end-to-end | 10 ingestões consecutivas sem falha |
| C2: Golden set mínimo | 20 pares pergunta/resposta, 3+ domínios |
| C3: Recall@10 >= 70% | Medido no golden set |
| C4: Front matter válido em 100% dos docs | 0 erros de parsing |
| C5: Monitoramento básico | Dashboard acessível com dados atualizados |

**Aprovação:** Arquiteto + PO, conjuntamente.

### Fase 2 → Fase 3 (Metadados → Knowledge Graph)

| Critério | Métrica |
|----------|---------|
| C1: Front matter validado (vocabulários controlados) | 0 warnings de validação |
| C2: Golden set expandido | 50 pares, 5+ domínios |
| C3: Recall@10 >= 80% | Medido no golden set expandido |
| C4: Filtros de confidencialidade testados | 100% cobertura, nenhum vazamento |
| C5: Backup operacional | Pelo menos 1 restore de teste bem-sucedido |

**Aprovação:** Arquiteto + PO, conjuntamente.

### Fase 3 → Fase 4 (Knowledge Graph → GraphRAG Corporativo)

| Critério | Métrica |
|----------|---------|
| C1: Knowledge graph com 5+ tipos de entidade | COUNT(DISTINCT labels) >= 7 |
| C2: Pelo menos 1 fonte não-.md integrada | >0 documentos de fonte não-.md |
| C3: Golden set robusto | 100 pares, 20 exigindo traversal |
| C4: Recall@10 >= 85% | Medido no golden set completo |
| C5: RBAC implementado | Testes cobrindo 3+ papéis com escopos diferentes |
| C6: Audit logging operacional | Logs pesquisáveis, retidos 90+ dias |

**Aprovação:** Arquiteto + PO + Compliance Officer, conjuntamente.

## Cadência de Curadoria

| Frequência | Quem | Atividades |
|------------|------|------------|
| **Contínua** | Owner | Atualizar docs quando processo/sistema/regulação muda; responder alertas |
| **Semanal** | Engenheiro | Health check do pipeline, detectar chunks órfãos, verificar consistência repo ↔ Base Vetorial |
| **Mensal** | Arquiteto + Curador | Golden set (Recall@10), revisar glossário, avaliar docs deprecated >3 meses |
| **Trimestral** | Arquiteto + Ops + Compliance | Auditoria de acesso, classificação, limpeza de deprecated >6 meses, capacity planning, drill de rollback |
| **Semestral** | Todos os papéis | Revisão abrangente, avaliação de transição de fase, revisão de ADRs e tecnologias, roadmap 6 meses |

## Capacity Planning

### Gatilhos de Ação

| Métrica | Threshold | Ação |
|---------|-----------|------|
| Uso de RAM (Base Vetorial) | > 80% | Investigar consumo |
| Uso de disco | > 70% | Planejar expansão para 6 meses |
| Latência p95 de busca | > 500ms | Otimizar índices, avaliar cache |
| Total de chunks | > 500.000 | Avaliar particionamento |
| Taxa de falha de ingestão | > 5% | Investigar pipeline/dados |
| Tempo de re-indexação completa | > 4 horas | Paralelizar workers |

### Projeção de Crescimento

| Fase | Documentos | Chunks | Storage estimado |
|------|-----------|--------|-----------------|
| Fase 1 | 20-100 | 200-1.000 | 2-10 MB |
| Fase 2 | 100-500 | 1K-5K | 10-50 MB |
| Fase 3 | 500-2.000 | 5K-20K | 50-200 MB |
| Fase 4 | 2.000-10K | 20K-100K | 200 MB - 1 GB |
| Escala | 10K-50K | 100K-500K | 1-5 GB |

## Alternativas Descartadas

| Alternativa | Motivo da rejeição |
|-------------|-------------------|
| Sem papéis formais ("todo mundo faz tudo") | Viola segregação de funções; sem accountability |
| Ciclo de vida binário (só APPROVED/DEPRECATED) | Sem quality gate; risco de indexar conteúdo não-validado |
| Rollback manual sem procedimentos | Sob pressão leva a erros; LGPD exige plano de resposta |
| Transição de fase por cronograma | Pressão para avançar sem fundações; dívida técnica |
| Auto-deprecação em 6 meses | Fadiga de re-validação para docs estáveis (ADRs); 12 meses é equilíbrio |

## Consequências

### Positivas

- Accountability clara para cada atividade
- Quality gates impedem conteúdo não-validado na Base Vetorial
- Rollback previsível com procedimento documentado para cada cenário
- Transições baseadas em evidência (métricas, não cronograma)
- Conformidade regulatória (LGPD, BACEN, controles internos)
- Escalabilidade organizacional (acúmulo na Fase 1, separação na Fase 3+)

### Negativas / Trade-offs

- **Overhead de processo:** revisão IN-REVIEW adiciona latência (mitigação: fast-track com registro posterior)
- **Complexidade para equipes pequenas:** 7 papéis é excessivo para 1-2 pessoas (mitigação: acúmulo documentado)
- **Auto-deprecação pode ser agressiva:** threshold customizável por doc_type
- **Rollback urgente depende de logging:** mitigação via meta-monitoramento
- **Critérios podem atrasar projeto:** revisáveis semestralmente com justificativa

## Implementação (Faseamento)

### Fase 1 — Implementação Imediata

- Semana 1: documentar papéis, implementar campo status no front matter, validação de front matter, golden set inicial (20 perguntas)
- Semana 2-3: batch_id no pipeline, rollback granular, backup diário, dashboard mínimo
- Semana 4: documentar/drill rollback urgente PII, medir Recall@10, avaliar critérios Fase 1→2

### Fase 2 — Implementação Progressiva

- Máquina de estados no pipeline, rollback de lote, auto-deprecação, notificações para Owners, expandir golden set (50), filtros de confidencialidade, testar restore

### Fase 3 — Maturidade

- Separar papéis, RBAC, audit logging, scanner PII, blocklist para rollback cirúrgico, golden set (100 com traversal), cadência formal de curadoria

## Referências

- [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]]: Pipeline de geração de conhecimento em 4 fases
- [[ADR-004_seguranca_classificacao_dados|ADR-004]]: Segurança, controle de acesso e conformidade
- [[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]]: Pipeline de ingestão (idempotência)
- LGPD (Lei 13.709/2018)
- BACEN Resolução 4.893/2021
- RACI Model (PMI)

---

<!-- QA-MD: inicio -->
## Quality Assurance — .md final

**Revisor:** Pipeline de Promoção QA
**Data:** 22/03/2026
**Fonte:** kb/rag-blueprint-adrs-kb/beta/ADR-008_governanca_ciclo_vida_rollback.beta.md

| Critério | Peso | Nota | Comentário |
|----------|------|------|------------|
| Front matter rico | 25% | 96% | Todos os campos obrigatórios presentes. 13 tags e 5 aliases (mínimos atendidos). Corrigido: `status: accepted` alterado para `status: approved` (valor válido conforme schema). |
| Completude de conteúdo | 20% | 100% | Todas as seções ADR completas. 4 pilares detalhados (Papéis/RACI, Ciclo de Vida, Rollback, Critérios de Transição). Cadência de curadoria e capacity planning incluídos. Tabela de referência no topo. |
| Wikilinks | 10% | 100% | Todos os wikilinks no formato [[ADR-NNN_slug\|ADR-NNN]]. Nenhum [[BETA-*]]. Nenhum wikilink no front matter. |
| Sem artefatos workspace | 15% | 100% | Nenhum marcador LOCKED, nenhum QA-BETA, nenhum BETA-NNN no campo id. |
| Compatibilidade Obsidian | 10% | 100% | YAML válido, tags e aliases como arrays YAML, front matter entre marcadores `---`. |
| Linhagem rastreável | 10% | 100% | source_path aponta para beta, source_beta_ids correto (BETA-008), conversion_pipeline: promotion-pipeline-v1. |
| Clareza e estrutura | 10% | 100% | Excelente organização em 4 pilares. Matrizes RACI detalhadas, máquina de estados visual, cenários de rollback com SLAs, tabelas de critérios de transição e capacity planning. |

**Score:** 99.0% — APROVADO para ingestão

**Por que não é 100%:** (1) Campo `status` continha valor `accepted` não previsto no schema — corrigido para `approved` (-4% no front matter rico).
<!-- QA-MD: fim -->
