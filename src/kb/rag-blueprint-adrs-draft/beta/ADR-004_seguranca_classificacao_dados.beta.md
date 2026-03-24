---
id: BETA-004
title: "Estrategia de Seguranca e Classificacao de Dados"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-004_seguranca_classificacao_dados.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags: [seguranca, classificacao de dados, lgpd, filtro pre retrieval, autenticacao, autorizacao, prompt injection, defesa em profundidade, confidencialidade, controle de acesso, rbac, abac, api key, jwt, oidc, saml, mcp server, anonimizacao, pii, bacen, cvm, compliance, auditoria, rate limiting, sanitizacao, validacao de output, segregacao de bases vetoriais, heranca de classificacao, revogacao de acesso, monitoramento de anomalias, residencia de dados, on premise, cloud soberana, criptografia, aes 256, tls, dados pessoais, direito a exclusao, reclassificacao, pipeline de anonimizacao, ner, regex, service account, perfil de acesso, knowledge base, data leakage, zero trust, regulatorio]
aliases:
  - "ADR-004"
  - "Seguranca RAG"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## Sumario

Este ADR define a estrategia de seguranca e classificacao de dados para o RAG Corporativo. A decisao central e adotar defesa em profundidade baseada em **6 pilares complementares**: (1) classificacao de dados em 4 niveis, (2) filtro pre-retrieval inviolavel, (3) autenticacao evolutiva, (4) autorizacao evolutiva, (5) protecao contra prompt injection, e (6) conformidade LGPD e regulatoria.

Conteudos procedimentais foram extraidos para documentos dedicados:

- SPEC-C01: Checklist de Seguranca LLM
- DOC-C02: Politica de Revisao de Dados
- RNB-C03: Migracao Auth API Key JWT
- RNB-C04: Anonimizacao PII
- RNB-C05: Incidente PII (de ADR-008)

**Depende de:** [[BETA-001]] (Pipeline de 4 Fases), [[BETA-002]] (Soberania de Dados)
**Relaciona-se com:** [[BETA-003]] (Modelo de Dados), ADR-006 (Pipeline de Ingestao), ADR-007 (Retrieval), ADR-008 (Governanca e Ciclo de Vida)

## 1. Contexto

O projeto RAG Corporativo esta sendo construido dentro de uma instituicao financeira regulada pelo **Banco Central do Brasil (BACEN)**, pela **Comissao de Valores Mobiliarios (CVM)** e pela **Lei Geral de Protecao de Dados (LGPD — Lei 13.709/2018)**. Qualquer decisao de arquitetura de dados precisa considerar restricoes regulatorias severas.

A base de conhecimento contera documentos que vao desde manuais tecnicos publicos ate informacoes altamente confidenciais (dados financeiros de clientes, estrategias de mercado, decisoes regulatorias internas, post-mortems de incidentes de seguranca).

**Problema fundamental:** o sistema RAG deve ser capaz de responder perguntas de diferentes perfis de usuario sem **jamais** expor dados que aquele perfil nao tem direito de ver.

Razoes de complexidade:

- **(a)** Busca vetorial sem filtro de acesso pode retornar chunks confidenciais para usuarios sem autorizacao — mesmo que o prompt instrua a LLM a "nao revelar dados confidenciais". Prompts **nao** sao mecanismo de seguranca
- **(b)** LLMs sao vulneraveis a prompt injection. Se o chunk confidencial ja esta no contexto, nenhuma instrucao de sistema garante que a LLM nao vai vaza-lo
- **(c)** A decisao de soberania de dados ([[BETA-002]]) define que dados RESTRICTED e CONFIDENTIAL devem ser processados on-premise, enquanto dados PUBLIC e INTERNAL podem usar APIs de cloud com controles. Isso exige pipelines de processamento separados conforme o nivel de classificacao
- **(d)** MCP Servers (Model Context Protocol) criam superficies de ataque adicionais — cada MCP Server e um ponto de acesso que precisa autenticacao e autorizacao proprias
- **(e)** A LGPD exige que dados pessoais (PII) possam ser removidos a pedido do titular, incluindo chunks, embeddings e metadados na Base Vetorial

### Alinhamento com ADR-001 (Pipeline de 4 Fases)

A seguranca permeia **todas** as 4 fases do pipeline definido na [[BETA-001]]:

