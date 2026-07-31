# Getting Started

## Prerequisites

DAGMakie requires a Makie backend. CairoMakie is typical for static figures:

```julia
using Pkg
Pkg.add("CairoMakie")
Pkg.add("Graphs")
```

## A chain DAG

```@example getting_started
using Graphs, DAGMakie, CairoMakie

# Create a simple chain: A → B → C
g = SimpleDiGraph(3)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)

# Plot with labels
fig, ax, p = dagplot(g, nlabels=["A", "B", "C"])
fig
```

`dagplot` returns:

- `fig`: the `Figure`
- `ax`: the `Axis`
- `p`: the `GraphPlot` (node positions and plot attributes)

## Saving figures

```julia
save("my_dag.png", fig)           # PNG
save("my_dag.pdf", fig)           # PDF (vector)
save("my_dag.svg", fig)           # SVG (vector)
```

## Common patterns

Convenience constructors for frequent causal structures:

```@example getting_started
fig = Figure(size = (1000, 220))
ax1 = Axis(fig[1, 1], title = "Chain")
ax2 = Axis(fig[1, 2], title = "Fork")
ax3 = Axis(fig[1, 3], title = "Collider")
ax4 = Axis(fig[1, 4], title = "Confounding")

g_chain, _ = chain_graph(["X", "Y", "Z"])
g_fork, _ = fork_graph(["X", "Y", "Z"])
g_collider, _ = collider_graph(["X", "Y", "Z"])
g_conf, _ = confounding_graph(["Z", "X", "Y"])

dagplot!(ax1, g_chain, nlabels = ["X", "Y", "Z"])
dagplot!(ax2, g_fork, nlabels = ["X", "Y", "Z"])
dagplot!(ax3, g_collider, nlabels = ["X", "Y", "Z"])
# Triangle layout is applied automatically for the Z→X→Y, Z→Y pattern
dagplot!(ax4, g_conf, nlabels = ["Z", "X", "Y"])
fig
```

Each pattern also has a one-liner (`dagplot_chain`, `dagplot_fork`, …). Composed
into one figure:

```@example getting_started
fig = Figure(size = (1100, 200))
ax1 = Axis(fig[1, 1], title = "chain")
ax2 = Axis(fig[1, 2], title = "fork")
ax3 = Axis(fig[1, 3], title = "collider")
ax4 = Axis(fig[1, 4], title = "confounding")
ax5 = Axis(fig[1, 5], title = "mediation")

g_chain, _ = chain_graph(["X", "Y", "Z"])
g_fork, _ = fork_graph(["X", "Y", "Z"])
g_collider, _ = collider_graph(["X", "Y", "Z"])
g_conf, _ = confounding_graph(["Z", "X", "Y"])
g_med, _ = mediation_graph(["X", "M", "Y"])
dagplot!(ax1, g_chain; nlabels = ["X", "Y", "Z"])
dagplot!(ax2, g_fork; nlabels = ["X", "Y", "Z"])
dagplot!(ax3, g_collider; nlabels = ["X", "Y", "Z"])
dagplot!(ax4, g_conf; nlabels = ["Z", "X", "Y"])
dagplot!(ax5, g_med; nlabels = ["X", "M", "Y"])
fig
```

Stand-alone one-liners return `(fig, ax, p)`:

```julia
fig, ax, p = dagplot_chain(["X", "Y", "Z"])
fig, ax, p = dagplot_fork(["X", "Y", "Z"])
fig, ax, p = dagplot_collider(["X", "Y", "Z"])
fig, ax, p = dagplot_confounding(["Z", "X", "Y"])
fig, ax, p = dagplot_mediation(["X", "M", "Y"])
```

Confounding, mediation, and mixed-graph helpers (`dagplot_frontdoor`,
`dagplot_iv_confounded`, etc.) use fixed triangle layouts by default so
shortcut and bidirected edges remain visible. Pass `layout=...` to override.

## Multiple DAGs in one figure

```@example getting_started
fig = Figure(size = (900, 280))

ax1 = Axis(fig[1, 1], title = "Chain")
ax2 = Axis(fig[1, 2], title = "Fork")
ax3 = Axis(fig[1, 3], title = "Collider")

g_chain, _ = chain_graph(["A", "B", "C"])
g_fork, _ = fork_graph(["A", "B", "C"])
g_collider, _ = collider_graph(["A", "B", "C"])

dagplot!(ax1, g_chain, nlabels = ["A", "B", "C"])
dagplot!(ax2, g_fork, nlabels = ["A", "B", "C"])
dagplot!(ax3, g_collider, nlabels = ["A", "B", "C"])
fig
```

## See also

- [Basic Plotting](@ref) — node and edge appearance
- [Node Types & Styling](@ref) — semantic node types
- [Visual Grammar](guide/visual_grammar.md) — IDAGs, SWIGs, modifier edges
- [Skeletons & Time](guide/skeletons_and_time.md) — CPDAG skeletons and time grids
- [Causal Analysis](guide/causal.md) — d-separation, adjustment sets, and
  dagitty-style `smart` colouring
