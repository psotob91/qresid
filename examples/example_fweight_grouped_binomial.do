version 15.0
set more off

set varabbrev off
clear
set obs 90
generate double x = (_n - 45) / 90
generate int trials = 8 + mod(_n, 4)
generate int y = max(1, min(trials - 1, floor(trials * invlogit(-.2 + .35*x))))
generate int fw = 1 + mod(_n, 3)

glm y x [fweight=fw], family(binomial trials) link(logit)
qresid qr_fw_gbinom, seed(123)

summarize qr_fw_gbinom
