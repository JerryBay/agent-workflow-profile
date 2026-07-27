[CmdletBinding()]
param(
    [string]$Root
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

$repoRoot = (Resolve-Path -LiteralPath $Root).Path
$agentsPath = Join-Path $repoRoot "AGENTS.md"
$readmePath = Join-Path $repoRoot "README.md"
$marketplacePath = Join-Path $repoRoot ".agents\plugins\marketplace.json"
$pluginRoot = Join-Path $repoRoot "plugins\personal-workflow"
$pluginManifestPath = Join-Path $pluginRoot ".codex-plugin\plugin.json"
$skillsRoot = Join-Path $pluginRoot "skills"

function Assert-Exists {
    param(
        [string]$Path,
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Label is missing: $Path"
    }
}

function Read-JsonFile {
    param(
        [string]$Path,
        [string]$Label
    )

    Assert-Exists -Path $Path -Label $Label
    try {
        return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        throw "$Label is not valid JSON: $Path`n$($_.Exception.Message)"
    }
}

Assert-Exists -Path $agentsPath -Label "Global AGENTS.md"
Assert-Exists -Path $readmePath -Label "README"
Assert-Exists -Path $skillsRoot -Label "Skills directory"

$marketplace = Read-JsonFile -Path $marketplacePath -Label "Marketplace manifest"
$pluginManifest = Read-JsonFile -Path $pluginManifestPath -Label "Plugin manifest"

if ($marketplace.name -ne "codex-workflow-profile") {
    throw "Marketplace name must be 'codex-workflow-profile'."
}

$marketplacePlugin = @($marketplace.plugins) | Where-Object { $_.name -eq "personal-workflow" }
if (@($marketplacePlugin).Count -ne 1) {
    throw "Marketplace must contain exactly one 'personal-workflow' plugin entry."
}

if ($pluginManifest.name -ne "personal-workflow") {
    throw "Plugin name must be 'personal-workflow'."
}

if ([string]$pluginManifest.version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Plugin version must use semantic versioning."
}

if ($pluginManifest.skills -ne "./skills/") {
    throw "Plugin skills path must be './skills/'."
}

$skillDirectories = @(Get-ChildItem -LiteralPath $skillsRoot -Directory | Sort-Object Name)
if ($skillDirectories.Count -eq 0) {
    throw "At least one skill is required."
}

foreach ($skillDirectory in $skillDirectories) {
    $skillPath = Join-Path $skillDirectory.FullName "SKILL.md"
    $metadataPath = Join-Path $skillDirectory.FullName "agents\openai.yaml"
    Assert-Exists -Path $skillPath -Label "Skill entrypoint for '$($skillDirectory.Name)'"
    Assert-Exists -Path $metadataPath -Label "Skill UI metadata for '$($skillDirectory.Name)'"

    $skillContent = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8
    $frontmatterMatch = [regex]::Match($skillContent, '\A---\r?\n(?<body>.*?)\r?\n---\r?\n', 'Singleline')
    if (-not $frontmatterMatch.Success) {
        throw "Skill '$($skillDirectory.Name)' has invalid YAML frontmatter boundaries."
    }

    $frontmatter = $frontmatterMatch.Groups['body'].Value
    if ($frontmatter.Length -gt 1024) {
        throw "Skill '$($skillDirectory.Name)' frontmatter exceeds 1024 characters."
    }

    $nameMatch = [regex]::Match($frontmatter, '(?m)^name:\s*(?<value>[a-z0-9-]+)\s*$')
    $descriptionMatch = [regex]::Match($frontmatter, '(?m)^description:\s*(?<value>.+?)\s*$')
    if (-not $nameMatch.Success -or -not $descriptionMatch.Success) {
        throw "Skill '$($skillDirectory.Name)' frontmatter requires name and description."
    }

    if ($nameMatch.Groups['value'].Value -ne $skillDirectory.Name) {
        throw "Skill name must match its directory: '$($skillDirectory.Name)'."
    }

    if ($descriptionMatch.Groups['value'].Value -notmatch '^Use when\b') {
        throw "Skill '$($skillDirectory.Name)' description must start with 'Use when'."
    }

    $frontmatterKeys = [regex]::Matches($frontmatter, '(?m)^(?<key>[A-Za-z][A-Za-z0-9_-]*):') |
        ForEach-Object { $_.Groups['key'].Value }
    $unexpectedKeys = @($frontmatterKeys | Where-Object { $_ -notin @('name', 'description') })
    if ($unexpectedKeys.Count -gt 0) {
        throw "Skill '$($skillDirectory.Name)' has unsupported frontmatter fields: $($unexpectedKeys -join ', ')."
    }

    $metadata = Get-Content -LiteralPath $metadataPath -Raw -Encoding UTF8
    foreach ($key in @('interface:', 'display_name:', 'short_description:', 'default_prompt:')) {
        if ($metadata -notmatch "(?m)^\s*$([regex]::Escape($key))") {
            throw "Skill '$($skillDirectory.Name)' metadata is missing '$key'."
        }
    }

    $defaultPromptMatch = [regex]::Match(
        $metadata,
        '(?m)^\s*default_prompt:\s*"(?<value>[^"]+)"\s*$'
    )
    if (-not $defaultPromptMatch.Success) {
        throw "Skill '$($skillDirectory.Name)' metadata requires a quoted default_prompt."
    }

    $requiredSkillToken = '$' + $skillDirectory.Name
    if ($defaultPromptMatch.Groups['value'].Value -notmatch [regex]::Escape($requiredSkillToken)) {
        throw "Skill '$($skillDirectory.Name)' default_prompt must mention '$requiredSkillToken'."
    }
}

$portableFiles = [System.Collections.Generic.List[string]]::new()
$portableFiles.Add($agentsPath)
$portableFiles.Add($readmePath)
Get-ChildItem -LiteralPath $skillsRoot -Recurse -File |
    Where-Object { $_.Extension -in @('.md', '.yaml', '.yml', '.json', '.txt') } |
    ForEach-Object { $portableFiles.Add($_.FullName) }

$absoluteWindowsPathPattern = '(?<![A-Za-z0-9])[A-Za-z]:[\\/]'
foreach ($portableFile in $portableFiles) {
    $content = Get-Content -LiteralPath $portableFile -Raw -Encoding UTF8
    if ($content -match $absoluteWindowsPathPattern) {
        throw "Portable profile content contains a hard-coded Windows path: $portableFile"
    }
}

Write-Host "Validated personal workflow profile: $($skillDirectories.Count) skills, plugin version $($pluginManifest.version)."
