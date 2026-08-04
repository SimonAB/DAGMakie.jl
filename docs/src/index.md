# DAGMakie.jl

DAGMakie plots directed acyclic, directed cyclic, and mixed causal graphs with
Makie, building on [GraphMakie.jl](https://github.com/MakieOrg/GraphMakie.jl).
Defaults omit axes and grids; node types follow common causal-diagram
conventions (observed, latent, treatment, outcome), with helpers for bidirected
confounding, path highlighting, display-only `do(·)` surgery, and a [visual
grammar](guide/visual_grammar.md) for interaction IDAGs and DiD SWIGs.

Compared with ggdag, dagitty plots, and Python graph glue: see [Comparison](comparison.md)
and [ECOSYSTEM_COMPARISON.md](https://github.com/SimonAB/DAGMakie.jl/blob/main/ECOSYSTEM_COMPARISON.md).

## Capabilities

Layouts are deterministic for DAGs (layered) and SCC-aware for cyclic graphs.
Undirected skeletons and time-indexed grids cover CPDAG output and unrolled
temporal DAGs ([Skeletons & Time](guide/skeletons_and_time.md)). Themes
(`default`, `minimal`, `bold`, `presentation`) control stroke weight and
spacing. Convenience constructors cover chain, fork, collider, confounding, and
mediation patterns. Edge labels (`elabels`, [`structural_edge_labels`](@ref))
carry structural path coefficients or short LaTeX mechanism fragments
([Getting started](getting_started.md#edge-labels-structural-parameters)). Path
helpers accept adjustment sets directly, or load CausalInference /
CausalDynamics when identification should be computed at plot time.

## Installation

```julia
using Pkg
Pkg.add("DAGMakie")
```

DAGMakie is on the Julia General registry. It is **visualisation-only**;
identification and `do(·)` calculus stay in [CausalInference.jl](https://github.com/mschauer/CausalInference.jl)
or [CausalDynamics.jl](https://github.com/SimonAB/CausalDynamics.jl).

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
    "guide/skeletons_and_time.md",
    "guide/bidirected.md",
    "guide/causal.md",
    "guide/interventions.md",
    "api.md",
]
Depth = 2
```
