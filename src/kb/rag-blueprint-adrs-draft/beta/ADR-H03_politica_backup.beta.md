---
id: BETA-H03
title: "Politica de Backup por KB"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-H03_politica_backup.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags:
  - politica de backup
  - backup
  - restauracao
  - retencao
  - recovery
  - sla de restauracao
  - full backup
  - incremental backup
  - snapshot
  - neo4j
  - base vetorial
  - git como fonte da verdade
  - re ingestao
  - pipeline de ingestao
  - knowledge base
  - kb public internal
  - kb restricted
  - kb confidential
  - criptografia
  - aes 256
  - tls
  - hsm
  - cofre fisico
  - off site
  - teste de restore
  - drill de restauracao
  - smoke test
  - golden set
  - integridade
  - consistencia
  - monitoramento de backup
  - alerta
  - raci
  - matriz de responsabilidades
  - compliance
  - lgpd
  - bacen
  - iso 27001
  - retencao regulatoria
  - dados pessoais
  - exclusao de dados
  - mirror clone
  - infrastructure as code
  - docker compose
  - cadencia
  - mensal
  - trimestral
  - independencia por kb
  - segregacao por confidencialidade
  - mcp server
  - orquestrador cross kb
aliases:
  - "ADR-H03"
  - "Politica de Backup"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## ADR-H03 -- Politica de Backup por KB

**Tipo:** ADR
**Origem:** ADR-011
**Data:** 23/03/2026

## 1. Objetivo

Definir a politica de backup, retencao e restauracao para cada uma das 3 Knowledge Bases (KBs) segregadas por nivel de confidencialidade, conforme estabelecido no ADR-011.

A premissa fundamental (ADR-001) e que o Git e a fonte da verdade e a Base Vetorial e uma projecao regeneravel. Portanto, o backup da Base Vetorial serve para ACELERAR a recuperacao (evitando re-ingestao completa), nao como unica copia dos dados.

## 2. Politica por KB

### 2.1 KB Public-Internal (Instancia A)

| Parametro | Valor |
|---|---|
| Frequencia | Diario (01:00 UTC) |
| Retencao | 30 dias |
| Criptografia | Opcional (dados public/internal) |
| Armazenamento | Storage padrao (cloud ou on-prem) |
| Teste de restore | Mensal (automatizado) |
| SLA de restauracao | 4 horas |
| Responsavel | Operacoes (R), Arquiteto (A) |

Justificativa:
- Dados public e internal tem baixo risco regulatorio.
- 30 dias de retencao cobrem ciclos de release tipicos.
- Re-ingestao a partir do Git e alternativa viavel se backup falhar.

### 2.2 KB Restricted (Instancia B)

| Parametro | Valor |
|---|---|
| Frequencia | Diario (02:00 UTC) |
| Retencao | 1 ano (365 dias) |
| Criptografia | Obrigatoria (AES-256 at-rest) |
| Armazenamento | Storage dedicado em ambiente on-premises |
| Teste de restore | Trimestral (com validacao de integridade) |
| SLA de restauracao | 2 horas |
| Responsavel | Operacoes (R), Compliance (A) |

Justificativa:
- Dados restricted incluem politicas internas, relatorios de gestao, auditorias internas e dados financeiros nao publicados.
- Retencao de 1 ano atende requisitos de auditoria interna.
- Criptografia obrigatoria por conter dados sensiveis.
- Teste trimestral alinhado com cadencia de curadoria (ADR-008).

### 2.3 KB Confidential (Instancia C)

| Parametro | Valor |
|---|---|
| Frequencia | Diario (03:00 UTC) |
| Retencao | 5 anos (1.825 dias) |
| Criptografia | Obrigatoria (AES-256 at-rest + TLS 1.3) |
| Chaves | Gerenciadas em HSM (Hardware Security Module) |
| Armazenamento | Cofre fisico separado (off-site) |
| Teste de restore | Trimestral (com drill completo documentado) |
| SLA de restauracao | 1 hora |
| Responsavel | Operacoes (R), Compliance (A), Director (I) |

Justificativa:
- Dados confidenciais incluem contratos, M&A, processos judiciais, vulnerabilidades de seguranca e dados regulatorios.
- Retencao de 5 anos atende BACEN (Resolucao 4.893/2021) para retencao de logs e dados de sistemas criticos.
- Cofre fisico separado garante sobrevivencia a desastres que afetem o data center principal.
- HSM impede extracao de chaves criptograficas.

## 3. Tipos de Backup

### 3.1 Backup da Base Vetorial (Neo4j)

| Tipo | Descricao |
|---|---|
| Full backup | Dump completo da instancia Neo4j |
| Incremental | Apenas transacoes desde o ultimo backup |
| Snapshot | Snapshot de volume (storage-level) |

Recomendacao por KB:
- **kb-public-internal:** Full diario + snapshot de volume
- **kb-restricted:** Full diario + incremental a cada 6 horas
- **kb-confidential:** Full diario + incremental a cada 4 horas + snapshot de volume

### 3.2 Backup do Repositorio Git

O repositorio Git (rag-knowledge-base) e a fonte da verdade. Mesmo sem backup da Base Vetorial, e possivel reconstruir tudo a partir do Git + pipeline de ingestao (ADR-006).

Backup do Git:
- Mirror clone automatico em storage secundario
- Frequencia: a cada push (webhook)
- Retencao: indefinida (Git ja e versionado)

### 3.3 Backup de Configuracao

- Docker Compose files, variaveis de ambiente, secrets
- Infrastructure as Code (IaC) versionado no Git
- Backup de configuracao do pipeline (schemas, templates)

