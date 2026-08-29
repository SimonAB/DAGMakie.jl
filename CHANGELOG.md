# Changelog

All notable changes to DAGMakie.jl will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.11] - 2026-08-29

### Added

- Temporal smart-role propagation for time-unrolled DAGs ([#5](https://github.com/SimonAB/DAGMakie.jl/issues/5)):
  [`propagate_temporal_smart_roles`](@ref), [`smart_style_for_temporal_graph`](@ref),
  [`temporal_role_styling`](@ref), [`apply_temporal_smart_kwargs`](@ref), and
  indexing helpers [`temporal_node_index`](@ref) / [`temporal_variable_time`](@ref).
- [`dagplot_time_indexed`](@ref) applies propagated `color_by` styling when
  `exposure` / `outcome` are set (scalar indices or `(variable, time)` tuples).
- `color_by = :ancestors_temporal` as an explicit alias for temporal plots.

### Changed

- **Breaking:** default `label_position` is `:outer` (compact [`OUTER_LABEL_NODE_SIZE`](@ref)
  markers, dark external labels, auto-aligned gaps). Use `label_position=:inner` with
  `fit_node_size_to_labels=true` for the previous in-node white-label style.
- [`default_style`](@ref) targets outer labels; [`DEFAULT_LABEL_FONTSIZE`](@ref) is `13`;
  [`DEFAULT_PADDING`](@ref) is `0.38`.
- `fit_node_size_to_labels` defaults to `false` (opt in for in-node oval markers).
- `dagplot!` applies label-aware axis limits when outer labels are active (pre- and
  post-`graphplot!` refinement under `DataAspect`).

## [0.1.10] - 2026-08-22

### Changed

- **`edge_routing`** and **`CurvedEdge`**: edges straight by default; curve per edge
  with `:curved`, [`CurvedEdge`](@ref) (default bow [`DEFAULT_EDGE_BOW`](@ref)),
  a bow fraction (`Real`), or `CurvedEdge(distance=…)` for GraphMakie bend angle
  (``γ = 2\\operatorname{atan}(2d/L)``). Legacy **`straight_edges`** remains
  shorthand for `:straight`.
- Default `long_edge_routing` is `:quadratic` (Bézier samples when an edge is
  curved); `:natural_cubic` remains available. Other styles: `:none`, `:rounded`,
  `:tangents`, `:curve_distance`.
- Removed automatic skip-chord obstacle routing (`:auto`); curvature is explicit
  via `edge_routing` only.

## [0.1.9] - 2026-08-21

### Fixed

- Feedback and bidirected overlays normalise `(width, height)` node sizes to a
  scalar extent before calling GraphMakie `distance_between_markers`, so fitted
  ovals work with **General** GraphMakie 0.6.6 (which multiplies sizes directly;
  the SimonAB fork already used `maximum` internally).

## [0.1.8] - 2026-08-21

### Changed

- Documentation and examples prefer the discoverable names below.
- Discoverable keyword aliases (legacy names kept):
  - `color_by` (was `smart`); `exposure` (alias of `treatment`)
  - `labels` (alias of `nlabels`); `label_obstacle_graph` (was `auto_align_graph`)
  - `show_removed_edges` (was `show_original`); `do_node_labels` (was `relabel_nodes`)
  - `OUTER_LABEL_*` constants (aliases of `AUTO_ALIGN_*`)
- Default within-layer `node_gap` is [`DEFAULT_NODE_GAP_INNER`](@ref) (`2.6`) when
  `label_position=:inner`, and [`DEFAULT_NODE_GAP_OUTER`](@ref) (`1.8`) when
  `label_position=:outer` (was a flat `1.8` for both).
- Document `layout_mode = :auto` as the default (docs no longer imply `Spring()`)
- Barycentric layer sweeps: 6 passes (was 4)
- Highlight node/edge colours: **first listing wins** when duplicates appear
- `label_position=:outer` (and legacy `auto_align_labels=true`) defaults to
  [`OUTER_LABEL_NODE_SIZE`](@ref) (19) unless `node_size` is set explicitly
  (in-node themes stay larger).
- Resolve docs: CausalInference ≥0.19.4 allows GraphMakie 0.6 in one environment
  with CausalDynamics; dual-env guidance retired.

### Added

- `label_position = :inner | :outer`: discoverable placement for node labels
  (`:outer` = outside in the largest angular gap). Legacy `auto_align_labels=true`
  remains a synonym for `:outer`.
- `fit_node_size_to_labels=true` **by default** for in-node labels: size markers
  from each label (short → round circle; wide → oval via [`FIT_NODE_MARKER`](@ref)
  + `(width, height)`), via [`estimate_label_pixel_size`](@ref) /
  [`node_size_for_inner_label`](@ref) / [`fit_node_sizes_to_labels`](@ref). Pass
  `false` (or set `node_size`) to keep a uniform size. Skipped for
  `label_position=:outer`.
- Long-range forward edges that skim intermediate nodes receive GraphMakie
  waypoints (cubic spline) so skip chords do not draw through nodes
- `count_layered_crossings` for layered quality checks
- Guide page [Output Quality](docs/src/guide/output_quality.md)
- Optional `DAGMAKIE_PERF=1` layout/render budgets in `test/test_perf.jl`
- Geometry regressions for skip chords, Unicode single-node limits, shared
  comparison layouts, and `show_backdoor=false`

### Fixed

- Documenter build: docstring aliases for `AUTO_ALIGN_*`, export/document
  `apply_smart_kwargs`, and import packages in the `basic-fit` `@example`.
- `fit_node_size_to_labels` now uses `Makie.Circle` ([`FIT_NODE_MARKER`](@ref))
  instead of `:circle`, whose BezierPath draws at ~70% of `markersize` and made
  fitted ovals too small for the labels (e.g. intro `fig-cdm-diagram`).
- Removed-edge overlays in `dagplot_intervention!` (`show_removed_edges=true`) now
  trim against the plot’s actual `node_size` / `node_marker` (including fitted
  ovals), so grey dashed arrows meet the node boundary instead of the in-node
  label.
- `color_by` + `label_position=:outer` now uses [`OUTER_LABEL_COLOR`](@ref)
  for outer labels (smart’s white in-node colours were kept before and were
  unreadable on the figure background).
- Intervention plots with `label_position=:outer` and `show_removed_edges=true` now
  align labels against the factual DAG, so grey removed parent edges count as
  obstacles (same placement as the left panel of `dagplot_do_comparison`).

## [0.1.7] - 2026-08-09

### Changed

- DiD SWIG defaults restore non-scalar `node_size` tuples (`Y₁(0)` `(132, 84)`,
  `a=0` `(105, 80)`) now that GraphMakie **0.6.6** includes
  [MakieOrg/GraphMakie#259](https://github.com/MakieOrg/GraphMakie.jl/pull/259).
- `[compat] GraphMakie` is `"0.6.6"` (registry 0.6.5 still errors on tuple sizes).

## [0.1.6] - 2026-08-04

### Changed

- DiD SWIG default node sizes are scalars (not width/height tuples) so package
  tests pass against registry GraphMakie before the non-scalar `node_size` fix
  ([MakieOrg/GraphMakie#259](https://github.com/MakieOrg/GraphMakie.jl/pull/259))
  is released. CI/docs no longer pin a GraphMakie fork for AutoMerge.

### Fixed

- `graph_from_structural_matrix` atol test asserted the wrong edge count
  (atol drops *small* entries, not the large diagonal).

### Added

- [`graph_from_structural_matrix`](@ref): build a `SimpleDiGraph` from a structural
  weight matrix $B$ (same `B[i,j]` on $j\to i$ convention as
  [`structural_edge_labels`](@ref)), including self-loops for non-zero diagonal
  entries so GraphMakie can draw self-pointing arcs.
- Compact default `selfedge_size` ([`DEFAULT_SELFEDGE_SIZE`](@ref) = 0.25) when
  the graph has self-loops and the caller does not set `selfedge_size`.
- [`ensure_structural_self_loops!`](@ref) and default
  `structural_edge_labels(...; ensure_self_loops=true)`: a non-zero diagonal on
  $B$ adds missing self-loops on `g` before labels are built.

### Fixed

- Layout classification ignores self-loops, so a diagonal structural weight no
  longer forces cyclic / flat layout on an otherwise acyclic DAG.
- Basic guide “Outside the node” example: GraphMakie only offsets labels along
  `nlabels_align`, so a positive `nlabels_distance` with the default
  `(:center, :center)` left black text inside the markers. The example now sets
  `nlabels_align = (:center, :bottom)` and documents the requirement.
- `dagplot` warns when `nlabels_distance > 0` but align remains centred.
- `structural_edge_labels` warns when off-diagonal non-zero `B` entries have no
  matching edge in `g` (diagonal self-loops are ensured automatically by default).

## [0.1.5] - 2026-07-31

### Added

- Dagitty-style `smart=true` / `:ancestors` / `:adjustment` node colouring on
  `dagplot` (exposure, outcome, ancestral roles; optional adjustment emphasis).
  Uses CausalInference.jl ancestors when loaded; Graphs fallback otherwise.
  See `dagplot_smart` and `guide/causal.md`.
- Guide examples for smart colouring (default vs smart, full role palette,
  adjustment emphasis, fork + smart).
- Guide page `guide/skeletons_and_time.md` for CPDAG skeletons and time-indexed
  grids.
- [`structural_edge_labels`](@ref): build GraphMakie `elabels` from a structural
  parameter matrix `B` (or a custom vector), with optional Makie `LaTeXString`
  maths on edges. (`edge_coefficient_labels` remains as a deprecated alias.)
  Documented with rendered examples in Getting started and Basic plotting;
  `dagplot` documents `elabels` / `elabels_*` passthrough.

## [0.1.4] - 2026-07-31

### Added

- Visual grammar for interactions and DiD SWIGs: `EffectMeasure` / `SwigFixed`
  node types, `Modifier` edge type, `modifier_edge`, and companion plot helpers
  `dagplot_vaccine_nutrition_interaction` / `dagplot_did_swig`.
- Guide page `guide/visual_grammar.md` documenting node/edge conventions and
  the two worked examples.
- Undirected CPDAG stroke defaults: undirected `SimpleGraph` plots suppress
  arrowheads (`arrow_show=false`) and use `UNDIRECTED_EDGE_COLOR`; convenience
  `dagplot_skeleton` wraps [`digraph_skeleton`](@ref).

## [0.1.3] - 2026-07-31

### Added

- `time_indexed_layout` / `dagplot_time_indexed` for graphs unrolled over occasions
  (column = time, row = variable; matches CausalDynamics `unroll_temporal_dag` order).
- `digraph_skeleton` to collapse opposing digraph edges into an undirected
  SimpleGraph (CPDAG-style PC displays).
- Undirected `SimpleGraph` inputs are treated as acyclic for layout metadata
  (avoids SCC on undirected graphs when plotting skeletons).

## [0.1.2] - 2026-07-29

### Changed

- Clarified that `do_surgery` / `do_surgery!` are **display-only** (plot
  mutilation), not CausalDynamics identification APIs.
- Documented that `ext/DAGMakieCausalDynamicsExt.jl` remains intentionally
  unregistered until CausalDynamics is on General.

## [0.1.1] - 2026-07-23

### Changed

- **Breaking:** Identification APIs removed from DAGMakie. Use CausalInference.jl
  (optional extension) or CausalDynamics.jl for d-separation and adjustment sets.
  `dagplot_*` helpers take precomputed `adjustment` / `paths`, or auto-compute when
  `using CausalInference`.
- Optional `CausalInference` weakdep / `DAGMakieCausalInferenceExt`.
- Dropped local monorepo `[sources]` so the release resolves GraphMakie and
  CausalInference from General.
- Compat tightened to `GraphMakie = "0.6"` and `Makie = "0.24"` (registry
  CausalInference still caps GraphMakie at 0.5, so it is not in the default
  test target).
- Defensive GraphMakie attribute access (`:to_px`, `:nlabels_align_processed`)
  with headless fallbacks.

## [0.1.0] - 2026-07-20

### Added

- Initial release of DAGMakie.jl
- Note: the CausalDynamics.jl package extension is deferred until CausalDynamics is registered in General; `ext/DAGMakieCausalDynamicsExt.jl` remains in-tree for a follow-up release
- Core `dagplot` and `dagplot!` functions for DAG visualisation
- Automatic label alignment to avoid edge overlaps
- Publication-ready theme with clean styling
- `DAGSpec` type for declarative DAG specification
- Node type system (`Observed`, `Latent`, `Treatment`, `Outcome`, etc.)
- Convenience functions for common patterns:
  - `dagplot_chain`, `dagplot_fork`, `dagplot_collider`
  - `dagplot_confounding`, `dagplot_mediation`
- `MixedGraph` type for bidirected edges (unmeasured confounding)
- Bidirected edge visualisation as curved arcs
- Convenience functions for confounded graphs:
  - `dagplot_confounded`, `dagplot_frontdoor`
  - `dagplot_iv_confounded`, `dagplot_m_bias`
- Path finding algorithms:
  - `find_all_paths`, `find_directed_paths`, `find_backdoor_paths`
- d-separation testing with `is_d_separated`
- Adjustment set computation:
  - `is_valid_adjustment_set`, `find_minimal_adjustment_set`
  - `list_all_adjustment_sets`
- Path highlighting visualisation:
  - `dagplot_backdoor`, `dagplot_dsep`
  - `dagplot_causal_paths`, `dagplot_adjustment`
- Intervention (do-operator) support:
  - `do_surgery` for graph modification
  - `dagplot_intervention`, `dagplot_do`
  - `dagplot_comparison`, `dagplot_do_comparison`
- CausalDynamics.jl integration via package extension:
  - Direct plotting of SCM types
  - Integration with CausalDynamics analysis functions
  - `causal_analysis` and `print_causal_analysis` helpers

[0.1.10]: https://github.com/SimonAB/DAGMakie.jl/releases/tag/v0.1.10
[0.1.1]: https://github.com/SimonAB/DAGMakie.jl/releases/tag/v0.1.1
[0.1.0]: https://github.com/SimonAB/DAGMakie.jl/releases/tag/v0.1.0
