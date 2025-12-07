# Myra Standard Library

Documentation for the built-in modules.

## Table of Contents

1. [Console](#console)
2. [System](#system)
3. [Assertions](#assertions)
4. [UnitTest](#unittest)
5. [Geometry](#geometry)
6. [Strings](#strings)
7. [Convert](#convert)
8. [Files](#files)
9. [Paths](#paths)
10. [Maths](#maths)
11. [DateTime](#datetime)

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

## Geometry

The Geometry module provides basic geometric types and utility functions for points, rectangles, and sizes.

```myra
import Geometry;
```

### Types

#### TPoint

A 2D point with integer coordinates.

```myra
type
  TPoint = record
    X: INTEGER;
    Y: INTEGER;
  end;
```

#### TRect

A rectangle defined by its edges.

```myra
type
  TRect = record
    Left: INTEGER;
    Top: INTEGER;
    Right: INTEGER;
    Bottom: INTEGER;
  end;
```

#### TSize

A size with width and height.

```myra
type
  TSize = record
    CX: INTEGER;
    CY: INTEGER;
  end;
```

### Constructor Functions

#### Point

Creates a TPoint from X and Y coordinates.

```myra
routine Point(const AX: INTEGER; const AY: INTEGER): TPoint;
```

```myra
var
  P: Geometry.TPoint;
begin
  P := Geometry.Point(100, 200);
end;
```

#### Rect

Creates a TRect from edge coordinates.

```myra
routine Rect(const ALeft: INTEGER; const ATop: INTEGER; const ARight: INTEGER; const ABottom: INTEGER): TRect;
```

```myra
var
  R: Geometry.TRect;
begin
  R := Geometry.Rect(10, 20, 110, 120);
end;
```

#### Bounds

Creates a TRect from position and dimensions.

```myra
routine Bounds(const ALeft: INTEGER; const ATop: INTEGER; const AWidth: INTEGER; const AHeight: INTEGER): TRect;
```

```myra
var
  R: Geometry.TRect;
begin
  R := Geometry.Bounds(10, 20, 100, 100);  // creates rect (10, 20, 110, 120)
end;
```

#### Size

Creates a TSize from width and height.

```myra
routine Size(const ACX: INTEGER; const ACY: INTEGER): TSize;
```

```myra
var
  S: Geometry.TSize;
begin
  S := Geometry.Size(800, 600);
end;
```

### Query Functions

#### PtInRect

Tests if a point is inside a rectangle.

```myra
routine PtInRect(const ARect: TRect; const APoint: TPoint): BOOLEAN;
```

```myra
var
  R: Geometry.TRect;
  P: Geometry.TPoint;
begin
  R := Geometry.Rect(0, 0, 100, 100);
  P := Geometry.Point(50, 50);
  if Geometry.PtInRect(R, P) then
    Console.PrintLn('Point is inside');
  end;
end;
```

#### RectWidth

Returns the width of a rectangle.

```myra
routine RectWidth(const ARect: TRect): INTEGER;
```

#### RectHeight

Returns the height of a rectangle.

```myra
routine RectHeight(const ARect: TRect): INTEGER;
```

#### IsRectEmpty

Tests if a rectangle is empty (zero or negative area).

```myra
routine IsRectEmpty(const ARect: TRect): BOOLEAN;
```

#### EqualRect

Tests if two rectangles are equal.

```myra
routine EqualRect(const ARect1: TRect; const ARect2: TRect): BOOLEAN;
```

### Modification Functions

#### OffsetRect

Moves a rectangle by the specified offset. Returns TRUE.

```myra
routine OffsetRect(var ARect: TRect; const ADX: INTEGER; const ADY: INTEGER): BOOLEAN;
```

```myra
var
  R: Geometry.TRect;
begin
  R := Geometry.Rect(0, 0, 100, 100);
  Geometry.OffsetRect(R, 50, 50);  // R is now (50, 50, 150, 150)
end;
```

#### InflateRect

Expands or shrinks a rectangle. Positive values expand, negative values shrink. Returns TRUE.

```myra
routine InflateRect(var ARect: TRect; const ADX: INTEGER; const ADY: INTEGER): BOOLEAN;
```

```myra
var
  R: Geometry.TRect;
begin
  R := Geometry.Rect(10, 10, 90, 90);
  Geometry.InflateRect(R, 10, 10);  // R is now (0, 0, 100, 100)
end;
```

### Complete Example

```myra
module exe GeometryDemo;

import
  Console,
  Geometry;

begin
  var
    Rect: Geometry.TRect;
    Point: Geometry.TPoint;
  begin
    Rect := Geometry.Bounds(100, 100, 200, 150);
    Point := Geometry.Point(150, 125);
    
    Console.PrintLn('Rectangle: ({}, {}) to ({}, {})',
      Rect.Left, Rect.Top, Rect.Right, Rect.Bottom);
    Console.PrintLn('Size: {} x {}',
      Geometry.RectWidth(Rect), Geometry.RectHeight(Rect));
    
    if Geometry.PtInRect(Rect, Point) then
      Console.PrintLn('Point ({}, {}) is inside', Point.X, Point.Y);
    end;
    
    Geometry.OffsetRect(Rect, 50, 50);
    Console.PrintLn('After offset: ({}, {}) to ({}, {})',
      Rect.Left, Rect.Top, Rect.Right, Rect.Bottom);
  end;
end.
```

## Strings

The Strings module provides string manipulation functions.

```myra
import Strings;
```

### Case Conversion

#### UpperCase

Converts a string to uppercase.

```myra
routine UpperCase(const AValue: STRING): STRING;
```

```myra
Console.PrintLn(Strings.UpperCase('hello'));  // HELLO
```

#### LowerCase

Converts a string to lowercase.

```myra
routine LowerCase(const AValue: STRING): STRING;
```

```myra
Console.PrintLn(Strings.LowerCase('HELLO'));  // hello
```

#### UpCase

Converts a single character to uppercase.

```myra
routine UpCase(const AValue: CHAR): CHAR;
```

#### LowCase

Converts a single character to lowercase.

```myra
routine LowCase(const AValue: CHAR): CHAR;
```

### Trimming

#### Trim

Removes leading and trailing whitespace.

```myra
routine Trim(const AValue: STRING): STRING;
```

```myra
Console.PrintLn(Strings.Trim('  hello  '));  // 'hello'
```

#### TrimLeft

Removes leading whitespace.

```myra
routine TrimLeft(const AValue: STRING): STRING;
```

#### TrimRight

Removes trailing whitespace.

```myra
routine TrimRight(const AValue: STRING): STRING;
```

### Searching

#### Pos

Returns the 1-based position of a substring, or 0 if not found.

```myra
routine Pos(const ASubStr: STRING; const AStr: STRING): INTEGER;
```

```myra
Console.PrintLn(Strings.Pos('world', 'hello world'));  // 7
Console.PrintLn(Strings.Pos('xyz', 'hello world'));    // 0
```

#### ContainsStr

Tests if a string contains a substring (case-sensitive).

```myra
routine ContainsStr(const AText: STRING; const ASubText: STRING): BOOLEAN;
```

#### ContainsText

Tests if a string contains a substring (case-insensitive).

```myra
routine ContainsText(const AText: STRING; const ASubText: STRING): BOOLEAN;
```

#### StartsStr

Tests if a string starts with a prefix (case-sensitive).

```myra
routine StartsStr(const ASubText: STRING; const AText: STRING): BOOLEAN;
```

#### EndsStr

Tests if a string ends with a suffix (case-sensitive).

```myra
routine EndsStr(const ASubText: STRING; const AText: STRING): BOOLEAN;
```

#### StartsText

Tests if a string starts with a prefix (case-insensitive).

```myra
routine StartsText(const ASubText: STRING; const AText: STRING): BOOLEAN;
```

#### EndsText

Tests if a string ends with a suffix (case-insensitive).

```myra
routine EndsText(const ASubText: STRING; const AText: STRING): BOOLEAN;
```

### Substring Extraction

#### LeftStr

Returns the first N characters.

```myra
routine LeftStr(const AText: STRING; const ACount: INTEGER): STRING;
```

```myra
Console.PrintLn(Strings.LeftStr('hello world', 5));  // 'hello'
```

#### RightStr

Returns the last N characters.

```myra
routine RightStr(const AText: STRING; const ACount: INTEGER): STRING;
```

```myra
Console.PrintLn(Strings.RightStr('hello world', 5));  // 'world'
```

#### MidStr

Returns a substring starting at position (1-based) with specified length.

```myra
routine MidStr(const AText: STRING; const AStart: INTEGER; const ACount: INTEGER): STRING;
```

```myra
Console.PrintLn(Strings.MidStr('hello world', 7, 5));  // 'world'
```

#### LeftBStr

Returns the first N bytes (same as LeftStr for ASCII).

```myra
routine LeftBStr(const AText: STRING; const AByteCount: INTEGER): STRING;
```

#### RightBStr

Returns the last N bytes (same as RightStr for ASCII).

```myra
routine RightBStr(const AText: STRING; const AByteCount: INTEGER): STRING;
```

### String Building

#### StringOfChar

Creates a string by repeating a character.

```myra
routine StringOfChar(const AChar: CHAR; const ACount: INTEGER): STRING;
```

```myra
Console.PrintLn(Strings.StringOfChar('*', 10));  // '**********'
```

#### DupeString

Creates a string by repeating a string.

```myra
routine DupeString(const AText: STRING; const ACount: INTEGER): STRING;
```

```myra
Console.PrintLn(Strings.DupeString('ab', 3));  // 'ababab'
```

#### StuffString

Replaces part of a string with another string.

```myra
routine StuffString(const AText: STRING; const AStart: INTEGER; const ALength: INTEGER; const ASubText: STRING): STRING;
```

```myra
Console.PrintLn(Strings.StuffString('hello world', 7, 5, 'Myra'));  // 'hello Myra'
```

### Replacement

#### StringReplace

Replaces all occurrences of a substring (case-sensitive).

```myra
routine StringReplace(const AStr: STRING; const AOld: STRING; const ANew: STRING): STRING;
```

```myra
Console.PrintLn(Strings.StringReplace('hello world', 'world', 'Myra'));  // 'hello Myra'
```

#### ReplaceStr

Same as StringReplace (case-sensitive).

```myra
routine ReplaceStr(const AText: STRING; const AFromText: STRING; const AToText: STRING): STRING;
```

#### ReplaceText

Replaces all occurrences (case-insensitive).

```myra
routine ReplaceText(const AText: STRING; const AFromText: STRING; const AToText: STRING): STRING;
```

### Comparison

#### CompareStr

Compares two strings. Returns -1, 0, or 1.

```myra
routine CompareStr(const AStr1: STRING; const AStr2: STRING): INTEGER;
```

#### SameText

Tests if two strings are equal (case-insensitive).

```myra
routine SameText(const AStr1: STRING; const AStr2: STRING): BOOLEAN;
```

```myra
Console.PrintLn(Strings.SameText('Hello', 'HELLO'));  // TRUE
```

### Miscellaneous

#### ReverseString

Reverses a string.

```myra
routine ReverseString(const AText: STRING): STRING;
```

```myra
Console.PrintLn(Strings.ReverseString('hello'));  // 'olleh'
```

#### QuotedStr

Wraps a string in single quotes, escaping internal quotes.

```myra
routine QuotedStr(const AValue: STRING): STRING;
```

```myra
Console.PrintLn(Strings.QuotedStr('it''s'));  // '''it''''s'''
```

#### PadLeft

Pads a string on the left to reach the specified width.

```myra
routine PadLeft(const AText: STRING; const AWidth: INTEGER): STRING;
```

```myra
Console.PrintLn(Strings.PadLeft('42', 5));  // '   42'
```

#### PadRight

Pads a string on the right to reach the specified width.

```myra
routine PadRight(const AText: STRING; const AWidth: INTEGER): STRING;
```

```myra
Console.PrintLn(Strings.PadRight('42', 5));  // '42   '
```

## Convert

The Convert module provides type conversion functions.

```myra
import Convert;
```

### Integer Conversions

#### IntToStr

Converts an integer to a string.

```myra
routine IntToStr(const AValue: INTEGER): STRING;
```

```myra
Console.PrintLn(Convert.IntToStr(42));  // '42'
```

#### IntToHex

Converts an integer to a hexadecimal string with specified digits.

```myra
routine IntToHex(const AValue: INTEGER; const ADigits: INTEGER): STRING;
```

```myra
Console.PrintLn(Convert.IntToHex(255, 4));  // '00FF'
```

#### HexToInt

Converts a hexadecimal string to an integer.

```myra
routine HexToInt(const AValue: STRING): INTEGER;
```

```myra
Console.PrintLn(Convert.HexToInt('FF'));  // 255
```

#### StrToInt

Converts a string to an integer. Raises an exception if invalid.

```myra
routine StrToInt(const AValue: STRING): INTEGER;
```

```myra
Console.PrintLn(Convert.StrToInt('42'));  // 42
```

#### StrToIntDef

Converts a string to an integer, returning a default value if invalid.

```myra
routine StrToIntDef(const AValue: STRING; const ADefault: INTEGER): INTEGER;
```

```myra
Console.PrintLn(Convert.StrToIntDef('abc', -1));  // -1
Console.PrintLn(Convert.StrToIntDef('42', -1));   // 42
```

### Floating Point Conversions

#### FloatToStr

Converts a float to a string.

```myra
routine FloatToStr(const AValue: FLOAT): STRING;
```

```myra
Console.PrintLn(Convert.FloatToStr(3.14159));  // '3.141590'
```

#### StrToFloat

Converts a string to a float. Raises an exception if invalid.

```myra
routine StrToFloat(const AValue: STRING): FLOAT;
```

```myra
Console.PrintLn(Convert.StrToFloat('3.14'));  // 3.14
```

### Boolean Conversions

#### BoolToStr

Converts a boolean to 'True' or 'False'.

```myra
routine BoolToStr(const AValue: BOOLEAN): STRING;
```

```myra
Console.PrintLn(Convert.BoolToStr(TRUE));   // 'True'
Console.PrintLn(Convert.BoolToStr(FALSE));  // 'False'
```

#### BoolToStrEx

Converts a boolean to a string with format control.

```myra
routine BoolToStrEx(const AValue: BOOLEAN; const AUseBoolStrs: BOOLEAN): STRING;
```

When AUseBoolStrs is TRUE, returns 'True'/'False'. When FALSE, returns '-1'/'0'.

```myra
Console.PrintLn(Convert.BoolToStrEx(TRUE, TRUE));   // 'True'
Console.PrintLn(Convert.BoolToStrEx(TRUE, FALSE));  // '-1'
```

## Files

The Files module provides file system operations and file I/O.

```myra
import Files;
```

### Types

#### TTextFile

Handle for text file operations.

#### TBinaryFile

Handle for binary file operations.

### Text File I/O

#### AssignTextFile

Associates a filename with a text file handle.

```myra
routine AssignTextFile(var AFile: TTextFile; const AFileName: STRING);
```

#### RewriteTextFile

Creates or truncates a file for writing.

```myra
routine RewriteTextFile(var AFile: TTextFile);
```

#### ResetTextFile

Opens a file for reading.

```myra
routine ResetTextFile(var AFile: TTextFile);
```

#### AppendTextFile

Opens a file for appending.

```myra
routine AppendTextFile(var AFile: TTextFile);
```

#### CloseTextFile

Closes a text file.

```myra
routine CloseTextFile(var AFile: TTextFile);
```

#### EofTextFile

Tests if end of file has been reached.

```myra
routine EofTextFile(var AFile: TTextFile): BOOLEAN;
```

#### ReadLnTextFile

Reads a line from a text file.

```myra
routine ReadLnTextFile(var AFile: TTextFile; var ALine: STRING);
```

#### ReadTextFile

Reads a whitespace-delimited token from a text file.

```myra
routine ReadTextFile(var AFile: TTextFile; var AValue: STRING);
```

#### EolnTextFile

Tests if at end of line.

```myra
routine EolnTextFile(var AFile: TTextFile): BOOLEAN;
```

#### SeekEofTextFile

Skips whitespace and tests for end of file.

```myra
routine SeekEofTextFile(var AFile: TTextFile): BOOLEAN;
```

#### SeekEolnTextFile

Skips whitespace and tests for end of line.

```myra
routine SeekEolnTextFile(var AFile: TTextFile): BOOLEAN;
```

#### FlushTextFile

Flushes buffered writes to disk.

```myra
routine FlushTextFile(var AFile: TTextFile);
```

### Text File Example

```myra
var
  F: Files.TTextFile;
  Line: STRING;
begin
  Files.AssignTextFile(F, 'data.txt');
  Files.ResetTextFile(F);
  
  while not Files.EofTextFile(F) do
    Files.ReadLnTextFile(F, Line);
    Console.PrintLn(Line);
  end;
  
  Files.CloseTextFile(F);
end;
```

### Binary File I/O

#### AssignBinaryFile

Associates a filename with a binary file handle.

```myra
routine AssignBinaryFile(var AFile: TBinaryFile; const AFileName: STRING);
```

#### RewriteBinaryFile

Creates or truncates a binary file for writing with specified record size.

```myra
routine RewriteBinaryFile(var AFile: TBinaryFile; const ARecordSize: INTEGER);
```

#### ResetBinaryFile

Opens a binary file for reading/writing with specified record size.

```myra
routine ResetBinaryFile(var AFile: TBinaryFile; const ARecordSize: INTEGER);
```

#### CloseBinaryFile

Closes a binary file.

```myra
routine CloseBinaryFile(var AFile: TBinaryFile);
```

#### EofBinaryFile

Tests if end of file has been reached.

```myra
routine EofBinaryFile(var AFile: TBinaryFile): BOOLEAN;
```

#### BlockWrite

Writes records to a binary file.

```myra
routine BlockWrite(var AFile: TBinaryFile; const ABuffer: POINTER; const ACount: INTEGER; var AResult: INTEGER);
```

#### BlockRead

Reads records from a binary file.

```myra
routine BlockRead(var AFile: TBinaryFile; ABuffer: POINTER; const ACount: INTEGER; var AResult: INTEGER);
```

#### FileSizeBinary

Returns the file size in records.

```myra
routine FileSizeBinary(var AFile: TBinaryFile): INTEGER;
```

#### FilePosBinary

Returns the current position in records.

```myra
routine FilePosBinary(var AFile: TBinaryFile): INTEGER;
```

#### SeekBinary

Seeks to a position in records.

```myra
routine SeekBinary(var AFile: TBinaryFile; const APosition: INTEGER);
```

#### TruncateBinary

Truncates the file at the current position.

```myra
routine TruncateBinary(var AFile: TBinaryFile);
```

### File System Functions

#### FileExists

Tests if a file exists.

```myra
routine FileExists(const AFileName: STRING): BOOLEAN;
```

```myra
if Files.FileExists('config.txt') then
  Console.PrintLn('Config file found');
end;
```

#### DirectoryExists

Tests if a directory exists.

```myra
routine DirectoryExists(const ADirectory: STRING): BOOLEAN;
```

#### DeleteFile

Deletes a file. Returns TRUE on success.

```myra
routine DeleteFile(const AFileName: STRING): BOOLEAN;
```

#### RenameFile

Renames a file. Returns TRUE on success.

```myra
routine RenameFile(const AOldName: STRING; const ANewName: STRING): BOOLEAN;
```

#### CreateDir

Creates a directory. Returns TRUE on success.

```myra
routine CreateDir(const ADirectory: STRING): BOOLEAN;
```

#### RemoveDir

Removes an empty directory. Returns TRUE on success.

```myra
routine RemoveDir(const ADirectory: STRING): BOOLEAN;
```

#### GetCurrentDir

Returns the current working directory.

```myra
routine GetCurrentDir(): STRING;
```

```myra
Console.PrintLn('Current dir: {}', Files.GetCurrentDir());
```

#### SetCurrentDir

Sets the current working directory. Returns TRUE on success.

```myra
routine SetCurrentDir(const ADirectory: STRING): BOOLEAN;
```

#### IOResult

Returns the I/O result code (always 0 in current implementation).

```myra
routine IOResult(): INTEGER;
```

## Paths

The Paths module provides path manipulation functions.

```myra
import Paths;
```

### Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `PathDelim` | `'\'` | Path separator character |
| `DriveDelim` | `':'` | Drive delimiter character |

### Path Extraction

#### ExtractFilePath

Extracts the path from a filename (includes trailing delimiter).

```myra
routine ExtractFilePath(const AFileName: STRING): STRING;
```

```myra
Console.PrintLn(Paths.ExtractFilePath('C:\Dir\File.txt'));  // 'C:\Dir\'
```

#### ExtractFileDir

Extracts the directory from a filename (no trailing delimiter).

```myra
routine ExtractFileDir(const AFileName: STRING): STRING;
```

```myra
Console.PrintLn(Paths.ExtractFileDir('C:\Dir\File.txt'));  // 'C:\Dir'
```

#### ExtractFileName

Extracts the filename from a path.

```myra
routine ExtractFileName(const AFileName: STRING): STRING;
```

```myra
Console.PrintLn(Paths.ExtractFileName('C:\Dir\File.txt'));  // 'File.txt'
```

#### ExtractFileExt

Extracts the file extension (including the dot).

```myra
routine ExtractFileExt(const AFileName: STRING): STRING;
```

```myra
Console.PrintLn(Paths.ExtractFileExt('C:\Dir\File.txt'));  // '.txt'
```

#### ExtractFileDrive

Extracts the drive letter.

```myra
routine ExtractFileDrive(const AFileName: STRING): STRING;
```

```myra
Console.PrintLn(Paths.ExtractFileDrive('C:\Dir\File.txt'));  // 'C:'
```

### Path Modification

#### ChangeFileExt

Changes the file extension.

```myra
routine ChangeFileExt(const AFileName: STRING; const AExtension: STRING): STRING;
```

```myra
Console.PrintLn(Paths.ChangeFileExt('file.txt', '.bak'));  // 'file.bak'
```

#### ExpandFileName

Expands a relative path to an absolute path.

```myra
routine ExpandFileName(const AFileName: STRING): STRING;
```

```myra
Console.PrintLn(Paths.ExpandFileName('file.txt'));  // 'C:\Current\Dir\file.txt'
```

### Trailing Delimiter Handling

#### IncludeTrailingPathDelimiter

Ensures the path ends with a path delimiter.

```myra
routine IncludeTrailingPathDelimiter(const APath: STRING): STRING;
```

```myra
Console.PrintLn(Paths.IncludeTrailingPathDelimiter('C:\Dir'));  // 'C:\Dir\'
```

#### ExcludeTrailingPathDelimiter

Removes trailing path delimiter if present.

```myra
routine ExcludeTrailingPathDelimiter(const APath: STRING): STRING;
```

```myra
Console.PrintLn(Paths.ExcludeTrailingPathDelimiter('C:\Dir\'));  // 'C:\Dir'
```

#### IncludeTrailingBackslash

Same as IncludeTrailingPathDelimiter.

```myra
routine IncludeTrailingBackslash(const APath: STRING): STRING;
```

#### ExcludeTrailingBackslash

Same as ExcludeTrailingPathDelimiter.

```myra
routine ExcludeTrailingBackslash(const APath: STRING): STRING;
```

### Delimiter Detection

#### IsPathDelimiter

Tests if character at index (1-based) is a path delimiter.

```myra
routine IsPathDelimiter(const APath: STRING; const AIndex: INTEGER): BOOLEAN;
```

#### IsDelimiter

Tests if character at index (1-based) is one of the specified delimiters.

```myra
routine IsDelimiter(const ADelimiters: STRING; const AText: STRING; const AIndex: INTEGER): BOOLEAN;
```

#### LastDelimiter

Returns the 1-based index of the last delimiter character, or 0 if not found.

```myra
routine LastDelimiter(const ADelimiters: STRING; const AText: STRING): INTEGER;
```

```myra
Console.PrintLn(Paths.LastDelimiter('\/:', 'C:\Dir\File'));  // 7
```

### Character Access

#### AnsiLastChar

Returns the last character of a string.

```myra
routine AnsiLastChar(const AText: STRING): CHAR;
```

#### AnsiStrLastChar

Returns the last character as a string.

```myra
routine AnsiStrLastChar(const AText: STRING): STRING;
```

## Maths

The Maths module provides mathematical functions and utilities.

```myra
import Maths;
```

### Absolute Value Functions

#### Abs

Returns the absolute value of an integer.

```myra
routine Abs(const AValue: INTEGER): INTEGER;
```

```myra
Console.PrintLn(Maths.Abs(-42));  // 42
```

#### AbsF

Returns the absolute value of a float.

```myra
routine AbsF(const AValue: FLOAT): FLOAT;
```

```myra
Console.PrintLn(Maths.AbsF(-3.14));  // 3.14
```

### Basic Arithmetic

#### Sqr

Returns the square of a value.

```myra
routine Sqr(const AValue: FLOAT): FLOAT;
```

```myra
Console.PrintLn(Maths.Sqr(5.0));  // 25.0
```

#### Sqrt

Returns the square root of a value.

```myra
routine Sqrt(const AValue: FLOAT): FLOAT;
```

```myra
Console.PrintLn(Maths.Sqrt(25.0));  // 5.0
```

### Trigonometric Functions

#### Sin

Returns the sine of an angle in radians.

```myra
routine Sin(const AValue: FLOAT): FLOAT;
```

#### Cos

Returns the cosine of an angle in radians.

```myra
routine Cos(const AValue: FLOAT): FLOAT;
```

#### Tan

Returns the tangent of an angle in radians.

```myra
routine Tan(const AValue: FLOAT): FLOAT;
```

#### ArcSin

Returns the arc sine (inverse sine) in radians.

```myra
routine ArcSin(const AValue: FLOAT): FLOAT;
```

#### ArcCos

Returns the arc cosine (inverse cosine) in radians.

```myra
routine ArcCos(const AValue: FLOAT): FLOAT;
```

#### ArcTan

Returns the arc tangent (inverse tangent) in radians.

```myra
routine ArcTan(const AValue: FLOAT): FLOAT;
```

#### ArcTan2

Returns the arc tangent of Y/X, using signs to determine quadrant.

```myra
routine ArcTan2(const AY: FLOAT; const AX: FLOAT): FLOAT;
```

### Hyperbolic Functions

#### Sinh

Returns the hyperbolic sine.

```myra
routine Sinh(const AValue: FLOAT): FLOAT;
```

#### Cosh

Returns the hyperbolic cosine.

```myra
routine Cosh(const AValue: FLOAT): FLOAT;
```

#### Tanh

Returns the hyperbolic tangent.

```myra
routine Tanh(const AValue: FLOAT): FLOAT;
```

#### ArcSinh

Returns the inverse hyperbolic sine.

```myra
routine ArcSinh(const AValue: FLOAT): FLOAT;
```

#### ArcCosh

Returns the inverse hyperbolic cosine.

```myra
routine ArcCosh(const AValue: FLOAT): FLOAT;
```

#### ArcTanh

Returns the inverse hyperbolic tangent.

```myra
routine ArcTanh(const AValue: FLOAT): FLOAT;
```

### Logarithmic and Exponential Functions

#### Ln

Returns the natural logarithm (base e).

```myra
routine Ln(const AValue: FLOAT): FLOAT;
```

#### Exp

Returns e raised to the power.

```myra
routine Exp(const AValue: FLOAT): FLOAT;
```

#### Power

Returns base raised to the exponent.

```myra
routine Power(const ABase: FLOAT; const AExponent: FLOAT): FLOAT;
```

```myra
Console.PrintLn(Maths.Power(2.0, 10.0));  // 1024.0
```

#### Log10

Returns the base-10 logarithm.

```myra
routine Log10(const AValue: FLOAT): FLOAT;
```

#### Log2

Returns the base-2 logarithm.

```myra
routine Log2(const AValue: FLOAT): FLOAT;
```

#### LogN

Returns the logarithm with specified base.

```myra
routine LogN(const ABase: FLOAT; const AValue: FLOAT): FLOAT;
```

### Rounding Functions

#### Trunc

Truncates toward zero, returning an integer.

```myra
routine Trunc(const AValue: FLOAT): INTEGER;
```

```myra
Console.PrintLn(Maths.Trunc(3.7));   // 3
Console.PrintLn(Maths.Trunc(-3.7));  // -3
```

#### Round

Rounds to nearest integer.

```myra
routine Round(const AValue: FLOAT): INTEGER;
```

```myra
Console.PrintLn(Maths.Round(3.4));  // 3
Console.PrintLn(Maths.Round(3.5));  // 4
```

#### Int

Returns the integer part as a float.

```myra
routine Int(const AValue: FLOAT): FLOAT;
```

#### Frac

Returns the fractional part.

```myra
routine Frac(const AValue: FLOAT): FLOAT;
```

```myra
Console.PrintLn(Maths.Frac(3.75));  // 0.75
```

#### Ceil

Rounds up to the nearest integer.

```myra
routine Ceil(const AValue: FLOAT): INTEGER;
```

```myra
Console.PrintLn(Maths.Ceil(3.1));  // 4
```

#### Floor

Rounds down to the nearest integer.

```myra
routine Floor(const AValue: FLOAT): INTEGER;
```

```myra
Console.PrintLn(Maths.Floor(3.9));  // 3
```

### Constants and Utilities

#### Pi

Returns the value of π (pi).

```myra
routine Pi(): FLOAT;
```

```myra
Console.PrintLn(Maths.Pi());  // 3.14159...
```

#### MinI

Returns the smaller of two integers.

```myra
routine MinI(const A: INTEGER; const B: INTEGER): INTEGER;
```

#### MinF

Returns the smaller of two floats.

```myra
routine MinF(const A: FLOAT; const B: FLOAT): FLOAT;
```

#### MaxI

Returns the larger of two integers.

```myra
routine MaxI(const A: INTEGER; const B: INTEGER): INTEGER;
```

#### MaxF

Returns the larger of two floats.

```myra
routine MaxF(const A: FLOAT; const B: FLOAT): FLOAT;
```

#### Sign

Returns the sign of a value: -1, 0, or 1.

```myra
routine Sign(const AValue: FLOAT): INTEGER;
```

```myra
Console.PrintLn(Maths.Sign(-5.0));  // -1
Console.PrintLn(Maths.Sign(0.0));   // 0
Console.PrintLn(Maths.Sign(5.0));   // 1
```

### Random Number Generation

#### RandomF

Returns a random float between 0.0 and 1.0.

```myra
routine RandomF(): FLOAT;
```

#### Random

Returns a random integer between 0 and ARange-1.

```myra
routine Random(const ARange: INTEGER): INTEGER;
```

```myra
Console.PrintLn(Maths.Random(100));  // 0-99
```

#### Randomize

Seeds the random number generator with the current time.

```myra
routine Randomize();
```

```myra
Maths.Randomize();
Console.PrintLn(Maths.Random(100));
```

### Swap Functions

#### SwapI

Swaps two integer values.

```myra
routine SwapI(var A: INTEGER; var B: INTEGER);
```

```myra
var
  X: INTEGER;
  Y: INTEGER;
begin
  X := 10;
  Y := 20;
  Maths.SwapI(X, Y);
  // X is now 20, Y is now 10
end;
```

#### SwapF

Swaps two float values.

```myra
routine SwapF(var A: FLOAT; var B: FLOAT);
```

## DateTime

The DateTime module provides date and time manipulation functions.

```myra
import DateTime;
```

### Types

#### TDateTime

A floating-point value representing a date/time. The integer part represents days since epoch, the fractional part represents time of day.

```myra
type
  TDateTime = FLOAT;
```

#### TMonthDays

Array type for days in each month.

```myra
type
  TMonthDays = ARRAY[1..12] OF INTEGER;
```

### Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `UnixDateDelta` | 25569 | Days between Delphi epoch and Unix epoch |
| `HoursPerDay` | 24 | Hours in a day |
| `MinsPerHour` | 60 | Minutes in an hour |
| `SecsPerMin` | 60 | Seconds in a minute |
| `MSecsPerSec` | 1000 | Milliseconds in a second |
| `MinsPerDay` | 1440 | Minutes in a day |
| `SecsPerDay` | 86400 | Seconds in a day |
| `MSecsPerDay` | 86400000 | Milliseconds in a day |
| `DateDelta` | 693594 | Days between day 0 and Delphi epoch |
| `DaysPerWeek` | 7 | Days in a week |
| `WeeksPerYear` | 52 | Weeks in a year |
| `MonthsPerYear` | 12 | Months in a year |

### Date Utilities

#### IsLeapYear

Tests if a year is a leap year.

```myra
routine IsLeapYear(const AYear: INTEGER): BOOLEAN;
```

```myra
Console.PrintLn(DateTime.IsLeapYear(2024));  // TRUE
Console.PrintLn(DateTime.IsLeapYear(2023));  // FALSE
```

#### DaysInMonth

Returns the number of days in a month.

```myra
routine DaysInMonth(const AYear: INTEGER; const AMonth: INTEGER): INTEGER;
```

```myra
Console.PrintLn(DateTime.DaysInMonth(2024, 2));  // 29 (leap year)
Console.PrintLn(DateTime.DaysInMonth(2023, 2));  // 28
```

#### DaysInYear

Returns the number of days in a year.

```myra
routine DaysInYear(const AYear: INTEGER): INTEGER;
```

```myra
Console.PrintLn(DateTime.DaysInYear(2024));  // 366
Console.PrintLn(DateTime.DaysInYear(2023));  // 365
```

### Encoding Functions

#### EncodeDate

Creates a TDateTime from year, month, and day.

```myra
routine EncodeDate(const AYear: INTEGER; const AMonth: INTEGER; const ADay: INTEGER): TDateTime;
```

```myra
var
  D: DateTime.TDateTime;
begin
  D := DateTime.EncodeDate(2024, 12, 25);
end;
```

#### EncodeTime

Creates a TDateTime from hour, minute, second, and millisecond.

```myra
routine EncodeTime(const AHour: INTEGER; const AMinute: INTEGER; const ASecond: INTEGER; const AMilliSecond: INTEGER): TDateTime;
```

```myra
var
  T: DateTime.TDateTime;
begin
  T := DateTime.EncodeTime(14, 30, 0, 0);  // 2:30 PM
end;
```

#### EncodeDateTime

Creates a TDateTime from all components.

```myra
routine EncodeDateTime(const AYear: INTEGER; const AMonth: INTEGER; const ADay: INTEGER; const AHour: INTEGER; const AMinute: INTEGER; const ASecond: INTEGER; const AMilliSecond: INTEGER): TDateTime;
```

### Current Date/Time

#### Now

Returns the current date and time.

```myra
routine Now(): TDateTime;
```

```myra
var
  CurrentTime: DateTime.TDateTime;
begin
  CurrentTime := DateTime.Now();
end;
```

#### GetDate

Returns the current date (time portion is zero).

```myra
routine GetDate(): TDateTime;
```

#### GetTime

Returns the current time (date portion is zero).

```myra
routine GetTime(): TDateTime;
```

### Decoding Functions

#### DecodeDate

Extracts year, month, and day from a TDateTime.

```myra
routine DecodeDate(const ADateTime: TDateTime; var AYear: INTEGER; var AMonth: INTEGER; var ADay: INTEGER);
```

```myra
var
  Year: INTEGER;
  Month: INTEGER;
  Day: INTEGER;
begin
  DateTime.DecodeDate(DateTime.Now(), Year, Month, Day);
  Console.PrintLn('Today: {}/{}/{}', Year, Month, Day);
end;
```

#### DecodeTime

Extracts hour, minute, second, and millisecond from a TDateTime.

```myra
routine DecodeTime(const ADateTime: TDateTime; var AHour: INTEGER; var AMinute: INTEGER; var ASecond: INTEGER; var AMilliSecond: INTEGER);
```

#### DecodeDateTime

Extracts all date/time components.

```myra
routine DecodeDateTime(const ADateTime: TDateTime; var AYear: INTEGER; var AMonth: INTEGER; var ADay: INTEGER; var AHour: INTEGER; var AMinute: INTEGER; var ASecond: INTEGER; var AMilliSecond: INTEGER);
```

### Part Extraction

#### DateOf

Returns the date portion (sets time to midnight).

```myra
routine DateOf(const ADateTime: TDateTime): TDateTime;
```

#### TimeOf

Returns the time portion (sets date to zero).

```myra
routine TimeOf(const ADateTime: TDateTime): TDateTime;
```

#### YearOf

Returns the year.

```myra
routine YearOf(const ADateTime: TDateTime): INTEGER;
```

#### MonthOf

Returns the month (1-12).

```myra
routine MonthOf(const ADateTime: TDateTime): INTEGER;
```

#### DayOf

Returns the day of month (1-31).

```myra
routine DayOf(const ADateTime: TDateTime): INTEGER;
```

#### HourOf

Returns the hour (0-23).

```myra
routine HourOf(const ADateTime: TDateTime): INTEGER;
```

#### MinuteOf

Returns the minute (0-59).

```myra
routine MinuteOf(const ADateTime: TDateTime): INTEGER;
```

#### SecondOf

Returns the second (0-59).

```myra
routine SecondOf(const ADateTime: TDateTime): INTEGER;
```

#### MilliSecondOf

Returns the millisecond (0-999).

```myra
routine MilliSecondOf(const ADateTime: TDateTime): INTEGER;
```

### Increment Functions

#### IncYear

Adds years to a date.

```myra
routine IncYear(const ADateTime: TDateTime; const ANumberOfYears: INTEGER): TDateTime;
```

```myra
var
  NextYear: DateTime.TDateTime;
begin
  NextYear := DateTime.IncYear(DateTime.Now(), 1);
end;
```

#### IncMonth

Adds months to a date.

```myra
routine IncMonth(const ADateTime: TDateTime; const ANumberOfMonths: INTEGER): TDateTime;
```

#### IncWeek

Adds weeks to a date.

```myra
routine IncWeek(const ADateTime: TDateTime; const ANumberOfWeeks: INTEGER): TDateTime;
```

#### IncDay

Adds days to a date.

```myra
routine IncDay(const ADateTime: TDateTime; const ANumberOfDays: INTEGER): TDateTime;
```

```myra
var
  Tomorrow: DateTime.TDateTime;
begin
  Tomorrow := DateTime.IncDay(DateTime.Now(), 1);
end;
```

#### IncHour

Adds hours to a date/time.

```myra
routine IncHour(const ADateTime: TDateTime; const ANumberOfHours: INTEGER): TDateTime;
```

#### IncMinute

Adds minutes to a date/time.

```myra
routine IncMinute(const ADateTime: TDateTime; const ANumberOfMinutes: INTEGER): TDateTime;
```

#### IncSecond

Adds seconds to a date/time.

```myra
routine IncSecond(const ADateTime: TDateTime; const ANumberOfSeconds: INTEGER): TDateTime;
```

#### IncMilliSecond

Adds milliseconds to a date/time.

```myra
routine IncMilliSecond(const ADateTime: TDateTime; const ANumberOfMilliSeconds: INTEGER): TDateTime;
```

### Difference Functions

#### DaysBetween

Returns the number of whole days between two dates.

```myra
routine DaysBetween(const ADateTime1: TDateTime; const ADateTime2: TDateTime): INTEGER;
```

```myra
var
  Start: DateTime.TDateTime;
  EndDate: DateTime.TDateTime;
begin
  Start := DateTime.EncodeDate(2024, 1, 1);
  EndDate := DateTime.EncodeDate(2024, 12, 31);
  Console.PrintLn('Days in 2024: {}', DateTime.DaysBetween(Start, EndDate));
end;
```

#### HoursBetween

Returns the number of whole hours between two date/times.

```myra
routine HoursBetween(const ADateTime1: TDateTime; const ADateTime2: TDateTime): INTEGER;
```

#### MinutesBetween

Returns the number of whole minutes between two date/times.

```myra
routine MinutesBetween(const ADateTime1: TDateTime; const ADateTime2: TDateTime): INTEGER;
```

#### SecondsBetween

Returns the number of whole seconds between two date/times.

```myra
routine SecondsBetween(const ADateTime1: TDateTime; const ADateTime2: TDateTime): INTEGER;
```

#### MilliSecondsBetween

Returns the number of milliseconds between two date/times.

```myra
routine MilliSecondsBetween(const ADateTime1: TDateTime; const ADateTime2: TDateTime): INTEGER;
```

### Comparison Functions

#### CompareDate

Compares the date portions. Returns -1, 0, or 1.

```myra
routine CompareDate(const ADateTime1: TDateTime; const ADateTime2: TDateTime): INTEGER;
```

#### CompareDateTime

Compares two date/times. Returns -1, 0, or 1.

```myra
routine CompareDateTime(const ADateTime1: TDateTime; const ADateTime2: TDateTime): INTEGER;
```

#### CompareTime

Compares the time portions. Returns -1, 0, or 1.

```myra
routine CompareTime(const ADateTime1: TDateTime; const ADateTime2: TDateTime): INTEGER;
```

#### SameDate

Tests if two date/times have the same date.

```myra
routine SameDate(const ADateTime1: TDateTime; const ADateTime2: TDateTime): BOOLEAN;
```

#### SameDateTime

Tests if two date/times are equal.

```myra
routine SameDateTime(const ADateTime1: TDateTime; const ADateTime2: TDateTime): BOOLEAN;
```

#### SameTime

Tests if two date/times have the same time.

```myra
routine SameTime(const ADateTime1: TDateTime; const ADateTime2: TDateTime): BOOLEAN;
```

### Day of Week

#### DayOfWeek

Returns the day of week (1=Sunday, 7=Saturday).

```myra
routine DayOfWeek(const ADateTime: TDateTime): INTEGER;
```

```myra
var
  DOW: INTEGER;
begin
  DOW := DateTime.DayOfWeek(DateTime.Now());
  case DOW of
    1: Console.PrintLn('Sunday');
    2: Console.PrintLn('Monday');
    3: Console.PrintLn('Tuesday');
    4: Console.PrintLn('Wednesday');
    5: Console.PrintLn('Thursday');
    6: Console.PrintLn('Friday');
    7: Console.PrintLn('Saturday');
  end;
end;
```

### Formatting

#### FormatDateTime

Formats a date/time using a format string.

```myra
routine FormatDateTime(const AFormat: STRING; const ADateTime: TDateTime): STRING;
```

**Format specifiers:**

| Specifier | Description |
|-----------|-------------|
| `d` | Day without leading zero (1-31) |
| `dd` | Day with leading zero (01-31) |
| `ddd` | Short day name (Sun, Mon, ...) |
| `dddd` | Long day name (Sunday, Monday, ...) |
| `m` | Month without leading zero (1-12) |
| `mm` | Month with leading zero (01-12) |
| `mmm` | Short month name (Jan, Feb, ...) |
| `mmmm` | Long month name (January, February, ...) |
| `yy` | Two-digit year |
| `yyyy` | Four-digit year |
| `h` | Hour without leading zero (0-23) |
| `hh` | Hour with leading zero (00-23) |
| `n` | Minute without leading zero (0-59) |
| `nn` | Minute with leading zero (00-59) |
| `s` | Second without leading zero (0-59) |
| `ss` | Second with leading zero (00-59) |
| `zzz` | Milliseconds (000-999) |

```myra
var
  Now: DateTime.TDateTime;
begin
  Now := DateTime.Now();
  
  Console.PrintLn(DateTime.FormatDateTime('yyyy-mm-dd', Now));
  // Output: 2024-06-15
  
  Console.PrintLn(DateTime.FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
  // Output: 15/06/2024 14:30:45
  
  Console.PrintLn(DateTime.FormatDateTime('dddd, mmmm d, yyyy', Now));
  // Output: Saturday, June 15, 2024
end;
```

### Complete Example

```myra
module exe DateTimeDemo;

import
  Console,
  DateTime;

begin
  var
    Now: DateTime.TDateTime;
    Year: INTEGER;
    Month: INTEGER;
    Day: INTEGER;
    Tomorrow: DateTime.TDateTime;
  begin
    Now := DateTime.Now();
    
    Console.PrintLn('Current date/time:');
    Console.PrintLn(DateTime.FormatDateTime('dddd, mmmm d, yyyy at hh:nn:ss', Now));
    
    DateTime.DecodeDate(Now, Year, Month, Day);
    Console.PrintLn('Year: {}, Month: {}, Day: {}', Year, Month, Day);
    
    if DateTime.IsLeapYear(Year) then
      Console.PrintLn('{} is a leap year', Year);
    end;
    
    Console.PrintLn('Days in this month: {}', DateTime.DaysInMonth(Year, Month));
    
    Tomorrow := DateTime.IncDay(Now, 1);
    Console.PrintLn('Tomorrow: {}', DateTime.FormatDateTime('yyyy-mm-dd', Tomorrow));
  end;
end.
```


*Myra™ — Pascal. Refined.*
