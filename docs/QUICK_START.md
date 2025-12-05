# Quick Start

Get from zero to working Myra program in 5 minutes.

## Prerequisites

- Windows (64-bit)

## Installation

1. Download the latest release from the [Releases](https://github.com/user/myra/releases) page
2. Extract to a folder (e.g., `C:\myra`)
3. Add the `bin` folder to your PATH

That's it! Everything is bundled:
- Zig compiler (C++ backend)
- LLDB debugger (with DAP support for IDE integration)
- Raylib (static library for game development)
- Standard library (Console, System, Assertions, UnitTest)

Verify installation:
```
myra version
```

## Create a Project

```
myra init HelloWorld
cd HelloWorld
```

This creates a new project with a starter source file.

## Edit the Source

Open `HelloWorld.myra`:

```myra
module exe HelloWorld;

import Console;

begin
  Console.PrintLn('Hello from Myra!');
end.
```

## Build and Run

```
myra build
myra run
```

Output:
```
Hello from Myra!
```

## What Just Happened?

1. `module exe HelloWorld` — Declares an executable module named HelloWorld
2. `import Console` — Imports the Console module for output
3. `begin...end.` — Main program block
4. `Console.PrintLn('...')` — Prints text with newline

Myra transpiled your code to C++23, compiled it with Zig's C++ backend, and produced a native executable.

## A Slightly Bigger Example

```myra
module exe Greeting;

import Console;

var
  Name: STRING;
  Count: INTEGER;

routine SayHello(const AName: STRING; const ATimes: INTEGER);
var
  I: INTEGER;
begin
  for I := 1 to ATimes do
    Console.PrintLn('Hello, {}!', AName);
  end;
end;

begin
  Name := 'World';
  Count := 3;
  SayHello(Name, Count);
end.
```

Output:
```
Hello, World!
Hello, World!
Hello, World!
```

## Next Steps

- [Tutorial](TUTORIAL.md) — Learn Myra step by step
- [Language Reference](LANGUAGE_REFERENCE.md) — Complete specification
- [Examples](EXAMPLES.md) — More code to learn from

*Myra™ — Pascal. Refined.*
