version 15.0
set more off
set varabbrev off
clear all
set more off
set seed 20260511

capture confirm file "qresid.ado"
if _rc {
    capture confirm file "qresid/qresid.ado"
    if !_rc {
        cd "qresid"
    }
}

capture confirm file "qresid.ado"
if _rc {
    display as err "Run this do-file from the qresid repository root or its parent."
    exit 601
}

adopath ++ "."
capture adopath ++ "../04_RETRIEVAL_CONTEXT/EXTERNAL_REPOS/STATA/hurdle_count_hilbe_hardin"
capture sysdir set PLUS "../04_RETRIEVAL_CONTEXT/EXTERNAL_REPOS/STATA/st0279"

capture mkdir "docs"
capture mkdir "docs/assets"
capture mkdir "docs/assets/img"
capture mkdir "docs/assets/output"

capture program drop _manual_snippet_start
program define _manual_snippet_start
    version 15.0
    syntax, Name(string)
    capture log close manual_snippet
    log using "docs/assets/output/`name'.txt", text replace name(manual_snippet)
end

capture program drop _manual_snippet_end
program define _manual_snippet_end
    version 15.0
    capture log close manual_snippet
end

capture program drop _manual_qnorm
program define _manual_qnorm
    version 15.0
    syntax varname, Name(string)
    qnorm `varlist', name(qmanual_graph, replace) ///
        title("Normal quantile plot") subtitle("`name'")
    graph export "docs/assets/img/`name'_qnorm.png", replace width(1400)
    graph drop qmanual_graph
end

capture program drop _manual_scatter
program define _manual_scatter
    version 15.0
    syntax varlist(min=2 max=2), Name(string) XTItle(string)
    gettoken y x : varlist
    scatter `y' `x', yline(0, lpattern(dash)) name(qmanual_graph, replace) ///
        title("Residual diagnostic plot") subtitle("`name'") ///
        ytitle("Quantile residual") xtitle("`xtitle'")
    graph export "docs/assets/img/`name'_scatter.png", replace width(1400)
    graph drop qmanual_graph
end

capture program drop _manual_scatter_ytitle
program define _manual_scatter_ytitle
    version 15.0
    syntax varlist(min=2 max=2), Name(string) XTItle(string) YTItle(string)
    gettoken y x : varlist
    scatter `y' `x', yline(0, lpattern(dash)) name(qmanual_graph, replace) ///
        title("Residual diagnostic plot") subtitle("`name'") ///
        ytitle("`ytitle'") xtitle("`xtitle'")
    graph export "docs/assets/img/`name'_scatter.png", replace width(1400)
    graph drop qmanual_graph
end

capture program drop _manual_lowess_ytitle
program define _manual_lowess_ytitle
    version 15.0
    syntax varlist(min=2 max=2), Name(string) XTItle(string) YTItle(string) [BW(real .35)]
    gettoken y x : varlist
    twoway ///
        (scatter `y' `x', msize(vsmall) mcolor(gs10)) ///
        (lowess `y' `x', lcolor(navy) bwidth(`bw')), ///
        yline(0, lpattern(dash)) legend(off) name(qmanual_graph, replace) ///
        title("Residual diagnostic plot") subtitle("`name'") ///
        ytitle("`ytitle'") xtitle("`xtitle'")
    graph export "docs/assets/img/`name'_lowess.png", replace width(1400)
    graph drop qmanual_graph
end

