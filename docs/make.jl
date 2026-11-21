# SPDX-License-Identifier: MIT

using Documenter
using DAGMakie
using CairoMakie
using Graphs

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
        "Choosing a diagram" => "orientation.md",
        "Getting Started" => "getting-started.md",
        "Guides" => [
            "Basic plotting" => "guide/basic.md",
            "Node types & styling" => "guide/styling.md",
            "Visual grammar" => "guide/visual_grammar.md",
            "Skeletons & time" => "guide/skeletons_and_time.md",
            "Bidirected edges" => "guide/bidirected.md",
            "Causal highlighting" => "guide/causal.md",
            "Interventions" => "guide/interventions.md",
        ],
        "API Reference" => [
            "Overview" => "api.md",
            "Plotting" => "api/plotting.md",
            "Specs & graphs" => "api/specs_and_graphs.md",
            "Highlighting & interventions" => "api/highlighting_and_do.md",
            "Temporal & skeletons" => "api/temporal_and_skeletons.md",
            "Layout & themes" => "api/layout_and_themes.md",
        ],
        "Architecture & Validation" => [
            "Scope & boundaries" => "scope.md",
            "Terminology" => "terminology.md",
            "Ecosystem comparison" => "comparison.md",
        ],
        "References" => "references.md",
    ],
    checkdocs = :exports,
    warnonly = false,
)

if get(ENV, "CI", nothing) == "true"
    deploydocs(
        repo = "github.com/SimonAB/DAGMakie.jl.git",
        devbranch = "main",
        push_preview = true,
    )
end
