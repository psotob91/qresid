version 15.0
set more off
set varabbrev off
set seed 20260510

capture which hplogit
if _rc {
    display as text "QRESID_EXAMPLE_HURDLE_COUNT SKIP hplogit is not installed; type findit hplogit for the external estimator"
    exit 0
}

clear
set obs 90
generate double x = rnormal()
generate double p0 = invlogit(-.25 + .45*x)
generate double mu = exp(.35 + .25*x)
generate int y = 0

quietly forvalues i = 1/90 {
    if runiform() > p0[`i'] {
        local yy = 0
        while `yy' == 0 {
            local yy = rpoisson(mu[`i'])
        }
        replace y = `yy' in `i'
    }
}

generate double ubench = mod(_n * 0.6180339887498949, 1)
replace ubench = 0.000001 if ubench <= 0

hplogit y x, nolog
qresid qr_hurdle_pois, uvar(ubench) saveflo(flo_h) savefhi(fhi_h) saveu(u_h)
assert r(family) == "hurdle_poisson"
assert !missing(qr_hurdle_pois) if e(sample)
