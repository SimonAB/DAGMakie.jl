# Scope & design boundaries

DAGMakie.jl is a **visualisation-only** package for causal diagrams on Makie
and GraphMakie. It draws what the user or an upstream identification package
already specified; it does not compute identification certificates, fit models,
or run simulations. See also
[BOUNDARIES.md](https://github.com/SimonAB/DAGMakie.jl/blob/main/BOUNDARIES.md)
and the shared
[DESIGN_PRINCIPLES.md](https://github.com/SimonAB/causal-dynamics-book/blob/main/packages/DESIGN_PRINCIPLES.md).

## Ownership across the CDCS stack

| Package | Role | Boundary with DAGMakie |
|---------|------|------------------------|
| **DAGMakie.jl** (this package) | Causal DAG / digraph / mixed-graph figures, layered & temporal layouts, themes, edge routing, display conventions | Core depends only on `Graphs`, `Makie`, `GraphMakie`, `NetworkLayout`, and `Reexport` |
| [CausalDynamics.jl](https://simonab.github.io/CausalDynamics.jl/dev/) | Structural graphs, `identify` certificates, `TemporalUnrolling`, SCM/CDM simulation | Supplies `IdentificationResult` and `TemporalUnrolling` via its `CausalDynamicsDAGMakieExt` weakdep |
| [CausalInference.jl](https://github.com/mschauer/CausalInference.jl) | d-separation and adjustment-set search | Optional weakdep (`DAGMakieCausalInferenceExt`) for highlighting when loaded |
| [CausalTargeted.jl](https://simonab.github.io/CausalTargeted.jl/dev/) / [CausalMediation.jl](https://simonab.github.io/CausalMediation.jl/dev/) | LMTP, Super Learner, Bayesian g-computation, and mediation EIF estimation | Out of scope here; stress notebooks call `dagplot` for figures only |

## What is in scope

- **Layered & SCC-aware layouts:** deterministic layered layout for acyclic
  graphs, SCC-aware layout with curved feedback overlays for cyclic graphs, and
  `NetworkLayout` fallbacks.
- **Temporal & skeleton layouts:** [`dagplot_time_indexed`](@ref),
  [`dagplot_temporal`](@ref), and [`dagplot_skeleton`](@ref). Temporal glyphs
  read declared `value_representation` (`:interval_summary` only uses rounded
  rectangles); support and referent identity are never inferred from shape.
- **Causal conventions & visual grammar:** observed vs latent styling,
  bidirected confounding (`MixedGraph`), dagitty-style `color_by` role
  colouring, display-only `do(·)` surgery (`do_surgery`, `dagplot_do`),
  interaction IDAGs, and DiD SWIGs.

## What is out of scope

- Computing adjustment sets, d-separation, or `identify` in core (belongs in
  `CausalInference.jl` / `CausalDynamics.jl`).
- Statistical estimation, Super Learner, LMTP, or mediation EIF.
- Cohort data, registries, or hierarchical model fitting.
- Inventing ontology from glyphs or layout (`:occasion` / `:enduring` belong in
  book prose and `CausalDynamics.ReferentSpec`; node count follows
  `temporal_support` + `graph_kind`).
- Hard dependency on `CausalDynamics`, `CausalInference`, or Graphviz (`dot`).
- Interactive WebGL graph exploration for massive graphs (target scale is
  notebook- and publication-scale causal diagrams, roughly 5–200 labelled
  nodes).

## Validation checks

- **Geometry & API regressions:** `test/test_layout.jl`,
  `test/test_temporal_layout.jl`, `test/test_auto_align.jl`,
  `test/test_highlighting.jl`, and `test/test_interventions.jl`.
- **Optional extension tests:** `test/test_smart.jl` and
  `test/test_causaldynamics_ext.jl`.
- **Package QA:** Aqua.jl ambiguity and piracy checks in `test/test_aqua.jl`.
- **Optional timing budgets:** set `DAGMAKIE_PERF=1` when running the test
  suite (`test/test_perf.jl`), or run the manual timing gallery via
  `julia --project=. test/benchmark_layouts.jl`.
