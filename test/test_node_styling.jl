# SPDX-License-Identifier: MIT

@testset "Node Type Styling" begin
    @testset "Individual styling functions" begin
        # Markers
        @test node_type_marker(Observed) == :circle
        @test node_type_marker(Latent) == :circle
        @test node_type_marker(Instrument) == :diamond
        
        # Colours (in-node white-label palette)
        @test node_type_color(Observed) == DEFAULT_NODE_COLOR
        @test node_type_color(Confounder) == NODE_COLOR_CONFOUNDER
        @test node_type_color(Mediator) == NODE_COLOR_MEDIATOR
        @test node_type_color(Treatment) == DEFAULT_NODE_COLOR
        @test node_type_color(Outcome) == DEFAULT_NODE_COLOR
        
        # Stroke widths
        @test node_type_strokewidth(Latent) == 2.0
        @test node_type_strokewidth(Observed) == 1.0
        @test node_type_strokewidth(Treatment) == TREATMENT_STROKEWIDTH
        
        # Stroke colours
        @test node_type_strokecolor(Latent) == :gray
        @test node_type_strokecolor(Observed) == :black
        @test node_type_strokecolor(Outcome) == :darkgray
        @test node_type_label_color(SwigFixed) == :black
    end
    
    @testset "apply_node_type_styling" begin
        types = [Treatment, Mediator, Outcome]
        styling = apply_node_type_styling(types)
        
        @test length(styling.colors) == 3
        @test length(styling.markers) == 3
        @test length(styling.strokewidths) == 3
        @test length(styling.strokecolors) == 3
        
        @test styling.colors[1] == node_type_color(Treatment)
        @test styling.colors[2] == node_type_color(Mediator)
        @test styling.colors[3] == node_type_color(Outcome)
    end
    
    @testset "apply_node_type_styling from DAGSpec" begin
        spec = DAGSpec(SimpleDiGraph(3),
            node_labels = ["X", "Y", "Z"],
            node_types = [Observed, Latent, Treatment]
        )
        
        styling = apply_node_type_styling(spec)
        
        @test styling.colors[1] == node_type_color(Observed)
        @test styling.colors[2] == node_type_color(Latent)
        @test styling.colors[3] == node_type_color(Treatment)
    end
    
    @testset "Typed graph constructors" begin
        # Confounding
        spec = typed_confounding_graph()
        @test length(spec.nodes) == 3
        @test spec.nodes[1].type == Confounder
        @test spec.nodes[2].type == Treatment
        @test spec.nodes[3].type == Outcome
        
        # Mediation
        spec = typed_mediation_graph()
        @test spec.nodes[1].type == Treatment
        @test spec.nodes[2].type == Mediator
        @test spec.nodes[3].type == Outcome
        
        # Instrumental
        spec = typed_instrumental_graph()
        @test length(spec.nodes) == 4
        @test spec.nodes[1].type == Instrument
        @test spec.nodes[4].type == Latent
        
        # Collider
        spec = typed_collider_graph()
        @test spec.nodes[2].type == Collider
    end
    
    @testset "dagplot with typed specs" begin
        spec = typed_confounding_graph()
        fig, ax, p = dagplot(spec)
        @test fig isa Makie.Figure
        
        spec = typed_instrumental_graph()
        fig, ax, p = dagplot(spec)
        @test fig isa Makie.Figure
    end
end
