{===============================================================================
  Myra™ - Pascal. Refined.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit Myra.AST;

{$I Myra.Defines.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Myra.Utils,
  Myra.Token;

type
  TASTNode = class;
  TBlockNode = class;
  TTypeNode = class;
  TTestNode = class;

  { TModuleKind }
  TModuleKind = (
    mkExecutable,
    mkLibrary,
    mkDll
  );

  { TCallingConvention }
  TCallingConvention = (
    ccDefault,
    ccCdecl,
    ccStdcall,
    ccFastcall
  );

  { TCppTarget }
  TCppTarget = (
    ctSource,   // emit to .cpp (default)
    ctHeader    // emit to .h
  );

  { TImportInfo }
  TImportInfo = record
    Name: string;
    Line: Integer;
    Column: Integer;
  end;

  { TASTNode }
  TASTNode = class(TBaseObject)
  public
    Filename: string;
    Line: Integer;
    Column: Integer;
    EndLine: Integer;
    ResolvedType: TObject;  // TTypeSymbol, set by semantic analyzer
  end;

  { TModuleNode }
  TModuleNode = class(TASTNode)
  public
    ModuleName: string;
    ModuleKind: TModuleKind;
    Imports: TList<TImportInfo>;
    Consts: TObjectList<TASTNode>;
    Types: TObjectList<TASTNode>;
    Vars: TObjectList<TASTNode>;
    Routines: TObjectList<TASTNode>;
    CppBlocks: TObjectList<TASTNode>;
    Directives: TObjectList<TASTNode>;
    Tests: TObjectList<TTestNode>;
    Body: TBlockNode;

    constructor Create(); override;
    destructor Destroy(); override;
  end;

  { TDirectiveNode }
  TDirectiveNode = class(TASTNode)
  public
    DirectiveName: string;
    Value: string;
  end;

  { TTypeNode }
  TTypeNode = class(TASTNode)
  public
    TypeName: string;
    TypeNameLine: Integer;
    TypeNameColumn: Integer;
    AliasedType: string;
    AliasedTypeLine: Integer;
    AliasedTypeColumn: Integer;
    IsPublic: Boolean;
  end;

  { TRecordNode }
  TRecordNode = class(TTypeNode)
  public
    ParentType: string;
    ParentTypeLine: Integer;
    ParentTypeColumn: Integer;
    Fields: TObjectList<TASTNode>;

    constructor Create(); override;
    destructor Destroy(); override;
  end;

  { TPointerTypeNode }
  TPointerTypeNode = class(TTypeNode)
  public
    BaseType: string;
    BaseTypeLine: Integer;
    BaseTypeColumn: Integer;
  end;

  { TArrayTypeNode }
  TArrayTypeNode = class(TTypeNode)
  public
    ElementType: string;
    ElementTypeLine: Integer;
    ElementTypeColumn: Integer;
    LowBound: Integer;
    HighBound: Integer;
    IsDynamic: Boolean;
  end;

  { TSetTypeNode }
  TSetTypeNode = class(TTypeNode)
  public
    ElementType: string;
    ElementTypeLine: Integer;
    ElementTypeColumn: Integer;
    LowBound: Integer;
    HighBound: Integer;
  end;

  { TVarDeclNode }
  TVarDeclNode = class(TASTNode)
  public
    VarName: string;
    TypeName: string;
    TypeNameLine: Integer;
    TypeNameColumn: Integer;
    InitValue: TASTNode;
    IsPublic: Boolean;

    destructor Destroy(); override;
  end;

  { TConstNode }
  TConstNode = class(TASTNode)
  public
    ConstName: string;
    TypeName: string;
    TypeNameLine: Integer;
    TypeNameColumn: Integer;
    Value: TASTNode;
    IsPublic: Boolean;

    destructor Destroy(); override;
  end;

  { TFieldNode }
  TFieldNode = class(TASTNode)
  public
    FieldName: string;
    TypeName: string;
    TypeNameLine: Integer;
    TypeNameColumn: Integer;
  end;

  { TParamNode }
  TParamNode = class(TASTNode)
  public
    ParamName: string;
    TypeName: string;
    TypeNameLine: Integer;
    TypeNameColumn: Integer;
    IsVar: Boolean;
    IsConst: Boolean;
  end;

  { TRoutineTypeNode }
  TRoutineTypeNode = class(TTypeNode)
  public
    Params: TObjectList<TParamNode>;
    ReturnType: string;
    ReturnTypeLine: Integer;
    ReturnTypeColumn: Integer;
    CallingConv: TCallingConvention;

    constructor Create(); override;
    destructor Destroy(); override;
  end;

  { TRoutineNode }
  TRoutineNode = class(TASTNode)
  public
    RoutineName: string;
    RoutineNameLine: Integer;
    RoutineNameColumn: Integer;
    Params: TObjectList<TParamNode>;
    ReturnType: string;
    ReturnTypeLine: Integer;
    ReturnTypeColumn: Integer;
    LocalVars: TObjectList<TVarDeclNode>;
    Body: TBlockNode;
    IsPublic: Boolean;
    IsMethod: Boolean;
    IsVariadic: Boolean;
    IsCExport: Boolean;
    IsExternal: Boolean;
    ExternalLib: string;
    ExternalLibIsIdent: Boolean;
    CallingConv: TCallingConvention;
    BoundToType: string;
    BoundToTypeLine: Integer;
    BoundToTypeColumn: Integer;

    constructor Create(); override;
    destructor Destroy(); override;
  end;

  { TBlockNode }
  TBlockNode = class(TASTNode)
  public
    Statements: TObjectList<TASTNode>;

    constructor Create(); override;
    destructor Destroy(); override;
  end;

  { TIfNode }
  TIfNode = class(TASTNode)
  public
    Condition: TASTNode;
    ThenBlock: TBlockNode;
    ElseBlock: TBlockNode;

    destructor Destroy(); override;
  end;

  { TWhileNode }
  TWhileNode = class(TASTNode)
  public
    Condition: TASTNode;
    Body: TBlockNode;

    destructor Destroy(); override;
  end;

  { TForNode }
  TForNode = class(TASTNode)
  public
    VarName: string;
    VarLine: Integer;
    VarColumn: Integer;
    StartExpr: TASTNode;
    EndExpr: TASTNode;
    IsDownTo: Boolean;
    Body: TBlockNode;

    destructor Destroy(); override;
  end;

  { TRepeatNode }
  TRepeatNode = class(TASTNode)
  public
    Body: TBlockNode;
    Condition: TASTNode;

    destructor Destroy(); override;
  end;

  { TCaseBranch }
  TCaseBranch = class(TASTNode)
  public
    Values: TObjectList<TASTNode>;
    Body: TBlockNode;

    constructor Create(); override;
    destructor Destroy(); override;
  end;

  { TCaseNode }
  TCaseNode = class(TASTNode)
  public
    Expr: TASTNode;
    Branches: TObjectList<TCaseBranch>;
    ElseBlock: TBlockNode;

    constructor Create(); override;
    destructor Destroy(); override;
  end;

  { TReturnNode }
  TReturnNode = class(TASTNode)
  public
    Value: TASTNode;

    destructor Destroy(); override;
  end;

  { TAssignNode }
  TAssignNode = class(TASTNode)
  public
    Target: TASTNode;
    Value: TASTNode;

    destructor Destroy(); override;
  end;

  { TCallNode }
  TCallNode = class(TASTNode)
  public
    RoutineName: string;
    RoutineNameLine: Integer;
    RoutineNameColumn: Integer;
    Qualifier: string;
    Args: TObjectList<TASTNode>;
    // Method call support
    IsMethodCall: Boolean;
    Receiver: TASTNode;         // The instance (LDog in LDog.Speak())
    IsCppPassthrough: Boolean;  // True if unknown type/method - emit as C++

    constructor Create(); override;
    destructor Destroy(); override;
  end;

  { TInheritedCallNode }
  TInheritedCallNode = class(TASTNode)
  public
    MethodName: string;
    MethodNameLine: Integer;
    MethodNameColumn: Integer;
    Args: TObjectList<TASTNode>;
    ResolvedParentType: string; // Resolved by semantic analyzer

    constructor Create(); override;
    destructor Destroy(); override;
  end;

  { TBinaryOpNode }
  TBinaryOpNode = class(TASTNode)
  public
    Left: TASTNode;
    Op: TTokenKind;
    Right: TASTNode;

    destructor Destroy(); override;
  end;

  { TUnaryOpNode }
  TUnaryOpNode = class(TASTNode)
  public
    Op: TTokenKind;
    Operand: TASTNode;

    destructor Destroy(); override;
  end;

  { TIdentifierNode }
  TIdentifierNode = class(TASTNode)
  public
    IdentName: string;
    Qualifier: string;
  end;

  { TIntegerLitNode }
  TIntegerLitNode = class(TASTNode)
  public
    Value: Int64;
  end;

  { TFloatLitNode }
  TFloatLitNode = class(TASTNode)
  public
    Value: Double;
  end;

  { TStringLitNode }
  TStringLitNode = class(TASTNode)
  public
    Value: string;
  end;

  { TCharLitNode }
  TCharLitNode = class(TASTNode)
  public
    Value: Char;
  end;

  { TWideStringLitNode }
  TWideStringLitNode = class(TASTNode)
  public
    Value: string;
  end;

  { TWideCharLitNode }
  TWideCharLitNode = class(TASTNode)
  public
    Value: Char;
  end;

  { TBoolLitNode }
  TBoolLitNode = class(TASTNode)
  public
    Value: Boolean;
  end;

  { TNilLitNode }
  TNilLitNode = class(TASTNode)
  end;

  { TFieldAccessNode }
  TFieldAccessNode = class(TASTNode)
  public
    Target: TASTNode;
    FieldName: string;
    FieldNameLine: Integer;
    FieldNameColumn: Integer;

    destructor Destroy(); override;
  end;

  { TIndexAccessNode }
  TIndexAccessNode = class(TASTNode)
  public
    Target: TASTNode;
    Index: TASTNode;
    LowBound: Integer;  // For non-zero based arrays (set by semantic analyzer)

    destructor Destroy(); override;
  end;

  { TDerefNode }
  TDerefNode = class(TASTNode)
  public
    Target: TASTNode;

    destructor Destroy(); override;
  end;

  { TTypeTestNode }
  TTypeTestNode = class(TASTNode)
  public
    Expr: TASTNode;
    TypeName: string;
    TypeNameLine: Integer;
    TypeNameColumn: Integer;

    destructor Destroy(); override;
  end;

  { TTypeCastNode }
  TTypeCastNode = class(TASTNode)
  public
    Expr: TASTNode;
    TypeName: string;
    TypeNameLine: Integer;
    TypeNameColumn: Integer;

    destructor Destroy(); override;
  end;

  { TSetLitNode }
  TSetLitNode = class(TASTNode)
  public
    Elements: TObjectList<TASTNode>;

    constructor Create(); override;
    destructor Destroy(); override;
  end;

  { TRangeNode }
  TRangeNode = class(TASTNode)
  public
    LowExpr: TASTNode;
    HighExpr: TASTNode;

    destructor Destroy(); override;
  end;

  { TCppBlockNode }
  TCppBlockNode = class(TASTNode)
  public
    RawText: string;
    Target: TCppTarget;
  end;

  { TCppPassthroughNode }
  TCppPassthroughNode = class(TASTNode)
  public
    RawText: string;
  end;

  { TNewNode }
  TNewNode = class(TASTNode)
  public
    Target: TASTNode;
    AsType: string;
    AsTypeLine: Integer;
    AsTypeColumn: Integer;

    destructor Destroy(); override;
  end;

  { TDisposeNode }
  TDisposeNode = class(TASTNode)
  public
    Target: TASTNode;

    destructor Destroy(); override;
  end;

  { TSetLengthNode }
  TSetLengthNode = class(TASTNode)
  public
    Target: TASTNode;   // The array variable
    NewSize: TASTNode;  // The new length expression

    destructor Destroy(); override;
  end;

  { TLenNode }
  TLenNode = class(TASTNode)
  public
    Target: TASTNode;   // The array to get length of

    destructor Destroy(); override;
  end;

  { TParamCountNode }
  TParamCountNode = class(TASTNode)
  end;

  { TParamStrNode }
  TParamStrNode = class(TASTNode)
  public
    Index: TASTNode;

    destructor Destroy(); override;
  end;

  { TTestNode }
  TTestNode = class(TASTNode)
  public
    Description: string;
    LocalVars: TObjectList<TVarDeclNode>;
    LocalConsts: TObjectList<TASTNode>;
    LocalTypes: TObjectList<TASTNode>;
    Body: TBlockNode;

    constructor Create(); override;
    destructor Destroy(); override;
  end;

  { TTryNode }
  TTryNode = class(TASTNode)
  public
    TryBlock: TBlockNode;
    ExceptBlock: TBlockNode;
    FinallyBlock: TBlockNode;

    destructor Destroy(); override;
  end;

implementation

{ TModuleNode }

constructor TModuleNode.Create();
begin
  inherited Create();

  Imports := TList<TImportInfo>.Create();
  Consts := TObjectList<TASTNode>.Create();
  Types := TObjectList<TASTNode>.Create();
  Vars := TObjectList<TASTNode>.Create();
  Routines := TObjectList<TASTNode>.Create();
  CppBlocks := TObjectList<TASTNode>.Create();
  Directives := TObjectList<TASTNode>.Create();
  Tests := TObjectList<TTestNode>.Create();
end;

destructor TModuleNode.Destroy();
begin
  Body.Free();
  Tests.Free();
  Directives.Free();
  CppBlocks.Free();
  Routines.Free();
  Vars.Free();
  Types.Free();
  Consts.Free();
  Imports.Free();

  inherited Destroy();
end;

{ TRecordNode }

constructor TRecordNode.Create();
begin
  inherited Create();

  Fields := TObjectList<TASTNode>.Create();
end;

destructor TRecordNode.Destroy();
begin
  Fields.Free();

  inherited Destroy();
end;

{ TRoutineTypeNode }

constructor TRoutineTypeNode.Create();
begin
  inherited Create();

  Params := TObjectList<TParamNode>.Create();
  CallingConv := ccDefault;
end;

destructor TRoutineTypeNode.Destroy();
begin
  Params.Free();

  inherited Destroy();
end;

{ TVarDeclNode }

destructor TVarDeclNode.Destroy();
begin
  InitValue.Free();

  inherited Destroy();
end;

{ TConstNode }

destructor TConstNode.Destroy();
begin
  Value.Free();

  inherited Destroy();
end;

{ TRoutineNode }

constructor TRoutineNode.Create();
begin
  inherited Create();

  Params := TObjectList<TParamNode>.Create();
  LocalVars := TObjectList<TVarDeclNode>.Create();
end;

destructor TRoutineNode.Destroy();
begin
  Body.Free();
  LocalVars.Free();
  Params.Free();

  inherited Destroy();
end;

{ TBlockNode }

constructor TBlockNode.Create();
begin
  inherited Create();

  Statements := TObjectList<TASTNode>.Create();
end;

destructor TBlockNode.Destroy();
begin
  Statements.Free();

  inherited Destroy();
end;

{ TIfNode }

destructor TIfNode.Destroy();
begin
  ElseBlock.Free();
  ThenBlock.Free();
  Condition.Free();

  inherited Destroy();
end;

{ TWhileNode }

destructor TWhileNode.Destroy();
begin
  Body.Free();
  Condition.Free();

  inherited Destroy();
end;

{ TForNode }

destructor TForNode.Destroy();
begin
  Body.Free();
  EndExpr.Free();
  StartExpr.Free();

  inherited Destroy();
end;

{ TRepeatNode }

destructor TRepeatNode.Destroy();
begin
  Condition.Free();
  Body.Free();

  inherited Destroy();
end;

{ TCaseBranch }

constructor TCaseBranch.Create();
begin
  inherited Create();

  Values := TObjectList<TASTNode>.Create();
end;

destructor TCaseBranch.Destroy();
begin
  Body.Free();
  Values.Free();

  inherited Destroy();
end;

{ TCaseNode }

constructor TCaseNode.Create();
begin
  inherited Create();

  Branches := TObjectList<TCaseBranch>.Create();
end;

destructor TCaseNode.Destroy();
begin
  ElseBlock.Free();
  Branches.Free();
  Expr.Free();

  inherited Destroy();
end;

{ TReturnNode }

destructor TReturnNode.Destroy();
begin
  Value.Free();

  inherited Destroy();
end;

{ TAssignNode }

destructor TAssignNode.Destroy();
begin
  Value.Free();
  Target.Free();

  inherited Destroy();
end;

{ TCallNode }

constructor TCallNode.Create();
begin
  inherited Create();

  Args := TObjectList<TASTNode>.Create();
end;

destructor TCallNode.Destroy();
begin
  Receiver.Free();
  Args.Free();

  inherited Destroy();
end;

{ TInheritedCallNode }

constructor TInheritedCallNode.Create();
begin
  inherited Create();

  Args := TObjectList<TASTNode>.Create();
end;

destructor TInheritedCallNode.Destroy();
begin
  Args.Free();

  inherited Destroy();
end;

{ TBinaryOpNode }

destructor TBinaryOpNode.Destroy();
begin
  Right.Free();
  Left.Free();

  inherited Destroy();
end;

{ TUnaryOpNode }

destructor TUnaryOpNode.Destroy();
begin
  Operand.Free();

  inherited Destroy();
end;

{ TFieldAccessNode }

destructor TFieldAccessNode.Destroy();
begin
  Target.Free();

  inherited Destroy();
end;

{ TIndexAccessNode }

destructor TIndexAccessNode.Destroy();
begin
  Index.Free();
  Target.Free();

  inherited Destroy();
end;

{ TDerefNode }

destructor TDerefNode.Destroy();
begin
  Target.Free();

  inherited Destroy();
end;

{ TTypeTestNode }

destructor TTypeTestNode.Destroy();
begin
  Expr.Free();

  inherited Destroy();
end;

{ TTypeCastNode }

destructor TTypeCastNode.Destroy();
begin
  Expr.Free();

  inherited Destroy();
end;

{ TSetLitNode }

constructor TSetLitNode.Create();
begin
  inherited Create();

  Elements := TObjectList<TASTNode>.Create();
end;

destructor TSetLitNode.Destroy();
begin
  Elements.Free();

  inherited Destroy();
end;

{ TRangeNode }

destructor TRangeNode.Destroy();
begin
  HighExpr.Free();
  LowExpr.Free();

  inherited Destroy();
end;

{ TNewNode }

destructor TNewNode.Destroy();
begin
  Target.Free();

  inherited Destroy();
end;

{ TDisposeNode }

destructor TDisposeNode.Destroy();
begin
  Target.Free();

  inherited Destroy();
end;

{ TSetLengthNode }

destructor TSetLengthNode.Destroy();
begin
  NewSize.Free();
  Target.Free();

  inherited Destroy();
end;

{ TLenNode }

destructor TLenNode.Destroy();
begin
  Target.Free();

  inherited Destroy();
end;

{ TParamStrNode }

destructor TParamStrNode.Destroy();
begin
  Index.Free();

  inherited Destroy();
end;

{ TTryNode }

destructor TTryNode.Destroy();
begin
  FinallyBlock.Free();
  ExceptBlock.Free();
  TryBlock.Free();

  inherited Destroy();
end;

{ TTestNode }

constructor TTestNode.Create();
begin
  inherited Create();

  LocalVars := TObjectList<TVarDeclNode>.Create();
  LocalConsts := TObjectList<TASTNode>.Create();
  LocalTypes := TObjectList<TASTNode>.Create();
end;

destructor TTestNode.Destroy();
begin
  Body.Free();
  LocalTypes.Free();
  LocalConsts.Free();
  LocalVars.Free();

  inherited Destroy();
end;

end.
