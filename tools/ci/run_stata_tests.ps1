param(
    [string[]]$DoFiles = @("tests/run_all_tests.do", "tests/hardening_smoke.do")
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

    $pathCandidates = @(
        "stata-mp",
        "stata-se",
        "stata",
        "StataMP-64.exe",
        "StataSE-64.exe",
        "StataBE-64.exe",
        "Stata-64.exe",
        "StataMP.exe",
        "StataSE.exe",
        "StataBE.exe",
        "Stata.exe"
    )
    foreach ($name in $pathCandidates) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) {
            return $cmd.Source
        }
    }

    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        $roots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ }
        foreach ($root in $roots) {
            $matches = Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match "^Stata(MP|SE|BE)?-?64\.exe$|^Stata(MP|SE|BE)?\.exe$" } |
                Sort-Object FullName
            if ($matches) {
                return $matches[0].FullName
            }
        }
    }

    throw "Stata executable not found. Put Stata on PATH or set STATA_EXE to the executable path."
}

function Invoke-StataDo {
    param(
        [string]$StataExe,
        [string]$DoFile,
        [string]$ExpectedStatus
    )

    if (-not (Test-Path -LiteralPath $DoFile)) {
        throw "Missing Stata do-file: $DoFile"
    }

    Write-Host "QRESID_CI_RUNNING $DoFile"
    $startedAt = Get-Date
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        & $StataExe /e do $DoFile
    }
    else {
        & $StataExe -b do $DoFile
    }
    $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }

    $logPattern = "*.log"
    if ($DoFile -like "*run_all_tests.do") {
        $logPattern = "*_run_all_tests.log"
    }
    elseif ($DoFile -like "*hardening_smoke.do") {
        $logPattern = "*_hardening_smoke.log"
    }

    $deadline = (Get-Date).AddSeconds(240)
    $latestLog = $null
    $content = $null
    while ((Get-Date) -lt $deadline) {
        $logs = Get-ChildItem -LiteralPath "tests/logs" -Filter $logPattern -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -ge $startedAt.AddSeconds(-5) } |
            Sort-Object LastWriteTime -Descending
        if ($logs) {
            $latestLog = $logs[0].FullName
            $content = Get-Content -LiteralPath $latestLog -Raw
            if ($content -match [regex]::Escape($ExpectedStatus)) {
                Write-Host "QRESID_CI_STATUS_FOUND $ExpectedStatus"
                return
            }
        }
        Start-Sleep -Seconds 2
    }

    if ($exitCode -ne 0) {
        throw "Stata returned exit code $exitCode for $DoFile and expected status '$ExpectedStatus' was not found."
    }
    if (-not $latestLog) {
        throw "No new test log was created for $DoFile"
    }
    else {
        throw "Expected status '$ExpectedStatus' was not found in $latestLog"
    }
}

New-Item -ItemType Directory -Force -Path "tests/logs" | Out-Null

$stata = Find-StataExecutable
Write-Host "QRESID_CI_STATA_EXE $stata"

foreach ($doFile in $DoFiles) {
    switch ($doFile) {
        "tests/run_all_tests.do" {
            Invoke-StataDo -StataExe $stata -DoFile $doFile -ExpectedStatus "QRESID_TEST_STATUS PASS"
        }
        "tests/hardening_smoke.do" {
            Invoke-StataDo -StataExe $stata -DoFile $doFile -ExpectedStatus "QRESID_HARDENING_SMOKE_STATUS PASS"
        }
        default {
            Invoke-StataDo -StataExe $stata -DoFile $doFile -ExpectedStatus "PASS"
        }
    }
}

Write-Host "QRESID_CI_STATUS PASS"
