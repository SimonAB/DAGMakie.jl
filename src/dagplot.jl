"""
Main dagplot recipe for DAG visualisation.

Provides `dagplot` and `dagplot!` functions for creating publication-ready
causal diagram visualisations with sensible defaults.
"""

using Makie: Figure, Axis, xlims!, ylims!, tightlimits!, lines!, scatter!, Billboard
using GraphMakie: graphplot!
using NetworkLayout: Spring

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
    layout = Spring(),
    padding::Float64 = DEFAULT_PADDING,
    # Nodes
    node_size = DEFAULT_NODE_SIZE,
    node_color = DEFAULT_NODE_COLOR,
    node_strokewidth = DEFAULT_NODE_STROKEWIDTH,
    node_strokecolor = DEFAULT_NODE_STROKECOLOR,
    node_marker = :circle,
    # Edges
    edge_color = DEFAULT_EDGE_COLOR,
    edge_width = DEFAULT_EDGE_WIDTH,
    arrow_size = DEFAULT_ARROW_SIZE,
    arrow_shift = DEFAULT_ARROW_SHIFT,
    # Labels
    nlabels = nothing,
    nlabels_align = DEFAULT_LABEL_ALIGN,
    auto_align_labels = true,
    nlabels_distance = DEFAULT_LABEL_DISTANCE,
    nlabels_fontsize = DEFAULT_LABEL_FONTSIZE,
    nlabels_color = DEFAULT_LABEL_COLOR,
    # Pass-through
    kwargs...
)
    # Determine if we should use GraphMakie's nlabels_auto_align
    # (requires our fork or upstream integration)
    use_graphmakie_auto_align = auto_align_labels && nlabels !== nothing
    
    # Plot the graph using GraphMakie
    p = graphplot!(ax, g;
        layout = layout,
        node_size = node_size,
        node_color = node_color,
        node_strokewidth = node_strokewidth,
        node_strokecolor = node_strokecolor,
        node_marker = node_marker,
        edge_color = edge_color,
        edge_width = edge_width,
        arrow_size = arrow_size,
        arrow_shift = arrow_shift,
        nlabels = nlabels,
        nlabels_align = nlabels_align,
        nlabels_auto_align = use_graphmakie_auto_align,
        nlabels_distance = nlabels_distance,
        nlabels_fontsize = nlabels_fontsize,
        nlabels_color = nlabels_color,
        kwargs...
    )
    
    # Apply clean theme
    apply_dag_theme!(ax)
    
    # Set limits with padding
    tightlimits!(ax)
    node_positions = p[:node_pos][]
    
    if !isempty(node_positions)
        # Compute label alignments for bounds calculation
        if nlabels !== nothing
            if auto_align_labels
                # Use our algorithm to get alignments for bounds
                computed_aligns = compute_auto_label_aligns(g, node_positions)
                # For isolated nodes, use fallback
                for i in 1:length(computed_aligns)
                    has_edges = false
                    for j in 1:Graphs.nv(g)
                        if Graphs.has_edge(g, i, j) || Graphs.has_edge(g, j, i)
                            has_edges = true
                            break
                        end
                    end
                    if !has_edges
                        computed_aligns[i] = _get_align(nlabels_align, i)
                    end
                end
                label_aligns = computed_aligns
            else
                label_aligns = if nlabels_align isa Tuple
                    [nlabels_align for _ in 1:length(node_positions)]
                else
                    nlabels_align
                end
            end
            
            xlim, ylim = compute_padded_limits(
                node_positions, nlabels, label_aligns, 
                nlabels_distance, nlabels_fontsize;
                padding = padding
            )
        else
            # No labels, just use node positions
            ext = graph_extent(node_positions)
            x_pad = padding * ext.x_range
            y_pad = padding * ext.y_range
            xlim = (ext.x_min - x_pad, ext.x_max + x_pad)
            ylim = (ext.y_min - y_pad, ext.y_max + y_pad)
        end
        
        xlims!(ax, xlim)
        ylims!(ax, ylim)
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
    # Extract labels and colours from spec
    nlabels = [n.label for n in spec.nodes]
    node_colors = [n.color !== nothing ? n.color : default_node_color(n.type) for n in spec.nodes]
    node_sizes = [n.size !== nothing ? n.size : DEFAULT_NODE_SIZE for n in spec.nodes]
    
    return dagplot(spec.graph;
        figure_size = figure_size,
        nlabels = nlabels,
        node_color = node_colors,
        node_size = node_sizes,
        kwargs...
    )
end

"""
    dagplot!(ax, spec::DAGSpec; kwargs...)

Plot a DAG from a DAGSpec specification into an existing axis.
"""
function dagplot!(ax, spec::DAGSpec; kwargs...)
    nlabels = [n.label for n in spec.nodes]
    node_colors = [n.color !== nothing ? n.color : default_node_color(n.type) for n in spec.nodes]
    node_sizes = [n.size !== nothing ? n.size : DEFAULT_NODE_SIZE for n in spec.nodes]
    
    return dagplot!(ax, spec.graph;
        nlabels = nlabels,
        node_color = node_colors,
        node_size = node_sizes,
        kwargs...
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
    layout = Spring(),
    padding::Float64 = DEFAULT_PADDING,
    # Nodes
    node_size = DEFAULT_NODE_SIZE,
    node_color = DEFAULT_NODE_COLOR,
    node_strokewidth = DEFAULT_NODE_STROKEWIDTH,
    node_strokecolor = DEFAULT_NODE_STROKECOLOR,
    node_marker = :circle,
    # Directed edges
    edge_color = DEFAULT_EDGE_COLOR,
    edge_width = DEFAULT_EDGE_WIDTH,
    arrow_size = DEFAULT_ARROW_SIZE,
    arrow_shift = DEFAULT_ARROW_SHIFT,
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
    nlabels_distance = DEFAULT_LABEL_DISTANCE,
    nlabels_fontsize = DEFAULT_LABEL_FONTSIZE,
    nlabels_color = DEFAULT_LABEL_COLOR,
    # Pass-through
    kwargs...
)
    # Plot the directed part using standard dagplot
    p = dagplot!(ax, mg.directed;
        layout = layout,
        padding = padding,
        node_size = node_size,
        node_color = node_color,
        node_strokewidth = node_strokewidth,
        node_strokecolor = node_strokecolor,
        node_marker = node_marker,
        edge_color = edge_color,
        edge_width = edge_width,
        arrow_size = arrow_size,
        arrow_shift = arrow_shift,
        nlabels = nlabels,
        nlabels_align = nlabels_align,
        auto_align_labels = auto_align_labels,
        nlabels_distance = nlabels_distance,
        nlabels_fontsize = nlabels_fontsize,
        nlabels_color = nlabels_color,
        kwargs...
    )
    
    # Add bidirected edges if any
    if num_bidirected_edges(mg) > 0
        positions = p[:node_pos][]
        
        # Draw bidirected edge paths
        paths = compute_all_bidirected_paths(mg, positions; curvature = bidirected_curvature)
        for path in paths
            lines!(ax, path;
                color = bidirected_color,
                linewidth = bidirected_width,
                linestyle = bidirected_style
            )
        end
        
        # Draw arrowheads on bidirected edges
        arrows = bidirected_arrow_positions(mg, positions; 
            curvature = bidirected_curvature,
            arrow_offset = 0.15
        )
        
        if !isempty(arrows.positions)
            scatter!(ax, arrows.positions;
                marker = '➤',
                markersize = bidirected_arrow_size,
                color = bidirected_color,
                rotation = Billboard(arrows.rotations),
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
