---
id: ADR-C05
doc_type: adr
title: "Runbook: Resposta a Incidente de PII"
system: RAG Corporativo
module: Incidente PII
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - incidente pii
  - resposta incidente
  - contenção dados
  - remoção base vetorial
  - vazamento dados pessoais
  - lgpd artigo 48
  - anpd comunicação
  - severidade crítica
  - sla contenção
  - blocklist retrieval
  - api parada emergência
  - evidência forense
  - chunks remoção
  - document remoção
  - repositório knowledge base
  - repositório workspace
  - git filter branch
  - bfg repo cleaner
  - histórico git limpeza
  - logs retrieval
  - logs resposta llm
  - compliance officer
  - dpo data protection officer
  - escalação incidente
  - matriz escalação
  - root cause analysis
  - rca pós incidente
  - ações preventivas
  - scanner pii
  - golden set testes
  - validação output
  - bacen resolução
  - cvm instrução
  - mnpi informação
  - retenção logs cinco anos
  - titulares afetados
  - direito eliminação
  - anonimização fontes
  - comitê crise
  - canal incidentes
  - comunicação segura
  - classificação severidade
  - pipeline anonimização
  - ner regex atualização
  - treinamento curadores
  - checklist resumido
  - cinco passos urgentes
  - contenção quinze minutos
  - remoção uma hora
  - impacto classificação
  - usuário não autorizado
  - cache purga
aliases:
  - "ADR-C05"
  - "Incidente PII Runbook"
  - "Resposta a Vazamento de Dados Pessoais"
  - "Procedimento de Contenção PII"
  - "Runbook Incidente LGPD"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-C05_incidente_pii.beta.md"
source_beta_ids:
  - "BETA-C05"
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

# ADR-C05 — Runbook: Resposta a Incidente de PII

## Objetivo

Procedimento operacional para resposta a incidentes envolvendo dados pessoais (PII) na base de conhecimento corporativa. Define os 5 passos urgentes de contenção e remediação, SLAs, escalação e ações pós-incidente.

Este runbook implementa o Cenário C (Rollback Urgente — PII/Vazamento) do Pilar 3 da [[ADR-008]] e complementa os controles do Pilar 6 da [[ADR-004]].

**PREMISSA CRÍTICA:** qualquer pessoa pode acionar este procedimento sem aprovação prévia. A contenção tem prioridade absoluta sobre qualquer outro processo em andamento.

## Seção 1 — Classificação do Incidente

Um incidente de PII é confirmado quando:
- Dados pessoais identificáveis foram indexados na base vetorial sem anonimização adequada; OU
- Dados pessoais foram servidos a usuários ou agentes que não deveriam ter acesso; OU
- Dados pessoais foram expostos em logs, caches ou respostas da LLM.

**Níveis de severidade:**

**CRÍTICO** — PII servida a usuário/agente não autorizado
- SLA de contenção: 15 minutos
- SLA de remoção completa: 4 horas
- Notificação: Compliance Officer imediata (15 min)
- Possível reporte à ANPD (art. 48 LGPD): 2 dias úteis

**ALTO** — PII indexada mas sem evidência de acesso não autorizado
- SLA de contenção: 1 hora
- SLA de remoção completa: 4 horas
- Notificação: Compliance Officer em até 1 hora

**MÉDIO** — PII detectada em documento pré-ingestão (antes da base vetorial)
- SLA de contenção: 4 horas
- SLA de remoção completa: 24 horas
- Notificação: Compliance Officer em até 4 horas

## Seção 2 — Os 5 Passos Urgentes

### Passo 1 — Conter

- **SLA:** 15 minutos a partir da detecção
- **Responsável:** Ops ou Engenheiro (quem detectar primeiro)
- **Escalação:** Compliance Officer notificado nos primeiros 15 minutos

**Ações:**

**1.1** Verificar imediatamente se os dados já foram servidos a usuários. Consultar logs de retrieval dos últimos 7 dias para o document_id afetado.

