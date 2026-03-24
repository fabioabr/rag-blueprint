---
# === IDENTIFICAÇÃO ===
id: ADR-005
doc_type: adr
title: "Front Matter como Contrato de Metadados"

# === CLASSIFICAÇÃO ===
system: RAG Corporativo
module: Front Matter e Metadados
domain: Arquitetura
owner: fabio
team: arquitetura

# === STATUS E GOVERNANÇA ===
status: accepted
confidentiality: internal
date_decided: 2026-03-21

# === TEMPORAL ===
valid_from: "2026-03-21"
valid_until: null
supersedes: null
superseded_by: null

# === DESCOBERTA ===
tags: [front matter, contrato metadados, schema validação, yaml, obsidian, conversion quality, front matter leve, front matter rico, metadados obrigatórios, pipeline promoção, base vetorial, rastreabilidade, linhagem dados, classificação dados, governança metadados, validação bloqueante, validação não bloqueante, campos obrigatórios, campos opcionais, ciclo vida documento, beta md, md final, rag workspace, rag knowledge base, score qualidade, thresholds conversão, qa score, enriquecimento ia, curadoria humana, tags semânticas, aliases obsidian, wikilinks, template obsidian, properties view, doc type, confidentiality, status documento, sources linhagem, domain negócio, owner responsável, team squad, versionamento documento, supersedes, valid from, valid until, regex validação, enum valores, rejeição explícita, warning log, parse front matter, herança metadados, filtro pre retrieval, campos bloqueantes, grupos lógicos, schema executável]
aliases:
  - "ADR-005"
  - "Contrato de Metadados"
  - "Front Matter YAML"
  - "Schema de Validação Front Matter"
  - "Especificação de Front Matter Leve e Rico"

# === LINHAGEM ===
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-005_front_matter_contrato_metadados.beta.md"
source_beta_ids: ["BETA-005"]
conversion_pipeline: promotion-pipeline-v2
conversion_quality: 95
converted_at: "2026-03-23"

# === QA ===
qa_score: null
qa_date: null
qa_status: pending

# === DATAS ===
created_at: "2026-03-21"
updated_at: "2026-03-23"
---

# ADR-005 — Front Matter como Contrato de Metadados

## Contexto

No pipeline de 4 fases definido na [[ADR-001]], o front matter YAML é o mecanismo que conecta o trabalho humano (edição de `.beta.md` no Obsidian) ao trabalho automatizado (pipeline de ingestão que gera `.md` final e alimenta a Base Vetorial).

Sem front matter válido, o pipeline não sabe:

- O que é esse documento (tipo, domínio, sistema)
- Quem é responsável por ele
- Qual o nível de confidencialidade ([[ADR-004]])
- Se o documento está vigente ou foi substituído
- De onde veio a informação (linhagem)
- Qual a qualidade da conversão da fonte original

O front matter não é um "detalhe técnico" — é um **contrato** entre:

- **Autores** (humanos que editam `.beta.md` no Obsidian)
- **Pipeline de mineração** (IA que gera/enriquece `.beta.md` na Fase 2)
- **Pipeline de promoção** (automação que transforma `.beta.md` em `.md` na Fase 3)
- **Pipeline de ingestão** (automação que ingere `.md` na Base Vetorial na Fase 4)
- **Sistema de retrieval** (agentes que buscam informação na Base Vetorial)

Se qualquer parte desse contrato for violada (campo ausente, valor inválido, formato incorreto), o pipeline DEVE rejeitar o documento com mensagem de erro explícita — nunca aceitar silenciosamente dados incompletos.

Existem **dois níveis** de front matter, conforme [[ADR-001]]:

1. **Front matter leve** (`.beta.md`) — usado no repositório `rag-workspace`. Contém apenas campos essenciais para a edição humana e o enriquecimento pela IA. Intencionalmente simples para não sobrecarregar autores humanos.
2. **Front matter rico** (`.md` final) — usado no repositório `rag-knowledge-base`. Contém todos os campos necessários para governança, classificação, temporalidade, QA e linhagem. Gerado automaticamente pelo pipeline de promoção (Fase 3) com enriquecimento dos campos leves.

Requisitos adicionais:

- Compatibilidade com Obsidian (YAML entre marcadores `---`)
- Suporte a temporalidade (`valid_from`/`valid_until`, conforme [[ADR-001]])
- Suporte a classificação de dados (`confidentiality`, conforme [[ADR-004]])
- Schema de validação executável (não apenas documentação)
- Suporte a rastreabilidade de origem (linhagem da fonte até a Base Vetorial)

## Decisão

Adotar front matter YAML como contrato de metadados obrigatório em dois níveis (leve e rico), com schema de validação executável que rejeita documentos inválidos com mensagem explícita.

<!-- LOCKED:START autor=fabio data=2026-03-23 -->

### Parte A — Front Matter Leve (.beta.md) — Repositório rag-workspace

O front matter leve é projetado para ser **simples** o suficiente para que um analista de negócio, PO ou especialista de domínio consiga preencher sem treinamento extenso, usando o Obsidian como editor.

