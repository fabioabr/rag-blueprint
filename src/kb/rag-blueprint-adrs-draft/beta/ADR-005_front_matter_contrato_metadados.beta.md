---
id: BETA-005
title: "Front Matter como Contrato de Metadados"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-B01_schema_front_matter_leve.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-B02_schema_front_matter_rico.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-B03_regras_validacao_front_matter.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-B04_metricas_conversao.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-A04_guia_uso_obsidian.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags: [front matter, contrato metadados, schema validacao, yaml, obsidian, conversion quality, front matter leve, front matter rico, metadados obrigatorios, pipeline promocao, base vetorial, rastreabilidade, linhagem dados, classificacao dados, governanca metadados, validacao bloqueante, validacao nao-bloqueante, campos obrigatorios, campos opcionais, ciclo vida documento, beta.md, md final, rag-workspace, rag-knowledge-base, score qualidade, thresholds conversao, qa score, enriquecimento ia, curadoria humana, tags semanticas, aliases obsidian, wikilinks, template obsidian, properties view, doc_type, confidentiality, status documento, sources linhagem, domain negocio, owner responsavel, team squad, versionamento documento, supersedes, valid_from, valid_until, regex validacao, enum valores, rejeicao explicita, warning log, parse front matter, heranca metadados, filtro pre-retrieval]
aliases:
  - "ADR-005"
  - "Contrato de Metadados"
  - "Front Matter YAML"
  - "Schema de Validacao Front Matter"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

# ADR-005 — Front Matter como Contrato de Metadados

## Contexto

No pipeline de 4 fases definido na [[BETA-001]], o front matter YAML e o mecanismo que conecta o trabalho humano (edicao de `.beta.md` no Obsidian) ao trabalho automatizado (pipeline de ingestao que gera `.md` final e alimenta a Base Vetorial).

Sem front matter valido, o pipeline nao sabe:

- O que e esse documento (tipo, dominio, sistema)
- Quem e responsavel por ele
- Qual o nivel de confidencialidade ([[BETA-004]])
- Se o documento esta vigente ou foi substituido
- De onde veio a informacao (linhagem)
- Qual a qualidade da conversao da fonte original

O front matter nao e um "detalhe tecnico" — e um **contrato** entre:

- **Autores** (humanos que editam `.beta.md` no Obsidian)
- **Pipeline de mineracao** (IA que gera/enriquece `.beta.md` na Fase 2)
- **Pipeline de promocao** (automacao que transforma `.beta.md` em `.md` na Fase 3)
- **Pipeline de ingestao** (automacao que ingere `.md` na Base Vetorial na Fase 4)
- **Sistema de retrieval** (agentes que buscam informacao na Base Vetorial)

Se qualquer parte desse contrato for violada (campo ausente, valor invalido, formato incorreto), o pipeline DEVE rejeitar o documento com mensagem de erro explicita — nunca aceitar silenciosamente dados incompletos.

Existem **dois niveis** de front matter, conforme [[BETA-001]]:

1. **Front matter leve** (`.beta.md`) — usado no repositorio `rag-workspace`. Contem apenas campos essenciais para a edicao humana e o enriquecimento pela IA. Intencionalmente simples para nao sobrecarregar autores humanos.
2. **Front matter rico** (`.md` final) — usado no repositorio `rag-knowledge-base`. Contem todos os campos necessarios para governanca, classificacao, temporalidade, QA e linhagem. Gerado automaticamente pelo pipeline de promocao (Fase 3) com enriquecimento dos campos leves.

Requisitos adicionais:

- Compatibilidade com Obsidian (YAML entre marcadores `---`)
- Suporte a temporalidade (`valid_from`/`valid_until`, conforme [[BETA-001]])
- Suporte a classificacao de dados (`confidentiality`, conforme [[BETA-004]])
- Schema de validacao executavel (nao apenas documentacao)
- Suporte a rastreabilidade de origem (linhagem da fonte ate a Base Vetorial)

## Decisao

Adotar front matter YAML como contrato de metadados obrigatorio em dois niveis (leve e rico), com schema de validacao executavel que rejeita documentos invalidos com mensagem explicita.

<!-- LOCKED:START autor=fabio data=2026-03-23 -->

### Parte A — Front Matter Leve (.beta.md) — Repositorio rag-workspace

O front matter leve e projetado para ser **simples** o suficiente para que um analista de negocio, PO ou especialista de dominio consiga preencher sem treinamento extenso, usando o Obsidian como editor.

Filosofia: conter o **MINIMO NECESSARIO** para que o pipeline funcione. Tudo que pode ser inferido ou enriquecido depois fica fora — reduzindo a carga cognitiva do autor humano.

Formato: YAML entre marcadores `---` no inicio do arquivo (compativel Obsidian).

#### Campos do front matter leve

**id** (obrigatorio, bloqueante)

