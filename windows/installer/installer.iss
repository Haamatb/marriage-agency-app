; Inno Setup Script for Marriage & Agency Management Desktop App
#define MyAppName "المكتب الشرعي - إدارة عقود الزواج والوكالات"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Legal Office Software"
#define MyAppExeName "marriage_agency_app.exe"

[Setup]
AppId={{D8A127F9-5C32-4E11-B647-92BA15437890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\MarriageAgencyApp
DisableProgramGroupPage=yes
OutputDir=..\..\build\windows\installer
OutputBaseFilename=MarriageAgencyApp_Setup_v1.0.0
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
