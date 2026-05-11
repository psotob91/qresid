# qresid examples

This directory contains executable examples for the current public release
scope. The examples cover Gaussian, Bernoulli and binomial, Poisson, negative
binomial, Gamma, inverse Gaussian, frequency-weighted specifications, selected
direct probability-weighted diagnostics, and documented count-model
specifications. Hurdle examples require the relevant user-written estimator to
be installed separately.

Run all examples from the package root with:

```stata
do examples/run_examples.do
```

The examples use only built-in Stata datasets or simulated data. Direct
`pweight` examples are model-based diagnostics from `[pweight=]` fits and do
not claim `svy:` support. The examples do not claim support for `aweight`,
`iweight`, unsupported weighted routes, weighted truncated/censored routes,
hurdle specifications outside documented unweighted `hplogit`/`hnblogit`, correlated,
panel, multilevel, finite-mixture, or mixed models.

Release checks run these examples under `version 15.0` with `set varabbrev off`.
