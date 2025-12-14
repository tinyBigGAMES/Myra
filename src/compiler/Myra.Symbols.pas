{===============================================================================
  Myra™ - Pascal. Refined.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit Myra.Symbols;

{$I Myra.Defines.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Myra.Utils,
  Myra.AST;

type
  TSymbol = class;
  TTypeSymbol = class;
  TScope = class;

  { TSymbolKind }
  TSymbolKind = (
    skConst,
    skVar,
    skType,
    skRoutine,
    skParam,
    skField
  );

  { TSymbol }
  TSymbol = class(TBaseObject)
  public
    SymbolName: string;
    Kind: TSymbolKind;
    TypeRef: TTypeSymbol;
    IsPublic: Boolean;
    Node: TASTNode;

    constructor Create(); override;
  end;

  { TTypeSymbol }
  TTypeSymbol = class(TSymbol)
  public
    BaseType: TTypeSymbol;
    Fields: TObjectList<TSymbol>;
    Methods: TObjectList<TSymbol>;
    IsBuiltIn: Boolean;

    constructor Create(); override;
    destructor Destroy(); override;

    function FindMethod(const AName: string): TSymbol;
  end;

  { TRoutineSymbol }
  TRoutineSymbol = class(TSymbol)
  public
    Params: TObjectList<TSymbol>;
    ReturnType: TTypeSymbol;
    IsMethod: Boolean;
    BoundToType: TTypeSymbol;

    constructor Create(); override;
    destructor Destroy(); override;
  end;

  { TRoutineTypeSymbol }
  TRoutineTypeSymbol = class(TTypeSymbol)
  public
    Params: TObjectList<TSymbol>;
    ReturnType: TTypeSymbol;
    CallingConv: TCallingConvention;

    constructor Create(); override;
    destructor Destroy(); override;
  end;

  { TScope }
  TScope = class(TBaseObject)
  private
    FSymbols: TObjectDictionary<string, TObjectList<TSymbol>>;

  public
    Parent: TScope;
    ScopeName: string;

    constructor Create(); override;
    destructor Destroy(); override;

    procedure Define(const ASymbol: TSymbol);
    function Lookup(const AName: string): TSymbol;
    function LookupLocal(const AName: string): TSymbol;
    function LookupAllLocal(const AName: string): TArray<TSymbol>;
    function Contains(const AName: string): Boolean;
    function GetAllSymbols(): TArray<TSymbol>;
  end;

  { TSymbolTable }
  TSymbolTable = class(TBaseObject)
  private
    FCurrentScope: TScope;
    FGlobalScope: TScope;
    FModules: TObjectDictionary<string, TScope>;
    FBuiltInTypes: TObjectDictionary<string, TTypeSymbol>;
    FImportedModules: TList<string>;

    procedure InitBuiltInTypes();

  public
    constructor Create(); override;
    destructor Destroy(); override;

    procedure EnterScope(const AName: string = '');
    procedure LeaveScope();
    procedure EnterModuleScope(const AName: string);
    procedure LeaveModuleScope();

    procedure Define(const ASymbol: TSymbol);
    procedure ImportModule(const AName: string);
    procedure ClearImports();
    function Lookup(const AName: string): TSymbol;
    function LookupQualified(const AModule: string; const AName: string): TSymbol;
    function LookupAllQualified(const AModule: string; const AName: string): TArray<TSymbol>;
    function GetModuleSymbols(const AModule: string): TArray<TSymbol>;
    function GetAllSymbols(): TArray<TSymbol>;
    function LookupType(const AName: string): TTypeSymbol;
    function GetBuiltInType(const AName: string): TTypeSymbol;

    property CurrentScope: TScope read FCurrentScope;
    property GlobalScope: TScope read FGlobalScope;

    function HasModule(const AName: string): Boolean;
  end;

implementation

{ TSymbol }

constructor TSymbol.Create();
begin
  inherited Create();
end;

{ TTypeSymbol }

constructor TTypeSymbol.Create();
begin
  inherited Create();

  Kind := skType;
  Fields := TObjectList<TSymbol>.Create(True); // Type owns its field symbols
  Methods := TObjectList<TSymbol>.Create(False); // Don't own methods, scope owns them
end;

destructor TTypeSymbol.Destroy();
begin
  Methods.Free();
  Fields.Free();

  inherited Destroy();
end;

function TTypeSymbol.FindMethod(const AName: string): TSymbol;
var
  LMethod: TSymbol;
begin
  Result := nil;

  // Search in this type's methods
  for LMethod in Methods do
  begin
    if LMethod.SymbolName = AName then
    begin
      Result := LMethod;
      Exit;
    end;
  end;

  // Search in parent type
  if (Result = nil) and (BaseType <> nil) then
    Result := BaseType.FindMethod(AName);
end;

{ TRoutineSymbol }

constructor TRoutineSymbol.Create();
begin
  inherited Create();

  Kind := skRoutine;
  Params := TObjectList<TSymbol>.Create(True); // Routine owns its param symbols
end;

destructor TRoutineSymbol.Destroy();
begin
  Params.Free();

  inherited Destroy();
end;

{ TRoutineTypeSymbol }

constructor TRoutineTypeSymbol.Create();
begin
  inherited Create();

  Params := TObjectList<TSymbol>.Create(True); // Routine type owns its param symbols
  CallingConv := ccDefault;
end;

destructor TRoutineTypeSymbol.Destroy();
begin
  Params.Free();

  inherited Destroy();
end;

{ TScope }

constructor TScope.Create();
begin
  inherited Create();

  // Dictionary owns the lists, lists own the symbols
  FSymbols := TObjectDictionary<string, TObjectList<TSymbol>>.Create([doOwnsValues]);
end;

destructor TScope.Destroy();
begin
  FSymbols.Free();

  inherited Destroy();
end;

procedure TScope.Define(const ASymbol: TSymbol);
var
  LKey: string;
  LList: TObjectList<TSymbol>;
begin
  LKey := ASymbol.SymbolName;

  if not FSymbols.TryGetValue(LKey, LList) then
  begin
    // Create new list for this symbol name
    LList := TObjectList<TSymbol>.Create(True); // List owns symbols
    FSymbols.Add(LKey, LList);
  end;

  // Add symbol to list (supports overloading)
  LList.Add(ASymbol);
end;

function TScope.Lookup(const AName: string): TSymbol;
var
  LKey: string;
  LList: TObjectList<TSymbol>;
begin
  LKey := AName;

  if FSymbols.TryGetValue(LKey, LList) and (LList.Count > 0) then
  begin
    Result := LList[0]; // Return first (maintains existing behavior)
    Exit;
  end;

  if Parent <> nil then
    Result := Parent.Lookup(AName)
  else
    Result := nil;
end;

function TScope.LookupLocal(const AName: string): TSymbol;
var
  LKey: string;
  LList: TObjectList<TSymbol>;
begin
  LKey := AName;

  if FSymbols.TryGetValue(LKey, LList) and (LList.Count > 0) then
    Result := LList[0]
  else
    Result := nil;
end;

function TScope.LookupAllLocal(const AName: string): TArray<TSymbol>;
var
  LKey: string;
  LList: TObjectList<TSymbol>;
begin
  LKey := AName;

  if FSymbols.TryGetValue(LKey, LList) then
    Result := LList.ToArray()
  else
    Result := nil;
end;

function TScope.Contains(const AName: string): Boolean;
begin
  Result := FSymbols.ContainsKey(AName);
end;

function TScope.GetAllSymbols(): TArray<TSymbol>;
var
  LResult: TList<TSymbol>;
  LPair: TPair<string, TObjectList<TSymbol>>;
  LSymbol: TSymbol;
begin
  LResult := TList<TSymbol>.Create();
  try
    for LPair in FSymbols do
    begin
      for LSymbol in LPair.Value do
        LResult.Add(LSymbol);
    end;
    Result := LResult.ToArray();
  finally
    LResult.Free();
  end;
end;

{ TSymbolTable }

constructor TSymbolTable.Create();
begin
  inherited Create();

  FModules := TObjectDictionary<string, TScope>.Create([doOwnsValues]);
  FBuiltInTypes := TObjectDictionary<string, TTypeSymbol>.Create([doOwnsValues]);
  FImportedModules := TList<string>.Create();

  FGlobalScope := TScope.Create();
  FGlobalScope.ScopeName := 'global';
  FCurrentScope := FGlobalScope;

  InitBuiltInTypes();
end;

destructor TSymbolTable.Destroy();
begin
  FImportedModules.Free();
  FBuiltInTypes.Free();
  FModules.Free();
  FGlobalScope.Free();

  inherited Destroy();
end;

procedure TSymbolTable.InitBuiltInTypes();

  procedure AddBuiltIn(const AName: string);
  var
    LType: TTypeSymbol;
  begin
    LType := TTypeSymbol.Create();
    LType.SymbolName := AName;
    LType.IsBuiltIn := True;
    LType.IsPublic := True;
    FBuiltInTypes.Add(UpperCase(AName), LType);
  end;

begin
  AddBuiltIn('BOOLEAN');
  AddBuiltIn('CHAR');
  AddBuiltIn('UCHAR');
  AddBuiltIn('INTEGER');
  AddBuiltIn('UINTEGER');
  AddBuiltIn('FLOAT');
  AddBuiltIn('STRING');
  AddBuiltIn('SET');
  AddBuiltIn('POINTER');
end;

procedure TSymbolTable.EnterScope(const AName: string);
var
  LScope: TScope;
begin
  LScope := TScope.Create();
  LScope.ScopeName := AName;
  LScope.Parent := FCurrentScope;
  FCurrentScope := LScope;
end;

procedure TSymbolTable.LeaveScope();
var
  LOldScope: TScope;
begin
  if FCurrentScope <> FGlobalScope then
  begin
    LOldScope := FCurrentScope;
    FCurrentScope := FCurrentScope.Parent;
    LOldScope.Free();
  end;
end;

procedure TSymbolTable.EnterModuleScope(const AName: string);
var
  LScope: TScope;
  LKey: string;
begin
  LKey := AName;

  if not FModules.TryGetValue(LKey, LScope) then
  begin
    LScope := TScope.Create();
    LScope.ScopeName := AName;
    LScope.Parent := FGlobalScope;
    FModules.Add(LKey, LScope);
  end;

  FCurrentScope := LScope;
end;

procedure TSymbolTable.LeaveModuleScope();
begin
  FCurrentScope := FGlobalScope;
end;

procedure TSymbolTable.Define(const ASymbol: TSymbol);
begin
  FCurrentScope.Define(ASymbol);
end;

procedure TSymbolTable.ImportModule(const AName: string);
var
  LKey: string;
begin
  LKey := AName;
  if FImportedModules.IndexOf(LKey) < 0 then
    FImportedModules.Add(LKey);
end;

procedure TSymbolTable.ClearImports();
begin
  FImportedModules.Clear();
end;

function TSymbolTable.Lookup(const AName: string): TSymbol;
var
  LModulePair: TPair<string, TScope>;
begin
  Result := FCurrentScope.Lookup(AName);

  // Check built-in types if not found
  if Result = nil then
    Result := GetBuiltInType(AName);
    
  // Check all module scopes as fallback (for LSP after analysis)
  if Result = nil then
  begin
    for LModulePair in FModules do
    begin
      Result := LModulePair.Value.LookupLocal(AName);
      if Result <> nil then
        Exit;
    end;
  end;
end;

function TSymbolTable.LookupQualified(const AModule: string; const AName: string): TSymbol;
var
  LScope: TScope;
  LKey: string;
begin
  Result := nil;
  LKey := AModule;

  if FModules.TryGetValue(LKey, LScope) then
    Result := LScope.LookupLocal(AName);
end;

function TSymbolTable.LookupAllQualified(const AModule: string; const AName: string): TArray<TSymbol>;
var
  LScope: TScope;
  LKey: string;
begin
  Result := nil;
  LKey := AModule;

  if FModules.TryGetValue(LKey, LScope) then
    Result := LScope.LookupAllLocal(AName);
end;

function TSymbolTable.GetModuleSymbols(const AModule: string): TArray<TSymbol>;
var
  LScope: TScope;
  LKey: string;
  LResult: TList<TSymbol>;
  LSymbol: TSymbol;
begin
  Result := nil;
  LKey := AModule;

  if FModules.TryGetValue(LKey, LScope) then
  begin
    LResult := TList<TSymbol>.Create();
    try
      for LSymbol in LScope.GetAllSymbols() do
      begin
        if LSymbol.IsPublic then
          LResult.Add(LSymbol);
      end;
      Result := LResult.ToArray();
    finally
      LResult.Free();
    end;
  end;
end;

function TSymbolTable.GetAllSymbols(): TArray<TSymbol>;
var
  LResult: TList<TSymbol>;
  LModulePair: TPair<string, TScope>;
  LSymbol: TSymbol;
begin
  LResult := TList<TSymbol>.Create();
  try
    // Add symbols from all module scopes
    for LModulePair in FModules do
    begin
      for LSymbol in LModulePair.Value.GetAllSymbols() do
        LResult.Add(LSymbol);
    end;
    
    // Add symbols from global scope
    for LSymbol in FGlobalScope.GetAllSymbols() do
      LResult.Add(LSymbol);
      
    Result := LResult.ToArray();
  finally
    LResult.Free();
  end;
end;

function TSymbolTable.LookupType(const AName: string): TTypeSymbol;
var
  LSymbol: TSymbol;
begin
  Result := GetBuiltInType(AName);

  if Result = nil then
  begin
    LSymbol := Lookup(AName);
    if (LSymbol <> nil) and (LSymbol is TTypeSymbol) then
      Result := TTypeSymbol(LSymbol);
  end;
end;

function TSymbolTable.GetBuiltInType(const AName: string): TTypeSymbol;
var
  LKey: string;
begin
  LKey := UpperCase(AName);

  if not FBuiltInTypes.TryGetValue(LKey, Result) then
    Result := nil;
end;

function TSymbolTable.HasModule(const AName: string): Boolean;
var
  LKey: string;
begin
  LKey := AName;
  Result := FModules.ContainsKey(LKey);
end;

end.
