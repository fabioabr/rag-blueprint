---
id: ADR-005
doc_type: adr
title: "Front Matter como Contrato de Metadados"
system: RAG Corporativo
module: Metadados e Governança
domain: Arquitetura
owner: fabio
team: arquitetura
status: approved
confidentiality: internal
date_decided: 2026-03-21
tags:
  - adr
  - front-matter
  - metadados
  - contrato
  - validacao
  - yaml
  - obsidian
  - schema
  - linhagem
  - governanca
aliases:
  - ADR-005
  - Contrato de Metadados
  - Front Matter YAML
  - Schema de Validacao Front Matter
  - Front Matter Obrigatorio
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-kb/beta/ADR-005_front_matter_contrato_metadados.beta.md"
source_beta_ids:
  - "BETA-005"
conversion_pipeline: promotion-pipeline-v1
conversion_quality: 100
converted_at: 2026-03-22
qa_score: 99
qa_date: 2026-03-22
qa_status: passed
created_at: 2026-03-21
updated_at: 2026-03-22
valid_from: 2026-03-21
valid_until: null
---

# ADR-005 — Front Matter como Contrato de Metadados

| Campo       | Valor                                                         |
|-------------|---------------------------------------------------------------|
| **Status**  | Accepted                                                      |
| **Data**    | 21/03/2026                                                    |
| **Decisor** | fabio (arquitetura)                                           |
| **Escopo**  | Front matter YAML como contrato de metadados em dois níveis (leve e rico) |

**Referências cruzadas:**

- [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]]: Pipeline de geração de conhecimento em 4 fases
- [[ADR-002_soberania_dados_cloud_vs_onprem|ADR-002]]: Soberania e residência de dados
- [[ADR-003_modelo_dados_base_vetorial|ADR-003]]: Modelo de dados da Base Vetorial
- [[ADR-004_seguranca_classificacao_dados|ADR-004]]: Estratégia de segurança e classificação de dados
- [[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]]: Pipeline de ingestão
- [[ADR-007_retrieval_hibrido_agentes|ADR-007]]: Retrieval híbrido e agentes
- [[ADR-009_selecao_modelos_embedding|ADR-009]]: Seleção de modelos de embedding
- [[ADR-010_git_flow_base_conhecimento|ADR-010]]: Git flow da base de conhecimento
- [[ADR-011_segregacao_kbs_por_confidencialidade|ADR-011]]: Segregação de KBs por confidencialidade

---

## Contexto

No pipeline de 4 fases definido na [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]], o front matter YAML e o mecanismo que conecta o trabalho humano (edicao de `.beta.md` no Obsidian) ao trabalho automatizado (pipeline de ingestao que gera `.md` final e alimenta a Base Vetorial).

Sem front matter valido, o pipeline nao sabe:

- O que e esse documento (tipo, dominio, sistema)
- Quem e responsavel por ele
- Qual o nivel de confidencialidade ([[ADR-004_seguranca_classificacao_dados|ADR-004]])
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

Existem **dois niveis** de front matter, conforme [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]]:

1. **Front matter leve** (`.beta.md`) — usado no repositorio `rag-workspace`. Contem apenas campos essenciais para a edicao humana e o enriquecimento pela IA. Intencionalmente simples para nao sobrecarregar autores humanos.
2. **Front matter rico** (`.md` final) — usado no repositorio `rag-knowledge-base`. Contem todos os campos necessarios para governanca, classificacao, temporalidade, QA e linhagem. Gerado automaticamente pelo pipeline de promocao (Fase 3) com enriquecimento dos campos leves.

Requisitos adicionais:

- Compatibilidade com Obsidian (YAML entre marcadores `---`)
- Suporte a temporalidade (`valid_from`/`valid_until`, conforme [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]])
- Suporte a classificacao de dados (`confidentiality`, conforme [[ADR-004_seguranca_classificacao_dados|ADR-004]])
- Schema de validacao executavel (nao apenas documentacao)
- Suporte a rastreabilidade de origem (linhagem da fonte ate a Base Vetorial)

