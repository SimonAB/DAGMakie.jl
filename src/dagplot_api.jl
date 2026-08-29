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
- Preferred plot kwargs (full list on [`dagplot!`](@ref)): `labels`,
  `label_position` (`:inner` / `:outer`), `color_by`, `exposure`, `outcome`,
  `label_obstacle_graph`, plus GraphMakie pass-throughs (`nlabels_*`,
  `elabels_*`, …). Legacy aliases (`nlabels`, `smart`, `treatment`,
  `auto_align_labels`, …) still work

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

fig, ax, p = dagplot(g; labels=["X", "Y", "Z"])
save("dag.png", fig)

# Outer labels
fig, ax, p = dagplot(g; labels=["X", "Y", "Z"], label_position=:outer)

# Access node positions
positions = p[:node_pos][]
```
"""
function dagplot(g::Graphs.AbstractGraph;
    figure_size::Tuple{Int, Int} = (600, 400),
    color_by = nothing,
    smart = nothing,
    exposure = nothing,
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
        color_by = color_by,
        smart = smart,
        exposure = exposure,
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
- `layout_mode = :auto`: `:auto` uses a deterministic layered layout for DAGs
  and an SCC-aware layout for cyclic digraphs; `:acyclic` / `:cyclic` force those
  modes; `:spring` uses NetworkLayout `Spring()`. Pass explicit `layout = …`
  (positions or a NetworkLayout algorithm) to bypass the strategy
- `padding::Float64 = 0.1`: Padding around graph as fraction of range
- `layer_gap = 2.6`: Spacing between layered columns (or rows)
- `node_gap = nothing`: Within-layer spacing. Defaults to
  [`DEFAULT_NODE_GAP_INNER`](@ref) (`2.6`) when `label_position=:inner`, and
  [`DEFAULT_NODE_GAP_OUTER`](@ref) (`1.8`) when `label_position=:outer`
- Comparison / intervention helpers reuse a shared [`DAGLayoutResult`](@ref) so
  panels keep the same node positions

# Node Keyword Arguments
- `node_size = DEFAULT_NODE_SIZE`: Node marker size in pixels (theme default 34;
  outer labels use [`OUTER_LABEL_NODE_SIZE`](@ref) unless set explicitly)
- `node_color = DEFAULT_NODE_COLOR`: Node fill colour (single value or vector; steel-blue by default)
- `node_strokewidth = 1.0`: Node outline width
- `node_strokecolor = :black`: Node outline colour
- `node_marker = :circle`: Node marker shape

# Edge Keyword Arguments
- `edge_color = :black`: Edge colour
- `edge_width = 1.0`: Edge line width
- `straight_edges = nothing`: Shorthand for `edge_routing = Dict(e => :straight for e in edges)`
- `edge_routing = nothing`: `Dict((src, dst) => spec)` per-edge routing — straight
  by default; curve with `:curved`, [`CurvedEdge`](@ref) (default bow
  [`DEFAULT_EDGE_BOW`](@ref)), a bow fraction (`Real`), or `CurvedEdge(distance=…)`
  for GraphMakie bend angle ``γ = 2\\operatorname{atan}(2d/L)``
- `long_edge_routing = :quadratic`: Geometry for bowed edges (`:none`, `:natural_cubic`, …)
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
- `labels = nothing`: Node labels (preferred DAGMakie name). `nlabels=` is the
  GraphMakie-compatible alias
- `nlabels_align = (:center, :center)`: Makie **text-box anchor** (or vector of
  anchors). Named sides are edges of the *label*, not “label goes this side of
  the node”: `(:left, :center)` left-anchors the text so it sits to the **right**
  of the node. See the Label Alignment guide.
- `label_position = :outer`: `:outer` (default) places labels outside in the largest
  angular gap (compact [`OUTER_LABEL_NODE_SIZE`](@ref) markers, dark text); `:inner`
  centres labels in the node fill (white text; pass `fit_node_size_to_labels=true`
  for oval markers on long names)
- `auto_align_labels = nothing`: Deprecated synonym for outer labels. Prefer
  `label_position = :outer`. `true` still enables outer placement when
  `label_position` is left at `:inner`
- `label_obstacle_graph = nothing`: Optional graph used only for outer-label
  angle gaps (defaults to the plotted graph). Intervention plots pass the
  factual DAG so grey removed parent edges still count as obstacles.
  Deprecated alias: `auto_align_graph`
- `fit_node_size_to_labels = false`: When true and `label_position=:inner`, size
  in-node markers from each label (short labels stay round; wider labels become
  ovals). Skipped for outer labels or an explicit `node_size`. Pass `true` with
  `label_position=:inner` for fitted in-node markers.
- `nlabels_distance = 0`: Label distance from node in pixels along
  `nlabels_align` (0 centres labels in nodes; with `(:center, :center)` the
  offset is zero regardless of distance—use a non-centred align or
  `label_position = :outer` for outside labels)
- `nlabels_fontsize = 16`: Label font size
- `nlabels_color = :white`: Label colour (white on dark node fills; dark via
  [`OUTER_LABEL_COLOR`](@ref) when `label_position = :outer`)

# Colouring / dagitty roles
- `color_by = nothing`: Set `:ancestors` (or `true`) for dagitty-style ancestor
  colours, or `:adjustment` to also emphasise a backdoor adjustment set (needs
  CausalInference or `adjustment=`). Deprecated alias: `smart`
- `exposure`, `outcome`: Exposure and outcome node indices (required when
  `color_by` is on). `treatment=` is an alias for `exposure=`
- `adjustment`: Optional `Set{Int}` for `color_by=:adjustment`

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
dagplot!(ax, g, labels=["Z", "X", "Y"])

# With node colours indicating roles
dagplot!(ax, g, 
    labels=["Confounder", "Treatment", "Outcome"],
    node_color=[NODE_COLOR_CONFOUNDER, DEFAULT_NODE_COLOR, DEFAULT_NODE_COLOR]
)

# Multiple DAGs in one figure
fig = Figure(size=(1200, 400))
ax1, ax2, ax3 = Axis(fig[1, 1]), Axis(fig[1, 2]), Axis(fig[1, 3])
dagplot!(ax1, g1, labels=["A", "B", "C"])
dagplot!(ax2, g2, labels=["X", "Y", "Z"])
dagplot!(ax3, g3, labels=["P", "Q", "R"])
```
"""
function dagplot!(ax, g::Graphs.AbstractGraph;
    # Layout
    layout = nothing,
    layout_mode::Symbol = :auto,
    orientation::Symbol = :lr,
    layer_gap::Real = 2.6,
    node_gap = nothing,
    component_gap::Real = 3.2,
    scc_radius::Real = 0.9,
    feedback_curvature::Real = 0.75,
    feedback_overlay::Bool = true,
    long_edge_routing::Symbol = :quadratic,
    long_edge_radius::Real = 0.35,
    edge_routing = nothing,
    straight_edges = nothing,
    padding = nothing,
    style::Union{Nothing, DAGStyle} = nothing,
    title = nothing,
    # Colouring / dagitty roles
    color_by = nothing,
    smart = nothing,
    exposure = nothing,
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
    labels = nothing,
    nlabels = nothing,
    nlabels_align = DEFAULT_LABEL_ALIGN,
    label_position::Symbol = DEFAULT_LABEL_POSITION,
    auto_align_labels = nothing,
    label_obstacle_graph = nothing,
    auto_align_graph = nothing,
    fit_node_size_to_labels = false,
    nlabels_distance = nothing,
    nlabels_fontsize = nothing,
    nlabels_color = nothing,
    # Pass-through
    kwargs...
)
    resolved_nlabels = resolve_nlabels(; labels = labels, nlabels = nlabels)
    outer_labels = resolve_outer_labels(label_position; auto_align_labels = auto_align_labels)
    resolved_node_gap = resolve_node_gap(node_gap; outer_labels = outer_labels)
    resolved_obstacle = resolve_label_obstacle_graph(;
        label_obstacle_graph = label_obstacle_graph,
        auto_align_graph = auto_align_graph,
    )
    resolved_color_by = resolve_color_by(; color_by = color_by, smart = smart)
    resolved_exposure = resolve_exposure(; exposure = exposure, treatment = treatment)
    smart_kwargs = apply_smart_kwargs(
        g;
        color_by = resolved_color_by,
        exposure = resolved_exposure,
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
        nlabels = resolved_nlabels,
        nlabels_align = nlabels_align,
        label_position = label_position,
        auto_align_labels = outer_labels,
        label_obstacle_graph = resolved_obstacle,
        fit_node_size_to_labels = fit_node_size_to_labels,
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
        node_gap = resolved_node_gap,
        component_gap = component_gap,
        scc_radius = scc_radius,
        feedback_curvature = feedback_curvature,
        feedback_overlay = feedback_overlay,
        long_edge_routing = long_edge_routing,
        long_edge_radius = long_edge_radius,
        edge_routing = edge_routing,
        straight_edges = straight_edges,
        padding = padding,
        style = style,
        title = title,
        smart_kwargs...,
    )
end

