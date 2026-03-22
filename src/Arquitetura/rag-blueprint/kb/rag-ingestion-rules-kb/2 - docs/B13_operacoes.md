---
id: RAG-B13
doc_type: architecture-doc
title: "Operações"
system: RAG Corporativo
module: Operações
domain: Arquitetura
owner: fabio
team: arquitetura
status: in-review
confidentiality: internal
tags: [rag, blueprint, operacoes, backup, erros, reindexacao, ciclo-vida, glossario]
aliases: ["Operações", "B13", "Backup", "Re-indexação"]
source_format: txt
source_repo: banco-patria
source_path: Arquitetura/rag-blueprint/1 - draft/B13_operacoes.txt
conversion_pipeline: manual-v1
conversion_quality: 100
converted_at: 2026-03-18
created_at: 2026-03-18
updated_at: 2026-03-18
---

# 🔧 Operações

**Backup, Re-indexação, Tratamento de Erros e Ciclo de Vida**

- 📂 Série: RAG Blueprint Series
- 📌 Documento: B13 — Operações
- 📅 Data: 18/03/2026
- 📋 Versão: 1.0
- 🔗 Base: [[B03_camada_ouro|B3 (Camada Ouro)]], [[B06_graphrag_maturidade|B6 (Retroalimentação)]], [[B08_pendencias|B8 (Infra)]], [[B11_deployment_infraestrutura|B11 (Deploy)]]

> [!info] Operações
> Cobre backup, disaster recovery, tratamento de erros, re-indexação e ciclo de vida — ver [[B16_roadmap_implementacao]] para marcos e sequenciamento.

#operacoes #backup #reindexacao

## 🎯 Objetivo

Cobrir os aspectos operacionais do RAG em produção: como proteger os dados, como lidar com falhas, como re-indexar e como gerenciar o ciclo de vida do conhecimento.

## 📌 13.1 — Backup e Disaster Recovery

### 🔹 O que precisa de backup

| Componente | Tipo | Criticidade |
|------------|------|-------------|
| Repo Bronze (Git) | Git + LFS | 🔴 ALTA — fonte orig. |
| Repo Prata (Git) | Git | 🟡 MÉDIA — regenerável |
| Neo4j (Ouro) | Banco de dados | 🟡 MÉDIA — regenerável |
| Config / .env | Arquivos | 🔴 ALTA — secrets |
| Logs do pipeline | Arquivos/JSON | 🟢 BAIXA — descartável |

A Prata e a Ouro são regeneráveis a partir do Bronze:

```
Bronze → pipeline Bronze→Prata → Prata
Prata → pipeline Prata→Ouro → Ouro (Neo4j)
```

Portanto o Bronze é o ativo mais crítico.

### 🔹 Estratégia de backup

**Repo Bronze:**

- 🔸 Git push para remote secundário (GitLab mirror, backup repo)
- 🔸 Frequência: a cada push (automático via hook)
- 🔸 Git LFS: garantir que remote de backup suporta LFS
- 🔸 Retenção: ilimitada (é a origem da verdade)

**Repo Prata:**

- 🔸 Git push para remote (mesmo fluxo do bronze)
- 🔸 Frequência: a cada commit
- 🔸 Se perder: regenerar a partir do bronze (pipeline completo)

**Neo4j:**

- 🔸 Neo4j Aura: backup automático incluído no serviço
- 🔸 Neo4j Docker: dump diário via neo4j-admin dump
  - Comando: `neo4j-admin database dump neo4j --to-path=/backup`
  - Cron: 03:00 UTC (após ingestão diária das 02:00)
- 🔸 Retenção: últimos 7 dumps (rotação automática)
- 🔸 Se perder: regenerar executando pipeline Prata→Ouro full (leva ~30min para 1000 docs — ver SLA em [[B12_testes_validacao_slas|B12]])

**Config / Secrets:**

- 🔸 .env files: backup cifrado em local seguro
- 🔸 Vault (se usar): backup do próprio Vault
- 🔸 Nunca commitar secrets em repositório Git

### 🔹 Procedimento de recovery

**Cenário 1 — Neo4j corrompido/perdido:**

