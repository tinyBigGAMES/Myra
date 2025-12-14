{===============================================================================
  Myra™ - Pascal. Refined.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit Myra.Lexer;

{$I Myra.Defines.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Myra.Utils,
  Myra.Errors,
  Myra.Token;

type
  { TLexer }
  TLexer = class(TBaseObject)
  private
    FSource: string;
    FFilename: string;
    FPos: Integer;
    FLine: Integer;
    FColumn: Integer;
    FErrors: TErrors;
    FTokens: TList<TToken>;

    function IsEOF(): Boolean;
    function PeekChar(const AOffset: Integer = 0): Char;
    function NextChar(): Char;
    procedure SkipWhitespace();
    procedure SkipLineComment();
    procedure SkipBlockComment(const AEndChar: Char);
    function IsLetter(const AChar: Char): Boolean;
    function IsDigit(const AChar: Char): Boolean;
    function IsAlphaNumeric(const AChar: Char): Boolean;
    function ScanIdentifierOrKeyword(): TToken;
    function ScanNumber(): TToken;
    function ScanString(): TToken;
    function ScanWideString(): TToken;
    function ScanCppBlock(): TToken;
    function ScanDirective(): TToken;
    function CheckKeyword(const AText: string): TTokenKind;
    function MakeToken(const AKind: TTokenKind; const AText: string): TToken;
    function MakeTokenAt(const AKind: TTokenKind; const AText: string; const ALine: Integer; const AColumn: Integer; const AStartPos: Integer): TToken;
    procedure ScanToken();

  public
    constructor Create(); override;
    destructor Destroy(); override;

    function Process(const ASource: string; const AFilename: string; const AErrors: TErrors): TArray<TToken>;
  end;

implementation

{ TLexer }

constructor TLexer.Create();
begin
  inherited Create();

  FTokens := TList<TToken>.Create();
end;

destructor TLexer.Destroy();
begin
  FTokens.Free();

  inherited Destroy();
end;

function TLexer.IsEOF(): Boolean;
begin
  Result := FPos > Length(FSource);
end;

function TLexer.PeekChar(const AOffset: Integer): Char;
var
  LIndex: Integer;
begin
  LIndex := FPos + AOffset;
  if (LIndex >= 1) and (LIndex <= Length(FSource)) then
    Result := FSource[LIndex]
  else
    Result := #0;
end;

function TLexer.NextChar(): Char;
begin
  if IsEOF() then
    Result := #0
  else
  begin
    Result := FSource[FPos];
    Inc(FPos);
    if Result = #10 then
    begin
      Inc(FLine);
      FColumn := 1;
    end
    else if Result <> #13 then
      Inc(FColumn);
  end;
end;

procedure TLexer.SkipWhitespace();
var
  LChar: Char;
begin
  while not IsEOF() do
  begin
    LChar := PeekChar();
    if CharInSet(LChar, [' ', #9, #10, #13]) then
      NextChar()
    else
      Break;
  end;
end;

procedure TLexer.SkipLineComment();
begin
  while not IsEOF() and (PeekChar() <> #10) do
    NextChar();
end;

procedure TLexer.SkipBlockComment(const AEndChar: Char);
var
  LStartLine: Integer;
  LStartColumn: Integer;
begin
  LStartLine := FLine;
  LStartColumn := FColumn;

  while not IsEOF() do
  begin
    if (AEndChar = ')') and (PeekChar() = '*') and (PeekChar(1) = ')') then
    begin
      NextChar();
      NextChar();
      Exit;
    end
    else if (AEndChar = '}') and (PeekChar() = '}') then
    begin
      NextChar();
      Exit;
    end;
    NextChar();
  end;

  FErrors.Add(FFilename, LStartLine, LStartColumn, esError, 'E001', 'Unterminated block comment');
end;

function TLexer.IsLetter(const AChar: Char): Boolean;
begin
  Result := ((AChar >= 'A') and (AChar <= 'Z')) or
            ((AChar >= 'a') and (AChar <= 'z')) or
            (AChar = '_');
end;

function TLexer.IsDigit(const AChar: Char): Boolean;
begin
  Result := (AChar >= '0') and (AChar <= '9');
end;

function TLexer.IsAlphaNumeric(const AChar: Char): Boolean;
begin
  Result := IsLetter(AChar) or IsDigit(AChar);
end;

function TLexer.CheckKeyword(const AText: string): TTokenKind;
var
  LUpper: string;
begin
  LUpper := UpperCase(AText);

  if LUpper = 'MODULE' then Result := tkModule
  else if LUpper = 'IMPORT' then Result := tkImport
  else if LUpper = 'PUBLIC' then Result := tkPublic
  else if LUpper = 'CONST' then Result := tkConst
  else if LUpper = 'TYPE' then Result := tkType
  else if LUpper = 'VAR' then Result := tkVar
  else if LUpper = 'ROUTINE' then Result := tkRoutine
  else if LUpper = 'BEGIN' then Result := tkBegin
  else if LUpper = 'END' then Result := tkEnd
  else if LUpper = 'IF' then Result := tkIf
  else if LUpper = 'THEN' then Result := tkThen
  else if LUpper = 'ELSE' then Result := tkElse
  else if LUpper = 'CASE' then Result := tkCase
  else if LUpper = 'OF' then Result := tkOf
  else if LUpper = 'WHILE' then Result := tkWhile
  else if LUpper = 'DO' then Result := tkDo
  else if LUpper = 'REPEAT' then Result := tkRepeat
  else if LUpper = 'UNTIL' then Result := tkUntil
  else if LUpper = 'FOR' then Result := tkFor
  else if LUpper = 'TO' then Result := tkTo
  else if LUpper = 'DOWNTO' then Result := tkDownto
  else if LUpper = 'RETURN' then Result := tkReturn
  else if LUpper = 'ARRAY' then Result := tkArray
  else if LUpper = 'RECORD' then Result := tkRecord
  else if LUpper = 'SET' then Result := tkSet
  else if LUpper = 'POINTER' then Result := tkPointer
  else if LUpper = 'NIL' then Result := tkNil
  else if LUpper = 'AND' then Result := tkAnd
  else if LUpper = 'OR' then Result := tkOr
  else if LUpper = 'NOT' then Result := tkNot
  else if LUpper = 'DIV' then Result := tkDiv
  else if LUpper = 'MOD' then Result := tkMod
  else if LUpper = 'IN' then Result := tkIn
  else if LUpper = 'IS' then Result := tkIs
  else if LUpper = 'AS' then Result := tkAs
  else if LUpper = 'TRY' then Result := tkTry
  else if LUpper = 'EXCEPT' then Result := tkExcept
  else if LUpper = 'FINALLY' then Result := tkFinally
  else if LUpper = 'TEST' then Result := tkTest
  else if LUpper = 'EXTERNAL' then Result := tkExternal
  else if LUpper = 'METHOD' then Result := tkMethod
  else if LUpper = 'SELF' then Result := tkSelf
  else if LUpper = 'INHERITED' then Result := tkInherited
  else if LUpper = 'PARAMCOUNT' then Result := tkParamCount
  else if LUpper = 'PARAMSTR' then Result := tkParamStr
  else Result := tkIdentifier;
end;

function TLexer.ScanIdentifierOrKeyword(): TToken;
var
  LStart: Integer;
  LStartColumn: Integer;
  LText: string;
  LKind: TTokenKind;
begin
  LStart := FPos;
  LStartColumn := FColumn;

  while not IsEOF() and IsAlphaNumeric(PeekChar()) do
    NextChar();

  LText := Copy(FSource, LStart, FPos - LStart);
  LKind := CheckKeyword(LText);

  Result := MakeTokenAt(LKind, LText, FLine, LStartColumn, LStart);
end;

function TLexer.ScanNumber(): TToken;
var
  LStart: Integer;
  LStartColumn: Integer;
  LText: string;
  LKind: TTokenKind;
  LHasDecimal: Boolean;
  LCheckPos: Integer;
  LIsHex: Boolean;
begin
  LStart := FPos;
  LStartColumn := FColumn;
  LHasDecimal := False;
  LIsHex := False;

  // Scan initial digits
  while not IsEOF() and IsDigit(PeekChar()) do
    NextChar();

  // Check if this could be Oberon-style hex: digits/hex-letters followed by H suffix
  // Peek ahead without consuming
  LCheckPos := FPos;
  while (LCheckPos <= Length(FSource)) and
        CharInSet(FSource[LCheckPos], ['0'..'9', 'A'..'F', 'a'..'f']) do
    Inc(LCheckPos);

  // If the char after hex digits is H/h, this is a hex literal
  if (LCheckPos <= Length(FSource)) and CharInSet(FSource[LCheckPos], ['H', 'h']) then
  begin
    // Scan hex digits
    while not IsEOF() and CharInSet(PeekChar(), ['0'..'9', 'A'..'F', 'a'..'f']) do
      NextChar();
    // Consume the H suffix
    NextChar();
    LIsHex := True;
  end
  else
  begin
    // Not hex - check for decimal point
    if (PeekChar() = '.') and IsDigit(PeekChar(1)) then
    begin
      LHasDecimal := True;
      NextChar();
      while not IsEOF() and IsDigit(PeekChar()) do
        NextChar();
    end;

    // Check for scientific notation exponent
    if CharInSet(PeekChar(), ['e', 'E']) then
    begin
      LHasDecimal := True;
      NextChar();
      if CharInSet(PeekChar(), ['+', '-']) then
        NextChar();
      while not IsEOF() and IsDigit(PeekChar()) do
        NextChar();
    end;
  end;

  LText := Copy(FSource, LStart, FPos - LStart);

  if LIsHex then
    LKind := tkInteger
  else if LHasDecimal then
    LKind := tkFloat
  else
    LKind := tkInteger;

  Result := MakeTokenAt(LKind, LText, FLine, LStartColumn, LStart);
end;

function TLexer.ScanString(): TToken;
var
  LStart: Integer;
  LStartLine: Integer;
  LStartColumn: Integer;
  LQuote: Char;
  LText: string;
  LKind: TTokenKind;
begin
  LStartLine := FLine;
  LStartColumn := FColumn;
  LQuote := PeekChar();
  LStart := FPos;

  NextChar();

  while not IsEOF() do
  begin
    if PeekChar() = LQuote then
    begin
      if PeekChar(1) = LQuote then
      begin
        NextChar();
        NextChar();
      end
      else
      begin
        NextChar();
        Break;
      end;
    end
    else if CharInSet(PeekChar(), [#10, #13]) then
    begin
      FErrors.Add(FFilename, LStartLine, LStartColumn, esError, 'E002', 'Unterminated string literal');
      Break;
    end
    else
      NextChar();
  end;

  LText := Copy(FSource, LStart, FPos - LStart);

  if Length(LText) = 3 then
    LKind := tkChar
  else
    LKind := tkString;

  Result := MakeTokenAt(LKind, LText, LStartLine, LStartColumn, LStart);
end;

function TLexer.ScanWideString(): TToken;
var
  LStart: Integer;
  LStartLine: Integer;
  LStartColumn: Integer;
  LQuote: Char;
  LText: string;
  LKind: TTokenKind;
  LContentLen: Integer;
begin
  LStartLine := FLine;
  LStartColumn := FColumn;
  LStart := FPos;

  NextChar(); // skip 'L'
  LQuote := PeekChar();
  NextChar(); // skip opening quote

  while not IsEOF() do
  begin
    if PeekChar() = LQuote then
    begin
      if PeekChar(1) = LQuote then
      begin
        // Escaped quote
        NextChar();
        NextChar();
      end
      else
      begin
        NextChar(); // closing quote
        Break;
      end;
    end
    else if CharInSet(PeekChar(), [#10, #13]) then
    begin
      FErrors.Add(FFilename, LStartLine, LStartColumn, esError, 'E002', 'Unterminated wide string literal');
      Break;
    end
    else
      NextChar();
  end;

  LText := Copy(FSource, LStart, FPos - LStart);

  // Content length: total minus L prefix (1) and quotes (2) = length - 3
  LContentLen := Length(LText) - 3;

  if LContentLen = 1 then
    LKind := tkWideChar
  else
    LKind := tkWideString;

  Result := MakeTokenAt(LKind, LText, LStartLine, LStartColumn, LStart);
end;

function TLexer.ScanCppBlock(): TToken;
var
  LStart: Integer;
  LStartLine: Integer;
  LStartColumn: Integer;
  LText: string;
begin
  LStartLine := FLine;
  LStartColumn := FColumn;

  // Skip leading newline after #startcpp
  if PeekChar() = #13 then
    NextChar();
  if PeekChar() = #10 then
    NextChar();

  LStart := FPos;

  while not IsEOF() do
  begin
    if (PeekChar() = '#') then
    begin
      if (Copy(FSource, FPos, 7) = '#endcpp') then
        Break;
    end;
    NextChar();
  end;

  LText := TrimRight(Copy(FSource, LStart, FPos - LStart));
  Result := MakeTokenAt(tkCppBlock, LText, LStartLine, LStartColumn, LStart);
end;

function TLexer.ScanDirective(): TToken;
var
  LStart: Integer;
  LStartColumn: Integer;
  LText: string;
begin
  LStart := FPos;
  LStartColumn := FColumn;

  NextChar(); // skip #

  while not IsEOF() and IsAlphaNumeric(PeekChar()) do
    NextChar();

  LText := Copy(FSource, LStart, FPos - LStart);
  Result := MakeTokenAt(tkDirective, LText, FLine, LStartColumn, LStart);
end;

function TLexer.MakeToken(const AKind: TTokenKind; const AText: string): TToken;
begin
  Result := MakeTokenAt(AKind, AText, FLine, FColumn, FPos);
end;

function TLexer.MakeTokenAt(const AKind: TTokenKind; const AText: string; const ALine: Integer; const AColumn: Integer; const AStartPos: Integer): TToken;
begin
  Result.Kind := AKind;
  Result.Text := AText;
  Result.Filename := FFilename;
  Result.Line := ALine;
  Result.Column := AColumn;
  Result.StartPos := AStartPos;
end;

procedure TLexer.ScanToken();
var
  LChar: Char;
  LStartColumn: Integer;
  LStartPos: Integer;
begin
  SkipWhitespace();

  if IsEOF() then
  begin
    FTokens.Add(MakeToken(tkEOF, ''));
    Exit;
  end;

  LChar := PeekChar();

  // Comments
  if (LChar = '/') and (PeekChar(1) = '/') then
  begin
    SkipLineComment();
    Exit;
  end;

  if (LChar = '(') and (PeekChar(1) = '*') then
  begin
    NextChar();
    NextChar();
    SkipBlockComment(')');
    Exit;
  end;

  // { } are set literal braces, not comments

  // #startcpp / #endcpp / #directive
  if LChar = '#' then
  begin
    if Copy(FSource, FPos, 9) = '#startcpp' then
    begin
      LStartColumn := FColumn;
      LStartPos := FPos;
      FPos := FPos + 9;
      FColumn := FColumn + 9;
      FTokens.Add(MakeTokenAt(tkStartCpp, '#startcpp', FLine, LStartColumn, LStartPos));

      // Skip spaces/tabs (NOT newlines) and look for optional "header" or "source"
      while not IsEOF() and CharInSet(PeekChar(), [' ', #9]) do
        NextChar();

      if IsLetter(PeekChar()) then
      begin
        // Scan identifier - could be "header" or "source"
        FTokens.Add(ScanIdentifierOrKeyword());
      end;

      FTokens.Add(ScanCppBlock());
      Exit;
    end
    else if Copy(FSource, FPos, 7) = '#endcpp' then
    begin
      LStartColumn := FColumn;
      LStartPos := FPos;
      FPos := FPos + 7;
      FColumn := FColumn + 7;
      FTokens.Add(MakeTokenAt(tkEndCpp, '#endcpp', FLine, LStartColumn, LStartPos));
      Exit;
    end
    else if IsLetter(PeekChar(1)) then
    begin
      FTokens.Add(ScanDirective());
      Exit;
    end;
  end;

  // Wide string/char literals: L'...' or L"..."
  if (LChar = 'L') and CharInSet(PeekChar(1), ['''', '"']) then
  begin
    FTokens.Add(ScanWideString());
    Exit;
  end;

  // Identifiers and keywords
  if IsLetter(LChar) then
  begin
    FTokens.Add(ScanIdentifierOrKeyword());
    Exit;
  end;

  // Numbers
  if IsDigit(LChar) then
  begin
    FTokens.Add(ScanNumber());
    Exit;
  end;

  // Strings
  if LChar = '''' then
  begin
    FTokens.Add(ScanString());
    Exit;
  end;

  // Two-character symbols
  LStartColumn := FColumn;
  LStartPos := FPos;

  if (LChar = ':') and (PeekChar(1) = '=') then
  begin
    NextChar();
    NextChar();
    FTokens.Add(MakeTokenAt(tkAssign, ':=', FLine, LStartColumn, LStartPos));
    Exit;
  end;

  if (LChar = '<') and (PeekChar(1) = '>') then
  begin
    NextChar();
    NextChar();
    FTokens.Add(MakeTokenAt(tkNotEquals, '<>', FLine, LStartColumn, LStartPos));
    Exit;
  end;

  if (LChar = '<') and (PeekChar(1) = '=') then
  begin
    NextChar();
    NextChar();
    FTokens.Add(MakeTokenAt(tkLessEq, '<=', FLine, LStartColumn, LStartPos));
    Exit;
  end;

  if (LChar = '>') and (PeekChar(1) = '=') then
  begin
    NextChar();
    NextChar();
    FTokens.Add(MakeTokenAt(tkGreaterEq, '>=', FLine, LStartColumn, LStartPos));
    Exit;
  end;

  if (LChar = '.') and (PeekChar(1) = '.') then
  begin
    NextChar();
    NextChar();
    // Check for ellipsis (...) vs range (..)
    if PeekChar() = '.' then
    begin
      NextChar();
      FTokens.Add(MakeTokenAt(tkEllipsis, '...', FLine, LStartColumn, LStartPos));
    end
    else
      FTokens.Add(MakeTokenAt(tkDotDot, '..', FLine, LStartColumn, LStartPos));
    Exit;
  end;

  // Single-character symbols
  NextChar();

  case LChar of
    '(': FTokens.Add(MakeTokenAt(tkLParen, '(', FLine, LStartColumn, LStartPos));
    ')': FTokens.Add(MakeTokenAt(tkRParen, ')', FLine, LStartColumn, LStartPos));
    '[': FTokens.Add(MakeTokenAt(tkLBracket, '[', FLine, LStartColumn, LStartPos));
    ']': FTokens.Add(MakeTokenAt(tkRBracket, ']', FLine, LStartColumn, LStartPos));
    '{': FTokens.Add(MakeTokenAt(tkLBrace, '{', FLine, LStartColumn, LStartPos));
    '}': FTokens.Add(MakeTokenAt(tkRBrace, '}', FLine, LStartColumn, LStartPos));
    '.': FTokens.Add(MakeTokenAt(tkDot, '.', FLine, LStartColumn, LStartPos));
    ',': FTokens.Add(MakeTokenAt(tkComma, ',', FLine, LStartColumn, LStartPos));
    ':': FTokens.Add(MakeTokenAt(tkColon, ':', FLine, LStartColumn, LStartPos));
    ';': FTokens.Add(MakeTokenAt(tkSemicolon, ';', FLine, LStartColumn, LStartPos));
    '=': FTokens.Add(MakeTokenAt(tkEquals, '=', FLine, LStartColumn, LStartPos));
    '<': FTokens.Add(MakeTokenAt(tkLess, '<', FLine, LStartColumn, LStartPos));
    '>': FTokens.Add(MakeTokenAt(tkGreater, '>', FLine, LStartColumn, LStartPos));
    '+': FTokens.Add(MakeTokenAt(tkPlus, '+', FLine, LStartColumn, LStartPos));
    '-': FTokens.Add(MakeTokenAt(tkMinus, '-', FLine, LStartColumn, LStartPos));
    '*': FTokens.Add(MakeTokenAt(tkStar, '*', FLine, LStartColumn, LStartPos));
    '/': FTokens.Add(MakeTokenAt(tkSlash, '/', FLine, LStartColumn, LStartPos));
    '^': FTokens.Add(MakeTokenAt(tkCaret, '^', FLine, LStartColumn, LStartPos));
  else
    // Unknown character - pass through as-is for C++ compatibility
    FTokens.Add(MakeTokenAt(tkIdentifier, LChar, FLine, LStartColumn, LStartPos));
  end;
end;

function TLexer.Process(const ASource: string; const AFilename: string; const AErrors: TErrors): TArray<TToken>;
begin
  FSource := ASource;
  FFilename := AFilename;
  FErrors := AErrors;
  FPos := 1;
  FLine := 1;
  FColumn := 1;
  FTokens.Clear();

  while not IsEOF() do
    ScanToken();

  if (FTokens.Count = 0) or (FTokens[FTokens.Count - 1].Kind <> tkEOF) then
    FTokens.Add(MakeToken(tkEOF, ''));

  Result := FTokens.ToArray();
end;

end.
