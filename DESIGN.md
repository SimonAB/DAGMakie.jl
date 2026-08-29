# DAGMakie.jl — design principles

This package is **visualisation only**: causal DAGs on GraphMakie/Makie, with optional highlighting tied to identification.

**Shared principles:** [DESIGN_PRINCIPLES.md](DESIGN_PRINCIPLES.md)

## Role in the stack

```
Graph (+ optional IdentificationResult)  →  dagplot! / plot_identification_result  →  Figure
```

DAGMakie does not identify effects, estimate them, or load data. It draws what the user or **CausalDynamics** already specified.

## Package-specific principles

### Visualisation only

- No estimation, no adjustment-set computation in core—optional **CausalInference** / **CausalDynamics** extensions may **highlight** paths or nodes returned by upstream ID.
- Default to **SVG-friendly** output (`CairoMakie`, responsive sizing) for HTML book builds.

### Julia native graphics

- Build on **Makie** and **GraphMakie**; do not fork layout algorithms without upstreaming general fixes to the GraphMakie fork when required by the book pin.
- API surface: **`dagplot!`**, style presets, convenience constructors (`dagplot_confounding`, …)—not a reimplementation of dagitty’s GUI.

### Causal diagram conventions

- **Dashed outlines** for latent states in state-space diagrams; solid for observed and exogenous noise (see book `.cursorrules`).
- **Layered DAG layout** for acyclic graphs; **SCC-aware** routing for feedback.
- **Time-indexed layout** (`time_indexed_layout` / `dagplot_time_indexed`) for unrolled temporal DAGs (column = occasion, row = variable). With `color_by`, exposure / outcome / ancestor roles propagate across each variable row (issue #5).
- **Undirected skeletons** (`digraph_skeleton` / `dagplot_skeleton`) for CPDAG-style
  PC displays; undirected `SimpleGraph` inputs skip directed SCC logic and suppress
  arrowheads with a dedicated stroke colour.
- Node roles (treatment, outcome, latent) are **styling hints**, not identification claims.
- **Default label placement** is `:outer` (compact nodes, external auto-aligned labels); `:inner` + fitted markers is opt in.
- **Plate / nested-unit layout** (when added) is display-only for CausalDynamics
  hierarchical DAG unrolls; DAGMakie does not own generative nesting or estimation.
- **Visual grammar** (interactions / DiD): IDAG effect-measure nodes, dash-dot
  modifier annotations, and SWIG fixed halves are display-only; see
  `docs/src/guide/visual_grammar.md`.
- **Dagitty-style colouring** (`color_by=`, `exposure=` / `treatment=`, `outcome=`): ancestor
  roles may use Graphs alone; adjustment emphasis prefers CausalInference via
  the optional extension.

### Lean and optional

- Core plotting works with **Graphs + Makie** only.
- Identification overlays (`plot_identification_result`, adjustment highlighting) live in **extensions** that load **CausalDynamics** when present.
- Keep load time low for users who only need a static figure.

### Composable with the ecosystem

- Accept standard **`Graphs.jl`** objects and label vectors; do not require a custom graph type.
- **`plot_identification_result`** should accept **`IdentificationResult`** without mutating it.
- Book chunks: separate **computation** and **`-viz`** chunks; DAGMakie figures echo variables from prior chunks.

### Publication defaults

- Sensible academic defaults: minimal chrome, readable fonts, steel-blue nodes, outer labels by default (`label_position=:inner` for in-node text).
- Themes (**default**, **minimal**, **bold**, **presentation**) are data, not one-off magic numbers scattered through call sites.

### What not to add

- Estimation, simulation, registry I/O, or hierarchical model fitting.
- Process-philosophy terminology in export names or manual pages.
- Hard dependency on CausalDynamics for basic `dagplot!` usage.
- Plate / nested-unit **layout** may visualise CausalDynamics
  `unroll_hierarchical_dag` graphs; it must not invent generative nesting.

## Adding a feature (workflow)

1. Is it purely visual? If it computes adjustment sets, it belongs in **CausalDynamics** with a thin plot hook here.
2. Prefer **keyword options** and theme keys over new global state.
3. Add a doc example with **`CairoMakie`** and a saved image under `docs/images/` when the visual is novel.
4. Test layout/rendering smoke tests where feasible; avoid brittle pixel comparisons.
5. Respect **Makie/GraphMakie version pins** documented in the CDCS `AGENTS.md` when changing behaviour the book relies on.
