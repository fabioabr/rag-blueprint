---
# === IDENTIFICAÇÃO ===
id: ADR-004
doc_type: adr
title: "Estratégia de Segurança e Classificação de Dados"

# === CLASSIFICAÇÃO ===
system: RAG Corporativo
module: Segurança e Classificação
domain: Arquitetura
owner: fabio
team: arquitetura

# === STATUS E GOVERNANÇA ===
status: accepted
confidentiality: internal
date_decided: 2026-03-21

# === TEMPORAL ===
valid_from: "2026-03-21"
valid_until: null
supersedes: null
superseded_by: null

# === DESCOBERTA ===
tags: [segurança, classificação de dados, lgpd, filtro pre retrieval, autenticação, autorização, prompt injection, defesa em profundidade, confidencialidade, controle de acesso, rbac, abac, api key, jwt, oidc, saml, mcp server, anonimização, pii, bacen, cvm, compliance, auditoria, rate limiting, sanitização, validação de output, segregação de bases vetoriais, herança de classificação, revogação de acesso, monitoramento de anomalias, residência de dados, on premise, cloud soberana, criptografia, aes 256, tls, dados pessoais, direito a exclusão, reclassificação, pipeline de anonimização, ner, regex, service account, perfil de acesso, knowledge base, data leakage, zero trust, regulatório, resolução bcb 85, resolução 4893, mnpi, whistle blowing, lei 13709]
aliases:
  - "ADR-004"
  - "Segurança RAG"
  - "Estratégia de Segurança RAG Corporativo"
  - "Classificação de Dados e Confidencialidade"
  - "Defesa em Profundidade RAG"

# === LINHAGEM ===
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/draft/ADR-004_seguranca_classificacao_dados.txt"
source_beta_ids: ["BETA-004"]
conversion_pipeline: promotion-pipeline-v2
conversion_quality: 95
converted_at: "2026-03-23"

# === QA ===
qa_score: null
qa_date: null
qa_status: pending

# === DATAS ===
created_at: "2026-03-21"
updated_at: "2026-03-23"
---

# ADR-004 — Estratégia de Segurança e Classificação de Dados

## Sumário

Este ADR define a estratégia de segurança e classificação de dados para o RAG Corporativo. A decisão central é adotar defesa em profundidade baseada em **6 pilares complementares**: (1) classificação de dados em 4 níveis, (2) filtro pré-retrieval inviolável, (3) autenticação evolutiva, (4) autorização evolutiva, (5) proteção contra prompt injection, e (6) conformidade LGPD e regulatória.

Conteúdos procedimentais foram extraídos para documentos dedicados:

- SPEC-C01: Checklist de Segurança LLM
- DOC-C02: Política de Revisão de Dados
- RNB-C03: Migração Auth API Key JWT
- RNB-C04: Anonimização PII
- RNB-C05: Incidente PII (de [[ADR-008]])

**Depende de:** [[ADR-001]] (Pipeline de 4 Fases), [[ADR-002]] (Soberania de Dados)
**Relaciona-se com:** [[ADR-003]] (Modelo de Dados), [[ADR-006]] (Pipeline de Ingestão), [[ADR-007]] (Retrieval), [[ADR-008]] (Governança e Ciclo de Vida)

## 1. Contexto

O projeto RAG Corporativo está sendo construído dentro de uma instituição financeira regulada pelo **Banco Central do Brasil (BACEN)**, pela **Comissão de Valores Mobiliários (CVM)** e pela **Lei Geral de Proteção de Dados (LGPD — Lei 13.709/2018)**. Qualquer decisão de arquitetura de dados precisa considerar restrições regulatórias severas.

A base de conhecimento conterá documentos que vão desde manuais técnicos públicos até informações altamente confidenciais (dados financeiros de clientes, estratégias de mercado, decisões regulatórias internas, post-mortems de incidentes de segurança).

**Problema fundamental:** o sistema RAG deve ser capaz de responder perguntas de diferentes perfis de usuário sem **jamais** expor dados que aquele perfil não tem direito de ver.

Razões de complexidade:

