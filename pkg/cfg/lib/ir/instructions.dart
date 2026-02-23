// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/field.dart';
import 'package:cfg/ir/global_context.dart';
import 'package:kernel/ast.dart' as ast show DartType, InterfaceType, Name;
import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/flow_graph.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/local_variable.dart';
import 'package:cfg/ir/loops.dart';
import 'package:cfg/ir/source_position.dart';
import 'package:cfg/ir/types.dart';
import 'package:cfg/ir/use_lists.dart';
import 'package:cfg/ir/visitor.dart';
import 'package:cfg/utils/misc.dart';

/// Base class for all instructions.
abstract base class Instruction {
  /// Enclosing control-flow graph.
  final FlowGraph graph;

  /// Index in the [FlowGraph.instructions].
  final int id;

  /// Source position associated with this instruction.
  final SourcePosition sourcePosition;

  /// Explicit inputs.
  final UsesArray _inputs;

  /// Enclosing basic block.
  Block? block;

  /// Next instruction in basic block.
  Instruction? next;

  /// Previous instruction in basic block.
  Instruction? previous;

  /// Values implicitly used by this instruction
  /// e.g. for exception handling and deoptimization).
  UsesArray? implicitInputs;

  /// Create a new instruction.
  ///
  /// The newly created instruction belongs to [graph] but not linked into
  /// a basic block and uses lists.
  Instruction(this.graph, this.sourcePosition, {required int inputCount})
    : id = graph.instructions.length,
      _inputs = inputCount == 0
          ? graph.emptyUsesArray
          : UsesArray.allocate(graph, inputCount) {
    for (var i = 0; i < inputCount; ++i) {
      _inputs.at(graph, i).init(graph, this);
    }
    graph.instructions.add(this);
  }

  /// Returns true if this instruction is linked into a list of instructions
  /// in a basic block (also imlplies inputs are linked in their use lists).
  bool get isInGraph => block != null;

  /// Number of explicit inputs.
  int get inputCount => _inputs.getLength(graph);

  /// [Use] corresponding to an [i]-th explicit input.
  Use inputAt(int i) => _inputs.at(graph, i);

  /// [Definition] of [i]-th explicit input.
  Definition inputDefAt(int i) => inputAt(i).getDefinition(graph);

  /// Set [i]-th input to the given [value]. Can be done only once.
  void setInputAt(int i, Definition value) {
    final input = inputAt(i);
    assert(input.getNext(graph) == Use.Null);
    assert(input.getPrevious(graph) == Use.Null);
    input.setDefinition(graph, value);
  }

  /// Replace [i]-th input with [value]. This instruction should be
  /// linked into a basic block.
  void replaceInputAt(int i, Definition value) {
    assert(isInGraph);
    removeInputFromUseList(i);
    setInputAt(i, value);
    addInputToUseList(i);
  }

  /// Reduce number of inputs to [newInputCount].
  void truncateInputs(int newInputCount) {
    _inputs.truncateTo(graph, newInputCount);
  }

  /// Link this instruction to the [next] instruction in basic block.
  void linkTo(Instruction next) {
    assert(!identical(this, next));
    this.next = next;
    next.previous = this;
    next.block = this.block;
  }

  /// Add [inputIndex]-th input to use list of its definition.
  ///
  /// This is a low-level operation which is rarely needed.
  /// Prefer using [appendInstruction] or [insertAfter].
  void addInputToUseList(int inputIndex) {
    final input = inputAt(inputIndex);
    assert(input.getNext(graph) == Use.Null);
    assert(input.getPrevious(graph) == Use.Null);
    final def = input.getDefinition(graph);
    final nextUse = def._inputUses;
    if (nextUse != Use.Null) {
      assert(nextUse.getPrevious(graph) == Use.Null);
      input.setNext(graph, nextUse);
      nextUse.setPrevious(graph, input);
    }
    def._inputUses = input;
  }

  void _addInputsToUseLists() {
    for (int i = 0, n = inputCount; i < n; ++i) {
      addInputToUseList(i);
    }
    assert(implicitInputs == null);
  }

  /// Remove [inputIndex]-th input from use list of its definition.
  ///
  /// This is a low-level operation which is rarely needed.
  /// Prefer using [replaceInputAt] or [removeFromGraph].
  void removeInputFromUseList(int inputIndex) {
    final input = inputAt(inputIndex);
    assert(input.getInstruction(graph) == this);
    final nextUse = input.getNext(graph);
    final prevUse = input.getPrevious(graph);
    if (prevUse == Use.Null) {
      final def = input.getDefinition(graph);
      assert(def._inputUses == input);
      def._inputUses = nextUse;
    } else {
      prevUse.setNext(graph, nextUse);
    }
    if (nextUse != Use.Null) {
      nextUse.setPrevious(graph, prevUse);
    }
    input.setNext(graph, Use.Null);
    input.setPrevious(graph, Use.Null);
  }

  /// Remove all inputs from their use lists.
  void removeInputsFromUseLists() {
    for (int i = 0, n = inputCount; i < n; ++i) {
      removeInputFromUseList(i);
    }
  }

  /// Append an unlinked [instr] after this instruction,
  /// which should be the last instruction appended into basic block.
  ///
  /// Also, add all inputs of [instr] to their use lists.
  void appendInstruction(Instruction instr) {
    assert(isInGraph);
    assert(!instr.isInGraph);
    assert(this.next == null);
    assert(this.block!.lastInstruction == this);
    assert(instr.next == null);
    assert(instr.previous == null);
    assert(instr.block == null);
    linkTo(instr);
    instr._addInputsToUseLists();
    block!.lastInstruction = instr;
  }

  /// Insert this instruction between [previous] and [previous.next].
  /// (which should be linked into a basic block).
  ///
  /// If [addInputsToUseLists], then also add all inputs to their use lists.
  void insertAfter(Instruction previous, {bool addInputsToUseLists = true}) {
    assert(previous.isInGraph);
    assert(!isInGraph);
    final next = previous.next!;
    assert(previous.block != null);
    assert(this.next == null);
    assert(this.previous == null);
    assert(this.block == null);

    this.previous = previous;
    this.next = next;
    this.block = previous.block;
    next.previous = this;
    previous.next = this;

    if (addInputsToUseLists) {
      _addInputsToUseLists();
    }
  }

  /// Insert this instruction between [next.previous] and [next].
  /// (which should be linked into a basic block).
  ///
  /// If [addInputsToUseLists], then also add all inputs to their use lists.
  void insertBefore(Instruction next, {bool addInputsToUseLists = true}) {
    assert(next.isInGraph);
    insertAfter(next.previous!, addInputsToUseLists: addInputsToUseLists);
  }

  /// Unlink this instruction from its basic block and use lists.
  void removeFromGraph() {
    assert(isInGraph);
    assert(block != null);
    assert(this != block);

    removeInputsFromUseLists();
    final next = this.next;
    final previous = this.previous!;
    previous.next = next;
    if (next != null) {
      next.previous = previous;
    } else {
      assert(this is ControlFlowInstruction);
      assert(this == block!.lastInstruction);
      block!.lastInstruction = previous;
    }
    this.next = null;
    this.previous = null;
    this.block = null;
    assert(!isInGraph);
  }

  /// Whether this instruction can potentially throw a Dart exception.
  bool get canThrow;

  /// Whether this instruction can have any visible side-effects.
  bool get hasSideEffects;

  /// Returns true if this instruction is idempotent (i.e. repeating this
  /// instruction with the same inputs does not have any effects after
  /// executing it once), and it is a subject to value numbering.
  bool get isIdempotent => false;

  /// Returns true if extra instruction attributes are equal.
  /// Used only for idempotent instructions of the same type.
  bool attributesEqual(Instruction other) =>
      throw 'Not implemented for ${runtimeType}';

  /// Return true if [other] dominates this instruction, i.e. every path from
  /// graph entry to this instruction goes through [other].
  bool isDominatedBy(Instruction other) =>
      graph.dominators.isDominatedBy(this, other);

  R accept<R>(InstructionVisitor<R> v);
}

