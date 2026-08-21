# SPDX-License-Identifier: MIT

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

# Precedence

When the same node or edge is listed more than once, the **first** listing wins
(exposure / outcome / adjustment colours should therefore precede path colours
in merged specs). Default theme colours sit underneath.
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
    treatment_color = :seagreen,
    outcome_color = :goldenrod,
    adjustment_color = :indianred
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
    highlight_backdoor_paths(paths::Vector{CausalPath};
                             blocked_color=:gray, open_color=:red,
                             blocked::AbstractVector{Bool}=Bool[])

Create a `HighlightSpec` from precomputed backdoor paths.

Pass `blocked` of the same length as `paths` to colour blocked vs open paths.
If `blocked` is empty, all paths use `open_color`.

Path finding belongs in CausalInference.jl / CausalDynamics.jl — not DAGMakie.
"""
function highlight_backdoor_paths(
    paths::Vector{CausalPath};
    blocked_color = :gray,
    open_color = :red,
    blocked::AbstractVector{Bool} = Bool[],
)
    all_edges = Tuple{Int, Int}[]
    all_edge_colors = Any[]

    for (i, path) in enumerate(paths)
        is_blocked = !isempty(blocked) && i <= length(blocked) && blocked[i]
        color = is_blocked ? blocked_color : open_color
        edges = path_edges(path)
        append!(all_edges, edges)
        append!(all_edge_colors, fill(color, length(edges)))
    end

    return HighlightSpec(
        nodes = Int[],
        node_colors = [],
        edges = all_edges,
        edge_colors = all_edge_colors,
        labels = String[],
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
path = CausalPath([1, 2, 3]; directions = [:forward, :forward])
highlight = highlight_from_path(path, color=:red)
fig, ax, p = dagplot_highlighted(g, highlight, labels=["Z", "X", "Y"])
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

Prefer `labels=` and `label_position=` (see [`dagplot!`](@ref)). Alias
`nlabels=` / `auto_align_labels=` still work.
"""
function dagplot_highlighted!(
    ax, 
    g::AbstractGraph, 
    highlight::HighlightSpec;
    # Layout
    layout = nothing,
    padding = nothing,
    style::Union{Nothing, DAGStyle} = nothing,
    # Base styling
    node_size = nothing,
    node_color = nothing,
    node_strokewidth = nothing,
    node_strokecolor = nothing,
    edge_color = nothing,
    edge_width = nothing,
    arrow_size = nothing,
    arrow_shift = nothing,
    # Highlight styling
    highlight_node_size = nothing,
    highlight_edge_width = 2.5,
    # Labels
    labels = nothing,
    nlabels = nothing,
    nlabels_fontsize = nothing,
    label_position::Symbol = :inner,
    auto_align_labels = nothing,
    kwargs...
)
    style_config = _resolve_style(style)
    nlabels = resolve_nlabels(; labels = labels, nlabels = nlabels)
    outer_labels = resolve_outer_labels(label_position; auto_align_labels = auto_align_labels)
    resolved_node_size = something(node_size, style_config.node_size)
    resolved_node_color = something(node_color, style_config.node_color)
    resolved_node_strokewidth = something(node_strokewidth, style_config.node_strokewidth)
    resolved_node_strokecolor = something(node_strokecolor, style_config.node_strokecolor)
    resolved_edge_color = something(edge_color, style_config.edge_color)
    resolved_edge_width = something(edge_width, style_config.edge_width)
    resolved_arrow_size = something(arrow_size, style_config.arrow_size)
    resolved_arrow_shift = something(arrow_shift, style_config.arrow_shift)
    resolved_label_fontsize = something(nlabels_fontsize, style_config.label_fontsize)
    resolved_highlight_node_size = something(highlight_node_size, resolved_node_size + 3)

    n = nv(g)
    node_colors = _fill_attribute(resolved_node_color, n)
    node_sizes = _fill_attribute(resolved_node_size, n)

    edge_to_idx = Dict{Tuple{Int, Int}, Int}()
    for (idx, e) in enumerate(edges(g))
        edge_to_idx[(src(e), dst(e))] = idx
    end

    edge_colors_arr = _fill_attribute(resolved_edge_color, ne(g))
    edge_widths = _fill_attribute(resolved_edge_width, ne(g))

    _apply_highlight_node_styles!(node_colors, node_sizes, highlight; highlight_node_size = resolved_highlight_node_size)
    _apply_highlight_edge_styles!(edge_colors_arr, edge_widths, edge_to_idx, highlight; highlight_edge_width = highlight_edge_width)

    p = dagplot!(ax, g;
        layout = layout,
        padding = padding,
        style = style,
        node_size = node_sizes,
        node_color = node_colors,
        node_strokewidth = resolved_node_strokewidth,
        node_strokecolor = resolved_node_strokecolor,
        edge_color = edge_colors_arr,
        edge_width = edge_widths,
        arrow_size = resolved_arrow_size,
        arrow_shift = resolved_arrow_shift,
        nlabels = nlabels,
        nlabels_fontsize = resolved_label_fontsize,
        label_position = outer_labels ? :outer : :inner,
        kwargs...
    )
    
    return p
end

# =============================================================================
# Convenience Functions
# =============================================================================

