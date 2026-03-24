---
id: BETA-C04
title: "Runbook: Pipeline de Anonimizacao de PII"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-C04_anonimizacao_pii.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
tags:
  - anonimizacao pii
  - dados pessoais
  - pipeline anonimizacao
  - deteccao pii
  - ner named entity recognition
  - regex deteccao
  - heuristica contextual
  - classificacao pii
  - pii direta
  - pii indireta
  - dado sensivel lgpd
  - placeholder substituicao
  - consistencia placeholders
  - tabela correspondencia
  - cofre seguro vault
  - validacao anonimizacao
  - score confianca
  - revisao humana
  - falso positivo
  - falso negativo
  - cpf anonimizacao
  - cnpj anonimizacao
  - telefone anonimizacao
  - email anonimizacao
  - endereco anonimizacao
  - conta bancaria anonimizacao
  - nome pessoa anonimizacao
  - lgpd artigo 5
  - lgpd artigo 14
  - lgpd artigo 18
  - bacen regulatorio
  - compliance officer
  - curador conhecimento
  - dpo notificacao
  - menores idade protecao
  - dupla validacao
  - aes 256 criptografia
  - retencao legal
  - embedding pre-processamento
  - base vetorial ingestao
  - incidente pii
  - blocklist documento
  - reprocessamento documento
  - metricas pipeline
  - tempo processamento
  - fila revisao humana
  - front matter preservacao
  - markdown estrutura
  - links internos
  - contexto semantico
  - reversao anonimizacao
  - acesso titular
  - retentativa automatica
  - tratamento falhas
aliases:
  - "ADR-C04"
  - "Pipeline Anonimizacao PII"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## Objetivo

Procedimento operacional detalhado para o pipeline de anonimizacao de dados pessoais (PII) em documentos antes da geracao de embeddings e ingestao na base vetorial. Este pipeline implementa o Pilar 6 (LGPD e Conformidade Regulatoria) da ADR-004 e opera como etapa obrigatoria do pipeline de ingestao (ADR-006) para documentos que contenham ou possam conter PII.

**PRINCIPIO:** dados originais com PII ficam APENAS nas fontes brutas (Fase 1 do pipeline ADR-001), com controle de acesso separado. A base vetorial recebe somente dados anonimizados.

## Secao 1 — Visao Geral do Pipeline (4 Etapas)

O pipeline de anonimizacao e composto por 4 etapas sequenciais. Cada documento que pode conter PII deve passar por todas as etapas antes de seguir para a geracao de embeddings.

**Fluxo:**

```
[Documento bruto] -> DETECCAO -> CLASSIFICACAO -> ANONIMIZACAO -> VALIDACAO -> [Documento limpo]
```

Tempo estimado por documento: 2-15 segundos (depende do tamanho e quantidade de entidades detectadas).

## Secao 2 — Etapa 1: Deteccao

**Objetivo:** identificar todas as ocorrencias de dados pessoais no documento.

### 2.1 Metodos de deteccao (em paralelo)

**NER (Named Entity Recognition):**
Modelo treinado para detectar entidades em portugues brasileiro. Tipos de entidade alvo:
- `PERSON` — nomes de pessoas fisicas
- `ORG` — organizacoes (complementar, nao e PII mas contextualiza)
- `LOCATION` — enderecos e localizacoes

**Regex (expressoes regulares):**
Padroes especificos para dados estruturados brasileiros:
- CPF: `###.###.###-##` e variantes sem pontuacao
- CNPJ: `##.###.###/####-##` e variantes
- PHONE: `(##) ####-####` e `(##) #####-####` e variantes
- EMAIL: padrao RFC 5322 simplificado
- ADDRESS: padroes de enderecos brasileiros (Rua, Av., CEP)
- BANK_ACCOUNT: padroes de agencia/conta bancaria

**Heuristica contextual:**
Identificar PII por proximidade (ex: "CPF:" seguido de numeros, "telefone:" seguido de digitos, campos de formulario).

### 2.2 Score de confianca (confidence)

Cada entidade detectada recebe um score de confianca (0-100%):

- **Score >= 90%: ACAO AUTOMATICA** — Entidade segue para classificacao e anonimizacao sem intervencao humana.
- **Score 60-89%: REVISAO HUMANA OBRIGATORIA** — Entidade e sinalizada para revisao do Curador ou Compliance Officer. Documento fica em fila de revisao ate decisao humana. SLA para revisao: 48 horas uteis.
- **Score < 60%: IGNORAR** — Falso positivo provavel. Registrar no log para analise posterior. Se a mesma entidade for ignorada repetidamente, avaliar ajuste nos modelos de deteccao.

