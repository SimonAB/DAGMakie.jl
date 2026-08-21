# SPDX-License-Identifier: MIT

"""
Optional performance budgets. Enabled with `DAGMAKIE_PERF=1`.

Default CI stays fast; local soak:

```
DAGMAKIE_PERF=1 julia --project=. -e 'using Pkg; Pkg.test()'
```
"""

if get(ENV, "DAGMAKIE_PERF", "") == "1"
    @testset "Layout performance budgets" begin
        include("benchmark_layouts.jl")
        fixtures = benchmark_fixture_graphs()
        dag = fixtures.dag

        layout_stats = benchmark_operation(; repeats = 5) do
            compute_graph_layout(dag)
        end
        @test layout_stats.mean_ms < 80

        render_stats = benchmark_operation(; repeats = 3) do
            dagplot(dag)
        end
        # First render pays Makie compile; subsequent calls are cheaper.
        # Budget is intentionally soft for CI/hardware variance.
        @test render_stats.mean_ms < 2500
    end
end