- Tipo: `string`
- Formato: `BETA-{NNN}` (numerico sequencial, 3+ digitos)
- Regex: `^BETA-\d{3,}$`
- Exemplos: `id: BETA-001`, `id: BETA-042`, `id: BETA-1337`
- Identificador unico do documento no workspace. Necessario para rastreabilidade, referencia cruzada, historico de enriquecimento e linkagem no Obsidian via `[[BETA-001]]`.
- Validacao: obrigatorio (bloqueante), regex `^BETA-\d{3,}$`, unico no repositorio workspace.
- Mensagem de erro: `"Campo 'id' ausente ou formato invalido"`

**title** (obrigatorio, bloqueante)

- Tipo: `string`, max 200 caracteres
- Formato: texto livre, min 10 chars, max 200 chars
- Exemplo: `title: "Processo de conciliacao bancaria do modulo Cobranca"`
- Titulo legivel do documento. Usado para exibicao no Obsidian, contexto para a LLM durante retrieval, identificacao humana rapida e resultado de busca.
- Validacao: obrigatorio (bloqueante), minimo 10 caracteres, maximo 200 caracteres, nao aceitar titulos genericos.
- Mensagem de erro: `"Campo 'title' ausente ou muito curto"`

**domain** (obrigatorio, bloqueante)

- Tipo: `string`, enum aberto (sem lista fixa, com recomendacoes)
- Formato: lowercase, sem espacos (usar hifen), minimo 2 caracteres
- Exemplos: `domain: "financeiro"`, `domain: "tecnologia"`, `domain: "rh"`
- Dominio de negocio ao qual o documento pertence. Fundamental para filtro pre-retrieval ([[BETA-004]]), organizacao do conhecimento, roteamento de agentes e responsabilidade por area.
- Validacao: obrigatorio (bloqueante), minimo 2 caracteres, lowercase, sem espacos (usar hifen).
- Regex: `^[a-z][a-z0-9-]*$`
- Mensagem de erro: `"Campo 'domain' ausente ou formato invalido"`

**sources** (obrigatorio, bloqueante)

- Tipo: `array de objetos`
- Sub-campos:
  - `type` (obrigatorio): formato da fonte original. Valores validos: `pdf`, `docx`, `xlsx`, `pptx`, `email`, `confluence`, `sharepoint`, `jira`, `clickup`, `transcription`, `web`, `manual`, `md`, `json`, `csv`, `image`, `video`, `audio`.
  - `origin` (obrigatorio): caminho ou URL da fonte original. Formato livre.
  - `captured_at` (obrigatorio): data de captura da fonte, formato `AAAA-MM-DD`.
  - `conversion_quality` (opcional): score de qualidade da conversao desta fonte (0-100), calculado pelo pipeline na Fase 2.
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
- Relacao com `conversion_quality` do `.md` final: no `.beta.md`, `conversion_quality` e per-source (dentro de `sources[]`). No `.md` final, e consolidado via `min(sources[].conversion_quality)`.
- Validacao: obrigatorio (bloqueante), array com pelo menos 1 elemento, cada elemento deve ter `type`, `origin` e `captured_at` validos.
- Mensagem de erro: `"Campo 'sources' ausente ou incompleto"`

**tags** (obrigatorio, nao-bloqueante)

- Tipo: `array de strings`, minimo 3 manuais + 50 semanticas (total ~53+)
- Formato: cada tag lowercase, sem acentos; termos compostos separados por espaco (ex: "busca vetorial", "filtro pre-retrieval")
- Ordenacao: por relevancia decrescente — indice 0 = mais relevante ao contexto especifico do documento
- Composicao:
  - Tags manuais (autor humano): minimo 3, inseridas pelo autor ou curador. Focam em categorizacao de alto nivel e descoberta.
  - Tags semanticas (geradas por IA): exatamente 50 termos, gerados automaticamente na promocao `.txt` -> `.beta.md`. Extraidos do conteudo do documento, priorizando termos tecnicos e de dominio com maior proximidade ao contexto especifico. Termos genericos devem ser evitados salvo quando centrais ao documento.
- Regra de geracao das 50 tags semanticas:
  1. Analisar o conteudo completo do documento
  2. Identificar termos tecnicos, conceitos de dominio e nomes proprios
  3. Incluir termos compostos quando o significado exige (ex: "base vetorial")
  4. Ordenar por relevancia ao contexto especifico do documento
  5. Descartar termos excessivamente genericos
  6. Garantir exatamente 50 termos no array de tags semanticas
  7. Manter as tags manuais do autor nas primeiras posicoes
  8. Persistir em todos os formatos: `.beta.md`, `.md`, `.html`
- Validacao: warning se menos de 3 tags manuais, minimo 3 tags para promocao (bloqueante na Fase 3).
- Warning: `"tags: menos de 3 tags manuais. Adicione mais para descoberta."`

