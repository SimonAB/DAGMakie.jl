# SPDX-License-Identifier: MIT

@testset "DAG Plotting" begin
    @testset "dagplot basic" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        
        # Should create figure without error
        fig, ax, p = dagplot(g)
        @test fig isa Makie.Figure
        @test ax isa Makie.Axis
        
        # With labels
        fig, ax, p = dagplot(g, labels =["X", "Y", "Z"])
        @test fig isa Makie.Figure
        
        # Check node positions are accessible
        positions = p[:node_pos][]
        @test length(positions) == 3
    end
    
    @testset "dagplot with options" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        
        # Custom styling
        fig, ax, p = dagplot(g,
            labels = ["A", "B", "C"],
            node_color = :lightgreen,
            node_size = 20,
            edge_color = :darkgray,
            nlabels_fontsize = 16
        )
        @test fig isa Makie.Figure
        
        # Per-node colours
        fig, ax, p = dagplot(g,
            labels = ["A", "B", "C"],
            node_color = [:red, :green, :blue]
        )
        @test fig isa Makie.Figure
    end
    
    @testset "dagplot! into existing axis" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        
        fig = Figure()
        ax = Axis(fig[1, 1])
        
        p = dagplot!(ax, g, labels =["X", "Y", "Z"])
        
        # Axis should have DAG theme applied
        @test ax.aspect[] isa Makie.DataAspect
    end
    
    @testset "dagplot with DAGSpec" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        
        spec = DAGSpec(g,
            node_labels = ["Treatment", "Mediator", "Outcome"],
            node_types = [Treatment, Mediator, Outcome]
        )
        
        fig, ax, p = dagplot(spec)
        @test fig isa Makie.Figure
    end

    @testset "automatic layout strategy" begin
        g = SimpleDiGraph(6)
        add_edge!(g, 1, 3)
        add_edge!(g, 2, 3)
        add_edge!(g, 3, 4)
        add_edge!(g, 3, 5)
        add_edge!(g, 5, 6)

        result = compute_graph_layout(g)
        @test result.kind == :acyclic
        @test all(result.positions[src(edge)][1] < result.positions[dst(edge)][1] for edge in edges(g))

        cyclic = SimpleDiGraph(4)
        add_edge!(cyclic, 1, 2)
        add_edge!(cyclic, 2, 1)
        add_edge!(cyclic, 2, 3)
        add_edge!(cyclic, 3, 4)

        cyclic_result = compute_graph_layout(cyclic)
        @test cyclic_result.kind == :cyclic
        @test Set(cyclic_result.feedback_edges) == Set([(1, 2), (2, 1)])
        @test haskey(cyclic_result.edge_waypoints, (1, 2))
        @test haskey(cyclic_result.edge_waypoints, (2, 1))
        # Opposing arcs of a 2-cycle must bow opposite ways
        wp12 = only(cyclic_result.edge_waypoints[(1, 2)])
        wp21 = only(cyclic_result.edge_waypoints[(2, 1)])
        mid = (cyclic_result.positions[1] + cyclic_result.positions[2]) / 2
        @test (wp12 - mid) ≈ -(wp21 - mid)
    end

    @testset "feedback overlay geometry" begin
        edge_pairs = [(1, 2)]
        positions = [Makie.Point2f(-1, 0), Makie.Point2f(1, 0)]
        fig, ax, p = dagplot(
            graph_from_edges(2, edge_pairs);
            layout = positions,
            node_size = 20,
        )

        geometry = DAGMakie.compute_feedback_geometry(
            edge_pairs,
            positions,
            fill(:circle, 2),
            fill(20, 2),
            [[Makie.Point2f(0, 1.4)]],
            DAGMakie._plot_to_px(p);
            arrow_size = [10],
            arrow_shift = [:end],
        )

        path = only(geometry.paths)
        @test length(path) > 10
        @test first(path) != positions[1]
        @test last(path) != positions[2]
        @test maximum(point[2] for point in path) > 0.6
        @test only(geometry.arrow_positions) == last(path)
    end

    @testset "feedback geometry with oval (tuple) node sizes" begin
        # General GraphMakie 0.6.6 cannot multiply by `(w, h)`; DAGMakie must
        # pass a scalar extent. Regression for removed-edge / feedback overlays.
        edge_pairs = [(1, 2)]
        positions = [Makie.Point2f(-1, 0), Makie.Point2f(1, 0)]
        fig, ax, p = dagplot(
            graph_from_edges(2, edge_pairs);
            layout = positions,
            node_size = 20,
        )
        geometry = DAGMakie.compute_feedback_geometry(
            edge_pairs,
            positions,
            Any[Makie.Circle, :circle],
            Any[(40.0, 24.0), 20],
            [[Makie.Point2f(0, 1.4)]],
            DAGMakie._plot_to_px(p);
            arrow_size = [10],
            arrow_shift = [:end],
        )
        @test length(only(geometry.paths)) >= 2
        @test length(geometry.arrow_positions) == 1
    end

    @testset "dagplot with fully styled DAGSpec" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)

        nodes = [
            NodeSpec("Instrument"; type = Instrument, marker = :diamond, color = :pink, size = 18),
            NodeSpec("Treatment"; type = Treatment),
            NodeSpec("Outcome"; type = Outcome),
        ]
        edges = [EdgeSpec(1, 2; color = :red, width = 2.5, style = :dash)]
        spec = DAGSpec(g, nodes, edges, "Styled DAG")

        fig, ax, p = dagplot(spec)
        @test fig isa Makie.Figure
        @test ax.title[] == "Styled DAG"
        @test p[:node_marker][][1] == :diamond
        @test p[:edge_color][][1] == :red
        @test p[:edge_linestyle][][1] == :dash
    end
    
    @testset "Convenience pattern functions" begin
        # Chain
        fig, ax, p = dagplot_chain(["A", "B", "C"])
        @test fig isa Makie.Figure
        
        # Fork
        fig, ax, p = dagplot_fork(["L", "F", "R"])
        @test fig isa Makie.Figure
        
        # Collider
        fig, ax, p = dagplot_collider(["L", "C", "R"])
        @test fig isa Makie.Figure
        
        # Confounding (triangle layout: confounder above treatment/outcome)
        fig, ax, p = dagplot_confounding(["Z", "X", "Y"])
        @test fig isa Makie.Figure
        positions = p[:node_pos][]
        @test length(unique(round.([pt[2] for pt in positions]; digits = 3))) >= 2
        
        # Mediation (triangle layout: mediator above treatment/outcome)
        fig, ax, p = dagplot_mediation(["X", "M", "Y"])
        @test fig isa Makie.Figure
        positions = p[:node_pos][]
        @test length(unique(round.([pt[2] for pt in positions]; digits = 3))) >= 2
    end
    
    @testset "default outer labels" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)

        fig, ax, p = dagplot(g; labels = ["X", "Y", "Z"])
        @test fig isa Makie.Figure
        @test p[:nlabels_distance][] == OUTER_LABEL_DISTANCE
        @test p[:nlabels_color][] == OUTER_LABEL_COLOR
        @test all(==(OUTER_LABEL_NODE_SIZE), p[:node_size][])
    end

    @testset "label_position option" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)

        fig1, ax1, p1 = dagplot(g,
            labels = ["X", "Y", "Z"],
            label_position = :outer,
        )
        @test fig1 isa Makie.Figure
        aligns_auto = p1[:nlabels_align][]
        @test aligns_auto isa AbstractVector
        @test length(aligns_auto) == 3
        @test aligns_auto != fill((:center, :center), 3)

        # Inner labels: explicit alignment is preserved
        fig2, ax2, p2 = dagplot(g,
            labels = ["X", "Y", "Z"],
            label_position = :inner,
            nlabels_align = (:left, :bottom)
        )
        @test fig2 isa Makie.Figure
        aligns_manual = p2[:nlabels_align][]
        if aligns_manual isa AbstractVector
            @test all(a -> a == (:left, :bottom), aligns_manual)
        else
            @test aligns_manual == (:left, :bottom)
        end
    end

    @testset "outside labels need non-centred align" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)

        fig, ax, p = dagplot(g;
            labels = ["X", "Y", "Z"],
            label_position = :inner,
            nlabels_color = :black,
            nlabels_distance = 12,
            nlabels_align = (:center, :bottom),
        )
        @test fig isa Makie.Figure
        @test p[:nlabels_distance][] == 12
        @test p[:nlabels_align][] == (:center, :bottom)
        @test p[:nlabels_offset_processed][] == Point2f(0, 12)

        # Centred align + positive distance is a GraphMakie no-op (and warns)
        logger = Test.TestLogger()
        Logging.with_logger(logger) do
            fig2, ax2, p2 = dagplot(g;
                labels = ["X", "Y", "Z"],
                label_position = :inner,
                nlabels_distance = 12,
            )
            @test p2[:nlabels_offset_processed][] == Point2f(0, 0)
            @test any(
                r -> r.level == Logging.Warn && occursin("nlabels_distance", string(r.message)),
                logger.logs,
            )
        end
    end
    
    @testset "Themes" begin
        theme = dag_theme()
        @test theme isa Makie.Theme
        
        # Style presets
        @test default_style() isa DAGStyle
        @test minimal_style() isa DAGStyle
        @test bold_style() isa DAGStyle
        @test presentation_style() isa DAGStyle
    end
    
    @testset "Multiple DAGs in one figure" begin
        g1 = SimpleDiGraph(3)
        add_edge!(g1, 1, 2)
        add_edge!(g1, 2, 3)
        
        g2 = SimpleDiGraph(3)
        add_edge!(g2, 2, 1)
        add_edge!(g2, 2, 3)
        
        fig = Figure(size = (800, 400))
        ax1 = Axis(fig[1, 1], title = "Chain")
        ax2 = Axis(fig[1, 2], title = "Fork")
        
        dagplot!(ax1, g1, labels = ["A", "B", "C"])
        dagplot!(ax2, g2, labels = ["X", "Y", "Z"])
        
        @test fig isa Makie.Figure
    end
end
