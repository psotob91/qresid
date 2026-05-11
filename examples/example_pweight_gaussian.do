version 15.0
set more off

set varabbrev off
sysuse auto, clear
generate double pw = max(1, weight/1000)
regress price mpg [pweight=pw]
qresid qr_pweight_gaussian
assert r(weight_type) == "pweight"
assert r(weight_status) == "pweight_direct_experimental"
summarize qr_pweight_gaussian
