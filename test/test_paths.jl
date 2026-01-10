@testset "Paths and d-Separation" begin
    @testset "Path finding" begin
        # Chain: 1 → 2 → 3
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        
        paths = find_all_paths(g, 1, 3)
        @test length(paths) == 1
        @test paths[1].nodes == [1, 2, 3]
        @test all(d -> d == :forward, paths[1].directions)
        
        # Directed paths
        directed = find_directed_paths(g, 1, 3)
        @test length(directed) == 1
        @test is_directed_path(directed[1])
    end
    
    @testset "Path with multiple routes" begin
        # Diamond: 1 → 2, 1 → 3, 2 → 4, 3 → 4
        g = SimpleDiGraph(4)
        add_edge!(g, 1, 2)
        add_edge!(g, 1, 3)
        add_edge!(g, 2, 4)
        add_edge!(g, 3, 4)
        
        paths = find_directed_paths(g, 1, 4)
        @test length(paths) == 2
    end
    
    @testset "path_edges" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        
        paths = find_directed_paths(g, 1, 3)
        edges = path_edges(paths[1])
        @test edges == [(1, 2), (2, 3)]
    end
    
    @testset "Backdoor paths" begin
        # Confounding: Z → X → Y, Z → Y
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)  # Z → X
        add_edge!(g, 2, 3)  # X → Y
        add_edge!(g, 1, 3)  # Z → Y
        
        backdoor = find_backdoor_paths(g, 2, 3)  # Treatment=X, Outcome=Y
        @test length(backdoor) == 1
        @test backdoor[1].nodes == [2, 1, 3]  # X ← Z → Y
        @test is_backdoor_path(backdoor[1], 2)
    end
    
    @testset "is_collider" begin
        # X → Z ← Y
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)  # X → Z
        add_edge!(g, 3, 2)  # Y → Z
        
        paths = find_all_paths(g, 1, 3)
        @test length(paths) == 1
        # Path: 1 → 2 ← 3, so node 2 is a collider
        @test is_collider(paths[1], 2)
    end
    
    @testset "d-separation: fork" begin
        # Fork: X ← Z → Y
        g = SimpleDiGraph(3)
        add_edge!(g, 2, 1)  # Z → X
        add_edge!(g, 2, 3)  # Z → Y
        
        # X and Y are connected through Z
        @test !is_d_separated(g, 1, 3, Set{Int}())
        
        # Conditioning on Z blocks the path
        @test is_d_separated(g, 1, 3, Set([2]))
    end
    
    @testset "d-separation: chain" begin
        # Chain: X → Z → Y
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        
        # Connected
        @test !is_d_separated(g, 1, 3, Set{Int}())
        
        # Conditioning on Z blocks
        @test is_d_separated(g, 1, 3, Set([2]))
    end
    
    @testset "d-separation: collider" begin
        # Collider: X → Z ← Y
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 3, 2)
        
        # Blocked by collider
        @test is_d_separated(g, 1, 3, Set{Int}())
        
        # Conditioning on Z opens the path
        @test !is_d_separated(g, 1, 3, Set([2]))
    end
    
    @testset "d-separation: Vector conditioning set" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 2, 1)
        add_edge!(g, 2, 3)
        
        @test is_d_separated(g, 1, 3, [2])
        @test !is_d_separated(g, 1, 3, Int[])
    end
    
    @testset "ancestors and descendants" begin
        # Chain: 1 → 2 → 3 → 4
        g = SimpleDiGraph(4)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 3, 4)
        
        @test descendants(g, 1) == Set([2, 3, 4])
        @test descendants(g, 2) == Set([3, 4])
        @test descendants(g, 4) == Set{Int}()
        
        @test ancestors(g, 4) == Set([1, 2, 3])
        @test ancestors(g, 1) == Set{Int}()
    end
    
    @testset "d_separated_from" begin
        # Fork
        g = SimpleDiGraph(3)
        add_edge!(g, 2, 1)
        add_edge!(g, 2, 3)
        
        separated = d_separated_from(g, 1, Set([2]))
        @test 3 in separated
    end
    
    @testset "Adjustment sets" begin
        # Confounding: Z → X → Y, Z → Y
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)  # Z → X
        add_edge!(g, 2, 3)  # X → Y
        add_edge!(g, 1, 3)  # Z → Y
        
        # Empty set doesn't block backdoor
        @test !is_valid_adjustment_set(g, 2, 3, Set{Int}())
        
        # Conditioning on Z blocks the backdoor path
        @test is_valid_adjustment_set(g, 2, 3, Set([1]))
        
        # Cannot condition on treatment or outcome
        @test !is_valid_adjustment_set(g, 2, 3, Set([2]))
        @test !is_valid_adjustment_set(g, 2, 3, Set([3]))
    end
    
    @testset "blocks_all_backdoor_paths" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 3)
        
        @test blocks_all_backdoor_paths(g, 2, 3, Set([1]))
        @test !blocks_all_backdoor_paths(g, 2, 3, Set{Int}())
    end
    
    @testset "find_minimal_adjustment_set" begin
        # Confounding
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 3)
        
        adj = find_minimal_adjustment_set(g, 2, 3)
        @test adj !== nothing
        @test 1 in adj
        
        # No confounding - empty set should work
        g2 = SimpleDiGraph(2)
        add_edge!(g2, 1, 2)
        adj2 = find_minimal_adjustment_set(g2, 1, 2)
        @test adj2 == Set{Int}()
    end
    
    @testset "list_all_adjustment_sets" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 3)
        
        all_sets = list_all_adjustment_sets(g, 2, 3)
        @test length(all_sets) >= 1
        @test Set([1]) in all_sets
    end
    
    @testset "Mediator blocking" begin
        # X → M → Y
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        
        # M is a mediator - shouldn't be adjusted for
        @test !is_valid_adjustment_set(g, 1, 3, Set([2]))
    end
    
    @testset "Complex graph" begin
        # Instrumental variable with confounding:
        # Z → X → Y, U → X, U → Y
        g = SimpleDiGraph(4)
        add_edge!(g, 1, 2)  # Z → X
        add_edge!(g, 2, 3)  # X → Y
        add_edge!(g, 4, 2)  # U → X
        add_edge!(g, 4, 3)  # U → Y
        
        # U is a confounder
        backdoor = find_backdoor_paths(g, 2, 3)
        @test length(backdoor) == 1
        
        # Adjusting for U blocks the backdoor
        @test is_valid_adjustment_set(g, 2, 3, Set([4]))
        
        # Z is an instrument - adjusting for it is also valid
        @test is_valid_adjustment_set(g, 2, 3, Set([1, 4]))
    end
end