/// Trait of instructions which can potentially throw Dart exceptions.
base mixin CanThrow on Instruction {
  bool get canThrow => true;
}

/// Trait of instructions which cannot throw Dart exceptions.
base mixin NoThrow on Instruction {
  bool get canThrow => false;
}

/// Trait of instructions which can have visible side-effects.
base mixin HasSideEffects on Instruction {
  bool get hasSideEffects => true;
}

/// Trait of instructions which do not have any side-effects.
base mixin Pure on Instruction {
  bool get hasSideEffects => false;
}

/// Trait of idempotent instructions.
base mixin Idempotent on Instruction {
  bool get isIdempotent => true;
}

/// Base class for instructions which yield a value.
abstract base class Definition extends Instruction {
  Use _inputUses = Use.Null;
  Use _implicitUses = Use.Null;

  Definition(super.graph, super.sourcePosition, {required super.inputCount});

  UsesIterable get inputUses => UsesIterable(graph, _inputUses);
  UsesIterable get implicitUses => UsesIterable(graph, _implicitUses);

  bool get hasInputUses => _inputUses != Use.Null;
  bool get hasImplicitUses => _implicitUses != Use.Null;
  bool get hasUses => hasInputUses || hasImplicitUses;

  /// Replace all uses of this instruction with [other].
  void replaceUsesWith(Definition other) {
    if (hasInputUses) {
      Use last = Use.Null;
      for (final use in inputUses) {
        use.setDefinition(graph, other);
        last = use;
      }
      final tail = other._inputUses;
      last.setNext(graph, tail);
      if (tail != Use.Null) {
        tail.setPrevious(graph, last);
      }
      other._inputUses = this._inputUses;
      this._inputUses = Use.Null;
    }
    if (hasImplicitUses) {
      Use last = Use.Null;
      for (final use in implicitUses) {
        use.setDefinition(graph, other);
        last = use;
      }
      final tail = other._implicitUses;
      last.setNext(graph, tail);
      if (tail != Use.Null) {
        tail.setPrevious(graph, last);
      }
      other._implicitUses = this._implicitUses;
      this._implicitUses = Use.Null;
    }
  }

  /// Result type of this instruction.
  CType get type;

  /// Whether this instruction can yield a zero value.
  bool get canBeZero => true;

  /// Whether this instruction can yield a negative value.
  bool get canBeNegative => true;

  /// Returns the only instruction which uses result of this instruction as
  /// an explicit input.
  ///
  /// Returns `null` if there are no or multiple uses.
  Instruction? get singleUser {
    if (hasInputUses && !hasImplicitUses) {
      final use = _inputUses;
      if (use.getNext(graph) == Use.Null) {
        return use.getInstruction(graph);
      }
    }
    return null;
  }
}

/// Forward iterator over instructions in the block.
final class _InstructionsIterator implements Iterator<Instruction> {
  Instruction? _current;
  Instruction? _next;

  _InstructionsIterator(this._next);

  @override
  bool moveNext() {
    _current = _next;
    _next = _current?.next;
    return (_current != null);
  }

  @override
  Instruction get current => _current!;
}

