# Basic Plotting

This guide covers the core plotting functions and customisation options.

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

```julia
dagplot(g,
    nlabels = ["A", "B", "C"],
    node_size = 15,              # Node marker size
    node_color = :lightblue,     # Single colour for all nodes
)

# Per-node colours
dagplot(g,
    nlabels = ["Confounder", "Treatment", "Outcome"],
    node_color = [:yellow, :lightgreen, :lightblue],
)
```

### Outline Styling

```julia
dagplot(g,
    nlabels = ["A", "B", "C"],
    node_strokewidth = 2.0,      # Outline width
    node_strokecolor = :black,   # Outline colour
)
```

## Edge Customisation

```julia
dagplot(g,
    nlabels = ["A", "B", "C"],
    edge_color = :gray,          # Edge colour
    edge_width = 1.5,            # Line width
    arrow_size = 12,             # Arrowhead size
    arrow_shift = :end,          # Arrow position (:end or 0-1)
)
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

Labels are automatically aligned to avoid edge overlaps:

```julia
dagplot(g,
    nlabels = ["X", "Y", "Z"],
    auto_align_labels = true,    # Default: automatic alignment
)

# Manual alignment
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

DAGMakie uses NetworkLayout.jl for graph layouts:

```julia
using NetworkLayout

# Default: Spring layout
dagplot(g, nlabels = labels, layout = Spring())

# Other layouts
dagplot(g, nlabels = labels, layout = Stress())
dagplot(g, nlabels = labels, layout = Shell())
dagplot(g, nlabels = labels, layout = Spectral())
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
