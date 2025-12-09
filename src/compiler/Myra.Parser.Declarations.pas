{===============================================================================
  Myra™ - Pascal. Refined.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit Myra.Parser.Declarations;

{$I Myra.Defines.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Myra.Token,
  Myra.AST,
  Myra.Compiler,
  Myra.Parser;

function ParseModule(const AParser: TParser): TModuleNode;
function ParseImports(const AParser: TParser): TList<TImportInfo>;
function ParseDirective(const AParser: TParser): TDirectiveNode;
function ParseConstSection(const AParser: TParser; const AIsPublic: Boolean): TObjectList<TASTNode>;
function ParseConst(const AParser: TParser; const AIsPublic: Boolean): TConstNode;
function ParseTypeSection(const AParser: TParser; const AIsPublic: Boolean): TObjectList<TASTNode>;
function ParseTypeDecl(const AParser: TParser; const AIsPublic: Boolean): TTypeNode;
function ParseRecordType(const AParser: TParser; const AIsPublic: Boolean): TRecordNode;
function ParseArrayType(const AParser: TParser; const AIsPublic: Boolean): TArrayTypeNode;
function ParsePointerType(const AParser: TParser; const AIsPublic: Boolean): TPointerTypeNode;
function ParseSetType(const AParser: TParser; const AIsPublic: Boolean): TSetTypeNode;
function ParseRoutineType(const AParser: TParser; const AIsPublic: Boolean): TRoutineTypeNode;
function ParseVarSection(const AParser: TParser; const AIsPublic: Boolean): TObjectList<TVarDeclNode>;
function ParseVarDecl(const AParser: TParser; const AIsPublic: Boolean): TVarDeclNode;
function ParseRoutine(const AParser: TParser; const AIsPublic: Boolean): TRoutineNode;
function ParseMethod(const AParser: TParser; const AIsPublic: Boolean): TRoutineNode;
function ParseParams(const AParser: TParser): TObjectList<TParamNode>;
function ParseParamsInner(const AParser: TParser): TObjectList<TParamNode>;
function ParseTest(const AParser: TParser): TTestNode;

implementation

uses
  Myra.Errors,
  Myra.Parser.Cpp,
  Myra.Parser.Expressions,
  Myra.Parser.Statements;

function IsMyrDirective(const AText: string): Boolean;
var
  LUpper: string;
begin
  LUpper := UpperCase(AText);
  Result := (LUpper = '#INCLUDE_HEADER') or
            (LUpper = '#UNITTESTMODE') or
            (LUpper = '#ABI') or
            (LUpper = '#EMIT') or
            (LUpper = '#LINK') or
            (LUpper = '#LIBRARY_PATH') or
            (LUpper = '#INCLUDE_PATH') or
            (LUpper = '#MODULE_PATH') or
            (LUpper = '#OPTIMIZATION') or
            (LUpper = '#TARGET') or
            (LUpper = '#APPTYPE') or
            (LUpper = '#BREAKPOINT');
end;

function ParseModule(const AParser: TParser): TModuleNode;
var
  LToken: TToken;
  LIsPublic: Boolean;
  LConsts: TObjectList<TASTNode>;
  LTypes: TObjectList<TASTNode>;
  LVars: TObjectList<TVarDeclNode>;
  LRoutine: TRoutineNode;
  LDirective: TDirectiveNode;
  LCppBlock: TCppBlockNode;
  LNode: TASTNode;
  LVar: TVarDeclNode;
begin
  Result := TModuleNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Expect(tkModule);

  LToken := AParser.Current();
  if LToken.Kind <> tkIdentifier then
  begin
    AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E107',
      'Expected module type (exe, dll, or lib)');
    Result.Free();
    Result := nil;
    Exit;
  end;

  if SameText(LToken.Text, 'dll') then
  begin
    Result.ModuleKind := mkDll;
    AParser.Advance();
  end
  else if SameText(LToken.Text, 'lib') then
  begin
    Result.ModuleKind := mkLibrary;
    AParser.Advance();
  end
  else if SameText(LToken.Text, 'exe') then
  begin
    Result.ModuleKind := mkExecutable;
    AParser.Advance();
  end
  else
  begin
    AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E107',
      'Expected module type (exe, dll, or lib), got: ' + LToken.Text);
    Result.Free();
    Result := nil;
    Exit;
  end;

  LToken := AParser.Current();
  AParser.Expect(tkIdentifier);
  Result.ModuleName := LToken.Text;
  AParser.Expect(tkSemicolon);

  while AParser.Current().Kind = tkDirective do
  begin
    if IsMyrDirective(AParser.Current().Text) then
    begin
      LDirective := ParseDirective(AParser);
      if LDirective <> nil then
        Result.Directives.Add(LDirective);
    end
    else
    begin
      LCppBlock := ParseCppPassthrough(AParser);
      Result.CppBlocks.Add(LCppBlock);
    end;
  end;

  if AParser.Current().Kind = tkImport then
  begin
    Result.Imports.Free();
    Result.Imports := ParseImports(AParser);
  end;

  while not AParser.IsAtEnd() and not (AParser.Current().Kind in [tkEnd, tkBegin]) do
  begin
    LToken := AParser.Current();
    LIsPublic := False;

    if LToken.Kind = tkPublic then
    begin
      LIsPublic := True;
      AParser.Advance();
      LToken := AParser.Current();
    end;

    if LToken.Kind = tkConst then
    begin
      LConsts := ParseConstSection(AParser, LIsPublic);
      for LNode in LConsts do
        Result.Consts.Add(LNode);
      LConsts.OwnsObjects := False;
      LConsts.Free();
    end
    else if LToken.Kind = tkType then
    begin
      LTypes := ParseTypeSection(AParser, LIsPublic);
      for LNode in LTypes do
        Result.Types.Add(LNode);
      LTypes.OwnsObjects := False;
      LTypes.Free();
    end
    else if LToken.Kind = tkVar then
    begin
      LVars := ParseVarSection(AParser, LIsPublic);
      for LVar in LVars do
        Result.Vars.Add(LVar);
      LVars.OwnsObjects := False;
      LVars.Free();
    end
    else if LToken.Kind = tkRoutine then
    begin
      LRoutine := ParseRoutine(AParser, LIsPublic);
      Result.Routines.Add(LRoutine);
    end
    else if LToken.Kind = tkMethod then
    begin
      LRoutine := ParseMethod(AParser, LIsPublic);
      Result.Routines.Add(LRoutine);
    end
    else if LToken.Kind = tkDirective then
    begin
      if IsMyrDirective(LToken.Text) then
      begin
        LDirective := ParseDirective(AParser);
        if LDirective <> nil then
          Result.Directives.Add(LDirective);
      end
      else
      begin
        LCppBlock := ParseCppPassthrough(AParser);
        Result.CppBlocks.Add(LCppBlock);
      end;
    end
    else if LToken.Kind = tkStartCpp then
    begin
      LCppBlock := ParseCppBlock(AParser);
      Result.CppBlocks.Add(LCppBlock);
    end
    else
    begin
      AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E101',
        'Unexpected token in module: ' + LToken.Text);
      AParser.Advance();
    end;
  end;

  if AParser.Current().Kind = tkBegin then
  begin
    AParser.Advance();
    Result.Body := ParseBlock(AParser);
  end;

  if (Result.Body <> nil) and (Result.ModuleKind <> mkExecutable) then
  begin
    AParser.FErrors.Add(Result.Filename, Result.Line, Result.Column, esError, 'E110',
      'Library or DLL modules cannot have an entry point (begin...end block)');
  end;

  Result.EndLine := AParser.Current().Line;
  AParser.Expect(tkEnd);
  AParser.Expect(tkDot);

  while not AParser.IsAtEnd() and (AParser.Current().Kind = tkTest) do
  begin
    if not AParser.FCompiler.GetUnitTestMode() then
    begin
      AParser.FErrors.Add(AParser.Current().Filename, AParser.Current().Line, AParser.Current().Column, esError, 'E111',
        'Test blocks require #UNITTESTMODE ON');
      Break;
    end;

    if Result.ModuleKind = mkDll then
    begin
      AParser.FErrors.Add(AParser.Current().Filename, AParser.Current().Line, AParser.Current().Column, esError, 'E112',
        'Test blocks are not allowed in DLL modules');
      Break;
    end;

    Result.Tests.Add(ParseTest(AParser));
  end;
