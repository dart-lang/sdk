// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface HVisitor<R> {
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
  R visitEquals(HEquals node);
  R visitExit(HExit node);
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
  R visitInvokeClosure(HInvokeClosure node);
  R visitInvokeDynamicGetter(HInvokeDynamicGetter node);
  R visitInvokeDynamicMethod(HInvokeDynamicMethod node);
  R visitInvokeDynamicSetter(HInvokeDynamicSetter node);
  R visitInvokeInterceptor(HInvokeInterceptor node);
  R visitInvokeStatic(HInvokeStatic node);
  R visitInvokeSuper(HInvokeSuper node);
  R visitIs(HIs node);
  R visitLess(HLess node);
  R visitLessEqual(HLessEqual node);
  R visitLiteralList(HLiteralList node);
  R visitLocalGet(HLocalGet node);
  R visitLocalSet(HLocalSet node);
  R visitLocalValue(HLocalValue node);
  R visitLoopBranch(HLoopBranch node);
  R visitModulo(HModulo node);
  R visitMultiply(HMultiply node);
  R visitNegate(HNegate node);
  R visitNot(HNot node);
  R visitParameterValue(HParameterValue node);
  R visitPhi(HPhi node);
  R visitReturn(HReturn node);
  R visitShiftLeft(HShiftLeft node);
  R visitShiftRight(HShiftRight node);
  R visitStatic(HStatic node);
  R visitStaticStore(HStaticStore node);
  R visitStringConcat(HStringConcat node);
  R visitSubtract(HSubtract node);
  R visitSwitch(HSwitch node);
  R visitThis(HThis node);
  R visitThrow(HThrow node);
  R visitTruncatingDivide(HTruncatingDivide node);
  R visitTry(HTry node);
  R visitTypeGuard(HTypeGuard node);
  R visitTypeConversion(HTypeConversion node);
}

class HGraphVisitor {
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

  abstract visitBasicBlock(HBasicBlock block);
}

class HInstructionVisitor extends HGraphVisitor {
  HBasicBlock currentBlock;

  abstract visitInstruction(HInstruction node);

