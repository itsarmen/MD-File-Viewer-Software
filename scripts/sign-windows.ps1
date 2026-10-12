# MD File Viewer
# Author:     Amiran Kimadze (itsarmen)
# GitHub:     https://github.com/itsarmen
# Email:      amoswaper@gmail.com
# Web:        https://xrow.asia
# Authenticode-sign one or more files.
#
# Certificate resolution order:
#   1. -Pfx <file.pfx> [-PfxPassword <password>]
#   2. -Thumbprint <cert thumbprint>
#   3. Code-signing certificate in CurrentUser\My with friendly name
#      "MD File Viewer Code Signing" (used automatically).
#
# Usage:
#   pwsh -File scripts/sign-windows.ps1 -Path dist/app.exe
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Path,
    [string]$Pfx,
    [string]$PfxPassword,
    [string]$Thumbprint
)

$ErrorActionPreference = 'Stop'

# Locate signtool.exe (Windows SDK).
$SigntoolPath = $null
$sdkTool = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\signtool.exe" `
    -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1
if ($sdkTool) { $SigntoolPath = $sdkTool.FullName }
if (-not $SigntoolPath) {
    $cmd = Get-Command 'signtool' -ErrorAction SilentlyContinue
    if ($cmd) { $SigntoolPath = $cmd.Source }
}
if (-not $SigntoolPath) {
    throw 'signtool.exe not found. Install the Windows SDK or pass a machine with signtool in PATH.'
}

if ($Pfx) {
    $SignArgs = @('sign', '/f', $Pfx)
    if ($PfxPassword) { $SignArgs += @('/p', $PfxPassword) }
} else {
    if (-not $Thumbprint) {
        $cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert |
            Where-Object { $_.FriendlyName -eq 'MD File Viewer Code Signing' } |
            Select-Object -First 1
        if (-not $cert) {
            throw 'No code-signing certificate found. Pass -Pfx or -Thumbprint, or create one named "MD File Viewer Code Signing".'
        }
        $Thumbprint = $cert.Thumbprint
    }
    $SignArgs = @('sign', '/sha1', $Thumbprint)
}

foreach ($file in $Path) {
    if (-not (Test-Path $file)) { throw "File not found: $file" }
    & $SigntoolPath @SignArgs /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 $file
    if ($LASTEXITCODE -ne 0) { throw "Signing failed: $file" }
    Write-Host "Signed: $file"
}