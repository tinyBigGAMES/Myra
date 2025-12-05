# Contributing to Myra

Guide for contributors.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Repository Structure](#repository-structure)
3. [Code Style](#code-style)
4. [Testing](#testing)
5. [Pull Requests](#pull-requests)
6. [Reporting Issues](#reporting-issues)

## Getting Started

### Prerequisites

- Delphi (for compiler development)
- Git

Note: Zig and LLDB are bundled in the release — no need to install separately.

### Clone the Repository

```bash
git clone https://github.com/user/myra.git
cd myra
```

### Build the Compiler

Open the project in Delphi and build, or use the command line build scripts.

### Run Tests

The test suite is run via the **Testbed** project, which is part of the `Myra Language.groupproj` Delphi project group:

1. Open `src/Myra Language.groupproj` in Delphi
2. Build and run the **Testbed** project
3. Testbed compiles and executes test files from `bin/res/tests/`

## Repository Structure

```
myra/
├── src/
│   ├── compiler/           # Compiler source (Delphi)
│   │   ├── Myra.Token.pas      # Lexer tokens
│   │   ├── Myra.Lexer.pas      # Lexical analysis
│   │   ├── Myra.AST.pas        # AST node definitions
│   │   ├── Myra.Parser.pas     # Parser
│   │   ├── Myra.Semantic.pas   # Semantic analysis
│   │   ├── Myra.CodeGen.pas    # C++ code generation
│   │   └── Myra.Compiler.pas   # Main compiler orchestration
│   ├── cli/                 # CLI source (Delphi)
│   ├── testbed/             # Test runner (Delphi)
│   └── Myra Language.groupproj  # Delphi project group
├── bin/
│   └── res/
│       ├── libs/std/       # Standard library
│       │   ├── Console.myra
│       │   ├── System.myra
│       │   ├── Assertions.myra
│       │   └── UnitTest.myra
│       └── tests/          # Test suite
│           ├── tier1/          # Atomic feature tests
│           ├── tier2/          # Integration tests
│           └── errors/         # Error handling tests
├── docs/                   # Documentation
└── .claude/
    ├── docs/               # Language specifications
    └── tasks/              # Development tasks
```

## Code Style

### Delphi Coding Standards

The compiler is written in Delphi. Follow these conventions:

#### Naming

- **Local variables:** Prefix with `L` (e.g., `LResult`, `LToken`)
- **Parameters:** Prefix with `A` (e.g., `AValue`, `ANode`)
- **Fields:** Prefix with `F` (e.g., `FTokens`, `FErrors`)
- **Types:** Prefix with `T` (e.g., `TParser`, `TASTNode`)
- **Pointer types:** Prefix with `P` (e.g., `PNode`)

#### Parameters

- Use `const` by default
- Use `var` only when modification is needed

```pascal
procedure Process(const AValue: Integer);  // Good
procedure Modify(var AResult: Integer);    // When needed
```

#### Units

- One class per unit (generally)
- Unit names prefixed with `Myra.`

#### Example

```pascal
procedure TParser.ParseStatement(const ABlock: TBlockNode);
var
  LToken: TToken;
  LStmt: TASTNode;
begin
  LToken := Current();
  
  case LToken.Kind of
    tkIf: LStmt := ParseIfStatement();
    tkWhile: LStmt := ParseWhileStatement();
    // ...
  end;
  
  if LStmt <> nil then
    ABlock.Statements.Add(LStmt);
  end;
end;
```

### Myra Code Style

For standard library and test code:

- Clear, readable code
- Meaningful identifier names
- Comments for complex logic
- Consistent formatting

## Testing

### Test Structure

```
tests/
├── tier1/              # Atomic feature tests
│   ├── arrays/
│   ├── const/
│   ├── expressions/
│   ├── interop/
│   ├── module/
│   ├── pointers/
│   ├── polymorphism/
│   ├── records/
│   ├── routines/
│   ├── sets/
│   ├── statements/
│   ├── types/
│   └── var/
├── tier2/              # Integration tests
│   ├── edgecases/
│   ├── multimodule/
│   ├── patterns/
│   ├── polymorphism/
│   └── realworld/
└── errors/             # Expected error tests
```

### Writing Tests

#### Tier 1: Atomic Tests

Test a single language feature:

```myra
(*==============================================================================
  Myra™ - Pascal. Refined.

  Test_Feature_Name - Brief description
===============================================================================*)

module exe Test_Feature_Name;

import Console;

// Test code here

begin
  // Verification with output
  PrintLn('Expected: X');
  PrintLn('Actual: {}', Result);
end.
```

#### Tier 2: Integration Tests

Test features working together:

```myra
(*==============================================================================
  Myra™ - Pascal. Refined.

  Test_Integration_Name - Tests X with Y
===============================================================================*)

module exe Test_Integration_Name;

import
  Console,
  System;

// Complex test involving multiple features

begin
  // ...
end.
```

#### Error Tests

Test that invalid code produces correct errors:

```myra
// This should produce error E001
module exe Test_Error_Something;

// Invalid code here

end.
```

### Running Tests

Use the **Testbed** project (in `src/testbed/`) to run tests:

1. Open `Myra Language.groupproj` in Delphi
2. In `UTestbed.pas`, call `TestFile('TestName')` with the test filename
3. Run Testbed — it compiles and executes the test, showing results

For unit tests (using TEST blocks), enable unit test mode in the source:

```myra
#unittestmode ON
```

Then Testbed runs the tests automatically after compilation.

## Pull Requests

### Process

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Add/update tests
5. Ensure all tests pass
6. Submit pull request

### Requirements

- [ ] Code follows style guidelines
- [ ] Tests added for new features
- [ ] All existing tests pass
- [ ] Documentation updated if needed
- [ ] Commit messages are clear

### Commit Messages

```
Short summary (50 chars or less)

Longer description if needed. Explain what and why,
not how (the code shows how).

Fixes #123
```

### Review Process

1. Maintainer reviews code
2. Feedback addressed
3. Tests verified
4. Merged when approved

## Reporting Issues

### Bug Reports

Include:

1. **Myra version**
2. **Operating system**
3. **Minimal code to reproduce**
4. **Expected behavior**
5. **Actual behavior**
6. **Error messages** (if any)

Example:

```
## Bug: Array index out of bounds not detected

**Version:** Myra 1.0.0
**OS:** Windows 11

**Code:**
```myra
var
  Arr: ARRAY[0..4] OF INTEGER;
begin
  Arr[10] := 1;  // Should error
end.
```

**Expected:** Compile-time or runtime error
**Actual:** Compiles without warning, crashes at runtime
```

### Feature Requests

Include:

1. **Description** of the feature
2. **Use case** - why is it needed?
3. **Proposed syntax** (if applicable)
4. **Alternatives** considered

### Security Issues

For security vulnerabilities, please email security@myralang.org instead of opening a public issue.

## Development Tips

### Adding a New Language Feature

1. Update `Myra.Token.pas` if new tokens needed
2. Update `Myra.AST.pas` with new node types
3. Update `Myra.Parser.pas` to parse the feature
4. Update `Myra.Semantic.pas` for type checking
5. Update `Myra.CodeGen.pas` for C++ generation
6. Add tests in appropriate tier1 category
7. Update documentation

### Debugging the Compiler

1. Build in Debug configuration
2. Set breakpoints in Delphi IDE
3. Step through with test input
4. Check AST nodes and symbol table

### Testing C++ Output

1. Compile with `--emit-cpp` to see generated code
2. Check `.h` and `.cpp` files
3. Verify C++ compiles standalone

## Community

- **Issues:** GitHub Issues
- **Discussions:** GitHub Discussions
- **Website:** [myralang.org](https://myralang.org)

*Thank you for contributing to Myra!*
