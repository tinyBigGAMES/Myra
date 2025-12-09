{===============================================================================
  Myra™ - Pascal. Refined.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit UMyra;

interface

procedure RunCLI();

implementation

uses
  WinApi.Windows,
  System.SysUtils,
  System.IOUtils,
  Myra.Compiler,
  Myra.Errors,
  Myra.Utils;

var
  GCompiler: TCompiler;

procedure PrintErrors();
var
  LError: TError;
  LErrorCount: Integer;
  LWarningCount: Integer;
begin
  LErrorCount := 0;
  LWarningCount := 0;

  for LError in GCompiler.Errors.Items do
  begin
    case LError.Severity of
      esWarning:
      begin
        Inc(LWarningCount);
        TUtils.PrintLn(COLOR_YELLOW + '  [WARN] ' + COLOR_RESET + LError.ToIDEString());
      end;
      esError, esFatal:
      begin
        Inc(LErrorCount);
        TUtils.PrintLn(COLOR_RED + '  [ERR]  ' + COLOR_RESET + LError.ToIDEString());
      end;
    end;
  end;

  if (LErrorCount > 0) or (LWarningCount > 0) then
    TUtils.PrintLn(Format('  %d error(s), %d warning(s)', [LErrorCount, LWarningCount]));
end;

procedure ShowBanner();
var
  LVersion: TVersionInfo;
begin
  TUtils.PrintLn(COLOR_CYAN + COLOR_BOLD);

  TUtils.PrintLn('   __  __');
  TUtils.PrintLn('  |  \/  |_  _ _ _ __ _™');
  TUtils.PrintLn('  | |\/| | || | ''_/ _` |');
  TUtils.PrintLn('  |_|  |_|\_, |_| \__,_|');
  TUtils.PrintLn('          |__/');

  TUtils.PrintLn(COLOR_WHITE + '     Pascal. Refined.' + COLOR_RESET);
  TUtils.PrintLn('');
  
  if TUtils.GetVersionInfo(LVersion) then
    TUtils.PrintLn(COLOR_CYAN + 'Version ' + LVersion.VersionString + COLOR_RESET)
  else
    TUtils.PrintLn(COLOR_CYAN + 'Version unknown' + COLOR_RESET);
    
  TUtils.PrintLn('');
end;

procedure ShowHelp();
begin
  ShowBanner();

  TUtils.PrintLn(COLOR_BOLD + 'USAGE:' + COLOR_RESET);
  TUtils.PrintLn('  myra ' + COLOR_CYAN + '<COMMAND>' + COLOR_RESET + ' [OPTIONS]');
  TUtils.PrintLn('');

  TUtils.PrintLn(COLOR_BOLD + 'COMMANDS:' + COLOR_RESET);
  TUtils.PrintLn('  ' + COLOR_GREEN + 'init' + COLOR_RESET + ' <n> [--template <type>]');
  TUtils.PrintLn('                   Create a new Myra project');
  TUtils.PrintLn('                     Templates: exe (default), lib, dll');
  TUtils.PrintLn('  ' + COLOR_GREEN + 'build' + COLOR_RESET + '            Compile Myra source to C++ and build executable');
  TUtils.PrintLn('  ' + COLOR_GREEN + 'run' + COLOR_RESET + '              Execute the compiled program');
  TUtils.PrintLn('  ' + COLOR_GREEN + 'debug' + COLOR_RESET + '            Start interactive debugger for the compiled program');
  TUtils.PrintLn('  ' + COLOR_GREEN + 'clean' + COLOR_RESET + '            Remove all generated files');
  TUtils.PrintLn('  ' + COLOR_GREEN + 'edit' + COLOR_RESET + ' [path]      Open folder in Myra Edit');
  TUtils.PrintLn('  ' + COLOR_GREEN + 'zig' + COLOR_RESET + ' <args>       Pass arguments directly to Zig compiler');
  TUtils.PrintLn('  ' + COLOR_GREEN + 'version' + COLOR_RESET + '          Display version information');
  TUtils.PrintLn('  ' + COLOR_GREEN + 'help' + COLOR_RESET + '             Display this help message');
  TUtils.PrintLn('');

  TUtils.PrintLn(COLOR_BOLD + 'OPTIONS:' + COLOR_RESET);
  TUtils.PrintLn('  -h, --help       Print help information');
  TUtils.PrintLn('  --version        Print version information');
  TUtils.PrintLn('  -t, --template   Specify project template type');
  TUtils.PrintLn('');

  TUtils.PrintLn(COLOR_BOLD + 'TEMPLATE TYPES:' + COLOR_RESET);
  TUtils.PrintLn('  ' + COLOR_CYAN + 'exe' + COLOR_RESET + '          Executable program (default)');
  TUtils.PrintLn('  ' + COLOR_CYAN + 'lib' + COLOR_RESET + '          Static library (.lib on Windows, .a on Linux)');
  TUtils.PrintLn('  ' + COLOR_CYAN + 'dll' + COLOR_RESET + '          Shared library (.dll on Windows, .so on Linux)');
  TUtils.PrintLn('');

  TUtils.PrintLn(COLOR_BOLD + 'EXAMPLES:' + COLOR_RESET);
  TUtils.PrintLn('  ' + COLOR_CYAN + 'myra init MyGame' + COLOR_RESET + '                   - Create an exe project');
  TUtils.PrintLn('  ' + COLOR_CYAN + 'myra init MyLib --template lib' + COLOR_RESET + '     - Create a static library project');
  TUtils.PrintLn('  ' + COLOR_CYAN + 'myra build' + COLOR_RESET + '                         - Build the current project');
  TUtils.PrintLn('  ' + COLOR_CYAN + 'myra run' + COLOR_RESET + '                           - Run the compiled executable');
  TUtils.PrintLn('  ' + COLOR_CYAN + 'myra zig cc -c myfile.c' + COLOR_RESET + '            - Compile C file with Zig');
  TUtils.PrintLn('  ' + COLOR_CYAN + 'myra edit' + COLOR_RESET + '                          - Open current folder in Myra IDE');
  TUtils.PrintLn('');

  TUtils.PrintLn('For more information, visit:');
  TUtils.PrintLn(COLOR_BLUE + '  https://myralang.org' + COLOR_RESET);
  TUtils.PrintLn('');
end;

procedure ShowVersion();
begin
  ShowBanner();
  TUtils.PrintLn('Copyright © 2025-present tinyBigGAMES™ LLC');
  TUtils.PrintLn('All Rights Reserved.');
  TUtils.PrintLn('');
  TUtils.PrintLn('Licensed under Apache 2.0 License');
  TUtils.PrintLn('');
end;

procedure CommandInit();
var
  LProjectName: string;
  LBaseDir: string;
  LTemplate: TTemplateType;
  LTemplateStr: string;
  LIndex: Integer;
begin
  if ParamCount < 2 then
  begin
    TUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + 'Project name required');
    TUtils.PrintLn('');
    TUtils.PrintLn('Usage: ' + COLOR_CYAN + 'myra init <n> [--template <type>]' + COLOR_RESET);
    TUtils.PrintLn('');
    TUtils.PrintLn('Template Types:');
    TUtils.PrintLn('  exe  - Executable program (default)');
    TUtils.PrintLn('  lib  - Static library (.lib/.a)');
    TUtils.PrintLn('  dll  - Shared library (.dll/.so)');
    TUtils.PrintLn('');
    TUtils.PrintLn('Example:');
    TUtils.PrintLn('  myra init MyGame');
    TUtils.PrintLn('  myra init MyLib --template dll');
    TUtils.PrintLn('');
    ExitCode := 2;
    Exit;
  end;

  LProjectName := ParamStr(2);
  LBaseDir := GetCurrentDir() + PathDelim;
  LTemplate := ttEXE; // Default
  
  // Parse optional --template parameter
  LIndex := 3;
  while LIndex <= ParamCount do
  begin
    if ((ParamStr(LIndex) = '--template') or (ParamStr(LIndex) = '-t')) and (LIndex < ParamCount) then
    begin
      Inc(LIndex);
      LTemplateStr := LowerCase(ParamStr(LIndex).Trim());
      
      if LTemplateStr = 'exe' then
        LTemplate := ttEXE
      else if LTemplateStr = 'lib' then
        LTemplate := ttLIB
      else if LTemplateStr = 'dll' then
        LTemplate := ttDll
      else
      begin
        TUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + 'Invalid template type: ' + ParamStr(LIndex));
        TUtils.PrintLn('Valid types: exe, lib, dll');
        TUtils.PrintLn('');
        ExitCode := 2;
        Exit;
      end;
    end;
    Inc(LIndex);
  end;

  TUtils.PrintLn('');
  GCompiler.Init(LProjectName, LBaseDir, LTemplate);
  TUtils.PrintLn('');
  TUtils.PrintLn(COLOR_GREEN + '✓ Project created successfully!' + COLOR_RESET);
  TUtils.PrintLn('');
  TUtils.PrintLn('Next steps:');
  TUtils.PrintLn('  cd %s', [LProjectName]);
  TUtils.PrintLn('  myra edit');
  TUtils.PrintLn('  -- or --');
  TUtils.PrintLn('  myra build');
  TUtils.PrintLn('  myra run');
