---
id: ADR-002
doc_type: adr
title: "Soberania de Dados: Trilha Cloud vs. On-Premise"
system: RAG Corporativo
module: Soberania de Dados
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-21
tags:
  - adr
  - soberania
  - cloud
  - on-premise
  - confidencialidade
  - trilha-hibrida
  - embedding
  - infraestrutura
  - bacen
  - lgpd
aliases:
  - "ADR-002"
  - "Soberania de Dados"
  - "Cloud vs On-Premise"
  - "Trilha Cloud e On-Premise"
  - "Trilha Híbrida RAG"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-kb/beta/ADR-002_soberania_dados_cloud_vs_onprem.beta.md"
source_beta_ids:
  - "BETA-002"
conversion_pipeline: promotion-pipeline-v1
conversion_quality: 100
converted_at: 2026-03-22
qa_score: 98
qa_date: 2026-03-22
qa_status: passed
created_at: 2026-03-21
updated_at: 2026-03-22
valid_from: 2026-03-21
valid_until: null
---

# ADR-002 — Soberania de Dados: Trilha Cloud vs. On-Premise

| Campo       | Valor                                                         |
|-------------|---------------------------------------------------------------|
| **Status**  | Accepted                                                      |
| **Data**    | 21/03/2026                                                    |
| **Decisor** | fabio (arquitetura)                                           |
| **Escopo**  | Escolha entre cloud e on-premise para cada componente do pipeline RAG |

**Referências cruzadas:**

- [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]]: Pipeline de Geração de Conhecimento em 4 Fases
- [[ADR-003_modelo_dados_base_vetorial|ADR-003]]: Modelo de Dados da Base Vetorial
- [[ADR-004_seguranca_classificacao_dados|ADR-004]]: Segurança e Classificação de Dados

---

## Sumário

Este ADR é a decisão macro que determina como o projeto RAG Corporativo escolhe entre serviços de nuvem e infraestrutura local (on-premise) para cada componente do pipeline. Trata-se da decisão mais cascateante do projeto: a partir dela, 4 escolhas pendentes são resolvidas de uma vez (modelo de embedding, infraestrutura da base vetorial, LLM de geração, modelo de reranking).

A premissa central é: a **classificação de confidencialidade** do documento (definida no front matter) determina qual trilha cada informação percorre. Não existe uma única resposta — existem **duas trilhas** válidas que o projeto suporta simultaneamente.

## Contexto

### O Problema da Soberania

Muitas organizações **não podem** enviar sua base de conhecimento para serviços externos. As razões são múltiplas e frequentemente cumulativas:

- **Política de segurança interna** — Empresas com política de segurança da informação que classifica documentos internos como restritos proíbem o envio de dados para APIs externas, independentemente de termos de uso do fornecedor.
- **Regulação setorial** — BACEN (sigilo bancário), CVM (informações privilegiadas), LGPD (dados pessoais), SOX (informação financeira), HIPAA (dados de saúde).
- **Cláusulas contratuais de confidencialidade** — NDAs com clientes, contratos governamentais com exigência de infraestrutura certificada e isolada.
- **Risco reputacional** — Mesmo sem violação legal, o vazamento de informação via API de terceiro gera dano reputacional.
- **Latência e disponibilidade** — Dependência de API externa significa que o RAG para de funcionar quando o serviço externo cai ou muda preços/limites.

### Por que Esta Decisão é Fundacional

O pipeline definido na [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] tem 4 fases. Nas Fases 3 e 4, o pipeline precisa de:

- **Modelo de embedding** para gerar vetores dos chunks
- **Base vetorial** para armazenar grafos + vetores + metadados
- **LLM** para geração de respostas a partir do contexto recuperado
- **Modelo de reranking** para reordenar resultados da busca híbrida

Cada um desses componentes pode ser cloud ou local. A decisão sobre soberania de dados resolve todos de uma vez, porque o critério é o mesmo: **o dado pode sair da infraestrutura controlada pela organização?**

- Se **SIM** → Trilha Cloud (mais simples, mais barata para começar)
- Se **NÃO** → Trilha On-Premise (mais complexa, mas soberana)

