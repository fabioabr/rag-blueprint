---
description: "Questionário de Onboarding — parâmetros corporativos que configuram o pipeline de ingestão de conhecimento"
version: "1.0"
last_updated: "2026-03-22"
---

# Onboarding Information — Parâmetros Corporativos

Este arquivo é preenchido **uma vez por organização** (ou por projeto) antes de iniciar o pipeline de ingestão de conhecimento. Os parâmetros aqui definidos são usados por todas as skills, pelo pipeline-master e pelo auditor de compliance para tomar decisões automatizadas.

> **Regra:** nenhum pipeline deve rodar sem este arquivo preenchido. O pipeline-master valida a existência e completude deste arquivo antes de iniciar qualquer processamento.

---

## 1. Identificação da Organização

```yaml
organizacao:
  nome: ""                          # Ex: "Banco Patria S.A."
  sigla: ""                         # Ex: "BPATRIA"
  setor: ""                         # Ex: "Financeiro", "Saúde", "Varejo", "Governo"
  pais: ""                          # Ex: "Brasil"
  estado: ""                        # Ex: "SP"
```

**Por que importa:** o setor determina quais regulações se aplicam (BACEN para financeiro, ANVISA para saúde, etc.). O país/estado define legislação de dados (LGPD, GDPR).

---

## 2. Regulações Aplicáveis

```yaml
regulacoes:
  lgpd: true                        # Lei Geral de Proteção de Dados (Brasil)
  gdpr: false                       # General Data Protection Regulation (Europa)
  bacen: false                      # Banco Central do Brasil (instituições financeiras)
  cvm: false                        # Comissão de Valores Mobiliários (mercado de capitais)
  sox: false                        # Sarbanes-Oxley (empresas listadas em bolsa US)
  hipaa: false                      # Health Insurance Portability (saúde - EUA)
  pci_dss: false                    # Payment Card Industry (meios de pagamento)
  iso_27001: false                  # Certificação de segurança da informação
  outras: []                        # Lista livre: ["ANPD", "Marco Civil"]
```

**Por que importa:** regulações definem requisitos obrigatórios de anonimização, retenção, auditoria e resposta a incidentes. O auditor de compliance valida documentos contra essas regras.

---

## 3. Política de Dados e Soberania

```yaml
soberania:
  dados_podem_sair_do_dominio: false   # Dados podem ser enviados para APIs cloud?
  trilha_padrao: "on-premises"         # "cloud" | "on-premises" | "hibrida"

  # Se trilha híbrida, definir por nível de confidencialidade:
  trilha_por_confidencialidade:
    public: "cloud"                    # Pode usar APIs cloud
    internal: "cloud"                  # Pode usar APIs cloud
    restricted: "on-premises"          # OBRIGATÓRIO on-premises
    confidential: "on-premises"        # OBRIGATÓRIO on-premises isolado

  residencia_dados: "Brasil"           # Onde os dados devem residir fisicamente
  cloud_providers_aprovados: []        # Ex: ["Azure", "AWS"] — se vazio, nenhum aprovado

  exige_criptografia_em_repouso: true  # Dados armazenados devem estar criptografados?
  exige_criptografia_em_transito: true # Comunicação deve usar TLS?
```

**Por que importa:** determina trilha A/B/híbrida (ADR-002), quais modelos de embedding e LLM usar, e onde a Base Vetorial roda.

---

## 4. Classificação de Dados

```yaml
classificacao:
  niveis_utilizados:                   # Quais níveis de confidencialidade são usados
    - "public"
    - "internal"
    - "restricted"
    - "confidential"

  nivel_padrao: "internal"             # Nível padrão quando não especificado

  # Segregação por KB (ADR-011)
  segregacao_por_kb: true              # Usar KBs separadas por nível?
  kbs:
    - nome: "kb-public-internal"
      niveis: ["public", "internal"]
      trilha: "cloud"                  # ou "on-premises"
    - nome: "kb-restricted"
      niveis: ["restricted"]
      trilha: "on-premises"
    - nome: "kb-confidential"
      niveis: ["confidential"]
      trilha: "on-premises"

  # Regras de classificação automática
  classificacao_automatica: true       # Pipeline pode inferir classificação?
  requer_aprovacao_humana_restricted: true   # Docs classified como restricted precisam de aprovação?
  requer_aprovacao_humana_confidential: true # Docs classified como confidential precisam de aprovação?
```

**Por que importa:** define a estrutura de KBs, MCPs e Bases Vetoriais (ADR-011), e as regras de filtragem pré-retrieval (ADR-004).

---

## 5. SLAs e Tempos de Resposta

