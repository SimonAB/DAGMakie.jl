"""
Automatic label alignment algorithm for DAG visualisation.

Computes optimal label positions by finding the largest angular gap
between incident edges for each node, preventing label-edge overlaps.
"""

using Graphs: AbstractGraph, nv, has_edge

"""
    compute_auto_label_aligns(g::AbstractGraph, node_positions::AbstractVector)

Compute optimal label alignment for each node to avoid edge overlaps.

For each node, finds the largest angular gap between incident edges and places
the label in the middle of that gap. This ensures labels do not overlap with
edges, improving readability of causal diagrams.

# Arguments
- `g::AbstractGraph`: A graph from Graphs.jl (directed or undirected)
- `node_positions::AbstractVector`: Vector of node positions (Point2f or similar)

# Returns
- `Vector{Tuple{Symbol, Symbol}}`: Alignment tuples `(:horizontal, :vertical)` for each node,
  suitable for use with `nlabels_align` in GraphMakie.

# Algorithm
1. For each node, collect angles of all incident edges (both incoming and outgoing)
2. Normalise angles to [0, 2π] and sort
3. Find the largest angular gap between adjacent edges (including wrap-around)
4. Place label in the middle of the largest gap
5. Map the gap midpoint angle to one of 8 alignment directions

# Edge Cases
- Isolated nodes (no incident edges): Returns `(:right, :bottom)` as default
- Single edge: Places label opposite the edge direction
- All edges in one direction: Places label in the opposite hemisphere

# Examples
```julia
using Graphs, DAGMakie

g = SimpleDiGraph(3)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)

# Compute positions (e.g., from a layout algorithm)
positions = [Point2f(0, 0), Point2f(1, 0), Point2f(2, 0)]

# Get optimal alignments
aligns = compute_auto_label_aligns(g, positions)
# aligns[1] might be (:center, :top) since edge goes right
# aligns[2] might be (:center, :top) since edges go left and right
# aligns[3] might be (:center, :top) since edge goes left
```

# Notes
- Works with any layout algorithm (uses computed node positions)
- Handles both directed and undirected graphs
- Time complexity: O(V × E) where V is vertices and E is edges
"""
function compute_auto_label_aligns(g::AbstractGraph, node_positions::AbstractVector)
    n = nv(g)
    aligns = Vector{Tuple{Symbol, Symbol}}(undef, n)
    
    for node in 1:n
        node_pos = node_positions[node]
        edge_angles = Float64[]
        
        # Collect angles of ALL incident edges (both incoming and outgoing)
        # Direction is FROM current node TO the connected node
        for other in 1:n
            if has_edge(g, other, node)  # Incoming edge
                other_pos = node_positions[other]
                dx = Float64(other_pos[1] - node_pos[1])
                dy = Float64(other_pos[2] - node_pos[2])
                push!(edge_angles, atan(dy, dx))
            end
            if has_edge(g, node, other)  # Outgoing edge
                other_pos = node_positions[other]
                dx = Float64(other_pos[1] - node_pos[1])
                dy = Float64(other_pos[2] - node_pos[2])
                push!(edge_angles, atan(dy, dx))
            end
        end
        
        # Default alignment for isolated nodes
        if isempty(edge_angles)
            aligns[node] = (:right, :bottom)
            continue
        end
        
        # Find the largest angular gap between adjacent edges
        aligns[node] = _angle_to_alignment(_find_best_gap_midpoint(edge_angles))
    end
    
    return aligns
end

