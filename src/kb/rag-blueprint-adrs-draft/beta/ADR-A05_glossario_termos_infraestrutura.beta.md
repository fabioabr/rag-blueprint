---
id: BETA-A05
title: "Glossário de Termos de Infraestrutura e Pipeline"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-A05_glossario_termos_infraestrutura.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags: [glossario infraestrutura, pipeline rag, trilha cloud, trilha on-premise, soberania de dados, base vetorial, embedding, chunking, reranking, mcp server, filtro pre-retrieval, knowledge base, segregacao fisica, confidencialidade, front matter, bloco locked, qa score, conversion quality, release tag, semver, rollback, quantizacao, vram, dbaas, bi-encoder, cross-encoder, rrf, vector index, retrieval hibrido, chunk semantico, pipeline ingestao, pipeline promocao, pipeline mineracao, trilha hibrida, hsm, jit access, curador, document family, neo4j, grafo conhecimento, lgpd, bacen, regulacao, idempotencia, busca similaridade, modelo embedding, bge-m3, cohere rerank, release-based flow, git branching, versionamento semantico, word error rate, speech-to-text]
aliases:
  - "ADR-A05"
  - "Glossario Infraestrutura Pipeline"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## 1. Sobre Este Glossário

Termos técnicos controlados utilizados no projeto RAG Corporativo. Extraídos primariamente da ADR-002 (Soberania de Dados) e complementados por definições recorrentes nas demais ADRs do projeto.

Objetivo: garantir que todos os envolvidos (POs, analistas, engenheiros, arquitetos) usem a mesma terminologia com o mesmo significado.

## 2. Termos de Infraestrutura e Soberania

### Trilha

Conjunto de componentes (embedding, base vetorial, LLM, reranker) que processam dados de um determinado nível de confidencialidade. O projeto define duas trilhas: Trilha A (Cloud) para dados public/internal e Trilha B (On-Premise) para dados restricted/confidential. A trilha é determinada pelo campo `confidentiality` no front matter do documento.

### Soberania de Dados

Princípio de que a organização mantém controle total sobre onde seus dados são armazenados e processados. Em contexto regulado (BACEN, LGPD, CVM), soberania implica que dados restritos não podem ser enviados para infraestrutura de terceiros, independentemente de termos de uso ou acordos contratuais.

### Trilha Híbrida

Configuração onde a organização opera ambas as trilhas simultaneamente: documentos public/internal pela Trilha A (Cloud) e documentos restricted/confidential pela Trilha B (On-Premise). É o cenário mais comum em organizações reguladas.

### DBaaS (Database as a Service)

Banco de dados gerenciado na nuvem. No contexto do projeto, refere-se à instância da base vetorial hospedada pelo provedor cloud (Trilha A), com backup automatizado e SLA definido.

### VRAM

Memória da GPU dedicada ao processamento de modelos de IA. Determina o tamanho máximo de modelo que pode ser carregado. Ex: GPU com 8GB VRAM comporta BGE-M3 para embeddings; 2x GPU com 24GB VRAM comporta Llama 3.1 70B quantizado.

### Quantização (Q4, AWQ)

Técnica que reduz o tamanho de modelos de IA comprimindo pesos de 16 bits para 4 bits, com perda mínima de qualidade. Permite rodar modelos grandes (70B+) em hardware consumer. Q4 = quantização de 4 bits. AWQ = Activation-aware Weight Quantization (método específico).

## 3. Termos do Pipeline

### Pipeline

Sequência automatizada de etapas que transforma dados de entrada em uma saída processada. No projeto RAG Corporativo, existem 3 pipelines principais:
1. **Pipeline de mineração** — gera `.beta.md` a partir de fontes brutas (Fase 2)
2. **Pipeline de promoção** — transforma `.beta.md` em `.md` final (Fase 3)
3. **Pipeline de ingestão** — alimenta a base vetorial a partir dos `.md` (Fase 4)

### Pipeline de Ingestão

Pipeline específico da Fase 4 que constrói/atualiza a base vetorial. Composto por 7 etapas: Descoberta, Parse, Chunking, Embeddings, Persistência, Indexação e Observabilidade. Triggered por release TAG no repositório knowledge-base. Deve ser idempotente (mesmo input = mesmo output).