- **(a)** Busca vetorial sem filtro de acesso pode retornar chunks confidenciais para usuários sem autorização — mesmo que o prompt instrua a LLM a "não revelar dados confidenciais". Prompts **não** são mecanismo de segurança
- **(b)** LLMs são vulneráveis a prompt injection. Se o chunk confidencial já está no contexto, nenhuma instrução de sistema garante que a LLM não vai vazá-lo
- **(c)** A decisão de soberania de dados ([[ADR-002]]) define que dados RESTRICTED e CONFIDENTIAL devem ser processados on-premise, enquanto dados PUBLIC e INTERNAL podem usar APIs de cloud com controles. Isso exige pipelines de processamento separados conforme o nível de classificação
- **(d)** MCP Servers (Model Context Protocol) criam superfícies de ataque adicionais — cada MCP Server é um ponto de acesso que precisa autenticação e autorização próprias
- **(e)** A LGPD exige que dados pessoais (PII) possam ser removidos a pedido do titular, incluindo chunks, embeddings e metadados na Base Vetorial

### Alinhamento com ADR-001 (Pipeline de 4 Fases)

A segurança permeia **todas** as 4 fases do pipeline definido na [[ADR-001]]:

- **Fase 1** (Seleção de insumos): controle de acesso ao repositório
- **Fase 2** (Mineração .beta.md): campo `confidentiality` no front matter leve roteia o documento pela trilha correta (cloud vs on-premise, conforme [[ADR-002]])
- **Fase 3** (Promoção .md): pipeline valida classificação no gate de qualidade
- **Fase 4** (Ingestão na Base Vetorial): filtro pré-retrieval aplicado nos chunks, herança de confidentiality do documento pai

### Por que esse ADR é crítico

Sem uma estratégia de segurança clara **antes** de implementar o retrieval, corremos o risco de criar um sistema que viola regulações (multas de até 2% do faturamento pela LGPD, sanções do BACEN incluindo intervenção) e expõe a instituição a riscos reputacionais irreparáveis.

## 2. Decisão

Adotar estratégia de segurança baseada em **6 pilares** complementares: (1) classificação de dados, (2) filtro pré-retrieval inviolável, (3) autenticação evolutiva, (4) autorização evolutiva, (5) proteção contra prompt injection, e (6) conformidade LGPD e regulatória. Cada pilar endereça uma camada diferente do problema e juntos formam defesa em profundidade.

### Pilar 1 — Classificação de Dados (4 Níveis)

Cada documento recebe uma classificação de confidencialidade no campo `confidentiality` do front matter. Essa classificação é **obrigatória** e determina:

- **Quem** pode acessar o documento
- **Onde** o documento pode ser processado (cloud vs on-premise)
- **Como** o documento é tratado pelo pipeline de ingestão

<!-- LOCKED:START autor=fabio data=2026-03-22 -->

| Nível | Label | Quem pode acessar | Onde pode ser processado | Exemplos |
|-------|-------|-------------------|--------------------------|----------|
| 1 | **PUBLIC** | Qualquer usuário autenticado, incluindo agentes de IA | Cloud APIs ou on-premise sem restrições | Documentação pública de APIs, tutoriais genéricos, manuais de ferramentas de terceiros, glossário de termos não proprietários |
| 2 | **INTERNAL** | Qualquer colaborador autenticado (Analyst, Manager, Director) e agentes com perfil interno | Cloud APIs **com controles** (DPA, sem uso para treinamento, logs de envio). On-premise sem restrições | Documentação de sistemas internos, ADRs, glossário interno, processos operacionais, métricas de performance não financeiras |
| 3 | **RESTRICTED** | Manager (com restrição por domínio), Director (acesso amplo), agentes de IA com perfil explícito | **Exclusivamente on-premise** (Resolução 4.893/2021 e BCB 85/2021) | Post-mortems de incidentes, auditorias internas, estratégias de produto, dados de compliance e PLD |
| 4 | **CONFIDENTIAL** | Director com justificativa em log de auditoria; agentes de IA com acesso **negado por padrão** | **Exclusivamente em ambiente isolado on-premise** (rede segregada, logs com retenção mínima de 5 anos, criptografia AES-256 em repouso e TLS 1.3 em trânsito, backup segregado, monitoramento em tempo real) | Dados pessoais sensíveis (art. 5, II, LGPD), investigações internas, MNPI (CVM), credenciais, modelos de risco proprietários, comunicações com reguladores, whistleblowing |

<!-- LOCKED:END -->

**Herança de classificação (Document → Chunk):**

