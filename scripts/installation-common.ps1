function Get-ProfileHome {
    param([ValidateSet('Codex', 'Pi')][string]$Agent)

    if ($Agent -eq 'Codex') {
        if ($env:CODEX_HOME) { return $env:CODEX_HOME }
        return Join-Path $env:USERPROFILE '.codex'
    }
    if ($env:PI_CODING_AGENT_DIR) { return $env:PI_CODING_AGENT_DIR }
    return Join-Path $env:USERPROFILE '.pi\agent'
}

function Get-ProfilePath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
    if ($Path.StartsWith('\\?\UNC\')) { $Path = '\\' + $Path.Substring(8) }
    elseif ($Path.StartsWith('\\?\')) { $Path = $Path.Substring(4) }
    return [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
}

function Invoke-ProfileCommand {
    param([string]$Command, [string[]]$Arguments, [switch]$Json, [switch]$AllowMissingMarketplace)

    $commandInfo = Get-Command -Name $Command -ErrorAction Stop | Select-Object -First 1
    $executable = $commandInfo.Source
    if (-not $executable) { $executable = $commandInfo.Definition }
    # Native stderr is diagnostic text, not JSON; check the exit code before parsing stdout.
    $savedPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $LASTEXITCODE = 0
        $output = @(& $executable @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally { $ErrorActionPreference = $savedPreference }
    $stdout = ($output | Where-Object { $_ -isnot [Management.Automation.ErrorRecord] } | Out-String).Trim()
    $diagnostic = ($output | Out-String).Trim()
    if ($exitCode -ne 0) {
        if ($AllowMissingMarketplace -and $diagnostic -match 'marketplace `codex-workflow-profile` is not configured or installed') { return }
        throw "Command failed ($exitCode): $Command $($Arguments -join ' ')`n$diagnostic"
    }
    if ($Json) { return $stdout | ConvertFrom-Json }
}

function Get-ProfileTreeDifference {
    param([string]$Reference, [string]$Candidate)

    $expected = @{}
    $actual = @{}
    foreach ($pair in @(@($Reference, $expected), @($Candidate, $actual))) {
        $root = [string]$pair[0]
        if (Test-Path -LiteralPath $root) {
            Get-ChildItem -LiteralPath $root -Recurse -File -Force | ForEach-Object {
                $relative = $_.FullName.Substring($root.TrimEnd('\', '/').Length).TrimStart('\', '/')
                $pair[1][$relative] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
            }
        }
    }
    foreach ($name in @(@($expected.Keys) + @($actual.Keys) | Sort-Object -Unique)) {
        if (-not $expected.ContainsKey($name)) { "Extra: $name" }
        elseif (-not $actual.ContainsKey($name)) { "Missing: $name" }
        elseif ($expected[$name] -ne $actual[$name]) { "Changed: $name" }
    }
}

function Backup-ProfilePath {
    param([string]$Path, [string]$BackupRoot, [string]$Name)

    if (Test-Path -LiteralPath $Path) {
        New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
        Copy-Item -LiteralPath $Path -Destination (Join-Path $BackupRoot $Name) -Recurse -Force
        Write-Host "Backed up $Path to $BackupRoot\$Name"
    }
}

function Get-PiPackageSource {
    param($Package)

    if ($Package -is [string]) { return $Package }
    return [string]$Package.source
}
