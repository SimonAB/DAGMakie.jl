# SPDX-License-Identifier: MIT

"""Convenience DAG patterns and MixedGraph `dagplot` methods."""

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
    fit_labels = get(kwargs, :fit_node_size_to_labels, true) !== false
    outer_labels = resolve_outer_labels(
        get(kwargs, :label_position, DEFAULT_LABEL_POSITION);
        auto_align_labels = get(kwargs, :auto_align_labels, nothing),
    )
    fontsize = haskey(kwargs, :nlabels_fontsize) && kwargs[:nlabels_fontsize] !== nothing ?
        kwargs[:nlabels_fontsize] : style_config.label_fontsize

    labels = [node.label for node in spec.nodes]
    node_colours = [node.color !== nothing ? node.color : node_type_color(node.type) for node in spec.nodes]
    node_sizes = Vector{Any}(undef, node_count)
    node_markers = Vector{Any}(undef, node_count)
    for (i, node) in enumerate(spec.nodes)
        default_marker = node.marker !== nothing ? node.marker : node_type_marker(node.type)
        if node.size !== nothing
            node_sizes[i] = node.size
            node_markers[i] = default_marker
        elseif fit_labels && !outer_labels
            size_i, marker_i = node_size_for_inner_label(
                node.label;
                fontsize = fontsize,
                marker = node.marker === nothing ? :auto : node.marker,
            )
            node_sizes[i] = size_i
            node_markers[i] = node.marker === nothing ? marker_i : default_marker
        else
            node_sizes[i] = style_config.node_size
            node_markers[i] = default_marker
        end
    end
    node_strokewidths = [node_type_strokewidth(node_type) for node_type in node_types]
    node_strokecolours = [node_type_strokecolor(node_type) for node_type in node_types]
    label_colours = [node_type_label_color(node_type) for node_type in node_types]

    edge_colours = fill(style_config.edge_color, Graphs.ne(spec.graph))
    edge_widths = fill(style_config.edge_width, Graphs.ne(spec.graph))
    edge_styles = fill(:solid, Graphs.ne(spec.graph))
    edge_lookup = _edge_index_lookup(spec.graph)

    for edge in spec.edges
        if !haskey(edge_lookup, (edge.src, edge.dst))
            continue
        end

        index = edge_lookup[(edge.src, edge.dst)]
        if edge.type == Modifier
            edge_colours[index] = something(edge.color, MODIFIER_EDGE_COLOR)
            edge_widths[index] = something(edge.width, MODIFIER_EDGE_WIDTH)
            edge_styles[index] = something(edge.style, MODIFIER_EDGE_STYLE)
        else
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
    end

    return (
        nlabels = labels,
        node_color = node_colours,
        node_size = node_sizes,
        node_marker = node_markers,
        node_strokewidth = node_strokewidths,
        node_strokecolor = node_strokecolours,
        nlabels_color = label_colours,
        edge_color = edge_colours,
        edge_width = edge_widths,
        edge_linestyle = edge_styles,
        title = spec.title,
    )
end

# =============================================================================
# Convenience functions for common patterns
# =============================================================================

# Pedagogical layouts: layered :acyclic placement puts one node per column for
# confounding/mediation-style graphs, hiding shortcut or bidirected edges.
const _LAYOUT_TRIANGLE_APEX_TOP = Point2f[
    Point2f(0.0, 1.0),
    Point2f(-1.0, 0.0),
    Point2f(1.0, 0.0),
]
const _LAYOUT_TRIANGLE_MEDIATOR_TOP = Point2f[
    Point2f(-1.0, 0.0),
    Point2f(0.0, 1.0),
    Point2f(1.0, 0.0),
]
# Classic M-bias letter shape: latents on top, X–M–Y along the base.
const _LAYOUT_M_BIAS = Point2f[
    Point2f(-1.0, 1.35),  # U₁
    Point2f(1.0, 1.35),   # U₂
    Point2f(-1.6, 0.0),   # X
    Point2f(0.0, 0.0),    # M (collider)
    Point2f(1.6, 0.0),    # Y
]
const _LAYOUT_PAIR_HORIZONTAL = Point2f[
    Point2f(-1.0, 0.0),
    Point2f(1.0, 0.0),
]

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
    return dagplot(g; labels = labels, kwargs...)
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
    return dagplot(g; labels = labels, kwargs...)
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
    return dagplot(g; labels = labels, kwargs...)
