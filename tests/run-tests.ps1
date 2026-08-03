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
Assert-FileContains "AGENTS.md" "use a fast path" "Low-risk fast path"
Assert-FileContains "AGENTS.md" "Resolve approximate names, shorthand, aliases, and omitted paths" "Contextual reference resolution"
Assert-FileContains "AGENTS.md" "challenge it directly and briefly" "Evidence-backed challenge"
Assert-FileContains "AGENTS.md" "respond through annotations or grouped feedback" "Grouped requirements clarification"
Assert-FileContains "AGENTS.md" "Ask a single blocking question separately" "Blocking-question exception"
Assert-FileContains "AGENTS.md" "implemented, verified, and unverified" "Completion-state separation"
Assert-FileContains "AGENTS.md" "single-agent" "Delegation threshold"
Assert-FileContains "AGENTS.md" "evidence-backed, reversible work" "Autonomous-action threshold"
Assert-FileContains "AGENTS.md" "high cohesion, low coupling" "Architecture preference"
Assert-FileContains "AGENTS.md" "observed facts, inferences, assumptions, and unknowns" "Uncertainty reporting"
Assert-FileContains "AGENTS.md" "outcome in plain language" "Communication preference"
Assert-FileContains "AGENTS.md" "briefly explain terms that are outside the user's field" "Terminology explanation preference"

$minimalSkill = "plugins\personal-workflow\skills\minimal-scope-repo-change\SKILL.md"
Assert-FileContains $minimalSkill "Verification Ladder" "Verification ladder"
Assert-FileContains $minimalSkill "runtime" "Runtime verification"
Assert-FileContains $minimalSkill "persistence" "Persistence verification"
Assert-FileContains $minimalSkill "fewest-line patch" "Design-correct minimum"
Assert-FileContains $minimalSkill "data structure" "Data-structure checkpoint"
Assert-FileContains $minimalSkill "performance" "Performance checkpoint"

$architectureRoot = "plugins\personal-workflow\skills\architecture-aware-development"
Assert-PathExists "$architectureRoot\SKILL.md" "Architecture-aware development skill"
Assert-PathExists "$architectureRoot\agents\openai.yaml" "Architecture-aware development metadata"
Assert-FileContains "$architectureRoot\SKILL.md" "cohesive ownership" "Architecture ownership rule"
Assert-FileContains "$architectureRoot\SKILL.md" "dominant reads, writes, lookups" "Data-structure design rule"
Assert-FileContains "$architectureRoot\SKILL.md" "Measure representative behavior" "Evidence-based performance rule"
Assert-FileContains "$architectureRoot\SKILL.md" "hypothetical futures" "Over-engineering guardrail"
Assert-FileContains "$architectureRoot\agents\openai.yaml" '\$architecture-aware-development' "Architecture skill default prompt"

$designSkill = "plugins\personal-workflow\skills\design-first-project-planning\SKILL.md"
foreach ($section in @("Confirmed", "Rejected", "Open", "Evidence", "Next validation")) {
    Assert-FileContains $designSkill ([regex]::Escape($section)) "Decision-log section '$section'"
}
Assert-FileContains $designSkill "Present related unresolved points together as a concise numbered review list" "Grouped planning clarification"
Assert-FileContains $designSkill "Ask a single blocking question separately" "Planning blocking-question exception"

$debugSkill = "plugins\personal-workflow\skills\evidence-first-local-debugging\SKILL.md"
Assert-FileContains $debugSkill "inclusion" "Repository-analysis inclusion rule"
Assert-FileContains $debugSkill "exclusion" "Repository-analysis exclusion rule"
Assert-FileContains $debugSkill "counting" "Repository-analysis counting rule"

$orientationRoot = "plugins\personal-workflow\skills\local-repo-orientation"
Assert-PathExists "$orientationRoot\SKILL.md" "Local repo orientation skill"
Assert-PathExists "$orientationRoot\agents\openai.yaml" "Local repo orientation metadata"
Assert-PathExists "$orientationRoot\assets\project-entry-card.md" "Project entry card template"
Assert-FileContains "README.md" "local-repo-orientation" "README skill inventory"
Assert-FileContains "README.md" "architecture-aware-development" "README architecture skill inventory"

Assert-FileContains "plugins\personal-workflow\.codex-plugin\plugin.json" '"version"\s*:\s*"0\.3\.0"' "Plugin version"
Assert-PathExists "package.json" "Pi package manifest"
Assert-FileContains "package.json" '"pi-package"' "Pi package keyword"
Assert-FileContains "package.json" '\./plugins/personal-workflow/skills' "Shared Pi skill path"
Assert-PathExists "scripts\validate-profile.ps1" "Profile validator"
Assert-FileContains "install.ps1" "ValidateOnly" "Validation-only install mode"
Assert-PathExists "install-pi.ps1" "Pi installer"
Assert-FileContains "install-pi.ps1" "ValidateOnly" "Pi validation-only install mode"
Assert-FileContains "install-pi.ps1" "PI_CODING_AGENT_DIR" "Pi configuration directory override"

