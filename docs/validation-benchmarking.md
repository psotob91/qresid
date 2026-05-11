# Validation and benchmarking

`qresid` emphasizes methodological traceability and reproducible validation.
The public release is checked under Stata 15.0 version mode with
`set varabbrev off`; see the [Stata version compatibility report](stata-version-compatibility.html).

## Validation principles

1. Statistical traceability: each implemented residual definition is linked to
   a published methodological source or an explicit mathematical derivation.
2. Cross-platform benchmarking: results are compared against independent R
   references when an equivalent is available.
3. Numerical robustness: implementation checks address extreme probabilities,
   discrete probability masses, truncation, censoring, and floating-point
   stability.
4. Reproducible diagnostics: validation uses Stata tests, simulation examples,
   graphical checks, benchmark datasets, and documented CDF endpoint checks.

## Benchmark references

Independent references include base R `stats::lm` and `stats::glm` (R Core
Team 2025), `statmod::qresiduals` for randomized quantile residuals (Dunn and
Smyth 1996; Giner and Smyth 2016), `MASS` for negative-binomial regression
(Venables and Ripley 2002), `VGAM::pgenpois0` for generalized Poisson CDF
checks (Yee 2015, 2010), `pscl::hurdle` for hurdle count models (Zeileis,
Kleiber, and Jackman 2008), `glmtoolbox::residuals2` for the Gaussian leverage
adjustment check (Vanegas, Rondon, and Paula 2024), and manual CDF replay
where the fitted distribution is reconstructed from Stata postestimation
quantities.

See [Validation evidence](validation.md) for the current validation summary
and [Supported specifications](supported-specifications.md) for the model
specifications documented in this release.

## References

R Core Team. 2025. *R: A Language and Environment for Statistical Computing*.
R Foundation for Statistical Computing, Vienna, Austria.

Venables, W. N., and B. D. Ripley. 2002. *Modern Applied Statistics with S*.
4th ed. New York: Springer.

Yee, T. W. 2010. The VGAM package for categorical data analysis. *Journal of
Statistical Software* 32(10): 1-34.

Yee, T. W. 2015. *Vector Generalized Linear and Additive Models: With an
Implementation in R*. New York: Springer.

Vanegas, L. H., L. M. Rondon, and G. A. Paula. 2024. `glmtoolbox`: Set of tools
to data analysis using generalized linear models. R package version 0.1.12.
doi:10.32614/CRAN.package.glmtoolbox.

Haghish, E. F. 2020. Developing, maintaining, and hosting Stata statistical
software on GitHub. *The Stata Journal* 20(4): 931-951.
