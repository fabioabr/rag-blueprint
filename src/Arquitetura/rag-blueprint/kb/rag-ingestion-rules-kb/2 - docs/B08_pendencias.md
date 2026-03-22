---
id: RAG-B08
doc_type: architecture-doc
title: "Pendências — Recomendações e Alternativas"
system: RAG Corporativo
module: Pendências
domain: Arquitetura
owner: fabio
team: arquitetura
status: in-review
confidentiality: internal
tags: [rag, blueprint, pendencias, decisoes, embedding, infra, stack]
aliases: ["Pendências", "Decisões Pendentes", "B08"]
source_format: txt
source_repo: banco-patria
source_path: Arquitetura/rag-blueprint/1 - draft/B08_pendencias.txt
conversion_pipeline: manual-v1
conversion_quality: 100
converted_at: 2026-03-18
created_at: 2026-03-18
updated_at: 2026-03-18
---

# Pendências — Recomendações e Alternativas

| | |
|---|---|
| **Série** | RAG Blueprint Series |
| **Documento** | B8 — Pendências |
| **Data** | 17/03/2026 |
| **Versão** | 1.1 |

## Nota sobre Soberania de Dados

> [!danger] Soberania de Dados — Premissa Transversal
> Muitas organizações **NÃO PODEM** enviar sua base de conhecimento para serviços externos (APIs cloud de embedding, LLMs cloud, vector DBs managed). Motivos comuns:
> - Política de segurança da informação
> - Regulação setorial (BACEN, CVM, LGPD)
> - Cláusulas contratuais de confidencialidade
> - Risco reputacional
>
> Cada pendência abaixo considera esse cenário e oferece alternativas on-premise/self-hosted. Detalhes em [[B14_seguranca_soberania_dados]].

#pendencia/soberania #fase/1

---

## ✅ Pendência 1 — Modelo de Embedding

O modelo de embedding transforma texto em vetores numéricos. É ele que permite a busca semântica — sem ele, não há RAG. A escolha desse modelo define o teto de qualidade de toda a busca.

> **✅ RECOMENDAÇÃO: duas trilhas conforme política de dados**
>
> **TRILHA A — Dados podem sair do domínio:**
> OpenAI text-embedding-3-small (1536 dimensões)
>
> **TRILHA B — Dados NÃO podem sair do domínio:**
> BGE-M3 (BAAI) ou multilingual-e5-large-instruct
> Rodando local via sentence-transformers ou Ollama

### Por que a Trilha A (OpenAI text-embedding-3-small)

- 🔸 Melhor custo-benefício do mercado: US$ 0,02 por 1M tokens — 10.000 chunks de 500 tokens = ~US$ 0,10 para embeddar tudo
- 🔸 1536 dimensões — equilíbrio entre qualidade e tamanho do índice
- 🔸 Multilíngue nativo (pt-BR funciona bem)
- 🔸 API estável, latência baixa, sem infra para manter
- 🔸 Se precisar mais qualidade: upgrade para text-embedding-3-large (3072 dims) sem mudar a arquitetura

### Por que a Trilha B (BGE-M3 local)

- 🔸 Dados nunca saem do domínio — compliance total
- 🔸 Sem custo por chamada — paga apenas infra (CPU/GPU)
- 🔸 BGE-M3 é o melhor modelo open-source multilíngue atual
- 🔸 Suporta 3 modos: dense, sparse e colbert
- 🔸 Roda em GPU modesta (8GB VRAM) ou CPU (mais lento)
- 🔸 Alternativa sem GPU: multilingual-e5-large-instruct (CPU ok)

### Alternativas descartadas e por que

