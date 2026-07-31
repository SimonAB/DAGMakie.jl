# SPDX-License-Identifier: MIT

using Makie: Point2f

@testset "Bidirected Edges" begin
    @testset "MixedGraph construction" begin
        # Empty graph
        mg = MixedGraph(3)
        @test nv(mg) == 3
        @test ne(mg) == 0
        @test num_bidirected_edges(mg) == 0
        
        # From directed graph
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        mg = MixedGraph(g)
        @test nv(mg) == 3
        @test ne(mg) == 2
        @test num_bidirected_edges(mg) == 0
        
        # With bidirected edges
        mg = MixedGraph(g, [(1, 3)])
        @test num_bidirected_edges(mg) == 1
        @test has_bidirected_edge(mg, 1, 3)
        @test has_bidirected_edge(mg, 3, 1)  # Symmetric
    end
    
    @testset "Edge manipulation" begin
        mg = MixedGraph(3)
        
        # Add directed edge
        add_directed_edge!(mg, 1, 2)
        @test has_edge(mg, 1, 2)
        @test !has_edge(mg, 2, 1)
        
        # Add bidirected edge
        add_bidirected_edge!(mg, 1, 3)
        @test has_bidirected_edge(mg, 1, 3)
        @test has_bidirected_edge(mg, 3, 1)
        @test !has_bidirected_edge(mg, 1, 2)
        
        # Bidirected edges iterator
        bi_edges = collect(bidirected_edges(mg))
        @test length(bi_edges) == 1
        @test (1, 3) in bi_edges || (3, 1) in bi_edges
    end
    
    @testset "mixed_graph constructor" begin
        mg = mixed_graph(3, [(1, 2), (2, 3)], [(1, 3)])
        @test nv(mg) == 3
        @test ne(mg) == 2
        @test has_edge(mg, 1, 2)
        @test has_edge(mg, 2, 3)
        @test has_bidirected_edge(mg, 1, 3)
    end
    
    @testset "Bidirected path computation" begin
        p1 = Point2f(0, 0)
        p2 = Point2f(2, 0)
        
        path = compute_bidirected_path(p1, p2; curvature = 0.3)
        
        @test length(path) > 2
        @test path[1] ≈ p1
        @test path[end] ≈ p2
        
        # Path should curve above the line
        mid_idx = div(length(path), 2)
        @test path[mid_idx][2] > 0  # y > 0 for positive curvature
    end
    
    @testset "All bidirected paths" begin
        mg = mixed_graph(3, [(1, 2)], [(1, 3), (2, 3)])
        positions = [Point2f(0, 0), Point2f(1, 0), Point2f(0.5, 1)]
        
        paths = compute_all_bidirected_paths(mg, positions)
        @test length(paths) == 2
        @test all(p -> length(p) > 2, paths)
    end
    
    @testset "Arrow positions" begin
        mg = mixed_graph(2, [], [(1, 2)])
        positions = [Point2f(0, 0), Point2f(2, 0)]
        
        arrows = bidirected_arrow_positions(mg, positions)
        
        # Should have 2 arrows (one at each end)
        @test length(arrows.positions) == 2
        @test length(arrows.rotations) == 2
        @test length(arrows.edge_indices) == 2
    end

    @testset "Boundary-aware bidirected geometry" begin
        mg = mixed_graph(2, [], [(1, 2)])
        positions = [Point2f(0, 0), Point2f(2, 0)]
        fig, ax, p = dagplot(mg.directed; layout = positions, node_size = 20)

        geometry = DAGMakie.compute_bidirected_geometry(
            mg,
            positions,
            fill(:circle, 2),
            fill(20, 2),
            DAGMakie._plot_to_px(p);
            curvature = 0.3,
            arrow_size = 8,
        )

        @test length(geometry.paths) == 1
        @test first(geometry.paths[1]) != positions[1]
        @test last(geometry.paths[1]) != positions[2]
        @test length(geometry.arrow_positions) == 2
    end
    
    @testset "Pattern graphs" begin
        # Confounded
        mg, labels = confounded_graph(["X", "Y"])
        @test nv(mg) == 2
        @test ne(mg) == 1
        @test has_edge(mg, 1, 2)
        @test has_bidirected_edge(mg, 1, 2)
        
        # Frontdoor
        mg, labels = frontdoor_graph(["X", "M", "Y"])
        @test nv(mg) == 3
        @test has_edge(mg, 1, 2)
        @test has_edge(mg, 2, 3)
        @test has_bidirected_edge(mg, 1, 3)
        
        # IV confounded
        mg, labels = iv_confounded_graph(["Z", "X", "Y"])
        @test nv(mg) == 3
        @test has_edge(mg, 1, 2)
        @test has_edge(mg, 2, 3)
        @test has_bidirected_edge(mg, 2, 3)
        
        # M-bias (five-node form with explicit latents)
        mg, labels = m_bias_graph()
        @test nv(mg) == 5
        @test labels == ["U₁", "U₂", "X", "M", "Y"]
        @test has_edge(mg, 1, 3)  # U₁ → X
        @test has_edge(mg, 1, 4)  # U₁ → M
        @test has_edge(mg, 2, 4)  # U₂ → M
        @test has_edge(mg, 2, 5)  # U₂ → Y
        @test !has_edge(mg, 3, 5)  # no X → Y
        @test num_bidirected_edges(mg) == 0
        spec = m_bias_spec()
        @test length(spec.nodes) == 5
        @test spec.nodes[1].type == Latent
        @test spec.nodes[4].type == Collider
    end
    
    @testset "dagplot with MixedGraph" begin
        mg = mixed_graph(3, [(1, 2), (2, 3)], [(1, 3)])
        
        # Should create figure without error
        fig, ax, p = dagplot(mg, nlabels = ["X", "Y", "Z"])
        @test fig isa Makie.Figure
        
        # With custom bidirected styling
        fig, ax, p = dagplot(mg,
            nlabels = ["A", "B", "C"],
            bidirected_color = :red,
            bidirected_width = 2.0,
            bidirected_style = :dot
        )
        @test fig isa Makie.Figure
    end
    
    @testset "Convenience plotting functions" begin
        # dagplot_confounded
        fig, ax, p = dagplot_confounded(["Treatment", "Outcome"])
        @test fig isa Makie.Figure
        positions = p[:node_pos][]
        @test length(unique(round.([pt[1] for pt in positions]; digits = 3))) >= 2
        
        # dagplot_frontdoor
        fig, ax, p = dagplot_frontdoor(["X", "M", "Y"])
        @test fig isa Makie.Figure
        positions = p[:node_pos][]
        @test length(unique(round.([pt[2] for pt in positions]; digits = 3))) >= 2
        
        # dagplot_iv_confounded
        fig, ax, p = dagplot_iv_confounded(["Z", "X", "Y"])
        @test fig isa Makie.Figure
        positions = p[:node_pos][]
        @test length(unique(round.([pt[2] for pt in positions]; digits = 3))) >= 2
        
        # dagplot_m_bias
        fig, ax, p = dagplot_m_bias()
        @test fig isa Makie.Figure
        positions = p[:node_pos][]
        @test length(positions) == 5
        @test length(unique(round.([pt[2] for pt in positions]; digits = 3))) >= 2
    end
end
