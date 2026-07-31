# Visual grammar: interactions and DiD SWIGs

DAGMakie keeps a small, fixed visual vocabulary for **effect modification /
interaction** figures and **difference-in-differences (DiD)** single-world
intervention graphs (SWIGs). The grammar
extends the publication defaults in [`dag_theme`](@ref) / [`default_style`](@ref):
white ground, no axes, in-node labels, steel-blue fills, goldenrod confounders,
seagreen mediators / effect nodes, and gray hollow latents.

## Terms

- **SWIG** (single-world intervention graph; Richardson & Robins, 2013): under
  ``do(A = a)``, the intervened node is drawn as a split — a random half ``A``
  that still receives incoming edges, and a fixed half ``a`` from which outgoing
  edges leave. Counterfactual labels such as ``Y(0)`` live on this graph; the
  factual DAG alone does not carry them.
- **IDAG** (interaction DAG): companion to an ordinary outcome DAG in which the
  outcome node is replaced by an **effect-measure** node (e.g. ``δ``). Use it
  when the question is how an effect varies with a modifier, not when identifying
  ``E[Y \mid do(A)]``.

!!! note "Display only"
    Modifier edges, effect-measure nodes, and SWIG fixed halves are **pedagogical
    annotations**. They do not change d-separation or identification. Use
    CausalInference.jl / CausalDynamics.jl for those queries.

## House rule

1. **Identification / adjustment** → ordinary outcome DAG (steel-blue /
   goldenrod).
2. **“Does ``G`` change the effect of ``A``?”** → IDAG companion (green
   effect-measure node), or a dash-dot `mod` edge with an explicit caption.
3. **“Is DiD justified?”** → time-expanded factual DAG plus a SWIG for the
   untreated world (parallel trends lives on ``Y_t(0)``, not on the factual DAG
   alone).

## Node conventions

| Role | `NodeType` | Fill / stroke | Marker |
|------|------------|---------------|--------|
| Observed / default | `Observed` | `:steelblue`, stroke 1 | circle |
| Treatment | `Treatment` | `:steelblue`, stroke **2.5** | circle |
| Outcome | `Outcome` | `:steelblue`, stroke **2.0** darkgray | circle |
| Confounder / context | `Confounder` | `:goldenrod` | circle |
| Mediator | `Mediator` | `:seagreen` | circle |
| Latent | `Latent` | gray / hollow, stroke 2 | circle |
| Effect measure (IDAG) | `EffectMeasure` | `:seagreen` | **rect** |
| SWIG fixed half | `SwigFixed` | white, stroke 2, **black** label | **rect** |

Treatment and outcome stay in the steel-blue family so `default` / `minimal` /
`bold` / `presentation` themes keep working; roles are stroke and shape, not a
new rainbow of fills.

## Edge conventions

| Kind | Style | Notes |
|------|-------|-------|
| Causal ``→`` | solid black | usual GraphMakie arrows |
| Latent confounding ``↔`` | dashed curve | [`MixedGraph`](@ref) |
| Removed by ``do(·)`` | dashed, light | intervention plots |
| Modifier annotation | **dash-dot**, `:darkgray` | [`modifier_edge`](@ref); caption required |

```@example grammar-modifier
using DAGMakie

e = modifier_edge(1, 3)
(e.type, e.style, e.color, e.label)
```

## Example 1 — Vaccine × nutrition

Nutrition ``N`` confounds vaccination ``V`` and outcome ``Y``, and may also
modify the vaccine effect on an additive scale. The left panel is the
**outcome DAG** for identification; the right panel is an **IDAG** where ``Y``
is replaced by an effect-measure node ``δ`` (Nilsson et al. style).

```@example grammar-vaccine
using DAGMakie, CairoMakie

fig = with_theme(dag_theme()) do
    dagplot_vaccine_nutrition_interaction()
end
fig
```

Constructors if you need the specs separately:

- [`vaccine_nutrition_outcome_spec`](@ref)
- [`vaccine_nutrition_idag_spec`](@ref)
- [`dagplot_vaccine_nutrition_interaction`](@ref)

**Caption pattern:** *Left: structural DAG for identifying* ``E[Y \mid do(V)]``
*after adjusting for* ``N``*. Right: IDAG for additive effect modification; the
effect node is not an outcome random variable.*

## Example 2 — Canonical 2×2 DiD SWIG

Two groups ``G``, two periods, treatment ``A_1`` only for the treated group in
period 1, with unit-level latent ``U``. The left panel is the factual
time-expanded DAG; the right panel is a SWIG under ``do(A_1 = 0)`` (split node
as above). Incoming edges stay on the random half ``A_1``; outflows leave from
the fixed half ``a=0``, and the post-period outcome is labelled ``Y_1(0)``.

```@example grammar-did
using DAGMakie, CairoMakie

fig = with_theme(dag_theme()) do
    dagplot_did_swig()
end
fig
```

Constructors:

- [`did_2x2_factual_spec`](@ref) / [`did_2x2_factual_layout`](@ref)
- [`did_2x2_swig_spec`](@ref) / [`did_2x2_swig_layout`](@ref)
- [`dagplot_did_swig`](@ref)

**Caption pattern:** *Left: two-period DAG with unit-level* ``U``*. Right: SWIG
for the untreated world; parallel trends is a statement about* ``Y_t(0)``*,
read on the SWIG.*

Do **not** draw two-way fixed-effect dummies as causal nodes; show substantive
latents (here ``U``) instead.

## Side-by-side companions

[`dagplot_side_by_side`](@ref) is the shared layout for outcome | IDAG and
factual | SWIG pairs (same habit as [`dagplot_do_comparison`](@ref)).

```@example grammar-side
using DAGMakie, CairoMakie

left = vaccine_nutrition_outcome_spec()
right = vaccine_nutrition_idag_spec()
fig = with_theme(dag_theme()) do
    dagplot_side_by_side(
        left, right;
        titles = ("Outcome DAG", "IDAG"),
        layout = vaccine_nutrition_layout(),
    )
end
fig
```
