---
id: BETA-C05
title: "Runbook: Resposta a Incidente de PII"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-C05_incidente_pii.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags:
  - incidente pii
  - resposta incidente
  - contencao dados
  - remocao base vetorial
  - vazamento dados pessoais
  - lgpd artigo 48
  - anpd comunicacao
  - severidade critica
  - sla contencao
  - blocklist retrieval
  - api parada emergencia
  - evidencia forense
  - chunks remocao
  - document remocao
  - repositorio knowledge base
  - repositorio workspace
  - git filter branch
  - bfg repo cleaner
  - historico git limpeza
  - logs retrieval
  - logs resposta llm
  - compliance officer
  - dpo data protection officer
  - escalacao incidente
  - matriz escalacao
  - root cause analysis
  - rca pos incidente
  - acoes preventivas
  - scanner pii
  - golden set testes
  - validacao output
  - bacen resolucao
  - cvm instrucao
  - mnpi informacao
  - retencao logs cinco anos
  - titulares afetados
  - direito eliminacao
  - anonimizacao fontes
  - comite crise
  - canal incidentes
  - comunicacao segura
  - classificacao severidade
  - pipeline anonimizacao
  - ner regex atualizacao
  - treinamento curadores
  - checklist resumido
  - cinco passos urgentes
  - contencao quinze minutos
  - remocao uma hora
  - impacto classificacao
  - usuario nao autorizado
  - cache purga
aliases:
  - "ADR-C05"
  - "Incidente PII Runbook"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## Objetivo

Procedimento operacional para resposta a incidentes envolvendo dados pessoais (PII) na base de conhecimento corporativa. Define os 5 passos urgentes de contencao e remediacao, SLAs, escalacao e acoes pos-incidente.

Este runbook implementa o Cenario C (Rollback Urgente — PII/Vazamento) do Pilar 3 da ADR-008 e complementa os controles do Pilar 6 da ADR-004.

**PREMISSA CRITICA:** qualquer pessoa pode acionar este procedimento sem aprovacao previa. A contencao tem prioridade absoluta sobre qualquer outro processo em andamento.

## Secao 1 — Classificacao do Incidente

Um incidente de PII e confirmado quando:
- Dados pessoais identificaveis foram indexados na base vetorial sem anonimizacao adequada; OU
- Dados pessoais foram servidos a usuarios ou agentes que nao deveriam ter acesso; OU
- Dados pessoais foram expostos em logs, caches ou respostas da LLM.

**Niveis de severidade:**

**CRITICO** — PII servida a usuario/agente nao autorizado
- SLA de contencao: 15 minutos
- SLA de remocao completa: 4 horas
- Notificacao: Compliance Officer imediata (15 min)
- Possivel reporte a ANPD (art. 48 LGPD): 2 dias uteis

**ALTO** — PII indexada mas sem evidencia de acesso nao autorizado
- SLA de contencao: 1 hora
- SLA de remocao completa: 4 horas
- Notificacao: Compliance Officer em ate 1 hora

**MEDIO** — PII detectada em documento pre-ingestao (antes da base vetorial)
- SLA de contencao: 4 horas
- SLA de remocao completa: 24 horas
- Notificacao: Compliance Officer em ate 4 horas

## Secao 2 — Os 5 Passos Urgentes

### Passo 1 — Conter

- **SLA:** 15 minutos a partir da deteccao
- **Responsavel:** Ops ou Engenheiro (quem detectar primeiro)
- **Escalacao:** Compliance Officer notificado nos primeiros 15 minutos

**Acoes:**

**1.1** Verificar imediatamente se os dados ja foram servidos a usuarios. Consultar logs de retrieval dos ultimos 7 dias para o document_id afetado.

**1.2** Executar UMA das acoes de contencao (a mais rapida disponivel):

- **OPCAO A — Adicionar documento a blocklist de retrieval**
  - Efeito: documento nao aparece em buscas, mas permanece na base.
  - Quando usar: se blocklist esta implementada e testada.
  - Tempo estimado: 1-2 minutos.

