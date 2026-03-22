---
id: DOC-000003
doc_type: architecture-doc
title: Template Padrão para Relatórios HTML
system: Todos
module: UI
domain: Design
owner: fabio
team: arquitetura
status: approved
confidentiality: internal
tags: [template, html, relatório, dashboard, padrão-visual]
created_at: 2026-03-17
updated_at: 2026-03-17
---

# Template Padrão para Relatórios HTML

## REGRA OBRIGATÓRIA

> **Todo relatório HTML gerado DEVE seguir este template.**
> Não inventar estilos. Não usar frameworks CSS externos (Bootstrap, Tailwind, etc.).
> O HTML deve ser **self-contained** — todo CSS inline no `<style>`, todo JS inline no `<script>`.

---

## 1. Estrutura Base do Documento

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{TITULO}} — Banco Patria</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/remixicon@4.1.0/fonts/remixicon.css" rel="stylesheet">
    <style>
        /* Colar os tokens e classes deste documento */
    </style>
</head>
<body>
    <header class="header">...</header>
    <div class="container">
        <!-- Conteúdo do relatório -->
    </div>
    <footer class="footer">...</footer>
    <script>
        /* Toggle de tema + tabs */
    </script>
</body>
</html>
```

---

## 2. Dependências Externas (CDN)

Dependências base (sempre incluídas):

| Recurso | CDN | Uso |
|---------|-----|-----|
| **Poppins** | `https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap` | Tipografia única |
| **Remix Icon** | `https://cdn.jsdelivr.net/npm/remixicon@4.1.0/fonts/remixicon.css` | Ícones |

Dependência opcional (apenas quando o relatório contiver diagramas):

| Recurso | CDN | Uso |
|---------|-----|-----|
| **Raphaël** | `https://cdnjs.cloudflare.com/ajax/libs/raphael/2.3.0/raphael.min.js` | Dependência do Flowchart.js |
| **Flowchart.js** | `https://cdnjs.cloudflare.com/ajax/libs/flowchart/1.18.0/flowchart.min.js` | Diagramas de fluxo declarativos |

Nenhuma outra dependência externa é permitida. O arquivo deve funcionar offline (exceto fontes/ícones/JointJS, que degradam graciosamente).

---

## 3. Tokens CSS (Design Tokens)

### 3.1 Tema Escuro (Padrão)

```css
:root {
    --primary: #5BA4D9;
    --primary-dark: #3182B1;
    --primary-light: rgba(91, 164, 217, 0.12);
    --secondary: #5BB8C4;
    --success: #6ABF3B;
    --success-light: rgba(106, 191, 59, 0.12);
    --success-border: rgba(106, 191, 59, 0.3);
    --warning: #F4AC00;
    --warning-light: rgba(244, 172, 0, 0.12);
    --warning-border: rgba(244, 172, 0, 0.3);
    --danger: #E85D54;
    --danger-light: rgba(232, 93, 84, 0.12);
    --danger-border: rgba(232, 93, 84, 0.3);
    --info: #38BDF8;
    --info-light: rgba(56, 189, 248, 0.12);
    --info-border: rgba(56, 189, 248, 0.3);
    --bg: #0f1319;
    --card-bg: #1a1f2e;
    --text: #e2e8f0;
    --text-muted: #8b9ab5;
    --border: #2a3244;
    --purple: #9B96FF;
    --purple-light: rgba(155, 150, 255, 0.12);
    --orange: #FF9473;
    --teal: #2DD4BF;
    --header-bg: linear-gradient(135deg, #1a2332 0%, #15202e 50%, #1a2838 100%);
    --progress-track: #2a3244;
    --milestone-future: #4a5568;
    --alert-warning-text: #f0c040;
    --alert-danger-text: #f08a84;
    --alert-info-text: #6ecbf5;
    --alert-success-text: #8ad45a;
    --pill-success-text: #8ad45a;
    --pill-info-text: #6ecbf5;
    --pill-warning-text: #f0c040;
    --area-warning-text: #f0c040;
}
```

### 3.2 Tema Claro

```css
[data-theme="light"] {
    --primary: #3182B1;
    --primary-dark: #256a94;
    --primary-light: rgba(49, 130, 177, 0.1);
    --secondary: #418F9D;
    --success: #4C7E1B;
    --success-light: rgba(76, 126, 27, 0.08);
    --success-border: rgba(76, 126, 27, 0.25);
    --warning: #F4AC00;
    --warning-light: rgba(244, 172, 0, 0.08);
    --warning-border: rgba(244, 172, 0, 0.25);
    --danger: #C72F25;
    --danger-light: rgba(199, 47, 37, 0.08);
    --danger-border: rgba(199, 47, 37, 0.25);
    --info: #0EA5E8;
    --info-light: rgba(14, 165, 232, 0.08);
    --info-border: rgba(14, 165, 232, 0.25);
    --bg: #f4f6f9;
    --card-bg: #ffffff;
    --text: #212B37;
    --text-muted: #6E829F;
    --border: #e2e8f0;
    --purple: #7B76FE;
    --purple-light: rgba(123, 118, 254, 0.08);
    --orange: #FE7C58;
    --teal: #00D8D8;
    --header-bg: linear-gradient(135deg, #3182B1 0%, #256a94 50%, #418F9D 100%);
    --progress-track: #e9ecef;
    --milestone-future: #adb5bd;
    --alert-warning-text: #8a6600;
    --alert-danger-text: #a52820;
    --alert-info-text: #0878a8;
    --alert-success-text: #3a6112;
    --pill-success-text: #3a6112;
    --pill-info-text: #0878a8;
    --pill-warning-text: #9a6d00;
    --area-warning-text: #8a6600;
}
```

