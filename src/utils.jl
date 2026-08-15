# SPDX-License-Identifier: MIT

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
    # Undirected graphs have no directed cycles; treat as acyclic for layout.
    Graphs.is_directed(g) || return true
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
    graph_from_structural_matrix(B; atol=0.0)

Build a `SimpleDiGraph` from a structural parameter matrix `B` (linear SEM /
linear SCM weights), including self-loops for non-zero diagonal entries.

Convention matches [`structural_edge_labels`](@ref): `B[i, j]` is the weight of
node `j` in the assignment for node `i`, so a non-zero entry yields the directed
edge `j → i`. In particular, `B[i, i] ≠ 0` yields a self-loop at `i`, which
GraphMakie draws as a self-pointing arc.

Entries with absolute value at most `atol` are treated as absent.

# Arguments
- `B`: Square structural weight matrix
- `atol`: Absolute tolerance for treating entries as zero

# Returns
- `SimpleDiGraph` with one edge per non-zero structural weight

# Example
```julia
B = [0.0 0.0 0.0; 0.8 0.0 0.0; 0.5 1.2 3.0]
g = graph_from_structural_matrix(B)  # edges 1→2, 1→3, 2→3, and self-loop 3→3
```
"""
function graph_from_structural_matrix(B::AbstractMatrix{<:Real}; atol::Real = 0.0)
    n = size(B, 1)
    size(B, 2) == n || throw(ArgumentError("B must be square"))
    g = Graphs.SimpleDiGraph(n)
    for i in 1:n
        for j in 1:n
            if abs(B[i, j]) > atol
                Graphs.add_edge!(g, j, i)  # B[i,j] on j → i
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
    pixel_length_to_data(distance_px, to_px)

Convert a pixel length to an isotropic data-space length (uses the x scale).
"""
function pixel_length_to_data(distance_px::Real, to_px)
    return Float64(abs(pixel_delta_to_data(Point2f(Float32(distance_px), 0f0), to_px)[1]))
end

"""
    trim_polyline_to_circles(path, centre_start, radius_start, centre_end, radius_end)

Trim a polyline so endpoints lie on circles around the start/end node centres.

Unlike arc-length trimming in pixel space, this keeps curved edges attached to
marker boundaries even when the Bézier leaves a node at a steep angle.
"""
function trim_polyline_to_circles(
    path::AbstractVector,
    centre_start::Point2f,
    radius_start::Real,
    centre_end::Point2f,
    radius_end::Real,
)
    @assert length(path) >= 2 "A polyline requires at least two points."
    ordered = Point2f.(path)
    r0 = max(Float64(radius_start), 0.0)
    r1 = max(Float64(radius_end), 0.0)

    start_point = _polyline_circle_point(ordered, centre_start, r0; from_start = true)
    end_point = _polyline_circle_point(ordered, centre_end, r1; from_start = false)

    trimmed = Point2f[start_point]
    for point in ordered
        if norm(point - centre_start) < r0 - 1e-9
            continue
        end
        if norm(point - centre_end) < r1 - 1e-9
            break
        end
        if norm(point - trimmed[end]) > 1e-8
            push!(trimmed, point)
        end
    end
    if norm(trimmed[end] - end_point) > 1e-8
        push!(trimmed, end_point)
    end
    return length(trimmed) < 2 ? Point2f[start_point, end_point] : trimmed
end

function _polyline_circle_point(
    path::Vector{Point2f},
    centre::Point2f,
    radius::Real;
    from_start::Bool,
)
    radius <= 0 && return from_start ? path[1] : path[end]
    n = length(path)
    indices = from_start ? (1:(n - 1)) : ((n - 1):-1:1)
    for index in indices
        hit = _segment_circle_hit(path[index], path[index + 1], centre, radius)
        hit !== nothing && return hit
    end
    endpoint = from_start ? path[1] : path[end]
    neighbour = from_start ? path[2] : path[end - 1]
    direction = neighbour - endpoint
    norm(direction) <= 1e-9 && return endpoint
    # Path never reaches the circle: place a point on the ray toward the path.
    return Point2f(centre + Float32(radius) * (direction / norm(direction)))
