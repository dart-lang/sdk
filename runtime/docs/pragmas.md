# VM-Specific Pragma Annotations

## Pragmas for general use

These pragmas are part of the VM's API and are safe for use in external code.

| Pragma | Meaning |
| --- | --- |
| `vm:entry-point` | [Defining entry-points into Dart code for an embedder or native methods](compiler/aot/entry_point_pragma.md) |
| `vm:never-inline` | [Never inline a function or method](compiler/pragmas_recognized_by_compiler.md#requesting-a-function-never-be-inlined)  |
| `vm:prefer-inline` | [Inline a function or method when possible](compiler/pragmas_recognized_by_compiler.md#requesting-a-function-be-inlined)  |

## Pragmas for internal use

These pragmas can cause unsound behavior if used incorrectly and therefore are only allowed within the core SDK libraries.

| Pragma | Meaning |
| --- | --- |
| `vm:exact-result-type` | [Declaring an exact result type of a method](compiler/pragmas_recognized_by_compiler.md#providing-an-exact-result-type) |
| `vm:recognized` | [Marking this as a recognized method](compiler/pragmas_recognized_by_compiler.md#marking-recognized-methods) |

## Pragmas for internal testing

These pragmas are used for inspecting or modifying internal VM state and should be used exclusively by SDK tests.
They must be enabled with the `--enable-testing-pragmas` flag.
The names of these pragmas are prefixed with "testing".
Additionally, they are categorized into "safe" and "unsafe" forms: "safe" pragmas should not affect the behavior of the program and can be safely added anywhere, whereas "unsafe" pragmas may change the code's behavior or may cause the VM to crash if used improperly.

| Pragma | Meaning |
| --- | --- |
| `vm:testing.unsafe.trace-entrypoints-fn` | [Observing which flow-graph-level entry-point was used when a function was called](compiler/frontend/testing_trace_entrypoints_pragma.md) |
