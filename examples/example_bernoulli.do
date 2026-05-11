version 15.0
set more off
set varabbrev off
set seed 12345

sysuse auto, clear
generate byte foreign01 = foreign
logit foreign01 mpg
qresid qr_bernoulli, seed(12345) family(bernoulli)
summarize qr_bernoulli

