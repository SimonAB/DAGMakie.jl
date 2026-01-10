"""
Layout utilities for DAG visualisation.

Functions for computing label bounds, padding, and automatic axis limits
to ensure all elements are visible without clipping.
"""

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
    nlabels_fontsize::Real
)
    n = length(node_positions)
    
    # Get node coordinate ranges
    xs = [Float64(pos[1]) for pos in node_positions]
    ys = [Float64(pos[2]) for pos in node_positions]
    
    x_range = maximum(xs) - minimum(xs)
    y_range = maximum(ys) - minimum(ys)
    
    # Estimate pixels-to-data conversion factor
    # Assume a typical figure width of ~500 pixels for the data range
    typical_fig_size = 500.0
    px_to_data_x = max(x_range, 0.1) / typical_fig_size
    px_to_data_y = max(y_range, 0.1) / typical_fig_size
    
    # Start with node bounds
    x_min, x_max = minimum(xs), maximum(xs)
    y_min, y_max = minimum(ys), maximum(ys)
    
    # Expand bounds to include labels
    for i in 1:n
        pos = node_positions[i]
        label = nlabels[i]
        align = _get_align(nlabels_align, i)
        
        # Get pixel-space extent
        extent = estimate_label_extent(label, align, nlabels_fontsize, nlabels_distance)
        
        # Convert to data coordinates and expand bounds
        x_min = min(x_min, Float64(pos[1]) + extent.dx_min * px_to_data_x)
        x_max = max(x_max, Float64(pos[1]) + extent.dx_max * px_to_data_x)
        y_min = min(y_min, Float64(pos[2]) + extent.dy_min * px_to_data_y)
        y_max = max(y_max, Float64(pos[2]) + extent.dy_max * px_to_data_y)
    end
    
    return (x_min, x_max, y_min, y_max)
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
    compute_padded_limits(node_positions, nlabels, nlabels_align, nlabels_distance, nlabels_fontsize; padding=0.1)

Compute axis limits with padding that includes all nodes and labels.

# Arguments
- `node_positions`: Vector of node positions
- `nlabels`: Vector of label strings (or `nothing` for no labels)
- `nlabels_align`: Alignment specification
- `nlabels_distance`: Label distance in pixels
- `nlabels_fontsize`: Font size
- `padding::Float64 = 0.1`: Padding as fraction of range (0.1 = 10%)

# Returns
- Tuple of tuples `((x_min, x_max), (y_min, y_max))` for axis limits
"""
function compute_padded_limits(
    node_positions::AbstractVector,
    nlabels::Union{AbstractVector{<:AbstractString}, Nothing},
    nlabels_align,
    nlabels_distance::Real,
    nlabels_fontsize::Real;
    padding::Float64 = 0.1
)
    if nlabels !== nothing && !isempty(nlabels)
        x_min, x_max, y_min, y_max = compute_label_bounds(
            node_positions, nlabels, nlabels_align, nlabels_distance, nlabels_fontsize
        )
    else
        xs = [Float64(pos[1]) for pos in node_positions]
        ys = [Float64(pos[2]) for pos in node_positions]
        x_min, x_max = minimum(xs), maximum(xs)
        y_min, y_max = minimum(ys), maximum(ys)
    end
    
    x_range = x_max - x_min
    y_range = y_max - y_min
    
    # Calculate percentage-based padding
    x_padding_pct = padding * x_range
    y_padding_pct = padding * y_range
    
    # Minimum padding: at least 5% of range or 0.05 units
    min_padding_x = min(0.05 * x_range, 0.05)
    min_padding_y = min(0.05 * y_range, 0.05)
    
    # Use the larger of percentage-based or minimum padding
    x_padding = max(x_padding_pct, min_padding_x)
    y_padding = max(y_padding_pct, min_padding_y)
    
    return (
        (x_min - x_padding, x_max + x_padding),
        (y_min - y_padding, y_max + y_padding)
    )
end
