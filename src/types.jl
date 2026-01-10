"""
Core types for DAGMakie.jl

Defines types for specifying DAG structure, node properties, and edge properties
with causal diagram semantics.
"""

# =============================================================================
# Node Types
# =============================================================================

"""
    NodeType

Enumeration of node types in causal diagrams.

# Values
- `Observed`: Standard observed variable (filled circle)
- `Latent`: Unobserved/latent variable (hollow circle or dashed outline)
- `Treatment`: Treatment/exposure variable (special highlight)
- `Outcome`: Outcome variable (special highlight)
- `Instrument`: Instrumental variable
- `Confounder`: Confounding variable
- `Mediator`: Mediating variable
- `Collider`: Collider variable
"""
@enum NodeType begin
    Observed
    Latent
    Treatment
    Outcome
    Instrument
    Confounder
    Mediator
    Collider
end

"""
    NodeSpec

Specification for a single node in a DAG.

# Fields
- `label::String`: Display label for the node
- `type::NodeType`: Type of node (determines styling)
- `color::Union{Symbol, Nothing}`: Override colour (nothing = use type default)
- `size::Union{Real, Nothing}`: Override size (nothing = use default)
- `marker::Union{Symbol, Char, Nothing}`: Override marker shape
"""
struct NodeSpec
    label::String
    type::NodeType
    color::Union{Symbol, Nothing}
    size::Union{Real, Nothing}
    marker::Union{Symbol, Char, Nothing}
end

"""
    NodeSpec(label; type=Observed, color=nothing, size=nothing, marker=nothing)

Create a node specification with the given label and optional properties.

# Examples
```julia
NodeSpec("X")  # Simple observed node
NodeSpec("U", type=Latent)  # Latent/unobserved node
NodeSpec("A", type=Treatment, color=:blue)  # Treatment with custom colour
```
"""
function NodeSpec(label::AbstractString; 
    type::NodeType = Observed,
    color::Union{Symbol, Nothing} = nothing,
    size::Union{Real, Nothing} = nothing,
    marker::Union{Symbol, Char, Nothing} = nothing
)
    return NodeSpec(String(label), type, color, size, marker)
end

# =============================================================================
# Edge Types
# =============================================================================

"""
    EdgeType

Enumeration of edge types in causal diagrams.

# Values
- `Directed`: Standard directed edge (→)
- `Bidirected`: Bidirected edge for unmeasured confounding (↔)
- `Undirected`: Undirected edge (—)
"""
@enum EdgeType begin
    Directed
    Bidirected
    Undirected
end

"""
    EdgeSpec

Specification for a single edge in a DAG.

# Fields
- `src::Int`: Source node index
- `dst::Int`: Destination node index
- `type::EdgeType`: Type of edge
- `color::Union{Symbol, String, Nothing}`: Override colour
- `width::Union{Real, Nothing}`: Override line width
- `style::Union{Symbol, Nothing}`: Line style (:solid, :dash, :dot, etc.)
- `label::Union{String, Nothing}`: Optional edge label
"""
struct EdgeSpec
    src::Int
    dst::Int
    type::EdgeType
    color::Union{Symbol, String, Nothing}
    width::Union{Real, Nothing}
    style::Union{Symbol, Nothing}
    label::Union{String, Nothing}
end

"""
    EdgeSpec(src, dst; type=Directed, color=nothing, width=nothing, style=nothing, label=nothing)

Create an edge specification.

# Examples
```julia
EdgeSpec(1, 2)  # Simple directed edge
EdgeSpec(1, 2, type=Bidirected)  # Bidirected edge (unmeasured confounding)
EdgeSpec(1, 2, style=:dash)  # Dashed edge
```
"""
function EdgeSpec(src::Int, dst::Int;
    type::EdgeType = Directed,
    color::Union{Symbol, String, Nothing} = nothing,
    width::Union{Real, Nothing} = nothing,
    style::Union{Symbol, Nothing} = nothing,
    label::Union{String, Nothing} = nothing
)
    return EdgeSpec(src, dst, type, color, width, style, label)
