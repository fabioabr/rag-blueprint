---
id: ADR-E05
doc_type: adr
title: "Reingestão com Merge de Chunks Existentes"
system: RAG Corporativo
module: Reingestão
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - reingestao com merge
  - merge de chunks
  - edicao humana
  - blocos locked
  - conflito de versao
  - beta md
  - pipeline de 4 fases
  - fase 2
  - fonte atualizada
  - diff de fontes
  - analise de impacto
  - relatorio de reingestao
  - categoria sem conflito
  - categoria possivel conflito
  - categoria conflito locked
  - categoria conteudo novo
  - categoria conteudo removido
  - marcador conflict
  - marcador locked conflict
  - marcador new from source
  - marcador source removed
  - resolucao de conflitos
  - curadoria humana
  - protecao de conteudo
  - git diff
  - last human edit
  - last enrichment
  - front matter sources
  - captured at
  - origin
  - versao hibrida
  - pipeline de promocao
  - fase 3
  - pre condicao de promocao
  - base vetorial
  - etapa 1 descoberta
  - etapa 3 chunking
  - etapa 5 persistencia
  - classificacao updated
  - rastreabilidade
  - auditoria
  - pdf
  - confluence
  - regulamento
  - integridade da base vetorial
  - sobrescrita destrutiva
  - contexto de negocio
  - decisoes deliberadas
  - deteccao de edicao humana
  - fluxo de resolucao
  - prazo de resolucao
aliases:
  - "ADR-E05"
  - "Reingestão com Merge"
  - "Re-ingestão com Merge de Chunks"
  - "Merge de Fontes Atualizadas"
  - "Procedimento de Reingestão"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/draft/ADR-E05_reingestao_com_merge.txt"
source_beta_ids:
  - "BETA-E05"
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

# ADR-E05 — Reingestão com Merge de Chunks Existentes

| Campo | Valor |
|-------|-------|
| **Status** | Accepted |
| **Data da Decisão** | 2026-03-23 |
| **Decisor** | fabio |
| **Escopo** | Reingestão |

**Referências Cruzadas:**

- **Depende de:** [[ADR-001]], [[ADR-006]]
- **Relaciona-se:** [[ADR-E01]], [[ADR-E04]]

## Sumário

Este documento detalha o procedimento de reingestão quando uma fonte é atualizada (ex: PDF v2 substitui PDF v1). O objetivo é incorporar as mudanças da nova versão sem destruir edições humanas realizadas no .beta.md intermediário. O procedimento se aplica à Fase 2 do pipeline de 4 fases definido na [[ADR-001]].

## 1. Contexto: Por que Reingestão com Merge

No pipeline de 4 fases ([[ADR-001]]), fontes externas são convertidas em arquivos .beta.md que podem ser editados por humanos (Fase 2). Quando a fonte original muda (ex: nova versão de um PDF, atualização de página Confluence, nova versão de regulamento), o .beta.md correspondente precisa ser atualizado.

O problema: se o .beta.md já foi editado por humanos (correções, ajustes, complementos, blocos LOCKED), simplesmente sobrescrever o arquivo com a nova conversão destruiria todo o trabalho humano.

**Solução:** reingestão com merge — um procedimento que identifica o que mudou na fonte, aplica as mudanças no .beta.md preservando edições humanas, e sinaliza conflitos para revisão manual.

## 2. Procedimento em 3 Passos

### Passo 1: Diff de fontes

Comparar a versão anterior (v1) com a versão atualizada (v2) da fonte:

1. Recuperar a versão anterior da fonte (registrada no campo `sources` do front matter do .beta.md, com `captured_at` e `origin`).
2. Obter a nova versão da fonte.
3. Gerar lista de mudanças entre v1 e v2:
   - Trechos adicionados (presentes em v2, ausentes em v1).
   - Trechos removidos (presentes em v1, ausentes em v2).
   - Trechos modificados (presentes em ambos, mas com conteúdo diferente).
   - Trechos inalterados (idênticos em v1 e v2).
4. Registrar o diff para auditoria e rastreabilidade.

### Passo 2: Análise de impacto

Para cada trecho do .beta.md existente, classificar o impacto da mudança:

**Categoria A — Sem conflito:**
- Condição: trecho NÃO foi editado por humano E fonte mudou nesse trecho.
- Ação: atualizar automaticamente. O conteúdo gerado pela IA é substituído pelo novo conteúdo gerado a partir da fonte atualizada.
- Risco: baixo (nenhum trabalho humano perdido).

**Categoria B — Possível conflito:**
- Condição: trecho FOI editado por humano E fonte mudou nesse mesmo trecho.
- Ação: NÃO sobrescrever. Inserir alerta inline no .beta.md:

```html
<!-- CONFLICT -->
<!-- FONTE ATUALIZADA: [trecho novo da fonte v2] -->
<!-- VERSÃO ATUAL: [trecho editado pelo humano] -->
<!-- CONFLICT:END -->
```

O humano deve revisar e decidir: aceitar a versão da fonte, manter sua edição, ou criar uma versão híbrida.

