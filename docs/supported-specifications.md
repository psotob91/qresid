# Supported specifications

This page summarizes the model specifications documented for `qresid` 1.0.0.
The Stata help file remains the command reference; see `help qresid` after
installation.

For validation evidence, see [Validation evidence](validation.md).

## Stable core

| Outcome family | Stata command or specification | Notes |
|---|---|---|
| Gaussian | `regress`; `glm, family(gaussian)` | Continuous outcomes with valid fitted means. |
| Bernoulli | `logit`; `logistic`; Bernoulli `binreg`; Bernoulli `glm, family(binomial)` | Supported links include logit and documented GLM binomial links where fitted probabilities are valid. |
| Binomial counts with trials | `glm, family(binomial trials)`; `binreg, n(trials)` | Uses the fitted binomial CDF with row-specific trial totals. |
| Poisson | `poisson`; `glm, family(poisson)` | Includes documented offset/exposure handling where Stata's fitted mean contains the offset or exposure. |
| Negative binomial | `nbreg`; documented NB variants | Uses the fitted mean and ancillary parameters exposed by Stata. |
| Gamma | `glm, family(gamma)` | Positive outcomes and positive fitted means; supports `dispersion(#)` for CDF replay. |
| Inverse Gaussian | `glm, family(igaussian)` | Positive outcomes and positive fitted means; supports `dispersion(#)` for CDF replay. |

## Additional documented specifications

These specifications are documented in the current release where the fitted
distribution and required postestimation quantities are available.

| Model class | Stata command or specification | Notes |
|---|---|---|
| Zero-inflated counts | `zip`; `zinb` | Unweighted specifications; the fitted CDF includes the extra mass at zero. |
| Truncated counts | `tpoisson`; `ztp`; `tnbreg`; `ztnb` | Unweighted specifications; the fitted CDF is conditional on the observable support. |
| Censored counts | `cpoisson` | Unweighted specifications; the PIT is computed over the fitted censoring interval. |
| Generalized Poisson | Stata Journal `gpoisson` | External estimator required; install and cite it separately. |
| Hurdle counts | `hplogit`; `hnblogit` | External estimators required; install and cite them separately. |

## Residual type and dispersion options

| Feature | Status | Notes |
|---|---|---|
| `type(quantile)` | Default | Normal-score quantile residual. For discrete outcomes this is the randomized quantile residual. |
| `type(adjusted)` | Supported where documented | Leverage adjustment `qres/sqrt(1-h)`, with `h` from `predict, hat`. |
| `type(studentized)` | Alias where documented | Same calculation as `type(adjusted)` on supported specifications. |
| `dispersion(#)` | Gamma and inverse Gaussian GLM | Replays the fitted CDF with a user-supplied positive dispersion; it does not refit the model. |

## Weights

| Weight type | Status | Notes |
|---|---|---|
| `fweight` | Supported only on documented specifications | Frequency weights affect the fitted model. The final residual is not multiplied by the weight. |
| Direct `pweight` | Model-based diagnostic only | Available for selected Gaussian, Poisson, and Bernoulli specifications. It is not `svy:` support and is not a survey-design residual. |
| `aweight`, `iweight`, `svy:` | Not currently supported | These require separate statistical semantics and are not claimed in this release. |

## External estimators

Some count specifications depend on user-installed Stata estimators:

```stata
findit gpoisson
findit hplogit
findit hnblogit
```

These commands are not bundled with `qresid` and are not installed by
`github install psotob91/qresid`.

## Not currently supported

The following are not supported in this release:

- `glm, family(nbinomial ml)`;
- unsupported weighted specifications;
- zero-inflated, truncated, censored, generalized-Poisson, and hurdle variants
  outside the documented command set;
- `aweight`, `iweight`, `svy:`;
- correlated, panel, finite-mixture, multilevel, mixed, and GSEM models;
- simulation-based residuals as a substitute for an analytic fitted CDF.

