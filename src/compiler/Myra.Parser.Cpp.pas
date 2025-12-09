{===============================================================================
  Myra™ - Pascal. Refined.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit Myra.Parser.Cpp;

{$I Myra.Defines.inc}

interface

uses
  System.SysUtils,
  Myra.Token,
  Myra.AST,
  Myra.Parser;

function ParseCppBlock(const AParser: TParser): TCppBlockNode;
function ParseCppPassthrough(const AParser: TParser): TCppBlockNode;
function ParseCppExprPassthrough(const AParser: TParser; const ATerminators: array of TTokenKind): TCppPassthroughNode;

implementation

function IsWordChar(const AChar: Char): Boolean;
begin
  Result := ((AChar >= 'A') and (AChar <= 'Z')) or
            ((AChar >= 'a') and (AChar <= 'z')) or
            ((AChar >= '0') and (AChar <= '9')) or
            (AChar = '_');
end;

function IsWordToken(const AText: string): Boolean;
begin
  Result := (Length(AText) > 0) and IsWordChar(AText[1]);
end;

function ParseCppBlock(const AParser: TParser): TCppBlockNode;
var
  LToken: TToken;
begin
  Result := TCppBlockNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Expect(tkStartCpp);

  // Default to source
  Result.Target := AParser.FCurrentEmitTarget;

  // Check for optional "header" or "source" target
  LToken := AParser.Current();
  if LToken.Kind = tkIdentifier then
  begin
    if SameText(LToken.Text, 'header') then
    begin
      Result.Target := ctHeader;
      AParser.Advance();
    end
    else if SameText(LToken.Text, 'source') then
    begin
      Result.Target := ctSource;
      AParser.Advance();
    end;
    // If neither, leave it as identifier for C++ block content
  end;

  LToken := AParser.Current();
  if LToken.Kind = tkCppBlock then
  begin
    Result.RawText := LToken.Text;
    AParser.Advance();
  end;

  AParser.Expect(tkEndCpp);
end;

function ParseCppPassthrough(const AParser: TParser): TCppBlockNode;
var
  LToken: TToken;
  LText: string;
  LPrevText: string;
  LCurrText: string;
  LStartLine: Integer;
begin
  Result := TCppBlockNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);
  Result.Target := AParser.FCurrentEmitTarget;

  LText := '';
  LPrevText := '';

  // C++ preprocessor directive: line-terminated
  if LToken.Kind = tkDirective then
  begin
    LStartLine := LToken.Line;
    
    while not AParser.IsAtEnd() and (AParser.Current().Line = LStartLine) do
    begin
      LCurrText := AParser.Current().Text;

      if LText <> '' then
      begin
        // After preprocessor directive keyword (starts with #), always add space
        if (Length(LPrevText) > 0) and (LPrevText[1] = '#') then
          LText := LText + ' '
        // Between two word tokens, add space (but not for hex literals like 0x...)
        else if IsWordToken(LPrevText) and IsWordToken(LCurrText) then
        begin
          if not ((LPrevText = '0') and (Length(LCurrText) > 0) and CharInSet(LCurrText[1], ['x', 'X'])) then
            LText := LText + ' ';
        end;
      end;

      LText := LText + LCurrText;
      LPrevText := LCurrText;
      AParser.Advance();
    end;
  end
  else
  begin
    // Original logic: semicolon-terminated
    while not AParser.IsAtEnd() and (AParser.Current().Kind <> tkSemicolon) and
          not (AParser.Current().Kind in [tkEnd, tkElse, tkUntil, tkExcept, tkFinally]) do
    begin
      LCurrText := AParser.Current().Text;

      if LText <> '' then
      begin
        // Only add space between word tokens that would merge without it
        // (identifiers, keywords, numbers). Operators and punctuation don't need spacing.
        // But not for hex literals like 0x...
        if IsWordToken(LPrevText) and IsWordToken(LCurrText) then
        begin
          if not ((LPrevText = '0') and (Length(LCurrText) > 0) and CharInSet(LCurrText[1], ['x', 'X'])) then
            LText := LText + ' ';
        end;
      end;

      LText := LText + LCurrText;
      LPrevText := LCurrText;
      AParser.Advance();
    end;

    if AParser.Current().Kind = tkSemicolon then
    begin
      LText := LText + ';';
      AParser.Advance();
    end;
  end;

  Result.RawText := LText;
end;

function ParseCppExprPassthrough(const AParser: TParser; const ATerminators: array of TTokenKind): TCppPassthroughNode;
var
  LToken: TToken;
  LText: string;
  LPrevText: string;
  LCurrText: string;
  LParenDepth: Integer;
  LBracketDepth: Integer;
  LBraceDepth: Integer;
  I: Integer;
  LIsTerminator: Boolean;
begin
  Result := TCppPassthroughNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  LText := '';
  LPrevText := '';
  LParenDepth := 0;
  LBracketDepth := 0;
  LBraceDepth := 0;

  while not AParser.IsAtEnd() do
  begin
    // Check if current token is a terminator (only at depth 0)
    if (LParenDepth = 0) and (LBracketDepth = 0) and (LBraceDepth = 0) then
    begin
      LIsTerminator := False;
      for I := Low(ATerminators) to High(ATerminators) do
      begin
        if AParser.Current().Kind = ATerminators[I] then
        begin
          LIsTerminator := True;
          Break;
        end;
      end;
      if LIsTerminator then
        Break;
    end;

    LCurrText := AParser.Current().Text;

    // Track nesting depth
    if AParser.Current().Kind = tkLParen then
      Inc(LParenDepth)
    else if AParser.Current().Kind = tkRParen then
      Dec(LParenDepth)
    else if AParser.Current().Kind = tkLBracket then
      Inc(LBracketDepth)
    else if AParser.Current().Kind = tkRBracket then
      Dec(LBracketDepth)
    else if AParser.Current().Kind = tkLBrace then
      Inc(LBraceDepth)
    else if AParser.Current().Kind = tkRBrace then
      Dec(LBraceDepth);

    if LText <> '' then
    begin
      // Only add space between word tokens that would merge without it
      // (identifiers, keywords, numbers). Operators and punctuation don't need spacing.
      // But not for hex literals like 0x...
      if IsWordToken(LPrevText) and IsWordToken(LCurrText) then
      begin
        if not ((LPrevText = '0') and (Length(LCurrText) > 0) and CharInSet(LCurrText[1], ['x', 'X'])) then
          LText := LText + ' ';
      end;
    end;

    LText := LText + LCurrText;
    LPrevText := LCurrText;
    AParser.Advance();
  end;

  Result.RawText := LText;
end;

end.
