---
id: ADR-H03
doc_type: adr
title: "Política de Backup por KB — Retenção, Restauração e Conformidade Regulatória"
system: RAG Corporativo
module: Backup
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - política de backup
  - backup
  - restauração
  - retenção
  - recovery
  - sla de restauração
  - full backup
  - incremental backup
  - snapshot
  - neo4j
  - base vetorial
  - git como fonte da verdade
  - re ingestão
  - pipeline de ingestão
  - knowledge base
  - kb public internal
  - kb restricted
  - kb confidential
  - criptografia
  - aes 256
  - tls
  - hsm
  - cofre físico
  - off site
  - teste de restore
  - drill de restauração
  - smoke test
  - golden set
  - integridade
  - consistência
  - monitoramento de backup
  - alerta
  - raci
  - matriz de responsabilidades
  - compliance
  - lgpd
  - bacen
  - iso 27001
  - retenção regulatória
  - dados pessoais
  - exclusão de dados
  - mirror clone
  - infrastructure as code
  - docker compose
  - cadência
  - mensal
  - trimestral
  - independência por kb
  - segregação por confidencialidade
  - mcp server
  - orquestrador cross kb
  - disaster recovery
  - procedimento de restauração
aliases:
  - "ADR-H03"
  - "Política de Backup"
  - "Política de Backup por KB"
  - "Backup e Restauração"
  - "Disaster Recovery KB"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/beta/ADR-H03_politica_backup.beta.md"
source_beta_ids:
  - "BETA-H03"
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

# ADR-H03 — Política de Backup por KB — Retenção, Restauração e Conformidade Regulatória

| Campo       | Valor                                                         |
|-------------|---------------------------------------------------------------|
| **Status**  | Accepted                                                      |
| **Data**    | 23/03/2026                                                    |
| **Decisor** | fabio (arquitetura)                                           |
| **Escopo**  | Política de backup, retenção e restauração para cada uma das 3 KBs segregadas por confidencialidade |

**Referências cruzadas:**

- [[ADR-011]]: Segregação de KBs por Confidencialidade
- [[ADR-008]]: Governança (cenário D rollback completo, cadência trimestral)
- [[ADR-006]]: Pipeline de Ingestão (idempotência, re-ingestão)
- [[ADR-001]]: Pipeline 4 Fases (Git como fonte da verdade)
- [[ADR-002]]: Soberania de Dados (Trilha A Cloud, Trilha B On-Prem)

---

## Contexto

A premissa fundamental ([[ADR-001]]) é que o Git é a fonte da verdade e a Base Vetorial é uma projeção regenerável. Portanto, o backup da Base Vetorial serve para ACELERAR a recuperação (evitando re-ingestão completa), não como única cópia dos dados.

## Decisão

Definir a política de backup, retenção e restauração para cada uma das 3 Knowledge Bases (KBs) segregadas por nível de confidencialidade, conforme estabelecido no [[ADR-011]].

## Política por KB

### KB Public-Internal (Instância A)

| Parâmetro | Valor |
|---|---|
| Frequência | Diário (01:00 UTC) |
| Retenção | 30 dias |
| Criptografia | Opcional (dados public/internal) |
| Armazenamento | Storage padrão (cloud ou on-prem) |
| Teste de restore | Mensal (automatizado) |
| SLA de restauração | 4 horas |
| Responsável | Operações (R), Arquiteto (A) |

Justificativa:
- Dados public e internal têm baixo risco regulatório.
- 30 dias de retenção cobrem ciclos de release típicos.
- Re-ingestão a partir do Git é alternativa viável se backup falhar.

### KB Restricted (Instância B)

| Parâmetro | Valor |
|---|---|
| Frequência | Diário (02:00 UTC) |
| Retenção | 1 ano (365 dias) |
| Criptografia | Obrigatória (AES-256 at-rest) |
| Armazenamento | Storage dedicado em ambiente on-premises |
| Teste de restore | Trimestral (com validação de integridade) |
| SLA de restauração | 2 horas |
| Responsável | Operações (R), Compliance (A) |

