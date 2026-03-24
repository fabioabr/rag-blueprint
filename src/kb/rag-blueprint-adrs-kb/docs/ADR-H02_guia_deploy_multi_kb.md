---
id: ADR-H02
doc_type: adr
title: "Guia de Deploy Multi-KB — Configuração de Infraestrutura para Segregação em 3 Knowledge Bases"
system: RAG Corporativo
module: Deploy Multi-KB
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - deploy multi kb
  - infraestrutura
  - docker compose
  - profiles
  - neo4j
  - instância dedicada
  - mcp server
  - segregação por confidencialidade
  - rede isolada
  - firewall
  - volumes isolados
  - pipeline parametrizado
  - variáveis de ambiente
  - secret manager
  - autenticação
  - sso
  - mfa
  - jit
  - cloud
  - on premises
  - staging
  - produção
  - release tag
  - ci cd
  - aprovação de deploy
  - monitoramento unificado
  - checklist de validação
  - smoke test
  - base vetorial
  - vector index
  - kb public internal
  - kb restricted
  - kb confidential
  - orquestrador cross kb
  - dimensionamento
  - fase de rollout
  - mvp
  - ram
  - disco
  - chunks
  - documentos
  - criptografia
  - aes 256
  - tls
  - hsm
  - backup
  - fail safe
  - confidentiality
  - front matter
  - compliance officer
  - manager
  - director
  - configuração de rede
  - segmentação de rede
  - isolamento de containers
  - credenciais por instância
  - pipeline de ingestão
aliases:
  - "ADR-H02"
  - "Deploy Multi-KB"
  - "Guia de Deploy Multi-KB"
  - "Infraestrutura Multi-KB"
  - "Deploy Segregado por Confidencialidade"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/beta/ADR-H02_guia_deploy_multi_kb.beta.md"
source_beta_ids:
  - "BETA-H02"
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

# ADR-H02 — Guia de Deploy Multi-KB — Configuração de Infraestrutura para Segregação em 3 Knowledge Bases

| Campo       | Valor                                                         |
|-------------|---------------------------------------------------------------|
| **Status**  | Accepted                                                      |
| **Data**    | 23/03/2026                                                    |
| **Decisor** | fabio (arquitetura)                                           |
| **Escopo**  | Configuração de infraestrutura para o modelo de segregação em 3 KBs, incluindo instâncias Neo4j, MCP Servers, rede e profiles de deploy |

**Referências cruzadas:**

- [[ADR-011]]: Segregação de KBs por Confidencialidade
- [[ADR-006]]: Pipeline de Ingestão (7 etapas, idempotência)
- [[ADR-002]]: Soberania de Dados (Trilha A Cloud, Trilha B On-Prem)
- [[ADR-004]]: Segurança e Classificação de Dados
- [[ADR-010]]: Git Flow (releases independentes por KB)
- [[ADR-H01]]: Orquestrador Cross-KB

---

## Contexto

O [[ADR-011]] estabelece 3 KBs fisicamente separadas para garantir segregação por nível de confidencialidade. Este ADR documenta a configuração prática de infraestrutura necessária para operacionalizar esse modelo.

## Decisão

Documentar a configuração de infraestrutura para o modelo de segregação em 3 Knowledge Bases (KBs) definido no [[ADR-011]], incluindo instâncias Neo4j dedicadas, MCP Servers por nível, configuração de rede e profiles de deploy.

## Visão Geral da Arquitetura Multi-Instância

| KB | Base Vetorial | MCP Server | Rede |
|---|---|---|---|
| kb-public-internal | Instância A | mcp-knowledge-public | Cloud (A) |
| kb-restricted | Instância B | mcp-knowledge-restricted | On-Prem (B) |
| kb-confidential | Instância C | mcp-knowledge-confidential | On-Prem (C) |

Cada KB opera como unidade autônoma: Base Vetorial própria, MCP Server próprio, volumes de dados isolados, rede segmentada.

## Configuração Docker Compose — Conceito

O deploy utiliza Docker Compose com profiles para ativar cada KB independentemente. O mesmo pipeline de ingestão ([[ADR-006]]) é parametrizado para cada instância.

### Profiles

