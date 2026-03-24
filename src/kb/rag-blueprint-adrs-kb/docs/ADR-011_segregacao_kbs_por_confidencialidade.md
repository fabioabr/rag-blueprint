---
id: ADR-011
doc_type: adr
title: "Segregação de Bases de Conhecimento por Nível de Confidencialidade"
system: RAG Corporativo
module: Segregação de KBs
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-21
tags:
  - segregação física
  - confidencialidade
  - isolamento infraestrutura
  - base vetorial
  - mcp server
  - segurança
  - compliance
  - defesa em profundidade
  - filtro pré retrieval
  - kb public internal
  - kb restricted
  - kb confidential
  - trilha a
  - trilha b
  - on premises
  - cloud
  - soberania dados
  - lgpd
  - bacen
  - cvm
  - sox
  - iso 27001
  - controle acesso
  - autenticação
  - autorização
  - mfa
  - sso
  - just in time access
  - rede segmentada
  - criptografia
  - aes 256
  - tls
  - hsm
  - roteamento pipeline
  - front matter
  - wikilinks cross kb
  - orquestrador cross kb
  - rrf
  - busca cross kb
  - blast radius
  - auditabilidade
  - perfis acesso
  - analyst
  - manager
  - director
  - release independente
  - pipeline ingestão
  - row level security
  - prompt injection
  - misconfiguration
  - escalação privilégios
  - data leakage
  - fail safe
  - backup
  - documentos expirados
aliases:
  - ADR-011
  - Segregação por Confidencialidade
  - Segregação de KBs
  - Isolamento por Nível de Confidencialidade
  - Multi-KB por Confidencialidade
  - ADR Segregação KBs
superseded_by: null
source_format: txt
source_repo: Rag
source_path:
  - "src/kb/rag-blueprint-adrs-draft/draft/ADR-011_segregacao_kbs_por_confidencialidade.txt"
source_beta_ids:
  - BETA-011
conversion_pipeline: promotion-pipeline-v2
conversion_quality: 95
converted_at: 2026-03-23
qa_score: null
qa_date: null
qa_status: pending
created_at: 2026-03-21
updated_at: 2026-03-23
valid_from: 2026-03-21
valid_until: null
---

# ADR-011 — Segregação de Bases de Conhecimento por Nível de Confidencialidade

## Sumário

Este ADR decide pela **segregação FÍSICA** de Bases de Conhecimento (KBs) por nível de confidencialidade. Em vez de confiar exclusivamente em filtro pré-retrieval (camada de software) para impedir acesso a dados sensíveis, o controle de acesso é movido para a camada de **INFRAESTRUTURA**: dados de níveis diferentes residem em Bases Vetoriais fisicamente separadas, com MCP Servers dedicados. O filtro pré-retrieval ([[ADR-004]]) permanece como camada **ADICIONAL** de defesa dentro de cada KB.

O modelo define **3 KBs segregadas:**

- **kb-public-internal** (PUBLIC + INTERNAL) — Trilha A (cloud permitido)
- **kb-restricted** (RESTRICTED) — Trilha B (on-premises obrigatório)
- **kb-confidential** (CONFIDENTIAL) — Trilha B (on-premises, reforçado)

## Contexto

### O problema: filtro pré-retrieval não é suficiente

O [[ADR-004]] estabeleceu 4 níveis de confidencialidade (PUBLIC, INTERNAL, RESTRICTED, CONFIDENTIAL) e definiu o filtro pré-retrieval como INVIOLÁVEL.

Essa decisão está correta como **PRINCÍPIO**, mas apresenta fragilidade crítica como **ÚNICO** mecanismo de proteção. O filtro pré-retrieval é um controle na camada de SOFTWARE, vulnerável a:

- **(a) Bugs de implementação** — condição WHERE mal formulada, operador lógico invertido, campo não indexado causando fallback sem filtro
- **(b) Prompt injection** — manipulação da query para bypassar o filtro quando o MCP Server tem acesso a TODOS os dados na mesma Base Vetorial
- **(c) Misconfiguration** — deploy incorreto, variável de ambiente errada, perfil permissivo demais (causa número 1 de vazamento segundo Verizon DBIR)
- **(d) Escalação de privilégios** — qualquer vulnerabilidade que permita acesso direto à Base Vetorial (SQL injection, credencial vazada) expõe TODOS os níveis de uma vez
- **(e) Complexidade de auditoria** — auditar filtro de query em todas as situações é exponencialmente mais difícil do que auditar se dois servidores estão em redes separadas

