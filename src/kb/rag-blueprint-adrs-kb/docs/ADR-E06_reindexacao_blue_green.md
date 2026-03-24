---
id: ADR-E06
doc_type: adr
title: "Reindexação Blue/Green (Troca de Modelo de Embedding)"
system: RAG Corporativo
module: Reindexação
domain: Arquitetura
owner: fabio
team: arquitetura
status: accepted
confidentiality: internal
date_decided: 2026-03-23
tags:
  - reindexacao blue green
  - troca de modelo de embedding
  - indice vetorial
  - indice hnsw
  - zero downtime
  - rollback de modelo
  - validacao de qualidade
  - golden set
  - recall at 10
  - switch atomico
  - embedding v2
  - campo temporario
  - re embedding
  - batch processing
  - retry com backoff
  - similaridade coseno
  - espacos dimensionais
  - vetores incompativeis
  - text embedding 3 small
  - text embedding 3 large
  - bge m3
  - neo4j
  - base vetorial
  - deploy blue green
  - indice blue
  - indice green
  - metadados do modelo
  - embedding model
  - embedding model version
  - embedding dimensions
  - embedded at
  - transacao atomica
  - batches transacionais
  - cleanup pos confirmacao
  - periodo de confirmacao
  - monitoramento pos switch
  - latencia de busca
  - feedback de usuarios
  - espaco de armazenamento
  - dobro do armazenamento
  - recursos de computacao
  - track a cloud openai
  - track b on premises
  - frequencia de reindexacao
  - operacao de manutencao
  - mudanca de provedor
  - atualizacao de versao
  - mudanca de dimensoes
  - validacao de vetores
  - valores anomalos
  - nan infinito zeros
  - pipeline de ingestao
  - etapa 4 embeddings
aliases:
  - "ADR-E06"
  - "Blue/Green Embedding"
  - "Reindexação Blue/Green"
  - "Troca de Modelo de Embedding"
  - "Blue/Green Index"
superseded_by: null
source_format: txt
source_repo: Rag
source_path: "kb/rag-blueprint-adrs-draft/draft/ADR-E06_reindexacao_blue_green.txt"
source_beta_ids:
  - "BETA-E06"
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

# ADR-E06 — Reindexação Blue/Green (Troca de Modelo de Embedding)

| Campo | Valor |
|-------|-------|
| **Status** | Accepted |
| **Data da Decisão** | 2026-03-23 |
| **Decisor** | fabio |
| **Escopo** | Reindexação |

**Referências Cruzadas:**

- **Depende de:** [[ADR-006]], [[ADR-009]]
- **Relaciona-se:** [[ADR-002]], [[ADR-E01]]

## Sumário

Este documento detalha o procedimento completo de reindexação Blue/Green, utilizado quando o modelo de embedding muda (ex: de text-embedding-3-small para text-embedding-3-large, ou de BGE-M3 para uma versão mais recente). O procedimento garante zero downtime e possibilidade de rollback.

## 1. Problema: Troca de Modelo de Embedding

Quando o modelo de embedding muda, TODOS os chunks na Base Vetorial precisam ser re-embedded. Isso é necessário porque:

- Vetores de modelos diferentes vivem em espaços dimensionais incompatíveis. Um vetor de 1536 dimensões (text-embedding-3-small) não pode ser comparado por similaridade cosseno com um vetor de 1024 dimensões (BGE-M3).
- Mesmo modelos com as mesmas dimensões geram vetores em espaços semânticos diferentes. Misturar vetores de modelos diferentes no mesmo índice produz resultados de busca incorretos.
- O índice vetorial HNSW é construído sobre os vetores existentes. Adicionar vetores de um modelo diferente corrompe a estrutura do grafo HNSW.

### Por que não sobrescrever diretamente

- Durante a re-embedding (que pode levar horas para milhares de chunks), o sistema ficaria com vetores misturados: alguns do modelo antigo, alguns do novo. Buscas retornariam resultados inconsistentes.
- Uma falha no meio do processo deixaria estado corrompido: parte dos chunks com vetores do modelo novo, parte com vetores do antigo.
- Não haveria rollback: os vetores antigos teriam sido sobrescritos.

## 2. Solução: Blue/Green Index

A estratégia Blue/Green é inspirada no deploy Blue/Green de infraestrutura: manter duas versões simultaneamente, validar a nova, e trocar atomicamente.

- **"Blue"** = índice atual (em produção)
- **"Green"** = índice novo (sendo preparado)

## 3. Procedimento em 5 Passos

### Passo 1: Criar novo índice ("Green" / "v2")

1. Criar novo índice vetorial HNSW no Neo4j com as dimensões do novo modelo de embedding. Exemplo: se o novo modelo gera vetores de 1024 dimensões, o índice v2 é configurado para 1024 dimensões com similaridade cosseno.
2. O índice atual ("Blue" / "v1") continua ativo e servindo buscas normalmente. Zero downtime.
3. O novo índice é criado vazio — será populado no Passo 2.
4. Registrar metadados do novo índice:
   - Nome do índice (ex: `chunk_embedding_v2`)
   - Modelo de embedding associado
   - Dimensões
   - Data de criação
   - Status: "building"

### Passo 2: Re-embed todos os chunks

