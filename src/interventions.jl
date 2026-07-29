"""
Intervention (`do(·)`) support for causal DAGs.

Pearl's do-calculus: graph surgery, intervention plots, and `do(X)` labels.
"""

using Graphs: AbstractGraph, SimpleDiGraph, nv, ne, add_edge!, rem_edge!,
              inneighbors, outneighbors, edges, src, dst

# =============================================================================
# Graph Surgery
# =============================================================================

"""
    do_surgery(g::AbstractGraph, intervention_nodes::Vector{Int})

Perform **display-only** graph surgery for `do(·)`: remove all incoming edges to
intervention nodes. Use this to draw mutilated DAGs in Makie; it is **not** an
identification API.

For CausalDynamics identification and CDM interventions, use
`DoIntervention` / `apply_intervention` (and related helpers) in CausalDynamics.jl.

Returns a graph where intervened nodes no longer have parents (for plotting).

# Arguments
- `g`: Original DAG
- `intervention_nodes`: Nodes being intervened on (set to fixed values)

# Returns
- New SimpleDiGraph with incoming edges to intervention nodes removed

# Examples
```julia
# Confounding: Z → X → Y, Z → Y
g = SimpleDiGraph(3)
add_edge!(g, 1, 2)  # Z → X
add_edge!(g, 2, 3)  # X → Y
add_edge!(g, 1, 3)  # Z → Y

# do(X) - intervene on X
g_do = do_surgery(g, [2])
# Result: X → Y, Z → Y (Z → X edge removed)
```
"""
function do_surgery(g::AbstractGraph, intervention_nodes::Vector{Int})
    # Create copy of the graph
    g_new = SimpleDiGraph(nv(g))
    
    for e in edges(g)
        s, d = src(e), dst(e)
        # Only keep edge if destination is NOT an intervention node
        if d ∉ intervention_nodes
            add_edge!(g_new, s, d)
        end
    end
    
    return g_new
end

"""
    do_surgery(g::AbstractGraph, intervention_node::Int)

Single-node intervention convenience method.
"""
do_surgery(g::AbstractGraph, intervention_node::Int) = do_surgery(g, [intervention_node])

"""
    do_surgery!(g::SimpleDiGraph, intervention_nodes::Vector{Int})

In-place **display-only** graph surgery — modifies the original graph.
Same boundary as `do_surgery`: for plotting mutilated DAGs, not CausalDynamics ID.
"""
function do_surgery!(g::SimpleDiGraph, intervention_nodes::Vector{Int})
    for node in intervention_nodes
        for parent in collect(inneighbors(g, node))
            rem_edge!(g, parent, node)
        end
    end
    return g
end

# =============================================================================
# Intervention Specification
# =============================================================================

"""
    Intervention

Specification for an intervention (`do(·)`) on one or more variables.

# Fields
- `nodes::Vector{Int}`: Nodes being intervened on
- `values::Vector{String}`: Display values for the interventions (e.g., "x=1")
- `label::String`: Overall intervention label (e.g., "do(X=1)")
"""
struct Intervention
    nodes::Vector{Int}
    values::Vector{String}
    label::String
end

"""
    Intervention(node::Int; value::String="", label::String="")

Create a single-node intervention.
"""
function Intervention(node::Int; value::String = "", label::String = "")
    if isempty(label)
        label = isempty(value) ? "do(X$(node))" : "do($(value))"
    end
    return Intervention([node], [value], label)
end

"""
    Intervention(nodes::Vector{Int}; values::Vector{String}=String[], label::String="")

Create a multi-node intervention.
"""
function Intervention(nodes::Vector{Int}; values::Vector{String} = String[], label::String = "")
    if isempty(values)
        values = fill("", length(nodes))
    end
    if isempty(label)
        parts = ["X$(n)" for n in nodes]
        label = "do($(join(parts, ", ")))"
    end
    return Intervention(nodes, values, label)
end