## Decisao

Adotar front matter YAML como contrato de metadados obrigatorio em dois niveis (leve e rico), com schema de validacao executavel que rejeita documentos invalidos com mensagem explicita.

### Parte A — Front Matter Leve (.beta.md) — Repositorio rag-workspace

O front matter leve e projetado para ser **simples** o suficiente para que um analista de negocio, PO ou especialista de dominio consiga preencher sem treinamento extenso, usando o Obsidian como editor.

#### Campos do front matter leve

**id** (obrigatorio, bloqueante)

- Tipo: `string`
- Formato: `BETA-{NNN}` (numerico sequencial, 3+ digitos)
- Exemplo: `id: BETA-001`, `id: BETA-042`, `id: BETA-1337`
- Identificador unico do documento no workspace. Necessario para rastreabilidade, referencia cruzada, historico de enriquecimento e linkagem no Obsidian via `[[BETA-001]]`.
- Validacao: obrigatorio (bloqueante), regex `^BETA-\d{3,}$`, unico no repositorio workspace.

**title** (obrigatorio, bloqueante)

- Tipo: `string`, max 200 caracteres
- Exemplo: `title: "Processo de conciliacao bancaria do modulo Cobranca"`
- Titulo legivel do documento. Usado para exibicao no Obsidian, contexto para a LLM durante retrieval, identificacao humana rapida e resultado de busca.
- Validacao: obrigatorio (bloqueante), minimo 10 caracteres, maximo 200 caracteres, nao aceitar titulos genericos.

**domain** (obrigatorio, bloqueante)

- Tipo: `string`, enum aberto (sem lista fixa, com recomendacoes)
- Exemplo: `domain: "financeiro"`, `domain: "tecnologia"`, `domain: "rh"`
- Dominio de negocio ao qual o documento pertence. Fundamental para filtro pre-retrieval ([[ADR-004_seguranca_classificacao_dados|ADR-004]]), organizacao do conhecimento, roteamento de agentes e responsabilidade por area.
- Validacao: obrigatorio (bloqueante), minimo 2 caracteres, lowercase, sem espacos (usar hifen).

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

**tags** (obrigatorio, nao-bloqueante)

- Tipo: `array de strings`, minimo 3 tags (recomendado 5+)
- Exemplo: `tags: [conciliacao, cobranca, bancaria, boleto, financeiro]`
- Permite busca por facetas, categorizacao e descoberta no Obsidian e no retrieval.
- Nao-bloqueante: o pipeline de IA pode sugeri-las automaticamente na Fase 2.
- Validacao: warning se ausente, cada tag lowercase sem espacos, minimo 3 tags para promocao (bloqueante na Fase 3).

**status** (obrigatorio, bloqueante)

- Tipo: `string` (enum)
- Valores: `draft` | `in-review` | `approved`
- Controla o ciclo de vida do `.beta.md`: somente `approved` pode ser promovido a `.md`.
- Transicoes validas: `draft` -> `in-review` -> `approved`. Retorno permitido: `approved` -> `draft`.
- Validacao: obrigatorio (bloqueante), deve ser um dos 3 valores validos.

**last_enrichment** (opcional, nao-bloqueante)

- Tipo: `string` (data ISO 8601), formato `AAAA-MM-DD`
- Registra a data da ultima vez que o pipeline de IA enriqueceu o documento. Permite identificar documentos que nunca foram enriquecidos ou estagnados.

**last_human_edit** (opcional, nao-bloqueante)

- Tipo: `string` (data ISO 8601), formato `AAAA-MM-DD`
- Registra a data da ultima edicao humana. Permite priorizar documentos para revisao e medir engajamento humano na curadoria.

**confidentiality** (obrigatorio, bloqueante)

