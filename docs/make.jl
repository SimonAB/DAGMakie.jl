using Documenter
using DAGMakie

makedocs(
    sitename = "DAGMakie.jl",
    authors = "Simon A. Babayan",
    modules = [DAGMakie],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://SimonAB.github.io/DAGMakie.jl",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Terminology" => "terminology.md",
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

deploydocs(
    repo = "github.com/SimonAB/DAGMakie.jl.git",
    devbranch = "main",
    push_preview = true,
)
