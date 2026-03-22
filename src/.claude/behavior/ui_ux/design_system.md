---
id: DOC-000002
doc_type: architecture-doc
title: Design System — Banco Patria
system: Todos
module: UI
domain: Design
owner: fabio
team: arquitetura
status: approved
confidentiality: internal
tags: [design-system, cores, tipografia, componentes, ui, ux]
created_at: 2026-03-17
updated_at: 2026-03-17
---

# Design System — Banco Patria

Este documento define os padrões visuais e de interface para todos os produtos e aplicações do Banco Patria. Serve como referência única para garantir consistência visual entre equipes e projetos.

---

## 1. Paleta de Cores

### 1.1 Cores Primárias (Brand)

| Nome         | Hex       | RGB              | Uso principal                                |
|--------------|-----------|------------------|----------------------------------------------|
| Dark Blue    | `#023E8A` | `2, 62, 138`     | Cor principal da marca, headers, CTAs primários |
| Ocean Blue   | `#0077B6` | `0, 119, 182`    | Elementos interativos, links, botões secundários |
| Soft Cyan    | `#90E0EF` | `144, 224, 239`  | Destaques, badges, indicadores visuais       |
| Pale Blue    | `#CAF0F8` | `202, 240, 248`  | Backgrounds, cards, áreas de conteúdo        |

### 1.2 Cores Neutras

| Nome           | Hex       | RGB              | Uso principal                          |
|----------------|-----------|------------------|----------------------------------------|
| Black          | `#0A0A0A` | `10, 10, 10`     | Texto principal                        |
| Dark Gray      | `#333333` | `51, 51, 51`     | Texto secundário, subtítulos           |
| Medium Gray    | `#666666` | `102, 102, 102`  | Texto auxiliar, placeholders           |
| Light Gray     | `#E0E0E0` | `224, 224, 224`  | Bordas, divisores                      |
| Off White      | `#F5F5F5` | `245, 245, 245`  | Background geral                       |
| White          | `#FFFFFF` | `255, 255, 255`  | Background de cards, superfícies       |

### 1.3 Cores Semânticas

| Nome    | Hex       | Uso                                  |
|---------|-----------|--------------------------------------|
| Success | `#2E7D32` | Confirmações, status positivo        |
| Warning | `#F9A825` | Alertas, ações que requerem atenção  |
| Error   | `#C62828` | Erros, validações negativas          |
| Info    | `#0077B6` | Informações, dicas (usa Ocean Blue)  |

### 1.4 Variações de Opacidade (Dark Blue)

Para overlays, estados hover e superfícies com transparência:

| Variação   | Valor                    | Uso                        |
|------------|--------------------------|----------------------------|
| 80%        | `rgba(2, 62, 138, 0.8)` | Overlays modais            |
| 60%        | `rgba(2, 62, 138, 0.6)` | Backgrounds sobrepostos    |
| 20%        | `rgba(2, 62, 138, 0.2)` | Hover em linhas de tabela  |
| 10%        | `rgba(2, 62, 138, 0.1)` | Backgrounds sutis          |

---

## 2. Tipografia

### 2.1 Família Tipográfica

| Contexto    | Família               | Fallback                    |
|-------------|-----------------------|-----------------------------|
| Interface   | **Inter**             | `system-ui, sans-serif`     |
| Código      | **JetBrains Mono**    | `monospace`                 |
| Documentos  | **Inter**             | `system-ui, sans-serif`     |

### 2.2 Escala Tipográfica

| Elemento     | Tamanho  | Peso       | Line Height | Uso                         |
|--------------|----------|------------|-------------|-----------------------------|
| Display      | `36px`   | Bold (700) | `1.2`       | Títulos de página           |
| H1           | `28px`   | Bold (700) | `1.3`       | Títulos de seção            |
| H2           | `22px`   | Semi (600) | `1.3`       | Subtítulos                  |
| H3           | `18px`   | Semi (600) | `1.4`       | Títulos de card/bloco       |
| Body         | `16px`   | Regular (400) | `1.5`    | Texto principal             |
| Body Small   | `14px`   | Regular (400) | `1.5`    | Texto secundário            |
| Caption      | `12px`   | Regular (400) | `1.4`    | Labels, timestamps, helpers |
| Code         | `14px`   | Regular (400) | `1.6`    | Blocos de código            |