- Tipo: `string` (enum)
- Valores: `public` | `internal` | `restricted` | `confidential`
- Default: `internal`
- Nivel de classificacao de dados conforme [[ADR-004_seguranca_classificacao_dados|ADR-004]]. Determina onde o documento pode ser processado (cloud vs on-premise, conforme [[ADR-002_soberania_dados_cloud_vs_onprem|ADR-002]]) e quem pode acessa-lo.
- **Excecao ao principio "governanca so no .md final"**: necessario desde a Fase 2 porque [[ADR-002_soberania_dados_cloud_vs_onprem|ADR-002]] usa `confidentiality` para rotear o documento pela trilha correta e [[ADR-004_seguranca_classificacao_dados|ADR-004]] exige classificacao antes de qualquer processamento automatizado.
- Validacao: obrigatorio (bloqueante), deve ser um dos 4 valores validos.

**aliases** (opcional, nao-bloqueante)

- Tipo: `array de strings`
- Exemplo: `aliases: ["Conciliacao Bancaria", "Retorno CNAB"]`
- Nomes alternativos reconhecidos nativamente pelo Obsidian para busca e descoberta.
- Validacao: opcional, se presente deve ser array de strings sem duplicatas, cada alias de 3-100 caracteres.

#### Campos intencionalmente ausentes do front matter leve

- **system, module, owner, team**: campos de governanca que exigem conhecimento da estrutura organizacional. Preenchidos na Fase 3 pelo pipeline.
- **valid_from, valid_until, supersedes, superseded_by**: campos temporais definidos na promocao.
- **qa_score, qa_date, qa_status**: QA so se aplica ao `.md` final.
- **doc_type**: definido na promocao, pois o conteudo pode mudar de natureza durante a elaboracao.

Filosofia: o front matter leve contem o **minimo necessario** para que o pipeline funcione. Tudo que pode ser inferido ou enriquecido depois fica fora — reduzindo a carga cognitiva do autor humano.

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

### Parte B — Front Matter Rico (.md final) — Repositorio rag-knowledge-base

O front matter rico e o contrato **completo** que o `.md` final carrega. E gerado pelo pipeline de promocao (Fase 3) a partir do front matter leve com enriquecimento de campos de governanca, classificacao e qualidade.

Os campos sao organizados em **8 grupos logicos**:

#### Grupo 1 — Identificacao

- **id**: `DOC-{NNNNNN}` (6 digitos, zero-padded). Identificador unico e definitivo na base de conhecimento. Permanente, referenciado pela Base Vetorial, chunks, relacoes e agentes.
- **doc_type**: enum (`system-doc`, `adr`, `runbook`, `glossary`, `task-doc`, `architecture-doc`, `policy`, `meeting-notes`, `onboarding`, `postmortem`). Determina estrategia de chunking, template de resposta do agente e filtro de busca.
- **title**: herdado do front matter leve.

#### Grupo 2 — Classificacao

- **system**: sistema corporativo (gera no `:System` na Base Vetorial)
- **module**: modulo funcional (gera no `:Module` na Base Vetorial)
- **domain**: herdado do front matter leve
- **owner**: responsavel pelo conteudo (gera no `:Owner` e relacao `OWNED_BY`)
- **team**: time, squad, chapter ou diretoria (gera no `:Team` e relacao `MEMBER_OF`)

#### Grupo 3 — Status e Governanca

- **status**: `draft` | `in-review` | `approved` | `deprecated`. Adiciona `deprecated` ao ciclo do `.beta.md`. Somente `approved` e ingerido na Base Vetorial. `deprecated` e mantido com ranking reduzido.
- **confidentiality**: herdado do front matter leve, com as mesmas regras de classificacao ([[ADR-004_seguranca_classificacao_dados|ADR-004]]).

#### Grupo 4 — Temporal

- **valid_from**: data de inicio de vigencia (formato `AAAA-MM-DD`). Permite consultas temporais no retrieval.
- **valid_until**: data de fim de vigencia ou `null` (vigente indefinidamente).
- **supersedes**: `DOC-{NNNNNN}` do documento anterior que este substitui. Gera relacao `SUPERSEDES` na Base Vetorial.
- **superseded_by**: `DOC-{NNNNNN}` do documento que substitui este. Obrigatorio quando `status = deprecated`.