capture program drop _manual_count_summary
program define _manual_count_summary
    version 15.0
    syntax varname
    quietly summarize `varlist'
    local mean = r(mean)
    local variance = r(Var)
    local zeros = 100 * sum(`varlist' == 0) / _N
    display as text "Observed mean: " as result %9.4f `mean'
    display as text "Observed variance: " as result %9.4f `variance'
    display as text "Variance / mean: " as result %9.4f (`variance' / `mean')
    display as text "Percent zero: " as result %9.2f `zeros'
end

display as text "QRESID_MANUAL_ASSETS_START"

* Continuous: Gaussian regression where the diagnostic scale is familiar.
sysuse auto, clear
_manual_snippet_start, name("continuous_gaussian_output")
regress price mpg weight
qresid rq_gauss
summarize rq_gauss
_manual_snippet_end
predict double fit_gauss, xb
_manual_qnorm rq_gauss, name("continuous_gaussian")
_manual_scatter rq_gauss fit_gauss, name("continuous_gaussian_fitted") xtitle("Fitted price")

* Continuous: positive right-skewed response, comparing Gaussian, Gamma, and inverse Gaussian.
clear
set obs 260
generate double x = rnormal()
generate double mu = exp(.4 + .55*x)
generate double y = rgamma(2, mu/2)

_manual_snippet_start, name("continuous_positive_output")
regress y x
qresid rq_pos_gauss
glm y x, family(gamma) link(log)
qresid rq_pos_gamma
glm y x, family(igaussian) link(log)
qresid rq_pos_ig
summarize rq_pos_gauss rq_pos_gamma rq_pos_ig
_manual_snippet_end
predict double fit_ig, mu
_manual_qnorm rq_pos_gauss, name("continuous_positive_gaussian")
_manual_qnorm rq_pos_gamma, name("continuous_positive_gamma")
_manual_qnorm rq_pos_ig, name("continuous_positive_igaussian")
_manual_scatter rq_pos_ig fit_ig, name("continuous_positive_ig_fitted") xtitle("Fitted mean")

* Binomial counts with few values: data generated from a complementary log-log link.
clear
set obs 900
generate int id = _n
generate double x = runiform()*3
generate byte trials = 5
generate double v = (mod(id*37, 100) + .5) / 101
generate double p = 1 - exp(-exp(-3.7 + 2.8*x))
replace p = min(max(p, .001), .999)
generate byte y = rbinomial(trials, p)

_manual_snippet_start, name("binary_links_output")
tabulate y
glm y x, family(binomial trials) link(loglog)
predict double pearson_link_loglog, pearson
predict double deviance_link_loglog, deviance
qresid rq_bin_loglog, uvar(v)
predict double phat_loglog, mu
estat ic
glm y x, family(binomial trials) link(cloglog)
qresid rq_bin_cloglog, uvar(v)
predict double phat_cloglog, mu
estat ic
summarize pearson_link_loglog deviance_link_loglog rq_bin_loglog rq_bin_cloglog
_manual_snippet_end
_manual_qnorm rq_bin_loglog, name("binary_loglog")
_manual_qnorm rq_bin_cloglog, name("binary_cloglog")
_manual_scatter_ytitle pearson_link_loglog x, name("binary_link_loglog_pearson_x") xtitle("Covariate x") ytitle("Pearson residual")
_manual_scatter_ytitle deviance_link_loglog x, name("binary_link_loglog_deviance_x") xtitle("Covariate x") ytitle("Deviance residual")
_manual_scatter_ytitle rq_bin_loglog x, name("binary_link_loglog_qres_x") xtitle("Covariate x") ytitle("Quantile residual")
_manual_scatter_ytitle rq_bin_cloglog x, name("binary_cloglog_x") xtitle("Covariate x") ytitle("Quantile residual")

* Binary: Pearson and deviance residuals are hard to read in sparse binary data.
clear
set obs 520
generate int id = _n
generate double x = rnormal()
generate double v = (mod(id*31, 100) + .5) / 101
generate double p = invlogit(-2.1 + 1.35*x)
generate byte y = runiform() < p

_manual_snippet_start, name("binary_residual_comparison_output")
glm y x, family(binomial) link(logit)
predict double pearson_bin, pearson
predict double deviance_bin, deviance
qresid rq_binary, uvar(v)
summarize pearson_bin deviance_bin rq_binary
_manual_snippet_end
_manual_qnorm pearson_bin, name("binary_pearson")
_manual_qnorm deviance_bin, name("binary_deviance")
_manual_qnorm rq_binary, name("binary_quantile")
_manual_scatter_ytitle pearson_bin x, name("binary_pearson_x") xtitle("Covariate x") ytitle("Pearson residual")
_manual_scatter_ytitle rq_binary x, name("binary_quantile_x") xtitle("Covariate x") ytitle("Quantile residual")

* Binary: nonlinear mean structure, linear logit versus quadratic logit.
clear
set obs 850
generate int id = _n
generate double x = runiform()*5 - 2.5
generate double x2 = x^2
generate double v = (mod(id*67, 100) + .5) / 101
generate double p = invlogit(-2.35 + .88*x2)
generate byte y = runiform() < p

_manual_snippet_start, name("binary_nonlinearity_output")
glm y x, family(binomial) link(logit)
predict double pearson_lin, pearson
predict double deviance_lin, deviance
qresid rq_logit_linear, uvar(v)
glm y x x2, family(binomial) link(logit)
qresid rq_logit_quadratic, uvar(v)
estat ic
summarize pearson_lin deviance_lin rq_logit_linear rq_logit_quadratic
_manual_snippet_end
_manual_scatter_ytitle pearson_lin x, name("binary_nonlinear_pearson_x") xtitle("Covariate x") ytitle("Pearson residual")
_manual_scatter_ytitle deviance_lin x, name("binary_nonlinear_deviance_x") xtitle("Covariate x") ytitle("Deviance residual")
_manual_scatter_ytitle rq_logit_linear x, name("binary_nonlinear_qres_linear_x") xtitle("Covariate x") ytitle("Quantile residual")
_manual_scatter_ytitle rq_logit_quadratic x, name("binary_nonlinear_qres_quadratic_x") xtitle("Covariate x") ytitle("Quantile residual")
_manual_qnorm rq_logit_linear, name("binary_nonlinear_qres_linear")
_manual_qnorm rq_logit_quadratic, name("binary_nonlinear_qres_quadratic")

* Binary: subtle seasonal functional form, simple time trend versus Fourier terms.
clear
set obs 1600
generate int id = _n
generate double t = (_n - 1) / (_N - 1)
generate double s1 = sin(2*_pi*t)
generate double c1 = cos(2*_pi*t)
generate double s2 = sin(4*_pi*t)
generate double c2 = cos(4*_pi*t)
generate double v = (mod(id*79, 100) + .5) / 101
generate double eta = -1.25 + 1.45*s1 - .85*c1 + 1.30*s2 - .45*c2
generate double p = invlogit(eta)
generate byte y = runiform() < p

_manual_snippet_start, name("binary_seasonal_functional_form_output")
glm y t, family(binomial) link(logit)
predict double pearson_seasonal, pearson
predict double deviance_seasonal, deviance
qresid rq_seasonal_linear, uvar(v)
estat ic
glm y s1 c1 s2 c2, family(binomial) link(logit)
qresid rq_seasonal_fourier, uvar(v)
estat ic
summarize pearson_seasonal deviance_seasonal rq_seasonal_linear rq_seasonal_fourier
_manual_snippet_end
_manual_scatter_ytitle pearson_seasonal t, name("binary_seasonal_pearson_t") xtitle("Seasonal time") ytitle("Pearson residual")
_manual_scatter_ytitle deviance_seasonal t, name("binary_seasonal_deviance_t") xtitle("Seasonal time") ytitle("Deviance residual")
_manual_scatter_ytitle rq_seasonal_linear t, name("binary_seasonal_qres_linear_t") xtitle("Seasonal time") ytitle("Quantile residual")
_manual_scatter_ytitle rq_seasonal_fourier t, name("binary_seasonal_qres_fourier_t") xtitle("Seasonal time") ytitle("Quantile residual")
_manual_lowess_ytitle rq_seasonal_linear t, name("binary_seasonal_qres_linear_t") xtitle("Seasonal time") ytitle("Quantile residual") bw(.14)
_manual_lowess_ytitle rq_seasonal_fourier t, name("binary_seasonal_qres_fourier_t") xtitle("Seasonal time") ytitle("Quantile residual") bw(.14)
_manual_qnorm rq_seasonal_linear, name("binary_seasonal_qres_linear")
_manual_qnorm rq_seasonal_fourier, name("binary_seasonal_qres_fourier")

* Binomial counts with trials.
clear
set obs 220
generate int id = _n
generate double x = runiform()*2 - 1
generate int trials = 8 + mod(_n, 5)
generate double p = invlogit(-.4 + .9*x)
generate int y = rbinomial(trials, p)
generate double v = (mod(id*41, 100) + .5) / 101

_manual_snippet_start, name("binomial_counts_output")
glm y x, family(binomial trials) link(logit)
qresid rq_bincount, uvar(v)
summarize rq_bincount
_manual_snippet_end
predict double phat_bincount, mu
_manual_qnorm rq_bincount, name("binomial_counts")
_manual_scatter rq_bincount phat_bincount, name("binomial_counts_fitted") xtitle("Fitted proportion")

* Counts: overdispersed data, Poisson versus negative binomial.
clear
set obs 500
generate int id = _n
generate double x = rnormal()
generate double mu = exp(.35 + .45*x)
generate double theta = 1.4
generate double pnb = theta/(theta + mu)
generate int y = rnbinomial(theta, pnb)
generate double v = (mod(id*43, 100) + .5) / 101

_manual_snippet_start, name("counts_poisson_nb_output")
_manual_count_summary y
poisson y x
qresid rq_pois, uvar(v)
predict double fit_pois, n
estat gof
estat ic
nbreg y x
qresid rq_nb, uvar(v)
predict double fit_nb, n
estat ic
summarize rq_pois rq_nb
_manual_snippet_end
_manual_qnorm rq_pois, name("counts_poisson")
_manual_qnorm rq_nb, name("counts_nb")
_manual_scatter rq_nb fit_nb, name("counts_nb_fitted") xtitle("Fitted mean")

* Special counts: zero-inflated, truncated, and censored examples.
clear
set obs 420
generate int id = _n
generate double x = rnormal()
generate double z = rnormal()
generate double mu = exp(.25 + .35*x)
generate double pi0 = invlogit(-1 + .7*z)
generate int y_zip = cond(runiform() < pi0, 0, rpoisson(mu))
generate double v = (mod(id*47, 100) + .5) / 101

_manual_snippet_start, name("special_counts_output")
zip y_zip x, inflate(z)
qresid rq_zip, uvar(v)
summarize rq_zip
generate int y_trunc = rpoisson(mu)
replace y_trunc = y_trunc + 1 if y_trunc == 0
tpoisson y_trunc x, ll(0)
qresid rq_tpois, uvar(v)
summarize rq_tpois
generate int y_cens = rpoisson(mu)
replace y_cens = 1 if y_cens <= 1
replace y_cens = 8 if y_cens >= 8
cpoisson y_cens x, ll(1) ul(8)
qresid rq_cpois, uvar(v)
summarize rq_cpois
_manual_snippet_end
_manual_qnorm rq_zip, name("special_zip")
_manual_qnorm rq_tpois, name("special_truncated")
_manual_qnorm rq_cpois, name("special_censored")

* Special counts: one data-generating process, several count candidates.
clear
set obs 650
generate int id = _n
generate double x = rnormal()
generate double z = rnormal()
generate double mu = exp(.20 + .55*x)
generate double theta = .55
generate double pnb = theta/(theta + mu)
generate double pi0 = invlogit(-.75 + 1.20*z)
generate int y = cond(runiform() < pi0, 0, rnbinomial(theta, pnb))
generate double v = (mod(id*73, 100) + .5) / 101
_manual_snippet_start, name("special_model_choice_output")
_manual_count_summary y
poisson y x
qresid rq_mc_pois, uvar(v)
predict double fit_mc_pois, n
estat gof
estat ic
nbreg y x
qresid rq_mc_nb, uvar(v)
predict double fit_mc_nb, n
estat ic
capture noisily gpoisson y x, nolog iterate(120)
if !_rc {
    qresid rq_mc_gp, uvar(v)
    predict double fit_mc_gp, n
    estat ic
}
zip y x, inflate(z)
qresid rq_mc_zip, uvar(v)
predict double fit_mc_zip, n
estat ic
zinb y x, inflate(z)
qresid rq_mc_zinb, uvar(v)
predict double fit_mc_zinb, n
estat ic
summarize rq_mc_pois rq_mc_nb rq_mc_zip rq_mc_zinb
_manual_snippet_end
_manual_qnorm rq_mc_pois, name("special_choice_poisson")
_manual_qnorm rq_mc_nb, name("special_choice_nb")
capture confirm variable rq_mc_gp
if !_rc {
    _manual_qnorm rq_mc_gp, name("special_choice_gpoisson")
}
_manual_qnorm rq_mc_zip, name("special_choice_zip")
_manual_qnorm rq_mc_zinb, name("special_choice_zinb")
_manual_lowess_ytitle rq_mc_pois fit_mc_pois, name("special_choice_poisson_fitted") xtitle("Fitted mean") ytitle("Quantile residual")
_manual_lowess_ytitle rq_mc_zinb fit_mc_zinb, name("special_choice_zinb_fitted") xtitle("Fitted mean") ytitle("Quantile residual")

* Generalized Poisson, if the documented external estimator is available.
capture which gpoisson
if !_rc {
    clear
    set obs 360
    generate int id = _n
    generate double x = rnormal()
    generate double mu = exp(.30 + .30*x)
    generate int y = rpoisson(mu)
    generate double v = (mod(id*53, 100) + .5) / 101
    _manual_snippet_start, name("gpoisson_output")
    gpoisson y x, nolog iterate(80)
    qresid rq_gpois, uvar(v)
    summarize rq_gpois
    _manual_snippet_end
    _manual_qnorm rq_gpois, name("gpoisson")
}
else {
    file open fh using "docs/assets/output/gpoisson_output.txt", write replace
    file write fh "The documented external gpoisson estimator was not available in this Stata session." _n
    file write fh "Install or add the Stata Journal st0279 source before running this example." _n
    file close fh
}

* Generalized Poisson: underdispersed count example compared with Poisson and NB.
capture which gpoisson
if !_rc {
    clear
    set obs 420
    generate int id = _n
    generate double x = runiform()*2 - 1
    generate double mu = exp(1.15 + .30*x)
    generate double p_under = mu/10
    generate int y = rbinomial(10, p_under)
    generate double v = (mod(id*71, 100) + .5) / 101
    _manual_snippet_start, name("counts_underdispersed_output")
    poisson y x
    qresid rq_under_pois, uvar(v)
    capture noisily nbreg y x
    if !_rc {
        capture noisily qresid rq_under_nb, uvar(v)
        if _rc {
            display as text "Negative-binomial residual skipped: fitted endpoints were not stable for this underdispersed example."
        }
    }
    capture noisily gpoisson y x, nolog iterate(120)
    if !_rc {
        qresid rq_under_gp, uvar(v)
        summarize rq_under_pois rq_under_gp
    }
    _manual_snippet_end
    _manual_qnorm rq_under_pois, name("counts_under_pois")
    capture confirm variable rq_under_nb
    if !_rc {
        _manual_qnorm rq_under_nb, name("counts_under_nb")
    }
    capture confirm variable rq_under_gp
    if !_rc {
        _manual_qnorm rq_under_gp, name("counts_under_gpoisson")
    }
}
else {
    file open fh using "docs/assets/output/counts_underdispersed_output.txt", write replace
    file write fh "The documented external gpoisson estimator was not available in this Stata session." _n
    file close fh
}

* Hurdle count: external hplogit/hnblogit examples, if available.
capture which hplogit
local has_hplogit = !_rc
capture which hnblogit
local has_hnblogit = !_rc
if `has_hplogit' & `has_hnblogit' {
    clear
    set obs 260
    generate int id = _n
    generate double x = rnormal()
    generate double p0 = invlogit(-.25 + .55*x)
    generate double mu = exp(.35 + .25*x)
    generate int y = 0
    quietly forvalues i = 1/260 {
        if runiform() > p0[`i'] {
            local yy = 0
            while `yy' == 0 {
                local yy = rpoisson(mu[`i'])
            }
            replace y = `yy' in `i'
        }
    }
    generate double v = (mod(id*59, 100) + .5) / 101
    _manual_snippet_start, name("hurdle_output")
    zip y x, inflate(x)
    qresid rq_zip_compare, uvar(v)
    hplogit y x, nolog
    qresid rq_hplogit, uvar(v)
    summarize rq_zip_compare rq_hplogit
    _manual_snippet_end
    _manual_qnorm rq_zip_compare, name("hurdle_zip_compare")
    _manual_qnorm rq_hplogit, name("hurdle_hplogit")
}
else {
    file open fh using "docs/assets/output/hurdle_output.txt", write replace
    file write fh "The external hplogit/hnblogit estimators were not available in this Stata session." _n
    file write fh "Use findit hplogit and findit hnblogit, or add the documented source path, before running this example." _n
    file close fh
}

* Weights and dispersion.
sysuse auto, clear
generate int fw = cond(_n <= 20, 2, 1)
_manual_snippet_start, name("weights_dispersion_output")
regress price mpg weight [fweight=fw]
qresid rq_fw
summarize rq_fw
_manual_snippet_end
_manual_qnorm rq_fw, name("weights_fweight")
clear
set obs 160
generate double x = rnormal()
generate double y = rgamma(2, exp(.4 + .35*x)/2)
_manual_snippet_start, name("dispersion_output")
glm y x, family(gamma) link(log)
qresid rq_gamma_default
qresid rq_gamma_phi, dispersion(.35)
summarize rq_gamma_default rq_gamma_phi
_manual_snippet_end
_manual_qnorm rq_gamma_phi, name("dispersion_gamma_fixed")

display as result "QRESID_MANUAL_ASSETS_STATUS PASS"
display as text "QRESID_MANUAL_ASSETS_END"