---

## 3. Espaçamento

Base de espaçamento: **4px**

| Token  | Valor   | Uso                                 |
|--------|---------|-------------------------------------|
| `xs`   | `4px`   | Espaço mínimo entre ícone e texto   |
| `sm`   | `8px`   | Padding interno de badges           |
| `md`   | `16px`  | Padding de inputs, gaps de grid     |
| `lg`   | `24px`  | Padding de cards, margem entre seções |
| `xl`   | `32px`  | Separação entre blocos              |
| `2xl`  | `48px`  | Margem de seções principais         |
| `3xl`  | `64px`  | Margem de topo/base de página       |

---

## 4. Bordas e Sombras

### 4.1 Border Radius

| Token     | Valor   | Uso                        |
|-----------|---------|----------------------------|
| `none`    | `0px`   | Tabelas, elementos retos   |
| `sm`      | `4px`   | Inputs, badges             |
| `md`      | `8px`   | Cards, modais              |
| `lg`      | `12px`  | Cards destacados           |
| `full`    | `9999px`| Avatares, pills            |

### 4.2 Sombras (Elevation)

| Nível | Valor                                        | Uso                       |
|-------|----------------------------------------------|---------------------------|
| 0     | `none`                                       | Elementos inline          |
| 1     | `0 1px 3px rgba(0,0,0,0.08)`                | Cards padrão              |
| 2     | `0 4px 12px rgba(0,0,0,0.12)`               | Cards elevados, dropdowns |
| 3     | `0 8px 24px rgba(0,0,0,0.16)`               | Modais, popovers          |

---

## 5. Componentes Base

### 5.1 Botões

| Variante    | Background    | Texto         | Borda          | Uso                    |
|-------------|---------------|---------------|----------------|------------------------|
| Primary     | `#023E8A`     | `#FFFFFF`     | —              | Ação principal         |
| Secondary   | `#FFFFFF`     | `#023E8A`     | `1px #023E8A`  | Ação secundária        |
| Ghost       | `transparent` | `#0077B6`     | —              | Ação terciária/links   |
| Danger      | `#C62828`     | `#FFFFFF`     | —              | Ações destrutivas      |
| Disabled    | `#E0E0E0`     | `#666666`     | —              | Estado desabilitado    |

**Estados:**
- **Hover (Primary):** `#012F6B` (Dark Blue escurecido ~15%)
- **Active (Primary):** `#012259` (Dark Blue escurecido ~25%)
- **Focus:** ring de `2px` com `#90E0EF` e offset de `2px`

**Tamanhos:**

| Tamanho | Padding           | Font Size | Height |
|---------|--------------------|-----------|--------|
| Small   | `8px 16px`         | `14px`    | `32px` |
| Medium  | `10px 24px`        | `16px`    | `40px` |
| Large   | `12px 32px`        | `16px`    | `48px` |

### 5.2 Inputs

| Estado      | Borda         | Background  | Observação                |
|-------------|---------------|-------------|---------------------------|
| Default     | `1px #E0E0E0` | `#FFFFFF`   | —                         |
| Focus       | `2px #0077B6` | `#FFFFFF`   | Ring com Soft Cyan        |
| Error       | `2px #C62828` | `#FFFFFF`   | Mensagem de erro abaixo   |
| Disabled    | `1px #E0E0E0` | `#F5F5F5`   | Cursor not-allowed        |

- Border radius: `sm` (4px)
- Padding: `10px 12px`
- Font size: `16px`
- Placeholder color: `#666666`

### 5.3 Cards

- Background: `#FFFFFF`
- Border: `1px solid #E0E0E0`
- Border radius: `md` (8px)
- Padding: `lg` (24px)
- Sombra: nível 1
- **Hover (se clicável):** sombra nível 2, borda `#0077B6`

### 5.4 Badges / Tags

