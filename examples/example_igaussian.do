version 15.0
set more off

set varabbrev off
clear
set obs 100
generate double x = (_n - 50) / 80
generate double y = exp(.8 + .25*x) + .2 + .02*sin(_n/7)

glm y x, family(igaussian) link(log)
qresid qr_ig, family(igaussian) saveflo(flo_ig) savefhi(fhi_ig) saveu(u_ig)

summarize qr_ig