end;

procedure CommandBuild();
var
  LExitCode: DWORD;
  LBuildSuccess: Boolean;
begin
  TUtils.PrintLn('');
  try
    LBuildSuccess := GCompiler.Build(True, LExitCode);
    TUtils.PrintLn('');
    
    if LBuildSuccess then
      TUtils.PrintLn(COLOR_GREEN + COLOR_BOLD + '✓ Build completed successfully!' + COLOR_RESET)
    else
    begin
      TUtils.PrintLn(COLOR_RED + COLOR_BOLD + '✗ Build failed!' + COLOR_RESET);
      PrintErrors();
      ExitCode := 3;
    end;
  except
    on E: Exception do
    begin
      TUtils.PrintLn('');
      TUtils.PrintLn(COLOR_RED + COLOR_BOLD + '✗ Build failed!' + COLOR_RESET);
      
      if GCompiler.Errors.HasErrors() then
        PrintErrors()
      else
        TUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + E.Message);
      
      TUtils.PrintLn('');
      ExitCode := 3;
    end;
  end;
end;

procedure CommandRun();
var
  LExitCode: DWORD;
  LBuildSuccess: Boolean;
begin
  TUtils.PrintLn('');
  try
    // Build first
    LBuildSuccess := GCompiler.Build(True, LExitCode);
    
    if not LBuildSuccess then
    begin
      TUtils.PrintLn('');
      TUtils.PrintLn(COLOR_RED + COLOR_BOLD + '✗ Build failed!' + COLOR_RESET);
      PrintErrors();
      ExitCode := 3;
      Exit;
    end;
    
    TUtils.PrintLn('');
    TUtils.PrintLn(COLOR_GREEN + COLOR_BOLD + '✓ Build completed successfully!' + COLOR_RESET);
    TUtils.PrintLn('');
    
    // Then run
    if not GCompiler.Run(LExitCode) then
      PrintErrors();
    TUtils.PrintLn('');
  except
    on E: Exception do
    begin
      TUtils.PrintLn('');
      TUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + E.Message);
      TUtils.PrintLn('');
      ExitCode := 1;
    end;
  end;
