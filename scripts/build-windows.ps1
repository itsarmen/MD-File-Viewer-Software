# MD File Viewer
# Author:     Amiran Kimadze (itsarmen)
# GitHub:     https://github.com/itsarmen
# Email:      amoswaper@gmail.com
# Web:        https://xrow.asia
# Build a distributable ZIP from the Flutter Windows release bundle.
#
# Usage:
#   flutter build windows --release
#   pwsh -File scripts/build-windows.ps1 [-Version X.Y.Z] [-Arch x64]
#
# Output: dist/md-file-viewer_<version>_windows-<arch>.zip
[CmdletBinding()]
param(
    [string]$Version,
    [string]$Arch = 'x64'
)

$ErrorActionPreference = 'Stop'

$App = 'md-file-viewer'
$BinName = 'md_file_viewer.exe'
$Root = Split-Path -Parent $PSScriptRoot
$Bundle = Join-Path $Root "build\windows\x64\runner\Release"

# Version falls back to pubspec.yaml (strip Flutter's "+build" suffix).
if (-not $Version) {
    $match = Select-String -Path (Join-Path $Root 'pubspec.yaml') `
        -Pattern '^version:\s*(\S+)' | Select-Object -First 1
    if (-not $match) {
        throw 'Could not read the version from pubspec.yaml; pass -Version.'
    }
    $Version = ($match.Matches[0].Groups[1].Value -split '\+')[0]
}

if (-not (Test-Path (Join-Path $Bundle $BinName))) {
    throw "Release bundle not found at $Bundle`nBuild it first:  flutter build windows --release"
}

$Pkg = "${App}_${Version}_windows-${Arch}"
$Dist = Join-Path $Root 'dist'
$Stage = Join-Path $Dist $Pkg
$Zip = Join-Path $Dist "$Pkg.zip"

Write-Host "Packaging $App $Version (windows-$Arch)"

if (Test-Path $Stage) { Remove-Item -Recurse -Force $Stage }
New-Item -ItemType Directory -Path $Stage -Force | Out-Null

Copy-Item -Path (Join-Path $Bundle '*') -Destination $Stage -Recurse -Force

foreach ($doc in @('LICENSE', 'README.md', 'BRANDING.md')) {
    $src = Join-Path $Root $doc
    if (Test-Path $src) { Copy-Item -Path $src -Destination $Stage -Force }
}

if (Test-Path $Zip) { Remove-Item -Force $Zip }
Compress-Archive -Path (Join-Path $Stage '*') -DestinationPath $Zip -Force

Write-Host ''
Write-Host "Built: $Zip"
Write-Host "Unzip anywhere and run $BinName."
