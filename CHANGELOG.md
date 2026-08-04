# Changelog

All notable changes to DAGMakie.jl will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[0.1.1]: https://github.com/SimonAB/DAGMakie.jl/releases/tag/v0.1.1
[0.1.0]: https://github.com/SimonAB/DAGMakie.jl/releases/tag/v0.1.0
