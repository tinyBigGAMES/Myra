{===============================================================================
  Myra™ Language Server Protocol - Entry Point

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit UMyraLSP;

interface

procedure RunLSP();

implementation

uses
  System.SysUtils,
  Myra.LSP.Server;

procedure RunLSP();
var
  LServer: TLSPServer;
begin
  LServer := TLSPServer.Create();
  try
    LServer.Run();
  finally
    LServer.Free();
  end;
end;

end.
