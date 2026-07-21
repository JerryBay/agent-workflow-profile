[CmdletBinding()]
param(
    [switch]$SkipAgents,
    [switch]$SkipPlugin,
    [switch]$RefreshPlugin
)

$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
$marketplaceName = "codex-workflow-profile"
$pluginName = "personal-workflow"
$pluginSelector = "$pluginName@$marketplaceName"

if (-not $SkipAgents) {
    $codexDir = Join-Path $env:USERPROFILE ".codex"
    $sourceAgents = Join-Path $repoRoot "AGENTS.md"
    $targetAgents = Join-Path $codexDir "AGENTS.md"

    New-Item -ItemType Directory -Force -Path $codexDir | Out-Null

    if (Test-Path -LiteralPath $targetAgents) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupAgents = "$targetAgents.backup-$timestamp"
        Copy-Item -LiteralPath $targetAgents -Destination $backupAgents -Force
        Write-Host "Backed up existing AGENTS.md to $backupAgents"
    }

    Copy-Item -LiteralPath $sourceAgents -Destination $targetAgents -Force
    Write-Host "Installed global AGENTS.md to $targetAgents"
}

if (-not $SkipPlugin) {
    $codexCommand = Get-Command codex -ErrorAction Stop
    $marketplaceState = (& $codexCommand.Source plugin marketplace list --json | Out-String | ConvertFrom-Json)
    $marketplaceExists = @($marketplaceState.marketplaces) |
        Where-Object { $_.name -eq $marketplaceName }

    if ($marketplaceExists) {
        & $codexCommand.Source plugin marketplace upgrade $marketplaceName --json
    }
    else {
        & $codexCommand.Source plugin marketplace add $repoRoot --json
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to register or refresh marketplace '$marketplaceName'."
    }

    $pluginState = (& $codexCommand.Source plugin list --json | Out-String | ConvertFrom-Json)
    $installedJson = $pluginState.installed | ConvertTo-Json -Depth 20 -Compress
    $pluginInstalled = $installedJson -match [regex]::Escape($pluginName)

    if ($pluginInstalled -and $RefreshPlugin) {
        & $codexCommand.Source plugin remove $pluginName
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to remove the existing '$pluginName' plugin."
        }
        $pluginInstalled = $false
    }

    if (-not $pluginInstalled) {
        & $codexCommand.Source plugin add $pluginSelector --json
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install plugin '$pluginSelector'."
        }
    }
    else {
        Write-Host "Plugin '$pluginName' is already installed. Use -RefreshPlugin to reinstall it."
    }
}

Write-Host "Codex workflow profile is ready. Restart Codex or open a new chat."
