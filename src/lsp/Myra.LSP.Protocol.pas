{===============================================================================
  Myra™ Language Server Protocol - JSON-RPC Transport

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit Myra.LSP.Protocol;

{$I ..\compiler\Myra.Defines.inc}

interface

uses
  WinAPI.Windows,
  System.SysUtils,
  System.Classes,
  System.JSON;

type
  { TLSPProtocol }
  TLSPProtocol = class
  private
    FInputStream: THandleStream;
    FOutputStream: THandleStream;
    FInputHandle: THandle;
    FParentProcessHandle: THandle;
    FShutdownRequested: Boolean;
    FLogEnabled: Boolean;
    FLogFile: TextFile;

    function ReadHeaders(out AContentLength: Integer): Boolean;
    function ReadContent(const ALength: Integer): string;
    procedure WriteContent(const AContent: string);
    function IsInputAvailable(): Boolean;

  public
    constructor Create();
    destructor Destroy(); override;

    procedure Log(const AMessage: string); overload;
    procedure Log(const AFormat: string; const AArgs: array of const); overload;

    function ReadMessage(out AMessage: TJSONObject): Boolean;
    procedure WriteMessage(const AMessage: TJSONObject);

    procedure SendResponse(const AId: TJSONValue; const AResult: TJSONValue);
    procedure SendError(const AId: TJSONValue; const ACode: Integer; const AMessage: string);
    procedure SendNotification(const AMethod: string; const AParams: TJSONObject);

    property LogEnabled: Boolean read FLogEnabled write FLogEnabled;
    property ShutdownRequested: Boolean read FShutdownRequested;
  end;

const
  // LSP Error Codes
  LSP_ERROR_PARSE_ERROR = -32700;
  LSP_ERROR_INVALID_REQUEST = -32600;
  LSP_ERROR_METHOD_NOT_FOUND = -32601;
  LSP_ERROR_INVALID_PARAMS = -32602;
  LSP_ERROR_INTERNAL_ERROR = -32603;
  LSP_ERROR_SERVER_NOT_INITIALIZED = -32002;
  LSP_ERROR_UNKNOWN_ERROR_CODE = -32001;
  LSP_ERROR_REQUEST_CANCELLED = -32800;
  LSP_ERROR_CONTENT_MODIFIED = -32801;

implementation

uses
  WinAPI.TlHelp32;

function GetParentProcessId(): DWORD;
var
  LSnapshot: THandle;
  LEntry: TProcessEntry32;
  LCurrentPid: DWORD;
begin
  Result := 0;
  LCurrentPid := GetCurrentProcessId();
  LSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if LSnapshot <> INVALID_HANDLE_VALUE then
  begin
    try
      LEntry.dwSize := SizeOf(TProcessEntry32);
      if Process32First(LSnapshot, LEntry) then
      begin
        repeat
          if LEntry.th32ProcessID = LCurrentPid then
          begin
            Result := LEntry.th32ParentProcessID;
            Break;
          end;
        until not Process32Next(LSnapshot, LEntry);
      end;
    finally
      CloseHandle(LSnapshot);
    end;
  end;
end;

{ TLSPProtocol }

constructor TLSPProtocol.Create();
var
  LLogPath: string;
  LParentPid: DWORD;
begin
  inherited Create();

  // Use standard input/output
  FInputHandle := GetStdHandle(STD_INPUT_HANDLE);
  FInputStream := THandleStream.Create(FInputHandle);
  FOutputStream := THandleStream.Create(GetStdHandle(STD_OUTPUT_HANDLE));

  // Get parent process handle for monitoring
  LParentPid := GetParentProcessId();
  if LParentPid <> 0 then
    FParentProcessHandle := OpenProcess(SYNCHRONIZE, False, LParentPid)
  else
    FParentProcessHandle := 0;

  FShutdownRequested := False;

  // Enable logging for debugging (optional)
  FLogEnabled := True;

  if FLogEnabled then
  begin
    LLogPath := ExtractFilePath(ParamStr(0)) + 'myralsp.log';
    AssignFile(FLogFile, LLogPath);
    Rewrite(FLogFile);
  end;
end;

destructor TLSPProtocol.Destroy();
begin
  if FLogEnabled then
    CloseFile(FLogFile);

  if FParentProcessHandle <> 0 then
    CloseHandle(FParentProcessHandle);

  FInputStream.Free();
  FOutputStream.Free();

  inherited;
end;

procedure TLSPProtocol.Log(const AMessage: string);
begin
  if FLogEnabled then
  begin
    WriteLn(FLogFile, '[' + FormatDateTime('hh:nn:ss.zzz', Now) + '] ' + AMessage);
    Flush(FLogFile);
  end;
end;

procedure TLSPProtocol.Log(const AFormat: string; const AArgs: array of const);
begin
  Log(Format(AFormat, AArgs));
end;

function TLSPProtocol.IsInputAvailable(): Boolean;
var
  LBytesAvailable: DWORD;
begin
  Result := False;
  
  // Already shutting down?
  if FShutdownRequested then
    Exit;
  
  // Check if parent process is still alive
  if FParentProcessHandle <> 0 then
  begin
    if WaitForSingleObject(FParentProcessHandle, 0) <> WAIT_TIMEOUT then
    begin
      Log('Parent process terminated');
      FShutdownRequested := True;
      Exit;
    end;
  end;
  
  // Check if input data is available on the pipe
  LBytesAvailable := 0;
  if PeekNamedPipe(FInputHandle, nil, 0, nil, @LBytesAvailable, nil) then
    Result := LBytesAvailable > 0
  else
  begin
    // Pipe error (broken pipe) - parent likely closed
    Log('Stdin pipe error');
    FShutdownRequested := True;
    Exit;
  end;
end;

function TLSPProtocol.ReadHeaders(out AContentLength: Integer): Boolean;
var
  LLine: string;
  LChar: AnsiChar;
  LBytesRead: Integer;
  LPos: Integer;
begin
  Result := False;
  AContentLength := 0;

  // Read headers line by line until empty line
  while True do
  begin
    LLine := '';

    // Read until CRLF
    while True do
    begin
      // Wait for input or detect shutdown
      while not IsInputAvailable() do
      begin
        if FShutdownRequested then
          Exit; // Exit cleanly
        Sleep(10); // Small delay to avoid busy-waiting
      end;
        
      LBytesRead := FInputStream.Read(LChar, 1);
      if LBytesRead = 0 then
        Exit; // EOF

      if LChar = #13 then
      begin
        // Read the LF
        FInputStream.Read(LChar, 1);
        Break;
      end;

      LLine := LLine + string(LChar);
    end;

    // Empty line marks end of headers
    if LLine = '' then
      Break;

    // Parse Content-Length header
    LPos := Pos('Content-Length:', LLine);
    if LPos = 1 then
    begin
      AContentLength := StrToIntDef(Trim(Copy(LLine, 16, MaxInt)), 0);
    end;
  end;

  Result := AContentLength > 0;
end;

function TLSPProtocol.ReadContent(const ALength: Integer): string;
var
  LBuffer: TBytes;
  LBytesRead: Integer;
  LTotalRead: Integer;
begin
  SetLength(LBuffer, ALength);
  LTotalRead := 0;

  while LTotalRead < ALength do
  begin
    LBytesRead := FInputStream.Read(LBuffer[LTotalRead], ALength - LTotalRead);
    if LBytesRead = 0 then
      Break;
    Inc(LTotalRead, LBytesRead);
  end;

  Result := TEncoding.UTF8.GetString(LBuffer);
end;

procedure TLSPProtocol.WriteContent(const AContent: string);
var
  LBody: TBytes;
  LHeader: AnsiString;
begin
  LBody := TEncoding.UTF8.GetBytes(AContent);
  LHeader := AnsiString(Format('Content-Length: %d'#13#10#13#10, [Length(LBody)]));

  FOutputStream.Write(LHeader[1], Length(LHeader));
  if Length(LBody) > 0 then
    FOutputStream.Write(LBody[0], Length(LBody));
end;

function TLSPProtocol.ReadMessage(out AMessage: TJSONObject): Boolean;
var
  LContentLength: Integer;
  LContent: string;
  LValue: TJSONValue;
begin
  Result := False;
  AMessage := nil;

  if not ReadHeaders(LContentLength) then
    Exit;

  LContent := ReadContent(LContentLength);
  Log('>> ' + LContent);

  try
    LValue := TJSONObject.ParseJSONValue(LContent);
    if Assigned(LValue) and (LValue is TJSONObject) then
    begin
      AMessage := TJSONObject(LValue);
      Result := True;
    end
    else if Assigned(LValue) then
      LValue.Free();
  except
    on E: Exception do
      Log('Parse error: ' + E.Message);
  end;
end;

procedure TLSPProtocol.WriteMessage(const AMessage: TJSONObject);
var
  LContent: string;
begin
  LContent := AMessage.ToString();
  Log('<< ' + LContent);
  WriteContent(LContent);
end;

procedure TLSPProtocol.SendResponse(const AId: TJSONValue; const AResult: TJSONValue);
var
  LResponse: TJSONObject;
begin
  LResponse := TJSONObject.Create();
  try
    LResponse.AddPair('jsonrpc', '2.0');

    if Assigned(AId) then
      LResponse.AddPair('id', AId.Clone as TJSONValue)
    else
      LResponse.AddPair('id', TJSONNull.Create());

    if Assigned(AResult) then
      LResponse.AddPair('result', AResult)
    else
      LResponse.AddPair('result', TJSONNull.Create());

    WriteMessage(LResponse);
  finally
    LResponse.Free();
  end;
end;

procedure TLSPProtocol.SendError(const AId: TJSONValue; const ACode: Integer; const AMessage: string);
var
  LResponse: TJSONObject;
  LError: TJSONObject;
begin
  LResponse := TJSONObject.Create();
  try
    LResponse.AddPair('jsonrpc', '2.0');

    if Assigned(AId) then
      LResponse.AddPair('id', AId.Clone as TJSONValue)
    else
      LResponse.AddPair('id', TJSONNull.Create());

    LError := TJSONObject.Create();
    LError.AddPair('code', TJSONNumber.Create(ACode));
    LError.AddPair('message', AMessage);
    LResponse.AddPair('error', LError);

    WriteMessage(LResponse);
  finally
    LResponse.Free();
  end;
end;

procedure TLSPProtocol.SendNotification(const AMethod: string; const AParams: TJSONObject);
var
  LNotification: TJSONObject;
begin
  LNotification := TJSONObject.Create();
  try
    LNotification.AddPair('jsonrpc', '2.0');
    LNotification.AddPair('method', AMethod);

    if Assigned(AParams) then
      LNotification.AddPair('params', AParams)
    else
      LNotification.AddPair('params', TJSONObject.Create());

    WriteMessage(LNotification);
  finally
    LNotification.Free();
  end;
end;

end.
