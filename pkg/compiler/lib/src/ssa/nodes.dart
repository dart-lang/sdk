// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We might want to change the initialization of HInstruction so that
// `HInstruction.inputs` is initialized to `[]` in the field declaration, and
// the subclasses add the input instructions to the existing List. This would
// guarantee that `HInstruction.inputs` is a monomorphic. Experiments suggest
// that this would improve the SSA time by ~2%. The suggestion to use
// super-parameters is unhelpful if we do this, so the suggestion is suppressed.
//
// ignore_for_file: use_super_parameters

import 'package:front_end/src/api_unstable/dart2js.dart' show Link;

import '../closure.dart';
import '../common.dart';
import '../common/elements.dart';
import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../diagnostics/spannable_with_entity.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js_backend/specialized_checks.dart' show IsTestSpecialization;
import '../js_model/js_world.dart' show JClosedWorld;
import '../js_model/type_recipe.dart'
    show TypeEnvironmentStructure, TypeRecipe, TypeExpressionRecipe;
import '../native/behavior.dart';
import '../options.dart';
import '../universe/selector.dart' show Selector;
import '../universe/side_effects.dart' show SideEffects;
import '../util/util.dart';
import 'invoke_dynamic_specializers.dart';
import 'validate.dart';

abstract class HVisitor<R> {
  R visitAbs(HAbs node);
  R visitAdd(HAdd node);
  R visitAwait(HAwait node);
  R visitBitAnd(HBitAnd node);
  R visitBitNot(HBitNot node);
  R visitBitOr(HBitOr node);
  R visitBitXor(HBitXor node);
  R visitBoundsCheck(HBoundsCheck node);
  R visitBreak(HBreak node);
  R visitCharCodeAt(HCharCodeAt node);
  R visitConstant(HConstant node);
  R visitContinue(HContinue node);
  R visitCreate(HCreate node);
  R visitCreateBox(HCreateBox node);
  R visitDivide(HDivide node);
  R visitExit(HExit node);
  R visitExitTry(HExitTry node);
  R visitFieldGet(HFieldGet node);
  R visitFieldSet(HFieldSet node);
  R visitFunctionReference(HFunctionReference node);
  R visitInvokeExternal(HInvokeExternal node);
  R visitForeignCode(HForeignCode node);
  R visitGetLength(HGetLength node);
  R visitGoto(HGoto node);
  R visitGreater(HGreater node);
  R visitGreaterEqual(HGreaterEqual node);
  R visitIdentity(HIdentity node);
  R visitIf(HIf node);
  R visitIndex(HIndex node);
  R visitIndexAssign(HIndexAssign node);
  R visitInterceptor(HInterceptor node);
  R visitInvokeClosure(HInvokeClosure node);
  R visitInvokeDynamicGetter(HInvokeDynamicGetter node);
  R visitInvokeDynamicMethod(HInvokeDynamicMethod node);
  R visitInvokeDynamicSetter(HInvokeDynamicSetter node);
  R visitInvokeStatic(HInvokeStatic node);
  R visitInvokeSuper(HInvokeSuper node);
  R visitInvokeConstructorBody(HInvokeConstructorBody node);
  R visitInvokeGeneratorBody(HInvokeGeneratorBody node);
  R visitIsLateSentinel(HIsLateSentinel node);
  R visitLateValue(HLateValue node);
  R visitLazyStatic(HLazyStatic node);
  R visitLess(HLess node);
  R visitLessEqual(HLessEqual node);
  R visitLiteralList(HLiteralList node);
  R visitLocalGet(HLocalGet node);
  R visitLocalSet(HLocalSet node);
  R visitLocalValue(HLocalValue node);
  R visitLoopBranch(HLoopBranch node);
  R visitMultiply(HMultiply node);
  R visitNegate(HNegate node);
  R visitNot(HNot node);
  R visitOneShotInterceptor(HOneShotInterceptor node);
  R visitParameterValue(HParameterValue node);
  R visitPhi(HPhi node);
  R visitRangeConversion(HRangeConversion node);
  R visitReadModifyWrite(HReadModifyWrite node);
  R visitRef(HRef node);
  R visitRemainder(HRemainder node);
  R visitReturn(HReturn node);
  R visitShiftLeft(HShiftLeft node);
  R visitShiftRight(HShiftRight node);
  R visitStatic(HStatic node);
  R visitStaticStore(HStaticStore node);
  R visitStringConcat(HStringConcat node);
  R visitStringify(HStringify node);
  R visitSubtract(HSubtract node);
  R visitSwitch(HSwitch node);
  R visitThis(HThis node);
  R visitThrow(HThrow node);
  R visitThrowExpression(HThrowExpression node);
  R visitTruncatingDivide(HTruncatingDivide node);
  R visitTry(HTry node);
  R visitPrimitiveCheck(HPrimitiveCheck node);
  R visitBoolConversion(HBoolConversion node);
  R visitNullCheck(HNullCheck node);
  R visitLateReadCheck(HLateReadCheck node);
  R visitLateWriteOnceCheck(HLateWriteOnceCheck node);
  R visitLateInitializeOnceCheck(HLateInitializeOnceCheck node);
  R visitTypeKnown(HTypeKnown node);
  R visitYield(HYield node);

  // Instructions for 'dart:_rti'.
  R visitIsTest(HIsTest node);
  R visitIsTestSimple(HIsTestSimple node);
  R visitAsCheck(HAsCheck node);
  R visitAsCheckSimple(HAsCheckSimple node);
  R visitSubtypeCheck(HSubtypeCheck node);
  R visitLoadType(HLoadType node);
  R visitInstanceEnvironment(HInstanceEnvironment node);
  R visitTypeEval(HTypeEval node);
  R visitTypeBind(HTypeBind node);

  R visitArrayFlagsCheck(HArrayFlagsCheck node);
  R visitArrayFlagsGet(HArrayFlagsGet node);
  R visitArrayFlagsSet(HArrayFlagsSet node);
}

abstract class HGraphVisitor {
  void visitDominatorTree(HGraph graph) {
    // Recursion free version of:
    //
    //     void visitBasicBlockAndSuccessors(HBasicBlock block) {
    //       visitBasicBlock(block);
    //       List dominated = block.dominatedBlocks;
    //       for (int i = 0; i < dominated.length; i++) {
    //         visitBasicBlockAndSuccessors(dominated[i]);
    //       }
    //     }
    //     visitBasicBlockAndSuccessors(graph.entry);

    _Frame? frame = _Frame(null);
    frame.block = graph.entry;
    frame.index = 0;

    visitBasicBlock(frame.block);

    while (frame != null) {
      HBasicBlock block = frame.block;
      int index = frame.index;
      if (index < block.dominatedBlocks.length) {
        frame.index = index + 1;
        frame = frame.next ??= _Frame(frame);
        frame.block = block.dominatedBlocks[index];
        frame.index = 0;
        visitBasicBlock(frame.block);
        continue;
      }
      frame = frame.previous;
    }
  }

  void visitPostDominatorTree(HGraph graph) {
    // Recursion-free version of:
    //
    //     void visitBasicBlockAndSuccessors(HBasicBlock block) {
    //       List dominated = block.dominatedBlocks;
    //       for (int i = dominated.length - 1; i >= 0; i--) {
    //         visitBasicBlockAndSuccessors(dominated[i]);
    //       }
    //       visitBasicBlock(block);
    //     }
    //     visitBasicBlockAndSuccessors(graph.entry);

    _Frame? frame = _Frame(null);
    frame.block = graph.entry;
    frame.index = frame.block.dominatedBlocks.length;

    while (frame != null) {
      HBasicBlock block = frame.block;
      int index = frame.index;
      if (index > 0) {
        frame.index = index - 1;
        frame = frame.next ??= _Frame(frame);
        frame.block = block.dominatedBlocks[index - 1];
        frame.index = frame.block.dominatedBlocks.length;
        continue;
      }
      visitBasicBlock(block);
      frame = frame.previous;
    }
  }

  void visitBasicBlock(HBasicBlock block);
}

class _Frame {
  final _Frame? previous;
  _Frame? next;
  late HBasicBlock block;
  late int index;
  _Frame(this.previous);
}

abstract class HInstructionVisitor extends HGraphVisitor {
  HBasicBlock? currentBlock;

  void visitInstruction(HInstruction node);

  @override
  void visitBasicBlock(HBasicBlock node) {
    void visitInstructionList(HInstructionList list) {
      for (var instruction = list.first;
          instruction != null;
          instruction = instruction.next) {
        visitInstruction(instruction);
        assert(instruction.next != list.first);
      }
    }

    currentBlock = node;
    visitInstructionList(node);
  }
}

class HGraph {
  late MemberEntity element; // Used for debug printing.
  late HBasicBlock entry;
  late HBasicBlock exit;
  HThis? thisInstruction;

  /// `true` if this graph should be transformed by a sync*/async/async*
  /// rewrite.
  bool needsAsyncRewrite = false;

  /// If this function requires an async rewrite, this is the element type of
  /// the generator.
  DartType? asyncElementType;

  /// Receiver parameter, set for methods using interceptor calling convention.
  HParameterValue? explicitReceiverParameter;
  bool isRecursiveMethod = false;
  bool calledInLoop = false;
  bool isLazyInitializer = false;

  final List<HBasicBlock> blocks = [];

  /// Nodes containing list allocations for which there is a known fixed length.
  // TODO(sigmund,sra): consider not storing this explicitly here (e.g. maybe
  // store it on HInstruction, or maybe this can be computed on demand).
  final Set<HInstruction> allocatedFixedLists = {};

  /// SourceInformation for the 'graph' is the location of the entry
  SourceInformation? sourceInformation;

  // We canonicalize all constants used within a graph so we do not
  // have to worry about them for global value numbering.
  Map<ConstantValue, HConstant> constants = {};

  HGraph() {
    entry = addNewBlock();
    // The exit block will be added later, so it has an id that is
    // after all others in the system.
    exit = HBasicBlock();
  }

  void addBlock(HBasicBlock block) {
    int id = blocks.length;
    block.id = id;
    blocks.add(block);
    assert(identical(blocks[id], block));
  }

  HBasicBlock addNewBlock() {
    HBasicBlock result = HBasicBlock();
    addBlock(result);
    return result;
  }

  HBasicBlock addNewLoopHeaderBlock(
      JumpTarget? target, List<LabelDefinition> labels) {
    HBasicBlock result = addNewBlock();
    result.loopInformation = HLoopInformation(result, target, labels);
    return result;
  }

  HConstant addConstant(ConstantValue constant, JClosedWorld closedWorld,
      {SourceInformation? sourceInformation}) {
    HConstant? result = constants[constant];
    // TODO(johnniwinther): Support source information per constant reference.
    if (result == null) {
      if (!constant.isConstant) {
        // We use `null` as the value for invalid constant expressions.
        constant = const NullConstantValue();
      }
      AbstractValue type = closedWorld.abstractValueDomain
          .computeAbstractValueForConstant(constant);
      result = HConstant._internal(constant, type)
        ..sourceInformation = sourceInformation;
      entry.addAtExit(result);
      constants[constant] = result;
    } else if (result.block == null) {
      // The constant was not used anymore.
      entry.addAtExit(result);
    }
    return result;
  }

  HConstant addDeferredConstant(DeferredGlobalConstantValue constant,
      SourceInformation? sourceInformation, JClosedWorld closedWorld) {
    return addConstant(constant, closedWorld,
        sourceInformation: sourceInformation);
  }

  HConstant addConstantInt(int i, JClosedWorld closedWorld) {
    return addConstant(constant_system.createIntFromInt(i), closedWorld);
  }

  HConstant addConstantIntAsUnsigned(int i, JClosedWorld closedWorld) {
    return addConstant(
        constant_system.createInt(BigInt.from(i).toUnsigned(64)), closedWorld);
  }

  HConstant addConstantDouble(double d, JClosedWorld closedWorld) {
    return addConstant(constant_system.createDouble(d), closedWorld);
  }

  HConstant addConstantString(String str, JClosedWorld closedWorld) {
    return addConstant(constant_system.createString(str), closedWorld);
  }

  HConstant addConstantStringFromName(js.Name name, JClosedWorld closedWorld) {
    return addConstant(JsNameConstantValue(js.quoteName(name)), closedWorld);
  }

  HConstant addConstantBool(bool value, JClosedWorld closedWorld) {
    return addConstant(constant_system.createBool(value), closedWorld);
  }

  HConstant addConstantNull(JClosedWorld closedWorld) {
    return addConstant(constant_system.createNull(), closedWorld);
  }

  HConstant addConstantUnreachable(JClosedWorld closedWorld) {
    // A constant with an empty type used as the HInstruction of an expression
    // in an unreachable context.
    return addConstant(UnreachableConstantValue(), closedWorld);
  }

  HConstant addConstantLateSentinel(JClosedWorld closedWorld,
          {SourceInformation? sourceInformation}) =>
      addConstant(LateSentinelConstantValue(), closedWorld,
          sourceInformation: sourceInformation);

  void finalize() {
    addBlock(exit);
    exit.open();
    exit.close(HExit());
    assignDominators();
  }

  void assignDominators() {
    // Run through the blocks in order of increasing ids so we are
    // guaranteed that we have computed dominators for all blocks
    // higher up in the dominator tree.
    for (int i = 0, length = blocks.length; i < length; i++) {
      HBasicBlock block = blocks[i];
      List<HBasicBlock> predecessors = block.predecessors;
      if (block.isLoopHeader()) {
        block.assignCommonDominator(predecessors[0]);
      } else {
        for (int j = predecessors.length - 1; j >= 0; j--) {
          block.assignCommonDominator(predecessors[j]);
        }
      }
    }
    assignDominatorRanges();
  }

  void assignDominatorRanges() {
    // DFS walk of dominator tree to assign dfs-in and dfs-out numbers to basic
    // blocks. A dominator has a dfs-in..dfs-out range that includes the range
    // of the dominated block. See [HGraphVisitor.visitDominatorTree] for
    // recursion-free schema.
    _Frame? frame = _Frame(null);
    frame.block = entry;
    frame.index = 0;

    int dfsNumber = 0;
    frame.block.dominatorDfsIn = dfsNumber;

    while (frame != null) {
      HBasicBlock block = frame.block;
      int index = frame.index;
      if (index < block.dominatedBlocks.length) {
        frame.index = index + 1;
        frame = frame.next ??= _Frame(frame);
        frame.block = block.dominatedBlocks[index];
        frame.index = 0;
        frame.block.dominatorDfsIn = ++dfsNumber;
        continue;
      }
      block.dominatorDfsOut = dfsNumber;
      frame = frame.previous;
    }
  }

  bool isValid() {
    HValidator validator = HValidator();
    validator.visitGraph(this);
    return validator.isValid;
  }

  @override
  String toString() => 'HGraph($element)';
}

class HBaseVisitor<R> extends HGraphVisitor implements HVisitor<R> {
  HBasicBlock? currentBlock;

  @override
  void visitBasicBlock(HBasicBlock node) {
    currentBlock = node;

    for (var instruction = node.first;
        instruction != null;
        instruction = instruction.next) {
      instruction.accept(this);
    }
  }

  R visitInstruction(HInstruction instruction) => null as R;

  R visitBinaryArithmetic(HBinaryArithmetic node) => visitInvokeBinary(node);
  R visitBinaryBitOp(HBinaryBitOp node) => visitInvokeBinary(node);
  R visitInvoke(HInvoke node) => visitInstruction(node);
  R visitInvokeBinary(HInvokeBinary node) => visitInstruction(node);
  R visitInvokeDynamic(HInvokeDynamic node) => visitInvoke(node);
  R visitInvokeDynamicField(HInvokeDynamicField node) =>
      visitInvokeDynamic(node);
  R visitInvokeUnary(HInvokeUnary node) => visitInstruction(node);
  R visitConditionalBranch(HConditionalBranch node) => visitControlFlow(node);
  R visitControlFlow(HControlFlow node) => visitInstruction(node);
  R visitFieldAccess(HFieldAccess node) => visitInstruction(node);
  R visitRelational(HRelational node) => visitInvokeBinary(node);

