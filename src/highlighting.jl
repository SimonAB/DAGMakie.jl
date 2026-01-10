"""
Path highlighting for causal DAG visualisation.

Provides visual highlighting of:
- Causal paths
- Backdoor paths
- Adjustment sets
- d-separation status
"""

using Makie: Figure, Axis, lines!, scatter!, text!, @lift
using GraphMakie: graphplot!

# =============================================================================
# Highlight Specifications
# =============================================================================

"""
    HighlightSpec

Specification for highlighting elements in a DAG plot.

# Fields
- `nodes::Vector{Int}`: Nodes to highlight
- `node_colors::Vector`: Colors for highlighted nodes
- `edges::Vector{Tuple{Int,Int}}`: Edges to highlight (as src, dst pairs)
- `edge_colors::Vector`: Colors for highlighted edges
- `labels::Vector{String}`: Optional labels for highlighted nodes
"""
struct HighlightSpec
    nodes::Vector{Int}
    node_colors::Vector
    edges::Vector{Tuple{Int, Int}}
    edge_colors::Vector
    labels::Vector{String}
end

function HighlightSpec(;
    nodes = Int[],
    node_colors = [],
    edges = Tuple{Int, Int}[],
    edge_colors = [],
    labels = String[]
)
    return HighlightSpec(nodes, node_colors, edges, edge_colors, labels)
end

# =============================================================================
# Highlighting from Paths
# =============================================================================

"""
    highlight_from_path(path::CausalPath; color=:red)

Create a HighlightSpec from a causal path.
"""
function highlight_from_path(path::CausalPath; color = :red)
    edges = path_edges(path)
    return HighlightSpec(
        nodes = path.nodes,
        node_colors = fill(color, length(path.nodes)),
        edges = edges,
        edge_colors = fill(color, length(edges)),
        labels = String[]
    )
end

"""
    highlight_from_paths(paths::Vector{CausalPath}; colors=nothing)

Create a HighlightSpec from multiple paths with different colors.
"""
function highlight_from_paths(paths::Vector{CausalPath}; colors = nothing)
    if colors === nothing
        colors = [:red, :blue, :green, :orange, :purple, :cyan, :magenta, :yellow]
    end
    
    all_nodes = Int[]
    all_node_colors = []
    all_edges = Tuple{Int, Int}[]
    all_edge_colors = []
    
    for (i, path) in enumerate(paths)
        color = colors[mod1(i, length(colors))]
        append!(all_nodes, path.nodes)
        append!(all_node_colors, fill(color, length(path.nodes)))
        edges = path_edges(path)
        append!(all_edges, edges)
        append!(all_edge_colors, fill(color, length(edges)))
    end
    
    return HighlightSpec(
        nodes = all_nodes,
        node_colors = all_node_colors,
        edges = all_edges,
        edge_colors = all_edge_colors,
        labels = String[]
    )
end

"""
    highlight_adjustment_set(g::AbstractGraph, treatment::Int, outcome::Int, 
                             adjustment::Set{Int}; treatment_color=:green, 
                             outcome_color=:blue, adjustment_color=:orange)

Create a HighlightSpec for visualising an adjustment set.
"""
function highlight_adjustment_set(
    g::AbstractGraph, 
    treatment::Int, 
    outcome::Int, 
    adjustment::Set{Int};
    treatment_color = :lightgreen,
    outcome_color = :lightyellow,
    adjustment_color = :lightsalmon
)
    nodes = [treatment, outcome, collect(adjustment)...]
    colors = [treatment_color, outcome_color, fill(adjustment_color, length(adjustment))...]
    
    return HighlightSpec(
        nodes = nodes,
        node_colors = colors,
        edges = Tuple{Int, Int}[],
        edge_colors = [],
        labels = String[]
    )
end

"""
    highlight_backdoor_paths(g::AbstractGraph, treatment::Int, outcome::Int;
                             blocked_color=:gray, open_color=:red, 
                             adjustment::Set{Int}=Set{Int}())

Create a HighlightSpec showing backdoor paths, coloured by whether blocked.
"""
function highlight_backdoor_paths(
    g::AbstractGraph, 
    treatment::Int, 
    outcome::Int;
    blocked_color = :gray,
    open_color = :red,
    adjustment::Set{Int} = Set{Int}(),
    max_length::Int = 10
)
    backdoor_paths = find_backdoor_paths(g, treatment, outcome; max_length = max_length)
    
    all_edges = Tuple{Int, Int}[]
    all_edge_colors = []
    
    # Compute descendants of conditioned nodes
    conditioned_and_descendants = copy(adjustment)
    for node in adjustment
        union!(conditioned_and_descendants, descendants(g, node))
    end
    
    for path in backdoor_paths
        # Check if path is blocked
        blocked = false
        for i in 2:(length(path.nodes) - 1)
            node = path.nodes[i]
            if is_collider(path, i)
                if node ∉ conditioned_and_descendants
                    blocked = true
                    break
                end
            else
                if node ∈ adjustment
                    blocked = true
                    break
                end
            end
        end
        
        color = blocked ? blocked_color : open_color
        edges = path_edges(path)
        append!(all_edges, edges)
        append!(all_edge_colors, fill(color, length(edges)))
    end
    
    return HighlightSpec(
        nodes = Int[],
        node_colors = [],
        edges = all_edges,
        edge_colors = all_edge_colors,
        labels = String[]
    )
