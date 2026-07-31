# SPDX-License-Identifier: MIT

"""
Dagitty-style smart node colouring from exposure / outcome ancestry.

Ancestor highlighting matches [dagitty](https://www.dagitty.net/) “highlight
ancestors”: green for ancestors of the exposure, blue for ancestors of the
outcome, red for ancestors of both, gray for variables outside that ancestral
closure. Exposure and outcome themselves use distinct fills.

Topology can be computed with Graphs alone (`smart = :ancestors`). When
CausalInference.jl is loaded, the extension prefers its `ancestors` (and can
also mark a minimal backdoor adjustment set under `smart = :adjustment`).
"""

using Graphs: AbstractGraph, nv, inneighbors

# =============================================================================
# Roles and palette
# =============================================================================

"""
    SmartNodeRole

Structural role of a node relative to a chosen exposure and outcome (dagitty-
style ancestor highlighting).
"""
@enum SmartNodeRole begin
    SmartExposure
    SmartOutcome
    SmartAncestorExposure
    SmartAncestorOutcome
    SmartAncestorBoth
    SmartIrrelevant
end

"""Dagitty-like fill for ancestors of the exposure only."""
const SMART_COLOR_ANC_EXPOSURE = :mediumseagreen

"""Dagitty-like fill for ancestors of the outcome only."""
const SMART_COLOR_ANC_OUTCOME = :steelblue

"""Dagitty-like fill for ancestors of both (often backdoor-relevant)."""
const SMART_COLOR_ANC_BOTH = :indianred

"""Fill for nodes outside the ancestral closure of exposure ∪ outcome."""
const SMART_COLOR_IRRELEVANT = :lightgray

"""Fill for the exposure / treatment node under smart colouring."""
const SMART_COLOR_EXPOSURE = :seagreen

"""Fill for the outcome node under smart colouring."""
const SMART_COLOR_OUTCOME = :royalblue

"""
    smart_node_color(role::SmartNodeRole)

Return the default fill colour for a smart node role.
"""
function smart_node_color(role::SmartNodeRole)
    return if role == SmartExposure
        SMART_COLOR_EXPOSURE
    elseif role == SmartOutcome
        SMART_COLOR_OUTCOME
    elseif role == SmartAncestorExposure
        SMART_COLOR_ANC_EXPOSURE
    elseif role == SmartAncestorOutcome
        SMART_COLOR_ANC_OUTCOME
    elseif role == SmartAncestorBoth
        SMART_COLOR_ANC_BOTH
    else
        SMART_COLOR_IRRELEVANT
    end
end

"""
    smart_label_color(role::SmartNodeRole)

Return in-node label colour for a smart role (black on light gray).
"""
function smart_label_color(role::SmartNodeRole)
    return role == SmartIrrelevant ? :black : :white
end

# =============================================================================
# Ancestor sets
# =============================================================================

"""
    ancestors_via_graphs(g, seeds) -> Set{Int}

Ancestors of `seeds` including the seeds themselves, via reverse BFS on
`inneighbors` (Graphs only; no CausalInference).
"""
function ancestors_via_graphs(g::AbstractGraph, seeds)
    n = nv(g)
    visited = falses(n)
    queue = Int[]
    for s in seeds
        1 <= s <= n || throw(ArgumentError("seed $s out of range 1:$n"))
        if !visited[s]
            visited[s] = true
            push!(queue, s)
        end
    end
    while !isempty(queue)
        v = popfirst!(queue)
        for u in inneighbors(g, v)
            if !visited[u]
                visited[u] = true
                push!(queue, u)
            end
        end
    end
    return Set(findall(visited))
end

"""
    ancestor_sets(g, treatment, outcome) -> (anc_treatment, anc_outcome)

Return ancestor sets of treatment and outcome. Uses CausalInference.jl when the
extension is loaded; otherwise Graphs reverse-BFS.
"""
function ancestor_sets(g::AbstractGraph, treatment::Int, outcome::Int)
    ext = Base.get_extension(@__MODULE__, :DAGMakieCausalInferenceExt)
    if ext !== nothing
        return ext.ancestor_sets(g, treatment, outcome)
    end
    return (
        ancestors_via_graphs(g, (treatment,)),
        ancestors_via_graphs(g, (outcome,)),
    )
end

# =============================================================================
# Role classification and styling
# =============================================================================

"""
    classify_smart_roles(g, treatment, outcome; anc_treatment=nothing, anc_outcome=nothing)

Classify each vertex into a [`SmartNodeRole`](@ref) given exposure `treatment`
and `outcome` (1-based indices).
"""
function classify_smart_roles(
    g::AbstractGraph,
    treatment::Int,
    outcome::Int;
    anc_treatment = nothing,
    anc_outcome = nothing,
)
    treatment == outcome && throw(ArgumentError("treatment and outcome must differ"))
    n = nv(g)
    (1 <= treatment <= n && 1 <= outcome <= n) || throw(ArgumentError(
        "treatment=$treatment and outcome=$outcome must be in 1:$n",
    ))

    ax, ay = if anc_treatment === nothing || anc_outcome === nothing
        ancestor_sets(g, treatment, outcome)
    else
        (anc_treatment, anc_outcome)
    end
    ax = something(anc_treatment, ax)
    ay = something(anc_outcome, ay)

    roles = Vector{SmartNodeRole}(undef, n)
    for i in 1:n
        roles[i] = if i == treatment
            SmartExposure
        elseif i == outcome
            SmartOutcome
        elseif i in ax && i in ay
            SmartAncestorBoth
        elseif i in ax
            SmartAncestorExposure
        elseif i in ay
            SmartAncestorOutcome
        else
            SmartIrrelevant
        end
    end
    return roles
