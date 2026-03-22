---
id: RAG-B00
doc_type: architecture-doc
title: "Blueprint RAG Corporativo — Introdução e Visão Geral"
system: RAG Corporativo
module: Introdução
domain: Arquitetura
owner: fabio
team: arquitetura
status: in-review
confidentiality: internal
tags: [rag, blueprint, introducao, visao-geral, bronze-prata-ouro]
aliases: ["Introdução", "Visão Geral", "B00", "Blueprint RAG"]
source_format: txt
source_repo: banco-patria
source_path: Arquitetura/rag-blueprint/1 - draft/B00_introducao.txt
conversion_pipeline: manual-v1
conversion_quality: 100
converted_at: 2026-03-18
created_at: 2026-03-18
updated_at: 2026-03-18
---

# Blueprint RAG Corporativo — Introdução

Arquitetura End-to-End para Entrega de um RAG Corporativo

| | |
|---|---|
| 📂 Série | RAG Blueprint Series |
| 📌 Documento | B0 — Introdução e Visão Geral |
| 📅 Data | 17/03/2026 |
| 📋 Versão | 1.1 |
| 🔗 Base | B0.1, B0.2, B1.1, blueprint_base_conhecimento_neo4j, ADR-001 |

### 📚 Documentos da série

- [[B00_introducao|B00 — Introdução e Visão Geral]] (este documento)
- [[B01_camada_bronze|B01 — Camada Bronze: Captura de Fontes Originais]]
- [[B02_camada_prata|B02 — Camada Prata: Pipeline de Conversão e Markdown Normalizado]]
- [[B03_camada_ouro|B03 — Camada Ouro: Pipeline de Ingestão Neo4j, Modelo de Dados e Busca]]
- [[B04_metadados_governanca|B04 — Fase 2: Metadados Fortes — Governança e Filtragem]]
- [[B05_knowledge_graph|B05 — Fase 3: Knowledge Graph — Relações e Fontes Expandidas]]
- [[B06_graphrag_maturidade|B06 — Fase 4: GraphRAG Corporativo — Maturidade Completa]]
- [[B07_visao_consolidada|B07 — Visão Consolidada: Evolução por Fase]]
- [[B08_pendencias|B08 — Pendências: Recomendações e Alternativas]]
- [[B09_referencias|B09 — Referências e Histórico de Versões]]
- [[B10_api_interface_acesso|B10 — API e Interface de Acesso]]
- [[B11_deployment_infraestrutura|B11 — Deployment e Infraestrutura de Execução]]
- [[B12_testes_validacao_slas|B12 — Testes, Validação e SLAs]]
- [[B13_operacoes|B13 — Operações: Backup, Re-indexação, Erros e Ciclo de Vida]]
- [[B14_seguranca_soberania_dados|B14 — Segurança e Soberania de Dados]]
- [[B15_governanca_capacidade_rollback|B15 — Governança, Capacidade e Rollback]]
- [[B16_roadmap_implementacao|B16 — Roadmap de Implementação]]

---

## 🎯 Visão Geral

Este conjunto de documentos detalha a construção de um RAG corporativo para uma empresa genérica. A arquitetura é descrita por camadas (Bronze, Prata, Ouro) e a evolução por fases (1 a 4).

### Premissa central

- 👉 **Git** = origem da verdade (documentos Markdown com front matter)
- 👉 **Neo4j** = projeção operacional (grafo + vetor + metadados)
- 👉 **Agentes de IA** = consumidores controlados via recuperação híbrida

### Princípios norteadores

| Código | Princípio |
|--------|-----------|
| P.1 | Qualidade sobre quantidade |
| P.2 | Evolução incremental (MVP → escala) |
| P.3 | Governança desde o dia zero |
| P.4 | Conhecimento vivo |
| P.5 | Git como fonte canônica |
| P.6 | Segurança pré-retrieval |
| P.7 | Ingestão incremental |

---

## 🥉🥈🥇 Modelo de Camadas — Bronze / Prata / Ouro (ADR-001)

O conhecimento corporativo não vive apenas em `.md`. PDFs, e-mails, documentos Word, planilhas, transcrições de reuniões e outros formatos precisam ser incorporados.

Para isso, adotamos um modelo de três camadas:

### Camada Bronze — Fontes originais #camada/bronze

- 🔸 Repositório Git separado (ex: `banco-xpto-bronze`)
- 🔸 Arquivos nos formatos originais, sem alteração
- 🔸 Versionado para rastreabilidade e auditoria
- 🔸 Organizado por domínio/sistema
- 🔸 Possível uso de Git LFS para binários grandes

