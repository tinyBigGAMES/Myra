{===============================================================================
  Myra™ - Pascal. Refined.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit Myra.CodeGen;

{$I Myra.Defines.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  Myra.Utils,
  Myra.Errors,
  Myra.Token,
  Myra.AST,
  Myra.Symbols,
  Myra.Compiler;

type
  { TSourceFile }
  TSourceFile = (
    sfHeader,
    sfSource
  );

  { TCodeGen }
  TCodeGen = class(TBaseObject)
  private
    FErrors: TErrors;
    FSymbols: TSymbolTable;
    FCompiler: TCompiler;
    FModuleName: string;
    FModuleKind: TModuleKind;
    FOutput: array[TSourceFile] of TStringBuilder;
    FIndent: array[TSourceFile] of Integer;

    procedure Emit(const ATarget: TSourceFile; const AText: string);
    procedure EmitLn(const ATarget: TSourceFile; const AText: string = '');
    procedure EmitFmt(const ATarget: TSourceFile; const AText: string; const AArgs: array of const);
    procedure EmitLnFmt(const ATarget: TSourceFile; const AText: string; const AArgs: array of const);
    procedure EmitLine(const ATarget: TSourceFile; const ANode: TASTNode);
    procedure IncIndent(const ATarget: TSourceFile);
    procedure DecIndent(const ATarget: TSourceFile);
    function GetIndent(const ATarget: TSourceFile): string;

    procedure EmitModule(const AModule: TModuleNode);
    procedure EmitModuleBody(const AModule: TModuleNode);
    procedure EmitIncludes(const AModule: TModuleNode);
    procedure EmitForwardDecls(const AModule: TModuleNode);
    procedure EmitTypeDecl(const AType: TTypeNode);
    procedure EmitRecordDecl(const ARecord: TRecordNode);
    procedure EmitRoutineTypeDecl(const ARoutineType: TRoutineTypeNode);
    procedure EmitConstDecl(const AConst: TConstNode);
    procedure EmitVarDecl(const AVar: TVarDeclNode);
    procedure EmitRoutineDecl(const ARoutine: TRoutineNode);
    procedure EmitRoutineImpl(const ARoutine: TRoutineNode);
    {$HINTS OFF}
    procedure EmitParams(const AParams: TObjectList<TParamNode>);
    {$HINTS ON}
    procedure EmitParamsTo(const ATarget: TSourceFile; const AParams: TObjectList<TParamNode>);
    procedure EmitBlock(const ABlock: TBlockNode);
    procedure EmitBlockTo(const ATarget: TSourceFile; const ABlock: TBlockNode);
    procedure EmitStatement(const AStmt: TASTNode);
    procedure EmitIf(const ANode: TIfNode);
    procedure EmitWhile(const ANode: TWhileNode);
    procedure EmitFor(const ANode: TForNode);
    procedure EmitRepeat(const ANode: TRepeatNode);
    procedure EmitCase(const ANode: TCaseNode);
    procedure EmitReturn(const ANode: TReturnNode);
    procedure EmitAssign(const ANode: TAssignNode);
    procedure EmitCall(const ANode: TCallNode);
    procedure EmitNew(const ANode: TNewNode);
    procedure EmitDispose(const ANode: TDisposeNode);
    procedure EmitSetLength(const ANode: TSetLengthNode);
    procedure EmitTry(const ANode: TTryNode);
    procedure EmitInherited(const ANode: TInheritedCallNode);
    procedure EmitCppBlock(const ANode: TCppBlockNode);
    procedure EmitTestImpl(const ATest: TTestNode; const AIndex: Integer);
    procedure EmitTestRegistration(const ATest: TTestNode; const AIndex: Integer);
    function RuntimeNS(): string;
    function EmitExpression(const AExpr: TASTNode): string;
    function EmitBinaryOp(const ANode: TBinaryOpNode): string;
    function EmitUnaryOp(const ANode: TUnaryOpNode): string;
    function EmitIdentifier(const ANode: TIdentifierNode): string;
    function EmitFieldAccess(const ANode: TFieldAccessNode): string;
    function EmitIndexAccess(const ANode: TIndexAccessNode): string;
    function EmitDeref(const ANode: TDerefNode): string;
    function EmitTypeCast(const ANode: TTypeCastNode): string;
    function EmitTypeTest(const ANode: TTypeTestNode): string;
    function EmitSetLiteral(const ANode: TSetLitNode): string;
    function EmitArrayLiteral(const ANode: TSetLitNode): string;
    function IsArrayType(const ATypeName: string): Boolean;

    function TypeToCpp(const ATypeName: string): string;
    function OpToCpp(const AOp: TTokenKind): string;
    function EscapeForCpp(const AValue: string): string;
    procedure EmitVarWithType(const ATarget: TSourceFile; const APrefix: string; const AVarName: string; const ATypeName: string; const ASuffix: string);

  public
    constructor Create(); override;
    destructor Destroy(); override;

    procedure Process(const AModule: TModuleNode; const ASymbols: TSymbolTable; const ACompiler: TCompiler; const AErrors: TErrors);
    function GetHeader(): string;
    function GetSource(): string;
    procedure SaveFiles(const AOutputPath: string);
  end;

implementation

{ TCodeGen }

constructor TCodeGen.Create();
begin
  inherited Create();

  FOutput[sfHeader] := TStringBuilder.Create();
  FOutput[sfSource] := TStringBuilder.Create();
end;

destructor TCodeGen.Destroy();
begin
  FOutput[sfSource].Free();
  FOutput[sfHeader].Free();

  inherited Destroy();
end;

procedure TCodeGen.Emit(const ATarget: TSourceFile; const AText: string);
begin
  FOutput[ATarget].Append(AText);
end;

procedure TCodeGen.EmitLn(const ATarget: TSourceFile; const AText: string);
begin
  FOutput[ATarget].Append(GetIndent(ATarget));
  FOutput[ATarget].AppendLine(AText);
end;

procedure TCodeGen.EmitFmt(const ATarget: TSourceFile; const AText: string; const AArgs: array of const);
begin
  FOutput[ATarget].Append(Format(AText, AArgs));
end;

procedure TCodeGen.EmitLnFmt(const ATarget: TSourceFile; const AText: string; const AArgs: array of const);
begin
  FOutput[ATarget].Append(GetIndent(ATarget));
  FOutput[ATarget].AppendLine(Format(AText, AArgs));
end;

procedure TCodeGen.EmitLine(const ATarget: TSourceFile; const ANode: TASTNode);
var
  LFilename: string;
begin
  if ANode <> nil then
  begin
    LFilename := ANode.Filename;
    
    // Expand relative paths to absolute for debugger compatibility
    if not TPath.IsPathRooted(LFilename) then
      LFilename := TPath.GetFullPath(LFilename);
    
    // Normalize path: replace backslashes with forward slashes for C++ #line directive
    LFilename := StringReplace(LFilename, '\', '/', [rfReplaceAll]);
    
    EmitLnFmt(ATarget, '#line %d "%s"', [ANode.Line, LFilename]);
  end;
end;

procedure TCodeGen.IncIndent(const ATarget: TSourceFile);
begin
  Inc(FIndent[ATarget]);
end;

procedure TCodeGen.DecIndent(const ATarget: TSourceFile);
begin
  if FIndent[ATarget] > 0 then
    Dec(FIndent[ATarget]);
end;

function TCodeGen.GetIndent(const ATarget: TSourceFile): string;
begin
  Result := StringOfChar(' ', FIndent[ATarget] * 4);
end;

procedure TCodeGen.Process(const AModule: TModuleNode; const ASymbols: TSymbolTable; const ACompiler: TCompiler; const AErrors: TErrors);
begin
  FErrors := AErrors;
  FSymbols := ASymbols;
  FCompiler := ACompiler;
  FModuleName := AModule.ModuleName;
  FModuleKind := AModule.ModuleKind;
  FIndent[sfHeader] := 0;
  FIndent[sfSource] := 0;
  FOutput[sfHeader].Clear();
  FOutput[sfSource].Clear();

  // Enter module scope so lookups find module-local types
  FSymbols.EnterModuleScope(FModuleName);
  try
    EmitModule(AModule);
  finally
    FSymbols.LeaveModuleScope();
  end;
end;

procedure TCodeGen.EmitModule(const AModule: TModuleNode);
var
  LType: TASTNode;
  LConst: TASTNode;
  LVar: TASTNode;
  LRoutine: TASTNode;
  LCppBlock: TASTNode;
  LNeedsNamespace: Boolean;
begin
  // Determine if we need namespace wrapping
  // Only libraries use namespaces (they're meant to be imported)
  // DLLs don't use namespaces (for C ABI compatibility)
  // Executables don't use namespaces (main() needs direct access to local items)
  LNeedsNamespace := (AModule.ModuleKind = mkLibrary);

  // Header file
  EmitLnFmt(sfHeader, '// %s.h - Generated by Myra Compiler', [FModuleName]);
  EmitLn(sfHeader, '#pragma once');
  EmitLn(sfHeader);

  EmitIncludes(AModule);
  EmitLn(sfHeader);

  // Forward declarations
  EmitForwardDecls(AModule);

  // C++ header blocks (emitted BEFORE namespace for global scope access)
  for LCppBlock in AModule.CppBlocks do
  begin
    if (LCppBlock is TCppBlockNode) and (TCppBlockNode(LCppBlock).Target = ctHeader) then
      EmitCppBlock(TCppBlockNode(LCppBlock));
  end;

  // Open namespace for header
  if LNeedsNamespace then
  begin
    EmitLnFmt(sfHeader, 'namespace %s {', [FModuleName]);
    EmitLn(sfHeader);
  end;

  // Type declarations
  for LType in AModule.Types do
  begin
    if LType is TTypeNode then
      EmitTypeDecl(TTypeNode(LType))
    else if LType is TCppBlockNode then
    begin
      EmitLine(sfHeader, TCppBlockNode(LType));
      EmitLn(sfHeader, TCppBlockNode(LType).RawText);
    end;
  end;

  // Constants
  for LConst in AModule.Consts do
  begin
    if LConst is TConstNode then
      EmitConstDecl(TConstNode(LConst))
    else if LConst is TCppBlockNode then
    begin
      EmitLine(sfHeader, TCppBlockNode(LConst));
      EmitLn(sfHeader, TCppBlockNode(LConst).RawText);
    end;
  end;

  // Variables (extern in header)
  for LVar in AModule.Vars do
  begin
    if LVar is TVarDeclNode then
    begin
      if TVarDeclNode(LVar).IsPublic then
      begin
        if FModuleKind = mkDll then
          EmitVarWithType(sfHeader, 'extern __declspec(dllimport) ', TVarDeclNode(LVar).VarName, TVarDeclNode(LVar).TypeName, ';')
        else
          EmitVarWithType(sfHeader, 'extern ', TVarDeclNode(LVar).VarName, TVarDeclNode(LVar).TypeName, ';');
      end;
    end;
  end;

  EmitLn(sfHeader);

  // Routine declarations
  for LRoutine in AModule.Routines do
  begin
    if LRoutine is TRoutineNode then
      EmitRoutineDecl(TRoutineNode(LRoutine));
  end;

  // Close namespace for header
  if LNeedsNamespace then
  begin
    EmitLn(sfHeader);
    EmitLnFmt(sfHeader, '} // namespace %s', [FModuleName]);
  end;

  // Source file
  EmitLnFmt(sfSource, '// %s.cpp - Generated by Myra Compiler', [FModuleName]);
  EmitLnFmt(sfSource, '#include "%s.h"', [FModuleName]);
  EmitLn(sfSource);

  // Open namespace for source
  if LNeedsNamespace then
  begin
    EmitLnFmt(sfSource, 'namespace %s {', [FModuleName]);
    EmitLn(sfSource);
  end;

  // Variable definitions
  for LVar in AModule.Vars do
  begin
    if LVar is TVarDeclNode then
      EmitVarDecl(TVarDeclNode(LVar));
  end;

  EmitLn(sfSource);

  // Emit routines and C++ source blocks in source order (sorted by line number)
  var LSourceItems: TList<TASTNode> := TList<TASTNode>.Create();
  try
    // Collect routines
    for LRoutine in AModule.Routines do
      LSourceItems.Add(LRoutine);
    
    // Collect C++ source blocks (not header blocks)
    for LCppBlock in AModule.CppBlocks do
    begin
      if (LCppBlock is TCppBlockNode) and (TCppBlockNode(LCppBlock).Target = ctSource) then
        LSourceItems.Add(LCppBlock);
    end;
    
    // Sort by line number
    LSourceItems.Sort(TComparer<TASTNode>.Construct(
      function(const ALeft: TASTNode; const ARight: TASTNode): Integer
      begin
        Result := ALeft.Line - ARight.Line;
      end
    ));
    
    // Emit in source order
    for var LItem in LSourceItems do
    begin
      if LItem is TRoutineNode then
        EmitRoutineImpl(TRoutineNode(LItem))
      else if LItem is TCppBlockNode then
        EmitCppBlock(TCppBlockNode(LItem));
    end;
  finally
    LSourceItems.Free();
  end;

  // Close namespace for source
  if LNeedsNamespace then
  begin
    EmitLn(sfSource);
    EmitLnFmt(sfSource, '} // namespace %s', [FModuleName]);
  end;

  // Unit test functions and registration (if unit test mode and tests exist)
  if Assigned(FCompiler) and FCompiler.GetUnitTestMode() and (AModule.Tests.Count > 0) then
  begin
    EmitLn(sfSource);
    EmitLn(sfSource, '// Unit Test Functions');
    for var I := 0 to AModule.Tests.Count - 1 do
      EmitTestImpl(AModule.Tests[I], I);

    EmitLn(sfSource);
    EmitLn(sfSource, '// Unit Test Registration');
    for var I := 0 to AModule.Tests.Count - 1 do
      EmitTestRegistration(AModule.Tests[I], I);
  end;

  // Module body -> int main() (only for exe modules)
  if AModule.ModuleKind = mkExecutable then
    EmitModuleBody(AModule);
end;

procedure TCodeGen.EmitModuleBody(const AModule: TModuleNode);
begin
  EmitLn(sfSource, 'int main(int argc, char* argv[]) {');
  IncIndent(sfSource);

  // Initialize Myra runtime
  EmitLn(sfSource, 'Myra::internal::SetCommandLine(argc, argv);');
  EmitLn(sfSource, 'Myra::internal::InitConsole();');
  EmitLn(sfSource);

  // Unit test mode: call RunTests and return early
  if Assigned(FCompiler) and FCompiler.GetUnitTestMode() then
  begin
    EmitLn(sfSource, '#ifdef MYRA_UNITTESTING');
    EmitLn(sfSource, 'return UnitTest::RunTests();');
    EmitLn(sfSource, '#endif');
  end;

  if AModule.Body <> nil then
    EmitBlock(AModule.Body);

  EmitLn(sfSource);
  EmitLn(sfSource, 'return 0;');
  DecIndent(sfSource);
  EmitLn(sfSource, '}');
end;

procedure TCodeGen.EmitIncludes(const AModule: TModuleNode);
var
  LImport: TImportInfo;
  LHeaders: TArray<string>;
  LHeader: string;
begin
  // Standard includes
  EmitLn(sfHeader, '#include <cstdint>');
  EmitLn(sfHeader, '#include <string>');
  EmitLn(sfHeader, '#include <vector>');

  // Myra runtime for EXE modules
  if AModule.ModuleKind = mkExecutable then
    EmitLn(sfHeader, '#include "myra_runtime.h"');

  // Collected headers from #include_header directives
  if Assigned(FCompiler) then
  begin
    LHeaders := FCompiler.GetIncludeHeaders();
    for LHeader in LHeaders do
      EmitLnFmt(sfHeader, '#include %s', [LHeader]);
  end;

  // Module imports
  for LImport in AModule.Imports do
    EmitLnFmt(sfHeader, '#include "%s.h"', [LImport.Name]);
end;

procedure TCodeGen.EmitForwardDecls(const AModule: TModuleNode);
var
  LType: TASTNode;
begin
  for LType in AModule.Types do
  begin
    if LType is TRecordNode then
      EmitLnFmt(sfHeader, 'struct %s;', [TRecordNode(LType).TypeName]);
  end;

  if AModule.Types.Count > 0 then
    EmitLn(sfHeader);
end;

procedure TCodeGen.EmitTypeDecl(const AType: TTypeNode);
begin
  if AType is TRecordNode then
    EmitRecordDecl(TRecordNode(AType))
  else if AType is TRoutineTypeNode then
    EmitRoutineTypeDecl(TRoutineTypeNode(AType))
  else if AType is TSetTypeNode then
  begin
    // SET OF 0..31 -> using TTypeName = uint64_t;
    EmitLine(sfHeader, AType);
    EmitLnFmt(sfHeader, 'using %s = uint64_t;', [AType.TypeName]);
    EmitLn(sfHeader);
  end
  else if AType is TArrayTypeNode then
  begin
    // ARRAY[0..9] OF INTEGER -> using TTypeName = int64_t[10];
    EmitLine(sfHeader, AType);
    with TArrayTypeNode(AType) do
    begin
      if IsDynamic then
        EmitLnFmt(sfHeader, 'using %s = std::vector<%s>;', [TypeName, TypeToCpp(ElementType)])
      else
        EmitLnFmt(sfHeader, 'using %s = %s[%d];', [TypeName, TypeToCpp(ElementType), HighBound - LowBound + 1]);
    end;
    EmitLn(sfHeader);
  end
  else if AType is TPointerTypeNode then
  begin
    // POINTER TO TType -> using TTypeName = TType*;
    EmitLine(sfHeader, AType);
    if TPointerTypeNode(AType).BaseType <> '' then
      EmitLnFmt(sfHeader, 'using %s = %s*;', [AType.TypeName, TypeToCpp(TPointerTypeNode(AType).BaseType)])
    else
      EmitLnFmt(sfHeader, 'using %s = void*;', [AType.TypeName]);
    EmitLn(sfHeader);
  end
  else if AType.AliasedType <> '' then
  begin
    // Simple type alias: TDateTime = FLOAT -> using TDateTime = double;
    EmitLine(sfHeader, AType);
    EmitLnFmt(sfHeader, 'using %s = %s;', [AType.TypeName, TypeToCpp(AType.AliasedType)]);
    EmitLn(sfHeader);
  end;
end;

procedure TCodeGen.EmitRecordDecl(const ARecord: TRecordNode);
var
  LField: TASTNode;
  LFieldNode: TFieldNode;
begin
  EmitLine(sfHeader, ARecord);

  if ARecord.ParentType <> '' then
    EmitLnFmt(sfHeader, 'struct %s : public %s {', [ARecord.TypeName, ARecord.ParentType])
  else
    EmitLnFmt(sfHeader, 'struct %s {', [ARecord.TypeName]);

  IncIndent(sfHeader);

  // Virtual destructor for polymorphism (enables dynamic_cast)
  EmitLnFmt(sfHeader, 'virtual ~%s() = default;', [ARecord.TypeName]);

  for LField in ARecord.Fields do
  begin
    if LField is TFieldNode then
    begin
      LFieldNode := TFieldNode(LField);
      EmitVarWithType(sfHeader, '', LFieldNode.FieldName, LFieldNode.TypeName, ';');
    end;
  end;

  DecIndent(sfHeader);
  EmitLn(sfHeader, '};');
  EmitLn(sfHeader);
end;

procedure TCodeGen.EmitRoutineTypeDecl(const ARoutineType: TRoutineTypeNode);
var
  LParam: TParamNode;
  LParams: string;
  LRetType: string;
  I: Integer;
  LCppType: string;
  LIsPointerType: Boolean;
begin
  EmitLine(sfHeader, ARoutineType);

  // Build parameter list
  LParams := '';
  for I := 0 to ARoutineType.Params.Count - 1 do
  begin
    LParam := ARoutineType.Params[I];
    if I > 0 then
      LParams := LParams + ', ';

    LCppType := TypeToCpp(LParam.TypeName);
    LIsPointerType := (Length(LCppType) > 0) and (LCppType[Length(LCppType)] = '*');

    if LParam.IsVar then
      LParams := LParams + LCppType + '&'
    else if LParam.IsConst then
    begin
      // For pointer types with const, use pass-by-value with const pointer
      if LIsPointerType then
        LParams := LParams + LCppType + ' const'
      else
        LParams := LParams + 'const ' + LCppType + '&';
    end
    else
      LParams := LParams + LCppType;
  end;

  // Return type
  if ARoutineType.ReturnType <> '' then
    LRetType := TypeToCpp(ARoutineType.ReturnType)
  else
    LRetType := 'void';

  // Emit: using TypeName = ReturnType(*)(Params);
  EmitLnFmt(sfHeader, 'using %s = %s(*)(%s);', [ARoutineType.TypeName, LRetType, LParams]);
  EmitLn(sfHeader);
end;

procedure TCodeGen.EmitConstDecl(const AConst: TConstNode);
var
  LValue: string;
  LType: string;
  LUpper: string;
begin
  EmitLine(sfHeader, AConst);

  // Context-aware emission: {elements} -> array initializer or set bitmask
  if (AConst.Value is TSetLitNode) and IsArrayType(AConst.TypeName) then
    LValue := EmitArrayLiteral(TSetLitNode(AConst.Value))
  else
    LValue := EmitExpression(AConst.Value);

  if AConst.TypeName <> '' then
  begin
    // Typed constant - use explicit type
    LType := TypeToCpp(AConst.TypeName);
    LUpper := UpperCase(AConst.TypeName);

    // STRING can't be constexpr, use const instead
    // Arrays also can't be constexpr in older C++ standards
    if (LUpper = 'STRING') or IsArrayType(AConst.TypeName) then
      EmitLnFmt(sfHeader, 'const %s %s = %s;', [LType, AConst.ConstName, LValue])
    else
      EmitLnFmt(sfHeader, 'constexpr %s %s = %s;', [LType, AConst.ConstName, LValue]);
  end
  else
    // Untyped constant - use auto
    EmitLnFmt(sfHeader, 'constexpr auto %s = %s;', [AConst.ConstName, LValue]);
end;

procedure TCodeGen.EmitVarDecl(const AVar: TVarDeclNode);
var
  LPrefix: string;
  LInit: string;
begin
  EmitLine(sfSource, AVar);
  LPrefix := '';
  if AVar.IsPublic and (FModuleKind = mkDll) then
    LPrefix := '__declspec(dllexport) ';

  if AVar.InitValue <> nil then
  begin
    // Context-aware emission: {elements} -> array initializer or set bitmask
    if (AVar.InitValue is TSetLitNode) and IsArrayType(AVar.TypeName) then
      LInit := EmitArrayLiteral(TSetLitNode(AVar.InitValue))
    else
      LInit := EmitExpression(AVar.InitValue);
    EmitVarWithType(sfSource, LPrefix, AVar.VarName, AVar.TypeName, ' = ' + LInit + ';');
  end
  else
    EmitVarWithType(sfSource, LPrefix, AVar.VarName, AVar.TypeName, ';');
end;

function CallingConvToCpp(const AConv: TCallingConvention): string;
begin
  case AConv of
    ccCdecl:    Result := '__cdecl ';
    ccStdcall:  Result := '__stdcall ';
    ccFastcall: Result := '__fastcall ';
  else
    Result := '';
  end;
end;

procedure TCodeGen.EmitRoutineDecl(const ARoutine: TRoutineNode);
var
  LReturnType: string;
  LPrefix: string;
  LCallingConv: string;
begin
  // External routines always need declarations (they have no implementation)
  // Non-external routines only need declarations if public
  if not ARoutine.IsExternal and not ARoutine.IsPublic then
    Exit;

  // Variadic routines are templates - declared in header with implementation
  // So we skip the separate declaration here
  if ARoutine.IsVariadic then
    Exit;

  EmitLine(sfHeader, ARoutine);

  if ARoutine.ReturnType <> '' then
    LReturnType := TypeToCpp(ARoutine.ReturnType)
  else
    LReturnType := 'void';

  // Build prefix
  LPrefix := '';
  if ARoutine.IsCExport then
    LPrefix := 'extern "C" ';

  // Add DLL export/import decorations
  if FModuleKind = mkDll then
  begin
    if ARoutine.IsExternal then
      LPrefix := LPrefix + '__declspec(dllimport) '
    else
      LPrefix := LPrefix + '__declspec(dllexport) ';
  end;

  // Calling convention
  LCallingConv := CallingConvToCpp(ARoutine.CallingConv);

  Emit(sfHeader, GetIndent(sfHeader));
  EmitFmt(sfHeader, '%s%s %s%s(', [LPrefix, LReturnType, LCallingConv, ARoutine.RoutineName]);
  EmitParamsTo(sfHeader, ARoutine.Params);
  Emit(sfHeader, ');'#10);
end;

procedure TCodeGen.EmitRoutineImpl(const ARoutine: TRoutineNode);
var
  LReturnType: string;
  LVar: TVarDeclNode;
  LTarget: TSourceFile;
  LPrefix: string;
  LCallingConv: string;
  LNeedsNamespaceWrap: Boolean;
begin
  // External routines have no implementation - skip
  if ARoutine.IsExternal then
    Exit;

  // Variadic routines must go in header (templates need to be in headers)
  if ARoutine.IsVariadic then
    LTarget := sfHeader
  else
    LTarget := sfSource;

  // For variadic routines going to header, we need to wrap in namespace
  // because the main namespace block is already closed at this point
  LNeedsNamespaceWrap := ARoutine.IsVariadic and (FModuleKind = mkLibrary);

  if LNeedsNamespaceWrap then
  begin
    EmitLn(LTarget);
    EmitLnFmt(LTarget, 'namespace %s {', [FModuleName]);
  end;

  EmitLine(LTarget, ARoutine);

  if ARoutine.ReturnType <> '' then
    LReturnType := TypeToCpp(ARoutine.ReturnType)
  else
    LReturnType := 'void';

  // Build prefix based on visibility and module kind
  LPrefix := '';
  if not ARoutine.IsPublic then
  begin
    // Non-public routines are static (internal linkage)
    LPrefix := 'static ';
  end
  else if FModuleKind = mkDll then
  begin
    // Public DLL routines get export decoration
    if ARoutine.IsCExport then
      LPrefix := 'extern "C" __declspec(dllexport) '
    else
      LPrefix := '__declspec(dllexport) ';
  end;

  // Calling convention
  LCallingConv := CallingConvToCpp(ARoutine.CallingConv);

  // Variadic template declaration
  if ARoutine.IsVariadic then
  begin
    EmitLn(LTarget, 'template<typename... Args>');
    Emit(LTarget, GetIndent(LTarget));
    EmitFmt(LTarget, '%s%s %s%s(Args&&... args) {'#10, [LPrefix, LReturnType, LCallingConv, ARoutine.RoutineName]);
  end
  else
  begin
    Emit(LTarget, GetIndent(LTarget));
    EmitFmt(LTarget, '%s%s %s%s(', [LPrefix, LReturnType, LCallingConv, ARoutine.RoutineName]);
    EmitParamsTo(LTarget, ARoutine.Params);
    Emit(LTarget, ') {'#10);
  end;

  IncIndent(LTarget);

  // Local variables
  for LVar in ARoutine.LocalVars do
  begin
    EmitLine(LTarget, LVar);
    if LVar.InitValue <> nil then
      EmitVarWithType(LTarget, '', LVar.VarName, LVar.TypeName, ' = ' + EmitExpression(LVar.InitValue) + ';')
    else
      EmitVarWithType(LTarget, '', LVar.VarName, LVar.TypeName, ';');
  end;

  if ARoutine.LocalVars.Count > 0 then
    EmitLn(LTarget);

  // Body
  if ARoutine.Body <> nil then
    EmitBlockTo(LTarget, ARoutine.Body);

  DecIndent(LTarget);
  EmitLn(LTarget, '}');

  if LNeedsNamespaceWrap then
    EmitLnFmt(LTarget, '} // namespace %s', [FModuleName])
  else
    EmitLn(LTarget);
end;

procedure TCodeGen.EmitParams(const AParams: TObjectList<TParamNode>);
begin
  EmitParamsTo(sfSource, AParams);
end;

procedure TCodeGen.EmitParamsTo(const ATarget: TSourceFile; const AParams: TObjectList<TParamNode>);
var
  I: Integer;
  LParam: TParamNode;
  LCppType: string;
  LIsPointerType: Boolean;
begin
  for I := 0 to AParams.Count - 1 do
  begin
    LParam := AParams[I];

    if I > 0 then
      Emit(ATarget, ', ');

    LCppType := TypeToCpp(LParam.TypeName);
    
    // Check if this is a pointer type (ends with * or is void*)
    LIsPointerType := (Length(LCppType) > 0) and (LCppType[Length(LCppType)] = '*');

    if LParam.IsVar then
      EmitFmt(ATarget, '%s& %s', [LCppType, LParam.ParamName])
    else if LParam.IsConst then
    begin
      // For pointer types with const, use pass-by-value with const pointer
      // to allow implicit pointer conversions while preventing modification
      if LIsPointerType then
        EmitFmt(ATarget, '%s const %s', [LCppType, LParam.ParamName])
      else
        EmitFmt(ATarget, 'const %s& %s', [LCppType, LParam.ParamName]);
    end
    else
      EmitFmt(ATarget, '%s %s', [LCppType, LParam.ParamName]);
  end;
end;

procedure TCodeGen.EmitBlock(const ABlock: TBlockNode);
begin
  EmitBlockTo(sfSource, ABlock);
end;

procedure TCodeGen.EmitBlockTo(const ATarget: TSourceFile; const ABlock: TBlockNode);
var
  LStmt: TASTNode;
begin
  for LStmt in ABlock.Statements do
  begin
    // Handle C++ blocks specially for variadic routines in header
    if LStmt is TCppBlockNode then
    begin
      EmitLn(ATarget, TCppBlockNode(LStmt).RawText);
    end
    else if ATarget = sfSource then
      EmitStatement(LStmt)
    else
    begin
      // For header target, we only support C++ blocks in variadic routine bodies
      // Other statements would need full EmitStatementTo implementation
      FErrors.Add(LStmt.Filename, LStmt.Line, LStmt.Column, esWarning, 'W001',
        'Non-C++ statements in variadic routine body may not emit correctly');
    end;
  end;
end;

procedure TCodeGen.EmitStatement(const AStmt: TASTNode);
begin
  if AStmt = nil then
    Exit;

  if AStmt is TIfNode then
    EmitIf(TIfNode(AStmt))
  else if AStmt is TWhileNode then
    EmitWhile(TWhileNode(AStmt))
  else if AStmt is TForNode then
    EmitFor(TForNode(AStmt))
  else if AStmt is TRepeatNode then
    EmitRepeat(TRepeatNode(AStmt))
  else if AStmt is TCaseNode then
    EmitCase(TCaseNode(AStmt))
  else if AStmt is TReturnNode then
    EmitReturn(TReturnNode(AStmt))
  else if AStmt is TAssignNode then
    EmitAssign(TAssignNode(AStmt))
  else if AStmt is TCallNode then
    EmitCall(TCallNode(AStmt))
  else if AStmt is TNewNode then
    EmitNew(TNewNode(AStmt))
  else if AStmt is TDisposeNode then
    EmitDispose(TDisposeNode(AStmt))
  else if AStmt is TSetLengthNode then
    EmitSetLength(TSetLengthNode(AStmt))
  else if AStmt is TTryNode then
    EmitTry(TTryNode(AStmt))
  else if AStmt is TInheritedCallNode then
    EmitInherited(TInheritedCallNode(AStmt))
  else if AStmt is TCppBlockNode then
    EmitCppBlock(TCppBlockNode(AStmt))
  else if AStmt is TBlockNode then
  begin
    EmitLn(sfSource, '{');
    IncIndent(sfSource);
    EmitBlock(TBlockNode(AStmt));
    DecIndent(sfSource);
    EmitLn(sfSource, '}');
  end;
end;

procedure TCodeGen.EmitIf(const ANode: TIfNode);
var
  LCond: string;
begin
  EmitLine(sfSource, ANode);
  LCond := EmitExpression(ANode.Condition);
  // These node types already produce wrapped output - don't double-wrap
  if (ANode.Condition is TBinaryOpNode) or
     (ANode.Condition is TUnaryOpNode) or
     (ANode.Condition is TDerefNode) then
    EmitLnFmt(sfSource, 'if %s {', [LCond])
  else
    EmitLnFmt(sfSource, 'if (%s) {', [LCond]);

  IncIndent(sfSource);
  if ANode.ThenBlock <> nil then
    EmitBlock(ANode.ThenBlock);
  DecIndent(sfSource);

  if ANode.ElseBlock <> nil then
  begin
    EmitLn(sfSource, '} else {');
    IncIndent(sfSource);
    EmitBlock(ANode.ElseBlock);
    DecIndent(sfSource);
  end;

  EmitLn(sfSource, '}');
end;

procedure TCodeGen.EmitWhile(const ANode: TWhileNode);
var
  LCond: string;
begin
  EmitLine(sfSource, ANode);
  LCond := EmitExpression(ANode.Condition);
  // These node types already produce wrapped output - don't double-wrap
  if (ANode.Condition is TBinaryOpNode) or
     (ANode.Condition is TUnaryOpNode) or
     (ANode.Condition is TDerefNode) then
    EmitLnFmt(sfSource, 'while %s {', [LCond])
  else
    EmitLnFmt(sfSource, 'while (%s) {', [LCond]);

  IncIndent(sfSource);
  if ANode.Body <> nil then
    EmitBlock(ANode.Body);
  DecIndent(sfSource);

  EmitLn(sfSource, '}');
end;

procedure TCodeGen.EmitFor(const ANode: TForNode);
var
  LStart: string;
  LEnd: string;
  LOp: string;
  LStep: string;
begin
  EmitLine(sfSource, ANode);
  LStart := EmitExpression(ANode.StartExpr);
  LEnd := EmitExpression(ANode.EndExpr);

  if ANode.IsDownTo then
  begin
    LOp := '>=';
    LStep := '--';
  end
  else
  begin
    LOp := '<=';
    LStep := '++';
  end;

  EmitLnFmt(sfSource, 'for (%s = %s; %s %s %s; %s%s) {', [
    ANode.VarName, LStart,
    ANode.VarName, LOp, LEnd,
    ANode.VarName, LStep
  ]);

  IncIndent(sfSource);
  if ANode.Body <> nil then
    EmitBlock(ANode.Body);
  DecIndent(sfSource);

  EmitLn(sfSource, '}');
end;

procedure TCodeGen.EmitRepeat(const ANode: TRepeatNode);
var
  LCond: string;
begin
  EmitLine(sfSource, ANode);
  EmitLn(sfSource, 'do {');

  IncIndent(sfSource);
  if ANode.Body <> nil then
    EmitBlock(ANode.Body);
  DecIndent(sfSource);

  LCond := EmitExpression(ANode.Condition);
  // These node types already produce wrapped output - don't double-wrap
  if (ANode.Condition is TBinaryOpNode) or
     (ANode.Condition is TUnaryOpNode) or
     (ANode.Condition is TDerefNode) then
    EmitLnFmt(sfSource, '} while (!%s);', [LCond])
  else
    EmitLnFmt(sfSource, '} while (!(%s));', [LCond]);
end;

procedure TCodeGen.EmitCase(const ANode: TCaseNode);
var
  LExpr: string;
  LBranch: TCaseBranch;
  LValue: TASTNode;
  LFirst: Boolean;
  LRange: TRangeNode;
  LLow: Int64;
  LHigh: Int64;
  I: Int64;
begin
  EmitLine(sfSource, ANode);
  LExpr := EmitExpression(ANode.Expr);
  EmitLnFmt(sfSource, 'switch (%s) {', [LExpr]);

  for LBranch in ANode.Branches do
  begin
    LFirst := True;
    for LValue in LBranch.Values do
    begin
      if LFirst then
        LFirst := False
      else
        EmitLn(sfSource);

      // Handle range values by expanding to individual case labels
      if LValue is TRangeNode then
      begin
        LRange := TRangeNode(LValue);
        // Only expand if both bounds are integer literals
        if (LRange.LowExpr is TIntegerLitNode) and (LRange.HighExpr is TIntegerLitNode) then
        begin
          LLow := TIntegerLitNode(LRange.LowExpr).Value;
          LHigh := TIntegerLitNode(LRange.HighExpr).Value;
          for I := LLow to LHigh do
          begin
            if I > LLow then
              EmitLn(sfSource);
            EmitLnFmt(sfSource, 'case %d:', [I]);
          end;
        end
        else
          // Fall back for non-literal ranges (emit as comment - won't compile)
          EmitLnFmt(sfSource, '// case %s..%s: (range not supported)', [EmitExpression(LRange.LowExpr), EmitExpression(LRange.HighExpr)]);
      end
      else
        EmitLnFmt(sfSource, 'case %s:', [EmitExpression(LValue)]);
    end;

    IncIndent(sfSource);
    if LBranch.Body <> nil then
      EmitBlock(LBranch.Body);
    EmitLn(sfSource, 'break;');
    DecIndent(sfSource);
  end;

  if ANode.ElseBlock <> nil then
  begin
    EmitLn(sfSource, 'default:');
    IncIndent(sfSource);
    EmitBlock(ANode.ElseBlock);
    EmitLn(sfSource, 'break;');
    DecIndent(sfSource);
  end;

  EmitLn(sfSource, '}');
end;

procedure TCodeGen.EmitReturn(const ANode: TReturnNode);
var
  LValue: string;
begin
  EmitLine(sfSource, ANode);

  if ANode.Value <> nil then
  begin
    LValue := EmitExpression(ANode.Value);
    EmitLnFmt(sfSource, 'return %s;', [LValue]);
  end
  else
    EmitLn(sfSource, 'return;');
end;

procedure TCodeGen.EmitAssign(const ANode: TAssignNode);
var
  LTarget: string;
  LValue: string;
begin
  EmitLine(sfSource, ANode);
  LTarget := EmitExpression(ANode.Target);
  LValue := EmitExpression(ANode.Value);
  EmitLnFmt(sfSource, '%s = %s;', [LTarget, LValue]);
end;

procedure TCodeGen.EmitCall(const ANode: TCallNode);
var
  LCall: string;
  LArg: TASTNode;
  I: Integer;
  LReceiver: string;
begin
  EmitLine(sfSource, ANode);

  // Handle method calls
  if ANode.IsMethodCall and (ANode.Receiver <> nil) then
  begin
    LReceiver := EmitExpression(ANode.Receiver);
    
    if ANode.IsCppPassthrough then
    begin
      // C++ member call: receiver.method(args)
      LCall := LReceiver + '.' + ANode.RoutineName + '(';
      for I := 0 to ANode.Args.Count - 1 do
      begin
        if I > 0 then
          LCall := LCall + ', ';
        LCall := LCall + EmitExpression(ANode.Args[I]);
      end;
      LCall := LCall + ');';
    end
    else
    begin
      // Myra method call: method(receiver, args)
      LCall := ANode.RoutineName + '(' + LReceiver;
      for I := 0 to ANode.Args.Count - 1 do
      begin
        LCall := LCall + ', ';
        LCall := LCall + EmitExpression(ANode.Args[I]);
      end;
      LCall := LCall + ');';
    end;
  end
  else
  begin
    // Regular call
    if ANode.Qualifier <> '' then
      LCall := ANode.Qualifier + '::' + ANode.RoutineName
    else
      LCall := ANode.RoutineName;

    LCall := LCall + '(';

    for I := 0 to ANode.Args.Count - 1 do
    begin
      LArg := ANode.Args[I];
      if I > 0 then
        LCall := LCall + ', ';
      LCall := LCall + EmitExpression(LArg);
    end;

    LCall := LCall + ');';
  end;
  
  EmitLn(sfSource, LCall);
end;

procedure TCodeGen.EmitNew(const ANode: TNewNode);
var
  LTarget: string;
  LType: string;
  LTargetType: TTypeSymbol;
  LPtrType: TPointerTypeNode;
  LTypeName: string;
  LUpperTypeName: string;
  LSymbol: TSymbol;
  LVarNode: TVarDeclNode;
begin
  EmitLine(sfSource, ANode);

  // Check if Target is a type cast (from "NEW(ptr AS Type)" syntax)
  if ANode.Target is TTypeCastNode then
  begin
    LTarget := EmitExpression(TTypeCastNode(ANode.Target).Expr);
    LType := TTypeCastNode(ANode.Target).TypeName;
  end
  else
  begin
    LTarget := EmitExpression(ANode.Target);
    if ANode.AsType <> '' then
      LType := ANode.AsType
    else
    begin
      // Try to deduce type from target
      LType := '';
      
      // Method 1: Check if target has a resolved type with a TPointerTypeNode
      if ANode.Target.ResolvedType <> nil then
      begin
        LTargetType := TTypeSymbol(ANode.Target.ResolvedType);
        if LTargetType.Node is TPointerTypeNode then
        begin
          LPtrType := TPointerTypeNode(LTargetType.Node);
          if LPtrType.BaseType <> '' then
            LType := LPtrType.BaseType;
        end;
      end;
      
      // Method 2: For identifiers, look up the variable declaration's type name
      if (LType = '') and (ANode.Target is TIdentifierNode) then
      begin
        LSymbol := FSymbols.Lookup(TIdentifierNode(ANode.Target).IdentName);
        if (LSymbol <> nil) and (LSymbol.Node is TVarDeclNode) then
        begin
          LVarNode := TVarDeclNode(LSymbol.Node);
          LTypeName := LVarNode.TypeName;
          LUpperTypeName := UpperCase(LTypeName);
          // Check for "POINTER TO X" inline type
          if Pos('POINTER TO ', LUpperTypeName) = 1 then
            LType := Trim(Copy(LTypeName, 12, Length(LTypeName)));
        end;
      end;
      
      // Fallback if we couldn't deduce the type
      if LType = '' then
        LType := 'auto';
    end;
  end;

  EmitLnFmt(sfSource, '%s = new %s();', [LTarget, TypeToCpp(LType)]);
end;

procedure TCodeGen.EmitDispose(const ANode: TDisposeNode);
var
  LTarget: string;
begin
  EmitLine(sfSource, ANode);
  LTarget := EmitExpression(ANode.Target);
  EmitLnFmt(sfSource, 'delete %s;', [LTarget]);
end;

procedure TCodeGen.EmitSetLength(const ANode: TSetLengthNode);
var
  LTarget: string;
  LSize: string;
begin
  EmitLine(sfSource, ANode);
  LTarget := EmitExpression(ANode.Target);
  LSize := EmitExpression(ANode.NewSize);
  EmitLnFmt(sfSource, '%s.resize(%s);', [LTarget, LSize]);
end;

procedure TCodeGen.EmitTestImpl(const ATest: TTestNode; const AIndex: Integer);
var
  LVar: TVarDeclNode;
  LConst: TASTNode;
  LType: TASTNode;
begin
  EmitLine(sfSource, ATest);
  EmitLnFmt(sfSource, 'void _myra_test_%d() {', [AIndex]);
  IncIndent(sfSource);

  // Local types
  for LType in ATest.LocalTypes do
  begin
    if LType is TTypeNode then
      EmitTypeDecl(TTypeNode(LType));
  end;

  // Local constants
  for LConst in ATest.LocalConsts do
  begin
    if LConst is TConstNode then
      EmitConstDecl(TConstNode(LConst));
  end;

  // Local variables
  for LVar in ATest.LocalVars do
  begin
    EmitLine(sfSource, LVar);
    if LVar.InitValue <> nil then
      EmitVarWithType(sfSource, '', LVar.VarName, LVar.TypeName, ' = ' + EmitExpression(LVar.InitValue) + ';')
    else
      EmitVarWithType(sfSource, '', LVar.VarName, LVar.TypeName, ';');
  end;

  if (ATest.LocalTypes.Count > 0) or (ATest.LocalConsts.Count > 0) or (ATest.LocalVars.Count > 0) then
    EmitLn(sfSource);

  // Body
  if ATest.Body <> nil then
    EmitBlock(ATest.Body);

  DecIndent(sfSource);
  EmitLn(sfSource, '}');
  EmitLn(sfSource);
end;

procedure TCodeGen.EmitTestRegistration(const ATest: TTestNode; const AIndex: Integer);
var
  LEscapedDesc: string;
  LFilename: string;
begin
  // Escape quotes in description for C++ string literal
  LEscapedDesc := StringReplace(ATest.Description, '\', '\\', [rfReplaceAll]);
  LEscapedDesc := StringReplace(LEscapedDesc, '"', '\"', [rfReplaceAll]);

  // Normalize path: replace backslashes with forward slashes
  LFilename := StringReplace(ATest.Filename, '\', '/', [rfReplaceAll]);

  EmitLnFmt(sfSource, 'static bool _myra_test_reg_%d = UnitTest::RegisterTest("%s", &_myra_test_%d, "%s", %d);',
    [AIndex, LEscapedDesc, AIndex, LFilename, ATest.Line]);
end;

procedure TCodeGen.EmitTry(const ANode: TTryNode);
begin
  EmitLine(sfSource, ANode);

  // If we have both except and finally, we need nested try blocks
  // try { try { ... } catch(...) { except } } finally cleanup
  if (ANode.ExceptBlock <> nil) and (ANode.FinallyBlock <> nil) then
  begin
    // Outer try for finally
    EmitLn(sfSource, 'try {');
    IncIndent(sfSource);

    // Inner try for except
    EmitLn(sfSource, 'try {');
    IncIndent(sfSource);
    EmitBlock(ANode.TryBlock);
    DecIndent(sfSource);
    EmitLn(sfSource, '} catch (const std::exception& _e) {');
    IncIndent(sfSource);
    EmitLn(sfSource, RuntimeNS() + 'SetLastException(_e.what());');
    EmitBlock(ANode.ExceptBlock);
    DecIndent(sfSource);
    EmitLn(sfSource, '} catch (...) {');
    IncIndent(sfSource);
    EmitLn(sfSource, RuntimeNS() + 'SetLastException("Unknown exception");');
    EmitBlock(ANode.ExceptBlock);
    DecIndent(sfSource);
    EmitLn(sfSource, '}');

    DecIndent(sfSource);
    EmitLn(sfSource, '} catch (...) {');
    IncIndent(sfSource);
    EmitBlock(ANode.FinallyBlock);
    EmitLn(sfSource, 'throw;');
    DecIndent(sfSource);
    EmitLn(sfSource, '}');

    // Finally block runs on normal exit too
    EmitBlock(ANode.FinallyBlock);
  end
  else if ANode.ExceptBlock <> nil then
  begin
    // Just try/except - catch std::exception first, then ...
    EmitLn(sfSource, 'try {');
    IncIndent(sfSource);
    EmitBlock(ANode.TryBlock);
    DecIndent(sfSource);
    EmitLn(sfSource, '} catch (const std::exception& _e) {');
    IncIndent(sfSource);
    EmitLn(sfSource, RuntimeNS() + 'SetLastException(_e.what());');
    EmitBlock(ANode.ExceptBlock);
    DecIndent(sfSource);
    EmitLn(sfSource, '} catch (...) {');
    IncIndent(sfSource);
    EmitLn(sfSource, RuntimeNS() + 'SetLastException("Unknown exception");');
    EmitBlock(ANode.ExceptBlock);
    DecIndent(sfSource);
    EmitLn(sfSource, '}');
  end
  else if ANode.FinallyBlock <> nil then
  begin
    // Just try/finally
    EmitLn(sfSource, 'try {');
    IncIndent(sfSource);
    EmitBlock(ANode.TryBlock);
    DecIndent(sfSource);
    EmitLn(sfSource, '} catch (...) {');
    IncIndent(sfSource);
    EmitBlock(ANode.FinallyBlock);
    EmitLn(sfSource, 'throw;');
    DecIndent(sfSource);
    EmitLn(sfSource, '}');
    EmitBlock(ANode.FinallyBlock);
  end
  else
  begin
    // Just try block with no handlers (unusual but valid)
    EmitBlock(ANode.TryBlock);
  end;
end;

procedure TCodeGen.EmitInherited(const ANode: TInheritedCallNode);
var
  LCall: string;
  LMethodName: string;
  I: Integer;
begin
  EmitLine(sfSource, ANode);

  // Get method name (defaults to current method if not specified)
  if ANode.MethodName <> '' then
    LMethodName := ANode.MethodName
  else
    LMethodName := '';

  // Emit call to parent method: MethodName(Self, args)
  // ResolvedParentType was set by semantic analyzer
  // Cast Self to parent type to ensure correct C++ overload resolution
  if ANode.ResolvedParentType <> '' then
    LCall := LMethodName + '(static_cast<' + ANode.ResolvedParentType + '&>(Self)'
  else
    LCall := LMethodName + '(Self';
  
  for I := 0 to ANode.Args.Count - 1 do
  begin
    LCall := LCall + ', ';
    LCall := LCall + EmitExpression(ANode.Args[I]);
  end;
  
  LCall := LCall + ');';
  EmitLn(sfSource, LCall);
end;

function TCodeGen.RuntimeNS(): string;
begin
  Result := 'Myra::';
end;

procedure TCodeGen.EmitCppBlock(const ANode: TCppBlockNode);
var
  LTarget: TSourceFile;
begin
  // Determine target based on node's Target field
  if ANode.Target = ctHeader then
    LTarget := sfHeader
  else
    LTarget := sfSource;

  EmitLine(LTarget, ANode);
  Emit(LTarget, ANode.RawText);
  EmitLn(LTarget);
end;

function TCodeGen.EmitExpression(const AExpr: TASTNode): string;
begin
  Result := '';

  if AExpr = nil then
    Exit;

  if AExpr is TBinaryOpNode then
    Result := EmitBinaryOp(TBinaryOpNode(AExpr))
  else if AExpr is TUnaryOpNode then
    Result := EmitUnaryOp(TUnaryOpNode(AExpr))
  else if AExpr is TIdentifierNode then
    Result := EmitIdentifier(TIdentifierNode(AExpr))
  else if AExpr is TFieldAccessNode then
    Result := EmitFieldAccess(TFieldAccessNode(AExpr))
  else if AExpr is TIndexAccessNode then
    Result := EmitIndexAccess(TIndexAccessNode(AExpr))
  else if AExpr is TDerefNode then
    Result := EmitDeref(TDerefNode(AExpr))
  else if AExpr is TLenNode then
    Result := EmitExpression(TLenNode(AExpr).Target) + '.size()'
  else if AExpr is TParamCountNode then
    Result := 'Myra::ParamCount()'
  else if AExpr is TParamStrNode then
    Result := 'Myra::ParamStr(' + EmitExpression(TParamStrNode(AExpr).Index) + ')'
  else if AExpr is TTypeCastNode then
    Result := EmitTypeCast(TTypeCastNode(AExpr))
  else if AExpr is TTypeTestNode then
    Result := EmitTypeTest(TTypeTestNode(AExpr))
  else if AExpr is TCallNode then
  begin
    with TCallNode(AExpr) do
    begin
      // Handle method calls
      if IsMethodCall and (Receiver <> nil) then
      begin
        var LRecv := EmitExpression(Receiver);
        
        if IsCppPassthrough then
        begin
          // C++ member call: receiver.method(args)
          Result := LRecv + '.' + RoutineName + '(';
          for var J := 0 to Args.Count - 1 do
          begin
            if J > 0 then
              Result := Result + ', ';
            Result := Result + EmitExpression(Args[J]);
          end;
          Result := Result + ')';
        end
        else
        begin
          // Myra method call: method(receiver, args)
          Result := RoutineName + '(' + LRecv;
          for var J := 0 to Args.Count - 1 do
          begin
            Result := Result + ', ';
            Result := Result + EmitExpression(Args[J]);
          end;
          Result := Result + ')';
        end;
      end
      else
      begin
        // Regular call
        if Qualifier <> '' then
          Result := Qualifier + '::' + RoutineName
        else
          Result := RoutineName;

        Result := Result + '(';
        for var J := 0 to Args.Count - 1 do
        begin
          if J > 0 then
            Result := Result + ', ';
          Result := Result + EmitExpression(Args[J]);
        end;
        Result := Result + ')';
      end;
    end;
  end
  else if AExpr is TIntegerLitNode then
    Result := IntToStr(TIntegerLitNode(AExpr).Value)
  else if AExpr is TFloatLitNode then
    Result := FloatToStr(TFloatLitNode(AExpr).Value)
  else if AExpr is TStringLitNode then
  begin
    // Check resolved type - emit as char if target expects CHAR
    if (AExpr.ResolvedType <> nil) and SameText(TSymbol(AExpr.ResolvedType).SymbolName, 'CHAR') then
      Result := '''' + EscapeForCpp(TStringLitNode(AExpr).Value) + ''''
    else
      Result := '"' + EscapeForCpp(TStringLitNode(AExpr).Value) + '"';
  end
  else if AExpr is TCharLitNode then
  begin
    // Check resolved type - emit as string if target expects STRING
    if (AExpr.ResolvedType <> nil) and SameText(TSymbol(AExpr.ResolvedType).SymbolName, 'STRING') then
      Result := '"' + EscapeForCpp(TCharLitNode(AExpr).Value) + '"'
    else
      Result := '''' + EscapeForCpp(TCharLitNode(AExpr).Value) + '''';
  end
  else if AExpr is TWideStringLitNode then
    Result := 'L"' + EscapeForCpp(TWideStringLitNode(AExpr).Value) + '"'
  else if AExpr is TWideCharLitNode then
    Result := 'L''' + EscapeForCpp(TWideCharLitNode(AExpr).Value) + ''''
  else if AExpr is TBoolLitNode then
  begin
    if TBoolLitNode(AExpr).Value then
      Result := 'true'
    else
      Result := 'false';
  end
  else if AExpr is TNilLitNode then
    Result := 'nullptr'
  else if AExpr is TSetLitNode then
    Result := EmitSetLiteral(TSetLitNode(AExpr))
  else if AExpr is TCppPassthroughNode then
    Result := TCppPassthroughNode(AExpr).RawText
  else if AExpr is TRangeNode then
    Result := '/* range */'; // Handled in set literal
end;

function TCodeGen.EmitBinaryOp(const ANode: TBinaryOpNode): string;
var
  LLeft: string;
  LRight: string;
  LOp: string;
  LLeftType: TTypeSymbol;
  LRightType: TTypeSymbol;
  LIsSetOp: Boolean;

  function IsSetType(const AType: TTypeSymbol): Boolean;
  begin
    Result := (AType <> nil) and
              (SameText(AType.SymbolName, 'SET') or (AType.Node is TSetTypeNode));
  end;

begin
  LLeft := EmitExpression(ANode.Left);
  LRight := EmitExpression(ANode.Right);

  // Get resolved types from semantic analysis
  LLeftType := TTypeSymbol(ANode.Left.ResolvedType);
  LRightType := TTypeSymbol(ANode.Right.ResolvedType);

  // Check if this is a set operation
  LIsSetOp := IsSetType(LLeftType) or IsSetType(LRightType);

  // Handle IN operator specially for set membership
  if ANode.Op = tkIn then
  begin
    // x IN set -> ((set & (1ULL << x)) != 0)
    Result := Format('((%s & (1ULL << %s)) != 0)', [LRight, LLeft]);
    Exit;
  end;

  // Handle set operations
  if LIsSetOp then
  begin
    case ANode.Op of
      tkPlus:  LOp := '|';  // union
      tkMinus: begin
        // difference: A - B -> A & ~B
        Result := Format('(%s & ~%s)', [LLeft, LRight]);
        Exit;
      end;
      tkStar:  LOp := '&';  // intersection
    else
      LOp := OpToCpp(ANode.Op);
    end;
  end
  else
    LOp := OpToCpp(ANode.Op);

  Result := Format('(%s %s %s)', [LLeft, LOp, LRight]);
end;

function TCodeGen.EmitUnaryOp(const ANode: TUnaryOpNode): string;
var
  LOperand: string;
  LOp: string;
begin
  LOperand := EmitExpression(ANode.Operand);
  LOp := OpToCpp(ANode.Op);

  Result := Format('(%s%s)', [LOp, LOperand]);
end;

function TCodeGen.EmitIdentifier(const ANode: TIdentifierNode): string;
begin
  if ANode.Qualifier <> '' then
    Result := ANode.Qualifier + '::' + ANode.IdentName
  else
    Result := ANode.IdentName;
end;

function TCodeGen.EmitFieldAccess(const ANode: TFieldAccessNode): string;
var
  LTarget: string;
  LTargetIdent: TIdentifierNode;
begin
  // Check if target is a module identifier (namespace qualification)
  if ANode.Target is TIdentifierNode then
  begin
    LTargetIdent := TIdentifierNode(ANode.Target);
    // Check if it's an imported module (has a module scope in symbol table)
    if FSymbols.HasModule(LTargetIdent.IdentName) then
    begin
      // Module qualification: Module::Symbol
      Result := LTargetIdent.IdentName + '::' + ANode.FieldName;
      Exit;
    end;
  end;

  LTarget := EmitExpression(ANode.Target);

  // Use -> for pointers, . for values
  // For now, assume . (would need type info for proper handling)
  Result := LTarget + '.' + ANode.FieldName;
end;

function TCodeGen.EmitIndexAccess(const ANode: TIndexAccessNode): string;
var
  LTarget: string;
  LIndex: string;
begin
  LTarget := EmitExpression(ANode.Target);
  LIndex := EmitExpression(ANode.Index);

  // Adjust index for non-zero lower bound (set by semantic analyzer)
  if ANode.LowBound <> 0 then
    Result := LTarget + '[' + LIndex + ' - ' + IntToStr(ANode.LowBound) + ']'
  else
    Result := LTarget + '[' + LIndex + ']';
end;

function TCodeGen.EmitDeref(const ANode: TDerefNode): string;
var
  LTarget: string;
begin
  LTarget := EmitExpression(ANode.Target);
  Result := '(*' + LTarget + ')';
end;

function TCodeGen.EmitTypeCast(const ANode: TTypeCastNode): string;
var
  LExpr: string;
  LType: string;
  LUpper: string;
  LExprType: TTypeSymbol;
  LExprTypeName: string;
  LVarSymbol: TSymbol;
  LVarNode: TVarDeclNode;
begin
  LExpr := EmitExpression(ANode.Expr);
  LType := TypeToCpp(ANode.TypeName);
  LUpper := UpperCase(ANode.TypeName);

  // Special handling for String() casts - use std::to_string for numeric types
  if LUpper = 'STRING' then
  begin
    // Check the source expression's type
    LExprType := TTypeSymbol(ANode.Expr.ResolvedType);
    if LExprType <> nil then
      LExprTypeName := UpperCase(LExprType.SymbolName)
    else
      LExprTypeName := '';

    // If resolved type not available, try to look up variable type
    if (LExprTypeName = '') and (ANode.Expr is TIdentifierNode) then
    begin
      LVarSymbol := FSymbols.Lookup(TIdentifierNode(ANode.Expr).IdentName);
      if (LVarSymbol <> nil) and (LVarSymbol.Node is TVarDeclNode) then
      begin
        LVarNode := TVarDeclNode(LVarSymbol.Node);
        LExprTypeName := UpperCase(LVarNode.TypeName);
      end;
    end;

    // Use std::to_string for numeric types
    if (LExprTypeName = 'INTEGER') or (LExprTypeName = 'UINTEGER') or
       (LExprTypeName = 'FLOAT') or (LExprTypeName = 'DOUBLE') or
       (LExprTypeName = 'REAL') or (LExprTypeName = 'BOOLEAN') then
    begin
      Result := Format('std::to_string(%s)', [LExpr]);
      Exit;
    end;

    // For char* / pointer types, use std::string constructor
    if (Pos('POINTER', LExprTypeName) > 0) then
    begin
      Result := Format('std::string(reinterpret_cast<const char*>(%s))', [LExpr]);
      Exit;
    end;

    // Direct char* variable - wrap with std::string
    if (LExprTypeName = 'CHAR') then
    begin
      Result := Format('std::string(%s)', [LExpr]);
      Exit;
    end;
  end;

  Result := Format('static_cast<%s>(%s)', [LType, LExpr]);
end;

function TCodeGen.EmitTypeTest(const ANode: TTypeTestNode): string;
var
  LExpr: string;
begin
  LExpr := EmitExpression(ANode.Expr);
  Result := Format('(dynamic_cast<%s*>(%s) != nullptr)', [ANode.TypeName, LExpr]);
end;

function TCodeGen.EmitSetLiteral(const ANode: TSetLitNode): string;
var
  LElement: TASTNode;
  LRange: TRangeNode;
  LLow: string;
  LHigh: string;
  LLowVal: Int64;
  LHighVal: Int64;
  LRangeWidth: Int64;
  I: Integer;
begin
  // Empty set -> 0
  if ANode.Elements.Count = 0 then
  begin
    Result := '0ULL';
    Exit;
  end;

  // Sets as uint64_t bitmask
  Result := '(uint64_t)(';

  for I := 0 to ANode.Elements.Count - 1 do
  begin
    LElement := ANode.Elements[I];

    if I > 0 then
      Result := Result + ' | ';

    if LElement is TRangeNode then
    begin
      LRange := TRangeNode(LElement);
      LLow := EmitExpression(LRange.LowExpr);
      LHigh := EmitExpression(LRange.HighExpr);
      
      // Check if both bounds are integer literals so we can compute range width
      if (LRange.LowExpr is TIntegerLitNode) and (LRange.HighExpr is TIntegerLitNode) then
      begin
        LLowVal := TIntegerLitNode(LRange.LowExpr).Value;
        LHighVal := TIntegerLitNode(LRange.HighExpr).Value;
        LRangeWidth := LHighVal - LLowVal + 1;
        
        // Handle 64-bit range specially to avoid 1ULL << 64 (undefined behavior)
        if LRangeWidth >= 64 then
        begin
          if LLowVal = 0 then
            Result := Result + '~0ULL'  // All 64 bits set
          else
            Result := Result + Format('(~0ULL << %s)', [LLow]);
        end
        else
          Result := Result + Format('(((1ULL << %d) - 1) << %s)', [LRangeWidth, LLow]);
      end
      else
        // Non-literal bounds - use runtime formula (may fail for 64-bit ranges)
        Result := Result + Format('(((1ULL << (%s - %s + 1)) - 1) << %s)', [LHigh, LLow, LLow]);
    end
    else
      Result := Result + Format('(1ULL << %s)', [EmitExpression(LElement)]);
  end;

  Result := Result + ')';
end;

function TCodeGen.EmitArrayLiteral(const ANode: TSetLitNode): string;
var
  I: Integer;
begin
  // Emit as C++ initializer list: {elem1, elem2, ...}
  Result := '{';
  for I := 0 to ANode.Elements.Count - 1 do
  begin
    if I > 0 then
      Result := Result + ', ';
    Result := Result + EmitExpression(ANode.Elements[I]);
  end;
  Result := Result + '}';
end;

function TCodeGen.IsArrayType(const ATypeName: string): Boolean;
var
  LTypeSymbol: TTypeSymbol;
begin
  // Check if type name starts with ARRAY (inline array type)
  if Pos('ARRAY', UpperCase(ATypeName)) = 1 then
  begin
    Result := True;
    Exit;
  end;

  // Check if it's a named type that is an array
  LTypeSymbol := FSymbols.LookupType(ATypeName);
  if (LTypeSymbol <> nil) and (LTypeSymbol.Node is TArrayTypeNode) then
  begin
    Result := True;
    Exit;
  end;

  Result := False;
end;

function TCodeGen.TypeToCpp(const ATypeName: string): string;
var
  LUpper: string;
  LPos: Integer;
  LElementType: string;
  LLow: Integer;
  LHigh: Integer;
  LBoundsStr: string;
begin
  LUpper := UpperCase(ATypeName);

  if LUpper = 'BOOLEAN' then
    Result := 'bool'
  else if LUpper = 'CHAR' then
    Result := 'char'
  else if LUpper = 'UCHAR' then
    Result := 'uint8_t'
  else if LUpper = 'INTEGER' then
    Result := 'int64_t'
  else if LUpper = 'UINTEGER' then
    Result := 'uint64_t'
  else if LUpper = 'FLOAT' then
    Result := 'double'
  else if LUpper = 'DOUBLE' then
    Result := 'double'
  else if LUpper = 'REAL' then
    Result := 'double'
  else if LUpper = 'STRING' then
    Result := 'std::string'
  else if LUpper = 'SET' then
    Result := 'uint64_t'
  else if LUpper = 'POINTER' then
    Result := 'void*'
  else if Pos('SET OF ', LUpper) = 1 then
    // SET OF 0..31 -> uint64_t
    Result := 'uint64_t'
  else if Pos('POINTER TO ', LUpper) = 1 then
    Result := TypeToCpp(Copy(ATypeName, 12, Length(ATypeName))) + '*'
  else if Pos('ARRAY', LUpper) = 1 then
  begin
    // Parse ARRAY[low..high] OF ElementType or ARRAY[] OF ElementType
    LPos := Pos(' OF ', LUpper);
    if LPos > 0 then
    begin
      LElementType := Trim(Copy(ATypeName, LPos + 4, Length(ATypeName)));
      LBoundsStr := Copy(ATypeName, 6, LPos - 6); // Extract [low..high] or []
      LBoundsStr := Trim(LBoundsStr);

      if (Length(LBoundsStr) >= 2) and (LBoundsStr[1] = '[') and (LBoundsStr[Length(LBoundsStr)] = ']') then
      begin
        LBoundsStr := Copy(LBoundsStr, 2, Length(LBoundsStr) - 2); // Remove brackets
        LPos := Pos('..', LBoundsStr);
        if LPos > 0 then
        begin
          // Static array: ARRAY[0..9] OF INTEGER -> int64_t[10]
          LLow := StrToIntDef(Trim(Copy(LBoundsStr, 1, LPos - 1)), 0);
          LHigh := StrToIntDef(Trim(Copy(LBoundsStr, LPos + 2, Length(LBoundsStr))), 0);
          Result := Format('%s[%d]', [TypeToCpp(LElementType), LHigh - LLow + 1]);
        end
        else if LBoundsStr = '' then
          // Dynamic array: ARRAY[] OF INTEGER -> std::vector<int64_t>
          Result := Format('std::vector<%s>', [TypeToCpp(LElementType)])
        else
          Result := 'auto';
      end
      else
        // ARRAY OF INTEGER (no brackets) -> std::vector<int64_t>
        Result := Format('std::vector<%s>', [TypeToCpp(LElementType)]);
    end
    else
      Result := 'auto';
  end
  else
  begin
    // Convert Myra dot notation to C++ scope operator for qualified types
    if Pos('.', ATypeName) > 0 then
      Result := StringReplace(ATypeName, '.', '::', [rfReplaceAll])
    else
      Result := ATypeName;
  end;
end;

function TCodeGen.OpToCpp(const AOp: TTokenKind): string;
begin
  case AOp of
    tkPlus:      Result := '+';
    tkMinus:     Result := '-';
    tkStar:      Result := '*';
    tkSlash:     Result := '/';
    tkDiv:       Result := '/';
    tkMod:       Result := '%';
    tkEquals:    Result := '==';
    tkNotEquals: Result := '!=';
    tkLess:      Result := '<';
    tkGreater:   Result := '>';
    tkLessEq:    Result := '<=';
    tkGreaterEq: Result := '>=';
    tkAnd:       Result := '&&';
    tkOr:        Result := '||';
    tkNot:       Result := '!';
    tkIn:        Result := '&'; // Bitwise AND for set membership
  else
    Result := '?';
  end;
end;

function TCodeGen.EscapeForCpp(const AValue: string): string;
var
  I: Integer;
  LChar: Char;
  LNextChar: Char;
begin
  // Escape special characters for C++ string output.
  // Handles: double quotes, backslashes (with exceptions for hex/octal escapes)
  Result := '';
  I := 1;
  while I <= Length(AValue) do
  begin
    LChar := AValue[I];
    if LChar = '"' then
    begin
      // Escape double quotes for C++ string literals
      Result := Result + '\"';
    end
    else if LChar = '\' then
    begin
      if I < Length(AValue) then
      begin
        LNextChar := AValue[I + 1];
        // Only pass through hex (\x) and octal (\0-\7) escapes
        if CharInSet(LNextChar, ['x', '0'..'7']) then
        begin
          // Valid intentional escape - pass through unchanged
          Result := Result + LChar;
        end
        else
        begin
          // Escape the backslash to prevent C++ interpretation
          Result := Result + '\\';
        end;
      end
      else
      begin
        // Backslash at end of string - must escape
        Result := Result + '\\';
      end;
    end
    else
      Result := Result + LChar;
    Inc(I);
  end;
end;

procedure TCodeGen.EmitVarWithType(const ATarget: TSourceFile; const APrefix: string; const AVarName: string; const ATypeName: string; const ASuffix: string);
var
  LCppType: string;
  LPos: Integer;
  LBaseType: string;
  LArraySize: string;
begin
  LCppType := TypeToCpp(ATypeName);

  // Handle C-style array syntax: type[size] -> prefix type varname[size] suffix
  LPos := Pos('[', LCppType);
  if LPos > 0 then
  begin
    LBaseType := Copy(LCppType, 1, LPos - 1);
    LArraySize := Copy(LCppType, LPos, Length(LCppType));
    EmitLnFmt(ATarget, '%s%s %s%s%s', [APrefix, LBaseType, AVarName, LArraySize, ASuffix]);
  end
  else
    EmitLnFmt(ATarget, '%s%s %s%s', [APrefix, LCppType, AVarName, ASuffix]);
end;

function TCodeGen.GetHeader(): string;
begin
  Result := FOutput[sfHeader].ToString();
end;

function TCodeGen.GetSource(): string;
begin
  Result := FOutput[sfSource].ToString();
end;

procedure TCodeGen.SaveFiles(const AOutputPath: string);
var
  LHeaderPath: string;
  LSourcePath: string;
begin
  LHeaderPath := IncludeTrailingPathDelimiter(AOutputPath) + FModuleName + '.h';
  LSourcePath := IncludeTrailingPathDelimiter(AOutputPath) + FModuleName + '.cpp';

  TFile.WriteAllText(LHeaderPath, GetHeader(), TEncoding.UTF8);
  TFile.WriteAllText(LSourcePath, GetSource(), TEncoding.UTF8);
end;

end.
