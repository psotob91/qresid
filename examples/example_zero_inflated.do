version 15.0
set more off

set varabbrev off
adopath ++ "."

clear
set seed 90202
set obs 500
generate int id = _n
generate double x = rnormal()
generate double z = rnormal()
generate double v = (mod(id*47, 100) + 0.5) / 101
generate double mu0 = exp(0.3 + 0.4*x)
generate double pi0 = invlogit(-1 + 0.45*z)
generate byte structural_zero = runiform() < pi0

generate int y_zip = cond(structural_zero, 0, rpoisson(mu0))
zip y_zip x, inflate(z)
qresid qr_zip, uvar(v)
summarize qr_zip

generate double theta0 = 2.4
generate double p0 = theta0 / (theta0 + mu0)
generate int y_zinb = cond(structural_zero, 0, rnbinomial(theta0, p0))
zinb y_zinb x, inflate(z)
qresid qr_zinb, uvar(v)
summarize qr_zinb