- ❌ **OpenAI text-embedding-3-large (3072 dims)** — Qualidade superior, mas dobra o tamanho do índice vetorial e o custo. Overkill para documentação corporativa. Manter como upgrade futuro se qualidade da busca não satisfizer.
- ❌ **Cohere embed-v3 / Voyage AI** — Qualidade excelente, mas lock-in em providers menores. OpenAI tem base instalada maior e mais previsibilidade de preço. Considerar apenas se OpenAI for vetado por política interna.
- ❌ **sentence-transformers/all-MiniLM-L6-v2** — Muito popular, mas fraco em português. Modelos monolíngues ingleses perdem qualidade significativa em pt-BR. Descartar para nosso caso.
- ❌ **Ollama + nomic-embed-text** — Fácil de rodar mas qualidade inferior ao BGE-M3 em benchmarks multilíngues. Ollama é ótimo para LLMs, não ideal para embeddings. Descartar.

### Impacto

- Define dimensão do vector index no Neo4j (1536 ou 1024) — ver [[B03_camada_ouro]]
- Define se precisamos de GPU na infra — ver [[B11_deployment_infraestrutura]]
- Re-embedding necessário se modelo mudar no futuro (por isso começar com modelo bom desde o início é importante)

> [!warning] Prazo
> Antes de iniciar Fase 1 — bloqueante para [[B03_camada_ouro]] e [[B12_testes_validacao_slas]]

#pendencia/fase1 #camada/ouro

---

## ✅ Pendência 2 — Backend de Indexação

O backend armazena os dados e executa as buscas. É a fundação técnica de todo o RAG.

> **✅ RECOMENDAÇÃO: Neo4j como backend único**
> (grafo + vetor + metadados em um só lugar)

### Por que Neo4j único

- 🔸 Simplicidade operacional — 1 banco para manter, monitorar, backupear
- 🔸 Busca vetorial + expansão por grafo na MESMA query Cypher — não precisa orquestrar chamadas entre sistemas
- 🔸 Neo4j suporta vector indexes nativamente desde v5.11+
- 🔸 Nosso volume projetado (dezenas de milhares de chunks) está confortavelmente dentro da capacidade do Neo4j
- 🔸 Filtros pré-retrieval por metadados nativos (WHERE clauses)
- 🔸 neo4j-graphrag-python (lib oficial) já abstrai tudo isso

### Para quando reconsiderar

- 🔸 Se ultrapassar ~500.000 chunks — avaliar performance vetorial
- 🔸 Se latência de busca vetorial ultrapassar 200ms no p99
- 🔸 Se precisar de busca vetorial distribuída (multi-região)

### Alternativa mantida (não escolhida)

⏸️ **Multi-backend: Neo4j (grafo) + Qdrant (vetor)**

- ✅ Qdrant é o melhor vector DB open-source em benchmarks
- ✅ Escalabilidade vetorial independente
- ✅ Qdrant roda self-hosted (soberania de dados ok)
- ❌ 2 backends para manter sincronizados
- ❌ Queries cross-system complexas
- ❌ Complexidade operacional dobra
- ❌ Para nosso volume, o ganho não justifica a complexidade
- Guardar como plano de contingência para escala futura

### Alternativa descartada

- ❌ **Pinecone / WeaviatéCloud** — Cloud-only ou cloud-first. Dados saem do domínio. Para organizações com restrição de soberania: inviável. Descartar.

> [!warning] Prazo
> Antes de iniciar Fase 1 — bloqueante para [[B05_knowledge_graph]] e [[B10_api_interface_acesso]]

#pendencia/fase1

---

## ✅ Pendência 3 — Infraestrutura Neo4j

> **✅ RECOMENDAÇÃO: duas trilhas conforme política de dados**
>
> **TRILHA A — Cloud permitido:**
> Neo4j Aura Professional (cloud managed)
>
> **TRILHA B — Tudo on-premise:**
> Neo4j Community Edition self-hosted via Docker
> (upgrade para Enterprise se RBAC nativo for necessário)

### Por que a Trilha A (Aura Professional)