**status** (obrigatorio, bloqueante)

- Tipo: `string` (enum)
- Valores: `draft` | `in-review` | `approved`
- Controla o ciclo de vida do `.beta.md`: somente `approved` pode ser promovido a `.md`.
- Transicoes validas: `draft` -> `in-review` -> `approved`. Retorno permitido: `approved` -> `draft`.
- Validacao: obrigatorio (bloqueante), deve ser um dos 3 valores validos.
- Mensagem de erro: `"Campo 'status' ausente ou valor invalido"`

**confidentiality** (obrigatorio, bloqueante)

- Tipo: `string` (enum)
- Valores: `public` | `internal` | `restricted` | `confidential`
- Default: `internal`
- Nivel de classificacao de dados conforme [[BETA-004]]. Determina onde o documento pode ser processado (cloud vs on-premise, conforme [[BETA-002]]) e quem pode acessa-lo.
- **Excecao ao principio "governanca so no .md final"**: necessario desde a Fase 2 porque [[BETA-002]] usa `confidentiality` para rotear o documento pela trilha correta e [[BETA-004]] exige classificacao antes de qualquer processamento automatizado.
- Validacao: obrigatorio (bloqueante), deve ser um dos 4 valores validos.
- Mensagem de erro: `"Campo 'confidentiality' ausente ou valor invalido"`

**last_enrichment** (opcional, nao-bloqueante)

- Tipo: `string` (data ISO 8601), formato `AAAA-MM-DD`
- Exemplo: `last_enrichment: "2026-03-18"`
- Registra a data da ultima vez que o pipeline de IA enriqueceu o documento. Permite identificar documentos que nunca foram enriquecidos ou estagnados.
- Warning: `"last_enrichment nao preenchido. Sera atualizado no proximo enriquecimento."`

**last_human_edit** (opcional, nao-bloqueante)

- Tipo: `string` (data ISO 8601), formato `AAAA-MM-DD`
- Exemplo: `last_human_edit: "2026-03-20"`
- Registra a data da ultima edicao humana. Permite priorizar documentos para revisao e medir engajamento humano na curadoria.
- Warning: `"last_human_edit nao preenchido. Revisao humana recomendada."`

**aliases** (opcional, nao-bloqueante)

- Tipo: `array de strings`
- Formato: cada alias de 3-100 caracteres, sem duplicatas
- Exemplo: `aliases: ["Conciliacao Bancaria", "Retorno CNAB"]`
- Nomes alternativos reconhecidos nativamente pelo Obsidian para busca e descoberta (quick switcher via Ctrl+O).
- Validacao: opcional, se presente deve ser array de strings sem duplicatas.

#### Campos intencionalmente ausentes do front matter leve

- **system, module, owner, team**: campos de governanca que exigem conhecimento da estrutura organizacional. Preenchidos na Fase 3 pelo pipeline.
- **valid_from, valid_until, supersedes, superseded_by**: campos temporais definidos na promocao.
- **qa_score, qa_date, qa_status**: QA so se aplica ao `.md` final.
- **doc_type**: definido na promocao, pois o conteudo pode mudar de natureza durante a elaboracao.

#### Exemplo completo de .beta.md com front matter leve

