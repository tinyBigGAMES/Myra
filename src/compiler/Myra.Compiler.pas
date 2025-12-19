{===============================================================================
  Myra™ - Pascal. Refined.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit Myra.Compiler;

{$I Myra.Defines.inc}

interface

uses
  WinAPI.Windows,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.JSON,
  System.Generics.Collections,
  Myra.Utils,
  Myra.Errors,
  Myra.Symbols,
  Myra.AST;

const
  MYRA_MAJOR      = '1';
  MYRA_MINOR      = '0';
  MYRA_PATCH      = '0';
  MYRA_PRERELEASE = '-alpha.2';
  MYRA_VERSION    = MYRA_MAJOR + '.' + MYRA_MINOR + '.' + MYRA_PATCH +
                    MYRA_PRERELEASE;

type
  { TOutputCallback }
  TOutputCallback = reference to procedure(const AText: string);

  { TOptimizationLevel }
  TOptimizationLevel = (
    optDebug,
    optReleaseSafe,
    optReleaseFast,
    optReleaseSmall
  );

  { TTargetPlatform }
  TTargetPlatform = (
    tgtNative,
    tgtX86_64_Windows,
    tgtX86_64_Linux,
    tgtAArch64_MacOS,
    tgtAArch64_Linux,
    tgtWasm32_WASI
  );

  { TApplicationType }
  TApplicationType = (
    atConsole,
    atGUI
  );

  { TABIMode }
  TABIMode = (
    abiC,
    abiCPP
  );

  { TCompilationUnit }
  TCompilationUnit = (
    cuEXE,
    cuDLL,
    cuLIB
  );

  { TTemplateType }
  TTemplateType = (
    ttEXE,
    ttLIB,
    ttDll
  );

  { TSourceBreakpoint }
  TSourceBreakpoint = record
    SourceFile: string;
    LineNumber: Integer;
  end;

  { TCompiler }
  TCompiler = class(TBaseObject)
  private
    FErrors: TErrors;
    FOutputCallback: TOutputCallback;
    FOptimization: TOptimizationLevel;
    FTarget: TTargetPlatform;
    FAppType: TApplicationType;
    FABIMode: TABIMode;
    FSymbols: TSymbolTable;

    FModulePaths: TStringList;
    FIncludePaths: TDictionary<string, Boolean>;
    FLibraryPaths: TDictionary<string, Boolean>;
    FLibraries: TDictionary<string, Boolean>;
    FDefines: TDictionary<string, string>;
    FSourcePaths: TDictionary<string, Boolean>;
    FSourceFiles: TDictionary<string, Boolean>;
    FIncludeHeaders: TDictionary<string, Boolean>;
    FProcessedFiles: TDictionary<string, string>;
    FBreakpoints: TList<TSourceBreakpoint>;
    FModules: TObjectDictionary<string, TModuleNode>;

    FProjectName: string;
    FProjectDir: string;
    FProjectGenPath: string;
    FProjectMainSourceFile: string;
    FCompilationUnit: TCompilationUnit;

    FEnableExceptions: Boolean;
    FEnableRTTI: Boolean;
    FUnitTestMode: Boolean;

    function GenerateBuildZig(): Boolean;
    function ValidateLibraries(): Boolean;
    function IsBuildAnExecutable(): Boolean;
    function GetBuildTarget(): TTargetPlatform;
    function ExecuteBuild(var AExitCode: DWORD): Boolean;
    function TranspileFile(const AFilename: string; const AIsMain: Boolean): Boolean;
    function AnalyzeFile(const AFilename: string; const AIsMain: Boolean): Boolean;
    procedure ShowCompiled(const AFilename: string);

  public
    constructor Create(); override;
    destructor Destroy(); override;

    function AddToSystemPath(const APath: string): Boolean;

    function GetProjectDir(): string;
    procedure SetProjectDir(const AValue: string);

    function GetProjectName(): string;
    procedure SetProjectName(const AName: string);

    function SetProject(const AMainSourceFile: string; const AProjectDir: string): Boolean;

    function GetProjectGenPath(): string;

    function GetCompilationUnit(): TCompilationUnit;
    procedure SetCompilationUnit(const AValue: TCompilationUnit);

    procedure SetOptimization(const ALevel: TOptimizationLevel);
    function GetOptimization(): TOptimizationLevel;

    function GetTarget(): TTargetPlatform;
    procedure SetTarget(const ATarget: TTargetPlatform);

    function GetAppType(): TApplicationType;
    procedure SetAppType(const AAppType: TApplicationType);

    function GetABIMode(): TABIMode;
    procedure SetABIMode(const AMode: TABIMode);

    procedure AddModulePath(const APath: string);
    function GetModulePaths(): TArray<string>;

    procedure AddIncludePath(const APath: string);
    function GetIncludePaths(): TArray<string>;

    function GetLibraryPaths(): TArray<string>;
    procedure AddLibraryPath(const APath: string);

    procedure AddLibrary(const ALibrary: string);
    function GetLibraries(): TArray<string>;

    procedure SetEnableExceptions(const AEnable: Boolean);
    function GetEnableExceptions(): Boolean;
    procedure SetEnableRTTI(const AEnable: Boolean);
    function GetEnableRTTI(): Boolean;

    procedure SetUnitTestMode(const AEnabled: Boolean);
    function GetUnitTestMode(): Boolean;

    procedure ClearProcessedFiles();
    function GetProcessedFiles(): TArray<string>;

    procedure AddSourcePath(const APath: string);
    procedure ClearSourcePaths();
    function GetSourcePaths(): TArray<string>;

    procedure AddIncludeHeader(const AHeader: string);
    procedure ClearIncludeHeaders();
    function GetIncludeHeaders(): TArray<string>;

    function GetOutputCallback(): TOutputCallback;
    procedure SetOutputCallback(const AValue: TOutputCallback);
    procedure Output(const AText: string; const AArgs: array of const; const ALinefeed: Boolean = True);

    procedure Undefine(const ASymbol: string);
    procedure SetDefine(const ASymbol: string; const AValue: string);
    function GetDefines(): TArray<TPair<string, string>>;

    procedure AddSourceFile(const AFilename: string);
    procedure ClearSourceFiles();
    function GetSourceFiles(): TArray<string>;

    procedure AddBreakpoint(const AFile: string; const ALine: Integer);
    function GetBreakpoints(): TArray<TSourceBreakpoint>;
    procedure SaveBreakpointsToFile(const AOutputPath: string);
    procedure ClearBreakpoints();

    procedure Init(const AProjectName: string; const ABaseDir: string; const ATemplate: TTemplateType);
    {$HINTS OFF}
    function Analyze(): Boolean;
    {$HINTS ON}
    function Build(const ACompileOnly: Boolean; var AExitCode: DWORD): Boolean;
    function Run(var AExitCode: DWORD; const ACaptureOutput: Boolean = False): Boolean;
    function Clean(): Boolean;
    function Debug(): Boolean;

    property Errors: TErrors read FErrors;
    property Symbols: TSymbolTable read FSymbols;
    property Modules: TObjectDictionary<string, TModuleNode> read FModules;
  end;

implementation

uses
  Myra.Token,
  Myra.Lexer,
  Myra.Parser,
  Myra.Semantic,
  Myra.CodeGen,
  Myra.Debug,
  Myra.Debug.REPL;

const
  TEMPLATE_EXE =
  '''
  (*
    %s - Myra EXE
  *)

  module exe %s;

  import
    Console;

  begin
    Console.PrintLn('Hello from Myra!');
  end.
  ''';

  TEMPLATE_LIB =
  '''
  (*
    %s - Myra LIB
  *)

  module lib %s;

  public routine LibAdd(const A: INTEGER; const B: INTEGER): INTEGER;
  begin
    return A + B;
  end;

  public routine LibMultiply(const A: INTEGER; const B: INTEGER): INTEGER;
  begin
    return A * B;
  end;

  end.
  ''';

  TEMPLATE_DLL =
  '''
  (*
    %s - Myra DLL
  *)

  module dll %s;

  #ABI C
  public routine LibAdd(const A: INTEGER; const B: INTEGER): INTEGER; cdecl;
  begin
    return A + B;
  end;

  #ABI CPP
  public routine LibMultiply(const A: INTEGER; const B: INTEGER): INTEGER; stdcall;
  begin
    return A * B;
  end;

  end.
  ''';

{ TCompiler }

constructor TCompiler.Create();
begin
  inherited Create();

  FErrors := TErrors.Create();
  FSymbols := TSymbolTable.Create();

  FModulePaths := TStringList.Create();
  FModulePaths.Delimiter := ';';
  FModulePaths.StrictDelimiter := True;

  FIncludePaths := TDictionary<string, Boolean>.Create();
  FLibraryPaths := TDictionary<string, Boolean>.Create();
  FLibraries := TDictionary<string, Boolean>.Create();
  FDefines := TDictionary<string, string>.Create();
  FSourcePaths := TDictionary<string, Boolean>.Create();
  FSourceFiles := TDictionary<string, Boolean>.Create();
  FIncludeHeaders := TDictionary<string, Boolean>.Create();
  FProcessedFiles := TDictionary<string, string>.Create();
  FBreakpoints := TList<TSourceBreakpoint>.Create();
  FModules := TObjectDictionary<string, TModuleNode>.Create([doOwnsValues]);

  FProjectDir := '';
  FProjectGenPath := '';
  FEnableRTTI := True;
  FEnableExceptions := True;

  // Set default defines
  SetDefine('MYRA', '1');
  SetOptimization(optDebug);
  SetTarget(tgtNative);
  SetAppType(atConsole);
  SetABIMode(abiCPP);

  // Add standard library path to module paths
  (*
  AddModulePath('.\res\libs\std');

  AddIncludePath('.\res\runtime');
  AddSourcePath('.\res\runtime');
  AddSourceFile('.\res\runtime\myra_runtime.cpp');

  AddIncludePath('.\res\libs\raylib\include');
  AddLibraryPath('.\res\libs\raylib\lib');
  *)
end;

destructor TCompiler.Destroy();
begin
  FModules.Free();
  FBreakpoints.Free();
  FProcessedFiles.Free();
  FIncludeHeaders.Free();
  FSourceFiles.Free();
  FSourcePaths.Free();
  FDefines.Free();
  FLibraries.Free();
  FLibraryPaths.Free();
  FIncludePaths.Free();
  FModulePaths.Free();
  FSymbols.Free();
  FErrors.Free();

  inherited Destroy();
end;

function TCompiler.GetProjectDir(): string;
begin
  Result := FProjectDir;
end;

procedure TCompiler.SetProjectDir(const AValue: string);
begin
  FProjectDir := AValue;
  FProjectGenPath := TPath.Combine(FProjectDir, 'generated');
end;

function TCompiler.GetProjectName(): string;
begin
  Result := FProjectName;
end;

procedure TCompiler.SetProjectName(const AName: string);
var
  LName: string;
begin
  LName := AName.Trim();
  if LName.Contains('.') then
    FProjectName := TPath.GetFileNameWithoutExtension(LName)
  else
    FProjectName := LName;
end;

function TCompiler.SetProject(const AMainSourceFile: string; const AProjectDir: string): Boolean;
begin
  Result := False;
  if not TFile.Exists(AMainSourceFile) then
    Exit;

  FProjectMainSourceFile := AMainSourceFile;
  SetProjectName(AMainSourceFile);
  SetProjectDir(AProjectDir);

  Result := True;
end;

function TCompiler.GetProjectGenPath(): string;
begin
  Result := FProjectGenPath;
end;

function TCompiler.GetCompilationUnit(): TCompilationUnit;
begin
  Result := FCompilationUnit;
end;

procedure TCompiler.SetCompilationUnit(const AValue: TCompilationUnit);
begin
  FCompilationUnit := AValue;
end;

function TCompiler.GetOptimization(): TOptimizationLevel;
begin
  Result := FOptimization;
end;

procedure TCompiler.SetOptimization(const ALevel: TOptimizationLevel);
begin
  FOptimization := ALevel;

  Undefine('DEBUG');
  Undefine('RELEASE');
  Undefine('OPTIMIZATION_DEBUG');
  Undefine('OPTIMIZATION_RELEASESAFE');
  Undefine('OPTIMIZATION_RELEASEFAST');
  Undefine('OPTIMIZATION_RELEASESMALL');

  case ALevel of
    optDebug:
      begin
        SetDefine('OPTIMIZATION_LEVEL', '0');
        SetDefine('OPTIMIZATION_DEBUG', '1');
        SetDefine('DEBUG', '1');
      end;
    optReleaseSafe:
      begin
        SetDefine('OPTIMIZATION_LEVEL', '1');
        SetDefine('OPTIMIZATION_RELEASESAFE', '1');
        SetDefine('RELEASE', '1');
      end;
    optReleaseFast:
      begin
        SetDefine('OPTIMIZATION_LEVEL', '2');
        SetDefine('OPTIMIZATION_RELEASEFAST', '1');
        SetDefine('RELEASE', '1');
      end;
    optReleaseSmall:
      begin
        SetDefine('OPTIMIZATION_LEVEL', '3');
        SetDefine('OPTIMIZATION_RELEASESMALL', '1');
        SetDefine('RELEASE', '1');
      end;
  end;
end;

function TCompiler.GetTarget(): TTargetPlatform;
begin
  Result := FTarget;
end;

procedure TCompiler.SetTarget(const ATarget: TTargetPlatform);
begin
  FTarget := ATarget;

  Undefine('CPUX64');
  Undefine('CPU386');
  Undefine('CPUARM64');
  Undefine('ARM64');
  Undefine('WIN64');
  Undefine('WIN32');
  Undefine('MSWINDOWS');
  Undefine('WINDOWS');
  Undefine('LINUX');
  Undefine('MACOS');
  Undefine('DARWIN');
  Undefine('POSIX');
  Undefine('UNIX');
  Undefine('TARGET_NATIVE');
  Undefine('TARGET_X86_64_WINDOWS');
  Undefine('TARGET_X86_64_LINUX');
  Undefine('TARGET_AARCH64_MACOS');
  Undefine('TARGET_AARCH64_LINUX');
  Undefine('TARGET_WASM32_WASI');

  case ATarget of
    tgtNative:
      begin
        SetDefine('TARGET_NATIVE', '1');
        {$IFDEF MSWINDOWS}
          {$IFDEF CPUX64}
            SetDefine('TARGET_X86_64_WINDOWS', '1');
            SetDefine('CPUX64', '1');
            SetDefine('WIN64', '1');
            SetDefine('MSWINDOWS', '1');
            SetDefine('WINDOWS', '1');
          {$ENDIF}
        {$ENDIF}
        {$IFDEF LINUX}
          {$IFDEF CPUX64}
            SetDefine('CPUX64', '1');
            SetDefine('LINUX', '1');
            SetDefine('POSIX', '1');
            SetDefine('UNIX', '1');
          {$ENDIF}
        {$ENDIF}
        {$IFDEF MACOS}
          {$IFDEF CPUARM64}
            SetDefine('CPUARM64', '1');
            SetDefine('ARM64', '1');
            SetDefine('MACOS', '1');
            SetDefine('DARWIN', '1');
            SetDefine('POSIX', '1');
            SetDefine('UNIX', '1');
          {$ENDIF}
        {$ENDIF}
      end;
    tgtX86_64_Windows:
      begin
        SetDefine('TARGET_X86_64_WINDOWS', '1');
        SetDefine('CPUX64', '1');
        SetDefine('WIN64', '1');
        SetDefine('MSWINDOWS', '1');
        SetDefine('WINDOWS', '1');
      end;
    tgtX86_64_Linux:
      begin
        SetDefine('TARGET_X86_64_LINUX', '1');
        SetDefine('CPUX64', '1');
        SetDefine('LINUX', '1');
        SetDefine('POSIX', '1');
        SetDefine('UNIX', '1');
      end;
    tgtAArch64_MacOS:
      begin
        SetDefine('TARGET_AARCH64_MACOS', '1');
        SetDefine('CPUARM64', '1');
        SetDefine('ARM64', '1');
        SetDefine('MACOS', '1');
        SetDefine('DARWIN', '1');
        SetDefine('POSIX', '1');
        SetDefine('UNIX', '1');
      end;
    tgtAArch64_Linux:
      begin
        SetDefine('TARGET_AARCH64_LINUX', '1');
        SetDefine('CPUARM64', '1');
        SetDefine('ARM64', '1');
        SetDefine('LINUX', '1');
        SetDefine('POSIX', '1');
        SetDefine('UNIX', '1');
      end;
    tgtWasm32_WASI:
      begin
        SetDefine('TARGET_WASM32_WASI', '1');
      end;
  end;
end;

function TCompiler.GetAppType(): TApplicationType;
begin
  Result := FAppType;
end;

procedure TCompiler.SetAppType(const AAppType: TApplicationType);
begin
  FAppType := AAppType;

  Undefine('CONSOLE_APP');
  Undefine('GUI_APP');
  Undefine('APPTYPE_CONSOLE');
  Undefine('APPTYPE_GUI');

  case AAppType of
    atConsole:
      begin
        SetDefine('APPTYPE_CONSOLE', '1');
        SetDefine('CONSOLE_APP', '1');
      end;
    atGUI:
      begin
        SetDefine('APPTYPE_GUI', '1');
        SetDefine('GUI_APP', '1');
      end;
  end;
end;

function TCompiler.GetABIMode(): TABIMode;
begin
  Result := FABIMode;
end;

procedure TCompiler.SetABIMode(const AMode: TABIMode);
begin
  FABIMode := AMode;

  Undefine('ABI_C');
  Undefine('ABI_CPP');

  case AMode of
    abiC:
      SetDefine('ABI_C', '1');
    abiCPP:
      SetDefine('ABI_CPP', '1');
  end;
end;

procedure TCompiler.AddModulePath(const APath: string);
begin
  if APath <> '' then
    FModulePaths.Add(APath);
end;

function TCompiler.GetModulePaths(): TArray<string>;
begin
  Result := FModulePaths.ToStringArray();
end;

procedure TCompiler.AddIncludePath(const APath: string);
begin
  if APath <> '' then
    FIncludePaths.AddOrSetValue(APath, True);
end;

function TCompiler.GetIncludePaths(): TArray<string>;
begin
  Result := FIncludePaths.Keys.ToArray();
end;

function TCompiler.GetLibraryPaths(): TArray<string>;
begin
  Result := FLibraryPaths.Keys.ToArray();
end;

procedure TCompiler.AddLibraryPath(const APath: string);
begin
  if APath <> '' then
    FLibraryPaths.AddOrSetValue(APath, True);
end;

procedure TCompiler.AddLibrary(const ALibrary: string);
begin
  if ALibrary <> '' then
    FLibraries.AddOrSetValue(ALibrary, True);
end;

function TCompiler.GetLibraries(): TArray<string>;
begin
  Result := FLibraries.Keys.ToArray();
end;

procedure TCompiler.SetEnableExceptions(const AEnable: Boolean);
begin
  FEnableExceptions := AEnable;
end;

function TCompiler.GetEnableExceptions(): Boolean;
begin
  Result := FEnableExceptions;
end;

procedure TCompiler.SetEnableRTTI(const AEnable: Boolean);
begin
  FEnableRTTI := AEnable;
end;

function TCompiler.GetEnableRTTI(): Boolean;
begin
  Result := FEnableRTTI;
end;

procedure TCompiler.SetUnitTestMode(const AEnabled: Boolean);
begin
  FUnitTestMode := AEnabled;
  if AEnabled then
    SetDefine('MYRA_UNITTESTING', '1')
  else
    Undefine('MYRA_UNITTESTING');
end;

function TCompiler.GetUnitTestMode(): Boolean;
begin
  Result := FUnitTestMode;
end;

procedure TCompiler.ClearProcessedFiles();
begin
  FProcessedFiles.Clear();
  FModules.Clear();
end;

function TCompiler.GetProcessedFiles(): TArray<string>;
begin
  Result := FProcessedFiles.Values.ToArray();
end;

procedure TCompiler.AddSourcePath(const APath: string);
begin
  if APath <> '' then
    FSourcePaths.AddOrSetValue(APath, True);
end;

procedure TCompiler.ClearSourcePaths();
begin
  FSourcePaths.Clear();
end;

function TCompiler.GetSourcePaths(): TArray<string>;
begin
  Result := FSourcePaths.Keys.ToArray();
end;

procedure TCompiler.AddSourceFile(const AFilename: string);
begin
  if AFilename <> '' then
    FSourceFiles.TryAdd(AFilename, True);
end;

procedure TCompiler.ClearSourceFiles();
begin
  FSourceFiles.Clear();
end;

function TCompiler.GetSourceFiles(): TArray<string>;
begin
  Result := FSourceFiles.Keys.ToArray();
end;

procedure TCompiler.AddIncludeHeader(const AHeader: string);
begin
  if AHeader <> '' then
    FIncludeHeaders.AddOrSetValue(AHeader, True);
end;

procedure TCompiler.ClearIncludeHeaders();
begin
  FIncludeHeaders.Clear();
end;

function TCompiler.GetIncludeHeaders(): TArray<string>;
begin
  Result := FIncludeHeaders.Keys.ToArray();
end;

procedure TCompiler.AddBreakpoint(const AFile: string; const ALine: Integer);
var
  LBP: TSourceBreakpoint;
begin
  LBP.SourceFile := AFile;
  LBP.LineNumber := ALine;
  FBreakpoints.Add(LBP);
end;

function TCompiler.GetBreakpoints(): TArray<TSourceBreakpoint>;
begin
  Result := FBreakpoints.ToArray();
end;

procedure TCompiler.ClearBreakpoints();
begin
  FBreakpoints.Clear();
end;

procedure TCompiler.SaveBreakpointsToFile(const AOutputPath: string);
var
  LJson: TJSONObject;
  LArray: TJSONArray;
  LBP: TSourceBreakpoint;
  LItem: TJSONObject;
  LFilePath: string;
begin
  if FBreakpoints.Count = 0 then
    Exit;

  LJson := TJSONObject.Create();
  try
    LJson.AddPair('version', '1.0');

    LArray := TJSONArray.Create();
    for LBP in FBreakpoints do
    begin
      LItem := TJSONObject.Create();
      LItem.AddPair('file', LBP.SourceFile);
      LItem.AddPair('line', TJSONNumber.Create(LBP.LineNumber));
      LArray.Add(LItem);
    end;

    LJson.AddPair('breakpoints', LArray);

    LFilePath := TPath.ChangeExtension(AOutputPath, '.breakpoints');
    TFile.WriteAllText(LFilePath, LJson.Format(2));

    Output('Saved %d breakpoint(s) to: %s', [FBreakpoints.Count, ExtractFileName(LFilePath)]);
  finally
    LJson.Free();
  end;
end;

function TCompiler.AddToSystemPath(const APath: string): Boolean;
var
  LFull: string;
  LPath: string;
begin
  Result := False;

  LFull := ExpandFileName(APath);
  if not DirectoryExists(LFull) then
    Exit;

  LPath := GetEnvironmentVariable('PATH');
  if LPath = '' then
    LPath := LFull
  else
  begin
    if LPath.EndsWith(';') then
      LPath := LPath + LFull
    else
      LPath := LPath + ';' + LFull;
  end;

  Result := SetEnvironmentVariable('PATH', PChar(LPath));
end;

function TCompiler.GetOutputCallback(): TOutputCallback;
begin
  Result := FOutputCallback;
end;

procedure TCompiler.SetOutputCallback(const AValue: TOutputCallback);
begin
  FOutputCallback := AValue;
end;

procedure TCompiler.Output(const AText: string; const AArgs: array of const; const ALinefeed: Boolean);
var
  LText: string;
begin
  LText := Format(AText, AArgs);

  if ALinefeed then
    LText := LText + sLineBreak;

  if Assigned(FOutputCallback) then
    FOutputCallback(LText)
  else
    TUtils.Print(LText);
end;

procedure TCompiler.Undefine(const ASymbol: string);
begin
  FDefines.Remove(ASymbol);
end;

procedure TCompiler.SetDefine(const ASymbol: string; const AValue: string);
begin
  FDefines.AddOrSetValue(ASymbol, AValue);
end;

function TCompiler.GetDefines(): TArray<TPair<string, string>>;
begin
  Result := FDefines.ToArray();
end;

function TCompiler.GenerateBuildZig(): Boolean;
var
  LBuildZigPath: string;
  LBuilder: TStringBuilder;
  LPath: string;
  LLibrary: string;
  LOptimizeMode: string;
  LTargetParts: TArray<string>;
  LArch: string;
  LOS: string;
  LABI: string;
  LFiles: TArray<string>;
  LFile: string;
  LLibraryPathsArray: TArray<string>;
  LExeDir: string;
  LExpandedPath: string;
  LTargetStr: string;
  LDefines: TArray<TPair<string, string>>;
  LDefine: TPair<string, string>;

  function MakeRelativePath(const ABasePath: string; const ATargetPath: string): string;
  var
    LBase: string;
    LTarget: string;
    LBaseParts: TArray<string>;
    LTargetParts: TArray<string>;
    LCommonCount: Integer;
    LI: Integer;
    LRelativeParts: TList<string>;

    function NormalizePath(const APath: string): string;
    begin
      Result := StringReplace(APath, '\', '/', [rfReplaceAll]);
    end;

  begin
    LBase := NormalizePath(TPath.GetFullPath(ABasePath));
    LTarget := NormalizePath(TPath.GetFullPath(ATargetPath));

    if SameText(LBase, LTarget) then
      Exit('.');

    LBaseParts := LBase.Split(['/']);
    LTargetParts := LTarget.Split(['/']);

    LCommonCount := 0;
    while (LCommonCount < Length(LBaseParts)) and
          (LCommonCount < Length(LTargetParts)) and
          SameText(LBaseParts[LCommonCount], LTargetParts[LCommonCount]) do
      Inc(LCommonCount);

    LRelativeParts := TList<string>.Create();
    try
      for LI := LCommonCount to High(LBaseParts) do
        LRelativeParts.Add('..');

      for LI := LCommonCount to High(LTargetParts) do
        LRelativeParts.Add(LTargetParts[LI]);

      Result := string.Join('/', LRelativeParts.ToArray());
    finally
      LRelativeParts.Free();
    end;
  end;

begin
  Result := False;

  if FProjectDir.IsEmpty then
    Exit;

  if FProjectName.IsEmpty then
    Exit;

  if FSourceFiles.Count = 0 then
    Exit;

  LExeDir := TPath.GetDirectoryName(ParamStr(0));

  LBuilder := TStringBuilder.Create();
  try
    case GetOptimization() of
      optDebug:        LOptimizeMode := 'Debug';
      optReleaseSafe:  LOptimizeMode := 'ReleaseSafe';
      optReleaseFast:  LOptimizeMode := 'ReleaseFast';
      optReleaseSmall: LOptimizeMode := 'ReleaseSmall';
    end;

    LLibraryPathsArray := GetLibraryPaths();

    LBuilder.AppendLine('const std = @import("std");');
    LBuilder.AppendLine('');
    LBuilder.AppendLine('pub fn build(b: *std.Build) void {');

    case GetTarget() of
      tgtNative:
        LTargetStr := 'native';
      tgtX86_64_Windows:
        LTargetStr := 'x86_64-windows';
      tgtX86_64_Linux:
        LTargetStr := 'x86_64-linux';
      tgtAArch64_MacOS:
        LTargetStr := 'aarch64-macos';
      tgtAArch64_Linux:
        LTargetStr := 'aarch64-linux';
      tgtWasm32_WASI:
        LTargetStr := 'wasm32-wasi';
    else
      LTargetStr := 'native';
    end;

    if LTargetStr.IsEmpty() or (LTargetStr.ToLower() = 'native') then
    begin
      LBuilder.AppendLine('    const target = b.standardTargetOptions(.{});');
    end
    else
    begin
      LTargetParts := LTargetStr.Split(['-']);

      LArch := LTargetParts[0];
      LOS := '';
      LABI := '';

      if Length(LTargetParts) >= 2 then
        LOS := LTargetParts[1];
      if Length(LTargetParts) >= 3 then
        LABI := LTargetParts[2];

      LBuilder.AppendLine('    const target = b.resolveTargetQuery(.{');
      LBuilder.AppendLine('        .cpu_arch = .' + LArch + ',');
      if not LOS.IsEmpty then
        LBuilder.AppendLine('        .os_tag = .' + LOS + ',');
      if not LABI.IsEmpty then
        LBuilder.AppendLine('        .abi = .' + LABI + ',');
      LBuilder.AppendLine('    });');
    end;

    LBuilder.AppendLine('    const optimize = .' + LOptimizeMode + ';');
    LBuilder.AppendLine('');

    LBuilder.AppendLine('    // Create module for C++ sources');
    LBuilder.AppendLine('    const module = b.addModule("' + FProjectName + '", .{');
    LBuilder.AppendLine('        .target = target,');
    LBuilder.AppendLine('        .optimize = optimize,');
    LBuilder.AppendLine('        .link_libc = true,');
    LBuilder.AppendLine('    });');
    LBuilder.AppendLine('');

    LBuilder.AppendLine('    // C++ compiler flags');
    LBuilder.AppendLine('    const cpp_flags = [_][]const u8{');
    LBuilder.AppendLine('        "-std=c++23",');
    if not FEnableExceptions then
      LBuilder.AppendLine('        "-fno-exceptions",');
    if not FEnableRTTI then
      LBuilder.AppendLine('        "-fno-rtti",');
    LBuilder.AppendLine('    };');
    LBuilder.AppendLine('');

    LFiles := FSourceFiles.Keys.ToArray();
    if Length(LFiles) > 0 then
    begin
      LBuilder.AppendLine('    // Add registered C++ source files');
      for LFile in LFiles do
      begin
        // Expand relative paths from exe location
        if not TPath.IsPathRooted(LFile) then
          LExpandedPath := TPath.GetFullPath(TPath.Combine(LExeDir, LFile))
        else
          LExpandedPath := LFile;

        LBuilder.AppendLine('    module.addCSourceFile(.{');
        LBuilder.AppendLine('        .file = b.path("' + MakeRelativePath(FProjectDir, LExpandedPath) + '"),');
        LBuilder.AppendLine('        .flags = &cpp_flags,');
        LBuilder.AppendLine('    });');
      end;
      LBuilder.AppendLine('');
    end;

    for LPath in GetIncludePaths() do
    begin
      if not TPath.IsPathRooted(LPath) then
        LExpandedPath := TPath.GetFullPath(TPath.Combine(LExeDir, LPath))
      else
        LExpandedPath := LPath;

      LBuilder.AppendLine('    module.addIncludePath(b.path("' +
        MakeRelativePath(FProjectDir, LExpandedPath) + '"));');
    end;
    if Length(GetIncludePaths()) > 0 then
      LBuilder.AppendLine('');

    case FCompilationUnit of
      cuEXE:
        begin
          LBuilder.AppendLine('    // Create executable');
          LBuilder.AppendLine('    const exe = b.addExecutable(.{');
          LBuilder.AppendLine('        .name = "' + FProjectName + '",');
          LBuilder.AppendLine('        .root_module = module,');
          LBuilder.AppendLine('    });');

          if GetAppType() = atGUI then
          begin
            LBuilder.AppendLine('');
            LBuilder.AppendLine('    // Set GUI subsystem (no console window)');
            LBuilder.AppendLine('    if (target.result.os.tag == .windows) {');
            LBuilder.AppendLine('        exe.subsystem = .Windows;');
            LBuilder.AppendLine('    }');
          end;
        end;

      cuDLL:
        begin
          LBuilder.AppendLine('    // Create shared library');
          LBuilder.AppendLine('    const lib = b.addLibrary(.{');
          LBuilder.AppendLine('        .linkage = .dynamic,');
          LBuilder.AppendLine('        .name = "' + FProjectName + '",');
          LBuilder.AppendLine('        .root_module = module,');
          LBuilder.AppendLine('    });');
        end;

      cuLIB:
        begin
          LBuilder.AppendLine('    // Create static library');
          LBuilder.AppendLine('    const lib = b.addLibrary(.{');
          LBuilder.AppendLine('        .linkage = .static,');
          LBuilder.AppendLine('        .name = "' + FProjectName + '",');
          LBuilder.AppendLine('        .root_module = module,');
          LBuilder.AppendLine('    });');
        end;
    end;
    LBuilder.AppendLine('');

    case FCompilationUnit of
      cuEXE:
        begin
          LBuilder.AppendLine('    // Link C++ standard library');
          LBuilder.AppendLine('    exe.linkLibCpp();');
        end;
      cuDLL, cuLIB:
        begin
          LBuilder.AppendLine('    // Link C++ standard library');
          LBuilder.AppendLine('    lib.linkLibCpp();');
        end;
    end;
    LBuilder.AppendLine('');

    case FCompilationUnit of
      cuEXE:
        begin
          for LPath in LLibraryPathsArray do
          begin
            if not TPath.IsPathRooted(LPath) then
              LExpandedPath := TPath.GetFullPath(TPath.Combine(LExeDir, LPath))
            else
              LExpandedPath := LPath;

            LBuilder.AppendLine('    exe.addLibraryPath(b.path("' +
              MakeRelativePath(FProjectDir, LExpandedPath) + '"));');
          end;
        end;
      cuDLL, cuLIB:
        begin
          for LPath in LLibraryPathsArray do
          begin
            if not TPath.IsPathRooted(LPath) then
              LExpandedPath := TPath.GetFullPath(TPath.Combine(LExeDir, LPath))
            else
              LExpandedPath := LPath;

            LBuilder.AppendLine('    lib.addLibraryPath(b.path("' +
              MakeRelativePath(FProjectDir, LExpandedPath) + '"));');
          end;
        end;
    end;
    if Length(LLibraryPathsArray) > 0 then
      LBuilder.AppendLine('');

    case FCompilationUnit of
      cuEXE:
        begin
          for LLibrary in GetLibraries() do
            LBuilder.AppendLine('    exe.linkSystemLibrary("' + LLibrary + '");');
        end;
      cuDLL, cuLIB:
        begin
          for LLibrary in GetLibraries() do
            LBuilder.AppendLine('    lib.linkSystemLibrary("' + LLibrary + '");');
        end;
    end;
    if Length(GetLibraries()) > 0 then
      LBuilder.AppendLine('');

    LDefines := GetDefines();
    if Length(LDefines) > 0 then
    begin
      LBuilder.AppendLine('');
      LBuilder.AppendLine('    // Preprocessor defines');
      for LDefine in LDefines do
        LBuilder.AppendLine('    module.addCMacro("' + LDefine.Key + '", "' + LDefine.Value + '");');
    end;

    case FCompilationUnit of
      cuEXE:
        LBuilder.AppendLine('    b.installArtifact(exe);');
      cuDLL, cuLIB:
        LBuilder.AppendLine('    b.installArtifact(lib);');
    end;
    LBuilder.AppendLine('}');

    LBuildZigPath := TPath.Combine(FProjectDir, 'build.zig');
    TFile.WriteAllText(LBuildZigPath, LBuilder.ToString());

    Result := True;

  finally
    LBuilder.Free();
  end;
end;

function TCompiler.ValidateLibraries(): Boolean;
var
  LLibrary: string;
  LHandle: HMODULE;
  LLowerLib: string;
  LIsStaticLib: Boolean;
  LPath: string;
  LFullPath: string;
  LFound: Boolean;
  LLibPaths: TArray<string>;
  LExeDir: string;
  LExpandedPath: string;
begin
  Result := True;
  LLibPaths := GetLibraryPaths();
  LExeDir := TPath.GetDirectoryName(ParamStr(0));

  for LLibrary in FLibraries.Keys do
  begin
    LLowerLib := LowerCase(LLibrary);

    // Check if explicit static library extension provided
    LIsStaticLib := LLowerLib.EndsWith('.lib') or
                    LLowerLib.EndsWith('.a') or
                    LLowerLib.EndsWith('.o') or
                    LLowerLib.EndsWith('.obj');

    LFound := False;

    // Search in library paths
    for LPath in LLibPaths do
    begin
      // Expand relative paths from exe location
      if not TPath.IsPathRooted(LPath) then
        LExpandedPath := TPath.GetFullPath(TPath.Combine(LExeDir, LPath))
      else
        LExpandedPath := LPath;

      if LIsStaticLib then
      begin
        // Explicit static lib - check exact name
        LFullPath := TPath.Combine(LExpandedPath, LLibrary);
        if TFile.Exists(LFullPath) then
        begin
          LFound := True;
          Break;
        end;
      end
      else
      begin
        // Base name - try Zig's search patterns for static libs
        // lib<name>.a (Unix convention)
        LFullPath := TPath.Combine(LExpandedPath, 'lib' + LLibrary + '.a');
        if TFile.Exists(LFullPath) then
        begin
          LFound := True;
          Break;
        end;

        // <name>.lib (Windows convention)
        LFullPath := TPath.Combine(LExpandedPath, LLibrary + '.lib');
        if TFile.Exists(LFullPath) then
        begin
          LFound := True;
          Break;
        end;

        // <name>.a
        LFullPath := TPath.Combine(LExpandedPath, LLibrary + '.a');
        if TFile.Exists(LFullPath) then
        begin
          LFound := True;
          Break;
        end;
      end;
    end;

    // If not found in library paths, try as system DLL
    if not LFound then
    begin
      if LLowerLib.EndsWith('.dll') then
        LFullPath := LLibrary
      else
        LFullPath := LLibrary + '.dll';

      LHandle := LoadLibrary(PChar(LFullPath));
      if LHandle <> 0 then
      begin
        LFound := True;
        FreeLibrary(LHandle);
      end;
    end;

    if not LFound then
    begin
      FErrors.Add(esFatal, 'E501', 'Library not found: %s', [LLibrary]);
      Result := False;
    end;
  end;
end;

function TCompiler.ExecuteBuild(var AExitCode: DWORD): Boolean;
var
  LZigExe: string;
  LFilePath: string;
  LLineNum: Integer;
  LColNum: Integer;
  LErrorMsg: string;
  LErrorPos: Integer;
  LParts: TArray<string>;
  LTrimmed: string;
begin
  Result := False;

  if FProjectDir.IsEmpty then
    Exit;

  if not GenerateBuildZig() then
    Exit;

  LZigExe := TUtils.GetZigExePath();
  if not TFile.Exists(LZigExe) then
  begin
    FErrors.Add('', 1, 1, esFatal, 'E500', 'Zig executable not found: ' + LZigExe);
    Exit;
  end;

  AExitCode := 0;

  TUtils.CaptureZigConsoleOutput(
    'Building ' + FProjectName,
    PChar(LZigExe),
    'build -p out --color on --summary new --prominent-compile-errors',
    FProjectDir,
    AExitCode,
    nil,
    procedure(const ALine: string; const AUserData: Pointer)
    begin
      LTrimmed := ALine.Trim();
      if LTrimmed = '' then
        Exit;

      LErrorPos := LTrimmed.IndexOf(': error:');
      if LErrorPos > 0 then
      begin
        LParts := Copy(LTrimmed, 1, LErrorPos).Split([':']);
        if Length(LParts) >= 3 then
        begin
          if Length(LParts) > 3 then
            LFilePath := string.Join(':', Copy(LParts, 0, Length(LParts) - 2))
          else
            LFilePath := LParts[0];

          if TryStrToInt(LParts[Length(LParts) - 2], LLineNum) and
             TryStrToInt(LParts[Length(LParts) - 1], LColNum) then
          begin
            LErrorMsg := Copy(LTrimmed, LErrorPos + 9, MaxInt).Trim();
            Output('%s(%d:%d): %s', [LFilePath, LLineNum, LColNum, LErrorMsg]);
            Exit;
          end;
        end;
      end;

      if (LTrimmed[1] = '[') then
      begin
        Output(#13 + '  ' + LTrimmed + #27'[K', [], False);
      end
      else
      begin
        if LTrimmed.StartsWith('Build Summary:') then
          Output('', []);
        if LTrimmed.StartsWith('+- ') then
          LTrimmed := LTrimmed.Replace('+- ', '');
        Output('  %s', [LTrimmed]);
      end;
    end
  );

  Output('', []);

  if AExitCode <> 0 then
    Exit;

  Result := True;
end;

procedure TCompiler.ShowCompiled(const AFilename: string);
begin
  if AFilename.IsEmpty then Exit;

  Output('  Compiled "%s"...', [AFilename]);
end;

function TCompiler.TranspileFile(const AFilename: string; const AIsMain: Boolean): Boolean;
var
  LLexer: TLexer;
  LParser: TParser;
  LSemantic: TSemanticAnalyzer;
  LCodeGen: TCodeGen;
  LSource: string;
  LTokens: TArray<TToken>;
  LAST: TModuleNode;
  LOutputPath: string;
  LImport: TImportInfo;
  LImportPath: string;
  LUnitPath: string;
  LFound: Boolean;
  LExpandedUnitPath: string;
  LExeDir: string;
begin
  Result := False;

  if not TFile.Exists(AFilename) then
  begin
    FErrors.Add(AFilename, 1, 1, esFatal, 'E001', 'File not found: ' + AFilename);
    Exit;
  end;

  // Check if already processed
  if FProcessedFiles.ContainsKey(AFilename) then
  begin
    Result := True;
    Exit;
  end;

  // Mark as being processed
  FProcessedFiles.Add(AFilename, AFilename);

  LSource := TFile.ReadAllText(AFilename, TEncoding.UTF8);

  // Tokenize
  LLexer := TLexer.Create();
  try
    LTokens := LLexer.Process(LSource, AFilename, FErrors);
  finally
    LLexer.Free();
  end;

  if FErrors.HasFatal() then
    Exit;

  // Parse
  LParser := TParser.Create();
  try
    LAST := LParser.Process(LTokens, LSource, Self, FErrors);
  finally
    LParser.Free();
  end;

  if (LAST = nil) or FErrors.HasFatal() then
  begin
    LAST.Free();
    Exit;
  end;

  LExeDir := TPath.GetDirectoryName(ParamStr(0));

  try
    // Process imports first (recursively transpile imported modules)
    for LImport in LAST.Imports do
    begin
      // Search for the import in module paths
      LFound := False;

      for LUnitPath in FModulePaths do
      begin
        // Expand relative paths from exe location
        if not TPath.IsPathRooted(LUnitPath) then
          LExpandedUnitPath := TPath.GetFullPath(TPath.Combine(LExeDir, LUnitPath))
        else
          LExpandedUnitPath := LUnitPath;

        LImportPath := TPath.Combine(LExpandedUnitPath, LImport.Name + '.myra');
        //LImportPath := TPath.Combine(LUnitPath, LImport.Name + '.myra');

        if TFile.Exists(LImportPath) then
        begin
          LFound := True;
          // Only transpile and show message if not already processed
          if not FProcessedFiles.ContainsKey(LImportPath) then
          begin
            if not TranspileFile(LImportPath, False) then
              Exit;
            ShowCompiled(LImportPath);
          end;
          Break;
        end;
      end;

      if not LFound then
      begin
        // Also check in same directory as current file
        LImportPath := TPath.Combine(TPath.GetDirectoryName(AFilename), LImport.Name + '.myra');
        if TFile.Exists(LImportPath) then
        begin
          LFound := True;
          // Only transpile and show message if not already processed
          if not FProcessedFiles.ContainsKey(LImportPath) then
          begin
            if not TranspileFile(LImportPath, False) then
              Exit;
            ShowCompiled(LImportPath);
          end;
        end;
      end;

      // Fatal error if import not found anywhere
      if not LFound then
      begin
        FErrors.Add(AFilename, LImport.Line, LImport.Column, esFatal, 'E002',
          'Module not found: ' + LImport.Name);
      end;
    end;

    // Semantic analysis
    LSemantic := TSemanticAnalyzer.Create();
    try
      LSemantic.Process(LAST, FSymbols, Self, FErrors);
    finally
      LSemantic.Free();
    end;

    if FErrors.HasErrors() then
      Exit;

    // Determine compilation unit from module kind (main file only)
    if AIsMain then
    begin
      case LAST.ModuleKind of
        mkExecutable: FCompilationUnit := cuEXE;
        mkLibrary:    FCompilationUnit := cuLIB;
        mkDll:        FCompilationUnit := cuDLL;
      end;
    end;

    // Code generation
    LOutputPath := FProjectGenPath;
    if not TDirectory.Exists(LOutputPath) then
      TDirectory.CreateDirectory(LOutputPath);

    LCodeGen := TCodeGen.Create();
    try
      LCodeGen.Process(LAST, FSymbols, Self, FErrors);
      LCodeGen.SaveFiles(LOutputPath);

      // Register the generated .cpp file for compilation
      AddSourceFile(TPath.Combine(LOutputPath, LAST.ModuleName + '.cpp'));
    finally
      LCodeGen.Free();
    end;

  finally
    LAST.Free();
  end;

  Result := not FErrors.HasErrors();
end;

function TCompiler.AnalyzeFile(const AFilename: string; const AIsMain: Boolean): Boolean;
var
  LLexer: TLexer;
  LParser: TParser;
  LSemantic: TSemanticAnalyzer;
  LSource: string;
  LTokens: TArray<TToken>;
  LAST: TModuleNode;
  LImport: TImportInfo;
  LImportPath: string;
  LUnitPath: string;
  LFound: Boolean;
  LExpandedUnitPath: string;
  LExeDir: string;
begin
  Result := False;

  if not TFile.Exists(AFilename) then
  begin
    FErrors.Add(AFilename, 1, 1, esFatal, 'E001', 'File not found: ' + AFilename);
    Exit;
  end;

  // Check if already processed
  if FProcessedFiles.ContainsKey(AFilename) then
  begin
    Result := True;
    Exit;
  end;

  // Mark as being processed
  FProcessedFiles.Add(AFilename, AFilename);

  LSource := TFile.ReadAllText(AFilename, TEncoding.UTF8);

  // Tokenize
  LLexer := TLexer.Create();
  try
    LTokens := LLexer.Process(LSource, AFilename, FErrors);
  finally
    LLexer.Free();
  end;

  if FErrors.HasFatal() then
    Exit;

  // Parse
  LParser := TParser.Create();
  try
    LAST := LParser.Process(LTokens, LSource, Self, FErrors);
  finally
    LParser.Free();
  end;

  if (LAST = nil) or FErrors.HasFatal() then
  begin
    LAST.Free();
    Exit;
  end;

  LExeDir := TPath.GetDirectoryName(ParamStr(0));

  try
    // Process imports first (recursively analyze imported modules)
    for LImport in LAST.Imports do
    begin
      LFound := False;

      for LUnitPath in FModulePaths do
      begin
        if not TPath.IsPathRooted(LUnitPath) then
          LExpandedUnitPath := TPath.GetFullPath(TPath.Combine(LExeDir, LUnitPath))
        else
          LExpandedUnitPath := LUnitPath;

        LImportPath := TPath.Combine(LExpandedUnitPath, LImport.Name + '.myra');

        if TFile.Exists(LImportPath) then
        begin
          LFound := True;
          if not AnalyzeFile(LImportPath, False) then
            Exit;
          Break;
        end;
      end;

      if not LFound then
      begin
        LImportPath := TPath.Combine(TPath.GetDirectoryName(AFilename), LImport.Name + '.myra');
        if TFile.Exists(LImportPath) then
        begin
          LFound := True;
          if not AnalyzeFile(LImportPath, False) then
            Exit;
        end;
      end;

      if not LFound then
      begin
        FErrors.Add(AFilename, LImport.Line, LImport.Column, esFatal, 'E002',
          'Module not found: ' + LImport.Name);
        Exit;
      end;
    end;

    // Semantic analysis (populates symbol table)
    LSemantic := TSemanticAnalyzer.Create();
    try
      LSemantic.Process(LAST, FSymbols, Self, FErrors);
    finally
      LSemantic.Free();
    end;

    // Determine compilation unit from module kind (main file only)
    if AIsMain then
    begin
      case LAST.ModuleKind of
        mkExecutable: FCompilationUnit := cuEXE;
        mkLibrary:    FCompilationUnit := cuLIB;
        mkDll:        FCompilationUnit := cuDLL;
      end;
    end;

    // NO code generation - analysis only

  finally
    // Store AST for LSP to use (FModules owns it now)
    FModules.AddOrSetValue(LAST.ModuleName, LAST);
  end;

  Result := not FErrors.HasErrors();
end;

function TCompiler.Analyze(): Boolean;
begin
  //Result := False;

  // Clear previous state
  FErrors.Clear();
  ClearProcessedFiles();

  // Reset symbol table for fresh analysis
  FSymbols.Free();
  FSymbols := TSymbolTable.Create();

  if FProjectDir.IsEmpty then
    SetProjectDir(GetCurrentDir());

  if FProjectName.IsEmpty then
    FProjectName := TPath.GetFileNameWithoutExtension(FProjectDir);

  if FProjectMainSourceFile.IsEmpty then
    FProjectMainSourceFile := TPath.Combine(FProjectDir, Format('src\%s.myra', [FProjectName]));

  // Add standard module path
  AddModulePath('.\res\libs\std');

  // Analyze the main source file (recursively analyzes imports)
  try
    Result := AnalyzeFile(FProjectMainSourceFile, True);
  except
    on E: ETooManyErrors do
      Result := False;
  end;
end;

procedure TCompiler.Init(const AProjectName: string; const ABaseDir: string; const ATemplate: TTemplateType);
var
  LProjectDir: string;
  LSrcDir: string;
  LMainFile: string;
  LTemplateContent: string;
begin
  Output('Initializing new project: %s', [AProjectName]);
  Output('', []);

  LProjectDir := TPath.Combine(ABaseDir, AProjectName);
  LSrcDir := TPath.Combine(LProjectDir, 'src');

  if TDirectory.Exists(LProjectDir) then
  begin
    FErrors.Add(esFatal, 'E100', 'Project directory already exists: %s', [LProjectDir]);
    raise Exception.CreateFmt('Project directory already exists: %s', [LProjectDir]);
  end;

  TDirectory.CreateDirectory(LProjectDir);
  TDirectory.CreateDirectory(LSrcDir);
  TDirectory.CreateDirectory(TPath.Combine(LProjectDir, 'generated'));

  case ATemplate of
    ttEXE:
      LTemplateContent := Format(TEMPLATE_EXE, [AProjectName, AProjectName]);
    ttLIB:
      LTemplateContent := Format(TEMPLATE_LIB, [AProjectName, AProjectName]);
    ttDll:
      LTemplateContent := Format(TEMPLATE_DLL, [AProjectName, AProjectName]);
  else
    LTemplateContent := Format(TEMPLATE_EXE, [AProjectName, AProjectName]);
  end;

  LMainFile := TPath.Combine(LSrcDir, AProjectName + '.myra');
  TFile.WriteAllText(LMainFile, LTemplateContent, TEncoding.UTF8);

  SetProjectName(AProjectName);
  SetProjectDir(LProjectDir);

  Output('  Created project structure', []);
  Output('  Created %s', [ExtractFileName(LMainFile)]);
  Output('', []);
  Output('Project initialized at: %s', [LProjectDir]);
end;

function TCompiler.Build(const ACompileOnly: Boolean; var AExitCode: DWORD): Boolean;
var
  LBreakpointPath: string;
begin
  Result := False;

  // Clear previous state
  FErrors.Clear();
  ClearProcessedFiles();
  ClearSourceFiles();
  ClearIncludeHeaders();
  
  // Reset symbol table for fresh build
  FSymbols.Free();
  FSymbols := TSymbolTable.Create();

  if FProjectDir.IsEmpty then
    SetProjectDir(GetCurrentDir());

  if FProjectName.IsEmpty then
    FProjectName := TPath.GetFileNameWithoutExtension(FProjectDir);

  if FProjectMainSourceFile.IsEmpty then
    FProjectMainSourceFile := TPath.Combine(FProjectDir, Format('src\%s.myra', [FProjectName]));

  // Add generated path to include paths
  AddIncludePath(FProjectGenPath);

  AddModulePath('.\res\libs\std');

  AddIncludePath('.\res\runtime');
  AddSourcePath('.\res\runtime');
  AddSourceFile('.\res\runtime\myra_runtime.cpp');

  AddIncludePath('.\res\libs\raylib\include');
  AddLibraryPath('.\res\libs\raylib\lib');


  // Transpile the main source file
  try
    if not TranspileFile(FProjectMainSourceFile, True) then
      Exit;
  except
    on E: ETooManyErrors do
    begin
      Output('  %s', [E.Message]);
      Exit;
    end;
  end;

  ShowCompiled(FProjectMainSourceFile);

  // Validate libraries before building
  if not ValidateLibraries() then
    Exit;

  // Execute Zig build
  Result := ExecuteBuild(AExitCode);

  if Result then
  begin
    if FBreakpoints.Count > 0 then
    begin
      LBreakpointPath := TPath.Combine(FProjectDir, 'out' + PathDelim + 'bin' + PathDelim + FProjectName + '.breakpoints');
      TUtils.CreateDirInPath(LBreakpointPath);
      SaveBreakpointsToFile(LBreakpointPath);
    end;

    if not ACompileOnly then
      Run(AExitCode);
  end;
end;

function TCompiler.IsBuildAnExecutable(): Boolean;
var
  LBuildZigPath: string;
  LContent: string;
  LProjectDir: string;
begin
  Result := False;

  LProjectDir := FProjectDir;
  if LProjectDir.IsEmpty then
    LProjectDir := GetCurrentDir();

  LBuildZigPath := TPath.Combine(LProjectDir, 'build.zig');

  if not TFile.Exists(LBuildZigPath) then
    Exit;

  LContent := TFile.ReadAllText(LBuildZigPath);
  Result := Pos('addExecutable', LContent) > 0;
end;

function TCompiler.GetBuildTarget(): TTargetPlatform;
var
  LBuildZigPath: string;
  LContent: string;
  LLines: TArray<string>;
  LLine: string;
  LArch: string;
  LOS: string;
  LProjectDir: string;
begin
  Result := tgtNative;

  LProjectDir := FProjectDir;
  if LProjectDir.IsEmpty then
    LProjectDir := GetCurrentDir();

  LBuildZigPath := TPath.Combine(LProjectDir, 'build.zig');

  if not TFile.Exists(LBuildZigPath) then
    Exit;

  LContent := TFile.ReadAllText(LBuildZigPath);

  if Pos('b.standardTargetOptions', LContent) > 0 then
  begin
    Result := tgtNative;
    Exit;
  end;

  if Pos('b.resolveTargetQuery', LContent) = 0 then
    Exit;

  LLines := LContent.Split([#13#10, #10], TStringSplitOptions.None);
  LArch := '';
  LOS := '';

  for LLine in LLines do
  begin
    if (Pos('.cpu_arch', LLine) > 0) and (Pos('=', LLine) > 0) then
    begin
      if Pos('.x86_64', LLine) > 0 then
        LArch := 'x86_64'
      else if Pos('.aarch64', LLine) > 0 then
        LArch := 'aarch64'
      else if Pos('.wasm32', LLine) > 0 then
        LArch := 'wasm32';
    end;

    if (Pos('.os_tag', LLine) > 0) and (Pos('=', LLine) > 0) then
    begin
      if Pos('.windows', LLine) > 0 then
        LOS := 'windows'
      else if Pos('.linux', LLine) > 0 then
        LOS := 'linux'
      else if Pos('.macos', LLine) > 0 then
        LOS := 'macos'
      else if Pos('.wasi', LLine) > 0 then
        LOS := 'wasi';
    end;
  end;

  if (LArch = 'x86_64') and (LOS = 'windows') then
    Result := tgtX86_64_Windows
  else if (LArch = 'x86_64') and (LOS = 'linux') then
    Result := tgtX86_64_Linux
  else if (LArch = 'aarch64') and (LOS = 'macos') then
    Result := tgtAArch64_MacOS
  else if (LArch = 'aarch64') and (LOS = 'linux') then
    Result := tgtAArch64_Linux
  else if (LArch = 'wasm32') and (LOS = 'wasi') then
    Result := tgtWasm32_WASI
  else
    Result := tgtNative;
end;

function TCompiler.Run(var AExitCode: DWORD; const ACaptureOutput: Boolean): Boolean;
var
  LProjectDir: string;
  LProjectName: string;
  LExePath: string;
  LBuildTarget: TTargetPlatform;
begin
  Result := False;

  LProjectDir := GetProjectDir();
  LProjectName := GetProjectName();

  if LProjectDir.IsEmpty then
    LProjectDir := GetCurrentDir();

  if LProjectName.IsEmpty then
    LProjectName := TPath.GetFileName(LProjectDir);

  if not IsBuildAnExecutable() then
  begin
    Output('Cannot run: Build does not produce an executable. Only programs are executable.', []);
    Exit;
  end;

  LBuildTarget := GetBuildTarget();

  if LBuildTarget <> tgtNative then
  begin
    if GetTarget() <> tgtX86_64_Windows then
    begin
      Output('Skipping run: Target is not Win64. Only Win64 targets can be executed directly.', []);
      Exit(True);
    end;
  end;

  LExePath := TPath.Combine(LProjectDir, 'out' + PathDelim + 'bin' + PathDelim + LProjectName);

  {$IFDEF MSWINDOWS}
  LExePath := LExePath + '.exe';
  {$ENDIF}

  if not TFile.Exists(LExePath) then
  begin
    Output('Executable not found. Did you run build first?', []);
    Exit;
  end;

  if ACaptureOutput then
  begin
    // Capture output and send to callback (for IDE integration)
    TUtils.CaptureConsoleOutput(
      'Running ' + LProjectName,
      PChar(LExePath),
      '',
      LProjectDir,
      AExitCode,
      nil,
      procedure(const ALine: string; const AUserData: Pointer)
      begin
        Output('%s', [ALine]);
      end
    );
  end
  else
  begin
    // Run in separate console window (for command-line usage)
    AExitCode := TUtils.RunExe(
      LExePath,
      '',
      LProjectDir,
      True,
      SW_SHOW
    );
  end;

  Result := True;
end;

function TCompiler.Clean(): Boolean;
var
  LZigCacheDir: string;
  LOutDir: string;
  LProjectDir: string;
  LProjectGenPath: string;
begin
  LProjectDir := FProjectDir;
  if LProjectDir.IsEmpty then
    LProjectDir := GetCurrentDir();

  LProjectGenPath := TPath.Combine(LProjectDir, 'generated');

  Output('  Cleaning project...', []);

  LZigCacheDir := TPath.Combine(LProjectDir, '.zig-cache');
  LOutDir := TPath.Combine(LProjectDir, 'out');

  if TDirectory.Exists(LProjectGenPath) then
  begin
    TDirectory.Delete(LProjectGenPath, True);
    Output('    Removed generated/', []);
  end;

  if TDirectory.Exists(LZigCacheDir) then
  begin
    TDirectory.Delete(LZigCacheDir, True);
    Output('    Removed .zig-cache/', []);
  end;

  if TDirectory.Exists(LOutDir) then
  begin
    TDirectory.Delete(LOutDir, True);
    Output('    Removed out/', []);
  end;

  TDirectory.CreateDirectory(LProjectGenPath);

  Output('  Clean complete.', []);

  Result := True;
end;

function TCompiler.Debug(): Boolean;
var
  LProjectDir: string;
  LProjectName: string;
  LExePath: string;
  LPasFile: string;
  LBuildTarget: TTargetPlatform;
  LDebug: TDebug;
  LREPL: TDebugREPL;
begin
  Result := False;

  LProjectDir := GetProjectDir();
  LProjectName := GetProjectName();

  if LProjectDir.IsEmpty then
    LProjectDir := GetCurrentDir();

  if LProjectName.IsEmpty then
    LProjectName := TPath.GetFileName(LProjectDir);

  if not IsBuildAnExecutable() then
  begin
    Output('Cannot debug: Build does not produce an executable.', []);
    Exit;
  end;

  LBuildTarget := GetBuildTarget();

  if (LBuildTarget <> tgtNative) and (LBuildTarget <> tgtX86_64_Windows) then
  begin
    Output('Cannot debug: Only Windows executables can be debugged.', []);
    Exit;
  end;

  LExePath := TPath.Combine(LProjectDir, 'out' + PathDelim + 'bin' + PathDelim + LProjectName);

  {$IFDEF MSWINDOWS}
  LExePath := LExePath + '.exe';
  {$ENDIF}

  if not TFile.Exists(LExePath) then
  begin
    Output('Executable not found. Run "myra build" first.', []);
    Exit;
  end;

  LPasFile := TPath.Combine(LProjectDir, 'src' + PathDelim + LProjectName + '.myra');

  LDebug := TDebug.Create();
  try
    LDebug.VerboseLogging := False;

    LDebug.OnBreakpointHit := procedure(ASender: TObject; const AFile: string; ALine: Integer)
    begin
      TUtils.PrintLn(COLOR_GREEN + Format('>>> STOPPED at %s:%d', [AFile, ALine]) + COLOR_RESET);
    end;

    LDebug.OnStateChange := procedure(ASender: TObject; const AOldState, ANewState: TDebugState)
    const
      STATE_NAMES: array[TDebugState] of string = (
        'NotStarted', 'Initializing', 'Ready', 'Launched', 'Running', 'Stopped', 'Exited', 'Error'
      );
    begin
      TUtils.PrintLn(Format('State: %s -> %s', [STATE_NAMES[AOldState], STATE_NAMES[ANewState]]));
    end;

    LDebug.OnOutput := procedure(ASender: TObject; const AOutput: string)
    begin
      if AOutput <> '' then
        TUtils.Print(COLOR_YELLOW + 'OUTPUT: ' + AOutput + COLOR_RESET);
    end;

    LDebug.OnError := procedure(ASender: TObject; const AError: string)
    begin
      TUtils.PrintLn(COLOR_RED + 'ERROR: ' + AError + COLOR_RESET);
    end;

    Output('Starting debugger...', []);
    if not LDebug.Start() then
    begin
      Output('Failed to start debugger: %s', [LDebug.GetLastError()]);
      Exit;
    end;

    Output('Initializing...', []);
    if not LDebug.Initialize() then
    begin
      Output('Failed to initialize debugger: %s', [LDebug.GetLastError()]);
      Exit;
    end;

    LREPL := TDebugREPL.Create();
    try
      LREPL.Debugger := LDebug;
      LREPL.Prompt := '(myra-debug) ';
      LREPL.Run(LExePath, LPasFile);
    finally
      FreeAndNil(LREPL);
    end;

    Result := True;
  finally
    Output('Stopping debugger...', []);
    LDebug.Stop();
    FreeAndNil(LDebug);
  end;
end;

end.
