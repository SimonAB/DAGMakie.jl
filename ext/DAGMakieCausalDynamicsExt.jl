"""
DAGMakie extension for CausalDynamics.jl integration.

Provides seamless plotting of CausalDynamics SCM types and integration
with CausalDynamics' causal analysis functions.
"""
module DAGMakieCausalDynamicsExt

using DAGMakie
using CausalDynamics
using Graphs: AbstractGraph, SimpleDiGraph, nv, ne, edges, src, dst, add_edge!

# =============================================================================
# SCM Plotting
# =============================================================================

"""
    dagplot(scm::CausalDynamics.AbstractSCM; kwargs...)

Plot a Structural Causal Model's causal graph.

# Arguments
- `scm`: A CausalDynamics SCM (GraphSCM or SymbolicSCM)
- `kwargs...`: Additional arguments passed to dagplot

# Examples
```julia
using DAGMakie, CausalDynamics, CairoMakie, Graphs

g = DiGraph(3)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)

scm = GraphSCM(g, Dict{Int,Function}(), Set{Int}())
fig, ax, p = dagplot(scm, nlabels=["X", "Y", "Z"])
```
"""
function DAGMakie.dagplot(scm::CausalDynamics.AbstractSCM; kwargs...)
    return DAGMakie.dagplot(scm.graph; kwargs...)
end

"""
    dagplot!(ax, scm::CausalDynamics.AbstractSCM; kwargs...)

Plot an SCM's graph into an existing axis.
"""
function DAGMakie.dagplot!(ax, scm::CausalDynamics.AbstractSCM; kwargs...)
    return DAGMakie.dagplot!(ax, scm.graph; kwargs...)
end

# =============================================================================
# d-Separation Integration
# =============================================================================

"""
    dagplot_dsep_cd(g, x, y, z; kwargs...)

Plot d-separation status using CausalDynamics' d_separated function.

# Arguments
- `g`: The graph (can be CausalDynamics or Graphs.jl graph)
- `x`: First node
- `y`: Second node  
- `z`: Conditioning set (Vector or Set)
- `kwargs...`: Additional dagplot arguments
"""
function dagplot_dsep_cd(
    g::AbstractGraph,
    x::Int,
    y::Int,
    z;
    x_color = :lightblue,
    y_color = :lightblue,
    z_color = :lightsalmon,
    kwargs...
)
    z_vec = z isa Set ? collect(z) : z
    separated = CausalDynamics.d_separated(g, x, y, z_vec)
    
    # Highlight nodes
    nodes = [x, y, z_vec...]
    colors = [x_color, y_color, fill(z_color, length(z_vec))...]
    
    highlight = DAGMakie.HighlightSpec(
        nodes = nodes,
        node_colors = colors,
        edges = Tuple{Int, Int}[],
        edge_colors = [],
        labels = String[]
    )
    
    fig, ax, p = DAGMakie.dagplot_highlighted(g, highlight; kwargs...)
    
    status_text = separated ? "X ⊥ Y | Z (d-separated)" : "X ↛⊥ Y | Z (d-connected)"
    ax.title = status_text
    
    return fig, ax, p
end

# =============================================================================
# Backdoor Analysis Integration
# =============================================================================

"""
    dagplot_backdoor_cd(g, treatment, outcome; kwargs...)

Plot backdoor paths using CausalDynamics' backdoor analysis.

Highlights the backdoor adjustment set computed by CausalDynamics.

# Arguments
- `g`: The causal graph
- `treatment`: Treatment node index
- `outcome`: Outcome node index
- `kwargs...`: Additional dagplot arguments
"""
function dagplot_backdoor_cd(
    g::AbstractGraph,
    treatment::Int,
    outcome::Int;
    treatment_color = :lightgreen,
    outcome_color = :lightyellow,
    adjustment_color = :lightsalmon,
    kwargs...
)
    # Use CausalDynamics to find adjustment set
    adj_set = CausalDynamics.backdoor_adjustment_set(g, treatment, outcome)
    
    if adj_set === nothing
        adj_set = Set{Int}()
    end
    
    return DAGMakie.dagplot_backdoor(g, treatment, outcome;
        adjustment = adj_set,
        treatment_color = treatment_color,
        outcome_color = outcome_color,
        adjustment_color = adjustment_color,
        kwargs...
    )
end

"""
    dagplot_adjustment_cd(g, treatment, outcome; kwargs...)

Plot a DAG with CausalDynamics-computed adjustment set highlighted.

# Arguments
- `g`: The causal graph
- `treatment`: Treatment node
- `outcome`: Outcome node
"""
function dagplot_adjustment_cd(
    g::AbstractGraph,
    treatment::Int,
    outcome::Int;
    treatment_color = :lightgreen,
    outcome_color = :lightyellow,
    adjustment_color = :lightsalmon,
    kwargs...
)
    adj_set = CausalDynamics.backdoor_adjustment_set(g, treatment, outcome)
    
    if adj_set === nothing || isempty(adj_set)
        # No adjustment needed or not possible
        nodes = [treatment, outcome]
        colors = [treatment_color, outcome_color]
    else
        nodes = [treatment, outcome, collect(adj_set)...]
        colors = [treatment_color, outcome_color, fill(adjustment_color, length(adj_set))...]
    end
    
    highlight = DAGMakie.HighlightSpec(
        nodes = nodes,
        node_colors = colors,
        edges = Tuple{Int, Int}[],
        edge_colors = [],
        labels = String[]
    )
    
    fig, ax, p = DAGMakie.dagplot_highlighted(g, highlight; kwargs...)
    
    if adj_set !== nothing && !isempty(adj_set)
        ax.title = "Adjustment set: {$(join(adj_set, ", "))}"
    else
        ax.title = "No adjustment needed"
    end
    
    return fig, ax, p
