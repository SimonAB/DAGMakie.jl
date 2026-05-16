"""
Path finding and d-separation algorithms for causal DAGs.

Implements algorithms for:
- Finding all paths between nodes
- Identifying backdoor paths
- d-separation testing
- Adjustment set computation
"""

using Graphs: AbstractGraph, nv, ne, neighbors, inneighbors, outneighbors, 
              has_edge, edges, src, dst, SimpleDiGraph

# =============================================================================
# Path Finding
# =============================================================================

"""
    PathSegment

A segment of a path, tracking the direction of traversal.

# Fields
- `node::Int`: The node in this segment
- `direction::Symbol`: `:forward` (→), `:backward` (←), or `:start`
"""
struct PathSegment
    node::Int
    direction::Symbol
end

"""
    CausalPath

A path through a DAG, tracking nodes and edge directions (forward or backward
along prehensive relations).

# Fields
- `nodes::Vector{Int}`: Sequence of nodes
- `directions::Vector{Symbol}`: Direction of each edge (:forward or :backward)
"""
struct CausalPath
    nodes::Vector{Int}
    directions::Vector{Symbol}  # Length = length(nodes) - 1
end

Base.length(p::CausalPath) = length(p.nodes)
Base.first(p::CausalPath) = first(p.nodes)
Base.last(p::CausalPath) = last(p.nodes)

"""
    path_edges(path::CausalPath)

Return the edges in a path as (src, dst) tuples.
"""
function path_edges(path::CausalPath)
    result = Tuple{Int, Int}[]
    for i in 1:(length(path.nodes) - 1)
        if path.directions[i] == :forward
            push!(result, (path.nodes[i], path.nodes[i+1]))
        else
            push!(result, (path.nodes[i+1], path.nodes[i]))
        end
    end
    return result
end

"""
    is_directed_path(path::CausalPath)

Check if all edges in the path point forward (a causal/directed path).
"""
is_directed_path(path::CausalPath) = all(d -> d == :forward, path.directions)

"""
    find_all_paths(g::AbstractGraph, source::Int, target::Int; max_length::Int=10)

Find all paths between source and target, ignoring edge direction.

Returns paths that may traverse edges in either direction, useful for
identifying backdoor paths and checking d-separation.

# Arguments
- `g`: The graph
- `source`: Starting node
- `target`: Ending node  
- `max_length`: Maximum path length to consider (default: 10)

# Returns
- Vector of `CausalPath` objects
"""
function find_all_paths(g::AbstractGraph, source::Int, target::Int; max_length::Int = 10)
    paths = CausalPath[]
    
    # DFS to find all paths
    function dfs(current::Int, path_nodes::Vector{Int}, path_dirs::Vector{Symbol}, visited::Set{Int})
        if current == target
            push!(paths, CausalPath(copy(path_nodes), copy(path_dirs)))
            return
        end
        
        if length(path_nodes) >= max_length
            return
        end
        
        # Try forward edges (current → neighbor)
        for neighbor in outneighbors(g, current)
            if neighbor ∉ visited
                push!(visited, neighbor)
                push!(path_nodes, neighbor)
                push!(path_dirs, :forward)
                dfs(neighbor, path_nodes, path_dirs, visited)
                pop!(path_nodes)
                pop!(path_dirs)
                delete!(visited, neighbor)
            end
        end
        
        # Try backward edges (neighbor → current)
        for neighbor in inneighbors(g, current)
            if neighbor ∉ visited
                push!(visited, neighbor)
                push!(path_nodes, neighbor)
                push!(path_dirs, :backward)
                dfs(neighbor, path_nodes, path_dirs, visited)
                pop!(path_nodes)
                pop!(path_dirs)
                delete!(visited, neighbor)
            end
        end
    end
    
    visited = Set([source])
    dfs(source, [source], Symbol[], visited)
    
    return paths
end

"""
    find_directed_paths(g::AbstractGraph, source::Int, target::Int; max_length::Int=10)

Find all directed (causal) paths from source to target.

Only follows edges in their natural direction.
"""
function find_directed_paths(g::AbstractGraph, source::Int, target::Int; max_length::Int = 10)
    paths = CausalPath[]
    
    function dfs(current::Int, path_nodes::Vector{Int}, visited::Set{Int})
        if current == target
            dirs = fill(:forward, length(path_nodes) - 1)
            push!(paths, CausalPath(copy(path_nodes), dirs))
            return
        end
        
        if length(path_nodes) >= max_length
            return
        end
        
        for neighbor in outneighbors(g, current)
            if neighbor ∉ visited
                push!(visited, neighbor)
                push!(path_nodes, neighbor)
                dfs(neighbor, path_nodes, visited)
                pop!(path_nodes)
                delete!(visited, neighbor)
            end
        end
    end
    
    visited = Set([source])
    dfs(source, [source], visited)
    
    return paths