"""
    _find_best_gap_midpoint(edge_angles::Vector{Float64})

Find the midpoint angle of the largest gap between sorted angles.

# Arguments
- `edge_angles`: Vector of angles in radians

# Returns
- Midpoint angle of the largest gap (in radians, range [-π, π])
"""
function _find_best_gap_midpoint(edge_angles::Vector{Float64})
    # Normalise angles to [0, 2π] and sort
    angles_norm = sort([mod(a + 2π, 2π) for a in edge_angles])
    
    # Find gaps between adjacent angles (including wrap-around gap)
    best_gap = 0.0
    best_midpoint = -π/4  # Default: Southeast (bottom-right)
    
    for i in 1:length(angles_norm)
        next_i = i == length(angles_norm) ? 1 : i + 1
        
        # Gap from angles_norm[i] to angles_norm[next_i]
        if next_i == 1
            # Wrap-around gap
            gap = (2π - angles_norm[i]) + angles_norm[1]
            midpoint = angles_norm[i] + gap / 2
            if midpoint > π
                midpoint -= 2π
            end
        else
            gap = angles_norm[next_i] - angles_norm[i]
            midpoint = angles_norm[i] + gap / 2
        end
        
        if gap > best_gap
            best_gap = gap
            best_midpoint = midpoint
        end
    end
    
    return best_midpoint
end

"""
    _angle_to_alignment(angle::Float64)

Convert an angle (in radians) to a Makie alignment tuple.

Maps angles to 8 cardinal/ordinal directions:
- 0 (East) → (:left, :center)
- π/4 (Northeast) → (:left, :bottom)
- π/2 (North) → (:center, :bottom)
- 3π/4 (Northwest) → (:right, :bottom)
- π (West) → (:right, :center)
- -3π/4 (Southwest) → (:right, :top)
- -π/2 (South) → (:center, :top)
- -π/4 (Southeast) → (:left, :top)

# Note on Makie alignment semantics
- `(:left, :center)` means label's LEFT edge is at anchor → label extends RIGHT (East)
- `(:right, :center)` means label's RIGHT edge is at anchor → label extends LEFT (West)
- `(:center, :bottom)` means label's BOTTOM is at anchor → label extends UP (North)
- `(:center, :top)` means label's TOP is at anchor → label extends DOWN (South)
"""
function _angle_to_alignment(angle::Float64)
    # Normalise to [0, 2π]
    angle_norm = mod(angle + 2π, 2π)
    
    # Map to 8 directions (each sector spans π/4 = 45°)
    # Sector boundaries centred on cardinal/ordinal directions
    return if angle_norm < π/8 || angle_norm >= 15π/8
        (:left, :center)       # East (right of node)
    elseif angle_norm < 3π/8
        (:left, :bottom)       # Northeast
    elseif angle_norm < 5π/8
        (:center, :bottom)     # North (above node)
    elseif angle_norm < 7π/8
        (:right, :bottom)      # Northwest
    elseif angle_norm < 9π/8
        (:right, :center)      # West (left of node)
    elseif angle_norm < 11π/8
        (:right, :top)         # Southwest
    elseif angle_norm < 13π/8
        (:center, :top)        # South (below node)
    else
        (:left, :top)          # Southeast
    end
end

"""
    align_to_direction(align::Tuple{Symbol, Symbol})

Convert an alignment tuple to a normalised direction vector.

# Arguments
- `align`: Tuple of `(:horizontal, :vertical)` alignment symbols

# Returns
- `Point2f`: Normalised direction vector pointing from node towards label

# Examples
```julia
align_to_direction((:left, :center))   # Point2f(1.0, 0.0) - East
align_to_direction((:right, :center))  # Point2f(-1.0, 0.0) - West
align_to_direction((:center, :bottom)) # Point2f(0.0, 1.0) - North
```
"""
function align_to_direction(align::Tuple{Symbol, Symbol})
    halign, valign = align
    
    x = if halign === :left
        1.0
    elseif halign === :right
        -1.0
    else
        0.0
    end
    
    y = if valign === :top
        -1.0
    elseif valign === :bottom
        1.0
    else
        0.0
    end
    
    # Normalise
    len = sqrt(x^2 + y^2)
    if len ≈ 0.0
        return (0.0, 0.0)
    end
    
    return (x / len, y / len)
end
