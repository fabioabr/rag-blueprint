---
id: ADR-001
doc_type: adr
title: "Pipeline de Geração de Conhecimento em 4 Fases"
system: RAG Corporativo
module: Pipeline de Conhecimento
domain: arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-21
tags:
  - pipeline geracao conhecimento
  - 4 fases
  - rag corporativo
  - base vetorial
  - mineracao preparacao
  - fonte da verdade
  - md final
  - repositorios separados
  - rag workspace
  - rag knowledge base
  - blocos locked
  - edicao humana
  - curadoria humana
  - front matter leve
  - front matter rico
  - conversion quality
  - gate de qualidade
  - qa score
  - temporalidade conhecimento
  - valid from
  - valid until
  - document family
  - supersedes
  - re ingestao merge
  - diff inteligente
  - locked conflict
  - segregacao acesso
  - wikilinks segregados
  - obsidian
  - pipeline promocao
  - release tag
  - service account
  - pr aprovacao
  - pilares pipeline
  - segregacao responsabilidades
  - desacoplamento etapas
  - observabilidade governanca
  - clareza informacao
  - versionamento git
  - rastreabilidade origem
  - reprodutibilidade
  - bronze prata ouro
  - selecao insumos
  - manifesto ingestao
  - confidentiality
  - rollout faseado
  - mvp metadados knowledge graph graphrag
  - compliance regulatorio
  - bacen lgpd
  - auditabilidade
  - enriquecimento ia
  - fonte bruta
  - beta md
aliases:
  - "ADR-001"
  - "Pipeline 4 Fases"
  - "Pipeline de Geração de Conhecimento"
  - "Knowledge Generation Pipeline"
  - "P4F"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-001_pipeline_geracao_conhecimento_4_fases.beta.md"
source_beta_ids:
  - "BETA-001"
conversion_pipeline: promotion-pipeline-v2
conversion_quality: 98
converted_at: 2026-03-23
qa_score: null
qa_date: null
qa_status: pending
created_at: 2026-03-21
updated_at: 2026-03-23
valid_from: 2026-03-21
valid_until: null
---

# ADR-001 — Pipeline de Geração de Conhecimento em 4 Fases

## Cabeçalho

| Campo | Valor |
|-------|-------|
| **Status** | proposed |
| **Data** | 21/03/2026 |
| **Revisão** | 23/03/2026 (reescrita para separar decisão de processo) |
| **Decisor** | Fabio A. B. Rodrigues |
| **Escopo** | RAG Corporativo — Pipeline completo de geração de conhecimento |
| **Relaciona-se** | [[ADR-002]] (Soberania de Dados), [[ADR-003]] (Modelo de Dados), [[ADR-005]] (Front Matter), [[ADR-006]] (Pipeline de Ingestão), [[ADR-011|ADR-011 — Segregação de KBs]] |

## 1. Sumário

Decidimos adotar um pipeline de geração de conhecimento em **4 fases** com camada intermediária `.beta.md` (editável por humanos e IA) e separação física em **2 repositórios** (workspace editável + knowledge-base imutável). O `.md` final é a **fonte da verdade** para o RAG, gerado exclusivamente por pipeline automatizado e nunca editado manualmente.

## 2. Contexto

O projeto RAG Corporativo precisa transformar fontes diversas (PDFs, e-mails, Confluence, transcrições, planilhas, etc.) em uma base de conhecimento estruturada para alimentar uma Base Vetorial (Neo4j com grafo + vetor).

Um modelo anterior (Bronze/Prata/Ouro, inspirado em data lakehouse) definiu 3 camadas, mas não endereçava lacunas críticas:

1. **Edição humana** — Como permitir que POs, analistas e especialistas enriqueçam o conteúdo gerado pela IA sem conflitos de sobrescrita.
2. **Fonte da verdade** — Qual artefato é a referência autoritativa para o RAG. Sem definição clara, diferentes versões do mesmo documento circulam sem controle.
3. **Segregação de acesso** — Como garantir que a fonte da verdade não seja alterada manualmente, mantendo auditabilidade para ambientes regulados (BACEN, LGPD).
4. **Temporalidade** — Como representar informações que mudam ao longo do tempo (leis, regulações, políticas internas) sem perder histórico.
5. **Re-ingestão** — Como lidar com atualizações de fontes sem destruir edições humanas já validadas.

### Pilares que guiam o pipeline

