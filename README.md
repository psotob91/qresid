[![Stata tests](https://github.com/psotob91/qresid/actions/workflows/stata-tests.yml/badge.svg)](https://github.com/psotob91/qresid/actions/workflows/stata-tests.yml)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/psotob91/qresid/releases/tag/v1.0.0)
[![Stata](https://img.shields.io/badge/Stata-15.0%2B-1f77b4.svg)](https://www.stata.com/)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Install](https://img.shields.io/badge/install-net%20install-lightgrey.svg)](#installation)

<img align="right" src="docs/assets/qresid-logo.png" width="145" alt="qresid logo">

# qresid

## Randomized quantile residuals for regression diagnostics in Stata

`qresid` implements randomized quantile residuals (Dunn-Smyth residuals) for
regression diagnostics in supported independent regression models in Stata.
The package is intended for generalized linear and related models where
conventional residuals may be difficult to interpret.

In practice, `qresid` gives applied users one graphical language for a broad
range of fitted probability models: Gaussian and positive continuous GLMs,
Bernoulli and binomial responses, Poisson and negative-binomial counts, and
selected extensions for zero inflation, truncation, censoring, hurdle
structures, frequency weights, and fixed-dispersion CDF replay.

## Installation

`qresid` version `v1.0.0` has been submitted to SSC and is pending
review/acceptance. Until SSC acceptance, users can install the package from
GitHub.

```stata
net install qresid, from("https://raw.githubusercontent.com/psotob91/qresid/main/") replace
```

After installation:

```stata
which qresid
help qresid
```

Once accepted by SSC, the recommended installation command will be:

```stata
ssc install qresid
```

While SSC review is pending, GitHub is the public source and development home
for the package.

## Quick Start

Gaussian regression:

```stata
sysuse auto, clear
regress price mpg
qresid rq
qnorm rq
predict double muhat, xb
scatter rq muhat, yline(0)
```

Poisson regression:

```stata
sysuse auto, clear
poisson rep78 mpg if rep78 < .
qresid rq_pois, seed(12345)
qnorm rq_pois
```

## Tutorials

| Tutorial | What you will learn |
|---|---|
| [Continuous outcomes](docs/continuous.md) | Compare Gaussian, Gamma, and inverse-Gaussian fits when positive continuous outcomes make ordinary residual plots hard to read. |
| [Binary and binomial outcomes](docs/binary-binomial.md) | Diagnose Bernoulli and binomial-count models on a normal-score residual scale instead of reading bands of Pearson or deviance residuals. |
| [Link and functional-form checks](docs/link-functional-form.md) | Detect link-function mistakes, nonlinear covariate effects, and seasonal patterns that can be subtle in binary or discrete data. |
| [Count outcomes](docs/counts.md) | Move beyond a generic "not Poisson" conclusion by comparing Poisson, negative-binomial, and generalized-Poisson alternatives graphically. |
| [Zero-inflated, truncated, and censored counts](docs/special-counts.md) | Separate lack of fit due to extra zeros, restricted support, censoring intervals, and count-tail behavior. |
| [Hurdle count models](docs/hurdle.md) | Compare hurdle and zero-inflated interpretations when zeros and positive counts may arise from different mechanisms. |
| [Weights and dispersion replay](docs/weights-dispersion.md) | Understand how frequency weights and fixed-dispersion CDF replay affect residual diagnostics without changing the fitted model. |

## Additional documentation

| Reference | What it covers |
|---|---|
| [Manual index](docs/README.md) | Full tutorial sequence, reproduction notes, and links to generated figures and output excerpts. |
| [Markdown reference](docs/reference.md) | GitHub-friendly version of the installed Stata help, including syntax, options, stored results, and formulas. |
| [Features and diagnostic workflow](docs/features.md) | Documented model classes and a concise workflow for Q-Q plots and residual-versus-fitted or covariate plots. |
| [Statistical background](docs/statistical-background.md) | PIT/RQR formulas, special count-model CDFs, and methodological references. |
| [Validation and benchmarking](docs/validation-benchmarking.md) | Validation principles, independent benchmark references, and Stata 15.0 compatibility checks. |
| [Supported specifications](docs/supported-specifications.md) | Public support scope for this release, including weights, dispersion, and optional external estimators. |
| [Validation evidence](docs/validation.md) | Summary table of validation approaches and links to public test entry points. |
| [Project scope](docs/project-scope.md) | Current boundaries and future extensions. |
| [News and changelog](changelog/CHANGELOG.md) | Release notes and documentation changes. |

## Contributing

Contributions, bug reports, reproducible examples, and methodological
discussion are welcome. Please read the [contributing guide](.github/CONTRIBUTING.md)
and [code of conduct](.github/CODE_OF_CONDUCT.md) before opening a pull
request.

## Citation

If you use `qresid` in academic work, please cite:

Soto-Becerra, P. 2026. `qresid`: Quantile and randomized quantile residuals for
Stata models. Version 1.0.0. Available from
https://github.com/psotob91/qresid

## Maintainer

| Role | Name | Affiliation | Contact |
|---|---|---|---|
| Maintainer | Percy Soto-Becerra, MD, MSc, PhD(c) | Universidad Privada del Norte, Lima, Peru | percy.soto@upn.edu.pe; percys1991@gmail.com |

## License

MIT