### Contexto Técnico Atual (Março 2026)

O ecossistema de modelos open-source atingiu maturidade suficiente para viabilizar a Trilha On-Premise com qualidade competitiva:

- **Embeddings:** BGE-M3 (BAAI) alcança 95%+ da qualidade do OpenAI em benchmarks multilíngues, rodando em GPU consumer (8GB VRAM)
- **LLMs:** Llama 3.1 70B e Qwen 2.5 72B competem com modelos proprietários em tarefas de RAG
- **Reranking:** BGE-Reranker-v2-m3 atinge resultados comparáveis ao Cohere Rerank v3 em cenários com passagens em português
- **Infraestrutura:** bases vetoriais com suporte a grafo possuem edições community com funcionalidades suficientes

### Alinhamento com os 8 Pilares da ADR-001

| Pilar | Descrição | Impacto da ADR-002 |
|-------|-----------|-------------------|
| A | Segregação de responsabilidades | Trilha A: operada por Engenharia de Dados. Trilha B: operada por Infraestrutura/Ops. Pipeline é o mesmo, mudam os adaptadores. |
| B | Desacoplamento de etapas | Ambas as trilhas usam interfaces abstratas. Trocar componente em uma trilha não impacta a outra. |
| C | Método garantidor de qualidade | Gates de qualidade (QA score >= 90%) são idênticos em ambas as trilhas. |
| D | Observabilidade e Governança | Cada trilha possui métricas próprias. Métricas de custo apenas na Trilha A. Métricas de GPU/hardware na Trilha B. |
| E | Clareza da informação | O campo `confidentiality` no front matter torna explícita a trilha de cada doc. |
| F | Versionamento | Git controla ambas as trilhas. O `embedding_model` é registrado no chunk. |
| G | Rastreabilidade de origem | Ambas as trilhas registram no chunk: `embedding_model`, `embedding_date`, trilha (A ou B), versão do modelo. |
| H | Reprodutibilidade | Trilha A: determinística. Trilha B: modelos quantizados (Q4) podem ter variação mínima — mitigado fixando seed e versão exata do modelo. |

## Decisão

O projeto RAG Corporativo suporta **duas trilhas simultâneas**, definidas pela classificação de confidencialidade do documento (front matter).

- **Trilha A (Cloud Permitido):** componentes cloud para dados `public` e `internal`.
- **Trilha B (Full On-Premise):** componentes locais para dados `restricted` e `confidential`.
- **Trilha Híbrida:** a mesma organização pode usar ambas as trilhas simultaneamente, segregando por nível de confidencialidade.

O **nível de confidencialidade do dado determina a trilha**. Não é uma escolha de preferência — é uma **obrigação**.

### Regra de Roteamento

O front matter de cada documento possui o campo `confidentiality`. Conforme [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] (seção Front Matter Leve), este campo está presente **desde o .beta.md** (Fase 2) — exceção ao princípio de "governança só no .md final" — para permitir o roteamento pela trilha correta e garantir que dados sensíveis não sejam processados por APIs cloud em nenhuma etapa do pipeline.

| Nível | Trilha Permitida | Descrição |
|-------|------------------|-----------|
| `public` | A (Cloud) | Informação pública, pode ser processada em qualquer lugar |
| `internal` | A (Cloud) | Uso interno, sem restrição legal de envio externo. Cloud permitido |
| `restricted` | B (On-Premise) | Dados com restrição regulatória ou contratual. Não pode sair |
| `confidential` | B (On-Premise) | Altamente confidencial. Somente infraestrutura isolada |

**Regra:** o pipeline de ingestão (Fase 4) **verifica** o campo `confidentiality` **antes** de escolher qual modelo de embedding usar, qual instância da base vetorial receber o dado, e qual LLM pode gerar respostas sobre ele. Essa verificação é **pré-retrieval**, nunca pós-retrieval. O dado restrito nunca chega a um componente cloud.

### Componentes por Trilha

#### Modelo de Embedding

**Trilha A (Cloud) — OpenAI text-embedding-3-small:**

