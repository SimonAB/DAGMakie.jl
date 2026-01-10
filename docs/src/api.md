# API Reference

## Main Plotting Functions

```@docs
dagplot
dagplot!
```

## Convenience Pattern Functions

```@docs
dagplot_chain
dagplot_fork
dagplot_collider
dagplot_confounding
dagplot_mediation
dagplot_confounded
dagplot_frontdoor
dagplot_iv_confounded
dagplot_m_bias
```

## Types

### Node Types

```@docs
NodeType
NodeSpec
```

### Edge Types

```@docs
EdgeType
EdgeSpec
```

### DAG Specification

```@docs
DAGSpec
```

### Mixed Graphs

```@docs
MixedGraph
```

### Paths

```@docs
CausalPath
PathSegment
```

### Interventions

```@docs
Intervention
CausalQuery
```

## Graph Construction

```@docs
chain_graph
fork_graph
collider_graph
confounding_graph
mediation_graph
instrumental_graph
mixed_graph
confounded_graph
frontdoor_graph
iv_confounded_graph
m_bias_graph
```

## Path Finding

```@docs
find_all_paths
find_directed_paths
find_backdoor_paths
is_backdoor_path
path_edges
is_directed_path
```

## d-Separation

```@docs
is_d_separated
d_separated_from
is_collider
ancestors
descendants
```

## Adjustment Sets

```@docs
is_valid_adjustment_set
blocks_all_backdoor_paths
find_minimal_adjustment_set
list_all_adjustment_sets
```

## Highlighting

```@docs
HighlightSpec
highlight_from_path
highlight_from_paths
highlight_adjustment_set
highlight_backdoor_paths
dagplot_highlighted
dagplot_highlighted!
dagplot_backdoor
dagplot_dsep
dagplot_causal_paths
dagplot_adjustment
```

## Interventions

```@docs
do_surgery
do_surgery!
dagplot_intervention
dagplot_intervention!
dagplot_do
dagplot_comparison
dagplot_do_comparison
causal_effect_identifiable
intervention_removes_confounding
identify_confounders
intervention_label
format_intervention_labels
query_identifiable
query_to_string
```

## Label Alignment

```@docs
compute_auto_label_aligns
align_to_direction
```

## Layout Utilities

```@docs
estimate_label_extent
compute_label_bounds
compute_padded_limits
get_node_positions
graph_extent
```

## Themes and Styling

```@docs
dag_theme
apply_dag_theme!
DAGStyle
default_style
minimal_style
bold_style
presentation_style
```

## Node Type Styling

```@docs
default_node_color
default_node_marker
default_node_strokewidth
node_type_marker
node_type_color
node_type_strokewidth
node_type_strokecolor
apply_node_type_styling
typed_confounding_graph
typed_mediation_graph
typed_instrumental_graph
typed_collider_graph
```

## Mixed Graph Operations

```@docs
add_directed_edge!
add_bidirected_edge!
has_bidirected_edge
bidirected_edges
num_bidirected_edges
compute_bidirected_path
compute_all_bidirected_paths
bidirected_arrow_positions
```

## Utilities

```@docs
is_dag
edge_list
adjacency_to_graph
graph_from_edges
```
