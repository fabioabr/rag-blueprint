---
id: BETA-002
title: "Soberania de Dados: Trilha Cloud vs. On-Premise"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-002_soberania_dados_cloud_vs_onprem.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags:
  - soberania dados
  - cloud vs on-premise
  - trilha cloud
  - trilha on-premise
  - trilha hibrida
  - confidencialidade
  - roteamento dados
  - modelo embedding
  - base vetorial
  - llm geracao
  - reranking
  - embedding open source
  - gpu consumer
  - multilingue
  - busca cross-instancia
  - incompatibilidade embeddings
  - componente mais restritivo
  - regulacao setorial
  - bacen
  - cvm
  - lgpd
  - sox
  - hipaa
  - politica seguranca interna
  - clausulas contratuais
  - nda
  - risco reputacional
  - latencia disponibilidade
  - pipeline 4 fases
  - front matter confidentiality
  - filtro pre-retrieval
  - instancia gerenciada
  - self hosted docker
  - community edition
  - instruction following
  - 70b parametros
  - quantizacao
  - capacity planning
  - checklist deploy
  - metricas observabilidade
  - catalogo componentes
  - glossario infraestrutura
  - vendor lock-in
  - abstracoes interfaces
  - re-indexacao automatizada
  - custo otimizado
  - compliance garantido
  - flexibilidade adocao
  - decisao automatica
  - evolucao independente
  - encryption at rest
  - govcloud
aliases:
  - "ADR-002"
  - "Soberania de Dados"
  - "Cloud vs On-Premise"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## Cabecalho

| Campo | Valor |
|-------|-------|
| **Status** | proposed |
| **Data** | 21/03/2026 |
| **Revisao** | 23/03/2026 (reescrita para separar decisao de processo) |
| **Decisor** | Fabio A. B. Rodrigues |
| **Escopo** | RAG Corporativo — Componentes de infraestrutura, modelos de embedding, LLM, reranking e base vetorial |
| **Supersede** | (nenhum) |
| **Depende de** | ADR-001 (Pipeline 4 Fases — define as 4 fases, 2 repos, .beta.md, blocos LOCKED e campo confidentiality) |
| **Relaciona** | ADR-003 (Modelo de Dados da Base Vetorial) |

## 1. Sumario

Este ADR e a **decisao macro** que determina como o projeto RAG Corporativo escolhe entre servicos de nuvem e infraestrutura local (on-premise) para cada componente do pipeline. Trata-se da decisao mais cascateante do projeto: a partir dela, **4 escolhas pendentes** sao resolvidas de uma vez (modelo de embedding, infraestrutura da base vetorial, LLM de geracao, modelo de reranking).

A premissa central e: a **classificacao de confidencialidade** do documento (definida no front matter) determina qual trilha cada informacao percorre. Nao existe uma unica resposta — existem **duas trilhas** validas que o projeto suporta simultaneamente.

**Nota:** esta versao foca exclusivamente nas decisoes arquiteturais e suas justificativas. Conteudos de processo foram extraidos para documentos dedicados:
- SPEC-D01: Catalogo de Componentes por Trilha
- SPEC-D02: Metricas de Observabilidade
- DOC-D03: Capacity Planning Infraestrutura
- RNB-D04: Checklist de Deploy por Trilha
- GLS-A05: Glossario de Termos de Infraestrutura

## 2. Contexto

### 2.1. O problema da soberania

Muitas organizacoes **nao podem** enviar sua base de conhecimento para servicos externos. As razoes sao multiplas e frequentemente cumulativas:

**(a) Politica de seguranca interna** — Empresas com politica de seguranca da informacao que classifica documentos internos como restritos proibem o envio de dados para APIs externas, independentemente de termos de uso do fornecedor.

**(b) Regulacao setorial** — BACEN, CVM, LGPD, SOX e HIPAA impoem restricoes sobre onde dados sensiveis podem ser armazenados e processados. Uma base de conhecimento corporativa que contenha dados pessoais, informacoes financeiras ou segredos industriais esta sujeita a essas regulacoes.

