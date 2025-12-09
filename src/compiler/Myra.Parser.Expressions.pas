{===============================================================================
  Myra™ - Pascal. Refined.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit Myra.Parser.Expressions;

{$I Myra.Defines.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Myra.Token,
  Myra.AST,
  Myra.Parser;

function ParseExpression(const AParser: TParser): TASTNode;
function ParseSimpleExpr(const AParser: TParser): TASTNode;
function ParseTerm(const AParser: TParser): TASTNode;
function ParseFactor(const AParser: TParser): TASTNode;
function ParsePrimary(const AParser: TParser): TASTNode;
function ParseSetLiteral(const AParser: TParser): TSetLitNode;
function ParseLen(const AParser: TParser): TLenNode;
function ParseParamCount(const AParser: TParser): TParamCountNode;
function ParseParamStr(const AParser: TParser): TParamStrNode;

implementation

uses
  Myra.Errors,
  Myra.Parser.Cpp;

function IsBuiltInType(const AName: string): Boolean;
var
  LUpper: string;
begin
  LUpper := UpperCase(AName);
  Result := (LUpper = 'BOOLEAN') or
            (LUpper = 'CHAR') or
            (LUpper = 'UCHAR') or
            (LUpper = 'INTEGER') or
            (LUpper = 'UINTEGER') or
            (LUpper = 'FLOAT') or
            (LUpper = 'STRING') or
            (LUpper = 'SET') or
            (LUpper = 'POINTER');
end;

function ParseExpression(const AParser: TParser): TASTNode;
var
  LToken: TToken;
  LRight: TASTNode;
  LBinOp: TBinaryOpNode;
  LTypeCast: TTypeCastNode;
  LTypeTest: TTypeTestNode;
begin
  Result := ParseSimpleExpr(AParser);

  // Relational operators and IS/AS
  while AParser.Current().Kind in [tkEquals, tkNotEquals, tkLess, tkGreater, tkLessEq, tkGreaterEq, tkIn, tkIs, tkAs] do
  begin
    LToken := AParser.Current();
    AParser.Advance();

    if LToken.Kind = tkAs then
    begin
      // Type cast
      LTypeCast := TTypeCastNode.Create();
      AParser.SetNodeLocation(LTypeCast, LToken);
      LTypeCast.Expr := Result;
      LTypeCast.TypeName := AParser.ParseTypeName(LTypeCast.TypeNameLine, LTypeCast.TypeNameColumn);
      Result := LTypeCast;
    end
    else if LToken.Kind = tkIs then
    begin
      // Type test
      LTypeTest := TTypeTestNode.Create();
      AParser.SetNodeLocation(LTypeTest, LToken);
      LTypeTest.Expr := Result;
      LTypeTest.TypeName := AParser.ParseTypeName(LTypeTest.TypeNameLine, LTypeTest.TypeNameColumn);
      Result := LTypeTest;
    end
    else
    begin
      LRight := ParseSimpleExpr(AParser);
      LBinOp := TBinaryOpNode.Create();
      AParser.SetNodeLocation(LBinOp, LToken);
      LBinOp.Left := Result;
      LBinOp.Op := LToken.Kind;
      LBinOp.Right := LRight;
      Result := LBinOp;
    end;
  end;
end;

function ParseSimpleExpr(const AParser: TParser): TASTNode;
var
  LToken: TToken;
  LRight: TASTNode;
  LBinOp: TBinaryOpNode;
begin
  Result := ParseTerm(AParser);

  while AParser.Current().Kind in [tkPlus, tkMinus, tkOr] do
  begin
    LToken := AParser.Current();
    AParser.Advance();
    LRight := ParseTerm(AParser);

    LBinOp := TBinaryOpNode.Create();
    AParser.SetNodeLocation(LBinOp, LToken);
    LBinOp.Left := Result;
    LBinOp.Op := LToken.Kind;
    LBinOp.Right := LRight;
    Result := LBinOp;
  end;
end;

function ParseTerm(const AParser: TParser): TASTNode;
var
  LToken: TToken;
  LRight: TASTNode;
  LBinOp: TBinaryOpNode;
begin
  Result := ParseFactor(AParser);

  while AParser.Current().Kind in [tkStar, tkSlash, tkDiv, tkMod, tkAnd] do
  begin
    LToken := AParser.Current();
    AParser.Advance();
    LRight := ParseFactor(AParser);

    LBinOp := TBinaryOpNode.Create();
    AParser.SetNodeLocation(LBinOp, LToken);
    LBinOp.Left := Result;
    LBinOp.Op := LToken.Kind;
    LBinOp.Right := LRight;
    Result := LBinOp;
  end;
end;

function ParseFactor(const AParser: TParser): TASTNode;
var
  LToken: TToken;
  LUnary: TUnaryOpNode;
begin
  LToken := AParser.Current();

  // Unary operators
  if LToken.Kind in [tkNot, tkMinus, tkPlus] then
  begin
    AParser.Advance();
    LUnary := TUnaryOpNode.Create();
    AParser.SetNodeLocation(LUnary, LToken);
    LUnary.Op := LToken.Kind;
    LUnary.Operand := ParseFactor(AParser);
    Result := LUnary;
  end
  else
    Result := ParsePrimary(AParser);
end;

function ParsePrimary(const AParser: TParser): TASTNode;
var
  LToken: TToken;
  LIdent: TIdentifierNode;
  LCall: TCallNode;
  LField: TFieldAccessNode;
  LIndex: TIndexAccessNode;
  LDeref: TDerefNode;
  LTypeCast: TTypeCastNode;
  LStartPos: Integer;
  LArg: TASTNode;
  LHexStr: string;
begin
  //LStartPos := AParser.FPos;
  LToken := AParser.Current();

  // Literals
  if LToken.Kind = tkInteger then
  begin
    AParser.Advance();
    Result := TIntegerLitNode.Create();
    AParser.SetNodeLocation(Result, LToken);
    // Handle Oberon-style hex: 0FFH
    if (Length(LToken.Text) > 1) and CharInSet(LToken.Text[Length(LToken.Text)], ['H', 'h']) then
    begin
      LHexStr := '$' + Copy(LToken.Text, 1, Length(LToken.Text) - 1);
      TIntegerLitNode(Result).Value := StrToInt64(LHexStr);
    end
    else
      TIntegerLitNode(Result).Value := StrToInt64(LToken.Text);
  end
  else if LToken.Kind = tkFloat then
  begin
    AParser.Advance();
    Result := TFloatLitNode.Create();
    AParser.SetNodeLocation(Result, LToken);
    TFloatLitNode(Result).Value := StrToFloat(LToken.Text);
  end
  else if LToken.Kind = tkString then
  begin
    AParser.Advance();
    Result := TStringLitNode.Create();
    AParser.SetNodeLocation(Result, LToken);
    // Remove quotes
    TStringLitNode(Result).Value := Copy(LToken.Text, 2, Length(LToken.Text) - 2);
  end
  else if LToken.Kind = tkChar then
  begin
    AParser.Advance();
    Result := TCharLitNode.Create();
    AParser.SetNodeLocation(Result, LToken);
    if Length(LToken.Text) >= 2 then
      TCharLitNode(Result).Value := LToken.Text[2];
  end
  else if LToken.Kind = tkWideString then
  begin
    AParser.Advance();
    Result := TWideStringLitNode.Create();
    AParser.SetNodeLocation(Result, LToken);
    // Remove L prefix and quotes: L'text' or L"text" -> text
    TWideStringLitNode(Result).Value := Copy(LToken.Text, 3, Length(LToken.Text) - 3);
  end
  else if LToken.Kind = tkWideChar then
  begin
    AParser.Advance();
    Result := TWideCharLitNode.Create();
    AParser.SetNodeLocation(Result, LToken);
    // Remove L prefix and quotes: L'x' or L"x" -> x
    if Length(LToken.Text) >= 3 then
      TWideCharLitNode(Result).Value := LToken.Text[3];
  end
  else if LToken.Kind = tkNil then
  begin
    AParser.Advance();
    Result := TNilLitNode.Create();
    AParser.SetNodeLocation(Result, LToken);
  end
  // Set literal
  else if LToken.Kind = tkLBrace then
  begin
    Result := ParseSetLiteral(AParser);
  end
  // Parenthesized expression
  else if LToken.Kind = tkLParen then
  begin
    AParser.Advance();
    Result := ParseExpression(AParser);
    AParser.Expect(tkRParen);
  end
  // ParamCount keyword
  else if LToken.Kind = tkParamCount then
  begin
    Result := ParseParamCount(AParser);
  end
  // ParamStr keyword
  else if LToken.Kind = tkParamStr then
  begin
    Result := ParseParamStr(AParser);
  end
  // Identifier (variable, constant, or function call)
  else if LToken.Kind in [tkIdentifier, tkSelf] then
  begin
    // Check for TRUE/FALSE
    if SameText(LToken.Text, 'TRUE') then
    begin
      AParser.Advance();
      Result := TBoolLitNode.Create();
      AParser.SetNodeLocation(Result, LToken);
      TBoolLitNode(Result).Value := True;
    end
    else if SameText(LToken.Text, 'FALSE') then
    begin
      AParser.Advance();
      Result := TBoolLitNode.Create();
      AParser.SetNodeLocation(Result, LToken);
      TBoolLitNode(Result).Value := False;
    end
    // Check for LEN built-in
    else if SameText(LToken.Text, 'LEN') then
    begin
      Result := ParseLen(AParser);
    end
    // Check for C++ template call: identifier<type>(...)
    // Only if followed by < identifier > ( pattern (template call)
    else if (AParser.Peek().Kind = tkLess) and (AParser.Peek(2).Kind = tkIdentifier) and (AParser.Peek(3).Kind = tkGreater) then
    begin
      // C++ template - capture as passthrough
      Result := ParseCppExprPassthrough(AParser, [tkSemicolon, tkComma, tkRParen, tkRBracket, tkAssign, tkThen, tkDo, tkOf, tkEnd, tkElse, tkUntil, tkPlus, tkMinus, tkStar, tkSlash]);
    end
    // Check for C++ namespace: identifier::...
    else if (AParser.Peek().Kind = tkColon) and (AParser.Peek(2).Kind = tkColon) then
    begin
      // C++ namespace - capture as passthrough
      Result := ParseCppExprPassthrough(AParser, [tkSemicolon, tkComma, tkRParen, tkRBracket, tkAssign, tkThen, tkDo, tkOf, tkEnd, tkElse, tkUntil, tkPlus, tkMinus, tkStar, tkSlash]);
    end
    else
    begin
      AParser.Advance();
      LIdent := TIdentifierNode.Create();
      AParser.SetNodeLocation(LIdent, LToken);
      // Handle Self keyword as identifier
      if LToken.Kind = tkSelf then
        LIdent.IdentName := 'Self'
      else
        LIdent.IdentName := LToken.Text;
      Result := LIdent;
    end;
  end
  else
  begin
    AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E104',
      'Unexpected token in expression: ' + LToken.Text);
    AParser.Advance();
    Result := nil;
    Exit;
  end;

  // Postfix operations: field access, index, dereference, call
  while AParser.Current().Kind in [tkDot, tkLBracket, tkCaret, tkLParen] do
  begin
    LToken := AParser.Current();

    if LToken.Kind = tkDot then
    begin
      AParser.Advance();
      LField := TFieldAccessNode.Create();
      AParser.SetNodeLocation(LField, LToken);
      LField.Target := Result;
      LToken := AParser.Current();
      // Accept identifier OR any keyword as field name (C++ fields can be named 'type', etc.)
      if LToken.Kind = tkIdentifier then
      begin
        LField.FieldName := LToken.Text;
        LField.FieldNameLine := LToken.Line;
        LField.FieldNameColumn := LToken.Column;
        AParser.Advance();
      end
      else if LToken.Kind in [tkType, tkConst, tkVar, tkRecord, tkArray, tkSet, tkPointer,
                              tkBegin, tkEnd, tkIf, tkThen, tkElse, tkCase, tkOf, tkWhile,
                              tkDo, tkRepeat, tkUntil, tkFor, tkTo, tkDownto, tkReturn,
                              tkAnd, tkOr, tkNot, tkDiv, tkMod, tkIn, tkIs, tkAs, tkNil,
                              tkTry, tkExcept, tkFinally, tkPublic, tkModule, tkImport,
                              tkRoutine, tkMethod, tkExternal, tkTest, tkSelf, tkInherited] then
      begin
        // Keyword used as C++ field name - passthrough
        LField.FieldName := LToken.Text;
        LField.FieldNameLine := LToken.Line;
        LField.FieldNameColumn := LToken.Column;
        AParser.Advance();
      end
      else
      begin
        AParser.FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E104',
          'Expected field name after dot');
      end;
      Result := LField;
    end
    else if LToken.Kind = tkLBracket then
    begin
      AParser.Advance();
      LIndex := TIndexAccessNode.Create();
      AParser.SetNodeLocation(LIndex, LToken);
      LIndex.Target := Result;
      LIndex.Index := ParseExpression(AParser);
      AParser.Expect(tkRBracket);
      Result := LIndex;
    end
    else if LToken.Kind = tkCaret then
    begin
      AParser.Advance();
      LDeref := TDerefNode.Create();
      AParser.SetNodeLocation(LDeref, LToken);
      LDeref.Target := Result;
      Result := LDeref;
    end
    else if LToken.Kind = tkLParen then
    begin
      // Call on result of previous expression (e.g., Module.Func() or obj.Method())
      // OR type cast for built-in types: FLOAT(expr), INTEGER(expr), etc.
      
      // Check if this is a built-in type cast
      if (Result is TIdentifierNode) and 
         (TIdentifierNode(Result).Qualifier = '') and
         IsBuiltInType(TIdentifierNode(Result).IdentName) then
      begin
        // Type cast: FLOAT(expr), INTEGER(expr), etc.
        LTypeCast := TTypeCastNode.Create();
        AParser.SetNodeLocation(LTypeCast, LToken);
        LTypeCast.TypeName := TIdentifierNode(Result).IdentName;
        LTypeCast.TypeNameLine := TIdentifierNode(Result).Line;
        LTypeCast.TypeNameColumn := TIdentifierNode(Result).Column;
        Result.Free();
        
        AParser.Advance(); // skip (
        LTypeCast.Expr := ParseExpression(AParser);
        AParser.Expect(tkRParen);
        
        Result := LTypeCast;
      end
      else
      begin
        LCall := TCallNode.Create();
        AParser.SetNodeLocation(LCall, LToken);

        // Extract routine name from field access or identifier
        if Result is TFieldAccessNode then
        begin
          LCall.RoutineName := TFieldAccessNode(Result).FieldName;
          LCall.RoutineNameLine := TFieldAccessNode(Result).FieldNameLine;
          LCall.RoutineNameColumn := TFieldAccessNode(Result).FieldNameColumn;
          // Potential method call: obj.Method()
          // Store receiver for semantic analysis to determine if method or module qualifier
          LCall.IsMethodCall := True;
          LCall.Receiver := TFieldAccessNode(Result).Target;
          TFieldAccessNode(Result).Target := nil; // Prevent double-free
          Result.Free();
        end
        else if Result is TIdentifierNode then
        begin
          LCall.RoutineName := TIdentifierNode(Result).IdentName;
          LCall.RoutineNameLine := TIdentifierNode(Result).Line;
          LCall.RoutineNameColumn := TIdentifierNode(Result).Column;
          Result.Free();
        end
        else
        begin
          // Complex expression - can't make a simple call
          LCall.Free();
          Break;
        end;

        AParser.Advance(); // skip (

        if AParser.Current().Kind <> tkRParen then
        begin
          repeat
            LStartPos := AParser.FPos;
            LArg := ParseExpression(AParser);
            
            // If not at expected terminator, backtrack and capture as C++ passthrough
            if not (AParser.Current().Kind in [tkComma, tkRParen]) then
            begin
              LArg.Free();
              AParser.FPos := LStartPos;
              LArg := ParseCppExprPassthrough(AParser, [tkComma, tkRParen]);
            end;
            
            LCall.Args.Add(LArg);
          until not AParser.Match(tkComma);
        end;

        AParser.Expect(tkRParen);
        Result := LCall;
      end;
    end;
  end;
