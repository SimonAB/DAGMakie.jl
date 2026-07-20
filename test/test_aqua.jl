using Aqua
using DAGMakie

@testset "Aqua.jl" begin
    # Run all Aqua tests except those that are too strict for this package
    Aqua.test_all(
        DAGMakie;
        ambiguities = false,  # Skip ambiguity checks (Makie ecosystem has many)
        stale_deps = (ignore = [:Reexport],),  # Reexport is used at compile time
        deps_compat = (
            check_extras = false,  # Don't require compat for test deps (Test, CairoMakie, Aqua)
        ),
    )
end