**(c) Clausulas contratuais de confidencialidade** — NDAs e contratos governamentais frequentemente proibem o compartilhamento de informacoes tecnicas com terceiros, incluindo provedores de API.

**(d) Risco reputacional** — Mesmo sem violacao legal, o vazamento de informacao via API de terceiro gera dano reputacional inaceitavel.

**(e) Latencia e disponibilidade** — Dependencia de API externa significa que o RAG para de funcionar quando o servico externo cai ou muda precos/limites.

### 2.2. Por que esta decisao e fundacional

O pipeline definido na ADR-001 tem 4 fases. Nas Fases 3 e 4, o pipeline precisa de: modelo de embedding, base vetorial, LLM e modelo de reranking.

Cada um desses componentes pode ser cloud **ou** local. A decisao sobre soberania de dados resolve todos de uma vez, porque o criterio e o mesmo: **o dado pode sair da infraestrutura controlada pela organizacao?**

- Se **SIM** → Trilha Cloud (mais simples, mais barata para comecar)
- Se **NAO** → Trilha On-Premise (mais complexa, mas soberana)

### 2.3. Contexto tecnico atual (marco 2026)

O ecossistema de modelos open-source atingiu maturidade suficiente para viabilizar a Trilha On-Premise com qualidade competitiva:

- Embeddings open-source alcancam 95%+ da qualidade de modelos cloud em benchmarks multilingues, rodando em GPU consumer (8GB VRAM)
- LLMs open-source de 70B+ parametros competem com modelos proprietarios em tarefas de RAG (resposta com contexto fornecido)
- Rerankers open-source atingem resultados comparaveis a solucoes cloud em cenarios de re-ranking com passagens em portugues
- Bases vetoriais com suporte a grafo possuem edicoes community com funcionalidades suficientes

Isso **nao** era verdade 18 meses atras. A viabilidade da Trilha On-Premise e uma janela recente que torna esta ADR possivel.

### 2.4. Alinhamento com os 8 pilares da ADR-001

A ADR-001 define 8 pilares norteadores. A decisao de soberania impacta cada pilar:

| Pilar | Impacto da ADR-002 |
|-------|-------------------|
| **A** | Segregacao de responsabilidades: Trilha A operada por Engenharia de Dados; Trilha B operada por Infraestrutura/Ops. Pipeline e o mesmo, mudam apenas os adaptadores. |
| **B** | Desacoplamento: ambas as trilhas usam interfaces abstratas. Trocar componente em uma trilha **nao** impacta a outra. |
| **C** | Qualidade: gates de qualidade (QA score >= 90%) sao identicos em ambas as trilhas. Promocao `.beta.md` -> `.md` e agnostica. |
| **D** | Observabilidade: cada trilha possui metricas proprias (ver SPEC-D02). |
| **E** | Clareza: o campo `confidentiality` no front matter torna explicita a trilha de cada documento. Nao ha ambiguidade. |
| **F** | Versionamento: Git controla ambas as trilhas. O `embedding_model` e registrado no chunk para rastreabilidade. |
| **G** | Rastreabilidade: ambas registram `embedding_model`, `embedding_date`, trilha e versao do modelo. |
| **H** | Reprodutibilidade: Trilha A deterministica via API. Trilha B com variacao minima em quantizados, mitigada fixando seed e versao exata. |

## 3. Decisao

O projeto RAG Corporativo suporta **duas trilhas** simultaneas, definidas pela classificacao de confidencialidade do documento (front matter).

- **Trilha A (Cloud Permitido):** componentes cloud para dados `public` e `internal`.
- **Trilha B (Full On-Premise):** componentes locais para dados `restricted` e `confidential`.
- **Trilha Hibrida:** a mesma organizacao pode usar ambas as trilhas simultaneamente, segregando por nivel de confidencialidade.

