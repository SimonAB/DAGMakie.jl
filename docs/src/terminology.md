# Terminology

DAGMakie keeps Pearl-style plot and surgery names (`Intervention`, `do_surgery`,
`find_backdoor_paths`, …). Display surgery does not change the simulation model.

**Temporal identity** follows CausalDynamics. Occasion and enduring are semantic
modes; glyphs must not be passed back as extra vertices. Whitehead glossary
terms belong in the
[CDCS book Concept Reference](https://simonab.github.io/causal-dynamics-book/concept-reference-tables.html),
not in this manual.

| Term | Meaning in this package |
|------|-------------------------|
| **Occasion** node `(v, t)` | One node per observation step; drawn as a circle |
| **Enduring** node `(v, nothing)` | One node per entity; rounded rectangle at onset |
| **Onset** | Horizontal placement of an enduring glyph (`onset_times`) |
| **Constitutive / influence** | Edge roles from CausalDynamics `temporal_edge_records`; styling only |
| **Replacement / deployment** | Optional view labels for successor identity and applicability intervals |

Prefer established names in plotting code. Use the closed lexicon when
explaining persistence in a temporal layout, not as a second graph ontology.