Filosofia: conter o **MÍNIMO NECESSÁRIO** para que o pipeline funcione. Tudo que pode ser inferido ou enriquecido depois fica fora — reduzindo a carga cognitiva do autor humano.

Formato: YAML entre marcadores `---` no início do arquivo (compatível Obsidian).

#### Campos do front matter leve

**id** (obrigatório, bloqueante)

- Tipo: `string`
- Formato: `BETA-{NNN}` (numérico sequencial, 3+ dígitos)
- Regex: `^BETA-\d{3,}$`
- Exemplos: `id: BETA-001`, `id: BETA-042`, `id: BETA-1337`
- Identificador único do documento no workspace. Necessário para rastreabilidade, referência cruzada, histórico de enriquecimento e linkagem no Obsidian via `[[BETA-001]]`.
- Validação: obrigatório (bloqueante), regex `^BETA-\d{3,}$`, único no repositório workspace.
- Mensagem de erro: `"Campo 'id' ausente ou formato inválido"`

**title** (obrigatório, bloqueante)

- Tipo: `string`, max 200 caracteres
- Formato: texto livre, min 10 chars, max 200 chars
- Exemplo: `title: "Processo de conciliação bancária do módulo Cobrança"`
- Título legível do documento. Usado para exibição no Obsidian, contexto para a LLM durante retrieval, identificação humana rápida e resultado de busca.
- Validação: obrigatório (bloqueante), mínimo 10 caracteres, máximo 200 caracteres, não aceitar títulos genéricos.
- Mensagem de erro: `"Campo 'title' ausente ou muito curto"`

**domain** (obrigatório, bloqueante)

- Tipo: `string`, enum aberto (sem lista fixa, com recomendações)
- Formato: lowercase, sem espaços (usar hífen), mínimo 2 caracteres
- Exemplos: `domain: "financeiro"`, `domain: "tecnologia"`, `domain: "rh"`
- Domínio de negócio ao qual o documento pertence. Fundamental para filtro pré-retrieval ([[ADR-004]]), organização do conhecimento, roteamento de agentes e responsabilidade por área.
- Validação: obrigatório (bloqueante), mínimo 2 caracteres, lowercase, sem espaços (usar hífen).
- Regex: `^[a-z][a-z0-9-]*$`
- Mensagem de erro: `"Campo 'domain' ausente ou formato inválido"`

**sources** (obrigatório, bloqueante)

- Tipo: `array de objetos`
- Sub-campos:
  - `type` (obrigatório): formato da fonte original. Valores válidos: `pdf`, `docx`, `xlsx`, `pptx`, `email`, `confluence`, `sharepoint`, `jira`, `clickup`, `transcription`, `web`, `manual`, `md`, `json`, `csv`, `image`, `video`, `audio`.
  - `origin` (obrigatório): caminho ou URL da fonte original. Formato livre.
  - `captured_at` (obrigatório): data de captura da fonte, formato `AAAA-MM-DD`.
  - `conversion_quality` (opcional): score de qualidade da conversão desta fonte (0-100), calculado pelo pipeline na Fase 2.
- Exemplo:
  ```yaml
  sources:
    - type: "pdf"
      origin: "sharepoint://financeiro/docs/conciliacao_v3.pdf"
      captured_at: "2026-03-15"
      conversion_quality: 92
    - type: "transcription"
      origin: "teams://recordings/2026-03-12_reuniao.mp4"
      captured_at: "2026-03-12"
      conversion_quality: 67
  ```
- Relação com `conversion_quality` do `.md` final: no `.beta.md`, `conversion_quality` é per-source (dentro de `sources[]`). No `.md` final, é consolidado via `min(sources[].conversion_quality)`.
- Validação: obrigatório (bloqueante), array com pelo menos 1 elemento, cada elemento deve ter `type`, `origin` e `captured_at` válidos.
- Mensagem de erro: `"Campo 'sources' ausente ou incompleto"`

**tags** (obrigatório, não-bloqueante)

- Tipo: `array de strings`, mínimo 3 manuais + 50 semânticas (total ~53+)
- Formato: cada tag lowercase, sem acentos; termos compostos separados por espaço (ex: "busca vetorial", "filtro pre-retrieval")
- Ordenação: por relevância decrescente — índice 0 = mais relevante ao contexto específico do documento
- Composição:
  - Tags manuais (autor humano): mínimo 3, inseridas pelo autor ou curador. Focam em categorização de alto nível e descoberta.
  - Tags semânticas (geradas por IA): exatamente 50 termos, gerados automaticamente na promoção `.txt` -> `.beta.md`. Extraídos do conteúdo do documento, priorizando termos técnicos e de domínio com maior proximidade ao contexto específico. Termos genéricos devem ser evitados salvo quando centrais ao documento.
- Regra de geração das 50 tags semânticas:
  1. Analisar o conteúdo completo do documento
  2. Identificar termos técnicos, conceitos de domínio e nomes próprios
  3. Incluir termos compostos quando o significado exige (ex: "base vetorial")
  4. Ordenar por relevância ao contexto específico do documento
  5. Descartar termos excessivamente genéricos
  6. Garantir exatamente 50 termos no array de tags semânticas
  7. Manter as tags manuais do autor nas primeiras posições
  8. Persistir em todos os formatos: `.beta.md`, `.md`, `.html`
