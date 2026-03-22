---
id: BETA-001
title: "Pipeline de Geração de Conhecimento em 4 Fases com Modelo Beta.md e Dois Repositórios"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "kb/rag-blueprint-adrs-kb/1 - draft/ADR-001_pipeline_geracao_conhecimento_4_fases.txt"
    captured_at: "2026-03-21"
    conversion_quality: 95
tags: [pipeline, beta-md, knowledge-base, fases, repositorios, locked-blocks, ingestao]
aliases:
  - "ADR-001"
  - "Pipeline 4 Fases"
status: approved
last_enrichment: "2026-03-22"
last_human_edit: "2026-03-22"
---

## Contexto

O projeto RAG Corporativo precisa de um pipeline que transforme fontes diversas (PDFs, e-mails, Confluence, transcrições, planilhas, etc.) em uma base de conhecimento estruturada para alimentar uma Base Vetorial.

Um modelo anterior (Bronze/Prata/Ouro, inspirado em data lakehouse) definiu 3 camadas, mas não endereçava:

- **Edição humana** — como permitir que POs, analistas e especialistas enriqueçam o conteúdo gerado pela IA sem conflitos
- **Fonte da verdade** — qual artefato é a referência autoritativa para o RAG
- **Segregação de acesso** — como garantir que a fonte da verdade não seja alterada manualmente
- **Temporalidade do conhecimento** — como representar informações que mudam ao longo do tempo (leis, regulações, políticas)
- **Re-ingestão** — como lidar com atualizações de fontes sem perder edições humanas

### Pilares do Processo

O pipeline é guiado por 8 pilares:

| Pilar | Descrição |
|-------|-----------|
| A | Segregação de responsabilidades — Quem faz o quê em cada etapa |
| B | Desacoplamento de etapas — Fases independentes, falha em uma não impacta outra |
| C | Método garantidor de qualidade — Gates de qualidade entre fases |
| D | Observabilidade e Governança — Rastreio de execução, métricas, auditoria |
| E | Clareza da informação — Documentos autoexplicativos, sem ambiguidade |
| F | Versionamento — Controle de versão de arquivos (Git) |
| G | Rastreabilidade de origem — De onde veio cada pedaço de informação |
| H | Reprodutibilidade — Mesmo input = mesmo output (previsível) |

## Decisão

<!-- LOCKED:START autor=fabio data=2026-03-21 -->
Adotar pipeline de geração de conhecimento em **4 fases** com camada intermediária `.beta.md` (editável por humanos e IA) e separação física em **2 repositórios** (workspace editável + knowledge-base imutável). O `.md` final é a fonte da verdade, gerado exclusivamente por pipeline e nunca editado manualmente.

```
FASE 1              FASE 2                FASE 3              FASE 4
┌──────────┐    ┌───────────────┐    ┌──────────────┐    ┌──────────────┐
│ Fontes   │    │  .beta.md     │    │  .md final   │    │ Base Vetorial│
│ diversas │───→│  (editável)   │───→│  (imutável)  │───→│    Vector    │
│          │    │               │    │              │    │      DB      │
└──────────┘    └───────────────┘    └──────────────┘    └──────────────┘
  Seleção         Mineração +          Promoção            Ingestão na
  de insumos      Edição humana        via pipeline        Base Vetorial
```
<!-- LOCKED:END -->

### Fase 1 — Seleção dos insumos geradores de conhecimento

- Definir quais fontes são relevantes para o contexto de negócio
- Disponibilizar os arquivos para processamento
- Gerar manifesto de ingestão (origem, formato, data, responsável, confidencialidade)
- Fontes: externas (internet, documentações de fornecedores, leis), internas (Sharepoint, Confluence, Jira, e-mails, transcrições, PDFs, planilhas), repositórios de código, wikis, post-mortems
- **DOD:** arquivos preparados + manifesto de ingestão

### Fase 2 — Mineração, preparação e ajustes finos (.beta.md)

