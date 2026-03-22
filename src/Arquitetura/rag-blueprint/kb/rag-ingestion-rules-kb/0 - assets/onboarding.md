---
description: "Onboarding — Parâmetros do projeto RAG Ingestion Rules KB"
version: "1.0"
last_updated: "2026-03-22"
---

# Onboarding Information — RAG Ingestion Rules KB

Parâmetros corporativos para o contexto de **regras e definições do processo de ingestão RAG**.

---

## 1. Identificação da Organização

```yaml
organizacao:
  nome: "Empresa XPTO"
  sigla: "XPTO"
  setor: "Financeiro"
  pais: "Brasil"
  estado: "SP"
```

---

## 2. Regulações Aplicáveis

```yaml
regulacoes:
  lgpd: true
  gdpr: false
  bacen: true
  cvm: true
  sox: false
  hipaa: false
  pci_dss: false
  iso_27001: false
  outras: []
```

---

## 3. Política de Dados e Soberania

```yaml
soberania:
  dados_podem_sair_do_dominio: false
  trilha_padrao: "on-premises"

  trilha_por_confidencialidade:
    public: "on-premises"
    internal: "on-premises"
    restricted: "on-premises"
    confidential: "on-premises"

  residencia_dados: "Brasil"
  cloud_providers_aprovados: []

  exige_criptografia_em_repouso: true
  exige_criptografia_em_transito: true
```

---

## 4. Classificação de Dados

```yaml
classificacao:
  niveis_utilizados:
    - "public"
    - "internal"
    - "restricted"
    - "confidential"

  nivel_padrao: "internal"

  segregacao_por_kb: true
  kbs:
    - nome: "kb-public-internal"
      niveis: ["public", "internal"]
      trilha: "on-premises"
    - nome: "kb-restricted"
      niveis: ["restricted"]
      trilha: "on-premises"
    - nome: "kb-confidential"
      niveis: ["confidential"]
      trilha: "on-premises"

  classificacao_automatica: true
  requer_aprovacao_humana_restricted: true
  requer_aprovacao_humana_confidential: true
```

---

## 5. SLAs e Tempos de Resposta

```yaml
slas:
  contencao_horas: 1
  remocao_completa_horas: 4
  notificacao_compliance_minutos: 30
  comunicacao_regulador_horas: 72

  ingestao_max_minutos: 60
  promocao_max_minutos: 30

  api_uptime_percentual: 99.0
  base_vetorial_uptime_percentual: 99.5
```

---

## 6. Qualidade e Gates

```yaml
qualidade:
  qa_minimo_para_conversao: 80
  qa_minimo_para_html: 90
  qa_minimo_para_promocao: 90

  recall_fase_1: 70
  recall_fase_2: 80
  recall_fase_3: 85

  golden_set_minimo_perguntas: 20
  golden_set_atualizacao_cadencia: "mensal"

  auto_deprecacao_meses: 12
  politica_deprecacao_externa: true
```

---

## 7. Domínios de Negócio

```yaml
dominios:
  taxonomia:
    - "Arquitetura"
    - "Estratégico"
    - "Operacional"
    - "Técnico"
    - "Financeiro"
    - "Comercial"
    - "Regulatório"

  taxonomia_aberta: true

  responsaveis:
    Arquitetura: "time-arquitetura"
    Financeiro: "time-financeiro"
    Regulatório: "time-compliance"
```

---

## 8. Fontes de Conhecimento

```yaml
fontes:
  aprovadas:
    - tipo: "git-repo"
      nome: "rag-blueprint"
      url: ""
      branch: "main"
      formatos: ["md", "txt"]

  proibidas: []

  formatos_aceitos: ["md", "pdf", "docx", "xlsx", "txt", "json", "html"]

  conversion_quality_minimo:
    md: 100
    pdf: 70
    docx: 90
    xlsx: 80
    txt: 100
    json: 95
    html: 80
```

---

## 9. Infraestrutura

```yaml
infraestrutura:
  hardware:
    cpu_cores: 16
    ram_gb: 64
    gpu_modelo: "GTX 1070"
    gpu_vram_gb: 8
    disco_ssd_gb: 500

  stack:
    linguagem_pipeline: "Python"
    linguagem_api: ""
    framework_embedding: "sentence-transformers"
    framework_ingestao: ""

  modelos:
    embedding: "BGE-M3"
    embedding_dimensoes: 1024
    llm: ""
    reranker: "BGE-Reranker-v2-m3"

  base_vetorial:
    tecnologia: ""
    versao: ""
    hospedagem: "self-hosted"

  ambientes:
    staging: true
    producao: true
```

---

## 10. Equipe e Papéis

```yaml
equipe:
  papeis:
    arquiteto:
      responsavel: "fabio.rodrigues"
      email: "fabio.rodrigues@bancopatria.com.br"

    curador_conhecimento:
      responsaveis: []

    engenheiro_pipeline:
      responsavel: ""

    compliance_officer:
      responsavel: ""
      email: ""

    owner_documentos:
      por_dominio:
        Arquitetura: "fabio.rodrigues"

  permite_acumulo: true
  acumulo_maximo: 3
```

---

## 11. Repositórios

```yaml
repositorios:
  workspace:
    nome: ""
    url: ""
    branch_padrao: ""
    acesso: "read-write"
    responsavel: "fabio.rodrigues"

  knowledge_base:
    nome: ""
    url: ""
    branch_padrao: "main"
    acesso: "pipeline-only"
    service_account: ""

  git_flow:
    padrao_branch_release: "release/v{MAJOR}.{MINOR}.{PATCH}/main"
    padrao_branch_trabalho: "release/v{MAJOR}.{MINOR}.{PATCH}/{username}/{task}"
    requer_pr_para_merge: true
    aprovadores_minimos: 1
```

---

## 12. Anonimização e PII

```yaml
anonimizacao:
  ativa: true

  pii_tipos:
    - "cpf"
    - "rg"
    - "nome_completo"
    - "email_pessoal"
    - "telefone"
    - "endereco"
    - "dados_bancarios"
    - "salario"
    - "data_nascimento"

  acao_pii_detectado: "bloquear"

  excecoes:
    - campo: "owner"
      motivo: "necessário para governança"
```

---

## 13. Observabilidade e Alertas

```yaml
observabilidade:
  canal_alertas: ""
  canal_url: ""

  alertas_criticos:
    destinatarios: []

  alertas_operacionais:
    destinatarios: []

  alertas_informativos:
    destinatarios: []

  logs:
    formato: "json"
    retencao_dias: 90
    nivel_padrao: "info"
```

---

## 14. Checklist de Validação

```yaml
validacao:
  campos_obrigatorios:
    - "organizacao.nome"
    - "organizacao.setor"
    - "soberania.trilha_padrao"
    - "classificacao.nivel_padrao"
    - "slas.contencao_horas"
    - "slas.remocao_completa_horas"
    - "qualidade.qa_minimo_para_conversao"
    - "qualidade.qa_minimo_para_html"
    - "qualidade.qa_minimo_para_promocao"
    - "infraestrutura.hardware.ram_gb"
    - "infraestrutura.modelos.embedding"
    - "equipe.papeis.arquiteto.responsavel"
    - "anonimizacao.acao_pii_detectado"
```