| Profile | Serviços Incluídos |
|---|---|
| public-internal | neo4j-public, mcp-public, monitoring-public |
| restricted | neo4j-restricted, mcp-restricted, monitoring-restricted |
| confidential | neo4j-confidential, mcp-confidential, monitoring-confidential |
| orchestrator | orquestrador cross-kb ([[ADR-H01]]) |

Para ativar apenas a KB pública (Fase 1 do rollout):
```bash
docker compose --profile public-internal up -d
```

Para ativar public + restricted (Fase 2):
```bash
docker compose --profile public-internal --profile restricted up -d
```

Para ativar tudo (Fase 3):
```bash
docker compose --profile public-internal --profile restricted \
  --profile confidential --profile orchestrator up -d
```

### Instâncias Neo4j

Cada instância Neo4j roda em container dedicado com volumes isolados:

| Serviço | Porta | Volume de Dados | Volume de Logs |
|---|---|---|---|
| neo4j-public | 7474 | vol-neo4j-public-data | vol-neo4j-public-logs |
| neo4j-restricted | 7475 | vol-neo4j-restr-data | vol-neo4j-restr-logs |
| neo4j-confidential | 7476 | vol-neo4j-conf-data | vol-neo4j-conf-logs |

Configurações por instância:
- NEO4J_AUTH: credenciais diferentes por instância
- NEO4J_PLUGINS: vector index habilitado em todas
- NEO4J_dbms_memory_heap_max__size: dimensionado por volume esperado
- Backups: agendados independentemente por instância

### MCP Servers

Cada MCP Server conecta-se EXCLUSIVAMENTE à sua instância Neo4j:

| Serviço | Porta | Conecta em | Autenticação |
|---|---|---|---|
| mcp-public | 8080 | neo4j-public:7474 | Token de serviço / SSO |
| mcp-restricted | 8081 | neo4j-restricted:7475 | SSO + MFA |
| mcp-confidential | 8082 | neo4j-confidential:7476 | SSO + MFA + JIT |

Variáveis de ambiente por MCP:
- `KB_TARGET`: identificador da KB (ex: kb-public-internal)
- `VECTOR_DB_HOST`: host da instância Neo4j
- `VECTOR_DB_CREDENTIALS`: credenciais (referência a vault/secret manager)
- `MCP_ENDPOINT`: URL de exposição do MCP
- `AUTH_MODE`: token | sso | sso+mfa | sso+mfa+jit
- `LOG_LEVEL`: info (public) | debug (restricted/confidential)

## Configuração de Rede

### Isolamento de Redes

Cada KB opera em rede Docker separada:

| Rede | Serviços | Acesso Externo |
|---|---|---|
| net-public | neo4j-public, mcp-public | Load balancer corp. |
| net-restricted | neo4j-restricted, mcp-restricted | VPN corporativa |
| net-confidential | neo4j-confidential, mcp-confidential | VPN dedicada + JIT |

Regras fundamentais:
- net-public NÃO tem rota para net-restricted nem net-confidential.
- net-restricted NÃO tem rota para net-confidential.
- O orquestrador cross-kb (quando ativado) tem acesso controlado por firewall: só pode acessar as portas dos MCPs, nunca as portas das instâncias Neo4j diretamente.

### Regras de Firewall

| Origem | Destino | Porta | Ação |
|---|---|---|---|
| mcp-public | neo4j-public | 7474 | ALLOW |
| mcp-restricted | neo4j-restricted | 7475 | ALLOW |
| mcp-confidential | neo4j-confidential | 7476 | ALLOW |
| orchestrator | mcp-public | 8080 | ALLOW |
| orchestrator | mcp-restricted | 8081 | ALLOW |
| orchestrator | mcp-confidential | 8082 | ALLOW |
| mcp-public | neo4j-restricted | * | DENY |
| mcp-public | neo4j-confidential | * | DENY |
| mcp-restricted | neo4j-confidential | * | DENY |
| * | neo4j-* | * | DENY (default) |

## Pipeline Parametrizado

O mesmo pipeline de ingestão ([[ADR-006]]) é reutilizado para as 3 KBs, parametrizado pelas seguintes variáveis:

| Variável | Descrição |
|---|---|
| KB_TARGET | Identificador da KB alvo |
| VECTOR_DB_HOST | Host da instância Neo4j correspondente |
| VECTOR_DB_CREDENTIALS | Credenciais (via secret manager) |
| MCP_ENDPOINT | Endpoint do MCP para validação pós-ingestão |
| EMBEDDING_MODEL | Modelo de embedding (pode variar por KB) |
| BATCH_SIZE | Tamanho do lote de ingestão |

