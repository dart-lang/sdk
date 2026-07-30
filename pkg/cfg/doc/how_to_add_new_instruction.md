# How to add a new instruction to CFG IR

Each instruction represents a minimal operation in the control-flow graph (CFG) intermediate representation (IR).
Instructions may have zero or more inputs, using the results of other instructions in the graph.
An instruction may yield a single result which can be used by zero or more other instructions.

Before adding a new instruction, it is critical to decide what the semantics of
the new instruction would be: what inputs would it take, how it would be used, when it would be
generated, and how it would be optimized.

Make sure you're familiar with all existing instructions before adding a new one.
If there is a similar instruction already, or a new instruction can be represented with
multiple existing instructions, then consider extending or reusing existing instructions instead of adding a new one.

Each instruction kind is represented by a separate class in [ir/instructions.dart](../lib/ir/instructions.dart).
When adding a new instruction, it is useful to pick an existing instruction that is
the most similar to the new one and inspect all its uses. This will give a good example
and starting point when adding all necessary code for the new instruction.

## Add a new instruction class

### Class modifiers

All concrete instruction classes should be declared `final class`.
Common base classes for instructions are declared as `abstract base class`.

### Base class

All instruction classes are subclasses of `Instruction`.
If an instruction yields a value, it should be a subclass of `Definition`.
Basic blocks in the control flow graph extend `Block` and are named `*Block`.
There are also dedicated abstract base classes for certain common classes of instructions such as `CallInstruction`, `LoadField`, `StoreField`, `Box`, `Unbox`.
Always pick the most specific base class when selecting a base class for the new instruction.

### Mixins, interfaces, and corresponding instruction properties

An instruction class should mix in certain mixins and implement certain interfaces
depending on its properties.

| Throwing Dart exceptions                | Instruction class                      |
| --------------------------------------- | -------------------------------------- |
| Never throws Dart exceptions            | Mix in `NoThrow`                       |
| Always throws Dart exceptions           | Mix in `CanThrow`                      |
| Depending on the instruction properties | Override `bool get canThrow`           |

| Visible side-effects (such as writing into the heap) | Instruction class                  |
| ---------------------------------------------------- | ---------------------------------- |
| Never has any visible side-effects                   | Mix in `Pure`                      |
| Always has visible side-effects                      | Mix in `HasSideEffects`            |
| Depending on the instruction properties              | Override `bool get hasSideEffects` |

| Idempotency (i.e., repeating this instruction with the same inputs does not have any effects after executing it once) | Instruction class                  |
| --------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| Always idempotent                                                                                                     | Mix in `Idempotent`                |
| Depending on the instruction properties                                                                               | Override `bool get isIdempotent`   |

Idempotent instructions with extra fields should also define `bool attributesEqual(covariant <InstructionClass> other)` to check if their fields match to be considered idempotent.

If an instruction is intended to be used only by certain back-end(s), then it should mix in `BackendInstruction`.
Such instructions are usually generated during a lowering pass specific to certain back-end(s).

If an instruction ends a basic block, then it should implement the marker interface `ControlFlowInstruction`.

### Constructor

All instruction classes should declare a constructor which takes the following parameters:
- `FlowGraph graph`, usually forwarded to the superclass via `super.graph`.
- `SourcePosition sourcePosition`, usually forwarded to the superclass via `super.sourcePosition`. In rare cases, when an instruction is not related to the source Dart program and doesn't have a corresponding source position, its constructor would not take a `sourcePosition` parameter and would pass `noPosition` to the super constructor.
- (Optional) instruction-specific opcode.
- (Optional) instruction inputs.
- (Optional) other instruction properties such as the type of the instruction result.
- (Optional) named parameter `required super.inputCount` if an instruction takes a variable number of inputs.

### Getters for instruction inputs and properties

If certain inputs of the new instruction have well-defined semantics, consider defining named getters for them, such as
```dart
  Definition get object => inputDefAt(0);
```

Each instruction yielding a value (subclass of `Definition`) should override `CType get type` to compute the type of its result.
The type of the instruction result should be _sound_, i.e., the instruction should always yield a value of this type.

