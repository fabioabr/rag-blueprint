---
id: ADR-004
doc_type: adr
title: "Estratégia de Segurança e Classificação de Dados"
system: RAG Corporativo
module: Segurança
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-21
tags:
  - adr
  - seguranca
  - classificacao-dados
  - lgpd
  - filtro-pre-retrieval
  - autenticacao
  - autorizacao
  - prompt-injection
  - bacen
  - rbac
aliases:
  - "ADR-004"
  - "Seguranca RAG"
  - "Classificacao de Confidencialidade"
  - "Seguranca e Classificacao de Dados"
  - "Filtro Pre-Retrieval"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-kb/beta/ADR-004_seguranca_classificacao_dados.beta.md"
source_beta_ids:
  - "BETA-004"
conversion_pipeline: promotion-pipeline-v1
conversion_quality: 100
converted_at: 2026-03-22
qa_score: 96
qa_date: 2026-03-22
qa_status: passed
created_at: 2026-03-21
updated_at: 2026-03-22
valid_from: 2026-03-21
valid_until: null
---

# ADR-004 — Estratégia de Segurança e Classificação de Dados

| Campo       | Valor                                                         |
|-------------|---------------------------------------------------------------|
| **Status**  | Accepted                                                      |
| **Data**    | 21/03/2026                                                    |
| **Decisor** | fabio (arquitetura)                                           |
| **Escopo**  | Segurança, classificação de dados, filtros pré-retrieval, autenticação, autorização, LGPD |

**Referências cruzadas:**

- [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]]: Pipeline de Geração de Conhecimento em 4 Fases
- [[ADR-002_soberania_dados_cloud_vs_onprem|ADR-002]]: Soberania de Dados — Trilha Cloud vs. On-Premise
- [[ADR-003_modelo_dados_base_vetorial|ADR-003]]: Modelo de Dados da Base Vetorial
- [[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]]: Pipeline de Ingestão
- [[ADR-007_retrieval_hibrido_agentes|ADR-007]]: Retrieval Híbrido e Agentes
- [[ADR-008_governanca_ciclo_vida_rollback|ADR-008]]: Governança e Ciclo de Vida

---

## Sumário

Este ADR define a estratégia de segurança e classificacao de dados para o RAG Corporativo, baseada em **6 pilares complementares**: (1) classificacao de dados, (2) filtro pre-retrieval inviolavel, (3) autenticacao evolutiva, (4) autorizacao evolutiva, (5) protecao contra prompt injection, e (6) conformidade LGPD e regulatoria. Cada pilar endereca uma camada diferente do problema e juntos formam defesa em profundidade.

**Depende de:** [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] (Pipeline de 4 Fases), [[ADR-002_soberania_dados_cloud_vs_onprem|ADR-002]] (Soberania de Dados)
**Relaciona-se com:** [[ADR-003_modelo_dados_base_vetorial|ADR-003]] (Modelo de Dados), [[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]] (Pipeline de Ingestao), [[ADR-007_retrieval_hibrido_agentes|ADR-007]] (Retrieval), [[ADR-008_governanca_ciclo_vida_rollback|ADR-008]] (Governanca e Ciclo de Vida)

## 1. Contexto

O projeto RAG Corporativo esta sendo construido dentro de uma instituicao financeira regulada pelo **BACEN**, **CVM** e pela **LGPD** (Lei 13.709/2018). A base de conhecimento contera documentos que vao desde manuais tecnicos publicos ate informacoes altamente confidenciais.

**Problema fundamental:** o sistema RAG deve responder perguntas de diferentes perfis de usuario sem **jamais** expor dados que aquele perfil nao tem direito de ver.

Complexidades envolvidas:

- **(a)** Busca vetorial sem filtro de acesso pode retornar chunks confidenciais — prompts **nao** sao mecanismo de seguranca
- **(b)** LLMs sao vulneraveis a prompt injection — se o chunk confidencial ja esta no contexto, nenhuma instrucao de sistema garante que a LLM nao vai vaza-lo
- **(c)** [[ADR-002_soberania_dados_cloud_vs_onprem|ADR-002]] define que dados RESTRICTED e CONFIDENTIAL devem ser processados on-premise — pipelines de processamento separados por classificacao
- **(d)** MCP Servers criam superficies de ataque adicionais — cada um precisa autenticacao e autorizacao proprias
- **(e)** LGPD exige mecanismo para identificar e remover dados de pessoa especifica (right to erasure)

