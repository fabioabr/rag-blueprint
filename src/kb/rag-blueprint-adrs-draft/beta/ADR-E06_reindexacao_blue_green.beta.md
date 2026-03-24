---
id: BETA-E06
title: "Re-indexacao Blue/Green (Troca de Modelo de Embedding)"
domain: arquitetura
confidentiality: internal
sources:
  - type: txt
    origin: "src/kb/rag-blueprint-adrs-draft/draft/ADR-E06_reindexacao_blue_green.txt"
    captured_at: "2026-03-23"
    conversion_quality: 95
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
  - re-embedding
  - batch processing
  - retry com backoff
  - similaridade coseno
  - espacos dimensionais
  - vetores incompativeis
  - text-embedding-3-small
  - text-embedding-3-large
  - bge-m3
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
  - track b on-premises
  - frequencia de reindexacao
  - operacao de manutencao
  - mudanca de provedor
  - atualizacao de versao
  - mudanca de dimensoes
  - validacao de vetores
  - valores anomalos
  - nan infinito zeros
  - adr-006
  - pipeline de ingestao
  - etapa 4 embeddings
aliases:
  - "ADR-E06"
  - "Blue/Green Embedding"
status: draft
last_enrichment: "2026-03-23"
last_human_edit: "2026-03-23"
---

## Sumario

Este documento detalha o procedimento completo de re-indexacao Blue/Green, utilizado quando o modelo de embedding muda (ex: de text-embedding-3-small para text-embedding-3-large, ou de BGE-M3 para uma versao mais recente). O procedimento garante zero downtime e possibilidade de rollback.

## 1. Problema: Troca de Modelo de Embedding

Quando o modelo de embedding muda, TODOS os chunks na Base Vetorial precisam ser re-embedded. Isso e necessario porque:

- Vetores de modelos diferentes vivem em espacos dimensionais incompativeis. Um vetor de 1536 dimensoes (text-embedding-3-small) nao pode ser comparado por similaridade coseno com um vetor de 1024 dimensoes (BGE-M3).
- Mesmo modelos com as mesmas dimensoes geram vetores em espacos semanticos diferentes. Misturar vetores de modelos diferentes no mesmo indice produz resultados de busca incorretos.
- O indice vetorial HNSW e construido sobre os vetores existentes. Adicionar vetores de um modelo diferente corrompe a estrutura do grafo HNSW.

### Por que nao sobrescrever diretamente

- Durante a re-embedding (que pode levar horas para milhares de chunks), o sistema ficaria com vetores misturados: alguns do modelo antigo, alguns do novo. Buscas retornariam resultados inconsistentes.
- Uma falha no meio do processo deixaria estado corrompido: parte dos chunks com vetores do modelo novo, parte com vetores do antigo.
- Nao haveria rollback: os vetores antigos teriam sido sobrescritos.

## 2. Solucao: Blue/Green Index

A estrategia Blue/Green e inspirada no deploy Blue/Green de infraestrutura: manter duas versoes simultaneamente, validar a nova, e trocar atomicamente.

- **"Blue"** = indice atual (em producao)
- **"Green"** = indice novo (sendo preparado)

## 3. Procedimento em 5 Passos

### Passo 1: Criar novo indice ("Green" / "v2")

1. Criar novo indice vetorial HNSW no Neo4j com as dimensoes do novo modelo de embedding. Exemplo: se o novo modelo gera vetores de 1024 dimensoes, o indice v2 e configurado para 1024 dimensoes com similaridade coseno.
2. O indice atual ("Blue" / "v1") continua ativo e servindo buscas normalmente. Zero downtime.
3. O novo indice e criado vazio — sera populado no Passo 2.
4. Registrar metadados do novo indice:
   - Nome do indice (ex: `chunk_embedding_v2`)
   - Modelo de embedding associado
   - Dimensoes
   - Data de criacao
   - Status: "building"

### Passo 2: Re-embed todos os chunks

1. Para CADA chunk existente na Base Vetorial:
   - Preparar texto de entrada: `"[heading_path]\n\n[content]"`
   - Enviar para o NOVO modelo de embedding.
   - Armazenar o vetor resultante em um campo temporario: `embedding_v2`.

2. Processamento em lotes (batch de 100 chunks) com as mesmas garantias da Etapa 4 do pipeline normal:
   - Retry com backoff exponencial (1s, 2s, 4s, 8s, max 60s).
   - Apos 3 retries, batch marcado como FAILED.
   - Chunks falhados vao para fila de retry.

3. O campo `embedding` original (v1) NAO e alterado. Ambos coexistem:
   - `embedding`: vetor do modelo antigo (v1, em producao)
   - `embedding_v2`: vetor do modelo novo (temporario)

