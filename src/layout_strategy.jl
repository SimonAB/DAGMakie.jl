using LinearAlgebra: norm
using Statistics: mean

"""
    DAGLayoutResult

Resolved node positions and routing metadata for a graph visualisation.

# Fields
- `positions::Vector{Point2f}`: Node positions in data coordinates
- `kind::Symbol`: One of `:acyclic`, `:cyclic`, `:mixed_acyclic`, or `:mixed_cyclic`
- `node_layers::Vector{Int}`: Layer index for each node
- `component_index::Vector{Int}`: Strongly connected component index for each node
- `components::Vector{Vector{Int}}`: Node membership for each component
- `component_layers::Vector{Int}`: Layer index for each component
- `feedback_edges::Vector{Tuple{Int, Int}}`: Directed edges routed as feedback edges
- `edge_waypoints::Dict{Tuple{Int, Int}, Vector{Point2f}}`: Extra waypoints for curved edges
"""
struct DAGLayoutResult
    positions::Vector{Point2f}
    kind::Symbol
    node_layers::Vector{Int}
    component_index::Vector{Int}
    components::Vector{Vector{Int}}
    component_layers::Vector{Int}
    feedback_edges::Vector{Tuple{Int, Int}}
    edge_waypoints::Dict{Tuple{Int, Int}, Vector{Point2f}}
end

"""
    classify_graph_kind(g)

Classify a graph by directed cyclicity and mixed-edge support.
"""
function classify_graph_kind(g::Graphs.AbstractGraph)
    return is_dag(g) ? :acyclic : :cyclic
end

function classify_graph_kind(mg::MixedGraph)
    return is_dag(mg.directed) ? :mixed_acyclic : :mixed_cyclic
end

"""
    compute_graph_layout(g; kwargs...)

Resolve deterministic positions and feedback-edge routing metadata for a graph.

If `layout` is provided, those positions are respected, but the graph is still
classified so cyclic feedback routing can be applied consistently.
"""
function compute_graph_layout(
    g::Graphs.AbstractGraph;
    layout = nothing,
    layout_mode::Symbol = :auto,
    orientation::Symbol = :lr,
    layer_gap::Real = 2.6,
    node_gap::Real = 1.8,
    component_gap::Real = 3.2,
    scc_radius::Real = 0.9,
    feedback_curvature::Real = 0.75,
)
    mode = _resolve_layout_mode(layout_mode)
    directed_kind = classify_graph_kind(g)
    actual_mode = _effective_layout_mode(mode, directed_kind)

    positions, node_layers, component_index, components, component_layers = if layout === nothing
        if actual_mode === :acyclic
            pos, layers = _compute_layered_positions(
                g;
                orientation = orientation,
                layer_gap = layer_gap,
                node_gap = node_gap,
            )
            component_index = collect(1:Graphs.nv(g))
            components = [[node] for node in 1:Graphs.nv(g)]
            component_layers = copy(layers)
            (pos, layers, component_index, components, component_layers)
        elseif actual_mode === :spring
            pos = _materialise_layout_positions(g, Spring())
            layers, component_index, components, component_layers = _graph_structure_metadata(g)
            (pos, layers, component_index, components, component_layers)
        else
            _compute_cyclic_positions(
                g;
                orientation = orientation,
                layer_gap = layer_gap,
                node_gap = node_gap,
                component_gap = component_gap,
                scc_radius = scc_radius,
            )
        end
    else
        pos = _materialise_layout_positions(g, layout)
        layers, component_index, components, component_layers = _graph_structure_metadata(g)
        (pos, layers, component_index, components, component_layers)
    end

    feedback_edges, edge_waypoints = if directed_kind === :cyclic
        _compute_feedback_routing(
            g,
            positions,
            component_index,
            components;
            feedback_curvature = feedback_curvature,
        )
    else
        (Tuple{Int, Int}[], Dict{Tuple{Int, Int}, Vector{Point2f}}())
    end

    return DAGLayoutResult(
        positions,
        directed_kind,
        node_layers,
        component_index,
        components,
        component_layers,
        feedback_edges,
        edge_waypoints,
    )
end