### Alinhamento com ADR-001 (Pipeline de 4 Fases)

A seguranca permeia **todas** as 4 fases do pipeline definido na [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]]:

- **Fase 1** (Selecao de insumos): fontes brutas podem conter PII — controle de acesso ao rag-workspace
- **Fase 2** (Mineracao .beta.md): campo `confidentiality` no front matter leve roteia o documento pela trilha correta (cloud vs on-premise, conforme [[ADR-002_soberania_dados_cloud_vs_onprem|ADR-002]])
- **Fase 3** (Promocao .md): pipeline valida classificacao no gate de qualidade (QA score >= 90%). Blocos LOCKED preservados
- **Fase 4** (Ingestao na Base Vetorial): filtro pre-retrieval aplicado nos chunks, heranca de confidentiality do documento pai

## 2. Decisao

### Pilar 1 — Classificacao de Dados (4 Niveis)

Cada documento recebe uma classificacao de confidencialidade no campo `confidentiality` do front matter. Essa classificacao e **obrigatoria** e determina quem pode acessar, onde pode ser processado e como e tratado pelo pipeline.

| Nivel | Label | Quem pode acessar | Onde pode ser processado | Exemplos |
|-------|-------|-------------------|--------------------------|----------|
| 1 | **PUBLIC** | Qualquer usuario autenticado, incluindo agentes de IA | Cloud APIs sem restricoes, on-premise | Documentacao publica de APIs, tutoriais, manuais de ferramentas, glossario de termos tecnicos nao proprietarios |
| 2 | **INTERNAL** | Qualquer colaborador autenticado (Analyst, Manager, Director). Agentes de IA com perfil interno | Cloud APIs **com controles** (DPA, sem uso para treinamento, logs). On-premise sem restricoes | Documentacao de sistemas internos, ADRs, glossario interno, processos operacionais, metricas de performance |
| 3 | **RESTRICTED** | Manager (com restricao por dominio), Director (acesso amplo), Agentes de IA com perfil explicito | **Exclusivamente on-premise** (BACEN Res. 4.893/2021 e BCB 85/2021) | Post-mortems de incidentes, auditorias internas, estrategias de produto, dados de compliance e PLD |
| 4 | **CONFIDENTIAL** | Director (com justificativa em log de auditoria). Agentes de IA: **acesso negado por padrao** | **Exclusivamente em ambiente isolado on-premise** (rede segregada, AES-256, TLS 1.3, logs 5 anos, monitoramento real-time) | Dados pessoais sensiveis (art. 5 LGPD), investigacoes internas, MNPI (CVM), credenciais, estrategias de precificacao, comunicacoes com reguladores |

**Heranca de classificacao (Document → Chunk):**

- `chunk.confidentiality = documento.confidentiality` — sem excecoes, sem override por chunk
- Se um documento tem partes com niveis diferentes, a solucao e **dividir em documentos separados**
- Na Base Vetorial, o chunk armazena `confidentiality` herdado + `document_id` para rastreabilidade

**Cadencia de revisao de classificacoes** (baseada no ADR-008):

- **Continua**: owners monitoram classificacao; reclassificacoes urgentes tratadas como incidente
- **Mensal**: revisao de documentos recem-ingeridos
- **Trimestral**: auditoria completa de RESTRICTED e CONFIDENTIAL (Compliance Officer participa)
- **Semestral**: revisao alinhada com mudancas regulatorias (BACEN, LGPD, CVM)

### Pilar 2 — Filtro Pre-Retrieval (Inviolavel)

**Regra fundamental:** o filtro de confidencialidade **deve** ser aplicado **antes** da busca vetorial. Nao depois. Nao "junto". **Antes.**

**Por que pre-retrieval e nao pos-retrieval?**