#### Grupo 5 — QA (Quality Assurance)

- **qa_score**: integer 0-100, score de qualidade calculado pelo pipeline de QA.
- **qa_date**: data da ultima execucao do QA.
- **qa_status**: `passed` (>= 90%) | `warning` (80-89%) | `not_reviewed`.
- **qa_notes**: obrigatorio quando `qa_status = warning`. Documenta motivos e decisao de promover com ressalva.

#### Grupo 6 — Descoberta

- **tags**: array com minimo 5 tags (mais restritivo que `.beta.md`), lowercase, sem espacos.
- **aliases**: array com minimo 5 aliases para busca e wikilinks no Obsidian.

#### Grupo 7 — Linhagem

- **source_format**: formato principal da fonte (`original`, `pdf`, `docx`, `xlsx`, `pptx`, `email`, `confluence`, `sharepoint`, `jira`, `clickup`, `transcription`, `web`, `json`, `csv`, `image`, `video`, `audio`, `manual`, `multiple`).
- **source_repo**: repositorio Git de origem do `.beta.md`.
- **source_path**: caminho do `.beta.md` no workspace.
- **source_beta_ids**: array de `BETA-{NNN}` que originaram este `.md`.
- **conversion_pipeline**: identificador do pipeline que gerou o `.md`.
- **conversion_quality**: integer 0-100, score consolidado via `min(sources[].conversion_quality)`.
- **converted_at**: timestamp da conversao/promocao.

#### Grupo 8 — Datas e Versionamento

- **created_at**: data de criacao do `.md` final.
- **updated_at**: data da ultima atualizacao.
- **release_version**: versao da release que disparou a ingestao (formato semver `vN.N.N`). Preenchido automaticamente pelo pipeline de ingestao ([[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]]).

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
qa_notes: "Score 85% — inferencias sobre custos cloud nao verificadas. Aprovado com ressalva pelo PO em 21/03/2026."

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

## Schema de Validacao (Parte C)

O schema de validacao e um componente **executavel** do pipeline — nao apenas documentacao. Ele roda em dois momentos:

1. Na Fase 2 (enriquecimento): valida o front matter leve do `.beta.md`
2. Na Fase 3 (promocao): valida o front matter rico do `.md` final

### Regras de validacao — Front matter leve (.beta.md)

**Campos bloqueantes** (documento rejeitado se invalido):

| Campo | Regra | Mensagem de erro |
|---|---|---|
| `id` | Presente, regex `^BETA-\d{3,}$`, unico | "Campo 'id' ausente ou formato invalido" |
| `title` | Presente, 10-200 chars, nao generico | "Campo 'title' ausente ou muito curto" |
| `domain` | Presente, >= 2 chars, lowercase, sem espacos | "Campo 'domain' ausente ou formato invalido" |
| `sources` | Presente, array >= 1, cada elem com type/origin/captured_at validos | "Campo 'sources' ausente ou incompleto" |
| `status` | Presente, enum valido (draft, in-review, approved) | "Campo 'status' ausente ou valor invalido" |
| `confidentiality` | Presente, enum valido (public, internal, restricted, confidential) | "Campo 'confidentiality' ausente ou valor invalido" |

**Campos com warning** (documento aceito, alerta emitido):

| Campo | Regra | Warning |
|---|---|---|
| `tags` | Array >= 3 elementos | "tags: menos de 3 tags. Adicione mais para melhor descoberta." |
| `last_enrichment` | Data valida se presente | "last_enrichment nao preenchido. Sera atualizado no proximo enriquecimento." |
| `last_human_edit` | Data valida se presente | "last_human_edit nao preenchido. Revisao humana recomendada." |

### Regras de validacao — Front matter rico (.md final)

