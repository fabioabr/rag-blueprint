---
id: ADR-B07
doc_type: adr
title: "Regras de Edição de Arquivos .beta.md (Blocos LOCKED)"
system: RAG Corporativo
module: Edição Beta
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - blocos locked
  - edição beta md
  - locked start
  - locked end
  - pipeline enriquecimento
  - edição humana
  - obsidian edição
  - conflito merge
  - re ingestão
  - ai suggestion
  - conflict marcador
  - locked conflict
  - safety net git diff
  - proteção conteúdo
  - sobrescrita ia
  - autor lock
  - data lock
  - comentário html
  - conteúdo validado
  - conteúdo protegido
  - regras ia
  - regras humano
  - pipeline fase 2
  - rag workspace
  - enriquecimento automático
  - last enrichment
  - tags enriquecimento
  - decisão arquitetural
  - definição negócio
  - especialista domínio
  - rascunho inicial
  - front matter schema
  - trecho sem conflito
  - trecho com conflito
  - fonte atualizada
  - relatório re ingestão
  - conflitos pendentes
  - locks desatualizados
  - locks grandes
  - warning 80 porcento
  - curadoria humana
  - prevalência humano
  - commit usuário
  - diagrama ascii
  - blocos aninhados
  - múltiplos blocos
  - markdown válido
  - reading view
  - resumo regras
  - ator humano
  - ator ia
  - proteção trabalho humano
  - edição livre
  - mecanismo proteção
aliases:
  - "ADR-B07"
  - "Regras Edição Blocos LOCKED"
  - "Blocos LOCKED Beta"
  - "Proteção Conteúdo Humano"
  - "Edição Arquivos Beta MD"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-B07_edicao_arquivos_beta.beta.md"
source_beta_ids:
  - "BETA-B07"
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

# ADR-B07 — Regras de Edição de Arquivos .beta.md (Blocos LOCKED)

## 1. Visão Geral

Arquivos `.beta.md` no repositório rag-workspace são editados por **DOIS atores**: humanos (via Obsidian) e pipeline de IA (enriquecimento automático na Fase 2). O mecanismo de blocos LOCKED resolve o conflito entre edição humana e enriquecimento automático, garantindo que trabalho humano validado não seja sobrescrito pela IA.

## 2. Sintaxe dos Blocos LOCKED

### 2.1 Formato

```html
<!-- LOCKED:START autor=fabio data=2026-03-21 -->
Este trecho foi validado e não deve ser alterado pela IA.
Pode conter múltiplos parágrafos, tabelas, code blocks, etc.
<!-- LOCKED:END -->
```

### 2.2 Atributos obrigatórios

- **autor:** identificador do humano que criou o lock (string, sem espaços)
- **data:** data em que o lock foi criado, formato AAAA-MM-DD

### 2.3 Formato técnico

- Usa comentários HTML (`<!-- -->`), invisíveis no Obsidian reading view
- Marcadores START e END devem estar em linhas separadas
- O conteúdo entre START e END pode ser qualquer Markdown válido
- Múltiplos blocos LOCKED podem existir no mesmo documento
- Blocos LOCKED **NÃO** podem ser aninhados (um dentro do outro)
- O bloco pode conter headings, tabelas, code blocks, listas, etc.

## 3. Regras para a IA (Pipeline de Enriquecimento)

### 3.1 O que a IA PODE fazer

- Adicionar conteúdo NOVO fora dos blocos LOCKED
- Reorganizar conteúdo fora dos blocos LOCKED
- Sugerir mudanças em blocos LOCKED como COMENTÁRIO SEPARADO (nunca alterar o bloco diretamente)
- Atualizar campo `last_enrichment` no front matter
- Adicionar/melhorar tags no front matter
- Enriquecer conteúdo não-locked com informações adicionais

### 3.2 O que a IA NÃO PODE fazer (NUNCA)

- Alterar qualquer conteúdo dentro de `LOCKED:START` / `LOCKED:END`
- Remover um bloco LOCKED
- Mover um bloco LOCKED para outra posição
- Inserir conteúdo DENTRO de um bloco LOCKED
- Alterar os atributos (autor, data) de um bloco LOCKED
- Dividir ou juntar blocos LOCKED

### 3.3 Como a IA sugere mudanças em blocos LOCKED

Se a IA identifica que um bloco LOCKED contém informação desatualizada ou incorreta, ela deve:

1. **NÃO** alterar o bloco
2. Inserir um comentário APÓS o bloco LOCKED com a sugestão:

```html
<!-- LOCKED:END -->

<!-- AI-SUGGESTION data=2026-03-22 -->
<!-- Sugestão: o trecho acima menciona "versão 2.0", mas a versão
     atual é 3.0 conforme fonte X. Considerar atualizar. -->
```

O humano decide se aceita a sugestão e atualiza o bloco LOCKED.

## 4. Regras para Humanos (Edição via Obsidian)

### 4.1 Criar um bloco LOCKED

O humano pode marcar qualquer trecho como LOCKED a qualquer momento. Basta inserir os marcadores:

```html
<!-- LOCKED:START autor=maria data=2026-03-21 -->
(conteúdo protegido)
<!-- LOCKED:END -->
```

### 4.2 Remover um bloco LOCKED

O humano pode remover o lock a qualquer momento, simplesmente apagando as linhas `<!-- LOCKED:START -->` e `<!-- LOCKED:END -->`. O conteúdo permanece, mas volta a ser editável pela IA.

