version 15.0
set more off

set varabbrev off
clear
set obs 100
generate double x = (_n - 50) / 100
generate byte y = mod(_n, 2)
generate int fw = 1 + mod(_n, 3)

logit y x [fweight=fw]
qresid qr_fw_bern, seed(123) family(bernoulli)

summarize qr_fw_bern
