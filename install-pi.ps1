[CmdletBinding()]
param(
    [switch]$SkipAgents,
    [switch]$SkipPackage,
    [switch]$ValidateOnly,
    [string]$PiCommand
)

$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
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

$piAgentDir = $env:PI_CODING_AGENT_DIR
if ([string]::IsNullOrWhiteSpace($piAgentDir)) {
    $piAgentDir = Join-Path $env:USERPROFILE ".pi\agent"
}

if (-not $SkipPackage) {
    $LASTEXITCODE = 0
    & $piExecutable install $repoRoot
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to register the local Pi package from '$repoRoot'."
    }
    Write-Host "Registered the local Pi package from $repoRoot"
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
