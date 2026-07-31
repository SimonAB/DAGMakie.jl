# SPDX-License-Identifier: MIT

@testset "Visual grammar" begin
    @testset "New node and edge types" begin
        @test EffectMeasure isa NodeType
        @test SwigFixed isa NodeType
        @test Modifier isa EdgeType

        @test default_node_color(EffectMeasure) == NODE_COLOR_EFFECT
        @test default_node_marker(EffectMeasure) == :rect
        @test default_node_color(SwigFixed) == NODE_COLOR_SWIG_FIXED
        @test default_node_label_color(SwigFixed) == :black
        @test default_node_strokewidth(Treatment) == TREATMENT_STROKEWIDTH
        @test default_node_strokewidth(Outcome) == OUTCOME_STROKEWIDTH
    end

    @testset "modifier_edge" begin
        e = modifier_edge(1, 3)
        @test e.type == Modifier
        @test e.style == MODIFIER_EDGE_STYLE
        @test e.color == MODIFIER_EDGE_COLOR
        @test e.label == "mod"
    end

    @testset "Vaccine × nutrition specs" begin
        outcome = vaccine_nutrition_outcome_spec()
        idag = vaccine_nutrition_idag_spec()
        @test length(outcome.nodes) == 3
        @test outcome.nodes[1].type == Confounder
        @test outcome.nodes[2].type == Treatment
        @test outcome.nodes[3].type == Outcome
        @test idag.nodes[3].type == EffectMeasure
        @test has_edge(outcome.graph, 1, 2)
        @test has_edge(idag.graph, 2, 3)
        @test length(vaccine_nutrition_layout()) == 3
    end

    @testset "2×2 DiD specs" begin
        factual = did_2x2_factual_spec()
        swig = did_2x2_swig_spec()
        @test nv(factual.graph) == 5
        @test nv(swig.graph) == 6
        @test factual.nodes[5].type == Treatment
        @test swig.nodes[6].type == SwigFixed
        @test has_edge(factual.graph, 5, 4)   # A₁ → Y₁
        @test has_edge(swig.graph, 6, 4)      # a=0 → Y₁(0)
        @test !has_edge(swig.graph, 5, 4)     # no outflow from random half
        @test length(did_2x2_factual_layout()) == 5
        @test length(did_2x2_swig_layout()) == 6
    end

    @testset "Example figures smoke" begin
        fig1 = dagplot_vaccine_nutrition_interaction()
        @test fig1 isa Figure
        fig2 = dagplot_did_swig()
        @test fig2 isa Figure
        fig3 = dagplot_side_by_side(
            vaccine_nutrition_outcome_spec(),
            vaccine_nutrition_idag_spec();
            layout = vaccine_nutrition_layout(),
        )
        @test fig3 isa Figure
    end
end