- `chunk.confidentiality = documento.confidentiality` — sem exceções, sem override por chunk
- Justificativa: classificações mistas por chunk são impossíveis de auditar, alto risco de erro humano, regra simples de entender, implementar e auditar
- Se um documento tem partes com níveis diferentes, a solução é **dividir em documentos separados**
- Na Base Vetorial, o chunk armazena `confidentiality` (herdado) e `document_id` (para rastreabilidade), permitindo filtro pré-retrieval direto no chunk

**Cadência de revisão de classificações:**

Ver DOC-C02: Política de Revisão de Dados para o detalhamento de cadências (contínua, mensal, trimestral, semestral) e procedimentos de reclassificação.

### Pilar 2 — Filtro Pré-Retrieval (Inviolável)

**Regra fundamental:** o filtro de confidencialidade **deve** ser aplicado **antes** da busca vetorial. Não depois. Não "junto". **Antes.**

**Por que pré-retrieval e não pós-retrieval?**

- **Pós-retrieval (incorreto):** busca vetorial retorna chunks sem filtro, depois remove os não autorizados. **Problema:** chunks confidenciais já foram carregados em memória. Qualquer falha (bug, log verbose, dump de debug) já constitui vazamento. Além disso: resultado com menos chunks que o esperado, ranking distorcido, e inferência de existência de dados confidenciais
- **Pré-retrieval (correto):** filtro aplicado como cláusula WHERE antes da busca vetorial. Chunks confidenciais **nunca** saem do armazenamento. Ranking feito sobre o universo correto. Sem vazamento por inferência

**Mapeamento perfil → níveis permitidos:**

- **Analyst:** `['public', 'internal']`
- **Manager:** `['public', 'internal', 'restricted']`
- **Director:** `['public', 'internal', 'restricted', 'confidential']`

O filtro pré-retrieval deve ser **inviolável**:

- Não pode ser desabilitado por parâmetro
- Não pode ser ignorado por flag de debug
- Não pode ser bypassado por role de admin
- Deve ser implementado na camada de infraestrutura (wrapper/middleware que SEMPRE injeta o filtro), não na camada de aplicação

**Filtros adicionais (complementares ao confidentiality):**

- domain: restringir busca a domínios do usuário
- system: restringir a sistemas com acesso
- team: restringir a documentos de times do usuário
- valid_from/valid_until: filtro temporal ([[ADR-001]], seção 2.6)

O filtro de confidentiality é sempre o primeiro e mais crítico.

**Validação do filtro:** testes unitários, de integração e de regressão devem garantir ZERO data leakage. Detalhamento em SPEC-C01: Checklist de Segurança LLM.

### Pilar 3 — Autenticação Evolutiva

**Fases 1 e 2 — API Key:**

- Cada usuário/agente recebe API Key única associada a um perfil
- Controles: expiração (max 90 dias), rotação obrigatória, revogação imediata, registro de uso, rate limiting
- Justificativa: simplicidade, velocidade, suficiente para poucos usuários iniciais, custo zero de infraestrutura adicional
- Limitações conhecidas: sem SSO, sem MFA, gestão manual não escala, sem federação de identidade

**Fases 3+ — JWT via IdP Corporativo (OIDC/SAML):**

- Autenticação via IdP corporativo (Azure AD, Keycloak)
- Token JWT com claims: sub, name, email, groups, department
- Justificativa da migração: escalabilidade, MFA via IdP, lifecycle gerenciado pelo RH, identidade inequívoca, SSO
- O caminho de migração API Key → JWT é detalhado em RNB-C03: Migração Auth API Key JWT

**MCP Server — autenticação:**

- MCP Servers autenticam usando service account com JWT
- Cada MCP Server tem perfil de acesso próprio (scoped tokens com domínios, níveis de confidencialidade e rate limits específicos)
- Auditoria registra agente de origem

**Revogação de acesso:**

- **Downgrade de perfil**: efeito imediato na próxima query (filtro usa perfil atual, sem cache de resultados)
- **Remoção de usuário**: API Key revogada imediatamente; JWT invalidado via blocklist (ou aguardar TTL curto — max 15 min); cache purgado; sessões encerradas; registro de auditoria
- **Reclassificação de documento**: requer re-promoção via pipeline ([[ADR-001]]); chunks atualizados no próximo refresh da Base Vetorial; reclassificações urgentes acionam refresh imediato

### Pilar 4 — Autorização Evolutiva

**Fase 1 (MVP) — Perfil único "Internal":**