- Dimensão: 1536 (padrão) ou ajustável (512, 1024, 3072)
- Custo: US$ 0,02 por 1 milhão de tokens
- Qualidade: referência de mercado em benchmarks MTEB multilíngues
- Latência: ~100ms para batch de 100 chunks (via API)
- Suporte a português: excelente

**Trilha B (On-Premise) — BGE-M3 (BAAI):**

- Dimensão: 1024 (padrão)
- Custo: hardware (GPU com 8GB+ VRAM) + energia. Sem custo por token.
- Qualidade: 95%+ da qualidade do OpenAI em benchmarks multilíngues
- Modo híbrido nativo: gera 3 tipos de representação simultaneamente — dense, sparse (lexical) e colbert
- Requisitos mínimos: 1x GPU com 8GB VRAM (RTX 3060, RTX 4060, T4)
- Requisitos recomendados: 1x GPU com 16GB+ VRAM (RTX 4070 Ti, A10G, L4)

#### Infraestrutura da Base Vetorial

**Trilha A (Cloud) — Base Vetorial Gerenciada (Managed Cloud):**

- Tipo: instância gerenciada pelo provedor (DBaaS)
- Custo: a partir de ~US$ 65/mês para instâncias básicas
- SLA: 99,9% típico
- Backup: automatizado pelo provedor

**Trilha B (On-Premise) — Base Vetorial Self-Hosted (Community Edition):**

- Tipo: instalação via Docker / Kubernetes na infraestrutura própria
- Custo: hardware (servidor com 16GB+ RAM, SSD) + operação
- Funcionalidades: grafo completo, vector index, full-text index, constraints
- Requisitos mínimos: 4 vCPU, 16GB RAM, 100GB SSD
- Requisitos recomendados: 8 vCPU, 32GB RAM, 500GB NVMe

#### LLM (Modelo de Linguagem para Geração)

O LLM é usado na Fase 2 (mineração de `.beta.md`), Fase 3 (geração do `.md` final) e Fase 4 (respostas RAG). A regra de roteamento por `confidentiality` se aplica **desde a Fase 2**.

**Trilha A (Cloud) — Claude (Anthropic):**

- Modelo recomendado: Claude Sonnet (tarefas de RAG) ou Claude Opus (mineração complexa)
- Janela de contexto: 200K tokens
- Qualidade em pt-BR: excelente
- Melhor instruction following do mercado

**Trilha B (On-Premise) — Llama 3.1 70B ou Qwen 2.5 72B:**

- **Llama 3.1 70B (Meta):** licença Llama Community License, ~85-90% da qualidade do Claude em tarefas de RAG, requer 2x GPU com 24GB VRAM para Q4
- **Qwen 2.5 72B (Alibaba):** licença Apache 2.0, qualidade comparável ao Llama com vantagem em multilíngue, requisitos similares
- Hosting: Ollama (simples) ou vLLM (produção com batching)
- Recomendação: iniciar com Llama 3.1 70B (maior ecossistema) e avaliar migração para Qwen 2.5 se desempenho em português não for satisfatório

#### Modelo de Reranking

**Trilha A (Cloud) — Cohere Rerank v3:**

- Custo: US$ 2,00 por 1.000 buscas
- Qualidade: referência de mercado para reranking multilíngue
- Latência: ~150ms para reranking de 50 candidatos

**Trilha B (On-Premise) — BGE-Reranker-v2-m3 (BAAI):**

- Qualidade: ~90-95% do Cohere Rerank v3
- Latência: ~100ms para reranking de 50 candidatos em GPU
- Sinergia com BGE-M3: mesma família de modelos, mesma GPU pode servir ambos

### Visão Consolidada — Tabela de Componentes

| Componente | Trilha A (Cloud) | Trilha B (On-Premise) |
|---|---|---|
| Embedding | OpenAI text-embedding-3-small (1536d, $0.02/1M tok) | BGE-M3 BAAI (1024d, GPU 8GB+ VRAM) |
| Base Vetorial | Managed Cloud (DBaaS, ~$65+/mês, SLA 99.9%) | Self-hosted Docker (Community Edition, 16GB+ RAM) |
| LLM | Claude Anthropic (Sonnet/Opus, 200K ctx) | Llama 3.1 70B ou Qwen 2.5 72B (2x GPU 24GB, Ollama/vLLM) |
| Reranking | Cohere Rerank v3 ($2/1K buscas) | BGE-Reranker-v2-m3 (GPU 4GB+) |

