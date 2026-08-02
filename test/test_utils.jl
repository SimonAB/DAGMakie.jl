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

    @testset "graph_from_structural_matrix" begin
        B = [
            0.0  0.0  0.0;
            0.8  0.0  0.0;
            0.5  1.2  3.0;
        ]
        g = graph_from_structural_matrix(B)
        @test nv(g) == 3
        @test ne(g) == 4
        @test has_edge(g, 1, 2)  # B[2,1]
        @test has_edge(g, 1, 3)  # B[3,1]
        @test has_edge(g, 2, 3)  # B[3,2]
        @test has_edge(g, 3, 3)  # B[3,3] self-loop
        @test ne(graph_from_structural_matrix(B; atol = 2.5)) == 3  # drops diagonal
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

    @testset "structural_edge_labels" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 3)
        B = [0.0 0.0 0.0; 0.8 0.0 0.0; 0.5 1.2 0.0]
        el = structural_edge_labels(g, B; latex = true, digits = 1)
        @test length(el) == 3
        @test el isa Vector{<:Makie.LaTeXString}
        # edges order: 1→2, 1→3, 2→3 → B[2,1], B[3,1], B[3,2]
        @test String(el[1]) == "\$0.8\$" || occursin("0.8", String(el[1]))
        plain = structural_edge_labels(g, B; latex = false, digits = 1)
        @test plain == ["0.8", "0.5", "1.2"]
        tex = structural_edge_labels(g, ["\\beta_{ZX}", "\\beta_{ZY}", "\\beta_{XY}"]; latex = true)
        @test length(tex) == 3
        @test tex[1] isa Makie.LaTeXString
        @test edge_coefficient_labels(g, B; latex = false, digits = 1) == plain
        fig, ax, p = dagplot(g; nlabels = ["Z", "X", "Y"], elabels = el, elabels_rotation = 0)
        @test fig isa Figure

        B_loop = [0.0 0.0 0.0; 0.8 0.0 0.0; 0.5 1.2 3.0]
        g_loop = graph_from_structural_matrix(B_loop)
        el_loop = structural_edge_labels(g_loop, B_loop; latex = false, digits = 1)
        @test length(el_loop) == 4
        @test "3.0" in el_loop
        fig_loop, ax_loop, p_loop = dagplot(g_loop;
            nlabels = ["Z", "X", "Y"],
            elabels = el_loop,
            elabels_rotation = 0,
        )
        @test fig_loop isa Figure
        @test p_loop[:selfedge_size][] == DAGMakie.DEFAULT_SELFEDGE_SIZE
        # Self-loop alone must not force cyclic layout (triangle preserved)
        using DAGMakie: compute_graph_layout
        lr = compute_graph_layout(g_loop)
        @test lr.kind === :acyclic
        @test length(unique(round.([pt[2] for pt in lr.positions]; digits = 3))) >= 2

        # Non-zero diagonal auto-adds missing self-loops on the caller's graph
        g_auto, _ = confounding_graph(["Z", "X", "Y"])
        @test !has_edge(g_auto, 3, 3)
        el_auto = structural_edge_labels(g_auto, B_loop; latex = false, digits = 1)
        @test has_edge(g_auto, 3, 3)
        @test length(el_auto) == 4
        @test "3.0" in el_auto
        g_off = SimpleDiGraph(3)
        add_edge!(g_off, 1, 2)
        logger = Test.TestLogger()
        Logging.with_logger(logger) do
            structural_edge_labels(g_off, B_loop; latex = false, digits = 1)
        end
        @test has_edge(g_off, 3, 3)  # diagonal still ensured
        @test any(r -> occursin("no matching edge", string(r.message)), logger.logs)
    end
end
