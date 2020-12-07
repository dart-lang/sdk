// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/dart2js.dart' show Link;

import '../closure.dart';
import '../common.dart';
import '../common_elements.dart';
import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js_backend/specialized_checks.dart' show IsTestSpecialization;
import '../js_model/type_recipe.dart'
    show TypeEnvironmentStructure, TypeRecipe, TypeExpressionRecipe;
import '../native/behavior.dart';
import '../options.dart';
import '../universe/selector.dart' show Selector;
import '../universe/side_effects.dart' show SideEffects;
import '../util/util.dart';
import '../world.dart' show JClosedWorld;
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
}

abstract class HGraphVisitor {
  visitDominatorTree(HGraph graph) {
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

    _Frame frame = new _Frame(null);
    frame.block = graph.entry;
    frame.index = 0;

    visitBasicBlock(frame.block);

    while (frame != null) {
      HBasicBlock block = frame.block;
      int index = frame.index;
      if (index < block.dominatedBlocks.length) {
        frame.index = index + 1;
        frame = frame.next ??= new _Frame(frame);
        frame.block = block.dominatedBlocks[index];
        frame.index = 0;
        visitBasicBlock(frame.block);
        continue;
      }
      frame = frame.previous;
    }
  }

  visitPostDominatorTree(HGraph graph) {
    // Recusion free version of:
    //
    //     void visitBasicBlockAndSuccessors(HBasicBlock block) {
    //       List dominated = block.dominatedBlocks;
    //       for (int i = dominated.length - 1; i >= 0; i--) {
    //         visitBasicBlockAndSuccessors(dominated[i]);
    //       }
    //       visitBasicBlock(block);
    //     }
    //     visitBasicBlockAndSuccessors(graph.entry);

    _Frame frame = new _Frame(null);
    frame.block = graph.entry;
    frame.index = frame.block.dominatedBlocks.length;

    while (frame != null) {
      HBasicBlock block = frame.block;
      int index = frame.index;
      if (index > 0) {
        frame.index = index - 1;
        frame = frame.next ??= new _Frame(frame);
        frame.block = block.dominatedBlocks[index - 1];
        frame.index = frame.block.dominatedBlocks.length;
        continue;
      }
      visitBasicBlock(block);
      frame = frame.previous;
    }
  }

  visitBasicBlock(HBasicBlock block);
}

class _Frame {
  final _Frame previous;
  _Frame next;
  HBasicBlock block;
  int index;
  _Frame(this.previous);
}

abstract class HInstructionVisitor extends HGraphVisitor {
  HBasicBlock currentBlock;

  visitInstruction(HInstruction node);

  @override
  visitBasicBlock(HBasicBlock node) {
    void visitInstructionList(HInstructionList list) {
      HInstruction instruction = list.first;
      while (instruction != null) {
        visitInstruction(instruction);
        instruction = instruction.next;
        assert(instruction != list.first);
      }
    }

    currentBlock = node;
    visitInstructionList(node);
  }
}

class HGraph {
  MemberEntity element; // Used for debug printing.
  HBasicBlock entry;
  HBasicBlock exit;
  HThis thisInstruction;

  /// `true` if this graph should be transformed by a sync*/async/async*
  /// rewrite.
  bool needsAsyncRewrite = false;

  /// If this function requires an async rewrite, this is the element type of
  /// the generator.
  DartType asyncElementType;

  /// Receiver parameter, set for methods using interceptor calling convention.
  HParameterValue explicitReceiverParameter;
  bool isRecursiveMethod = false;
  bool calledInLoop = false;
  bool isLazyInitializer = false;

  final List<HBasicBlock> blocks = <HBasicBlock>[];

  /// Nodes containing list allocations for which there is a known fixed length.
  // TODO(sigmund,sra): consider not storing this explicitly here (e.g. maybe
  // store it on HInstruction, or maybe this can be computed on demand).
  final Set<HInstruction> allocatedFixedLists = new Set<HInstruction>();

  SourceInformation sourceInformation;

  // We canonicalize all constants used within a graph so we do not
  // have to worry about them for global value numbering.
  Map<ConstantValue, HConstant> constants = new Map<ConstantValue, HConstant>();

  HGraph() {
    entry = addNewBlock();
    // The exit block will be added later, so it has an id that is
    // after all others in the system.
    exit = new HBasicBlock();
  }

  void addBlock(HBasicBlock block) {
    int id = blocks.length;
    block.id = id;
    blocks.add(block);
    assert(identical(blocks[id], block));
  }

  HBasicBlock addNewBlock() {
    HBasicBlock result = new HBasicBlock();
    addBlock(result);
    return result;
  }

  HBasicBlock addNewLoopHeaderBlock(
      JumpTarget target, List<LabelDefinition> labels) {
    HBasicBlock result = addNewBlock();
    result.loopInformation = new HLoopInformation(result, target, labels);
    return result;
  }

