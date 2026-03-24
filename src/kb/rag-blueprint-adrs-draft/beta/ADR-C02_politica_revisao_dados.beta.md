---
id: BETA-C02
title: "Politica de Revisao e Reclassificacao de Dados"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-C02_politica_revisao_dados.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags:
  - politica revisao classificacao
  - reclassificacao dados
  - confidencialidade niveis
  - revisao periodica
  - cadencia revisao
  - compliance officer
  - curador conhecimento
  - owner documento
  - heranca classificacao
  - chunk confidentiality
  - gatilho reclassificacao
  - elevacao restricao
  - rebaixamento restricao
  - reclassificacao urgente
  - incidente classificacao
  - lgpd conformidade
  - bacen regulatorio
  - cvm instrucao
  - mnpi informacao
  - auditoria trimestral
  - revisao semestral
  - revisao mensal
  - revisao continua
  - dados sensiveis
  - classificacao public
  - classificacao internal
  - classificacao restricted
  - classificacao confidential
  - front matter confidentiality
  - base vetorial consistencia
  - refresh imediato
  - propagacao reclassificacao
  - sla contencao
  - blocklist documento
  - engenheiro pipeline
  - arquiteto responsabilidade
  - operacoes monitoramento
  - documento chunk heranca
  - metricas reclassificacao
  - tempo medio reclassificacao
  - auditoria logs acesso
  - regulatorio mudanca
  - sigilo contratual
  - sistema descontinuado
  - dpa controles cloud
  - aes 256 criptografia
  - rede segregada
  - retencao cinco anos
  - anpd procedimento
  - governanca dados
  - ciclo vida documento
aliases:
  - "ADR-C02"
  - "Politica Revisao Dados"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## Objetivo

Estabelecer a politica formal de revisao periodica das classificacoes de confidencialidade dos documentos na base de conhecimento corporativa. Define cadencias, responsaveis, gatilhos de reclassificacao e procedimentos para garantir que a classificacao de dados permaneca precisa ao longo do tempo.

Esta politica deriva do Pilar 1 (Classificacao de Dados) da ADR-004 e se articula com as cadencias de curadoria definidas na ADR-008.

## Secao 1 — Niveis de Classificacao (Referencia)

A base de conhecimento utiliza 4 niveis de confidencialidade, atribuidos no campo `confidentiality` do front matter de cada documento:

**Nivel 1 — PUBLIC**
- Acesso: qualquer usuario autenticado, incluindo agentes de IA.
- Processamento: cloud sem restricoes ou on-premise.
- Exemplos: documentacao publica de APIs, tutoriais, manuais de ferramentas.

**Nivel 2 — INTERNAL**
- Acesso: qualquer colaborador autenticado (Analyst, Manager, Director).
- Processamento: cloud com controles (DPA, sem uso para treinamento, logs).
- Exemplos: documentacao de sistemas internos, ADRs, processos operacionais.

**Nivel 3 — RESTRICTED**
- Acesso: Manager (com restricao por dominio), Director.
- Processamento: exclusivamente on-premise (BACEN Res. 4.893/2021).
- Exemplos: post-mortems, auditorias internas, estrategias de produto.

**Nivel 4 — CONFIDENTIAL**
- Acesso: Director (com justificativa em log de auditoria).
- Processamento: ambiente isolado on-premise (rede segregada, AES-256).
- Exemplos: dados pessoais sensiveis (art. 5 LGPD), investigacoes internas.

## Secao 2 — Cadencia de Revisao

A revisao de classificacoes segue 4 cadencias complementares, da mais frequente a mais abrangente:

### 2.1 Revisao Continua

- **Frequencia:** Permanente (evento-driven)
- **Responsavel:** Owner de Documento
- **Atividades:**
  - Monitorar se a classificacao do documento permanece adequada sempre que houver alteracao no conteudo, contexto regulatorio ou organizacional.
  - Verificar se novos dados inseridos no documento alteram o nivel de sensibilidade (ex: inclusao de nomes, CPFs, dados financeiros).
  - Reclassificacoes urgentes devem ser tratadas como INCIDENTE — ver Secao 4 (Gatilhos de Reclassificacao).
