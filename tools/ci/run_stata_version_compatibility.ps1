param(
    [string[]]$VersionModes = @("15.0"),
    [string]$ReportPath = "docs/stata-version-compatibility.html"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "../..")
Set-Location $repoRoot

function Find-StataExecutable {
    if ($env:STATA_EXE) {
        if (Test-Path -LiteralPath $env:STATA_EXE) {
            return (Resolve-Path -LiteralPath $env:STATA_EXE).Path
        }
        $cmd = Get-Command $env:STATA_EXE -ErrorAction SilentlyContinue
        if ($cmd) {
            return $cmd.Source
        }
        throw "STATA_EXE is set but was not found: $env:STATA_EXE"
    }

    foreach ($name in @("stata-mp", "stata-se", "stata", "StataMP-64.exe", "StataSE-64.exe", "StataBE-64.exe", "Stata-64.exe")) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) {
            return $cmd.Source
        }
    }

    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ }) {
            $match = Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match "^Stata(MP|SE|BE)?-?64\.exe$|^Stata(MP|SE|BE)?\.exe$" } |
                Sort-Object FullName |
                Select-Object -First 1
            if ($match) {
                return $match.FullName
            }
        }
    }

    throw "Stata executable not found. Put Stata on PATH or set STATA_EXE."
}

function Convert-Status {
    param([bool]$Ok, [string]$SkipReason = "")
    if ($SkipReason) { return "SKIP" }
    if ($Ok) { return "OK" }
    return "FAIL"
}

function Invoke-StataCompatibilityDo {
    param(
        [string]$StataExe,
        [string]$VersionMode,
        [string]$BlockName,
        [string]$DoFile,
        [string]$ExpectedStatus
    )

    $logDir = Join-Path "compatibility/logs" $VersionMode
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    $safeName = ($BlockName -replace "[^A-Za-z0-9]+", "_").Trim("_").ToLowerInvariant()
    $wrapper = Join-Path $logDir "$safeName.do"
    $log = (Join-Path (Resolve-Path $logDir).Path "$safeName.log")

    @"
version $VersionMode
clear all
set more off
set varabbrev off
cd "$repoRoot"
log using "$log", text replace
display as text "QRESID_COMPAT_BLOCK $BlockName"
display as text "QRESID_COMPAT_VERSION_MODE $VersionMode"
capture noisily do "$DoFile"
if _rc {
    display as error "QRESID_COMPAT_BLOCK_FAIL $BlockName rc=" _rc
    log close
    exit _rc
}
display as result "QRESID_COMPAT_BLOCK_PASS $BlockName"
log close
exit 0
"@ | Set-Content -LiteralPath $wrapper -Encoding ascii

    $startedAt = Get-Date
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        & $StataExe /e do $wrapper | Out-Null
    }
    else {
        & $StataExe -b do $wrapper | Out-Null
    }
    $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }

    $deadline = (Get-Date).AddSeconds(300)
    $content = ""
    while ((Get-Date) -lt $deadline) {
        if (Test-Path -LiteralPath $log) {
            $content = Get-Content -LiteralPath $log -Raw
            if ($content -match [regex]::Escape($ExpectedStatus)) {
                return [pscustomobject]@{
                    VersionMode = $VersionMode
                    Block = $BlockName
                    Varabbrev = "off"
                    Status = "OK"
                    Log = $log
                    Note = "Expected status found"
                }
            }
            if ($content -match "QRESID_COMPAT_BLOCK_FAIL") {
                break
            }
        }
        Start-Sleep -Seconds 2
    }

    $note = "Expected status not found"
    if ($exitCode -ne 0) {
        $note = "Stata exit code $exitCode"
    }
    elseif (-not (Test-Path -LiteralPath $log)) {
        $note = "No log created"
    }
    return [pscustomobject]@{
        VersionMode = $VersionMode
        Block = $BlockName
        Varabbrev = "off"
        Status = "FAIL"
        Log = $log
        Note = $note
    }
}

function Invoke-RCompatibilityCheck {
    param([string]$VersionMode)

    $logDir = Join-Path "compatibility/logs" $VersionMode
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    $log = Join-Path $logDir "r_support_consistency.log"
    try {
        & Rscript tests/check_support_report_consistency.R *> $log
        $content = Get-Content -LiteralPath $log -Raw
        $ok = $LASTEXITCODE -eq 0 -and $content -match "QRESID_SUPPORT_REPORT_CONSISTENCY_STATUS PASS"
        return [pscustomobject]@{
            VersionMode = $VersionMode
            Block = "R support consistency"
            Varabbrev = "not applicable"
            Status = (Convert-Status -Ok $ok)
            Log = $log
            Note = if ($ok) { "R checker passed" } else { "R checker failed" }
        }
    }
    catch {
        return [pscustomobject]@{
            VersionMode = $VersionMode
            Block = "R support consistency"
            Varabbrev = "not applicable"
            Status = "FAIL"
            Log = $log
            Note = $_.Exception.Message
        }
    }
}

