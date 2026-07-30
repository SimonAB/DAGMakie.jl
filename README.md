# DAGMakie.jl

[![CI](https://github.com/SimonAB/DAGMakie.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/SimonAB/DAGMakie.jl/actions/workflows/CI.yml)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21703327.svg)](https://doi.org/10.5281/zenodo.21703327)
[![Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://simonab.github.io/DAGMakie.jl/dev/)
[![codecov](https://codecov.io/gh/SimonAB/DAGMakie.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/SimonAB/DAGMakie.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Publication-ready visualisation of directed acyclic, directed cyclic, and mixed causal graphs for causal inference.

**Design principles:** [DESIGN.md](DESIGN.md) · [ecosystem](../DESIGN_PRINCIPLES.md)

DAGMakie provides clean, minimal DAG visualisation with sensible defaults for academic papers and presentations. It builds on [GraphMakie.jl](https://github.com/MakieOrg/GraphMakie.jl) with features specifically designed for causal diagrams.

## Features

- **In-node white labels** on steel-blue nodes by default (short variable names)
- **Deterministic layered DAG layout**: Acyclic graphs default to a fast layered layout rather than a generic spring layout
- **SCC-aware cyclic layout**: Directed feedback loops are grouped and routed as explicit curved feedback edges
- **Publication-ready themes**: Clean styling with no axes or grids
- **Causal diagram conventions**: Support for observed, latent, treatment, outcome, and bidirected confounding edges
- **Common patterns**: Convenience functions for chain, fork, collider, confounding DAGs
- **Style presets**: Default, minimal, bold, and presentation styles

## Installation

```julia
using Pkg
Pkg.add("DAGMakie")
```

v0.1.0 is on the [General registry](https://github.com/JuliaRegistries/General). Prefer the latest release (0.1.1+): visualisation-only core with optional CausalInference.jl for adjustment / d-separation in plots.

For local development:

```julia
Pkg.develop(path="/path/to/DAGMakie.jl")
```

## Quick Start

```julia
using DAGMakie, CairoMakie

# Confounding DAG Z → X → Y, Z → Y (triangle layout: confounder on top)
fig, ax, p = dagplot_confounding(["Z", "X", "Y"])
save("docs/images/confounding_dag.png", fig)
```

![Confounding DAG](docs/images/confounding_dag.png)

## Examples

### Basic DAG

```julia
using Graphs, DAGMakie, CairoMakie

g = SimpleDiGraph(4)
add_edge!(g, 1, 2)
add_edge!(g, 1, 3)
add_edge!(g, 2, 4)
add_edge!(g, 3, 4)

fig, ax, p = dagplot(g, 
    nlabels = ["A", "B", "C", "D"],
    node_color = :lightblue
)
```

### With Node Type Styling

```julia
# Highlight treatment and outcome
fig, ax, p = dagplot(g,
    nlabels = ["Confounder", "Treatment", "Outcome"],
    node_color = [:yellow, :lightgreen, :lightblue]
)
```

### Multiple DAGs

```julia
fig = Figure(size = (1200, 400))

ax1 = Axis(fig[1, 1], title = "Chain")
ax2 = Axis(fig[1, 2], title = "Fork")
ax3 = Axis(fig[1, 3], title = "Collider")

g_chain, _ = chain_graph(["A", "B", "C"])
g_fork, _ = fork_graph(["A", "B", "C"])
g_collider, _ = collider_graph(["A", "B", "C"])

dagplot!(ax1, g_chain, nlabels = ["A", "B", "C"])
dagplot!(ax2, g_fork, nlabels = ["A", "B", "C"])
dagplot!(ax3, g_collider, nlabels = ["A", "B", "C"])

save("dag_patterns.png", fig)
```

### Convenience Functions

```julia
# Common causal patterns with one function call
fig, ax, p = dagplot_chain(["X₁", "X₂", "X₃"])
fig, ax, p = dagplot_fork(["Effect₁", "Cause", "Effect₂"])
fig, ax, p = dagplot_collider(["Cause₁", "Effect", "Cause₂"])
fig, ax, p = dagplot_confounding(["Confounder", "Treatment", "Outcome"])
fig, ax, p = dagplot_mediation(["Treatment", "Mediator", "Outcome"])
```

Triangle layouts are used by default for confounding, mediation, frontdoor, IV,
and related helpers so shortcut and bidirected edges are not drawn through
intermediate nodes. Pass `layout=...` to override.

### Using DAGSpec for Complex Graphs

```julia
g = SimpleDiGraph(4)
add_edge!(g, 1, 2)
add_edge!(g, 1, 3)
add_edge!(g, 2, 4)
add_edge!(g, 3, 4)

spec = DAGSpec(g,
    node_labels = ["Instrument", "Treatment", "Confounder", "Outcome"],
    node_types = [Instrument, Treatment, Confounder, Outcome]
)

fig, ax, p = dagplot(spec)
```

### Bidirected Edges (Unmeasured Confounding)

```julia
using DAGMakie, CairoMakie

# Create a mixed graph with bidirected edge (X ↔ Y = unmeasured confounder)
mg = mixed_graph(3, 
    [(1, 2), (2, 3)],  # Directed: Z → X → Y
    [(2, 3)]           # Bidirected: X ↔ Y
)
fig, ax, p = dagplot(mg, nlabels=["Z", "X", "Y"])

# Or use convenience function
fig, ax, p = dagplot_iv_confounded(["Instrument", "Treatment", "Outcome"])

# Customise bidirected edge appearance
fig, ax, p = dagplot(mg,
    nlabels = ["Z", "X", "Y"],
    bidirected_color = :red,
    bidirected_style = :dot,
    bidirected_curvature = 0.4
)
```

### Path Highlighting and Adjustment

Identification (d-separation, adjustment sets) lives in
[CausalInference.jl](https://github.com/mschauer/CausalInference.jl) or
[CausalDynamics.jl](https://github.com/SimonAB/CausalDynamics.jl). Pass results into
`dagplot_*` via `adjustment=` / `paths=`, or load CausalInference so the optional
extension can compute a minimal backdoor set.

```julia
using DAGMakie, CausalInference, CairoMakie

# Confounded DAG: Z → X → Y, Z → Y
g, labels = confounding_graph(["Z", "X", "Y"])

# Pass an explicit adjustment set
fig, ax, p = dagplot_backdoor(g, 2, 3;
    adjustment = Set([1]),
    nlabels = labels,
)

# Or let the CausalInference extension compute a minimal backdoor set
fig, ax, p = dagplot_adjustment(g, 2, 3; nlabels = labels)

# Visualise d-separation status (pass conditioning set explicitly)
fig, ax, p = dagplot_dsep(g, 1, 3, Set([2]); nlabels = labels)

# Show directed (causal) paths when you already have them
fig, ax, p = dagplot_causal_paths(g, 2, 3; nlabels = labels)
```

### Interventions (do-operator)

`do_surgery` / `dagplot_do` are **display-only**: they mutilate a graph for
figures. They are not an identification API — use CausalDynamics
(`DoIntervention`, `apply_intervention`, …) or CausalInference for that.

```julia
# Graph surgery: remove incoming edges to intervention target
g, labels = confounding_graph(["Z", "X", "Y"])
g_do = do_surgery(g, 2)  # do(X) - removes Z → X

# Visualise intervention (shows removed edges as dashed)
int = Intervention(2; label="do(X)")
fig, ax, p = dagplot_intervention(g, int, nlabels=labels)

# Convenience function
fig, ax, p = dagplot_do(g, 2, nlabels=labels)

# Side-by-side comparison: original vs post-intervention
fig = dagplot_do_comparison(g, 2, nlabels=labels)

# Identification (d-separation, adjustment) lives in CausalInference.jl /
# CausalDynamics.jl — pass results into dagplot_* via `adjustment=` / `paths=`,
# or `using CausalInference` so the optional extension can compute them.
```

### CausalDynamics.jl Integration

> Deferred until [CausalDynamics.jl](https://github.com/SimonAB/CausalDynamics.jl) is on General. Prefer plotting via CausalDynamics’ own DAGMakie extension (`using CausalDynamics, DAGMakie`). The reverse extension source remains under `ext/DAGMakieCausalDynamicsExt.jl` for a follow-up release.

### Style Presets

```julia
# Different styles for different contexts
style = default_style()       # Standard academic paper
style = minimal_style()       # Thin lines, small nodes
style = bold_style()          # Thick lines, large nodes
style = presentation_style()  # Extra large for slides
```

## API Reference

### Main Functions

| Function | Description |
|----------|-------------|
| `dagplot(g; kwargs...)` | Create new figure with DAG |
| `dagplot!(ax, g; kwargs...)` | Plot DAG into existing axis |
| `dagplot(spec::DAGSpec; kwargs...)` | Plot from specification |

### Keyword Arguments

#### Layout

- `layout_mode = :auto` — Use the layered DAG layout for acyclic graphs and the SCC-aware cyclic layout for feedback graphs
- `layout = ...` — Override node positions directly, or pass a `NetworkLayout.jl` layout such as `Spring()` when you want a force-directed layout
- `padding = 0.1` — Padding around graph (fraction of range)

#### Nodes
- `node_size = 12` — Node size in pixels
- `node_color = :lightblue` — Fill colour
- `node_strokewidth = 1.0` — Outline width
- `node_strokecolor = :black` — Outline colour

#### Edges
- `edge_color = :black` — Edge colour
- `edge_width = 1.0` — Edge line width
- `arrow_size = 10` — Arrowhead size
- `arrow_shift = :end` — Arrow position

#### Labels
- `nlabels = nothing` — Node labels (vector of strings)
- `nlabels_align = (:right, :bottom)` — Label alignment
- `auto_align_labels = true` — Automatic alignment via `compute_auto_label_aligns` (package-local; works with registry GraphMakie)
- `nlabels_distance = 10` — Distance from node (pixels)
- `nlabels_fontsize = 14` — Font size
- `nlabels_color = :black` — Label colour

### Convenience Functions

| Function | Pattern |
|----------|---------|
| `dagplot_chain(labels)` | X₁ → X₂ → ... → Xₙ |
| `dagplot_fork(labels)` | X ← Y → Z |
| `dagplot_collider(labels)` | X → Y ← Z |
| `dagplot_confounding(labels)` | Z → X → Y, Z → Y |
| `dagplot_mediation(labels)` | X → M → Y, X → Y |
| `dagplot_confounded(labels)` | X → Y with X ↔ Y |
| `dagplot_frontdoor(labels)` | X → M → Y with X ↔ Y |
| `dagplot_iv_confounded(labels)` | Z → X → Y with X ↔ Y |
| `dagplot_m_bias(labels)` | X → Y with X ↔ M ↔ Y |

### Types

| Type | Description |
|------|-------------|
| `NodeType` | Enum: `Observed`, `Latent`, `Treatment`, `Outcome`, etc. |
| `NodeSpec` | Node specification with label, type, styling |
| `EdgeType` | Enum: `Directed`, `Bidirected`, `Undirected` |
| `EdgeSpec` | Edge specification with styling |
| `DAGSpec` | Complete DAG specification |
| `MixedGraph` | Graph with both directed and bidirected edges |

### Utilities

| Function | Description |
|----------|-------------|
| `compute_auto_label_aligns(g, positions)` | Compute optimal label positions |
| `chain_graph(labels)` | Create chain graph |
| `fork_graph(labels)` | Create fork graph |
| `collider_graph(labels)` | Create collider graph |
| `confounding_graph(labels)` | Create confounding graph |
| `mixed_graph(n, directed, bidirected)` | Create mixed graph |
| `confounded_graph(labels)` | X → Y with X ↔ Y |
| `frontdoor_graph(labels)` | X → M → Y with X ↔ Y |
| `is_dag(g)` | Check if graph is acyclic |

### Highlighting Functions

| Function | Description |
|----------|-------------|
| `dagplot_backdoor(g, t, o; adjustment, paths)` | Highlight treatment, outcome, adjustment, paths |
| `dagplot_dsep(g, x, y, z)` | Show d-separation status |
| `dagplot_causal_paths(g, t, o; paths)` | Show directed paths |
| `dagplot_adjustment(g, t, o; adjustment)` | Show adjustment (or compute via CausalInference) |
| `dagplot_highlighted(g, spec)` | Custom highlighting |

### Intervention Functions

| Function | Description |
|----------|-------------|
| `do_surgery(g, nodes)` | Display-only: remove incoming edges (plot surgery) |
| `dagplot_intervention(g, int)` | Show intervention with removed edges |
| `dagplot_do(g, node)` | Single-node intervention plot |
| `dagplot_comparison(g, int)` | Side-by-side comparison |
| `dagplot_do_comparison(g, node)` | Side-by-side for single intervention |

## Roadmap

### Phase 1 ✅ (Complete)
- [x] Automatic label alignment
- [x] Publication-ready theme
- [x] Basic dagplot recipe
- [x] Common pattern convenience functions
- [x] Node type system

### Phase 2 ✅ (Complete)
- [x] Bidirected edges for unmeasured confounding (↔)
- [x] MixedGraph type for directed + bidirected edges
- [x] Visual node type styling
- [x] Convenience functions for common confounded graphs

### Phase 3 ✅ (Complete)
- [x] Path highlighting visualisation
- [x] Convenience functions for backdoor, d-separation, and adjustment plots
- [x] Optional CausalInference.jl weakdep for auto-adjustment in plots (v0.1.1+)

### Phase 4 ✅ (Complete)
- [x] Graph surgery for do-operator
- [x] Intervention notation (`do(X)`) rendering
- [x] Intervention visualisation (single and comparison views)

### Phase 5 🚧
- [ ] CausalDynamics.jl package extension (deferred until CausalDynamics is in General)
- [ ] Direct plotting of SCM types (GraphSCM, SymbolicSCM)
- [ ] Integration with CausalDynamics analysis functions
- [ ] Causal analysis helpers and reporting

## Related Packages

- [GraphMakie.jl](https://github.com/MakieOrg/GraphMakie.jl) — General graph visualisation for Makie
- [CausalDynamics.jl](https://github.com/SimonAB/CausalDynamics.jl) — Causal inference algorithms
- [Graphs.jl](https://github.com/JuliaGraphs/Graphs.jl) — Graph data structures

## License

MIT License — see [LICENSE](LICENSE) for details.

## Citation

If you use DAGMakie.jl in your research, please cite:

```bibtex
@software{dagmakie2026,
  author = {Babayan, Simon A.},
  title = {DAGMakie.jl: Publication-ready DAG visualisation for Julia},
  year = {2026},
  url = {https://github.com/SimonAB/DAGMakie.jl}
}
```