end

# =============================================================================
# Backdoor Paths
# =============================================================================

"""
    is_backdoor_path(path::CausalPath, treatment::Int)

Check if a path is a backdoor path from treatment to outcome.

A backdoor path starts with an arrow **into** the treatment node—confounding
via prehension against the directed flow from treatment to outcome.
"""
function is_backdoor_path(path::CausalPath, treatment::Int)
    if isempty(path.directions)
        return false
    end
    # First node should be treatment, and first edge should point backward (into treatment)
    return path.nodes[1] == treatment && path.directions[1] == :backward
end

"""
    find_backdoor_paths(g::AbstractGraph, treatment::Int, outcome::Int; max_length::Int=10)

Find all backdoor paths from treatment to outcome.

Backdoor paths are non-causal paths that start with an edge pointing INTO
the treatment variable.

# Arguments
- `g`: The DAG
- `treatment`: Treatment/exposure node
- `outcome`: Outcome node
- `max_length`: Maximum path length

# Returns
- Vector of `CausalPath` representing backdoor paths
"""
function find_backdoor_paths(g::AbstractGraph, treatment::Int, outcome::Int; max_length::Int = 10)
    all_paths = find_all_paths(g, treatment, outcome; max_length = max_length)
    return filter(p -> is_backdoor_path(p, treatment), all_paths)
end

# =============================================================================
# d-Separation
# =============================================================================

"""
    is_collider(path::CausalPath, index::Int)

Check if the node at `index` in the path is a collider (← node →).

A collider has edges pointing INTO it from both adjacent nodes.
"""
function is_collider(path::CausalPath, index::Int)
    if index <= 1 || index >= length(path.nodes)
        return false
    end
    # Check if both adjacent edges point INTO this node
    # directions[i] is the direction from nodes[i] to nodes[i+1]
    incoming_from_left = path.directions[index - 1] == :forward
    incoming_from_right = path.directions[index] == :backward
    return incoming_from_left && incoming_from_right
end

"""
    is_path_blocked(path::CausalPath, conditioned::Set{Int})

Check if a path is blocked given a conditioning set.

A path is blocked if:
1. It contains a non-collider that is in the conditioning set, OR
2. It contains a collider where neither the collider nor its descendants
   are in the conditioning set.

Note: This simplified version doesn't check descendants of colliders.
For full d-separation, use `is_d_separated`.
"""
function is_path_blocked(path::CausalPath, conditioned::Set{Int})
    for i in 2:(length(path.nodes) - 1)
        node = path.nodes[i]
        if is_collider(path, i)
            # Collider: path is blocked unless collider (or descendant) is conditioned
            # Simplified: only check the collider itself
            if node ∉ conditioned
                return true  # Blocked at collider
            end
        else
            # Non-collider (chain or fork): blocked if conditioned
            if node ∈ conditioned
                return true  # Blocked at non-collider
            end
        end
    end
    return false
end

"""
    descendants(g::AbstractGraph, node::Int)

Find all descendants of a node (nodes reachable via directed paths).
"""
function descendants(g::AbstractGraph, node::Int)
    desc = Set{Int}()
    queue = [node]
    while !isempty(queue)
        current = popfirst!(queue)
        for child in outneighbors(g, current)
            if child ∉ desc
                push!(desc, child)
                push!(queue, child)
            end
        end
    end
    return desc
end

"""
    ancestors(g::AbstractGraph, node::Int)

Find all ancestors of a node (nodes that can reach it via directed paths).
"""
function ancestors(g::AbstractGraph, node::Int)
    anc = Set{Int}()
    queue = [node]
    while !isempty(queue)
        current = popfirst!(queue)
        for parent in inneighbors(g, current)
            if parent ∉ anc
                push!(anc, parent)
                push!(queue, parent)
            end
        end
    end
    return anc
end