end;

function ParseImports(const AParser: TParser): TList<TImportInfo>;
var
  LToken: TToken;
  LImport: TImportInfo;
begin
  Result := TList<TImportInfo>.Create();

  AParser.Expect(tkImport);

  repeat
    LToken := AParser.Current();
    AParser.Expect(tkIdentifier);
    LImport.Name := LToken.Text;
    LImport.Line := LToken.Line;
    LImport.Column := LToken.Column;
    Result.Add(LImport);
  until not AParser.Match(tkComma);

  AParser.Expect(tkSemicolon);
end;

function ParseDirective(const AParser: TParser): TDirectiveNode;
var
  LToken: TToken;
  LDirective: string;
  LHeader: string;
begin
  LToken := AParser.Current();
  LDirective := UpperCase(LToken.Text);

  if LDirective = '#INCLUDE_HEADER' then
  begin
    AParser.Advance();
    LToken := AParser.Current();
    if LToken.Kind = tkString then
    begin
      LHeader := Copy(LToken.Text, 2, Length(LToken.Text) - 2);
      if Assigned(AParser.FCompiler) then
        AParser.FCompiler.AddIncludeHeader(LHeader);
      AParser.Advance();
    end
    else
      AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E106',
        'Expected string literal after #include_header');
    AParser.Match(tkSemicolon);
    Result := nil;
    Exit;
  end;

  if LDirective = '#UNITTESTMODE' then
  begin
    AParser.Advance();
    LToken := AParser.Current();
    if LToken.Kind = tkIdentifier then
    begin
      if SameText(LToken.Text, 'ON') then
      begin
        if Assigned(AParser.FCompiler) then
          AParser.FCompiler.SetUnitTestMode(True);
      end
      else if SameText(LToken.Text, 'OFF') then
      begin
        if Assigned(AParser.FCompiler) then
          AParser.FCompiler.SetUnitTestMode(False);
      end
      else
        AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E108',
          'Expected ON or OFF after #UNITTESTMODE');
      AParser.Advance();
    end
    else
      AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E108',
        'Expected ON or OFF after #UNITTESTMODE');
    Result := nil;
    Exit;
  end;

  if LDirective = '#ABI' then
  begin
    AParser.Advance();
    LToken := AParser.Current();
    if LToken.Kind = tkIdentifier then
    begin
      if SameText(LToken.Text, 'C') then
        AParser.FCurrentABIIsC := True
      else if SameText(LToken.Text, 'CPP') then
        AParser.FCurrentABIIsC := False
      else
        AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E113',
          'Expected C or CPP after #ABI');
      AParser.Advance();
    end
    else
      AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E113',
        'Expected C or CPP after #ABI');
    Result := nil;
    Exit;
  end;

  if LDirective = '#EMIT' then
  begin
    AParser.Advance();
    LToken := AParser.Current();
    if LToken.Kind = tkIdentifier then
    begin
      if SameText(LToken.Text, 'HEADER') then
        AParser.FCurrentEmitTarget := ctHeader
      else if SameText(LToken.Text, 'SOURCE') then
        AParser.FCurrentEmitTarget := ctSource
      else
        AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E122',
          'Expected HEADER or SOURCE after #emit');
      AParser.Advance();
    end
    else
      AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E122',
        'Expected HEADER or SOURCE after #emit');
    Result := nil;
    Exit;
  end;

  if LDirective = '#LINK' then
  begin
    AParser.Advance();
    LToken := AParser.Current();
    if LToken.Kind = tkString then
    begin
      LHeader := Copy(LToken.Text, 2, Length(LToken.Text) - 2);
      if Assigned(AParser.FCompiler) then
        AParser.FCompiler.AddLibrary(LHeader);
      AParser.Advance();
    end
    else
      AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E114',
        'Expected string literal after #link');
    Result := nil;
    Exit;
  end;

  if LDirective = '#LIBRARY_PATH' then
  begin
    AParser.Advance();
    LToken := AParser.Current();
    if LToken.Kind = tkString then
    begin
      LHeader := Copy(LToken.Text, 2, Length(LToken.Text) - 2);
      if Assigned(AParser.FCompiler) then
        AParser.FCompiler.AddLibraryPath(LHeader);
      AParser.Advance();
    end
    else
      AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E115',
        'Expected string literal after #library_path');
    Result := nil;
    Exit;
  end;

  if LDirective = '#INCLUDE_PATH' then
  begin
    AParser.Advance();
    LToken := AParser.Current();
    if LToken.Kind = tkString then
    begin
      LHeader := Copy(LToken.Text, 2, Length(LToken.Text) - 2);
      if Assigned(AParser.FCompiler) then
        AParser.FCompiler.AddIncludePath(LHeader);
      AParser.Advance();
    end
    else
      AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E116',
        'Expected string literal after #include_path');
    Result := nil;
    Exit;
  end;

  if LDirective = '#MODULE_PATH' then
  begin
    AParser.Advance();
    LToken := AParser.Current();
    if LToken.Kind = tkString then
    begin
      LHeader := Copy(LToken.Text, 2, Length(LToken.Text) - 2);
      if Assigned(AParser.FCompiler) then
        AParser.FCompiler.AddModulePath(LHeader);
      AParser.Advance();
    end
    else
      AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E117',
        'Expected string literal after #module_path');
    Result := nil;
    Exit;
  end;

  if LDirective = '#OPTIMIZATION' then
  begin
    AParser.Advance();
    LToken := AParser.Current();
    if LToken.Kind = tkIdentifier then
    begin
      if SameText(LToken.Text, 'DEBUG') then
        AParser.FCompiler.SetOptimization(optDebug)
      else if SameText(LToken.Text, 'RELEASESAFE') then
        AParser.FCompiler.SetOptimization(optReleaseSafe)
      else if SameText(LToken.Text, 'RELEASEFAST') then
        AParser.FCompiler.SetOptimization(optReleaseFast)
      else if SameText(LToken.Text, 'RELEASESMALL') then
        AParser.FCompiler.SetOptimization(optReleaseSmall)
      else
        AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E118',
          'Expected DEBUG, RELEASESAFE, RELEASEFAST, or RELEASESMALL after #optimization');
      AParser.Advance();
    end
    else
      AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E118',
        'Expected optimization level after #optimization');
    Result := nil;
    Exit;
  end;

  if LDirective = '#TARGET' then
  begin
    AParser.Advance();
    LToken := AParser.Current();
    if LToken.Kind = tkIdentifier then
    begin
      LHeader := LowerCase(LToken.Text);
      AParser.Advance();
      while AParser.Current().Kind = tkMinus do
      begin
        AParser.Advance();
        LHeader := LHeader + '-' + LowerCase(AParser.Current().Text);
        AParser.Advance();
      end;

      if LHeader = 'native' then
        AParser.FCompiler.SetTarget(tgtNative)
      else if LHeader = 'x86_64-windows' then
        AParser.FCompiler.SetTarget(tgtX86_64_Windows)
      else if LHeader = 'x86_64-linux' then
        AParser.FCompiler.SetTarget(tgtX86_64_Linux)
      else if LHeader = 'aarch64-macos' then
        AParser.FCompiler.SetTarget(tgtAArch64_MacOS)
      else if LHeader = 'aarch64-linux' then
        AParser.FCompiler.SetTarget(tgtAArch64_Linux)
      else if LHeader = 'wasm32-wasi' then
        AParser.FCompiler.SetTarget(tgtWasm32_WASI)
      else
        AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E119',
          'Invalid target platform: ' + LHeader);
    end
    else
      AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E119',
        'Expected target platform after #target');
    Result := nil;
    Exit;
  end;

  if LDirective = '#APPTYPE' then
  begin
    AParser.Advance();
    LToken := AParser.Current();
    if LToken.Kind = tkIdentifier then
    begin
      if SameText(LToken.Text, 'CONSOLE') then
        AParser.FCompiler.SetAppType(atConsole)
      else if SameText(LToken.Text, 'GUI') then
        AParser.FCompiler.SetAppType(atGUI)
      else
        AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E120',
          'Expected CONSOLE or GUI after #apptype');
      AParser.Advance();
    end
    else
      AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E120',
        'Expected application type after #apptype');
    Result := nil;
    Exit;
  end;

  if LDirective = '#BREAKPOINT' then
  begin
    if Assigned(AParser.FCompiler) then
      AParser.FCompiler.AddBreakpoint(LToken.Filename, LToken.Line + 1);
    AParser.Advance();
    Result := nil;
    Exit;
  end;

  Result := TDirectiveNode.Create();
  AParser.SetNodeLocation(Result, LToken);
  AParser.Expect(tkDirective);
  Result.DirectiveName := LToken.Text;

  LToken := AParser.Current();
  if LToken.Kind in [tkIdentifier, tkString, tkInteger] then
  begin
    Result.Value := LToken.Text;
    AParser.Advance();
  end;

  AParser.Match(tkSemicolon);