- **OPCAO B — Parar a API de busca**
  - Efeito: nenhum usuario consegue fazer queries.
  - Quando usar: se blocklist nao esta disponivel OU se ha multiplos documentos afetados OU se severidade e CRITICA com evidencia de acesso nao autorizado.
  - Tempo estimado: 1-5 minutos.

**1.3** Notificar Compliance Officer com:
- document_id(s) afetado(s)
- tipo de PII detectada
- evidencia preliminar de acesso (servido ou nao)
- acao de contencao executada
- timestamp da deteccao e da contencao

**1.4** Registrar no canal de incidentes:
- Quem detectou
- Como foi detectado (monitoramento automatico, revisao manual, report)
- Timestamp
- Acao de contencao executada

> **ATENCAO:** NAO tentar corrigir o documento neste passo. O objetivo e APENAS conter. Correcao vem nos passos seguintes.

### Passo 2 — Remover da Base Vetorial

- **SLA:** 1 hora a partir da deteccao
- **Responsavel:** Engenheiro de Pipeline

**Acoes:**

**2.1** Identificar TODOS os chunks do documento afetado na base vetorial. Query: buscar por document_id na base vetorial. Verificar se ha chunks duplicados ou versoes anteriores.

**2.2** ANTES de deletar, exportar os chunks para evidencia forense:
- Salvar em diretorio isolado com acesso restrito
- Incluir: chunk_id, document_id, texto do chunk, embedding, metadados, timestamps
- Este export e necessario para investigacao e possivel reporte a ANPD

**2.3** Deletar chunks e registro do documento da base vetorial:
- Remover todos os chunks (PART_OF relationship)
- Remover o no Document
- Remover de indices vetoriais
- Remover de caches (se existirem)

**2.4** Verificar remocao:
- Buscar pelo document_id — deve retornar zero resultados
- Buscar pelos chunk_ids — deve retornar zero resultados
- Executar busca semantica com termos do documento — nao deve retornar chunks deletados

**2.5** Se a API foi parada no Passo 1 (Opcao B):
- Verificar que remocao foi completa
- Reativar a API
- Monitorar primeiras queries por 30 minutos

### Passo 3 — Remover do Repositorio Knowledge-Base

- **SLA:** 2 horas a partir da deteccao
- **Responsavel:** Engenheiro de Pipeline

**Acoes:**

**3.1** No repositorio knowledge-base (rag-knowledge-base):
- Localizar o arquivo `.md` correspondente
- Decidir acao:
  - SE documento e exclusivo do titular (ex: ficha cadastral): Deletar arquivo completamente.
  - SE documento menciona o titular entre outros conteudos: Anonimizar (substituir PII por placeholders).

**3.2** Avaliar necessidade de remocao do historico Git:
- SE PII aparece em commits anteriores: Executar `git filter-branch` ou BFG Repo-Cleaner para reescrever historico e remover PII de todas as versoes. **ATENCAO:** esta operacao e destrutiva e requer coordenacao com todos os colaboradores do repositorio.
- SE PII aparece apenas no commit mais recente: `git revert` pode ser suficiente (PII fica no historico mas acessivel apenas via Git — avaliar risco com Compliance).

**3.3** Confirmar que o `.md` foi removido/anonimizado com commit descritivo: Mensagem: `INCIDENTE-PII: remocao/anonimizacao de [document_id]`

### Passo 4 — Verificar Repositorio Workspace

- **SLA:** 3 horas a partir da deteccao
- **Responsavel:** Curador de Conhecimento + Engenheiro de Pipeline

**Acoes:**

**4.1** No repositorio workspace (rag-workspace):
- Localizar o arquivo `.beta.md` correspondente
- Anonimizar ou deletar conforme decisao do Passo 3