end

# =============================================================================
# SCM-Specific Visualisation
# =============================================================================

"""
    dagplot_scm(scm::CausalDynamics.GraphSCM; show_exogenous=false, kwargs...)

Plot a GraphSCM with optional exogenous variable highlighting.

# Arguments
- `scm`: The GraphSCM to plot
- `show_exogenous`: Whether to highlight exogenous nodes
- `exogenous_color`: Colour for exogenous nodes
"""
function dagplot_scm(
    scm::CausalDynamics.GraphSCM;
    show_exogenous::Bool = true,
    exogenous_color = :lightgray,
    endogenous_color = :lightblue,
    kwargs...
)
    g = scm.graph
    n = nv(g)
    
    if show_exogenous
        node_colors = [i ∈ scm.exogenous ? exogenous_color : endogenous_color for i in 1:n]
        return DAGMakie.dagplot(g; node_color = node_colors, kwargs...)
    else
        return DAGMakie.dagplot(g; kwargs...)
    end
end

"""
    dagplot_scm(scm::CausalDynamics.SymbolicSCM; kwargs...)

Plot a SymbolicSCM's causal graph.
"""
function dagplot_scm(scm::CausalDynamics.SymbolicSCM; kwargs...)
    return DAGMakie.dagplot(scm.graph; kwargs...)
end

# =============================================================================
# Intervention Visualisation with CausalDynamics
# =============================================================================

"""
    dagplot_intervention_cd(scm::CausalDynamics.AbstractSCM, intervention_node::Int; kwargs...)

Visualise an intervention on an SCM.

Shows the original SCM graph with the intervention applied (incoming edges removed).
"""
function dagplot_intervention_cd(
    scm::CausalDynamics.AbstractSCM,
    intervention_node::Int;
    kwargs...
)
    int = DAGMakie.Intervention(intervention_node)
    return DAGMakie.dagplot_intervention(scm.graph, int; kwargs...)
end

"""
    dagplot_scm_comparison(scm::CausalDynamics.AbstractSCM, intervention_node::Int; kwargs...)

Side-by-side comparison of SCM before and after intervention.
"""
function dagplot_scm_comparison(
    scm::CausalDynamics.AbstractSCM,
    intervention_node::Int;
    nlabels = nothing,
    kwargs...
)
    int = DAGMakie.Intervention(intervention_node)
    return DAGMakie.dagplot_comparison(scm.graph, int; nlabels = nlabels, kwargs...)
end

# =============================================================================
# Analysis Helpers
# =============================================================================

"""
    causal_analysis(g, treatment, outcome; nlabels=nothing)

Perform comprehensive causal analysis and return a summary.

# Returns
- Named tuple with:
  - `backdoor_paths`: Backdoor paths found
  - `adjustment_set`: Valid adjustment set (or nothing)
  - `identifiable`: Whether effect is identifiable
  - `d_separated_unconditional`: Whether X ⊥ Y unconditionally
"""
function causal_analysis(
    g::AbstractGraph,
    treatment::Int,
    outcome::Int;
    nlabels = nothing
)
    # Use CausalDynamics functions
    backdoor_paths = CausalDynamics.find_backdoor_paths(g, treatment, outcome)
    adj_set = CausalDynamics.backdoor_adjustment_set(g, treatment, outcome)
    identifiable = CausalDynamics.is_backdoor_adjustable(g, treatment, outcome)
    d_sep_uncond = CausalDynamics.d_separated(g, treatment, outcome, Int[])
    
    return (
        backdoor_paths = backdoor_paths,
        adjustment_set = adj_set,
        identifiable = identifiable,
        d_separated_unconditional = d_sep_uncond
    )
end

"""
    print_causal_analysis(g, treatment, outcome; nlabels=nothing)

Print a formatted causal analysis report.
"""
function print_causal_analysis(
    g::AbstractGraph,
    treatment::Int,
    outcome::Int;
    nlabels = nothing
)
    analysis = causal_analysis(g, treatment, outcome; nlabels = nlabels)
    
    t_name = nlabels !== nothing && treatment <= length(nlabels) ? nlabels[treatment] : "X$treatment"
    o_name = nlabels !== nothing && outcome <= length(nlabels) ? nlabels[outcome] : "Y$outcome"
    
    println("=" ^ 50)
    println("Causal Analysis: $t_name → $o_name")
    println("=" ^ 50)
    println()
    println("Backdoor paths: $(length(analysis.backdoor_paths))")
    for (i, path) in enumerate(analysis.backdoor_paths)
        path_str = if nlabels !== nothing
            join([nlabels[n] for n in path], " → ")
        else
            join(path, " → ")
        end
        println("  $i. $path_str")
    end
    println()
    
    if analysis.adjustment_set !== nothing && !isempty(analysis.adjustment_set)
        adj_str = if nlabels !== nothing
            join([nlabels[n] for n in analysis.adjustment_set], ", ")
        else
            join(analysis.adjustment_set, ", ")
        end
        println("Adjustment set: {$adj_str}")
    else
        println("Adjustment set: ∅ (none needed)")
    end
    println()
    
    println("Effect identifiable: $(analysis.identifiable ? "✓ Yes" : "✗ No")")
    println("d-separated (unconditional): $(analysis.d_separated_unconditional ? "Yes" : "No")")
    println("=" ^ 50)
    
    return analysis
end

# =============================================================================
# Exports
# =============================================================================

export dagplot_dsep_cd, dagplot_backdoor_cd, dagplot_adjustment_cd
export dagplot_scm, dagplot_intervention_cd, dagplot_scm_comparison
export causal_analysis, print_causal_analysis

end # module