end;

function ParseConstSection(const AParser: TParser; const AIsPublic: Boolean): TObjectList<TASTNode>;
var
  LConst: TConstNode;
  LLocalPublic: Boolean;
begin
  Result := TObjectList<TASTNode>.Create();
  AParser.Expect(tkConst);

  while AParser.Current().Kind in [tkIdentifier, tkPublic] do
  begin
    LLocalPublic := AIsPublic;

    if AParser.Current().Kind = tkPublic then
    begin
      if AParser.Peek().Kind <> tkIdentifier then
        Break;
      LLocalPublic := True;
      AParser.Advance();
    end;

    if (AParser.Current().Kind = tkIdentifier) and (AParser.Peek().Kind = tkIdentifier) then
      Result.Add(ParseCppPassthrough(AParser))
    else
    begin
      LConst := ParseConst(AParser, LLocalPublic);
      Result.Add(LConst);
    end;
  end;
end;

function ParseConst(const AParser: TParser; const AIsPublic: Boolean): TConstNode;
var
  LToken: TToken;
  LStartPos: Integer;
begin
  Result := TConstNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Expect(tkIdentifier);
  Result.ConstName := LToken.Text;
  Result.IsPublic := AIsPublic;

  // Check for optional type annotation
  if AParser.Match(tkColon) then
    Result.TypeName := AParser.ParseTypeName(Result.TypeNameLine, Result.TypeNameColumn);

  AParser.Expect(tkEquals);

  LStartPos := AParser.FPos;
  Result.Value := ParseExpression(AParser);

  if AParser.Current().Kind <> tkSemicolon then
  begin
    Result.Value.Free();
    AParser.FPos := LStartPos;
    Result.Value := ParseCppExprPassthrough(AParser, [tkSemicolon]);
  end;

  AParser.Expect(tkSemicolon);
