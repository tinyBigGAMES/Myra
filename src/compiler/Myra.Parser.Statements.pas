{===============================================================================
  Myra™ - Pascal. Refined.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit Myra.Parser.Statements;

{$I Myra.Defines.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Myra.Token,
  Myra.AST,
  Myra.Parser;

function ParseBlock(const AParser: TParser): TBlockNode;
function ParseStatement(const AParser: TParser): TASTNode;
function ParseIf(const AParser: TParser): TIfNode;
function ParseWhile(const AParser: TParser): TWhileNode;
function ParseFor(const AParser: TParser): TForNode;
function ParseRepeat(const AParser: TParser): TRepeatNode;
function ParseCase(const AParser: TParser): TCaseNode;
function ParseReturn(const AParser: TParser): TReturnNode;
function ParseTry(const AParser: TParser): TTryNode;
function ParseNew(const AParser: TParser): TNewNode;
function ParseDispose(const AParser: TParser): TDisposeNode;
function ParseSetLength(const AParser: TParser): TSetLengthNode;
function ParseAssignmentOrCall(const AParser: TParser): TASTNode;
function ParseInherited(const AParser: TParser): TInheritedCallNode;

implementation

uses
  Myra.Errors,
  Myra.Parser.Cpp,
  Myra.Parser.Expressions;

// Check if there's a ':=' assignment operator before the next statement terminator
function HasAssignAhead(const AParser: TParser): Boolean;
var
  LOffset: Integer;
  LKind: TTokenKind;
begin
  Result := False;
  LOffset := 0;
  while True do
  begin
    LKind := AParser.Peek(LOffset).Kind;
    if LKind = tkAssign then
    begin
      Result := True;
      Exit;
    end;
    if LKind in [tkSemicolon, tkEnd, tkElse, tkUntil, tkExcept, tkFinally, tkEOF] then
      Exit;
    Inc(LOffset);
  end;
end;

function ParseBlock(const AParser: TParser): TBlockNode;
var
  LToken: TToken;
  LStmt: TASTNode;
begin
  Result := TBlockNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  while not AParser.IsAtEnd() and not (AParser.Current().Kind in [tkEnd, tkElse, tkUntil, tkExcept, tkFinally]) do
  begin
    LStmt := ParseStatement(AParser);
    if LStmt <> nil then
      Result.Statements.Add(LStmt);
  end;
end;

// Check if current position looks like the start of a case label
// Case labels are: value[, value...]: where value is integer/char/identifier
// Also handles ranges: value..value:
function IsCaseLabelStart(const AParser: TParser): Boolean;
var
  LKind: TTokenKind;
  LPeekKind: TTokenKind;
begin
  Result := False;

  // First token must be something that can be a case value
  LKind := AParser.Current().Kind;
  if not (LKind in [tkInteger, tkIdentifier, tkChar]) then
    Exit;

  // Check if followed by colon or comma (case label pattern)
  LPeekKind := AParser.Peek().Kind;

  // Handle range: value..value: or value..value,
  if LPeekKind = tkDotDot then
  begin
    // Pattern: value .. value : or value .. value ,
    if AParser.Peek(2).Kind in [tkInteger, tkIdentifier, tkChar] then
      Result := AParser.Peek(3).Kind in [tkColon, tkComma];
    Exit;
  end;

  Result := LPeekKind in [tkColon, tkComma];
end;

// Special block parser for case arm bodies that stops at next case label
function ParseCaseBlock(const AParser: TParser): TBlockNode;
var
  LToken: TToken;
  LStmt: TASTNode;
begin
  Result := TBlockNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  while not AParser.IsAtEnd() and
        not (AParser.Current().Kind in [tkEnd, tkElse, tkUntil, tkExcept, tkFinally]) and
        not IsCaseLabelStart(AParser) do
  begin
    LStmt := ParseStatement(AParser);
    if LStmt <> nil then
      Result.Statements.Add(LStmt);
  end;
end;

function ParseStatement(const AParser: TParser): TASTNode;
var
  LToken: TToken;
begin
  Result := nil;
  LToken := AParser.Current();

  if LToken.Kind = tkIf then
    Result := ParseIf(AParser)
  else if LToken.Kind = tkWhile then
    Result := ParseWhile(AParser)
  else if LToken.Kind = tkFor then
    Result := ParseFor(AParser)
  else if LToken.Kind = tkRepeat then
    Result := ParseRepeat(AParser)
  else if LToken.Kind = tkCase then
    Result := ParseCase(AParser)
  else if LToken.Kind = tkReturn then
    Result := ParseReturn(AParser)
  else if LToken.Kind = tkInherited then
    Result := ParseInherited(AParser)
  else if LToken.Kind = tkTry then
    Result := ParseTry(AParser)
  else if LToken.Kind = tkStartCpp then
    Result := ParseCppBlock(AParser)
  else if LToken.Kind = tkDirective then
  begin
    if SameText(LToken.Text, '#BREAKPOINT') then
    begin
      if Assigned(AParser.FCompiler) then
        AParser.FCompiler.AddBreakpoint(LToken.Filename, LToken.Line + 1);
      AParser.Advance();
      Result := nil;
    end
    else
      Result := ParseCppPassthrough(AParser);
  end
  else if LToken.Kind = tkIdentifier then
  begin
    if SameText(LToken.Text, 'NEW') then
      Result := ParseNew(AParser)
    else if SameText(LToken.Text, 'DISPOSE') then
      Result := ParseDispose(AParser)
    else if SameText(LToken.Text, 'SETLENGTH') then
      Result := ParseSetLength(AParser)
    else
      Result := ParseAssignmentOrCall(AParser);
  end
  else if LToken.Kind = tkSemicolon then
    AParser.Advance()
  else if LToken.Kind = tkSelf then
  begin
    // Self.xxx := value -> Myra assignment (needs := to = conversion)
    // Self.xxx++ or other C++ syntax -> C++ passthrough
    if HasAssignAhead(AParser) then
      Result := ParseAssignmentOrCall(AParser)
    else
      Result := ParseCppPassthrough(AParser);
  end
  else if LToken.Kind in [tkRoutine, tkMethod, tkType, tkConst, tkVar, tkModule, tkImport, tkPublic, tkRecord, tkBegin] then
  begin
    AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E140',
      'Unexpected ''' + LToken.Text + ''' in statement context (missing END?)');
    AParser.Advance();
    Result := nil;
  end
  else
    Result := ParseCppPassthrough(AParser);
end;

function ParseIf(const AParser: TParser): TIfNode;
var
  LToken: TToken;
begin
  Result := TIfNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Expect(tkIf);
  Result.Condition := ParseExpression(AParser);
  AParser.Expect(tkThen);
  Result.ThenBlock := ParseBlock(AParser);

  if AParser.Match(tkElse) then
    Result.ElseBlock := ParseBlock(AParser);

  AParser.Expect(tkEnd);
  AParser.Match(tkSemicolon);
end;

function ParseWhile(const AParser: TParser): TWhileNode;
var
  LToken: TToken;
begin
  Result := TWhileNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Expect(tkWhile);
  Result.Condition := ParseExpression(AParser);
  AParser.Expect(tkDo);
  Result.Body := ParseBlock(AParser);
  AParser.Expect(tkEnd);
  AParser.Match(tkSemicolon);
end;

function ParseFor(const AParser: TParser): TForNode;
var
  LToken: TToken;
begin
  Result := TForNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Expect(tkFor);

  LToken := AParser.Current();
  AParser.Expect(tkIdentifier);
  Result.VarName := LToken.Text;
  Result.VarLine := LToken.Line;
  Result.VarColumn := LToken.Column;

  AParser.Expect(tkAssign);
  Result.StartExpr := ParseExpression(AParser);

  if AParser.Match(tkTo) then
    Result.IsDownTo := False
  else if AParser.Match(tkDownto) then
    Result.IsDownTo := True
  else
    AParser.FErrors.Add(AParser.Current().Filename, AParser.Current().Line, AParser.Current().Column, esError, 'E103',
      'Expected TO or DOWNTO');

  Result.EndExpr := ParseExpression(AParser);
  AParser.Expect(tkDo);
  Result.Body := ParseBlock(AParser);
  AParser.Expect(tkEnd);
  AParser.Match(tkSemicolon);
end;

function ParseRepeat(const AParser: TParser): TRepeatNode;
var
  LToken: TToken;
begin
  Result := TRepeatNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Expect(tkRepeat);
  Result.Body := ParseBlock(AParser);
  AParser.Expect(tkUntil);
  Result.Condition := ParseExpression(AParser);
  AParser.Match(tkSemicolon);
end;

function ParseCase(const AParser: TParser): TCaseNode;
var
  LToken: TToken;
  LBranch: TCaseBranch;
  LValue: TASTNode;
  LLowExpr: TASTNode;
  LHighExpr: TASTNode;
  LRange: TRangeNode;
begin
  Result := TCaseNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Expect(tkCase);
  Result.Expr := ParseExpression(AParser);
  AParser.Expect(tkOf);

  while not AParser.IsAtEnd() and not (AParser.Current().Kind in [tkElse, tkEnd]) do
  begin
    LBranch := TCaseBranch.Create();
    LToken := AParser.Current();
    AParser.SetNodeLocation(LBranch, LToken);

    repeat
      LLowExpr := ParseExpression(AParser);
      
      // Check for range: value..value
      if AParser.Current().Kind = tkDotDot then
      begin
        AParser.Advance(); // consume ..
        LHighExpr := ParseExpression(AParser);
        
        // Create range node
        LRange := TRangeNode.Create();
        AParser.SetNodeLocation(LRange, LToken);
        LRange.LowExpr := LLowExpr;
        LRange.HighExpr := LHighExpr;
        LValue := LRange;
      end
      else
        LValue := LLowExpr;
        
      LBranch.Values.Add(LValue);
    until not AParser.Match(tkComma);

    AParser.Expect(tkColon);
    LBranch.Body := ParseCaseBlock(AParser);

    Result.Branches.Add(LBranch);
  end;

  if AParser.Match(tkElse) then
    Result.ElseBlock := ParseBlock(AParser);

  AParser.Expect(tkEnd);
  AParser.Match(tkSemicolon);
end;

function ParseReturn(const AParser: TParser): TReturnNode;
var
  LToken: TToken;
begin
  Result := TReturnNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Expect(tkReturn);

  if not (AParser.Current().Kind in [tkSemicolon, tkEnd, tkElse, tkUntil]) then
    Result.Value := ParseExpression(AParser);

  AParser.Match(tkSemicolon);
end;

function ParseTry(const AParser: TParser): TTryNode;
var
  LToken: TToken;
begin
  Result := TTryNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Expect(tkTry);
  Result.TryBlock := ParseBlock(AParser);

  if AParser.Match(tkExcept) then
    Result.ExceptBlock := ParseBlock(AParser);

  if AParser.Match(tkFinally) then
    Result.FinallyBlock := ParseBlock(AParser);

  AParser.Expect(tkEnd);
  AParser.Match(tkSemicolon);
end;

function ParseNew(const AParser: TParser): TNewNode;
var
  LToken: TToken;
begin
  Result := TNewNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Advance();

  AParser.Expect(tkLParen);
  Result.Target := ParseExpression(AParser);

  if AParser.Match(tkAs) then
  begin
    LToken := AParser.Current();
    AParser.Expect(tkIdentifier);
    Result.AsType := LToken.Text;
    Result.AsTypeLine := LToken.Line;
    Result.AsTypeColumn := LToken.Column;
  end;

  AParser.Expect(tkRParen);
  AParser.Match(tkSemicolon);
end;

function ParseDispose(const AParser: TParser): TDisposeNode;
var
  LToken: TToken;
begin
  Result := TDisposeNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Advance();

  AParser.Expect(tkLParen);
  Result.Target := ParseExpression(AParser);
  AParser.Expect(tkRParen);
  AParser.Match(tkSemicolon);
end;

function ParseSetLength(const AParser: TParser): TSetLengthNode;
var
  LToken: TToken;
begin
  Result := TSetLengthNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Advance();

  AParser.Expect(tkLParen);
  Result.Target := ParseExpression(AParser);
  AParser.Expect(tkComma);
  Result.NewSize := ParseExpression(AParser);
  AParser.Expect(tkRParen);
  AParser.Match(tkSemicolon);
end;

function ParseAssignmentOrCall(const AParser: TParser): TASTNode;
var
  LToken: TToken;
  LTarget: TASTNode;
  LAssign: TAssignNode;
  LStartPos: Integer;
begin
  // If current is identifier and next is NOT valid Myra, it's C++ passthrough
  if (AParser.Current().Kind = tkIdentifier) and not AParser.IsMyraStatementContinuation() then
  begin
    Result := ParseCppPassthrough(AParser);
    Exit;
  end;

  LTarget := ParseExpression(AParser);

  if AParser.Match(tkAssign) then
  begin
    LAssign := TAssignNode.Create();
    LToken := AParser.Current();
    AParser.SetNodeLocation(LAssign, LToken);
    LAssign.Target := LTarget;
    
    if AParser.Current().Kind = tkLBracket then
      LAssign.Value := ParseCppExprPassthrough(AParser, [tkSemicolon, tkEnd, tkElse, tkUntil])
    else
    begin
      LStartPos := AParser.FPos;
      LAssign.Value := ParseExpression(AParser);
      
      if not (AParser.Current().Kind in [tkSemicolon, tkEnd, tkElse, tkUntil]) then
      begin
        LAssign.Value.Free();
        AParser.FPos := LStartPos;
        LAssign.Value := ParseCppExprPassthrough(AParser, [tkSemicolon, tkEnd, tkElse, tkUntil]);
      end;
    end;
    
    Result := LAssign;
    AParser.Match(tkSemicolon);
  end
  else
  begin
    Result := LTarget;
    AParser.Match(tkSemicolon);
  end;
end;

function ParseInherited(const AParser: TParser): TInheritedCallNode;
var
  LToken: TToken;
  LArg: TASTNode;
begin
  Result := TInheritedCallNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Expect(tkInherited);

  if AParser.Current().Kind = tkIdentifier then
  begin
    LToken := AParser.Current();
    Result.MethodName := LToken.Text;
    Result.MethodNameLine := LToken.Line;
    Result.MethodNameColumn := LToken.Column;
    AParser.Advance();

    if AParser.Match(tkLParen) then
    begin
      if AParser.Current().Kind <> tkRParen then
      begin
        repeat
          LArg := ParseExpression(AParser);
          Result.Args.Add(LArg);
        until not AParser.Match(tkComma);
      end;
      AParser.Expect(tkRParen);
    end;
  end;

  AParser.Match(tkSemicolon);
end;

end.