- Pipeline de IA gera/atualiza `.beta.md` a partir dos insumos
- Humanos editam via Obsidian (compatível, com front matter leve)
- Blocos `<!-- LOCKED -->` protegem edições humanas contra sobrescrita da IA
- Múltiplas rodadas de enriquecimento (IA + humano) até consolidação
- **DOD:** arquivos `.beta.md` consolidados e aprovados para promoção

### Fase 3 — Geração da origem consolidada — "Informação Verdade"

- Pipeline promove `.beta.md` → `.md` final com front matter rico
- O `.md` final **NUNCA** é editado manualmente — sempre gerado por pipeline
- Aprovação via PR no repositório knowledge-base (PO + Arquiteto)
- Release com tag para controlar o que entra na Base Vetorial
- Gate de qualidade: QA score >= 90% no `.beta.md`. Documentos com score 80-89% podem ser promovidos se os motivos estiverem documentados no front matter (campo `qa_notes`). Abaixo de 80% é bloqueante.
- **DOD:** arquivos `.md` gerados, aprovados e com release criada

### Fase 4 — Geração do RAG (Camada Ouro)

- Pipeline de ingestão constrói/atualiza banco vetorial
- Triggered por release tag no repo knowledge-base
- Versão da release é registrada no header dos dados na Base Vetorial
- **DOD:** banco vetorial criado/atualizado

## Dois Repositórios

| Repositório | Propósito | Quem edita | Acesso |
|---|---|---|---|
| `rag-workspace` | `.beta.md` em trabalho, fontes brutas, logs do processo | Humanos (Obsidian) + IA (pipeline) | Read-write para times de conhecimento |
| `rag-knowledge-base` | `.md` finais (fonte da verdade), apresentações, releases | Pipeline apenas (service account) | Read-only para times, write apenas via pipeline + PR |

Wikilinks são segregados: `.beta.md` só navega para `.beta.md`, `.md` só navega para `.md`.

### Estrutura de Pastas

**rag-workspace:**

```
rag-workspace/
├── sources/                          # FASE 1 — Insumos brutos
│   ├── manifesto.json
│   ├── external/
│   │   ├── regulations/
│   │   ├── vendor-docs/
│   │   └── web/
│   └── internal/
│       ├── sharepoint/
│       ├── confluence/
│       ├── emails/
│       ├── transcriptions/
│       ├── documents/
│       └── tickets/
├── beta/                             # FASE 2 — .beta.md editáveis
│   ├── {dominio}/
│   │   └── {documento}.beta.md
│   └── glossary/
├── process/                          # Logs e métricas do processo
│   ├── logs/
│   ├── metrics/
│   └── reports/
└── .pipeline/                        # Configuração do pipeline
    ├── templates/
    ├── schemas/
    └── config.json
```

**rag-knowledge-base:**

```
rag-knowledge-base/
├── docs/                             # FASE 3 — .md finais
│   ├── {dominio}/
│   │   └── {documento}.md
│   ├── glossary/
│   └── ADRs/
├── presentations/                    # .html gerados do .md
└── releases/                         # FASE 4 — Snapshots para Base Vetorial
    └── v{N.N}/
        ├── release-notes.md
        └── manifest.json
```

## Proteção de Edições Humanas (Blocos LOCKED)

Humanos podem marcar trechos no `.beta.md` como protegidos:

```
<!-- LOCKED:START autor=fabio data=2026-03-21 -->
Este trecho foi validado e não deve ser alterado pela IA.
<!-- LOCKED:END -->
```

**Regras:**

- IA pode adicionar conteúdo novo fora dos blocos locked
- IA **NUNCA** altera conteúdo dentro de `LOCKED:START`/`END`
- IA pode sugerir mudanças em blocos locked como comentário separado
- Humano pode remover o lock a qualquer momento

## Front Matter Leve do .beta.md

