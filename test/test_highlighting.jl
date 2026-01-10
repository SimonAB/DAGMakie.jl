@testset "Highlighting" begin
    @testset "HighlightSpec construction" begin
        hs = HighlightSpec()
        @test isempty(hs.nodes)
        @test isempty(hs.edges)
        
        hs = HighlightSpec(
            nodes = [1, 2],
            node_colors = [:red, :blue],
            edges = [(1, 2)],
            edge_colors = [:green]
        )
        @test hs.nodes == [1, 2]
        @test length(hs.edge_colors) == 1
    end
    
    @testset "highlight_from_path" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        
        paths = find_directed_paths(g, 1, 3)
        hs = highlight_from_path(paths[1], color = :red)
        
        @test hs.nodes == [1, 2, 3]
        @test all(c -> c == :red, hs.node_colors)
        @test (1, 2) in hs.edges
        @test (2, 3) in hs.edges
    end
    
    @testset "highlight_from_paths" begin
        g = SimpleDiGraph(4)
        add_edge!(g, 1, 2)
        add_edge!(g, 1, 3)
        add_edge!(g, 2, 4)
        add_edge!(g, 3, 4)
        
        paths = find_directed_paths(g, 1, 4)
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
        
        @test 2 in hs.nodes  # treatment
        @test 3 in hs.nodes  # outcome
        @test 1 in hs.nodes  # adjustment
    end
    
    @testset "highlight_backdoor_paths" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 3)
        
        # Without adjustment - should have open path
        hs = highlight_backdoor_paths(g, 2, 3)
        @test !isempty(hs.edges)
        @test any(c -> c == :red, hs.edge_colors)  # open path in red
        
        # With adjustment - should be blocked
        hs = highlight_backdoor_paths(g, 2, 3, adjustment = Set([1]))
        @test !isempty(hs.edges)
        @test all(c -> c == :gray, hs.edge_colors)  # all blocked
    end
    
    @testset "dagplot_highlighted" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        
        paths = find_directed_paths(g, 1, 3)
        hs = highlight_from_path(paths[1])
        
        fig, ax, p = dagplot_highlighted(g, hs, nlabels = ["A", "B", "C"])
        @test fig isa Makie.Figure
    end
    
    @testset "dagplot_backdoor" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 3)
        
        fig, ax, p = dagplot_backdoor(g, 2, 3, nlabels = ["Z", "X", "Y"])
        @test fig isa Makie.Figure
        
        # With adjustment
        fig, ax, p = dagplot_backdoor(g, 2, 3, 
            adjustment = Set([1]),
            nlabels = ["Z", "X", "Y"]
        )
        @test fig isa Makie.Figure
    end
    
    @testset "dagplot_dsep" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 2, 1)
        add_edge!(g, 2, 3)
        
        fig, ax, p = dagplot_dsep(g, 1, 3, Set([2]), nlabels = ["X", "Z", "Y"])
        @test fig isa Makie.Figure
        @test contains(ax.title[], "d-separated")
        
        fig, ax, p = dagplot_dsep(g, 1, 3, Set{Int}(), nlabels = ["X", "Z", "Y"])
        @test contains(ax.title[], "d-connected")
    end
    
    @testset "dagplot_causal_paths" begin
        g = SimpleDiGraph(4)
        add_edge!(g, 1, 2)
        add_edge!(g, 1, 3)
        add_edge!(g, 2, 4)
        add_edge!(g, 3, 4)
        
        fig, ax, p = dagplot_causal_paths(g, 1, 4, nlabels = ["A", "B", "C", "D"])
        @test fig isa Makie.Figure
    end
    
    @testset "dagplot_adjustment" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 3)
        
        fig, ax, p = dagplot_adjustment(g, 2, 3, nlabels = ["Z", "X", "Y"])
        @test fig isa Makie.Figure
    end
    
    @testset "No backdoor paths" begin
        # Simple chain - no backdoor
        g = SimpleDiGraph(2)
        add_edge!(g, 1, 2)
        
        fig, ax, p = dagplot_backdoor(g, 1, 2, nlabels = ["X", "Y"])
        @test fig isa Makie.Figure
    end
end
