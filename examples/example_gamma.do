version 15.0
set more off
set varabbrev off
set seed 12345

clear
set obs 80
generate double x = (_n - 40) / 20
generate double y = exp(1 + .25*x)
glm y x, family(gamma) link(log)
qresid qr_gamma, family(gamma) saveu(u)
assert u > 0 & u < 1 if e(sample)
summarize qr_gamma

