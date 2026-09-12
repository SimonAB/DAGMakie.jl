# Package boundaries

**Design principles:** [DESIGN.md](DESIGN.md) · [shared](https://github.com/SimonAB/causal-dynamics-book/blob/main/packages/DESIGN_PRINCIPLES.md)

## DAGMakie.jl (this package)

- Causal DAG / digraph / mixed-graph figures on Makie + GraphMakie
- Layouts (`dagplot`, layered, time-indexed, temporal key layout), themes, edge routing
- Display conventions: latents, bidirected confounding, path / role highlighting, display-only `do(·)` surgery
- Temporal glyphs from declared `value_representation` (rounded only for `:interval_summary`); support and referent identity are never inferred from shape
- Optional overlays that **highlight** upstream identification results (CausalInference / CausalDynamics extensions)

## CausalDynamics.jl

- Graphs, identification certificates, temporal unrolling, CDM simulation
- Supplies `TemporalUnrolling` / node specs for `dagplot_temporal`; DAGMakie does not own those types

## CausalTargeted.jl / CausalMediation.jl

- Estimation and mediation engines; stress notebooks may call `dagplot` for figures only

## Out of scope

- Computing adjustment sets, d-separation, or `identify` in core (belongs in CausalInference / CausalDynamics)
- Estimation, Super Learner, LMTP, mediation EIF
- Cohort data, registries, or hierarchical model fitting
- Inventing ontology from glyphs or layout (occasion / enduring stay book prose; node count follows Dynamics support + `graph_kind`)
- Hard dependency on CausalDynamics for basic `dagplot` / `dagplot!`
