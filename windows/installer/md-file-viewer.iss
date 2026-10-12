; MD File Viewer
; Author:     Amiran Kimadze (itsarmen)
; GitHub:     https://github.com/itsarmen
; Email:      amoswaper@gmail.com
; Web:        https://xrow.asia
;
; Inno Setup script for the Windows installer.
; Build it through scripts/build-installer.ps1, which passes -DMyAppVersion.

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

#ifndef MySourceDir
  #define MySourceDir "..\..\build\windows\x64\runner\Release"
#endif

#define MyAppName "MD File Viewer"
#define MyAppPublisher "Amiran Kimadze (itsarmen)"
#define MyAppURL "https://github.com/itsarmen/MD-File-Viewer-Software"
#define MyAppExeName "md_file_viewer.exe"

[Setup]
AppId={{1F30B288-1D97-4F5F-8D79-00F03619E650}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
AppCopyright=Copyright 2026 Amiran Kimadze (itsarmen)
DefaultDirName={localappdata}\Programs\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
OutputDir=..\..\dist
OutputBaseFilename=md-file-viewer_{#MyAppVersion}_windows-x64-setup
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
LicenseFile=..\..\LICENSE
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} Setup
VersionInfoCopyright=Copyright 2026 Amiran Kimadze (itsarmen)
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#MySourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\..\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\BRANDING.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
; “Open with” and ProgID entries (removed again on uninstall).
Root: HKCU; Subkey: "Software\Classes\Applications\md_file_viewer.exe"; ValueType: string; ValueName: "FriendlyAppName"; ValueData: "{#MyAppName}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\Applications\md_file_viewer.exe\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"",0"
Root: HKCU; Subkey: "Software\Classes\Applications\md_file_viewer.exe\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""
Root: HKCU; Subkey: "Software\Classes\MDFileViewer"; ValueType: string; ValueName: ""; ValueData: "{#MyAppName}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\MDFileViewer\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"",0"
Root: HKCU; Subkey: "Software\Classes\MDFileViewer\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""
; Capabilities so the app is listed under Settings > Default apps.
Root: HKCU; Subkey: "Software\MD File Viewer"; ValueType: none; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\MD File Viewer\Capabilities"; ValueType: string; ValueName: "ApplicationName"; ValueData: "{#MyAppName}"
Root: HKCU; Subkey: "Software\MD File Viewer\Capabilities"; ValueType: string; ValueName: "ApplicationDescription"; ValueData: "View and edit Markdown files."
Root: HKCU; Subkey: "Software\MD File Viewer\Capabilities\FileAssociations"; ValueType: string; ValueName: ".md"; ValueData: "MDFileViewer"
Root: HKCU; Subkey: "Software\RegisteredApplications"; ValueType: string; ValueName: "{#MyAppName}"; ValueData: "Software\MD File Viewer\Capabilities"; Flags: uninsdeletevalue

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent