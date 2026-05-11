# Features and diagnostic workflow

The current release focuses on independent-response models and related
count-data specifications where the fitted conditional distribution can be
evaluated after Stata estimation.

## Documented specifications

| Area | Examples | Notes |
|---|---|---|
| Continuous outcomes | Gaussian, Gamma, inverse Gaussian | Includes positive continuous GLM specifications where the fitted CDF is available. |
| Binary and binomial outcomes | Bernoulli, binomial counts with trials | Uses the fitted Bernoulli or binomial CDF, with randomized intervals for discrete outcomes. |
| Count outcomes | Poisson, negative binomial, generalized Poisson | Includes documented offset/exposure and ancillary-parameter handling where supported. |
| Special count outcomes | Zero-inflated, truncated, censored, hurdle counts | Uses the fitted CDF appropriate to extra zeros, restricted support, censoring intervals, or hurdle structure. |
| Weights and diagnostics | Selected `fweight` specifications; selected direct `pweight` diagnostics | Frequency weights affect the fitted model; direct probability-weighted fits are model-based diagnostics, not `svy:` residuals. |

## Diagnostic workflow

| Step | What to inspect | Purpose |
|---|---|---|
| Compute residuals | `qresid newvar` after a fitted model | Place observations on a common normal quantile scale. |
| Check normality | `qnorm newvar` | Assess whether the fitted conditional distribution is plausible. |
| Check fitted mean range | Residuals versus fitted values | Look for mean, variance, support, or tail problems over the fitted scale. |
| Check covariates | Residuals versus key predictors | Look for omitted nonlinear structure, link problems, or seasonal patterns. |
| Compare models | Same plots across candidate specifications | Distinguish broad lack of fit from a more credible probability model. |

For detailed support boundaries, see [Supported specifications](supported-specifications.md).