"""
    is_d_separated(g::AbstractGraph, x::Int, y::Int, z::Set{Int}; max_length::Int=10)

Test if X and Y are d-separated given conditioning set Z.

Two nodes are d-separated if all paths between them are blocked.

# Arguments
- `g`: The DAG
- `x`: First node
- `y`: Second node
- `z`: Conditioning set
- `max_length`: Maximum path length to consider

# Returns
- `true` if X ⊥ Y | Z (d-separated)
- `false` if X and Y are d-connected given Z

# Examples
```julia
# Fork: X ← Z → Y
g = SimpleDiGraph(3)
add_edge!(g, 2, 1)  # Z → X
add_edge!(g, 2, 3)  # Z → Y

is_d_separated(g, 1, 3, Set{Int}())      # false (connected via Z)
is_d_separated(g, 1, 3, Set([2]))        # true (blocked by conditioning on Z)
```
"""
function is_d_separated(g::AbstractGraph, x::Int, y::Int, z::Set{Int}; max_length::Int = 10)
    # Find descendants of all conditioned nodes (for collider unblocking)
    conditioned_and_descendants = copy(z)
    for node in z
        union!(conditioned_and_descendants, descendants(g, node))
    end
    
    paths = find_all_paths(g, x, y; max_length = max_length)
    
    for path in paths
        blocked = false
        for i in 2:(length(path.nodes) - 1)
            node = path.nodes[i]
            if is_collider(path, i)
                # Collider: blocked unless collider or descendant is conditioned
                if node ∉ conditioned_and_descendants
                    blocked = true
                    break
                end
            else
                # Non-collider: blocked if conditioned
                if node ∈ z
                    blocked = true
                    break
                end
            end
        end
        
        if !blocked
            return false  # Found an open path
        end
    end
    
    return true  # All paths blocked
end

"""
    is_d_separated(g::AbstractGraph, x::Int, y::Int, z::Vector{Int}; kwargs...)

Convenience method accepting a Vector instead of Set.
"""
function is_d_separated(g::AbstractGraph, x::Int, y::Int, z::Vector{Int}; kwargs...)
    return is_d_separated(g, x, y, Set(z); kwargs...)
end

"""
    d_separated_from(g::AbstractGraph, x::Int, z::Set{Int}; max_length::Int=10)

Find all nodes that are d-separated from x given conditioning set z.
"""
function d_separated_from(g::AbstractGraph, x::Int, z::Set{Int}; max_length::Int = 10)
    separated = Int[]
    for y in 1:nv(g)
        if y != x && y ∉ z && is_d_separated(g, x, y, z; max_length = max_length)
            push!(separated, y)
        end
    end
    return separated
end

# =============================================================================
# Adjustment Sets
# =============================================================================

"""
    blocks_all_backdoor_paths(g::AbstractGraph, treatment::Int, outcome::Int, 
                               adjustment::Set{Int}; max_length::Int=10)

Check if an adjustment set blocks all backdoor paths.
"""
function blocks_all_backdoor_paths(
    g::AbstractGraph, 
    treatment::Int, 
    outcome::Int, 
    adjustment::Set{Int};
    max_length::Int = 10
)
    backdoor_paths = find_backdoor_paths(g, treatment, outcome; max_length = max_length)
    
    # Check each backdoor path is blocked
    conditioned_and_descendants = copy(adjustment)
    for node in adjustment
        union!(conditioned_and_descendants, descendants(g, node))
    end
    
    for path in backdoor_paths
        blocked = false
        for i in 2:(length(path.nodes) - 1)
            node = path.nodes[i]
            if is_collider(path, i)
                if node ∉ conditioned_and_descendants
                    blocked = true
                    break
                end
            else
                if node ∈ adjustment
                    blocked = true
                    break
                end
            end
        end
        
        if !blocked
            return false  # Found an open backdoor path
        end
    end
    
    return true
end

"""
    is_valid_adjustment_set(g::AbstractGraph, treatment::Int, outcome::Int, 
                            adjustment::Set{Int}; max_length::Int=10)

Check if a set of variables is a valid adjustment set for the causal effect
of treatment on outcome.

A valid adjustment set must:
1. Block all backdoor paths
2. Not include the treatment or outcome
3. Not include any descendants of treatment on a causal path to outcome

# Arguments
- `g`: The DAG
- `treatment`: Treatment variable
- `outcome`: Outcome variable
- `adjustment`: Proposed adjustment set
- `max_length`: Maximum path length to consider

# Returns
- `true` if the adjustment set satisfies the backdoor criterion
"""
function is_valid_adjustment_set(
    g::AbstractGraph, 
    treatment::Int, 
    outcome::Int, 
    adjustment::Set{Int};
    max_length::Int = 10
)
    # Cannot include treatment or outcome
    if treatment ∈ adjustment || outcome ∈ adjustment
        return false
    end
    
    # Cannot include descendants of treatment that are on causal paths
    treatment_descendants = descendants(g, treatment)
    causal_paths = find_directed_paths(g, treatment, outcome; max_length = max_length)
    nodes_on_causal_paths = Set{Int}()
    for path in causal_paths
        for node in path.nodes[2:end-1]  # Exclude treatment and outcome
            push!(nodes_on_causal_paths, node)
        end
    end
    
    # Check no adjustment variable is a descendant of treatment on causal path
    for adj in adjustment
        if adj ∈ nodes_on_causal_paths
            return false
        end
    end
    
    # Must block all backdoor paths
    return blocks_all_backdoor_paths(g, treatment, outcome, adjustment; max_length = max_length)