```yaml
---
id: BETA-042
title: "Processo de conciliacao bancaria do modulo Cobranca"
domain: "financeiro"
confidentiality: internal
sources:
  - type: "pdf"
    origin: "sharepoint://financeiro/docs/conciliacao_v3.pdf"
    captured_at: "2026-03-15"
  - type: "transcription"
    origin: "teams://recordings/2026-03-12_reuniao_cobranca.mp4"
    captured_at: "2026-03-12"
tags: [conciliacao, cobranca, bancaria, boleto, retorno, cnab]
aliases: ["Conciliacao Bancaria", "Retorno CNAB"]
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

### Parte B — Front Matter Rico (.md final) — Repositorio rag-knowledge-base

O front matter rico e o contrato **completo** que o `.md` final carrega. E gerado pelo pipeline de promocao (Fase 3) a partir do front matter leve com enriquecimento de campos de governanca, classificacao e qualidade.

Os campos sao organizados em **8 grupos logicos**:

#### Grupo 1 — Identificacao

- **id**: `DOC-{NNNNNN}` (6 digitos, zero-padded). Regex: `^DOC-\d{6}$`. Identificador unico e definitivo na base de conhecimento. Permanente, referenciado pela Base Vetorial, chunks, relacoes e agentes. Diferente do `BETA-{NNN}` que e temporario no workspace.
- **doc_type**: enum (`system-doc`, `adr`, `runbook`, `glossary`, `task-doc`, `architecture-doc`, `policy`, `meeting-notes`, `onboarding`, `postmortem`). Determina estrategia de chunking, template de resposta do agente e filtro de busca.
- **title**: herdado do front matter leve.

#### Grupo 2 — Classificacao

- **system**: sistema corporativo (gera no `:System` na Base Vetorial). Permite filtro por sistema no retrieval e organizacao do grafo de conhecimento.
- **module**: modulo funcional (gera no `:Module` na Base Vetorial e relacao `BELONGS_TO` com System).
- **domain**: herdado do front matter leve (lowercase, sem espacos).
- **owner**: responsavel pelo conteudo (gera no `:Owner` e relacao `OWNED_BY`). Permite rastreabilidade de responsabilidade.
- **team**: time, squad, chapter ou diretoria (gera no `:Team` e relacao `MEMBER_OF`). Permite filtro por equipe.

#### Grupo 3 — Status e Governanca

- **status**: `draft` | `in-review` | `approved` | `deprecated`. Adiciona `deprecated` ao ciclo do `.beta.md`. Somente `approved` e ingerido na Base Vetorial. `deprecated` e mantido com ranking reduzido. Quando deprecated, campo `superseded_by` e obrigatorio.
- **confidentiality**: herdado do front matter leve, com as mesmas regras de classificacao ([[BETA-004]]).

#### Grupo 4 — Temporal

- **valid_from**: data de inicio de vigencia (formato `AAAA-MM-DD`). Permite consultas temporais no retrieval. Validacao: data valida, nao futura (excecao: politicas programadas).
- **valid_until**: data de fim de vigencia ou `null` (vigente indefinidamente). Quando preenchido, o documento deixa de ser retornado como vigente apos a data.
- **supersedes**: `DOC-{NNNNNN}` do documento anterior que este substitui. Gera relacao `SUPERSEDES` na Base Vetorial. Permite navegacao na cadeia de versoes.
- **superseded_by**: `DOC-{NNNNNN}` do documento que substitui este. Obrigatorio quando `status = deprecated`.

#### Grupo 5 — QA (Quality Assurance)

- **qa_score**: integer 0-100, score de qualidade calculado pelo pipeline de QA. Determina se o documento pode ser promovido.
- **qa_date**: data da ultima execucao do QA.
- **qa_status**: `passed` (>= 90%) | `warning` (80-89%) | `not_reviewed`.
- **qa_notes**: obrigatorio quando `qa_status = warning`. Documenta motivos e decisao de promover com ressalva. Rastreabilidade de decisoes de qualidade.

#### Grupo 6 — Descoberta

- **tags**: array com minimo 5 manuais + 50 semanticas (total ~55+), lowercase, sem acentos. Termos compostos separados por espaco. Ordenacao por relevancia decrescente. Tags manuais do autor nas primeiras posicoes + 50 tags semanticas geradas por IA mantidas da promocao `.txt` -> `.beta.md`.
- **aliases**: array com minimo 5 aliases para busca e wikilinks no Obsidian. No `.md` final, o requisito e mais rigoroso (5+) para maximizar a descoberta na Base Vetorial.

#### Grupo 7 — Linhagem

- **source_format**: formato principal da fonte (`original`, `pdf`, `docx`, `xlsx`, `pptx`, `email`, `confluence`, `sharepoint`, `jira`, `clickup`, `transcription`, `web`, `json`, `csv`, `image`, `video`, `audio`, `manual`, `multiple`). Permite analises de qualidade por formato.
- **source_repo**: repositorio Git de origem do `.beta.md`.
- **source_path**: caminho do `.beta.md` no workspace.
- **source_beta_ids**: array de `BETA-{NNN}` que originaram este `.md`. Rastreabilidade completa: de qual(is) `.beta.md` este `.md` foi gerado.
- **conversion_pipeline**: identificador do pipeline que gerou o `.md`.
- **conversion_quality**: integer 0-100, score consolidado via `min(sources[].conversion_quality)`. A funcao `min()` garante que a pior fonte determine o score final.
- **converted_at**: timestamp da conversao/promocao (formato ISO 8601).

#### Grupo 8 — Datas e Versionamento

- **created_at**: data de criacao do `.md` final.
- **updated_at**: data da ultima atualizacao. Validacao: `>= created_at`.
- **release_version**: versao da release que disparou a ingestao (formato semver `vN.N.N`). Preenchido automaticamente pelo pipeline de ingestao ([[BETA-006]]). Permite rastrear qual versao do conhecimento esta ativa.

#### Exemplo completo de .md final com front matter rico

```yaml
---
# === IDENTIFICACAO ===
id: DOC-000042
doc_type: system-doc
title: "Processo de conciliacao bancaria do modulo Cobranca"

# === CLASSIFICACAO ===
system: Cobranca
module: Conciliacao
domain: financeiro
owner: maria.silva
team: squad-pagamentos

