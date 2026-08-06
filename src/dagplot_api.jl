# SPDX-License-Identifier: MIT

"""Public `dagplot` / `dagplot!` entry points for `AbstractGraph`."""

# SPDX-License-Identifier: MIT

"""
Main dagplot recipe for DAG visualisation.

Provides `dagplot` and `dagplot!` functions for creating publication-ready
causal diagram visualisations with sensible defaults.
"""

using Makie: Figure, Axis, xlims!, ylims!, tightlimits!, lines!, scatter!, RGBAf, Point2f
using GraphMakie: graphplot!, Arrow, distance_between_markers

"""
    dagplot(g; kwargs...)

Create a clean DAG visualisation with publication-ready defaults.

This is a convenience wrapper that creates a new figure and axis, then
delegates to `dagplot!`. All keyword arguments are passed through.

# Arguments
- `g::AbstractGraph`: A graph from Graphs.jl to plot

# Keyword Arguments
- `figure_size::Tuple{Int, Int} = (600, 400)`: Figure dimensions
- See `dagplot!` for all other keyword arguments

# Returns
- Tuple `(fig, ax, p)` where:
  - `fig`: The Figure object
  - `ax`: The Axis object
  - `p`: The GraphPlot object (for accessing node positions, etc.)

# Examples
```julia
using Graphs, DAGMakie, CairoMakie

# Simple chain graph
g = SimpleDiGraph(3)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)

fig, ax, p = dagplot(g, nlabels=["X", "Y", "Z"])
save("dag.png", fig)

# Access node positions
positions = p[:node_pos][]
```
"""
function dagplot(g::Graphs.AbstractGraph;
    figure_size::Tuple{Int, Int} = (600, 400),
    smart = false,
    treatment = nothing,
    outcome = nothing,
    adjustment = nothing,
    kwargs...
)
    fig = Figure(size = figure_size)
    ax = Axis(fig[1, 1])
    p = dagplot!(
        ax,
        g;
        smart = smart,
        treatment = treatment,
        outcome = outcome,
        adjustment = adjustment,
        kwargs...,
    )
    return fig, ax, p
end

