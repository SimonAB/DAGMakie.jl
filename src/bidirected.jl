# SPDX-License-Identifier: MIT

"""
Bidirected edge support for causal diagrams.

Bidirected edges (↔) represent unmeasured common causes (latent confounders)
in causal diagrams. This module provides:
- MixedGraph type for graphs with both directed and bidirected edges
- Rendering of bidirected edges as curved arcs with double arrowheads
"""

using Graphs: AbstractGraph, SimpleDiGraph, nv, ne, add_edge!, has_edge, edges, src, dst
using Makie: Point2f
using GraphMakie: Arrow, distance_between_markers

# =============================================================================
# MixedGraph Type
# =============================================================================

"""
    MixedGraph

A graph that supports both directed edges (→) and bidirected edges (↔).

Bidirected edges represent unmeasured common causes (latent confounders) in
causal diagrams. Internally, bidirected edges are stored separately from
the directed graph structure.

# Fields
- `directed::SimpleDiGraph`: The directed edges
- `bidirected::Set{Tuple{Int, Int}}`: Set of bidirected edge pairs (unordered)

# Examples
```julia
# Create a mixed graph with confounding
mg = MixedGraph(3)
add_directed_edge!(mg, 1, 3)  # X → Y
add_directed_edge!(mg, 2, 3)  # Z → Y
add_bidirected_edge!(mg, 1, 2)  # X ↔ Z (unmeasured confounder)

# Or from existing directed graph
g = SimpleDiGraph(3)
add_edge!(g, 1, 3)
add_edge!(g, 2, 3)
mg = MixedGraph(g, [(1, 2)])  # Add bidirected edge
```
"""
struct MixedGraph <: AbstractGraph{Int}
    directed::SimpleDiGraph{Int}
    bidirected::Set{Tuple{Int, Int}}
end

"""
    MixedGraph(n::Int)

Create a MixedGraph with `n` vertices and no edges.
"""
function MixedGraph(n::Int)
    return MixedGraph(SimpleDiGraph(n), Set{Tuple{Int, Int}}())
end

"""
    MixedGraph(g::SimpleDiGraph)

Create a MixedGraph from an existing directed graph (no bidirected edges).
"""
function MixedGraph(g::SimpleDiGraph)
    return MixedGraph(g, Set{Tuple{Int, Int}}())
end

"""
    MixedGraph(g::SimpleDiGraph, bidirected_pairs)

Create a MixedGraph from a directed graph with specified bidirected edges.

# Arguments
- `g::SimpleDiGraph`: The directed graph
- `bidirected_pairs`: Iterable of `(i, j)` pairs for bidirected edges
"""
function MixedGraph(g::SimpleDiGraph, bidirected_pairs)
    bi_set = Set{Tuple{Int, Int}}()
    for (i, j) in bidirected_pairs
        # Store in canonical order (smaller index first)
        push!(bi_set, i < j ? (i, j) : (j, i))
    end
    return MixedGraph(g, bi_set)
end

# Implement AbstractGraph interface
Graphs.nv(mg::MixedGraph) = nv(mg.directed)
Graphs.ne(mg::MixedGraph) = ne(mg.directed)  # Only directed edges
Graphs.vertices(mg::MixedGraph) = Graphs.vertices(mg.directed)
Graphs.edges(mg::MixedGraph) = edges(mg.directed)
Graphs.has_edge(mg::MixedGraph, i::Int, j::Int) = has_edge(mg.directed, i, j)
Graphs.is_directed(::Type{MixedGraph}) = true
Graphs.is_directed(::MixedGraph) = true

# Forward other graph methods to directed graph
Graphs.inneighbors(mg::MixedGraph, v::Int) = Graphs.inneighbors(mg.directed, v)
Graphs.outneighbors(mg::MixedGraph, v::Int) = Graphs.outneighbors(mg.directed, v)

# =============================================================================
# Edge manipulation
# =============================================================================

"""
    add_directed_edge!(mg::MixedGraph, i::Int, j::Int)

Add a directed edge i → j to the mixed graph.
"""
function add_directed_edge!(mg::MixedGraph, i::Int, j::Int)
    add_edge!(mg.directed, i, j)
    return mg
end

"""
    add_bidirected_edge!(mg::MixedGraph, i::Int, j::Int)

Add a bidirected edge i ↔ j to the mixed graph.
"""
function add_bidirected_edge!(mg::MixedGraph, i::Int, j::Int)
    # Store in canonical order
    pair = i < j ? (i, j) : (j, i)
    push!(mg.bidirected, pair)
    return mg
