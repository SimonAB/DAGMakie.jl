# Changelog

All notable changes to DAGMakie.jl will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-07-20

### Added

- Initial release of DAGMakie.jl
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

[0.1.0]: https://github.com/SimonAB/DAGMakie.jl/releases/tag/v0.1.0
