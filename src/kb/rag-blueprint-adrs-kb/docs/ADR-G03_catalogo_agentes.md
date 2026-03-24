---
id: ADR-G03
doc_type: adr
title: "Catálogo de Agentes Especializados"
system: RAG Corporativo
module: Agentes Especializados
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - agentes especializados
  - architecture agent
  - operations agent
  - business agent
  - dispatcher
  - roteador de intenção
  - classificação de intenção
  - system prompt
  - filtro de documento
  - doc type
  - relações priorizadas
  - graph search
  - few shot
  - confidence threshold
  - fallback
  - ambiguous
  - retrieval híbrido
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
  - glossário
  - system doc
  - architecture doc
  - task doc
  - domínio
  - confidencialidade
  - compliance agent
  - onboarding agent
  - incident agent
  - evolução futura
  - cache
  - latência
  - acurácia
  - público alvo
  - tom de resposta
  - citação de origem
  - filtro de segurança
  - pipeline de query
  - classificação binária
  - módulo funcional
  - dependências técnicas
  - trade off
aliases:
  - "ADR-G03"
  - "Catálogo de Agentes"
  - "Catálogo de Agentes Especializados"
  - "Agentes do RAG"
  - "Dispatcher e Agentes"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/draft/ADR-G03_catalogo_agentes.txt"
source_beta_ids:
  - "BETA-G03"
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

# ADR-G03 — Catálogo de Agentes Especializados

| Campo | Valor |
|-------|-------|
| **Status** | Accepted |
| **Data da Decisão** | 2026-03-23 |
| **Decisor** | fabio |
| **Escopo** | Agentes Especializados |

**Referências Cruzadas:**

- **Depende de:** [[ADR-007]]
- **Relaciona-se:** [[ADR-004]], [[ADR-003]], [[ADR-005]], [[ADR-G02]]

## Objetivo

Catalogar os agentes especializados do RAG Corporativo, incluindo suas configurações de filtro, system prompts, relações priorizadas no grafo e a lógica do Dispatcher (roteador de intenção). Cada agente é otimizado para um domínio específico de perguntas.

## 1. Architecture Agent

### 1.1 Propósito

Responder perguntas sobre decisões arquiteturais, trade-offs técnicos, dependências entre sistemas e módulos, e evolução técnica. Público-alvo: desenvolvedores, tech leads e arquitetos.

### 1.2 Filtros de Documento

```
doc_type IN ["architecture-doc", "adr", "system-doc"]
```

Estes filtros são aplicados como restrição adicional ao filtro de segurança (que sempre roda primeiro). O agente só vê documentos que o usuário tem permissão E que são dos tipos acima.

### 1.3 Relações Priorizadas no Grafo

Ao executar Graph Search, o Architecture Agent prioriza:

| Relação | Direção | Uso |
|---|---|---|
| DEPENDS_ON | (:Module)-[:DEPENDS_ON]->(:Module) | Mapear dependências técnicas |
| BELONGS_TO | (:Document)-[:BELONGS_TO]->(:Module) | Contexto de módulo/sistema |
| DECIDES | (:ADR)-[:DECIDES]->(:System) | Decisões sobre sistemas |
| REFERENCES | (:Document)-[:REFERENCES]->(:Document) | Cadeia de referências |
| SUPERSEDES | (:Document)-[:SUPERSEDES]->(:Document) | Versionamento de ADRs |

### 1.4 System Prompt

> Você é um arquiteto de software sênior especializado na base de conhecimento corporativa. Suas respostas devem ter:
> - Profundidade técnica adequada ao público (desenvolvedores e arquitetos)
> - Citação explícita de ADRs relevantes (ex: "Conforme ADR-003...")
> - Análise de trade-offs quando existirem alternativas
> - Indicação de dependências e impactos em outros módulos
> - Referência a versões anteriores quando o documento foi superado
> - Linguagem técnica precisa em português brasileiro
>
> Regras:
> - Nunca invente informação além do contexto fornecido
> - Cite a origem de cada afirmação (documento, sistema, módulo)
> - Se a informação é incompleta, declare explicitamente
> - Alerte sobre documentos deprecated ou próximos de expiração

### 1.5 Exemplos de Queries