end

"""
    has_bidirected_edge(mg::MixedGraph, i::Int, j::Int)

Check if there is a bidirected edge between nodes i and j.
"""
function has_bidirected_edge(mg::MixedGraph, i::Int, j::Int)
    pair = i < j ? (i, j) : (j, i)
    return pair in mg.bidirected
end

"""
    bidirected_edges(mg::MixedGraph)

Return an iterator over all bidirected edge pairs.
"""
bidirected_edges(mg::MixedGraph) = mg.bidirected

"""
    num_bidirected_edges(mg::MixedGraph)

Return the number of bidirected edges.
"""
num_bidirected_edges(mg::MixedGraph) = length(mg.bidirected)

# =============================================================================
# Bidirected Edge Path Calculation
# =============================================================================

"""
    compute_bidirected_path(p1::Point2f, p2::Point2f; curvature=0.3)

Compute a curved path for a bidirected edge between two points.

Returns a vector of points representing a quadratic Bézier curve that arcs
above the straight line connecting the two points.

# Arguments
- `p1`: Start point
- `p2`: End point
- `curvature::Float64 = 0.3`: How much the arc curves (fraction of distance)

# Returns
- Vector of Point2f representing the curved path
"""
function compute_bidirected_path(p1::Point2f, p2::Point2f; curvature::Float64 = 0.3)
    # Midpoint
    mid = (p1 + p2) / 2
    
    # Direction vector and perpendicular
    dir = p2 - p1
    dist = sqrt(dir[1]^2 + dir[2]^2)
    
    if dist < 1e-6
        return [p1, p2]
    end
    
    # Normalised perpendicular (rotate 90 degrees counterclockwise)
    perp = Point2f(-dir[2], dir[1]) / dist
    
    # Control point offset
    offset = curvature * dist
    control = mid + offset * perp
    
    # Generate points along quadratic Bézier curve
    # B(t) = (1-t)²P1 + 2(1-t)t·C + t²P2
    n_points = 20
    path = Vector{Point2f}(undef, n_points)
    
    for i in 1:n_points
        t = (i - 1) / (n_points - 1)
        path[i] = (1 - t)^2 * p1 + 2 * (1 - t) * t * control + t^2 * p2
    end
    
    return path
end

"""
    compute_all_bidirected_paths(mg::MixedGraph, positions::AbstractVector; curvature=0.3)

Compute curved paths for all bidirected edges in a mixed graph.

# Arguments
- `mg`: The mixed graph
- `positions`: Vector of node positions
- `curvature`: Arc curvature parameter

# Returns
- Vector of path vectors, one per bidirected edge
"""
function compute_all_bidirected_paths(
    mg::MixedGraph, 
    positions::AbstractVector;
    curvature::Float64 = 0.3
)
    paths = Vector{Vector{Point2f}}()

    for (i, j) in _sorted_bidirected_edges(mg)
        p1 = Point2f(positions[i])
        p2 = Point2f(positions[j])
        path = compute_bidirected_path(p1, p2; curvature = curvature)
        push!(paths, path)
    end
    
    return paths
end

"""
    bidirected_arrow_positions(mg::MixedGraph, positions::AbstractVector; curvature=0.3, arrow_offset=0.1)

Compute positions and rotations for arrowheads on bidirected edges.

Returns positions and rotation angles for arrows at both ends of each
bidirected edge.

# Arguments
- `mg`: The mixed graph
- `positions`: Vector of node positions
- `curvature`: Arc curvature parameter
- `arrow_offset`: How far from the node centre to place arrows (0-0.5)

# Returns
- Named tuple with:
  - `positions`: Vector of Point2f for arrow positions
  - `rotations`: Vector of Float64 rotation angles
  - `edge_indices`: Which bidirected edge each arrow belongs to
"""
function bidirected_arrow_positions(
    mg::MixedGraph, 
    positions::AbstractVector;
    curvature::Float64 = 0.3,
    arrow_offset::Float64 = 0.15
)
    arrow_pos = Point2f[]
    arrow_rot = Float64[]
    edge_idx = Int[]
    
    for (idx, (i, j)) in enumerate(_sorted_bidirected_edges(mg))
        p1 = Point2f(positions[i])
        p2 = Point2f(positions[j])
        path = compute_bidirected_path(p1, p2; curvature = curvature)
        
        n = length(path)
        
        # Arrow near node i (at start of path)
        start_idx = max(1, round(Int, arrow_offset * n))
        if start_idx < n
            pos_start = path[start_idx]
            # Tangent direction at this point
            tangent_start = path[min(start_idx + 1, n)] - path[max(start_idx - 1, 1)]
            rot_start = atan(tangent_start[2], tangent_start[1]) + π  # Point towards node
            push!(arrow_pos, pos_start)
            push!(arrow_rot, rot_start)
            push!(edge_idx, idx)
        end
        
        # Arrow near node j (at end of path)
        end_idx = min(n, round(Int, (1 - arrow_offset) * n))
        if end_idx > 1
            pos_end = path[end_idx]
            tangent_end = path[min(end_idx + 1, n)] - path[max(end_idx - 1, 1)]
            rot_end = atan(tangent_end[2], tangent_end[1])  # Point towards node
            push!(arrow_pos, pos_end)
            push!(arrow_rot, rot_end)
            push!(edge_idx, idx)
        end
    end
    
    return (positions = arrow_pos, rotations = arrow_rot, edge_indices = edge_idx)