**1.2** Executar UMA das ações de contenção (a mais rápida disponível):

- **OPÇÃO A — Adicionar documento à blocklist de retrieval**
  - Efeito: documento não aparece em buscas, mas permanece na base.
  - Quando usar: se blocklist está implementada e testada.
  - Tempo estimado: 1-2 minutos.

- **OPÇÃO B — Parar a API de busca**
  - Efeito: nenhum usuário consegue fazer queries.
  - Quando usar: se blocklist não está disponível OU se há múltiplos documentos afetados OU se severidade é CRÍTICA com evidência de acesso não autorizado.
  - Tempo estimado: 1-5 minutos.

**1.3** Notificar Compliance Officer com:
- document_id(s) afetado(s)
- tipo de PII detectada
- evidência preliminar de acesso (servido ou não)
- ação de contenção executada
- timestamp da detecção e da contenção

**1.4** Registrar no canal de incidentes:
- Quem detectou
- Como foi detectado (monitoramento automático, revisão manual, report)
- Timestamp
- Ação de contenção executada

> **ATENÇÃO:** NÃO tentar corrigir o documento neste passo. O objetivo é APENAS conter. Correção vem nos passos seguintes.

### Passo 2 — Remover da Base Vetorial

- **SLA:** 1 hora a partir da detecção
- **Responsável:** Engenheiro de Pipeline

**Ações:**

**2.1** Identificar TODOS os chunks do documento afetado na base vetorial. Query: buscar por document_id na base vetorial. Verificar se há chunks duplicados ou versões anteriores.

**2.2** ANTES de deletar, exportar os chunks para evidência forense:
- Salvar em diretório isolado com acesso restrito
- Incluir: chunk_id, document_id, texto do chunk, embedding, metadados, timestamps
- Este export é necessário para investigação e possível reporte à ANPD

**2.3** Deletar chunks e registro do documento da base vetorial:
- Remover todos os chunks (PART_OF relationship)
- Remover o nó Document
- Remover de índices vetoriais
- Remover de caches (se existirem)

**2.4** Verificar remoção:
- Buscar pelo document_id — deve retornar zero resultados
- Buscar pelos chunk_ids — deve retornar zero resultados
- Executar busca semântica com termos do documento — não deve retornar chunks deletados

**2.5** Se a API foi parada no Passo 1 (Opção B):
- Verificar que remoção foi completa
- Reativar a API
- Monitorar primeiras queries por 30 minutos

### Passo 3 — Remover do Repositório Knowledge-Base

- **SLA:** 2 horas a partir da detecção
- **Responsável:** Engenheiro de Pipeline

**Ações:**

**3.1** No repositório knowledge-base (rag-knowledge-base):
- Localizar o arquivo `.md` correspondente
- Decidir ação:
  - SE documento é exclusivo do titular (ex: ficha cadastral): Deletar arquivo completamente.
  - SE documento menciona o titular entre outros conteúdos: Anonimizar (substituir PII por placeholders).

**3.2** Avaliar necessidade de remoção do histórico Git:
- SE PII aparece em commits anteriores: Executar `git filter-branch` ou BFG Repo-Cleaner para reescrever histórico e remover PII de todas as versões. **ATENÇÃO:** esta operação é destrutiva e requer coordenação com todos os colaboradores do repositório.
- SE PII aparece apenas no commit mais recente: `git revert` pode ser suficiente (PII fica no histórico mas acessível apenas via Git — avaliar risco com Compliance).

**3.3** Confirmar que o `.md` foi removido/anonimizado com commit descritivo: Mensagem: `INCIDENTE-PII: remoção/anonimização de [document_id]`

### Passo 4 — Verificar Repositório Workspace

- **SLA:** 3 horas a partir da detecção
- **Responsável:** Curador de Conhecimento + Engenheiro de Pipeline

**Ações:**

**4.1** No repositório workspace (rag-workspace):
- Localizar o arquivo `.beta.md` correspondente
- Anonimizar ou deletar conforme decisão do Passo 3