  @override
  R visitAbs(HAbs node) => visitInvokeUnary(node);
  @override
  R visitAdd(HAdd node) => visitBinaryArithmetic(node);
  @override
  R visitBitAnd(HBitAnd node) => visitBinaryBitOp(node);
  @override
  R visitBitNot(HBitNot node) => visitInvokeUnary(node);
  @override
  R visitBitOr(HBitOr node) => visitBinaryBitOp(node);
  @override
  R visitBitXor(HBitXor node) => visitBinaryBitOp(node);
  @override
  R visitBoundsCheck(HBoundsCheck node) => visitCheck(node);
  @override
  R visitBreak(HBreak node) => visitJump(node);
  @override
  R visitContinue(HContinue node) => visitJump(node);
  @override
  R visitCharCodeAt(HCharCodeAt node) => visitInstruction(node);
  R visitCheck(HCheck node) => visitInstruction(node);
  @override
  R visitConstant(HConstant node) => visitInstruction(node);
  @override
  R visitCreate(HCreate node) => visitInstruction(node);
  @override
  R visitCreateBox(HCreateBox node) => visitInstruction(node);
  @override
  R visitDivide(HDivide node) => visitBinaryArithmetic(node);
  @override
  R visitExit(HExit node) => visitControlFlow(node);
  @override
  R visitExitTry(HExitTry node) => visitControlFlow(node);
  @override
  R visitFieldGet(HFieldGet node) => visitFieldAccess(node);
  @override
  R visitFieldSet(HFieldSet node) => visitFieldAccess(node);
  @override
  R visitFunctionReference(HFunctionReference node) => visitInstruction(node);
  @override
  R visitInvokeExternal(HInvokeExternal node) => visitInstruction(node);
  @override
  R visitForeignCode(HForeignCode node) => visitInstruction(node);
  @override
  R visitGetLength(HGetLength node) => visitInstruction(node);
  @override
  R visitGoto(HGoto node) => visitControlFlow(node);
  @override
  R visitGreater(HGreater node) => visitRelational(node);
  @override
  R visitGreaterEqual(HGreaterEqual node) => visitRelational(node);
  @override
  R visitIdentity(HIdentity node) => visitRelational(node);
  @override
  R visitIf(HIf node) => visitConditionalBranch(node);
  @override
  R visitIndex(HIndex node) => visitInstruction(node);
  @override
  R visitIndexAssign(HIndexAssign node) => visitInstruction(node);
  @override
  R visitInterceptor(HInterceptor node) => visitInstruction(node);
  @override
  R visitInvokeClosure(HInvokeClosure node) => visitInvokeDynamic(node);
  @override
  R visitInvokeConstructorBody(HInvokeConstructorBody node) =>
      visitInvokeStatic(node);
  @override
  R visitInvokeGeneratorBody(HInvokeGeneratorBody node) =>
      visitInvokeStatic(node);
  @override
  R visitInvokeDynamicMethod(HInvokeDynamicMethod node) =>
      visitInvokeDynamic(node);
  @override
  R visitInvokeDynamicGetter(HInvokeDynamicGetter node) =>
      visitInvokeDynamicField(node);
  @override
  R visitInvokeDynamicSetter(HInvokeDynamicSetter node) =>
      visitInvokeDynamicField(node);
  @override
  R visitInvokeStatic(HInvokeStatic node) => visitInvoke(node);
  @override
  R visitInvokeSuper(HInvokeSuper node) => visitInvokeStatic(node);
  R visitJump(HJump node) => visitControlFlow(node);
  @override
  R visitLazyStatic(HLazyStatic node) => visitInstruction(node);
  @override
  R visitLess(HLess node) => visitRelational(node);
  @override
  R visitLessEqual(HLessEqual node) => visitRelational(node);
  @override
  R visitLiteralList(HLiteralList node) => visitInstruction(node);
  R visitLocalAccess(HLocalAccess node) => visitInstruction(node);
  @override
  R visitLocalGet(HLocalGet node) => visitLocalAccess(node);
  @override
  R visitLocalSet(HLocalSet node) => visitLocalAccess(node);
  @override
  R visitLocalValue(HLocalValue node) => visitInstruction(node);
  @override
  R visitLoopBranch(HLoopBranch node) => visitConditionalBranch(node);
  @override
  R visitNegate(HNegate node) => visitInvokeUnary(node);
  @override
  R visitNot(HNot node) => visitInstruction(node);
  @override
  R visitOneShotInterceptor(HOneShotInterceptor node) =>
      visitInvokeDynamic(node);
  @override
  R visitPhi(HPhi node) => visitInstruction(node);
  @override
  R visitMultiply(HMultiply node) => visitBinaryArithmetic(node);
  @override
  R visitParameterValue(HParameterValue node) => visitLocalValue(node);
  @override
  R visitRangeConversion(HRangeConversion node) => visitCheck(node);
  @override
  R visitReadModifyWrite(HReadModifyWrite node) => visitInstruction(node);
  @override
  R visitRef(HRef node) => node.value.accept(this);
  @override
  R visitRemainder(HRemainder node) => visitBinaryArithmetic(node);
  @override
  R visitReturn(HReturn node) => visitControlFlow(node);
  @override
  R visitShiftLeft(HShiftLeft node) => visitBinaryBitOp(node);
  @override
  R visitShiftRight(HShiftRight node) => visitBinaryBitOp(node);
  @override
  R visitSubtract(HSubtract node) => visitBinaryArithmetic(node);
  @override
  R visitSwitch(HSwitch node) => visitControlFlow(node);
  @override
  R visitStatic(HStatic node) => visitInstruction(node);
  @override
  R visitStaticStore(HStaticStore node) => visitInstruction(node);
  @override
  R visitStringConcat(HStringConcat node) => visitInstruction(node);
  @override
  R visitStringify(HStringify node) => visitInstruction(node);
  @override
  R visitThis(HThis node) => visitParameterValue(node);
  @override
  R visitThrow(HThrow node) => visitControlFlow(node);
  @override
  R visitThrowExpression(HThrowExpression node) => visitInstruction(node);
  @override
  R visitTruncatingDivide(HTruncatingDivide node) =>
      visitBinaryArithmetic(node);
  @override
  R visitTry(HTry node) => visitControlFlow(node);
  @override
  R visitIsLateSentinel(HIsLateSentinel node) => visitInstruction(node);
  @override
  R visitLateValue(HLateValue node) => visitInstruction(node);
  @override
  R visitBoolConversion(HBoolConversion node) => visitCheck(node);
  @override
  R visitNullCheck(HNullCheck node) => visitCheck(node);
  R visitLateCheck(HLateCheck node) => visitCheck(node);
  @override
  R visitLateReadCheck(HLateReadCheck node) => visitLateCheck(node);
  @override
  R visitLateWriteOnceCheck(HLateWriteOnceCheck node) => visitLateCheck(node);
  @override
  R visitLateInitializeOnceCheck(HLateInitializeOnceCheck node) =>
      visitLateCheck(node);
  @override
  R visitPrimitiveCheck(HPrimitiveCheck node) => visitCheck(node);
  @override
  R visitTypeKnown(HTypeKnown node) => visitCheck(node);
  @override
  R visitAwait(HAwait node) => visitInstruction(node);
  @override
  R visitYield(HYield node) => visitInstruction(node);

  @override
  R visitIsTest(HIsTest node) => visitInstruction(node);
  @override
  R visitIsTestSimple(HIsTestSimple node) => visitInstruction(node);
  @override
  R visitAsCheck(HAsCheck node) => visitCheck(node);
  @override
  R visitAsCheckSimple(HAsCheckSimple node) => visitCheck(node);
  @override
  R visitSubtypeCheck(HSubtypeCheck node) => visitCheck(node);
  @override
  R visitLoadType(HLoadType node) => visitInstruction(node);
  @override
  R visitInstanceEnvironment(HInstanceEnvironment node) =>
      visitInstruction(node);
  @override
  R visitTypeEval(HTypeEval node) => visitInstruction(node);
  @override
  R visitTypeBind(HTypeBind node) => visitInstruction(node);

  @override
  R visitArrayFlagsCheck(HArrayFlagsCheck node) => visitCheck(node);
  @override
  R visitArrayFlagsGet(HArrayFlagsGet node) => visitInstruction(node);
  @override
  R visitArrayFlagsSet(HArrayFlagsSet node) => visitInstruction(node);
}

class SubGraph {
  // The first and last block of the sub-graph.
  final HBasicBlock start;
  final HBasicBlock end;

  const SubGraph(this.start, this.end);

  bool contains(HBasicBlock block) {
    return start.id <= block.id && block.id <= end.id;
  }
}

class SubExpression extends SubGraph {
  const SubExpression(super.start, super.end);

  /// Find the condition expression if this sub-expression is a condition.
  HInstruction? get conditionExpression {
    HInstruction? last = end.last;
    if (last is HConditionalBranch || last is HSwitch) return last!.inputs[0];
    return null;
  }
}

class HInstructionList {
  HInstruction? first = null;
  HInstruction? last = null;

  bool get isEmpty {
    return first == null;
  }

  void internalAddAfter(HInstruction? cursor, HInstruction instruction) {
    if (cursor == null) {
      assert(isEmpty);
      first = last = instruction;
    } else if (identical(cursor, last)) {
      last!.next = instruction;
      instruction.previous = last;
      last = instruction;
    } else {
      instruction.previous = cursor;
      instruction.next = cursor.next;
      cursor.next!.previous = instruction;
      cursor.next = instruction;
    }
  }

  void internalAddBefore(HInstruction? cursor, HInstruction instruction) {
    if (cursor == null) {
      assert(isEmpty);
      first = last = instruction;
    } else if (identical(cursor, first)) {
      first!.previous = instruction;
      instruction.next = first;
      first = instruction;
    } else {
      instruction.next = cursor;
      instruction.previous = cursor.previous;
      cursor.previous!.next = instruction;
      cursor.previous = instruction;
    }
  }

  void detach(HInstruction instruction) {
    assert(_truncatedContainsForAssert(instruction));
    assert(instruction.isInBasicBlock());
    if (instruction.previous == null) {
      first = instruction.next;
    } else {
      instruction.previous!.next = instruction.next;
    }
    if (instruction.next == null) {
      last = instruction.previous;
    } else {
      instruction.next!.previous = instruction.previous;
    }
    instruction.previous = null;
    instruction.next = null;
  }

  void remove(HInstruction instruction) {
    assert(instruction.usedBy.isEmpty);
    detach(instruction);
  }

  /// Linear search for [instruction].
  bool contains(HInstruction instruction) {
    for (var cursor = first; cursor != null; cursor = cursor.next) {
      if (identical(cursor, instruction)) return true;
    }

    return false;
  }

  /// Linear search for [instruction], up to a limit of 100. Returns whether
  /// the instruction is found or the list is too big.
  ///
  /// This is used for assertions only: some tests have pathological cases where
  /// the basic blocks are huge (50K nodes!), and we found that checking for
  /// [contains] within our assertions made compilation really slow.
  bool _truncatedContainsForAssert(HInstruction instruction) {
    int count = 0;
    for (var cursor = first; cursor != null; cursor = cursor.next) {
      count++;
      if (count > 100) return true;
      if (identical(cursor, instruction)) return true;
    }

    return false;
  }
}

class HPhiList extends HInstructionList {
  HPhi? get firstPhi => first as HPhi?;
  HPhi? get lastPhi => last as HPhi?;
}

enum _BasicBlockStatus {
  new_,
  open,
  closed,
}

class HBasicBlock extends HInstructionList {
  // The [id] must be such that any successor's id is greater than
  // this [id]. The exception are back-edges.
  int id = -1;

  _BasicBlockStatus _status = _BasicBlockStatus.new_;

  var phis = HPhiList();

  HLoopInformation? loopInformation = null;
  HBlockFlow? blockFlow = null;
  HBasicBlock? parentLoopHeader = null;
  bool isLive = true;

  final List<HBasicBlock> predecessors = [];
  List<HBasicBlock> successors = const [];

  HBasicBlock? dominator = null;
  final List<HBasicBlock> dominatedBlocks = [];
  int dominatorDfsIn = -1;
  int dominatorDfsOut = -1;

  HBasicBlock();

  @override
  int get hashCode => id;

  bool get isNew => _status == _BasicBlockStatus.new_;
  bool get isOpen => _status == _BasicBlockStatus.open;
  bool get isClosed => _status == _BasicBlockStatus.closed;

  bool isLoopHeader() {
    return loopInformation != null;
  }

  void setBlockFlow(HBlockInformation blockInfo, HBasicBlock? continuation) {
    blockFlow = HBlockFlow(blockInfo, continuation);
  }

  bool isLabeledBlock() =>
      blockFlow != null && blockFlow!.body is HLabeledBlockInformation;

  HBasicBlock? get enclosingLoopHeader {
    if (isLoopHeader()) return this;
    return parentLoopHeader;
  }

  void open() {
    assert(isNew);
    _status = _BasicBlockStatus.open;
  }

  void close(HControlFlow end) {
    assert(isOpen);
    addAfter(last, end);
    _status = _BasicBlockStatus.closed;
  }

  void addAtEntry(HInstruction instruction) {
    assert(instruction is! HPhi);
    internalAddBefore(first, instruction);
    instruction.notifyAddedToBlock(this);
  }

  void addAtExit(HInstruction instruction) {
    assert(isClosed);
    assert(last is HControlFlow);
    assert(instruction is! HPhi);
    internalAddBefore(last, instruction);
    instruction.notifyAddedToBlock(this);
  }

  void moveAtExit(HInstruction instruction) {
    assert(instruction is! HPhi);
    assert(instruction.isInBasicBlock());
    assert(isClosed);
    assert(last is HControlFlow);
    internalAddBefore(last, instruction);
    instruction.block = this;
    assert(isValid());
  }

  void add(HInstruction instruction) {
    assert(instruction is! HControlFlow);
    assert(instruction is! HPhi);
    internalAddAfter(last, instruction);
    instruction.notifyAddedToBlock(this);
  }

  void addPhi(HPhi phi) {
    assert(phi.inputs.length == 0 || phi.inputs.length == predecessors.length);
    assert(phi.block == null);
    phis.internalAddAfter(phis.last, phi);
    phi.notifyAddedToBlock(this);
  }

  void removePhi(HPhi phi) {
    phis.remove(phi);
    assert(phi.block == this);
    phi.notifyRemovedFromBlock();
  }

  void addAfter(HInstruction? cursor, HInstruction instruction) {
    assert(cursor is! HPhi);
    assert(instruction is! HPhi);
    assert(isOpen || isClosed);
    internalAddAfter(cursor, instruction);
    instruction.notifyAddedToBlock(this);
  }

  void addBefore(HInstruction? cursor, HInstruction instruction) {
    assert(cursor is! HPhi);
    assert(instruction is! HPhi);
    assert(isOpen || isClosed);
    internalAddBefore(cursor, instruction);
    instruction.notifyAddedToBlock(this);
  }

  @override
  void remove(HInstruction instruction) {
    assert(isOpen || isClosed);
    assert(instruction is! HPhi);
    super.remove(instruction);
    assert(instruction.block == this);
    instruction.notifyRemovedFromBlock();
  }

  void addSuccessor(HBasicBlock block) {
    if (successors.isEmpty) {
      successors = [block];
    } else {
      successors.add(block);
    }
    block.predecessors.add(this);
  }

  void postProcessLoopHeader() {
    assert(isLoopHeader());
    // Only the first entry into the loop is from outside the
    // loop. All other entries must be back edges.
    for (int i = 1, length = predecessors.length; i < length; i++) {
      loopInformation!.addBackEdge(predecessors[i]);
    }
  }

  /// Rewrites all uses of the [from] instruction to using the [to]
  /// instruction instead.
  void rewrite(HInstruction from, HInstruction to) {
    for (HInstruction use in from.usedBy) {
      use.rewriteInput(from, to);
    }
    to.usedBy.addAll(from.usedBy);
    from.usedBy.clear();
  }

  /// Rewrites all uses of the [from] instruction to using either the
  /// [to] instruction, or a [HCheck] instruction that has better type
  /// information on [to], and that dominates the user.
  void rewriteWithBetterUser(HInstruction? from, HInstruction to) {
    // BUG(11841): Turn this method into a phase to be run after GVN phases.
    Link<HCheck> better = const Link();
    for (HInstruction user in to.usedBy) {
      if (user == from || user is! HCheck) continue;
      HCheck check = user;
      if (check.checkedInput == to) {
        better = better.prepend(user);
      }
    }

    if (better.isEmpty) return rewrite(from!, to);

    L1:
    for (HInstruction user in from!.usedBy) {
      for (HCheck check in better) {
        if (check.dominates(user)) {
          user.rewriteInput(from, check);
          check.usedBy.add(user);
          continue L1;
        }
      }
      user.rewriteInput(from, to);
      to.usedBy.add(user);
    }
    from.usedBy.clear();
  }

  bool isExitBlock() {
    return identical(first, last) && first is HExit;
  }

  void addDominatedBlock(HBasicBlock block) {
    assert(isClosed);
    assert(id >= 0 && block.id >= 0);
    assert(dominatedBlocks.indexOf(block) < 0);
    // Keep the list of dominated blocks sorted such that if there are two
    // succeeding blocks in the list, the predecessor is before the successor.
    // Assume that we add the dominated blocks in the right order.
    int index = dominatedBlocks.length;
    while (index > 0 && dominatedBlocks[index - 1].id > block.id) {
      index--;
    }
    if (index == dominatedBlocks.length) {
      dominatedBlocks.add(block);
    } else {
      dominatedBlocks.insert(index, block);
    }
    assert(block.dominator == null);
    block.dominator = this;
  }

  void removeDominatedBlock(HBasicBlock block) {
    assert(isClosed);
    assert(id >= 0 && block.id >= 0);
    int index = dominatedBlocks.indexOf(block);
    assert(index >= 0);
    if (index == dominatedBlocks.length - 1) {
      dominatedBlocks.removeLast();
    } else {
      dominatedBlocks.removeRange(index, index + 1);
    }
    assert(identical(block.dominator, this));
    block.dominator = null;
  }

  void assignCommonDominator(HBasicBlock predecessor) {
    assert(isClosed);
    if (dominator == null) {
      // If this basic block doesn't have a dominator yet we use the
      // given predecessor as the dominator.
      predecessor.addDominatedBlock(this);
    } else if (predecessor.dominator != null) {
      // If the predecessor has a dominator and this basic block has a
      // dominator, we find a common parent in the dominator tree and
      // use that as the dominator.
      HBasicBlock block0 = dominator!;
      HBasicBlock block1 = predecessor;
      while (!identical(block0, block1)) {
        if (block0.id > block1.id) {
          block0 = block0.dominator!;
        } else {
          block1 = block1.dominator!;
        }
        //assert(block0 != null && block1 != null);
      }
      if (!identical(dominator, block0)) {
        dominator!.removeDominatedBlock(this);
        block0.addDominatedBlock(this);
      }
    }
  }

  void forEachPhi(void f(HPhi phi)) {
    var current = phis.firstPhi;
    while (current != null) {
      final next = current.nextPhi;
      f(current);
      current = next;
    }
  }

  void forEachInstruction(void f(HInstruction instruction)) {
    var current = first;
    while (current != null) {
      final next = current.next;
      f(current);
      current = next;
    }
  }

  bool isValid() {
    assert(isClosed);
    HValidator validator = HValidator();
    validator.visitBasicBlock(this);
    return validator.isValid;
  }

  bool dominates(HBasicBlock other) {
    return this.dominatorDfsIn <= other.dominatorDfsIn &&
        other.dominatorDfsOut <= this.dominatorDfsOut;
  }

  @override
  String toString() => 'HBasicBlock($id)';
}

enum _GvnType {
  undefined,
  boundsCheck,
  interceptor,
  add,
  divide,
  multiply,
  subtract,
  shiftLeft,
  bitOr,
  bitAnd,
  bitXor,
  negate,
  bitNot,
  not,
  identity,
  greater,
  greaterEqual,
  less,
  lessEqual,
  static,
  staticStore,
  fieldGet,
  functionReference,
  typeKnown,
  invokeStatic,
  index_,
  invokeDynamic,
  shiftRight,
  truncatingDivide,
  invokeExternal,
  foreignCode,
  remainder,
  getLength,
  abs,
  boolConversion,
  nullCheck,
  primitiveCheck,
  isTest,
  isTestSimple,
  asCheck,
  asCheckSimple,
  subtypeCheck,
  loadType,
  instanceEnvironment,
  typeEval,
  typeBind,
  isLateSentinel,
  stringConcat,
  stringify,
  lateReadCheck,
  lateWriteOnceCheck,
  lateInitializeOnceCheck,
  charCodeAt,
  arrayFlagsGet,
  arrayFlagsCheck,
}

