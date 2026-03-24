---
id: ADR-C03
doc_type: adr
title: "Runbook: Migração de Autenticação API Key para JWT"
system: RAG Corporativo
module: Migração Auth
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - migração autenticação
  - api key para jwt
  - jwt token
  - oidc openid connect
  - saml autenticação
  - idp corporativo
  - rbac perfis
  - controle acesso
  - coexistência autenticação
  - deprecação api key
  - revogação api key
  - service account
  - mcp server autenticação
  - claims jwt
  - grupos idp
  - azure ad keycloak
  - middleware validação
  - migração ondas
  - rollback migração
  - reclassificação documento
  - blocklist jwt
  - downgrade perfil
  - remoção usuário
  - cache invalidação
  - auditoria claims
  - rate limiting perfil
  - runbook operacional
  - fase 3 roadmap
  - comunicação stakeholders
  - backup configuração
  - early adopters
  - agentes ia autenticação
  - automações autenticação
  - rotação api key
  - exceção documentada
  - checklist pós migração
  - métricas autenticação
  - dashboard autenticação
  - latência jwt validação
  - erros autenticação
  - sessão ativa encerramento
  - ttl token
  - client id secret
  - redirect uri
  - escopos oidc
  - subject claim
  - department claim
  - abac futuro
  - bacen rastreabilidade
  - staging homologação
  - header deprecação
aliases:
  - "ADR-C03"
  - "Migração Auth JWT"
  - "Runbook Migração API Key JWT"
  - "Autenticação Evolutiva RAG"
  - "Migração Autenticação Corporativa"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-C03_migracao_auth_apikey_jwt.beta.md"
source_beta_ids:
  - "BETA-C03"
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

# ADR-C03 — Runbook: Migração de Autenticação API Key para JWT

## 1. Objetivo

Procedimento operacional para migrar a autenticação do RAG Corporativo de API Keys (utilizada nas Fases 1 e 2) para JWT via IdP corporativo (OIDC/SAML), conforme definido no Pilar 3 (Autenticação Evolutiva) da [[ADR-004]].

Este runbook deve ser executado na transição para a Fase 3 do roadmap.

## 2. Pré-Requisitos

Antes de iniciar a migração, todos os itens abaixo devem estar confirmados:

- [ ] **2.1** IdP corporativo configurado e operacional (Azure AD, Keycloak ou equivalente) com suporte a OIDC ou SAML.

- [ ] **2.2** Aplicação RAG registrada no IdP com:
  - Client ID e Client Secret gerados
  - Redirect URIs configurados
  - Escopos definidos (openid, profile, email, groups)

- [ ] **2.3** Claims do JWT definidos e mapeados:
  - `sub` (subject — identificador único do usuário)
  - `name` (nome do usuário)
  - `email` (email corporativo)
  - `groups` (grupos/papéis no IdP)
  - `department` (departamento — para ABAC futuro)

- [ ] **2.4** Mapeamento de grupos do IdP para perfis RBAC do RAG:
  - Grupo "rag-analyst" → perfil Analyst (`public`, `internal`)
  - Grupo "rag-manager" → perfil Manager (`public`, `internal`, `restricted`)
  - Grupo "rag-director" → perfil Director (`public`, `internal`, `restricted`, `confidential`)
  - Grupo "rag-agent-*" → perfil AI_Agent (configurável)

- [ ] **2.5** Ambiente de staging/homologação disponível para testes.

- [ ] **2.6** Lista completa de usuários e agentes ativos com API Key, incluindo: user_id, perfil atual, último uso, agente ou humano.

- [ ] **2.7** Comunicação enviada a todos os usuários com pelo menos 30 dias de antecedência informando sobre a migração.

- [ ] **2.8** Pipeline de ingestão e base vetorial estáveis (nenhuma migração ou re-indexação em andamento).

- [ ] **2.9** Backup da configuração atual de API Keys e mapeamentos.