end;

function ParseTypeSection(const AParser: TParser; const AIsPublic: Boolean): TObjectList<TASTNode>;
var
  LType: TTypeNode;
  LLocalPublic: Boolean;
begin
  Result := TObjectList<TASTNode>.Create();
  AParser.Expect(tkType);

  while AParser.Current().Kind in [tkIdentifier, tkPublic] do
  begin
    LLocalPublic := AIsPublic;

    if AParser.Current().Kind = tkPublic then
    begin
      if AParser.Peek().Kind <> tkIdentifier then
        Break;
      LLocalPublic := True;
      AParser.Advance();
    end;

    if (AParser.Current().Kind = tkIdentifier) and (AParser.Peek().Kind = tkIdentifier) then
      Result.Add(ParseCppPassthrough(AParser))
    else
    begin
      LType := ParseTypeDecl(AParser, LLocalPublic);
      Result.Add(LType);
    end;
  end;
end;

function ParseTypeDecl(const AParser: TParser; const AIsPublic: Boolean): TTypeNode;
var
  LToken: TToken;
  LName: string;
begin
  LToken := AParser.Current();
  AParser.Expect(tkIdentifier);
  LName := LToken.Text;
  AParser.Expect(tkEquals);

  LToken := AParser.Current();

  if LToken.Kind = tkRecord then
  begin
    Result := ParseRecordType(AParser, AIsPublic);
    Result.TypeName := LName;
  end
  else if LToken.Kind = tkArray then
  begin
    Result := ParseArrayType(AParser, AIsPublic);
    Result.TypeName := LName;
  end
  else if LToken.Kind = tkPointer then
  begin
    Result := ParsePointerType(AParser, AIsPublic);
    Result.TypeName := LName;
  end
  else if LToken.Kind = tkSet then
  begin
    Result := ParseSetType(AParser, AIsPublic);
    Result.TypeName := LName;
  end
  else if LToken.Kind = tkRoutine then
  begin
    Result := ParseRoutineType(AParser, AIsPublic);
    Result.TypeName := LName;
  end
  else
  begin
    // Simple type alias: TDateTime = FLOAT
    Result := TTypeNode.Create();
    AParser.SetNodeLocation(Result, LToken);
    Result.TypeName := LName;
    Result.TypeNameLine := LToken.Line;
    Result.TypeNameColumn := LToken.Column;
    Result.AliasedType := AParser.ParseTypeName(Result.AliasedTypeLine, Result.AliasedTypeColumn);
    Result.IsPublic := AIsPublic;
  end;

  AParser.Expect(tkSemicolon);
