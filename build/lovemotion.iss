; Inno Setup script for LoveMotion Windows installer
[Setup]
AppName=LoveMotion
AppVersion={#MyAppVersion}
DefaultDirName={autopf}\LoveMotion
DefaultGroupName=LoveMotion
UninstallDisplayIcon={app}\LoveMotion.exe
OutputDir=dist_installer
OutputBaseFilename=LoveMotion-Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Files]
Source: "..\dist_win64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\LoveMotion"; Filename: "{app}\LoveMotion.exe"
Name: "{autodesktop}\LoveMotion"; Filename: "{app}\LoveMotion.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Run]
Filename: "{app}\LoveMotion.exe"; Description: "Launch LoveMotion"; Flags: nowait postinstall skipifsilent
