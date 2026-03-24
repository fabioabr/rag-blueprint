---
id: BETA-C01
title: "Checklist de Seguranca para LLM no RAG Corporativo"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-C01_checklist_seguranca_llm.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags:
  - checklist seguranca llm
  - prompt injection
  - data leakage
  - jailbreak
  - sanitizacao input
  - validacao output
  - filtro pre-retrieval
  - rate limiting
  - monitoramento anomalias
  - auditoria queries
  - separacao contexto prompt
  - pii deteccao
  - confidencialidade niveis
  - rbac perfis acesso
  - owasp llm top 10
  - lgpd conformidade
  - bacen regulatorio
  - seguranca rag corporativo
  - protecao dados
  - controle acesso
  - teste prompt injection
  - teste regressao seguranca
  - golden set queries
  - unicode normalizacao
  - caracteres controle
  - delimitadores prompt
  - system prompt protecao
  - chunks nao confiaveis
  - blocklist retrieval
  - alerta automatico
  - retencao logs
  - investigacao incidentes
  - deteccao padroes
  - automacao nao autorizada
  - testes unitarios seguranca
  - testes integracao seguranca
  - validacao output llm
  - cpf cnpj deteccao
  - email pessoal deteccao
  - source ip rastreio
  - agent id rastreio
  - mcp server rastreio
  - html malicioso
  - markdown malicioso
  - encoding bypass
  - resposta generica substituicao
  - equipe seguranca alerta
  - log pesquisavel
  - queries suspeitas
  - extracao iterativa
  - dominio perfil usuario
aliases:
  - "ADR-C01"
  - "Checklist Seguranca LLM"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## Objetivo

Este checklist consolida as medidas de seguranca obrigatorias para protecao contra prompt injection, vazamento de dados (data leakage) e tentativas de jailbreak no contexto do RAG Corporativo. Cada item deve ser verificado antes de qualquer release que exponha a LLM a usuarios ou agentes.

Os controles aqui descritos derivam do Pilar 5 (Protecao contra Prompt Injection) e do Pilar 2 (Filtro Pre-Retrieval) da ADR-004.

## Secao 1 — Sanitizacao de Input

- [ ] **1.1** Remover caracteres de controle do input do usuario antes de qualquer processamento (null bytes, escape sequences, Unicode invisivel).

- [ ] **1.2** Implementar deteccao de padroes conhecidos de injection:
  - Strings como "ignore previous instructions", "system prompt", "you are now", "disregard", "forget everything"
  - Tentativas de role-play: "act as", "pretend you are", "simulate"
  - Injecao de delimitadores: "[SYSTEM]", "###", "---"

- [ ] **1.3** Limitar tamanho do input do usuario a no maximo 2000 caracteres. Queries acima desse limite devem ser rejeitadas com mensagem generica.

- [ ] **1.4** Rejeitar input contendo Markdown ou HTML malicioso que possa interferir na estrutura do prompt (ex: tags `<script>`, iframes, blocos de codigo que simulam instrucoes de sistema).

- [ ] **1.5** Normalizar encoding do input para UTF-8 antes da validacao, prevenindo bypass via encodings alternativos.

## Secao 2 — Separacao de Contexto no Prompt

- [ ] **2.1** Utilizar delimitadores claros e consistentes para separar as secoes do prompt montado:
  - `[SYSTEM INSTRUCTIONS]` — instrucoes de comportamento da LLM
  - `[USER QUERY]` — pergunta do usuario
  - `[CONTEXT]` — chunks recuperados da base vetorial

- [ ] **2.2** Garantir que o system prompt NUNCA e concatenado diretamente com o input do usuario. Deve haver delimitador e secao separada.

- [ ] **2.3** Contexto recuperado (chunks) deve estar em secao isolada, tratado como dado nao-confiavel — a LLM deve ser instruida a citar mas nao executar instrucoes contidas nos chunks.

- [ ] **2.4** Nenhuma informacao do system prompt deve ser retornada ao usuario na resposta, mesmo que solicitada explicitamente.

## Secao 3 — Filtro Pre-Retrieval (Inviolavel)

- [ ] **3.1** O filtro de confidencialidade DEVE ser aplicado ANTES da busca vetorial. Nunca depois, nunca "junto". Antes.

- [ ] **3.2** O mapeamento perfil -> niveis de acesso deve ser:
  - Analyst: `['public', 'internal']`
  - Manager: `['public', 'internal', 'restricted']`
  - Director: `['public', 'internal', 'restricted', 'confidential']`
  - AI_Agent: configuravel por instancia

