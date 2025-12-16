# Myra Changelog

All notable changes to the Myra programming language.

## [1.0.0-alpha.2]

### Added
- FAQ: How to build static libraries using CMake with Myra's Zig toolchain (SDL3 example)
- SDL3 library bundled in `libs/sdl3` (static build)
- New demo project: `sdl3_demo` - demonstrates SDL3 integration with window rendering, HSV color cycling, and animated graphics
- Clean button in Myra Edit editor title bar for quick project cleanup
- Dear ImGui library bundled in `libs/imgui`
- rlImGui library bundled in `libs/rlimgui` (Dear ImGui backend for raylib)
- New demo project: `imgui_demo` - demonstrates Dear ImGui integration with raylib using rlImGui backend
- SQLite library bundled in `libs/sqlite` with header, source, and build script
- New demo project: `sqlite_demo` - demonstrates SQLite database integration with C library interop
- New demo project: `raylib_3d_camera` - demonstrates 3D graphics with first-person camera controls
- Custom file icons for .myra files in Myra Edit
- New code snippets: Unit Test Mode, ABI Directive
- New directives: `#source_path` and `#source_file` for C/C++ source integration

### Changed
- Code snippets updated to use correct Myra syntax
  - Lowercase keywords (module, routine, begin, etc.)
  - Correct module syntax: `module exe|lib|dll Name;`
  - Correct method syntax: `method Name(var Self: TType)`
  - Correct test block syntax: `test 'name'`
  - Correct C++ passthrough: `#startcpp`/`#endcpp`

### Fixed
- Memory leaks in compiler parser when syntax errors occur (added exception cleanup to `ParseRoutine`, `ParseMethod`, `ParseParamsInner`)
- C++ passthrough now uses whitelist approach: defines what IS Myra syntax, everything else passes through as C++
- Myra keywords (`End`, `Else`, etc.) in C++ context now correctly pass through (e.g., `ImGui::End()`)
- Module-level C++ declarations now work without `#startcpp` wrapper (e.g., `inline float x = 0.5f;`)
- Code generation: C++ passthrough statements (like `ImGui::Text(...)`) inside Myra control structures now properly emitted
- Code generation: Fixed double parentheses in `if`/`while`/`repeat` conditions that triggered clang warning
- Code generation: Double quotes in string literals now properly escaped for C++
- Code generation: `String()` casts on numeric types now emit `std::to_string()` instead of invalid `static_cast<std::string>()`
- Code generation: `Double` and `Real` types now correctly emit as `double` in C++
- Memory leak in compiler when parsing fails (AST not freed on early exit)
- Memory leak in `TRoutineTypeSymbol.Params` (now owns param symbols)
- C++ passthrough now properly preserves original source text instead of reconstructing from tokens
- LSP autocomplete now replaces entire word instead of inserting
  - Uses textEdit with range instead of insertText
  - Scans backwards and forwards from cursor to find word boundaries
  - Selecting a completion now replaces the entire word, even when cursor is mid-word
- LSP autocomplete now uses correct casing
  - Keywords: lowercase (module, routine, if, etc.)
  - Types: PascalCase (Integer, String, Boolean, etc.)
  - Constants: PascalCase (True, False)
  - Special: Self, ParamCount, ParamStr

## [1.0.0-alpha.1]
- Initial alpha release
