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
fig, ax, p = dagplot(g, labels = ["A", "B", "C"])
fig
```

`dagplot` returns:

- `fig`: the `Figure`
- `ax`: the `Axis`
- `p`: the `GraphPlot` (node positions and plot attributes)

By default, labels sit **outside** compact nodes (`label_position = :outer`). Pass
`label_position = :inner` with `fit_node_size_to_labels = true` for in-node white text
(see [Basic Plotting](guide/basic.md)).

## Edge labels (structural parameters)

GraphMakie `elabels` pass through `dagplot`. Prefer
[`structural_edge_labels`](@ref) so labels follow `Graphs.edges(g)` order and
optional LaTeX maths (path coefficients or short mechanism fragments):

```@example getting_started
g_w, labels_w = confounding_graph(["Z", "X", "Y"])
# B[i,j] = structural weight on j → i
B = [
    0.0  0.0  0.0;
    0.8  0.0  0.0;
    0.5  1.2  0.0;
]
fig, ax, p = dagplot(g_w;
    labels = labels_w,
    elabels = structural_edge_labels(g_w, B; digits = 1),
    elabels_fontsize = 14,
    elabels_distance = 12,
    elabels_rotation = 0,
    padding = 0.45,
)
fig
```

Symbolic TeX on the same topology:

```@example getting_started
fig, ax, p = dagplot(g_w;
    labels = labels_w,
    elabels = structural_edge_labels(
        g_w,
        ["\\beta_{ZX}", "\\beta_{ZY}", "\\beta_{XY}"];
        latex = true,
    ),
    elabels_fontsize = 14,
    elabels_distance = 12,
    elabels_rotation = 0,
    padding = 0.45,
)
fig
```

See [Basic Plotting](guide/basic.md#structural-edge-labels-latex) for more
`elabels_*` options.

## Saving figures

```julia
save("my_dag.png", fig)           # PNG
save("my_dag.pdf", fig)           # PDF (vector)
save("my_dag.svg", fig)           # SVG (vector)
```

## Common patterns

Convenience constructors cover the five canonical three-variable causal motifs:

```@example getting_started
fig = Figure(size = (1100, 220))
ax1 = Axis(fig[1, 1], title = "Chain")
ax2 = Axis(fig[1, 2], title = "Fork")
ax3 = Axis(fig[1, 3], title = "Collider")
ax4 = Axis(fig[1, 4], title = "Confounding")
ax5 = Axis(fig[1, 5], title = "Mediation")

g_chain, _ = chain_graph(["X", "Y", "Z"])
g_fork, _ = fork_graph(["X", "Y", "Z"])
g_collider, _ = collider_graph(["X", "Y", "Z"])
# Triangle layout is applied automatically for confounding and mediation
g_conf, _ = confounding_graph(["Z", "X", "Y"])
g_med, _ = mediation_graph(["X", "M", "Y"])

dagplot!(ax1, g_chain; labels = ["X", "Y", "Z"])
dagplot!(ax2, g_fork; labels = ["X", "Y", "Z"])
dagplot!(ax3, g_collider; labels = ["X", "Y", "Z"])
dagplot!(ax4, g_conf; labels = ["Z", "X", "Y"])
dagplot!(ax5, g_med; labels = ["X", "M", "Y"])
fig
```

Each pattern also has a stand-alone one-liner returning `(fig, ax, p)`:

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

To compose multiple panels in a single `Figure`, pass `Axis` objects to
`dagplot!`:

```julia
fig = Figure(size = (720, 260))
ax1 = Axis(fig[1, 1], title = "Panel A")
ax2 = Axis(fig[1, 2], title = "Panel B")
dagplot!(ax1, g1; labels = labels1)
dagplot!(ax2, g2; labels = labels2)
```

## Curved edges (skip chords)

Edges are straight unless you pass `edge_routing`. Curve a fork or skip chord with
`:curved`, [`CurvedEdge`](@ref), or a bow fraction (fraction of chord length):

```@example getting_started
g_m = DiGraph(4)
add_edge!(g_m, 1, 2); add_edge!(g_m, 1, 3); add_edge!(g_m, 1, 4)
add_edge!(g_m, 2, 3); add_edge!(g_m, 2, 4); add_edge!(g_m, 3, 4)
labels_m = ["W", "A", "M", "Y"]
positions = [Point2f(0, 0), Point2f(1.2, 0), Point2f(1.2, 0.9), Point2f(2.4, 0)]
fig, ax, p = dagplot(g_m;
    labels = labels_m,
    layout = positions,
    edge_routing = Dict(
        (1, 4) => CurvedEdge(bow = 0.18, side = :right),
        (1, 3) => CurvedEdge(bow = 0.12),
    ),
)
fig
```

## Temporal glyphs

Rounded rectangles mean `value_representation = :interval_summary` only. Single-node
supports (from-onset attributes) stay circles unless you pass that representation:

```@example getting_started
keys = [(:pasture, nothing), (:burden, 0)]
g = SimpleDiGraph(2)
add_edge!(g, 1, 2)
fig, ax, p = dagplot_temporal(
    g,
    keys;
    onset_times = [0, 0],
    value_representations = [:attribute, :interval_summary],
    labels = ["pasture", "burden"],
    figure_size = (420, 220),
    fit_node_size_to_labels = false,
)
@assert p[:node_marker][][1] == :circle
@assert p[:node_marker][][2] == interval_summary_node_marker()
fig
```

See [Skeletons & Time](guide/skeletons_and_time.md) and [Terminology](terminology.md).

## Signed and cyclic biological feedback

Pass `edge_weights` to distinguish activating (`→`, positive) from inhibitory
(`-|`, negative) influences, and `layout_mode = :cyclic` when a biological
diagram contains a reciprocal feedback loop (such as host immunity suppressing
parasite load):

```@example getting_started
# 1=Infection (I), 2=Immunity (M), 3=Condition (C)
# I → M (+0.7), M -| I (-0.6), I -| C (-0.5)
B_fb = [
     0.0  -0.6   0.0;
     0.7   0.0   0.0;
    -0.5   0.0   0.0;
]
g_fb = graph_from_structural_matrix(B_fb)
fig, ax, p = dagplot(
    g_fb;
    labels = ["I", "M", "C"],
    edge_weights = B_fb,
    layout_mode = :cyclic,
    title = "Host–parasite feedback (inhibitory -|)",
)
fig
```

## Difference-in-differences (BACI) SWIG

In a before–after-control-impact (BACI) or difference-in-differences study, the
parallel-trends assumption is a statement about the untreated potential outcome
`Yₜ(0)` rather than the factual DAG alone. `dagplot_did_swig()` pairs the
factual 2×2 DAG with its Single-World Intervention Graph (Richardson & Robins,
2013; see [Visual Grammar](guide/visual_grammar.md)):

```@example getting_started
fig = dagplot_did_swig()
fig
```

## See also

- [Basic Plotting](@ref) — node and edge appearance
- [Node Types & Styling](@ref) — semantic node types
- [Visual Grammar](guide/visual_grammar.md) — IDAGs, SWIGs, modifier edges
- [Skeletons & Time](guide/skeletons_and_time.md) — CPDAG skeletons and time grids
- [Causal Analysis](guide/causal.md) — d-separation, adjustment sets, and
  dagitty-style `color_by` colouring
