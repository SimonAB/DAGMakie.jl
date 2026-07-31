# Skeletons and time-indexed plots

Two layout helpers sit beside ordinary [`dagplot`](@ref): **undirected skeletons**
(CPDAG / PC-style output) and **time-indexed grids** for graphs unrolled over
occasions.

## Undirected skeletons

PC and related algorithms often return an undirected edge as a pair of opposing
arrows. Plotting both looks like a cycle; collapse them first with
[`digraph_skeleton`](@ref), or use [`dagplot_skeleton`](@ref) so arrowheads stay
off and edges use [`UNDIRECTED_EDGE_COLOR`](@ref).

```@example skeleton
using Graphs, DAGMakie, CairoMakie

# Opposing arcs encode an undirected edge between X and Y; Z → X is directed.
g = SimpleDiGraph(3)
add_edge!(g, 1, 2)  # X → Y
add_edge!(g, 2, 1)  # Y → X  (undirected {X,Y})
add_edge!(g, 3, 1)  # Z → X

labels = ["X", "Y", "Z"]
layout = Point2f[Point2f(-1, 0), Point2f(1, 0), Point2f(0, 1)]

fig = Figure(size = (720, 280))
ax1 = Axis(fig[1, 1], title = "Directed (misleading)")
ax2 = Axis(fig[1, 2], title = "Skeleton")
dagplot!(ax1, g; nlabels = labels, layout = layout)
dagplot!(ax2, digraph_skeleton(g); nlabels = labels, layout = layout)
fig
```

One-liner when you only need the skeleton figure:

```julia
fig, ax, p = dagplot_skeleton(g; nlabels = labels, layout = layout)
```

Passing an undirected `SimpleGraph` to [`dagplot`](@ref) / [`dagplot!`](@ref)
also suppresses arrowheads and applies the undirected edge colour.

## Time-indexed unrolling

For a graph with `n_variables × n_times` nodes in CausalDynamics order (outer
loop over occasions, inner loop over variables), use
[`dagplot_time_indexed`](@ref). Columns run left→right in time; rows are
variables.

```@example time-indexed
using Graphs, DAGMakie, CairoMakie

# Two variables (A, B), two occasions. Nodes: A₁, B₁, A₂, B₂.
g = SimpleDiGraph(4)
add_edge!(g, 1, 3)  # A₁ → A₂
add_edge!(g, 2, 4)  # B₁ → B₂
add_edge!(g, 1, 4)  # A₁ → B₂

fig, ax, p = dagplot_time_indexed(
    g, 2, 2;
    nlabels = ["A₁", "B₁", "A₂", "B₂"],
    figure_size = (520, 260),
)
fig
```

Spacing keywords `dx` and `dy` stretch columns and rows. For a
`TemporalUnrolling` from CausalDynamics.jl, prefer
`CausalDynamics.dagplot_temporal(unrolling)` (labels come from
`temporal_node_label`).

## See also

- [Visual Grammar](visual_grammar.md) — DiD SWIGs and interaction IDAGs
- [Basic Plotting](basic.md) — `layout_mode` and general `dagplot` options
