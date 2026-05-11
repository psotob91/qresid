# Changelog

All notable changes to `qresid` will be documented in this file.

## [1.0.0] - 2026-05-11

### Added

- Initial complete public release of `qresid`.
- Implements randomized quantile residuals for supported independent
  regression models.
- Includes Stata help, package metadata, examples, and validation materials
  available in the repository.
- Includes compatibility checks under Stata 15.0 with `set varabbrev off`,
  SSC name checks, SSC example checks, and public test runners.
- Includes cross-platform validation using independent R implementations when
  available, and programmed CDF replay in R and Stata when validation requires
  model-specific probability calculations.

### Notes

- Submitted to SSC; pending review/acceptance.
- Supersedes the earlier preliminary 0.1.0 prerelease line.

## [0.1.0 prerelease] - 2026-05-10

### Notes

- Earlier preliminary version with known bugs and incomplete validation.
- Superseded by `v1.0.0`, where those issues are addressed in the tested and
  validated public release.