/// Backwards iterator over instructions in the block.
final class _ReverseInstructionsIterator implements Iterator<Instruction> {
  Instruction? _current;
  Instruction _previous;

  _ReverseInstructionsIterator(this._previous);

  @override
  bool moveNext() {
    final instr = _previous.previous;
    if (instr == null) {
      assert(_previous is Block);
      _current = null;
      return false;
    } else {
      _current = _previous;
      _previous = instr;
      return true;
    }
  }

  @override
  Instruction get current => _current!;
}

/// Iterable for backwards iteration of instructions in the block.
final class _ReverseInstructionsIterable extends Iterable<Instruction> {
  final Block _block;

  _ReverseInstructionsIterable(this._block);

  @override
  Iterator<Instruction> get iterator =>
      _ReverseInstructionsIterator(_block.lastInstruction);
}

/// Basic block.
abstract base class Block extends Instruction
    with NoThrow, Pure, Iterable<Instruction> {
  final List<Block> predecessors = [];
  final List<Block> successors = [];
  late Instruction lastInstruction;
  CatchBlock? exceptionHandler;

  int preorderNumber = -1;
  int postorderNumber = -1;

  Block(super.graph, super.sourcePosition) : super(inputCount: 0) {
    this.block = this;
    this.lastInstruction = this;
  }

  Block? get dominator {
    int idom = graph.dominators.idom[preorderNumber];
    return (idom < 0) ? null : graph.preorder[idom];
  }

  List<Block> get dominatedBlocks => graph.dominators.dominated[preorderNumber];

  Loop? get loop => graph.loops[this];

  int get loopDepth => loop?.depth ?? 0;

  /// Replace [oldPredecessor] with [newPredecessor].
  void replacePredecessor(Block oldPredecessor, Block newPredecessor) {
    final predecessors = this.predecessors;
    for (int i = 0, n = predecessors.length; i < n; ++i) {
      if (predecessors[i] == oldPredecessor) {
        predecessors[i] = newPredecessor;
      }
    }
  }

  /// Iterate over instructions in the block from the first to the last.
  /// Iteration is robust wrt removal of the current instruction.
  @override
  Iterator<Instruction> get iterator => _InstructionsIterator(next);

  /// Iterate over instructions in the block from the last to the first.
  /// Iteration is robust wrt removal of the current instruction.
  Iterable<Instruction> get reversed => _ReverseInstructionsIterable(this);
}

/// The entry block in the [FlowGraph].
///
/// Contains all [Constant] instructions and [Parameter] instructions
/// corresponding to the function parameters.
final class EntryBlock extends Block {
  EntryBlock(super.graph, super.sourcePosition);

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitEntryBlock(this);
}

/// Iterator over [Phi] instructions in the [JoinBlock].
final class _PhiIterator implements Iterator<Phi> {
  Phi? _current;
  Phi? _next;

  _PhiIterator(JoinBlock block) {
    final nextInstruction = block.next;
    _next = (nextInstruction is Phi) ? nextInstruction : null;
  }

  @override
  bool moveNext() {
    _current = _next;
    final nextInstruction = _current?.next;
    _next = (nextInstruction is Phi) ? nextInstruction : null;
    return (_current != null);
  }

  @override
  Phi get current => _current!;
}

/// Iterable over [Phi] instructions in the [JoinBlock].
final class _PhiIterable extends Iterable<Phi> {
  final JoinBlock _block;

  _PhiIterable(this._block);

  @override
  Iterator<Phi> get iterator => _PhiIterator(_block);
}

/// Basic block which can have multiple predecessors.
///
/// May contain [Phi] instructions in the beginning of the block.
final class JoinBlock extends Block {
  JoinBlock(super.graph, super.sourcePosition);

  Iterable<Phi> get phis => _PhiIterable(this);

  bool get hasPhis => next is Phi;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitJoinBlock(this);
}

/// Target block of a branch.
final class TargetBlock extends Block {
  TargetBlock(super.graph, super.sourcePosition);

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitTargetBlock(this);
}

/// Exception handler block.
///
/// May contain [Parameter] instructions in the beginning of the block
/// to represent incoming values of local variables, exception object and
/// stack trace.
final class CatchBlock extends Block {
  CatchBlock(super.graph, super.sourcePosition);

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitCatchBlock(this);
}

/// Marker interface for instructions which can end basic block.
abstract class ControlFlowInstruction {}

/// Unconditional jump to the sole successor of this basic block.
final class Goto extends Instruction
    with NoThrow, Pure
    implements ControlFlowInstruction {
  Goto(super.graph, super.sourcePosition) : super(inputCount: 0);

  Block get target => block!.successors.single;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitGoto(this);
}

/// Conditional branch to either true of false successors of this basic block.
final class Branch extends Instruction
    with NoThrow, Pure
    implements ControlFlowInstruction {
  Branch(super.graph, super.sourcePosition, Definition condition)
    : super(inputCount: 1) {
    setInputAt(0, condition);
  }

  Definition get condition => inputDefAt(0);
  TargetBlock get trueSuccessor => block!.successors[0] as TargetBlock;
  TargetBlock get falseSuccessor => block!.successors[1] as TargetBlock;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitBranch(this);
}

/// Unconditional jump to the try block body (the first succesor of this
/// basic block). The second successor of this basic block is a catch block.
final class TryEntry extends Instruction
    with NoThrow, Pure
    implements ControlFlowInstruction {
  TryEntry(super.graph, super.sourcePosition) : super(inputCount: 0);

  TargetBlock get tryBody => block!.successors[0] as TargetBlock;
  CatchBlock get catchBlock => block!.successors[1] as CatchBlock;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitTryEntry(this);
}