- 🔸 Zero operação — Neo4j cuida de backup, updates, scaling
- 🔸 Vector indexes suportados nativamente
- 🔸 Custo previsível (~US$ 65/mês no plano menor)
- 🔸 Free tier disponível para POC (limitado mas suficiente para MVP)
- 🔸 Time foca no pipeline e não em infra

### Por que a Trilha B (Community self-hosted)

- 🔸 Dados nunca saem da infra da organização
- 🔸 Custo zero de licença (Community é gratuita)
- 🔸 Docker compose para subir rápido
- 🔸 Controle total sobre configuração de memória e disco
- 🔸 Community suporta vector indexes (desde Neo4j 5.11+)
- ⚠️ Community NÃO tem RBAC nativo — controle de acesso implementado na camada de aplicação (aceitável atéFase 3)
- ⚠️ Precisamos manter: backups, updates, monitoramento

### Sizing inicial (ambas as trilhas)

- 🔸 RAM: 4-8 GB (suficiente para ~50.000 chunks com vetor 1536d)
- 🔸 Disco: 20 GB SSD
- 🔸 CPU: 2-4 cores
- 🔸 Crescimento esperado: ~1 GB de index a cada 30.000 chunks

### Alternativa descartada

- ❌ **Neo4j Enterprise self-hosted** — RBAC nativo, clustering, backup quente. Mas custa ~US$ 36.000/ano. Injustificável para fase inicial. Reavaliar se RBAC nativo for requisito forte.

> [!warning] Prazo
> Antes de iniciar Fase 1 — bloqueante para [[B11_deployment_infraestrutura]]

#pendencia/fase1

---

## ✅ Pendência 4 — Linguagem e Stack do Pipeline

Precisamos definir a linguagem/stack para duas camadas distintas:

- 🔹 **Pipeline de ingestão** — parsear .md, gerar embeddings, persistir no Neo4j
- 🔹 **Camada de consumo** — API, agentes, MCP, interface com usuários/sistemas

> Nota: essas camadas NÃO precisam usar a mesma linguagem. É válido, por exemplo, ter o pipeline em Python e a API em .NET, ou vice-versa. Ferramentas específicas de curadoria (parsers, embeddings, Neo4j) podem ser escolhidas independentemente da linguagem principal.

> **⚠️ DECISÃO PENDENTE: escolher linguagem(ns) para pipeline e camada de consumo dentre as opções abaixo**

### Opção A: Python

**✅ Pros:**

- 🔸 Ecossistema de IA/ML mais maduro que existe
- 🔸 neo4j-graphrag-python — biblioteca oficial da Neo4j para GraphRAG — Pipeline de ingestão, embeddings, retrieval integrados
- 🔸 sentence-transformers, tiktoken, frontmatter — tudo disponível
- 🔸 Comunidade massiva — qualquer dúvida tem resposta rápida
- 🔸 Perfil de profissional abundante no mercado
- 🔸 Prototipagem rápida, notebooks para experimentação

**❌ Contras:**

- 🔸 Performance inferior a linguagens compiladas para APIs de alto throughput
- 🔸 Tipagem dinâmica pode gerar bugs sutis em projetos maiores
- 🔸 GIL limita paralelismo real em CPU-bound (mitigável com async/multiprocess)
- 🔸 Pode não ser a linguagem dominante no time corporativo

**📦 Bibliotecas-chave:**

- 🔸 neo4j-graphrag-python (ingestão + retrieval)
- 🔸 sentence-transformers (embeddings locais)
- 🔸 FastAPI / Flask (camada de API)
- 🔸 python-frontmatter (parser de YAML front matter)

### Opção B: .NET Core + C\#

**✅ Pros:**

- 🔸 Ecossistema enterprise consolidado — familiar em ambientes corporativos
- 🔸 Neo4j .NET Driver oficial — suporte completo a Cypher e vector indexes
- 🔸 Tipagem forte e ferramentas de refactoring maduras
- 🔸 ASP.NET Core — framework robusto para APIs de produção
- 🔸 Performance superior a Python para APIs de alto throughput
- 🔸 Semantic Kernel (Microsoft) — framework de orquestração de agentes IA
- 🔸 Se o time corporativo já usa .NET, reduz curva de aprendizado

