// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names

import '../ir/ir.dart' as ir;
import 'builder.dart';

// TODO(joshualitt): Suggested further optimizations:
//   1) Add size estimates to `_Instruction`, and then remove logic where we
//      need to serialize instructions to get their size.
//   2) Emit binary directly to a filestream, instead of buffering with a
//      Uint8List.

/// Thrown when Wasm bytecode validation fails.
class ValidationError {
  final String trace;
  final String error;

  ValidationError(this.trace, this.error);

  @override
  String toString() => "$trace\n$error";
}

/// Label to use as target for branch instructions.
abstract class Label {
  final List<ir.ValueType> inputs;
  final List<ir.ValueType> outputs;

  late final int? ordinal;
  late final int depth;
  late final int baseStackHeight;
  late final bool reachable;
  late final int localInitializationStackHeight;

  Label._(this.inputs, this.outputs);

  List<ir.ValueType> get targetTypes;

  bool get hasOrdinal => ordinal != null;

  @override
  String toString() => "L$ordinal";
}

class Expression extends Label {
  Expression(List<ir.ValueType> inputs, List<ir.ValueType> outputs)
      : super._(inputs, outputs) {
    ordinal = null;
    depth = 0;
    baseStackHeight = 0;
    reachable = true;
    localInitializationStackHeight = 0;
  }

  @override
  List<ir.ValueType> get targetTypes => outputs;
}

class Block extends Label {
  Block(List<ir.ValueType> inputs, List<ir.ValueType> outputs)
      : super._(inputs, outputs);

  @override
  List<ir.ValueType> get targetTypes => outputs;
}

class Loop extends Label {
  Loop(List<ir.ValueType> inputs, List<ir.ValueType> outputs)
      : super._(inputs, outputs);

  @override
  List<ir.ValueType> get targetTypes => inputs;
}

class If extends Label {
  bool hasElse = false;

  If(List<ir.ValueType> inputs, List<ir.ValueType> outputs)
      : super._(inputs, outputs);

  @override
  List<ir.ValueType> get targetTypes => outputs;
}

class Try extends Label {
  bool hasCatch = false;

  Try(List<ir.ValueType> inputs, List<ir.ValueType> outputs)
      : super._(inputs, outputs);

  @override
  List<ir.ValueType> get targetTypes => outputs;
}

/// A sequence of Wasm instructions.
///
/// Instructions can be added to the sequence by calling the corresponding
/// instruction methods.
///
/// If asserts are enabled, the instruction methods will perform on-the-fly
/// validation and throw a [ValidationError] if validation fails.
class InstructionsBuilder with Builder<ir.Instructions> {
  /// The module containing these instructions.
  final ModuleBuilder module;

  /// Locals declared in this body, including parameters.
  final List<ir.Local> locals = [];

  /// Is this the initializer of a global variable?
  final bool isGlobalInitializer;

  /// Whether a textual trace of the instruction stream should be recorded when
  /// emitting instructions (provided asserts are enabled).
  ///
  /// This trace can be accessed via the [trace] property and will be part of
  /// the exception text if a validation error occurs.
  bool traceEnabled = true;

  /// Column width for the instructions.
  int instructionColumnWidth = 50;

  /// The maximum number of stack slots for which to print the types after each
  /// instruction. When the stack is higher than this, some elements in the
  /// middle of the stack are left out.
  int maxStackShown = 10;

  int _indent = 1;
  final List<String> _traceLines = [];

  int _labelCount = 0;
  final List<Label> _labelStack = [];
  final List<ir.ValueType> _stackTypes = [];
  bool _reachable = true;

  /// Whether each local is currently definitely initialized.
  final List<bool> _localInitialized = [];

  /// Stack of currently initialized non-defaultable locals.
  final List<int> _localInitializationStack = [];

  /// List of instructions.
  final List<ir.Instruction> _instructions = [];

  /// Create a new instruction sequence.
  InstructionsBuilder(this.module, List<ir.ValueType> outputs,
      {this.isGlobalInitializer = false}) {
    _labelStack.add(Expression(const [], outputs));
  }

  /// Whether the current point in the instruction stream is reachable.
  bool get reachable => _reachable;

  /// Whether the instruction sequence has been completed by the final `end`.
  bool get isComplete => _labelStack.isEmpty;

  /// Textual trace of the instructions.
  String get trace => _traceLines.join();

  @override
  ir.Instructions forceBuild() =>
      ir.Instructions(locals, _instructions, _traceLines);

  void _add(ir.Instruction i) => _instructions.add(i);

  ir.Local addLocal(ir.ValueType type, {required bool isParameter}) {
    final local = ir.Local(locals.length, type);
    locals.add(local);
    _localInitialized.add(isParameter || type.defaultable);
    return local;
  }

  bool _initializeLocal(ir.Local local) {
    if (!_localInitialized[local.index]) {
      _localInitialized[local.index] = true;
      _localInitializationStack.add(local.index);
    }
    return true;
  }

  bool _localIsInitialized(ir.Local local) {
    return _localInitialized[local.index];
  }

  void _resetLocalInitialization(Label label) {
    while (_localInitializationStack.length >
        label.localInitializationStackHeight) {
      _localInitialized[_localInitializationStack.removeLast()] = false;
    }
  }

  bool _debugTrace(List<Object>? trace,
      {required bool reachableAfter,
      int indentBefore = 0,
      int indentAfter = 0}) {
    if (traceEnabled && trace != null) {
      _indent += indentBefore;
      String instr = "${"  " * _indent} ${trace.join(" ")}";
      instr = instr.length > instructionColumnWidth - 2
          ? "${instr.substring(0, instructionColumnWidth - 4)}... "
          : instr.padRight(instructionColumnWidth);
      final int stackHeight = _stackTypes.length;
      final String stack = reachableAfter
          ? stackHeight <= maxStackShown
              ? _stackTypes.join(', ')
              : [
                  ..._stackTypes.sublist(0, maxStackShown ~/ 2),
                  "... ${stackHeight - maxStackShown} omitted ...",
                  ..._stackTypes.sublist(stackHeight - (maxStackShown + 1) ~/ 2)
                ].join(', ')
          : "-";
      final String line = "$instr$stack\n";
      _indent += indentAfter;

      _traceLines.add(line);
    }
    return true;
  }

  bool _comment(String text) {
    if (traceEnabled) {
      final String line = "${"  " * _indent} ;; $text\n";
      _traceLines.add(line);
    }
    return true;
  }

  Never _reportError(String error) {
    throw ValidationError(trace, error);
  }

  ir.ValueType get _topOfStack {
    if (!reachable) return ir.RefType.common(nullable: true);
    if (_stackTypes.isEmpty) _reportError("Stack underflow");
    return _stackTypes.last;
  }

  Label get _topOfLabelStack {
    if (_labelStack.isEmpty) _reportError("Label stack underflow");
    return _labelStack.last;
  }

  List<ir.ValueType> _stack(int n) {
    if (_stackTypes.length < n) _reportError("Stack underflow");
    return _stackTypes.sublist(_stackTypes.length - n);
  }

  List<ir.ValueType> _checkStackTypes(List<ir.ValueType> inputs,
      [List<ir.ValueType>? stack]) {
    stack ??= _stack(inputs.length);
    bool typesMatch = true;
    for (int i = 0; i < inputs.length; i++) {
      if (!stack[i].isSubtypeOf(inputs[i])) {
        typesMatch = false;
        break;
      }
    }
    if (!typesMatch) {
      final String expected = inputs.join(', ');
      final String got = stack.join(', ');
      _reportError("Expected [$expected], but stack contained [$got]");
    }
    return stack;
  }

  bool _verifyTypes(List<ir.ValueType> inputs, List<ir.ValueType> outputs,
      {List<Object>? trace, bool reachableAfter = true}) {
    return _verifyTypesFun(inputs, (_) => outputs,
        trace: trace, reachableAfter: reachableAfter);
  }

  bool _verifyTypesFun(List<ir.ValueType> inputs,
      List<ir.ValueType> Function(List<ir.ValueType>) outputsFun,
      {List<Object>? trace, bool reachableAfter = true}) {
    if (!reachable) {
      return _debugTrace(trace, reachableAfter: false);
    }
    final int baseStackHeight = _topOfLabelStack.baseStackHeight;
    if (_stackTypes.length - inputs.length < baseStackHeight) {
      final String expected = inputs.join(', ');
      final String got = _stackTypes.sublist(baseStackHeight).join(', ');
      _reportError(
          "Underflowing base stack of innermost block: expected [$expected], "
          "but stack contained [$got]");
    }
    final List<ir.ValueType> stack = _checkStackTypes(inputs);
    _stackTypes.length -= inputs.length;
    _stackTypes.addAll(outputsFun(stack));
    return _debugTrace(trace, reachableAfter: reachableAfter);
  }

  bool _verifyBranchTypes(Label label,
      [int popped = 0, List<ir.ValueType> pushed = const []]) {
    if (!reachable) {
      return true;
    }
    final List<ir.ValueType> inputs = label.targetTypes;
    if (_stackTypes.length - popped + pushed.length - inputs.length <
        label.baseStackHeight) {
      _reportError("Underflowing base stack of target label");
    }
    final List<ir.ValueType> stack = inputs.length <= pushed.length
        ? pushed.sublist(pushed.length - inputs.length)
        : [
            ..._stackTypes.sublist(
                _stackTypes.length - popped + pushed.length - inputs.length,
                _stackTypes.length - popped),
            ...pushed
          ];
    _checkStackTypes(inputs, stack);
    return true;
  }

