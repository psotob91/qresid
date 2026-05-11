version 15.0
set more off

set varabbrev off
local qresid_root "`c(pwd)'"
capture confirm file "qresid.ado"
if _rc {
    display as error "QRESID_TEST_RUNNER_ERROR run tests/run_all_tests.do from the qresid repository root"
    exit 601
}
capture confirm file "qresid.sthlp"
if _rc {
    display as error "QRESID_TEST_RUNNER_ERROR qresid.sthlp not found in repository root"
    exit 601
}
adopath ++ "`qresid_root'"

capture mkdir "tests/logs"
local stamp = subinstr("`c(current_date)'_`c(current_time)'", " ", "_", .)
local stamp = subinstr("`stamp'", ":", "", .)
local stamp = subinstr("`stamp'", "/", "", .)
local stamp = subinstr("`stamp'", "-", "", .)
local suffix = floor(1000000*runiform())
local stamp "`stamp'_`suffix'"
local logfile "tests/logs/`stamp'_run_all_tests.log"

capture log close qresid_tests
log using "`logfile'", text replace name(qresid_tests)

display as text "QRESID_TEST_RUNNER_START"
display as text "ROOT `qresid_root'"
display as text "STATA_VERSION " c(stata_version)

local pass_current = 0
local expected_fail = 0
local unexpected_fail = 0

capture noisily which qresid
if _rc == 0 {
    display as result "P0-LOAD-001 PASS_CURRENT which qresid"
    local ++pass_current
}
else {
    display as error "P0-LOAD-001 UNEXPECTED_FAIL_STOP which qresid rc=" _rc
    local ++unexpected_fail
}

capture noisily findfile qresid.ado
if _rc == 0 {
    display as result "P0-LOAD-002 PASS_CURRENT findfile qresid.ado"
    local ++pass_current
}
else {
    display as error "P0-LOAD-002 UNEXPECTED_FAIL_STOP findfile qresid.ado rc=" _rc
    local ++unexpected_fail
}

