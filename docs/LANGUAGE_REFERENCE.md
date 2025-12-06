# Myra Language Reference

Complete specification for Myra 1.0.

## Table of Contents

1. [Lexical Elements](#lexical-elements)
2. [Module Structure](#module-structure)
3. [Types](#types)
4. [Declarations](#declarations)
5. [Statements](#statements)
6. [Expressions](#expressions)
7. [Routines and Methods](#routines-and-methods)
8. [Type Extension and Polymorphism](#type-extension-and-polymorphism)
9. [Exception Handling](#exception-handling)
10. [C++ Interoperability](#c-interoperability)
11. [Directives](#directives)
12. [Unit Testing](#unit-testing)

## Lexical Elements

### Keywords (45)

```
MODULE    IMPORT    PUBLIC    CONST     TYPE      VAR
ROUTINE   METHOD    BEGIN     END       IF        THEN
ELSE      CASE      OF        WHILE     DO        REPEAT
UNTIL     FOR       TO        DOWNTO    RETURN    ARRAY
RECORD    SET       POINTER   NIL       AND       OR
NOT       DIV       MOD       IN        IS        AS
TRY       EXCEPT    FINALLY   TEST      EXTERNAL  SELF
INHERITED PARAMCOUNT PARAMSTR
```

Keywords are case-insensitive. `begin`, `BEGIN`, and `Begin` are equivalent.

### Identifiers

Identifiers start with a letter or underscore, followed by letters, digits, or underscores. Identifiers are case-sensitive.

```myra
MyVariable    // valid
_private      // valid
count2        // valid
2ndValue      // invalid - starts with digit
```

### Operators

| Operator | Description |
|----------|-------------|
| `:=` | Assignment |
| `=` | Equality |
| `<>` | Not equal |
| `<` `>` `<=` `>=` | Comparison |
| `+` `-` `*` `/` | Arithmetic |
| `DIV` | Integer division |
| `MOD` | Modulus |
| `AND` `OR` `NOT` | Logical |
| `IN` | Set membership |
| `IS` | Type test |
| `AS` | Type cast |
| `.` | Field access |
| `^` | Pointer dereference |
| `..` | Range |
| `...` | Variadic parameters |

### Operator Precedence (Highest to Lowest)

| Level | Operators |
|-------|-----------|
| 1 | `NOT`, unary `+`, unary `-` |
| 2 | `*`, `/`, `DIV`, `MOD`, `AND` |
| 3 | `+`, `-`, `OR` |
| 4 | `=`, `<>`, `<`, `>`, `<=`, `>=`, `IN` |
| 5 | `IS`, `AS` |

### Literals

**Integers:**
```myra
42          // decimal
0x2A        // hexadecimal
```

**Floats:**
```myra
3.14159
1.0e-10
```

**Strings:**
```myra
'Hello, World!'
'It''s escaped'    // doubled single quote
```

**Characters:**
```myra
'A'
'\n'        // newline
'\x1b'      // hex escape (ESC)
```

**Booleans:**
```myra
TRUE
FALSE
```

### Comments

```myra
// Single line comment

(* Multi-line
   comment *)
```

## Module Structure

Every Myra source file is a module.

### Module Declaration

```myra
module ModuleKind ModuleName;
```

Module kinds:
- `exe` — Executable program (has entry point)
- `lib` — Static library (no entry point)
- `dll` — Dynamic library (no entry point)

### Complete Module Structure

```myra
module exe MyProgram;

import
  Console,
  System;

const
  MaxSize = 100;

type
  TData = record
    Value: INTEGER;
  end;

var
  GlobalCount: INTEGER;

routine DoWork();
begin
  // ...
end;

begin
  // Entry point (exe only)
  DoWork();
end.
```

### Import Statement

```myra
import
  Console,
  System,
  MyModule;
```

Imported symbols must be used with full module qualification:

```myra
Console.PrintLn('Hello');
System.Halt(0);
```

### Visibility

Everything is private by default. Use `PUBLIC` to export:

```myra
public const
  Version = '1.0';

public type
  TPoint = record
    X: INTEGER;
    Y: INTEGER;
  end;

public var
  Counter: INTEGER;

public routine GetCount(): INTEGER;
begin
  return Counter;
end;
```

## Types

### Built-in Types

| Type | C++ Mapping | Description |
|------|-------------|-------------|
| `BOOLEAN` | `bool` | `TRUE` or `FALSE` |
| `CHAR` | `char` | Signed single byte character |
| `UCHAR` | `unsigned char` | Unsigned single byte character |
| `INTEGER` | `int64_t` | Signed 64-bit integer |
| `UINTEGER` | `uint64_t` | Unsigned 64-bit integer |
| `FLOAT` | `double` | 64-bit IEEE 754 |
| `STRING` | `std::string` | Auto-managed string |
| `SET` | `std::bitset` | Bit set for ordinal ranges |
| `POINTER` | `void*` | Untyped pointer |

### Record Types

```myra
type
  TPoint = record
    X: INTEGER;
    Y: INTEGER;
  end;

  TPerson = record
    Name: STRING;
    Age: INTEGER;
    Active: BOOLEAN;
  end;
```

Usage:
```myra
var
  Point: TPoint;
  Person: TPerson;
begin
  Point.X := 10;
  Point.Y := 20;
  
  Person.Name := 'Alice';
  Person.Age := 30;
  Person.Active := TRUE;
end.
```

### Record Extension

Records can extend other records:

```myra
type
  TShape = record
    X: INTEGER;
    Y: INTEGER;
  end;

  TCircle = record(TShape)
    Radius: INTEGER;
  end;

  TRect = record(TShape)
    Width: INTEGER;
    Height: INTEGER;
  end;
```

Extended records inherit all parent fields:

```myra
var
  Circle: TCircle;
begin
  Circle.X := 100;       // inherited from TShape
  Circle.Y := 100;       // inherited from TShape
  Circle.Radius := 50;   // own field
end.
```

### Array Types

**Static arrays:**
```myra
type
  TNumbers = ARRAY[0..9] OF INTEGER;
  TMatrix = ARRAY[0..2, 0..2] OF FLOAT;

var
  Numbers: TNumbers;
  Matrix: TMatrix;
begin
  Numbers[0] := 42;
  Matrix[1, 1] := 3.14;
end.
```

**Dynamic arrays:**
```myra
var
  Data: ARRAY OF INTEGER;
  Names: ARRAY OF STRING;
begin
  SetLength(Data, 100);
  Data[0] := 1;
  
  SetLength(Names, 3);
  Names[0] := 'Alice';
  
  Console.PrintLn('Length: {}', Len(Data));
end.
```

### Pointer Types

**Typed pointers:**
```myra
type
  PInteger = POINTER TO INTEGER;
  PShape = POINTER TO TShape;

var
  P: PInteger;
  S: PShape;
begin
  NEW(P);
  P^ := 42;
  Console.PrintLn('Value: {}', P^);
  DISPOSE(P);
end.
```

**Untyped pointers:**
```myra
var
  Raw: POINTER;
begin
  Raw := NIL;
end.
```

**Dereferencing:**

Use `^` to dereference pointers:
```myra
var
  P: PInteger;
  S: PShape;
begin
  NEW(P);
  P^ := 42;
  Console.PrintLn('{}', P^);
  DISPOSE(P);
  
  NEW(S);
  S^.X := 10;
  S^.Y := 20;
  DISPOSE(S);
end.
```

### Set Types

```myra
type
  TByteSet = SET OF 0..31;
  TCharSet = SET OF 0..255;

var
  Flags: TByteSet;
  Vowels: TCharSet;
begin
  Flags := {1, 2, 4};
  Flags := {0..7};           // range
  Flags := {1, 3, 5..10};    // mixed
  
  if 4 IN Flags then
    Console.PrintLn('Flag 4 is set');
  end;
end.
```

Set operations:
```myra
var
  A: TByteSet;
  B: TByteSet;
  C: TByteSet;
begin
  A := {1, 2, 3};
  B := {2, 3, 4};
  
  C := A + B;    // union: {1, 2, 3, 4}
  C := A * B;    // intersection: {2, 3}
  C := A - B;    // difference: {1}
end.
```

### Routine Types

Routine types allow routines to be stored in variables and passed as parameters:

```myra
type
  TSimpleProc = routine();
  TIntFunc = routine(const A: INTEGER): INTEGER;
  TCallback = routine(const AValue: INTEGER; var AResult: INTEGER);

var
  MyProc: TSimpleProc;
  MyFunc: TIntFunc;

routine Double(const A: INTEGER): INTEGER;
begin
  return A * 2;
end;

begin
  MyFunc := Double;
  Console.PrintLn('Result: {}', MyFunc(21));  // prints 42
end.
```

Routine types in records (callbacks/event handlers):
```myra
type
  TOnClick = routine();
  TOnValue = routine(const AValue: INTEGER);

  TButton = record
    Caption: STRING;
    OnClick: TOnClick;
    OnValue: TOnValue;
  end;
```

## Declarations

### Constants

**Untyped constants:**
```myra
const
  MaxSize = 100;
  Pi = 3.14159;
  AppName = 'MyApp';
  Debug = TRUE;
```

**Typed constants:**
```myra
const
  MaxCount: INTEGER = 1000;
  Epsilon: FLOAT = 0.0001;
```

### Variables

**Module-level variables:**
```myra
var
  Counter: INTEGER;
  Name: STRING;
  Active: BOOLEAN;
```

**Local variables:**
```myra
routine DoWork();
var
  I: INTEGER;
  Total: FLOAT;
  Temp: STRING;
begin
  I := 0;
  Total := 0.0;
  Temp := '';
end;
```

## Statements

### Assignment

```myra
X := 10;
Name := 'Alice';
Point.X := 100;
Data[0] := 42;
P^ := Value;
```

### If Statement

```myra
if Condition then
  DoSomething();
end;

if X > 0 then
  Console.PrintLn('Positive');
else
  Console.PrintLn('Non-positive');
end;

if X > 100 then
  Console.PrintLn('Large');
else if X > 10 then
  Console.PrintLn('Medium');
else
  Console.PrintLn('Small');
end;
```

### While Statement

```myra
while Count > 0 do
  Process();
  Count := Count - 1;
end;
```

### For Statement

```myra
// Counting up
for I := 1 to 10 do
  Console.PrintLn('I = {}', I);
end;

// Counting down
for I := 10 downto 1 do
  Console.PrintLn('Countdown: {}', I);
end;

// Nested loops
for I := 1 to 3 do
  for J := 1 to 3 do
    Console.PrintLn('{}, {}', I, J);
  end;
end;
```

### Repeat Statement

```myra
repeat
  Process();
  Count := Count - 1;
until Count = 0;
```

### Case Statement

```myra
case Day of
  1: Result := 'Monday';
  2: Result := 'Tuesday';
  3: Result := 'Wednesday';
  4: Result := 'Thursday';
  5: Result := 'Friday';
  6, 7: Result := 'Weekend';
else
  Result := 'Invalid';
end;

// Multiple values per branch
case Value of
  1, 2, 3: Console.PrintLn('Low');
  4, 5, 6: Console.PrintLn('Medium');
  7, 8, 9: Console.PrintLn('High');
end;
```

### Return Statement

```myra
routine GetMax(const A: INTEGER; const B: INTEGER): INTEGER;
begin
  if A > B then
    return A;
  else
    return B;
  end;
end;

routine DoWork();
begin
  if not Ready then
    return;  // early exit
  end;
  Process();
end;
```

## Routines and Methods

### Routine Declaration

```myra
// No parameters, no return value
routine SayHello();
begin
  Console.PrintLn('Hello!');
end;

// Parameters with return value
routine Add(const A: INTEGER; const B: INTEGER): INTEGER;
begin
  return A + B;
end;

// VAR parameter (pass by reference)
routine Increment(var AValue: INTEGER);
begin
  AValue := AValue + 1;
end;

// Mixed parameters
routine Process(const AInput: INTEGER; var AOutput: INTEGER);
begin
  AOutput := AInput * 2;
end;
```

### Parameter Modifiers

| Modifier | Meaning |
|----------|---------|
| `const` | Pass by value (read-only) |
| `var` | Pass by reference (mutable) |
| (none) | Pass by value |

### Variadic Routines

```myra
public routine Print(...);
begin
  // Implementation uses C++ variadic templates
end;
```

### External Routines

```myra
routine MessageBoxA(
  const AHwnd: POINTER;
  const AText: STRING;
  const ACaption: STRING;
  const AType: INTEGER
): INTEGER;
external 'user32.dll';
```

### Methods

Methods are routines bound to a type. Declare with `method` keyword and `var Self` parameter:

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

method Add(var Self: TCounter; const AAmount: INTEGER);
begin
  Self.Value := Self.Value + AAmount;
end;

method GetValue(var Self: TCounter): INTEGER;
begin
  return Self.Value;
end;
```

Call methods using dot notation:
```myra
var
  Counter: TCounter;
begin
  Counter.Reset();
  Counter.Increment();
  Counter.Add(10);
  Console.PrintLn('Value: {}', Counter.GetValue());
end.
```

## Type Extension and Polymorphism

### Type Testing: IS

```myra
var
  Shape: PShape;
begin
  NEW(Shape AS TCircle);
  
  if Shape IS TCircle then
    Console.PrintLn('It is a circle');
  end;
  
  DISPOSE(Shape);
end.
```

### Type Casting: AS

```myra
var
  Shape: PShape;
  Circle: TCircle;
begin
  NEW(Shape AS TCircle);
  
  if Shape IS TCircle then
    Circle := Shape AS TCircle;
    Console.PrintLn('Radius: {}', Circle.Radius);
  end;
  
  DISPOSE(Shape);
end.
```

### Polymorphic Allocation

```myra
var
  Shape: POINTER TO TShape;
begin
  NEW(Shape AS TCircle);   // allocate derived type
  // Shape points to a TCircle
  DISPOSE(Shape);
end.
```

### Method Overriding

```myra
type
  TShape = record
    X: INTEGER;
    Y: INTEGER;
  end;

  TCircle = record(TShape)
    Radius: INTEGER;
  end;

// Base method
method Describe(var Self: TShape);
begin
  Console.PrintLn('Shape at ({}, {})', Self.X, Self.Y);
end;

// Override for TCircle
method Describe(var Self: TCircle);
begin
  inherited Describe();  // call parent method
  Console.PrintLn('  Radius: {}', Self.Radius);
end;
```

### Inherited Keyword

Use `inherited` to call the parent type's method:

```myra
method Draw(var Self: TCircle);
begin
  inherited Draw();      // calls TShape.Draw
  DrawCircleSpecific();
end;
```

## Exception Handling

### Try/Except

```myra
try
  DoRiskyOperation();
except
  Console.PrintLn('Error: {}', System.GetExceptionMessage());
end;
```

### Try/Finally

```myra
try
  OpenFile();
  ProcessFile();
finally
  CloseFile();  // always executes
end;
```

### Try/Except/Finally

```myra
try
  DoWork();
except
  HandleError();
finally
  Cleanup();
end;
```

### Raising Exceptions

```myra
import System;

routine Divide(const A: INTEGER; const B: INTEGER): INTEGER;
begin
  if B = 0 then
    System.RaiseException('Division by zero');
  end;
  return A DIV B;
end;
```

### Getting Exception Message

```myra
try
  DoWork();
except
  Console.PrintLn('Caught: {}', System.GetExceptionMessage());
end;
```

## C++ Interoperability

Myra's defining feature: seamless C++ integration.

### Raw C++ Blocks

```myra
#startcpp header
#include <vector>
inline int CppAdd(int a, int b) {
    return a + b;
}
#endcpp

#startcpp source
void CppHelper() {
    // Implementation
}
#endcpp
```

### C++ Passthrough

C++ code can appear directly in Myra:

```myra
const
  constexpr int32_t MAX_SIZE = 1024;

type
  typedef int32_t MyInt;

var
  flags: uint32_t;

begin
  int32_t localVar = 42;
  Console.PrintLn('Value: {}', localVar);
end.
```

### Calling C++ from Myra

```myra
#startcpp header
inline int Square(int x) { return x * x; }
#endcpp

begin
  Console.PrintLn('5 squared = {}', Square(5));
end.
```

### Including Headers

```myra
#include_header '<vector>'
#include_header '<algorithm>'
#include_header '"myheader.h"'
```

## Directives

### Include Directives

```myra
#include_header '<iostream>'
#include_header '"local.h"'
#include_path 'path/to/headers'
```

### Link Directives

```myra
#link 'mylib'
#library_path 'path/to/libs'
```

### Build Directives

```myra
// Optimization
#optimization DEBUG
#optimization RELEASESAFE
#optimization RELEASEFAST
#optimization RELEASESMALL

// Target platform
#target native
#target x86_64-windows
#target x86_64-linux
#target aarch64-macos

// Application type (Windows)
#apptype CONSOLE
#apptype GUI

// ABI for external functions
#abi C
#abi CPP
```

### Unit Test Mode

```myra
#unittestmode ON
```

## Unit Testing

### TEST Blocks

```myra
#unittestmode ON

module exe MyTests;

import UnitTest;

var
  GValue: INTEGER;

routine Double(const A: INTEGER): INTEGER;
begin
  return A * 2;
end;

begin
end.

test 'Double returns correct value';
var
  LResult: INTEGER;
begin
  LResult := Double(21);
  TestAssertEqual(42, LResult);
end;

test 'Double handles zero';
begin
  TestAssertEqual(0, Double(0));
end;

test 'Double handles negative';
begin
  TestAssertEqual(-10, Double(-5));
end;
```

### Test Assertions

| Assertion | Description |
|-----------|-------------|
| `TestAssert(cond)` | Fails if condition is false |
| `TestAssertTrue(cond)` | Fails if not true |
| `TestAssertFalse(cond)` | Fails if not false |
| `TestAssertEqual(exp, act)` | Fails if not equal |
| `TestAssertNotEqual(val, act)` | Fails if equal |
| `TestAssertNil(ptr)` | Fails if not nil |
| `TestAssertNotNil(ptr)` | Fails if nil |
| `TestFail(msg)` | Unconditional failure |

## Built-in Operations

### Memory Management

```myra
var
  P: POINTER TO TData;
begin
  NEW(P);              // allocate
  NEW(P AS TDerived);  // allocate as derived type
  DISPOSE(P);          // deallocate
end.
```

### Dynamic Arrays

```myra
var
  Data: ARRAY OF INTEGER;
begin
  SetLength(Data, 100);     // resize
  Console.PrintLn('{}', Len(Data)); // get length
end.
```

### Command Line Arguments

Access command line arguments using `ParamCount` and `ParamStr`:

```myra
var
  I: INTEGER;
begin
  Console.PrintLn('Argument count: {}', ParamCount);
  for I := 0 to ParamCount - 1 do
    Console.PrintLn('  [{}] = {}', I, ParamStr(I));
  end;
end.
```

| Keyword | Description |
|---------|-------------|
| `ParamCount` | Returns number of command line arguments |
| `ParamStr(N)` | Returns the Nth command line argument (0-based) |

### Boolean Constants

```myra
var
  Active: BOOLEAN;
begin
  Active := TRUE;
  Active := FALSE;
end.
```

## File Extension

Myra source files use the `.myra` extension.


*Myra™ — Pascal. Refined.*