### Contexto regulatório

O projeto opera dentro de instituição financeira regulada pelo BACEN, CVM e LGPD. O risco de vazamento de dados RESTRICTED/CONFIDENTIAL é regulatório e legal:

- **LGPD** (Lei 13.709/2018): multas de até 2% do faturamento + indenização
- **BACEN** (Resolução 4.893/2021): controles proporcionais à sensibilidade; falhas podem resultar em sanções e intervenção
- **CVM** (Instrução 400, Lei 6.385/1976): vazamento de informação privilegiada pode configurar crime
- **SOX** (se aplicável): controles insuficientes sobre informação financeira

Reguladores esperam controles em **MÚLTIPLAS CAMADAS**, com isolamento físico quando possível. Confiar EXCLUSIVAMENTE em filtro de query é **INACEITÁVEL** do ponto de vista de compliance.

### A tese: mover o controle da query para a infraestrutura

> Se dados RESTRICTED estão em uma Base Vetorial **SEPARADA**, com um MCP Server **SEPARADO**, em uma rede **SEPARADA**, então é **FISICAMENTE IMPOSSÍVEL** que um usuário acessando o MCP público consiga ver dados RESTRICTED.

Isso é **SEGURANÇA POR ISOLAMENTO DE INFRAESTRUTURA** — em contraste com segurança por filtro de software. O [[ADR-001]] já antecipou essa possibilidade ao definir KBs separadas; o [[ADR-002]] reforça ao definir Trilha A (Cloud) e Trilha B (On-Premise).

### Por que agora

Essa decisão precisa ser tomada **ANTES** da implementação do pipeline de ingestão ([[ADR-006]]), porque o roteamento de documentos para a Base Vetorial correta depende da arquitetura de segregação estar definida. Migrar depois implica re-ingestão completa, recriação de índices, reconfiguração de MCPs e agentes, e período de indisponibilidade.

## Decisão

**DECISÃO PRINCIPAL:**

Adotar modelo de **segregação física de Bases de Conhecimento (KBs) por nível de confidencialidade**, com Base Vetorial dedicada e MCP Server dedicado para cada nível. O campo `confidentiality` no front matter do documento determina para qual KB e Base Vetorial ele será roteado pelo pipeline de ingestão. O filtro pré-retrieval ([[ADR-004]]) continua existindo como camada ADICIONAL de defesa, mas NÃO é mais a única barreira.

> **NOTA** — Filtro pré-retrieval como camada ADICIONAL: O filtro pré-retrieval NÃO é eliminado. Ele permanece como camada de defesa DENTRO de cada KB para granularidade por DOMÍNIO de negócio. Exemplo: dentro da kb-restricted, o filtro restringe por domínio (Manager de financeiro não vê documentos restricted de compliance). A segregação física substitui o filtro como ÚNICA barreira entre níveis; o filtro permanece útil DENTRO do mesmo nível.

### Modelo de segregação — 3 níveis de KB

**NÍVEL 1: KB PÚBLICA + INTERNA (acesso geral)**

| Aspecto | Valor |
|---------|-------|
| Identificador | `kb-public-internal` |
| Confidencialidade | PUBLIC + INTERNAL |
| Base Vetorial | Instância A |
| MCP Server | `mcp-knowledge-public` |
| Trilha ([[ADR-002]]) | Trilha A (Cloud) — permitido |
| Acesso | Todos os funcionários autenticados, agentes de IA genéricos, assistentes de onboarding |
| Autenticação | Token de serviço ou SSO corporativo |
| Autorização | Perfis Analyst, Manager, Director — todos têm acesso |

**NÍVEL 2: KB RESTRITA (acesso por cargo/função)**

| Aspecto | Valor |
|---------|-------|
| Identificador | `kb-restricted` |
| Confidencialidade | RESTRICTED |
| Base Vetorial | Instância B (SEPARADA FISICAMENTE da Instância A) |
| MCP Server | `mcp-knowledge-restricted` |
| Trilha ([[ADR-002]]) | Trilha B (On-Premise) — OBRIGATÓRIO |
| Acesso | Gestores (Manager), Diretoria (Director), agentes de IA com perfil explícito para RESTRICTED |
| Autenticação | SSO corporativo + MFA obrigatório |
| Autorização | Manager: restrito ao seu domínio de negócio; Director: acesso amplo a restricted |
| Controles extras | Rede segmentada, firewall por IP, backup criptografado, SIEM, access review trimestral |

