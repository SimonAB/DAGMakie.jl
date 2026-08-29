# SPDX-License-Identifier: MIT

using Graphs: SimpleDiGraph, add_edge!

@testset "temporal smart role propagation (#5)" begin
    @test temporal_node_index(2, 1, 1) == 1
    @test temporal_node_index(2, 2, 1) == 2
    @test temporal_node_index(2, 1, 2) == 3
    @test temporal_variable_time(4, 2) == (2, 2)

    # Two variables (A, B), two occasions. Propagate treatment / outcome rows.
    g = SimpleDiGraph(4)
    add_edge!(g, 1, 3)  # A₁ → A₂
    add_edge!(g, 1, 4)  # A₁ → B₂
    base = classify_smart_roles(g, 1, 4)
    roles = propagate_temporal_smart_roles(base, 2, 2; exposure = 1, outcome = 4)
    @test roles[1] == SmartExposure
    @test roles[3] == SmartExposure
    @test roles[2] == SmartOutcome
    @test roles[4] == SmartOutcome

    # Confounder row: strongest ancestral role across occasions.
    g3 = SimpleDiGraph(6)
    add_edge!(g3, 1, 2)  # W₁ → A₁
    add_edge!(g3, 1, 3)  # W₁ → Y₁
    add_edge!(g3, 4, 5)  # W₂ → A₂
    add_edge!(g3, 4, 6)  # W₂ → Y₂
    add_edge!(g3, 2, 5)  # A₁ → A₂
    add_edge!(g3, 2, 6)  # A₁ → Y₂
    base3 = classify_smart_roles(g3, 2, 6)
    roles3 = propagate_temporal_smart_roles(base3, 3, 2; exposure = 2, outcome = 6)
    @test roles3[1] == SmartAncestorBoth
    @test roles3[4] == SmartAncestorBoth
    @test roles3[2] == SmartExposure
    @test roles3[5] == SmartExposure
    @test roles3[6] == SmartOutcome
    @test roles3[3] == SmartOutcome

    exp_node, out_node = resolve_temporal_exposure_outcome((2, 1), (3, 2), 3)
    @test exp_node == 2
    @test out_node == 6

    style = temporal_role_styling(
        g3, 3, 2;
        exposure = (2, 1),
        outcome = (3, 2),
        color_by = :ancestors,
    )
    @test length(style.node_color) == 6
    @test style.node_color[2] == smart_node_color(SmartExposure)
    @test style.node_color[5] == smart_node_color(SmartExposure)
    @test style.node_color[1] == style.node_color[4]

    fig, ax, p = dagplot_time_indexed(
        g3, 3, 2;
        labels = ["W₁", "A₁", "Y₁", "W₂", "A₂", "Y₂"],
        color_by = :ancestors,
        exposure = (2, 1),
        outcome = (3, 2),
    )
    @test fig !== nothing
end