- **Fase 1** (Selecao de insumos): controle de acesso ao repositorio
- **Fase 2** (Mineracao .beta.md): campo `confidentiality` no front matter leve roteia o documento pela trilha correta (cloud vs on-premise, conforme [[BETA-002]])
- **Fase 3** (Promocao .md): pipeline valida classificacao no gate de qualidade
- **Fase 4** (Ingestao na Base Vetorial): filtro pre-retrieval aplicado nos chunks, heranca de confidentiality do documento pai

### Por que esse ADR e critico

Sem uma estrategia de seguranca clara **antes** de implementar o retrieval, corremos o risco de criar um sistema que viola regulacoes (multas de ate 2% do faturamento pela LGPD, sancoes do BACEN incluindo intervencao) e expoe a instituicao a riscos reputacionais irreparaveis.

## 2. Decisao

Adotar estrategia de seguranca baseada em **6 pilares** complementares: (1) classificacao de dados, (2) filtro pre-retrieval inviolavel, (3) autenticacao evolutiva, (4) autorizacao evolutiva, (5) protecao contra prompt injection, e (6) conformidade LGPD e regulatoria. Cada pilar endereca uma camada diferente do problema e juntos formam defesa em profundidade.

### Pilar 1 — Classificacao de Dados (4 Niveis)

Cada documento recebe uma classificacao de confidencialidade no campo `confidentiality` do front matter. Essa classificacao e **obrigatoria** e determina:

- **Quem** pode acessar o documento
- **Onde** o documento pode ser processado (cloud vs on-premise)
- **Como** o documento e tratado pelo pipeline de ingestao

<!-- LOCKED:START autor=fabio data=2026-03-22 -->

| Nivel | Label | Quem pode acessar | Onde pode ser processado | Exemplos |
|-------|-------|-------------------|--------------------------|----------|
| 1 | **PUBLIC** | Qualquer usuario autenticado, incluindo agentes de IA | Cloud APIs ou on-premise sem restricoes | Documentacao publica de APIs, tutoriais genericos, manuais de ferramentas de terceiros, glossario de termos nao proprietarios |
| 2 | **INTERNAL** | Qualquer colaborador autenticado (Analyst, Manager, Director) e agentes com perfil interno | Cloud APIs **com controles** (DPA, sem uso para treinamento, logs de envio). On-premise sem restricoes | Documentacao de sistemas internos, ADRs, glossario interno, processos operacionais, metricas de performance nao financeiras |
| 3 | **RESTRICTED** | Manager (com restricao por dominio), Director (acesso amplo), agentes de IA com perfil explicito | **Exclusivamente on-premise** (Resolucao 4.893/2021 e BCB 85/2021) | Post-mortems de incidentes, auditorias internas, estrategias de produto, dados de compliance e PLD |
| 4 | **CONFIDENTIAL** | Director com justificativa em log de auditoria; agentes de IA com acesso **negado por padrao** | **Exclusivamente em ambiente isolado on-premise** (rede segregada, logs com retencao minima de 5 anos, criptografia AES-256 em repouso e TLS 1.3 em transito, backup segregado, monitoramento em tempo real) | Dados pessoais sensiveis (art. 5, II, LGPD), investigacoes internas, MNPI (CVM), credenciais, modelos de risco proprietarios, comunicacoes com reguladores, whistleblowing |

<!-- LOCKED:END -->

**Heranca de classificacao (Document → Chunk):**

- `chunk.confidentiality = documento.confidentiality` — sem excecoes, sem override por chunk
- Justificativa: classificacoes mistas por chunk sao impossiveis de auditar, alto risco de erro humano, regra simples de entender, implementar e auditar
- Se um documento tem partes com niveis diferentes, a solucao e **dividir em documentos separados**
- Na Base Vetorial, o chunk armazena `confidentiality` (herdado) e `document_id` (para rastreabilidade), permitindo filtro pre-retrieval direto no chunk

**Cadencia de revisao de classificacoes:**

Ver DOC-C02: Politica de Revisao de Dados para o detalhamento de cadencias (continua, mensal, trimestral, semestral) e procedimentos de reclassificacao.

### Pilar 2 — Filtro Pre-Retrieval (Inviolavel)

**Regra fundamental:** o filtro de confidencialidade **deve** ser aplicado **antes** da busca vetorial. Nao depois. Nao "junto". **Antes.**

