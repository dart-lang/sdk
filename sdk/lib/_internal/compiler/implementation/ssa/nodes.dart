// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

abstract class HVisitor<R> {
  R visitAdd(HAdd node);
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
  R visitInterceptor(HInterceptor node);
  R visitInvokeClosure(HInvokeClosure node);
  R visitInvokeDynamicGetter(HInvokeDynamicGetter node);
  R visitInvokeDynamicMethod(HInvokeDynamicMethod node);
  R visitInvokeDynamicSetter(HInvokeDynamicSetter node);
  R visitInvokeStatic(HInvokeStatic node);
  R visitInvokeSuper(HInvokeSuper node);
  R visitInvokeConstructorBody(HInvokeConstructorBody node);
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
  R visitOneShotInterceptor(HOneShotInterceptor node);
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
  R visitTypeConversion(HTypeConversion node);
  R visitTypeKnown(HTypeKnown node);
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

  static TypeMask mapConstantTypeToSsaType(Constant constant,
                                           Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    if (constant.isNull()) return backend.nullType;
    if (constant.isBool()) return backend.boolType;
    if (constant.isInt()) return backend.intType;
    if (constant.isDouble()) return backend.doubleType;
    if (constant.isString()) return backend.stringType;
    if (constant.isList()) return backend.readableArrayType;
    if (constant.isFunction()) return backend.nonNullType;
    if (constant.isSentinel()) return backend.nonNullType;
    // TODO(sra): What is the type of the prototype of an interceptor?
    if (constant.isInterceptor()) return backend.nonNullType;
    ObjectConstant objectConstant = constant;
    if (backend.isInterceptorClass(objectConstant.type.element)) {
      return backend.nonNullType;
    }
    return new TypeMask.nonNullExact(objectConstant.type.element);
  }

  HConstant addConstant(Constant constant, Compiler compiler) {
    HConstant result = constants[constant];
    if (result == null) {
      TypeMask type = mapConstantTypeToSsaType(constant, compiler);
      result = new HConstant.internal(constant, type);
      entry.addAtExit(result);
      constants[constant] = result;
    } else if (result.block == null) {
      // The constant was not used anymore.
      entry.addAtExit(result);
    }
    return result;
  }

  HConstant addConstantInt(int i, Compiler compiler) {
    return addConstant(compiler.backend.constantSystem.createInt(i), compiler);
  }

  HConstant addConstantDouble(double d, Compiler compiler) {
    return addConstant(
        compiler.backend.constantSystem.createDouble(d), compiler);
  }

  HConstant addConstantString(DartString str,
                              Node diagnosticNode,
                              Compiler compiler) {
    return addConstant(
        compiler.backend.constantSystem.createString(str, diagnosticNode),
        compiler);
  }

  HConstant addConstantBool(bool value, Compiler compiler) {
    return addConstant(
        compiler.backend.constantSystem.createBool(value), compiler);
  }