| Pilar | Descrição |
|-------|-----------|
| **A** | Segregação de responsabilidades (quem faz o que em cada etapa) |
| **B** | Desacoplamento de etapas (falha em uma não impacta outra) |
| **C** | Método garantidor de qualidade (gates entre fases) |
| **D** | Observabilidade e Governança (rastreio, métricas, auditoria) |
| **E** | Clareza da informação (documentos autoexplicativos) |
| **F** | Versionamento (controle de versão via Git) |
| **G** | Rastreabilidade de origem (linhagem completa) |
| **H** | Reprodutibilidade (mesmo input = mesmo output) |

## 3. Decisão

### 3.1. Pipeline em 4 fases sequenciais

O pipeline é composto por 4 fases com fronteiras claras e gates de qualidade:

**Fase 1 — Seleção dos Insumos**
Definir quais fontes são relevantes para o contexto de negócio. Disponibilizar arquivos para processamento com manifesto de ingestão (origem, formato, data, responsável, confidencialidade). Fontes: externas (internet, documentações de fornecedores, leis), internas (Sharepoint, Confluence, Jira, e-mails, transcrições, PDFs, planilhas), repositórios de código, wikis, post-mortems.

**Fase 2 — Mineração e Preparação (.beta.md)**
Pipeline de IA gera/atualiza `.beta.md` a partir dos insumos. Humanos editam via Obsidian (compatível, com front matter leve). Blocos `LOCKED` protegem edições humanas contra sobrescrita da IA. Múltiplas rodadas de enriquecimento (IA + humano) até consolidação.

**Fase 3 — Geração da Origem Consolidada (.md final)**
Pipeline promove `.beta.md` para `.md` final com front matter rico. O `.md` final **NUNCA** é editado manualmente — sempre gerado por pipeline. Aprovação via PR no repositório knowledge-base (PO + Arquiteto). Release com tag para controlar o que entra na Base Vetorial. Gate de qualidade: QA score >= 90%. Documentos com score 80-89% podem ser promovidos se motivos estiverem documentados em `qa_notes`. Abaixo de 80% é bloqueante.

**Fase 4 — Geração do RAG (Base Vetorial)**
Pipeline de ingestão ([[ADR-006]]) constrói/atualiza banco vetorial, disparado por release tag no repositório knowledge-base. Versão da release registrada no header dos dados na Base Vetorial.

**Por que 4 fases e não 3 (Bronze/Prata/Ouro):**
- O modelo de 3 camadas não previa edição humana intermediária
- Sem camada beta, qualquer correção exige reprocessamento completo
- A fase 2 (beta) permite coexistência de IA e curadoria humana
- A separação entre beta (editável) e final (imutável) garante que a fonte da verdade nunca é corrompida por edição manual

Para detalhamento de estrutura de pastas dos repositórios: ver DOC-A01 (Guia de Estrutura de Pastas)

### 3.2. Dois repositórios fisicamente separados

| Repositório | Propósito | Quem edita |
|-------------|-----------|------------|
| `rag-workspace` | `.beta.md` em trabalho, fontes brutas, logs | Humanos (Obsidian) + IA (pipeline) |
| `rag-knowledge-base` | `.md` finais (fonte da verdade), apresentações, releases | Pipeline apenas (service account) |

**Por que 2 repos e não 1 com branch protection:**
- Branches podem confundir equipes não-técnicas
- Risco de merge acidental em repositório único
- Para ambiente regulado (BACEN, LGPD), separação física é mais segura e auditável do que separação lógica por branches
- Obsidian com Git requer plugin; separação física simplifica o setup

Wikilinks são segregados: `.beta.md` só navega para `.beta.md`, `.md` só navega para `.md`. Isso evita referências cruzadas entre artefatos de maturidade diferente.

Para detalhamento de estrutura de pastas: ver DOC-A01 (Guia de Estrutura de Pastas)

### 3.3. Proteção de edições humanas (Blocos LOCKED)

Humanos podem marcar trechos no `.beta.md` como protegidos contra sobrescrita da IA usando marcadores `LOCKED:START` / `LOCKED:END`.

**Regras:**
- IA pode adicionar conteúdo novo fora dos blocos locked
- IA **NUNCA** altera conteúdo dentro de `LOCKED:START`/`LOCKED:END`
- IA pode sugerir mudanças em blocos locked como comentário separado
- Humano pode remover o lock a qualquer momento

**Por que blocos inline e não arquivos separados por autor:**
- Separar em `.ai.beta.md` + `.human.beta.md` triplica arquivos
- Merge entre dois arquivos é mais complexo que proteção inline
- Blocos LOCKED são granulares (protegem trechos, não documentos inteiros)
- Humano vê e edita um único arquivo no Obsidian

