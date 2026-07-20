@testset "Highlighting" begin
    @testset "HighlightSpec construction" begin
        hs = HighlightSpec()
        @test isempty(hs.nodes)
        @test isempty(hs.edges)

        hs = HighlightSpec(
            nodes = [1, 2],
            node_colors = [:red, :blue],
            edges = [(1, 2)],
            edge_colors = [:green],
        )
        @test hs.nodes == [1, 2]
        @test length(hs.edge_colors) == 1
    end

    @testset "highlight_from_path" begin
        path = CausalPath([1, 2, 3])
        hs = highlight_from_path(path, color = :red)

        @test hs.nodes == [1, 2, 3]
        @test all(c -> c == :red, hs.node_colors)
        @test (1, 2) in hs.edges
        @test (2, 3) in hs.edges
    end

    @testset "highlight_from_paths" begin
        paths = [
            CausalPath([1, 2, 4]),
            CausalPath([1, 3, 4]),
        ]
        hs = highlight_from_paths(paths)
        @test length(hs.nodes) > 0
        @test length(hs.edges) > 0
    end

    @testset "highlight_adjustment_set" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 3)

        hs = highlight_adjustment_set(g, 2, 3, Set([1]))
        @test 2 in hs.nodes
        @test 3 in hs.nodes
        @test 1 in hs.nodes
    end

    @testset "highlight_backdoor_paths from precomputed paths" begin
        paths = [CausalPath([2, 1, 3]; directions = [:backward, :forward])]
        hs = highlight_backdoor_paths(paths)
        @test !isempty(hs.edges)
        @test any(c -> c == :red, hs.edge_colors)

        hs_blocked = highlight_backdoor_paths(paths; blocked = [true])
        @test all(c -> c == :gray, hs_blocked.edge_colors)
    end

    @testset "dagplot_highlighted" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)

        path = CausalPath([1, 2, 3])
        hs = highlight_from_path(path)
        fig, ax, p = dagplot_highlighted(g, hs, nlabels = ["A", "B", "C"])
        @test fig isa Makie.Figure
    end

    @testset "dagplot_backdoor with explicit adjustment" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 3)

        fig, ax, p = dagplot_backdoor(g, 2, 3; adjustment = Set([1]), nlabels = ["Z", "X", "Y"])
        @test fig isa Makie.Figure
    end

    @testset "dagplot_adjustment requires CausalInference or adjustment=" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 3)

        fig, ax, p = dagplot_adjustment(g, 2, 3; adjustment = Set([1]))
        @test fig isa Makie.Figure
    end
end