end

# =============================================================================
# Highlighted DAG Plotting
# =============================================================================

"""
    dagplot_highlighted(g::AbstractGraph, highlight::HighlightSpec; kwargs...)

Create a DAG plot with highlighted elements.

# Arguments
- `g`: The graph
- `highlight`: HighlightSpec defining what to highlight
- `kwargs...`: Additional arguments passed to dagplot

# Examples
```julia
g = confounding_graph(["Z", "X", "Y"])[1]
paths = find_backdoor_paths(g, 2, 3)
highlight = highlight_from_path(paths[1], color=:red)
fig, ax, p = dagplot_highlighted(g, highlight, nlabels=["Z", "X", "Y"])
```
"""
function dagplot_highlighted(
    g::AbstractGraph, 
    highlight::HighlightSpec;
    figure_size::Tuple{Int, Int} = (600, 400),
    kwargs...
)
    fig = Figure(size = figure_size)
    ax = Axis(fig[1, 1])
    p = dagplot_highlighted!(ax, g, highlight; kwargs...)
    return fig, ax, p
end

"""
    dagplot_highlighted!(ax, g::AbstractGraph, highlight::HighlightSpec; kwargs...)

Plot a highlighted DAG into an existing axis.
"""
function dagplot_highlighted!(
    ax, 
    g::AbstractGraph, 
    highlight::HighlightSpec;
    # Layout
    layout = Spring(),
    padding::Float64 = DEFAULT_PADDING,
    # Base styling
    node_size = DEFAULT_NODE_SIZE,
    node_color = DEFAULT_NODE_COLOR,
    node_strokewidth = DEFAULT_NODE_STROKEWIDTH,
    node_strokecolor = DEFAULT_NODE_STROKECOLOR,
    edge_color = DEFAULT_EDGE_COLOR,
    edge_width = DEFAULT_EDGE_WIDTH,
    arrow_size = DEFAULT_ARROW_SIZE,
    arrow_shift = DEFAULT_ARROW_SHIFT,
    # Highlight styling
    highlight_node_size = 15,
    highlight_edge_width = 2.5,
    # Labels
    nlabels = nothing,
    nlabels_fontsize = DEFAULT_LABEL_FONTSIZE,
    auto_align_labels = true,
    kwargs...
)
    # Build node colors array (base color, override for highlighted nodes)
    n = nv(g)
    node_colors = fill(node_color, n)
    node_sizes = fill(node_size, n)
    
    for (i, node) in enumerate(highlight.nodes)
        if node >= 1 && node <= n && i <= length(highlight.node_colors)
            node_colors[node] = highlight.node_colors[i]
            node_sizes[node] = highlight_node_size
        end
    end
    
    # Build edge colors array
    edge_colors_arr = fill(edge_color, ne(g))
    edge_widths = fill(edge_width, ne(g))
    
    edge_to_idx = Dict{Tuple{Int, Int}, Int}()
    for (idx, e) in enumerate(edges(g))
        edge_to_idx[(src(e), dst(e))] = idx
    end
    
    for (i, edge) in enumerate(highlight.edges)
        if haskey(edge_to_idx, edge) && i <= length(highlight.edge_colors)
            idx = edge_to_idx[edge]
            edge_colors_arr[idx] = highlight.edge_colors[i]
            edge_widths[idx] = highlight_edge_width
        end
    end
    
    # Plot with computed colors
    p = dagplot!(ax, g;
        layout = layout,
        padding = padding,
        node_size = node_sizes,
        node_color = node_colors,
        node_strokewidth = node_strokewidth,
        node_strokecolor = node_strokecolor,
        edge_color = edge_colors_arr,
        edge_width = edge_widths,
        arrow_size = arrow_size,
        arrow_shift = arrow_shift,
        nlabels = nlabels,
        nlabels_fontsize = nlabels_fontsize,
        auto_align_labels = auto_align_labels,
        kwargs...
    )
    
    return p
end

# =============================================================================
# Convenience Functions
# =============================================================================

