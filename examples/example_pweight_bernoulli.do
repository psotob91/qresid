version 15.0
set more off
set varabbrev off
set seed 12345

sysuse auto, clear
generate byte foreign01 = foreign
generate double pw = max(1, weight/1000)
logit foreign01 mpg [pweight=pw]
qresid qr_pweight_bernoulli, seed(12345) family(bernoulli)
assert r(weight_type) == "pweight"
assert r(weight_status) == "pweight_direct_experimental"
summarize qr_pweight_bernoulli
