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
    kwargs...
)
    fig = Figure(size = figure_size)
    ax = Axis(fig[1, 1])
    p = dagplot!(ax, g; kwargs...)
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
- `node_color = :lightblue`: Node fill colour (single value or vector)
- `node_strokewidth = 1.0`: Node outline width
- `node_strokecolor = :black`: Node outline colour
- `node_marker = :circle`: Node marker shape

# Edge Keyword Arguments
- `edge_color = :black`: Edge colour
- `edge_width = 1.0`: Edge line width
- `arrow_size = 10`: Arrowhead size
- `arrow_shift = :end`: Arrow position (`:end` or Float64 0-1)

# Label Keyword Arguments
- `nlabels = nothing`: Node labels (vector of strings, or `nothing`)
- `nlabels_align = (:right, :bottom)`: Label alignment (or vector)
- `auto_align_labels = true`: Automatically compute label alignment to avoid edges
- `nlabels_distance = 10`: Label distance from node in pixels
- `nlabels_fontsize = 14`: Label font size
- `nlabels_color = :black`: Label colour

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
    node_color=[:yellow, :lightgreen, :lightblue]
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
    padding = nothing,
    style::Union{Nothing, DAGStyle} = nothing,
    title = nothing,
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
    auto_align_labels = true,
    nlabels_distance = nothing,
    nlabels_fontsize = nothing,
    nlabels_color = nothing,
    # Pass-through
    kwargs...
)
    style_config = _resolve_style(style)

    resolved_padding = something(padding, style_config.padding)
    resolved_node_size = something(node_size, style_config.node_size)
    resolved_node_color = something(node_color, style_config.node_color)
    resolved_node_strokewidth = something(node_strokewidth, style_config.node_strokewidth)
    resolved_node_strokecolor = something(node_strokecolor, style_config.node_strokecolor)
    resolved_node_marker = something(node_marker, :circle)
    resolved_edge_color = something(edge_color, style_config.edge_color)
    resolved_edge_width = something(edge_width, style_config.edge_width)
    resolved_edge_linestyle = something(edge_linestyle, :solid)
    resolved_arrow_size = something(arrow_size, style_config.arrow_size)
    resolved_arrow_shift = something(arrow_shift, style_config.arrow_shift)
    resolved_label_distance = something(nlabels_distance, style_config.label_distance)
    resolved_label_fontsize = something(nlabels_fontsize, style_config.label_fontsize)
    resolved_label_color = something(nlabels_color, style_config.label_color)

    node_count = Graphs.nv(g)
    edge_count = Graphs.ne(g)
    node_sizes = _fill_attribute(resolved_node_size, node_count)
    node_colours = _fill_attribute(resolved_node_color, node_count)
    node_strokewidths = _fill_attribute(resolved_node_strokewidth, node_count)
    node_strokecolours = _fill_attribute(resolved_node_strokecolor, node_count)
    node_markers = _fill_attribute(resolved_node_marker, node_count)
    edge_colours = _fill_attribute(resolved_edge_color, edge_count)
    edge_widths = _fill_attribute(resolved_edge_width, edge_count)
    edge_linestyles = _fill_attribute(resolved_edge_linestyle, edge_count)
    edge_arrow_sizes = _fill_attribute(resolved_arrow_size, edge_count)
    edge_arrow_shifts = _fill_attribute(resolved_arrow_shift, edge_count)

    layout_result = compute_graph_layout(
        g;
        layout = layout,
        layout_mode = layout_mode,
        orientation = orientation,
        layer_gap = layer_gap,
        node_gap = node_gap,
        component_gap = component_gap,
        scc_radius = scc_radius,
        feedback_curvature = feedback_curvature,
    )

    edge_lookup = _edge_index_lookup(g)
    feedback_mask = feedback_edge_mask(g, layout_result)
    user_waypoints = _materialise_waypoints(g, waypoints)
    base_waypoints = [
        feedback_mask[index] ? Point2f[] : user_waypoints[index]
        for index in 1:edge_count
    ]
    base_edge_colours = any(feedback_mask) ? Any[edge_colours...] : copy(edge_colours)
    base_edge_widths = copy(edge_widths)
    for index in eachindex(feedback_mask)
        if feedback_mask[index]
            base_edge_colours[index] = RGBAf(0, 0, 0, 0)
            base_edge_widths[index] = 0.0
        end
    end

    use_graphmakie_auto_align = auto_align_labels && nlabels !== nothing

    p = graphplot!(ax, g;
        layout = layout_result.positions,
        node_size = node_sizes,
        node_color = node_colours,
        node_strokewidth = node_strokewidths,
        node_strokecolor = node_strokecolours,
        node_marker = node_markers,
        edge_color = base_edge_colours,
        edge_width = base_edge_widths,
        edge_linestyle = edge_linestyles,
        arrow_size = edge_arrow_sizes,
        arrow_shift = edge_arrow_shifts,
        waypoints = base_waypoints,
        nlabels = nlabels,
        nlabels_align = nlabels_align,
        nlabels_auto_align = use_graphmakie_auto_align,
        nlabels_distance = resolved_label_distance,
        nlabels_fontsize = resolved_label_fontsize,
        nlabels_color = resolved_label_color,
        kwargs...
    )

    apply_dag_theme!(ax)

    feedback_bound_points = Point2f[]
    if any(feedback_mask)
        feedback_edges = layout_result.feedback_edges
        overlay_colours = _overlay_values(feedback_color, feedback_edges, edge_lookup, edge_colours)
        overlay_widths = _overlay_values(feedback_width, feedback_edges, edge_lookup, edge_widths)
        overlay_styles = _overlay_values(feedback_linestyle, feedback_edges, edge_lookup, edge_linestyles)
        overlay_arrow_sizes = _overlay_values(nothing, feedback_edges, edge_lookup, edge_arrow_sizes)
        overlay_arrow_shifts = _overlay_values(nothing, feedback_edges, edge_lookup, edge_arrow_shifts)
        overlay_waypoints = [get(layout_result.edge_waypoints, edge, Point2f[]) for edge in feedback_edges]

        feedback_bound_points = _plot_directed_overlay!(
            ax,
            feedback_edges,
            layout_result.positions;
            node_sizes = node_sizes,
            node_markers = node_markers,
            edge_colours = overlay_colours,
            edge_widths = overlay_widths,
            edge_linestyles = overlay_styles,
            arrow_sizes = overlay_arrow_sizes,
            arrow_shifts = overlay_arrow_shifts,
            waypoints = overlay_waypoints,
            to_px = p[:to_px][],
        )
    end

    tightlimits!(ax)
    node_positions = p[:node_pos][]
    extra_bound_points = _extra_bound_points(layout_result.edge_waypoints)
    append!(extra_bound_points, feedback_bound_points)

    if !isempty(node_positions)
        if nlabels !== nothing
            label_aligns = p[:nlabels_align_processed][]
            xlim, ylim = compute_padded_limits(
                node_positions,
                nlabels,
                label_aligns,
                resolved_label_distance,
                resolved_label_fontsize;
                padding = resolved_padding,
                to_px = p[:to_px][],
                extra_points = extra_bound_points,
            )
        else
            xlim, ylim = compute_padded_limits(
                node_positions,
                nothing,
                nlabels_align,
                resolved_label_distance,
                resolved_label_fontsize;
                padding = resolved_padding,
                extra_points = extra_bound_points,
            )
        end

        xlims!(ax, xlim)
        ylims!(ax, ylim)
    end

    if title !== nothing
        ax.title = title
    end

    return p