**NÍVEL 3: KB CONFIDENCIAL (acesso mínimo)**

| Aspecto | Valor |
|---------|-------|
| Identificador | `kb-confidential` |
| Confidencialidade | CONFIDENTIAL |
| Base Vetorial | Instância C (ISOLADA — rede separada) |
| MCP Server | `mcp-knowledge-confidential` |
| Trilha ([[ADR-002]]) | Trilha B (On-Premise) — OBRIGATÓRIO, controles EXTRAS |
| Acesso | Diretoria com justificativa, Compliance Officer, agentes dedicados com aprovação documentada |
| Autenticação | SSO + MFA + aprovação just-in-time (tempo limitado) |
| Autorização | Agente IA: acesso NEGADO por padrão |
| Controles extras | Rede fisicamente separada, VPN dedicada, AES-256 at-rest, TLS 1.3 in-transit, HSM, cofre de backup, SOC 24/7, retenção de logs mínimo 5 anos (BACEN) |

### Vantagens do modelo

- **(a) ELIMINAÇÃO DE CLASSE INTEIRA DE VULNERABILIDADES** — Qualquer vulnerabilidade na Base Vetorial A (bug, injection, misconfiguration, credencial vazada) NÃO tem como acessar dados RESTRICTED. Eles não existem naquele ambiente.
- **(b) ZERO RISCO DE DATA LEAKAGE VIA QUERY** — MCP público se conecta APENAS à Base Vetorial A. Não tem credencial ou endpoint para acessar B ou C. Contraste: filtro na query depende de código correto (pode falhar); segregação física não depende (não falha).
- **(c) AUDITABILIDADE SIMPLIFICADA** — Basta verificar quem tem acesso a qual MCP. Não precisa auditar queries individuais. Para reguladores: demonstrável de forma trivial.
- **(d) SIMPLICIDADE CONCEITUAL** — Controle de acesso = "qual MCP você acessa?" (não "qual filtro a query aplica?"). Simplifica desenvolvimento, teste, operação e onboarding.
- **(e) COMPLIANCE NATIVO** — Atende NATIVAMENTE: BACEN (ambiente isolado), LGPD (acesso restrito e auditável), CVM (informações privilegiadas isoladas), SOX (controles documentáveis), ISO 27001 (segmentação e controle por nível).
- **(f) ALINHAMENTO COM [[ADR-002]] (SOBERANIA)** — Cada Base Vetorial reside na trilha correta por design, não por configuração.

### Decisões complementares

**BUSCA CROSS-KB**

Usuários com acesso a múltiplos níveis necessitam de um agente orquestrador que consulte os MCPs autorizados em paralelo, funda resultados via RRF ([[ADR-007]]) e classifique a resposta pelo nível mais alto de chunk utilizado. Cada chunk no contexto deve indicar sua classificação (`[PUBLIC]`, `[RESTRICTED]`, etc.).

**DOCUMENTOS COM CONFIDENCIALIDADE MISTA**

Documentos com seções de níveis diferentes devem ser splitados na Fase 2 (`.beta.md`) em documentos separados por nível, com `cross_ref` no front matter. Fallback: classificar pelo nível MAIS ALTO.

Na re-ingestão ([[ADR-001]] seção 2.7), mudança de classificação de seções gera alerta para revisão humana.

**ROTEAMENTO NO PIPELINE DE INGESTÃO**

O campo `confidentiality` no front matter é o **ÚNICO** determinante do roteamento:

| Valor | Destino | Base Vetorial |
|-------|---------|---------------|
| `public` | kb-public-internal | Base Vetorial A |
| `internal` | kb-public-internal | Base Vetorial A |
| `restricted` | kb-restricted | Base Vetorial B |
| `confidential` | kb-confidential | Base Vetorial C |

Se campo **AUSENTE** ou inválido: pipeline **REJEITA** o documento (fail-safe). NÃO existe default — ausência de classificação é **ERRO**.

**WIKILINKS CROSS-KB**

Wikilinks cross-KB são **PROIBIDOS**. Motivo: link para documento restricted em documento público revela EXISTÊNCIA de informação restrita. Para referências cruzadas, usar `cross_ref` no front matter (sem link navegável). Pipeline valida: wikilink cross-KB = ERRO de ingestão.

**DOCUMENTOS EXPIRADOS NAS KBs**

Documentos expirados (`valid_until` ultrapassado) permanecem na Base Vetorial para consultas históricas. Cada MCP aplica filtro temporal individualmente. Documentos expirados são marcados como `[EXPIRADO]` no retrieval.