1. Restaurar dump mais recente: `neo4j-admin database load`
2. Ou: executar pipeline Prata→Ouro full (regenera tudo)
3. Validar: rodar golden set de testes ([[B12_testes_validacao_slas|B12]])

**Cenário 2 — Repo Prata perdido:**

1. Clonar novo repo prata (vazio)
2. Executar pipeline Bronze→Prata full
3. Executar pipeline Prata→Ouro full
4. Validar: conferir contagem de docs no Neo4j

**Cenário 3 — Repo Bronze perdido:**

🔴 CRÍTICO — dados originais perdidos

1. Restaurar do remote de backup
2. Se não houver backup: dados perdidos irreversivelmente
3. Por isso: manter SEMPRE um mirror atualizado

## 📌 13.2 — Tratamento de Erros nos Pipelines

### 🔹 Princípio geral

- 🔸 Falha em 1 documento NÃO deve parar o pipeline inteiro
- 🔸 Documentos com erro vão para fila de retry
- 🔸 Após N retries sem sucesso → dead letter (log + alerta)
- 🔸 Pipeline sempre gera relatório de execução ao final

### 🔹 Pipeline Bronze→Prata — erros comuns

| Erro | Ação |
|------|------|
| Arquivo corrompido (PDF ilegível, DOCX broken) | Log + skip + dead letter |
| OCR com confidence < 30% | Rejeitar (não gera .md), Log com path do original |
| LLM indisponível (se usado na conversão) | Retry 3x com backoff exponencial (5s, 30s, 120s). Se falhar: skip + dead letter |
| Formato não suportado | Log warning + skip, Registrar no manifesto |
| Git clone/pull falha | Retry 3x com backoff. Se falhar: abortar execução (sem repo = sem pipeline) |

### 🔹 Pipeline Prata→Ouro — erros comuns

| Erro | Ação |
|------|------|
| Front matter inválido | Log + skip + dead letter, Relatório de conformidade |
| API de embedding down | Retry 3x com backoff exponencial (5s, 30s, 120s). Se falhar: skip doc + dead letter |
| Neo4j indisponível | Retry 3x com backoff. Se falhar: abortar execução (sem Neo4j = nada a fazer) |
| Documento muito grande (> token limit do embed) | Truncar com warning ou chunking mais agressivo |
| Constraint violation (document_id duplicado) | Log erro + investigar duplicata. Possível merge de versões |

### 🔹 Retry strategy

Padrão para todas as chamadas a serviços externos:

- 🔸 Máximo de tentativas: 3
- 🔸 Backoff exponencial: 5s → 30s → 120s
- 🔸 Jitter aleatório: ±20% para evitar thundering herd
- 🔸 Se falhar após 3 retries: skip + dead letter + alerta

### 🔹 Dead letter

Documentos que falharam repetidamente são registrados em:

- 🔸 Arquivo JSON: `dead_letter_<timestamp>.json`
- 🔸 Conteúdo: path, erro, tentativas, timestamps
- 🔸 Revisão manual necessária para resolver
- 🔸 Alerta por e-mail ou Slack quando dead letter não está vazio

### 🔹 Relatório de execução

Ao final de cada pipeline run, gerar relatório com:

- 🔸 Total de documentos processados
- 🔸 Total de sucesso / falha / skip
- 🔸 Lista de documentos com erro (path + tipo de erro)
- 🔸 Dead letter entries criados
- 🔸 Tempo total de execução
- 🔸 Formato: JSON (para automação) + HTML (para visualização — [[B12_testes_validacao_slas|B12]])

## 📌 13.3 — Re-indexação

Situações que exigem re-indexação:

### 🔹 Mudança de modelo de embedding

- 🔸 Todos os chunks precisam de novos vetores
- 🔸 Não é possível misturar vetores de modelos diferentes no mesmo índice

**Procedimento (blue/green):**

1. Criar novo vector index com novo nome (ex: `chunk_embedding_index_v2`)
2. Reprocessar todos os chunks → novos embeddings → novo index
3. Validar: rodar golden set contra novo index
4. Se ok: alterar config da API para usar novo index
5. Dropar index antigo

