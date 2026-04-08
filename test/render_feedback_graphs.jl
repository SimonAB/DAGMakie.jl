using CairoMakie
using DAGMakie

"""
    build_layered_example()

Create a moderately complex acyclic graph to inspect the default layered DAG layout.
"""
function build_layered_example()
    g = SimpleDiGraph(8)
    add_edge!(g, 1, 4)
    add_edge!(g, 2, 4)
    add_edge!(g, 2, 5)
    add_edge!(g, 3, 5)
    add_edge!(g, 4, 6)
    add_edge!(g, 5, 6)
    add_edge!(g, 5, 7)
    add_edge!(g, 6, 8)
    add_edge!(g, 7, 8)
    labels = ["U₁", "U₂", "U₃", "M₁", "M₂", "T", "B", "Y"]
    return g, labels
end

"""
    build_feedback_example()

Create a directed cyclic graph with a three-node feedback loop and a downstream outcome.
"""
function build_feedback_example()
    g = SimpleDiGraph(5)
    add_edge!(g, 1, 2)
    add_edge!(g, 2, 3)
    add_edge!(g, 3, 1)
    add_edge!(g, 3, 4)
    add_edge!(g, 2, 5)
    add_edge!(g, 4, 5)
    labels = ["X", "Y", "Z", "W", "Outcome"]
    return g, labels
end

"""
    build_mixed_confounding_example()

Create a mixed graph where bidirected confounding should remain visibly distinct from directed flow.
"""
function build_mixed_confounding_example()
    mg = mixed_graph(4, [(1, 2), (2, 4), (1, 3), (3, 4)], [(2, 3)])
    labels = ["Z", "X", "M", "Y"]
    return mg, labels
end

"""
    build_styled_spec_example()

Create a styled `DAGSpec` for checking marker, stroke, and edge-style propagation.
"""
function build_styled_spec_example()
    g = SimpleDiGraph(4)
    add_edge!(g, 1, 2)
    add_edge!(g, 2, 4)
    add_edge!(g, 3, 4)

    nodes = [
        NodeSpec("Z"; type = Instrument, marker = :diamond, color = :mistyrose, size = 18),
        NodeSpec("X"; type = Treatment),
        NodeSpec("U"; type = Latent),
        NodeSpec("Y"; type = Outcome),
    ]
    edges = [
        EdgeSpec(1, 2; color = :firebrick, width = 2.5, style = :dash),
        EdgeSpec(3, 4; color = :slateblue, width = 2.0, style = :dot),
    ]

    return DAGSpec(g, nodes, edges, "Styled DAGSpec")
end

"""
    save_feedback_graphs(; output_dir=...)

Render a small gallery of graphs for design feedback.
"""
function save_feedback_graphs(; output_dir = joinpath(@__DIR__, "generated-feedback", "checkpoint-1"))
    mkpath(output_dir)
    CairoMakie.activate!(type = "png")

    layered_graph, layered_labels = build_layered_example()
    fig, _, _ = dagplot(layered_graph;
        nlabels = layered_labels,
        figure_size = (900, 520),
    )
    save(joinpath(output_dir, "acyclic-layered.png"), fig)

    feedback_graph, feedback_labels = build_feedback_example()
    fig, _, _ = dagplot(feedback_graph;
        nlabels = feedback_labels,
        figure_size = (900, 520),
    )
    save(joinpath(output_dir, "cyclic-feedback.png"), fig)

    mixed_graph_example, mixed_labels = build_mixed_confounding_example()
    fig, _, _ = dagplot(mixed_graph_example;
        nlabels = mixed_labels,
        figure_size = (900, 520),
    )
    save(joinpath(output_dir, "mixed-confounding.png"), fig)

    styled_spec = build_styled_spec_example()
    fig, _, _ = dagplot(styled_spec; figure_size = (900, 520))
    save(joinpath(output_dir, "styled-spec.png"), fig)

    intervention_graph, intervention_labels = confounding_graph(["Z", "X", "Y"])
    comparison = dagplot_do_comparison(intervention_graph, 2;
        nlabels = intervention_labels,
        figure_size = (1000, 420),
    )
    save(joinpath(output_dir, "intervention-comparison.png"), comparison)

    println("Wrote feedback renders to: $(output_dir)")
    return output_dir
end

save_feedback_graphs()
