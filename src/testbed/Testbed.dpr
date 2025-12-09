{===============================================================================
  Myra™ - Pascal. Refined.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

program Testbed;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  UTestbed in 'UTestbed.pas',
  UTester in 'UTester.pas',
  Myra.AST in '..\compiler\Myra.AST.pas',
  Myra.CodeGen in '..\compiler\Myra.CodeGen.pas',
  Myra.Compiler in '..\compiler\Myra.Compiler.pas',
  Myra.Errors in '..\compiler\Myra.Errors.pas',
  Myra.Lexer in '..\compiler\Myra.Lexer.pas',
  Myra.Parser.Cpp in '..\compiler\Myra.Parser.Cpp.pas',
  Myra.Parser.Declarations in '..\compiler\Myra.Parser.Declarations.pas',
  Myra.Parser.Expressions in '..\compiler\Myra.Parser.Expressions.pas',
  Myra.Parser in '..\compiler\Myra.Parser.pas',
  Myra.Parser.Statements in '..\compiler\Myra.Parser.Statements.pas',
  Myra.Semantic in '..\compiler\Myra.Semantic.pas',
  Myra.Symbols in '..\compiler\Myra.Symbols.pas',
  Myra.Token in '..\compiler\Myra.Token.pas',
  Myra.Utils in '..\compiler\Myra.Utils.pas',
  Myra.Debug in '..\compiler\Myra.Debug.pas',
  Myra.Debug.REPL in '..\compiler\Myra.Debug.REPL.pas';

begin
  RunTestbed();
end.
