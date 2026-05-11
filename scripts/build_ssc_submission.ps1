param(
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$releaseRoot = Join-Path $repoRoot "release"
$sscRoot = Join-Path $releaseRoot "ssc"
$stageName = "qresid-$Version-ssc"
$stageDir = Join-Path $sscRoot $stageName
$zipPath = Join-Path $sscRoot "$stageName.zip"

$required = @("qresid.ado", "qresid.sthlp")
foreach ($file in $required) {
    $path = Join-Path $repoRoot $file
    if (-not (Test-Path $path)) {
        throw "Required SSC file is missing: $file"
    }
}

if (Test-Path $stageDir) {
    Remove-Item -LiteralPath $stageDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $stageDir | Out-Null

foreach ($file in $required) {
    Copy-Item -LiteralPath (Join-Path $repoRoot $file) -Destination (Join-Path $stageDir $file)
}

$example = Join-Path $repoRoot "qresid_examples.do"
if (Test-Path $example) {
    Copy-Item -LiteralPath $example -Destination (Join-Path $stageDir "qresid_examples.do")
}

$cover = @"
qresid SSC submission cover note

Package: qresid
Version: $Version
Submission type: new materials
Suggested package name: qresid
Title: Randomized quantile residuals for regression diagnostics in Stata
Purpose: Randomized quantile residuals for regression diagnostics in Stata.
Author: Percy Soto-Becerra, MD, MSc, PhD(c)
Affiliation: Universidad Privada del Norte, Lima, Peru
Email: percy.soto@upn.edu.pe
Email: percys1991@gmail.com
License: MIT
GitHub: https://github.com/psotob91/qresid

Abstract:
qresid implements randomized quantile residuals (Dunn-Smyth residuals) for
regression diagnostics in supported independent regression models in Stata.
The package is intended for generalized linear and related models where
conventional residuals may be difficult to interpret.

Extended documentation, examples, and validation evidence are available in the GitHub repository.
The SSC submission payload is intentionally minimal and contains only the command, help file, cover note, and short examples using official Stata commands.
Minimum Stata version: 15.0.
The core functionality does not require external SSC dependencies.
Optional model-specific support for user-written estimators is documented in the help file and is not required by the examples included in this submission.
"@
$cover | Set-Content -LiteralPath (Join-Path $stageDir "qresid_ssc_cover_note.txt") -Encoding ASCII

$allowed = @(
    "qresid.ado",
    "qresid.sthlp",
    "qresid_ssc_cover_note.txt",
    "qresid_examples.do"
)

$found = Get-ChildItem -LiteralPath $stageDir -File -Recurse
$unexpected = @()
foreach ($item in $found) {
    if ($allowed -notcontains $item.Name) {
        $unexpected += $item.FullName
    }
}
if ($unexpected.Count -gt 0) {
    throw "Unexpected file(s) in SSC staging: $($unexpected -join '; ')"
}

if (Test-Path $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}
Compress-Archive -Path (Join-Path $stageDir "*") -DestinationPath $zipPath -Force

Write-Host "QRESID_SSC_SUBMISSION_STATUS PASS"
Write-Host "QRESID_SSC_STAGE $stageDir"
Write-Host "QRESID_SSC_ZIP $zipPath"