"""
    dagplot_backdoor(g, treatment, outcome; adjustment=Set{Int}(), paths=CausalPath[], kwargs...)

Plot a DAG highlighting treatment, outcome, an adjustment set, and optional
precomputed backdoor paths.

For automatic adjustment / d-separation from CausalInference.jl, load that
package so `DAGMakieCausalInferenceExt` activates, or pass `adjustment` / `paths`
explicitly from CausalDynamics.jl.
"""
function dagplot_backdoor(
    g::AbstractGraph,
    treatment::Int,
    outcome::Int;
    adjustment::Set{Int} = Set{Int}(),
    paths::Vector{CausalPath} = CausalPath[],
    treatment_color = :seagreen,
    outcome_color = :goldenrod,
    adjustment_color = :indianred,
    kwargs...
)
    path_highlight = highlight_backdoor_paths(paths)
    node_highlight = highlight_adjustment_set(g, treatment, outcome, adjustment;
        treatment_color = treatment_color,
        outcome_color = outcome_color,
        adjustment_color = adjustment_color,
    )

    combined = HighlightSpec(
        nodes = node_highlight.nodes,
        node_colors = node_highlight.node_colors,
        edges = path_highlight.edges,
        edge_colors = path_highlight.edge_colors,
        labels = String[],
    )

    return dagplot_highlighted(g, combined; kwargs...)
end

"""
    dagplot_dsep(g, x, y, z; separated, kwargs...)

Plot a DAG with X, Y, and conditioning set Z highlighted.

Pass `separated::Bool` for the axis title (from CausalInference.jl `dsep` or
CausalDynamics.jl `d_separated`). With `using CausalInference`, `separated`
defaults via the package extension when omitted.
"""
function dagplot_dsep(
    g::AbstractGraph,
    x::Int,
    y::Int,
    z::Set{Int};
    separated::Union{Nothing, Bool} = nothing,
    x_color = :seagreen,
    y_color = :goldenrod,
    z_color = :indianred,
    kwargs...
)
    if separated === nothing
        ext = Base.get_extension(@__MODULE__, :DAGMakieCausalInferenceExt)
        if ext !== nothing
            separated = ext.dsep_status(g, x, y, z)
        end
    end

    nodes = [x, y, collect(z)...]
    colors = [x_color, y_color, fill(z_color, length(z))...]

    highlight = HighlightSpec(
        nodes = nodes,
        node_colors = colors,
        edges = Tuple{Int, Int}[],
        edge_colors = [],
        labels = String[],
    )

    fig, ax, p = dagplot_highlighted(g, highlight; kwargs...)

    if separated === nothing
        ax.title = "X, Y | Z"
    else
        ax.title = separated ? "X ⊥ Y | Z (d-separated)" : "X ↛⊥ Y | Z (d-connected)"
    end

    return fig, ax, p
end

"""
    dagplot_causal_paths(g, treatment, outcome; paths, kwargs...)

Highlight precomputed directed paths from treatment to outcome.
"""
function dagplot_causal_paths(
    g::AbstractGraph,
    treatment::Int,
    outcome::Int;
    paths::Vector{CausalPath},
    path_color = :green,
    treatment_color = :seagreen,
    outcome_color = :goldenrod,
    kwargs...
)
    all_edges = Tuple{Int, Int}[]
    for path in paths
        append!(all_edges, path_edges(path))
    end
    unique!(all_edges)

    highlight = HighlightSpec(
        nodes = [treatment, outcome],
        node_colors = [treatment_color, outcome_color],
        edges = all_edges,
        edge_colors = fill(path_color, length(all_edges)),
        labels = String[],
    )

    return dagplot_highlighted(g, highlight; kwargs...)
end

"""
    dagplot_adjustment(g, treatment, outcome; adjustment=nothing, kwargs...)

Plot a DAG with an adjustment set. Pass `adjustment::Set{Int}` explicitly, or
`using CausalInference` so the extension can compute a minimal backdoor set.
"""
function dagplot_adjustment(
    g::AbstractGraph,
    treatment::Int,
    outcome::Int;
    adjustment::Union{Nothing, Set{Int}} = nothing,
    show_backdoor::Bool = true,
    paths::Vector{CausalPath} = CausalPath[],
    adjustment_color = :indianred,
    kwargs...
)
    if adjustment === nothing
        ext = Base.get_extension(@__MODULE__, :DAGMakieCausalInferenceExt)
        ext === nothing && error(
            "Pass adjustment::Set{Int}, or load CausalInference.jl " *
            "(`using CausalInference`) to compute a backdoor adjustment set.",
        )
        adjustment = ext.min_backdoor_adjustment(g, treatment, outcome)
    end

    if show_backdoor
        return dagplot_backdoor(g, treatment, outcome;
            adjustment = adjustment,
            paths = paths,
            adjustment_color = adjustment_color,
            kwargs...,
        )
    end

    highlight = highlight_adjustment_set(g, treatment, outcome, adjustment;
        adjustment_color = adjustment_color,
    )
    return dagplot_highlighted(g, highlight; kwargs...)
end

function _apply_highlight_node_styles!(
    node_colors,
    node_sizes,
    highlight::HighlightSpec;
    highlight_node_size,
)
    # First listing wins (exposure/outcome typically precede paths in specs).
    claimed = falses(length(node_colors))
    for (index, node) in enumerate(highlight.nodes)
        if 1 <= node <= length(node_colors) &&
                index <= length(highlight.node_colors) &&
                !claimed[node]
            node_colors[node] = highlight.node_colors[index]
            node_sizes[node] = highlight_node_size
            claimed[node] = true
        end
    end

    return nothing
end

function _apply_highlight_edge_styles!(
    edge_colors,
    edge_widths,
    edge_to_idx,
    highlight::HighlightSpec;
    highlight_edge_width,
)
    # First listing wins when the same edge appears in several paths.
    claimed = Set{Tuple{Int, Int}}()
    for (index, edge) in enumerate(highlight.edges)
        if haskey(edge_to_idx, edge) &&
                index <= length(highlight.edge_colors) &&
                !(edge in claimed)
            edge_index = edge_to_idx[edge]
            edge_colors[edge_index] = highlight.edge_colors[index]
            edge_widths[edge_index] = highlight_edge_width
            push!(claimed, edge)
        end
    end

    return nothing
end
