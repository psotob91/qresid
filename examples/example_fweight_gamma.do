version 15.0
set more off

set varabbrev off
clear
set obs 100
set seed 910
generate double x = (_n - 50) / 100
generate double mu = exp(.8 + .25*x)
generate double y = rgamma(5, mu/5)
generate int fw = 1 + mod(_n, 4)

glm y x [fweight=fw], family(gamma) link(log)
qresid qr_fw_gamma, family(gamma)

summarize qr_fw_gamma