end

"""
    dagplot(spec::DAGSpec; kwargs...)

Plot a DAG from a DAGSpec specification.

# Arguments
- `spec::DAGSpec`: A DAG specification with graph, nodes, and edges

# Keyword Arguments
- Same as `dagplot(g; kwargs...)`

# Returns
- Tuple `(fig, ax, p)`
"""
function dagplot(spec::DAGSpec;
    figure_size::Tuple{Int, Int} = (600, 400),
    kwargs...
)
    merged_kwargs = _merge_default_kwargs(kwargs, _spec_defaults(spec, kwargs))
    return dagplot(spec.graph; figure_size = figure_size, merged_kwargs...)
end

"""
    dagplot!(ax, spec::DAGSpec; kwargs...)

Plot a DAG from a DAGSpec specification into an existing axis.
"""
function dagplot!(ax, spec::DAGSpec; kwargs...)
    merged_kwargs = _merge_default_kwargs(kwargs, _spec_defaults(spec, kwargs))
    return dagplot!(ax, spec.graph; merged_kwargs...)
end

function _resolve_style(style::Union{Nothing, DAGStyle})
    return style === nothing ? default_style() : style
end

function _fill_attribute(value, count::Int)
    if value isa AbstractVector && !(value isa AbstractString)
        @assert length(value) == count "Attribute length must match the graph size."
        return collect(value)
    end

    return fill(value, count)
