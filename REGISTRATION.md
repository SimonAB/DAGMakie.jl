## Registration status

Source release **0.1.12** is on General ([#175630](https://github.com/JuliaRegistries/General/pull/175630), merged 2026-11-10; tree `e03b57316559f2e5223da44eec1f56c80c04a3d0`) and identified by tag `v0.1.12`. See [CHANGELOG.md](CHANGELOG.md) for the released changes.

DAGMakie **0.1.11** is on
[General](https://github.com/JuliaRegistries/General/blob/master/D/DAGMakie/Versions.toml)
(tree `5d6cb170b4bac35d4a66ced98d2c55cb8c13b8e1`); TagBot tagged `v0.1.11`.
Source release **0.1.12** includes the label-alignment corrections. The General
registry contains this release; the stable manual may still reflect 0.1.11
while the Pages deployment issue is unresolved.

Tip **0.1.6** was registered via [General#163400](https://github.com/JuliaRegistries/General/pull/163400)
(2026-08-04), using plan path **2**: scalar DiD SWIG `node_size` so AutoMerge
passed on registry GraphMakie `v0.6.5`.

GraphMakie **0.6.6** (General, 2026-08-05) includes
[MakieOrg/GraphMakie#259](https://github.com/MakieOrg/GraphMakie.jl/pull/259)
(non-scalar `node_size`). **0.1.7** restores tuple DiD SWIG defaults and requires
`GraphMakie = "0.6.6"`.

Book / CDCS authoring uses registry GraphMakie 0.6.6; automatic label alignment
is implemented in DAGMakie.

## GraphMakie / CausalDynamics resolve matrix

CausalInference **≥0.19.4** (General) allows GraphMakie `"0.5, 0.6"`, so a single
environment can resolve CausalDynamics + DAGMakie + GraphMakie **≥0.6.6**.

| Combo | Result |
|-------|--------|
| CausalDynamics + DAGMakie + GraphMakie **≥0.6.6** | OK (supported single-env) |

Dual-env was required only while CausalInference’s GraphMakie weakdep was capped
at 0.5 ([#179](https://github.com/mschauer/CausalInference.jl/pull/179), merged
in 0.19.4). Companion docs:
[CausalDynamics REGISTRATION.md](https://github.com/SimonAB/CausalDynamics.jl/blob/main/REGISTRATION.md).
Tracking issue: [#3](https://github.com/SimonAB/DAGMakie.jl/issues/3).
