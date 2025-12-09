{===============================================================================
  Myra™ - Pascal. Refined.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit Myra.Parser;

{$I Myra.Defines.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Myra.Utils,
  Myra.Errors,
  Myra.Token,
  Myra.AST,
  Myra.Compiler;

type
  { TParser }
  TParser = class(TBaseObject)
  public
    FTokens: TArray<TToken>;
    FPos: Integer;
    FErrors: TErrors;
    FCompiler: TCompiler;
    FCurrentABIIsC: Boolean;
    FCurrentEmitTarget: TCppTarget;

    function Current(): TToken;
    function Peek(const AOffset: Integer = 1): TToken;
    procedure Advance();
    function Match(const AKind: TTokenKind): Boolean;
    procedure Expect(const AKind: TTokenKind);
    function IsAtEnd(): Boolean;

    procedure SetNodeLocation(const ANode: TASTNode; const AToken: TToken);
    function ParseTypeName(): string; overload;
    function ParseTypeName(out ALine: Integer; out AColumn: Integer): string; overload;

    constructor Create(); override;
    destructor Destroy(); override;

    function Process(const ATokens: TArray<TToken>; const ACompiler: TCompiler; const AErrors: TErrors): TModuleNode;
  end;

implementation

uses
  Myra.Parser.Declarations;

{ TParser }

constructor TParser.Create();
begin
  inherited Create();
end;

destructor TParser.Destroy();
begin
  inherited Destroy();
end;

function TParser.Current(): TToken;
begin
  if FPos < Length(FTokens) then
    Result := FTokens[FPos]
  else
    Result := FTokens[High(FTokens)];
end;

function TParser.Peek(const AOffset: Integer): TToken;
var
  LIndex: Integer;
begin
  LIndex := FPos + AOffset;
  if (LIndex >= 0) and (LIndex < Length(FTokens)) then
    Result := FTokens[LIndex]
  else
    Result := FTokens[High(FTokens)];
end;

procedure TParser.Advance();
begin
  if FPos < Length(FTokens) then
    Inc(FPos);
end;

function TParser.Match(const AKind: TTokenKind): Boolean;
begin
  if Current().Kind = AKind then
  begin
    Advance();
    Result := True;
  end
  else
    Result := False;
end;

procedure TParser.Expect(const AKind: TTokenKind);
var
  LToken: TToken;
begin
  LToken := Current();
  if LToken.Kind <> AKind then
    FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E100',
      'Expected ' + IntToStr(Ord(AKind)) + ' but found ' + LToken.Text)
  else
    Advance();
end;

function TParser.IsAtEnd(): Boolean;
begin
  Result := Current().Kind = tkEOF;
end;

procedure TParser.SetNodeLocation(const ANode: TASTNode; const AToken: TToken);
begin
  ANode.Filename := AToken.Filename;
  ANode.Line := AToken.Line;
  ANode.Column := AToken.Column;
end;

function TParser.Process(const ATokens: TArray<TToken>; const ACompiler: TCompiler; const AErrors: TErrors): TModuleNode;
begin
  FTokens := ATokens;
  FCompiler := ACompiler;
  FErrors := AErrors;
  FPos := 0;
  FCurrentABIIsC := False;
  FCurrentEmitTarget := ctSource;

  Result := ParseModule(Self);
end;

function TParser.ParseTypeName(): string;
var
  LLine: Integer;
  LColumn: Integer;
begin
  Result := ParseTypeName(LLine, LColumn);
end;

function TParser.ParseTypeName(out ALine: Integer; out AColumn: Integer): string;
var
  LToken: TToken;
  LDepth: Integer;
begin
  Result := '';
  LToken := Current();
  
  // Capture position of the first token of the type name
  ALine := LToken.Line;
  AColumn := LToken.Column;

  if LToken.Kind = tkPointer then
  begin
    Advance();
    Result := 'POINTER';
    if Match(tkTo) then
      Result := Result + ' TO ' + ParseTypeName();
  end
  else if LToken.Kind = tkArray then
  begin
    Result := 'ARRAY';
    Advance();
    if Match(tkLBracket) then
    begin
      if Current().Kind = tkRBracket then
      begin
        Advance();
        Result := Result + '[]';
      end
      else
      begin
        LToken := Current();
        Expect(tkInteger);
        Result := Result + '[' + LToken.Text;
        Expect(tkDotDot);
        LToken := Current();
        Expect(tkInteger);
        Result := Result + '..' + LToken.Text + ']';
        Expect(tkRBracket);
      end;
    end;
    Expect(tkOf);
    Result := Result + ' OF ' + ParseTypeName();
  end
  else if LToken.Kind = tkSet then
  begin
    Result := 'SET';
    Advance();
    Expect(tkOf);
    LToken := Current();
    if LToken.Kind = tkInteger then
    begin
      Expect(tkInteger);
      Result := Result + ' OF ' + LToken.Text;
      Expect(tkDotDot);
      LToken := Current();
      Expect(tkInteger);
      Result := Result + '..' + LToken.Text;
    end
    else
      Result := Result + ' OF ' + ParseTypeName();
  end
  else if LToken.Kind = tkIdentifier then
  begin
    Result := LToken.Text;
    Advance();
    while not IsAtEnd() do
    begin
      LToken := Current();
      if LToken.Kind = tkDot then
      begin
        Result := Result + '.';
        Advance();
        LToken := Current();
        if LToken.Kind = tkIdentifier then
        begin
          Result := Result + LToken.Text;
          Advance();
        end;
      end
      else if (LToken.Kind = tkColon) and (Peek().Kind = tkColon) then
      begin
        Result := Result + '::';
        Advance();
        Advance();
        LToken := Current();
        if LToken.Kind = tkIdentifier then
        begin
          Result := Result + LToken.Text;
          Advance();
        end;
      end
      else if LToken.Kind = tkLess then
      begin
        Result := Result + '<';
        Advance();
        LDepth := 1;
        while not IsAtEnd() and (LDepth > 0) do
        begin
          LToken := Current();
          if LToken.Kind = tkLess then
          begin
            Inc(LDepth);
            Result := Result + '<';
          end
          else if LToken.Kind = tkGreater then
          begin
            Dec(LDepth);
            Result := Result + '>';
          end
          else if LToken.Kind = tkComma then
            Result := Result + ', '
          else if (LToken.Kind = tkColon) and (Peek().Kind = tkColon) then
          begin
            Result := Result + '::';
            Advance();
          end
          else
            Result := Result + LToken.Text;
          Advance();
        end;
      end
      else
        Break;
    end;
  end
  else
  begin
    FErrors.Add(LToken.Filename, LToken.Line, LToken.Column, esError, 'E105',
      'Expected type name but found: ' + LToken.Text);
    Advance();
  end;
end;

end.
