# C++ Interoperability Guide

Myra's defining feature: seamless C++ integration.

## Table of Contents

1. [Philosophy](#philosophy)
2. [Basic Integration](#basic-integration)
3. [Raw C++ Blocks](#raw-c-blocks)
4. [C++ Passthrough](#c-passthrough)
5. [External Libraries](#external-libraries)
6. [Type Mapping](#type-mapping)
7. [Common Patterns](#common-patterns)
8. [Complete Examples](#complete-examples)

## Philosophy

Myra's approach to C++ integration is simple:

> **If it's not Myra, it's C++. Emit it.**

This means you can freely mix Myra and C++ code. No wrappers, no bindings, no FFI complexity. Just write the code you need.

### When to Use C++

- Accessing system APIs
- Using existing C/C++ libraries
- Performance-critical inner loops
- Features not in Myra (templates, operator overloading)

### When to Use Myra

- Application logic
- Data structures
- Control flow
- Readable, maintainable code

## Basic Integration

### Calling C++ from Myra

```myra
module exe BasicCpp;

import Console;

#startcpp header
inline int CppAdd(int a, int b) {
    return a + b;
}
#endcpp

begin
  Console.PrintLn('5 + 3 = {}', CppAdd(5, 3));
end.
```

### Calling Myra from C++

Myra routines are just C++ functions:

```myra
module exe CppCallsMyra;

import Console;

routine MyraFunction(): INTEGER;
begin
  return 42;
end;

#startcpp source
void CppCode() {
    int result = MyraFunction();
    std::println("Myra returned: {}", result);
}
#endcpp

begin
  CppCode();
end.
```

## Raw C++ Blocks

Use `#startcpp` and `#endcpp` for pure C++ code.

### Header Target

Code goes into the generated `.h` file:

```myra
#startcpp header
#include <vector>
#include <string>

inline int Square(int x) {
    return x * x;
}

template<typename T>
T Max(T a, T b) {
    return (a > b) ? a : b;
}
#endcpp
```

Use `header` for:
- Inline functions
- Templates
- Type definitions
- Include directives

### Source Target

Code goes into the generated `.cpp` file:

```myra
#startcpp source
static int counter = 0;

void IncrementCounter() {
    counter++;
}

int GetCounter() {
    return counter;
}
#endcpp
```

Use `source` for:
- Static variables
- Non-inline functions
- Implementation details

### Default Target

Without specifier, defaults to `source`:

```myra
#startcpp
// This goes to the .cpp file
void Helper() {
    // ...
}
#endcpp
```

## C++ Passthrough

C++ code can appear inline within Myra code.

### In Const Section

```myra
const
  MaxSize = 100;                        // Myra
  constexpr int32_t CPP_MAX = 1024;     // C++
  constexpr uint32_t FLAGS = 0x0001;    // C++
```

### In Type Section

```myra
type
  TPoint = record                       // Myra
    X: INTEGER;
    Y: INTEGER;
  end;
  
  typedef int32_t MyInt;                // C++
  using MyHandle = void*;               // C++
```

### In Var Section

```myra
var
  Count: INTEGER;                       // Myra
  flags: uint32_t;                      // C++
  buffer: std::vector<int>;             // C++
```

### In Statements

```myra
begin
  Count := 10;                          // Myra
  
  int32_t cppVar = 42;                  // C++
  cppVar = cppVar * 2;                  // C++
  
  Console.PrintLn('Result: {}', cppVar);  // Myra
end.
```

## External Libraries

### Including Headers

```myra
#include_header '<iostream>'
#include_header '<vector>'
#include_header '<algorithm>'
#include_header '"mylocal.h"'
```

### Setting Include Paths

```myra
#include_path 'include'
#include_path '/usr/local/include'
#include_path 'C:/SDK/include'
```

### Linking Libraries

```myra
#link 'sqlite3'
#link 'opengl32'
#link 'pthread'
```

### Setting Library Paths

```myra
#library_path 'lib'
#library_path '/usr/local/lib'
#library_path 'C:/SDK/lib'
```

### External Functions

```myra
// Windows MessageBox
routine MessageBoxA(
  const AHwnd: POINTER;
  const AText: STRING;
  const ACaption: STRING;
  const AType: INTEGER
): INTEGER;
external 'user32.dll';

// Calling convention
routine SomeFunction(const A: INTEGER): INTEGER;
cdecl;
external 'mylib';
```

## Type Mapping

### Myra to C++

| Myra Type | C++ Type |
|-----------|----------|
| `BOOLEAN` | `bool` |
| `CHAR` | `char` |
| `UCHAR` | `unsigned char` |
| `INTEGER` | `int64_t` |
| `UINTEGER` | `uint64_t` |
| `FLOAT` | `double` |
| `STRING` | `std::string` |
| `SET` | `std::bitset` |
| `POINTER` | `void*` |
| `POINTER TO T` | `T*` |

### Using C++ Types Directly

```myra
var
  small: int32_t;
  byte: uint8_t;
  single: float;
  wide: wchar_t;
```

### Pointer Compatibility

```myra
var
  MyraPtr: POINTER TO INTEGER;
  CppPtr: int64_t*;
begin
  NEW(MyraPtr);
  MyraPtr^ := 42;
  
  // Compatible - both are int64_t*
  CppPtr = MyraPtr;
end.
```

## Common Patterns

### Using STL Containers

```myra
module exe StlDemo;

import Console;

#include_header '<vector>'
#include_header '<map>'
#include_header '<string>'

#startcpp header
inline void VectorExample() {
    std::vector<int> numbers = {1, 2, 3, 4, 5};
    
    for (int n : numbers) {
        std::println("  {}", n);
    }
}

inline void MapExample() {
    std::map<std::string, int> ages;
    ages["Alice"] = 30;
    ages["Bob"] = 25;
    
    for (const auto& [name, age] : ages) {
        std::println("  {}: {}", name, age);
    }
}
#endcpp

begin
  Console.PrintLn('Vector:');
  VectorExample();
  
  Console.PrintLn('Map:');
  MapExample();
end.
```

### Calling Windows API

```myra
module exe WinApiDemo;

import Console;

#startcpp header
#ifdef _WIN32
#include <windows.h>
#endif
#endcpp

begin
  #ifdef _WIN32
  DWORD ticks = GetTickCount();
  Console.PrintLn('System uptime: {} ms', ticks);
  
  SYSTEMTIME st;
  GetLocalTime(&st);
  Console.PrintLn('Current time: {}:{}:{}', st.wHour, st.wMinute, st.wSecond);
  #else
  Console.PrintLn('Windows-only example');
  #endif
end.
```

### Calling POSIX Functions

```myra
module exe PosixDemo;

import Console;

#startcpp header
#ifndef _WIN32
#include <unistd.h>
#include <sys/time.h>
#endif
#endcpp

begin
  #ifndef _WIN32
  pid_t pid = getpid();
  Console.PrintLn('Process ID: {}', pid);
  
  char hostname[256];
  gethostname(hostname, sizeof(hostname));
  Console.PrintLn('Hostname: {}', hostname);
  #else
  Console.PrintLn('POSIX-only example');
  #endif
end.
```

### Wrapping C Libraries

```myra
module lib SqliteWrapper;

#include_header '<sqlite3.h>'
#link 'sqlite3'

type
  public TDatabase = record
    Handle: POINTER;
  end;

#startcpp header
inline bool OpenDatabase(TDatabase& db, const std::string& path) {
    return sqlite3_open(path.c_str(), (sqlite3**)&db.Handle) == SQLITE_OK;
}

inline void CloseDatabase(TDatabase& db) {
    if (db.Handle) {
        sqlite3_close((sqlite3*)db.Handle);
        db.Handle = nullptr;
    }
}
#endcpp

end.
```

## Complete Examples

### Math Functions

```myra
module exe MathDemo;

import Console;

#include_header '<cmath>'

begin
  Console.PrintLn('Math functions:');
  Console.PrintLn('  sqrt(16) = {}', std::sqrt(16.0));
  Console.PrintLn('  pow(2, 10) = {}', std::pow(2.0, 10.0));
  Console.PrintLn('  sin(0) = {}', std::sin(0.0));
  Console.PrintLn('  cos(0) = {}', std::cos(0.0));
  Console.PrintLn('  log(2.718) = {}', std::log(2.718));
  Console.PrintLn('  floor(3.7) = {}', std::floor(3.7));
  Console.PrintLn('  ceil(3.2) = {}', std::ceil(3.2));
end.
```

### File I/O

```myra
module exe FileDemo;

import Console;

#include_header '<fstream>'
#include_header '<string>'

#startcpp header
inline bool WriteFile(const std::string& path, const std::string& content) {
    std::ofstream file(path);
    if (!file) return false;
    file << content;
    return true;
}

inline std::string ReadFile(const std::string& path) {
    std::ifstream file(path);
    if (!file) return "";
    std::string content((std::istreambuf_iterator<char>(file)),
                         std::istreambuf_iterator<char>());
    return content;
}

inline bool FileExists(const std::string& path) {
    std::ifstream file(path);
    return file.good();
}
#endcpp

begin
  Console.PrintLn('File I/O demo:');
  
  if WriteFile('test.txt', 'Hello from Myra!') then
    Console.PrintLn('  File written');
  end;
  
  if FileExists('test.txt') then
    Console.PrintLn('  File exists');
    Console.PrintLn('  Content: {}', ReadFile('test.txt'));
  end;
end.
```

### Timer/Benchmark

```myra
module exe TimerDemo;

import Console;

#include_header '<chrono>'

#startcpp header
class Timer {
    std::chrono::high_resolution_clock::time_point start;
public:
    void Start() {
        start = std::chrono::high_resolution_clock::now();
    }
    
    double ElapsedMs() {
        auto end = std::chrono::high_resolution_clock::now();
        return std::chrono::duration<double, std::milli>(end - start).count();
    }
};

inline Timer globalTimer;
#endcpp

var
  I: INTEGER;
  Sum: INTEGER;

begin
  Console.PrintLn('Benchmark demo:');
  
  globalTimer.Start();
  
  Sum := 0;
  for I := 1 to 1000000 do
    Sum := Sum + I;
  end;
  
  Console.PrintLn('Sum: {}', Sum);
  Console.PrintLn('Time: {} ms', globalTimer.ElapsedMs());
end.
```

### Random Numbers

```myra
module exe RandomDemo;

import Console;

#include_header '<random>'

#startcpp header
inline std::mt19937& GetRng() {
    static std::mt19937 rng(std::random_device{}());
    return rng;
}

inline int RandomInt(int min, int max) {
    std::uniform_int_distribution<int> dist(min, max);
    return dist(GetRng());
}

inline double RandomFloat(double min, double max) {
    std::uniform_real_distribution<double> dist(min, max);
    return dist(GetRng());
}
#endcpp

var
  I: INTEGER;

begin
  Console.PrintLn('Random integers 1-100:');
  for I := 1 to 5 do
    Console.PrintLn('  {}', RandomInt(1, 100));
  end;
  
  Console.PrintLn('Random floats 0-1:');
  for I := 1 to 5 do
    Console.PrintLn('  {}', RandomFloat(0.0, 1.0));
  end;
end.
```

### JSON-like Data

```myra
module exe JsonDemo;

import Console;

#include_header '<map>'
#include_header '<string>'
#include_header '<variant>'
#include_header '<vector>'

#startcpp header
using JsonValue = std::variant<int, double, std::string, bool>;
using JsonObject = std::map<std::string, JsonValue>;

inline void PrintJson(const JsonObject& obj) {
    std::println("{{");
    for (const auto& [key, value] : obj) {
        std::print("  \"{}\": ", key);
        std::visit([](auto&& v) {
            if constexpr (std::is_same_v<std::decay_t<decltype(v)>, std::string>)
                std::println("\"{}\"", v);
            else if constexpr (std::is_same_v<std::decay_t<decltype(v)>, bool>)
                std::println("{}", v ? "true" : "false");
            else
                std::println("{}", v);
        }, value);
    }
    std::println("}}");
}
#endcpp

begin
  Console.PrintLn('JSON-like demo:');
  
  #startcpp
  JsonObject person;
  person["name"] = std::string("Alice");
  person["age"] = 30;
  person["score"] = 95.5;
  person["active"] = true;
  
  PrintJson(person);
  #endcpp
end.
```

## Best Practices

1. **Keep C++ blocks focused** — Small, single-purpose functions
2. **Use header for inline** — Templates and inline functions go in header
3. **Use source for state** — Static variables and complex implementations
4. **Match types carefully** — Be explicit about integer sizes
5. **Handle errors** — Check return values from C++ functions
6. **Document interfaces** — Comment what C++ functions expect

*Myra™ — Pascal. Refined.*
