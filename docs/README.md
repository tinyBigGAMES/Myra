# Myra

**Pascal. Refined.**

Myra is a minimal systems programming language, inspired by Niklaus Wirth's Oberon—itself derived from Pascal—that compiles to native executables via C++23. It preserves Pascal's readability and structure while removing decades of accumulated complexity. The result: 45 keywords, 9 built-in types, seamless C++ interoperability, and code that compiles to native executables.

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

```myra
module exe HelloWorld;

import Console;

begin
  Console.PrintLn('Hello from Myra!');
end.
```

Build and run:
```
myra init HelloWorld
cd HelloWorld
myra build
myra run
```

## Documentation

| Document | Description |
|----------|-------------|
| [Quick Start](QUICK_START.md) | Get running in 5 minutes |
| [Tutorial](TUTORIAL.md) | Guided learning path |
| [Language Reference](LANGUAGE_REFERENCE.md) | Complete language specification |
| [Standard Library](STANDARD_LIBRARY.md) | Console, System, Assertions, UnitTest |
| [C++ Interop](CPP_INTEROP.md) | Mixing Myra and C++ code |
| [Build System](BUILD_SYSTEM.md) | Compilation, targets, optimization |
| [Examples](EXAMPLES.md) | Real-world code samples |
| [FAQ](FAQ.md) | Common questions answered |
| [Migration Guide](MIGRATION.md) | Coming from Pascal/Delphi |
| [Contributing](CONTRIBUTING.md) | How to contribute |

## Resources

- **Website:** [myralang.org](https://myralang.org)
- **Repository:** [GitHub](https://github.com/user/myra)

## License

Myra is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.

*Myra™ — Pascal. Refined.*
