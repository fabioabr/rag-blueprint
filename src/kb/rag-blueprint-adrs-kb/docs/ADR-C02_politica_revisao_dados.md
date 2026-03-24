---
id: ADR-C02
doc_type: adr
title: "Política de Revisão e Reclassificação de Dados"
system: RAG Corporativo
module: Revisão de Dados
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - política revisão classificação
  - reclassificação dados
  - confidencialidade níveis
  - revisão periódica
  - cadência revisão
  - compliance officer
  - curador conhecimento
  - owner documento
  - herança classificação
  - chunk confidentiality
  - gatilho reclassificação
  - elevação restrição
  - rebaixamento restrição
  - reclassificação urgente
  - incidente classificação
  - lgpd conformidade
  - bacen regulatório
  - cvm instrução
  - mnpi informação
  - auditoria trimestral
  - revisão semestral
  - revisão mensal
  - revisão contínua
  - dados sensíveis
  - classificação public
  - classificação internal
  - classificação restricted
  - classificação confidential
  - front matter confidentiality
  - base vetorial consistência
  - refresh imediato
  - propagação reclassificação
  - sla contenção
  - blocklist documento
  - engenheiro pipeline
  - arquiteto responsabilidade
  - operações monitoramento
  - documento chunk herança
  - métricas reclassificação
  - tempo médio reclassificação
  - auditoria logs acesso
  - regulatório mudança
  - sigilo contratual
  - sistema descontinuado
  - dpa controles cloud
  - aes 256 criptografia
  - rede segregada
  - retenção cinco anos
  - anpd procedimento
  - governança dados
  - ciclo vida documento
aliases:
  - "ADR-C02"
  - "Política Revisão Dados"
  - "Reclassificação de Confidencialidade"
  - "Revisão Periódica Classificação"
  - "Governança Classificação Dados"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-C02_politica_revisao_dados.beta.md"
source_beta_ids:
  - "BETA-C02"
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

# ADR-C02 — Política de Revisão e Reclassificação de Dados

## 1. Objetivo

Estabelecer a política formal de revisão periódica das classificações de confidencialidade dos documentos na base de conhecimento corporativa. Define cadências, responsáveis, gatilhos de reclassificação e procedimentos para garantir que a classificação de dados permaneça precisa ao longo do tempo.

Esta política deriva do Pilar 1 (Classificação de Dados) da [[ADR-004]] e se articula com as cadências de curadoria definidas na [[ADR-008]].

## 2. Níveis de Classificação (Referência)

A base de conhecimento utiliza 4 níveis de confidencialidade, atribuídos no campo `confidentiality` do front matter de cada documento:

### 2.1 Nível 1 — PUBLIC

- **Acesso:** qualquer usuário autenticado, incluindo agentes de IA.
- **Processamento:** cloud sem restrições ou on-premise.
- **Exemplos:** documentação pública de APIs, tutoriais, manuais de ferramentas.

### 2.2 Nível 2 — INTERNAL

- **Acesso:** qualquer colaborador autenticado (Analyst, Manager, Director).
- **Processamento:** cloud com controles (DPA, sem uso para treinamento, logs).
- **Exemplos:** documentação de sistemas internos, ADRs, processos operacionais.

### 2.3 Nível 3 — RESTRICTED

- **Acesso:** Manager (com restrição por domínio), Director.
- **Processamento:** exclusivamente on-premise (BACEN Res. 4.893/2021).
- **Exemplos:** post-mortems, auditorias internas, estratégias de produto.

### 2.4 Nível 4 — CONFIDENTIAL

- **Acesso:** Director (com justificativa em log de auditoria).
- **Processamento:** ambiente isolado on-premise (rede segregada, AES-256).
- **Exemplos:** dados pessoais sensíveis (art. 5 LGPD), investigações internas.

## 3. Cadência de Revisão

A revisão de classificações segue 4 cadências complementares, da mais frequente à mais abrangente:

### 3.1 Revisão Contínua

