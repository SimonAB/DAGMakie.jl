# Changelog

All notable changes to DAGMakie.jl will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
