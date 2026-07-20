"""
Layout utilities for DAG visualisation.

Functions for computing label bounds, padding, and automatic axis limits
to ensure all elements are visible without clipping.
"""

using Makie: Point2f

"""
    estimate_label_extent(label, align, fontsize, distance)

Estimate the extent of a label in pixel coordinates.

Returns a named tuple `(dx_min, dx_max, dy_min, dy_max)` representing
the approximate bounding box offset from the node position.

# Arguments
- `label::AbstractString`: The label text
- `align::Tuple{Symbol, Symbol}`: Alignment tuple `(:horizontal, :vertical)`
- `fontsize::Real`: Font size in pixels
- `distance::Real`: Label distance from node in pixels

# Returns
- Named tuple with `dx_min`, `dx_max`, `dy_min`, `dy_max` in pixels

# Notes
- Uses approximate character width of 0.6 × fontsize for typical fonts
- Returns pixel-space estimates (caller must convert to data coordinates)
"""
function estimate_label_extent(
    label::AbstractString, 
    align::Tuple{Symbol, Symbol}, 
    fontsize::Real, 
    distance::Real
)
    halign, valign = align
    
    # Approximate character dimensions (in pixels)
    # Typical monospace/sans-serif: width ≈ 0.6 × height
    char_width = 0.6 * fontsize
    char_height = Float64(fontsize)
    
    # Estimate label dimensions in pixels
    label_width = length(label) * char_width
    label_height = char_height
    
    # Calculate offset based on alignment
    # The alignment specifies which part of the label is at the anchor point
    # e.g., (:left, :center) means label's LEFT edge is at anchor, so label extends RIGHT
    
    # Horizontal extent from anchor
    dx_min, dx_max = if halign === :left
        (Float64(distance), Float64(distance) + label_width)      # Label extends right
    elseif halign === :right
        (-Float64(distance) - label_width, -Float64(distance))    # Label extends left
    else  # :center
        (-label_width / 2, label_width / 2)
    end
    
    # Vertical extent from anchor
    dy_min, dy_max = if valign === :bottom
        (Float64(distance), Float64(distance) + label_height)     # Label extends up
    elseif valign === :top
        (-Float64(distance) - label_height, -Float64(distance))   # Label extends down
    else  # :center
        (-label_height / 2, label_height / 2)
    end
    
    return (dx_min = dx_min, dx_max = dx_max, dy_min = dy_min, dy_max = dy_max)
end

"""
    compute_label_bounds(node_positions, nlabels, nlabels_align, nlabels_distance, nlabels_fontsize)

Compute the bounding box that encompasses all nodes and their labels.

# Arguments
- `node_positions::AbstractVector`: Vector of node positions (Point2f or similar)
- `nlabels::AbstractVector{<:AbstractString}`: Vector of label strings
- `nlabels_align`: Vector of alignment tuples or single tuple for all
- `nlabels_distance::Real`: Label distance from node in pixels
- `nlabels_fontsize::Real`: Font size for labels

# Returns
- Tuple `(x_min, x_max, y_min, y_max)` in data coordinates

# Notes
- Estimates pixel-to-data conversion based on current data range
- Assumes typical figure width of ~500 pixels for the data range
"""
function compute_label_bounds(
    node_positions::AbstractVector,
    nlabels::AbstractVector{<:AbstractString},
    nlabels_align,
    nlabels_distance::Real,
    nlabels_fontsize::Real;
    to_px = nothing,
    pixel_size::Tuple{Real, Real} = (500.0, 500.0),
    extra_points::AbstractVector = Point2f[],
)
    n = length(node_positions)

    # Get node coordinate ranges
    xs = [Float64(pos[1]) for pos in node_positions]
    ys = [Float64(pos[2]) for pos in node_positions]

    px_to_data_x, px_to_data_y = _pixel_to_data_scale(xs, ys; to_px = to_px, pixel_size = pixel_size)

    # Start with node bounds
    x_min, x_max = minimum(xs), maximum(xs)
    y_min, y_max = minimum(ys), maximum(ys)

    # Expand bounds to include labels
    for i in 1:n
        pos = node_positions[i]
        label = nlabels[i]
        align = _get_align(nlabels_align, i)
        label_distance = _get_scalar_or_indexed(nlabels_distance, i)
        label_fontsize = _get_scalar_or_indexed(nlabels_fontsize, i)
        
        # Get pixel-space extent
        extent = estimate_label_extent(label, align, label_fontsize, label_distance)
        
        # Convert to data coordinates and expand bounds
        x_min = min(x_min, Float64(pos[1]) + extent.dx_min * px_to_data_x)
        x_max = max(x_max, Float64(pos[1]) + extent.dx_max * px_to_data_x)
        y_min = min(y_min, Float64(pos[2]) + extent.dy_min * px_to_data_y)
        y_max = max(y_max, Float64(pos[2]) + extent.dy_max * px_to_data_y)
    end

    if !isempty(extra_points)
        extra_xs = [Float64(point[1]) for point in extra_points]
        extra_ys = [Float64(point[2]) for point in extra_points]
        x_min = min(x_min, minimum(extra_xs))
        x_max = max(x_max, maximum(extra_xs))
        y_min = min(y_min, minimum(extra_ys))
        y_max = max(y_max, maximum(extra_ys))
    end

    return (x_min, x_max, y_min, y_max)
end

function _get_scalar_or_indexed(value, index::Int)
    if value isa AbstractVector && !(value isa AbstractString)
        return value[index]
    end

    return value
end

