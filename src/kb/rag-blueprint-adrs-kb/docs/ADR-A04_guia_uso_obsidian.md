---
id: ADR-A04
doc_type: adr
title: "Guia de Uso do Obsidian para Edição da KB"
system: RAG Corporativo
module: Obsidian
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - obsidian
  - editor markdown
  - beta md
  - front matter yaml
  - wikilinks
  - tags yaml
  - aliases
  - locked blocks
  - vault
  - properties view
  - templates
  - templater
  - obsidian git
  - dataview
  - plugins
  - source mode
  - live preview
  - pipeline validacao
  - rag workspace
  - fase 2
  - campos obrigatorios
  - campos opcionais
  - campos governanca
  - confidencialidade
  - cross kb
  - hashtag
  - quick switcher
  - front matter leve
  - carga cognitiva
  - last enrichment
  - last human edit
  - conversion quality
  - qa score
  - status draft
  - status in review
  - status approved
  - yaml spec
  - domain
  - sources array
  - retrocompatibilidade
  - markdown puro
  - vs code
  - typora
  - commit automatico
  - diff
  - pull push
  - tabelas dinamicas
  - curador
  - contribuidor
  - segregacao wikilinks
aliases:
  - "ADR-A04"
  - "Guia Obsidian KB"
  - "Guia de Edição Obsidian"
  - "Obsidian para RAG Corporativo"
  - "Editor Markdown KB"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-A04_guia_uso_obsidian.beta.md"
source_beta_ids:
  - "BETA-A04"
conversion_pipeline: promotion-pipeline-v2
conversion_quality: 96
converted_at: 2026-03-23
qa_score: null
qa_date: null
qa_status: pending
created_at: 2026-03-23
updated_at: 2026-03-23
valid_from: 2026-03-23
valid_until: null
---

# ADR-A04 — Guia de Uso do Obsidian para Edição da KB

## 1. Visão Geral

O Obsidian é o editor recomendado para edição de arquivos `.beta.md` no repositório rag-workspace (Fase 2 do pipeline, conforme [[ADR-001]]). Este guia cobre a configuração necessária, compatibilidade com front matter YAML, uso de tags, aliases, wikilinks e plugins recomendados.

O Obsidian foi escolhido porque:

- Renderiza front matter YAML no painel de propriedades (Properties view)
- Suporta wikilinks nativamente (`[[BETA-001]]`)
- Aceita qualquer campo personalizado no front matter sem configuração extra
- Funciona como editor local (offline), sem dependência de servidor
- Possui ecossistema de plugins para produtividade

## 2. Configuração Inicial

### 2.1 Abrir o Vault

O vault do Obsidian deve apontar para a pasta raiz do repositório rag-workspace (ou para a subpasta `beta/` se preferir escopo reduzido).

**Caminho recomendado:** abrir o rag-workspace inteiro como vault para ter acesso a todas as pastas (`sources/`, `beta/`, `process/`).

### 2.2 Configurações Recomendadas

**No menu Settings > Editor:**

- **Default editing mode:** Source mode (para visualizar o YAML diretamente) ou Live Preview (para editar com renderização parcial)
- **Strict line breaks:** Desativado (permite quebras naturais de parágrafo)

**No menu Settings > Files & Links:**

- **Default location for new notes:** In the folder specified below -> Especificar `beta/{subpasta-padrao}`
- **New link format:** Wikilink (padrão do Obsidian)
- **Use [[Wikilinks]]:** Ativado

## 3. Front Matter YAML

### 3.1 Estrutura Básica

Todo `.beta.md` deve começar com front matter YAML entre marcadores `---`:

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
tags: [conciliacao, cobranca, bancaria, boleto, retorno, cnab]
aliases: ["Conciliacao Bancaria", "Retorno CNAB"]
status: in-review
last_enrichment: "2026-03-18"
last_human_edit: "2026-03-20"
---
```

O Obsidian renderiza esses campos no painel de propriedades (Properties view), acessível pelo ícone no topo do editor.

### 3.2 Campos Obrigatórios

| Campo | Formato | Exemplo |
|---|---|---|
| id | `BETA-{NNN}` | BETA-042 |
| title | string, 10-200 chars | "Conciliação bancária" |
| domain | string, lowercase, sem espaços | financeiro |
| confidentiality | enum | internal |
| sources | array de objetos | (ver exemplo acima) |
| status | enum | draft / in-review / approved |

### 3.3 Campos Opcionais

| Campo | Formato | Propósito |
|---|---|---|
| tags | array de strings | Busca por facetas |
| aliases | array de strings | Nomes alternativos |
| last_enrichment | data AAAA-MM-DD | Última vez que IA enriqueceu |
| last_human_edit | data AAAA-MM-DD | Última edição humana |

### 3.4 Campos que NÃO Devem Existir no .beta.md

Os seguintes campos são de governança e só entram na promoção para `.md` (Fase 3):

- `system`, `module`, `owner`, `team`
- `valid_from`, `valid_until`, `supersedes`, `superseded_by`
- `qa_score`, `qa_date`, `qa_status`
- `doc_type`

**Filosofia:** o front matter leve contém o mínimo necessário para que o pipeline funcione. Tudo que pode ser inferido ou enriquecido depois fica fora, reduzindo a carga cognitiva do autor humano.

## 4. Tags

### 4.1 No Front Matter (Array YAML)

Tags no front matter devem ser arrays YAML:

```yaml
# CORRETO
tags: [conciliacao, cobranca, boleto]