```yaml
slas:
  # Rollback urgente (PII/dados sensíveis)
  contencao_horas: 1                   # Tempo máximo para conter o incidente
  remocao_completa_horas: 4            # Tempo máximo para remover dados completamente
  notificacao_compliance_minutos: 30   # Tempo máximo para notificar compliance

  # Comunicação regulatória (se aplicável)
  comunicacao_regulador_horas: 72      # LGPD: 72h para ANPD. Ajustar conforme regulação.

  # Pipeline
  ingestao_max_minutos: 60             # Tempo máximo para ingestão de uma release
  promocao_max_minutos: 30             # Tempo máximo para promoção .beta.md → .md

  # Disponibilidade
  api_uptime_percentual: 99.0          # SLA de uptime da API (%)
  base_vetorial_uptime_percentual: 99.5  # SLA de uptime da Base Vetorial (%)
```

**Por que importa:** o auditor de compliance valida se os procedimentos de rollback atendem aos SLAs. O pipeline-master monitora tempos de execução contra esses limites.

---

## 6. Qualidade e Gates

```yaml
qualidade:
  # Gates de qualidade (ADR-001)
  qa_minimo_para_conversao: 80         # QA score mínimo para converter .txt → .md
  qa_minimo_para_html: 90              # QA score mínimo para gerar HTML
  qa_minimo_para_promocao: 90          # QA score mínimo para promover .beta.md → .md

  # Recall@10 progressivo (ADR-008)
  recall_fase_1: 70                    # Recall@10 mínimo para Fase 1→2
  recall_fase_2: 80                    # Recall@10 mínimo para Fase 2→3
  recall_fase_3: 85                    # Recall@10 mínimo para Fase 3→4

  # Golden set
  golden_set_minimo_perguntas: 20      # Tamanho mínimo do golden set
  golden_set_atualizacao_cadencia: "mensal"  # Com que frequência atualizar

  # Auto-deprecação
  auto_deprecacao_meses: 12            # Meses sem atualização para deprecar
  politica_deprecacao_externa: true    # Usar política externa em vez de auto-deprecação por doc_type?
```

**Por que importa:** o pipeline-master usa esses valores como gates entre etapas. O adr-reviewer valida que as decisões respeitam esses thresholds.

---

## 7. Domínios de Negócio

```yaml
dominios:
  taxonomia:                           # Domínios válidos para o campo 'domain' no front matter
    - "Arquitetura"
    - "Estratégico"
    - "Operacional"
    - "Técnico"
    - "Financeiro"
    - "Comercial"
    - "Regulatório"

  taxonomia_aberta: true               # Permitir domínios fora da lista acima?

  # Mapeamento domínio → responsável padrão
  responsaveis:
    Arquitetura: "time-arquitetura"
    Financeiro: "time-financeiro"
    Regulatório: "time-compliance"
    # Adicionar conforme necessário
```

**Por que importa:** valida o campo `domain` no front matter e define quem é responsável padrão por documentos de cada domínio.

---

## 8. Fontes de Conhecimento

```yaml
fontes:
  # Fontes aprovadas para ingestão (Fase 1 do ADR-001)
  aprovadas:
    - tipo: "git-repo"
      nome: ""                         # Ex: "banco-patria-docs"
      url: ""                          # Ex: "https://github.com/org/repo"
      branch: "main"
      formatos: ["md"]

    - tipo: "sharepoint"
      nome: ""
      url: ""
      formatos: ["docx", "xlsx", "pdf"]

    - tipo: "confluence"
      nome: ""
      url: ""
      formatos: ["html"]

    # Adicionar conforme necessário

  # Fontes explicitamente proibidas
  proibidas:
    - tipo: "email"
      motivo: "LGPD — dados pessoais não anonimizados"

    # Adicionar conforme necessário

  # Formatos aceitos
  formatos_aceitos: ["md", "pdf", "docx", "xlsx", "txt", "json", "html"]

  # Conversion quality mínimo por formato
  conversion_quality_minimo:
    md: 100
    pdf: 70
    docx: 90
    xlsx: 80
    txt: 100
    json: 95
    html: 80
```

**Por que importa:** o pipeline-master valida se as fontes são aprovadas antes de processar. O auditor rejeita documentos de fontes proibidas.

---

## 9. Infraestrutura

```yaml
infraestrutura:
  # Hardware disponível (impacta ADR-009 — modelos de embedding)
  hardware:
    cpu_cores: 0                       # Ex: 16
    ram_gb: 0                          # Ex: 64
    gpu_modelo: ""                     # Ex: "GTX 1070"
    gpu_vram_gb: 0                     # Ex: 8
    disco_ssd_gb: 0                    # Ex: 500

  # Stack definida (ADR-002)
  stack:
    linguagem_pipeline: ""             # Ex: "Python"
    linguagem_api: ""                  # Ex: "Python" ou ".NET"
    framework_embedding: ""            # Ex: "sentence-transformers"
    framework_ingestao: ""             # Ex: "LangChain" ou "neo4j-graphrag-python"

  # Modelos escolhidos
  modelos:
    embedding: ""                      # Ex: "BGE-M3" ou "text-embedding-3-small"
    embedding_dimensoes: 0             # Ex: 1024 ou 1536
    llm: ""                            # Ex: "Llama 3.1 70B" ou "Claude Sonnet"
    reranker: ""                       # Ex: "BGE-Reranker-v2-m3" ou "Cohere Rerank v3"

  # Base Vetorial
  base_vetorial:
    tecnologia: ""                     # Ex: "Neo4j Community", "Neo4j Aura"
    versao: ""                         # Ex: "5.15"
    hospedagem: ""                     # "self-hosted" | "managed-cloud"

  # Ambientes (ADR-010)
  ambientes:
    staging: true
    producao: true
```

