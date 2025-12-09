{===============================================================================
  Myra™ - Pascal. Refined.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit Myra.Semantic;

{$I Myra.Defines.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Myra.Utils,
  Myra.Errors,
  Myra.Token,
  Myra.AST,
  Myra.Symbols;

type
  { TSemanticAnalyzer }
  TSemanticAnalyzer = class(TBaseObject)
  private
    FErrors: TErrors;
    FSymbols: TSymbolTable;
    FCompiler: TObject;
    FCurrentModule: TModuleNode;
    FCurrentRoutine: TRoutineNode;

    procedure AnalyzeModule(const AModule: TModuleNode);
    procedure AnalyzeImports(const AImports: TList<TImportInfo>);
    procedure AnalyzeConst(const AConst: TConstNode);
    procedure AnalyzeType(const AType: TTypeNode);
    procedure AnalyzeRecord(const ARecord: TRecordNode);
    procedure AnalyzeRoutineType(const ARoutineType: TRoutineTypeNode);
    procedure AnalyzeVar(const AVar: TVarDeclNode);
    procedure AnalyzeRoutine(const ARoutine: TRoutineNode);
    procedure AnalyzeBlock(const ABlock: TBlockNode);
    procedure AnalyzeStatement(const AStmt: TASTNode);
    procedure AnalyzeIf(const ANode: TIfNode);
    procedure AnalyzeWhile(const ANode: TWhileNode);
    procedure AnalyzeFor(const ANode: TForNode);
    procedure AnalyzeRepeat(const ANode: TRepeatNode);
    procedure AnalyzeCase(const ANode: TCaseNode);
    procedure AnalyzeReturn(const ANode: TReturnNode);
    procedure AnalyzeAssign(const ANode: TAssignNode);
    procedure AnalyzeCall(const ANode: TCallNode);
    function AnalyzeCallReturnType(const ANode: TCallNode): TTypeSymbol;
    procedure AnalyzeNew(const ANode: TNewNode);
    procedure AnalyzeDispose(const ANode: TDisposeNode);
    procedure AnalyzeTry(const ANode: TTryNode);
    procedure AnalyzeInherited(const ANode: TInheritedCallNode);
    function AnalyzeExpression(const AExpr: TASTNode): TTypeSymbol;
    function AnalyzeBinaryOp(const ANode: TBinaryOpNode): TTypeSymbol;
    function AnalyzeUnaryOp(const ANode: TUnaryOpNode): TTypeSymbol;
    function AnalyzeIdentifier(const ANode: TIdentifierNode): TTypeSymbol;
    function AnalyzeFieldAccess(const ANode: TFieldAccessNode): TTypeSymbol;
    function AnalyzeIndexAccess(const ANode: TIndexAccessNode): TTypeSymbol;
    function AnalyzeDeref(const ANode: TDerefNode): TTypeSymbol;
    function AnalyzeTypeCast(const ANode: TTypeCastNode): TTypeSymbol;
    function AnalyzeTypeTest(const ANode: TTypeTestNode): TTypeSymbol;

    procedure DetectMethodBinding(const ARoutine: TRoutineNode; const ASymbol: TRoutineSymbol);
    function ResolveConstantString(const AName: string; const ANode: TASTNode): string;
    function ResolveTypeName(const AName: string; const ANode: TASTNode): TTypeSymbol;
    function AreTypesCompatible(const ALeft: TTypeSymbol; const ARight: TTypeSymbol): Boolean;
    procedure Error(const ANode: TASTNode; const ACode: string; const AMessage: string); overload;
    procedure Error(const ANode: TASTNode; const ACode: string; const AMessage: string; const AArgs: array of const); overload;
    procedure NormalizeQualifiedType(var ATypeName: string; const AResolvedType: TTypeSymbol);

  public
    constructor Create(); override;
    destructor Destroy(); override;

    procedure Process(const AModule: TModuleNode; const ASymbols: TSymbolTable; const ACompiler: TObject; const AErrors: TErrors);
  end;

implementation

uses
  Myra.Compiler;

{ TSemanticAnalyzer }

constructor TSemanticAnalyzer.Create();
begin
  inherited Create();
end;

destructor TSemanticAnalyzer.Destroy();
begin
  inherited Destroy();
end;

procedure TSemanticAnalyzer.Process(const AModule: TModuleNode; const ASymbols: TSymbolTable; const ACompiler: TObject; const AErrors: TErrors);
begin
  FErrors := AErrors;
  FSymbols := ASymbols;
  FCompiler := ACompiler;
  FCurrentModule := AModule;
  FCurrentRoutine := nil;

  AnalyzeModule(AModule);
end;

procedure TSemanticAnalyzer.AnalyzeModule(const AModule: TModuleNode);
var
  LConst: TASTNode;
  LType: TASTNode;
  LVar: TASTNode;
  LRoutine: TASTNode;
begin
  FSymbols.EnterModuleScope(AModule.ModuleName);

  // Analyze imports first
  AnalyzeImports(AModule.Imports);

  // First pass: register all types
  for LType in AModule.Types do
  begin
    if LType is TTypeNode then
      AnalyzeType(TTypeNode(LType));
  end;

  // Register constants
  for LConst in AModule.Consts do
  begin
    if LConst is TConstNode then
      AnalyzeConst(TConstNode(LConst));
  end;

  // Register variables
  for LVar in AModule.Vars do
  begin
    if LVar is TVarDeclNode then
      AnalyzeVar(TVarDeclNode(LVar));
  end;

  // Analyze routines
  for LRoutine in AModule.Routines do
  begin
    if LRoutine is TRoutineNode then
      AnalyzeRoutine(TRoutineNode(LRoutine));
  end;

  // Analyze module body
  if AModule.Body <> nil then
    AnalyzeBlock(AModule.Body);

  FSymbols.LeaveModuleScope();
end;

procedure TSemanticAnalyzer.AnalyzeImports(const AImports: TList<TImportInfo>);
var
  LImport: TImportInfo;
begin
  // Clear any previous imports and register new ones
  FSymbols.ClearImports();
  
  for LImport in AImports do
  begin
    // Register import so Lookup() can find PUBLIC symbols
    FSymbols.ImportModule(LImport.Name);
  end;
end;

procedure TSemanticAnalyzer.AnalyzeConst(const AConst: TConstNode);
var
  LSymbol: TSymbol;
  LExprType: TTypeSymbol;
  LDeclaredType: TTypeSymbol;
begin
  // Check for duplicate
  if FSymbols.CurrentScope.Contains(AConst.ConstName) then
  begin
    Error(AConst, 'E200', 'Duplicate identifier: %s', [AConst.ConstName]);
    Exit;
  end;

  // Analyze expression
  LExprType := AnalyzeExpression(AConst.Value);

  // If typed constant, verify type compatibility
  if AConst.TypeName <> '' then
  begin
    LDeclaredType := ResolveTypeName(AConst.TypeName, AConst);
    if LDeclaredType = nil then
    begin
      Error(AConst, 'E206', 'Unknown type: %s', [AConst.TypeName]);
      Exit;
    end;

    // Check type compatibility
    if not AreTypesCompatible(LDeclaredType, LExprType) then
    begin
      Error(AConst, 'E207', 'Type mismatch in constant declaration');
      Exit;
    end;

    // Use declared type
    LExprType := LDeclaredType;
  end;

  // Create symbol
  LSymbol := TSymbol.Create();
  LSymbol.SymbolName := AConst.ConstName;
  LSymbol.Kind := skConst;
  LSymbol.TypeRef := LExprType;
  LSymbol.IsPublic := AConst.IsPublic;
  LSymbol.Node := AConst;

  FSymbols.Define(LSymbol);
end;

procedure TSemanticAnalyzer.AnalyzeType(const AType: TTypeNode);
var
  LSymbol: TTypeSymbol;
  LAliasedType: TTypeSymbol;
begin
  // Check for duplicate
  if FSymbols.CurrentScope.Contains(AType.TypeName) then
  begin
    Error(AType, 'E201', 'Duplicate type: %s', [AType.TypeName]);
    Exit;
  end;

  // Handle routine types specially
  if AType is TRoutineTypeNode then
  begin
    AnalyzeRoutineType(TRoutineTypeNode(AType));
    Exit;
  end;

  // Create type symbol
  LSymbol := TTypeSymbol.Create();
  LSymbol.SymbolName := AType.TypeName;
  LSymbol.IsPublic := AType.IsPublic;
  LSymbol.Node := AType;

  // For simple type aliases (TDateTime = FLOAT), resolve and store the aliased type
  if (AType.AliasedType <> '') and not (AType is TRecordNode) and
     not (AType is TArrayTypeNode) and not (AType is TSetTypeNode) and
     not (AType is TPointerTypeNode) then
  begin
    LAliasedType := ResolveTypeName(AType.AliasedType, AType);
    LSymbol.TypeRef := LAliasedType;  // Store aliased type in TypeRef
  end;

  FSymbols.Define(LSymbol);

  // Analyze record fields
  if AType is TRecordNode then
    AnalyzeRecord(TRecordNode(AType));
end;

procedure TSemanticAnalyzer.AnalyzeRecord(const ARecord: TRecordNode);
var
  LField: TASTNode;
  LFieldNode: TFieldNode;
  LSymbol: TSymbol;
  LTypeSymbol: TTypeSymbol;
  LParentType: TTypeSymbol;
begin
  // Resolve parent type if extending
  if ARecord.ParentType <> '' then
  begin
    LParentType := ResolveTypeName(ARecord.ParentType, ARecord);
    NormalizeQualifiedType(ARecord.ParentType, LParentType);
    if LParentType <> nil then
    begin
      LTypeSymbol := FSymbols.LookupType(ARecord.TypeName);
      if LTypeSymbol <> nil then
        LTypeSymbol.BaseType := LParentType;
    end;
  end;

  // Analyze fields
  LTypeSymbol := FSymbols.LookupType(ARecord.TypeName);

  for LField in ARecord.Fields do
  begin
    if LField is TFieldNode then
    begin
      LFieldNode := TFieldNode(LField);

      LSymbol := TSymbol.Create();
      LSymbol.SymbolName := LFieldNode.FieldName;
      LSymbol.Kind := skField;
      LSymbol.TypeRef := ResolveTypeName(LFieldNode.TypeName, LFieldNode);
      NormalizeQualifiedType(LFieldNode.TypeName, LSymbol.TypeRef);
      LSymbol.Node := LFieldNode;

      if LTypeSymbol <> nil then
        LTypeSymbol.Fields.Add(LSymbol);
    end;
  end;
end;

function TSemanticAnalyzer.AnalyzeCallReturnType(const ANode: TCallNode): TTypeSymbol;
var
  LRoutineSym: TSymbol;
  LRoutineSymbol: TRoutineSymbol;
begin
  Result := nil;

  // Look up the routine symbol to get return type
  if ANode.Qualifier <> '' then
    LRoutineSym := FSymbols.LookupQualified(ANode.Qualifier, ANode.RoutineName)
  else
    LRoutineSym := FSymbols.Lookup(ANode.RoutineName);

  if (LRoutineSym <> nil) and (LRoutineSym is TRoutineSymbol) then
  begin
    LRoutineSymbol := TRoutineSymbol(LRoutineSym);
    Result := LRoutineSymbol.ReturnType;
  end;
end;

procedure TSemanticAnalyzer.AnalyzeRoutineType(const ARoutineType: TRoutineTypeNode);
var
  LSymbol: TRoutineTypeSymbol;
  LParam: TParamNode;
  LParamSym: TSymbol;
begin
  LSymbol := TRoutineTypeSymbol.Create();
  LSymbol.SymbolName := ARoutineType.TypeName;
  LSymbol.IsPublic := ARoutineType.IsPublic;
  LSymbol.Node := ARoutineType;
  LSymbol.CallingConv := ARoutineType.CallingConv;

  // Resolve parameters
  for LParam in ARoutineType.Params do
  begin
    LParamSym := TSymbol.Create();
    LParamSym.SymbolName := LParam.ParamName;
    LParamSym.Kind := skParam;
    LParamSym.TypeRef := ResolveTypeName(LParam.TypeName, LParam);
    NormalizeQualifiedType(LParam.TypeName, LParamSym.TypeRef);
    LParamSym.Node := LParam;
    LSymbol.Params.Add(LParamSym);
  end;

  // Resolve return type
  if ARoutineType.ReturnType <> '' then
  begin
    LSymbol.ReturnType := ResolveTypeName(ARoutineType.ReturnType, ARoutineType);
    NormalizeQualifiedType(ARoutineType.ReturnType, LSymbol.ReturnType);
  end;

  FSymbols.Define(LSymbol);
end;

procedure TSemanticAnalyzer.AnalyzeVar(const AVar: TVarDeclNode);
var
  LSymbol: TSymbol;
  LDeclaredType: TTypeSymbol;
  LInitType: TTypeSymbol;
begin
  // Check for duplicate
  if FSymbols.CurrentScope.Contains(AVar.VarName) then
  begin
    Error(AVar, 'E202', 'Duplicate variable: %s', [AVar.VarName]);
    Exit;
  end;

  // Resolve declared type
  LDeclaredType := ResolveTypeName(AVar.TypeName, AVar);
  NormalizeQualifiedType(AVar.TypeName, LDeclaredType);

  // If initialized, check type compatibility
  if AVar.InitValue <> nil then
  begin
    LInitType := AnalyzeExpression(AVar.InitValue);

    if (LDeclaredType <> nil) and (LInitType <> nil) then
    begin
      if not AreTypesCompatible(LDeclaredType, LInitType) then
        Error(AVar, 'E208', 'Type mismatch in variable initialization');
    end;
  end;

  // Create symbol
  LSymbol := TSymbol.Create();
  LSymbol.SymbolName := AVar.VarName;
  LSymbol.Kind := skVar;
  LSymbol.TypeRef := LDeclaredType;
  LSymbol.IsPublic := AVar.IsPublic;
  LSymbol.Node := AVar;

  FSymbols.Define(LSymbol);
end;

procedure TSemanticAnalyzer.AnalyzeRoutine(const ARoutine: TRoutineNode);
var
  LSymbol: TRoutineSymbol;
  LParam: TParamNode;
  LParamSymbol: TSymbol;
  LScopeParamSymbol: TSymbol;
  LVar: TVarDeclNode;
begin
  // Create routine symbol
  LSymbol := TRoutineSymbol.Create();
  LSymbol.SymbolName := ARoutine.RoutineName;
  LSymbol.IsPublic := ARoutine.IsPublic;
  LSymbol.Node := ARoutine;

  // Resolve return type
  if ARoutine.ReturnType <> '' then
  begin
    LSymbol.ReturnType := ResolveTypeName(ARoutine.ReturnType, ARoutine);
    NormalizeQualifiedType(ARoutine.ReturnType, LSymbol.ReturnType);
  end;

  // Detect method binding
  DetectMethodBinding(ARoutine, LSymbol);

  // Resolve external library name if it came from an identifier (must be a string const)
  if ARoutine.IsExternal and ARoutine.ExternalLibIsIdent then
  begin
    ARoutine.ExternalLib := ResolveConstantString(ARoutine.ExternalLib, ARoutine);
    // Add resolved library to linker
    if Assigned(FCompiler) and (ARoutine.ExternalLib <> '') then
      TCompiler(FCompiler).AddLibrary(ARoutine.ExternalLib);
  end;

  FSymbols.Define(LSymbol);

  // Enter routine scope
  FSymbols.EnterScope(ARoutine.RoutineName);
  FCurrentRoutine := ARoutine;

  // Register parameters
  for LParam in ARoutine.Params do
  begin
    // Create param symbol for routine's Params list (routine owns this)
    LParamSymbol := TSymbol.Create();
    LParamSymbol.SymbolName := LParam.ParamName;
    LParamSymbol.Kind := skParam;
    LParamSymbol.TypeRef := ResolveTypeName(LParam.TypeName, LParam);
    NormalizeQualifiedType(LParam.TypeName, LParamSymbol.TypeRef);
    LParamSymbol.Node := LParam;
    LSymbol.Params.Add(LParamSymbol);

    // Create separate param symbol for scope (scope owns this, freed on LeaveScope)
    LScopeParamSymbol := TSymbol.Create();
    LScopeParamSymbol.SymbolName := LParam.ParamName;
    LScopeParamSymbol.Kind := skParam;
    LScopeParamSymbol.TypeRef := LParamSymbol.TypeRef;
    LScopeParamSymbol.Node := LParam;
    FSymbols.Define(LScopeParamSymbol);
  end;

  // Register local variables
  for LVar in ARoutine.LocalVars do
    AnalyzeVar(LVar);

  // Analyze body
  if ARoutine.Body <> nil then
    AnalyzeBlock(ARoutine.Body);

  FCurrentRoutine := nil;
  FSymbols.LeaveScope();
end;

procedure TSemanticAnalyzer.DetectMethodBinding(const ARoutine: TRoutineNode; const ASymbol: TRoutineSymbol);
var
  LFirstParam: TParamNode;
  LTypeName: string;
  LTypeSymbol: TTypeSymbol;
begin
  // Method binding: declared with 'method' keyword OR first parameter is VAR Self/ASelf: TRecordType
  if ARoutine.Params.Count = 0 then
    Exit;

  LFirstParam := ARoutine.Params[0];

  if not LFirstParam.IsVar then
    Exit;

  // Check for Self (new method keyword) or ASelf (old style)
  if not (SameText(LFirstParam.ParamName, 'Self') or SameText(LFirstParam.ParamName, 'ASelf')) then
    Exit;

  LTypeName := LFirstParam.TypeName;
  LTypeSymbol := ResolveTypeName(LTypeName, LFirstParam);

  if LTypeSymbol = nil then
    Exit;

  // It's a method - register with the type
  ASymbol.IsMethod := True;
  ASymbol.BoundToType := LTypeSymbol;
  ARoutine.IsMethod := True;
  ARoutine.BoundToType := LTypeName;
  
  // Add method to type's method list
  LTypeSymbol.Methods.Add(ASymbol);
end;

procedure TSemanticAnalyzer.AnalyzeBlock(const ABlock: TBlockNode);
var
  LStmt: TASTNode;
begin
  for LStmt in ABlock.Statements do
    AnalyzeStatement(LStmt);
end;

procedure TSemanticAnalyzer.AnalyzeStatement(const AStmt: TASTNode);
begin
  if AStmt = nil then
    Exit;

  if AStmt is TIfNode then
    AnalyzeIf(TIfNode(AStmt))
  else if AStmt is TWhileNode then
    AnalyzeWhile(TWhileNode(AStmt))
  else if AStmt is TForNode then
    AnalyzeFor(TForNode(AStmt))
  else if AStmt is TRepeatNode then
    AnalyzeRepeat(TRepeatNode(AStmt))
  else if AStmt is TCaseNode then
    AnalyzeCase(TCaseNode(AStmt))
  else if AStmt is TReturnNode then
    AnalyzeReturn(TReturnNode(AStmt))
  else if AStmt is TAssignNode then
    AnalyzeAssign(TAssignNode(AStmt))
  else if AStmt is TCallNode then
    AnalyzeCall(TCallNode(AStmt))
  else if AStmt is TNewNode then
    AnalyzeNew(TNewNode(AStmt))
  else if AStmt is TDisposeNode then
    AnalyzeDispose(TDisposeNode(AStmt))
  else if AStmt is TBlockNode then
    AnalyzeBlock(TBlockNode(AStmt))
  else if AStmt is TInheritedCallNode then
    AnalyzeInherited(TInheritedCallNode(AStmt))
  else if AStmt is TTryNode then
    AnalyzeTry(TTryNode(AStmt))
  else if AStmt is TCppBlockNode then
    // C++ blocks pass through
  else if AStmt is TCppPassthroughNode then
    // C++ passthrough
  else
    AnalyzeExpression(AStmt);
end;

procedure TSemanticAnalyzer.AnalyzeIf(const ANode: TIfNode);
var
  LCondType: TTypeSymbol;
begin
  LCondType := AnalyzeExpression(ANode.Condition);

  if (LCondType <> nil) and not SameText(LCondType.SymbolName, 'BOOLEAN') then
    Error(ANode.Condition, 'E210', 'Condition must be boolean');

  if ANode.ThenBlock <> nil then
    AnalyzeBlock(ANode.ThenBlock);

  if ANode.ElseBlock <> nil then
    AnalyzeBlock(ANode.ElseBlock);
end;

procedure TSemanticAnalyzer.AnalyzeWhile(const ANode: TWhileNode);
var
  LCondType: TTypeSymbol;
begin
  LCondType := AnalyzeExpression(ANode.Condition);

  if (LCondType <> nil) and not SameText(LCondType.SymbolName, 'BOOLEAN') then
    Error(ANode.Condition, 'E211', 'Condition must be boolean');

  if ANode.Body <> nil then
    AnalyzeBlock(ANode.Body);
end;

procedure TSemanticAnalyzer.AnalyzeFor(const ANode: TForNode);
var
  LSymbol: TSymbol;
  LStartType: TTypeSymbol;
  LEndType: TTypeSymbol;
begin
  // Check loop variable exists
  LSymbol := FSymbols.Lookup(ANode.VarName);
  if LSymbol = nil then
    Error(ANode, 'E212', 'Undeclared loop variable: %s', [ANode.VarName]);

  LStartType := AnalyzeExpression(ANode.StartExpr);
  LEndType := AnalyzeExpression(ANode.EndExpr);

  // Check types are integer
  if (LStartType <> nil) and not SameText(LStartType.SymbolName, 'INTEGER') then
    Error(ANode.StartExpr, 'E213', 'Loop bounds must be integer');

  if (LEndType <> nil) and not SameText(LEndType.SymbolName, 'INTEGER') then
    Error(ANode.EndExpr, 'E213', 'Loop bounds must be integer');

  if ANode.Body <> nil then
    AnalyzeBlock(ANode.Body);
end;

procedure TSemanticAnalyzer.AnalyzeRepeat(const ANode: TRepeatNode);
var
  LCondType: TTypeSymbol;
begin
  if ANode.Body <> nil then
    AnalyzeBlock(ANode.Body);

  LCondType := AnalyzeExpression(ANode.Condition);

  if (LCondType <> nil) and not SameText(LCondType.SymbolName, 'BOOLEAN') then
    Error(ANode.Condition, 'E214', 'Condition must be boolean');
end;

procedure TSemanticAnalyzer.AnalyzeCase(const ANode: TCaseNode);
var
  LBranch: TCaseBranch;
  LValue: TASTNode;
begin
  AnalyzeExpression(ANode.Expr);

  for LBranch in ANode.Branches do
  begin
    for LValue in LBranch.Values do
      AnalyzeExpression(LValue);

    if LBranch.Body <> nil then
      AnalyzeBlock(LBranch.Body);
  end;

  if ANode.ElseBlock <> nil then
    AnalyzeBlock(ANode.ElseBlock);
end;

procedure TSemanticAnalyzer.AnalyzeReturn(const ANode: TReturnNode);
var
  LValueType: TTypeSymbol;
  LReturnType: TTypeSymbol;
begin
  if ANode.Value <> nil then
  begin
    LValueType := AnalyzeExpression(ANode.Value);

    // Check return type matches
    if (FCurrentRoutine <> nil) and (FCurrentRoutine.ReturnType <> '') then
    begin
      LReturnType := ResolveTypeName(FCurrentRoutine.ReturnType, ANode);
      if (LValueType <> nil) and (LReturnType <> nil) then
      begin
        if not AreTypesCompatible(LReturnType, LValueType) then
          Error(ANode, 'E215', 'Return type mismatch');
      end;
    end;
  end
  else
  begin
    // No return value - check routine has no return type
    if (FCurrentRoutine <> nil) and (FCurrentRoutine.ReturnType <> '') then
      Error(ANode, 'E216', 'Return value expected');
  end;
end;

procedure TSemanticAnalyzer.AnalyzeAssign(const ANode: TAssignNode);
var
  LTargetType: TTypeSymbol;
  LValueType: TTypeSymbol;
begin
  LTargetType := AnalyzeExpression(ANode.Target);
  LValueType := AnalyzeExpression(ANode.Value);

  if (LTargetType <> nil) and (LValueType <> nil) then
  begin
    if not AreTypesCompatible(LTargetType, LValueType) then
      Error(ANode, 'E217', 'Type mismatch in assignment');
  end;
end;

procedure TSemanticAnalyzer.AnalyzeCall(const ANode: TCallNode);
var
  LArg: TASTNode;
  LReceiverType: TTypeSymbol;
  LMethod: TSymbol;
  LReceiverIdent: TIdentifierNode;
  LImport: TImportInfo;
  LIsImportedModule: Boolean;
  LRoutineSym: TSymbol;
  LRoutineSymbol: TRoutineSymbol;
  I: Integer;
begin
  // Handle method calls (obj.Method())
  if ANode.IsMethodCall and (ANode.Receiver <> nil) then
  begin
    // Analyze receiver to get its type
    LReceiverType := AnalyzeExpression(ANode.Receiver);
    
    if LReceiverType <> nil then
    begin
      // Look for method in type hierarchy
      LMethod := LReceiverType.FindMethod(ANode.RoutineName);
      
      if LMethod <> nil then
      begin
        // It's a Myra method - keep IsMethodCall = True, IsCppPassthrough = False
        ANode.IsCppPassthrough := False;
      end
      else
      begin
        // Method not found in Myra types - pass through as C++
        ANode.IsCppPassthrough := True;
      end;
    end
    else
    begin
      // Unknown receiver type - could be module qualifier or C++ type
      // Check if receiver is a simple identifier that might be a module
      if ANode.Receiver is TIdentifierNode then
      begin
        LReceiverIdent := TIdentifierNode(ANode.Receiver);
        
        // First check if this matches an imported module name
        LIsImportedModule := False;
        for LImport in FCurrentModule.Imports do
        begin
          if SameText(LImport.Name, LReceiverIdent.IdentName) then
          begin
            LIsImportedModule := True;
            Break;
          end;
        end;
        
        if LIsImportedModule then
        begin
          // It's a module-qualified call (e.g., Console.PrintLn)
          ANode.Qualifier := LReceiverIdent.IdentName;
          ANode.IsMethodCall := False;
          ANode.IsCppPassthrough := False;
        end
        else if FSymbols.LookupQualified(LReceiverIdent.IdentName, ANode.RoutineName) <> nil then
        begin
          // It's a qualified call to a known routine
          ANode.Qualifier := LReceiverIdent.IdentName;
          ANode.IsMethodCall := False;
          ANode.IsCppPassthrough := False;
        end
        else
        begin
          // Not a module - assume C++ passthrough
          ANode.IsCppPassthrough := True;
        end;
      end
      else
      begin
        // Complex receiver expression - assume C++ passthrough
        ANode.IsCppPassthrough := True;
      end;
    end;
  end;

  // Look up the routine symbol to get parameter types
  //LRoutineSym := nil;
  if ANode.Qualifier <> '' then
    LRoutineSym := FSymbols.LookupQualified(ANode.Qualifier, ANode.RoutineName)
  else
    LRoutineSym := FSymbols.Lookup(ANode.RoutineName);

  // Analyze arguments and set expected types from parameter declarations
  for I := 0 to ANode.Args.Count - 1 do
  begin
    LArg := ANode.Args[I];
    if LArg <> nil then
    begin
      AnalyzeExpression(LArg);

      // If we found the routine and have parameter info, set expected type
      if (LRoutineSym <> nil) and (LRoutineSym is TRoutineSymbol) then
      begin
        LRoutineSymbol := TRoutineSymbol(LRoutineSym);
        if (LRoutineSymbol.Params <> nil) and (I < LRoutineSymbol.Params.Count) and
           (LRoutineSymbol.Params[I] <> nil) then
          LArg.ResolvedType := LRoutineSymbol.Params[I].TypeRef;
      end;
    end;
  end;
end;

procedure TSemanticAnalyzer.AnalyzeNew(const ANode: TNewNode);
begin
  AnalyzeExpression(ANode.Target);

  if ANode.AsType <> '' then
    ResolveTypeName(ANode.AsType, ANode);
end;

procedure TSemanticAnalyzer.AnalyzeDispose(const ANode: TDisposeNode);
begin
  AnalyzeExpression(ANode.Target);
end;

procedure TSemanticAnalyzer.AnalyzeTry(const ANode: TTryNode);
begin
  if ANode.TryBlock <> nil then
    AnalyzeBlock(ANode.TryBlock);

  if ANode.ExceptBlock <> nil then
    AnalyzeBlock(ANode.ExceptBlock);

  if ANode.FinallyBlock <> nil then
    AnalyzeBlock(ANode.FinallyBlock);
end;

procedure TSemanticAnalyzer.AnalyzeInherited(const ANode: TInheritedCallNode);
var
  LArg: TASTNode;
  LBoundType: TTypeSymbol;
  LParentType: TTypeSymbol;
  LMethodName: string;
begin
  // inherited can only be used inside a method
  if (FCurrentRoutine = nil) or (not FCurrentRoutine.IsMethod) then
  begin
    Error(ANode, 'E140', 'inherited can only be used inside a method');
    Exit;
  end;

  // Get the method name (use current method name if not specified)
  if ANode.MethodName <> '' then
    LMethodName := ANode.MethodName
  else
    LMethodName := FCurrentRoutine.RoutineName;

  // Get bound type and find parent
  LBoundType := ResolveTypeName(FCurrentRoutine.BoundToType, ANode);
  if LBoundType = nil then
  begin
    Error(ANode, 'E141', 'Cannot resolve bound type for method');
    Exit;
  end;

  LParentType := LBoundType.BaseType;
  if LParentType = nil then
  begin
    Error(ANode, 'E142', 'Type %s has no parent type', [FCurrentRoutine.BoundToType]);
    Exit;
  end;

  // Store resolved parent type for code generation
  ANode.ResolvedParentType := LParentType.SymbolName;

  // Analyze arguments
  for LArg in ANode.Args do
    AnalyzeExpression(LArg);
end;

function TSemanticAnalyzer.AnalyzeExpression(const AExpr: TASTNode): TTypeSymbol;
begin
  Result := nil;

  if AExpr = nil then
    Exit;

  if AExpr is TBinaryOpNode then
    Result := AnalyzeBinaryOp(TBinaryOpNode(AExpr))
  else if AExpr is TUnaryOpNode then
    Result := AnalyzeUnaryOp(TUnaryOpNode(AExpr))
  else if AExpr is TIdentifierNode then
    Result := AnalyzeIdentifier(TIdentifierNode(AExpr))
  else if AExpr is TFieldAccessNode then
    Result := AnalyzeFieldAccess(TFieldAccessNode(AExpr))
  else if AExpr is TIndexAccessNode then
    Result := AnalyzeIndexAccess(TIndexAccessNode(AExpr))
  else if AExpr is TDerefNode then
    Result := AnalyzeDeref(TDerefNode(AExpr))
  else if AExpr is TTypeCastNode then
    Result := AnalyzeTypeCast(TTypeCastNode(AExpr))
  else if AExpr is TTypeTestNode then
    Result := AnalyzeTypeTest(TTypeTestNode(AExpr))
  else if AExpr is TCallNode then
  begin
    AnalyzeCall(TCallNode(AExpr));
    Result := AnalyzeCallReturnType(TCallNode(AExpr));
  end
  else if AExpr is TIntegerLitNode then
    Result := FSymbols.GetBuiltInType('INTEGER')
  else if AExpr is TFloatLitNode then
    Result := FSymbols.GetBuiltInType('FLOAT')
  else if AExpr is TStringLitNode then
    Result := FSymbols.GetBuiltInType('STRING')
  else if AExpr is TCharLitNode then
    Result := FSymbols.GetBuiltInType('CHAR')
  else if AExpr is TBoolLitNode then
    Result := FSymbols.GetBuiltInType('BOOLEAN')
  else if AExpr is TNilLitNode then
    Result := FSymbols.GetBuiltInType('POINTER')
  else if AExpr is TSetLitNode then
    Result := FSymbols.GetBuiltInType('SET');

  // Store resolved type on the AST node for code generation
  AExpr.ResolvedType := Result;
end;

function TSemanticAnalyzer.AnalyzeBinaryOp(const ANode: TBinaryOpNode): TTypeSymbol;
var
  LLeftType: TTypeSymbol;
  LRightType: TTypeSymbol;
  LStringType: TTypeSymbol;
begin
  LLeftType := AnalyzeExpression(ANode.Left);
  LRightType := AnalyzeExpression(ANode.Right);

  // Handle CHAR/STRING coercion for comparison and equality operators
  if ANode.Op in [tkEquals, tkNotEquals, tkLess, tkGreater, tkLessEq, tkGreaterEq] then
  begin
    // If one side is CHAR and other is STRING, coerce CHAR to STRING
    if (LLeftType <> nil) and (LRightType <> nil) then
    begin
      if SameText(LLeftType.SymbolName, 'CHAR') and SameText(LRightType.SymbolName, 'STRING') then
      begin
        // Left is CHAR, right is STRING - coerce left to STRING
        LStringType := FSymbols.GetBuiltInType('STRING');
        ANode.Left.ResolvedType := LStringType;
      end
      else if SameText(LLeftType.SymbolName, 'STRING') and SameText(LRightType.SymbolName, 'CHAR') then
      begin
        // Left is STRING, right is CHAR - coerce right to STRING
        LStringType := FSymbols.GetBuiltInType('STRING');
        ANode.Right.ResolvedType := LStringType;
      end;
    end;
  end;

  // Determine result type based on operator
  case ANode.Op of
    tkPlus, tkMinus, tkStar:
      begin
        // Set operations - if either operand is a set, result is set
        if (LLeftType <> nil) and (SameText(LLeftType.SymbolName, 'SET') or (LLeftType.Node is TSetTypeNode)) then
          Result := LLeftType
        else if (LRightType <> nil) and (SameText(LRightType.SymbolName, 'SET') or (LRightType.Node is TSetTypeNode)) then
          Result := LRightType
        else if (LLeftType <> nil) and SameText(LLeftType.SymbolName, 'FLOAT') then
          Result := FSymbols.GetBuiltInType('FLOAT')
        else if (LRightType <> nil) and SameText(LRightType.SymbolName, 'FLOAT') then
          Result := FSymbols.GetBuiltInType('FLOAT')
        // String concatenation (+ only)
        else if (ANode.Op = tkPlus) and (LLeftType <> nil) and SameText(LLeftType.SymbolName, 'STRING') then
          Result := FSymbols.GetBuiltInType('STRING')
        // Unsigned integer arithmetic - both must be UINTEGER to return UINTEGER
        else if (LLeftType <> nil) and (LRightType <> nil) and
                SameText(LLeftType.SymbolName, 'UINTEGER') and SameText(LRightType.SymbolName, 'UINTEGER') then
          Result := FSymbols.GetBuiltInType('UINTEGER')
        else
          Result := FSymbols.GetBuiltInType('INTEGER');
      end;

    tkSlash, tkDiv, tkMod:
      begin
        if (LLeftType <> nil) and SameText(LLeftType.SymbolName, 'FLOAT') then
          Result := FSymbols.GetBuiltInType('FLOAT')
        else if (LRightType <> nil) and SameText(LRightType.SymbolName, 'FLOAT') then
          Result := FSymbols.GetBuiltInType('FLOAT')
        // Unsigned integer division - both must be UINTEGER to return UINTEGER
        else if (LLeftType <> nil) and (LRightType <> nil) and
                SameText(LLeftType.SymbolName, 'UINTEGER') and SameText(LRightType.SymbolName, 'UINTEGER') then
          Result := FSymbols.GetBuiltInType('UINTEGER')
        else
          Result := FSymbols.GetBuiltInType('INTEGER');
      end;

    tkEquals, tkNotEquals, tkLess, tkGreater, tkLessEq, tkGreaterEq:
      Result := FSymbols.GetBuiltInType('BOOLEAN');

    tkAnd, tkOr:
      Result := FSymbols.GetBuiltInType('BOOLEAN');

    tkIn:
      Result := FSymbols.GetBuiltInType('BOOLEAN');
  else
    Result := LLeftType;
  end;
end;

function TSemanticAnalyzer.AnalyzeUnaryOp(const ANode: TUnaryOpNode): TTypeSymbol;
begin
  Result := AnalyzeExpression(ANode.Operand);

  if ANode.Op = tkNot then
    Result := FSymbols.GetBuiltInType('BOOLEAN');
end;

function TSemanticAnalyzer.AnalyzeIdentifier(const ANode: TIdentifierNode): TTypeSymbol;
var
  LSymbol: TSymbol;
begin
  Result := nil;

  if ANode.Qualifier <> '' then
    LSymbol := FSymbols.LookupQualified(ANode.Qualifier, ANode.IdentName)
  else
    LSymbol := FSymbols.Lookup(ANode.IdentName);

  // Allow unknown identifiers for C++ interop
  if LSymbol <> nil then
    Result := LSymbol.TypeRef;
end;

function TSemanticAnalyzer.AnalyzeFieldAccess(const ANode: TFieldAccessNode): TTypeSymbol;
var
  LTargetType: TTypeSymbol;
  LField: TSymbol;
begin
  Result := nil;

  LTargetType := AnalyzeExpression(ANode.Target);

  if LTargetType = nil then
    Exit;

  // Look up field in type
  for LField in LTargetType.Fields do
  begin
    if SameText(LField.SymbolName, ANode.FieldName) then
    begin
      Result := LField.TypeRef;
      Exit;
    end;
  end;

  // Check parent type
  if LTargetType.BaseType <> nil then
  begin
    for LField in LTargetType.BaseType.Fields do
    begin
      if SameText(LField.SymbolName, ANode.FieldName) then
      begin
        Result := LField.TypeRef;
        Exit;
      end;
    end;
  end;

  // Allow unknown fields for C++ interop
end;

function TSemanticAnalyzer.AnalyzeIndexAccess(const ANode: TIndexAccessNode): TTypeSymbol;
var
  LTargetType: TTypeSymbol;
  LVarSymbol: TSymbol;
  LVarNode: TVarDeclNode;
  LTypeName: string;
  LBoundsStr: string;
  LPos: Integer;
  LLow: Integer;
  LArrayTypeNode: TArrayTypeNode;
begin
  LTargetType := AnalyzeExpression(ANode.Target);
  AnalyzeExpression(ANode.Index);

  // Default low bound is 0
  ANode.LowBound := 0;

  // Try to determine the array's low bound
  if ANode.Target is TIdentifierNode then
  begin
    LVarSymbol := FSymbols.Lookup(TIdentifierNode(ANode.Target).IdentName);
    if (LVarSymbol <> nil) and (LVarSymbol.Kind = skVar) and (LVarSymbol.Node is TVarDeclNode) then
    begin
      LVarNode := TVarDeclNode(LVarSymbol.Node);
      LTypeName := UpperCase(LVarNode.TypeName);

      // Check if it's an inline array type: ARRAY[low..high] OF ...
      if Pos('ARRAY', LTypeName) = 1 then
      begin
        LPos := Pos('[', LTypeName);
        if LPos > 0 then
        begin
          LBoundsStr := Copy(LTypeName, LPos + 1, Pos(']', LTypeName) - LPos - 1);
          LPos := Pos('..', LBoundsStr);
          if LPos > 0 then
          begin
            LLow := StrToIntDef(Trim(Copy(LBoundsStr, 1, LPos - 1)), 0);
            ANode.LowBound := LLow;
          end;
        end;
      end
      else if LVarSymbol.TypeRef <> nil then
      begin
        // Named type - check if it's an array type
        if (LVarSymbol.TypeRef.Node <> nil) and (LVarSymbol.TypeRef.Node is TArrayTypeNode) then
        begin
          LArrayTypeNode := TArrayTypeNode(LVarSymbol.TypeRef.Node);
          ANode.LowBound := LArrayTypeNode.LowBound;
        end;
      end;
    end;
  end
  else if LTargetType <> nil then
  begin
    // Target might be a named array type
    if (LTargetType.Node <> nil) and (LTargetType.Node is TArrayTypeNode) then
    begin
      LArrayTypeNode := TArrayTypeNode(LTargetType.Node);
      ANode.LowBound := LArrayTypeNode.LowBound;
    end;
  end;

  // TODO: Track element type of arrays for proper type checking
  Result := nil;
end;

function TSemanticAnalyzer.AnalyzeDeref(const ANode: TDerefNode): TTypeSymbol;
var
  LTargetType: TTypeSymbol;
begin
  Result := nil;

  LTargetType := AnalyzeExpression(ANode.Target);

  // Would need to track pointed-to type
  if LTargetType <> nil then
    Result := LTargetType.BaseType;
end;

function TSemanticAnalyzer.AnalyzeTypeCast(const ANode: TTypeCastNode): TTypeSymbol;
begin
  AnalyzeExpression(ANode.Expr);
  Result := ResolveTypeName(ANode.TypeName, ANode);
end;

function TSemanticAnalyzer.AnalyzeTypeTest(const ANode: TTypeTestNode): TTypeSymbol;
begin
  AnalyzeExpression(ANode.Expr);
  ResolveTypeName(ANode.TypeName, ANode);
  Result := FSymbols.GetBuiltInType('BOOLEAN');
end;

function TSemanticAnalyzer.ResolveConstantString(const AName: string; const ANode: TASTNode): string;
var
  LSymbol: TSymbol;
  LConstNode: TConstNode;
  LStringLit: TStringLitNode;
begin
  Result := '';

  LSymbol := FSymbols.Lookup(AName);
  if LSymbol = nil then
  begin
    Error(ANode, 'E203', 'Unknown constant: %s', [AName]);
    Exit;
  end;

  if LSymbol.Kind <> skConst then
  begin
    Error(ANode, 'E204', 'Expected constant but found: %s', [AName]);
    Exit;
  end;

  // Get the constant's value from its node
  if LSymbol.Node is TConstNode then
  begin
    LConstNode := TConstNode(LSymbol.Node);
    if LConstNode.Value is TStringLitNode then
    begin
      LStringLit := TStringLitNode(LConstNode.Value);
      Result := LStringLit.Value;
    end
    else
      Error(ANode, 'E205', 'Constant is not a string: %s', [AName]);
  end;
end;

function TSemanticAnalyzer.ResolveTypeName(const AName: string; const ANode: TASTNode): TTypeSymbol;
var
  LPos: Integer;
  LModule: string;
  LTypeName: string;
begin
  // Check for qualified name
  LPos := Pos('.', AName);
  if LPos > 0 then
  begin
    LModule := Copy(AName, 1, LPos - 1);
    LTypeName := Copy(AName, LPos + 1, Length(AName));
    Result := TTypeSymbol(FSymbols.LookupQualified(LModule, LTypeName));
  end
  else
    Result := FSymbols.LookupType(AName);

  // Allow unknown types for C++ interop
end;

function TSemanticAnalyzer.AreTypesCompatible(const ALeft: TTypeSymbol; const ARight: TTypeSymbol): Boolean;
begin
  if (ALeft = nil) or (ARight = nil) then
  begin
    Result := True; // Allow unknown types for C++ interop
    Exit;
  end;

  // Same type
  if ALeft = ARight then
  begin
    Result := True;
    Exit;
  end;

  // Same name
  if SameText(ALeft.SymbolName, ARight.SymbolName) then
  begin
    Result := True;
    Exit;
  end;

  // NIL compatible with any pointer
  if SameText(ARight.SymbolName, 'POINTER') then
  begin
    Result := True;
    Exit;
  end;

  // Integer/Float compatibility - FLOAT accepts INTEGER or UINTEGER
  if SameText(ALeft.SymbolName, 'FLOAT') and
     (SameText(ARight.SymbolName, 'INTEGER') or SameText(ARight.SymbolName, 'UINTEGER')) then
  begin
    Result := True;
    Exit;
  end;

  // INTEGER and UINTEGER are compatible with each other
  if (SameText(ALeft.SymbolName, 'INTEGER') or SameText(ALeft.SymbolName, 'UINTEGER')) and
     (SameText(ARight.SymbolName, 'INTEGER') or SameText(ARight.SymbolName, 'UINTEGER')) then
  begin
    Result := True;
    Exit;
  end;

  // Type alias compatibility: if left is a type alias, check against its aliased type
  if (ALeft.TypeRef <> nil) then
  begin
    Result := AreTypesCompatible(ALeft.TypeRef, ARight);
    Exit;
  end;

  // SET literal compatible with any set type
  if SameText(ARight.SymbolName, 'SET') then
  begin
    if SameText(ALeft.SymbolName, 'SET') or (ALeft.Node is TSetTypeNode) then
    begin
      Result := True;
      Exit;
    end;
    // Allow {elements} syntax for array initialization
    if (ALeft.Node is TArrayTypeNode) then
    begin
      Result := True;
      Exit;
    end;
  end;

  // Check inheritance
  if ARight.BaseType <> nil then
  begin
    Result := AreTypesCompatible(ALeft, ARight.BaseType);
    Exit;
  end;

  Result := False;
end;

procedure TSemanticAnalyzer.Error(const ANode: TASTNode; const ACode: string; const AMessage: string);
begin
  FErrors.Add(ANode.Filename, ANode.Line, ANode.Column, esError, ACode, AMessage);
end;

procedure TSemanticAnalyzer.Error(const ANode: TASTNode; const ACode: string; const AMessage: string; const AArgs: array of const);
begin
  FErrors.Add(ANode.Filename, ANode.Line, ANode.Column, esError, ACode, AMessage, AArgs);
end;

procedure TSemanticAnalyzer.NormalizeQualifiedType(var ATypeName: string; const AResolvedType: TTypeSymbol);
begin
  // Only convert if Myra resolved the type (non-nil) AND it contains '.'
  // If nil, it's a C++ passthrough type - leave unchanged
  if (AResolvedType <> nil) and (Pos('.', ATypeName) > 0) then
    ATypeName := StringReplace(ATypeName, '.', '::', [rfReplaceAll]);
end;

end.