---

## 4. CSS Base Obrigatório

```css
/* Reset seletivo — NÃO usar * para não quebrar SVG de diagramas JointJS/ELK */
html, body, div, span, h1, h2, h3, h4, h5, h6, p, a, img, ul, ol, li,
header, footer, nav, section, article, aside, button, input, select, textarea,
table, tr, td, th, form, label, fieldset, legend { margin: 0; padding: 0; box-sizing: border-box; }

body {
    font-family: 'Poppins', sans-serif;
    background: var(--bg);
    color: var(--text);
    line-height: 1.5;
}

.container { max-width: 1400px; margin: 0 auto; padding: 0 24px; }
```

---

## 5. Componentes do Template

### 5.1 Header

Toda página começa com um header com gradiente, ícone, título, subtítulo, badges informativos e botão de toggle de tema.

```html
<header class="header">
    <div class="container">
        <div class="header-content">
            <div class="header-top">
                <div class="header-left">
                    <img class="header-logo logo-dark" src="data:image/png;base64,{{LOGO_DARK_BASE64}}" alt="{{EMPRESA}}">
                    <img class="header-logo logo-light" src="data:image/png;base64,{{LOGO_LIGHT_BASE64}}" alt="{{EMPRESA}}">
                    <div>
                        <h1>{{TITULO}}</h1>
                        <div class="subtitle">{{SUBTITULO}}</div>
                    </div>
                </div>
                <div class="header-right">
                    <div class="header-badge"><i class="ri-calendar-check-line"></i> {{DATA}}</div>
                    <!-- Outros badges conforme necessário -->
                    <button onclick="toggleTheme()" class="header-badge" style="border:none;cursor:pointer;" title="Alternar tema">
                        <i id="theme-icon" class="ri-sun-line"></i>
                    </button>
                </div>
            </div>
        </div>
    </div>
    <!-- Tabs — mínimo 3 obrigatórias + customizadas -->
    <div class="tabs-nav container">
        <!-- ABA 1 — OBRIGATÓRIA: Visão Macro (sempre a primeira, sempre ativa por padrão) -->
        <button class="tab-btn active" onclick="switchTab('visao-macro')">
            <i class="ri-eye-line"></i> Visão Macro
        </button>
        <!-- ABA 2 — OBRIGATÓRIA: Visão Técnica -->
        <button class="tab-btn" onclick="switchTab('visao-tecnica')">
            <i class="ri-code-s-slash-line"></i> Visão Técnica
        </button>
        <!-- ABA 3 — OBRIGATÓRIA: Quality Assurance -->
        <button class="tab-btn" onclick="switchTab('quality-assurance')">
            <i class="ri-shield-check-line"></i> Quality Assurance
        </button>
        <!-- ABA 4+ — CUSTOMIZADAS (opcionais, conforme necessidade do relatório) -->
        <!-- <button class="tab-btn" onclick="switchTab('custom-1')">
            <i class="ri-{{ICONE}}"></i> {{NOME_TAB}}
        </button> -->
    </div>
</header>
```

**CSS do Header:**

```css
.header {
    background: var(--header-bg);
    color: white;
    padding: 36px 0 0;
    position: relative;
    overflow: hidden;
}
.header::before {
    content: '';
    position: absolute;
    top: -50%;
    right: -10%;
    width: 500px;
    height: 500px;
    background: rgba(255,255,255,0.03);
    border-radius: 50%;
    z-index: 0;
}
.header-content { position: relative; z-index: 1; }
.header-top {
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 16px;
    margin-bottom: 8px;
}
.header-left { display: flex; align-items: center; gap: 16px; }
.header-icon {
    width: 52px;
    height: 52px;
    background: rgba(255,255,255,0.15);
    border-radius: 14px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 26px;
    backdrop-filter: blur(10px);
}
.header-logo {
    height: 36px;
    width: auto;
    opacity: 0.95;
    flex-shrink: 0;
}
/* Tema escuro (padrão): mostra logo-dark, esconde logo-light */
.logo-light { display: none; }
.logo-dark { display: inline-block; }
/* Tema claro: inverte visibilidade */
[data-theme="light"] .logo-dark { display: none; }
[data-theme="light"] .logo-light { display: inline-block; }
.header h1 { font-size: 1.8rem; font-weight: 700; letter-spacing: -0.5px; }
.header .subtitle { font-size: 0.95rem; opacity: 0.85; font-weight: 300; margin-top: 2px; }
.header-right { display: flex; gap: 16px; align-items: center; flex-wrap: wrap; }
.header-badge {
    background: rgba(255,255,255,0.15);
    padding: 6px 14px;
    border-radius: 8px;
    font-size: 0.78rem;
    display: flex;
    align-items: center;
    gap: 6px;
    backdrop-filter: blur(10px);
}
```

