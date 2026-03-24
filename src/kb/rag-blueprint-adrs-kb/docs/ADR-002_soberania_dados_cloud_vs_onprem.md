---
id: ADR-002
doc_type: adr
title: "Soberania de Dados: Trilha Cloud vs. On-Premise"
system: RAG Corporativo
module: Soberania de Dados
domain: arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-21
tags:
  - soberania dados
  - cloud vs on premise
  - trilha cloud
  - trilha on premise
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
  - busca cross instancia
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
  - filtro pre retrieval
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
  - vendor lock in
  - abstracoes interfaces
  - re indexacao automatizada
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
  - "Data Sovereignty"
  - "Trilha A e B"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-002_soberania_dados_cloud_vs_onprem.beta.md"
source_beta_ids:
  - "BETA-002"
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

# ADR-002 — Soberania de Dados: Trilha Cloud vs. On-Premise

## Cabeçalho

| Campo | Valor |
|-------|-------|
| **Status** | proposed |
| **Data** | 21/03/2026 |
| **Revisão** | 23/03/2026 (reescrita para separar decisão de processo) |
| **Decisor** | Fabio A. B. Rodrigues |
| **Escopo** | RAG Corporativo — Componentes de infraestrutura, modelos de embedding, LLM, reranking e base vetorial |
| **Supersede** | (nenhum) |
| **Depende de** | [[ADR-001]] (Pipeline 4 Fases — define as 4 fases, 2 repos, .beta.md, blocos LOCKED e campo confidentiality) |
| **Relaciona** | [[ADR-003]] (Modelo de Dados da Base Vetorial) |

## 1. Sumário

Este ADR é a **decisão macro** que determina como o projeto RAG Corporativo escolhe entre serviços de nuvem e infraestrutura local (on-premise) para cada componente do pipeline. Trata-se da decisão mais cascateante do projeto: a partir dela, **4 escolhas pendentes** são resolvidas de uma vez (modelo de embedding, infraestrutura da base vetorial, LLM de geração, modelo de reranking).

A premissa central é: a **classificação de confidencialidade** do documento (definida no front matter) determina qual trilha cada informação percorre. Não existe uma única resposta — existem **duas trilhas** válidas que o projeto suporta simultaneamente.

**Nota:** esta versão foca exclusivamente nas decisões arquiteturais e suas justificativas. Conteúdos de processo foram extraídos para documentos dedicados:
- SPEC-D01: Catálogo de Componentes por Trilha
- SPEC-D02: Métricas de Observabilidade
- DOC-D03: Capacity Planning Infraestrutura
- RNB-D04: Checklist de Deploy por Trilha
- GLS-A05: Glossário de Termos de Infraestrutura

## 2. Contexto

### 2.1. O problema da soberania

Muitas organizações **não podem** enviar sua base de conhecimento para serviços externos. As razões são múltiplas e frequentemente cumulativas:

**(a) Política de segurança interna** — Empresas com política de segurança da informação que classifica documentos internos como restritos proíbem o envio de dados para APIs externas, independentemente de termos de uso do fornecedor.

**(b) Regulação setorial** — BACEN, CVM, LGPD, SOX e HIPAA impõem restrições sobre onde dados sensíveis podem ser armazenados e processados. Uma base de conhecimento corporativa que contenha dados pessoais, informações financeiras ou segredos industriais está sujeita a essas regulações.

**(c) Cláusulas contratuais de confidencialidade** — NDAs e contratos governamentais frequentemente proíbem o compartilhamento de informações técnicas com terceiros, incluindo provedores de API.

**(d) Risco reputacional** — Mesmo sem violação legal, o vazamento de informação via API de terceiro gera dano reputacional inaceitável.

**(e) Latência e disponibilidade** — Dependência de API externa significa que o RAG para de funcionar quando o serviço externo cai ou muda preços/limites.

### 2.2. Por que esta decisão é fundacional

O pipeline definido na [[ADR-001]] tem 4 fases. Nas Fases 3 e 4, o pipeline precisa de: modelo de embedding, base vetorial, LLM e modelo de reranking.

Cada um desses componentes pode ser cloud **ou** local. A decisão sobre soberania de dados resolve todos de uma vez, porque o critério é o mesmo: **o dado pode sair da infraestrutura controlada pela organização?**

- Se **SIM** → Trilha Cloud (mais simples, mais barata para começar)
- Se **NÃO** → Trilha On-Premise (mais complexa, mas soberana)

### 2.3. Contexto técnico atual (março 2026)

