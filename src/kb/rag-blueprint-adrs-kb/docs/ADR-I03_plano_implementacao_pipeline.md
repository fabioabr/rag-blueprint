---
id: ADR-I03
doc_type: adr
title: "Plano de Implementação do Pipeline — 6 Fases com Entregas, Dependências e Critérios de Conclusão"
system: RAG Corporativo
module: Implementação Pipeline
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - plano de implementação
  - pipeline de conhecimento
  - faseamento
  - estrutura de repositórios
  - rag workspace
  - rag knowledge base
  - beta md
  - md final
  - front matter
  - schema de validação
  - templates
  - permissões
  - branch protection
  - service account
  - pipeline beta
  - captura de fontes
  - conversion quality
  - manifesto de ingestão
  - formatos suportados
  - pdf
  - docx
  - xlsx
  - email
  - confluence
  - edição humana
  - obsidian
  - blocos locked
  - re ingestão
  - merge
  - conflito
  - locked conflict
  - pipeline de promoção
  - pr automático
  - aprovação
  - qa score
  - gate de qualidade
  - release tag
  - changelog
  - temporalidade
  - valid from
  - valid until
  - supersedes
  - version of
  - document family
  - filtro temporal
  - diff de fontes
  - safety net
  - git diff
  - critérios de transição
  - golden set
  - recall
  - rbac
  - audit logging
  - compliance officer
  - dependências entre fases
  - duração estimada
  - responsáveis
  - definition of done
aliases:
  - "ADR-I03"
  - "Plano de Implementação Pipeline"
  - "Plano de Implementação do Pipeline"
  - "Implementação Faseada do Pipeline"
  - "Roadmap de Implementação Pipeline"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/beta/ADR-I03_plano_implementacao_pipeline.beta.md"
source_beta_ids:
  - "BETA-I03"
conversion_pipeline: promotion-pipeline-v2
conversion_quality: 95
converted_at: 2026-03-23
qa_score: null
qa_date: null
qa_status: pending
created_at: 2026-03-23
updated_at: 2026-03-23
valid_from: 2026-03-23
valid_until: null
---

# ADR-I03 — Plano de Implementação do Pipeline — 6 Fases com Entregas, Dependências e Critérios de Conclusão

| Campo       | Valor                                                         |
|-------------|---------------------------------------------------------------|
| **Status**  | Accepted                                                      |
| **Data**    | 23/03/2026                                                    |
| **Decisor** | fabio (arquitetura)                                           |
| **Escopo**  | Plano de implementação fase a fase do pipeline de geração de conhecimento em 4 fases, com entregas, dependências, responsáveis e critérios de conclusão |

**Referências cruzadas:**

- [[ADR-001]]: Pipeline de Geração de Conhecimento em 4 Fases
- [[ADR-008]]: Governança (Pilar 4 critérios de transição, papéis RACI)
- [[ADR-006]]: Pipeline de Ingestão (7 etapas, idempotência)
- [[ADR-010]]: Git Flow (release, promoção, ambientes)

---

## Contexto

O [[ADR-001]] define o pipeline de geração de conhecimento em 4 fases (Fontes → .beta.md → .md final → Base Vetorial). Este ADR detalha o plano de implementação prático, fase a fase, com dependências explícitas.

## Decisão

Detalhar o plano de implementação fase a fase do pipeline de geração de conhecimento em 4 fases ([[ADR-001]]), incluindo entregas, dependências, responsáveis e critérios de conclusão para cada etapa.

O [[ADR-001]] define o pipeline como:

- **FASE 1:** Fontes diversas (seleção de insumos)
- **FASE 2:** .beta.md (mineração + edição humana)
- **FASE 3:** .md final (promoção via pipeline — fonte da verdade)
- **FASE 4:** Base Vetorial (ingestão)

A implementação é faseada em 6 etapas sequenciais, com dependências explícitas entre elas.

## Fase 1 — Estrutura

**Entrega:**
- Criar os 2 repositórios (rag-workspace e rag-knowledge-base)
- Configurar estrutura de pastas conforme [[ADR-001]]:
  - rag-workspace: sources/, beta/, process/, .pipeline/
  - rag-knowledge-base: docs/, presentations/, releases/
- Criar templates de .beta.md com front matter leve
- Criar schemas de validação de front matter
- Configurar permissões de acesso:
  - rag-workspace: read-write para times de conhecimento
  - rag-knowledge-base: read-only para todos, write via service account
- Configurar branch protection rules

**Dependência:** Nenhuma (ponto de partida)

**Responsáveis:**
- Arquiteto: definição de schemas, templates e estrutura
- Operações: criação de repos, permissões, service account

**Critérios de conclusão (DOD):**
- [ ] 2 repositórios criados e acessíveis
- [ ] Estrutura de pastas criada
- [ ] Templates de .beta.md disponíveis
- [ ] Schemas de validação configurados
- [ ] Permissões configuradas e testadas
- [ ] Branch protection ativa

**Duração estimada:** 1 semana

## Fase 2 — Pipeline Beta