  bool _verifyStartOfBlock(Label label, {required List<Object> trace}) {
    return _debugTrace(
        ["$label:", ...trace, ir.FunctionType(label.inputs, label.outputs)],
        reachableAfter: reachable, indentAfter: 1);
  }

  bool _verifyEndOfBlock(List<ir.ValueType> outputs,
      {required List<Object> trace,
      required bool reachableAfter,
      required bool reindent}) {
    final Label label = _topOfLabelStack;
    if (reachable) {
      final int expectedHeight = label.baseStackHeight + label.outputs.length;
      if (_stackTypes.length != expectedHeight) {
        _reportError("Incorrect stack height at end of block"
            " (expected $expectedHeight, actual ${_stackTypes.length})");
      }
      _checkStackTypes(label.outputs);
    }
    if (label.reachable) {
      assert(_stackTypes.length >= label.baseStackHeight);
      _stackTypes.length = label.baseStackHeight;
      _stackTypes.addAll(outputs);
    }
    _resetLocalInitialization(label);
    return _debugTrace([if (label.hasOrdinal) "$label:", ...trace],
        reachableAfter: reachableAfter,
        indentBefore: -1,
        indentAfter: reindent ? 1 : 0);
  }

  // Meta

  /// Emit a comment.
  void comment(String text) {
    assert(_comment(text));
  }

  // Control instructions

  /// Emit an `unreachable` instruction.
  void unreachable() {
    assert(_verifyTypes(const [], const [],
        trace: const ['unreachable'], reachableAfter: false));
    _reachable = false;
    _add(const ir.Unreachable());
  }

  /// Emit a `nop` instruction.
  void nop() {
    assert(_verifyTypes(const [], const [], trace: const ['nop']));
    _add(const ir.Nop());
  }

  Label _pushLabel(Label label, {required List<Object> trace}) {
    assert(_verifyTypes(label.inputs, label.inputs));
    label.ordinal = ++_labelCount;
    label.depth = _labelStack.length;
    label.baseStackHeight = _stackTypes.length - label.inputs.length;
    label.reachable = reachable;
    label.localInitializationStackHeight = _localInitializationStack.length;
    _labelStack.add(label);
    assert(_verifyStartOfBlock(label, trace: trace));
    return label;
  }

  Label _beginBlock(
      Label label,
      ir.Instruction Function() noEffect,
      ir.Instruction Function(ir.ValueType type) oneOutput,
      ir.Instruction Function(ir.FunctionType type) function) {
    if (label.inputs.isEmpty && label.outputs.isEmpty) {
      _add(noEffect());
    } else if (label.inputs.isEmpty && label.outputs.length == 1) {
      _add(oneOutput(label.outputs.single));
    } else {
      _add(function(module.types.defineFunction(label.inputs, label.outputs)));
    }
    return label;
  }

  /// Emit a `block` instruction.
  /// Branching to the returned label will branch to the matching `end`.
  Label block(
          [List<ir.ValueType> inputs = const [],
          List<ir.ValueType> outputs = const []]) =>
      _beginBlock(
          _pushLabel(Block(inputs, outputs), trace: const ['block']),
          ir.BeginNoEffectBlock.new,
          ir.BeginOneOutputBlock.new,
          ir.BeginFunctionBlock.new);

  /// Emit a `loop` instruction.
  /// Branching to the returned label will branch to the `loop`.
  Label loop(
          [List<ir.ValueType> inputs = const [],
          List<ir.ValueType> outputs = const []]) =>
      _beginBlock(
          _pushLabel(Loop(inputs, outputs), trace: const ['loop']),
          ir.BeginNoEffectLoop.new,
          ir.BeginOneOutputLoop.new,
          ir.BeginFunctionLoop.new);

  /// Emit an `if` instruction.
  /// Branching to the returned label will branch to the matching `end`.
  Label if_(
      [List<ir.ValueType> inputs = const [],
      List<ir.ValueType> outputs = const []]) {
    assert(_verifyTypes(const [ir.NumType.i32], const []));
    return _beginBlock(
        _pushLabel(If(inputs, outputs), trace: const ['if']),
        ir.BeginNoEffectIf.new,
        ir.BeginOneOutputIf.new,
        ir.BeginFunctionIf.new);
  }

  /// Emit an `else` instruction.
  void else_() {
    assert(_topOfLabelStack is If ||
        _reportError("Unexpected 'else' (not in 'if' block)"));
    final If label = _topOfLabelStack as If;
    assert(!label.hasElse || _reportError("Duplicate 'else' in 'if' block"));
    assert(_verifyEndOfBlock(label.inputs,
        trace: const ['else'],
        reachableAfter: _topOfLabelStack.reachable,
        reindent: true));
    label.hasElse = true;
    _reachable = _topOfLabelStack.reachable;
    _add(const ir.Else());
  }

  /// Emit a `try` instruction.
  Label try_(
          [List<ir.ValueType> inputs = const [],
          List<ir.ValueType> outputs = const []]) =>
      _beginBlock(
          _pushLabel(Try(inputs, outputs), trace: const ['try']),
          ir.BeginNoEffectTry.new,
          ir.BeginOneOutputTry.new,
          ir.BeginFunctionTry.new);

  /// Emit a `catch` instruction.
  void catch_(ir.Tag tag) {
    assert(_topOfLabelStack is Try ||
        _reportError("Unexpected 'catch' (not in 'try' block)"));
    final Try try_ = _topOfLabelStack as Try;
    assert(_verifyEndOfBlock(tag.type.inputs,
        trace: ['catch', tag], reachableAfter: try_.reachable, reindent: true));
    try_.hasCatch = true;
    _reachable = try_.reachable;
    _add(ir.Catch(tag));
  }

  void catch_all() {
    assert(_topOfLabelStack is Try ||
        _reportError("Unexpected 'catch_all' (not in 'try' block)"));
    final Try try_ = _topOfLabelStack as Try;
    assert(_verifyEndOfBlock([],
        trace: ['catch_all'], reachableAfter: try_.reachable, reindent: true));
    try_.hasCatch = true;
    _reachable = try_.reachable;
    _add(const ir.CatchAll());
  }

  /// Emit a `throw` instruction.
  void throw_(ir.Tag tag) {
    assert(_verifyTypes(tag.type.inputs, const [], trace: ['throw', tag]));
    _reachable = false;
    _add(ir.Throw(tag));
  }

  /// Emit a `rethrow` instruction.
  void rethrow_(Label label) {
    assert(label is Try && label.hasCatch);
    assert(_verifyTypes(const [], const [], trace: ['rethrow', label]));
    _reachable = false;
    _add(ir.Rethrow(_labelIndex(label)));
  }

  /// Emit an `end` instruction.
  void end() {
    assert(_verifyEndOfBlock(_topOfLabelStack.outputs,
        trace: const ['end'],
        reachableAfter: _topOfLabelStack.reachable,
        reindent: false));
    _reachable = _topOfLabelStack.reachable;
    _labelStack.removeLast();
    _add(const ir.End());
  }

  int _labelIndex(Label label) {
    final int index = _labelStack.length - label.depth - 1;
    assert(_labelStack[label.depth] == label);
    return index;
  }

  /// Emit a `br` instruction.
  void br(Label label) {
    assert(_verifyTypes(const [], const [],
        trace: ['br', label], reachableAfter: false));
    assert(_verifyBranchTypes(label));
    _reachable = false;
    _add(ir.Br(_labelIndex(label)));
  }

  /// Emit a `br_if` instruction.
  void br_if(Label label) {
    assert(_verifyTypes(const [ir.NumType.i32], const [],
        trace: ['br_if', label]));
    assert(_verifyBranchTypes(label));
    _add(ir.BrIf(_labelIndex(label)));
  }

  /// Emit a `br_table` instruction.
  void br_table(List<Label> labels, Label defaultLabel) {
    assert(_verifyTypes(const [ir.NumType.i32], const [],
        trace: ['br_table', ...labels, defaultLabel], reachableAfter: false));
    for (var label in labels) {
      assert(_verifyBranchTypes(label));
    }
    assert(_verifyBranchTypes(defaultLabel));
    _reachable = false;
    _add(ir.BrTable(
        labels.map(_labelIndex).toList(), _labelIndex(defaultLabel)));
  }

  /// Emit a `return` instruction.
  void return_() {
    assert(_verifyTypes(_labelStack[0].outputs, const [],
        trace: const ['return'], reachableAfter: false));
    _reachable = false;
    _add(const ir.Return());
  }

  /// Emit a `call` instruction.
  void call(ir.BaseFunction function) {
    assert(_verifyTypes(function.type.inputs, function.type.outputs,
        trace: ['call', function]));
    _add(ir.Call(function));
  }

  /// Emit a `call_indirect` instruction.
  void call_indirect(ir.FunctionType type, [ir.Table? table]) {
    assert(_verifyTypes([...type.inputs, ir.NumType.i32], type.outputs,
        trace: ['call_indirect', type, if (table != null) table.name]));
    _add(ir.CallIndirect(type, table));
  }

