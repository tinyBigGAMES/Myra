{===============================================================================
  Myra™ - Pascal. Refined.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit UTester;

interface

function TestFile(
  const AFilename: string;
  const ARun: Boolean = True;
  const AClean: Boolean = False;
  const AExpectedExitCode: Integer = 0;
  const AQuiet: Boolean = False
): Boolean;

implementation

uses
  WinApi.Windows,
  System.SysUtils,
  System.IOUtils,
  System.Diagnostics,
  Myra.Utils,
  Myra.Errors,
  Myra.Compiler;

const
  { Configuration }
  CProjectDir = '.\output';
  CProjectOutputBinDir = '.\output\out\bin';
  CTestDir = '.\res\tests\';

  { UI Constants }
  CLineWidth = 70;
  CVersion = '1.0.0';

var
  LCompiler: TCompiler;
  LExitCode: DWORD;
  LFilename: string;
  LStopwatch: TStopwatch;
  LBuildSuccess: Boolean;

  procedure PrintHeader(const AQuiet: Boolean);
  begin
    if AQuiet then
      Exit;
    TUtils.PrintLn('');
    TUtils.PrintLn(COLOR_CYAN + '   __  __');
    TUtils.PrintLn(COLOR_CYAN + '  |  \/  |_  _ _ _ __ _');
    TUtils.PrintLn(COLOR_CYAN + '  | |\/| | || | ''_/ _` |');
    TUtils.PrintLn(COLOR_CYAN + '  |_|  |_|\_, |_| \__,_|');
    TUtils.PrintLn(COLOR_CYAN + '          |__/');
    TUtils.PrintLn(COLOR_CYAN + '  Compiler Testbed v' + CVersion);
    TUtils.PrintLn(COLOR_RESET + StringOfChar('=', CLineWidth));
    TUtils.PrintLn('');
  end;

  procedure PrintSection(const ATitle: string; const AQuiet: Boolean);
  begin
    if AQuiet then
      Exit;
    TUtils.PrintLn(COLOR_YELLOW + '[' + ATitle + ']' + COLOR_RESET);
  end;

  procedure PrintInfo(const ALabel: string; const AValue: string; const AQuiet: Boolean);
  begin
    if AQuiet then
      Exit;
    TUtils.PrintLn(COLOR_WHITE + '  ' + ALabel + ': ' + COLOR_RESET + AValue);
  end;

  procedure PrintLine(const AQuiet: Boolean);
  begin
    if AQuiet then
      Exit;
    TUtils.PrintLn(StringOfChar('=', CLineWidth));
  end;

  procedure PrintSuccess(const AElapsedMs: Double; const AQuiet: Boolean);
  begin
    if AQuiet then
      Exit;
    TUtils.PrintLn('');
    TUtils.PrintLn(COLOR_GREEN + '  [OK] SUCCESS' + COLOR_RESET + Format(' (%.3fs)', [AElapsedMs / 1000]));
  end;

  procedure PrintFailure(const AQuiet: Boolean);
  begin
    if AQuiet then
      Exit;
    TUtils.PrintLn(COLOR_RED + '  [X] FAILED' + COLOR_RESET);
  end;

  procedure PrintErrors(const AQuiet: Boolean);
  var
    LError: TError;
    LErrorCount: Integer;
    LWarningCount: Integer;
  begin
    if AQuiet then
      Exit;

    LErrorCount := 0;
    LWarningCount := 0;

    PrintLine(AQuiet);

    for LError in LCompiler.Errors.Items do
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

    PrintLine(AQuiet);
    TUtils.PrintLn(Format('  %d error(s), %d warning(s)', [LErrorCount, LWarningCount]));
  end;

  procedure PrintException(const AException: Exception; const AQuiet: Boolean);
  begin
    if AQuiet then
      Exit;
    PrintLine(AQuiet);
    TUtils.PrintLn(COLOR_RED + '  [EXCEPTION] ' + COLOR_RESET + AException.ClassName);
    TUtils.PrintLn('  ' + AException.Message);
  end;

  function SearchFile(const AFolder: string; const AFileName: string): string;
  var
    LSubFolders: TArray<string>;
    LSubFolder: string;
    LFilePath: string;
  begin
    Result := '';

    // First check in the root folder
    LFilePath := TPath.Combine(AFolder, AFileName);
    if TFile.Exists(LFilePath) then
    begin
      Result := LFilePath;
      Exit;
    end;

    // Get all subfolders
    LSubFolders := TDirectory.GetDirectories(AFolder);

    // Search each subfolder recursively
    for LSubFolder in LSubFolders do
    begin
      Result := SearchFile(LSubFolder, AFileName);
      if Result <> '' then
        Exit;
    end;
  end;

function TestFile(
  const AFilename: string;
  const ARun: Boolean;
  const AClean: Boolean;
  const AExpectedExitCode: Integer;
  const AQuiet: Boolean
): Boolean;
begin
  Result := False;

  PrintHeader(AQuiet);

  // Resolve filename
  LFilename := TPath.ChangeExtension(AFilename, 'myra');
  LFilename := SearchFile(CTestDir, LFilename);

  if LFilename.IsEmpty then
  begin
    if not AQuiet then
      TUtils.PrintLn(COLOR_RED + '  [ERR] File not found: ' + COLOR_RESET + AFilename);
    Exit;
  end;

  // Print source info
  PrintSection('SOURCE', AQuiet);
  PrintInfo('File', ExtractFileName(LFilename), AQuiet);
  PrintInfo('Path', ExtractFilePath(LFilename), AQuiet);
  PrintInfo('Output', CProjectDir, AQuiet);
  if not AQuiet then
    TUtils.PrintLn('');

  LCompiler := TCompiler.Create();
  try
    // Configure compiler
    LCompiler.SetProject(LFilename, CProjectDir);
    LCompiler.AddToSystemPath(CProjectOutputBinDir);

    // Compile phase
    PrintSection('COMPILE', AQuiet);

    LStopwatch := TStopwatch.StartNew();
    LBuildSuccess := False;

    try
      LBuildSuccess := LCompiler.Build(True, LExitCode);
    except
      on E: Exception do
      begin
        PrintFailure(AQuiet);
        PrintException(E, AQuiet);
        if LCompiler.Errors.Count > 0 then
          PrintErrors(AQuiet);
        Exit;
      end;
    end;

    LStopwatch.Stop();

    if LBuildSuccess then
    begin
      PrintSuccess(LStopwatch.ElapsedMilliseconds, AQuiet);
      PrintLine(AQuiet);

      // Run phase
      if ARun then
      begin
        if not AQuiet then
          TUtils.PrintLn('');
        PrintSection('RUN', AQuiet);

        LCompiler.Run(LExitCode);

        PrintInfo('Exit code', IntToStr(LExitCode), AQuiet);
        PrintInfo('Expected', IntToStr(AExpectedExitCode), AQuiet);

        // Check if exit code matches expected
        if Integer(LExitCode) = AExpectedExitCode then
        begin
          Result := True;
        end
        else
        begin
          if not AQuiet then
            TUtils.PrintLn(COLOR_RED + '  [X] Exit code mismatch!' + COLOR_RESET);
        end;
      end
      else
      begin
        // Not running, compile success is enough
        Result := True;
      end;

      // Clean phase
      if AClean then
      begin
        if not AQuiet then
          TUtils.PrintLn('');
        PrintSection('CLEAN', AQuiet);
        LCompiler.Clean();
      end;
    end
    else
    begin
      PrintFailure(AQuiet);
      PrintErrors(AQuiet);
    end;

  finally
    LCompiler.Free();
  end;

  if not AQuiet then
  begin
    TUtils.PrintLn('');
    PrintLine(AQuiet);
  end;
end;

end.
