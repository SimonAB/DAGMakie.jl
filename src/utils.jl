"""
Utility functions for DAGMakie.jl
"""

using Graphs: AbstractGraph, nv, ne, edges, src, dst, has_edge

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
