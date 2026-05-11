# Statistical background

Quantile residuals use the probability integral transform (PIT) to place
observations on a common normal-quantile scale. For discrete outcomes, the
randomized form is often called the randomized quantile residual (RQR) or
Dunn-Smyth residual.

Let the fitted conditional cumulative distribution function (CDF) for
observation $i$ be

```math
F_i(y_i;\widehat{\theta}).
```

For continuous outcomes, the PIT value is

```math
U_i = F_i(y_i;\widehat{\theta}),
```

and the corresponding quantile residual is

```math
r_i = \Phi^{-1}(U_i),
```

where $\Phi$ is the standard normal CDF. Under correct model specification and
ignoring the usual effect of parameter estimation, the residuals are
approximately standard normal.

For discrete outcomes, define

```math
F_{\mathrm{low},i}=P(Y_i \lt y_i), \qquad
F_{\mathrm{high},i}=P(Y_i \le y_i).
```

Randomized quantile residuals sample uniformly within the fitted probability
interval assigned to the observed outcome:

```math
U_i =
F_{\mathrm{low},i}
{}+ V_i\left\{F_{\mathrm{high},i}-F_{\mathrm{low},i}\right\},
\qquad V_i \sim \mathrm{Uniform}(0,1).
```

The randomized residual is then

```math
r_i = \Phi^{-1}(U_i).
```

This construction avoids many of the artificial discreteness patterns commonly
observed with Pearson or deviance residuals in binary-response and low-count
settings. The same PIT logic extends to more complex outcomes once the fitted
CDF is specified.

## Special count structures

For zero-inflated models, let $\pi_i$ be the fitted probability of a structural
zero and let $F_{0i}$ be the CDF of the ordinary count component:

```math
F_i(y)=
\begin{cases}
\pi_i + (1-\pi_i)F_{0i}(0), & y=0,\\
\pi_i + (1-\pi_i)F_{0i}(y), & y \gt 0.
\end{cases}
```

For truncated models, the residual is based on the distribution conditional on
being observable. If the untruncated CDF is $F_{0i}$ and the observed support
is $L_i \lt Y_i \le U_i$, then

```math
F_{Ti}(y)=
\frac{F_{0i}(y)-F_{0i}(L_i)}
     {F_{0i}(U_i)-F_{0i}(L_i)}.
```

For censored outcomes, if the observed information is
$a_i \lt Y_i \le b_i$, then

```math
U_i =
F_i(a_i)
{}+ V_i\left\{F_i(b_i)-F_i(a_i)\right\},
\qquad V_i \sim \mathrm{Uniform}(0,1).
```

For hurdle count models, let $\pi_i=P(Y_i=0)$, and let $F_{+i}$ be the CDF of
the positive count component, truncated so that it starts at 1:

```math
P(Y_i=0)=\pi_i,\qquad
F_i(y)=\pi_i+(1-\pi_i)F_{+i}(y), \quad y \gt 0.
```

The diagnostic value is that different probability models can be compared on
one normal-score scale while still respecting each model's fitted probability
law.

## References

Dunn, P. K., and G. K. Smyth. 1996. Randomized quantile residuals. *Journal of
Computational and Graphical Statistics* 5(3): 236-244.
doi:10.1080/10618600.1996.10474708.

Dunn, P. K., and G. K. Smyth. 2018. *Generalized Linear Models With Examples
in R*. New York: Springer.

Giner, G., and G. K. Smyth. 2016. statmod: Probability calculations for the
inverse Gaussian distribution. *The R Journal* 8(1): 339-351.

Feng, C., L. Li, and A. Sadeghpour. 2020. A comparison of residual diagnosis
tools for diagnosing regression models for count data. *BMC Medical Research
Methodology* 20: 175.

Bai, W., M. Dong, L. Li, C. Feng, et al. 2021. Randomized quantile residuals
for diagnosing zero-inflated generalized linear mixed models with applications
to microbiome count data. *BMC Bioinformatics* 22: 564.

Yee, T. W., and C. Ma. 2024. Altered, inflated, truncated, and deflated
regression. *Statistical Science* 39(4): 568-588.

Zeileis, A., C. Kleiber, and S. Jackman. 2008. Regression models for count data
in R. *Journal of Statistical Software* 27(8): 1-25.
