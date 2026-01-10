using Test
using DAGMakie
using Graphs
using CairoMakie

@testset "DAGMakie.jl" begin
    include("test_types.jl")
    include("test_auto_align.jl")
    include("test_layout.jl")
    include("test_utils.jl")
    include("test_bidirected.jl")
    include("test_node_styling.jl")
    include("test_paths.jl")
    include("test_highlighting.jl")
    include("test_interventions.jl")
    include("test_dagplot.jl")
    include("test_aqua.jl")
end
