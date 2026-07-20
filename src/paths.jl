"""
Path data types for DAG visualisation highlights.

Identification algorithms (d-separation, adjustment sets, path search) live in
CausalInference.jl. These types only describe paths already computed elsewhere
so `HighlightSpec` helpers can colour edges.
"""

"""
    PathSegment

A segment of a path, tracking the direction of traversal.

# Fields
- `node::Int`: The node in this segment
- `direction::Symbol`: `:forward` (→), `:backward` (←), or `:start`
"""
struct PathSegment
    node::Int
    direction::Symbol
end

"""
    CausalPath

A path through a DAG, tracking nodes and edge directions (forward or backward
along graph edges).

# Fields
- `nodes::Vector{Int}`: Sequence of nodes
- `directions::Vector{Symbol}`: Direction of each edge (`:forward` or `:backward`)
"""
struct CausalPath
    nodes::Vector{Int}
    directions::Vector{Symbol}  # Length = length(nodes) - 1
end

Base.length(p::CausalPath) = length(p.nodes)
Base.first(p::CausalPath) = first(p.nodes)
Base.last(p::CausalPath) = last(p.nodes)

"""
    CausalPath(nodes::Vector{Int}; directions=nothing)

Build a path from node indices. If `directions` is omitted, all edges are
treated as forward (a directed causal path).
"""
function CausalPath(nodes::Vector{Int}; directions = nothing)
    isempty(nodes) && return CausalPath(Int[], Symbol[])
    if directions === nothing
        directions = fill(:forward, max(0, length(nodes) - 1))
    end
    length(directions) == length(nodes) - 1 ||
        throw(ArgumentError("directions length must be length(nodes) - 1"))
    return CausalPath(nodes, directions)
end

"""
    path_edges(path::CausalPath)

Return the edges in a path as `(src, dst)` tuples in graph orientation.
"""
function path_edges(path::CausalPath)
    result = Tuple{Int, Int}[]
    for i in 1:(length(path.nodes) - 1)
        if path.directions[i] == :forward
            push!(result, (path.nodes[i], path.nodes[i + 1]))
        else
            push!(result, (path.nodes[i + 1], path.nodes[i]))
        end
    end
    return result
end

"""
    is_directed_path(path::CausalPath)

Return `true` if every edge in the path is forward (a directed causal path).
"""
is_directed_path(path::CausalPath) = all(d -> d == :forward, path.directions)