- Todos os usuários acessam public + internal
- Documentos restricted e confidential **não são ingeridos** na Base Vetorial
- O risco é controlado pela exclusão de dados sensíveis da ingestão

**Fase 2+ — Segregação por Bases Vetoriais (KBs por Confidencialidade):**

Bases Vetoriais separadas por nível, cada uma com MCP Server próprio:

| Knowledge Base | Base Vetorial | MCP Server | Acesso |
|---------------|---------------|------------|--------|
| kb-public-internal | Base Vetorial A | MCP público | Todos os usuários |
| kb-restricted | Base Vetorial B | MCP restrito | Manager, Director, agentes autorizados |
| kb-confidential | Base Vetorial C | MCP confidencial | Director, compliance officers |

Justificativa: zero risco de data leakage via query (dados em bases fisicamente separadas), controle binário (acesso ao MCP ou não), auditabilidade na camada de infraestrutura, escalabilidade (nova classificação = nova KB + novo MCP).

**NOTA:** este modelo merece ADR próprio para detalhar segregação de KBs, estratégia de deployment e sincronização de schemas entre bases.

**Fase 2 — RBAC (Role-Based Access Control):**

4 perfis pré-definidos com mapeamento para níveis de confidencialidade:

| Perfil | Níveis de acesso | Descrição |
|--------|-----------------|-----------|
| **Analyst** | public, internal | Devs, analistas, suporte |
| **Manager** | public, internal, restricted | Gestores, tech leads |
| **Director** | todos (confidential com justificativa) | Diretores, C-level, compliance |
| **AI_Agent** | configurável por instância | Agentes de IA via MCP |

Justificativa de RBAC na Fase 2: Fase 1 tem poucos usuários com mesmo perfil; RBAC requer tabelas de usuários/perfis; Fase 2 introduz filtros por sistema/módulo (momento natural).

**Fase 3+ — ABAC (Attribute-Based Access Control):**

- Decisão de acesso baseada em atributos do usuário (role, department, team, location), do recurso (confidentiality, domain, system, doc_type) e do contexto (time, ip_address, mfa_verified, session_duration)
- Justificativa: RBAC não escala para regras complexas (explosão de roles); ABAC permite políticas declarativas e auditáveis; requisito BACEN de controle granular; padrão NIST SP 800-162. RBAC é subset de ABAC — migração incremental

**Auditoria (presente em todas as fases):**

Cada query gera registro contendo: timestamp, user_id, user_role, query, filtros aplicados, chunks retornados (com chunk_id, confidentiality, document_id), latência, source_ip, agent_id, mcp_server. Retenção: mínimo 5 anos (requisito BACEN). Formato: JSON Lines em sistema de logs corporativo.

**Controle de acesso para repositórios:**

- **rag-workspace** (read-write): POs e especialistas editam .beta.md; pipeline de IA gera .beta.md; pasta sources/ com acesso restrito (PII)
- **rag-knowledge-base** (read-only para todos, write via pipeline): escrita exclusiva via service account com PR aprovado por PO + Arquiteto

### Pilar 5 — Proteção contra Prompt Injection

Decisão: adotar 5 camadas de proteção obrigatórias, implementadas como defesa em profundidade:

1. **Sanitização de input**: limpar e validar a query antes de enviar à LLM. Remover caracteres de controle, detectar padrões de injection, limitar tamanho (max 2000 chars), rejeitar inputs com Markdown/HTML que confundam separação instrução/dados. Primeira linha de defesa
2. **Separação de system prompt**: system prompt **nunca** concatenado com input do usuário. Delimitadores claros entre `[SYSTEM]`, `[USER QUERY]` e `[CONTEXT]`. Contexto (chunks) injetado em seção separada
3. **Validação de output**: verificar resposta da LLM antes de entregar ao usuário. Detectar padrões de PII (CPF, CNPJ, contas bancárias, tokens), trechos de system prompt. Se detectado, substituir por resposta genérica e registrar incidente. Última linha de defesa
4. **Rate limiting por usuário**: Analyst: 100/hora, 500/dia; Manager: 150/hora, 750/dia; Director: 200/hora, 1000/dia; AI_Agent: configurável (default 200/hora). Torna extração lenta e detectável
5. **Monitoramento de anomalias**: queries com termos suspeitos, sequências similares, domínios fora do perfil, volume anormal, respostas que acionaram validação repetidamente. Alertas em tempo real

Detalhamento de checklists e procedimentos em SPEC-C01: Checklist de Segurança LLM.