end

"""
    is_valid_adjustment_set(g::AbstractGraph, treatment::Int, outcome::Int, 
                            adjustment::Vector{Int}; kwargs...)

Convenience method accepting a Vector instead of Set.
"""
function is_valid_adjustment_set(g::AbstractGraph, treatment::Int, outcome::Int, 
                                  adjustment::Vector{Int}; kwargs...)
    return is_valid_adjustment_set(g, treatment, outcome, Set(adjustment); kwargs...)
end

"""
    find_minimal_adjustment_set(g::AbstractGraph, treatment::Int, outcome::Int;
                                 max_length::Int=10)

Find a minimal adjustment set for the backdoor criterion.

Returns the smallest set of variables that blocks all backdoor paths.
Uses a greedy algorithm - may not find the globally optimal solution.

# Returns
- Set of node indices forming a minimal adjustment set, or `nothing` if
  no valid adjustment set exists
"""
function find_minimal_adjustment_set(
    g::AbstractGraph, 
    treatment::Int, 
    outcome::Int;
    max_length::Int = 10
)
    # Candidates: ancestors of treatment or outcome, excluding treatment/outcome
    candidates = union(ancestors(g, treatment), ancestors(g, outcome))
    setdiff!(candidates, Set([treatment, outcome]))
    
    # Also exclude descendants of treatment
    treatment_descendants = descendants(g, treatment)
    setdiff!(candidates, treatment_descendants)
    
    # Check if empty set works (no confounding)
    if is_valid_adjustment_set(g, treatment, outcome, Set{Int}(); max_length = max_length)
        return Set{Int}()
    end
    
    # Try single variables
    for c in candidates
        adj = Set([c])
        if is_valid_adjustment_set(g, treatment, outcome, adj; max_length = max_length)
            return adj
        end
    end
    
    # Try pairs
    candidates_vec = collect(candidates)
    for i in 1:length(candidates_vec)
        for j in (i+1):length(candidates_vec)
            adj = Set([candidates_vec[i], candidates_vec[j]])
            if is_valid_adjustment_set(g, treatment, outcome, adj; max_length = max_length)
                return adj
            end
        end
    end
    
    # Try the full candidate set
    if is_valid_adjustment_set(g, treatment, outcome, candidates; max_length = max_length)
        return candidates
    end
    
    return nothing  # No valid adjustment set found
end

"""
    list_all_adjustment_sets(g::AbstractGraph, treatment::Int, outcome::Int;
                              max_size::Int=5, max_length::Int=10)

List all valid adjustment sets up to a given size.

# Arguments
- `g`: The DAG
- `treatment`: Treatment variable
- `outcome`: Outcome variable
- `max_size`: Maximum size of adjustment sets to consider
- `max_length`: Maximum path length

# Returns
- Vector of Sets, each a valid adjustment set
"""
function list_all_adjustment_sets(
    g::AbstractGraph, 
    treatment::Int, 
    outcome::Int;
    max_size::Int = 5,
    max_length::Int = 10
)
    # Candidates
    candidates = union(ancestors(g, treatment), ancestors(g, outcome))
    setdiff!(candidates, Set([treatment, outcome]))
    treatment_descendants = descendants(g, treatment)
    setdiff!(candidates, treatment_descendants)
    
    candidates_vec = collect(candidates)
    valid_sets = Set{Int}[]
    
    # Check empty set
    if is_valid_adjustment_set(g, treatment, outcome, Set{Int}(); max_length = max_length)
        push!(valid_sets, Set{Int}())
    end
    
    # Generate all subsets up to max_size
    for size in 1:min(max_size, length(candidates_vec))
        for combo in combinations(candidates_vec, size)
            adj = Set(combo)
            if is_valid_adjustment_set(g, treatment, outcome, adj; max_length = max_length)
                push!(valid_sets, adj)
            end
        end
    end
    
    return valid_sets
end

# Simple combinations generator
function combinations(arr::Vector{T}, k::Int) where T
    n = length(arr)
    result = Vector{T}[]
    
    function generate(start::Int, combo::Vector{T})
        if length(combo) == k
            push!(result, copy(combo))
            return
        end
        for i in start:n
            push!(combo, arr[i])
            generate(i + 1, combo)
            pop!(combo)
        end
    end
    
    generate(1, T[])
    return result
end