| Variante   | Background    | Texto       | Uso                     |
|------------|---------------|-------------|-------------------------|
| Default    | `#CAF0F8`     | `#023E8A`   | Tags genéricas          |
| Info       | `#CAF0F8`     | `#0077B6`   | Status informativo      |
| Success    | `#E8F5E9`     | `#2E7D32`   | Status positivo         |
| Warning    | `#FFF8E1`     | `#F57F17`   | Alerta                  |
| Error      | `#FFEBEE`     | `#C62828`   | Erro / crítico          |

- Border radius: `sm` (4px)
- Padding: `4px 8px`
- Font size: `12px` / Semi-bold (600)

### 5.5 Tabelas

- Header background: `#023E8A`
- Header texto: `#FFFFFF`
- Linhas alternadas: `#FFFFFF` / `#CAF0F8`
- Hover na linha: `rgba(2, 62, 138, 0.1)`
- Borda: `1px solid #E0E0E0`
- Padding de célula: `12px 16px`

### 5.6 Navegação / Sidebar

- Background: `#023E8A`
- Texto: `#FFFFFF`
- Item ativo: background `#0077B6`, borda esquerda `3px #90E0EF`
- Hover: `rgba(255, 255, 255, 0.1)`
- Ícones: `#90E0EF` (ativos) / `rgba(255, 255, 255, 0.7)` (inativos)

---

## 6. Ícones

- Biblioteca recomendada: **Lucide Icons** (ou Phosphor Icons)
- Tamanhos: `16px` (inline), `20px` (padrão), `24px` (destaque)
- Stroke width: `1.5px`
- Cor padrão: herda do texto (`currentColor`)

---

## 7. Responsividade

### Breakpoints

| Nome   | Largura mínima | Uso                          |
|--------|----------------|------------------------------|
| `sm`   | `640px`        | Mobile landscape             |
| `md`   | `768px`        | Tablet                       |
| `lg`   | `1024px`       | Desktop                      |
| `xl`   | `1280px`       | Desktop wide                 |
| `2xl`  | `1536px`       | Monitores grandes            |

### Grid

- Colunas: 12
- Gutter: `16px` (mobile) / `24px` (desktop)
- Margem lateral: `16px` (mobile) / `32px` (tablet) / `auto` com max-width (desktop)
- Max-width do conteúdo: `1280px`

---

## 8. Acessibilidade

- Contraste mínimo de texto: **4.5:1** (WCAG AA)
- Contraste de elementos interativos: **3:1**
- Todos os elementos interativos devem ter estado de foco visível
- Nunca usar cor como único indicador de estado
- Tamanho mínimo de área clicável: `44x44px`

### Verificação de Contraste das Cores Primárias

| Combinação                        | Ratio  | WCAG AA |
|-----------------------------------|--------|---------|
| Dark Blue `#023E8A` sobre White   | ~8.5:1 | Pass    |
| Ocean Blue `#0077B6` sobre White  | ~4.6:1 | Pass    |
| Black `#0A0A0A` sobre Pale Blue   | ~17:1  | Pass    |
| Dark Blue `#023E8A` sobre Pale Blue | ~7:1 | Pass   |

---

## 9. Tokens CSS (Referência Rápida)

```css
:root {
  /* Cores primárias */
  --color-primary-dark:    #023E8A;
  --color-primary:         #0077B6;
  --color-primary-light:   #90E0EF;
  --color-primary-lighter: #CAF0F8;

  /* Neutras */
  --color-black:       #0A0A0A;
  --color-gray-900:    #333333;
  --color-gray-600:    #666666;
  --color-gray-200:    #E0E0E0;
  --color-gray-100:    #F5F5F5;
  --color-white:       #FFFFFF;

  /* Semânticas */
  --color-success: #2E7D32;
  --color-warning: #F9A825;
  --color-error:   #C62828;
  --color-info:    #0077B6;

  /* Tipografia */
  --font-family:      'Inter', system-ui, sans-serif;
  --font-family-mono: 'JetBrains Mono', monospace;

  /* Espaçamento */
  --space-xs:  4px;
  --space-sm:  8px;
  --space-md:  16px;
  --space-lg:  24px;
  --space-xl:  32px;
  --space-2xl: 48px;
  --space-3xl: 64px;

  /* Border radius */
  --radius-sm:   4px;
  --radius-md:   8px;
  --radius-lg:   12px;
  --radius-full: 9999px;

  /* Sombras */
  --shadow-1: 0 1px 3px rgba(0,0,0,0.08);
  --shadow-2: 0 4px 12px rgba(0,0,0,0.12);
  --shadow-3: 0 8px 24px rgba(0,0,0,0.16);
}
```

