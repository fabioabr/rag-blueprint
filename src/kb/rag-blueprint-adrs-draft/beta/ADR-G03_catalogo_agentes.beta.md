---
id: BETA-G03
title: "Catalogo de Agentes Especializados"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-G03_catalogo_agentes.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags:
  - agentes especializados
  - architecture agent
  - operations agent
  - business agent
  - dispatcher
  - roteador de intencao
  - classificacao de intencao
  - system prompt
  - filtro de documento
  - doc type
  - relacoes priorizadas
  - graph search
  - few shot
  - confidence threshold
  - fallback
  - ambiguous
  - retrieval hibrido
  - rrf
  - reranking
  - neo4j
  - grafo de conhecimento
  - depends on
  - belongs to
  - decides
  - references
  - supersedes
  - implements
  - relates to task
  - owned by
  - member of
  - uses term
  - adr
  - runbook
  - glossario
  - system doc
  - architecture doc
  - task doc
  - dominio
  - confidencialidade
  - compliance agent
  - onboarding agent
  - incident agent
  - evolucao futura
  - cache
  - latencia
  - acuracia
  - publico alvo
  - tom de resposta
  - citacao de origem
aliases:
  - "ADR-G03"
  - "Catalogo de Agentes"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## ADR-G03 -- Catalogo de Agentes Especializados

**Tipo:** ADR
**Origem:** ADR-007
**Data:** 23/03/2026

## Objetivo

Catalogar os agentes especializados do RAG Corporativo, incluindo suas configuracoes de filtro, system prompts, relacoes priorizadas no grafo e a logica do Dispatcher (roteador de intencao). Cada agente e otimizado para um dominio especifico de perguntas.

## 1. Architecture Agent

### 1.1 Proposito

Responder perguntas sobre decisoes arquiteturais, trade-offs tecnicos, dependencias entre sistemas e modulos, e evolucao tecnica. Publico-alvo: desenvolvedores, tech leads e arquitetos.

### 1.2 Filtros de Documento

```
doc_type IN ["architecture-doc", "adr", "system-doc"]
```

Estes filtros sao aplicados como restricao adicional ao filtro de seguranca (que sempre roda primeiro). O agente so ve documentos que o usuario tem permissao E que sao dos tipos acima.

### 1.3 Relacoes Priorizadas no Grafo

Ao executar Graph Search, o Architecture Agent prioriza:

| Relacao | Direcao | Uso |
|---|---|---|
| DEPENDS_ON | (:Module)-[:DEPENDS_ON]->(:Module) | Mapear dependencias tecnicas |
| BELONGS_TO | (:Document)-[:BELONGS_TO]->(:Module) | Contexto de modulo/sistema |
| DECIDES | (:ADR)-[:DECIDES]->(:System) | Decisoes sobre sistemas |
| REFERENCES | (:Document)-[:REFERENCES]->(:Document) | Cadeia de referencias |
| SUPERSEDES | (:Document)-[:SUPERSEDES]->(:Document) | Versionamento de ADRs |

### 1.4 System Prompt

> Voce e um arquiteto de software senior especializado na base de conhecimento corporativa. Suas respostas devem ter:
> - Profundidade tecnica adequada ao publico (desenvolvedores e arquitetos)
> - Citacao explicita de ADRs relevantes (ex: "Conforme ADR-003...")
> - Analise de trade-offs quando existirem alternativas
> - Indicacao de dependencias e impactos em outros modulos
> - Referencia a versoes anteriores quando o documento foi superado
> - Linguagem tecnica precisa em portugues brasileiro
>
> Regras:
> - Nunca invente informacao alem do contexto fornecido
> - Cite a origem de cada afirmacao (documento, sistema, modulo)
> - Se a informacao e incompleta, declare explicitamente
> - Alerte sobre documentos deprecated ou proximos de expiracao

### 1.5 Exemplos de Queries

- "Qual ADR decidiu sobre o banco de dados do sistema de cobranca?"
- "Quais modulos dependem do modulo de autenticacao?"
- "Quais foram os trade-offs considerados na escolha do Neo4j?"
- "Existe alguma ADR sobre estrategia de cache?"
- "Como evoluiu a arquitetura do modulo financeiro?"

## 2. Operations Agent

### 2.1 Proposito

