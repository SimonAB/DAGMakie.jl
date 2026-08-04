# SPDX-License-Identifier: MIT

"""
Visual grammar helpers for interactions (IDAGs) and DiD SWIGs.

These helpers are **display-only**. Modifier edges and effect-measure nodes do
not change d-separation; SWIG fixed halves are drawn for pedagogy, not for
identification algorithms.
"""

using Makie: Figure, Axis, Point2f

# =============================================================================
# Edge helpers
# =============================================================================

"""
    modifier_edge(src, dst; kwargs...)

Create a pedagogical modifier `EdgeSpec` (dash-dot, dark gray).

Modifier edges annotate that one variable modifies an effect; they are **not**
inputs to d-separation. Prefer an IDAG ([`vaccine_nutrition_idag_spec`](@ref))
when the claim is about effect variation.
"""
function modifier_edge(
    src::Int,
    dst::Int;
    color = MODIFIER_EDGE_COLOR,
    width::Real = MODIFIER_EDGE_WIDTH,
    style::Symbol = MODIFIER_EDGE_STYLE,
    label::Union{String, Nothing} = "mod",
)
    return EdgeSpec(
        src,
        dst;
        type = Modifier,
        color = color,
        width = width,
        style = style,
        label = label,
    )
end

# =============================================================================
# Side-by-side companion figures
# =============================================================================

"""
    dagplot_side_by_side(left, right; titles, figure_size, kwargs...)

Plot two `DAGSpec` (or graph) panels with shared keyword overrides.

Used for outcome-DAG | IDAG and factual-DAG | SWIG companion figures.
"""
function dagplot_side_by_side(
    left,
    right;
    titles::Tuple{<:AbstractString, <:AbstractString} = ("Left", "Right"),
    figure_size::Tuple{Int, Int} = (1000, 420),
    left_kwargs = NamedTuple(),
    right_kwargs = NamedTuple(),
    kwargs...,
)
    fig = Figure(size = figure_size)
    ax1 = Axis(fig[1, 1], title = titles[1])
    ax2 = Axis(fig[1, 2], title = titles[2])
    dagplot!(ax1, left; _merge_default_kwargs(kwargs, left_kwargs)...)
    dagplot!(ax2, right; _merge_default_kwargs(kwargs, right_kwargs)...)
    return fig
end

# =============================================================================
# Vaccine × nutrition (interaction / effect modification)
# =============================================================================

"""
    vaccine_nutrition_outcome_spec(; labels)

Outcome DAG: nutrition ``N`` confounds vaccination ``V`` and outcome ``Y``.

Suitable for identification / adjustment illustrations.
"""
function vaccine_nutrition_outcome_spec(;
    labels::Vector{<:AbstractString} = ["N", "V", "Y"],
)
    length(labels) == 3 || throw(ArgumentError("expected 3 labels [N, V, Y]"))
    g = Graphs.SimpleDiGraph(3)
    Graphs.add_edge!(g, 1, 2)  # N → V
    Graphs.add_edge!(g, 1, 3)  # N → Y
    Graphs.add_edge!(g, 2, 3)  # V → Y
    nodes = [
        NodeSpec(labels[1]; type = Confounder),
        NodeSpec(labels[2]; type = Treatment),
        NodeSpec(labels[3]; type = Outcome),
    ]
    return DAGSpec(g, nodes, EdgeSpec[], "Vaccine × nutrition (outcome DAG)")
end

"""
    vaccine_nutrition_idag_spec(; labels)

IDAG companion: replace ``Y`` with an additive effect-measure node ``δ``.

Arrows into ``δ`` show which variables drive effect size (Nilsson et al. style).
"""
function vaccine_nutrition_idag_spec(;
    labels::Vector{<:AbstractString} = ["N", "V", "δ"],
)
    length(labels) == 3 || throw(ArgumentError("expected 3 labels [N, V, δ]"))
    g = Graphs.SimpleDiGraph(3)
    Graphs.add_edge!(g, 1, 2)  # N → V
    Graphs.add_edge!(g, 1, 3)  # N → δ (modifier of the effect)
    Graphs.add_edge!(g, 2, 3)  # V → δ
    nodes = [
        NodeSpec(labels[1]; type = Confounder),
        NodeSpec(labels[2]; type = Treatment),
        NodeSpec(labels[3]; type = EffectMeasure),
    ]
    return DAGSpec(g, nodes, EdgeSpec[], "Vaccine × nutrition (IDAG)")
end

"""
    vaccine_nutrition_layout()

Triangle layout with nutrition at the apex (same geometry as confounding demos).
"""
vaccine_nutrition_layout() = copy(_LAYOUT_TRIANGLE_APEX_TOP)

"""
    dagplot_vaccine_nutrition_interaction(; kwargs...)

Side-by-side outcome DAG and IDAG for vaccine × nutrition effect modification.
"""
function dagplot_vaccine_nutrition_interaction(;
    figure_size::Tuple{Int, Int} = (1000, 420),
    kwargs...,
)
    left = vaccine_nutrition_outcome_spec()
    right = vaccine_nutrition_idag_spec()
    layout = vaccine_nutrition_layout()
    return dagplot_side_by_side(
        left,
        right;
        titles = ("Outcome DAG (identification)", "IDAG (effect variation)"),
        figure_size = figure_size,
        layout = layout,
        kwargs...,
    )
