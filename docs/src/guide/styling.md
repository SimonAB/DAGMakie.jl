# Node Types & Styling

DAGMakie provides semantic node types for causal diagrams, with automatic styling.

## Node Types

The `NodeType` enum defines common roles in causal diagrams:

```julia
@enum NodeType begin
    Observed    # Standard observed variable
    Latent      # Unobserved/latent variable
    Treatment   # Treatment/exposure variable
    Outcome     # Outcome variable
    Instrument  # Instrumental variable
    Confounder  # Confounding variable
    Mediator    # Mediating variable
    Collider    # Collider variable
end
```

## Using DAGSpec

The `DAGSpec` type combines a graph with node specifications:

```julia
g = SimpleDiGraph(4)
add_edge!(g, 1, 2)  # Z → X
add_edge!(g, 1, 3)  # Z → Y
add_edge!(g, 2, 3)  # X → Y

spec = DAGSpec(g,
    node_labels = ["Instrument", "Treatment", "Outcome", "Confounder"],
    node_types = [Instrument, Treatment, Outcome, Confounder]
)

fig, ax, p = dagplot(spec)
```

## Node Type Styling

Each node type has default styling:

| Type | Default Colour | Use Case |
|------|---------------|----------|
| `Observed` | Light blue | Standard observed variables |
| `Latent` | White | Unobserved variables |
| `Treatment` | Light green | Exposure/intervention variables |
| `Outcome` | Light yellow | Response variables |
| `Instrument` | Light pink | Instrumental variables |
| `Confounder` | Light salmon | Confounding variables |
| `Mediator` | Light cyan | Mediating variables |
| `Collider` | Plum | Collider variables |

## Custom Styling Functions

Override default styling:

```julia
# Get default colour for a type
color = default_node_color(Treatment)  # :lightgreen

# Get default marker
marker = default_node_marker(Latent)   # :circle

# Get default stroke width
stroke = default_node_strokewidth(Latent)  # 2.0 (prominent outline)
```

## Apply Node Type Styling

Apply styling to existing graphs:

```julia
g = SimpleDiGraph(3)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)

types = [Confounder, Treatment, Outcome]
colors, markers, strokewidths = apply_node_type_styling(types)

dagplot(g,
    nlabels = ["Z", "X", "Y"],
    node_color = colors,
    node_marker = markers,
    node_strokewidth = strokewidths,
)
```

## Pre-typed Graph Constructors

Create graphs with pre-assigned node types:

```julia
# Confounding pattern with types
spec = typed_confounding_graph(["Z", "X", "Y"])
fig, ax, p = dagplot(spec)

# Mediation pattern with types
spec = typed_mediation_graph(["X", "M", "Y"])

# Instrumental variable pattern
spec = typed_instrumental_graph(["Z", "X", "Y", "U"])

# Collider pattern
spec = typed_collider_graph(["X", "C", "Y"])
```

## Style Presets

DAGMakie provides style presets for different contexts:

```julia
# Standard academic paper style
style = default_style()

# Minimal style (thin lines, small nodes)
style = minimal_style()

# Bold style (thick lines, large nodes)
style = bold_style()

# Presentation style (extra large for slides)
style = presentation_style()
```