end

function _edge_index_lookup(g::Graphs.AbstractGraph)
    return Dict((Graphs.src(edge), Graphs.dst(edge)) => index for (index, edge) in enumerate(Graphs.edges(g)))
end

function _materialise_waypoints(g::Graphs.AbstractGraph, waypoints)
    edge_count = Graphs.ne(g)
    if waypoints === nothing
        return [Point2f[] for _ in 1:edge_count]
    elseif waypoints isa AbstractVector
        @assert length(waypoints) == edge_count "Waypoint vector must match the number of edges."
        return [Point2f.(points) for points in waypoints]
    elseif waypoints isa AbstractDict
        materialised = [Point2f[] for _ in 1:edge_count]
        for (index, points) in waypoints
            materialised[index] = Point2f.(points)
        end
        return materialised
    end

    error("Unsupported waypoints specification $(typeof(waypoints)).")
end

"""
    compute_feedback_geometry(edge_pairs, positions, node_markers, node_sizes, waypoints, to_px;
        arrow_size=8, arrow_shift=:end)

Compute boundary-aware paths and arrowheads for curved directed feedback edges.
"""
function compute_feedback_geometry(
    edge_pairs::Vector{Tuple{Int, Int}},
    positions::AbstractVector,
    node_markers,
    node_sizes,
    waypoints::AbstractVector,
    to_px;
    arrow_size = 8,
    arrow_shift = :end,
)
    @assert length(waypoints) == length(edge_pairs) "Waypoint vector must match the number of feedback edges."

    paths = Vector{Vector{Point2f}}()
    arrow_positions = Point2f[]
    arrow_rotations = Float64[]
    arrow_sizes = Float64[]
    boundary_points = Point2f[]

    for (index, (source, destination)) in enumerate(edge_pairs)
        raw_path = _feedback_curve_path(
            Point2f(positions[source]),
            Point2f(positions[destination]),
            waypoints[index],
        )
        start_distance = distance_between_markers(
            _attribute_value(node_markers, source),
            _attribute_value(node_sizes, source),
            :circle,
            0,
        )
        arrow_size_value = Float64(_attribute_value(arrow_size, index))
        end_distance = distance_between_markers(
            _attribute_value(node_markers, destination),
            _attribute_value(node_sizes, destination),
            Arrow,
            arrow_size_value,
        )

        trimmed_path = trim_polyline(raw_path, start_distance, end_distance, to_px)
        if length(trimmed_path) < 2 || polyline_length_px(trimmed_path, to_px) <= 1e-6
            trimmed_path = raw_path
        end

        push!(paths, trimmed_path)
        append!(boundary_points, trimmed_path)

        arrow_position, arrow_rotation = _feedback_arrow_pose(
            trimmed_path,
            to_px,
            _attribute_value(arrow_shift, index),
        )
        push!(arrow_positions, arrow_position)
        push!(arrow_rotations, arrow_rotation)
        push!(arrow_sizes, arrow_size_value)
    end

    return (
        paths = paths,
        arrow_positions = arrow_positions,
        arrow_rotations = arrow_rotations,
        arrow_sizes = arrow_sizes,
        boundary_points = boundary_points,
    )
end

