version 15.0
set more off

set varabbrev off
capture log close qresid_examples
capture mkdir "examples/logs"
local stamp = subinstr("`c(current_date)'_`c(current_time)'", " ", "_", .)
local stamp = subinstr("`stamp'", ":", "", .)
local stamp = subinstr("`stamp'", "/", "", .)
local stamp = subinstr("`stamp'", "-", "", .)
local logfile "examples/logs/`stamp'_examples.log"

log using "`logfile'", text replace name(qresid_examples)

display as text "QRESID_EXAMPLES_START"
adopath ++ "."

do "examples/example_gaussian.do"
display as result "QRESID_EXAMPLE_GAUSSIAN PASS"

do "examples/example_poisson.do"
display as result "QRESID_EXAMPLE_POISSON PASS"

do "examples/example_bernoulli.do"
display as result "QRESID_EXAMPLE_BERNOULLI PASS"

do "examples/example_binreg.do"
display as result "QRESID_EXAMPLE_BINREG PASS"

do "examples/example_gamma.do"
display as result "QRESID_EXAMPLE_GAMMA PASS"

do "examples/example_igaussian.do"
display as result "QRESID_EXAMPLE_IGAUSSIAN PASS"

do "examples/example_fweight_gaussian.do"
display as result "QRESID_EXAMPLE_FWEIGHT_GAUSSIAN PASS"

do "examples/example_fweight_poisson.do"
display as result "QRESID_EXAMPLE_FWEIGHT_POISSON PASS"

do "examples/example_fweight_bernoulli.do"
display as result "QRESID_EXAMPLE_FWEIGHT_BERNOULLI PASS"

do "examples/example_fweight_grouped_binomial.do"
display as result "QRESID_EXAMPLE_FWEIGHT_GROUPED_BINOMIAL PASS"

do "examples/example_fweight_nb.do"
display as result "QRESID_EXAMPLE_FWEIGHT_NB PASS"

do "examples/example_nb_variants.do"
display as result "QRESID_EXAMPLE_NB_VARIANTS PASS"

do "examples/example_zero_inflated.do"
display as result "QRESID_EXAMPLE_ZERO_INFLATED PASS"

do "examples/example_truncated_count.do"
display as result "QRESID_EXAMPLE_TRUNCATED_COUNT PASS"

do "examples/example_censored_count.do"
display as result "QRESID_EXAMPLE_CENSORED_COUNT PASS"

do "examples/example_hurdle_count.do"
display as result "QRESID_EXAMPLE_HURDLE_COUNT PASS"

do "examples/example_fweight_gamma.do"
display as result "QRESID_EXAMPLE_FWEIGHT_GAMMA PASS"

do "examples/example_fweight_igaussian.do"
display as result "QRESID_EXAMPLE_FWEIGHT_IGAUSSIAN PASS"

do "examples/example_pweight_gaussian.do"
display as result "QRESID_EXAMPLE_PWEIGHT_GAUSSIAN PASS"

do "examples/example_pweight_poisson.do"
display as result "QRESID_EXAMPLE_PWEIGHT_POISSON PASS"

do "examples/example_pweight_bernoulli.do"
display as result "QRESID_EXAMPLE_PWEIGHT_BERNOULLI PASS"

display as result "QRESID_EXAMPLES_STATUS PASS"
display as text "QRESID_EXAMPLES_END"
log close qresid_examples
