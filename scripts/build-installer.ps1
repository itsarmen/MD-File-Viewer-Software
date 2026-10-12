# MD File Viewer
# Author:     Amiran Kimadze (itsarmen)
# GitHub:     https://github.com/itsarmen
# Email:      amoswaper@gmail.com
# Web:        https://xrow.asia
# Build a single-file Windows installer (.exe) with Inno Setup.
#
# Usage:
#   flutter build windows --release
#   pwsh -File scripts/build-installer.ps1 [-Version X.Y.Z]
#
# Output: dist/md-file-viewer_<version>_windows-x64-setup.exe
[CmdletBinding()]
param(
    [string]$Version
)

$ErrorActionPreference = 'Stop'

$App = 'md-file-viewer'
$Root = Split-Path -Parent $PSScriptRoot
$Bundle = Join-Path $Root 'build\windows\x64\runner\Release'
$Iss = Join-Path $Root 'windows\installer\md-file-viewer.iss'

# Version falls back to pubspec.yaml (strip Flutter's "+build" suffix).
if (-not $Version) {
    $match = Select-String -Path (Join-Path $Root 'pubspec.yaml') `
        -Pattern '^version:\s*(\S+)' | Select-Object -First 1
    if (-not $match) {
        throw 'Could not read the version from pubspec.yaml; pass -Version.'
    }
    $Version = ($match.Matches[0].Groups[1].Value -split '\+')[0]
}

if (-not (Test-Path (Join-Path $Bundle 'md_file_viewer.exe'))) {
    throw "Release bundle not found at $Bundle`nBuild it first:  flutter build windows --release"
}

# Locate the Inno Setup compiler (ISCC.exe).
$IsccCandidates = @(
    (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
    'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
    'C:\Program Files\Inno Setup 6\ISCC.exe'
)
$Iscc = $IsccCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Iscc) {
    $cmd = Get-Command 'iscc' -ErrorAction SilentlyContinue
    if ($cmd) { $Iscc = $cmd.Source }
}
if (-not $Iscc) {
    throw 'Inno Setup (ISCC.exe) not found. Install it with:  winget install JRSoftware.InnoSetup'
}

$Exe = Join-Path $Root "dist\${App}_${Version}_windows-x64-setup.exe"

Write-Host "Building $App $Version installer (windows-x64)"
& $Iscc "/DMyAppVersion=$Version" $Iss
if ($LASTEXITCODE -ne 0) {
    throw "ISCC failed with exit code $LASTEXITCODE"
}

Write-Host ''
Write-Host "Built: $Exe"