Justificativa:
- Dados restricted incluem políticas internas, relatórios de gestão, auditorias internas e dados financeiros não publicados.
- Retenção de 1 ano atende requisitos de auditoria interna.
- Criptografia obrigatória por conter dados sensíveis.
- Teste trimestral alinhado com cadência de curadoria ([[ADR-008]]).

### KB Confidential (Instância C)

| Parâmetro | Valor |
|---|---|
| Frequência | Diário (03:00 UTC) |
| Retenção | 5 anos (1.825 dias) |
| Criptografia | Obrigatória (AES-256 at-rest + TLS 1.3) |
| Chaves | Gerenciadas em HSM (Hardware Security Module) |
| Armazenamento | Cofre físico separado (off-site) |
| Teste de restore | Trimestral (com drill completo documentado) |
| SLA de restauração | 1 hora |
| Responsável | Operações (R), Compliance (A), Director (I) |

Justificativa:
- Dados confidenciais incluem contratos, M&A, processos judiciais, vulnerabilidades de segurança e dados regulatórios.
- Retenção de 5 anos atende BACEN (Resolução 4.893/2021) para retenção de logs e dados de sistemas críticos.
- Cofre físico separado garante sobrevivência a desastres que afetem o data center principal.
- HSM impede extração de chaves criptográficas.

## Tipos de Backup

### Backup da Base Vetorial (Neo4j)

| Tipo | Descrição |
|---|---|
| Full backup | Dump completo da instância Neo4j |
| Incremental | Apenas transações desde o último backup |
| Snapshot | Snapshot de volume (storage-level) |

Recomendação por KB:
- **kb-public-internal:** Full diário + snapshot de volume
- **kb-restricted:** Full diário + incremental a cada 6 horas
- **kb-confidential:** Full diário + incremental a cada 4 horas + snapshot de volume

### Backup do Repositório Git

O repositório Git (rag-knowledge-base) é a fonte da verdade. Mesmo sem backup da Base Vetorial, é possível reconstruir tudo a partir do Git + pipeline de ingestão ([[ADR-006]]).

Backup do Git:
- Mirror clone automático em storage secundário
- Frequência: a cada push (webhook)
- Retenção: indefinida (Git já é versionado)

### Backup de Configuração

- Docker Compose files, variáveis de ambiente, secrets
- Infrastructure as Code (IaC) versionado no Git
- Backup de configuração do pipeline (schemas, templates)

## Procedimento de Restauração

### Restauração a Partir de Backup (Caminho Rápido)

| Passo | Ação | SLA |
|---|---|---|
| 1 | Identificar backup alvo (data/hora desejada) | 15 min |
| 2 | Validar integridade do arquivo de backup | 15 min |
| 3 | Parar MCP Server da KB afetada | 5 min |
| 4 | Restaurar instância Neo4j a partir do backup | 30-60 min |
| 5 | Iniciar instância Neo4j e validar consistência | 15 min |
| 6 | Iniciar MCP Server | 5 min |
| 7 | Smoke test de busca semântica | 15 min |
| 8 | Notificar stakeholders | 5 min |

Tempo total estimado: 1.5 a 2 horas

### Restauração a Partir do Git (Caminho Completo)

Usado quando backup não está disponível ou está corrompido.

| Passo | Ação | SLA |
|---|---|---|
| 1 | Identificar TAG de release desejada no Git | 10 min |
| 2 | Provisionar nova instância Neo4j (se necessário) | 30 min |
| 3 | Executar pipeline de ingestão completo | Variável* |
| 4 | Validar integridade (contagem de docs/chunks) | 15 min |
| 5 | Executar golden set de testes ([[ADR-008]]) | 15 min |
| 6 | Apontar MCP Server para nova instância | 5 min |
| 7 | Smoke test de busca semântica | 15 min |
| 8 | Notificar stakeholders | 5 min |

