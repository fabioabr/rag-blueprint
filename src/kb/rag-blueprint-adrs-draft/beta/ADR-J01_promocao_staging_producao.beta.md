---
id: BETA-J01
title: "Promocao de Staging para Producao"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-J01_promocao_staging_producao.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags:
  - promocao staging producao
  - release
  - deploy
  - consolidacao
  - tag release
  - staging
  - producao
  - pipeline de promocao
  - pipeline de ingestao
  - qa score
  - gate humano
  - aprovacao manual
  - pr automatico
  - merge
  - rag workspace
  - rag knowledge base
  - base vetorial
  - golden set
  - recall
  - smoke test
  - testes automatizados
  - testes de acesso
  - confidencialidade
  - integridade
  - contagem de documentos
  - contagem de chunks
  - agentes de ia
  - mcp
  - curador
  - arquiteto
  - po
  - operacoes
  - wikilinks
  - front matter
  - changelog
  - release notes
  - beta md
  - md final
  - blocos locked
  - versionamento semantico
  - idempotencia
  - release version
  - monitoramento
  - latencia
  - rollback
  - hotfix
  - staging failed
  - patch
  - checklist
  - stakeholders
  - notificacao
  - tempos de referencia
  - fluxo de 4 passos
aliases:
  - "ADR-J01"
  - "Promocao Staging Producao"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## ADR-J01 -- Promocao de Staging para Producao

**Tipo:** ADR
**Origem:** ADR-010
**Data:** 23/03/2026

## 1. Objetivo

Documentar o procedimento operacional de 4 passos para promover uma release de staging para producao na base de conhecimento, incluindo pre-condicoes, acoes detalhadas e criterios de saida para cada passo. Extraido do fluxo de promocao definido no ADR-010 (Release-Based Flow).

## 2. Visao Geral do Fluxo

```
Passo 1: Consolidacao (branches mergeadas, QA aprovado)
    |
    v
Passo 2: TAG Release (TAG no workspace, pipeline gera .md, PR no KB)
    |
    v
Passo 3: Staging (ingestao na Base Vetorial staging, testes)
    |
    v
Passo 4: Producao (aprovacao manual, implantacao, smoke test)
```

**REGRA FUNDAMENTAL:** nenhum dado chega em producao sem passar por staging. A implantacao em producao e SEMPRE manual (gate humano obrigatorio).

## 3. Passo 1 -- Consolidacao

**Pre-condicoes:**
- Todas as branches de trabalho mergeadas em release/vX.Y.Z/main
- Nenhum Pull Request pendente no release/vX.Y.Z/
- Zero alertas `<!-- CONFLICT -->` nao resolvidos nos .beta.md
- Zero alertas `<!-- LOCKED-CONFLICT -->` nao resolvidos

**Acoes:**

### 1.1 Curador revisa estado consolidado do release/vX.Y.Z/main

- Navegar pelos .beta.md alterados nesta release
- Verificar que conteudo esta completo e coerente
- Confirmar que todos os blocos LOCKED estao intactos

### 1.2 QA automatizado executa

- Validacao de front matter em todos os .beta.md (schema completo)
- Calculo de QA score por documento
- Verificacao de wikilinks (todos apontam para documentos existentes)
- Verificacao de consistencia de tags e glossario

### 1.3 Curador gera relatorio de release (changelog)

- Lista de documentos novos nesta release
- Lista de documentos atualizados (com resumo das mudancas)
- Lista de documentos deprecados
- QA score consolidado

**Criterios de saida:**
- [ ] QA score >= 90% em todos os documentos (ou 80-89% com qa_notes documentado no front matter)
- [ ] Abaixo de 80% e BLOQUEANTE -- retorna para edicao
- [ ] Relatorio de release gerado e revisado pelo Curador
- [ ] Zero conflitos nao resolvidos
- [ ] Todos os wikilinks validos

**Responsavel:** Curador (R), Arquiteto (A)

## 4. Passo 2 -- TAG Release

**Pre-condicoes:**
- Passo 1 concluido e aprovado
- QA score dentro do threshold

**Acoes:**

### 2.1 Curador cria TAG vX.Y.Z no branch release/vX.Y.Z/main do rag-workspace

```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z -- {descricao breve}"
```

### 2.2 TAG dispara automaticamente pipeline de promocao

a) Le .beta.md do rag-workspace (TAG vX.Y.Z)
b) Remove marcadores LOCKED (conteudo preservado, marcadores removidos)
c) Enriquece front matter: adiciona campos de governanca (system, module, owner, team, QA score, qa_notes)
d) Gera .md final (fonte da verdade)
e) Cria PR automatico no rag-knowledge-base com os .md gerados

### 2.3 PR no rag-knowledge-base requer 2 aprovacoes

- PO: valida conteudo (correto, completo, alinhado com negocio)
- Arquiteto: valida integridade tecnica (front matter, schema, wikilinks, estrutura)

### 2.4 Apos aprovacao do PR

- Merge no main do rag-knowledge-base
- TAG vX.Y.Z espelhada no rag-knowledge-base
- Verificar sincronizacao de TAGs entre os 2 repos

**Criterios de saida:**
- [ ] TAG vX.Y.Z criada no rag-workspace
- [ ] Pipeline de promocao executou com sucesso
- [ ] .md finais gerados com front matter rico
- [ ] PR criado no rag-knowledge-base
- [ ] PR aprovado por PO + Arquiteto (2 aprovacoes)
- [ ] TAG vX.Y.Z espelhada no rag-knowledge-base

**Responsavel:** Curador (TAG), Pipeline (promocao), PO + Arquiteto (aprovacao)

