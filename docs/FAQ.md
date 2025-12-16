# Frequently Asked Questions

Common questions about Myra.

## General

### What is Myra?

Myra is a minimal systems programming language, inspired by Niklaus Wirth's Oberon, that compiles to native executables via C++23. It combines Pascal's readability with seamless C++ interoperability.

### Why another language?

Most Pascal variants have grown complex over decades. Myra strips away that complexity while adding modern C++ integration. The result: readable code with access to the entire C/C++ ecosystem.

### How does Myra compare to Delphi/FreePascal?

| Aspect | Myra | Delphi/FreePascal |
|--------|------|-------------------|
| Keywords | 45 | 60+ |
| Classes | No (records + extension) | Yes |
| Generics | No (use C++) | Yes |
| C++ interop | Native | Via headers/DLLs |
| Build system | Zig | IDE/Make |
| Target | C++23 | Native |

### Is Myra production-ready?

Myra 1.0 is suitable for projects where you value simplicity and C++ access. The language is stable, and the release is fully self-contained — everything you need (Zig compiler, LLDB debugger, raylib, standard library) is bundled.

### What's the license?

Apache License 2.0. Free for commercial and personal use.

## Language

### Why no classes?

Records with type extension provide inheritance without the complexity of classes. Methods bind to types explicitly via `var Self` parameter. This is simpler and equally powerful for most use cases.

```myra
type
  TShape = record
    X: INTEGER;
    Y: INTEGER;
  end;

  TCircle = record(TShape)
    Radius: INTEGER;
  end;

method Draw(var Self: TCircle);
begin
  // ...
end;
```

### Why no generics?

Generics add significant complexity. Myra provides alternatives:

1. **POINTER** for type-agnostic code
2. **C++ templates** via interop
3. **Specific types** (often clearer anyway)

```myra
// Option 1: Use POINTER
routine Sort(const AData: POINTER; const ACount: INTEGER);

// Option 2: Use C++ templates
#startcpp header
template<typename T>
void Sort(std::vector<T>& data) { ... }
#endcpp
```

### Why explicit Self parameter?

It makes method binding explicit and visible. No hidden `this` pointer, no magic.

```myra
method Reset(var Self: TCounter);
begin
  Self.Value := 0;  // Clear what's being modified
end;
```

### Why 64-bit types only?

Modern systems are 64-bit. INTEGER is `int64_t`, FLOAT is `double`. For smaller types, use C++ directly:

```myra
var
  small: int32_t;
  byte: uint8_t;
```

### Can I use 32-bit integers?

Yes, via C++ types:

```myra
var
  Value: int32_t;
  Flags: uint32_t;
```

### How do I do string formatting?

Use `{}` placeholders:

```myra
Console.PrintLn('Name: {}, Age: {}', Name, Age);
Console.PrintLn('Result: {}', X + Y);
```

## Practical

### How do I read/write files?

Use the Files module for file system operations and file I/O:

```myra
import Files;

var
  F: Files.TTextFile;
  Line: STRING;
begin
  // Reading a text file
  Files.AssignTextFile(F, 'data.txt');
  Files.ResetTextFile(F);
  while not Files.EofTextFile(F) do
    Files.ReadLnTextFile(F, Line);
    Console.PrintLn(Line);
  end;
  Files.CloseTextFile(F);
  
  // File system operations
  if Files.FileExists('config.txt') then
    Console.PrintLn('Config found');
  end;
  
  Files.CreateDir('output');
  Files.DeleteFile('temp.txt');
end.
```

