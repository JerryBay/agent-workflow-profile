[CmdletBinding()]
param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [string]$CodexHome,
    [string]$PiAgentDir,
    [string]$CodexCommand = 'codex',
    [switch]$Json,
    [switch]$FailOnIssues
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'installation-common.ps1')
$Root = (Resolve-Path -LiteralPath $Root).Path
if (-not $CodexHome) { $CodexHome = Get-ProfileHome Codex }
if (-not $PiAgentDir) { $PiAgentDir = Get-ProfileHome Pi }
$sourcePlugin = Join-Path $Root 'plugins\personal-workflow'
$manifest = Get-Content -LiteralPath (Join-Path $sourcePlugin '.codex-plugin\plugin.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$checks = [Collections.Generic.List[object]]::new()
function Add-Check {
    param([string]$Kind, [string]$Status, [string]$Path, [string]$Detail)
    $checks.Add([pscustomobject]@{ kind = $Kind; status = $Status; path = $Path; detail = $Detail })
}

foreach ($homePath in @($CodexHome, $PiAgentDir)) {
    $target = Join-Path $homePath 'AGENTS.md'
    if (-not (Test-Path -LiteralPath $target)) { Add-Check 'Agents' 'warning' $target 'Missing' }
    elseif ((Get-FileHash -LiteralPath $target).Hash -ne (Get-FileHash -LiteralPath (Join-Path $Root 'AGENTS.md')).Hash) {
        Add-Check 'Agents' 'warning' $target 'Differs from the repository; review before replacement'
    }
    else { Add-Check 'Agents' 'ok' $target 'Matches the repository' }
}

$previousHome = $env:CODEX_HOME
try {
    $env:CODEX_HOME = $CodexHome
    $markets = Invoke-ProfileCommand $CodexCommand @('plugin', 'marketplace', 'list', '--json') -Json
    $currentMarket = @($markets.marketplaces | Where-Object { $_.name -eq 'agent-workflow-profile' })
    if ($currentMarket.Count -ne 1 -or (Get-ProfilePath $currentMarket[0].root) -ne (Get-ProfilePath $Root)) {
        Add-Check 'Marketplace' 'warning' $Root 'Current marketplace is missing or points to another checkout'
    }
    else { Add-Check 'Marketplace' 'ok' $currentMarket[0].root 'Current checkout registered' }
    foreach ($market in $markets.marketplaces) {
        if (-not (Test-Path -LiteralPath $market.root)) { Add-Check 'Marketplace' 'warning' $market.root 'Registered path is missing' }
        if ($market.name -eq 'codex-workflow-profile') { Add-Check 'LegacyMarketplace' 'warning' $market.root 'Legacy registration remains; review migration' }
    }
    $state = Invoke-ProfileCommand $CodexCommand @('plugin', 'list', '--json') -Json
    $plugins = @($state.installed | Where-Object { $_.name -eq 'personal-workflow' })
    $currentPlugin = @($plugins | Where-Object { $_.pluginId -eq 'personal-workflow@agent-workflow-profile' })
    if ($currentPlugin.Count -ne 1 -or $currentPlugin[0].enabled -ne $true -or $currentPlugin[0].version -ne $manifest.version) {
        Add-Check 'Plugin' 'warning' $CodexHome "Expected one enabled current plugin, version $($manifest.version)"
    }
    else { Add-Check 'Plugin' 'ok' $CodexHome "Enabled current plugin, version $($manifest.version)" }
    if (@($plugins | Where-Object { $_.enabled -eq $true }).Count -gt 1) {
        Add-Check 'DuplicatePlugin' 'warning' $CodexHome 'Multiple personal-workflow plugins are enabled'
    }
}
catch {
    Add-Check 'CodexSnapshot' 'error' $CodexHome "Cannot determine active registrations: $($_.Exception.Message)"
}
finally { $env:CODEX_HOME = $previousHome }

# Cache presence alone does not establish that a plugin is enabled.
$cache = Join-Path $CodexHome "plugins\cache\agent-workflow-profile\personal-workflow\$($manifest.version)"
if (-not (Test-Path -LiteralPath $cache)) { Add-Check 'PluginContent' 'warning' $cache 'Expected cache is missing' }
else {
    $differences = @(Get-ProfileTreeDifference $sourcePlugin $cache)
    if ($differences.Count) { Add-Check 'PluginContent' 'warning' $cache ($differences -join '; ') }
    else { Add-Check 'PluginContent' 'ok' $cache 'All plugin files match the repository' }
}
foreach ($skill in Get-ChildItem -LiteralPath (Join-Path $sourcePlugin 'skills') -Directory) {
    $standalone = Join-Path $CodexHome "skills\$($skill.Name)"
    if (Test-Path -LiteralPath $standalone) {
        $differences = @(Get-ProfileTreeDifference $skill.FullName $standalone)
        $detail = 'Identical standalone copy; review archival'
        if ($differences.Count) { $detail = 'Review local differences before archival: ' + ($differences -join '; ') }
        Add-Check 'StandaloneSkill' 'warning' $standalone $detail
    }
}
$legacyDesign = Join-Path $CodexHome 'skills\design-first-development\SKILL.md'
if (Test-Path -LiteralPath $legacyDesign) {
    Add-Check 'IndependentSkill' 'warning' $legacyDesign 'Separate design workflow; review overlap manually, not an automatic archival candidate'
}

$settingsPath = Join-Path $PiAgentDir 'settings.json'
try {
    if (-not (Test-Path -LiteralPath $settingsPath)) { throw 'Pi settings.json is missing' }
    $settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $currentPackages = @($settings.packages | Where-Object {
        $source = Get-PiPackageSource $_
        [IO.Path]::IsPathRooted($source) -and (Get-ProfilePath $source) -eq (Get-ProfilePath $Root)
    })
    if ($currentPackages.Count -eq 1) { Add-Check 'PiPackage' 'ok' $Root 'Current checkout registered' }
    else { Add-Check 'PiPackage' 'warning' $settingsPath 'Expected exactly one registration for the current checkout' }
    foreach ($package in $settings.packages) {
        $source = Get-PiPackageSource $package
        if (-not [IO.Path]::IsPathRooted($source)) { continue }
        if (-not (Test-Path -LiteralPath $source)) { Add-Check 'PiPackagePath' 'warning' $source 'Registered local path is missing' }
        if ((Split-Path -Leaf (Get-ProfilePath $source)) -eq 'codex-workflow-profile') {
            Add-Check 'LegacyPiPackage' 'warning' $source 'Legacy path remains; review migration'
        }
        if ($package -isnot [string] -and (Get-ProfilePath $source) -eq (Get-ProfilePath $Root)) {
            Add-Check 'PiPackageFilters' 'warning' $source 'Resource filters are configured; verify which shared skills are enabled'
        }
    }
}
catch { Add-Check 'PiSettings' 'error' $settingsPath $_.Exception.Message }

$issues = @($checks | Where-Object { $_.status -ne 'ok' }).Count
if ($Json) { [pscustomobject]@{ issues = $issues; checks = @($checks.ToArray()) } | ConvertTo-Json -Depth 10 }
else {
    $checks | Format-Table status, kind, path, detail -Wrap
    Write-Host "Installation audit: $issues issue(s). No configuration, packages or skills were changed."
}
if ($FailOnIssues -and $issues) { throw "Installation audit found $issues issue(s)." }
