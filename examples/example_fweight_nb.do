version 15.0
set more off

set varabbrev off
clear
set obs 120
set seed 911
generate double x = rnormal()
generate double mu = exp(.25 + .35*x)
generate double theta = 3
generate double p = theta/(theta + mu)
generate int y = rnbinomial(theta, p)
generate int fw = 1 + mod(_n, 3)

nbreg y x [fweight=fw], dispersion(mean)
qresid qr_fw_nb, seed(123)

summarize qr_fw_nb
