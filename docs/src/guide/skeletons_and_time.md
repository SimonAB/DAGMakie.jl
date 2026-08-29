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
# Z above X so reciprocal X–Y arcs stay clear of Z.
layout = Point2f[Point2f(-1, 0), Point2f(1, 0), Point2f(-1, 1.2)]

fig = Figure(size = (720, 280))
ax1 = Axis(fig[1, 1], title = "Directed (misleading)")
ax2 = Axis(fig[1, 2], title = "Skeleton")
dagplot!(ax1, g; labels = labels, layout = layout)
dagplot!(ax2, digraph_skeleton(g); labels = labels, layout = layout)
fig
```

One-liner when you only need the skeleton figure:

```@example skeleton
fig, ax, p = dagplot_skeleton(g; labels = labels, layout = layout)
fig
```

Passing an undirected `SimpleGraph` to [`dagplot`](@ref) / [`dagplot!`](@ref)
also suppresses arrowheads and applies the undirected edge colour.

## Time-indexed unrolling

For a graph with `n_variables × n_times` nodes in CausalDynamics order (outer
loop over occasions, inner loop over variables), use
[`dagplot_time_indexed`](@ref). Columns run left→right in time; rows are
variables.

With `color_by = :ancestors` (or `:ancestors_temporal`), exposure and outcome
roles propagate across each variable row so later occasions of the same variable
keep treatment / outcome / ancestor colours ([#5](https://github.com/SimonAB/DAGMakie.jl/issues/5)).
Pass scalar node indices or `(variable_index, time_index)` tuples for
`exposure` and `outcome`.

```@example time-smart
using Graphs, DAGMakie, CairoMakie

# W, A, Y × two occasions (CausalDynamics unroll order).
g = SimpleDiGraph(6)
add_edge!(g, 1, 2)  # W₁ → A₁
add_edge!(g, 1, 3)  # W₁ → Y₁
add_edge!(g, 4, 5)  # W₂ → A₂
add_edge!(g, 4, 6)  # W₂ → Y₂
add_edge!(g, 2, 5)  # A₁ → A₂
add_edge!(g, 2, 6)  # A₁ → Y₂

fig, ax, p = dagplot_time_indexed(
    g, 3, 2;
    labels = ["W₁", "A₁", "Y₁", "W₂", "A₂", "Y₂"],
    color_by = :ancestors,
    exposure = (2, 1),
    outcome = (3, 2),
    figure_size = (640, 260),
)
fig
```

For manual styling without the plot wrapper, use [`apply_node_type_styling`](@ref)
or [`temporal_role_styling`](@ref).

Spacing keywords `dx` and `dy` stretch columns and rows. For a
`TemporalUnrolling` from CausalDynamics.jl, prefer
`CausalDynamics.dagplot_temporal(unrolling)` (labels come from
`temporal_node_label`).

## See also

- [Visual Grammar](visual_grammar.md) — DiD SWIGs and interaction IDAGs
- [Node Types & Styling](styling.md) — `EffectMeasure` / `SwigFixed` colours
- [Basic Plotting](basic.md) — `layout_mode` and general `dagplot` options
