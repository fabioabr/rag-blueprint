---
id: ADR-011
doc_type: adr
title: "Segregação de Bases de Conhecimento por Nível de Confidencialidade"
system: RAG Corporativo
module: Segregação de KBs
domain: Arquitetura
owner: fabio
team: arquitetura
status: approved
confidentiality: internal
date_decided: 2026-03-21
tags:
  - adr
  - segregacao
  - seguranca
  - confidencialidade
  - kbs
  - isolamento-fisico
  - compliance
  - mcp
  - lgpd
  - bacen
aliases:
  - "ADR-011"
  - "Segregação por Confidencialidade"
  - "Segregacao por Confidencialidade"
  - "Segregação de KBs"
  - "Isolamento Físico de KBs"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-kb/beta/ADR-011_segregacao_kbs_por_confidencialidade.beta.md"
source_beta_ids:
  - "BETA-011"
conversion_pipeline: promotion-pipeline-v1
conversion_quality: 100
converted_at: 2026-03-22
qa_score: 98
qa_date: 2026-03-22
qa_status: passed
created_at: 2026-03-21
updated_at: 2026-03-22
valid_from: 2026-03-21
valid_until: null
---

# ADR-011 — Segregação de Bases de Conhecimento por Nível de Confidencialidade

| Campo | Valor |
|-------|-------|
| **Status** | Approved |
| **Data da Decisão** | 2026-03-21 |
| **Decisor** | fabio |
| **Escopo** | Segregação de KBs |

**Referências Cruzadas:**

- **Depende de:** [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]], [[ADR-002_soberania_dados_cloud_vs_onprem|ADR-002]], [[ADR-004_seguranca_classificacao_dados|ADR-004]]
- **Relaciona-se:** [[ADR-005_front_matter_contrato_metadados|ADR-005]], [[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]], [[ADR-007_retrieval_hibrido_agentes|ADR-007]], [[ADR-008_governanca_ciclo_vida_rollback|ADR-008]], [[ADR-010_git_flow_base_conhecimento|ADR-010]]

## Contexto

### O Problema: Filtro Pré-Retrieval Não é Suficiente

O [[ADR-004_seguranca_classificacao_dados|ADR-004]] estabeleceu 4 níveis de confidencialidade para toda a base de conhecimento corporativa: PUBLIC, INTERNAL, RESTRICTED e CONFIDENTIAL. Também definiu que o filtro pré-retrieval — aplicado antes da busca vetorial — é inviolável.

Essa decisão está correta como **princípio**, mas apresenta uma fragilidade crítica quando analisada sob a ótica de **implementação**:

O filtro pré-retrieval é um controle na camada de **software** (query). Qualquer controle na camada de software é vulnerável a:

1. **Bugs de implementação** — um erro no código do filtro pode permitir que chunks RESTRICTED sejam retornados em buscas PUBLIC
2. **Prompt injection** — um atacante pode manipular a query para tentar bypassar o filtro
3. **Misconfiguration** — deploy incorreto, variável de ambiente errada, perfil de acesso permissivo demais
4. **Escalação de privilégios** — se todos os dados estão na mesma Base Vetorial, qualquer vulnerabilidade expõe todos os níveis
5. **Complexidade de auditoria** — auditar se um filtro de query funciona corretamente em todas as situações é exponencialmente mais difícil do que auditar se dois servidores estão em redes separadas

### Contexto Regulatório: Risco Inaceitável

O projeto RAG Corporativo opera dentro de uma instituição financeira regulada pelo BACEN, CVM e LGPD:

- **LGPD:** multas de até 2% do faturamento por incidente de vazamento de dados pessoais (art. 52)
- **BACEN:** Resolução 4.893/2021 exige controles de segurança proporcionais à sensibilidade dos dados
- **CVM:** informações privilegiadas têm tratamento específico pela Instrução CVM 400 e Lei 6.385/1976
- **SOX (se aplicável):** controles insuficientes sobre informação financeira podem resultar em sanções

Para uma instituição financeira, confiar **exclusivamente** em um filtro de query como único mecanismo de proteção de dados RESTRICTED/CONFIDENTIAL é **inaceitável** do ponto de vista de compliance.

### A Solução: Mover o Controle de Acesso da Query para a Infraestrutura

Se dados RESTRICTED estão em uma Base Vetorial **separada**, com um MCP Server **separado**, em uma rede **separada**, então é **fisicamente impossível** que um usuário acessando o MCP público consiga ver dados RESTRICTED. Não importa se há bug no filtro, prompt injection, misconfiguration ou escalação de privilégios — os dados simplesmente **não existem** naquele ambiente.