- **Pos-retrieval (incorreto):** busca vetorial retorna top-K sem filtro → sistema verifica acesso → remove nao autorizados. **Problema:** chunks confidenciais ja foram carregados em memoria; ranking distorcido; resultado pode ter menos chunks que o esperado; inferencia de existencia de dados por padrao de filtragem
- **Pre-retrieval (correto):** sistema identifica perfil e niveis de acesso → filtro como clausula WHERE → busca vetorial retorna top-K dentre os acessiveis. **Beneficio:** chunks confidenciais nunca saem do armazenamento

**Implementacao:**

```python
class SecureRetriever:
    def search(self, query, user_context):
        # Filtro INJETADO automaticamente — nao e opcional
        allowed_levels = self._get_allowed_levels(user_context)
        return self._vector_search(
            query,
            pre_filter={'confidentiality': {'$in': allowed_levels}}
        )
    # Nao existe metodo de busca sem filtro nesta classe
```

Mapeamento perfil → niveis:

- **Analyst:** `['public', 'internal']`
- **Manager:** `['public', 'internal', 'restricted']`
- **Director:** `['public', 'internal', 'restricted', 'confidential']`

O filtro pre-retrieval deve ser **inviolavel**: nao pode ser desabilitado por parametro, ignorado por flag de debug, bypassado por role de admin. Implementado na camada de infraestrutura, nao na aplicacao.

**Filtros adicionais:** domain, system, team, valid_from/valid_until (complementares ao filtro de confidentiality).

**Testes obrigatorios:**

1. **Testes unitarios**: para cada perfil, verificar que NENHUM chunk retornado tem confidentiality acima do nivel de acesso
2. **Testes de integracao**: golden set de queries com diferentes perfis — verificar zero data leakage
3. **Testes de regressao**: apos qualquer alteracao na logica de filtragem, re-executar suite completa

### Pilar 3 — Autenticacao Evolutiva

**Fases 1 e 2 — API Key:**

- Cada usuario/agente recebe API Key unica associada a um perfil
- Controles: expiracao (max 90 dias), rotacao obrigatoria, revogacao imediata, registro de uso, rate limiting
- Limitacoes: sem SSO, sem MFA, gestao manual nao escala

**Fases 3+ — JWT via IdP Corporativo (OIDC/SAML):**

- Autenticacao via IdP corporativo (Azure AD, Keycloak)
- Token JWT com claims: sub, name, email, groups, department
- Beneficios: escalabilidade, MFA, lifecycle via RH, SSO
- Caminho de migracao: JWT em paralelo → migrar usuarios → deprecar API Keys (30 dias) → remover. API Keys mantidas apenas para agentes de IA sem IdP

**MCP Server — autenticacao:**

- Service account com JWT e escopo limitado (dominios, niveis de confidencialidade, rate limits)
- Auditoria de cada query com agente de origem

**Revogacao de acesso:**

- **Downgrade de perfil**: efeito imediato na proxima query (sem cache de resultados)
- **Remocao de usuario**: API Key revogada, JWT invalidado via blocklist (TTL max 15 min), cache purgado, sessoes encerradas
- **Reclassificacao de documento**: chunks atualizados no proximo ciclo de ingestao; reclassificacoes urgentes acionam refresh imediato

### Pilar 4 — Autorizacao Evolutiva

**Fase 1 (MVP) — Perfil unico "Internal":**

- Todos os usuarios acessam public + internal
- Documentos restricted e confidential **nao sao ingeridos** na Fase 1
- Risco controlado pela exclusao de dados sensiveis

**Fase 2 — Segregacao por Bases Vetoriais + RBAC:**

Modelo de segregacao por KBs:

| Knowledge Base | Base Vetorial | MCP Server | Acesso |
|---------------|---------------|------------|--------|
| kb-public-internal | Base Vetorial A | MCP publico | Todos os usuarios |
| kb-restricted | Base Vetorial B | MCP restrito | Manager, Director, agentes autorizados |
| kb-confidential | Base Vetorial C | MCP confidencial | Director, compliance officers |

4 perfis RBAC:

| Perfil | Niveis de acesso | Descricao |
|--------|-----------------|-----------|
| **Analyst** | public, internal | Desenvolvedores, analistas de negocio, suporte |
| **Manager** | public, internal, restricted | Gestores, tech leads (filtro de dominio adicional recomendado) |
| **Director** | public, internal, restricted, confidential | Diretores, C-level (confidential requer justificativa) |
| **AI_Agent** | configuravel | Niveis definidos na configuracao do agente por instancia |

**Fase 3+ — ABAC (Attribute-Based Access Control):**

- Decisao baseada em atributos do usuario (role, department, team, location), do recurso (confidentiality, domain, system, doc_type) e do contexto (time, ip_address, mfa_verified)
- Regras como: "Manager do dominio Financeiro ve restricted de Financeiro mas nao de RH"

**Auditoria (todas as fases):**

Cada query gera registro com: timestamp, user_id, user_role, query, filters_applied, chunks_returned, latency_ms, source_ip, agent_id, mcp_server. Retencao minima de 5 anos (requisito BACEN).

**Controle de acesso a repositorios:**

- **rag-workspace** (read-write): POs, analistas e pipeline de IA editam .beta.md. Pasta `sources/` com PII restrita a service accounts e DPO
- **rag-knowledge-base** (read-only): escrita exclusivamente via service account com PR aprovado por PO + Arquiteto

### Pilar 5 — Protecao contra Prompt Injection

Medidas obrigatorias:

1. **Sanitizacao de input**: remover caracteres de controle, detectar padroes de injection, limitar tamanho (max 2000 chars), rejeitar Markdown/HTML malicioso
2. **Separacao de system prompt**: delimitadores claros (`[SYSTEM INSTRUCTIONS]`, `[USER QUERY]`, `[CONTEXT]`), system prompt nunca concatenado com input, contexto em secao separada
3. **Validacao de output**: detectar PII na resposta (CPF, CNPJ, contas), detectar trechos do system prompt, substituir por resposta generica e registrar incidente
4. **Rate limiting por usuario**: Analyst 100/h, Manager 150/h, Director 200/h, AI_Agent configuravel. Alerta a 80% do limite
5. **Monitoramento de anomalias**: queries com "system prompt"/"ignore", sequencias similares, queries fora do dominio do perfil, volume anormal, respostas que acionam validacao repetidamente

### Pilar 6 — LGPD e Conformidade Regulatoria

**Minimizacao de dados:**

- Pipeline de ingestao com etapa de anonimizacao para documentos com PII (antes de embeddings)
- PII anonimizado: CPF → `[CPF_ANONIMIZADO]`, nomes → `[NOME_ANONIMIZADO]`, etc.
- Dados originais ficam apenas nas fontes brutas (Fase 1) com controle de acesso separado

**Direito a exclusao (art. 18, VI, LGPD):**

1. Receber solicitacao via DPO
2. Identificar documentos com dados do titular (busca por nome, CPF, email)
3. Remover ou re-anonimizar conforme o caso (documento exclusivo vs. mencao entre outros)
4. Confirmar exclusao com evidencia de remocao de todas as camadas

**Residencia de dados (conforme [[ADR-002_soberania_dados_cloud_vs_onprem|ADR-002]]):**

- PUBLIC e INTERNAL: cloud permitida (regiao Brasil ou adequacao LGPD)
- RESTRICTED e CONFIDENTIAL: **exclusivamente** infraestrutura nacional (on-premise ou cloud soberana)

**Requisitos BACEN (Res. BCB 85/2021 e 4.893/2021):**

- Comunicacao previa ao BACEN sobre cloud para dados relevantes
- Plano de contingencia, auditabilidade pelo BACEN, contrato com provedor
- Recomendacao para MVP: LLM on-premise (Ollama) para evitar comunicacao ao BACEN

**Pipeline de anonimizacao (4 etapas):**

1. **Deteccao**: NER + regex para PERSON, CPF, CNPJ, PHONE, EMAIL, ADDRESS, BANK_ACCOUNT. Thresholds: >=90% auto, 60-89% revisao humana, <60% ignora
2. **Classificacao**: PII direta (sempre anonimizar), PII indireta (avaliar combinacoes), dado sensivel art. 5 LGPD (sempre)
3. **Anonimizacao**: substituicao por placeholder consistente no documento, tabela de correspondencia em cofre seguro
4. **Validacao**: verificar ausencia de PII remanescente, consistencia de placeholders, registro em log

