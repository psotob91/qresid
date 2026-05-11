# Contributing to qresid

Thank you for your interest in improving `qresid`. The project welcomes bug
reports, reproducible examples, documentation improvements, validation cases,
and carefully scoped pull requests.

## Reporting issues

For bugs, please open an issue with:

- the Stata version and operating system;
- the estimation command that was run before `qresid`;
- a minimal reproducible example using built-in or simulated data;
- the exact error message or unexpected result.

For methodological or feature requests, please describe the model, fitted CDF,
required postestimation quantities, and any independent software or published
reference that can be used for validation.

## Pull requests

Before a substantial pull request, please open an issue so the scope can be
discussed. Small documentation fixes may be submitted directly.

Pull requests should:

- keep changes focused on one topic;
- avoid reformatting unrelated Stata, Markdown, or PowerShell files;
- update `qresid.sthlp`, Markdown documentation, and the changelog when
  user-facing behavior changes;
- include or update Stata tests when command behavior changes;
- preserve the minimal install payload in `qresid.pkg`.

## Local checks

From the repository root, run the public checks when Stata and R are available:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/ci/run_stata_tests.ps1
Rscript tests/check_support_report_consistency.R
```

The SSC-style archive can be rebuilt with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build_ssc_submission.ps1
```

The generated SSC ZIP is a minimal submission artifact. It should contain only
the Stata command, help file, and cover note.

## Generated material

Do not commit local logs, temporary files, Stata license files, activation
files, or machine-specific configuration. Tutorial figures and selected output
excerpts may be regenerated with:

```stata
do docs/scripts/build_manual_assets.do
```

If you regenerate tutorial assets, update the relevant Markdown text in the
same pull request.

## Code of conduct

By contributing to this project, you agree to follow the
[Contributor Code of Conduct](CODE_OF_CONDUCT.md).