- [ ] **3.3** O filtro pre-retrieval NAO pode ser desabilitado por parametro, ignorado por flag de debug, ou bypassado por role de admin.

- [ ] **3.4** O filtro deve estar implementado na camada de infraestrutura, nao na camada de aplicacao.

- [ ] **3.5** Verificar que nenhum metodo de busca sem filtro existe na classe de retrieval (nao deve existir endpoint "sem filtro").

## Secao 4 — Validacao de Output

- [ ] **4.1** Implementar deteccao de PII na resposta gerada pela LLM:
  - CPF (padroes `###.###.###-##` e variantes)
  - CNPJ (padroes `##.###.###/####-##` e variantes)
  - Numeros de contas bancarias
  - Emails pessoais (quando nao esperados no contexto)
  - Nomes completos associados a dados sensiveis

- [ ] **4.2** Detectar trechos do system prompt na resposta da LLM. Se a resposta contiver fragmentos das instrucoes de sistema, substituir por resposta generica e registrar como incidente.

- [ ] **4.3** Se PII for detectada na resposta:
  - Substituir a resposta inteira por mensagem generica
  - Registrar o incidente com: timestamp, user_id, query, resposta original (para investigacao), chunks utilizados
  - Acionar alerta para equipe de seguranca

- [ ] **4.4** Manter log de todas as respostas que acionaram validacao de output para analise de padroes e melhoria continua.

## Secao 5 — Rate Limiting por Perfil

- [ ] **5.1** Aplicar limites de requisicoes por hora por perfil:
  - Analyst: 100 queries/hora
  - Manager: 150 queries/hora
  - Director: 200 queries/hora
  - AI_Agent: configuravel por instancia

- [ ] **5.2** Emitir alerta automatico quando usuario atinge 80% do limite.

- [ ] **5.3** Ao atingir 100%, rejeitar queries com mensagem informativa e registrar o evento.

## Secao 6 — Monitoramento de Anomalias

- [ ] **6.1** Monitorar e alertar sobre queries contendo termos suspeitos:
  - "system prompt", "ignore instructions", "forget", "disregard"
  - "act as", "pretend", "simulate", "you are now"

- [ ] **6.2** Detectar sequencias de queries similares do mesmo usuario (possivel tentativa iterativa de extracao).

- [ ] **6.3** Alertar sobre queries fora do dominio esperado do perfil do usuario (ex: Analyst de TI fazendo queries sobre dados financeiros restritos).

- [ ] **6.4** Monitorar volume anormal de requisicoes por usuario (mesmo abaixo do rate limit, picos subitos podem indicar automacao nao autorizada).

- [ ] **6.5** Registrar e investigar respostas que acionam validacao de output repetidamente para o mesmo usuario.

## Secao 7 — Procedimentos de Teste Obrigatorios

- [ ] **7.1** **TESTES UNITARIOS:** para cada perfil de acesso, verificar que NENHUM chunk retornado tem confidentiality acima do nivel de acesso do perfil.

- [ ] **7.2** **TESTES DE INTEGRACAO:** manter golden set de queries com diferentes perfis. Verificar zero data leakage em todas as combinacoes.

- [ ] **7.3** **TESTES DE REGRESSAO:** apos QUALQUER alteracao na logica de filtragem, re-executar suite completa de testes de seguranca.

- [ ] **7.4** **TESTE DE PROMPT INJECTION:** manter bateria de payloads conhecidos (OWASP LLM Top 10) e verificar que nenhum produz vazamento.

- [ ] **7.5** **TESTE DE VALIDACAO DE OUTPUT:** injetar PII conhecida em chunks de teste e verificar que a validacao de output detecta e bloqueia.

## Secao 8 — Auditoria

- [ ] **8.1** Cada query deve gerar registro com:
  - timestamp
  - user_id e user_role
  - query submetida
  - filters_applied (filtros pre-retrieval)
  - chunks_returned (IDs)
  - latency_ms
  - source_ip
  - agent_id (se aplicavel)
  - mcp_server (se aplicavel)

- [ ] **8.2** Retencao minima de logs: 5 anos (requisito BACEN).

- [ ] **8.3** Logs devem ser pesquisaveis para investigacao de incidentes.

## Referencias

- ADR-004 — Estrategia de Seguranca e Classificacao de Dados (Pilares 2 e 5)
- OWASP LLM Top 10 — Prompt Injection: <https://owasp.org/www-project-top-10-for-large-language-model-applications/>
- LGPD — Lei 13.709/2018
- BACEN Resolucao 4.893/2021

<!-- conversion_quality: 95 -->