## 5. Passo 3 -- Staging

**Pre-condicoes:**
- TAG vX.Y.Z criada no rag-knowledge-base
- Base Vetorial de staging disponivel e limpa (ou pronta para rebuild)

**Acoes:**

### 5.1 TAG dispara automaticamente pipeline de ingestao na Base Vetorial de staging

Seguindo as 7 etapas do ADR-006:
a) Descoberta: identificar .md na TAG
b) Parse: extrair front matter, headings, links internos
c) Chunking: quebrar por headings, herdar metadados
d) Embeddings: gerar embedding por chunk
e) Persistencia: upsert Document/Chunk, criar relacoes
f) Indexacao: vector index + indices auxiliares
g) Observabilidade: metricas de volume, falhas, latencia

### 5.2 Testes automatizados executam

a) **Golden Set:** executar pares pergunta/resposta contra staging
   - Recall@10 >= threshold da fase atual (ADR-008 Pilar 4)
   - Comparar com resultado anterior (nao pode ter regressao significativa)

b) **Testes de acesso por confidencialidade:**
   - Documento public acessivel via MCP publico
   - Documento restricted NAO acessivel via MCP publico
   - Filtros pre-retrieval funcionando

c) **Testes de integridade:**
   - Contagem de documentos na Base Vetorial confere com .md no Git
   - Contagem de chunks dentro da faixa esperada
   - Indices vetoriais funcionais (busca retorna resultados)

d) **Smoke tests dos agentes:**
   - Agentes de IA conseguem consultar via MCP
   - Respostas incluem citacoes de origem

### 5.3 Se qualquer teste falha

- Marcar como "staging-failed"
- Curador investiga causa raiz
- Correcao via nova TAG patch (vX.Y.Z+1)
- Repetir a partir do Passo 1 (para patch)

**Criterios de saida:**
- [ ] Pipeline de ingestao executou com sucesso em staging
- [ ] Golden Set Recall@10 >= threshold
- [ ] Testes de confidencialidade passaram (zero vazamentos)
- [ ] Testes de integridade passaram
- [ ] Smoke tests dos agentes passaram
- [ ] Zero testes falhando

**Responsavel:** Pipeline (ingestao), QA automatizado (testes), Curador (analise)

## 6. Passo 4 -- Producao

**Pre-condicoes:**
- Passo 3 concluido e TODOS os testes passando
- Nenhum teste em estado "staging-failed"

**Acoes:**

### 6.1 Aprovacao manual OBRIGATORIA

- PO aprova conteudo (valida que o que esta em staging e o esperado)
- Arquiteto aprova integridade tecnica
- Ambas aprovacoes registradas com timestamp e responsavel

### 6.2 Implantacao manual em producao

- NUNCA automatica (gate humano obrigatorio)
- Operador executa pipeline usando a MESMA TAG que passou em staging
- Pipeline e idempotente (ADR-006): mesma TAG = mesmo resultado
- Base Vetorial de producao e reconstruida (rebuild completo)

### 6.3 Pos-implantacao

a) release_version registrada na Base Vetorial (metadado que identifica qual TAG esta em producao)

b) Smoke test de producao:
   - Busca semantica funciona
   - Agentes retornam resultados com citacoes
   - Latencia dentro do esperado (p95 < 500ms)

c) Notificacao para stakeholders:
   - E-mail ou mensagem com: versao implantada, changelog resumido, responsavel pela implantacao

d) Monitoramento intensivo nas primeiras 2 horas:
   - Observar latencia, taxa de erro, volume de queries
   - Qualquer anomalia: avaliar rollback (ADR-J02)

**Criterios de saida:**
- [ ] Aprovacao de PO + Arquiteto registrada
- [ ] Pipeline de producao executou com sucesso
- [ ] release_version registrada
- [ ] Smoke test de producao passou
- [ ] Stakeholders notificados
- [ ] Monitoramento de 2 horas concluido sem anomalias

**Responsavel:** PO + Arquiteto (aprovacao), Curador/Ops (implantacao)

## 7. Tempos de Referencia

| Passo | Tempo Tipico |
|---|---|
| Passo 1 (Consolidacao) | 1-2 horas |
| Passo 2 (TAG + PR) | 2-4 horas (inclui aprovacoes) |
| Passo 3 (Staging + testes) | 1-4 horas (depende do volume) |
| Passo 4 (Producao) | 1-3 horas (inclui monitoramento) |
| **Total** | **5-13 horas (tipicamente 1 dia util)** |

## 8. Checklist Rapido para o Curador

- [ ] Todas branches mergeadas, zero PRs pendentes
- [ ] QA score >= 90% (ou 80-89% com qa_notes)
- [ ] Zero conflitos nao resolvidos
- [ ] TAG criada no workspace
- [ ] PR aprovado no knowledge-base (PO + Arquiteto)
- [ ] Staging: todos os testes passaram
- [ ] Producao: aprovacao manual obtida
- [ ] Producao: implantacao concluida + smoke test OK
- [ ] Stakeholders notificados
- [ ] 2 horas de monitoramento sem anomalias

## 9. Referencias

- ADR-010: Git Flow (Release-Based Flow, 4 passos de promocao)
- ADR-006: Pipeline de Ingestao (7 etapas, idempotencia)
- ADR-008: Governanca (Pilar 4 criterios, golden set, papeis)
- ADR-001: Pipeline 4 Fases (promocao .beta.md -> .md, TAGs)
- ADR-J02: Rollback de Release (quando staging ou producao falha)
- ADR-J03: Hotfix (correcao urgente sem esperar proxima release)

<!-- conversion_quality: 95 -->