"""
    dagplot!(ax, g; kwargs...)

Plot a DAG into an existing axis with clean, publication-ready styling.

Automatically hides axis decorations, applies DataAspect, and sets appropriate
limits to prevent clipping of nodes and labels.

# Arguments
- `ax`: A Makie Axis object
- `g::AbstractGraph`: A graph from Graphs.jl to plot

# Layout Keyword Arguments
- `layout = Spring()`: Layout algorithm from NetworkLayout.jl
- `padding::Float64 = 0.1`: Padding around graph as fraction of range

# Node Keyword Arguments
- `node_size = 12`: Node marker size in pixels
- `node_color = DEFAULT_NODE_COLOR`: Node fill colour (single value or vector; steel-blue by default)
- `node_strokewidth = 1.0`: Node outline width
- `node_strokecolor = :black`: Node outline colour
- `node_marker = :circle`: Node marker shape

# Edge Keyword Arguments
- `edge_color = :black`: Edge colour
- `edge_width = 1.0`: Edge line width
- `arrow_size = 10`: Arrowhead size
- `arrow_shift = :end`: Arrow position (`:end` or Float64 0-1)
- `elabels = nothing`: Edge labels in `Graphs.edges(g)` order. Accepts plain
  `String`s or Makie `LaTeXString`s (e.g. from [`structural_edge_labels`](@ref)
  with `latex=true`) for structural parameters or short mechanism TeX on edges
- `elabels_fontsize`, `elabels_distance`, `elabels_rotation`, `elabels_side`, …
  : forwarded to GraphMakie (use `elabels_rotation = 0` to keep maths upright)
- `selfedge_size`, `selfedge_direction`, `selfedge_width`: GraphMakie self-loop
  geometry. When the graph has self-loops and `selfedge_size` is omitted,
  DAGMakie defaults to [`DEFAULT_SELFEDGE_SIZE`](@ref) (compact beside the node)

# Label Keyword Arguments
- `nlabels = nothing`: Node labels (vector of strings / `LaTeXString`s, or `nothing`)
- `nlabels_align = (:center, :center)`: Makie **text-box anchor** (or vector of
  anchors). Named sides are edges of the *label*, not “label goes this side of
  the node”: `(:left, :center)` left-anchors the text so it sits to the **right**
  of the node. See the Label Alignment guide.
- `auto_align_labels = false`: When true, place labels **outside** nodes in the
  largest angular gap (sets a positive distance and dark label colour unless you
  override them)
- `nlabels_distance = 0`: Label distance from node in pixels along
  `nlabels_align` (0 centres labels in nodes; with `(:center, :center)` the
  offset is zero regardless of distance—use a non-centred align or
  `auto_align_labels=true` for outside labels)
- `nlabels_fontsize = 16`: Label font size
- `nlabels_color = :white`: Label colour (white on dark node fills)

# Smart / dagitty colouring
- `smart = false`: Set `true` / `:ancestors` for dagitty-style ancestor colours, or
  `:adjustment` to also emphasise a backdoor adjustment set (needs CausalInference
  or `adjustment=`)
- `treatment`, `outcome`: Exposure and outcome node indices (required when `smart` is on)
- `adjustment`: Optional `Set{Int}` for `smart=:adjustment`

# Additional Arguments
- Additional keyword arguments are passed to `GraphMakie.graphplot!`

# Returns
- The GraphPlot object

# Examples
```julia
using Graphs, DAGMakie, CairoMakie

g = SimpleDiGraph(3)
add_edge!(g, 1, 2)
add_edge!(g, 1, 3)
add_edge!(g, 2, 3)

# Simple usage
fig = Figure()
ax = Axis(fig[1, 1])
dagplot!(ax, g, nlabels=["Z", "X", "Y"])

# With node colours indicating roles
dagplot!(ax, g, 
    nlabels=["Confounder", "Treatment", "Outcome"],
    node_color=[NODE_COLOR_CONFOUNDER, DEFAULT_NODE_COLOR, DEFAULT_NODE_COLOR]
)

# Multiple DAGs in one figure
fig = Figure(size=(1200, 400))
ax1, ax2, ax3 = Axis(fig[1, 1]), Axis(fig[1, 2]), Axis(fig[1, 3])
dagplot!(ax1, g1, nlabels=["A", "B", "C"])
dagplot!(ax2, g2, nlabels=["X", "Y", "Z"])
dagplot!(ax3, g3, nlabels=["P", "Q", "R"])
```
"""
function dagplot!(ax, g::Graphs.AbstractGraph;
    # Layout
    layout = nothing,
    layout_mode::Symbol = :auto,
    orientation::Symbol = :lr,
    layer_gap::Real = 2.6,
    node_gap::Real = 1.8,
    component_gap::Real = 3.2,
    scc_radius::Real = 0.9,
    feedback_curvature::Real = 0.75,
    feedback_overlay::Bool = true,
    padding = nothing,
    style::Union{Nothing, DAGStyle} = nothing,
    title = nothing,
    # Smart / dagitty colouring
    smart = false,
    treatment = nothing,
    outcome = nothing,
    adjustment = nothing,
    # Nodes
    node_size = nothing,
    node_color = nothing,
    node_strokewidth = nothing,
    node_strokecolor = nothing,
    node_marker = nothing,
    # Edges
    edge_color = nothing,
    edge_width = nothing,
    edge_linestyle = nothing,
    feedback_color = nothing,
    feedback_width = nothing,
    feedback_linestyle = nothing,
    arrow_size = nothing,
    arrow_shift = nothing,
    waypoints = nothing,
    # Labels
    nlabels = nothing,
    nlabels_align = DEFAULT_LABEL_ALIGN,
    auto_align_labels = false,
    nlabels_distance = nothing,
    nlabels_fontsize = nothing,
    nlabels_color = nothing,
    # Pass-through
    kwargs...
)
    smart_kwargs = apply_smart_kwargs(
        g;
        smart = smart,
        treatment = treatment,
        outcome = outcome,
        adjustment = adjustment,
        node_size = node_size,
        node_color = node_color,
        node_strokewidth = node_strokewidth,
        node_strokecolor = node_strokecolor,
        node_marker = node_marker,
        edge_color = edge_color,
        edge_width = edge_width,
        edge_linestyle = edge_linestyle,
        feedback_color = feedback_color,
        feedback_width = feedback_width,
        feedback_linestyle = feedback_linestyle,
        arrow_size = arrow_size,
        arrow_shift = arrow_shift,
        waypoints = waypoints,
        nlabels = nlabels,
        nlabels_align = nlabels_align,
        auto_align_labels = auto_align_labels,
        nlabels_distance = nlabels_distance,
        nlabels_fontsize = nlabels_fontsize,
        nlabels_color = nlabels_color,
        kwargs...,
    )
    return _dagplot_core!(
        ax,
        g;
        layout = layout,
        layout_mode = layout_mode,
        orientation = orientation,
        layer_gap = layer_gap,
        node_gap = node_gap,
        component_gap = component_gap,
        scc_radius = scc_radius,
        feedback_curvature = feedback_curvature,
        feedback_overlay = feedback_overlay,
        padding = padding,
        style = style,
        title = title,
        smart_kwargs...,
    )
end