- "Qual ADR decidiu sobre o banco de dados do sistema de cobrança?"
- "Quais módulos dependem do módulo de autenticação?"
- "Quais foram os trade-offs considerados na escolha do Neo4j?"
- "Existe alguma ADR sobre estratégia de cache?"
- "Como evoluiu a arquitetura do módulo financeiro?"

## 2. Operations Agent

### 2.1 Propósito

Responder perguntas operacionais: como executar procedimentos, resolver incidentes, comandos exatos, passos de deploy e configuração. Público-alvo: engenheiros de operações, SREs e desenvolvedores em contexto de incidente.

### 2.2 Filtros de Documento

```
doc_type IN ["runbook", "glossary", "task-doc", "system-doc"]
```

### 2.3 Relações Priorizadas no Grafo

| Relação | Direção | Uso |
|---|---|---|
| BELONGS_TO | (:Document)-[:BELONGS_TO]->(:Module) | Contexto de módulo |
| IMPLEMENTS | (:Task)-[:IMPLEMENTS]->(:Module) | Tarefas relacionadas |
| RELATES_TO_TASK | (:Document)-[:RELATES_TO_TASK]->(:Task) | Documentação de tasks |

### 2.4 System Prompt

> Você é um engenheiro de operações sênior. Suas respostas devem:
> - Fornecer passos NUMERADOS, claros e executáveis
> - Incluir comandos EXATOS quando disponíveis (copiar e colar)
> - Destacar avisos de SEGURANÇA (ex: "ATENÇÃO: este comando apaga dados")
> - Indicar pré-requisitos antes de cada procedimento
> - Mencionar rollback quando aplicável
> - Usar linguagem direta e sem ambiguidade
>
> Regras:
> - Nunca sugira comandos que você não encontrou na documentação
> - Se o runbook está incompleto, alerte explicitamente
> - Indique a versão do documento consultado
> - Para procedimentos críticos, mencione quem deve aprovar

### 2.5 Exemplos de Queries

- "Como fazer deploy do módulo de cobrança em produção?"
- "Qual é o procedimento de rollback do sistema de pagamentos?"
- "Como reiniciar o serviço de notificações?"
- "Quais tasks estão relacionadas ao módulo de boletos?"
- "O que significa o termo 'liquidação' no glossário?"

## 3. Business Agent

### 3.1 Propósito

Responder perguntas de negócio: responsabilidades, regras vigentes, termos do glossário, estrutura organizacional. Público-alvo: gestores, analistas de negócio e executivos.

### 3.2 Filtros de Documento

```
domain filtrado conforme query (ex: se a query menciona "financeiro",
filtrar domain = "Financeiro")
```

Diferente dos outros agentes, o Business Agent filtra por DOMÍNIO em vez de doc_type, pois perguntas de negócio podem atravessar qualquer tipo de documento.

### 3.3 Relações Priorizadas no Grafo

| Relação | Direção | Uso |
|---|---|---|
| OWNED_BY | (:Document)-[:OWNED_BY]->(:Owner) | Responsáveis |
| MEMBER_OF | (:Owner)-[:MEMBER_OF]->(:Team) | Estrutura de times |
| USES_TERM | (:Document)-[:USES_TERM]->(:GlossaryTerm) | Termos de negócio |
| BELONGS_TO | (:Module)-[:BELONGS_TO]->(:System) | Contexto organizacional |

### 3.4 System Prompt

> Você é um analista de negócios sênior. Suas respostas devem:
> - Usar linguagem ACESSÍVEL (evitar jargão técnico desnecessário)
> - Citar regras com período de VIGÊNCIA (de quando até quando)
> - Indicar RESPONSÁVEIS (owner e time)
> - Contextualizar termos de negócio usando o glossário corporativo
> - Resumir quando o público for executivo (visão macro)
> - Detalhar quando o público for analista (visão operacional)
>
> Regras:
> - Nunca invente regras de negócio
> - Cite a fonte de cada afirmação
> - Se há conflito entre documentos, apresente ambas as versões com datas
> - Alerte sobre regras expiradas ou em revisão

### 3.5 Exemplos de Queries

- "Quem é o responsável pelo processo de cobrança?"
- "Qual time cuida do sistema de pagamentos?"
- "O que significa 'remessa bancária'?"
- "Quais são as regras vigentes de cancelamento de boleto?"
- "Qual é a estrutura organizacional da área financeira?"

## 4. Dispatcher (Roteador de Intenção)

### 4.1 Mecanismo

