# SPDX-License-Identifier: MIT

using Makie: Point2f

@testset "Utilities" begin
    @testset "is_dag" begin
        # Acyclic graph
        g1 = SimpleDiGraph(3)
        add_edge!(g1, 1, 2)
        add_edge!(g1, 2, 3)
        @test is_dag(g1) == true
        
        # Cyclic graph
        g2 = SimpleDiGraph(3)
        add_edge!(g2, 1, 2)
        add_edge!(g2, 2, 3)
        add_edge!(g2, 3, 1)
        @test is_dag(g2) == false
    end
    
    @testset "edge_list" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        
        edges = edge_list(g)
        @test length(edges) == 2
        @test (1, 2) in edges
        @test (2, 3) in edges
    end
    
    @testset "adjacency_to_graph" begin
        adj = [0 1 0; 0 0 1; 0 0 0]
        g = adjacency_to_graph(adj)
        
        @test nv(g) == 3
        @test ne(g) == 2
        @test has_edge(g, 1, 2)
        @test has_edge(g, 2, 3)
        @test !has_edge(g, 1, 3)
    end
    
    @testset "graph_from_edges" begin
        g = graph_from_edges(4, [(1, 2), (2, 3), (3, 4)])
        
        @test nv(g) == 4
        @test ne(g) == 3
        @test has_edge(g, 1, 2)
        @test has_edge(g, 2, 3)
        @test has_edge(g, 3, 4)
    end
    
    @testset "graph_extent" begin
        positions = [Point2f(0, 0), Point2f(2, 1), Point2f(1, 3)]
        ext = graph_extent(positions)
        
        @test ext.x_min == 0
        @test ext.x_max == 2
        @test ext.y_min == 0
        @test ext.y_max == 3
        @test ext.x_range == 2
        @test ext.y_range == 3
    end
    
    @testset "Pattern graphs" begin
        # Chain
        g, labels = chain_graph(["A", "B", "C"])
        @test nv(g) == 3
        @test ne(g) == 2
        @test has_edge(g, 1, 2)
        @test has_edge(g, 2, 3)
        
        # Fork
        g, labels = fork_graph(["L", "F", "R"])
        @test nv(g) == 3
        @test ne(g) == 2
        @test has_edge(g, 2, 1)  # Fork → Left
        @test has_edge(g, 2, 3)  # Fork → Right
        
        # Collider
        g, labels = collider_graph(["L", "C", "R"])
        @test nv(g) == 3
        @test ne(g) == 2
        @test has_edge(g, 1, 2)  # Left → Collider
        @test has_edge(g, 3, 2)  # Right → Collider
        
        # Confounding
        g, labels = confounding_graph(["Z", "X", "Y"])
        @test nv(g) == 3
        @test ne(g) == 3
        @test has_edge(g, 1, 2)  # Z → X
        @test has_edge(g, 1, 3)  # Z → Y
        @test has_edge(g, 2, 3)  # X → Y
        
        # Mediation
        g, labels = mediation_graph(["X", "M", "Y"])
        @test nv(g) == 3
        @test ne(g) == 3
        @test has_edge(g, 1, 2)  # X → M
        @test has_edge(g, 2, 3)  # M → Y
        @test has_edge(g, 1, 3)  # X → Y (direct)
        
        # Instrumental
        g, labels = instrumental_graph(["Z", "X", "Y", "U"])
        @test nv(g) == 4
        @test ne(g) == 4
        @test has_edge(g, 1, 2)  # Z → X
        @test has_edge(g, 2, 3)  # X → Y
        @test has_edge(g, 4, 2)  # U → X
        @test has_edge(g, 4, 3)  # U → Y
    end
end