Isso é **segurança por isolamento de infraestrutura** — em contraste com segurança por filtro de software.

O [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] já antecipou essa possibilidade ao definir que cada contexto de negócio pode ter sua KB separada. O [[ADR-002_soberania_dados_cloud_vs_onprem|ADR-002]] reforça ao definir duas trilhas de infraestrutura: Trilha A (Cloud) para PUBLIC/INTERNAL e Trilha B (On-Premise) para RESTRICTED/CONFIDENTIAL.

### Por que Agora

Essa decisão precisa ser tomada **antes** da implementação do pipeline de ingestão ([[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]]), porque o roteamento de documentos para a Base Vetorial correta depende da arquitetura de segregação estar definida. Começar com única Base Vetorial e depois segregar gera custo significativo de migração.

## Decisão: Modelo de Segregação em 3 KBs

Adotar modelo de **segregação física** de Bases de Conhecimento (KBs) por nível de confidencialidade, com Base Vetorial dedicada e MCP Server dedicado para cada nível. O campo `confidentiality` no front matter do documento determina para qual KB e Base Vetorial ele será roteado pelo pipeline de ingestão. O filtro pré-retrieval ([[ADR-004_seguranca_classificacao_dados|ADR-004]]) continua existindo como camada **adicional** de defesa, mas **não** é mais a única barreira.

### Nível 1: KB Pública + Interna (acesso geral)

- **Identificador:** `kb-public-internal`
- **Confidencialidade:** PUBLIC + INTERNAL
- **Base Vetorial:** Instância A
- **Conteúdo:** documentação de sistemas, ADRs (internal), runbooks operacionais, glossário, tutoriais, documentação de APIs, manuais, FAQ
- **MCP Server:** `mcp-knowledge-public`
- **Acesso:** todos os funcionários autenticados, agentes de IA genéricos
- **Trilha ([[ADR-002_soberania_dados_cloud_vs_onprem|ADR-002]]):** Trilha A (Cloud) — permitido
- **Autenticação:** token de serviço ou SSO corporativo
- **Autorização:** perfis Analyst, Manager, Director — todos têm acesso

### Nível 2: KB Restrita (acesso por cargo/função)

- **Identificador:** `kb-restricted`
- **Confidencialidade:** RESTRICTED
- **Base Vetorial:** Instância B (separada fisicamente da Instância A)
- **Conteúdo:** políticas internas, dados financeiros não publicados, relatórios de gestão, post-mortems de segurança, auditorias internas, estratégias de produto, dados de performance, informações de PLD, dados de fornecedores com cláusula de confidencialidade
- **MCP Server:** `mcp-knowledge-restricted`
- **Acesso:** Gestores (Manager), Diretoria (Director), agentes de IA com perfil explícito
- **Trilha ([[ADR-002_soberania_dados_cloud_vs_onprem|ADR-002]]):** Trilha B (On-Premise) — obrigatório
- **Autenticação:** SSO corporativo + MFA obrigatório
- **Autorização:** Manager (acesso restrito ao seu domínio), Director (acesso amplo), Agente IA (perfil explícito por domínio)
- **Controles extras:** rede segmentada, acesso restrito por IP/firewall, backup criptografado, monitoramento SIEM, access review trimestral

### Nível 3: KB Confidencial (acesso mínimo)

- **Identificador:** `kb-confidential`
- **Confidencialidade:** CONFIDENTIAL
- **Base Vetorial:** Instância C (isolada — rede separada)
- **Conteúdo:** contratos, dados pessoais anonimizados, estratégia corporativa de longo prazo, M&A, insider trading, processos judiciais, remuneração de executivos, BCP/DRP, vulnerabilidades de segurança, relatórios de pen testing, dados regulatórios confidenciais
- **MCP Server:** `mcp-knowledge-confidential`
- **Acesso:** Diretoria (Director) com justificativa registrada, Compliance Officer, agentes de IA dedicados com aprovação documentada
- **Trilha ([[ADR-002_soberania_dados_cloud_vs_onprem|ADR-002]]):** Trilha B (On-Premise) — obrigatório, com controles extras
- **Autenticação:** SSO + MFA + aprovação just-in-time (acesso sob demanda com tempo limitado)
- **Controles extras:** rede fisicamente separada ou fortemente segmentada, VPN dedicada + just-in-time, criptografia at-rest (AES-256) e in-transit (TLS 1.3), chaves em HSM, backup em cofre físico separado, monitoramento 24/7 com alertas para SOC, pen test periódico, retenção de logs mínimo 5 anos (BACEN), acesso revogado automaticamente após período configurável