end;

function ParseRecordType(const AParser: TParser; const AIsPublic: Boolean): TRecordNode;
var
  LToken: TToken;
  LField: TFieldNode;
begin
  Result := TRecordNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);
  Result.IsPublic := AIsPublic;

  AParser.Expect(tkRecord);

  if AParser.Match(tkLParen) then
  begin
    LToken := AParser.Current();
    AParser.Expect(tkIdentifier);
    Result.ParentType := LToken.Text;
    Result.ParentTypeLine := LToken.Line;
    Result.ParentTypeColumn := LToken.Column;
    AParser.Expect(tkRParen);
  end;

  while AParser.Current().Kind = tkIdentifier do
  begin
    LField := TFieldNode.Create();
    LToken := AParser.Current();
    AParser.SetNodeLocation(LField, LToken);

    AParser.Expect(tkIdentifier);
    LField.FieldName := LToken.Text;
    AParser.Expect(tkColon);
    LField.TypeName := AParser.ParseTypeName(LField.TypeNameLine, LField.TypeNameColumn);
    AParser.Expect(tkSemicolon);

    Result.Fields.Add(LField);
  end;

  Result.EndLine := AParser.Current().Line;
  AParser.Expect(tkEnd);
end;

function ParseArrayType(const AParser: TParser; const AIsPublic: Boolean): TArrayTypeNode;
var
  LToken: TToken;
  LLowValue: Int64;
  LHighValue: Int64;