/// The result of instruction `v = Phi(v[0],...,v[N-1])` is `v[i]` when
/// control is transferred from the i-th predecessor block.
///
/// Number of inputs always matches number of predecessor blocks.
final class Phi extends Definition with NoThrow, Pure {
  /// Local variable for which this [Phi] was originally created.
  final LocalVariable variable;

  Phi(
    super.graph,
    super.sourcePosition,
    this.variable, {
    required super.inputCount,
  });

  @override
  CType get type => variable.type;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitPhi(this);
}

/// Return value from the current function.
final class Return extends Instruction
    with NoThrow, Pure
    implements ControlFlowInstruction {
  Return(super.graph, super.sourcePosition, Definition value)
    : super(inputCount: 1) {
    setInputAt(0, value);
  }

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitReturn(this);
}

enum ComparisonOpcode {
  // Simple object pointer equality.
  equal('=='),
  notEqual('!='),
  // identical with special cases for num.
  identical('==='),
  notIdentical('!=='),
  // int comparisons.
  intEqual('int =='),
  intNotEqual('int !='),
  intLess('int <'),
  intLessOrEqual('int <='),
  intGreater('int >'),
  intGreaterOrEqual('int >='),
  // int bitwise tests
  intTestIsZero('int & == 0'),
  intTestIsNotZero('int & != 0'),
  // double comparisons.
  doubleEqual('double =='),
  doubleNotEqual('double !='),
  doubleLess('double <'),
  doubleLessOrEqual('double <='),
  doubleGreater('double >'),
  doubleGreaterOrEqual('double >=');

  final String token;
  const ComparisonOpcode(this.token);

  bool get isIntComparison => switch (this) {
    intEqual ||
    intNotEqual ||
    intLess ||
    intLessOrEqual ||
    intGreater ||
    intGreaterOrEqual ||
    intTestIsZero ||
    intTestIsNotZero => true,
    _ => false,
  };

  bool get isDoubleComparison => switch (this) {
    doubleEqual ||
    doubleNotEqual ||
    doubleLess ||
    doubleLessOrEqual ||
    doubleGreater ||
    doubleGreaterOrEqual => true,
    _ => false,
  };

  ComparisonOpcode flipOperands() => switch (this) {
    equal ||
    notEqual ||
    identical ||
    notIdentical ||
    intEqual ||
    intNotEqual ||
    intTestIsZero ||
    intTestIsNotZero ||
    doubleEqual ||
    doubleNotEqual => this,
    intLess => intGreaterOrEqual,
    intLessOrEqual => intGreater,
    intGreater => intLessOrEqual,
    intGreaterOrEqual => intLess,
    doubleLess => doubleGreaterOrEqual,
    doubleLessOrEqual => doubleGreater,
    doubleGreater => doubleLessOrEqual,
    doubleGreaterOrEqual => doubleLess,
  };

  bool get canBeNegated => switch (this) {
    doubleLess ||
    doubleLessOrEqual ||
    doubleGreater ||
    doubleGreaterOrEqual => false,
    _ => true,
  };

  ComparisonOpcode negate() => switch (this) {
    equal => notEqual,
    notEqual => equal,
    identical => notIdentical,
    notIdentical => identical,
    intEqual => intNotEqual,
    intNotEqual => intEqual,
    intLess => intGreaterOrEqual,
    intLessOrEqual => intGreater,
    intGreater => intLessOrEqual,
    intGreaterOrEqual => intLess,
    intTestIsZero => intTestIsNotZero,
    intTestIsNotZero => intTestIsZero,
    doubleEqual => doubleNotEqual,
    doubleNotEqual => doubleEqual,
    doubleLess ||
    doubleLessOrEqual ||
    doubleGreater ||
    doubleGreaterOrEqual => throw '${token} cannot be negated',
  };
}

/// Compare two operands.
final class Comparison extends Definition with NoThrow, Pure, Idempotent {
  ComparisonOpcode op;

  Comparison(
    super.graph,
    super.sourcePosition,
    this.op,
    Definition left,
    Definition right,
  ) : super(inputCount: 2) {
    setInputAt(0, left);
    setInputAt(1, right);
  }

  Definition get left => inputDefAt(0);
  Definition get right => inputDefAt(1);

  @override
  CType get type => const BoolType();

  @override
  bool attributesEqual(covariant Comparison other) => op == other.op;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitComparison(this);
}

/// Instruction representing a constant value.
///
/// Should not be created directly, use [FlowGraph.getConstant] instead.
final class Constant extends Definition with NoThrow, Pure {
  final ConstantValue value;

  Constant(FlowGraph graph, this.value)
    : super(graph, noPosition, inputCount: 0);

  @override
  bool get canBeZero => value.isZero;

  @override
  bool get canBeNegative => value.isNegative;

  @override
  CType get type => value.type;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitConstant(this);
}

/// Base class for various calls.
abstract base class CallInstruction extends Definition
    with CanThrow, HasSideEffects {
  final ArgumentsShape argumentsShape;

  CallInstruction(
    super.graph,
    super.sourcePosition, {
    required super.inputCount,
    required this.argumentsShape,
  }) {
    assert(
      inputCount ==
          ((argumentsShape.types > 0) ? 1 : 0) +
              argumentsShape.positional +
              argumentsShape.named.length,
    );
  }

  bool get hasTypeArguments => argumentsShape.types > 0;
  Definition? get typeArguments => hasTypeArguments ? inputDefAt(0) : null;
}

/// Direct call of the target function.
final class DirectCall extends CallInstruction {
  final CFunction target;

  @override
  final CType type;