# === STATUS E GOVERNANCA ===
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
qa_notes: "Score 85% -- inferencias sobre custos cloud nao verificadas. Aprovado com ressalva pelo PO em 21/03/2026."

# === DESCOBERTA ===
tags: [conciliacao, cobranca, bancaria, boleto, retorno, cnab, financeiro, banco-do-brasil, arquivo-retorno, cnab-240]
aliases: ["Conciliacao Bancaria", "Retorno CNAB", "Arquivo de Retorno", "Conciliacao de Cobranca", "Processamento CNAB 240"]

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

## Schema de Validacao (Parte C)

O schema de validacao e um componente **executavel** do pipeline — nao apenas documentacao. Ele roda em dois momentos:

1. Na Fase 2 (enriquecimento): valida o front matter leve do `.beta.md`
2. Na Fase 3 (promocao): valida o front matter rico do `.md` final

**Regra fundamental**: rejeicao **EXPLICITA**, nunca skip silencioso.

### Classificacao: bloqueante vs nao-bloqueante

- **Bloqueante**: documento e REJEITADO se o campo esta ausente ou invalido. Pipeline para, registra erro, notifica responsavel.
- **Nao-bloqueante (warning)**: documento e ACEITO, mas alerta e registrado no log. Documento aparece em relatorio de "documentos com alertas".

### Regras de validacao — Front matter leve (.beta.md)

**Campos bloqueantes** (documento rejeitado se invalido):

| Campo | Regra | Regex/Formato | Mensagem de erro |
|---|---|---|---|
| `id` | Presente, formato valido, unico | `^BETA-\d{3,}$` | "Campo 'id' ausente ou formato invalido" |
| `title` | Presente, 10-200 chars, nao generico | `len >= 10 AND len <= 200` | "Campo 'title' ausente ou muito curto" |
| `domain` | Presente, >= 2 chars, lowercase, sem espacos | `^[a-z][a-z0-9-]*$`, len >= 2 | "Campo 'domain' ausente ou formato invalido" |
| `sources` | Presente, array >= 1 elem, sub-campos ok | array, each: type+origin+captured_at | "Campo 'sources' ausente ou incompleto" |
| `status` | Presente, enum valido | `^(draft\|in-review\|approved)$` | "Campo 'status' ausente ou valor invalido" |
| `confidentiality` | Presente, enum valido | `^(public\|internal\|restricted\|confidential)$` | "Campo 'confidentiality' ausente ou valor invalido" |

Validacao de sub-campos de `sources[]`:

- `type`: obrigatorio, deve ser um dos valores validos do enum source_type
- `origin`: obrigatorio, string nao vazia
- `captured_at`: obrigatorio, formato `AAAA-MM-DD`, data valida
- `conversion_quality`: opcional, se presente deve ser integer 0-100

**Campos com warning** (documento aceito, alerta emitido):

| Campo | Regra | Warning |
|---|---|---|
| `tags` | Array >= 3 elementos | "tags: menos de 3 tags. Adicione mais para melhor descoberta." |
| `last_enrichment` | Data valida se presente | "last_enrichment nao preenchido. Sera atualizado no proximo enriquecimento." |
| `last_human_edit` | Data valida se presente | "last_human_edit nao preenchido. Revisao humana recomendada." |
| `aliases` | Array sem duplicatas | (sem warning especifico, apenas validacao de formato) |

**NOTA**: tags com menos de 3 sao warning na Fase 2, mas BLOQUEANTE na Fase 3 (promocao exige minimo 3 tags).

### Regras de validacao — Front matter rico (.md final)

Todos os campos do front matter rico sao bloqueantes na promocao, exceto os marcados como "opcional, nao-bloqueante".

**Campos bloqueantes adicionais** (alem dos herdados do leve):

| Campo | Regra |
|---|---|
| `id` | Formato `DOC-{NNNNNN}`, regex `^DOC-\d{6}$`, unico |
| `doc_type` | Enum valido |
| `system` | Sistema cadastrado (string nao vazia) |
| `module` | Modulo do sistema indicado (string nao vazia) |
| `owner` | Usuario cadastrado (string nao vazia) |
| `team` | Time cadastrado (string nao vazia) |
| `valid_from` | Data valida, nao futura* |
| `tags` | Array >= 5 elementos (mais restritivo que `.beta.md`) |
| `aliases` | Array >= 5 elementos |
| `source_format` | Enum valido |
| `source_repo` | String nao vazia |
| `source_path` | String nao vazia |
| `source_beta_ids` | Array de strings formato `BETA-{NNN}` |
| `conversion_pipeline` | String nao vazia |
| `conversion_quality` | Integer 0-100 |
| `created_at` | Data valida |
| `updated_at` | Data valida, >= `created_at` |
| `converted_at` | Timestamp ISO 8601 valido |
| `qa_score` | Integer 0-100 |
| `qa_date` | Data valida |
| `qa_status` | Enum valido |

