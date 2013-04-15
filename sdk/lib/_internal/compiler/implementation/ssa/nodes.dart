// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

abstract class HVisitor<R> {
  R visitAdd(HAdd node);
  R visitBailoutTarget(HBailoutTarget node);
  R visitBitAnd(HBitAnd node);
  R visitBitNot(HBitNot node);
  R visitBitOr(HBitOr node);
  R visitBitXor(HBitXor node);
  R visitBoolify(HBoolify node);
  R visitBoundsCheck(HBoundsCheck node);
  R visitBreak(HBreak node);
  R visitConstant(HConstant node);
  R visitContinue(HContinue node);
  R visitDivide(HDivide node);
  R visitExit(HExit node);
  R visitExitTry(HExitTry node);
  R visitFieldGet(HFieldGet node);
  R visitFieldSet(HFieldSet node);
  R visitForeign(HForeign node);
  R visitForeignNew(HForeignNew node);
  R visitGoto(HGoto node);
  R visitGreater(HGreater node);
  R visitGreaterEqual(HGreaterEqual node);
  R visitIdentity(HIdentity node);
  R visitIf(HIf node);
  R visitIndex(HIndex node);
  R visitIndexAssign(HIndexAssign node);
  R visitIntegerCheck(HIntegerCheck node);
  R visitInterceptor(HInterceptor node);
  R visitInvokeClosure(HInvokeClosure node);
  R visitInvokeDynamicGetter(HInvokeDynamicGetter node);
  R visitInvokeDynamicMethod(HInvokeDynamicMethod node);
  R visitInvokeDynamicSetter(HInvokeDynamicSetter node);
  R visitInvokeStatic(HInvokeStatic node);
  R visitInvokeSuper(HInvokeSuper node);
  R visitIs(HIs node);
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
  R visitOneShotInterceptor(HOneShotInterceptor);
  R visitParameterValue(HParameterValue node);
  R visitPhi(HPhi node);
  R visitRangeConversion(HRangeConversion node);
  R visitReturn(HReturn node);
  R visitShiftLeft(HShiftLeft node);
  R visitStatic(HStatic node);
  R visitStaticStore(HStaticStore node);
  R visitStringConcat(HStringConcat node);
  R visitStringify(HStringify node);
  R visitSubtract(HSubtract node);
  R visitSwitch(HSwitch node);
  R visitThis(HThis node);
  R visitThrow(HThrow node);
  R visitThrowExpression(HThrowExpression node);
  R visitTry(HTry node);
  R visitTypeGuard(HTypeGuard node);
  R visitTypeConversion(HTypeConversion node);
}

abstract class HGraphVisitor {
  visitDominatorTree(HGraph graph) {
    void visitBasicBlockAndSuccessors(HBasicBlock block) {
      visitBasicBlock(block);
      List dominated = block.dominatedBlocks;
      for (int i = 0; i < dominated.length; i++) {
        visitBasicBlockAndSuccessors(dominated[i]);
      }
    }

    visitBasicBlockAndSuccessors(graph.entry);
  }

  visitPostDominatorTree(HGraph graph) {
    void visitBasicBlockAndSuccessors(HBasicBlock block) {
      List dominated = block.dominatedBlocks;
      for (int i = dominated.length - 1; i >= 0; i--) {
        visitBasicBlockAndSuccessors(dominated[i]);
      }
      visitBasicBlock(block);
    }

    visitBasicBlockAndSuccessors(graph.entry);
  }

  visitBasicBlock(HBasicBlock block);
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
  HBasicBlock entry;
  HBasicBlock exit;
  HThis thisInstruction;
  /// Receiver parameter, set for methods using interceptor calling convention.
  HParameterValue explicitReceiverParameter;
  bool isRecursiveMethod = false;
  bool calledInLoop = false;
  final List<HBasicBlock> blocks;

  // We canonicalize all constants used within a graph so we do not
  // have to worry about them for global value numbering.
  Map<Constant, HConstant> constants;

