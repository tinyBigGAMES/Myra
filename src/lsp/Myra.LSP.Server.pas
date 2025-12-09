{===============================================================================
  Myra™ Language Server Protocol - Main Server

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit Myra.LSP.Server;

{$I ..\compiler\Myra.Defines.inc}

interface

uses
  System.SysUtils,
  System.JSON,
  Myra.LSP.Protocol,
  Myra.LSP.Handlers;

type
  { TLSPServer }
  TLSPServer = class
  private
    FProtocol: TLSPProtocol;
    FHandlers: TLSPHandlers;
    FRunning: Boolean;

    procedure HandleMessage(const AMessage: TJSONObject);
    procedure HandleRequest(const AId: TJSONValue; const AMethod: string; const AParams: TJSONObject);
    procedure HandleNotification(const AMethod: string; const AParams: TJSONObject);

  public
    constructor Create();
    destructor Destroy(); override;

    procedure Run();
    procedure Stop();

    property Protocol: TLSPProtocol read FProtocol;
  end;

implementation

{ TLSPServer }

constructor TLSPServer.Create();
begin
  inherited Create();

  FProtocol := TLSPProtocol.Create();
  FHandlers := TLSPHandlers.Create(FProtocol);
  FRunning := False;
end;

destructor TLSPServer.Destroy();
begin
  FHandlers.Free();
  FProtocol.Free();

  inherited;
end;

procedure TLSPServer.Run();
var
  LMessage: TJSONObject;
begin
  FRunning := True;

  while FRunning do
  begin
    if FProtocol.ReadMessage(LMessage) then
    begin
      try
        HandleMessage(LMessage);
      finally
        LMessage.Free();
      end;
    end
    else
    begin
      // EOF or error - exit
      FRunning := False;
    end;
  end;
end;

procedure TLSPServer.Stop();
begin
  FRunning := False;
end;

procedure TLSPServer.HandleMessage(const AMessage: TJSONObject);
var
  LId: TJSONValue;
  LMethod: string;
  LParams: TJSONObject;
begin
  LMethod := AMessage.GetValue<string>('method', '');
  LParams := AMessage.GetValue<TJSONObject>('params');
  LId := AMessage.GetValue('id');

  if LId <> nil then
    HandleRequest(LId, LMethod, LParams)
  else
    HandleNotification(LMethod, LParams);
end;

procedure TLSPServer.HandleRequest(const AId: TJSONValue; const AMethod: string; const AParams: TJSONObject);
var
  LResult: TJSONValue;
begin
  try
    // Lifecycle
    if AMethod = 'initialize' then
      LResult := FHandlers.HandleInitialize(AParams)
    else if AMethod = 'shutdown' then
      LResult := FHandlers.HandleShutdown()

    // Text Document
    else if AMethod = 'textDocument/completion' then
      LResult := FHandlers.HandleTextDocumentCompletion(AParams)
    else if AMethod = 'textDocument/hover' then
      LResult := FHandlers.HandleTextDocumentHover(AParams)
    else if AMethod = 'textDocument/definition' then
      LResult := FHandlers.HandleTextDocumentDefinition(AParams)
    else if AMethod = 'textDocument/typeDefinition' then
      LResult := FHandlers.HandleTextDocumentTypeDefinition(AParams)
    else if AMethod = 'textDocument/references' then
      LResult := FHandlers.HandleTextDocumentReferences(AParams)
    else if AMethod = 'textDocument/documentHighlight' then
      LResult := FHandlers.HandleTextDocumentDocumentHighlight(AParams)
    else if AMethod = 'textDocument/documentSymbol' then
      LResult := FHandlers.HandleTextDocumentDocumentSymbol(AParams)
    else if AMethod = 'textDocument/signatureHelp' then
      LResult := FHandlers.HandleTextDocumentSignatureHelp(AParams)
    else if AMethod = 'textDocument/codeAction' then
      LResult := FHandlers.HandleTextDocumentCodeAction(AParams)
    else if AMethod = 'textDocument/rename' then
      LResult := FHandlers.HandleTextDocumentRename(AParams)
    else if AMethod = 'textDocument/implementation' then
      LResult := FHandlers.HandleTextDocumentImplementation(AParams)
    else if AMethod = 'textDocument/foldingRange' then
      LResult := FHandlers.HandleTextDocumentFoldingRange(AParams)
    else if AMethod = 'textDocument/selectionRange' then
      LResult := FHandlers.HandleTextDocumentSelectionRange(AParams)
    else if AMethod = 'textDocument/semanticTokens/full' then
      LResult := FHandlers.HandleTextDocumentSemanticTokensFull(AParams)

    // Unknown method
    else
    begin
      FProtocol.SendError(AId, LSP_ERROR_METHOD_NOT_FOUND, 'Method not found: ' + AMethod);
      Exit;
    end;

    FProtocol.SendResponse(AId, LResult);

  except
    on E: Exception do
      FProtocol.SendError(AId, LSP_ERROR_INTERNAL_ERROR, E.Message);
  end;
end;

procedure TLSPServer.HandleNotification(const AMethod: string; const AParams: TJSONObject);
begin
  try
    // Lifecycle
    if AMethod = 'initialized' then
      FHandlers.HandleInitialized(AParams)
    else if AMethod = 'exit' then
      FHandlers.HandleExit()

    // Text Document
    else if AMethod = 'textDocument/didOpen' then
      FHandlers.HandleTextDocumentDidOpen(AParams)
    else if AMethod = 'textDocument/didChange' then
      FHandlers.HandleTextDocumentDidChange(AParams)
    else if AMethod = 'textDocument/didClose' then
      FHandlers.HandleTextDocumentDidClose(AParams)
    else if AMethod = 'textDocument/didSave' then
      FHandlers.HandleTextDocumentDidSave(AParams);

    // Unknown notifications are ignored per LSP spec

  except
    // Notifications don't send error responses
  end;
end;

end.