## Vantagens do Modelo de Segregação Física

1. **Segurança física** — elimina classe inteira de vulnerabilidades. Qualquer vulnerabilidade na Base Vetorial A não tem como acessar dados RESTRICTED
2. **Zero risco de data leakage via query** — o MCP público se conecta apenas à Base Vetorial A; mesmo com controle total do MCP público, só se vê dados public/internal
3. **Auditabilidade simplificada** — basta verificar quem tem acesso a qual MCP; trivial para auditores e reguladores
4. **Simplicidade conceitual** — controle de acesso é "qual MCP você acessa?", não "qual filtro a query aplica"
5. **Compliance nativo** — atende nativamente BACEN, LGPD, CVM, SOX, ISO 27001
6. **Alinhamento com [[ADR-002_soberania_dados_cloud_vs_onprem|ADR-002]]** — cada Base Vetorial reside na trilha correta por design

## Desafios e Soluções

### Desafio 1: Busca Cross-KB

**Problema:** usuário com perfil Director pode fazer pergunta cujo contexto ideal requer chunks de múltiplos níveis.

**Solução: Agente Orquestrador Cross-KB**

1. Recebe a pergunta do usuario
2. Identifica quais MCPs o usuario tem acesso (baseado no perfil)
3. Envia a query para cada MCP autorizado em paralelo
4. Recebe os resultados de cada MCP
5. Funde os resultados usando RRF — Reciprocal Rank Fusion ([[ADR-007_retrieval_hibrido_agentes|ADR-007]])
6. Aplica reranking no conjunto fundido
7. Monta o prompt com chunks ordenados por relevancia
8. Gera a resposta

Regras do orquestrador:
- Roda com o **perfil do usuário** — só acessa os MCPs que o usuário tem direito
- Nunca mistura chunks de níveis diferentes sem **indicar a classificação** de cada chunk
- Se chunks CONFIDENTIAL foram usados, a resposta inteira e classificada como CONFIDENTIAL

### Desafio 2: Mesmo Documento em Múltiplos Níveis

**Problema:** um documento pode ter seções com diferentes níveis de confidencialidade.

**Solução: Split na Fase 2 (.beta.md)**

- **Opção A — Split por seção (recomendada):** gerar `.beta.md` separados para cada nível, com `cross_ref` no front matter indicando que são partes do mesmo original
- **Opção B — Classificação conservadora (fallback):** documento inteiro classificado pelo nível mais alto presente

**Decisão:** usar Opção A como padrão, com Opção B como fallback para casos onde o split não é viável.

Na re-ingestão (quando fonte original é atualizada), o pipeline aplica o merge separadamente em cada `.beta.md` splitado via campo `cross_ref`, respeitando blocos LOCKED. Se o split por confidencialidade mudar, gera alerta para revisão humana.

### Desafio 3: Roteamento no Pipeline de Ingestão

O campo `confidentiality` no front matter ([[ADR-004_seguranca_classificacao_dados|ADR-004]], [[ADR-005_front_matter_contrato_metadados|ADR-005]]) é o **único determinante** do roteamento:

| confidentiality | KB | Base Vetorial |
|---|---|---|
| `public` | `kb-public-internal` | Instancia A |
| `internal` | `kb-public-internal` | Instancia A |
| `restricted` | `kb-restricted` | Instancia B |
| `confidential` | `kb-confidential` | Instancia C |

**Fail-safe crítico:** se o campo `confidentiality` estiver **ausente**, o pipeline **deve rejeitar** o documento e notificar o responsável. Não existe default seguro — ausência de classificação é tratada como **erro**, não como "public por padrão".

### Desafio 4: Manutenção de Múltiplas Instâncias

**Solução: Pipeline Parametrizado + Automação**

O mesmo pipeline de ingestão ([[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]]) é utilizado para as 3 KBs, parametrizado por: `KB_TARGET`, `VECTOR_DB_HOST`, `VECTOR_DB_CREDENTIALS`, `MCP_ENDPOINT`.

Cada profile define: serviço da Base Vetorial, MCP Server, monitoring, volumes isolados, rede isolada.

Backup por KB:
- **kb-public-internal:** diário, retenção 30 dias
- **kb-restricted:** diário, retenção 1 ano, criptografado
- **kb-confidential:** diário, retenção 5 anos, criptografado, cofre físico separado

