---
id: ADR-C04
doc_type: adr
title: "Runbook: Pipeline de Anonimização de PII"
system: RAG Corporativo
module: Anonimização PII
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - anonimização pii
  - dados pessoais
  - pipeline anonimização
  - detecção pii
  - ner named entity recognition
  - regex detecção
  - heurística contextual
  - classificação pii
  - pii direta
  - pii indireta
  - dado sensível lgpd
  - placeholder substituição
  - consistência placeholders
  - tabela correspondência
  - cofre seguro vault
  - validação anonimização
  - score confiança
  - revisão humana
  - falso positivo
  - falso negativo
  - cpf anonimização
  - cnpj anonimização
  - telefone anonimização
  - email anonimização
  - endereço anonimização
  - conta bancária anonimização
  - nome pessoa anonimização
  - lgpd artigo 5
  - lgpd artigo 14
  - lgpd artigo 18
  - bacen regulatório
  - compliance officer
  - curador conhecimento
  - dpo notificação
  - menores idade proteção
  - dupla validação
  - aes 256 criptografia
  - retenção legal
  - embedding pré processamento
  - base vetorial ingestão
  - incidente pii
  - blocklist documento
  - reprocessamento documento
  - métricas pipeline
  - tempo processamento
  - fila revisão humana
  - front matter preservação
  - markdown estrutura
  - links internos
  - contexto semântico
  - reversão anonimização
  - acesso titular
  - retentativa automática
  - tratamento falhas
aliases:
  - "ADR-C04"
  - "Pipeline Anonimização PII"
  - "Runbook Anonimização Dados Pessoais"
  - "Pipeline de Proteção PII"
  - "Procedimento Anonimização LGPD"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "src/kb/rag-blueprint-adrs-draft/beta/ADR-C04_anonimizacao_pii.beta.md"
source_beta_ids:
  - "BETA-C04"
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

# ADR-C04 — Runbook: Pipeline de Anonimização de PII

## Objetivo

Procedimento operacional detalhado para o pipeline de anonimização de dados pessoais (PII) em documentos antes da geração de embeddings e ingestão na base vetorial. Este pipeline implementa o Pilar 6 (LGPD e Conformidade Regulatória) da [[ADR-004]] e opera como etapa obrigatória do pipeline de ingestão ([[ADR-006]]) para documentos que contenham ou possam conter PII.

**PRINCÍPIO:** dados originais com PII ficam APENAS nas fontes brutas (Fase 1 do pipeline [[ADR-001]]), com controle de acesso separado. A base vetorial recebe somente dados anonimizados.

## Seção 1 — Visão Geral do Pipeline (4 Etapas)

O pipeline de anonimização é composto por 4 etapas sequenciais. Cada documento que pode conter PII deve passar por todas as etapas antes de seguir para a geração de embeddings.

**Fluxo:**

```
[Documento bruto] → DETECÇÃO → CLASSIFICAÇÃO → ANONIMIZAÇÃO → VALIDAÇÃO → [Documento limpo]
```

Tempo estimado por documento: 2-15 segundos (depende do tamanho e quantidade de entidades detectadas).

## Seção 2 — Etapa 1: Detecção

**Objetivo:** identificar todas as ocorrências de dados pessoais no documento.

### 2.1 Métodos de detecção (em paralelo)

**NER (Named Entity Recognition):**
Modelo treinado para detectar entidades em português brasileiro. Tipos de entidade alvo:
- `PERSON` — nomes de pessoas físicas
- `ORG` — organizações (complementar, não é PII mas contextualiza)
- `LOCATION` — endereços e localizações

**Regex (expressões regulares):**
Padrões específicos para dados estruturados brasileiros:
- CPF: `###.###.###-##` e variantes sem pontuação
- CNPJ: `##.###.###/####-##` e variantes
- PHONE: `(##) ####-####` e `(##) #####-####` e variantes
- EMAIL: padrão RFC 5322 simplificado
- ADDRESS: padrões de endereços brasileiros (Rua, Av., CEP)
- BANK_ACCOUNT: padrões de agência/conta bancária

**Heurística contextual:**
Identificar PII por proximidade (ex: "CPF:" seguido de números, "telefone:" seguido de dígitos, campos de formulário).

### 2.2 Score de confiança (confidence)

Cada entidade detectada recebe um score de confiança (0-100%):