Para regras detalhadas de edição de arquivos beta: ver RNB-B07 (Edição de Arquivos Beta)

### 3.4. Front matter em dois níveis (leve + rico)

O `.beta.md` usa **front matter leve** (`id`, `title`, `domain`, `sources`, `tags`, `status`, `confidentiality`, `last_enrichment`, `last_human_edit`). O `.md` final usa **front matter rico** com governança completa (`system`, `module`, `owner`, `team`, QA, temporalidade, linhagem).

**Exceção:** `confidentiality` é incluído no front matter leve porque [[ADR-002]] precisa dele para rotear pela trilha correta (cloud vs on-prem) desde a Fase 2. Segurança não pode esperar a Fase 3.

Para schemas completos: ver [[ADR-005|ADR-005 — Front Matter como Contrato de Metadados]].

### 3.5. conversion_quality como gate de automação

Cada fonte convertida para `.beta.md` recebe um score `conversion_quality` (0-100%) que expressa confiança na fidelidade da extração. O score é calculado como média ponderada de sinais específicos por formato de origem.

**Uso do score:**
- **>= 80%:** ingestão automática no `.beta.md`
- **30-79%:** `.beta.md` gerado com `status: draft`, revisão humana obrigatória
- **< 30%:** fonte rejeitada, log de erro gerado

Para detalhamento de sinais por formato: ver SPEC-B05 (Conversão de Formatos RAW)

### 3.6. Temporalidade do conhecimento

Modelo em 3 camadas para versionamento semântico de documentos:

**Camada 1 — No `.md` (front matter):**
`valid_from`, `valid_until` (null = vigente), `superseded_by`, `supersedes`.

**Camada 2 — Na Base Vetorial (relações temporais):**
- `(:Document)-[:SUPERSEDES]->(:Document)`
- `(:Document)-[:VERSION_OF]->(:DocumentFamily)`
- Nó `:DocumentFamily` com `family_id`, `title`, `current_version`

**Camada 3 — No retrieval (filtro temporal):**
Detectar contexto temporal na pergunta, filtrar por vigência antes da busca vetorial, assumir data atual se não houver contexto explícito.

**Por que temporalidade explícita e não versionamento implícito via Git:**
- Git versiona **arquivos**, não **vigência** de regras de negócio
- Uma lei pode ser vigente de 2024 a 2026 independente de commits
- Retrieval precisa filtrar por data de consulta, não por data de commit
- DocumentFamily permite consultas "como era antes?"

Para política completa de temporalidade: ver SPEC-B06 (Política de Temporalidade)

### 3.7. Re-ingestão com merge (não sobrescrita)

Quando uma fonte é atualizada (ex: PDF v2), o pipeline faz **merge inteligente** em vez de sobrescrita total:

1. **Diff de fontes** — comparar v1 com v2, gerar lista de mudanças
2. **Análise de impacto** — classificar cada trecho do `.beta.md`:
   - *Sem conflito* (não editado por humano): atualizar automaticamente
   - *Possível conflito* (editado por humano E fonte mudou): alerta `CONFLICT`
   - *Conflito em bloco locked*: não alterar, registrar alerta `LOCKED-CONFLICT`
3. **Relatório** — quantos trechos atualizados, conflitos para revisão

**Por que merge e não sobrescrita:**
- Sobrescrita destruiria edições humanas validadas
- Blocos LOCKED seriam ignorados em sobrescrita total
- Merge preserva trabalho humano e sinaliza conflitos para revisão
- Humano sempre tem a palavra final

Para procedimento completo de re-ingestão: ver RNB-E05 (Reingestão com Merge)

## 4. Alternativas descartadas

### 4.1. Modelo Bronze/Prata/Ouro (3 camadas)

**Descartada:** não prevê edição humana; mistura preparação e verdade final na camada prata; sem temporalidade; sem re-ingestão com merge. Conceitos úteis (conversion_quality, linhagem, formatos suportados) foram absorvidos neste ADR.

### 4.2. Pipeline direto sem camada beta (fontes -> .txt -> .md)

**Descartada:** não permite edição humana antes da promoção; qualquer correção exige reprocessamento completo; não suporta fontes diversas (apenas .txt); insuficiente para cenário corporativo com curadoria humana.

### 4.3. Repositório único com branch protection

**Descartada:** branches confundem equipes não-técnicas; risco de merge acidental; para ambiente regulado (BACEN, LGPD), separação física é mais segura e auditável; Obsidian com Git requer plugin.

