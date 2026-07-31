# DAGMakie.jl

DAGMakie plots directed acyclic, directed cyclic, and mixed causal graphs with
Makie, building on [GraphMakie.jl](https://github.com/MakieOrg/GraphMakie.jl).
Defaults omit axes and grids; node types follow common causal-diagram
conventions (observed, latent, treatment, outcome), with helpers for bidirected
confounding, path highlighting, display-only `do(·)` surgery, and a [visual
grammar](guide/visual_grammar.md) for interaction IDAGs and DiD SWIGs.

## Capabilities

Layouts are deterministic for DAGs (layered) and SCC-aware for cyclic graphs.
Themes (`default`, `minimal`, `bold`, `presentation`) control stroke weight and
spacing. Convenience constructors cover chain, fork, collider, confounding, and
mediation patterns. Path helpers accept adjustment sets directly, or load
CausalInference / CausalDynamics when identification should be computed at plot
time.

## Installation

```julia
using Pkg
Pkg.add("DAGMakie")
```

Prefer **0.1.1+** (visualisation-only core; identification via CausalInference.jl /
CausalDynamics.jl). v0.1.0 remains on General as the initial release.

Or for development:

```julia
Pkg.develop(url="https://github.com/SimonAB/DAGMakie.jl")
```

## Quick example

```@example home
using DAGMakie, CairoMakie

# Confounding DAG Z → X → Y, Z → Y (triangle layout: confounder on top)
fig, ax, p = dagplot_confounding(["Z", "X", "Y"])
fig
```

## Package overview

```@contents
Pages = [
    "getting_started.md",
    "guide/basic.md",
    "guide/styling.md",
    "guide/visual_grammar.md",
    "guide/bidirected.md",
    "guide/causal.md",
    "guide/interventions.md",
    "api.md",
]
Depth = 2
```