### Trilha Híbrida — O Cenário Mais Comum

Na prática, a maioria das organizações usará a **Trilha Híbrida**:

- Documentos `public` e `internal` → processados pela Trilha A (Cloud)
- Documentos `restricted` e `confidential` → processados pela Trilha B (On-Premise)

Isso significa que a organização opera **duas instâncias paralelas** da base vetorial.

**Incompatibilidade de embeddings:** os vetores gerados pela OpenAI (1536d) e pelo BGE-M3 (1024d) não são compatíveis. Um chunk indexado com OpenAI só pode ser buscado com embedding de query gerado pela OpenAI. Isso reforça a separação em duas instâncias.

**Busca cross-instância:** o retriever executa a busca em paralelo nas duas instâncias e faz merge dos resultados antes do reranking. Só é permitido quando o usuário tem acesso a ambos os níveis de confidencialidade.

**Regra:** quando resultados de ambas as instâncias são mesclados, o reranking e a geração de resposta **devem** usar componentes on-premise, pois os chunks restricted/confidential estão presentes. **O componente mais restritivo determina a trilha.**

O BGE-Reranker-v2-m3 é um cross-encoder — recebe o texto da query e o texto do chunk, não os embeddings. Portanto, funciona corretamente independentemente de qual modelo gerou os embeddings originais.

### Dimensionamento de Custos

**Cenário de referência:** empresa com 10.000 documentos, média de 5 chunks por documento (50.000 chunks total), 50 usuários, 20 buscas por usuário por dia útil (~22 dias/mês).

**Trilha A — Custo Mensal Estimado:**

| Componente | Custo | Cálculo |
|---|---|---|
| Embedding (indexação) | ~$0.50 | 25M tokens x $0.02/1M (única vez) |
| Embedding (query) | ~$2.00 | 22K queries x ~100 tok x $0.02/1M |
| Base Vetorial | ~$65.00 | Instância básica managed |
| LLM (respostas) | ~$150.00 | 22K queries x ~2K tok out x preço/tok |
| Reranking | ~$44.00 | 22K buscas x $2/1K |
| **Total mensal** | **~$261.50** | |

**Trilha B — Custo Estimado:**

| Componente | Custo | Cálculo |
|---|---|---|
| Hardware (GPU) | ~$3,000 | 2x RTX 4090 (investimento único) |
| Servidor | ~$2,000 | 64GB RAM, NVMe (investimento único) |
| Energia/mês | ~$50 | ~500W médio x 24/7 |
| Operação/mês | ~$500 | Fração de tempo de ops/infra |
| Base Vetorial | $0 | Community Edition |
| **Investimento** | **~$5,000** | Único |
| **Custo mensal** | **~$550** | Recorrente |

**Break-even:** Trilha B fica mais barata que Trilha A após ~12 meses (considerando amortização do hardware).

**Nota:** o custo da Trilha B não é a razão da escolha. A razão é **soberania**. Organizações que precisam da Trilha B não têm a opção de usar a Trilha A para dados restritos, independentemente de custo.

## Alternativas Descartadas

### Trilha Única Cloud

- **Descrição:** usar somente componentes cloud para todos os níveis de confidencialidade
- **Por que descartada:** insuficiente para ambientes regulados. Termos de uso de API não substituem requisitos regulatórios (BACEN, CVM). Auditorias externas questionam onde fisicamente estão os embeddings dos documentos confidenciais.

### Trilha Única On-Premise

- **Descrição:** usar somente componentes on-premise para todos os níveis
- **Por que descartada:** desperdiça recursos e qualidade. Para dados public/internal, a qualidade dos modelos cloud é superior e o custo é menor.

### Encryption-at-Rest + Cloud