function _plot_directed_overlay!(
    ax,
    edge_pairs::Vector{Tuple{Int, Int}},
    positions::Vector{Point2f};
    node_sizes,
    node_markers,
    edge_colours,
    edge_widths,
    edge_linestyles,
    arrow_sizes,
    arrow_shifts,
    waypoints,
    to_px,
)
    isempty(edge_pairs) && return Point2f[]

    geometry = compute_feedback_geometry(
        edge_pairs,
        positions,
        node_markers,
        node_sizes,
        waypoints,
        to_px;
        arrow_size = arrow_sizes,
        arrow_shift = arrow_shifts,
    )

    for (index, path) in enumerate(geometry.paths)
        lines!(ax, path;
            color = edge_colours[index],
            linewidth = edge_widths[index],
            linestyle = edge_linestyles[index],
        )
    end

    if !isempty(geometry.arrow_positions)
        scatter!(ax, geometry.arrow_positions;
            marker = Arrow,
            markersize = geometry.arrow_sizes,
            color = edge_colours,
            rotation = geometry.arrow_rotations,
            markerspace = :pixel,
        )
    end

    return geometry.boundary_points
end

function _feedback_curve_path(p1::Point2f, p2::Point2f, waypoints::AbstractVector)
    control_points = Point2f.(waypoints)
    if isempty(control_points)
        return Point2f[p1, p2]
    elseif length(control_points) == 1
        midpoint = (p1 + p2) / 2
        control = 2f0 * control_points[1] - midpoint
        return _quadratic_bezier_path(p1, control, p2)
    end

    return _chaikin_smooth_path(vcat(Point2f[p1], control_points, Point2f[p2]))
end

function _quadratic_bezier_path(p1::Point2f, control::Point2f, p2::Point2f; n_points::Int = 32)
    path = Vector{Point2f}(undef, n_points)
    for index in 1:n_points
        t = Float32((index - 1) / (n_points - 1))
        path[index] = (1 - t)^2 * p1 + 2f0 * (1 - t) * t * control + t^2 * p2
    end
    return path
end

function _chaikin_smooth_path(points::Vector{Point2f}; refinements::Int = 2)
    smoothed = copy(points)
    for _ in 1:refinements
        next_points = Point2f[first(smoothed)]
        for index in 1:(length(smoothed) - 1)
            p1 = smoothed[index]
            p2 = smoothed[index + 1]
            push!(next_points, 0.75f0 * p1 + 0.25f0 * p2)
            push!(next_points, 0.25f0 * p1 + 0.75f0 * p2)
        end
        push!(next_points, last(smoothed))
        smoothed = next_points
    end
    return smoothed
end

function _feedback_arrow_pose(path::AbstractVector, to_px, arrow_shift)
    if length(path) < 2
        return Point2f(path[1]), 0.0
    elseif arrow_shift === :end
        return last(path), _polyline_rotation(path, to_px; from_start = false, reverse_direction = false)
    end

    total_length = polyline_length_px(path, to_px)
    distance_px = clamp(Float64(arrow_shift), 0.0, 1.0) * total_length
    position = polyline_point_at_distance(path, distance_px, to_px; from_start = true)
    rotation = _polyline_rotation_at_distance(path, distance_px, to_px)
    return position, rotation
end

function _polyline_rotation_at_distance(path::AbstractVector, distance_px::Real, to_px)
    ordered_points = Point2f.(path)
    target = clamp(Float64(distance_px), 0.0, polyline_length_px(ordered_points, to_px))
    traversed = 0.0

    for index in 1:(length(ordered_points) - 1)
        p1 = ordered_points[index]
        p2 = ordered_points[index + 1]
        tangent_px = to_px(p2) - to_px(p1)
        segment_length_px = norm(tangent_px)
        if segment_length_px <= 1e-6
            continue
        end

        if traversed + segment_length_px >= target
            return atan(tangent_px[2], tangent_px[1])
        end

        traversed += segment_length_px
    end

    return _polyline_rotation(ordered_points, to_px; from_start = false, reverse_direction = false)
end