Responder perguntas operacionais: como executar procedimentos, resolver incidentes, comandos exatos, passos de deploy e configuracao. Publico-alvo: engenheiros de operacoes, SREs e desenvolvedores em contexto de incidente.

### 2.2 Filtros de Documento

```
doc_type IN ["runbook", "glossary", "task-doc", "system-doc"]
```

### 2.3 Relacoes Priorizadas no Grafo

| Relacao | Direcao | Uso |
|---|---|---|
| BELONGS_TO | (:Document)-[:BELONGS_TO]->(:Module) | Contexto de modulo |
| IMPLEMENTS | (:Task)-[:IMPLEMENTS]->(:Module) | Tarefas relacionadas |
| RELATES_TO_TASK | (:Document)-[:RELATES_TO_TASK]->(:Task) | Documentacao de tasks |

### 2.4 System Prompt

> Voce e um engenheiro de operacoes senior. Suas respostas devem:
> - Fornecer passos NUMERADOS, claros e executaveis
> - Incluir comandos EXATOS quando disponveis (copiar e colar)
> - Destacar avisos de SEGURANCA (ex: "ATENCAO: este comando apaga dados")
> - Indicar pre-requisitos antes de cada procedimento
> - Mencionar rollback quando aplicavel
> - Usar linguagem direta e sem ambiguidade
>
> Regras:
> - Nunca sugira comandos que voce nao encontrou na documentacao
> - Se o runbook esta incompleto, alerte explicitamente
> - Indique a versao do documento consultado
> - Para procedimentos criticos, mencione quem deve aprovar

### 2.5 Exemplos de Queries

- "Como fazer deploy do modulo de cobranca em producao?"
- "Qual e o procedimento de rollback do sistema de pagamentos?"
- "Como reiniciar o servico de notificacoes?"
- "Quais tasks estao relacionadas ao modulo de boletos?"
- "O que significa o termo 'liquidacao' no glossario?"

## 3. Business Agent

### 3.1 Proposito

Responder perguntas de negocio: responsabilidades, regras vigentes, termos do glossario, estrutura organizacional. Publico-alvo: gestores, analistas de negocio e executivos.

### 3.2 Filtros de Documento

```
domain filtrado conforme query (ex: se a query menciona "financeiro",
filtrar domain = "Financeiro")
```

Diferente dos outros agentes, o Business Agent filtra por DOMINIO em vez de doc_type, pois perguntas de negocio podem atravessar qualquer tipo de documento.

### 3.3 Relacoes Priorizadas no Grafo

| Relacao | Direcao | Uso |
|---|---|---|
| OWNED_BY | (:Document)-[:OWNED_BY]->(:Owner) | Responsaveis |
| MEMBER_OF | (:Owner)-[:MEMBER_OF]->(:Team) | Estrutura de times |
| USES_TERM | (:Document)-[:USES_TERM]->(:GlossaryTerm) | Termos de negocio |
| BELONGS_TO | (:Module)-[:BELONGS_TO]->(:System) | Contexto organizacional |

### 3.4 System Prompt

> Voce e um analista de negocios senior. Suas respostas devem:
> - Usar linguagem ACESSIVEL (evitar jargao tecnico desnecessario)
> - Citar regras com periodo de VIGENCIA (de quando ate quando)
> - Indicar RESPONSAVEIS (owner e time)
> - Contextualizar termos de negocio usando o glossario corporativo
> - Resumir quando o publico for executivo (visao macro)
> - Detalhar quando o publico for analista (visao operacional)
>
> Regras:
> - Nunca invente regras de negocio
> - Cite a fonte de cada afirmacao
> - Se ha conflito entre documentos, apresente ambas as versoes com datas
> - Alerte sobre regras expiradas ou em revisao

### 3.5 Exemplos de Queries

- "Quem e o responsavel pelo processo de cobranca?"
- "Qual time cuida do sistema de pagamentos?"
- "O que significa 'remessa bancaria'?"
- "Quais sao as regras vigentes de cancelamento de boleto?"
- "Qual e a estrutura organizacional da area financeira?"

## 4. Dispatcher (Roteador de Intencao)

### 4.1 Mecanismo

O Dispatcher e o componente que classifica a intencao da query e direciona para o agente especializado correto. Usa um LLM com few-shot examples para classificacao.

### 4.2 Classificacao