**Entrega:**
- Implementar captura de fontes diversas para .beta.md
- Pipeline de IA que gera .beta.md a partir dos insumos:
  - Leitura da fonte → parsing → extração de conteúdo → geração de .beta.md com front matter leve
- Implementar manifesto de ingestão (sources/manifesto.json): origem, formato, data, responsável, confidencialidade
- Implementar cálculo de conversion_quality:
  - >= 80%: ingestão automática
  - 30-79%: draft com revisão humana obrigatória
  - < 30%: fonte rejeitada com log de erro
- Suporte a formatos: MD nativo, PDF texto, PDF OCR, DOCX, XLSX, e-mail, transcrição, JSON/ticket, web/Confluence
- Registrar campo sources no front matter do .beta.md

**Dependência:** Fase 1 (repositórios e templates existem)

**Responsáveis:**
- Engenharia de dados: implementação do pipeline de captura e conversão
- Arquiteto: definição de formatos suportados, regras de conversion_quality

**Critérios de conclusão (DOD):**
- [ ] Pipeline gera .beta.md a partir de pelo menos 3 formatos de fonte
- [ ] Manifesto de ingestão gerado automaticamente
- [ ] conversion_quality calculado e registrado no front matter
- [ ] Fontes com score < 30% rejeitadas com log
- [ ] .beta.md gerado com front matter leve válido

**Duração estimada:** 2-3 semanas

## Fase 3 — Edição Humana

**Entrega:**
- Configurar Obsidian + plugin Git no rag-workspace
- Treinar equipe em:
  - Edição de .beta.md via Obsidian
  - Uso de blocos LOCKED para proteger edições humanas
  - Fluxo de submissão para revisão (DRAFT → IN-REVIEW)
- Implementar suporte a blocos LOCKED no pipeline:
  - IA NUNCA altera conteúdo dentro de LOCKED:START/END
  - IA pode sugerir mudanças como comentário separado
  - Humano pode remover lock a qualquer momento
- Implementar mecanismo de re-ingestão com merge:
  - Diff de fontes (v1 vs v2)
  - Classificação de trechos (sem conflito, possível conflito, conflito em bloco locked)
  - Alertas CONFLICT e LOCKED-CONFLICT inline
  - Relatório de re-ingestão

**Dependência:** Fase 2 (pipeline beta funcional, .beta.md existem)

**Responsáveis:**
- Arquiteto: definição do fluxo de edição e regras LOCKED
- POs / Analistas: edição dos .beta.md, validação de conteúdo
- Engenharia de dados: implementação de blocos LOCKED e re-ingestão

**Critérios de conclusão (DOD):**
- [ ] Obsidian configurado e acessível para o time
- [ ] Equipe treinada (pelo menos 2 sessões de treinamento)
- [ ] Blocos LOCKED respeitados pelo pipeline (teste automatizado)
- [ ] Re-ingestão com merge funcional (teste com fonte atualizada)
- [ ] Alertas CONFLICT gerados corretamente

**Duração estimada:** 1-2 semanas

## Fase 4 — Pipeline de Promoção

**Entrega:**
- Implementar pipeline .beta.md → .md final:
  - Leitura do .beta.md consolidado
  - Remoção de marcadores LOCKED (conteúdo preservado, marcadores removidos)
  - Enriquecimento de front matter (adicionar campos de governança: system, module, owner, team, QA score)
  - Geração do .md final
- Implementar PR automático no rag-knowledge-base:
  - Pipeline gera .md e cria PR automaticamente
  - PR requer aprovação de PO + Arquiteto (2 aprovações)
  - Após aprovação: merge no main
- Implementar release com TAG:
  - TAG vX.Y.Z criada após merge aprovado
  - Release notes geradas automaticamente (changelog)
- Gate de qualidade:
  - QA score >= 90%: promoção automática
  - QA score 80-89%: promoção com qa_notes documentado no front matter
  - QA score < 80%: bloqueante, retorna para .beta.md

**Dependência:** Fase 3 (.beta.md editados e consolidados por humanos)

**Responsáveis:**
- Engenharia de dados: implementação do pipeline de promoção
- Arquiteto: definição de front matter rico, gate de qualidade
- POs: aprovação de PRs (conteúdo)

**Critérios de conclusão (DOD):**
- [ ] Pipeline gera .md final com front matter rico
- [ ] PR automático criado no rag-knowledge-base
- [ ] PR requer 2 aprovações antes do merge
- [ ] TAG vX.Y.Z criada após merge
- [ ] Gate de qualidade funcional (score < 80% bloqueia)

**Duração estimada:** 2-3 semanas

## Fase 5 — Temporalidade

**Entrega:**
- Adicionar campos temporais ao front matter do .md final: valid_from, valid_until, superseded_by, supersedes
- Implementar na Base Vetorial:
  - Relação `(:Document)-[:SUPERSEDES {effective_date}]->(:Document)`
  - Relação `(:Document)-[:VERSION_OF]->(:DocumentFamily)`
  - Nó `:DocumentFamily` com family_id, title, current_version