end

"""
    dagplot_confounding(labels; kwargs...)

Plot a confounding DAG: Z → X → Y, Z → Y.

Uses a triangle layout by default (confounder on top, treatment and outcome
below). Layered left-to-right layout places one node per layer and draws the
backdoor edge through the treatment node; pass `layout` to override.

# Arguments
- `labels::Vector{String}`: Labels [confounder, treatment, outcome]
- `kwargs...`: Additional arguments passed to `dagplot`
"""
function dagplot_confounding(
    labels::Vector{String};
    layout = _LAYOUT_TRIANGLE_APEX_TOP,
    kwargs...,
)
    g, _ = confounding_graph(labels)
    return dagplot(g; labels = labels, layout = layout, kwargs...)
end

"""
    dagplot_mediation(labels; kwargs...)

Plot a mediation DAG: X → M → Y, X → Y.

Uses a triangle layout by default (mediator on top, treatment and outcome
below). Layered left-to-right layout places one node per layer and draws the
direct effect through the mediator; pass `layout` to override.

# Arguments
- `labels::Vector{String}`: Labels [treatment, mediator, outcome]
- `kwargs...`: Additional arguments passed to `dagplot`
"""
function dagplot_mediation(
    labels::Vector{String};
    layout = _LAYOUT_TRIANGLE_MEDIATOR_TOP,
    kwargs...,
)
    g, _ = mediation_graph(labels)
    return dagplot(g; labels = labels, layout = layout, kwargs...)
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
fig, ax, p = dagplot(mg, labels=["X", "Y"])

# Instrumental variable with confounding
mg = mixed_graph(3, [(1, 2), (2, 3)], [(2, 3)])  # Z → X → Y, X ↔ Y
fig, ax, p = dagplot(mg, labels=["Z", "X", "Y"])
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

Accepts the same preferred label kwargs as [`dagplot!`](@ref) on
`AbstractGraph` (`labels`, `label_position`, …), plus bidirected-edge styling
(`bidirected_color`, `bidirected_width`, …).
"""
function dagplot!(ax, mg::MixedGraph;
    # Layout
    layout = nothing,
    layout_mode::Symbol = :auto,
    orientation::Symbol = :lr,
    layer_gap::Real = 2.6,
    node_gap = nothing,
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
    labels = nothing,
    nlabels = nothing,
    nlabels_align = DEFAULT_LABEL_ALIGN,
    label_position::Symbol = DEFAULT_LABEL_POSITION,
    auto_align_labels = nothing,
    nlabels_distance = nothing,
    nlabels_fontsize = nothing,
    nlabels_color = nothing,
    # Pass-through
    kwargs...
)
    nlabels = resolve_nlabels(; labels = labels, nlabels = nlabels)
    outer_labels = resolve_outer_labels(label_position; auto_align_labels = auto_align_labels)
    resolved_node_gap = resolve_node_gap(node_gap; outer_labels = outer_labels)
    p = dagplot!(ax, mg.directed;
        layout = layout,
        layout_mode = layout_mode,
        orientation = orientation,
        layer_gap = layer_gap,
        node_gap = resolved_node_gap,
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
        label_position = outer_labels ? :outer : :inner,
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
        resolved_padding = something(padding, style_config.padding)
        resolved_label_distance = something(nlabels_distance, style_config.label_distance)
        resolved_label_fontsize = something(nlabels_fontsize, style_config.label_fontsize)

        # Set limits from raw arcs before trimming (same to_px ordering as feedback overlays).
        raw_paths = compute_all_bidirected_paths(mg, positions; curvature = bidirected_curvature)
        raw_bound_points = Point2f[point for path in raw_paths for point in path]
        if !isempty(raw_bound_points)
            if nlabels !== nothing
                xlim, ylim = compute_padded_limits(
                    positions,
                    nlabels,
                    _plot_attr(p, :nlabels_align_processed, nlabels_align),
                    resolved_label_distance,
                    resolved_label_fontsize;
                    padding = resolved_padding,
                    to_px = _plot_to_px(p),
                    extra_points = raw_bound_points,
                    node_sizes = resolved_node_size,
                )
            else
                xlim, ylim = compute_padded_limits(
                    positions,
                    nothing,
                    nlabels_align,
                    resolved_label_distance,
                    resolved_label_fontsize;
                    padding = resolved_padding,
                    to_px = _plot_to_px(p),
                    extra_points = raw_bound_points,
                    node_sizes = resolved_node_size,
                )
            end
            xlims!(ax, xlim)
            ylims!(ax, ylim)
        end

        geometry = compute_bidirected_geometry(
            mg,
            positions,
            resolved_node_marker,
            resolved_node_size,
            _plot_to_px(p);
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
    end

    return p
end

# =============================================================================
# Convenience functions for mixed graphs
# =============================================================================

"""
    dagplot_confounded(labels; kwargs...)

