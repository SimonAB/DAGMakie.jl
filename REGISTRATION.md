## Registration status

DAGMakie is on General (`0.1.0`, `0.1.1`). Tip **0.1.6** is intended for the next
registration (scalar DiD SWIG `node_size` so AutoMerge works on registry GraphMakie).

### Resolved blocker (path 2)

Registry GraphMakie `v0.6.5` still predates [MakieOrg/GraphMakie#259](https://github.com/MakieOrg/GraphMakie.jl/pull/259)
(merged on `master`, not yet released). Tuple / vector `node_size` still errors in
`distance_between_markers` on General.

Default DiD SWIG specs therefore use **scalar** `node_size` (large enough for
labels). CI and docs no longer override GraphMakie with a fork. Optional rectangular
sizes can return once a GraphMakie release including #259 is on General
([issue #2](https://github.com/SimonAB/DAGMakie.jl/issues/2)).

Book / CDCS authoring may still use the local GraphMakie `cdcs` path dep for
non-scalar markers and other fork features.