*`valid_from` pode ser futura para politicas programadas (excecao documentada).

**Campos condicionalmente obrigatorios:**

| Campo | Condicao | Regra |
|---|---|---|
| `superseded_by` | `status = deprecated` | `DOC-{NNNNNN}` obrigatorio |
| `qa_notes` | `qa_status = warning` | String nao vazia obrigatoria |

### Comportamento quando validacao falha

**Campo BLOQUEANTE invalido:**

1. Documento e REJEITADO (nao processado)
2. Mensagem de erro registrada no log com: identificador do documento, campo invalido, valor encontrado, valor esperado, sugestao de correcao
3. Notificacao enviada ao responsavel
4. Documento aparece em relatorio de "documentos pendentes"

**Campo com WARNING invalido:**

1. Documento e ACEITO (processamento continua)
2. Warning registrado no log
3. Documento aparece em relatorio de "documentos com alertas"

**Principio fundamental**: NUNCA aceitar silenciosamente dados incompletos ou invalidos. Se o campo e bloqueante, o pipeline PARA. Se o campo e warning, o pipeline CONTINUA mas REGISTRA. Em nenhum caso o pipeline ignora silenciosamente.

### Valores validos para enums

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
| `domain` | `^[a-z][a-z0-9-]*$` (minimo 2 chars) |
| `status` (.beta.md) | `^(draft\|in-review\|approved)$` |
| `status` (.md) | `^(draft\|in-review\|approved\|deprecated)$` |
| `confidentiality` | `^(public\|internal\|restricted\|confidential)$` |
| `captured_at` | `^\d{4}-\d{2}-\d{2}$` (validar como data real) |
| `conversion_quality` | `^\d{1,3}$` (0-100, validar range) |

## Conversion Quality (Parte D)

O campo `conversion_quality` expressa a confianca na fidelidade da conversao da fonte original para o formato `.md`. Score de 0 a 100% calculado pelo pipeline de conversao na Fase 2 ([[BETA-001]]).

Dois niveis de registro:

- No `.beta.md`: `conversion_quality` e **per-source** (dentro de `sources[]`)
- No `.md` final: `conversion_quality` e **consolidado** via `min(sources[].conversion_quality)`

### Formula de calculo

```
conversion_quality = min(
    media_ponderada(sinais_do_formato),
    penalidade_por_erro_critico
)
```

A funcao `min()` garante que um erro critico **sempre** reduz o score, mesmo que os outros sinais sejam bons.

Consolidacao para `.md` final: `conversion_quality_final = min(sources[].conversion_quality)`. A pior fonte entre todas determina o score final.

### Sinais por formato de origem

| Formato | Sinais | Peso |
|---|---|---|
| **MD nativo** | 100% automatico (sem conversao) | - |
| **PDF texto** | % caracteres reconhecidos (40%), headings preservados (30%), tabelas (20%), links (10%) | - |
| **PDF escaneado (OCR)** | Confidence OCR (50%), resolucao DPI (20%), % texto reconhecido (20%), idioma (10%) | - |
| **DOCX** | Conversao deterministica (30%), estilos preservados (30%), tabelas (20%), imagens com alt (20%) | - |
| **XLSX** | Tabelas convertidas (40%), formulas identificadas (20%), merges resolvidos (20%), abas processadas (20%) | - |
| **PPTX** | Slides convertidos (30%), notas do apresentador (25%), imagens descritas (25%), ordem logica (20%) | - |
| **Email** | Headers completos (30%), corpo HTML->MD (30%), anexos (25%), thread preservada (15%) | - |
| **Transcricao (audio/video)** | WER do STT (40%), identificacao de falantes (25%), timestamps (15%), sobreposicao tratada (20%) | - |
| **Confluence** | Estrutura HTML preservada (30%), macros expandidas (25%), links internos (25%), anexos (20%) | - |
| **Web** | HTML->MD com estrutura (35%), navegacao removida (25%), imagens com alt (20%), links resolvidos (20%) | - |
| **JSON / Ticket (Jira, ClickUp)** | Campos extraidos (40%), historico preservado (25%), comentarios (20%), anexos (15%) | - |
| **CSV** | Headers identificados (30%), tipos inferidos (25%), encoding correto (25%), delimitador (20%) | - |
| **Image** | OCR confidence (50%), descricao por VLM (30%), resolucao suficiente (20%) | - |
| **Manual** | Score definido pelo humano (100%) | - |

### Thresholds de decisao

| Score | Acao |
|---|---|
| >= 80% | **Ingestao automatica**. `.beta.md` gerado e processado sem intervencao humana. Status: `draft`. |
| 30% a 79% | **Revisao humana obrigatoria**. `.beta.md` gerado com flag `requires_human_review`. Pipeline emite warning com sinais de score baixo. |
| < 30% | **Rejeicao**. `.beta.md` nao gerado. Fonte rejeitada. Log com detalhes. Humano deve providenciar fonte melhor ou conversao manual. |

