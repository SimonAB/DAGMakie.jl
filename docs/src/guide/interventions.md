# Interventions

DAGMakie supports Pearl's do-calculus operations and intervention visualisation.

## Graph Surgery

The `do(X)` operator removes all incoming edges to the intervention target:

```julia
g, labels = confounding_graph(["Z", "X", "Y"])

# Perform graph surgery: do(X)
g_do = do_surgery(g, 2)

# Original: Z → X → Y, Z → Y
# After do(X): X → Y, Z → Y (Z → X removed)
```

### Multiple Interventions

```julia
# Intervene on multiple nodes
g_do = do_surgery(g, [1, 2])  # do(Z, X)
```

## Intervention Visualisation

### Basic Intervention Plot

```julia
# Show intervention (removed edges displayed as dashed)
int = Intervention(2; label="do(X)")
fig, ax, p = dagplot_intervention(g, int, nlabels=labels)
```

### Convenience Function

```julia
# Simpler syntax
fig, ax, p = dagplot_do(g, 2, nlabels=labels)
```

### Comparison View

Side-by-side comparison of original and post-intervention graphs:

```julia
# Two-panel comparison
fig = dagplot_do_comparison(g, 2, nlabels=labels)
```

## The Intervention Type

```julia
# Create an intervention specification
int = Intervention(
    2;                  # Node to intervene on
    label = "do(X=1)",  # Display label
    value = 1.0         # Optional: intervention value
)

# Access properties
int.node    # Target node
int.label   # Display label
int.value   # Intervention value (or nothing)
```

## Causal Effect Identifiability

Check if causal effects are identifiable:

```julia
# Is P(Y | do(X)) identifiable via backdoor adjustment?
causal_effect_identifiable(g, 2, 3)  # true/false

# Does intervention remove confounding?
intervention_removes_confounding(g, 2, 3)  # true/false
```

## Identifying Confounders

```julia
# Find variables that confound the X → Y relationship
confounders = identify_confounders(g, 2, 3)
# Returns vector of node indices
```

## Causal Queries

The `CausalQuery` type represents causal effect queries:

```julia
# Create a causal query: P(Y | do(X))
query = CausalQuery(
    treatment = 2,
    outcome = 3,
    conditioning = Int[],
    interventions = [2]
)

# Check if query is identifiable
query_identifiable(g, query)

# Format as string
str = query_to_string(query, labels)
# "P(Y | do(X))"
```

## Formatting Intervention Labels

```julia
# Single intervention
label = intervention_label(2, labels)  # "do(X)"

# Multiple interventions
labels = format_intervention_labels([1, 2], labels)  # "do(Z, X)"
```

## Complete Workflow Example

```julia
using Graphs, DAGMakie, CairoMakie

# Create confounded graph
g, labels = confounding_graph(["Confounder", "Treatment", "Outcome"])

# Check identifiability
if causal_effect_identifiable(g, 2, 3)
    println("Effect is identifiable!")
    
    # Find adjustment set
    adj = find_minimal_adjustment_set(g, 2, 3)
    println("Adjust for: ", [labels[i] for i in adj])
    
    # Visualise
    fig = dagplot_do_comparison(g, 2, nlabels=labels)
    save("intervention_comparison.png", fig)
else
    println("Effect is NOT identifiable via backdoor adjustment")
    
    # Show the confounding
    confounders = identify_confounders(g, 2, 3)
    println("Confounders: ", [labels[i] for i in confounders])
end
```
