# JointJS+: Container distance guides (JavaScript) <a href="https://www.jointjs.com/jointjs-plus"><img src="../../jointjs-plus-badge.svg" alt="JointJS+" width="123" align="right" /></a>

This demo extends the [alignment and distance-based position guides](../alignment-and-distance-based-position-guides/js/) demo with container elements. When an element is dragged inside a container, it shows distance guides to the container walls. Sibling elements inside the container take priority over walls — if a neighbor is found in a given direction, the distance to that neighbor is shown instead of the distance to the wall.

### Features

- **Distance to container walls** — dragging an element inside a container shows distances to all four walls
- **Sibling priority** — neighbor elements inside the container replace wall distances in their direction
- **Center snapping** — elements snap to the center between two walls, two siblings, or a wall and a sibling
- **Grid snapping** — wall distances snap to the same distance grid as neighbor distances
- **Embedding** — elements can be embedded into containers via drag-and-drop (with visual feedback)
- **Custom layers** — containers render in a dedicated layer below regular shapes
- **Stencil support** — dragging new elements from the stencil also shows container wall guides

This demo is also available online at [demos.jointjs.com](https://demos.jointjs.com/container-distance-guides).

This demo builds on the original alignment and distance-based position guides demo. See that demo for the baseline behavior (neighbor distance lines, alignment lines, distance grid snapping).

## How to download this demo

You can download this demo using our [`@joint/cli` tool](https://www.npmjs.com/package/@joint/cli):

```bash
npx @joint/cli download container-distance-guides/js
```

Alternatively, you can get the [copy of the repository](https://github.com/clientIO/joint-demos/archive/refs/heads/main.zip) from GitHub as usual.

## Running the application

To run this application you need to have access to JointJS+ package. You can get it by having a JointJS+ license or by starting a [free trial](https://www.jointjs.com/free-trial).

If you are a trial user, you received your access token during the trial sign-up process.
If you are a customer, log in to the customer portal at https://my.jointjs.com to obtain your access token.

This example uses `.npmrc` file to set up access to the JointJS+ private npm registry. By default it uses `JOINTJS_NPM_TOKEN` environment variable to get authentication token. You can set this environment variable in your terminal or CI environment in the following way:

**macOS / Linux**:
```sh
export JOINTJS_NPM_TOKEN="jjs-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

**Windows (PowerShell)**:
```sh
$env:JOINTJS_NPM_TOKEN="jjs-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

Learn more about our [private npm registry here.](https://docs.jointjs.com/learn/help-center/npm-registry)

After setting up access to JointJS+ package, install the dependencies by running:

```bash
npm install
```

And then start the application with:

```bash
npm run dev
```