- Validação: warning se menos de 3 tags manuais, mínimo 3 tags para promoção (bloqueante na Fase 3).
- Warning: `"tags: menos de 3 tags manuais. Adicione mais para descoberta."`

**status** (obrigatório, bloqueante)

- Tipo: `string` (enum)
- Valores: `draft` | `in-review` | `approved`
- Controla o ciclo de vida do `.beta.md`: somente `approved` pode ser promovido a `.md`.
- Transições válidas: `draft` -> `in-review` -> `approved`. Retorno permitido: `approved` -> `draft`.
- Validação: obrigatório (bloqueante), deve ser um dos 3 valores válidos.
- Mensagem de erro: `"Campo 'status' ausente ou valor inválido"`

**confidentiality** (obrigatório, bloqueante)

- Tipo: `string` (enum)
- Valores: `public` | `internal` | `restricted` | `confidential`
- Default: `internal`
- Nível de classificação de dados conforme [[ADR-004]]. Determina onde o documento pode ser processado (cloud vs on-premise, conforme [[ADR-002]]) e quem pode acessá-lo.
- **Exceção ao princípio "governança só no .md final"**: necessário desde a Fase 2 porque [[ADR-002]] usa `confidentiality` para rotear o documento pela trilha correta e [[ADR-004]] exige classificação antes de qualquer processamento automatizado.
- Validação: obrigatório (bloqueante), deve ser um dos 4 valores válidos.
- Mensagem de erro: `"Campo 'confidentiality' ausente ou valor inválido"`

**last_enrichment** (opcional, não-bloqueante)

- Tipo: `string` (data ISO 8601), formato `AAAA-MM-DD`
- Exemplo: `last_enrichment: "2026-03-18"`
- Registra a data da última vez que o pipeline de IA enriqueceu o documento. Permite identificar documentos que nunca foram enriquecidos ou estagnados.
- Warning: `"last_enrichment não preenchido. Será atualizado no próximo enriquecimento."`

**last_human_edit** (opcional, não-bloqueante)

- Tipo: `string` (data ISO 8601), formato `AAAA-MM-DD`
- Exemplo: `last_human_edit: "2026-03-20"`
- Registra a data da última edição humana. Permite priorizar documentos para revisão e medir engajamento humano na curadoria.
- Warning: `"last_human_edit não preenchido. Revisão humana recomendada."`

**aliases** (opcional, não-bloqueante)

- Tipo: `array de strings`
- Formato: cada alias de 3-100 caracteres, sem duplicatas
- Exemplo: `aliases: ["Conciliação Bancária", "Retorno CNAB"]`
- Nomes alternativos reconhecidos nativamente pelo Obsidian para busca e descoberta (quick switcher via Ctrl+O).
- Validação: opcional, se presente deve ser array de strings sem duplicatas.

#### Campos intencionalmente ausentes do front matter leve

- **system, module, owner, team**: campos de governança que exigem conhecimento da estrutura organizacional. Preenchidos na Fase 3 pelo pipeline.
- **valid_from, valid_until, supersedes, superseded_by**: campos temporais definidos na promoção.
- **qa_score, qa_date, qa_status**: QA só se aplica ao `.md` final.
- **doc_type**: definido na promoção, pois o conteúdo pode mudar de natureza durante a elaboração.

#### Exemplo completo de .beta.md com front matter leve

```yaml
---
id: BETA-042
title: "Processo de conciliação bancária do módulo Cobrança"
domain: "financeiro"
confidentiality: internal
sources:
  - type: "pdf"
    origin: "sharepoint://financeiro/docs/conciliacao_v3.pdf"
    captured_at: "2026-03-15"
  - type: "transcription"
    origin: "teams://recordings/2026-03-12_reuniao_cobranca.mp4"
    captured_at: "2026-03-12"
tags: [conciliação, cobrança, bancária, boleto, retorno, cnab]
aliases: ["Conciliação Bancária", "Retorno CNAB"]
status: in-review
last_enrichment: "2026-03-18"
last_human_edit: "2026-03-20"
---
```

#### Template Obsidian recomendado

```yaml
---
id: BETA-
title: ""
domain: ""
confidentiality: internal
sources:
  - type: ""
    origin: ""
    captured_at: ""
tags: []
aliases: []
status: draft
last_enrichment:
last_human_edit:
---
```

### Parte B — Front Matter Rico (.md final) — Repositório rag-knowledge-base

O front matter rico é o contrato **completo** que o `.md` final carrega. É gerado pelo pipeline de promoção (Fase 3) a partir do front matter leve com enriquecimento de campos de governança, classificação e qualidade.

Os campos são organizados em **8 grupos lógicos**:

#### Grupo 1 — Identificação

- **id**: `DOC-{NNNNNN}` (6 dígitos, zero-padded). Regex: `^DOC-\d{6}$`. Identificador único e definitivo na base de conhecimento. Permanente, referenciado pela Base Vetorial, chunks, relações e agentes. Diferente do `BETA-{NNN}` que é temporário no workspace.
- **doc_type**: enum (`system-doc`, `adr`, `runbook`, `glossary`, `task-doc`, `architecture-doc`, `policy`, `meeting-notes`, `onboarding`, `postmortem`). Determina estratégia de chunking, template de resposta do agente e filtro de busca.
- **title**: herdado do front matter leve.

