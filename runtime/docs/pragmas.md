# VM-Specific Pragma Annotations

## Pragmas for general use

These pragmas are part of the VM's API and are safe for use in external code.

| Pragma | Meaning |
| --- | --- |
| `vm:entry-point` | [Defining entry-points into Dart code for an embedder or native methods](compiler/aot/entry_point_pragma.md) |
| `vm:never-inline` | [Never inline a function or method](compiler/pragmas_recognized_by_compiler.md#requesting-a-function-never-be-inlined) |
| `vm:prefer-inline` | [Inline a function or method when possible](compiler/pragmas_recognized_by_compiler.md#requesting-a-function-be-inlined) |
| `vm:notify-debugger-on-exception` | Marks a function that catches exceptions, making the VM treat any caught exception as if they were uncaught. This can be used to notify an attached debugger during debugging, without pausing the app during regular execution. |
| `vm:keep-name` | Will ensure we keep the name of the class/function - even if e.g. obfuscation mode is enabled. |
| `vm:external-name` | Allows to specify an external (native) name for an `external` function. This name is used to lookup native implementation via native resolver associated with the current library through embedding APIs. This is a replacement for legacy VM specific `native "name"` syntax. |
| `vm:invisible` | Allows to mark a function as invisible so it will not appear on stack traces. |
| `vm:always-consider-inlining` | Marks a function which particularly benefits from inlining and specialization in context of the caller (for example, when concrete types of arguments are known). Inliner will not give up after one failed inlining attempt and will continue trying to inline this function. |
| `vm:platform-const` | Marks a static getter or a static field with an initializer where the getter body or field initializer evaluates to a constant value if the target operating system is known. |
| `weak-tearoff-reference` | [Declaring a static weak reference intrinsic method.](compiler/pragmas_recognized_by_compiler.md#declaring-a-static-weak-reference-intrinsic-method) |
| `vm:isolate-unsendable` | Marks a class, instances of which won't be allowed to be passed through ports or sent between isolates. |
| `vm:awaiter-link` | [Specifying variable to follow for awaiter stack unwinding](awaiter_stack_traces.md) |

## Unsafe pragmas for general use

These pragmas are available for use in third-party code but are potentially
unsafe. The use of these pragmas is discouraged unless the developer fully
understands potential repercussions.

| Pragma | Meaning |
| --- | --- |
| `vm:unsafe:no-interrupts` | Removes all `CheckStackOverflow` instructions from the optimized version of the marked function, which disables stack overflow checking and interruption within that function. This pragma exists mainly for performance evaluation and should not be used in a general-purpose code, because VM relies on these checks for OOB message delivery and GC scheduling. |

## Pragmas for internal use

These pragmas can cause unsound behavior if used incorrectly and therefore are only allowed within the core SDK libraries.

| Pragma | Meaning |
| --- | --- |
| `vm:exact-result-type` | [Declaring an exact result type of a method](compiler/pragmas_recognized_by_compiler.md#providing-an-exact-result-type) |
| `vm:recognized` | [Marking this as a recognized method](compiler/pragmas_recognized_by_compiler.md#marking-recognized-methods) |
| `vm:idempotent` | Method marked with this pragma can be repeated or restarted multiple times without change to its effect. Loading, storing of memory values are examples of this, while reads and writes from file are examples of non-idempotent methods. At present, use of this pragma is limited to driving inlining of force-optimized functions. |

## Pragmas ignored in user code

These pragma's are only used on AST nodes synthesized by us, so users defining these will be ignored.

| Pragma | Meaning |
| --- | --- |
| `vm:ffi:native-assets` | [Passing a native assets mapping to the VM](compiler/ffi_pragmas.md) |

## Pragmas for internal testing

These pragmas are used for inspecting or modifying internal VM state and should be used exclusively by SDK tests.
They must be enabled with the `--enable-testing-pragmas` flag.
The names of these pragmas are prefixed with "testing".
Additionally, they are categorized into "safe" and "unsafe" forms: "safe" pragmas should not affect the behavior of the program and can be safely added anywhere, whereas "unsafe" pragmas may change the code's behavior or may cause the VM to crash if used improperly.

| Pragma | Meaning |
| --- | --- |
| `vm:testing.unsafe.trace-entrypoints-fn` | [Observing which flow-graph-level entry-point was used when a function was called](compiler/frontend/testing_trace_entrypoints_pragma.md) |

## Flutter toString transformer pragmas

These pragmas are useful to exclude certain toString methods from toString transformation,
which is enabled with `--delete-tostring-package-uri` option in kernel compilers and
used by Flutter to remove certain toString methods in release mode to reduce size.

| Pragma | Meaning |
| --- | --- |
| `flutter:keep-to-string` | Avoid transforming the annotated toString method. |
| `flutter:keep-to-string-in-subtypes` | Avoid transforming toString methods in all subtypes of the annotated class. |
