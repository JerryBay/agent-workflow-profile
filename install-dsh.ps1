[CmdletBinding()]
param(
    [string]$DshHome,
    [switch]$SkipAgents,
    [switch]$SkipSkills,
    [switch]$ValidateOnly,
    [switch]$Refresh
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot
. (Join-Path $repoRoot 'scripts\installation-common.ps1')
& (Join-Path $repoRoot 'scripts\validate-profile.ps1') -Root $repoRoot

if ($ValidateOnly) {
    Write-Host 'DeepSeek Harness profile validation completed. No user configuration was changed.'
    return
}

if ([string]::IsNullOrWhiteSpace($DshHome)) { $DshHome = $env:DSH_HOME }
if ([string]::IsNullOrWhiteSpace($DshHome)) { $DshHome = Join-Path $env:USERPROFILE '.dsh' }
$targetRoot = Get-ProfilePath $DshHome
$sourceSkills = Get-ProfilePath (Join-Path $repoRoot 'plugins\personal-workflow\skills')
if ($targetRoot -eq (Get-ProfilePath $repoRoot)) {
    throw 'The DeepSeek Harness home must differ from this workflow checkout.'
}
if ($targetRoot -eq $sourceSkills -or
    $targetRoot.StartsWith($sourceSkills + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The DeepSeek Harness home must not be inside the source skills directory.'
}

function Test-DshEntryEqual {
    param($Entry, [string]$Candidate)

    if ($Entry.IsDirectory) {
        return (Test-Path -LiteralPath $Candidate -PathType Container) -and
            @(Get-ProfileTreeDifference -Reference $Entry.Source -Candidate $Candidate).Count -eq 0
    }
    return (Test-Path -LiteralPath $Candidate -PathType Leaf) -and
        (Get-FileHash -LiteralPath $Entry.Source).Hash -eq (Get-FileHash -LiteralPath $Candidate).Hash
}

function Assert-DshRegularPath {
    param([string]$Path)

    $current = $Path
    while ($current) {
        $item = Get-Item -LiteralPath $current -Force -ErrorAction SilentlyContinue
        if ($null -ne $item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Linked installation paths are not replaced automatically: $current"
        }
        $current = Split-Path -Parent $current
    }
}

$entries = @()
if (-not $SkipAgents) {
    $entries += [pscustomobject]@{
        Relative = 'AGENTS.md'
        Source = Join-Path $repoRoot 'AGENTS.md'
        IsDirectory = $false
    }
}
if (-not $SkipSkills) {
    foreach ($skill in Get-ChildItem -LiteralPath $sourceSkills -Directory | Sort-Object Name) {
        $entries += [pscustomobject]@{
            Relative = Join-Path 'skills' $skill.Name
            Source = $skill.FullName
            IsDirectory = $true
        }
    }
}

# Check every destination before installing anything, including same-name flat skills.
Assert-DshRegularPath $targetRoot
$changes = @()
foreach ($entry in $entries) {
    $target = Join-Path $targetRoot $entry.Relative
    Assert-DshRegularPath $target
    $exists = Test-Path -LiteralPath $target
    if ($exists -and ((Get-Item -LiteralPath $target -Force).PSIsContainer -ne $entry.IsDirectory)) {
        throw "Unexpected file or directory at $target. No profile files were changed."
    }
    if ($entry.IsDirectory -and (Test-Path -LiteralPath "$target.md")) {
        throw "A same-name flat skill already exists at $target.md. Resolve the duplicate before installing."
    }
    if (Test-DshEntryEqual $entry $target) {
        Write-Host "Already up to date: $target"
        continue
    }
    if ($entry.IsDirectory -and $exists -and -not $Refresh) {
        throw "Skill differs at $target. Run with -Refresh to back up and replace same-name skills. No profile files were changed."
    }
    $changes += $entry
}

if ($changes.Count -eq 0) {
    Write-Host 'DeepSeek Harness profile is already up to date for the selected components.'
    return
}

$runId = (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + [guid]::NewGuid().ToString('N')
$stageRoot = Join-Path $targetRoot ".workflow-profile-stage-$runId"
$backupRoot = Join-Path $targetRoot "workflow-profile-backups\$runId"
$published = [System.Collections.Generic.List[object]]::new()
try {
    New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null
    foreach ($entry in $changes) {
        $staged = Join-Path $stageRoot $entry.Relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $staged) -Force | Out-Null
        Copy-Item -LiteralPath $entry.Source -Destination $staged -Recurse -Force
        if (-not (Test-DshEntryEqual $entry $staged)) {
            throw "Staged copy failed hash verification: $($entry.Relative)"
        }
    }

    foreach ($entry in $changes) {
        $target = Join-Path $targetRoot $entry.Relative
        $staged = Join-Path $stageRoot $entry.Relative
        $backup = Join-Path $backupRoot $entry.Relative
        $record = [pscustomobject]@{
            Target = $target; Staged = $staged; Backup = $backup
            BackedUp = $false; Installed = $false
        }
        $published.Add($record)
        New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        if (Test-Path -LiteralPath $target) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $backup) -Force | Out-Null
            Move-Item -LiteralPath $target -Destination $backup
            $record.BackedUp = $true
        }
        Move-Item -LiteralPath $staged -Destination $target
        $record.Installed = $true
        if (-not (Test-DshEntryEqual $entry $target)) {
            throw "Installed copy failed hash verification: $($entry.Relative)"
        }
    }
}
catch {
    $installError = $_
    for ($index = $published.Count - 1; $index -ge 0; $index--) {
        $record = $published[$index]
        try {
            if ($record.Installed) {
                Move-Item -LiteralPath $record.Target -Destination $record.Staged
            }
            if ($record.BackedUp) {
                Move-Item -LiteralPath $record.Backup -Destination $record.Target
            }
        }
        catch {
            Write-Warning "Could not restore $($record.Target): $($_.Exception.Message). Check $backupRoot."
        }
    }
    throw $installError
}
finally {
    # Only remove this run's staging directory; live skills are never recursively deleted.
    $resolvedStage = [IO.Path]::GetFullPath($stageRoot)
    $expectedStage = Join-Path $targetRoot ".workflow-profile-stage-$runId"
    if ($resolvedStage -eq $expectedStage -and
        (Split-Path -Parent $resolvedStage) -eq $targetRoot -and
        (Test-Path -LiteralPath $resolvedStage)) {
        Remove-Item -LiteralPath $resolvedStage -Recurse -Force
    }
}

Write-Host "Verified $($changes.Count) updated profile items in $targetRoot."
if (Test-Path -LiteralPath $backupRoot) { Write-Host "Previous files are backed up at $backupRoot" }
Write-Host 'Start a new DeepSeek Harness session using this DSH_HOME to load AGENTS.md.'
Write-Host 'Files are verified; runtime loading depends on the instruction and filesystem-skill plugins in your preset.'