### 5.2 Tabs de Navegação

Usar quando o relatório tem múltiplas seções/visões.

```css
.tabs-nav { display: flex; gap: 4px; margin-top: 20px; }
.tab-btn {
    padding: 10px 24px;
    background: rgba(255,255,255,0.1);
    border: none;
    border-radius: 10px 10px 0 0;
    color: rgba(255,255,255,0.7);
    font-family: 'Poppins', sans-serif;
    font-size: 0.85rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
    display: flex;
    align-items: center;
    gap: 8px;
}
.tab-btn:hover { background: rgba(255,255,255,0.18); color: white; }
.tab-btn.active { background: var(--bg); color: var(--primary); font-weight: 600; }
.tab-btn i { font-size: 1.1rem; }
.tab-content { display: none; padding-top: 24px; padding-bottom: 32px; }
.tab-content.active { display: block; }
```

### 5.3 Stat Cards (KPIs)

Cards de indicadores numéricos no topo da página.

```html
<div class="stats-grid">
    <div class="stat-card">
        <div class="stat-card-icon bg-primary"><i class="ri-{{ICONE}}"></i></div>
        <div class="stat-card-info">
            <div class="stat-card-number" style="color: var(--primary)">{{VALOR}}</div>
            <div class="stat-card-label">{{LABEL}}</div>
        </div>
    </div>
</div>
```

```css
.stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 16px;
    margin-bottom: 28px;
}
.stat-card {
    background: var(--card-bg);
    border-radius: 12px;
    padding: 18px 20px;
    box-shadow: 0 2px 12px rgba(0,0,0,0.04);
    border: 1px solid var(--border);
    display: flex;
    align-items: center;
    gap: 14px;
}
.stat-card-icon {
    width: 44px;
    height: 44px;
    border-radius: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.3rem;
    color: white;
    flex-shrink: 0;
}
.stat-card-info { flex: 1; }
.stat-card-number { font-size: 1.12rem; font-weight: 700; line-height: 1.1; }
.stat-card-label { font-size: 0.72rem; color: var(--text-muted); font-weight: 500; text-transform: uppercase; letter-spacing: 0.3px; }
```

### 5.4 Cards Genéricos

Container padrão para qualquer bloco de conteúdo.

```html
<div class="card">
    <div class="card-header">
        <div class="card-header-icon bg-primary"><i class="ri-{{ICONE}}"></i></div>
        <div class="card-title">{{TITULO}}</div>
        <div class="card-badge" style="background: var(--primary-light); color: var(--primary);">{{BADGE}}</div>
    </div>
    <div class="card-body">
        <!-- Conteúdo -->
    </div>
</div>
```

```css
.card {
    background: var(--card-bg);
    border-radius: 12px;
    border: 1px solid var(--border);
    box-shadow: 0 2px 8px rgba(0,0,0,0.03);
    overflow: hidden;
    margin-bottom: 20px;
}
.card-header {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 14px 18px;
    border-bottom: 1px solid var(--border);
    background: var(--bg);
}
.card-header-icon {
    width: 32px;
    height: 32px;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1rem;
    color: white;
    flex-shrink: 0;
}
.card-title { font-weight: 600; font-size: 0.95rem; flex: 1; }
.card-badge {
    padding: 2px 10px;
    border-radius: 12px;
    font-size: 0.7rem;
    font-weight: 600;
    white-space: nowrap;
}
.card-body { padding: 18px; }
```

### 5.5 Progress Bars

```html
<div class="progress-container">
    <div class="progress-header">
        <span class="progress-label">{{LABEL}}</span>
        <span class="progress-value">{{PERCENTUAL}}%</span>
    </div>
    <div class="progress-bar-bg">
        <div class="progress-bar-fill bg-success" style="width: {{PERCENTUAL}}%"></div>
    </div>
</div>
```

```css
.progress-container { margin-bottom: 16px; }
.progress-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
.progress-label { font-size: 0.82rem; font-weight: 500; }
.progress-value { font-size: 0.82rem; font-weight: 600; }
.progress-bar-bg { width: 100%; height: 8px; background: var(--progress-track); border-radius: 4px; overflow: hidden; }
.progress-bar-fill { height: 100%; border-radius: 4px; transition: width 0.5s; }
```

### 5.6 Alertas

```html
<div class="alert alert-warning">
    <i class="ri-error-warning-line"></i>
    <span>{{MENSAGEM}}</span>
</div>
```

Variantes: `alert-warning`, `alert-danger`, `alert-info`, `alert-success`.