**Por que pre-retrieval e nao pos-retrieval?**

- **Pos-retrieval (incorreto):** busca vetorial retorna chunks sem filtro, depois remove os nao autorizados. **Problema:** chunks confidenciais ja foram carregados em memoria. Qualquer falha (bug, log verbose, dump de debug) ja constitui vazamento. Alem disso: resultado com menos chunks que o esperado, ranking distorcido, e inferencia de existencia de dados confidenciais
- **Pre-retrieval (correto):** filtro aplicado como clausula WHERE antes da busca vetorial. Chunks confidenciais **nunca** saem do armazenamento. Ranking feito sobre o universo correto. Sem vazamento por inferencia

**Mapeamento perfil → niveis permitidos:**

- **Analyst:** `['public', 'internal']`
- **Manager:** `['public', 'internal', 'restricted']`
- **Director:** `['public', 'internal', 'restricted', 'confidential']`

O filtro pre-retrieval deve ser **inviolavel**:

- Nao pode ser desabilitado por parametro
- Nao pode ser ignorado por flag de debug
- Nao pode ser bypassado por role de admin
- Deve ser implementado na camada de infraestrutura (wrapper/middleware que SEMPRE injeta o filtro), nao na camada de aplicacao

**Filtros adicionais (complementares ao confidentiality):**

- domain: restringir busca a dominios do usuario
- system: restringir a sistemas com acesso
- team: restringir a documentos de times do usuario
- valid_from/valid_until: filtro temporal ([[BETA-001]], secao 2.6)

O filtro de confidentiality e sempre o primeiro e mais critico.

**Validacao do filtro:** testes unitarios, de integracao e de regressao devem garantir ZERO data leakage. Detalhamento em SPEC-C01: Checklist de Seguranca LLM.

### Pilar 3 — Autenticacao Evolutiva

**Fases 1 e 2 — API Key:**

- Cada usuario/agente recebe API Key unica associada a um perfil
- Controles: expiracao (max 90 dias), rotacao obrigatoria, revogacao imediata, registro de uso, rate limiting
- Justificativa: simplicidade, velocidade, suficiente para poucos usuarios iniciais, custo zero de infraestrutura adicional
- Limitacoes conhecidas: sem SSO, sem MFA, gestao manual nao escala, sem federacao de identidade

**Fases 3+ — JWT via IdP Corporativo (OIDC/SAML):**

- Autenticacao via IdP corporativo (Azure AD, Keycloak)
- Token JWT com claims: sub, name, email, groups, department
- Justificativa da migracao: escalabilidade, MFA via IdP, lifecycle gerenciado pelo RH, identidade inequivoca, SSO
- O caminho de migracao API Key → JWT e detalhado em RNB-C03: Migracao Auth API Key JWT

**MCP Server — autenticacao:**

- MCP Servers autenticam usando service account com JWT
- Cada MCP Server tem perfil de acesso proprio (scoped tokens com dominios, niveis de confidencialidade e rate limits especificos)
- Auditoria registra agente de origem

**Revogacao de acesso:**

- **Downgrade de perfil**: efeito imediato na proxima query (filtro usa perfil atual, sem cache de resultados)
- **Remocao de usuario**: API Key revogada imediatamente; JWT invalidado via blocklist (ou aguardar TTL curto — max 15 min); cache purgado; sessoes encerradas; registro de auditoria
- **Reclassificacao de documento**: requer re-promocao via pipeline ([[BETA-001]]); chunks atualizados no proximo refresh da Base Vetorial; reclassificacoes urgentes acionam refresh imediato

### Pilar 4 — Autorizacao Evolutiva

**Fase 1 (MVP) — Perfil unico "Internal":**

- Todos os usuarios acessam public + internal
- Documentos restricted e confidential **nao sao ingeridos** na Base Vetorial
- O risco e controlado pela exclusao de dados sensiveis da ingestao

**Fase 2+ — Segregacao por Bases Vetoriais (KBs por Confidencialidade):**

Bases Vetoriais separadas por nivel, cada uma com MCP Server proprio:

| Knowledge Base | Base Vetorial | MCP Server | Acesso |
|---------------|---------------|------------|--------|
| kb-public-internal | Base Vetorial A | MCP publico | Todos os usuarios |
| kb-restricted | Base Vetorial B | MCP restrito | Manager, Director, agentes autorizados |
| kb-confidential | Base Vetorial C | MCP confidencial | Director, compliance officers |

