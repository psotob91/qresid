version 15.0
set more off

set varabbrev off
adopath ++ "."

sysuse auto, clear
generate byte foreign01 = foreign
binreg foreign01 mpg
qresid qr_binreg, seed(123) family(bernoulli)
summarize qr_binreg