#### Grupo 2 — Classificação

- **system**: sistema corporativo (gera nó `:System` na Base Vetorial). Permite filtro por sistema no retrieval e organização do grafo de conhecimento.
- **module**: módulo funcional (gera nó `:Module` na Base Vetorial e relação `BELONGS_TO` com System).
- **domain**: herdado do front matter leve (lowercase, sem espaços).
- **owner**: responsável pelo conteúdo (gera nó `:Owner` e relação `OWNED_BY`). Permite rastreabilidade de responsabilidade.
- **team**: time, squad, chapter ou diretoria (gera nó `:Team` e relação `MEMBER_OF`). Permite filtro por equipe.

#### Grupo 3 — Status e Governança

- **status**: `draft` | `in-review` | `approved` | `deprecated`. Adiciona `deprecated` ao ciclo do `.beta.md`. Somente `approved` é ingerido na Base Vetorial. `deprecated` é mantido com ranking reduzido. Quando deprecated, campo `superseded_by` é obrigatório.
- **confidentiality**: herdado do front matter leve, com as mesmas regras de classificação ([[ADR-004]]).

#### Grupo 4 — Temporal

- **valid_from**: data de início de vigência (formato `AAAA-MM-DD`). Permite consultas temporais no retrieval. Validação: data válida, não futura (exceção: políticas programadas).
- **valid_until**: data de fim de vigência ou `null` (vigente indefinidamente). Quando preenchido, o documento deixa de ser retornado como vigente após a data.
- **supersedes**: `DOC-{NNNNNN}` do documento anterior que este substitui. Gera relação `SUPERSEDES` na Base Vetorial. Permite navegação na cadeia de versões.
- **superseded_by**: `DOC-{NNNNNN}` do documento que substitui este. Obrigatório quando `status = deprecated`.

#### Grupo 5 — QA (Quality Assurance)

- **qa_score**: integer 0-100, score de qualidade calculado pelo pipeline de QA. Determina se o documento pode ser promovido.
- **qa_date**: data da última execução do QA.
- **qa_status**: `passed` (>= 90%) | `warning` (80-89%) | `not_reviewed`.
- **qa_notes**: obrigatório quando `qa_status = warning`. Documenta motivos e decisão de promover com ressalva. Rastreabilidade de decisões de qualidade.

#### Grupo 6 — Descoberta

- **tags**: array com mínimo 5 manuais + 50 semânticas (total ~55+), lowercase, sem acentos. Termos compostos separados por espaço. Ordenação por relevância decrescente. Tags manuais do autor nas primeiras posições + 50 tags semânticas geradas por IA mantidas da promoção `.txt` -> `.beta.md`.
- **aliases**: array com mínimo 5 aliases para busca e wikilinks no Obsidian. No `.md` final, o requisito é mais rigoroso (5+) para maximizar a descoberta na Base Vetorial.

#### Grupo 7 — Linhagem

- **source_format**: formato principal da fonte (`original`, `pdf`, `docx`, `xlsx`, `pptx`, `email`, `confluence`, `sharepoint`, `jira`, `clickup`, `transcription`, `web`, `json`, `csv`, `image`, `video`, `audio`, `manual`, `multiple`). Permite análises de qualidade por formato.
- **source_repo**: repositório Git de origem do `.beta.md`.
- **source_path**: caminho do `.beta.md` no workspace.
- **source_beta_ids**: array de `BETA-{NNN}` que originaram este `.md`. Rastreabilidade completa: de qual(is) `.beta.md` este `.md` foi gerado.
- **conversion_pipeline**: identificador do pipeline que gerou o `.md`.
- **conversion_quality**: integer 0-100, score consolidado via `min(sources[].conversion_quality)`. A função `min()` garante que a pior fonte determine o score final.
- **converted_at**: timestamp da conversão/promoção (formato ISO 8601).

#### Grupo 8 — Datas e Versionamento

- **created_at**: data de criação do `.md` final.
- **updated_at**: data da última atualização. Validação: `>= created_at`.
- **release_version**: versão da release que disparou a ingestão (formato semver `vN.N.N`). Preenchido automaticamente pelo pipeline de ingestão ([[ADR-006]]). Permite rastrear qual versão do conhecimento está ativa.

#### Exemplo completo de .md final com front matter rico

