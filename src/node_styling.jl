"""
Visual node type styling for causal diagrams.

Provides styling based on NodeType to visually distinguish different
roles in causal diagrams (observed, latent, treatment, outcome, etc.).
"""

# =============================================================================
# Marker shapes for node types
# =============================================================================

"""
    node_type_marker(type::NodeType)

Return the marker shape for a given node type.

Standard causal diagram conventions:
- `Observed`: Filled circle
- `Latent`: Circle (hollow via styling)
- `Treatment`/`Outcome`: Circle (highlighted via colour)
- `Instrument`: Diamond
- `Confounder`: Circle
- `Mediator`: Circle
- `Collider`: Circle
"""
function node_type_marker(type::NodeType)
    return if type == Latent
        :circle  # Hollow via strokewidth
    elseif type == Instrument
        :diamond
    else
        :circle
    end
end

"""
    node_type_color(type::NodeType)

Return the default fill colour for a given node type.
"""
function node_type_color(type::NodeType)
    return default_node_color(type)
end

"""
    node_type_strokewidth(type::NodeType)

Return the stroke width for a given node type.

Latent nodes have thicker stroke to emphasise the hollow appearance.
"""
function node_type_strokewidth(type::NodeType)
    return if type == Latent
        2.0
    else
        1.0
    end
end

"""
    node_type_strokecolor(type::NodeType)

Return the stroke colour for a given node type.
"""
function node_type_strokecolor(type::NodeType)
    return if type == Latent
        :gray  # More visible for hollow nodes
    else
        :black
    end
end

# =============================================================================
# Apply styling from node types
# =============================================================================

"""
    apply_node_type_styling(node_types::Vector{NodeType})

Generate styling arrays for a list of node types.

# Arguments
- `node_types`: Vector of NodeType for each node

# Returns
- Named tuple with:
  - `colors`: Vector of fill colours
  - `markers`: Vector of marker shapes
  - `strokewidths`: Vector of stroke widths
  - `strokecolors`: Vector of stroke colours
"""
function apply_node_type_styling(node_types::Vector{NodeType})
    n = length(node_types)
    return (
        colors = [node_type_color(t) for t in node_types],
        markers = [node_type_marker(t) for t in node_types],
        strokewidths = [node_type_strokewidth(t) for t in node_types],
        strokecolors = [node_type_strokecolor(t) for t in node_types]
    )
end

"""
    apply_node_type_styling(spec::DAGSpec)

Generate styling arrays from a DAGSpec.
"""
function apply_node_type_styling(spec::DAGSpec)
    types = [n.type for n in spec.nodes]
    return apply_node_type_styling(types)
end

# =============================================================================
# Convenience functions for creating typed DAGs
# =============================================================================

"""
    typed_confounding_graph()

Create a confounding graph with proper node types.

Returns DAGSpec with: Confounder → Treatment → Outcome, Confounder → Outcome
"""
function typed_confounding_graph()
    g = Graphs.SimpleDiGraph(3)
    Graphs.add_edge!(g, 1, 2)  # Z → X
    Graphs.add_edge!(g, 1, 3)  # Z → Y
    Graphs.add_edge!(g, 2, 3)  # X → Y
    
    return DAGSpec(g,
        node_labels = ["Z", "X", "Y"],
        node_types = [Confounder, Treatment, Outcome]
    )
end

"""
    typed_mediation_graph()

Create a mediation graph with proper node types.

Returns DAGSpec with: Treatment → Mediator → Outcome, Treatment → Outcome
"""
function typed_mediation_graph()
    g = Graphs.SimpleDiGraph(3)
    Graphs.add_edge!(g, 1, 2)  # X → M
    Graphs.add_edge!(g, 2, 3)  # M → Y
    Graphs.add_edge!(g, 1, 3)  # X → Y
    
    return DAGSpec(g,
        node_labels = ["X", "M", "Y"],
        node_types = [Treatment, Mediator, Outcome]
    )
end

"""
    typed_instrumental_graph()

Create an instrumental variable graph with proper node types.

Returns DAGSpec with: Instrument → Treatment → Outcome, Confounder → Treatment, Confounder → Outcome
"""
function typed_instrumental_graph()
    g = Graphs.SimpleDiGraph(4)
    Graphs.add_edge!(g, 1, 2)  # Z → X
    Graphs.add_edge!(g, 2, 3)  # X → Y
    Graphs.add_edge!(g, 4, 2)  # U → X
    Graphs.add_edge!(g, 4, 3)  # U → Y
    
    return DAGSpec(g,
        node_labels = ["Z", "X", "Y", "U"],
        node_types = [Instrument, Treatment, Outcome, Latent]
    )
end

"""
    typed_collider_graph()

Create a collider graph with proper node types.

Returns DAGSpec with: Cause₁ → Collider ← Cause₂
"""
function typed_collider_graph()
    g = Graphs.SimpleDiGraph(3)
    Graphs.add_edge!(g, 1, 2)  # A → C
    Graphs.add_edge!(g, 3, 2)  # B → C
    
    return DAGSpec(g,
        node_labels = ["A", "C", "B"],
        node_types = [Observed, Collider, Observed]
    )
end
