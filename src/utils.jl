"""
Utility functions for DAGMakie.jl
"""

using Graphs: AbstractGraph, nv, ne, edges, src, dst, has_edge
using LinearAlgebra: norm
using Makie: Point2f

"""
    apply_dag_theme!(ax)

Apply clean DAG theme to an existing axis.

Hides all axis decorations (spines, ticks, labels, grid) and sets
DataAspect for proper graph proportions.

# Arguments
- `ax`: A Makie Axis object

# Example
```julia
fig = Figure()
ax = Axis(fig[1, 1])
apply_dag_theme!(ax)
graphplot!(ax, g)
```
"""
function apply_dag_theme!(ax)
    Makie.hidedecorations!(ax)
    Makie.hidespines!(ax)
    ax.aspect = Makie.DataAspect()
    return ax
end

"""
    _plot_has_attr(p, key::Symbol) -> Bool

Return whether a GraphMakie plot exposes attribute `key` (Makie 0.23 Dict attrs
or 0.24+ compute-pipeline attrs).
"""
function _plot_has_attr(p, key::Symbol)
    return haskey(p.attributes, key)
end

"""
    _plot_attr(p, key::Symbol, default)

Return `p[key][]` when present, otherwise `default`. Used so DAGMakie works when
GraphMakie has not yet published derived attributes (headless / older Makie).
"""
function _plot_attr(p, key::Symbol, default)
    return _plot_has_attr(p, key) ? p[key][] : default
end

"""
Fallback pixel transform when GraphMakie `:to_px` is unavailable: treat data
units as pixels so geometry helpers still run in headless tests.
"""
_default_to_px(p) = Point2f(p)

"""
    _plot_to_px(p)

Return GraphMakie's `:to_px` transform, or `_default_to_px` as a headless fallback.
"""
_plot_to_px(p) = _plot_attr(p, :to_px, _default_to_px)

"""
    get_node_positions(p)

Extract node positions from a GraphPlot object.

# Arguments
- `p`: A GraphMakie GraphPlot object

# Returns
- Vector of node positions (Point2f or Point3f)
"""
function get_node_positions(p)
    return p[:node_pos][]
end

"""
    graph_extent(node_positions)

Compute the spatial extent of a graph from node positions.

# Arguments
- `node_positions`: Vector of node positions

# Returns
- Named tuple `(x_min, x_max, y_min, y_max, x_range, y_range)`
"""
function graph_extent(node_positions::AbstractVector)
    xs = [Float64(pos[1]) for pos in node_positions]
    ys = [Float64(pos[2]) for pos in node_positions]
    
    x_min, x_max = extrema(xs)
    y_min, y_max = extrema(ys)
    
    return (
        x_min = x_min,
        x_max = x_max,
        y_min = y_min,
        y_max = y_max,
        x_range = x_max - x_min,
        y_range = y_max - y_min
    )
end

"""
    is_dag(g::AbstractGraph)

Check if a directed graph is acyclic (a valid DAG).

# Arguments
- `g`: A directed graph

# Returns
- `true` if the graph has no cycles, `false` otherwise
"""
function is_dag(g::AbstractGraph)
    # Use topological sort - if it succeeds, graph is acyclic
    try
        Graphs.topological_sort_by_dfs(g)
        return true
    catch
        return false
    end
end

"""
    edge_list(g::AbstractGraph)

Return a vector of (src, dst) tuples for all edges in the graph.
"""
function edge_list(g::AbstractGraph)
    return [(src(e), dst(e)) for e in edges(g)]
end

"""
    adjacency_to_graph(adj::AbstractMatrix)

Create a DiGraph from an adjacency matrix.

# Arguments
- `adj`: Square adjacency matrix where `adj[i,j] != 0` indicates edge i → j

# Returns
- `SimpleDiGraph` with edges from the adjacency matrix
"""
function adjacency_to_graph(adj::AbstractMatrix)
    n = size(adj, 1)
    @assert size(adj, 2) == n "Adjacency matrix must be square"
    
    g = Graphs.SimpleDiGraph(n)
    for i in 1:n
        for j in 1:n
            if adj[i, j] != 0
                Graphs.add_edge!(g, i, j)
            end
        end
    end
    
    return g
end

