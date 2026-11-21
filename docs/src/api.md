# API Reference

```@meta
CurrentModule = DAGMakie
```

Public symbols in `DAGMakie` are organised across five reference pages:

- [Plotting](api/plotting.md) — [`dagplot`](@ref), [`dagplot!`](@ref),
  convenience pattern plotters, edge labels/terminals, and visual-grammar
  (IDAG / DiD SWIG) helpers.
- [Specs & graphs](api/specs_and_graphs.md) — `NodeType`, `EdgeType`, `DAGSpec`,
  `MixedGraph`, graph constructors, and graph utilities.
- [Highlighting & interventions](api/highlighting_and_do.md) — paths,
  `HighlightSpec`, dagitty-style `color_by` role colouring, display-only
  `do_surgery`, and `CausalQuery`.
- [Temporal & skeletons](api/temporal_and_skeletons.md) — time-indexed and mixed
  temporal layouts, temporal role propagation, and CPDAG skeletons.
- [Layout & themes](api/layout_and_themes.md) — layered/SCC layouts, label
  alignment and sizing, edge routing, themes, and node-type styling.

## Preferred keyword names

Public plotting prefers discoverable names; legacy aliases still work:

| Prefer | Alias (removed from public API) |
|--------|---------------------------------|
| `labels` | `nlabels` (GraphMakie pass-through still accepted) |
| `label_position = :outer` | former `auto_align_labels=true` |
| `label_obstacle_graph` | former `auto_align_graph` |
| `color_by` | former `smart` |
| `exposure` | former `treatment` (colouring kwargs) |
| `show_removed_edges` | former `show_original` |
| `do_node_labels` | former `relabel_nodes` |
| `OUTER_LABEL_*` | former `AUTO_ALIGN_*` |

GraphMakie pass-throughs keep the `nlabels_*` / `elabels_*` prefixes.
