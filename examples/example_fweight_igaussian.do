version 15.0
set more off

set varabbrev off
clear
set obs 100
generate double x = (_n - 50) / 100
generate double y = exp(.75 + .25*x) + .2 + .02*cos(_n/7)
generate int fw = 1 + mod(_n, 3)

glm y x [fweight=fw], family(igaussian) link(log)
qresid qr_fw_ig, family(igaussian)

summarize qr_fw_ig