```yaml
---
# === IDENTIFICAÇÃO ===
id: DOC-000042
doc_type: system-doc
title: "Processo de conciliação bancária do módulo Cobrança"

# === CLASSIFICAÇÃO ===
system: Cobrança
module: Conciliação
domain: financeiro
owner: maria.silva
team: squad-pagamentos

# === STATUS E GOVERNANÇA ===
status: approved
confidentiality: internal

# === TEMPORAL ===
valid_from: "2026-01-15"
valid_until: null
supersedes: "DOC-000023"
superseded_by: null

# === QA ===
qa_score: 85
qa_date: "2026-03-21"
qa_status: warning
qa_notes: "Score 85% -- inferências sobre custos cloud não verificadas. Aprovado com ressalva pelo PO em 21/03/2026."

# === DESCOBERTA ===
tags: [conciliação, cobrança, bancária, boleto, retorno, cnab, financeiro, banco-do-brasil, arquivo-retorno, cnab-240]
aliases: ["Conciliação Bancária", "Retorno CNAB", "Arquivo de Retorno", "Conciliação de Cobrança", "Processamento CNAB 240"]

# === LINHAGEM ===
source_format: pdf
source_repo: rag-workspace
source_path: "beta/financeiro/conciliacao_bancaria.beta.md"
source_beta_ids: ["BETA-042", "BETA-043"]
conversion_pipeline: promotion-pipeline-v1
conversion_quality: 82
converted_at: "2026-03-21T14:30:00Z"

# === DATAS E VERSIONAMENTO ===
created_at: "2026-03-21"
updated_at: "2026-03-21"
release_version: "v1.3.0"
---
```

<!-- LOCKED:END -->

## Schema de Validação (Parte C)

O schema de validação é um componente **executável** do pipeline — não apenas documentação. Ele roda em dois momentos:

1. Na Fase 2 (enriquecimento): valida o front matter leve do `.beta.md`
2. Na Fase 3 (promoção): valida o front matter rico do `.md` final

**Regra fundamental**: rejeição **EXPLÍCITA**, nunca skip silencioso.

### Classificação: bloqueante vs não-bloqueante

- **Bloqueante**: documento é REJEITADO se o campo está ausente ou inválido. Pipeline para, registra erro, notifica responsável.
- **Não-bloqueante (warning)**: documento é ACEITO, mas alerta é registrado no log. Documento aparece em relatório de "documentos com alertas".

### Regras de validação — Front matter leve (.beta.md)

**Campos bloqueantes** (documento rejeitado se inválido):

| Campo | Regra | Regex/Formato | Mensagem de erro |
|---|---|---|---|
| `id` | Presente, formato válido, único | `^BETA-\d{3,}$` | "Campo 'id' ausente ou formato inválido" |
| `title` | Presente, 10-200 chars, não genérico | `len >= 10 AND len <= 200` | "Campo 'title' ausente ou muito curto" |
| `domain` | Presente, >= 2 chars, lowercase, sem espaços | `^[a-z][a-z0-9-]*$`, len >= 2 | "Campo 'domain' ausente ou formato inválido" |
| `sources` | Presente, array >= 1 elem, sub-campos ok | array, each: type+origin+captured_at | "Campo 'sources' ausente ou incompleto" |
| `status` | Presente, enum válido | `^(draft\|in-review\|approved)$` | "Campo 'status' ausente ou valor inválido" |
| `confidentiality` | Presente, enum válido | `^(public\|internal\|restricted\|confidential)$` | "Campo 'confidentiality' ausente ou valor inválido" |

Validação de sub-campos de `sources[]`:

- `type`: obrigatório, deve ser um dos valores válidos do enum source_type
- `origin`: obrigatório, string não vazia
- `captured_at`: obrigatório, formato `AAAA-MM-DD`, data válida
- `conversion_quality`: opcional, se presente deve ser integer 0-100

**Campos com warning** (documento aceito, alerta emitido):

| Campo | Regra | Warning |
|---|---|---|
| `tags` | Array >= 3 elementos | "tags: menos de 3 tags. Adicione mais para melhor descoberta." |
| `last_enrichment` | Data válida se presente | "last_enrichment não preenchido. Será atualizado no próximo enriquecimento." |
| `last_human_edit` | Data válida se presente | "last_human_edit não preenchido. Revisão humana recomendada." |
| `aliases` | Array sem duplicatas | (sem warning específico, apenas validação de formato) |

**NOTA**: tags com menos de 3 são warning na Fase 2, mas BLOQUEANTE na Fase 3 (promoção exige mínimo 3 tags).

### Regras de validação — Front matter rico (.md final)

Todos os campos do front matter rico são bloqueantes na promoção, exceto os marcados como "opcional, não-bloqueante".

**Campos bloqueantes adicionais** (além dos herdados do leve):

| Campo | Regra |
|---|---|
| `id` | Formato `DOC-{NNNNNN}`, regex `^DOC-\d{6}$`, único |
| `doc_type` | Enum válido |
| `system` | Sistema cadastrado (string não vazia) |
| `module` | Módulo do sistema indicado (string não vazia) |
| `owner` | Usuário cadastrado (string não vazia) |
| `team` | Time cadastrado (string não vazia) |
| `valid_from` | Data válida, não futura* |
| `tags` | Array >= 5 elementos (mais restritivo que `.beta.md`) |
| `aliases` | Array >= 5 elementos |
| `source_format` | Enum válido |
| `source_repo` | String não vazia |
| `source_path` | String não vazia |
| `source_beta_ids` | Array de strings formato `BETA-{NNN}` |
| `conversion_pipeline` | String não vazia |
| `conversion_quality` | Integer 0-100 |
| `created_at` | Data válida |
| `updated_at` | Data válida, >= `created_at` |
| `converted_at` | Timestamp ISO 8601 válido |
| `qa_score` | Integer 0-100 |
| `qa_date` | Data válida |
| `qa_status` | Enum válido |

