# SPDX-License-Identifier: MIT

"""
    DAGMakie

Plot directed acyclic and related causal graphs with Makie, building on
GraphMakie.jl. Defaults omit axes and grids; helpers cover common causal
diagram conventions, bidirected confounding, and display-only `do(·)` surgery.

Identification (d-separation, adjustment sets) belongs in CausalInference.jl;
executable SCMs belong in CausalDynamics.jl. Optional convenience plots that
call CausalInference activate via `using CausalInference`.

Layouts are deterministic for DAGs; themes (`dag_theme`, …) control stroke and
spacing. Pattern constructors include chain, fork, collider, and confounding.

# Quick Start

```julia
using Graphs, DAGMakie, CairoMakie

g = SimpleDiGraph(3)
add_edge!(g, 1, 2)  # Z → X
add_edge!(g, 1, 3)  # Z → Y
add_edge!(g, 2, 3)  # X → Y

fig, ax, p = dagplot(g, nlabels=["Z", "X", "Y"])
save("confounding_dag.png", fig)
```

# Main Functions

- `dagplot(g; kwargs...)` - Create a new figure with DAG plot
- `dagplot!(ax, g; kwargs...)` - Plot DAG into existing axis
- `compute_auto_label_aligns(g, positions)` - Compute optimal label positions
- `dag_theme()` - Return the default Makie theme for DAG figures

# Convenience Patterns

- `dagplot_chain(labels)` - X₁ → X₂ → ... → Xₙ
- `dagplot_fork(labels)` - X ← Y → Z
- `dagplot_collider(labels)` - X → Y ← Z
- `dagplot_confounding(labels)` - Z → X → Y, Z → Y
- `dagplot_mediation(labels)` - X → M → Y, X → Y

See the documentation for full details and examples.
"""
module DAGMakie

using Reexport

# Dependencies
using Graphs
using Makie
using GraphMakie
using NetworkLayout

# Re-export useful types from dependencies
@reexport using Graphs: SimpleDiGraph, DiGraph, add_edge!, has_edge, nv, ne

# Include source files
include("themes.jl")
include("types.jl")
include("auto_align.jl")
include("layout.jl")
include("utils.jl")
include("bidirected.jl")
include("layout_strategy.jl")
include("node_styling.jl")
include("paths.jl")
include("highlighting.jl")
include("interventions.jl")
include("smart.jl")
include("dagplot.jl")
include("visual_grammar.jl")

# =============================================================================
# Exports
# =============================================================================

# Main plotting functions
export dagplot, dagplot!

# Convenience pattern functions
export dagplot_chain, dagplot_fork, dagplot_collider
export dagplot_confounding, dagplot_mediation
export dagplot_confounded, dagplot_frontdoor, dagplot_iv_confounded, dagplot_m_bias

# Auto-alignment
export compute_auto_label_aligns
export align_to_direction
export resolve_auto_align_label_settings
export AUTO_ALIGN_LABEL_DISTANCE, AUTO_ALIGN_LABEL_COLOR

# Layout utilities
export estimate_label_extent, compute_label_bounds, compute_padded_limits
export DAGLayoutResult, classify_graph_kind, compute_graph_layout, feedback_edge_mask, edge_waypoint_vector
export time_indexed_layout, dagplot_time_indexed

# Themes and styling
export dag_theme
export DAGStyle, default_style, minimal_style, bold_style, presentation_style
export DEFAULT_NODE_COLOR, NODE_COLOR_CONFOUNDER, NODE_COLOR_MEDIATOR
export NODE_COLOR_EFFECT, NODE_COLOR_SWIG_FIXED
export TREATMENT_STROKEWIDTH, OUTCOME_STROKEWIDTH
export MODIFIER_EDGE_STYLE, MODIFIER_EDGE_COLOR, MODIFIER_EDGE_WIDTH
export UNDIRECTED_EDGE_COLOR
export apply_dag_theme!

# Types
export NodeType, Observed, Latent, Treatment, Outcome, Instrument, Confounder, Mediator, Collider
export EffectMeasure, SwigFixed
export NodeSpec, EdgeSpec, DAGSpec
export EdgeType, Directed, Bidirected, Undirected, Modifier
export node, edge
export default_node_color, default_node_marker, default_node_strokewidth
export default_node_strokecolor, default_node_label_color

# Node type styling
export node_type_marker, node_type_color, node_type_strokewidth, node_type_strokecolor
export node_type_label_color
export apply_node_type_styling
export typed_confounding_graph, typed_mediation_graph, typed_instrumental_graph, typed_collider_graph

# Visual grammar (interactions / DiD SWIGs)
export modifier_edge, dagplot_side_by_side
export vaccine_nutrition_outcome_spec, vaccine_nutrition_idag_spec
export vaccine_nutrition_layout, dagplot_vaccine_nutrition_interaction
export did_2x2_factual_spec, did_2x2_swig_spec
export did_2x2_factual_layout, did_2x2_swig_layout, dagplot_did_swig

# Smart / dagitty-style colouring
export SmartNodeRole, SmartExposure, SmartOutcome
export SmartAncestorExposure, SmartAncestorOutcome, SmartAncestorBoth, SmartIrrelevant
export smart_node_color, smart_label_color
export ancestors_via_graphs, ancestor_sets, classify_smart_roles
export smart_style_for_graph, dagplot_smart
export SMART_COLOR_EXPOSURE, SMART_COLOR_OUTCOME
export SMART_COLOR_ANC_EXPOSURE, SMART_COLOR_ANC_OUTCOME, SMART_COLOR_ANC_BOTH
export SMART_COLOR_IRRELEVANT

# Utilities
export get_node_positions, graph_extent, is_dag, edge_list
export adjacency_to_graph, graph_from_edges, graph_from_structural_matrix
export ensure_structural_self_loops!
export chain_graph, fork_graph, collider_graph, confounding_graph, mediation_graph, instrumental_graph
export digraph_skeleton, dagplot_skeleton
export structural_edge_labels, edge_coefficient_labels

# Bidirected edges / Mixed graphs
export MixedGraph, mixed_graph
export add_directed_edge!, add_bidirected_edge!
export has_bidirected_edge, bidirected_edges, num_bidirected_edges
export compute_bidirected_path, compute_all_bidirected_paths, bidirected_arrow_positions
export confounded_graph, frontdoor_graph, iv_confounded_graph, m_bias_graph, m_bias_spec

# Paths (data for highlights — not identification algorithms)
export CausalPath, PathSegment
export path_edges, is_directed_path

# Highlighting
export HighlightSpec
export highlight_from_path, highlight_from_paths
export highlight_adjustment_set, highlight_backdoor_paths
export dagplot_highlighted, dagplot_highlighted!
export dagplot_backdoor, dagplot_dsep, dagplot_causal_paths, dagplot_adjustment

# Interventions (graph surgery + drawing)
export Intervention, CausalQuery
export do_surgery, do_surgery!
export intervention_label, format_intervention_labels
export dagplot_intervention, dagplot_intervention!
export dagplot_do, dagplot_comparison, dagplot_do_comparison
export query_to_string

# Constants
export DEFAULT_NODE_SIZE, DEFAULT_NODE_COLOR, DEFAULT_EDGE_COLOR
export DEFAULT_LABEL_FONTSIZE, DEFAULT_LABEL_DISTANCE, DEFAULT_SELFEDGE_SIZE

end # module