end

"""
    compute_bidirected_geometry(mg, positions, node_markers, node_sizes, to_px; curvature=0.3, arrow_size=8)

Compute boundary-aware paths and arrowheads for bidirected confounding edges.
"""
function compute_bidirected_geometry(
    mg::MixedGraph,
    positions::AbstractVector,
    node_markers,
    node_sizes,
    to_px;
    curvature::Float64 = 0.3,
    arrow_size::Real = 8,
)
    paths = Vector{Vector{Point2f}}()
    arrow_positions = Point2f[]
    arrow_rotations = Float64[]
    boundary_points = Point2f[]

    for (i, j) in _sorted_bidirected_edges(mg)
        path = compute_bidirected_path(Point2f(positions[i]), Point2f(positions[j]); curvature = curvature)
        start_distance = distance_between_markers(
            _attribute_value(node_markers, i),
            _attribute_value(node_sizes, i),
            Arrow,
            arrow_size,
        )
        end_distance = distance_between_markers(
            _attribute_value(node_markers, j),
            _attribute_value(node_sizes, j),
            Arrow,
            arrow_size,
        )

        r_start = pixel_length_to_data(start_distance, to_px)
        r_end = pixel_length_to_data(end_distance, to_px)
        trimmed_path = trim_polyline_to_circles(
            path,
            Point2f(positions[i]),
            r_start,
            Point2f(positions[j]),
            r_end,
        )
        length(trimmed_path) < 2 && (trimmed_path = path)

        push!(paths, trimmed_path)
        append!(boundary_points, trimmed_path)

        push!(arrow_positions, first(trimmed_path))
        push!(arrow_rotations, _polyline_rotation(trimmed_path, to_px; from_start = true, reverse_direction = true))
        push!(arrow_positions, last(trimmed_path))
        push!(arrow_rotations, _polyline_rotation(trimmed_path, to_px; from_start = false, reverse_direction = false))
    end

    return (
        paths = paths,
        arrow_positions = arrow_positions,
        arrow_rotations = arrow_rotations,
        boundary_points = boundary_points,
    )
end

function _sorted_bidirected_edges(mg::MixedGraph)
    return sort!(collect(bidirected_edges(mg)))
end

function _attribute_value(value, index::Int)
    return value isa AbstractVector ? value[index] : value
end

function _polyline_rotation(path::AbstractVector, to_px; from_start::Bool, reverse_direction::Bool)
    if length(path) < 2
        return 0.0
    end

    p1, p2 = if from_start
        (Point2f(path[1]), Point2f(path[2]))
    else
        (Point2f(path[end - 1]), Point2f(path[end]))
    end

    tangent_px = to_px(p2) - to_px(p1)
    if reverse_direction
        tangent_px = -tangent_px
    end

    return atan(tangent_px[2], tangent_px[1])
end

# =============================================================================
# Convenience constructors
# =============================================================================

"""
    mixed_graph(n::Int, directed_edges, bidirected_edges)

Create a MixedGraph with specified directed and bidirected edges.

# Arguments
- `n::Int`: Number of vertices
- `directed_edges`: Iterable of `(src, dst)` pairs for directed edges
- `bidirected_edges`: Iterable of `(i, j)` pairs for bidirected edges

# Examples
```julia
# Confounded treatment-outcome graph
mg = mixed_graph(2, [(1, 2)], [(1, 2)])  # X → Y with X ↔ Y

# Instrumental variable setup
mg = mixed_graph(4,
    [(1, 2), (2, 3)],  # Z → X → Y
    [(2, 3)]           # X ↔ Y (unmeasured confounding)
)
```
"""
function mixed_graph(n::Int, directed_edges, bidirected_edges)
    g = SimpleDiGraph(n)
    for (s, d) in directed_edges
        add_edge!(g, s, d)
    end
    return MixedGraph(g, bidirected_edges)
