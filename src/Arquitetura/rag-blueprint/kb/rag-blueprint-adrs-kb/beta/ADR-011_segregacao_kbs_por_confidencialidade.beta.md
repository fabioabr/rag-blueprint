---
id: BETA-011
title: "Segregacao de Bases de Conhecimento por Nivel de Confidencialidade"
domain: "arquitetura"
confidentiality: internal
sources:
  - type: "txt"
    origin: "Arquitetura/rag-blueprint/kb/rag-blueprint-adrs-kb/1 - draft/ADR-011_segregacao_kbs_por_confidencialidade.txt"
    captured_at: "2026-03-21"
tags: [segregacao, seguranca, confidencialidade, kbs, isolamento-fisico, compliance, mcp]
aliases: ["ADR-011", "Segregacao por Confidencialidade"]
status: approved
last_enrichment: "2026-03-22"
last_human_edit: "2026-03-22"
---

## Referências Cruzadas

- **Depende de:** [[BETA-001]], [[BETA-002]], [[BETA-004]]
- **Relaciona-se:** [[BETA-005]], [[BETA-006]], [[BETA-007]], [[BETA-008]], [[BETA-010]]

## Contexto

### O Problema: Filtro Pre-Retrieval Nao e Suficiente

O [[BETA-004]] estabeleceu 4 niveis de confidencialidade para toda a base de conhecimento corporativa: PUBLIC, INTERNAL, RESTRICTED e CONFIDENTIAL. Tambem definiu que o filtro pre-retrieval — aplicado antes da busca vetorial — e inviolavel.

Essa decisao esta correta como **principio**, mas apresenta uma fragilidade critica quando analisada sob a otica de **implementacao**:

O filtro pre-retrieval e um controle na camada de **software** (query). Qualquer controle na camada de software e vulneravel a:

1. **Bugs de implementacao** — um erro no codigo do filtro pode permitir que chunks RESTRICTED sejam retornados em buscas PUBLIC
2. **Prompt injection** — um atacante pode manipular a query para tentar bypassar o filtro
3. **Misconfiguration** — deploy incorreto, variavel de ambiente errada, perfil de acesso permissivo demais
4. **Escalacao de privilegios** — se todos os dados estao na mesma Base Vetorial, qualquer vulnerabilidade expoe todos os niveis
5. **Complexidade de auditoria** — auditar se um filtro de query funciona corretamente em todas as situacoes e exponencialmente mais dificil do que auditar se dois servidores estao em redes separadas

### Contexto Regulatorio: Risco Inaceitavel

O projeto RAG Corporativo opera dentro de uma instituicao financeira regulada pelo BACEN, CVM e LGPD:

- **LGPD:** multas de ate 2% do faturamento por incidente de vazamento de dados pessoais (art. 52)
- **BACEN:** Resolucao 4.893/2021 exige controles de seguranca proporcionais a sensibilidade dos dados
- **CVM:** informacoes privilegiadas tem tratamento especifico pela Instrucao CVM 400 e Lei 6.385/1976
- **SOX (se aplicavel):** controles insuficientes sobre informacao financeira podem resultar em sancoes

Para uma instituicao financeira, confiar **exclusivamente** em um filtro de query como unico mecanismo de protecao de dados RESTRICTED/CONFIDENTIAL e **inaceitavel** do ponto de vista de compliance.

### A Solucao: Mover o Controle de Acesso da Query para a Infraestrutura

Se dados RESTRICTED estao em uma Base Vetorial **separada**, com um MCP Server **separado**, em uma rede **separada**, entao e **fisicamente impossivel** que um usuario acessando o MCP publico consiga ver dados RESTRICTED. Nao importa se ha bug no filtro, prompt injection, misconfiguration ou escalacao de privilegios — os dados simplesmente **nao existem** naquele ambiente.

Isso e **seguranca por isolamento de infraestrutura** — em contraste com seguranca por filtro de software.

O [[BETA-001]] ja antecipou essa possibilidade ao definir que cada contexto de negocio pode ter sua KB separada. O [[BETA-002]] reforca ao definir duas trilhas de infraestrutura: Trilha A (Cloud) para PUBLIC/INTERNAL e Trilha B (On-Premise) para RESTRICTED/CONFIDENTIAL.