**❌ Contras:**

- 🔸 Ecossistema de IA/ML menos maduro que Python
- 🔸 Não existe equivalente ao neo4j-graphrag-python — pipeline de ingestão GraphRAG precisaria ser construído manualmente
- 🔸 Menos bibliotecas prontas para embeddings locais
- 🔸 Comunidade de RAG/IA menor (menos exemplos, tutoriais, respostas)
- 🔸 Prototipagem mais lenta que Python para experimentação rápida

**📦 Bibliotecas-chave:**

- 🔸 Neo4j.Driver (driver oficial .NET)
- 🔸 Semantic Kernel (orquestração de agentes)
- 🔸 ML.NET / ONNX Runtime (inferência de modelos)
- 🔸 ASP.NET Core (camada de API)

### Opção C: Node.js / TypeScript

**✅ Pros:**

- 🔸 Async nativo — excelente para I/O-bound (chamadas a APIs, Neo4j, embeddings)
- 🔸 Prototipagem rápida, ecossistema npm vasto
- 🔸 Neo4j JavaScript Driver oficial — suporte completo
- 🔸 TypeScript oferece tipagem forte com flexibilidade
- 🔸 Natural para camada de API e integrações web
- 🔸 LangChain.js e Vercel AI SDK disponíveis para orquestração

**❌ Contras:**

- 🔸 Ecossistema de RAG em JS ainda atrás de Python em maturidade
- 🔸 Não existe equivalente ao neo4j-graphrag-python em JS
- 🔸 Menos bibliotecas de ML/embeddings locais
- 🔸 Menos exemplos e tutoriais específicos de GraphRAG
- 🔸 Para processamento pesado de embeddings locais, não é ideal

**📦 Bibliotecas-chave:**

- 🔸 neo4j-driver (driver oficial JS)
- 🔸 LangChain.js / Vercel AI SDK (orquestração)
- 🔸 Express / Fastify / NestJS (camada de API)
- 🔸 gray-matter (parser de YAML front matter)

### Abordagem Híbrida (mix de stacks)

Componentes diferentes podem usar stacks diferentes. Exemplos:

- 🔸 Pipeline de ingestão em Python (melhor ecossistema de ML) + API/agentes em .NET (alinhado com stack corporativo)
- 🔸 Pipeline em Python + MCP server em Node.js/TypeScript
- 🔸 Pipeline em Python + API em qualquer linguagem consumindo Neo4j

A única restrição real é que o Neo4j é acessível via driver oficial em todas essas linguagens — a escolha de stack não cria lock-in no banco.

### Nota sobre Frameworks de Orquestração

Independente da linguagem, evitar "frameworkitis":

- 🔸 **LangChain (Python/JS):** popular, mas abstração excessiva e breaking changes frequentes — usar com cautela
- 🔸 **LlamaIndex:** bom para RAG genérico, mas sem integração profunda com Neo4j como grafo + vetor
- 🔸 **Semantic Kernel (.NET):** mais estável, mas menos focado em RAG
- 🔸 **neo4j-graphrag-python:** foco cirúrgico em GraphRAG, oficial Neo4j — se escolher Python, é a melhor opção para o pipeline

**Recomendação:** preferir bibliotecas focadas e drivers oficiais ao invés de mega-frameworks. Menos "magia", mais controle.

> [!danger] Decisão Pendente — Prazo: antes de iniciar Fase 1
> Esta é a única pendência sem recomendação fechada. Bloqueante para [[B10_api_interface_acesso]], [[B11_deployment_infraestrutura]] e [[B02_camada_prata]].

#pendencia/fase1

---

## ✅ Pendência 5 — Repositórios Alvo