abstract class HInstruction implements SpannableWithEntity {
  Entity? sourceElement;
  SourceInformation? sourceInformation;

  final int id = idCounter++;
  static int idCounter = 0;

  // A HInstruction owns its [inputs] list. A fresh list is created in every
  // base class constructor to ensure that [inputs] is always a growable
  // List. Although many instructions have a fixed number of inputs (including
  // zero inputs), having a uniform growable representation is more flexible for
  // editing, and allows hundreds of method calls on [inputs] to be
  // devirtualized.
  final List<HInstruction> inputs;

  // Instructions that uses this instruction. A user is [usedBy] once per input
  // that is this instruction.
  //
  //     y = [x, x + 1, x];
  //
  // The [usedBy] for the instruction `x` has three elements, one for the
  // addition instruction and two for the list literal instruction, in no
  // particilar order.
  final List<HInstruction> usedBy = [];

  HBasicBlock? block;
  HInstruction? previous = null;
  HInstruction? next = null;

  /// Type of the instruction.
  late AbstractValue instructionType;

  SideEffects sideEffects = SideEffects.empty();
  bool _useGvn = false;

  // Main constructor copies the list of inputs to ensure ownership.
  HInstruction(List<HInstruction> initialInputs, this.instructionType)
      : inputs = [...initialInputs];

  // Convenience constructors that avoid an intermediate list.
  HInstruction._0(this.instructionType) : inputs = [];
  HInstruction._1(HInstruction input, this.instructionType) : inputs = [input];
  HInstruction._2(
      HInstruction input1, HInstruction input2, this.instructionType)
      : inputs = [input1, input2];

  HInstruction._noType() : inputs = [];

  @override
  Entity? get sourceEntity => sourceElement;

  @override
  SourceSpan? get sourceSpan => sourceInformation?.sourceSpan;

  @override
  int get hashCode => id;

  bool useGvn() => _useGvn;
  void setUseGvn() {
    _useGvn = true;
  }

  bool get isMovable => useGvn();

  /// A pure instruction is an instruction that does not have any side
  /// effect, nor any dependency. They can be moved anywhere in the
  /// graph.
  bool isPure(AbstractValueDomain domain) {
    return !sideEffects.hasSideEffects() &&
        !sideEffects.dependsOnSomething() &&
        !canThrow(domain);
  }

  /// An instruction is an 'allocation' is it is the sole alias for an object.
  /// This applies to instructions that allocate new objects and can be extended
  /// to methods that return other allocations without escaping them.
  bool isAllocation(AbstractValueDomain domain) => false;

  /// Overridden by [HCheck] to return the actual non-[HCheck]
  /// instruction it checks against.
  HInstruction nonCheck() => this;

  /// Can this node throw an exception?
  bool canThrow(AbstractValueDomain domain) => false;

  /// Does this node potentially affect control flow.
  bool isControlFlow() => false;

  bool isValue(AbstractValueDomain domain) =>
      domain.isPrimitiveValue(instructionType);

  AbstractBool isNull(AbstractValueDomain domain) =>
      domain.isNull(instructionType);

  AbstractBool isLateSentinel(AbstractValueDomain domain) =>
      domain.isLateSentinel(instructionType);

  AbstractBool isConflicting(AbstractValueDomain domain) =>
      domain.isEmpty(instructionType);

  AbstractBool isPrimitive(AbstractValueDomain domain) =>
      domain.isPrimitive(instructionType);

  AbstractBool isPrimitiveNumber(AbstractValueDomain domain) =>
      domain.isPrimitiveNumber(instructionType);

  AbstractBool isPrimitiveBoolean(AbstractValueDomain domain) =>
      domain.isPrimitiveBoolean(instructionType);

  AbstractBool isIndexablePrimitive(AbstractValueDomain domain) =>
      domain.isIndexablePrimitive(instructionType);

  AbstractBool isFixedArray(AbstractValueDomain domain) =>
      domain.isFixedArray(instructionType);

  AbstractBool isExtendableArray(AbstractValueDomain domain) =>
      domain.isExtendableArray(instructionType);

  AbstractBool isMutableArray(AbstractValueDomain domain) =>
      domain.isMutableArray(instructionType);

  AbstractBool isMutableIndexable(AbstractValueDomain domain) =>
      domain.isMutableIndexable(instructionType);

  AbstractBool isArray(AbstractValueDomain domain) =>
      domain.isArray(instructionType);

  AbstractBool isPrimitiveString(AbstractValueDomain domain) =>
      domain.isPrimitiveString(instructionType);

  AbstractBool isInteger(AbstractValueDomain domain) =>
      domain.isInteger(instructionType);

  AbstractBool isUInt32(AbstractValueDomain domain) =>
      domain.isUInt32(instructionType);

  AbstractBool isUInt31(AbstractValueDomain domain) =>
      domain.isUInt31(instructionType);

  AbstractBool isPositiveInteger(AbstractValueDomain domain) =>
      domain.isPositiveInteger(instructionType);

  AbstractBool isPositiveIntegerOrNull(AbstractValueDomain domain) =>
      domain.isPositiveIntegerOrNull(instructionType);

  AbstractBool isIntegerOrNull(AbstractValueDomain domain) =>
      domain.isIntegerOrNull(instructionType);

  AbstractBool isNumber(AbstractValueDomain domain) =>
      domain.isNumber(instructionType);

  AbstractBool isNumberOrNull(AbstractValueDomain domain) =>
      domain.isNumberOrNull(instructionType);

  AbstractBool isBoolean(AbstractValueDomain domain) =>
      domain.isBoolean(instructionType);

  AbstractBool isBooleanOrNull(AbstractValueDomain domain) =>
      domain.isBooleanOrNull(instructionType);

  AbstractBool isString(AbstractValueDomain domain) =>
      domain.isString(instructionType);

  AbstractBool isStringOrNull(AbstractValueDomain domain) =>
      domain.isStringOrNull(instructionType);

  AbstractBool isPrimitiveOrNull(AbstractValueDomain domain) =>
      domain.isPrimitiveOrNull(instructionType);

  HInstruction? getDartReceiver(JClosedWorld closedWorld) => null;
  bool onlyThrowsNSM() => false;

  bool isInBasicBlock() => block != null;

  bool gvnEquals(HInstruction other) {
    assert(useGvn() && other.useGvn());
    // Check that the type and the sideEffects match.
    bool hasSameType = typeEquals(other);
    assert(hasSameType == (_gvnType == other._gvnType));
    if (!hasSameType) return false;
    if (sideEffects != other.sideEffects) return false;
    // Check that the inputs match.
    final int inputsLength = inputs.length;
    final List<HInstruction> otherInputs = other.inputs;
    if (inputsLength != otherInputs.length) return false;
    for (int i = 0; i < inputsLength; i++) {
      if (!identical(inputs[i].nonCheck(), otherInputs[i].nonCheck())) {
        return false;
      }
    }
    // Check that the data in the instruction matches.
    return dataEquals(other);
  }

  int gvnHashCode() {
    int result = _gvnType.index;
    int length = inputs.length;
    for (int i = 0; i < length; i++) {
      result = (result * 19) + (inputs[i].nonCheck().id) + (result >> 7);
    }
    return result;
  }

  // These methods should be overwritten by instructions that
  // participate in global value numbering.
  _GvnType get _gvnType => _GvnType.undefined;
  bool typeEquals(covariant HInstruction other) => false;
  bool dataEquals(covariant HInstruction other) => false;

  R accept<R>(HVisitor<R> visitor);

  void notifyAddedToBlock(HBasicBlock targetBlock) {
    assert(!isInBasicBlock());
    assert(block == null);
    // Add [this] to the inputs' uses.
    for (int i = 0; i < inputs.length; i++) {
      assert(inputs[i].isInBasicBlock());
      inputs[i].usedBy.add(this);
    }
    block = targetBlock;
    assert(isValid());
  }

  void notifyRemovedFromBlock() {
    assert(isInBasicBlock());
    assert(usedBy.isEmpty);

    // Remove [this] from the inputs' uses.
    for (int i = 0; i < inputs.length; i++) {
      inputs[i].removeUser(this);
    }
    this.block = null;
    assert(isValid());
  }

  /// Do a in-place change of [from] to [to]. Warning: this function
  /// does not update [inputs] and [usedBy]. Use [changeUse] instead.
  void rewriteInput(HInstruction? from, HInstruction to) {
    for (int i = 0; i < inputs.length; i++) {
      if (identical(inputs[i], from)) inputs[i] = to;
    }
  }

  /// Removes all occurrences of [instruction] from [list].
  void removeFromList(List<HInstruction> list, HInstruction instruction) {
    int length = list.length;
    int i = 0;
    while (i < length) {
      if (instruction == list[i]) {
        list[i] = list[length - 1];
        length--;
      } else {
        i++;
      }
    }
    list.length = length;
  }

  /// Removes all occurrences of [user] from [usedBy].
  void removeUser(HInstruction user) {
    removeFromList(usedBy, user);
  }

  // Change all uses of [oldInput] by [this] to [newInput]. Also updates the
  // [usedBy] of [oldInput] and [newInput].
  void changeUse(HInstruction oldInput, HInstruction newInput) {
    assert(!identical(oldInput, newInput));
    for (int i = 0; i < inputs.length; i++) {
      if (identical(inputs[i], oldInput)) {
        inputs[i] = newInput;
        newInput.usedBy.add(this);
      }
    }
    removeFromList(oldInput.usedBy, this);
  }

  /// Replace a single input.
  ///
  /// Use [changeUse] to change all inputs that are the same value.
  void replaceInput(int index, HInstruction replacement) {
    assert(replacement.isInBasicBlock());
    inputs[index].usedBy.remove(this);
    inputs[index] = replacement;
    replacement.usedBy.add(this);
  }

  /// Remove a single input.
  void removeInput(int index) {
    inputs[index].usedBy.remove(this);
    inputs.removeAt(index);
  }

  void replaceAllUsersDominatedBy(
      HInstruction cursor, HInstruction newInstruction) {
    DominatedUses.of(this, cursor).replaceWith(newInstruction);
  }

  void moveBefore(HInstruction other) {
    assert(this is! HControlFlow);
    assert(this is! HPhi);
    assert(other is! HPhi);
    block!.detach(this);
    other.block!.internalAddBefore(other, this);
    block = other.block;
  }

  bool isConstantBoolean() => false;
  bool isConstantNull() => false;
  bool isConstantNumber() => false;
  bool isConstantInteger() => false;
  bool isConstantString() => false;
  bool isConstantFalse() => false;
  bool isConstantTrue() => false;

  bool isInterceptor(JClosedWorld closedWorld) => false;

  bool isValid() {
    HValidator validator = HValidator();
    validator.currentBlock = block;
    validator.visitInstruction(this);
    return validator.isValid;
  }

  bool isCodeMotionInvariant() => false;

  bool isJsStatement() => false;

  bool dominates(HInstruction other) {
    // An instruction does not dominates itself.
    if (this == other) return false;
    if (block != other.block) return block!.dominates(other.block!);

    for (var current = next; current != null; current = current.next) {
      if (current == other) return true;
    }
    return false;
  }

  /// Return whether the instructions do not belong to a loop or
  /// belong to the same loop.
  bool hasSameLoopHeaderAs(HInstruction other) {
    return block!.enclosingLoopHeader == other.block!.enclosingLoopHeader;
  }

  @override
  String toString() => '${this.runtimeType}()';
}

/// An interface implemented by certain kinds of [HInstruction]. This makes it
/// possible to discover which annotations were in force in the code from which
/// the instruction originated.
// TODO(sra): It would be easier to use a mostly-shared Map-like structure that
// surfaces the ambient annotations at any point in the code.
abstract class InstructionContext {
  MemberEntity? instructionContext;
}

/// The set of uses of [source] that are dominated by [dominator].
class DominatedUses {
  final HInstruction _source;

  // Two list of matching length holding (instruction, input-index) pairs for
  // the dominated uses.
  final List<HInstruction> _instructions = [];
  final List<int> _indexes = [];

  DominatedUses._(this._source);

  /// The uses of [source] that are dominated by [dominator].
  ///
  /// The uses by [dominator] are included in the result, unless
  /// [excludeDominator] is `true`, so `true` selects uses following
  /// [dominator].
  ///
  /// The uses include the in-edges of a HPhi node that corresponds to a
  /// dominated block. (There can be many such edges on a single phi at the exit
  /// of a loop with many break statements).  If [excludePhiOutEdges] is `true`
  /// then these edge uses are not included.
  static DominatedUses of(HInstruction source, HInstruction dominator,
      {bool excludeDominator = false, bool excludePhiOutEdges = false}) {
    return DominatedUses._(source)
      .._compute(source, dominator, excludeDominator, excludePhiOutEdges);
  }

  bool get isEmpty => _instructions.isEmpty;
  bool get isNotEmpty => !isEmpty;
  int get length => _instructions.length;

  /// Changes all the uses in the set to [replacement].
  void replaceWith(HInstruction replacement) {
    assert(replacement.isInBasicBlock());
    assert(!identical(replacement, _source));
    if (isEmpty) return;

    for (int i = 0; i < _instructions.length; i++) {
      HInstruction user = _instructions[i];
      int index = _indexes[i];
      assert(
          identical(user.inputs[index], _source),
          'Input ${index} of ${user} changed.'
          '\n  Found: ${user.inputs[index]}\n  Expected: ${_source}');
      user.inputs[index] = replacement;
      replacement.usedBy.add(user);
    }

    // The following loop is a more efficient implementation of:
    //
    //     for (final user in _instructions) {
    //       _source.usedBy.remove(user);
    //     }
    //
    // `List.remove` searches the list to find the key, and then scans the rest
    // of the list to move the elements up one position.  Repeating this is
    // quadratic.
    //
    // The code below combines searching for the next element with move-up
    // scanning for the previous element(s) to remove several elements in one
    // pass, provided elements of `_instructions` are in the same order as in
    // `usedBy`. This is usually the case since the DominatedUses set is
    // constructed from `_source.usedBy`.

    final usedBy = _source.usedBy;
    int instructionsIndex = 0;
    while (instructionsIndex < _instructions.length) {
      HInstruction nextToRemove = _instructions[instructionsIndex];
      int readIndex = 0, writeIndex = 0;
      while (readIndex < usedBy.length) {
        final user = usedBy[readIndex++];
        if (identical(user, nextToRemove)) {
          instructionsIndex++;
          if (instructionsIndex < _instructions.length) {
            nextToRemove = _instructions[instructionsIndex];
          } else {
            // Copy rest of the list elements up as-is.
            while (readIndex < usedBy.length) {
              usedBy[writeIndex++] = usedBy[readIndex++];
            }
            break;
          }
        } else {
          usedBy[writeIndex++] = user;
        }
      }
      assert(writeIndex < readIndex, 'Should remove at least one per pass');
      usedBy.length = writeIndex;
    }
  }

  bool get isSingleton => _instructions.length == 1;

  HInstruction get single => _instructions.single;

  Iterable<HInstruction> get instructions => _instructions;

  void _addUse(HInstruction user, int inputIndex) {
    _instructions.add(user);
    _indexes.add(inputIndex);
  }

  void _compute(HInstruction source, HInstruction dominator,
      bool excludeDominator, bool excludePhiOutEdges) {
    assert(dominator is! HPhi);

    // Keep track of all instructions that we have to deal with later and count
    // the number of them that are in the dominator's block.
    Set<HInstruction> users = Setlet();
    Set<HInstruction> seen = Setlet();
    int usersInDominatorBlock = 0;

    HBasicBlock dominatorBlock = dominator.block!;

    // Run through all the users and see if they are dominated, or potentially
    // dominated, or partially dominated by [dominator]. It is easier to
    // de-duplicate [usedBy] and process all inputs of an instruction than to
    // track the repeated elements of usedBy and match them up by index.
    for (HInstruction current in source.usedBy) {
      if (!seen.add(current)) continue;
      HBasicBlock currentBlock = current.block!;
      if (identical(currentBlock, dominatorBlock)) {
        // Ignore phi nodes of the dominator instruction block, they come before
        // the dominator instruction.
        if (current is! HPhi) {
          users.add(current);
          usersInDominatorBlock++;
        }
      } else if (dominatorBlock.dominates(currentBlock)) {
        users.add(current);
      } else if (!excludePhiOutEdges && current is HPhi) {
        // A non-dominated HPhi.
        // See if there a dominated edge into the phi. The input must be
        // [source] and the position must correspond to a dominated block.
        List<HBasicBlock> predecessors = currentBlock.predecessors;
        for (int i = 0; i < predecessors.length; i++) {
          if (current.inputs[i] != source) continue;
          HBasicBlock predecessor = predecessors[i];
          if (dominatorBlock.dominates(predecessor)) {
            _addUse(current, i);
          }
        }
      }
    }

    // Run through all the instructions before [dominator] and remove them from
    // the users set.
    if (usersInDominatorBlock > 0) {
      for (var current = dominatorBlock.first;
          !identical(current, dominator);
          current = current!.next) {
        if (users.remove(current)) {
          if (--usersInDominatorBlock == 0) break;
        }
      }
      if (excludeDominator) {
        users.remove(dominator);
      }
    }

    // Convert users into a list of (user, input-index) uses.
    for (HInstruction user in users) {
      var inputs = user.inputs;
      for (int i = 0; i < inputs.length; i++) {
        if (inputs[i] == source) {
          _addUse(user, i);
        }
      }
    }
  }
}

/// A reference to a [HInstruction] that can hold its own source information.
///
/// This used for attaching source information to reads of locals.
class HRef extends HInstruction {
  HRef(HInstruction value, SourceInformation sourceInformation)
      : super._1(value, value.instructionType) {
    this.sourceInformation = sourceInformation;
  }

  HInstruction get value => inputs[0];

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitRef(this);

  @override
  String toString() => 'HRef(${value})';
}

/// Marker interface for late instructions. Late instructions are used after the
/// main optimization phases. They capture codegen decisions just prior to
/// generating JavaScript.
abstract interface class HLateInstruction {}