  HConstant addConstantNull(Compiler compiler) {
    return addConstant(compiler.backend.constantSystem.createNull(), compiler);
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
  visitInterceptor(HInterceptor node) => visitInstruction(node);
  visitInvokeClosure(HInvokeClosure node)
      => visitInvokeDynamic(node);
  visitInvokeConstructorBody(HInvokeConstructorBody node)
      => visitInvokeStatic(node);
  visitInvokeDynamicMethod(HInvokeDynamicMethod node)
      => visitInvokeDynamic(node);
  visitInvokeDynamicGetter(HInvokeDynamicGetter node)
      => visitInvokeDynamicField(node);
  visitInvokeDynamicSetter(HInvokeDynamicSetter node)
      => visitInvokeDynamicField(node);
  visitInvokeStatic(HInvokeStatic node) => visitInvoke(node);
  visitInvokeSuper(HInvokeSuper node) => visitInvokeStatic(node);
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
  visitIs(HIs node) => visitInstruction(node);
  visitTypeConversion(HTypeConversion node) => visitCheck(node);
  visitTypeKnown(HTypeKnown node) => visitCheck(node);
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
    blockFlow != null &&
    blockFlow.body is HLabeledBlockInformation;

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

  HInstruction(this.inputs, this.instructionType)
      : id = idCounter++, usedBy = <HInstruction>[] {
    assert(inputs.every((e) => e != null));
  }

  int get hashCode => id;

  bool useGvn() => _useGvn;
  void setUseGvn() { _useGvn = true; }

  void updateInput(int i, HInstruction insn) {
    assert(insn != null);
    inputs[i] = insn;
  }

  /**
   * A pure instruction is an instruction that does not have any side
   * effect, nor any dependency. They can be moved anywhere in the
   * graph.
   */
  bool isPure() {
    return !sideEffects.hasSideEffects()
        && !sideEffects.dependsOnSomething()
        && !canThrow();
  }

  // Overridden by [HCheck] to return the actual non-[HCheck]
  // instruction it checks against.
  HInstruction nonCheck() => this;

  // Can this node throw an exception?
  bool canThrow() => false;

  // Does this node potentially affect control flow.
  bool isControlFlow() => false;

  bool isExact() => instructionType.isExact || isNull();

  bool canBeNull() => instructionType.isNullable;

  bool isNull() => instructionType.isEmpty && instructionType.isNullable;
  bool isConflicting() {
    return instructionType.isEmpty && !instructionType.isNullable;
  }

  bool canBePrimitive(Compiler compiler) {
    return canBePrimitiveNumber(compiler)
        || canBePrimitiveArray(compiler)
        || canBePrimitiveBoolean(compiler)
        || canBePrimitiveString(compiler)
        || isNull();
  }

  bool canBePrimitiveNumber(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return instructionType.contains(backend.jsNumberClass, compiler)
        || instructionType.contains(backend.jsIntClass, compiler)
        || instructionType.contains(backend.jsDoubleClass, compiler);
  }

  bool canBePrimitiveBoolean(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return instructionType.contains(backend.jsBoolClass, compiler);
  }

  bool canBePrimitiveArray(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return instructionType.contains(backend.jsArrayClass, compiler)
        || instructionType.contains(backend.jsFixedArrayClass, compiler)
        || instructionType.contains(backend.jsExtendableArrayClass, compiler);
  }

  bool isIndexablePrimitive(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return instructionType.containsOnlyString(compiler)
        || instructionType.satisfies(backend.jsIndexableClass, compiler);
  }

  bool isFixedArray(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return instructionType.containsOnly(backend.jsFixedArrayClass);
  }

  bool isExtendableArray(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return instructionType.containsOnly(backend.jsExtendableArrayClass);
  }

  bool isMutableArray(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return instructionType.satisfies(backend.jsMutableArrayClass, compiler);
  }

  bool isReadableArray(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return instructionType.satisfies(backend.jsArrayClass, compiler);
  }

  bool isMutableIndexable(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return instructionType.satisfies(backend.jsMutableIndexableClass, compiler);
  }

  bool isArray(Compiler compiler) => isReadableArray(compiler);

  bool canBePrimitiveString(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return instructionType.contains(backend.jsStringClass, compiler);
  }

  bool isInteger(Compiler compiler) {
    return instructionType.containsOnlyInt(compiler)
        && !instructionType.isNullable;
  }

  bool isIntegerOrNull(Compiler compiler) {
    return instructionType.containsOnlyInt(compiler);
  }

  bool isNumber(Compiler compiler) {
    return instructionType.containsOnlyNum(compiler)
        && !instructionType.isNullable;
  }

  bool isNumberOrNull(Compiler compiler) {
    return instructionType.containsOnlyNum(compiler);
  }

  bool isDouble(Compiler compiler) {
    return instructionType.containsOnlyDouble(compiler)
        && !instructionType.isNullable;
  }

  bool isDoubleOrNull(Compiler compiler) {
    return instructionType.containsOnlyDouble(compiler);
  }

  bool isBoolean(Compiler compiler) {
    return instructionType.containsOnlyBool(compiler)
        && !instructionType.isNullable;
  }

  bool isBooleanOrNull(Compiler compiler) {
    return instructionType.containsOnlyBool(compiler);
  }

  bool isString(Compiler compiler) {
    return instructionType.containsOnlyString(compiler);
  }

  bool isPrimitive(Compiler compiler) {
    return (isPrimitiveOrNull(compiler) && !instructionType.isNullable)
        || isNull();
  }

  bool isPrimitiveOrNull(Compiler compiler) {
    return isIndexablePrimitive(compiler)
        || isNumberOrNull(compiler)
        || isBooleanOrNull(compiler)
        || isNull();
  }

  /**
   * Type of the unstruction.
   */
  TypeMask instructionType;

  Selector get selector => null;
  HInstruction getDartReceiver(Compiler compiler) => null;
  bool onlyThrowsNSM() => false;

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

  // Compute the set of users of this instruction that is dominated by
  // [other]. If [other] is a user of [this], it is included in the
  // returned set.
  Setlet<HInstruction> dominatedUsers(HInstruction other) {
    // Keep track of all instructions that we have to deal with later
    // and count the number of them that are in the current block.
    Setlet<HInstruction> users = new Setlet<HInstruction>();
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

  void replaceAllUsersDominatedBy(HInstruction cursor,
                                  HInstruction newInstruction) {
    Setlet<HInstruction> users = dominatedUsers(cursor);
    for (HInstruction user in users) {
      user.changeUse(this, newInstruction);
    }
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
    type = type.unalias(compiler);
    // Only the builder knows how to create [HTypeConversion]
    // instructions with generics. It has the generic type context
    // available.
    assert(type.kind != TypeKind.TYPE_VARIABLE);
    assert(type.treatAsRaw || type.kind == TypeKind.FUNCTION);
    if (type.isDynamic) return this;
    // The type element is either a class or the void element.
    Element element = type.element;
    if (identical(element, compiler.objectClass)) return this;
    JavaScriptBackend backend = compiler.backend;
    if (type.kind != TypeKind.INTERFACE) {
      return new HTypeConversion(type, kind, backend.dynamicType, this);
    } else if (kind == HTypeConversion.BOOLEAN_CONVERSION_CHECK) {
      // Boolean conversion checks work on non-nullable booleans.
      return new HTypeConversion(type, kind, backend.boolType, this);
    } else if (kind == HTypeConversion.CHECKED_MODE_CHECK && !type.treatAsRaw) {
      throw 'creating compound check to $type (this = ${this})';
    } else {
      TypeMask subtype = new TypeMask.subtype(element.declaration);
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
  HBoolify(HInstruction value, TypeMask type)
      : super(<HInstruction>[value], type) {
    setUseGvn();
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
  Element element;

  HInvokeDynamic(Selector selector,
                 this.element,
                 List<HInstruction> inputs,
                 TypeMask type,
                 [bool isIntercepted = false])
    : super(inputs, type),
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
   * Returns whether this call is on an interceptor object.
   */
  bool isCallOnInterceptor(Compiler compiler) {
    return isInterceptedCall && receiver.isInterceptor(compiler);
  }

  int typeCode() => HInstruction.INVOKE_DYNAMIC_TYPECODE;
  bool typeEquals(other) => other is HInvokeDynamic;
  bool dataEquals(HInvokeDynamic other) {
    // Use the name and the kind instead of [Selector.operator==]
    // because we don't need to check the arity (already checked in
    // [gvnEquals]), and the receiver types may not be in sync.
    return selector.name == other.selector.name
        && selector.kind == other.selector.kind;
  }
}

class HInvokeClosure extends HInvokeDynamic {
  HInvokeClosure(Selector selector, List<HInstruction> inputs, TypeMask type)
    : super(selector, null, inputs, type) {
    assert(selector.isClosureCall());
  }
  accept(HVisitor visitor) => visitor.visitInvokeClosure(this);
}

class HInvokeDynamicMethod extends HInvokeDynamic {
  HInvokeDynamicMethod(Selector selector,
                       List<HInstruction> inputs,
                       TypeMask type,
                       [bool isIntercepted = false])
    : super(selector, null, inputs, type, isIntercepted);

  String toString() => 'invoke dynamic method: $selector';
  accept(HVisitor visitor) => visitor.visitInvokeDynamicMethod(this);

  bool isIndexOperatorOnIndexablePrimitive(Compiler compiler) {
    return isInterceptedCall
        && selector.kind == SelectorKind.INDEX
        && selector.name == '[]'
        && inputs[1].isIndexablePrimitive(compiler);
  }
}

abstract class HInvokeDynamicField extends HInvokeDynamic {
  final bool isSideEffectFree;
  HInvokeDynamicField(
      Selector selector, Element element, List<HInstruction> inputs,
      TypeMask type, this.isSideEffectFree)
      : super(selector, element, inputs, type);
  toString() => 'invoke dynamic field: $selector';
}

class HInvokeDynamicGetter extends HInvokeDynamicField {
  HInvokeDynamicGetter(selector, element, inputs, type, isSideEffectFree)
    : super(selector, element, inputs, type, isSideEffectFree) {
    sideEffects.clearAllSideEffects();
    if (isSideEffectFree) {
      setUseGvn();
      sideEffects.setDependsOnInstancePropertyStore();
    } else {
      sideEffects.setDependsOnSomething();
      sideEffects.setAllSideEffects();
    }
  }
  toString() => 'invoke dynamic getter: $selector';
  accept(HVisitor visitor) => visitor.visitInvokeDynamicGetter(this);
}

class HInvokeDynamicSetter extends HInvokeDynamicField {
  HInvokeDynamicSetter(selector, element, inputs, type, isSideEffectFree)
    : super(selector, element, inputs, type, isSideEffectFree) {
    sideEffects.clearAllSideEffects();
    if (isSideEffectFree) {
      sideEffects.setChangesInstanceProperty();
    } else {
      sideEffects.setAllSideEffects();
      sideEffects.setDependsOnSomething();
    }
  }
  toString() => 'invoke dynamic setter: $selector';
  accept(HVisitor visitor) => visitor.visitInvokeDynamicSetter(this);
}

class HInvokeStatic extends HInvoke {
  final Element element;

  /// If this instruction is a call to a constructor, [instantiatedTypes]
  /// contains the type(s) used in the (Dart) `New` expression(s).
  /// The [instructionType] of this node is not enough, because we also need
  /// the type arguments.  See also [SsaBuilder.currentInlinedInstantiations].
  List<DartType> instantiatedTypes;

  /** The first input must be the target. */
  HInvokeStatic(this.element, inputs, TypeMask type) : super(inputs, type);

  toString() => 'invoke static: ${element.name}';
  accept(HVisitor visitor) => visitor.visitInvokeStatic(this);
  int typeCode() => HInstruction.INVOKE_STATIC_TYPECODE;
}

class HInvokeSuper extends HInvokeStatic {
  /** The class where the call to super is being done. */
  final ClassElement caller;
  final bool isSetter;
  final Selector selector;

  HInvokeSuper(Element element,
               this.caller,
               this.selector,
               inputs,
               type,
               {this.isSetter})
      : super(element, inputs, type);
  toString() => 'invoke super: ${element.name}';
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
  HInvokeConstructorBody(element, inputs, type)
      : super(element, inputs, type);

  String toString() => 'invoke constructor body: ${element.name}';
  accept(HVisitor visitor) => visitor.visitInvokeConstructorBody(this);
}

abstract class HFieldAccess extends HInstruction {
  final Element element;

  HFieldAccess(Element element, List<HInstruction> inputs, TypeMask type)
      : this.element = element, super(inputs, type);

  HInstruction get receiver => inputs[0];
}

class HFieldGet extends HFieldAccess {
  final bool isAssignable;

  HFieldGet(Element element,
            HInstruction receiver,
            TypeMask type,
            {bool isAssignable})
      : this.isAssignable = (isAssignable != null)
            ? isAssignable
            : element.isAssignable(),
        super(element, <HInstruction>[receiver], type) {
    sideEffects.clearAllSideEffects();
    setUseGvn();
    if (this.isAssignable) {
      sideEffects.setDependsOnInstancePropertyStore();
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

  HInstruction getDartReceiver(Compiler compiler) => receiver;
  bool onlyThrowsNSM() => true;
  bool get isNullCheck => element == null;

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
      : super(element, <HInstruction>[receiver, value],
              const TypeMask.nonNullEmpty()) {
    sideEffects.clearAllSideEffects();
    sideEffects.setChangesInstanceProperty();
  }

  bool canThrow() => receiver.canBeNull();

  HInstruction getDartReceiver(Compiler compiler) => receiver;
  bool onlyThrowsNSM() => true;

  HInstruction get value => inputs[1];
  accept(HVisitor visitor) => visitor.visitFieldSet(this);

  bool isJsStatement() => true;
  String toString() => "FieldSet $element";
}

class HLocalGet extends HFieldAccess {
  // No need to use GVN for a [HLocalGet], it is just a local
  // access.
  HLocalGet(Element element, HLocalValue local, TypeMask type)
      : super(element, <HInstruction>[local], type);

  accept(HVisitor visitor) => visitor.visitLocalGet(this);

  HLocalValue get local => inputs[0];
}

class HLocalSet extends HFieldAccess {
  HLocalSet(Element element, HLocalValue local, HInstruction value)
      : super(element, <HInstruction>[local, value],
              const TypeMask.nonNullEmpty());

  accept(HVisitor visitor) => visitor.visitLocalSet(this);

  HLocalValue get local => inputs[0];
  HInstruction get value => inputs[1];
  bool isJsStatement() => true;
}

class HForeign extends HInstruction {
  final js.Node codeAst;
  final bool isStatement;
  final native.NativeBehavior nativeBehavior;

  HForeign(this.codeAst,
           TypeMask type,
           List<HInstruction> inputs,
           {this.isStatement: false,
            SideEffects effects,
            native.NativeBehavior nativeBehavior})
      : this.nativeBehavior = nativeBehavior, super(inputs, type) {
    if (effects == null && nativeBehavior != null) {
      effects = nativeBehavior.sideEffects;
    }
    if (effects != null) sideEffects.add(effects);
  }

  HForeign.statement(codeAst, List<HInstruction> inputs,
                     SideEffects effects,
                     native.NativeBehavior nativeBehavior,
                     TypeMask type)
      : this(codeAst, type, inputs, isStatement: true,
             effects: effects, nativeBehavior: nativeBehavior);

  accept(HVisitor visitor) => visitor.visitForeign(this);

  bool isJsStatement() => isStatement;
  bool canThrow() {
    return sideEffects.hasSideEffects() || sideEffects.dependsOnSomething();
  }
}

class HForeignNew extends HForeign {
  ClassElement element;

  /// If this field is not `null`, this call is from an inlined constructor and
  /// we have to register the instantiated type in the code generator.
  /// The [instructionType] of this node is not enough, because we also need
  /// the type arguments.  See also [SsaBuilder.currentInlinedInstantiations].
  List<DartType> instantiatedTypes;

  HForeignNew(this.element, TypeMask type, List<HInstruction> inputs,
              [this.instantiatedTypes])
      : super(null, type, inputs);

  accept(HVisitor visitor) => visitor.visitForeignNew(this);
}

abstract class HInvokeBinary extends HInstruction {
  final Selector selector;
  HInvokeBinary(HInstruction left, HInstruction right, this.selector, type)
      : super(<HInstruction>[left, right], type) {
    sideEffects.clearAllSideEffects();
    setUseGvn();
  }

  HInstruction get left => inputs[0];
  HInstruction get right => inputs[1];

  BinaryOperation operation(ConstantSystem constantSystem);
}

abstract class HBinaryArithmetic extends HInvokeBinary {
  HBinaryArithmetic(left, right, selector, type)
      : super(left, right, selector, type);
  BinaryOperation operation(ConstantSystem constantSystem);
}

class HAdd extends HBinaryArithmetic {
  HAdd(left, right, selector, type) : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitAdd(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.add;
  int typeCode() => HInstruction.ADD_TYPECODE;
  bool typeEquals(other) => other is HAdd;
  bool dataEquals(HInstruction other) => true;
}

class HDivide extends HBinaryArithmetic {
  HDivide(left, right, selector, type) : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitDivide(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.divide;
  int typeCode() => HInstruction.DIVIDE_TYPECODE;
  bool typeEquals(other) => other is HDivide;
  bool dataEquals(HInstruction other) => true;
}

class HMultiply extends HBinaryArithmetic {
  HMultiply(left, right, selector, type) : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitMultiply(this);

  BinaryOperation operation(ConstantSystem operations)
      => operations.multiply;
  int typeCode() => HInstruction.MULTIPLY_TYPECODE;
  bool typeEquals(other) => other is HMultiply;
  bool dataEquals(HInstruction other) => true;
}

class HSubtract extends HBinaryArithmetic {
  HSubtract(left, right, selector, type) : super(left, right, selector, type);
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
  HBinaryBitOp(left, right, selector, type)
      : super(left, right, selector, type);
}

class HShiftLeft extends HBinaryBitOp {
  HShiftLeft(left, right, selector, type) : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitShiftLeft(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.shiftLeft;
  int typeCode() => HInstruction.SHIFT_LEFT_TYPECODE;
  bool typeEquals(other) => other is HShiftLeft;
  bool dataEquals(HInstruction other) => true;
}

class HBitOr extends HBinaryBitOp {
  HBitOr(left, right, selector, type) : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitBitOr(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.bitOr;
  int typeCode() => HInstruction.BIT_OR_TYPECODE;
  bool typeEquals(other) => other is HBitOr;
  bool dataEquals(HInstruction other) => true;
}

class HBitAnd extends HBinaryBitOp {
  HBitAnd(left, right, selector, type) : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitBitAnd(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.bitAnd;
  int typeCode() => HInstruction.BIT_AND_TYPECODE;
  bool typeEquals(other) => other is HBitAnd;
  bool dataEquals(HInstruction other) => true;
}

class HBitXor extends HBinaryBitOp {
  HBitXor(left, right, selector, type) : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitBitXor(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.bitXor;
  int typeCode() => HInstruction.BIT_XOR_TYPECODE;
  bool typeEquals(other) => other is HBitXor;
  bool dataEquals(HInstruction other) => true;
}

abstract class HInvokeUnary extends HInstruction {
  final Selector selector;
  HInvokeUnary(HInstruction input, this.selector, type)
      : super(<HInstruction>[input], type) {
    sideEffects.clearAllSideEffects();
    setUseGvn();
  }

  HInstruction get operand => inputs[0];

  UnaryOperation operation(ConstantSystem constantSystem);
}

class HNegate extends HInvokeUnary {
  HNegate(input, selector, type) : super(input, selector, type);
  accept(HVisitor visitor) => visitor.visitNegate(this);

  UnaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.negate;
  int typeCode() => HInstruction.NEGATE_TYPECODE;
  bool typeEquals(other) => other is HNegate;
  bool dataEquals(HInstruction other) => true;
}

class HBitNot extends HInvokeUnary {
  HBitNot(input, selector, type) : super(input, selector, type);
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
  /**
   * Signals that this is a special break instruction for the synthetic loop
   * generatedfor a switch statement with continue statements. See
   * [SsaBuilder.buildComplexSwitchStatement] for detail.
   */
  final bool breakSwitchContinueLoop;
  HBreak(TargetElement target, {bool this.breakSwitchContinueLoop: false})
      : super(target);
  HBreak.toLabel(LabelElement label)
      : breakSwitchContinueLoop = false, super.toLabel(label);
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
  HConstant.internal(this.constant, TypeMask constantType)
      : super(<HInstruction>[], constantType);

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
  HLocalValue(Element element, TypeMask type) : super(<HInstruction>[], type) {
    sourceElement = element;
  }

  toString() => 'local ${sourceElement.name}';
  accept(HVisitor visitor) => visitor.visitLocalValue(this);
}

class HParameterValue extends HLocalValue {
  HParameterValue(Element element, type) : super(element, type);

  toString() => 'parameter ${sourceElement.name}';
  accept(HVisitor visitor) => visitor.visitParameterValue(this);
}

class HThis extends HParameterValue {
  HThis(Element element, TypeMask type) : super(element, type);
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
  HPhi(Element element, List<HInstruction> inputs, TypeMask type)
      : super(inputs, type) {
    sourceElement = element;
  }
  HPhi.noInputs(Element element, TypeMask type)
      : this(element, <HInstruction>[], type);
  HPhi.singleInput(Element element, HInstruction input, TypeMask type)
      : this(element, <HInstruction>[input], type);
  HPhi.manyInputs(Element element, List<HInstruction> inputs, TypeMask type)
      : this(element, inputs, type);

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
  HRelational(left, right, selector, type) : super(left, right, selector, type);
}

class HIdentity extends HRelational {
  HIdentity(left, right, selector, type) : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitIdentity(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.identity;
  int typeCode() => HInstruction.IDENTITY_TYPECODE;
  bool typeEquals(other) => other is HIdentity;
  bool dataEquals(HInstruction other) => true;
}

class HGreater extends HRelational {
  HGreater(left, right, selector, type) : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitGreater(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.greater;
  int typeCode() => HInstruction.GREATER_TYPECODE;
  bool typeEquals(other) => other is HGreater;
  bool dataEquals(HInstruction other) => true;
}

class HGreaterEqual extends HRelational {
  HGreaterEqual(left, right, selector, type)
      : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitGreaterEqual(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.greaterEqual;
  int typeCode() => HInstruction.GREATER_EQUAL_TYPECODE;
  bool typeEquals(other) => other is HGreaterEqual;
  bool dataEquals(HInstruction other) => true;
}

class HLess extends HRelational {
  HLess(left, right, selector, type) : super(left, right, selector, type);
  accept(HVisitor visitor) => visitor.visitLess(this);

  BinaryOperation operation(ConstantSystem constantSystem)
      => constantSystem.less;
  int typeCode() => HInstruction.LESS_TYPECODE;
  bool typeEquals(other) => other is HLess;
  bool dataEquals(HInstruction other) => true;
}

class HLessEqual extends HRelational {
  HLessEqual(left, right, selector, type) : super(left, right, selector, type);
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
  HThrowExpression(value)
      : super(<HInstruction>[value], const TypeMask.nonNullEmpty());
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
  HStatic(this.element, type) : super(<HInstruction>[], type) {
    assert(element != null);
    assert(invariant(this, element.isDeclaration));
    sideEffects.clearAllSideEffects();
    if (element.isAssignable()) {
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
  bool isCodeMotionInvariant() => !element.isAssignable();
}

class HInterceptor extends HInstruction {
  // This field should originally be null to allow GVN'ing all
  // [HInterceptor] on the same input.
  Set<ClassElement> interceptedClasses;
  HInterceptor(HInstruction receiver, TypeMask type)
      : super(<HInstruction>[receiver], type) {
    sideEffects.clearAllSideEffects();
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
                      TypeMask type,
                      this.interceptedClasses)
      : super(selector, null, inputs, type, true) {
    assert(inputs[0] is HConstant);
    assert(inputs[0].isNull());
  }
  bool isCallOnInterceptor(Compiler compiler) => true;

  String toString() => 'one shot interceptor on $selector';
  accept(HVisitor visitor) => visitor.visitOneShotInterceptor(this);
}

/** An [HLazyStatic] is a static that is initialized lazily at first read. */
class HLazyStatic extends HInstruction {
  final Element element;
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
  Element element;
  HStaticStore(this.element, HInstruction value)
      : super(<HInstruction>[value], const TypeMask.nonNullEmpty()) {
    sideEffects.clearAllSideEffects();
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
}

/**
 * The primitive array indexing operation. Note that this instruction
 * does not throw because we generate the checks explicitly.
 */
class HIndex extends HInstruction {
  final Selector selector;
  HIndex(HInstruction receiver, HInstruction index, this.selector, type)
      : super(<HInstruction>[receiver, index], type) {
    sideEffects.clearAllSideEffects();
    sideEffects.setDependsOnIndexStore();
    setUseGvn();
  }

  String toString() => 'index operator';
  accept(HVisitor visitor) => visitor.visitIndex(this);

  HInstruction get receiver => inputs[0];
  HInstruction get index => inputs[1];

  HInstruction getDartReceiver(Compiler compiler) => receiver;
  bool onlyThrowsNSM() => true;

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
  HIndexAssign(HInstruction receiver,
               HInstruction index,
               HInstruction value,
               this.selector)
      : super(<HInstruction>[receiver, index, value],
              const TypeMask.nonNullEmpty()) {
    sideEffects.clearAllSideEffects();
    sideEffects.setChangesIndex();
  }
  String toString() => 'index assign operator';
  accept(HVisitor visitor) => visitor.visitIndexAssign(this);

  HInstruction get receiver => inputs[0];
  HInstruction get index => inputs[1];
  HInstruction get value => inputs[2];

  HInstruction getDartReceiver(Compiler compiler) => receiver;
  bool onlyThrowsNSM() => true;
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

  HIs.direct(DartType typeExpression,
             HInstruction expression,
             TypeMask type)
      : this.internal(typeExpression, [expression], RAW_CHECK, type);

  HIs.raw(DartType typeExpression,
          HInstruction expression,
          HInterceptor interceptor,
          TypeMask type)
      : this.internal(
            typeExpression, [expression, interceptor], RAW_CHECK, type);

  HIs.compound(DartType typeExpression,
               HInstruction expression,
               HInstruction call,
               TypeMask type)
      : this.internal(typeExpression, [expression, call], COMPOUND_CHECK, type);

  HIs.variable(DartType typeExpression,
               HInstruction expression,
               HInstruction call,
               TypeMask type)
      : this.internal(typeExpression, [expression, call], VARIABLE_CHECK, type);

  HIs.internal(this.typeExpression, List<HInstruction> inputs, this.kind, type)
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
    return typeExpression == other.typeExpression
        && kind == other.kind;
  }
}

class HTypeConversion extends HCheck {
  final DartType typeExpression;
  final int kind;
  final Selector receiverTypeCheckSelector;
  final bool contextIsTypeArguments;
  TypeMask checkedType;  // Not final because we refine it.

  static const int CHECKED_MODE_CHECK = 0;
  static const int ARGUMENT_TYPE_CHECK = 1;
  static const int CAST_TYPE_CHECK = 2;
  static const int BOOLEAN_CONVERSION_CHECK = 3;
  static const int RECEIVER_TYPE_CHECK = 4;

  HTypeConversion(this.typeExpression, this.kind,
                  TypeMask type, HInstruction input,
                  [this.receiverTypeCheckSelector])
      : contextIsTypeArguments = false,
        checkedType = type,
        super(<HInstruction>[input], type) {
    assert(!isReceiverTypeCheck || receiverTypeCheckSelector != null);
    assert(typeExpression == null ||
           typeExpression.kind != TypeKind.TYPEDEF);
    sourceElement = input.sourceElement;
  }

  HTypeConversion.withTypeRepresentation(this.typeExpression, this.kind,
                                         TypeMask type, HInstruction input,
                                         HInstruction typeRepresentation)
      : contextIsTypeArguments = false,
        checkedType = type,
        super(<HInstruction>[input, typeRepresentation],type),
        receiverTypeCheckSelector = null {
    assert(typeExpression.kind != TypeKind.TYPEDEF);
    sourceElement = input.sourceElement;
  }

  HTypeConversion.withContext(this.typeExpression, this.kind,
                              TypeMask type, HInstruction input,
                              HInstruction context,
                              {bool this.contextIsTypeArguments})
      : super(<HInstruction>[input, context], type),
        checkedType = type,
        receiverTypeCheckSelector = null {
    assert(typeExpression.kind != TypeKind.TYPEDEF);
    sourceElement = input.sourceElement;
  }

  bool get hasTypeRepresentation {
    return typeExpression.kind == TypeKind.INTERFACE && inputs.length > 1;
  }
  HInstruction get typeRepresentation => inputs[1];

  bool get hasContext {
    return typeExpression.kind == TypeKind.FUNCTION && inputs.length > 1;
  }
  HInstruction get context => inputs[1];

  HInstruction convertType(Compiler compiler, DartType type, int kind) {
    if (typeExpression == type) return this;
    return super.convertType(compiler, type, kind);
  }

  bool get isCheckedModeCheck {
    return kind == CHECKED_MODE_CHECK
        || kind == BOOLEAN_CONVERSION_CHECK;
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
    return kind == other.kind
        && typeExpression == other.typeExpression
        && checkedType == other.checkedType;
  }
}

/// The [HTypeKnown] instruction marks a value with a refined type.
class HTypeKnown extends HCheck {
  TypeMask knownType;
  HTypeKnown(TypeMask knownType, HInstruction input)
      : this.knownType = knownType,
        super(<HInstruction>[input], knownType);
  toString() => 'TypeKnown $knownType';
  accept(HVisitor visitor) => visitor.visitTypeKnown(this);

  bool isJsStatement() => false;
  bool isControlFlow() => false;
  bool canThrow() => false;

  int typeCode() => HInstruction.TYPE_KNOWN_TYPECODE;
  bool typeEquals(HInstruction other) => other is HTypeKnown;
  bool isCodeMotionInvariant() => true;

  bool dataEquals(HTypeKnown other) {
    return knownType == other.knownType
        && instructionType == other.instructionType;
  }
}

class HRangeConversion extends HCheck {
  HRangeConversion(HInstruction input, type)
      : super(<HInstruction>[input], type) {
    sourceElement = input.sourceElement;
  }
  accept(HVisitor visitor) => visitor.visitRangeConversion(this);
}

class HStringConcat extends HInstruction {
  final Node node;
  HStringConcat(HInstruction left, HInstruction right, this.node, TypeMask type)
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
  final Node node;
  HStringify(HInstruction input, this.node, TypeMask type)
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
  final List<LabelElement> labels;
  final TargetElement target;

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
  int visitSwitchStatement(SwitchStatement node) =>
      HLoopBlockInformation.SWITCH_CONTINUE_LOOP;
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
  final TargetElement target;
  final List<LabelElement> labels;

  HSwitchBlockInformation(this.expression,
                          this.matchExpressions,
                          this.statements,
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
