// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../closure.dart';
import '../common.dart';
import '../common_elements.dart' show CommonElements;
import '../compiler.dart' show Compiler;
import '../constants/constant_system.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../elements/types.dart';
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js_backend/js_backend.dart';
import '../native/native.dart' as native;
import '../types/constants.dart' show computeTypeMask;
import '../types/types.dart';
import '../universe/selector.dart' show Selector;
import '../universe/side_effects.dart' show SideEffects;
import '../util/util.dart';
import '../world.dart' show ClosedWorld;
import 'invoke_dynamic_specializers.dart';
import 'validate.dart';

abstract class HVisitor<R> {
  R visitAdd(HAdd node);
  R visitAwait(HAwait node);
  R visitBitAnd(HBitAnd node);
  R visitBitNot(HBitNot node);
  R visitBitOr(HBitOr node);
  R visitBitXor(HBitXor node);
  R visitBoolify(HBoolify node);
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
  R visitIs(HIs node);
  R visitIsViaInterceptor(HIsViaInterceptor node);
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
  R visitTypeConversion(HTypeConversion node);
  R visitTypeKnown(HTypeKnown node);
  R visitYield(HYield node);

  R visitTypeInfoReadRaw(HTypeInfoReadRaw node);
  R visitTypeInfoReadVariable(HTypeInfoReadVariable node);
  R visitTypeInfoExpression(HTypeInfoExpression node);
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
  // TODO(johnniwinther): Maybe this should be [MemberLike].
  Entity element; // Used for debug printing.
  HBasicBlock entry;
  HBasicBlock exit;
  HThis thisInstruction;

  /// Receiver parameter, set for methods using interceptor calling convention.
  HParameterValue explicitReceiverParameter;
  bool isRecursiveMethod = false;
  bool calledInLoop = false;
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