"""
    dagplot_backdoor(g::AbstractGraph, treatment::Int, outcome::Int;
                     adjustment::Set{Int}=Set{Int}(), kwargs...)

Plot a DAG highlighting backdoor paths.

Open backdoor paths are shown in red, blocked paths in gray.

# Arguments
- `g`: The DAG
- `treatment`: Treatment node index
- `outcome`: Outcome node index
- `adjustment`: Optional adjustment set to condition on
- `kwargs...`: Additional arguments for dagplot

# Examples
```julia
g, labels = confounding_graph(["Z", "X", "Y"])
fig, ax, p = dagplot_backdoor(g, 2, 3, nlabels=labels)

# With adjustment set
fig, ax, p = dagplot_backdoor(g, 2, 3, adjustment=Set([1]), nlabels=labels)
```
"""
function dagplot_backdoor(
    g::AbstractGraph, 
    treatment::Int, 
    outcome::Int;
    adjustment::Set{Int} = Set{Int}(),
    treatment_color = :lightgreen,
    outcome_color = :lightyellow,
    adjustment_color = :lightsalmon,
    kwargs...
)
    # Combine path highlighting with node highlighting
    path_highlight = highlight_backdoor_paths(g, treatment, outcome; adjustment = adjustment)
    node_highlight = highlight_adjustment_set(g, treatment, outcome, adjustment;
        treatment_color = treatment_color,
        outcome_color = outcome_color,
        adjustment_color = adjustment_color
    )
    
    # Merge highlights
    combined = HighlightSpec(
        nodes = node_highlight.nodes,
        node_colors = node_highlight.node_colors,
        edges = path_highlight.edges,
        edge_colors = path_highlight.edge_colors,
        labels = String[]
    )
    
    return dagplot_highlighted(g, combined; kwargs...)
end

"""
    dagplot_dsep(g::AbstractGraph, x::Int, y::Int, z::Set{Int}; kwargs...)

Plot a DAG showing d-separation status.

Shows whether X and Y are d-separated given Z, with appropriate highlighting.

# Arguments
- `g`: The DAG
- `x`: First node
- `y`: Second node
- `z`: Conditioning set
"""
function dagplot_dsep(
    g::AbstractGraph, 
    x::Int, 
    y::Int, 
    z::Set{Int};
    x_color = :lightblue,
    y_color = :lightblue,
    z_color = :lightsalmon,
    kwargs...
)
    separated = is_d_separated(g, x, y, z)
    
    # Highlight nodes
    nodes = [x, y, collect(z)...]
    colors = [x_color, y_color, fill(z_color, length(z))...]
    
    highlight = HighlightSpec(
        nodes = nodes,
        node_colors = colors,
        edges = Tuple{Int, Int}[],
        edge_colors = [],
        labels = String[]
    )
    
    fig, ax, p = dagplot_highlighted(g, highlight; kwargs...)
    
    # Add title indicating d-separation status
    status_text = separated ? "X ⊥ Y | Z (d-separated)" : "X ↛⊥ Y | Z (d-connected)"
    ax.title = status_text
    
    return fig, ax, p
end

"""
    dagplot_causal_paths(g::AbstractGraph, treatment::Int, outcome::Int;
                         path_color=:green, kwargs...)

Plot a DAG highlighting all causal (directed) paths from treatment to outcome.
"""
function dagplot_causal_paths(
    g::AbstractGraph, 
    treatment::Int, 
    outcome::Int;
    path_color = :green,
    treatment_color = :lightgreen,
    outcome_color = :lightyellow,
    kwargs...
)
    causal_paths = find_directed_paths(g, treatment, outcome)
    
    all_edges = Tuple{Int, Int}[]
    for path in causal_paths
        append!(all_edges, path_edges(path))
    end
    unique!(all_edges)
    
    highlight = HighlightSpec(
        nodes = [treatment, outcome],
        node_colors = [treatment_color, outcome_color],
        edges = all_edges,
        edge_colors = fill(path_color, length(all_edges)),
        labels = String[]
    )
    
    return dagplot_highlighted(g, highlight; kwargs...)
end

"""
    dagplot_adjustment(g::AbstractGraph, treatment::Int, outcome::Int;
                       show_backdoor::Bool=true, kwargs...)

Plot a DAG with automatically computed minimal adjustment set.

# Arguments
- `g`: The DAG
- `treatment`: Treatment node
- `outcome`: Outcome node
- `show_backdoor`: Whether to show backdoor paths
"""
function dagplot_adjustment(
    g::AbstractGraph, 
    treatment::Int, 
    outcome::Int;
    show_backdoor::Bool = true,
    adjustment_color = :lightsalmon,
    kwargs...
)
    # Find minimal adjustment set
    adj_set = find_minimal_adjustment_set(g, treatment, outcome)
    
    if adj_set === nothing
        # No valid adjustment set - just plot with treatment/outcome highlighted
        return dagplot_backdoor(g, treatment, outcome; kwargs...)
    end
    
    return dagplot_backdoor(g, treatment, outcome; 
        adjustment = adj_set,
        adjustment_color = adjustment_color,
        kwargs...
    )
end