```css
.alert {
    padding: 12px 16px;
    border-radius: 8px;
    font-size: 0.82rem;
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 10px;
    border: 1px solid;
}
.alert i { font-size: 1.1rem; flex-shrink: 0; }
.alert-warning { background: var(--warning-light); border-color: var(--warning-border); color: var(--alert-warning-text); }
.alert-danger { background: var(--danger-light); border-color: var(--danger-border); color: var(--alert-danger-text); }
.alert-info { background: var(--info-light); border-color: var(--info-border); color: var(--alert-info-text); }
.alert-success { background: var(--success-light); border-color: var(--success-border); color: var(--alert-success-text); }
```

### 5.7 Timeline / Roadmap

Linha horizontal com milestones para marcos de projeto.

```html
<div class="roadmap">
    <div class="milestone completed">
        <div class="milestone-dot"><i class="ri-check-line"></i></div>
        <div class="milestone-label">{{LABEL}}</div>
        <div class="milestone-date">{{DATA}}</div>
        <div class="milestone-name">{{NOME}}</div>
    </div>
    <div class="milestone current">...</div>
    <div class="milestone future">...</div>
</div>
```

Classes de estado: `completed` (verde), `current` (azul com pulse), `future` (cinza), `golive` (laranja).

```css
.roadmap { display: flex; gap: 0; margin: 24px 0; position: relative; }
.roadmap::before {
    content: '';
    position: absolute;
    top: 24px;
    left: 0;
    right: 0;
    height: 4px;
    background: var(--border);
    z-index: 0;
}
.milestone { flex: 1; position: relative; z-index: 1; text-align: center; padding: 0 8px; }
.milestone-dot {
    width: 48px;
    height: 48px;
    border-radius: 50%;
    margin: 0 auto 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.2rem;
    color: white;
    border: 4px solid var(--bg);
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}
.milestone-label { font-size: 0.7rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.3px; color: var(--text-muted); }
.milestone-date { font-size: 0.82rem; font-weight: 600; color: var(--text); margin-top: 2px; }
.milestone-name { font-size: 0.75rem; color: var(--text-muted); margin-top: 2px; }
.milestone.completed .milestone-dot { background: var(--success); }
.milestone.current .milestone-dot { background: var(--primary); animation: pulse 2s infinite; }
.milestone.future .milestone-dot { background: var(--milestone-future); }
.milestone.golive .milestone-dot { background: var(--orange); }
@keyframes pulse {
    0%, 100% { box-shadow: 0 0 0 0 rgba(49,130,177,0.4); }
    50% { box-shadow: 0 0 0 8px rgba(49,130,177,0); }
}
```

### 5.8 Delivery Cards (Entregas com status)

Cards com lista de itens e indicador de status por item.

```html
<div class="delivery-grid">
    <div class="delivery-card">
        <div class="delivery-header">
            <div class="delivery-icon bg-primary"><i class="ri-{{ICONE}}"></i></div>
            <div class="delivery-title">{{TITULO}}</div>
            <div class="delivery-marco" style="background: var(--success-light); color: var(--success);">{{MARCO}}</div>
        </div>
        <div class="delivery-body">
            <div class="delivery-item">
                <div class="delivery-status status-done"><i class="ri-check-line"></i></div>
                <div class="delivery-item-text">
                    {{DESCRICAO}}
                    <div class="delivery-item-detail">{{DETALHE}}</div>
                </div>
            </div>
        </div>
    </div>
</div>
```

Status: `status-done` (verde), `status-progress` (azul), `status-partial` (amarelo), `status-blocked` (vermelho), `status-pending` (cinza).

```css
.delivery-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px; }
.delivery-card {
    background: var(--card-bg);
    border-radius: 12px;
    border: 1px solid var(--border);
    overflow: hidden;
    box-shadow: 0 2px 8px rgba(0,0,0,0.03);
}
.delivery-card.full-width { grid-column: 1 / -1; }
.delivery-header { display: flex; align-items: center; gap: 10px; padding: 14px 18px; border-bottom: 1px solid var(--border); }
.delivery-icon {
    width: 36px;
    height: 36px;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.1rem;
    color: white;
    flex-shrink: 0;
}
.delivery-title { font-weight: 600; font-size: 0.95rem; flex: 1; }
.delivery-marco { font-size: 0.65rem; padding: 2px 8px; border-radius: 10px; font-weight: 600; text-transform: uppercase; }
.delivery-body { padding: 16px 18px; }
.delivery-item {
    display: flex;
    align-items: flex-start;
    gap: 10px;
    padding: 8px 0;
    border-bottom: 1px solid var(--border);
    font-size: 0.82rem;
}
.delivery-item:last-child { border-bottom: none; }
.delivery-status {
    width: 22px;
    height: 22px;
    border-radius: 6px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 0.7rem;
    color: white;
    flex-shrink: 0;
    margin-top: 1px;
}
.delivery-item-text { flex: 1; }
.delivery-item-detail { font-size: 0.72rem; color: var(--text-muted); margin-top: 1px; }
.status-done { background: var(--success); }
.status-progress { background: var(--primary); }
.status-partial { background: var(--warning); }
.status-blocked { background: var(--danger); }
.status-pending { background: var(--milestone-future); }
```