- 🔸 Zero downtime: API continua servindo pelo index antigo durante o reprocessamento. Troca é atômica (alterar nome na config).

### 🔹 Mudança de estratégia de chunking

- 🔸 Todos os chunks precisam ser regenerados
- 🔸 Embeddings também mudam (conteúdo diferente = vetor diferente)

**Procedimento:**

1. Executar pipeline Prata→Ouro full com novo chunking
2. Pipeline remove chunks antigos e cria novos (upsert por document_id)
3. Validar: golden set + conferir contagem de chunks

### 🔹 Mudança no schema do Neo4j (nova propriedade, novo index)

- 🔸 Neo4j é schema-free — adicionar propriedade não requer migração
- 🔸 Para novo index: criar via Cypher, sem downtime
- 🔸 Para popular nova propriedade em nós existentes: Cypher batch update (MATCH → SET em lotes de 1000)

### 🔹 Re-indexação de emergência

- 🔸 Se Neo4j corrupto ou com dados inconsistentes
- 🔸 Procedimento: drop database → recreate → pipeline full
- 🔸 Tempo estimado: ~30 min para 1000 docs (ver SLA em [[B12_testes_validacao_slas|B12]])

## 📌 13.4 — Ciclo de Vida do Documento

### Estados e transições

```
┌─────────┐     ┌───────────┐     ┌──────────┐
│  DRAFT  │ ──→ │ IN-REVIEW │ ──→ │ APPROVED │
└─────────┘     └───────────┘     └────┬─────┘
     ↑                                  │
     │ (conversão baixa quality)        ↓
     │                           ┌──────────────┐
     └───────────────────────────│ DEPRECATED   │
                                 └──────────────┘
```

### 🔹 Triggers de transição

| Transição | Trigger |
|-----------|---------|
| → DRAFT | Conversão com quality < 80% ou criação manual sem revisão |
| DRAFT → IN-REVIEW | Revisão humana feita (campo update) ou quality recalculado >= 80% |
| IN-REVIEW → APPROVED | Aprovação humana (commit com status) ou automática se origem é .md nativo |
| APPROVED → DEPRECATED | Documento substituído por versão nova, ou marcado manualmente como obsoleto, ou sem atualização por > 12 meses (candidato — requer confirmação) |
| DEPRECATED → DRAFT | Reativação: documento revisado e atualizado, volta ao início do ciclo |

### 🔹 Impacto no retrieval por status

- 🔸 **APPROVED** — incluído em todas as buscas (peso normal)
- 🔸 **IN-REVIEW** — incluído com flag de "em revisão" na resposta
- 🔸 **DRAFT** — excluído da busca por padrão (incluído apenas se filtro explícito: status=draft)
- 🔸 **DEPRECATED** — excluído da busca por padrão (incluído apenas se filtro explícito ou busca histórica)

### 🔹 Quem pode alterar status

- 🔸 Pipeline automático → DRAFT (conversão nova)
- 🔸 Pipeline automático → IN-REVIEW (quality >= 80%)
- 🔸 Owner do documento → APPROVED, DEPRECATED
- 🔸 Admin / curador → qualquer transição

### 🔹 Detecção de obsolescência

- 🔸 Query semanal: documentos approved sem updated_at há > 12 meses
- 🔸 Gerar relatório de candidatos a deprecated
- 🔸 Notificar owner para revisão
- 🔸 Se owner não responde em 30 dias → mover para deprecated automaticamente

## 📌 13.5 — Curadoria do Glossário

O nó `:GlossaryTerm` ([[B05_knowledge_graph|B5]]) requer curadoria ativa:

### 🔹 Fontes de termos

- 🔸 **Manual** — curador adiciona termos ao repo prata como .md com `doc_type: glossary`
- 🔸 **Automática** — pipeline de NER (Fase 3+) sugere termos novos detectados em documentos, curador aprova/rejeita
- 🔸 **Colaborativa** — formulário simples onde qualquer pessoa sugere termos (aprovação do curador obrigatória)

### 🔹 Estrutura de um termo no glossário