O Dispatcher é o componente que classifica a intenção da query e direciona para o agente especializado correto. Usa um LLM com few-shot examples para classificação.

### 4.2 Classificação

Entrada: query do usuário (texto livre)
Saída: uma das categorias: "architecture", "operations", "business", "ambiguous"

| Intenção | Critérios | Agente |
|---|---|---|
| architecture | Menciona ADR, decisão, trade-off, dependência técnica, arquitetura, escolha de tecnologia | Architecture Agent |
| operations | Menciona deploy, procedimento, comando, restart, rollback, incidente, runbook, passo-a-passo | Operations Agent |
| business | Menciona responsável, dono, time, regra de negócio, glossário, organização, domínio | Business Agent |
| ambiguous | Não se encaixa claramente em nenhuma categoria OU confiança < 0.7 | Todos (fallback) |

### 4.3 Few-Shot Examples para o Dispatcher

**Exemplo 1:**
- Query: "Qual ADR decidiu sobre o banco de dados?"
- Classificação: architecture
- Justificativa: menciona ADR e decisão técnica

**Exemplo 2:**
- Query: "Como fazer deploy do módulo de cobrança?"
- Classificação: operations
- Justificativa: menciona deploy e procedimento operacional

**Exemplo 3:**
- Query: "Quem é o responsável pelo sistema de pagamentos?"
- Classificação: business
- Justificativa: pergunta sobre responsável/owner

**Exemplo 4:**
- Query: "Me fale sobre o sistema SAP"
- Classificação: ambiguous
- Justificativa: pergunta genérica sem direção clara

**Exemplo 5:**
- Query: "Quais dependências o módulo de cobrança tem e quem cuida dele?"
- Classificação: ambiguous
- Justificativa: mistura arquitetura (dependências) com negócio (responsável)

### 4.4 Configuração do Dispatcher

| Parâmetro | Valor |
|---|---|
| Modelo | LLM leve (GPT-4o-mini ou Llama 3.1 8B local) |
| Latência alvo | < 100ms |
| Cache | 5 minutos para queries idênticas |
| Confidence | Se confiança < 0.7, classificar como "ambiguous" |
| Few-shot | Mínimo 5 exemplos por categoria |

### 4.5 Fallback (Ambiguous)

Quando a classificação é "ambiguous":
1. Acionar TODOS os 3 agentes em paralelo
2. Cada agente executa seu pipeline completo (filtros + buscas + reranking)
3. Resultados dos 3 agentes são fundidos via RRF adicional
4. Top-K final é montado a partir da fusão

Trade-off: latência ~3x maior, mas evita perda de informação por classificação incorreta.

### 4.6 Métricas do Dispatcher

| Métrica | Alvo |
|---|---|
| Acurácia de classificação | > 85% |
| % queries ambiguous (fallback) | < 20% |
| Latência média | < 100ms |
| Cache hit rate | > 30% |

## 5. Tabela Consolidada dos Agentes

| Aspecto | Architecture | Operations | Business |
|---|---|---|---|
| Público | Devs, Arquitetos | SREs, Ops | Gestores, Analistas |
| Filtro doc_type | arch-doc, adr, sys | runbook, glossary, task-doc, sys-doc | (por domínio) |
| Relações prio | DEPENDS_ON, DECIDES, REFERENCES | BELONGS_TO, IMPLEMENTS, RELATES_TO_TASK | OWNED_BY, MEMBER_OF, USES_TERM |
| Tom | Técnico | Direto/executável | Acessível |
| Formato | Análise + refs | Passos numerados | Resumo + contexto |

## 6. Evolução Futura

Novos agentes podem ser adicionados conforme a base de conhecimento cresce:

| Agente potencial | Domínio | Gatilho |
|---|---|---|
| Compliance Agent | Regulatório (BACEN, CVM, LGPD) | Quando docs de compliance forem ingeridos |
| Onboarding Agent | Integração de novos colaboradores | Quando base tiver cobertura de processos > 80% |
| Incident Agent | Post-mortem e troubleshooting | Quando runbooks de incidentes estiverem catalogados |

## Referências

- [[ADR-007]]: Retrieval Híbrido e Agentes Especializados
- [[ADR-004]]: Segurança e Classificação de Dados
- [[ADR-003]]: Modelo de Dados da Base Vetorial
- [[ADR-005]]: Front Matter — Contrato de Metadados

<!-- conversion_quality: 95 -->
