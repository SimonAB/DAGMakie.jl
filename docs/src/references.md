# References

Literature underpinning DAGMakie.jl's causal-diagram conventions, layout rules,
and visual grammar. BibTeX keys match the CDCS book
[`references.bib`](https://github.com/SimonAB/causal-dynamics-book/blob/main/references.bib)
where present.

## Causal diagrams, good controls, and `do(·)` surgery

- Pearl, J. (2009). *Causality: Models, Reasoning, and Inference* (2nd ed.). Cambridge University Press, Cambridge. — key `pearl2009causality` (structural diagrams, d-separation, and `do(·)` graph surgery)

- Cinelli, C., Forney, A., & Pearl, J. (2024). A crash course in good and bad controls. *Sociological Methods & Research*, *53*(3), 1071–1104. [doi:10.1177/00491241221099552](https://doi.org/10.1177/00491241221099552) — key `cinelli2024goodbadcontrols` (canonical good-control vs bad-control layouts)

- Hernán, M. A., & Robins, J. M. (2020). *Causal Inference: What If*. Chapman & Hall/CRC, Boca Raton, FL. — key `hernan2020causal` (longitudinal and time-varying confounding diagrams)

## Role colouring and adjustment sets

- Textor, J., van der Zander, B., Gilthorpe, M. S., Liśkiewicz, M., & Ellison, G. T. H. (2016). Robust causal inference using directed acyclic graphs: the R package 'dagitty'. *International Journal of Epidemiology*, *45*(6), 1887–1894. [doi:10.1093/ije/dyw341](https://doi.org/10.1093/ije/dyw341) (ancestor and adjustment role colouring used by `color_by`)

- van der Zander, B., Liśkiewicz, M., & Textor, J. (2019). Separators and adjustment sets in causal graphs: complete criteria and an algorithmic framework. *Artificial Intelligence*, *270*, 1–40. [doi:10.1016/j.artint.2018.12.006](https://doi.org/10.1016/j.artint.2018.12.006) — key `vanderzander2019separators` ([arXiv:1803.00116](https://arxiv.org/abs/1803.00116)) (upstream algorithm in `CausalInference.jl` / `CausalDynamics.jl`)

## SWIGs and interaction diagrams

- Richardson, T. S., & Robins, J. M. (2013). Single world intervention graphs (SWIGs): A unification of the counterfactual and graphical approaches to causality. [arXiv:1201.5658](https://arxiv.org/abs/1201.5658) — key `richardson2013single` (split-node intervention grammar for `dagplot_did_swig` and `SwigFixed`)

## Related software

- **Julia plotting & graphs:** [Makie.jl](https://github.com/MakieOrg/Makie.jl), [GraphMakie.jl](https://github.com/MakieOrg/GraphMakie.jl), [Graphs.jl](https://github.com/JuliaGraphs/Graphs.jl)
- **Julia causal stack:** [CausalDynamics.jl](https://simonab.github.io/CausalDynamics.jl/dev/), [CausalTargeted.jl](https://simonab.github.io/CausalTargeted.jl/dev/), [CausalMediation.jl](https://simonab.github.io/CausalMediation.jl/dev/), [CausalInference.jl](https://github.com/mschauer/CausalInference.jl)
- **R companions:** [dagitty](https://cran.r-project.org/package=dagitty), [ggdag](https://cran.r-project.org/package=ggdag)
- **Narrative companion:** [CDCS Book](https://simonab.github.io/causal-dynamics-book/)