### 2.3 Registro de deteccao

Para cada entidade detectada, registrar:
- document_id
- posicao no texto (offset inicio, offset fim)
- texto original (armazenado em cofre seguro, nao no log aberto)
- tipo de entidade (PERSON, CPF, etc.)
- metodo de deteccao (NER, regex, heuristica)
- score de confianca
- decisao (automatica, revisao humana, ignorada)

## Secao 3 — Etapa 2: Classificacao

**Objetivo:** categorizar cada entidade detectada para definir a acao apropriada.

### 3.1 Categorias de PII

**PII DIRETA** — identificacao inequivoca de pessoa
- Exemplos: CPF, RG, nome completo + documento, biometria
- Acao padrao: SEMPRE anonimizar, sem excecao.

**PII INDIRETA** — identificacao possivel por combinacao
- Exemplos: nome + departamento, cargo + equipe, email corporativo
- Acao padrao: avaliar combinacoes. Nome isolado em contexto tecnico pode ser aceitavel (ex: "owner: fabio" no front matter); nome + departamento + cargo = potencialmente identificavel = anonimizar.

**DADO SENSIVEL (art. 5, II, LGPD)** — categorias especiais
- Exemplos: origem racial, opiniao politica, dado de saude, dado biometrico, dado genetico, vida sexual, conviccao religiosa
- Acao padrao: SEMPRE anonimizar. Compliance Officer notificado.

### 3.2 Regras de classificacao

- **Regra 1:** Na duvida entre PII direta e indireta, tratar como DIRETA.
- **Regra 2:** Dados sensiveis (art. 5 LGPD) sao sempre tratados com o nivel mais restritivo, independente do score.
- **Regra 3:** PII em documentos CONFIDENTIAL recebe dupla validacao (automatica + humana, sem excecao).
- **Regra 4:** PII de menores de idade (art. 14 LGPD) exige notificacao imediata ao DPO.

## Secao 4 — Etapa 3: Anonimizacao

**Objetivo:** substituir PII detectada e classificada por placeholders consistentes, preservando a utilidade semantica do documento.

### 4.1 Metodo: substituicao por placeholder

Cada tipo de PII e substituido por um placeholder padronizado:

| Tipo original | Placeholder | Exemplo |
|---|---|---|
| Nome de pessoa | `[NOME_ANONIMIZADO_NNN]` | Joao Silva -> `[NOME_ANONIMIZADO_001]` |
| CPF | `[CPF_ANONIMIZADO]` | 123.456.789-00 -> `[CPF_ANONIMIZADO]` |
| CNPJ | `[CNPJ_ANONIMIZADO]` | 12.345.678/0001-90 -> `[CNPJ_ANONIMIZADO]` |
| Telefone | `[TELEFONE_ANONIMIZADO]` | (11) 99999-0000 -> `[TELEFONE_ANONIMIZADO]` |
| Email pessoal | `[EMAIL_ANONIMIZADO]` | joao@email.com -> `[EMAIL_ANONIMIZADO]` |
| Endereco | `[ENDERECO_ANONIMIZADO]` | Rua X, 123 -> `[ENDERECO_ANONIMIZADO]` |
| Conta bancaria | `[CONTA_ANONIMIZADA]` | Ag 0001 / CC 12345-6 -> `[CONTA_ANONIMIZADA]` |
| Dado sensivel | `[DADO_SENSIVEL_ANONIMIZADO]` | (conforme tipo) |

### 4.2 Consistencia de placeholders

- A MESMA pessoa deve receber o MESMO placeholder em todo o documento. Ex: "Joao Silva" aparece 5 vezes -> todas viram `[NOME_ANONIMIZADO_001]`.
- Pessoas DIFERENTES recebem placeholders DIFERENTES. Ex: "Joao Silva" = `[NOME_ANONIMIZADO_001]`, "Maria Santos" = `[NOME_ANONIMIZADO_002]`.
- Isso preserva relacoes semanticas ("X aprovou o documento de Y") sem revelar identidades.

### 4.3 Tabela de correspondencia

Uma tabela de correspondencia (mapping table) e mantida para permitir reversao em caso de necessidade legal (ex: direito de acesso do titular):

| Placeholder | Valor original | Documento | Data |
|---|---|---|---|
| `[NOME_ANONIMIZADO_001]` | Joao Silva | DOC-000456 | 2026-03-23 |
| `[CPF_ANONIMIZADO]` | 123.456.789-00 | DOC-000456 | 2026-03-23 |