**4.2** Verificar fontes brutas (pasta sources/):
- Localizar documentos originais que contem a PII
- Fontes brutas podem MANTER PII se:
  - (a) acesso e restrito a service accounts e DPO, E
  - (b) ha base legal para retencao (ex: contrato, obrigacao legal)
- Se nao ha base legal: deletar ou anonimizar

**4.3** Verificar se ha referencias em outros documentos:
- Buscar pelo nome, CPF, email ou outros identificadores do titular em TODOS os repositorios
- Tratar cada referencia encontrada conforme os mesmos criterios

**4.4** Registrar todas as acoes realizadas com evidencia.

### Passo 5 — Verificar Logs e Determinar Impacto

- **SLA:** 4 horas a partir da deteccao
- **Responsavel:** Operacoes (Ops) + Compliance Officer

**Acoes:**

**5.1** Consultar logs de retrieval para determinar se PII foi servida:
- Buscar pelo document_id nos logs de queries
- Buscar pelos chunk_ids nos logs de retrieval
- Identificar: quais usuarios receberam chunks com PII, quando (timestamps), quantas vezes, via qual endpoint/agente

**5.2** Consultar logs de resposta da LLM (se disponiveis):
- Verificar se a PII apareceu nas respostas geradas
- Verificar se a validacao de output detectou e bloqueou

**5.3** Classificar o impacto:

**PII NAO FOI SERVIDA (contida a tempo):**
- Incidente contido com sucesso
- Compliance Officer documenta e arquiva
- Nao requer reporte a ANPD (salvo decisao do DPO)

**PII FOI SERVIDA a usuarios autorizados:**
- Impacto moderado
- Compliance avalia necessidade de reporte
- Notificar usuarios que receberam os dados

**PII FOI SERVIDA a usuarios NAO autorizados:**
- INCIDENTE CONFIRMADO
- Compliance Officer lidera procedimento ANPD
- Prazo para comunicacao a ANPD: 2 dias uteis (art. 48 LGPD)
- Comunicacao deve conter: natureza dos dados, titulares afetados, medidas de contencao, riscos, medidas para reverter/mitigar
- Avaliar necessidade de notificar os titulares (art. 48, §1)

**5.4** Registrar conclusao do Passo 5 com:
- Resumo do impacto
- Lista de usuarios que acessaram os dados (se aplicavel)
- Decisao sobre reporte a ANPD
- Proximos passos (pos-incidente)

## Secao 3 — Pos-Incidente (ate 5 dias uteis)

### 3.1 Root Cause Analysis (RCA)

- **Responsavel:** Arquiteto (coordena) + envolvidos no incidente
- **Prazo:** 5 dias uteis apos resolucao

**Conteudo do RCA:**
- Timeline completa (deteccao -> contencao -> resolucao)
- Causa raiz: como a PII entrou na base sem anonimizacao? Exemplos: falha no pipeline de anonimizacao, documento ingerido sem passar pelo pipeline, classificacao incorreta, novo tipo de PII nao reconhecido, erro humano na revisao
- Impacto: quantos titulares, que tipo de dados, por quanto tempo
- Eficacia da resposta: SLAs cumpridos? Gaps no procedimento?
- Acoes corretivas com responsavel e prazo

### 3.2 Acoes preventivas (exemplos)

- Atualizar modelos NER/regex para detectar o tipo de PII que falhou.
- Implementar ou atualizar scanner automatico de PII pre-ingestao.
- Expandir blocklist com padroes identificados no incidente.
- Treinamento para Curadores sobre identificacao de PII.
- Adicionar caso ao golden set de testes.
- Revisar e fortalecer validacao de output da LLM.

### 3.3 Documentacao

- RCA documentado no repositorio knowledge-base (sem PII no RCA).
- Atualizacao deste runbook se gaps forem identificados.
- Atualizacao do pipeline de anonimizacao (ADR-C04) se aplicavel.
- Registro no log de incidentes com retencao de 5 anos (BACEN).

## Secao 4 — Matriz de Escalacao

