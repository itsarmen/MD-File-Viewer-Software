# MD File Viewer
# Author:     Amiran Kimadze (itsarmen)
# GitHub:     https://github.com/itsarmen
# Email:      amoswaper@gmail.com
# Web:        https://xrow.asia
# Build a single-file Windows installer (.exe) with Inno Setup and
# Authenticode-sign it when a code-signing certificate is available.
#
# Usage:
#   flutter build windows --release
#   pwsh -File scripts/build-installer.ps1 [-Version X.Y.Z] [-NoSign]
#                                          [-SignPfx cert.pfx [-SignPfxPassword pw]]
#                                          [-SignThumbprint <thumbprint>]
#
# Output: dist/md-file-viewer_<version>_windows-x64-setup.exe
[CmdletBinding()]
param(
    [string]$Version,
    [switch]$NoSign,
    [string]$SignPfx,
    [string]$SignPfxPassword,
    [string]$SignThumbprint
)

$ErrorActionPreference = 'Stop'

$App = 'md-file-viewer'
$Root = Split-Path -Parent $PSScriptRoot
$Bundle = Join-Path $Root 'build\windows\x64\runner\Release'
$Iss = Join-Path $Root 'windows\installer\md-file-viewer.iss'
$SignScript = Join-Path $PSScriptRoot 'sign-windows.ps1'

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
$AppExe = Join-Path $Bundle 'md_file_viewer.exe'

# Decide whether we can sign: an explicit certificate always signs (and
# fails loudly on error); without one we auto-detect the project's
# self-signed certificate and fall back to an unsigned build.
$CanSign = -not $NoSign
$SignParams = @{}
if ($CanSign) {
    if ($SignPfx) {
        $SignParams.Pfx = $SignPfx
        if ($SignPfxPassword) { $SignParams.PfxPassword = $SignPfxPassword }
    } elseif ($SignThumbprint) {
        $SignParams.Thumbprint = $SignThumbprint
    } else {
        $auto = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert -ErrorAction SilentlyContinue |
            Where-Object { $_.FriendlyName -eq 'MD File Viewer Code Signing' } |
            Select-Object -First 1
        if ($auto) {
            $SignParams.Thumbprint = $auto.Thumbprint
        } else {
            Write-Warning 'No code-signing certificate found; building an unsigned installer.'
            $CanSign = $false
        }
    }
} else {
    Write-Host 'Code signing disabled (-NoSign).'
}

Write-Host "Building $App $Version installer (windows-x64)"

if ($CanSign) {
    # Sign the app binary before it is embedded into the setup EXE.
    & $SignScript -Path $AppExe @SignParams
}

& $Iscc "/DMyAppVersion=$Version" $Iss
if ($LASTEXITCODE -ne 0) {
    throw "ISCC failed with exit code $LASTEXITCODE"
}

if ($CanSign) {
    & $SignScript -Path $Exe @SignParams
}

Write-Host ''
Write-Host "Built: $Exe"