*Tempo de re-ingestão depende do volume:
- 50 documentos → ~5 minutos
- 200 documentos → ~15 minutos
- 1.000 documentos → ~30-45 minutos
- 10.000+ docs → ~4-8 horas

### Restauração por KB (Independência)

Cada KB pode ser restaurada INDEPENDENTEMENTE. Erro na KB pública NÃO afeta a KB restrita nem a confidencial ([[ADR-011]]).

Cenário: corrupção na Instância A (public-internal)
- Restaurar Instância A a partir de backup
- Instâncias B e C continuam operando normalmente
- Orquestrador cross-kb continua funcionando com resultado parcial (aviso: "KB public-internal indisponível temporariamente")

## Testes de Restore

### Cadência

| KB | Frequência | Tipo de Teste |
|---|---|---|
| kb-public-internal | Mensal | Automatizado (restore + smoke test + validação) |
| kb-restricted | Trimestral | Semi-automatizado (restore + validação + aprovação) |
| kb-confidential | Trimestral | Drill completo documentado (restore + validação + auditoria + relatório) |

### Critérios de Sucesso do Teste

- [ ] Backup restaurado sem erros
- [ ] Contagem de documentos e chunks confere com manifesto
- [ ] Índices vetoriais recriados e funcionais
- [ ] Busca semântica retorna resultados corretos
- [ ] Golden set ([[ADR-008]]) passa com Recall >= threshold
- [ ] Tempo de restauração dentro do SLA
- [ ] Relatório de teste gerado e arquivado

### Registro

Cada teste de restore deve ser registrado com:
- Data/hora do teste
- KB testada
- Tipo de restauração (backup ou Git)
- Backup utilizado (data, tamanho)
- Tempo de restauração
- Resultado (sucesso/falha)
- Problemas encontrados e resolução
- Responsável pela execução
- Aprovação (para KB restricted e confidential)

## Monitoramento de Backups

Alertas configurados para:
- Backup não executado na janela esperada
- Falha na execução do backup
- Backup com tamanho anômalo (muito menor que o anterior)
- Storage de backup acima de 80% de capacidade
- Teste de restore atrasado (não executado na cadência)

Métricas de acompanhamento:
- Taxa de sucesso de backups (meta: 100%)
- Tempo médio de backup por KB
- Tamanho do backup ao longo do tempo (tendência de crescimento)
- Tempo médio de restauração por KB
- Taxa de sucesso dos testes de restore

## Matriz de Responsabilidades (RACI)

| Atividade | ARQ | ENG | OPS | CMP |
|---|---|---|---|---|
| Configurar backup | I | C | R | A |
| Executar backup diário | - | - | R | I |
| Testar restore | I | C | R | A |
| Restaurar em incidente | A | C | R | I |
| Auditar política | I | - | C | A |
| Revisar retenção | C | - | I | A |

R=Responsible  A=Accountable  C=Consulted  I=Informed

## Conformidade Regulatória

- **LGPD:** backups contendo dados pessoais (mesmo anonimizados) devem respeitar direitos de exclusão. Em caso de solicitação de exclusão, o dado deve ser removido de TODOS os backups ativos.
- **BACEN (Resolução 4.893/2021):** retenção mínima de 5 anos para dados de sistemas críticos (KB confidential).
- **ISO 27001:** controle A.12.3 (backup de informações) exige política documentada, testes periódicos e criptografia.

## Referências

- [[ADR-011]]: Segregação de KBs por Confidencialidade (política de backup por KB, cofre físico, retenção)
- [[ADR-008]]: Governança (cenário D rollback completo, cadência trimestral)
- [[ADR-006]]: Pipeline de Ingestão (idempotência, re-ingestão)
- [[ADR-001]]: Pipeline 4 Fases (Git como fonte da verdade)
- [[ADR-002]]: Soberania de Dados (Trilha A Cloud, Trilha B On-Prem)

<!-- conversion_quality: 95 -->