### Pipeline de Promoção

Pipeline específico da Fase 3 que transforma `.beta.md` editáveis em `.md` finais imutáveis. Remove marcadores LOCKED, enriquece front matter com campos de governança, gera PR automático no repositório knowledge-base.

### Ingestão

Processo de inserir dados processados (chunks + embeddings + metadados) na base vetorial. Inclui parse de front matter, chunking, geração de embeddings e persistência no banco.

### Chunk

Fragmento semântico de um documento. Resultado do chunking (quebra de um documento em pedaços menores). Cada chunk herda metadados do documento pai, possui seu próprio embedding e é a unidade básica de busca na base vetorial. Faixa típica: 300-800 tokens.

### Chunking

Etapa do pipeline que quebra documentos em fragmentos semânticos (chunks). A estratégia de chunking varia por tipo de documento:

- **ADR:** chunks menores e precisos
- **Runbook:** chunk por procedimento/passo operacional
- **Documento arquitetural:** chunk por módulo, fluxo ou decisão
- **Glossário:** chunk quase atômico por termo
- **Documento de task:** chunk por contexto, escopo, decisão e aceite

### Embedding

Representação vetorial densa de um trecho de texto. Um array de números (ex: 1024 ou 1536 dimensões) que captura o significado semântico do texto. Permite busca por similaridade na base vetorial. Gerado por modelo de embedding (ex: OpenAI text-embedding-3-small na Trilha A, BGE-M3 na Trilha B).

### Bi-encoder

Modelo que codifica query e documento separadamente em vetores independentes. Rápido (codifica uma vez, busca muitas vezes), mas menos preciso que cross-encoder. Usado para geração de embeddings.

### Cross-encoder

Modelo que codifica query e documento juntos em uma única passagem. Lento (processa cada par query-documento), mas mais preciso que bi-encoder. Usado para reranking dos resultados da busca.

## 4. Termos da Base Vetorial

### Base Vetorial

Banco de dados especializado em armazenar e buscar vetores (embeddings). No projeto, utiliza-se banco com suporte a grafo + vetor + full-text (ex: Neo4j). Armazena chunks, embeddings, metadados e relações entre entidades.

### Knowledge Base (KB)

Base de conhecimento. No contexto do projeto, refere-se a uma instância lógica que agrupa documentos de um mesmo nível de confidencialidade. O projeto opera 3 KBs: kb-public-internal (Nível 1), kb-restricted (Nível 2) e kb-confidential (Nível 3). Cada KB possui sua própria base vetorial e MCP.

### Vector Index

Índice especializado para busca por similaridade de vetores. Permite encontrar os chunks mais semanticamente próximos de uma query. Construído sobre os embeddings armazenados na base vetorial.

### Retrieval

Processo de buscar e recuperar informações relevantes da base vetorial para responder a uma pergunta. Inclui busca vetorial (por similaridade), expansão por grafo (relações entre entidades) e reranking.

### Reranking

Etapa pós-busca que reordena os resultados usando modelo mais preciso (cross-encoder). Melhora a precisão dos top-K resultados. No projeto: Cohere Rerank v3 (Trilha A) ou BGE-Reranker-v2-m3 (Trilha B).

### Filtro Pré-Retrieval

Filtro aplicado ANTES da busca vetorial. No projeto, filtra por nível de confidencialidade, domínio e contexto temporal. Diferente de filtro pós-retrieval (que filtra resultados já retornados). É inviolável: nunca confiar apenas em prompt para segurança.

### RRF (Reciprocal Rank Fusion)

Algoritmo para fundir resultados de múltiplas fontes de busca. Combina rankings de diferentes MCPs/bases vetoriais em um único ranking unificado. Usado pelo agente orquestrador na busca cross-KB.

### MCP (Model Context Protocol)

Protocolo que define como agentes de IA acessam bases de conhecimento. No projeto, cada KB possui seu próprio MCP Server dedicado:

- **mcp-knowledge-public** (KB Nível 1)
- **mcp-knowledge-restricted** (KB Nível 2)
- **mcp-knowledge-confidential** (KB Nível 3)

## 5. Termos de Governança e Qualidade

### Front Matter

