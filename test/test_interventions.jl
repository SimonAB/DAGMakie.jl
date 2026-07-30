# SPDX-License-Identifier: MIT

@testset "Interventions (do-operator)" begin
    @testset "Graph surgery" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 3)

        g_do = do_surgery(g, 2)
        @test nv(g_do) == 3
        @test ne(g_do) == 2
        @test !has_edge(g_do, 1, 2)
        @test has_edge(g_do, 2, 3)
        @test has_edge(g_do, 1, 3)
        @test has_edge(g, 1, 2)
    end

    @testset "Multi-node surgery" begin
        g = SimpleDiGraph(4)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 3, 4)

        g_do = do_surgery(g, [2, 3])
        @test !has_edge(g_do, 1, 2)
        @test !has_edge(g_do, 2, 3)
        @test has_edge(g_do, 3, 4)
    end

    @testset "In-place surgery" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)

        do_surgery!(g, [2])
        @test !has_edge(g, 1, 2)
        @test has_edge(g, 2, 3)
    end

    @testset "Intervention struct" begin
        int = Intervention(2)
        @test int.nodes == [2]
        @test contains(int.label, "do")

        int = Intervention(2; value = "X=1", label = "do(X=1)")
        @test int.label == "do(X=1)"

        int = Intervention([1, 2])
        @test length(int.nodes) == 2
    end

    @testset "Intervention labels" begin
        @test intervention_label("X") == "do(X)"
        @test intervention_label("X"; value = 1) == "do(X=1)"

        labels = ["Z", "X", "Y"]
        int = Intervention(2)
        new_labels = format_intervention_labels(labels, int)
        @test new_labels[2] == "do(X)"
        @test new_labels[1] == "Z"
        @test new_labels[3] == "Y"
    end

    @testset "dagplot_intervention" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 3)

        int = Intervention(2)
        fig, ax, p = dagplot_intervention(g, int, nlabels = ["Z", "X", "Y"])
        @test fig isa Makie.Figure

        fig_hidden, ax_hidden, p_hidden = dagplot_intervention(g, int;
            show_original = false,
            nlabels = ["Z", "X", "Y"],
        )
        @test fig_hidden isa Makie.Figure
        @test length(ax.scene.plots) > length(ax_hidden.scene.plots)
    end

    @testset "dagplot_do" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)

        fig, ax, p = dagplot_do(g, 2, nlabels = ["A", "B", "C"])
        @test fig isa Makie.Figure
    end

    @testset "dagplot_comparison" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 3)

        int = Intervention(2)
        fig = dagplot_comparison(g, int, nlabels = ["Z", "X", "Y"])
        @test fig isa Makie.Figure
    end

    @testset "dagplot_do_comparison" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)

        fig = dagplot_do_comparison(g, 2, nlabels = ["A", "B", "C"])
        @test fig isa Makie.Figure
    end

    @testset "CausalQuery" begin
        query = CausalQuery(2, 3)
        @test query.treatment == 2
        @test query.outcome == 3

        query = CausalQuery(2, 3;
            intervention = Intervention(2),
            conditioning = Set([1]),
        )
        @test query.intervention !== nothing
        @test 1 in query.conditioning
    end

    @testset "Query to string" begin
        query = CausalQuery(2, 3; intervention = Intervention(2))
        s = query_to_string(query, ["Z", "X", "Y"])
        @test contains(s, "do")
        @test contains(s, "Y")

        query = CausalQuery(2, 3)
        s = query_to_string(query, ["Z", "X", "Y"])
        @test contains(s, "P(Y")
    end
end
