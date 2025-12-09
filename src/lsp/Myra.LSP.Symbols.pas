{===============================================================================
  Myra™ Language Server Protocol - Symbol Extractor

  Lightweight symbol extraction without full compiler dependency.
  Extracts routines, types, variables, and constants from source.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit Myra.LSP.Symbols;

{$I ..\compiler\Myra.Defines.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Myra.Token,
  Myra.Lexer,
  Myra.Errors;

type
  { TLSPSymbolKind }
  TLSPSymbolKind = (
    skModule,
    skRoutine,
    skType,
    skVariable,
    skConstant,
    skField,
    skParameter
  );

  { TLSPParameter }
  TLSPParameter = record
    ParamName: string;
    TypeName: string;
    IsVar: Boolean;
    IsConst: Boolean;
  end;

  { TLSPSymbol }
  TLSPSymbol = record
    SymbolName: string;
    Kind: TLSPSymbolKind;
    TypeName: string;          // Return type for routines, type for vars
    Line: Integer;
    Column: Integer;
    EndLine: Integer;
    EndColumn: Integer;
    IsPublic: Boolean;
    ModuleName: string;        // Which module this symbol belongs to
    Parameters: TArray<TLSPParameter>;  // For routines
    Documentation: string;     // Extracted from comments
  end;

  { TLSPSymbolTable }
  TLSPSymbolTable = class
  private
    FSymbols: TList<TLSPSymbol>;
    FTokens: TArray<TToken>;
    FPos: Integer;
    FCurrentModule: string;

    function Current(): TToken;
    function Peek(const AOffset: Integer = 1): TToken;
    procedure Advance();
    function Match(const AKind: TTokenKind): Boolean;
    function IsAtEnd(): Boolean;
    function CurrentIsPublic(): Boolean;

    procedure ParseModule();
    procedure ParseImport();
    procedure ParseRoutine(const AIsPublic: Boolean);
    procedure ParseType(const AIsPublic: Boolean);
    procedure ParseVar(const AIsPublic: Boolean);
    procedure ParseConst(const AIsPublic: Boolean);
    procedure ParseRecord(const ATypeName: string; const AIsPublic: Boolean; const ALine: Integer; const ACol: Integer);
    function ParseParameters(): TArray<TLSPParameter>;
    procedure SkipToEnd();
    procedure SkipBlock();

  public
    constructor Create();
    destructor Destroy(); override;

    procedure Clear();
    procedure ExtractFromSource(const ASource: string; const AFilename: string);

    function FindSymbol(const AName: string): TLSPSymbol;
    function FindSymbolsStartingWith(const APrefix: string): TArray<TLSPSymbol>;
    function GetAllSymbols(): TArray<TLSPSymbol>;
    function GetRoutineByName(const AName: string): TLSPSymbol;

    property Symbols: TList<TLSPSymbol> read FSymbols;
  end;

implementation

{ TLSPSymbolTable }

constructor TLSPSymbolTable.Create();
begin
  inherited Create();
  FSymbols := TList<TLSPSymbol>.Create();
end;

destructor TLSPSymbolTable.Destroy();
begin
  FSymbols.Free();
  inherited;
end;

procedure TLSPSymbolTable.Clear();
begin
  FSymbols.Clear();
  FCurrentModule := '';
end;

function TLSPSymbolTable.Current(): TToken;
begin
  if FPos < Length(FTokens) then
    Result := FTokens[FPos]
  else if Length(FTokens) > 0 then
    Result := FTokens[High(FTokens)]
  else
  begin
    Result.Kind := tkEOF;
    Result.Text := '';
    Result.Line := 0;
    Result.Column := 0;
  end;
end;

function TLSPSymbolTable.Peek(const AOffset: Integer): TToken;
var
  LIndex: Integer;
begin
  LIndex := FPos + AOffset;
  if (LIndex >= 0) and (LIndex < Length(FTokens)) then
    Result := FTokens[LIndex]
  else if Length(FTokens) > 0 then
    Result := FTokens[High(FTokens)]
  else
  begin
    Result.Kind := tkEOF;
    Result.Text := '';
  end;
end;

procedure TLSPSymbolTable.Advance();
begin
  if FPos < Length(FTokens) then
    Inc(FPos);
end;

function TLSPSymbolTable.Match(const AKind: TTokenKind): Boolean;
begin
  Result := Current().Kind = AKind;
  if Result then
    Advance();
end;

function TLSPSymbolTable.IsAtEnd(): Boolean;
begin
  Result := (FPos >= Length(FTokens)) or (Current().Kind = tkEOF);
end;

function TLSPSymbolTable.CurrentIsPublic(): Boolean;
begin
  Result := Current().Kind = tkPublic;
  if Result then
    Advance();
end;

procedure TLSPSymbolTable.ExtractFromSource(const ASource: string; const AFilename: string);
var
  LLexer: TLexer;
  LErrors: TErrors;
  LIsPublic: Boolean;
begin
  Clear();

  LLexer := TLexer.Create();
  LErrors := TErrors.Create();
  try
    FTokens := LLexer.Process(ASource, AFilename, LErrors);
    FPos := 0;

    while not IsAtEnd() do
    begin
      case Current().Kind of
        tkModule:
          ParseModule();

        tkImport:
          ParseImport();

        tkPublic:
          begin
            Advance(); // Skip PUBLIC
            case Current().Kind of
              tkRoutine: ParseRoutine(True);
              tkType: ParseType(True);
              tkVar: ParseVar(True);
              tkConst: ParseConst(True);
            else
              Advance();
            end;
          end;

        tkRoutine:
          ParseRoutine(False);

        tkType:
          ParseType(False);

        tkVar:
          ParseVar(False);

        tkConst:
          ParseConst(False);

      else
        Advance();
      end;
    end;
  finally
    LErrors.Free();
    LLexer.Free();
  end;
end;

procedure TLSPSymbolTable.ParseModule();
var
  LSymbol: TLSPSymbol;
begin
  // MODULE [exe|lib|dll] Name;
  Advance(); // Skip MODULE

  // Skip optional module kind (exe, lib, dll are identifiers)
  if (Current().Kind = tkIdentifier) and 
     ((UpperCase(Current().Text) = 'EXE') or 
      (UpperCase(Current().Text) = 'LIB') or 
      (UpperCase(Current().Text) = 'DLL')) then
    Advance();

  if Current().Kind = tkIdentifier then
  begin
    LSymbol := Default(TLSPSymbol);
    LSymbol.SymbolName := Current().Text;
    LSymbol.Kind := skModule;
    LSymbol.Line := Current().Line;
    LSymbol.Column := Current().Column;
    LSymbol.IsPublic := True;
    FCurrentModule := LSymbol.SymbolName;
    LSymbol.ModuleName := FCurrentModule;
    FSymbols.Add(LSymbol);
    Advance();
  end;

  // Skip to semicolon
  while not IsAtEnd() and (Current().Kind <> tkSemicolon) do
    Advance();
  if Current().Kind = tkSemicolon then
    Advance();
end;

procedure TLSPSymbolTable.ParseImport();
begin
  // IMPORT Name1, Name2, ...;
  Advance(); // Skip IMPORT

  while not IsAtEnd() and (Current().Kind <> tkSemicolon) do
    Advance();

  if Current().Kind = tkSemicolon then
    Advance();
end;

procedure TLSPSymbolTable.ParseRoutine(const AIsPublic: Boolean);
var
  LSymbol: TLSPSymbol;
begin
  // ROUTINE Name(params): ReturnType;
  Advance(); // Skip ROUTINE

  if Current().Kind = tkIdentifier then
  begin
    LSymbol := Default(TLSPSymbol);
    LSymbol.SymbolName := Current().Text;
    LSymbol.Kind := skRoutine;
    LSymbol.Line := Current().Line;
    LSymbol.Column := Current().Column;
    LSymbol.IsPublic := AIsPublic;
    LSymbol.ModuleName := FCurrentModule;
    Advance();

    // Parse parameters
    if Current().Kind = tkLParen then
      LSymbol.Parameters := ParseParameters();

    // Parse return type
    if Current().Kind = tkColon then
    begin
      Advance(); // Skip :
      if Current().Kind = tkIdentifier then
      begin
        LSymbol.TypeName := Current().Text;
        Advance();
      end;
    end;

    FSymbols.Add(LSymbol);
  end;

  // Skip to END or next declaration
  SkipToEnd();
end;

function TLSPSymbolTable.ParseParameters(): TArray<TLSPParameter>;
var
  LParams: TList<TLSPParameter>;
  LParam: TLSPParameter;
begin
  LParams := TList<TLSPParameter>.Create();
  try
    Advance(); // Skip (

    while not IsAtEnd() and (Current().Kind <> tkRParen) do
    begin
      LParam := Default(TLSPParameter);

      // Check for CONST or VAR
      if Current().Kind = tkConst then
      begin
        LParam.IsConst := True;
        Advance();
      end
      else if Current().Kind = tkVar then
      begin
        LParam.IsVar := True;
        Advance();
      end;

      // Parameter name
      if Current().Kind = tkIdentifier then
      begin
        LParam.ParamName := Current().Text;
        Advance();
      end;

      // Colon and type
      if Current().Kind = tkColon then
      begin
        Advance();
        if Current().Kind = tkIdentifier then
        begin
          LParam.TypeName := Current().Text;
          Advance();
        end;
      end;

      LParams.Add(LParam);

      // Skip comma or semicolon between params
      if Current().Kind in [tkComma, tkSemicolon] then
        Advance();
    end;

    if Current().Kind = tkRParen then
      Advance();

    Result := LParams.ToArray();
  finally
    LParams.Free();
  end;
end;

procedure TLSPSymbolTable.ParseType(const AIsPublic: Boolean);
var
  LSymbol: TLSPSymbol;
  LTypeName: string;
  LLine: Integer;
  LCol: Integer;
begin
  // TYPE Name = ...;
  Advance(); // Skip TYPE

  while not IsAtEnd() and not (Current().Kind in [tkPublic, tkRoutine, tkVar, tkConst, tkType, tkBegin, tkEOF]) do
  begin
    if Current().Kind = tkIdentifier then
    begin
      LTypeName := Current().Text;
      LLine := Current().Line;
      LCol := Current().Column;
      Advance();

      if Current().Kind = tkEquals then
      begin
        Advance(); // Skip =

        if Current().Kind = tkRecord then
        begin
          ParseRecord(LTypeName, AIsPublic, LLine, LCol);
        end
        else
        begin
          // Simple type alias
          LSymbol := Default(TLSPSymbol);
          LSymbol.SymbolName := LTypeName;
          LSymbol.Kind := skType;
          LSymbol.Line := LLine;
          LSymbol.Column := LCol;
          LSymbol.IsPublic := AIsPublic;
          LSymbol.ModuleName := FCurrentModule;

          if Current().Kind = tkIdentifier then
            LSymbol.TypeName := Current().Text;

          FSymbols.Add(LSymbol);

          // Skip to semicolon
          while not IsAtEnd() and (Current().Kind <> tkSemicolon) do
            Advance();
          if Current().Kind = tkSemicolon then
            Advance();
        end;
      end;
    end
    else
      Advance();
  end;
end;

procedure TLSPSymbolTable.ParseRecord(const ATypeName: string; const AIsPublic: Boolean; const ALine: Integer; const ACol: Integer);
var
  LSymbol: TLSPSymbol;
  LFieldSymbol: TLSPSymbol;
begin
  // RECORD ... END
  LSymbol := Default(TLSPSymbol);
  LSymbol.SymbolName := ATypeName;
  LSymbol.Kind := skType;
  LSymbol.TypeName := 'RECORD';
  LSymbol.Line := ALine;
  LSymbol.Column := ACol;
  LSymbol.IsPublic := AIsPublic;
  LSymbol.ModuleName := FCurrentModule;
  FSymbols.Add(LSymbol);

  Advance(); // Skip RECORD

  // Skip optional parent type
  if Current().Kind = tkLParen then
  begin
    while not IsAtEnd() and (Current().Kind <> tkRParen) do
      Advance();
    if Current().Kind = tkRParen then
      Advance();
  end;

  // Parse fields until END
  while not IsAtEnd() and (Current().Kind <> tkEnd) do
  begin
    if Current().Kind = tkIdentifier then
    begin
      LFieldSymbol := Default(TLSPSymbol);
      LFieldSymbol.SymbolName := ATypeName + '.' + Current().Text;
      LFieldSymbol.Kind := skField;
      LFieldSymbol.Line := Current().Line;
      LFieldSymbol.Column := Current().Column;
      LFieldSymbol.ModuleName := FCurrentModule;
      Advance();

      if Current().Kind = tkColon then
      begin
        Advance();
        if Current().Kind = tkIdentifier then
        begin
          LFieldSymbol.TypeName := Current().Text;
          Advance();
        end;
      end;

      FSymbols.Add(LFieldSymbol);
    end
    else
      Advance();
  end;

  if Current().Kind = tkEnd then
    Advance();
  if Current().Kind = tkSemicolon then
    Advance();
end;

procedure TLSPSymbolTable.ParseVar(const AIsPublic: Boolean);
var
  LSymbol: TLSPSymbol;
begin
  // VAR Name: Type; ...
  Advance(); // Skip VAR

  while not IsAtEnd() and not (Current().Kind in [tkPublic, tkRoutine, tkVar, tkConst, tkType, tkBegin, tkEOF]) do
  begin
    if Current().Kind = tkIdentifier then
    begin
      LSymbol := Default(TLSPSymbol);
      LSymbol.SymbolName := Current().Text;
      LSymbol.Kind := skVariable;
      LSymbol.Line := Current().Line;
      LSymbol.Column := Current().Column;
      LSymbol.IsPublic := AIsPublic;
      LSymbol.ModuleName := FCurrentModule;
      Advance();

      if Current().Kind = tkColon then
      begin
        Advance();
        if Current().Kind = tkIdentifier then
        begin
          LSymbol.TypeName := Current().Text;
          Advance();
        end;
      end;

      FSymbols.Add(LSymbol);

      // Skip to semicolon
      while not IsAtEnd() and (Current().Kind <> tkSemicolon) do
        Advance();
      if Current().Kind = tkSemicolon then
        Advance();
    end
    else
      Advance();
  end;
end;

procedure TLSPSymbolTable.ParseConst(const AIsPublic: Boolean);
var
  LSymbol: TLSPSymbol;
begin
  // CONST Name = Value; ...
  Advance(); // Skip CONST

  while not IsAtEnd() and not (Current().Kind in [tkPublic, tkRoutine, tkVar, tkConst, tkType, tkBegin, tkEOF]) do
  begin
    if Current().Kind = tkIdentifier then
    begin
      LSymbol := Default(TLSPSymbol);
      LSymbol.SymbolName := Current().Text;
      LSymbol.Kind := skConstant;
      LSymbol.Line := Current().Line;
      LSymbol.Column := Current().Column;
      LSymbol.IsPublic := AIsPublic;
      LSymbol.ModuleName := FCurrentModule;
      Advance();

      // Skip to semicolon (value could be complex)
      while not IsAtEnd() and (Current().Kind <> tkSemicolon) do
        Advance();
      if Current().Kind = tkSemicolon then
        Advance();

      FSymbols.Add(LSymbol);
    end
    else
      Advance();
  end;
end;

procedure TLSPSymbolTable.SkipToEnd();
var
  LDepth: Integer;
begin
  LDepth := 0;

  while not IsAtEnd() do
  begin
    case Current().Kind of
      tkBegin, tkRecord, tkCase, tkTry:
        Inc(LDepth);

      tkEnd:
        begin
          if LDepth > 0 then
            Dec(LDepth)
          else
          begin
            Advance();
            if Current().Kind = tkSemicolon then
              Advance();
            Exit;
          end;
        end;

      // Stop at next top-level declaration
      tkPublic, tkRoutine, tkType, tkVar, tkConst:
        if LDepth = 0 then
          Exit;
    end;

    Advance();
  end;
end;

procedure TLSPSymbolTable.SkipBlock();
var
  LDepth: Integer;
begin
  LDepth := 1;

  while not IsAtEnd() and (LDepth > 0) do
  begin
    case Current().Kind of
      tkBegin, tkRecord, tkCase, tkTry:
        Inc(LDepth);
      tkEnd:
        Dec(LDepth);
    end;
    Advance();
  end;
end;

function TLSPSymbolTable.FindSymbol(const AName: string): TLSPSymbol;
var
  LSymbol: TLSPSymbol;
begin
  Result := Default(TLSPSymbol);
  Result.Line := -1; // Indicate not found

  for LSymbol in FSymbols do
  begin
    if SameText(LSymbol.SymbolName, AName) then
    begin
      Result := LSymbol;
      Exit;
    end;
  end;
end;

function TLSPSymbolTable.FindSymbolsStartingWith(const APrefix: string): TArray<TLSPSymbol>;
var
  LResult: TList<TLSPSymbol>;
  LSymbol: TLSPSymbol;
  LUpperPrefix: string;
begin
  LResult := TList<TLSPSymbol>.Create();
  try
    LUpperPrefix := UpperCase(APrefix);

    for LSymbol in FSymbols do
    begin
      if UpperCase(LSymbol.SymbolName).StartsWith(LUpperPrefix) then
        LResult.Add(LSymbol);
    end;

    Result := LResult.ToArray();
  finally
    LResult.Free();
  end;
end;

function TLSPSymbolTable.GetAllSymbols(): TArray<TLSPSymbol>;
begin
  Result := FSymbols.ToArray();
end;

function TLSPSymbolTable.GetRoutineByName(const AName: string): TLSPSymbol;
var
  LSymbol: TLSPSymbol;
begin
  Result := Default(TLSPSymbol);
  Result.Line := -1;

  for LSymbol in FSymbols do
  begin
    if (LSymbol.Kind = skRoutine) and SameText(LSymbol.SymbolName, AName) then
    begin
      Result := LSymbol;
      Exit;
    end;
  end;
end;

end.
