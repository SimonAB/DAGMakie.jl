# SPDX-License-Identifier: MIT

"""Feedback-edge geometry and overlay helpers for cyclic layouts."""

"""
    compute_feedback_geometry(edge_pairs, positions, node_markers, node_sizes, waypoints, to_px;
        arrow_size=8, arrow_shift=:end)

Compute boundary-aware paths and arrowheads for curved directed feedback edges.
"""
function compute_feedback_geometry(
    edge_pairs::Vector{Tuple{Int, Int}},
    positions::AbstractVector,
    node_markers,
    node_sizes,
    waypoints::AbstractVector,
    to_px;
    arrow_size = 8,
    arrow_shift = :end,
)
    @assert length(waypoints) == length(edge_pairs) "Waypoint vector must match the number of feedback edges."

    paths = Vector{Vector{Point2f}}()
    arrow_positions = Point2f[]
    arrow_rotations = Float64[]
    arrow_sizes = Float64[]
    boundary_points = Point2f[]

    for (index, (source, destination)) in enumerate(edge_pairs)
        raw_path = _feedback_curve_path(
            Point2f(positions[source]),
            Point2f(positions[destination]),
            waypoints[index],
        )
        # Normalise to a scalar extent: General GraphMakie 0.6.6 multiplies
        # sizes directly; `(width, height)` ovals need `maximum` first (fork
        # already does this inside `distance_between_markers`).
        start_distance = distance_between_markers(
            _attribute_value(node_markers, source),
            _marker_extent_px(_attribute_value(node_sizes, source)),
            :circle,
            0,
        )
        arrow_size_value = Float64(_attribute_value(arrow_size, index))
        end_distance = distance_between_markers(
            _attribute_value(node_markers, destination),
            _marker_extent_px(_attribute_value(node_sizes, destination)),
            Arrow,
            arrow_size_value,
        )

        r_start = pixel_length_to_data(start_distance, to_px)
        r_end = pixel_length_to_data(end_distance, to_px)
        trimmed_path = trim_polyline_to_circles(
            raw_path,
            Point2f(positions[source]),
            r_start,
            Point2f(positions[destination]),
            r_end,
        )
        if length(trimmed_path) < 2
            trimmed_path = raw_path
        end

        push!(paths, trimmed_path)
        append!(boundary_points, trimmed_path)

        arrow_position, arrow_rotation = _feedback_arrow_pose(
            trimmed_path,
            to_px,
            _attribute_value(arrow_shift, index),
        )
        push!(arrow_positions, arrow_position)
        push!(arrow_rotations, arrow_rotation)
        push!(arrow_sizes, arrow_size_value)
    end

    return (
        paths = paths,
        arrow_positions = arrow_positions,
        arrow_rotations = arrow_rotations,
        arrow_sizes = arrow_sizes,
        boundary_points = boundary_points,
    )
end

function _plot_directed_overlay!(
    ax,
    edge_pairs::Vector{Tuple{Int, Int}},
    positions::Vector{Point2f};
    node_sizes,
    node_markers,
    edge_colours,
    edge_widths,
    edge_linestyles,
    arrow_sizes,
    arrow_shifts,
    waypoints,
    to_px,
)
    isempty(edge_pairs) && return Point2f[]

    geometry = compute_feedback_geometry(
        edge_pairs,
        positions,
        node_markers,
        node_sizes,
        waypoints,
        to_px;
        arrow_size = arrow_sizes,
        arrow_shift = arrow_shifts,
    )

    for (index, path) in enumerate(geometry.paths)
        lines!(ax, path;
            color = edge_colours[index],
            linewidth = edge_widths[index],
            linestyle = edge_linestyles[index],
        )
    end

    if !isempty(geometry.arrow_positions)
        scatter!(ax, geometry.arrow_positions;
            marker = Arrow,
            markersize = geometry.arrow_sizes,
            color = edge_colours,
            rotation = geometry.arrow_rotations,
            markerspace = :pixel,
        )
    end

    return geometry.boundary_points
end

function _feedback_curve_path(p1::Point2f, p2::Point2f, waypoints::AbstractVector)
    control_points = Point2f.(waypoints)
    if isempty(control_points)
        return Point2f[p1, p2]
    elseif length(control_points) == 1
        midpoint = (p1 + p2) / 2
        control = 2f0 * control_points[1] - midpoint
        return _quadratic_bezier_path(p1, control, p2)
    end

    return _chaikin_smooth_path(vcat(Point2f[p1], control_points, Point2f[p2]))
