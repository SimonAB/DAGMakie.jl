# Causal highlighting

DAGMakie highlights paths and adjustment sets that you already computed.
**Identification algorithms** live in [CausalInference.jl](https://github.com/SimonAB/CausalInference.jl)
(or [CausalDynamics.jl](https://github.com/SimonAB/CausalDynamics.jl) façades).

```@example causal
using Graphs, DAGMakie, CairoMakie, CausalInference

g, labels = confounding_graph(["Z", "X", "Y"])

# Compute with CausalInference, then plot
adj = find_min_backdoor_adjustment(g, 2, 3)
adjustment = adj === false ? Set{Int}() : Set{Int}(adj)

fig, ax, p = dagplot_backdoor(g, 2, 3; adjustment = adjustment, nlabels = labels)
fig
```

With `using CausalInference`, `dagplot_adjustment` can compute a minimal
backdoor set for you via the package extension:

```@example causal-auto
using Graphs, DAGMakie, CairoMakie, CausalInference

g, labels = confounding_graph(["Z", "X", "Y"])
fig, ax, p = dagplot_adjustment(g, 2, 3; nlabels = labels)
fig
```

d-separation status for titles:

```@example causal-dsep
using Graphs, DAGMakie, CairoMakie, CausalInference

g, labels = confounding_graph(["Z", "X", "Y"])
fig, ax, p = dagplot_dsep(g, 2, 3, Set([1]); nlabels = labels)
fig
```
