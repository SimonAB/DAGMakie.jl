# SPDX-License-Identifier: MIT

"""Internal `dagplot!` body and `DAGSpec` dispatch."""

"""
Internal plotting body for [`dagplot!`](@ref) after smart-kwargs merging.
"""
function _dagplot_core!(ax, g::Graphs.AbstractGraph;
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
    node_size = nothing,
    node_color = nothing,
    node_strokewidth = nothing,
    node_strokecolor = nothing,
    node_marker = nothing,
    edge_color = nothing,
    edge_width = nothing,
    edge_linestyle = nothing,
    feedback_color = nothing,
    feedback_width = nothing,
    feedback_linestyle = nothing,
    arrow_size = nothing,
    arrow_shift = nothing,
    waypoints = nothing,
    nlabels = nothing,
    nlabels_align = DEFAULT_LABEL_ALIGN,
    auto_align_labels = false,
    nlabels_distance = nothing,
    nlabels_fontsize = nothing,
    nlabels_color = nothing,
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
    # Undirected graphs (e.g. CPDAG skeletons): hide arrowheads unless the caller
    # overrides `arrow_show` / `arrow_size`. GraphMakie defaults `arrow_show` to
    # `is_directed(g)`, but an explicit directed-style `arrow_size` from themes
    # can still leave stubs; force a clean stroke here.
    undirected = !Graphs.is_directed(g)
    user_kwargs = Dict{Symbol, Any}(kwargs)
    if undirected && arrow_size === nothing && !haskey(user_kwargs, :arrow_size)
        resolved_arrow_size = 0
    else
        resolved_arrow_size = something(arrow_size, style_config.arrow_size)
    end
    if undirected && !haskey(user_kwargs, :arrow_show)
        user_kwargs[:arrow_show] = false
    end
    if undirected && edge_color === nothing && !haskey(user_kwargs, :edge_color)
        resolved_edge_color = UNDIRECTED_EDGE_COLOR
    end
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
    feedback_mask = if feedback_overlay
        feedback_edge_mask(g, layout_result)
    else
        falses(edge_count)
    end
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

    # Use package-local auto-align so registry GraphMakie (without
    # `nlabels_auto_align`) still gets sensible label placement.
    # Auto-align is for *outside* labels: with the in-node default
    # (distance 0, white text) non-centred aligns only clip text inside markers.
    resolved_nlabels_align = nlabels_align
    if auto_align_labels && nlabels !== nothing
        auto_settings = resolve_auto_align_label_settings(
            g,
            layout_result.positions;
            align = nlabels_align,
            distance = resolved_label_distance,
            color = resolved_label_color,
            distance_explicit = nlabels_distance !== nothing,
            color_explicit = nlabels_color !== nothing,
        )
        resolved_nlabels_align = auto_settings.align
        resolved_label_distance = auto_settings.distance
        resolved_label_color = auto_settings.color
    elseif nlabels !== nothing &&
            resolved_label_distance > 0 &&
            _is_centred_label_align(resolved_nlabels_align)
        @warn "nlabels_distance=$(resolved_label_distance) has no effect with " *
              "nlabels_align=(:center, :center): GraphMakie offsets along the " *
              "align direction. Use a non-centred nlabels_align (e.g. " *
              "(:center, :bottom)) or auto_align_labels=true for outside labels."
    end

    # Set axis limits *before* `graphplot!`. GraphMakie trims edges using the
    # current `to_px` transform; changing limits afterwards leaves curved (and
    # sometimes straight) edges floating off the markers.
    apply_dag_theme!(ax)
    extra_bound_points = _extra_bound_points(layout_result.edge_waypoints)
    _apply_data_limits!(
        ax,
        layout_result.positions,
        extra_bound_points;
        padding = resolved_padding,
    )

    # Compact self-loops: GraphMakie automatic size is half the nearest-neighbour
    # distance and balloons on typical DAG spacing.
    if _has_self_loops(g) && !haskey(user_kwargs, :selfedge_size)
        user_kwargs[:selfedge_size] = DEFAULT_SELFEDGE_SIZE
    end

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
        nlabels_align = resolved_nlabels_align,
        nlabels_distance = resolved_label_distance,
        nlabels_fontsize = resolved_label_fontsize,
        nlabels_color = resolved_label_color,
        user_kwargs...
    )

    if any(feedback_mask)
        feedback_edges = layout_result.feedback_edges
        overlay_colours = _overlay_values(feedback_color, feedback_edges, edge_lookup, edge_colours)
        overlay_widths = _overlay_values(feedback_width, feedback_edges, edge_lookup, edge_widths)
        overlay_styles = _overlay_values(feedback_linestyle, feedback_edges, edge_lookup, edge_linestyles)
        overlay_arrow_sizes = _overlay_values(nothing, feedback_edges, edge_lookup, edge_arrow_sizes)
        overlay_arrow_shifts = _overlay_values(nothing, feedback_edges, edge_lookup, edge_arrow_shifts)
        overlay_waypoints = [get(layout_result.edge_waypoints, edge, Point2f[]) for edge in feedback_edges]

        _plot_directed_overlay!(
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
            to_px = _plot_to_px(p),
        )
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