/// Interface for instructions where the output is constrained to be one of the
/// inputs. Used for checks, where the SSA value of the check represents the
/// same value as the input, but restricted in some way, e.g., being of a
/// refined type or in a checked range.
abstract interface class HOutputConstrainedToAnInput implements HInstruction {
  /// The input which is the 'same' as the output.
  HInstruction get constrainedInput;
}

/// A [HCheck] instruction is an instruction that might do a dynamic check at
/// runtime on an input instruction. To have proper instruction dependencies in
/// the graph, instructions that depend on the check being done reference the
/// [HCheck] instruction instead of the input instruction.
abstract class HCheck extends HInstruction
    implements HOutputConstrainedToAnInput {
  HCheck(super.inputs, super.type) {
    setUseGvn();
  }
  HCheck._1(super.input, super.type) : super._1() {
    setUseGvn();
  }
  HCheck._2(super.input1, super.input2, super.type) : super._2() {
    setUseGvn();
  }

  HInstruction get checkedInput => inputs[0];

  @override
  HInstruction get constrainedInput => checkedInput;

  @override
  bool isJsStatement() => true;

  @override
  bool canThrow(AbstractValueDomain domain) => true;

  @override
  HInstruction nonCheck() => checkedInput.nonCheck();
}

enum StaticBoundsChecks {
  alwaysFalse,
  fullCheck,
  alwaysAboveZero,
  alwaysBelowLength,
  alwaysTrue,
}

class HBoundsCheck extends HCheck {
  /// Details which tests have been done statically during compilation.
  /// Default is that all checks must be performed dynamically.
  StaticBoundsChecks staticChecks = StaticBoundsChecks.fullCheck;

  HBoundsCheck(HInstruction index, HInstruction length, HInstruction array,
      AbstractValue type)
      : super([index, length, array], type);

  HInstruction get index => inputs[0];
  HInstruction get length => inputs[1];
  HInstruction get array => inputs[2];
  // There can be an additional fourth input which is the index to report to
  // [ioore]. This is used by the expansion of [JSArray.removeLast].
  HInstruction get reportedIndex => inputs.length > 3 ? inputs[3] : index;
  @override
  bool isControlFlow() => true;

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitBoundsCheck(this);
  @override
  _GvnType get _gvnType => _GvnType.boundsCheck;
  @override
  bool typeEquals(other) => other is HBoundsCheck;
  @override
  bool dataEquals(HInstruction other) => true;
}

abstract class HConditionalBranch extends HControlFlow {
  HConditionalBranch(HInstruction condition) {
    inputs.add(condition);
  }
  HInstruction get condition => inputs[0];
  HBasicBlock get trueBranch => block!.successors[0];
  HBasicBlock get falseBranch => block!.successors[1];
}

abstract class HControlFlow extends HInstruction {
  HControlFlow() : super._noType();
  @override
  bool isControlFlow() => true;
  @override
  bool isJsStatement() => true;

  /// HControlFlow instructions don't have an abstract value.
  @override
  AbstractValue get instructionType =>
      throw UnsupportedError('HControlFlow.instructionType');
}

// Allocates and initializes an instance.
class HCreate extends HInstruction {
  final ClassEntity element;

  /// Does this instruction have reified type information as the last input?
  final bool hasRtiInput;

  /// If this field is not `null`, this call is from an inlined constructor and
  /// we have to register the instantiated type in the code generator. The
  /// [instructionType] of this node is not enough, because we also need the
  /// type arguments. See also [SsaFromAstMixin.currentInlinedInstantiations].
  List<InterfaceType>? instantiatedTypes;

  /// If this node creates a closure class, [callMethod] is the call method of
  /// the closure class.
  FunctionEntity? callMethod;

  HCreate(this.element, super.inputs, super.type,
      SourceInformation? sourceInformation,
      {this.instantiatedTypes, this.hasRtiInput = false, this.callMethod}) {
    this.sourceInformation = sourceInformation;
  }

  @override
  bool isAllocation(AbstractValueDomain domain) => true;

  HInstruction get rtiInput {
    assert(hasRtiInput);
    return inputs.last;
  }

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitCreate(this);

  @override
  String toString() => 'HCreate($element, ${instantiatedTypes})';
}

// Allocates a box to hold mutated captured variables.
class HCreateBox extends HInstruction {
  HCreateBox(super.type) : super._0();

  @override
  bool isAllocation(AbstractValueDomain domain) => true;

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitCreateBox(this);

  @override
  String toString() => 'HCreateBox()';
}

abstract class HInvoke extends HInstruction {
  bool _isAllocation = false;

  /// [isInterceptedCall] is true if this invocation uses the interceptor
  /// calling convention where the first input is the methods and the second
  /// input is the Dart receiver.
  bool isInterceptedCall = false;

  HInvoke(super.inputs, super.type) : super() {
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
  }
  static const int ARGUMENTS_OFFSET = 1;

  @override
  bool canThrow(AbstractValueDomain domain) => true;

  @override
  bool isAllocation(AbstractValueDomain domain) => _isAllocation;

  void setAllocation(bool value) {
    _isAllocation = value;
  }
}

abstract class HInvokeDynamic extends HInvoke implements InstructionContext {
  final InvokeDynamicSpecializer specializer;

  Selector _selector;
  AbstractValue _receiverType;
  final AbstractValue _originalReceiverType;

  /// Static type at call-site, often better than union-over-targets.
  AbstractValue? staticType;

  /// `true` if the type parameters at the call known to be invariant with
  /// respect to the type parameters of the receiver instance. This corresponds
  /// to the [ir.MethodInvocation.isInvariant] property and may be updated with
  /// additional analysis.
  bool isInvariant = false;

  /// `true` for an indexed getter or setter if the index is known to be in
  /// range. This corresponds to the [ir.MethodInvocation.isBoundsSafe] property
  /// but and may updated with additional analysis.
  bool isBoundsSafe = false;

  // Cached target when non-nullable receiver type and selector determine a
  // single target. This is in effect a direct call (except for a possible
  // `null` receiver). The element should only be set if the inputs are correct
  // for a direct call. These constraints exclude caching a target when the call
  // needs defaulted arguments, is `noSuchMethod` (legacy), or is a call-through
  // stub.
  MemberEntity? element;

  @override
  MemberEntity? instructionContext;

  HInvokeDynamic(Selector selector, this._receiverType, this.element,
      List<HInstruction> inputs, bool isIntercepted, AbstractValue resultType)
      : this._selector = selector,
        this._originalReceiverType = _receiverType,
        specializer = isIntercepted
            ? InvokeDynamicSpecializer.lookupSpecializer(selector)
            : const InvokeDynamicSpecializer(),
        super(inputs, resultType) {
    isInterceptedCall = isIntercepted;
  }

  Selector get selector => _selector;

  set selector(Selector selector) {
    _selector = selector;
    element = null; // Cached element would no longer match new selector.
  }

  AbstractValue get receiverType => _receiverType;

  void updateReceiverType(
      AbstractValueDomain abstractValueDomain, AbstractValue value) {
    _receiverType =
        abstractValueDomain.intersection(_originalReceiverType, value);
  }

  @override
  String toString() => 'invoke dynamic: selector=$selector, mask=$receiverType';

  HInstruction get receiver => inputs[0];

  @override
  HInstruction getDartReceiver(JClosedWorld closedWorld) {
    return isCallOnInterceptor(closedWorld) ? inputs[1] : inputs[0];
  }

  /// The type arguments passed in this dynamic invocation.
  List<DartType> get typeArguments;

  /// Returns whether this call is on an interceptor object.
  bool isCallOnInterceptor(JClosedWorld closedWorld) {
    return isInterceptedCall && receiver.isInterceptor(closedWorld);
  }

  @override
  _GvnType get _gvnType => _GvnType.invokeDynamic;

  @override
  bool typeEquals(other) => other is HInvokeDynamic;

  @override
  bool dataEquals(HInvokeDynamic other) {
    // Use the name and the kind instead of [Selector.operator==]
    // because we don't need to check the arity (already checked in
    // [gvnEquals]), and the receiver types may not be in sync.
    // TODO(sra): If we GVN calls with named (optional) arguments then the
    // selector needs a deeper check for the same subset of named arguments.
    return selector.name == other.selector.name &&
        selector.kind == other.selector.kind;
  }
}

class HInvokeClosure extends HInvokeDynamic {
  @override
  final List<DartType> typeArguments;

  HInvokeClosure(Selector selector, AbstractValue receiverType,
      List<HInstruction> inputs, AbstractValue resultType, this.typeArguments)
      : super(selector, receiverType, null, inputs, false, resultType) {
    assert(selector.isMaybeClosureCall);
    assert(selector.callStructure.typeArgumentCount == typeArguments.length);
    assert(!isInterceptedCall);
  }
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitInvokeClosure(this);
}

class HInvokeDynamicMethod extends HInvokeDynamic {
  @override
  final List<DartType> typeArguments;

  HInvokeDynamicMethod(
      Selector selector,
      AbstractValue receiverType,
      List<HInstruction> inputs,
      AbstractValue resultType,
      this.typeArguments,
      SourceInformation? sourceInformation,
      {bool isIntercepted = false})
      : super(selector, receiverType, null, inputs, isIntercepted, resultType) {
    this.sourceInformation = sourceInformation;
    assert(selector.callStructure.typeArgumentCount == typeArguments.length);
  }

  @override
  String toString() =>
      'invoke dynamic method: selector=$selector, mask=$receiverType';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitInvokeDynamicMethod(this);
}

abstract class HInvokeDynamicField extends HInvokeDynamic {
  HInvokeDynamicField(
      Selector selector,
      AbstractValue receiverType,
      MemberEntity? element,
      List<HInstruction> inputs,
      bool isIntercepted,
      AbstractValue resultType)
      : super(
            selector, receiverType, element, inputs, isIntercepted, resultType);

  @override
  String toString() =>
      'invoke dynamic field: selector=$selector, mask=$receiverType';
}

class HInvokeDynamicGetter extends HInvokeDynamicField {
  HInvokeDynamicGetter(
      Selector selector,
      AbstractValue receiverType,
      MemberEntity? element,
      List<HInstruction> inputs,
      bool isIntercepted,
      AbstractValue resultType,
      SourceInformation? sourceInformation)
      : super(selector, receiverType, element, inputs, isIntercepted,
            resultType) {
    this.sourceInformation = sourceInformation;
  }

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitInvokeDynamicGetter(this);

  bool get isTearOff => element != null && element!.isFunction;

  @override
  List<DartType> get typeArguments => const [];

  // There might be an interceptor input, so `inputs.last` is the dart receiver.
  @override
  bool canThrow(AbstractValueDomain domain) => isTearOff
      ? inputs.last.isNull(domain).isPotentiallyTrue
      : super.canThrow(domain);

  @override
  String toString() =>
      'invoke dynamic getter: selector=$selector, mask=$receiverType';
}

class HInvokeDynamicSetter extends HInvokeDynamicField {
  /// If `true` a call to the setter is needed for checking the type even
  /// though the target field is known.
  bool needsCheck = false;

  HInvokeDynamicSetter(
      Selector selector,
      AbstractValue receiverType,
      MemberEntity? element,
      List<HInstruction> inputs,
      bool isIntercepted,
      // TODO(johnniwinther): The result type for a setter should be the empty
      // type.
      AbstractValue resultType,
      SourceInformation? sourceInformation)
      : super(selector, receiverType, element, inputs, isIntercepted,
            resultType) {
    this.sourceInformation = sourceInformation;
  }

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitInvokeDynamicSetter(this);

  @override
  List<DartType> get typeArguments => const [];

  @override
  String toString() =>
      'invoke dynamic setter: selector=$selector, mask=$receiverType, element=$element';
}

class HInvokeStatic extends HInvoke {
  final MemberEntity element;

  /// The type arguments passed in this static invocation.
  final List<DartType> typeArguments;

  bool targetCanThrow;

  @override
  bool canThrow(AbstractValueDomain domain) => targetCanThrow;

  /// If this instruction is a call to a constructor, [instantiatedTypes]
  /// contains the type(s) used in the (Dart) `New` expression(s). The
  /// [instructionType] of this node is not enough, because we also need the
  /// type arguments. See also [SsaFromAstMixin.currentInlinedInstantiations].
  List<InterfaceType>? instantiatedTypes;

  /// The first input must be the target.
  HInvokeStatic(this.element, List<HInstruction> inputs, AbstractValue type,
      this.typeArguments,
      {this.targetCanThrow = true, bool isIntercepted = false})
      : super(inputs, type) {
    isInterceptedCall = isIntercepted;
  }

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitInvokeStatic(this);

  @override
  _GvnType get _gvnType => _GvnType.invokeStatic;

  @override
  String toString() => 'invoke static: $element';
}

class HInvokeSuper extends HInvokeStatic {
  /// The class where the call to super is being done.
  final ClassEntity caller;
  final bool isSetter;
  final Selector selector;

  HInvokeSuper(
      MemberEntity element,
      this.caller,
      this.selector,
      List<HInstruction> inputs,
      bool isIntercepted,
      AbstractValue type,
      List<DartType> typeArguments,
      SourceInformation? sourceInformation,
      {required this.isSetter})
      : super(element, inputs, type, typeArguments,
            isIntercepted: isIntercepted) {
    this.sourceInformation = sourceInformation;
  }

  HInstruction get receiver => inputs[0];
  @override
  HInstruction getDartReceiver(JClosedWorld closedWorld) {
    return isCallOnInterceptor(closedWorld) ? inputs[1] : inputs[0];
  }

  /// Returns whether this call is on an interceptor object.
  bool isCallOnInterceptor(JClosedWorld closedWorld) {
    return isInterceptedCall && receiver.isInterceptor(closedWorld);
  }

  @override
  String toString() => 'invoke super: $element';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitInvokeSuper(this);

  HInstruction get value {
    assert(isSetter);
    // The 'inputs' are [receiver, value] or [interceptor, receiver, value].
    return inputs.last;
  }
}

class HInvokeConstructorBody extends HInvokeStatic {
  // The 'inputs' are
  //     [receiver, arg1, ..., argN] or
  //     [interceptor, receiver, arg1, ... argN].
  HInvokeConstructorBody(
      ConstructorBodyEntity element,
      List<HInstruction> inputs,
      AbstractValue type,
      SourceInformation? sourceInformation)
      : super(element, inputs, type, const []) {
    this.sourceInformation = sourceInformation;
  }

  @override
  String toString() => 'invoke constructor body: ${element.name}';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitInvokeConstructorBody(this);
}

class HInvokeGeneratorBody extends HInvokeStatic {
  // Directly call the JGeneratorBody method. The generator body can be a static
  // method or a member. The target is directly called.
  // The 'inputs' are
  //     [arg1, ..., argN] or
  //     [receiver, arg1, ..., argN] or
  //     [interceptor, receiver, arg1, ... argN].
  // The 'inputs' may or may not have an additional type argument used for
  // creating the generator (T for new Completer<T>() inside the body).
  HInvokeGeneratorBody(FunctionEntity element, List<HInstruction> inputs,
      AbstractValue type, SourceInformation? sourceInformation)
      : super(element, inputs, type, const []) {
    this.sourceInformation = sourceInformation;
  }

  @override
  String toString() => 'HInvokeGeneratorBody(${element.name})';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitInvokeGeneratorBody(this);
}

abstract class HFieldAccess extends HInstruction {
  final FieldEntity element;

  HFieldAccess(this.element, List<HInstruction> inputs, AbstractValue type)
      : super(inputs, type);

  HInstruction get receiver => inputs[0];
}

class HFieldGet extends HFieldAccess {
  final bool isAssignable;

  HFieldGet(FieldEntity element, HInstruction receiver, AbstractValue type,
      SourceInformation? sourceInformation,
      {required this.isAssignable})
      : super(element, [receiver], type) {
    this.sourceInformation = sourceInformation;
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    setUseGvn();
    if (this.isAssignable) {
      sideEffects.setDependsOnInstancePropertyStore();
    }
  }

  @override
  bool isInterceptor(JClosedWorld closedWorld) {
    final entity = sourceElement;
    // In case of a closure inside an interceptor class, JavaScript `this`, the
    // interceptor, is stored in the generated closure class, and accessed
    // through a [HFieldGet].
    // TODO(sra): It would be better to track this as an explicit property
    // rather than recover it from `sourceElement`.
    if (entity is ThisLocal) {
      return closedWorld.interceptorData
          .isInterceptedClass(entity.enclosingClass);
    }
    return false;
  }

  @override
  bool canThrow(AbstractValueDomain domain) =>
      receiver.isNull(domain).isPotentiallyTrue;

  @override
  HInstruction getDartReceiver(JClosedWorld closedWorld) => receiver;
  @override
  bool onlyThrowsNSM() => true;

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitFieldGet(this);

  @override
  _GvnType get _gvnType => _GvnType.fieldGet;
  @override
  bool typeEquals(other) => other is HFieldGet;
  @override
  bool dataEquals(HFieldGet other) => element == other.element;
  @override
  String toString() => "FieldGet(element=$element,type=$instructionType)";
}

class HFieldSet extends HFieldAccess {
  HFieldSet(FieldEntity element, HInstruction receiver, HInstruction value)
      : super(element, [receiver, value], value.instructionType) {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    sideEffects.setChangesInstanceProperty();
  }

  @override
  bool canThrow(AbstractValueDomain domain) =>
      receiver.isNull(domain).isPotentiallyTrue;

  @override
  HInstruction getDartReceiver(JClosedWorld closedWorld) => receiver;
  @override
  bool onlyThrowsNSM() => true;

  HInstruction get value => inputs[1];
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitFieldSet(this);

  // HFieldSet is an expression if it has a user.
  @override
  bool isJsStatement() => usedBy.isEmpty;

  @override
  String toString() => "FieldSet(element=$element,type=$instructionType)";
}

// Raw reference to a function.
class HFunctionReference extends HInstruction {
  FunctionEntity element;
  HFunctionReference(this.element, super.type) : super._0() {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    setUseGvn();
  }

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitFunctionReference(this);

  @override
  _GvnType get _gvnType => _GvnType.functionReference;
  @override
  bool typeEquals(other) => other is HFunctionReference;
  @override
  bool dataEquals(HFunctionReference other) => element == other.element;
  @override
  String toString() => "FunctionReference($element)";
}

