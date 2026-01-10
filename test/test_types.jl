@testset "Types" begin
    @testset "NodeType" begin
        # Test all node types exist
        @test Observed isa NodeType
        @test Latent isa NodeType
        @test Treatment isa NodeType
        @test Outcome isa NodeType
        @test Instrument isa NodeType
        @test Confounder isa NodeType
        @test Mediator isa NodeType
        @test Collider isa NodeType
    end
    
    @testset "NodeSpec" begin
        # Basic construction
        n1 = NodeSpec("X")
        @test n1.label == "X"
        @test n1.type == Observed
        @test n1.color === nothing
        
        # With type
        n2 = NodeSpec("U", type=Latent)
        @test n2.type == Latent
        
        # With all options
        n3 = NodeSpec("A", type=Treatment, color=:blue, size=20)
        @test n3.color == :blue
        @test n3.size == 20
        
        # Shorthand
        n4 = node("Y", type=Outcome)
        @test n4.label == "Y"
        @test n4.type == Outcome
    end
    
    @testset "EdgeType" begin
        @test Directed isa EdgeType
        @test Bidirected isa EdgeType
        @test Undirected isa EdgeType
    end
    
    @testset "EdgeSpec" begin
        # Basic construction
        e1 = EdgeSpec(1, 2)
        @test e1.src == 1
        @test e1.dst == 2
        @test e1.type == Directed
        
        # With options
        e2 = EdgeSpec(1, 2, type=Bidirected, color=:red)
        @test e2.type == Bidirected
        @test e2.color == :red
        
        # Shorthand
        e3 = edge(2, 3, style=:dash)
        @test e3.style == :dash
    end
    
    @testset "DAGSpec" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        
        # Basic construction
        spec = DAGSpec(g)
        @test length(spec.nodes) == 3
        @test spec.nodes[1].label == "1"
        
        # With labels
        spec2 = DAGSpec(g, node_labels=["X", "Y", "Z"])
        @test spec2.nodes[1].label == "X"
        @test spec2.nodes[3].label == "Z"
        
        # With types
        spec3 = DAGSpec(g, 
            node_labels=["A", "B", "C"],
            node_types=[Treatment, Mediator, Outcome]
        )
        @test spec3.nodes[1].type == Treatment
        @test spec3.nodes[2].type == Mediator
    end
    
    @testset "Default styling" begin
        @test default_node_color(Observed) == :lightblue
        @test default_node_color(Latent) == :white
        @test default_node_color(Treatment) == :lightgreen
        
        @test default_node_marker(Observed) == :circle
        @test default_node_marker(Latent) == :circle
        
        @test default_node_strokewidth(Latent) == 2.0
        @test default_node_strokewidth(Observed) == 1.0
    end
end