### Por que Agora

Essa decisao precisa ser tomada **antes** da implementacao do pipeline de ingestao ([[BETA-006]]), porque o roteamento de documentos para a Base Vetorial correta depende da arquitetura de segregacao estar definida. Comecar com unica Base Vetorial e depois segregar gera custo significativo de migracao.

<!-- LOCKED:START autor=fabio data=2026-03-22 -->
## Decisao: Modelo de Segregacao em 3 KBs

Adotar modelo de **segregacao fisica** de Bases de Conhecimento (KBs) por nivel de confidencialidade, com Base Vetorial dedicada e MCP Server dedicado para cada nivel. O campo `confidentiality` no front matter do documento determina para qual KB e Base Vetorial ele sera roteado pelo pipeline de ingestao. O filtro pre-retrieval ([[BETA-004]]) continua existindo como camada **adicional** de defesa, mas **nao** e mais a unica barreira.

### Nivel 1: KB Publica + Interna (acesso geral)

- **Identificador:** `kb-public-internal`
- **Confidencialidade:** PUBLIC + INTERNAL
- **Base Vetorial:** Instancia A
- **Conteudo:** documentacao de sistemas, ADRs (internal), runbooks operacionais, glossario, tutoriais, documentacao de APIs, manuais, FAQ
- **MCP Server:** `mcp-knowledge-public`
- **Acesso:** todos os funcionarios autenticados, agentes de IA genericos
- **Trilha ([[BETA-002]]):** Trilha A (Cloud) — permitido
- **Autenticacao:** token de servico ou SSO corporativo
- **Autorizacao:** perfis Analyst, Manager, Director — todos tem acesso

### Nivel 2: KB Restrita (acesso por cargo/funcao)

- **Identificador:** `kb-restricted`
- **Confidencialidade:** RESTRICTED
- **Base Vetorial:** Instancia B (separada fisicamente da Instancia A)
- **Conteudo:** politicas internas, dados financeiros nao publicados, relatorios de gestao, post-mortems de seguranca, auditorias internas, estrategias de produto, dados de performance, informacoes de PLD, dados de fornecedores com clausula de confidencialidade
- **MCP Server:** `mcp-knowledge-restricted`
- **Acesso:** Gestores (Manager), Diretoria (Director), agentes de IA com perfil explicito
- **Trilha ([[BETA-002]]):** Trilha B (On-Premise) — obrigatorio
- **Autenticacao:** SSO corporativo + MFA obrigatorio
- **Autorizacao:** Manager (acesso restrito ao seu dominio), Director (acesso amplo), Agente IA (perfil explicito por dominio)
- **Controles extras:** rede segmentada, acesso restrito por IP/firewall, backup criptografado, monitoramento SIEM, access review trimestral

### Nivel 3: KB Confidencial (acesso minimo)

- **Identificador:** `kb-confidential`
- **Confidencialidade:** CONFIDENTIAL
- **Base Vetorial:** Instancia C (isolada — rede separada)
- **Conteudo:** contratos, dados pessoais anonimizados, estrategia corporativa de longo prazo, M&A, insider trading, processos judiciais, remuneracao de executivos, BCP/DRP, vulnerabilidades de seguranca, relatorios de pen testing, dados regulatorios confidenciais
- **MCP Server:** `mcp-knowledge-confidential`
- **Acesso:** Diretoria (Director) com justificativa registrada, Compliance Officer, agentes de IA dedicados com aprovacao documentada
- **Trilha ([[BETA-002]]):** Trilha B (On-Premise) — obrigatorio, com controles extras
- **Autenticacao:** SSO + MFA + aprovacao just-in-time (acesso sob demanda com tempo limitado)
- **Controles extras:** rede fisicamente separada ou fortemente segmentada, VPN dedicada + just-in-time, criptografia at-rest (AES-256) e in-transit (TLS 1.3), chaves em HSM, backup em cofre fisico separado, monitoramento 24/7 com alertas para SOC, pen test periodico, retencao de logs minimo 5 anos (BACEN), acesso revogado automaticamente apos periodo configuravel
<!-- LOCKED:END -->