- **Descrição:** enviar dados criptografados para cloud, descriptografar apenas no processamento
- **Por que descartada:** tecnicamente inviável para embeddings. O modelo de embedding precisa do texto claro para gerar o vetor. Técnicas de homomorphic encryption não estão em produção.

### Provedor Cloud Único com Região Dedicada

- **Descrição:** contratar região dedicada (ex: AWS GovCloud, Azure Government)
- **Por que descartada:** custo proibitivo (10-50x mais caro que região padrão). O dado ainda está na infraestrutura de um terceiro.

### Modelos de Embedding Menores On-Premise (7B, distilled)

- **Descrição:** usar modelos de embedding menores (ex: all-MiniLM-L6-v2, E5-small)
- **Por que descartada:** qualidade insuficiente para português. BGE-M3, apesar de maior, roda em GPU consumer (8GB VRAM) e oferece qualidade multilíngue competitiva.

### LLM Local Pequeno (7B-13B) para Todas as Tarefas

- **Descrição:** usar Llama 3.1 8B ou Qwen 2.5 14B no lugar dos modelos de 70B+
- **Por que descartada:** modelos de 7-13B falham em geração de `.beta.md` com front matter estruturado, respeito a blocos LOCKED, e respostas com citação de fontes. Para Fase 4 simples, um 13B pode ser fallback, mas não é recomendado como único LLM.

## Consequências

### Positivas

- **Compliance garantido:** organizações reguladas podem adotar o RAG sem violar políticas de segurança
- **Flexibilidade de adoção:** organizações sem restrição podem começar pela Trilha A (zero hardware) e migrar para Trilha B conforme necessidade
- **Decisão automática:** o campo `confidentiality` no front matter determina automaticamente a trilha
- **Custo otimizado:** dados que podem ir para cloud usam cloud; dados que precisam ficar locais usam local
- **Evolução independente:** cada trilha pode evoluir separadamente (trocar componente em uma não impacta a outra)
- **Alinhamento com [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]]:** as 4 fases do pipeline funcionam identicamente em ambas as trilhas

### Negativas / Trade-offs

- **Complexidade operacional:** manter duas instâncias da base vetorial, dois conjuntos de modelos e dois fluxos de serving
- **Inconsistência de qualidade:** Trilha A (cloud) terá qualidade ligeiramente superior à Trilha B
- **Busca cross-instância:** mais complexa (merge de embeddings incompatíveis) e mais lenta
- **Custo de hardware:** Trilha B exige investimento inicial (~$3-5K)
- **Competência da equipe:** Trilha B exige equipe capaz de operar modelos de ML em produção

### Riscos e Mitigações

- **Classificação incorreta de confidencialidade** (Probabilidade: MÉDIA, Impacto: ALTO) — documento confidential classificado como internal por erro humano. *Mitigação:* validação automática no pipeline de promoção. Documentos de domínios sensíveis (financeiro, jurídico) devem ser no mínimo `restricted`. Alerta bloqueante se a regra for violada.
- **Degradação de qualidade na Trilha B** (Probabilidade: BAIXA, Impacto: MÉDIO) — modelos open-source evoluem mais devagar. *Mitigação:* monitorar benchmarks trimestralmente. O pipeline é agnóstico ao modelo — basta trocar o endpoint.
- **Indisponibilidade da Trilha A** (Probabilidade: BAIXA, Impacto: MÉDIO) — API cloud fora do ar. *Mitigação:* implementar fallback local (só possível se a organização já possui infraestrutura da Trilha B).
- **Custo cloud escalando** (Probabilidade: MÉDIA, Impacto: BAIXO) — *Mitigação:* monitorar custo mensal. Se ultrapassar threshold, migrar dados `internal` para Trilha B.
- **Vendor lock-in** (Probabilidade: MÉDIA, Impacto: MÉDIO) — *Mitigação:* a arquitetura usa abstrações (interfaces de embedding, LLM e reranking). Trocar provedor não exige mudar o pipeline, apenas o adaptador.

## Implementação

### Matriz de Decisão — Como Escolher sua Trilha