> **✅ RECOMENDAÇÃO: começar pelo repositório "Banco xpto"**
> (este próprio repositório de arquitetura)

### Por que

- 🔸 Já possui documentos .md com conteúdo real (blueprints, ADRs)
- 🔸 Estamos ativamente criando front matter padronizado aqui
- 🔸 Volume controlado — ideal para validar pipeline sem surpresas
- 🔸 Feedback imédiato — nós mesmos somos os usuários do RAG
- 🔸 Erros são seguros — não impactam operação

### Ações necessárias

- 🔸 Mapear todos os .md do repositório
- 🔸 Garantir front matter YAML em cada um
- 🔸 Definir branch monitorada (provavelmente main)
- 🔸 Estimar volume de chunks esperado

### Expansão futura

- 🔸 Identificar 2-3 repositórios corporativos com documentação .md
- 🔸 Priorizar repos com mais conteúdo técnico útil
- 🔸 Branch: monitorar apenas main (evitar ruído de branches WIP)

### Decisões pendentes

- 🔸 Quais outros repositórios existem com .md relevantes?
- 🔸 Os .md existentes têm front matter ou precisam de preparação?

> [!warning] Prazo
> Antes de iniciar Fase 1 — bloqueante para [[B01_camada_bronze]] (ingestão depende de repos definidos)

#pendencia/fase1

---

## ✅ Pendência 6 — LLM para Geração de Respostas

> **✅ RECOMENDAÇÃO: duas trilhas conforme política de dados**
>
> **TRILHA A — Cloud permitido:**
> Claude (Anthropic) via API
>
> **TRILHA B — Tudo on-premise:**
> Llama 3.1 70B ou Qwen 2.5 72B via Ollama/vLLM

### Por que essa escolha NÃO bloqueia nada

- 🔸 O LLM é consumidor do RAG, não parte do pipeline de ingestão
- 🔸 O pipeline funciona sem LLM — retorna chunks diretamente
- 🔸 O LLM pode ser trocado a qualquer momento sem reprocessar

### Por que Trilha A (Claude)

- 🔸 Melhor modelo para instruções complexas e contextual prompting
- 🔸 Janela de contexto grande (200K tokens) — cabe muitos chunks
- 🔸 Excelente em português brasileiro
- 🔸 API estável, boa documentação
- 🔸 Custo razoável (Haiku para queries simples, Sonnet para complexas)

### Por que Trilha B (Llama/Qwen local)

- 🔸 Dados e prompts nunca saem do domínio
- 🔸 Sem custo por token — paga apenas GPU
- 🔸 Llama 3.1 70B: melhor open-source generalista
- 🔸 Qwen 2.5 72B: alternativa forte, especialmente em tarefas técnicas
- ⚠️ Exige GPU potente (A100 80GB ou 2x A10G para 70B quantizado)
- ⚠️ Qualidade inferior aos modelos cloud de fronteira

### Alternativas descartadas

- ❌ **GPT-4 (OpenAI)** — Excelente qualidade, mas política de dados da OpenAI é menos transparente que a da Anthropic. Preço mais alto. Considerar apenas se Claude não for opção.
- ❌ **Modelos pequenos locais (7B, 13B)** — Qualidade insuficiente para geração de respostas confiáveis com contexto corporativo. Alucinam mais. Descartar para geração. Podem servir para tarefas auxiliares (classificação, extração de entidades).

> [!info] Prazo
> Não é bloqueante para Fase 1 — pode ser decidido durante [[B06_graphrag_maturidade|Fase 4]]

#pendencia/fase2

---

## ✅ Pendência 7 — Fontes Prioritárias para Expansão

> **✅ RECOMENDAÇÃO: priorizar pela matriz valor x fácilidade**

### Ordem sugerida de expansão

🥇 **Prioridade 1 — PDFs de documentação técnica**

- Valor: alto (conhecimento formal curado)
- Facilidade: média (parser existente — Unstructured.io / Apache Tika)
- Volume: baixo-médio
- Muita documentação corporativa vive em PDF. Alto valor, risco baixo.

