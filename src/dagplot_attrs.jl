# SPDX-License-Identifier: MIT

"""Attribute / waypoint helpers for `dagplot!`."""

function _resolve_style(style::Union{Nothing, DAGStyle})
    return style === nothing ? default_style() : style
end

"""
    _has_self_loops(g) -> Bool

Return true when `g` contains at least one edge `i → i`.
"""
function _has_self_loops(g::Graphs.AbstractGraph)
    return any(e -> Graphs.src(e) == Graphs.dst(e), Graphs.edges(g))
end

"""
    _is_centred_label_align(align) -> Bool

Return true when every label uses the in-node Makie anchor `(:center, :center)`.
With that anchor GraphMakie's `nlabels_distance` offset is the zero vector.
"""
function _is_centred_label_align(align::Tuple{Symbol, Symbol})
    return align === DEFAULT_LABEL_ALIGN || align == DEFAULT_LABEL_ALIGN
end

function _is_centred_label_align(align::AbstractVector)
    return !isempty(align) && all(_is_centred_label_align, align)
end

_is_centred_label_align(::Any) = false

function _fill_attribute(value, count::Int)
    if value isa AbstractVector && !(value isa AbstractString)
        @assert length(value) == count "Attribute length must match the graph size."
        return collect(value)
    end

    return fill(value, count)
end

function _edge_index_lookup(g::Graphs.AbstractGraph)
    return Dict((Graphs.src(edge), Graphs.dst(edge)) => index for (index, edge) in enumerate(Graphs.edges(g)))
end

function _materialise_waypoints(g::Graphs.AbstractGraph, waypoints)
    edge_count = Graphs.ne(g)
    if waypoints === nothing
        return [Point2f[] for _ in 1:edge_count]
    elseif waypoints isa AbstractVector
        @assert length(waypoints) == edge_count "Waypoint vector must match the number of edges."
        return [Point2f.(points) for points in waypoints]
    elseif waypoints isa AbstractDict
        materialised = [Point2f[] for _ in 1:edge_count]
        for (index, points) in waypoints
            materialised[index] = Point2f.(points)
        end
        return materialised
    end

    error("Unsupported waypoints specification $(typeof(waypoints)).")
end

"""
    _apply_long_edge_graphmakie_attrs!(user_kwargs, g, layout_result, base_waypoints; routing, radius)

Set GraphMakie `waypoint_radius`, `tangents`, or `curve_distance` for the chosen
`long_edge_routing` style when the caller has not already set them.
"""
function _apply_long_edge_graphmakie_attrs!(
    user_kwargs::AbstractDict,
    g::Graphs.AbstractGraph,
    layout_result,
    base_waypoints::AbstractVector;
    routing::Symbol,
    radius::Real,
)
    edge_list = collect(Graphs.edges(g))
    n_edges = length(edge_list)
    routed = layout_result.edge_waypoints

    if routing === :rounded && !haskey(user_kwargs, :waypoint_radius)
        radii = Vector{Any}(undef, n_edges)
        for (index, edge) in enumerate(edge_list)
            key = (Graphs.src(edge), Graphs.dst(edge))
            radii[index] = haskey(routed, key) && !isempty(base_waypoints[index]) ?
                Float64(radius) : nothing
        end
        user_kwargs[:waypoint_radius] = radii
    elseif routing === :tangents && !haskey(user_kwargs, :tangents)
        tangents = Vector{Any}(undef, n_edges)
        positions = layout_result.positions
        for (index, edge) in enumerate(edge_list)
            if isempty(base_waypoints[index])
                tangents[index] = nothing
                continue
            end
            p1 = positions[Graphs.src(edge)]
            p2 = positions[Graphs.dst(edge)]
            chord = p2 - p1
            nrm = hypot(chord[1], chord[2])
            t = nrm <= 1f-8 ? Point2f(1, 0) : Point2f(chord[1] / nrm, chord[2] / nrm)
            tangents[index] = (t, t)
        end
        user_kwargs[:tangents] = tangents
    elseif routing === :curve_distance && !haskey(user_kwargs, :curve_distance)
        distances = Vector{Float64}(undef, n_edges)
        for (index, edge) in enumerate(edge_list)
            key = (Graphs.src(edge), Graphs.dst(edge))
            distances[index] = haskey(routed, key) ? 0.18 : 0.0
        end
        user_kwargs[:curve_distance] = distances
        user_kwargs[:curve_distance_usage] = true
    end
    return user_kwargs
end