- **Registro:** Nao exige registro formal se nao houver mudanca. Mudancas devem ser registradas via commit no repositorio.

### 2.2 Revisao Mensal

- **Frequencia:** 1x por mes (primeira semana util)
- **Responsavel:** Arquiteto + Curador de Conhecimento
- **Atividades:**
  - Revisar classificacao de TODOS os documentos ingeridos no mes anterior.
  - Verificar se documentos novos foram classificados corretamente, especialmente aqueles gerados ou enriquecidos por IA.
  - Confirmar que a heranca de classificacao (Document -> Chunk) esta consistente na base vetorial.
  - Identificar documentos que mencionam dados de outros niveis de classificacao (ex: documento INTERNAL que referencia dados RESTRICTED).
- **Entregavel:** Registro da revisao com: data, documentos revisados, reclassificacoes realizadas (se houver), responsavel.

### 2.3 Revisao Trimestral

- **Frequencia:** 1x por trimestre
- **Responsavel:** Arquiteto + Operacoes + Compliance Officer
- **Atividades:**
  - Auditoria completa de documentos classificados como RESTRICTED e CONFIDENTIAL — validar se a classificacao permanece justificada.
  - Verificar se documentos RESTRICTED podem ser rebaixados para INTERNAL (ex: informacao que deixou de ser sensivel apos divulgacao publica).
  - Verificar se documentos INTERNAL deveriam ser elevados para RESTRICTED (ex: mudanca regulatoria que tornou a informacao mais sensivel).
  - Revisar logs de acesso a documentos RESTRICTED e CONFIDENTIAL para detectar padroes anomalos.
  - Compliance Officer valida conformidade com LGPD, BACEN e politicas internas.
- **Entregavel:** Relatorio de auditoria trimestral com: documentos auditados, reclassificacoes, justificativas, assinatura do Compliance Officer. Retencao minima de 5 anos.

### 2.4 Revisao Semestral

- **Frequencia:** 1x por semestre
- **Responsavel:** Todos os papeis (Arquiteto, Curador, Engenheiro, Dev, Ops, Owners, Compliance)
- **Atividades:**
  - Revisao abrangente alinhada com mudancas regulatorias (BACEN, LGPD, CVM).
  - Avaliar se os criterios de classificacao precisam ser atualizados (ex: novo tipo de dado que nao se encaixa nos 4 niveis atuais).
  - Revisar a politica de classificacao em si — este documento.
  - Avaliar novas ameacas ou vulnerabilidades que impactem a classificacao (ex: novo tipo de ataque que exige elevacao de nivel).
  - Alinhar com revisao de ADRs e roadmap tecnico.
- **Entregavel:** Ata da revisao semestral com participantes, decisoes, atualizacoes na politica (se houver), proximos passos.

## Secao 3 — Responsabilidades por Papel

**Owner de Documento**
- Responsavel primario pela classificacao dos seus documentos.
- Deve responder a alertas de reclassificacao em ate 48 horas uteis.
- Deve justificar a classificacao no momento da criacao do documento.

**Curador de Conhecimento**
- Valida classificacao durante edicao e revisao de `.beta.md`.
- Sinaliza inconsistencias ao Owner ou Compliance.

**Arquiteto**
- Define e mantem os criterios de classificacao.
- Participa das revisoes mensais e trimestrais.
- Aprova mudancas nos criterios de classificacao.

**Compliance Officer**
- Autoridade final sobre classificacao de dados sensiveis.
- Pode VETAR classificacao que considere inadequada.
- Lidera auditorias trimestrais de RESTRICTED e CONFIDENTIAL.
- Responsavel por garantir conformidade regulatoria.

**Engenheiro de Pipeline**
- Garante que reclassificacoes sejam refletidas na base vetorial.
- Executa refresh imediato quando reclassificacao eleva o nivel.
- Monitora consistencia entre repositorio e base vetorial.

**Operacoes (Ops)**
- Monitora acessos e gera alertas de padroes anomalos.
- Participa das revisoes trimestrais.

## Secao 4 — Gatilhos de Reclassificacao

Alem das revisoes periodicas, os seguintes eventos DEVEM disparar avaliacao imediata de reclassificacao:

