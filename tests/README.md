# qresid tests

This directory contains the Stata test suite used for routine development and
GitHub Actions checks.

## Local run

From the repository root:

```stata
do tests/run_all_tests.do
do tests/hardening_smoke.do
```

The test runner adds the repository root to the local `adopath`, writes logs to
`tests/logs/`, and exits with a nonzero status if an unexpected failure occurs.
Run the do-files from the repository root so that relative paths remain
portable.

## GitHub Actions

The workflow `.github/workflows/stata-tests.yml` runs the same quick test suite
on a self-hosted runner. The runner must already have Stata installed and
licensed locally. The repository must not contain a Stata license, installer,
activation file, or any private machine-specific configuration.

If Stata is not discoverable on `PATH`, set the runner environment variable
`STATA_EXE` to the executable path before the workflow runs. Examples:

```powershell
$env:STATA_EXE = "C:\Program Files\StataNow19\StataSE-64.exe"
```

```bash
export STATA_EXE=/usr/local/stata/stata-mp
```

The workflow uploads Stata logs as artifacts, including logs generated under
`tests/logs/` and `examples/logs/`.

## Certification

Routine CI is a fast guard against broken tests and package installation
smoke failures. It is not a substitute for the fuller certification and R
benchmark evidence used for release review.
