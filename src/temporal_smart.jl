# SPDX-License-Identifier: MIT

"""
Temporal propagation of dagitty-style roles across variable rows in time-unrolled DAGs.

Node order matches CausalDynamics [`unroll_temporal_dag`](@ref): outer loop over
occasion `t`, inner loop over variable index `v` (see [`time_indexed_layout`](@ref)).
"""

"""
    temporal_node_index(n_variables, variable, time) -> Int

Linear node index for `(variable, time)` in a time-unrolled graph.
"""
function temporal_node_index(n_variables::Integer, variable::Integer, time::Integer)
    n_variables = Int(n_variables)
    variable = Int(variable)
    time = Int(time)
    n_variables >= 1 || throw(ArgumentError("n_variables must be ≥ 1, got $n_variables"))
    1 <= variable <= n_variables ||
        throw(ArgumentError("variable index $variable must be in 1:$n_variables"))
    time >= 1 || throw(ArgumentError("time index $time must be ≥ 1"))
    return (time - 1) * n_variables + variable
end

"""
    temporal_variable_time(node, n_variables) -> (variable, time)

Inverse of [`temporal_node_index`](@ref) for 1-based node indices.
"""
function temporal_variable_time(node::Integer, n_variables::Integer)
    n_variables = Int(n_variables)
    node = Int(node)
    n_variables >= 1 || throw(ArgumentError("n_variables must be ≥ 1, got $n_variables"))
    node >= 1 || throw(ArgumentError("node index must be ≥ 1, got $node"))
    time = div(node - 1, n_variables) + 1
    variable = (node - 1) % n_variables + 1
    return (variable, time)
end

const _SMART_ROLE_RANK = Dict(
    SmartIrrelevant => 0,
    SmartAncestorOutcome => 1,
    SmartAncestorExposure => 2,
    SmartAncestorBoth => 3,
    SmartOutcome => 4,
    SmartExposure => 5,
)

"""
    propagate_temporal_smart_roles(
        roles, n_variables, n_times; exposure, outcome
    ) -> Vector{SmartNodeRole}

Propagate per-node [`SmartNodeRole`](@ref)s across each **variable row** so
`Treatment[t]` / `Outcome[t]` styling applies at every occasion on the estimand
path (see [issue #5](https://github.com/SimonAB/DAGMakie.jl/issues/5)).

- The exposure variable row → all `SmartExposure`
- The outcome variable row → all `SmartOutcome`
- Other rows → strongest ancestral role among occasions (both > X-only > Y-only > gray)
"""
function propagate_temporal_smart_roles(
    roles::AbstractVector{SmartNodeRole},
    n_variables::Integer,
    n_times::Integer;
    exposure::Int,
    outcome::Int,
)
    n_variables = Int(n_variables)
    n_times = Int(n_times)
    length(roles) == n_variables * n_times || throw(ArgumentError(
        "roles length $(length(roles)) must equal n_variables×n_times = $(n_variables * n_times)",
    ))
    v_e, _ = temporal_variable_time(exposure, n_variables)
    v_y, _ = temporal_variable_time(outcome, n_variables)
    out = copy(roles)
    for v in 1:n_variables
        indices = [temporal_node_index(n_variables, v, t) for t in 1:n_times]
        if v == v_e
            for i in indices
                out[i] = SmartExposure
            end
        elseif v == v_y
            for i in indices
                out[i] = SmartOutcome
            end
        else
            best = SmartIrrelevant
            best_rank = 0
            for i in indices
                rank = _SMART_ROLE_RANK[roles[i]]
                if rank > best_rank
                    best_rank = rank
                    best = roles[i]
                end
            end
            for i in indices
                out[i] = best
            end
        end
    end
    return out
end

"""
    _style_tuple_from_roles(roles; adjustment=nothing, exposure, outcome) -> NamedTuple

Build dagplot keyword styling from propagated smart roles.
"""
function _style_tuple_from_roles(
    roles::Vector{SmartNodeRole};
    adjustment::Union{Nothing, Set{Int}} = nothing,
    exposure::Int,
    outcome::Int,
)
    colors = [smart_node_color(r) for r in roles]
    label_colors = [smart_label_color(r) for r in roles]
    strokewidths = [r == SmartExposure || r == SmartOutcome ? 2.5 : 1.0 for r in roles]
    strokecolors = fill(:black, length(roles))
    adj = adjustment === nothing ? Set{Int}() : adjustment
    for z in adj
        if 1 <= z <= length(strokewidths) && z != exposure && z != outcome
            strokewidths[z] = 3.0
            strokecolors[z] = :darkred
        end
    end
    return (
        roles = roles,
        node_color = colors,
        nlabels_color = label_colors,
        node_strokewidth = strokewidths,
        node_strokecolor = strokecolors,
        adjustment = adj,
    )
end