# =============================================================================
# Intervention Labels for Plotting
# =============================================================================

"""
    intervention_label(var_name::String; value=nothing)

Create a formatted intervention label: do(X) or do(X=x).
"""
function intervention_label(var_name::String; value = nothing)
    if value === nothing
        return "do($(var_name))"
    else
        return "do($(var_name)=$(value))"
    end
end

"""
    format_intervention_labels(nlabels::Vector{String}, intervention::Intervention)

Update node labels to show intervention notation.
"""
function format_intervention_labels(nlabels::Vector{String}, intervention::Intervention)
    new_labels = copy(nlabels)
    for (i, node) in enumerate(intervention.nodes)
        if node >= 1 && node <= length(new_labels)
            val = i <= length(intervention.values) ? intervention.values[i] : ""
            if isempty(val)
                new_labels[node] = "do($(new_labels[node]))"
            else
                new_labels[node] = "do($(new_labels[node])=$(val))"
            end
        end
    end
    return new_labels
end

# =============================================================================
# Intervention Visualisation
# =============================================================================

"""
    dagplot_intervention(g::AbstractGraph, intervention::Intervention;
                         show_original::Bool=true, kwargs...)

Plot a DAG with intervention applied, showing removed edges.

# Arguments
- `g`: Original DAG
- `intervention`: Intervention specification
- `show_original`: If true, show original edges as dashed
- `kwargs...`: Additional arguments for dagplot

# Examples
```julia
g, labels = confounding_graph(["Z", "X", "Y"])
int = Intervention(2)  # do(X)
fig, ax, p = dagplot_intervention(g, int, nlabels=labels)
```
"""
function dagplot_intervention(
    g::AbstractGraph, 
    intervention::Intervention;
    show_original::Bool = true,
    intervention_color = :darkorange,
    removed_edge_color = :lightgray,
    removed_edge_style = :dash,
    figure_size::Tuple{Int, Int} = (600, 400),
    kwargs...
)
    fig = Figure(size = figure_size)
    ax = Axis(fig[1, 1])
    p = dagplot_intervention!(ax, g, intervention;
        show_original = show_original,
        intervention_color = intervention_color,
        removed_edge_color = removed_edge_color,
        removed_edge_style = removed_edge_style,
        kwargs...
    )
    return fig, ax, p
end

