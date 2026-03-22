# 📚 Guia de Escrita de Documentos Markdown para Obsidian (KB para Agentes de IA)

## 🎯 Objetivo

Este documento define as regras e padrões para criação de arquivos `.md` no Obsidian, com foco em:

- Estruturação de conhecimento interligado (grafo)
- Facilidade de navegação e manutenção
- Compatibilidade com agentes de IA (RAG, MCP, vetorização)
- Consistência semântica e estrutural

---

# 🧠 Princípios Fundamentais

## 1. Atomicidade (Regra Crítica)

Cada arquivo deve conter **apenas um conceito principal**.

## 2. Nomeação Padronizada

- Sempre usar lowercase
- Separar palavras com `_` (underscore)
- Nome deve representar claramente o conceito

## 3. Tudo deve ser linkável

Sempre que um conceito aparecer, ele deve ser referenciado com [[link]]

---

# 🔗 Regras de Linking

## Link básico
[[nome-do-arquivo]]

## Link com alias
[[bigquery|Camada Analítica]]

## Link para seção
[[bigquery#segurança]]

## Link para bloco
Processo crítico ^id
[[bigquery#^id]]

---

# 🧩 Estrutura de Documento

# Título

## 📌 Definição
## 🧠 Contexto
## 🔗 Relacionamentos
## ⚙️ Detalhamento
## 🔒 Considerações
## 📎 Referências internas

---

# 🧠 Estratégia para IA

- Alta densidade de links
- Baixa ambiguidade
- Estrutura previsível
- Documentos pequenos e conectados

---

# ⚠️ Anti-Padrões

- Arquivos genéricos
- Conteúdo misto
- Falta de links
- Texto sem estrutura

---

# 🚀 Direcionamento Final

1. Criar arquivos atômicos
2. Garantir links bidirecionais
3. Seguir padrão
4. Criar novos docs quando necessário
5. Nunca deixar termos sem link

---

# 📌 Resultado Esperado

Base de conhecimento:
- Navegável
- Semântica
- Compatível com IA