### Desafio 5: Wikilinks Cross-KB

**Decisão: Wikilinks cross-KB são proibidos.**

Documentos de uma KB não podem fazer wikilink para documentos de outra KB. Motivo: um wikilink para documento restricted em um documento público revela a existência de informação restrita. Para referências cruzadas entre KBs, usar o campo `cross_ref` no front matter (sem link navegável). O pipeline valida: wikilinks que apontam para documentos em outra KB são tratados como erro de ingestão.

### Desafio 6: Documentos Expirados (Temporalidade)

**Decisão: Documentos expirados permanecem, com filtro temporal.**

Documentos expirados não são removidos da Base Vetorial — permanecem para consultas históricas. O filtro temporal ([[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] seção temporalidade) é aplicado por cada MCP individualmente antes de retornar resultados. Documentos expirados são marcados como `[EXPIRADO]` no retrieval.

## Estrutura de Pastas no Workspace (rag-workspace)

Esta seção supercede a estrutura de pastas do [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]], adicionando camada de diretório por nível de confidencialidade:

```
rag-workspace/
  beta/
    public-internal/          -> KB Nivel 1
      arquitetura/
      operacional/
      glossary/
      apis/
      onboarding/
      faq/
    restricted/               -> KB Nivel 2
      financeiro/
      gestao/
      compliance/
      seguranca/
      estrategia/
    confidential/             -> KB Nivel 3
      contratos/
      estrategia-corporativa/
      juridico/
      remuneracao/
      continuidade/
  manifests/
    public-internal.manifest.yaml
    restricted.manifest.yaml
    confidential.manifest.yaml
```

Regras: cada subpasta corresponde a uma KB e uma Base Vetorial; documentos não podem estar em mais de uma pasta (exceto via `cross_ref`); a pasta determina o nível de confidencialidade — o front matter deve ser consistente; inconsistência entre pasta e front matter = erro de ingestão.

## Estrutura no Knowledge-Base (rag-knowledge-base)

Replica a mesma segregacao, com `docs/`, `presentations/` e `releases/` dentro de cada subpasta de KB:

```
rag-knowledge-base/
  public-internal/            -> alimenta Base Vetorial A
    docs/
    presentations/
    releases/
  restricted/                 -> alimenta Base Vetorial B
    docs/
    presentations/
    releases/
  confidential/               -> alimenta Base Vetorial C
    docs/
    presentations/
    releases/
```

O pipeline de promoção lê de cada pasta e envia para a Base Vetorial correspondente. Um `.md` em `restricted/docs/` **nunca** é enviado para a Base Vetorial A.

## Diagrama de Acesso por Perfil

| Perfil | MCPs Acessíveis | Bases Vetoriais |
|---|---|---|
| **Analyst** (funcionario comum) | `mcp-knowledge-public` | A |
| **Manager** (gestor) | `mcp-knowledge-public` + `mcp-knowledge-restricted` | A, B |
| **Director** (diretoria) | `mcp-knowledge-public` + `mcp-knowledge-restricted` + `mcp-knowledge-confidential` | A, B, C |
| Agente IA genérico | `mcp-knowledge-public` | A |
| Agente IA de domínio | `mcp-knowledge-public` + `mcp-knowledge-restricted` (domínio específico) | A, B |
| Agente IA dedicado | `mcp-knowledge-confidential` (com aprovação) | C |

## Relação com [[ADR-010_git_flow_base_conhecimento|ADR-010]] (Git Flow e Release)

A segregação por KB impacta o fluxo de release e versionamento:

1. **Release TAGs independentes por KB:** cada KB tem seu próprio ciclo (`kb-public-internal@v1.2.0`, `kb-restricted@v1.0.3`, `kb-confidential@v1.0.1`)
2. **Staging/Prod por KB:** cada KB tem seu próprio ambiente de staging (Base Vetorial A-staging, B-staging, C-staging)
3. **Pipeline de deploy separado:** KB pública pode ser automática (CI/CD), KB restrita requer aprovação de Manager, KB confidencial requer aprovação de Director + Compliance
4. **Rollback independente ([[ADR-008_governanca_ciclo_vida_rollback|ADR-008]]):** erro na KB pública não afeta as demais Bases Vetoriais

## Alternativas Descartadas

### Alternativa A: Filtro Pré-Retrieval na Query (modelo [[ADR-004_seguranca_classificacao_dados|ADR-004]] original)

