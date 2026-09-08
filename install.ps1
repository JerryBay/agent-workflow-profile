[CmdletBinding()]
param(
    [switch]$SkipAgents,
    [switch]$SkipPlugin,
    [switch]$RefreshPlugin,
    [switch]$ValidateOnly,
    [switch]$MigrateLegacy,
    [string[]]$ArchiveStandaloneSkills = @(),
    [string]$CodexCommand = 'codex'
)

$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
. (Join-Path $repoRoot 'scripts\installation-common.ps1')
$marketplaceName = "agent-workflow-profile"
$pluginName = "personal-workflow"
$pluginSelector = "$pluginName@$marketplaceName"
$validator = Join-Path $repoRoot "scripts\validate-profile.ps1"

& $validator -Root $repoRoot

if ($ValidateOnly) {
    Write-Host "Validation completed. No user configuration was changed."
    return
}

if ($SkipPlugin -and ($MigrateLegacy -or $ArchiveStandaloneSkills.Count)) {
    throw 'Migration and standalone archival require plugin installation and verification.'
}
$sourcePlugin = Join-Path $repoRoot 'plugins\personal-workflow'
$manifest = Get-Content -LiteralPath (Join-Path $sourcePlugin '.codex-plugin\plugin.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$knownSkills = @(Get-ChildItem -LiteralPath (Join-Path $sourcePlugin 'skills') -Directory | Select-Object -ExpandProperty Name)
foreach ($name in $ArchiveStandaloneSkills) {
    if ($name -notin $knownSkills) { throw "Not a shared profile skill: $name. Review it separately." }
}
$codexDir = Get-ProfileHome Codex
$backupRoot = Join-Path $codexDir ('workflow-profile-backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))

if (-not $SkipPlugin) {
    Get-Command $CodexCommand -ErrorAction Stop | Out-Null
    Backup-ProfilePath (Join-Path $codexDir 'config.toml') $backupRoot 'config.toml'
    $previousHome = $env:CODEX_HOME
    try {
        $env:CODEX_HOME = $codexDir
        if ($MigrateLegacy) {
            # A missing legacy root can break list itself, so unregister it first.
            Backup-ProfilePath (Join-Path $codexDir 'plugins\cache\codex-workflow-profile\personal-workflow') $backupRoot 'legacy-plugin'
            Invoke-ProfileCommand $CodexCommand @('plugin', 'marketplace', 'remove', 'codex-workflow-profile', '--json') -Json -AllowMissingMarketplace | Out-Null
        }
        Invoke-ProfileCommand $CodexCommand @('plugin', 'marketplace', 'add', $repoRoot, '--json') -Json | Out-Null
        $markets = Invoke-ProfileCommand $CodexCommand @('plugin', 'marketplace', 'list', '--json') -Json
        $market = @($markets.marketplaces | Where-Object { $_.name -eq $marketplaceName })
        if ($market.Count -ne 1 -or (Get-ProfilePath $market[0].root) -ne (Get-ProfilePath $repoRoot)) {
            throw 'Marketplace registration does not point to this checkout.'
        }
        $state = Invoke-ProfileCommand $CodexCommand @('plugin', 'list', '--json') -Json
        $installed = @($state.installed | Where-Object { $_.pluginId -eq $pluginSelector })
        $cachePath = Join-Path $codexDir "plugins\cache\$marketplaceName\personal-workflow\$($manifest.version)"
        $current = $installed.Count -eq 1 -and $installed[0].enabled -eq $true -and
            $installed[0].version -eq $manifest.version -and (Test-Path -LiteralPath $cachePath) -and
            @(Get-ProfileTreeDifference $sourcePlugin $cachePath).Count -eq 0
        if ($RefreshPlugin -or -not $current) {
            Backup-ProfilePath (Join-Path $codexDir "plugins\cache\$marketplaceName\personal-workflow") $backupRoot 'current-plugin'
            if ($installed.Count -gt 0) {
                Invoke-ProfileCommand $CodexCommand @('plugin', 'remove', $pluginSelector, '--json') -Json | Out-Null
            }
            Invoke-ProfileCommand $CodexCommand @('plugin', 'add', $pluginSelector, '--json') -Json | Out-Null
        }
        $verified = Invoke-ProfileCommand $CodexCommand @('plugin', 'list', '--json') -Json
        $plugin = @($verified.installed | Where-Object { $_.pluginId -eq $pluginSelector })
        if ($plugin.Count -ne 1 -or $plugin[0].enabled -ne $true -or $plugin[0].version -ne $manifest.version -or
            -not (Test-Path -LiteralPath $cachePath) -or @(Get-ProfileTreeDifference $sourcePlugin $cachePath).Count -ne 0) {
            throw 'Installed plugin failed identity, enabled state, version or content verification. Standalone skills were preserved.'
        }
        if ($MigrateLegacy) {
            Invoke-ProfileCommand $CodexCommand @('plugin', 'remove', 'personal-workflow@codex-workflow-profile', '--json') -Json | Out-Null
        }
        foreach ($name in $ArchiveStandaloneSkills) {
            $standalone = Join-Path $codexDir "skills\$name"
            if (Test-Path -LiteralPath $standalone) {
                $difference = @(Get-ProfileTreeDifference (Join-Path $sourcePlugin "skills\$name") $standalone)
                Write-Host "Archiving reviewed standalone skill '$name': $($difference -join '; ')"
                $destination = Join-Path $backupRoot 'standalone-skills'
                New-Item -ItemType Directory -Path $destination -Force | Out-Null
                $resolved = (Resolve-Path -LiteralPath $standalone).Path
                if ((Split-Path -Parent $resolved) -ne (Get-ProfilePath (Join-Path $codexDir 'skills')) -or
                    ((Get-Item -LiteralPath $standalone).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                    throw "Refusing to archive a redirected skill path: $standalone"
                }
                Move-Item -LiteralPath $resolved -Destination (Join-Path $destination $name)
            }
        }
        Write-Host "Verified $pluginSelector version $($manifest.version)."
    }
    finally { $env:CODEX_HOME = $previousHome }
}

if (-not $SkipAgents) {
    $sourceAgents = Join-Path $repoRoot 'AGENTS.md'
    $targetAgents = Join-Path $codexDir 'AGENTS.md'
    $current = (Test-Path -LiteralPath $targetAgents) -and
        (Get-FileHash -LiteralPath $sourceAgents).Hash -eq (Get-FileHash -LiteralPath $targetAgents).Hash
    if (-not $current) {
        Backup-ProfilePath $targetAgents $backupRoot 'AGENTS.md'
        New-Item -ItemType Directory -Path $codexDir -Force | Out-Null
        Copy-Item -LiteralPath $sourceAgents -Destination $targetAgents -Force
    }
}

Write-Host "Agent workflow profile is ready. Restart Codex or open a new chat."
