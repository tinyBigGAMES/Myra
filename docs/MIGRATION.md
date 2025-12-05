# Migration Guide

Transitioning from Pascal/Delphi to Myra.

## Table of Contents

1. [Overview](#overview)
2. [What's the Same](#whats-the-same)
3. [What's Different](#whats-different)
4. [What's Gone](#whats-gone)
5. [What's New](#whats-new)
6. [Syntax Changes](#syntax-changes)
7. [Porting Guide](#porting-guide)

## Overview

Myra is Pascal refined to its essence. If you know Pascal or Delphi, you'll feel at home. The core concepts remain: strong typing, readable syntax, structured programming. The complexity is stripped away.

## What's the Same

- Record types with fields
- Strong static typing
- BEGIN/END blocks
- IF/THEN/ELSE
- WHILE/DO, FOR/TO/DOWNTO, REPEAT/UNTIL
- CASE/OF statements
- Pointer types with NEW/DISPOSE
- Arrays (static and dynamic)
- Sets with IN operator
- AND/OR/NOT logical operators
- DIV/MOD integer operators
- Single-line `//` and multi-line `(* *)` comments

## What's Different

### Module Declaration

**Delphi:**
```pascal
unit MyUnit;

interface
// public declarations

implementation
// private code

end.
```

**Myra:**
```myra
module lib MyUnit;

// PUBLIC keyword marks exports
public type
  TMyType = record
    Value: INTEGER;
  end;

public routine DoWork();
begin
end;

// No PUBLIC = private
routine Helper();
begin
end;

end.
```

### Routines

**Delphi:**
```pascal
procedure DoWork;
begin
end;

function Calculate(A, B: Integer): Integer;
begin
  Result := A + B;
end;
```

**Myra:**
```myra
routine DoWork();
begin
end;

routine Calculate(const A: INTEGER; const B: INTEGER): INTEGER;
begin
  return A + B;
end;
```

Key differences:
- Single `ROUTINE` keyword (not procedure/function)
- `return` instead of `Result :=`
- Parameters separated by semicolons
- Each parameter needs its own type

### Methods

**Delphi:**
```pascal
type
  TCounter = class
  private
    FValue: Integer;
  public
    procedure Reset;
    procedure Increment;
    function GetValue: Integer;
  end;

procedure TCounter.Reset;
begin
  FValue := 0;
end;
```

**Myra:**
```myra
type
  TCounter = record
    Value: INTEGER;
  end;

method Reset(var Self: TCounter);
begin
  Self.Value := 0;
end;

method Increment(var Self: TCounter);
begin
  Self.Value := Self.Value + 1;
end;

method GetValue(var Self: TCounter): INTEGER;
begin
  return Self.Value;
end;
```

Key differences:
- Records instead of classes
- Explicit `var Self` parameter
- `method` keyword for binding
- Call with dot notation: `Counter.Reset()`

### Control Structures

**Delphi:**
```pascal
if Condition then
begin
  DoSomething;
end
else
begin
  DoOther;
end;

while Count > 0 do
begin
  Process;
  Dec(Count);
end;

for I := 1 to 10 do
begin
  Process(I);
end;
```

**Myra:**
```myra
if Condition then
  DoSomething();
else
  DoOther();
end;

while Count > 0 do
  Process();
  Count := Count - 1;
end;

for I := 1 to 10 do
  Process(I);
end;
```

Key differences:
- No BEGIN after THEN/DO
- Always END to close blocks
- Semicolons after routine calls

### Exception Handling

**Delphi:**
```pascal
try
  DoWork;
except
  on E: Exception do
    ShowMessage(E.Message);
end;
```

**Myra:**
```myra
try
  DoWork();
except
  Console.PrintLn('Error: {}', System.GetExceptionMessage());
end;
```

Key differences:
- No `on E: Exception` syntax
- Use `System.GetExceptionMessage()` to get message
- Raise with `System.RaiseException('message')`

## What's Gone

### Classes

Use records with type extension instead.

**Delphi:**
```pascal
type
  TShape = class
    X, Y: Integer;
    procedure Draw; virtual;
  end;
  
  TCircle = class(TShape)
    Radius: Integer;
    procedure Draw; override;
  end;
```

**Myra:**
```myra
type
  TShape = record
    X: INTEGER;
    Y: INTEGER;
  end;
  
  TCircle = record(TShape)
    Radius: INTEGER;
  end;

method Draw(var Self: TShape);
begin
  Console.PrintLn('Shape at {}, {}', Self.X, Self.Y);
end;

method Draw(var Self: TCircle);
begin
  inherited Draw();
  Console.PrintLn('  Radius: {}', Self.Radius);
end;
```

### Interfaces

Use routine types for callbacks/polymorphism.

**Delphi:**
```pascal
type
  IClickable = interface
    procedure OnClick;
  end;
```

**Myra:**
```myra
type
  TOnClick = routine();
  
  TButton = record
    OnClick: TOnClick;
  end;
```

### Properties

Use routines directly.

**Delphi:**
```pascal
property Value: Integer read FValue write SetValue;
```

**Myra:**
```myra
method GetValue(var Self: TData): INTEGER;
begin
  return Self.FValue;
end;

method SetValue(var Self: TData; const AValue: INTEGER);
begin
  Self.FValue := AValue;
end;
```

### Generics

Use POINTER or C++ templates.

**Delphi:**
```pascal
type
  TList<T> = class
    // ...
  end;
```

**Myra (using C++):**
```myra
#startcpp header
template<typename T>
class List {
    std::vector<T> items;
public:
    void Add(const T& item) { items.push_back(item); }
    T& Get(size_t index) { return items[index]; }
};
#endcpp
```

### Other Removed Features

| Feature | Alternative |
|---------|-------------|
| WITH statement | Use full qualification |
| GOTO/LABEL | Structured control flow |
| Nested routines | Top-level routines |
| Anonymous methods | Routine types |
| Operator overloading | Named routines |
| RTTI | IS/AS operators |
| String CASE | IF/ELSE IF chain |

## What's New

### C++ Integration

Mix C++ freely with Myra:

```myra
#include_header '<vector>'

#startcpp header
inline int CppFunction(int x) {
    return x * 2;
}
#endcpp

begin
  Console.PrintLn('Result: {}', CppFunction(21));
  
  std::vector<int> vec;
  vec.push_back(10);
end.
```

### Format Strings

```myra
Console.PrintLn('Name: {}, Age: {}', Name, Age);
```

### Built-in Exception Handling

```myra
try
  DoWork();
except
  Console.PrintLn('Error: {}', System.GetExceptionMessage());
finally
  Cleanup();
end;
```

### Unit Testing

```myra
#unittestmode ON

test 'My test';
begin
  TestAssertEqual(42, Calculate(21, 21));
end;
```

### Modern Build System

- Cross-compilation support
- Multiple optimization levels
- Zig backend for C++ compilation

## Syntax Changes

### Quick Reference

| Delphi | Myra |
|--------|------|
| `procedure Foo;` | `routine Foo();` |
| `function Foo: Integer;` | `routine Foo(): INTEGER;` |
| `Result := X;` | `return X;` |
| `if X then begin ... end` | `if X then ... end` |
| `while X do begin ... end` | `while X do ... end` |
| `for I := 1 to N do begin ... end` | `for I := 1 to N do ... end` |
| `TMyClass = class` | `TMyRecord = record` |
| `TMyClass = class(TBase)` | `TMyRecord = record(TBase)` |
| `inherited;` | `inherited;` or `inherited MethodName();` |
| `on E: Exception do` | `except` + `GetExceptionMessage()` |
| `raise Exception.Create('msg')` | `System.RaiseException('msg')` |
| `Length(Arr)` | `Len(Arr)` |
| `ParamCount` | `ParamCount` |
| `ParamStr(N)` | `ParamStr(N)` |
| `SetLength(Arr, N)` | `SetLength(Arr, N)` |
| `WriteLn('text')` | `Console.PrintLn('text')` |
| `WriteLn('X=', X)` | `Console.PrintLn('X={}', X)` |

## Porting Guide

### Step 1: Convert Unit Structure

**From:**
```pascal
unit MyUnit;

interface

type
  TData = record
    Value: Integer;
  end;

procedure Process(var Data: TData);

implementation

procedure Process(var Data: TData);
begin
  Data.Value := Data.Value + 1;
end;

end.
```

**To:**
```myra
module lib MyUnit;

public type
  TData = record
    Value: INTEGER;
  end;

public routine Process(var AData: TData);
begin
  AData.Value := AData.Value + 1;
end;

end.
```

### Step 2: Convert Classes to Records

**From:**
```pascal
type
  TCounter = class
  private
    FCount: Integer;
  public
    constructor Create;
    procedure Inc;
    function GetCount: Integer;
  end;

constructor TCounter.Create;
begin
  FCount := 0;
end;

procedure TCounter.Inc;
begin
  FCount := FCount + 1;
end;

function TCounter.GetCount: Integer;
begin
  Result := FCount;
end;
```

**To:**
```myra
type
  TCounter = record
    Count: INTEGER;
  end;

method Init(var Self: TCounter);
begin
  Self.Count := 0;
end;

method Inc(var Self: TCounter);
begin
  Self.Count := Self.Count + 1;
end;

method GetCount(var Self: TCounter): INTEGER;
begin
  return Self.Count;
end;
```

### Step 3: Convert Control Flow

Remove BEGIN after THEN/DO, ensure END closes blocks:

**From:**
```pascal
if X > 0 then
begin
  for I := 1 to X do
  begin
    Process(I);
  end;
end
else
begin
  HandleError;
end;
```

**To:**
```myra
if X > 0 then
  for I := 1 to X do
    Process(I);
  end;
else
  HandleError();
end;
```

### Step 4: Convert Exception Handling

**From:**
```pascal
try
  DoWork;
except
  on E: Exception do
    ShowMessage(E.Message);
end;
```

**To:**
```myra
try
  DoWork();
except
  Console.PrintLn('Error: {}', System.GetExceptionMessage());
end;
```

### Step 5: Convert Output

**From:**
```pascal
WriteLn('Value: ', X);
WriteLn('A=', A, ' B=', B);
```

**To:**
```myra
Console.PrintLn('Value: {}', X);
Console.PrintLn('A={} B={}', A, B);
```

## Common Pitfalls

1. **Forgetting END** — Every IF/WHILE/FOR needs END
2. **Using BEGIN** — Don't use BEGIN after THEN/DO
3. **Result vs return** — Use `return X` not `Result := X`
4. **Parameter syntax** — Separate with semicolons, each needs type
5. **String formatting** — Use `{}` placeholders, not comma concatenation

*Myra™ — Pascal. Refined.*