See [Standard Library - Files](STANDARD_LIBRARY.md#files) for complete documentation.

### How do I use command line arguments?

Use `ParamCount` and `ParamStr`:

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

### How do I get the current time?

Use the DateTime module:

```myra
import DateTime;

var
  Now: DateTime.TDateTime;
begin
  Now := DateTime.Now();
  Console.PrintLn(DateTime.FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
  Console.PrintLn('Year: {}', DateTime.YearOf(Now));
  Console.PrintLn('Month: {}', DateTime.MonthOf(Now));
  Console.PrintLn('Day: {}', DateTime.DayOf(Now));
end.
```

See [Standard Library - DateTime](STANDARD_LIBRARY.md#datetime) for complete documentation.

### How do I generate random numbers?

Use the Maths module:

```myra
import Maths;

begin
  Maths.Randomize();  // Seed the generator
  
  Console.PrintLn('Random 0-99: {}', Maths.Random(100));
  Console.PrintLn('Random float 0-1: {}', Maths.RandomF());
end.
```

See [Standard Library - Maths](STANDARD_LIBRARY.md#maths) for complete documentation.

### Can I use my favorite C library?

Yes. Include the header, link the library:

```myra
#include_header '<sqlite3.h>'
#link 'sqlite3'

begin
  // Use sqlite3 functions directly
end.
```

### How do I build C libraries for use with Myra?

Use `myra zig` to build C libraries as static libraries:

```bash
# Navigate to library source
cd path/to/library

# Build as static library
myra zig build-lib sqlite3.c -OReleaseFast -lc
```

This creates `sqlite3.lib` (Windows) or `libsqlite3.a` (Linux/macOS).

Then link it in your Myra project:

```myra
#include_path 'path/to/library'
#library_path 'path/to/library'
#link 'sqlite3'
#include_header '"sqlite3.h"'
```

**Why not use `#source_file` for C files?**

Myra's build system applies C++23 flags to all source files, which causes errors with pure C code. Building as a static library first avoids this issue.

See [Build System - Using Zig Directly](BUILD_SYSTEM.md#using-zig-directly) for more details.

### How do I build a static library (like SDL3) using Myra's Zig toolchain?

Myra bundles Zig-based compiler drivers in `bin\res\utils\`:
- `zig-cc.cmd` - C compiler driver
- `zig-cpp.cmd` - C++ compiler driver

These can be used with CMake to build static libraries compatible with Myra.

#### Example: Building SDL3 as a static library

**Prerequisites:**
- CMake installed
- Ninja build system installed
- SDL3 source from https://github.com/libsdl-org/SDL

**Method 1: Command Line**

```cmd
cd path\to\SDL3\source
mkdir build
cd build

cmake -G Ninja ^
  -DCMAKE_C_COMPILER=C:/myra/bin/res/utils/zig-cc.cmd ^
  -DCMAKE_CXX_COMPILER=C:/myra/bin/res/utils/zig-cpp.cmd ^
  -DSDL_STATIC=ON ^
  -DSDL_SHARED=OFF ^
  -DCMAKE_BUILD_TYPE=Release ^
  ..

ninja
```

**Method 2: CMake GUI**

1. Create a `build` folder inside the SDL source directory
2. Open CMake GUI:
   - **Source**: SDL source folder
   - **Build**: The `build` folder
3. Click "Configure", select **Ninja** as the generator
4. Set the following options:
   - `CMAKE_C_COMPILER` = full path to `zig-cc.cmd`
   - `CMAKE_CXX_COMPILER` = full path to `zig-cpp.cmd`
   - `SDL_STATIC` = ON
   - `SDL_SHARED` = OFF
   - `CMAKE_BUILD_TYPE` = Release
5. Click "Configure" again, then "Generate"
6. Open a terminal in the build folder and run: `ninja`

The build produces `libSDL3.a` which can be used with Myra.

### How do I debug Myra programs?

Myra includes both a command-line debugger and full IDE debugging:

**IDE Debugging (Recommended):**
1. Run `myra edit` to open the Myra IDE
2. Set breakpoints by clicking in the gutter or pressing F9
3. Press F5 to start debugging
4. Use F10 (step over), F11 (step into), Shift+F11 (step out)
5. Inspect variables in the Debug panel

**Command Line Debugging:**
1. Use `#optimization DEBUG` for debug builds
2. Run `myra debug` to launch the interactive debugger
3. Use debugger commands: `b` (breakpoint), `c` (continue), `n` (next), `s` (step into), `bt` (backtrace), `locals`, `p` (print)
4. Use `#breakpoint` directives in code for automatic breakpoint generation

### What IDE support exists?

Myra includes a complete IDE (`myra edit`) based on VSCodium with:

- **Syntax highlighting** — Full Myra grammar with C++ passthrough support
- **Code completion** — Keywords, types, and module symbols (e.g., `Console.PrintLn`)
- **Signature help** — Parameter hints with overload support
- **Hover information** — Symbol details on mouse hover
- **Go to definition** — Jump to symbol declarations (F12)
- **Real-time diagnostics** — Errors and warnings as you type
- **Debugging** — Breakpoints, stepping, variable inspection
- **Run/Debug buttons** — Quick access in the editor title bar

The extension also works with VS Code or any VSCodium installation.

## Troubleshooting

### "Unknown identifier" errors

**Cause:** Using a symbol before declaring it, or not importing the module.

**Solutions:**
- Check spelling (identifiers are case-sensitive)
- Ensure the module is imported
- Declare before use

### "Module not found" errors

**Cause:** Compiler can't find the imported module file.

**Solutions:**
- Check filename matches module name
- Use `#unit_path` to add search directories
- Verify file exists

### Linker errors ("undefined reference")

**Cause:** Missing library or wrong function signature.

**Solutions:**
- Add `#link 'library'` directive
- Add `#library_path` if needed
- Check function signature matches

### C++ compilation errors

**Cause:** Invalid C++ in `#startcpp` blocks or passthrough.

**Solutions:**
- Check generated `.cpp` file
- Verify C++ syntax
- Ensure headers are included

### "Cannot convert type" errors

**Cause:** Type mismatch in assignment or parameter.

**Solutions:**
- Check types match exactly
- Use explicit cast if needed
- Use `AS` for type conversion

### Runtime crashes

**Common causes:**
- NIL pointer dereference
- Array out of bounds
- Memory not allocated (forgot NEW)
- Memory already freed (double DISPOSE)

**Debug steps:**
1. Build with `#optimization DEBUG`
2. Add Console.PrintLn to narrow down location
3. Check all pointers before use
4. Verify array indices

## Best Practices

### When should I use Myra vs C++?

**Use Myra for:**
- Application structure
- Business logic
- Readable algorithms
- Data types

**Use C++ for:**
- Performance-critical loops
- System API calls
- Template code
- Existing library wrappers

### How should I organize large projects?

```
project/
├── src/
│   ├── Main.myra          # Entry point
│   ├── Core/
│   │   ├── Types.myra     # Common types
│   │   └── Utils.myra     # Utilities
│   └── Features/
│       ├── Feature1.myra
│       └── Feature2.myra
├── lib/                   # External libraries
├── include/               # C++ headers
└── build/                 # Output
```

### Should I use methods or routines?

**Use methods when:**
- Operating on a specific record type
- Want dot notation: `Object.DoSomething()`
- Building object-like abstractions

**Use routines when:**
- General purpose functions
- Operating on multiple types
- Utility functions

*Myra™ — Pascal. Refined.*
