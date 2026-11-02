[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$installer = Join-Path $repoRoot 'install-dsh.ps1'
. (Join-Path $repoRoot 'scripts\installation-common.ps1')
$sourceSkills = Join-Path $repoRoot 'plugins\personal-workflow\skills'
$skills = @(Get-ChildItem -LiteralPath $sourceSkills -Directory | Sort-Object Name)
$testName = 'workflow-dsh-test-' + [guid]::NewGuid().ToString('N')
$testRoot = Join-Path ([IO.Path]::GetTempPath()) $testName
$previousDshHome = $env:DSH_HOME
$previousUserProfile = $env:USERPROFILE
$checks = 0

function Assert-DshTest {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
    $script:checks++
}

function Assert-DshFailure {
    param([scriptblock]$Action, [string]$Expected)
    $caught = $null
    try { & $Action }
    catch { $caught = $_.Exception.Message }
    Assert-DshTest ($null -ne $caught -and $caught -like "*$Expected*") "Expected '$Expected', got '$caught'."
}

function Get-DshSnapshot {
    param([string]$Root)
    return (@(Get-ChildItem -LiteralPath $Root -Recurse -File -Force | Sort-Object FullName | ForEach-Object {
        $_.FullName.Substring($Root.Length) + ':' + (Get-FileHash -LiteralPath $_.FullName).Hash
    }) -join "`n")
}

try {
    New-Item -ItemType Directory -Path $testRoot | Out-Null
    $env:DSH_HOME = Join-Path $testRoot 'environment home'
    $env:USERPROFILE = Join-Path $testRoot 'fake user'

    & $installer -ValidateOnly
    Assert-DshTest (-not (Test-Path -LiteralPath $env:DSH_HOME)) 'ValidateOnly created the environment home.'
    Assert-DshFailure { & $installer -DshHome $repoRoot } 'must differ'
    Assert-DshFailure { & $installer -DshHome (Join-Path $sourceSkills 'nested-home') } 'source skills directory'
    Assert-DshTest (-not (Test-Path -LiteralPath (Join-Path $sourceSkills 'nested-home'))) 'Rejected home changed the source directory.'

    $wrongTypeRoot = Join-Path $testRoot 'wrong type'
    New-Item -ItemType Directory -Path (Join-Path $wrongTypeRoot 'AGENTS.md') -Force | Out-Null
    Assert-DshFailure { & $installer -DshHome $wrongTypeRoot } 'Unexpected file or directory'
    Assert-DshTest (-not (Test-Path -LiteralPath (Join-Path $wrongTypeRoot 'skills'))) 'Invalid destination partially installed skills.'

    $explicitRoot = Join-Path $testRoot 'explicit home'
    & $installer -DshHome $explicitRoot
    Assert-DshTest (-not (Test-Path -LiteralPath $env:DSH_HOME)) 'Explicit home did not take precedence over DSH_HOME.'
    Assert-DshTest ((Get-FileHash -LiteralPath (Join-Path $repoRoot 'AGENTS.md')).Hash -eq
        (Get-FileHash -LiteralPath (Join-Path $explicitRoot 'AGENTS.md')).Hash) 'Global instructions differ.'
    Assert-DshTest (@(Get-ProfileTreeDifference $sourceSkills (Join-Path $explicitRoot 'skills')).Count -eq 0) 'Installed skill bundles differ.'

    $before = Get-DshSnapshot $explicitRoot
    $agentsWriteTime = (Get-Item -LiteralPath (Join-Path $explicitRoot 'AGENTS.md')).LastWriteTimeUtc
    & $installer -DshHome $explicitRoot -Refresh
    Assert-DshTest ((Get-DshSnapshot $explicitRoot) -eq $before) 'An identical refresh changed files.'
    Assert-DshTest ((Get-Item -LiteralPath (Join-Path $explicitRoot 'AGENTS.md')).LastWriteTimeUtc -eq $agentsWriteTime) 'An identical refresh rewrote AGENTS.md.'
    Assert-DshTest (-not (Test-Path -LiteralPath (Join-Path $explicitRoot 'workflow-profile-backups'))) 'An identical refresh created a backup.'

    $targetAgents = Join-Path $explicitRoot 'AGENTS.md'
    $targetSkill = Join-Path $explicitRoot (Join-Path 'skills' $skills[0].Name)
    $targetSkillFile = Join-Path $targetSkill 'SKILL.md'
    Set-Content -LiteralPath $targetAgents -Value 'old personal rules' -Encoding UTF8
    Add-Content -LiteralPath $targetSkillFile -Value 'local customization' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $targetSkill 'obsolete.txt') -Value 'old resource' -Encoding UTF8
    $unrelated = Join-Path $explicitRoot 'skills\unrelated-skill'
    New-Item -ItemType Directory -Path $unrelated | Out-Null
    Set-Content -LiteralPath (Join-Path $unrelated 'SKILL.md') -Value 'unrelated skill' -Encoding UTF8
    $config = Join-Path $explicitRoot 'settings.yaml'
    Set-Content -LiteralPath $config -Value 'keep: true' -Encoding UTF8
    $configHash = (Get-FileHash -LiteralPath $config).Hash
    $unrelatedHash = (Get-FileHash -LiteralPath (Join-Path $unrelated 'SKILL.md')).Hash
    $oldAgentsHash = (Get-FileHash -LiteralPath $targetAgents).Hash
    $oldSkillHash = (Get-FileHash -LiteralPath $targetSkillFile).Hash

    $before = Get-DshSnapshot $explicitRoot
    Assert-DshFailure { & $installer -DshHome $explicitRoot } 'Run with -Refresh'
    Assert-DshTest ((Get-DshSnapshot $explicitRoot) -eq $before) 'Conflict detection changed profile files.'

    & $installer -DshHome $explicitRoot -Refresh
    $backupRuns = @(Get-ChildItem -LiteralPath (Join-Path $explicitRoot 'workflow-profile-backups') -Directory)
    Assert-DshTest ($backupRuns.Count -eq 1) 'Expected one backup run.'
    $backupRoot = $backupRuns[0].FullName
    Assert-DshTest ((Get-FileHash -LiteralPath (Join-Path $backupRoot 'AGENTS.md')).Hash -eq $oldAgentsHash) 'Previous instructions were not backed up.'
    $skillBackup = Join-Path $backupRoot (Join-Path 'skills' $skills[0].Name)
    Assert-DshTest ((Get-FileHash -LiteralPath (Join-Path $skillBackup 'SKILL.md')).Hash -eq $oldSkillHash) 'Customized skill was not backed up.'
    Assert-DshTest (Test-Path -LiteralPath (Join-Path $skillBackup 'obsolete.txt')) 'Old resource was not backed up.'
    Assert-DshTest (-not (Test-Path -LiteralPath (Join-Path $targetSkill 'obsolete.txt'))) 'Refresh retained an obsolete bundled resource.'
    foreach ($skill in $skills) {
        Assert-DshTest (@(Get-ProfileTreeDifference $skill.FullName (Join-Path $explicitRoot (Join-Path 'skills' $skill.Name))).Count -eq 0) "Refreshed skill differs: $($skill.Name)"
    }
    Assert-DshTest ((Get-FileHash -LiteralPath $config).Hash -eq $configHash) 'DSH settings were changed.'
    Assert-DshTest ((Get-FileHash -LiteralPath (Join-Path $unrelated 'SKILL.md')).Hash -eq $unrelatedHash) 'Unrelated skill was changed.'

    $flatSkill = "$targetSkill.md"
    Set-Content -LiteralPath $flatSkill -Value 'existing flat skill' -Encoding UTF8
    $before = Get-DshSnapshot $explicitRoot
    Assert-DshFailure { & $installer -DshHome $explicitRoot -Refresh } 'same-name flat skill'
    Assert-DshTest ((Get-DshSnapshot $explicitRoot) -eq $before) 'Flat-skill conflict changed files.'
    Remove-Item -LiteralPath $flatSkill

    & $installer -SkipSkills
    Assert-DshTest (Test-Path -LiteralPath (Join-Path $env:DSH_HOME 'AGENTS.md')) 'DSH_HOME was not honored.'
    Assert-DshTest (-not (Test-Path -LiteralPath (Join-Path $env:DSH_HOME 'skills'))) 'SkipSkills installed skills.'
    $env:DSH_HOME = $null
    & $installer -SkipAgents
    $defaultRoot = Join-Path $env:USERPROFILE '.dsh'
    Assert-DshTest (Test-Path -LiteralPath (Join-Path $defaultRoot 'skills')) 'Default user home was not honored.'
    Assert-DshTest (-not (Test-Path -LiteralPath (Join-Path $defaultRoot 'AGENTS.md'))) 'SkipAgents installed instructions.'

    $linkedRoot = Join-Path $testRoot 'linked home'
    New-Item -ItemType Junction -Path $linkedRoot -Target $defaultRoot | Out-Null
    try {
        $before = Get-DshSnapshot $defaultRoot
        Assert-DshFailure { & $installer -DshHome $linkedRoot -Refresh } 'Linked installation paths'
        Assert-DshTest ((Get-DshSnapshot $defaultRoot) -eq $before) 'A linked installation modified its target.'
    }
    finally { [IO.Directory]::Delete($linkedRoot) }

    # Fail the second publication after AGENTS.md has changed, then check rollback.
    Set-Content -LiteralPath $targetAgents -Value 'rules before failed refresh' -Encoding UTF8
    Add-Content -LiteralPath $targetSkillFile -Value 'skill before failed refresh' -Encoding UTF8
    $beforeAgents = (Get-FileHash -LiteralPath $targetAgents).Hash
    $beforeSkill = Get-DshSnapshot $targetSkill
    $dshFailureState = @{ Destination = $targetSkill }
    function Move-Item {
        param([string]$LiteralPath, [string]$Destination)
        if ($Destination -eq $dshFailureState.Destination -and $LiteralPath -like '*.workflow-profile-stage-*') {
            $dshFailureState.Destination = $null
            throw 'Injected publication failure'
        }
        Microsoft.PowerShell.Management\Move-Item -LiteralPath $LiteralPath -Destination $Destination
    }
    try {
        Assert-DshFailure { & $installer -DshHome $explicitRoot -Refresh } 'Injected publication failure'
    }
    finally { Remove-Item -LiteralPath Function:\Move-Item }
    Assert-DshTest ((Get-FileHash -LiteralPath $targetAgents).Hash -eq $beforeAgents) 'Failed refresh did not restore instructions.'
    Assert-DshTest ((Get-DshSnapshot $targetSkill) -eq $beforeSkill) 'Failed refresh did not restore the skill.'
    Assert-DshTest (@(Get-ChildItem -LiteralPath $explicitRoot -Filter '.workflow-profile-stage-*' -Force).Count -eq 0) 'Staging files were left behind.'

    $invalidRepo = Join-Path $testRoot 'invalid profile'
    New-Item -ItemType Directory -Path $invalidRepo | Out-Null
    Get-ChildItem -LiteralPath $repoRoot -Force |
        Where-Object { $_.Name -in @('.agents', 'plugins', 'scripts', 'AGENTS.md', 'README.md', 'package.json', 'install-dsh.ps1') } |
        Copy-Item -Destination $invalidRepo -Recurse -Force
    $invalidSkill = Join-Path $invalidRepo (Join-Path 'plugins\personal-workflow\skills' (Join-Path $skills[0].Name 'SKILL.md'))
    Set-Content -LiteralPath $invalidSkill -Value 'missing frontmatter' -Encoding UTF8
    $invalidTarget = Join-Path $testRoot 'must not be created'
    Assert-DshFailure { & (Join-Path $invalidRepo 'install-dsh.ps1') -DshHome $invalidTarget } 'frontmatter'
    Assert-DshTest (-not (Test-Path -LiteralPath $invalidTarget)) 'Invalid source created a target home.'
}
finally {
    $env:DSH_HOME = $previousDshHome
    $env:USERPROFILE = $previousUserProfile
    $resolvedTest = [IO.Path]::GetFullPath($testRoot)
    $tempParent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
    if ((Split-Path -Parent $resolvedTest) -eq $tempParent -and
        (Split-Path -Leaf $resolvedTest) -eq $testName -and
        (Test-Path -LiteralPath $resolvedTest)) {
        Remove-Item -LiteralPath $resolvedTest -Recurse -Force
    }
}

Write-Host "DeepSeek Harness installation tests passed: $checks checks."
