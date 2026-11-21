# Specs & graphs

```@meta
CurrentModule = DAGMakie
```

## Types

### Node types

```@docs
NodeType
NodeSpec
node
```

### Edge types

```@docs
EdgeType
EdgeSpec
edge
```

### DAG specification

```@docs
DAGSpec
```

### Mixed graphs

```@docs
MixedGraph
```

## Graph construction

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
m_bias_spec
graph_from_structural_matrix
ensure_structural_self_loops!
```

## Mixed graph operations

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
get_node_positions
graph_extent
```