O roteamento é determinado pelo campo "confidentiality" no front matter:
- public → KB_TARGET=kb-public-internal
- internal → KB_TARGET=kb-public-internal
- restricted → KB_TARGET=kb-restricted
- confidential → KB_TARGET=kb-confidential

**FAIL-SAFE:** se o campo "confidentiality" estiver AUSENTE, o pipeline REJEITA o documento e notifica o responsável. Não existe default seguro.

## Ambientes por KB (Staging e Produção)

Cada KB possui seus próprios ambientes de staging e produção:

| KB | Staging | Produção |
|---|---|---|
| kb-public-internal | neo4j-public-staging | neo4j-public-prod |
| kb-restricted | neo4j-restricted-staging | neo4j-restricted-prod |
| kb-confidential | neo4j-conf-staging | neo4j-conf-prod |

Release TAGs são independentes por KB ([[ADR-011]]):
- kb-public-internal@v1.2.0
- kb-restricted@v1.0.3
- kb-confidential@v1.0.1

Pipeline de deploy por KB:
- KB pública: deploy automático (CI/CD) após testes em staging
- KB restrita: requer aprovação de Manager antes do deploy
- KB confidencial: requer aprovação de Director + Compliance Officer

## Dimensionamento por Fase de Rollout

**Fase 1 — MVP (apenas kb-public-internal):**
- 1 instância Neo4j (Instância A)
- 1 MCP Server (mcp-knowledge-public)
- Documentos RESTRICTED e CONFIDENTIAL rejeitados pelo pipeline
- Estimativa: 20-100 documentos, 200-1.000 chunks, 2-10 MB
- RAM Neo4j: 2-4 GB suficiente
- Duração estimada: 2-3 sprints

**Fase 2 — Adicionar kb-restricted:**
- +1 instância Neo4j (Instância B) em ambiente on-premises
- +1 MCP Server (mcp-knowledge-restricted) com SSO+MFA
- Rede segmentada, validação de isolamento
- Estimativa KB restrita: 50-200 documentos iniciais
- Duração estimada: 3-4 sprints

**Fase 3 — Adicionar kb-confidential + orquestrador:**
- +1 instância Neo4j (Instância C) em rede isolada
- +1 MCP Server (mcp-knowledge-confidential) com SSO+MFA+JIT
- Orquestrador cross-KB com fusão RRF
- Criptografia at-rest (AES-256) e in-transit (TLS 1.3)
- Chaves em HSM
- Duração estimada: 4-6 sprints

## Monitoramento Unificado

Apesar do isolamento físico, o monitoramento é centralizado:
- Dashboard único com visão de saúde das 3 KBs
- Métricas por KB: uptime, latência, volume de chunks, uso de recursos
- Alertas independentes por KB (falha em uma não gera alerta nas demais)
- Logs de acesso separados por KB (retenção conforme política de backup)

Para KB confidencial: monitoramento 24/7 com alertas para SOC.

## Checklist de Validação de Deploy

- [ ] Cada MCP conecta SOMENTE à sua instância Neo4j
- [ ] MCP público NÃO consegue acessar Base Vetorial B ou C
- [ ] MCP restrito NÃO consegue acessar Base Vetorial C
- [ ] Firewall rules estão aplicadas e testadas
- [ ] Volumes de dados são isolados (não compartilhados)
- [ ] Credenciais são diferentes por instância
- [ ] Backup automatizado está configurado por KB
- [ ] Pipeline de ingestão rejeita documentos sem "confidentiality"
- [ ] Monitoramento está recebendo métricas de todas as instâncias
- [ ] Smoke test de busca semântica passa em cada KB

## Referências

- [[ADR-011]]: Segregação de KBs por Confidencialidade
- [[ADR-006]]: Pipeline de Ingestão (7 etapas, idempotência)
- [[ADR-002]]: Soberania de Dados (Trilha A Cloud, Trilha B On-Prem)
- [[ADR-004]]: Segurança e Classificação de Dados
- [[ADR-010]]: Git Flow (releases independentes por KB)
- [[ADR-H01]]: Orquestrador Cross-KB

<!-- conversion_quality: 95 -->
