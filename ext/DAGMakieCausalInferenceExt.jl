"""
    DAGMakieCausalInferenceExt

Helpers used by DAGMakie convenience plots when CausalInference.jl is loaded.
"""
module DAGMakieCausalInferenceExt

using DAGMakie
using CausalInference
using Graphs: AbstractGraph

"""Return d-separation status via CausalInference.dsep."""
function dsep_status(g::AbstractGraph, x::Int, y::Int, z::Set{Int})
    return CausalInference.dsep(g, x, y, z)
end

"""Minimal backdoor adjustment set as `Set{Int}` (empty if none / not needed)."""
function min_backdoor_adjustment(g::AbstractGraph, treatment::Int, outcome::Int)
    adj = CausalInference.find_min_backdoor_adjustment(g, treatment, outcome)
    return adj === false ? Set{Int}() : Set{Int}(adj)
end

end # module