```json
{
  "id": "GLOSS-000001",
  "doc_type": "glossary",
  "title": "CNAB 240",
  "domain": "Financeiro",
  "status": "approved"
}
```

```markdown
## CNAB 240

**Definição:** Padrão de layout de arquivo para troca de informações
entre bancos e empresas, definido pela FEBRABAN. Versão 240 posições.

**Sinônimos:** Layout CNAB, Remessa 240

**Contexto:** Utilizado no módulo de Cobrança para geração de
arquivos de remessa bancária.
```

### 🔹 Vinculação automática

- 🔸 Pipeline Prata→Ouro identifica termos do glossário no conteúdo dos chunks (matching por nome + sinônimos)
- 🔸 Cria relação `(:Document)-[:USES_TERM]->(:GlossaryTerm)`
- 🔸 Permite perguntas como: "Quais documentos mencionam CNAB 240?"

### 🔹 Responsabilidade

- 🔸 Curador do glossário: owner designado (1 pessoa por domínio)
- 🔸 Revisão trimestral: termos ainda relevantes? definições atuais?
- 🔸 Métricas: termos sem vínculo (órfãos), termos mais referenciados

## 📌 13.6 — Alertas e Notificações

Eventos que devem gerar alerta:

| Evento | Canal | Severidade |
|--------|-------|------------|
| Pipeline falhou completamente | Slack/email | 🔴 CRÍTICO |
| Neo4j indisponível | Slack/email | 🔴 CRÍTICO |
| API down (health check fail) | Slack/email | 🔴 CRÍTICO |
| Dead letter não vazio | Slack | 🟡 ATENÇÃO |
| Taxa de falha > 5% no pipeline | Slack | 🟡 ATENÇÃO |
| Latência p95 > SLA | Slack | 🟡 ATENÇÃO |
| Backup falhou | Slack/email | 🟡 ATENÇÃO |
| Docs candidatos a deprecated | Email owner | 🟢 INFO |
| Pipeline full sync concluído | Log | 🟢 INFO |
| Novo glossário term sugerido | Email curad. | 🟢 INFO |

**Implementação:**

- 🔸 Fase 1-2: alertas por e-mail ou mensagem Slack via webhook
- 🔸 Fase 3+: integrar com ferramenta de alerting (PagerDuty, Opsgenie) se houver SLA formal

## 📌 13.7 — Evolução por Fase

| Capacidade | Fase 1 | Fase 2 | Fase 3 | Fase 4 |
|------------|--------|--------|--------|--------|
| Backup Neo4j | Manual | Cron diário | Cron diário | Cron + alertas |
| Backup Git | Remote (push) | Remote (push) | Remote (push) | Remote + mirror |
| Error handling | Log + skip | + retry backoff | + dead letter | + alertas automát. |
| Re-indexação | Manual (full) | Manual (full) | Blue/green | Blue/green |
| Ciclo de vida | Manual | Status no front matter | + detect. obsolesc. | + auto deprec. |
| Glossário | — | — | Manual + curador | + NER + auto |
| Alertas | Log | E-mail | Slack | PagerDty |

> [!warning] Dependências críticas
> A re-indexação depende da escolha de modelo de embedding — ver [[B08_pendencias#P1|P1 — Embedding]]. A observabilidade do pipeline depende de [[B08_pendencias#P12|P12 — Observabilidade]].

> [!info] Segurança
> Para procedimentos de incidente com dados sensíveis (PII), seguir [[B14_seguranca_soberania_dados]]. Para rollback urgente, ver [[B15_governanca_capacidade_rollback#🔹 Rollback urgente (dados sensíveis)|B15 — Rollback urgente]].

---

## Documentos relacionados

### Depende de
- [[B03_camada_ouro]] — persistência e vector index
- [[B06_graphrag_maturidade]] — retrieval híbrido e retroalimentação
- [[B11_deployment_infraestrutura]] — ambiente de produção
- [[B12_testes_validacao_slas]] — golden set e métricas de qualidade

### Habilita
- [[B15_governanca_capacidade_rollback]] — governança operacional

### Relacionados
- [[B08_pendencias]] — P1 (embedding para re-indexação) e P12 (observabilidade)