class HGetLength extends HInstruction {
  final bool isAssignable;
  HGetLength(super.receiver, super.type, {required this.isAssignable})
      : super._1() {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    setUseGvn();
    if (this.isAssignable) {
      sideEffects.setDependsOnInstancePropertyStore();
    }
  }

  HInstruction get receiver => inputs.single;

  @override
  bool canThrow(AbstractValueDomain domain) =>
      receiver.isNull(domain).isPotentiallyTrue;

  @override
  HInstruction getDartReceiver(JClosedWorld closedWorld) => receiver;
  @override
  bool onlyThrowsNSM() => true;

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitGetLength(this);

  @override
  _GvnType get _gvnType => _GvnType.getLength;
  @override
  bool typeEquals(other) => other is HGetLength;
  @override
  bool dataEquals(HGetLength other) => true;
  @override
  String toString() => "GetLength()";
}

enum ReadModifyWriteKind {
  assign,
  prefix,
  postfix,
}

/// HReadModifyWrite is a late stage instruction for a field (property) update
/// via an assignment operation or pre- or post-increment.
class HReadModifyWrite extends HInstruction implements HLateInstruction {
  final FieldEntity element;
  final String jsOp;
  final ReadModifyWriteKind opKind;

  HReadModifyWrite._(
      this.element, this.jsOp, this.opKind, super.inputs, super.type) {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    sideEffects.setChangesInstanceProperty();
    sideEffects.setDependsOnInstancePropertyStore();
  }

  HReadModifyWrite.assignOp(FieldEntity element, String jsOp,
      HInstruction receiver, HInstruction operand, AbstractValue type)
      : this._(element, jsOp, ReadModifyWriteKind.assign, [receiver, operand],
            type);

  HReadModifyWrite.preOp(FieldEntity element, String jsOp,
      HInstruction receiver, AbstractValue type)
      : this._(element, jsOp, ReadModifyWriteKind.prefix, [receiver], type);

  HReadModifyWrite.postOp(FieldEntity element, String jsOp,
      HInstruction receiver, AbstractValue type)
      : this._(element, jsOp, ReadModifyWriteKind.postfix, [receiver], type);

  HInstruction get receiver => inputs[0];

  bool get isPreOp => opKind == ReadModifyWriteKind.prefix;
  bool get isPostOp => opKind == ReadModifyWriteKind.postfix;
  bool get isAssignOp => opKind == ReadModifyWriteKind.assign;

  @override
  bool canThrow(AbstractValueDomain domain) =>
      receiver.isNull(domain).isPotentiallyTrue;

  @override
  HInstruction getDartReceiver(JClosedWorld closedWorld) => receiver;
  @override
  bool onlyThrowsNSM() => true;

  HInstruction get value => inputs[1];
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitReadModifyWrite(this);

  @override
  bool isJsStatement() => isAssignOp;
  @override
  String toString() => "ReadModifyWrite $jsOp $opKind $element";
}

abstract class HLocalAccess extends HInstruction {
  final Local variable;

  HLocalAccess(this.variable, List<HInstruction> inputs, AbstractValue type)
      : super(inputs, type);

  HInstruction get receiver => inputs[0];
}

class HLocalGet extends HLocalAccess {
  // No need to use GVN for a [HLocalGet], it is just a local
  // access.
  HLocalGet(Local variable, HLocalValue local, AbstractValue type,
      SourceInformation? sourceInformation)
      : super(variable, [local], type) {
    this.sourceInformation = sourceInformation;
  }

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitLocalGet(this);

  HLocalValue get local => inputs[0] as HLocalValue;

  @override
  String toString() => 'HLocalGet($local).$hashCode';
}

class HLocalSet extends HLocalAccess {
  HLocalSet(
      Local variable, HLocalValue local, HInstruction value, AbstractValue type)
      : super(variable, [local, value], type);

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitLocalSet(this);

  HLocalValue get local => inputs[0] as HLocalValue;
  HInstruction get value => inputs[1];
  @override
  bool isJsStatement() => true;
}

/// Invocation of a native or JS-interop method.
///
/// Includes various invocations where the JavaScript form is similar to the
/// Dart form:
///
///     receiver.property          // An instance getter
///     receiver.property = value  // An instance setter
///     receiver.method(arg)       // An instance method
///
///     Class.property             // A static getter
///     Class.property = value     // A static setter
///     Class.method(arg)          // A static method
///     new Class(arg)             // A constructor
///
/// HInvokeDynamicMethod can be lowered to HInvokeExternal with the same
/// [element]. The difference is a HInvokeDynamicMethod is a call to a
/// Dart-calling-convention stub identified by [element] that contains a call to
/// the external method, whereas a HInvokeExternal instruction is a direct
/// JavaScript call to the external method identified by [element].
class HInvokeExternal extends HInvoke {
  final FunctionEntity element;

  // The following fields are functions of [element] that are extracted for
  // convenience.
  final NativeBehavior? nativeBehavior;
  final NativeThrowBehavior throwBehavior;

  HInvokeExternal(this.element, List<HInstruction> inputs, AbstractValue type,
      this.nativeBehavior,
      {SourceInformation? sourceInformation})
      : throwBehavior =
            nativeBehavior?.throwBehavior ?? NativeThrowBehavior.may,
        super(inputs, type) {
    if (nativeBehavior == null) {
      sideEffects.setAllSideEffects();
      sideEffects.setDependsOnSomething();
    } else {
      sideEffects.add(nativeBehavior!.sideEffects);
    }
    if (nativeBehavior != null && nativeBehavior!.useGvn) {
      setUseGvn();
    }
    this.sourceInformation = sourceInformation;
  }

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitInvokeExternal(this);

  @override
  bool isJsStatement() => false;

  @override
  bool canThrow(AbstractValueDomain domain) {
    if (element.isInstanceMember) {
      if (inputs.length > 0) {
        return inputs.first.isNull(domain).isPotentiallyTrue
            ? throwBehavior.canThrow
            : throwBehavior.onNonNull.canThrow;
      }
    }
    return throwBehavior.canThrow;
  }

  @override
  bool onlyThrowsNSM() => throwBehavior.isOnlyNullNSMGuard;

  @override
  bool isAllocation(AbstractValueDomain domain) =>
      nativeBehavior != null &&
      nativeBehavior!.isAllocation &&
      this.isNull(domain).isDefinitelyFalse;

  /// Returns `true` if the call will throw an NoSuchMethod error if [receiver]
  /// is `null` before having any other side-effects.
  bool isNullGuardFor(HInstruction receiver) {
    if (!element.isInstanceMember) return false;
    if (inputs.length < 1) return false;
    if (inputs.first.nonCheck() != receiver.nonCheck()) return false;
    return true;
  }

  @override
  _GvnType get _gvnType => _GvnType.invokeExternal;
  @override
  bool typeEquals(other) => other is HInvokeExternal;
  @override
  bool dataEquals(HInvokeExternal other) {
    return element == other.element;
  }

  @override
  String toString() => 'HInvokeExternal($element)';
}

abstract class HForeign extends HInstruction {
  HForeign(AbstractValue type, List<HInstruction> inputs) : super(inputs, type);

  bool get isStatement => false;
  NativeBehavior? get nativeBehavior => null;

  @override
  bool canThrow(AbstractValueDomain domain) {
    return sideEffects.hasSideEffects() || sideEffects.dependsOnSomething();
  }
}

class HForeignCode extends HForeign {
  final js.Template codeTemplate;
  @override
  final bool isStatement;
  @override
  final NativeBehavior? nativeBehavior;
  late final NativeThrowBehavior throwBehavior;

  HForeignCode(this.codeTemplate, AbstractValue type, List<HInstruction> inputs,
      {this.isStatement = false,
      SideEffects? effects,
      NativeBehavior? nativeBehavior,
      NativeThrowBehavior? throwBehavior})
      : this.nativeBehavior = nativeBehavior,
        //this.throwBehavior = throwBehavior,
        super(type, inputs) {
    if (effects == null && nativeBehavior != null) {
      effects = nativeBehavior.sideEffects;
    }
    throwBehavior ??= (nativeBehavior == null)
        ? NativeThrowBehavior.may
        : nativeBehavior.throwBehavior;
    this.throwBehavior = throwBehavior;

    if (effects != null) sideEffects.add(effects);
    if (nativeBehavior != null && nativeBehavior.useGvn) {
      setUseGvn();
    }
  }

  HForeignCode.statement(js.Template codeTemplate, List<HInstruction> inputs,
      SideEffects effects, NativeBehavior nativeBehavior, AbstractValue type)
      : this(codeTemplate, type, inputs,
            isStatement: true,
            effects: effects,
            nativeBehavior: nativeBehavior);

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitForeignCode(this);

  @override
  bool isJsStatement() => isStatement;
  @override
  bool canThrow(AbstractValueDomain domain) {
    if (inputs.length > 0) {
      return inputs.first.isNull(domain).isPotentiallyTrue
          ? throwBehavior.canThrow
          : throwBehavior.onNonNull.canThrow;
    }
    return throwBehavior.canThrow;
  }

  @override
  bool onlyThrowsNSM() => throwBehavior.isOnlyNullNSMGuard;

  @override
  bool isAllocation(AbstractValueDomain domain) =>
      nativeBehavior != null &&
      nativeBehavior!.isAllocation &&
      isNull(domain).isDefinitelyFalse;

  /// Returns `true` if the template will throw an NoSuchMethod error if
  /// [receiver] is `null` before having any other side-effects.
  bool isNullGuardFor(HInstruction? receiver) {
    if (!throwBehavior.isNullNSMGuard) return false;
    if (inputs.length < 1) return false;
    if (inputs.first.nonCheck() != receiver!.nonCheck()) return false;
    return true;
  }

  @override
  _GvnType get _gvnType => _GvnType.foreignCode;
  @override
  bool typeEquals(other) => other is HForeignCode;
  @override
  bool dataEquals(HForeignCode other) {
    return codeTemplate.source != null &&
        codeTemplate.source == other.codeTemplate.source;
  }

  @override
  String toString() => 'HForeignCode("${codeTemplate.source}")';
}

abstract class HInvokeBinary extends HInstruction {
  HInvokeBinary(super.left, super.right, super.type) : super._2() {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    setUseGvn();
  }

  HInstruction get left => inputs[0];
  HInstruction get right => inputs[1];

  constant_system.BinaryOperation operation();
}

