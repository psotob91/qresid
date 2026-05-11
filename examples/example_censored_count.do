version 15.0
set more off

set varabbrev off
adopath ++ "."
clear
set obs 180
set seed 72502
generate double x = rnormal()
generate double mu0 = exp(0.5 + 0.2*x)
generate int y = rpoisson(mu0)
replace y = 1 if y <= 1
replace y = 8 if y >= 8

cpoisson y x, ll(1) ul(8)
qresid qr_cpoisson, seed(123)
summarize qr_cpoisson