end;

function ParseSetLiteral(const AParser: TParser): TSetLitNode;
var
  LToken: TToken;
  LElement: TASTNode;
  LRange: TRangeNode;
begin
  Result := TSetLitNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Expect(tkLBrace);

  if AParser.Current().Kind <> tkRBrace then
  begin
    repeat
      LElement := ParseExpression(AParser);

      // Check for range: low..high
      if AParser.Match(tkDotDot) then
      begin
        LRange := TRangeNode.Create();
        AParser.SetNodeLocation(LRange, LToken);
        LRange.LowExpr := LElement;
        LRange.HighExpr := ParseExpression(AParser);
        Result.Elements.Add(LRange);
      end
      else
        Result.Elements.Add(LElement);
    until not AParser.Match(tkComma);
  end;

  AParser.Expect(tkRBrace);
end;

function ParseLen(const AParser: TParser): TLenNode;
var
  LToken: TToken;
begin
  Result := TLenNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Advance(); // skip LEN

  AParser.Expect(tkLParen);
  Result.Target := ParseExpression(AParser);
  AParser.Expect(tkRParen);
end;

function ParseParamCount(const AParser: TParser): TParamCountNode;
var
  LToken: TToken;
begin
  Result := TParamCountNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Advance(); // skip PARAMCOUNT

  // ParamCount() - optional parentheses
  if AParser.Current().Kind = tkLParen then
  begin
    AParser.Advance();
    AParser.Expect(tkRParen);
  end;
end;

function ParseParamStr(const AParser: TParser): TParamStrNode;
var
  LToken: TToken;
begin
  Result := TParamStrNode.Create();
  LToken := AParser.Current();
  AParser.SetNodeLocation(Result, LToken);

  AParser.Advance(); // skip PARAMSTR

  AParser.Expect(tkLParen);
  Result.Index := ParseExpression(AParser);
  AParser.Expect(tkRParen);
end;

end.