Os thresholds (80% e 30%) sao configuraveis por organizacao via config do pipeline.

### Relacao entre conversion_quality e QA

- **conversion_quality**: calculado na Fase 2, mede fidelidade da EXTRACAO (fonte original -> markdown), per-source no `.beta.md`, consolidado no `.md` final.
- **qa_score**: calculado na Fase 3, mede qualidade do CONTEUDO (completude, clareza, estrutura), aplicado ao documento como um todo.

Sao metricas complementares: um documento pode ter `conversion_quality` alto (boa extracao) mas `qa_score` baixo (conteudo incompleto), e vice-versa.

### Exemplos praticos

**PDF texto de boa qualidade:**

```yaml
sources:
  - type: "pdf"
    origin: "sharepoint://financeiro/manual_cobranca_v3.pdf"
    captured_at: "2026-03-15"
    conversion_quality: 92
```

Sinais: 95% chars reconhecidos, headings 100%, tabelas 85%, links 80%. Score: `0.95*0.4 + 1.0*0.3 + 0.85*0.2 + 0.80*0.1 = 93`. Nenhum erro critico -> score final 92. Gate: >= 80% -> ingestao automatica.

**Transcricao de reuniao com ruido:**

```yaml
sources:
  - type: "transcription"
    origin: "teams://recordings/2026-03-12_reuniao.mp4"
    captured_at: "2026-03-12"
    conversion_quality: 67
```

Sinais: WER 25% (ruim), falantes 80%, timestamps 90%, sobreposicao 40%. Score: `0.75*0.4 + 0.80*0.25 + 0.90*0.15 + 0.40*0.20 = 71.5`. Penalidade por WER alto -> score final 67. Gate: 30-79% -> revisao humana obrigatoria.

**Consolidacao para .md final (multiplas fontes):**

`conversion_quality_final = min(92, 67) = 67`. A pior fonte determina o score consolidado.

## Compatibilidade com Obsidian (Parte E)

O Obsidian e o editor recomendado para edicao de `.beta.md` ([[BETA-001]], Fase 2). O front matter deve ser 100% compativel.

O Obsidian foi escolhido porque:

- Renderiza front matter YAML no painel de propriedades (Properties view)
- Suporta wikilinks nativamente (`[[BETA-001]]`)
- Aceita qualquer campo personalizado no front matter sem configuracao extra
- Funciona como editor local (offline), sem dependencia de servidor
- Possui ecossistema de plugins para produtividade

### YAML entre marcadores ---

O front matter **deve** estar entre marcadores `---` no inicio do arquivo. O Obsidian renderiza os campos no painel de propriedades (Properties view).

### Tags como array YAML

Tags devem ser arrays YAML, **nao** a sintaxe `#tag` no front matter:

- **Correto**: `tags: [conciliacao, cobranca, boleto]`
- **Incorreto**: `tags: #conciliacao #cobranca #boleto`

No corpo do documento (abaixo do `---`), tags `#tag` podem ser usadas normalmente. O Obsidian indexa ambas as formas.

### Aliases para busca e descoberta

O campo `aliases` e reconhecido nativamente pelo Obsidian. Permite encontrar o documento pelo Quick Switcher (Ctrl+O) usando qualquer alias.

### Wikilinks no corpo, nao no front matter

Wikilinks (`[[DOC-000042]]`) devem ser usados apenas no **corpo** do documento, nunca no front matter. O front matter e YAML puro e wikilinks podem quebrar parsers. Wikilinks cross-KB sao **PROIBIDOS** (ex: documento public nao linka para restricted).

### Campos personalizados

O Obsidian aceita qualquer campo no front matter YAML. Campos como `qa_score`, `conversion_quality`, etc. sao exibidos no painel de propriedades sem configuracao adicional. Nao e necessario plugin especial.

### Blocos LOCKED

Humanos podem marcar trechos como protegidos contra sobrescrita pela IA:

```
<!-- LOCKED:START autor=fabio data=2026-03-21 -->
Este trecho foi validado e nao deve ser alterado pela IA.
<!-- LOCKED:END -->
```

Regras:
- IA pode adicionar conteudo novo FORA dos blocos locked
- IA NUNCA altera conteudo DENTRO de `LOCKED:START`/`END`
- IA pode sugerir mudancas em blocos locked como comentario separado
- Humano pode remover o lock a qualquer momento

### Plugins recomendados

- **Templates** (Core Plugin): template com front matter pre-preenchido
- **Templater** (Community Plugin): insercao automatica de data, geracao de id sequencial, preenchimento de domain baseado na pasta
- **Git** (Community Plugin, obsidian-git): commit automatico, pull/push sem sair do editor, visualizacao de diff
- **Dataview** (Community Plugin): tabelas e listas dinamicas baseadas no front matter (util para Curador monitorar estado dos documentos)