```yaml
---
id: BETA-{NNN}
title: "{título descritivo}"
domain: "{domínio de negócio}"
confidentiality: public | internal | restricted | confidential
sources:
  - type: "{pdf|email|confluence|manual|transcription|...}"
    origin: "{caminho ou referência da fonte}"
    captured_at: "{AAAA-MM-DD}"
tags: [termo1, termo2, ...]
status: draft | in-review | approved
last_enrichment: "{AAAA-MM-DD}"
last_human_edit: "{AAAA-MM-DD}"
---
```

Campos de governança (`system`, `module`, `owner`, `team`, QA) entram apenas na promoção para `.md` final (Fase 3).

**Exceção:** `confidentiality` é incluído no front matter leve do `.beta.md`. É necessário desde a Fase 2 para rotear pela trilha correta ([[BETA-002]]) e garantir que dados sensíveis não sejam processados por APIs cloud.

### Conversão de Fontes e conversion_quality

Cada fonte convertida para `.beta.md` recebe um score `conversion_quality` (0-100%) que expressa confiança na fidelidade da extração. Este score é registrado no campo `sources` do front matter.

| Formato | Sinais para cálculo |
|---------|---------------------|
| MD nativo | 100% (sem conversão, apenas validação) |
| PDF texto | % caracteres reconhecidos, estrutura preservada |
| PDF escaneado (OCR) | confidence do OCR, resolução da imagem |
| DOCX | ~100% (conversão determinística) |
| XLSX | complexidade de fórmulas/merges, % tabelas convertidas |
| E-mail | completude de headers, anexos processados |
| Transcrição | word error rate do STT, sobreposição de falantes |
| JSON/Ticket | completude dos campos extraídos |
| Web/Confluence | estrutura HTML preservada, links resolvidos |

**Fórmula:** média ponderada dos sinais aplicáveis ao formato. Score final = min(média_dos_sinais, penalidade_por_erro_crítico).

**Uso do score:**

- >= 80% → ingestão automática no `.beta.md`
- 30-79% → `.beta.md` gerado com `status: draft`, revisão humana obrigatória
- < 30% → fonte rejeitada, log de erro gerado

## Temporalidade do Conhecimento

Modelo em 3 camadas para versionamento semântico:

**Camada 1 — No .md (front matter):**

```yaml
valid_from: "2026-01-01"
valid_until: null               # null = vigente
superseded_by: "DOC-000456"     # ID do doc que substitui
supersedes: "DOC-000123"        # ID do doc anterior
```

**Camada 2 — Na Base Vetorial (relações temporais):**

- Relação `(:Document)-[:SUPERSEDES {effective_date}]->(:Document)`
- Relação `(:Document)-[:VERSION_OF]->(:DocumentFamily)`
- Nó `:DocumentFamily` com `family_id`, `title`, `current_version`

**Camada 3 — No retrieval (filtro temporal):**

- Detectar contexto temporal na pergunta
- Filtrar por `valid_from`/`valid_until` antes da busca vetorial
- Assumir data atual se não houver contexto temporal explícito
- Agentes instruídos a citar vigência e versões anteriores nas respostas

## Re-ingestão com Merge

Quando uma fonte é atualizada (ex: PDF v2):

1. **Diff de fontes** — comparar v1 com v2, gerar lista de mudanças
2. **Análise de impacto** — classificar cada trecho do `.beta.md`:
   - Sem conflito (não editado por humano) → atualizar automaticamente
   - Possível conflito (editado por humano E fonte mudou) → inserir alerta `<!-- CONFLICT -->` inline
   - Conflito em bloco locked → não alterar, registrar alerta `<!-- LOCKED-CONFLICT -->`
3. **Relatório** — quantos trechos atualizados, conflitos para revisão, locks desatualizados

## Alternativas Consideradas

### Modelo Bronze/Prata/Ouro (3 camadas)

- **Descrição:** 3 camadas inspiradas em data lakehouse: Bronze (fontes originais) → Prata (.md normalizado) → Ouro (Base Vetorial). Pipeline linear sem edição humana intermediária.
- **Prós:** rastreabilidade completa, original preservado, pipeline simples
- **Contras:** não prevê edição humana; não suporta `.beta.md`; sem temporalidade; sem re-ingestão com merge
- **Motivo da absorção:** os conceitos úteis (conversion_quality, linhagem, formatos suportados) foram incorporados nesta ADR. A separação em 4 fases com `.beta.md` resolve as lacunas do modelo de 3 camadas.

