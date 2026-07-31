# SPDX-License-Identifier: MIT

@testset "Smart colouring" begin
    @testset "ancestors_via_graphs" begin
        g, _ = confounding_graph(["Z", "X", "Y"])
        @test ancestors_via_graphs(g, (2,)) == Set([1, 2])  # Z, X
        @test ancestors_via_graphs(g, (3,)) == Set([1, 2, 3])
    end

    @testset "classify_smart_roles" begin
        g, _ = confounding_graph(["Z", "X", "Y"])
        roles = classify_smart_roles(g, 2, 3)
        @test roles[2] == SmartExposure
        @test roles[3] == SmartOutcome
        @test roles[1] == SmartAncestorBoth  # Z → X and Z → Y
    end

    @testset "dagplot smart" begin
        g, labels = confounding_graph(["Z", "X", "Y"])
        style = smart_style_for_graph(g, 2, 3)
        @test style.node_color[1] == SMART_COLOR_ANC_BOTH
        @test style.node_color[2] == SMART_COLOR_EXPOSURE
        @test style.node_color[3] == SMART_COLOR_OUTCOME

        fig, ax, p = dagplot(g; smart = true, treatment = 2, outcome = 3, nlabels = labels)
        @test fig isa Figure

        fig2, ax2, p2 = dagplot_smart(g, 2, 3; nlabels = labels)
        @test fig2 isa Figure
    end

    @testset "irrelevant nodes gray" begin
        g = SimpleDiGraph(4)
        add_edge!(g, 1, 2)  # Z → X
        add_edge!(g, 1, 3)  # Z → Y
        add_edge!(g, 2, 3)  # X → Y
        # node 4 isolated
        roles = classify_smart_roles(g, 2, 3)
        @test roles[4] == SmartIrrelevant
        @test smart_label_color(SmartIrrelevant) == :black
    end

    @testset "adjustment mode without CI needs adjustment=" begin
        g, _ = confounding_graph(["Z", "X", "Y"])
        style = smart_style_for_graph(g, 2, 3; mode = :adjustment, adjustment = Set([1]))
        @test style.node_strokewidth[1] == 3.0
        @test 1 in style.adjustment
    end
end