end

function _segment_circle_hit(p1::Point2f, p2::Point2f, centre::Point2f, radius::Real)
    d1 = norm(p1 - centre)
    d2 = norm(p2 - centre)
    abs(d1 - radius) <= 1e-8 && return p1
    abs(d2 - radius) <= 1e-8 && return p2
    if (d1 - radius) * (d2 - radius) <= 0
        t = abs(d2 - d1) <= 1e-9 ? 0.5 : (radius - d1) / (d2 - d1)
        return Point2f(p1 + Float32(clamp(t, 0.0, 1.0)) * (p2 - p1))
    end
    return nothing
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


"""
    digraph_skeleton(g::AbstractGraph) -> SimpleGraph

Undirected skeleton of a directed graph: keep an undirected edge `{i,j}` whenever
`g` has `i → j`, `j → i`, or both.

Useful for CPDAG-style PC output that encodes an undirected edge as a pair of
opposing directed edges. Prefer this over plotting both arrows. See
[`dagplot_skeleton`](@ref) for a ready-made figure with undirected stroke styling.
"""
function digraph_skeleton(g::AbstractGraph)
    n = Graphs.nv(g)
    sk = Graphs.SimpleGraph(n)
    for e in Graphs.edges(g)
        i, j = Graphs.src(e), Graphs.dst(e)
        i == j && continue
        Graphs.add_edge!(sk, i, j)
    end
    return sk
end

"""
    ensure_structural_self_loops!(g, B; atol=0.0)

Add missing self-loops `i → i` whenever `|B[i, i]| > atol`. Mutates `g` and
returns it. Off-diagonal structure is left unchanged.

Used by [`structural_edge_labels`](@ref) when `ensure_self_loops=true` (the
default) so a non-zero diagonal is enough to draw self-pointing arcs.
"""
function ensure_structural_self_loops!(
    g::AbstractGraph,
    B::AbstractMatrix{<:Real};
    atol::Real = 0.0,
)
    n = Graphs.nv(g)
    size(B) == (n, n) || throw(ArgumentError("B must be $n×$n to match nv(g)"))
    for i in 1:n
        if abs(B[i, i]) > atol && !Graphs.has_edge(g, i, i)
            Graphs.add_edge!(g, i, i)
        end
    end
    return g
end

"""
    structural_edge_labels(g, B; latex=true, digits=2, ensure_self_loops=true)

Build GraphMakie `elabels` for `g` from a structural parameter matrix `B`
(linear SEM / linear SCM weights).

Convention: `B[i, j]` is the structural weight of node `j` in the assignment for
node `i`, i.e. the parameter on the directed edge `j → i` (including self-loops
when `i == j`). Labels are returned in `Graphs.edges(g)` order (the order
GraphMakie expects for `elabels`).

When `ensure_self_loops=true` (default), non-zero diagonal entries that are
missing from `g` are added in place via [`ensure_structural_self_loops!`](@ref)
before labels are built. Off-diagonal non-zeros without a matching edge still
warn (and are omitted from labels). You can also build the full edge set with
[`graph_from_structural_matrix`](@ref).

This is deliberately not named “effects”: in the Pearl ladder an *effect* is
usually an interventional or counterfactual estimand, whereas these labels are
structural parameters (or other short mechanism annotations) on the graph.

When `latex=true` (default), each entry is a Makie `LaTeXString` so parameters
render as maths on the edge. Set `latex=false` for plain `String` labels.

# Examples

```julia
g, labels = confounding_graph(["Z", "X", "Y"])
B = [0 0 0; 0.8 0 0; 0.5 1.2 3.0]  # diagonal 3.0 → self-loop on Y
fig, ax, p = dagplot(g;
    labels = labels,
    elabels = structural_edge_labels(g, B),  # adds Y → Y automatically
    elabels_fontsize = 14,
    elabels_distance = 12,
    elabels_rotation = 0,
)
```
"""
function structural_edge_labels(
    g::AbstractGraph,
    B::AbstractMatrix{<:Real};
    latex::Bool = true,
    digits::Integer = 2,
    atol::Real = 0.0,
    ensure_self_loops::Bool = true,
)
    size(B, 1) == size(B, 2) || throw(ArgumentError("B must be square"))
    size(B, 1) == Graphs.nv(g) || throw(ArgumentError("size(B, 1) must equal nv(g)"))
    if ensure_self_loops
        ensure_structural_self_loops!(g, B; atol = atol)
    end
    _warn_structural_matrix_orphans(g, B; atol = atol)
    labels = map(Graphs.edges(g)) do e
        β = B[Graphs.dst(e), Graphs.src(e)]
        _format_edge_label(β; latex = latex, digits = digits)
    end
    return collect(labels)
