# Highlighting & interventions

```@meta
CurrentModule = DAGMakie
```

## Paths

```@docs
CausalPath
PathSegment
path_edges
is_directed_path
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

## Smart / dagitty colouring

```@docs
SmartNodeRole
classify_smart_roles
smart_style_for_graph
apply_smart_kwargs
dagplot_smart
ancestor_sets
ancestors_via_graphs
smart_node_color
smart_label_color
SMART_COLOR_EXPOSURE
SMART_COLOR_OUTCOME
SMART_COLOR_ANC_EXPOSURE
SMART_COLOR_ANC_OUTCOME
SMART_COLOR_ANC_BOTH
SMART_COLOR_IRRELEVANT
```

## Interventions

```@docs
Intervention
CausalQuery
do_surgery
do_surgery!
dagplot_intervention
dagplot_intervention!
dagplot_do
dagplot_comparison
dagplot_do_comparison
intervention_label
format_intervention_labels
query_to_string
```