begin
  Result := TArrayTypeNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);
  Result.IsPublic := AIsPublic;

  AParser.Expect(tkArray);

  if AParser.Match(tkLBracket) then
  begin
    if AParser.Current().Kind = tkRBracket then
    begin
      Result.IsDynamic := True;
      AParser.Advance();
    end
    else
    begin
      LToken := AParser.Current();
      AParser.Expect(tkInteger);
      LLowValue := StrToInt64(LToken.Text);
      Result.LowBound := LLowValue;

      AParser.Expect(tkDotDot);

      LToken := AParser.Current();
      AParser.Expect(tkInteger);
      LHighValue := StrToInt64(LToken.Text);
      Result.HighBound := LHighValue;

      AParser.Expect(tkRBracket);
    end;
  end
  else
    Result.IsDynamic := True;

  AParser.Expect(tkOf);
  Result.ElementType := AParser.ParseTypeName(Result.ElementTypeLine, Result.ElementTypeColumn);
end;

function ParsePointerType(const AParser: TParser; const AIsPublic: Boolean): TPointerTypeNode;
var
  LToken: TToken;
begin
  Result := TPointerTypeNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);
  Result.IsPublic := AIsPublic;

  AParser.Expect(tkPointer);

  if AParser.Match(tkTo) then
    Result.BaseType := AParser.ParseTypeName(Result.BaseTypeLine, Result.BaseTypeColumn)
  else
    Result.BaseType := '';
end;

function ParseSetType(const AParser: TParser; const AIsPublic: Boolean): TSetTypeNode;
var
  LToken: TToken;
  LLowValue: Int64;
  LHighValue: Int64;
begin
  Result := TSetTypeNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);
  Result.IsPublic := AIsPublic;

  AParser.Expect(tkSet);
  AParser.Expect(tkOf);

  LToken := AParser.Current();
  if LToken.Kind = tkInteger then
  begin
    AParser.Expect(tkInteger);
    LLowValue := StrToInt64(LToken.Text);
    Result.LowBound := LLowValue;

    AParser.Expect(tkDotDot);

    LToken := AParser.Current();
    AParser.Expect(tkInteger);
    LHighValue := StrToInt64(LToken.Text);
    Result.HighBound := LHighValue;
  end
  else
    Result.ElementType := AParser.ParseTypeName(Result.ElementTypeLine, Result.ElementTypeColumn);
end;

function ParseRoutineType(const AParser: TParser; const AIsPublic: Boolean): TRoutineTypeNode;
var
  LToken: TToken;
begin
  Result := TRoutineTypeNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);
  Result.IsPublic := AIsPublic;

  AParser.Expect(tkRoutine);

  // Parameters (required parentheses, may be empty)
  AParser.Expect(tkLParen);
  if AParser.Current().Kind <> tkRParen then
  begin
    Result.Params.Free();
    Result.Params := ParseParamsInner(AParser);
  end;
  AParser.Expect(tkRParen);

  // Optional return type
  if AParser.Match(tkColon) then
    Result.ReturnType := AParser.ParseTypeName(Result.ReturnTypeLine, Result.ReturnTypeColumn);
end;

function ParseVarSection(const AParser: TParser; const AIsPublic: Boolean): TObjectList<TVarDeclNode>;
var
  LVar: TVarDeclNode;
  LLocalPublic: Boolean;
begin
  Result := TObjectList<TVarDeclNode>.Create();
  AParser.Expect(tkVar);

  while AParser.Current().Kind in [tkIdentifier, tkPublic] do
  begin
    LLocalPublic := AIsPublic;

    if AParser.Current().Kind = tkPublic then
    begin
      if AParser.Peek().Kind <> tkIdentifier then
        Break;
      LLocalPublic := True;
      AParser.Advance();
    end;

    LVar := ParseVarDecl(AParser, LLocalPublic);
    Result.Add(LVar);
  end;
end;

function ParseVarDecl(const AParser: TParser; const AIsPublic: Boolean): TVarDeclNode;
var
  LToken: TToken;
  LStartPos: Integer;
begin
  Result := TVarDeclNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Expect(tkIdentifier);
  Result.VarName := LToken.Text;
  Result.IsPublic := AIsPublic;

  AParser.Expect(tkColon);
  Result.TypeName := AParser.ParseTypeName(Result.TypeNameLine, Result.TypeNameColumn);

  // Check for optional initialization
  if AParser.Match(tkEquals) then
  begin
    LStartPos := AParser.FPos;
    Result.InitValue := ParseExpression(AParser);

    // Fallback to C++ passthrough if not a valid Myra expression
    if AParser.Current().Kind <> tkSemicolon then
    begin
      Result.InitValue.Free();
      AParser.FPos := LStartPos;
      Result.InitValue := ParseCppExprPassthrough(AParser, [tkSemicolon]);
    end;
  end;

  AParser.Expect(tkSemicolon);