Instructions can also override getters describing the result of the instruction, such as `canBeNull`, `canBeZero`, `canBeNegative`.

All instruction properties should be provable at compile time and monotonic with respect to optimization passes.
For example, if `canBeNull` of the instruction returns `false` at some point, it should remain `false` throughout the rest of the pipeline.
If `canBeNull` returns `true`, then after optimization passes it can return either `true` or `false`.

### Dispatcher for visitors

Each concrete instruction class should define
```dart
  @override
  R accept<R>(InstructionVisitor<R> v) => v.visit<InstructionClass>(this);
```

This method provides class-specific dispatching to instruction visitors.

## Add methods to visitor base classes

[ir/visitor.dart](../lib/ir/visitor.dart) provides a clean way to organize instruction-specific logic without bloating instruction classes via instruction visitors.
For each instruction class, a visitor can define a `visit<InstructionClass>` method to handle instructions of a particular instruction class.

When adding a new instruction class, add a new abstract method to the `InstructionVisitor` interface:
```dart
  R visit<InstructionClass>(<InstructionClass> instr);
```

Also add a new method to the `DefaultInstructionVisitor` mixin class:
```dart
  R visit<InstructionClass>(<InstructionClass> instr) => defaultInstruction(instr);
```
If the new instruction class is a Block, then it should delegate to `defaultBlock(instr)`.
Back-end specific instructions should delegate to `defaultBackendInstruction(instr)`.

## Customize printing of the new instruction

[ir/ir_to_text.dart](../lib/ir/ir_to_text.dart) provides a convenient way to print separate instructions or the whole CFG.
By default, it prints the instruction class name and instruction inputs.
If a new instruction holds other useful attributes such as an instruction-specific opcode, consider printing them as well.

An instruction-specific opcode can be printed in `IrToText.opcode`.
Additional attributes of the new instruction can be printed before or after instruction inputs in `IrToText._printInputs`.

## Update flow graph checker

[ir/flow_graph_checker.dart](../lib/ir/flow_graph_checker.dart) contains the `FlowGraphChecker` pass, which verifies the structural integrity of the CFG IR and maintains
all invariants of IR instructions.

Add a method to verify new instructions:
```dart
  void visit<InstructionClass>(<InstructionClass> instr) {
    // Check instruction invariants throughout optimization pipeline, such as types of inputs.
  }
```

## Generate new instruction when building CFG IR

If a new instruction is not back-end specific and should be generated when building CFG IR,
then the following code should be added.

[ir/flow_graph_builder.dart](../lib/ir/flow_graph_builder.dart) contains a helper class `FlowGraphBuilder` to simplify building CFG IR.
It maintains a simple expression stack, current basic block, current source position, creates and links instructions into the graph, etc.

For a new back-end independent instruction, add a new `add<InstructionClass>` method to `FlowGraphBuilder` to create new instructions.
Something along the lines:
```dart
  <InstructionClass> add<InstructionClass>(<attributes>) {
    // Pop inputs from the expression stack.
    final object = pop();
    // Create a new instruction
    final instr = <InstructionClass>(
      graph,
      currentSourcePosition,
      <attributes>
      <inputs>
    );
    // Push result onto the stack if instruction is a Definition.
    push(instr);
    // Append instruction into the graph.
    appendInstruction(instr);
    // End current basic block if instruction is a ControlFlowInstruction.
    endBlock();
    return instr;
  }
```
Note that `FlowGraphBuilder` is only responsible for creating individual instructions and
should not have any logic specific to the source IR (such as kernel AST).

After that, add logic for generating new instructions into
[front_end/ast_to_ir.dart](../lib/front_end/ast_to_ir.dart) which translates kernel AST to CFG IR or
[front_end/recognized_methods.dart](../lib/front_end/recognized_methods.dart) which generates CFG IR for recognized methods.
This logic should use `FlowGraphBuilder` instead of creating instructions directly.

## Update optimization passes to handle the new instruction

Most optimization passes are instruction visitors and they need to
have a corresponding `visit<InstructionClass>` method for each instruction class.

### Simplification

[passes/simplification.dart](../lib/passes/simplification.dart) contains the implementation of the instruction simplification (canonicalization) pass.

