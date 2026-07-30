# SPDX-License-Identifier: MIT

using CairoMakie
using DAGMakie

"""
    benchmark_fixture_graphs()

Create representative acyclic, cyclic, and mixed graphs for layout timing.
"""
function benchmark_fixture_graphs()
    dag = SimpleDiGraph(12)
    for (source, destination) in [
        (1, 4), (1, 5), (2, 5), (2, 6), (3, 6),
        (4, 7), (5, 7), (5, 8), (6, 8),
        (7, 9), (8, 10), (9, 11), (10, 11), (11, 12),
    ]
        add_edge!(dag, source, destination)
    end

    cyclic = SimpleDiGraph(10)
    for (source, destination) in [
        (1, 2), (2, 3), (3, 1),
        (3, 4), (4, 5), (5, 6), (6, 4),
        (6, 7), (7, 8), (8, 9), (9, 10),
    ]
        add_edge!(cyclic, source, destination)
    end

    mixed = mixed_graph(
        10,
        [(1, 4), (2, 4), (4, 6), (3, 5), (5, 6), (6, 8), (7, 8), (8, 10), (9, 10)],
        [(2, 3), (6, 7)],
    )

    return (
        dag = dag,
        cyclic = cyclic,
        mixed = mixed,
    )
end

"""
    benchmark_operation(f; repeats=5)

Run a small repeated timing loop and return summary statistics in milliseconds.
"""
function benchmark_operation(f; repeats::Int = 5)
    timings_ms = Float64[]

    f()
    GC.gc()

    for _ in 1:repeats
        GC.gc()
        elapsed = @elapsed f()
        push!(timings_ms, 1_000 * elapsed)
    end

    return (
        minimum_ms = minimum(timings_ms),
        mean_ms = sum(timings_ms) / length(timings_ms),
        maximum_ms = maximum(timings_ms),
    )
end

"""
    run_layout_benchmarks(; repeats=5)

Print a simple timing summary for layout resolution and figure construction.
"""
function run_layout_benchmarks(; repeats::Int = 5)
    CairoMakie.activate!(type = "png")
    fixtures = benchmark_fixture_graphs()

    println("layout benchmarks (milliseconds)")
    println()

    for (name, graph) in pairs(fixtures)
        layout_stats = benchmark_operation(; repeats = repeats) do
            compute_graph_layout(graph)
        end

        render_stats = benchmark_operation(; repeats = repeats) do
            dagplot(graph)
        end

        println("$(name)")
        println("  layout: min=$(round(layout_stats.minimum_ms; digits = 1)) mean=$(round(layout_stats.mean_ms; digits = 1)) max=$(round(layout_stats.maximum_ms; digits = 1))")
        println("  render: min=$(round(render_stats.minimum_ms; digits = 1)) mean=$(round(render_stats.mean_ms; digits = 1)) max=$(round(render_stats.maximum_ms; digits = 1))")
    end

    return nothing
end
