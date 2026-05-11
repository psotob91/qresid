version 15.0
set more off

set varabbrev off
sysuse auto, clear
regress price mpg
qresid qr_gaussian
summarize qr_gaussian

