# JointJS+: Data Pipeline (Angular)

This example demonstrates a data pipeline diagram built with JointJS+ and Angular, featuring automatic orthogonal link routing using the [libavoid](https://github.com/Aksem/libavoid-js) WASM library.

## Features

- **Data Pipeline Visualization**: Nodes represent pipeline stages (Database, Transform, Aggregate, Dashboard, etc.) with typed input/output ports
- **Automatic Routing**: Links are routed orthogonally around nodes using the libavoid WASM library running in a Web Worker to keep the UI responsive
- **Live Re-routing**: Dragging nodes triggers automatic re-routing of all connected links in the background worker
- **PaperScroller**: Pan and zoom the diagram with trackpad or mouse
- **Navigator**: Minimap with simplified element views for quick orientation
- **Undo/Redo**: Command manager tracks user actions while excluding router-generated changes from the history
- **Toolbar**: Undo/redo, zoom slider, auto layout, and export buttons (PNG, SVG, JSON)
- **Fallback Router**: Uses JointJS `rightAngle` router when libavoid cannot find a valid route

## Running the application

To run this application you need to have access to JointJS+ package. You can get it by having a JointJS+ license or by starting a [free trial](https://www.jointjs.com/free-trial).

This example uses `.npmrc` file to set up access to the JointJS+ private npm registry. By default it uses `JOINTJS_NPM_TOKEN` environment variable to get authentication token.

If you are a trial user, you received your access token during the trial sign-up process.
If you are a customer, log in to the customer portal at https://my.jointjs.com to obtain your access token.

You can set this environment variable in your terminal in the following way:

**macOS / Linux**:
```sh
export JOINTJS_NPM_TOKEN="jjs-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

**Windows (PowerShell)**:
```sh
$env:JOINTJS_NPM_TOKEN="jjs-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

Learn more about our [private npm registry here.](https://docs.jointjs.com/learn/help-center/npm-registry)

### Install dependencies

After setting up access to JointJS+ package, install the dependencies by running:

```bash
npm install
```

And then start the application with:

```bash
npm start
```

Navigate to `http://localhost:4200/` in your browser.

## Built with

- [JointJS+](https://www.jointjs.com/jointjs-plus) (`@joint/plus`)
- [@joint/layout-directed-graph](https://www.npmjs.com/package/@joint/layout-directed-graph) — automatic directed graph layout
- [Angular](https://angular.dev/) 19+
- [libavoid-js](https://github.com/Aksem/libavoid-js) — WASM build of the libavoid connector routing library

## Project Structure

```
src/
├── main.ts                           # Angular bootstrap
├── styles.css                        # Global styles
├── index.html                        # HTML entry point
└── app/
    ├── app.component.ts              # Main component with JointJS setup
    ├── app.component.html            # Layout template
    ├── app.component.css             # Layout styles
    ├── sample-diagram.ts             # Sample pipeline nodes and links
    ├── routing/
    │   ├── avoid-router.js           # Libavoid WASM router integration
    │   └── avoid-router.worker.js    # Web worker for off-thread routing
    └── models/
        ├── node.ts                   # Node shape with left/right port groups
        ├── edge.ts                   # Link with arrow marker
        └── port-layouts.ts           # Custom port layout (vertical fixed offsets)
```