*`valid_from` pode ser futura para políticas programadas (exceção documentada).

**Campos condicionalmente obrigatórios:**

| Campo | Condição | Regra |
|---|---|---|
| `superseded_by` | `status = deprecated` | `DOC-{NNNNNN}` obrigatório |
| `qa_notes` | `qa_status = warning` | String não vazia obrigatória |

### Comportamento quando validação falha

**Campo BLOQUEANTE inválido:**

1. Documento é REJEITADO (não processado)
2. Mensagem de erro registrada no log com: identificador do documento, campo inválido, valor encontrado, valor esperado, sugestão de correção
3. Notificação enviada ao responsável
4. Documento aparece em relatório de "documentos pendentes"

**Campo com WARNING inválido:**

1. Documento é ACEITO (processamento continua)
2. Warning registrado no log
3. Documento aparece em relatório de "documentos com alertas"

**Princípio fundamental**: NUNCA aceitar silenciosamente dados incompletos ou inválidos. Se o campo é bloqueante, o pipeline PARA. Se o campo é warning, o pipeline CONTINUA mas REGISTRA. Em nenhum caso o pipeline ignora silenciosamente.

### Valores válidos para enums

- **doc_type**: `system-doc`, `adr`, `runbook`, `glossary`, `task-doc`, `architecture-doc`, `policy`, `meeting-notes`, `onboarding`, `postmortem`
- **status (.beta.md)**: `draft`, `in-review`, `approved`
- **status (.md final)**: `draft`, `in-review`, `approved`, `deprecated`
- **confidentiality**: `public`, `internal`, `restricted`, `confidential`
- **source_format**: `original`, `pdf`, `docx`, `xlsx`, `pptx`, `email`, `confluence`, `sharepoint`, `jira`, `clickup`, `transcription`, `web`, `json`, `csv`, `image`, `video`, `audio`, `manual`
- **qa_status**: `pending`, `passed`, `failed`, `skipped`
- **source type** (no array `sources[]` do `.beta.md`): `pdf`, `docx`, `xlsx`, `pptx`, `email`, `confluence`, `sharepoint`, `jira`, `clickup`, `transcription`, `web`, `manual`, `md`, `json`, `csv`, `image`, `video`, `audio`

### Regex patterns — Resumo consolidado

| Campo | Pattern |
|---|---|
| `id` (.beta.md) | `^BETA-\d{3,}$` |
| `id` (.md final) | `^DOC-\d{6}$` |
| `domain` | `^[a-z][a-z0-9-]*$` (mínimo 2 chars) |
| `status` (.beta.md) | `^(draft\|in-review\|approved)$` |
| `status` (.md) | `^(draft\|in-review\|approved\|deprecated)$` |
| `confidentiality` | `^(public\|internal\|restricted\|confidential)$` |
| `captured_at` | `^\d{4}-\d{2}-\d{2}$` (validar como data real) |
| `conversion_quality` | `^\d{1,3}$` (0-100, validar range) |

## Conversion Quality (Parte D)

O campo `conversion_quality` expressa a confiança na fidelidade da conversão da fonte original para o formato `.md`. Score de 0 a 100% calculado pelo pipeline de conversão na Fase 2 ([[ADR-001]]).

Dois níveis de registro:

- No `.beta.md`: `conversion_quality` é **per-source** (dentro de `sources[]`)
- No `.md` final: `conversion_quality` é **consolidado** via `min(sources[].conversion_quality)`

### Fórmula de cálculo

```
conversion_quality = min(
    media_ponderada(sinais_do_formato),
    penalidade_por_erro_critico
)
```

A função `min()` garante que um erro crítico **sempre** reduz o score, mesmo que os outros sinais sejam bons.

Consolidação para `.md` final: `conversion_quality_final = min(sources[].conversion_quality)`. A pior fonte entre todas determina o score final.

### Sinais por formato de origem

| Formato | Sinais | Peso |
|---|---|---|
| **MD nativo** | 100% automático (sem conversão) | - |
| **PDF texto** | % caracteres reconhecidos (40%), headings preservados (30%), tabelas (20%), links (10%) | - |
| **PDF escaneado (OCR)** | Confidence OCR (50%), resolução DPI (20%), % texto reconhecido (20%), idioma (10%) | - |
| **DOCX** | Conversão determinística (30%), estilos preservados (30%), tabelas (20%), imagens com alt (20%) | - |
| **XLSX** | Tabelas convertidas (40%), fórmulas identificadas (20%), merges resolvidos (20%), abas processadas (20%) | - |
| **PPTX** | Slides convertidos (30%), notas do apresentador (25%), imagens descritas (25%), ordem lógica (20%) | - |
| **Email** | Headers completos (30%), corpo HTML->MD (30%), anexos (25%), thread preservada (15%) | - |
| **Transcrição (áudio/vídeo)** | WER do STT (40%), identificação de falantes (25%), timestamps (15%), sobreposição tratada (20%) | - |
| **Confluence** | Estrutura HTML preservada (30%), macros expandidas (25%), links internos (25%), anexos (20%) | - |
| **Web** | HTML->MD com estrutura (35%), navegação removida (25%), imagens com alt (20%), links resolvidos (20%) | - |
| **JSON / Ticket (Jira, ClickUp)** | Campos extraídos (40%), histórico preservado (25%), comentários (20%), anexos (15%) | - |
| **CSV** | Headers identificados (30%), tipos inferidos (25%), encoding correto (25%), delimitador (20%) | - |
| **Image** | OCR confidence (50%), descrição por VLM (30%), resolução suficiente (20%) | - |
| **Manual** | Score definido pelo humano (100%) | - |