- **Frequência:** Permanente (evento-driven)
- **Responsável:** Owner de Documento
- **Atividades:**
  - Monitorar se a classificação do documento permanece adequada sempre que houver alteração no conteúdo, contexto regulatório ou organizacional.
  - Verificar se novos dados inseridos no documento alteram o nível de sensibilidade (ex: inclusão de nomes, CPFs, dados financeiros).
  - Reclassificações urgentes devem ser tratadas como INCIDENTE — ver Seção 5 (Gatilhos de Reclassificação).
- **Registro:** Não exige registro formal se não houver mudança. Mudanças devem ser registradas via commit no repositório.

### 3.2 Revisão Mensal

- **Frequência:** 1x por mês (primeira semana útil)
- **Responsável:** Arquiteto + Curador de Conhecimento
- **Atividades:**
  - Revisar classificação de TODOS os documentos ingeridos no mês anterior.
  - Verificar se documentos novos foram classificados corretamente, especialmente aqueles gerados ou enriquecidos por IA.
  - Confirmar que a herança de classificação (Document → Chunk) está consistente na base vetorial.
  - Identificar documentos que mencionam dados de outros níveis de classificação (ex: documento INTERNAL que referencia dados RESTRICTED).
- **Entregável:** Registro da revisão com: data, documentos revisados, reclassificações realizadas (se houver), responsável.

### 3.3 Revisão Trimestral

- **Frequência:** 1x por trimestre
- **Responsável:** Arquiteto + Operações + Compliance Officer
- **Atividades:**
  - Auditoria completa de documentos classificados como RESTRICTED e CONFIDENTIAL — validar se a classificação permanece justificada.
  - Verificar se documentos RESTRICTED podem ser rebaixados para INTERNAL (ex: informação que deixou de ser sensível após divulgação pública).
  - Verificar se documentos INTERNAL deveriam ser elevados para RESTRICTED (ex: mudança regulatória que tornou a informação mais sensível).
  - Revisar logs de acesso a documentos RESTRICTED e CONFIDENTIAL para detectar padrões anômalos.
  - Compliance Officer valida conformidade com LGPD, BACEN e políticas internas.
- **Entregável:** Relatório de auditoria trimestral com: documentos auditados, reclassificações, justificativas, assinatura do Compliance Officer. Retenção mínima de 5 anos.

### 3.4 Revisão Semestral

- **Frequência:** 1x por semestre
- **Responsável:** Todos os papéis (Arquiteto, Curador, Engenheiro, Dev, Ops, Owners, Compliance)
- **Atividades:**
  - Revisão abrangente alinhada com mudanças regulatórias (BACEN, LGPD, CVM).
  - Avaliar se os critérios de classificação precisam ser atualizados (ex: novo tipo de dado que não se encaixa nos 4 níveis atuais).
  - Revisar a política de classificação em si — este documento.
  - Avaliar novas ameaças ou vulnerabilidades que impactem a classificação (ex: novo tipo de ataque que exige elevação de nível).
  - Alinhar com revisão de ADRs e roadmap técnico.
- **Entregável:** Ata da revisão semestral com participantes, decisões, atualizações na política (se houver), próximos passos.

## 4. Responsabilidades por Papel

### 4.1 Owner de Documento

- Responsável primário pela classificação dos seus documentos.
- Deve responder a alertas de reclassificação em até 48 horas úteis.
- Deve justificar a classificação no momento da criação do documento.

### 4.2 Curador de Conhecimento

- Valida classificação durante edição e revisão de `.beta.md`.
- Sinaliza inconsistências ao Owner ou Compliance.

### 4.3 Arquiteto

- Define e mantém os critérios de classificação.
- Participa das revisões mensais e trimestrais.
- Aprova mudanças nos critérios de classificação.

### 4.4 Compliance Officer

- Autoridade final sobre classificação de dados sensíveis.
- Pode VETAR classificação que considere inadequada.
- Lidera auditorias trimestrais de RESTRICTED e CONFIDENTIAL.
- Responsável por garantir conformidade regulatória.

### 4.5 Engenheiro de Pipeline

- Garante que reclassificações sejam refletidas na base vetorial.
- Executa refresh imediato quando reclassificação eleva o nível.
- Monitora consistência entre repositório e base vetorial.

### 4.6 Operações (Ops)

- Monitora acessos e gera alertas de padrões anômalos.
- Participa das revisões trimestrais.

