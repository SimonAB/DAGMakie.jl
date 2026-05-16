# DAGMakie.jl

Publication-ready visualisation of Directed Acyclic Graphs (DAGs) for causal inference.

DAGMakie provides clean, minimal DAG visualisation with sensible defaults for academic papers and presentations. It builds on [GraphMakie.jl](https://github.com/MakieOrg/GraphMakie.jl) with features specifically designed for causal diagrams.

API names follow Pearl (`Intervention`, `do_surgery`, `find_backdoor_paths`, …). For a concise **process** reading of those terms (edges as prehensive relations, `do(·)` as physical prehension), see [Terminology](@ref).

## Features

- **Automatic label alignment**: Labels positioned to avoid edge overlaps
- **Publication-ready themes**: Clean styling with no axes or grids
- **Causal diagram conventions**: Support for observed, latent, treatment, and outcome nodes
- **Common patterns**: Convenience functions for chain, fork, collider, confounding DAGs
- **Bidirected edges**: Support for unmeasured confounding (↔)
- **Causal analysis**: d-separation, backdoor paths, adjustment sets
- **Interventions**: do-operator visualisation and graph surgery

## Installation

Since this package is not yet registered, install from GitHub:

```julia
using Pkg
Pkg.add(url="https://github.com/SimonAB/DAGMakie.jl")
```

Or for development:

```julia
Pkg.develop(url="https://github.com/SimonAB/DAGMakie.jl")
```

## Quick Example

```julia
using Graphs, DAGMakie, CairoMakie

# Create a confounding DAG: Z → X → Y, Z → Y
g = SimpleDiGraph(3)
add_edge!(g, 1, 2)  # Z → X
add_edge!(g, 1, 3)  # Z → Y
add_edge!(g, 2, 3)  # X → Y

# Plot with labels
fig, ax, p = dagplot(g, nlabels=["Z", "X", "Y"])
save("confounding_dag.png", fig)
```

## Package Overview

```@contents
Pages = [
    "getting_started.md",
    "guide/basic.md",
    "guide/styling.md",
    "guide/bidirected.md",
    "guide/causal.md",
    "guide/interventions.md",
    "api.md",
]
Depth = 2
```
