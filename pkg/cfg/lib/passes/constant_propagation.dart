// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/visitor.dart';
import 'package:cfg/passes/pass.dart';
import 'package:cfg/utils/bit_vector.dart';

/// Sparse conditional constant propagation.
///
/// Performs constant propagation and unreachable code elimination
/// at the same time.
///
/// The algorithm is described in Wegman, Mark N. and Zadeck, F. Kenneth.
/// "Constant Propagation with Conditional Branches".
final class ConstantPropagation extends Pass
    implements InstructionVisitor<void> {
  final ConstantFolding constantFolding = ConstantFolding();

  // State transition for blocks: unreachable -> reachable.
  late final BitVector _reachable = BitVector(graph.preorder.length);

  // State transitions for definitions:
  //   unknown -> constant -> non-constant
  final Map<Definition, ConstantValue> _constantValues = {};
  late final BitVector _nonConstant = BitVector(graph.instructions.length);

  // State transitions for phis:
  //   unknown -> redundant -> non-redundant
  final Map<Phi, Definition> _redundantPhis = {};

  // Work lists for blocks and definitions, appended on state transitions.
  final _blockWorkList = <Block>[];
  final _definitionsWorkList = <Definition>[];

  ConstantPropagation() : super('ConstantPropagation');

  @override
  void run() {
    analyze();
    transform();
  }

  void analyze() {
    _addReachableBlock(graph.entryBlock);

    while (_blockWorkList.isNotEmpty || _definitionsWorkList.isNotEmpty) {
      while (_definitionsWorkList.isNotEmpty) {
        final def = _definitionsWorkList.removeLast();
        for (final use in def.inputUses) {
          final user = use.getInstruction(graph);
          if (_isReachable(user.block!)) {
            _visit(user);
          }
        }
      }
      while (_blockWorkList.isNotEmpty) {
        final block = _blockWorkList.removeLast();
        _visit(block);
      }
    }
  }

  void _visit(Instruction instr) {
    currentInstruction = instr;
    instr.accept(this);
  }

  bool _isReachable(Block block) => _reachable[block.preorderNumber];

  void _addReachableBlock(Block block) {
    if (!_isReachable(block)) {
      _reachable[block.preorderNumber] = true;
      _blockWorkList.add(block);
    }
  }

  bool _isNonConstant(Definition instr) => _nonConstant[instr.id];

  ConstantValue? _getConstantValue(Definition instr) =>
      instr is Constant ? instr.value : _constantValues[instr];

  void _setConstantValue(Definition instr, ConstantValue result) {
    assert(!_isNonConstant(instr));
    assert(instr is! Constant);
    final old = _constantValues[instr];
    if (old == null) {
      // State transition: unknown -> constant.
      _constantValues[instr] = result;
      _definitionsWorkList.add(instr);
    } else {
      // Constant -> same constant.
      assert(old == result);
    }
  }

  void _setNonConstant(Definition instr) {
    assert(instr is! Constant);
    if (!_isNonConstant(instr)) {
      // State transition: unknown or constant -> non-constant.
      _nonConstant[instr.id] = true;
      _constantValues.remove(instr);
      _definitionsWorkList.add(instr);
    }
  }

  void _setResult(Definition instr, ConstantValue? result) {
    if (result != null) {
      _setConstantValue(instr, result);
    } else {
      _setNonConstant(instr);
    }
  }

  void _setRedundantPhi(Phi instr, Definition originalInput) {
    final old = _redundantPhis[instr];
    if (old == null) {
      // State transition: unknown -> redundant.
      _redundantPhis[instr] = originalInput;
      _definitionsWorkList.add(instr);
    } else {
      // No state transition: redundant -> redundant with the same input.
      assert(old == originalInput);
    }
  }

  void _setNonRedundantPhi(Phi instr) {
    if (_redundantPhis.remove(instr) != null) {
      // State transition: redundant -> non-redundant.
      _definitionsWorkList.add(instr);
    }
  }

  Definition _unwrapRedundantPhi(Definition def) =>
      def is Phi ? (_redundantPhis[def] ?? def) : def;

  bool _sameDefinitions(Definition a, Definition b) =>
      _unwrapRedundantPhi(a) == _unwrapRedundantPhi(b);

  void visitBlock(Block block) {
    currentBlock = block;
    assert(_isReachable(block));
    var canThrow = false;
    for (final instr in block) {
      _visit(instr);
      canThrow = canThrow || instr.canThrow;
    }
    final exceptionHandler = block.exceptionHandler;
    if (exceptionHandler != null && canThrow) {
      _addReachableBlock(exceptionHandler);
    }
    currentBlock = null;
  }

  @override
  void visitEntryBlock(EntryBlock instr) => visitBlock(instr);

  @override
  void visitJoinBlock(JoinBlock instr) => visitBlock(instr);

  @override
  void visitTargetBlock(TargetBlock instr) => visitBlock(instr);

  @override
  void visitCatchBlock(CatchBlock instr) => visitBlock(instr);

  @override
  void visitGoto(Goto instr) {
    final target = instr.target;
    if (!_isReachable(target)) {
      _addReachableBlock(target);
    } else {
      // Re-visit phis in the target block as this predecessor
      // became reachable.
      if (target is JoinBlock) {
        for (final phi in target.phis) {
          _visit(phi);
        }
      }
    }
  }

  @override
  void visitBranch(Branch instr) {
    if (_isNonConstant(instr.condition)) {
      _addReachableBlock(instr.trueSuccessor);
      _addReachableBlock(instr.falseSuccessor);
      return;
    }
    ConstantValue? condition = _getConstantValue(instr.condition);
    if (condition != null) {
      _addReachableBlock(
        condition.boolValue ? instr.trueSuccessor : instr.falseSuccessor,
      );
    }
  }

  @override
  void visitCompareAndBranch(CompareAndBranch instr) {
    // Comparison and Branch should be optimized separately
    // before combined to CompareAndBranch.
    _addReachableBlock(instr.trueSuccessor);
    _addReachableBlock(instr.falseSuccessor);
  }

  @override
  void visitTryEntry(TryEntry instr) {
    _addReachableBlock(instr.tryBody);
    // Do not mark catch block as reachable here.
    // Catch block is marked reachable iff any instruction in the try body
    // can throw.
  }

  @override
  void visitPhi(Phi instr) {
    final preds = instr.block!.predecessors;
    assert(instr.inputCount == preds.length);
    var canBeConstant = true;
    var canBeRedundant = true;
    ConstantValue? constantValue;
    Definition? originalInput;
    for (int i = 0, n = instr.inputCount; i < n; ++i) {
      if (!_isReachable(preds[i])) {
        continue;
      }
      final input = instr.inputDefAt(i);
      if (input == instr) {
        continue;
      }
      if (_isNonConstant(input)) {
        // Any input is non-constant => phi is non-constant.
        _setNonConstant(instr);
        canBeConstant = false;
      } else if (canBeConstant) {
        ConstantValue? value = _getConstantValue(input);
        if (value == null) {
          // Unknown input => unknown phi.
          canBeConstant = false;
        } else {
          if (constantValue == null) {
            // First constant input is discovered.
            constantValue = value;
          } else if (constantValue != value) {
            // Two constant inputs with different values =>
            // phi is non-constant.
            _setNonConstant(instr);
            canBeConstant = false;
          }
        }
      }
      if (canBeRedundant) {
        if (originalInput == null) {
          originalInput = input;
        } else if (input != originalInput) {
          canBeRedundant = false;
        }
      }
    }
    if (canBeConstant) {
      _setConstantValue(instr, constantValue!);
    }
    if (canBeRedundant) {
      _setRedundantPhi(instr, originalInput!);
    } else {
      _setNonRedundantPhi(instr);
    }
  }

  @override
  void visitReturn(Return instr) {}

  @override
  void visitConstant(Constant instr) {
    // There is no need to flood _constantValues map with Constant
    // instructions as they are handled in _getConstantValue directly
    // and will not be replaced.
  }

  @override
  void visitDirectCall(DirectCall instr) {
    _setNonConstant(instr);
  }

  @override
  void visitInterfaceCall(InterfaceCall instr) {
    _setNonConstant(instr);
  }

  @override
  void visitClosureCall(ClosureCall instr) {
    _setNonConstant(instr);
  }

  @override
  void visitDynamicCall(DynamicCall instr) {
    _setNonConstant(instr);
  }

  @override
  void visitParameter(Parameter instr) {
    _setNonConstant(instr);
  }

  @override
  void visitLoadLocal(LoadLocal instr) =>
      throw 'Should not be used in SSA form.';

  @override
  void visitStoreLocal(StoreLocal instr) =>
      throw 'Should not be used in SSA form.';

  @override
  void visitLoadInstanceField(LoadInstanceField instr) {
    _setNonConstant(instr);
  }

  @override
  void visitStoreInstanceField(StoreInstanceField instr) {}

  @override
  void visitLoadStaticField(LoadStaticField instr) {
    _setNonConstant(instr);
  }

  @override
  void visitStoreStaticField(StoreStaticField instr) {}

  @override
  void visitThrow(Throw instr) {}

  @override
  void visitNullCheck(NullCheck instr) {
    if (_isNonConstant(instr.operand)) {
      _setNonConstant(instr);
      return;
    }
    ConstantValue? operand = _getConstantValue(instr.operand);
    if (operand != null) {
      if (!operand.isNull) {
        _setResult(instr, operand);
      } else {
        _setNonConstant(instr);
      }
    }
  }

  @override
  void visitTypeParameters(TypeParameters instr) {
    _setNonConstant(instr);
  }

  @override
  void visitTypeCast(TypeCast instr) {
    if (_isNonConstant(instr.operand)) {
      _setNonConstant(instr);
      return;
    }
    ConstantValue? operand = _getConstantValue(instr.operand);
    if (operand != null) {
      if (operand.type.isSubtypeOf(instr.testedType)) {
        _setResult(instr, operand);
      } else {
        _setNonConstant(instr);
      }
    }
  }

  @override
  void visitTypeTest(TypeTest instr) {
    if (_isNonConstant(instr.operand)) {
      _setNonConstant(instr);
      return;
    }
    ConstantValue? operand = _getConstantValue(instr.operand);
    if (operand != null) {
      _setResult(
        instr,
        ConstantValue.fromBool(operand.type.isSubtypeOf(instr.testedType)),
      );
    }
  }

  @override
  void visitTypeArguments(TypeArguments instr) {
    _setNonConstant(instr);
  }

  @override
  void visitTypeLiteral(TypeLiteral instr) {
    _setNonConstant(instr);
  }

  @override
  void visitAllocateObject(AllocateObject instr) {
    _setNonConstant(instr);
  }

  @override
  void visitAllocateClosure(AllocateClosure instr) {
    _setNonConstant(instr);
  }

  @override
  void visitAllocateListLiteral(AllocateListLiteral instr) {
    _setNonConstant(instr);
  }

  @override
  void visitAllocateMapLiteral(AllocateMapLiteral instr) {
    _setNonConstant(instr);
  }

  @override
  void visitStringInterpolation(StringInterpolation instr) {
    for (int i = 0, n = instr.inputCount; i < n; ++i) {
      if (_isNonConstant(instr.inputDefAt(i))) {
        _setNonConstant(instr);
        return;
      }
    }
    final operands = <ConstantValue>[];
    for (int i = 0, n = instr.inputCount; i < n; ++i) {
      final operand = _getConstantValue(instr.inputDefAt(i));
      if (operand == null) {
        return;
      }
      operands.add(operand);
    }
    ConstantValue? result = constantFolding.stringInterpolation(operands);
    if (result != null) {
      _setResult(instr, result);
    } else {
      _setNonConstant(instr);
    }
  }

  @override
  void visitComparison(Comparison instr) {
    switch (instr.op) {
      case ComparisonOpcode.equal:
      case ComparisonOpcode.identical:
      case ComparisonOpcode.intEqual:
        if (_sameDefinitions(instr.left, instr.right)) {
          _setResult(instr, ConstantValue.fromBool(true));
          return;
        }
      case ComparisonOpcode.notEqual:
      case ComparisonOpcode.notIdentical:
      case ComparisonOpcode.intNotEqual:
        if (_sameDefinitions(instr.left, instr.right)) {
          _setResult(instr, ConstantValue.fromBool(false));
          return;
        }
      default:
    }
    if (_isNonConstant(instr.left) || _isNonConstant(instr.right)) {
      _setNonConstant(instr);
      return;
    }
    ConstantValue? left = _getConstantValue(instr.left);
    ConstantValue? right = _getConstantValue(instr.right);
    if (left != null && right != null) {
      ConstantValue result = constantFolding.comparison(instr.op, left, right);
      _setResult(instr, result);
    }
  }

  @override
  void visitBinaryIntOp(BinaryIntOp instr) {
    if (_isNonConstant(instr.left) || _isNonConstant(instr.right)) {
      _setNonConstant(instr);
      return;
    }
    ConstantValue? left = _getConstantValue(instr.left);
    ConstantValue? right = _getConstantValue(instr.right);
    if (left != null && right != null) {
      ConstantValue? result = constantFolding.binaryIntOp(
        instr.op,
        left,
        right,
      );
      _setResult(instr, result);
    }
  }

  @override
  void visitUnaryIntOp(UnaryIntOp instr) {
    if (_isNonConstant(instr.operand)) {
      _setNonConstant(instr);
      return;
    }
    ConstantValue? operand = _getConstantValue(instr.operand);
    if (operand != null) {
      ConstantValue? result = constantFolding.unaryIntOp(instr.op, operand);
      _setResult(instr, result);
    }
  }

  @override
  void visitBinaryDoubleOp(BinaryDoubleOp instr) {
    if (_isNonConstant(instr.left) || _isNonConstant(instr.right)) {
      _setNonConstant(instr);
      return;
    }
    ConstantValue? left = _getConstantValue(instr.left);
    ConstantValue? right = _getConstantValue(instr.right);
    if (left != null && right != null) {
      ConstantValue? result = constantFolding.binaryDoubleOp(
        instr.op,
        left,
        right,
      );
      _setResult(instr, result);
    }
  }

  @override
  void visitUnaryDoubleOp(UnaryDoubleOp instr) {
    if (_isNonConstant(instr.operand)) {
      _setNonConstant(instr);
      return;
    }
    ConstantValue? operand = _getConstantValue(instr.operand);
    if (operand != null) {
      ConstantValue? result = constantFolding.unaryDoubleOp(instr.op, operand);
      _setResult(instr, result);
    }
  }

  @override
  void visitUnaryBoolOp(UnaryBoolOp instr) {
    if (_isNonConstant(instr.operand)) {
      _setNonConstant(instr);
      return;
    }
    ConstantValue? operand = _getConstantValue(instr.operand);
    if (operand != null) {
      ConstantValue? result = constantFolding.unaryBoolOp(instr.op, operand);
      _setResult(instr, result);
    }
  }

  @override
  void visitAllocateList(AllocateList instr) {
    _setNonConstant(instr);
  }

  @override
  void visitSetListElement(SetListElement instr) {}

  @override
  void visitParallelMove(ParallelMove instr) {}

  void transform() {
    for (final entry in _constantValues.entries) {
      final instr = entry.key;
      final constantValue = entry.value;
      instr.replaceUsesWith(graph.getConstant(constantValue));
      instr.removeFromGraph();
    }
    for (final entry in _redundantPhis.entries) {
      final instr = entry.key;
      final input = entry.value;
      if (!_constantValues.containsKey(instr)) {
        assert(!_constantValues.containsKey(input));
        instr.replaceUsesWith(input);
        instr.removeFromGraph();
      }
    }
    var recomputeControlFlow = false;
    for (final block in graph.preorder) {
      if (!_isReachable(block)) {
        for (final instr in block) {
          instr.removeInputsFromUseLists();
        }
        recomputeControlFlow = true;
      }
    }
    if (!recomputeControlFlow) {
      graph.invalidateInstructionNumbering();
      return;
    }
    for (final block in graph.preorder) {
      if (_isReachable(block)) {
        if (block is JoinBlock) {
          _transformPhis(block);
        }
        block.exceptionHandler = _transformExceptionHandler(
          block.exceptionHandler,
        );
        _transformLastInstruction(block);
      }
    }
    graph.discoverBlocks();
  }

  void _transformPhis(JoinBlock block) {
    var inputCount = 0;
    for (int i = 0, n = block.predecessors.length; i < n; ++i) {
      if (_isReachable(block.predecessors[i])) {
        if (inputCount < i) {
          // Move inputs corresponding to the reachable predecessor.
          for (final phi in block.phis) {
            phi.removeInputFromUseList(i);
            phi.setInputAt(inputCount, phi.inputDefAt(i));
            phi.addInputToUseList(inputCount);
          }
        }
        ++inputCount;
      } else {
        // Remove inputs corresponding to the unreachable predecessor.
        for (final phi in block.phis) {
          phi.removeInputFromUseList(i);
        }
      }
    }
    if (inputCount < block.predecessors.length) {
      // Adjust number of inputs.
      for (final phi in block.phis) {
        phi.truncateInputs(inputCount);
      }
    }
  }

  CatchBlock? _transformExceptionHandler(CatchBlock? handler) {
    while (handler != null && !_isReachable(handler)) {
      handler = handler.exceptionHandler;
    }
    return handler;
  }

  TargetBlock? _getSingleSuccessor(Block block) {
    final last = block.lastInstruction;
    switch (last) {
      case Goto():
        assert(_isReachable(last.target));
        return null;
      case Branch(:var condition):
        if (condition is Constant) {
          return condition.value.boolValue
              ? last.trueSuccessor
              : last.falseSuccessor;
        } else {
          assert(_isReachable(last.trueSuccessor));
          assert(_isReachable(last.falseSuccessor));
          return null;
        }
      case TryEntry():
        assert(_isReachable(last.tryBody));
        if (!_isReachable(last.catchBlock)) {
          return last.tryBody;
        }
        return null;
      case Return() || Throw():
        return null;
      default:
        throw 'Unexpected block end ${last.runtimeType}';
    }
  }

  void _transformLastInstruction(Block block) {
    TargetBlock? successor = _getSingleSuccessor(block);
    if (successor == null) {
      return;
    }
    assert(_isReachable(successor));
    // Replace last instruction with Goto.
    final last = block.lastInstruction;
    last.removeFromGraph();
    block.lastInstruction.appendInstruction(Goto(graph, last.sourcePosition));
    block.successors.clear();
    block.successors.add(successor);
  }
}