function _overlay_values(override, edge_pairs, edge_lookup, base_values)
    if override === nothing
        return [base_values[edge_lookup[edge]] for edge in edge_pairs]
    end

    return _fill_attribute(override, length(edge_pairs))
end

function _extra_bound_points(edge_waypoints::Dict{Tuple{Int, Int}, Vector{Point2f}})
    points = Point2f[]
    for waypoint_set in values(edge_waypoints)
        append!(points, waypoint_set)
    end
    return points
end

function _merge_default_kwargs(kwargs, defaults::NamedTuple)
    merged = Dict{Symbol, Any}(pairs(defaults))
    for (key, value) in kwargs
        merged[key] = value
    end
    return (; merged...)
end

function _spec_defaults(spec::DAGSpec, kwargs)
    style = haskey(kwargs, :style) ? kwargs[:style] : nothing
    style_config = _resolve_style(style)
    node_types = [node.type for node in spec.nodes]
    node_count = length(spec.nodes)

    labels = [node.label for node in spec.nodes]
    node_colours = [node.color !== nothing ? node.color : node_type_color(node.type) for node in spec.nodes]
    node_sizes = [node.size !== nothing ? node.size : style_config.node_size for node in spec.nodes]
    node_markers = [node.marker !== nothing ? node.marker : node_type_marker(node.type) for node in spec.nodes]
    node_strokewidths = [node_type_strokewidth(node_type) for node_type in node_types]
    node_strokecolours = [node_type_strokecolor(node_type) for node_type in node_types]

    edge_colours = fill(style_config.edge_color, Graphs.ne(spec.graph))
    edge_widths = fill(style_config.edge_width, Graphs.ne(spec.graph))
    edge_styles = fill(:solid, Graphs.ne(spec.graph))
    edge_lookup = _edge_index_lookup(spec.graph)

    for edge in spec.edges
        if !haskey(edge_lookup, (edge.src, edge.dst))
            continue
        end

        index = edge_lookup[(edge.src, edge.dst)]
        if edge.color !== nothing
            edge_colours[index] = edge.color
        end
        if edge.width !== nothing
            edge_widths[index] = edge.width
        end
        if edge.style !== nothing
            edge_styles[index] = edge.style
        end
    end

    return (
        nlabels = labels,
        node_color = node_colours,
        node_size = node_sizes,
        node_marker = node_markers,
        node_strokewidth = node_strokewidths,
        node_strokecolor = node_strokecolours,
        edge_color = edge_colours,
        edge_width = edge_widths,
        edge_linestyle = edge_styles,
        title = spec.title,
    )
end

# =============================================================================
# Convenience functions for common patterns
# =============================================================================

"""
    dagplot_chain(labels; kwargs...)

Plot a simple chain DAG: X₁ → X₂ → ... → Xₙ

# Arguments
- `labels::Vector{String}`: Labels for each node in the chain
- `kwargs...`: Additional arguments passed to `dagplot`

# Returns
- Tuple `(fig, ax, p)`
"""
function dagplot_chain(labels::Vector{String}; kwargs...)
    g, _ = chain_graph(labels)
    return dagplot(g; nlabels = labels, kwargs...)
end

"""
    dagplot_fork(labels; kwargs...)

Plot a fork DAG: X₁ ← X₂ → X₃

# Arguments
- `labels::Vector{String}`: Labels [left, fork, right]
- `kwargs...`: Additional arguments passed to `dagplot`
"""
function dagplot_fork(labels::Vector{String}; kwargs...)
    g, _ = fork_graph(labels)
    return dagplot(g; nlabels = labels, kwargs...)
end

"""
    dagplot_collider(labels; kwargs...)

Plot a collider DAG: X₁ → X₂ ← X₃

# Arguments
- `labels::Vector{String}`: Labels [left, collider, right]
- `kwargs...`: Additional arguments passed to `dagplot`
"""
function dagplot_collider(labels::Vector{String}; kwargs...)
    g, _ = collider_graph(labels)
    return dagplot(g; nlabels = labels, kwargs...)
end

