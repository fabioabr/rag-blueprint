---
id: BETA-B06
title: "Política de Temporalidade do Conhecimento"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-B06_politica_temporalidade.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags: [temporalidade conhecimento, valid from, valid until, supersedes, superseded by, camadas temporais, front matter temporal, base vetorial relacoes, retrieval filtro temporal, deprecacao documento, document family, version of, ranking reduzido, cadeia supersedes, versionamento semantico, politica programada, vigencia documento, consulta historica, filtro pre-retrieval, agente temporal, pipeline promocao, pipeline ingestao, neo4j relacoes, effective date, current version, status deprecated, regras deprecacao, validacao temporal, data iso 8601, md final temporal, beta-md campos ausentes, knowledge base, grafo conhecimento, diff semantico, documento vigente, documento historico, regulacao, lgpd, bacen, rollback, release tag, rebuild base vetorial, idempotencia, contexto temporal, reranking penalidade, auditoria, rastreabilidade, navegacao versoes, familia documento, promocao fase 3, ingestao fase 4]
aliases:
  - "ADR-B06"
  - "Politica Temporalidade Conhecimento"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## 1. Visão Geral

O conhecimento corporativo não é estático. Leis mudam, regulações são atualizadas, políticas internas evoluem, sistemas são substituídos. O pipeline de conhecimento precisa representar essa temporalidade de forma explícita.

ADR-001 define um modelo em **3 CAMADAS** para versionamento semântico do conhecimento, garantindo que agentes possam responder tanto sobre o estado atual quanto sobre estados históricos.

## 2. Campos Temporais no Front Matter (.md final)

### 2.1 valid_from

- **Tipo:** string (data ISO 8601), formato AAAA-MM-DD
- **Obrigatório:** sim (bloqueante no `.md` final)
- **Validação:** data válida, não futura (exceção: políticas programadas)
- **Exemplo:** `valid_from: "2026-01-01"`

Define a data a partir da qual o documento passa a ser considerado **VIGENTE**. Antes desta data, o documento existe mas não deve ser retornado como referência válida.

**Exceção:** políticas programadas podem ter `valid_from` no futuro (ex: nova regulamentação que entra em vigor em data específica).

### 2.2 valid_until

- **Tipo:** string (data ISO 8601) ou null
- **Obrigatório:** não (`null` = vigente indefinidamente)
- **Validação:** se presente, data válida e > `valid_from`
- **Exemplo:** `valid_until: null`
- **Exemplo:** `valid_until: "2026-12-31"`

Define a data até a qual o documento é considerado vigente. Após esta data, o documento não deve ser retornado como referência principal (mas pode ser retornado como referência histórica se solicitado).

`null` significa que o documento é vigente por tempo indeterminado — até que seja explicitamente deprecado.

### 2.3 supersedes

- **Tipo:** string (`DOC-{NNNNNN}`)
- **Obrigatório:** não (apenas quando substitui outro documento)
- **Validação:** formato `DOC-{NNNNNN}`, documento referenciado deve existir
- **Exemplo:** `supersedes: "DOC-000023"`

Identificador do documento ANTERIOR que este documento substitui. Gera relação `SUPERSEDES` na Base Vetorial.

### 2.4 superseded_by

- **Tipo:** string (`DOC-{NNNNNN}`)
- **Obrigatório:** sim quando `status = deprecated`
- **Validação:** formato `DOC-{NNNNNN}`, documento referenciado deve existir
- **Exemplo:** `superseded_by: "DOC-000456"`

Identificador do documento que SUBSTITUI este documento. Obrigatório quando o documento é deprecado, garantindo que sempre haja um ponteiro para a versão corrente.

**Regra:** quando `superseded_by` é preenchido, `status` DEVE ser `deprecated` e `valid_until` DEVE ser preenchido.

## 3. As 3 Camadas de Temporalidade

### 3.1 Camada 1 — No .md (front matter)

**Onde:** Campos `valid_from`, `valid_until`, `supersedes`, `superseded_by` no front matter YAML do `.md` final.

**Exemplo:**

```yaml
valid_from: "2026-01-01"
valid_until: null
superseded_by: null
supersedes: "DOC-000123"
```

**Responsabilidade:**

- Pipeline de promoção (Fase 3) preenche estes campos
- Validação automática no schema de front matter rico
- Humano pode sugerir datas durante edição do `.beta.md`

### 3.2 Camada 2 — Na Base Vetorial (relações temporais)

**Onde:** Grafo Neo4j, relações e nós específicos.

**Relações:**

- `(:Document)-[:SUPERSEDES {effective_date}]->(:Document)` — Conecta versão nova à versão anterior com data de efeito.
- `(:Document)-[:VERSION_OF]->(:DocumentFamily)` — Conecta todas as versões de um documento a uma "família".

**Nó específico:**

