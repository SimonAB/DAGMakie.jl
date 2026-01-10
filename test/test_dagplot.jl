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
        fig, ax, p = dagplot(g, nlabels=["X", "Y", "Z"])
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
            nlabels = ["A", "B", "C"],
            node_color = :lightgreen,
            node_size = 20,
            edge_color = :darkgray,
            nlabels_fontsize = 16
        )
        @test fig isa Makie.Figure
        
        # Per-node colours
        fig, ax, p = dagplot(g,
            nlabels = ["A", "B", "C"],
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
        
        p = dagplot!(ax, g, nlabels=["X", "Y", "Z"])
        
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
        
        # Confounding
        fig, ax, p = dagplot_confounding(["Z", "X", "Y"])
        @test fig isa Makie.Figure
        
        # Mediation
        fig, ax, p = dagplot_mediation(["X", "M", "Y"])
        @test fig isa Makie.Figure
    end
    
    @testset "auto_align_labels option" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        
        # With auto-align (default)
        fig1, ax1, p1 = dagplot(g, 
            nlabels = ["X", "Y", "Z"],
            auto_align_labels = true
        )
        @test fig1 isa Makie.Figure
        
        # Without auto-align
        fig2, ax2, p2 = dagplot(g,
            nlabels = ["X", "Y", "Z"],
            auto_align_labels = false,
            nlabels_align = (:left, :bottom)
        )
        @test fig2 isa Makie.Figure
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
        
        dagplot!(ax1, g1, nlabels = ["A", "B", "C"])
        dagplot!(ax2, g2, nlabels = ["X", "Y", "Z"])
        
        @test fig isa Makie.Figure
    end
end