**ACESSO POR PERFIL (resumo)**

| Perfil | Acesso |
|--------|--------|
| Analyst | `mcp-knowledge-public` apenas |
| Manager | `mcp-knowledge-public` + `mcp-knowledge-restricted` (domínio) |
| Director | todos os 3 MCPs |
| Agente genérico | `mcp-knowledge-public` apenas |
| Agente de domínio | public + restricted (domínio específico) |
| Agente dedicado | `mcp-knowledge-confidential` (com aprovação) |

**RELEASES INDEPENDENTES POR KB (extensão do [[ADR-010]])**

Cada KB tem release tag independente (ex: `kb-restricted@v1.0.3`), ambiente de staging próprio e pipeline de deploy separado:

- KB pública: deploy automático (CI/CD)
- KB restrita: aprovação de Manager
- KB confidencial: aprovação de Director + Compliance

Rollback é independente por KB ([[ADR-008]]).

**MANUTENÇÃO DE MÚLTIPLAS INSTÂNCIAS**

Pipeline parametrizado (`KB_TARGET`, `VECTOR_DB_HOST`, `VECTOR_DB_CREDENTIALS`, `MCP_ENDPOINT`) permite usar o mesmo pipeline ([[ADR-006]]) para as 3 KBs.

**ESTRUTURA DE PASTAS**

A segregação por confidencialidade adiciona camada de diretório nos dois repositórios (`rag-workspace` e `rag-knowledge-base`), com subpastas por nível (`public-internal/`, `restricted/`, `confidential/`).

**NOTA:** Esta decisão **SUPERCEDE** a estrutura de pastas do [[ADR-001]] (seção 2.3).

## Alternativas Descartadas

### Alternativa A: Filtro pré-retrieval na query (modelo [[ADR-004]] original)

**Descrição:** Manter uma única Base Vetorial com todos os níveis. Controle de acesso exclusivamente via filtro pré-retrieval na query.

**Motivo da rejeição:** Para instituição financeira regulada, confiar EXCLUSIVAMENTE em filtro de query como mecanismo de proteção de dados RESTRICTED/CONFIDENTIAL é INACEITÁVEL. Vulnerável a bugs, prompt injection, misconfiguration e escalação de privilégios. Um único bug expõe TODOS os níveis. NÃO atende requisitos regulatórios de isolamento físico (BACEN, LGPD). Viola princípio de defesa em profundidade.

### Alternativa B: Banco único com Row-Level Security (RLS)

**Descrição:** Única Base Vetorial com RLS nativo do banco, aplicando política de acesso por usuário conectado.

**Motivo da rejeição:** RLS é controle na camada de software do banco, não na infraestrutura. Dados permanecem no mesmo disco, mesma memória, mesmo processo — admin do banco vê TUDO. Maturidade de RLS em bases vetoriais é limitada. Dependência de vendor indesejável. NÃO atende requisito de isolamento físico do BACEN para dados altamente sensíveis.

### Alternativa C: Criptografia at-rest com decrypt por perfil

**Descrição:** Todos os dados em única Base Vetorial, com chunks de níveis superiores criptografados com chaves diferentes.

**Motivo da rejeição:** INCOMPATÍVEL com busca vetorial — embeddings criptografados não podem ser comparados por similaridade. Embeddings em texto claro já revelam informação semântica (inversion attack possível). Complexidade criptográfica desproporcional quando segregação física resolve o problema de forma mais simples e segura. Criptografia at-rest é boa prática COMPLEMENTAR, não substituta de isolamento.

### Alternativa D: Segregação por 4 KBs (uma por nível)

**Descrição:** 4 KBs separadas — KB-public, KB-internal, KB-restricted, KB-confidential.

**Motivo da rejeição:** PUBLIC e INTERNAL têm perfis de acesso muito similares (todos os colaboradores autenticados). A diferença é sobre disseminação EXTERNA (pode sair da empresa?), não sobre acesso INTERNO. Separar não agrega segurança significativa e gera complexidade operacional excessiva (4 Bases Vetoriais, 4 MCPs, 4 pipelines, 4 ambientes de staging).

## Consequências

### Positivas