### 5.9 Section Headers

Cabeçalhos de seção dentro do conteúdo.

```html
<div class="section">
    <div class="section-header">
        <div class="section-icon bg-primary"><i class="ri-{{ICONE}}"></i></div>
        <div class="section-title">{{TITULO}}</div>
        <div class="section-count">{{CONTAGEM}}</div>
    </div>
</div>
```

```css
.section { margin-top: 32px; }
.section-header {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 20px;
    padding-bottom: 12px;
    border-bottom: 2px solid var(--border);
}
.section-icon {
    width: 36px;
    height: 36px;
    border-radius: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.1rem;
    color: white;
    flex-shrink: 0;
}
.section-title { font-size: 1.15rem; font-weight: 600; }
.section-count {
    background: var(--bg);
    padding: 4px 12px;
    border-radius: 20px;
    font-size: 0.78rem;
    font-weight: 600;
    color: var(--text-muted);
}
```

### 5.10 Area Cards (Grids de informação)

```css
.areas-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; }
.area-card {
    background: var(--card-bg);
    border-radius: 10px;
    border: 1px solid var(--border);
    padding: 16px;
}
.area-header { display: flex; align-items: center; gap: 8px; margin-bottom: 12px; }
.area-icon {
    width: 28px;
    height: 28px;
    border-radius: 6px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 0.85rem;
    color: white;
}
.area-name { font-weight: 600; font-size: 0.82rem; }
.area-item { font-size: 0.75rem; color: var(--text-muted); padding: 3px 0; display: flex; align-items: center; gap: 6px; }
.area-item i { font-size: 0.65rem; }
.area-item.critical { color: var(--danger); font-weight: 500; }
.area-item.warning { color: var(--area-warning-text); }
```

### 5.11 Pills / Tags

```css
.uc-pills { display: flex; flex-wrap: wrap; gap: 4px; }
.uc-pill {
    display: inline-block;
    padding: 2px 9px;
    border-radius: 6px;
    font-size: 0.68rem;
    font-weight: 400;
    white-space: nowrap;
    line-height: 1.6;
    border: 1px solid;
}
```

### 5.12 Legenda

```html
<div class="legend">
    <div class="legend-item"><div class="legend-dot bg-success"></div> Concluído</div>
    <div class="legend-item"><div class="legend-dot bg-primary"></div> Em andamento</div>
    <div class="legend-item"><div class="legend-dot bg-warning"></div> Parcial</div>
    <div class="legend-item"><div class="legend-dot bg-danger"></div> Bloqueado</div>
</div>
```

```css
.legend { display: flex; gap: 20px; flex-wrap: wrap; }
.legend-item { display: flex; align-items: center; gap: 6px; font-size: 0.75rem; color: var(--text-muted); }
.legend-dot { width: 10px; height: 10px; border-radius: 3px; }
```

### 5.13 Footer (badge-footer)

Footer no padrão badge: barra colorida à esquerda, avatar com iniciais + nome/área/data, informações do documento à direita, e selo vertical "Criado por" na extremidade.

```html
<div class="container">
    <div class="badge badge-footer" style="margin-bottom:40px; margin-top:10px; display:flex; width:100%;">
        <div class="badge-bar"></div>
        <div class="badge-body" style="flex:1; justify-content:space-between;">
            <div style="display:flex; align-items:center; gap:10px;">
                <div class="badge-icon">{{INICIAIS}}</div>
                <div class="badge-text">
                    <span class="badge-name">{{NOME_AUTOR}}</span>
                    <span class="badge-role">{{AREA_AUTOR}}</span>
                    <span class="badge-date">Criado em: {{DATA_CRIACAO}}</span>
                </div>
            </div>
            <div style="text-align:right; font-size:11px; color:var(--text-muted);">
                {{SISTEMA}} &middot; {{TITULO_DOCUMENTO}}<br>
                {{DESCRICAO_DOCUMENTO}} &middot; {{DATA_DOCUMENTO}}
            </div>
        </div>
        <div class="badge-seal">Criado por</div>
    </div>
</div>
```

O componente badge é reutilizável (aparece também em headers de poster/relatório). A variante `.badge-footer` aplica a cor primária na barra, ícone e selo.

```css
.badge {
    display: inline-flex;
    align-items: stretch;
    border-radius: 6px;
    overflow: hidden;
    box-shadow: 0 1px 4px rgba(0,0,0,0.30);
    font-family: 'Poppins', sans-serif;
    margin-bottom: 10px;
}
.badge-bar { width: 5px; flex-shrink: 0; }
.badge-body {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 7px 14px 7px 10px;
    background: var(--card-bg);
}
.badge-icon {
    width: 32px;
    height: 32px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 700;
    font-size: 12px;
    color: var(--bg);
    flex-shrink: 0;
}
.badge-text { display: flex; flex-direction: column; gap: 1px; }
.badge-name { font-weight: 700; font-size: 13px; color: var(--text); }
.badge-role { font-size: 11px; font-weight: 500; color: var(--text-muted); }
.badge-date { font-size: 10.5px; color: var(--text-muted); }
.badge-seal {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 7px 10px;
    font-size: 9px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 1px;
    writing-mode: vertical-rl;
    text-orientation: mixed;
    color: var(--bg);
}
.badge-footer .badge-bar,
.badge-footer .badge-icon,
.badge-footer .badge-seal { background: var(--primary); }
```

