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
        fig, ax, p = dagplot_intervention(g, int, labels = ["Z", "X", "Y"])
        @test fig isa Makie.Figure

        fig_hidden, ax_hidden, p_hidden = dagplot_intervention(g, int;
            show_removed_edges = false,
            labels = ["Z", "X", "Y"],
        )
        @test fig_hidden isa Makie.Figure
        @test length(ax.scene.plots) > length(ax_hidden.scene.plots)
    end

    @testset "dagplot_do" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)

        fig, ax, p = dagplot_do(g, 2, labels = ["A", "B", "C"])
        @test fig isa Makie.Figure
    end

    @testset "dagplot_comparison" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 3)

        int = Intervention(2)
        fig = dagplot_comparison(g, int, labels = ["Z", "X", "Y"])
        @test fig isa Makie.Figure
    end

    @testset "dagplot_do_comparison" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)

        fig = dagplot_do_comparison(g, 2, labels = ["A", "B", "C"])
        @test fig isa Makie.Figure
    end

    @testset "do comparison shares layout positions" begin
        g = SimpleDiGraph(4)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 4)
        add_edge!(g, 4, 3)
        shared = compute_graph_layout(g)
        fig = dagplot_do_comparison(
            g, 2;
            labels = ["C", "A", "Y", "X"],
            layout = shared,
        )
        @test fig isa Makie.Figure
        # Re-resolving with the same DAGLayoutResult must keep positions
        again = compute_graph_layout(g; layout = shared)
        @test again.positions == shared.positions
    end

    @testset "removed-edge overlay trims to fitted markers" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 3)
        labels = ["Cₜ₋₁", "Aₜ₋₁", "Yₜ"]
        positions = [Point2f(0, 0), Point2f(2, 0), Point2f(4, 0)]
        fig, ax, p = dagplot_intervention(
            g,
            Intervention(2);
            labels = labels,
            layout = positions,
            show_removed_edges = true,
            label_position = :inner,
            fit_node_size_to_labels = true,
        )
        @test fig isa Makie.Figure
        fitted_sizes = p[:node_size][]
        fitted_markers = p[:node_marker][]
        @test fitted_sizes[2] isa Tuple  # long treatment label → oval

        to_px = DAGMakie._plot_to_px(p)
        removed = [(1, 2)]
        geom_fit = DAGMakie.compute_feedback_geometry(
            removed,
            positions,
            fitted_markers,
            fitted_sizes,
            [Point2f[]],
            to_px;
            arrow_size = 8,
            arrow_shift = :end,
        )
        style_size = DAGMakie._resolve_style(nothing).node_size
        geom_default = DAGMakie.compute_feedback_geometry(
            removed,
            positions,
            fill(:circle, 3),
            fill(Float64(style_size), 3),
            [Point2f[]],
            to_px;
            arrow_size = 8,
            arrow_shift = :end,
        )
        dest = positions[2]
        d_fit = hypot(
            geom_fit.arrow_positions[1][1] - dest[1],
            geom_fit.arrow_positions[1][2] - dest[2],
        )
        d_def = hypot(
            geom_default.arrow_positions[1][1] - dest[1],
            geom_default.arrow_positions[1][2] - dest[2],
        )
        # Theme-default size under-trims vs fitted oval; arrow must sit further out.
        @test d_fit > d_def
    end

    @testset "outer labels on do use factual edges when show_removed_edges" begin
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)  # removed under do(2); still drawn grey when show_removed_edges
        add_edge!(g, 2, 3)
        labels = ["Z", "X", "Y"]
        positions = [Point2f(0, 0), Point2f(1, 0), Point2f(2, 0)]
        aligns_factual = compute_auto_label_aligns(g, positions)
        aligns_mutilated = compute_auto_label_aligns(do_surgery(g, 2), positions)
        @test aligns_factual != aligns_mutilated

        fig, ax, p = dagplot_do(
            g, 2;
            labels = labels,
            layout = positions,
            label_position = :outer,
            show_removed_edges = true,
        )
        @test p[:nlabels_align][] == aligns_factual

        fig2, ax2, p2 = dagplot_do(
            g, 2;
            labels = labels,
            layout = positions,
            label_position = :outer,
            show_removed_edges = false,
        )
        @test p2[:nlabels_align][] == aligns_mutilated
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