1. A organização possui **algum** documento `restricted` ou `confidential`?
   - **NÃO** → Use Trilha A (Cloud) para tudo. Fim.
   - **SIM** → Continue.
2. **Todos** os documentos são `restricted` ou `confidential`?
   - **SIM** → Use Trilha B (On-Premise) para tudo. Fim.
   - **NÃO** → Continue.
3. A organização aceita operar **duas instâncias** da base vetorial simultaneamente?
   - **SIM** → Use Trilha Híbrida (A + B). Fim.
   - **NÃO** → Use Trilha B para tudo (mais seguro, sacrifica qualidade para dados não-restritos). Fim.
4. (Para Trilha Híbrida) A organização tem GPUs disponíveis ou orçamento para adquirir?
   - **SIM** → Implementar Trilha B com GPU. Fim.
   - **NÃO** → Iniciar com Trilha A apenas para dados public/internal. Dados restricted/confidential não são ingeridos até ter infraestrutura.

### Ordem de Implementação

| Fase | Escopo | DOD |
|------|--------|-----|
| 1 — MVP | Trilha A apenas (public/internal). Base vetorial managed, OpenAI embedding, Claude LLM. Sem reranking. | Busca vetorial retorna resultados corretos para 10 queries de teste; LLM gera respostas com citação de fonte |
| 2 — Reranking + Qualidade | Adicionar Cohere Rerank v3 na Trilha A. Medir precision@10, MRR. | precision@10 melhora >= 15% com reranking |
| 3 — Trilha B | Provisionar hardware, instalar base vetorial self-hosted, BGE-M3, Llama/Qwen via Ollama/vLLM, BGE-Reranker. | Checklist Trilha B completo; nenhum dado restricted/confidential trafega por rede externa; latência < 2s |
| 4 — Trilha Híbrida | Retriever cross-instância, merge de resultados, controle de acesso por usuário. | Busca cross-instância correta; controle de acesso funcional; reranking local com chunks de ambas as trilhas |

### Checklist de Validação por Trilha

**Trilha A:**

- [ ] API key da OpenAI configurada e testada
- [ ] API key da Anthropic (Claude) configurada e testada
- [ ] API key da Cohere configurada e testada
- [ ] Base vetorial managed provisionada e acessível
- [ ] Pipeline de ingestão filtra `confidentiality` = public/internal
- [ ] Embedding de teste gera vetor de 1536 dimensões
- [ ] Busca vetorial retorna resultados corretos
- [ ] Reranking melhora ordenação (medir precision@10)
- [ ] LLM gera respostas citando fontes

**Trilha B:**

- [ ] GPU(s) instalada(s) e CUDA funcionando
- [ ] Base vetorial self-hosted rodando via Docker
- [ ] BGE-M3 carregado e gerando embeddings de 1024 dimensões
- [ ] Llama/Qwen servido via Ollama ou vLLM
- [ ] BGE-Reranker carregado e funcionando
- [ ] Pipeline de ingestão filtra `confidentiality` = restricted/confidential
- [ ] Busca vetorial retorna resultados corretos
- [ ] Nenhum dado restricted/confidential sai da rede local (validar logs)
- [ ] Latência aceitável (<2s para busca + reranking + resposta)

### Observabilidade por Trilha (Pilar D — ADR-001)

**Métricas comuns (ambas as trilhas):**

- Latência end-to-end (query → resposta): p50, p95, p99
- Taxa de erro de ingestão (chunks rejeitados / total)
- Volume de chunks ingeridos por dia/semana
- Precisão da busca (precision@10, MRR) — amostral, via golden set
- Consistência: total de chunks na base vs. total de documentos no repo

**Métricas específicas — Trilha A (Cloud):**

- Custo acumulado por mês (embedding + LLM + reranking + base vetorial)
- Latência de API por provedor
- Taxa de rate-limiting / throttling
- Disponibilidade percebida (% de requests com sucesso)

**Métricas específicas — Trilha B (On-Premise):**

