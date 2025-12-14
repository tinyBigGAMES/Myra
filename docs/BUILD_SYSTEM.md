# Myra Build System

Compilation, targets, and build options.

## Table of Contents

1. [Overview](#overview)
2. [Command Line](#command-line)
3. [Using Zig Directly](#using-zig-directly)
4. [Project Structure](#project-structure)
5. [Module Types](#module-types)
6. [Optimization Levels](#optimization-levels)
7. [Target Platforms](#target-platforms)
8. [Linking](#linking)
9. [Directives](#directives)
10. [Troubleshooting](#troubleshooting)

## Overview

Myra uses a two-stage compilation process:

1. **Transpilation** — Myra source → C++23 code
2. **Compilation** — C++23 → Native executable (via bundled Zig)

```
HelloWorld.myra
      ↓
  [Myra Compiler]
      ↓
HelloWorld.h + HelloWorld.cpp
      ↓
  [Zig C++ Backend]
      ↓
HelloWorld (native executable)
```

### Bundled Tools

Everything is included in the release — no external dependencies:

| Tool | Description |
|------|-------------|
| Zig | C++ compiler backend for native code generation |
| LLDB | Debugger with DAP support for IDE integration |
| Myra Edit | VSCodium with Myra extension, LSP, and debugging |
| raylib | Static library for game/graphics development |
| Standard Library | Console, System, Assertions, UnitTest modules |

## Command Line

### Usage

```
myra <COMMAND> [OPTIONS]
```

### Commands

| Command | Description |
|---------|-------------|
| `init <name> [--template <type>]` | Create a new Myra project |
| `build` | Compile source to C++ and build executable |
| `run` | Execute the compiled program |
| `debug` | Start interactive debugger for compiled program |
| `edit` | Open project in the Myra IDE |
| `clean` | Remove all generated files |
| `zig <args>` | Pass arguments directly to Zig compiler |
| `version` | Display version information |
| `help` | Display help message |

### Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Print help information |
| `--version` | Print version information |
| `-t, --template` | Specify project template type |

### Template Types

| Template | Description |
|----------|-------------|
| `exe` | Executable program (default) |
| `dll` | Dynamic library (.dll on Windows, .so on Linux) |
| `lib` | Static library (.lib on Windows, .a on Linux) |

### Examples

```bash
# Create a new executable project
myra init MyGame

# Create a dynamic library project
myra init MyPlugin --template dll

# Create a static library project
myra init MyLib --template lib

# Open project in IDE
myra edit

# Build the current project
myra build

# Run the compiled executable
myra run

# Debug the compiled executable
myra debug

# Clean generated files
myra clean

# Pass arguments to Zig
myra zig version
myra zig cc -c myfile.c
```

## Using Zig Directly

The `myra zig` command passes arguments directly to the bundled Zig compiler. This is invaluable for building C libraries, compiling individual files, or using any Zig functionality.

### Syntax

```bash
myra zig <arguments>
```

This is equivalent to running `zig <arguments>` directly, using Myra's bundled Zig installation.

### Building C Libraries

Many C libraries (like SQLite) can't be included directly via `#source_file` because Myra applies C++23 flags to all source files. Instead, build them as static libraries:

```bash
# Build SQLite as a static library
cd path/to/sqlite
myra zig build-lib sqlite3.c -OReleaseFast -lc
```

This creates `sqlite3.lib` (Windows) or `libsqlite3.a` (Linux/macOS).

Then link it in your Myra project:

```myra
#include_path 'path/to/sqlite'
#library_path 'path/to/sqlite'
#link 'sqlite3'
#include_header '"sqlite3.h"'
```

### Common Zig Commands

| Command | Description |
|---------|-------------|
| `myra zig version` | Show Zig version |
| `myra zig build-lib file.c -lc` | Build C file as static library |
| `myra zig build-lib file.c -OReleaseFast -lc` | Build optimized static library |
| `myra zig cc -c file.c` | Compile C file to object file |
| `myra zig c++ -c file.cpp` | Compile C++ file to object file |
| `myra zig targets` | List all supported cross-compilation targets |

### Optimization Flags

| Flag | Description |
|------|-------------|
| `-ODebug` | Debug build (default) |
| `-OReleaseSafe` | Optimized with safety checks |
| `-OReleaseFast` | Maximum optimization |
| `-OReleaseSmall` | Optimize for size |

### Example: Building a Complete C Library

```bash
# Navigate to library source
cd myra/bin/res/libs/sqlite

# Build optimized static library
myra zig build-lib sqlite3.c -OReleaseFast -lc

# Result: sqlite3.lib (Windows)
```

Now your Myra project can link against it without C++23 flag conflicts.

### Typical Workflow

```bash
# Create project
myra init HelloWorld
cd HelloWorld

# Open in IDE (recommended)
myra edit

# Or use command line:
# Edit source file manually
myra build
myra run

# Clean when needed
myra clean
```

## Project Structure

When you run `myra init ProjectName`, it creates:

```
ProjectName/
├── src/
│   └── ProjectName.myra    # Main source file
├── generated/              # Transpiled C++ (after build)
│   ├── ProjectName.h
│   └── ProjectName.cpp
├── out/
│   └── bin/
│       └── ProjectName     # Final executable
└── build.zig               # Zig build script (generated)
```

## Module Types

### Executable (exe)

Creates a standalone executable program.

```myra
module exe MyProgram;

import Console;

begin
  Console.PrintLn('Hello!');
end.
```

- Has entry point (`begin...end.`)
- Produces `.exe` (Windows) or binary (Linux/macOS)

### Static Library (lib)

Creates a static library for linking.

```myra
module lib MathLib;

public routine Square(const X: INTEGER): INTEGER;
begin
  return X * X;
end;

end.
```

- No entry point allowed
- Produces `.lib` (Windows) or `.a` (Linux/macOS)
- Linked at compile time

### Dynamic Library (dll)

Creates a shared/dynamic library.

```myra
module dll MyPlugin;

public routine Initialize(): BOOLEAN;
begin
  return TRUE;
end;

public routine Shutdown();
begin
  // cleanup
end;

end.
```

- No entry point allowed
- Produces `.dll` (Windows), `.so` (Linux), or `.dylib` (macOS)
- Loaded at runtime

## Optimization Levels

Set via directive in source file.

### DEBUG

No optimization, full debug info.

```myra
#optimization DEBUG
```

- Fast compilation
- Full debugging support
- Assertions enabled
- No inlining

### RELEASESAFE

Optimized with safety checks.

```myra
#optimization RELEASESAFE
```

- Moderate optimization
- Bounds checking enabled
- Overflow detection
- Good for production with safety

### RELEASEFAST

Maximum performance.

```myra
#optimization RELEASEFAST
```

- Aggressive optimization
- No safety checks
- Maximum speed
- Best for performance-critical code

### RELEASESMALL

Optimized for size.

```myra
#optimization RELEASESMALL
```

- Size optimization
- Minimal binary size
- Good for embedded/constrained environments

## Target Platforms

### Native

Compiles for the current platform.

```myra
#target native
```

### Cross-Compilation Targets

| Target | Description |
|--------|-------------|
| `x86_64-windows` | 64-bit Windows |
| `x86_64-linux` | 64-bit Linux |
| `aarch64-macos` | Apple Silicon macOS |
| `aarch64-linux` | 64-bit ARM Linux |
| `wasm32-wasi` | WebAssembly |

### Example: Cross-Compile for Linux

```myra
#target x86_64-linux

module exe LinuxApp;

import Console;

begin
  Console.PrintLn('Running on Linux!');
end.
```

## Linking

### Static Linking

Link static libraries with `#link`:

```myra
#link 'mylib'
#library_path 'path/to/libs'

module exe MyApp;
// ...
end.
```

### Dynamic Linking

For DLLs/shared libraries:

```myra
#link 'mylib'

module exe MyApp;

routine MyFunction(): INTEGER;
external 'mylib.dll';

begin
  Console.PrintLn('Result: {}', MyFunction());
end.
```

### System Libraries

```myra
#link 'user32'    // Windows
#link 'pthread'   // POSIX threads
#link 'm'         // Math library (Linux)
```

### Library Search Paths

```myra
#library_path 'C:/libs'
#library_path '/usr/local/lib'
#library_path './vendor/lib'
```

## Directives

### Include Directives

```myra
// C++ headers
#include_header '<iostream>'
#include_header '<vector>'
#include_header '"myheader.h"'

// Header search paths
#include_path 'include'
#include_path '/usr/local/include'
```

### Link Directives

```myra
// Libraries to link
#link 'sqlite3'
#link 'opengl32'

// Library search paths
#library_path 'lib'
#library_path 'C:/SDK/lib'
```

### Build Directives

```myra
// Optimization
#optimization DEBUG
#optimization RELEASEFAST

// Target platform
#target native
#target x86_64-windows

// Application type (Windows)
#apptype CONSOLE
#apptype GUI

// ABI for external functions
#abi C
#abi CPP
```

### C/C++ Source Integration

```myra
// Include C/C++ source files directly in compilation
#source_path 'path/to/sources'
#source_file 'path/to/file.cpp'

// Example: Include a C++ wrapper
#source_path 'vendor/src'
#source_file 'vendor/src/wrapper.cpp'
```

**Note:** When including C source files (`.c`), the build system applies C++23 flags which causes errors. For C libraries like SQLite, build them as static libraries first (see [Using Zig Directly](#using-zig-directly)).

### Unit Test Mode

```myra
#unittestmode ON
```

Enables TEST blocks and unit testing framework.

## Debugging

Myra includes both command-line and IDE debugging options.

### Myra Edit Debugging (Recommended)

The easiest way to debug is using Myra Edit:

```bash
myra edit
```

In the editor:
1. Set breakpoints by clicking in the gutter (left margin) or press F9
2. Press F5 to start debugging
3. Use F10 (step over), F11 (step into), Shift+F11 (step out)
4. Inspect variables in the Debug panel
5. View call stack and watch expressions

### Command Line Debugging

Myra also includes an interactive command-line debugger based on LLDB with Debug Adapter Protocol (DAP) support.

### Debugger Location

The debugger components are bundled in `bin/res/lldb/bin/`:

| Component | Description |
|-----------|-------------|
| `lldb-dap.exe` | DAP server (used by Myra's integrated debugger) |
| `lldb.exe` | Command-line LLDB debugger |

### Debug Builds

For debugging, use the DEBUG optimization level:

```myra
#optimization DEBUG
```

This enables:
- Full debug information
- No optimization (preserves code structure)
- Source-level debugging support

### Running the Debugger

Myra includes an interactive debugger REPL. To debug a program:

```bash
myra debug
```

This launches the compiled program under the debugger with full source-level debugging.

### Debugger Commands

| Command | Description |
|---------|-------------|
| `h`, `help` | Show help |
| `b <file>:<line>` | Set breakpoint |
| `bl` | List breakpoints |
| `bd <id>` | Delete breakpoint by ID |
| `bc` | Clear all breakpoints |
| `c` | Continue execution |
| `n` | Step over (next line) |
| `s` | Step into |
| `finish` | Step out |
| `r` | Run/restart program |
| `bt` | Show call stack (backtrace) |
| `locals` | Show local variables |
| `p <expr>` | Print/evaluate expression |
| `threads` | Show threads |
| `verbose on/off` | Toggle DAP message logging |
| `quit` | Exit debugger |

### Breakpoint Directives

Myra supports `#breakpoint` directives that are saved to a `.breakpoints` file during compilation:

```myra
routine ProcessData();
begin
  #breakpoint  // Debugger will stop here
  DoWork();
end;
```

The `.breakpoints` file (JSON format) is automatically loaded when debugging.

## Troubleshooting

### Common Build Errors

#### "Module not found"

The compiler cannot find an imported module.

**Solutions:**
- Check module name matches filename
- Verify file exists in search path
- Use `#unit_path` to add search directories

```myra
#unit_path 'src/modules'
```

#### "Undefined reference"

Linker cannot find a symbol.

**Solutions:**
- Add `#link 'library'` directive
- Add `#library_path` if needed
- Check function signature matches

#### "Cannot find header"

C++ header not found.

**Solutions:**
- Check header path with `#include_path`
- Use correct quotes: `<system>` vs `"local"`

### C++ Compilation Errors

Myra transpiles to C++. If you see C++ errors:

1. Check generated `.cpp` files in build directory
2. Verify C++ syntax in `#startcpp` blocks
3. Ensure included headers exist

### Linker Errors

Common linker issues:

| Error | Cause | Solution |
|-------|-------|----------|
| Undefined reference | Missing library | Add `#link` |
| Cannot find -lxxx | Wrong path | Add `#library_path` |
| Multiple definition | Duplicate symbol | Check for duplicates |

### Platform-Specific Issues

**Windows:**
- Use `.dll` extension for dynamic libraries
- GUI apps need `#apptype GUI`

**Linux:**
- Libraries need `lib` prefix (`libfoo.so`)
- May need `-l` prefix in `#link`

**macOS:**
- Use `.dylib` extension
- May need framework linking

## Build Output Structure

```
project/
├── src/
│   └── MyApp.myra
├── generated/
│   ├── MyApp.h          # Generated header
│   └── MyApp.cpp        # Generated source
├── out/
│   └── bin/
│       └── MyApp        # Final executable
└── build.zig            # Zig build script
```

*Myra™ — Pascal. Refined.*
