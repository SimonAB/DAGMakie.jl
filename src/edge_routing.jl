# SPDX-License-Identifier: MIT

"""Per-edge straight / curved routing for `dagplot`."""

using LinearAlgebra: norm

const LONG_EDGE_ROUTINGS = (
    :none,
    :natural_cubic,
    :quadratic,
    :rounded,
    :tangents,
    :curve_distance,
)

"""Default lateral bow as a fraction of chord length for [`CurvedEdge`](@ref)."""
const DEFAULT_EDGE_BOW = 0.22

"""
    CurvedEdge

Per-edge bow for [`dagplot`](@ref). Unspecified edges are straight.

# Fields
- `bow::Union{Real, Nothing}`: Lateral quadratic control offset as a **fraction of
  chord length** (typical 0.12–0.35). Defaults to [`DEFAULT_EDGE_BOW`](@ref). Ignored
  when `distance` is set.
- `distance::Union{Real, Nothing}`: GraphMakie `curve_distance` in data units
  (perpendicular sagitta). The bend angle along the chord satisfies
  ``γ = 2 \\operatorname{atan}(2d / L)`` for chord length ``L``.
- `side::Symbol`: `:auto` bows away from the nearest non-endpoint node on the
  chord; `:left` / `:right` are relative to the forward chord direction.

# Examples
```julia
edge_routing = Dict(
    (1, 4) => CurvedEdge(),              # default bow
    (1, 5) => CurvedEdge(bow = 0.28),    # deeper arc
    (2, 4) => CurvedEdge(distance = 0.35),
    (3, 5) => 0.18,                      # bow fraction shorthand
)
```
"""
Base.@kwdef struct CurvedEdge
    bow::Union{Real, Nothing} = DEFAULT_EDGE_BOW
    distance::Union{Real, Nothing} = nothing
    side::Symbol = :auto
end

CurvedEdge(bow::Real) = CurvedEdge(bow = bow, distance = nothing, side = :auto)

const EdgeRoutingSpec = Union{Symbol, CurvedEdge, Real}

"""Interior samples of the quadratic Bézier through control point `control`."""
function _quadratic_bezier_samples(
    p1::Point2f,
    control::Point2f,
    p2::Point2f;
    ts::NTuple{N, Float32} = (0.25f0, 0.5f0, 0.75f0),
) where {N}
    samples = Vector{Point2f}(undef, N)
    for (index, t) in enumerate(ts)
        samples[index] = (1 - t)^2 * p1 + 2f0 * (1 - t) * t * control + t^2 * p2
    end
    return samples
end

function _long_edge_waypoints(p1::Point2f, p2::Point2f, control::Point2f, routing::Symbol)
    if routing === :natural_cubic || routing === :rounded || routing === :tangents
        return Point2f[control]
    elseif routing === :quadratic
        return _quadratic_bezier_samples(p1, control, p2)
    end
    return Point2f[]
end

"""Merge `edge_routing` dict with legacy `straight_edges` (`:straight` wins)."""
function _merge_edge_routing(edge_routing, straight_edges)
    specs = Dict{Tuple{Int, Int}, EdgeRoutingSpec}()
    if edge_routing isa AbstractDict
        for (key, val) in edge_routing
            key isa Tuple{Int, Int} || throw(ArgumentError(
                "edge_routing keys must be (src::Int, dst::Int); got $(typeof(key))",
            ))
            specs[key] = val
        end
    elseif edge_routing !== nothing
        throw(ArgumentError("edge_routing must be a Dict or nothing"))
    end
    for edge in _normalise_edge_pairs(straight_edges)
        specs[edge] = :straight
    end
    return specs
end

function _parse_routing_spec(spec::EdgeRoutingSpec)
    spec === :straight && return (:straight, nothing)
    spec === :curved && return (:curved, CurvedEdge())
    spec isa CurvedEdge && return (:curved, spec)
    spec isa Real && return (:curved, CurvedEdge(bow = Float64(spec)))
    throw(ArgumentError(
        "edge routing must be :straight, :curved, a bow fraction (Real), or CurvedEdge; got $(typeof(spec))",
    ))
end

function _routing_spec_for_edge(
    specs::Dict{Tuple{Int, Int}, EdgeRoutingSpec},
    source::Int,
    destination::Int,
)
    return _parse_routing_spec(get(specs, (source, destination), :straight))
end

