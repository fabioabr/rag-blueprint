---
id: ADR-E04
doc_type: adr
title: "Garantias de Idempotência do Pipeline de Ingestão"
system: RAG Corporativo
module: Idempotência
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - idempotencia
  - pipeline de ingestao
  - hash sha 256
  - upsert
  - merge cypher
  - create if not exists
  - base vetorial
  - classificacao unchanged
  - zero alteracoes
  - funcao deterministica
  - webhooks duplicados
  - cron overlap
  - retries seguros
  - testabilidade
  - reprodutibilidade
  - rollback previsivel
  - debugging simplificado
  - seguranca de retry
  - etapa 1 descoberta
  - etapa 5 persistencia
  - etapa 6 indexacao
  - file hash
  - no document
  - indice vetorial
  - full text index
  - constraint
  - duplicacao de chunks
  - corrupcao de relacoes
  - github webhook
  - gitlab webhook
  - timeout de resposta
  - retry automatico
  - lock exclusivo
  - snapshot da base vetorial
  - ci cd
  - teste automatizado
  - diff de estado
  - propriedades derivadas
  - mesma entrada mesma saida
  - estado estavel
  - comparacao de hash
  - nos auxiliares
  - system module owner team
  - no op
  - reprocessamento
  - classificacao new
  - classificacao deleted
  - release anterior
  - confiabilidade do sistema
  - garantia de idempotencia
  - funcao idempotente
  - re execucao segura
aliases:
  - "ADR-E04"
  - "Idempotência do Pipeline"
  - "Garantias de Idempotência"
  - "Pipeline Idempotente"
  - "Idempotência da Ingestão"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/draft/ADR-E04_garantias_idempotencia.txt"
source_beta_ids:
  - "BETA-E04"
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

# ADR-E04 — Garantias de Idempotência do Pipeline de Ingestão

| Campo | Valor |
|-------|-------|
| **Status** | Accepted |
| **Data da Decisão** | 2026-03-23 |
| **Decisor** | fabio |
| **Escopo** | Idempotência |

**Referências Cruzadas:**

- **Depende de:** [[ADR-006]]
- **Relaciona-se:** [[ADR-E03]], [[ADR-E01]]

## Sumário

Este documento detalha como o pipeline de ingestão garante idempotência em cada uma de suas etapas, e por que essa propriedade é crítica para a confiabilidade do sistema.

## 1. Definição Formal de Idempotência

Um pipeline é idempotente quando executar a função f(x) duas vezes produz o mesmo resultado que executar uma vez:

```
f(f(x)) = f(x)
```

No contexto deste pipeline: se os documentos não mudaram desde a última execução, re-executar DEVE resultar em ZERO ALTERAÇÕES na Base Vetorial.

Isso significa que:
- Nenhum nó é criado, atualizado ou deletado.
- Nenhuma relação é modificada.
- Nenhum embedding é recalculado.
- O estado da Base Vetorial antes e depois da re-execução é idêntico.

## 2. Como Cada Etapa Garante Idempotência

### Etapa 1: Descoberta (hash SHA-256)

**Mecanismo:** comparação de hash SHA-256.

O hash SHA-256 é uma função determinística: o mesmo conteúdo sempre produz o mesmo hash. Para cada documento .md no manifesto, o pipeline:

1. Calcula o hash SHA-256 do conteúdo atual.
2. Consulta o hash armazenado na Base Vetorial (campo `file_hash` do nó Document).
3. Se os hashes são idênticos: classifica como UNCHANGED.

Documentos UNCHANGED são completamente ignorados nas Etapas 2 a 6. Nenhum processamento ocorre.

Este é o **MECANISMO CENTRAL** de idempotência. Se nada mudou, nada é processado.

**Alternativas descartadas e por que não funcionam:**
- Data de modificação: git clone reseta timestamps de arquivos.
- Número de versão no front matter: depende do autor lembrar de incrementar.
- Tamanho do arquivo: colisões óbvias (dois conteúdos diferentes podem ter o mesmo tamanho).

### Etapa 5: Persistência (upsert)

**Mecanismo:** padrão upsert (MERGE no Cypher).

Upsert = "update if exists, insert if not". Se um documento NEW for re-processado por qualquer razão:

- Se o nó Document já existe (criado na execução anterior): atualiza com os mesmos valores. Resultado idêntico.
- Se o nó Document não existe: cria normalmente.