O ecossistema de modelos open-source atingiu maturidade suficiente para viabilizar a Trilha On-Premise com qualidade competitiva:

- Embeddings open-source alcançam 95%+ da qualidade de modelos cloud em benchmarks multilíngues, rodando em GPU consumer (8GB VRAM)
- LLMs open-source de 70B+ parâmetros competem com modelos proprietários em tarefas de RAG (resposta com contexto fornecido)
- Rerankers open-source atingem resultados comparáveis a soluções cloud em cenários de re-ranking com passagens em português
- Bases vetoriais com suporte a grafo possuem edições community com funcionalidades suficientes

Isso **não** era verdade 18 meses atrás. A viabilidade da Trilha On-Premise é uma janela recente que torna esta ADR possível.

### 2.4. Alinhamento com os 8 pilares da [[ADR-001]]

A [[ADR-001]] define 8 pilares norteadores. A decisão de soberania impacta cada pilar:

| Pilar | Impacto da ADR-002 |
|-------|-------------------|
| **A** | Segregação de responsabilidades: Trilha A operada por Engenharia de Dados; Trilha B operada por Infraestrutura/Ops. Pipeline é o mesmo, mudam apenas os adaptadores. |
| **B** | Desacoplamento: ambas as trilhas usam interfaces abstratas. Trocar componente em uma trilha **não** impacta a outra. |
| **C** | Qualidade: gates de qualidade (QA score >= 90%) são idênticos em ambas as trilhas. Promoção `.beta.md` -> `.md` é agnóstica. |
| **D** | Observabilidade: cada trilha possui métricas próprias (ver SPEC-D02). |
| **E** | Clareza: o campo `confidentiality` no front matter torna explícita a trilha de cada documento. Não há ambiguidade. |
| **F** | Versionamento: Git controla ambas as trilhas. O `embedding_model` é registrado no chunk para rastreabilidade. |
| **G** | Rastreabilidade: ambas registram `embedding_model`, `embedding_date`, trilha e versão do modelo. |
| **H** | Reprodutibilidade: Trilha A determinística via API. Trilha B com variação mínima em quantizados, mitigada fixando seed e versão exata. |

## 3. Decisão

O projeto RAG Corporativo suporta **duas trilhas** simultâneas, definidas pela classificação de confidencialidade do documento (front matter).

- **Trilha A (Cloud Permitido):** componentes cloud para dados `public` e `internal`.
- **Trilha B (Full On-Premise):** componentes locais para dados `restricted` e `confidential`.
- **Trilha Híbrida:** a mesma organização pode usar ambas as trilhas simultaneamente, segregando por nível de confidencialidade.

O **nível de confidencialidade** do dado determina a trilha. **Não** é uma escolha de preferência — é uma **obrigação**.

### 3.1. Regra de roteamento

O front matter de cada documento possui o campo `confidentiality`. Conforme [[ADR-001]] (seção 2.5), este campo está presente **desde** o `.beta.md` (Fase 2) para garantir que dados sensíveis não sejam processados por APIs cloud em nenhuma etapa do pipeline.

Os 4 níveis de confidencialidade e suas trilhas:

| Nível | Trilha Permitida | Descrição |
|-------|-----------------|-----------|
| `public` | A (Cloud) | Informação pública, pode ser processada em qualquer lugar. |
| `internal` | A (Cloud) | Uso interno, sem restrição legal de envio externo. |
| `restricted` | B (On-Premise) | Dados com restrição regulatória ou contratual. **Não** pode sair. |
| `confidential` | B (On-Premise) | Altamente confidencial. Somente infraestrutura isolada. |

**Regra:** o pipeline de ingestão **verifica** o campo `confidentiality` **antes** de escolher qual modelo de embedding usar, qual instância da base vetorial receber o dado, e qual LLM pode gerar respostas sobre ele.

Essa verificação é **pre-retrieval** (antes da busca vetorial), nunca pós-retrieval. O dado restrito **nunca** chega a um componente cloud.

### 3.2. Escolhas de componentes por trilha

Para cada componente do pipeline, há uma opção recomendada por trilha. O catálogo completo com detalhamento técnico, custos, requisitos de hardware e configurações de referência está em SPEC-D01.

**Resumo das escolhas e justificativas:**

#### Embedding

