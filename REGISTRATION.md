## Registration status

DAGMakie is on General (`0.1.0`, `0.1.1`, **`0.1.6`**). Local tip is **`0.1.7`**
(not yet registered).

Tip **0.1.6** was registered via [General#163400](https://github.com/JuliaRegistries/General/pull/163400)
(2026-08-04), using plan path **2**: scalar DiD SWIG `node_size` so AutoMerge
passed on registry GraphMakie `v0.6.5`.

GraphMakie **0.6.6** (General, 2026-08-05) includes
[MakieOrg/GraphMakie#259](https://github.com/MakieOrg/GraphMakie.jl/pull/259)
(non-scalar `node_size`). **0.1.7** restores tuple DiD SWIG defaults and requires
`GraphMakie = "0.6.6"`.

Book / CDCS authoring may still use the local GraphMakie path dep for other fork
features (auto-label alignment).

## GraphMakie / CausalDynamics resolve matrix

CausalInference **≥0.19.4** (General) allows GraphMakie `"0.5, 0.6"`, so a single
environment can resolve CausalDynamics + DAGMakie + GraphMakie **≥0.6.6**.

| Combo | Result |
|-------|--------|
| CausalDynamics + DAGMakie + GraphMakie **≥0.6.6** | OK (supported single-env) |
| + CDCS GraphMakie fork (auto-label alignment) | OK via path develop |

Dual-env was required only while CausalInference’s GraphMakie weakdep was capped
at 0.5 ([#179](https://github.com/mschauer/CausalInference.jl/pull/179), merged
in 0.19.4). Companion docs:
[CausalDynamics REGISTRATION.md](https://github.com/SimonAB/CausalDynamics.jl/blob/main/REGISTRATION.md).
Tracking issue: [#3](https://github.com/SimonAB/DAGMakie.jl/issues/3).