- `:DocumentFamily` — Atributos: `family_id`, `title`, `current_version`. Agrupa todas as versões de um mesmo documento conceitual.

**Responsabilidade:**

- Pipeline de ingestão (Fase 4) cria estas relações
- Atualiza `current_version` no DocumentFamily quando nova versão é ingerida

### 3.3 Camada 3 — No retrieval (filtro temporal)

**Onde:** Lógica do agente/retriever no momento da consulta.

**Regras:**

1. Detectar contexto temporal na pergunta do usuário
   - Ex: "como era o processo de cobrança em 2025?"
   - Ex: "qual a política vigente de férias?"
2. Filtrar por `valid_from`/`valid_until` ANTES da busca vetorial (filtro pré-retrieval, não pós-retrieval)
3. Se não houver contexto temporal explícito, assumir **DATA ATUAL** (retornar apenas documentos vigentes)
4. Agentes instruídos a citar vigência e versões anteriores nas respostas

**Exemplos de comportamento:**

**Pergunta:** "qual a política de férias?"
- Filtro: `valid_from <= hoje AND (valid_until IS NULL OR valid_until >= hoje)`
- Retorna: versão vigente

**Pergunta:** "como era a política de férias em 2024?"
- Filtro: `valid_from <= 2024-12-31 AND (valid_until IS NULL OR valid_until >= 2024-01-01)`
- Retorna: versão vigente em 2024

**Pergunta:** "o que mudou na política de férias?"
- Busca: DocumentFamily -> todas as versões -> diff semântico
- Retorna: comparação entre versões

## 4. Regras de Deprecação

### 4.1 Quando deprecar

Um documento é deprecado quando:

- Uma nova versão do mesmo documento é criada (substitui)
- A política/processo que ele descreve foi descontinuada
- A informação se tornou obsoleta sem substituta

### 4.2 Processo de deprecação

1. Criar novo documento (`.md` final) com `supersedes` apontando para o antigo
2. No documento antigo, preencher:
   - `status: deprecated`
   - `superseded_by: DOC-{NNNNNN}` (novo documento)
   - `valid_until:` data de efeito da deprecação
3. Na Base Vetorial:
   - Criar relação `SUPERSEDES` entre novo e antigo
   - Atualizar `current_version` no DocumentFamily
   - Documento deprecated mantido com **RANKING REDUZIDO** (não removido)

### 4.3 Ranking de documentos deprecated

Documentos deprecated **NÃO** são removidos da Base Vetorial. Eles são mantidos com ranking reduzido para:

- Consultas históricas ("como era antes?")
- Rastreabilidade e auditoria
- Contexto para o agente ("isso mudou em tal data")

Na prática: documentos deprecated recebem penalidade no reranking, aparecendo abaixo de documentos vigentes. Só são priorizados quando o contexto temporal da pergunta exige.

## 5. Cadeia Supersedes

A cadeia supersedes permite navegar toda a história de um documento:

```
DOC-000001 (v1, deprecated)
  superseded_by: DOC-000023
    |
    v
DOC-000023 (v2, deprecated)
  supersedes: DOC-000001
  superseded_by: DOC-000042
    |
    v
DOC-000042 (v3, approved, vigente)
  supersedes: DOC-000023
  superseded_by: null
```

Na Base Vetorial, o DocumentFamily agrupa todos:

```
:DocumentFamily {
  family_id: "FAM-001",
  title: "Processo de Conciliação Bancária",
  current_version: "DOC-000042"
}

DOC-000001 -[:VERSION_OF]-> FAM-001
DOC-000023 -[:VERSION_OF]-> FAM-001
DOC-000042 -[:VERSION_OF]-> FAM-001
DOC-000042 -[:SUPERSEDES {effective_date: "2026-01-15"}]-> DOC-000023
DOC-000023 -[:SUPERSEDES {effective_date: "2025-06-01"}]-> DOC-000001
```

## 6. Regras de Validação Temporal

| Regra | Tipo |
|-------|------|
| `valid_from` obrigatório no `.md` final | Bloqueante |
| `valid_from` não futura (exceto políticas) | Bloqueante |
| `valid_until` > `valid_from` (se presente) | Bloqueante |
| `superseded_by` obrigatório se deprecated | Bloqueante |
| `supersedes` referencia documento existente | Bloqueante |
| `valid_until` preenchido se `superseded_by` presente | Bloqueante |

## 7. Campos Ausentes no .beta.md

Os campos temporais (`valid_from`, `valid_until`, `supersedes`, `superseded_by`) **NÃO** existem no front matter leve do `.beta.md`. São preenchidos exclusivamente na Fase 3 (promoção) pelo pipeline.

**Motivo:** durante a elaboração do `.beta.md`, o conteúdo ainda está em construção e não faz sentido definir vigência. A temporalidade só é relevante quando o documento é promovido para `.md` final e passa a ser a "informação verdade".

<!-- conversion_quality: 95 -->
