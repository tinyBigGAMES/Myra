# Myra Examples

Real-world code samples to learn from and adapt.

## Table of Contents

1. [Basic Examples](#basic-examples)
2. [Data Structures](#data-structures)
3. [Algorithms](#algorithms)
4. [Patterns](#patterns)
5. [C++ Integration](#c-integration)

## Basic Examples

### Hello World

```myra
module exe HelloWorld;

import Console;

begin
  Console.PrintLn('Hello from Myra!');
end.
```

### Variables and Output

```myra
module exe Variables;

import Console;

var
  Name: STRING;
  Age: INTEGER;
  Score: FLOAT;
  Active: BOOLEAN;

begin
  Name := 'Alice';
  Age := 25;
  Score := 95.5;
  Active := TRUE;
  
  Console.PrintLn('Name: {}', Name);
  Console.PrintLn('Age: {}', Age);
  Console.PrintLn('Score: {}', Score);
  Console.PrintLn('Active: {}', Active);
end.
```

### Console Colors

```myra
module exe Colors;

import Console;

begin
  Console.Print(Console.clRed);
  Console.PrintLn('This is red');
  
  Console.Print(Console.clGreen);
  Console.PrintLn('This is green');
  
  Console.Print(Console.clBlue);
  Console.PrintLn('This is blue');
  
  Console.Print(Console.clBold);
  Console.Print(Console.clYellow);
  Console.PrintLn('Bold yellow');
  
  Console.ResetColors();
  Console.PrintLn('Back to normal');
end.
```

### Sum and Factorial

```myra
module exe MathBasics;

import Console;

var
  I: INTEGER;
  Sum: INTEGER;
  Factorial: INTEGER;

begin
  // Sum 1 to 10
  Sum := 0;
  for I := 1 to 10 do
    Sum := Sum + I;
  end;
  Console.PrintLn('Sum 1..10 = {}', Sum);
  
  // Factorial of 5
  Factorial := 1;
  for I := 5 downto 1 do
    Factorial := Factorial * I;
  end;
  Console.PrintLn('5! = {}', Factorial);
end.
```

## Data Structures

### Dynamic List

```myra
module exe DynamicList;

import Console;

var
  Items: ARRAY OF INTEGER;
  I: INTEGER;

routine Add(var AList: ARRAY OF INTEGER; const AValue: INTEGER);
var
  LLen: INTEGER;
begin
  LLen := Len(AList);
  SetLength(AList, LLen + 1);
  AList[LLen] := AValue;
end;

routine PrintList(const AList: ARRAY OF INTEGER);
var
  I: INTEGER;
begin
  Console.Print('[');
  for I := 0 to Len(AList) - 1 do
    if I > 0 then
      Console.Print(', ');
    end;
    Console.Print('{}', AList[I]);
  end;
  Console.PrintLn(']');
end;

begin
  SetLength(Items, 0);
  
  Add(Items, 10);
  Add(Items, 20);
  Add(Items, 30);
  Add(Items, 40);
  Add(Items, 50);
  
  Console.PrintLn('List contents:');
  PrintList(Items);
  Console.PrintLn('Length: {}', Len(Items));
end.
```

### Stack

```myra
module exe Stack;

import Console;

type
  TStack = record
    Data: ARRAY OF INTEGER;
    Top: INTEGER;
  end;

method Init(var Self: TStack; const ACapacity: INTEGER);
begin
  SetLength(Self.Data, ACapacity);
  Self.Top := -1;
end;

method Push(var Self: TStack; const AValue: INTEGER);
begin
  Self.Top := Self.Top + 1;
  Self.Data[Self.Top] := AValue;
end;

method Pop(var Self: TStack): INTEGER;
begin
  return Self.Data[Self.Top];
  Self.Top := Self.Top - 1;
end;

method Peek(var Self: TStack): INTEGER;
begin
  return Self.Data[Self.Top];
end;

method IsEmpty(var Self: TStack): BOOLEAN;
begin
  return Self.Top < 0;
end;

var
  Stack: TStack;

begin
  Stack.Init(10);
  
  Stack.Push(10);
  Stack.Push(20);
  Stack.Push(30);
  
  Console.PrintLn('Top: {}', Stack.Peek());
  
  while not Stack.IsEmpty() do
    Console.PrintLn('Pop: {}', Stack.Pop());
  end;
end.
```

### Linked List

```myra
module exe LinkedList;

import Console;

type
  PNode = POINTER TO TNode;
  
  TNode = record
    Value: INTEGER;
    Next: PNode;
  end;

var
  Head: PNode;
  Current: PNode;
  Temp: PNode;

routine AddNode(var AHead: PNode; const AValue: INTEGER);
var
  LNew: PNode;
  LCurrent: PNode;
begin
  NEW(LNew);
  LNew.Value := AValue;
  LNew.Next := NIL;
  
  if AHead = NIL then
    AHead := LNew;
  else
    LCurrent := AHead;
    while LCurrent.Next <> NIL do
      LCurrent := LCurrent.Next;
    end;
    LCurrent.Next := LNew;
  end;
end;

routine PrintList(const AHead: PNode);
var
  LCurrent: PNode;
begin
  LCurrent := AHead;
  while LCurrent <> NIL do
    Console.PrintLn('  Value: {}', LCurrent.Value);
    LCurrent := LCurrent.Next;
  end;
end;

routine FreeList(var AHead: PNode);
var
  LCurrent: PNode;
  LNext: PNode;
begin
  LCurrent := AHead;
  while LCurrent <> NIL do
    LNext := LCurrent.Next;
    DISPOSE(LCurrent);
    LCurrent := LNext;
  end;
  AHead := NIL;
end;

begin
  Head := NIL;
  
  AddNode(Head, 10);
  AddNode(Head, 20);
  AddNode(Head, 30);
  AddNode(Head, 40);
  
  Console.PrintLn('Linked list:');
  PrintList(Head);
  
  FreeList(Head);
  Console.PrintLn('List freed');
end.
```

## Algorithms

### Bubble Sort

```myra
module exe BubbleSort;

import Console;

var
  Data: ARRAY OF INTEGER;
  I: INTEGER;

routine Sort(var AData: ARRAY OF INTEGER);
var
  I: INTEGER;
  J: INTEGER;
  Temp: INTEGER;
  Swapped: BOOLEAN;
begin
  repeat
    Swapped := FALSE;
    for I := 0 to Len(AData) - 2 do
      if AData[I] > AData[I + 1] then
        Temp := AData[I];
        AData[I] := AData[I + 1];
        AData[I + 1] := Temp;
        Swapped := TRUE;
      end;
    end;
  until not Swapped;
end;

routine PrintArray(const AData: ARRAY OF INTEGER);
var
  I: INTEGER;
begin
  for I := 0 to Len(AData) - 1 do
    Console.Print('{} ', AData[I]);
  end;
  Console.PrintLn('');
end;

begin
  SetLength(Data, 8);
  Data[0] := 64;
  Data[1] := 34;
  Data[2] := 25;
  Data[3] := 12;
  Data[4] := 22;
  Data[5] := 11;
  Data[6] := 90;
  Data[7] := 42;
  
  Console.PrintLn('Before sort:');
  PrintArray(Data);
  
  Sort(Data);
  
  Console.PrintLn('After sort:');
  PrintArray(Data);
end.
```

### Binary Search

```myra
module exe BinarySearch;

import Console;

routine Search(const AData: ARRAY OF INTEGER; const AValue: INTEGER): INTEGER;
var
  Low: INTEGER;
  High: INTEGER;
  Mid: INTEGER;
begin
  Low := 0;
  High := Len(AData) - 1;
  
  while Low <= High do
    Mid := (Low + High) div 2;
    
    if AData[Mid] = AValue then
      return Mid;
    else if AData[Mid] < AValue then
      Low := Mid + 1;
    else
      High := Mid - 1;
    end;
  end;
  
  return -1;
end;

var
  Data: ARRAY OF INTEGER;
  Index: INTEGER;

begin
  SetLength(Data, 10);
  Data[0] := 10;
  Data[1] := 20;
  Data[2] := 30;
  Data[3] := 40;
  Data[4] := 50;
  Data[5] := 60;
  Data[6] := 70;
  Data[7] := 80;
  Data[8] := 90;
  Data[9] := 100;
  
  Index := Search(Data, 50);
  Console.PrintLn('Search for 50: index {}', Index);
  
  Index := Search(Data, 35);
  Console.PrintLn('Search for 35: index {}', Index);
  
  Index := Search(Data, 10);
  Console.PrintLn('Search for 10: index {}', Index);
  
  Index := Search(Data, 100);
  Console.PrintLn('Search for 100: index {}', Index);
end.
```

### Recursion (Fibonacci)

```myra
module exe Fibonacci;

import Console;

routine Fib(const N: INTEGER): INTEGER;
begin
  if N <= 1 then
    return N;
  else
    return Fib(N - 1) + Fib(N - 2);
  end;
end;

var
  I: INTEGER;

begin
  Console.PrintLn('Fibonacci sequence:');
  for I := 0 to 15 do
    Console.PrintLn('  Fib({}) = {}', I, Fib(I));
  end;
end.
```

## Patterns

### Polymorphic Shapes

```myra
module exe Shapes;

import Console;

const
  PI = 3.14159;

type
  TShape = record
    Name: STRING;
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

method Describe(var Self: TShape);
begin
  Console.PrintLn('Shape: {} at ({}, {})', Self.Name, Self.X, Self.Y);
end;

method Describe(var Self: TCircle);
begin
  inherited Describe();
  Console.PrintLn('  Circle, radius {}', Self.Radius);
end;

method Describe(var Self: TRect);
begin
  inherited Describe();
  Console.PrintLn('  Rectangle {}x{}', Self.Width, Self.Height);
end;

method GetArea(var Self: TCircle): FLOAT;
begin
  return PI * Self.Radius * Self.Radius;
end;

method GetArea(var Self: TRect): FLOAT;
begin
  return Self.Width * Self.Height;
end;

var
  Circle: TCircle;
  Rect: TRect;

begin
  Circle.Name := 'MyCircle';
  Circle.X := 100;
  Circle.Y := 100;
  Circle.Radius := 50;
  
  Rect.Name := 'MyRect';
  Rect.X := 0;
  Rect.Y := 0;
  Rect.Width := 200;
  Rect.Height := 100;
  
  Circle.Describe();
  Console.PrintLn('  Area: {}', Circle.GetArea());
  Console.PrintLn('');
  
  Rect.Describe();
  Console.PrintLn('  Area: {}', Rect.GetArea());
end.
```

### Callback Pattern

```myra
module exe Callbacks;

import Console;

type
  TCallback = routine(const AValue: INTEGER);
  TTransform = routine(const AValue: INTEGER): INTEGER;

routine ProcessArray(const AData: ARRAY OF INTEGER; const ACallback: TCallback);
var
  I: INTEGER;
begin
  for I := 0 to Len(AData) - 1 do
    ACallback(AData[I]);
  end;
end;

routine TransformArray(var AData: ARRAY OF INTEGER; const ATransform: TTransform);
var
  I: INTEGER;
begin
  for I := 0 to Len(AData) - 1 do
    AData[I] := ATransform(AData[I]);
  end;
end;

routine PrintValue(const AValue: INTEGER);
begin
  Console.PrintLn('  Value: {}', AValue);
end;

routine Double(const AValue: INTEGER): INTEGER;
begin
  return AValue * 2;
end;

routine Square(const AValue: INTEGER): INTEGER;
begin
  return AValue * AValue;
end;

var
  Data: ARRAY OF INTEGER;
  I: INTEGER;

begin
  SetLength(Data, 5);
  for I := 0 to 4 do
    Data[I] := I + 1;
  end;
  
  Console.PrintLn('Original:');
  ProcessArray(Data, PrintValue);
  
  TransformArray(Data, Double);
  Console.PrintLn('After Double:');
  ProcessArray(Data, PrintValue);
  
  TransformArray(Data, Square);
  Console.PrintLn('After Square:');
  ProcessArray(Data, PrintValue);
end.
```

### Sets for Flags

```myra
module exe SetFlags;

import Console;

type
  TPermission = SET OF 0..7;

const
  PermRead    = 0;
  PermWrite   = 1;
  PermExecute = 2;
  PermDelete  = 3;

var
  UserPerms: TPermission;
  AdminPerms: TPermission;

routine PrintPerms(const AName: STRING; const APerms: TPermission);
begin
  Console.PrintLn('{}:', AName);
  Console.PrintLn('  Read: {}', PermRead IN APerms);
  Console.PrintLn('  Write: {}', PermWrite IN APerms);
  Console.PrintLn('  Execute: {}', PermExecute IN APerms);
  Console.PrintLn('  Delete: {}', PermDelete IN APerms);
end;

begin
  UserPerms := {PermRead, PermExecute};
  AdminPerms := {PermRead, PermWrite, PermExecute, PermDelete};
  
  PrintPerms('User', UserPerms);
  Console.PrintLn('');
  PrintPerms('Admin', AdminPerms);
  
  Console.PrintLn('');
  Console.PrintLn('User has all admin perms: {}', (UserPerms * AdminPerms) = UserPerms);
  
  // Grant write permission
  UserPerms := UserPerms + {PermWrite};
  Console.PrintLn('');
  PrintPerms('User (after grant)', UserPerms);
end.
```

## C++ Integration

### Using C++ Math

```myra
module exe CppMath;

import Console;

#include_header '<cmath>'

begin
  Console.PrintLn('sqrt(16) = {}', std::sqrt(16.0));
  Console.PrintLn('pow(2, 10) = {}', std::pow(2.0, 10.0));
  Console.PrintLn('sin(0) = {}', std::sin(0.0));
  Console.PrintLn('cos(0) = {}', std::cos(0.0));
  Console.PrintLn('log(2.718) = {}', std::log(2.718));
  Console.PrintLn('floor(3.7) = {}', std::floor(3.7));
  Console.PrintLn('ceil(3.2) = {}', std::ceil(3.2));
end.
```

### C++ Helper Functions

```myra
module exe CppHelpers;

import Console;

#startcpp header
inline int Clamp(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
}

inline int Max(int a, int b) {
    return (a > b) ? a : b;
}

inline int Min(int a, int b) {
    return (a < b) ? a : b;
}
#endcpp

var
  X: INTEGER;

begin
  X := 150;
  Console.PrintLn('Clamp({}, 0, 100) = {}', X, Clamp(X, 0, 100));
  
  X := -50;
  Console.PrintLn('Clamp({}, 0, 100) = {}', X, Clamp(X, 0, 100));
  
  Console.PrintLn('Max(10, 20) = {}', Max(10, 20));
  Console.PrintLn('Min(10, 20) = {}', Min(10, 20));
end.
```

### Using std::vector

```myra
module exe StdVector;

import Console;

#include_header '<vector>'

#startcpp header
inline void VectorDemo() {
    std::vector<int> vec;
    
    vec.push_back(10);
    vec.push_back(20);
    vec.push_back(30);
    
    std::println("Vector size: {}", vec.size());
    
    for (size_t i = 0; i < vec.size(); i++) {
        std::println("  [{}] = {}", i, vec[i]);
    }
}
#endcpp

begin
  Console.PrintLn('std::vector demo:');
  VectorDemo();
end.
```

### Exception Handling

```myra
module exe ExceptionDemo;

import
  Console,
  System;

routine Divide(const A: INTEGER; const B: INTEGER): INTEGER;
begin
  if B = 0 then
    System.RaiseException('Division by zero!');
  end;
  return A div B;
end;

var
  Result: INTEGER;

begin
  Console.PrintLn('Exception handling demo:');
  
  try
    Result := Divide(10, 2);
    Console.PrintLn('10 / 2 = {}', Result);
    
    Result := Divide(10, 0);
    Console.PrintLn('This will not print');
  except
    Console.PrintLn('Caught: {}', System.GetExceptionMessage());
  finally
    Console.PrintLn('Cleanup complete');
  end;
  
  Console.PrintLn('Program continues');
end.
```

## Complete Application: Simple Calculator

```myra
module exe Calculator;

import
  Console,
  System;

routine Calculate(const A: FLOAT; const AOp: STRING; const B: FLOAT): FLOAT;
begin
  if AOp = '+' then
    return A + B;
  else if AOp = '-' then
    return A - B;
  else if AOp = '*' then
    return A * B;
  else if AOp = '/' then
    if B = 0.0 then
      System.RaiseException('Division by zero');
    end;
    return A / B;
  else
    System.RaiseException('Unknown operator: ' + AOp);
  end;
  return 0.0;
end;

var
  Result: FLOAT;

begin
  Console.PrintLn('=== Simple Calculator ===');
  Console.PrintLn('');
  
  try
    Result := Calculate(10.0, '+', 5.0);
    Console.PrintLn('10 + 5 = {}', Result);
    
    Result := Calculate(10.0, '-', 3.0);
    Console.PrintLn('10 - 3 = {}', Result);
    
    Result := Calculate(6.0, '*', 7.0);
    Console.PrintLn('6 * 7 = {}', Result);
    
    Result := Calculate(20.0, '/', 4.0);
    Console.PrintLn('20 / 4 = {}', Result);
    
    Console.PrintLn('');
    Console.PrintLn('Testing error handling:');
    Result := Calculate(10.0, '/', 0.0);
  except
    Console.PrintLn('Error: {}', System.GetExceptionMessage());
  end;
  
  Console.PrintLn('');
  Console.PrintLn('Calculator done');
end.
```

*Myra™ — Pascal. Refined.*