## 3. Alternativas Descartadas

### 3.1. Seguranca apenas por prompt

- **Descricao**: confiar nas instrucoes do system prompt para que a LLM nao revele dados confidenciais
- **Rejeicao**: LLMs nao sao deterministicas; prompt injection sobrescreve instrucoes; impossivel auditar para compliance; controle de acesso deve estar na infraestrutura

### 3.2. Classificacao por chunk (nao por documento)

- **Descricao**: permitir classificacao independente por chunk
- **Rejeicao**: complexidade de gestao inviavel (50 chunks com classificacoes mistas), alto risco de erro humano, auditoria complexa. Solucao correta: dividir em documentos separados

### 3.3. Autenticacao unica (JWT desde MVP)

- **Descricao**: JWT via IdP corporativo desde a fase 1
- **Rejeicao**: dependencia de infraestrutura, atrasa MVP, overhead desnecessario para 5-10 usuarios iniciais

### 3.4. ABAC desde o inicio (sem RBAC)

- **Descricao**: implementar ABAC diretamente, pulando RBAC
- **Rejeicao**: requer engine de politicas (OPA, Cedar), definir politicas requer entender padroes de acesso reais, RBAC com 4 perfis suficiente para fases 1-2

### 3.5. Criptografia como unico controle

- **Descricao**: proteger dados apenas com criptografia, sem classificacao
- **Rejeicao**: criptografia nao resolve controle de acesso logico; sem classificacao, filtro pre-retrieval nao tem criterio; LGPD e BACEN exigem controle granular. Criptografia adotada como controle **complementar** (AES-256 para confidential)

## 4. Consequencias

### 4.1. Positivas

- **Defesa em profundidade**: 6 pilares complementares, falha em um nao compromete os outros
- **Compliance regulatorio**: alinhado com LGPD, BACEN e CVM
- **Evolutivo**: complexidade adicionada gradualmente conforme necessidade
- **Auditavel**: cada query com registro completo
- **Flexivel**: perfil AI_Agent com configuracao granular por agente

### 4.2. Negativas / Trade-offs

- Filtro pre-retrieval pode reduzir universo de busca para perfis restritos (Analyst ve menos, respostas potencialmente piores)
- Pipeline de anonimizacao adiciona latencia na ingestao
- Duas instancias da Base Vetorial (cloud + on-prem) aumentam custo e complexidade
- Auditoria com retencao de 5 anos gera volume significativo de logs
- Migracao de API Key para JWT requer planejamento de transicao

### 4.3. Riscos

| Risco | Mitigacao |
|-------|-----------|
| Falso negativo na anonimizacao (PII nao detectado) | Revisao humana para confidence <90%, auditoria periodica por amostragem |
| Prompt injection zero-day | Filtro pre-retrieval garante que dados confidenciais nunca chegam ao contexto de usuarios nao autorizados |
| Classificacao incorreta (PUBLIC quando deveria ser RESTRICTED) | Revisao de classificacao no pipeline de promocao (Fase 3), checklist |
| Sobrecarga de auditoria (muitos logs, ninguem revisa) | Alertas automaticos para padroes anomalos, revisao humana apenas para alertas |
| Re-ingestao com mudanca de classificacao | Pipeline verifica se classificacao mudou e aciona refresh imediato na Base Vetorial |
| Janela de exposicao na reclassificacao | Reclassificacoes que aumentam restricao acionam refresh imediato; diminuicoes aguardam ciclo normal |

## 5. Implementacao

| Fase | Entregas | Dependencia |
|------|----------|-------------|
| **1-MVP** | Campo confidentiality no front matter, filtro pre-retrieval basico (WHERE), API Key, log basico de queries | [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] Fase 1 |
| **2** | 4 perfis RBAC, mapeamento perfil→niveis, pipeline de anonimizacao (NER + regex), validacao de output basica | [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] Fase 2 |
| **3** | JWT via IdP (OIDC), migracao API Key→JWT, ABAC basico (dominio + confidentiality), sanitizacao avancada, rate limiting | [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] Fase 3 + IdP configurado |
| **4** | ABAC completo (atributos de contexto), monitoramento de anomalias, auditoria 5 anos, procedimento de exclusao LGPD testado, comunicacao ao BACEN | [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] Fase 4 |

