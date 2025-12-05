# Myra Tutorial

A guided learning path from beginner to proficient.

## Table of Contents

1. [Your First Program](#1-your-first-program)
2. [Variables and Types](#2-variables-and-types)
3. [Control Flow](#3-control-flow)
4. [Routines](#4-routines)
5. [Records](#5-records)
6. [Arrays](#6-arrays)
7. [Pointers](#7-pointers)
8. [Modules](#8-modules)
9. [Type Extension](#9-type-extension)
10. [Methods](#10-methods)
11. [Exception Handling](#11-exception-handling)
12. [C++ Integration](#12-c-integration)

## 1. Your First Program

Every Myra program starts with a module declaration.

```myra
module exe HelloWorld;

import Console;

begin
  Console.PrintLn('Hello from Myra!');
end.
```

Let's break this down:

- `module exe HelloWorld` — Declares an executable module
- `import Console` — Imports the Console module for output
- `begin...end.` — The main program block (note the period at the end)
- `Console.PrintLn('...')` — Prints text with a newline

Create a project, build and run:

```
myra init HelloWorld
cd HelloWorld
myra build
myra run
```

Output:
```
Hello from Myra!
```

## 2. Variables and Types

### Declaring Variables

Variables are declared in a `var` section:

```myra
module exe Variables;

import Console;

var
  Age: INTEGER;
  Name: STRING;
  Price: FLOAT;
  Active: BOOLEAN;

begin
  Age := 25;
  Name := 'Alice';
  Price := 19.99;
  Active := TRUE;
  
  Console.PrintLn('Name: {}', Name);
  Console.PrintLn('Age: {}', Age);
  Console.PrintLn('Price: {}', Price);
  Console.PrintLn('Active: {}', Active);
end.
```

### Built-in Types

| Type | Description | Example |
|------|-------------|---------|
| `BOOLEAN` | True or false | `TRUE`, `FALSE` |
| `CHAR` | Signed single byte character | `'A'`, `'\n'` |
| `UCHAR` | Unsigned single byte character | `'A'` |
| `INTEGER` | 64-bit signed integer | `42`, `-100` |
| `UINTEGER` | 64-bit unsigned integer | `0`, `255` |
| `FLOAT` | 64-bit floating point | `3.14`, `1.0e-5` |
| `STRING` | Text string | `'Hello'` |
| `SET` | Bit set for ordinal ranges | `{1, 2, 3}` |
| `POINTER` | Untyped pointer | `NIL` |

### Format Strings

Use `{}` as placeholder in PrintLn:

```myra
var
  X: INTEGER;
  Y: INTEGER;
begin
  X := 10;
  Y := 20;
  Console.PrintLn('X = {}, Y = {}', X, Y);
  Console.PrintLn('Sum = {}', X + Y);
end.
```

Output:
```
X = 10, Y = 20
Sum = 30
```

## 3. Control Flow

### If Statement

```myra
module exe IfDemo;

import Console;

var
  X: INTEGER;

begin
  X := 15;
  
  if X > 10 then
    Console.PrintLn('X is greater than 10');
  end;
  
  if X > 20 then
    Console.PrintLn('Large');
  else
    Console.PrintLn('Not so large');
  end;
  
  if X > 100 then
    Console.PrintLn('Huge');
  else if X > 50 then
    Console.PrintLn('Big');
  else if X > 10 then
    Console.PrintLn('Medium');
  else
    Console.PrintLn('Small');
  end;
end.
```

### While Loop

```myra
module exe WhileDemo;

import Console;

var
  Count: INTEGER;

begin
  Count := 5;
  
  while Count > 0 do
    Console.PrintLn('Count = {}', Count);
    Count := Count - 1;
  end;
  
  Console.PrintLn('Done!');
end.
```

### For Loop

```myra
module exe ForDemo;

import Console;

var
  I: INTEGER;
  Sum: INTEGER;

begin
  // Count up
  Console.PrintLn('Counting up:');
  for I := 1 to 5 do
    Console.PrintLn('  I = {}', I);
  end;
  
  // Count down
  Console.PrintLn('Countdown:');
  for I := 5 downto 1 do
    Console.PrintLn('  {}...', I);
  end;
  Console.PrintLn('  Liftoff!');
  
  // Sum 1 to 10
  Sum := 0;
  for I := 1 to 10 do
    Sum := Sum + I;
  end;
  Console.PrintLn('Sum 1..10 = {}', Sum);
end.
```

### Repeat Loop

```myra
module exe RepeatDemo;

import Console;

var
  N: INTEGER;

begin
  N := 1;
  
  repeat
    Console.PrintLn('N = {}', N);
    N := N * 2;
  until N > 100;
  
  Console.PrintLn('Final N = {}', N);
end.
```

### Case Statement

```myra
module exe CaseDemo;

import Console;

var
  Day: INTEGER;
  Result: STRING;

begin
  Day := 3;
  
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
  
  Console.PrintLn('Day {} is {}', Day, Result);
end.
```

## 4. Routines

### Basic Routines

```myra
module exe RoutineDemo;

import Console;

// Routine with no parameters, no return
routine SayHello();
begin
  Console.PrintLn('Hello!');
end;

// Routine with parameters
routine Greet(const AName: STRING);
begin
  Console.PrintLn('Hello, {}!', AName);
end;

// Routine with return value
routine Add(const A: INTEGER; const B: INTEGER): INTEGER;
begin
  return A + B;
end;

// Routine with local variables
routine Factorial(const N: INTEGER): INTEGER;
var
  I: INTEGER;
  Result: INTEGER;
begin
  Result := 1;
  for I := 2 to N do
    Result := Result * I;
  end;
  return Result;
end;

begin
  SayHello();
  Greet('World');
  Console.PrintLn('5 + 3 = {}', Add(5, 3));
  Console.PrintLn('5! = {}', Factorial(5));
end.
```

### Parameter Passing

```myra
module exe ParamDemo;

import Console;

// const - pass by value (cannot modify)
routine ShowValue(const AValue: INTEGER);
begin
  Console.PrintLn('Value is {}', AValue);
end;

// var - pass by reference (can modify)
routine DoubleIt(var AValue: INTEGER);
begin
  AValue := AValue * 2;
end;

// Swap example
routine Swap(var A: INTEGER; var B: INTEGER);
var
  Temp: INTEGER;
begin
  Temp := A;
  A := B;
  B := Temp;
end;

var
  X: INTEGER;
  Y: INTEGER;

begin
  X := 10;
  ShowValue(X);
  
  DoubleIt(X);
  Console.PrintLn('After DoubleIt: X = {}', X);
  
  X := 5;
  Y := 10;
  Console.PrintLn('Before swap: X={}, Y={}', X, Y);
  Swap(X, Y);
  Console.PrintLn('After swap: X={}, Y={}', X, Y);
end.
```

## 5. Records

Records group related data together.

```myra
module exe RecordDemo;

import Console;

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

var
  Point: TPoint;
  Person: TPerson;

begin
  // Assign fields
  Point.X := 100;
  Point.Y := 200;
  Console.PrintLn('Point: ({}, {})', Point.X, Point.Y);
  
  Person.Name := 'Alice';
  Person.Age := 30;
  Person.Active := TRUE;
  Console.PrintLn('Person: {} (age {})', Person.Name, Person.Age);
end.
```

### Records with Routines

```myra
module exe RecordRoutines;

import Console;

type
  TPoint = record
    X: INTEGER;
    Y: INTEGER;
  end;

routine InitPoint(var APoint: TPoint; const AX: INTEGER; const AY: INTEGER);
begin
  APoint.X := AX;
  APoint.Y := AY;
end;

routine PrintPoint(const APoint: TPoint);
begin
  Console.PrintLn('({}, {})', APoint.X, APoint.Y);
end;

routine MovePoint(var APoint: TPoint; const ADX: INTEGER; const ADY: INTEGER);
begin
  APoint.X := APoint.X + ADX;
  APoint.Y := APoint.Y + ADY;
end;

var
  P: TPoint;

begin
  InitPoint(P, 10, 20);
  Console.PrintLn('Initial:');
  PrintPoint(P);
  
  MovePoint(P, 5, 10);
  Console.PrintLn('After move:');
  PrintPoint(P);
end.
```

## 6. Arrays

### Static Arrays

```myra
module exe StaticArrayDemo;

import Console;

var
  Numbers: ARRAY[0..4] OF INTEGER;
  I: INTEGER;

begin
  // Initialize
  for I := 0 to 4 do
    Numbers[I] := I * 10;
  end;
  
  // Print
  Console.PrintLn('Array contents:');
  for I := 0 to 4 do
    Console.PrintLn('  [{}] = {}', I, Numbers[I]);
  end;
end.
```

### Dynamic Arrays

```myra
module exe DynamicArrayDemo;

import Console;

var
  Data: ARRAY OF INTEGER;
  Names: ARRAY OF STRING;
  I: INTEGER;

begin
  // Create and fill integer array
  SetLength(Data, 5);
  Console.PrintLn('Data length: {}', Len(Data));
  
  for I := 0 to Len(Data) - 1 do
    Data[I] := I * 10;
  end;
  
  Console.PrintLn('Data contents:');
  for I := 0 to Len(Data) - 1 do
    Console.PrintLn('  [{}] = {}', I, Data[I]);
  end;
  
  // String array
  SetLength(Names, 3);
  Names[0] := 'Alice';
  Names[1] := 'Bob';
  Names[2] := 'Charlie';
  
  Console.PrintLn('Names:');
  for I := 0 to Len(Names) - 1 do
    Console.PrintLn('  {}', Names[I]);
  end;
  
  // Resize
  SetLength(Data, 10);
  Console.PrintLn('After resize: {}', Len(Data));
end.
```

### Open Array Parameters

```myra
module exe OpenArrayDemo;

import Console;

routine PrintAll(const AValues: ARRAY OF INTEGER);
var
  I: INTEGER;
begin
  for I := 0 to Len(AValues) - 1 do
    Console.PrintLn('  [{}] = {}', I, AValues[I]);
  end;
end;

routine Sum(const AValues: ARRAY OF INTEGER): INTEGER;
var
  I: INTEGER;
  Total: INTEGER;
begin
  Total := 0;
  for I := 0 to Len(AValues) - 1 do
    Total := Total + AValues[I];
  end;
  return Total;
end;

var
  Numbers: ARRAY OF INTEGER;

begin
  SetLength(Numbers, 5);
  Numbers[0] := 10;
  Numbers[1] := 20;
  Numbers[2] := 30;
  Numbers[3] := 40;
  Numbers[4] := 50;
  
  Console.PrintLn('Array:');
  PrintAll(Numbers);
  Console.PrintLn('Sum = {}', Sum(Numbers));
end.
```

## 7. Pointers

### Basic Pointer Usage

```myra
module exe PointerDemo;

import Console;

type
  PInteger = POINTER TO INTEGER;

var
  P: PInteger;

begin
  // Allocate
  NEW(P);
  Console.PrintLn('Allocated pointer');
  
  // Use (explicit dereference for values)
  P^ := 42;
  Console.PrintLn('Value: {}', P^);
  
  // Deallocate
  DISPOSE(P);
  Console.PrintLn('Disposed pointer');
end.
```

### Pointers to Records

```myra
module exe RecordPointerDemo;

import Console;

type
  TData = record
    Value: INTEGER;
    Name: STRING;
  end;

  PData = POINTER TO TData;

var
  P: PData;

begin
  NEW(P);
  
  // Field access auto-dereferences
  P.Value := 100;
  P.Name := 'Test';
  
  Console.PrintLn('Value: {}', P.Value);
  Console.PrintLn('Name: {}', P.Name);
  
  DISPOSE(P);
end.
```

### NIL Pointers

```myra
module exe NilDemo;

import Console;

type
  PInteger = POINTER TO INTEGER;

var
  P: PInteger;

begin
  P := NIL;
  
  if P = NIL then
    Console.PrintLn('Pointer is NIL');
  end;
  
  NEW(P);
  
  if P <> NIL then
    Console.PrintLn('Pointer is valid');
    P^ := 42;
  end;
  
  DISPOSE(P);
  P := NIL;
end.
```

## 8. Modules

### Creating a Library Module

File: `MathLib.myra`
```myra
module lib MathLib;

public const
  PI = 3.14159;

public routine Square(const X: INTEGER): INTEGER;
begin
  return X * X;
end;

public routine Cube(const X: INTEGER): INTEGER;
begin
  return X * X * X;
end;

public routine CircleArea(const Radius: FLOAT): FLOAT;
begin
  return PI * Radius * Radius;
end;

end.
```

### Using a Library

File: `UseLib.myra`
```myra
module exe UseLib;

import
  Console,
  MathLib;

begin
  Console.PrintLn('PI = {}', MathLib.PI);
  Console.PrintLn('5 squared = {}', MathLib.Square(5));
  Console.PrintLn('3 cubed = {}', MathLib.Cube(3));
  Console.PrintLn('Circle area (r=2): {}', MathLib.CircleArea(2.0));
end.
```

### Module Qualification

All imported symbols require full module qualification:

```myra
import
  Console,
  MathLib;

begin
  Console.PrintLn('{}', MathLib.Square(5));
end.
```

## 9. Type Extension

Records can extend other records, inheriting their fields.

```myra
module exe ExtensionDemo;

import Console;

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

var
  Circle: TCircle;
  Rect: TRect;

begin
  // TCircle has X, Y from TShape plus Radius
  Circle.X := 100;
  Circle.Y := 100;
  Circle.Radius := 50;
  Console.PrintLn('Circle at ({}, {}), radius {}', Circle.X, Circle.Y, Circle.Radius);
  
  // TRect has X, Y from TShape plus Width, Height
  Rect.X := 0;
  Rect.Y := 0;
  Rect.Width := 200;
  Rect.Height := 100;
  Console.PrintLn('Rect at ({}, {}), size {}x{}', Rect.X, Rect.Y, Rect.Width, Rect.Height);
end.
```

### Type Testing with IS

```myra
module exe IsDemo;

import Console;

type
  TShape = record
    X: INTEGER;
    Y: INTEGER;
  end;

  TCircle = record(TShape)
    Radius: INTEGER;
  end;

  PShape = POINTER TO TShape;

var
  Shape: PShape;

begin
  NEW(Shape AS TCircle);
  
  if Shape IS TCircle then
    Console.PrintLn('Shape is a TCircle');
  else
    Console.PrintLn('Shape is not a TCircle');
  end;
  
  DISPOSE(Shape);
end.
```

### Type Casting with AS

```myra
var
  Shape: PShape;
  Circle: TCircle;
begin
  NEW(Shape AS TCircle);
  
  if Shape IS TCircle then
    Circle := Shape AS TCircle;
    Circle.Radius := 50;
    Console.PrintLn('Radius: {}', Circle.Radius);
  end;
  
  DISPOSE(Shape);
end.
```

## 10. Methods

Methods are routines bound to a type using the `method` keyword.

```myra
module exe MethodDemo;

import Console;

type
  TCounter = record
    Value: INTEGER;
    Name: STRING;
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

var
  Counter: TCounter;

begin
  Counter.Name := 'MyCounter';
  Counter.Reset();
  
  Console.PrintLn('After Reset: {}', Counter.GetValue());
  
  Counter.Increment();
  Counter.Increment();
  Console.PrintLn('After 2 increments: {}', Counter.GetValue());
  
  Counter.Add(10);
  Console.PrintLn('After Add(10): {}', Counter.GetValue());
end.
```

### Method Overriding and Inherited

```myra
module exe InheritedDemo;

import Console;

type
  TShape = record
    Name: STRING;
    X: INTEGER;
    Y: INTEGER;
  end;

  TCircle = record(TShape)
    Radius: INTEGER;
  end;

method Describe(var Self: TShape);
begin
  Console.PrintLn('Shape "{}" at ({}, {})', Self.Name, Self.X, Self.Y);
end;

method Describe(var Self: TCircle);
begin
  inherited Describe();
  Console.PrintLn('  Radius: {}', Self.Radius);
end;

var
  Circle: TCircle;

begin
  Circle.Name := 'MyCircle';
  Circle.X := 100;
  Circle.Y := 100;
  Circle.Radius := 50;
  
  Circle.Describe();
end.
```

Output:
```
Shape "MyCircle" at (100, 100)
  Radius: 50
```

## 11. Exception Handling

### Try/Except

```myra
module exe ExceptDemo;

import
  Console,
  System;

routine MayFail(const AValue: INTEGER);
begin
  if AValue < 0 then
    System.RaiseException('Value cannot be negative');
  end;
  Console.PrintLn('Value is {}', AValue);
end;

begin
  Console.PrintLn('Testing try/except:');
  
  try
    MayFail(10);
    MayFail(-5);
    Console.PrintLn('This will not print');
  except
    Console.PrintLn('Caught: {}', System.GetExceptionMessage());
  end;
  
  Console.PrintLn('Continuing after exception');
end.
```

### Try/Finally

```myra
module exe FinallyDemo;

import Console;

var
  ResourceOpen: BOOLEAN;

routine OpenResource();
begin
  Console.PrintLn('Opening resource');
  ResourceOpen := TRUE;
end;

routine CloseResource();
begin
  Console.PrintLn('Closing resource');
  ResourceOpen := FALSE;
end;

routine UseResource();
begin
  Console.PrintLn('Using resource');
end;

begin
  ResourceOpen := FALSE;
  
  try
    OpenResource();
    UseResource();
  finally
    CloseResource();
  end;
  
  Console.PrintLn('Resource open: {}', ResourceOpen);
end.
```

### Try/Except/Finally

```myra
module exe FullTryDemo;

import
  Console,
  System;

begin
  try
    Console.PrintLn('Trying...');
    System.RaiseException('Something went wrong');
  except
    Console.PrintLn('Caught: {}', System.GetExceptionMessage());
  finally
    Console.PrintLn('Cleanup always runs');
  end;
  
  Console.PrintLn('Done');
end.
```

## 12. C++ Integration

Myra's killer feature: mix C++ freely with Myra code.

### C++ Blocks

```myra
module exe CppBlockDemo;

import Console;

#startcpp header
inline int CppAdd(int a, int b) {
    return a + b;
}

inline int CppSquare(int x) {
    return x * x;
}
#endcpp

begin
  Console.PrintLn('CppAdd(10, 20) = {}', CppAdd(10, 20));
  Console.PrintLn('CppSquare(7) = {}', CppSquare(7));
end.
```

### C++ Passthrough

C++ code can appear inline:

```myra
module exe CppPassthrough;

import Console;

const
  constexpr int32_t MAX_VALUE = 1000;

var
  flags: uint32_t;

begin
  int32_t localVar = 42;
  Console.PrintLn('C++ local: {}', localVar);
  
  flags = 0x0001 | 0x0002;
  Console.PrintLn('Flags: {}', flags);
end.
```

### Including C++ Headers

```myra
module exe CppHeaders;

import Console;

#include_header '<cmath>'

begin
  Console.PrintLn('sqrt(16) = {}', std::sqrt(16.0));
  Console.PrintLn('pow(2, 10) = {}', std::pow(2.0, 10.0));
end.
```

### Calling System APIs

```myra
module exe SystemAPI;

import Console;

#startcpp header
#ifdef _WIN32
#include <windows.h>
#endif
#endcpp

begin
  #ifdef _WIN32
  DWORD tickCount = GetTickCount();
  Console.PrintLn('Tick count: {}', tickCount);
  #endif
end.
```

## What's Next?

You've learned the core of Myra. Continue with:

- [Language Reference](LANGUAGE_REFERENCE.md) — Complete specification
- [Standard Library](STANDARD_LIBRARY.md) — Console, System, Assertions
- [Build System](BUILD_SYSTEM.md) — Compilation, debugging, and optimization
- [Examples](EXAMPLES.md) — Real-world code samples
- [C++ Interop Guide](CPP_INTEROP.md) — Advanced C++ integration

### Debugging Your Code

Myra includes an integrated debugger. To debug a program:

```bash
myra debug
```

This launches an interactive debugger with commands like `b` (breakpoint), `c` (continue), `n` (step over), `s` (step into), `bt` (backtrace), and `locals`. See the [Build System](BUILD_SYSTEM.md) guide for details.

*Myra™ — Pascal. Refined.*
