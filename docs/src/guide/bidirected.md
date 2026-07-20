# Bidirected Edges

Bidirected edges (↔) represent unmeasured common causes (latent confounders) in causal diagrams.

## The MixedGraph Type

`MixedGraph` supports both directed (→) and bidirected (↔) edges:

```julia
# Create empty mixed graph
mg = MixedGraph(3)

# Add directed edges
add_directed_edge!(mg, 1, 2)  # X → Y
add_directed_edge!(mg, 2, 3)  # Y → Z

# Add bidirected edge (unmeasured confounding)
add_bidirected_edge!(mg, 1, 3)  # X ↔ Z

fig, ax, p = dagplot(mg, nlabels = ["X", "Y", "Z"])
```

## Creating Mixed Graphs

### From Scratch

```julia
mg = MixedGraph(3)
add_directed_edge!(mg, 1, 2)
add_bidirected_edge!(mg, 1, 2)
```

### From Edge Lists

```julia
mg = mixed_graph(3,
    [(1, 2), (2, 3)],    # Directed edges
    [(1, 3)]              # Bidirected edges
)
```

### From Existing DiGraph

```julia
g = SimpleDiGraph(3)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)

mg = MixedGraph(g, [(1, 3)])  # Add bidirected X ↔ Z
```

## Customising Bidirected Edges

```julia
dagplot(mg,
    nlabels = ["X", "Y", "Z"],
    bidirected_color = :red,       # Colour
    bidirected_width = 1.5,        # Line width
    bidirected_style = :dash,      # Line style (:solid, :dash, :dot)
    bidirected_curvature = 0.4,    # Arc curvature (0-1)
    bidirected_arrow_size = 10,    # Arrowhead size
)
```

## Common Confounded Patterns

DAGMakie provides convenience functions for common confounded structures.
Each uses a pedagogical default layout so bidirected arcs are not obscured;
pass `layout=...` to override.

### Simple Confounding

```julia
# X → Y with X ↔ Y (unmeasured confounder U affects both)
fig, ax, p = dagplot_confounded(["X", "Y"])
```

### Frontdoor Criterion

```julia
# X → M → Y with X ↔ Y
# The mediator M allows identification via the frontdoor criterion
fig, ax, p = dagplot_frontdoor(["X", "M", "Y"])
```

### Instrumental Variable with Confounding

```julia
# Z → X → Y with X ↔ Y
# Z is an instrument for the confounded X → Y effect
fig, ax, p = dagplot_iv_confounded(["Z", "X", "Y"])
```

### M-Bias

```julia
# X → Y with X ↔ M ↔ Y
# M is a collider that shouldn't be conditioned on
fig, ax, p = dagplot_m_bias(["X", "M", "Y"])
```

## Graph Constructors

Get the underlying mixed graph objects:

```julia
mg, labels = confounded_graph(["X", "Y"])
mg, labels = frontdoor_graph(["X", "M", "Y"])
mg, labels = iv_confounded_graph(["Z", "X", "Y"])
mg, labels = m_bias_graph(["X", "M", "Y"])
```

## Querying Bidirected Edges

```julia
# Check if bidirected edge exists
has_bidirected_edge(mg, 1, 2)  # true/false

# Get all bidirected edges
bi_edges = bidirected_edges(mg)  # Set of (i, j) tuples

# Count bidirected edges
n = num_bidirected_edges(mg)
```
