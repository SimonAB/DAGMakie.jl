# SPDX-License-Identifier: MIT

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
- Intended for **outside-node** labels: pair with a positive `nlabels_distance`
  (see [`resolve_auto_align_label_settings`](@ref)). With distance 0 the
  non-centred alignments only shift text inside the marker and look broken.
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

Convert a Makie text-box `align` to the offset direction GraphMakie uses with
`nlabels_distance`.

Makie `align` names the edge of the **label** that sits on the anchor. Combined
with a positive distance, that places the label on the **opposite** side of the
node (e.g. `(:left, :center)` → offset east → label to the right of the node).

# Arguments
- `align`: Tuple of `(:horizontal, :vertical)` Makie text-align symbols

# Returns
- Direction from node toward the label (for use as `distance .* dir`)

# Examples
```julia
align_to_direction((:left, :center))   # (1, 0)  — label ends up east of node
align_to_direction((:right, :center))  # (-1, 0) — label ends up west of node
align_to_direction((:center, :bottom)) # (0, 1)  — label ends up north of node
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

"""
    resolve_outer_labels(label_position; auto_align_labels=nothing) -> Bool

Whether labels should sit **outside** the nodes.

Preferred API: `label_position = :inner` (default) or `:outer`. The older
`auto_align_labels=true` flag is accepted as a synonym for `:outer` when
`label_position` is left at `:inner`. Conflicting combinations throw.
"""
function resolve_outer_labels(
    label_position::Symbol = :inner;
    auto_align_labels::Union{Bool, Nothing} = nothing,
)
    label_position in (:inner, :outer) || throw(ArgumentError(
        "label_position must be :inner or :outer, got $(repr(label_position))",
    ))
    if auto_align_labels === nothing
        return label_position === :outer
    elseif auto_align_labels === true
        if label_position === :outer
            return true
        end
        # Legacy: `auto_align_labels=true` with default `:inner` → outer
        return true
    else  # false
        label_position === :outer && throw(ArgumentError(
            "label_position=:outer conflicts with auto_align_labels=false; " *
            "omit auto_align_labels (preferred: label_position=:outer alone)",
        ))
        return false
    end
end

"""
    resolve_auto_align_label_settings(g, positions; align, distance, color,
        distance_explicit, color_explicit)

Resolve label align / distance / colour when outer labels are enabled
(`label_position=:outer` or legacy `auto_align_labels=true`).

Outer placement puts labels in the largest angular gap **outside** the node. If
the caller left the in-node defaults (`distance == 0`, white text), switch to
[`OUTER_LABEL_DISTANCE`](@ref) and [`OUTER_LABEL_COLOR`](@ref).
Explicit `nlabels_distance` / `nlabels_color` from the caller are preserved.
(Node size for outer labels is resolved separately in [`dagplot!`](@ref) via
[`OUTER_LABEL_NODE_SIZE`](@ref).)
"""
function resolve_auto_align_label_settings(
    g::AbstractGraph,
    positions::AbstractVector;
    align = DEFAULT_LABEL_ALIGN,
    distance = DEFAULT_LABEL_DISTANCE,
    color = DEFAULT_LABEL_COLOR,
    distance_explicit::Bool = false,
    color_explicit::Bool = false,
)
    resolved_align = compute_auto_label_aligns(g, positions)
    resolved_distance = if !distance_explicit && (distance == 0 || distance === 0.0)
        OUTER_LABEL_DISTANCE
    else
        distance
    end
    resolved_color = if !color_explicit && resolved_distance > 0 &&
            (color === DEFAULT_LABEL_COLOR || color === :white)
        OUTER_LABEL_COLOR
    else
        color
    end
    return (
        align = resolved_align,
        distance = resolved_distance,
        color = resolved_color,
    )
end

# =============================================================================
# Discoverable keyword aliases
# =============================================================================

"""
    resolve_nlabels(; labels=nothing, nlabels=nothing)

Prefer `labels=` (DAGMakie); `nlabels=` remains the GraphMakie-compatible alias.
"""
function resolve_nlabels(; labels = nothing, nlabels = nothing)
    if labels !== nothing && nlabels !== nothing && labels != nlabels
        throw(ArgumentError(
            "conflicting labels= and nlabels=; prefer labels= alone",
        ))
    end
    return labels !== nothing ? labels : nlabels
end

"""
    resolve_label_obstacle_graph(; label_obstacle_graph=nothing, auto_align_graph=nothing)

Graph used only for outer-label angular gaps. Prefer `label_obstacle_graph=`;
`auto_align_graph=` is a deprecated alias.
"""
function resolve_label_obstacle_graph(;
    label_obstacle_graph = nothing,
    auto_align_graph = nothing,
)
    if label_obstacle_graph !== nothing && auto_align_graph !== nothing &&
            label_obstacle_graph !== auto_align_graph
        throw(ArgumentError(
            "conflicting label_obstacle_graph= and auto_align_graph=; " *
            "prefer label_obstacle_graph= alone",
        ))
    end
    return label_obstacle_graph !== nothing ? label_obstacle_graph : auto_align_graph
end

"""
    resolve_color_by(; color_by=nothing, smart=nothing)

Normalise dagitty-style colouring to `nothing` (off) or `:ancestors` / `:adjustment`.
Prefer `color_by=`; `smart=` is a deprecated alias (`true` → `:ancestors`).
"""
function resolve_color_by(; color_by = nothing, smart = nothing)
    mode_from(x) = if x === false || x === nothing
        nothing
    elseif x === true || x === :ancestors
        :ancestors
    elseif x === :adjustment
        :adjustment
    else
        throw(ArgumentError(
            "color_by/smart must be false, true, :ancestors, or :adjustment; got $(repr(x))",
        ))
    end
    cb = mode_from(color_by)
    sm = mode_from(smart)
    if color_by !== nothing && smart !== nothing && cb !== sm
        throw(ArgumentError(
            "conflicting color_by=$(repr(color_by)) and smart=$(repr(smart)); " *
            "prefer color_by= alone",
        ))
    end
    return cb !== nothing ? cb : sm
end

"""
    resolve_exposure(; exposure=nothing, treatment=nothing)

Exposure / treatment node index. Prefer `exposure=`; `treatment=` remains an alias.
"""
function resolve_exposure(; exposure = nothing, treatment = nothing)
    if exposure !== nothing && treatment !== nothing && exposure != treatment
        throw(ArgumentError(
            "conflicting exposure= and treatment=; prefer exposure= alone",
        ))
    end
    return exposure !== nothing ? exposure : treatment
end

"""
    resolve_show_removed_edges(; show_removed_edges=nothing, show_original=nothing)

Whether to overlay severed parent edges after `do(·)`. Prefer
`show_removed_edges=`; `show_original=` is a deprecated alias. Default `true`.
"""
function resolve_show_removed_edges(;
    show_removed_edges = nothing,
    show_original = nothing,
)
    if show_removed_edges !== nothing && show_original !== nothing &&
            show_removed_edges != show_original
        throw(ArgumentError(
            "conflicting show_removed_edges= and show_original=; " *
            "prefer show_removed_edges= alone",
        ))
    end
    if show_removed_edges !== nothing
        return show_removed_edges
    elseif show_original !== nothing
        return show_original
    else
        return true
    end
end

"""
    resolve_do_node_labels(; do_node_labels=nothing, relabel_nodes=nothing)

Whether to rewrite node labels to `do(·)` text. Prefer `do_node_labels=`;
`relabel_nodes=` is a deprecated alias. Default `false`.
"""
function resolve_do_node_labels(; do_node_labels = nothing, relabel_nodes = nothing)
    if do_node_labels !== nothing && relabel_nodes !== nothing &&
            do_node_labels != relabel_nodes
        throw(ArgumentError(
            "conflicting do_node_labels= and relabel_nodes=; prefer do_node_labels= alone",
        ))
    end
    if do_node_labels !== nothing
        return do_node_labels
    elseif relabel_nodes !== nothing
        return relabel_nodes
    else
        return false
    end
end

"""
    resolve_node_gap(node_gap; outer_labels::Bool) -> Real

Within-layer spacing for layered layouts. When `node_gap` is omitted (`nothing`),
use [`DEFAULT_NODE_GAP_INNER`](@ref) for in-node labels and
[`DEFAULT_NODE_GAP_OUTER`](@ref) for outer labels.
"""
function resolve_node_gap(node_gap; outer_labels::Bool)
    node_gap !== nothing && return node_gap
    return outer_labels ? DEFAULT_NODE_GAP_OUTER : DEFAULT_NODE_GAP_INNER
end