capture noisily findfile qresid.sthlp
if _rc == 0 {
    display as result "P0-LOAD-003 PASS_CURRENT findfile qresid.sthlp"
    local ++pass_current
}
else {
    display as error "P0-LOAD-003 UNEXPECTED_FAIL_STOP findfile qresid.sthlp rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    regress price mpg
    capture drop qr_smoke
    qresid qr_smoke
    confirm variable qr_smoke
    summarize qr_smoke
}
if _rc == 0 {
    display as result "P0-SMOKE-001 PASS_CURRENT regress plus historical qresid"
    local ++pass_current
}
else {
    display as error "P0-SMOKE-001 UNEXPECTED_FAIL_STOP regress plus historical qresid rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    regress price mpg
    capture drop qr_seed
    qresid qr_seed, seed(123)
    confirm variable qr_seed
    summarize qr_seed
}
if _rc == 0 {
    display as result "P1B-API-001 PASS_CURRENT seed option accepted"
    local ++pass_current
}
else {
    display as error "P0-API-001 UNEXPECTED_FAIL_STOP seed option rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    regress price mpg
    qresid qr_default
    qresid qr_quantile, type(quantile)
    assert abs(qr_default - qr_quantile) < 1e-12 if e(sample)
    assert "`r(type)'" == "quantile"
}
if _rc == 0 {
    display as result "P1C-API-004 PASS_CURRENT type(quantile) preserves default"
    local ++pass_current
}
else {
    display as error "P1C-API-004 UNEXPECTED_FAIL_STOP type(quantile) rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    regress price mpg
    predict double qresid_hat, hat
    qresid qr_quantile
    qresid qr_student, type(studentized)
    assert "`r(type)'" == "studentized"
    qresid qr_adjusted, type(adjusted)
    assert "`r(type)'" == "adjusted"
    assert abs(qr_student - qr_quantile / sqrt(1 - qresid_hat)) < 1e-10 if e(sample)
    assert abs(qr_adjusted - qr_student) < 1e-10 if e(sample)
}
if _rc == 0 {
    display as result "P1C-API-005 PASS_CURRENT type(studentized) leverage standardization"
    local ++pass_current
}
else {
    display as error "P1C-API-005 UNEXPECTED_FAIL_STOP type(studentized) rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    clear
    set obs 60
    generate double x = (_n - 30) / 15
    generate double y = exp(1 + .2*x) * (1 + .1*sin(_n/4))
    glm y x, family(gamma) link(log)
    predict double qresid_hat_gamma, hat
    qresid qr_quantile_gamma
    qresid qr_adjusted_gamma, type(adjusted)
    assert abs(qr_adjusted_gamma - qr_quantile_gamma / sqrt(1 - qresid_hat_gamma)) < 1e-10 if e(sample)
    assert "`r(type)'" == "adjusted"
}
if _rc == 0 {
    display as result "P1C-API-006 PASS_CURRENT type(adjusted) gamma leverage adjustment"
    local ++pass_current
}
else {
    display as error "P1C-API-006 UNEXPECTED_FAIL_STOP type(adjusted) gamma rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    clear
    set obs 60
    generate double x = (_n - 30) / 15
    generate double mu = exp(1 + .18*x)
    generate double y = rgamma(4, mu/4)
    glm y x, family(gamma) link(log)
    predict double muhat, mu
    qresid qr_gamma_fixed, dispersion(.35) saveu(u_gamma_fixed)
    assert "`r(dispersion_source)'" == "USER_FIXED"
    assert abs(r(phi) - .35) < 1e-12
    generate double u_expected = gammap(1/.35, y/(muhat*.35))
    assert abs(u_gamma_fixed - u_expected) < 1e-10 if e(sample)
}
if _rc == 0 {
    display as result "P1C-API-006C PASS_CURRENT gamma dispersion() override"
    local ++pass_current
}
else {
    display as error "P1C-API-006C UNEXPECTED_FAIL_STOP gamma dispersion() rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    clear
    set obs 40
    generate double x = (_n - 20) / 10
    generate double y = exp(1 + .2*x) * (1 + .05*sin(_n))
    glm y x, family(gamma) link(log)
    qresid qr_bad_phi, dispersion(0)
}
if _rc != 0 {
    display as result "P1C-API-006C2 PASS_CURRENT dispersion() rejects nonpositive value rc=" _rc
    local ++pass_current
}
else {
    display as error "P1C-API-006C2 UNEXPECTED_FAIL_STOP dispersion() accepted nonpositive value"
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    poisson rep78 mpg if rep78 < .
    qresid qr_bad_disp, dispersion(.5)
}
if _rc != 0 {
    display as result "P1C-API-006D PASS_CURRENT dispersion() rejects unsupported family rc=" _rc
    local ++pass_current
}
else {
    display as error "P1C-API-006D UNEXPECTED_FAIL_STOP dispersion() accepted unsupported family"
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    regress price mpg
    qresid qr_adjusted, type(adjusted)
    qresid qr_student_alias, type(studentized)
    assert abs(qr_adjusted - qr_student_alias) < 1e-10 if e(sample)
}
if _rc == 0 {
    display as result "P1C-API-006B PASS_CURRENT type(adjusted) is canonical alias for regress"
    local ++pass_current
}
else {
    display as error "P1C-API-006B UNEXPECTED_FAIL_STOP type(adjusted) regress alias rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    poisson rep78 mpg if rep78 < .
    qresid qr_student_pois, type(studentized)
}
if _rc != 0 {
    display as result "P1C-API-007 PASS_CURRENT type(studentized) rejects non-regress/glm estimator rc=" _rc
    local ++pass_current
}
else {
    display as error "P1C-API-007 UNEXPECTED_FAIL_STOP type(studentized) accepted unsupported estimator"
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    regress price mpg
    qresid, generate(qr_generated)
}
if _rc != 0 {
    display as result "P0-API-002 PASS_CURRENT generate() rejected rc=" _rc
    local ++pass_current
}
else {
    display as error "P0-API-002 UNEXPECTED_FAIL_STOP generate() accepted"
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    regress price mpg
    generate double qr_exists = .
    qresid qr_exists
}
if _rc != 0 {
    display as result "P0-API-003 PASS_CURRENT existing output rejected rc=" _rc
    local ++pass_current
}
else {
    display as error "P0-API-003 UNEXPECTED_FAIL_STOP existing output overwritten/accepted"
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    poisson rep78 mpg if rep78 < .
    generate double qresid_u = runiform()
    qresid qr_uvar, uvar(qresid_u)
    confirm variable qr_uvar
    summarize qr_uvar
}
if _rc == 0 {
    display as result "P1B-RNG-001 PASS_CURRENT uvar option accepted"
    local ++pass_current
}
else {
    display as error "P0-RNG-001 UNEXPECTED_FAIL_STOP uvar option rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    poisson rep78 mpg if rep78 < .
    qresid qr_save, saveflo(flo) savefhi(fhi) saveu(u)
    confirm variable qr_save
    confirm variable flo
    confirm variable fhi
    confirm variable u
    assert flo <= fhi if e(sample)
    assert u >= flo & u <= fhi if e(sample)
}
if _rc == 0 {
    display as result "P1B-PIT-001 PASS_CURRENT save endpoint options accepted"
    local ++pass_current
}
else {
    display as error "P0-PIT-001 UNEXPECTED_FAIL_STOP save endpoint options rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    poisson rep78 mpg if rep78 < .
    generate double qresid_u = runiform()
    qresid qr_savev, uvar(qresid_u) savev(v)
    confirm variable qr_savev
    confirm variable v
    assert abs(v - qresid_u) < 1e-12 if e(sample)
}
if _rc == 0 {
    display as result "P1B-PIT-002 PASS_CURRENT savev() stores V"
    local ++pass_current
}
else {
    display as error "P1B-PIT-002 UNEXPECTED_FAIL_STOP savev() rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    generate byte foreign01 = foreign
    logit foreign01 mpg
    qresid qr_logit, seed(123) family(bernoulli)
    confirm variable qr_logit
    summarize qr_logit
}
if _rc == 0 {
    display as result "P1C-BERNOULLI-001 PASS_CURRENT logit Bernoulli"
    local ++pass_current
}
else {
    display as error "P1C-BERNOULLI-001 UNEXPECTED_FAIL_STOP logit rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    generate byte foreign01 = foreign
    logistic foreign01 mpg
    qresid qr_logistic, seed(123) family(bernoulli)
    confirm variable qr_logistic
    summarize qr_logistic
}
if _rc == 0 {
    display as result "P1C-BERNOULLI-002 PASS_CURRENT logistic Bernoulli"
    local ++pass_current
}
else {
    display as error "P1C-BERNOULLI-002 UNEXPECTED_FAIL_STOP logistic rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    glm price mpg, family(gaussian) link(identity)
    qresid qr_glm_gaussian, family(gaussian)
    confirm variable qr_glm_gaussian
    summarize qr_glm_gaussian
}
if _rc == 0 {
    display as result "P1C-GLM-001 PASS_CURRENT glm Gaussian"
    local ++pass_current
}
else {
    display as error "P1C-GLM-001 UNEXPECTED_FAIL_STOP glm Gaussian rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    glm rep78 mpg if rep78 < ., family(poisson) link(log)
    qresid qr_glm_poisson, seed(123) family(poisson)
    confirm variable qr_glm_poisson
    summarize qr_glm_poisson
}
if _rc == 0 {
    display as result "P1C-GLM-002 PASS_CURRENT glm Poisson"
    local ++pass_current
}
else {
    display as error "P1C-GLM-002 UNEXPECTED_FAIL_STOP glm Poisson rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    generate byte foreign01 = foreign
    glm foreign01 mpg, family(binomial) link(logit)
    qresid qr_glm_binomial, seed(123) family(bernoulli) saveflo(flo) savefhi(fhi) saveu(u)
    confirm variable qr_glm_binomial
    assert flo <= fhi if e(sample)
    assert u >= flo & u <= fhi if e(sample)
    summarize qr_glm_binomial
}
if _rc == 0 {
    display as result "P1C-BERNOULLI-003 PASS_CURRENT glm binomial individual Bernoulli"
    local ++pass_current
}
else {
    display as error "P1C-BERNOULLI-003 UNEXPECTED_FAIL_STOP glm binomial rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    generate byte foreign01 = foreign
    binreg foreign01 mpg
    qresid qr_binreg_logit, seed(123) family(bernoulli) saveflo(flo) savefhi(fhi) saveu(u)
    confirm variable qr_binreg_logit
    assert flo <= fhi if e(sample)
    assert u >= flo & u <= fhi if e(sample)
    summarize qr_binreg_logit
}
if _rc == 0 {
    display as result "P1C-BINREG-001 PASS_CURRENT binreg individual logit"
    local ++pass_current
}
else {
    display as error "P1C-BINREG-001 UNEXPECTED_FAIL_STOP binreg logit rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    clear
    set obs 40
    generate byte foreign01 = (_n <= 12)
    binreg foreign01, rr
    qresid qr_binreg_log, seed(123) family(bernoulli)
    confirm variable qr_binreg_log
    summarize qr_binreg_log
}
if _rc == 0 {
    display as result "P1C-BINREG-002 PASS_CURRENT binreg individual log"
    local ++pass_current
}
else {
    display as error "P1C-BINREG-002 UNEXPECTED_FAIL_STOP binreg rr rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    clear
    set obs 40
    generate byte foreign01 = (_n <= 12)
    binreg foreign01, rd
    qresid qr_binreg_identity, seed(123) family(bernoulli)
    confirm variable qr_binreg_identity
    summarize qr_binreg_identity
}
if _rc == 0 {
    display as result "P1C-BINREG-003 PASS_CURRENT binreg individual identity"
    local ++pass_current
}
else {
    display as error "P1C-BINREG-003 UNEXPECTED_FAIL_STOP binreg rd rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    clear
    set obs 80
    set seed 12345
    generate double x = (_n - 40) / 20
    generate double mu = exp(1 + .25*x)
    generate double y = rgamma(4, mu/4)
    glm y x, family(gamma) link(log)
    qresid qr_gamma, family(gamma) saveflo(gflo) savefhi(gfhi) saveu(gu)
    confirm variable qr_gamma
    assert gflo == gfhi if e(sample)
    assert gu == gfhi if e(sample)
    assert gu > 0 & gu < 1 if e(sample)
    summarize qr_gamma
}
if _rc == 0 {
    display as result "P1C-GAMMA-001 PASS_CURRENT glm Gamma"
    local ++pass_current
}
else {
    display as error "P1C-GAMMA-001 UNEXPECTED_FAIL_STOP glm Gamma rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    regress price mpg [aw=weight]
    qresid qr_weighted
}
if _rc != 0 {
    display as result "P1B-WEIGHTS-001 PASS_CURRENT weighted model declined rc=" _rc
    local ++pass_current
}
else {
    display as error "P1B-WEIGHTS-001 UNEXPECTED_FAIL_STOP weighted model accepted"
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    regress price mpg [fw=rep78] if rep78 < .
    qresid qr_fweight
    assert "`r(weight_status)'" == "fweight_experimental"
}
if _rc == 0 {
    display as result "EXT-WEIGHTS-001 PASS_CURRENT fweight Gaussian experimental"
    local ++pass_current
}
else {
    display as error "EXT-WEIGHTS-001 UNEXPECTED_FAIL_STOP fweight Gaussian rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    generate double pw = 1 + mod(_n, 5)/10
    regress price mpg [pw=pw]
    qresid qr_pweight
    assert "`r(weight_status)'" == "pweight_direct_experimental"
}
if _rc == 0 {
    display as result "EXT-PWEIGHT-001 PASS_CURRENT pweight direct Gaussian experimental"
    local ++pass_current
}
else {
    display as error "EXT-PWEIGHT-001 UNEXPECTED_FAIL_STOP pweight direct Gaussian rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    clear
    set obs 60
    generate int id = _n
    generate double x = (_n - 30.5) / 30
    generate int m = 8 + mod(_n, 4)
    generate double p0 = invlogit(-.1 + .6*x)
    generate int y = max(1, min(m-1, floor(m*p0 + .5)))
    generate double v_ext = (mod(id*37,100)+.5)/101
    glm y x, family(binomial m) link(logit)
    qresid qr_gbinom, uvar(v_ext) saveflo(flo_gb) savefhi(fhi_gb) saveu(u_gb)
    assert "`r(family)'" == "grouped_binomial"
    assert flo_gb <= fhi_gb if e(sample)
    assert u_gb >= flo_gb & u_gb <= fhi_gb if e(sample)
}
if _rc == 0 {
    display as result "EXT-GBINOM-001 PASS_CURRENT grouped binomial glm"
    local ++pass_current
}
else {
    display as error "EXT-GBINOM-001 UNEXPECTED_FAIL_STOP grouped binomial rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    clear
    set obs 60
    generate int id = _n
    generate double x = (_n - 30.5) / 30
    generate int m = 8 + mod(_n, 4)
    generate double p0 = invlogit(-.1 + .6*x)
    generate int y = max(1, min(m-1, floor(m*p0 + .5)))
    generate double v_ext = (mod(id*37,100)+.5)/101
    binreg y x, n(m) or
    qresid qr_binreg_gb, uvar(v_ext) saveflo(flo_brg) savefhi(fhi_brg) saveu(u_brg)
    assert "`r(family)'" == "grouped_binomial"
    assert flo_brg <= fhi_brg if e(sample)
    assert u_brg >= flo_brg & u_brg <= fhi_brg if e(sample)
}
if _rc == 0 {
    display as result "EXT-GBINOM-002 PASS_CURRENT grouped binomial binreg n()"
    local ++pass_current
}
else {
    display as error "EXT-GBINOM-002 UNEXPECTED_FAIL_STOP grouped binomial binreg rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    clear
    set obs 120
    set seed 811
    generate double x = rnormal()
    generate double mu0 = exp(.2 + .4*x)
    generate double theta0 = 3
    generate double p0 = theta0/(theta0+mu0)
    generate int y = rnbinomial(theta0, p0)
    generate double v_ext = (mod(_n*41,100)+.5)/101
    nbreg y x, dispersion(mean)
    qresid qr_nb, uvar(v_ext) saveflo(flo_nb) savefhi(fhi_nb) saveu(u_nb)
    assert "`r(family)'" == "nbreg_mean"
    assert flo_nb <= fhi_nb if e(sample)
    assert u_nb >= flo_nb & u_nb <= fhi_nb if e(sample)
}
if _rc == 0 {
    display as result "EXT-NB-001 PASS_CURRENT nbreg dispersion(mean)"
    local ++pass_current
}
else {
    display as error "EXT-NB-001 UNEXPECTED_FAIL_STOP nbreg rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    clear
    set obs 160
    set seed 8111
    generate double x = rnormal()
    generate double exposure = 0.5 + runiform()*2
    generate double mu0 = exp(.15 + .4*x + ln(exposure))
    generate double theta0 = 3
    generate double p0 = theta0/(theta0+mu0)
    generate int y = rnbinomial(theta0, p0)
    generate double v_ext = (mod(_n*41,100)+.5)/101
    nbreg y x, exposure(exposure) dispersion(mean)
    qresid qr_nb_exp, uvar(v_ext) saveflo(flo_nb_exp) savefhi(fhi_nb_exp) saveu(u_nb_exp)
    assert "`r(family)'" == "nbreg_mean"
    assert flo_nb_exp <= fhi_nb_exp if e(sample)
    assert u_nb_exp >= flo_nb_exp & u_nb_exp <= fhi_nb_exp if e(sample)
}
if _rc == 0 {
    display as result "EXT-NB-002 PASS_CURRENT nbreg dispersion(mean) exposure"
    local ++pass_current
}
else {
    display as error "EXT-NB-002 UNEXPECTED_FAIL_STOP nbreg exposure rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    clear
    set obs 160
    set seed 8112
    generate double x = rnormal()
    generate double lnoffset = ln(0.5 + runiform()*2)
    generate double mu0 = exp(.15 + .4*x + lnoffset)
    generate double theta0 = 3
    generate double p0 = theta0/(theta0+mu0)
    generate int y = rnbinomial(theta0, p0)
    generate double v_ext = (mod(_n*41,100)+.5)/101
    nbreg y x, offset(lnoffset) dispersion(mean)
    qresid qr_nb_off, uvar(v_ext) saveflo(flo_nb_off) savefhi(fhi_nb_off) saveu(u_nb_off)
    assert "`r(family)'" == "nbreg_mean"
    assert flo_nb_off <= fhi_nb_off if e(sample)
    assert u_nb_off >= flo_nb_off & u_nb_off <= fhi_nb_off if e(sample)
}
if _rc == 0 {
    display as result "EXT-NB-003 PASS_CURRENT nbreg dispersion(mean) offset"
    local ++pass_current
}
else {
    display as error "EXT-NB-003 UNEXPECTED_FAIL_STOP nbreg offset rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    clear
    set obs 120
    generate double x = (_n - 60) / 80
    generate double y = exp(1 + .35*x) + .25 + .03*sin(_n/5)
    glm y x, family(igaussian) link(log)
    qresid qr_ig, family(igaussian) saveflo(flo_ig) savefhi(fhi_ig) saveu(u_ig)
    assert "`r(family)'" == "igaussian"
    assert flo_ig == fhi_ig if e(sample)
    assert u_ig > 0 & u_ig < 1 if e(sample)
    summarize qr_ig
}
if _rc == 0 {
    display as result "EXT-IG-001 PASS_CURRENT inverse Gaussian glm"
    local ++pass_current
}
else {
    display as error "EXT-IG-001 UNEXPECTED_FAIL_STOP inverse Gaussian rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    clear
    set obs 90
    generate double x = (_n - 45) / 80
    generate double y = exp(.8 + .14*x) + .24 + .01*cos(_n/7)
    glm y x, family(igaussian) link(log)
    predict double muhat, mu
    qresid qr_ig_fixed, dispersion(.42) saveu(u_ig_fixed)
    assert "`r(dispersion_source)'" == "USER_FIXED"
    assert abs(r(phi) - .42) < 1e-12
    generate double lambda = 1/.42
    generate double z1 = sqrt(lambda/y) * (y/muhat - 1)
    generate double z2 = -sqrt(lambda/y) * (y/muhat + 1)
    generate double logterm = 2*lambda/muhat + lnnormal(z2)
    generate double u_expected = normal(z1) + cond(logterm < -745, 0, exp(logterm))
    assert abs(u_ig_fixed - u_expected) < 1e-10 if e(sample)
}
if _rc == 0 {
    display as result "EXT-IG-001B PASS_CURRENT inverse Gaussian dispersion() override"
    local ++pass_current
}
else {
    display as error "EXT-IG-001B UNEXPECTED_FAIL_STOP inverse Gaussian dispersion() rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    clear
    set obs 100
    generate double x = (_n - 50) / 100
    generate byte y = mod(_n, 2)
    generate int fw = 1 + mod(_n, 3)
    logit y x [fweight=fw]
    qresid qr_fw_bern, seed(123)
    assert "`r(weight_status)'" == "fweight_experimental"
}
if _rc == 0 {
    display as result "EXT-FWEIGHT-002 PASS_CURRENT fweight Bernoulli"
    local ++pass_current
}
else {
    display as error "EXT-FWEIGHT-002 UNEXPECTED_FAIL_STOP fweight Bernoulli rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    clear
    set obs 100
    generate double x = (_n - 50) / 100
    generate double mu0 = exp(1 + .2*x)
    generate double y = rgamma(5, mu0/5)
    generate int fw = 1 + mod(_n, 4)
    glm y x [fweight=fw], family(gamma) link(log)
    qresid qr_fw_gamma
    assert "`r(weight_status)'" == "fweight_experimental"
}
if _rc == 0 {
    display as result "EXT-FWEIGHT-003 PASS_CURRENT fweight Gamma"
    local ++pass_current
}
else {
    display as error "EXT-FWEIGHT-003 UNEXPECTED_FAIL_STOP fweight Gamma rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    clear
    set obs 90
    generate double x = (_n - 45) / 90
    generate int m = 8 + mod(_n, 4)
    generate double p0 = invlogit(-.2 + .35*x)
    generate int y = floor(m*p0)
    replace y = max(1, min(m-1, y))
    generate int fw = 1 + mod(_n, 3)
    generate double v_ext = (mod(_n*31,100)+.5)/101
    glm y x [fweight=fw], family(binomial m) link(logit)
    qresid qr_fw_gb, uvar(v_ext)
    assert "`r(family)'" == "grouped_binomial"
    assert "`r(weight_status)'" == "fweight_experimental"
}
if _rc == 0 {
    display as result "EXT-FWEIGHT-004 PASS_CURRENT fweight grouped binomial"
    local ++pass_current
}
else {
    display as error "EXT-FWEIGHT-004 UNEXPECTED_FAIL_STOP fweight grouped binomial rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    clear
    set obs 120
    set seed 812
    generate double x = rnormal()
    generate double mu0 = exp(.25 + .35*x)
    generate double theta0 = 3
    generate double p0 = theta0/(theta0+mu0)
    generate int y = rnbinomial(theta0, p0)
    generate int fw = 1 + mod(_n, 3)
    generate double v_ext = (mod(_n*43,100)+.5)/101
    nbreg y x [fweight=fw], dispersion(mean)
    qresid qr_fw_nb, uvar(v_ext)
    assert "`r(family)'" == "nbreg_mean"
    assert "`r(weight_status)'" == "fweight_experimental"
}
if _rc == 0 {
    display as result "EXT-FWEIGHT-005 PASS_CURRENT fweight NB"
    local ++pass_current
}
else {
    display as error "EXT-FWEIGHT-005 UNEXPECTED_FAIL_STOP fweight NB rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    clear
    set obs 100
    generate double x = (_n - 50) / 100
    generate double y = exp(.8 + .3*x) + .2 + .02*cos(_n/5)
    generate int fw = 1 + mod(_n, 3)
    glm y x [fweight=fw], family(igaussian) link(log)
    qresid qr_fw_ig
    assert "`r(family)'" == "igaussian"
    assert "`r(weight_status)'" == "fweight_experimental"
}
if _rc == 0 {
    display as result "EXT-FWEIGHT-006 PASS_CURRENT fweight inverse Gaussian"
    local ++pass_current
}
else {
    display as error "EXT-FWEIGHT-006 UNEXPECTED_FAIL_STOP fweight inverse Gaussian rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    regress price mpg
    qresid qr_family_bad, family(poisson)
}
if _rc != 0 {
    display as result "P1B-API-004 PASS_CURRENT contradictory family() rejected rc=" _rc
    local ++pass_current
}
else {
    display as error "P1B-API-004 UNEXPECTED_FAIL_STOP contradictory family() accepted"
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    regress price mpg
    qresid qr_if if _n <= 10
    count if !missing(qr_if)
    assert r(N) == 10
}
if _rc == 0 {
    display as result "P1B-SAMPLE-001 PASS_CURRENT if restriction respected"
    local ++pass_current
}
else {
    display as error "P1B-SAMPLE-001 UNEXPECTED_FAIL_STOP if restriction rc=" _rc
    local ++unexpected_fail
}

capture noisily {
    sysuse auto, clear
    regress price mpg
    capture drop qr_return
    qresid qr_return
    return list
    confirm scalar r(N)
    assert r(N) > 0
}
if _rc == 0 {
    display as result "P1B-RETURN-001 PASS_CURRENT r() results available"
    local ++pass_current
}
else {
    display as error "P0-RETURN-001 UNEXPECTED_FAIL_STOP r(N) unavailable rc=" _rc
    local ++unexpected_fail
}

display as text "QRESID_TEST_SUMMARY pass_current=`pass_current' expected_fail=`expected_fail' unexpected_fail=`unexpected_fail'"

if `unexpected_fail' > 0 {
    display as error "QRESID_TEST_STATUS UNEXPECTED_FAIL_STOP"
    log close qresid_tests
    exit 9
}

if `expected_fail' > 0 {
    display as result "QRESID_TEST_STATUS PASS_WITH_EXPECTED_FAILURES"
}
else {
    display as result "QRESID_TEST_STATUS PASS"
}
log close qresid_tests