"""
    dagplot_intervention!(ax, g::AbstractGraph, intervention::Intervention; kwargs...)

Plot intervention into an existing axis.
"""
function dagplot_intervention!(
    ax,
    g::AbstractGraph, 
    intervention::Intervention;
    # Layout
    layout = nothing,
    padding = nothing,
    style::Union{Nothing, DAGStyle} = nothing,
    # Styling
    node_size = nothing,
    node_color = nothing,
    node_strokewidth = nothing,
    node_strokecolor = nothing,
    node_marker = nothing,
    intervention_color = :darkorange,
    edge_color = nothing,
    edge_width = nothing,
    edge_linestyle = nothing,
    arrow_size = nothing,
    arrow_shift = nothing,
    waypoints = nothing,
    removed_edge_color = :lightgray,
    removed_edge_width = nothing,
    removed_edge_style = :dash,
    # Labels
    nlabels = nothing,
    nlabels_align = DEFAULT_LABEL_ALIGN,
    nlabels_distance = nothing,
    nlabels_fontsize = nothing,
    nlabels_color = nothing,
    auto_align_labels = false,
    show_original::Bool = true,
    relabel_nodes::Bool = false,
    kwargs...
)
    # Apply intervention
    g_do = do_surgery(g, intervention.nodes)
    
    # Identify removed edges
    removed_edges = Tuple{Int, Int}[]
    for e in edges(g)
        if dst(e) ∈ intervention.nodes
            push!(removed_edges, (src(e), dst(e)))
        end
    end
    
    # Build node colours
    n = nv(g)
    style_config = _resolve_style(style)
    base_node_color = something(node_color, style_config.node_color)
    node_colors = _fill_attribute(base_node_color, n)
    for node in intervention.nodes
        if node >= 1 && node <= n
            node_colors[node] = intervention_color
        end
    end
    
    # Optionally rewrite node labels to do(·); prefer axis title for that notation
    # so short in-node labels stay centred and readable.
    if nlabels !== nothing && relabel_nodes
        nlabels = format_intervention_labels(nlabels, intervention)
    end
    
    # Plot the post-intervention graph
    p = dagplot!(ax, g_do;
        layout = layout,
        padding = padding,
        style = style,
        node_size = node_size,
        node_color = node_colors,
        node_strokewidth = node_strokewidth,
        node_strokecolor = node_strokecolor,
        node_marker = node_marker,
        edge_color = edge_color,
        edge_width = edge_width,
        edge_linestyle = edge_linestyle,
        arrow_size = arrow_size,
        arrow_shift = arrow_shift,
        waypoints = waypoints,
        nlabels = nlabels,
        nlabels_align = nlabels_align,
        nlabels_distance = nlabels_distance,
        nlabels_fontsize = nlabels_fontsize,
        nlabels_color = nlabels_color,
        auto_align_labels = auto_align_labels,
        kwargs...
    )
    
    # Optionally show removed edges as dashed
    if show_original && !isempty(removed_edges)
        resolved_node_size = _fill_attribute(something(node_size, style_config.node_size), n)
        resolved_node_marker = _fill_attribute(something(node_marker, :circle), n)
        edge_lookup = _edge_index_lookup(g)
        base_edge_widths = _fill_attribute(something(edge_width, style_config.edge_width), ne(g))
        base_arrow_sizes = _fill_attribute(something(arrow_size, style_config.arrow_size), ne(g))
        base_arrow_shifts = _fill_attribute(something(arrow_shift, style_config.arrow_shift), ne(g))
        overlay_widths = if removed_edge_width === nothing
            _overlay_values(nothing, removed_edges, edge_lookup, base_edge_widths)
        else
            _fill_attribute(removed_edge_width, length(removed_edges))
        end
        overlay_arrow_sizes = _overlay_values(nothing, removed_edges, edge_lookup, base_arrow_sizes)
        overlay_arrow_shifts = _overlay_values(nothing, removed_edges, edge_lookup, base_arrow_shifts)

        _plot_directed_overlay!(
            ax,
            removed_edges,
            Point2f.(p[:node_pos][]);
            node_sizes = resolved_node_size,
            node_markers = resolved_node_marker,
            edge_colours = fill(removed_edge_color, length(removed_edges)),
            edge_widths = overlay_widths,
            edge_linestyles = fill(removed_edge_style, length(removed_edges)),
            arrow_sizes = overlay_arrow_sizes,
            arrow_shifts = overlay_arrow_shifts,
            waypoints = [Point2f[] for _ in removed_edges],
            to_px = _plot_to_px(p),
        )
    end
    
    # Set title
    ax.title = intervention.label
    
    return p
end

"""
    dagplot_do(g::AbstractGraph, intervention_node::Int; nlabels=nothing, kwargs...)

Convenience function for single-node intervention visualisation.
"""
function dagplot_do(
    g::AbstractGraph, 
    intervention_node::Int;
    nlabels = nothing,
    kwargs...
)
    var_name = nlabels !== nothing && intervention_node <= length(nlabels) ? 
               nlabels[intervention_node] : "X$(intervention_node)"
    int = Intervention(intervention_node; label = intervention_label(var_name))
    return dagplot_intervention(g, int; nlabels = nlabels, kwargs...)
end

