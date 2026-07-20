# Causal Analysis

DAGMakie provides algorithms for d-separation testing, path finding, and adjustment set computation.

```@example causal
using Graphs, DAGMakie, CairoMakie

g, labels = confounding_graph(["Z", "X", "Y"])
nothing # hide
```

## Path Finding

### All Paths

Find all paths between two nodes, ignoring edge direction:

```@example causal
paths = find_all_paths(g, 2, 3)  # All paths from X to Y
for path in paths
    println(path.nodes)       # Node sequence
    println(path.directions)  # Edge directions (:forward/:backward)
end
```

### Directed (Causal) Paths

Find paths following edge direction only:

```@example causal
causal_paths = find_directed_paths(g, 2, 3)  # X → ... → Y
println(length(causal_paths), " directed path(s)")
```

### Backdoor Paths

Find non-causal paths that start with an edge into the treatment:

```@example causal
backdoor = find_backdoor_paths(g, 2, 3)  # Treatment=X, Outcome=Y
println(length(backdoor), " backdoor path(s)")
```

## d-Separation

Test conditional independence implied by graph structure:

```@example causal
# Unconditional: X and Y connected via Z
println(is_d_separated(g, 2, 3, Set{Int}()))  # false

# Conditional on Z: X and Y are d-separated
println(is_d_separated(g, 2, 3, Set([1])))    # true
```

### Collider Example

```@example causal
g_col, labels_col = collider_graph(["X", "C", "Y"])

# Unconditionally: X and Y are d-separated (collider blocks)
println(is_d_separated(g_col, 1, 3, Set{Int}()))  # true

# Conditioning on collider opens the path
println(is_d_separated(g_col, 1, 3, Set([2])))    # false
```

## Adjustment Sets

### Check Validity

```@example causal
# Is {Z} a valid adjustment set for X → Y?
println(is_valid_adjustment_set(g, 2, 3, Set([1])))  # true

# Empty set is not valid (backdoor path open)
println(is_valid_adjustment_set(g, 2, 3, Set{Int}()))  # false
```

### Find Minimal Adjustment Set

```@example causal
adj = find_minimal_adjustment_set(g, 2, 3)
println(adj)  # Set([1]) = {Z}
```

### List All Adjustment Sets

```@example causal
all_sets = list_all_adjustment_sets(g, 2, 3; max_size=3)
println(all_sets)
```

## Ancestors and Descendants

```@example causal
# Find all ancestors of a node
anc = ancestors(g, 3)  # Ancestors of Y
println(anc)

# Find all descendants of a node
desc = descendants(g, 1)  # Descendants of Z
println(desc)
```

## Visualising Causal Analysis

### Backdoor Paths

```@example causal
# Show backdoor paths (open paths highlighted)
fig, ax, p = dagplot_backdoor(g, 2, 3, nlabels=labels)
fig
```

```@example causal
# With adjustment set (shows blocked paths)
fig, ax, p = dagplot_backdoor(g, 2, 3,
    adjustment = Set([1]),
    nlabels = labels
)
fig
```

### d-Separation Status

```@example causal
fig, ax, p = dagplot_dsep(g, 2, 3, Set([1]), nlabels=labels)
fig
```

### Causal Paths

```@example causal
fig, ax, p = dagplot_causal_paths(g, 2, 3, nlabels=labels)
fig
```

### Auto-Computed Adjustment

```@example causal
fig, ax, p = dagplot_adjustment(g, 2, 3, nlabels=labels)
fig
```

## CausalDynamics.jl Integration

When CausalDynamics.jl is loaded, additional functions become available:

```julia
using DAGMakie, CausalDynamics, Graphs

# Use CausalDynamics' d-separation
CausalDynamics.d_separated(g, 2, 3, [1])

# Get the extension module
ext = Base.get_extension(DAGMakie, :DAGMakieCausalDynamicsExt)

# Comprehensive analysis
analysis = ext.causal_analysis(g, 2, 3)
# Returns: (backdoor_paths, adjustment_set, identifiable, d_separated_unconditional)

# Formatted report
ext.print_causal_analysis(g, 2, 3, nlabels=labels)
```