"""
    graph_from_edges(n::Int, edge_pairs::Vector{Tuple{Int, Int}})

Create a DiGraph from a list of edge pairs.

# Arguments
- `n`: Number of vertices
- `edge_pairs`: Vector of (src, dst) tuples

# Returns
- `SimpleDiGraph` with the specified edges

# Example
```julia
g = graph_from_edges(3, [(1, 2), (2, 3), (1, 3)])
```
"""
function graph_from_edges(n::Int, edge_pairs::Vector{Tuple{Int, Int}})
    g = Graphs.SimpleDiGraph(n)
    for (s, d) in edge_pairs
        Graphs.add_edge!(g, s, d)
    end
    return g
end

"""
    pixel_delta_to_data(delta_px, to_px)

Convert a pixel-space offset into a data-space offset for the current axis.
"""
function pixel_delta_to_data(delta_px::Point2f, to_px)
    origin_px = to_px(Point2f(0, 0))
    unit_x_px = to_px(Point2f(1, 0))
    unit_y_px = to_px(Point2f(0, 1))

    scale_x = Float64(unit_x_px[1] - origin_px[1])
    scale_y = Float64(unit_y_px[2] - origin_px[2])

    safe_scale_x = abs(scale_x) > 1e-6 ? scale_x : 1.0
    safe_scale_y = abs(scale_y) > 1e-6 ? scale_y : 1.0

    return Point2f(delta_px[1] / safe_scale_x, delta_px[2] / safe_scale_y)
end

"""
    polyline_point_at_distance(path, distance_px, to_px; from_start=true)

Return the point `distance_px` pixels along a polyline.
"""
function polyline_point_at_distance(
    path::AbstractVector,
    distance_px::Real,
    to_px;
    from_start::Bool = true,
)
    @assert length(path) >= 2 "A polyline requires at least two points."

    ordered_path = from_start ? collect(path) : reverse(collect(path))
    remaining = Float64(distance_px)

    for index in 1:(length(ordered_path) - 1)
        p1 = Point2f(ordered_path[index])
        p2 = Point2f(ordered_path[index + 1])
        segment_px = to_px(p2) - to_px(p1)
        segment_length_px = norm(segment_px)

        if segment_length_px <= 1e-6
            continue
        end

        if remaining <= segment_length_px
            fraction = remaining / segment_length_px
            return p1 + fraction * (p2 - p1)
        end

        remaining -= segment_length_px
    end

    return Point2f(ordered_path[end])
end

"""
    trim_polyline(path, start_distance_px, end_distance_px, to_px)

Trim a polyline by pixel distances from the start and end.
"""
function trim_polyline(
    path::AbstractVector,
    start_distance_px::Real,
    end_distance_px::Real,
    to_px,
)
    @assert length(path) >= 2 "A polyline requires at least two points."

    ordered_points = Point2f.(path)
    trimmed_points = Point2f[
        polyline_point_at_distance(ordered_points, start_distance_px, to_px; from_start = true),
    ]

    traversed = 0.0
    full_length = polyline_length_px(ordered_points, to_px)
    stop_length = max(full_length - Float64(end_distance_px), Float64(start_distance_px))

    for index in 1:(length(ordered_points) - 1)
        p1 = ordered_points[index]
        p2 = ordered_points[index + 1]
        segment_length_px = norm(to_px(p2) - to_px(p1))
        next_traversed = traversed + segment_length_px

        if next_traversed < start_distance_px
            traversed = next_traversed
            continue
        end

        if traversed > stop_length
            break
        end

        if traversed >= start_distance_px && next_traversed <= stop_length
            push!(trimmed_points, p2)
        else
            local_distance = max(stop_length - traversed, 0.0)
            if local_distance <= segment_length_px
                fraction = segment_length_px <= 1e-6 ? 0.0 : local_distance / segment_length_px
                push!(trimmed_points, p1 + fraction * (p2 - p1))
                break
            end
        end

        traversed = next_traversed
    end

    end_point = polyline_point_at_distance(ordered_points, end_distance_px, to_px; from_start = false)
    if isempty(trimmed_points) || norm(trimmed_points[end] - end_point) > 1e-6
        push!(trimmed_points, end_point)
    end

    return trimmed_points
end

"""
    polyline_length_px(path, to_px)

Compute the pixel length of a polyline.
"""
function polyline_length_px(path::AbstractVector, to_px)
    total_length = 0.0
    for index in 1:(length(path) - 1)
        total_length += norm(to_px(Point2f(path[index + 1])) - to_px(Point2f(path[index])))
    end
    return total_length