Todos os campos do front matter rico sao bloqueantes na promocao, exceto os marcados como "opcional, nao-bloqueante" na Parte B.

Campos bloqueantes adicionais (alem dos herdados do leve):

| Campo | Regra |
|---|---|
| `doc_type` | Enum valido |
| `system` | Sistema cadastrado |
| `module` | Modulo do sistema indicado |
| `owner` | Usuario cadastrado |
| `team` | Time cadastrado |
| `valid_from` | Data valida, nao futura* |
| `tags` | Array >= 5 elementos |
| `aliases` | Array >= 5 elementos |
| `source_format` | Enum valido |
| `source_repo` | String nao vazia |
| `conversion_pipeline` | String nao vazia |
| `conversion_quality` | Integer 0-100 |
| `created_at` | Data valida |
| `updated_at` | Data valida, >= created_at |

*`valid_from` pode ser futura para politicas programadas.

### Comportamento quando validacao falha

**Regra fundamental**: rejeicao **explicita**, nunca skip silencioso.

Quando um campo **bloqueante** falha:

1. Documento e rejeitado (nao processado)
2. Mensagem de erro registrada no log com: documento, campo invalido, valor encontrado, valor esperado, sugestao de correcao
3. Notificacao enviada ao responsavel
4. Documento aparece em relatorio de "documentos pendentes"

Quando um campo com **warning** falha:

1. Documento e aceito (processamento continua)
2. Warning registrado no log
3. Documento aparece em relatorio de "documentos com alertas"

### Valores validos para enums

- **doc_type**: `system-doc`, `adr`, `runbook`, `glossary`, `task-doc`, `architecture-doc`, `policy`, `meeting-notes`, `onboarding`, `postmortem`
- **status (.beta.md)**: `draft`, `in-review`, `approved`
- **status (.md final)**: `draft`, `in-review`, `approved`, `deprecated`
- **confidentiality**: `public`, `internal`, `restricted`, `confidential`
- **source_format**: `original`, `pdf`, `docx`, `xlsx`, `pptx`, `email`, `confluence`, `sharepoint`, `jira`, `clickup`, `transcription`, `web`, `json`, `csv`, `image`, `video`, `audio`, `manual`
- **qa_status**: `pending`, `passed`, `failed`, `skipped`
- **source type** (no array sources do .beta.md): `pdf`, `docx`, `xlsx`, `pptx`, `email`, `confluence`, `sharepoint`, `jira`, `clickup`, `transcription`, `web`, `manual`, `md`, `json`, `csv`, `image`, `video`, `audio`

## Conversion Quality (Parte D)

O campo `conversion_quality` expressa a confianca na fidelidade da conversao da fonte original para o formato `.md`. Score de 0 a 100% calculado pelo pipeline de conversao na Fase 2 ([[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]]).

### Formula de calculo

```
conversion_quality = min(
    media_ponderada(sinais_do_formato),
    penalidade_por_erro_critico
)
```

A funcao `min()` garante que um erro critico **sempre** reduz o score, mesmo que os outros sinais sejam bons.

### Sinais por formato de origem

| Formato | Sinais | Peso |
|---|---|---|
| MD nativo | 100% automatico (sem conversao) | - |
| PDF texto | % caracteres reconhecidos (40%), headings preservados (30%), tabelas (20%), links (10%) | - |
| PDF escaneado (OCR) | Confidence OCR (50%), resolucao DPI (20%), % texto reconhecido (20%), idioma (10%) | - |
| DOCX | Conversao deterministica (30%), estilos preservados (30%), tabelas (20%), imagens com alt (20%) | - |
| XLSX | Tabelas convertidas (40%), formulas identificadas (20%), merges resolvidos (20%), abas processadas (20%) | - |
| PPTX | Slides convertidos (30%), notas do apresentador (25%), imagens descritas (25%), ordem logica (20%) | - |
| Email | Headers completos (30%), corpo HTML->MD (30%), anexos (25%), thread preservada (15%) | - |
| Transcricao (audio/video) | WER do STT (40%), identificacao de falantes (25%), timestamps (15%), sobreposicao tratada (20%) | - |
| Confluence | Estrutura HTML preservada (30%), macros expandidas (25%), links internos (25%), anexos (20%) | - |
| Web | HTML->MD com estrutura (35%), navegacao removida (25%), imagens com alt (20%), links resolvidos (20%) | - |
| JSON / Ticket (Jira, ClickUp) | Campos extraidos (40%), historico preservado (25%), comentarios (20%), anexos (15%) | - |
| CSV | Headers identificados (30%), tipos inferidos (25%), encoding correto (25%), delimitador (20%) | - |
| Image | OCR confidence (50%), descricao por VLM (30%), resolucao suficiente (20%) | - |
| Manual | Score definido pelo humano (100%) | - |