### Pipeline direto sem camada beta

- **Descrição:** fontes → `.txt` (draft) → `.md` (verdade) — sem edição humana intermediária
- **Prós:** simples, menos artefatos, pipeline linear
- **Contras:** não permite edição humana antes da promoção; qualquer correção exige reprocessamento completo
- **Motivo da rejeição:** insuficiente para cenário corporativo com múltiplas fontes e necessidade de curadoria humana

### Repositório único com branch protection

- **Descrição:** um repo só, `.beta.md` no branch develop, `.md` no branch main protegido
- **Prós:** um repo para manter, Git nativo resolve permissões, PR como gate
- **Contras:** branches podem confundir equipes não-técnicas; risco de merge acidental; sem separação física de acesso
- **Motivo da rejeição:** para ambiente regulado (BACEN, LGPD), separação física de repositórios é mais segura e auditável

### Arquivos separados por autor (.ai.beta.md + .human.beta.md)

- **Descrição:** dois arquivos por documento — um gerado pela IA, outro editado pelo humano, merge automático
- **Prós:** separação total, zero conflito de edição
- **Contras:** triplicação de arquivos, merge não-trivial, não escala
- **Motivo da rejeição:** over-engineering; blocos LOCKED resolvem o conflito de forma mais simples e granular

## Consequências

### Positivas

- Edição humana e enriquecimento por IA coexistem sem conflito
- Fonte da verdade (`.md`) é imutável e auditável
- Separação física de repos garante compliance regulatório
- Temporalidade permite consultas históricas ("como era antes?")
- Re-ingestão não destrói trabalho humano
- Pipeline é reprodutível (pilar H)
- Rastreabilidade completa de cada informação (pilar G)

### Negativas / Trade-offs

- Complexidade aumenta: 2 repos, 2 tipos de front matter, blocos LOCKED
- Curva de aprendizado: equipes precisam entender o fluxo beta → md
- Pipeline de promoção (Fase 3) é mais complexo que conversão direta
- Wikilinks segregados impede navegação cross-repo no Obsidian

### Riscos

- **Blocos LOCKED esquecidos** — humano edita sem marcar LOCKED, IA sobrescreve na re-ingestão. *Mitigação:* safety net via git diff (edição humana detectada sempre prevalece)
- **Acúmulo de conflitos** — muitos alertas `<!-- CONFLICT -->` não revisados. *Mitigação:* relatório de re-ingestão com contagem de conflitos pendentes
- **Dessincronia entre repos** — `.beta.md` evolui mas promoção para `.md` atrasa. *Mitigação:* cadência de promoção sob demanda, controlada por tags/releases no Git do workspace. A promoção acontece quando o Curador decide que os `.beta.md` estão prontos e cria uma tag de release no workspace.
- **Temporalidade incorreta** — `valid_from`/`valid_until` preenchidos errado. *Mitigação:* validação de schema no pipeline de promoção
- **Complexidade do merge** — re-ingestão com diff pode gerar falsos positivos. *Mitigação:* humano sempre tem a palavra final

## Implementação

### Faseamento

| Fase | Entrega | Dependência |
|------|---------|-------------|
| 1 — Estrutura | Criar os 2 repos, estrutura de pastas, templates, schemas | Nenhuma |
| 2 — Pipeline beta | Implementar captura de fontes → geração de `.beta.md` | Fase 1 |
| 3 — Edição humana | Configurar Obsidian + plugin Git no workspace, treinar equipe em blocos LOCKED | Fase 2 |
| 4 — Pipeline promoção | Implementar `.beta.md` → `.md` com front matter rico, PR automático | Fase 3 |
| 5 — Temporalidade | Adicionar `valid_from`/`valid_until`, DocumentFamily na Base Vetorial | Fase 4 |
| 6 — Re-ingestão | Implementar diff + merge + alertas de conflito | Fase 4 |

