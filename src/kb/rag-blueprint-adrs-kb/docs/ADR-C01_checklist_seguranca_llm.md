---
id: ADR-C01
doc_type: adr
title: "Checklist de Segurança para LLM no RAG Corporativo"
system: RAG Corporativo
module: Segurança LLM
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - checklist segurança llm
  - prompt injection
  - data leakage
  - jailbreak
  - sanitização input
  - validação output
  - filtro pré retrieval
  - rate limiting
  - monitoramento anomalias
  - auditoria queries
  - separação contexto prompt
  - pii detecção
  - confidencialidade níveis
  - rbac perfis acesso
  - owasp llm top 10
  - lgpd conformidade
  - bacen regulatório
  - segurança rag corporativo
  - proteção dados
  - controle acesso
  - teste prompt injection
  - teste regressão segurança
  - golden set queries
  - unicode normalização
  - caracteres controle
  - delimitadores prompt
  - system prompt proteção
  - chunks não confiáveis
  - blocklist retrieval
  - alerta automático
  - retenção logs
  - investigação incidentes
  - detecção padrões
  - automação não autorizada
  - testes unitários segurança
  - testes integração segurança
  - validação output llm
  - cpf cnpj detecção
  - email pessoal detecção
  - source ip rastreio
  - agent id rastreio
  - mcp server rastreio
  - html malicioso
  - markdown malicioso
  - encoding bypass
  - resposta genérica substituição
  - equipe segurança alerta
  - log pesquisável
  - queries suspeitas
  - extração iterativa
  - domínio perfil usuário
aliases:
  - "ADR-C01"
  - "Checklist Segurança LLM"
  - "Segurança LLM RAG"
  - "Proteção contra Prompt Injection"
  - "Checklist Segurança RAG Corporativo"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-C01_checklist_seguranca_llm.beta.md"
source_beta_ids:
  - "BETA-C01"
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

# ADR-C01 — Checklist de Segurança para LLM no RAG Corporativo

## 1. Objetivo

Este checklist consolida as medidas de segurança obrigatórias para proteção contra prompt injection, vazamento de dados (data leakage) e tentativas de jailbreak no contexto do RAG Corporativo. Cada item deve ser verificado antes de qualquer release que exponha a LLM a usuários ou agentes.

Os controles aqui descritos derivam do Pilar 5 (Proteção contra Prompt Injection) e do Pilar 2 (Filtro Pré-Retrieval) da [[ADR-004]].

## 2. Sanitização de Input

- [ ] **2.1** Remover caracteres de controle do input do usuário antes de qualquer processamento (null bytes, escape sequences, Unicode invisível).

- [ ] **2.2** Implementar detecção de padrões conhecidos de injection:
  - Strings como "ignore previous instructions", "system prompt", "you are now", "disregard", "forget everything"
  - Tentativas de role-play: "act as", "pretend you are", "simulate"
  - Injeção de delimitadores: "[SYSTEM]", "###", "---"

- [ ] **2.3** Limitar tamanho do input do usuário a no máximo 2000 caracteres. Queries acima desse limite devem ser rejeitadas com mensagem genérica.

- [ ] **2.4** Rejeitar input contendo Markdown ou HTML malicioso que possa interferir na estrutura do prompt (ex: tags `<script>`, iframes, blocos de código que simulam instruções de sistema).

- [ ] **2.5** Normalizar encoding do input para UTF-8 antes da validação, prevenindo bypass via encodings alternativos.

## 3. Separação de Contexto no Prompt

- [ ] **3.1** Utilizar delimitadores claros e consistentes para separar as seções do prompt montado:
  - `[SYSTEM INSTRUCTIONS]` — instruções de comportamento da LLM
  - `[USER QUERY]` — pergunta do usuário
  - `[CONTEXT]` — chunks recuperados da base vetorial

- [ ] **3.2** Garantir que o system prompt NUNCA é concatenado diretamente com o input do usuário. Deve haver delimitador e seção separada.

- [ ] **3.3** Contexto recuperado (chunks) deve estar em seção isolada, tratado como dado não-confiável — a LLM deve ser instruída a citar mas não executar instruções contidas nos chunks.

- [ ] **3.4** Nenhuma informação do system prompt deve ser retornada ao usuário na resposta, mesmo que solicitada explicitamente.

## 4. Filtro Pré-Retrieval (Inviolável)

- [ ] **4.1** O filtro de confidencialidade DEVE ser aplicado ANTES da busca vetorial. Nunca depois, nunca "junto". Antes.

