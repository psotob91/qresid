version 15.0
set more off

set varabbrev off
adopath ++ "."
clear
set obs 180
set seed 72501
generate double x = rnormal()
generate double mu0 = exp(0.45 + 0.25*x)
generate int y = rpoisson(mu0)
replace y = y + 1 if y == 0

tpoisson y x, ll(0)
qresid qr_tpoisson, seed(123)
summarize qr_tpoisson

tnbreg y x, ll(0)
qresid qr_tnbreg, seed(123)
summarize qr_tnbreg
