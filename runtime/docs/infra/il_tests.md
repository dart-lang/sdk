# Writing IL tests for AOT compiler

Usually optimized IL strongly depends on TFA results and which makes it
difficult to test certain AOT optimizations through `run_vm_tests`.

In such cases you can attempt to write an IL test instead. In these tests
test runner will run full AOT pipeline (TFA + `gen_snapshot`), will instruct
`gen_snapshot` to dump flow graphs of specific methods and then run
`pkg/vm/tool/compare_il` helper script to compare expectations. Here is how you
create an IL test.

IL tests are placed in files ending with `_il_test.dart`.

Each IL test should contain one or more of the functions marked with a
`@pragma('vm:testing:print-flow-graph'[, 'phases filter'])`.

These functions will have their IL dumped at points specified by the
_phases filter_ (if present, `]AllocateRegisters` by default), which follows
the same syntax as `--compiler-passes=` flag and dumped IL will be compared
against the expectations, which are specified programmatically using
`package:vm/testing/il_matchers.dart` helpers. A function named `foo` has
its IL expectations in the function called `matchIL$foo` in the same file.

```dart
import 'package:vm/testing/il_matchers.dart';

@pragma('vm:testing:print-flow-graph')
void foo() {
}

/// Expectations for [foo].
void matchIL$foo(FlowGraph graph) {
  graph.match([/* expectations */]);
}
```

Actual matching is done by the `pkg/vm/tool/compare_il` script.

In order to test IL of the inner (local) function, use
`@pragma('vm:testing:match-inner-flow-graph', 'inner name')`.
Specifying a particular phase is not supported for inner closures.

## Example

```dart
@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int factorial(int value) => value == 1 ? value : value * factorial(value - 1);

void matchIL$factorial(FlowGraph graph) {
  // Expected a graph which starts with GraphEntry block followed by a
  // FunctionEntry block. FunctionEntry block should contain a Branch()
  // instruction, with EqualityCompare as a comparison.
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      match.Branch(match.EqualityCompare(match.any, match.any, kind: '==')),
    ]),
  ]);
}

@pragma('vm:testing:match-inner-flow-graph', 'bar')
void foo() {
  @pragma('vm:testing:print-flow-graph')
  bar() {
  }
}

void matchIL$foo_bar(FlowGraph graph) {
  // Test IL of local bar() in foo().
}
```