---

## 10. Princípios de Design

1. **Clareza** — Interfaces devem comunicar com precisão. Priorizar legibilidade e hierarquia visual.
2. **Consistência** — Usar os mesmos padrões em todos os produtos. Componentes reutilizáveis, tokens centralizados.
3. **Confiança** — O visual deve transmitir solidez e segurança, adequado ao contexto bancário.
4. **Acessibilidade** — Design inclusivo como requisito, não como exceção.
5. **Simplicidade** — Menos é mais. Reduzir ruído visual e focar no que importa.

---

## 11. Diretrizes para Geração de Materiais

### 11.1 Tom Visual da Marca

O Banco Patria posiciona-se como uma instituição **sólida, moderna e confiável**. Todo material gerado deve refletir:

- **Sobriedade** — evitar cores vibrantes fora da paleta, animações excessivas ou elementos decorativos sem função
- **Profissionalismo** — linguagem visual limpa, alinhamentos rígidos, espaço em branco generoso
- **Modernidade** — formas limpas, ícones lineares, tipografia sans-serif, flat design com elevação sutil
- **Identidade azul** — o azul é a cor dominante em toda comunicação; outros matizes aparecem apenas como apoio semântico

### 11.2 Hierarquia de Aplicação de Cores

Ao gerar qualquer material visual, seguir esta proporção:

| Cor             | Proporção aproximada | Onde aplicar                                      |
|-----------------|----------------------|---------------------------------------------------|
| White / Off White | ~50-60%            | Fundo principal, áreas de respiro                 |
| Dark Blue       | ~15-20%              | Header, navbar, CTAs, títulos de destaque         |
| Ocean Blue      | ~10-15%              | Links, botões secundários, ícones ativos          |
| Pale Blue       | ~10-15%              | Cards, backgrounds de seção, áreas de conteúdo    |
| Soft Cyan       | ~5%                  | Acentos, badges, indicadores, detalhes decorativos|

**Regra geral:** fundo claro + elementos estruturais escuros + acentos em cyan. Nunca usar Soft Cyan ou Pale Blue como cor de texto.

### 11.3 Apresentações (Slides / Decks)

**Layout padrão de slide:**
- Fundo: `#FFFFFF` ou `#F5F5F5`
- Barra superior ou lateral: `#023E8A` (Dark Blue) com altura/largura de `60-80px`
- Título do slide: `#023E8A`, tamanho `28-36px`, Bold
- Subtítulo: `#0077B6`, tamanho `18-22px`, Semi-bold
- Corpo de texto: `#333333`, tamanho `16-18px`, Regular
- Rodapé: `#666666`, tamanho `12px`, com nome do documento e numeração

**Slide de capa:**
- Fundo: gradiente de `#023E8A` → `#0077B6` (diagonal ou horizontal)
- Título: `#FFFFFF`, Bold, tamanho `40-48px`
- Subtítulo/data: `#CAF0F8`, tamanho `20px`
- Logo ou nome da instituição: canto inferior direito, `#FFFFFF`

**Slide de seção/divisória:**
- Fundo: `#023E8A` sólido
- Título da seção: `#FFFFFF`, centralizado, Bold, `36px`
- Linha decorativa: `#90E0EF`, `3px` de espessura, abaixo do título

**Elementos visuais em slides:**
- Gráficos: usar a paleta primária na ordem Dark Blue → Ocean Blue → Soft Cyan → Pale Blue
- Ícones: `#FFFFFF` sobre fundo escuro ou `#023E8A` sobre fundo claro
- Destaques/callouts: fundo `#CAF0F8` com borda esquerda `4px #0077B6`
- Tabelas: seguir padrão da seção 5.5

