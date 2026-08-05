## Registration status

DAGMakie is on General (`0.1.0`, `0.1.1`, **`0.1.6`**).

Tip **0.1.6** was registered via [General#163400](https://github.com/JuliaRegistries/General/pull/163400)
(2026-08-04), using plan path **2**: scalar DiD SWIG `node_size` so AutoMerge
passes on registry GraphMakie `v0.6.5`.

[MakieOrg/GraphMakie#259](https://github.com/MakieOrg/GraphMakie.jl/pull/259) is
merged on `master` but not yet in a General release. Optional follow-up: restore
tuple/vector `node_size` in DiD SWIG defaults once that release lands.

Book / CDCS authoring may still use the local GraphMakie `cdcs` path dep for
non-scalar markers and other fork features.

## GraphMakie / CausalDynamics resolve matrix

Registry DAGMakie co-installs with CausalDynamics when GraphMakie stays on
**0.5.x**. The CDCS tip path (GraphMakie **≥0.6** + newer DAGMakie) currently
cannot share a Julia project with CausalDynamics, because registry
CausalInference pins its optional GraphMakie weakdep to 0.5.

| Combo | Result |
|-------|--------|
| CausalDynamics 0.3.x alone | OK |
| + registry GraphMakie **0.5.x** | OK |
| + registry DAGMakie **0.1.x** + GraphMakie **0.5.x** | OK (supported single-env) |
| CDCS tip GraphMakie **≥0.6** + tip DAGMakie + CausalDynamics | Mutually exclusive |

**Supported pattern for tip GraphMakie 0.6:** dual environment.

1. Identification-only env: CausalDynamics from General (no GraphMakie 0.6).
2. Fig0 / plot env: develop CDCS GraphMakie + DAGMakie; drop CausalDynamics for that resolve.

Companion docs: [CausalDynamics REGISTRATION.md](https://github.com/SimonAB/CausalDynamics.jl/blob/main/REGISTRATION.md).
Tracking issue: [#3](https://github.com/SimonAB/DAGMakie.jl/issues/3).
Upstream unblocker: [mschauer/CausalInference.jl#179](https://github.com/mschauer/CausalInference.jl/pull/179).
After that merges and registers, re-test tip GraphMakie + CausalDynamics + DAGMakie in one env before changing dual-env guidance.