O upsert garante que re-processar um documento já existente não duplica nós nem corrompe relações. O resultado final é o mesmo independente de quantas vezes a operação é executada.

Isso se aplica também à criação de nós auxiliares (System, Module, Owner, Team): são criados com MERGE, que só cria se não existir.

### Etapa 6: Indexação (CREATE IF NOT EXISTS)

**Mecanismo:** índices são criados com semântica "CREATE IF NOT EXISTS".

Se o índice vetorial, full-text ou qualquer constraint já existe:
- A operação é um no-op (nada acontece).
- Nenhum erro é gerado.
- O índice existente permanece intacto.

Isso garante que re-executar a Etapa 6 quantas vezes for necessário nunca duplica índices nem causa conflitos.

## 3. Fluxo Completo de Idempotência

Cenário: pipeline executado 2 vezes sobre os mesmos documentos sem mudanças.

**Execução 1:**
- Etapa 1: Classifica documentos como NEW -> processa tudo.
- Etapa 2: Parse dos documentos.
- Etapa 3: Gera chunks.
- Etapa 4: Gera embeddings.
- Etapa 5: Upsert cria nós e relações.
- Etapa 6: Cria índices.
- Etapa 7: Registra métricas.

**Execução 2 (mesmos documentos, sem mudanças):**
- Etapa 1: Calcula hash -> idêntico ao armazenado -> UNCHANGED para TODOS.
- Etapas 2-6: NÃO EXECUTADAS (todos documentos são UNCHANGED).
- Etapa 7: Registra métricas (0 documentos processados).

**Resultado:** Base Vetorial idêntica antes e depois da Execução 2.

## 4. Por que Idempotência é Crítica

### 4.1 Webhooks duplicados

Plataformas Git (GitHub, GitLab) podem enviar o mesmo webhook mais de uma vez. Motivos comuns:
- Timeout na resposta do handler (plataforma reenvia).
- Retry automático após falha de rede.
- Bug na plataforma.

**Com idempotência:** o segundo webhook dispara o pipeline, que classifica todos os documentos como UNCHANGED e termina sem alterações. Seguro.

**Sem idempotência:** o segundo webhook reprocessaria tudo, potencialmente duplicando chunks ou corrompendo relações. Perigoso.

### 4.2 Cron overlap

Se existir um cron job como fallback (ex: verificação diária de releases não processadas), duas execuções podem sobrepor-se:

**Com idempotência:** a segunda execução encontra tudo UNCHANGED. No-op. (Nota: o lock exclusivo da [[ADR-E03]] impede execução simultânea, mas a idempotência garante segurança mesmo se o lock falhar.)

### 4.3 Retries seguros

Se o pipeline falha na Etapa 4 (Embeddings) e precisa ser re-executado:

**Com idempotência:** documentos já processados com sucesso nas Etapas 1-3 são classificados como UNCHANGED na Etapa 1 da re-execução. Apenas documentos que falharam são reprocessados.

**Sem idempotência:** todos os documentos seriam reprocessados, incluindo os que já estavam corretos. Desperdício de recursos e risco de erro.

### 4.4 Testabilidade

Idempotência é diretamente testável:

1. Executar pipeline sobre conjunto de documentos.
2. Registrar estado da Base Vetorial (snapshot).
3. Executar pipeline novamente sobre os mesmos documentos.
4. Comparar diff do estado: DEVE ser vazio.

Se o diff não é vazio, há um bug no pipeline. Este teste pode ser automatizado e executado em CI/CD.

## 5. Propriedades Derivadas

A idempotência do pipeline habilita outras propriedades importantes:

- **Reprodutibilidade:** Mesma entrada = mesma saída. Qualquer execução sobre o mesmo conjunto de documentos produz o mesmo estado na Base Vetorial.

- **Segurança de retry:** Qualquer etapa pode ser re-executada sem risco de corromper dados.

- **Debugging simplificado:** Se o estado da Base Vetorial está incorreto, basta re-executar o pipeline com a release correta. A idempotência garante que o resultado será o esperado.

- **Rollback previsível:** Re-executar o pipeline com uma release anterior restaura o estado correspondente. Documentos da release mais recente são classificados como DELETED e removidos.

<!-- conversion_quality: 95 -->
