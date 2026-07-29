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

d-separation status for titles (pass `separated` from `dsep` / `d_separated`):

```@example causal-dsep
using Graphs, DAGMakie, CairoMakie

g, labels = confounding_graph(["Z", "X", "Y"])
# X ⊥ Y | Z in this confounding DAG
fig, ax, p = dagplot_dsep(g, 2, 3, Set([1]); separated = true, nlabels = labels)
fig
```