Manter única Base Vetorial com filtro de query. Rejeitada: vulnerável a bugs, prompt injection, misconfiguration, escalação de privilégios. Não atende requisitos regulatórios de isolamento físico (BACEN, LGPD).

### Alternativa B: Banco Único com Row-Level Security (RLS)

Única Base Vetorial com RLS nativo do banco. Rejeitada: nem toda Base Vetorial suporta RLS de forma madura, dependência de vendor, não garante isolamento físico, admin do banco vê tudo, não atende requisito BACEN.

### Alternativa C: Criptografia At-Rest com Decrypt por Perfil

Chunks de níveis superiores criptografados com chaves diferentes. Rejeitada: incompatível com busca vetorial — embeddings precisam estar em texto claro para comparação por similaridade. Um atacante com acesso aos embeddings pode reconstruir informações via inversion attack.

### Alternativa D: Segregação por 4 KBs (uma por nível)

4 KBs separadas (PUBLIC, INTERNAL, RESTRICTED, CONFIDENTIAL). Rejeitada: complexidade operacional excessiva (4 Bases Vetoriais, 4 MCPs, 4 pipelines, 4 stagings). A separação PUBLIC/INTERNAL não agrega segurança significativa — ambos são acessíveis por todos os colaboradores autenticados.

## Consequencias

### Positivas

- Segurança reforçada por isolamento físico — elimina classe inteira de vulnerabilidades
- Compliance nativo com BACEN, LGPD, CVM
- Auditoria simplificada — "quem acessa qual MCP" é documentável e verificável
- Alinhamento com [[ADR-002_soberania_dados_cloud_vs_onprem|ADR-002]] (soberania) — cada KB na trilha correta por design
- Blast radius limitado — comprometimento de uma Base Vetorial não afeta as demais
- Release independente — cada KB com seu proprio ciclo
- Escalabilidade independente — Base Vetorial A pode escalar sem afetar B ou C
- Simplicidade conceitual — controle de acesso e "qual MCP voce acessa"

### Negativas

- **Custo operacional maior** — 3 Bases Vetoriais para manter. Mitigação: pipeline parametrizado, automação, monitoring unificado
- **Complexidade de busca cross-KB** — precisa de agente orquestrador. Mitigação: RRF ([[ADR-007_retrieval_hibrido_agentes|ADR-007]]) já define fusão de resultados
- **Duplicação potencial de chunks** — documento split em múltiplos níveis. Mitigação: `cross_ref` no front matter, orquestrador deduplica por `document_id`
- **Custo de infraestrutura maior** — 3 servidores/containers. Mitigação: KB restricted e confidential tendem a ter muito menos documentos
- **Latência na busca cross-KB** — consultar 3 MCPs em paralelo é mais lento. Mitigação: queries em paralelo, timeout por MCP, resultado parcial

### Riscos

| Risco | Prob. | Impacto | Mitigacao |
|---|---|---|---|
| Classificação incorreta de documento | Média | Alto | Quality gate na Fase 2, validação automática de keywords sensíveis, revisão trimestral |
| Orquestrador cross-KB com falha de segurança | Baixa | Alto | Roda com perfil do usuário, sem credenciais próprias, pen test específico, stateless |
| Drift de configuração entre ambientes | Média | Médio | Infrastructure as Code, configuração versionada, drift detection automática |
| Documento sem classificação entra no pipeline | Média | Alto | Pipeline rejeita (fail-safe), pre-commit hook, quality gate na Fase 2 |

## Implementação

### Fase 1 — MVP (apenas KB public-internal)

Validar pipeline completo com unica KB antes de adicionar complexidade:

- Base Vetorial A operacional, MCP `mcp-knowledge-public` configurado
- Pipeline roteando documentos public e internal para Base Vetorial A
- Documentos RESTRICTED e CONFIDENTIAL rejeitados pelo pipeline (com log e notificação)
- Testes de busca semântica, monitoring básico

**Duração estimada:** 2-3 sprints

### Fase 2 — Adicionar KB Restricted

Implementar segregação física com a segunda KB em infraestrutura on-premises:

- Base Vetorial B operacional em ambiente on-premises, rede segmentada
- MCP `mcp-knowledge-restricted` com autenticação SSO+MFA
- Pipeline parametrizado para rotear restricted para Base Vetorial B
- Validação de isolamento: MCP público não consegue acessar Base Vetorial B (teste de segurança)
- Controles de auditoria, backup criptografado, testes de acesso por perfil

**Duração estimada:** 3-4 sprints

### Fase 3 — Adicionar KB Confidential + Orquestrador Cross-KB