function compute_graph_layout(mg::MixedGraph; kwargs...)
    result = compute_graph_layout(mg.directed; kwargs...)
    return DAGLayoutResult(
        result.positions,
        classify_graph_kind(mg),
        result.node_layers,
        result.component_index,
        result.components,
        result.component_layers,
        result.feedback_edges,
        result.edge_waypoints,
    )
end

"""
    feedback_edge_mask(g, layout_result)

Return a Boolean mask, aligned with `edges(g)`, indicating which directed edges
should be rendered as curved feedback overlays.
"""
function feedback_edge_mask(g::Graphs.AbstractGraph, layout_result::DAGLayoutResult)
    feedback = Set(layout_result.feedback_edges)
    return [(Graphs.src(edge), Graphs.dst(edge)) in feedback for edge in Graphs.edges(g)]
end

"""
    edge_waypoint_vector(g, layout_result)

Materialise a per-edge waypoint vector aligned with `edges(g)` for
`GraphMakie.graphplot!`.
"""
function edge_waypoint_vector(g::Graphs.AbstractGraph, layout_result::DAGLayoutResult)
    return [
        get(layout_result.edge_waypoints, (Graphs.src(edge), Graphs.dst(edge)), Point2f[])
        for edge in Graphs.edges(g)
    ]
end

function _resolve_layout_mode(layout_mode::Symbol)
    allowed = (:auto, :acyclic, :cyclic, :spring)
    layout_mode in allowed || error("Unsupported layout_mode $(layout_mode). Expected one of $(allowed).")
    return layout_mode
end

function _effective_layout_mode(layout_mode::Symbol, directed_kind::Symbol)
    if layout_mode === :auto
        return directed_kind === :acyclic ? :acyclic : :cyclic
    end
    return layout_mode
end

function _materialise_layout_positions(g::Graphs.AbstractGraph, layout)
    raw_positions = if layout isa AbstractVector
        layout
    elseif layout isa NetworkLayout.AbstractLayout || layout isa Function
        layout(g)
    else
        error("Unsupported layout $(typeof(layout)). Provide positions, a NetworkLayout layout, or a layout function.")
    end

    return Point2f.(raw_positions)
end

function _graph_structure_metadata(g::Graphs.AbstractGraph)
    if is_dag(g)
        topo_order = Graphs.topological_sort_by_dfs(g)
        node_layers = _longest_path_layers(g, topo_order)
        component_index = collect(1:Graphs.nv(g))
        components = [[node] for node in 1:Graphs.nv(g)]
        component_layers = copy(node_layers)
        return node_layers, component_index, components, component_layers
    end

    components = _sorted_components(Graphs.strongly_connected_components(g))
    component_index = _component_index(components, Graphs.nv(g))
    condensation = _condensation_graph(g, component_index, length(components))
    component_order = Graphs.topological_sort_by_dfs(condensation)
    component_layers = _longest_path_layers(condensation, component_order)
    node_layers = [component_layers[component_index[node]] for node in 1:Graphs.nv(g)]
    return node_layers, component_index, components, component_layers
end

function _compute_layered_positions(
    g::Graphs.AbstractGraph;
    orientation::Symbol,
    layer_gap::Real,
    node_gap::Real,
)
    topo_order = Graphs.topological_sort_by_dfs(g)
    node_layers = _longest_path_layers(g, topo_order)
    layers = _collect_layers(node_layers, topo_order)
    _barycentric_sweeps!(g, layers)
    positions = _positions_from_layers(
        layers,
        Graphs.nv(g);
        orientation = orientation,
        layer_gap = layer_gap,
        node_gap = node_gap,
    )
    return positions, node_layers
end

function _compute_cyclic_positions(
    g::Graphs.AbstractGraph;
    orientation::Symbol,
    layer_gap::Real,
    node_gap::Real,
    component_gap::Real,
    scc_radius::Real,
)
    components = _sorted_components(Graphs.strongly_connected_components(g))
    component_index = _component_index(components, Graphs.nv(g))
    condensation = _condensation_graph(g, component_index, length(components))
    component_positions, component_layers = _compute_layered_positions(
        condensation;
        orientation = orientation,
        layer_gap = layer_gap * 2.2,
        node_gap = component_gap,
    )

    node_positions = Vector{Point2f}(undef, Graphs.nv(g))
    node_layers = Vector{Int}(undef, Graphs.nv(g))

    for (component_id, nodes) in enumerate(components)
        centre = component_positions[component_id]
        layer = component_layers[component_id]
        local_positions = _place_component_nodes(
            nodes,
            centre;
            orientation = orientation,
            radius = _component_radius(length(nodes), scc_radius, node_gap),
        )
        for (node, position) in zip(nodes, local_positions)
            node_positions[node] = position
            node_layers[node] = layer
        end
    end

    return node_positions, node_layers, component_index, components, component_layers