  HGraph()
      : blocks = new List<HBasicBlock>(),
        constants = new Map<Constant, HConstant>() {
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

  HBasicBlock addNewLoopHeaderBlock(TargetElement target,
                                    List<LabelElement> labels) {
    HBasicBlock result = addNewBlock();
    result.loopInformation =
        new HLoopInformation(result, target, labels);
    return result;
  }

  static HType mapConstantTypeToSsaType(Constant constant) {
    if (constant.isNull()) return HType.NULL;
    if (constant.isBool()) return HType.BOOLEAN;
    if (constant.isInt()) return HType.INTEGER;
    if (constant.isDouble()) return HType.DOUBLE;
    if (constant.isString()) return HType.STRING;
    if (constant.isList()) return HType.READABLE_ARRAY;
    if (constant.isFunction()) return HType.UNKNOWN;
    if (constant.isSentinel()) return HType.UNKNOWN;
    // TODO(sra): What is the type of the prototype of an interceptor?
    if (constant.isInterceptor()) return HType.UNKNOWN;
    // TODO(kasperl): This seems a bit fishy, but we do not have the
    // compiler at hand so we cannot use the usual HType factory
    // methods. At some point this should go away.
    ObjectConstant objectConstant = constant;
    TypeMask mask = new TypeMask.nonNullExact(objectConstant.type);
    return new HBoundedType(mask);
  }

  HConstant addConstant(Constant constant) {
    HConstant result = constants[constant];
    if (result == null) {
      HType type = mapConstantTypeToSsaType(constant);
      result = new HConstant.internal(constant, type);
      entry.addAtExit(result);
      constants[constant] = result;
    } else if (result.block == null) {
      // The constant was not used anymore.
      entry.addAtExit(result);
    }
    return result;
  }

  HConstant addConstantInt(int i, ConstantSystem constantSystem) {
    return addConstant(constantSystem.createInt(i));
  }

  HConstant addConstantDouble(double d, ConstantSystem constantSystem) {
    return addConstant(constantSystem.createDouble(d));
  }

  HConstant addConstantString(DartString str,
                              Node diagnosticNode,
                              ConstantSystem constantSystem) {
    return addConstant(constantSystem.createString(str, diagnosticNode));
  }

  HConstant addConstantBool(bool value, ConstantSystem constantSystem) {
    return addConstant(constantSystem.createBool(value));
  }

  HConstant addConstantNull(ConstantSystem constantSystem) {
    return addConstant(constantSystem.createNull());
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
  visitBailoutTarget(HBailoutTarget node) => visitInstruction(node);
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
  visitDivide(HDivide node) => visitBinaryArithmetic(node);
  visitExit(HExit node) => visitControlFlow(node);
  visitExitTry(HExitTry node) => visitControlFlow(node);
  visitFieldGet(HFieldGet node) => visitFieldAccess(node);
  visitFieldSet(HFieldSet node) => visitFieldAccess(node);
  visitForeign(HForeign node) => visitInstruction(node);
  visitForeignNew(HForeignNew node) => visitForeign(node);
  visitGoto(HGoto node) => visitControlFlow(node);
  visitGreater(HGreater node) => visitRelational(node);
  visitGreaterEqual(HGreaterEqual node) => visitRelational(node);
  visitIdentity(HIdentity node) => visitRelational(node);
  visitIf(HIf node) => visitConditionalBranch(node);
  visitIndex(HIndex node) => visitInstruction(node);
  visitIndexAssign(HIndexAssign node) => visitInstruction(node);
  visitIntegerCheck(HIntegerCheck node) => visitCheck(node);
  visitInterceptor(HInterceptor node) => visitInstruction(node);
  visitInvokeClosure(HInvokeClosure node)
      => visitInvokeDynamic(node);
  visitInvokeDynamicMethod(HInvokeDynamicMethod node)
      => visitInvokeDynamic(node);
  visitInvokeDynamicGetter(HInvokeDynamicGetter node)
      => visitInvokeDynamicField(node);
  visitInvokeDynamicSetter(HInvokeDynamicSetter node)
      => visitInvokeDynamicField(node);
  visitInvokeStatic(HInvokeStatic node) => visitInvoke(node);
  visitInvokeSuper(HInvokeSuper node) => visitInvoke(node);
  visitJump(HJump node) => visitControlFlow(node);
  visitLazyStatic(HLazyStatic node) => visitInstruction(node);
  visitLess(HLess node) => visitRelational(node);
  visitLessEqual(HLessEqual node) => visitRelational(node);
  visitLiteralList(HLiteralList node) => visitInstruction(node);
  visitLocalGet(HLocalGet node) => visitFieldAccess(node);
  visitLocalSet(HLocalSet node) => visitFieldAccess(node);
  visitLocalValue(HLocalValue node) => visitInstruction(node);
  visitLoopBranch(HLoopBranch node) => visitConditionalBranch(node);
  visitNegate(HNegate node) => visitInvokeUnary(node);
  visitNot(HNot node) => visitInstruction(node);
  visitOneShotInterceptor(HOneShotInterceptor node)
      => visitInvokeDynamic(node);
  visitPhi(HPhi node) => visitInstruction(node);
  visitMultiply(HMultiply node) => visitBinaryArithmetic(node);
  visitParameterValue(HParameterValue node) => visitLocalValue(node);
  visitRangeConversion(HRangeConversion node) => visitCheck(node);
  visitReturn(HReturn node) => visitControlFlow(node);
  visitShiftLeft(HShiftLeft node) => visitBinaryBitOp(node);
  visitSubtract(HSubtract node) => visitBinaryArithmetic(node);
  visitSwitch(HSwitch node) => visitControlFlow(node);
  visitStatic(HStatic node) => visitInstruction(node);
  visitStaticStore(HStaticStore node) => visitInstruction(node);
  visitStringConcat(HStringConcat node) => visitInstruction(node);
  visitStringify(HStringify node) => visitInstruction(node);
  visitThis(HThis node) => visitParameterValue(node);
  visitThrow(HThrow node) => visitControlFlow(node);
  visitThrowExpression(HThrowExpression node) => visitInstruction(node);
  visitTry(HTry node) => visitControlFlow(node);
  visitTypeGuard(HTypeGuard node) => visitCheck(node);
  visitIs(HIs node) => visitInstruction(node);
  visitTypeConversion(HTypeConversion node) => visitCheck(node);
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
  const SubExpression(HBasicBlock start, HBasicBlock end)
      : super(start, end);

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
  List<HBailoutTarget> bailoutTargets;

  final List<HBasicBlock> predecessors;
  List<HBasicBlock> successors;

  HBasicBlock dominator = null;
  final List<HBasicBlock> dominatedBlocks;

  HBasicBlock() : this.withId(null);
  HBasicBlock.withId(this.id)
      : phis = new HInstructionList(),
        predecessors = <HBasicBlock>[],
        successors = const <HBasicBlock>[],
        dominatedBlocks = <HBasicBlock>[],
        bailoutTargets = <HBailoutTarget>[];

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
    blockFlow != null &&
    blockFlow.body is HLabeledBlockInformation;

  HBasicBlock get enclosingLoopHeader {
    if (isLoopHeader()) return this;
    return parentLoopHeader;
  }

  bool hasBailoutTargets() => !bailoutTargets.isEmpty;

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
    assert(instruction is !HPhi);
    internalAddBefore(first, instruction);
    instruction.notifyAddedToBlock(this);
  }

  void addAtExit(HInstruction instruction) {
    assert(isClosed());
    assert(last is HControlFlow);
    assert(instruction is !HPhi);
    internalAddBefore(last, instruction);
    instruction.notifyAddedToBlock(this);
  }

  void moveAtExit(HInstruction instruction) {
    assert(instruction is !HPhi);
    assert(instruction.isInBasicBlock());
    assert(isClosed());
    assert(last is HControlFlow);
    internalAddBefore(last, instruction);
    instruction.block = this;
    assert(isValid());
  }

  void add(HInstruction instruction) {
    assert(instruction is !HControlFlow);
    assert(instruction is !HPhi);
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
    assert(cursor is !HPhi);
    assert(instruction is !HPhi);
    assert(isOpen() || isClosed());
    internalAddAfter(cursor, instruction);
    instruction.notifyAddedToBlock(this);
  }

  void addBefore(HInstruction cursor, HInstruction instruction) {
    assert(cursor is !HPhi);
    assert(instruction is !HPhi);
    assert(isOpen() || isClosed());
    internalAddBefore(cursor, instruction);
    instruction.notifyAddedToBlock(this);
  }

  void remove(HInstruction instruction) {
    assert(isOpen() || isClosed());
    assert(instruction is !HPhi);
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
    Link<HCheck> better = const Link<HCheck>();
    for (HInstruction user in to.usedBy) {
      if (user is HCheck && identical((user as HCheck).checkedInput, to)) {
        better = better.prepend(user);
      }
    }

    if (better.isEmpty) return rewrite(from, to);

    L1: for (HInstruction user in from.usedBy) {
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

  // TODO(ngeoffray): Cache the information if this method ends up
  // being hot.
  bool dominates(HBasicBlock other) {
    do {
      if (identical(this, other)) return true;
      other = other.dominator;
    } while (other != null && other.id >= id);
    return false;
  }
}


abstract class HInstruction implements Spannable {
  Element sourceElement;
  SourceFileLocation sourcePosition;

  final int id;
  static int idCounter;

  final List<HInstruction> inputs;
  final List<HInstruction> usedBy;

  HBasicBlock block;
  HInstruction previous = null;
  HInstruction next = null;
  int flags = 0;

  // Changes flags.
  static const int FLAG_CHANGES_INDEX = 0;
  static const int FLAG_CHANGES_INSTANCE_PROPERTY = FLAG_CHANGES_INDEX + 1;
  static const int FLAG_CHANGES_STATIC_PROPERTY
      = FLAG_CHANGES_INSTANCE_PROPERTY + 1;
  static const int FLAG_CHANGES_COUNT = FLAG_CHANGES_STATIC_PROPERTY + 1;

  // Depends flags (one for each changes flag).
  static const int FLAG_DEPENDS_ON_INDEX_STORE = FLAG_CHANGES_COUNT;
  static const int FLAG_DEPENDS_ON_INSTANCE_PROPERTY_STORE =
      FLAG_DEPENDS_ON_INDEX_STORE + 1;
  static const int FLAG_DEPENDS_ON_STATIC_PROPERTY_STORE =
      FLAG_DEPENDS_ON_INSTANCE_PROPERTY_STORE + 1;
  static const int FLAG_DEPENDS_ON_COUNT =
      FLAG_DEPENDS_ON_STATIC_PROPERTY_STORE + 1;

  // Other flags.
  static const int FLAG_USE_GVN = FLAG_DEPENDS_ON_COUNT;

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
  static const int BAILOUT_TARGET_TYPECODE = 25;
  static const int INVOKE_STATIC_TYPECODE = 26;
  static const int INDEX_TYPECODE = 27;
  static const int IS_TYPECODE = 28;
  static const int INVOKE_DYNAMIC_TYPECODE = 29;

  HInstruction(this.inputs) : id = idCounter++, usedBy = <HInstruction>[];

  int get hashCode => id;

  bool getFlag(int position) => (flags & (1 << position)) != 0;
  void setFlag(int position) { flags |= (1 << position); }
  void clearFlag(int position) { flags &= ~(1 << position); }

  static int computeDependsOnFlags(int flags) => flags << FLAG_CHANGES_COUNT;

  int getChangesFlags() => flags & ((1 << FLAG_CHANGES_COUNT) - 1);
  int getDependsOnFlags() {
    return (flags & ((1 << FLAG_DEPENDS_ON_COUNT) - 1)) >> FLAG_CHANGES_COUNT;
  }

  bool hasSideEffects() => getChangesFlags() != 0;
  bool dependsOnSomething() => getDependsOnFlags() != 0;

  void setAllSideEffects() { flags |= ((1 << FLAG_CHANGES_COUNT) - 1); }
  void clearAllSideEffects() { flags &= ~((1 << FLAG_CHANGES_COUNT) - 1); }

  void setDependsOnSomething() {
    int count = FLAG_DEPENDS_ON_COUNT - FLAG_CHANGES_COUNT;
    flags |= (((1 << count) - 1) << FLAG_CHANGES_COUNT);
  }
  void clearAllDependencies() {
    int count = FLAG_DEPENDS_ON_COUNT - FLAG_CHANGES_COUNT;
    flags &= ~(((1 << count) - 1) << FLAG_CHANGES_COUNT);
  }

  bool dependsOnStaticPropertyStore() {
    return getFlag(FLAG_DEPENDS_ON_STATIC_PROPERTY_STORE);
  }
  void setDependsOnStaticPropertyStore() {
    setFlag(FLAG_DEPENDS_ON_STATIC_PROPERTY_STORE);
  }
  void setChangesStaticProperty() { setFlag(FLAG_CHANGES_STATIC_PROPERTY); }

  bool dependsOnIndexStore() => getFlag(FLAG_DEPENDS_ON_INDEX_STORE);
  void setDependsOnIndexStore() { setFlag(FLAG_DEPENDS_ON_INDEX_STORE); }
  void setChangesIndex() { setFlag(FLAG_CHANGES_INDEX); }

  bool dependsOnInstancePropertyStore() {
    return getFlag(FLAG_DEPENDS_ON_INSTANCE_PROPERTY_STORE);
  }
  void setDependsOnInstancePropertyStore() {
    setFlag(FLAG_DEPENDS_ON_INSTANCE_PROPERTY_STORE);
  }
  void setChangesInstanceProperty() { setFlag(FLAG_CHANGES_INSTANCE_PROPERTY); }

  bool useGvn() => getFlag(FLAG_USE_GVN);
  void setUseGvn() { setFlag(FLAG_USE_GVN); }

  void updateInput(int i, HInstruction insn) {
    inputs[i] = insn;
  }

  /**
   * A pure instruction is an instruction that does not have any side
   * effect, nor any dependency. They can be moved anywhere in the
   * graph.
   */
  bool isPure() => !hasSideEffects() && !dependsOnSomething() && !canThrow();

  // Can this node throw an exception?
  bool canThrow() => false;

  // Does this node potentially affect control flow.
  bool isControlFlow() => false;

  // All isFunctions work on the propagated types.
  bool isArray() => instructionType.isArray();
  bool isReadableArray() => instructionType.isReadableArray();
  bool isMutableArray() => instructionType.isMutableArray();
  bool isExtendableArray() => instructionType.isExtendableArray();
  bool isFixedArray() => instructionType.isFixedArray();
  bool isBoolean() => instructionType.isBoolean();
  bool isInteger() => instructionType.isInteger();
  bool isDouble() => instructionType.isDouble();
  bool isNumber() => instructionType.isNumber();
  bool isNumberOrNull() => instructionType.isNumberOrNull();
  bool isString() => instructionType.isString();
  bool isIndexablePrimitive() => instructionType.isIndexablePrimitive();
  bool isPrimitive() => instructionType.isPrimitive();
  bool canBeNull() => instructionType.canBeNull();
  bool canBePrimitive(Compiler compiler) =>
      instructionType.canBePrimitive(compiler);

  /**
   * Type of the unstruction.
   */
  HType instructionType = HType.UNKNOWN;

  bool isInBasicBlock() => block != null;

  String inputsToString() {
    void addAsCommaSeparated(StringBuffer buffer, List<HInstruction> list) {
      for (int i = 0; i < list.length; i++) {
        if (i != 0) buffer.write(', ');
        buffer.write("@${list[i].id}");
      }
    }

    StringBuffer buffer = new StringBuffer();
    buffer.write('(');
    addAsCommaSeparated(buffer, inputs);
    buffer.write(') - used at [');
    addAsCommaSeparated(buffer, usedBy);
    buffer.write(']');
    return buffer.toString();
  }

  bool gvnEquals(HInstruction other) {
    assert(useGvn() && other.useGvn());
    // Check that the type and the flags match.
    bool hasSameType = typeEquals(other);
    assert(hasSameType == (typeCode() == other.typeCode()));
    if (!hasSameType) return false;
    if (flags != other.flags) return false;
    // Check that the inputs match.
    final int inputsLength = inputs.length;
    final List<HInstruction> otherInputs = other.inputs;
    if (inputsLength != otherInputs.length) return false;
    for (int i = 0; i < inputsLength; i++) {
      if (!identical(inputs[i], otherInputs[i])) return false;
    }
    // Check that the data in the instruction matches.
    return dataEquals(other);
  }

  int gvnHashCode() {
    int result = typeCode();
    int length = inputs.length;
    for (int i = 0; i < length; i++) {
      result = (result * 19) + (inputs[i].id) + (result >> 7);
    }
    return result;
  }

  // These methods should be overwritten by instructions that
  // participate in global value numbering.
  int typeCode() => HInstruction.UNDEFINED_TYPECODE;
  bool typeEquals(HInstruction other) => false;
  bool dataEquals(HInstruction other) => false;

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

  void rewriteInput(HInstruction from, HInstruction to) {
    for (int i = 0; i < inputs.length; i++) {
      if (identical(inputs[i], from)) inputs[i] = to;
    }
  }

  /** Removes all occurrences of [user] from [usedBy]. */
  void removeUser(HInstruction user) {
    List<HInstruction> users = usedBy;
    int length = users.length;
    for (int i = 0; i < length; i++) {
      if (identical(users[i], user)) {
        users[i] = users[length - 1];
        length--;
      }
    }
    users.length = length;
  }

  // Change all uses of [oldInput] by [this] to [newInput]. Also
  // updates the [usedBy] of [oldInput] and [newInput].
  void changeUse(HInstruction oldInput, HInstruction newInput) {
    for (int i = 0; i < inputs.length; i++) {
      if (identical(inputs[i], oldInput)) {
        inputs[i] = newInput;
        newInput.usedBy.add(this);
      }
    }
    List<HInstruction> oldInputUsers = oldInput.usedBy;
    int i = 0;
    while (i < oldInputUsers.length) {
      if (oldInputUsers[i] == this) {
        oldInputUsers[i] = oldInputUsers[oldInput.usedBy.length - 1];
        oldInputUsers.length--;
      } else {
        i++;
      }
    }
  }

  // Compute the set of users of this instruction that is dominated by
  // [other]. If [other] is a user of [this], it is included in the
  // returned set.
  Set<HInstruction> dominatedUsers(HInstruction other) {
    // Keep track of all instructions that we have to deal with later
    // and count the number of them that are in the current block.
    Set<HInstruction> users = new Set<HInstruction>();
    int usersInCurrentBlock = 0;

    // Run through all the users and see if they are dominated or
    // potentially dominated by [other].
    HBasicBlock otherBlock = other.block;
    for (int i = 0, length = usedBy.length; i < length; i++) {
      HInstruction current = usedBy[i];
      if (otherBlock.dominates(current.block)) {
        if (identical(current.block, otherBlock)) usersInCurrentBlock++;
        users.add(current);
      }
    }

    // Run through all the phis in the same block as [other] and remove them
    // from the users set.
    if (usersInCurrentBlock > 0) {
      for (HPhi phi = otherBlock.phis.first; phi != null; phi = phi.next) {
        if (users.contains(phi)) {
          users.remove(phi);
          if (--usersInCurrentBlock == 0) break;
        }
      }
    }

    // Run through all the instructions before [other] and remove them
    // from the users set.
    if (usersInCurrentBlock > 0) {
      HInstruction current = otherBlock.first;
      while (!identical(current, other)) {
        if (users.contains(current)) {
          users.remove(current);
          if (--usersInCurrentBlock == 0) break;
        }
        current = current.next;
      }
    }

    return users;
  }

  void moveBefore(HInstruction other) {
    assert(this is !HControlFlow);
    assert(this is !HPhi);
    assert(other is !HPhi);
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
  bool isConstantSentinel() => false;

  bool isInterceptor(Compiler compiler) => false;

  bool isValid() {
    HValidator validator = new HValidator();
    validator.currentBlock = block;
    validator.visitInstruction(this);
    return validator.isValid;
  }

  /**
   * The code for computing a bailout environment, and the code
   * generation must agree on what does not need to be captured,
   * so should always be generated at use site.
   */
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

  HInstruction convertType(Compiler compiler, DartType type, int kind) {
    if (type == null) return this;
    if (identical(type.element, compiler.dynamicClass)) return this;
    if (identical(type.element, compiler.objectClass)) return this;
    if (type.isMalformed || type.kind != TypeKind.INTERFACE) {
      return new HTypeConversion(type, kind, HType.UNKNOWN, this);
    } else if (kind == HTypeConversion.BOOLEAN_CONVERSION_CHECK) {
      // Boolean conversion checks work on non-nullable booleans.
      return new HTypeConversion(type, kind, HType.BOOLEAN, this);
    } else {
      HType subtype = new HType.subtype(type, compiler);
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

class HBoolify extends HInstruction {
  HBoolify(HInstruction value) : super(<HInstruction>[value]) {
    assert(!hasSideEffects());
    setUseGvn();
    instructionType = HType.BOOLEAN;
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
  HCheck(inputs) : super(inputs) {
    assert(!hasSideEffects());
    setUseGvn();
  }
  HInstruction get checkedInput => inputs[0];
  bool isJsStatement() => true;
  bool canThrow() => true;
}

class HBailoutTarget extends HInstruction {
  final int state;
  bool isEnabled = true;
  // For each argument we record how many dummy (unused) arguments should
  // precede it, to make sure it lands in the correctly named parameter in the
  // bailout function.
  List<int> padding;
  HBailoutTarget(this.state) : super(<HInstruction>[]) {
    assert(!hasSideEffects());
    setUseGvn();
  }

  void disable() {
    isEnabled = false;
  }

  bool isControlFlow() => isEnabled;
  bool isJsStatement() => isEnabled;

  accept(HVisitor visitor) => visitor.visitBailoutTarget(this);
  int typeCode() => HInstruction.BAILOUT_TARGET_TYPECODE;
  bool typeEquals(other) => other is HBailoutTarget;
  bool dataEquals(HBailoutTarget other) => other.state == state;
}

class HTypeGuard extends HCheck {
  HType guardedType;
  bool isEnabled = false;

  HTypeGuard(this.guardedType, HInstruction guarded, HInstruction bailoutTarget)
      : super(<HInstruction>[guarded, bailoutTarget]);

  HInstruction get guarded => inputs[0];
  HInstruction get checkedInput => guarded;
  HBailoutTarget get bailoutTarget => inputs[1];
  int get state => bailoutTarget.state;

  void enable() {
    isEnabled = true;
    instructionType = guardedType;
  }

  void disable() {
    isEnabled = false;
    instructionType = guarded.instructionType;
  }

  bool isControlFlow() => true;
  bool isJsStatement() => isEnabled;
  bool canThrow() => isEnabled;

  // A [HTypeGuard] cannot be moved anywhere in the graph, otherwise
  // instructions that have side effects could end up before the guard
  // in the otpimized version, and after the guard in a bailout
  // version.
  bool isPure() => false;

  accept(HVisitor visitor) => visitor.visitTypeGuard(this);
  int typeCode() => HInstruction.TYPE_GUARD_TYPECODE;
  bool typeEquals(other) => other is HTypeGuard;
  bool dataEquals(HTypeGuard other) => guardedType == other.guardedType;
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

  HBoundsCheck(length, index) : super(<HInstruction>[length, index]) {
    instructionType = HType.INTEGER;
  }

  HInstruction get length => inputs[1];
  HInstruction get index => inputs[0];
  bool isControlFlow() => true;

  accept(HVisitor visitor) => visitor.visitBoundsCheck(this);
  int typeCode() => HInstruction.BOUNDS_CHECK_TYPECODE;
  bool typeEquals(other) => other is HBoundsCheck;
  bool dataEquals(HInstruction other) => true;
}

class HIntegerCheck extends HCheck {
  bool alwaysFalse = false;

  HIntegerCheck(value) : super(<HInstruction>[value]) {
    instructionType = HType.INTEGER;
  }

  HInstruction get value => inputs[0];
  bool isControlFlow() => true;

  accept(HVisitor visitor) => visitor.visitIntegerCheck(this);
  int typeCode() => HInstruction.INTEGER_CHECK_TYPECODE;
  bool typeEquals(other) => other is HIntegerCheck;
  bool dataEquals(HInstruction other) => true;
}

abstract class HConditionalBranch extends HControlFlow {
  HConditionalBranch(inputs) : super(inputs);
  HInstruction get condition => inputs[0];
  HBasicBlock get trueBranch => block.successors[0];
  HBasicBlock get falseBranch => block.successors[1];
}

abstract class HControlFlow extends HInstruction {
  HControlFlow(inputs) : super(inputs);
  bool isControlFlow() => true;
  bool isJsStatement() => true;
}

abstract class HInvoke extends HInstruction {
  /**
    * The first argument must be the target: either an [HStatic] node, or
    * the receiver of a method-call. The remaining inputs are the arguments
    * to the invocation.
    */
  HInvoke(List<HInstruction> inputs) : super(inputs) {
    setAllSideEffects();
    setDependsOnSomething();
  }
  static const int ARGUMENTS_OFFSET = 1;
  bool canThrow() => true;
}

abstract class HInvokeDynamic extends HInvoke {
  final InvokeDynamicSpecializer specializer;
  final Selector selector;
  Element element;

  HInvokeDynamic(Selector selector,
                 this.element,
                 List<HInstruction> inputs,
                 [bool isIntercepted = false])
    : super(inputs),
      this.selector = selector,
      specializer = isIntercepted
          ? InvokeDynamicSpecializer.lookupSpecializer(selector)
          : const InvokeDynamicSpecializer();
  toString() => 'invoke dynamic: $selector';
  HInstruction get receiver => inputs[0];
  HInstruction getDartReceiver(Compiler compiler) {
    return isCallOnInterceptor(compiler) ? inputs[1] : inputs[0];
  }

  /**
   * Returns whether this call is on an intercepted method.
   */
  bool get isInterceptedCall {
    // We know it's a selector call if it follows the interceptor
    // calling convention, which adds the actual receiver as a
    // parameter to the call.
    return inputs.length - 2 == selector.argumentCount;
  }

  /**
   * Returns whether this call is on an interceptor object.
   */
  bool isCallOnInterceptor(Compiler compiler) {
    return isInterceptedCall && receiver.isInterceptor(compiler);
  }

  int typeCode() => HInstruction.INVOKE_DYNAMIC_TYPECODE;
  bool typeEquals(other) => other is HInvokeDynamic;
  bool dataEquals(HInvokeDynamic other) {
    return selector == other.selector && element == other.element;
  }
}

class HInvokeClosure extends HInvokeDynamic {
  HInvokeClosure(Selector selector, List<HInstruction> inputs)
    : super(selector, null, inputs) {
    assert(selector.isClosureCall());
  }
  accept(HVisitor visitor) => visitor.visitInvokeClosure(this);
}

class HInvokeDynamicMethod extends HInvokeDynamic {
  HInvokeDynamicMethod(Selector selector,
                       List<HInstruction> inputs,
                       [bool isIntercepted = false])
    : super(selector, null, inputs, isIntercepted);

  String toString() => 'invoke dynamic method: $selector';
  accept(HVisitor visitor) => visitor.visitInvokeDynamicMethod(this);

  bool isIndexOperatorOnIndexablePrimitive() {
    return isInterceptedCall
        && selector.kind == SelectorKind.INDEX
        && selector.name == const SourceString('[]')
        && inputs[1].isIndexablePrimitive();
  }
}

abstract class HInvokeDynamicField extends HInvokeDynamic {
  final bool isSideEffectFree;
  HInvokeDynamicField(
      Selector selector, Element element, List<HInstruction> inputs,
      this.isSideEffectFree)
      : super(selector, element, inputs);
  toString() => 'invoke dynamic field: $selector';
}

class HInvokeDynamicGetter extends HInvokeDynamicField {
  HInvokeDynamicGetter(selector, element, receiver, isSideEffectFree)
    : super(selector, element, [receiver], isSideEffectFree) {
    clearAllSideEffects();
    if (isSideEffectFree) {
      setUseGvn();
      setDependsOnInstancePropertyStore();
    } else {
      setDependsOnSomething();
      setAllSideEffects();
    }
  }
  toString() => 'invoke dynamic getter: $selector';
  accept(HVisitor visitor) => visitor.visitInvokeDynamicGetter(this);
}

class HInvokeDynamicSetter extends HInvokeDynamicField {
  HInvokeDynamicSetter(selector, element, receiver, value, isSideEffectFree)
    : super(selector, element, [receiver, value], isSideEffectFree) {
    clearAllSideEffects();
    if (isSideEffectFree) {
      setChangesInstanceProperty();
    } else {
      setAllSideEffects();
      setDependsOnSomething();
    }
  }
  toString() => 'invoke dynamic setter: $selector';
  accept(HVisitor visitor) => visitor.visitInvokeDynamicSetter(this);
}

class HInvokeStatic extends HInvoke {
  /** The first input must be the target. */
  HInvokeStatic(inputs, HType type) : super(inputs) {
    instructionType = type;
  }

  toString() => 'invoke static: ${element.name}';
  accept(HVisitor visitor) => visitor.visitInvokeStatic(this);
  int typeCode() => HInstruction.INVOKE_STATIC_TYPECODE;
  Element get element => target.element;
  HStatic get target => inputs[0];
}

class HInvokeSuper extends HInvokeStatic {
  final bool isSetter;
  HInvokeSuper(inputs, {this.isSetter: false}) : super(inputs, HType.UNKNOWN);
  toString() => 'invoke super: ${element.name}';
  accept(HVisitor visitor) => visitor.visitInvokeSuper(this);

  HInstruction get value {
    assert(isSetter);
    // Index 0: the element, index 1: 'this'.
    return inputs[2];
  }
}

abstract class HFieldAccess extends HInstruction {
  final Element element;

  HFieldAccess(Element element, List<HInstruction> inputs)
      : this.element = element, super(inputs);

  HInstruction get receiver => inputs[0];
}

class HFieldGet extends HFieldAccess {
  final bool isAssignable;

  HFieldGet(Element element, HInstruction receiver, {bool isAssignable})
      : this.isAssignable = (isAssignable != null)
            ? isAssignable
            : element.isAssignable(),
        super(element, <HInstruction>[receiver]) {
    clearAllSideEffects();
    setUseGvn();
    if (this.isAssignable) {
      setDependsOnInstancePropertyStore();
    }
  }

  bool isInterceptor(Compiler compiler) {
    if (sourceElement == null) return false;
    // In case of a closure inside an interceptor class, [:this:] is
    // stored in the generated closure class, and accessed through a
    // [HFieldGet].
    JavaScriptBackend backend = compiler.backend;
    bool interceptor =
        backend.isInterceptorClass(sourceElement.getEnclosingClass());
    return interceptor && sourceElement is ThisElement;
  }

  bool canThrow() => receiver.canBeNull();

  accept(HVisitor visitor) => visitor.visitFieldGet(this);

  int typeCode() => HInstruction.FIELD_GET_TYPECODE;
  bool typeEquals(other) => other is HFieldGet;
  bool dataEquals(HFieldGet other) => element == other.element;
  String toString() => "FieldGet $element";
}

class HFieldSet extends HFieldAccess {
  HFieldSet(Element element,
            HInstruction receiver,
            HInstruction value)
      : super(element, <HInstruction>[receiver, value]) {
    clearAllSideEffects();
    setChangesInstanceProperty();
  }

  bool canThrow() => receiver.canBeNull();

  HInstruction get value => inputs[1];
  accept(HVisitor visitor) => visitor.visitFieldSet(this);

  bool isJsStatement() => true;
  String toString() => "FieldSet $element";
}

class HLocalGet extends HFieldAccess {
  // No need to use GVN for a [HLocalGet], it is just a local
  // access.
  HLocalGet(Element element, HLocalValue local)
      : super(element, <HInstruction>[local]);

  accept(HVisitor visitor) => visitor.visitLocalGet(this);

  HLocalValue get local => inputs[0];
}

class HLocalSet extends HFieldAccess {
  HLocalSet(Element element, HLocalValue local, HInstruction value)
      : super(element, <HInstruction>[local, value]);

  accept(HVisitor visitor) => visitor.visitLocalSet(this);

  HLocalValue get local => inputs[0];
  HInstruction get value => inputs[1];
  bool isJsStatement() => true;
}

class HForeign extends HInstruction {
  final DartString code;
  final bool isStatement;
  final bool isSideEffectFree;

  HForeign(this.code,
           HType type,
           List<HInstruction> inputs,
           {this.isStatement: false,
            this.isSideEffectFree: false})
      : super(inputs) {
    if (!isSideEffectFree) {
      setAllSideEffects();
      setDependsOnSomething();
    }
    instructionType = type;
  }

  HForeign.statement(code, List<HInstruction> inputs)
      : this(code, HType.UNKNOWN, inputs, isStatement: true);

  accept(HVisitor visitor) => visitor.visitForeign(this);

  bool isJsStatement() => isStatement;
  bool canThrow() => !isSideEffectFree;
}

class HForeignNew extends HForeign {
  ClassElement element;
  HForeignNew(this.element, HType type, List<HInstruction> inputs)
      : super(const LiteralDartString("new"), type, inputs);
  accept(HVisitor visitor) => visitor.visitForeignNew(this);
}

abstract class HInvokeBinary extends HInstruction {
  HInvokeBinary(HInstruction left, HInstruction right)
      : super(<HInstruction>[left, right]) {
    clearAllSideEffects();
    setUseGvn();
  }

  HInstruction get left => inputs[0];
  HInstruction get right => inputs[1];

  BinaryOperation operation(ConstantSystem constantSystem);
}

abstract class HBinaryArithmetic extends HInvokeBinary {
  HBinaryArithmetic(HInstruction left, HInstruction right) : super(left, right);
  BinaryOperation operation(ConstantSystem constantSystem);
}

class HAdd extends HBinaryArithmetic {
  HAdd(HInstruction left, HInstruction right) : super(left, right);
  accept(HVisitor visitor) => visitor.visitAdd(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.add;
  int typeCode() => HInstruction.ADD_TYPECODE;
  bool typeEquals(other) => other is HAdd;
  bool dataEquals(HInstruction other) => true;
}

class HDivide extends HBinaryArithmetic {
  HDivide(HInstruction left, HInstruction right) : super(left, right) {
    instructionType = HType.DOUBLE;
  }
  accept(HVisitor visitor) => visitor.visitDivide(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.divide;
  int typeCode() => HInstruction.DIVIDE_TYPECODE;
  bool typeEquals(other) => other is HDivide;
  bool dataEquals(HInstruction other) => true;
}

class HMultiply extends HBinaryArithmetic {
  HMultiply(HInstruction left, HInstruction right) : super(left, right);
  accept(HVisitor visitor) => visitor.visitMultiply(this);

  BinaryOperation operation(ConstantSystem operations)
      => operations.multiply;
  int typeCode() => HInstruction.MULTIPLY_TYPECODE;
  bool typeEquals(other) => other is HMultiply;
  bool dataEquals(HInstruction other) => true;
}

class HSubtract extends HBinaryArithmetic {
  HSubtract(HInstruction left, HInstruction right) : super(left, right);
  accept(HVisitor visitor) => visitor.visitSubtract(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.subtract;
  int typeCode() => HInstruction.SUBTRACT_TYPECODE;
  bool typeEquals(other) => other is HSubtract;
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
  HBinaryBitOp(HInstruction left, HInstruction right) : super(left, right) {
    instructionType = HType.INTEGER;
  }
}

class HShiftLeft extends HBinaryBitOp {
  HShiftLeft(HInstruction left, HInstruction right) : super(left, right);
  accept(HVisitor visitor) => visitor.visitShiftLeft(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.shiftLeft;
  int typeCode() => HInstruction.SHIFT_LEFT_TYPECODE;
  bool typeEquals(other) => other is HShiftLeft;
  bool dataEquals(HInstruction other) => true;
}

class HBitOr extends HBinaryBitOp {
  HBitOr(HInstruction left, HInstruction right) : super(left, right);
  accept(HVisitor visitor) => visitor.visitBitOr(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.bitOr;
  int typeCode() => HInstruction.BIT_OR_TYPECODE;
  bool typeEquals(other) => other is HBitOr;
  bool dataEquals(HInstruction other) => true;
}

class HBitAnd extends HBinaryBitOp {
  HBitAnd(HInstruction left, HInstruction right) : super(left, right);
  accept(HVisitor visitor) => visitor.visitBitAnd(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.bitAnd;
  int typeCode() => HInstruction.BIT_AND_TYPECODE;
  bool typeEquals(other) => other is HBitAnd;
  bool dataEquals(HInstruction other) => true;
}

class HBitXor extends HBinaryBitOp {
  HBitXor(HInstruction left, HInstruction right) : super(left, right);
  accept(HVisitor visitor) => visitor.visitBitXor(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.bitXor;
  int typeCode() => HInstruction.BIT_XOR_TYPECODE;
  bool typeEquals(other) => other is HBitXor;
  bool dataEquals(HInstruction other) => true;
}

abstract class HInvokeUnary extends HInstruction {
  HInvokeUnary(HInstruction input) : super(<HInstruction>[input]) {
    clearAllSideEffects();
    setUseGvn();
  }

  HInstruction get operand => inputs[0];

  UnaryOperation operation(ConstantSystem constantSystem);
}

class HNegate extends HInvokeUnary {
  HNegate(HInstruction input) : super(input);
  accept(HVisitor visitor) => visitor.visitNegate(this);

  UnaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.negate;
  int typeCode() => HInstruction.NEGATE_TYPECODE;
  bool typeEquals(other) => other is HNegate;
  bool dataEquals(HInstruction other) => true;
}

class HBitNot extends HInvokeUnary {
  HBitNot(HInstruction input) : super(input) {
    instructionType = HType.INTEGER;
  }
  accept(HVisitor visitor) => visitor.visitBitNot(this);
  
  UnaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.bitNot;
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
  final TargetElement target;
  final LabelElement label;
  HJump(this.target) : label = null, super(const <HInstruction>[]);
  HJump.toLabel(LabelElement label)
      : label = label, target = label.target, super(const <HInstruction>[]);
}

class HBreak extends HJump {
  HBreak(TargetElement target) : super(target);
  HBreak.toLabel(LabelElement label) : super.toLabel(label);
  toString() => (label != null) ? 'break ${label.labelName}' : 'break';
  accept(HVisitor visitor) => visitor.visitBreak(this);
}

class HContinue extends HJump {
  HContinue(TargetElement target) : super(target);
  HContinue.toLabel(LabelElement label) : super.toLabel(label);
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

  bool isDoWhile() {
    return identical(kind, DO_WHILE_LOOP);
  }

  HBasicBlock computeLoopHeader() {
    HBasicBlock result;
    if (isDoWhile()) {
      // In case of a do/while, the successor is a block that avoids
      // a critical edge and branchs to the loop header.
      result = block.successors[0].successors[0];
    } else {
      // For other loops, the loop header might be up the dominator
      // tree if the loop condition has control flow.
      result = block;
      while (!result.isLoopHeader()) result = result.dominator;
    }

    assert(result.isLoopHeader());
    return result;
  }
}

class HConstant extends HInstruction {
  final Constant constant;
  HConstant.internal(this.constant, HType constantType)
      : super(<HInstruction>[]) {
    instructionType = constantType;
  }

  toString() => 'literal: $constant';
  accept(HVisitor visitor) => visitor.visitConstant(this);

  bool isConstant() => true;
  bool isConstantBoolean() => constant.isBool();
  bool isConstantNull() => constant.isNull();
  bool isConstantNumber() => constant.isNum();
  bool isConstantInteger() => constant.isInt();
  bool isConstantString() => constant.isString();
  bool isConstantList() => constant.isList();
  bool isConstantMap() => constant.isMap();
  bool isConstantFalse() => constant.isFalse();
  bool isConstantTrue() => constant.isTrue();
  bool isConstantSentinel() => constant.isSentinel();

  bool isInterceptor(Compiler compiler) => constant.isInterceptor();

  // Maybe avoid this if the literal is big?
  bool isCodeMotionInvariant() => true;
}

class HNot extends HInstruction {
  HNot(HInstruction value) : super(<HInstruction>[value]) {
    setUseGvn();
    instructionType = HType.BOOLEAN;
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
  HLocalValue(Element element) : super(<HInstruction>[]) {
    sourceElement = element;
  }

  toString() => 'local ${sourceElement.name}';
  accept(HVisitor visitor) => visitor.visitLocalValue(this);
}

class HParameterValue extends HLocalValue {
  HParameterValue(Element element) : super(element);

  toString() => 'parameter ${sourceElement.name.slowToString()}';
  accept(HVisitor visitor) => visitor.visitParameterValue(this);
}

class HThis extends HParameterValue {
  HThis(Element element, [HType type = HType.UNKNOWN]) : super(element) {
    instructionType = type;
  }
  toString() => 'this';
  accept(HVisitor visitor) => visitor.visitThis(this);
  bool isCodeMotionInvariant() => true;
  bool isInterceptor(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return backend.isInterceptorClass(sourceElement.getEnclosingClass());
  }
}

class HPhi extends HInstruction {
  static const IS_NOT_LOGICAL_OPERATOR = 0;
  static const IS_AND = 1;
  static const IS_OR = 2;

  int logicalOperatorType = IS_NOT_LOGICAL_OPERATOR;

  // The order of the [inputs] must correspond to the order of the
  // predecessor-edges. That is if an input comes from the first predecessor
  // of the surrounding block, then the input must be the first in the [HPhi].
  HPhi(Element element, List<HInstruction> inputs) : super(inputs) {
    sourceElement = element;
  }
  HPhi.noInputs(Element element) : this(element, <HInstruction>[]);
  HPhi.singleInput(Element element, HInstruction input)
      : this(element, <HInstruction>[input]);
  HPhi.manyInputs(Element element, List<HInstruction> inputs)
      : this(element, inputs);

  void addInput(HInstruction input) {
    assert(isInBasicBlock());
    inputs.add(input);
    assert(inputs.length <= block.predecessors.length);
    input.usedBy.add(this);
  }

  bool isLogicalOperator() => logicalOperatorType != IS_NOT_LOGICAL_OPERATOR;

  String logicalOperator() {
    assert(isLogicalOperator());
    if (logicalOperatorType == IS_AND) return "&&";
    assert(logicalOperatorType == IS_OR);
    return "||";
  }

  toString() => 'phi';
  accept(HVisitor visitor) => visitor.visitPhi(this);
}

abstract class HRelational extends HInvokeBinary {
  bool usesBoolifiedInterceptor = false;
  HRelational(HInstruction left, HInstruction right) : super(left, right) {
    instructionType = HType.BOOLEAN;
  }
}

class HIdentity extends HRelational {
  HIdentity(HInstruction left, HInstruction right) : super(left, right);
  accept(HVisitor visitor) => visitor.visitIdentity(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.identity;
  int typeCode() => HInstruction.IDENTITY_TYPECODE;
  bool typeEquals(other) => other is HIdentity;
  bool dataEquals(HInstruction other) => true;
}

class HGreater extends HRelational {
  HGreater(HInstruction left, HInstruction right) : super(left, right);
  accept(HVisitor visitor) => visitor.visitGreater(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.greater;
  int typeCode() => HInstruction.GREATER_TYPECODE;
  bool typeEquals(other) => other is HGreater;
  bool dataEquals(HInstruction other) => true;
}

class HGreaterEqual extends HRelational {
  HGreaterEqual(HInstruction left, HInstruction right) : super(left, right);
  accept(HVisitor visitor) => visitor.visitGreaterEqual(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.greaterEqual;
  int typeCode() => HInstruction.GREATER_EQUAL_TYPECODE;
  bool typeEquals(other) => other is HGreaterEqual;
  bool dataEquals(HInstruction other) => true;
}

class HLess extends HRelational {
  HLess(HInstruction left, HInstruction right) : super(left, right);
  accept(HVisitor visitor) => visitor.visitLess(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.less;
  int typeCode() => HInstruction.LESS_TYPECODE;
  bool typeEquals(other) => other is HLess;
  bool dataEquals(HInstruction other) => true;
}

class HLessEqual extends HRelational {
  HLessEqual(HInstruction left, HInstruction right) : super(left, right);
  accept(HVisitor visitor) => visitor.visitLessEqual(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.lessEqual;
  int typeCode() => HInstruction.LESS_EQUAL_TYPECODE;
  bool typeEquals(other) => other is HLessEqual;
  bool dataEquals(HInstruction other) => true;
}

class HReturn extends HControlFlow {
  HReturn(value) : super(<HInstruction>[value]);
  toString() => 'return';
  accept(HVisitor visitor) => visitor.visitReturn(this);
}

class HThrowExpression extends HInstruction {
  HThrowExpression(value) : super(<HInstruction>[value]);
  toString() => 'throw expression';
  accept(HVisitor visitor) => visitor.visitThrowExpression(this);
  bool canThrow() => true;
}

class HThrow extends HControlFlow {
  final bool isRethrow;
  HThrow(value, {this.isRethrow: false}) : super(<HInstruction>[value]);
  toString() => 'throw';
  accept(HVisitor visitor) => visitor.visitThrow(this);
}

class HStatic extends HInstruction {
  final Element element;
  HStatic(this.element) : super(<HInstruction>[]) {
    assert(element != null);
    assert(invariant(this, element.isDeclaration));
    clearAllSideEffects();
    if (element.isAssignable()) {
      setDependsOnStaticPropertyStore();
    }
    setUseGvn();
  }
  toString() => 'static ${element.name}';
  accept(HVisitor visitor) => visitor.visitStatic(this);

  int gvnHashCode() => super.gvnHashCode() ^ element.hashCode;
  int typeCode() => HInstruction.STATIC_TYPECODE;
  bool typeEquals(other) => other is HStatic;
  bool dataEquals(HStatic other) => element == other.element;
  bool isCodeMotionInvariant() => !element.isAssignable();
}

class HInterceptor extends HInstruction {
  Set<ClassElement> interceptedClasses;
  HInterceptor(this.interceptedClasses, HInstruction receiver)
      : super(<HInstruction>[receiver]) {
    clearAllSideEffects();
    setUseGvn();
  }
  String toString() => 'interceptor on $interceptedClasses';
  accept(HVisitor visitor) => visitor.visitInterceptor(this);
  HInstruction get receiver => inputs[0];
  bool isInterceptor(Compiler compiler) => true;

  int typeCode() => HInstruction.INTERCEPTOR_TYPECODE;
  bool typeEquals(other) => other is HInterceptor;
  bool dataEquals(HInterceptor other) {
    return interceptedClasses == other.interceptedClasses
        || (interceptedClasses.length == other.interceptedClasses.length
            && interceptedClasses.containsAll(other.interceptedClasses));
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
  Set<ClassElement> interceptedClasses;
  HOneShotInterceptor(Selector selector,
                      List<HInstruction> inputs,
                      this.interceptedClasses)
      : super(selector, null, inputs, true) {
    assert(inputs[0] is HConstant);
    assert(inputs[0].instructionType == HType.NULL);
  }
  bool isCallOnInterceptor(Compiler compiler) => true;

  String toString() => 'one shot interceptor on $selector';
  accept(HVisitor visitor) => visitor.visitOneShotInterceptor(this);
}

/** An [HLazyStatic] is a static that is initialized lazily at first read. */
class HLazyStatic extends HInstruction {
  final Element element;
  HLazyStatic(this.element) : super(<HInstruction>[]) {
    // TODO(4931): The first access has side-effects, but we afterwards we
    // should be able to GVN.
    setAllSideEffects();
    setDependsOnSomething();
  }

  toString() => 'lazy static ${element.name}';
  accept(HVisitor visitor) => visitor.visitLazyStatic(this);

  int typeCode() => 30;
  // TODO(4931): can we do better here?
  bool isCodeMotionInvariant() => false;
  bool canThrow() => true;
}

class HStaticStore extends HInstruction {
  Element element;
  HStaticStore(this.element, HInstruction value)
      : super(<HInstruction>[value]) {
    clearAllSideEffects();
    setChangesStaticProperty();
  }
  toString() => 'static store ${element.name}';
  accept(HVisitor visitor) => visitor.visitStaticStore(this);

  int typeCode() => HInstruction.STATIC_STORE_TYPECODE;
  bool typeEquals(other) => other is HStaticStore;
  bool dataEquals(HStaticStore other) => element == other.element;
  bool isJsStatement() => true;
}

class HLiteralList extends HInstruction {
  HLiteralList(inputs) : super(inputs) {
    instructionType = HType.EXTENDABLE_ARRAY;
  }
  toString() => 'literal list';
  accept(HVisitor visitor) => visitor.visitLiteralList(this);
}

/**
 * The primitive array indexing operation. Note that this instruction
 * does not throw because we generate the checks explicitly.
 */
class HIndex extends HInstruction {
  HIndex(HInstruction receiver, HInstruction index)
      : super(<HInstruction>[receiver, index]) {
    clearAllSideEffects();
    setDependsOnIndexStore();
    setUseGvn();
  }

  String toString() => 'index operator';
  accept(HVisitor visitor) => visitor.visitIndex(this);

  HInstruction get receiver => inputs[0];
  HInstruction get index => inputs[1];

  int typeCode() => HInstruction.INDEX_TYPECODE;
  bool typeEquals(HInstruction other) => other is HIndex;
  bool dataEquals(HIndex other) => true;
}

/**
 * The primitive array assignment operation. Note that this instruction
 * does not throw because we generate the checks explicitly.
 */
class HIndexAssign extends HInstruction {
  HIndexAssign(HInstruction receiver,
               HInstruction index,
               HInstruction value)
      : super(<HInstruction>[receiver, index, value]) {
    clearAllSideEffects();
    setChangesIndex();
  }
  String toString() => 'index assign operator';
  accept(HVisitor visitor) => visitor.visitIndexAssign(this);

  HInstruction get receiver => inputs[0];
  HInstruction get index => inputs[1];
  HInstruction get value => inputs[2];
}

// TODO(karlklose): use this class to represent type conversions as well.
class HIs extends HInstruction {
  /// A check against a raw type: 'o is int', 'o is A'.
  static const int RAW_CHECK = 0;
  /// A check against a type with type arguments: 'o is List<int>', 'o is C<T>'.
  static const int COMPOUND_CHECK = 1;
  /// A check against a single type variable: 'o is T'.
  static const int VARIABLE_CHECK = 2;

  final DartType typeExpression;
  final bool nullOk;
  final int kind;

  HIs(this.typeExpression, List<HInstruction> inputs, this.kind,
      {this.nullOk: false}) : super(inputs) {
    assert(kind >= RAW_CHECK && kind <= VARIABLE_CHECK);
    setUseGvn();
    instructionType = HType.BOOLEAN;
  }

  HInstruction get expression => inputs[0];

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
    return typeExpression == other.typeExpression
        && nullOk == other.nullOk
        && kind == other.kind;
  }
}

class HTypeConversion extends HCheck {
  final DartType typeExpression;
  final int kind;

  static const int NO_CHECK = 0;
  static const int CHECKED_MODE_CHECK = 1;
  static const int ARGUMENT_TYPE_CHECK = 2;
  static const int CAST_TYPE_CHECK = 3;
  static const int BOOLEAN_CONVERSION_CHECK = 4;

  HTypeConversion(this.typeExpression, this.kind,
                  HType type, HInstruction input)
      : super(<HInstruction>[input]) {
    sourceElement = input.sourceElement;
    instructionType = type;
  }

  bool get isChecked => kind != NO_CHECK;
  bool get isCheckedModeCheck {
    return kind == CHECKED_MODE_CHECK
        || kind == BOOLEAN_CONVERSION_CHECK;
  }
  bool get isArgumentTypeCheck => kind == ARGUMENT_TYPE_CHECK;
  bool get isCastTypeCheck => kind == CAST_TYPE_CHECK;
  bool get isBooleanConversionCheck => kind == BOOLEAN_CONVERSION_CHECK;

  accept(HVisitor visitor) => visitor.visitTypeConversion(this);

  bool isJsStatement() => kind == ARGUMENT_TYPE_CHECK;
  bool isControlFlow() => kind == ARGUMENT_TYPE_CHECK;
  bool canThrow() => isChecked;

  int typeCode() => HInstruction.TYPE_CONVERSION_TYPECODE;
  bool typeEquals(HInstruction other) => other is HTypeConversion;

  bool dataEquals(HTypeConversion other) {
    return kind == other.kind
        && typeExpression == other.typeExpression
        && instructionType == other.instructionType;
  }
}

class HRangeConversion extends HCheck {
  HRangeConversion(HInstruction input) : super(<HInstruction>[input]) {
    sourceElement = input.sourceElement;
    // We currently only do range analysis for integers.
    instructionType = HType.INTEGER;
  }
  accept(HVisitor visitor) => visitor.visitRangeConversion(this);
}

class HStringConcat extends HInstruction {
  final Node node;
  HStringConcat(HInstruction left, HInstruction right, this.node)
      : super(<HInstruction>[left, right]) {
    // TODO(sra): Until Issue 9293 is fixed, this false dependency keeps the
    // concats bunched with stringified inputs for much better looking code with
    // fewer temps.
    setDependsOnSomething();
    instructionType = HType.STRING;
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
  final Node node;
  HStringify(HInstruction input, this.node) : super(<HInstruction>[input]) {
    setAllSideEffects();
    setDependsOnSomething();
    instructionType = HType.STRING;
  }

  accept(HVisitor visitor) => visitor.visitStringify(this);
  toString() => "stringify";
}

/** Non-block-based (aka. traditional) loop information. */
class HLoopInformation {
  final HBasicBlock header;
  final List<HBasicBlock> blocks;
  final List<HBasicBlock> backEdges;
  final List<LabelElement> labels;
  final TargetElement target;

  /** Corresponding block information for the loop. */
  HLoopBlockInformation loopBlockInformation;

  HLoopInformation(this.header, this.target, this.labels)
      : blocks = new List<HBasicBlock>(),
        backEdges = new List<HBasicBlock>();

  void addBackEdge(HBasicBlock predecessor) {
    backEdges.add(predecessor);
    addBlock(predecessor);
  }

  // Adds a block and transitively all its predecessors in the loop as
  // loop blocks.
  void addBlock(HBasicBlock block) {
    if (identical(block, header)) return;
    HBasicBlock parentHeader = block.parentLoopHeader;
    if (identical(parentHeader, header)) {
      // Nothing to do in this case.
    } else if (parentHeader != null) {
      addBlock(parentHeader);
    } else {
      block.parentLoopHeader = header;
      blocks.add(block);
      for (int i = 0, length = block.predecessors.length; i < length; i++) {
        addBlock(block.predecessors[i]);
      }
    }
  }

  HBasicBlock getLastBackEdge() {
    int maxId = -1;
    HBasicBlock result = null;
    for (int i = 0, length = backEdges.length; i < length; i++) {
      HBasicBlock current = backEdges[i];
      if (current.id > maxId) {
        maxId = current.id;
        result = current;
      }
    }
    return result;
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
    implements HStatementInformationVisitor, HExpressionInformationVisitor {
}


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
  final List<LabelElement> labels;
  final TargetElement target;
  final bool isContinue;

  HLabeledBlockInformation(this.body,
                           List<LabelElement> labels,
                           {this.isContinue: false}) :
      this.labels = labels, this.target = labels[0].target;

  HLabeledBlockInformation.implicit(this.body,
                                    this.target,
                                    {this.isContinue: false})
      : this.labels = const<LabelElement>[];

  HBasicBlock get start => body.start;
  HBasicBlock get end => body.end;

  bool accept(HStatementInformationVisitor visitor) =>
    visitor.visitLabeledBlockInfo(this);
}

class LoopTypeVisitor extends Visitor {
  const LoopTypeVisitor();
  int visitNode(Node node) => HLoopBlockInformation.NOT_A_LOOP;
  int visitWhile(While node) => HLoopBlockInformation.WHILE_LOOP;
  int visitFor(For node) => HLoopBlockInformation.FOR_LOOP;
  int visitDoWhile(DoWhile node) => HLoopBlockInformation.DO_WHILE_LOOP;
  int visitForIn(ForIn node) => HLoopBlockInformation.FOR_IN_LOOP;
}

class HLoopBlockInformation implements HStatementInformation {
  static const int WHILE_LOOP = 0;
  static const int FOR_LOOP = 1;
  static const int DO_WHILE_LOOP = 2;
  static const int FOR_IN_LOOP = 3;
  static const int NOT_A_LOOP = -1;

  final int kind;
  final HExpressionInformation initializer;
  final HExpressionInformation condition;
  final HStatementInformation body;
  final HExpressionInformation updates;
  final TargetElement target;
  final List<LabelElement> labels;
  final SourceFileLocation sourcePosition;
  final SourceFileLocation endSourcePosition;

  HLoopBlockInformation(this.kind,
                        this.initializer,
                        this.condition,
                        this.body,
                        this.updates,
                        this.target,
                        this.labels,
                        this.sourcePosition,
                        this.endSourcePosition) {
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

  static int loopType(Node node) {
    return node.accept(const LoopTypeVisitor());
  }

  bool isDoWhile() => kind == DO_WHILE_LOOP;

  bool accept(HStatementInformationVisitor visitor) =>
    visitor.visitLoopInfo(this);
}

class HIfBlockInformation implements HStatementInformation {
  final HExpressionInformation condition;
  final HStatementInformation thenGraph;
  final HStatementInformation elseGraph;
  HIfBlockInformation(this.condition,
                      this.thenGraph,
                      this.elseGraph);

  HBasicBlock get start => condition.start;
  HBasicBlock get end => elseGraph == null ? thenGraph.end : elseGraph.end;

  bool accept(HStatementInformationVisitor visitor) =>
    visitor.visitIfInfo(this);
}

class HAndOrBlockInformation implements HExpressionInformation {
  final bool isAnd;
  final HExpressionInformation left;
  final HExpressionInformation right;
  HAndOrBlockInformation(this.isAnd,
                         this.left,
                         this.right);

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
  HTryBlockInformation(this.body,
                       this.catchVariable,
                       this.catchBlock,
                       this.finallyBlock);

  HBasicBlock get start => body.start;
  HBasicBlock get end =>
      finallyBlock == null ? catchBlock.end : finallyBlock.end;

  bool accept(HStatementInformationVisitor visitor) =>
    visitor.visitTryInfo(this);
}



class HSwitchBlockInformation implements HStatementInformation {
  final HExpressionInformation expression;
  final List<List<Constant>> matchExpressions;
  final List<HStatementInformation> statements;
  // If the switch has a default, it's the last statement block, which
  // may or may not have other expresions.
  final bool hasDefault;
  final TargetElement target;
  final List<LabelElement> labels;

  HSwitchBlockInformation(this.expression,
                          this.matchExpressions,
                          this.statements,
                          this.hasDefault,
                          this.target,
                          this.labels);

  HBasicBlock get start => expression.start;
  HBasicBlock get end {
    // We don't create a switch block if there are no cases.
    assert(!statements.isEmpty);
    return statements.last.end;
  }

  bool accept(HStatementInformationVisitor visitor) =>
      visitor.visitSwitchInfo(this);
}
