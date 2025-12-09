{===============================================================================
  Myra™ Language Server Protocol

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

program MyraLSP;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  UMyraLSP in 'UMyraLSP.pas',
  Myra.LSP.Server in 'Myra.LSP.Server.pas',
  Myra.LSP.Protocol in 'Myra.LSP.Protocol.pas',
  Myra.LSP.Handlers in 'Myra.LSP.Handlers.pas';

begin
  try
    RunLSP();
  except
    on E: Exception do
    begin
      // LSP servers should not write to stdout on error
      // Log to file if needed
      Halt(1);
    end;
  end;
end.
