# Basic Plotting

This guide covers the core plotting functions and customisation options.

```@example basic
using Graphs, DAGMakie, CairoMakie

# Classic confounding triangle: Z → X → Y, Z → Y
g, labels = confounding_graph(["Z", "X", "Y"])
nothing # hide
```

## The `dagplot` Function

The main entry point is `dagplot`, which creates a new figure:

```julia
fig, ax, p = dagplot(g; kwargs...)
```

For plotting into an existing axis, use `dagplot!`:

```julia
p = dagplot!(ax, g; kwargs...)
```

## Node Customisation

### Size and Colour

```@example basic
fig, ax, p = dagplot(g,
    nlabels = labels,
    node_size = 18,
    node_color = [:yellow, :lightgreen, :lightblue],
)
fig
```

### Outline Styling

```@example basic
fig, ax, p = dagplot(g,
    nlabels = labels,
    node_strokewidth = 2.0,
    node_strokecolor = :black,
)
fig
```

## Edge Customisation

```@example basic
fig, ax, p = dagplot(g,
    nlabels = labels,
    edge_color = :gray,
    edge_width = 1.5,
    arrow_size = 12,
    arrow_shift = :end,
)
fig
```

## Label Customisation

### Basic Labels

```julia
dagplot(g,
    nlabels = ["X", "Y", "Z"],
    nlabels_fontsize = 16,       # Font size
    nlabels_color = :black,      # Label colour
    nlabels_distance = 12,       # Distance from node (pixels)
)
```

### Label Alignment

By default, labels use a fixed alignment. Pass `auto_align_labels = true` to compute
per-node alignments that avoid edges (via package-local `compute_auto_label_aligns`,
which does not require a GraphMakie fork):

```@example basic
fig, ax, p = dagplot(g,
    nlabels = labels,
    auto_align_labels = true,
)
fig
```

Manual alignment options:

```julia
dagplot(g,
    nlabels = ["X", "Y", "Z"],
    auto_align_labels = false,
    nlabels_align = (:right, :bottom),  # Fixed alignment for all
)

# Per-node alignment
dagplot(g,
    nlabels = ["X", "Y", "Z"],
    auto_align_labels = false,
    nlabels_align = [(:left, :center), (:center, :top), (:right, :center)],
)
```

## Layout

DAGMakie now defaults to an automatic layout strategy:

- `layout_mode = :auto` chooses a deterministic layered layout for acyclic graphs
- `layout_mode = :cyclic` uses an SCC-aware layout with curved feedback edges
- `layout_mode = :spring` falls back to a force-directed layout
- `layout = ...` still accepts explicit node positions or a `NetworkLayout.jl` layout object

You can still use `NetworkLayout.jl` directly when you want a force-directed layout:

```@example basic
fig, ax, p = dagplot(g, nlabels = labels, layout_mode = :spring)
fig
```

```julia
using NetworkLayout

dagplot(g, nlabels = labels, layout = Spring())
dagplot(g, nlabels = labels, layout = Stress())
```

## Figure Size

```julia
fig, ax, p = dagplot(g,
    nlabels = ["A", "B", "C"],
    figure_size = (800, 600),    # Width × Height in pixels
)
```

## Padding

Control spacing around the graph:

```julia
dagplot(g,
    nlabels = ["A", "B", "C"],
    padding = 0.15,              # 15% padding (fraction of range)
)
```