$piInstallerPath = Join-Path $repoRoot "install-pi.ps1"
if (Test-Path -LiteralPath $piInstallerPath) {
    try {
        & $piInstallerPath -ValidateOnly | Out-Null
    }
    catch {
        Add-Failure "Pi installer validation-only mode failed: $($_.Exception.Message)"
    }
}

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

        $wrongPrompt = Copy-ProfileFixture -Name "wrong-prompt"
        $fixtureRoots.Add($wrongPrompt)
        $metadataPath = Join-Path $wrongPrompt "$architectureRoot\agents\openai.yaml"
        $metadataContent = Get-Content -LiteralPath $metadataPath -Raw -Encoding UTF8
        $metadataContent = $metadataContent -replace '\$architecture-aware-development', '$different-skill'
        Set-Content -LiteralPath $metadataPath -Value $metadataContent -Encoding UTF8
        if ((Invoke-ProfileValidator -Root $wrongPrompt) -eq 0) {
            Add-Failure "Validator accepted a skill default_prompt without its skill token"
        }

        $absolutePath = Copy-ProfileFixture -Name "absolute-path"
        $fixtureRoots.Add($absolutePath)
        $skillPath = Join-Path $absolutePath "$orientationRoot\SKILL.md"
        Add-Content -LiteralPath $skillPath -Value "Example project: E:\specific\project" -Encoding UTF8
        if ((Invoke-ProfileValidator -Root $absolutePath) -eq 0) {
            Add-Failure "Validator accepted a hard-coded Windows project path"
        }

        $wrongPiSkills = Copy-ProfileFixture -Name "wrong-pi-skills"
        $fixtureRoots.Add($wrongPiSkills)
        $packagePath = Join-Path $wrongPiSkills "package.json"
        $package = Get-Content -LiteralPath $packagePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $package.pi.skills = @("./different-skills")
        $package | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $packagePath -Encoding UTF8
        if ((Invoke-ProfileValidator -Root $wrongPiSkills) -eq 0) {
            Add-Failure "Validator accepted a Pi package that does not use the shared skills"
        }

        $piInstall = Copy-ProfileFixture -Name "pi-install"
        $fixtureRoots.Add($piInstall)
        $previousPiAgentDir = $env:PI_CODING_AGENT_DIR
        $previousUserProfile = $env:USERPROFILE
        try {
            $testPiAgentDir = Join-Path $piInstall ".pi-agent"
            New-Item -ItemType Directory -Path $testPiAgentDir | Out-Null
            $testPiAgents = Join-Path $testPiAgentDir "AGENTS.md"
            Set-Content -LiteralPath $testPiAgents -Value "previous Pi rules" -Encoding UTF8

            $testCodexDir = Join-Path $piInstall ".codex"
            New-Item -ItemType Directory -Path $testCodexDir | Out-Null
            $testCodexAgents = Join-Path $testCodexDir "AGENTS.md"
            Set-Content -LiteralPath $testCodexAgents -Value "unchanged Codex rules" -Encoding UTF8
            $codexAgentsHash = (Get-FileHash -LiteralPath $testCodexAgents).Hash

            $fakePiLog = Join-Path $piInstall "pi-command.log"
            $fakePiCommand = Join-Path $piInstall "pi.cmd"
            $fakePiScript = "@echo off`r`necho %* > `"$fakePiLog`"`r`nexit /b 0"
            Set-Content -LiteralPath $fakePiCommand -Value $fakePiScript -Encoding ASCII

            $env:PI_CODING_AGENT_DIR = $testPiAgentDir
            $env:USERPROFILE = $piInstall

            & (Join-Path $piInstall "install-pi.ps1") -PiCommand $fakePiCommand | Out-Null

            $expectedPiArguments = "install $piInstall"
            if (-not (Test-Path -LiteralPath $fakePiLog) -or
                (Get-Content -LiteralPath $fakePiLog -Raw).Trim() -ne $expectedPiArguments) {
                Add-Failure "Pi installer did not register the current checkout as a local package"
            }

            $sourceAgents = Join-Path $piInstall "AGENTS.md"
            if ((Get-FileHash -LiteralPath $sourceAgents).Hash -ne (Get-FileHash -LiteralPath $testPiAgents).Hash) {
                Add-Failure "Pi installer did not install the shared AGENTS.md"
            }

            if (@(Get-ChildItem -LiteralPath $testPiAgentDir -Filter "AGENTS.md.backup-*").Count -ne 1) {
                Add-Failure "Pi installer did not back up the previous AGENTS.md"
            }

            if ((Get-FileHash -LiteralPath $testCodexAgents).Hash -ne $codexAgentsHash) {
                Add-Failure "Pi installer modified the existing Codex AGENTS.md"
            }
        }
        catch {
            Add-Failure "Pi installer fixture failed: $($_.Exception.Message)"
        }
        finally {
            $env:PI_CODING_AGENT_DIR = $previousPiAgentDir
            $env:USERPROFILE = $previousUserProfile
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
