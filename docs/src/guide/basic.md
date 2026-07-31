# Basic Plotting

Core plotting entry points and customisation options.

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

Default plots use steel-blue fills with **white in-node labels**. When you choose
light fills, set `nlabels_color` accordingly (and keep nodes large enough for
the label):

```@example basic
fig, ax, p = dagplot(g,
    nlabels = labels,
    node_size = 34,
    node_color = [:goldenrod, :seagreen, :steelblue],
    nlabels_color = :white,
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

In-node labels (default) want a contrasting colour on the fill. For external
labels, increase `nlabels_distance` and typically use black text:

```@example basic
fig = Figure(size = (720, 280))
ax1 = Axis(fig[1, 1], title = "In-node (default)")
ax2 = Axis(fig[1, 2], title = "Outside the node")
dagplot!(ax1, g;
    nlabels = labels,
    nlabels_fontsize = 16,
    nlabels_color = :white,
    nlabels_distance = 0,
)
dagplot!(ax2, g;
    nlabels = labels,
    nlabels_color = :black,
    nlabels_distance = 12,
)
fig
```

### Label Alignment

By default labels sit **inside** the node (`nlabels_distance = 0`, centred).
Pass `auto_align_labels = true` to place labels **outside** in the largest
angular gap between incident edges (dagitty-style external labels). That mode
automatically uses a positive distance and dark text unless you override them:

```@example basic
fig, ax, p = dagplot(g,
    nlabels = labels,
    auto_align_labels = true,
)
fig
```

Manual alignment options (still typically with a positive `nlabels_distance`
when labels sit outside the fill):

```@example basic
fig = Figure(size = (720, 280))
ax1 = Axis(fig[1, 1], title = "Fixed align")
ax2 = Axis(fig[1, 2], title = "Per-node align")
dagplot!(ax1, g;
    nlabels = labels,
    auto_align_labels = false,
    nlabels_distance = 12,
    nlabels_color = :black,
    nlabels_align = (:right, :bottom),
)
dagplot!(ax2, g;
    nlabels = labels,
    auto_align_labels = false,
    nlabels_distance = 12,
    nlabels_color = :black,
    nlabels_align = [(:left, :center), (:center, :top), (:right, :center)],
)
fig
```

## Layout

DAGMakie now defaults to an automatic layout strategy:

- `layout_mode = :auto` chooses a deterministic layered layout for acyclic graphs
- `layout_mode = :cyclic` uses an SCC-aware layout with curved feedback edges
- `layout_mode = :spring` falls back to a force-directed layout
- `layout = ...` still accepts explicit node positions or a `NetworkLayout.jl` layout object

For CPDAG skeletons and occasion×variable grids, see
[Skeletons & Time](skeletons_and_time.md) (`dagplot_skeleton`,
`dagplot_time_indexed`).

You can still use `NetworkLayout.jl` directly when you want a force-directed layout:

```@example basic
fig, ax, p = dagplot(g, nlabels = labels, layout_mode = :spring)
fig
```

```@example basic
using NetworkLayout

fig = Figure(size = (720, 280))
ax1 = Axis(fig[1, 1], title = "Spring()")
ax2 = Axis(fig[1, 2], title = "Stress()")
dagplot!(ax1, g; nlabels = labels, layout = Spring())
dagplot!(ax2, g; nlabels = labels, layout = Stress())
fig
```

## Figure Size

```@example basic
fig, ax, p = dagplot(g,
    nlabels = labels,
    figure_size = (480, 320),    # Width × Height in pixels
)
fig
```

## Padding

Control spacing around the graph:

```@example basic
fig, ax, p = dagplot(g,
    nlabels = labels,
    padding = 0.15,              # 15% padding (fraction of range)
)
fig
```
