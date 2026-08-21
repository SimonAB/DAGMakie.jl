# Output quality

DAGMakie aims for notebook-scale causal diagrams (roughly 5–200 labelled nodes)
that read closer to Graphviz `dot` / dagitty than to a generic spring layout.

## Defaults

- `layout_mode = :auto` — layered for DAGs; SCC-aware for cyclic digraphs
- `:spring` — explicit NetworkLayout fallback
- Pass `layout = …` for fixed positions or another NetworkLayout algorithm
- `dagplot_do_comparison` / intervention helpers reuse a shared
  [`DAGLayoutResult`](@ref)

## Robustness features

- Long-range forward edges that skim intermediate nodes receive a sideways
  quadratic Bézier samples (`long_edge_routing = :quadratic`), so skip chords
  do not draw through nodes; other styles include `:natural_cubic`, `:none`,
  `:rounded`, `:tangents`, `:curve_distance`
- Feedback edges inside an SCC use curved overlays with boundary-aware arrowheads
- Bidirected confounding arcs are clipped to node markers
- Axis limits include markers, labels, and overlay waypoints
- Highlight specs use **first listing wins** when the same node or edge is
  repeated (put exposure / outcome / adjustment before path colours)

## Checks

- Geometry regressions live in `test/test_layout.jl`, `test/test_interventions.jl`,
  and `test/test_highlighting.jl`
- Optional timing budgets: set `DAGMAKIE_PERF=1` when running the test suite
  (see `test/test_perf.jl`)
- Manual timing gallery: `julia --project=. test/benchmark_layouts.jl`

## Non-goals

- No hard Graphviz dependency (optional local `dot` comparison is fine in scripts)
- Not a WebGL explorer for huge graphs