> [!tip] Ver também
> Detalhes em [[B01_camada_bronze]]

### Camada Prata — Markdown normalizado #camada/prata

- 🔸 Repositório principal da base de conhecimento
- 🔸 Apenas `.md` com front matter padronizado
- 🔸 Gerado por pipeline de conversão a partir do bronze
- 🔸 Todo documento passa pelo bronze antes de chegar aqui
- 🔸 Inclui campos de linhagem (lineage) no front matter

> [!tip] Ver também
> Detalhes em [[B02_camada_prata]]

### Camada Ouro — Projeção operacional (Neo4j) #camada/ouro

- 🔸 Grafo + vetor + metadados
- 🔸 Gerada pelo pipeline de ingestão (lê apenas `.md` da prata)

> [!tip] Ver também
> Detalhes em [[B03_camada_ouro]]

### Fluxo

```
[Repo Bronze]                [Repo Prata]                 [Neo4j — Ouro]
 .md, .pdf, .docx,     →     .md normalizados       →     Document, Chunk,
 .eml, .xlsx, .txt,          front matter padrão          relações, embeddings
 transcrições                 campos de linhagem           vector index
                              conversion_quality
```

### Campos de linhagem no front matter

```json
{
  "source_format": "pdf",           // md | pdf | docx | xlsx | eml | txt | transcript
  "source_repo": "banco-xpto-bronze",
  "source_path": "financeiro/relatorio-q1.xlsx",
  "source_hash": "sha256:...",
  "conversion_pipeline": "v1.2",
  "conversion_model": "gpt-4o",     // se usou LLM para extrair/estruturar
  "conversion_quality": 92.5,       // 0-100%, confiança na fidelidade da extração
  "converted_at": "2026-03-17"
}
```

### Campo conversion_quality (0–100%)

Escala contínua que expressa a confiança na fidelidade da conversão.

**Sinais para cálculo por formato:**

| Formato | Sinais |
|---------|--------|
| 📄 MD | 100% (validação de estrutura) |
| 📄 PDF texto | % de caracteres reconhecidos, estrutura preservada |
| 📄 PDF scan (OCR) | confidence do OCR, resolução da imagem |
| 📝 DOCX | praticamente 100% (conversão determinística) |
| 📊 XLSX | complexidade de fórmulas/merges, % tabelas convertidas |
| 📧 E-mail | completude de headers, anexos processados |
| 🎙️ Transcrição | word error rate do STT, sobreposição de falantes |

**Usos no pipeline:**

- ✅ **Threshold de ingestão** — abaixo de X%, entra como `status: draft`
- ✅ **Peso no reranking** — quality alta = prioridade na busca
- ✅ **Filtro no retriever** — agentes críticos podem exigir >= 80%
- ✅ **Observabilidade** — distribuição de qualidade por formato de origem

> [!info] Decisão formalizada
> Ver [[ADR-001_pipeline_geracao_conhecimento_4_fases]]

---

## Documentos relacionados

Este documento é o **ponto de entrada** da série e referencia todos os demais.

### Pipeline de Dados (fluxo linear)
- [[B01_camada_bronze]] — captura de fontes originais
- [[B02_camada_prata]] — pipeline de conversão e .md normalizado
- [[B03_camada_ouro]] — ingestão Neo4j, modelo de dados e busca

### Evolução por Fases (incremental)
- [[B04_metadados_governanca]] — Fase 2: governança e filtragem
- [[B05_knowledge_graph]] — Fase 3: relações e fontes expandidas
- [[B06_graphrag_maturidade]] — Fase 4: maturidade completa

### Consolidação e Planejamento
- [[B07_visao_consolidada]] — evolução por fase
- [[B08_pendencias]] — recomendações e alternativas
- [[B09_referencias]] — referências e histórico
- [[B16_roadmap_implementacao]] — marcos e sequenciamento

### Transversais (todas as fases)
- [[B10_api_interface_acesso]] — API e interface de acesso
- [[B11_deployment_infraestrutura]] — deployment e infraestrutura
- [[B12_testes_validacao_slas]] — testes, validação e SLAs
- [[B13_operacoes]] — operações, backup, ciclo de vida
- [[B14_seguranca_soberania_dados]] — segurança e soberania de dados
- [[B15_governanca_capacidade_rollback]] — governança, capacidade e rollback
