# SPDX-License-Identifier: MIT

"""
Themes for DAG visualisation (no axes or grids by default).
"""

using Makie: Theme, Attributes, RGBf

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
    dagplot(g, labels=["X", "Y", "Z"])
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

"""Fill for IDAG effect-measure nodes (same family as mediators)."""
const NODE_COLOR_EFFECT = :seagreen

"""Fill for the fixed half of a SWIG split node."""
const NODE_COLOR_SWIG_FIXED = :white

"""Stroke width for treatment / exposure nodes."""
const TREATMENT_STROKEWIDTH = 2.5

"""Stroke width for outcome nodes (emphasised outline)."""
const OUTCOME_STROKEWIDTH = 2.0

"""Line style for pedagogical modifier annotations."""
const MODIFIER_EDGE_STYLE = :dashdot

"""Colour for pedagogical modifier annotations."""
const MODIFIER_EDGE_COLOR = :darkgray

"""Line width for pedagogical modifier annotations."""
const MODIFIER_EDGE_WIDTH = 1.25

"""Default colour for undirected (CPDAG skeleton) edges."""
const UNDIRECTED_EDGE_COLOR = RGBf(0.35, 0.35, 0.38)

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

"""Pixel offset used when `label_position=:outer` places labels outside nodes."""
const OUTER_LABEL_DISTANCE = 14

"""Label colour for outside-node labels (`label_position=:outer`)."""
const OUTER_LABEL_COLOR = :black

"""Default node size when `label_position=:outer` (compact markers; labels sit outside)."""
const OUTER_LABEL_NODE_SIZE = 19

"""Within-layer node spacing when `label_position=:inner` (room for fitted markers / chords)."""
const DEFAULT_NODE_GAP_INNER = 2.6

"""Within-layer node spacing when `label_position=:outer` (compact markers)."""
const DEFAULT_NODE_GAP_OUTER = 1.8

"""Deprecated alias of [`OUTER_LABEL_DISTANCE`](@ref). Prefer `OUTER_LABEL_DISTANCE`."""
const AUTO_ALIGN_LABEL_DISTANCE = OUTER_LABEL_DISTANCE

"""Deprecated alias of [`OUTER_LABEL_COLOR`](@ref). Prefer `OUTER_LABEL_COLOR`."""
const AUTO_ALIGN_LABEL_COLOR = OUTER_LABEL_COLOR

"""Deprecated alias of [`OUTER_LABEL_NODE_SIZE`](@ref). Prefer `OUTER_LABEL_NODE_SIZE`."""
const AUTO_ALIGN_NODE_SIZE = OUTER_LABEL_NODE_SIZE

"""Total padding (px) around text when fitting in-node markers to labels."""
const FIT_NODE_LABEL_PADDING = 12.0

"""Minimum marker size (px) when fitting in-node markers to labels."""
const FIT_NODE_MIN_SIZE = 28.0

"""Width/height ratio above which fitted in-node markers become ovals (not disks)."""
const FIT_NODE_RECT_ASPECT = 1.4

"""Default label alignment (centred in the node)."""
const DEFAULT_LABEL_ALIGN = (:center, :center)

"""Default padding fraction."""
const DEFAULT_PADDING = 0.35

"""Default GraphMakie `selfedge_size` (data units) for self-loops.

GraphMakie's automatic size is half the nearest-neighbour distance, which is
oversized on typical DAG layouts; keep loops compact beside the marker.
"""
const DEFAULT_SELFEDGE_SIZE = 0.25

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
