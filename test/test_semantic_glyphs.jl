using Test
using DAGMakie

@testset "semantic glyphs" begin
    @test marker_for_value_representation(:state) === :circle
    @test marker_for_value_representation(:event) === :circle
    @test marker_for_value_representation(:interval_summary) === enduring_node_marker()
    @test marker_for_value_representation(:attribute) === enduring_node_marker()
    @test marker_for_value_representation(:unspecified; single_node = true) === enduring_node_marker()
    @test marker_for_temporal_support(:point) === :circle
    @test marker_for_temporal_support(:from_onset) === enduring_node_marker()
end