### Pilar 6 — LGPD e Conformidade Regulatória

**Minimização de dados:**

- Pipeline de ingestão deve ter etapa de anonimização para documentos com PII antes de gerar embeddings
- Dados originais ficam apenas nas fontes brutas (Fase 1), com controle de acesso separado
- Exceção: documentos cuja finalidade é conter dados pessoais devem ser classificados como RESTRICTED ou CONFIDENTIAL
- Detalhamento do pipeline em RNB-C04: Anonimização PII

**Direito à exclusão (art. 18, VI, LGPD):**

- O titular pode solicitar exclusão dos seus dados
- Desafio técnico: embeddings não são reversíveis — requer índice de metadados mapeando PII → chunks/documentos
- Logs de auditoria **não** são alterados (requisito legal) mas são marcados como "dados do titular X excluídos"
- Procedimento detalhado em RNB-C05: Incidente PII (de [[ADR-008]])

**Residência de dados (conforme [[ADR-002]]):**

- PUBLIC e INTERNAL: armazenamento em região Brasil ou com adequação LGPD (Europa/GDPR); processamento em cloud permitido
- RESTRICTED e CONFIDENTIAL: processamento e armazenamento **exclusivamente** em infraestrutura nacional (on-premise ou cloud soberana em território brasileiro)
- Implicação: Base Vetorial com dados de todos os níveis **deve** estar on-premise, ou usar duas instâncias separadas (cloud para public+internal, on-premise para restricted+confidential)

**Requisitos BACEN para uso de cloud (Resolução BCB 85/2021 e 4.893/2021):**

- Comunicação prévia ao BACEN sobre contratação de serviços de cloud
- Plano de contingência e continuidade
- Possibilidade de auditoria pelo BACEN
- Recomendação MVP: LLM on-premise (modelos open source) para evitar necessidade de comunicação ao BACEN; migrar para cloud após processo de comunicação completo

## 3. Alternativas Descartadas

### 3.1. Segurança apenas por prompt (instruções à LLM)

- **Descrição**: confiar nas instruções do system prompt para que a LLM não revele dados confidenciais
- **Rejeição**: LLMs não são determinísticas; prompt injection pode sobrescrever instruções; impossível auditar ou garantir compliance; viola princípio básico de que controle de acesso deve estar na infraestrutura, não na aplicação

### 3.2. Classificação por chunk (não por documento)

- **Descrição**: permitir que cada chunk tenha classificação independente do documento pai
- **Rejeição**: complexidade inviável de gestão; alto risco de erro humano; auditoria muito mais complexa; solução correta é dividir em documentos separados

### 3.3. Autenticação única (só JWT, desde o MVP)

- **Descrição**: implementar JWT via IdP corporativo desde a fase 1
- **Rejeição**: dependência de infraestrutura para configurar IdP; atrasa o MVP; overhead desnecessário para 5-10 usuários iniciais; princípio YAGNI

### 3.4. ABAC desde o início (sem fase RBAC)

- **Descrição**: implementar ABAC diretamente, pulando RBAC
- **Rejeição**: requer engine de políticas (OPA, Cedar); definir políticas ABAC requer entender padrões de acesso reais; RBAC com 4 perfis é suficiente para fases 1-2; migração RBAC→ABAC é incremental

### 3.5. Criptografia como único controle (sem classificação)

- **Descrição**: proteger dados apenas com criptografia, sem classificação de confidencialidade
- **Rejeição**: criptografia protege contra acesso não autorizado ao storage, mas não resolve controle de acesso lógico; sem classificação o filtro pré-retrieval não tem critério; LGPD e BACEN exigem controle granular. Criptografia é adotada como controle **complementar** (AES-256 para confidential), nunca como controle único

## 4. Consequências

### 4.1. Positivas

- **Defesa em profundidade**: 6 pilares complementares, falha em um não compromete os outros
- **Compliance regulatório**: alinhado com LGPD, BACEN e CVM
- **Evolutivo**: complexidade adicionada gradualmente conforme necessidade
- **Auditável**: cada query tem registro completo
- **Flexível**: perfil AI_Agent permite configuração granular por agente

### 4.2. Negativas / Trade-offs