- Segurança reforçada por isolamento físico — elimina classe inteira de vulnerabilidades relacionadas a filtro de query
- Compliance nativo com BACEN, LGPD, CVM — isolamento físico atende requisitos regulatórios sem controles adicionais complexos
- Auditoria simplificada — "quem acessa qual MCP" é documentável e verificável de forma trivial
- Alinhamento com [[ADR-002]] (soberania) — cada KB na trilha de infraestrutura correta por design
- Blast radius limitado — comprometimento de uma Base Vetorial não afeta as demais
- Release independente — cada KB com seu próprio ciclo, sem acoplamento
- Escalabilidade independente — Base Vetorial A pode escalar sem afetar performance da B ou C
- Simplicidade conceitual — controle de acesso é "qual MCP você acessa"

### Negativas (com mitigações)

- Custo operacional maior — 3 Bases Vetoriais para manter. **Mitigação:** pipeline parametrizado, automação, monitoring unificado.
- Complexidade de busca cross-KB — precisa de agente orquestrador. **Mitigação:** orquestrador bem definido; RRF ([[ADR-007]]) já define fusão.
- Duplicação potencial de chunks — documento split em múltiplos níveis. **Mitigação:** `cross_ref` no front matter; orquestrador deduplica por `document_id` na fusão.
- Custo de infraestrutura maior — 3 instâncias em vez de 1. **Mitigação:** KBs restricted e confidential tendem a ter MUITO menos documentos — instâncias menores são suficientes.
- Latência na busca cross-KB — consultar 3 MCPs em paralelo. **Mitigação:** queries em paralelo, timeout por MCP, resultado parcial.

### Riscos

| # | Risco | Probabilidade | Impacto | Mitigação |
|---|-------|--------------|---------|-----------|
| 1 | Classificação incorreta de documento | MÉDIA | ALTO | Quality gate na Fase 2 com revisão humana; validação automática por keywords sensíveis; scan trimestral; na dúvida, classificar pelo nível MAIS ALTO |
| 2 | Orquestrador cross-KB com falha de segurança | BAIXA | ALTO | Orquestrador roda com perfil do USUÁRIO (não admin), sem credenciais próprias, stateless, com log completo e pen test específico |
| 3 | Drift de configuração entre ambientes | MÉDIA | MÉDIO | Infrastructure as Code, configuração no Git, drift detection automática, alertas para desvios |
| 4 | Documento sem classificação entra no pipeline | MÉDIA | ALTO | Pipeline REJEITA (fail-safe), pre-commit hook, quality gate na Fase 2, dashboard de documentos sem classificação |

## Implementação

A implementação segue **3 fases incrementais:**

### Fase 1 — MVP (apenas kb-public-internal)

- Base Vetorial A + MCP público operacionais
- Pipeline roteando public/internal para Base Vetorial A
- Documentos restricted/confidential **REJEITADOS** pelo pipeline
- Validação do mecanismo de rejeição por equipe de segurança

### Fase 2 — Adicionar kb-restricted

- Base Vetorial B em ambiente on-premises com rede segmentada
- MCP restricted com SSO+MFA
- Teste de penetração confirmando isolamento (MCP público NÃO acessa B)
- Controles de auditoria operacionais
- Validação de compliance (BACEN)

### Fase 3 — Adicionar kb-confidential + orquestrador cross-KB

- Base Vetorial C em rede isolada com HSM
- MCP confidential com SSO+MFA+JIT
- Criptografia at-rest (AES-256) e in-transit (TLS 1.3)
- Agente orquestrador cross-KB com fusão via RRF ([[ADR-007]])
- SOC 24/7, pen test completo, retenção de logs 5 anos
- Aprovação formal de Diretoria e Compliance

## Referências

### ADRs relacionadas

- [[ADR-001]] — Pipeline de Geração de Conhecimento em 4 Fases
- [[ADR-002]] — Soberania e Residência de Dados — Cloud vs. On-Premise
- [[ADR-004]] — Segurança, Classificação de Dados e Controle de Acesso
- [[ADR-006]] — Pipeline de Ingestão — Da Fonte à Base Vetorial
- [[ADR-007]] — Retrieval Híbrido e Agentes
- [[ADR-008]] — Governança, Ciclo de Vida e Rollback
- [[ADR-010]] — Git Flow e Release

### Regulações

- LGPD — Lei 13.709/2018
- BACEN — Resolução 4.893/2021
- BACEN — Resolução BCB 85/2021
- CVM — Instrução CVM 400, Lei 6.385/1976
- ISO 27001
- Verizon DBIR

### Conceitos

- Defense in depth
- Blast radius
- Fail-safe
- Just-in-time access
- RRF (Reciprocal Rank Fusion)

<!-- conversion_quality: 95 -->