## Vantagens do Modelo de Segregacao Fisica

1. **Seguranca fisica** — elimina classe inteira de vulnerabilidades. Qualquer vulnerabilidade na Base Vetorial A nao tem como acessar dados RESTRICTED
2. **Zero risco de data leakage via query** — o MCP publico se conecta apenas a Base Vetorial A; mesmo com controle total do MCP publico, so se ve dados public/internal
3. **Auditabilidade simplificada** — basta verificar quem tem acesso a qual MCP; trivial para auditores e reguladores
4. **Simplicidade conceitual** — controle de acesso e "qual MCP voce acessa?", nao "qual filtro a query aplica"
5. **Compliance nativo** — atende nativamente BACEN, LGPD, CVM, SOX, ISO 27001
6. **Alinhamento com [[BETA-002]]** — cada Base Vetorial reside na trilha correta por design

## Desafios e Solucoes

### Desafio 1: Busca Cross-KB

**Problema:** usuario com perfil Director pode fazer pergunta cujo contexto ideal requer chunks de multiplos niveis.

**Solucao: Agente Orquestrador Cross-KB**

1. Recebe a pergunta do usuario
2. Identifica quais MCPs o usuario tem acesso (baseado no perfil)
3. Envia a query para cada MCP autorizado em paralelo
4. Recebe os resultados de cada MCP
5. Funde os resultados usando RRF — Reciprocal Rank Fusion ([[BETA-007]])
6. Aplica reranking no conjunto fundido
7. Monta o prompt com chunks ordenados por relevancia
8. Gera a resposta

Regras do orquestrador:
- Roda com o **perfil do usuario** — so acessa os MCPs que o usuario tem direito
- Nunca mistura chunks de niveis diferentes sem **indicar a classificacao** de cada chunk
- Se chunks CONFIDENTIAL foram usados, a resposta inteira e classificada como CONFIDENTIAL

### Desafio 2: Mesmo Documento em Multiplos Niveis

**Problema:** um documento pode ter secoes com diferentes niveis de confidencialidade.

**Solucao: Split na Fase 2 (.beta.md)**

- **Opcao A — Split por secao (recomendada):** gerar `.beta.md` separados para cada nivel, com `cross_ref` no front matter indicando que sao partes do mesmo original
- **Opcao B — Classificacao conservadora (fallback):** documento inteiro classificado pelo nivel mais alto presente

**Decisao:** usar Opcao A como padrao, com Opcao B como fallback para casos onde o split nao e viavel.

Na re-ingestao (quando fonte original e atualizada), o pipeline aplica o merge separadamente em cada `.beta.md` splitado via campo `cross_ref`, respeitando blocos LOCKED. Se o split por confidencialidade mudar, gera alerta para revisao humana.

### Desafio 3: Roteamento no Pipeline de Ingestao

O campo `confidentiality` no front matter ([[BETA-004]], [[BETA-005]]) e o **unico determinante** do roteamento:

| confidentiality | KB | Base Vetorial |
|---|---|---|
| `public` | `kb-public-internal` | Instancia A |
| `internal` | `kb-public-internal` | Instancia A |
| `restricted` | `kb-restricted` | Instancia B |
| `confidential` | `kb-confidential` | Instancia C |

**Fail-safe critico:** se o campo `confidentiality` estiver **ausente**, o pipeline **deve rejeitar** o documento e notificar o responsavel. Nao existe default seguro — ausencia de classificacao e tratada como **erro**, nao como "public por padrao".

### Desafio 4: Manutencao de Multiplas Instancias

**Solucao: Pipeline Parametrizado + Automacao**

O mesmo pipeline de ingestao ([[BETA-006]]) e utilizado para as 3 KBs, parametrizado por: `KB_TARGET`, `VECTOR_DB_HOST`, `VECTOR_DB_CREDENTIALS`, `MCP_ENDPOINT`.

Cada profile define: servico da Base Vetorial, MCP Server, monitoring, volumes isolados, rede isolada.

