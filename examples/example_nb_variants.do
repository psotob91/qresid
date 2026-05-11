version 15.0
set more off

set varabbrev off
adopath ++ "."

clear
set seed 90201
set obs 320
generate int id = _n
generate double x = rnormal()
generate double z = rnormal()
generate double v = (mod(id*43, 100) + 0.5) / 101

generate double mu0 = exp(0.25 + 0.45*x)
generate double delta0 = 1.1
generate double theta0 = mu0 / delta0
generate double p0 = 1 / (1 + delta0)
generate int y_const = rnbinomial(theta0, p0)
nbreg y_const x, dispersion(constant)
qresid qr_nb_constant, uvar(v)
summarize qr_nb_constant

generate double alpha0 = exp(-0.5 + 0.2*z)
replace theta0 = 1 / alpha0
replace p0 = theta0 / (theta0 + mu0)
generate int y_gnb = rnbinomial(theta0, p0)
gnbreg y_gnb x, lnalpha(z)
qresid qr_gnb, uvar(v)
summarize qr_gnb

generate int y_glm_nb = rnbinomial(0.8, 0.8/(0.8 + mu0))
glm y_glm_nb x, family(nbinomial 1.25) link(log)
qresid qr_glm_nb, uvar(v)
summarize qr_glm_nb
