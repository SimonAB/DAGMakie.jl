# SPDX-License-Identifier: MIT

using Makie: Point2f, Figure
using Graphs: SimpleGraph, SimpleDiGraph, add_edge!, ne, has_edge, is_directed

@testset "time-indexed layout and skeleton" begin
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