end

function _quadratic_bezier_path(p1::Point2f, control::Point2f, p2::Point2f; n_points::Int = 32)
    path = Vector{Point2f}(undef, n_points)
    for index in 1:n_points
        t = Float32((index - 1) / (n_points - 1))
        path[index] = (1 - t)^2 * p1 + 2f0 * (1 - t) * t * control + t^2 * p2
    end
    return path
end

function _chaikin_smooth_path(points::Vector{Point2f}; refinements::Int = 2)
    smoothed = copy(points)
    for _ in 1:refinements
        next_points = Point2f[first(smoothed)]
        for index in 1:(length(smoothed) - 1)
            p1 = smoothed[index]
            p2 = smoothed[index + 1]
            push!(next_points, 0.75f0 * p1 + 0.25f0 * p2)
            push!(next_points, 0.25f0 * p1 + 0.75f0 * p2)
        end
        push!(next_points, last(smoothed))
        smoothed = next_points
    end
    return smoothed
end

function _feedback_arrow_pose(path::AbstractVector, to_px, arrow_shift)
    if length(path) < 2
        return Point2f(path[1]), 0.0
    elseif arrow_shift === :end
        return last(path), _polyline_rotation(path, to_px; from_start = false, reverse_direction = false)
    end

    total_length = polyline_length_px(path, to_px)
    distance_px = clamp(Float64(arrow_shift), 0.0, 1.0) * total_length
    position = polyline_point_at_distance(path, distance_px, to_px; from_start = true)
    rotation = _polyline_rotation_at_distance(path, distance_px, to_px)
    return position, rotation
end

function _polyline_rotation_at_distance(path::AbstractVector, distance_px::Real, to_px)
    ordered_points = Point2f.(path)
    target = clamp(Float64(distance_px), 0.0, polyline_length_px(ordered_points, to_px))
    traversed = 0.0

    for index in 1:(length(ordered_points) - 1)
        p1 = ordered_points[index]
        p2 = ordered_points[index + 1]
        tangent_px = to_px(p2) - to_px(p1)
        segment_length_px = norm(tangent_px)
        if segment_length_px <= 1e-6
            continue
        end

        if traversed + segment_length_px >= target
            return atan(tangent_px[2], tangent_px[1])
        end

        traversed += segment_length_px
    end

    return _polyline_rotation(ordered_points, to_px; from_start = false, reverse_direction = false)
end

function _overlay_values(override, edge_pairs, edge_lookup, base_values)
    if override === nothing
        return [base_values[edge_lookup[edge]] for edge in edge_pairs]
    end

    return _fill_attribute(override, length(edge_pairs))
end

function _apply_data_limits!(
    ax,
    positions::AbstractVector,
    extra_points::AbstractVector;
    padding::Real = 0.15,
)
    isempty(positions) && return ax
    pts = Point2f[Point2f(p) for p in positions]
    append!(pts, Point2f(p) for p in extra_points)
    xs = [Float64(p[1]) for p in pts]
    ys = [Float64(p[2]) for p in pts]
    x_min, x_max = extrema(xs)
    y_min, y_max = extrema(ys)
    x_range = max(x_max - x_min, 1e-3)
    y_range = max(y_max - y_min, 1e-3)
    # Match DataAspect-friendly padding used by compute_padded_limits.
    min_aspect = 0.35
    x_pad = max(Float64(padding) * x_range, 0.05 * x_range, 0.15)
    y_pad = max(Float64(padding) * y_range, 0.05 * y_range, 0.15)
    x_span = x_range + 2 * x_pad
    y_span = y_range + 2 * y_pad
    if y_span < min_aspect * x_span
        y_pad = max(y_pad, 0.5 * (min_aspect * x_span - y_range))
    end
    if x_span < min_aspect * y_span
        x_pad = max(x_pad, 0.5 * (min_aspect * y_span - x_range))
    end
    xlims!(ax, x_min - x_pad, x_max + x_pad)
    ylims!(ax, y_min - y_pad, y_max + y_pad)
    return ax
end

function _extra_bound_points(edge_waypoints::Dict{Tuple{Int, Int}, Vector{Point2f}})
    points = Point2f[]
    for waypoint_set in values(edge_waypoints)
        append!(points, waypoint_set)
    end
    return points
end