🥈 **Prioridade 2 — Tickets resolvidos (ClickUp, Jira)**

- Valor: alto (base de conhecimento natural)
- Facilidade: média (APIs disponíveis)
- Volume: médio-alto
- Tickets com resolução documentada são ouro para suporte.

🥉 **Prioridade 3 — Documentação de APIs (Swagger/OpenAPI)**

- Valor: alto para times técnicos
- Facilidade: fácil (formato padronizado, JSON/YAML)
- Volume: baixo
- Formato já estruturado, ingestão quase direta.

⏸️ **Prioridade 4+ (avaliar depois):**

- 🔸 Políticas internas (Word/PDF) — valor médio, cuidado com versionamento
- 🔸 E-mails — valor alto mas complexidade enorme (ruído, LGPD)
- 🔸 Slack — valor médio, muito ruído, requer curadoria pesada

### Decisões pendentes

- 🔸 Mapear quais dessas fontes existem
- 🔸 Avaliar volume real de cada uma
- 🔸 Validar sensibilidade com compliance

---

## ✅ Pendência 8 — Modelo de Reranking

> **✅ RECOMENDAÇÃO: duas trilhas conforme política de dados**
>
> **TRILHA A — Cloud permitido:**
> Cohere Rerank v3
>
> **TRILHA B — Tudo on-premise:**
> BGE-Reranker-v2-m3 (BAAI) via sentence-transformers

### O que é reranking

Após a busca retornar ~50 chunks candidatos, o reranker reordena esses resultados para colocar os mais relevantes no topo. É a "segunda opinião" que melhora a precisão do retrieval.

### Por que Trilha A (Cohere Rerank)

- 🔸 Melhor reranker do mercado em benchmarks (BEIR, MTEB)
- 🔸 API simples — envia query + chunks, recebe scores
- 🔸 Custo baixo: US$ 2 por 1.000 buscas
- 🔸 Multilíngue

### Por que Trilha B (BGE-Reranker-v2-m3)

- 🔸 Melhor reranker open-source
- 🔸 Roda local, dados não saem do domínio
- 🔸 Compatível com sentence-transformers (Python)
- 🔸 Pode rodar em CPU (mais lento) ou GPU (rápido)

### Alternativas descartadas

- ❌ **LLM como reranker (usar o Claude/GPT para reordenar)** — Funciona, mas latência alta (precisa processar todos os chunks pelo LLM) e custo por busca sobe muito. Descartar para produção. Útil para experimentação.
- ❌ **Scoring customizado por regras** — Sem modelo de ML — apenas regras manuais (boost por doc_type, recência, etc.). Simples mas limitado. Usar como complemento ao reranker, não como substituto.

---

## ✅ Pendência 9 — Taxonomia Corporativa

> **✅ RECOMENDAÇÃO: adotar a taxonomia proposta com 1 ajuste**
> Adicionar categoria "Financeiro" separada de "Comercial"

### Taxonomia recomendada

- 🔹 **Estratégico** — visão, objetivos, planejamento, OKRs
- 🔹 **Operacional** — processos, playbooks, procedimentos, runbooks
- 🔹 **Técnico** — arquitetura, sistemas, código, ADRs, APIs
- 🔹 **Financeiro** — produtos financeiros, regulação BACEN, contabilidade
- 🔹 **Comercial** — clientes, produtos, contratos, comercialização
- 🔹 **Regulatório** — compliance, LGPD, auditoria, políticas internas

### Por que separar Financeiro de Comercial

- 🔸 Instituição financeira — o domínio financeiro é core e tem volume/complexidade próprios
- 🔸 Regulação BACEN, produtos de investimento, operações de crédito não se misturam com "clientes e contratos" genéricos

### Por que não inventar uma taxonomia diferente