end

"""
    confounded_graph(labels::Vector{String})

Create a simple confounded graph: X → Y with X ↔ Y (unmeasured confounder).

# Arguments
- `labels`: Vector of 2 labels [treatment, outcome]

# Returns
- Tuple `(mg, labels)` where `mg` is a MixedGraph
"""
function confounded_graph(labels::Vector{String})
    @assert length(labels) == 2 "Confounded graph requires exactly 2 nodes"
    mg = mixed_graph(2, [(1, 2)], [(1, 2)])
    return (mg, labels)
end

"""
    frontdoor_graph(labels::Vector{String})

Create a frontdoor criterion graph: X → M → Y with X ↔ Y.

# Arguments
- `labels`: Vector of 3 labels [treatment, mediator, outcome]

# Returns
- Tuple `(mg, labels)` where `mg` is a MixedGraph
"""
function frontdoor_graph(labels::Vector{String})
    @assert length(labels) == 3 "Frontdoor graph requires exactly 3 nodes"
    mg = mixed_graph(3, 
        [(1, 2), (2, 3)],  # X → M → Y
        [(1, 3)]           # X ↔ Y (unmeasured confounding)
    )
    return (mg, labels)
end

"""
    iv_confounded_graph(labels::Vector{String})

Create an instrumental variable graph with confounding: Z → X → Y, X ↔ Y.

# Arguments
- `labels`: Vector of 3 labels [instrument, treatment, outcome]

# Returns
- Tuple `(mg, labels)` where `mg` is a MixedGraph
"""
function iv_confounded_graph(labels::Vector{String})
    @assert length(labels) == 3 "IV graph requires exactly 3 nodes"
    mg = mixed_graph(3,
        [(1, 2), (2, 3)],  # Z → X → Y
        [(2, 3)]           # X ↔ Y (unmeasured confounding)
    )
    return (mg, labels)
end

"""
    m_bias_graph(labels)

Create the classic five-node M-bias DAG with explicit latents:

```
U₁ → X, U₁ → M, U₂ → M, U₂ → Y
```

No directed edge ``X → Y`` (pure M-bias). Conditioning on the collider ``M``
opens the non-causal path ``X ← U₁ → M ← U₂ → Y``.

# Arguments
- `labels`: Vector of 5 labels ``[U₁, U₂, X, M, Y]`` (defaults to those symbols)

# Returns
- Tuple `(mg, labels)` where `mg` is a `MixedGraph` with no bidirected edges
  (latents are drawn explicitly rather than as ``X ↔ M ↔ Y``)
"""
function m_bias_graph(
    labels::Vector{<:AbstractString} = ["U₁", "U₂", "X", "M", "Y"],
)
    length(labels) == 5 || throw(ArgumentError(
        "expected 5 labels [U₁, U₂, X, M, Y]",
    ))
    g = SimpleDiGraph(5)
    add_edge!(g, 1, 3)  # U₁ → X
    add_edge!(g, 1, 4)  # U₁ → M
    add_edge!(g, 2, 4)  # U₂ → M
    add_edge!(g, 2, 5)  # U₂ → Y
    return (MixedGraph(g), String.(labels))
end

"""
    m_bias_spec(labels)

DAGSpec for the five-node M-bias DAG with latent / collider styling.

Same edges as [`m_bias_graph`](@ref): ``U₁ → X``, ``U₁ → M``, ``U₂ → M``,
``U₂ → Y``.
"""
function m_bias_spec(
    labels::Vector{<:AbstractString} = ["U₁", "U₂", "X", "M", "Y"],
)
    length(labels) == 5 || throw(ArgumentError(
        "expected 5 labels [U₁, U₂, X, M, Y]",
    ))
    g = SimpleDiGraph(5)
    add_edge!(g, 1, 3)  # U₁ → X
    add_edge!(g, 1, 4)  # U₁ → M
    add_edge!(g, 2, 4)  # U₂ → M
    add_edge!(g, 2, 5)  # U₂ → Y
    nodes = [
        NodeSpec(labels[1]; type = Latent),
        NodeSpec(labels[2]; type = Latent),
        NodeSpec(labels[3]; type = Treatment),
        NodeSpec(labels[4]; type = Collider),
        NodeSpec(labels[5]; type = Outcome),
    ]
    return DAGSpec(g, nodes, EdgeSpec[], "M-bias")
end