### Compatibilidade e limitacoes

- O Obsidian nao e obrigatorio — qualquer editor que preserve YAML front matter entre marcadores `---` funciona (VS Code, Typora, etc.)
- Se o Obsidian for descontinuado, a migracao e trivial: os arquivos sao Markdown puro com YAML, sem formato proprietario
- O Obsidian nao edita o `.md` final (knowledge-base) — apenas o `.beta.md` (workspace)

## Alternativas Descartadas

### Front matter unico (mesmo schema para .beta.md e .md)

Rejeitada porque sobrecarrega o autor humano com campos que ele nao sabe preencher, aumenta taxa de erros e campos de governanca preenchidos pelo autor podem estar incorretos.

### Metadados em arquivo separado (sidecar)

Rejeitada porque duplica arquivos, risco de dessincronizacao, Obsidian nao reconhece sidecar e YAML embutido e o padrao da industria.

### Metadados apenas na Base Vetorial (sem front matter)

Rejeitada porque perde rastreabilidade, exige logica complexa de inferencia, impossibilita validacao pre-ingestao e viola principio "documento autoexplicativo" ([[BETA-001]], Pilar E).

### JSON em vez de YAML

Rejeitada porque JSON nao e suportado pelo Obsidian como front matter, YAML e mais legivel para humanos e e o padrao da industria.

### Schema de validacao opcional (best-effort)

Rejeitada porque em ambiente regulado "best-effort" nao e aceitavel, documentos invalidos poluem a Base Vetorial e warning sem rejeicao e warning ignorado.

## Consequencias

### Positivas

- Contrato claro entre autores e pipeline — sem ambiguidade
- Dois niveis de front matter respeitam a maturidade do documento
- Validacao executavel garante qualidade minima
- Rejeicao explicita evita poluicao da Base Vetorial
- 100% compativel com Obsidian (zero config adicional)
- Rastreabilidade completa: da fonte ate o chunk na Base Vetorial
- `conversion_quality` permite automacao inteligente (auto vs review vs rejeicao)
- Campos temporais habilitam consultas historicas

### Negativas / Trade-offs

- Curva de aprendizado para autores (mitigado por templates no Obsidian)
- Campos bloqueantes podem frustrar autores que querem contribuir rapidamente (mitigado pelo front matter leve com poucos campos obrigatorios)
- Manutencao de enums: listas de valores validos precisam ser atualizadas quando novos tipos surgem
- Dois schemas (leve e rico) e mais complexo que um so

### Riscos

- Front matter incorreto bloqueando ingestao em massa (mitigacao: versionamento do schema, migracao automatica)
- `conversion_quality` parcialmente subjetivo (mitigacao: calibracao periodica com revisao humana)
- Obsidian descontinuado (mitigacao: qualquer editor com suporte a YAML front matter funciona)

## Implementacao

| Fase | Entrega | Dependencia |
|---|---|---|
| 1-MVP | Schema leve definido, validador basico, template Obsidian | [[BETA-001]] Fase 1 |
| 2 | Schema rico definido, validador completo, enums centralizados, relatorio de rejeitados, `conversion_quality` | [[BETA-001]] Fase 2 |
| 3 | Pipeline de promocao (leve -> rico), sugestao automatica de governanca, validacao de classificacao ([[BETA-004]]), QA automatizado | [[BETA-001]] Fase 3 |
| 4 | Temporalidade completa, schema versionado com migracao, dashboard de cobertura, auditoria de classificacao | [[BETA-001]] Fase 4 |

## Referencias

### Internas

- [[BETA-001]] — Pipeline de Geracao de Conhecimento em 4 Fases (secoes 2.5, 2.5.1, 2.6)
- [[BETA-002]] — Soberania e Residencia de Dados
- [[BETA-003]] — Modelo de Dados da Base Vetorial
- [[BETA-004]] — Estrategia de Seguranca e Classificacao de Dados
- [[BETA-006]] — Pipeline de Ingestao (consome front matter na Etapa 2)
- [[BETA-007]] — Retrieval Hibrido e Agentes
- [[BETA-009]] — Selecao de Modelos de Embedding
- [[BETA-010]] — Git Flow da Base de Conhecimento
- [[BETA-011]] — Segregacao de KBs

### Externas

- [YAML Specification 1.2](https://yaml.org/spec/1.2.2/)
- [Obsidian Properties](https://help.obsidian.md/Editing+and+formatting/Properties)
- [Hugo Front Matter](https://gohugo.io/content-management/front-matter/)
- [Jekyll Front Matter](https://jekyllrb.com/docs/front-matter/)

<!-- conversion_quality: 95 -->