4. Este processo pode levar horas para bases grandes, sem impactar o servico em producao. Buscas continuam usando `embedding` (v1).

5. Registrar progresso:
   - Total de chunks processados / total
   - Batches com sucesso / falha
   - Tempo estimado de conclusao

### Passo 3: Validacao de qualidade

1. Executar o golden set (50-100 perguntas curadas) contra AMBOS os indices:
   - Busca no indice v1 (`embedding`): registrar Recall@10.
   - Busca no indice v2 (`embedding_v2`): registrar Recall@10.

2. Comparar os resultados:

   - **Se Recall@10(v2) >= Recall@10(v1):** Novo modelo e igual ou melhor. Prosseguir para o Passo 4.
   - **Se Recall@10(v2) < Recall@10(v1):** Novo modelo e PIOR. Procedimento de aborto:
     a. Deletar indice v2.
     b. Remover campo `embedding_v2` de todos os chunks.
     c. Manter v1 ativo sem alteracoes.
     d. Registrar resultado da validacao para analise.
     e. Alertar o time com os resultados comparativos.

3. Alem do Recall@10, verificar:
   - Todos os chunks tem `embedding_v2` (nenhum faltando).
   - Dimensoes dos vetores v2 sao consistentes.
   - Nenhum vetor com valores anomalos (NaN, infinito, todos zeros).

### Passo 4: Switch atomico

Apos validacao bem-sucedida, trocar o indice ativo:

1. Mover `embedding_v2` para `embedding`:
   - Para cada chunk: `embedding = embedding_v2`.
   - Operacao executada em transacao (ou batches transacionais para bases grandes).

2. Atualizar metadados do modelo em todos os chunks:
   - `embedding_model`: nome do novo modelo
   - `embedding_model_version`: versao do novo modelo
   - `embedding_dimensions`: dimensoes do novo modelo
   - `embedded_at`: timestamp atual

3. Atualizar indice ativo:
   - Dropar indice v1.
   - Renomear ou reconfigurar indice v2 como indice principal.
   - Ou: criar novo indice sobre o campo `embedding` atualizado e dropar ambos v1 e v2.

4. Zero downtime: a troca e atomica do ponto de vista do servico de busca. Nao ha janela onde buscas ficam indisponiveis.

5. Registrar:
   - Timestamp do switch
   - Modelo anterior e modelo novo
   - Recall@10 comparativo
   - Responsavel pela aprovacao

### Passo 5: Cleanup apos confirmacao

1. Manter o indice v1 e os campos temporarios por 24-48 horas apos o switch. Motivo: permite rollback rapido se problemas forem detectados em producao.

2. Durante as 48 horas de confirmacao:
   - Monitorar Recall@10 em producao.
   - Monitorar latencia de busca.
   - Monitorar feedback dos usuarios/agentes.
   - Verificar se nenhum comportamento anomalo aparece.

3. Se tudo estiver normal apos 48 horas:
   - Deletar indice v1 (se ainda existir).
   - Remover campo `embedding_v2` de todos os chunks (se ainda existir).
   - Liberar espaco de armazenamento.

4. Se problemas forem detectados durante as 48 horas:
   - Rollback: restaurar embedding original do campo temporario.
   - Reativar indice v1.
   - Dropar indice v2.
   - Investigar a causa do problema.

5. Registrar resultado final:
   - Sucesso ou rollback
   - Duracao total do processo
   - Metricas comparativas antes/depois

## 4. Requisitos de Espaco e Recursos

Durante o processo Blue/Green, a Base Vetorial precisa de espaco para:

- Dois campos de embedding por chunk (`embedding` e `embedding_v2`).
- Dois indices vetoriais HNSW simultaneos (v1 e v2).

Estimativa: aproximadamente o DOBRO do espaco de armazenamento normal para embeddings, durante o periodo do processo (horas a dias).

Recursos de computacao:
- Re-embedding de todos os chunks (Passo 2) consome API/GPU proporcionalmente ao volume total da Base Vetorial.
- Para Track A (Cloud/OpenAI): custo de re-embedding proporcional ao total de tokens.
- Para Track B (On-premises/BGE-M3): tempo de GPU proporcional ao total de chunks.

## 5. Frequencia Esperada

A re-indexacao Blue/Green NAO e uma operacao frequente. Cenarios:

- Mudanca de modelo de embedding (ex: novo modelo com melhor qualidade).
- Mudanca de provedor (ex: migrar de Track A para Track B).
- Atualizacao de versao do modelo (ex: BGE-M3 v1 para v2).
- Mudanca de dimensoes ou parametros do embedding.

Frequencia esperada: poucas vezes por ano, no maximo. Cada execucao deve ser planejada, validada e monitorada como uma operacao de manutencao critica.

<!-- conversion_quality: 95 -->