Justificativa: zero risco de data leakage via query (dados em bases fisicamente separadas), controle binario (acesso ao MCP ou nao), auditabilidade na camada de infraestrutura, escalabilidade (nova classificacao = nova KB + novo MCP).

**NOTA:** este modelo merece ADR proprio para detalhar segregacao de KBs, estrategia de deployment e sincronizacao de schemas entre bases.

**Fase 2 — RBAC (Role-Based Access Control):**

4 perfis pre-definidos com mapeamento para niveis de confidencialidade:

| Perfil | Niveis de acesso | Descricao |
|--------|-----------------|-----------|
| **Analyst** | public, internal | Devs, analistas, suporte |
| **Manager** | public, internal, restricted | Gestores, tech leads |
| **Director** | todos (confidential com justificativa) | Diretores, C-level, compliance |
| **AI_Agent** | configuravel por instancia | Agentes de IA via MCP |

Justificativa de RBAC na Fase 2: Fase 1 tem poucos usuarios com mesmo perfil; RBAC requer tabelas de usuarios/perfis; Fase 2 introduz filtros por sistema/modulo (momento natural).

**Fase 3+ — ABAC (Attribute-Based Access Control):**

- Decisao de acesso baseada em atributos do usuario (role, department, team, location), do recurso (confidentiality, domain, system, doc_type) e do contexto (time, ip_address, mfa_verified, session_duration)
- Justificativa: RBAC nao escala para regras complexas (explosao de roles); ABAC permite politicas declarativas e auditaveis; requisito BACEN de controle granular; padrao NIST SP 800-162. RBAC e subset de ABAC — migracao incremental

**Auditoria (presente em todas as fases):**

Cada query gera registro contendo: timestamp, user_id, user_role, query, filtros aplicados, chunks retornados (com chunk_id, confidentiality, document_id), latencia, source_ip, agent_id, mcp_server. Retencao: minimo 5 anos (requisito BACEN). Formato: JSON Lines em sistema de logs corporativo.

**Controle de acesso para repositorios:**

- **rag-workspace** (read-write): POs e especialistas editam .beta.md; pipeline de IA gera .beta.md; pasta sources/ com acesso restrito (PII)
- **rag-knowledge-base** (read-only para todos, write via pipeline): escrita exclusiva via service account com PR aprovado por PO + Arquiteto

### Pilar 5 — Protecao contra Prompt Injection

Decisao: adotar 5 camadas de protecao obrigatorias, implementadas como defesa em profundidade:

1. **Sanitizacao de input**: limpar e validar a query antes de enviar a LLM. Remover caracteres de controle, detectar padroes de injection, limitar tamanho (max 2000 chars), rejeitar inputs com Markdown/HTML que confundam separacao instrucao/dados. Primeira linha de defesa
2. **Separacao de system prompt**: system prompt **nunca** concatenado com input do usuario. Delimitadores claros entre `[SYSTEM]`, `[USER QUERY]` e `[CONTEXT]`. Contexto (chunks) injetado em secao separada
3. **Validacao de output**: verificar resposta da LLM antes de entregar ao usuario. Detectar padroes de PII (CPF, CNPJ, contas bancarias, tokens), trechos de system prompt. Se detectado, substituir por resposta generica e registrar incidente. Ultima linha de defesa
4. **Rate limiting por usuario**: Analyst: 100/hora, 500/dia; Manager: 150/hora, 750/dia; Director: 200/hora, 1000/dia; AI_Agent: configuravel (default 200/hora). Torna extracao lenta e detectavel
5. **Monitoramento de anomalias**: queries com termos suspeitos, sequencias similares, dominios fora do perfil, volume anormal, respostas que acionaram validacao repetidamente. Alertas em tempo real

Detalhamento de checklists e procedimentos em SPEC-C01: Checklist de Seguranca LLM.

### Pilar 6 — LGPD e Conformidade Regulatoria

**Minimizacao de dados:**

- Pipeline de ingestao deve ter etapa de anonimizacao para documentos com PII antes de gerar embeddings
- Dados originais ficam apenas nas fontes brutas (Fase 1), com controle de acesso separado
- Excecao: documentos cuja finalidade e conter dados pessoais devem ser classificados como RESTRICTED ou CONFIDENTIAL
- Detalhamento do pipeline em RNB-C04: Anonimizacao PII

