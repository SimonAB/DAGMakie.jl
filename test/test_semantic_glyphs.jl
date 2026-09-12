using Test
using DAGMakie
using Graphs

@testset "semantic glyphs" begin
    @test marker_for_value_representation(:state) === :circle
    @test marker_for_value_representation(:event) === :circle
    @test marker_for_value_representation(:attribute) === :circle
    @test marker_for_value_representation(:trajectory) === :circle
    @test marker_for_value_representation(:interval_summary) === interval_summary_node_marker()
    @test marker_for_value_representation(:unspecified) === :circle
    @test interval_summary_node_marker() !== :circle
end

@testset "clarity export diet (glyphs and dagplot kwargs)" begin
    public = names(DAGMakie)
    @test :interval_summary_node_marker ∈ public
    @test :marker_for_value_representation ∈ public
    @test :enduring_node_marker ∉ public
    @test :ENDURING_NODE_MARKER ∉ public
    @test :AUTO_ALIGN_LABEL_DISTANCE ∉ public
    @test :resolve_color_by ∉ public
    @test :vaccine_nutrition_outcome_spec ∉ public
    @test isdefined(DAGMakie, :vaccine_nutrition_outcome_spec)
    @test isdefined(DAGMakie, :resolve_outer_labels)

    g = SimpleDiGraph(3)
    add_edge!(g, 1, 2)
    add_edge!(g, 1, 3)
    add_edge!(g, 2, 3)
    fig, _, p = dagplot(
        g;
        labels = ["W", "A", "Y"],
        color_by = true,
        exposure = 2,
        outcome = 3,
    )
    @test fig !== nothing
    @test length(p[:node_color][]) == 3
    @test length(unique(p[:node_color][])) > 1
    # Legacy aliases are accepted as pass-through kwargs but no longer drive
    # colouring; prefer color_by=/exposure= (clarity export diet).
    fig_legacy, _, p_legacy = dagplot(g; smart = true, treatment = 2, outcome = 3)
    @test fig_legacy !== nothing
    @test length(unique(p_legacy[:node_color][])) == 1
    fig_outer, _, p_outer = dagplot(
        g;
        labels = ["W", "A", "Y"],
        label_position = :outer,
    )
    @test fig_outer !== nothing
    @test p_outer[:nlabels_distance][] == OUTER_LABEL_DISTANCE
end
