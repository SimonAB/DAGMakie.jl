using Test
using DAGMakie

@testset "semantic glyphs" begin
    @test marker_for_value_representation(:state) === :circle
    @test marker_for_value_representation(:event) === :circle
    @test marker_for_value_representation(:attribute) === :circle
    @test marker_for_value_representation(:trajectory) === :circle
    @test marker_for_value_representation(:interval_summary) === interval_summary_node_marker()
    @test marker_for_value_representation(:unspecified; single_node = true) === :circle
    @test marker_for_temporal_support(:from_onset) === :circle
    @test marker_for_temporal_support(:interval) === :circle
    @test enduring_node_marker() === interval_summary_node_marker()
end