abstract class HBinaryArithmetic extends HInvokeBinary {
  HBinaryArithmetic(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  constant_system.BinaryOperation operation();
}

class HAdd extends HBinaryArithmetic {
  HAdd(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitAdd(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.add;
  @override
  _GvnType get _gvnType => _GvnType.add;
  @override
  bool typeEquals(other) => other is HAdd;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HDivide extends HBinaryArithmetic {
  HDivide(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitDivide(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.divide;
  @override
  _GvnType get _gvnType => _GvnType.divide;
  @override
  bool typeEquals(other) => other is HDivide;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HMultiply extends HBinaryArithmetic {
  HMultiply(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitMultiply(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.multiply;
  @override
  _GvnType get _gvnType => _GvnType.multiply;
  @override
  bool typeEquals(other) => other is HMultiply;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HSubtract extends HBinaryArithmetic {
  HSubtract(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitSubtract(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.subtract;
  @override
  _GvnType get _gvnType => _GvnType.subtract;
  @override
  bool typeEquals(other) => other is HSubtract;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HTruncatingDivide extends HBinaryArithmetic {
  HTruncatingDivide(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitTruncatingDivide(this);

  @override
  constant_system.BinaryOperation operation() =>
      constant_system.truncatingDivide;
  @override
  _GvnType get _gvnType => _GvnType.truncatingDivide;
  @override
  bool typeEquals(other) => other is HTruncatingDivide;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HRemainder extends HBinaryArithmetic {
  HRemainder(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitRemainder(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.remainder;
  @override
  _GvnType get _gvnType => _GvnType.remainder;
  @override
  bool typeEquals(other) => other is HRemainder;
  @override
  bool dataEquals(HInstruction other) => true;
}

/// An [HSwitch] instruction has one input for the incoming
/// value, and one input per constant that it can switch on.
/// Its block has one successor per constant, and one for the default.
class HSwitch extends HControlFlow {
  HSwitch(HInstruction input) {
    inputs.add(input);
  }

  HConstant constant(int index) => inputs[index + 1] as HConstant;
  HInstruction get expression => inputs[0];

  /// Provides the target to jump to if none of the constants match
  /// the expression. If the switch had no default case, this is the
  /// following join-block.
  HBasicBlock get defaultTarget => block!.successors.last;

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitSwitch(this);

  @override
  String toString() => "HSwitch cases = $inputs";
}

abstract class HBinaryBitOp extends HInvokeBinary {
  /// JavaScript bitwise operations like `&` produce a 32-bit signed results but
  /// the Dart-web operations produce an unsigned result. Conversion to unsigned
  /// might be unnecessary (e.g. the inputs are such that JavaScript operation
  /// cannot produce a negative value). During instruction selection we
  /// determine if conversion is unnecessary.
  bool requiresUintConversion = true;

  HBinaryBitOp(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
}

class HShiftLeft extends HBinaryBitOp {
  HShiftLeft(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitShiftLeft(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.shiftLeft;
  @override
  _GvnType get _gvnType => _GvnType.shiftLeft;
  @override
  bool typeEquals(other) => other is HShiftLeft;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HShiftRight extends HBinaryBitOp {
  HShiftRight(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitShiftRight(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.shiftRight;
  @override
  _GvnType get _gvnType => _GvnType.shiftRight;
  @override
  bool typeEquals(other) => other is HShiftRight;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HBitOr extends HBinaryBitOp {
  HBitOr(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitBitOr(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.bitOr;
  @override
  _GvnType get _gvnType => _GvnType.bitOr;
  @override
  bool typeEquals(other) => other is HBitOr;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HBitAnd extends HBinaryBitOp {
  HBitAnd(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitBitAnd(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.bitAnd;
  @override
  _GvnType get _gvnType => _GvnType.bitAnd;
  @override
  bool typeEquals(other) => other is HBitAnd;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HBitXor extends HBinaryBitOp {
  HBitXor(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitBitXor(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.bitXor;
  @override
  _GvnType get _gvnType => _GvnType.bitXor;
  @override
  bool typeEquals(other) => other is HBitXor;
  @override
  bool dataEquals(HInstruction other) => true;
}

abstract class HInvokeUnary extends HInstruction {
  HInvokeUnary(super.input, super.type) : super._1() {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    setUseGvn();
  }

  HInstruction get operand => inputs[0];

  constant_system.UnaryOperation operation();
}

class HNegate extends HInvokeUnary {
  HNegate(HInstruction input, AbstractValue type) : super(input, type);
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitNegate(this);

  @override
  constant_system.UnaryOperation operation() => constant_system.negate;
  @override
  _GvnType get _gvnType => _GvnType.negate;
  @override
  bool typeEquals(other) => other is HNegate;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HAbs extends HInvokeUnary {
  HAbs(HInstruction input, AbstractValue type) : super(input, type);
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitAbs(this);

  @override
  constant_system.UnaryOperation operation() => constant_system.abs;
  @override
  _GvnType get _gvnType => _GvnType.abs;
  @override
  bool typeEquals(other) => other is HAbs;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HBitNot extends HInvokeUnary {
  /// JavaScript `~` produces a 32-bit signed result the Dart-web operation
  /// produces an unsigned result. Conversion to unsigned might be unnecessary
  /// (e.g. the value is immediately masked). During instruction selection we
  /// determine if conversion is unnecessary.
  bool requiresUintConversion = true;

  HBitNot(HInstruction input, AbstractValue type) : super(input, type);
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitBitNot(this);

  @override
  constant_system.UnaryOperation operation() => constant_system.bitNot;
  @override
  _GvnType get _gvnType => _GvnType.bitNot;
  @override
  bool typeEquals(other) => other is HBitNot;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HExit extends HControlFlow {
  @override
  String toString() => 'exit';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitExit(this);
}

class HGoto extends HControlFlow {
  @override
  String toString() => 'goto';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitGoto(this);
}

abstract class HJump extends HControlFlow {
  final JumpTarget target;
  final LabelDefinition? label;
  HJump(this.target, SourceInformation? sourceInformation) : label = null {
    this.sourceInformation = sourceInformation;
  }
  HJump.toLabel(LabelDefinition label, SourceInformation? sourceInformation)
      : label = label,
        target = label.target {
    this.sourceInformation = sourceInformation;
  }
}

class HBreak extends HJump {
  /// Signals that this is a special break instruction for the synthetic loop
  /// generated for a switch statement with continue statements. See
  /// [SsaFromAstMixin.buildComplexSwitchStatement] for detail.
  final bool breakSwitchContinueLoop;

  HBreak(JumpTarget target, SourceInformation? sourceInformation,
      {this.breakSwitchContinueLoop = false})
      : super(target, sourceInformation);

  HBreak.toLabel(LabelDefinition label, SourceInformation? sourceInformation)
      : breakSwitchContinueLoop = false,
        super.toLabel(label, sourceInformation);

  @override
  String toString() => (label != null) ? 'break ${label!.labelName}' : 'break';

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitBreak(this);
}

class HContinue extends HJump {
  HContinue(JumpTarget target, SourceInformation? sourceInformation)
      : super(target, sourceInformation);

  HContinue.toLabel(LabelDefinition label, SourceInformation? sourceInformation)
      : super.toLabel(label, sourceInformation);

  @override
  String toString() =>
      (label != null) ? 'continue ${label!.labelName}' : 'continue';

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitContinue(this);
}

class HTry extends HControlFlow {
  HLocalValue? exception;
  HBasicBlock? catchBlock;
  HBasicBlock? finallyBlock;
  @override
  String toString() => 'try';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitTry(this);
  HBasicBlock get joinBlock => this.block!.successors.last;
}

// An [HExitTry] control flow node is used when the body of a try or
// the body of a catch contains a return, break or continue. To build
// the control flow graph, we explicitly mark the body that
// leads to one of this instruction a predecessor of catch and
// finally.
class HExitTry extends HControlFlow {
  @override
  String toString() => 'exit try';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitExitTry(this);
  HBasicBlock get bodyTrySuccessor => block!.successors[0];
}

class HIf extends HConditionalBranch {
  HBlockFlow? blockInformation = null;
  HIf(super.condition);
  @override
  String toString() => 'if';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitIf(this);

  HBasicBlock get thenBlock {
    assert(identical(block!.dominatedBlocks[0], block!.successors[0]));
    return block!.successors[0];
  }

  HBasicBlock get elseBlock {
    assert(identical(block!.dominatedBlocks[1], block!.successors[1]));
    return block!.successors[1];
  }

  HBasicBlock? get joinBlock => blockInformation!.continuation;
}

class HLoopBranch extends HConditionalBranch {
  HLoopBranch(super.condition);
  @override
  String toString() => 'loop-branch';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitLoopBranch(this);
}

class HConstant extends HInstruction {
  final ConstantValue constant;
  HConstant._internal(this.constant, super.constantType) : super._0();

  @override
  String toString() => 'literal: ${constant.toStructuredText(null)}';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitConstant(this);

  @override
  bool isConstantBoolean() => constant is BoolConstantValue;
  @override
  bool isConstantNull() => constant is NullConstantValue;
  @override
  bool isConstantNumber() => constant is NumConstantValue;
  @override
  bool isConstantInteger() => constant is IntConstantValue;
  @override
  bool isConstantString() => constant is StringConstantValue;
  @override
  bool isConstantFalse() => constant is FalseConstantValue;
  @override
  bool isConstantTrue() => constant is TrueConstantValue;

  @override
  bool isInterceptor(JClosedWorld closedWorld) =>
      constant is InterceptorConstantValue;

  // Maybe avoid this if the literal is big?
  @override
  bool isCodeMotionInvariant() => true;

  @override
  set instructionType(AbstractValue type) {
    // Only lists can be specialized. The SSA builder uses the
    // inferrer for finding the type of a constant list. We should
    // have the constant know its type instead.
    if (constant is! ListConstantValue) return;
    super.instructionType = type;
  }
}

class HNot extends HInstruction {
  HNot(super.value, super.type) : super._1() {
    setUseGvn();
  }

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitNot(this);
  @override
  _GvnType get _gvnType => _GvnType.not;
  @override
  bool typeEquals(other) => other is HNot;
  @override
  bool dataEquals(HInstruction other) => true;
}

/// An [HLocalValue] represents a local. Unlike [HParameterValue]s its
/// first use must be in an HLocalSet. That is, [HParameterValue]s have a
/// value from the start, whereas [HLocalValue]s need to be initialized first.
class HLocalValue extends HInstruction {
  HLocalValue(Entity? variable, super.type) : super._0() {
    sourceElement = variable;
  }

  @override
  String toString() => 'local ${sourceElement!.name}';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitLocalValue(this);
}

class HParameterValue extends HLocalValue {
  bool _potentiallyUsedAsVariable = true;

  HParameterValue(Entity? variable, AbstractValue type) : super(variable, type);

  // [HParameterValue]s are either the value of the parameter (in fully SSA
  // converted code), or the mutable variable containing the value (in
  // incompletely SSA converted code, e.g. methods containing exceptions).
  bool usedAsVariable() {
    if (_potentiallyUsedAsVariable) {
      // If the HParameterValue is used as a variable, all of the uses should be
      // HLocalGet or HLocalSet, so this loop exits fast.
      for (HInstruction user in usedBy) {
        if (user is HLocalGet) return true;
        if (user is HLocalSet && user.local == this) return true;
      }
      // An 'ssa-conversion' optimization can make the HParameterValue change
      // from a variable to a value, but there is no transformation that
      // re-introduces the variable.
      // TODO(sra): The builder knows that most parameters are not variables to
      // begin with, so could initialize [_potentiallyUsedAsVariable] to
      // `false`.
      _potentiallyUsedAsVariable = false;
    }
    return false;
  }

  @override
  String toString() => 'parameter ${sourceElement!.name}';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitParameterValue(this);
}

class HThis extends HParameterValue {
  // [element] can be null for some synthetic members, e.g. `$signature`.
  HThis(ThisLocal? element, AbstractValue type) : super(element, type);

  @override
  ThisLocal? get sourceElement => super.sourceElement as ThisLocal?;

  @override
  void set sourceElement(covariant ThisLocal? local) {
    super.sourceElement = local;
  }

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitThis(this);

  @override
  bool isCodeMotionInvariant() => true;

  @override
  bool isInterceptor(JClosedWorld closedWorld) {
    return closedWorld.interceptorData
        .isInterceptedClass(sourceElement!.enclosingClass);
  }

  @override
  String toString() => 'this';
}

class HPhi extends HInstruction {
  HPhi? get previousPhi => previous as HPhi?;
  HPhi? get nextPhi => next as HPhi?;

  // The order of the [inputs] must correspond to the order of the
  // predecessor-edges. That is if an input comes from the first predecessor
  // of the surrounding block, then the input must be the first in the [HPhi].
  HPhi(Local? variable, List<HInstruction> inputs, AbstractValue type)
      : super(inputs, type) {
    sourceElement = variable;
  }
  HPhi.noInputs(Local? variable, AbstractValue type) : this(variable, [], type);
  HPhi.singleInput(Local variable, HInstruction input, AbstractValue type)
      : this(variable, [input], type);
  HPhi.manyInputs(
      Local? variable, List<HInstruction> inputs, AbstractValue type)
      : this(variable, inputs, type);

  void addInput(HInstruction input) {
    assert(isInBasicBlock());
    inputs.add(input);
    assert(inputs.length <= block!.predecessors.length);
    input.usedBy.add(this);
  }

  @override
  String toString() => 'phi $id';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitPhi(this);
}

abstract class HRelational extends HInvokeBinary {
  bool usesBoolifiedInterceptor = false;
  HRelational(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
}

class HIdentity extends HRelational {
  // Cached codegen decision.
  String? singleComparisonOp; // null, '===', '=='

  HIdentity(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitIdentity(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.identity;
  @override
  _GvnType get _gvnType => _GvnType.identity;
  @override
  bool typeEquals(other) => other is HIdentity;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HGreater extends HRelational {
  HGreater(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitGreater(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.greater;
  @override
  _GvnType get _gvnType => _GvnType.greater;
  @override
  bool typeEquals(other) => other is HGreater;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HGreaterEqual extends HRelational {
  HGreaterEqual(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitGreaterEqual(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.greaterEqual;
  @override
  _GvnType get _gvnType => _GvnType.greaterEqual;
  @override
  bool typeEquals(other) => other is HGreaterEqual;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HLess extends HRelational {
  HLess(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitLess(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.less;
  @override
  _GvnType get _gvnType => _GvnType.less;
  @override
  bool typeEquals(other) => other is HLess;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HLessEqual extends HRelational {
  HLessEqual(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitLessEqual(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.lessEqual;
  @override
  _GvnType get _gvnType => _GvnType.lessEqual;
  @override
  bool typeEquals(other) => other is HLessEqual;
  @override
  bool dataEquals(HInstruction other) => true;
}

/// Return statement, either with or without a value.
class HReturn extends HControlFlow {
  HReturn(HInstruction? value, SourceInformation? sourceInformation) {
    if (value != null) inputs.add(value);
    this.sourceInformation = sourceInformation;
  }
  @override
  String toString() => 'return';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitReturn(this);
}

class HThrowExpression extends HInstruction {
  HThrowExpression(
      super.value, super.type, SourceInformation? sourceInformation)
      : super._1() {
    this.sourceInformation = sourceInformation;
  }
  @override
  String toString() => 'throw expression';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitThrowExpression(this);
  @override
  bool canThrow(AbstractValueDomain domain) => true;
}

class HAwait extends HInstruction {
  HAwait(super.value, super.type) : super._1();
  @override
  String toString() => 'await';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitAwait(this);
  // An await will throw if its argument is not a real future.
  @override
  bool canThrow(AbstractValueDomain domain) => true;
  @override
  SideEffects sideEffects = SideEffects();
}

class HYield extends HInstruction {
  HYield(super.value, this.hasStar, super.type,
      SourceInformation? sourceInformation)
      : super._1() {
    this.sourceInformation = sourceInformation;
  }
  bool hasStar;
  @override
  String toString() => 'yield';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitYield(this);
  @override
  bool canThrow(AbstractValueDomain domain) => false;
  @override
  SideEffects sideEffects = SideEffects();
}

class HThrow extends HControlFlow {
  final bool isRethrow;
  HThrow(HInstruction value, SourceInformation? sourceInformation,
      {this.isRethrow = false}) {
    inputs.add(value);
    this.sourceInformation = sourceInformation;
  }
  @override
  String toString() => 'throw';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitThrow(this);
}

// TODO(johnniwinther): Change this to a "HStaticLoad" of a field when we use
// CFE constants. It has been used for static tear-offs even though these should
// have been constants.
class HStatic extends HInstruction {
  final MemberEntity element;

  HStatic(this.element, super.type, SourceInformation? sourceInformation)
      : super._0() {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    if (element.isAssignable) {
      sideEffects.setDependsOnStaticPropertyStore();
    }
    setUseGvn();
    this.sourceInformation = sourceInformation;
  }
  @override
  String toString() => 'static ${element.name}';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitStatic(this);

  @override
  int gvnHashCode() => super.gvnHashCode() ^ element.hashCode;
  @override
  _GvnType get _gvnType => _GvnType.static;
  @override
  bool typeEquals(other) => other is HStatic;
  @override
  bool dataEquals(HStatic other) => element == other.element;
  @override
  bool isCodeMotionInvariant() => !element.isAssignable;
}

class HInterceptor extends HInstruction {
  // This field should originally be null to allow GVN'ing all
  // [HInterceptor] on the same input.
  Set<ClassEntity>? interceptedClasses;

  // inputs[0] is initially the only input, the receiver.

  // inputs[1] is a constant interceptor when the interceptor is a constant
  // except for a `null` receiver.  This is used when the receiver can't be
  // falsy, except for `null`, allowing the generation of code like
  //
  //     (a && C.JSArray_methods).get$first(a)
  //

  HInterceptor(super.receiver, super.type) : super._1() {
    this.sourceInformation = receiver.sourceInformation;
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    setUseGvn();
  }

  @override
  String toString() => 'interceptor on $interceptedClasses';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitInterceptor(this);
  HInstruction get receiver => inputs[0];

  bool get isConditionalConstantInterceptor => inputs.length == 2;
  HConstant get conditionalConstantInterceptor => inputs[1] as HConstant;
  void set conditionalConstantInterceptor(HConstant constant) {
    assert(!isConditionalConstantInterceptor);
    inputs.add(constant);
  }

  @override
  bool isInterceptor(JClosedWorld closedWorld) => true;

  @override
  _GvnType get _gvnType => _GvnType.interceptor;
  @override
  bool typeEquals(other) => other is HInterceptor;
  @override
  bool dataEquals(HInterceptor other) {
    return interceptedClasses == other.interceptedClasses ||
        (interceptedClasses!.length == other.interceptedClasses!.length &&
            interceptedClasses!.containsAll(other.interceptedClasses!));
  }
}

/// A "one-shot" interceptor is a call to a synthesized method that will fetch
/// the interceptor of its first parameter, and make a call on a given selector
/// with the remaining parameters.
///
/// In order to share the same optimizations with regular interceptor calls,
/// this class extends [HInvokeDynamic] and also has the null constant as the
/// first input.
class HOneShotInterceptor extends HInvokeDynamic {
  @override
  List<DartType> typeArguments;
  Set<ClassEntity>? interceptedClasses;

  HOneShotInterceptor(
      Selector selector,
      AbstractValue receiverType,
      List<HInstruction> inputs,
      AbstractValue resultType,
      this.typeArguments,
      this.interceptedClasses)
      : super(selector, receiverType, null, inputs, true, resultType) {
    assert(inputs[0].isConstantNull());
    assert(selector.callStructure.typeArgumentCount == typeArguments.length);
  }
  @override
  bool isCallOnInterceptor(JClosedWorld closedWorld) => true;

  @override
  String toString() =>
      'one shot interceptor: selector=$selector, mask=$receiverType';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitOneShotInterceptor(this);
}

/// An [HLazyStatic] is a static that is initialized lazily at first read.
class HLazyStatic extends HInstruction {
  final FieldEntity element;

  HLazyStatic(this.element, super.type, SourceInformation? sourceInformation)
      : super._0() {
    // TODO(4931): The first access has side-effects, but we afterwards we
    // should be able to GVN.
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
    this.sourceInformation = sourceInformation;
  }

  @override
  String toString() => 'lazy static ${element.name}';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitLazyStatic(this);

  // TODO(4931): We should be able to GVN some lazy static loads.

  @override
  bool isCodeMotionInvariant() => false;
  @override
  bool canThrow(AbstractValueDomain domain) => true;
}

class HStaticStore extends HInstruction {
  FieldEntity element;
  HStaticStore(this.element, HInstruction value)
      : super._1(value, value.instructionType) {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    sideEffects.setChangesStaticProperty();
  }
  @override
  String toString() => 'static store ${element.name}';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitStaticStore(this);

  HInstruction get value => inputs.single;

  @override
  _GvnType get _gvnType => _GvnType.staticStore;
  @override
  bool typeEquals(other) => other is HStaticStore;
  @override
  bool dataEquals(HStaticStore other) => element == other.element;
  @override
  bool isJsStatement() => usedBy.isEmpty;
}

class HLiteralList extends HInstruction {
  HLiteralList(List<HInstruction> inputs, AbstractValue type)
      : super(inputs, type);
  @override
  String toString() => 'literal list';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitLiteralList(this);

  @override
  bool isAllocation(AbstractValueDomain domain) => true;
}

/// The primitive array indexing operation. Note that this instruction
/// does not throw because we generate the checks explicitly.
class HIndex extends HInstruction {
  HIndex(super.receiver, super.index, super.type) : super._2() {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    sideEffects.setDependsOnIndexStore();
    setUseGvn();
  }

  @override
  String toString() => 'index operator';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitIndex(this);

  HInstruction get receiver => inputs[0];
  HInstruction get index => inputs[1];

  // Implicit dependency on HBoundsCheck or constraints on index.
  // TODO(27272): Make HIndex dependent on positions of eliminated bounds
  // checks.
  @override
  bool get isMovable => false;

  @override
  HInstruction getDartReceiver(JClosedWorld closedWorld) => receiver;
  @override
  bool onlyThrowsNSM() => true;
  @override
  bool canThrow(AbstractValueDomain domain) =>
      receiver.isNull(domain).isPotentiallyTrue;

  @override
  _GvnType get _gvnType => _GvnType.index_;
  @override
  bool typeEquals(HInstruction other) => other is HIndex;
  @override
  bool dataEquals(HIndex other) => true;
}

/// The primitive array assignment operation. Note that this instruction
/// does not throw because we generate the checks explicitly.
class HIndexAssign extends HInstruction {
  HIndexAssign(HInstruction receiver, HInstruction index, HInstruction value)
      : super([receiver, index, value], value.instructionType) {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    sideEffects.setChangesIndex();
  }
  @override
  String toString() => 'index assign operator';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitIndexAssign(this);

  HInstruction get receiver => inputs[0];
  HInstruction get index => inputs[1];
  HInstruction get value => inputs[2];

  // Implicit dependency on HBoundsCheck or constraints on index.
  // TODO(27272): Make HIndex dependent on eliminated bounds checks.
  @override
  bool get isMovable => false;

  @override
  HInstruction getDartReceiver(JClosedWorld closedWorld) => receiver;
  @override
  bool onlyThrowsNSM() => true;
  @override
  bool canThrow(AbstractValueDomain domain) =>
      receiver.isNull(domain).isPotentiallyTrue;
}

class HCharCodeAt extends HInstruction {
  HCharCodeAt(super.receiver, super.index, super.type) : super._2();

  @override
  String toString() => 'HCharCodeAt';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitCharCodeAt(this);

  HInstruction get receiver => inputs[0];
  HInstruction get index => inputs[1];

  // Implicit dependency on HBoundsCheck or constraints on index.
  // TODO(27272): Make HCharCodeAt dependent on positions of eliminated bounds
  // checks.
  @override
  bool get isMovable => false;

  @override
  HInstruction getDartReceiver(JClosedWorld closedWorld) => receiver;
  @override
  bool onlyThrowsNSM() => true;
  @override
  bool canThrow(AbstractValueDomain domain) =>
      receiver.isNull(domain).isPotentiallyTrue;

  @override
  _GvnType get _gvnType => _GvnType.charCodeAt;
  @override
  bool typeEquals(other) => other is HCharCodeAt;
  @override
  bool dataEquals(HCharCodeAt other) => true;
}

/// HLateValue is a late-stage instruction that can be used to force a value
/// into a temporary.
///
/// HLateValue is useful for naming values that would otherwise be generated at
/// use site, for example, if 'this' is used many times, replacing uses of
/// 'this' with HLateValue(HThis) will have the effect of copying 'this' to a
/// temporary which will reduce the size of minified code.
class HLateValue extends HInstruction implements HLateInstruction {
  HLateValue(HInstruction target) : super._1(target, target.instructionType);

  HInstruction get target => inputs.single;

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitLateValue(this);
  @override
  String toString() => 'HLateValue($target)';
}

enum PrimitiveCheckKind {
  argumentType,
  receiverType,
}

/// Check for receiver or argument type when lowering operation to a primitive,
/// e.g. lowering `+` to [HAdd].
///
/// With sound null safety, `a + b` will require `a` and `b` to be non-nullable
/// and these checks will become explicit in the source (e.g. `a! + b!`). At
/// that time, this check should be removed. If needed, the `!` check can be
/// optimized to give the same signals to the JavaScript VM.
class HPrimitiveCheck extends HCheck {
  final DartType typeExpression;
  final PrimitiveCheckKind kind;

  // [receiverTypeCheckSelector] is the selector used for a receiver type check
  // on open-coded operators, e.g. the not-null check on `x` in `x + 1` would be
  // compiled to the following, for which we need the selector `$add`.
  //
  //     if (typeof x != "number") x.$add();
  //
  final Selector? receiverTypeCheckSelector;

  final AbstractValue checkedType;

  HPrimitiveCheck(this.typeExpression, this.kind, AbstractValue type,
      HInstruction input, SourceInformation? sourceInformation,
      {this.receiverTypeCheckSelector})
      : checkedType = type,
        super._1(input, type) {
    assert(isReceiverTypeCheck == (receiverTypeCheckSelector != null));
    this.sourceElement = input.sourceElement;
    this.sourceInformation = sourceInformation;
  }

  bool get isArgumentTypeCheck => kind == PrimitiveCheckKind.argumentType;
  bool get isReceiverTypeCheck => kind == PrimitiveCheckKind.receiverType;

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitPrimitiveCheck(this);

  @override
  bool isJsStatement() => true;
  @override
  bool isControlFlow() => true;

  @override
  _GvnType get _gvnType => _GvnType.primitiveCheck;
  @override
  bool typeEquals(HInstruction other) => other is HPrimitiveCheck;
  @override
  bool isCodeMotionInvariant() => false;

  @override
  bool dataEquals(HPrimitiveCheck other) {
    return kind == other.kind &&
        checkedType == other.checkedType &&
        receiverTypeCheckSelector == other.receiverTypeCheckSelector;
  }

  bool isRedundant(JClosedWorld closedWorld) {
    AbstractValueDomain abstractValueDomain = closedWorld.abstractValueDomain;
    // Type is refined from `dynamic`, so it might become non-redundant.
    if (abstractValueDomain.containsAll(checkedType).isPotentiallyTrue) {
      return false;
    }
    AbstractValue inputType = checkedInput.instructionType;
    return abstractValueDomain.isIn(inputType, checkedType).isDefinitelyTrue;
  }

  @override
  String toString() => 'HPrimitiveCheck(checkedType=$checkedType, kind=$kind, '
      'checkedInput=$checkedInput)';
}

/// A check that the input to a condition (if, ?:, while, etc) is non-null. The
/// front-end generates 'as bool' checks, but until the transition to null
/// safety is complete, this allows `null` to be passed to the condition.
///
// TODO(sra): Once NNDB is far enough along that the front-end can generate `as
// bool!` checks and the backend checks them correctly, this instruction will
// become unnecessary and should be removed.
class HBoolConversion extends HCheck {
  HBoolConversion(super.input, super.type) : super._1();

  @override
  bool isJsStatement() => false;

  @override
  bool isCodeMotionInvariant() => false;

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitBoolConversion(this);

  @override
  _GvnType get _gvnType => _GvnType.boolConversion;
  @override
  bool typeEquals(HInstruction other) => other is HBoolConversion;
  @override
  bool dataEquals(HBoolConversion other) => true;

  bool isRedundant(JClosedWorld closedWorld) {
    AbstractValueDomain abstractValueDomain = closedWorld.abstractValueDomain;
    AbstractValue inputType = checkedInput.instructionType;
    return abstractValueDomain
        .isIn(inputType, instructionType)
        .isDefinitelyTrue;
  }

  @override
  String toString() => 'HBoolConversion($checkedInput)';
}

/// A check that the input is not null. This corresponds to the postfix
/// null-check operator '!'.
///
/// A null check is inserted on the receiver when inlining an instance method or
/// field getter or setter when the receiver might be null. In these cases, the
/// [selector] and [field] members are assigned.
class HNullCheck extends HCheck {
  // A sticky check is not optimized away on the basis of the input type.
  final bool sticky;
  Selector? selector;
  FieldEntity? field;

  HNullCheck(super.input, super.type, {this.sticky = false}) : super._1();

  @override
  bool isControlFlow() => true;
  @override
  bool isJsStatement() => true;

  @override
  bool isCodeMotionInvariant() => false;

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitNullCheck(this);

  @override
  _GvnType get _gvnType => _GvnType.nullCheck;
  @override
  bool typeEquals(HInstruction other) => other is HNullCheck;
  @override
  bool dataEquals(HNullCheck other) => true;

  bool isRedundant(JClosedWorld closedWorld) {
    if (sticky) return false;
    AbstractValueDomain abstractValueDomain = closedWorld.abstractValueDomain;
    AbstractValue inputType = checkedInput.instructionType;
    return abstractValueDomain.isNull(inputType).isDefinitelyFalse;
  }

  @override
  String toString() {
    String fieldString = field == null ? '' : ', $field';
    String selectorString = selector == null ? '' : ', $selector';
    return 'HNullCheck($checkedInput$fieldString$selectorString)';
  }
}

/// A check for a late sentinel to determine if a late field may be read from or
/// written to.
abstract class HLateCheck extends HCheck {
  // Checks may be 'trusted' and result in no runtime check. This is done by
  // compiling with the checks in place and removing them after optimizations.
  final bool isTrusted;

  HLateCheck(HInstruction input, HInstruction? name, this.isTrusted,
      AbstractValue type)
      : super([input, if (name != null) name], type);

  bool get hasName => inputs.length > 1;

  HInstruction get name {
    if (hasName) return inputs[1];
    throw StateError('HLateCheck.name: no name');
  }

  @override
  bool isControlFlow() => true;

  @override
  bool isCodeMotionInvariant() => false;
}

/// A check that a late field has been initialized and can therefore be read.
class HLateReadCheck extends HLateCheck {
  HLateReadCheck(HInstruction input, HInstruction? name, bool isTrusted,
      AbstractValue type)
      : super(input, name, isTrusted, type);

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitLateReadCheck(this);

  @override
  _GvnType get _gvnType => _GvnType.lateReadCheck;

  @override
  bool typeEquals(HInstruction other) => other is HLateReadCheck;

  @override
  bool dataEquals(HLateReadCheck other) => isTrusted == other.isTrusted;

  bool isRedundant(JClosedWorld closedWorld) {
    AbstractValueDomain abstractValueDomain = closedWorld.abstractValueDomain;
    AbstractValue inputType = checkedInput.instructionType;
    return abstractValueDomain.isLateSentinel(inputType).isDefinitelyFalse;
  }

  @override
  String toString() {
    return 'HLateReadCheck($checkedInput)';
  }
}

/// A check that a late final field has not been initialized yet and can
/// therefore be written to.
///
/// The difference between [HLateWriteOnceCheck] and [HLateInitializeOnceCheck]
/// is that the latter occurs on writes performed as part of the initializer
/// expression.
class HLateWriteOnceCheck extends HLateCheck {
  HLateWriteOnceCheck(HInstruction input, HInstruction? name, bool isTrusted,
      AbstractValue type)
      : super(input, name, isTrusted, type);

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitLateWriteOnceCheck(this);

  @override
  _GvnType get _gvnType => _GvnType.lateWriteOnceCheck;

  @override
  bool typeEquals(HInstruction other) => other is HLateWriteOnceCheck;

  @override
  bool dataEquals(HLateWriteOnceCheck other) => isTrusted == other.isTrusted;

  bool isRedundant(JClosedWorld closedWorld) {
    AbstractValueDomain abstractValueDomain = closedWorld.abstractValueDomain;
    AbstractValue inputType = checkedInput.instructionType;
    return abstractValueDomain.isLateSentinel(inputType).isDefinitelyTrue;
  }

  @override
  String toString() {
    return 'HLateWriteOnceCheck($checkedInput)';
  }
}

/// A check that a late final field has not been initialized yet and can
/// therefore be initialized.
///
/// The difference between [HLateWriteOnceCheck] and [HLateInitializeOnceCheck]
/// is that the latter occurs on writes performed as part of the initializer
/// expression.
class HLateInitializeOnceCheck extends HLateCheck {
  HLateInitializeOnceCheck(HInstruction input, HInstruction? name,
      bool isTrusted, AbstractValue type)
      : super(input, name, isTrusted, type);

  @override
  R accept<R>(HVisitor<R> visitor) =>
      visitor.visitLateInitializeOnceCheck(this);

  @override
  _GvnType get _gvnType => _GvnType.lateInitializeOnceCheck;

  @override
  bool typeEquals(HInstruction other) => other is HLateInitializeOnceCheck;

  @override
  bool dataEquals(HLateInitializeOnceCheck other) =>
      isTrusted == other.isTrusted;

  bool isRedundant(JClosedWorld closedWorld) {
    AbstractValueDomain abstractValueDomain = closedWorld.abstractValueDomain;
    AbstractValue inputType = checkedInput.instructionType;
    return abstractValueDomain.isLateSentinel(inputType).isDefinitelyTrue;
  }

  @override
  String toString() {
    return 'HLateInitializeOnceCheck($checkedInput)';
  }
}

/// The [HTypeKnown] instruction marks a value with a refined type.
class HTypeKnown extends HCheck {
  AbstractValue knownType;
  final bool _isMovable;

  HTypeKnown.pinned(this.knownType, HInstruction input)
      : this._isMovable = false,
        super._1(input, knownType);

  HTypeKnown.witnessed(this.knownType, HInstruction input, HInstruction witness)
      : this._isMovable = true,
        super._2(input, witness, knownType);

  @override
  String toString() => 'TypeKnown $knownType';
  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitTypeKnown(this);

  @override
  bool isJsStatement() => false;
  @override
  bool isControlFlow() => false;
  @override
  bool canThrow(AbstractValueDomain domain) => false;

  bool get isPinned => inputs.length == 1;

  HInstruction? get witness => inputs.length == 2 ? inputs[1] : null;

  @override
  _GvnType get _gvnType => _GvnType.typeKnown;
  @override
  bool typeEquals(HInstruction other) => other is HTypeKnown;
  @override
  bool isCodeMotionInvariant() => true;
  @override
  bool get isMovable => _isMovable && useGvn();

  @override
  bool dataEquals(HTypeKnown other) {
    return knownType == other.knownType &&
        instructionType == other.instructionType;
  }

  bool isRedundant(JClosedWorld closedWorld) {
    AbstractValueDomain abstractValueDomain = closedWorld.abstractValueDomain;
    if (abstractValueDomain.containsAll(knownType).isPotentiallyTrue) {
      return false;
    }
    AbstractValue inputType = checkedInput.instructionType;
    return abstractValueDomain.isIn(inputType, knownType).isDefinitelyTrue;
  }
}

class HRangeConversion extends HCheck {
  HRangeConversion(super.input, super.type) : super._1() {
    sourceElement = checkedInput.sourceElement;
  }

  @override
  bool get isMovable => false;

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitRangeConversion(this);
}

class HStringConcat extends HInstruction {
  HStringConcat(super.left, super.right, super.type) : super._2() {
    setUseGvn();
  }

  HInstruction get left => inputs[0];
  HInstruction get right => inputs[1];

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitStringConcat(this);
  @override
  String toString() => "string concat";

  @override
  _GvnType get _gvnType => _GvnType.stringConcat;
  @override
  bool typeEquals(HInstruction other) => other is HStringConcat;
  @override
  bool dataEquals(HStringConcat other) => true;
}

/// The part of string interpolation which converts and interpolated expression
/// into a String value.
class HStringify extends HInstruction {
  bool _isPure = false; // Some special cases are pure, e.g. int argument.
  HStringify(super.input, super.resultType) : super._1() {
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
  }

  void setPure() {
    sideEffects.clearAllDependencies();
    sideEffects.clearAllSideEffects();
    _isPure = true;
    setUseGvn();
  }

  @override
  bool canThrow(AbstractValueDomain domain) => !_isPure;

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitStringify(this);
  @override
  String toString() => "stringify";

  @override
  _GvnType get _gvnType => _GvnType.stringify;
  @override
  bool typeEquals(HInstruction other) => other is HStringify;
  @override
  bool dataEquals(HStringify other) => this._isPure == other._isPure;
}

/// Non-block-based (aka. traditional) loop information.
class HLoopInformation {
  final HBasicBlock header;
  final List<HBasicBlock> blocks = [];
  final List<HBasicBlock> backEdges = [];
  final List<LabelDefinition> labels;
  final JumpTarget? target;

  /// Corresponding block information for the loop.
  HLoopBlockInformation? loopBlockInformation;

  HLoopInformation(this.header, this.target, this.labels);

  void addBackEdge(HBasicBlock predecessor) {
    backEdges.add(predecessor);
    List<HBasicBlock> workQueue = [predecessor];
    do {
      HBasicBlock current = workQueue.removeLast();
      addBlock(current, workQueue);
    } while (!workQueue.isEmpty);
  }

  // Adds a block and transitively all its predecessors in the loop as
  // loop blocks.
  void addBlock(HBasicBlock block, List<HBasicBlock> workQueue) {
    if (identical(block, header)) return;
    HBasicBlock? parentHeader = block.parentLoopHeader;
    if (identical(parentHeader, header)) {
      // Nothing to do in this case.
    } else if (parentHeader != null) {
      workQueue.add(parentHeader);
    } else {
      block.parentLoopHeader = header;
      blocks.add(block);
      workQueue.addAll(block.predecessors);
    }
  }
}

/// Embedding of a [HBlockInformation] for block-structure based traversal
/// in a dominator based flow traversal by attaching it to a basic block.
/// To go back to dominator-based traversal, a [HSubGraphBlockInformation]
/// structure can be added in the block structure.
class HBlockFlow {
  final HBlockInformation body;
  final HBasicBlock? continuation; // `null` if all paths throw.
  HBlockFlow(this.body, this.continuation);
}

/// Information about a syntactic-like structure.
abstract class HBlockInformation {
  HBasicBlock get start;
  HBasicBlock get end;
  bool accept(HBlockInformationVisitor visitor);
}

/// Information about a statement-like structure.
abstract class HStatementInformation extends HBlockInformation {
  @override
  bool accept(HStatementInformationVisitor visitor);
}

/// Information about an expression-like structure.
abstract class HExpressionInformation extends HBlockInformation {
  @override
  bool accept(HExpressionInformationVisitor visitor);
  HInstruction? get conditionExpression;
}

abstract class HStatementInformationVisitor {
  bool visitLabeledBlockInfo(HLabeledBlockInformation info);
  bool visitLoopInfo(HLoopBlockInformation info);
  bool visitIfInfo(HIfBlockInformation info);
  bool visitTryInfo(HTryBlockInformation info);
  bool visitSwitchInfo(HSwitchBlockInformation info);
  bool visitSequenceInfo(HStatementSequenceInformation info);
  // Pseudo-structure embedding a dominator-based traversal into
  // the block-structure traversal. This will eventually go away.
  bool visitSubGraphInfo(HSubGraphBlockInformation info);
}

abstract class HExpressionInformationVisitor {
  bool visitSubExpressionInfo(HSubExpressionBlockInformation info);
}

abstract class HBlockInformationVisitor
    implements HStatementInformationVisitor, HExpressionInformationVisitor {}

/// Generic class wrapping a [SubGraph] as a block-information until
/// all structures are handled properly.
class HSubGraphBlockInformation implements HStatementInformation {
  final SubGraph? subGraph;
  HSubGraphBlockInformation(this.subGraph);

  @override
  HBasicBlock get start => subGraph!.start;
  @override
  HBasicBlock get end => subGraph!.end;

  @override
  bool accept(HStatementInformationVisitor visitor) =>
      visitor.visitSubGraphInfo(this);
}

/// Generic class wrapping a [SubExpression] as a block-information until
/// expressions structures are handled properly.
class HSubExpressionBlockInformation implements HExpressionInformation {
  final SubExpression? subExpression;
  HSubExpressionBlockInformation(this.subExpression);

  @override
  HBasicBlock get start => subExpression!.start;
  @override
  HBasicBlock get end => subExpression!.end;

  @override
  HInstruction? get conditionExpression => subExpression!.conditionExpression;

  @override
  bool accept(HExpressionInformationVisitor visitor) =>
      visitor.visitSubExpressionInfo(this);
}

/// A sequence of separate statements.
class HStatementSequenceInformation implements HStatementInformation {
  final List<HStatementInformation> statements;
  HStatementSequenceInformation(this.statements);

  @override
  HBasicBlock get start => statements[0].start;
  @override
  HBasicBlock get end => statements.last.end;

  @override
  bool accept(HStatementInformationVisitor visitor) =>
      visitor.visitSequenceInfo(this);
}

class HLabeledBlockInformation implements HStatementInformation {
  final HStatementInformation body;
  final List<LabelDefinition> labels;
  final JumpTarget? target;
  final bool isContinue;

  HLabeledBlockInformation(this.body, List<LabelDefinition> labels,
      {this.isContinue = false})
      : this.labels = labels,
        this.target = labels[0].target;

  HLabeledBlockInformation.implicit(this.body, this.target,
      {this.isContinue = false})
      : this.labels = const [];

  @override
  HBasicBlock get start => body.start;
  @override
  HBasicBlock get end => body.end;

  @override
  bool accept(HStatementInformationVisitor visitor) =>
      visitor.visitLabeledBlockInfo(this);
}

enum LoopBlockInformationKind {
  notALoop,
  whileLoop,
  forLoop,
  doWhileLoop,
  forInLoop,
  switchContinueLoop,
}

class HLoopBlockInformation implements HStatementInformation {
  final LoopBlockInformationKind kind;
  final HExpressionInformation? initializer;
  final HExpressionInformation? condition;
  final HStatementInformation? body;
  final HExpressionInformation? updates;
  final JumpTarget? target;
  final List<LabelDefinition> labels;
  final SourceInformation? sourceInformation;

  HLoopBlockInformation(this.kind, this.initializer, this.condition, this.body,
      this.updates, this.target, this.labels, this.sourceInformation) {
    assert((kind == LoopBlockInformationKind.doWhileLoop
            ? body!.start
            : condition!.start)
        .isLoopHeader());
  }

  @override
  HBasicBlock get start {
    if (initializer != null) return initializer!.start;
    if (kind == LoopBlockInformationKind.doWhileLoop) {
      return body!.start;
    }
    return condition!.start;
  }

  HBasicBlock get loopHeader {
    return kind == LoopBlockInformationKind.doWhileLoop
        ? body!.start
        : condition!.start;
  }

  @override
  HBasicBlock get end {
    if (updates != null) return updates!.end;
    if (kind == LoopBlockInformationKind.doWhileLoop && condition != null) {
      return condition!.end;
    }
    return body!.end;
  }

  @override
  bool accept(HStatementInformationVisitor visitor) =>
      visitor.visitLoopInfo(this);
}

class HIfBlockInformation implements HStatementInformation {
  final HExpressionInformation? condition;
  final HStatementInformation? thenGraph;
  final HStatementInformation? elseGraph;
  HIfBlockInformation(this.condition, this.thenGraph, this.elseGraph);

  @override
  HBasicBlock get start => condition!.start;
  @override
  HBasicBlock get end => elseGraph == null ? thenGraph!.end : elseGraph!.end;

  @override
  bool accept(HStatementInformationVisitor visitor) =>
      visitor.visitIfInfo(this);
}

class HTryBlockInformation implements HStatementInformation {
  final HStatementInformation? body;
  final HLocalValue? catchVariable;
  final HStatementInformation? catchBlock;
  final HStatementInformation? finallyBlock;
  HTryBlockInformation(
      this.body, this.catchVariable, this.catchBlock, this.finallyBlock);

  @override
  HBasicBlock get start => body!.start;
  @override
  HBasicBlock get end =>
      finallyBlock == null ? catchBlock!.end : finallyBlock!.end;

  @override
  bool accept(HStatementInformationVisitor visitor) =>
      visitor.visitTryInfo(this);
}

class HSwitchBlockInformation implements HStatementInformation {
  final HExpressionInformation expression;
  final List<HStatementInformation> statements;
  final JumpTarget? target;
  final List<LabelDefinition> labels;
  final SourceInformation? sourceInformation;

  HSwitchBlockInformation(this.expression, this.statements, this.target,
      this.labels, this.sourceInformation);

  @override
  HBasicBlock get start => expression.start;
  @override
  HBasicBlock get end {
    // We don't create a switch block if there are no cases.
    assert(!statements.isEmpty);
    return statements.last.end;
  }

  @override
  bool accept(HStatementInformationVisitor visitor) =>
      visitor.visitSwitchInfo(this);
}

// -----------------------------------------------------------------------------

/// Is-test using Rti form of type expression.
///
/// This instruction can be used for any type. Tests for simple types are
/// lowered to other instructions, so this instruction remains for types that
/// depend on type variables and complex types.
class HIsTest extends HInstruction {
  final AbstractValueWithPrecision checkedAbstractValue;
  DartType dartType;

  HIsTest(this.dartType, this.checkedAbstractValue, super.rti, super.checked,
      super.instructionType)
      : super._2() {
    setUseGvn();
  }

  // The type input is first to facilitate the `type.is(value)` codegen pattern.
  HInstruction get typeInput => inputs[0];
  HInstruction get checkedInput => inputs[1];

  AbstractBool evaluate(JClosedWorld closedWorld, CompilerOptions options) =>
      _typeTest(
          checkedInput, dartType, checkedAbstractValue, closedWorld, options,
          isCast: false);

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitIsTest(this);

  @override
  _GvnType get _gvnType => _GvnType.isTest;

  @override
  bool typeEquals(HInstruction other) => other is HIsTest;

  @override
  bool dataEquals(HIsTest other) => true;

  @override
  String toString() => 'HIsTest()';
}

/// Simple is-test for a known type that can be achieved without reference to an
/// Rti describing the type.
class HIsTestSimple extends HInstruction {
  final DartType dartType;
  final AbstractValueWithPrecision checkedAbstractValue;
  final IsTestSpecialization specialization;

  HIsTestSimple(this.dartType, this.checkedAbstractValue, this.specialization,
      super.checked, super.type)
      : super._1() {
    setUseGvn();
  }

  HInstruction get checkedInput => inputs[0];

  AbstractBool evaluate(JClosedWorld closedWorld, CompilerOptions options) =>
      _typeTest(
          checkedInput, dartType, checkedAbstractValue, closedWorld, options,
          isCast: false);

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitIsTestSimple(this);

  @override
  _GvnType get _gvnType => _GvnType.isTestSimple;

  @override
  bool typeEquals(HInstruction other) => other is HIsTestSimple;

  @override
  bool dataEquals(HIsTestSimple other) => dartType == other.dartType;

  @override
  String toString() => 'HIsTestSimple()';
}

AbstractBool _typeTest(
    HInstruction expression,
    DartType dartType,
    AbstractValueWithPrecision checkedAbstractValue,
    JClosedWorld closedWorld,
    CompilerOptions options,
    {required bool isCast}) {
  // The null safety mode may affect the result of a type test, so defer to
  // runtime.
  if (options.experimentNullSafetyChecks) return AbstractBool.Maybe;

  JCommonElements commonElements = closedWorld.commonElements;
  DartTypes dartTypes = closedWorld.dartTypes;
  AbstractValueDomain abstractValueDomain = closedWorld.abstractValueDomain;
  AbstractValue subsetType = expression.instructionType;
  AbstractValue supersetType = checkedAbstractValue.abstractValue;
  AbstractBool expressionIsNull = expression.isNull(abstractValueDomain);

  bool _nullIs(DartType type) =>
      dartTypes.isStrongTopType(type) ||
      type is LegacyType &&
          (type.baseType.isObject ||
              type.baseType is NeverType ||
              _nullIs(type.baseType)) ||
      type is NullableType ||
      type is FutureOrType && _nullIs(type.typeArgument) ||
      type.isNull;

  if (!isCast) {
    if (expressionIsNull.isDefinitelyTrue) {
      if (dartType.containsFreeTypeVariables) return AbstractBool.Maybe;
      return AbstractBool.trueOrFalse(_nullIs(dartType));
    }
    if (expressionIsNull.isPotentiallyTrue) {
      if (dartType.isObject) return AbstractBool.Maybe;
    }
  } else if (expressionIsNull.isDefinitelyTrue && _nullIs(dartType)) {
    return AbstractBool.True;
  }

  if (checkedAbstractValue.isPrecise &&
      abstractValueDomain.isIn(subsetType, supersetType).isDefinitelyTrue) {
    return AbstractBool.True;
  }

  if (abstractValueDomain
      .areDisjoint(subsetType, supersetType)
      .isDefinitelyTrue) {
    return AbstractBool.False;
  }

  // TODO(39287): Let the abstract value domain fully handle this.
  // Currently, the abstract value domain cannot (soundly) state that an is-test
  // is definitely false, so we reuse some of the case-by-case logic from the
  // old [HIs] optimization.

  AbstractBool checkInterface(InterfaceType interface) {
    if (expression.isInteger(abstractValueDomain).isDefinitelyTrue) {
      if (dartTypes.isSubtype(commonElements.intType, interface)) {
        return AbstractBool.True;
      }
      if (interface == commonElements.doubleType) {
        // We let the JS semantics decide for that check. Currently the code we
        // emit will always return true.
        return AbstractBool.Maybe;
      }
      return AbstractBool.False;
    }

    if (expression.isNumber(abstractValueDomain).isDefinitelyTrue) {
      if (dartTypes.isSubtype(commonElements.numType, interface)) {
        return AbstractBool.True;
      }
      // We cannot just return false, because the expression may be of type int or
      // double.
      return AbstractBool.Maybe;
    }

    // We need the raw check because we don't have the notion of generics in the
    // backend. For example, `this` in a class `A<T>` is currently always
    // considered to have the raw type.
    if (dartTypes.treatAsRawType(interface)) {
      return abstractValueDomain.isInstanceOf(subsetType, interface.element);
    }

    return AbstractBool.Maybe;
  }

  AbstractBool isNullAsCheck = !options.useLegacySubtyping && isCast
      ? expressionIsNull
      : AbstractBool.False;
  AbstractBool isNullIsTest = !isCast ? expressionIsNull : AbstractBool.False;

  AbstractBool unwrapAndCheck(DartType type) {
    if (dartTypes.isTopType(dartType)) return AbstractBool.True;
    if (type is NeverType) return AbstractBool.False;
    if (type is InterfaceType) {
      if (type.isNull) return expressionIsNull;
      return ~(isNullAsCheck | isNullIsTest) & checkInterface(type);
    }
    if (type is LegacyType) {
      assert(!type.baseType.isObject);
      return ~isNullIsTest & unwrapAndCheck(type.baseType);
    }
    if (type is NullableType) {
      return unwrapAndCheck(type.baseType);
    }
    if (type is FutureOrType) {
      return unwrapAndCheck(type.typeArgument) | AbstractBool.Maybe;
    }
    return AbstractBool.Maybe;
  }

  return unwrapAndCheck(dartType);
}

/// Type cast or type check using Rti form of type expression.
class HAsCheck extends HCheck {
  final AbstractValueWithPrecision checkedType;
  DartType checkedTypeExpression;
  final bool isTypeError;

  HAsCheck(this.checkedType, this.checkedTypeExpression, this.isTypeError,
      super.rti, super.checked, super.instructionType)
      : super._2();

  // The type input is first to facilitate the `type.as(value)` codegen pattern.
  HInstruction get typeInput => inputs[0];
  @override
  HInstruction get checkedInput => inputs[1];

  @override
  bool isJsStatement() => false;

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitAsCheck(this);

  @override
  _GvnType get _gvnType => _GvnType.asCheck;

  @override
  bool typeEquals(HInstruction other) => other is HAsCheck;

  @override
  bool dataEquals(HAsCheck other) {
    return isTypeError == other.isTypeError;
  }

  bool isRedundant(JClosedWorld closedWorld, CompilerOptions options) =>
      _typeTest(checkedInput, checkedTypeExpression, checkedType, closedWorld,
              options,
              isCast: true)
          .isDefinitelyTrue;

  @override
  String toString() {
    String error = isTypeError ? 'TypeError' : 'CastError';
    return 'HAsCheck($error)';
  }
}

/// Type cast or type check for simple known types that are achieved via a
/// simple static call.
class HAsCheckSimple extends HCheck {
  final DartType dartType;
  final AbstractValueWithPrecision checkedType;
  final bool isTypeError;
  final FunctionEntity method;

  HAsCheckSimple(super.checked, this.dartType, this.checkedType,
      this.isTypeError, this.method, super.type)
      : super._1();

  @override
  HInstruction get checkedInput => inputs[0];

  @override
  bool isJsStatement() => false;

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitAsCheckSimple(this);

  bool isRedundant(JClosedWorld closedWorld, CompilerOptions options) =>
      _typeTest(checkedInput, dartType, checkedType, closedWorld, options,
              isCast: true)
          .isDefinitelyTrue;

  @override
  _GvnType get _gvnType => _GvnType.asCheckSimple;

  @override
  bool typeEquals(HInstruction other) => other is HAsCheckSimple;

  @override
  bool dataEquals(HAsCheckSimple other) {
    return isTypeError == other.isTypeError && dartType == other.dartType;
  }

  @override
  String toString() {
    String error = isTypeError ? 'TypeError' : 'CastError';
    return 'HAsCheckSimple($error)';
  }
}

/// Subtype check comparing two Rti types.
class HSubtypeCheck extends HCheck {
  HSubtypeCheck(super.subtype, super.supertype, super.type) : super._2() {
    setUseGvn();
  }

  HInstruction get typeInput => inputs[1];

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitSubtypeCheck(this);

  @override
  _GvnType get _gvnType => _GvnType.subtypeCheck;

  @override
  bool typeEquals(HInstruction other) => other is HSubtypeCheck;

  @override
  bool dataEquals(HSubtypeCheck other) => true;

  @override
  String toString() => 'HSubtypeCheck()';
}

/// Common supertype for instructions that generate Rti values.
abstract interface class HRtiInstruction {}

/// Evaluates an Rti type recipe in the global environment.
class HLoadType extends HInstruction implements HRtiInstruction {
  TypeRecipe typeExpression;

  HLoadType(this.typeExpression, super.instructionType) : super._0() {
    setUseGvn();
  }

  HLoadType.type(DartType dartType, AbstractValue instructionType)
      : this(TypeExpressionRecipe(dartType), instructionType);

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitLoadType(this);

  @override
  _GvnType get _gvnType => _GvnType.loadType;

  @override
  bool typeEquals(HInstruction other) => other is HLoadType;

  @override
  bool dataEquals(HLoadType other) {
    return typeExpression == other.typeExpression;
  }

  @override
  String toString() => 'HLoadType($typeExpression)';
}

/// The reified Rti environment stored on a class instance.
///
/// Classes with reified type arguments have the type environment stored on the
/// instance. The reified environment is typically stored as the instance type,
/// e.g. "UnmodifiableListView<int>".
class HInstanceEnvironment extends HInstruction implements HRtiInstruction {
  late AbstractValue codegenInputType; // Assigned in SsaTypeKnownRemover

  HInstanceEnvironment(super.instance, super.type) : super._1() {
    setUseGvn();
  }

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitInstanceEnvironment(this);

  @override
  _GvnType get _gvnType => _GvnType.instanceEnvironment;

  @override
  bool typeEquals(HInstruction other) => other is HInstanceEnvironment;

  @override
  bool dataEquals(HInstanceEnvironment other) => true;

  @override
  String toString() => 'HInstanceEnvironment()';
}

/// Evaluates an Rti type recipe in an Rti environment.
class HTypeEval extends HInstruction implements HRtiInstruction {
  TypeEnvironmentStructure envStructure;
  TypeRecipe typeExpression;

  HTypeEval(
      super.environment, this.envStructure, this.typeExpression, super.type)
      : super._1() {
    setUseGvn();
  }

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitTypeEval(this);

  @override
  _GvnType get _gvnType => _GvnType.typeEval;

  @override
  bool typeEquals(HInstruction other) => other is HTypeEval;

  @override
  bool dataEquals(HTypeEval other) {
    return TypeRecipe.yieldsSameType(
        typeExpression, envStructure, other.typeExpression, other.envStructure);
  }

  @override
  String toString() => 'HTypeEval($typeExpression)';
}

/// Extends an Rti type environment with generic function types.
class HTypeBind extends HInstruction implements HRtiInstruction {
  HTypeBind(super.environment, super.typeArguments, super.type) : super._2() {
    setUseGvn();
  }

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitTypeBind(this);

  @override
  _GvnType get _gvnType => _GvnType.typeBind;

  @override
  bool typeEquals(HInstruction other) => other is HTypeBind;

  @override
  bool dataEquals(HTypeBind other) => true;

  @override
  String toString() => 'HTypeBind()';
}

/// Check Array or TypedData for permission to modify or grow.
///
/// Typical use to check modifiability for `a[i] = 0`. The array flags are
/// checked to see if there is a bit that prohibits modification.
///
///     a = ...
///     f = HArrayFlagsGet(a);
///     a2 = HArrayFlagsCheck(a, f, ArrayFlags.unmodifiableCheck, "[]=", "modify")
///     a2[i] = 0
///
/// HArrayFlagsGet is a separate instruction so that 'loading' the flags from
/// the Array can by hoisted.
class HArrayFlagsCheck extends HCheck {
  HArrayFlagsCheck(
      HInstruction array,
      HInstruction arrayFlags,
      HInstruction checkFlags,
      HInstruction? operation,
      HInstruction? verb,
      AbstractValue type)
      : super([
          array,
          arrayFlags,
          checkFlags,
          if (operation != null) operation,
          if (verb != null) verb,
        ], type);

  HInstruction get array => inputs[0];
  HInstruction get arrayFlags => inputs[1];
  HInstruction get checkFlags => inputs[2];

  bool get hasOperation => inputs.length > 3;
  HInstruction get operation => inputs[3];

  bool get hasVerb => inputs.length > 4;
  HInstruction get verb => inputs[4];

  // The checked type is the input type, refined to match the flags.
  AbstractValue computeInstructionType(
      AbstractValue inputType, AbstractValueDomain domain) {
    // TODO(sra): Depening on the checked flags, the output is fixed-length or
    // unmodifiable. Refine the type to the degree an AbstractValue can express
    // that.
    return inputType;
  }

  bool alwaysThrows() {
    if ((arrayFlags, checkFlags)
        case (
          HConstant(constant: IntConstantValue(intValue: final arrayBits)),
          HConstant(constant: IntConstantValue(intValue: final checkBits))
        ) when arrayBits & checkBits != BigInt.zero) {
      return true;
    }
    return false;
  }

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitArrayFlagsCheck(this);

  @override
  bool isControlFlow() => true;
  @override
  bool isJsStatement() => true;

  @override
  _GvnType get _gvnType => _GvnType.arrayFlagsCheck;

  @override
  bool typeEquals(HInstruction other) => other is HArrayFlagsCheck;

  @override
  bool dataEquals(HArrayFlagsCheck other) => true;
}

class HArrayFlagsGet extends HInstruction {
  HArrayFlagsGet(HInstruction array, AbstractValue type)
      : super([array], type) {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    // Dependency on HArrayFlagsSet.
    sideEffects.setDependsOnInstancePropertyStore();
    setUseGvn();
  }

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitArrayFlagsGet(this);

  @override
  _GvnType get _gvnType => _GvnType.arrayFlagsGet;

  @override
  bool typeEquals(HInstruction other) => other is HArrayFlagsGet;

  @override
  bool dataEquals(HArrayFlagsGet other) => true;
}

/// Tag an Array or TypedData object to mark it as unmodifiable or fixed-length.
///
/// The HArrayFlagsSet instruction represents the tagged Array or TypedData
/// object. The instruction type can be different to the `array` input.
/// HArrayFlagsSet is used in a 'linear' style - there are no accesses to the
/// input after this operation.
///
/// To ensure that HArrayFlagsGet (possibly from inlined code) does not float
/// past HArrayFlagsSet, we use the 'instance property' effect.
class HArrayFlagsSet extends HInstruction
    implements HOutputConstrainedToAnInput {
  HArrayFlagsSet(HInstruction array, HInstruction flags, AbstractValue type)
      : super([array, flags], type) {
    // For correct ordering with respect to HArrayFlagsGet:
    sideEffects.setChangesInstanceProperty();
    // Be conservative and make HArrayFlagsSet be a memory fence:
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
  }

  HInstruction get array => inputs[0];
  HInstruction get flags => inputs[1];

  @override
  HInstruction get constrainedInput => array;

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitArrayFlagsSet(this);

  @override
  bool isJsStatement() => true;
}

class HIsLateSentinel extends HInstruction {
  HIsLateSentinel(super.value, super.type) : super._1() {
    setUseGvn();
  }

  @override
  R accept<R>(HVisitor<R> visitor) => visitor.visitIsLateSentinel(this);

  @override
  _GvnType get _gvnType => _GvnType.isLateSentinel;

  @override
  bool typeEquals(HInstruction other) => other is HIsLateSentinel;

  @override
  bool dataEquals(HIsLateSentinel other) => true;

  @override
  String toString() => 'HIsLateSentinel()';
}
