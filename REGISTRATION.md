## Registration status

DAGMakie is on General (`0.1.0`, `0.1.1`). Local / GitHub tip is **0.1.5**.

### Blocker for registering `0.1.2+`

AutoMerge uses **registry** GraphMakie. Default tests (and DiD SWIG figures) use
rectangular `node_size` tuples such as `(width, height)`. Older registry GraphMakie
(`distance_between_markers`) does `scale * size / 2` and errors on tuples:

`MethodError: *(::Float64, ::Tuple{Int64,Int64})`

Upstream [MakieOrg/GraphMakie#259](https://github.com/MakieOrg/GraphMakie.jl/pull/259)
is **merged** (`8fc8f7a` on `master`). It is **not yet in a General release**
(latest tag remains `v0.6.5`, which predates the merge). Tracking:
[SimonAB/DAGMakie.jl#2](https://github.com/SimonAB/DAGMakie.jl/issues/2).

Until a GraphMakie release that includes #259 is on General, keep authoring against
the CDCS GraphMakie path dep (branch `cdcs` already includes the fix).

### Paths forward

1. Wait for a General GraphMakie release containing #259, smoke-test DAGMakie
   against registry GraphMakie (tuple `node_size` / DiD SWIG), then
   `@JuliaRegistrator register` tip (`0.1.5` or next); or
2. Soften default tests / examples to scalar `node_size` only so AutoMerge passes
   on today’s GraphMakie.

Do not register `0.1.5` until (1) or (2) is done.