end

"""
    smart_style_for_graph(g, treatment, outcome; mode=:ancestors, adjustment=nothing)

Return a named tuple of per-node styling for dagitty-like smart colouring.

# Modes
- `:ancestors` — exposure / outcome / ancestor-of-X / ancestor-of-Y / both / gray
- `:adjustment` — same, plus thicker stroke on a backdoor adjustment set
  (requires CausalInference, or pass `adjustment::Set{Int}`)
"""
function smart_style_for_graph(
    g::AbstractGraph,
    treatment::Int,
    outcome::Int;
    mode::Symbol = :ancestors,
    adjustment::Union{Nothing, Set{Int}} = nothing,
)
    mode in (:ancestors, :adjustment) || throw(ArgumentError(
        "smart mode must be :ancestors or :adjustment, got $(repr(mode))",
    ))

    roles = classify_smart_roles(g, treatment, outcome)
    colors = [smart_node_color(r) for r in roles]
    label_colors = [smart_label_color(r) for r in roles]
    strokewidths = [r == SmartExposure || r == SmartOutcome ? 2.5 : 1.0 for r in roles]
    strokecolors = fill(:black, length(roles))

    adj = adjustment
    if mode == :adjustment
        if adj === nothing
            ext = Base.get_extension(@__MODULE__, :DAGMakieCausalInferenceExt)
            ext === nothing && throw(ArgumentError(
                "smart=:adjustment requires CausalInference.jl " *
                "(`using CausalInference`) or an explicit adjustment::Set{Int}",
            ))
            adj = ext.min_backdoor_adjustment(g, treatment, outcome)
        end
        for z in adj
            if 1 <= z <= length(strokewidths) && z != treatment && z != outcome
                strokewidths[z] = 3.0
                strokecolors[z] = :darkred
            end
        end
    end

    return (
        roles = roles,
        node_color = colors,
        nlabels_color = label_colors,
        node_strokewidth = strokewidths,
        node_strokecolor = strokecolors,
        adjustment = adj === nothing ? Set{Int}() : adj,
    )
end

"""
    resolve_smart_mode(smart) -> Union{Nothing, Symbol}

Normalise a `smart` keyword to `nothing` (off) or a mode symbol.
"""
function resolve_smart_mode(smart)
    if smart === false || smart === nothing
        return nothing
    elseif smart === true || smart === :ancestors
        return :ancestors
    elseif smart === :adjustment
        return :adjustment
    else
        throw(ArgumentError(
            "smart must be false, true, :ancestors, or :adjustment; got $(repr(smart))",
        ))
    end
end

"""
    apply_smart_kwargs(g; smart, treatment, outcome, adjustment, kwargs...)

If `smart` is enabled, merge dagitty-style colours into keyword args for
[`dagplot!`](@ref). Explicit `node_color` from the caller wins.
"""
function apply_smart_kwargs(
    g::AbstractGraph;
    smart = false,
    treatment = nothing,
    outcome = nothing,
    adjustment = nothing,
    kwargs...,
)
    mode = resolve_smart_mode(smart)
    mode === nothing && return (; kwargs...)

    treatment === nothing && throw(ArgumentError(
        "smart colouring requires treatment= (exposure node index)",
    ))
    outcome === nothing && throw(ArgumentError(
        "smart colouring requires outcome= (outcome node index)",
    ))

    style = smart_style_for_graph(
        g,
        Int(treatment),
        Int(outcome);
        mode = mode,
        adjustment = adjustment,
    )

    merged = Dict{Symbol, Any}(kwargs)
    for (key, value) in (
        :node_color => style.node_color,
        :nlabels_color => style.nlabels_color,
        :node_strokewidth => style.node_strokewidth,
        :node_strokecolor => style.node_strokecolor,
    )
        if !haskey(merged, key) || merged[key] === nothing
            merged[key] = value
        end
    end
    return (; merged...)
end

"""
    dagplot_smart(g, treatment, outcome; smart=:ancestors, kwargs...)

Convenience wrapper: [`dagplot`](@ref) with dagitty-style smart node colours.
"""
function dagplot_smart(
    g::AbstractGraph,
    treatment::Int,
    outcome::Int;
    smart::Union{Bool, Symbol} = :ancestors,
    adjustment = nothing,
    kwargs...,
)
    return dagplot(
        g;
        smart = smart,
        treatment = treatment,
        outcome = outcome,
        adjustment = adjustment,
        kwargs...,
    )
end
