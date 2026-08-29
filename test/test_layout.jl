# SPDX-License-Identifier: MIT

using Makie: Point2f

@testset "Layout Utilities" begin
    @testset "estimate_label_extent" begin
        # Label extending right (left-aligned)
        extent = estimate_label_extent("Test", (:left, :center), 14, 10)
        @test extent.dx_min > 0  # Offset from node
        @test extent.dx_max > extent.dx_min  # Extends right
        
        # Label extending left (right-aligned)
        extent = estimate_label_extent("Test", (:right, :center), 14, 10)
        @test extent.dx_max < 0  # Extends left
        @test extent.dx_min < extent.dx_max
        
        # Label extending up (bottom-aligned)
        extent = estimate_label_extent("Test", (:center, :bottom), 14, 10)
        @test extent.dy_min > 0
        @test extent.dy_max > extent.dy_min
        
        # Longer labels have larger extent
        short = estimate_label_extent("A", (:left, :center), 14, 10)
        long = estimate_label_extent("Long Label", (:left, :center), 14, 10)
        @test long.dx_max > short.dx_max
    end

    @testset "fit_node_sizes_to_labels" begin
        w_short, h_short = estimate_label_pixel_size("A", 16)
        w_long, h_long = estimate_label_pixel_size("nutrition", 16)
        @test w_long > w_short
        @test h_short == h_long

        size_a, marker_a = node_size_for_inner_label("A")
        size_n, marker_n = node_size_for_inner_label("nutrition")
        @test marker_a === FIT_NODE_MARKER
        @test size_a isa Real
        @test marker_n === FIT_NODE_MARKER
        @test size_n isa Tuple

        sizes, markers = fit_node_sizes_to_labels(["A", "nutrition", "Y"])
        @test markers[1] === FIT_NODE_MARKER
        @test markers[2] === FIT_NODE_MARKER
        @test sizes[2] isa Tuple
        @test sizes[2][1] > sizes[1]

        # `:circle` BezierPath undersizes vs markersize; fit normalises to Circle.
        size_forced, marker_forced = node_size_for_inner_label("nutrition"; marker = :circle)
        @test marker_forced === FIT_NODE_MARKER
        @test size_forced isa Real

        g, labels = confounding_graph(["nutrition", "X", "Y"])
        fig, ax, p = dagplot(g;
            nlabels = labels,
            label_position = :inner,
            fit_node_size_to_labels = true,
        )
        @test fig isa Figure
        @test p[:node_marker][][1] === FIT_NODE_MARKER
        @test p[:node_size][][1] isa Tuple
        @test p[:node_size][][2] isa Real

        fig_off, ax_off, p_off = dagplot(g;
            nlabels = labels,
            label_position = :inner,
            fit_node_size_to_labels = false,
        )
        @test all(==(DAGMakie._resolve_style(nothing).node_size), p_off[:node_size][])
    end
    
    @testset "compute_label_bounds" begin
        positions = [Point2f(0, 0), Point2f(1, 0), Point2f(2, 0)]
        labels = ["A", "B", "C"]
        align = (:right, :bottom)
        
        bounds = compute_label_bounds(positions, labels, align, 10, 14)
        x_min, x_max, y_min, y_max = bounds
        
        # Bounds should encompass all nodes
        @test x_min <= 0
        @test x_max >= 2
        
        # Bounds should be larger than just node range due to labels
        @test x_max - x_min >= 2
    end
    
    @testset "compute_padded_limits" begin
        positions = [Point2f(0, 0), Point2f(1, 0), Point2f(2, 0)]
        labels = ["X", "Y", "Z"]
        
        # With labels
        xlim, ylim = compute_padded_limits(
            positions, labels, (:right, :bottom), 10, 14;
            padding = 0.1
        )
        
        @test xlim[1] < 0  # Padding on left
        @test xlim[2] > 2  # Padding on right
        
        # Without labels
        xlim_no_label, ylim_no_label = compute_padded_limits(
            positions, nothing, (:right, :bottom), 10, 14;
            padding = 0.1
        )
        
        @test xlim_no_label[1] < 0
        @test xlim_no_label[2] > 2

        # Horizontal chain: y-span is degenerate; DataAspect must not collapse
        # the plot area below the marker diameter.
        xlim_chain, ylim_chain = compute_padded_limits(
            positions, labels, (:center, :center), 0, 16;
            padding = 0.1,
            node_sizes = 34,
        )
        y_span = ylim_chain[2] - ylim_chain[1]
        x_span = xlim_chain[2] - xlim_chain[1]
        @test y_span / x_span >= 0.3
        @test y_span / 2 > 0.2
    end

    @testset "pedagogical triangle for confounding DAGs" begin
        g, _ = confounding_graph(["Z", "X", "Y"])
        result = compute_graph_layout(g)
        ys = [p[2] for p in result.positions]
        xs = [p[1] for p in result.positions]
        # Confounder Z (node 1) at apex; X and Y on the base
        @test result.positions[1][2] > result.positions[2][2]
        @test result.positions[1][2] > result.positions[3][2]
        @test result.positions[2][1] < result.positions[3][1]
        # Not collinear: y-range is non-degenerate
        @test maximum(ys) - minimum(ys) > 0.5
        @test maximum(xs) - minimum(xs) > 0.5

        # Explicit spring mode still available when requested
        layered = compute_graph_layout(g; layout_mode = :spring)
        @test length(layered.positions) == 3
    end

    @testset "curved edge waypoints" begin
        g = SimpleDiGraph(4)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 3, 4)
        add_edge!(g, 1, 4)
        result = compute_graph_layout(
            g;
            layout_mode = :acyclic,
            edge_routing = Dict((1, 4) => CurvedEdge()),
        )
        @test haskey(result.edge_waypoints, (1, 4))
        @test !isempty(result.edge_waypoints[(1, 4)])
        waypoints = result.edge_waypoints[(1, 4)]
        waypoint = waypoints[cld(length(waypoints), 2)]
        p1, p2 = result.positions[1], result.positions[4]
        chord = p2 - p1
        offset = waypoint - (p1 + p2) / 2
        cross = chord[1] * offset[2] - chord[2] * offset[1]
        @test abs(cross) > 1e-3

        layout = Point2f[Point2f(0, 0), Point2f(1, 0), Point2f(2, 0), Point2f(3, 0)]
        res_shallow = compute_graph_layout(
            g; layout = layout, edge_routing = Dict((1, 4) => CurvedEdge(bow = 0.12)),
        )
        res_deep = compute_graph_layout(
            g; layout = layout, edge_routing = Dict((1, 4) => CurvedEdge(bow = 0.35)),
        )
        bow_depth(res, key) = begin
            wps = res.edge_waypoints[key]
            p1, p2 = res.positions[key[1]], res.positions[key[2]]
            mid = (p1 + p2) / 2
            wp = wps[cld(length(wps), 2)]
            abs((p2[1] - p1[1]) * (wp[2] - mid[2]) - (p2[2] - p1[2]) * (wp[1] - mid[1]))
        end
        @test bow_depth(res_deep, (1, 4)) > bow_depth(res_shallow, (1, 4))

        fig, ax, p = dagplot(
            g;
            nlabels = ["A", "B", "C", "D"],
            edge_routing = Dict((1, 4) => :curved),
        )
        @test fig isa Figure
        wps = p[:waypoints][]
        edge_lookup = Dict((src(e), dst(e)) => i for (i, e) in enumerate(edges(g)))
        @test !isempty(wps[edge_lookup[(1, 4)]])
    end

    @testset "edge_routing straight and curved" begin
        g = SimpleDiGraph(4)
        add_edge!(g, 1, 2); add_edge!(g, 2, 3); add_edge!(g, 1, 3); add_edge!(g, 1, 4); add_edge!(g, 3, 4)
        layout = Point2f[
            Point2f(0, 0),
            Point2f(1.2, 1.0),
            Point2f(2.4, 0),
            Point2f(3.6, 0),
        ]
        res = compute_graph_layout(g; layout = layout)
        @test !haskey(res.edge_waypoints, (1, 4))  # default straight
        res_curved = compute_graph_layout(
            g;
            layout = layout,
            edge_routing = Dict((1, 4) => 0.3),
        )
        @test haskey(res_curved.edge_waypoints, (1, 4))
        fig, _, _ = dagplot(
            g;
            layout = layout,
            labels = ["A", "M1", "M2", "Y"],
            edge_routing = Dict((1, 4) => :curved),
        )
        @test fig isa Figure
    end

    @testset "layered crossing count" begin
        g = SimpleDiGraph(4)
        add_edge!(g, 1, 3)
        add_edge!(g, 1, 4)
        add_edge!(g, 2, 4)
        layers_crossed = [[1, 2], [4, 3]]
        layers_sorted = [[1, 2], [3, 4]]
        @test count_layered_crossings(g, layers_crossed) == 1
        @test count_layered_crossings(g, layers_sorted) == 0

        result = compute_graph_layout(g; layout_mode = :acyclic)
        layers = [Int[] for _ in 0:maximum(result.node_layers)]
        for node in 1:nv(g)
            push!(layers[result.node_layers[node] + 1], node)
        end
        # Barycentric sweeps should prefer the uncrossed pairing
        @test count_layered_crossings(g, layers) == 0
    end

    @testset "single-node and Unicode label limits" begin
        g = SimpleDiGraph(1)
        fig, ax, p = dagplot(g; nlabels = ["αβγ_long_label"])
        @test fig isa Figure
        xlims = ax.xaxis.attributes.limits[]
        ylims = ax.yaxis.attributes.limits[]
        @test xlims[2] > xlims[1]
        @test ylims[2] > ylims[1]
    end
end