---

## 6. Classes Utilitárias

```css
/* Backgrounds */
.bg-primary { background: var(--primary); }
.bg-success { background: var(--success); }
.bg-info { background: var(--info); }
.bg-warning { background: var(--warning); }
.bg-danger { background: var(--danger); }
.bg-secondary { background: var(--secondary); }
.bg-purple { background: var(--purple); }
.bg-orange { background: var(--orange); }

/* Grids */
.grid-2 { display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px; }
.grid-3 { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; }

/* Texto */
.text-success { color: var(--success); }
.text-warning { color: var(--warning); }
.text-danger { color: var(--danger); }
.text-info { color: var(--info); }
.text-muted { color: var(--text-muted); }

/* Helpers */
.fw-600 { font-weight: 600; }
.fs-12 { font-size: 0.75rem; }
.mt-16 { margin-top: 16px; }
.mb-8 { margin-bottom: 8px; }
```

---

## 7. Responsividade

```css
@media (max-width: 1024px) {
    .contexts-grid, .delivery-grid, .grid-2 { grid-template-columns: 1fr; }
    .context-card.full-width, .delivery-card.full-width { grid-column: auto; }
    .areas-grid, .grid-3 { grid-template-columns: 1fr 1fr; }
}
@media (max-width: 768px) {
    .stats-grid { grid-template-columns: repeat(2, 1fr); }
    .areas-grid { grid-template-columns: 1fr; }
    .roadmap { flex-direction: column; gap: 16px; }
    .roadmap::before { display: none; }
    .tabs-nav { flex-wrap: wrap; }
    .tab-btn { font-size: 0.78rem; padding: 8px 16px; }
}
```

---

## 8. Impressão

```css
@media print {
    body { background: #1a1f2e !important; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    .header { padding: 16px 0 0; }
    .card, .stat-card, .context-card, .delivery-card { box-shadow: none; break-inside: avoid; }
    .tab-content { display: block !important; page-break-before: always; }
    .tabs-nav { display: none; }
}
```

---

## 9. JavaScript Obrigatório

Todo relatório deve incluir toggle de tema e navegação por tabs:

```javascript
function switchTab(tabId) {
    document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + tabId).classList.add('active');
    event.currentTarget.classList.add('active');
}

function toggleTheme() {
    const html = document.documentElement;
    const icon = document.getElementById('theme-icon');
    if (html.getAttribute('data-theme') === 'light') {
        html.removeAttribute('data-theme');
        icon.className = 'ri-sun-line';
        localStorage.setItem('caefe-theme', 'dark');
    } else {
        html.setAttribute('data-theme', 'light');
        icon.className = 'ri-moon-line';
        localStorage.setItem('caefe-theme', 'light');
    }
}

// Restaurar tema salvo
(function() {
    const saved = localStorage.getItem('caefe-theme');
    if (saved === 'light') {
        document.documentElement.setAttribute('data-theme', 'light');
        document.addEventListener('DOMContentLoaded', function() {
            document.getElementById('theme-icon').className = 'ri-moon-line';
        });
    }
})();
```

---

## 10. Estrutura Obrigatória de Abas

Todo relatório HTML **DEVE** ter no mínimo 3 abas obrigatórias. Da quarta em diante são opcionais e customizáveis.

### Aba 1 — Visão Macro (OBRIGATÓRIA)

- **ID:** `tab-visao-macro`
- **Ícone:** `ri-eye-line`
- **Sempre ativa por padrão** (classe `active` no botão e no conteúdo)
- **Propósito:** visão executiva e estratégica do que o relatório apresenta

**Conteúdo esperado:**
- Stats Grid com KPIs principais (números de alto nível)
- Timeline / Roadmap com marcos e datas-chave
- Cards de progresso geral (barras percentuais por área/módulo)
- Alertas de risco ou bloqueios críticos
- Resumo de status (o que está bem, o que precisa de atenção)

**Tom:** direto, objetivo, voltado para gestores e stakeholders. Números agregados, sem detalhes de implementação. Quem lê esta aba deve entender o cenário completo em 30 segundos.

```html
<div id="tab-visao-macro" class="tab-content active">
    <!-- Stats Grid com KPIs macro -->
    <div class="stats-grid">...</div>

    <!-- Timeline / Roadmap (se aplicável) -->
    <div class="card">
        <div class="card-header">
            <div class="card-header-icon bg-primary"><i class="ri-flag-line"></i></div>
            <div class="card-title">Marcos do Projeto</div>
        </div>
        <div class="card-body">
            <div class="roadmap">...</div>
        </div>
    </div>

    <!-- Progresso geral + Alertas lado a lado -->
    <div class="grid-2">
        <div class="card"><!-- Progresso por área --></div>
        <div class="card"><!-- Riscos e alertas --></div>
    </div>
</div>
```

