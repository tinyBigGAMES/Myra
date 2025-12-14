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
  LStartPos: Integer;
  LEndPos: Integer;
  LStartLine: Integer;
  LLastToken: TToken;
begin
  Result := TCppBlockNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);
  Result.Target := AParser.FCurrentEmitTarget;

  // Record start position in source
  LStartPos := LToken.StartPos;

  // C++ preprocessor directive: line-terminated
  if LToken.Kind = tkDirective then
  begin
    LStartLine := LToken.Line;
    
    while not AParser.IsAtEnd() and (AParser.Current().Line = LStartLine) do
    begin
      LLastToken := AParser.Current();
      AParser.Advance();
    end;
    
    // Calculate end position from last consumed token
    LEndPos := LLastToken.StartPos + Length(LLastToken.Text);
  end
  else
  begin
    // Original logic: semicolon-terminated
    while not AParser.IsAtEnd() and (AParser.Current().Kind <> tkSemicolon) and
          not (AParser.Current().Kind in [tkEnd, tkElse, tkUntil, tkExcept, tkFinally]) do
    begin
      LLastToken := AParser.Current();
      AParser.Advance();
    end;

    if AParser.Current().Kind = tkSemicolon then
    begin
      LLastToken := AParser.Current();
      AParser.Advance();
    end;
    
    // Calculate end position from last consumed token
    LEndPos := LLastToken.StartPos + Length(LLastToken.Text);
  end;

  // Extract raw source text - exact preservation
  Result.RawText := Copy(AParser.FSource, LStartPos, LEndPos - LStartPos);
end;

function ParseCppExprPassthrough(const AParser: TParser; const ATerminators: array of TTokenKind): TCppPassthroughNode;
var
  LToken: TToken;
  LStartPos: Integer;
  LEndPos: Integer;
  LParenDepth: Integer;
  LBracketDepth: Integer;
  LBraceDepth: Integer;
  I: Integer;
  LIsTerminator: Boolean;
  LLastToken: TToken;
begin
  Result := TCppPassthroughNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  // Record start position in source
  LStartPos := LToken.StartPos;
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

    LLastToken := AParser.Current();
    AParser.Advance();
  end;

  // Calculate end position from last consumed token
  LEndPos := LLastToken.StartPos + Length(LLastToken.Text);

  // Extract raw source text - exact preservation
  Result.RawText := Copy(AParser.FSource, LStartPos, LEndPos - LStartPos);
end;

end.