end

function _sorted_components(components::AbstractVector{<:AbstractVector{Int}})
    sorted_components = [sort!(collect(component)) for component in components]
    sort!(sorted_components, by = component -> first(component))
    return sorted_components
end

function _component_index(components::Vector{Vector{Int}}, n_nodes::Int)
    component_index = zeros(Int, n_nodes)
    for (component_id, nodes) in enumerate(components)
        for node in nodes
            component_index[node] = component_id
        end
    end
    return component_index
end

function _condensation_graph(g::Graphs.AbstractGraph, component_index::Vector{Int}, n_components::Int)
    condensation = Graphs.SimpleDiGraph(n_components)
    for edge in Graphs.edges(g)
        source_component = component_index[Graphs.src(edge)]
        destination_component = component_index[Graphs.dst(edge)]
        if source_component != destination_component
            Graphs.add_edge!(condensation, source_component, destination_component)
        end
    end
    return condensation
end

function _longest_path_layers(g::Graphs.AbstractGraph, topo_order::Vector{Int})
    node_layers = zeros(Int, Graphs.nv(g))
    for node in topo_order
        parents = Graphs.inneighbors(g, node)
        if !isempty(parents)
            node_layers[node] = maximum(node_layers[parent] + 1 for parent in parents)
        end
    end
    return node_layers
end

function _collect_layers(node_layers::Vector{Int}, stable_order::Vector{Int})
    max_layer = isempty(node_layers) ? 0 : maximum(node_layers)
    layers = [Int[] for _ in 0:max_layer]
    for node in stable_order
        push!(layers[node_layers[node] + 1], node)
    end
    return layers
end

function _barycentric_sweeps!(g::Graphs.AbstractGraph, layers::Vector{Vector{Int}}; sweeps::Int = 4)
    for _ in 1:sweeps
        order_lookup = _layer_order_lookup(layers)
        for layer_id in 2:length(layers)
            _sort_layer_by_neighbours!(layers[layer_id], Graphs.inneighbors, order_lookup, g)
        end

        order_lookup = _layer_order_lookup(layers)
        for layer_id in (length(layers) - 1):-1:1
            _sort_layer_by_neighbours!(layers[layer_id], Graphs.outneighbors, order_lookup, g)
        end
    end

    return layers
end

function _layer_order_lookup(layers::Vector{Vector{Int}})
    lookup = Dict{Int, Float64}()
    for layer in layers
        for (index, node) in enumerate(layer)
            lookup[node] = Float64(index)
        end
    end
    return lookup
end

function _sort_layer_by_neighbours!(
    layer_nodes::Vector{Int},
    neighbour_function,
    order_lookup::Dict{Int, Float64},
    g::Graphs.AbstractGraph,
)
    isempty(layer_nodes) && return layer_nodes

    scores = Dict{Int, Float64}()
    for node in layer_nodes
        neighbours = neighbour_function(g, node)
        scores[node] = if isempty(neighbours)
            order_lookup[node]
        else
            mean(order_lookup[neighbour] for neighbour in neighbours)
        end
    end

    sort!(layer_nodes, by = node -> (scores[node], order_lookup[node], node))
    return layer_nodes
end

function _positions_from_layers(
    layers::Vector{Vector{Int}},
    n_nodes::Int;
    orientation::Symbol,
    layer_gap::Real,
    node_gap::Real,
)
    positions = Vector{Point2f}(undef, n_nodes)
    for (layer_id, layer_nodes) in enumerate(layers)
        offsets = _centred_offsets(length(layer_nodes), node_gap)
        for (index, node) in enumerate(layer_nodes)
            positions[node] = _oriented_point(
                (layer_id - 1) * Float64(layer_gap),
                offsets[index],
                orientation,
            )
        end
    end
    return positions
end