end

"""
    chain_graph(labels::Vector{String})

Create a simple chain DAG: X₁ → X₂ → ... → Xₙ

# Arguments
- `labels`: Vector of node labels

# Returns
- Tuple `(g, labels)` where `g` is the graph
"""
function chain_graph(labels::Vector{String})
    n = length(labels)
    g = Graphs.SimpleDiGraph(n)
    for i in 1:(n-1)
        Graphs.add_edge!(g, i, i+1)
    end
    return (g, labels)
end

"""
    fork_graph(labels::Vector{String})

Create a fork DAG: X₁ ← X₂ → X₃ (with X₂ as the fork point)

Assumes 3 nodes: labels[1] ← labels[2] → labels[3]

# Arguments
- `labels`: Vector of 3 node labels

# Returns
- Tuple `(g, labels)` where `g` is the graph
"""
function fork_graph(labels::Vector{String})
    @assert length(labels) == 3 "Fork graph requires exactly 3 nodes"
    g = Graphs.SimpleDiGraph(3)
    Graphs.add_edge!(g, 2, 1)  # Fork → Left
    Graphs.add_edge!(g, 2, 3)  # Fork → Right
    return (g, labels)
end

"""
    collider_graph(labels::Vector{String})

Create a collider DAG: X₁ → X₂ ← X₃ (with X₂ as the collider)

Assumes 3 nodes: labels[1] → labels[2] ← labels[3]

# Arguments
- `labels`: Vector of 3 node labels

# Returns
- Tuple `(g, labels)` where `g` is the graph
"""
function collider_graph(labels::Vector{String})
    @assert length(labels) == 3 "Collider graph requires exactly 3 nodes"
    g = Graphs.SimpleDiGraph(3)
    Graphs.add_edge!(g, 1, 2)  # Left → Collider
    Graphs.add_edge!(g, 3, 2)  # Right → Collider
    return (g, labels)
end

"""
    confounding_graph(labels::Vector{String})

Create a classic confounding DAG: Z → X → Y, Z → Y

Assumes 3 nodes: Z (confounder), X (treatment), Y (outcome)

# Arguments  
- `labels`: Vector of 3 node labels [Z, X, Y]

# Returns
- Tuple `(g, labels)` where `g` is the graph
"""
function confounding_graph(labels::Vector{String})
    @assert length(labels) == 3 "Confounding graph requires exactly 3 nodes"
    g = Graphs.SimpleDiGraph(3)
    Graphs.add_edge!(g, 1, 2)  # Z → X
    Graphs.add_edge!(g, 1, 3)  # Z → Y
    Graphs.add_edge!(g, 2, 3)  # X → Y
    return (g, labels)
end

"""
    mediation_graph(labels::Vector{String})

Create a mediation DAG: X → M → Y, X → Y

Assumes 3 nodes: X (treatment), M (mediator), Y (outcome)

# Arguments
- `labels`: Vector of 3 node labels [X, M, Y]

# Returns
- Tuple `(g, labels)` where `g` is the graph
"""
function mediation_graph(labels::Vector{String})
    @assert length(labels) == 3 "Mediation graph requires exactly 3 nodes"
    g = Graphs.SimpleDiGraph(3)
    Graphs.add_edge!(g, 1, 2)  # X → M
    Graphs.add_edge!(g, 2, 3)  # M → Y
    Graphs.add_edge!(g, 1, 3)  # X → Y (direct effect)
    return (g, labels)
end

"""
    instrumental_graph(labels::Vector{String})

Create an instrumental variable DAG: Z → X → Y, U → X, U → Y

Assumes 4 nodes: Z (instrument), X (treatment), Y (outcome), U (unobserved confounder)

# Arguments
- `labels`: Vector of 4 node labels [Z, X, Y, U]

# Returns
- Tuple `(g, labels)` where `g` is the graph
"""
function instrumental_graph(labels::Vector{String})
    @assert length(labels) == 4 "Instrumental graph requires exactly 4 nodes"
    g = Graphs.SimpleDiGraph(4)
    Graphs.add_edge!(g, 1, 2)  # Z → X (instrument)
    Graphs.add_edge!(g, 2, 3)  # X → Y
    Graphs.add_edge!(g, 4, 2)  # U → X (confounding)
    Graphs.add_edge!(g, 4, 3)  # U → Y (confounding)
    return (g, labels)
end