| Tempo desde deteccao | Se nao resolvido, escalar para |
|---|---|
| 15 minutos | Compliance Officer (se ainda nao notificado) |
| 30 minutos | Arquiteto + Gerente de Engenharia |
| 1 hora | DPO (Data Protection Officer) |
| 2 horas | Diretor de Tecnologia |
| 4 horas | Comite de Crise (se PII servida) |

**Canais de comunicacao (em ordem de prioridade):**
1. Mensagem direta (telefone/chat) para Compliance Officer
2. Canal de incidentes (chat corporativo)
3. Email para lista de distribuicao de incidentes

**REGRA:** nunca incluir a PII real nas comunicacoes de escalacao. Referenciar por document_id e tipo de dado apenas.

## Secao 5 — Checklist Resumido (para impressao/rapido acesso)

- [ ] **PASSO 1 — CONTER (15 min)**
  - [ ] Verificar se dados foram servidos (logs)
  - [ ] Blocklist OU parar API
  - [ ] Notificar Compliance
  - [ ] Registrar no canal de incidentes

- [ ] **PASSO 2 — REMOVER DA BASE VETORIAL (1 hora)**
  - [ ] Identificar todos os chunks
  - [ ] Exportar evidencia forense
  - [ ] Deletar chunks e documento
  - [ ] Verificar remocao (busca por ID e semantica)
  - [ ] Reativar API (se parada)

- [ ] **PASSO 3 — REMOVER DO KNOWLEDGE-BASE REPO (2 horas)**
  - [ ] Deletar ou anonimizar .md
  - [ ] Avaliar limpeza de historico Git
  - [ ] Commit com mensagem "INCIDENTE-PII"

- [ ] **PASSO 4 — VERIFICAR WORKSPACE REPO (3 horas)**
  - [ ] Anonimizar/deletar .beta.md
  - [ ] Verificar fontes brutas (sources/)
  - [ ] Buscar referencias em outros documentos

- [ ] **PASSO 5 — VERIFICAR LOGS E IMPACTO (4 horas)**
  - [ ] Consultar logs de retrieval
  - [ ] Consultar logs de resposta LLM
  - [ ] Classificar impacto
  - [ ] Decidir sobre reporte ANPD (se PII servida: 2 dias uteis)

- [ ] **POS-INCIDENTE (5 dias uteis)**
  - [ ] Root Cause Analysis
  - [ ] Acoes preventivas definidas e atribuidas
  - [ ] Documentacao registrada

## Secao 6 — Requisitos Legais (Referencia)

**LGPD — Lei 13.709/2018:**
- Art. 48: comunicacao a ANPD em prazo razoavel (regulamentacao ANPD define 2 dias uteis) em caso de incidente de seguranca que possa acarretar risco ou dano relevante aos titulares.
- Art. 48, §1: comunicacao deve conter: natureza dos dados pessoais afetados, informacoes sobre titulares envolvidos, medidas tecnicas e de seguranca, riscos relacionados, medidas adotadas para reverter ou mitigar.
- Art. 18, VI: direito a eliminacao dos dados pessoais tratados com consentimento do titular.

**BACEN — Resolucao 4.893/2021:**
- Rastreabilidade e auditoria obrigatorias.
- Retencao de logs: minimo 5 anos.
- Plano de resposta a incidentes documentado e testado.

**CVM — Instrucao 358/2002:**
- Se PII vazada inclui MNPI (informacao nao-publica de mercado), notificar area de Compliance de mercado de capitais adicionalmente.

## Referencias

- ADR-008 — Governanca: Papeis, Ciclo de Vida e Rollback (Pilar 3, Cenario C)
- ADR-004 — Estrategia de Seguranca e Classificacao de Dados (Pilar 6)
- ADR-C04 — Pipeline de Anonimizacao de PII
- LGPD — Lei 13.709/2018 (art. 48, art. 18)
- BACEN Resolucao 4.893/2021
- ANPD — Regulamento de Comunicacao de Incidentes de Seguranca

<!-- conversion_quality: 95 -->