### 11.4 Documentos e Relatórios (PDF / Word / Markdown)

**Estrutura visual:**
- Capa: fundo `#023E8A`, título `#FFFFFF`, dados complementares em `#CAF0F8`
- Header de página: linha fina `1px #023E8A` com nome do documento à esquerda e data à direita, `12px`, `#666666`
- Footer: numeração centralizada, `12px`, `#666666`
- Títulos H1: `#023E8A`, `24px`, Bold, com `border-bottom: 2px solid #0077B6`
- Títulos H2: `#0077B6`, `20px`, Semi-bold
- Títulos H3: `#333333`, `16px`, Semi-bold
- Corpo: `#333333`, `14px`, line-height `1.6`
- Links: `#0077B6`, underline

**Blocos especiais:**
- Nota/Info: fundo `#CAF0F8`, borda esquerda `4px #0077B6`, padding `16px`
- Alerta: fundo `#FFF8E1`, borda esquerda `4px #F9A825`
- Erro/Crítico: fundo `#FFEBEE`, borda esquerda `4px #C62828`
- Sucesso: fundo `#E8F5E9`, borda esquerda `4px #2E7D32`
- Citação/Destaque: fundo `#F5F5F5`, borda esquerda `4px #023E8A`, itálico

### 11.5 Dashboards e Interfaces de Dados

**Layout geral:**
- Background da página: `#F5F5F5`
- Sidebar: `#023E8A` (ver seção 5.6)
- Top bar: `#FFFFFF` com sombra nível 1
- Área de conteúdo: grid de cards sobre fundo `#F5F5F5`

**KPI Cards:**
- Fundo: `#FFFFFF`, sombra nível 1, border-radius `md`
- Label: `#666666`, `12px`, uppercase, letter-spacing `0.5px`
- Valor: `#0A0A0A`, `28-36px`, Bold
- Variação positiva: `#2E7D32` com seta ↑
- Variação negativa: `#C62828` com seta ↓
- Ícone decorativo: `#90E0EF`, `24px`, canto superior direito

**Gráficos e Visualizações:**
- Paleta sequencial (do mais importante ao menos): `#023E8A` → `#0077B6` → `#90E0EF` → `#CAF0F8`
- Para mais de 4 séries, intercalar com neutras: `#333333`, `#666666`
- Grid lines: `#E0E0E0`, `1px`, tracejado
- Labels de eixo: `#666666`, `12px`
- Tooltips: fundo `#0A0A0A` com `90%` opacidade, texto `#FFFFFF`, border-radius `sm`
- Legenda: posicionada abaixo do gráfico, `14px`, `#333333`

**Tabelas de dados:**
- Seguir padrão da seção 5.5
- Ações inline: ícones em `#0077B6`, hover em `#023E8A`
- Status cells: usar badges da seção 5.4
- Linhas selecionadas: fundo `rgba(2, 62, 138, 0.1)`, borda esquerda `3px #0077B6`

### 11.6 E-mails e Comunicações

**Template de e-mail:**
- Largura máxima: `600px`, centralizado
- Header: fundo `#023E8A`, altura `80px`, logo/nome em `#FFFFFF`
- Corpo: fundo `#FFFFFF`, padding `32px`, texto `#333333`, `16px`
- CTA principal: botão `#023E8A` com texto `#FFFFFF`, border-radius `sm`, padding `12px 32px`
- CTA secundário: texto `#0077B6`, underline
- Divisor: `1px solid #E0E0E0`, margem `24px 0`
- Footer: fundo `#F5F5F5`, texto `#666666`, `12px`, links em `#0077B6`

### 11.7 Diagramas e Fluxogramas

**Nós/Caixas:**
- Processo: fundo `#FFFFFF`, borda `2px #023E8A`, border-radius `md`, texto `#333333`
- Decisão (losango): fundo `#CAF0F8`, borda `2px #0077B6`, texto `#023E8A`
- Início/Fim: fundo `#023E8A`, texto `#FFFFFF`, border-radius `full`
- Subprocesso: fundo `#F5F5F5`, borda `1px #E0E0E0`, texto `#333333`
- Ação externa: fundo `#FFFFFF`, borda `2px tracejada #0077B6`