## 3. Fase de Coexistência (JWT em Paralelo)

Nesta fase, ambos os métodos de autenticação são aceitos simultaneamente. Duração estimada: 30 dias.

### 3.1 Implementar suporte a JWT no backend

- **Responsável:** Dev API/Consumo
- **Atividades:**
  - Adicionar middleware de validação de JWT (verificação de assinatura, expiração, issuer, audience).
  - Implementar extração de claims do JWT para contexto de usuário.
  - Mapear claim "groups" para perfis RBAC existentes.
  - Manter middleware de API Key existente inalterado.
  - Configurar ordem de verificação: JWT primeiro, API Key como fallback.

- **Validação:**
  - Request com JWT válido → aceito, perfil extraído dos claims.
  - Request com API Key válida → aceito, perfil extraído do mapeamento existente.
  - Request sem credencial → rejeitado (401).
  - Request com JWT expirado → rejeitado (401), não fallback para API Key.

### 3.2 Configurar MCP Servers para JWT

- **Responsável:** Dev API/Consumo + Engenheiro de Pipeline
- **Atividades:**
  - Cada MCP Server recebe service account no IdP com JWT e escopo limitado:
    - Domínios permitidos (ex: apenas "financeiro", "tecnologia")
    - Níveis de confidencialidade permitidos
    - Rate limits específicos
  - Manter API Keys dos MCP Servers ativas durante coexistência.
  - Configurar auditoria de cada query com agente de origem via JWT claims.

### 3.3 Migrar usuários em ondas

- **Responsável:** Arquiteto (coordena) + Ops (executa)
- **Atividades:**

**Onda 1 (Semana 1-2): Equipe interna / early adopters**
- Provisionar usuários no IdP com grupos corretos.
- Orientar troca de API Key por fluxo OIDC.
- Monitorar logs para erros de autenticação.
- Coletar feedback.

**Onda 2 (Semana 2-3): Todos os usuários humanos restantes**
- Provisionar e orientar.
- Desativar API Keys dos usuários já migrados (mas não revogar ainda).

**Onda 3 (Semana 3-4): Agentes de IA e automações**
- Atualizar configuração dos agentes para usar JWT (service accounts).
- Agentes que não suportam OIDC mantêm API Key (exceção documentada).
- Registrar exceções com justificativa e data de revisão.

### 3.4 Monitorar coexistência

- **Responsável:** Ops
- **Métricas a acompanhar:**
  - Percentual de requests via JWT vs API Key (meta: >90% JWT ao fim dos 30 dias)
  - Erros de autenticação (JWT inválido, expirado, claims incorretos)
  - Latência adicionada pela validação de JWT
  - Usuários que ainda não migraram (lista nominal)

## 4. Deprecação de API Keys

Após 30 dias de coexistência e com >90% dos requests via JWT.

### 4.1 Comunicar deprecação

- **Responsável:** Arquiteto
- **Atividades:**
  - Enviar comunicação final a usuários remanescentes com API Key.
  - Definir data-limite para remoção (30 dias após comunicação).
  - Listar explicitamente as exceções aprovadas (agentes sem suporte OIDC).

### 4.2 Deprecar API Keys

- **Responsável:** Ops + Engenheiro
- **Atividades:**
  - Marcar todas as API Keys como "deprecated" (ainda funcionais, mas gerando warning no log).
  - Adicionar header de resposta informando deprecação: `X-Auth-Warning: API Key authentication is deprecated. Migrate to JWT.`
  - Monitorar por 30 dias adicionais.

### 4.3 Revogar API Keys

- **Responsável:** Ops
- **Atividades:**
  - Na data-limite, revogar todas as API Keys marcadas como deprecated.
  - EXCEÇÃO: API Keys de agentes sem suporte OIDC permanecem ativas com:
    - Rotação obrigatória a cada 90 dias
    - Rate limiting mais restritivo
    - Monitoramento dedicado
    - Revisão trimestral da exceção
  - Remover middleware de API Key do backend (manter apenas JWT).
  - Confirmar que nenhum request está falhando por falta de API Key.

