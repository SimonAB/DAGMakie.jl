# Terminology

DAGMakie keeps Pearl-style plot and surgery names (`Intervention`, `do_surgery`,
`find_backdoor_paths`, …). Display surgery does not change the simulation model.

**Temporal declarations** follow CausalDynamics: glyphs follow
`value_representation` (rounded only for `:interval_summary`), not ontology
and not single-node support. Whitehead glossary
terms belong in the
[CDCS book Concept Reference](https://simonab.github.io/causal-dynamics-book/concept-reference-tables.html),
not in this manual.

| Term | Meaning in this package |
|------|-------------------------|
| **Pointwise node** `(v, t)` | One node per discrete time; default circle glyph |
| **Single-node support** `(v, nothing)` | Reused node (`FromOnsetSupport`, …); placed at onset; **circle by default** (shape ≠ support) |
| **Interval summary glyph** | Rounded rectangle only when `value_representation = :interval_summary` ([`interval_summary_node_marker`](@ref)) |
| **Onset** | Horizontal placement for single-node keys (`onset_times`) |
| **`graph_kind`** | Annotate time-unrolled vs process vs semantic figures |
| **Constitutive / influence** | Edge roles from CausalDynamics `temporal_edge_records`; styling only |
| **`referent_id` lanes** | Optional identity connectors; not graph edges and not cut by `do_surgery` |

Placement follows the key shape alone: `(v, t)` sits at column `t`, `(v, nothing)`
at its onset. There is no separate node-mode flag. Glyphs and layout must not
change identification meaning, and must not be read as ontology.


## Display vs identify

DAGMakie reuses Pearl plot names (`Intervention`, `CausalQuery`, `do_surgery`)
for **display surgery** only. Prefer the `DAGMakie.` qualifier in mixed
sessions. Identification and generative `do(·)` remain in CausalDynamics.
See the Policy taxonomy in the shared
[DESIGN_PRINCIPLES](https://github.com/SimonAB/causal-dynamics-book/blob/main/packages/DESIGN_PRINCIPLES.md).
