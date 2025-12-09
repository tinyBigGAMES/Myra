{===============================================================================
  Myra™ - Pascal. Refined.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit Myra.Errors;

{$I Myra.Defines.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Myra.Utils;

const
  MAX_ERRORS = 10;

type
  { ETooManyErrors }
  ETooManyErrors = class(Exception);

  { TErrorSeverity }
  TErrorSeverity = (
    esWarning,
    esError,
    esFatal
  );

  { TError }
  TError = record
    Filename: string;
    Line: Integer;
    Column: Integer;
    Severity: TErrorSeverity;
    Code: string;
    Message: string;

    function ToIDEString(): string;
  end;

  { TErrors }
  TErrors = class(TBaseObject)
  private
    FItems: TList<TError>;

  public
    constructor Create(); override;
    destructor Destroy(); override;

    procedure Add(
      const AFilename: string;
      const ALine: Integer;
      const AColumn: Integer;
      const ASeverity: TErrorSeverity;
      const ACode: string;
      const AMessage: string
    ); overload;

    procedure Add(
      const AFilename: string;
      const ALine: Integer;
      const AColumn: Integer;
      const ASeverity: TErrorSeverity;
      const ACode: string;
      const AMessage: string;
      const AArgs: array of const
    ); overload;

    procedure Add(
      const ASeverity: TErrorSeverity;
      const ACode: string;
      const AMessage: string
    ); overload;

    procedure Add(
      const ASeverity: TErrorSeverity;
      const ACode: string;
      const AMessage: string;
      const AArgs: array of const
    ); overload;

    function HasErrors(): Boolean;
    function HasFatal(): Boolean;
    function Count(): Integer;
    procedure Clear();

    property Items: TList<TError> read FItems;
  end;

implementation

{ TError }

function TError.ToIDEString(): string;
var
  LSeverityStr: string;
begin
  case Severity of
    esWarning: LSeverityStr := 'Warning';
    esError:   LSeverityStr := 'Error';
    esFatal:   LSeverityStr := 'Fatal';
  else
    LSeverityStr := 'unknown';
  end;

  // Simple format when no file location
  if (Line = 0) and (Column = 0) then
    Result := Format('%s %s: %s', [LSeverityStr, Code, Message])
  else
    Result := Format('%s(%d,%d): %s %s: %s', [
      Filename,
      Line,
      Column,
      LSeverityStr,
      Code,
      Message
    ]);
end;

{ TErrors }

constructor TErrors.Create();
begin
  inherited Create();

  FItems := TList<TError>.Create();
end;

destructor TErrors.Destroy();
begin
  FItems.Free();

  inherited Destroy();
end;

procedure TErrors.Add(
  const AFilename: string;
  const ALine: Integer;
  const AColumn: Integer;
  const ASeverity: TErrorSeverity;
  const ACode: string;
  const AMessage: string
);
var
  LError: TError;
  LErrorCount: Integer;
begin
  // Count existing errors (not warnings)
  LErrorCount := 0;
  for LError in FItems do
  begin
    if LError.Severity in [esError, esFatal] then
      Inc(LErrorCount);
  end;

  // Stop adding errors after limit reached, raise exception
  if (ASeverity in [esError, esFatal]) and (LErrorCount >= MAX_ERRORS) then
    raise ETooManyErrors.Create('Too many errors, compilation stopped');

  LError.Filename := AFilename;
  LError.Line := ALine;
  LError.Column := AColumn;
  LError.Severity := ASeverity;
  LError.Code := ACode;
  LError.Message := AMessage;

  FItems.Add(LError);

  // Fatal errors immediately stop compilation
  if ASeverity = esFatal then
    raise Exception.Create(LError.ToIDEString());
end;

procedure TErrors.Add(
  const AFilename: string;
  const ALine: Integer;
  const AColumn: Integer;
  const ASeverity: TErrorSeverity;
  const ACode: string;
  const AMessage: string;
  const AArgs: array of const
);
begin
  Add(AFilename, ALine, AColumn, ASeverity, ACode, Format(AMessage, AArgs));
end;

procedure TErrors.Add(
  const ASeverity: TErrorSeverity;
  const ACode: string;
  const AMessage: string
);
begin
  Add('', 0, 0, ASeverity, ACode, AMessage);
end;

procedure TErrors.Add(
  const ASeverity: TErrorSeverity;
  const ACode: string;
  const AMessage: string;
  const AArgs: array of const
);
begin
  Add('', 0, 0, ASeverity, ACode, Format(AMessage, AArgs));
end;

function TErrors.HasErrors(): Boolean;
var
  LError: TError;
begin
  Result := False;

  for LError in FItems do
  begin
    if LError.Severity in [esError, esFatal] then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TErrors.HasFatal(): Boolean;
var
  LError: TError;
begin
  Result := False;

  for LError in FItems do
  begin
    if LError.Severity = esFatal then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TErrors.Count(): Integer;
begin
  Result := FItems.Count;
end;

procedure TErrors.Clear();
begin
  FItems.Clear();
end;

end.