- **Trilha A:** modelo cloud de referência (1536d, custo por token mínimo). *Justificativa:* melhor relação custo x qualidade x simplicidade para dados que podem sair. Custo tão baixo que não justifica infraestrutura própria para dados não-restritos.
- **Trilha B:** modelo open-source multilíngue com modo híbrido nativo (dense + sparse + colbert), rodando em GPU consumer (8GB VRAM). *Justificativa:* único modelo open-source que combina qualidade multilíngue competitiva com modo híbrido nativo. Barreira de entrada baixa por rodar em GPU consumer.

#### Base Vetorial

- **Trilha A:** instância gerenciada pelo provedor (DBaaS). *Justificativa:* elimina necessidade de DBA/ops dedicado. Custo previsível e escalabilidade automática.
- **Trilha B:** instalação self-hosted via Docker (Community Edition). *Justificativa:* Community Edition oferece todas as funcionalidades necessárias (vector index, graph traversal, full-text, constraints). Limitação de single-instance não é problema para bases típicas (<500K chunks).

#### LLM

- **Trilha A:** modelo cloud com melhor instruction following do mercado. *Justificativa:* capacidade de seguir instruções complexas é decisiva para gerar `.beta.md` com front matter estruturado, respeitar blocos LOCKED e formatar documentos segundo templates.
- **Trilha B:** LLM open-source de 70B+ parâmetros via serving local. *Justificativa:* únicos modelos open-source com qualidade suficiente para as três funções do pipeline (mineração, geração de `.md`, respostas RAG). Modelos menores (7-13B) falham em tarefas de formatação estruturada e instruction following.

#### Reranking

- **Trilha A:** reranker cloud de referência para multilíngue. *Justificativa:* melhor desempenho documentado em benchmarks multilíngues. Integração trivial e custo proporcional ao uso.
- **Trilha B:** reranker open-source da mesma família do modelo de embedding. *Justificativa:* sinergia com o modelo de embedding (mesmo tokenizador, mesma GPU pode servir ambos). Único reranker open-source com qualidade competitiva em multilíngue que roda em GPU consumer.

**Nota sobre o LLM nas Fases 2 e 3:** O LLM não é usado apenas na Fase 4. Ele também é usado na mineração de `.beta.md` (Fase 2) e na geração do `.md` final (Fase 3). A regra de roteamento por `confidentiality` se aplica **desde** a Fase 2: um documento `restricted`/`confidential` **deve** usar LLM local mesmo na mineração.

### 3.3. Trilha híbrida — o cenário mais comum

Na prática, a maioria das organizações usará a **Trilha Híbrida**:

- Documentos `public` e `internal` → processados pela Trilha A (Cloud)
- Documentos `restricted` e `confidential` → processados pela Trilha B

Isso significa que a organização opera **duas instâncias paralelas** da base vetorial, com modelos de embedding diferentes e incompatíveis.

**Incompatibilidade de embeddings:** Os vetores gerados pelos modelos cloud e on-premise **não** são compatíveis (dimensões diferentes). Um chunk indexado com modelo cloud só pode ser buscado com embedding de query gerado pelo mesmo modelo. Isso reforça a separação em duas instâncias.

**Busca cross-instância:** Para busca que precisa de resultados de ambas as instâncias, o retriever executa a busca em **paralelo** nas duas instâncias e faz merge dos resultados antes do reranking. Isso só é permitido quando o usuário tem acesso a ambos os níveis de confidencialidade.

**Regra:** quando resultados de ambas as instâncias são mesclados, o reranking e a geração de resposta **devem** usar componentes on-premise, pois chunks `restricted`/`confidential` estão presentes. O **componente mais restritivo** determina a trilha.

**Nota:** o reranker on-premise é um cross-encoder que opera sobre **texto** (não sobre embeddings), portanto funciona corretamente independentemente de qual modelo gerou os embeddings originais.

### 3.4. Matriz de decisão

**Pergunta 1:** A organização possui **algum** documento `restricted` ou `confidential`?
- **Não** → Use Trilha A (Cloud) para tudo. Fim.
- **Sim** → Continue.

**Pergunta 2:** **Todos** os documentos são `restricted` ou `confidential`?
- **Sim** → Use Trilha B (On-Premise) para tudo. Fim.
- **Não** → Continue.

**Pergunta 3:** A organização aceita operar duas instâncias simultaneamente?
- **Sim** → Use Trilha Híbrida (A + B). Fim.
- **Não** → Use Trilha B para tudo (mais seguro, sacrifica qualidade para dados não-restritos). Fim.

## 4. Alternativas descartadas

### 4.1. Trilha única cloud

Usar somente componentes cloud para todos os níveis de confidencialidade, confiando nos termos de uso e contratos dos provedores.