"""
    smart_style_for_temporal_graph(
        g, n_variables, n_times, exposure, outcome; mode=:ancestors, adjustment=nothing
    ) -> NamedTuple

Dagitty-style colours on a time-unrolled graph, with roles propagated across
variable rows (see [`propagate_temporal_smart_roles`](@ref)).
"""
function smart_style_for_temporal_graph(
    g::AbstractGraph,
    n_variables::Integer,
    n_times::Integer,
    exposure::Int,
    outcome::Int;
    mode::Symbol = :ancestors,
    adjustment::Union{Nothing, Set{Int}} = nothing,
)
    mode = mode === :ancestors_temporal ? :ancestors : mode
    base = smart_style_for_graph(g, exposure, outcome; mode = mode, adjustment = adjustment)
    roles = propagate_temporal_smart_roles(
        base.roles, n_variables, n_times;
        exposure = exposure, outcome = outcome,
    )
    style = _style_tuple_from_roles(
        roles;
        adjustment = base.adjustment,
        exposure = exposure,
        outcome = outcome,
    )
    if mode == :adjustment && !isempty(style.adjustment)
        adj_rows = Set{Int}()
        for z in style.adjustment
            v, _ = temporal_variable_time(z, n_variables)
            push!(adj_rows, v)
        end
        strokewidths = copy(style.node_strokewidth)
        strokecolors = copy(style.node_strokecolor)
        for v in adj_rows
            for t in 1:Int(n_times)
                z = temporal_node_index(n_variables, v, t)
                if z != exposure && z != outcome
                    strokewidths[z] = 3.0
                    strokecolors[z] = :darkred
                end
            end
        end
        return merge(style, (;
            node_strokewidth = strokewidths,
            node_strokecolor = strokecolors,
        ))
    end
    return style
end

"""
    resolve_temporal_exposure_outcome(exposure, outcome, n_variables) -> (Int, Int)

Accept node indices (`Int`) or `(variable, time)` tuples for exposure / outcome.
"""
function resolve_temporal_exposure_outcome(
    exposure,
    outcome,
    n_variables::Integer,
)
    exp_node = if exposure isa Integer
        Int(exposure)
    elseif exposure isa Tuple && length(exposure) == 2
        temporal_node_index(n_variables, exposure[1], exposure[2])
    else
        throw(ArgumentError(
            "exposure must be a node index (Int) or (variable, time) tuple; got $(typeof(exposure))",
        ))
    end
    out_node = if outcome isa Integer
        Int(outcome)
    elseif outcome isa Tuple && length(outcome) == 2
        temporal_node_index(n_variables, outcome[1], outcome[2])
    else
        throw(ArgumentError(
            "outcome must be a node index (Int) or (variable, time) tuple; got $(typeof(outcome))",
        ))
    end
    return (exp_node, out_node)
end

"""
    temporal_role_styling(
        g, n_variables, n_times; exposure, outcome, color_by=:ancestors, adjustment=nothing
    ) -> NamedTuple

Convenience wrapper returning `(node_color, nlabels_color, node_strokewidth,
node_strokecolor, roles, adjustment)` for manual `dagplot` / `dagplot_time_indexed`
calls ([#5](https://github.com/SimonAB/DAGMakie.jl/issues/5)).

`exposure` and `outcome` may be node indices or `(variable_index, time_index)` pairs.
"""
function temporal_role_styling(
    g::AbstractGraph,
    n_variables::Integer,
    n_times::Integer;
    exposure,
    outcome,
    color_by = :ancestors,
    smart = nothing,
    adjustment = nothing,
)
    mode = resolve_color_by(; color_by = color_by, smart = smart)
    mode === nothing && throw(ArgumentError("temporal_role_styling requires color_by=:ancestors, :ancestors_temporal, or :adjustment"))
    mode = mode === :ancestors_temporal ? :ancestors : mode
    mode in (:ancestors, :adjustment) || throw(ArgumentError(
        "temporal_role_styling requires color_by=:ancestors, :ancestors_temporal, or :adjustment; got $(repr(mode))",
    ))
    exp_node, out_node = resolve_temporal_exposure_outcome(exposure, outcome, n_variables)
    return smart_style_for_temporal_graph(
        g, n_variables, n_times, exp_node, out_node;
        mode = mode,
        adjustment = adjustment,
    )
end

"""
    apply_temporal_smart_kwargs(
        g, n_variables, n_times; color_by, exposure, outcome, adjustment, kwargs...
    ) -> NamedTuple

Like [`apply_smart_kwargs`](@ref), but propagates exposure / outcome / ancestor
roles across variable rows on time-unrolled graphs ([#5](https://github.com/SimonAB/DAGMakie.jl/issues/5)).
"""
function apply_temporal_smart_kwargs(
    g::AbstractGraph,
    n_variables::Integer,
    n_times::Integer;
    color_by = nothing,
    smart = nothing,
    exposure = nothing,
    treatment = nothing,
    outcome = nothing,
    adjustment = nothing,
    kwargs...,
)
    mode = resolve_color_by(; color_by = color_by, smart = smart)
    mode === nothing && return (; kwargs...)

    exp_input = something(exposure, treatment)
    exp_input === nothing && throw(ArgumentError(
        "color_by colouring requires exposure= (or treatment=) node index or (variable, time) tuple",
    ))
    outcome === nothing && throw(ArgumentError(
        "color_by colouring requires outcome= node index or (variable, time) tuple",
    ))

    exp_node, out_node = resolve_temporal_exposure_outcome(exp_input, outcome, n_variables)
    style = smart_style_for_temporal_graph(
        g, n_variables, n_times, exp_node, out_node;
        mode = mode === :ancestors_temporal ? :ancestors : mode,
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
    if resolve_outer_labels(
            get(merged, :label_position, DEFAULT_LABEL_POSITION);
            auto_align_labels = get(merged, :auto_align_labels, nothing),
        )
        user_label_color = get(kwargs, :nlabels_color, nothing)
        if user_label_color === nothing
            merged[:nlabels_color] = OUTER_LABEL_COLOR
        end
    end
    return (; merged...)
end

export temporal_node_index, temporal_variable_time
export propagate_temporal_smart_roles, smart_style_for_temporal_graph
export temporal_role_styling, resolve_temporal_exposure_outcome
export apply_temporal_smart_kwargs