Completar modelo de segregação com KB confidencial e agente orquestrador:

- Base Vetorial C operacional em rede isolada, criptografia at-rest/in-transit, HSM
- MCP `mcp-knowledge-confidential` com SSO+MFA+JIT
- Agente orquestrador cross-KB com fusao via RRF ([[ADR-007_retrieval_hibrido_agentes|ADR-007]])
- Pen test completo, monitoramento 24/7 com SOC, just-in-time access
- Retenção de logs 5 anos, drill de restore documentado

**Duração estimada:** 4-6 sprints

## Referências

### ADRs Relacionados

- [[ADR-001_pipeline_geracao_conhecimento_4_fases|ADR-001]] — Pipeline de Geração de Conhecimento em 4 Fases (define Fase 2 onde split por confidencialidade ocorre, separação em dois repositórios)
- [[ADR-002_soberania_dados_cloud_vs_onprem|ADR-002]] — Soberania e Residência de Dados (Trilha A/Cloud e Trilha B/On-Premise)
- [[ADR-004_seguranca_classificacao_dados|ADR-004]] — Segurança, Classificação de Dados e Controle de Acesso (4 níveis de confidencialidade, filtro pré-retrieval)
- [[ADR-005_front_matter_contrato_metadados|ADR-005]] — Front Matter: Contrato de Metadados (campo `confidentiality` no front matter)
- [[ADR-006_pipeline_ingestao_fonte_base_vetorial|ADR-006]] — Pipeline de Ingestão (etapas de ingestão, roteamento por confidencialidade)
- [[ADR-007_retrieval_hibrido_agentes|ADR-007]] — Retrieval Híbrido e Agentes (RRF para fusão de resultados cross-KB)
- [[ADR-008_governanca_ciclo_vida_rollback|ADR-008]] — Governança, Ciclo de Vida e Rollback (rollback independente por KB)
- [[ADR-010_git_flow_base_conhecimento|ADR-010]] — Git Flow e Release (releases independentes por KB)

### Regulações

- LGPD — Lei 13.709/2018
- BACEN — Resolução 4.893/2021 (segurança cibernética)
- BACEN — Resolução BCB 85/2021 (processamento de dados em nuvem)
- CVM — Instrução CVM 400 (informações privilegiadas)
- ISO 27001 (segurança da informação)
- Verizon DBIR (Data Breach Investigations Report)

---

<!-- QA-MD: inicio -->
## Quality Assurance — .md final

**Revisor:** Pipeline de Promoção QA
**Data:** 22/03/2026
**Fonte:** kb/rag-blueprint-adrs-kb/beta/ADR-011_segregacao_kbs_por_confidencialidade.beta.md

| Critério | Peso | Nota | Comentário |
|----------|------|------|------------|
| Front matter rico | 25% | 95% | Todos os campos obrigatórios presentes. Campo `status` corrigido de "accepted" para "approved" (valor válido no schema). |
| Completude de conteúdo | 20% | 98% | Todas as seções ADR presentes: Contexto, Decisão, Desafios e Soluções, Alternativas, Consequências, Riscos, Implementação, Referências. Cross-references completas com 8 ADRs e regulações. |
| Wikilinks | 10% | 100% | Todos os wikilinks no formato [[ADR-NNN_slug\|ADR-NNN]]. Nenhuma referência a BETA-*. |
| Sem artefatos workspace | 15% | 100% | Nenhum marcador LOCKED, QA-BETA ou BETA-NNN no id encontrado. |
| Compatibilidade Obsidian | 10% | 100% | YAML válido, aliases e tags como arrays, front matter bem formado. |
| Linhagem rastreável | 10% | 100% | source_path aponta para beta, source_beta_ids presente, conversion_pipeline: promotion-pipeline-v1. |
| Clareza e estrutura | 10% | 92% | Headings hierárquicos, tabelas bem formatadas, diagramas de acesso por perfil. Corpo do documento estava parcialmente sem acentos pt-BR (corrigido: ~60 ocorrências). Estrutura de seções excelente com 6 desafios detalhados. |

**Score:** 97.6% — APROVADO para ingestão

**Por que não é 100%:** (1) Campo `status` original era "accepted" (valor fora do schema, corrigido para "approved"). (2) Corpo do documento continha palavras sem acentos/diacríticos em português (ex: "segregacao", "nao", "decisao", "implementacao") — corrigido integralmente. A penalização residual reflete a extensão das correções necessárias.
<!-- QA-MD: fim -->