  DirectCall(
    super.graph,
    super.sourcePosition,
    this.target,
    this.type, {
    required super.inputCount,
    required super.argumentsShape,
  });

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitDirectCall(this);
}

/// Interface call via given interface target.
final class InterfaceCall extends CallInstruction {
  final CFunction interfaceTarget;

  @override
  final CType type;

  InterfaceCall(
    super.graph,
    super.sourcePosition,
    this.interfaceTarget,
    this.type, {
    required super.inputCount,
    required super.argumentsShape,
  }) : assert(argumentsShape.positional > 0);

  Definition get receiver => inputDefAt(hasTypeArguments ? 1 : 0);

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitInterfaceCall(this);
}

/// Call closure function using the given closure instance.
final class ClosureCall extends CallInstruction {
  @override
  final CType type;

  ClosureCall(
    super.graph,
    super.sourcePosition,
    this.type, {
    required super.inputCount,
    required super.argumentsShape,
  }) : assert(argumentsShape.positional > 0);

  Definition get closure => inputDefAt(hasTypeArguments ? 1 : 0);

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitClosureCall(this);
}

enum DynamicCallKind { method, getter, setter }

/// Dynamic call via given selector.
final class DynamicCall extends CallInstruction {
  final ast.Name selector;
  final DynamicCallKind kind;

  DynamicCall(
    super.graph,
    super.sourcePosition,
    this.selector,
    this.kind, {
    required super.inputCount,
    required super.argumentsShape,
  }) : assert(argumentsShape.positional > 0);

  Definition get receiver => inputDefAt(hasTypeArguments ? 1 : 0);

  @override
  CType get type => const TopType();

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitDynamicCall(this);
}

/// Parameter of a function or a catch block.
final class Parameter extends Definition with NoThrow, Pure {
  final LocalVariable variable;

  Parameter(super.graph, super.sourcePosition, this.variable)
    : super(inputCount: 0);

  bool get isFunctionParameter => block is EntryBlock;
  bool get isCatchParameter => block is CatchBlock;

  @override
  CType get type => variable.type;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitParameter(this);
}

/// Loads value from the local variable.
///
/// [LoadLocal] instructions are only used before
/// IR is converted to SSA form.
final class LoadLocal extends Definition with NoThrow, Pure {
  final LocalVariable variable;

  LoadLocal(super.graph, super.sourcePosition, this.variable)
    : super(inputCount: 0);

  @override
  CType get type => variable.type;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitLoadLocal(this);
}

/// Store value to the local variable.
///
/// [StoreLocal] instructions are only used before
/// IR is converted to SSA form.
final class StoreLocal extends Instruction with NoThrow, HasSideEffects {
  final LocalVariable variable;

  StoreLocal(super.graph, super.sourcePosition, this.variable, Definition value)
    : super(inputCount: 1) {
    setInputAt(0, value);
  }

  Definition get value => inputDefAt(0);

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitStoreLocal(this);
}

/// Load value from a field.
///
/// Check if field is initialized if [checkInitialized].
/// If it is not, then either call initializer or throw exception.
abstract base class LoadField extends Definition {
  final CField field;
  bool checkInitialized;

  LoadField(
    super.graph,
    super.sourcePosition,
    this.field, {
    required super.inputCount,
    required this.checkInitialized,
  });

  @override
  bool get canThrow => checkInitialized;

  @override
  bool get hasSideEffects => checkInitialized && field.hasInitializer;

  @override
  bool get isIdempotent => field.isFinal;

  @override
  bool attributesEqual(covariant LoadField other) =>
      // 'checkInitialized' is not taken into account as checked and unchecked loads
      // of the same field are congruent wrt value numbering.
      this.field == other.field;

  @override
  CType get type => field.type;
}

/// Store value to a field.
///
/// For late final fields, check if field is not initialized if [checkNotInitialized].
/// If it is already initialized, then throw exception.
abstract base class StoreField extends Instruction with HasSideEffects {
  final CField field;
  bool checkNotInitialized;

  StoreField(
    super.graph,
    super.sourcePosition,
    this.field, {
    required super.inputCount,
    required this.checkNotInitialized,
  }) {
    assert((field.isLate && field.isFinal) || !checkNotInitialized);
  }

  @override
  bool get canThrow => checkNotInitialized;
}

/// Load value from an instance field.
///
/// For late fields, check if field is initialized if [checkInitialized].
/// If it is not, then either call initializer or throw exception.
final class LoadInstanceField extends LoadField {
  LoadInstanceField(
    super.graph,
    super.sourcePosition,
    super.field,
    Definition object, {
    bool checkInitialized = false,
  }) : super(inputCount: 1, checkInitialized: checkInitialized) {
    assert(field.isLate || !checkInitialized);
    setInputAt(0, object);
  }

  Definition get object => inputDefAt(0);

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitLoadInstanceField(this);
}

/// Store value to an instance field.
///
/// For late final fields, check if field is not initialized if [checkNotInitialized].
/// If it is already initialized, then throw exception.
final class StoreInstanceField extends StoreField {
  StoreInstanceField(
    super.graph,
    super.sourcePosition,
    super.field,
    Definition object,
    Definition value, {
    bool checkNotInitialized = false,
  }) : super(inputCount: 2, checkNotInitialized: checkNotInitialized) {
    setInputAt(0, object);
    setInputAt(1, value);
  }

  Definition get object => inputDefAt(0);
  Definition get value => inputDefAt(1);

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitStoreInstanceField(this);
}

