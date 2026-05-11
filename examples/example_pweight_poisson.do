version 15.0
set more off
set varabbrev off
set seed 12345

sysuse auto, clear
generate double pw = max(1, weight/1000)
poisson rep78 mpg [pweight=pw] if rep78 < .
qresid qr_pweight_poisson, seed(12345) saveflo(flo) savefhi(fhi) saveu(u)
assert r(weight_type) == "pweight"
assert r(weight_status) == "pweight_direct_experimental"
assert flo <= fhi if e(sample)
assert u >= flo & u <= fhi if e(sample)
summarize qr_pweight_poisson
