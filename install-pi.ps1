[CmdletBinding()]
param(
    [switch]$SkipAgents,
    [switch]$SkipPackage,
    [switch]$ValidateOnly,
    [switch]$MigrateLegacy,
    [string]$LegacyPackagePath,
    [string]$PiCommand
)

$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
. (Join-Path $repoRoot 'scripts\installation-common.ps1')
$validator = Join-Path $repoRoot "scripts\validate-profile.ps1"

& $validator -Root $repoRoot

if ($ValidateOnly) {
    Write-Host "Pi installation validation completed. No user configuration was changed."
    return
}

$piExecutable = $null
if (-not $SkipPackage) {
    $piCommandName = $PiCommand
    if ([string]::IsNullOrWhiteSpace($piCommandName)) {
        $piCommandName = "pi"
    }

    $piCommandInfo = Get-Command -Name $piCommandName -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($null -eq $piCommandInfo) {
        throw "Pi command was not found. Install Pi or pass -PiCommand with its executable path. No user configuration was changed."
    }

    $piExecutable = $piCommandInfo.Source
    if ([string]::IsNullOrWhiteSpace($piExecutable)) {
        $piExecutable = $piCommandInfo.Definition
    }
}

$piAgentDir = Get-ProfileHome Pi
if ($SkipPackage -and $MigrateLegacy) { throw 'Legacy migration requires package installation.' }

if (-not $SkipPackage) {
    $settingsPath = Join-Path $piAgentDir 'settings.json'
    $legacyEntries = @()
    if ($MigrateLegacy) {
        if (-not $LegacyPackagePath) {
            $LegacyPackagePath = Join-Path (Split-Path -Parent $repoRoot) 'codex-workflow-profile'
        }
        if ((Get-ProfilePath $LegacyPackagePath) -eq (Get-ProfilePath $repoRoot)) {
            throw 'The legacy package path must differ from the current checkout.'
        }
        if (Test-Path -LiteralPath $settingsPath) {
            $settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $legacyEntries = @($settings.packages | Where-Object {
                $source = Get-PiPackageSource $_
                [IO.Path]::IsPathRooted($source) -and (Get-ProfilePath $source) -eq (Get-ProfilePath $LegacyPackagePath)
            })
            if (@($legacyEntries | Where-Object { $_ -isnot [string] }).Count) {
                throw 'The legacy Pi entry has resource filters. Review and migrate those settings explicitly before removing it.'
            }
        }
    }
    $backupRoot = Join-Path $piAgentDir ('workflow-profile-backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
    Backup-ProfilePath $settingsPath $backupRoot 'settings.json'
    $previousAgentDir = $env:PI_CODING_AGENT_DIR
    try {
        $env:PI_CODING_AGENT_DIR = $piAgentDir
        Invoke-ProfileCommand $piExecutable @('install', $repoRoot)
        $settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $registered = @($settings.packages | Where-Object {
            $source = Get-PiPackageSource $_
            [IO.Path]::IsPathRooted($source) -and (Get-ProfilePath $source) -eq (Get-ProfilePath $repoRoot)
        })
        if ($registered.Count -ne 1) { throw 'Pi did not persist exactly one registration for this checkout. Legacy entries were preserved.' }
        foreach ($entry in $legacyEntries) {
            Invoke-ProfileCommand $piExecutable @('remove', $entry)
        }
        if ($legacyEntries.Count) {
            $settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $remaining = @($settings.packages | Where-Object { (Get-PiPackageSource $_) -in $legacyEntries })
            if ($remaining.Count) { throw 'Pi still contains the legacy package registration.' }
        }
    }
    finally { $env:PI_CODING_AGENT_DIR = $previousAgentDir }
    Write-Host "Verified the local Pi package registration from $repoRoot"
}

if (-not $SkipAgents) {
    $sourceAgents = Join-Path $repoRoot "AGENTS.md"
    $targetAgents = Join-Path $piAgentDir "AGENTS.md"

    New-Item -ItemType Directory -Force -Path $piAgentDir | Out-Null

    $agentsCurrent = (Test-Path -LiteralPath $targetAgents) -and
        ((Get-FileHash -LiteralPath $sourceAgents).Hash -eq (Get-FileHash -LiteralPath $targetAgents).Hash)

    if ($agentsCurrent) {
        Write-Host "Pi AGENTS.md is already up to date at $targetAgents"
    }
    else {
        if (Test-Path -LiteralPath $targetAgents) {
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $backupAgents = "$targetAgents.backup-$timestamp"
            Copy-Item -LiteralPath $targetAgents -Destination $backupAgents -Force
            Write-Host "Backed up existing Pi AGENTS.md to $backupAgents"
        }

        Copy-Item -LiteralPath $sourceAgents -Destination $targetAgents -Force
        Write-Host "Installed global Pi AGENTS.md to $targetAgents"
    }
}

Write-Host "Pi workflow profile is ready. Start a new Pi session to load it."