- [ ] **4.2** O mapeamento perfil → níveis de acesso deve ser:
  - Analyst: `['public', 'internal']`
  - Manager: `['public', 'internal', 'restricted']`
  - Director: `['public', 'internal', 'restricted', 'confidential']`
  - AI_Agent: configurável por instância

- [ ] **4.3** O filtro pré-retrieval NÃO pode ser desabilitado por parâmetro, ignorado por flag de debug, ou bypassado por role de admin.

- [ ] **4.4** O filtro deve estar implementado na camada de infraestrutura, não na camada de aplicação.

- [ ] **4.5** Verificar que nenhum método de busca sem filtro existe na classe de retrieval (não deve existir endpoint "sem filtro").

## 5. Validação de Output

- [ ] **5.1** Implementar detecção de PII na resposta gerada pela LLM:
  - CPF (padrões `###.###.###-##` e variantes)
  - CNPJ (padrões `##.###.###/####-##` e variantes)
  - Números de contas bancárias
  - Emails pessoais (quando não esperados no contexto)
  - Nomes completos associados a dados sensíveis

- [ ] **5.2** Detectar trechos do system prompt na resposta da LLM. Se a resposta contiver fragmentos das instruções de sistema, substituir por resposta genérica e registrar como incidente.

- [ ] **5.3** Se PII for detectada na resposta:
  - Substituir a resposta inteira por mensagem genérica
  - Registrar o incidente com: timestamp, user_id, query, resposta original (para investigação), chunks utilizados
  - Acionar alerta para equipe de segurança

- [ ] **5.4** Manter log de todas as respostas que acionaram validação de output para análise de padrões e melhoria contínua.

## 6. Rate Limiting por Perfil

- [ ] **6.1** Aplicar limites de requisições por hora por perfil:
  - Analyst: 100 queries/hora
  - Manager: 150 queries/hora
  - Director: 200 queries/hora
  - AI_Agent: configurável por instância

- [ ] **6.2** Emitir alerta automático quando usuário atinge 80% do limite.

- [ ] **6.3** Ao atingir 100%, rejeitar queries com mensagem informativa e registrar o evento.

## 7. Monitoramento de Anomalias

- [ ] **7.1** Monitorar e alertar sobre queries contendo termos suspeitos:
  - "system prompt", "ignore instructions", "forget", "disregard"
  - "act as", "pretend", "simulate", "you are now"

- [ ] **7.2** Detectar sequências de queries similares do mesmo usuário (possível tentativa iterativa de extração).

- [ ] **7.3** Alertar sobre queries fora do domínio esperado do perfil do usuário (ex: Analyst de TI fazendo queries sobre dados financeiros restritos).

- [ ] **7.4** Monitorar volume anormal de requisições por usuário (mesmo abaixo do rate limit, picos súbitos podem indicar automação não autorizada).

- [ ] **7.5** Registrar e investigar respostas que acionam validação de output repetidamente para o mesmo usuário.

## 8. Procedimentos de Teste Obrigatórios

- [ ] **8.1** **TESTES UNITÁRIOS:** para cada perfil de acesso, verificar que NENHUM chunk retornado tem confidentiality acima do nível de acesso do perfil.

- [ ] **8.2** **TESTES DE INTEGRAÇÃO:** manter golden set de queries com diferentes perfis. Verificar zero data leakage em todas as combinações.

- [ ] **8.3** **TESTES DE REGRESSÃO:** após QUALQUER alteração na lógica de filtragem, re-executar suíte completa de testes de segurança.

- [ ] **8.4** **TESTE DE PROMPT INJECTION:** manter bateria de payloads conhecidos (OWASP LLM Top 10) e verificar que nenhum produz vazamento.

- [ ] **8.5** **TESTE DE VALIDAÇÃO DE OUTPUT:** injetar PII conhecida em chunks de teste e verificar que a validação de output detecta e bloqueia.

## 9. Auditoria

- [ ] **9.1** Cada query deve gerar registro com:
  - timestamp
  - user_id e user_role
  - query submetida
  - filters_applied (filtros pré-retrieval)
  - chunks_returned (IDs)
  - latency_ms
  - source_ip
  - agent_id (se aplicável)
  - mcp_server (se aplicável)

- [ ] **9.2** Retenção mínima de logs: 5 anos (requisito BACEN).

- [ ] **9.3** Logs devem ser pesquisáveis para investigação de incidentes.

## 10. Referências

- [[ADR-004]] — Estratégia de Segurança e Classificação de Dados (Pilares 2 e 5)
- OWASP LLM Top 10 — Prompt Injection: <https://owasp.org/www-project-top-10-for-large-language-model-applications/>
- LGPD — Lei 13.709/2018
- BACEN Resolução 4.893/2021

<!-- conversion_quality: 95 -->