Add the following method to the `Simplification` class:
```dart
  @override
  Instruction visit<InstructionClass>(<InstructionClass> instr) => instr;
```

If the instruction cannot be simplified, canonicalized or constant folded, then `visit<InstructionClass>` should return the original instruction.
Otherwise, it should return the simplified/canonicalized replacement of the instruction.

If an instruction can be constant folded (in case of constant inputs), add the corresponding logic to the simplification pass:
```dart
    final input0 = instr.input0;
    final input1 = instr.input1;
    if (input0 is Constant && input1 is Constant) {
      ConstantValue result = constantFolding.<instructionClass>(input0.value, input1.value);
      return graph.getConstant(result);
    }
```

Actual logic for constant folding the new instruction from constant inputs should be added to the `ConstantFolding` class in
[ir/constant_value.dart](../lib/ir/constant_value.dart) so it can be reused in other optimization passes (e.g., constant propagation).

### Constant propagation

[passes/constant_propagation.dart](../lib/passes/constant_propagation.dart) contains the sparse conditional constant propagation pass.

If an instruction is not a Definition, add an empty `visit<InstructionClass>` method.

If an instruction is a Definition but cannot be constant evaluated even if all inputs
are constant, then add
```dart
  @override
  void visit<InstructionClass>(<InstructionClass> instr) {
    _setNonConstant(instr);
  }
```

Otherwise, add a non-trivial method implementing how this instruction can be replaced with a constant. Something along the lines:
```dart
  @override
  void visit<InstructionClass>(<InstructionClass> instr) {
    if (_isNonConstant(instr.input0) || _isNonConstant(instr.input1)) {
      _setNonConstant(instr);
      return;
    }
    ConstantValue? input0Value = _getConstantValue(instr.input0);
    ConstantValue? input1Value = _getConstantValue(instr.input1);
    if (input0Value != null && input1Value != null) {
      ConstantValue? result = constantFolding.<instructionClass>(input0Value, input1Value);
      _setResult(instr, result);
    }
  }
```

Actual logic for constant folding the new instruction from constant inputs should be added to the `ConstantFolding` class in
[ir/constant_value.dart](../lib/ir/constant_value.dart) so it can be reused in other optimization passes (e.g., simplification).

## Update lowering, code generation and other visitors in the back-ends

### Native back-end

If the new instruction should be lowered (replaced with other instructions during the lowering pass), add a corresponding
`visit<InstructionClass>` to [passes/lowering.dart](../../native_compiler/lib/passes/lowering.dart).

If the new instruction is back-end specific and should be generated during the lowering pass, add corresponding
logic to create the new instruction to [passes/lowering.dart](../../native_compiler/lib/passes/lowering.dart).

If the new instruction is specific to another back-end or should be eliminated during lowering, then add the following method to
[back_end/code_generator.dart](../../native_compiler/lib/back_end/code_generator.dart):
```dart
  @override
  void visit<InstructionClass>(<InstructionClass> instr) =>
      throw 'Unexpected <InstructionClass>';
      // or throw 'Unexpected <InstructionClass> (should be lowered)';
```
and the following method to [back_end/constraints.dart](../../native_compiler/lib/back_end/constraints.dart):
```dart
  @override
  InstructionConstraints? visit<InstructionClass>(<InstructionClass> instr) =>
      throw 'Unexpected <InstructionClass>';
      // or throw 'Unexpected <InstructionClass> (should be lowered)';
```

If the new instruction should reach code generation and register allocation, then it should be handled
in the corresponding `visit<InstructionClass>` methods in the code generator and register allocation constraints for each supported architecture:

- [back_end/arm64/code_generator.dart](../../native_compiler/lib/back_end/arm64/code_generator.dart)
- [back_end/arm64/constraints.dart](../../native_compiler/lib/back_end/arm64/constraints.dart)

## Add IR unit tests

Add test cases involving the new instruction to the IR unit test suite at [pkg/cfg/testcases/](../testcases/).

For back-end specific instructions, add test cases to the IR unit test suite specific to the back-end (for the native back-end: [pkg/native_compiler/testcases/](../../native_compiler/testcases/)).
