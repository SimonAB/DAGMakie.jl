# SPDX-License-Identifier: MIT

using CausalInference

@testset "DAGMakieCausalInferenceExt" begin
    ext = Base.get_extension(DAGMakie, :DAGMakieCausalInferenceExt)
    @test ext !== nothing

    @testset "dsep_status and dagplot_dsep" begin
        # Chain: 1 → 2 → 3
        g_chain, chain_labels = chain_graph(["X", "M", "Y"])
        @test ext.dsep_status(g_chain, 1, 3, Set{Int}()) === false
        @test ext.dsep_status(g_chain, 1, 3, Set([2])) === true

        # Collider: 1 → 2 ← 3
        g_coll, coll_labels = collider_graph(["A", "C", "B"])
        @test ext.dsep_status(g_coll, 1, 3, Set{Int}()) === true
        @test ext.dsep_status(g_coll, 1, 3, Set([2])) === false

        fig, ax, p = dagplot_dsep(g_chain, 1, 3, Set([2]); labels = chain_labels)
        @test fig isa Figure
        @test occursin("d-separated", String(ax.title[]))
    end

    @testset "min_backdoor_adjustment and dagplot_adjustment" begin
        # Confounding: Z (1) → X (2) → Y (3), Z (1) → Y (3)
        g_conf, conf_labels = confounding_graph(["Z", "X", "Y"])
        @test ext.min_backdoor_adjustment(g_conf, 2, 3) == Set([1])

        # Chain without confounding needs no adjustment
        g_chain, _ = chain_graph(["X", "M", "Y"])
        @test isempty(ext.min_backdoor_adjustment(g_chain, 1, 3))

        # dagplot_adjustment computes minimal backdoor set via extension when adjustment= omitted
        fig, ax, p = dagplot_adjustment(g_conf, 2, 3; labels = conf_labels)
        @test fig isa Figure
        @test p[:node_color][][1] == :indianred

        # color_by = :adjustment without explicit adjustment= uses extension
        fig2, ax2, p2 = dagplot(
            g_conf;
            color_by = :adjustment,
            exposure = 2,
            outcome = 3,
            labels = conf_labels,
        )
        @test fig2 isa Figure
        @test p2[:node_strokecolor][][1] == :darkred
    end

    @testset "ancestor_sets" begin
        g_conf, _ = confounding_graph(["Z", "X", "Y"])
        ax_ext, ay_ext = ext.ancestor_sets(g_conf, 2, 3)
        @test ax_ext == Set([1, 2])
        @test ay_ext == Set([1, 2, 3])

        # Public ancestor_sets dispatches through the loaded extension
        @test ancestor_sets(g_conf, 2, 3) == (Set([1, 2]), Set([1, 2, 3]))
    end
end