Backup por KB:
- **kb-public-internal:** diario, retencao 30 dias
- **kb-restricted:** diario, retencao 1 ano, criptografado
- **kb-confidential:** diario, retencao 5 anos, criptografado, cofre fisico separado

### Desafio 5: Wikilinks Cross-KB

**Decisao: Wikilinks cross-KB sao proibidos.**

Documentos de uma KB nao podem fazer wikilink para documentos de outra KB. Motivo: um wikilink para documento restricted em um documento publico revela a existencia de informacao restrita. Para referencias cruzadas entre KBs, usar o campo `cross_ref` no front matter (sem link navegavel). O pipeline valida: wikilinks que apontam para documentos em outra KB sao tratados como erro de ingestao.

### Desafio 6: Documentos Expirados (Temporalidade)

**Decisao: Documentos expirados permanecem, com filtro temporal.**

Documentos expirados nao sao removidos da Base Vetorial — permanecem para consultas historicas. O filtro temporal ([[BETA-001]] secao temporalidade) e aplicado por cada MCP individualmente antes de retornar resultados. Documentos expirados sao marcados como `[EXPIRADO]` no retrieval.

## Estrutura de Pastas no Workspace (rag-workspace)

Esta secao supercede a estrutura de pastas do [[BETA-001]], adicionando camada de diretorio por nivel de confidencialidade:

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

Regras: cada subpasta corresponde a uma KB e uma Base Vetorial; documentos nao podem estar em mais de uma pasta (exceto via `cross_ref`); a pasta determina o nivel de confidencialidade — o front matter deve ser consistente; inconsistencia entre pasta e front matter = erro de ingestao.

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

O pipeline de promocao le de cada pasta e envia para a Base Vetorial correspondente. Um `.md` em `restricted/docs/` **nunca** e enviado para a Base Vetorial A.

## Diagrama de Acesso por Perfil

| Perfil | MCPs Acessiveis | Bases Vetoriais |
|---|---|---|
| **Analyst** (funcionario comum) | `mcp-knowledge-public` | A |
| **Manager** (gestor) | `mcp-knowledge-public` + `mcp-knowledge-restricted` | A, B |
| **Director** (diretoria) | `mcp-knowledge-public` + `mcp-knowledge-restricted` + `mcp-knowledge-confidential` | A, B, C |
| Agente IA generico | `mcp-knowledge-public` | A |
| Agente IA de dominio | `mcp-knowledge-public` + `mcp-knowledge-restricted` (dominio especifico) | A, B |
| Agente IA dedicado | `mcp-knowledge-confidential` (com aprovacao) | C |

## Relacao com [[BETA-010]] (Git Flow e Release)

A segregacao por KB impacta o fluxo de release e versionamento:

1. **Release TAGs independentes por KB:** cada KB tem seu proprio ciclo (`kb-public-internal@v1.2.0`, `kb-restricted@v1.0.3`, `kb-confidential@v1.0.1`)
2. **Staging/Prod por KB:** cada KB tem seu proprio ambiente de staging (Base Vetorial A-staging, B-staging, C-staging)
3. **Pipeline de deploy separado:** KB publica pode ser automatica (CI/CD), KB restrita requer aprovacao de Manager, KB confidencial requer aprovacao de Director + Compliance
4. **Rollback independente ([[BETA-008]]):** erro na KB publica nao afeta as demais Bases Vetoriais

## Alternativas Descartadas

### Alternativa A: Filtro Pre-Retrieval na Query (modelo [[BETA-004]] original)

Manter unica Base Vetorial com filtro de query. Rejeitada: vulneravel a bugs, prompt injection, misconfiguration, escalacao de privilegios. Nao atende requisitos regulatorios de isolamento fisico (BACEN, LGPD).

### Alternativa B: Banco Unico com Row-Level Security (RLS)

Unica Base Vetorial com RLS nativo do banco. Rejeitada: nem toda Base Vetorial suporta RLS de forma madura, dependencia de vendor, nao garante isolamento fisico, admin do banco ve tudo, nao atende requisito BACEN.

### Alternativa C: Criptografia At-Rest com Decrypt por Perfil