### Responsáveis

- **Arquiteto:** definição do pipeline, schemas, templates
- **Engenharia de dados:** implementação dos pipelines (Fases 2, 4, 6)
- **POs / Analistas:** edição dos `.beta.md`, aprovação de PRs (Fase 3)
- **Ops:** configuração dos repos, CI/CD, permissões

## Referências

- B00 — Introdução — visão geral da série de blueprints
- B02 — Camada Prata — pipeline de conversão substituído pelo modelo de 4 fases
- B03 — Camada Ouro — pipeline de ingestão na Base Vetorial (Fase 4)
- B05 — Knowledge Graph — modelo de dados com DocumentFamily
- B14 — Segurança — requisitos de compliance que motivam 2 repos
- B15 — Governança — papéis e RACI que se aplicam ao novo pipeline

## Documentos Relacionados

**Impacta diretamente:**

- B02 — Camada Prata — pipeline de conversão precisa ser atualizado
- B03 — Camada Ouro — pipeline de ingestão precisa suportar temporalidade e DocumentFamily
- B04 — Metadados e Governança — front matter do `.md` final precisa incluir campos temporais

**Relacionados:**

- B01 — Camada Bronze — a Fase 1 (seleção de insumos) substitui o conceito de bronze
- B05 — Knowledge Graph — modelo de grafo precisa de nó DocumentFamily + relação SUPERSEDES
- B07 — Visão Consolidada — tabela consolidada precisa refletir o novo pipeline
- B08 — Pendências — várias pendências são endereçadas por esta decisão
- B14 — Segurança e Soberania de Dados — segregação de repos é motivada por compliance
- B16 — Roadmap de Implementação — roadmap precisa incorporar as 4 fases
- [[BETA-002]] — Soberania de Dados: Trilha Cloud vs. On-Premise (depende do campo `confidentiality` definido aqui)

---

<!-- QA-BETA: inicio -->
## Quality Assurance — .beta.md

| Critério | Peso | Nota | Comentário |
|----------|------|------|------------|
| Front matter leve | 25% | 100% | id BETA-001 valido, title descritivo (81 chars), domain lowercase, confidentiality enum valido, sources com type/origin/captured_at + conversion_quality, 7 tags, status approved, aliases array, datas ISO validas. Nenhum campo de governanca presente. |
| Completude de conteudo | 25% | 95% | Todas as secoes do .txt preservadas: Contexto, Pilares, Decisao (4 fases), Dois Repositorios, Estrutura de Pastas, Blocos LOCKED, Front Matter Leve, conversion_quality, Temporalidade, Re-ingestao, Alternativas (4), Consequencias (positivas/negativas/riscos), Implementacao, Referencias. Conteudo fiel ao draft original. |
| Blocos LOCKED | 15% | 100% | Bloco LOCKED presente (linhas 49-62) protegendo a decisao central (pipeline 4 fases + diagrama). Corretamente aberto e fechado. Autor e data presentes. |
| Wikilinks | 10% | 100% | Usa formato [[BETA-002]] corretamente. Sem wikilinks no front matter. |
| Compatibilidade Obsidian | 10% | 100% | YAML entre --- valido, tags como array YAML, aliases como array YAML. |
| Clareza e estrutura | 15% | 95% | Hierarquia de headings clara (##, ###), tabelas bem formatadas, code blocks com diagramas ASCII, leitura fluida sem contexto previo. Secoes de Documentos Relacionados bem organizadas. |

**Score:** 97.5% — APROVADO para promocao

**Por que nao e 100%:** O .txt original possui detalhamento adicional em subsecoes (ex: 2.5.1 conversion_quality com mais exemplos de formatos, secao de Documentos que Impactam com mais contexto). A versao beta condensou esses detalhes sem perda de decisoes, mas ha leve reducao de granularidade em comparacao ao draft completo.
<!-- QA-BETA: fim -->
