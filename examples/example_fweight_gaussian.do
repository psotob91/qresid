version 15.0
set more off

set varabbrev off
sysuse auto, clear
generate int fw = 1 + mod(_n, 3)
regress price mpg [fweight=fw]
qresid qr_fweight_gaussian
assert r(weight_type) == "fweight"
assert r(weight_status) == "fweight_experimental"
summarize qr_fweight_gaussian
