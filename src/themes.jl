"""
Publication-ready themes for DAG visualisation.

Provides clean, minimal themes suitable for academic papers and presentations.
"""

using Makie: Theme, Attributes

"""
    dag_theme()

Return a clean theme for DAG visualisation.

This theme removes axes, grids, and frames to create publication-ready
causal diagrams with focus on the graph structure.

# Returns
- `Theme`: A Makie theme with clean DAG styling

# Usage
```julia
using CairoMakie, DAGMakie

# Apply theme globally
set_theme!(dag_theme())

# Or use with_theme for a single plot
with_theme(dag_theme()) do
    dagplot(g, nlabels=["X", "Y", "Z"])
end
```
"""
function dag_theme()
    return Theme(
        # Axis styling - hide everything
        Axis = Attributes(
            xgridvisible = false,
            ygridvisible = false,
            xticksvisible = false,
            yticksvisible = false,
            xticklabelsvisible = false,
            yticklabelsvisible = false,
            xlabelvisible = false,
            ylabelvisible = false,
            topspinevisible = false,
            bottomspinevisible = false,
            leftspinevisible = false,
            rightspinevisible = false,
            aspect = Makie.DataAspect(),
        ),
        # Figure styling
        Figure = Attributes(
            backgroundcolor = :white,
        ),
    )
end

# =============================================================================
# Default Styling Constants
# =============================================================================

"""Default node size in pixels (large enough for in-node labels)."""
const DEFAULT_NODE_SIZE = 34
"""Default node colour (steel-blue; white labels read clearly)."""
const DEFAULT_NODE_COLOR = :steelblue

"""Highlight colour for confounders / exogenous noise / instruments."""
const NODE_COLOR_CONFOUNDER = :goldenrod

"""Highlight colour for mediators or other focal nodes."""
const NODE_COLOR_MEDIATOR = :seagreen

"""Default node stroke width."""
const DEFAULT_NODE_STROKEWIDTH = 1.0

"""Default node stroke colour."""
const DEFAULT_NODE_STROKECOLOR = :black

"""Default edge colour."""
const DEFAULT_EDGE_COLOR = :black

"""Default edge width."""
const DEFAULT_EDGE_WIDTH = 2.0

"""Default arrow size."""
const DEFAULT_ARROW_SIZE = 14

"""Default arrow shift (`:end` places arrow at destination node)."""
const DEFAULT_ARROW_SHIFT = :end

"""Default label font size."""
const DEFAULT_LABEL_FONTSIZE = 16

"""Default label colour (white text inside nodes)."""
const DEFAULT_LABEL_COLOR = :white

"""Default label distance from node (pixels); 0 centres labels in nodes."""
const DEFAULT_LABEL_DISTANCE = 0

"""Default label alignment (centred in the node)."""
const DEFAULT_LABEL_ALIGN = (:center, :center)

"""Default padding fraction."""
const DEFAULT_PADDING = 0.35

# =============================================================================
# Style Presets
# =============================================================================

"""
    DAGStyle

Preset styling configuration for DAG visualisation.

# Fields
- `node_size::Real`: Node size in pixels
- `node_color::Symbol`: Default node colour
- `node_strokewidth::Real`: Node outline width
- `node_strokecolor::Symbol`: Node outline colour
- `edge_color::Symbol`: Edge colour
- `edge_width::Real`: Edge line width
- `arrow_size::Real`: Arrowhead size
- `arrow_shift`: Arrow position (`:end` or Float64)
- `label_fontsize::Real`: Label font size
- `label_color::Symbol`: Label colour
- `label_distance::Real`: Label distance from node
- `padding::Float64`: Padding fraction
"""
struct DAGStyle
    node_size::Real
    node_color
    node_strokewidth::Real
    node_strokecolor
    edge_color
    edge_width::Real
    arrow_size::Real
    arrow_shift::Union{Symbol, Real}
    label_fontsize::Real
    label_color
    label_distance::Real
    padding::Float64
end

"""
    default_style()

Return the default DAG styling configuration.
"""
function default_style()
    return DAGStyle(
        DEFAULT_NODE_SIZE,
        DEFAULT_NODE_COLOR,
        DEFAULT_NODE_STROKEWIDTH,
        DEFAULT_NODE_STROKECOLOR,
        DEFAULT_EDGE_COLOR,
        DEFAULT_EDGE_WIDTH,
        DEFAULT_ARROW_SIZE,
        DEFAULT_ARROW_SHIFT,
        DEFAULT_LABEL_FONTSIZE,
        DEFAULT_LABEL_COLOR,
        DEFAULT_LABEL_DISTANCE,
        DEFAULT_PADDING
    )
end

"""
    minimal_style()

Return a minimal DAG style with smaller nodes and thinner edges.
"""
function minimal_style()
    return DAGStyle(
        28,             # node_size
        :slategray,     # muted steel
        0.5,            # node_strokewidth
        :darkgray,      # node_strokecolor
        :darkgray,      # edge_color
        1.0,            # edge_width
        10,             # arrow_size
        :end,           # arrow_shift
        14,             # label_fontsize
        :white,         # label_color
        0,              # label_distance (in-node)
        0.30            # padding
    )
end

"""
    bold_style()

Return a bold DAG style with larger nodes and thicker edges.
"""
function bold_style()
    return DAGStyle(
        42,             # node_size
        DEFAULT_NODE_COLOR,
        2.0,            # node_strokewidth
        :black,         # node_strokecolor
        :black,         # edge_color
        2.5,            # edge_width
        16,             # arrow_size
        :end,           # arrow_shift
        18,             # label_fontsize
        :white,         # label_color
        0,              # label_distance (in-node)
        0.40            # padding
    )
end

"""
    presentation_style()

Return a style optimised for presentations (large, high contrast, in-node labels).
"""
function presentation_style()
    return DAGStyle(
        48,             # node_size
        DEFAULT_NODE_COLOR,
        2.5,            # node_strokewidth
        :black,         # node_strokecolor
        :black,         # edge_color
        2.5,            # edge_width
        18,             # arrow_size
        :end,           # arrow_shift
        20,             # label_fontsize
        :white,         # label_color
        0,              # label_distance (in-node)
        0.45            # padding
    )
end
