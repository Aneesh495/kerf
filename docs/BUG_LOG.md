# Bug Log & Resolution Registry

This document records technical defects and compiler edge cases identified during the development of Kerf, along with root cause analyses and permanent verification tests.

---

## Bug 1: LiveScript Implicit Block Pronoun Collision

- Subsystem: Test Runner Harness (`test/test_runner_utils.ls`)
- Symptom: Defining `it = (name, fn) -> ...` threw runtime exception `TypeError: it is not a function`.
- Root Cause: In LiveScript, `it` is a reserved implicit block parameter (similar to `this` or implicit topic variable in comprehensions). Defining a function named `it` was masked by the compiler's implicit pronoun scoping.
- Failing Reproduction:
  ```livescript
  it = (name, fn) -> fn!
  it "test name", -> console.log "hello"
  ```
- Resolution: Renamed the test harness assertion function to `test-case` and added an alias `test: test-case`.
- Regression Test: Verified across all 11 test suites in `test/`.

---

## Bug 2: Multi-Line Arithmetic Expressions in Parentheses

- Subsystem: Matrix Algebra (`src/math/matrix4.ls`)
- Symptom: Determinant calculation in `Matrix4` returned `0.0` for valid non-singular rotation matrices, causing matrix inversion to throw a false singular matrix error.
- Root Cause: In LiveScript, breaking an arithmetic expression across multiple lines inside parentheses where subsequent lines begin with `+` or `-` is parsed as a comma-separated sequence of independent statements rather than a continuous arithmetic sum. The leading unary operators were evaluated independently, and only the final line value was returned.
- Failing Reproduction:
  ```livescript
  det = (
    n41 * (a - b) +
    n42 * (c - d) +
    n43 * (e - f) +
    n44 * (g - h)
  ) # Compiled to comma-separated statements
  ```
- Resolution: Assigned intermediate products to individual terms `term1`, `term2`, `term3`, `term4` and summed them explicitly: `term1 + term2 + term3 + term4`.
- Regression Test: `test/test_bug_fixes.ls` (Bug Regression 1).

---

## Bug 3: Hyphenated Variable Identifiers Ending in Digits

- Subsystem: Slicing Engine (`src/slicing/slicer.ls`)
- Symptom: Assigning `p1-2d = new Point2D(...)` produced compiler error `SyntaxError: invalid assign on line 57`.
- Root Cause: LiveScript supports hyphenated identifiers (e.g. `layer-height`), but when a hyphen is followed by a number or digit (e.g. `-2d`), the lexer parses it as subtraction: `p1 - 2d = ...`. An assignment cannot target a subtraction expression.
- Failing Reproduction:
  ```livescript
  p1-2d = new Point2D 0, 0 # Parsed as (p1 - 2d) = ...
  ```
- Resolution: Renamed variables to avoid hyphen-digit sequences: `p1-xy`, `p2-xy`.
- Regression Test: `src/slicing/slicer.ls` clean compilation pass.

---

## Bug 4: Test Variable Naming with Digit Suffixes

- Subsystem: Infill Test Suite (`test/test_infill.ls`)
- Symptom: Declaring `paths-layer-0 = ...` produced compiler error `SyntaxError: invalid assign on line 28`.
- Root Cause: Analogous to Bug 3, `-0` was treated as subtraction of zero: `paths-layer - 0 = ...`.
- Resolution: Renamed test variables to `paths-layer-a` and `paths-layer-b`.
- Regression Test: `test/test_infill.ls` clean execution.

---

## Bug 5: Bitwise Operator Lexing in LiveScript

- Subsystem: Space-Filling Curve & TPMS Infill (`src/infill/hilbert_infill.ls`, `src/infill/gyroid_infill.ls`)
- Symptom: Using keywords `bitand`, `bitor`, `bitxor` produced compiler errors `Parse error: Unexpected ','`.
- Root Cause: Unlike Python or Lua, LiveScript uses distinct dot-bracketed operators for bitwise logic: `.&.` for bitwise AND, `.|.` for bitwise OR, and `.^.` for bitwise XOR.
- Failing Reproduction:
  ```livescript
  mask = mask bitor 1 # Syntax error
  ```
- Resolution: Converted all bitwise operations to `mask = mask .|. 1`, `rx = 1 .&. Math.floor(t / 2)`, and `ry = 1 .&. (t .^. rx)`.
- Regression Test: `test/test_bug_fixes.ls` (Bug Regression 4).

---

## Bug 6: Reverse Loop Step Syntax

- Subsystem: Trapezoidal Motion Planner (`src/motion/trapezoid_planner.ls`)
- Symptom: Backward loop `for i from (n - 1) down to 0` threw compiler error `SyntaxError: invalid callee on line 50`.
- Root Cause: The syntax `down to` with a space was parsed as calling a function named `down` with an argument `(to 0)`.
- Failing Reproduction:
  ```livescript
  for i from 5 down to 0 => console.log i # Syntax error
  ```
- Resolution: Utilized LiveScript's explicit step loop construct: `for i from (n - 1) to 0 by -1`.
- Regression Test: `test/test_bug_fixes.ls` (Bug Regression 3).

---

## Bug 7: CSS Hex Color Interpolation in Double-Quoted Strings

- Subsystem: SVG Exporter (`src/vis/svg_exporter.ls`)
- Symptom: SVG export threw runtime exception `ReferenceError: e0e0e0 is not defined`.
- Root Cause: LiveScript interprets `#variable` inside multiline double-quoted strings (`"""..."""`) as string interpolation shorthand for `#{variable}`. When encountering `#e0e0e0`, the compiler attempted to look up a runtime variable named `e0e0e0`.
- Failing Reproduction:
  ```livescript
  str = """<text fill="#e0e0e0">Hello</text>""" # Throws ReferenceError
  ```
- Resolution: Converted SVG string assembly to single-quoted strings and explicit concatenation (`'fill="#e0e0e0"'`), avoiding template interpolation on CSS hex codes.
- Regression Test: `test/test_bug_fixes.ls` (Bug Regression 2).