- Implementar filtro temporal no retrieval:
  - Detectar contexto temporal na pergunta
  - Filtrar por valid_from/valid_until antes da busca vetorial
  - Assumir data atual se não houver contexto temporal explícito
- Agentes instruídos a citar vigência e versões anteriores

**Dependência:** Fase 4 (pipeline de promoção e .md finais existem)

**Responsáveis:**
- Arquiteto: definição do modelo temporal e filtros
- Engenharia de dados: implementação dos campos e relações na Base Vetorial
- Dev API/Consumo: implementação do filtro temporal no retrieval

**Critérios de conclusão (DOD):**
- [ ] Campos temporais no front matter do .md
- [ ] Relações SUPERSEDES e VERSION_OF na Base Vetorial
- [ ] Nó DocumentFamily criado e populado
- [ ] Filtro temporal funcional no retrieval (teste com perguntas temporais)
- [ ] Agentes citam vigência nas respostas

**Duração estimada:** 2 semanas

## Fase 6 — Re-Ingestão

**Entrega:**
- Implementar pipeline de re-ingestão completo:
  - Detecção de fontes atualizadas (webhook ou polling)
  - Diff de fontes (comparação v1 vs v2)
  - Análise de impacto: classificação de trechos
  - Merge automático (sem conflito) + alertas (com conflito)
- Implementar relatório de re-ingestão:
  - Trechos atualizados automaticamente
  - Conflitos para revisão humana
  - Locks potencialmente desatualizados
- Safety net via git diff:
  - Edição humana detectada sempre prevalece sobre IA
  - Mesmo que humano não tenha usado LOCKED, o diff detecta edições manuais e preserva

**Dependência:** Fase 4 (pipeline de promoção funcional)

**Responsáveis:**
- Engenharia de dados: implementação do diff, merge e relatório
- Arquiteto: definição de regras de conflito e priorização
- Curador: revisão de conflitos não resolvidos automaticamente

**Critérios de conclusão (DOD):**
- [ ] Pipeline detecta fontes atualizadas
- [ ] Diff de fontes gera lista de mudanças
- [ ] Merge automático preserva blocos LOCKED
- [ ] Alertas CONFLICT e LOCKED-CONFLICT gerados
- [ ] Relatório de re-ingestão gerado
- [ ] Safety net via git diff funcional

**Duração estimada:** 2-3 semanas

## Resumo Consolidado

| Fase | Entrega | Dependência | Responsável | Duração |
|---|---|---|---|---|
| 1 | Estrutura (repos, pastas) | Nenhuma | ARQ + OPS | 1 semana |
| 2 | Pipeline beta | Fase 1 | ENG + ARQ | 2-3 semanas |
| 3 | Edição humana (Obsidian) | Fase 2 | ARQ + POs | 1-2 semanas |
| 4 | Pipeline promoção | Fase 3 | ENG + ARQ | 2-3 semanas |
| 5 | Temporalidade | Fase 4 | ARQ + ENG + DEV | 2 semanas |
| 6 | Re-ingestão | Fase 4 | ENG + ARQ | 2-3 semanas |

**Total estimado:** 10-14 semanas

**Nota:** Fases 5 e 6 podem ser executadas em paralelo (ambas dependem apenas da Fase 4), reduzindo o total para 8-12 semanas.

## Critérios de Transição entre Fases do Roadmap

Além das fases de implementação acima, o projeto possui fases de maturidade ([[ADR-008]] Pilar 4). Os critérios para avançar são:

**Fase 1 → Fase 2 (MVP → Metadados):**
- 10 ingestões consecutivas sem falha
- Golden set mínimo: 20 pares pergunta/resposta, 3+ domínios
- Recall@10 >= 70%
- Front matter válido em 100% dos documentos
- Monitoramento básico com dashboard acessível
- Aprovação: Arquiteto + PO

**Fase 2 → Fase 3 (Metadados → Knowledge Graph):**
- Front matter validado (vocabulários controlados, 0 warnings)
- Golden set expandido: 50 pares, 5+ domínios
- Recall@10 >= 80%
- Filtros de confidencialidade testados (100% cobertura)
- Pelo menos 1 restore de backup bem-sucedido
- Aprovação: Arquiteto + PO

**Fase 3 → Fase 4 (Knowledge Graph → GraphRAG Corporativo):**
- Knowledge graph com 5+ tipos de entidade
- Pelo menos 1 fonte não-.md integrada
- Golden set robusto: 100 pares, 20 exigindo traversal
- Recall@10 >= 85%
- RBAC implementado (3+ papéis com escopos diferentes)
- Audit logging operacional (logs retidos 90+ dias)
- Aprovação: Arquiteto + PO + Compliance Officer

## Referências

- [[ADR-001]]: Pipeline de Geração de Conhecimento em 4 Fases (faseamento, responsáveis, estrutura de pastas, blocos LOCKED, temporalidade, re-ingestão)
- [[ADR-008]]: Governança (Pilar 4 critérios de transição, papéis RACI)
- [[ADR-006]]: Pipeline de Ingestão (7 etapas, idempotência)
- [[ADR-010]]: Git Flow (release, promoção, ambientes)

<!-- conversion_quality: 95 -->