### Aba 2 — Visão Técnica (OBRIGATÓRIA)

- **ID:** `tab-visao-tecnica`
- **Ícone:** `ri-code-s-slash-line`
- **Propósito:** detalhamento técnico do que foi apresentado na Visão Macro

**Conteúdo esperado:**
- Delivery Cards com status item a item (done, progress, partial, blocked, pending)
- Detalhamento por módulo, componente ou entidade
- Listas de tarefas com granularidade técnica
- Mapeamentos (use cases, endpoints, entidades, dependências)
- Métricas técnicas (cobertura, performance, contagens detalhadas)
- Area Cards com pendências por responsável ou equipe

**Tom:** detalhado, técnico, voltado para desenvolvedores e tech leads. Cada item deve ter status visual claro. Quem lê esta aba deve conseguir agir sobre os itens.

```html
<div id="tab-visao-tecnica" class="tab-content">
    <!-- Delivery Cards com entregas detalhadas -->
    <div class="delivery-grid">
        <div class="delivery-card">...</div>
        <div class="delivery-card">...</div>
    </div>

    <!-- Seções com detalhamento -->
    <div class="section">
        <div class="section-header">
            <div class="section-icon bg-info"><i class="ri-list-check-2"></i></div>
            <div class="section-title">Detalhamento por Módulo</div>
            <div class="section-count">{{TOTAL}} itens</div>
        </div>
        <!-- Conteúdo detalhado -->
    </div>

    <!-- Pendências por área -->
    <div class="section">
        <div class="section-header">
            <div class="section-icon bg-warning"><i class="ri-error-warning-line"></i></div>
            <div class="section-title">Pendências</div>
        </div>
        <div class="areas-grid">...</div>
    </div>
</div>
```

### Aba 3 — Quality Assurance (OBRIGATÓRIA)

- **ID:** `tab-quality-assurance`
- **Ícone:** `ri-shield-check-line`
- **Propósito:** avaliação de qualidade do documento/artefato apresentado, com score, critérios e sugestões de melhoria

**Conteúdo esperado:**
- Stats Grid com 4 KPIs de QA (Score Geral, Status QA, Data da Revisão, Formalização/Próximo Passo)
- Alerta de status (success se >= 90%, warning se 80-89%, danger se < 80%)
- Card de breakdown com barras de progresso por critério de qualidade
- Grid 2 colunas: Pontos Fortes (esquerda) + Sugestões de Melhoria (direita)
- Cada ponto forte/sugestão como delivery-item com status visual (done/partial)

**Tom:** analítico, transparente, construtivo. Quem lê esta aba deve saber exatamente: qual é o score, por que não é 100%, e o que fazer para melhorar.

**Referência de implementação:** ver `ADR-008_governanca_ciclo_vida_rollback.html` na pasta `3 - presentation/` da KB de ADRs.

```html
<div id="tab-quality-assurance" class="tab-content">
    <!-- Stats Grid com KPIs de QA -->
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-card-icon bg-success"><i class="ri-shield-check-line"></i></div>
            <div class="stat-card-info">
                <div class="stat-card-number" style="color: var(--success)">{{QA_SCORE}}%</div>
                <div class="stat-card-label">QA Score Geral</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-card-icon bg-primary"><i class="ri-checkbox-circle-line"></i></div>
            <div class="stat-card-info">
                <div class="stat-card-number" style="color: var(--primary)">{{QA_STATUS}}</div>
                <div class="stat-card-label">Status QA</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-card-icon bg-info"><i class="ri-calendar-check-line"></i></div>
            <div class="stat-card-info">
                <div class="stat-card-number" style="color: var(--info)">{{QA_DATE}}</div>
                <div class="stat-card-label">Data da Revisão</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-card-icon bg-warning"><i class="ri-arrow-right-circle-line"></i></div>
            <div class="stat-card-info">
                <div class="stat-card-number" style="color: var(--warning)">{{NEXT_STEP}}</div>
                <div class="stat-card-label">Próximo Passo</div>
            </div>
        </div>
    </div>

    <!-- Alerta de status -->
    <div class="alert alert-{{QA_ALERT_TYPE}}">
        <i class="ri-checkbox-circle-line"></i>
        <span><strong>{{QA_ALERT_TITLE}}</strong> {{QA_ALERT_DESCRIPTION}}</span>
    </div>

    <!-- Breakdown por critério -->
    <div class="card">
        <div class="card-header">
            <div class="card-header-icon bg-primary"><i class="ri-bar-chart-grouped-line"></i></div>
            <div class="card-title">Avaliação por Critério</div>
            <div class="card-badge" style="background: var(--success-light); color: var(--success)">{{QA_SCORE}}% média</div>
        </div>
        <div class="card-body">
            <!-- Repetir para cada critério -->
            <div class="progress-container">
                <div class="progress-header">
                    <span class="progress-label">{{CRITERIO_NOME}} — {{CRITERIO_DESCRICAO}}</span>
                    <span class="progress-value" style="color:var(--{{CRITERIO_COR}})">{{CRITERIO_SCORE}}%</span>
                </div>
                <div class="progress-bar-bg">
                    <div class="progress-bar-fill bg-{{CRITERIO_COR}}" style="width:{{CRITERIO_SCORE}}%"></div>
                </div>
            </div>
        </div>
    </div>

    <!-- Pontos Fortes + Sugestões lado a lado -->
    <div class="grid-2">
        <div class="card">
            <div class="card-header">
                <div class="card-header-icon bg-success"><i class="ri-thumb-up-line"></i></div>
                <div class="card-title">Pontos Fortes</div>
            </div>
            <div class="card-body">
                <!-- Repetir para cada ponto forte -->
                <div class="delivery-item">
                    <div class="delivery-status status-done"><i class="ri-check-line"></i></div>
                    <div class="delivery-item-text">
                        <strong>{{PONTO_FORTE_TITULO}}</strong>
                        <div class="delivery-item-detail">{{PONTO_FORTE_DETALHE}}</div>
                    </div>
                </div>
            </div>
        </div>
        <div class="card">
            <div class="card-header">
                <div class="card-header-icon bg-warning"><i class="ri-lightbulb-line"></i></div>
                <div class="card-title">Sugestões de Melhoria</div>
            </div>
            <div class="card-body">
                <!-- Repetir para cada sugestão -->
                <div class="delivery-item">
                    <div class="delivery-status status-partial"><i class="ri-arrow-up-line"></i></div>
                    <div class="delivery-item-text">
                        <strong>{{SUGESTAO_TITULO}}</strong>
                        <div class="delivery-item-detail">{{SUGESTAO_DETALHE}}</div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
```