### 4.4. Arquivos separados por autor (.ai.beta.md + .human.beta.md)

**Descartada:** triplicação de arquivos; merge não-trivial entre dois arquivos; humano precisa saber qual arquivo editar; não escala. Blocos LOCKED resolvem o conflito de forma mais simples e granular.

## 5. Consequências

### Positivas

- Edição humana e enriquecimento por IA coexistem sem conflito
- Fonte da verdade (`.md`) é imutável e auditável
- Separação física de repos garante compliance regulatório
- Temporalidade permite consultas históricas ("como era antes?")
- Re-ingestão não destrói trabalho humano
- Pipeline é reprodutível (pilar H) e rastreável (pilar G)
- Gate de qualidade (QA score) previne promoção de conteúdo imaturo

### Negativas / Trade-offs

- Complexidade aumenta: 2 repos, 2 níveis de front matter, blocos LOCKED
- Curva de aprendizado: equipes precisam entender o fluxo beta -> md
- Pipeline de promoção (Fase 3) é mais complexo que conversão direta
- Wikilinks segregados impede navegação cross-repo no Obsidian

### Riscos

- **Blocos LOCKED esquecidos:** humano edita sem marcar LOCKED, IA sobrescreve na re-ingestão. *Mitigação:* safety net via git diff (edição humana detectada sempre prevalece).
- **Acúmulo de conflitos:** alertas CONFLICT não revisados. *Mitigação:* relatório de re-ingestão com contagem de conflitos pendentes.
- **Dessincronia entre repos:** `.beta.md` evolui mas promoção para `.md` atrasa. *Mitigação:* promoção sob demanda controlada por tags/releases. Não há cadência fixa — o Curador decide quando os `.beta.md` estão prontos.
- **Temporalidade incorreta:** `valid_from`/`valid_until` preenchidos errado. *Mitigação:* validação de schema no pipeline de promoção.
- **Complexidade do merge:** re-ingestão com diff pode gerar falsos positivos. *Mitigação:* humano sempre tem a palavra final.

## 6. Implementação (alto nível)

Alinhado com o rollout do CLAUDE.md:

- **Fase 1 (MVP):** Estrutura dos 2 repos, templates básicos, pipeline de captura de fontes para geração de `.beta.md`, gate de `conversion_quality` básico
- **Fase 2 (Metadados):** Front matter leve validado, blocos LOCKED funcionais, edição humana via Obsidian configurada, pipeline de mineração com múltiplas rodadas
- **Fase 3 (Knowledge Graph):** Pipeline de promoção (beta -> md) com front matter rico, PR automático, QA score como gate, temporalidade (`valid_from`/`valid_until`, DocumentFamily)
- **Fase 4 (GraphRAG Corporativo):** Re-ingestão com merge completo, diff inteligente, resolução de conflitos, dashboards de cobertura e maturidade do conhecimento

Para plano de implementação detalhado: ver DOC-I03 (Plano de Implementação Pipeline)

## 7. Referências

### ADRs relacionados

- [[ADR-002|ADR-002 — Soberania de Dados]] (roteamento por `confidentiality`, Track A/B)
- [[ADR-003|ADR-003 — Modelo de Dados da Base Vetorial]] (DocumentFamily, SUPERSEDES)
- [[ADR-005|ADR-005 — Front Matter como Contrato de Metadados]] (2 níveis, schemas)
- [[ADR-006|ADR-006 — Pipeline de Ingestão]] (Fase 4, 7 etapas de ingestão)
- [[ADR-007|ADR-007 — Retrieval Híbrido]] (consome a Base Vetorial com filtros temporais)
- [[ADR-009|ADR-009 — Seleção de Modelos de Embedding]]
- [[ADR-010|ADR-010 — Git Flow]] (releases e tags)
- [[ADR-011|ADR-011 — Segregação de KBs]] (estrutura de pastas, regras por KB)

### Documentos de processo extraídos deste ADR

- **DOC-A01:** Guia de Estrutura de Pastas (estrutura dos 2 repos, convenções)
- **SPEC-B05:** Conversão de Formatos RAW (sinais por formato, fórmula, gates)
- **SPEC-B06:** Política de Temporalidade (3 camadas, vigência, DocumentFamily)
- **RNB-B07:** Edição de Arquivos Beta (blocos LOCKED, regras, exemplos)
- **RNB-E05:** Reingestão com Merge (diff, análise de impacto, conflitos)
- **DOC-I03:** Plano de Implementação Pipeline (faseamento, responsáveis)

<!-- conversion_quality: 97 -->