end

# =============================================================================
# DAG Specification
# =============================================================================

"""
    DAGSpec

Complete specification for a causal DAG visualisation.

# Fields
- `graph::AbstractGraph`: The underlying graph structure
- `nodes::Vector{NodeSpec}`: Node specifications (one per vertex)
- `edges::Vector{EdgeSpec}`: Edge specifications (overrides for specific edges)
- `title::Union{String, Nothing}`: Optional title for the DAG
"""
struct DAGSpec{G <: Graphs.AbstractGraph}
    graph::G
    nodes::Vector{NodeSpec}
    edges::Vector{EdgeSpec}
    title::Union{String, Nothing}
end

"""
    DAGSpec(g; node_labels=nothing, node_types=nothing, title=nothing)

Create a DAG specification from a graph with optional node labels and types.

# Arguments
- `g::AbstractGraph`: The graph structure
- `node_labels::Union{Vector{String}, Nothing}`: Labels for each node
- `node_types::Union{Vector{NodeType}, NodeType, Nothing}`: Types for nodes
- `title::Union{String, Nothing}`: Optional title

# Examples
```julia
g = SimpleDiGraph(3)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)

# Simple specification with labels
spec = DAGSpec(g, node_labels=["X", "Y", "Z"])

# Specification with node types
spec = DAGSpec(g, 
    node_labels=["Treatment", "Mediator", "Outcome"],
    node_types=[Treatment, Mediator, Outcome]
)
```
"""
function DAGSpec(g::Graphs.AbstractGraph;
    node_labels::Union{Vector{<:AbstractString}, Nothing} = nothing,
    node_types::Union{Vector{NodeType}, NodeType, Nothing} = nothing,
    title::Union{String, Nothing} = nothing
)
    n = Graphs.nv(g)
    
    # Create default labels if not provided
    labels = if node_labels === nothing
        [string(i) for i in 1:n]
    else
        @assert length(node_labels) == n "Number of labels must match number of nodes"
        String.(node_labels)
    end
    
    # Create node types
    types = if node_types === nothing
        fill(Observed, n)
    elseif node_types isa NodeType
        fill(node_types, n)
    else
        @assert length(node_types) == n "Number of node types must match number of nodes"
        node_types
    end
    
    # Create node specs
    nodes = [NodeSpec(labels[i], type=types[i]) for i in 1:n]
    
    # No edge overrides by default
    edges = EdgeSpec[]
    
    return DAGSpec(g, nodes, edges, title)
end

# =============================================================================
# Convenience constructors
# =============================================================================

"""
    node(label; kwargs...)

Shorthand for creating a NodeSpec.
"""
node(label::AbstractString; kwargs...) = NodeSpec(label; kwargs...)

"""
    edge(src, dst; kwargs...)

Shorthand for creating an EdgeSpec.
"""
edge(src::Int, dst::Int; kwargs...) = EdgeSpec(src, dst; kwargs...)

# =============================================================================
# Default styling for node types
# =============================================================================

"""
    default_node_color(type::NodeType)

Return the default colour for a given node type.
"""
function default_node_color(type::NodeType)
    return if type == Observed
        :lightblue
    elseif type == Latent
        :white
    elseif type == Treatment
        :lightgreen
    elseif type == Outcome
        :lightyellow
    elseif type == Instrument
        :lightpink
    elseif type == Confounder
        :lightsalmon
    elseif type == Mediator
        :lightcyan
    elseif type == Collider
        :plum
    else
        :lightgray
    end
end

"""
    default_node_marker(type::NodeType)

Return the default marker for a given node type.
"""
function default_node_marker(type::NodeType)
    return if type == Latent
        :circle  # Will be hollow via strokewidth
    else
        :circle
    end
end

"""
    default_node_strokewidth(type::NodeType)

Return the default stroke width for a given node type.
"""
function default_node_strokewidth(type::NodeType)
    return if type == Latent
        2.0  # Prominent outline for latent
    else
        1.0
    end
end