## 5. Gatilhos de Reclassificação

Além das revisões periódicas, os seguintes eventos DEVEM disparar avaliação imediata de reclassificação:

### 5.1 Gatilhos de Elevação (aumentar restrição)

- Inclusão de dados pessoais (PII) em documento INTERNAL ou PUBLIC.
- Mudança regulatória que torna informação mais sensível.
- Incidente de segurança envolvendo o documento ou sistema relacionado.
- Solicitação do Compliance Officer.
- Inclusão de informação não-pública de mercado (MNPI — CVM 358/2002).

### 5.2 Gatilhos de Rebaixamento (reduzir restrição)

- Informação tornada pública oficialmente.
- Expiração de período de sigilo contratual ou regulatório.
- Sistema ou módulo descontinuado (informação perde sensibilidade).
- Decisão documentada do Owner + aprovação do Compliance Officer.

### 5.3 Procedimento de Reclassificação

**Passo 1 — Identificação**
Quem detecta o gatilho notifica o Owner e o Compliance Officer.

**Passo 2 — Avaliação**
Owner avalia e propõe nova classificação. Compliance Officer valida (obrigatório para RESTRICTED e CONFIDENTIAL).

**Passo 3 — Execução**
Owner atualiza campo `confidentiality` no front matter. Commit no repositório com mensagem descritiva.

**Passo 4 — Propagação na Base Vetorial**
- SE elevação (ex: INTERNAL → RESTRICTED): Engenheiro executa refresh IMEDIATO na base vetorial. Chunks devem refletir nova classificação antes da próxima query.
- SE rebaixamento (ex: RESTRICTED → INTERNAL): Pode aguardar próximo ciclo normal de ingestão.

**Passo 5 — Registro**
Registrar: documento, classificação anterior, classificação nova, justificativa, data, responsáveis (Owner + Compliance se aplicável).

## 6. Regra de Herança (Documento → Chunk)

A classificação é sempre herdada do documento para seus chunks, sem exceção:

```
chunk.confidentiality = documento.confidentiality
```

**Regras:**
- NÃO existe override de classificação por chunk individual.
- Se um documento contém partes com níveis diferentes de sensibilidade, a solução correta é DIVIDIR em documentos separados.
- Na base vetorial, cada chunk armazena o campo `confidentiality` herdado do documento pai, mais o `document_id` para rastreabilidade.
- Reclassificação do documento implica reclassificação automática de TODOS os seus chunks.

## 7. Reclassificações Urgentes

Quando a reclassificação envolve ELEVAÇÃO de nível e há risco de exposição de dados sensíveis, o tratamento é de INCIDENTE:

- **SLA de contenção:** 1 hora
- **SLA de remoção:** 4 horas

**Procedimento:**
1. Quem detecta notifica Compliance e Engenheiro imediatamente.
2. Engenheiro adiciona documento à blocklist ou para a API (contenção).
3. Engenheiro atualiza classificação e executa refresh na base vetorial.
4. Ops verifica logs para confirmar se dados foram servidos a usuários não autorizados.
5. Se dados foram servidos → incidente de PII confirmado → procedimento ANPD conforme [[ADR-008]] (Cenário C de Rollback).

Qualquer pessoa pode acionar o procedimento sem aprovação prévia.

## 8. Métricas e Indicadores

Para acompanhar a eficácia desta política, medir:

- Número de reclassificações por período (mensal/trimestral).
- Tempo médio entre detecção de gatilho e efetivação da reclassificação.
- Percentual de documentos RESTRICTED/CONFIDENTIAL auditados no trimestre.
- Número de incidentes de classificação incorreta detectados.
- Percentual de revisões realizadas dentro do prazo.

## 9. Referências

- [[ADR-004]] — Estratégia de Segurança e Classificação de Dados (Pilar 1)
- [[ADR-008]] — Governança: Papéis, Ciclo de Vida e Rollback (Cadência de Curadoria)
- LGPD — Lei 13.709/2018 (art. 5, art. 18)
- BACEN Resolução 4.893/2021
- CVM Instrução 358/2002 (MNPI)

<!-- conversion_quality: 95 -->