- Filtro pré-retrieval reduz universo de busca para perfis restritos (Analyst vê menos documentos, pode ter respostas de menor qualidade)
- Pipeline de anonimização adiciona latência na ingestão
- Duas instâncias da Base Vetorial (cloud + on-prem) aumentam custo e complexidade operacional
- Auditoria com retenção de 5 anos gera volume significativo de logs
- Migração API Key → JWT requer planejamento de transição

### 4.3. Riscos

| Risco | Mitigação |
|-------|-----------|
| Falso negativo na anonimização: PII não detectado e ingerido | Revisão humana para confidence < 90%, auditoria periódica |
| Prompt injection zero-day: ataque novo que bypassa sanitização | Filtro pré-retrieval garante que dados confidenciais nunca chegam ao contexto de usuários não autorizados |
| Classificação incorreta de documento: humano classifica como PUBLIC algo RESTRICTED | Revisão no pipeline de promoção (Fase 3, [[ADR-001]]) |
| Sobrecarga de auditoria | Alertas automáticos para padrões anômalos, revisão humana apenas para alertas |
| Janela de exposição na reclassificação: entre reclassificação no repositório e refresh da Base Vetorial, chunks podem estar desatualizados | Reclassificações que aumentam restrição acionam refresh imediato; as que diminuem aguardam ciclo normal |

## 5. Implementação

| Fase | Entrega | Dependência |
|------|---------|-------------|
| **1-MVP** | Campo confidentiality no front matter, filtro pré-retrieval básico (WHERE), API Key para autenticação, log básico de queries | [[ADR-001]] Fase 1 |
| **2** | 4 perfis RBAC, mapeamento perfil → níveis de acesso, pipeline de anonimização (NER + regex), validação de output básica, segregação por KBs/MCPs | [[ADR-001]] Fase 2 |
| **3** | JWT via IdP corporativo (OIDC), migração API Key → JWT, ABAC básico (domínio + confidentiality), sanitização de input avançada, rate limiting por usuário | [[ADR-001]] Fase 3, IdP configurado |
| **4** | ABAC completo (atributos de contexto), monitoramento de anomalias, auditoria com retenção de 5 anos, procedimento de exclusão LGPD testado, comunicação ao BACEN (se cloud) | [[ADR-001]] Fase 4 |

**Responsáveis:**

- Arquiteto: definição de políticas, schemas, classificação
- Segurança da Informação: validação de controles, pen testing
- Engenharia: implementação de filtros, autenticação, auditoria
- DPO / Compliance: validação LGPD, comunicação BACEN
- Ops / Infra: configuração de rede segregada, IdP, logs

Detalhamento de procedimentos nos documentos extraídos:

- RNB-C03: Migração Auth API Key JWT (passos de migração Fase 3)
- RNB-C04: Anonimização PII (pipeline NER + regex + validação)
- SPEC-C01: Checklist de Segurança LLM (testes, validação de filtros)

## 6. Referências

### Internas

- [[ADR-001]] — Pipeline de Geração de Conhecimento em 4 Fases
- [[ADR-002]] — Soberania de Dados: Trilha Cloud vs. On-Premise
- [[ADR-003]] — Modelo de Dados da Base Vetorial
- [[ADR-008]] — Governança e Ciclo de Vida (cadências de curadoria)
- B14 — Segurança e Soberania de Dados (blueprint)
- B04 — Metadados e Governança (front matter)

### Documentos extraídos deste ADR

- SPEC-C01: Checklist de Segurança LLM
- DOC-C02: Política de Revisão de Dados
- RNB-C03: Migração Auth API Key JWT
- RNB-C04: Anonimização PII
- RNB-C05: Incidente PII (de [[ADR-008]])

### Externas

- [LGPD — Lei 13.709/2018](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm)
- [Resolução BCB 85/2021 — Política de segurança cibernética](https://www.bcb.gov.br/estabilidadefinanceira/exibenormativo?tipo=Resolu%C3%A7%C3%A3o%20BCB&numero=85)
- [Resolução 4.893/2021 — Contratação de serviços de cloud](https://www.bcb.gov.br/estabilidadefinanceira/exibenormativo?tipo=Resolu%C3%A7%C3%A3o&numero=4893)
- [NIST SP 800-162 — Guide to ABAC](https://csrc.nist.gov/publications/detail/sp/800-162/final)
- [OWASP LLM Top 10 — Prompt Injection](https://owasp.org/www-project-top-10-for-large-language-model-applications/)
- CVM Instrução 358/2002 — Divulgação de informação relevante (MNPI)

<!-- conversion_quality: 95 -->