- Uso de GPU (VRAM, utilização %)
- Temperatura da GPU (alerta se > 85C)
- Uso de RAM/CPU do servidor da base vetorial
- Espaço em disco (alerta se < 20% livre)
- Throughput de inferência (tokens/segundo para LLM, chunks/segundo para embedding)

**Armazenamento:** pasta `process/metrics/` no rag-workspace (conforme estrutura da [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]]).

## Glossário

- **Trilha** — conjunto de componentes (embedding, base vetorial, LLM, reranker) que processam dados de um nível de confidencialidade
- **Soberania de dados** — princípio de que a organização mantém controle total sobre onde seus dados são armazenados e processados
- **Bi-encoder** — modelo que codifica query e documento separadamente (rápido, menos preciso). Usado para embedding.
- **Cross-encoder** — modelo que codifica query e documento juntos (lento, mais preciso). Usado para reranking.
- **VRAM** — memória da GPU dedicada ao processamento de modelos de IA
- **Quantização (Q4, AWQ)** — técnica que reduz o tamanho de modelos comprimindo pesos de 16 bits para 4 bits, com perda mínima de qualidade
- **DBaaS** — Database as a Service — banco de dados gerenciado na nuvem

## Referências

**Decisões relacionadas:**

- [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] — Pipeline de Geração de Conhecimento em 4 Fases (define o pipeline que esta ADR complementa com escolhas de infra)
- [[ADR-003_modelo_dados_base_vetorial|ADR-003]] — Modelo de Dados da Base Vetorial (define os nós e relações que serão armazenados na infra escolhida)

**Documentos do blueprint:**

- B14 — Segurança e Soberania de Dados
- B03 — Camada Ouro (pipeline de ingestão na base vetorial)
- B07 — Visão Consolidada

**Referências externas:**

- [OpenAI Embeddings](https://platform.openai.com/docs/guides/embeddings)
- [BGE-M3 (BAAI)](https://huggingface.co/BAAI/bge-m3)
- [BGE-Reranker-v2-m3](https://huggingface.co/BAAI/bge-reranker-v2-m3)
- [Cohere Rerank](https://docs.cohere.com/docs/rerank-2)
- [Ollama](https://ollama.ai)
- [vLLM](https://github.com/vllm-project/vllm)
- [LGPD (Lei 13.709/2018)](http://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm)

---

<!-- QA-MD: inicio -->
## Quality Assurance — .md final

**Revisor:** Pipeline de Promoção QA
**Data:** 22/03/2026
**Fonte:** kb/rag-blueprint-adrs-kb/beta/ADR-002_soberania_dados_cloud_vs_onprem.beta.md

| Critério | Peso | Nota | Comentário |
|----------|------|------|------------|
| Front matter rico | 25% | 96% | Todos os campos obrigatórios presentes e válidos. Campo `status: accepted` fora do enum do schema mas consistente com referência ADR-008. |
| Completude de conteúdo | 20% | 100% | Todas as seções ADR presentes: Sumário, Contexto, Decisão, Alternativas Descartadas, Consequências, Implementação, Glossário, Referências. Tabela de referência no topo. |
| Wikilinks | 10% | 100% | Formato correto [[ADR-NNN_slug\|ADR-NNN]]. Sem wikilinks no front matter. Referências cruzadas precisas. |
| Sem artefatos workspace | 15% | 100% | Sem marcadores LOCKED:START/END. Referência a "blocos LOCKED" é contextual (seção Alternativas). Sem QA-BETA. |
| Compatibilidade Obsidian | 10% | 100% | YAML válido. Tags e aliases como arrays. |
| Linhagem rastreável | 10% | 100% | source_path → .beta.md, source_beta_ids → BETA-002, conversion_pipeline → promotion-pipeline-v1. |
| Clareza e estrutura | 10% | 100% | Documento exemplar. Hierarquia clara, tabelas comparativas, checklists, dimensionamento de custos, glossário. Leitura independente possível. |

**Score:** 99.0% — APROVADO para ingestão

**Por que não é 100%:** (1) Campo `status: accepted` fora do enum oficial do schema (-1.0% sobre peso 25% = -0.25%). Impacto mínimo, sem risco funcional.
<!-- QA-MD: fim -->