O **nivel de confidencialidade** do dado determina a trilha. **Nao** e uma escolha de preferencia — e uma **obrigacao**.

### 3.1. Regra de roteamento

O front matter de cada documento possui o campo `confidentiality`. Conforme ADR-001 (secao 2.5), este campo esta presente **desde** o `.beta.md` (Fase 2) para garantir que dados sensiveis nao sejam processados por APIs cloud em nenhuma etapa do pipeline.

Os 4 niveis de confidencialidade e suas trilhas:

| Nivel | Trilha Permitida | Descricao |
|-------|-----------------|-----------|
| `public` | A (Cloud) | Informacao publica, pode ser processada em qualquer lugar. |
| `internal` | A (Cloud) | Uso interno, sem restricao legal de envio externo. |
| `restricted` | B (On-Premise) | Dados com restricao regulatoria ou contratual. **Nao** pode sair. |
| `confidential` | B (On-Premise) | Altamente confidencial. Somente infraestrutura isolada. |

**Regra:** o pipeline de ingestao **verifica** o campo `confidentiality` **antes** de escolher qual modelo de embedding usar, qual instancia da base vetorial receber o dado, e qual LLM pode gerar respostas sobre ele.

Essa verificacao e **pre-retrieval** (antes da busca vetorial), nunca pos-retrieval. O dado restrito **nunca** chega a um componente cloud.

### 3.2. Escolhas de componentes por trilha

Para cada componente do pipeline, ha uma opcao recomendada por trilha. O catalogo completo com detalhamento tecnico, custos, requisitos de hardware e configuracoes de referencia esta em SPEC-D01.

**Resumo das escolhas e justificativas:**

#### Embedding

- **Trilha A:** modelo cloud de referencia (1536d, custo por token minimo). *Justificativa:* melhor relacao custo x qualidade x simplicidade para dados que podem sair. Custo tao baixo que nao justifica infraestrutura propria para dados nao-restritos.
- **Trilha B:** modelo open-source multilingue com modo hibrido nativo (dense + sparse + colbert), rodando em GPU consumer (8GB VRAM). *Justificativa:* unico modelo open-source que combina qualidade multilingue competitiva com modo hibrido nativo. Barreira de entrada baixa por rodar em GPU consumer.

#### Base Vetorial

- **Trilha A:** instancia gerenciada pelo provedor (DBaaS). *Justificativa:* elimina necessidade de DBA/ops dedicado. Custo previsivel e escalabilidade automatica.
- **Trilha B:** instalacao self-hosted via Docker (Community Edition). *Justificativa:* Community Edition oferece todas as funcionalidades necessarias (vector index, graph traversal, full-text, constraints). Limitacao de single-instance nao e problema para bases tipicas (<500K chunks).

#### LLM

- **Trilha A:** modelo cloud com melhor instruction following do mercado. *Justificativa:* capacidade de seguir instrucoes complexas e decisiva para gerar `.beta.md` com front matter estruturado, respeitar blocos LOCKED e formatar documentos segundo templates.
- **Trilha B:** LLM open-source de 70B+ parametros via serving local. *Justificativa:* unicos modelos open-source com qualidade suficiente para as tres funcoes do pipeline (mineracao, geracao de `.md`, respostas RAG). Modelos menores (7-13B) falham em tarefas de formatacao estruturada e instruction following.

#### Reranking

- **Trilha A:** reranker cloud de referencia para multilingue. *Justificativa:* melhor desempenho documentado em benchmarks multilingues. Integracao trivial e custo proporcional ao uso.
- **Trilha B:** reranker open-source da mesma familia do modelo de embedding. *Justificativa:* sinergia com o modelo de embedding (mesmo tokenizador, mesma GPU pode servir ambos). Unico reranker open-source com qualidade competitiva em multilingue que roda em GPU consumer.