Entrada: query do usuario (texto livre)
Saida: uma das categorias: "architecture", "operations", "business", "ambiguous"

| Intencao | Criterios | Agente |
|---|---|---|
| architecture | Menciona ADR, decisao, trade-off, dependencia tecnica, arquitetura, escolha de tecnologia | Architecture Agent |
| operations | Menciona deploy, procedimento, comando, restart, rollback, incidente, runbook, passo-a-passo | Operations Agent |
| business | Menciona responsavel, dono, time, regra de negocio, glossario, organizacao, dominio | Business Agent |
| ambiguous | Nao se encaixa claramente em nenhuma categoria OU confianca < 0.7 | Todos (fallback) |

### 4.3 Few-Shot Examples para o Dispatcher

**Exemplo 1:**
- Query: "Qual ADR decidiu sobre o banco de dados?"
- Classificacao: architecture
- Justificativa: menciona ADR e decisao tecnica

**Exemplo 2:**
- Query: "Como fazer deploy do modulo de cobranca?"
- Classificacao: operations
- Justificativa: menciona deploy e procedimento operacional

**Exemplo 3:**
- Query: "Quem e o responsavel pelo sistema de pagamentos?"
- Classificacao: business
- Justificativa: pergunta sobre responsavel/owner

**Exemplo 4:**
- Query: "Me fale sobre o sistema SAP"
- Classificacao: ambiguous
- Justificativa: pergunta generica sem direcao clara

**Exemplo 5:**
- Query: "Quais dependencias o modulo de cobranca tem e quem cuida dele?"
- Classificacao: ambiguous
- Justificativa: mistura arquitetura (dependencias) com negocio (responsavel)

### 4.4 Configuracao do Dispatcher

| Parametro | Valor |
|---|---|
| Modelo | LLM leve (GPT-4o-mini ou Llama 3.1 8B local) |
| Latencia alvo | < 100ms |
| Cache | 5 minutos para queries identicas |
| Confidence | Se confianca < 0.7, classificar como "ambiguous" |
| Few-shot | Minimo 5 exemplos por categoria |

### 4.5 Fallback (Ambiguous)

Quando a classificacao e "ambiguous":
1. Acionar TODOS os 3 agentes em paralelo
2. Cada agente executa seu pipeline completo (filtros + buscas + reranking)
3. Resultados dos 3 agentes sao fundidos via RRF adicional
4. Top-K final e montado a partir da fusao

Trade-off: latencia ~3x maior, mas evita perda de informacao por classificacao incorreta.

### 4.6 Metricas do Dispatcher

| Metrica | Alvo |
|---|---|
| Acuracia de classificacao | > 85% |
| % queries ambiguous (fallback) | < 20% |
| Latencia media | < 100ms |
| Cache hit rate | > 30% |

## 5. Tabela Consolidada dos Agentes

| Aspecto | Architecture | Operations | Business |
|---|---|---|---|
| Publico | Devs, Arquitetos | SREs, Ops | Gestores, Analistas |
| Filtro doc_type | arch-doc, adr, sys | runbook, glossary, task-doc, sys-doc | (por dominio) |
| Relacoes prio | DEPENDS_ON, DECIDES, REFERENCES | BELONGS_TO, IMPLEMENTS, RELATES_TO_TASK | OWNED_BY, MEMBER_OF, USES_TERM |
| Tom | Tecnico | Direto/executavel | Acessivel |
| Formato | Analise + refs | Passos numerados | Resumo + contexto |

## 6. Evolucao Futura

Novos agentes podem ser adicionados conforme a base de conhecimento cresce:

| Agente potencial | Dominio | Gatilho |
|---|---|---|
| Compliance Agent | Regulatorio (BACEN, CVM, LGPD) | Quando docs de compliance forem ingeridos |
| Onboarding Agent | Integracao de novos colaboradores | Quando base tiver cobertura de processos > 80% |
| Incident Agent | Post-mortem e troubleshooting | Quando runbooks de incidentes estiverem catalogados |

## Referencias

- ADR-007: Retrieval Hibrido e Agentes Especializados
- ADR-004: Seguranca e Classificacao de Dados
- ADR-003: Modelo de Dados da Base Vetorial
- ADR-005: Front Matter -- Contrato de Metadados

<!-- conversion_quality: 95 -->
