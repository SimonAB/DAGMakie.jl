# Interventions (`do(·)`)

Graph surgery and intervention *plots* live in DAGMakie. `do_surgery` is
**display-only** (mutilate a DAG for figures); it is not an identification API.
For whether an effect is identifiable, and for CDM `do(·)` semantics, use
CausalInference.jl / CausalDynamics.jl (`DoIntervention`, `apply_intervention`, …).

```@example interventions
using Graphs, DAGMakie, CairoMakie

g, labels = confounding_graph(["Z", "X", "Y"])

# do(X): remove incoming edges to X
g_do = do_surgery(g, 2)
@assert !has_edge(g_do, 1, 2)
@assert has_edge(g_do, 2, 3)

fig, ax, p = dagplot_intervention(g, Intervention(2); labels = labels)
fig
```

Compare factual and intervened graphs:

```@example interventions-cmp
using Graphs, DAGMakie, CairoMakie

g, labels = confounding_graph(["Z", "X", "Y"])
fig = dagplot_do_comparison(g, 2; labels = labels)
fig
```

With `label_position=:outer`, the right-hand panel aligns labels against the
**factual** graph when `show_removed_edges=true` (default), so grey removed parent
edges still count as obstacles—matching the left panel.
