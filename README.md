<div align="center">

![Myra](media/logo.png)

[![Chat on Discord](https://img.shields.io/discord/754884471324672040?style=for-the-badge)](https://discord.gg/tPWjMwK)
[![Follow on Bluesky](https://img.shields.io/badge/Bluesky-tinyBigGAMES-blue?style=for-the-badge&logo=bluesky)](https://bsky.app/profile/tinybiggames.com)

A minimal systems programming language that compiles to native executables via C++23.

[Quick Start](#quick-start) • [Documentation](docs/README.md) • [Examples](docs/EXAMPLES.md) • [FAQ](docs/FAQ.md)

</div>

## What is Myra?

Inspired by Niklaus Wirth's Oberon—itself derived from Pascal—Myra preserves Pascal's readability and structure while removing decades of accumulated complexity. The result: **45 keywords**, **9 built-in types**, seamless C++ interoperability, and code that compiles to native executables.

```myra
module exe HelloWorld;

import Console;

begin
  Console.PrintLn('Hello from Myra!');
end.
```

## Key Features

- **Minimal by design** — 45 keywords, 9 types. No redundancy.
- **C++ interoperability** — Mix Myra and C++ freely. No wrappers needed.
- **Batteries included** — Zig compiler, LLDB debugger, raylib, all bundled.
- **Integrated debugger** — Source-level debugging with breakpoints and stepping.
- **Type extension** — Record inheritance without class complexity.
- **Methods** — Bind routines to types with explicit `Self` parameter.
- **Exception handling** — Built-in try/except/finally.
- **Dynamic arrays** — SetLength/Len with automatic memory management.
- **Unit testing** — Built-in TEST blocks for integrated testing.

## Quick Start

### Prerequisites

- Windows (64-bit)

### Installation

1. Download the latest release from the [Releases](https://github.com/user/myra/releases) page
2. Extract to a folder (e.g., `C:\myra`)
3. Add the `bin` folder to your PATH

That's it! Everything is bundled — Zig compiler, LLDB debugger, raylib, and the standard library.

Verify installation:
```bash
myra version
```

### Create Your First Project

```bash
myra init HelloWorld
cd HelloWorld
myra build
myra run
```

Output:
```
Hello from Myra!
```

## Language Overview

### Built-in Types

| Type | Description |
|------|-------------|
| `BOOLEAN` | True or false |
| `CHAR` | Signed single byte character |
| `UCHAR` | Unsigned single byte character |
| `INTEGER` | 64-bit signed integer |
| `UINTEGER` | 64-bit unsigned integer |
| `FLOAT` | 64-bit floating point |
| `STRING` | Auto-managed string |
| `SET` | Bit set for ordinal ranges |
| `POINTER` | Untyped pointer |

### Records and Methods

```myra
type
  TCounter = record
    Value: INTEGER;
  end;

method Increment(var Self: TCounter);
begin
  Self.Value := Self.Value + 1;
end;

method GetValue(var Self: TCounter): INTEGER;
begin
  return Self.Value;
end;

var
  Counter: TCounter;
begin
  Counter.Value := 0;
  Counter.Increment();
  Console.PrintLn('Count: {}', Counter.GetValue());
end.
```

### Type Extension

```myra
type
  TShape = record
    X: INTEGER;
    Y: INTEGER;
  end;

  TCircle = record(TShape)
    Radius: INTEGER;
  end;

var
  Circle: TCircle;
begin
  Circle.X := 100;      // inherited from TShape
  Circle.Y := 100;      // inherited from TShape
  Circle.Radius := 50;  // own field
end.
```

### C++ Integration

Myra's defining feature: seamless C++ integration. If it's not Myra syntax, it's C++.

```myra
module exe CppDemo;

import Console;

#include_header '<cmath>'

#startcpp header
inline int Square(int x) {
    return x * x;
}
#endcpp

begin
  Console.PrintLn('Square(7) = {}', Square(7));
  Console.PrintLn('sqrt(16) = {}', std::sqrt(16.0));
end.
```

### Exception Handling

```myra
try
  DoRiskyOperation();
except
  Console.PrintLn('Error: {}', System.GetExceptionMessage());
finally
  Cleanup();
end;
```

### Unit Testing

```myra
#unittestmode ON

module exe Tests;

import UnitTest;

routine Add(const A: INTEGER; const B: INTEGER): INTEGER;
begin
  return A + B;
end;

begin
end.

test 'Add returns correct sum';
begin
  TestAssertEqual(5, Add(2, 3));
end;
```

## Module Types

| Type | Description |
|------|-------------|
| `module exe Name` | Executable program |
| `module lib Name` | Static library |
| `module dll Name` | Dynamic/shared library |

## Documentation

| Document | Description |
|----------|-------------|
| [Quick Start](docs/QUICK_START.md) | Get running in 5 minutes |
| [Tutorial](docs/TUTORIAL.md) | Guided learning path |
| [Language Reference](docs/LANGUAGE_REFERENCE.md) | Complete specification |
| [Standard Library](docs/STANDARD_LIBRARY.md) | Console, System, Assertions, UnitTest |
| [C++ Interop](docs/CPP_INTEROP.md) | Mixing Myra and C++ code |
| [Build System](docs/BUILD_SYSTEM.md) | Compilation, targets, optimization |
| [Examples](docs/EXAMPLES.md) | Real-world code samples |
| [FAQ](docs/FAQ.md) | Common questions answered |
| [Migration Guide](docs/MIGRATION.md) | Coming from Pascal/Delphi |
| [Contributing](docs/CONTRIBUTING.md) | How to contribute |

## What's Included

Everything you need is bundled in the release:

```
myra/
├── bin/
│   ├── myra.exe              # Myra compiler CLI
│   └── res/
│       ├── libs/
│       │   ├── std/          # Standard library
│       │   │   ├── Console.myra
│       │   │   ├── System.myra
│       │   │   ├── Assertions.myra
│       │   │   └── UnitTest.myra
│       │   └── raylib/       # Raylib (static library)
│       │       ├── include/
│       │       └── lib/
│       ├── lldb/             # LLDB debugger with DAP support
│       │   └── bin/
│       │       ├── lldb-dap.exe
│       │       └── lldb.exe
│       ├── runtime/          # C++ runtime support
│       ├── zig/              # Bundled Zig compiler
│       │   └── zig.exe
│       └── tests/            # Test suite
├── src/                      # Compiler source (Delphi)
└── docs/                     # Documentation
```

## CLI Commands

```bash
myra init <n>              # Create new project
myra init <n> -t lib       # Create static library project
myra init <n> -t dll       # Create dynamic library project
myra build                 # Compile and build
myra run                   # Run the executable
myra debug                 # Run with integrated debugger
myra clean                 # Remove generated files
myra zig <args>            # Pass arguments to Zig
myra version               # Show version
myra help                  # Show help
```

## Integrated Debugger

Myra includes a fully integrated source-level debugger:

```bash
myra debug
```

| Command | Description |
|---------|-------------|
| `b <file>:<line>` | Set breakpoint |
| `bl` | List breakpoints |
| `c` | Continue |
| `n` | Step over |
| `s` | Step into |
| `finish` | Step out |
| `bt` | Backtrace |
| `locals` | Show local variables |
| `p <expr>` | Evaluate expression |
| `r` | Restart program |
| `quit` | Exit debugger |

Use `#breakpoint` directives in code for automatic breakpoints.

## Build Directives

```myra
#optimization DEBUG        // Debug build
#optimization RELEASEFAST  // Maximum performance
#target x86_64-windows     // Cross-compile target
#apptype GUI               // Windows GUI application
#include_header '<vector>' // Include C++ header
#link 'sqlite3'            // Link library
#breakpoint                // Set debugger breakpoint
```

## Philosophy

Myra follows a simple principle:

> **If it's not Myra, it's C++. Emit it.**

This means you can freely mix Myra and C++ code. No wrappers, no bindings, no FFI complexity. Write readable Myra for your application logic, drop to C++ when you need it.

## Requirements

- **Platform:** Windows (64-bit)
- **Dependencies:** None! Everything is bundled in the release:
  - Zig compiler (C++ backend)
  - LLDB debugger (with DAP support for IDE integration)
  - Raylib (static library for game development)
  - Standard library (Console, System, Assertions, UnitTest)

## License

Myra is licensed under the **Apache License 2.0**. See [LICENSE](LICENSE) for details.

## Links

- **Website:** [myralang.org](https://myralang.org)
- **Documentation:** [docs/](docs/README.md)

---

<div align="center">

**Myra™ — Pascal. Refined.**

Copyright © 2025-present tinyBigGAMES™ LLC.  
All Rights Reserved.

</div>
