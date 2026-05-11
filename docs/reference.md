# qresid reference

This Markdown reference mirrors the public Stata help at a high level for
GitHub readers. The authoritative command reference is the Stata help file:

```stata
help qresid
```

`qresid` requires Stata 15.0 or newer.

## Syntax

```stata
qresid newvarname [if] [in] [, options]
```

Main options:

| Option | Description |
|---|---|
| `seed(integer)` | Set Stata's random-number seed before drawing randomized PIT values. |
| `uvar(varname)` | Use externally supplied uniform values for discrete residuals. |
| `type(quantile)` | Default normal-score quantile residual. |
| `type(adjusted)` | Leverage-adjusted residual where supported. |
| `type(studentized)` | Alias for `type(adjusted)` where supported. |
| `dispersion(#)` | Use a fixed positive dispersion for Gamma or inverse-Gaussian CDF replay. |
| `family(string)` | Require `qresid`'s inferred family to match the requested family. |
| `saveflo(name)` | Save `F_low`, the lower fitted CDF endpoint. |
| `savefhi(name)` | Save `F_high`, the upper fitted CDF endpoint. |
| `saveu(name)` | Save `U`, the PIT value used before `invnormal()`. |
| `savev(name)` | Save `V`, the uniform variate used inside a discrete CDF interval. |

## Description

`qresid` creates quantile residuals after supported Stata estimation commands.
These residuals are also known as PIT residuals on the normal scale. For
discrete outcomes, the randomized form is commonly called a randomized quantile
residual.

The command evaluates the fitted conditional CDF at each observed response,
obtains a PIT value, and transforms that probability to the standard normal
scale with `invnormal()`.

## Methods and formulas

For a continuous response,

```text
U_i = F_i(y_i; theta_hat)
r_i = Phi^{-1}(U_i)
```

For a discrete response,

```text
F_low  = P(Y_i <  y_i)
F_high = P(Y_i <= y_i)
U_i    = F_low + V_i * (F_high - F_low),  V_i ~ Uniform(0,1)
r_i    = Phi^{-1}(U_i)
```

For zero-inflated, truncated, censored, and hurdle count models, the same
construction is used after building the appropriate fitted CDF.

Zero-inflated count models combine the zero mass with the ordinary count CDF:

```text
F_i(0) = pi_i + (1 - pi_i) F_0i(0)
F_i(y) = pi_i + (1 - pi_i) F_0i(y),  y > 0
```

Truncated models use the distribution conditional on the observable support:

```text
F_Ti(y) = {F_0i(y) - F_0i(L_i)} / {F_0i(U_i) - F_0i(L_i)}
```

Censored observations contribute a fitted probability interval:

```text
U_i = F_i(a_i) + V_i {F_i(b_i) - F_i(a_i)}
```

Hurdle count models combine a zero process with a positive truncated count CDF:

```text
P(Y_i = 0) = pi_i
F_i(y) = pi_i + (1 - pi_i) F_+i(y),  y > 0
```

In all cases, the final residual is still `Phi^{-1}(U_i)`. The diagnostic
advantage is that the fitted probability law, including zero mass, truncation,
censoring, or two-part structure, is read on the same normal-score scale.

`type(adjusted)` uses

```text
r_i / sqrt(1 - h_i)
```

where `h_i` is the leverage from `predict, hat`. `type(studentized)` is an
alias for the same calculation where supported.

## Stored results

`qresid` stores information in `r()` including:

| Stored result | Meaning |
|---|---|
| `r(N)` | Estimation-sample observations used by `qresid`. |
| `r(cmd)` | Stata estimation command found in `e(cmd)`. |
| `r(family)` | Fitted distributional family used for the CDF. |
| `r(type)` | Residual type requested. |
| `r(weight_type)` | Stata estimation weight type, if any. |
| `r(weight_status)` | Weight handling status used by `qresid`. |
| `r(dispersion_source)` | Whether dispersion came from Stata or from `dispersion()`. |
| `r(depvar)` | Dependent variable from the fitted model. |
| `r(residual)` | Generated residual variable. |
| `r(saveflo)`, `r(savefhi)`, `r(saveu)`, `r(savev)` | Saved auxiliary variables, if requested. |
| `r(clipped_low)`, `r(clipped_high)` | Number of PIT values moved away from 0 or 1 for numerical stability. |
| `r(phi)`, `r(lambda)`, `r(alpha)`, `r(theta)`, `r(delta)` | Distribution-specific ancillary quantities, when applicable. |

## Examples

Gaussian regression:

```stata
sysuse auto, clear
regress price mpg
qresid rq
qnorm rq
```

Poisson count model:

```stata
sysuse auto, clear
poisson rep78 mpg if rep78 < .
qresid rq_pois, seed(12345)
qnorm rq_pois
```

Bernoulli model:

```stata
sysuse auto, clear
logit foreign mpg
qresid rq_logit, seed(12345) family(bernoulli)
qnorm rq_logit
```

Gamma CDF replay with a fixed dispersion:

```stata
glm y x, family(gamma) link(log)
qresid rq_gamma
qresid rq_gamma_phi, dispersion(.5)
```

## See also

- [Supported specifications](supported-specifications.md)
- [Validation evidence](validation.md)
- [Continuous outcomes](continuous.md)
- [Count outcomes](counts.md)
- Stata help: `help qresid`