"""Sign for bow side: +1 / -1 perpendicular to chord."""
function _bow_side_sign(
    side::Symbol,
    p1::Point2f,
    p2::Point2f,
    perp::Point2f,
    positions::Vector{Point2f},
    source::Int,
    destination::Int,
)
    side === :left && return 1.0f0
    side === :right && return -1.0f0
    side === :auto || throw(ArgumentError("side must be :auto, :left, or :right; got :$side"))
    midpoint = (p1 + p2) / 2
    best_dist = typemax(Float32)
    best_sign = 1.0f0
    for node in eachindex(positions)
        node == source && continue
        node == destination && continue
        to_node = positions[node] - midpoint
        proj = Float32(to_node[1] * perp[1] + to_node[2] * perp[2])
        dist = norm(to_node)
        if dist < best_dist
            best_dist = dist
            best_sign = sign(proj)
            iszero(best_sign) && (best_sign = 1.0f0)
        end
    end
    return best_sign
end

"""
    _quadratic_control_point(p1, p2, bow_frac, curved::CurvedEdge, positions, source, destination)

Control point for a quadratic bow with lateral offset `bow_frac * chord_length`.
"""
function _quadratic_control_point(
    p1::Point2f,
    p2::Point2f,
    bow_frac::Real,
    curved::CurvedEdge,
    positions::Vector{Point2f},
    source::Int,
    destination::Int,
)
    chord = p2 - p1
    L = norm(chord)
    L <= 1f-8 && return (p1 + p2) / 2
    perp = _normalised_perpendicular(chord)
    offset = Float32(bow_frac) * Float32(L)
    sign = _bow_side_sign(curved.side, p1, p2, perp, positions, source, destination)
    midpoint = (p1 + p2) / 2
    return midpoint + sign * offset * perp
end

"""
    _compute_edge_routing(...) -> (edge_waypoints, edge_curve_distance)

Resolve per-edge routing: straight by default, or [`CurvedEdge`](@ref) / bow fraction.
"""
function _compute_edge_routing(
    g::Graphs.AbstractGraph,
    positions::Vector{Point2f};
    edge_routing::Dict{Tuple{Int, Int}, EdgeRoutingSpec} = Dict{Tuple{Int, Int}, EdgeRoutingSpec}(),
    routing::Symbol = :quadratic,
)
    routing in LONG_EDGE_ROUTINGS || throw(ArgumentError(
        "long_edge_routing must be one of $(LONG_EDGE_ROUTINGS); got :$routing",
    ))
    edge_waypoints = Dict{Tuple{Int, Int}, Vector{Point2f}}()
    edge_curve_distance = Dict{Tuple{Int, Int}, Float64}()
    routing === :none && return edge_waypoints, edge_curve_distance

    for edge in Graphs.edges(g)
        source = Graphs.src(edge)
        destination = Graphs.dst(edge)
        key = (source, destination)
        mode, curved = _routing_spec_for_edge(edge_routing, source, destination)
        mode === :straight && continue

        p1 = positions[source]
        p2 = positions[destination]
        curved = something(curved, CurvedEdge())
        if curved.distance !== nothing
            edge_curve_distance[key] = Float64(curved.distance)
            continue
        end
        bow = something(curved.bow, DEFAULT_EDGE_BOW)
        control = _quadratic_control_point(
            p1, p2, bow, curved, positions, source, destination,
        )
        edge_waypoints[key] = _long_edge_waypoints(p1, p2, control, routing)
    end

    return edge_waypoints, edge_curve_distance
end

"""Per-edge `curve_distance` vector for GraphMakie (0 = straight)."""
function _materialise_edge_curve_distances(
    g::Graphs.AbstractGraph,
    edge_lookup::Dict{Tuple{Int, Int}, Int},
    layout_curve::Dict{Tuple{Int, Int}, Float64},
    edge_routing::Dict{Tuple{Int, Int}, EdgeRoutingSpec},
)
    n = Graphs.ne(g)
    distances = zeros(Float64, n)
    for edge in Graphs.edges(g)
        key = (Graphs.src(edge), Graphs.dst(edge))
        idx = edge_lookup[key]
        mode, curved = _routing_spec_for_edge(edge_routing, key...)
        if mode === :straight
            distances[idx] = 0.0
        elseif haskey(layout_curve, key)
            distances[idx] = layout_curve[key]
        elseif mode === :curved && curved !== nothing && curved.distance !== nothing
            distances[idx] = Float64(curved.distance)
        end
    end
    return distances
end

function _apply_edge_curve_distances!(
    user_kwargs::AbstractDict,
    g::Graphs.AbstractGraph,
    edge_lookup::Dict{Tuple{Int, Int}, Int},
    layout_curve::Dict{Tuple{Int, Int}, Float64},
    edge_routing::Dict{Tuple{Int, Int}, EdgeRoutingSpec},
)
    haskey(user_kwargs, :curve_distance) && return user_kwargs
    distances = _materialise_edge_curve_distances(g, edge_lookup, layout_curve, edge_routing)
    if any(!iszero, distances)
        user_kwargs[:curve_distance] = distances
        user_kwargs[:curve_distance_usage] = true
    end
    return user_kwargs
end
