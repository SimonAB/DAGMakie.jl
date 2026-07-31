# Causal highlighting

DAGMakie highlights paths and adjustment sets that you already computed.
**Identification algorithms** live in [CausalInference.jl](https://github.com/SimonAB/CausalInference.jl)
(or [CausalDynamics.jl](https://github.com/SimonAB/CausalDynamics.jl) façades).
Pass the resulting sets into the plot helpers — the core package does not pull
CausalInference (registry CausalInference is incompatible with GraphMakie 0.6).

```@example causal
using Graphs, DAGMakie, CairoMakie

g, labels = confounding_graph(["Z", "X", "Y"])

# From CausalInference.find_min_backdoor_adjustment(g, 2, 3) — or hard-code Z
adjustment = Set([1])

fig, ax, p = dagplot_backdoor(g, 2, 3; adjustment = adjustment, nlabels = labels)
fig
```

`dagplot_adjustment` accepts an explicit set the same way:

```@example causal-auto
using Graphs, DAGMakie, CairoMakie

g, labels = confounding_graph(["Z", "X", "Y"])
fig, ax, p = dagplot_adjustment(g, 2, 3; adjustment = Set([1]), nlabels = labels)
fig
```

d-separation status for titles (pass `separated` from `dsep` / `d_separated`).
Use a **fork** ``X ← Z → Y`` (no direct ``X → Y``): conditioning on ``Z`` d-separates
``X`` and ``Y``. A confounding triangle with ``X → Y`` keeps them d-connected.

```@example causal-dsep
using Graphs, DAGMakie, CairoMakie

g, labels = fork_graph(["X", "Z", "Y"])  # X ← Z → Y
# X ⊥ Y | Z (Z blocks the only path)
fig, ax, p = dagplot_dsep(g, 1, 3, Set([2]); separated = true, nlabels = labels)
fig
```
