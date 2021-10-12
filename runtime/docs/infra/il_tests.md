# Writing IL tests for AOT compiler

Usually optimized IL strongly depends on TFA results and which makes it
difficult to test certain AOT optimizations through `run_vm_tests`.

In such cases you can attempt to write an IL test instead. In these tests
test runner will run full AOT pipeline (TFA + `gen_snapshot`), will instruct
`gen_snapshot` to dump flow graphs of specific methods and then run
`pkg/vm/tool/compare_il` helper script to compare expectations. Here is how you
create an IL test.

IL tests are placed in files ending with `_il_test.dart`.

Each IL test should contain one or more _IL matching blocks_, which have the
following format:

```dart
// MatchIL[AOT]=functionName
//   comment
// __ op
//   comment
// __ op
// __ op
// __ op
```

Each section starts with a `// MatchIL[AOT]=functionName` line which contains
the name (or a substring of a name) of the function for which IL should be
matched.

`// MatchIL[AOT]=...` line is followed by some number of comment lines `//`,
where lines starting with `// __ ` specify _an instruction matcher_ and the rest
are ignored (they just act as normal comments).

`gen_snapshot` will be instructed (via `--print-flow-graph-optimized` and
`--print-flow-graph-filter=functionName,...` flags) to dump IL for all
functions names specified in IL matching blocks.

After that `pkg/vm/tool/compare_il` script will be used to compare the dumps
to actual expectations: by checking that dumped flow graph starts with the
expected sequence of commands (ignoring some instructions like `ParallelMove`).

## Example

```dart
// MatchIL[AOT]=factorial
// __ GraphEntry
// __ FunctionEntry
// __ CheckStackOverflow
// __ Branch(EqualityCompare)
@pragma('vm:never-inline')
int factorial(int value) => value == 1 ? value : value * factorial(value - 1);
```

This test specifies that the graph for `factorial` should start with a sequence
`GraphEntry`, `FunctionEntry`, `CheckStackOverflow`, `Branch(EqualityCompare)`.

If the graph has a different shape the test will fail, e.g. given the graph

```
*** BEGIN CFG
After AllocateRegisters
==== file:///.../src/dart/sdk/runtime/tests/vm/dart/aot_prefer_equality_comparison_il_test.dart_::_factorial (RegularFunction)
  0: B0[graph]:0 {
      v3 <- Constant(#1) [1, 1] T{_Smi}
      v19 <- UnboxedConstant(#1 int64) T{_Smi}
}
  2: B1[function entry]:2 {
      v2 <- Parameter(0) [-9223372036854775808, 9223372036854775807] T{int}
}
  4:     CheckStackOverflow:8(stack=0, loop=0)
  5:     ParallelMove rcx <- S+2
  6:     v17 <- BoxInt64(v2) [-9223372036854775808, 9223372036854775807] T{int}
  7:     ParallelMove rax <- rax
  8:     Branch if StrictCompare(===, v17 T{int}, v3) T{bool} goto (3, 4)
```

we will get:

```
Unhandled exception:
Failed to match graph of ==== file:///.../src/dart/sdk/runtime/tests/vm/dart/aot_prefer_equality_comparison_il_test.dart_::_factorial (RegularFunction) to expectations for factorial at instruction 3: got BoxInt64 expected Branch(EqualityCompare)
#0      main (file:///.../src/dart/sdk/pkg/vm/bin/compare_il.dart:37:9)
#1      _delayEntrypointInvocation.<anonymous closure> (dart:isolate-patch/isolate_patch.dart:285:32)
#2      _RawReceivePortImpl._handleMessage (dart:isolate-patch/isolate_patch.dart:187:12)
```