## 5. Configuração de Revogação de Acesso (JWT)

Com JWT implementado, configurar os mecanismos de revogação:

### 5.1 Downgrade de perfil

- Alteração de grupo no IdP tem efeito imediato no próximo token.
- Cache de resultados de busca NÃO deve ser utilizado — cada query deve verificar o perfil atual.

### 5.2 Remoção de usuário

**Procedimento:**
1. Desativar usuário no IdP.
2. JWT existente invalidado via blocklist (TTL máximo de 15 minutos).
3. Purgar qualquer cache associado ao usuário.
4. Encerrar sessões ativas.

**SLA:** usuário sem acesso em no máximo 15 minutos após desativação no IdP.

### 5.3 Reclassificação de documento

- Chunks são atualizados no próximo ciclo de ingestão.
- Reclassificações urgentes (elevação) acionam refresh imediato na base vetorial — ver [[ADR-C02]] para detalhes.

## 6. Rollback da Migração

Se a migração apresentar problemas críticos, o procedimento de rollback é:

### 6.1 Rollback durante fase de coexistência

- **Impacto:** BAIXO — ambos os métodos ainda estão ativos.
- **Procedimento:**
  1. Reverter a ordem de verificação: API Key primeiro, JWT como fallback.
  2. Comunicar usuários para voltar a usar API Key.
  3. Investigar e corrigir problemas no fluxo JWT.
  4. Reagendar migração.

### 6.2 Rollback após deprecação de API Keys (antes da revogação)

- **Impacto:** MÉDIO — API Keys existem mas estão marcadas como deprecated.
- **Procedimento:**
  1. Reativar API Keys (remover flag "deprecated").
  2. Reativar middleware de API Key no backend.
  3. Comunicar usuários que API Key voltou a ser aceita.
  4. Investigar causa raiz.

### 6.3 Rollback após revogação de API Keys

- **Impacto:** ALTO — API Keys foram removidas.
- **Procedimento:**
  1. Gerar novas API Keys para todos os usuários afetados.
  2. Reimplementar middleware de API Key no backend (se removido).
  3. Distribuir novas API Keys.
  4. Este cenário indica falha grave no planejamento — exige RCA.

> **NOTA:** este cenário deve ser evitado. A revogação só deve acontecer quando há confiança total no funcionamento do JWT.

## 7. Checklist Pós-Migração

- [ ] **7.1** 100% dos usuários humanos autenticando via JWT.
- [ ] **7.2** Agentes de IA usando JWT (ou exceção documentada com API Key).
- [ ] **7.3** Middleware de API Key removido (exceto para exceções).
- [ ] **7.4** Mapeamento grupos IdP → perfis RBAC validado e documentado.
- [ ] **7.5** Mecanismo de revogação testado (downgrade, remoção, blocklist).
- [ ] **7.6** Auditoria funcionando com claims JWT (sub, groups, department).
- [ ] **7.7** MCP Servers usando service accounts com JWT.
- [ ] **7.8** Documentação atualizada ([[ADR-004]], runbooks, onboarding).
- [ ] **7.9** Métricas de autenticação atualizadas no dashboard.
- [ ] **7.10** Comunicação de conclusão enviada a todos os stakeholders.

## 8. Referências

- [[ADR-004]] — Estratégia de Segurança e Classificação de Dados (Pilar 3)
- [[ADR-008]] — Governança: Papéis, Ciclo de Vida e Rollback
- BACEN Resolução 4.893/2021 (rastreabilidade e controle de acesso)
- OIDC — OpenID Connect Core 1.0: <https://openid.net/specs/openid-connect-core-1_0.html>

<!-- conversion_quality: 95 -->
