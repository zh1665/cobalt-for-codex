$ErrorActionPreference = "Stop"

$ThemeName = "Cobalt for CodeX"
$CodexHome = Join-Path $env:USERPROFILE ".codex"
$ConfigPath = Join-Path $CodexHome "config.toml"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupPath = "$ConfigPath.cobalt-for-codex-backup-$Timestamp"

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Ensure-Section {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)][string]$Section
    )

    $pattern = "(?m)^\[$([regex]::Escape($Section))\]\s*$"
    if ($Text -match $pattern) {
        return $Text
    }

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return "[$Section]`r`n"
    }

    return $Text.TrimEnd() + "`r`n`r`n[$Section]`r`n"
}

function Set-SectionKey {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)][string]$Section,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$Value
    )

    $Text = Ensure-Section -Text $Text -Section $Section

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in ($Text -split "\r?\n")) {
        $lines.Add($line)
    }

    $sectionHeader = "[$Section]"
    $sectionIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq $sectionHeader) {
            $sectionIndex = $i
            break
        }
    }

    if ($sectionIndex -lt 0) {
        throw "Could not find TOML section [$Section]."
    }

    $insertIndex = $lines.Count
    for ($i = $sectionIndex + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*\[[^\]]+\]\s*$') {
            $insertIndex = $i
            break
        }
    }

    $keyPattern = "^\s*$([regex]::Escape($Key))\s*="
    for ($i = $sectionIndex + 1; $i -lt $insertIndex; $i++) {
        if ($lines[$i] -match $keyPattern) {
            $lines[$i] = "$Key = $Value"
            return ($lines -join "`r`n").TrimEnd() + "`r`n"
        }
    }

    if ($insertIndex -gt $sectionIndex + 1 -and -not [string]::IsNullOrWhiteSpace($lines[$insertIndex - 1])) {
        $lines.Insert($insertIndex, "")
        $insertIndex++
    }

    $lines.Insert($insertIndex, "$Key = $Value")
    return ($lines -join "`r`n").TrimEnd() + "`r`n"
}

function Remove-Section {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)][string]$Section
    )

    $sectionPattern = '(?ms)^\[' + [regex]::Escape($Section) + '\]\s*$(.*?)(?=^\[|\z)'
    return [regex]::Replace($Text, $sectionPattern, "").TrimEnd()
}

function Append-SectionBlock {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)][string]$Block
    )

    return $Text.TrimEnd() + "`r`n`r`n" + $Block.Trim() + "`r`n"
}

$ThemeBlock = @"
[desktop.appearanceLightChromeTheme]
accent = "#ffc600"
contrast = 55
ink = "#002240"
opaqueWindows = true
surface = "#f4f8ff"

[desktop.appearanceLightChromeTheme.fonts]

[desktop.appearanceLightChromeTheme.semanticColors]
diffAdded = "#3ad900"
diffRemoved = "#ff628c"
skill = "#ffc600"

[desktop.appearanceDarkChromeTheme]
accent = "#ffc600"
contrast = 65
ink = "#ffffff"
opaqueWindows = true
surface = "#002240"

[desktop.appearanceDarkChromeTheme.fonts]
code = '"Jetbrains Mono"'
ui = "Inter"

[desktop.appearanceDarkChromeTheme.semanticColors]
diffAdded = "#3ad900"
diffRemoved = "#ff628c"
skill = "#ffc600"
"@

New-Item -ItemType Directory -Force -Path $CodexHome | Out-Null

if (Test-Path -LiteralPath $ConfigPath) {
    Copy-Item -LiteralPath $ConfigPath -Destination $BackupPath
    $config = [System.IO.File]::ReadAllText($ConfigPath)
}
else {
    $config = ""
    $BackupPath = $null
}

$config = Set-SectionKey -Text $config -Section "desktop" -Key "appearanceTheme" -Value '"dark"'
$config = Set-SectionKey -Text $config -Section "desktop" -Key "appearanceLightCodeThemeId" -Value '"cobalt"'
$config = Set-SectionKey -Text $config -Section "desktop" -Key "appearanceDarkCodeThemeId" -Value '"cobalt"'

$themeSections = @(
    "desktop.appearanceLightChromeTheme",
    "desktop.appearanceLightChromeTheme.fonts",
    "desktop.appearanceLightChromeTheme.semanticColors",
    "desktop.appearanceDarkChromeTheme",
    "desktop.appearanceDarkChromeTheme.fonts",
    "desktop.appearanceDarkChromeTheme.semanticColors"
)

foreach ($section in $themeSections) {
    $config = Remove-Section -Text $config -Section $section
}

$config = Append-SectionBlock -Text $config -Block $ThemeBlock
Write-Utf8NoBom -Path $ConfigPath -Content $config

Write-Host "$ThemeName installed."
Write-Host "Config: $ConfigPath"
if ($BackupPath) {
    Write-Host "Backup: $BackupPath"
}
Write-Host "Restart Codex Desktop to reload the theme."
