# DAGMakie.jl

[![CI](https://github.com/SimonAB/DAGMakie.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/SimonAB/DAGMakie.jl/actions/workflows/CI.yml)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21703327.svg)](https://doi.org/10.5281/zenodo.21703327)
[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://simonab.github.io/DAGMakie.jl/dev/)
[![codecov](https://codecov.io/gh/SimonAB/DAGMakie.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/SimonAB/DAGMakie.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

DAGMakie plots directed acyclic, directed cyclic, and mixed causal graphs with
Makie, building on [GraphMakie.jl](https://github.com/MakieOrg/GraphMakie.jl).
Defaults omit axes and grids; node types follow common causal-diagram
conventions (observed, latent, treatment, outcome), with helpers for bidirected
confounding, path highlighting, and display-only `do(·)` surgery.

**Design principles:** [DESIGN.md](DESIGN.md) · [ecosystem](DESIGN_PRINCIPLES.md)

DAGMakie is on the Julia **General** registry (`Pkg.add("DAGMakie")`). It is a
**visualisation-only** package; identification and `do(·)` calculus stay in
[CausalInference.jl](https://github.com/mschauer/CausalInference.jl) /
[CausalDynamics.jl](https://github.com/SimonAB/CausalDynamics.jl).

## Installation

```julia
using Pkg
Pkg.add("DAGMakie")
```

From the CDCS monorepo:

```julia
Pkg.develop(path="packages/DAGMakie.jl")
```

With CausalDynamics in the same project, use GraphMakie **≥0.6.6**
(CausalInference **≥0.19.4**). Book authoring may still path-develop the CDCS
GraphMakie fork for extra features (e.g. auto-label alignment) — see
[REGISTRATION.md](REGISTRATION.md#graphmakie--causaldynamics-resolve-matrix).

## Quick start

```julia
using DAGMakie, CairoMakie

# Confounding DAG Z → X → Y, Z → Y (triangle layout: confounder on top)
fig, ax, p = dagplot_confounding(["Z", "X", "Y"])

# Structural path coefficients on edges (Graphs.edges order via helper)
g, labels = confounding_graph(["Z", "X", "Y"])
B = [0.0 0.0 0.0; 0.8 0.0 0.0; 0.5 1.2 0.0]
fig, ax, p = dagplot(g;
    labels = labels,
    elabels = structural_edge_labels(g, B; digits = 1),
    elabels_rotation = 0,
)
```

![Confounding DAG](docs/images/confounding_dag.png)

Common patterns:

```julia
fig, ax, p = dagplot_chain(["X₁", "X₂", "X₃"])
fig, ax, p = dagplot_fork(["Effect₁", "Cause", "Effect₂"])
fig, ax, p = dagplot_collider(["Cause₁", "Effect", "Cause₂"])
fig, ax, p = dagplot_mediation(["Treatment", "Mediator", "Outcome"])
```

## Capabilities

- In-node white labels on steel-blue nodes by default (`label_position = :inner`);
  pass `label_position = :outer` for dagitty-style external labels
- Marker size follows label width by default (`fit_node_size_to_labels = true`)
- Prefer `labels=` for node text (`nlabels=` remains a GraphMakie-compatible alias)
- Edge labels via GraphMakie `elabels` and [`structural_edge_labels`](https://simonab.github.io/DAGMakie.jl/dev/) (numeric \(B\) or LaTeX path coefficients)
- Deterministic layered DAG layout for acyclic graphs (not a generic spring layout)
- SCC-aware cyclic layout with explicit curved feedback edges
- Themes without axes or grids (`default`, `minimal`, `bold`, `presentation`)
- Causal diagram conventions: observed, latent, treatment, outcome, bidirected confounding
- Path highlighting and `color_by = :ancestors` / `:adjustment` (dagitty-style roles;
  `smart=` is a deprecated alias; prefer `exposure=` over `treatment=`)
- Interventions: display-only `do(·)` surgery with `show_removed_edges` overlays

## Ecosystem

| Package | Role |
|---------|------|
| [CausalDynamics.jl](https://github.com/SimonAB/CausalDynamics.jl) | Graphs, identification, CDMs (plot via its DAGMakie extension) |
| [CausalTargeted.jl](https://github.com/SimonAB/CausalTargeted.jl) | Cross-fitted LMTP / interventional mediation |
| **DAGMakie** | DAG figures |
| Application repos | Cohort data, registries, concordance (thin) |

### Compared with R and Python

| Need | This package | Familiar elsewhere |
|------|--------------|--------------------|
| Layered causal DAG + bidirected arcs | Yes | ggdag, dagitty |
| Path / adjustment highlighting | Yes | ggdag + dagitty |
| Time-indexed / SWIG / DiD visual grammar | **Unique** | Custom ggplot / matplotlib |
| Same Makie stack as SciML figures | **Unique** | — |

**Choose this** when causal figures should live next to SciML and Documenter in
Julia. **Prefer ggdag / dagitty** for tidyverse-centric workflows or the dagitty
web GUI.

Full matrices: [ECOSYSTEM_COMPARISON.md](ECOSYSTEM_COMPARISON.md) ·
[Documenter comparison](https://simonab.github.io/DAGMakie.jl/dev/comparison/).

Identification algorithms live in CausalInference.jl or CausalDynamics.jl.
Pass adjustment sets / paths into `dagplot_*`, or `using CausalInference` so the
optional extension can compute a minimal backdoor set. Prefer plotting from
CausalDynamics with `using CausalDynamics, DAGMakie` when you already hold an
`IdentificationResult`.

## Path highlighting and interventions

```julia
using DAGMakie, CausalInference, CairoMakie

g, labels = confounding_graph(["Z", "X", "Y"])

fig, ax, p = dagplot_backdoor(g, 2, 3;
    adjustment = Set([1]),
    labels = labels,
)

# Display-only graph surgery (not an identification API)
fig, ax, p = dagplot_do(g, 2; labels = labels)
```

## Related packages

| Package | Role |
|---------|------|
| [CausalDynamics.jl](https://github.com/SimonAB/CausalDynamics.jl) | Graphs, identification, CDMs |
| [CausalTargeted.jl](https://github.com/SimonAB/CausalTargeted.jl) | Continuous MTP / LMTP and interventional mediation |
| [TMLE.jl](https://github.com/TARGENE/TMLE.jl) | Point-treatment TMLE / OSE (CM, ATE, AIE) |
| [CausalInference.jl](https://github.com/mschauer/CausalInference.jl) | Optional weakdep for adjustment / d-separation in plots |
| [CausalTables.jl](https://github.com/salbalkus/CausalTables.jl) | SCM-aware tables; often paired with TMLE.jl |
| [GraphMakie.jl](https://github.com/MakieOrg/GraphMakie.jl) | General graph visualisation for Makie |
| [Graphs.jl](https://github.com/JuliaGraphs/Graphs.jl) | Graph data structures |

## Documentation

- [Documenter site](https://simonab.github.io/DAGMakie.jl/dev/) — getting started, styling, bidirected edges, causal highlighting, interventions, API
- [Stress validation](https://github.com/SimonAB/CausalTargeted.jl/blob/main/STRESS.md) — Quarto notebook ([qmd](https://github.com/SimonAB/CausalTargeted.jl/blob/main/docs/stress/stress_validation.qmd)); toy identify → `dagplot`; [Documenter](https://simonab.github.io/CausalTargeted.jl/dev/stress_validation/)
- [CDCS book](https://simonab.github.io/causal-dynamics-book/) — narrative figures in context

## Roadmap

Phases 1–4 are complete (layouts, themes, bidirected edges, path highlighting,
display-only interventions, optional CausalInference extension). Remaining:

- [ ] CausalDynamics.jl package extension (deferred until CausalDynamics is on General; prefer CausalDynamics’ own DAGMakie extension today)
- [ ] Direct plotting of SCM types (`GraphSCM`, …)

## Acknowledgements

Part of the Causal Dynamics for Complex Systems (CDCS) project.
Maintainer: [Simon A. Babayan](https://orcid.org/0000-0002-4949-1117).

## License

MIT License — see [LICENSE](LICENSE).

## Citation

See [CITATION.cff](CITATION.cff) or:

```bibtex
@software{dagmakie2026,
  author = {Babayan, Simon A.},
  title  = {DAGMakie.jl: DAG visualisation for causal diagrams in Julia},
  year   = {2026},
  doi    = {10.5281/zenodo.21703327},
  url    = {https://github.com/SimonAB/DAGMakie.jl}
}
```