end

# =============================================================================
# Canonical 2×2 DiD (factual DAG + SWIG)
# =============================================================================

"""
    did_2x2_factual_spec(; labels)

Time-expanded factual DAG for a two-group, two-period DiD design.

Nodes (default order): ``G``, ``U``, ``Y₀``, ``Y₁``, ``A₁``.
"""
function did_2x2_factual_spec(;
    labels::Vector{<:AbstractString} = ["G", "U", "Y₀", "Y₁", "A₁"],
)
    length(labels) == 5 || throw(ArgumentError("expected 5 labels [G, U, Y₀, Y₁, A₁]"))
    g = Graphs.SimpleDiGraph(5)
    Graphs.add_edge!(g, 1, 3)  # G → Y₀
    Graphs.add_edge!(g, 1, 4)  # G → Y₁
    Graphs.add_edge!(g, 1, 5)  # G → A₁
    Graphs.add_edge!(g, 2, 3)  # U → Y₀
    Graphs.add_edge!(g, 2, 4)  # U → Y₁
    Graphs.add_edge!(g, 5, 4)  # A₁ → Y₁
    nodes = [
        NodeSpec(labels[1]; type = Confounder),
        NodeSpec(labels[2]; type = Latent),
        NodeSpec(labels[3]; type = Outcome),
        NodeSpec(labels[4]; type = Outcome),
        NodeSpec(labels[5]; type = Treatment),
    ]
    return DAGSpec(g, nodes, EdgeSpec[], "2×2 DiD (factual)")
end

"""
    did_2x2_swig_spec(; labels)

SWIG under ``do(A₁ = 0)`` for the untreated world used by parallel trends.

Nodes (default order): ``G``, ``U``, ``Y₀``, ``Y₁(0)``, ``A₁``, ``a=0``.
Incoming edges stay on the random half ``A₁``; outflows leave from the fixed
half ``a=0``.
"""
function did_2x2_swig_spec(;
    labels::Vector{<:AbstractString} = ["G", "U", "Y₀", "Y₁(0)", "A₁", "a=0"],
)
    length(labels) == 6 || throw(ArgumentError(
        "expected 6 labels [G, U, Y₀, Y₁(0), A₁, a=0]",
    ))
    g = Graphs.SimpleDiGraph(6)
    Graphs.add_edge!(g, 1, 3)  # G → Y₀
    Graphs.add_edge!(g, 1, 4)  # G → Y₁(0) (group baseline path)
    Graphs.add_edge!(g, 1, 5)  # G → A₁ (incoming stays on random half)
    Graphs.add_edge!(g, 2, 3)  # U → Y₀
    Graphs.add_edge!(g, 2, 4)  # U → Y₁(0)
    Graphs.add_edge!(g, 6, 4)  # a=0 → Y₁(0) (outflow from fixed half)
    nodes = [
        NodeSpec(labels[1]; type = Confounder),
        NodeSpec(labels[2]; type = Latent),
        NodeSpec(labels[3]; type = Outcome),
        # Scalar sizes: registry GraphMakie before the non-scalar `node_size` fix
        # (#259) errors on tuples in `distance_between_markers`. Prefer large
        # scalars so wide labels (Y₁(0)) remain readable; restore tuples once
        # General ships a GraphMakie release that includes #259.
        NodeSpec(labels[4]; type = Outcome, marker = :rect, size = 96),
        NodeSpec(labels[5]; type = Treatment),
        NodeSpec(labels[6]; type = SwigFixed, size = 80),
    ]
    return DAGSpec(g, nodes, EdgeSpec[], "2×2 DiD SWIG (a=0)")
end

"""
    did_2x2_factual_layout()

Manual positions for the factual 2×2 DiD DAG (time left→right).
"""
function did_2x2_factual_layout()
    return Point2f[
        Point2f(-1.6, 0.4),  # G
        Point2f(0.2, 1.6),   # U
        Point2f(0.0, 0.0),   # Y₀
        Point2f(2.2, 0.0),   # Y₁
        Point2f(1.2, -1.2),  # A₁
    ]
end

"""
    did_2x2_swig_layout()

Manual positions for the DiD SWIG with a split treatment node.
"""
function did_2x2_swig_layout()
    return Point2f[
        Point2f(-1.6, 0.4),  # G
        Point2f(0.2, 1.6),   # U
        Point2f(0.0, 0.0),   # Y₀
        Point2f(3.2, 0.0),   # Y₁(0) (wide rounded rect)
        Point2f(0.55, -1.45), # A₁ (random)
        Point2f(2.1, -1.45), # a=0 (fixed)
    ]
end

"""
    dagplot_did_swig(; kwargs...)

Side-by-side factual 2×2 DiD DAG and untreated-world SWIG.
"""
function dagplot_did_swig(;
    figure_size::Tuple{Int, Int} = (1100, 440),
    kwargs...,
)
    left = did_2x2_factual_spec()
    right = did_2x2_swig_spec()
    return dagplot_side_by_side(
        left,
        right;
        titles = ("Factual 2×2 DAG", "SWIG under do(A₁ = 0)"),
        figure_size = figure_size,
        left_kwargs = (layout = did_2x2_factual_layout(),),
        right_kwargs = (
            layout = did_2x2_swig_layout(),
            nlabels_fontsize = 12,
        ),
        kwargs...,
    )
end