**Direito a exclusao (art. 18, VI, LGPD):**

- O titular pode solicitar exclusao dos seus dados
- Desafio tecnico: embeddings nao sao reversiveis — requer indice de metadados mapeando PII → chunks/documentos
- Logs de auditoria **nao** sao alterados (requisito legal) mas sao marcados como "dados do titular X excluidos"
- Procedimento detalhado em RNB-C05: Incidente PII (de ADR-008)

**Residencia de dados (conforme [[BETA-002]]):**

- PUBLIC e INTERNAL: armazenamento em regiao Brasil ou com adequacao LGPD (Europa/GDPR); processamento em cloud permitido
- RESTRICTED e CONFIDENTIAL: processamento e armazenamento **exclusivamente** em infraestrutura nacional (on-premise ou cloud soberana em territorio brasileiro)
- Implicacao: Base Vetorial com dados de todos os niveis **deve** estar on-premise, ou usar duas instancias separadas (cloud para public+internal, on-premise para restricted+confidential)

**Requisitos BACEN para uso de cloud (Resolucao BCB 85/2021 e 4.893/2021):**

- Comunicacao previa ao BACEN sobre contratacao de servicos de cloud
- Plano de contingencia e continuidade
- Possibilidade de auditoria pelo BACEN
- Recomendacao MVP: LLM on-premise (modelos open source) para evitar necessidade de comunicacao ao BACEN; migrar para cloud apos processo de comunicacao completo

## 3. Alternativas Descartadas

### 3.1. Seguranca apenas por prompt (instrucoes a LLM)

- **Descricao**: confiar nas instrucoes do system prompt para que a LLM nao revele dados confidenciais
- **Rejeicao**: LLMs nao sao deterministicas; prompt injection pode sobrescrever instrucoes; impossivel auditar ou garantir compliance; viola principio basico de que controle de acesso deve estar na infraestrutura, nao na aplicacao

### 3.2. Classificacao por chunk (nao por documento)

- **Descricao**: permitir que cada chunk tenha classificacao independente do documento pai
- **Rejeicao**: complexidade inviavel de gestao; alto risco de erro humano; auditoria muito mais complexa; solucao correta e dividir em documentos separados

### 3.3. Autenticacao unica (so JWT, desde o MVP)

- **Descricao**: implementar JWT via IdP corporativo desde a fase 1
- **Rejeicao**: dependencia de infraestrutura para configurar IdP; atrasa o MVP; overhead desnecessario para 5-10 usuarios iniciais; principio YAGNI

### 3.4. ABAC desde o inicio (sem fase RBAC)

- **Descricao**: implementar ABAC diretamente, pulando RBAC
- **Rejeicao**: requer engine de politicas (OPA, Cedar); definir politicas ABAC requer entender padroes de acesso reais; RBAC com 4 perfis e suficiente para fases 1-2; migracao RBAC→ABAC e incremental

### 3.5. Criptografia como unico controle (sem classificacao)

- **Descricao**: proteger dados apenas com criptografia, sem classificacao de confidencialidade
- **Rejeicao**: criptografia protege contra acesso nao autorizado ao storage, mas nao resolve controle de acesso logico; sem classificacao o filtro pre-retrieval nao tem criterio; LGPD e BACEN exigem controle granular. Criptografia e adotada como controle **complementar** (AES-256 para confidential), nunca como controle unico

## 4. Consequencias

### 4.1. Positivas

- **Defesa em profundidade**: 6 pilares complementares, falha em um nao compromete os outros
- **Compliance regulatorio**: alinhado com LGPD, BACEN e CVM
- **Evolutivo**: complexidade adicionada gradualmente conforme necessidade
- **Auditavel**: cada query tem registro completo
- **Flexivel**: perfil AI_Agent permite configuracao granular por agente

### 4.2. Negativas / Trade-offs

- Filtro pre-retrieval reduz universo de busca para perfis restritos (Analyst ve menos documentos, pode ter respostas de menor qualidade)
- Pipeline de anonimizacao adiciona latencia na ingestao
- Duas instancias da Base Vetorial (cloud + on-prem) aumentam custo e complexidade operacional
- Auditoria com retencao de 5 anos gera volume significativo de logs
- Migracao API Key → JWT requer planejamento de transicao