end;

procedure CommandClean();
begin
  TUtils.PrintLn('');
  try
    GCompiler.Clean();
    TUtils.PrintLn('');
    TUtils.PrintLn(COLOR_GREEN + '✓ Clean completed successfully!' + COLOR_RESET);
    TUtils.PrintLn('');
  except
    on E: Exception do
    begin
      TUtils.PrintLn('');
      TUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + E.Message);
      TUtils.PrintLn('');
      ExitCode := 1;
    end;
  end;
end;

procedure CommandZig();
var
  LArgs: string;
  LI: Integer;
  LZigExe: string;
  LExitCode: Cardinal;
begin
  // Collect all parameters after "zig" command
  LArgs := '';
  for LI := 2 to ParamCount do
  begin
    if LI > 2 then
      LArgs := LArgs + ' ';
    LArgs := LArgs + ParamStr(LI);
  end;

  if LArgs.Trim().IsEmpty then
  begin
    TUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + 'Zig command requires arguments');
    TUtils.PrintLn('');
    TUtils.PrintLn('Usage: ' + COLOR_CYAN + 'myra zig <zig-args>' + COLOR_RESET);
    TUtils.PrintLn('');
    TUtils.PrintLn('Examples:');
    TUtils.PrintLn('  myra zig version');
    TUtils.PrintLn('  myra zig build --help');
    TUtils.PrintLn('  myra zig cc -c myfile.c -o myfile.o');
    TUtils.PrintLn('  myra zig c++ -c myfile.cpp -o myfile.o');
    TUtils.PrintLn('');
    ExitCode := 2;
    Exit;
  end;

  LZigExe := TUtils.GetZigExePath();
  if not TFile.Exists(LZigExe) then
  begin
    TUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + 'Zig executable not found: ' + LZigExe);
    TUtils.PrintLn('');
    ExitCode := 1;
    Exit;
  end;

  TUtils.PrintLn('');
  try
    LExitCode := TUtils.RunExe(LZigExe, LArgs, GetCurrentDir(), True, SW_SHOW);
    ExitCode := LExitCode;
    TUtils.PrintLn('');
  except
    on E: Exception do
    begin
      TUtils.PrintLn('');
      TUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + E.Message);
      TUtils.PrintLn('');
      ExitCode := 1;
    end;
  end;