Bloco de metadados YAML no início de um arquivo Markdown, delimitado por `---`. No projeto, existem dois níveis: front matter leve (`.beta.md`, com campos essenciais) e front matter rico (`.md` final, com todos os campos de governança).

### Bloco LOCKED

Marcador HTML (`<!-- LOCKED:START -->` / `<!-- LOCKED:END -->`) que protege trechos de `.beta.md` contra sobrescrita pela IA. Permite que humanos marquem conteúdo validado como intocável durante re-ingestão ou enriquecimento automático.

### QA Score

Score de qualidade (0-100%) calculado pelo pipeline de QA. Determina se um documento pode ser promovido para `.md` final:

- **>= 90%:** aprovado para promoção
- **80-89%:** aprovado com ressalva (requer `qa_notes`)
- **< 80%:** bloqueado para promoção

### Conversion Quality

Score de qualidade (0-100%) que expressa a confiança na fidelidade da conversão de uma fonte original para formato `.beta.md`. Calculado pelo pipeline na Fase 2.

- **>= 80%:** ingestão automática
- **30-79%:** revisão humana obrigatória
- **< 30%:** fonte rejeitada

### Release TAG

Tag Git com versão semântica (vMAJOR.MINOR.PATCH) que marca um ponto de release. No workspace, a TAG dispara o pipeline de promoção. No knowledge-base, a TAG dispara o pipeline de ingestão na base vetorial.

### Curador

Papel responsável por gerenciar releases, criar TAGs, aprovar promoções e decidir sobre rollbacks. Definido na ADR-008 (Governança).

## 6. Termos de Segurança

### Confidencialidade

Nível de classificação de dados atribuído a cada documento via campo `confidentiality` no front matter. Quatro níveis:

- **public:** informação pública, acesso livre
- **internal:** uso interno, sem restrição legal de envio externo
- **restricted:** restrição regulatória ou contratual, on-premise obrigatório
- **confidential:** altamente confidencial, rede isolada obrigatória

### Segregação Física

Separação de dados em instâncias diferentes de base vetorial, com MCP Server dedicado e rede separada. Garante que dados restritos sejam fisicamente inacessíveis a partir da infraestrutura pública, eliminando classe inteira de vulnerabilidades.

### Just-in-Time (JIT) Access

Modelo de acesso onde permissões são concedidas sob demanda, com tempo limitado e justificativa registrada. Usado para KB confidential: acesso revogado automaticamente após período configurável.

### HSM (Hardware Security Module)

Módulo de hardware dedicado ao armazenamento seguro de chaves criptográficas. Usado na KB confidential para proteção de chaves de criptografia at-rest.

## 7. Termos de Versionamento

### SemVer (Semantic Versioning)

Padrão de versionamento no formato MAJOR.MINOR.PATCH:

- **MAJOR:** mudança estrutural (novo domínio, reestruturação, migração de modelo)
- **MINOR:** novos documentos ou atualizações significativas (>30% do doc)
- **PATCH:** correções pontuais (typos, ajustes de front matter, links quebrados)

### Release-Based Flow

Modelo de branching adotado pelo projeto. Utiliza apenas 2 tipos de branch: `release/vX.Y.Z/main` (consolidação) e `release/vX.Y.Z/{user}/{task}` (trabalho individual). Alternativa simplificada ao Git Flow tradicional.

### Rollback

Re-implantação de uma TAG anterior em produção. Rebuild completo da base vetorial (limpa dados, re-ingere, re-gera embeddings, re-cria relações). Preferido ao rollback parcial porque o pipeline é idempotente.

## 8. Referências

- **ADR-002 (BETA-002)** — Soberania de Dados: Trilha Cloud vs. On-Premise (fonte primária do glossário de infraestrutura)
- **ADR-001 (BETA-001)** — Pipeline de Geração de Conhecimento em 4 Fases (termos de pipeline e fases)
- **ADR-004 (BETA-004)** — Segurança e Classificação de Dados (termos de segurança e confidencialidade)
- **ADR-005 (BETA-005)** — Front Matter como Contrato de Metadados (termos de front matter e validação)
- **ADR-010 (BETA-010)** — Git Flow da Base de Conhecimento (termos de versionamento e branching)
- **ADR-011 (BETA-011)** — Segregação de KBs por Confidencialidade (termos de segregação e KBs)

<!-- conversion_quality: 95 -->
