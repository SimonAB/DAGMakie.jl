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