**Responsaveis:** Arquiteto (politicas, schemas), Seguranca da Informacao (validacao, pen testing), Engenharia (filtros, autenticacao, auditoria), DPO/Compliance (LGPD, BACEN), Ops/Infra (rede segregada, IdP, logs).

## 6. Referencias

**Internas:**

- [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] — Pipeline de Geracao de Conhecimento em 4 Fases
- [[ADR-002_soberania_dados_cloud_vs_onprem|ADR-002]] — Soberania de Dados: Cloud vs. On-Premise
- [[ADR-003_modelo_dados_base_vetorial|ADR-003]] — Modelo de Dados da Base Vetorial
- [[ADR-008_governanca_ciclo_vida_rollback|ADR-008]] — Governanca e Ciclo de Vida (cadencias de curadoria)

**Externas:**

- [LGPD — Lei 13.709/2018](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm)
- [Resolucao BCB 85/2021](https://www.bcb.gov.br/estabilidadefinanceira/exibenormativo?tipo=Resolu%C3%A7%C3%A3o%20BCB&numero=85)
- [Resolucao 4.893/2021](https://www.bcb.gov.br/estabilidadefinanceira/exibenormativo?tipo=Resolu%C3%A7%C3%A3o&numero=4893)
- [NIST SP 800-162 — Guide to ABAC](https://csrc.nist.gov/publications/detail/sp/800-162/final)
- [OWASP LLM Top 10 — Prompt Injection](https://owasp.org/www-project-top-10-for-large-language-model-applications/)
- CVM Instrucao 358/2002 — Divulgacao de informacao relevante (MNPI)

---

<!-- QA-MD: inicio -->
## Quality Assurance — .md final

**Revisor:** Pipeline de Promoção QA
**Data:** 22/03/2026
**Fonte:** kb/rag-blueprint-adrs-kb/beta/ADR-004_seguranca_classificacao_dados.beta.md

| Critério | Peso | Nota | Comentário |
|----------|------|------|------------|
| Front matter rico | 25% | 98% | Todos os campos presentes. Title corrigido para incluir acentos ("Estratégia de Segurança e Classificação de Dados"). Campo `status: accepted` fora do enum mas consistente. |
| Completude de conteúdo | 20% | 100% | Todas as seções presentes: Contexto, Decisão (6 Pilares), Alternativas Descartadas, Consequências, Implementação, Referências. Referências cruzadas amplas (6 ADRs). |
| Wikilinks | 10% | 100% | Formato correto [[ADR-NNN_slug\|ADR-NNN]]. Inclui referências a ADR-006, ADR-007, ADR-008 além das adjacentes. |
| Sem artefatos workspace | 15% | 100% | Sem marcadores LOCKED fora de contexto. Referência a "Blocos LOCKED preservados" é contextual. Sem QA-BETA. |
| Compatibilidade Obsidian | 10% | 100% | YAML válido. Tags e aliases como arrays. |
| Linhagem rastreável | 10% | 100% | source_path → .beta.md, source_beta_ids → BETA-004, conversion_pipeline → promotion-pipeline-v1. |
| Clareza e estrutura | 10% | 80% | Hierarquia clara com 6 pilares bem definidos. Tabelas comparativas. Código Python ilustrativo. Porém, **acentuação ausente sistematicamente no corpo** (ex: "estrategia", "seguranca", "classificacao", "autenticacao", "autorizacao"). Title e H1 corrigidos. Impacta legibilidade e busca full-text. |

**Score:** 97.0% — APROVADO para ingestão

**Por que não é 100%:** (1) Campo `status: accepted` fora do enum (-0.5%); (2) Acentuação ausente no corpo do documento (-2.0% sobre peso 10%). Title e H1 corrigidos nesta revisão. Recomendação: re-processar o .beta.md com pipeline de correção ortográfica antes da próxima promoção. (3) Inconsistência de acentuação entre front matter (corrigido) e corpo (sem acentos) = -0.5%.
<!-- QA-MD: fim -->
