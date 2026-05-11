version 15.0
set more off
set varabbrev off
set seed 12345

sysuse auto, clear
generate int fw = 1 + mod(_n, 3)
poisson rep78 mpg [fweight=fw] if rep78 < .
qresid qr_fweight_poisson, seed(12345) saveflo(flo) savefhi(fhi) saveu(u)
assert r(weight_type) == "fweight"
assert r(weight_status) == "fweight_experimental"
assert flo <= fhi if e(sample)
assert u >= flo & u <= fhi if e(sample)
summarize qr_fweight_poisson
