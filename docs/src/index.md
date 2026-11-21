# DAGMakie.jl

```@meta
CurrentModule = DAGMakie
```

```@docs
DAGMakie
```

DAGMakie draws causal diagrams for observational studies, experiments, and
time-evolving biological systems using Makie, making confounders, mediators,
unmeasured variables, interventions, and temporal structure explicit before
fitting a statistical model.

**Deciding which diagram fits your study?** See
[Choosing a diagram](orientation.md) to match your biological question or study
design to the right graph type and helper.

DAGMakie plots directed acyclic, directed cyclic, and mixed causal graphs with
Makie, building on [GraphMakie.jl](https://github.com/MakieOrg/GraphMakie.jl).
Defaults omit axes and grids; node types follow common causal-diagram
conventions from Pearl (2009) and related practice (observed, latent, treatment,
outcome), with helpers for bidirected confounding, path highlighting (Textor et
al., 2016, dagitty-style roles), display-only `do(·)` surgery, and a [visual
grammar](guide/visual_grammar.md) for interaction IDAGs and DiD SWIGs. Example
layouts often follow Cinelli, Forney & Pearl (2024,
[doi:10.1177/00491241221099552](https://doi.org/10.1177/00491241221099552)).
Temporal glyphs, single-node placement, and display-only surgery are summarised
in [Terminology](terminology.md); boundaries and validation checks live in
[Scope & boundaries](scope.md) ([BOUNDARIES.md](https://github.com/SimonAB/DAGMakie.jl/blob/main/BOUNDARIES.md)).
DOIs and BibTeX keys: [References](references.md).

## Compared with R and Python

DAGMakie brings layered causal DAGs, bidirected confounding arcs, dagitty-style
path/role highlighting, time-indexed layouts, and SWIG/DiD visual grammar into
Julia’s Makie stack—alongside SciML,
[CausalDynamics.jl](https://simonab.github.io/CausalDynamics.jl/dev/),
[CausalTargeted.jl](https://simonab.github.io/CausalTargeted.jl/dev/), and
[CausalMediation.jl](https://simonab.github.io/CausalMediation.jl/dev/). Choose
DAGMakie when causal figures should live in Julia and Documenter; prefer
`ggdag` / `dagitty` for tidyverse pipelines or the dagitty web GUI. See
[Ecosystem comparison](comparison.md) and
[ECOSYSTEM_COMPARISON.md](https://github.com/SimonAB/causal-dynamics-book/blob/main/packages/ECOSYSTEM_COMPARISON.md).

## Capabilities

Layouts are deterministic for DAGs (layered) and SCC-aware for cyclic graphs.
Edges are straight by default; mark curved edges with `:curved`, `CurvedEdge()`,
or a bow fraction to receive quadratic Bézier samples (`long_edge_routing = :quadratic`)
([Basic Plotting](guide/basic.md#layout)). Undirected skeletons and
time-indexed grids cover CPDAG output and unrolled temporal DAGs
([Skeletons & Time](guide/skeletons_and_time.md)). Themes
(`default`, `minimal`, `bold`, `presentation`) control stroke weight and
spacing. Node labels prefer `labels=`; default `label_position = :outer` (compact
markers, external auto-aligned text). Use `:inner` with `fit_node_size_to_labels=true`
for in-node white labels. Optional `color_by` role colouring; on time-indexed plots,
roles propagate across variable rows (see [Skeletons & Time](guide/skeletons_and_time.md)).
Convenience constructors cover chain,
fork, collider, confounding, and mediation patterns. Edge labels (`elabels`,
[`structural_edge_labels`](@ref)) carry structural path coefficients or short
LaTeX mechanism fragments
([Getting Started](getting-started.md#edge-labels-structural-parameters)). Path
helpers accept adjustment sets directly, or load CausalInference /
CausalDynamics when identification should be computed at plot time.

## Installation

```julia
using Pkg
Pkg.add("DAGMakie")
```

DAGMakie is on the Julia **General** registry. It is **visualisation-only**;
identification and `do(·)` calculus stay in [CausalInference.jl](https://github.com/mschauer/CausalInference.jl)
or [CausalDynamics.jl](https://github.com/SimonAB/CausalDynamics.jl).

Or for development:

```julia
Pkg.develop(path="path/to/DAGMakie.jl")
```

## Quick example

```@example home
using DAGMakie, CairoMakie

# Confounding DAG Z → X → Y, Z → Y (triangle layout: confounder on top)
fig, ax, p = dagplot_confounding(["Z", "X", "Y"])
fig
```

## Documentation

- **Guides:** [Choosing a diagram](orientation.md) · [Getting Started](getting-started.md) · [Basic plotting](guide/basic.md) · [Node types & styling](guide/styling.md) · [Visual grammar](guide/visual_grammar.md) · [Skeletons & time](guide/skeletons_and_time.md) · [Bidirected edges](guide/bidirected.md) · [Causal highlighting](guide/causal.md) · [Interventions](guide/interventions.md)
- **API Reference:** [Overview](api.md) · [Plotting](api/plotting.md) · [Specs & graphs](api/specs_and_graphs.md) · [Highlighting & interventions](api/highlighting_and_do.md) · [Temporal & skeletons](api/temporal_and_skeletons.md) · [Layout & themes](api/layout_and_themes.md)
- **Architecture & Validation:** [Scope & boundaries](scope.md) · [Terminology](terminology.md) · [Ecosystem comparison](comparison.md) · [References](references.md)

```@contents
Pages = [
    "orientation.md",
    "getting-started.md",
    "guide/basic.md",
    "guide/styling.md",
    "guide/visual_grammar.md",
    "guide/skeletons_and_time.md",
    "guide/bidirected.md",
    "guide/causal.md",
    "guide/interventions.md",
    "api.md",
    "scope.md",
    "terminology.md",
    "comparison.md",
    "references.md",
]
Depth = 2
```