**Por que importa:** o pipeline-master ajusta comportamento baseado no hardware (batch size, paralelismo). O ADR-009 usa para validar se o modelo de embedding cabe na GPU.

---

## 10. Equipe e Papéis

```yaml
equipe:
  # Papéis definidos (ADR-008)
  papeis:
    arquiteto:
      responsavel: ""                  # Ex: "fabio.rodrigues"
      email: ""

    curador_conhecimento:
      responsaveis: []                 # Ex: ["maria.silva", "joao.santos"]

    engenheiro_pipeline:
      responsavel: ""

    compliance_officer:
      responsavel: ""
      email: ""                        # Email para notificação de incidentes

    owner_documentos:
      # Mapeamento domínio → owner
      por_dominio:
        Arquitetura: ""
        Financeiro: ""
        # Adicionar conforme necessário

  # Acúmulo de papéis permitido? (Fase 1/MVP)
  permite_acumulo: true
  acumulo_maximo: 3                    # Máximo de papéis por pessoa
```

**Por que importa:** o pipeline-master usa para notificar responsáveis. O ADR-008 define RACI baseado nesses papéis.

---

## 11. Repositórios

```yaml
repositorios:
  # Dois repos (ADR-001)
  workspace:
    nome: ""                           # Ex: "rag-workspace"
    url: ""
    branch_padrao: ""                  # Ex: "release/v1.0.0/main"
    acesso: "read-write"
    responsavel: ""

  knowledge_base:
    nome: ""                           # Ex: "rag-knowledge-base"
    url: ""
    branch_padrao: "main"
    acesso: "pipeline-only"            # Somente service account escreve
    service_account: ""                # Ex: "svc-rag-pipeline"

  # Git Flow (ADR-010)
  git_flow:
    padrao_branch_release: "release/v{MAJOR}.{MINOR}.{PATCH}/main"
    padrao_branch_trabalho: "release/v{MAJOR}.{MINOR}.{PATCH}/{username}/{task}"
    requer_pr_para_merge: true
    aprovadores_minimos: 1             # Mínimo de aprovações no PR
```

**Por que importa:** o pipeline-master usa para localizar arquivos, criar branches e gerar TAGs.

---

## 12. Anonimização e PII

```yaml
anonimizacao:
  # Pipeline de anonimização (ADR-004)
  ativa: true                          # Anonimização automática está ativa?

  # Tipos de PII a detectar
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

  # Ação quando PII detectado
  acao_pii_detectado: "bloquear"       # "bloquear" | "anonimizar" | "alertar"

  # Exceções (campos que contêm PII mas são aceitáveis)
  excecoes:
    - campo: "owner"                   # Owner do documento é PII mas necessário
      motivo: "necessário para governança"
```

**Por que importa:** o auditor de compliance usa para detectar e bloquear documentos com PII não tratado. Define se o pipeline anonimiza automaticamente ou bloqueia para revisão humana.

---

## 13. Observabilidade e Alertas

```yaml
observabilidade:
  # Canais de notificação
  canal_alertas: ""                    # Ex: "slack", "email", "teams"
  canal_url: ""                        # Ex: webhook URL do Slack

  # Quem recebe alertas
  alertas_criticos:                    # PII, rollback urgente
    destinatarios: []                  # Ex: ["compliance@empresa.com"]

  alertas_operacionais:                # Falha de pipeline, QA baixo
    destinatarios: []

  alertas_informativos:                # Release concluída, métricas
    destinatarios: []

  # Logs
  logs:
    formato: "json"                    # "json" | "texto"
    retencao_dias: 90                  # Quanto tempo manter logs
    nivel_padrao: "info"               # "debug" | "info" | "warning" | "error"
```

**Por que importa:** o pipeline-master usa para enviar notificações. O auditor alerta sobre violações.

---

## 14. Checklist de Validação do Onboarding

Antes de iniciar o pipeline, verificar que TODOS os itens obrigatórios estão preenchidos:

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
    - "repositorios.workspace.nome"
    - "repositorios.knowledge_base.nome"
    - "equipe.papeis.arquiteto.responsavel"
    - "anonimizacao.acao_pii_detectado"
```

**Pipeline-master NÃO inicia sem esses campos preenchidos.**