# ERRADO
tags: #conciliacao #cobranca #boleto
```

O Obsidian reconhece ambas as formas, mas o pipeline de validação exige array YAML para parsing consistente.

**Regras:**

- Todas as tags em lowercase
- Sem espaços (usar hífen se necessário)
- Mínimo 3 tags recomendado (bloqueante na promoção para `.md`)
- Máximo não definido, mas 5-10 é o range ideal

### 4.2 No Corpo do Documento (Hashtag)

No corpo do documento (abaixo do `---`), tags com `#` podem ser usadas normalmente:

```
Este processo envolve #conciliacao e #retorno-cnab.
```

O Obsidian indexa ambas as formas (front matter + corpo).

## 5. Aliases

O campo `aliases` é reconhecido nativamente pelo Obsidian. Permite encontrar o documento pelo Quick Switcher (`Ctrl+O`) usando qualquer alias.

```yaml
aliases: ["Conciliacao Bancaria", "Retorno CNAB"]
```

**Regras:**

- Array de strings
- Sem duplicatas
- Cada alias de 3 a 100 caracteres
- Usar nomes alternativos reais (siglas, nomes informais, nomes em inglês)

## 6. Wikilinks

### 6.1 Uso Correto

Wikilinks são usados no **corpo** do documento para referenciar outros `.beta.md`:

```
Conforme definido na [[BETA-001]], o pipeline possui 4 fases.
```

O Obsidian cria links navegáveis automaticamente.

### 6.2 Regras

- Usar formato `[[BETA-NNN]]` para `.beta.md`
- **NUNCA** colocar wikilinks no front matter (YAML puro, wikilinks quebram parsers)
- `.beta.md` só navega para `.beta.md` (segregação de wikilinks)
- Wikilinks cross-KB são **PROIBIDOS** (ex: documento public não linka para restricted)

### 6.3 Formato

```
[[BETA-001]]                    -> link simples
[[BETA-001|Pipeline 4 Fases]]  -> link com texto de exibição
```

## 7. Blocos LOCKED

Humanos podem marcar trechos como protegidos contra sobrescrita pela IA:

```html
<!-- LOCKED:START autor=fabio data=2026-03-21 -->
Este trecho foi validado e não deve ser alterado pela IA.
<!-- LOCKED:END -->
```

**Regras:**

- IA pode adicionar conteúdo novo **FORA** dos blocos locked
- IA **NUNCA** altera conteúdo **DENTRO** de `LOCKED:START/END`
- IA pode sugerir mudanças em blocos locked como comentário separado
- Humano pode remover o lock a qualquer momento
- Ao editar no Obsidian, respeitar os marcadores HTML (não apagar)

## 8. Plugins Recomendados

### 8.1 Templates (Core Plugin)

Plugin nativo do Obsidian. Criar template com front matter pré-preenchido:

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

**Configurar:** Settings > Core Plugins > Templates > Template folder location

### 8.2 Templater (Community Plugin)

Alternativa mais avançada ao Templates nativo. Permite:

- Inserção automática de data no campo `last_human_edit`
- Geração automática de id sequencial (`BETA-NNN`)
- Preenchimento de `domain` baseado na pasta

### 8.3 Git (Community Plugin)

Plugin `obsidian-git` para integrar Git diretamente no Obsidian:

- Commit automático em intervalos configurados
- Pull/push sem sair do editor
- Visualização de diff no painel lateral

Recomendado para contribuidores que não usam terminal.

### 8.4 Dataview (Community Plugin)

Permite criar tabelas e listas dinâmicas baseadas no front matter:

````
```dataview
TABLE title, status, domain
FROM "beta"
WHERE status = "draft"
SORT last_human_edit DESC
```
````

Útil para o Curador monitorar estado dos documentos.

## 9. Campos Personalizados

O Obsidian aceita qualquer campo no front matter YAML. Campos como `qa_score`, `conversion_quality`, etc. são exibidos no painel de propriedades sem configuração adicional. Não é necessário plugin especial.

Campos adicionados pelo pipeline (ex: `last_enrichment`, `conversion_quality`) aparecem automaticamente no Properties view na próxima vez que o arquivo for aberto.

## 10. Compatibilidade e Limitações

- O Obsidian **não é obrigatório** — qualquer editor que preserve YAML front matter entre marcadores `---` funciona (VS Code, Typora, etc.)
- Se o Obsidian for descontinuado, a migração é trivial: os arquivos são Markdown puro com YAML, sem formato proprietário
- O Obsidian não edita o `.md` final (knowledge-base) — apenas o `.beta.md` (workspace)
- Wikilinks do Obsidian (`[[BETA-NNN]]`) são válidos em Markdown e renderizam em qualquer viewer que suporte a sintaxe

## 11. Referências

- [[ADR-005]] — Front Matter como Contrato de Metadados (Parte E: Compatibilidade com Obsidian, templates, tags, aliases, wikilinks)
- [[ADR-001]] — Pipeline de Geração de Conhecimento em 4 Fases (define Fase 2 onde `.beta.md` são editados via Obsidian)
- [Obsidian Properties](https://help.obsidian.md/Editing+and+formatting/Properties)
- [YAML Specification 1.2](https://yaml.org/spec/1.2.2/)

<!-- conversion_quality: 96 -->