"""
    dagplot_confounding(labels; kwargs...)

Plot a confounding DAG: Z → X → Y, Z → Y

# Arguments
- `labels::Vector{String}`: Labels [confounder, treatment, outcome]
- `kwargs...`: Additional arguments passed to `dagplot`
"""
function dagplot_confounding(labels::Vector{String}; kwargs...)
    g, _ = confounding_graph(labels)
    return dagplot(g; nlabels = labels, kwargs...)
end

"""
    dagplot_mediation(labels; kwargs...)

Plot a mediation DAG: X → M → Y, X → Y

# Arguments
- `labels::Vector{String}`: Labels [treatment, mediator, outcome]
- `kwargs...`: Additional arguments passed to `dagplot`
"""
function dagplot_mediation(labels::Vector{String}; kwargs...)
    g, _ = mediation_graph(labels)
    return dagplot(g; nlabels = labels, kwargs...)
end

# =============================================================================
# Mixed Graph (Bidirected Edge) Support
# =============================================================================

"""
    dagplot(mg::MixedGraph; kwargs...)

Create a DAG visualisation with both directed and bidirected edges.

Bidirected edges (↔) are rendered as curved arcs with double arrowheads,
representing unmeasured common causes (latent confounders).

# Additional Keyword Arguments
- `bidirected_color = :gray`: Colour for bidirected edges
- `bidirected_width = 1.0`: Line width for bidirected edges
- `bidirected_style = :dash`: Line style for bidirected edges
- `bidirected_curvature = 0.3`: Curvature of bidirected arcs
- `bidirected_arrow_size = 8`: Size of arrowheads on bidirected edges

# Examples
```julia
using DAGMakie, CairoMakie

# Confounded treatment-outcome
mg = mixed_graph(2, [(1, 2)], [(1, 2)])  # X → Y with X ↔ Y
fig, ax, p = dagplot(mg, nlabels=["X", "Y"])

# Instrumental variable with confounding
mg = mixed_graph(3, [(1, 2), (2, 3)], [(2, 3)])  # Z → X → Y, X ↔ Y
fig, ax, p = dagplot(mg, nlabels=["Z", "X", "Y"])
```
"""
function dagplot(mg::MixedGraph;
    figure_size::Tuple{Int, Int} = (600, 400),
    kwargs...
)
    fig = Figure(size = figure_size)
    ax = Axis(fig[1, 1])
    p = dagplot!(ax, mg; kwargs...)
    return fig, ax, p
end