### Thresholds de decisao

| Score | Acao |
|---|---|
| >= 80% | **Ingestao automatica**. `.beta.md` gerado e processado sem intervencao humana. Status: `draft`. |
| 30% a 79% | **Revisao humana obrigatoria**. `.beta.md` gerado com flag `requires_human_review`. Pipeline emite warning com sinais de score baixo. |
| < 30% | **Rejeicao**. `.beta.md` nao gerado. Fonte rejeitada. Log com detalhes. Humano deve providenciar fonte melhor ou conversao manual. |

Os thresholds sao configuraveis por organizacao (via config do pipeline).

## Compatibilidade com Obsidian (Parte E)

O Obsidian e o editor recomendado para edicao de `.beta.md` ([[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]], Fase 2). O front matter deve ser 100% compativel.

### YAML entre marcadores ---

O front matter **deve** estar entre marcadores `---` no inicio do arquivo. O Obsidian renderiza os campos no painel de propriedades (Properties view).

### Tags como array YAML

Tags devem ser arrays YAML, **nao** a sintaxe `#tag` no front matter:

- Correto: `tags: [conciliacao, cobranca, boleto]`
- Incorreto: `tags: #conciliacao #cobranca #boleto`

No corpo do documento (abaixo do `---`), tags `#tag` podem ser usadas normalmente.

### Aliases para busca e descoberta

O campo `aliases` e reconhecido nativamente pelo Obsidian. Permite encontrar o documento pelo quick switcher (Ctrl+O) usando qualquer alias.

### Wikilinks no corpo, nao no front matter

Wikilinks (`[[DOC-000042]]`) devem ser usados apenas no **corpo** do documento, nunca no front matter. O front matter e YAML puro e wikilinks podem quebrar parsers.

### Campos personalizados

O Obsidian aceita qualquer campo no front matter YAML. Campos como `qa_score`, `conversion_quality`, etc. sao exibidos no painel de propriedades sem configuracao adicional. Nao e necessario plugin especial.

### Templates no Obsidian

Recomendacao: criar templates no Obsidian (via plugin Templates ou Templater) com o front matter pre-preenchido:

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

## Alternativas Descartadas

### Front matter unico (mesmo schema para .beta.md e .md)

Rejeitada porque sobrecarrega o autor humano com campos que ele nao sabe preencher, aumenta taxa de erros e campos de governanca preenchidos pelo autor podem estar incorretos.

### Metadados em arquivo separado (sidecar)

Rejeitada porque duplica arquivos, risco de dessincronizacao, Obsidian nao reconhece sidecar e YAML embutido e o padrao da industria.

### Metadados apenas na Base Vetorial (sem front matter)

Rejeitada porque perde rastreabilidade, exige logica complexa de inferencia, impossibilita validacao pre-ingestao e viola principio "documento autoexplicativo" ([[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]], Pilar E).

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
| 1-MVP | Schema leve definido, validador basico, template Obsidian | [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] Fase 1 |
| 2 | Schema rico definido, validador completo, enums centralizados, relatorio de rejeitados, `conversion_quality` | [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] Fase 2 |
| 3 | Pipeline de promocao (leve -> rico), sugestao automatica de governanca, validacao de classificacao ([[ADR-004_seguranca_classificacao_dados|ADR-004]]), QA automatizado | [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] Fase 3 |
| 4 | Temporalidade completa, schema versionado com migracao, dashboard de cobertura, auditoria de classificacao | [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] Fase 4 |