### Thresholds de decisão

| Score | Ação |
|---|---|
| >= 80% | **Ingestão automática**. `.beta.md` gerado e processado sem intervenção humana. Status: `draft`. |
| 30% a 79% | **Revisão humana obrigatória**. `.beta.md` gerado com flag `requires_human_review`. Pipeline emite warning com sinais de score baixo. |
| < 30% | **Rejeição**. `.beta.md` não gerado. Fonte rejeitada. Log com detalhes. Humano deve providenciar fonte melhor ou conversão manual. |

Os thresholds (80% e 30%) são configuráveis por organização via config do pipeline.

### Relação entre conversion_quality e QA

- **conversion_quality**: calculado na Fase 2, mede fidelidade da EXTRAÇÃO (fonte original -> markdown), per-source no `.beta.md`, consolidado no `.md` final.
- **qa_score**: calculado na Fase 3, mede qualidade do CONTEÚDO (completude, clareza, estrutura), aplicado ao documento como um todo.

São métricas complementares: um documento pode ter `conversion_quality` alto (boa extração) mas `qa_score` baixo (conteúdo incompleto), e vice-versa.

### Exemplos práticos

**PDF texto de boa qualidade:**

```yaml
sources:
  - type: "pdf"
    origin: "sharepoint://financeiro/manual_cobranca_v3.pdf"
    captured_at: "2026-03-15"
    conversion_quality: 92
```

Sinais: 95% chars reconhecidos, headings 100%, tabelas 85%, links 80%. Score: `0.95*0.4 + 1.0*0.3 + 0.85*0.2 + 0.80*0.1 = 93`. Nenhum erro crítico -> score final 92. Gate: >= 80% -> ingestão automática.

**Transcrição de reunião com ruído:**

```yaml
sources:
  - type: "transcription"
    origin: "teams://recordings/2026-03-12_reuniao.mp4"
    captured_at: "2026-03-12"
    conversion_quality: 67
```

Sinais: WER 25% (ruim), falantes 80%, timestamps 90%, sobreposição 40%. Score: `0.75*0.4 + 0.80*0.25 + 0.90*0.15 + 0.40*0.20 = 71.5`. Penalidade por WER alto -> score final 67. Gate: 30-79% -> revisão humana obrigatória.

**Consolidação para .md final (múltiplas fontes):**

`conversion_quality_final = min(92, 67) = 67`. A pior fonte determina o score consolidado.

## Compatibilidade com Obsidian (Parte E)

O Obsidian é o editor recomendado para edição de `.beta.md` ([[ADR-001]], Fase 2). O front matter deve ser 100% compatível.

O Obsidian foi escolhido porque:

- Renderiza front matter YAML no painel de propriedades (Properties view)
- Suporta wikilinks nativamente (`[[ADR-001]]`)
- Aceita qualquer campo personalizado no front matter sem configuração extra
- Funciona como editor local (offline), sem dependência de servidor
- Possui ecossistema de plugins para produtividade

### YAML entre marcadores ---

O front matter **deve** estar entre marcadores `---` no início do arquivo. O Obsidian renderiza os campos no painel de propriedades (Properties view).

### Tags como array YAML

Tags devem ser arrays YAML, **não** a sintaxe `#tag` no front matter:

- **Correto**: `tags: [conciliação, cobrança, boleto]`
- **Incorreto**: `tags: #conciliação #cobrança #boleto`

No corpo do documento (abaixo do `---`), tags `#tag` podem ser usadas normalmente. O Obsidian indexa ambas as formas.

### Aliases para busca e descoberta

O campo `aliases` é reconhecido nativamente pelo Obsidian. Permite encontrar o documento pelo Quick Switcher (Ctrl+O) usando qualquer alias.

### Wikilinks no corpo, não no front matter

Wikilinks (`[[ADR-003]]`) devem ser usados apenas no **corpo** do documento, nunca no front matter. O front matter é YAML puro e wikilinks podem quebrar parsers. Wikilinks cross-KB são **PROIBIDOS** (ex: documento public não linka para restricted).

### Campos personalizados

O Obsidian aceita qualquer campo no front matter YAML. Campos como `qa_score`, `conversion_quality`, etc. são exibidos no painel de propriedades sem configuração adicional. Não é necessário plugin especial.

### Blocos LOCKED

Humanos podem marcar trechos como protegidos contra sobrescrita pela IA:

```
<!-- LOCKED:START autor=fabio data=2026-03-21 -->
Este trecho foi validado e não deve ser alterado pela IA.
<!-- LOCKED:END -->
```

