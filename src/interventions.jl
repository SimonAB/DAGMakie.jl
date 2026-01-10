"""
Intervention (do-operator) support for causal DAGs.

Implements Pearl's do-calculus operations:
- Graph surgery (removing incoming edges to intervention targets)
- Visualisation of pre/post intervention graphs
- do(X) notation rendering
"""

using Graphs: AbstractGraph, SimpleDiGraph, nv, ne, add_edge!, rem_edge!,
              inneighbors, outneighbors, edges, src, dst

# =============================================================================
# Graph Surgery
# =============================================================================

"""
    do_surgery(g::AbstractGraph, intervention_nodes::Vector{Int})

Perform graph surgery for do-operator: remove all incoming edges to intervention nodes.

This creates a new graph representing the causal model after intervention,
where the intervention nodes are set to fixed values (no longer influenced
by their parents).

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

In-place graph surgery - modifies the original graph.
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

Specification for an intervention on one or more variables.

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
# Intervention Effects
# =============================================================================

"""
    causal_effect_identifiable(g::AbstractGraph, treatment::Int, outcome::Int)

Check if the causal effect of treatment on outcome is identifiable from
observational data using the backdoor criterion.

Returns `true` if there exists a valid adjustment set.
"""
function causal_effect_identifiable(g::AbstractGraph, treatment::Int, outcome::Int)
    adj = find_minimal_adjustment_set(g, treatment, outcome)
    return adj !== nothing
end

"""
    intervention_removes_confounding(g::AbstractGraph, treatment::Int, outcome::Int)

Check if intervening on treatment removes all confounding with outcome.

After do(treatment), there should be no backdoor paths.
"""
function intervention_removes_confounding(g::AbstractGraph, treatment::Int, outcome::Int)
    g_do = do_surgery(g, treatment)
    backdoor = find_backdoor_paths(g_do, treatment, outcome)
    return isempty(backdoor)
end

"""
    identify_confounders(g::AbstractGraph, treatment::Int, outcome::Int)

Identify variables that confound the treatment-outcome relationship.

Returns nodes that are ancestors of both treatment and outcome.
"""
function identify_confounders(g::AbstractGraph, treatment::Int, outcome::Int)
    treatment_ancestors = ancestors(g, treatment)
    outcome_ancestors = ancestors(g, outcome)
    
    # Common ancestors that aren't descendants of treatment
    common = intersect(treatment_ancestors, outcome_ancestors)
    
    # Filter to those that create backdoor paths
    confounders = Int[]
    for node in common
        # Check if this node opens a backdoor path
        if has_path_through(g, node, treatment, outcome)
            push!(confounders, node)
        end
    end
    
    return confounders
end

"""
    has_path_through(g::AbstractGraph, through::Int, source::Int, target::Int)

Check if there's a path from source to target that goes through a specific node.
"""
function has_path_through(g::AbstractGraph, through::Int, source::Int, target::Int)
    # Check if 'through' is ancestor of both source and target
    # This creates a backdoor path source ← ... ← through → ... → target
    source_ancestors = ancestors(g, source)
    target_ancestors = ancestors(g, target)
    
    return through ∈ source_ancestors && through ∈ target_ancestors
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
    intervention_color = :orange,
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
    layout = Spring(),
    padding::Float64 = DEFAULT_PADDING,
    # Styling
    node_size = DEFAULT_NODE_SIZE,
    node_color = DEFAULT_NODE_COLOR,
    intervention_color = :orange,
    edge_color = DEFAULT_EDGE_COLOR,
    removed_edge_color = :lightgray,
    removed_edge_style = :dash,
    # Labels
    nlabels = nothing,
    nlabels_fontsize = DEFAULT_LABEL_FONTSIZE,
    auto_align_labels = true,
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
    
    # Build node colors
    n = nv(g)
    node_colors = fill(node_color, n)
    for node in intervention.nodes
        if node >= 1 && node <= n
            node_colors[node] = intervention_color
        end
    end
    
    # Update labels if provided
    if nlabels !== nothing
        nlabels = format_intervention_labels(nlabels, intervention)
    end
    
    # Plot the post-intervention graph
    p = dagplot!(ax, g_do;
        layout = layout,
        padding = padding,
        node_size = node_size,
        node_color = node_colors,
        edge_color = edge_color,
        nlabels = nlabels,
        nlabels_fontsize = nlabels_fontsize,
        auto_align_labels = auto_align_labels,
        kwargs...
    )
    
    # Optionally show removed edges as dashed
    if !isempty(removed_edges)
        positions = p[:node_pos][]
        for (s, d) in removed_edges
            p1, p2 = Point2f(positions[s]), Point2f(positions[d])
            lines!(ax, [p1, p2];
                color = removed_edge_color,
                linestyle = removed_edge_style,
                linewidth = 1.0
            )
        end
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
    
    # Original DAG
    ax1 = Axis(fig[1, 1], title = "Original")
    dagplot!(ax1, g; nlabels = nlabels, kwargs...)
    
    # Post-intervention DAG
    ax2 = Axis(fig[1, 2], title = intervention.label)
    dagplot_intervention!(ax2, g, intervention; nlabels = nlabels, kwargs...)
    
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
    query_identifiable(g::AbstractGraph, query::CausalQuery)

Check if a causal query is identifiable from observational data.
"""
function query_identifiable(g::AbstractGraph, query::CausalQuery)
    return causal_effect_identifiable(g, query.treatment, query.outcome)
end

"""
    query_to_string(query::CausalQuery, nlabels::Vector{String})

Convert a causal query to readable notation.
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