  visitBasicBlock(HBasicBlock node) {
    void visitInstructionList(HInstructionList list) {
      HInstruction instruction = list.first;
      while (instruction !== null) {
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
    assert(blocks[id] === block);
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
    ObjectConstant objectConstant = constant;
    return new HBoundedType.exact(objectConstant.type);
  }

  HConstant addConstant(Constant constant) {
    HConstant result = constants[constant];
    if (result === null) {
      HType type = mapConstantTypeToSsaType(constant);
      result = new HConstant.internal(constant, type);
      entry.addAtExit(result);
      constants[constant] = result;
    }
    return result;
  }

  HConstant addConstantInt(int i) {
    return addConstant(new IntConstant(i));
  }

  HConstant addConstantDouble(double d) {
    return addConstant(new DoubleConstant(d));
  }

  HConstant addConstantString(DartString str, Node node) {
    return addConstant(new StringConstant(str, node));
  }

  HConstant addConstantBool(bool value) {
    return addConstant(new BoolConstant(value));
  }

  HConstant addConstantNull() {
    return addConstant(new NullConstant());
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
        assert(predecessors.length >= 2);
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
    while (instruction !== null) {
      instruction.accept(this);
      instruction = instruction.next;
    }
  }

  visitInstruction(HInstruction instruction) {}

  visitBinaryArithmetic(HBinaryArithmetic node) => visitInvokeBinary(node);
  visitBinaryBitOp(HBinaryBitOp node) => visitBinaryArithmetic(node);
  visitInvoke(HInvoke node) => visitInstruction(node);
  visitInvokeBinary(HInvokeBinary node) => visitInvokeStatic(node);
  visitInvokeDynamic(HInvokeDynamic node) => visitInvoke(node);
  visitInvokeDynamicField(HInvokeDynamicField node) => visitInvokeDynamic(node);
  visitInvokeUnary(HInvokeUnary node) => visitInvokeStatic(node);
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
  visitEquals(HEquals node) => visitRelational(node);
  visitExit(HExit node) => visitControlFlow(node);
  visitFieldGet(HFieldGet node) => visitFieldAccess(node);
  visitFieldSet(HFieldSet node) => visitFieldAccess(node);
  visitForeign(HForeign node) => visitInstruction(node);
  visitForeignNew(HForeignNew node) => visitForeign(node);
  visitGoto(HGoto node) => visitControlFlow(node);
  visitGreater(HGreater node) => visitRelational(node);
  visitGreaterEqual(HGreaterEqual node) => visitRelational(node);
  visitIdentity(HIdentity node) => visitRelational(node);
  visitIf(HIf node) => visitConditionalBranch(node);
  visitIndex(HIndex node) => visitInvokeStatic(node);
  visitIndexAssign(HIndexAssign node) => visitInvokeStatic(node);
  visitIntegerCheck(HIntegerCheck node) => visitCheck(node);
  visitInvokeClosure(HInvokeClosure node)
      => visitInvokeDynamic(node);
  visitInvokeDynamicMethod(HInvokeDynamicMethod node)
      => visitInvokeDynamic(node);
  visitInvokeDynamicGetter(HInvokeDynamicGetter node)
      => visitInvokeDynamicField(node);
  visitInvokeDynamicSetter(HInvokeDynamicSetter node)
      => visitInvokeDynamicField(node);
  visitInvokeInterceptor(HInvokeInterceptor node)
      => visitInvokeStatic(node);
  visitInvokeStatic(HInvokeStatic node) => visitInvoke(node);
  visitInvokeSuper(HInvokeSuper node) => visitInvoke(node);
  visitJump(HJump node) => visitControlFlow(node);
  visitLess(HLess node) => visitRelational(node);
  visitLessEqual(HLessEqual node) => visitRelational(node);
  visitLiteralList(HLiteralList node) => visitInstruction(node);
  visitLocalGet(HLocalGet node) => visitFieldGet(node);
  visitLocalSet(HLocalSet node) => visitFieldSet(node);
  visitLocalValue(HLocalValue node) => visitInstruction(node);
  visitLoopBranch(HLoopBranch node) => visitConditionalBranch(node);
  visitModulo(HModulo node) => visitBinaryArithmetic(node);
  visitNegate(HNegate node) => visitInvokeUnary(node);
  visitNot(HNot node) => visitInstruction(node);
  visitPhi(HPhi node) => visitInstruction(node);
  visitMultiply(HMultiply node) => visitBinaryArithmetic(node);
  visitParameterValue(HParameterValue node) => visitLocalValue(node);
  visitReturn(HReturn node) => visitControlFlow(node);
  visitShiftRight(HShiftRight node) => visitBinaryBitOp(node);
  visitShiftLeft(HShiftLeft node) => visitBinaryBitOp(node);
  visitSubtract(HSubtract node) => visitBinaryArithmetic(node);
  visitSwitch(HSwitch node) => visitControlFlow(node);
  visitStatic(HStatic node) => visitInstruction(node);
  visitStaticStore(HStaticStore node) => visitInstruction(node);
  visitStringConcat(HStringConcat node) => visitInstruction(node);
  visitThis(HThis node) => visitParameterValue(node);
  visitThrow(HThrow node) => visitControlFlow(node);
  visitTry(HTry node) => visitControlFlow(node);
  visitTruncatingDivide(HTruncatingDivide node) => visitBinaryArithmetic(node);
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
    assert(start !== null);
    assert(end !== null);
    assert(block !== null);
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

  bool isEmpty() {
    return first === null;
  }

  void addAfter(HInstruction cursor, HInstruction instruction) {
    if (cursor === null) {
      assert(isEmpty());
      first = last = instruction;
    } else if (cursor === last) {
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

  void addBefore(HInstruction cursor, HInstruction instruction) {
    if (cursor === null) {
      assert(isEmpty());
      first = last = instruction;
    } else if (cursor === first) {
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
    if (instruction.previous === null) {
      first = instruction.next;
    } else {
      instruction.previous.next = instruction.next;
    }
    if (instruction.next === null) {
      last = instruction.previous;
    } else {
      instruction.next.previous = instruction.previous;
    }
    instruction.previous = null;
    instruction.next = null;
  }

  void remove(HInstruction instruction) {
    assert(instruction.usedBy.isEmpty());
    detach(instruction);
  }

  /** Linear search for [instruction]. */
  bool contains(HInstruction instruction) {
    HInstruction cursor = first;
    while (cursor != null) {
      if (cursor === instruction) return true;
      cursor = cursor.next;
    }
    return false;
  }
}

class HBasicBlock extends HInstructionList implements Hashable {
  // The [id] must be such that any successor's id is greater than
  // this [id]. The exception are back-edges.
  int id;

  static final int STATUS_NEW = 0;
  static final int STATUS_OPEN = 1;
  static final int STATUS_CLOSED = 2;
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

  int hashCode() => id;

  bool isNew() => status == STATUS_NEW;
  bool isOpen() => status == STATUS_OPEN;
  bool isClosed() => status == STATUS_CLOSED;

  bool isLoopHeader() {
    return loopInformation !== null;
  }

  void setBlockFlow(HBlockInformation blockInfo, HBasicBlock continuation) {
    blockFlow = new HBlockFlow(blockInfo, continuation);
  }

  bool isLabeledBlock() =>
    blockFlow !== null &&
    blockFlow.body is HLabeledBlockInformation;

  HBasicBlock get enclosingLoopHeader {
    if (isLoopHeader()) return this;
    return parentLoopHeader;
  }

  bool hasBailoutTargets() => !bailoutTargets.isEmpty();

  void open() {
    assert(isNew());
    status = STATUS_OPEN;
  }

  void close(HControlFlow end) {
    assert(isOpen());
    addAfter(last, end);
    status = STATUS_CLOSED;
  }

  // TODO(kasperl): I really don't want to pass the compiler into this
  // method. Maybe we need a better logging framework.
  void printToCompiler(Compiler compiler) {
    HInstruction instruction = first;
    while (instruction != null) {
      int instructionId = instruction.id;
      String inputsAsString = instruction.inputsToString();
      compiler.log('$instructionId: $instruction $inputsAsString');
      instruction = instruction.next;
    }
  }

  void addAtEntry(HInstruction instruction) {
    assert(isClosed());
    assert(instruction is !HPhi);
    super.addBefore(first, instruction);
    instruction.notifyAddedToBlock(this);
  }

  void addAtExit(HInstruction instruction) {
    assert(isClosed());
    assert(last is HControlFlow);
    assert(instruction is !HPhi);
    super.addBefore(last, instruction);
    instruction.notifyAddedToBlock(this);
  }

  void moveAtExit(HInstruction instruction) {
    assert(instruction is !HPhi);
    assert(instruction.isInBasicBlock());
    assert(isClosed());
    assert(last is HControlFlow);
    super.addBefore(last, instruction);
    instruction.block = this;
    assert(isValid());
  }

  void add(HInstruction instruction) {
    assert(instruction is !HControlFlow);
    assert(instruction is !HPhi);
    super.addAfter(last, instruction);
    instruction.notifyAddedToBlock(this);
  }

  void addPhi(HPhi phi) {
    phis.addAfter(phis.last, phi);
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
    super.addAfter(cursor, instruction);
    instruction.notifyAddedToBlock(this);
  }

  void addBefore(HInstruction cursor, HInstruction instruction) {
    assert(cursor is !HPhi);
    assert(instruction is !HPhi);
    assert(isOpen() || isClosed());
    super.addBefore(cursor, instruction);
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
    // Forward branches are only allowed to new blocks.
    assert(isClosed() && (block.isNew() || block.id < id));
    if (successors.isEmpty()) {
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
    Link<HCheck> better = const EmptyLink<HCheck>();
    for (HInstruction user in to.usedBy) {
      if (user is HCheck && (user as HCheck).checkedInput === to) {
        better = better.prepend(user);
      }
    }

    if (better.isEmpty()) return rewrite(from, to);

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
    return first === last && first is HExit;
  }

  void addDominatedBlock(HBasicBlock block) {
    assert(isClosed());
    assert(id !== null && block.id !== null);
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
      dominatedBlocks.insertRange(index, 1, block);
    }
    assert(block.dominator === null);
    block.dominator = this;
  }

  void removeDominatedBlock(HBasicBlock block) {
    assert(isClosed());
    assert(id !== null && block.id !== null);
    int index = dominatedBlocks.indexOf(block);
    assert(index >= 0);
    if (index == dominatedBlocks.length - 1) {
      dominatedBlocks.removeLast();
    } else {
      dominatedBlocks.removeRange(index, 1);
    }
    assert(block.dominator === this);
    block.dominator = null;
  }

  void assignCommonDominator(HBasicBlock predecessor) {
    assert(isClosed());
    if (dominator === null) {
      // If this basic block doesn't have a dominator yet we use the
      // given predecessor as the dominator.
      predecessor.addDominatedBlock(this);
    } else if (predecessor.dominator !== null) {
      // If the predecessor has a dominator and this basic block has a
      // dominator, we find a common parent in the dominator tree and
      // use that as the dominator.
      HBasicBlock block0 = dominator;
      HBasicBlock block1 = predecessor;
      while (block0 !== block1) {
        if (block0.id > block1.id) {
          block0 = block0.dominator;
        } else {
          block1 = block1.dominator;
        }
        assert(block0 !== null && block1 !== null);
      }
      if (dominator !== block0) {
        dominator.removeDominatedBlock(this);
        block0.addDominatedBlock(this);
      }
    }
  }

  void forEachPhi(void f(HPhi phi)) {
    HPhi current = phis.first;
    while (current !== null) {
      f(current);
      current = current.next;
    }
  }

  void forEachInstruction(void f(HInstruction instruction)) {
    HInstruction current = first;
    while (current !== null) {
      f(current);
      current = current.next;
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
      if (this === other) return true;
      other = other.dominator;
    } while (other !== null && other.id >= id);
    return false;
  }
}


class HInstruction implements Hashable {
  Element sourceElement;
  Token sourcePosition;

  final int id;
  static int idCounter;

  final List<HInstruction> inputs;
  final List<HInstruction> usedBy;

  HBasicBlock block;
  HInstruction previous = null;
  HInstruction next = null;
  int flags = 0;

  // Changes flags.
  static final int FLAG_CHANGES_SOMETHING    = 0;
  static final int FLAG_CHANGES_COUNT        = FLAG_CHANGES_SOMETHING + 1;

  // Depends flags (one for each changes flag).
  static final int FLAG_DEPENDS_ON_SOMETHING = FLAG_CHANGES_COUNT;

  // Other flags.
  static final int FLAG_USE_GVN              = FLAG_DEPENDS_ON_SOMETHING + 1;

  HInstruction(this.inputs)
      : id = idCounter++,
        usedBy = <HInstruction>[];

  int hashCode() => id;

  bool getFlag(int position) => (flags & (1 << position)) != 0;
  void setFlag(int position) { flags |= (1 << position); }
  void clearFlag(int position) { flags &= ~(1 << position); }

  static int computeDependsOnFlags(int flags) => flags << FLAG_CHANGES_COUNT;

  int getChangesFlags() => flags & ((1 << FLAG_CHANGES_COUNT) - 1);
  bool hasSideEffects(HTypeMap types) => getChangesFlags() != 0;
  void prepareGvn(HTypeMap types) { setAllSideEffects(); }

  void setAllSideEffects() { flags |= ((1 << FLAG_CHANGES_COUNT) - 1); }
  void clearAllSideEffects() { flags &= ~((1 << FLAG_CHANGES_COUNT) - 1); }

  bool dependsOnSomething() => getFlag(FLAG_DEPENDS_ON_SOMETHING);
  void setDependsOnSomething() { setFlag(FLAG_DEPENDS_ON_SOMETHING); }

  bool useGvn() => getFlag(FLAG_USE_GVN);
  void setUseGvn() { setFlag(FLAG_USE_GVN); }
  // Does this node potentially affect control flow.
  bool isControlFlow() => false;

  // All isFunctions work on the propagated types.
  bool isArray(HTypeMap types) => types[this].isArray();
  bool isReadableArray(HTypeMap types) => types[this].isReadableArray();
  bool isMutableArray(HTypeMap types) => types[this].isMutableArray();
  bool isExtendableArray(HTypeMap types) => types[this].isExtendableArray();
  bool isBoolean(HTypeMap types) => types[this].isBoolean();
  bool isInteger(HTypeMap types) => types[this].isInteger();
  bool isDouble(HTypeMap types) => types[this].isDouble();
  bool isNumber(HTypeMap types) => types[this].isNumber();
  bool isString(HTypeMap types) => types[this].isString();
  bool isTypeUnknown(HTypeMap types) => types[this].isUnknown();
  bool isIndexablePrimitive(HTypeMap types)
      => types[this].isIndexablePrimitive();
  bool isPrimitive(HTypeMap types) => types[this].isPrimitive();
  bool canBePrimitive(HTypeMap types) => types[this].canBePrimitive();
  bool canBeNull(HTypeMap types) => types[this].canBeNull();

  /**
   * This is the type the instruction is guaranteed to have. It does not
   * take any propagation into account.
   */
  HType guaranteedType = HType.UNKNOWN;
  bool hasGuaranteedType() => !guaranteedType.isUnknown();

  /**
   * Some instructions have a good idea of their return type, but cannot
   * guarantee the type. The computed does not need to be more specialized
   * than the provided type for [this].
   *
   * Examples: the likely type of [:x == y:] is a boolean. In most cases this
   * cannot be guaranteed, but when merging types we still want to use this
   * information.
   *
   * Similarily the [HAdd] instruction is likely a number. Note that, even if
   * the incoming type is already set to integer, the likely type might still
   * just return the number type.
   */
  HType computeLikelyType(HTypeMap types) => types[this];

  /**
   * Compute the type of the instruction by propagating the input types through
   * the instruction.
   *
   * By default just copy the guaranteed type.
   */
  HType computeTypeFromInputTypes(HTypeMap types) => guaranteedType;

  /**
   * Compute the desired type for the the given [input]. Aside from using
   * other inputs to compute the desired type one should also use
   * the given [types] which, during the invocation of this method,
   * represents the desired type of [this].
   */
  HType computeDesiredTypeForInput(HInstruction input, HTypeMap types) {
    return HType.UNKNOWN;
  }

  bool isInBasicBlock() => block !== null;

  String inputsToString() {
    void addAsCommaSeparated(StringBuffer buffer, List<HInstruction> list) {
      for (int i = 0; i < list.length; i++) {
        if (i != 0) buffer.add(', ');
        buffer.add("@${list[i].id}");
      }
    }

    StringBuffer buffer = new StringBuffer();
    buffer.add('(');
    addAsCommaSeparated(buffer, inputs);
    buffer.add(') - used at [');
    addAsCommaSeparated(buffer, usedBy);
    buffer.add(']');
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
      if (inputs[i] !== otherInputs[i]) return false;
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
  int typeCode() => -1;
  bool typeEquals(HInstruction other) => false;
  bool dataEquals(HInstruction other) => false;

  abstract accept(HVisitor visitor);

  void notifyAddedToBlock(HBasicBlock targetBlock) {
    assert(!isInBasicBlock());
    assert(block === null);
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
    assert(usedBy.isEmpty());

    // Remove [this] from the inputs' uses.
    for (int i = 0; i < inputs.length; i++) {
      inputs[i].removeUser(this);
    }
    this.block = null;
    assert(isValid());
  }

  void rewriteInput(HInstruction from, HInstruction to) {
    for (int i = 0; i < inputs.length; i++) {
      if (inputs[i] === from) inputs[i] = to;
    }
  }

  /** Removes all occurrences of [user] from [usedBy]. */
  void removeUser(HInstruction user) {
    List<HInstruction> users = usedBy;
    int length = users.length;
    for (int i = 0; i < length; i++) {
      if (users[i] === user) {
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
      if (inputs[i] === oldInput) {
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
        if (current.block === otherBlock) usersInCurrentBlock++;
        users.add(current);
      }
    }

    // Run through all the phis in the same block as [other] and remove them
    // from the users set.
    if (usersInCurrentBlock > 0) {
      for (HPhi phi = otherBlock.phis.first; phi !== null; phi = phi.next) {
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
      while (current !== other) {
        if (users.contains(current)) {
          users.remove(current);
          if (--usersInCurrentBlock == 0) break;
        }
        current = current.next;
      }
    }

    return users;
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

  bool isStatement(HTypeMap types) => false;

  bool dominates(HInstruction other) {
    if (block != other.block) return block.dominates(other.block);

    HInstruction current = this;
    while (current !== null) {
      if (current === other) return true;
      current = current.next;
    }
    return false;
  }
}

class HBoolify extends HInstruction {
  HBoolify(HInstruction value) : super(<HInstruction>[value]);
  void prepareGvn(HTypeMap types) {
    assert(!hasSideEffects(types));
    setUseGvn();
  }

  HType get guaranteedType => HType.BOOLEAN;

  accept(HVisitor visitor) => visitor.visitBoolify(this);
  int typeCode() => 0;
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
  HCheck(inputs) : super(inputs);
  HInstruction get checkedInput => inputs[0];
  bool isStatement(HTypeMap types) => true;
  void prepareGvn(HTypeMap types) {
    assert(!hasSideEffects(types));
    setUseGvn();
  }
}

class HBailoutTarget extends HInstruction {
  final int state;
  bool isEnabled = false;
  HBailoutTarget(this.state) : super(<HInstruction>[]);
  void prepareGvn(HTypeMap types) {
    assert(!hasSideEffects(types));
    setUseGvn();
  }

  bool isControlFlow() => true;
  bool isStatement(HTypeMap types) => isEnabled;

  accept(HVisitor visitor) => visitor.visitBailoutTarget(this);
  int typeCode() => 29;
  bool typeEquals(other) => other is HBailoutTarget;
  bool dataEquals(HBailoutTarget other) => other.state == state;
}

class HTypeGuard extends HCheck {
  final HType guardedType;
  bool isEnabled = false;

  HTypeGuard(this.guardedType, HInstruction guarded, HInstruction bailoutTarget)
      : super(<HInstruction>[guarded, bailoutTarget]);

  HInstruction get guarded => inputs[0];
  HInstruction get checkedInput => guarded;
  HBailoutTarget get bailoutTarget => inputs[1];
  int get state => bailoutTarget.state;

  HType computeTypeFromInputTypes(HTypeMap types) {
    return isEnabled ? guardedType : types[guarded];
  }

  HType get guaranteedType => isEnabled ? guardedType : HType.UNKNOWN;

  bool isControlFlow() => true;

  bool isStatement(HTypeMap types) => isEnabled;

  accept(HVisitor visitor) => visitor.visitTypeGuard(this);
  int typeCode() => 1;
  bool typeEquals(other) => other is HTypeGuard;
  bool dataEquals(HTypeGuard other) => guardedType == other.guardedType;
}

class HBoundsCheck extends HCheck {
  static final int ALWAYS_FALSE = 0;
  static final int FULL_CHECK = 1;
  static final int ALWAYS_ABOVE_ZERO = 2;
  static final int ALWAYS_TRUE = 3;
  /**
   * Details which tests have been done statically during compilation.
   * Default is that all checks must be performed dynamically.
   */
  int staticChecks = FULL_CHECK;

  HBoundsCheck(length, index) : super(<HInstruction>[length, index]);

  HInstruction get length => inputs[1];
  HInstruction get index => inputs[0];
  bool isControlFlow() => true;

  HType get guaranteedType => HType.INTEGER;

  accept(HVisitor visitor) => visitor.visitBoundsCheck(this);
  int typeCode() => 2;
  bool typeEquals(other) => other is HBoundsCheck;
  bool dataEquals(HInstruction other) => true;
}

class HIntegerCheck extends HCheck {
  bool alwaysFalse = false;

  HIntegerCheck(value) : super(<HInstruction>[value]);

  HInstruction get value => inputs[0];
  bool isControlFlow() => true;

  HType get guaranteedType => HType.INTEGER;

  HType computeDesiredTypeForInput(HInstruction input, HTypeMap types) {
    // If the desired type of the input is already a number, we want
    // to specialize it to an integer.
    return input.isNumber(types)
      ? HType.INTEGER
      : super.computeDesiredTypeForInput(input, types);
  }

  accept(HVisitor visitor) => visitor.visitIntegerCheck(this);
  int typeCode() => 3;
  bool typeEquals(other) => other is HIntegerCheck;
  bool dataEquals(HInstruction other) => true;
}

class HConditionalBranch extends HControlFlow {
  HConditionalBranch(inputs) : super(inputs);
  HInstruction get condition => inputs[0];
  HBasicBlock get trueBranch => block.successors[0];
  HBasicBlock get falseBranch => block.successors[1];
  abstract toString();
}

class HControlFlow extends HInstruction {
  HControlFlow(inputs) : super(inputs);
  abstract toString();
  void prepareGvn(HTypeMap types) {
    // Control flow does not have side-effects.
  }
  bool isControlFlow() => true;
  bool isStatement(HTypeMap types) => true;
}

class HInvoke extends HInstruction {
  /**
    * The first argument must be the target: either an [HStatic] node, or
    * the receiver of a method-call. The remaining inputs are the arguments
    * to the invocation.
    */
  HInvoke(List<HInstruction> inputs) : super(inputs);
  static final int ARGUMENTS_OFFSET = 1;

  // TODO(floitsch): make class abstract instead of adding an abstract method.
  abstract accept(HVisitor visitor);
}

class HInvokeDynamic extends HInvoke {
  final Selector selector;
  Element element;

  HInvokeDynamic(this.selector, this.element, List<HInstruction> inputs)
    : super(inputs);
  toString() => 'invoke dynamic: $selector';
  HInstruction get receiver => inputs[0];

  // TODO(floitsch): make class abstract instead of adding an abstract method.
  abstract accept(HVisitor visitor);
}

class HInvokeClosure extends HInvokeDynamic {
  HInvokeClosure(Selector selector, List<HInstruction> inputs)
    : super(selector, null, inputs);
  accept(HVisitor visitor) => visitor.visitInvokeClosure(this);
}

class HInvokeDynamicMethod extends HInvokeDynamic {
  HInvokeDynamicMethod(Selector selector, List<HInstruction> inputs)
    : super(selector, null, inputs);
  toString() => 'invoke dynamic method: $selector';
  accept(HVisitor visitor) => visitor.visitInvokeDynamicMethod(this);
}

class HInvokeDynamicField extends HInvokeDynamic {
  HInvokeDynamicField(Selector selector, Element element,
                      List<HInstruction> inputs)
      : super(selector, element, inputs);
  toString() => 'invoke dynamic field: $selector';

  // TODO(floitsch): make class abstract instead of adding an abstract method.
  abstract accept(HVisitor visitor);
}

class HInvokeDynamicGetter extends HInvokeDynamicField {
  HInvokeDynamicGetter(selector, element, receiver)
    : super(selector, element,[receiver]);
  toString() => 'invoke dynamic getter: $selector';
  accept(HVisitor visitor) => visitor.visitInvokeDynamicGetter(this);
}

class HInvokeDynamicSetter extends HInvokeDynamicField {
  HInvokeDynamicSetter(selector, element, receiver, value)
    : super(selector, element, [receiver, value]);
  toString() => 'invoke dynamic setter: $selector';
  accept(HVisitor visitor) => visitor.visitInvokeDynamicSetter(this);
}

class HInvokeStatic extends HInvoke {
  static final int INVOKE_STATIC_TYPECODE = 30;

  /** The first input must be the target. */
  HInvokeStatic(inputs, [HType knownType = HType.UNKNOWN]) : super(inputs) {
    guaranteedType = knownType;
  }

  toString() => 'invoke static: ${element.name}';
  accept(HVisitor visitor) => visitor.visitInvokeStatic(this);
  int typeCode() => INVOKE_STATIC_TYPECODE;
  Element get element => target.element;
  HStatic get target => inputs[0];

  HType computeDesiredTypeForInput(HInstruction input, HTypeMap types) {
    // TODO(floitsch): we want the target to be a function.
    if (input == target) return HType.UNKNOWN;
    return computeDesiredTypeForNonTargetInput(input, types);
  }

  HType computeDesiredTypeForNonTargetInput(HInstruction input,
                                            HTypeMap types) {
    return HType.UNKNOWN;
  }
}

class HInvokeSuper extends HInvokeStatic {
  final bool isSetter;
  HInvokeSuper(inputs, [this.isSetter = false]) : super(inputs);
  toString() => 'invoke super: ${element.name}';
  accept(HVisitor visitor) => visitor.visitInvokeSuper(this);

  HInstruction get value {
    assert(isSetter);
    // Index 0: the element, index 1: 'this'.
    return inputs[2];
  }
}

class HInvokeInterceptor extends HInvokeStatic {
  final Selector selector;
  final SourceString name;
  final bool getter;
  final bool setter;

  HInvokeInterceptor(this.selector,
                     this.name,
                     List<HInstruction> inputs,
                     [HType knownType = HType.UNKNOWN,
                      this.getter = false,
                      this.setter = false])
      : super(inputs, knownType);

  toString() => 'invoke interceptor: ${element.name}';
  accept(HVisitor visitor) => visitor.visitInvokeInterceptor(this);

  bool isLengthGetter() {
    return getter && name == const SourceString('length');
  }

  bool isLengthGetterOnStringOrArray(HTypeMap types) {
    return isLengthGetter() && inputs[1].isIndexablePrimitive(types);
  }

  HType computeLikelyType(HTypeMap types) {
    // In general a length getter or method returns an int.
    if (name == const SourceString('length')) return HType.INTEGER;
    return HType.UNKNOWN;
  }

  HType computeTypeFromInputTypes(HTypeMap types) {
    if (isLengthGetterOnStringOrArray(types)) return HType.INTEGER;
    return HType.UNKNOWN;
  }

  HType computeDesiredTypeForNonTargetInput(HInstruction input,
                                            HTypeMap types) {
    // If the first argument is a string or an array and we invoke methods
    // on it that mutate it, then we want to restrict the incoming type to be
    // a mutable array.
    if (input == inputs[1] && input.isIndexablePrimitive(types)) {
      if (name == const SourceString('add')
          || name == const SourceString('removeLast')) {
        return HType.MUTABLE_ARRAY;
      }
    }
    return HType.UNKNOWN;
  }

  void prepareGvn(HTypeMap types) {
    if (isLengthGetterOnStringOrArray(types)) {
      setUseGvn();
      clearAllSideEffects();
      setDependsOnSomething();
    } else {
      setAllSideEffects();
    }
  }

  int typeCode() => 4;
  bool typeEquals(other) => other is HInvokeInterceptor;
  bool dataEquals(HInvokeInterceptor other) {
    return getter == other.getter && name == other.name;
  }
}

abstract class HFieldAccess extends HInstruction {
  final Element element;
  final SourceString fieldName;
  final LibraryElement library;

  HFieldAccess(this.fieldName, this.library, List<HInstruction> inputs)
      : element = null, super(inputs);

  HFieldAccess.withElement(Element element, List<HInstruction> inputs)
      : this.element = element,
        fieldName = element.name,
        library = element.getLibrary(),
        super(inputs);
}

class HFieldGet extends HFieldAccess {
  final bool isFinalOrConst;

  HFieldGet(SourceString name, LibraryElement library, HInstruction receiver,
            [this.isFinalOrConst = false])
      : super(name, library, <HInstruction>[receiver]);

  HFieldGet.withElement(Element element, HInstruction receiver,
                        [this.isFinalOrConst = false])
      : super.withElement(element, <HInstruction>[receiver]);

  HInstruction get receiver => inputs[0];

  accept(HVisitor visitor) => visitor.visitFieldGet(this);

  void prepareGvn(HTypeMap types) {
    setUseGvn();
    clearAllSideEffects();
    if (!isFinalOrConst) setDependsOnSomething();
  }

  int typeCode() => 27;
  bool typeEquals(other) => other is HFieldGet;
  bool dataEquals(HFieldGet other) => element == other.element;
  String toString() => "FieldGet ${element == null ? fieldName : element}";
}

class HFieldSet extends HFieldAccess {
  HFieldSet(SourceString name,
            LibraryElement library,
            HInstruction receiver,
            HInstruction value)
      : super(name, library, <HInstruction>[receiver, value]);

  HFieldSet.withElement(Element element,
                        HInstruction receiver,
                        HInstruction value)
      : super.withElement(element, <HInstruction>[receiver, value]);

  HInstruction get receiver => inputs[0];
  HInstruction get value => inputs[1];
  accept(HVisitor visitor) => visitor.visitFieldSet(this);

  void prepareGvn(HTypeMap types) {
    // TODO(ngeoffray): implement more fine grained side effects.
    setAllSideEffects();
  }

  bool isStatement(HTypeMap types) => true;
  String toString() => "FieldSet ${element == null ? fieldName : element}";
}

class HLocalGet extends HFieldGet {
  HLocalGet(Element element, HLocalValue local)
      : super.withElement(element, local);

  accept(HVisitor visitor) => visitor.visitLocalGet(this);

  HLocalValue get local => inputs[0];

  void prepareGvn(HTypeMap types) {
    setUseGvn();
    // TODO(floitsch): if the variable is not captured then it only depends
    // on assignments to the same variable. Otherwise we need to see if the
    // variable is mutated inside closures.
    setDependsOnSomething();
  }
}

class HLocalSet extends HFieldSet {
  HLocalSet(Element element, HLocalValue local, HInstruction value)
      : super.withElement(element, local, value);

  accept(HVisitor visitor) => visitor.visitLocalSet(this);

  HLocalValue get local => inputs[0];

  void prepareGvn(HTypeMap types) {
    // TODO(floitsch): implement more fine grained side effects.
    setAllSideEffects();
  }
}

class HForeign extends HInstruction {
  final DartString code;
  final HType foreignType;
  final bool _isStatement;

  HForeign(this.code, DartString declaredType, List<HInstruction> inputs)
      : foreignType = computeTypeFromDeclaredType(declaredType),
        _isStatement = false,
        super(inputs);
  HForeign.statement(this.code, List<HInstruction> inputs)
      : foreignType = HType.UNKNOWN,
        _isStatement = true,
        super(inputs);
  accept(HVisitor visitor) => visitor.visitForeign(this);

  static HType computeTypeFromDeclaredType(DartString declaredType) {
    if (declaredType.slowToString() == 'bool') return HType.BOOLEAN;
    if (declaredType.slowToString() == 'int') return HType.INTEGER;
    if (declaredType.slowToString() == 'double') return HType.DOUBLE;
    if (declaredType.slowToString() == 'num') return HType.NUMBER;
    if (declaredType.slowToString() == 'String') return HType.STRING;
    return HType.UNKNOWN;
  }

  HType get guaranteedType => foreignType;

  bool isStatement(HTypeMap types) => _isStatement;
}

class HForeignNew extends HForeign {
  ClassElement element;
  HForeignNew(this.element, List<HInstruction> inputs)
      : super(const LiteralDartString("new"),
              const LiteralDartString("Object"), inputs);
  accept(HVisitor visitor) => visitor.visitForeignNew(this);
}

class HInvokeBinary extends HInvokeStatic {
  HInvokeBinary(HStatic target, HInstruction left, HInstruction right)
      : super(<HInstruction>[target, left, right]);

  HInstruction get left => inputs[1];
  HInstruction get right => inputs[2];

  abstract BinaryOperation get operation();
  abstract isBuiltin(HTypeMap types);
}

class HBinaryArithmetic extends HInvokeBinary {
  HBinaryArithmetic(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);

  void prepareGvn(HTypeMap types) {
    // An arithmetic expression can take part in global value
    // numbering and do not have any side-effects if we know that all
    // inputs are numbers.
    if (isBuiltin(types)) {
      clearAllSideEffects();
      setUseGvn();
    } else {
      setAllSideEffects();
    }
  }

  bool isBuiltin(HTypeMap types)
      => left.isNumber(types) && right.isNumber(types);

  HType computeTypeFromInputTypes(HTypeMap types) {
    if (left.isInteger(types) && right.isInteger(types)) return HType.INTEGER;
    if (left.isNumber(types)) {
      if (left.isDouble(types) || right.isDouble(types)) return HType.DOUBLE;
      return HType.NUMBER;
    }
    return HType.UNKNOWN;
  }

  HType computeDesiredTypeForNonTargetInput(HInstruction input,
                                            HTypeMap types) {
    HType propagatedType = types[this];
    // If the desired output type should be an integer we want to get two
    // integers as arguments.
    if (propagatedType.isInteger()) return HType.INTEGER;
    // If the outgoing type should be a number we can get that if both inputs
    // are numbers. If we don't know the outgoing type we try to make it a
    // number.
    if (propagatedType.isUnknown() || propagatedType.isNumber()) {
      return HType.NUMBER;
    }
    // Even if the desired outgoing type is not a number we still want the
    // second argument to be a number if the first one is a number. This will
    // not help for the outgoing type, but at least the binary arithmetic
    // operation will not have type problems.
    // TODO(floitsch): normally we shouldn't request a number, but simply
    // throw an IllegalArgumentException if it isn't. This would be similar
    // to the array case.
    if (input == right && left.isNumber(types)) return HType.NUMBER;
    return HType.UNKNOWN;
  }

  HType computeLikelyType(HTypeMap types) {
    if (left.isTypeUnknown(types)) return HType.NUMBER;
    return HType.UNKNOWN;
  }

  // TODO(1603): The class should be marked as abstract.
  abstract BinaryOperation get operation();
}

class HAdd extends HBinaryArithmetic {
  HAdd(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitAdd(this);

  AddOperation get operation => const AddOperation();
  int typeCode() => 5;
  bool typeEquals(other) => other is HAdd;
  bool dataEquals(HInstruction other) => true;
}

class HDivide extends HBinaryArithmetic {
  HDivide(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitDivide(this);

  HType computeTypeFromInputTypes(HTypeMap types) {
    if (left.isNumber(types)) return HType.DOUBLE;
    return HType.UNKNOWN;
  }

  HType computeDesiredTypeForNonTargetInput(HInstruction input,
                                            HTypeMap types) {
    // A division can never return an integer. So don't ask for integer inputs.
    if (isInteger(types)) return HType.UNKNOWN;
    return super.computeDesiredTypeForNonTargetInput(input, types);
  }

  DivideOperation get operation => const DivideOperation();
  int typeCode() => 6;
  bool typeEquals(other) => other is HDivide;
  bool dataEquals(HInstruction other) => true;
}

class HModulo extends HBinaryArithmetic {
  HModulo(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitModulo(this);

  ModuloOperation get operation => const ModuloOperation();
  int typeCode() => 7;
  bool typeEquals(other) => other is HModulo;
  bool dataEquals(HInstruction other) => true;
}

class HMultiply extends HBinaryArithmetic {
  HMultiply(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitMultiply(this);

  MultiplyOperation get operation => const MultiplyOperation();
  int typeCode() => 8;
  bool typeEquals(other) => other is HMultiply;
  bool dataEquals(HInstruction other) => true;
}

class HSubtract extends HBinaryArithmetic {
  HSubtract(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitSubtract(this);

  SubtractOperation get operation => const SubtractOperation();
  int typeCode() => 9;
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
  HBasicBlock get defaultTarget => block.successors.last();

  accept(HVisitor visitor) => visitor.visitSwitch(this);

  String toString() => "HSwitch cases = $inputs";
}

class HTruncatingDivide extends HBinaryArithmetic {
  HTruncatingDivide(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitTruncatingDivide(this);

  TruncatingDivideOperation get operation
      => const TruncatingDivideOperation();
  int typeCode() => 10;
  bool typeEquals(other) => other is HTruncatingDivide;
  bool dataEquals(HInstruction other) => true;
}


// TODO(floitsch): Should HBinaryArithmetic really be the super class of
// HBinaryBitOp?
class HBinaryBitOp extends HBinaryArithmetic {
  HBinaryBitOp(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);

  HType computeTypeFromInputTypes(HTypeMap types) {
    // All bitwise operations on primitive types either produce an
    // integer or throw an error.
    if (left.isPrimitive(types)) return HType.INTEGER;
    return HType.UNKNOWN;
  }

  HType computeDesiredTypeForNonTargetInput(HInstruction input,
                                            HTypeMap types) {
    HType propagatedType = types[this];
    // If the outgoing type should be a number we can get that only if both
    // inputs are integers. If we don't know the outgoing type we try to make
    // it an integer.
    if (propagatedType.isUnknown() || propagatedType.isNumber()) {
      return HType.INTEGER;
    }
    return HType.UNKNOWN;
  }

  HType computeLikelyType(HTypeMap types) {
    if (left.isTypeUnknown(types)) return HType.INTEGER;
    return HType.UNKNOWN;
  }

  // TODO(floitsch): make class abstract instead of adding an abstract method.
  abstract accept(HVisitor visitor);
}

class HShiftLeft extends HBinaryBitOp {
  HShiftLeft(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitShiftLeft(this);

  // Shift left cannot be mapped to the native operator unless the
  // shift count is guaranteed to be an integer in the [0,31] range.
  bool isBuiltin(HTypeMap types) {
    if (!left.isNumber(types) || !right.isConstantInteger()) return false;
    HConstant rightConstant = right;
    IntConstant intConstant = rightConstant.constant;
    int count = intConstant.value;
    return count >= 0 && count <= 31;
  }

  ShiftLeftOperation get operation => const ShiftLeftOperation();
  int typeCode() => 11;
  bool typeEquals(other) => other is HShiftLeft;
  bool dataEquals(HInstruction other) => true;
}

class HShiftRight extends HBinaryBitOp {
  HShiftRight(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitShiftRight(this);

  // Shift right cannot be mapped to the native operator easily.
  bool isBuiltin(HTypeMap types) => false;

  ShiftRightOperation get operation => const ShiftRightOperation();
  int typeCode() => 12;
  bool typeEquals(other) => other is HShiftRight;
  bool dataEquals(HInstruction other) => true;
}

class HBitOr extends HBinaryBitOp {
  HBitOr(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitBitOr(this);

  BitOrOperation get operation => const BitOrOperation();
  int typeCode() => 13;
  bool typeEquals(other) => other is HBitOr;
  bool dataEquals(HInstruction other) => true;
}

class HBitAnd extends HBinaryBitOp {
  HBitAnd(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitBitAnd(this);

  BitAndOperation get operation => const BitAndOperation();
  int typeCode() => 14;
  bool typeEquals(other) => other is HBitAnd;
  bool dataEquals(HInstruction other) => true;
}

class HBitXor extends HBinaryBitOp {
  HBitXor(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitBitXor(this);

  BitXorOperation get operation => const BitXorOperation();
  int typeCode() => 15;
  bool typeEquals(other) => other is HBitXor;
  bool dataEquals(HInstruction other) => true;
}

class HInvokeUnary extends HInvokeStatic {
  HInvokeUnary(HStatic target, HInstruction input)
      : super(<HInstruction>[target, input]);

  HInstruction get operand => inputs[1];

  void prepareGvn(HTypeMap types) {
    // A unary arithmetic expression can take part in global value
    // numbering and does not have any side-effects if its input is a
    // number.
    if (isBuiltin(types)) {
      clearAllSideEffects();
      setUseGvn();
    } else {
      setAllSideEffects();
    }
  }

  bool isBuiltin(HTypeMap types) => operand.isNumber(types);

  HType computeTypeFromInputTypes(HTypeMap types) {
    HType operandType = types[operand];
    if (operandType.isNumber()) return operandType;
    return HType.UNKNOWN;
  }

  HType computeDesiredTypeForNonTargetInput(HInstruction input,
                                            HTypeMap types) {
    HType propagatedType = types[this];
    // If the outgoing type should be a number (integer, double or both) we
    // want the outgoing type to be the input too.
    // If we don't know the outgoing type we try to make it a number.
    if (propagatedType.isNumber()) return propagatedType;
    if (propagatedType.isUnknown()) return HType.NUMBER;
    return HType.UNKNOWN;
  }

  HType computeLikelyType(HTypeMap types) => HType.NUMBER;

  abstract UnaryOperation get operation();
}

class HNegate extends HInvokeUnary {
  HNegate(HStatic target, HInstruction input) : super(target, input);
  accept(HVisitor visitor) => visitor.visitNegate(this);

  NegateOperation get operation => const NegateOperation();
  int typeCode() => 16;
  bool typeEquals(other) => other is HNegate;
  bool dataEquals(HInstruction other) => true;
}

class HBitNot extends HInvokeUnary {
  HBitNot(HStatic target, HInstruction input) : super(target, input);
  accept(HVisitor visitor) => visitor.visitBitNot(this);

  HType computeTypeFromInputTypes(HTypeMap types) {
    // All bitwise operations on primitive types either produce an
    // integer or throw an error.
    if (operand.isPrimitive(types)) return HType.INTEGER;
    return HType.UNKNOWN;
  }

  HType computeDesiredTypeForNonTargetInput(HInstruction input,
                                            HTypeMap types) {
    HType propagatedType = types[this];
    // Bit operations only work on integers. If there is no desired output
    // type or if it as a number we want to get an integer as input.
    if (propagatedType.isUnknown() || propagatedType.isNumber()) {
      return HType.INTEGER;
    }
    return HType.UNKNOWN;
  }

  BitNotOperation get operation => const BitNotOperation();
  int typeCode() => 17;
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
  toString() => (label !== null) ? 'break ${label.labelName}' : 'break';
  accept(HVisitor visitor) => visitor.visitBreak(this);
}

class HContinue extends HJump {
  HContinue(TargetElement target) : super(target);
  HContinue.toLabel(LabelElement label) : super.toLabel(label);
  toString() => (label !== null) ? 'continue ${label.labelName}' : 'continue';
  accept(HVisitor visitor) => visitor.visitContinue(this);
}

class HTry extends HControlFlow {
  HParameterValue exception;
  HBasicBlock catchBlock;
  HBasicBlock finallyBlock;
  HTry() : super(const <HInstruction>[]);
  toString() => 'try';
  accept(HVisitor visitor) => visitor.visitTry(this);
  HBasicBlock get joinBlock => this.block.successors.last();
}

class HIf extends HConditionalBranch {
  HBlockFlow blockInformation = null;
  HIf(HInstruction condition) : super(<HInstruction>[condition]);
  toString() => 'if';
  accept(HVisitor visitor) => visitor.visitIf(this);

  HBasicBlock get thenBlock {
    assert(block.dominatedBlocks[0] === block.successors[0]);
    return block.successors[0];
  }

  HBasicBlock get elseBlock {
    assert(block.dominatedBlocks[1] === block.successors[1]);
    return block.successors[1];
  }

  HBasicBlock get joinBlock => blockInformation.continuation;
}

class HLoopBranch extends HConditionalBranch {
  static final int CONDITION_FIRST_LOOP = 0;
  static final int DO_WHILE_LOOP = 1;

  final int kind;
  HLoopBranch(HInstruction condition, [this.kind = CONDITION_FIRST_LOOP])
      : super(<HInstruction>[condition]);
  toString() => 'loop-branch';
  accept(HVisitor visitor) => visitor.visitLoopBranch(this);

  bool isDoWhile() {
    return kind === DO_WHILE_LOOP;
  }
}

class HConstant extends HInstruction {
  final Constant constant;
  final HType constantType;
  HConstant.internal(this.constant, HType this.constantType)
      : super(<HInstruction>[]);

  void prepareGvn(HTypeMap types) {
    assert(!hasSideEffects(types));
  }

  toString() => 'literal: $constant';
  accept(HVisitor visitor) => visitor.visitConstant(this);

  HType get guaranteedType => constantType;

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

  // Maybe avoid this if the literal is big?
  bool isCodeMotionInvariant() => true;
}

class HNot extends HInstruction {
  HNot(HInstruction value) : super(<HInstruction>[value]);
  void prepareGvn(HTypeMap types) {
    assert(!hasSideEffects(types));
    setUseGvn();
  }

  HType get guaranteedType => HType.BOOLEAN;

  // 'Not' only works on booleans. That's what we want as input.
  HType computeDesiredTypeForInput(HInstruction input, HTypeMap types) {
    return HType.BOOLEAN;
  }

  accept(HVisitor visitor) => visitor.visitNot(this);
  int typeCode() => 18;
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

  void prepareGvn(HTypeMap types) {
    assert(!hasSideEffects(types));
  }
  toString() => 'local ${sourceElement.name}';
  accept(HVisitor visitor) => visitor.visitLocalValue(this);
  bool isCodeMotionInvariant() => true;
}

class HParameterValue extends HLocalValue {
  HParameterValue(Element element) : super(element);

  toString() => 'parameter ${sourceElement.name.slowToString()}';
  accept(HVisitor visitor) => visitor.visitParameterValue(this);
}

class HThis extends HParameterValue {
  HThis([HType type = HType.UNKNOWN]) : super(null) {
    guaranteedType = type;
  }
  toString() => 'this';
  accept(HVisitor visitor) => visitor.visitThis(this);
}

class HPhi extends HInstruction {
  static final IS_NOT_LOGICAL_OPERATOR = 0;
  static final IS_AND = 1;
  static final IS_OR = 2;

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
    input.usedBy.add(this);
  }

  // Compute the (shared) type of the inputs if any. If all inputs
  // have the same known type return it. If any two inputs have
  // different known types, we'll return a conflict -- otherwise we'll
  // simply return an unknown type.
  HType computeInputsType(bool ignoreUnknowns, HTypeMap types) {
    HType candidateType = HType.CONFLICTING;
    for (int i = 0, length = inputs.length; i < length; i++) {
      HType inputType = types[inputs[i]];
      if (ignoreUnknowns && inputType.isUnknown()) continue;
      // Phis need to combine the incoming types using the union operation.
      // For example, if one incoming edge has type integer and the other has
      // type double, then the phi is either an integer or double and thus has
      // type number.
      candidateType = candidateType.union(inputType);
      if (candidateType.isUnknown()) return HType.UNKNOWN;
    }
    return candidateType;
  }

  HType computeTypeFromInputTypes(HTypeMap types) {
    HType inputsType = computeInputsType(false, types);
    if (inputsType.isConflicting()) return HType.UNKNOWN;
    return inputsType;
  }

  HType computeDesiredTypeForInput(HInstruction input, HTypeMap types) {
    HType propagatedType = types[this];
    // Best case scenario for a phi is, when all inputs have the same type. If
    // there is no desired outgoing type we therefore try to unify the input
    // types (which is basically the [likelyType]).
    if (propagatedType.isUnknown()) return computeLikelyType(types);
    // When the desired outgoing type is conflicting we don't need to give any
    // requirements on the inputs.
    if (propagatedType.isConflicting()) return HType.UNKNOWN;
    // Otherwise the input type must match the desired outgoing type.
    return propagatedType;
  }

  HType computeLikelyType(HTypeMap types) {
    HType agreedType = computeInputsType(true, types);
    if (agreedType.isConflicting()) return HType.UNKNOWN;
    // Don't be too restrictive. If the agreed type is integer or double just
    // say that the likely type is number. If more is expected the type will be
    // propagated back.
    if (agreedType.isNumber()) return HType.NUMBER;
    return agreedType;
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

class HRelational extends HInvokeBinary {
  bool usesBoolifiedInterceptor = false;
  HRelational(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);

  void prepareGvn(HTypeMap types) {
    // Relational expressions can take part in global value numbering
    // and do not have any side-effects if we know all the inputs are
    // numbers. This can be improved for at least equality.
    if (isBuiltin(types)) {
      clearAllSideEffects();
      setUseGvn();
    } else {
      setAllSideEffects();
    }
  }

  HType computeTypeFromInputTypes(HTypeMap types) {
    if (left.isNumber(types) || usesBoolifiedInterceptor) return HType.BOOLEAN;
    return HType.UNKNOWN;
  }

  HType get guaranteedType {
    if (usesBoolifiedInterceptor) return HType.BOOLEAN;
    return HType.UNKNOWN;
  }

  HType computeDesiredTypeForNonTargetInput(HInstruction input,
                                            HTypeMap types) {
    HType propagatedType = types[this];
    // For all relational operations exept HEquals, we expect to get numbers
    // only. With numbers the outgoing type is a boolean. If something else
    // is desired, then numbers are incorrect, though.
    if (propagatedType.isUnknown() || propagatedType.isBoolean()) {
      if (left.isTypeUnknown(types) || left.isNumber(types)) {
        return HType.NUMBER;
      }
    }
    return HType.UNKNOWN;
  }

  HType computeLikelyType(HTypeMap types) => HType.BOOLEAN;

  bool isBuiltin(HTypeMap types)
      => left.isNumber(types) && right.isNumber(types);
  // TODO(1603): the class should be marked as abstract.
  abstract BinaryOperation get operation();
}

class HEquals extends HRelational {
  HEquals(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitEquals(this);

  bool isBuiltin(HTypeMap types) {
    // All primitive types have === semantics.
    // Note that this includes all constants except the user-constructed
    // objects.
    return types[left].isPrimitive() ||
        left.isConstantNull() ||
        right.isConstantNull();
  }

  HType computeTypeFromInputTypes(HTypeMap types) {
    if (isBuiltin(types) || usesBoolifiedInterceptor) return HType.BOOLEAN;
    return HType.UNKNOWN;
  }

  HType computeDesiredTypeForNonTargetInput(HInstruction input,
                                            HTypeMap types) {
    HType propagatedType = types[this];
    if (input == left && types[right].isUseful()) {
      // All our useful types have === semantics. But we don't want to
      // speculatively test for all possible types. Therefore we try to match
      // the two types. That is, if we see x == 3, then we speculatively test
      // if x is a number and bailout if it isn't.
      // If right is a number we don't need more than a number (no need to match
      // the exact type of right).
      if (right.isNumber(types)) return HType.NUMBER;
      // String equality testing is much more common than array equality
      // testing.
      if (right.isIndexablePrimitive(types)) return HType.STRING;
      return types[right];
    }
    // String equality testing is much more common than array equality testing.
    if (input == left && left.isIndexablePrimitive(types)) {
      return HType.READABLE_ARRAY;
    }
    // String equality testing is much more common than array equality testing.
    if (input == right && right.isIndexablePrimitive(types)) {
      return HType.STRING;
    }
    return HType.UNKNOWN;
  }

  EqualsOperation get operation => const EqualsOperation();
  int typeCode() => 19;
  bool typeEquals(other) => other is HEquals;
  bool dataEquals(HInstruction other) => true;
}

class HIdentity extends HRelational {
  HIdentity(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitIdentity(this);

  bool isBuiltin(HTypeMap types) => true;

  HType get guaranteedType => HType.BOOLEAN;
  HType computeTypeFromInputTypes(HTypeMap types)
      => HType.BOOLEAN;
  // Note that the identity operator really does not care for its input types.
  HType computeDesiredTypeForInput(HInstruction input, HTypeMap types)
      => HType.UNKNOWN;

  IdentityOperation get operation => const IdentityOperation();
  int typeCode() => 20;
  bool typeEquals(other) => other is HIdentity;
  bool dataEquals(HInstruction other) => true;
}

class HGreater extends HRelational {
  HGreater(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitGreater(this);

  GreaterOperation get operation => const GreaterOperation();
  int typeCode() => 21;
  bool typeEquals(other) => other is HGreater;
  bool dataEquals(HInstruction other) => true;
}

class HGreaterEqual extends HRelational {
  HGreaterEqual(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitGreaterEqual(this);

  GreaterEqualOperation get operation => const GreaterEqualOperation();
  int typeCode() => 22;
  bool typeEquals(other) => other is HGreaterEqual;
  bool dataEquals(HInstruction other) => true;
}

class HLess extends HRelational {
  HLess(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitLess(this);

  LessOperation get operation => const LessOperation();
  int typeCode() => 23;
  bool typeEquals(other) => other is HLess;
  bool dataEquals(HInstruction other) => true;
}

class HLessEqual extends HRelational {
  HLessEqual(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitLessEqual(this);

  LessEqualOperation get operation => const LessEqualOperation();
  int typeCode() => 24;
  bool typeEquals(other) => other is HLessEqual;
  bool dataEquals(HInstruction other) => true;
}

class HReturn extends HControlFlow {
  HReturn(value) : super(<HInstruction>[value]);
  toString() => 'return';
  accept(HVisitor visitor) => visitor.visitReturn(this);
}

class HThrow extends HControlFlow {
  final bool isRethrow;
  HThrow(value, [this.isRethrow = false]) : super(<HInstruction>[value]);
  toString() => 'throw';
  accept(HVisitor visitor) => visitor.visitThrow(this);
}

class HStatic extends HInstruction {
  final Element element;
  HStatic(this.element) : super(<HInstruction>[]) { assert(element !== null); }

  void prepareGvn(HTypeMap types) {
    if (!element.isAssignable()) {
      clearAllSideEffects();
      setUseGvn();
    }
  }
  toString() => 'static ${element.name}';
  accept(HVisitor visitor) => visitor.visitStatic(this);

  int gvnHashCode() => super.gvnHashCode() ^ element.hashCode();
  int typeCode() => 25;
  bool typeEquals(other) => other is HStatic;
  bool dataEquals(HStatic other) => element == other.element;
  bool isCodeMotionInvariant() => !element.isAssignable();
}

class HStaticStore extends HInstruction {
  Element element;
  HStaticStore(this.element, HInstruction value) : super(<HInstruction>[value]);
  toString() => 'static store ${element.name}';
  accept(HVisitor visitor) => visitor.visitStaticStore(this);

  int typeCode() => 26;
  bool typeEquals(other) => other is HStaticStore;
  bool dataEquals(HStaticStore other) => element == other.element;
  bool isStatement(HTypeMap types) => true;
}

class HLiteralList extends HInstruction {
  HLiteralList(inputs) : super(inputs);
  toString() => 'literal list';
  accept(HVisitor visitor) => visitor.visitLiteralList(this);

  HType get guaranteedType => HType.MUTABLE_ARRAY;

  void prepareGvn(HTypeMap types) {
    assert(!hasSideEffects(types));
  }
}

class HIndex extends HInvokeStatic {
  HIndex(HStatic target, HInstruction receiver, HInstruction index)
      : super(<HInstruction>[target, receiver, index]);
  toString() => 'index operator';
  accept(HVisitor visitor) => visitor.visitIndex(this);

  void prepareGvn(HTypeMap types) {
    if (isBuiltin(types)) {
      clearAllSideEffects();
    } else {
      setAllSideEffects();
    }
  }

  HInstruction get receiver => inputs[1];
  HInstruction get index => inputs[2];

  HType computeDesiredTypeForNonTargetInput(HInstruction input,
                                            HTypeMap types) {
    if (input == receiver &&
        (index.isTypeUnknown(types) || index.isNumber(types))) {
      return HType.INDEXABLE_PRIMITIVE;
    }
    // The index should be an int when the receiver is a string or array.
    // However it turns out that inserting an integer check in the optimized
    // version is cheaper than having another bailout case. This is true,
    // because the integer check will simply throw if it fails.
    return HType.UNKNOWN;
  }

  bool isBuiltin(HTypeMap types)
      => receiver.isIndexablePrimitive(types) && index.isInteger(types);
}

class HIndexAssign extends HInvokeStatic {
  HIndexAssign(HStatic target,
               HInstruction receiver,
               HInstruction index,
               HInstruction value)
      : super(<HInstruction>[target, receiver, index, value]);
  toString() => 'index assign operator';
  accept(HVisitor visitor) => visitor.visitIndexAssign(this);

  HInstruction get receiver => inputs[1];
  HInstruction get index => inputs[2];
  HInstruction get value => inputs[3];

  // Note, that we don't have a computeTypeFromInputTypes, since [HIndexAssign]
  // is never used as input.

  HType computeDesiredTypeForNonTargetInput(HInstruction input,
                                            HTypeMap types) {
    if (input == receiver &&
        (index.isTypeUnknown(types) || index.isNumber(types))) {
      return HType.MUTABLE_ARRAY;
    }
    // The index should be an int when the receiver is a string or array.
    // However it turns out that inserting an integer check in the optimized
    // version is cheaper than having another bailout case. This is true,
    // because the integer check will simply throw if it fails.
    return HType.UNKNOWN;
  }

  bool isBuiltin(HTypeMap types)
      => receiver.isMutableArray(types) && index.isInteger(types);
  bool isStatement(HTypeMap types) => !isBuiltin(types);
}

class HIs extends HInstruction {
  final Type typeExpression;
  final bool nullOk;

  HIs.withTypeInfoCall(this.typeExpression, HInstruction expression,
                       HInstruction typeInfo, [this.nullOk = false])
    : super(<HInstruction>[expression, typeInfo]);

  HIs(this.typeExpression, HInstruction expression, [this.nullOk = false])
     : super(<HInstruction>[expression]);

  HInstruction get expression => inputs[0];

  HInstruction get typeInfoCall => inputs[1];

  HType get guaranteedType => HType.BOOLEAN;

  accept(HVisitor visitor) => visitor.visitIs(this);

  toString() => "$expression is $typeExpression";
}

class HTypeConversion extends HCheck {
  HType type;
  final int kind;

  static final int NO_CHECK = 0;
  static final int CHECKED_MODE_CHECK = 1;
  static final int ARGUMENT_TYPE_CHECK = 2;
  static final int CAST_TYPE_CHECK = 3;

  HTypeConversion(this.type, HInstruction input, [this.kind = NO_CHECK])
      : super(<HInstruction>[input]) {
    sourceElement = input.sourceElement;
  }
  HTypeConversion.checkedModeCheck(HType type, HInstruction input)
      : this(type, input, CHECKED_MODE_CHECK);
  HTypeConversion.argumentTypeCheck(HType type, HInstruction input)
      : this(type, input, ARGUMENT_TYPE_CHECK);
  HTypeConversion.castCheck(HType type, HInstruction input)
      : this(type, input, CAST_TYPE_CHECK);


  bool get isChecked => kind != NO_CHECK;
  bool get isCheckedModeCheck => kind == CHECKED_MODE_CHECK;
  bool get isArgumentTypeCheck => kind == ARGUMENT_TYPE_CHECK;
  bool get isCastTypeCheck => kind == CAST_TYPE_CHECK;

  HType get guaranteedType => type;

  accept(HVisitor visitor) => visitor.visitTypeConversion(this);

  bool isStatement(HTypeMap types) => kind == ARGUMENT_TYPE_CHECK;
  bool isControlFlow() => kind == ARGUMENT_TYPE_CHECK;

  int typeCode() => 28;
  bool typeEquals(HInstruction other) => other is HTypeConversion;
  bool dataEquals(HTypeConversion other) {
    return type == other.type && kind == other.kind;
  }
}

class HStringConcat extends HInstruction {
  final Node node;
  HStringConcat(HInstruction left, HInstruction right, this.node)
      : super(<HInstruction>[left, right]);
  HType get guaranteedType => HType.STRING;

  HInstruction get left => inputs[0];
  HInstruction get right => inputs[1];

  accept(HVisitor visitor) => visitor.visitStringConcat(this);
  toString() => "string concat";
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
    if (block === header) return;
    HBasicBlock parentHeader = block.parentLoopHeader;
    if (parentHeader === header) {
      // Nothing to do in this case.
    } else if (parentHeader !== null) {
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
interface HBlockInformation {
  HBasicBlock get start();
  HBasicBlock get end();
  bool accept(HBlockInformationVisitor visitor);
}


/**
 * Information about a statement-like structure.
 */
interface HStatementInformation extends HBlockInformation {
  bool accept(HStatementInformationVisitor visitor);
}


/**
 * Information about an expression-like structure.
 */
interface HExpressionInformation extends HBlockInformation {
  bool accept(HExpressionInformationVisitor visitor);
  HInstruction get conditionExpression();
}


interface HStatementInformationVisitor {
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


interface HExpressionInformationVisitor {
  bool visitAndOrInfo(HAndOrBlockInformation info);
  bool visitSubExpressionInfo(HSubExpressionBlockInformation info);
}


interface HBlockInformationVisitor extends HStatementInformationVisitor,
                                           HExpressionInformationVisitor {
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
  HBasicBlock get end => statements.last().end;

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
                           [this.isContinue = false]) :
      this.labels = labels, this.target = labels[0].target;

  HLabeledBlockInformation.implicit(this.body,
                                    this.target,
                                    [this.isContinue = false])
      : this.labels = const<LabelElement>[];

  HBasicBlock get start => body.start;
  HBasicBlock get end => body.end;

  bool accept(HStatementInformationVisitor visitor) =>
    visitor.visitLabeledBlockInfo(this);
}

class LoopTypeVisitor extends AbstractVisitor {
  const LoopTypeVisitor();
  int visitNode(Node node) => HLoopBlockInformation.NOT_A_LOOP;
  int visitWhile(While node) => HLoopBlockInformation.WHILE_LOOP;
  int visitFor(For node) => HLoopBlockInformation.FOR_LOOP;
  int visitDoWhile(DoWhile node) => HLoopBlockInformation.DO_WHILE_LOOP;
  int visitForIn(ForIn node) => HLoopBlockInformation.FOR_IN_LOOP;
}

class HLoopBlockInformation implements HStatementInformation {
  static final int WHILE_LOOP = 0;
  static final int FOR_LOOP = 1;
  static final int DO_WHILE_LOOP = 2;
  static final int FOR_IN_LOOP = 3;
  static final int NOT_A_LOOP = -1;

  final int kind;
  final HExpressionInformation initializer;
  final HExpressionInformation condition;
  final HStatementInformation body;
  final HExpressionInformation updates;
  final TargetElement target;
  final List<LabelElement> labels;
  final Node sourcePosition;

  HLoopBlockInformation(this.kind,
                        this.initializer,
                        this.condition,
                        this.body,
                        this.updates,
                        this.target,
                        this.labels,
                        this.sourcePosition);

  HBasicBlock get start {
    if (initializer !== null) return initializer.start;
    if (kind == DO_WHILE_LOOP) {
      return body.start;
    }
    return condition.start;
  }

  HBasicBlock get loopHeader {
    return kind == DO_WHILE_LOOP ? body.start : condition.start;
  }

  HBasicBlock get end {
    if (updates !== null) return updates.end;
    if (kind == DO_WHILE_LOOP) {
      return condition.end;
    }
    return body.end;
  }

  static int loopType(Node node) {
    return node.accept(const LoopTypeVisitor());
  }

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
  HBasicBlock get end => elseGraph === null ? thenGraph.end : elseGraph.end;

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
  final HParameterValue catchVariable;
  final HStatementInformation catchBlock;
  final HStatementInformation finallyBlock;
  HTryBlockInformation(this.body,
                       this.catchVariable,
                       this.catchBlock,
                       this.finallyBlock);

  HBasicBlock get start => body.start;
  HBasicBlock get end =>
      finallyBlock === null ? catchBlock.end : finallyBlock.end;

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
    assert(!statements.isEmpty());
    return statements.last().end;
  }

  bool accept(HStatementInformationVisitor visitor) =>
      visitor.visitSwitchInfo(this);
}