Regras:
- IA pode adicionar conteúdo novo FORA dos blocos locked
- IA NUNCA altera conteúdo DENTRO de `LOCKED:START`/`END`
- IA pode sugerir mudanças em blocos locked como comentário separado
- Humano pode remover o lock a qualquer momento

### Plugins recomendados

- **Templates** (Core Plugin): template com front matter pré-preenchido
- **Templater** (Community Plugin): inserção automática de data, geração de id sequencial, preenchimento de domain baseado na pasta
- **Git** (Community Plugin, obsidian-git): commit automático, pull/push sem sair do editor, visualização de diff
- **Dataview** (Community Plugin): tabelas e listas dinâmicas baseadas no front matter (útil para Curador monitorar estado dos documentos)

### Compatibilidade e limitações

- O Obsidian não é obrigatório — qualquer editor que preserve YAML front matter entre marcadores `---` funciona (VS Code, Typora, etc.)
- Se o Obsidian for descontinuado, a migração é trivial: os arquivos são Markdown puro com YAML, sem formato proprietário
- O Obsidian não edita o `.md` final (knowledge-base) — apenas o `.beta.md` (workspace)

## Alternativas Descartadas

### Front matter único (mesmo schema para .beta.md e .md)

Rejeitada porque sobrecarrega o autor humano com campos que ele não sabe preencher, aumenta taxa de erros e campos de governança preenchidos pelo autor podem estar incorretos.

### Metadados em arquivo separado (sidecar)

Rejeitada porque duplica arquivos, risco de dessincronização, Obsidian não reconhece sidecar e YAML embutido é o padrão da indústria.

### Metadados apenas na Base Vetorial (sem front matter)

Rejeitada porque perde rastreabilidade, exige lógica complexa de inferência, impossibilita validação pré-ingestão e viola princípio "documento autoexplicativo" ([[ADR-001]], Pilar E).

### JSON em vez de YAML

Rejeitada porque JSON não é suportado pelo Obsidian como front matter, YAML é mais legível para humanos e é o padrão da indústria.

### Schema de validação opcional (best-effort)

Rejeitada porque em ambiente regulado "best-effort" não é aceitável, documentos inválidos poluem a Base Vetorial e warning sem rejeição é warning ignorado.

## Consequências

### Positivas

- Contrato claro entre autores e pipeline — sem ambiguidade
- Dois níveis de front matter respeitam a maturidade do documento
- Validação executável garante qualidade mínima
- Rejeição explícita evita poluição da Base Vetorial
- 100% compatível com Obsidian (zero config adicional)
- Rastreabilidade completa: da fonte até o chunk na Base Vetorial
- `conversion_quality` permite automação inteligente (auto vs review vs rejeição)
- Campos temporais habilitam consultas históricas

### Negativas / Trade-offs

- Curva de aprendizado para autores (mitigado por templates no Obsidian)
- Campos bloqueantes podem frustrar autores que querem contribuir rapidamente (mitigado pelo front matter leve com poucos campos obrigatórios)
- Manutenção de enums: listas de valores válidos precisam ser atualizadas quando novos tipos surgem
- Dois schemas (leve e rico) é mais complexo que um só

### Riscos

- Front matter incorreto bloqueando ingestão em massa (mitigação: versionamento do schema, migração automática)
- `conversion_quality` parcialmente subjetivo (mitigação: calibração periódica com revisão humana)
- Obsidian descontinuado (mitigação: qualquer editor com suporte a YAML front matter funciona)

## Implementação

| Fase | Entrega | Dependência |
|---|---|---|
| 1-MVP | Schema leve definido, validador básico, template Obsidian | [[ADR-001]] Fase 1 |
| 2 | Schema rico definido, validador completo, enums centralizados, relatório de rejeitados, `conversion_quality` | [[ADR-001]] Fase 2 |
| 3 | Pipeline de promoção (leve -> rico), sugestão automática de governança, validação de classificação ([[ADR-004]]), QA automatizado | [[ADR-001]] Fase 3 |
| 4 | Temporalidade completa, schema versionado com migração, dashboard de cobertura, auditoria de classificação | [[ADR-001]] Fase 4 |

## Referências

### Internas

- [[ADR-001]] — Pipeline de Geração de Conhecimento em 4 Fases (seções 2.5, 2.5.1, 2.6)
- [[ADR-002]] — Soberania e Residência de Dados
- [[ADR-003]] — Modelo de Dados da Base Vetorial
- [[ADR-004]] — Estratégia de Segurança e Classificação de Dados
- [[ADR-006]] — Pipeline de Ingestão (consome front matter na Etapa 2)
- [[ADR-007]] — Retrieval Híbrido e Agentes
- [[ADR-009]] — Seleção de Modelos de Embedding
- [[ADR-010]] — Git Flow da Base de Conhecimento
- [[ADR-011]] — Segregação de KBs

### Externas

- [YAML Specification 1.2](https://yaml.org/spec/1.2.2/)
- [Obsidian Properties](https://help.obsidian.md/Editing+and+formatting/Properties)
- [Hugo Front Matter](https://gohugo.io/content-management/front-matter/)
- [Jekyll Front Matter](https://jekyllrb.com/docs/front-matter/)

<!-- conversion_quality: 95 -->