end

"""
Warn when non-zero `B` entries have no matching edge in `g`.
"""
function _warn_structural_matrix_orphans(
    g::AbstractGraph,
    B::AbstractMatrix{<:Real};
    atol::Real,
)
    n = Graphs.nv(g)
    orphans = Tuple{Int, Int, Float64}[]
    for i in 1:n
        for j in 1:n
            β = Float64(B[i, j])
            abs(β) > atol || continue
            Graphs.has_edge(g, j, i) && continue
            push!(orphans, (j, i, β))
        end
    end
    isempty(orphans) && return nothing
    examples = join(
        ["$j → $i (B[$i,$j]=$β)" for (j, i, β) in orphans[1:min(3, end)]],
        "; ",
    )
    extra = length(orphans) > 3 ? "…" : ""
    @warn "structural_edge_labels: $(length(orphans)) non-zero B entr$(length(orphans) == 1 ? "y has" : "ies have") no matching edge in g (labels omitted). " *
          "Examples: $examples$extra. " *
          "Use graph_from_structural_matrix(B), or ensure_self_loops=true for diagonal self-loops."
    return nothing
end

"""
    structural_edge_labels(g, labels; latex=false)

Pass edge annotations already ordered as `Graphs.edges(g)`. With `latex=true`,
wrap plain strings (or numbers) as `LaTeXString` via `Makie.latexstring` so short
TeX such as `"\\\\beta_{ZX}"` or a fragment of a structural assignment renders on
the edge.
"""
function structural_edge_labels(
    g::AbstractGraph,
    labels::AbstractVector;
    latex::Bool = false,
)
    length(labels) == Graphs.ne(g) ||
        throw(ArgumentError("need one label per edge (ne(g) = $(Graphs.ne(g)))"))
    return [_format_edge_label(lab; latex = latex, digits = 2) for lab in labels]
end

"""
    edge_coefficient_labels(args...; kwargs...)

Deprecated alias for [`structural_edge_labels`](@ref).
"""
edge_coefficient_labels(args...; kwargs...) = structural_edge_labels(args...; kwargs...)

function _format_edge_label(β::Real; latex::Bool, digits::Integer)
    text = string(round(Float64(β); digits = digits))
    return latex ? Makie.latexstring(text) : text
end

function _format_edge_label(text::AbstractString; latex::Bool, digits::Integer)
    return latex ? Makie.latexstring(String(text)) : String(text)
end

function _format_edge_label(text::Makie.LaTeXString; latex::Bool, digits::Integer)
    return text
end

"""
    dagplot_skeleton(g; kwargs...)

Plot the undirected skeleton of `g` ([`digraph_skeleton`](@ref)).

Arrowheads are suppressed and edges use [`UNDIRECTED_EDGE_COLOR`](@ref) unless
overridden. Remaining keywords go to [`dagplot`](@ref).
"""
function dagplot_skeleton(g::Graphs.AbstractGraph; kwargs...)
    return dagplot(digraph_skeleton(g); kwargs...)
end