- 🔸 As 5 categorias originais já cobrem 90% dos cenários corporativos
- 🔸 Taxonomia complexa demais não é adotada (P.1 — qualidade > quantidade)
- 🔸 Começar simples, expandir se necessário

---

## ✅ Pendência 10 — Landing Zone: Tecnologia

> **✅ RECOMENDAÇÃO: duas trilhas conforme infra disponível**
>
> **TRILHA A — Cloud:** AWS S3 ou Azure Blob Storage
> **TRILHA B — On-premise:** MinIO (compatível S3, self-hosted)
> **TRILHA C — MVP rápido:** file system local com estrutura de pastas

### Por que a Trilha B (MinIO) é a mais versátil

- 🔸 Compatível com API S3 — migrar para cloud depois é trivial
- 🔸 Self-hosted — dados ficam no domínio
- 🔸 Open-source, gratuito
- 🔸 Docker compose para subir em minutos
- 🔸 Já pensado para armazenamento de objetos imutáveis

### Por que a Trilha C (file system) para MVP

- 🔸 Zero infraestrutura adicional
- 🔸 Basta um diretório organizado com pastas por fonte
- 🔸 Migrar para MinIO/S3 depois é copiar arquivos

### Decisão real

- 🔸 Se já tem cloud (AWS/Azure): usar o object storage nativo
- 🔸 Se tudo on-premise: MinIO
- 🔸 Se quer zero overhead no início: file system + migrar depois

---

## ✅ Pendência 11 — Estratégia de Chunking Hierárquico

> **✅ RECOMENDAÇÃO: não implementar no início.**
> Chunking simples por heading primeiro.
> Avaliar se a qualidade justifica a complexidade depois.

### O que é chunking hierárquico

Criar 2 níveis de chunks para cada seção:

- Chunk filho (pequeno, ~200 tokens) — usado na busca vetorial
- Chunk pai (grande, ~1000 tokens) — expandido na resposta
- Busca precisa + contexto amplo.

### Por que NÃO implementar agora

- 🔸 Complexidade dobra no pipeline de chunking
- 🔸 Volume de chunks no Neo4j dobra (mais storage, mais index)
- 🔸 Documentos .md já são bem estruturados por headings — o chunking simples por seção já produz chunks coerentes
- 🔸 A expansão por grafo já resolve o problema de contexto amplo de outra forma (navegando relações)

### Quando reconsiderar

- 🔸 Se as respostas perderem contexto em docs longos
- 🔸 Se fontes não-Git (PDFs de 100 páginas) precisarem de granularidade fina na busca + contexto largo na resposta
- 🔸 Se benchmark mostrar ganho significativo de qualidade

---

## ✅ Pendência 12 — Observabilidade: Ferramentas

> **✅ RECOMENDAÇÃO: logs estruturados + relatório HTML**
> (padrão visual do projeto)

### Por que essa abordagem

- 🔸 Já temos um padrão de relatórios HTML com design system próprio
- 🔸 O pipeline Python pode gerar logs estruturados (JSON)
- 🔸 Um script pode consolidar métricas e gerar HTML de dashboard
- 🔸 Zero dependência adicional (Grafana, Prometheus, Datadog)

### Quando evoluir

- 🔸 Se o volume de ingestão crescer e precisar de alertas automáticos — considerar Grafana + Prometheus
- 🔸 Com retroalimentação e curadoria, um dashboard em tempo real faz mais sentido

### Alternativas mantidas (para futuro)

- ⏸️ **Grafana + Prometheus** — Stack clássico de observabilidade. Open-source, self-hosted. Poderoso mas exige setup e manutenção.
- ❌ **Datadog** — Excelente, mas SaaS caro e dados saem do domínio. Descartar para organizações com restrição de dados.

---

## ✅ Pendência 13 — Multi-Tenant

> **✅ RECOMENDAÇÃO: não implementar agora.**
> Preparar o modelo de dados para suportar (campo tenant_id) mas não enforçar até que o cenário se confirme.

