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
- LLDB debugger (with DAP support)
- Raylib (static library for game development)
- Myra Edit (VSCodium with full Myra support)
- Language Server (IntelliSense)
- Standard library

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

## Option 1: Use Myra Edit (Recommended)

Open your project in Myra Edit:

```
myra edit
```

This launches a fully-configured development environment with:
- **Syntax highlighting** for Myra and embedded C++
- **Code completion** as you type (Ctrl+Space)
- **Signature help** with parameter hints
- **Real-time error checking** — errors appear as you type
- **Debugging** with breakpoints (F5 to start)
- **Run/Debug buttons** in the editor title bar

### Editor Workflow

1. Edit your code in the editor
2. Press **Ctrl+Shift+B** to build
3. Press **F5** to debug (with breakpoints)
4. Press **Ctrl+F5** to run without debugging

### Setting Breakpoints

Click in the gutter (left margin) next to a line number, or press **F9** on a line.

## Option 2: Command Line

### Edit the Source

Open `src/HelloWorld.myra` in any text editor:

```myra
module exe HelloWorld;

import Console;

begin
  Console.PrintLn('Hello from Myra!');
end.
```

### Build and Run

```
myra build
myra run
```

Output:
```
Hello from Myra!
```

### Debug from Command Line

```
myra debug
```

This starts the integrated debugger. Use commands like `b` (breakpoint), `n` (next), `c` (continue).

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

## Editor Features at a Glance

| Feature | How to Use |
|---------|------------|
| Code Completion | Type and wait, or press Ctrl+Space |
| Signature Help | Type `(` after a routine name |
| Go to Definition | F12 or Ctrl+Click |
| Hover Info | Hover mouse over a symbol |
| Build | Ctrl+Shift+B |
| Run | Ctrl+F5 or click ▶ button |
| Debug | F5 or click 🐛 button |
| Set Breakpoint | Click gutter or F9 |
| Step Over | F10 |
| Step Into | F11 |
| Step Out | Shift+F11 |

## Next Steps

- [Tutorial](TUTORIAL.md) — Learn Myra step by step
- [Language Reference](LANGUAGE_REFERENCE.md) — Complete specification
- [Examples](EXAMPLES.md) — More code to learn from

*Myra™ — Pascal. Refined.*
