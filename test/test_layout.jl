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
end