**Categoria C — Conflito em bloco LOCKED:**
- Condição: trecho está dentro de um bloco `<!-- LOCKED:START -->` e a fonte mudou nesse trecho.
- Ação: NÃO alterar o conteúdo do bloco LOCKED (respeitar a proteção). Registrar alerta separado:

```html
<!-- LOCKED-CONFLICT -->
<!-- O bloco LOCKED abaixo pode estar desatualizado em relação à fonte. -->
<!-- Fonte atualizada em: [data] -->
<!-- Trecho da fonte v2: [resumo da mudança] -->
<!-- LOCKED-CONFLICT:END -->
```

O humano decide se remove o lock e atualiza, ou mantém a versão locked.

**Categoria D — Conteúdo novo:**
- Condição: trecho existe em v2 mas não em v1 (seção adicionada na fonte).
- Ação: adicionar ao .beta.md em posição lógica (após seção relacionada ou ao final do documento). Marcar como novo:

```html
<!-- NEW-FROM-SOURCE: [data] -->
[conteúdo novo]
<!-- NEW-FROM-SOURCE:END -->
```

**Categoria E — Conteúdo removido:**
- Condição: trecho existe em v1 mas não em v2 (seção removida da fonte).
- Ação: NÃO remover automaticamente do .beta.md. Inserir alerta:

```html
<!-- SOURCE-REMOVED -->
<!-- Este trecho foi removido da fonte v2. Revisar se deve ser mantido. -->
<!-- SOURCE-REMOVED:END -->
```

### Passo 3: Relatório de reingestão

Gerar relatório com:

- Total de trechos atualizados automaticamente (Categoria A).
- Total de conflitos para revisão humana (Categoria B).
- Total de locks potencialmente desatualizados (Categoria C).
- Total de conteúdos novos adicionados (Categoria D).
- Total de conteúdos removidos da fonte sinalizados (Categoria E).

O relatório serve para:
- Priorizar revisão humana (conflitos primeiro).
- Identificar .beta.md com muitos locks desatualizados.
- Medir o impacto de cada atualização de fonte.
- Auditoria do processo de reingestão.

## 3. Detecção de Edição Humana

Para classificar corretamente os trechos nas categorias acima, o pipeline precisa distinguir entre conteúdo gerado pela IA e conteúdo editado por humano. Mecanismos:

1. **Blocos LOCKED:** Trechos dentro de `<!-- LOCKED:START -->` / `<!-- LOCKED:END -->` são explicitamente protegidos. Detecção direta.

2. **Git diff como safety net:** Comparar a versão original gerada pela IA (commit de geração) com a versão atual (HEAD). Diferenças fora de blocos LOCKED indicam edição humana. Essa edição humana SEMPRE prevalece sobre a re-geração da IA.

3. **Campo `last_human_edit` no front matter:** Se `last_human_edit` > `last_enrichment`, o .beta.md foi editado por humano desde a última rodada de IA.

## 4. Resolução de Conflitos

Conflitos (Categoria B e C) devem ser resolvidos por humanos. O pipeline NÃO tenta resolver conflitos automaticamente. Motivos:

- Edições humanas podem conter contexto de negócio que a IA não possui.
- Blocos LOCKED representam decisões deliberadas de proteção.
- Resolução automática poderia destruir trabalho curado.

### Fluxo de resolução

1. Pipeline gera .beta.md com alertas inline (CONFLICT, LOCKED-CONFLICT).
2. Relatório lista todos os conflitos pendentes.
3. Humano (PO, analista, curador) revisa cada conflito:
   - Aceita versão da fonte: remove alerta, atualiza trecho.
   - Mantém edição humana: remove alerta, mantém trecho original.
   - Cria versão híbrida: combina ambas versões, remove alerta.
4. Se conflito está em bloco LOCKED:
   - Humano decide se remove o lock para atualizar.
   - Ou mantém o lock e registra que está ciente da desatualização.
5. Após resolução, atualizar `last_human_edit` no front matter.

### Prazo para resolução

Conflitos não resolvidos não bloqueiam o pipeline. Porém, documentos com conflitos pendentes NÃO devem ser promovidos para .md final (Fase 3). O pipeline de promoção verifica ausência de marcadores CONFLICT como pré-condição.

## 5. Impacto na Cadeia de Ingestão

Após a reingestão com merge no .beta.md (Fase 2), o fluxo normal segue:

1. .beta.md atualizado é revisado (conflitos resolvidos).
2. Promoção para .md final (Fase 3) quando aprovado.
3. Release tag criada no repositório knowledge-base.
4. Pipeline de ingestão na Base Vetorial (Fase 4, [[ADR-006]]) processa o .md atualizado:
   - Etapa 1 (Descoberta): hash mudou -> classificado como UPDATED.
   - Etapa 3 (Chunking): novos chunks gerados.
   - Etapa 5 (Persistência): chunks antigos removidos, novos persistidos.

O merge na Fase 2 garante que a cadeia completa funciona sem perda de edições humanas, mantendo a rastreabilidade de origem e a integridade da Base Vetorial.

<!-- conversion_quality: 95 -->
