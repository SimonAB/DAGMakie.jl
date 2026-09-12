# SPDX-License-Identifier: MIT

using Makie: Point2f, Figure
using Graphs: SimpleGraph, SimpleDiGraph, add_edge!, ne, has_edge, is_directed

@testset "time-indexed layout and skeleton" begin
    @testset "mixed temporal layout" begin
        keys = [(:diagnosis, 0), (:pasture, nothing), (:weight, 0), (:weight, 1)]
        positions = temporal_layout(
            keys;
            onset_times = [0, 1, 0, 0],
            dx = 2.0,
            dy = 1.5,
        )

        @test positions[1] == Point2f(0, 0)
        @test positions[2] == Point2f(2, -1.5)
        @test positions[3] == Point2f(0, -3.0)
        @test positions[4] == Point2f(2, -3.0)
        @test interval_summary_node_marker() isa Makie.BezierPath
        @test_throws ArgumentError temporal_layout(keys; onset_times = [0, 1])
        @test_throws ArgumentError temporal_layout([(:x, 0.5)])

        g_mixed = SimpleDiGraph(4)
        add_edge!(g_mixed, 1, 2)
        add_edge!(g_mixed, 1, 3)
        add_edge!(g_mixed, 2, 4)
        fig_mixed, _ax_mixed, p_mixed = dagplot_temporal(
            g_mixed,
            keys;
            onset_times = [0, 1, 0, 0],
            nlabels = ["diagnosis[0]", "pasture", "weight[0]", "weight[1]"],
        )
        @test fig_mixed isa Figure
        @test p_mixed[:node_marker][][2] === :circle
        @test all(m === :circle for m in p_mixed[:node_marker][])
    end

    @testset "declared value representation controls marker" begin
        g_summary = SimpleDiGraph(1)
        fig_summary, _ax_summary, p_summary = dagplot_temporal(
            g_summary,
            [(:burden_summary, 0)];
            temporal_supports = [:pointwise],
            value_representations = [:interval_summary],
            nlabels = ["burden summary"],
        )
        @test fig_summary isa Figure
        @test p_summary[:node_marker][][1] == interval_summary_node_marker()

        _fig_support, _ax_support, p_support = dagplot_temporal(
            g_summary,
            [(:burden, 0)];
            temporal_supports = [:from_onset],
            value_representations = [:unspecified],
            nlabels = ["burden"],
        )
        @test p_support[:node_marker][][1] === :circle

        _fig_attr, _ax_attr, p_attr = dagplot_temporal(
            g_summary,
            [(:pasture, nothing)];
            onset_times = [1],
            value_representations = [:attribute],
            nlabels = ["pasture"],
        )
        @test p_attr[:node_marker][][1] === :circle
    end

    pts = time_indexed_layout(2, 3; dx = 2.0, dy = 1.5)
    @test length(pts) == 6
    @test pts[1] == Point2f(0, 0)
    @test pts[2] == Point2f(0, -1.5)  # var 2 at t=1
    @test pts[3] == Point2f(2, 0)     # var 1 at t=2

    g = SimpleDiGraph(4)
    add_edge!(g, 1, 2)
    add_edge!(g, 2, 1)
    add_edge!(g, 1, 3)
    sk = digraph_skeleton(g)
    @test sk isa SimpleGraph
    @test ne(sk) == 2
    @test has_edge(sk, 1, 2)
    @test has_edge(sk, 1, 3)

    fig_sk, ax_sk, p_sk = dagplot(sk;
        layout = Point2f[Point2f(0, 1), Point2f(-1, 0), Point2f(1, 0), Point2f(2, 0)],
        nlabels = ["1", "2", "3", "4"],
    )
    @test fig_sk isa Figure

    # Auto layout must not call directed-only Algorithms on SimpleGraph
    fig_auto, ax_auto, p_auto = dagplot(sk; layout_mode = :acyclic, nlabels = ["1", "2", "3", "4"])
    @test fig_auto isa Figure
    fig_spring, ax_spring, p_spring = dagplot(sk; layout_mode = :spring, nlabels = ["1", "2", "3", "4"])
    @test fig_spring isa Figure

    fig_sk2, ax_sk2, p_sk2 = dagplot_skeleton(g;
        layout = Point2f[Point2f(0, 1), Point2f(-1, 0), Point2f(1, 0), Point2f(2, 0)],
        nlabels = ["1", "2", "3", "4"],
    )
    @test fig_sk2 isa Figure
    @test !is_directed(digraph_skeleton(g))

    u = SimpleDiGraph(4)
    add_edge!(u, 1, 3)
    add_edge!(u, 2, 4)
    fig, ax, p = dagplot_time_indexed(u, 2, 2; nlabels = ["a1", "b1", "a2", "b2"])
    @test fig isa Figure
end
