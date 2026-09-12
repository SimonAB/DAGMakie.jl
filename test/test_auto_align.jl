# SPDX-License-Identifier: MIT

using Makie: Point2f

@testset "Auto Label Alignment" begin
    @testset "compute_auto_label_aligns" begin
        # Simple chain: 1 → 2 → 3
        g_chain = SimpleDiGraph(3)
        add_edge!(g_chain, 1, 2)
        add_edge!(g_chain, 2, 3)

        positions_horizontal = [Point2f(0, 0), Point2f(1, 0), Point2f(2, 0)]
        aligns = compute_auto_label_aligns(g_chain, positions_horizontal)

        @test length(aligns) == 3
        # All alignments should be tuples of symbols
        @test all(a -> a isa Tuple{Symbol, Symbol}, aligns)

        # Node 1 has edge going right, label should be above or below
        # Node 3 has edge going left, label should be above or below
        # Node 2 has edges both ways, label should be above or below

        # Vertical chain
        positions_vertical = [Point2f(0, 0), Point2f(0, 1), Point2f(0, 2)]
        aligns_v = compute_auto_label_aligns(g_chain, positions_vertical)
        @test length(aligns_v) == 3
    end

    @testset "Isolated nodes" begin
        # Graph with isolated node
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        # Node 3 is isolated

        positions = [Point2f(0, 0), Point2f(1, 0), Point2f(2, 0)]
        aligns = compute_auto_label_aligns(g, positions)

        # Isolated node should get default alignment
        @test aligns[3] == (:right, :bottom)
    end

    @testset "Fork pattern" begin
        # Fork: 1 ← 2 → 3
        g = SimpleDiGraph(3)
        add_edge!(g, 2, 1)
        add_edge!(g, 2, 3)

        positions = [Point2f(0, 0), Point2f(1, 0), Point2f(2, 0)]
        aligns = compute_auto_label_aligns(g, positions)

        @test length(aligns) == 3
        # Node 2 (fork) has edges going both left and right
        # Label should be above or below
    end

    @testset "Collider pattern" begin
        # Collider: 1 → 2 ← 3
        g = SimpleDiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 3, 2)

        positions = [Point2f(0, 0), Point2f(1, 0), Point2f(2, 0)]
        aligns = compute_auto_label_aligns(g, positions)

        @test length(aligns) == 3
    end

    @testset "align_to_direction" begin
        # East (label extends right)
        dir = align_to_direction((:left, :center))
        @test dir[1] ≈ 1.0
        @test dir[2] ≈ 0.0

        # West (label extends left)
        dir = align_to_direction((:right, :center))
        @test dir[1] ≈ -1.0
        @test dir[2] ≈ 0.0

        # North (label extends up)
        dir = align_to_direction((:center, :bottom))
        @test dir[1] ≈ 0.0
        @test dir[2] ≈ 1.0

        # South (label extends down)
        dir = align_to_direction((:center, :top))
        @test dir[1] ≈ 0.0
        @test dir[2] ≈ -1.0

        # Northeast
        dir = align_to_direction((:left, :bottom))
        @test dir[1] > 0
        @test dir[2] > 0
        @test dir[1]^2 + dir[2]^2 ≈ 1.0
    end

    @testset "_angle_to_alignment" begin
        # Test that angles map to expected directions
        # 0 radians = East
        @test DAGMakie._angle_to_alignment(0.0) == (:left, :center)

        # π radians = West
        @test DAGMakie._angle_to_alignment(Float64(π)) == (:right, :center)

        # π/2 radians = North
        @test DAGMakie._angle_to_alignment(Float64(π/2)) == (:center, :bottom)

        # -π/2 or 3π/2 radians = South
        @test DAGMakie._angle_to_alignment(Float64(3π/2)) == (:center, :top)
    end

    @testset "DAGMakie.resolve_auto_align_label_settings" begin
        g, _ = confounding_graph(["Z", "X", "Y"])
        positions = Point2f[Point2f(0, 1), Point2f(-1, 0), Point2f(1, 0)]
        settings = DAGMakie.resolve_auto_align_label_settings(
            g, positions;
            distance = 0,
            color = :white,
            distance_explicit = false,
            color_explicit = false,
        )
        @test length(settings.align) == 3
        @test settings.distance == OUTER_LABEL_DISTANCE
        @test settings.color == OUTER_LABEL_COLOR

        # Explicit in-node distance is preserved (even if unusual with auto-align)
        kept = DAGMakie.resolve_auto_align_label_settings(
            g, positions;
            distance = 0,
            color = :white,
            distance_explicit = true,
            color_explicit = true,
        )
        @test kept.distance == 0
        @test kept.color == :white
    end

    @testset "OUTER_LABEL aliases" begin
        @test OUTER_LABEL_DISTANCE isa Real
        @test OUTER_LABEL_COLOR === :black
        @test OUTER_LABEL_NODE_SIZE isa Real
    end

    @testset "DAGMakie.resolve_outer_labels" begin
        @test DAGMakie.resolve_outer_labels(:inner) === false
        @test DAGMakie.resolve_outer_labels(:outer) === true
        @test_throws ArgumentError DAGMakie.resolve_outer_labels(:side)
    end

    @testset "resolve_nlabels prefers labels= and refuses conflicts" begin
        @test DAGMakie.resolve_nlabels(; labels = ["A", "B"]) == ["A", "B"]
        @test DAGMakie.resolve_nlabels(; nlabels = ["A", "B"]) == ["A", "B"]
        @test DAGMakie.resolve_nlabels(; labels = ["A"], nlabels = ["A"]) == ["A"]
        @test_throws ArgumentError DAGMakie.resolve_nlabels(;
            labels = ["A", "B"], nlabels = ["X", "Y"],
        )
        g = SimpleDiGraph(2)
        add_edge!(g, 1, 2)
        @test_throws ArgumentError dagplot(
            g; labels = ["A", "B"], nlabels = ["X", "Y"],
        )
    end

    @testset "DAGMakie.resolve_node_gap" begin
        @test DAGMakie.resolve_node_gap(nothing; outer_labels = false) == DEFAULT_NODE_GAP_INNER
        @test DAGMakie.resolve_node_gap(nothing; outer_labels = true) == DEFAULT_NODE_GAP_OUTER
        @test DAGMakie.resolve_node_gap(3.1; outer_labels = false) == 3.1
        @test DAGMakie.resolve_node_gap(3.1; outer_labels = true) == 3.1
    end

    @testset "dagplot outer labels" begin
        g, labels = confounding_graph(["Z", "X", "Y"])
        fig, ax, p = dagplot(g; labels = labels, label_position = :outer)
        @test fig isa Figure
        @test p[:nlabels_distance][] == OUTER_LABEL_DISTANCE
        @test p[:nlabels_color][] == OUTER_LABEL_COLOR
        @test all(==(OUTER_LABEL_NODE_SIZE), p[:node_size][])

        fig2, ax2, p2 = dagplot(
            g;
            labels = labels,
            label_position = :outer,
            node_size = 30,
        )
        @test all(==(30), p2[:node_size][])
    end
end
