# Myra Standard Library

Documentation for the built-in modules.

## Table of Contents

1. [Console](#console)
2. [System](#system)
3. [Assertions](#assertions)
4. [UnitTest](#unittest)

## Console

The Console module provides formatted output and ANSI terminal control.

```myra
import Console;
```

### Output Routines

#### Print

Prints formatted text without newline.

```myra
Console.Print('Hello');
Console.Print('Value: {}', X);
Console.Print('{} + {} = {}', A, B, A + B);
```

#### PrintLn

Prints formatted text with newline.

```myra
Console.PrintLn('Hello, World!');
Console.PrintLn('X = {}', X);
Console.PrintLn('Name: {}, Age: {}', Name, Age);
```

Empty call prints blank line:
```myra
Console.PrintLn();
```

### Format Placeholders

Use `{}` as placeholder for values:

```myra
var
  Name: STRING;
  Age: INTEGER;
  Score: FLOAT;
begin
  Name := 'Alice';
  Age := 25;
  Score := 95.5;
  
  Console.PrintLn('Name: {}', Name);
  Console.PrintLn('Age: {}', Age);
  Console.PrintLn('Score: {}', Score);
  Console.PrintLn('{} is {} years old with score {}', Name, Age, Score);
end.
```

### Color Constants

#### Text Colors

| Constant | Description |
|----------|-------------|
| `clBlack` | Black text |
| `clRed` | Red text |
| `clGreen` | Green text |
| `clYellow` | Yellow text |
| `clBlue` | Blue text |
| `clMagenta` | Magenta text |
| `clCyan` | Cyan text |
| `clWhite` | White text |

#### Bright Text Colors

| Constant | Description |
|----------|-------------|
| `clBrightBlack` | Bright black (gray) |
| `clBrightRed` | Bright red |
| `clBrightGreen` | Bright green |
| `clBrightYellow` | Bright yellow |
| `clBrightBlue` | Bright blue |
| `clBrightMagenta` | Bright magenta |
| `clBrightCyan` | Bright cyan |
| `clBrightWhite` | Bright white |

#### Background Colors

| Constant | Description |
|----------|-------------|
| `clBgBlack` | Black background |
| `clBgRed` | Red background |
| `clBgGreen` | Green background |
| `clBgYellow` | Yellow background |
| `clBgBlue` | Blue background |
| `clBgMagenta` | Magenta background |
| `clBgCyan` | Cyan background |
| `clBgWhite` | White background |

#### Style Constants

| Constant | Description |
|----------|-------------|
| `clReset` | Reset all formatting |
| `clBold` | Bold text |

### Using Colors

```myra
import Console;

begin
  Console.Print(Console.clRed);
  Console.PrintLn('This is red');
  
  Console.Print(Console.clGreen);
  Console.Print(Console.clBold);
  Console.PrintLn('Bold green');
  
  Console.Print(Console.clBgBlue);
  Console.Print(Console.clWhite);
  Console.PrintLn('White on blue');
  
  Console.ResetColors();
  Console.PrintLn('Back to normal');
end.
```

### Terminal Control

#### ResetColors

Resets text formatting to default.

```myra
Console.ResetColors();
```

#### ClearScreen

Clears the entire screen.

```myra
Console.ClearScreen();
```

#### ClearLine

Clears the current line.

```myra
Console.ClearLine();
```

#### HideCursor

Hides the terminal cursor.

```myra
Console.HideCursor();
```

#### ShowCursor

Shows the terminal cursor.

```myra
Console.ShowCursor();
```

### Escape Sequence Constants

| Constant | Description |
|----------|-------------|
| `escClearScreen` | Clear screen sequence |
| `escClearLine` | Clear line sequence |
| `escHideCursor` | Hide cursor sequence |
| `escShowCursor` | Show cursor sequence |

## System

The System module provides program control, exception handling, and memory operations.

```myra
import System;
```

### Program Control

#### Halt

Terminates the program with an exit code.

```myra
System.Halt(0);    // exit with code 0
System.Halt(1);    // exit with code 1
System.Halt();     // exit with code 0
```

### Exception Handling

#### RaiseException

Raises an exception with a message.

```myra
System.RaiseException('Something went wrong');
```

#### GetExceptionMessage

Returns the message from the current exception. Use inside an `except` block.

```myra
try
  DoSomething();
except
  Console.PrintLn('Error: {}', System.GetExceptionMessage());
end;
```

### Memory Operations

#### Move

Copies bytes from source to destination.

```myra
System.Move(source, destination, byteCount);
```

#### Zero

Fills memory with zeros.

```myra
System.Zero(destination, byteCount);
```

### Complete Example

```myra
module exe SystemDemo;

import
  Console,
  System;

routine Divide(const A: INTEGER; const B: INTEGER): INTEGER;
begin
  if B = 0 then
    System.RaiseException('Division by zero');
  end;
  return A div B;
end;

begin
  try
    Console.PrintLn('10 / 2 = {}', Divide(10, 2));
    Console.PrintLn('10 / 0 = {}', Divide(10, 0));
  except
    Console.PrintLn('Caught: {}', System.GetExceptionMessage());
  end;
  
  Console.PrintLn('Exiting...');
  System.Halt(0);
end.
```

## Assertions

The Assertions module provides runtime assertion checking for non-test code.

```myra
import Assertions;
```

**Note:** This module cannot be used during unit testing. Use UnitTest assertions instead.

### Basic Assertions

#### Assert

Fails if condition is false.

```myra
Assertions.Assert(X > 0, 'X must be positive');
```

#### AssertTrue

Explicitly asserts condition is true.

```myra
Assertions.AssertTrue(IsValid, 'Must be valid');
```

#### AssertFalse

Asserts condition is false.

```myra
Assertions.AssertFalse(HasError, 'Must not have error');
```

### Equality Assertions

#### AssertEqual

Asserts two values are equal (pass as boolean expression).

```myra
Assertions.AssertEqual(Result = 42, 'Result should be 42');
```

#### AssertNotEqual

Asserts two values are not equal.

```myra
Assertions.AssertNotEqual(A <> B, 'A and B must differ');
```

### Pointer Assertions

#### AssertNil

Asserts pointer is NIL.

```myra
Assertions.AssertNil(P, 'Pointer should be NIL');
```

#### AssertNotNil

Asserts pointer is not NIL.

```myra
Assertions.AssertNotNil(P, 'Pointer should not be NIL');
```

### Range Assertion

#### AssertInRange

Asserts value is within range [low, high].

```myra
Assertions.AssertInRange(Index, 0, 99, 'Index out of bounds');
```

### Result Markers

#### Pass

Marks a test as passed with a message.

```myra
Assertions.Pass('All checks passed');
```

#### Fail

Unconditionally fails with a message.

```myra
Assertions.Fail('This should not happen');
```

### Complete Example

```myra
module exe AssertDemo;

import
  Console,
  Assertions;

routine ValidateInput(const AValue: INTEGER);
begin
  Assertions.Assert(AValue >= 0, 'Value must be non-negative');
  Assertions.AssertInRange(AValue, 0, 100, 'Value must be 0-100');
end;

begin
  Console.PrintLn('Testing assertions...');
  
  ValidateInput(50);
  Assertions.Pass('ValidateInput(50) passed');
  
  ValidateInput(0);
  Assertions.Pass('ValidateInput(0) passed');
  
  ValidateInput(100);
  Assertions.Pass('ValidateInput(100) passed');
  
  Console.PrintLn('All assertions passed!');
end.
```

## UnitTest

The UnitTest module provides a unit testing framework with TEST blocks.

```myra
import UnitTest;
```

**Note:** Requires `#unittestmode ON` directive.

### Writing Tests

Tests are written as TEST blocks after the main program:

```myra
#unittestmode ON

module exe MyTests;

import UnitTest;

routine Add(const A: INTEGER; const B: INTEGER): INTEGER;
begin
  return A + B;
end;

begin
  // Empty main - tests run automatically
end.

test 'Add returns correct sum';
begin
  TestAssertEqual(5, Add(2, 3));
end;

test 'Add handles zero';
begin
  TestAssertEqual(0, Add(0, 0));
  TestAssertEqual(5, Add(5, 0));
  TestAssertEqual(5, Add(0, 5));
end;

test 'Add handles negatives';
begin
  TestAssertEqual(-5, Add(-2, -3));
  TestAssertEqual(1, Add(-2, 3));
end;
```

### Test Assertions

#### TestAssert

Fails if condition is false.

```myra
TestAssert(X > 0);
```

#### TestAssertTrue

Asserts condition is true.

```myra
TestAssertTrue(IsValid);
```

#### TestAssertFalse

Asserts condition is false.

```myra
TestAssertFalse(HasError);
```

#### TestAssertEqual

Asserts expected equals actual.

```myra
TestAssertEqual(42, Result);
TestAssertEqual('hello', Name);
```

#### TestAssertNotEqual

Asserts values are not equal.

```myra
TestAssertNotEqual(0, Count);
```

#### TestAssertNil

Asserts pointer is NIL.

```myra
TestAssertNil(P);
```

#### TestAssertNotNil

Asserts pointer is not NIL.

```myra
TestAssertNotNil(P);
```

#### TestFail

Unconditionally fails with message.

```myra
TestFail('Not implemented');
```

### Test Structure

```myra
test 'Test name here';
var
  LValue: INTEGER;  // local variables allowed
begin
  // test code
  LValue := ComputeSomething();
  TestAssertEqual(42, LValue);
end;
```

### Complete Example

```myra
#unittestmode ON

module exe CalculatorTests;

import UnitTest;

type
  TCalculator = record
    Value: INTEGER;
  end;

method Reset(var Self: TCalculator);
begin
  Self.Value := 0;
end;

method Add(var Self: TCalculator; const AAmount: INTEGER);
begin
  Self.Value := Self.Value + AAmount;
end;

method Subtract(var Self: TCalculator; const AAmount: INTEGER);
begin
  Self.Value := Self.Value - AAmount;
end;

method GetValue(var Self: TCalculator): INTEGER;
begin
  return Self.Value;
end;

begin
end.

test 'Reset sets value to zero';
var
  Calc: TCalculator;
begin
  Calc.Value := 100;
  Calc.Reset();
  TestAssertEqual(0, Calc.GetValue());
end;

test 'Add increases value';
var
  Calc: TCalculator;
begin
  Calc.Reset();
  Calc.Add(10);
  TestAssertEqual(10, Calc.GetValue());
  Calc.Add(5);
  TestAssertEqual(15, Calc.GetValue());
end;

test 'Subtract decreases value';
var
  Calc: TCalculator;
begin
  Calc.Reset();
  Calc.Add(20);
  Calc.Subtract(8);
  TestAssertEqual(12, Calc.GetValue());
end;

test 'Negative values work';
var
  Calc: TCalculator;
begin
  Calc.Reset();
  Calc.Subtract(5);
  TestAssertEqual(-5, Calc.GetValue());
end;
```

### Test Output

When tests run, output looks like:

```
╔══════════════════════════════════════════════════════════════╗
║                 Myra Unit Test Runner                        ║
╚══════════════════════════════════════════════════════════════╝

Running 4 test(s)...

✅ PASS: Reset sets value to zero
✅ PASS: Add increases value
✅ PASS: Subtract decreases value
✅ PASS: Negative values work

══════════════════════════════════════════════════════════════════
Results: 4 passed, 0 failed, 4 total
══════════════════════════════════════════════════════════════════
```

*Myra™ — Pascal. Refined.*
