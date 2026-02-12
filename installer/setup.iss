; ADAMV TWEAKS — Inno Setup Installer Script
; Compile with Inno Setup 6: https://jrsoftware.org/isinfo.php
;
; Before compiling:
;   1. Build TweakApp.exe in Release mode
;   2. Run windeployqt on the build output folder
;   3. Point SourceDir below to the deployment folder
;
; Usage:
;   "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\setup.iss

#define MyAppName "ADAMV TWEAKS"
#define MyAppVersion "5.0.0"
#define MyAppPublisher "ADAMV"
#define MyAppURL "https://github.com/pedziito/Tweak"
#define MyAppExeName "TweakApp.exe"

; ── CHANGE THIS to your actual deployment folder ──
; After building, run: windeployqt --release --no-translations --no-opengl-sw TweakApp.exe
; Then point this to that folder:
#define DeployDir "..\deploy"

[Setup]
AppId={{A1D2A3M4-V5T6-W7E8-A9K0-S1E2T3U4P5V6}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputBaseFilename=adamv_tweakingutil_setup
OutputDir=..\dist
SetupIconFile=..\resources\icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Dark modern look
WizardImageFile=compiler:WizModernImage-IS.bmp
WizardSmallImageFile=compiler:WizModernSmallImage-IS.bmp

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "danish"; MessagesFile: "compiler:Languages\Danish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "startupentry"; Description: "Start ADAMV TWEAKS with Windows"; GroupDescription: "Startup:"

[Files]
; Main executable
Source: "{#DeployDir}\TweakApp.exe"; DestDir: "{app}"; Flags: ignoreversion

; All Qt DLLs, plugins, and resources
Source: "{#DeployDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs
Source: "{#DeployDir}\platforms\*"; DestDir: "{app}\platforms"; Flags: ignoreversion recursesubdirs
Source: "{#DeployDir}\styles\*"; DestDir: "{app}\styles"; Flags: ignoreversion recursesubdirs
Source: "{#DeployDir}\tls\*"; DestDir: "{app}\tls"; Flags: ignoreversion recursesubdirs
Source: "{#DeployDir}\imageformats\*"; DestDir: "{app}\imageformats"; Flags: ignoreversion recursesubdirs
Source: "{#DeployDir}\iconengines\*"; DestDir: "{app}\iconengines"; Flags: ignoreversion recursesubdirs
Source: "{#DeployDir}\networkinformation\*"; DestDir: "{app}\networkinformation"; Flags: ignoreversion recursesubdirs
Source: "{#DeployDir}\position\*"; DestDir: "{app}\position"; Flags: ignoreversion recursesubdirs

; QtWebEngine resources
Source: "{#DeployDir}\resources\*"; DestDir: "{app}\resources"; Flags: ignoreversion recursesubdirs
Source: "{#DeployDir}\QtWebEngineProcess.exe"; DestDir: "{app}"; Flags: ignoreversion

; QML modules (if present)
Source: "{#DeployDir}\qml\*"; DestDir: "{app}\qml"; Flags: ignoreversion recursesubdirs skipifsourcedoesntexist
Source: "{#DeployDir}\qmltooling\*"; DestDir: "{app}\qmltooling"; Flags: ignoreversion recursesubdirs skipifsourcedoesntexist

; Translations (if present)
Source: "{#DeployDir}\translations\*"; DestDir: "{app}\translations"; Flags: ignoreversion recursesubdirs skipifsourcedoesntexist

; VC++ Redistributable (include if needed)
Source: "{#DeployDir}\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall skipifsourcedoesntexist

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
; Auto-start with Windows (optional)
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "ADAMV_TWEAKS"; ValueData: """{app}\{#MyAppExeName}"""; Flags: uninsdeletevalue; Tasks: startupentry

[Run]
; Install VC++ Redistributable silently if bundled
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Installing Visual C++ Runtime..."; Flags: waituntilterminated skipifdoesntexist
; Launch after install
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent runascurrentuser

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
// Check if app is running before uninstall
function InitializeUninstall(): Boolean;
var
  ResultCode: Integer;
begin
  Result := True;
  if CheckForMutexes('ADAMV_TWEAKS_MUTEX') then
  begin
    MsgBox('ADAMV TWEAKS is currently running. Please close it before uninstalling.', mbError, MB_OK);
    Result := False;
  end;
end;
