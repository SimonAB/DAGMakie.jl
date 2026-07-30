# SPDX-License-Identifier: MIT

# Test CausalDynamics extension
# Run with: julia --project=. -e 'include("test/test_causaldynamics_ext.jl")'
# Requires CausalDynamics.jl to be available

using Test
using DAGMakie
using Graphs

# Try loading visualization backend
makie_available = try
    @eval using CairoMakie
    true
catch
    @warn "CairoMakie not available - skipping visualization tests"
    false
end

# Check if CausalDynamics is available
cd_available = try
    @eval using CausalDynamics
    true
catch
    false
end

if cd_available
    @testset "CausalDynamics Extension" begin
        @testset "d-Separation integration" begin
            # Fork: X ← Z → Y
            g = SimpleDiGraph(3)
            add_edge!(g, 2, 1)  # Z → X
            add_edge!(g, 2, 3)  # Z → Y
            
            # Test CausalDynamics d_separated
            @test !CausalDynamics.d_separated(g, 1, 3, Int[])
            @test CausalDynamics.d_separated(g, 1, 3, [2])
        end
        
        @testset "Backdoor adjustment" begin
            # Confounding: Z → X → Y, Z → Y
            g = SimpleDiGraph(3)
            add_edge!(g, 1, 2)  # Z → X
            add_edge!(g, 2, 3)  # X → Y
            add_edge!(g, 1, 3)  # Z → Y
            
            # Test CausalDynamics backdoor
            adj = CausalDynamics.backdoor_adjustment_set(g, 2, 3)
            @test 1 in adj
        end
        
        @testset "Causal analysis" begin
            g = SimpleDiGraph(3)
            add_edge!(g, 1, 2)
            add_edge!(g, 2, 3)
            add_edge!(g, 1, 3)
            
            analysis = DAGMakieCausalDynamicsExt.causal_analysis(g, 2, 3)
            
            @test haskey(analysis, :backdoor_paths)
            @test haskey(analysis, :adjustment_set)
            @test haskey(analysis, :identifiable)
            @test analysis.identifiable == true
        end
        
        if makie_available
            @testset "SCM Plotting" begin
                # Create a simple GraphSCM
                g = SimpleDiGraph(3)
                add_edge!(g, 1, 2)
                add_edge!(g, 2, 3)
                
                scm = CausalDynamics.GraphSCM(g, Dict{Int,Function}(), Set{Int}())
                
                # Test dagplot with SCM
                fig, ax, p = dagplot(scm, nlabels = ["X", "Y", "Z"])
                @test fig isa Makie.Figure
            end
            
            @testset "d-Separation plotting" begin
                g = SimpleDiGraph(3)
                add_edge!(g, 2, 1)
                add_edge!(g, 2, 3)
                
                fig, ax, p = DAGMakieCausalDynamicsExt.dagplot_dsep_cd(g, 1, 3, [2], 
                    nlabels = ["X", "Z", "Y"]
                )
                @test fig isa Makie.Figure
                @test contains(ax.title[], "d-separated")
            end
            
            @testset "Backdoor plotting" begin
                g = SimpleDiGraph(3)
                add_edge!(g, 1, 2)
                add_edge!(g, 2, 3)
                add_edge!(g, 1, 3)
                
                fig, ax, p = DAGMakieCausalDynamicsExt.dagplot_backdoor_cd(g, 2, 3,
                    nlabels = ["Z", "X", "Y"]
                )
                @test fig isa Makie.Figure
            end
            
            @testset "SCM-specific plotting" begin
                g = SimpleDiGraph(4)
                add_edge!(g, 1, 3)
                add_edge!(g, 2, 1)
                add_edge!(g, 4, 3)
                
                scm = CausalDynamics.GraphSCM(g, Dict{Int,Function}(), Set([2, 4]))
                
                fig, ax, p = DAGMakieCausalDynamicsExt.dagplot_scm(scm,
                    nlabels = ["X", "U_X", "Y", "U_Y"],
                    show_exogenous = true
                )
                @test fig isa Makie.Figure
            end
            
            @testset "Intervention visualisation" begin
                g = SimpleDiGraph(3)
                add_edge!(g, 1, 2)
                add_edge!(g, 2, 3)
                add_edge!(g, 1, 3)
                
                scm = CausalDynamics.GraphSCM(g, Dict{Int,Function}(), Set{Int}())
                
                fig, ax, p = DAGMakieCausalDynamicsExt.dagplot_intervention_cd(scm, 2,
                    nlabels = ["Z", "X", "Y"]
                )
                @test fig isa Makie.Figure
            end
        end
    end
    
    println("\n✓ CausalDynamics extension tests passed!")
else
    @warn "CausalDynamics not available - skipping extension tests"
end