end;

function ParseRoutine(const AParser: TParser; const AIsPublic: Boolean): TRoutineNode;
var
  LToken: TToken;
  LVars: TObjectList<TVarDeclNode>;
  LVar: TVarDeclNode;
begin
  Result := TRoutineNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);
  Result.IsPublic := AIsPublic;
  Result.IsCExport := AParser.FCurrentABIIsC;

  AParser.Expect(tkRoutine);

  LToken := AParser.Current();
  AParser.Expect(tkIdentifier);
  Result.RoutineName := LToken.Text;
  Result.RoutineNameLine := LToken.Line;
  Result.RoutineNameColumn := LToken.Column;

  if AParser.Current().Kind = tkLParen then
  begin
    AParser.Advance();

    if AParser.Current().Kind = tkEllipsis then
    begin
      Result.IsVariadic := True;
      AParser.Advance();
    end
    else if AParser.Current().Kind <> tkRParen then
    begin
      Result.Params.Free();
      Result.Params := ParseParamsInner(AParser);
    end;

    AParser.Expect(tkRParen);
  end;

  if AParser.Match(tkColon) then
    Result.ReturnType := AParser.ParseTypeName(Result.ReturnTypeLine, Result.ReturnTypeColumn);

  AParser.Expect(tkSemicolon);

  LToken := AParser.Current();
  if LToken.Kind = tkIdentifier then
  begin
    if SameText(LToken.Text, 'CDECL') then
    begin
      Result.CallingConv := ccCdecl;
      AParser.Advance();
      AParser.Expect(tkSemicolon);
    end
    else if SameText(LToken.Text, 'STDCALL') then
    begin
      Result.CallingConv := ccStdcall;
      AParser.Advance();
      AParser.Expect(tkSemicolon);
    end
    else if SameText(LToken.Text, 'FASTCALL') then
    begin
      Result.CallingConv := ccFastcall;
      AParser.Advance();
      AParser.Expect(tkSemicolon);
    end;
  end;

  if AParser.Current().Kind = tkExternal then
  begin
    AParser.Advance();
    Result.IsExternal := True;

    LToken := AParser.Current();
    if LToken.Kind = tkString then
    begin
      Result.ExternalLib := Copy(LToken.Text, 2, Length(LToken.Text) - 2);
      Result.ExternalLibIsIdent := False;
      if Assigned(AParser.FCompiler) and (Result.ExternalLib <> '') then
        AParser.FCompiler.AddLibrary(Result.ExternalLib);
      AParser.Advance();
    end
    else if LToken.Kind = tkIdentifier then
    begin
      Result.ExternalLib := LToken.Text;
      Result.ExternalLibIsIdent := True;
      AParser.Advance();
    end
    else
      AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E121',
        'Expected library name or constant after external');

    AParser.Expect(tkSemicolon);
    Exit;
  end;

  if AParser.Current().Kind = tkVar then
  begin
    LVars := ParseVarSection(AParser, False);
    for LVar in LVars do
      Result.LocalVars.Add(LVar);
    LVars.OwnsObjects := False;
    LVars.Free();
  end;

  AParser.Expect(tkBegin);
  Result.Body := ParseBlock(AParser);
  Result.EndLine := AParser.Current().Line;
  AParser.Expect(tkEnd);
  AParser.Expect(tkSemicolon);
end;

function ParseMethod(const AParser: TParser; const AIsPublic: Boolean): TRoutineNode;
var
  LToken: TToken;
  LVars: TObjectList<TVarDeclNode>;
  LVar: TVarDeclNode;
  LFirstParam: TParamNode;
