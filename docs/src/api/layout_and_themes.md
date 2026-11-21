# Layout & themes

```@meta
CurrentModule = DAGMakie
```

## Layout utilities

```@docs
compute_graph_layout
DAGLayoutResult
classify_graph_kind
feedback_edge_mask
edge_waypoint_vector
count_layered_crossings
```

## Label alignment and sizing

```@docs
compute_auto_label_aligns
align_to_direction
estimate_label_extent
estimate_label_pixel_size
node_size_for_inner_label
fit_node_sizes_to_labels
compute_label_bounds
compute_padded_limits
```

## Edge routing

Edges are straight by default. Per-edge bows use `edge_routing` on
[`dagplot`](@ref) / [`dagplot!`](@ref) (see [Basic Plotting](@ref)).

```@docs
CurvedEdge
DEFAULT_EDGE_BOW
```

## Themes and styling

```@docs
dag_theme
apply_dag_theme!
DAGStyle
default_style
minimal_style
bold_style
presentation_style
UNDIRECTED_EDGE_COLOR
OUTER_LABEL_DISTANCE
OUTER_LABEL_COLOR
OUTER_LABEL_NODE_SIZE
DEFAULT_NODE_GAP_INNER
DEFAULT_NODE_GAP_OUTER
FIT_NODE_LABEL_PADDING
FIT_NODE_MIN_SIZE
FIT_NODE_RECT_ASPECT
FIT_NODE_MARKER
DEFAULT_NODE_COLOR
DEFAULT_NODE_SIZE
DEFAULT_EDGE_COLOR
DEFAULT_LABEL_FONTSIZE
DEFAULT_LABEL_DISTANCE
DEFAULT_LABEL_POSITION
DEFAULT_SELFEDGE_SIZE
MODIFIER_EDGE_COLOR
MODIFIER_EDGE_STYLE
MODIFIER_EDGE_WIDTH
NODE_COLOR_CONFOUNDER
NODE_COLOR_MEDIATOR
NODE_COLOR_EFFECT
NODE_COLOR_SWIG_FIXED
TREATMENT_STROKEWIDTH
OUTCOME_STROKEWIDTH
```

## Node type styling

```@docs
default_node_color
default_node_marker
default_node_strokewidth
default_node_strokecolor
default_node_label_color
node_type_marker
node_type_color
node_type_strokewidth
node_type_strokecolor
node_type_label_color
apply_node_type_styling
typed_confounding_graph
typed_mediation_graph
typed_instrumental_graph
typed_collider_graph
```