1. Para CADA chunk existente na Base Vetorial:
   - Preparar texto de entrada: `"[heading_path]\n\n[content]"`
   - Enviar para o NOVO modelo de embedding.
   - Armazenar o vetor resultante em um campo temporário: `embedding_v2`.

2. Processamento em lotes (batch de 100 chunks) com as mesmas garantias da Etapa 4 do pipeline normal:
   - Retry com backoff exponencial (1s, 2s, 4s, 8s, max 60s).
   - Após 3 retries, batch marcado como FAILED.
   - Chunks falhados vão para fila de retry.

3. O campo `embedding` original (v1) NÃO é alterado. Ambos coexistem:
   - `embedding`: vetor do modelo antigo (v1, em produção)
   - `embedding_v2`: vetor do modelo novo (temporário)

4. Este processo pode levar horas para bases grandes, sem impactar o serviço em produção. Buscas continuam usando `embedding` (v1).

5. Registrar progresso:
   - Total de chunks processados / total
   - Batches com sucesso / falha
   - Tempo estimado de conclusão

### Passo 3: Validação de qualidade

1. Executar o golden set (50-100 perguntas curadas) contra AMBOS os índices:
   - Busca no índice v1 (`embedding`): registrar Recall@10.
   - Busca no índice v2 (`embedding_v2`): registrar Recall@10.

2. Comparar os resultados:

   - **Se Recall@10(v2) >= Recall@10(v1):** Novo modelo é igual ou melhor. Prosseguir para o Passo 4.
   - **Se Recall@10(v2) < Recall@10(v1):** Novo modelo é PIOR. Procedimento de aborto:
     a. Deletar índice v2.
     b. Remover campo `embedding_v2` de todos os chunks.
     c. Manter v1 ativo sem alterações.
     d. Registrar resultado da validação para análise.
     e. Alertar o time com os resultados comparativos.

3. Além do Recall@10, verificar:
   - Todos os chunks têm `embedding_v2` (nenhum faltando).
   - Dimensões dos vetores v2 são consistentes.
   - Nenhum vetor com valores anômalos (NaN, infinito, todos zeros).

### Passo 4: Switch atômico

Após validação bem-sucedida, trocar o índice ativo:

1. Mover `embedding_v2` para `embedding`:
   - Para cada chunk: `embedding = embedding_v2`.
   - Operação executada em transação (ou batches transacionais para bases grandes).

2. Atualizar metadados do modelo em todos os chunks:
   - `embedding_model`: nome do novo modelo
   - `embedding_model_version`: versão do novo modelo
   - `embedding_dimensions`: dimensões do novo modelo
   - `embedded_at`: timestamp atual

3. Atualizar índice ativo:
   - Dropar índice v1.
   - Renomear ou reconfigurar índice v2 como índice principal.
   - Ou: criar novo índice sobre o campo `embedding` atualizado e dropar ambos v1 e v2.

4. Zero downtime: a troca é atômica do ponto de vista do serviço de busca. Não há janela onde buscas ficam indisponíveis.

5. Registrar:
   - Timestamp do switch
   - Modelo anterior e modelo novo
   - Recall@10 comparativo
   - Responsável pela aprovação

### Passo 5: Cleanup após confirmação

1. Manter o índice v1 e os campos temporários por 24-48 horas após o switch. Motivo: permite rollback rápido se problemas forem detectados em produção.

2. Durante as 48 horas de confirmação:
   - Monitorar Recall@10 em produção.
   - Monitorar latência de busca.
   - Monitorar feedback dos usuários/agentes.
   - Verificar se nenhum comportamento anômalo aparece.

3. Se tudo estiver normal após 48 horas:
   - Deletar índice v1 (se ainda existir).
   - Remover campo `embedding_v2` de todos os chunks (se ainda existir).
   - Liberar espaço de armazenamento.

4. Se problemas forem detectados durante as 48 horas:
   - Rollback: restaurar embedding original do campo temporário.
   - Reativar índice v1.
   - Dropar índice v2.
   - Investigar a causa do problema.

5. Registrar resultado final:
   - Sucesso ou rollback
   - Duração total do processo
   - Métricas comparativas antes/depois

## 4. Requisitos de Espaço e Recursos

Durante o processo Blue/Green, a Base Vetorial precisa de espaço para:

- Dois campos de embedding por chunk (`embedding` e `embedding_v2`).
- Dois índices vetoriais HNSW simultâneos (v1 e v2).

Estimativa: aproximadamente o DOBRO do espaço de armazenamento normal para embeddings, durante o período do processo (horas a dias).

Recursos de computação:
- Re-embedding de todos os chunks (Passo 2) consome API/GPU proporcionalmente ao volume total da Base Vetorial.
- Para Track A (Cloud/OpenAI): custo de re-embedding proporcional ao total de tokens.
- Para Track B (On-premises/BGE-M3): tempo de GPU proporcional ao total de chunks.

## 5. Frequência Esperada

A reindexação Blue/Green NÃO é uma operação frequente. Cenários:

- Mudança de modelo de embedding (ex: novo modelo com melhor qualidade).
- Mudança de provedor (ex: migrar de Track A para Track B).
- Atualização de versão do modelo (ex: BGE-M3 v1 para v2).
- Mudança de dimensões ou parâmetros do embedding.

Frequência esperada: poucas vezes por ano, no máximo. Cada execução deve ser planejada, validada e monitorada como uma operação de manutenção crítica.

<!-- conversion_quality: 95 -->