### 4.1 Gatilhos de Elevacao (aumentar restricao)

- Inclusao de dados pessoais (PII) em documento INTERNAL ou PUBLIC.
- Mudanca regulatoria que torna informacao mais sensivel.
- Incidente de seguranca envolvendo o documento ou sistema relacionado.
- Solicitacao do Compliance Officer.
- Inclusao de informacao nao-publica de mercado (MNPI — CVM 358/2002).

### 4.2 Gatilhos de Rebaixamento (reduzir restricao)

- Informacao tornada publica oficialmente.
- Expiracao de periodo de sigilo contratual ou regulatorio.
- Sistema ou modulo descontinuado (informacao perde sensibilidade).
- Decisao documentada do Owner + aprovacao do Compliance Officer.

### 4.3 Procedimento de Reclassificacao

**Passo 1 — Identificacao**
Quem detecta o gatilho notifica o Owner e o Compliance Officer.

**Passo 2 — Avaliacao**
Owner avalia e propoe nova classificacao. Compliance Officer valida (obrigatorio para RESTRICTED e CONFIDENTIAL).

**Passo 3 — Execucao**
Owner atualiza campo `confidentiality` no front matter. Commit no repositorio com mensagem descritiva.

**Passo 4 — Propagacao na Base Vetorial**
- SE elevacao (ex: INTERNAL -> RESTRICTED): Engenheiro executa refresh IMEDIATO na base vetorial. Chunks devem refletir nova classificacao antes da proxima query.
- SE rebaixamento (ex: RESTRICTED -> INTERNAL): Pode aguardar proximo ciclo normal de ingestao.

**Passo 5 — Registro**
Registrar: documento, classificacao anterior, classificacao nova, justificativa, data, responsaveis (Owner + Compliance se aplicavel).

## Secao 5 — Regra de Heranca (Documento -> Chunk)

A classificacao e sempre herdada do documento para seus chunks, sem excecao:

```
chunk.confidentiality = documento.confidentiality
```

**Regras:**
- NAO existe override de classificacao por chunk individual.
- Se um documento contem partes com niveis diferentes de sensibilidade, a solucao correta e DIVIDIR em documentos separados.
- Na base vetorial, cada chunk armazena o campo `confidentiality` herdado do documento pai, mais o `document_id` para rastreabilidade.
- Reclassificacao do documento implica reclassificacao automatica de TODOS os seus chunks.

## Secao 6 — Reclassificacoes Urgentes

Quando a reclassificacao envolve ELEVACAO de nivel e ha risco de exposicao de dados sensiveis, o tratamento e de INCIDENTE:

- **SLA de contencao:** 1 hora
- **SLA de remocao:** 4 horas

**Procedimento:**
1. Quem detecta notifica Compliance e Engenheiro imediatamente.
2. Engenheiro adiciona documento a blocklist ou para a API (contencao).
3. Engenheiro atualiza classificacao e executa refresh na base vetorial.
4. Ops verifica logs para confirmar se dados foram servidos a usuarios nao autorizados.
5. Se dados foram servidos -> incidente de PII confirmado -> procedimento ANPD conforme ADR-008 (Cenario C de Rollback).

Qualquer pessoa pode acionar o procedimento sem aprovacao previa.

## Secao 7 — Metricas e Indicadores

Para acompanhar a eficacia desta politica, medir:

- Numero de reclassificacoes por periodo (mensal/trimestral).
- Tempo medio entre deteccao de gatilho e efetivacao da reclassificacao.
- Percentual de documentos RESTRICTED/CONFIDENTIAL auditados no trimestre.
- Numero de incidentes de classificacao incorreta detectados.
- Percentual de revisoes realizadas dentro do prazo.

## Referencias

- ADR-004 — Estrategia de Seguranca e Classificacao de Dados (Pilar 1)
- ADR-008 — Governanca: Papeis, Ciclo de Vida e Rollback (Cadencia de Curadoria)
- LGPD — Lei 13.709/2018 (art. 5, art. 18)
- BACEN Resolucao 4.893/2021
- CVM Instrucao 358/2002 (MNPI)

<!-- conversion_quality: 95 -->
