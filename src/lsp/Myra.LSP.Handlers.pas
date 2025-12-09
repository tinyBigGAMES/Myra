{===============================================================================
  Myra™ Language Server Protocol - Method Handlers

  Uses TCompiler for full cross-module symbol resolution.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit Myra.LSP.Handlers;

{$I ..\compiler\Myra.Defines.inc}

interface

uses
  WinApi.Windows,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.JSON,
  Myra.Errors,
  Myra.Token,
  Myra.Symbols,
  Myra.Compiler,
  Myra.AST,
  Myra.LSP.Protocol;

const
  // Semantic token types (must match legend order)
  STT_NAMESPACE = 0;
  STT_TYPE = 1;
  STT_PARAMETER = 2;
  STT_VARIABLE = 3;
  STT_PROPERTY = 4;
  STT_FUNCTION = 5;
  STT_KEYWORD = 6;
  STT_NUMBER = 7;
  STT_STRING = 8;
  STT_ENUMMEMBER = 9;

  // Semantic token modifiers (bitmask)
  STM_DECLARATION = 1;
  STM_READONLY = 2;
  STM_DEFAULTLIBRARY = 4;

type
  { TDocumentInfo }
  TDocumentInfo = record
    Uri: string;
    FilePath: string;
    Content: string;
    Version: Integer;
  end;

  { TSemanticToken }
  TSemanticToken = record
    Line: Integer;
    Column: Integer;
    Length: Integer;
    TokenType: Integer;
    Modifiers: Integer;
  end;

  { TLSPHandlers }
  TLSPHandlers = class
  private
    FProtocol: TLSPProtocol;
    FDocuments: TDictionary<string, TDocumentInfo>;
    FCompiler: TCompiler;
    FInitialized: Boolean;
    FShutdownRequested: Boolean;
    FWorkspaceRoot: string;
    FProjectRoot: string;
    FMainSourceFile: string;

    function UriToPath(const AUri: string): string;
    function PathToUri(const APath: string): string;
    function GetDiagnosticSeverity(const ASeverity: TErrorSeverity): Integer;
    
    function FindProjectRoot(const AStartPath: string): string;
    function FindMainSourceFile(const AProjectRoot: string): string;
    procedure RebuildSymbols();
    procedure PublishDiagnostics(const AUri: string);
    
    function GetWordAtPosition(const AContent: string; const ALine: Integer; const AChar: Integer): string;
    function ExtractRoutineNameBeforeParen(const AContent: string; const ALine: Integer; const AChar: Integer; out AModuleName: string): string;
    function GetSymbolKindForLSP(const AKind: TSymbolKind): Integer;
    function GetCompletionKindForLSP(const AKind: TSymbolKind): Integer;
    procedure CollectReferences(const ANode: TASTNode; const ASymbolName: string; const AResults: TList<TASTNode>; const ASyntheticNodes: TObjectList<TASTNode>);
    procedure CollectSemanticTokens(const ANode: TASTNode; const AFilePath: string; const ATokens: TList<TSemanticToken>);
    function EncodeSemanticTokens(const ATokens: TList<TSemanticToken>): TJSONArray;

  public
    constructor Create(const AProtocol: TLSPProtocol);
    destructor Destroy(); override;

    // Lifecycle
    function HandleInitialize(const AParams: TJSONObject): TJSONObject;
    procedure HandleInitialized(const AParams: TJSONObject);
    function HandleShutdown(): TJSONObject;
    procedure HandleExit();

    // Document Synchronization
    procedure HandleTextDocumentDidOpen(const AParams: TJSONObject);
    procedure HandleTextDocumentDidChange(const AParams: TJSONObject);
    procedure HandleTextDocumentDidClose(const AParams: TJSONObject);
    procedure HandleTextDocumentDidSave(const AParams: TJSONObject);

    // Language Features
    function HandleTextDocumentCompletion(const AParams: TJSONObject): TJSONValue;
    function HandleTextDocumentHover(const AParams: TJSONObject): TJSONValue;
    function HandleTextDocumentDefinition(const AParams: TJSONObject): TJSONValue;
    function HandleTextDocumentTypeDefinition(const AParams: TJSONObject): TJSONValue;
    function HandleTextDocumentReferences(const AParams: TJSONObject): TJSONValue;
    function HandleTextDocumentDocumentHighlight(const AParams: TJSONObject): TJSONValue;
    function HandleTextDocumentDocumentSymbol(const AParams: TJSONObject): TJSONValue;
    function HandleTextDocumentSignatureHelp(const AParams: TJSONObject): TJSONValue;
    function HandleTextDocumentCodeAction(const AParams: TJSONObject): TJSONValue;
    function HandleTextDocumentRename(const AParams: TJSONObject): TJSONValue;
    function HandleTextDocumentImplementation(const AParams: TJSONObject): TJSONValue;
    function HandleTextDocumentFoldingRange(const AParams: TJSONObject): TJSONValue;
    function HandleTextDocumentSelectionRange(const AParams: TJSONObject): TJSONValue;
    function HandleTextDocumentSemanticTokensFull(const AParams: TJSONObject): TJSONValue;

    property Initialized: Boolean read FInitialized;
    property ShutdownRequested: Boolean read FShutdownRequested;
  end;

implementation


{ TLSPHandlers }

constructor TLSPHandlers.Create(const AProtocol: TLSPProtocol);
begin
  inherited Create();

  FProtocol := AProtocol;
  FDocuments := TDictionary<string, TDocumentInfo>.Create();
  FCompiler := nil;
  FInitialized := False;
  FShutdownRequested := False;
  FWorkspaceRoot := '';
  FProjectRoot := '';
  FMainSourceFile := '';
end;

destructor TLSPHandlers.Destroy();
begin
  if Assigned(FCompiler) then
    FCompiler.Free();
  FDocuments.Free();

  inherited;
end;

function TLSPHandlers.UriToPath(const AUri: string): string;
begin
  Result := AUri;

  if Result.StartsWith('file:///') then
    Result := Copy(Result, 9, MaxInt)
  else if Result.StartsWith('file://') then
    Result := Copy(Result, 8, MaxInt);

  Result := Result.Replace('%3A', ':', [rfReplaceAll, rfIgnoreCase]);
  Result := Result.Replace('%20', ' ', [rfReplaceAll]);
  Result := Result.Replace('/', '\', [rfReplaceAll]);
end;

function TLSPHandlers.PathToUri(const APath: string): string;
begin
  Result := APath;
  Result := Result.Replace('\', '/', [rfReplaceAll]);
  Result := 'file:///' + Result;
end;

function TLSPHandlers.GetDiagnosticSeverity(const ASeverity: TErrorSeverity): Integer;
begin
  case ASeverity of
    esFatal, esError: Result := 1;
    esWarning: Result := 2;
  else
    Result := 3;
  end;
end;

function TLSPHandlers.GetSymbolKindForLSP(const AKind: TSymbolKind): Integer;
begin
  case AKind of
    skRoutine: Result := 12;   // Function
    skType: Result := 5;       // Class
    skVar: Result := 13;       // Variable
    skConst: Result := 14;     // Constant
    skField: Result := 8;      // Field
    skParam: Result := 13;     // Variable
  else
    Result := 1; // File
  end;
end;

function TLSPHandlers.GetCompletionKindForLSP(const AKind: TSymbolKind): Integer;
begin
  case AKind of
    skRoutine: Result := 3;    // Function
    skType: Result := 7;       // Class
    skVar: Result := 6;        // Variable
    skConst: Result := 21;     // Constant
    skField: Result := 5;      // Field
    skParam: Result := 6;      // Variable
  else
    Result := 1; // Text
  end;
end;

procedure TLSPHandlers.CollectReferences(const ANode: TASTNode; const ASymbolName: string; const AResults: TList<TASTNode>; const ASyntheticNodes: TObjectList<TASTNode>);
var
  LI: Integer;
  LJ: Integer;
  LModule: TModuleNode;
  LRoutine: TRoutineNode;
  LBlock: TBlockNode;
  LIf: TIfNode;
  LWhile: TWhileNode;
  LFor: TForNode;
  LRepeat: TRepeatNode;
  LCase: TCaseNode;
  LBranch: TCaseBranch;
  LTry: TTryNode;
  LTest: TTestNode;
  LRecord: TRecordNode;
  LAssign: TAssignNode;
  LBinary: TBinaryOpNode;
  LUnary: TUnaryOpNode;
  LCall: TCallNode;
  LFieldAccess: TFieldAccessNode;
  LIndexAccess: TIndexAccessNode;
  LDeref: TDerefNode;
  LReturn: TReturnNode;
  LTypeCast: TTypeCastNode;
  LTypeTest: TTypeTestNode;
  LSetLit: TSetLitNode;
  LRange: TRangeNode;
  LNewNode: TNewNode;
  LDisposeNode: TDisposeNode;
  LSetLength: TSetLengthNode;
  LLen: TLenNode;
  LParamStr: TParamStrNode;
  LVarDecl: TVarDeclNode;
  LConstNode: TConstNode;
  LIdent: TIdentifierNode;
  LInherited: TInheritedCallNode;
  LSyntheticIdent: TIdentifierNode;
begin
  if ANode = nil then
    Exit;

  // Check identifier references
  if ANode is TIdentifierNode then
  begin
    LIdent := TIdentifierNode(ANode);
    if SameText(LIdent.IdentName, ASymbolName) then
      AResults.Add(ANode);
  end
  // Check call references
  else if ANode is TCallNode then
  begin
    LCall := TCallNode(ANode);
    // Create synthetic identifier node for the routine name with correct position
    if SameText(LCall.RoutineName, ASymbolName) and (LCall.RoutineNameLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := LCall.RoutineName;
      LSyntheticIdent.Filename := LCall.Filename;
      LSyntheticIdent.Line := LCall.RoutineNameLine;
      LSyntheticIdent.Column := LCall.RoutineNameColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
    // Walk arguments
    for LI := 0 to LCall.Args.Count - 1 do
      CollectReferences(LCall.Args[LI], ASymbolName, AResults, ASyntheticNodes);
    // Walk receiver
    CollectReferences(LCall.Receiver, ASymbolName, AResults, ASyntheticNodes);
  end
  // Check field access
  else if ANode is TFieldAccessNode then
  begin
    LFieldAccess := TFieldAccessNode(ANode);
    // Create synthetic identifier node for the field name with correct position
    if SameText(LFieldAccess.FieldName, ASymbolName) and (LFieldAccess.FieldNameLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := LFieldAccess.FieldName;
      LSyntheticIdent.Filename := LFieldAccess.Filename;
      LSyntheticIdent.Line := LFieldAccess.FieldNameLine;
      LSyntheticIdent.Column := LFieldAccess.FieldNameColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
    CollectReferences(LFieldAccess.Target, ASymbolName, AResults, ASyntheticNodes);
  end
  // Check type references in declarations
  else if ANode is TVarDeclNode then
  begin
    LVarDecl := TVarDeclNode(ANode);
    if SameText(LVarDecl.VarName, ASymbolName) then
      AResults.Add(ANode);
    // Create synthetic node for TypeName
    if SameText(LVarDecl.TypeName, ASymbolName) and (LVarDecl.TypeNameLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := LVarDecl.TypeName;
      LSyntheticIdent.Filename := LVarDecl.Filename;
      LSyntheticIdent.Line := LVarDecl.TypeNameLine;
      LSyntheticIdent.Column := LVarDecl.TypeNameColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
    CollectReferences(LVarDecl.InitValue, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TConstNode then
  begin
    LConstNode := TConstNode(ANode);
    if SameText(LConstNode.ConstName, ASymbolName) then
      AResults.Add(ANode);
    // Create synthetic node for TypeName
    if SameText(LConstNode.TypeName, ASymbolName) and (LConstNode.TypeNameLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := LConstNode.TypeName;
      LSyntheticIdent.Filename := LConstNode.Filename;
      LSyntheticIdent.Line := LConstNode.TypeNameLine;
      LSyntheticIdent.Column := LConstNode.TypeNameColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
    CollectReferences(LConstNode.Value, ASymbolName, AResults, ASyntheticNodes);
  end
  // Module node - walk all children
  else if ANode is TModuleNode then
  begin
    LModule := TModuleNode(ANode);
    for LI := 0 to LModule.Consts.Count - 1 do
      CollectReferences(LModule.Consts[LI], ASymbolName, AResults, ASyntheticNodes);
    for LI := 0 to LModule.Types.Count - 1 do
      CollectReferences(LModule.Types[LI], ASymbolName, AResults, ASyntheticNodes);
    for LI := 0 to LModule.Vars.Count - 1 do
      CollectReferences(LModule.Vars[LI], ASymbolName, AResults, ASyntheticNodes);
    for LI := 0 to LModule.Routines.Count - 1 do
      CollectReferences(LModule.Routines[LI], ASymbolName, AResults, ASyntheticNodes);
    for LI := 0 to LModule.Tests.Count - 1 do
      CollectReferences(LModule.Tests[LI], ASymbolName, AResults, ASyntheticNodes);
    CollectReferences(LModule.Body, ASymbolName, AResults, ASyntheticNodes);
  end
  // Routine node
  else if ANode is TRoutineNode then
  begin
    LRoutine := TRoutineNode(ANode);
    // Create synthetic identifier node for the routine name with correct position
    if SameText(LRoutine.RoutineName, ASymbolName) and (LRoutine.RoutineNameLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := LRoutine.RoutineName;
      LSyntheticIdent.Filename := LRoutine.Filename;
      LSyntheticIdent.Line := LRoutine.RoutineNameLine;
      LSyntheticIdent.Column := LRoutine.RoutineNameColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
    // Create synthetic node for ReturnType
    if SameText(LRoutine.ReturnType, ASymbolName) and (LRoutine.ReturnTypeLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := LRoutine.ReturnType;
      LSyntheticIdent.Filename := LRoutine.Filename;
      LSyntheticIdent.Line := LRoutine.ReturnTypeLine;
      LSyntheticIdent.Column := LRoutine.ReturnTypeColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
    // Create synthetic node for BoundToType (method binding)
    if SameText(LRoutine.BoundToType, ASymbolName) and (LRoutine.BoundToTypeLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := LRoutine.BoundToType;
      LSyntheticIdent.Filename := LRoutine.Filename;
      LSyntheticIdent.Line := LRoutine.BoundToTypeLine;
      LSyntheticIdent.Column := LRoutine.BoundToTypeColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
    // Walk params for TypeName references
    for LI := 0 to LRoutine.Params.Count - 1 do
      CollectReferences(LRoutine.Params[LI], ASymbolName, AResults, ASyntheticNodes);
    for LI := 0 to LRoutine.LocalVars.Count - 1 do
      CollectReferences(LRoutine.LocalVars[LI], ASymbolName, AResults, ASyntheticNodes);
    CollectReferences(LRoutine.Body, ASymbolName, AResults, ASyntheticNodes);
  end
  // Record node
  else if ANode is TRecordNode then
  begin
    LRecord := TRecordNode(ANode);
    // Create synthetic node for ParentType
    if SameText(LRecord.ParentType, ASymbolName) and (LRecord.ParentTypeLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := LRecord.ParentType;
      LSyntheticIdent.Filename := LRecord.Filename;
      LSyntheticIdent.Line := LRecord.ParentTypeLine;
      LSyntheticIdent.Column := LRecord.ParentTypeColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
    for LI := 0 to LRecord.Fields.Count - 1 do
      CollectReferences(LRecord.Fields[LI], ASymbolName, AResults, ASyntheticNodes);
  end
  // Block node
  else if ANode is TBlockNode then
  begin
    LBlock := TBlockNode(ANode);
    for LI := 0 to LBlock.Statements.Count - 1 do
      CollectReferences(LBlock.Statements[LI], ASymbolName, AResults, ASyntheticNodes);
  end
  // Control flow nodes
  else if ANode is TIfNode then
  begin
    LIf := TIfNode(ANode);
    CollectReferences(LIf.Condition, ASymbolName, AResults, ASyntheticNodes);
    CollectReferences(LIf.ThenBlock, ASymbolName, AResults, ASyntheticNodes);
    CollectReferences(LIf.ElseBlock, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TWhileNode then
  begin
    LWhile := TWhileNode(ANode);
    CollectReferences(LWhile.Condition, ASymbolName, AResults, ASyntheticNodes);
    CollectReferences(LWhile.Body, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TForNode then
  begin
    LFor := TForNode(ANode);
    // Create synthetic identifier node for the loop variable with correct position
    if SameText(LFor.VarName, ASymbolName) and (LFor.VarLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := LFor.VarName;
      LSyntheticIdent.Filename := LFor.Filename;
      LSyntheticIdent.Line := LFor.VarLine;
      LSyntheticIdent.Column := LFor.VarColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
    CollectReferences(LFor.StartExpr, ASymbolName, AResults, ASyntheticNodes);
    CollectReferences(LFor.EndExpr, ASymbolName, AResults, ASyntheticNodes);
    CollectReferences(LFor.Body, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TRepeatNode then
  begin
    LRepeat := TRepeatNode(ANode);
    CollectReferences(LRepeat.Body, ASymbolName, AResults, ASyntheticNodes);
    CollectReferences(LRepeat.Condition, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TCaseNode then
  begin
    LCase := TCaseNode(ANode);
    CollectReferences(LCase.Expr, ASymbolName, AResults, ASyntheticNodes);
    for LI := 0 to LCase.Branches.Count - 1 do
    begin
      LBranch := LCase.Branches[LI];
      for LJ := 0 to LBranch.Values.Count - 1 do
        CollectReferences(LBranch.Values[LJ], ASymbolName, AResults, ASyntheticNodes);
      CollectReferences(LBranch.Body, ASymbolName, AResults, ASyntheticNodes);
    end;
    CollectReferences(LCase.ElseBlock, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TTryNode then
  begin
    LTry := TTryNode(ANode);
    CollectReferences(LTry.TryBlock, ASymbolName, AResults, ASyntheticNodes);
    CollectReferences(LTry.ExceptBlock, ASymbolName, AResults, ASyntheticNodes);
    CollectReferences(LTry.FinallyBlock, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TTestNode then
  begin
    LTest := TTestNode(ANode);
    for LI := 0 to LTest.LocalVars.Count - 1 do
      CollectReferences(LTest.LocalVars[LI], ASymbolName, AResults, ASyntheticNodes);
    for LI := 0 to LTest.LocalConsts.Count - 1 do
      CollectReferences(LTest.LocalConsts[LI], ASymbolName, AResults, ASyntheticNodes);
    CollectReferences(LTest.Body, ASymbolName, AResults, ASyntheticNodes);
  end
  // Expression nodes
  else if ANode is TAssignNode then
  begin
    LAssign := TAssignNode(ANode);
    CollectReferences(LAssign.Target, ASymbolName, AResults, ASyntheticNodes);
    CollectReferences(LAssign.Value, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TBinaryOpNode then
  begin
    LBinary := TBinaryOpNode(ANode);
    CollectReferences(LBinary.Left, ASymbolName, AResults, ASyntheticNodes);
    CollectReferences(LBinary.Right, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TUnaryOpNode then
  begin
    LUnary := TUnaryOpNode(ANode);
    CollectReferences(LUnary.Operand, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TIndexAccessNode then
  begin
    LIndexAccess := TIndexAccessNode(ANode);
    CollectReferences(LIndexAccess.Target, ASymbolName, AResults, ASyntheticNodes);
    CollectReferences(LIndexAccess.Index, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TDerefNode then
  begin
    LDeref := TDerefNode(ANode);
    CollectReferences(LDeref.Target, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TReturnNode then
  begin
    LReturn := TReturnNode(ANode);
    CollectReferences(LReturn.Value, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TTypeCastNode then
  begin
    LTypeCast := TTypeCastNode(ANode);
    // Create synthetic node for TypeName
    if SameText(LTypeCast.TypeName, ASymbolName) and (LTypeCast.TypeNameLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := LTypeCast.TypeName;
      LSyntheticIdent.Filename := LTypeCast.Filename;
      LSyntheticIdent.Line := LTypeCast.TypeNameLine;
      LSyntheticIdent.Column := LTypeCast.TypeNameColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
    CollectReferences(LTypeCast.Expr, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TTypeTestNode then
  begin
    LTypeTest := TTypeTestNode(ANode);
    // Create synthetic node for TypeName
    if SameText(LTypeTest.TypeName, ASymbolName) and (LTypeTest.TypeNameLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := LTypeTest.TypeName;
      LSyntheticIdent.Filename := LTypeTest.Filename;
      LSyntheticIdent.Line := LTypeTest.TypeNameLine;
      LSyntheticIdent.Column := LTypeTest.TypeNameColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
    CollectReferences(LTypeTest.Expr, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TSetLitNode then
  begin
    LSetLit := TSetLitNode(ANode);
    for LI := 0 to LSetLit.Elements.Count - 1 do
      CollectReferences(LSetLit.Elements[LI], ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TRangeNode then
  begin
    LRange := TRangeNode(ANode);
    CollectReferences(LRange.LowExpr, ASymbolName, AResults, ASyntheticNodes);
    CollectReferences(LRange.HighExpr, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TNewNode then
  begin
    LNewNode := TNewNode(ANode);
    // Create synthetic node for AsType
    if SameText(LNewNode.AsType, ASymbolName) and (LNewNode.AsTypeLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := LNewNode.AsType;
      LSyntheticIdent.Filename := LNewNode.Filename;
      LSyntheticIdent.Line := LNewNode.AsTypeLine;
      LSyntheticIdent.Column := LNewNode.AsTypeColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
    CollectReferences(LNewNode.Target, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TDisposeNode then
  begin
    LDisposeNode := TDisposeNode(ANode);
    CollectReferences(LDisposeNode.Target, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TSetLengthNode then
  begin
    LSetLength := TSetLengthNode(ANode);
    CollectReferences(LSetLength.Target, ASymbolName, AResults, ASyntheticNodes);
    CollectReferences(LSetLength.NewSize, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TLenNode then
  begin
    LLen := TLenNode(ANode);
    CollectReferences(LLen.Target, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TParamStrNode then
  begin
    LParamStr := TParamStrNode(ANode);
    CollectReferences(LParamStr.Index, ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TInheritedCallNode then
  begin
    LInherited := TInheritedCallNode(ANode);
    // Create synthetic node for MethodName
    if SameText(LInherited.MethodName, ASymbolName) and (LInherited.MethodNameLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := LInherited.MethodName;
      LSyntheticIdent.Filename := LInherited.Filename;
      LSyntheticIdent.Line := LInherited.MethodNameLine;
      LSyntheticIdent.Column := LInherited.MethodNameColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
    for LI := 0 to LInherited.Args.Count - 1 do
      CollectReferences(LInherited.Args[LI], ASymbolName, AResults, ASyntheticNodes);
  end
  // Type declaration nodes - handle base/element/aliased type references
  else if ANode is TPointerTypeNode then
  begin
    // Create synthetic node for BaseType
    if SameText(TPointerTypeNode(ANode).BaseType, ASymbolName) and (TPointerTypeNode(ANode).BaseTypeLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := TPointerTypeNode(ANode).BaseType;
      LSyntheticIdent.Filename := TPointerTypeNode(ANode).Filename;
      LSyntheticIdent.Line := TPointerTypeNode(ANode).BaseTypeLine;
      LSyntheticIdent.Column := TPointerTypeNode(ANode).BaseTypeColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
  end
  else if ANode is TArrayTypeNode then
  begin
    // Create synthetic node for ElementType
    if SameText(TArrayTypeNode(ANode).ElementType, ASymbolName) and (TArrayTypeNode(ANode).ElementTypeLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := TArrayTypeNode(ANode).ElementType;
      LSyntheticIdent.Filename := TArrayTypeNode(ANode).Filename;
      LSyntheticIdent.Line := TArrayTypeNode(ANode).ElementTypeLine;
      LSyntheticIdent.Column := TArrayTypeNode(ANode).ElementTypeColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
  end
  else if ANode is TSetTypeNode then
  begin
    // Create synthetic node for ElementType
    if SameText(TSetTypeNode(ANode).ElementType, ASymbolName) and (TSetTypeNode(ANode).ElementTypeLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := TSetTypeNode(ANode).ElementType;
      LSyntheticIdent.Filename := TSetTypeNode(ANode).Filename;
      LSyntheticIdent.Line := TSetTypeNode(ANode).ElementTypeLine;
      LSyntheticIdent.Column := TSetTypeNode(ANode).ElementTypeColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
  end
  else if ANode is TTypeNode then
  begin
    // Create synthetic node for AliasedType
    if SameText(TTypeNode(ANode).AliasedType, ASymbolName) and (TTypeNode(ANode).AliasedTypeLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := TTypeNode(ANode).AliasedType;
      LSyntheticIdent.Filename := TTypeNode(ANode).Filename;
      LSyntheticIdent.Line := TTypeNode(ANode).AliasedTypeLine;
      LSyntheticIdent.Column := TTypeNode(ANode).AliasedTypeColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
  end
  // Routine type node
  else if ANode is TRoutineTypeNode then
  begin
    // Create synthetic node for ReturnType
    if SameText(TRoutineTypeNode(ANode).ReturnType, ASymbolName) and (TRoutineTypeNode(ANode).ReturnTypeLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := TRoutineTypeNode(ANode).ReturnType;
      LSyntheticIdent.Filename := TRoutineTypeNode(ANode).Filename;
      LSyntheticIdent.Line := TRoutineTypeNode(ANode).ReturnTypeLine;
      LSyntheticIdent.Column := TRoutineTypeNode(ANode).ReturnTypeColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
    // Walk params
    for LI := 0 to TRoutineTypeNode(ANode).Params.Count - 1 do
      CollectReferences(TRoutineTypeNode(ANode).Params[LI], ASymbolName, AResults, ASyntheticNodes);
  end
  else if ANode is TFieldNode then
  begin
    if SameText(TFieldNode(ANode).FieldName, ASymbolName) then
      AResults.Add(ANode);
    // Create synthetic node for TypeName
    if SameText(TFieldNode(ANode).TypeName, ASymbolName) and (TFieldNode(ANode).TypeNameLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := TFieldNode(ANode).TypeName;
      LSyntheticIdent.Filename := TFieldNode(ANode).Filename;
      LSyntheticIdent.Line := TFieldNode(ANode).TypeNameLine;
      LSyntheticIdent.Column := TFieldNode(ANode).TypeNameColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
  end
  // Parameter node
  else if ANode is TParamNode then
  begin
    if SameText(TParamNode(ANode).ParamName, ASymbolName) then
      AResults.Add(ANode);
    // Create synthetic node for TypeName
    if SameText(TParamNode(ANode).TypeName, ASymbolName) and (TParamNode(ANode).TypeNameLine > 0) then
    begin
      LSyntheticIdent := TIdentifierNode.Create();
      LSyntheticIdent.IdentName := TParamNode(ANode).TypeName;
      LSyntheticIdent.Filename := TParamNode(ANode).Filename;
      LSyntheticIdent.Line := TParamNode(ANode).TypeNameLine;
      LSyntheticIdent.Column := TParamNode(ANode).TypeNameColumn;
      ASyntheticNodes.Add(LSyntheticIdent);
      AResults.Add(LSyntheticIdent);
    end;
  end;
end;

function TLSPHandlers.FindProjectRoot(const AStartPath: string): string;
var
  LDir: string;
  LBuildZig: string;
  LSrcDir: string;
begin
  Result := '';
  LDir := AStartPath;

  // Walk up looking for build.zig or src/ directory
  while (LDir <> '') and (Length(LDir) > 3) do
  begin
    LBuildZig := TPath.Combine(LDir, 'build.zig');
    LSrcDir := TPath.Combine(LDir, 'src');

    if TFile.Exists(LBuildZig) or TDirectory.Exists(LSrcDir) then
    begin
      Result := LDir;
      Exit;
    end;

    LDir := TPath.GetDirectoryName(LDir);
  end;
end;

function TLSPHandlers.FindMainSourceFile(const AProjectRoot: string): string;
var
  LProjectName: string;
  LSrcDir: string;
  LMainFile: string;
  LFiles: TArray<string>;
begin
  Result := '';

  if AProjectRoot = '' then
    Exit;

  LProjectName := TPath.GetFileName(AProjectRoot);
  LSrcDir := TPath.Combine(AProjectRoot, 'src');

  // Try src/<projectname>.myra
  LMainFile := TPath.Combine(LSrcDir, LProjectName + '.myra');
  if TFile.Exists(LMainFile) then
  begin
    Result := LMainFile;
    Exit;
  end;

  // Try any .myra file in src/
  if TDirectory.Exists(LSrcDir) then
  begin
    LFiles := TDirectory.GetFiles(LSrcDir, '*.myra');
    if Length(LFiles) > 0 then
    begin
      Result := LFiles[0];
      Exit;
    end;
  end;
end;

procedure TLSPHandlers.RebuildSymbols();
begin
  if FMainSourceFile = '' then
    Exit;

  if FProjectRoot = '' then
    Exit;

  // Create fresh compiler
  if Assigned(FCompiler) then
    FreeAndNil(FCompiler);

  FCompiler := TCompiler.Create();
  
  // Suppress output
  FCompiler.SetOutputCallback(
    procedure(const AText: string)
    begin
      // Silent - no output during LSP operation
    end
  );

  // Setup project
  FCompiler.SetProject(FMainSourceFile, FProjectRoot);

  // Analyze only (no code generation, no Zig build)
  FCompiler.Analyze();
end;

procedure TLSPHandlers.PublishDiagnostics(const AUri: string);
var
  LParams: TJSONObject;
  LDiagnostics: TJSONArray;
  LDiagnostic: TJSONObject;
  LRange: TJSONObject;
  LStart: TJSONObject;
  LEnd: TJSONObject;
  LError: TError;
  LDocInfo: TDocumentInfo;
  LFilePath: string;
begin
  if not FDocuments.TryGetValue(AUri, LDocInfo) then
    Exit;

  LFilePath := LDocInfo.FilePath;

  LParams := TJSONObject.Create();
  LDiagnostics := TJSONArray.Create();

  try
    LParams.AddPair('uri', AUri);

    // Get errors from compiler
    if Assigned(FCompiler) then
    begin
      for LError in FCompiler.Errors.Items do
      begin
        // Only include errors for this file
        if not SameText(LError.FileName, LFilePath) then
          Continue;

        LDiagnostic := TJSONObject.Create();

        LRange := TJSONObject.Create();
        LStart := TJSONObject.Create();
        LStart.AddPair('line', TJSONNumber.Create(LError.Line - 1));
        LStart.AddPair('character', TJSONNumber.Create(LError.Column - 1));
        LEnd := TJSONObject.Create();
        LEnd.AddPair('line', TJSONNumber.Create(LError.Line - 1));
        LEnd.AddPair('character', TJSONNumber.Create(LError.Column + 10));
        LRange.AddPair('start', LStart);
        LRange.AddPair('end', LEnd);

        LDiagnostic.AddPair('range', LRange);
        LDiagnostic.AddPair('severity', TJSONNumber.Create(GetDiagnosticSeverity(LError.Severity)));
        LDiagnostic.AddPair('code', LError.Code);
        LDiagnostic.AddPair('source', 'myra');
        LDiagnostic.AddPair('message', LError.Message);

        LDiagnostics.Add(LDiagnostic);
      end;
    end;

    LParams.AddPair('diagnostics', LDiagnostics);
    FProtocol.SendNotification('textDocument/publishDiagnostics', LParams);
  except
    LParams.Free();
    raise;
  end;
end;

function TLSPHandlers.GetWordAtPosition(const AContent: string; const ALine: Integer; const AChar: Integer): string;
var
  LLines: TArray<string>;
  LCurrentLine: string;
  LI: Integer;
begin
  Result := '';

  LLines := AContent.Split([#10]);
  if (ALine < 0) or (ALine >= Length(LLines)) then
    Exit;

  LCurrentLine := LLines[ALine].TrimRight([#13]);
  if (AChar < 0) or (AChar >= Length(LCurrentLine)) then
    Exit;

  LI := AChar + 1;

  while (LI > 1) and CharInSet(LCurrentLine[LI - 1], ['A'..'Z', 'a'..'z', '0'..'9', '_']) do
    Dec(LI);

  while (LI <= Length(LCurrentLine)) and CharInSet(LCurrentLine[LI], ['A'..'Z', 'a'..'z', '0'..'9', '_']) do
  begin
    Result := Result + LCurrentLine[LI];
    Inc(LI);
  end;
end;

function TLSPHandlers.ExtractRoutineNameBeforeParen(const AContent: string; const ALine: Integer; const AChar: Integer; out AModuleName: string): string;
var
  LLines: TArray<string>;
  LCurrentLine: string;
  LI: Integer;
  LParenDepth: Integer;
begin
  Result := '';
  AModuleName := '';

  LLines := AContent.Split([#10]);
  if (ALine < 0) or (ALine >= Length(LLines)) then
    Exit;

  LCurrentLine := LLines[ALine].TrimRight([#13]);

  LI := AChar;
  LParenDepth := 0;

  while LI > 0 do
  begin
    if LI <= Length(LCurrentLine) then
    begin
      if LCurrentLine[LI] = ')' then
        Inc(LParenDepth)
      else if LCurrentLine[LI] = '(' then
      begin
        if LParenDepth > 0 then
          Dec(LParenDepth)
        else
        begin
          Dec(LI);

          while (LI > 0) and (LI <= Length(LCurrentLine)) and (LCurrentLine[LI] = ' ') do
            Dec(LI);

          while (LI > 0) and (LI <= Length(LCurrentLine)) and CharInSet(LCurrentLine[LI], ['A'..'Z', 'a'..'z', '0'..'9', '_']) do
          begin
            Result := LCurrentLine[LI] + Result;
            Dec(LI);
          end;

          // Check for module prefix (Module.Routine)
          if (LI > 0) and (LI <= Length(LCurrentLine)) and (LCurrentLine[LI] = '.') then
          begin
            Dec(LI);
            while (LI > 0) and (LI <= Length(LCurrentLine)) and CharInSet(LCurrentLine[LI], ['A'..'Z', 'a'..'z', '0'..'9', '_']) do
            begin
              AModuleName := LCurrentLine[LI] + AModuleName;
              Dec(LI);
            end;
          end;

          Exit;
        end;
      end;
    end;
    Dec(LI);
  end;
end;

function TLSPHandlers.HandleInitialize(const AParams: TJSONObject): TJSONObject;
var
  LCapabilities: TJSONObject;
  LTextDocumentSync: TJSONObject;
  LCompletionProvider: TJSONObject;
  LSignatureHelpProvider: TJSONObject;
  LSemanticTokensProvider: TJSONObject;
  LSemanticTokensLegend: TJSONObject;
  LTokenTypes: TJSONArray;
  LTokenModifiers: TJSONArray;
  LServerInfo: TJSONObject;
  LRootUri: string;
begin
  if AParams.TryGetValue<string>('rootUri', LRootUri) then
    FWorkspaceRoot := UriToPath(LRootUri)
  else if AParams.TryGetValue<string>('rootPath', FWorkspaceRoot) then
    { already assigned }
  else
    FWorkspaceRoot := '';

  // Find project root and main source
  if FWorkspaceRoot <> '' then
  begin
    FProjectRoot := FindProjectRoot(FWorkspaceRoot);
    if FProjectRoot <> '' then
      FMainSourceFile := FindMainSourceFile(FProjectRoot);
  end;

  Result := TJSONObject.Create();
  LCapabilities := TJSONObject.Create();

  LTextDocumentSync := TJSONObject.Create();
  LTextDocumentSync.AddPair('openClose', TJSONBool.Create(True));
  LTextDocumentSync.AddPair('change', TJSONNumber.Create(1));
  LTextDocumentSync.AddPair('save', TJSONBool.Create(True));
  LCapabilities.AddPair('textDocumentSync', LTextDocumentSync);

  LCompletionProvider := TJSONObject.Create();
  LCompletionProvider.AddPair('triggerCharacters', TJSONArray.Create().Add('.'));
  LCompletionProvider.AddPair('resolveProvider', TJSONBool.Create(False));
  LCapabilities.AddPair('completionProvider', LCompletionProvider);

  LSignatureHelpProvider := TJSONObject.Create();
  LSignatureHelpProvider.AddPair('triggerCharacters', TJSONArray.Create().Add('(').Add(','));
  LCapabilities.AddPair('signatureHelpProvider', LSignatureHelpProvider);

  LCapabilities.AddPair('hoverProvider', TJSONBool.Create(True));
  LCapabilities.AddPair('definitionProvider', TJSONBool.Create(True));
  LCapabilities.AddPair('typeDefinitionProvider', TJSONBool.Create(True));
  LCapabilities.AddPair('referencesProvider', TJSONBool.Create(True));
  LCapabilities.AddPair('documentSymbolProvider', TJSONBool.Create(True));
  LCapabilities.AddPair('documentHighlightProvider', TJSONBool.Create(True));
  LCapabilities.AddPair('codeActionProvider', TJSONBool.Create(True));
  LCapabilities.AddPair('renameProvider', TJSONBool.Create(True));
  LCapabilities.AddPair('implementationProvider', TJSONBool.Create(True));
  LCapabilities.AddPair('foldingRangeProvider', TJSONBool.Create(True));
  LCapabilities.AddPair('selectionRangeProvider', TJSONBool.Create(True));

  // Semantic tokens provider
  LSemanticTokensProvider := TJSONObject.Create();
  LSemanticTokensLegend := TJSONObject.Create();

  // Token types (order matters - index used in encoding)
  LTokenTypes := TJSONArray.Create();
  LTokenTypes.Add('namespace');   // 0 - modules
  LTokenTypes.Add('type');        // 1 - types
  LTokenTypes.Add('parameter');   // 2 - routine parameters
  LTokenTypes.Add('variable');    // 3 - variables
  LTokenTypes.Add('property');    // 4 - record fields
  LTokenTypes.Add('function');    // 5 - routines/methods
  LTokenTypes.Add('keyword');     // 6 - keywords (reserved)
  LTokenTypes.Add('number');      // 7 - numeric literals (reserved)
  LTokenTypes.Add('string');      // 8 - string literals (reserved)
  LTokenTypes.Add('enumMember');  // 9 - constants

  // Token modifiers (bitmask)
  LTokenModifiers := TJSONArray.Create();
  LTokenModifiers.Add('declaration');    // bit 0 - where symbol is declared
  LTokenModifiers.Add('readonly');       // bit 1 - constants
  LTokenModifiers.Add('defaultLibrary'); // bit 2 - built-in types

  LSemanticTokensLegend.AddPair('tokenTypes', LTokenTypes);
  LSemanticTokensLegend.AddPair('tokenModifiers', LTokenModifiers);
  LSemanticTokensProvider.AddPair('legend', LSemanticTokensLegend);
  LSemanticTokensProvider.AddPair('full', TJSONBool.Create(True));
  LCapabilities.AddPair('semanticTokensProvider', LSemanticTokensProvider);

  Result.AddPair('capabilities', LCapabilities);

  LServerInfo := TJSONObject.Create();
  LServerInfo.AddPair('name', 'Myra Language Server');
  LServerInfo.AddPair('version', '1.0.0');
  Result.AddPair('serverInfo', LServerInfo);
end;

procedure TLSPHandlers.HandleInitialized(const AParams: TJSONObject);
begin
  FInitialized := True;

  // Build initial symbol table
  RebuildSymbols();
end;

function TLSPHandlers.HandleShutdown(): TJSONObject;
begin
  FShutdownRequested := True;
  Result := nil;
end;

procedure TLSPHandlers.HandleExit();
begin
  if FShutdownRequested then
    Halt(0)
  else
    Halt(1);
end;

procedure TLSPHandlers.HandleTextDocumentDidOpen(const AParams: TJSONObject);
var
  LTextDocument: TJSONObject;
  LUri: string;
  LText: string;
  LVersion: Integer;
  LDocInfo: TDocumentInfo;
begin
  LTextDocument := AParams.GetValue<TJSONObject>('textDocument');
  LUri := LTextDocument.GetValue<string>('uri');
  LText := LTextDocument.GetValue<string>('text');
  LVersion := LTextDocument.GetValue<Integer>('version', 0);

  LDocInfo.Uri := LUri;
  LDocInfo.FilePath := UriToPath(LUri);
  LDocInfo.Content := LText;
  LDocInfo.Version := LVersion;

  FDocuments.AddOrSetValue(LUri, LDocInfo);

  // Rebuild symbols and publish diagnostics
  RebuildSymbols();
  PublishDiagnostics(LUri);
end;

procedure TLSPHandlers.HandleTextDocumentDidChange(const AParams: TJSONObject);
var
  LTextDocument: TJSONObject;
  LUri: string;
  LVersion: Integer;
  LContentChanges: TJSONArray;
  LChange: TJSONObject;
  LText: string;
  LDocInfo: TDocumentInfo;
begin
  LTextDocument := AParams.GetValue<TJSONObject>('textDocument');
  LUri := LTextDocument.GetValue<string>('uri');
  LVersion := LTextDocument.GetValue<Integer>('version', 0);

  LContentChanges := AParams.GetValue<TJSONArray>('contentChanges');
  if LContentChanges.Count > 0 then
  begin
    LChange := LContentChanges.Items[LContentChanges.Count - 1] as TJSONObject;
    LText := LChange.GetValue<string>('text');

    if FDocuments.TryGetValue(LUri, LDocInfo) then
    begin
      LDocInfo.Content := LText;
      LDocInfo.Version := LVersion;
      FDocuments.AddOrSetValue(LUri, LDocInfo);
    end;
  end;

  // Don't rebuild on every keystroke - too slow
  // Rebuild on save instead
end;

procedure TLSPHandlers.HandleTextDocumentDidClose(const AParams: TJSONObject);
var
  LTextDocument: TJSONObject;
  LUri: string;
  LParams: TJSONObject;
begin
  LTextDocument := AParams.GetValue<TJSONObject>('textDocument');
  LUri := LTextDocument.GetValue<string>('uri');

  FDocuments.Remove(LUri);

  LParams := TJSONObject.Create();
  LParams.AddPair('uri', LUri);
  LParams.AddPair('diagnostics', TJSONArray.Create());
  FProtocol.SendNotification('textDocument/publishDiagnostics', LParams);
end;

procedure TLSPHandlers.HandleTextDocumentDidSave(const AParams: TJSONObject);
var
  LTextDocument: TJSONObject;
  LUri: string;
begin
  LTextDocument := AParams.GetValue<TJSONObject>('textDocument');
  LUri := LTextDocument.GetValue<string>('uri');

  // Rebuild symbols on save
  RebuildSymbols();
  PublishDiagnostics(LUri);
end;

function TLSPHandlers.HandleTextDocumentCompletion(const AParams: TJSONObject): TJSONValue;
var
  LTextDocument: TJSONObject;
  LPosition: TJSONObject;
  LUri: string;
  LLine: Integer;
  LChar: Integer;
  LItems: TJSONArray;
  LItem: TJSONObject;
  LDocInfo: TDocumentInfo;
  LKeyword: string;
  LTypeName: string;
  LConstName: string;
  LSymbol: TSymbol;
  LRoutine: TRoutineSymbol;
  LDetail: string;
  LCurrentLine: string;
  LLines: TArray<string>;
  LModuleName: string;
  LDotPos: Integer;
  LTypeSymbol: TTypeSymbol;
  LWalkType: TTypeSymbol;
  LField: TSymbol;
  LMethod: TSymbol;
begin
  LTextDocument := AParams.GetValue<TJSONObject>('textDocument');
  LPosition := AParams.GetValue<TJSONObject>('position');
  LUri := LTextDocument.GetValue<string>('uri');
  LLine := LPosition.GetValue<Integer>('line');
  LChar := LPosition.GetValue<Integer>('character');

  LItems := TJSONArray.Create();

  // Check if after a dot (Module.)
  LModuleName := '';
  if FDocuments.TryGetValue(LUri, LDocInfo) then
  begin
    LLines := LDocInfo.Content.Split([#10]);
    if (LLine >= 0) and (LLine < Length(LLines)) then
    begin
      LCurrentLine := LLines[LLine].TrimRight([#13]);
      
      // Find if we're after Module.
      LDotPos := LChar;
      while (LDotPos > 0) and CharInSet(LCurrentLine[LDotPos], ['A'..'Z', 'a'..'z', '0'..'9', '_']) do
        Dec(LDotPos);
      
      if (LDotPos > 0) and (LCurrentLine[LDotPos] = '.') then
      begin
        // Get module name before dot
        Dec(LDotPos);
        while (LDotPos > 0) and CharInSet(LCurrentLine[LDotPos], ['A'..'Z', 'a'..'z', '0'..'9', '_']) do
        begin
          LModuleName := LCurrentLine[LDotPos] + LModuleName;
          Dec(LDotPos);
        end;
      end;
    end;
  end;

  // If after identifier., check if it's a record variable or module
  if (LModuleName <> '') and Assigned(FCompiler) and Assigned(FCompiler.Symbols) then
  begin
    // First check if it's a variable/param with a record type
    LSymbol := FCompiler.Symbols.Lookup(LModuleName);
    if Assigned(LSymbol) and (LSymbol.Kind in [skVar, skParam, skField]) and
       Assigned(LSymbol.TypeRef) then
    begin
      LTypeSymbol := LSymbol.TypeRef;
      
      // Show fields and methods from the record type (including inherited)
      LWalkType := LTypeSymbol;
      while Assigned(LWalkType) do
      begin
        // Show fields
        for LField in LWalkType.Fields do
        begin
          LItem := TJSONObject.Create();
          LItem.AddPair('label', LField.SymbolName);
          LItem.AddPair('kind', TJSONNumber.Create(5)); // Field
          
          if Assigned(LField.TypeRef) then
            LItem.AddPair('detail', ': ' + LField.TypeRef.SymbolName);
          
          LItem.AddPair('insertText', LField.SymbolName);
          LItems.Add(LItem);
        end;
        
        // Show methods
        for LMethod in LWalkType.Methods do
        begin
          LItem := TJSONObject.Create();
          LItem.AddPair('label', LMethod.SymbolName);
          LItem.AddPair('kind', TJSONNumber.Create(3)); // Method
          
          if (LMethod is TRoutineSymbol) and Assigned(TRoutineSymbol(LMethod).ReturnType) then
            LItem.AddPair('detail', ': ' + TRoutineSymbol(LMethod).ReturnType.SymbolName);
          
          LItem.AddPair('insertText', LMethod.SymbolName);
          LItems.Add(LItem);
        end;
        
        // Walk up inheritance chain
        LWalkType := LWalkType.BaseType;
      end;
      
      Result := LItems;
      Exit;
    end;
    
    // Otherwise check if it's a module
    for LSymbol in FCompiler.Symbols.GetModuleSymbols(LModuleName) do
    begin
      LItem := TJSONObject.Create();
      LItem.AddPair('label', LSymbol.SymbolName);
      LItem.AddPair('kind', TJSONNumber.Create(GetCompletionKindForLSP(LSymbol.Kind)));
      
      // Build detail string
      LDetail := '';
      if LSymbol is TRoutineSymbol then
      begin
        LRoutine := TRoutineSymbol(LSymbol);
        if Assigned(LRoutine.ReturnType) then
          LDetail := ': ' + LRoutine.ReturnType.SymbolName;
      end
      else if Assigned(LSymbol.TypeRef) then
        LDetail := ': ' + LSymbol.TypeRef.SymbolName;
      
      if LDetail <> '' then
        LItem.AddPair('detail', LDetail);
      
      LItem.AddPair('insertText', LSymbol.SymbolName);
      LItems.Add(LItem);
    end;
    
    Result := LItems;
    Exit;
  end;

  // Add symbols from all modules for general completion
  if Assigned(FCompiler) and Assigned(FCompiler.Symbols) then
  begin
    for LSymbol in FCompiler.Symbols.GetAllSymbols() do
    begin
      LItem := TJSONObject.Create();
      LItem.AddPair('label', LSymbol.SymbolName);
      LItem.AddPair('kind', TJSONNumber.Create(GetCompletionKindForLSP(LSymbol.Kind)));
      
      // Build detail string
      LDetail := '';
      if LSymbol is TRoutineSymbol then
      begin
        LRoutine := TRoutineSymbol(LSymbol);
        if Assigned(LRoutine.ReturnType) then
          LDetail := ': ' + LRoutine.ReturnType.SymbolName;
      end
      else if Assigned(LSymbol.TypeRef) then
        LDetail := ': ' + LSymbol.TypeRef.SymbolName;
      
      if LDetail <> '' then
        LItem.AddPair('detail', LDetail);
      
      LItem.AddPair('insertText', LSymbol.SymbolName);
      LItems.Add(LItem);
    end;
  end;

  // Keywords (45 total)
  for LKeyword in ['MODULE', 'IMPORT', 'PUBLIC', 'CONST', 'TYPE', 'VAR',
                   'ROUTINE', 'BEGIN', 'END', 'IF', 'THEN', 'ELSE', 'CASE', 'OF',
                   'WHILE', 'DO', 'REPEAT', 'UNTIL', 'FOR', 'TO', 'DOWNTO',
                   'RETURN', 'ARRAY', 'RECORD', 'SET', 'POINTER', 'NIL',
                   'AND', 'OR', 'NOT', 'DIV', 'MOD', 'IN', 'IS', 'AS',
                   'TRY', 'EXCEPT', 'FINALLY', 'TEST', 'EXTERNAL', 'METHOD',
                   'SELF', 'INHERITED', 'PARAMCOUNT', 'PARAMSTR'] do
  begin
    LItem := TJSONObject.Create();
    LItem.AddPair('label', LKeyword);
    LItem.AddPair('kind', TJSONNumber.Create(14));
    LItem.AddPair('insertText', LKeyword);
    LItems.Add(LItem);
  end;

  // Built-in types (7 native Myra types)
  for LTypeName in ['INTEGER', 'UINTEGER', 'FLOAT', 'STRING', 'BOOLEAN', 'CHAR', 'UCHAR'] do
  begin
    LItem := TJSONObject.Create();
    LItem.AddPair('label', LTypeName);
    LItem.AddPair('kind', TJSONNumber.Create(22));
    LItem.AddPair('insertText', LTypeName);
    LItems.Add(LItem);
  end;

  // Built-in constants
  for LConstName in ['TRUE', 'FALSE'] do
  begin
    LItem := TJSONObject.Create();
    LItem.AddPair('label', LConstName);
    LItem.AddPair('kind', TJSONNumber.Create(21));
    LItem.AddPair('insertText', LConstName);
    LItems.Add(LItem);
  end;

  Result := LItems;
end;

function TLSPHandlers.HandleTextDocumentHover(const AParams: TJSONObject): TJSONValue;
var
  LTextDocument: TJSONObject;
  LPosition: TJSONObject;
  LUri: string;
  LLine: Integer;
  LChar: Integer;
  LDocInfo: TDocumentInfo;
  LWord: string;
  LContents: TJSONObject;
  LResult: TJSONObject;
  LHoverText: string;
  LSymbol: TSymbol;
  LRoutine: TRoutineSymbol;
  LParam: TSymbol;
  LParamStr: string;
  LI: Integer;
begin
  Result := TJSONNull.Create();

  LTextDocument := AParams.GetValue<TJSONObject>('textDocument');
  LPosition := AParams.GetValue<TJSONObject>('position');

  LUri := LTextDocument.GetValue<string>('uri');
  LLine := LPosition.GetValue<Integer>('line');
  LChar := LPosition.GetValue<Integer>('character');

  if not FDocuments.TryGetValue(LUri, LDocInfo) then
    Exit;

  LWord := GetWordAtPosition(LDocInfo.Content, LLine, LChar);
  if LWord = '' then
    Exit;

  LHoverText := '';

  // Check compiler symbols
  if Assigned(FCompiler) and Assigned(FCompiler.Symbols) then
  begin
    LSymbol := FCompiler.Symbols.Lookup(LWord);
    if Assigned(LSymbol) then
    begin
      case LSymbol.Kind of
        skRoutine:
          begin
            if LSymbol is TRoutineSymbol then
            begin
              LRoutine := TRoutineSymbol(LSymbol);
              LParamStr := '';
              for LI := 0 to LRoutine.Params.Count - 1 do
              begin
                LParam := LRoutine.Params[LI];
                if LI > 0 then
                  LParamStr := LParamStr + '; ';
                LParamStr := LParamStr + LParam.SymbolName;
                if Assigned(LParam.TypeRef) then
                  LParamStr := LParamStr + ': ' + LParam.TypeRef.SymbolName;
              end;
              LHoverText := '**routine** ' + LSymbol.SymbolName + '(' + LParamStr + ')';
              if Assigned(LRoutine.ReturnType) then
                LHoverText := LHoverText + ': ' + LRoutine.ReturnType.SymbolName;
            end;
          end;
        skType:
          LHoverText := '**type** ' + LSymbol.SymbolName;
        skVar:
          begin
            LHoverText := '**var** ' + LSymbol.SymbolName;
            if Assigned(LSymbol.TypeRef) then
              LHoverText := LHoverText + ': ' + LSymbol.TypeRef.SymbolName;
          end;
        skConst:
          LHoverText := '**const** ' + LSymbol.SymbolName;
        skField:
          begin
            LHoverText := '**field** ' + LSymbol.SymbolName;
            if Assigned(LSymbol.TypeRef) then
              LHoverText := LHoverText + ': ' + LSymbol.TypeRef.SymbolName;
          end;
      end;
    end;
  end;

  // Fallback to built-in keywords, types, and constants
  if LHoverText = '' then
  begin
    LWord := UpperCase(LWord);

    // Keywords (45 total)
    if LWord = 'MODULE' then LHoverText := '**MODULE** - Declares a module'
    else if LWord = 'IMPORT' then LHoverText := '**IMPORT** - Import other modules'
    else if LWord = 'PUBLIC' then LHoverText := '**PUBLIC** - Export symbol for external access'
    else if LWord = 'CONST' then LHoverText := '**CONST** - Constant declaration section'
    else if LWord = 'TYPE' then LHoverText := '**TYPE** - Type declaration section'
    else if LWord = 'VAR' then LHoverText := '**VAR** - Variable declaration section'
    else if LWord = 'ROUTINE' then LHoverText := '**ROUTINE** - Declare a procedure or function'
    else if LWord = 'BEGIN' then LHoverText := '**BEGIN** - Start of statement block'
    else if LWord = 'END' then LHoverText := '**END** - End of block or module'
    else if LWord = 'IF' then LHoverText := '**IF** - Conditional statement'
    else if LWord = 'THEN' then LHoverText := '**THEN** - Follows IF condition'
    else if LWord = 'ELSE' then LHoverText := '**ELSE** - Alternative branch in IF statement'
    else if LWord = 'CASE' then LHoverText := '**CASE** - Multi-way branch statement'
    else if LWord = 'OF' then LHoverText := '**OF** - Follows CASE expression or ARRAY'
    else if LWord = 'WHILE' then LHoverText := '**WHILE** - Pre-test loop'
    else if LWord = 'DO' then LHoverText := '**DO** - Follows WHILE or FOR'
    else if LWord = 'REPEAT' then LHoverText := '**REPEAT** - Post-test loop'
    else if LWord = 'UNTIL' then LHoverText := '**UNTIL** - Loop termination condition'
    else if LWord = 'FOR' then LHoverText := '**FOR** - Counted loop'
    else if LWord = 'TO' then LHoverText := '**TO** - Ascending loop direction'
    else if LWord = 'DOWNTO' then LHoverText := '**DOWNTO** - Descending loop direction'
    else if LWord = 'RETURN' then LHoverText := '**RETURN** - Return from routine with optional value'
    else if LWord = 'ARRAY' then LHoverText := '**ARRAY** - Array type declaration'
    else if LWord = 'RECORD' then LHoverText := '**RECORD** - Record type declaration'
    else if LWord = 'SET' then LHoverText := '**SET** - Set type declaration'
    else if LWord = 'POINTER' then LHoverText := '**POINTER** - Pointer type declaration'
    else if LWord = 'NIL' then LHoverText := '**NIL** - Null pointer value'
    else if LWord = 'AND' then LHoverText := '**AND** - Logical/bitwise AND operator'
    else if LWord = 'OR' then LHoverText := '**OR** - Logical/bitwise OR operator'
    else if LWord = 'NOT' then LHoverText := '**NOT** - Logical/bitwise NOT operator'
    else if LWord = 'DIV' then LHoverText := '**DIV** - Integer division operator'
    else if LWord = 'MOD' then LHoverText := '**MOD** - Modulo (remainder) operator'
    else if LWord = 'IN' then LHoverText := '**IN** - Set membership test'
    else if LWord = 'IS' then LHoverText := '**IS** - Type test operator'
    else if LWord = 'AS' then LHoverText := '**AS** - Type cast operator'
    else if LWord = 'TRY' then LHoverText := '**TRY** - Start exception handling block'
    else if LWord = 'EXCEPT' then LHoverText := '**EXCEPT** - Exception handler section'
    else if LWord = 'FINALLY' then LHoverText := '**FINALLY** - Cleanup section (always executes)'
    else if LWord = 'TEST' then LHoverText := '**TEST** - Unit test declaration'
    else if LWord = 'EXTERNAL' then LHoverText := '**EXTERNAL** - External routine declaration'
    else if LWord = 'METHOD' then LHoverText := '**METHOD** - Method bound to a type'
    else if LWord = 'SELF' then LHoverText := '**SELF** - Reference to current instance'
    else if LWord = 'INHERITED' then LHoverText := '**INHERITED** - Call parent method'
    else if LWord = 'PARAMCOUNT' then LHoverText := '**PARAMCOUNT** - Number of command-line arguments'
    else if LWord = 'PARAMSTR' then LHoverText := '**PARAMSTR** - Get command-line argument by index'

    // Built-in types (7 native Myra types)
    else if LWord = 'INTEGER' then LHoverText := '**INTEGER** - 32-bit signed integer'
    else if LWord = 'UINTEGER' then LHoverText := '**UINTEGER** - 32-bit unsigned integer'
    else if LWord = 'FLOAT' then LHoverText := '**FLOAT** - 64-bit floating point'
    else if LWord = 'STRING' then LHoverText := '**STRING** - Text string'
    else if LWord = 'BOOLEAN' then LHoverText := '**BOOLEAN** - True or False'
    else if LWord = 'CHAR' then LHoverText := '**CHAR** - 8-bit character'
    else if LWord = 'UCHAR' then LHoverText := '**UCHAR** - 16-bit wide character'

    // Built-in constants
    else if LWord = 'TRUE' then LHoverText := '**TRUE** - Boolean true value'
    else if LWord = 'FALSE' then LHoverText := '**FALSE** - Boolean false value'

    // Module type specifiers
    else if LWord = 'EXE' then LHoverText := '**EXE** - Executable module type'
    else if LWord = 'DLL' then LHoverText := '**DLL** - Dynamic link library module type'
    else if LWord = 'LIB' then LHoverText := '**LIB** - Static library module type';
  end;

  if LHoverText = '' then
    Exit;

  Result.Free();

  LResult := TJSONObject.Create();
  LContents := TJSONObject.Create();
  LContents.AddPair('kind', 'markdown');
  LContents.AddPair('value', LHoverText);
  LResult.AddPair('contents', LContents);

  Result := LResult;
end;

function TLSPHandlers.HandleTextDocumentDefinition(const AParams: TJSONObject): TJSONValue;
var
  LTextDocument: TJSONObject;
  LPosition: TJSONObject;
  LUri: string;
  LLine: Integer;
  LChar: Integer;
  LDocInfo: TDocumentInfo;
  LWord: string;
  LSymbol: TSymbol;
  LResult: TJSONObject;
  LRange: TJSONObject;
  LStart: TJSONObject;
  LEnd: TJSONObject;
  LNode: TASTNode;
begin
  Result := TJSONNull.Create();

  LTextDocument := AParams.GetValue<TJSONObject>('textDocument');
  LPosition := AParams.GetValue<TJSONObject>('position');

  LUri := LTextDocument.GetValue<string>('uri');
  LLine := LPosition.GetValue<Integer>('line');
  LChar := LPosition.GetValue<Integer>('character');

  if not FDocuments.TryGetValue(LUri, LDocInfo) then
    Exit;

  LWord := GetWordAtPosition(LDocInfo.Content, LLine, LChar);
  if LWord = '' then
    Exit;

  if not Assigned(FCompiler) or not Assigned(FCompiler.Symbols) then
    Exit;

  LSymbol := FCompiler.Symbols.Lookup(LWord);
  if not Assigned(LSymbol) then
    Exit;

  LNode := LSymbol.Node;
  if not Assigned(LNode) then
    Exit;

  if LNode.Filename = '' then
    Exit;

  Result.Free();

  LResult := TJSONObject.Create();
  LResult.AddPair('uri', PathToUri(LNode.Filename));

  LRange := TJSONObject.Create();
  LStart := TJSONObject.Create();
  LStart.AddPair('line', TJSONNumber.Create(LNode.Line - 1));
  LStart.AddPair('character', TJSONNumber.Create(LNode.Column - 1));
  LEnd := TJSONObject.Create();
  LEnd.AddPair('line', TJSONNumber.Create(LNode.Line - 1));
  LEnd.AddPair('character', TJSONNumber.Create(LNode.Column - 1 + Length(LSymbol.SymbolName)));
  LRange.AddPair('start', LStart);
  LRange.AddPair('end', LEnd);
  LResult.AddPair('range', LRange);

  Result := LResult;
end;

function TLSPHandlers.HandleTextDocumentTypeDefinition(const AParams: TJSONObject): TJSONValue;
var
  LTextDocument: TJSONObject;
  LPosition: TJSONObject;
  LUri: string;
  LLine: Integer;
  LChar: Integer;
  LDocInfo: TDocumentInfo;
  LWord: string;
  LSymbol: TSymbol;
  LTypeSymbol: TTypeSymbol;
  LResult: TJSONObject;
  LRange: TJSONObject;
  LStart: TJSONObject;
  LEnd: TJSONObject;
  LNode: TASTNode;
begin
  Result := TJSONNull.Create();

  LTextDocument := AParams.GetValue<TJSONObject>('textDocument');
  LPosition := AParams.GetValue<TJSONObject>('position');

  LUri := LTextDocument.GetValue<string>('uri');
  LLine := LPosition.GetValue<Integer>('line');
  LChar := LPosition.GetValue<Integer>('character');

  if not FDocuments.TryGetValue(LUri, LDocInfo) then
    Exit;

  LWord := GetWordAtPosition(LDocInfo.Content, LLine, LChar);
  if LWord = '' then
    Exit;

  if not Assigned(FCompiler) or not Assigned(FCompiler.Symbols) then
    Exit;

  LSymbol := FCompiler.Symbols.Lookup(LWord);
  if not Assigned(LSymbol) then
    Exit;

  // Get the type of the symbol
  LTypeSymbol := LSymbol.TypeRef;
  if not Assigned(LTypeSymbol) then
    Exit;

  // Built-in types have no source location
  if LTypeSymbol.IsBuiltIn then
    Exit;

  LNode := LTypeSymbol.Node;
  if not Assigned(LNode) then
    Exit;

  if LNode.Filename = '' then
    Exit;

  Result.Free();

  LResult := TJSONObject.Create();
  LResult.AddPair('uri', PathToUri(LNode.Filename));

  LRange := TJSONObject.Create();
  LStart := TJSONObject.Create();
  LStart.AddPair('line', TJSONNumber.Create(LNode.Line - 1));
  LStart.AddPair('character', TJSONNumber.Create(LNode.Column - 1));
  LEnd := TJSONObject.Create();
  LEnd.AddPair('line', TJSONNumber.Create(LNode.Line - 1));
  LEnd.AddPair('character', TJSONNumber.Create(LNode.Column - 1 + Length(LTypeSymbol.SymbolName)));
  LRange.AddPair('start', LStart);
  LRange.AddPair('end', LEnd);
  LResult.AddPair('range', LRange);

  Result := LResult;
end;

function TLSPHandlers.HandleTextDocumentReferences(const AParams: TJSONObject): TJSONValue;
var
  LTextDocument: TJSONObject;
  LPosition: TJSONObject;
  LUri: string;
  LLine: Integer;
  LChar: Integer;
  LDocInfo: TDocumentInfo;
  LWord: string;
  LResults: TJSONArray;
  LLocation: TJSONObject;
  LRange: TJSONObject;
  LStart: TJSONObject;
  LEnd: TJSONObject;
  LModule: TModuleNode;
  LReferences: TList<TASTNode>;
  LSyntheticNodes: TObjectList<TASTNode>;
  LNode: TASTNode;
  LModulePair: TPair<string, TModuleNode>;
begin
  LResults := TJSONArray.Create();

  LTextDocument := AParams.GetValue<TJSONObject>('textDocument');
  LPosition := AParams.GetValue<TJSONObject>('position');

  LUri := LTextDocument.GetValue<string>('uri');
  LLine := LPosition.GetValue<Integer>('line');
  LChar := LPosition.GetValue<Integer>('character');

  if not FDocuments.TryGetValue(LUri, LDocInfo) then
  begin
    Result := LResults;
    Exit;
  end;

  LWord := GetWordAtPosition(LDocInfo.Content, LLine, LChar);
  if LWord = '' then
  begin
    Result := LResults;
    Exit;
  end;

  if not Assigned(FCompiler) or not Assigned(FCompiler.Modules) then
  begin
    Result := LResults;
    Exit;
  end;

  // Collect references from all modules
  LReferences := TList<TASTNode>.Create();
  LSyntheticNodes := TObjectList<TASTNode>.Create();
  try
    for LModulePair in FCompiler.Modules do
    begin
      LModule := LModulePair.Value;
      if Assigned(LModule) then
        CollectReferences(LModule, LWord, LReferences, LSyntheticNodes);
    end;

    // Build result array
    for LNode in LReferences do
    begin
      if (LNode.Filename = '') or (LNode.Line < 1) then
        Continue;

      LLocation := TJSONObject.Create();
      LLocation.AddPair('uri', PathToUri(LNode.Filename));

      LRange := TJSONObject.Create();
      LStart := TJSONObject.Create();
      LStart.AddPair('line', TJSONNumber.Create(LNode.Line - 1));
      LStart.AddPair('character', TJSONNumber.Create(LNode.Column - 1));
      LEnd := TJSONObject.Create();
      LEnd.AddPair('line', TJSONNumber.Create(LNode.Line - 1));
      LEnd.AddPair('character', TJSONNumber.Create(LNode.Column - 1 + Length(LWord)));
      LRange.AddPair('start', LStart);
      LRange.AddPair('end', LEnd);
      LLocation.AddPair('range', LRange);

      LResults.Add(LLocation);
    end;
  finally
    LSyntheticNodes.Free();
    LReferences.Free();
  end;

  Result := LResults;
end;

function TLSPHandlers.HandleTextDocumentDocumentHighlight(const AParams: TJSONObject): TJSONValue;
var
  LTextDocument: TJSONObject;
  LPosition: TJSONObject;
  LUri: string;
  LLine: Integer;
  LChar: Integer;
  LDocInfo: TDocumentInfo;
  LFilePath: string;
  LWord: string;
  LResults: TJSONArray;
  LHighlight: TJSONObject;
  LRange: TJSONObject;
  LStart: TJSONObject;
  LEnd: TJSONObject;
  LModule: TModuleNode;
  LReferences: TList<TASTNode>;
  LSyntheticNodes: TObjectList<TASTNode>;
  LNode: TASTNode;
  LModulePair: TPair<string, TModuleNode>;
begin
  LResults := TJSONArray.Create();

  LTextDocument := AParams.GetValue<TJSONObject>('textDocument');
  LPosition := AParams.GetValue<TJSONObject>('position');

  LUri := LTextDocument.GetValue<string>('uri');
  LLine := LPosition.GetValue<Integer>('line');
  LChar := LPosition.GetValue<Integer>('character');

  if not FDocuments.TryGetValue(LUri, LDocInfo) then
  begin
    Result := LResults;
    Exit;
  end;

  LFilePath := LDocInfo.FilePath;

  LWord := GetWordAtPosition(LDocInfo.Content, LLine, LChar);
  if LWord = '' then
  begin
    Result := LResults;
    Exit;
  end;

  if not Assigned(FCompiler) or not Assigned(FCompiler.Modules) then
  begin
    Result := LResults;
    Exit;
  end;

  // Collect references from all modules but filter to current file
  LReferences := TList<TASTNode>.Create();
  LSyntheticNodes := TObjectList<TASTNode>.Create();
  try
    for LModulePair in FCompiler.Modules do
    begin
      LModule := LModulePair.Value;
      if Assigned(LModule) then
        CollectReferences(LModule, LWord, LReferences, LSyntheticNodes);
    end;

    // Build result array - only include references from current file
    for LNode in LReferences do
    begin
      if (LNode.Filename = '') or (LNode.Line < 1) then
        Continue;

      // Filter to current file only
      if not SameText(LNode.Filename, LFilePath) then
        Continue;

      LHighlight := TJSONObject.Create();

      LRange := TJSONObject.Create();
      LStart := TJSONObject.Create();
      LStart.AddPair('line', TJSONNumber.Create(LNode.Line - 1));
      LStart.AddPair('character', TJSONNumber.Create(LNode.Column - 1));
      LEnd := TJSONObject.Create();
      LEnd.AddPair('line', TJSONNumber.Create(LNode.Line - 1));
      LEnd.AddPair('character', TJSONNumber.Create(LNode.Column - 1 + Length(LWord)));
      LRange.AddPair('start', LStart);
      LRange.AddPair('end', LEnd);
      LHighlight.AddPair('range', LRange);

      // Kind: 1=Text, 2=Read, 3=Write (we use Text for simplicity)
      LHighlight.AddPair('kind', TJSONNumber.Create(1));

      LResults.Add(LHighlight);
    end;
  finally
    LSyntheticNodes.Free();
    LReferences.Free();
  end;

  Result := LResults;
end;

function TLSPHandlers.HandleTextDocumentDocumentSymbol(const AParams: TJSONObject): TJSONValue;
var
  LTextDocument: TJSONObject;
  LUri: string;
  LSymbols: TJSONArray;
  LSymbolJson: TJSONObject;
  LSymbol: TSymbol;
  LRange: TJSONObject;
  LStart: TJSONObject;
  LEnd: TJSONObject;
  LNode: TASTNode;
begin
  LTextDocument := AParams.GetValue<TJSONObject>('textDocument');
  LUri := LTextDocument.GetValue<string>('uri');

  LSymbols := TJSONArray.Create();

  if Assigned(FCompiler) and Assigned(FCompiler.Symbols) then
  begin
    for LSymbol in FCompiler.Symbols.GetAllSymbols() do
    begin
      LNode := LSymbol.Node;

      // Skip symbols without valid source location
      if not Assigned(LNode) then
        Continue;
      if LNode.Line < 1 then
        Continue;
      if LNode.Column < 1 then
        Continue;

      LSymbolJson := TJSONObject.Create();
      LSymbolJson.AddPair('name', LSymbol.SymbolName);
      LSymbolJson.AddPair('kind', TJSONNumber.Create(GetSymbolKindForLSP(LSymbol.Kind)));

      LRange := TJSONObject.Create();
      LStart := TJSONObject.Create();
      LStart.AddPair('line', TJSONNumber.Create(LNode.Line - 1));
      LStart.AddPair('character', TJSONNumber.Create(LNode.Column - 1));
      LEnd := TJSONObject.Create();
      LEnd.AddPair('line', TJSONNumber.Create(LNode.Line - 1));
      LEnd.AddPair('character', TJSONNumber.Create(LNode.Column - 1 + Length(LSymbol.SymbolName)));
      LRange.AddPair('start', LStart);
      LRange.AddPair('end', LEnd);

      LSymbolJson.AddPair('range', LRange);
      
      // Create separate selectionRange (don't clone)
      LStart := TJSONObject.Create();
      LStart.AddPair('line', TJSONNumber.Create(LNode.Line - 1));
      LStart.AddPair('character', TJSONNumber.Create(LNode.Column - 1));
      LEnd := TJSONObject.Create();
      LEnd.AddPair('line', TJSONNumber.Create(LNode.Line - 1));
      LEnd.AddPair('character', TJSONNumber.Create(LNode.Column - 1 + Length(LSymbol.SymbolName)));
      LRange := TJSONObject.Create();
      LRange.AddPair('start', LStart);
      LRange.AddPair('end', LEnd);
      LSymbolJson.AddPair('selectionRange', LRange);

      LSymbols.Add(LSymbolJson);
    end;
  end;

  Result := LSymbols;
end;

function TLSPHandlers.HandleTextDocumentSignatureHelp(const AParams: TJSONObject): TJSONValue;
var
  LTextDocument: TJSONObject;
  LPosition: TJSONObject;
  LUri: string;
  LLine: Integer;
  LChar: Integer;
  LDocInfo: TDocumentInfo;
  LRoutineName: string;
  LModuleName: string;
  LSymbols: TArray<TSymbol>;
  LSymbol: TSymbol;
  LRoutine: TRoutineSymbol;
  LResult: TJSONObject;
  LSignatures: TJSONArray;
  LSignature: TJSONObject;
  LParameters: TJSONArray;
  LParamJson: TJSONObject;
  LParam: TSymbol;
  LLabel: string;
  LParamLabel: string;
  LI: Integer;
begin
  Result := TJSONNull.Create();

  LTextDocument := AParams.GetValue<TJSONObject>('textDocument');
  LPosition := AParams.GetValue<TJSONObject>('position');

  LUri := LTextDocument.GetValue<string>('uri');
  LLine := LPosition.GetValue<Integer>('line');
  LChar := LPosition.GetValue<Integer>('character');

  if not FDocuments.TryGetValue(LUri, LDocInfo) then
    Exit;

  LRoutineName := ExtractRoutineNameBeforeParen(LDocInfo.Content, LLine, LChar, LModuleName);
  
  if LRoutineName = '' then
    Exit;

  if not Assigned(FCompiler) or not Assigned(FCompiler.Symbols) then
    Exit;

  // Check if module exists
  if LModuleName <> '' then
  begin
    FProtocol.Log('SignatureHelp: HasModule(%s)=%s', [LModuleName, BoolToStr(FCompiler.Symbols.HasModule(LModuleName), True)]);
  end;

  // Look up all overloads
  if LModuleName <> '' then
    LSymbols := FCompiler.Symbols.LookupAllQualified(LModuleName, LRoutineName)
  else
  begin
    // For non-qualified lookup, just get single symbol for now
    LSymbol := FCompiler.Symbols.Lookup(LRoutineName);
    if Assigned(LSymbol) then
      LSymbols := [LSymbol]
    else
      LSymbols := nil;
  end;

  if (LSymbols = nil) or (Length(LSymbols) = 0) then
    Exit;

  Result.Free();
  
  LSignatures := TJSONArray.Create();
  
  // Build signatures for all overloads
  for LSymbol in LSymbols do
  begin
    if not (LSymbol is TRoutineSymbol) then
      Continue;
      
    LRoutine := TRoutineSymbol(LSymbol);

    // Build signature label
    LLabel := LRoutine.SymbolName + '(';
    
    // Check if variadic via AST node
    if Assigned(LRoutine.Node) and (LRoutine.Node is TRoutineNode) and TRoutineNode(LRoutine.Node).IsVariadic then
    begin
      LLabel := LLabel + '...';
    end
    else
    begin
      for LI := 0 to LRoutine.Params.Count - 1 do
      begin
        LParam := LRoutine.Params[LI];
        if LI > 0 then
          LLabel := LLabel + '; ';
        LLabel := LLabel + LParam.SymbolName;
        if Assigned(LParam.TypeRef) then
          LLabel := LLabel + ': ' + LParam.TypeRef.SymbolName;
      end;
    end;
    
    LLabel := LLabel + ')';
    if Assigned(LRoutine.ReturnType) then
      LLabel := LLabel + ': ' + LRoutine.ReturnType.SymbolName;

    // Build parameters array
    LParameters := TJSONArray.Create();
    for LI := 0 to LRoutine.Params.Count - 1 do
    begin
      LParam := LRoutine.Params[LI];
      LParamLabel := LParam.SymbolName;
      if Assigned(LParam.TypeRef) then
        LParamLabel := LParamLabel + ': ' + LParam.TypeRef.SymbolName;

      LParamJson := TJSONObject.Create();
      LParamJson.AddPair('label', LParamLabel);
      LParameters.Add(LParamJson);
    end;

    LSignature := TJSONObject.Create();
    LSignature.AddPair('label', LLabel);
    LSignature.AddPair('parameters', LParameters);
    LSignatures.Add(LSignature);
  end;
  
  if LSignatures.Count = 0 then
  begin
    LSignatures.Free();
    Exit;
  end;

  LResult := TJSONObject.Create();
  LResult.AddPair('signatures', LSignatures);
  LResult.AddPair('activeSignature', TJSONNumber.Create(0));
  LResult.AddPair('activeParameter', TJSONNumber.Create(0));

  Result := LResult;
end;

function TLSPHandlers.HandleTextDocumentCodeAction(const AParams: TJSONObject): TJSONValue;
var
  LTextDocument: TJSONObject;
  LContext: TJSONObject;
  LDiagnostics: TJSONArray;
  LDiagnostic: TJSONObject;
  LUri: string;
  LCode: string;
  LRange: TJSONObject;
  LStartLine: Integer;
  LActions: TJSONArray;
  LAction: TJSONObject;
  LEdit: TJSONObject;
  LChanges: TJSONObject;
  LTextEdits: TJSONArray;
  LTextEdit: TJSONObject;
  LEditRange: TJSONObject;
  LEditStart: TJSONObject;
  LEditEnd: TJSONObject;
  LDocInfo: TDocumentInfo;
  LLines: TArray<string>;
  LCurrentLine: string;
  LModuleEndPos: Integer;
  LI: Integer;
  LModuleType: string;
begin
  LActions := TJSONArray.Create();

  LTextDocument := AParams.GetValue<TJSONObject>('textDocument');
  LUri := LTextDocument.GetValue<string>('uri');
  LContext := AParams.GetValue<TJSONObject>('context');

  if LContext = nil then
  begin
    Result := LActions;
    Exit;
  end;

  LDiagnostics := LContext.GetValue<TJSONArray>('diagnostics');
  if (LDiagnostics = nil) or (LDiagnostics.Count = 0) then
  begin
    Result := LActions;
    Exit;
  end;

  // Get document content
  if not FDocuments.TryGetValue(LUri, LDocInfo) then
  begin
    Result := LActions;
    Exit;
  end;

  LLines := LDocInfo.Content.Split([#10]);

  // Process each diagnostic
  for LI := 0 to LDiagnostics.Count - 1 do
  begin
    LDiagnostic := LDiagnostics.Items[LI] as TJSONObject;
    LCode := LDiagnostic.GetValue<string>('code', '');
    LRange := LDiagnostic.GetValue<TJSONObject>('range');

    if LRange = nil then
      Continue;

    LStartLine := LRange.GetValue<TJSONObject>('start').GetValue<Integer>('line');

    // E107: Expected module type (exe, dll, or lib)
    if LCode = 'E107' then
    begin
      // Syntax: MODULE EXE|DLL|LIB Name;
      // Insert type after MODULE keyword, before the name
      if (LStartLine >= 0) and (LStartLine < Length(LLines)) then
      begin
        LCurrentLine := LLines[LStartLine].TrimRight([#13]);

        // Find position after MODULE keyword and whitespace
        LModuleEndPos := 1;
        // Skip MODULE keyword
        while (LModuleEndPos <= Length(LCurrentLine)) and not CharInSet(LCurrentLine[LModuleEndPos], [' ', #9]) do
          Inc(LModuleEndPos);
        // Skip whitespace after MODULE
        while (LModuleEndPos <= Length(LCurrentLine)) and CharInSet(LCurrentLine[LModuleEndPos], [' ', #9]) do
          Inc(LModuleEndPos);

        // Create quick fix for each module type
        for LModuleType in ['EXE', 'DLL', 'LIB'] do
        begin
          LAction := TJSONObject.Create();
          LAction.AddPair('title', 'Insert ' + LModuleType + ' module type');
          LAction.AddPair('kind', 'quickfix');

          // Create workspace edit
          LEdit := TJSONObject.Create();
          LChanges := TJSONObject.Create();
          LTextEdits := TJSONArray.Create();

          LTextEdit := TJSONObject.Create();
          LEditRange := TJSONObject.Create();
          LEditStart := TJSONObject.Create();
          LEditStart.AddPair('line', TJSONNumber.Create(LStartLine));
          LEditStart.AddPair('character', TJSONNumber.Create(LModuleEndPos - 1));
          LEditEnd := TJSONObject.Create();
          LEditEnd.AddPair('line', TJSONNumber.Create(LStartLine));
          LEditEnd.AddPair('character', TJSONNumber.Create(LModuleEndPos - 1));
          LEditRange.AddPair('start', LEditStart);
          LEditRange.AddPair('end', LEditEnd);
          LTextEdit.AddPair('range', LEditRange);
          LTextEdit.AddPair('newText', LModuleType + ' ');

          LTextEdits.Add(LTextEdit);
          LChanges.AddPair(LUri, LTextEdits);
          LEdit.AddPair('changes', LChanges);
          LAction.AddPair('edit', LEdit);

          // Link to diagnostic
          LAction.AddPair('diagnostics', TJSONArray.Create().Add(LDiagnostic.Clone as TJSONObject));

          LActions.Add(LAction);
        end;
      end;
    end;
  end;

  Result := LActions;
end;

function TLSPHandlers.HandleTextDocumentRename(const AParams: TJSONObject): TJSONValue;
var
  LTextDocument: TJSONObject;
  LPosition: TJSONObject;
  LUri: string;
  LLine: Integer;
  LChar: Integer;
  LNewName: string;
  LDocInfo: TDocumentInfo;
  LWord: string;
  LResult: TJSONObject;
  LChanges: TJSONObject;
  LModule: TModuleNode;
  LReferences: TList<TASTNode>;
  LSyntheticNodes: TObjectList<TASTNode>;
  LNode: TASTNode;
  LModulePair: TPair<string, TModuleNode>;
  LFileEdits: TDictionary<string, TJSONArray>;
  LFileUri: string;
  LTextEdits: TJSONArray;
  LTextEdit: TJSONObject;
  LRange: TJSONObject;
  LStart: TJSONObject;
  LEnd: TJSONObject;
  LPair: TPair<string, TJSONArray>;
begin
  Result := TJSONNull.Create();

  LTextDocument := AParams.GetValue<TJSONObject>('textDocument');
  LPosition := AParams.GetValue<TJSONObject>('position');
  LNewName := AParams.GetValue<string>('newName', '');

  if LNewName = '' then
    Exit;

  LUri := LTextDocument.GetValue<string>('uri');
  LLine := LPosition.GetValue<Integer>('line');
  LChar := LPosition.GetValue<Integer>('character');

  if not FDocuments.TryGetValue(LUri, LDocInfo) then
    Exit;

  LWord := GetWordAtPosition(LDocInfo.Content, LLine, LChar);
  if LWord = '' then
    Exit;

  if not Assigned(FCompiler) or not Assigned(FCompiler.Modules) then
    Exit;

  // Collect references from all modules
  LReferences := TList<TASTNode>.Create();
  LSyntheticNodes := TObjectList<TASTNode>.Create();
  LFileEdits := TDictionary<string, TJSONArray>.Create();
  try
    for LModulePair in FCompiler.Modules do
    begin
      LModule := LModulePair.Value;
      if Assigned(LModule) then
        CollectReferences(LModule, LWord, LReferences, LSyntheticNodes);
    end;

    if LReferences.Count = 0 then
      Exit;

    // Group edits by file URI
    for LNode in LReferences do
    begin
      if (LNode.Filename = '') or (LNode.Line < 1) then
        Continue;

      LFileUri := PathToUri(LNode.Filename);

      if not LFileEdits.TryGetValue(LFileUri, LTextEdits) then
      begin
        LTextEdits := TJSONArray.Create();
        LFileEdits.Add(LFileUri, LTextEdits);
      end;

      LTextEdit := TJSONObject.Create();
      LRange := TJSONObject.Create();
      LStart := TJSONObject.Create();
      LStart.AddPair('line', TJSONNumber.Create(LNode.Line - 1));
      LStart.AddPair('character', TJSONNumber.Create(LNode.Column - 1));
      LEnd := TJSONObject.Create();
      LEnd.AddPair('line', TJSONNumber.Create(LNode.Line - 1));
      LEnd.AddPair('character', TJSONNumber.Create(LNode.Column - 1 + Length(LWord)));
      LRange.AddPair('start', LStart);
      LRange.AddPair('end', LEnd);
      LTextEdit.AddPair('range', LRange);
      LTextEdit.AddPair('newText', LNewName);

      LTextEdits.Add(LTextEdit);
    end;

    // Build WorkspaceEdit
    Result.Free();
    LResult := TJSONObject.Create();
    LChanges := TJSONObject.Create();

    for LPair in LFileEdits do
      LChanges.AddPair(LPair.Key, LPair.Value);

    LResult.AddPair('changes', LChanges);
    Result := LResult;

  finally
    LSyntheticNodes.Free();
    LReferences.Free();
    LFileEdits.Free();
  end;
end;

function TLSPHandlers.HandleTextDocumentImplementation(const AParams: TJSONObject): TJSONValue;
var
  LTextDocument: TJSONObject;
  LPosition: TJSONObject;
  LUri: string;
  LLine: Integer;
  LChar: Integer;
  LDocInfo: TDocumentInfo;
  LWord: string;
  LSymbol: TSymbol;
  LResult: TJSONObject;
  LRange: TJSONObject;
  LStart: TJSONObject;
  LEnd: TJSONObject;
begin
  // In Myra, implementation is the same as definition (no interface/implementation split)
  Result := TJSONNull.Create();

  LTextDocument := AParams.GetValue<TJSONObject>('textDocument');
  LPosition := AParams.GetValue<TJSONObject>('position');

  LUri := LTextDocument.GetValue<string>('uri');
  LLine := LPosition.GetValue<Integer>('line');
  LChar := LPosition.GetValue<Integer>('character');

  if not FDocuments.TryGetValue(LUri, LDocInfo) then
    Exit;

  LWord := GetWordAtPosition(LDocInfo.Content, LLine, LChar);
  if LWord = '' then
    Exit;

  if not Assigned(FCompiler) or not Assigned(FCompiler.Symbols) then
    Exit;

  LSymbol := FCompiler.Symbols.Lookup(LWord);
  if not Assigned(LSymbol) or not Assigned(LSymbol.Node) then
    Exit;

  if (LSymbol.Node.Filename = '') or (LSymbol.Node.Line < 1) then
    Exit;

  Result.Free();
  LResult := TJSONObject.Create();
  LResult.AddPair('uri', PathToUri(LSymbol.Node.Filename));

  LRange := TJSONObject.Create();
  LStart := TJSONObject.Create();
  LStart.AddPair('line', TJSONNumber.Create(LSymbol.Node.Line - 1));
  LStart.AddPair('character', TJSONNumber.Create(LSymbol.Node.Column - 1));
  LEnd := TJSONObject.Create();
  LEnd.AddPair('line', TJSONNumber.Create(LSymbol.Node.Line - 1));
  LEnd.AddPair('character', TJSONNumber.Create(LSymbol.Node.Column - 1 + Length(LWord)));
  LRange.AddPair('start', LStart);
  LRange.AddPair('end', LEnd);
  LResult.AddPair('range', LRange);

  Result := LResult;
end;

function TLSPHandlers.HandleTextDocumentFoldingRange(const AParams: TJSONObject): TJSONValue;
var
  LTextDocument: TJSONObject;
  LUri: string;
  LDocInfo: TDocumentInfo;
  LFilePath: string;
  LModule: TModuleNode;
  LModulePair: TPair<string, TModuleNode>;
  LRanges: TJSONArray;

  procedure AddFoldingRange(const AStartLine: Integer; const AEndLine: Integer; const AKind: string);
  var
    LRange: TJSONObject;
  begin
    if AEndLine > AStartLine then
    begin
      LRange := TJSONObject.Create();
      LRange.AddPair('startLine', TJSONNumber.Create(AStartLine - 1));
      LRange.AddPair('endLine', TJSONNumber.Create(AEndLine - 1));
      if AKind <> '' then
        LRange.AddPair('kind', AKind);
      LRanges.Add(LRange);
    end;
  end;

  procedure CollectFoldingRanges(const ANode: TASTNode);
  var
    LI: Integer;
    LRoutine: TRoutineNode;
    LRecord: TRecordNode;
    LIf: TIfNode;
    LWhile: TWhileNode;
    LFor: TForNode;
    LRepeat: TRepeatNode;
    LCase: TCaseNode;
    LTry: TTryNode;
    LTest: TTestNode;
    LBlock: TBlockNode;
    LBranch: TCaseBranch;
  begin
    if ANode = nil then
      Exit;

    if ANode is TRoutineNode then
    begin
      LRoutine := TRoutineNode(ANode);
      AddFoldingRange(LRoutine.Line, LRoutine.EndLine, 'region');
      CollectFoldingRanges(LRoutine.Body);
    end
    else if ANode is TRecordNode then
    begin
      LRecord := TRecordNode(ANode);
      AddFoldingRange(LRecord.Line, LRecord.EndLine, 'region');
    end
    else if ANode is TTestNode then
    begin
      LTest := TTestNode(ANode);
      AddFoldingRange(LTest.Line, LTest.EndLine, 'region');
      CollectFoldingRanges(LTest.Body);
    end
    else if ANode is TIfNode then
    begin
      LIf := TIfNode(ANode);
      CollectFoldingRanges(LIf.ThenBlock);
      CollectFoldingRanges(LIf.ElseBlock);
    end
    else if ANode is TWhileNode then
    begin
      LWhile := TWhileNode(ANode);
      CollectFoldingRanges(LWhile.Body);
    end
    else if ANode is TForNode then
    begin
      LFor := TForNode(ANode);
      CollectFoldingRanges(LFor.Body);
    end
    else if ANode is TRepeatNode then
    begin
      LRepeat := TRepeatNode(ANode);
      CollectFoldingRanges(LRepeat.Body);
    end
    else if ANode is TCaseNode then
    begin
      LCase := TCaseNode(ANode);
      for LI := 0 to LCase.Branches.Count - 1 do
      begin
        LBranch := LCase.Branches[LI];
        CollectFoldingRanges(LBranch.Body);
      end;
      CollectFoldingRanges(LCase.ElseBlock);
    end
    else if ANode is TTryNode then
    begin
      LTry := TTryNode(ANode);
      CollectFoldingRanges(LTry.TryBlock);
      CollectFoldingRanges(LTry.ExceptBlock);
      CollectFoldingRanges(LTry.FinallyBlock);
    end
    else if ANode is TBlockNode then
    begin
      LBlock := TBlockNode(ANode);
      for LI := 0 to LBlock.Statements.Count - 1 do
        CollectFoldingRanges(LBlock.Statements[LI]);
    end
    else if ANode is TModuleNode then
    begin
      LModule := TModuleNode(ANode);
      // Module itself is foldable
      AddFoldingRange(LModule.Line, LModule.EndLine, 'region');
      for LI := 0 to LModule.Types.Count - 1 do
        CollectFoldingRanges(LModule.Types[LI]);
      for LI := 0 to LModule.Routines.Count - 1 do
        CollectFoldingRanges(LModule.Routines[LI]);
      for LI := 0 to LModule.Tests.Count - 1 do
        CollectFoldingRanges(LModule.Tests[LI]);
      CollectFoldingRanges(LModule.Body);
    end;
  end;

begin
  LRanges := TJSONArray.Create();
  Result := LRanges;

  LTextDocument := AParams.GetValue<TJSONObject>('textDocument');
  LUri := LTextDocument.GetValue<string>('uri');

  if not FDocuments.TryGetValue(LUri, LDocInfo) then
    Exit;

  LFilePath := LDocInfo.FilePath;

  if not Assigned(FCompiler) or not Assigned(FCompiler.Modules) then
    Exit;

  // Find module for this file
  for LModulePair in FCompiler.Modules do
  begin
    LModule := LModulePair.Value;
    if Assigned(LModule) and SameText(LModule.Filename, LFilePath) then
    begin
      CollectFoldingRanges(LModule);
      Break;
    end;
  end;
end;

function TLSPHandlers.HandleTextDocumentSelectionRange(const AParams: TJSONObject): TJSONValue;
var
  LTextDocument: TJSONObject;
  LPositions: TJSONArray;
  LPosition: TJSONObject;
  LUri: string;
  LLine: Integer;
  LChar: Integer;
  LDocInfo: TDocumentInfo;
  LFilePath: string;
  LModule: TModuleNode;
  LModulePair: TPair<string, TModuleNode>;
  LResults: TJSONArray;
  LI: Integer;
  LRanges: TList<TASTNode>;

  function ContainsPosition(const ANode: TASTNode; const ALine: Integer; const AChar: Integer): Boolean;
  begin
    Result := False;
    if ANode = nil then
      Exit;
    if ANode.Line < 1 then
      Exit;
    // Check if position is within node's range
    if (ALine + 1 >= ANode.Line) and (ANode.EndLine > 0) and (ALine + 1 <= ANode.EndLine) then
      Result := True
    else if (ALine + 1 = ANode.Line) then
      Result := True;
  end;

  procedure CollectEnclosingNodes(const ANode: TASTNode; const ALine: Integer; const AChar: Integer);
  var
    LJ: Integer;
    LRoutine: TRoutineNode;
    LRecord: TRecordNode;
    LBlock: TBlockNode;
    LIf: TIfNode;
    LWhile: TWhileNode;
    LFor: TForNode;
    LRepeat: TRepeatNode;
    LCase: TCaseNode;
    LTry: TTryNode;
    LTest: TTestNode;
    LBranch: TCaseBranch;
  begin
    if ANode = nil then
      Exit;

    if not ContainsPosition(ANode, ALine, AChar) then
      Exit;

    // Add this node if it has valid range
    if (ANode.Line > 0) and (ANode.EndLine > 0) then
      LRanges.Add(ANode);

    // Recurse into children
    if ANode is TModuleNode then
    begin
      for LJ := 0 to TModuleNode(ANode).Types.Count - 1 do
        CollectEnclosingNodes(TModuleNode(ANode).Types[LJ], ALine, AChar);
      for LJ := 0 to TModuleNode(ANode).Routines.Count - 1 do
        CollectEnclosingNodes(TModuleNode(ANode).Routines[LJ], ALine, AChar);
      for LJ := 0 to TModuleNode(ANode).Tests.Count - 1 do
        CollectEnclosingNodes(TModuleNode(ANode).Tests[LJ], ALine, AChar);
      CollectEnclosingNodes(TModuleNode(ANode).Body, ALine, AChar);
    end
    else if ANode is TRoutineNode then
    begin
      LRoutine := TRoutineNode(ANode);
      CollectEnclosingNodes(LRoutine.Body, ALine, AChar);
    end
    else if ANode is TTestNode then
    begin
      LTest := TTestNode(ANode);
      CollectEnclosingNodes(LTest.Body, ALine, AChar);
    end
    else if ANode is TRecordNode then
    begin
      LRecord := TRecordNode(ANode);
      for LJ := 0 to LRecord.Fields.Count - 1 do
        CollectEnclosingNodes(LRecord.Fields[LJ], ALine, AChar);
    end
    else if ANode is TBlockNode then
    begin
      LBlock := TBlockNode(ANode);
      for LJ := 0 to LBlock.Statements.Count - 1 do
        CollectEnclosingNodes(LBlock.Statements[LJ], ALine, AChar);
    end
    else if ANode is TIfNode then
    begin
      LIf := TIfNode(ANode);
      CollectEnclosingNodes(LIf.ThenBlock, ALine, AChar);
      CollectEnclosingNodes(LIf.ElseBlock, ALine, AChar);
    end
    else if ANode is TWhileNode then
    begin
      LWhile := TWhileNode(ANode);
      CollectEnclosingNodes(LWhile.Body, ALine, AChar);
    end
    else if ANode is TForNode then
    begin
      LFor := TForNode(ANode);
      CollectEnclosingNodes(LFor.Body, ALine, AChar);
    end
    else if ANode is TRepeatNode then
    begin
      LRepeat := TRepeatNode(ANode);
      CollectEnclosingNodes(LRepeat.Body, ALine, AChar);
    end
    else if ANode is TCaseNode then
    begin
      LCase := TCaseNode(ANode);
      for LJ := 0 to LCase.Branches.Count - 1 do
      begin
        LBranch := LCase.Branches[LJ];
        CollectEnclosingNodes(LBranch.Body, ALine, AChar);
      end;
      CollectEnclosingNodes(LCase.ElseBlock, ALine, AChar);
    end
    else if ANode is TTryNode then
    begin
      LTry := TTryNode(ANode);
      CollectEnclosingNodes(LTry.TryBlock, ALine, AChar);
      CollectEnclosingNodes(LTry.ExceptBlock, ALine, AChar);
      CollectEnclosingNodes(LTry.FinallyBlock, ALine, AChar);
    end;
  end;

  function BuildSelectionRange(const AIndex: Integer): TJSONObject;
  var
    LNode: TASTNode;
    LRange: TJSONObject;
    LStart: TJSONObject;
    LEnd: TJSONObject;
  begin
    Result := TJSONObject.Create();
    LNode := LRanges[AIndex];

    LRange := TJSONObject.Create();
    LStart := TJSONObject.Create();
    LStart.AddPair('line', TJSONNumber.Create(LNode.Line - 1));
    LStart.AddPair('character', TJSONNumber.Create(0));
    LEnd := TJSONObject.Create();
    LEnd.AddPair('line', TJSONNumber.Create(LNode.EndLine - 1));
    LEnd.AddPair('character', TJSONNumber.Create(0));
    LRange.AddPair('start', LStart);
    LRange.AddPair('end', LEnd);
    Result.AddPair('range', LRange);

    // Link to parent (outer) range
    if AIndex > 0 then
      Result.AddPair('parent', BuildSelectionRange(AIndex - 1));
  end;

begin
  LResults := TJSONArray.Create();
  Result := LResults;

  LTextDocument := AParams.GetValue<TJSONObject>('textDocument');
  LPositions := AParams.GetValue<TJSONArray>('positions');
  LUri := LTextDocument.GetValue<string>('uri');

  if not FDocuments.TryGetValue(LUri, LDocInfo) then
    Exit;

  LFilePath := LDocInfo.FilePath;

  if not Assigned(FCompiler) or not Assigned(FCompiler.Modules) then
    Exit;

  // Find module for this file
  LModule := nil;
  for LModulePair in FCompiler.Modules do
  begin
    if Assigned(LModulePair.Value) and SameText(LModulePair.Value.Filename, LFilePath) then
    begin
      LModule := LModulePair.Value;
      Break;
    end;
  end;

  if LModule = nil then
    Exit;

  // Process each position
  for LI := 0 to LPositions.Count - 1 do
  begin
    LPosition := LPositions.Items[LI] as TJSONObject;
    LLine := LPosition.GetValue<Integer>('line');
    LChar := LPosition.GetValue<Integer>('character');

    LRanges := TList<TASTNode>.Create();
    try
      CollectEnclosingNodes(LModule, LLine, LChar);

      if LRanges.Count > 0 then
        LResults.Add(BuildSelectionRange(LRanges.Count - 1))
      else
        LResults.AddElement(TJSONNull.Create());
    finally
      LRanges.Free();
    end;
  end;
end;

procedure TLSPHandlers.CollectSemanticTokens(const ANode: TASTNode; const AFilePath: string; const ATokens: TList<TSemanticToken>);

  procedure AddToken(const ALine: Integer; const AColumn: Integer; const ALength: Integer; const ATokenType: Integer; const AModifiers: Integer);
  var
    LToken: TSemanticToken;
  begin
    if (ALine < 1) or (AColumn < 1) or (ALength < 1) then
      Exit;
    LToken.Line := ALine;
    LToken.Column := AColumn;
    LToken.Length := ALength;
    LToken.TokenType := ATokenType;
    LToken.Modifiers := AModifiers;
    ATokens.Add(LToken);
  end;

var
  LI: Integer;
  LJ: Integer;
  LModule: TModuleNode;
  LRoutine: TRoutineNode;
  LRecord: TRecordNode;
  LField: TFieldNode;
  LParam: TParamNode;
  LVarDecl: TVarDeclNode;
  LConstNode: TConstNode;
  LBlock: TBlockNode;
  LIf: TIfNode;
  LWhile: TWhileNode;
  LFor: TForNode;
  LRepeat: TRepeatNode;
  LCase: TCaseNode;
  LBranch: TCaseBranch;
  LTry: TTryNode;
  LTest: TTestNode;
  LAssign: TAssignNode;
  LBinary: TBinaryOpNode;
  LUnary: TUnaryOpNode;
  LCall: TCallNode;
  LFieldAccess: TFieldAccessNode;
  LIndexAccess: TIndexAccessNode;
  LDeref: TDerefNode;
  LReturn: TReturnNode;
  LTypeCast: TTypeCastNode;
  LTypeTest: TTypeTestNode;
  LIdent: TIdentifierNode;
  LInherited: TInheritedCallNode;
  LNewNode: TNewNode;
  LSetLit: TSetLitNode;
  LRange: TRangeNode;
  LSymbol: TSymbol;
begin
  if ANode = nil then
    Exit;

  // Only process nodes from the target file
  if (ANode.Filename <> '') and not SameText(ANode.Filename, AFilePath) then
    Exit;

  // Module node
  if ANode is TModuleNode then
  begin
    LModule := TModuleNode(ANode);
    // Module name - namespace (use base Line/Column)
    if LModule.Line > 0 then
      AddToken(LModule.Line, LModule.Column, Length(LModule.ModuleName), STT_NAMESPACE, STM_DECLARATION);
    // Walk children
    for LI := 0 to LModule.Consts.Count - 1 do
      CollectSemanticTokens(LModule.Consts[LI], AFilePath, ATokens);
    for LI := 0 to LModule.Types.Count - 1 do
      CollectSemanticTokens(LModule.Types[LI], AFilePath, ATokens);
    for LI := 0 to LModule.Vars.Count - 1 do
      CollectSemanticTokens(LModule.Vars[LI], AFilePath, ATokens);
    for LI := 0 to LModule.Routines.Count - 1 do
      CollectSemanticTokens(LModule.Routines[LI], AFilePath, ATokens);
    for LI := 0 to LModule.Tests.Count - 1 do
      CollectSemanticTokens(LModule.Tests[LI], AFilePath, ATokens);
    CollectSemanticTokens(LModule.Body, AFilePath, ATokens);
  end
  // Routine node
  else if ANode is TRoutineNode then
  begin
    LRoutine := TRoutineNode(ANode);
    // Routine name - function
    if LRoutine.RoutineNameLine > 0 then
      AddToken(LRoutine.RoutineNameLine, LRoutine.RoutineNameColumn, Length(LRoutine.RoutineName), STT_FUNCTION, STM_DECLARATION);
    // Bound type - type
    if (LRoutine.BoundToType <> '') and (LRoutine.BoundToTypeLine > 0) then
      AddToken(LRoutine.BoundToTypeLine, LRoutine.BoundToTypeColumn, Length(LRoutine.BoundToType), STT_TYPE, 0);
    // Return type - type
    if (LRoutine.ReturnType <> '') and (LRoutine.ReturnTypeLine > 0) then
      AddToken(LRoutine.ReturnTypeLine, LRoutine.ReturnTypeColumn, Length(LRoutine.ReturnType), STT_TYPE, 0);
    // Walk params
    for LI := 0 to LRoutine.Params.Count - 1 do
      CollectSemanticTokens(LRoutine.Params[LI], AFilePath, ATokens);
    // Walk local vars
    for LI := 0 to LRoutine.LocalVars.Count - 1 do
      CollectSemanticTokens(LRoutine.LocalVars[LI], AFilePath, ATokens);
    // Walk body
    CollectSemanticTokens(LRoutine.Body, AFilePath, ATokens);
  end
  // Record node
  else if ANode is TRecordNode then
  begin
    LRecord := TRecordNode(ANode);
    // Record name - type (TypeName from TTypeNode parent)
    if (LRecord.TypeNameLine > 0) then
      AddToken(LRecord.TypeNameLine, LRecord.TypeNameColumn, Length(LRecord.TypeName), STT_TYPE, STM_DECLARATION);
    // Parent type - type
    if (LRecord.ParentType <> '') and (LRecord.ParentTypeLine > 0) then
      AddToken(LRecord.ParentTypeLine, LRecord.ParentTypeColumn, Length(LRecord.ParentType), STT_TYPE, 0);
    // Walk fields
    for LI := 0 to LRecord.Fields.Count - 1 do
      CollectSemanticTokens(LRecord.Fields[LI], AFilePath, ATokens);
  end
  // Field node
  else if ANode is TFieldNode then
  begin
    LField := TFieldNode(ANode);
    // Field name - property
    if LField.Line > 0 then
      AddToken(LField.Line, LField.Column, Length(LField.FieldName), STT_PROPERTY, STM_DECLARATION);
    // Field type - type
    if (LField.TypeName <> '') and (LField.TypeNameLine > 0) then
      AddToken(LField.TypeNameLine, LField.TypeNameColumn, Length(LField.TypeName), STT_TYPE, 0);
  end
  // Param node
  else if ANode is TParamNode then
  begin
    LParam := TParamNode(ANode);
    // Param name - parameter
    if LParam.Line > 0 then
      AddToken(LParam.Line, LParam.Column, Length(LParam.ParamName), STT_PARAMETER, STM_DECLARATION);
    // Param type - type
    if (LParam.TypeName <> '') and (LParam.TypeNameLine > 0) then
      AddToken(LParam.TypeNameLine, LParam.TypeNameColumn, Length(LParam.TypeName), STT_TYPE, 0);
  end
  // Var decl node
  else if ANode is TVarDeclNode then
  begin
    LVarDecl := TVarDeclNode(ANode);
    // Var name - variable
    if LVarDecl.Line > 0 then
      AddToken(LVarDecl.Line, LVarDecl.Column, Length(LVarDecl.VarName), STT_VARIABLE, STM_DECLARATION);
    // Var type - type
    if (LVarDecl.TypeName <> '') and (LVarDecl.TypeNameLine > 0) then
      AddToken(LVarDecl.TypeNameLine, LVarDecl.TypeNameColumn, Length(LVarDecl.TypeName), STT_TYPE, 0);
    // Walk init value
    CollectSemanticTokens(LVarDecl.InitValue, AFilePath, ATokens);
  end
  // Const node
  else if ANode is TConstNode then
  begin
    LConstNode := TConstNode(ANode);
    // Const name - enumMember (constant)
    if LConstNode.Line > 0 then
      AddToken(LConstNode.Line, LConstNode.Column, Length(LConstNode.ConstName), STT_ENUMMEMBER, STM_DECLARATION or STM_READONLY);
    // Const type - type
    if (LConstNode.TypeName <> '') and (LConstNode.TypeNameLine > 0) then
      AddToken(LConstNode.TypeNameLine, LConstNode.TypeNameColumn, Length(LConstNode.TypeName), STT_TYPE, 0);
    // Walk value
    CollectSemanticTokens(LConstNode.Value, AFilePath, ATokens);
  end
  // Test node
  else if ANode is TTestNode then
  begin
    LTest := TTestNode(ANode);
    // Walk local vars
    for LI := 0 to LTest.LocalVars.Count - 1 do
      CollectSemanticTokens(LTest.LocalVars[LI], AFilePath, ATokens);
    for LI := 0 to LTest.LocalConsts.Count - 1 do
      CollectSemanticTokens(LTest.LocalConsts[LI], AFilePath, ATokens);
    CollectSemanticTokens(LTest.Body, AFilePath, ATokens);
  end
  // Block node
  else if ANode is TBlockNode then
  begin
    LBlock := TBlockNode(ANode);
    for LI := 0 to LBlock.Statements.Count - 1 do
      CollectSemanticTokens(LBlock.Statements[LI], AFilePath, ATokens);
  end
  // Identifier node - look up symbol to determine type
  else if ANode is TIdentifierNode then
  begin
    LIdent := TIdentifierNode(ANode);
    if (LIdent.Line > 0) and Assigned(FCompiler) and Assigned(FCompiler.Symbols) then
    begin
      LSymbol := FCompiler.Symbols.Lookup(LIdent.IdentName);
      if Assigned(LSymbol) then
      begin
        case LSymbol.Kind of
          skRoutine: AddToken(LIdent.Line, LIdent.Column, Length(LIdent.IdentName), STT_FUNCTION, 0);
          skType: AddToken(LIdent.Line, LIdent.Column, Length(LIdent.IdentName), STT_TYPE, 0);
          skVar: AddToken(LIdent.Line, LIdent.Column, Length(LIdent.IdentName), STT_VARIABLE, 0);
          skConst: AddToken(LIdent.Line, LIdent.Column, Length(LIdent.IdentName), STT_ENUMMEMBER, STM_READONLY);
          skField: AddToken(LIdent.Line, LIdent.Column, Length(LIdent.IdentName), STT_PROPERTY, 0);
          skParam: AddToken(LIdent.Line, LIdent.Column, Length(LIdent.IdentName), STT_PARAMETER, 0);
        end;
      end;
    end;
  end
  // Call node
  else if ANode is TCallNode then
  begin
    LCall := TCallNode(ANode);
    // Routine name - function
    if LCall.RoutineNameLine > 0 then
      AddToken(LCall.RoutineNameLine, LCall.RoutineNameColumn, Length(LCall.RoutineName), STT_FUNCTION, 0);
    // Walk receiver
    CollectSemanticTokens(LCall.Receiver, AFilePath, ATokens);
    // Walk arguments
    for LI := 0 to LCall.Args.Count - 1 do
      CollectSemanticTokens(LCall.Args[LI], AFilePath, ATokens);
  end
  // Field access node
  else if ANode is TFieldAccessNode then
  begin
    LFieldAccess := TFieldAccessNode(ANode);
    // Field name - property
    if LFieldAccess.FieldNameLine > 0 then
      AddToken(LFieldAccess.FieldNameLine, LFieldAccess.FieldNameColumn, Length(LFieldAccess.FieldName), STT_PROPERTY, 0);
    // Walk target
    CollectSemanticTokens(LFieldAccess.Target, AFilePath, ATokens);
  end
  // Type cast node
  else if ANode is TTypeCastNode then
  begin
    LTypeCast := TTypeCastNode(ANode);
    // Type name - type
    if LTypeCast.TypeNameLine > 0 then
      AddToken(LTypeCast.TypeNameLine, LTypeCast.TypeNameColumn, Length(LTypeCast.TypeName), STT_TYPE, 0);
    CollectSemanticTokens(LTypeCast.Expr, AFilePath, ATokens);
  end
  // Type test node
  else if ANode is TTypeTestNode then
  begin
    LTypeTest := TTypeTestNode(ANode);
    // Type name - type
    if LTypeTest.TypeNameLine > 0 then
      AddToken(LTypeTest.TypeNameLine, LTypeTest.TypeNameColumn, Length(LTypeTest.TypeName), STT_TYPE, 0);
    CollectSemanticTokens(LTypeTest.Expr, AFilePath, ATokens);
  end
  // New node
  else if ANode is TNewNode then
  begin
    LNewNode := TNewNode(ANode);
    // AsType - type
    if (LNewNode.AsType <> '') and (LNewNode.AsTypeLine > 0) then
      AddToken(LNewNode.AsTypeLine, LNewNode.AsTypeColumn, Length(LNewNode.AsType), STT_TYPE, 0);
    CollectSemanticTokens(LNewNode.Target, AFilePath, ATokens);
  end
  // Inherited call node
  else if ANode is TInheritedCallNode then
  begin
    LInherited := TInheritedCallNode(ANode);
    // Method name - function
    if LInherited.MethodNameLine > 0 then
      AddToken(LInherited.MethodNameLine, LInherited.MethodNameColumn, Length(LInherited.MethodName), STT_FUNCTION, 0);
    for LI := 0 to LInherited.Args.Count - 1 do
      CollectSemanticTokens(LInherited.Args[LI], AFilePath, ATokens);
  end
  // For node
  else if ANode is TForNode then
  begin
    LFor := TForNode(ANode);
    // Loop variable - variable
    if LFor.VarLine > 0 then
      AddToken(LFor.VarLine, LFor.VarColumn, Length(LFor.VarName), STT_VARIABLE, 0);
    CollectSemanticTokens(LFor.StartExpr, AFilePath, ATokens);
    CollectSemanticTokens(LFor.EndExpr, AFilePath, ATokens);
    CollectSemanticTokens(LFor.Body, AFilePath, ATokens);
  end
  // Control flow - recurse into children
  else if ANode is TIfNode then
  begin
    LIf := TIfNode(ANode);
    CollectSemanticTokens(LIf.Condition, AFilePath, ATokens);
    CollectSemanticTokens(LIf.ThenBlock, AFilePath, ATokens);
    CollectSemanticTokens(LIf.ElseBlock, AFilePath, ATokens);
  end
  else if ANode is TWhileNode then
  begin
    LWhile := TWhileNode(ANode);
    CollectSemanticTokens(LWhile.Condition, AFilePath, ATokens);
    CollectSemanticTokens(LWhile.Body, AFilePath, ATokens);
  end
  else if ANode is TRepeatNode then
  begin
    LRepeat := TRepeatNode(ANode);
    CollectSemanticTokens(LRepeat.Body, AFilePath, ATokens);
    CollectSemanticTokens(LRepeat.Condition, AFilePath, ATokens);
  end
  else if ANode is TCaseNode then
  begin
    LCase := TCaseNode(ANode);
    CollectSemanticTokens(LCase.Expr, AFilePath, ATokens);
    for LI := 0 to LCase.Branches.Count - 1 do
    begin
      LBranch := LCase.Branches[LI];
      for LJ := 0 to LBranch.Values.Count - 1 do
        CollectSemanticTokens(LBranch.Values[LJ], AFilePath, ATokens);
      CollectSemanticTokens(LBranch.Body, AFilePath, ATokens);
    end;
    CollectSemanticTokens(LCase.ElseBlock, AFilePath, ATokens);
  end
  else if ANode is TTryNode then
  begin
    LTry := TTryNode(ANode);
    CollectSemanticTokens(LTry.TryBlock, AFilePath, ATokens);
    CollectSemanticTokens(LTry.ExceptBlock, AFilePath, ATokens);
    CollectSemanticTokens(LTry.FinallyBlock, AFilePath, ATokens);
  end
  // Expression nodes
  else if ANode is TAssignNode then
  begin
    LAssign := TAssignNode(ANode);
    CollectSemanticTokens(LAssign.Target, AFilePath, ATokens);
    CollectSemanticTokens(LAssign.Value, AFilePath, ATokens);
  end
  else if ANode is TBinaryOpNode then
  begin
    LBinary := TBinaryOpNode(ANode);
    CollectSemanticTokens(LBinary.Left, AFilePath, ATokens);
    CollectSemanticTokens(LBinary.Right, AFilePath, ATokens);
  end
  else if ANode is TUnaryOpNode then
  begin
    LUnary := TUnaryOpNode(ANode);
    CollectSemanticTokens(LUnary.Operand, AFilePath, ATokens);
  end
  else if ANode is TIndexAccessNode then
  begin
    LIndexAccess := TIndexAccessNode(ANode);
    CollectSemanticTokens(LIndexAccess.Target, AFilePath, ATokens);
    CollectSemanticTokens(LIndexAccess.Index, AFilePath, ATokens);
  end
  else if ANode is TDerefNode then
  begin
    LDeref := TDerefNode(ANode);
    CollectSemanticTokens(LDeref.Target, AFilePath, ATokens);
  end
  else if ANode is TReturnNode then
  begin
    LReturn := TReturnNode(ANode);
    CollectSemanticTokens(LReturn.Value, AFilePath, ATokens);
  end
  else if ANode is TSetLitNode then
  begin
    LSetLit := TSetLitNode(ANode);
    for LI := 0 to LSetLit.Elements.Count - 1 do
      CollectSemanticTokens(LSetLit.Elements[LI], AFilePath, ATokens);
  end
  else if ANode is TRangeNode then
  begin
    LRange := TRangeNode(ANode);
    CollectSemanticTokens(LRange.LowExpr, AFilePath, ATokens);
    CollectSemanticTokens(LRange.HighExpr, AFilePath, ATokens);
  end;
end;

function TLSPHandlers.EncodeSemanticTokens(const ATokens: TList<TSemanticToken>): TJSONArray;
var
  LResult: TJSONArray;
  LSorted: TList<TSemanticToken>;
  LPrevLine: Integer;
  LPrevChar: Integer;
  LToken: TSemanticToken;
  LDeltaLine: Integer;
  LDeltaChar: Integer;
begin
  LResult := TJSONArray.Create();

  // Sort tokens by line, then column
  LSorted := TList<TSemanticToken>.Create();
  try
    LSorted.AddRange(ATokens);
    LSorted.Sort(
      TComparer<TSemanticToken>.Construct(
        function(const ALeft: TSemanticToken; const ARight: TSemanticToken): Integer
        begin
          Result := ALeft.Line - ARight.Line;
          if Result = 0 then
            Result := ALeft.Column - ARight.Column;
        end
      )
    );

    LPrevLine := 0;
    LPrevChar := 0;

    for LToken in LSorted do
    begin
      // LSP uses 0-based lines/columns
      LDeltaLine := (LToken.Line - 1) - LPrevLine;

      if LDeltaLine = 0 then
        LDeltaChar := (LToken.Column - 1) - LPrevChar
      else
        LDeltaChar := LToken.Column - 1;

      // 5 integers per token: deltaLine, deltaStartChar, length, tokenType, tokenModifiers
      LResult.Add(LDeltaLine);
      LResult.Add(LDeltaChar);
      LResult.Add(LToken.Length);
      LResult.Add(LToken.TokenType);
      LResult.Add(LToken.Modifiers);

      LPrevLine := LToken.Line - 1;
      LPrevChar := LToken.Column - 1;
    end;
  finally
    LSorted.Free();
  end;

  Result := LResult;
end;

function TLSPHandlers.HandleTextDocumentSemanticTokensFull(const AParams: TJSONObject): TJSONValue;
var
  LTextDocument: TJSONObject;
  LUri: string;
  LDocInfo: TDocumentInfo;
  LFilePath: string;
  LModule: TModuleNode;
  LModulePair: TPair<string, TModuleNode>;
  LTokens: TList<TSemanticToken>;
  LResult: TJSONObject;
begin
  Result := TJSONNull.Create();

  LTextDocument := AParams.GetValue<TJSONObject>('textDocument');
  LUri := LTextDocument.GetValue<string>('uri');

  if not FDocuments.TryGetValue(LUri, LDocInfo) then
    Exit;

  LFilePath := LDocInfo.FilePath;

  if not Assigned(FCompiler) or not Assigned(FCompiler.Modules) then
    Exit;

  // Find module for this file
  LModule := nil;
  for LModulePair in FCompiler.Modules do
  begin
    if Assigned(LModulePair.Value) and SameText(LModulePair.Value.Filename, LFilePath) then
    begin
      LModule := LModulePair.Value;
      Break;
    end;
  end;

  if LModule = nil then
    Exit;

  LTokens := TList<TSemanticToken>.Create();
  try
    CollectSemanticTokens(LModule, LFilePath, LTokens);

    Result.Free();
    LResult := TJSONObject.Create();
    LResult.AddPair('data', EncodeSemanticTokens(LTokens));
    Result := LResult;
  finally
    LTokens.Free();
  end;
end;

end.