  /// Emit a `call_ref` instruction.
  void call_ref(ir.FunctionType type) {
    assert(_verifyTypes(
        [...type.inputs, ir.RefType.def(type, nullable: true)], type.outputs,
        trace: ['call_ref', type]));
    _add(ir.CallRef(type));
  }

  // Parametric instructions

  /// Emit a `drop` instruction.
  void drop() {
    assert(_verifyTypes([_topOfStack], const [], trace: const ['drop']));
    _add(const ir.Drop());
  }

  /// Emit a `select` instruction.
  void select(ir.ValueType type) {
    assert(_verifyTypes([type, type, ir.NumType.i32], [type],
        trace: ['select', type]));
    _add(ir.Select(type));
  }

  // Variable instructions

  /// Emit a `local.get` instruction.
  void local_get(ir.Local local) {
    assert(locals[local.index] == local);
    assert(_verifyTypes(const [], [local.type], trace: ['local.get', local]));
    assert(_localIsInitialized(local) ||
        _reportError("Uninitialized local with non-defaultable type"));
    _add(ir.LocalGet(local));
  }

  /// Emit a `local.set` instruction.
  void local_set(ir.Local local) {
    assert(locals[local.index] == local);
    assert(_verifyTypes([local.type], const [], trace: ['local.set', local]));
    assert(_initializeLocal(local));
    _add(ir.LocalSet(local));
  }

  /// Emit a `local.tee` instruction.
  void local_tee(ir.Local local) {
    assert(locals[local.index] == local);
    assert(
        _verifyTypes([local.type], [local.type], trace: ['local.tee', local]));
    assert(_initializeLocal(local));
    _add(ir.LocalTee(local));
  }

  /// Emit a `global.get` instruction.
  void global_get(ir.Global global) {
    assert(_verifyTypes(const [], [global.type.type],
        trace: ['global.get', global]));
    _add(ir.GlobalGet(global));
  }

  /// Emit a `global.set` instruction.
  void global_set(ir.Global global) {
    assert(global.type.mutable);
    assert(_verifyTypes([global.type.type], const [],
        trace: ['global.set', global]));
    _add(ir.GlobalSet(global));
  }

  // Table instructions

  /// Emit a `table.get` instruction.
  void table_get(ir.Table table) {
    assert(_verifyTypes(const [ir.NumType.i32], [table.type],
        trace: ['table.get', table.name]));
    _add(ir.TableSet(table));
  }

  /// Emit a `table.set` instruction.
  void table_set(ir.Table table) {
    assert(_verifyTypes([ir.NumType.i32, table.type], const [],
        trace: ['table.set', table.name]));
    _add(ir.TableGet(table));
  }

  /// Emit a `table.size` instruction.
  void table_size(ir.Table table) {
    assert(_verifyTypes(const [], const [ir.NumType.i32],
        trace: ['table.size', table.name]));
    _add(ir.TableSize(table));
  }

  // Memory instructions
  void _addMemoryInstruction(
          ir.Instruction Function(ir.MemoryOffsetAlign memory) create,
          ir.Memory memory,
          {required int offset,
          required int align}) =>
      _add(create(ir.MemoryOffsetAlign(memory, offset: offset, align: align)));