**Nota sobre o LLM nas Fases 2 e 3:** O LLM nao e usado apenas na Fase 4. Ele tambem e usado na mineracao de `.beta.md` (Fase 2) e na geracao do `.md` final (Fase 3). A regra de roteamento por `confidentiality` se aplica **desde** a Fase 2: um documento `restricted`/`confidential` **deve** usar LLM local mesmo na mineracao.

### 3.3. Trilha hibrida — o cenario mais comum

Na pratica, a maioria das organizacoes usara a **Trilha Hibrida**:

- Documentos `public` e `internal` → processados pela Trilha A (Cloud)
- Documentos `restricted` e `confidential` → processados pela Trilha B

Isso significa que a organizacao opera **duas instancias paralelas** da base vetorial, com modelos de embedding diferentes e incompativeis.

**Incompatibilidade de embeddings:** Os vetores gerados pelos modelos cloud e on-premise **nao** sao compativeis (dimensoes diferentes). Um chunk indexado com modelo cloud so pode ser buscado com embedding de query gerado pelo mesmo modelo. Isso reforca a separacao em duas instancias.

**Busca cross-instancia:** Para busca que precisa de resultados de ambas as instancias, o retriever executa a busca em **paralelo** nas duas instancias e faz merge dos resultados antes do reranking. Isso so e permitido quando o usuario tem acesso a ambos os niveis de confidencialidade.

**Regra:** quando resultados de ambas as instancias sao mesclados, o reranking e a geracao de resposta **devem** usar componentes on-premise, pois chunks `restricted`/`confidential` estao presentes. O **componente mais restritivo** determina a trilha.

**Nota:** o reranker on-premise e um cross-encoder que opera sobre **texto** (nao sobre embeddings), portanto funciona corretamente independentemente de qual modelo gerou os embeddings originais.

### 3.4. Matriz de decisao

**Pergunta 1:** A organizacao possui **algum** documento `restricted` ou `confidential`?
- **Nao** → Use Trilha A (Cloud) para tudo. Fim.
- **Sim** → Continue.

**Pergunta 2:** **Todos** os documentos sao `restricted` ou `confidential`?
- **Sim** → Use Trilha B (On-Premise) para tudo. Fim.
- **Nao** → Continue.

**Pergunta 3:** A organizacao aceita operar duas instancias simultaneamente?
- **Sim** → Use Trilha Hibrida (A + B). Fim.
- **Nao** → Use Trilha B para tudo (mais seguro, sacrifica qualidade para dados nao-restritos). Fim.

## 4. Alternativas descartadas

### 4.1. Trilha unica cloud

Usar somente componentes cloud para todos os niveis de confidencialidade, confiando nos termos de uso e contratos dos provedores.

**Por que descartada:** insuficiente para ambientes regulados. Termos de uso de API **nao** substituem requisitos regulatorios (BACEN, CVM). Mesmo com contrato enterprise, o dado trafega por infraestrutura de terceiro. Auditorias externas frequentemente questionam a localizacao fisica dos dados — e a resposta precisa ser "na nossa infraestrutura".

### 4.2. Trilha unica on-premise

Usar somente componentes on-premise para todos os niveis, mesmo para dados publicos.

**Por que descartada:** desperdica recursos e qualidade. Para dados `public`/`internal`, a qualidade dos modelos cloud e superior e o custo e menor. Forcar Trilha B para dados que nao precisam de soberania e over-engineering. Alem disso, nem toda organizacao tem GPUs — a Trilha A permite comecar sem investimento em hardware.

### 4.3. Encryption-at-rest + cloud

Enviar dados criptografados para cloud, descriptografar apenas no momento do processamento.

**Por que descartada:** tecnicamente inviavel para embeddings. O modelo precisa do **texto claro** para gerar o vetor. Nao ha como gerar embedding de texto criptografado e obter resultados semanticamente uteis. Tecnicas de "homomorphic encryption" para busca vetorial existem em pesquisa academica, mas nao estao em producao (latencia 1000x+ maior, precisao degradada).

### 4.4. Provedor cloud com regiao dedicada