  HConstant addConstant(ConstantValue constant, ClosedWorld closedWorld,
      {SourceInformation sourceInformation}) {
    HConstant result = constants[constant];
    // TODO(johnniwinther): Support source information per constant reference.
    if (result == null) {
      if (!constant.isConstant) {
        // We use `null` as the value for invalid constant expressions.
        constant = const NullConstantValue();
      }
      TypeMask type = computeTypeMask(closedWorld, constant);
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

  HConstant addDeferredConstant(
      ConstantValue constant,
      ImportEntity import,
      SourceInformation sourceInformation,
      Compiler compiler,
      ClosedWorld closedWorld) {
    // TODO(sigurdm,johnniwinther): These deferred constants should be created
    // by the constant evaluator.
    ConstantValue wrapper = new DeferredConstantValue(constant, import);
    compiler.backend.outputUnitData
        .registerConstantDeferredUse(wrapper, import);
    return addConstant(wrapper, closedWorld,
        sourceInformation: sourceInformation);
  }

  HConstant addConstantInt(int i, ClosedWorld closedWorld) {
    return addConstant(closedWorld.constantSystem.createInt(i), closedWorld);
  }

  HConstant addConstantDouble(double d, ClosedWorld closedWorld) {
    return addConstant(closedWorld.constantSystem.createDouble(d), closedWorld);
  }

  HConstant addConstantString(String str, ClosedWorld closedWorld) {
    return addConstant(
        closedWorld.constantSystem.createString(str), closedWorld);
  }

  HConstant addConstantStringFromName(js.Name name, ClosedWorld closedWorld) {
    return addConstant(
        new SyntheticConstantValue(
            SyntheticConstantKind.NAME, js.quoteName(name)),
        closedWorld);
  }

  HConstant addConstantBool(bool value, ClosedWorld closedWorld) {
    return addConstant(
        closedWorld.constantSystem.createBool(value), closedWorld);
  }

  HConstant addConstantNull(ClosedWorld closedWorld) {
    return addConstant(closedWorld.constantSystem.createNull(), closedWorld);
  }

  HConstant addConstantUnreachable(ClosedWorld closedWorld) {
    // A constant with an empty type used as the HInstruction of an expression
    // in an unreachable context.
    return addConstant(
        new SyntheticConstantValue(
            SyntheticConstantKind.EMPTY_VALUE, const TypeMask.nonNullEmpty()),
        closedWorld);
  }

  void finalize() {
    addBlock(exit);
    exit.open();
    exit.close(new HExit());
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
  }

  bool isValid() {
    HValidator validator = new HValidator();
    validator.visitGraph(this);
    return validator.isValid;
  }

  toString() => 'HGraph($element)';
}

class HBaseVisitor extends HGraphVisitor implements HVisitor {
  HBasicBlock currentBlock;

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

  visitAdd(HAdd node) => visitBinaryArithmetic(node);
  visitBitAnd(HBitAnd node) => visitBinaryBitOp(node);
  visitBitNot(HBitNot node) => visitInvokeUnary(node);
  visitBitOr(HBitOr node) => visitBinaryBitOp(node);
  visitBitXor(HBitXor node) => visitBinaryBitOp(node);
  visitBoolify(HBoolify node) => visitInstruction(node);
  visitBoundsCheck(HBoundsCheck node) => visitCheck(node);
  visitBreak(HBreak node) => visitJump(node);
  visitContinue(HContinue node) => visitJump(node);
  visitCheck(HCheck node) => visitInstruction(node);
  visitConstant(HConstant node) => visitInstruction(node);
  visitCreate(HCreate node) => visitInstruction(node);
  visitCreateBox(HCreateBox node) => visitInstruction(node);
  visitDivide(HDivide node) => visitBinaryArithmetic(node);
  visitExit(HExit node) => visitControlFlow(node);
  visitExitTry(HExitTry node) => visitControlFlow(node);
  visitFieldGet(HFieldGet node) => visitFieldAccess(node);
  visitFieldSet(HFieldSet node) => visitFieldAccess(node);
  visitForeignCode(HForeignCode node) => visitInstruction(node);
  visitGetLength(HGetLength node) => visitInstruction(node);
  visitGoto(HGoto node) => visitControlFlow(node);
  visitGreater(HGreater node) => visitRelational(node);
  visitGreaterEqual(HGreaterEqual node) => visitRelational(node);
  visitIdentity(HIdentity node) => visitRelational(node);
  visitIf(HIf node) => visitConditionalBranch(node);
  visitIndex(HIndex node) => visitInstruction(node);
  visitIndexAssign(HIndexAssign node) => visitInstruction(node);
  visitInterceptor(HInterceptor node) => visitInstruction(node);
  visitInvokeClosure(HInvokeClosure node) => visitInvokeDynamic(node);
  visitInvokeConstructorBody(HInvokeConstructorBody node) =>
      visitInvokeStatic(node);
  visitInvokeDynamicMethod(HInvokeDynamicMethod node) =>
      visitInvokeDynamic(node);
  visitInvokeDynamicGetter(HInvokeDynamicGetter node) =>
      visitInvokeDynamicField(node);
  visitInvokeDynamicSetter(HInvokeDynamicSetter node) =>
      visitInvokeDynamicField(node);
  visitInvokeStatic(HInvokeStatic node) => visitInvoke(node);
  visitInvokeSuper(HInvokeSuper node) => visitInvokeStatic(node);
  visitJump(HJump node) => visitControlFlow(node);
  visitLazyStatic(HLazyStatic node) => visitInstruction(node);
  visitLess(HLess node) => visitRelational(node);
  visitLessEqual(HLessEqual node) => visitRelational(node);
  visitLiteralList(HLiteralList node) => visitInstruction(node);
  visitLocalAccess(HLocalAccess node) => visitInstruction(node);
  visitLocalGet(HLocalGet node) => visitLocalAccess(node);
  visitLocalSet(HLocalSet node) => visitLocalAccess(node);
  visitLocalValue(HLocalValue node) => visitInstruction(node);
  visitLoopBranch(HLoopBranch node) => visitConditionalBranch(node);
  visitNegate(HNegate node) => visitInvokeUnary(node);
  visitNot(HNot node) => visitInstruction(node);
  visitOneShotInterceptor(HOneShotInterceptor node) => visitInvokeDynamic(node);
  visitPhi(HPhi node) => visitInstruction(node);
  visitMultiply(HMultiply node) => visitBinaryArithmetic(node);
  visitParameterValue(HParameterValue node) => visitLocalValue(node);
  visitRangeConversion(HRangeConversion node) => visitCheck(node);
  visitReadModifyWrite(HReadModifyWrite node) => visitInstruction(node);
  visitRef(HRef node) => node.value.accept(this);
  visitRemainder(HRemainder node) => visitBinaryArithmetic(node);
  visitReturn(HReturn node) => visitControlFlow(node);
  visitShiftLeft(HShiftLeft node) => visitBinaryBitOp(node);
  visitShiftRight(HShiftRight node) => visitBinaryBitOp(node);
  visitSubtract(HSubtract node) => visitBinaryArithmetic(node);
  visitSwitch(HSwitch node) => visitControlFlow(node);
  visitStatic(HStatic node) => visitInstruction(node);
  visitStaticStore(HStaticStore node) => visitInstruction(node);
  visitStringConcat(HStringConcat node) => visitInstruction(node);
  visitStringify(HStringify node) => visitInstruction(node);
  visitThis(HThis node) => visitParameterValue(node);
  visitThrow(HThrow node) => visitControlFlow(node);
  visitThrowExpression(HThrowExpression node) => visitInstruction(node);
  visitTruncatingDivide(HTruncatingDivide node) => visitBinaryArithmetic(node);
  visitTry(HTry node) => visitControlFlow(node);
  visitIs(HIs node) => visitInstruction(node);
  visitIsViaInterceptor(HIsViaInterceptor node) => visitInstruction(node);
  visitTypeConversion(HTypeConversion node) => visitCheck(node);
  visitTypeKnown(HTypeKnown node) => visitCheck(node);
  visitAwait(HAwait node) => visitInstruction(node);
  visitYield(HYield node) => visitInstruction(node);

  visitTypeInfoReadRaw(HTypeInfoReadRaw node) => visitInstruction(node);
  visitTypeInfoReadVariable(HTypeInfoReadVariable node) =>
      visitInstruction(node);
  visitTypeInfoExpression(HTypeInfoExpression node) => visitInstruction(node);
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

  /** Find the condition expression if this sub-expression is a condition. */
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
    assert(contains(instruction));
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

  /** Linear search for [instruction]. */
  bool contains(HInstruction instruction) {
    HInstruction cursor = first;
    while (cursor != null) {
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

  HBasicBlock() : this.withId(null);
  HBasicBlock.withId(this.id)
      : phis = new HInstructionList(),
        predecessors = <HBasicBlock>[],
        successors = const <HBasicBlock>[],
        dominatedBlocks = <HBasicBlock>[];

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

  /**
   * Rewrites all uses of the [from] instruction to using the [to]
   * instruction instead.
   */
  void rewrite(HInstruction from, HInstruction to) {
    for (HInstruction use in from.usedBy) {
      use.rewriteInput(from, to);
    }
    to.usedBy.addAll(from.usedBy);
    from.usedBy.clear();
  }

  /**
   * Rewrites all uses of the [from] instruction to using either the
   * [to] instruction, or a [HCheck] instruction that has better type
   * information on [to], and that dominates the user.
   */
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

  Map<HBasicBlock, bool> dominatesCache;

  bool dominates(HBasicBlock other) {
    if (dominatesCache == null) {
      dominatesCache = new Map<HBasicBlock, bool>();
    } else {
      bool res = dominatesCache[other];
      if (res != null) return res;
    }
    do {
      if (identical(this, other)) return dominatesCache[other] = true;
      other = other.dominator;
    } while (other != null && other.id >= id);
    return dominatesCache[other] = false;
  }

  toString() => 'HBasicBlock($id)';
}

abstract class HInstruction implements Spannable {
  Entity sourceElement;
  SourceInformation sourceInformation;

  final int id;
  static int idCounter;

  final List<HInstruction> inputs;
  final List<HInstruction> usedBy;

  HBasicBlock block;
  HInstruction previous = null;
  HInstruction next = null;

  SideEffects sideEffects = new SideEffects.empty();
  bool _useGvn = false;

  // Type codes.
  static const int UNDEFINED_TYPECODE = -1;
  static const int BOOLIFY_TYPECODE = 0;
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
  static const int TYPE_CONVERSION_TYPECODE = 24;
  static const int TYPE_KNOWN_TYPECODE = 25;
  static const int INVOKE_STATIC_TYPECODE = 26;
  static const int INDEX_TYPECODE = 27;
  static const int IS_TYPECODE = 28;
  static const int INVOKE_DYNAMIC_TYPECODE = 29;
  static const int SHIFT_RIGHT_TYPECODE = 30;

  static const int TRUNCATING_DIVIDE_TYPECODE = 36;
  static const int IS_VIA_INTERCEPTOR_TYPECODE = 37;

  static const int TYPE_INFO_READ_RAW_TYPECODE = 38;
  static const int TYPE_INFO_READ_VARIABLE_TYPECODE = 39;
  static const int TYPE_INFO_EXPRESSION_TYPECODE = 40;

  static const int FOREIGN_CODE_TYPECODE = 41;
  static const int REMAINDER_TYPECODE = 42;
  static const int GET_LENGTH_TYPECODE = 43;

  HInstruction(this.inputs, this.instructionType)
      : id = idCounter++,
        usedBy = <HInstruction>[] {
    assert(inputs.every((e) => e != null));
  }

  int get hashCode => id;

  bool useGvn() => _useGvn;
  void setUseGvn() {
    _useGvn = true;
  }

  bool get isMovable => useGvn();

  /**
   * A pure instruction is an instruction that does not have any side
   * effect, nor any dependency. They can be moved anywhere in the
   * graph.
   */
  bool isPure() {
    return !sideEffects.hasSideEffects() &&
        !sideEffects.dependsOnSomething() &&
        !canThrow();
  }

  /// An instruction is an 'allocation' is it is the sole alias for an object.
  /// This applies to to instructions that allocate new objects and can be
  /// extended to methods that return other allocations without escaping them.
  bool get isAllocation => false;

  /// Overridden by [HCheck] to return the actual non-[HCheck]
  /// instruction it checks against.
  HInstruction nonCheck() => this;

  /// Can this node throw an exception?
  bool canThrow() => false;

  /// Does this node potentially affect control flow.
  bool isControlFlow() => false;

  bool isExact() => instructionType.isExact || isNull();

  bool isValue() => instructionType.isValue;

  bool canBeNull() => instructionType.isNullable;

  bool isNull() => instructionType.isNull;

  bool isConflicting() => instructionType.isEmpty;

  /// Returns `true` if [typeMask] contains [cls].
  static bool containsType(
      TypeMask typeMask, ClassEntity cls, ClosedWorld closedWorld) {
    return closedWorld.isInstantiated(cls) &&
        typeMask.contains(cls, closedWorld);
  }

  /// Returns `true` if [typeMask] contains only [cls].
  static bool containsOnlyType(
      TypeMask typeMask, ClassEntity cls, ClosedWorld closedWorld) {
    return closedWorld.isInstantiated(cls) && typeMask.containsOnly(cls);
  }

  /// Returns `true` if [typeMask] is an instance of [cls].
  static bool isInstanceOf(
      TypeMask typeMask, ClassEntity cls, ClosedWorld closedWorld) {
    return closedWorld.isImplemented(cls) &&
        typeMask.satisfies(cls, closedWorld);
  }

  bool canBePrimitive(ClosedWorld closedWorld) {
    return canBePrimitiveNumber(closedWorld) ||
        canBePrimitiveArray(closedWorld) ||
        canBePrimitiveBoolean(closedWorld) ||
        canBePrimitiveString(closedWorld) ||
        isNull();
  }

  bool canBePrimitiveNumber(ClosedWorld closedWorld) {
    CommonElements commonElements = closedWorld.commonElements;
    // TODO(sra): It should be possible to test only jsDoubleClass and
    // jsUInt31Class, since all others are superclasses of these two.
    return containsType(
            instructionType, commonElements.jsNumberClass, closedWorld) ||
        containsType(instructionType, commonElements.jsIntClass, closedWorld) ||
        containsType(
            instructionType, commonElements.jsPositiveIntClass, closedWorld) ||
        containsType(
            instructionType, commonElements.jsUInt32Class, closedWorld) ||
        containsType(
            instructionType, commonElements.jsUInt31Class, closedWorld) ||
        containsType(
            instructionType, commonElements.jsDoubleClass, closedWorld);
  }

  bool canBePrimitiveBoolean(ClosedWorld closedWorld) {
    return containsType(
        instructionType, closedWorld.commonElements.jsBoolClass, closedWorld);
  }

  bool canBePrimitiveArray(ClosedWorld closedWorld) {
    CommonElements commonElements = closedWorld.commonElements;
    return containsType(
            instructionType, commonElements.jsArrayClass, closedWorld) ||
        containsType(
            instructionType, commonElements.jsFixedArrayClass, closedWorld) ||
        containsType(instructionType, commonElements.jsExtendableArrayClass,
            closedWorld) ||
        containsType(instructionType, commonElements.jsUnmodifiableArrayClass,
            closedWorld);
  }

  bool isIndexablePrimitive(ClosedWorld closedWorld) {
    return instructionType.containsOnlyString(closedWorld) ||
        isInstanceOf(instructionType,
            closedWorld.commonElements.jsIndexableClass, closedWorld);
  }

  bool isFixedArray(ClosedWorld closedWorld) {
    CommonElements commonElements = closedWorld.commonElements;
    // TODO(sra): Recognize the union of these types as well.
    return containsOnlyType(
            instructionType, commonElements.jsFixedArrayClass, closedWorld) ||
        containsOnlyType(instructionType,
            commonElements.jsUnmodifiableArrayClass, closedWorld);
  }

  bool isExtendableArray(ClosedWorld closedWorld) {
    return containsOnlyType(instructionType,
        closedWorld.commonElements.jsExtendableArrayClass, closedWorld);
  }

  bool isMutableArray(ClosedWorld closedWorld) {
    return isInstanceOf(instructionType,
        closedWorld.commonElements.jsMutableArrayClass, closedWorld);
  }

  bool isReadableArray(ClosedWorld closedWorld) {
    return isInstanceOf(
        instructionType, closedWorld.commonElements.jsArrayClass, closedWorld);
  }

  bool isMutableIndexable(ClosedWorld closedWorld) {
    return isInstanceOf(instructionType,
        closedWorld.commonElements.jsMutableIndexableClass, closedWorld);
  }

  bool isArray(ClosedWorld closedWorld) => isReadableArray(closedWorld);

  bool canBePrimitiveString(ClosedWorld closedWorld) {
    return containsType(
        instructionType, closedWorld.commonElements.jsStringClass, closedWorld);
  }

  bool isInteger(ClosedWorld closedWorld) {
    return instructionType.containsOnlyInt(closedWorld) &&
        !instructionType.isNullable;
  }

  bool isUInt32(ClosedWorld closedWorld) {
    return !instructionType.isNullable &&
        isInstanceOf(instructionType, closedWorld.commonElements.jsUInt32Class,
            closedWorld);
  }

  bool isUInt31(ClosedWorld closedWorld) {
    return !instructionType.isNullable &&
        isInstanceOf(instructionType, closedWorld.commonElements.jsUInt31Class,
            closedWorld);
  }

  bool isPositiveInteger(ClosedWorld closedWorld) {
    return !instructionType.isNullable &&
        isInstanceOf(instructionType,
            closedWorld.commonElements.jsPositiveIntClass, closedWorld);
  }

  bool isPositiveIntegerOrNull(ClosedWorld closedWorld) {
    return isInstanceOf(instructionType,
        closedWorld.commonElements.jsPositiveIntClass, closedWorld);
  }

  bool isIntegerOrNull(ClosedWorld closedWorld) {
    return instructionType.containsOnlyInt(closedWorld);
  }

  bool isNumber(ClosedWorld closedWorld) {
    return instructionType.containsOnlyNum(closedWorld) &&
        !instructionType.isNullable;
  }

  bool isNumberOrNull(ClosedWorld closedWorld) {
    return instructionType.containsOnlyNum(closedWorld);
  }

  bool isDouble(ClosedWorld closedWorld) {
    return instructionType.containsOnlyDouble(closedWorld) &&
        !instructionType.isNullable;
  }

  bool isDoubleOrNull(ClosedWorld closedWorld) {
    return instructionType.containsOnlyDouble(closedWorld);
  }

  bool isBoolean(ClosedWorld closedWorld) {
    return instructionType.containsOnlyBool(closedWorld) &&
        !instructionType.isNullable;
  }

  bool isBooleanOrNull(ClosedWorld closedWorld) {
    return instructionType.containsOnlyBool(closedWorld);
  }

  bool isString(ClosedWorld closedWorld) {
    return instructionType.containsOnlyString(closedWorld) &&
        !instructionType.isNullable;
  }

  bool isStringOrNull(ClosedWorld closedWorld) {
    return instructionType.containsOnlyString(closedWorld);
  }

  bool isPrimitive(ClosedWorld closedWorld) {
    return (isPrimitiveOrNull(closedWorld) && !instructionType.isNullable) ||
        isNull();
  }

  bool isPrimitiveOrNull(ClosedWorld closedWorld) {
    return isIndexablePrimitive(closedWorld) ||
        isNumberOrNull(closedWorld) ||
        isBooleanOrNull(closedWorld) ||
        isNull();
  }

  /**
   * Type of the instruction.
   */
  TypeMask instructionType;

  Selector get selector => null;
  HInstruction getDartReceiver(ClosedWorld closedWorld) => null;
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

  /** Removes all occurrences of [instruction] from [list]. */
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

  /** Removes all occurrences of [user] from [usedBy]. */
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

  bool isInterceptor(ClosedWorld closedWorld) => false;

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

  HInstruction convertType(ClosedWorld closedWorld, DartType type, int kind) {
    if (type == null) return this;
    type = type.unaliased;
    // Only the builder knows how to create [HTypeConversion]
    // instructions with generics. It has the generic type context
    // available.
    assert(!type.isTypeVariable);
    assert(type.treatAsRaw || type.isFunctionType);
    if (type.isDynamic) return this;
    if (type.isVoid) return this;
    if (type == closedWorld.commonElements.objectType) return this;
    if (type.isFunctionType || type.isMalformed) {
      return new HTypeConversion(
          type, kind, closedWorld.commonMasks.dynamicType, this);
    }
    assert(type.isInterfaceType);
    if (kind == HTypeConversion.BOOLEAN_CONVERSION_CHECK) {
      // Boolean conversion checks work on non-nullable booleans.
      return new HTypeConversion(
          type, kind, closedWorld.commonMasks.boolType, this);
    } else if (kind == HTypeConversion.CHECKED_MODE_CHECK && !type.treatAsRaw) {
      throw 'creating compound check to $type (this = ${this})';
    } else {
      InterfaceType interfaceType = type;
      TypeMask subtype =
          new TypeMask.subtype(interfaceType.element, closedWorld);
      return new HTypeConversion(type, kind, subtype, this);
    }
  }

  /**
   * Return whether the instructions do not belong to a loop or
   * belong to the same loop.
   */
  bool hasSameLoopHeaderAs(HInstruction other) {
    return block.enclosingLoopHeader == other.block.enclosingLoopHeader;
  }
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
  static of(HInstruction source, HInstruction dominator,
      {bool excludeDominator: false, bool excludePhiOutEdges: false}) {
    return new DominatedUses._(source)
      .._compute(source, dominator, excludeDominator, excludePhiOutEdges);
  }

  bool get isEmpty => _instructions.isEmpty;
  bool get isNotEmpty => !isEmpty;

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
  HInstruction convertType(ClosedWorld closedWorld, DartType type, int kind) {
    HInstruction converted = value.convertType(closedWorld, type, kind);
    if (converted == value) return this;
    HTypeConversion conversion = converted;
    conversion.inputs[0] = this;
    return conversion;
  }

  @override
  accept(HVisitor visitor) => visitor.visitRef(this);

  String toString() => 'HRef(${value})';
}

/**
 * Late instructions are used after the main optimization phases.  They capture
 * codegen decisions just prior to generating JavaScript.
 */
abstract class HLateInstruction extends HInstruction {
  HLateInstruction(List<HInstruction> inputs, TypeMask type)
      : super(inputs, type);
}

class HBoolify extends HInstruction {
  HBoolify(HInstruction value, TypeMask type)
      : super(<HInstruction>[value], type) {
    setUseGvn();
    sourceInformation = value.sourceInformation;
  }

  accept(HVisitor visitor) => visitor.visitBoolify(this);
  int typeCode() => HInstruction.BOOLIFY_TYPECODE;
  bool typeEquals(other) => other is HBoolify;
  bool dataEquals(HInstruction other) => true;
}

/**
 * A [HCheck] instruction is an instruction that might do a dynamic
 * check at runtime on another instruction. To have proper instruction
 * dependencies in the graph, instructions that depend on the check
 * being done reference the [HCheck] instruction instead of the
 * instruction itself.
 */
abstract class HCheck extends HInstruction {
  HCheck(inputs, type) : super(inputs, type) {
    setUseGvn();
  }
  HInstruction get checkedInput => inputs[0];
  bool isJsStatement() => true;
  bool canThrow() => true;

  HInstruction nonCheck() => checkedInput.nonCheck();
}

class HBoundsCheck extends HCheck {
  static const int ALWAYS_FALSE = 0;
  static const int FULL_CHECK = 1;
  static const int ALWAYS_ABOVE_ZERO = 2;
  static const int ALWAYS_BELOW_LENGTH = 3;
  static const int ALWAYS_TRUE = 4;
  /**
   * Details which tests have been done statically during compilation.
   * Default is that all checks must be performed dynamically.
   */
  int staticChecks = FULL_CHECK;

  HBoundsCheck(length, index, array, type)
      : super(<HInstruction>[length, index, array], type);

  HInstruction get length => inputs[1];
  HInstruction get index => inputs[0];
  HInstruction get array => inputs[2];
  // There can be an additional fourth input which is the index to report to
  // [ioore]. This is used by the expansion of [JSArray.removeLast].
  HInstruction get reportedIndex => inputs.length > 3 ? inputs[3] : index;
  bool isControlFlow() => true;

  accept(HVisitor visitor) => visitor.visitBoundsCheck(this);
  int typeCode() => HInstruction.BOUNDS_CHECK_TYPECODE;
  bool typeEquals(other) => other is HBoundsCheck;
  bool dataEquals(HInstruction other) => true;
}

abstract class HConditionalBranch extends HControlFlow {
  HConditionalBranch(inputs) : super(inputs);
  HInstruction get condition => inputs[0];
  HBasicBlock get trueBranch => block.successors[0];
  HBasicBlock get falseBranch => block.successors[1];
}

abstract class HControlFlow extends HInstruction {
  HControlFlow(inputs) : super(inputs, const TypeMask.nonNullEmpty());
  bool isControlFlow() => true;
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
  List<DartType> instantiatedTypes;

  /// If this node creates a closure class, [callMethod] is the call method of
  /// the closure class.
  FunctionEntity callMethod;

  HCreate(this.element, List<HInstruction> inputs, TypeMask type,
      {this.instantiatedTypes, this.hasRtiInput: false, this.callMethod})
      : super(inputs, type);

  bool get isAllocation => true;

  HInstruction get rtiInput {
    assert(hasRtiInput);
    return inputs.last;
  }

  accept(HVisitor visitor) => visitor.visitCreate(this);

  String toString() => 'HCreate($element, ${instantiatedTypes})';
}

// Allocates a box to hold mutated captured variables.
class HCreateBox extends HInstruction {
  HCreateBox(TypeMask type) : super(<HInstruction>[], type);

  bool get isAllocation => true;

  accept(HVisitor visitor) => visitor.visitCreateBox(this);

  String toString() => 'HCreateBox()';
}

abstract class HInvoke extends HInstruction {
  /**
    * The first argument must be the target: either an [HStatic] node, or
    * the receiver of a method-call. The remaining inputs are the arguments
    * to the invocation.
    */
  HInvoke(List<HInstruction> inputs, type) : super(inputs, type) {
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
  }
  static const int ARGUMENTS_OFFSET = 1;
  bool canThrow() => true;

  /**
   * Returns whether this call is on an intercepted method.
   */
  bool get isInterceptedCall {
    // We know it's a selector call if it follows the interceptor
    // calling convention, which adds the actual receiver as a
    // parameter to the call.
    return (selector != null) && (inputs.length - 2 == selector.argumentCount);
  }
}

abstract class HInvokeDynamic extends HInvoke {
  final InvokeDynamicSpecializer specializer;
  Selector selector;
  TypeMask mask;
  MemberEntity element;

  HInvokeDynamic(Selector selector, this.mask, this.element,
      List<HInstruction> inputs, TypeMask type,
      [bool isIntercepted = false])
      : this.selector = selector,
        specializer = isIntercepted
            ? InvokeDynamicSpecializer.lookupSpecializer(selector)
            : const InvokeDynamicSpecializer(),
        super(inputs, type);
  toString() => 'invoke dynamic: selector=$selector, mask=$mask';
  HInstruction get receiver => inputs[0];
  HInstruction getDartReceiver(ClosedWorld closedWorld) {
    return isCallOnInterceptor(closedWorld) ? inputs[1] : inputs[0];
  }

  /**
   * Returns whether this call is on an interceptor object.
   */
  bool isCallOnInterceptor(ClosedWorld closedWorld) {
    return isInterceptedCall && receiver.isInterceptor(closedWorld);
  }

  int typeCode() => HInstruction.INVOKE_DYNAMIC_TYPECODE;
  bool typeEquals(other) => other is HInvokeDynamic;
  bool dataEquals(HInvokeDynamic other) {
    // Use the name and the kind instead of [Selector.operator==]
    // because we don't need to check the arity (already checked in
    // [gvnEquals]), and the receiver types may not be in sync.
    return selector.name == other.selector.name &&
        selector.kind == other.selector.kind;
  }
}

class HInvokeClosure extends HInvokeDynamic {
  HInvokeClosure(Selector selector, List<HInstruction> inputs, TypeMask type)
      : super(selector, null, null, inputs, type) {
    assert(selector.isClosureCall);
  }
  accept(HVisitor visitor) => visitor.visitInvokeClosure(this);
}

class HInvokeDynamicMethod extends HInvokeDynamic {
  HInvokeDynamicMethod(Selector selector, TypeMask mask,
      List<HInstruction> inputs, TypeMask type,
      [bool isIntercepted = false])
      : super(selector, mask, null, inputs, type, isIntercepted);

  String toString() => 'invoke dynamic method: selector=$selector, mask=$mask';
  accept(HVisitor visitor) => visitor.visitInvokeDynamicMethod(this);
}

abstract class HInvokeDynamicField extends HInvokeDynamic {
  HInvokeDynamicField(Selector selector, TypeMask mask, MemberEntity element,
      List<HInstruction> inputs, TypeMask type)
      : super(selector, mask, element, inputs, type);
  toString() => 'invoke dynamic field: selector=$selector, mask=$mask';
}

class HInvokeDynamicGetter extends HInvokeDynamicField {
  HInvokeDynamicGetter(Selector selector, TypeMask mask, MemberEntity element,
      List<HInstruction> inputs, TypeMask type)
      : super(selector, mask, element, inputs, type);
  toString() => 'invoke dynamic getter: selector=$selector, mask=$mask';
  accept(HVisitor visitor) => visitor.visitInvokeDynamicGetter(this);

  bool get isTearOff => element != null && element.isFunction;

  // There might be an interceptor input, so `inputs.last` is the dart receiver.
  bool canThrow() => isTearOff ? inputs.last.canBeNull() : super.canThrow();
}

class HInvokeDynamicSetter extends HInvokeDynamicField {
  HInvokeDynamicSetter(Selector selector, TypeMask mask, MemberEntity element,
      List<HInstruction> inputs, TypeMask type)
      : super(selector, mask, element, inputs, type);
  toString() => 'invoke dynamic setter: selector=$selector, mask=$mask';
  accept(HVisitor visitor) => visitor.visitInvokeDynamicSetter(this);
}

class HInvokeStatic extends HInvoke {
  final MemberEntity element;

  final bool targetCanThrow;

  bool canThrow() => targetCanThrow;

  /// If this instruction is a call to a constructor, [instantiatedTypes]
  /// contains the type(s) used in the (Dart) `New` expression(s). The
  /// [instructionType] of this node is not enough, because we also need the
  /// type arguments. See also [SsaFromAstMixin.currentInlinedInstantiations].
  List<DartType> instantiatedTypes;

  /** The first input must be the target. */
  HInvokeStatic(this.element, inputs, TypeMask type,
      {this.targetCanThrow: true})
      : super(inputs, type);

  toString() => 'invoke static: $element';
  accept(HVisitor visitor) => visitor.visitInvokeStatic(this);
  int typeCode() => HInstruction.INVOKE_STATIC_TYPECODE;
}

class HInvokeSuper extends HInvokeStatic {
  /** The class where the call to super is being done. */
  final ClassEntity caller;
  final bool isSetter;
  final Selector selector;

  HInvokeSuper(MemberEntity element, this.caller, this.selector, inputs, type,
      SourceInformation sourceInformation,
      {this.isSetter})
      : super(element, inputs, type) {
    this.sourceInformation = sourceInformation;
  }

  HInstruction get receiver => inputs[0];
  HInstruction getDartReceiver(ClosedWorld closedWorld) {
    return isCallOnInterceptor(closedWorld) ? inputs[1] : inputs[0];
  }

  /**
   * Returns whether this call is on an interceptor object.
   */
  bool isCallOnInterceptor(ClosedWorld closedWorld) {
    return isInterceptedCall && receiver.isInterceptor(closedWorld);
  }

  toString() => 'invoke super: $element';
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
  HInvokeConstructorBody(element, inputs, type) : super(element, inputs, type);

  String toString() => 'invoke constructor body: ${element.name}';
  accept(HVisitor visitor) => visitor.visitInvokeConstructorBody(this);
}

abstract class HFieldAccess extends HInstruction {
  final FieldEntity element;

  HFieldAccess(this.element, List<HInstruction> inputs, TypeMask type)
      : super(inputs, type);

  HInstruction get receiver => inputs[0];
}

class HFieldGet extends HFieldAccess {
  final bool isAssignable;

  HFieldGet(FieldEntity element, HInstruction receiver, TypeMask type,
      {bool isAssignable})
      : this.isAssignable =
            (isAssignable != null) ? isAssignable : element.isAssignable,
        super(element, <HInstruction>[receiver], type) {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    setUseGvn();
    if (this.isAssignable) {
      sideEffects.setDependsOnInstancePropertyStore();
    }
  }

  bool isInterceptor(ClosedWorld closedWorld) {
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

  bool canThrow() => receiver.canBeNull();

  HInstruction getDartReceiver(ClosedWorld closedWorld) => receiver;
  bool onlyThrowsNSM() => true;
  bool get isNullCheck => element == null;

  accept(HVisitor visitor) => visitor.visitFieldGet(this);

  int typeCode() => HInstruction.FIELD_GET_TYPECODE;
  bool typeEquals(other) => other is HFieldGet;
  bool dataEquals(HFieldGet other) => element == other.element;
  String toString() => "FieldGet $element";
}

class HFieldSet extends HFieldAccess {
  HFieldSet(FieldEntity element, HInstruction receiver, HInstruction value)
      : super(element, <HInstruction>[receiver, value],
            const TypeMask.nonNullEmpty()) {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    sideEffects.setChangesInstanceProperty();
  }

  bool canThrow() => receiver.canBeNull();

  HInstruction getDartReceiver(ClosedWorld closedWorld) => receiver;
  bool onlyThrowsNSM() => true;

  HInstruction get value => inputs[1];
  accept(HVisitor visitor) => visitor.visitFieldSet(this);

  bool isJsStatement() => true;
  String toString() => "FieldSet $element";
}

class HGetLength extends HInstruction {
  final bool isAssignable;
  HGetLength(HInstruction receiver, TypeMask type, {bool this.isAssignable})
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

  bool canThrow() => receiver.canBeNull();

  HInstruction getDartReceiver(ClosedWorld closedWorld) => receiver;
  bool onlyThrowsNSM() => true;

  accept(HVisitor visitor) => visitor.visitGetLength(this);

  int typeCode() => HInstruction.GET_LENGTH_TYPECODE;
  bool typeEquals(other) => other is HGetLength;
  bool dataEquals(HGetLength other) => true;
  String toString() => "GetLength()";
}

/**
 * HReadModifyWrite is a late stage instruction for a field (property) update
 * via an assignment operation or pre- or post-increment.
 */
class HReadModifyWrite extends HLateInstruction {
  static const ASSIGN_OP = 0;
  static const PRE_OP = 1;
  static const POST_OP = 2;
  final FieldEntity element;
  final String jsOp;
  final int opKind;

  HReadModifyWrite._(this.element, this.jsOp, this.opKind,
      List<HInstruction> inputs, TypeMask type)
      : super(inputs, type) {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    sideEffects.setChangesInstanceProperty();
    sideEffects.setDependsOnInstancePropertyStore();
  }

  HReadModifyWrite.assignOp(FieldEntity element, String jsOp,
      HInstruction receiver, HInstruction operand, TypeMask type)
      : this._(
            element, jsOp, ASSIGN_OP, <HInstruction>[receiver, operand], type);

  HReadModifyWrite.preOp(
      FieldEntity element, String jsOp, HInstruction receiver, TypeMask type)
      : this._(element, jsOp, PRE_OP, <HInstruction>[receiver], type);

  HReadModifyWrite.postOp(
      FieldEntity element, String jsOp, HInstruction receiver, TypeMask type)
      : this._(element, jsOp, POST_OP, <HInstruction>[receiver], type);

  HInstruction get receiver => inputs[0];

  bool get isPreOp => opKind == PRE_OP;
  bool get isPostOp => opKind == POST_OP;
  bool get isAssignOp => opKind == ASSIGN_OP;

  bool canThrow() => receiver.canBeNull();

  HInstruction getDartReceiver(ClosedWorld closedWorld) => receiver;
  bool onlyThrowsNSM() => true;

  HInstruction get value => inputs[1];
  accept(HVisitor visitor) => visitor.visitReadModifyWrite(this);

  bool isJsStatement() => isAssignOp;
  String toString() => "ReadModifyWrite $jsOp $opKind $element";
}

abstract class HLocalAccess extends HInstruction {
  final Local variable;

  HLocalAccess(this.variable, List<HInstruction> inputs, TypeMask type)
      : super(inputs, type);

  HInstruction get receiver => inputs[0];
}

class HLocalGet extends HLocalAccess {
  // No need to use GVN for a [HLocalGet], it is just a local
  // access.
  HLocalGet(Local variable, HLocalValue local, TypeMask type,
      SourceInformation sourceInformation)
      : super(variable, <HInstruction>[local], type) {
    this.sourceInformation = sourceInformation;
  }

  accept(HVisitor visitor) => visitor.visitLocalGet(this);

  HLocalValue get local => inputs[0];
}

class HLocalSet extends HLocalAccess {
  HLocalSet(Local variable, HLocalValue local, HInstruction value)
      : super(variable, <HInstruction>[local, value],
            const TypeMask.nonNullEmpty());

  accept(HVisitor visitor) => visitor.visitLocalSet(this);

  HLocalValue get local => inputs[0];
  HInstruction get value => inputs[1];
  bool isJsStatement() => true;
}

abstract class HForeign extends HInstruction {
  HForeign(TypeMask type, List<HInstruction> inputs) : super(inputs, type);

  bool get isStatement => false;
  native.NativeBehavior get nativeBehavior => null;

  bool canThrow() {
    return sideEffects.hasSideEffects() || sideEffects.dependsOnSomething();
  }
}

class HForeignCode extends HForeign {
  final js.Template codeTemplate;
  final bool isStatement;
  final native.NativeBehavior nativeBehavior;
  native.NativeThrowBehavior throwBehavior;
  final FunctionEntity foreignFunction;

  HForeignCode(this.codeTemplate, TypeMask type, List<HInstruction> inputs,
      {this.isStatement: false,
      SideEffects effects,
      native.NativeBehavior nativeBehavior,
      native.NativeThrowBehavior throwBehavior,
      this.foreignFunction})
      : this.nativeBehavior = nativeBehavior,
        this.throwBehavior = throwBehavior,
        super(type, inputs) {
    assert(codeTemplate != null);
    if (effects == null && nativeBehavior != null) {
      effects = nativeBehavior.sideEffects;
    }
    if (this.throwBehavior == null) {
      this.throwBehavior = (nativeBehavior == null)
          ? native.NativeThrowBehavior.MAY
          : nativeBehavior.throwBehavior;
    }
    assert(this.throwBehavior != null);

    if (effects != null) sideEffects.add(effects);
    if (nativeBehavior != null && nativeBehavior.useGvn) {
      setUseGvn();
    }
  }

  HForeignCode.statement(js.Template codeTemplate, List<HInstruction> inputs,
      SideEffects effects, native.NativeBehavior nativeBehavior, TypeMask type)
      : this(codeTemplate, type, inputs,
            isStatement: true,
            effects: effects,
            nativeBehavior: nativeBehavior);

  accept(HVisitor visitor) => visitor.visitForeignCode(this);

  bool isJsStatement() => isStatement;
  bool canThrow() {
    if (inputs.length > 0) {
      return inputs.first.canBeNull()
          ? throwBehavior.canThrow
          : throwBehavior.onNonNull.canThrow;
    }
    return throwBehavior.canThrow;
  }

  bool onlyThrowsNSM() => throwBehavior.isOnlyNullNSMGuard;

  bool get isAllocation =>
      nativeBehavior != null && nativeBehavior.isAllocation && !canBeNull();

  int typeCode() => HInstruction.FOREIGN_CODE_TYPECODE;
  bool typeEquals(other) => other is HForeignCode;
  bool dataEquals(HForeignCode other) {
    return codeTemplate.source != null &&
        codeTemplate.source == other.codeTemplate.source;
  }

  String toString() => 'HForeignCode("${codeTemplate.source}")';
}

abstract class HInvokeBinary extends HInstruction {
  final Selector selector;
  HInvokeBinary(
      HInstruction left, HInstruction right, this.selector, TypeMask type)
      : super(<HInstruction>[left, right], type) {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    setUseGvn();
  }

  HInstruction get left => inputs[0];
  HInstruction get right => inputs[1];

  BinaryOperation operation(ConstantSystem constantSystem);
}

abstract class HBinaryArithmetic extends HInvokeBinary {
  HBinaryArithmetic(
      HInstruction left, HInstruction right, Selector selector, TypeMask type)
      : super(left, right, selector, type);
  BinaryOperation operation(ConstantSystem constantSystem);
}

class HAdd extends HBinaryArithmetic {
  HAdd(HInstruction left, HInstruction right, Selector selector, TypeMask type)
      : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitAdd(this);

  BinaryOperation operation(ConstantSystem constantSystem) =>
      constantSystem.add;
  int typeCode() => HInstruction.ADD_TYPECODE;
  bool typeEquals(other) => other is HAdd;
  bool dataEquals(HInstruction other) => true;
}

class HDivide extends HBinaryArithmetic {
  HDivide(
      HInstruction left, HInstruction right, Selector selector, TypeMask type)
      : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitDivide(this);

  BinaryOperation operation(ConstantSystem constantSystem) =>
      constantSystem.divide;
  int typeCode() => HInstruction.DIVIDE_TYPECODE;
  bool typeEquals(other) => other is HDivide;
  bool dataEquals(HInstruction other) => true;
}

class HMultiply extends HBinaryArithmetic {
  HMultiply(
      HInstruction left, HInstruction right, Selector selector, TypeMask type)
      : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitMultiply(this);

  BinaryOperation operation(ConstantSystem operations) => operations.multiply;
  int typeCode() => HInstruction.MULTIPLY_TYPECODE;
  bool typeEquals(other) => other is HMultiply;
  bool dataEquals(HInstruction other) => true;
}

class HSubtract extends HBinaryArithmetic {
  HSubtract(
      HInstruction left, HInstruction right, Selector selector, TypeMask type)
      : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitSubtract(this);

  BinaryOperation operation(ConstantSystem constantSystem) =>
      constantSystem.subtract;
  int typeCode() => HInstruction.SUBTRACT_TYPECODE;
  bool typeEquals(other) => other is HSubtract;
  bool dataEquals(HInstruction other) => true;
}

class HTruncatingDivide extends HBinaryArithmetic {
  HTruncatingDivide(
      HInstruction left, HInstruction right, Selector selector, TypeMask type)
      : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitTruncatingDivide(this);

  BinaryOperation operation(ConstantSystem constantSystem) =>
      constantSystem.truncatingDivide;
  int typeCode() => HInstruction.TRUNCATING_DIVIDE_TYPECODE;
  bool typeEquals(other) => other is HTruncatingDivide;
  bool dataEquals(HInstruction other) => true;
}

class HRemainder extends HBinaryArithmetic {
  HRemainder(
      HInstruction left, HInstruction right, Selector selector, TypeMask type)
      : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitRemainder(this);

  BinaryOperation operation(ConstantSystem constantSystem) =>
      constantSystem.remainder;
  int typeCode() => HInstruction.REMAINDER_TYPECODE;
  bool typeEquals(other) => other is HRemainder;
  bool dataEquals(HInstruction other) => true;
}

/**
 * An [HSwitch] instruction has one input for the incoming
 * value, and one input per constant that it can switch on.
 * Its block has one successor per constant, and one for the default.
 */
class HSwitch extends HControlFlow {
  HSwitch(List<HInstruction> inputs) : super(inputs);

  HConstant constant(int index) => inputs[index + 1];
  HInstruction get expression => inputs[0];

  /**
   * Provides the target to jump to if none of the constants match
   * the expression. If the switch had no default case, this is the
   * following join-block.
   */
  HBasicBlock get defaultTarget => block.successors.last;

  accept(HVisitor visitor) => visitor.visitSwitch(this);

  String toString() => "HSwitch cases = $inputs";
}

abstract class HBinaryBitOp extends HInvokeBinary {
  HBinaryBitOp(
      HInstruction left, HInstruction right, Selector selector, TypeMask type)
      : super(left, right, selector, type);
}

class HShiftLeft extends HBinaryBitOp {
  HShiftLeft(
      HInstruction left, HInstruction right, Selector selector, TypeMask type)
      : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitShiftLeft(this);

  BinaryOperation operation(ConstantSystem constantSystem) =>
      constantSystem.shiftLeft;
  int typeCode() => HInstruction.SHIFT_LEFT_TYPECODE;
  bool typeEquals(other) => other is HShiftLeft;
  bool dataEquals(HInstruction other) => true;
}

class HShiftRight extends HBinaryBitOp {
  HShiftRight(
      HInstruction left, HInstruction right, Selector selector, TypeMask type)
      : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitShiftRight(this);

  BinaryOperation operation(ConstantSystem constantSystem) =>
      constantSystem.shiftRight;
  int typeCode() => HInstruction.SHIFT_RIGHT_TYPECODE;
  bool typeEquals(other) => other is HShiftRight;
  bool dataEquals(HInstruction other) => true;
}

class HBitOr extends HBinaryBitOp {
  HBitOr(
      HInstruction left, HInstruction right, Selector selector, TypeMask type)
      : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitBitOr(this);

  BinaryOperation operation(ConstantSystem constantSystem) =>
      constantSystem.bitOr;
  int typeCode() => HInstruction.BIT_OR_TYPECODE;
  bool typeEquals(other) => other is HBitOr;
  bool dataEquals(HInstruction other) => true;
}

class HBitAnd extends HBinaryBitOp {
  HBitAnd(
      HInstruction left, HInstruction right, Selector selector, TypeMask type)
      : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitBitAnd(this);

  BinaryOperation operation(ConstantSystem constantSystem) =>
      constantSystem.bitAnd;
  int typeCode() => HInstruction.BIT_AND_TYPECODE;
  bool typeEquals(other) => other is HBitAnd;
  bool dataEquals(HInstruction other) => true;
}

class HBitXor extends HBinaryBitOp {
  HBitXor(
      HInstruction left, HInstruction right, Selector selector, TypeMask type)
      : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitBitXor(this);

  BinaryOperation operation(ConstantSystem constantSystem) =>
      constantSystem.bitXor;
  int typeCode() => HInstruction.BIT_XOR_TYPECODE;
  bool typeEquals(other) => other is HBitXor;
  bool dataEquals(HInstruction other) => true;
}

abstract class HInvokeUnary extends HInstruction {
  final Selector selector;
  HInvokeUnary(HInstruction input, this.selector, type)
      : super(<HInstruction>[input], type) {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    setUseGvn();
  }

  HInstruction get operand => inputs[0];

  UnaryOperation operation(ConstantSystem constantSystem);
}

class HNegate extends HInvokeUnary {
  HNegate(HInstruction input, Selector selector, TypeMask type)
      : super(input, selector, type);
  accept(HVisitor visitor) => visitor.visitNegate(this);

  UnaryOperation operation(ConstantSystem constantSystem) =>
      constantSystem.negate;
  int typeCode() => HInstruction.NEGATE_TYPECODE;
  bool typeEquals(other) => other is HNegate;
  bool dataEquals(HInstruction other) => true;
}

class HBitNot extends HInvokeUnary {
  HBitNot(HInstruction input, Selector selector, TypeMask type)
      : super(input, selector, type);
  accept(HVisitor visitor) => visitor.visitBitNot(this);

  UnaryOperation operation(ConstantSystem constantSystem) =>
      constantSystem.bitNot;
  int typeCode() => HInstruction.BIT_NOT_TYPECODE;
  bool typeEquals(other) => other is HBitNot;
  bool dataEquals(HInstruction other) => true;
}

class HExit extends HControlFlow {
  HExit() : super(const <HInstruction>[]);
  toString() => 'exit';
  accept(HVisitor visitor) => visitor.visitExit(this);
}

class HGoto extends HControlFlow {
  HGoto() : super(const <HInstruction>[]);
  toString() => 'goto';
  accept(HVisitor visitor) => visitor.visitGoto(this);
}

abstract class HJump extends HControlFlow {
  final JumpTarget target;
  final LabelDefinition label;
  HJump(this.target)
      : label = null,
        super(const <HInstruction>[]);
  HJump.toLabel(LabelDefinition label)
      : label = label,
        target = label.target,
        super(const <HInstruction>[]);
}

class HBreak extends HJump {
  /// Signals that this is a special break instruction for the synthetic loop
  /// generated for a switch statement with continue statements. See
  /// [SsaFromAstMixin.buildComplexSwitchStatement] for detail.
  final bool breakSwitchContinueLoop;
  HBreak(JumpTarget target, {bool this.breakSwitchContinueLoop: false})
      : super(target);
  HBreak.toLabel(LabelDefinition label)
      : breakSwitchContinueLoop = false,
        super.toLabel(label);
  toString() => (label != null) ? 'break ${label.labelName}' : 'break';
  accept(HVisitor visitor) => visitor.visitBreak(this);
}

class HContinue extends HJump {
  HContinue(JumpTarget target) : super(target);
  HContinue.toLabel(LabelDefinition label) : super.toLabel(label);
  toString() => (label != null) ? 'continue ${label.labelName}' : 'continue';
  accept(HVisitor visitor) => visitor.visitContinue(this);
}

class HTry extends HControlFlow {
  HLocalValue exception;
  HBasicBlock catchBlock;
  HBasicBlock finallyBlock;
  HTry() : super(const <HInstruction>[]);
  toString() => 'try';
  accept(HVisitor visitor) => visitor.visitTry(this);
  HBasicBlock get joinBlock => this.block.successors.last;
}

// An [HExitTry] control flow node is used when the body of a try or
// the body of a catch contains a return, break or continue. To build
// the control flow graph, we explicitly mark the body that
// leads to one of this instruction a predecessor of catch and
// finally.
class HExitTry extends HControlFlow {
  HExitTry() : super(const <HInstruction>[]);
  toString() => 'exit try';
  accept(HVisitor visitor) => visitor.visitExitTry(this);
  HBasicBlock get bodyTrySuccessor => block.successors[0];
}

class HIf extends HConditionalBranch {
  HBlockFlow blockInformation = null;
  HIf(HInstruction condition) : super(<HInstruction>[condition]);
  toString() => 'if';
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
  HLoopBranch(HInstruction condition, [this.kind = CONDITION_FIRST_LOOP])
      : super(<HInstruction>[condition]);
  toString() => 'loop-branch';
  accept(HVisitor visitor) => visitor.visitLoopBranch(this);
}

class HConstant extends HInstruction {
  final ConstantValue constant;
  HConstant.internal(this.constant, TypeMask constantType)
      : super(<HInstruction>[], constantType);

  toString() => 'literal: ${constant.toStructuredText()}';
  accept(HVisitor visitor) => visitor.visitConstant(this);

  bool isConstant() => true;
  bool isConstantBoolean() => constant.isBool;
  bool isConstantNull() => constant.isNull;
  bool isConstantNumber() => constant.isNum;
  bool isConstantInteger() => constant.isInt;
  bool isConstantString() => constant.isString;
  bool isConstantList() => constant.isList;
  bool isConstantMap() => constant.isMap;
  bool isConstantFalse() => constant.isFalse;
  bool isConstantTrue() => constant.isTrue;

  bool isInterceptor(ClosedWorld closedWorld) => constant.isInterceptor;

  // Maybe avoid this if the literal is big?
  bool isCodeMotionInvariant() => true;

  set instructionType(type) {
    // Only lists can be specialized. The SSA builder uses the
    // inferrer for finding the type of a constant list. We should
    // have the constant know its type instead.
    if (!isConstantList()) return;
    super.instructionType = type;
  }
}

class HNot extends HInstruction {
  HNot(HInstruction value, TypeMask type) : super(<HInstruction>[value], type) {
    setUseGvn();
  }

  accept(HVisitor visitor) => visitor.visitNot(this);
  int typeCode() => HInstruction.NOT_TYPECODE;
  bool typeEquals(other) => other is HNot;
  bool dataEquals(HInstruction other) => true;
}

/**
  * An [HLocalValue] represents a local. Unlike [HParameterValue]s its
  * first use must be in an HLocalSet. That is, [HParameterValue]s have a
  * value from the start, whereas [HLocalValue]s need to be initialized first.
  */
class HLocalValue extends HInstruction {
  HLocalValue(Entity variable, TypeMask type) : super(<HInstruction>[], type) {
    sourceElement = variable;
  }

  toString() => 'local ${sourceElement.name}';
  accept(HVisitor visitor) => visitor.visitLocalValue(this);
}

class HParameterValue extends HLocalValue {
  HParameterValue(Entity variable, type) : super(variable, type);

  // [HParameterValue]s are either the value of the parameter (in fully SSA
  // converted code), or the mutable variable containing the value (in
  // incompletely SSA converted code, e.g. methods containing exceptions).
  bool usedAsVariable() {
    for (HInstruction user in usedBy) {
      if (user is HLocalGet) return true;
      if (user is HLocalSet && user.local == this) return true;
    }
    return false;
  }

  toString() => 'parameter ${sourceElement.name}';
  accept(HVisitor visitor) => visitor.visitParameterValue(this);
}

class HThis extends HParameterValue {
  HThis(ThisLocal element, TypeMask type) : super(element, type);

  ThisLocal get sourceElement => super.sourceElement;
  void set sourceElement(covariant ThisLocal local) {
    super.sourceElement = local;
  }

  accept(HVisitor visitor) => visitor.visitThis(this);

  bool isCodeMotionInvariant() => true;

  bool isInterceptor(ClosedWorld closedWorld) {
    return closedWorld.interceptorData
        .isInterceptedClass(sourceElement.enclosingClass);
  }

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
  HPhi(Local variable, List<HInstruction> inputs, TypeMask type)
      : super(inputs, type) {
    sourceElement = variable;
  }
  HPhi.noInputs(Local variable, TypeMask type)
      : this(variable, <HInstruction>[], type);
  HPhi.singleInput(Local variable, HInstruction input, TypeMask type)
      : this(variable, <HInstruction>[input], type);
  HPhi.manyInputs(Local variable, List<HInstruction> inputs, TypeMask type)
      : this(variable, inputs, type);

  void addInput(HInstruction input) {
    assert(isInBasicBlock());
    inputs.add(input);
    assert(inputs.length <= block.predecessors.length);
    input.usedBy.add(this);
  }

  toString() => 'phi $id';
  accept(HVisitor visitor) => visitor.visitPhi(this);
}

abstract class HRelational extends HInvokeBinary {
  bool usesBoolifiedInterceptor = false;
  HRelational(left, right, selector, type) : super(left, right, selector, type);
}

class HIdentity extends HRelational {
  // Cached codegen decision.
  String singleComparisonOp; // null, '===', '=='

  HIdentity(left, right, selector, type) : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitIdentity(this);

  BinaryOperation operation(ConstantSystem constantSystem) =>
      constantSystem.identity;
  int typeCode() => HInstruction.IDENTITY_TYPECODE;
  bool typeEquals(other) => other is HIdentity;
  bool dataEquals(HInstruction other) => true;
}

class HGreater extends HRelational {
  HGreater(left, right, selector, type) : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitGreater(this);

  BinaryOperation operation(ConstantSystem constantSystem) =>
      constantSystem.greater;
  int typeCode() => HInstruction.GREATER_TYPECODE;
  bool typeEquals(other) => other is HGreater;
  bool dataEquals(HInstruction other) => true;
}

class HGreaterEqual extends HRelational {
  HGreaterEqual(left, right, selector, type)
      : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitGreaterEqual(this);

  BinaryOperation operation(ConstantSystem constantSystem) =>
      constantSystem.greaterEqual;
  int typeCode() => HInstruction.GREATER_EQUAL_TYPECODE;
  bool typeEquals(other) => other is HGreaterEqual;
  bool dataEquals(HInstruction other) => true;
}

class HLess extends HRelational {
  HLess(left, right, selector, type) : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitLess(this);

  BinaryOperation operation(ConstantSystem constantSystem) =>
      constantSystem.less;
  int typeCode() => HInstruction.LESS_TYPECODE;
  bool typeEquals(other) => other is HLess;
  bool dataEquals(HInstruction other) => true;
}

class HLessEqual extends HRelational {
  HLessEqual(left, right, selector, type) : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitLessEqual(this);

  BinaryOperation operation(ConstantSystem constantSystem) =>
      constantSystem.lessEqual;
  int typeCode() => HInstruction.LESS_EQUAL_TYPECODE;
  bool typeEquals(other) => other is HLessEqual;
  bool dataEquals(HInstruction other) => true;
}

class HReturn extends HControlFlow {
  HReturn(HInstruction value, SourceInformation sourceInformation)
      : super(<HInstruction>[value]) {
    this.sourceInformation = sourceInformation;
  }
  toString() => 'return';
  accept(HVisitor visitor) => visitor.visitReturn(this);
}

class HThrowExpression extends HInstruction {
  HThrowExpression(HInstruction value, SourceInformation sourceInformation)
      : super(<HInstruction>[value], const TypeMask.nonNullEmpty()) {
    this.sourceInformation = sourceInformation;
  }
  toString() => 'throw expression';
  accept(HVisitor visitor) => visitor.visitThrowExpression(this);
  bool canThrow() => true;
}

class HAwait extends HInstruction {
  HAwait(HInstruction value, TypeMask type)
      : super(<HInstruction>[value], type);
  toString() => 'await';
  accept(HVisitor visitor) => visitor.visitAwait(this);
  // An await will throw if its argument is not a real future.
  bool canThrow() => true;
  SideEffects sideEffects = new SideEffects();
}

class HYield extends HInstruction {
  HYield(HInstruction value, this.hasStar)
      : super(<HInstruction>[value], const TypeMask.nonNullEmpty());
  bool hasStar;
  toString() => 'yield';
  accept(HVisitor visitor) => visitor.visitYield(this);
  bool canThrow() => false;
  SideEffects sideEffects = new SideEffects();
}

class HThrow extends HControlFlow {
  final bool isRethrow;
  HThrow(HInstruction value, SourceInformation sourceInformation,
      {this.isRethrow: false})
      : super(<HInstruction>[value]) {
    this.sourceInformation = sourceInformation;
  }
  toString() => 'throw';
  accept(HVisitor visitor) => visitor.visitThrow(this);
}

class HStatic extends HInstruction {
  final MemberEntity element;
  HStatic(this.element, type) : super(<HInstruction>[], type) {
    assert(element != null);
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    if (element.isAssignable) {
      sideEffects.setDependsOnStaticPropertyStore();
    }
    setUseGvn();
  }
  toString() => 'static ${element.name}';
  accept(HVisitor visitor) => visitor.visitStatic(this);

  int gvnHashCode() => super.gvnHashCode() ^ element.hashCode;
  int typeCode() => HInstruction.STATIC_TYPECODE;
  bool typeEquals(other) => other is HStatic;
  bool dataEquals(HStatic other) => element == other.element;
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

  HInterceptor(HInstruction receiver, TypeMask type)
      : super(<HInstruction>[receiver], type) {
    this.sourceInformation = receiver.sourceInformation;
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    setUseGvn();
  }

  String toString() => 'interceptor on $interceptedClasses';
  accept(HVisitor visitor) => visitor.visitInterceptor(this);
  HInstruction get receiver => inputs[0];

  bool get isConditionalConstantInterceptor => inputs.length == 2;
  HInstruction get conditionalConstantInterceptor => inputs[1];
  void set conditionalConstantInterceptor(HConstant constant) {
    assert(!isConditionalConstantInterceptor);
    inputs.add(constant);
  }

  bool isInterceptor(ClosedWorld closedWorld) => true;

  int typeCode() => HInstruction.INTERCEPTOR_TYPECODE;
  bool typeEquals(other) => other is HInterceptor;
  bool dataEquals(HInterceptor other) {
    return interceptedClasses == other.interceptedClasses ||
        (interceptedClasses.length == other.interceptedClasses.length &&
            interceptedClasses.containsAll(other.interceptedClasses));
  }
}

/**
 * A "one-shot" interceptor is a call to a synthetized method that
 * will fetch the interceptor of its first parameter, and make a call
 * on a given selector with the remaining parameters.
 *
 * In order to share the same optimizations with regular interceptor
 * calls, this class extends [HInvokeDynamic] and also has the null
 * constant as the first input.
 */
class HOneShotInterceptor extends HInvokeDynamic {
  Set<ClassEntity> interceptedClasses;
  HOneShotInterceptor(Selector selector, TypeMask mask,
      List<HInstruction> inputs, TypeMask type, this.interceptedClasses)
      : super(selector, mask, null, inputs, type, true) {
    assert(inputs[0] is HConstant);
    assert(inputs[0].isNull());
  }
  bool isCallOnInterceptor(ClosedWorld closedWorld) => true;

  String toString() => 'one shot interceptor: selector=$selector, mask=$mask';
  accept(HVisitor visitor) => visitor.visitOneShotInterceptor(this);
}

/** An [HLazyStatic] is a static that is initialized lazily at first read. */
class HLazyStatic extends HInstruction {
  final FieldEntity element;
  HLazyStatic(this.element, type) : super(<HInstruction>[], type) {
    // TODO(4931): The first access has side-effects, but we afterwards we
    // should be able to GVN.
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
  }

  toString() => 'lazy static ${element.name}';
  accept(HVisitor visitor) => visitor.visitLazyStatic(this);

  int typeCode() => 30;
  // TODO(4931): can we do better here?
  bool isCodeMotionInvariant() => false;
  bool canThrow() => true;
}

class HStaticStore extends HInstruction {
  MemberEntity element;
  HStaticStore(this.element, HInstruction value)
      : super(<HInstruction>[value], const TypeMask.nonNullEmpty()) {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    sideEffects.setChangesStaticProperty();
  }
  toString() => 'static store ${element.name}';
  accept(HVisitor visitor) => visitor.visitStaticStore(this);

  int typeCode() => HInstruction.STATIC_STORE_TYPECODE;
  bool typeEquals(other) => other is HStaticStore;
  bool dataEquals(HStaticStore other) => element == other.element;
  bool isJsStatement() => true;
}

class HLiteralList extends HInstruction {
  HLiteralList(List<HInstruction> inputs, TypeMask type) : super(inputs, type);
  toString() => 'literal list';
  accept(HVisitor visitor) => visitor.visitLiteralList(this);

  bool get isAllocation => true;
}

/**
 * The primitive array indexing operation. Note that this instruction
 * does not throw because we generate the checks explicitly.
 */
class HIndex extends HInstruction {
  final Selector selector;
  HIndex(
      HInstruction receiver, HInstruction index, this.selector, TypeMask type)
      : super(<HInstruction>[receiver, index], type) {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    sideEffects.setDependsOnIndexStore();
    setUseGvn();
  }

  String toString() => 'index operator';
  accept(HVisitor visitor) => visitor.visitIndex(this);

  HInstruction get receiver => inputs[0];
  HInstruction get index => inputs[1];

  // Implicit dependency on HBoundsCheck or constraints on index.
  // TODO(27272): Make HIndex dependent on bounds checking.
  bool get isMovable => false;

  HInstruction getDartReceiver(ClosedWorld closedWorld) => receiver;
  bool onlyThrowsNSM() => true;
  bool canThrow() => receiver.canBeNull();

  int typeCode() => HInstruction.INDEX_TYPECODE;
  bool typeEquals(HInstruction other) => other is HIndex;
  bool dataEquals(HIndex other) => true;
}

/**
 * The primitive array assignment operation. Note that this instruction
 * does not throw because we generate the checks explicitly.
 */
class HIndexAssign extends HInstruction {
  final Selector selector;
  HIndexAssign(HInstruction receiver, HInstruction index, HInstruction value,
      this.selector)
      : super(<HInstruction>[receiver, index, value],
            const TypeMask.nonNullEmpty()) {
    sideEffects.clearAllSideEffects();
    sideEffects.clearAllDependencies();
    sideEffects.setChangesIndex();
  }
  String toString() => 'index assign operator';
  accept(HVisitor visitor) => visitor.visitIndexAssign(this);

  HInstruction get receiver => inputs[0];
  HInstruction get index => inputs[1];
  HInstruction get value => inputs[2];

  // Implicit dependency on HBoundsCheck or constraints on index.
  // TODO(27272): Make HIndex dependent on bounds checking.
  bool get isMovable => false;

  HInstruction getDartReceiver(ClosedWorld closedWorld) => receiver;
  bool onlyThrowsNSM() => true;
  bool canThrow() => receiver.canBeNull();
}

class HIs extends HInstruction {
  /// A check against a raw type: 'o is int', 'o is A'.
  static const int RAW_CHECK = 0;

  /// A check against a type with type arguments: 'o is List<int>', 'o is C<T>'.
  static const int COMPOUND_CHECK = 1;

  /// A check against a single type variable: 'o is T'.
  static const int VARIABLE_CHECK = 2;

  final DartType typeExpression;
  final int kind;
  final bool useInstanceOf;

  HIs.direct(DartType typeExpression, HInstruction expression, TypeMask type)
      : this.internal(typeExpression, [expression], RAW_CHECK, type);

  // Pre-verified that the check can be done using 'instanceof'.
  HIs.instanceOf(
      DartType typeExpression, HInstruction expression, TypeMask type)
      : this.internal(typeExpression, [expression], RAW_CHECK, type,
            useInstanceOf: true);

  HIs.raw(DartType typeExpression, HInstruction expression,
      HInterceptor interceptor, TypeMask type)
      : this.internal(
            typeExpression, [expression, interceptor], RAW_CHECK, type);

  HIs.compound(DartType typeExpression, HInstruction expression,
      HInstruction call, TypeMask type)
      : this.internal(typeExpression, [expression, call], COMPOUND_CHECK, type);

  HIs.variable(DartType typeExpression, HInstruction expression,
      HInstruction call, TypeMask type)
      : this.internal(typeExpression, [expression, call], VARIABLE_CHECK, type);

  HIs.internal(
      this.typeExpression, List<HInstruction> inputs, this.kind, TypeMask type,
      {bool this.useInstanceOf: false})
      : super(inputs, type) {
    assert(kind >= RAW_CHECK && kind <= VARIABLE_CHECK);
    setUseGvn();
  }

  HInstruction get expression => inputs[0];

  HInstruction get interceptor {
    assert(kind == RAW_CHECK);
    return inputs.length > 1 ? inputs[1] : null;
  }

  HInstruction get checkCall {
    assert(kind == VARIABLE_CHECK || kind == COMPOUND_CHECK);
    return inputs[1];
  }

  bool get isRawCheck => kind == RAW_CHECK;
  bool get isVariableCheck => kind == VARIABLE_CHECK;
  bool get isCompoundCheck => kind == COMPOUND_CHECK;

  accept(HVisitor visitor) => visitor.visitIs(this);

  toString() => "$expression is $typeExpression";

  int typeCode() => HInstruction.IS_TYPECODE;

  bool typeEquals(HInstruction other) => other is HIs;

  bool dataEquals(HIs other) {
    return typeExpression == other.typeExpression && kind == other.kind;
  }
}

/**
 * HIsViaInterceptor is a late-stage instruction for a type test that can be
 * done entirely on an interceptor.  It is not a HCheck because the checked
 * input is not one of the inputs.
 */
class HIsViaInterceptor extends HLateInstruction {
  final DartType typeExpression;
  HIsViaInterceptor(
      this.typeExpression, HInstruction interceptor, TypeMask type)
      : super(<HInstruction>[interceptor], type) {
    setUseGvn();
  }

  HInstruction get interceptor => inputs[0];

  accept(HVisitor visitor) => visitor.visitIsViaInterceptor(this);
  toString() => "$interceptor is $typeExpression";
  int typeCode() => HInstruction.IS_VIA_INTERCEPTOR_TYPECODE;
  bool typeEquals(HInstruction other) => other is HIsViaInterceptor;
  bool dataEquals(HIs other) {
    return typeExpression == other.typeExpression;
  }
}

class HTypeConversion extends HCheck {
  // Values for [kind].
  static const int CHECKED_MODE_CHECK = 0;
  static const int ARGUMENT_TYPE_CHECK = 1;
  static const int CAST_TYPE_CHECK = 2;
  static const int BOOLEAN_CONVERSION_CHECK = 3;
  static const int RECEIVER_TYPE_CHECK = 4;

  final DartType typeExpression;
  final int kind;
  // [receiverTypeCheckSelector] is the selector used for a receiver type check
  // on open-coded operators, e.g. the not-null check on `x` in `x + 1` would be
  // compiled to the following, for which we need the selector `$add`.
  //
  //     if (typeof x != "number") x.$add();
  //
  final Selector receiverTypeCheckSelector;

  TypeMask checkedType; // Not final because we refine it.
  TypeMask inputType; // Holds input type for codegen after HTypeKnown removal.

  HTypeConversion(
      this.typeExpression, this.kind, TypeMask type, HInstruction input,
      {this.receiverTypeCheckSelector})
      : checkedType = type,
        super(<HInstruction>[input], type) {
    assert(!isReceiverTypeCheck || receiverTypeCheckSelector != null);
    assert(typeExpression == null || !typeExpression.isTypedef);
    sourceElement = input.sourceElement;
  }

  HTypeConversion.withTypeRepresentation(this.typeExpression, this.kind,
      TypeMask type, HInstruction input, HInstruction typeRepresentation)
      : checkedType = type,
        receiverTypeCheckSelector = null,
        super(<HInstruction>[input, typeRepresentation], type) {
    assert(!typeExpression.isTypedef);
    sourceElement = input.sourceElement;
  }

  HTypeConversion.viaMethodOnType(this.typeExpression, this.kind, TypeMask type,
      HInstruction reifiedType, HInstruction input)
      : checkedType = type,
        receiverTypeCheckSelector = null,
        super(<HInstruction>[reifiedType, input], type) {
    // This form is currently used only for function types.
    assert(typeExpression.isFunctionType);
    assert(kind == CHECKED_MODE_CHECK || kind == CAST_TYPE_CHECK);
    sourceElement = input.sourceElement;
  }

  bool get hasTypeRepresentation {
    return typeExpression.isInterfaceType && inputs.length > 1;
  }

  HInstruction get typeRepresentation => inputs[1];

  HInstruction get checkedInput => super.checkedInput;

  HInstruction convertType(ClosedWorld closedWorld, DartType type, int kind) {
    if (typeExpression == type) {
      // Don't omit a boolean conversion (which doesn't allow `null`) unless
      // this type conversion is already a boolean conversion.
      if (kind != BOOLEAN_CONVERSION_CHECK || isBooleanConversionCheck) {
        return this;
      }
    }
    return super.convertType(closedWorld, type, kind);
  }

  bool get isCheckedModeCheck {
    return kind == CHECKED_MODE_CHECK || kind == BOOLEAN_CONVERSION_CHECK;
  }

  bool get isArgumentTypeCheck => kind == ARGUMENT_TYPE_CHECK;
  bool get isReceiverTypeCheck => kind == RECEIVER_TYPE_CHECK;
  bool get isCastTypeCheck => kind == CAST_TYPE_CHECK;
  bool get isBooleanConversionCheck => kind == BOOLEAN_CONVERSION_CHECK;

  accept(HVisitor visitor) => visitor.visitTypeConversion(this);

  bool isJsStatement() => isControlFlow();
  bool isControlFlow() => isArgumentTypeCheck || isReceiverTypeCheck;

  int typeCode() => HInstruction.TYPE_CONVERSION_TYPECODE;
  bool typeEquals(HInstruction other) => other is HTypeConversion;
  bool isCodeMotionInvariant() => false;

  bool dataEquals(HTypeConversion other) {
    return kind == other.kind &&
        typeExpression == other.typeExpression &&
        checkedType == other.checkedType &&
        receiverTypeCheckSelector == other.receiverTypeCheckSelector;
  }
}

/// The [HTypeKnown] instruction marks a value with a refined type.
class HTypeKnown extends HCheck {
  TypeMask knownType;
  final bool _isMovable;

  HTypeKnown.pinned(TypeMask knownType, HInstruction input)
      : this.knownType = knownType,
        this._isMovable = false,
        super(<HInstruction>[input], knownType);

  HTypeKnown.witnessed(
      TypeMask knownType, HInstruction input, HInstruction witness)
      : this.knownType = knownType,
        this._isMovable = true,
        super(<HInstruction>[input, witness], knownType);

  toString() => 'TypeKnown $knownType';
  accept(HVisitor visitor) => visitor.visitTypeKnown(this);

  bool isJsStatement() => false;
  bool isControlFlow() => false;
  bool canThrow() => false;

  bool get isPinned => inputs.length == 1;

  HInstruction get witness => inputs.length == 2 ? inputs[1] : null;

  int typeCode() => HInstruction.TYPE_KNOWN_TYPECODE;
  bool typeEquals(HInstruction other) => other is HTypeKnown;
  bool isCodeMotionInvariant() => true;
  bool get isMovable => _isMovable && useGvn();

  bool dataEquals(HTypeKnown other) {
    return knownType == other.knownType &&
        instructionType == other.instructionType;
  }
}

class HRangeConversion extends HCheck {
  HRangeConversion(HInstruction input, type)
      : super(<HInstruction>[input], type) {
    sourceElement = input.sourceElement;
  }

  bool get isMovable => false;

  accept(HVisitor visitor) => visitor.visitRangeConversion(this);
}

class HStringConcat extends HInstruction {
  HStringConcat(HInstruction left, HInstruction right, TypeMask type)
      : super(<HInstruction>[left, right], type) {
    // TODO(sra): Until Issue 9293 is fixed, this false dependency keeps the
    // concats bunched with stringified inputs for much better looking code with
    // fewer temps.
    sideEffects.setDependsOnSomething();
  }

  HInstruction get left => inputs[0];
  HInstruction get right => inputs[1];

  accept(HVisitor visitor) => visitor.visitStringConcat(this);
  toString() => "string concat";
}

/**
 * The part of string interpolation which converts and interpolated expression
 * into a String value.
 */
class HStringify extends HInstruction {
  HStringify(HInstruction input, TypeMask type)
      : super(<HInstruction>[input], type) {
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
  }

  accept(HVisitor visitor) => visitor.visitStringify(this);
  toString() => "stringify";
}

/** Non-block-based (aka. traditional) loop information. */
class HLoopInformation {
  final HBasicBlock header;
  final List<HBasicBlock> blocks;
  final List<HBasicBlock> backEdges;
  final List<LabelDefinition> labels;
  final JumpTarget target;

  /** Corresponding block information for the loop. */
  HLoopBlockInformation loopBlockInformation;

  HLoopInformation(this.header, this.target, this.labels)
      : blocks = new List<HBasicBlock>(),
        backEdges = new List<HBasicBlock>();

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

/**
 * Embedding of a [HBlockInformation] for block-structure based traversal
 * in a dominator based flow traversal by attaching it to a basic block.
 * To go back to dominator-based traversal, a [HSubGraphBlockInformation]
 * structure can be added in the block structure.
 */
class HBlockFlow {
  final HBlockInformation body;
  final HBasicBlock continuation;
  HBlockFlow(this.body, this.continuation);
}

/**
 * Information about a syntactic-like structure.
 */
abstract class HBlockInformation {
  HBasicBlock get start;
  HBasicBlock get end;
  bool accept(HBlockInformationVisitor visitor);
}

/**
 * Information about a statement-like structure.
 */
abstract class HStatementInformation extends HBlockInformation {
  bool accept(HStatementInformationVisitor visitor);
}

/**
 * Information about an expression-like structure.
 */
abstract class HExpressionInformation extends HBlockInformation {
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

/**
 * Generic class wrapping a [SubGraph] as a block-information until
 * all structures are handled properly.
 */
class HSubGraphBlockInformation implements HStatementInformation {
  final SubGraph subGraph;
  HSubGraphBlockInformation(this.subGraph);

  HBasicBlock get start => subGraph.start;
  HBasicBlock get end => subGraph.end;

  bool accept(HStatementInformationVisitor visitor) =>
      visitor.visitSubGraphInfo(this);
}

/**
 * Generic class wrapping a [SubExpression] as a block-information until
 * expressions structures are handled properly.
 */
class HSubExpressionBlockInformation implements HExpressionInformation {
  final SubExpression subExpression;
  HSubExpressionBlockInformation(this.subExpression);

  HBasicBlock get start => subExpression.start;
  HBasicBlock get end => subExpression.end;

  HInstruction get conditionExpression => subExpression.conditionExpression;

  bool accept(HExpressionInformationVisitor visitor) =>
      visitor.visitSubExpressionInfo(this);
}

/** A sequence of separate statements. */
class HStatementSequenceInformation implements HStatementInformation {
  final List<HStatementInformation> statements;
  HStatementSequenceInformation(this.statements);

  HBasicBlock get start => statements[0].start;
  HBasicBlock get end => statements.last.end;

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

  HBasicBlock get start => body.start;
  HBasicBlock get end => body.end;

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

  HBasicBlock get end {
    if (updates != null) return updates.end;
    if (kind == DO_WHILE_LOOP && condition != null) {
      return condition.end;
    }
    return body.end;
  }

  bool accept(HStatementInformationVisitor visitor) =>
      visitor.visitLoopInfo(this);
}

class HIfBlockInformation implements HStatementInformation {
  final HExpressionInformation condition;
  final HStatementInformation thenGraph;
  final HStatementInformation elseGraph;
  HIfBlockInformation(this.condition, this.thenGraph, this.elseGraph);

  HBasicBlock get start => condition.start;
  HBasicBlock get end => elseGraph == null ? thenGraph.end : elseGraph.end;

  bool accept(HStatementInformationVisitor visitor) =>
      visitor.visitIfInfo(this);
}

class HAndOrBlockInformation implements HExpressionInformation {
  final bool isAnd;
  final HExpressionInformation left;
  final HExpressionInformation right;
  HAndOrBlockInformation(this.isAnd, this.left, this.right);

  HBasicBlock get start => left.start;
  HBasicBlock get end => right.end;

  // We don't currently use HAndOrBlockInformation.
  HInstruction get conditionExpression {
    return null;
  }

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

  HBasicBlock get start => body.start;
  HBasicBlock get end =>
      finallyBlock == null ? catchBlock.end : finallyBlock.end;

  bool accept(HStatementInformationVisitor visitor) =>
      visitor.visitTryInfo(this);
}

class HSwitchBlockInformation implements HStatementInformation {
  final HExpressionInformation expression;
  final List<HStatementInformation> statements;
  final JumpTarget target;
  final List<LabelDefinition> labels;

  HSwitchBlockInformation(
      this.expression, this.statements, this.target, this.labels);

  HBasicBlock get start => expression.start;
  HBasicBlock get end {
    // We don't create a switch block if there are no cases.
    assert(!statements.isEmpty);
    return statements.last.end;
  }

  bool accept(HStatementInformationVisitor visitor) =>
      visitor.visitSwitchInfo(this);
}

/// Reads raw reified type info from an object.
class HTypeInfoReadRaw extends HInstruction {
  HTypeInfoReadRaw(HInstruction receiver, TypeMask instructionType)
      : super(<HInstruction>[receiver], instructionType) {
    setUseGvn();
  }

  accept(HVisitor visitor) => visitor.visitTypeInfoReadRaw(this);

  bool canThrow() => false;

  int typeCode() => HInstruction.TYPE_INFO_READ_RAW_TYPECODE;
  bool typeEquals(HInstruction other) => other is HTypeInfoReadRaw;

  bool dataEquals(HTypeInfoReadRaw other) {
    return true;
  }
}

/// Reads a type variable from an object. The read may be a simple indexing of
/// the type parameters or it may require 'substitution'.
class HTypeInfoReadVariable extends HInstruction {
  /// The type variable being read.
  final TypeVariableType variable;

  HTypeInfoReadVariable(
      this.variable, HInstruction receiver, TypeMask instructionType)
      : super(<HInstruction>[receiver], instructionType) {
    setUseGvn();
  }

  HInstruction get object => inputs.single;

  accept(HVisitor visitor) => visitor.visitTypeInfoReadVariable(this);

  bool canThrow() => false;

  int typeCode() => HInstruction.TYPE_INFO_READ_VARIABLE_TYPECODE;
  bool typeEquals(HInstruction other) => other is HTypeInfoReadVariable;

  bool dataEquals(HTypeInfoReadVariable other) {
    return variable == other.variable;
  }

  String toString() => 'HTypeInfoReadVariable($variable)';
}

enum TypeInfoExpressionKind { COMPLETE, INSTANCE }

/// Constructs a representation of a closed or ground-term type (that is, a type
/// without type variables).
///
/// There are two forms:
///
/// - COMPLETE: A complete form that is self contained, used for the values of
///   type parameters and non-raw is-checks.
///
/// - INSTANCE: A headless flat form for representing the sequence of values of
///   the type parameters of an instance of a generic type.
///
/// The COMPLETE form value is constructed from [dartType] by replacing the type
/// variables with consecutive values from [inputs], in the order generated by
/// [DartType.forEachTypeVariable].  The type variables in [dartType] are
/// treated as 'holes' in the term, which means that it must be ensured at
/// construction, that duplicate occurences of a type variable in [dartType] are
/// assigned the same value.
///
/// The INSTANCE form is constructed as a list of [inputs]. This is the same as
/// the COMPLETE form for the 'thisType', except the root term's type is
/// missing; this is implicit as the raw type of instance.  The [dartType] of
/// the INSTANCE form must be the thisType of some class.
///
/// We want to remove the constrains on the INSTANCE form. In the meantime we
/// get by with a tree of TypeExpressions.  Consider:
///
///     class Foo<T> {
///       ... new Set<List<T>>()
///     }
///     class Set<E1> {
///       factory Set() => new _LinkedHashSet<E1>();
///     }
///     class List<E2> { ... }
///     class _LinkedHashSet<E3> { ... }
///
/// After inlining the factory constructor for `Set<E1>`, the HCreate should
/// have type `_LinkedHashSet<List<T>>` and the TypeExpression should be a tree:
///
///    HCreate(dartType: _LinkedHashSet<List<T>>,
///        [], // No arguments
///        HTypeInfoExpression(INSTANCE,
///            dartType: _LinkedHashSet<E3>, // _LinkedHashSet's thisType
///            HTypeInfoExpression(COMPLETE,  // E3 = List<T>
///                dartType: List<E2>,
///                HTypeInfoReadVariable(this, T)))) // E2 = T

// TODO(sra): The INSTANCE form requires the actual instance for full
// interpretation. If the COMPLETE form was used on instances, then we could
// simplify HTypeInfoReadVariable without an object.

class HTypeInfoExpression extends HInstruction {
  final TypeInfoExpressionKind kind;
  final DartType dartType;
  HTypeInfoExpression(this.kind, this.dartType, List<HInstruction> inputs,
      TypeMask instructionType)
      : super(inputs, instructionType) {
    setUseGvn();
  }

  accept(HVisitor visitor) => visitor.visitTypeInfoExpression(this);

  bool canThrow() => false;

  int typeCode() => HInstruction.TYPE_INFO_EXPRESSION_TYPECODE;
  bool typeEquals(HInstruction other) => other is HTypeInfoExpression;

  bool dataEquals(HTypeInfoExpression other) {
    return kind == other.kind && dartType == other.dartType;
  }

  String toString() => 'HTypeInfoExpression($kindAsString, $dartType)';

  // ignore: MISSING_RETURN
  String get kindAsString {
    switch (kind) {
      case TypeInfoExpressionKind.COMPLETE:
        return 'COMPLETE';
      case TypeInfoExpressionKind.INSTANCE:
        return 'INSTANCE';
    }
  }
}