**4.2** Verificar fontes brutas (pasta sources/):
- Localizar documentos originais que contêm a PII
- Fontes brutas podem MANTER PII se:
  - (a) acesso é restrito a service accounts e DPO, E
  - (b) há base legal para retenção (ex: contrato, obrigação legal)
- Se não há base legal: deletar ou anonimizar

**4.3** Verificar se há referências em outros documentos:
- Buscar pelo nome, CPF, email ou outros identificadores do titular em TODOS os repositórios
- Tratar cada referência encontrada conforme os mesmos critérios

**4.4** Registrar todas as ações realizadas com evidência.

### Passo 5 — Verificar Logs e Determinar Impacto

- **SLA:** 4 horas a partir da detecção
- **Responsável:** Operações (Ops) + Compliance Officer

**Ações:**

**5.1** Consultar logs de retrieval para determinar se PII foi servida:
- Buscar pelo document_id nos logs de queries
- Buscar pelos chunk_ids nos logs de retrieval
- Identificar: quais usuários receberam chunks com PII, quando (timestamps), quantas vezes, via qual endpoint/agente

**5.2** Consultar logs de resposta da LLM (se disponíveis):
- Verificar se a PII apareceu nas respostas geradas
- Verificar se a validação de output detectou e bloqueou

**5.3** Classificar o impacto:

**PII NÃO FOI SERVIDA (contida a tempo):**
- Incidente contido com sucesso
- Compliance Officer documenta e arquiva
- Não requer reporte à ANPD (salvo decisão do DPO)

**PII FOI SERVIDA a usuários autorizados:**
- Impacto moderado
- Compliance avalia necessidade de reporte
- Notificar usuários que receberam os dados

**PII FOI SERVIDA a usuários NÃO autorizados:**
- INCIDENTE CONFIRMADO
- Compliance Officer lidera procedimento ANPD
- Prazo para comunicação à ANPD: 2 dias úteis (art. 48 LGPD)
- Comunicação deve conter: natureza dos dados, titulares afetados, medidas de contenção, riscos, medidas para reverter/mitigar
- Avaliar necessidade de notificar os titulares (art. 48, §1)

**5.4** Registrar conclusão do Passo 5 com:
- Resumo do impacto
- Lista de usuários que acessaram os dados (se aplicável)
- Decisão sobre reporte à ANPD
- Próximos passos (pós-incidente)

## Seção 3 — Pós-Incidente (até 5 dias úteis)

### 3.1 Root Cause Analysis (RCA)

- **Responsável:** Arquiteto (coordena) + envolvidos no incidente
- **Prazo:** 5 dias úteis após resolução

**Conteúdo do RCA:**
- Timeline completa (detecção → contenção → resolução)
- Causa raiz: como a PII entrou na base sem anonimização? Exemplos: falha no pipeline de anonimização, documento ingerido sem passar pelo pipeline, classificação incorreta, novo tipo de PII não reconhecido, erro humano na revisão
- Impacto: quantos titulares, que tipo de dados, por quanto tempo
- Eficácia da resposta: SLAs cumpridos? Gaps no procedimento?
- Ações corretivas com responsável e prazo

### 3.2 Ações preventivas (exemplos)

- Atualizar modelos NER/regex para detectar o tipo de PII que falhou.
- Implementar ou atualizar scanner automático de PII pré-ingestão.
- Expandir blocklist com padrões identificados no incidente.
- Treinamento para Curadores sobre identificação de PII.
- Adicionar caso ao golden set de testes.
- Revisar e fortalecer validação de output da LLM.

### 3.3 Documentação

- RCA documentado no repositório knowledge-base (sem PII no RCA).
- Atualização deste runbook se gaps forem identificados.
- Atualização do pipeline de anonimização ([[ADR-C04]]) se aplicável.
- Registro no log de incidentes com retenção de 5 anos (BACEN).

## Seção 4 — Matriz de Escalação

