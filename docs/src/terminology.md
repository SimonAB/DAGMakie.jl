# Terminology

DAGMakie keeps Pearl-style plot and surgery names (`Intervention`, `do_surgery`,
`find_backdoor_paths`, …). Display surgery does not change the simulation model.

**Temporal declarations** follow CausalDynamics: glyphs follow
`value_representation` / `temporal_support`, not ontology. Whitehead glossary
terms belong in the
[CDCS book Concept Reference](https://simonab.github.io/causal-dynamics-book/concept-reference-tables.html),
not in this manual.

| Term | Meaning in this package |
|------|-------------------------|
| **Pointwise node** `(v, t)` | One node per discrete time; default circle glyph |
| **Single-node support** `(v, nothing)` | Reused node (`FromOnsetSupport`, …); default rounded rectangle at onset |
| **Onset** | Horizontal placement for single-node glyphs (`onset_times`) |
| **`graph_kind`** | Annotate time-unrolled vs process vs semantic figures |
| **Constitutive / influence** | Edge roles from CausalDynamics `temporal_edge_records`; styling only |
| **`referent_id` lanes** | Optional identity connectors; not graph edges and not cut by `do_surgery` |

Deprecated layout kwargs still accept `:occasion` / `:enduring` as synonyms for
pointwise vs single-node placement. Prefer support-driven markers when CausalDynamics
semantics are available. Glyphs and layout must not change identification meaning.
