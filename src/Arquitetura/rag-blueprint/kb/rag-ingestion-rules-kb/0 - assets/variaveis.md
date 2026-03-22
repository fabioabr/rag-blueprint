---
description: "Variáveis globais para geração de documentos e apresentações HTML"
---

# Variáveis Globais

Dados centralizados usados pelas skills de geração (prs-writer, doc-writer, adr-writer, etc.).
Toda skill que gera output final (.md ou .html) DEVE ler este arquivo e substituir as variáveis correspondentes.

## Empresa

| Variável | Valor |
|----------|-------|
| `{{EMPRESA}}` | Empresa XPTO |
| `{{EMPRESA_SIGLA}}` | XPTO |
| `{{AREA}}` | Arquitetura e Produtividade Corporativa |
| `{{TEAM}}` | Arquitetura |

## Autor / Responsável

| Variável | Valor |
|----------|-------|
| `{{AUTOR_NOME}}` | Fabio A. B. Rodrigues |
| `{{AUTOR_INICIAIS}}` | FR |
| `{{AUTOR_CARGO}}` | Arquitetura e Produtividade Corporativa |
| `{{AUTOR_EMAIL}}` | fabio.rodrigues@bancopatria.com.br |

## Repositório

| Variável | Valor |
|----------|-------|
| `{{REPO_NOME}}` | Rag |
| `{{REPO_PROJETO}}` | RAG Corporativo |
| `{{REPO_SERIE}}` | RAG Blueprint Series |

## Logos (HTML)

| Variável | Valor |
|----------|-------|
| `{{LOGO_DARK_BASE64}}` | conteúdo de `0 - assets/logo-dark-base64.txt` |
| `{{LOGO_LIGHT_BASE64}}` | conteúdo de `0 - assets/logo-light-base64.txt` |

> **Implementação no HTML:** dois `<img>` com classes `.logo-dark` e `.logo-light`. O toggle de tema alterna a visibilidade via CSS. Tema escuro mostra `.logo-dark`, tema claro mostra `.logo-light`.

## Footer (HTML)

| Variável | Valor |
|----------|-------|
| `{{FOOTER_TEXTO}}` | {{EMPRESA}} · {{AREA}} |
| `{{FOOTER_AUTOR}}` | {{AUTOR_NOME}} |
| `{{FOOTER_CARGO}}` | {{AUTOR_CARGO}} |
| `{{FOOTER_SELO}}` | Criado por |