**Armazenamento da tabela:**
- Em cofre seguro (vault), NUNCA no mesmo repositorio dos documentos.
- Acesso restrito: apenas DPO e Compliance Officer.
- Criptografia AES-256 em repouso.
- Retencao conforme exigencia legal (LGPD + BACEN = ate 5 anos).
- Log de acesso a tabela com justificativa obrigatoria.

### 4.4 Preservacao de contexto

A anonimizacao deve preservar a utilidade do documento para o RAG:
- Estrutura de frases mantida (nao remover frases inteiras).
- Placeholders sao termos validos para a LLM processar.
- Metadados do front matter: campo "owner" pode manter alias ou codigo (ex: "owner: USR-001") em vez de nome completo.
- Nao anonimizar nomes de sistemas, modulos ou processos (nao sao PII).

## Secao 5 — Etapa 4: Validacao

**Objetivo:** confirmar que a anonimizacao foi completa e consistente antes de liberar o documento para geracao de embeddings.

### 5.1 Verificacoes automaticas

- [ ] Nenhuma PII remanescente detectada (re-executar deteccao no documento anonimizado — se detectar novas entidades, voltar a Etapa 1).
- [ ] Consistencia de placeholders verificada:
  - Mesmo placeholder para mesma entidade em todo o documento.
  - Nenhum placeholder orfao (sem correspondencia na tabela).
  - Nenhuma entidade original sobrevivente.
- [ ] Documento anonimizado e sintaticamente valido:
  - Front matter intacto (YAML valido).
  - Estrutura Markdown preservada.
  - Links internos funcionais.
- [ ] Tabela de correspondencia registrada no cofre seguro.

### 5.2 Verificacao humana (quando aplicavel)

Obrigatoria quando:
- Documento e classificado como RESTRICTED ou CONFIDENTIAL.
- Etapa 1 sinalizou entidades com score entre 60-89%.
- Documento contem dado sensivel (art. 5 LGPD).
- Primeira ingestao de novo tipo de documento (sem precedente).

**Responsavel:** Curador + Compliance Officer (para RESTRICTED/CONFIDENTIAL).
**SLA:** 48 horas uteis.

### 5.3 Registro de validacao

Para cada documento processado, registrar:
- document_id
- timestamp de inicio e fim do pipeline
- total de entidades detectadas (por tipo)
- total de entidades anonimizadas
- total de entidades ignoradas (com justificativa)
- total de entidades em revisao humana
- resultado da validacao (aprovado / reprovado / pendente revisao)
- responsavel pela validacao humana (se aplicavel)

## Secao 6 — Tratamento de Falhas

### 6.1 Falha na deteccao (NER/regex indisponivel)

- Documento NAO prossegue para embeddings.
- Registrar falha com erro e document_id.
- Retentativa automatica em 15 minutos (ate 3 tentativas).
- Apos 3 falhas: alertar Engenheiro de Pipeline.

### 6.2 Falha na anonimizacao (placeholder inconsistente)

- Documento volta para Etapa 1 (reprocessamento completo).
- Se falhar novamente: encaminhar para revisao humana manual.

### 6.3 PII detectada apos ingestao na base vetorial

- INCIDENTE — acionar procedimento ADR-C05 (Incidente de PII).
- Contencao imediata: adicionar documento a blocklist.
- Remover chunks da base vetorial.
- Reprocessar documento pelo pipeline de anonimizacao.
- Re-ingerir apos validacao.

## Secao 7 — Metricas do Pipeline

Acompanhar mensalmente:
- Total de documentos processados pelo pipeline de anonimizacao.
- Total de entidades detectadas, anonimizadas e ignoradas.
- Taxa de falso positivo (entidades detectadas que nao eram PII).
- Taxa de falso negativo (PII nao detectada — medida por amostragem).
- Tempo medio de processamento por documento.
- Documentos em fila de revisao humana e tempo medio de espera.
- Incidentes de PII pos-ingestao (meta: zero).

## Referencias

- ADR-004 — Estrategia de Seguranca e Classificacao de Dados (Pilar 6)
- ADR-006 — Pipeline de Ingestao: Fonte ate Base Vetorial
- ADR-008 — Governanca: Papeis, Ciclo de Vida e Rollback
- LGPD — Lei 13.709/2018 (art. 5, art. 14, art. 18)
- BACEN Resolucao 4.893/2021

<!-- conversion_quality: 95 -->
