version 15.0
set more off

set varabbrev off
local qresid_root "`c(pwd)'"
capture confirm file "qresid.ado"
if _rc {
    display as error "QRESID_HARDENING_ERROR run tests/hardening_smoke.do from the qresid repository root"
    exit 601
}
capture confirm file "qresid.pkg"
if _rc {
    display as error "QRESID_HARDENING_ERROR qresid.pkg not found in repository root"
    exit 601
}

capture mkdir "`qresid_root'/tests/logs"
local stamp = subinstr("`c(current_date)'_`c(current_time)'", " ", "_", .)
local stamp = subinstr("`stamp'", ":", "", .)
local stamp = subinstr("`stamp'", "/", "", .)
local stamp = subinstr("`stamp'", "-", "", .)
local suffix = floor(1000000*runiform())
local stamp "`stamp'_`suffix'"
local logfile "`qresid_root'/tests/logs/`stamp'_hardening_smoke.log"

capture log close qresid_hardening
log using "`logfile'", text replace name(qresid_hardening)

display as text "QRESID_HARDENING_SMOKE_START"
display as text "ROOT `qresid_root'"

local oldplus "`c(sysdir_plus)'"
tempfile marker
local plusdir "`marker'_plus"
capture mkdir "`plusdir'"

sysdir set PLUS "`plusdir'"
cd "`c(tmpdir)'"

capture noisily net install qresid, from("`qresid_root'") replace
if _rc {
    display as error "QRESID_INSTALL_SMOKE FAIL rc=" _rc
    sysdir set PLUS "`oldplus'"
    log close qresid_hardening
    exit _rc
}
display as result "QRESID_INSTALL_SMOKE PASS"

capture noisily which qresid
if _rc {
    display as error "QRESID_WHICH_INSTALLED FAIL rc=" _rc
    sysdir set PLUS "`oldplus'"
    log close qresid_hardening
    exit _rc
}
display as result "QRESID_WHICH_INSTALLED PASS"

capture noisily help qresid
if _rc {
    display as error "QRESID_HELP_SMOKE FAIL rc=" _rc
    sysdir set PLUS "`oldplus'"
    log close qresid_hardening
    exit _rc
}
display as result "QRESID_HELP_SMOKE PASS"

adopath ++ "`qresid_root'"
cd "`qresid_root'"
capture noisily do "examples/run_examples.do"
if _rc {
    display as error "QRESID_EXAMPLES_SMOKE FAIL rc=" _rc
    sysdir set PLUS "`oldplus'"
    log close qresid_hardening
    exit _rc
}
display as result "QRESID_EXAMPLES_SMOKE PASS"

sysdir set PLUS "`oldplus'"
display as result "QRESID_HARDENING_SMOKE_STATUS PASS"
display as text "QRESID_HARDENING_SMOKE_END"
log close qresid_hardening
