using Documenter
using DAGMakie
using CairoMakie

# Prefer PNG MIME so Documenter writes figure files instead of huge inline HTML.
CairoMakie.activate!(type = "png")
CairoMakie.enable_only_mime!("png")

makedocs(
    sitename = "DAGMakie.jl",
    authors = "Simon A. Babayan",
    modules = [DAGMakie],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://simonab.github.io/DAGMakie.jl",
        assets = String[],
        example_size_threshold = 0,  # always write @example figures to files
    ),
    pages = [
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "User Guide" => [
            "Basic Plotting" => "guide/basic.md",
            "Node Types & Styling" => "guide/styling.md",
            "Bidirected Edges" => "guide/bidirected.md",
            "Causal Analysis" => "guide/causal.md",
            "Interventions" => "guide/interventions.md",
        ],
        "API Reference" => "api.md",
    ],
    checkdocs = :exports,
    warnonly = [:missing_docs],
)

if get(ENV, "CI", nothing) == "true"
    deploydocs(
        repo = "github.com/SimonAB/DAGMakie.jl.git",
        devbranch = "main",
        push_preview = true,
    )
end