  /// Emit an `i32.load` instruction.
  void i32_load(ir.Memory memory, int offset, [int align = 2]) {
    assert(align >= 0 && align <= 2);
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i32],
        trace: ['i32.load', memory.name, offset, align]));
    _addMemoryInstruction(ir.I32Load.new, memory, offset: offset, align: align);
  }

  /// Emit an `i64.load` instruction.
  void i64_load(ir.Memory memory, int offset, [int align = 3]) {
    assert(align >= 0 && align <= 3);
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i64],
        trace: ['i64.load', memory.name, offset, align]));
    _addMemoryInstruction(ir.I64Load.new, memory, offset: offset, align: align);
  }

  /// Emit an `f32.load` instruction.
  void f32_load(ir.Memory memory, int offset, [int align = 2]) {
    assert(align >= 0 && align <= 2);
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.f32],
        trace: ['f32.load', memory.name, offset, align]));
    _addMemoryInstruction(ir.F32Load.new, memory, offset: offset, align: align);
  }

  /// Emit an `f64.load` instruction.
  void f64_load(ir.Memory memory, int offset, [int align = 3]) {
    assert(align >= 0 && align <= 3);
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.f64],
        trace: ['f64.load', memory.name, offset, align]));
    _addMemoryInstruction(ir.F64Load.new, memory, offset: offset, align: align);
  }

  /// Emit an `i32.load8_s` instruction.
  void i32_load8_s(ir.Memory memory, int offset, [int align = 0]) {
    assert(align == 0);
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i32],
        trace: ['i32.load8_s', memory.name, offset, align]));
    _addMemoryInstruction(ir.I32Load8S.new, memory,
        offset: offset, align: align);
  }

  /// Emit an `i32.load8_u` instruction.
  void i32_load8_u(ir.Memory memory, int offset, [int align = 0]) {
    assert(align == 0);
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i32],
        trace: ['i32.load8_u', memory.name, offset, align]));
    _addMemoryInstruction(ir.I32Load8U.new, memory,
        offset: offset, align: align);
  }

  /// Emit an `i32.load16_s` instruction.
  void i32_load16_s(ir.Memory memory, int offset, [int align = 1]) {
    assert(align >= 0 && align <= 1);
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i32],
        trace: ['i32.load16_s', memory.name, offset, align]));
    _addMemoryInstruction(ir.I32Load16S.new, memory,
        offset: offset, align: align);
  }

  /// Emit an `i32.load16_u` instruction.
  void i32_load16_u(ir.Memory memory, int offset, [int align = 1]) {
    assert(align >= 0 && align <= 1);
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i32],
        trace: ['i32.load16_u', memory.name, offset, align]));
    _addMemoryInstruction(ir.I32Load16U.new, memory,
        offset: offset, align: align);
  }

  /// Emit an `i64.load8_s` instruction.
  void i64_load8_s(ir.Memory memory, int offset, [int align = 0]) {
    assert(align == 0);
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i64],
        trace: ['i64.load8_s', memory.name, offset, align]));
    _addMemoryInstruction(ir.I64Load8S.new, memory,
        offset: offset, align: align);
  }

  /// Emit an `i64.load8_u` instruction.
  void i64_load8_u(ir.Memory memory, int offset, [int align = 0]) {
    assert(align == 0);
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i64],
        trace: ['i64.load8_u', memory.name, offset, align]));
    _addMemoryInstruction(ir.I64Load8U.new, memory,
        offset: offset, align: align);
  }

  /// Emit an `i64.load16_s` instruction.
  void i64_load16_s(ir.Memory memory, int offset, [int align = 1]) {
    assert(align >= 0 && align <= 1);
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i64],
        trace: ['i64.load16_s', memory.name, offset, align]));
    _addMemoryInstruction(ir.I64Load16S.new, memory,
        offset: offset, align: align);
  }

  /// Emit an `i64.load16_u` instruction.
  void i64_load16_u(ir.Memory memory, int offset, [int align = 1]) {
    assert(align >= 0 && align <= 1);
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i64],
        trace: ['i64.load16_u', memory.name, offset, align]));
    _addMemoryInstruction(ir.I64Load16U.new, memory,
        offset: offset, align: align);
  }

  /// Emit an `i64.load32_s` instruction.
  void i64_load32_s(ir.Memory memory, int offset, [int align = 2]) {
    assert(align >= 0 && align <= 2);
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i64],
        trace: ['i64.load32_s', memory.name, offset, align]));
    _addMemoryInstruction(ir.I64Load32S.new, memory,
        offset: offset, align: align);
  }

  /// Emit an `i64.load32_u` instruction.
  void i64_load32_u(ir.Memory memory, int offset, [int align = 2]) {
    assert(align >= 0 && align <= 2);
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i64],
        trace: ['i64.load32_u', memory.name, offset, align]));
    _addMemoryInstruction(ir.I64Load32U.new, memory,
        offset: offset, align: align);
  }

  /// Emit an `i32.store` instruction.
  void i32_store(ir.Memory memory, int offset, [int align = 2]) {
    assert(align >= 0 && align <= 2);
    assert(_verifyTypes(const [ir.NumType.i32, ir.NumType.i32], const [],
        trace: ['i32.store', memory.name, offset, align]));
    _addMemoryInstruction(ir.I32Store.new, memory,
        offset: offset, align: align);
  }

  /// Emit an `i64.store` instruction.
  void i64_store(ir.Memory memory, int offset, [int align = 3]) {
    assert(align >= 0 && align <= 3);
    assert(_verifyTypes(const [ir.NumType.i32, ir.NumType.i64], const [],
        trace: ['i64.store', memory.name, offset, align]));
    _addMemoryInstruction(ir.I64Store.new, memory,
        offset: offset, align: align);
  }

  /// Emit an `f32.store` instruction.
  void f32_store(ir.Memory memory, int offset, [int align = 2]) {
    assert(align >= 0 && align <= 2);
    assert(_verifyTypes(const [ir.NumType.i32, ir.NumType.f32], const [],
        trace: ['f32.store', memory.name, offset, align]));
    _addMemoryInstruction(ir.F32Store.new, memory,
        offset: offset, align: align);
  }

  /// Emit an `f64.store` instruction.
  void f64_store(ir.Memory memory, int offset, [int align = 3]) {
    assert(align >= 0 && align <= 3);
    assert(_verifyTypes(const [ir.NumType.i32, ir.NumType.f64], const [],
        trace: ['f64.store', memory.name, offset, align]));
    _addMemoryInstruction(ir.F64Store.new, memory,
        offset: offset, align: align);
  }

  /// Emit an `i32.store8` instruction.
  void i32_store8(ir.Memory memory, int offset, [int align = 0]) {
    assert(align == 0);
    assert(_verifyTypes(const [ir.NumType.i32, ir.NumType.i32], const [],
        trace: ['i32.store8', memory.name, offset, align]));
    _addMemoryInstruction(ir.I32Store8.new, memory,
        offset: offset, align: align);
  }

  /// Emit an `i32.store16` instruction.
  void i32_store16(ir.Memory memory, int offset, [int align = 1]) {
    assert(align >= 0 && align <= 1);
    assert(_verifyTypes(const [ir.NumType.i32, ir.NumType.i32], const [],
        trace: ['i32.store16', memory.name, offset, align]));
    _addMemoryInstruction(ir.I32Store16.new, memory,
        offset: offset, align: align);
  }

  /// Emit an `i64.store8` instruction.
  void i64_store8(ir.Memory memory, int offset, [int align = 0]) {
    assert(align == 0);
    assert(_verifyTypes(const [ir.NumType.i32, ir.NumType.i64], const [],
        trace: ['i64.store8', memory.name, offset, align]));
    _addMemoryInstruction(ir.I64Store8.new, memory,
        offset: offset, align: align);
  }

  /// Emit an `i64.store16` instruction.
  void i64_store16(ir.Memory memory, int offset, [int align = 1]) {
    assert(align >= 0 && align <= 1);
    assert(_verifyTypes(const [ir.NumType.i32, ir.NumType.i64], const [],
        trace: ['i64.store16', memory.name, offset, align]));
    _addMemoryInstruction(ir.I64Store16.new, memory,
        offset: offset, align: align);
  }

  /// Emit an `i64.store32` instruction.
  void i64_store32(ir.Memory memory, int offset, [int align = 2]) {
    assert(align >= 0 && align <= 2);
    assert(_verifyTypes(const [ir.NumType.i32, ir.NumType.i64], const [],
        trace: ['i64.store32', memory.name, offset, align]));
    _addMemoryInstruction(ir.I64Store32.new, memory,
        offset: offset, align: align);
  }

  /// Emit a `memory.size` instruction.
  void memory_size(ir.Memory memory) {
    assert(_verifyTypes(const [], const [ir.NumType.i32]));
    _add(ir.MemorySize(memory));
  }

  /// Emit a `memory.grow` instruction.
  void memory_grow(ir.Memory memory) {
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i32]));
    _add(ir.MemoryGrow(memory));
  }

  // Reference instructions

  /// Emit a `ref.null` instruction.
  void ref_null(ir.HeapType heapType) {
    assert(_verifyTypes(const [], [ir.RefType(heapType, nullable: true)],
        trace: ['ref.null', heapType]));
    _add(ir.RefNull(heapType));
  }

  /// Emit a `ref.is_null` instruction.
  void ref_is_null() {
    assert(_verifyTypes(
        const [ir.RefType.common(nullable: true)], const [ir.NumType.i32],
        trace: const ['ref.is_null']));
    _add(const ir.RefIsNull());
  }

  /// Emit a `ref.func` instruction.
  void ref_func(ir.BaseFunction function) {
    assert(_verifyTypes(
        const [], [ir.RefType.def(function.type, nullable: false)],
        trace: ['ref.func', function]));
    _add(ir.RefFunc(function));
  }

  /// Emit a `ref.as_non_null` instruction.
  void ref_as_non_null() {
    assert(_verifyTypes(const [ir.RefType.common(nullable: true)],
        [_topOfStack.withNullability(false)],
        trace: const ['ref.as_non_null']));
    _add(const ir.RefAsNonNull());
  }

  /// Emit a `br_on_null` instruction.
  void br_on_null(Label label) {
    assert(_verifyTypes(const [ir.RefType.common(nullable: true)],
        [_topOfStack.withNullability(false)],
        trace: ['br_on_null', label]));
    assert(_verifyBranchTypes(label, 1));
    _add(ir.BrOnNull(_labelIndex(label)));
  }

  /// Emit a `ref.eq` instruction.
  void ref_eq() {
    assert(_verifyTypes(
        const [ir.RefType.eq(nullable: true), ir.RefType.eq(nullable: true)],
        const [ir.NumType.i32],
        trace: const ['ref.eq']));
    _add(const ir.RefEq());
  }

  /// Emit a `br_on_non_null` instruction.
  void br_on_non_null(Label label) {
    assert(_verifyBranchTypes(label, 1, [_topOfStack.withNullability(false)]));
    assert(_verifyTypes(const [ir.RefType.common(nullable: true)], const [],
        trace: ['br_on_non_null', label]));
    _add(ir.BrOnNonNull(_labelIndex(label)));
  }

  /// Emit a `struct.get` instruction.
  void struct_get(ir.StructType structType, int fieldIndex) {
    assert(structType.fields[fieldIndex].type is ir.ValueType);
    assert(_verifyTypes([ir.RefType.def(structType, nullable: true)],
        [structType.fields[fieldIndex].type.unpacked],
        trace: ['struct.get', structType, fieldIndex]));
    _add(ir.StructGet(structType, fieldIndex));
  }

  /// Emit a `struct.get_s` instruction.
  void struct_get_s(ir.StructType structType, int fieldIndex) {
    assert(structType.fields[fieldIndex].type is ir.PackedType);
    assert(_verifyTypes([ir.RefType.def(structType, nullable: true)],
        [structType.fields[fieldIndex].type.unpacked],
        trace: ['struct.get_s', structType, fieldIndex]));
    _add(ir.StructGetS(structType, fieldIndex));
  }

  /// Emit a `struct.get_u` instruction.
  void struct_get_u(ir.StructType structType, int fieldIndex) {
    assert(structType.fields[fieldIndex].type is ir.PackedType);
    assert(_verifyTypes([ir.RefType.def(structType, nullable: true)],
        [structType.fields[fieldIndex].type.unpacked],
        trace: ['struct.get_u', structType, fieldIndex]));
    _add(ir.StructGetU(structType, fieldIndex));
  }

  /// Emit a `struct.set` instruction.
  void struct_set(ir.StructType structType, int fieldIndex) {
    assert(_verifyTypes([
      ir.RefType.def(structType, nullable: true),
      structType.fields[fieldIndex].type.unpacked
    ], const [], trace: [
      'struct.set',
      structType,
      fieldIndex
    ]));
    _add(ir.StructSet(structType, fieldIndex));
  }

  /// Emit a `struct.new` instruction.
  void struct_new(ir.StructType structType) {
    assert(_verifyTypes([...structType.fields.map((f) => f.type.unpacked)],
        [ir.RefType.def(structType, nullable: false)],
        trace: ['struct.new', structType]));
    _add(ir.StructNew(structType));
  }

  /// Emit a `struct.new_default` instruction.
  void struct_new_default(ir.StructType structType) {
    assert(_verifyTypes(const [], [ir.RefType.def(structType, nullable: false)],
        trace: ['struct.new_default', structType]));
    _add(ir.StructNewDefault(structType));
  }

  /// Emit an `array.get` instruction.
  void array_get(ir.ArrayType arrayType) {
    assert(arrayType.elementType.type is ir.ValueType);
    assert(_verifyTypes(
        [ir.RefType.def(arrayType, nullable: true), ir.NumType.i32],
        [arrayType.elementType.type.unpacked],
        trace: ['array.get', arrayType]));
    _add(ir.ArrayGet(arrayType));
  }

  /// Emit an `array.get_s` instruction.
  void array_get_s(ir.ArrayType arrayType) {
    assert(arrayType.elementType.type is ir.PackedType);
    assert(_verifyTypes(
        [ir.RefType.def(arrayType, nullable: true), ir.NumType.i32],
        [arrayType.elementType.type.unpacked],
        trace: ['array.get_s', arrayType]));
    _add(ir.ArrayGetS(arrayType));
  }

  /// Emit an `array.get_u` instruction.
  void array_get_u(ir.ArrayType arrayType) {
    assert(arrayType.elementType.type is ir.PackedType);
    assert(_verifyTypes(
        [ir.RefType.def(arrayType, nullable: true), ir.NumType.i32],
        [arrayType.elementType.type.unpacked],
        trace: ['array.get_u', arrayType]));
    _add(ir.ArrayGetU(arrayType));
  }

  /// Emit an `array.set` instruction.
  void array_set(ir.ArrayType arrayType) {
    assert(_verifyTypes([
      ir.RefType.def(arrayType, nullable: true),
      ir.NumType.i32,
      arrayType.elementType.type.unpacked
    ], const [], trace: [
      'array.set',
      arrayType
    ]));
    _add(ir.ArraySet(arrayType));
  }

  /// Emit an `array.len` instruction.
  void array_len() {
    assert(_verifyTypes(
        [ir.RefType.array(nullable: true)], const [ir.NumType.i32],
        trace: ['array.len']));
    _add(const ir.ArrayLen());
  }

  /// Emit an `array.new_fixed` instruction.
  void array_new_fixed(ir.ArrayType arrayType, int length) {
    ir.ValueType elementType = arrayType.elementType.type.unpacked;
    assert(_verifyTypes([...List.filled(length, elementType)],
        [ir.RefType.def(arrayType, nullable: false)],
        trace: ['array.new_fixed', arrayType, length]));
    _add(ir.ArrayNewFixed(arrayType, length));
  }

  /// Emit an `array.new` instruction.
  void array_new(ir.ArrayType arrayType) {
    assert(_verifyTypes([arrayType.elementType.type.unpacked, ir.NumType.i32],
        [ir.RefType.def(arrayType, nullable: false)],
        trace: ['array.new', arrayType]));
    _add(ir.ArrayNew(arrayType));
  }

  /// Emit an `array.new_default` instruction.
  void array_new_default(ir.ArrayType arrayType) {
    assert(_verifyTypes(
        [ir.NumType.i32], [ir.RefType.def(arrayType, nullable: false)],
        trace: ['array.new_default', arrayType]));
    _add(ir.ArrayNewDefault(arrayType));
  }

  /// Emit an `array.new_data` instruction.
  void array_new_data(ir.ArrayType arrayType, ir.BaseDataSegment data) {
    assert(arrayType.elementType.type.isPrimitive);
    assert(_verifyTypes([ir.NumType.i32, ir.NumType.i32],
        [ir.RefType.def(arrayType, nullable: false)],
        trace: ['array.new_data', arrayType, data.index]));
    _add(ir.ArrayNewData(arrayType, data));
    if (isGlobalInitializer) module.dataReferencedFromGlobalInitializer = true;
  }

  /// Emit an `array.copy` instruction.
  void array_copy(ir.ArrayType destArrayType, ir.ArrayType sourceArrayType) {
    assert(_verifyTypes([
      ir.RefType.def(destArrayType, nullable: true), // dest
      ir.NumType.i32, // dest_offset
      ir.RefType.def(sourceArrayType, nullable: true), // source
      ir.NumType.i32, // source_offset
      ir.NumType.i32 // size
    ], [], trace: [
      'array.copy',
      destArrayType,
      sourceArrayType
    ]));
    _add(ir.ArrayCopy(
        destArrayType: destArrayType, sourceArrayType: sourceArrayType));
  }

  /// Emit an `array.fill` instruction.
  void array_fill(ir.ArrayType arrayType) {
    assert(_verifyTypes([
      ir.RefType.def(arrayType, nullable: true),
      ir.NumType.i32, // offset
      arrayType.elementType.type.unpacked, // fill value
      ir.NumType.i32 // size
    ], [], trace: [
      'array.copy',
      arrayType,
    ]));
    _add(ir.ArrayFill(arrayType));
  }

  /// Emit an `i31.new` instruction.
  void i31_new() {
    assert(_verifyTypes(
        const [ir.NumType.i32], const [ir.RefType.i31(nullable: false)],
        trace: const ['i31.new']));
    _add(const ir.I31New());
  }

  /// Emit an `i31.get_s` instruction.
  void i31_get_s() {
    assert(_verifyTypes(
        const [ir.RefType.i31(nullable: false)], const [ir.NumType.i32],
        trace: const ['i31.get_s']));
    _add(const ir.I31GetS());
  }

  /// Emit an `i31.get_u` instruction.
  void i31_get_u() {
    assert(_verifyTypes(
        const [ir.RefType.i31(nullable: false)], const [ir.NumType.i32],
        trace: const ['i31.get_u']));
    _add(const ir.I31GetU());
  }

  bool _verifyCast(
      ir.RefType inputType, ir.RefType targetType, ir.ValueType outputType,
      {List<Object>? trace}) {
    _verifyTypes([inputType], [outputType], trace: trace);
    if (!targetType.isSubtypeOf(inputType)) {
      _reportError("Target type '$targetType' not a subtype of "
          "input type '$inputType' in cast");
    }
    return true;
  }

  /// Emit a `ref.test` instruction.
  void ref_test(ir.RefType targetType) {
    assert(_verifyCast(ir.RefType(targetType.heapType.topType, nullable: true),
        targetType, ir.NumType.i32, trace: [
      'ref.test',
      if (targetType.nullable) 'null',
      targetType.heapType
    ]));
    _add(ir.RefTest(targetType));
  }

  /// Emit a `ref.cast` instruction.
  void ref_cast(ir.RefType targetType) {
    assert(_verifyCast(ir.RefType(targetType.heapType.topType, nullable: true),
        targetType, targetType, trace: [
      'ref.cast',
      if (targetType.nullable) 'null',
      targetType.heapType
    ]));
    _add(ir.RefCast(targetType));
  }

  /// Emit a `br_on_cast` instruction.
  void br_on_cast(Label label, ir.RefType inputType, ir.RefType targetType) {
    assert(_verifyCast(inputType, targetType,
        inputType.withNullability(inputType.nullable && !targetType.nullable),
        trace: [
          'br_on_cast',
          label,
          if (inputType.nullable) 'null',
          inputType.heapType,
          if (targetType.nullable) 'null',
          targetType.heapType
        ]));
    assert(_verifyBranchTypes(label, 1, [targetType]));
    _add(ir.BrOnCast(_labelIndex(label), inputType, targetType));
  }

  /// Emit a `br_on_cast_fail` instruction.
  void br_on_cast_fail(
      Label label, ir.RefType inputType, ir.RefType targetType) {
    assert(_verifyCast(inputType, targetType, targetType, trace: [
      'br_on_cast_fail',
      label,
      if (inputType.nullable) 'null',
      inputType.heapType,
      if (targetType.nullable) 'null',
      targetType.heapType
    ]));
    assert(_verifyBranchTypes(label, 1, [
      inputType.withNullability(inputType.nullable && !targetType.nullable)
    ]));
    _add(ir.BrOnCastFail(_labelIndex(label), inputType, targetType));
  }

  /// Emit an `extern.internalize` instruction.
  void extern_internalize() {
    assert(_verifyTypesFun(const [ir.RefType.extern(nullable: true)],
        (inputs) => [ir.RefType.any(nullable: inputs.single.nullable)],
        trace: ['extern.internalize']));
    _add(const ir.ExternInternalize());
  }

  /// Emit an `extern.externalize` instruction.
  void extern_externalize() {
    assert(_verifyTypesFun(const [ir.RefType.any(nullable: true)],
        (inputs) => [ir.RefType.extern(nullable: inputs.single.nullable)],
        trace: ['extern.externalize']));
    _add(const ir.ExternExternalize());
  }

  // Numeric instructions

  /// Emit an `i32.const` instruction.
  void i32_const(int value) {
    assert(_verifyTypes(const [], const [ir.NumType.i32],
        trace: ['i32.const', value]));
    assert(-1 << 31 <= value && value < 1 << 31);
    _add(ir.I32Const(value));
  }

  /// Emit an `i64.const` instruction.
  void i64_const(int value) {
    assert(_verifyTypes(const [], const [ir.NumType.i64],
        trace: ['i64.const', value]));
    _add(ir.I64Const(value));
  }

  /// Emit an `f32.const` instruction.
  void f32_const(double value) {
    assert(_verifyTypes(const [], const [ir.NumType.f32],
        trace: ['f32.const', value]));
    _add(ir.F32Const(value));
  }

  /// Emit an `f64.const` instruction.
  void f64_const(double value) {
    assert(_verifyTypes(const [], const [ir.NumType.f64],
        trace: ['f64.const', value]));
    _add(ir.F64Const(value));
  }

  /// Emit an `i32.eqz` instruction.
  void i32_eqz() {
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.eqz']));
    _add(const ir.I32Eqz());
  }

  /// Emit an `i32.eq` instruction.
  void i32_eq() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.eq']));
    _add(const ir.I32Eq());
  }

  /// Emit an `i32.ne` instruction.
  void i32_ne() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.ne']));
    _add(const ir.I32Ne());
  }

  /// Emit an `i32.lt_s` instruction.
  void i32_lt_s() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.lt_s']));
    _add(const ir.I32LtS());
  }

  /// Emit an `i32.lt_u` instruction.
  void i32_lt_u() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.lt_u']));
    _add(const ir.I32LtU());
  }

  /// Emit an `i32.gt_s` instruction.
  void i32_gt_s() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.gt_s']));
    _add(const ir.I32GtS());
  }

  /// Emit an `i32.gt_u` instruction.
  void i32_gt_u() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.gt_u']));
    _add(const ir.I32GtU());
  }

  /// Emit an `i32.le_s` instruction.
  void i32_le_s() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.le_s']));
    _add(const ir.I32LeS());
  }

  /// Emit an `i32.le_u` instruction.
  void i32_le_u() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.le_u']));
    _add(const ir.I32LeU());
  }

  /// Emit an `i32.ge_s` instruction.
  void i32_ge_s() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.ge_s']));
    _add(const ir.I32GeS());
  }

  /// Emit an `i32.ge_u` instruction.
  void i32_ge_u() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.ge_u']));
    _add(const ir.I32GeU());
  }

  /// Emit an `i64.eqz` instruction.
  void i64_eqz() {
    assert(_verifyTypes(const [ir.NumType.i64], const [ir.NumType.i32],
        trace: const ['i64.eqz']));
    _add(const ir.I64Eqz());
  }

  /// Emit an `i64.eq` instruction.
  void i64_eq() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i32],
        trace: const ['i64.eq']));
    _add(const ir.I64Eq());
  }

  /// Emit an `i64.ne` instruction.
  void i64_ne() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i32],
        trace: const ['i64.ne']));
    _add(const ir.I64Ne());
  }

  /// Emit an `i64.lt_s` instruction.
  void i64_lt_s() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i32],
        trace: const ['i64.lt_s']));
    _add(const ir.I64LtS());
  }

  /// Emit an `i64.lt_u` instruction.
  void i64_lt_u() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i32],
        trace: const ['i64.lt_u']));
    _add(const ir.I64LtU());
  }

  /// Emit an `i64.gt_s` instruction.
  void i64_gt_s() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i32],
        trace: const ['i64.gt_s']));
    _add(const ir.I64GtS());
  }

  /// Emit an `i64.gt_u` instruction.
  void i64_gt_u() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i32],
        trace: const ['i64.gt_u']));
    _add(const ir.I64GtU());
  }

  /// Emit an `i64.le_s` instruction.
  void i64_le_s() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i32],
        trace: const ['i64.le_s']));
    _add(const ir.I64LeS());
  }

  /// Emit an `i64.le_u` instruction.
  void i64_le_u() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i32],
        trace: const ['i64.le_u']));
    _add(const ir.I64LeU());
  }

  /// Emit an `i64.ge_s` instruction.
  void i64_ge_s() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i32],
        trace: const ['i64.ge_s']));
    _add(const ir.I64GeS());
  }

  /// Emit an `i64.ge_u` instruction.
  void i64_ge_u() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i32],
        trace: const ['i64.ge_u']));
    _add(const ir.I64GeU());
  }

  /// Emit an `f32.eq` instruction.
  void f32_eq() {
    assert(_verifyTypes(
        const [ir.NumType.f32, ir.NumType.f32], const [ir.NumType.i32],
        trace: const ['f32.eq']));
    _add(const ir.F32Eq());
  }

  /// Emit an `f32.ne` instruction.
  void f32_ne() {
    assert(_verifyTypes(
        const [ir.NumType.f32, ir.NumType.f32], const [ir.NumType.i32],
        trace: const ['f32.ne']));
    _add(const ir.F32Ne());
  }

  /// Emit an `f32.lt` instruction.
  void f32_lt() {
    assert(_verifyTypes(
        const [ir.NumType.f32, ir.NumType.f32], const [ir.NumType.i32],
        trace: const ['f32.lt']));
    _add(const ir.F32Lt());
  }

  /// Emit an `f32.gt` instruction.
  void f32_gt() {
    assert(_verifyTypes(
        const [ir.NumType.f32, ir.NumType.f32], const [ir.NumType.i32],
        trace: const ['f32.gt']));
    _add(const ir.F32Gt());
  }

  /// Emit an `f32.le` instruction.
  void f32_le() {
    assert(_verifyTypes(
        const [ir.NumType.f32, ir.NumType.f32], const [ir.NumType.i32],
        trace: const ['f32.le']));
    _add(const ir.F32Le());
  }

  /// Emit an `f32.ge` instruction.
  void f32_ge() {
    assert(_verifyTypes(
        const [ir.NumType.f32, ir.NumType.f32], const [ir.NumType.i32],
        trace: const ['f32.ge']));
    _add(const ir.F32Ge());
  }

  /// Emit an `f64.eq` instruction.
  void f64_eq() {
    assert(_verifyTypes(
        const [ir.NumType.f64, ir.NumType.f64], const [ir.NumType.i32],
        trace: const ['f64.eq']));
    _add(const ir.F64Eq());
  }

  /// Emit an `f64.ne` instruction.
  void f64_ne() {
    assert(_verifyTypes(
        const [ir.NumType.f64, ir.NumType.f64], const [ir.NumType.i32],
        trace: const ['f64.ne']));
    _add(const ir.F64Ne());
  }

  /// Emit an `f64.lt` instruction.
  void f64_lt() {
    assert(_verifyTypes(
        const [ir.NumType.f64, ir.NumType.f64], const [ir.NumType.i32],
        trace: const ['f64.lt']));
    _add(const ir.F64Lt());
  }

  /// Emit an `f64.gt` instruction.
  void f64_gt() {
    assert(_verifyTypes(
        const [ir.NumType.f64, ir.NumType.f64], const [ir.NumType.i32],
        trace: const ['f64.gt']));
    _add(const ir.F64Gt());
  }

  /// Emit an `f64.le` instruction.
  void f64_le() {
    assert(_verifyTypes(
        const [ir.NumType.f64, ir.NumType.f64], const [ir.NumType.i32],
        trace: const ['f64.le']));
    _add(const ir.F64Le());
  }

  /// Emit an `f64.ge` instruction.
  void f64_ge() {
    assert(_verifyTypes(
        const [ir.NumType.f64, ir.NumType.f64], const [ir.NumType.i32],
        trace: const ['f64.ge']));
    _add(const ir.F64Ge());
  }

  /// Emit an `i32.clz` instruction.
  void i32_clz() {
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.clz']));
    _add(const ir.I32Clz());
  }

  /// Emit an `i32.ctz` instruction.
  void i32_ctz() {
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.ctz']));
    _add(const ir.I32Ctz());
  }

  /// Emit an `i32.popcnt` instruction.
  void i32_popcnt() {
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.popcnt']));
    _add(const ir.I32Popcnt());
  }

  /// Emit an `i32.add` instruction.
  void i32_add() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.add']));
    _add(const ir.I32Add());
  }

  /// Emit an `i32.sub` instruction.
  void i32_sub() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.sub']));
    _add(const ir.I32Sub());
  }

  /// Emit an `i32.mul` instruction.
  void i32_mul() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.mul']));
    _add(const ir.I32Mul());
  }

  /// Emit an `i32.div_s` instruction.
  void i32_div_s() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.div_s']));
    _add(const ir.I32DivS());
  }

  /// Emit an `i32.div_u` instruction.
  void i32_div_u() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.div_u']));
    _add(const ir.I32DivU());
  }

  /// Emit an `i32.rem_s` instruction.
  void i32_rem_s() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.rem_s']));
    _add(const ir.I32RemS());
  }

  /// Emit an `i32.rem_u` instruction.
  void i32_rem_u() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.rem_u']));
    _add(const ir.I32RemU());
  }

  /// Emit an `i32.and` instruction.
  void i32_and() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.and']));
    _add(const ir.I32And());
  }

  /// Emit an `i32.or` instruction.
  void i32_or() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.or']));
    _add(const ir.I32Or());
  }

  /// Emit an `i32.xor` instruction.
  void i32_xor() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.xor']));
    _add(const ir.I32Xor());
  }

  /// Emit an `i32.shl` instruction.
  void i32_shl() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.shl']));
    _add(const ir.I32Shl());
  }

  /// Emit an `i32.shr_s` instruction.
  void i32_shr_s() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.shr_s']));
    _add(const ir.I32ShrS());
  }

  /// Emit an `i32.shr_u` instruction.
  void i32_shr_u() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.shr_u']));
    _add(const ir.I32ShrU());
  }

  /// Emit an `i32.rotl` instruction.
  void i32_rotl() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.rotl']));
    _add(const ir.I32Rotl());
  }

  /// Emit an `i32.rotr` instruction.
  void i32_rotr() {
    assert(_verifyTypes(
        const [ir.NumType.i32, ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.rotr']));
    _add(const ir.I32Rotr());
  }

  /// Emit an `i64.clz` instruction.
  void i64_clz() {
    assert(_verifyTypes(const [ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.clz']));
    _add(const ir.I64Clz());
  }

  /// Emit an `i64.ctz` instruction.
  void i64_ctz() {
    assert(_verifyTypes(const [ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.ctz']));
    _add(const ir.I64Ctz());
  }

  /// Emit an `i64.popcnt` instruction.
  void i64_popcnt() {
    assert(_verifyTypes(const [ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.popcnt']));
    _add(const ir.I64Popcnt());
  }

  /// Emit an `i64.add` instruction.
  void i64_add() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.add']));
    _add(const ir.I64Add());
  }

  /// Emit an `i64.sub` instruction.
  void i64_sub() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.sub']));
    _add(const ir.I64Sub());
  }

  /// Emit an `i64.mul` instruction.
  void i64_mul() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.mul']));
    _add(const ir.I64Mul());
  }

  /// Emit an `i64.div_s` instruction.
  void i64_div_s() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.div_s']));
    _add(const ir.I64DivS());
  }

  /// Emit an `i64.div_u` instruction.
  void i64_div_u() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.div_u']));
    _add(const ir.I64DivU());
  }

  /// Emit an `i64.rem_s` instruction.
  void i64_rem_s() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.rem_s']));
    _add(const ir.I64RemS());
  }

  /// Emit an `i64.rem_u` instruction.
  void i64_rem_u() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.rem_u']));
    _add(const ir.I64RemU());
  }

  /// Emit an `i64.and` instruction.
  void i64_and() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.and']));
    _add(const ir.I64And());
  }

  /// Emit an `i64.or` instruction.
  void i64_or() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.or']));
    _add(const ir.I64Or());
  }

  /// Emit an `i64.xor` instruction.
  void i64_xor() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.xor']));
    _add(const ir.I64Xor());
  }

  /// Emit an `i64.shl` instruction.
  void i64_shl() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.shl']));
    _add(const ir.I64Shl());
  }

  /// Emit an `i64.shr_s` instruction.
  void i64_shr_s() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.shr_s']));
    _add(const ir.I64ShrS());
  }

  /// Emit an `i64.shr_u` instruction.
  void i64_shr_u() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.shr_u']));
    _add(const ir.I64ShrU());
  }

  /// Emit an `i64.rotl` instruction.
  void i64_rotl() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.rotl']));
    _add(const ir.I64Rotl());
  }

  /// Emit an `i64.rotr` instruction.
  void i64_rotr() {
    assert(_verifyTypes(
        const [ir.NumType.i64, ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.rotr']));
    _add(const ir.I64Rotr());
  }

  /// Emit an `f32.abs` instruction.
  void f32_abs() {
    assert(_verifyTypes(const [ir.NumType.f32], const [ir.NumType.f32],
        trace: const ['f32.abs']));
    _add(const ir.F32Abs());
  }

  /// Emit an `f32.neg` instruction.
  void f32_neg() {
    assert(_verifyTypes(const [ir.NumType.f32], const [ir.NumType.f32],
        trace: const ['f32.neg']));
    _add(const ir.F32Neg());
  }

  /// Emit an `f32.ceil` instruction.
  void f32_ceil() {
    assert(_verifyTypes(const [ir.NumType.f32], const [ir.NumType.f32],
        trace: const ['f32.ceil']));
    _add(const ir.F32Ceil());
  }

  /// Emit an `f32.floor` instruction.
  void f32_floor() {
    assert(_verifyTypes(const [ir.NumType.f32], const [ir.NumType.f32],
        trace: const ['f32.floor']));
    _add(const ir.F32Floor());
  }

  /// Emit an `f32.trunc` instruction.
  void f32_trunc() {
    assert(_verifyTypes(const [ir.NumType.f32], const [ir.NumType.f32],
        trace: const ['f32.trunc']));
    _add(const ir.F32Trunc());
  }

  /// Emit an `f32.nearest` instruction.
  void f32_nearest() {
    assert(_verifyTypes(const [ir.NumType.f32], const [ir.NumType.f32],
        trace: const ['f32.nearest']));
    _add(const ir.F32Nearest());
  }

  /// Emit an `f32.sqrt` instruction.
  void f32_sqrt() {
    assert(_verifyTypes(const [ir.NumType.f32], const [ir.NumType.f32],
        trace: const ['f32.sqrt']));
    _add(const ir.F32Sqrt());
  }

  /// Emit an `f32.add` instruction.
  void f32_add() {
    assert(_verifyTypes(
        const [ir.NumType.f32, ir.NumType.f32], const [ir.NumType.f32],
        trace: const ['f32.add']));
    _add(const ir.F32Add());
  }

  /// Emit an `f32.sub` instruction.
  void f32_sub() {
    assert(_verifyTypes(
        const [ir.NumType.f32, ir.NumType.f32], const [ir.NumType.f32],
        trace: const ['f32.sub']));
    _add(const ir.F32Sub());
  }

  /// Emit an `f32.mul` instruction.
  void f32_mul() {
    assert(_verifyTypes(
        const [ir.NumType.f32, ir.NumType.f32], const [ir.NumType.f32],
        trace: const ['f32.mul']));
    _add(const ir.F32Mul());
  }

  /// Emit an `f32.div` instruction.
  void f32_div() {
    assert(_verifyTypes(
        const [ir.NumType.f32, ir.NumType.f32], const [ir.NumType.f32],
        trace: const ['f32.div']));
    _add(const ir.F32Div());
  }

  /// Emit an `f32.min` instruction.
  void f32_min() {
    assert(_verifyTypes(
        const [ir.NumType.f32, ir.NumType.f32], const [ir.NumType.f32],
        trace: const ['f32.min']));
    _add(const ir.F32Min());
  }

  /// Emit an `f32.max` instruction.
  void f32_max() {
    assert(_verifyTypes(
        const [ir.NumType.f32, ir.NumType.f32], const [ir.NumType.f32],
        trace: const ['f32.max']));
    _add(const ir.F32Max());
  }

  /// Emit an `f32.copysign` instruction.
  void f32_copysign() {
    assert(_verifyTypes(
        const [ir.NumType.f32, ir.NumType.f32], const [ir.NumType.f32],
        trace: const ['f32.copysign']));
    _add(const ir.F32Copysign());
  }

  /// Emit an `f64.abs` instruction.
  void f64_abs() {
    assert(_verifyTypes(const [ir.NumType.f64], const [ir.NumType.f64],
        trace: const ['f64.abs']));
    _add(const ir.F64Abs());
  }

  /// Emit an `f64.neg` instruction.
  void f64_neg() {
    assert(_verifyTypes(const [ir.NumType.f64], const [ir.NumType.f64],
        trace: const ['f64.neg']));
    _add(const ir.F64Neg());
  }

  /// Emit an `f64.ceil` instruction.
  void f64_ceil() {
    assert(_verifyTypes(const [ir.NumType.f64], const [ir.NumType.f64],
        trace: const ['f64.ceil']));
    _add(const ir.F64Ceil());
  }

  /// Emit an `f64.floor` instruction.
  void f64_floor() {
    assert(_verifyTypes(const [ir.NumType.f64], const [ir.NumType.f64],
        trace: const ['f64.floor']));
    _add(const ir.F64Floor());
  }

  /// Emit an `f64.trunc` instruction.
  void f64_trunc() {
    assert(_verifyTypes(const [ir.NumType.f64], const [ir.NumType.f64],
        trace: const ['f64.trunc']));
    _add(const ir.F64Trunc());
  }

  /// Emit an `f64.nearest` instruction.
  void f64_nearest() {
    assert(_verifyTypes(const [ir.NumType.f64], const [ir.NumType.f64],
        trace: const ['f64.nearest']));
    _add(const ir.F64Nearest());
  }

  /// Emit an `f64.sqrt` instruction.
  void f64_sqrt() {
    assert(_verifyTypes(const [ir.NumType.f64], const [ir.NumType.f64],
        trace: const ['f64.sqrt']));
    _add(const ir.F64Sqrt());
  }

  /// Emit an `f64.add` instruction.
  void f64_add() {
    assert(_verifyTypes(
        const [ir.NumType.f64, ir.NumType.f64], const [ir.NumType.f64],
        trace: const ['f64.add']));
    _add(const ir.F64Add());
  }

  /// Emit an `f64.sub` instruction.
  void f64_sub() {
    assert(_verifyTypes(
        const [ir.NumType.f64, ir.NumType.f64], const [ir.NumType.f64],
        trace: const ['f64.sub']));
    _add(const ir.F64Sub());
  }

  /// Emit an `f64.mul` instruction.
  void f64_mul() {
    assert(_verifyTypes(
        const [ir.NumType.f64, ir.NumType.f64], const [ir.NumType.f64],
        trace: const ['f64.mul']));
    _add(const ir.F64Mul());
  }

  /// Emit an `f64.div` instruction.
  void f64_div() {
    assert(_verifyTypes(
        const [ir.NumType.f64, ir.NumType.f64], const [ir.NumType.f64],
        trace: const ['f64.div']));
    _add(const ir.F64Div());
  }

  /// Emit an `f64.min` instruction.
  void f64_min() {
    assert(_verifyTypes(
        const [ir.NumType.f64, ir.NumType.f64], const [ir.NumType.f64],
        trace: const ['f64.min']));
    _add(const ir.F64Min());
  }

  /// Emit an `f64.max` instruction.
  void f64_max() {
    assert(_verifyTypes(
        const [ir.NumType.f64, ir.NumType.f64], const [ir.NumType.f64],
        trace: const ['f64.max']));
    _add(const ir.F64Max());
  }

  /// Emit an `f64.copysign` instruction.
  void f64_copysign() {
    assert(_verifyTypes(
        const [ir.NumType.f64, ir.NumType.f64], const [ir.NumType.f64],
        trace: const ['f64.copysign']));
    _add(const ir.F64Copysign());
  }

  /// Emit an `i32.wrap_i64` instruction.
  void i32_wrap_i64() {
    assert(_verifyTypes(const [ir.NumType.i64], const [ir.NumType.i32],
        trace: const ['i32.wrap_i64']));
    _add(const ir.I32WrapI64());
  }

  /// Emit an `i32.trunc_f32_s` instruction.
  void i32_trunc_f32_s() {
    assert(_verifyTypes(const [ir.NumType.f32], const [ir.NumType.i32],
        trace: const ['i32.trunc_f32_s']));
    _add(const ir.I32TruncF32S());
  }

  /// Emit an `i32.trunc_f32_u` instruction.
  void i32_trunc_f32_u() {
    assert(_verifyTypes(const [ir.NumType.f32], const [ir.NumType.i32],
        trace: const ['i32.trunc_f32_u']));
    _add(const ir.I32TruncF32U());
  }

  /// Emit an `i32.trunc_f64_s` instruction.
  void i32_trunc_f64_s() {
    assert(_verifyTypes(const [ir.NumType.f64], const [ir.NumType.i32],
        trace: const ['i32.trunc_f64_s']));
    _add(const ir.I32TruncF64S());
  }

  /// Emit an `i32.trunc_f64_u` instruction.
  void i32_trunc_f64_u() {
    assert(_verifyTypes(const [ir.NumType.f64], const [ir.NumType.i32],
        trace: const ['i32.trunc_f64_u']));
    _add(const ir.I32TruncF64U());
  }

  /// Emit an `i64.extend_i32_s` instruction.
  void i64_extend_i32_s() {
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i64],
        trace: const ['i64.extend_i32_s']));
    _add(const ir.I64ExtendI32S());
  }

  /// Emit an `i64.extend_i32_u` instruction.
  void i64_extend_i32_u() {
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i64],
        trace: const ['i64.extend_i32_u']));
    _add(const ir.I64ExtendI32U());
  }

  /// Emit an `i64.trunc_f32_s` instruction.
  void i64_trunc_f32_s() {
    assert(_verifyTypes(const [ir.NumType.f32], const [ir.NumType.i64],
        trace: const ['i64.trunc_f32_s']));
    _add(const ir.I64TruncF32S());
  }

  /// Emit an `i64.trunc_f32_u` instruction.
  void i64_trunc_f32_u() {
    assert(_verifyTypes(const [ir.NumType.f32], const [ir.NumType.i64],
        trace: const ['i64.trunc_f32_u']));
    _add(const ir.I64TruncF32U());
  }

  /// Emit an `i64.trunc_f64_s` instruction.
  void i64_trunc_f64_s() {
    assert(_verifyTypes(const [ir.NumType.f64], const [ir.NumType.i64],
        trace: const ['i64.trunc_f64_s']));
    _add(const ir.I64TruncF64S());
  }

  /// Emit an `i64.trunc_f64_u` instruction.
  void i64_trunc_f64_u() {
    assert(_verifyTypes(const [ir.NumType.f64], const [ir.NumType.i64],
        trace: const ['i64.trunc_f64_u']));
    _add(const ir.I64TruncF64U());
  }

  /// Emit an `f32.convert_i32_s` instruction.
  void f32_convert_i32_s() {
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.f32],
        trace: const ['f32.convert_i32_s']));
    _add(const ir.F32ConvertI32S());
  }

  /// Emit an `f32.convert_i32_u` instruction.
  void f32_convert_i32_u() {
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.f32],
        trace: const ['f32.convert_i32_u']));
    _add(const ir.F32ConvertI32U());
  }

  /// Emit an `f32.convert_i64_s` instruction.
  void f32_convert_i64_s() {
    assert(_verifyTypes(const [ir.NumType.i64], const [ir.NumType.f32],
        trace: const ['f32.convert_i64_s']));
    _add(const ir.F32ConvertI64S());
  }

  /// Emit an `f32.convert_i64_u` instruction.
  void f32_convert_i64_u() {
    assert(_verifyTypes(const [ir.NumType.i64], const [ir.NumType.f32],
        trace: const ['f32.convert_i64_u']));
    _add(const ir.F32ConvertI64U());
  }

  /// Emit an `f32.demote_f64` instruction.
  void f32_demote_f64() {
    assert(_verifyTypes(const [ir.NumType.f64], const [ir.NumType.f32],
        trace: const ['f32.demote_f64']));
    _add(const ir.F32DemoteF64());
  }

  /// Emit an `f64.convert_i32_s` instruction.
  void f64_convert_i32_s() {
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.f64],
        trace: const ['f64.convert_i32_s']));
    _add(const ir.F64ConvertI32S());
  }

  /// Emit an `f64.convert_i32_u` instruction.
  void f64_convert_i32_u() {
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.f64],
        trace: const ['f64.convert_i32_u']));
    _add(const ir.F64ConvertI32U());
  }

  /// Emit an `f64.convert_i64_s` instruction.
  void f64_convert_i64_s() {
    assert(_verifyTypes(const [ir.NumType.i64], const [ir.NumType.f64],
        trace: const ['f64.convert_i64_s']));
    _add(const ir.F64ConvertI64S());
  }

  /// Emit an `f64.convert_i64_u` instruction.
  void f64_convert_i64_u() {
    assert(_verifyTypes(const [ir.NumType.i64], const [ir.NumType.f64],
        trace: const ['f64.convert_i64_u']));
    _add(const ir.F64ConvertI64U());
  }

  /// Emit an `f64.promote_f32` instruction.
  void f64_promote_f32() {
    assert(_verifyTypes(const [ir.NumType.f32], const [ir.NumType.f64],
        trace: const ['f64.promote_f32']));
    _add(const ir.F64PromoteF32());
  }

  /// Emit an `i32.reinterpret_f32` instruction.
  void i32_reinterpret_f32() {
    assert(_verifyTypes(const [ir.NumType.f32], const [ir.NumType.i32],
        trace: const ['i32.reinterpret_f32']));
    _add(const ir.I32ReinterpretF32());
  }

  /// Emit an `i64.reinterpret_f64` instruction.
  void i64_reinterpret_f64() {
    assert(_verifyTypes(const [ir.NumType.f64], const [ir.NumType.i64],
        trace: const ['i64.reinterpret_f64']));
    _add(const ir.I64ReinterpretF64());
  }

  /// Emit an `f32.reinterpret_i32` instruction.
  void f32_reinterpret_i32() {
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.f32],
        trace: const ['f32.reinterpret_i32']));
    _add(const ir.F32ReinterpretI32());
  }

  /// Emit an `f64.reinterpret_i64` instruction.
  void f64_reinterpret_i64() {
    assert(_verifyTypes(const [ir.NumType.i64], const [ir.NumType.f64],
        trace: const ['f64.reinterpret_i64']));
    _add(const ir.F64ReinterpretI64());
  }

  /// Emit an `i32.extend8_s` instruction.
  void i32_extend8_s() {
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.extend8_s']));
    _add(const ir.I32Extend8S());
  }

  /// Emit an `i32.extend16_s` instruction.
  void i32_extend16_s() {
    assert(_verifyTypes(const [ir.NumType.i32], const [ir.NumType.i32],
        trace: const ['i32.extend16_s']));
    _add(const ir.I32Extend16S());
  }

  /// Emit an `i64.extend8_s` instruction.
  void i64_extend8_s() {
    assert(_verifyTypes(const [ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.extend8_s']));
    _add(const ir.I64Extend8S());
  }

  /// Emit an `i64.extend16_s` instruction.
  void i64_extend16_s() {
    assert(_verifyTypes(const [ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.extend16_s']));
    _add(const ir.I64Extend16S());
  }

  /// Emit an `i64.extend32_s` instruction.
  void i64_extend32_s() {
    assert(_verifyTypes(const [ir.NumType.i64], const [ir.NumType.i64],
        trace: const ['i64.extend32_s']));
    _add(const ir.I64Extend32S());
  }

  /// Emit an `i32.trunc_sat_f32_s` instruction.
  void i32_trunc_sat_f32_s() {
    assert(_verifyTypes(const [ir.NumType.f32], const [ir.NumType.i32],
        trace: const ['i32.trunc_sat_f32_s']));
    _add(const ir.I32TruncSatF32S());
  }

  /// Emit an `i32.trunc_sat_f32_u` instruction.
  void i32_trunc_sat_f32_u() {
    assert(_verifyTypes(const [ir.NumType.f32], const [ir.NumType.i32],
        trace: const ['i32.trunc_sat_f32_u']));
    _add(const ir.I32TruncSatF32U());
  }

  /// Emit an `i32.trunc_sat_f64_s` instruction.
  void i32_trunc_sat_f64_s() {
    assert(_verifyTypes(const [ir.NumType.f64], const [ir.NumType.i32],
        trace: const ['i32.trunc_sat_f64_s']));
    _add(const ir.I32TruncSatF64S());
  }

  /// Emit an `i32.trunc_sat_f64_u` instruction.
  void i32_trunc_sat_f64_u() {
    assert(_verifyTypes(const [ir.NumType.f64], const [ir.NumType.i32],
        trace: const ['i32.trunc_sat_f64_u']));
    _add(const ir.I32TruncSatF64U());
  }

  /// Emit an `i64.trunc_sat_f32_s` instruction.
  void i64_trunc_sat_f32_s() {
    assert(_verifyTypes(const [ir.NumType.f32], const [ir.NumType.i64],
        trace: const ['i64.trunc_sat_f32_s']));
    _add(const ir.I64TruncSatF32S());
  }

  /// Emit an `i64.trunc_sat_f32_u` instruction.
  void i64_trunc_sat_f32_u() {
    assert(_verifyTypes(const [ir.NumType.f32], const [ir.NumType.i64],
        trace: const ['i64.trunc_sat_f32_u']));
    _add(const ir.I64TruncSatF32U());
  }

  /// Emit an `i64.trunc_sat_f64_s` instruction.
  void i64_trunc_sat_f64_s() {
    assert(_verifyTypes(const [ir.NumType.f64], const [ir.NumType.i64],
        trace: const ['i64.trunc_sat_f64_s']));
    _add(const ir.I64TruncSatF64S());
  }

  /// Emit an `i64.trunc_sat_f64_u` instruction.
  void i64_trunc_sat_f64_u() {
    assert(_verifyTypes(const [ir.NumType.f64], const [ir.NumType.i64],
        trace: const ['i64.trunc_sat_f64_u']));
    _add(const ir.I64TruncSatF64U());
  }
}