### 4.3 Editar conteúdo dentro de um bloco LOCKED

O humano pode editar livremente o conteúdo dentro de um bloco LOCKED. Recomendação: atualizar o atributo "data" quando fizer edições significativas.

### 4.4 Quando usar LOCKED

**Recomendado para:**

- Decisões arquiteturais validadas por comitê
- Definições de negócio aprovadas pelo PO
- Trechos revisados e confirmados por especialista de domínio
- Diagramas ASCII que representam decisões finais
- Qualquer conteúdo que o humano considera "pronto" e não quer que a IA altere

**NÃO recomendado para:**

- Rascunhos iniciais (deixar a IA ajudar)
- Conteúdo que o humano sabe que está incompleto
- Front matter (protegido por schema, não por LOCKED)

## 5. Comportamento na Re-Ingestão (Merge)

Quando uma fonte é atualizada (ex: PDF v2 substitui PDF v1), o pipeline de re-ingestão precisa lidar com blocos LOCKED:

### 5.1 Trecho SEM conflito (não editado por humano, sem LOCKED)

**Ação:** atualizar automaticamente com conteúdo da nova fonte. Nenhuma intervenção humana necessária.

### 5.2 Trecho COM possível conflito (editado por humano, SEM LOCKED)

**Ação:** inserir alerta inline no `.beta.md`:

```html
<!-- CONFLICT fonte=pdf_v2 data=2026-03-22 -->
<!-- Trecho abaixo foi editado por humano mas a fonte mudou.
     Revisar e decidir qual versão manter. -->
(conteúdo do humano permanece)
<!-- CONFLICT:NEW -->
(conteúdo da nova fonte)
<!-- CONFLICT:END -->
```

Humano deve revisar e resolver o conflito.

### 5.3 Trecho em bloco LOCKED com fonte desatualizada

**Ação:** NÃO alterar o bloco LOCKED. Inserir alerta externo:

```html
<!-- LOCKED-CONFLICT fonte=pdf_v2 data=2026-03-22 -->
<!-- ATENÇÃO: A fonte deste bloco LOCKED foi atualizada.
     O conteúdo do bloco pode estar desatualizado.
     Revisar e decidir se o lock deve ser mantido. -->
```

O bloco LOCKED permanece **INTACTO**. O humano decide se atualiza.

### 5.4 Safety net via git diff

Como proteção adicional, o pipeline de re-ingestão compara o `.beta.md` antes e depois via `git diff`. Qualquer edição humana detectada (commits por usuário humano) **SEMPRE** prevalece sobre o conteúdo gerado pela IA.

**Regra:** na dúvida, preservar o trabalho humano.

## 6. Relatório de Re-Ingestão

Após cada re-ingestão, o pipeline gera relatório com:

- Quantos trechos atualizados automaticamente
- Quantos conflitos para revisão humana (CONFLICT)
- Quantos blocos LOCKED com fonte desatualizada (LOCKED-CONFLICT)
- Lista de documentos afetados
- Contagem de conflitos pendentes (não resolvidos)

## 7. Riscos e Mitigações

### 7.1 Blocos LOCKED esquecidos

- **Risco:** Humano edita conteúdo importante sem marcar LOCKED. Na próxima re-ingestão, a IA sobrescreve.
- **Mitigação:** Safety net via git diff. Edição humana detectada por commit de usuário humano SEMPRE prevalece.

### 7.2 Acúmulo de conflitos

- **Risco:** Muitos alertas CONFLICT não revisados, poluindo o documento.
- **Mitigação:** Relatório de re-ingestão com contagem de conflitos pendentes. Alertas em dashboard de saúde da KB.

### 7.3 Locks desatualizados

- **Risco:** Bloco LOCKED com informação obsoleta permanece "protegido" indefinidamente.
- **Mitigação:** Alerta LOCKED-CONFLICT quando fonte muda. Revisão periódica de locks antigos (ex: locks com data > 6 meses).

### 7.4 Blocos LOCKED muito grandes

- **Risco:** Humano marca documento inteiro como LOCKED, impedindo qualquer enriquecimento pela IA.
- **Mitigação:** Recomendação de boas práticas (lock trechos, não documentos inteiros). Pipeline emite warning se > 80% do documento estiver locked.

## 8. Resumo de Regras

| Ator | Pode criar LOCKED | Pode remover LOCKED | Pode editar dentro | Pode editar fora |
|------|-------------------|---------------------|--------------------|------------------|
| Humano | Sim | Sim | Sim | Sim |
| IA | Não | Não | **NÃO (nunca)** | Sim |

| Situação | Ação do pipeline |
|----------|------------------|
| Conteúdo fora de LOCKED | Atualiza livremente |
| Conteúdo dentro de LOCKED | NÃO toca, sugere via comentário |
| Conflito sem LOCKED | Insere `<!-- CONFLICT -->` |
| Conflito com LOCKED | Insere `<!-- LOCKED-CONFLICT -->` (externo) |
| Git diff detecta edit humano | Preserva versão humana (safety net) |

## 9. Referências

- [[ADR-001]] — Pipeline de Geração de Conhecimento em 4 Fases
- [[ADR-005]] — Front Matter: Contrato de Metadados
- [[ADR-008]] — Governança: Papéis, Ciclo de Vida e Rollback
- [[ADR-E05]] — Re-Ingestão com Merge

<!-- conversion_quality: 95 -->