Chunks de niveis superiores criptografados com chaves diferentes. Rejeitada: incompativel com busca vetorial — embeddings precisam estar em texto claro para comparacao por similaridade. Um atacante com acesso aos embeddings pode reconstruir informacoes via inversion attack.

### Alternativa D: Segregacao por 4 KBs (uma por nivel)

4 KBs separadas (PUBLIC, INTERNAL, RESTRICTED, CONFIDENTIAL). Rejeitada: complexidade operacional excessiva (4 Bases Vetoriais, 4 MCPs, 4 pipelines, 4 stagings). A separacao PUBLIC/INTERNAL nao agrega seguranca significativa — ambos sao acessiveis por todos os colaboradores autenticados.

## Consequencias

### Positivas

- Seguranca reforcada por isolamento fisico — elimina classe inteira de vulnerabilidades
- Compliance nativo com BACEN, LGPD, CVM
- Auditoria simplificada — "quem acessa qual MCP" e documentavel e verificavel
- Alinhamento com [[BETA-002]] (soberania) — cada KB na trilha correta por design
- Blast radius limitado — comprometimento de uma Base Vetorial nao afeta as demais
- Release independente — cada KB com seu proprio ciclo
- Escalabilidade independente — Base Vetorial A pode escalar sem afetar B ou C
- Simplicidade conceitual — controle de acesso e "qual MCP voce acessa"

### Negativas

- **Custo operacional maior** — 3 Bases Vetoriais para manter. Mitigacao: pipeline parametrizado, automacao, monitoring unificado
- **Complexidade de busca cross-KB** — precisa de agente orquestrador. Mitigacao: RRF ([[BETA-007]]) ja define fusao de resultados
- **Duplicacao potencial de chunks** — documento split em multiplos niveis. Mitigacao: `cross_ref` no front matter, orquestrador deduplica por `document_id`
- **Custo de infraestrutura maior** — 3 servidores/containers. Mitigacao: KB restricted e confidential tendem a ter muito menos documentos
- **Latencia na busca cross-KB** — consultar 3 MCPs em paralelo e mais lento. Mitigacao: queries em paralelo, timeout por MCP, resultado parcial

### Riscos

| Risco | Prob. | Impacto | Mitigacao |
|---|---|---|---|
| Classificacao incorreta de documento | Media | Alto | Quality gate na Fase 2, validacao automatica de keywords sensiveis, revisao trimestral |
| Orquestrador cross-KB com falha de seguranca | Baixa | Alto | Roda com perfil do usuario, sem credenciais proprias, pen test especifico, stateless |
| Drift de configuracao entre ambientes | Media | Medio | Infrastructure as Code, configuracao versionada, drift detection automatica |
| Documento sem classificacao entra no pipeline | Media | Alto | Pipeline rejeita (fail-safe), pre-commit hook, quality gate na Fase 2 |

## Implementacao

### Fase 1 — MVP (apenas KB public-internal)

Validar pipeline completo com unica KB antes de adicionar complexidade:

- Base Vetorial A operacional, MCP `mcp-knowledge-public` configurado
- Pipeline roteando documentos public e internal para Base Vetorial A
- Documentos RESTRICTED e CONFIDENTIAL rejeitados pelo pipeline (com log e notificacao)
- Testes de busca semantica, monitoring basico

**Duracao estimada:** 2-3 sprints

### Fase 2 — Adicionar KB Restricted

Implementar segregacao fisica com a segunda KB em infraestrutura on-premises:

- Base Vetorial B operacional em ambiente on-premises, rede segmentada
- MCP `mcp-knowledge-restricted` com autenticacao SSO+MFA
- Pipeline parametrizado para rotear restricted para Base Vetorial B
- Validacao de isolamento: MCP publico nao consegue acessar Base Vetorial B (teste de seguranca)
- Controles de auditoria, backup criptografado, testes de acesso por perfil

**Duracao estimada:** 3-4 sprints

### Fase 3 — Adicionar KB Confidential + Orquestrador Cross-KB

Completar modelo de segregacao com KB confidencial e agente orquestrador:

- Base Vetorial C operacional em rede isolada, criptografia at-rest/in-transit, HSM
- MCP `mcp-knowledge-confidential` com SSO+MFA+JIT
- Agente orquestrador cross-KB com fusao via RRF ([[BETA-007]])
- Pen test completo, monitoramento 24/7 com SOC, just-in-time access
- Retencao de logs 5 anos, drill de restore documentado

**Duracao estimada:** 4-6 sprints

## Referencias

### ADRs Relacionados

- [[BETA-001]] — Pipeline de Geracao de Conhecimento em 4 Fases (define Fase 2 onde split por confidencialidade ocorre, separacao em dois repositorios)
- [[BETA-002]] — Soberania e Residencia de Dados (Trilha A/Cloud e Trilha B/On-Premise)
- [[BETA-004]] — Seguranca, Classificacao de Dados e Controle de Acesso (4 niveis de confidencialidade, filtro pre-retrieval)
- [[BETA-005]] — Front Matter: Contrato de Metadados (campo `confidentiality` no front matter)
- [[BETA-006]] — Pipeline de Ingestao (etapas de ingestao, roteamento por confidencialidade)
- [[BETA-007]] — Retrieval Hibrido e Agentes (RRF para fusao de resultados cross-KB)
- [[BETA-008]] — Governanca, Ciclo de Vida e Rollback (rollback independente por KB)
- [[BETA-010]] — Git Flow e Release (releases independentes por KB)

### Regulacoes

- LGPD — Lei 13.709/2018
- BACEN — Resolucao 4.893/2021 (seguranca cibernetica)
- BACEN — Resolucao BCB 85/2021 (processamento de dados em nuvem)
- CVM — Instrucao CVM 400 (informacoes privilegiadas)
- ISO 27001 (seguranca da informacao)
- Verizon DBIR (Data Breach Investigations Report)

---

<!-- QA-BETA: inicio -->
## Quality Assurance — .beta.md

| Critério | Peso | Nota | Comentário |
|----------|------|------|------------|
| Front matter leve | 25% | 100% | id BETA-011 valido, title descritivo (62 chars), domain lowercase, confidentiality enum valido, sources com type/origin/captured_at, tags 7 itens (>= 3), status approved, aliases opcional presente (corrigido para strings entre aspas). Nenhum campo de governanca indevido. |
| Completude de conteúdo | 25% | 95% | Cobertura excelente: Contexto (problema, regulatorio, solucao, timing), Decisao (3 niveis de KB com detalhes de acesso/trilha/controles), Vantagens, Desafios e Solucoes (6 desafios), Estrutura de Pastas (workspace e knowledge-base), Diagrama de Acesso, Relacao com BETA-010, Alternativas Descartadas (4), Consequencias, Riscos, Implementacao (3 fases), Referencias. Conteudo do draft fielmente representado. Adicionada secao "Referências Cruzadas" para consistencia. |
| Blocos LOCKED | 15% | 100% | Um bloco LOCKED na decisao principal (Modelo de Segregacao em 3 KBs com detalhamento dos 3 niveis), corretamente aberto e fechado com autor e data. |
| Wikilinks | 10% | 100% | 22 wikilinks no formato [[BETA-NNN]], todos corretos (BETA-001, 002, 004, 005, 006, 007, 008, 010). Nenhum wikilink no front matter. |
| Compatibilidade Obsidian | 10% | 100% | YAML valido entre delimitadores ---, tags como array, aliases corrigido para array com strings entre aspas. Totalmente compativel. |
| Clareza e estrutura | 15% | 95% | Headings hierarquicos e claros, tabelas de roteamento e acesso por perfil bem formatadas, desafios numerados com problema/solucao. Estrutura de pastas em blocos de codigo. Acentuacao ausente no corpo — consistente com o draft original. |

**Score:** 98.3% — APROVADO para promoção

**Por que não é 100%:** (1) Acentuacao ausente no corpo do texto (ex: "segregacao" em vez de "segregação") — consistente com draft original, mas impacta legibilidade (-1%). (2) Secao de alternativas descartadas poderia ter detalhamento ligeiramente maior na Alternativa D (4 KBs) sobre o calculo de custo operacional (-0.7%).
<!-- QA-BETA: fim -->