**Por que descartada:** insuficiente para ambientes regulados. Termos de uso de API **não** substituem requisitos regulatórios (BACEN, CVM). Mesmo com contrato enterprise, o dado trafega por infraestrutura de terceiro. Auditorias externas frequentemente questionam a localização física dos dados — e a resposta precisa ser "na nossa infraestrutura".

### 4.2. Trilha única on-premise

Usar somente componentes on-premise para todos os níveis, mesmo para dados públicos.

**Por que descartada:** desperdiça recursos e qualidade. Para dados `public`/`internal`, a qualidade dos modelos cloud é superior e o custo é menor. Forçar Trilha B para dados que não precisam de soberania é over-engineering. Além disso, nem toda organização tem GPUs — a Trilha A permite começar sem investimento em hardware.

### 4.3. Encryption-at-rest + cloud

Enviar dados criptografados para cloud, descriptografar apenas no momento do processamento.

**Por que descartada:** tecnicamente inviável para embeddings. O modelo precisa do **texto claro** para gerar o vetor. Não há como gerar embedding de texto criptografado e obter resultados semanticamente úteis. Técnicas de "homomorphic encryption" para busca vetorial existem em pesquisa acadêmica, mas não estão em produção (latência 1000x+ maior, precisão degradada).

### 4.4. Provedor cloud com região dedicada

Contratar região dedicada (ex: GovCloud) com garantia de isolamento físico e compliance.

**Por que descartada:** custo proibitivo (10-50x mais caro que região padrão). Disponível apenas para contratos governamentais específicos. Não resolve o problema fundamental: o dado ainda está na infraestrutura de um terceiro, mesmo que fisicamente isolado.

### 4.5. Modelos de embedding menores on-premise

Usar modelos de embedding menores (<1B parâmetros) para reduzir requisito de GPU.

**Por que descartada:** qualidade insuficiente para português. Modelos pequenos têm desempenho significativamente inferior em línguas não-inglesas. O modelo escolhido, apesar de maior, roda em GPU consumer (8GB VRAM) e oferece qualidade multilíngue competitiva. A economia de GPU não compensa a perda de qualidade.

### 4.6. LLM local pequeno (7B-13B) para todas as tarefas

Usar modelos de 7-13B parâmetros no lugar dos 70B+, reduzindo drasticamente o requisito de GPU.

**Por que descartada:** modelos de 7-13B falham consistentemente em três tarefas críticas do pipeline:
- (a) Geração de `.beta.md` com front matter estruturado (Fase 2)
- (b) Respeito a blocos LOCKED (Fase 2)
- (c) Respostas com citação de fontes (Fase 4)

## 5. Consequências

### 5.1. Positivas

**(a) Compliance garantido:** organizações reguladas podem adotar o RAG sem violar políticas de segurança, porque a Trilha B garante que dados restritos nunca saem da infraestrutura própria.

**(b) Flexibilidade de adoção:** organizações sem restrição podem começar pela Trilha A (zero hardware) e migrar para Trilha B conforme necessidade. O pipeline é o mesmo — só mudam os componentes.

**(c) Decisão automática:** o campo `confidentiality` no front matter determina automaticamente a trilha. Não há decisão humana no momento da ingestão — o pipeline lê o metadado e roteia.

**(d) Custo otimizado:** dados que podem ir para cloud usam cloud (melhor qualidade, menor custo operacional). Dados que precisam ficar locais usam local. Não há desperdício.

**(e) Evolução independente:** cada trilha pode evoluir separadamente. Se surgir um embedding cloud melhor, troca-se na Trilha A sem impactar a Trilha B. E vice-versa.

**(f) Alinhamento com [[ADR-001]]:** as 4 fases do pipeline funcionam identicamente em ambas as trilhas. A soberania é uma preocupação de **infraestrutura**, não de **processo**.

### 5.2. Negativas / Trade-offs

**(a) Complexidade operacional:** manter duas instâncias da base vetorial, dois conjuntos de modelos e dois fluxos de serving aumenta a complexidade operacional significativamente.

**(b) Inconsistência de qualidade:** a Trilha A (cloud) terá qualidade ligeiramente superior à Trilha B (on-premise) em embeddings, reranking e respostas do LLM.

**(c) Busca cross-instância:** a busca que cruza dados das duas instâncias é mais complexa (merge de resultados de embeddings incompatíveis) e mais lenta.

**(d) Custo de hardware:** a Trilha B exige investimento inicial em GPUs que pode ser barreira para organizações menores (ver DOC-D03).

