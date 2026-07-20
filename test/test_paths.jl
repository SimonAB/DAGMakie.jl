using Test
using DAGMakie
using Graphs

@testset "Path types (viz-only)" begin
    path = CausalPath([1, 2, 3])
    @test length(path) == 3
    @test is_directed_path(path)
    @test path_edges(path) == [(1, 2), (2, 3)]

    back = CausalPath([3, 2, 1]; directions = [:backward, :backward])
    @test !is_directed_path(back)
    @test path_edges(back) == [(2, 3), (1, 2)]
end