- **Score >= 90%: AÇÃO AUTOMÁTICA** — Entidade segue para classificação e anonimização sem intervenção humana.
- **Score 60-89%: REVISÃO HUMANA OBRIGATÓRIA** — Entidade é sinalizada para revisão do Curador ou Compliance Officer. Documento fica em fila de revisão até decisão humana. SLA para revisão: 48 horas úteis.
- **Score < 60%: IGNORAR** — Falso positivo provável. Registrar no log para análise posterior. Se a mesma entidade for ignorada repetidamente, avaliar ajuste nos modelos de detecção.

### 2.3 Registro de detecção

Para cada entidade detectada, registrar:
- document_id
- posição no texto (offset início, offset fim)
- texto original (armazenado em cofre seguro, não no log aberto)
- tipo de entidade (PERSON, CPF, etc.)
- método de detecção (NER, regex, heurística)
- score de confiança
- decisão (automática, revisão humana, ignorada)

## Seção 3 — Etapa 2: Classificação

**Objetivo:** categorizar cada entidade detectada para definir a ação apropriada.

### 3.1 Categorias de PII

**PII DIRETA** — identificação inequívoca de pessoa
- Exemplos: CPF, RG, nome completo + documento, biometria
- Ação padrão: SEMPRE anonimizar, sem exceção.

**PII INDIRETA** — identificação possível por combinação
- Exemplos: nome + departamento, cargo + equipe, email corporativo
- Ação padrão: avaliar combinações. Nome isolado em contexto técnico pode ser aceitável (ex: "owner: fabio" no front matter); nome + departamento + cargo = potencialmente identificável = anonimizar.

**DADO SENSÍVEL (art. 5, II, LGPD)** — categorias especiais
- Exemplos: origem racial, opinião política, dado de saúde, dado biométrico, dado genético, vida sexual, convicção religiosa
- Ação padrão: SEMPRE anonimizar. Compliance Officer notificado.

### 3.2 Regras de classificação

- **Regra 1:** Na dúvida entre PII direta e indireta, tratar como DIRETA.
- **Regra 2:** Dados sensíveis (art. 5 LGPD) são sempre tratados com o nível mais restritivo, independente do score.
- **Regra 3:** PII em documentos CONFIDENTIAL recebe dupla validação (automática + humana, sem exceção).
- **Regra 4:** PII de menores de idade (art. 14 LGPD) exige notificação imediata ao DPO.

## Seção 4 — Etapa 3: Anonimização

**Objetivo:** substituir PII detectada e classificada por placeholders consistentes, preservando a utilidade semântica do documento.

### 4.1 Método: substituição por placeholder

Cada tipo de PII é substituído por um placeholder padronizado:

| Tipo original | Placeholder | Exemplo |
|---|---|---|
| Nome de pessoa | `[NOME_ANONIMIZADO_NNN]` | João Silva → `[NOME_ANONIMIZADO_001]` |
| CPF | `[CPF_ANONIMIZADO]` | 123.456.789-00 → `[CPF_ANONIMIZADO]` |
| CNPJ | `[CNPJ_ANONIMIZADO]` | 12.345.678/0001-90 → `[CNPJ_ANONIMIZADO]` |
| Telefone | `[TELEFONE_ANONIMIZADO]` | (11) 99999-0000 → `[TELEFONE_ANONIMIZADO]` |
| Email pessoal | `[EMAIL_ANONIMIZADO]` | joao@email.com → `[EMAIL_ANONIMIZADO]` |
| Endereço | `[ENDERECO_ANONIMIZADO]` | Rua X, 123 → `[ENDERECO_ANONIMIZADO]` |
| Conta bancária | `[CONTA_ANONIMIZADA]` | Ag 0001 / CC 12345-6 → `[CONTA_ANONIMIZADA]` |
| Dado sensível | `[DADO_SENSIVEL_ANONIMIZADO]` | (conforme tipo) |

### 4.2 Consistência de placeholders

- A MESMA pessoa deve receber o MESMO placeholder em todo o documento. Ex: "João Silva" aparece 5 vezes → todas viram `[NOME_ANONIMIZADO_001]`.
- Pessoas DIFERENTES recebem placeholders DIFERENTES. Ex: "João Silva" = `[NOME_ANONIMIZADO_001]`, "Maria Santos" = `[NOME_ANONIMIZADO_002]`.
- Isso preserva relações semânticas ("X aprovou o documento de Y") sem revelar identidades.

### 4.3 Tabela de correspondência

Uma tabela de correspondência (mapping table) é mantida para permitir reversão em caso de necessidade legal (ex: direito de acesso do titular):

