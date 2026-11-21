# Plotting

```@meta
CurrentModule = DAGMakie
```

## Main plotting functions

```@docs
dagplot
dagplot!
```

## Convenience pattern functions

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

## Edge labels and terminal markers

```@docs
structural_edge_labels
edge_coefficient_labels
edge_terminal_markers
INHIBITORY_EDGE_MARKER
```

## Visual grammar (interactions / DiD)

```@docs
modifier_edge
dagplot_side_by_side
did_2x2_factual_spec
did_2x2_swig_spec
did_2x2_factual_layout
did_2x2_swig_layout
dagplot_did_swig
```