Contratar regiao dedicada (ex: GovCloud) com garantia de isolamento fisico e compliance.

**Por que descartada:** custo proibitivo (10-50x mais caro que regiao padrao). Disponivel apenas para contratos governamentais especificos. Nao resolve o problema fundamental: o dado ainda esta na infraestrutura de um terceiro, mesmo que fisicamente isolado.

### 4.5. Modelos de embedding menores on-premise

Usar modelos de embedding menores (<1B parametros) para reduzir requisito de GPU.

**Por que descartada:** qualidade insuficiente para portugues. Modelos pequenos tem desempenho significativamente inferior em linguas nao-inglesas. O modelo escolhido, apesar de maior, roda em GPU consumer (8GB VRAM) e oferece qualidade multilingue competitiva. A economia de GPU nao compensa a perda de qualidade.

### 4.6. LLM local pequeno (7B-13B) para todas as tarefas

Usar modelos de 7-13B parametros no lugar dos 70B+, reduzindo drasticamente o requisito de GPU.

**Por que descartada:** modelos de 7-13B falham consistentemente em tres tarefas criticas do pipeline:
- (a) Geracao de `.beta.md` com front matter estruturado (Fase 2)
- (b) Respeito a blocos LOCKED (Fase 2)
- (c) Respostas com citacao de fontes (Fase 4)

## 5. Consequencias

### 5.1. Positivas

**(a) Compliance garantido:** organizacoes reguladas podem adotar o RAG sem violar politicas de seguranca, porque a Trilha B garante que dados restritos nunca saem da infraestrutura propria.

**(b) Flexibilidade de adocao:** organizacoes sem restricao podem comecar pela Trilha A (zero hardware) e migrar para Trilha B conforme necessidade. O pipeline e o mesmo — so mudam os componentes.

**(c) Decisao automatica:** o campo `confidentiality` no front matter determina automaticamente a trilha. Nao ha decisao humana no momento da ingestao — o pipeline le o metadado e roteia.

**(d) Custo otimizado:** dados que podem ir para cloud usam cloud (melhor qualidade, menor custo operacional). Dados que precisam ficar locais usam local. Nao ha desperdicio.

**(e) Evolucao independente:** cada trilha pode evoluir separadamente. Se surgir um embedding cloud melhor, troca-se na Trilha A sem impactar a Trilha B. E vice-versa.

**(f) Alinhamento com ADR-001:** as 4 fases do pipeline funcionam identicamente em ambas as trilhas. A soberania e uma preocupacao de **infraestrutura**, nao de **processo**.

### 5.2. Negativas / Trade-offs

**(a) Complexidade operacional:** manter duas instancias da base vetorial, dois conjuntos de modelos e dois fluxos de serving aumenta a complexidade operacional significativamente.

**(b) Inconsistencia de qualidade:** a Trilha A (cloud) tera qualidade ligeiramente superior a Trilha B (on-premise) em embeddings, reranking e respostas do LLM.

**(c) Busca cross-instancia:** a busca que cruza dados das duas instancias e mais complexa (merge de resultados de embeddings incompativeis) e mais lenta.

**(d) Custo de hardware:** a Trilha B exige investimento inicial em GPUs que pode ser barreira para organizacoes menores (ver DOC-D03).

**(e) Competencia da equipe:** a Trilha B exige equipe capaz de operar modelos de ML em producao (GPU drivers, CUDA, model serving, monitoramento de inferencia).

### 5.3. Riscos e mitigacoes

**Risco 1: Classificacao incorreta de confidencialidade**
- Probabilidade: **Media** | Impacto: **Alto**
- Documento `confidential` classificado como `internal` por erro humano, sendo enviado para componentes cloud.
- *Mitigacao:* validacao automatica no pipeline de promocao (Fase 3). Regras por dominio e tags bloqueiam promocao se nivel estiver abaixo do minimo esperado.