function New-CompatibilityHtml {
    param(
        [object[]]$Rows,
        [string]$Path
    )

    $minimum = "not established"
    foreach ($version in ($Rows.VersionMode | Select-Object -Unique)) {
        $versionRows = $Rows | Where-Object { $_.VersionMode -eq $version -and $_.Status -ne "SKIP" }
        if ($versionRows -and (($versionRows | Where-Object Status -eq "FAIL").Count -eq 0)) {
            $minimum = $version
            break
        }
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
    $repoPath = (Resolve-Path ".").Path
    $tableRows = foreach ($row in $Rows) {
        $logPath = [string]$row.Log
        if ($logPath.StartsWith($repoPath, [System.StringComparison]::OrdinalIgnoreCase)) {
            $logPath = $logPath.Substring($repoPath.Length).TrimStart("\", "/")
        }
        $statusClass = $row.Status.ToLowerInvariant()
        "<tr><td>$($row.VersionMode)</td><td>$($row.Block)</td><td>$($row.Varabbrev)</td><td class=""$statusClass"">$($row.Status)</td><td><code>$logPath</code></td><td>$($row.Note)</td><td>$minimum</td></tr>"
    }

    $html = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>qresid Stata version compatibility</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 2rem; line-height: 1.45; color: #1f2933; }
    table { border-collapse: collapse; width: 100%; margin-top: 1rem; }
    th, td { border: 1px solid #cbd5e1; padding: 0.45rem 0.55rem; vertical-align: top; }
    th { background: #eef2f7; text-align: left; }
    .ok { color: #166534; font-weight: 700; }
    .fail { color: #991b1b; font-weight: 700; }
    .skip { color: #854d0e; font-weight: 700; }
    code { font-size: 0.9em; }
  </style>
</head>
<body>
  <h1>qresid Stata version compatibility</h1>
  <p>This report checks parser/version-mode compatibility using the installed Stata executable. It is not a substitute for running a historical Stata binary.</p>
  <p><strong>Generated:</strong> $timestamp</p>
  <p><strong>Minimum version mode recommended by this run:</strong> $minimum</p>
  <table>
    <thead>
      <tr>
        <th>Version mode</th>
        <th>Block</th>
        <th>varabbrev</th>
        <th>Status</th>
        <th>Log</th>
        <th>Observation</th>
        <th>Minimum recommended</th>
      </tr>
    </thead>
    <tbody>
      $($tableRows -join "`n      ")
    </tbody>
  </table>
</body>
</html>
"@
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    Set-Content -LiteralPath $Path -Value $html -Encoding utf8
}

New-Item -ItemType Directory -Force -Path "compatibility/logs" | Out-Null

$stata = Find-StataExecutable
Write-Host "QRESID_COMPAT_STATA_EXE $stata"

$rows = @()
foreach ($version in $VersionModes) {
    $rows += Invoke-StataCompatibilityDo -StataExe $stata -VersionMode $version -BlockName "Unit tests" -DoFile "tests/run_all_tests.do" -ExpectedStatus "QRESID_TEST_STATUS PASS"
    $rows += Invoke-StataCompatibilityDo -StataExe $stata -VersionMode $version -BlockName "Hardening smoke local install and examples" -DoFile "tests/hardening_smoke.do" -ExpectedStatus "QRESID_HARDENING_SMOKE_STATUS PASS"
    $rows += Invoke-StataCompatibilityDo -StataExe $stata -VersionMode $version -BlockName "Public examples" -DoFile "examples/run_examples.do" -ExpectedStatus "QRESID_EXAMPLES_STATUS PASS"
    $rows += Invoke-RCompatibilityCheck -VersionMode $version

    $failures = ($rows | Where-Object { $_.VersionMode -eq $version -and $_.Status -eq "FAIL" }).Count
    if ($failures -eq 0) {
        break
    }
}

New-CompatibilityHtml -Rows $rows -Path $ReportPath
$rows | Format-Table -AutoSize
if (($rows | Where-Object Status -eq "FAIL").Count -gt 0) {
    Write-Host "QRESID_COMPATIBILITY_STATUS FAIL"
    exit 1
}
Write-Host "QRESID_COMPATIBILITY_STATUS PASS"