/// Load value from a static field.
///
/// Check if field is initialized if [checkInitialized].
/// If it is not, then either call initializer or throw exception.
final class LoadStaticField extends LoadField {
  LoadStaticField(
    super.graph,
    super.sourcePosition,
    super.field, {
    bool checkInitialized = false,
  }) : super(inputCount: 0, checkInitialized: checkInitialized);

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitLoadStaticField(this);
}

/// Store value to a static field.
///
/// For late final fields, check if field is not initialized if [checkNotInitialized].
/// If it is already initialized, then throw exception.
final class StoreStaticField extends StoreField {
  StoreStaticField(
    super.graph,
    super.sourcePosition,
    super.field,
    Definition value, {
    bool checkNotInitialized = false,
  }) : super(inputCount: 1, checkNotInitialized: checkNotInitialized) {
    setInputAt(0, value);
  }

  Definition get value => inputDefAt(0);

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitStoreStaticField(this);
}

/// Throw given exception object. Also takes optional stack trace
/// input to rethrow exception object without collecting a new stack trace.
final class Throw extends Instruction
    with CanThrow, HasSideEffects
    implements ControlFlowInstruction {
  Throw(
    super.graph,
    super.sourcePosition,
    Definition exception,
    Definition? stackTrace,
  ) : super(inputCount: stackTrace != null ? 2 : 1) {
    setInputAt(0, exception);
    if (stackTrace != null) {
      setInputAt(1, stackTrace);
    }
  }

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitThrow(this);
}

/// Checks that input object is not null. Throws TypeError if object is null.
final class NullCheck extends Definition with CanThrow, Pure, Idempotent {
  @override
  late final CType type = operand.type.toNonNullableType;

  NullCheck(super.graph, super.sourcePosition, Definition object)
    : super(inputCount: 1) {
    setInputAt(0, object);
  }

  Definition get operand => inputDefAt(0);

  @override
  bool attributesEqual(covariant NullCheck other) => true;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitNullCheck(this);
}

/// Represents collection of class and function type parameters.
final class TypeParameters extends Definition with NoThrow, Pure {
  TypeParameters(super.graph, super.sourcePosition, Definition? receiver)
    : super(inputCount: receiver != null ? 1 : 0) {
    if (receiver != null) {
      setInputAt(0, receiver);
    }
  }

  @override
  CType get type => const TypeParametersType();

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitTypeParameters(this);
}

/// Casts input object to the given type.
///
/// Checked casts throw TypeError if
/// object is not assignable to the given type.
final class TypeCast extends Definition with CanThrow, Pure, Idempotent {
  /// Target type for the type cast.
  final CType testedType;

  /// Whether this type cast involves check at runtime.
  bool isChecked;

  TypeCast(
    super.graph,
    super.sourcePosition,
    Definition object,
    this.testedType,
    Definition? typeParameters, {
    this.isChecked = true,
  }) : super(inputCount: typeParameters != null ? 2 : 1) {
    setInputAt(0, object);
    if (typeParameters != null) {
      setInputAt(1, typeParameters);
    }
  }

  Definition get operand => inputDefAt(0);
  Definition? get typeParameters => (inputCount > 1) ? inputDefAt(1) : null;

  @override
  CType get type => testedType;

  @override
  bool get canThrow => isChecked;

  @override
  bool attributesEqual(covariant TypeCast other) =>
      // 'isChecked' is not taken into account as checked and unchecked casts
      // against the same type are congruent wrt value numbering.
      testedType == other.testedType;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitTypeCast(this);
}

/// Test if input object is assignable to the given type.
final class TypeTest extends Definition with NoThrow, Pure, Idempotent {
  final CType testedType;

  TypeTest(
    super.graph,
    super.sourcePosition,
    Definition object,
    this.testedType,
    Definition? typeParameters,
  ) : super(inputCount: typeParameters != null ? 2 : 1) {
    setInputAt(0, object);
    if (typeParameters != null) {
      setInputAt(1, typeParameters);
    }
  }

  Definition get operand => inputDefAt(0);
  Definition? get typeParameters => (inputCount > 1) ? inputDefAt(1) : null;

  @override
  CType get type => const BoolType();

  @override
  bool attributesEqual(covariant TypeTest other) =>
      testedType == other.testedType;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitTypeTest(this);
}

/// Represents a list of type arguments which use type parameters and
/// passed to a call or an instance allocation.
///
/// Only used as the first input of call instructions, [AllocateObject],
/// [AllocateListLiteral] and [AllocateMapLiteral].
final class TypeArguments extends Definition with NoThrow, Pure, Idempotent {
  final List<ast.DartType> types;
  TypeArguments(
    super.graph,
    super.sourcePosition,
    this.types,
    Definition typeParameters,
  ) : super(inputCount: 1) {
    setInputAt(0, typeParameters);
  }

  Definition get typeParameters => inputDefAt(0);

  @override
  CType get type => const TypeArgumentsType();

  @override
  bool attributesEqual(covariant TypeArguments other) =>
      listEquals(types, other.types);

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitTypeArguments(this);
}

/// Represents a type literal which uses type parameters.
final class TypeLiteral extends Definition with NoThrow, Pure, Idempotent {
  final ast.DartType uninstantiatedType;
  TypeLiteral(
    super.graph,
    super.sourcePosition,
    this.uninstantiatedType,
    Definition typeParameters,
  ) : super(inputCount: 1) {
    setInputAt(0, typeParameters);
  }

  Definition get typeParameters => inputDefAt(0);

  @override
  CType get type =>
      StaticType(GlobalContext.instance.coreTypes.typeNonNullableRawType);

  @override
  bool attributesEqual(covariant TypeLiteral other) =>
      this.uninstantiatedType == other.uninstantiatedType;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitTypeLiteral(this);
}