begin
  Result := TRoutineNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);
  Result.IsPublic := AIsPublic;
  Result.IsMethod := True;

  AParser.Expect(tkMethod);

  LToken := AParser.Current();
  AParser.Expect(tkIdentifier);
  Result.RoutineName := LToken.Text;
  Result.RoutineNameLine := LToken.Line;
  Result.RoutineNameColumn := LToken.Column;

  AParser.Expect(tkLParen);
  
  if AParser.Current().Kind <> tkRParen then
  begin
    Result.Params.Free();
    Result.Params := ParseParamsInner(AParser);
  end;

  AParser.Expect(tkRParen);

  if Result.Params.Count = 0 then
  begin
    AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E130',
      'Method must have var Self parameter');
  end
  else
  begin
    LFirstParam := Result.Params[0];
    if not LFirstParam.IsVar then
      AParser.FErrors.Add(LFirstParam.Filename, LFirstParam.Line, LFirstParam.Column, esError, 'E131',
        'First parameter must be var Self');
    if not SameText(LFirstParam.ParamName, 'Self') then
      AParser.FErrors.Add(LFirstParam.Filename, LFirstParam.Line, LFirstParam.Column, esError, 'E132',
        'First parameter must be named Self');
    Result.BoundToType := LFirstParam.TypeName;
    Result.BoundToTypeLine := LFirstParam.TypeNameLine;
    Result.BoundToTypeColumn := LFirstParam.TypeNameColumn;
  end;

  if AParser.Match(tkColon) then
    Result.ReturnType := AParser.ParseTypeName(Result.ReturnTypeLine, Result.ReturnTypeColumn);

  AParser.Expect(tkSemicolon);

  if AParser.Current().Kind = tkVar then
  begin
    LVars := ParseVarSection(AParser, False);
    for LVar in LVars do
      Result.LocalVars.Add(LVar);
    LVars.OwnsObjects := False;
    LVars.Free();
  end;

  AParser.Expect(tkBegin);
  Result.Body := ParseBlock(AParser);
  Result.EndLine := AParser.Current().Line;
  AParser.Expect(tkEnd);
  AParser.Expect(tkSemicolon);
end;

function ParseParams(const AParser: TParser): TObjectList<TParamNode>;
begin
  AParser.Expect(tkLParen);
  Result := ParseParamsInner(AParser);
  AParser.Expect(tkRParen);
end;

function ParseParamsInner(const AParser: TParser): TObjectList<TParamNode>;
var
  LToken: TToken;
  LParam: TParamNode;
  LIsVar: Boolean;
  LIsConst: Boolean;
begin
  Result := TObjectList<TParamNode>.Create();

  if AParser.Current().Kind <> tkRParen then
  begin
    repeat
      LIsVar := False;
      LIsConst := False;

      if AParser.Match(tkVar) then
        LIsVar := True
      else if AParser.Match(tkConst) then
        LIsConst := True;

      LParam := TParamNode.Create();
      LToken := AParser.Current();
      AParser.SetNodeLocation(LParam, LToken);

      if LToken.Kind = tkSelf then
      begin
        LParam.ParamName := 'Self';
        AParser.Advance();
      end
      else
      begin
        AParser.Expect(tkIdentifier);
        LParam.ParamName := LToken.Text;
      end;
      
      LParam.IsVar := LIsVar;
      LParam.IsConst := LIsConst;

      AParser.Expect(tkColon);
      LParam.TypeName := AParser.ParseTypeName(LParam.TypeNameLine, LParam.TypeNameColumn);

      Result.Add(LParam);
    until not AParser.Match(tkSemicolon);
  end;
end;

function ParseTest(const AParser: TParser): TTestNode;
var
  LToken: TToken;
  LVars: TObjectList<TVarDeclNode>;
  LVar: TVarDeclNode;
  LConsts: TObjectList<TASTNode>;
  LConst: TASTNode;
  LTypes: TObjectList<TASTNode>;
  LType: TASTNode;
begin
  Result := TTestNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Expect(tkTest);

  LToken := AParser.Current();
  if LToken.Kind = tkString then
  begin
    Result.Description := Copy(LToken.Text, 2, Length(LToken.Text) - 2);
    AParser.Advance();
  end
  else
    AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E109',
      'Expected test description string');

  if AParser.Current().Kind = tkVar then
  begin
    LVars := ParseVarSection(AParser, False);
    for LVar in LVars do
      Result.LocalVars.Add(LVar);
    LVars.OwnsObjects := False;
    LVars.Free();
  end;

  if AParser.Current().Kind = tkConst then
  begin
    LConsts := ParseConstSection(AParser, False);
    for LConst in LConsts do
      Result.LocalConsts.Add(LConst);
    LConsts.OwnsObjects := False;
    LConsts.Free();
  end;

  if AParser.Current().Kind = tkType then
  begin
    LTypes := ParseTypeSection(AParser, False);
    for LType in LTypes do
      Result.LocalTypes.Add(LType);
    LTypes.OwnsObjects := False;
    LTypes.Free();
  end;

  AParser.Expect(tkBegin);
  Result.Body := ParseBlock(AParser);
  Result.EndLine := AParser.Current().Line;
  AParser.Expect(tkEnd);
  AParser.Expect(tkSemicolon);
end;

end.