**Conectores:**
- Setas: `#333333`, espessura `1.5px`, ponta preenchida
- Labels de conector: `#666666`, `12px`, fundo `#FFFFFF` com padding `2px 6px`

**Swimlanes:**
- Header da lane: fundo `#023E8A`, texto `#FFFFFF`, `14px` Bold
- Fundo alternado entre lanes: `#FFFFFF` / `#CAF0F8`
- Separadores: `1px solid #E0E0E0`

### 11.8 Formulários e Interfaces de Entrada

**Layout de formulário:**
- Max-width: `560px` para formulários simples, `800px` para formulários complexos (multi-coluna)
- Agrupamento: seções com título H3 (`#023E8A`) e separador `1px #E0E0E0`
- Labels: `#333333`, `14px`, Semi-bold, posicionados acima do input
- Helper text: `#666666`, `12px`, abaixo do input
- Campos obrigatórios: asterisco `*` em `#C62828`
- Espaço entre campos: `lg` (24px)
- Espaço entre seções: `xl` (32px)

**Ações de formulário:**
- Botão principal (submit): alinhado à direita, variante Primary
- Botão secundário (cancelar): à esquerda do principal, variante Ghost
- Espaço entre botões: `md` (16px)

### 11.9 Estados Vazios e Feedback

**Empty states:**
- Ícone ilustrativo: `48px`, cor `#90E0EF`
- Título: `#333333`, `18px`, Semi-bold
- Descrição: `#666666`, `14px`, max-width `400px`, centralizado
- CTA (se houver): botão Secondary

**Loading:**
- Spinner/skeleton: cor `#90E0EF` sobre fundo `#E0E0E0`
- Skeleton blocks: border-radius `sm`, animação pulse

**Notificações toast:**
- Posição: canto superior direito, `16px` de margem
- Largura: `360px`
- Border-radius: `md`
- Sombra: nível 2
- Borda esquerda: `4px` na cor semântica correspondente
- Auto-dismiss: 5 segundos (com opção de fechar)

### 11.10 Modo Escuro (Dark Mode)

Mapeamento de cores para dark mode, quando aplicável:

| Token Light          | Token Dark           | Hex Dark    |
|----------------------|----------------------|-------------|
| White (background)   | Dark Surface         | `#121212`   |
| Off White            | Dark Surface Alt     | `#1E1E1E`   |
| Black (texto)        | White (texto)        | `#FFFFFF`   |
| Dark Gray            | Light Gray           | `#E0E0E0`   |
| Medium Gray          | Medium Gray          | `#999999`   |
| Light Gray (bordas)  | Dark Border          | `#333333`   |
| Dark Blue            | Ocean Blue           | `#0077B6`   |
| Ocean Blue           | Soft Cyan            | `#90E0EF`   |
| Pale Blue (bg cards) | Dark Card            | `#1E1E1E`   |
| Soft Cyan (acentos)  | Soft Cyan            | `#90E0EF`   |

**Regras gerais em dark mode:**
- Reduzir intensidade de sombras (usar bordas sutis no lugar)
- Manter cores semânticas com luminosidade levemente aumentada
- Garantir contraste mínimo de 4.5:1 sobre superfícies escuras

---

## 12. Checklist de Validação de Materiais

Antes de publicar qualquer material visual, verificar:

- [ ] Usa exclusivamente cores da paleta definida (seções 1.1 a 1.3)
- [ ] Tipografia segue a escala e famílias definidas (seção 2)
- [ ] Espaçamentos usam os tokens do sistema (seção 3)
- [ ] Contraste atende WCAG AA (mínimo 4.5:1 para texto)
- [ ] Hierarquia visual está clara (títulos > subtítulos > corpo > captions)
- [ ] Elementos interativos têm estados visíveis (hover, focus, active, disabled)
- [ ] Cor não é o único indicador de significado (ícones/texto complementam)
- [ ] Material está legível em impressão P&B (quando aplicável)
- [ ] Alinhamentos estão consistentes (usar grid de 4px ou 8px)
- [ ] Tom visual transmite confiança e profissionalismo bancário