"""
    _get_align(nlabels_align, i::Int)

Get the alignment for node `i` from a scalar or vector alignment specification.
"""
function _get_align(nlabels_align::Tuple{Symbol, Symbol}, i::Int)
    return nlabels_align
end

function _get_align(nlabels_align::AbstractVector, i::Int)
    return nlabels_align[i]
end

"""
    compute_padded_limits(node_positions, nlabels, nlabels_align, nlabels_distance, nlabels_fontsize; padding=0.1, node_sizes=nothing)

Compute axis limits with padding that includes all nodes, labels, and marker extents.

# Arguments
- `node_positions`: Vector of node positions
- `nlabels`: Vector of label strings (or `nothing` for no labels)
- `nlabels_align`: Alignment specification
- `nlabels_distance`: Label distance in pixels
- `nlabels_fontsize`: Font size
- `padding::Float64 = 0.1`: Padding as fraction of range (0.1 = 10%)
- `node_sizes`: Optional node marker size(s) in pixels; used so flat chains/columns
  are not cropped under `DataAspect`

# Returns
- Tuple of tuples `((x_min, x_max), (y_min, y_max))` for axis limits
"""
function compute_padded_limits(
    node_positions::AbstractVector,
    nlabels::Union{AbstractVector{<:AbstractString}, Nothing},
    nlabels_align,
    nlabels_distance::Real,
    nlabels_fontsize::Real;
    padding::Float64 = 0.1,
    to_px = nothing,
    pixel_size::Tuple{Real, Real} = (500.0, 500.0),
    extra_points::AbstractVector = Point2f[],
    node_sizes = nothing,
)
    if nlabels !== nothing && !isempty(nlabels)
        x_min, x_max, y_min, y_max = compute_label_bounds(
            node_positions, nlabels, nlabels_align, nlabels_distance, nlabels_fontsize;
            to_px = to_px,
            pixel_size = pixel_size,
            extra_points = extra_points,
        )
    else
        xs = [Float64(pos[1]) for pos in node_positions]
        ys = [Float64(pos[2]) for pos in node_positions]
        x_min, x_max = minimum(xs), maximum(xs)
        y_min, y_max = minimum(ys), maximum(ys)

        if !isempty(extra_points)
            extra_xs = [Float64(point[1]) for point in extra_points]
            extra_ys = [Float64(point[2]) for point in extra_points]
            x_min = min(x_min, minimum(extra_xs))
            x_max = max(x_max, maximum(extra_xs))
            y_min = min(y_min, minimum(extra_ys))
            y_max = max(y_max, maximum(extra_ys))
        end
    end

    x_range = max(x_max - x_min, 1e-3)
    y_range = max(y_max - y_min, 1e-3)

    xs_nodes = [Float64(pos[1]) for pos in node_positions]
    ys_nodes = [Float64(pos[2]) for pos in node_positions]
    scale_x, scale_y = _pixel_to_data_scale(xs_nodes, ys_nodes; to_px = to_px, pixel_size = pixel_size)

    # Half the largest marker diameter in data units. Prefer the longer-axis
    # pixel→data scale so circular markers survive DataAspect on flat chains.
    node_radius_data = 0.0
    if node_sizes !== nothing
        sizes = node_sizes isa AbstractVector ? node_sizes : [node_sizes]
        max_node_px = Float64(maximum(sizes))
        node_radius_data = 0.5 * max_node_px * max(abs(scale_x), abs(scale_y))
    end

    long_range = max(x_range, y_range, 1.0)
    # Extra margin: at least one node radius plus a little breathing room
    marker_pad = node_radius_data + max(0.08 * long_range, 0.15 * node_radius_data)

    x_padding = max(padding * x_range, 0.05 * x_range, 0.05, marker_pad)
    y_padding = max(padding * y_range, 0.05 * y_range, 0.05, marker_pad)

    # DataAspect shrinks the plot area to match the data aspect ratio. A nearly
    # collinear chain can collapse that area to a strip thinner than the node
    # markers (pixel-sized). Enforce the minimum aspect on the *final* spans
    # after ordinary padding, otherwise growing the long axis undoes the fix.
    min_aspect = 0.35
    x_span = x_range + 2 * x_padding
    y_span = y_range + 2 * y_padding
    if y_span < min_aspect * x_span
        y_padding = max(y_padding, 0.5 * (min_aspect * x_span - y_range))
    end
    if x_span < min_aspect * y_span
        x_padding = max(x_padding, 0.5 * (min_aspect * y_span - x_range))
    end

    return (
        (x_min - x_padding, x_max + x_padding),
        (y_min - y_padding, y_max + y_padding)
    )
end

function _pixel_to_data_scale(xs::Vector{Float64}, ys::Vector{Float64}; to_px, pixel_size::Tuple{Real, Real})
    if to_px === nothing
        x_range = max(maximum(xs) - minimum(xs), 0.1)
        y_range = max(maximum(ys) - minimum(ys), 0.1)
        return x_range / Float64(pixel_size[1]), y_range / Float64(pixel_size[2])
    end

    origin_px = to_px(Point2f(0, 0))
    unit_x_px = to_px(Point2f(1, 0))
    unit_y_px = to_px(Point2f(0, 1))

    scale_x = Float64(unit_x_px[1] - origin_px[1])
    scale_y = Float64(unit_y_px[2] - origin_px[2])

    safe_scale_x = abs(scale_x) > 1e-6 ? scale_x : 1.0
    safe_scale_y = abs(scale_y) > 1e-6 ? scale_y : 1.0

    return 1 / safe_scale_x, 1 / safe_scale_y
end