  HConstant addConstant(ConstantValue constant, JClosedWorld closedWorld,
      {SourceInformation sourceInformation}) {
    HConstant result = constants[constant];
    // TODO(johnniwinther): Support source information per constant reference.
    if (result == null) {
      if (!constant.isConstant) {
        // We use `null` as the value for invalid constant expressions.
        constant = const NullConstantValue();
      }
      AbstractValue type = closedWorld.abstractValueDomain
          .computeAbstractValueForConstant(constant);
      result = new HConstant.internal(constant, type)
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
      SourceInformation sourceInformation, JClosedWorld closedWorld) {
    return addConstant(constant, closedWorld,
        sourceInformation: sourceInformation);
  }

  HConstant addConstantInt(int i, JClosedWorld closedWorld) {
    return addConstant(constant_system.createIntFromInt(i), closedWorld);
  }

  HConstant addConstantIntAsUnsigned(int i, JClosedWorld closedWorld) {
    return addConstant(
        constant_system.createInt(new BigInt.from(i).toUnsigned(64)),
        closedWorld);
  }

  HConstant addConstantDouble(double d, JClosedWorld closedWorld) {
    return addConstant(constant_system.createDouble(d), closedWorld);
  }

  HConstant addConstantString(String str, JClosedWorld closedWorld) {
    return addConstant(constant_system.createString(str), closedWorld);
  }

  HConstant addConstantStringFromName(js.Name name, JClosedWorld closedWorld) {
    return addConstant(
        new JsNameConstantValue(js.quoteName(name)), closedWorld);
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

  void finalize(AbstractValueDomain domain) {
    addBlock(exit);
    exit.open();
    exit.close(new HExit(domain));
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
    _Frame frame = new _Frame(null);
    frame.block = entry;
    frame.index = 0;

    int dfsNumber = 0;
    frame.block.dominatorDfsIn = dfsNumber;

    while (frame != null) {
      HBasicBlock block = frame.block;
      int index = frame.index;
      if (index < block.dominatedBlocks.length) {
        frame.index = index + 1;
        frame = frame.next ??= new _Frame(frame);
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
    HValidator validator = new HValidator();
    validator.visitGraph(this);
    return validator.isValid;
  }

  @override
  toString() => 'HGraph($element)';
}

class HBaseVisitor extends HGraphVisitor implements HVisitor {
  HBasicBlock currentBlock;

  @override
  visitBasicBlock(HBasicBlock node) {
    currentBlock = node;

    HInstruction instruction = node.first;
    while (instruction != null) {
      instruction.accept(this);
      instruction = instruction.next;
    }
  }

  visitInstruction(HInstruction instruction) {}

  visitBinaryArithmetic(HBinaryArithmetic node) => visitInvokeBinary(node);
  visitBinaryBitOp(HBinaryBitOp node) => visitInvokeBinary(node);
  visitInvoke(HInvoke node) => visitInstruction(node);
  visitInvokeBinary(HInvokeBinary node) => visitInstruction(node);
  visitInvokeDynamic(HInvokeDynamic node) => visitInvoke(node);
  visitInvokeDynamicField(HInvokeDynamicField node) => visitInvokeDynamic(node);
  visitInvokeUnary(HInvokeUnary node) => visitInstruction(node);
  visitConditionalBranch(HConditionalBranch node) => visitControlFlow(node);
  visitControlFlow(HControlFlow node) => visitInstruction(node);
  visitFieldAccess(HFieldAccess node) => visitInstruction(node);
  visitRelational(HRelational node) => visitInvokeBinary(node);

  @override
  visitAbs(HAbs node) => visitInvokeUnary(node);
  @override
  visitAdd(HAdd node) => visitBinaryArithmetic(node);
  @override
  visitBitAnd(HBitAnd node) => visitBinaryBitOp(node);
  @override
  visitBitNot(HBitNot node) => visitInvokeUnary(node);
  @override
  visitBitOr(HBitOr node) => visitBinaryBitOp(node);
  @override
  visitBitXor(HBitXor node) => visitBinaryBitOp(node);
  @override
  visitBoundsCheck(HBoundsCheck node) => visitCheck(node);
  @override
  visitBreak(HBreak node) => visitJump(node);
  @override
  visitContinue(HContinue node) => visitJump(node);
  visitCheck(HCheck node) => visitInstruction(node);
  @override
  visitConstant(HConstant node) => visitInstruction(node);
  @override
  visitCreate(HCreate node) => visitInstruction(node);
  @override
  visitCreateBox(HCreateBox node) => visitInstruction(node);
  @override
  visitDivide(HDivide node) => visitBinaryArithmetic(node);
  @override
  visitExit(HExit node) => visitControlFlow(node);
  @override
  visitExitTry(HExitTry node) => visitControlFlow(node);
  @override
  visitFieldGet(HFieldGet node) => visitFieldAccess(node);
  @override
  visitFieldSet(HFieldSet node) => visitFieldAccess(node);
  @override
  visitFunctionReference(HFunctionReference node) => visitInstruction(node);
  @override
  visitInvokeExternal(HInvokeExternal node) => visitInstruction(node);
  @override
  visitForeignCode(HForeignCode node) => visitInstruction(node);
  @override
  visitGetLength(HGetLength node) => visitInstruction(node);
  @override
  visitGoto(HGoto node) => visitControlFlow(node);
  @override
  visitGreater(HGreater node) => visitRelational(node);
  @override
  visitGreaterEqual(HGreaterEqual node) => visitRelational(node);
  @override
  visitIdentity(HIdentity node) => visitRelational(node);
  @override
  visitIf(HIf node) => visitConditionalBranch(node);
  @override
  visitIndex(HIndex node) => visitInstruction(node);
  @override
  visitIndexAssign(HIndexAssign node) => visitInstruction(node);
  @override
  visitInterceptor(HInterceptor node) => visitInstruction(node);
  @override
  visitInvokeClosure(HInvokeClosure node) => visitInvokeDynamic(node);
  @override
  visitInvokeConstructorBody(HInvokeConstructorBody node) =>
      visitInvokeStatic(node);
  @override
  visitInvokeGeneratorBody(HInvokeGeneratorBody node) =>
      visitInvokeStatic(node);
  @override
  visitInvokeDynamicMethod(HInvokeDynamicMethod node) =>
      visitInvokeDynamic(node);
  @override
  visitInvokeDynamicGetter(HInvokeDynamicGetter node) =>
      visitInvokeDynamicField(node);
  @override
  visitInvokeDynamicSetter(HInvokeDynamicSetter node) =>
      visitInvokeDynamicField(node);
  @override
  visitInvokeStatic(HInvokeStatic node) => visitInvoke(node);
  @override
  visitInvokeSuper(HInvokeSuper node) => visitInvokeStatic(node);
  visitJump(HJump node) => visitControlFlow(node);
  @override
  visitLazyStatic(HLazyStatic node) => visitInstruction(node);
  @override
  visitLess(HLess node) => visitRelational(node);
  @override
  visitLessEqual(HLessEqual node) => visitRelational(node);
  @override
  visitLiteralList(HLiteralList node) => visitInstruction(node);
  visitLocalAccess(HLocalAccess node) => visitInstruction(node);
  @override
  visitLocalGet(HLocalGet node) => visitLocalAccess(node);
  @override
  visitLocalSet(HLocalSet node) => visitLocalAccess(node);
  @override
  visitLocalValue(HLocalValue node) => visitInstruction(node);
  @override
  visitLoopBranch(HLoopBranch node) => visitConditionalBranch(node);
  @override
  visitNegate(HNegate node) => visitInvokeUnary(node);
  @override
  visitNot(HNot node) => visitInstruction(node);
  @override
  visitOneShotInterceptor(HOneShotInterceptor node) => visitInvokeDynamic(node);
  @override
  visitPhi(HPhi node) => visitInstruction(node);
  @override
  visitMultiply(HMultiply node) => visitBinaryArithmetic(node);
  @override
  visitParameterValue(HParameterValue node) => visitLocalValue(node);
  @override
  visitRangeConversion(HRangeConversion node) => visitCheck(node);
  @override
  visitReadModifyWrite(HReadModifyWrite node) => visitInstruction(node);
  @override
  visitRef(HRef node) => node.value.accept(this);
  @override
  visitRemainder(HRemainder node) => visitBinaryArithmetic(node);
  @override
  visitReturn(HReturn node) => visitControlFlow(node);
  @override
  visitShiftLeft(HShiftLeft node) => visitBinaryBitOp(node);
  @override
  visitShiftRight(HShiftRight node) => visitBinaryBitOp(node);
  @override
  visitSubtract(HSubtract node) => visitBinaryArithmetic(node);
  @override
  visitSwitch(HSwitch node) => visitControlFlow(node);
  @override
  visitStatic(HStatic node) => visitInstruction(node);
  @override
  visitStaticStore(HStaticStore node) => visitInstruction(node);
  @override
  visitStringConcat(HStringConcat node) => visitInstruction(node);
  @override
  visitStringify(HStringify node) => visitInstruction(node);
  @override
  visitThis(HThis node) => visitParameterValue(node);
  @override
  visitThrow(HThrow node) => visitControlFlow(node);
  @override
  visitThrowExpression(HThrowExpression node) => visitInstruction(node);
  @override
  visitTruncatingDivide(HTruncatingDivide node) => visitBinaryArithmetic(node);
  @override
  visitTry(HTry node) => visitControlFlow(node);
  @override
  visitLateValue(HLateValue node) => visitInstruction(node);
  @override
  visitBoolConversion(HBoolConversion node) => visitCheck(node);
  @override
  visitNullCheck(HNullCheck node) => visitCheck(node);
  @override
  visitPrimitiveCheck(HPrimitiveCheck node) => visitCheck(node);
  @override
  visitTypeKnown(HTypeKnown node) => visitCheck(node);
  @override
  visitAwait(HAwait node) => visitInstruction(node);
  @override
  visitYield(HYield node) => visitInstruction(node);

  @override
  visitIsTest(HIsTest node) => visitInstruction(node);
  @override
  visitIsTestSimple(HIsTestSimple node) => visitInstruction(node);
  @override
  visitAsCheck(HAsCheck node) => visitCheck(node);
  @override
  visitAsCheckSimple(HAsCheckSimple node) => visitCheck(node);
  @override
  visitSubtypeCheck(HSubtypeCheck node) => visitCheck(node);
  @override
  visitLoadType(HLoadType node) => visitInstruction(node);
  @override
  visitInstanceEnvironment(HInstanceEnvironment node) => visitInstruction(node);
  @override
  visitTypeEval(HTypeEval node) => visitInstruction(node);
  @override
  visitTypeBind(HTypeBind node) => visitInstruction(node);
}

class SubGraph {
  // The first and last block of the sub-graph.
  final HBasicBlock start;
  final HBasicBlock end;

  const SubGraph(this.start, this.end);

  bool contains(HBasicBlock block) {
    assert(start != null);
    assert(end != null);
    assert(block != null);
    return start.id <= block.id && block.id <= end.id;
  }
}

class SubExpression extends SubGraph {
  const SubExpression(HBasicBlock start, HBasicBlock end) : super(start, end);

  /// Find the condition expression if this sub-expression is a condition.
  HInstruction get conditionExpression {
    HInstruction last = end.last;
    if (last is HConditionalBranch || last is HSwitch) return last.inputs[0];
    return null;
  }
}

class HInstructionList {
  HInstruction first = null;
  HInstruction last = null;

  bool get isEmpty {
    return first == null;
  }

  void internalAddAfter(HInstruction cursor, HInstruction instruction) {
    if (cursor == null) {
      assert(isEmpty);
      first = last = instruction;
    } else if (identical(cursor, last)) {
      last.next = instruction;
      instruction.previous = last;
      last = instruction;
    } else {
      instruction.previous = cursor;
      instruction.next = cursor.next;
      cursor.next.previous = instruction;
      cursor.next = instruction;
    }
  }

  void internalAddBefore(HInstruction cursor, HInstruction instruction) {
    if (cursor == null) {
      assert(isEmpty);
      first = last = instruction;
    } else if (identical(cursor, first)) {
      first.previous = instruction;
      instruction.next = first;
      first = instruction;
    } else {
      instruction.next = cursor;
      instruction.previous = cursor.previous;
      cursor.previous.next = instruction;
      cursor.previous = instruction;
    }
  }

  void detach(HInstruction instruction) {
    assert(_truncatedContainsForAssert(instruction));
    assert(instruction.isInBasicBlock());
    if (instruction.previous == null) {
      first = instruction.next;
    } else {
      instruction.previous.next = instruction.next;
    }
    if (instruction.next == null) {
      last = instruction.previous;
    } else {
      instruction.next.previous = instruction.previous;
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
    HInstruction cursor = first;
    while (cursor != null) {
      if (identical(cursor, instruction)) return true;
      cursor = cursor.next;
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
    HInstruction cursor = first;
    int count = 0;
    while (cursor != null) {
      count++;
      if (count > 100) return true;
      if (identical(cursor, instruction)) return true;
      cursor = cursor.next;
    }

    return false;
  }
}

class HBasicBlock extends HInstructionList {
  // The [id] must be such that any successor's id is greater than
  // this [id]. The exception are back-edges.
  int id;

  static const int STATUS_NEW = 0;
  static const int STATUS_OPEN = 1;
  static const int STATUS_CLOSED = 2;
  int status = STATUS_NEW;

  HInstructionList phis;

  HLoopInformation loopInformation = null;
  HBlockFlow blockFlow = null;
  HBasicBlock parentLoopHeader = null;
  bool isLive = true;

  final List<HBasicBlock> predecessors;
  List<HBasicBlock> successors;

  HBasicBlock dominator = null;
  final List<HBasicBlock> dominatedBlocks;
  int dominatorDfsIn;
  int dominatorDfsOut;

  HBasicBlock() : this.withId(null);
  HBasicBlock.withId(this.id)
      : phis = new HInstructionList(),
        predecessors = <HBasicBlock>[],
        successors = const <HBasicBlock>[],
        dominatedBlocks = <HBasicBlock>[];

  @override
  int get hashCode => id;

  bool isNew() => status == STATUS_NEW;
  bool isOpen() => status == STATUS_OPEN;
  bool isClosed() => status == STATUS_CLOSED;

  bool isLoopHeader() {
    return loopInformation != null;
  }

  void setBlockFlow(HBlockInformation blockInfo, HBasicBlock continuation) {
    blockFlow = new HBlockFlow(blockInfo, continuation);
  }

  bool isLabeledBlock() =>
      blockFlow != null && blockFlow.body is HLabeledBlockInformation;

  HBasicBlock get enclosingLoopHeader {
    if (isLoopHeader()) return this;
    return parentLoopHeader;
  }

  void open() {
    assert(isNew());
    status = STATUS_OPEN;
  }

  void close(HControlFlow end) {
    assert(isOpen());
    addAfter(last, end);
    status = STATUS_CLOSED;
  }

  void addAtEntry(HInstruction instruction) {
    assert(instruction is! HPhi);
    internalAddBefore(first, instruction);
    instruction.notifyAddedToBlock(this);
  }

  void addAtExit(HInstruction instruction) {
    assert(isClosed());
    assert(last is HControlFlow);
    assert(instruction is! HPhi);
    internalAddBefore(last, instruction);
    instruction.notifyAddedToBlock(this);
  }

  void moveAtExit(HInstruction instruction) {
    assert(instruction is! HPhi);
    assert(instruction.isInBasicBlock());
    assert(isClosed());
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

  void addAfter(HInstruction cursor, HInstruction instruction) {
    assert(cursor is! HPhi);
    assert(instruction is! HPhi);
    assert(isOpen() || isClosed());
    internalAddAfter(cursor, instruction);
    instruction.notifyAddedToBlock(this);
  }

  void addBefore(HInstruction cursor, HInstruction instruction) {
    assert(cursor is! HPhi);
    assert(instruction is! HPhi);
    assert(isOpen() || isClosed());
    internalAddBefore(cursor, instruction);
    instruction.notifyAddedToBlock(this);
  }

  @override
  void remove(HInstruction instruction) {
    assert(isOpen() || isClosed());
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
      loopInformation.addBackEdge(predecessors[i]);
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
  void rewriteWithBetterUser(HInstruction from, HInstruction to) {
    // BUG(11841): Turn this method into a phase to be run after GVN phases.
    Link<HCheck> better = const Link<HCheck>();
    for (HInstruction user in to.usedBy) {
      if (user == from || user is! HCheck) continue;
      HCheck check = user;
      if (check.checkedInput == to) {
        better = better.prepend(user);
      }
    }

    if (better.isEmpty) return rewrite(from, to);

    L1:
    for (HInstruction user in from.usedBy) {
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
    assert(isClosed());
    assert(id != null && block.id != null);
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
    assert(isClosed());
    assert(id != null && block.id != null);
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
    assert(isClosed());
    if (dominator == null) {
      // If this basic block doesn't have a dominator yet we use the
      // given predecessor as the dominator.
      predecessor.addDominatedBlock(this);
    } else if (predecessor.dominator != null) {
      // If the predecessor has a dominator and this basic block has a
      // dominator, we find a common parent in the dominator tree and
      // use that as the dominator.
      HBasicBlock block0 = dominator;
      HBasicBlock block1 = predecessor;
      while (!identical(block0, block1)) {
        if (block0.id > block1.id) {
          block0 = block0.dominator;
        } else {
          block1 = block1.dominator;
        }
        assert(block0 != null && block1 != null);
      }
      if (!identical(dominator, block0)) {
        dominator.removeDominatedBlock(this);
        block0.addDominatedBlock(this);
      }
    }
  }

  void forEachPhi(void f(HPhi phi)) {
    HPhi current = phis.first;
    while (current != null) {
      HInstruction saved = current.next;
      f(current);
      current = saved;
    }
  }

  void forEachInstruction(void f(HInstruction instruction)) {
    HInstruction current = first;
    while (current != null) {
      HInstruction saved = current.next;
      f(current);
      current = saved;
    }
  }

  bool isValid() {
    assert(isClosed());
    HValidator validator = new HValidator();
    validator.visitBasicBlock(this);
    return validator.isValid;
  }

  bool dominates(HBasicBlock other) {
    return this.dominatorDfsIn <= other.dominatorDfsIn &&
        other.dominatorDfsOut <= this.dominatorDfsOut;
  }

  @override
  toString() => 'HBasicBlock($id)';
}

abstract class HInstruction implements Spannable {
  Entity sourceElement;
  SourceInformation sourceInformation;

  final int id = idCounter++;
  static int idCounter;

  final List<HInstruction> inputs;
  final List<HInstruction> usedBy = [];

  HBasicBlock block;
  HInstruction previous = null;
  HInstruction next = null;

  SideEffects sideEffects = new SideEffects.empty();
  bool _useGvn = false;

  // Type codes.
  static const int UNDEFINED_TYPECODE = -1;
  static const int TYPE_GUARD_TYPECODE = 1;
  static const int BOUNDS_CHECK_TYPECODE = 2;
  static const int INTEGER_CHECK_TYPECODE = 3;
  static const int INTERCEPTOR_TYPECODE = 4;
  static const int ADD_TYPECODE = 5;
  static const int DIVIDE_TYPECODE = 6;
  static const int MULTIPLY_TYPECODE = 7;
  static const int SUBTRACT_TYPECODE = 8;
  static const int SHIFT_LEFT_TYPECODE = 9;
  static const int BIT_OR_TYPECODE = 10;
  static const int BIT_AND_TYPECODE = 11;
  static const int BIT_XOR_TYPECODE = 12;
  static const int NEGATE_TYPECODE = 13;
  static const int BIT_NOT_TYPECODE = 14;
  static const int NOT_TYPECODE = 15;
  static const int IDENTITY_TYPECODE = 16;
  static const int GREATER_TYPECODE = 17;
  static const int GREATER_EQUAL_TYPECODE = 18;
  static const int LESS_TYPECODE = 19;
  static const int LESS_EQUAL_TYPECODE = 20;
  static const int STATIC_TYPECODE = 21;
  static const int STATIC_STORE_TYPECODE = 22;
  static const int FIELD_GET_TYPECODE = 23;
  static const int FUNCTION_REFERENCE_TYPECODE = 24;
  static const int TYPE_KNOWN_TYPECODE = 26;
  static const int INVOKE_STATIC_TYPECODE = 27;
  static const int INDEX_TYPECODE = 28;
  static const int INVOKE_DYNAMIC_TYPECODE = 29;
  static const int SHIFT_RIGHT_TYPECODE = 30;

  static const int TRUNCATING_DIVIDE_TYPECODE = 36;

  static const int INVOKE_EXTERNAL_TYPECODE = 41;
  static const int FOREIGN_CODE_TYPECODE = 42;
  static const int REMAINDER_TYPECODE = 43;
  static const int GET_LENGTH_TYPECODE = 44;
  static const int ABS_TYPECODE = 45;
  static const int BOOL_CONVERSION_TYPECODE = 46;
  static const int NULL_CHECK_TYPECODE = 47;
  static const int PRIMITIVE_CHECK_TYPECODE = 48;

  static const int IS_TEST_TYPECODE = 49;
  static const int IS_TEST_SIMPLE_TYPECODE = 50;
  static const int AS_CHECK_TYPECODE = 51;
  static const int AS_CHECK_SIMPLE_TYPECODE = 52;
  static const int SUBTYPE_CHECK_TYPECODE = 53;
  static const int LOAD_TYPE_TYPECODE = 54;
  static const int INSTANCE_ENVIRONMENT_TYPECODE = 55;
  static const int TYPE_EVAL_TYPECODE = 56;
  static const int TYPE_BIND_TYPECODE = 57;

  HInstruction(this.inputs, this.instructionType) {
    assert(inputs.every((e) => e != null), "inputs: $inputs");
  }

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

  AbstractBool isConflicting(AbstractValueDomain domain) =>
      domain.isEmpty(instructionType);

  AbstractBool isPrimitive(AbstractValueDomain domain) =>
      domain.isPrimitive(instructionType);

  AbstractBool isPrimitiveNumber(AbstractValueDomain domain) =>
      domain.isPrimitiveNumber(instructionType);

  AbstractBool isPrimitiveBoolean(AbstractValueDomain domain) =>
      domain.isPrimitiveBoolean(instructionType);

  AbstractBool isPrimitiveArray(AbstractValueDomain domain) =>
      domain.isPrimitiveArray(instructionType);

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

  AbstractBool isDouble(AbstractValueDomain domain) =>
      domain.isDouble(instructionType);

  AbstractBool isDoubleOrNull(AbstractValueDomain domain) =>
      domain.isDoubleOrNull(instructionType);

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

  /// Type of the instruction.
  AbstractValue instructionType;

  HInstruction getDartReceiver(JClosedWorld closedWorld) => null;
  bool onlyThrowsNSM() => false;

  bool isInBasicBlock() => block != null;

  bool gvnEquals(HInstruction other) {
    assert(useGvn() && other.useGvn());
    // Check that the type and the sideEffects match.
    bool hasSameType = typeEquals(other);
    assert(hasSameType == (typeCode() == other.typeCode()));
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
    int result = typeCode();
    int length = inputs.length;
    for (int i = 0; i < length; i++) {
      result = (result * 19) + (inputs[i].nonCheck().id) + (result >> 7);
    }
    return result;
  }

  // These methods should be overwritten by instructions that
  // participate in global value numbering.
  int typeCode() => HInstruction.UNDEFINED_TYPECODE;
  bool typeEquals(covariant HInstruction other) => false;
  bool dataEquals(covariant HInstruction other) => false;

  accept(HVisitor visitor);

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
  void rewriteInput(HInstruction from, HInstruction to) {
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

  // Change all uses of [oldInput] by [this] to [newInput]. Also
  // updates the [usedBy] of [oldInput] and [newInput].
  void changeUse(HInstruction oldInput, HInstruction newInput) {
    assert(newInput != null && !identical(oldInput, newInput));
    for (int i = 0; i < inputs.length; i++) {
      if (identical(inputs[i], oldInput)) {
        inputs[i] = newInput;
        newInput.usedBy.add(this);
      }
    }
    removeFromList(oldInput.usedBy, this);
  }

  void replaceAllUsersDominatedBy(
      HInstruction cursor, HInstruction newInstruction) {
    DominatedUses.of(this, cursor).replaceWith(newInstruction);
  }

  void moveBefore(HInstruction other) {
    assert(this is! HControlFlow);
    assert(this is! HPhi);
    assert(other is! HPhi);
    block.detach(this);
    other.block.internalAddBefore(other, this);
    block = other.block;
  }

  bool isConstant() => false;
  bool isConstantBoolean() => false;
  bool isConstantNull() => false;
  bool isConstantNumber() => false;
  bool isConstantInteger() => false;
  bool isConstantString() => false;
  bool isConstantList() => false;
  bool isConstantMap() => false;
  bool isConstantFalse() => false;
  bool isConstantTrue() => false;

  bool isInterceptor(JClosedWorld closedWorld) => false;

  bool isValid() {
    HValidator validator = new HValidator();
    validator.currentBlock = block;
    validator.visitInstruction(this);
    return validator.isValid;
  }

  bool isCodeMotionInvariant() => false;

  bool isJsStatement() => false;

  bool dominates(HInstruction other) {
    // An instruction does not dominates itself.
    if (this == other) return false;
    if (block != other.block) return block.dominates(other.block);

    HInstruction current = this.next;
    while (current != null) {
      if (current == other) return true;
      current = current.next;
    }
    return false;
  }

  /// Return whether the instructions do not belong to a loop or
  /// belong to the same loop.
  bool hasSameLoopHeaderAs(HInstruction other) {
    return block.enclosingLoopHeader == other.block.enclosingLoopHeader;
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
  MemberEntity instructionContext;
}

/// The set of uses of [source] that are dominated by [dominator].
class DominatedUses {
  final HInstruction _source;

  // Two list of matching length holding (instruction, input-index) pairs for
  // the dominated uses.
  final List<HInstruction> _instructions = <HInstruction>[];
  final List<int> _indexes = <int>[];

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
      {bool excludeDominator: false, bool excludePhiOutEdges: false}) {
    return new DominatedUses._(source)
      .._compute(source, dominator, excludeDominator, excludePhiOutEdges);
  }

  bool get isEmpty => _instructions.isEmpty;
  bool get isNotEmpty => !isEmpty;
  int get length => _instructions.length;

  /// Changes all the uses in the set to [newInstruction].
  void replaceWith(HInstruction newInstruction) {
    assert(!identical(newInstruction, _source));
    if (isEmpty) return;
    for (int i = 0; i < _instructions.length; i++) {
      HInstruction user = _instructions[i];
      int index = _indexes[i];
      HInstruction oldInstruction = user.inputs[index];
      assert(
          identical(oldInstruction, _source),
          'Input ${index} of ${user} changed.'
          '\n  Found: ${oldInstruction}\n  Expected: ${_source}');
      user.inputs[index] = newInstruction;
      oldInstruction.usedBy.remove(user);
      newInstruction.usedBy.add(user);
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
    // Keep track of all instructions that we have to deal with later and count
    // the number of them that are in the current block.
    Set<HInstruction> users = new Setlet<HInstruction>();
    Set<HInstruction> seen = new Setlet<HInstruction>();
    int usersInCurrentBlock = 0;

    HBasicBlock dominatorBlock = dominator.block;

    // Run through all the users and see if they are dominated, or potentially
    // dominated, or partially dominated by [dominator]. It is easier to
    // de-duplicate [usedBy] and process all inputs of an instruction than to
    // track the repeated elements of usedBy and match them up by index.
    for (HInstruction current in source.usedBy) {
      if (!seen.add(current)) continue;
      HBasicBlock currentBlock = current.block;
      if (dominatorBlock.dominates(currentBlock)) {
        users.add(current);
        if (identical(currentBlock, dominatorBlock)) usersInCurrentBlock++;
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

    // Run through all the phis in the same block as [dominator] and remove them
    // from the users set. These come before [dominator].
    // TODO(sra): Could we simply not add them in the first place?
    if (usersInCurrentBlock > 0) {
      for (HPhi phi = dominatorBlock.phis.first; phi != null; phi = phi.next) {
        if (users.remove(phi)) {
          if (--usersInCurrentBlock == 0) break;
        }
      }
    }

    // Run through all the instructions before [dominator] and remove them from
    // the users set.
    if (usersInCurrentBlock > 0) {
      HInstruction current = dominatorBlock.first;
      while (!identical(current, dominator)) {
        if (users.contains(current)) {
          // TODO(29302): Use 'user.remove(current)' as the condition.
          users.remove(current);
          if (--usersInCurrentBlock == 0) break;
        }
        current = current.next;
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
      : super([value], value.instructionType) {
    this.sourceInformation = sourceInformation;
  }

  HInstruction get value => inputs[0];

  @override
  accept(HVisitor visitor) => visitor.visitRef(this);

  @override
  String toString() => 'HRef(${value})';
}

/// Late instructions are used after the main optimization phases.  They capture
/// codegen decisions just prior to generating JavaScript.
abstract class HLateInstruction extends HInstruction {
  HLateInstruction(List<HInstruction> inputs, AbstractValue type)
      : super(inputs, type);
}

/// A [HCheck] instruction is an instruction that might do a dynamic check at
/// runtime on an input instruction. To have proper instruction dependencies in
/// the graph, instructions that depend on the check being done reference the
/// [HCheck] instruction instead of the input instruction.
abstract class HCheck extends HInstruction {
  HCheck(inputs, type) : super(inputs, type) {
    setUseGvn();
  }

  HInstruction get checkedInput => inputs[0];

  @override
  bool isJsStatement() => true;

  @override
  bool canThrow(AbstractValueDomain domain) => true;

  @override
  HInstruction nonCheck() => checkedInput.nonCheck();
}

class HBoundsCheck extends HCheck {
  static const int ALWAYS_FALSE = 0;
  static const int FULL_CHECK = 1;
  static const int ALWAYS_ABOVE_ZERO = 2;
  static const int ALWAYS_BELOW_LENGTH = 3;
  static const int ALWAYS_TRUE = 4;

  /// Details which tests have been done statically during compilation.
  /// Default is that all checks must be performed dynamically.
  int staticChecks = FULL_CHECK;

  HBoundsCheck(length, index, array, type)
      : super(<HInstruction>[length, index, array], type);

  HInstruction get length => inputs[1];
  HInstruction get index => inputs[0];
  HInstruction get array => inputs[2];
  // There can be an additional fourth input which is the index to report to
  // [ioore]. This is used by the expansion of [JSArray.removeLast].
  HInstruction get reportedIndex => inputs.length > 3 ? inputs[3] : index;
  @override
  bool isControlFlow() => true;

  @override
  accept(HVisitor visitor) => visitor.visitBoundsCheck(this);
  @override
  int typeCode() => HInstruction.BOUNDS_CHECK_TYPECODE;
  @override
  bool typeEquals(other) => other is HBoundsCheck;
  @override
  bool dataEquals(HInstruction other) => true;
}

abstract class HConditionalBranch extends HControlFlow {
  HConditionalBranch(AbstractValueDomain domain, List<HInstruction> inputs)
      : super(domain, inputs);
  HInstruction get condition => inputs[0];
  HBasicBlock get trueBranch => block.successors[0];
  HBasicBlock get falseBranch => block.successors[1];
}

abstract class HControlFlow extends HInstruction {
  HControlFlow(AbstractValueDomain domain, List<HInstruction> inputs)
      // TODO(johnniwinther): May only expression-like [HInstruction]s should
      // have an `instructionType`, or statement-like [HInstruction]s should
      // have a throwing getter.
      : super(inputs, domain.emptyType);
  @override
  bool isControlFlow() => true;
  @override
  bool isJsStatement() => true;
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
  List<InterfaceType> instantiatedTypes;

  /// If this node creates a closure class, [callMethod] is the call method of
  /// the closure class.
  FunctionEntity callMethod;

  HCreate(this.element, List<HInstruction> inputs, AbstractValue type,
      SourceInformation sourceInformation,
      {this.instantiatedTypes, this.hasRtiInput: false, this.callMethod})
      : super(inputs, type) {
    this.sourceInformation = sourceInformation;
  }

  @override
  bool isAllocation(AbstractValueDomain domain) => true;

  HInstruction get rtiInput {
    assert(hasRtiInput);
    return inputs.last;
  }

  @override
  accept(HVisitor visitor) => visitor.visitCreate(this);

  @override
  String toString() => 'HCreate($element, ${instantiatedTypes})';
}

// Allocates a box to hold mutated captured variables.
class HCreateBox extends HInstruction {
  HCreateBox(AbstractValue type) : super(<HInstruction>[], type);

  @override
  bool isAllocation(AbstractValueDomain domain) => true;

  @override
  accept(HVisitor visitor) => visitor.visitCreateBox(this);

  @override
  String toString() => 'HCreateBox()';
}

abstract class HInvoke extends HInstruction {
  bool _isAllocation = false;

  /// [isInterceptedCall] is true if this invocation uses the interceptor
  /// calling convention where the first input is the methods and the second
  /// input is the Dart receiver.
  bool isInterceptedCall = false;

  HInvoke(List<HInstruction> inputs, AbstractValue resultType)
      : super(inputs, resultType) {
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
  MemberEntity element;

  @override
  MemberEntity instructionContext;

  HInvokeDynamic(Selector selector, this._receiverType, this.element,
      List<HInstruction> inputs, bool isIntercepted, AbstractValue resultType)
      : this._selector = selector,
        this._originalReceiverType = _receiverType,
        specializer = isIntercepted
            ? InvokeDynamicSpecializer.lookupSpecializer(selector)
            : const InvokeDynamicSpecializer(),
        super(inputs, resultType) {
    assert(isIntercepted != null);
    assert(_receiverType != null);
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
  int typeCode() => HInstruction.INVOKE_DYNAMIC_TYPECODE;

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
    assert(selector.isClosureCall);
    assert(selector.callStructure.typeArgumentCount == typeArguments.length);
    assert(!isInterceptedCall);
  }
  @override
  accept(HVisitor visitor) => visitor.visitInvokeClosure(this);
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
      SourceInformation sourceInformation,
      {bool isIntercepted: false})
      : super(selector, receiverType, null, inputs, isIntercepted, resultType) {
    this.sourceInformation = sourceInformation;
    assert(selector.callStructure.typeArgumentCount == typeArguments.length);
  }

  @override
  String toString() =>
      'invoke dynamic method: selector=$selector, mask=$receiverType';
  @override
  accept(HVisitor visitor) => visitor.visitInvokeDynamicMethod(this);
}

abstract class HInvokeDynamicField extends HInvokeDynamic {
  HInvokeDynamicField(
      Selector selector,
      AbstractValue receiverType,
      MemberEntity element,
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
      MemberEntity element,
      List<HInstruction> inputs,
      bool isIntercepted,
      AbstractValue resultType,
      SourceInformation sourceInformation)
      : super(selector, receiverType, element, inputs, isIntercepted,
            resultType) {
    this.sourceInformation = sourceInformation;
  }

  @override
  accept(HVisitor visitor) => visitor.visitInvokeDynamicGetter(this);

  bool get isTearOff => element != null && element.isFunction;

  @override
  List<DartType> get typeArguments => const <DartType>[];

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
      MemberEntity element,
      List<HInstruction> inputs,
      bool isIntercepted,
      // TODO(johnniwinther): The result type for a setter should be the empty
      // type.
      AbstractValue resultType,
      SourceInformation sourceInformation)
      : super(selector, receiverType, element, inputs, isIntercepted,
            resultType) {
    this.sourceInformation = sourceInformation;
  }

  @override
  accept(HVisitor visitor) => visitor.visitInvokeDynamicSetter(this);

  @override
  List<DartType> get typeArguments => const <DartType>[];

  @override
  String toString() =>
      'invoke dynamic setter: selector=$selector, mask=$receiverType, element=$element';
}

class HInvokeStatic extends HInvoke {
  final MemberEntity element;

  /// The type arguments passed in this static invocation.
  final List<DartType> typeArguments;

  final bool targetCanThrow;

  @override
  bool canThrow(AbstractValueDomain domain) => targetCanThrow;

  /// If this instruction is a call to a constructor, [instantiatedTypes]
  /// contains the type(s) used in the (Dart) `New` expression(s). The
  /// [instructionType] of this node is not enough, because we also need the
  /// type arguments. See also [SsaFromAstMixin.currentInlinedInstantiations].
  List<InterfaceType> instantiatedTypes;

  /// The first input must be the target.
  HInvokeStatic(this.element, inputs, AbstractValue type, this.typeArguments,
      {this.targetCanThrow: true, bool isIntercepted: false})
      : super(inputs, type) {
    isInterceptedCall = isIntercepted;
  }

  @override
  accept(HVisitor visitor) => visitor.visitInvokeStatic(this);

  @override
  int typeCode() => HInstruction.INVOKE_STATIC_TYPECODE;

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
      SourceInformation sourceInformation,
      {this.isSetter})
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
  toString() => 'invoke super: $element';
  @override
  accept(HVisitor visitor) => visitor.visitInvokeSuper(this);

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
      SourceInformation sourceInformation)
      : super(element, inputs, type, const <DartType>[]) {
    this.sourceInformation = sourceInformation;
  }

  @override
  String toString() => 'invoke constructor body: ${element.name}';
  @override
  accept(HVisitor visitor) => visitor.visitInvokeConstructorBody(this);
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
      AbstractValue type, SourceInformation sourceInformation)
      : super(element, inputs, type, const <DartType>[]) {
    this.sourceInformation = sourceInformation;
  }

  @override
  String toString() => 'HInvokeGeneratorBody(${element.name})';
  @override
  accept(HVisitor visitor) => visitor.visitInvokeGeneratorBody(this);
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
      SourceInformation sourceInformation,
      {bool isAssignable})
      : this.isAssignable =
            (isAssignable != null) ? isAssignable : element.isAssignable,
        super(element, <HInstruction>[receiver], type) {
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
    if (sourceElement == null) return false;
    // In case of a closure inside an interceptor class, [:this:] is
    // stored in the generated closure class, and accessed through a
    // [HFieldGet].
    if (sourceElement is ThisLocal) {
      ThisLocal thisLocal = sourceElement;
      return closedWorld.interceptorData
          .isInterceptedClass(thisLocal.enclosingClass);
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
  accept(HVisitor visitor) => visitor.visitFieldGet(this);

  @override
  int typeCode() => HInstruction.FIELD_GET_TYPECODE;
  @override
  bool typeEquals(other) => other is HFieldGet;
  @override
  bool dataEquals(HFieldGet other) => element == other.element;
  @override
  String toString() => "FieldGet(element=$element,type=$instructionType)";
}

class HFieldSet extends HFieldAccess {
  HFieldSet(AbstractValueDomain domain, FieldEntity element,
      HInstruction receiver, HInstruction value)
      : super(element, <HInstruction>[receiver, value], domain.emptyType) {
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
  accept(HVisitor visitor) => visitor.visitFieldSet(this);

  // HFieldSet is an expression if it has a user.
  @override
  bool isJsStatement() => usedBy.isEmpty;

  @override
  String toString() => "FieldSet(element=$element,type=$instructionType)";
}

// Raw reference to a function.
class HFunctionReference extends HInstruction {
  FunctionEntity element;
  HFunctionReference(this.element, AbstractValue type) : super([], type) {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    setUseGvn();
  }

  @override
  accept(HVisitor visitor) => visitor.visitFunctionReference(this);

  @override
  int typeCode() => HInstruction.FUNCTION_REFERENCE_TYPECODE;
  @override
  bool typeEquals(other) => other is HFunctionReference;
  @override
  bool dataEquals(HFunctionReference other) => element == other.element;
  @override
  String toString() => "FunctionReference($element)";
}

class HGetLength extends HInstruction {
  final bool isAssignable;
  HGetLength(HInstruction receiver, AbstractValue type,
      {bool this.isAssignable})
      : super(<HInstruction>[receiver], type) {
    assert(isAssignable != null);
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
  accept(HVisitor visitor) => visitor.visitGetLength(this);

  @override
  int typeCode() => HInstruction.GET_LENGTH_TYPECODE;
  @override
  bool typeEquals(other) => other is HGetLength;
  @override
  bool dataEquals(HGetLength other) => true;
  @override
  String toString() => "GetLength()";
}

/// HReadModifyWrite is a late stage instruction for a field (property) update
/// via an assignment operation or pre- or post-increment.
class HReadModifyWrite extends HLateInstruction {
  static const ASSIGN_OP = 0;
  static const PRE_OP = 1;
  static const POST_OP = 2;
  final FieldEntity element;
  final String jsOp;
  final int opKind;

  HReadModifyWrite._(this.element, this.jsOp, this.opKind,
      List<HInstruction> inputs, AbstractValue type)
      : super(inputs, type) {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    sideEffects.setChangesInstanceProperty();
    sideEffects.setDependsOnInstancePropertyStore();
  }

  HReadModifyWrite.assignOp(FieldEntity element, String jsOp,
      HInstruction receiver, HInstruction operand, AbstractValue type)
      : this._(
            element, jsOp, ASSIGN_OP, <HInstruction>[receiver, operand], type);

  HReadModifyWrite.preOp(FieldEntity element, String jsOp,
      HInstruction receiver, AbstractValue type)
      : this._(element, jsOp, PRE_OP, <HInstruction>[receiver], type);

  HReadModifyWrite.postOp(FieldEntity element, String jsOp,
      HInstruction receiver, AbstractValue type)
      : this._(element, jsOp, POST_OP, <HInstruction>[receiver], type);

  HInstruction get receiver => inputs[0];

  bool get isPreOp => opKind == PRE_OP;
  bool get isPostOp => opKind == POST_OP;
  bool get isAssignOp => opKind == ASSIGN_OP;

  @override
  bool canThrow(AbstractValueDomain domain) =>
      receiver.isNull(domain).isPotentiallyTrue;

  @override
  HInstruction getDartReceiver(JClosedWorld closedWorld) => receiver;
  @override
  bool onlyThrowsNSM() => true;

  HInstruction get value => inputs[1];
  @override
  accept(HVisitor visitor) => visitor.visitReadModifyWrite(this);

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
      SourceInformation sourceInformation)
      : super(variable, <HInstruction>[local], type) {
    this.sourceInformation = sourceInformation;
  }

  @override
  accept(HVisitor visitor) => visitor.visitLocalGet(this);

  HLocalValue get local => inputs[0];

  @override
  String toString() => 'HLocalGet($local).$hashCode';
}

class HLocalSet extends HLocalAccess {
  HLocalSet(AbstractValueDomain domain, Local variable, HLocalValue local,
      HInstruction value)
      : super(variable, <HInstruction>[local, value], domain.emptyType);

  @override
  accept(HVisitor visitor) => visitor.visitLocalSet(this);

  HLocalValue get local => inputs[0];
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
/// Dart-calling-convention stub identifed by [element] that contains a call to
/// the external method, whereas a HInvokeExternal instruction is a direct
/// JavaScript call to the external method identified by [element].
class HInvokeExternal extends HInvoke {
  final FunctionEntity element;

  // The following fields are functions of [element] that are extracted for
  // convenience.
  final NativeBehavior nativeBehavior;
  final NativeThrowBehavior throwBehavior;

  HInvokeExternal(this.element, List<HInstruction> inputs, AbstractValue type,
      this.nativeBehavior,
      {SourceInformation sourceInformation})
      : throwBehavior =
            nativeBehavior?.throwBehavior ?? NativeThrowBehavior.MAY,
        super(inputs, type) {
    if (nativeBehavior == null) {
      sideEffects.setAllSideEffects();
      sideEffects.setDependsOnSomething();
    } else {
      sideEffects.add(nativeBehavior.sideEffects);
    }
    if (nativeBehavior != null && nativeBehavior.useGvn) {
      setUseGvn();
    }
    this.sourceInformation = sourceInformation;
  }

  @override
  accept(HVisitor visitor) => visitor.visitInvokeExternal(this);

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
      nativeBehavior.isAllocation &&
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
  int typeCode() => HInstruction.INVOKE_EXTERNAL_TYPECODE;
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
  NativeBehavior get nativeBehavior => null;

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
  final NativeBehavior nativeBehavior;
  NativeThrowBehavior throwBehavior;

  HForeignCode(this.codeTemplate, AbstractValue type, List<HInstruction> inputs,
      {this.isStatement: false,
      SideEffects effects,
      NativeBehavior nativeBehavior,
      NativeThrowBehavior throwBehavior})
      : this.nativeBehavior = nativeBehavior,
        this.throwBehavior = throwBehavior,
        super(type, inputs) {
    assert(codeTemplate != null);
    if (effects == null && nativeBehavior != null) {
      effects = nativeBehavior.sideEffects;
    }
    if (this.throwBehavior == null) {
      this.throwBehavior = (nativeBehavior == null)
          ? NativeThrowBehavior.MAY
          : nativeBehavior.throwBehavior;
    }
    assert(this.throwBehavior != null);

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
  accept(HVisitor visitor) => visitor.visitForeignCode(this);

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
      nativeBehavior.isAllocation &&
      isNull(domain).isDefinitelyFalse;

  /// Returns `true` if the template will throw an NoSuchMethod error if
  /// [receiver] is `null` before having any other side-effects.
  bool isNullGuardFor(HInstruction receiver) {
    if (!throwBehavior.isNullNSMGuard) return false;
    if (inputs.length < 1) return false;
    if (inputs.first.nonCheck() != receiver.nonCheck()) return false;
    return true;
  }

  @override
  int typeCode() => HInstruction.FOREIGN_CODE_TYPECODE;
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
  HInvokeBinary(HInstruction left, HInstruction right, AbstractValue type)
      : super(<HInstruction>[left, right], type) {
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
  accept(HVisitor visitor) => visitor.visitAdd(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.add;
  @override
  int typeCode() => HInstruction.ADD_TYPECODE;
  @override
  bool typeEquals(other) => other is HAdd;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HDivide extends HBinaryArithmetic {
  HDivide(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  accept(HVisitor visitor) => visitor.visitDivide(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.divide;
  @override
  int typeCode() => HInstruction.DIVIDE_TYPECODE;
  @override
  bool typeEquals(other) => other is HDivide;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HMultiply extends HBinaryArithmetic {
  HMultiply(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  accept(HVisitor visitor) => visitor.visitMultiply(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.multiply;
  @override
  int typeCode() => HInstruction.MULTIPLY_TYPECODE;
  @override
  bool typeEquals(other) => other is HMultiply;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HSubtract extends HBinaryArithmetic {
  HSubtract(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  accept(HVisitor visitor) => visitor.visitSubtract(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.subtract;
  @override
  int typeCode() => HInstruction.SUBTRACT_TYPECODE;
  @override
  bool typeEquals(other) => other is HSubtract;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HTruncatingDivide extends HBinaryArithmetic {
  HTruncatingDivide(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  accept(HVisitor visitor) => visitor.visitTruncatingDivide(this);

  @override
  constant_system.BinaryOperation operation() =>
      constant_system.truncatingDivide;
  @override
  int typeCode() => HInstruction.TRUNCATING_DIVIDE_TYPECODE;
  @override
  bool typeEquals(other) => other is HTruncatingDivide;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HRemainder extends HBinaryArithmetic {
  HRemainder(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  accept(HVisitor visitor) => visitor.visitRemainder(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.remainder;
  @override
  int typeCode() => HInstruction.REMAINDER_TYPECODE;
  @override
  bool typeEquals(other) => other is HRemainder;
  @override
  bool dataEquals(HInstruction other) => true;
}

/// An [HSwitch] instruction has one input for the incoming
/// value, and one input per constant that it can switch on.
/// Its block has one successor per constant, and one for the default.
class HSwitch extends HControlFlow {
  HSwitch(AbstractValueDomain domain, List<HInstruction> inputs)
      : super(domain, inputs);

  HConstant constant(int index) => inputs[index + 1];
  HInstruction get expression => inputs[0];

  /// Provides the target to jump to if none of the constants match
  /// the expression. If the switch had no default case, this is the
  /// following join-block.
  HBasicBlock get defaultTarget => block.successors.last;

  @override
  accept(HVisitor visitor) => visitor.visitSwitch(this);

  @override
  String toString() => "HSwitch cases = $inputs";
}

abstract class HBinaryBitOp extends HInvokeBinary {
  HBinaryBitOp(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
}

class HShiftLeft extends HBinaryBitOp {
  HShiftLeft(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  accept(HVisitor visitor) => visitor.visitShiftLeft(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.shiftLeft;
  @override
  int typeCode() => HInstruction.SHIFT_LEFT_TYPECODE;
  @override
  bool typeEquals(other) => other is HShiftLeft;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HShiftRight extends HBinaryBitOp {
  HShiftRight(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  accept(HVisitor visitor) => visitor.visitShiftRight(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.shiftRight;
  @override
  int typeCode() => HInstruction.SHIFT_RIGHT_TYPECODE;
  @override
  bool typeEquals(other) => other is HShiftRight;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HBitOr extends HBinaryBitOp {
  HBitOr(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  accept(HVisitor visitor) => visitor.visitBitOr(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.bitOr;
  @override
  int typeCode() => HInstruction.BIT_OR_TYPECODE;
  @override
  bool typeEquals(other) => other is HBitOr;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HBitAnd extends HBinaryBitOp {
  HBitAnd(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  accept(HVisitor visitor) => visitor.visitBitAnd(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.bitAnd;
  @override
  int typeCode() => HInstruction.BIT_AND_TYPECODE;
  @override
  bool typeEquals(other) => other is HBitAnd;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HBitXor extends HBinaryBitOp {
  HBitXor(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  accept(HVisitor visitor) => visitor.visitBitXor(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.bitXor;
  @override
  int typeCode() => HInstruction.BIT_XOR_TYPECODE;
  @override
  bool typeEquals(other) => other is HBitXor;
  @override
  bool dataEquals(HInstruction other) => true;
}

abstract class HInvokeUnary extends HInstruction {
  HInvokeUnary(HInstruction input, type) : super(<HInstruction>[input], type) {
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
  accept(HVisitor visitor) => visitor.visitNegate(this);

  @override
  constant_system.UnaryOperation operation() => constant_system.negate;
  @override
  int typeCode() => HInstruction.NEGATE_TYPECODE;
  @override
  bool typeEquals(other) => other is HNegate;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HAbs extends HInvokeUnary {
  HAbs(HInstruction input, AbstractValue type) : super(input, type);
  @override
  accept(HVisitor visitor) => visitor.visitAbs(this);

  @override
  constant_system.UnaryOperation operation() => constant_system.abs;
  @override
  int typeCode() => HInstruction.ABS_TYPECODE;
  @override
  bool typeEquals(other) => other is HAbs;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HBitNot extends HInvokeUnary {
  HBitNot(HInstruction input, AbstractValue type) : super(input, type);
  @override
  accept(HVisitor visitor) => visitor.visitBitNot(this);

  @override
  constant_system.UnaryOperation operation() => constant_system.bitNot;
  @override
  int typeCode() => HInstruction.BIT_NOT_TYPECODE;
  @override
  bool typeEquals(other) => other is HBitNot;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HExit extends HControlFlow {
  HExit(AbstractValueDomain domain) : super(domain, const <HInstruction>[]);
  @override
  toString() => 'exit';
  @override
  accept(HVisitor visitor) => visitor.visitExit(this);
}

class HGoto extends HControlFlow {
  HGoto(AbstractValueDomain domain) : super(domain, const <HInstruction>[]);
  @override
  toString() => 'goto';
  @override
  accept(HVisitor visitor) => visitor.visitGoto(this);
}

abstract class HJump extends HControlFlow {
  final JumpTarget target;
  final LabelDefinition label;
  HJump(AbstractValueDomain domain, this.target,
      SourceInformation sourceInformation)
      : label = null,
        super(domain, const <HInstruction>[]) {
    this.sourceInformation = sourceInformation;
  }
  HJump.toLabel(AbstractValueDomain domain, LabelDefinition label,
      SourceInformation sourceInformation)
      : label = label,
        target = label.target,
        super(domain, const <HInstruction>[]) {
    this.sourceInformation = sourceInformation;
  }
}

class HBreak extends HJump {
  /// Signals that this is a special break instruction for the synthetic loop
  /// generated for a switch statement with continue statements. See
  /// [SsaFromAstMixin.buildComplexSwitchStatement] for detail.
  final bool breakSwitchContinueLoop;

  HBreak(AbstractValueDomain domain, JumpTarget target,
      SourceInformation sourceInformation,
      {bool this.breakSwitchContinueLoop: false})
      : super(domain, target, sourceInformation);

  HBreak.toLabel(AbstractValueDomain domain, LabelDefinition label,
      SourceInformation sourceInformation)
      : breakSwitchContinueLoop = false,
        super.toLabel(domain, label, sourceInformation);

  @override
  String toString() => (label != null) ? 'break ${label.labelName}' : 'break';

  @override
  accept(HVisitor visitor) => visitor.visitBreak(this);
}

class HContinue extends HJump {
  HContinue(AbstractValueDomain domain, JumpTarget target,
      SourceInformation sourceInformation)
      : super(domain, target, sourceInformation);

  HContinue.toLabel(AbstractValueDomain domain, LabelDefinition label,
      SourceInformation sourceInformation)
      : super.toLabel(domain, label, sourceInformation);

  @override
  String toString() =>
      (label != null) ? 'continue ${label.labelName}' : 'continue';

  @override
  accept(HVisitor visitor) => visitor.visitContinue(this);
}

class HTry extends HControlFlow {
  HLocalValue exception;
  HBasicBlock catchBlock;
  HBasicBlock finallyBlock;
  HTry(AbstractValueDomain domain) : super(domain, const <HInstruction>[]);
  @override
  toString() => 'try';
  @override
  accept(HVisitor visitor) => visitor.visitTry(this);
  HBasicBlock get joinBlock => this.block.successors.last;
}

// An [HExitTry] control flow node is used when the body of a try or
// the body of a catch contains a return, break or continue. To build
// the control flow graph, we explicitly mark the body that
// leads to one of this instruction a predecessor of catch and
// finally.
class HExitTry extends HControlFlow {
  HExitTry(AbstractValueDomain domain) : super(domain, const <HInstruction>[]);
  @override
  toString() => 'exit try';
  @override
  accept(HVisitor visitor) => visitor.visitExitTry(this);
  HBasicBlock get bodyTrySuccessor => block.successors[0];
}

class HIf extends HConditionalBranch {
  HBlockFlow blockInformation = null;
  HIf(AbstractValueDomain domain, HInstruction condition)
      : super(domain, <HInstruction>[condition]);
  @override
  toString() => 'if';
  @override
  accept(HVisitor visitor) => visitor.visitIf(this);

  HBasicBlock get thenBlock {
    assert(identical(block.dominatedBlocks[0], block.successors[0]));
    return block.successors[0];
  }

  HBasicBlock get elseBlock {
    assert(identical(block.dominatedBlocks[1], block.successors[1]));
    return block.successors[1];
  }

  HBasicBlock get joinBlock => blockInformation.continuation;
}

class HLoopBranch extends HConditionalBranch {
  static const int CONDITION_FIRST_LOOP = 0;
  static const int DO_WHILE_LOOP = 1;

  final int kind;
  HLoopBranch(AbstractValueDomain domain, HInstruction condition,
      [this.kind = CONDITION_FIRST_LOOP])
      : super(domain, <HInstruction>[condition]);
  @override
  toString() => 'loop-branch';
  @override
  accept(HVisitor visitor) => visitor.visitLoopBranch(this);
}

class HConstant extends HInstruction {
  final ConstantValue constant;
  HConstant.internal(this.constant, AbstractValue constantType)
      : super(<HInstruction>[], constantType);

  @override
  toString() => 'literal: ${constant.toStructuredText(null)}';
  @override
  accept(HVisitor visitor) => visitor.visitConstant(this);

  @override
  bool isConstant() => true;
  @override
  bool isConstantBoolean() => constant.isBool;
  @override
  bool isConstantNull() => constant.isNull;
  @override
  bool isConstantNumber() => constant.isNum;
  @override
  bool isConstantInteger() => constant.isInt;
  @override
  bool isConstantString() => constant.isString;
  @override
  bool isConstantList() => constant.isList;
  @override
  bool isConstantMap() => constant.isMap;
  @override
  bool isConstantFalse() => constant.isFalse;
  @override
  bool isConstantTrue() => constant.isTrue;

  @override
  bool isInterceptor(JClosedWorld closedWorld) => constant.isInterceptor;

  // Maybe avoid this if the literal is big?
  @override
  bool isCodeMotionInvariant() => true;

  @override
  set instructionType(type) {
    // Only lists can be specialized. The SSA builder uses the
    // inferrer for finding the type of a constant list. We should
    // have the constant know its type instead.
    if (!isConstantList()) return;
    super.instructionType = type;
  }
}

class HNot extends HInstruction {
  HNot(HInstruction value, AbstractValue type)
      : super(<HInstruction>[value], type) {
    setUseGvn();
  }

  @override
  accept(HVisitor visitor) => visitor.visitNot(this);
  @override
  int typeCode() => HInstruction.NOT_TYPECODE;
  @override
  bool typeEquals(other) => other is HNot;
  @override
  bool dataEquals(HInstruction other) => true;
}

/// An [HLocalValue] represents a local. Unlike [HParameterValue]s its
/// first use must be in an HLocalSet. That is, [HParameterValue]s have a
/// value from the start, whereas [HLocalValue]s need to be initialized first.
class HLocalValue extends HInstruction {
  HLocalValue(Entity variable, AbstractValue type)
      : super(<HInstruction>[], type) {
    sourceElement = variable;
  }

  @override
  toString() => 'local ${sourceElement.name}';
  @override
  accept(HVisitor visitor) => visitor.visitLocalValue(this);
}

class HParameterValue extends HLocalValue {
  bool _potentiallyUsedAsVariable = true;

  HParameterValue(Entity variable, AbstractValue type) : super(variable, type);

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
  toString() => 'parameter ${sourceElement.name}';
  @override
  accept(HVisitor visitor) => visitor.visitParameterValue(this);
}

class HThis extends HParameterValue {
  HThis(ThisLocal element, AbstractValue type) : super(element, type);

  @override
  ThisLocal get sourceElement => super.sourceElement;

  @override
  void set sourceElement(covariant ThisLocal local) {
    super.sourceElement = local;
  }

  @override
  accept(HVisitor visitor) => visitor.visitThis(this);

  @override
  bool isCodeMotionInvariant() => true;

  @override
  bool isInterceptor(JClosedWorld closedWorld) {
    return closedWorld.interceptorData
        .isInterceptedClass(sourceElement.enclosingClass);
  }

  @override
  String toString() => 'this';
}

class HPhi extends HInstruction {
  static const IS_NOT_LOGICAL_OPERATOR = 0;
  static const IS_AND = 1;
  static const IS_OR = 2;

  int logicalOperatorType = IS_NOT_LOGICAL_OPERATOR;

  // The order of the [inputs] must correspond to the order of the
  // predecessor-edges. That is if an input comes from the first predecessor
  // of the surrounding block, then the input must be the first in the [HPhi].
  HPhi(Local variable, List<HInstruction> inputs, AbstractValue type)
      : super(inputs, type) {
    sourceElement = variable;
  }
  HPhi.noInputs(Local variable, AbstractValue type)
      : this(variable, <HInstruction>[], type);
  HPhi.singleInput(Local variable, HInstruction input, AbstractValue type)
      : this(variable, <HInstruction>[input], type);
  HPhi.manyInputs(Local variable, List<HInstruction> inputs, AbstractValue type)
      : this(variable, inputs, type);

  void addInput(HInstruction input) {
    assert(isInBasicBlock());
    inputs.add(input);
    assert(inputs.length <= block.predecessors.length);
    input.usedBy.add(this);
  }

  @override
  toString() => 'phi $id';
  @override
  accept(HVisitor visitor) => visitor.visitPhi(this);
}

abstract class HRelational extends HInvokeBinary {
  bool usesBoolifiedInterceptor = false;
  HRelational(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
}

class HIdentity extends HRelational {
  // Cached codegen decision.
  String singleComparisonOp; // null, '===', '=='

  HIdentity(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  accept(HVisitor visitor) => visitor.visitIdentity(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.identity;
  @override
  int typeCode() => HInstruction.IDENTITY_TYPECODE;
  @override
  bool typeEquals(other) => other is HIdentity;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HGreater extends HRelational {
  HGreater(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  accept(HVisitor visitor) => visitor.visitGreater(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.greater;
  @override
  int typeCode() => HInstruction.GREATER_TYPECODE;
  @override
  bool typeEquals(other) => other is HGreater;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HGreaterEqual extends HRelational {
  HGreaterEqual(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  accept(HVisitor visitor) => visitor.visitGreaterEqual(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.greaterEqual;
  @override
  int typeCode() => HInstruction.GREATER_EQUAL_TYPECODE;
  @override
  bool typeEquals(other) => other is HGreaterEqual;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HLess extends HRelational {
  HLess(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  accept(HVisitor visitor) => visitor.visitLess(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.less;
  @override
  int typeCode() => HInstruction.LESS_TYPECODE;
  @override
  bool typeEquals(other) => other is HLess;
  @override
  bool dataEquals(HInstruction other) => true;
}

class HLessEqual extends HRelational {
  HLessEqual(HInstruction left, HInstruction right, AbstractValue type)
      : super(left, right, type);
  @override
  accept(HVisitor visitor) => visitor.visitLessEqual(this);

  @override
  constant_system.BinaryOperation operation() => constant_system.lessEqual;
  @override
  int typeCode() => HInstruction.LESS_EQUAL_TYPECODE;
  @override
  bool typeEquals(other) => other is HLessEqual;
  @override
  bool dataEquals(HInstruction other) => true;
}

/// Return statement, either with or without a value.
class HReturn extends HControlFlow {
  HReturn(AbstractValueDomain domain, HInstruction /*?*/ value,
      SourceInformation sourceInformation)
      : super(domain, [if (value != null) value]) {
    this.sourceInformation = sourceInformation;
  }
  @override
  toString() => 'return';
  @override
  accept(HVisitor visitor) => visitor.visitReturn(this);
}

class HThrowExpression extends HInstruction {
  HThrowExpression(AbstractValueDomain domain, HInstruction value,
      SourceInformation sourceInformation)
      : super(<HInstruction>[value], domain.emptyType) {
    this.sourceInformation = sourceInformation;
  }
  @override
  toString() => 'throw expression';
  @override
  accept(HVisitor visitor) => visitor.visitThrowExpression(this);
  @override
  bool canThrow(AbstractValueDomain domain) => true;
}

class HAwait extends HInstruction {
  HAwait(HInstruction value, AbstractValue type)
      : super(<HInstruction>[value], type);
  @override
  toString() => 'await';
  @override
  accept(HVisitor visitor) => visitor.visitAwait(this);
  // An await will throw if its argument is not a real future.
  @override
  bool canThrow(AbstractValueDomain domain) => true;
  @override
  SideEffects sideEffects = new SideEffects();
}

class HYield extends HInstruction {
  HYield(AbstractValueDomain domain, HInstruction value, this.hasStar,
      SourceInformation sourceInformation)
      : super(<HInstruction>[value], domain.emptyType) {
    this.sourceInformation = sourceInformation;
  }
  bool hasStar;
  @override
  toString() => 'yield';
  @override
  accept(HVisitor visitor) => visitor.visitYield(this);
  @override
  bool canThrow(AbstractValueDomain domain) => false;
  @override
  SideEffects sideEffects = new SideEffects();
}

class HThrow extends HControlFlow {
  final bool isRethrow;
  HThrow(AbstractValueDomain domain, HInstruction value,
      SourceInformation sourceInformation,
      {this.isRethrow: false})
      : super(domain, <HInstruction>[value]) {
    this.sourceInformation = sourceInformation;
  }
  @override
  toString() => 'throw';
  @override
  accept(HVisitor visitor) => visitor.visitThrow(this);
}

// TODO(johnniwinther): Change this to a "HStaticLoad" of a field when we use
// CFE constants. It has been used for static tear-offs even though these should
// have been constants.
class HStatic extends HInstruction {
  final MemberEntity element;

  HStatic(this.element, AbstractValue type, SourceInformation sourceInformation)
      : super(<HInstruction>[], type) {
    assert(element != null);
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    if (element.isAssignable) {
      sideEffects.setDependsOnStaticPropertyStore();
    }
    setUseGvn();
    this.sourceInformation = sourceInformation;
  }
  @override
  toString() => 'static ${element.name}';
  @override
  accept(HVisitor visitor) => visitor.visitStatic(this);

  @override
  int gvnHashCode() => super.gvnHashCode() ^ element.hashCode;
  @override
  int typeCode() => HInstruction.STATIC_TYPECODE;
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
  Set<ClassEntity> interceptedClasses;

  // inputs[0] is initially the only input, the receiver.

  // inputs[1] is a constant interceptor when the interceptor is a constant
  // except for a `null` receiver.  This is used when the receiver can't be
  // falsy, except for `null`, allowing the generation of code like
  //
  //     (a && C.JSArray_methods).get$first(a)
  //

  HInterceptor(HInstruction receiver, AbstractValue type)
      : super(<HInstruction>[receiver], type) {
    this.sourceInformation = receiver.sourceInformation;
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    setUseGvn();
  }

  @override
  String toString() => 'interceptor on $interceptedClasses';
  @override
  accept(HVisitor visitor) => visitor.visitInterceptor(this);
  HInstruction get receiver => inputs[0];

  bool get isConditionalConstantInterceptor => inputs.length == 2;
  HInstruction get conditionalConstantInterceptor => inputs[1];
  void set conditionalConstantInterceptor(HConstant constant) {
    assert(!isConditionalConstantInterceptor);
    inputs.add(constant);
  }

  @override
  bool isInterceptor(JClosedWorld closedWorld) => true;

  @override
  int typeCode() => HInstruction.INTERCEPTOR_TYPECODE;
  @override
  bool typeEquals(other) => other is HInterceptor;
  @override
  bool dataEquals(HInterceptor other) {
    return interceptedClasses == other.interceptedClasses ||
        (interceptedClasses.length == other.interceptedClasses.length &&
            interceptedClasses.containsAll(other.interceptedClasses));
  }
}

/// A "one-shot" interceptor is a call to a synthetized method that
/// will fetch the interceptor of its first parameter, and make a call
/// on a given selector with the remaining parameters.
///
/// In order to share the same optimizations with regular interceptor
/// calls, this class extends [HInvokeDynamic] and also has the null
/// constant as the first input.
class HOneShotInterceptor extends HInvokeDynamic {
  @override
  List<DartType> typeArguments;
  Set<ClassEntity> interceptedClasses;

  HOneShotInterceptor(
      AbstractValueDomain domain,
      Selector selector,
      AbstractValue receiverType,
      List<HInstruction> inputs,
      AbstractValue resultType,
      this.typeArguments,
      this.interceptedClasses)
      : super(selector, receiverType, null, inputs, true, resultType) {
    assert(inputs[0] is HConstant);
    assert(inputs[0].instructionType == domain.nullType);
    assert(selector.callStructure.typeArgumentCount == typeArguments.length);
  }
  @override
  bool isCallOnInterceptor(JClosedWorld closedWorld) => true;

  @override
  String toString() =>
      'one shot interceptor: selector=$selector, mask=$receiverType';
  @override
  accept(HVisitor visitor) => visitor.visitOneShotInterceptor(this);
}

/// An [HLazyStatic] is a static that is initialized lazily at first read.
class HLazyStatic extends HInstruction {
  final FieldEntity element;

  HLazyStatic(
      this.element, AbstractValue type, SourceInformation sourceInformation)
      : super(<HInstruction>[], type) {
    // TODO(4931): The first access has side-effects, but we afterwards we
    // should be able to GVN.
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
    this.sourceInformation = sourceInformation;
  }

  @override
  toString() => 'lazy static ${element.name}';
  @override
  accept(HVisitor visitor) => visitor.visitLazyStatic(this);

  @override
  int typeCode() => 30;
  // TODO(4931): can we do better here?
  @override
  bool isCodeMotionInvariant() => false;
  @override
  bool canThrow(AbstractValueDomain domain) => true;
}

class HStaticStore extends HInstruction {
  MemberEntity element;
  HStaticStore(AbstractValueDomain domain, this.element, HInstruction value)
      : super(<HInstruction>[value], domain.emptyType) {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    sideEffects.setChangesStaticProperty();
  }
  @override
  toString() => 'static store ${element.name}';
  @override
  accept(HVisitor visitor) => visitor.visitStaticStore(this);

  HInstruction get value => inputs.single;

  @override
  int typeCode() => HInstruction.STATIC_STORE_TYPECODE;
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
  toString() => 'literal list';
  @override
  accept(HVisitor visitor) => visitor.visitLiteralList(this);

  @override
  bool isAllocation(AbstractValueDomain domain) => true;
}

/// The primitive array indexing operation. Note that this instruction
/// does not throw because we generate the checks explicitly.
class HIndex extends HInstruction {
  HIndex(HInstruction receiver, HInstruction index, AbstractValue type)
      : super(<HInstruction>[receiver, index], type) {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    sideEffects.setDependsOnIndexStore();
    setUseGvn();
  }

  @override
  String toString() => 'index operator';
  @override
  accept(HVisitor visitor) => visitor.visitIndex(this);

  HInstruction get receiver => inputs[0];
  HInstruction get index => inputs[1];

  // Implicit dependency on HBoundsCheck or constraints on index.
  // TODO(27272): Make HIndex dependent on bounds checking.
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
  int typeCode() => HInstruction.INDEX_TYPECODE;
  @override
  bool typeEquals(HInstruction other) => other is HIndex;
  @override
  bool dataEquals(HIndex other) => true;
}

/// The primitive array assignment operation. Note that this instruction
/// does not throw because we generate the checks explicitly.
class HIndexAssign extends HInstruction {
  HIndexAssign(AbstractValueDomain domain, HInstruction receiver,
      HInstruction index, HInstruction value)
      : super(<HInstruction>[receiver, index, value], domain.emptyType) {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    sideEffects.setChangesIndex();
  }
  @override
  String toString() => 'index assign operator';
  @override
  accept(HVisitor visitor) => visitor.visitIndexAssign(this);

  HInstruction get receiver => inputs[0];
  HInstruction get index => inputs[1];
  HInstruction get value => inputs[2];

  // Implicit dependency on HBoundsCheck or constraints on index.
  // TODO(27272): Make HIndex dependent on bounds checking.
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

/// HLateValue is a late-stage instruction that can be used to force a value
/// into a temporary.
///
/// HLateValue is useful for naming values that would otherwise be generated at
/// use site, for example, if 'this' is used many times, replacing uses of
/// 'this' with HLateValue(HThis) will have the effect of copying 'this' to a
/// temporary will reduce the size of minified code.
class HLateValue extends HLateInstruction {
  HLateValue(HInstruction target) : super([target], target.instructionType);

  HInstruction get target => inputs.single;

  @override
  accept(HVisitor visitor) => visitor.visitLateValue(this);
  @override
  toString() => 'HLateValue($target)';
}

/// Check for receiver or argument type when lowering operation to a primitive,
/// e.g. lowering `+` to [HAdd].
///
/// After NNBD, `a + b` will require `a` and `b` are non-nullable and these
/// checks will become explicit in the source (e.g. `a! + b!`). At that time,
/// this check should be removed.  If needed, the `!` check can be optimized
/// give the same signals to the JavaScript VM.
class HPrimitiveCheck extends HCheck {
  // Values for [kind].
  static const int ARGUMENT_TYPE_CHECK = 1;
  static const int RECEIVER_TYPE_CHECK = 3;

  final DartType typeExpression;
  final int kind;

  // [receiverTypeCheckSelector] is the selector used for a receiver type check
  // on open-coded operators, e.g. the not-null check on `x` in `x + 1` would be
  // compiled to the following, for which we need the selector `$add`.
  //
  //     if (typeof x != "number") x.$add();
  //
  final Selector receiverTypeCheckSelector;

  final AbstractValue checkedType;

  HPrimitiveCheck(this.typeExpression, this.kind, AbstractValue type,
      HInstruction input, SourceInformation sourceInformation,
      {this.receiverTypeCheckSelector})
      : checkedType = type,
        super(<HInstruction>[input], type) {
    assert(isReceiverTypeCheck == (receiverTypeCheckSelector != null));
    this.sourceElement = input.sourceElement;
    this.sourceInformation = sourceInformation;
  }

  bool get isArgumentTypeCheck => kind == ARGUMENT_TYPE_CHECK;
  bool get isReceiverTypeCheck => kind == RECEIVER_TYPE_CHECK;

  @override
  accept(HVisitor visitor) => visitor.visitPrimitiveCheck(this);

  @override
  bool isJsStatement() => true;
  @override
  bool isControlFlow() => true;

  @override
  int typeCode() => HInstruction.PRIMITIVE_CHECK_TYPECODE;
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
/// front-end generates 'as bool' checks, but until the transition to NNBD is
/// complete, this allows `null` to be passed to the condition.
///
// TODO(sra): Once NNDB is far enough along that the front-end can generate `as
// bool!` checks and the backend checks them correctly, this instruction will
// become unnecessary and should be removed.
class HBoolConversion extends HCheck {
  HBoolConversion(HInstruction input, AbstractValue type)
      : super(<HInstruction>[input], type);

  @override
  bool isJsStatement() => false;

  @override
  bool isCodeMotionInvariant() => false;

  @override
  accept(HVisitor visitor) => visitor.visitBoolConversion(this);

  @override
  int typeCode() => HInstruction.BOOL_CONVERSION_TYPECODE;
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
  toString() => 'HBoolConversion($checkedInput)';
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
  Selector selector;
  FieldEntity field;

  HNullCheck(HInstruction input, AbstractValue type, {this.sticky = false})
      : super(<HInstruction>[input], type);

  @override
  bool isControlFlow() => true;
  @override
  bool isJsStatement() => true;

  @override
  bool isCodeMotionInvariant() => false;

  @override
  accept(HVisitor visitor) => visitor.visitNullCheck(this);

  @override
  int typeCode() => HInstruction.NULL_CHECK_TYPECODE;
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
  toString() {
    String fieldString = field == null ? '' : ', $field';
    String selectorString = selector == null ? '' : ', $selector';
    return 'HNullCheck($checkedInput$fieldString$selectorString)';
  }
}

/// The [HTypeKnown] instruction marks a value with a refined type.
class HTypeKnown extends HCheck {
  AbstractValue knownType;
  final bool _isMovable;

  HTypeKnown.pinned(AbstractValue knownType, HInstruction input)
      : this.knownType = knownType,
        this._isMovable = false,
        super(<HInstruction>[input], knownType);

  HTypeKnown.witnessed(
      AbstractValue knownType, HInstruction input, HInstruction witness)
      : this.knownType = knownType,
        this._isMovable = true,
        super(<HInstruction>[input, witness], knownType);

  @override
  toString() => 'TypeKnown $knownType';
  @override
  accept(HVisitor visitor) => visitor.visitTypeKnown(this);

  @override
  bool isJsStatement() => false;
  @override
  bool isControlFlow() => false;
  @override
  bool canThrow(AbstractValueDomain domain) => false;

  bool get isPinned => inputs.length == 1;

  HInstruction get witness => inputs.length == 2 ? inputs[1] : null;

  @override
  int typeCode() => HInstruction.TYPE_KNOWN_TYPECODE;
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
  HRangeConversion(HInstruction input, type)
      : super(<HInstruction>[input], type) {
    sourceElement = input.sourceElement;
  }

  @override
  bool get isMovable => false;

  @override
  accept(HVisitor visitor) => visitor.visitRangeConversion(this);
}

class HStringConcat extends HInstruction {
  HStringConcat(HInstruction left, HInstruction right, AbstractValue type)
      : super(<HInstruction>[left, right], type) {
    // TODO(sra): Until Issue 9293 is fixed, this false dependency keeps the
    // concats bunched with stringified inputs for much better looking code with
    // fewer temps.
    sideEffects.setDependsOnSomething();
  }

  HInstruction get left => inputs[0];
  HInstruction get right => inputs[1];

  @override
  accept(HVisitor visitor) => visitor.visitStringConcat(this);
  @override
  toString() => "string concat";
}

/// The part of string interpolation which converts and interpolated expression
/// into a String value.
class HStringify extends HInstruction {
  HStringify(HInstruction input, AbstractValue resultType)
      : super(<HInstruction>[input], resultType) {
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
  }

  @override
  accept(HVisitor visitor) => visitor.visitStringify(this);
  @override
  toString() => "stringify";
}

/// Non-block-based (aka. traditional) loop information.
class HLoopInformation {
  final HBasicBlock header;
  final List<HBasicBlock> blocks;
  final List<HBasicBlock> backEdges;
  final List<LabelDefinition> labels;
  final JumpTarget target;

  /// Corresponding block information for the loop.
  HLoopBlockInformation loopBlockInformation;

  HLoopInformation(this.header, this.target, this.labels)
      : blocks = <HBasicBlock>[],
        backEdges = <HBasicBlock>[];

  void addBackEdge(HBasicBlock predecessor) {
    backEdges.add(predecessor);
    List<HBasicBlock> workQueue = <HBasicBlock>[predecessor];
    do {
      HBasicBlock current = workQueue.removeLast();
      addBlock(current, workQueue);
    } while (!workQueue.isEmpty);
  }

  // Adds a block and transitively all its predecessors in the loop as
  // loop blocks.
  void addBlock(HBasicBlock block, List<HBasicBlock> workQueue) {
    if (identical(block, header)) return;
    HBasicBlock parentHeader = block.parentLoopHeader;
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
  final HBasicBlock continuation;
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
  HInstruction get conditionExpression;
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
  bool visitAndOrInfo(HAndOrBlockInformation info);
  bool visitSubExpressionInfo(HSubExpressionBlockInformation info);
}

abstract class HBlockInformationVisitor
    implements HStatementInformationVisitor, HExpressionInformationVisitor {}

/// Generic class wrapping a [SubGraph] as a block-information until
/// all structures are handled properly.
class HSubGraphBlockInformation implements HStatementInformation {
  final SubGraph subGraph;
  HSubGraphBlockInformation(this.subGraph);

  @override
  HBasicBlock get start => subGraph.start;
  @override
  HBasicBlock get end => subGraph.end;

  @override
  bool accept(HStatementInformationVisitor visitor) =>
      visitor.visitSubGraphInfo(this);
}

/// Generic class wrapping a [SubExpression] as a block-information until
/// expressions structures are handled properly.
class HSubExpressionBlockInformation implements HExpressionInformation {
  final SubExpression subExpression;
  HSubExpressionBlockInformation(this.subExpression);

  @override
  HBasicBlock get start => subExpression.start;
  @override
  HBasicBlock get end => subExpression.end;

  @override
  HInstruction get conditionExpression => subExpression.conditionExpression;

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
  final JumpTarget target;
  final bool isContinue;

  HLabeledBlockInformation(this.body, List<LabelDefinition> labels,
      {this.isContinue: false})
      : this.labels = labels,
        this.target = labels[0].target;

  HLabeledBlockInformation.implicit(this.body, this.target,
      {this.isContinue: false})
      : this.labels = const <LabelDefinition>[];

  @override
  HBasicBlock get start => body.start;
  @override
  HBasicBlock get end => body.end;

  @override
  bool accept(HStatementInformationVisitor visitor) =>
      visitor.visitLabeledBlockInfo(this);
}

class HLoopBlockInformation implements HStatementInformation {
  static const int WHILE_LOOP = 0;
  static const int FOR_LOOP = 1;
  static const int DO_WHILE_LOOP = 2;
  static const int FOR_IN_LOOP = 3;
  static const int SWITCH_CONTINUE_LOOP = 4;
  static const int NOT_A_LOOP = -1;

  final int kind;
  final HExpressionInformation initializer;
  final HExpressionInformation condition;
  final HStatementInformation body;
  final HExpressionInformation updates;
  final JumpTarget target;
  final List<LabelDefinition> labels;
  final SourceInformation sourceInformation;

  HLoopBlockInformation(this.kind, this.initializer, this.condition, this.body,
      this.updates, this.target, this.labels, this.sourceInformation) {
    assert(
        (kind == DO_WHILE_LOOP ? body.start : condition.start).isLoopHeader());
  }

  @override
  HBasicBlock get start {
    if (initializer != null) return initializer.start;
    if (kind == DO_WHILE_LOOP) {
      return body.start;
    }
    return condition.start;
  }

  HBasicBlock get loopHeader {
    return kind == DO_WHILE_LOOP ? body.start : condition.start;
  }

  @override
  HBasicBlock get end {
    if (updates != null) return updates.end;
    if (kind == DO_WHILE_LOOP && condition != null) {
      return condition.end;
    }
    return body.end;
  }

  @override
  bool accept(HStatementInformationVisitor visitor) =>
      visitor.visitLoopInfo(this);
}

class HIfBlockInformation implements HStatementInformation {
  final HExpressionInformation condition;
  final HStatementInformation thenGraph;
  final HStatementInformation elseGraph;
  HIfBlockInformation(this.condition, this.thenGraph, this.elseGraph);

  @override
  HBasicBlock get start => condition.start;
  @override
  HBasicBlock get end => elseGraph == null ? thenGraph.end : elseGraph.end;

  @override
  bool accept(HStatementInformationVisitor visitor) =>
      visitor.visitIfInfo(this);
}

class HAndOrBlockInformation implements HExpressionInformation {
  final bool isAnd;
  final HExpressionInformation left;
  final HExpressionInformation right;
  HAndOrBlockInformation(this.isAnd, this.left, this.right);

  @override
  HBasicBlock get start => left.start;
  @override
  HBasicBlock get end => right.end;

  // We don't currently use HAndOrBlockInformation.
  @override
  HInstruction get conditionExpression {
    return null;
  }

  @override
  bool accept(HExpressionInformationVisitor visitor) =>
      visitor.visitAndOrInfo(this);
}

class HTryBlockInformation implements HStatementInformation {
  final HStatementInformation body;
  final HLocalValue catchVariable;
  final HStatementInformation catchBlock;
  final HStatementInformation finallyBlock;
  HTryBlockInformation(
      this.body, this.catchVariable, this.catchBlock, this.finallyBlock);

  @override
  HBasicBlock get start => body.start;
  @override
  HBasicBlock get end =>
      finallyBlock == null ? catchBlock.end : finallyBlock.end;

  @override
  bool accept(HStatementInformationVisitor visitor) =>
      visitor.visitTryInfo(this);
}

class HSwitchBlockInformation implements HStatementInformation {
  final HExpressionInformation expression;
  final List<HStatementInformation> statements;
  final JumpTarget target;
  final List<LabelDefinition> labels;
  final SourceInformation sourceInformation;

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

  HIsTest(this.dartType, this.checkedAbstractValue, HInstruction checked,
      HInstruction rti, AbstractValue type)
      : super([rti, checked], type) {
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
  accept(HVisitor visitor) => visitor.visitIsTest(this);

  @override
  int typeCode() => HInstruction.IS_TEST_TYPECODE;

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
      HInstruction checked, AbstractValue type)
      : super([checked], type) {
    setUseGvn();
  }

  HInstruction get checkedInput => inputs[0];

  AbstractBool evaluate(JClosedWorld closedWorld, CompilerOptions options) =>
      _typeTest(
          checkedInput, dartType, checkedAbstractValue, closedWorld, options,
          isCast: false);

  @override
  accept(HVisitor visitor) => visitor.visitIsTestSimple(this);

  @override
  int typeCode() => HInstruction.IS_TEST_SIMPLE_TYPECODE;

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
    {bool isCast}) {
  JCommonElements commonElements = closedWorld.commonElements;
  DartTypes dartTypes = closedWorld.dartTypes;
  AbstractValueDomain abstractValueDomain = closedWorld.abstractValueDomain;
  AbstractValue subsetType = expression.instructionType;
  AbstractValue supersetType = checkedAbstractValue.abstractValue;
  AbstractBool expressionIsNull = expression.isNull(abstractValueDomain);

  bool _nullIs(DartType type) =>
      dartTypes.isStrongTopType(type) ||
      type is LegacyType &&
          (type.baseType.isObject || type.baseType is NeverType) ||
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

    if (expression.isDouble(abstractValueDomain).isDefinitelyTrue) {
      if (dartTypes.isSubtype(commonElements.doubleType, interface)) {
        return AbstractBool.True;
      }
      if (interface == commonElements.intType) {
        // We let the JS semantics decide for that check. Currently the code we
        // emit will return true for a double that can be represented as a 31-bit
        // integer and for -0.0.
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

  HAsCheck(
      HInstruction checked,
      HInstruction rti,
      this.checkedType,
      this.checkedTypeExpression,
      this.isTypeError,
      AbstractValue instructionType)
      : assert(isTypeError != null),
        super([rti, checked], instructionType);

  // The type input is first to facilitate the `type.as(value)` codegen pattern.
  HInstruction get typeInput => inputs[0];
  @override
  HInstruction get checkedInput => inputs[1];

  @override
  bool isJsStatement() => false;

  @override
  accept(HVisitor visitor) => visitor.visitAsCheck(this);

  @override
  int typeCode() => HInstruction.AS_CHECK_TYPECODE;

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
  final MemberEntity method;

  HAsCheckSimple(HInstruction checked, this.dartType, this.checkedType,
      this.isTypeError, this.method, AbstractValue type)
      : assert(isTypeError != null),
        super([checked], type);

  @override
  HInstruction get checkedInput => inputs[0];

  @override
  bool isJsStatement() => false;

  @override
  accept(HVisitor visitor) => visitor.visitAsCheckSimple(this);

  bool isRedundant(JClosedWorld closedWorld, CompilerOptions options) =>
      _typeTest(checkedInput, dartType, checkedType, closedWorld, options,
              isCast: true)
          .isDefinitelyTrue;

  @override
  int typeCode() => HInstruction.AS_CHECK_SIMPLE_TYPECODE;

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
  HSubtypeCheck(
      HInstruction subtype, HInstruction supertype, AbstractValue type)
      : super([subtype, supertype], type) {
    setUseGvn();
  }

  HInstruction get typeInput => inputs[1];

  @override
  accept(HVisitor visitor) => visitor.visitSubtypeCheck(this);

  @override
  int typeCode() => HInstruction.SUBTYPE_CHECK_TYPECODE;

  @override
  bool typeEquals(HInstruction other) => other is HSubtypeCheck;

  @override
  bool dataEquals(HSubtypeCheck other) => true;

  @override
  String toString() => 'HSubtypeCheck()';
}

/// Common superclass for instructions that generate Rti values.
abstract class HRtiInstruction extends HInstruction {
  HRtiInstruction(List<HInstruction> inputs, AbstractValue type)
      : super(inputs, type);
}

/// Evaluates an Rti type recipe in the global environment.
class HLoadType extends HRtiInstruction {
  TypeRecipe typeExpression;

  HLoadType(this.typeExpression, AbstractValue instructionType)
      : super([], instructionType) {
    setUseGvn();
  }

  HLoadType.type(DartType dartType, AbstractValue instructionType)
      : this(TypeExpressionRecipe(dartType), instructionType);

  @override
  accept(HVisitor visitor) => visitor.visitLoadType(this);

  @override
  int typeCode() => HInstruction.LOAD_TYPE_TYPECODE;

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
class HInstanceEnvironment extends HRtiInstruction {
  AbstractValue codegenInputType; // Assigned in SsaTypeKnownRemover

  HInstanceEnvironment(HInstruction instance, AbstractValue type)
      : super([instance], type) {
    setUseGvn();
  }

  @override
  accept(HVisitor visitor) => visitor.visitInstanceEnvironment(this);

  @override
  int typeCode() => HInstruction.INSTANCE_ENVIRONMENT_TYPECODE;

  @override
  bool typeEquals(HInstruction other) => other is HInstanceEnvironment;

  @override
  bool dataEquals(HInstanceEnvironment other) => true;

  @override
  String toString() => 'HInstanceEnvironment()';
}

/// Evaluates an Rti type recipe in an Rti environment.
class HTypeEval extends HRtiInstruction {
  TypeEnvironmentStructure envStructure;
  TypeRecipe typeExpression;

  HTypeEval(HInstruction environment, this.envStructure, this.typeExpression,
      AbstractValue type)
      : super([environment], type) {
    setUseGvn();
  }

  @override
  accept(HVisitor visitor) => visitor.visitTypeEval(this);

  @override
  int typeCode() => HInstruction.TYPE_EVAL_TYPECODE;

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
class HTypeBind extends HRtiInstruction {
  HTypeBind(
      HInstruction environment, HInstruction typeArguments, AbstractValue type)
      : super([environment, typeArguments], type) {
    setUseGvn();
  }

  @override
  accept(HVisitor visitor) => visitor.visitTypeBind(this);

  @override
  int typeCode() => HInstruction.TYPE_BIND_TYPECODE;

  @override
  bool typeEquals(HInstruction other) => other is HTypeBind;

  @override
  bool dataEquals(HTypeBind other) => true;

  @override
  String toString() => 'HTypeBind()';
}