### Abas 4+ — Customizadas (OPCIONAIS)

- **ID:** `tab-{{slug-customizado}}`
- **Ícone:** livre (Remix Icon)
- **Propósito:** visões complementares específicas do contexto do relatório

**Exemplos de abas customizadas:**
- "Mapeamento de Use Cases" — grid de contextos e módulos com pills de UC
- "Integrações" — status de APIs e dependências externas
- "Histórico" — evolução temporal, changelog, comparativo entre períodos
- "Financeiro" — custos, orçamento, burn rate
- "Equipe" — alocação, responsabilidades, capacity

**Regra:** abas customizadas devem manter o mesmo padrão visual (mesmos componentes, mesmos tokens). Não inventar estilos novos.

### Resumo da Estrutura de Abas

| Posição | Nome | ID | Ícone | Obrigatória | Público-alvo |
|---------|------|----|-------|-------------|--------------|
| 1a | Visão Macro | `tab-visao-macro` | `ri-eye-line` | Sim | Gestores, stakeholders |
| 2a | Visão Técnica | `tab-visao-tecnica` | `ri-code-s-slash-line` | Sim | Desenvolvedores, tech leads |
| 3a | Quality Assurance | `tab-quality-assurance` | `ri-shield-check-line` | Sim | Revisores, QA, arquitetos |
| 4a+ | {{Customizada}} | `tab-{{slug}}` | livre | Não | Conforme contexto |

---

## 11. Regras de Geração

1. **Tema escuro é o padrão.** O toggle permite alternar para claro.
2. **Nunca usar cores fora dos tokens.** Toda cor vem de `var(--token)`.
3. **Nunca usar frameworks CSS externos.** Sem Bootstrap, Tailwind, etc.
4. **Arquivo self-contained.** Um único `.html` com tudo embutido.
5. **Sempre incluir toggle de tema.** O botão fica no header-right.
6. **Sempre responsivo.** Incluir os media queries da seção 7.
7. **Sempre com suporte a impressão.** Incluir os estilos da seção 8.
8. **Ícones exclusivamente Remix Icon.** Usar classes `ri-*`.
9. **Tipografia exclusivamente Poppins.** Sem outra fonte além de Poppins.
10. **Manter a hierarquia:** Header → Stats Grid → Cards → Sections → Footer.
11. **Placeholders com `{{VARIAVEL}}`** para facilitar substituição programática.
12. **Conteúdo em pt-BR.** Toda label, título e texto em português brasileiro.
13. **Mínimo 3 abas obrigatórias.** "Visão Macro" (1a, ativa por padrão), "Visão Técnica" (2a) e "Quality Assurance" (3a). Abas customizadas da 4a em diante.
14. **Visão Macro primeiro.** A aba macro deve funcionar como resumo executivo — quem lê apenas ela deve entender o cenário.
15. **Visão Técnica com ação.** Cada item na aba técnica deve ter status visual claro e granularidade suficiente para ação imediata.
16. **Quality Assurance com transparência.** A aba QA deve exibir score geral, breakdown por critério com barras de progresso, pontos fortes e sugestões de melhoria. Deve documentar explicitamente por que o score não é 100%.
16. **Logo no header.** Sempre usar a logo do Banco Patria em base64 (arquivo `logo-patria-base64.txt`) no canto superior esquerdo do header, via `<img class="header-logo">`. Substitui o `header-icon` com ícone Remix.