"""
    dagplot_comparison(g::AbstractGraph, intervention::Intervention;
                       nlabels=nothing, kwargs...)

Create a side-by-side comparison of original and post-intervention DAGs.

# Returns
- Figure with two panels: original (left) and post-intervention (right)
"""
function dagplot_comparison(
    g::AbstractGraph,
    intervention::Intervention;
    nlabels = nothing,
    figure_size::Tuple{Int, Int} = (1000, 400),
    kwargs...
)
    fig = Figure(size = figure_size)

    shared_layout = compute_graph_layout(
        g;
        layout = haskey(kwargs, :layout) ? kwargs[:layout] : nothing,
        layout_mode = haskey(kwargs, :layout_mode) ? kwargs[:layout_mode] : :auto,
        orientation = haskey(kwargs, :orientation) ? kwargs[:orientation] : :lr,
        layer_gap = haskey(kwargs, :layer_gap) ? kwargs[:layer_gap] : 2.6,
        node_gap = haskey(kwargs, :node_gap) ? kwargs[:node_gap] : 1.8,
        component_gap = haskey(kwargs, :component_gap) ? kwargs[:component_gap] : 3.2,
        scc_radius = haskey(kwargs, :scc_radius) ? kwargs[:scc_radius] : 0.9,
        feedback_curvature = haskey(kwargs, :feedback_curvature) ? kwargs[:feedback_curvature] : 0.75,
    ).positions

    original_kwargs = _merge_default_kwargs(kwargs, (layout = shared_layout, nlabels = nlabels))
    intervention_kwargs = _merge_default_kwargs(kwargs, (layout = shared_layout, nlabels = nlabels))

    # Original DAG
    ax1 = Axis(fig[1, 1], title = "Original")
    dagplot!(ax1, g; original_kwargs...)

    # Post-intervention DAG
    ax2 = Axis(fig[1, 2], title = intervention.label)
    dagplot_intervention!(ax2, g, intervention; intervention_kwargs...)

    return fig
end

"""
    dagplot_do_comparison(g::AbstractGraph, intervention_node::Int;
                          nlabels=nothing, kwargs...)

Convenience function for side-by-side comparison with single intervention.
"""
function dagplot_do_comparison(
    g::AbstractGraph,
    intervention_node::Int;
    nlabels = nothing,
    kwargs...
)
    var_name = nlabels !== nothing && intervention_node <= length(nlabels) ? 
               nlabels[intervention_node] : "X$(intervention_node)"
    int = Intervention(intervention_node; label = intervention_label(var_name))
    return dagplot_comparison(g, int; nlabels = nlabels, kwargs...)
end

# =============================================================================
# Causal Effect Queries
# =============================================================================

"""
    CausalQuery

A query about a causal effect.

# Fields
- `treatment::Int`: Treatment variable
- `outcome::Int`: Outcome variable  
- `intervention::Union{Intervention, Nothing}`: Intervention (if specified)
- `conditioning::Set{Int}`: Variables to condition on
"""
struct CausalQuery
    treatment::Int
    outcome::Int
    intervention::Union{Intervention, Nothing}
    conditioning::Set{Int}
end

function CausalQuery(treatment::Int, outcome::Int; 
                     intervention = nothing, 
                     conditioning = Set{Int}())
    return CausalQuery(treatment, outcome, intervention, conditioning)
end

"""
    query_to_string(query::CausalQuery, nlabels::Vector{String})

Convert a causal query to readable notation for plot titles.
"""
function query_to_string(query::CausalQuery, nlabels::Vector{String})
    t_name = query.treatment <= length(nlabels) ? nlabels[query.treatment] : "X$(query.treatment)"
    o_name = query.outcome <= length(nlabels) ? nlabels[query.outcome] : "Y$(query.outcome)"
    
    if query.intervention !== nothing
        return "P($(o_name) | do($(t_name)))"
    elseif !isempty(query.conditioning)
        cond_names = [i <= length(nlabels) ? nlabels[i] : "X$(i)" for i in query.conditioning]
        return "P($(o_name) | $(t_name), $(join(cond_names, ", ")))"
    else
        return "P($(o_name) | $(t_name))"
    end
end