**Risco 2: Degradacao de qualidade na Trilha B**
- Probabilidade: **Baixa** | Impacto: **Medio**
- Modelos open-source evoluem mais devagar que proprietarios.
- *Mitigacao:* monitorar benchmarks trimestralmente. Pipeline e agnostico ao modelo — basta trocar o endpoint.

**Risco 3: Indisponibilidade da Trilha A**
- Probabilidade: **Baixa** | Impacto: **Medio**
- API de provedores cloud fora do ar impede buscas em dados nao-restritos.
- *Mitigacao:* implementar fallback local para a Trilha A (somente viavel se a organizacao ja possui infraestrutura da Trilha B).

**Risco 4: Custo cloud escalando**
- Probabilidade: **Media** | Impacto: **Baixo**
- Aumento de uso faz o custo cloud escalar alem do orcamento.
- *Mitigacao:* monitorar custo mensal. Se ultrapassar threshold, migrar dados `internal` para Trilha B, mantendo apenas `public` na Trilha A.

**Risco 5: Vendor lock-in**
- Probabilidade: **Media** | Impacto: **Medio**
- Dependencia de provedores cloud pode ser problematica se mudarem precos, termos ou descontinuarem modelos.
- *Mitigacao:* arquitetura usa abstracoes (interfaces de embedding, LLM e reranking). Trocar provedor **nao** exige mudar o pipeline, apenas o adaptador. Re-indexacao e automatizada.

## 6. Implementacao (alto nivel)

A implementacao segue 4 fases progressivas:

**Fase 1 — MVP (Trilha A apenas, dados public/internal)**
Configurar base vetorial managed, integrar APIs cloud de embedding e LLM, ingerir documentos `public`/`internal`. Sem reranking nesta fase.
*DOD:* busca vetorial retorna resultados corretos; LLM gera respostas com citacao de fonte.

**Fase 2 — Reranking + Qualidade (Trilha A)**
Adicionar reranker cloud. Medir melhoria de precisao (precision@10, MRR). Ajustar parametros (top-K retrieval, top-N reranking).
*DOD:* precision@10 melhora >= 15% com reranking.

**Fase 3 — Trilha B (dados restricted/confidential)**
Provisionar hardware, instalar base vetorial self-hosted, configurar modelos de embedding, LLM e reranking locais. Ingerir documentos `restricted`/`confidential`.
*DOD:* nenhum dado `restricted`/`confidential` trafega por rede externa; latencia < 2s end-to-end. Ver RNB-D04 para checklist completo.

**Fase 4 — Trilha Hibrida (busca cross-instancia)**
Implementar retriever multi-instancia, merge de resultados e controle de acesso por usuario.
*DOD:* busca cross-instancia retorna resultados mesclados corretamente; controle de acesso impede usuario sem permissao de ver dados `restricted`.

Detalhamento de hardware, capacity planning e custos: ver DOC-D03.
Checklists de validacao por trilha: ver RNB-D04.
Metricas de observabilidade por trilha: ver SPEC-D02.

## 7. Referencias

### Decisoes relacionadas

- **ADR-001** — Pipeline de Geracao de Conhecimento em 4 Fases (define o pipeline que esta ADR complementa com escolhas de infra)
- **ADR-003** — Modelo de Dados da Base Vetorial (define os nos e relacoes armazenados na infra escolhida aqui)

### Documentos do blueprint

- B14 — Seguranca e Soberania de Dados
- B03 — Camada Ouro (pipeline de ingestao na base vetorial)
- B07 — Visao Consolidada

### Documentos extraidos desta ADR

- **SPEC-D01:** Catalogo de Componentes por Trilha
- **SPEC-D02:** Metricas de Observabilidade
- **DOC-D03:** Capacity Planning Infraestrutura
- **RNB-D04:** Checklist de Deploy por Trilha
- **GLS-A05:** Glossario de Termos de Infraestrutura

### Referencias externas

- LGPD (Lei 13.709/2018): http://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm

<!-- conversion_quality: 95 -->