"""
    dagplot!(ax, mg::MixedGraph; kwargs...)

Plot a MixedGraph (with bidirected edges) into an existing axis.
"""
function dagplot!(ax, mg::MixedGraph;
    # Layout
    layout = nothing,
    layout_mode::Symbol = :auto,
    orientation::Symbol = :lr,
    layer_gap::Real = 2.6,
    node_gap::Real = 1.8,
    component_gap::Real = 3.2,
    scc_radius::Real = 0.9,
    feedback_curvature::Real = 0.75,
    padding = nothing,
    style::Union{Nothing, DAGStyle} = nothing,
    title = nothing,
    # Nodes
    node_size = nothing,
    node_color = nothing,
    node_strokewidth = nothing,
    node_strokecolor = nothing,
    node_marker = nothing,
    # Directed edges
    edge_color = nothing,
    edge_width = nothing,
    edge_linestyle = nothing,
    feedback_color = nothing,
    feedback_width = nothing,
    feedback_linestyle = nothing,
    arrow_size = nothing,
    arrow_shift = nothing,
    waypoints = nothing,
    # Bidirected edges
    bidirected_color = :gray,
    bidirected_width = 1.0,
    bidirected_style = :dash,
    bidirected_curvature = 0.3,
    bidirected_arrow_size = 8,
    # Labels
    nlabels = nothing,
    nlabels_align = DEFAULT_LABEL_ALIGN,
    auto_align_labels = true,
    nlabels_distance = nothing,
    nlabels_fontsize = nothing,
    nlabels_color = nothing,
    # Pass-through
    kwargs...
)
    p = dagplot!(ax, mg.directed;
        layout = layout,
        layout_mode = layout_mode,
        orientation = orientation,
        layer_gap = layer_gap,
        node_gap = node_gap,
        component_gap = component_gap,
        scc_radius = scc_radius,
        feedback_curvature = feedback_curvature,
        padding = padding,
        style = style,
        title = title,
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
        kwargs...
    )

    if num_bidirected_edges(mg) > 0
        positions = p[:node_pos][]
        style_config = _resolve_style(style)
        resolved_node_size = _fill_attribute(something(node_size, style_config.node_size), Graphs.nv(mg))
        resolved_node_marker = _fill_attribute(something(node_marker, :circle), Graphs.nv(mg))
        geometry = compute_bidirected_geometry(
            mg,
            positions,
            resolved_node_marker,
            resolved_node_size,
            p[:to_px][];
            curvature = bidirected_curvature,
            arrow_size = bidirected_arrow_size,
        )

        for path in geometry.paths
            lines!(ax, path;
                color = bidirected_color,
                linewidth = bidirected_width,
                linestyle = bidirected_style
            )
        end

        if !isempty(geometry.arrow_positions)
            scatter!(ax, geometry.arrow_positions;
                marker = Arrow,
                markersize = bidirected_arrow_size,
                color = bidirected_color,
                rotation = geometry.arrow_rotations,
                markerspace = :pixel
            )
        end

        extra_points = geometry.boundary_points
        if !isempty(extra_points)
            style_config = _resolve_style(style)
            resolved_padding = something(padding, style_config.padding)
            resolved_label_distance = something(nlabels_distance, style_config.label_distance)
            resolved_label_fontsize = something(nlabels_fontsize, style_config.label_fontsize)

            if nlabels !== nothing
                xlim, ylim = compute_padded_limits(
                    positions,
                    nlabels,
                    p[:nlabels_align_processed][],
                    resolved_label_distance,
                    resolved_label_fontsize;
                    padding = resolved_padding,
                    to_px = p[:to_px][],
                    extra_points = extra_points,
                )
            else
                xlim, ylim = compute_padded_limits(
                    positions,
                    nothing,
                    nlabels_align,
                    resolved_label_distance,
                    resolved_label_fontsize;
                    padding = resolved_padding,
                    extra_points = extra_points,
                )
            end

            xlims!(ax, xlim)
            ylims!(ax, ylim)
        end
    end

    return p
end

# =============================================================================
# Convenience functions for mixed graphs
# =============================================================================

"""
    dagplot_confounded(labels; kwargs...)

Plot a simple confounded graph: X → Y with X ↔ Y.

# Arguments
- `labels::Vector{String}`: Labels [treatment, outcome]
"""
function dagplot_confounded(labels::Vector{String}; kwargs...)
    mg, _ = confounded_graph(labels)
    return dagplot(mg; nlabels = labels, kwargs...)
end

"""
    dagplot_frontdoor(labels; kwargs...)

Plot a frontdoor criterion graph: X → M → Y with X ↔ Y.

# Arguments
- `labels::Vector{String}`: Labels [treatment, mediator, outcome]
"""
function dagplot_frontdoor(labels::Vector{String}; kwargs...)
    mg, _ = frontdoor_graph(labels)
    return dagplot(mg; nlabels = labels, kwargs...)
end

"""
    dagplot_iv_confounded(labels; kwargs...)

Plot an IV graph with confounding: Z → X → Y, X ↔ Y.

# Arguments
- `labels::Vector{String}`: Labels [instrument, treatment, outcome]
"""
function dagplot_iv_confounded(labels::Vector{String}; kwargs...)
    mg, _ = iv_confounded_graph(labels)
    return dagplot(mg; nlabels = labels, kwargs...)
end

"""
    dagplot_m_bias(labels; kwargs...)

Plot an M-bias graph: X → Y with X ↔ M ↔ Y.

# Arguments
- `labels::Vector{String}`: Labels [treatment, collider, outcome]
"""
function dagplot_m_bias(labels::Vector{String}; kwargs...)
    mg, _ = m_bias_graph(labels)
    return dagplot(mg; nlabels = labels, kwargs...)
end