### Por que não implementar agora

- 🔸 Organização única — não é SaaS multi-cliente
- 🔸 A separação por confidentiality (4 níveis) + RBAC já cobre o cenário de isolamento entre áreas
- 🔸 Multi-tenant adiciona complexidade em toda query

### Quando implementar

- 🔸 Se o RAG for oferecido como serviço para empresas do grupo
- 🔸 Se unidades de negócio exigirem isolamento total de dados (não apenas controle de acesso, mas invisibilidade mútua)

### Preparação (sem custo)

- 🔸 Incluir tenant_id como campo opcional no Document
- 🔸 Não usar em queries até necessário
- 🔸 Se precisar: basta adicionar `WHERE doc.tenant_id = $t` em tudo

---

## 📊 Resumo das Decisões

### Antes da Fase 1 (bloqueantes)

| # | Pendência | Decisão |
|---|-----------|---------|
| 1 | Embedding | OpenAI small (cloud) OU BGE-M3 (on-prem) |
| 2 | Backend | Neo4j único |
| 3 | Infra | Aura (cloud) OU Community Docker (on-prem) |
| 4 | Stack | Definir linguagem do pipeline e da camada de consumo |
| 5 | Repo alvo | Repositório de arquitetura |

> [!danger] Decisão Macro Necessária
> **Trilha A (cloud) ou B (on-prem)?** Essa resposta resolve as pendências 1, 3, 6 e 8 de uma vez. Sem essa definição, o Marco 1 não inicia. Ver [[B16_roadmap_implementacao]] para sequenciamento.

### Durante Fase 1-2

| # | Pendência | Decisão |
|---|-----------|---------|
| 6 | LLM | Claude (cloud) OU Llama 70B (on-prem) |
| 9 | Taxonomia | 6 categorias (+ Financeiro separado) |
| 10 | Landing zone | MinIO (on-prem) OU S3/Azure (cloud) |
| 12 | Observabilidade | Logs + relatório HTML |

### Durante Fase 3-4

| # | Pendência | Decisão |
|---|-----------|---------|
| 7 | Fontes | PDFs > Tickets > APIs (nessa ordem) |
| 8 | Reranking | Cohere (cloud) OU BGE-Reranker (on-prem) |
| 11 | Chunking hierárquico | Não agora, reavaliar depois |
| 13 | Multi-tenant | Não agora, reavaliar se necessário |

---

## Documentos relacionados

### Habilita
- [[B03_camada_ouro]] — P1 (embedding) e P2 (backend) são pré-requisitos para ingestão na camada ouro
- [[B10_api_interface_acesso]] — P4 (stack) e P6 (LLM) definem a camada de consumo
- [[B11_deployment_infraestrutura]] — P3 (infra Neo4j), P4 (stack) e P10 (landing zone) definem onde roda
- [[B14_seguranca_soberania_dados]] — P13 (multi-tenant) impacta modelo de segurança

### Relacionados
- [[B00_introducao]] — ponto de entrada da série, referência todas as pendências
- [[B01_camada_bronze]] — ingestão depende de P5 (repos alvo)
- [[B02_camada_prata]] — conversão depende de P4 (stack)
- [[B04_metadados_governanca]] — taxonomia corporativa definida em P9
- [[B05_knowledge_graph]] — grafo depende de P2 (backend Neo4j)
- [[B06_graphrag_maturidade]] — retrieval depende de P8 (reranking)
- [[B07_visao_consolidada]] — consolida as decisões deste documento
- [[B09_referencias]] — fontes externas e histórico de decisões
- [[B12_testes_validacao_slas]] — testes dependem de P1 (embedding) para golden set
- [[B13_operacoes]] — observabilidade definida em P12
- [[B15_governanca_capacidade_rollback]] — segurança e governança dependem de P13
- [[B16_roadmap_implementacao]] — sequenciamento depende de todas as decisões deste documento