function _centred_offsets(n_items::Int, spacing::Real)
    if n_items <= 1
        return [0.0]
    end

    half_width = (n_items - 1) * Float64(spacing) / 2
    return [half_width - (index - 1) * Float64(spacing) for index in 1:n_items]
end

function _oriented_point(primary::Real, secondary::Real, orientation::Symbol)
    return if orientation === :lr
        Point2f(primary, secondary)
    elseif orientation === :rl
        Point2f(-primary, secondary)
    elseif orientation === :tb
        Point2f(secondary, -primary)
    elseif orientation === :bt
        Point2f(secondary, primary)
    else
        error("Unsupported orientation $(orientation). Expected one of (:lr, :rl, :tb, :bt).")
    end
end

function _component_radius(n_nodes::Int, base_radius::Real, node_gap::Real)
    if n_nodes <= 1
        return 0.0
    elseif n_nodes == 2
        return max(Float64(base_radius), Float64(node_gap) * 0.45)
    end

    return max(Float64(base_radius), Float64(node_gap) * 0.4 * n_nodes / π)
end

function _place_component_nodes(
    nodes::Vector{Int},
    centre::Point2f;
    orientation::Symbol,
    radius::Real,
)
    n_nodes = length(nodes)
    if n_nodes == 1
        return [centre]
    elseif n_nodes == 2
        if orientation in (:lr, :rl)
            return [
                centre + Point2f(0, radius),
                centre + Point2f(0, -radius),
            ]
        else
            return [
                centre + Point2f(-radius, 0),
                centre + Point2f(radius, 0),
            ]
        end
    end

    angles = range(π / 2, step = (2π) / n_nodes, length = n_nodes)
    return [
        centre + Point2f(radius * cos(angle), radius * sin(angle))
        for angle in angles
    ]
end

function _compute_feedback_routing(
    g::Graphs.AbstractGraph,
    positions::Vector{Point2f},
    component_index::Vector{Int},
    components::Vector{Vector{Int}};
    feedback_curvature::Real,
)
    feedback_edges = Tuple{Int, Int}[]
    edge_waypoints = Dict{Tuple{Int, Int}, Vector{Point2f}}()

    component_centres = Dict(
        component_id => _mean_point([positions[node] for node in nodes])
        for (component_id, nodes) in enumerate(components)
    )

    for edge in Graphs.edges(g)
        source = Graphs.src(edge)
        destination = Graphs.dst(edge)
        component_id = component_index[source]
        if component_id != component_index[destination]
            continue
        end

        component_nodes = components[component_id]
        if length(component_nodes) <= 1
            continue
        end

        waypoint = _feedback_waypoint(
            source,
            destination,
            positions,
            component_nodes,
            component_centres[component_id];
            feedback_curvature = feedback_curvature,
        )

        push!(feedback_edges, (source, destination))
        edge_waypoints[(source, destination)] = [waypoint]
    end

    return feedback_edges, edge_waypoints
end

function _feedback_waypoint(
    source::Int,
    destination::Int,
    positions::Vector{Point2f},
    component_nodes::Vector{Int},
    component_centre::Point2f;
    feedback_curvature::Real,
)
    p1 = positions[source]
    p2 = positions[destination]
    midpoint = (p1 + p2) / 2
    chord = p2 - p1
    chord_length = max(norm(chord), 1f-3)

    if length(component_nodes) == 2
        ordered_nodes = sort(component_nodes)
        sign = (source == ordered_nodes[1] && destination == ordered_nodes[2]) ? 1.0f0 : -1.0f0
        direction = _normalised_perpendicular(chord)
        return midpoint + sign * Float32(feedback_curvature * chord_length) * direction
    end

    radial = midpoint - component_centre
    if norm(radial) <= 1f-3
        radial = _normalised_perpendicular(chord)
    else
        radial = radial / norm(radial)
    end

    return midpoint + Float32(feedback_curvature * chord_length) * radial
end

function _mean_point(points::Vector{Point2f})
    xs = [point[1] for point in points]
    ys = [point[2] for point in points]
    return Point2f(mean(xs), mean(ys))
end

function _normalised_perpendicular(vector::Point2f)
    if norm(vector) <= 1f-6
        return Point2f(0, 1)
    end

    perpendicular = Point2f(-vector[2], vector[1])
    return perpendicular / norm(perpendicular)
end
