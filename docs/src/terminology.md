# Terminology

DAGMakie uses standard causal-inference names in its API (`Intervention`, `do_surgery`, `find_backdoor_paths`, …). The table below maps those names to a **process** reading (relations and occasions, not static substances) when that helps interpretation.

| API / Pearl term | Process reading (when useful) |
|------------------|-------------------------------|
| Node in a DAG | **Occasion** (a variable at a point in the structure) |
| Directed edge `i → j` | **Prehensive relation**: how `j` takes account of `i` |
| Exogenous noise / unmodelled parent | **Creative advance** (not fixed by the diagram alone) |
| `do_surgery`, `Intervention` | **Physical prehension**: fix a mechanism, remove incoming prehensions |
| `find_backdoor_paths` | Paths that enter the treatment **against** the directed prehensive flow (confounding) |
| `simulate_scm` / forward pass | One **concrescence** step given fixed exogenous `U` |
| Counterfactual with shared `U` | **Alternative concrescences** for the same unit |

Prefer established names in code; use the process column when explaining *what* an operation does, not as a replacement label.