## Referencias

### Internas

- [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] — Pipeline de Geracao de Conhecimento em 4 Fases (secoes 2.5, 2.5.1, 2.6)
- [[ADR-002_soberania_dados_cloud_vs_onprem|ADR-002]] — Soberania e Residencia de Dados
- [[ADR-003_modelo_dados_base_vetorial|ADR-003]] — Modelo de Dados da Base Vetorial
- [[ADR-004_seguranca_classificacao_dados|ADR-004]] — Estrategia de Seguranca e Classificacao de Dados
- [[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]] — Pipeline de Ingestao (consome front matter na Etapa 2)
- [[ADR-007_retrieval_hibrido_agentes|ADR-007]] — Retrieval Hibrido e Agentes
- [[ADR-009_selecao_modelos_embedding|ADR-009]] — Selecao de Modelos de Embedding
- [[ADR-010_git_flow_base_conhecimento|ADR-010]] — Git Flow da Base de Conhecimento
- [[ADR-011_segregacao_kbs_por_confidencialidade|ADR-011]] — Segregacao de KBs

### Externas

- [YAML Specification 1.2](https://yaml.org/spec/1.2.2/)
- [Obsidian Properties](https://help.obsidian.md/Editing+and+formatting/Properties)
- [Hugo Front Matter](https://gohugo.io/content-management/front-matter/)
- [Jekyll Front Matter](https://jekyllrb.com/docs/front-matter/)

---

<!-- QA-MD: inicio -->
## Quality Assurance — .md final

**Revisor:** Pipeline de Promoção QA
**Data:** 22/03/2026
**Fonte:** kb/rag-blueprint-adrs-kb/beta/ADR-005_front_matter_contrato_metadados.beta.md

| Critério | Peso | Nota | Comentário |
|----------|------|------|------------|
| Front matter rico | 25% | 96% | Todos os campos obrigatórios presentes. Corrigido: `status: accepted` alterado para `status: approved` (valor válido conforme schema). |
| Completude de conteúdo | 20% | 100% | Todas as seções ADR presentes (Contexto, Decisão, Alternativas Descartadas, Consequências, Implementação, Referências). Tabela de referência no topo. Referências cruzadas completas. |
| Wikilinks | 10% | 100% | Todos os wikilinks no formato [[ADR-NNN_slug\|ADR-NNN]]. Nenhum [[BETA-*]] como wikilink (referências a BETA dentro de code spans são conteúdo legítimo). Nenhum wikilink no front matter. |
| Sem artefatos workspace | 15% | 100% | Nenhum marcador LOCKED, nenhum QA-BETA, nenhum BETA-NNN no campo id. source_beta_ids contém BETA-005 corretamente para linhagem. |
| Compatibilidade Obsidian | 10% | 100% | YAML válido, tags e aliases como arrays YAML, front matter entre marcadores `---`. |
| Linhagem rastreável | 10% | 100% | source_path aponta para beta, source_beta_ids correto (BETA-005), conversion_pipeline: promotion-pipeline-v1, source_repo e source_format presentes. |
| Clareza e estrutura | 10% | 98% | Estrutura exemplar com Partes A-E bem organizadas, tabelas de validação, exemplos completos de front matter leve e rico. Conteúdo denso mas bem segmentado. |

**Score:** 98.9% — APROVADO para ingestão

**Por que não é 100%:** (1) Campo `status` continha valor `accepted` não previsto no schema — corrigido para `approved` (-4% no front matter rico). (2) Pequena margem de melhoria em clareza: seção de Schema de Validação (Parte C) poderia separar regras leve/rico em sub-headings mais distintos (-2% clareza).
<!-- QA-MD: fim -->
