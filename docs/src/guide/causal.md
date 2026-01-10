# Causal Analysis

DAGMakie provides algorithms for d-separation testing, path finding, and adjustment set computation.

## Path Finding

### All Paths

Find all paths between two nodes, ignoring edge direction:

```julia
g, labels = confounding_graph(["Z", "X", "Y"])

paths = find_all_paths(g, 2, 3)  # All paths from X to Y
for path in paths
    println(path.nodes)       # Node sequence
    println(path.directions)  # Edge directions (:forward/:backward)
end
```

### Directed (Causal) Paths

Find paths following edge direction only:

```julia
causal_paths = find_directed_paths(g, 2, 3)  # X → ... → Y
```

### Backdoor Paths

Find non-causal paths that start with an edge into the treatment:

```julia
backdoor = find_backdoor_paths(g, 2, 3)  # Treatment=X, Outcome=Y
```

## d-Separation

Test conditional independence implied by graph structure:

```julia
g, labels = confounding_graph(["Z", "X", "Y"])

# Unconditional: X and Y connected via Z
is_d_separated(g, 2, 3, Set{Int}())  # false

# Conditional on Z: X and Y are d-separated
is_d_separated(g, 2, 3, Set([1]))    # true
```

### Collider Example

```julia
g, labels = collider_graph(["X", "C", "Y"])

# Unconditionally: X and Y are d-separated (collider blocks)
is_d_separated(g, 1, 3, Set{Int}())  # true

# Conditioning on collider opens the path
is_d_separated(g, 1, 3, Set([2]))    # false
```

## Adjustment Sets

### Check Validity

```julia
g, labels = confounding_graph(["Z", "X", "Y"])

# Is {Z} a valid adjustment set for X → Y?
is_valid_adjustment_set(g, 2, 3, Set([1]))  # true

# Empty set is not valid (backdoor path open)
is_valid_adjustment_set(g, 2, 3, Set{Int}())  # false
```

### Find Minimal Adjustment Set

```julia
adj = find_minimal_adjustment_set(g, 2, 3)
# Returns Set([1]) = {Z}
```

### List All Adjustment Sets

```julia
all_sets = list_all_adjustment_sets(g, 2, 3; max_size=3)
# Returns Vector of all valid adjustment sets
```

## Ancestors and Descendants

```julia
# Find all ancestors of a node
anc = ancestors(g, 3)  # Ancestors of Y

# Find all descendants of a node
desc = descendants(g, 1)  # Descendants of Z
```

## Visualising Causal Analysis

### Backdoor Paths

```julia
# Show backdoor paths (open paths highlighted)
fig, ax, p = dagplot_backdoor(g, 2, 3, nlabels=labels)

# With adjustment set (shows blocked paths)
fig, ax, p = dagplot_backdoor(g, 2, 3,
    adjustment = Set([1]),
    nlabels = labels
)
```

### d-Separation Status

```julia
# Visualise d-separation
fig, ax, p = dagplot_dsep(g, 2, 3, Set([1]), nlabels=labels)
```

### Causal Paths

```julia
# Show directed paths from treatment to outcome
fig, ax, p = dagplot_causal_paths(g, 2, 3, nlabels=labels)
```

### Auto-Computed Adjustment

```julia
# Automatically compute and display adjustment set
fig, ax, p = dagplot_adjustment(g, 2, 3, nlabels=labels)
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
