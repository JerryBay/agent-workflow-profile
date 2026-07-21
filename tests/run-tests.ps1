[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)

    $failures.Add($Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Assert-PathExists {
    param(
        [string]$RelativePath,
        [string]$Label
    )

    $path = Join-Path $repoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Failure "$Label is missing: $RelativePath"
    }
}

function Assert-FileContains {
    param(
        [string]$RelativePath,
        [string]$Pattern,
        [string]$Label
    )

    $path = Join-Path $repoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Failure "$Label cannot be checked because $RelativePath is missing"
        return
    }

    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($content -notmatch $Pattern) {
        Add-Failure "$Label is not encoded in $RelativePath"
    }
}

function Copy-ProfileFixture {
    param([string]$Name)

    $fixtureRoot = Join-Path $PSScriptRoot ".tmp-$Name-$PID"
    New-Item -ItemType Directory -Path $fixtureRoot | Out-Null

    Get-ChildItem -LiteralPath $repoRoot -Force |
        Where-Object { $_.Name -notin @(".git", "tests") } |
        Copy-Item -Destination $fixtureRoot -Recurse -Force

    return $fixtureRoot
}

function Invoke-ProfileValidator {
    param([string]$Root)

    $validator = Join-Path $repoRoot "scripts\validate-profile.ps1"
    $shell = (Get-Process -Id $PID).Path
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $shell
    $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$validator`""
    if (-not [string]::IsNullOrWhiteSpace($Root)) {
        $startInfo.Arguments += " -Root `"$Root`""
    }
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    [void]$process.Start()
    [void]$process.StandardOutput.ReadToEnd()
    [void]$process.StandardError.ReadToEnd()
    $process.WaitForExit()
    return $process.ExitCode
}

Assert-FileContains "AGENTS.md" "mode, goal, boundaries, and acceptance criteria" "Task contract"
Assert-FileContains "AGENTS.md" "implemented, verified, and unverified" "Completion-state separation"
Assert-FileContains "AGENTS.md" "single-agent" "Delegation threshold"

$minimalSkill = "plugins\personal-workflow\skills\minimal-scope-repo-change\SKILL.md"
Assert-FileContains $minimalSkill "Verification Ladder" "Verification ladder"
Assert-FileContains $minimalSkill "runtime" "Runtime verification"
Assert-FileContains $minimalSkill "persistence" "Persistence verification"

$designSkill = "plugins\personal-workflow\skills\design-first-project-planning\SKILL.md"
foreach ($section in @("Confirmed", "Rejected", "Open", "Evidence", "Next validation")) {
    Assert-FileContains $designSkill ([regex]::Escape($section)) "Decision-log section '$section'"
}

$debugSkill = "plugins\personal-workflow\skills\evidence-first-local-debugging\SKILL.md"
Assert-FileContains $debugSkill "inclusion" "Repository-analysis inclusion rule"
Assert-FileContains $debugSkill "exclusion" "Repository-analysis exclusion rule"
Assert-FileContains $debugSkill "counting" "Repository-analysis counting rule"

$orientationRoot = "plugins\personal-workflow\skills\local-repo-orientation"
Assert-PathExists "$orientationRoot\SKILL.md" "Local repo orientation skill"
Assert-PathExists "$orientationRoot\agents\openai.yaml" "Local repo orientation metadata"
Assert-PathExists "$orientationRoot\assets\project-entry-card.md" "Project entry card template"
Assert-FileContains "README.md" "local-repo-orientation" "README skill inventory"

Assert-FileContains "plugins\personal-workflow\.codex-plugin\plugin.json" '"version"\s*:\s*"0\.2\.0"' "Plugin version"
Assert-PathExists "scripts\validate-profile.ps1" "Profile validator"
Assert-FileContains "install.ps1" "ValidateOnly" "Validation-only install mode"

$validatorPath = Join-Path $repoRoot "scripts\validate-profile.ps1"
if (Test-Path -LiteralPath $validatorPath) {
    if ((Invoke-ProfileValidator) -ne 0) {
        Add-Failure "Validator failed when invoked directly with its default root"
    }

    if ((Invoke-ProfileValidator -Root $repoRoot) -ne 0) {
        Add-Failure "Validator rejected the valid profile"
    }

    $fixtureRoots = [System.Collections.Generic.List[string]]::new()
    try {
        $missingMetadata = Copy-ProfileFixture -Name "missing-metadata"
        $fixtureRoots.Add($missingMetadata)
        $metadataPath = Join-Path $missingMetadata "$orientationRoot\agents\openai.yaml"
        Remove-Item -LiteralPath $metadataPath -Force
        if ((Invoke-ProfileValidator -Root $missingMetadata) -eq 0) {
            Add-Failure "Validator accepted a skill without agents/openai.yaml"
        }

        $absolutePath = Copy-ProfileFixture -Name "absolute-path"
        $fixtureRoots.Add($absolutePath)
        $skillPath = Join-Path $absolutePath "$orientationRoot\SKILL.md"
        Add-Content -LiteralPath $skillPath -Value "Example project: E:\specific\project" -Encoding UTF8
        if ((Invoke-ProfileValidator -Root $absolutePath) -eq 0) {
            Add-Failure "Validator accepted a hard-coded Windows project path"
        }
    }
    finally {
        foreach ($fixtureRoot in $fixtureRoots) {
            if (Test-Path -LiteralPath $fixtureRoot) {
                Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
            }
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host "Profile tests failed: $($failures.Count)" -ForegroundColor Red
    exit 1
}

Write-Host "Profile tests passed." -ForegroundColor Green