### 4.3. Riscos

| Risco | Mitigacao |
|-------|-----------|
| Falso negativo na anonimizacao: PII nao detectado e ingerido | Revisao humana para confidence < 90%, auditoria periodica |
| Prompt injection zero-day: ataque novo que bypassa sanitizacao | Filtro pre-retrieval garante que dados confidenciais nunca chegam ao contexto de usuarios nao autorizados |
| Classificacao incorreta de documento: humano classifica como PUBLIC algo RESTRICTED | Revisao no pipeline de promocao (Fase 3, [[BETA-001]]) |
| Sobrecarga de auditoria | Alertas automaticos para padroes anomalos, revisao humana apenas para alertas |
| Janela de exposicao na reclassificacao: entre reclassificacao no repositorio e refresh da Base Vetorial, chunks podem estar desatualizados | Reclassificacoes que aumentam restricao acionam refresh imediato; as que diminuem aguardam ciclo normal |

## 5. Implementacao

| Fase | Entrega | Dependencia |
|------|---------|-------------|
| **1-MVP** | Campo confidentiality no front matter, filtro pre-retrieval basico (WHERE), API Key para autenticacao, log basico de queries | [[BETA-001]] Fase 1 |
| **2** | 4 perfis RBAC, mapeamento perfil → niveis de acesso, pipeline de anonimizacao (NER + regex), validacao de output basica, segregacao por KBs/MCPs | [[BETA-001]] Fase 2 |
| **3** | JWT via IdP corporativo (OIDC), migracao API Key → JWT, ABAC basico (dominio + confidentiality), sanitizacao de input avancada, rate limiting por usuario | [[BETA-001]] Fase 3, IdP configurado |
| **4** | ABAC completo (atributos de contexto), monitoramento de anomalias, auditoria com retencao de 5 anos, procedimento de exclusao LGPD testado, comunicacao ao BACEN (se cloud) | [[BETA-001]] Fase 4 |

**Responsaveis:**

- Arquiteto: definicao de politicas, schemas, classificacao
- Seguranca da Informacao: validacao de controles, pen testing
- Engenharia: implementacao de filtros, autenticacao, auditoria
- DPO / Compliance: validacao LGPD, comunicacao BACEN
- Ops / Infra: configuracao de rede segregada, IdP, logs

Detalhamento de procedimentos nos documentos extraidos:

- RNB-C03: Migracao Auth API Key JWT (passos de migracao Fase 3)
- RNB-C04: Anonimizacao PII (pipeline NER + regex + validacao)
- SPEC-C01: Checklist de Seguranca LLM (testes, validacao de filtros)

## 6. Referencias

**Internas:**

- [[BETA-001]] — Pipeline de Geracao de Conhecimento em 4 Fases
- [[BETA-002]] — Soberania de Dados: Trilha Cloud vs. On-Premise
- [[BETA-003]] — Modelo de Dados da Base Vetorial
- ADR-008 — Governanca e Ciclo de Vida (cadencias de curadoria)
- B14 — Seguranca e Soberania de Dados (blueprint)
- B04 — Metadados e Governanca (front matter)

**Documentos extraidos deste ADR:**

- SPEC-C01: Checklist de Seguranca LLM
- DOC-C02: Politica de Revisao de Dados
- RNB-C03: Migracao Auth API Key JWT
- RNB-C04: Anonimizacao PII
- RNB-C05: Incidente PII (de ADR-008)

**Externas:**

- [LGPD — Lei 13.709/2018](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm)
- [Resolucao BCB 85/2021 — Politica de seguranca cibernetica](https://www.bcb.gov.br/estabilidadefinanceira/exibenormativo?tipo=Resolu%C3%A7%C3%A3o%20BCB&numero=85)
- [Resolucao 4.893/2021 — Contratacao de servicos de cloud](https://www.bcb.gov.br/estabilidadefinanceira/exibenormativo?tipo=Resolu%C3%A7%C3%A3o&numero=4893)
- [NIST SP 800-162 — Guide to ABAC](https://csrc.nist.gov/publications/detail/sp/800-162/final)
- [OWASP LLM Top 10 — Prompt Injection](https://owasp.org/www-project-top-10-for-large-language-model-applications/)
- CVM Instrucao 358/2002 — Divulgacao de informacao relevante (MNPI)

<!-- conversion_quality: 95 -->