/// Allocate an instance of given type.
///
/// If type is a generic class, then [AllocateObject] takes type arguments
/// as an input.
final class AllocateObject extends Definition with CanThrow, Pure {
  @override
  final CType type;

  AllocateObject(
    super.graph,
    super.sourcePosition,
    this.type,
    Definition? typeArguments,
  ) : super(inputCount: typeArguments != null ? 1 : 0) {
    if (typeArguments != null) {
      assert(
        (type.dartType as ast.InterfaceType)
            .classNode
            .typeParameters
            .isNotEmpty,
      );
      setInputAt(0, typeArguments);
    }
  }

  bool get hasTypeArguments => inputCount > 0;
  Definition? get typeArguments => hasTypeArguments ? inputDefAt(0) : null;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitAllocateObject(this);
}

/// Allocate a closure instance.
///
/// Takes captured values as inputs.
final class AllocateClosure extends Definition with CanThrow, Pure {
  final ClosureFunction function;

  @override
  final CType type;

  AllocateClosure(
    super.graph,
    super.sourcePosition,
    this.function,
    this.type, {
    required super.inputCount,
  });

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitAllocateClosure(this);
}

/// Allocate a new List literal with given type arguments and elements.
final class AllocateListLiteral extends Definition with CanThrow, Pure {
  @override
  final CType type;

  AllocateListLiteral(
    super.graph,
    super.sourcePosition,
    this.type, {
    required super.inputCount,
  }) : assert(inputCount > 0);

  Definition get typeArguments => inputDefAt(0);
  Definition elementAt(int index) => inputDefAt(index + 1);
  int get length => inputCount - 1;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitAllocateListLiteral(this);
}

/// Allocate a new Map literal with given type arguments and key-value pairs.
final class AllocateMapLiteral extends Definition with CanThrow, Pure {
  @override
  final CType type;

  AllocateMapLiteral(
    super.graph,
    super.sourcePosition,
    this.type, {
    required super.inputCount,
  }) : assert(inputCount > 0 && inputCount.isOdd);

  Definition get typeArguments => inputDefAt(0);
  Definition keyAt(int index) => inputDefAt((index << 1) + 1);
  Definition valueAt(int index) => inputDefAt((index << 1) + 2);
  int get length => (inputCount - 1) >> 1;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitAllocateMapLiteral(this);
}

/// Interpolate given objects into a String.
final class StringInterpolation extends Definition
    with CanThrow, HasSideEffects {
  StringInterpolation(
    super.graph,
    super.sourcePosition, {
    required super.inputCount,
  });

  @override
  CType get type => const StringType();

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitStringInterpolation(this);
}

enum BinaryIntOpcode {
  add('+'),
  sub('-'),
  mul('*'),
  truncatingDiv('~/'),
  mod('%'),
  rem('remainder'),
  bitOr('|'),
  bitAnd('&'),
  bitXor('^'),
  shiftLeft('<<'),
  shiftRight('>>'),
  unsignedShiftRight('>>>');

  final String token;
  const BinaryIntOpcode(this.token);

  bool get isCommutative => switch (this) {
    add || mul || bitOr || bitAnd || bitXor => true,
    _ => false,
  };
}

/// Binary operation on two int operands.
final class BinaryIntOp extends Definition with Pure, Idempotent {
  BinaryIntOpcode op;

  BinaryIntOp(
    super.graph,
    super.sourcePosition,
    this.op,
    Definition left,
    Definition right,
  ) : super(inputCount: 2) {
    setInputAt(0, left);
    setInputAt(1, right);
  }

  Definition get left => inputDefAt(0);
  Definition get right => inputDefAt(1);

  @override
  bool get canThrow => switch (op) {
    BinaryIntOpcode.truncatingDiv ||
    BinaryIntOpcode.mod ||
    BinaryIntOpcode.rem => right.canBeZero,
    BinaryIntOpcode.shiftLeft ||
    BinaryIntOpcode.shiftRight ||
    BinaryIntOpcode.unsignedShiftRight => right.canBeNegative,
    _ => false,
  };

  @override
  CType get type => const IntType();

  @override
  bool attributesEqual(covariant BinaryIntOp other) => op == other.op;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitBinaryIntOp(this);
}

enum UnaryIntOpcode {
  neg('-'),
  bitNot('~'),
  toDouble('toDouble'),
  abs('abs'),
  sign('sign');

  final String token;
  const UnaryIntOpcode(this.token);
}

/// Unary operation on the int operand.
final class UnaryIntOp extends Definition with NoThrow, Pure, Idempotent {
  UnaryIntOpcode op;

  UnaryIntOp(super.graph, super.sourcePosition, this.op, Definition operand)
    : super(inputCount: 1) {
    setInputAt(0, operand);
  }

  Definition get operand => inputDefAt(0);

  @override
  CType get type => switch (op) {
    UnaryIntOpcode.toDouble => const DoubleType(),
    _ => const IntType(),
  };

  @override
  bool attributesEqual(covariant UnaryIntOp other) => op == other.op;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitUnaryIntOp(this);
}

enum BinaryDoubleOpcode {
  add('+'),
  sub('-'),
  mul('*'),
  div('/'),
  truncatingDiv('~/'),
  mod('%'),
  rem('remainder');

  final String token;
  const BinaryDoubleOpcode(this.token);

  bool get isCommutative => switch (this) {
    add || mul => true,
    _ => false,
  };
}

/// Binary operation on two double operands.
final class BinaryDoubleOp extends Definition with NoThrow, Pure, Idempotent {
  BinaryDoubleOpcode op;