**(e) Competência da equipe:** a Trilha B exige equipe capaz de operar modelos de ML em produção (GPU drivers, CUDA, model serving, monitoramento de inferência).

### 5.3. Riscos e mitigações

**Risco 1: Classificação incorreta de confidencialidade**
- Probabilidade: **Média** | Impacto: **Alto**
- Documento `confidential` classificado como `internal` por erro humano, sendo enviado para componentes cloud.
- *Mitigação:* validação automática no pipeline de promoção (Fase 3). Regras por domínio e tags bloqueiam promoção se nível estiver abaixo do mínimo esperado.

**Risco 2: Degradação de qualidade na Trilha B**
- Probabilidade: **Baixa** | Impacto: **Médio**
- Modelos open-source evoluem mais devagar que proprietários.
- *Mitigação:* monitorar benchmarks trimestralmente. Pipeline é agnóstico ao modelo — basta trocar o endpoint.

**Risco 3: Indisponibilidade da Trilha A**
- Probabilidade: **Baixa** | Impacto: **Médio**
- API de provedores cloud fora do ar impede buscas em dados não-restritos.
- *Mitigação:* implementar fallback local para a Trilha A (somente viável se a organização já possui infraestrutura da Trilha B).

**Risco 4: Custo cloud escalando**
- Probabilidade: **Média** | Impacto: **Baixo**
- Aumento de uso faz o custo cloud escalar além do orçamento.
- *Mitigação:* monitorar custo mensal. Se ultrapassar threshold, migrar dados `internal` para Trilha B, mantendo apenas `public` na Trilha A.

**Risco 5: Vendor lock-in**
- Probabilidade: **Média** | Impacto: **Médio**
- Dependência de provedores cloud pode ser problemática se mudarem preços, termos ou descontinuarem modelos.
- *Mitigação:* arquitetura usa abstrações (interfaces de embedding, LLM e reranking). Trocar provedor **não** exige mudar o pipeline, apenas o adaptador. Re-indexação é automatizada.

## 6. Implementação (alto nível)

A implementação segue 4 fases progressivas:

**Fase 1 — MVP (Trilha A apenas, dados public/internal)**
Configurar base vetorial managed, integrar APIs cloud de embedding e LLM, ingerir documentos `public`/`internal`. Sem reranking nesta fase.
*DOD:* busca vetorial retorna resultados corretos; LLM gera respostas com citação de fonte.

**Fase 2 — Reranking + Qualidade (Trilha A)**
Adicionar reranker cloud. Medir melhoria de precisão (precision@10, MRR). Ajustar parâmetros (top-K retrieval, top-N reranking).
*DOD:* precision@10 melhora >= 15% com reranking.

**Fase 3 — Trilha B (dados restricted/confidential)**
Provisionar hardware, instalar base vetorial self-hosted, configurar modelos de embedding, LLM e reranking locais. Ingerir documentos `restricted`/`confidential`.
*DOD:* nenhum dado `restricted`/`confidential` trafega por rede externa; latência < 2s end-to-end. Ver RNB-D04 para checklist completo.

**Fase 4 — Trilha Híbrida (busca cross-instância)**
Implementar retriever multi-instância, merge de resultados e controle de acesso por usuário.
*DOD:* busca cross-instância retorna resultados mesclados corretamente; controle de acesso impede usuário sem permissão de ver dados `restricted`.

Detalhamento de hardware, capacity planning e custos: ver DOC-D03.
Checklists de validação por trilha: ver RNB-D04.
Métricas de observabilidade por trilha: ver SPEC-D02.

## 7. Referências

### Decisões relacionadas

- [[ADR-001|ADR-001 — Pipeline de Geração de Conhecimento em 4 Fases]] (define o pipeline que esta ADR complementa com escolhas de infra)
- [[ADR-003|ADR-003 — Modelo de Dados da Base Vetorial]] (define os nós e relações armazenados na infra escolhida aqui)

### Documentos do blueprint

- B14 — Segurança e Soberania de Dados
- B03 — Camada Ouro (pipeline de ingestão na base vetorial)
- B07 — Visão Consolidada

### Documentos extraídos desta ADR

- **SPEC-D01:** Catálogo de Componentes por Trilha
- **SPEC-D02:** Métricas de Observabilidade
- **DOC-D03:** Capacity Planning Infraestrutura
- **RNB-D04:** Checklist de Deploy por Trilha
- **GLS-A05:** Glossário de Termos de Infraestrutura

### Referências externas

- LGPD (Lei 13.709/2018): http://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm

<!-- conversion_quality: 97 -->