## 4. Procedimento de Restauracao

### 4.1 Restauracao a Partir de Backup (Caminho Rapido)

| Passo | Acao | SLA |
|---|---|---|
| 1 | Identificar backup alvo (data/hora desejada) | 15 min |
| 2 | Validar integridade do arquivo de backup | 15 min |
| 3 | Parar MCP Server da KB afetada | 5 min |
| 4 | Restaurar instancia Neo4j a partir do backup | 30-60 min |
| 5 | Iniciar instancia Neo4j e validar consistencia | 15 min |
| 6 | Iniciar MCP Server | 5 min |
| 7 | Smoke test de busca semantica | 15 min |
| 8 | Notificar stakeholders | 5 min |

Tempo total estimado: 1.5 a 2 horas

### 4.2 Restauracao a Partir do Git (Caminho Completo)

Usado quando backup nao esta disponivel ou esta corrompido.

| Passo | Acao | SLA |
|---|---|---|
| 1 | Identificar TAG de release desejada no Git | 10 min |
| 2 | Provisionar nova instancia Neo4j (se necessario) | 30 min |
| 3 | Executar pipeline de ingestao completo | Variavel* |
| 4 | Validar integridade (contagem de docs/chunks) | 15 min |
| 5 | Executar golden set de testes (ADR-008) | 15 min |
| 6 | Apontar MCP Server para nova instancia | 5 min |
| 7 | Smoke test de busca semantica | 15 min |
| 8 | Notificar stakeholders | 5 min |

*Tempo de re-ingestao depende do volume:
- 50 documentos -> ~5 minutos
- 200 documentos -> ~15 minutos
- 1.000 documentos -> ~30-45 minutos
- 10.000+ docs -> ~4-8 horas

### 4.3 Restauracao por KB (Independencia)

Cada KB pode ser restaurada INDEPENDENTEMENTE. Erro na KB publica NAO afeta a KB restrita nem a confidencial (ADR-011).

Cenario: corrupcao na Instancia A (public-internal)
- Restaurar Instancia A a partir de backup
- Instancias B e C continuam operando normalmente
- Orquestrador cross-kb continua funcionando com resultado parcial (aviso: "KB public-internal indisponivel temporariamente")

## 5. Testes de Restore

### 5.1 Cadencia

| KB | Frequencia | Tipo de Teste |
|---|---|---|
| kb-public-internal | Mensal | Automatizado (restore + smoke test + validacao) |
| kb-restricted | Trimestral | Semi-automatizado (restore + validacao + aprovacao) |
| kb-confidential | Trimestral | Drill completo documentado (restore + validacao + auditoria + relatorio) |

### 5.2 Criterios de Sucesso do Teste

- [ ] Backup restaurado sem erros
- [ ] Contagem de documentos e chunks confere com manifesto
- [ ] Indices vetoriais recriados e funcionais
- [ ] Busca semantica retorna resultados corretos
- [ ] Golden set (ADR-008) passa com Recall >= threshold
- [ ] Tempo de restauracao dentro do SLA
- [ ] Relatorio de teste gerado e arquivado

### 5.3 Registro

Cada teste de restore deve ser registrado com:
- Data/hora do teste
- KB testada
- Tipo de restauracao (backup ou Git)
- Backup utilizado (data, tamanho)
- Tempo de restauracao
- Resultado (sucesso/falha)
- Problemas encontrados e resolucao
- Responsavel pela execucao
- Aprovacao (para KB restricted e confidential)

## 6. Monitoramento de Backups

Alertas configurados para:
- Backup nao executado na janela esperada
- Falha na execucao do backup
- Backup com tamanho anomalo (muito menor que o anterior)
- Storage de backup acima de 80% de capacidade
- Teste de restore atrasado (nao executado na cadencia)

Metricas de acompanhamento:
- Taxa de sucesso de backups (meta: 100%)
- Tempo medio de backup por KB
- Tamanho do backup ao longo do tempo (tendencia de crescimento)
- Tempo medio de restauracao por KB
- Taxa de sucesso dos testes de restore

## 7. Matriz de Responsabilidades (RACI)

| Atividade | ARQ | ENG | OPS | CMP |
|---|---|---|---|---|
| Configurar backup | I | C | R | A |
| Executar backup diario | - | - | R | I |
| Testar restore | I | C | R | A |
| Restaurar em incidente | A | C | R | I |
| Auditar politica | I | - | C | A |
| Revisar retencao | C | - | I | A |

R=Responsible  A=Accountable  C=Consulted  I=Informed

## 8. Conformidade Regulatoria

- **LGPD:** backups contendo dados pessoais (mesmo anonimizados) devem respeitar direitos de exclusao. Em caso de solicitacao de exclusao, o dado deve ser removido de TODOS os backups ativos.
- **BACEN (Resolucao 4.893/2021):** retencao minima de 5 anos para dados de sistemas criticos (KB confidential).
- **ISO 27001:** controle A.12.3 (backup de informacoes) exige politica documentada, testes periodicos e criptografia.

## 9. Referencias

- ADR-011: Segregacao de KBs por Confidencialidade (politica de backup por KB, cofre fisico, retencao)
- ADR-008: Governanca (cenario D rollback completo, cadencia trimestral)
- ADR-006: Pipeline de Ingestao (idempotencia, re-ingestao)
- ADR-001: Pipeline 4 Fases (Git como fonte da verdade)
- ADR-002: Soberania de Dados (Trilha A Cloud, Trilha B On-Prem)

<!-- conversion_quality: 95 -->