| Placeholder | Valor original | Documento | Data |
|---|---|---|---|
| `[NOME_ANONIMIZADO_001]` | João Silva | DOC-000456 | 2026-03-23 |
| `[CPF_ANONIMIZADO]` | 123.456.789-00 | DOC-000456 | 2026-03-23 |

**Armazenamento da tabela:**
- Em cofre seguro (vault), NUNCA no mesmo repositório dos documentos.
- Acesso restrito: apenas DPO e Compliance Officer.
- Criptografia AES-256 em repouso.
- Retenção conforme exigência legal (LGPD + BACEN = até 5 anos).
- Log de acesso à tabela com justificativa obrigatória.

### 4.4 Preservação de contexto

A anonimização deve preservar a utilidade do documento para o RAG:
- Estrutura de frases mantida (não remover frases inteiras).
- Placeholders são termos válidos para a LLM processar.
- Metadados do front matter: campo "owner" pode manter alias ou código (ex: "owner: USR-001") em vez de nome completo.
- Não anonimizar nomes de sistemas, módulos ou processos (não são PII).

## Seção 5 — Etapa 4: Validação

**Objetivo:** confirmar que a anonimização foi completa e consistente antes de liberar o documento para geração de embeddings.

### 5.1 Verificações automáticas

- [ ] Nenhuma PII remanescente detectada (re-executar detecção no documento anonimizado — se detectar novas entidades, voltar à Etapa 1).
- [ ] Consistência de placeholders verificada:
  - Mesmo placeholder para mesma entidade em todo o documento.
  - Nenhum placeholder órfão (sem correspondência na tabela).
  - Nenhuma entidade original sobrevivente.
- [ ] Documento anonimizado é sintaticamente válido:
  - Front matter intacto (YAML válido).
  - Estrutura Markdown preservada.
  - Links internos funcionais.
- [ ] Tabela de correspondência registrada no cofre seguro.

### 5.2 Verificação humana (quando aplicável)

Obrigatória quando:
- Documento é classificado como RESTRICTED ou CONFIDENTIAL.
- Etapa 1 sinalizou entidades com score entre 60-89%.
- Documento contém dado sensível (art. 5 LGPD).
- Primeira ingestão de novo tipo de documento (sem precedente).

**Responsável:** Curador + Compliance Officer (para RESTRICTED/CONFIDENTIAL).
**SLA:** 48 horas úteis.

### 5.3 Registro de validação

Para cada documento processado, registrar:
- document_id
- timestamp de início e fim do pipeline
- total de entidades detectadas (por tipo)
- total de entidades anonimizadas
- total de entidades ignoradas (com justificativa)
- total de entidades em revisão humana
- resultado da validação (aprovado / reprovado / pendente revisão)
- responsável pela validação humana (se aplicável)

## Seção 6 — Tratamento de Falhas

### 6.1 Falha na detecção (NER/regex indisponível)

- Documento NÃO prossegue para embeddings.
- Registrar falha com erro e document_id.
- Retentativa automática em 15 minutos (até 3 tentativas).
- Após 3 falhas: alertar Engenheiro de Pipeline.

### 6.2 Falha na anonimização (placeholder inconsistente)

- Documento volta para Etapa 1 (reprocessamento completo).
- Se falhar novamente: encaminhar para revisão humana manual.

### 6.3 PII detectada após ingestão na base vetorial

- INCIDENTE — acionar procedimento [[ADR-C05]] (Incidente de PII).
- Contenção imediata: adicionar documento à blocklist.
- Remover chunks da base vetorial.
- Reprocessar documento pelo pipeline de anonimização.
- Re-ingerir após validação.

## Seção 7 — Métricas do Pipeline

Acompanhar mensalmente:
- Total de documentos processados pelo pipeline de anonimização.
- Total de entidades detectadas, anonimizadas e ignoradas.
- Taxa de falso positivo (entidades detectadas que não eram PII).
- Taxa de falso negativo (PII não detectada — medida por amostragem).
- Tempo médio de processamento por documento.
- Documentos em fila de revisão humana e tempo médio de espera.
- Incidentes de PII pós-ingestão (meta: zero).

## Referências

- [[ADR-004]] — Estratégia de Segurança e Classificação de Dados (Pilar 6)
- [[ADR-006]] — Pipeline de Ingestão: Fonte até Base Vetorial
- [[ADR-008]] — Governança: Papéis, Ciclo de Vida e Rollback
- LGPD — Lei 13.709/2018 (art. 5, art. 14, art. 18)
- BACEN Resolução 4.893/2021

<!-- conversion_quality: 95 -->
