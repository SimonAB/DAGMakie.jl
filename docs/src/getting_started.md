# Getting Started

This guide will help you create your first DAG visualisations with DAGMakie.

## Prerequisites

DAGMakie requires a Makie backend for rendering. We recommend CairoMakie for publication-quality output:

```julia
using Pkg
Pkg.add("CairoMakie")
Pkg.add("Graphs")
```

## Your First DAG

```julia
using Graphs, DAGMakie, CairoMakie

# Create a simple chain: A → B → C
g = SimpleDiGraph(3)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)

# Plot with labels
fig, ax, p = dagplot(g, nlabels=["A", "B", "C"])
```

The `dagplot` function returns:
- `fig`: The Figure object
- `ax`: The Axis object
- `p`: The GraphPlot object (for accessing node positions)

## Saving Figures

```julia
save("my_dag.png", fig)           # PNG format
save("my_dag.pdf", fig)           # PDF format (vector graphics)
save("my_dag.svg", fig)           # SVG format (vector graphics)
```

## Common Patterns

DAGMakie provides convenience functions for common causal structures:

```julia
# Chain: X → Y → Z
fig, ax, p = dagplot_chain(["X", "Y", "Z"])

# Fork: X ← Y → Z
fig, ax, p = dagplot_fork(["X", "Y", "Z"])

# Collider: X → Y ← Z
fig, ax, p = dagplot_collider(["X", "Y", "Z"])

# Confounding: Z → X → Y, Z → Y
fig, ax, p = dagplot_confounding(["Z", "X", "Y"])

# Mediation: X → M → Y, X → Y
fig, ax, p = dagplot_mediation(["X", "M", "Y"])
```

Confounding, mediation, and mixed-graph helpers (`dagplot_frontdoor`,
`dagplot_iv_confounded`, etc.) use fixed triangle layouts by default so
shortcut and bidirected edges remain visible. Pass `layout=...` to override.

## Multiple DAGs in One Figure

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

save("patterns.png", fig)
```

## Next Steps

- [Basic Plotting](@ref) — Customising node and edge appearance
- [Node Types & Styling](@ref) — Using semantic node types
- [Causal Analysis](@ref) — d-separation and adjustment sets