| Tempo desde detecção | Se não resolvido, escalar para |
|---|---|
| 15 minutos | Compliance Officer (se ainda não notificado) |
| 30 minutos | Arquiteto + Gerente de Engenharia |
| 1 hora | DPO (Data Protection Officer) |
| 2 horas | Diretor de Tecnologia |
| 4 horas | Comitê de Crise (se PII servida) |

**Canais de comunicação (em ordem de prioridade):**
1. Mensagem direta (telefone/chat) para Compliance Officer
2. Canal de incidentes (chat corporativo)
3. Email para lista de distribuição de incidentes

**REGRA:** nunca incluir a PII real nas comunicações de escalação. Referenciar por document_id e tipo de dado apenas.

## Seção 5 — Checklist Resumido (para impressão/rápido acesso)

- [ ] **PASSO 1 — CONTER (15 min)**
  - [ ] Verificar se dados foram servidos (logs)
  - [ ] Blocklist OU parar API
  - [ ] Notificar Compliance
  - [ ] Registrar no canal de incidentes

- [ ] **PASSO 2 — REMOVER DA BASE VETORIAL (1 hora)**
  - [ ] Identificar todos os chunks
  - [ ] Exportar evidência forense
  - [ ] Deletar chunks e documento
  - [ ] Verificar remoção (busca por ID e semântica)
  - [ ] Reativar API (se parada)

- [ ] **PASSO 3 — REMOVER DO KNOWLEDGE-BASE REPO (2 horas)**
  - [ ] Deletar ou anonimizar .md
  - [ ] Avaliar limpeza de histórico Git
  - [ ] Commit com mensagem "INCIDENTE-PII"

- [ ] **PASSO 4 — VERIFICAR WORKSPACE REPO (3 horas)**
  - [ ] Anonimizar/deletar .beta.md
  - [ ] Verificar fontes brutas (sources/)
  - [ ] Buscar referências em outros documentos

- [ ] **PASSO 5 — VERIFICAR LOGS E IMPACTO (4 horas)**
  - [ ] Consultar logs de retrieval
  - [ ] Consultar logs de resposta LLM
  - [ ] Classificar impacto
  - [ ] Decidir sobre reporte ANPD (se PII servida: 2 dias úteis)

- [ ] **PÓS-INCIDENTE (5 dias úteis)**
  - [ ] Root Cause Analysis
  - [ ] Ações preventivas definidas e atribuídas
  - [ ] Documentação registrada

## Seção 6 — Requisitos Legais (Referência)

**LGPD — Lei 13.709/2018:**
- Art. 48: comunicação à ANPD em prazo razoável (regulamentação ANPD define 2 dias úteis) em caso de incidente de segurança que possa acarretar risco ou dano relevante aos titulares.
- Art. 48, §1: comunicação deve conter: natureza dos dados pessoais afetados, informações sobre titulares envolvidos, medidas técnicas e de segurança, riscos relacionados, medidas adotadas para reverter ou mitigar.
- Art. 18, VI: direito à eliminação dos dados pessoais tratados com consentimento do titular.

**BACEN — Resolução 4.893/2021:**
- Rastreabilidade e auditoria obrigatórias.
- Retenção de logs: mínimo 5 anos.
- Plano de resposta a incidentes documentado e testado.

**CVM — Instrução 358/2002:**
- Se PII vazada inclui MNPI (informação não-pública de mercado), notificar área de Compliance de mercado de capitais adicionalmente.

## Referências

- [[ADR-008]] — Governança: Papéis, Ciclo de Vida e Rollback (Pilar 3, Cenário C)
- [[ADR-004]] — Estratégia de Segurança e Classificação de Dados (Pilar 6)
- [[ADR-C04]] — Pipeline de Anonimização de PII
- LGPD — Lei 13.709/2018 (art. 48, art. 18)
- BACEN Resolução 4.893/2021
- ANPD — Regulamento de Comunicação de Incidentes de Segurança

<!-- conversion_quality: 95 -->
