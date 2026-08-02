## Registration status

DAGMakie is on General (`0.1.0`, `0.1.1`). Local / GitHub tip is **0.1.5**.

### Blocker for registering `0.1.2+`

AutoMerge uses **registry** GraphMakie. Default tests (and DiD SWIG figures) use
rectangular `node_size` tuples such as `(width, height)`. Upstream
`distance_between_markers` does `scale * size / 2` and errors on tuples:

`MethodError: *(::Float64, ::Tuple{Int64,Int64})`

Upstream fix in progress: [MakieOrg/GraphMakie#259](https://github.com/MakieOrg/GraphMakie.jl/pull/259).
The CDCS fork already carries the same change (`4977033`); package CI / docs
override GraphMakie with that fork until General has it.

### Paths forward

1. Land #259, wait for a General GraphMakie release, then `@JuliaRegistrator register` DAGMakie; or
2. Soften default tests / examples to scalar `node_size` only so AutoMerge passes today.

Do not register `0.1.5` until (1) or (2) is done.
