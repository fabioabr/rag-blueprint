---
description: "Mapeamento de heranca de assets — define quais assets cada pasta sob src/ utiliza"
version: "1.0"
last_updated: "2026-03-23"
---

# Assets — Mapeamento de Heranca

## Regra Geral

Toda pasta sob `src/` herda automaticamente os assets de `src/assets/main/`.
Isso significa que, salvo definicao explicita abaixo, qualquer skill ou processo
que precise de logos, variaveis ou onboarding deve buscar em `main/`.

## Estrutura de main/

```
src/assets/main/
├── logos/
│   ├── logo.png                  # Logo principal (PNG original)
│   ├── logo-dark-base64.txt      # Logo dark em base64 (para HTML inline)
│   └── logo-light-base64.txt     # Logo light em base64 (para HTML inline)
├── variaveis.md                  # Variaveis globais (empresa, autor, repo, footer)
└── onboarding.md                 # Parametros do projeto (regulacoes, SLAs, infra, equipe)
```

## Mapeamento por Pasta

| Pasta                          | Asset Set | Observacao                              |
|--------------------------------|-----------|-----------------------------------------|
| `src/kb/*`                     | `main`    | Todas as KBs herdam de main             |
| `src/pendings/*`               | `main`    | Planos e pendencias herdam de main      |
| `src/diagrams/*`               | `main`    | Diagramas herdam de main                |
| `src/.claude/*`                | `main`    | Behavior e skills herdam de main        |

## Como Adicionar Overrides (futuro)

Caso uma KB ou contexto precise de assets customizados (ex: logo diferente,
variaveis especificas), criar uma subpasta em `src/assets/` com o nome do contexto:

```
src/assets/
├── main/                        # padrao (herdado por todos)
├── rag-blueprint-adrs/          # override para esta KB (exemplo futuro)
│   └── variaveis.md             # sobrescreve apenas variaveis.md
└── mapping.md                   # atualizar este arquivo com o novo mapeamento
```

Regra de resolucao:
1. Buscar primeiro no asset set especifico (se mapeado)
2. Se nao encontrar, cair para `main/`
3. `main/` e sempre o fallback

## Quem Consome

- Skills de geracao: `/prs-writer`, `/doc-writer`, `/adr-writer`, `/rnb-writer`, `/gls-writer`
- Skills de revisao: `/drf-reviewer`, `/adr-reviewer`, `/compliance-auditor`
- Templates HTML: leem logos e variaveis para gerar HTML standalone
- Pipeline master: `/pipeline-master` resolve os paths via este mapeamento