  BinaryDoubleOp(
    super.graph,
    super.sourcePosition,
    this.op,
    Definition left,
    Definition right,
  ) : super(inputCount: 2) {
    setInputAt(0, left);
    setInputAt(1, right);
  }

  Definition get left => inputDefAt(0);
  Definition get right => inputDefAt(1);

  @override
  CType get type => switch (op) {
    BinaryDoubleOpcode.truncatingDiv => const IntType(),
    _ => const DoubleType(),
  };

  @override
  bool attributesEqual(covariant BinaryDoubleOp other) => op == other.op;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitBinaryDoubleOp(this);
}

enum UnaryDoubleOpcode {
  neg('-'),
  abs('abs'),
  sign('sign'),
  square('square'),
  round('round'),
  floor('floor'),
  ceil('ceil'),
  truncate('truncate'),
  roundToDouble('roundToDouble'),
  floorToDouble('floorToDouble'),
  ceilToDouble('ceilToDouble'),
  truncateToDouble('truncateToDouble');

  final String token;
  const UnaryDoubleOpcode(this.token);
}

/// Unary operation on the double operand.
final class UnaryDoubleOp extends Definition with NoThrow, Pure, Idempotent {
  UnaryDoubleOpcode op;

  UnaryDoubleOp(super.graph, super.sourcePosition, this.op, Definition operand)
    : super(inputCount: 1) {
    setInputAt(0, operand);
  }

  Definition get operand => inputDefAt(0);

  @override
  CType get type => switch (op) {
    UnaryDoubleOpcode.round ||
    UnaryDoubleOpcode.floor ||
    UnaryDoubleOpcode.ceil ||
    UnaryDoubleOpcode.truncate => const IntType(),
    _ => const DoubleType(),
  };

  @override
  bool attributesEqual(covariant UnaryDoubleOp other) => op == other.op;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitUnaryDoubleOp(this);
}

enum UnaryBoolOpcode {
  not('!');

  final String token;
  const UnaryBoolOpcode(this.token);
}

/// Unary operation on the bool operand.
final class UnaryBoolOp extends Definition with NoThrow, Pure, Idempotent {
  UnaryBoolOpcode op;

  UnaryBoolOp(super.graph, super.sourcePosition, this.op, Definition operand)
    : super(inputCount: 1) {
    setInputAt(0, operand);
  }

  Definition get operand => inputDefAt(0);

  @override
  CType get type => const BoolType();

  @override
  bool attributesEqual(covariant UnaryBoolOp other) => op == other.op;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitUnaryBoolOp(this);
}

/// Marker for the back-end specific instructions.
base mixin BackendInstruction on Instruction {}

/// Combined comparison and branch.
///
/// Certain back-ends may create [CompareAndBranch] during lowering.
final class CompareAndBranch extends Instruction
    with NoThrow, Pure, BackendInstruction
    implements ControlFlowInstruction {
  ComparisonOpcode op;

  CompareAndBranch(
    super.graph,
    super.sourcePosition,
    this.op,
    Definition left,
    Definition right,
  ) : super(inputCount: 2) {
    setInputAt(0, left);
    setInputAt(1, right);
  }

  Definition get left => inputDefAt(0);
  Definition get right => inputDefAt(1);
  TargetBlock get trueSuccessor => block!.successors[0] as TargetBlock;
  TargetBlock get falseSuccessor => block!.successors[1] as TargetBlock;

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitCompareAndBranch(this);
}

/// Allocate a fixed-size List of given length.
final class AllocateList extends Definition
    with CanThrow, Pure, BackendInstruction {
  AllocateList(super.graph, super.sourcePosition, Definition length)
    : super(inputCount: 1) {
    setInputAt(0, length);
  }

  Definition get length => inputDefAt(0);

  CType get type =>
      StaticType(GlobalContext.instance.coreTypes.listNonNullableRawType);

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitAllocateList(this);
}

/// Set value of [index]-th element of the given fixed-size List.
final class SetListElement extends Instruction
    with NoThrow, HasSideEffects, BackendInstruction {
  SetListElement(
    super.graph,
    super.sourcePosition,
    Definition list,
    Definition index,
    Definition value,
  ) : super(inputCount: 3) {
    setInputAt(0, list);
    setInputAt(1, index);
    setInputAt(2, value);
  }

  Definition get list => inputDefAt(0);
  Definition get index => inputDefAt(1);
  Definition get value => inputDefAt(2);

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitSetListElement(this);
}

/// Base class for move operations, part of [ParallelMove].
abstract base class MoveOp {}

/// Purpose of the [ParallelMove] operation, used to distinguish multiple
/// independent moves.
///
/// This enum also specifies the order of successive [ParallelMove] instructions,
/// e.g. for every two successive [ParallelMove] instructions it is guaranteed
/// that `instr.stage.index < instr.next.stage.index`.
enum ParallelMoveStage {
  // Move fixed output of the instruction to its desired location.
  output,
  // Spill output of the instruction.
  spill,
  // Split live ranges.
  split,
  // Moves at control flow edges (including phi moves).
  control,
  // Move instruction inputs to their fixed locations.
  input,
}

/// In native back-ends, register allocator inserts [ParallelMove]
/// instructions to copy values atomically between registers
/// and memory locations.
final class ParallelMove extends Instruction
    with NoThrow, HasSideEffects, BackendInstruction {
  final ParallelMoveStage stage;
  final List<MoveOp> moves = [];

  ParallelMove(FlowGraph graph, this.stage)
    : super(graph, noPosition, inputCount: 0);

  @override
  R accept<R>(InstructionVisitor<R> v) => v.visitParallelMove(this);
}