Plot a simple confounded graph: X → Y with X ↔ Y.

Uses a horizontal layout by default so the bidirected arc is visible above the
directed edge; pass `layout` to override.

# Arguments
- `labels::Vector{String}`: Labels [treatment, outcome]
"""
function dagplot_confounded(
    labels::Vector{String};
    layout = _LAYOUT_PAIR_HORIZONTAL,
    kwargs...,
)
    mg, _ = confounded_graph(labels)
    return dagplot(mg; labels = labels, layout = layout, kwargs...)
end

"""
    dagplot_frontdoor(labels; kwargs...)

Plot a frontdoor criterion graph: X → M → Y with X ↔ Y.

Uses a triangle layout by default (mediator on top). Layered layout collinearises
the three nodes and obscures the bidirected confounding arc; pass `layout` to
override.

# Arguments
- `labels::Vector{String}`: Labels [treatment, mediator, outcome]
"""
function dagplot_frontdoor(
    labels::Vector{String};
    layout = _LAYOUT_TRIANGLE_MEDIATOR_TOP,
    kwargs...,
)
    mg, _ = frontdoor_graph(labels)
    return dagplot(mg; labels = labels, layout = layout, kwargs...)
end

"""
    dagplot_iv_confounded(labels; kwargs...)

Plot an IV graph with confounding: Z → X → Y, X ↔ Y.

Uses a triangle layout by default (instrument on top). Layered layout
collinearises the chain and hides the bidirected confounding arc; pass
`layout` to override.

# Arguments
- `labels::Vector{String}`: Labels [instrument, treatment, outcome]
"""
function dagplot_iv_confounded(
    labels::Vector{String};
    layout = _LAYOUT_TRIANGLE_APEX_TOP,
    kwargs...,
)
    mg, _ = iv_confounded_graph(labels)
    return dagplot(mg; labels = labels, layout = layout, kwargs...)
end

"""
    dagplot_m_bias(labels; kwargs...)

Plot the classic five-node M-bias DAG with explicit latents:

```
U₁ → X, U₁ → M, U₂ → M, U₂ → Y
```

Default layout forms the letter M (latents on top, ``X``–``M``–``Y`` on the
base). Pass `layout` to override.

# Arguments
- `labels::Vector{<:AbstractString}`: Labels ``[U₁, U₂, X, M, Y]``
"""
function dagplot_m_bias(
    labels::Vector{<:AbstractString} = ["U₁", "U₂", "X", "M", "Y"];
    layout = _LAYOUT_M_BIAS,
    kwargs...,
)
    spec = m_bias_spec(labels)
    return dagplot(spec; layout = layout, kwargs...)
end