end;

procedure CommandEdit();
var
  LPath: string;
  LEditExe: string;
  LExeDir: string;
begin
  // Get path argument or default to current directory
  if ParamCount >= 2 then
    LPath := ParamStr(2)
  else
    LPath := GetCurrentDir();

  // Resolve to absolute path
  LPath := TPath.GetFullPath(LPath);

  // Check path exists
  if not TDirectory.Exists(LPath) then
  begin
    TUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + 'Path not found: ' + LPath);
    TUtils.PrintLn('');
    ExitCode := 1;
    Exit;
  end;

  // Myra Edit is in bin/res/edit relative to myra.exe
  LExeDir := TPath.GetDirectoryName(ParamStr(0));
  LEditExe := TPath.Combine(LExeDir, 'res' + PathDelim + 'edit' + PathDelim + 'Edit.exe');

  if not TFile.Exists(LEditExe) then
  begin
    TUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + 'Myra Edit not found: ' + LEditExe);
    TUtils.PrintLn('');
    TUtils.PrintLn('Expected location: bin/res/edit/Edit.exe');
    TUtils.PrintLn('');
    ExitCode := 1;
    Exit;
  end;

  try
    // Spawn Myra Edit with folder path (don't wait)
    TUtils.RunExe(LEditExe, '"' + LPath + '"', LPath, False, SW_SHOW);
  except
    on E: Exception do
    begin
      TUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + E.Message);
      TUtils.PrintLn('');
      ExitCode := 1;
    end;
  end;
end;

procedure CommandDebug();
begin
  TUtils.PrintLn('');
  try
    if not GCompiler.Debug() then
      PrintErrors();
    TUtils.PrintLn('');
  except
    on E: Exception do
    begin
      TUtils.PrintLn('');
      TUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + E.Message);
      TUtils.PrintLn('');
      ExitCode := 1;
    end;
  end;
end;

procedure ProcessCommand();
var
  LCommand: string;
begin
  if ParamCount = 0 then
  begin
    ShowHelp();
    Exit;
  end;

  LCommand := LowerCase(ParamStr(1));

  // Handle flags
  if (LCommand = '-h') or (LCommand = '--help') or (LCommand = 'help') then
  begin
    ShowHelp();
    Exit;
  end;

  if (LCommand = '--version') or (LCommand = 'version') then
  begin
    ShowVersion();
    Exit;
  end;

  // Handle commands
  if LCommand = 'init' then
    CommandInit()
  else if LCommand = 'build' then
    CommandBuild()
  else if LCommand = 'run' then
    CommandRun()
  else if LCommand = 'debug' then
    CommandDebug()
  else if LCommand = 'edit' then
    CommandEdit()
  else if LCommand = 'clean' then
    CommandClean()
  else if LCommand = 'zig' then
    CommandZig()
  else
  begin
    TUtils.PrintLn('');
    TUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + 'Unknown command: ' + COLOR_YELLOW + LCommand + COLOR_RESET);
    TUtils.PrintLn('');
    TUtils.PrintLn('Run ' + COLOR_CYAN + 'myra help' + COLOR_RESET + ' to see available commands');
    TUtils.PrintLn('');
    ExitCode := 2;
  end;
end;

procedure RunCLI();
begin
  ExitCode := 0;
  GCompiler := nil;

  try
    GCompiler := TCompiler.Create();
    try
      ProcessCommand();
    finally
      FreeAndNil(GCompiler);
    end;
  except
    on E: Exception do
    begin
      TUtils.PrintLn('');
      TUtils.PrintLn(COLOR_RED + COLOR_BOLD + 'Fatal Error: ' + COLOR_RESET + E.Message);
      TUtils.PrintLn('');
      ExitCode := 1;
    end;
  end;
end;

end.
