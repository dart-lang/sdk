# VM-Specific Pragma Annotations

## Pragmas for general use

These pragmas are part of the VM's API and are safe for use in external code.

- **vm:entry-point**

  [Defining entry-points into Dart code for an embedder or native methods]
  (file://../vm/compiler/aot/entry_points_pragma.md)

## Pragmas for internal use

These pragmas can cause unsound behavior if used incorrectly and therefore are only allowed within the core SDK libraries.

- **vm:exact-result-type**

  [Declaring an exact result type of a method]
  (file://../vm/compiler/result_type_pragma.md)

## Pragmas for internal testing

These pragmas are used for inspecting or modifying internal VM state and should be used exclusively by SDK tests.
They must be enabled with the `--enable-testing-pragmas` flag.
The names of these pragmas are prefixed with "testing".
Additionally, they are categorized into "safe" and "unsafe" forms: "safe" pragmas should not affect the behavior of the program and can be safely added anywhere, whereas "unsafe" pragmas may change the code's behavior or may cause the VM to crash if used improperly.

- **vm:testing.unsafe.trace-entrypoints-fn**

  [Observing which flow-graph-level entry-point was used when a function was called]
  (file://../vm/compiler/frontend/entrypoints_pragma.md)
