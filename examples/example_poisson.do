version 15.0
set more off
set varabbrev off
set seed 12345

sysuse auto, clear
poisson rep78 mpg if rep78 < .
qresid qr_poisson, seed(12345) saveflo(flo) savefhi(fhi) saveu(u)
assert flo <= fhi if e(sample)
assert u >= flo & u <= fhi if e(sample)
summarize qr_poisson

