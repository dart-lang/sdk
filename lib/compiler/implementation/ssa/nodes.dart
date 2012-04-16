// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface HVisitor<R> {
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
  R visitSubtract(HSubtract node);
  R visitThis(HThis node);
  R visitThrow(HThrow node);
  R visitTruncatingDivide(HTruncatingDivide node);
  R visitTry(HTry node);
  R visitTypeGuard(HTypeGuard node);
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

  HBasicBlock addNewLoopHeaderBlock(int type,
                                    TargetElement target,
                                    List<LabelElement> labels) {
    HBasicBlock result = addNewBlock();
    result.loopInformation = new HLoopInformation(type, result, target, labels);
    return result;
  }

  static HType mapConstantTypeToSsaType(Constant constant) {
    if (constant.isNull()) return HType.UNKNOWN;
    if (constant.isBool()) return HType.BOOLEAN;
    if (constant.isInt()) return HType.INTEGER;
    if (constant.isDouble()) return HType.DOUBLE;
    if (constant.isString()) return HType.STRING;
    if (constant.isList()) return HType.READABLE_ARRAY;
    return HType.UNKNOWN;
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

  HConstant addConstantString(DartString str) {
    return addConstant(new StringConstant(str));
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
  visitRelational(HRelational node) => visitInvokeBinary(node);

  visitAdd(HAdd node) => visitBinaryArithmetic(node);
  visitBitAnd(HBitAnd node) => visitBinaryBitOp(node);
  visitBitNot(HBitNot node) => visitInvokeUnary(node);
  visitBitOr(HBitOr node) => visitBinaryBitOp(node);
  visitBitXor(HBitXor node) => visitBinaryBitOp(node);
  visitBoolify(HBoolify node) => visitInstruction(node);
  visitBoundsCheck(HBoundsCheck node) => visitCheck(node);
  visitBreak(HBreak node) => visitGoto(node);
  visitContinue(HContinue node) => visitGoto(node);
  visitCheck(HCheck node) => visitInstruction(node);
  visitConstant(HConstant node) => visitInstruction(node);
  visitDivide(HDivide node) => visitBinaryArithmetic(node);
  visitEquals(HEquals node) => visitRelational(node);
  visitExit(HExit node) => visitControlFlow(node);
  visitFieldGet(HFieldGet node) => visitInstruction(node);
  visitFieldSet(HFieldSet node) => visitInstruction(node);
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
  visitLess(HLess node) => visitRelational(node);
  visitLessEqual(HLessEqual node) => visitRelational(node);
  visitLiteralList(HLiteralList node) => visitInstruction(node);
  visitLoopBranch(HLoopBranch node) => visitConditionalBranch(node);
  visitModulo(HModulo node) => visitBinaryArithmetic(node);
  visitNegate(HNegate node) => visitInvokeUnary(node);
  visitNot(HNot node) => visitInstruction(node);
  visitPhi(HPhi node) => visitInstruction(node);
  visitMultiply(HMultiply node) => visitBinaryArithmetic(node);
  visitParameterValue(HParameterValue node) => visitInstruction(node);
  visitReturn(HReturn node) => visitControlFlow(node);
  visitShiftRight(HShiftRight node) => visitBinaryBitOp(node);
  visitShiftLeft(HShiftLeft node) => visitBinaryBitOp(node);
  visitSubtract(HSubtract node) => visitBinaryArithmetic(node);
  visitStatic(HStatic node) => visitInstruction(node);
  visitStaticStore(HStaticStore node) => visitInstruction(node);
  visitThis(HThis node) => visitParameterValue(node);
  visitThrow(HThrow node) => visitControlFlow(node);
  visitTry(HTry node) => visitControlFlow(node);
  visitTruncatingDivide(HTruncatingDivide node) => visitBinaryArithmetic(node);
  visitTypeGuard(HTypeGuard node) => visitInstruction(node);
  visitIs(HIs node) => visitInstruction(node);
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
  final HInstruction expression;
  const SubExpression(HBasicBlock start, HBasicBlock end, this.expression)
      : super(start, end);
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
  HLabeledBlockInformation labeledBlockInformation = null;
  HBasicBlock parentLoopHeader = null;
  List<HTypeGuard> guards;

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
        guards = <HTypeGuard>[];

  int hashCode() => id;

  bool isNew() => status == STATUS_NEW;
  bool isOpen() => status == STATUS_OPEN;
  bool isClosed() => status == STATUS_CLOSED;

  bool isLoopHeader() => loopInformation !== null;
  bool hasLabeledBlockInformation() => labeledBlockInformation !== null;

  bool hasGuards() => !guards.isEmpty();

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
      rewriteInput(use, from, to);
    }
    to.usedBy.addAll(from.usedBy);
    from.usedBy.clear();
  }

  static void rewriteInput(HInstruction instruction,
                           HInstruction from,
                           HInstruction to) {
    List inputs = instruction.inputs;
    for (int i = 0; i < inputs.length; i++) {
      if (inputs[i] === from) inputs[i] = to;
    }
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
      HBasicBlock first = dominator;
      HBasicBlock second = predecessor;
      while (first !== second) {
        if (first.id > second.id) {
          first = first.dominator;
        } else {
          second = second.dominator;
        }
        assert(first !== null && second !== null);
      }
      if (dominator !== first) {
        dominator.removeDominatedBlock(this);
        first.addDominatedBlock(this);
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

  bool isValid() {
    assert(isClosed());
    HValidator validator = new HValidator();
    validator.visitBasicBlock(this);
    return validator.isValid;
  }
}

interface HBlockInformation {}

class HLabeledBlockInformation implements HBlockInformation {
  final SubGraph body;
  final HBasicBlock joinBlock;
  final List<LabelElement> labels;
  final TargetElement target;
  final bool isContinue;

  HLabeledBlockInformation(this.body, this.joinBlock,
                           List<LabelElement> labels,
                           [this.isContinue = false]) :
      this.labels = labels, this.target = labels[0].target;

  HLabeledBlockInformation.implicit(this.body,
                                    this.joinBlock,
                                    this.target,
                                    [this.isContinue = false])
      : this.labels = const<LabelElement>[];
}

class LoopTypeVisitor extends AbstractVisitor {
  const LoopTypeVisitor();
  int visitNode(Node node) {
    unreachable();
  }
  int visitWhile(While node) => HLoopInformation.WHILE_LOOP;
  int visitFor(For node) => HLoopInformation.FOR_LOOP;
  int visitDoWhile(DoWhile node) => HLoopInformation.DO_WHILE_LOOP;
  int visitForIn(ForIn node) => HLoopInformation.FOR_IN_LOOP;
}

class HLoopInformation implements HBlockInformation {
  static final int WHILE_LOOP = 0;
  static final int FOR_LOOP = 1;
  static final int DO_WHILE_LOOP = 2;
  static final int FOR_IN_LOOP = 3;

  final int type;
  final HBasicBlock header;
  final List<HBasicBlock> blocks;
  final List<HBasicBlock> backEdges;
  final List<LabelElement> labels;
  final TargetElement target;
  SubGraph initializer = null;
  SubExpression condition = null;
  SubGraph body = null;
  SubGraph updates = null;
  HBasicBlock joinBlock;

  HLoopInformation(this.type, this.header, this.target, this.labels)
      : blocks = new List<HBasicBlock>(),
        backEdges = new List<HBasicBlock>();

  static int loopType(Node node) {
    return node.accept(const LoopTypeVisitor());
  }

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

class HType {
  final int flag;
  const HType(int this.flag);

  static final int FLAG_CONFLICTING = 0;
  static final int FLAG_UNKNOWN = 1;
  static final int FLAG_BOOLEAN = FLAG_UNKNOWN << 1;
  static final int FLAG_INTEGER = FLAG_BOOLEAN << 1;
  static final int FLAG_STRING = FLAG_INTEGER << 1;
  static final int FLAG_READABLE_ARRAY = FLAG_STRING << 1;
  // FLAG_WRITABLE_ARRAY implies FLAG_READABLE_ARRAY.
  static final int FLAG_WRITEABLE_ARRAY = FLAG_READABLE_ARRAY << 1;
  static final int FLAG_DOUBLE = FLAG_WRITEABLE_ARRAY << 1;

  static final HType CONFLICTING = const HType(FLAG_CONFLICTING);
  static final HType UNKNOWN = const HType(FLAG_UNKNOWN);
  static final HType BOOLEAN = const HType(FLAG_BOOLEAN);
  static final HType STRING = const HType(FLAG_STRING);
  static final HType READABLE_ARRAY = const HType(FLAG_READABLE_ARRAY);
  static final HType MUTABLE_ARRAY =
      const HType(FLAG_READABLE_ARRAY | FLAG_WRITEABLE_ARRAY);
  static final HType INTEGER = const HType(FLAG_INTEGER);
  static final HType DOUBLE = const HType(FLAG_DOUBLE);
  static final HType STRING_OR_ARRAY =
      const HType(FLAG_STRING | FLAG_READABLE_ARRAY | FLAG_WRITEABLE_ARRAY);
  static final HType NUMBER = const HType(FLAG_DOUBLE | FLAG_INTEGER);

  bool isConflicting() => this === CONFLICTING;
  bool isUnknown() => this === UNKNOWN;
  bool isBoolean() => this === BOOLEAN;
  bool isInteger() => this === INTEGER;
  bool isDouble() => this === DOUBLE;
  bool isString() => this === STRING;
  bool isArray() => (this.flag & FLAG_READABLE_ARRAY) != 0;
  bool isMutableArray() => this === MUTABLE_ARRAY;
  bool isNumber() => (this.flag & (FLAG_INTEGER | FLAG_DOUBLE)) != 0;
  bool isStringOrArray() =>
      (this.flag & (FLAG_STRING | FLAG_READABLE_ARRAY)) != 0;
  bool isKnown() => this !== UNKNOWN && this !== CONFLICTING;

  static HType getTypeFromFlag(int flag) {
    if (flag === CONFLICTING.flag) return CONFLICTING;
    if (flag === UNKNOWN.flag) return UNKNOWN;
    if (flag === BOOLEAN.flag) return BOOLEAN;
    if (flag === INTEGER.flag) return INTEGER;
    if (flag === DOUBLE.flag) return DOUBLE;
    if (flag === STRING.flag) return STRING;
    if (flag === READABLE_ARRAY.flag) return READABLE_ARRAY;
    if (flag === MUTABLE_ARRAY.flag) return MUTABLE_ARRAY;
    if (flag === NUMBER.flag) return NUMBER;
    if (flag === STRING_OR_ARRAY.flag) return STRING_OR_ARRAY;
    assert(false);
  }

  String toString() {
    if (isConflicting()) return 'conflicting';
    if (isUnknown()) return 'unknown';
    if (isBoolean()) return 'boolean';
    if (isInteger()) return 'integer';
    if (isDouble()) return 'double';
    if (isString()) return 'string';
    if (isMutableArray()) return 'mutable array';
    if (isArray()) return 'array';
    if (isNumber()) return 'number';
    if (isStringOrArray()) return 'string or array';
    unreachable();
  }

  HType combine(HType other) {
    if (isUnknown()) return other;
    if (other.isUnknown()) return this;
    return getTypeFromFlag(this.flag & other.flag);
  }
}

class HInstruction implements Hashable {
  final int id;
  static int idCounter;

  final List<HInstruction> inputs;
  final List<HInstruction> usedBy;

  HBasicBlock block;
  HInstruction previous = null;
  HInstruction next = null;
  int flags = 0;
  HType type = HType.UNKNOWN;

  // Changes flags.
  static final int FLAG_CHANGES_SOMETHING    = 0;
  static final int FLAG_CHANGES_COUNT        = FLAG_CHANGES_SOMETHING + 1;

  // Depends flags (one for each changes flag).
  static final int FLAG_DEPENDS_ON_SOMETHING = FLAG_CHANGES_COUNT;

  // Other flags.
  static final int FLAG_USE_GVN              = FLAG_DEPENDS_ON_SOMETHING + 1;

  HInstruction(this.inputs) : id = idCounter++, usedBy = <HInstruction>[];

  int hashCode() => id;

  bool getFlag(int position) => (flags & (1 << position)) != 0;
  void setFlag(int position) { flags |= (1 << position); }
  void clearFlag(int position) { flags &= ~(1 << position); }

  static int computeDependsOnFlags(int flags) => flags << FLAG_CHANGES_COUNT;

  int getChangesFlags() => flags & ((1 << FLAG_CHANGES_COUNT) - 1);
  bool hasSideEffects() => getChangesFlags() != 0;
  void prepareGvn() { setAllSideEffects(); }

  void setAllSideEffects() { flags |= ((1 << FLAG_CHANGES_COUNT) - 1); }
  void clearAllSideEffects() { flags &= ~((1 << FLAG_CHANGES_COUNT) - 1); }

  bool useGvn() => getFlag(FLAG_USE_GVN);
  void setUseGvn() { setFlag(FLAG_USE_GVN); }
  // Does this node potentially affect control flow.
  bool isControlFlow() => false;

  bool isArray() => type.isArray();
  bool isMutableArray() => type.isMutableArray();
  bool isBoolean() => type.isBoolean();
  bool isInteger() => type.isInteger();
  bool isNumber() => type.isNumber();
  bool isString() => type.isString();
  bool isTypeUnknown() => type.isUnknown();
  bool isStringOrArray() => type.isStringOrArray();

  // Compute the type of the instruction.
  HType computeType() => HType.UNKNOWN;

  HType computeDesiredInputType(HInstruction input) => HType.UNKNOWN;

  // Returns whether the instruction does produce the type it claims.
  // For most instructions, this returns false. A type guard will be
  // inserted to make sure the users get the right type in.
  bool hasExpectedType() => false;

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
      List inputUsedBy = inputs[i].usedBy;
      for (int j = 0; j < inputUsedBy.length; j++) {
        if (inputUsedBy[j] === this) {
          inputUsedBy[j] = inputUsedBy[inputUsedBy.length - 1];
          inputUsedBy.removeLast();
          break;
        }
      }
    }
    this.block = null;
    assert(isValid());
  }

  bool isConstant() => false;
  bool isConstantNull() => false;
  bool isConstantNumber() => false;
  bool isConstantString() => false;

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
}

class HBoolify extends HInstruction {
  HBoolify(HInstruction value) : super(<HInstruction>[value]);
  void prepareGvn() {
    assert(!hasSideEffects());
    setUseGvn();
  }

  HType computeType() => HType.BOOLEAN;
  bool hasExpectedType() => true;

  accept(HVisitor visitor) => visitor.visitBoolify(this);
  int typeCode() => 0;
  bool typeEquals(other) => other is HBoolify;
  bool dataEquals(HInstruction other) => true;
}

class HCheck extends HInstruction {
  HCheck(inputs) : super(inputs);

  // TODO(floitsch): make class abstract instead of adding an abstract method.
  abstract accept(HVisitor visitor);

  bool isControlFlow() => true;
}

class HTypeGuard extends HInstruction {
  int state;
  HTypeGuard(int this.state, List<HInstruction> env) : super(env);

  void prepareGvn() {
    assert(!hasSideEffects());
    setUseGvn();
  }

  HInstruction get guarded() => inputs.last();

  HType computeType() => type;
  bool hasExpectedType() => true;

  bool isControlFlow() => true;

  accept(HVisitor visitor) => visitor.visitTypeGuard(this);
  int typeCode() => 1;
  bool typeEquals(other) => other is HTypeGuard;
  bool dataEquals(HTypeGuard other) => type == other.type;
}

class HBoundsCheck extends HCheck {
  HBoundsCheck(length, index) : super(<HInstruction>[length, index]) {
    type = HType.INTEGER;
  }

  HInstruction get length() => inputs[0];
  HInstruction get index() => inputs[1];

  void prepareGvn() {
    assert(!hasSideEffects());
    setUseGvn();
  }

  HType computeType() => HType.INTEGER;
  bool hasExpectedType() => true;

  accept(HVisitor visitor) => visitor.visitBoundsCheck(this);
  int typeCode() => 2;
  bool typeEquals(other) => other is HBoundsCheck;
  bool dataEquals(HInstruction other) => true;
}

class HIntegerCheck extends HCheck {
  HIntegerCheck(value) : super(<HInstruction>[value]);

  HInstruction get value() => inputs[0];

  void prepareGvn() {
    assert(!hasSideEffects());
    setUseGvn();
  }

  HType computeType() => HType.INTEGER;
  bool hasExpectedType() => true;

  accept(HVisitor visitor) => visitor.visitIntegerCheck(this);
  int typeCode() => 3;
  bool typeEquals(other) => other is HIntegerCheck;
  bool dataEquals(HInstruction other) => true;
}

class HConditionalBranch extends HControlFlow {
  HConditionalBranch(inputs) : super(inputs);
  HInstruction get condition() => inputs[0];
  HBasicBlock get trueBranch() => block.successors[0];
  HBasicBlock get falseBranch() => block.successors[1];
  abstract toString();
}

class HControlFlow extends HInstruction {
  HControlFlow(inputs) : super(inputs);
  abstract toString();
  bool isControlFlow() => true;
}

class HInvoke extends HInstruction {
  /**
    * The first argument must be the target: either an [HStatic] node, or
    * the receiver of a method-call. The remaining inputs are the arguments
    * to the invocation.
    */
  final Selector selector;
  HInvoke(Selector this.selector, List<HInstruction> inputs) : super(inputs);
  static final int ARGUMENTS_OFFSET = 1;

  // TODO(floitsch): make class abstract instead of adding an abstract method.
  abstract accept(HVisitor visitor);
}

class HInvokeDynamic extends HInvoke {
  SourceString name;
  HInvokeDynamic(Selector selector, this.name, List<HInstruction> inputs)
      : super(selector, inputs);
  toString() => 'invoke dynamic: $name';
  HInstruction get receiver() => inputs[0];

  // TODO(floitsch): make class abstract instead of adding an abstract method.
  abstract accept(HVisitor visitor);
}

class HInvokeClosure extends HInvokeDynamic {
  Element element;
  HInvokeClosure(Selector selector, List<HInstruction> inputs)
    : super(selector, const SourceString('call'), inputs);
  accept(HVisitor visitor) => visitor.visitInvokeClosure(this);
}

class HInvokeDynamicMethod extends HInvokeDynamic {
  HInvokeDynamicMethod(Selector selector,
                       SourceString methodName,
                       List<HInstruction> inputs)
    : super(selector, methodName, inputs);
  toString() => 'invoke dynamic method: $name';
  accept(HVisitor visitor) => visitor.visitInvokeDynamicMethod(this);
}

class HInvokeDynamicField extends HInvokeDynamic {
  Element element;
  HInvokeDynamicField(Selector selector,
                      Element this.element,
                      SourceString name,
                      List<HInstruction>inputs)
      : super(selector, name, inputs);
  toString() => 'invoke dynamic field: $name';

  // TODO(floitsch): make class abstract instead of adding an abstract method.
  abstract accept(HVisitor visitor);
}

class HInvokeDynamicGetter extends HInvokeDynamicField {
  HInvokeDynamicGetter(selector, element, name, receiver)
    : super(selector, element, name, [receiver]);
  toString() => 'invoke dynamic getter: $name';
  accept(HVisitor visitor) => visitor.visitInvokeDynamicGetter(this);
}

class HInvokeDynamicSetter extends HInvokeDynamicField {
  HInvokeDynamicSetter(selector, element, name, receiver, value)
    : super(selector, element, name, [receiver, value]);
  toString() => 'invoke dynamic setter: $name';
  accept(HVisitor visitor) => visitor.visitInvokeDynamicSetter(this);
}

class HInvokeStatic extends HInvoke {
  /** The first input must be the target. */
  HInvokeStatic(selector, inputs) : super(selector, inputs);
  toString() => 'invoke static: ${element.name}';
  accept(HVisitor visitor) => visitor.visitInvokeStatic(this);
  Element get element() => target.element;
  HStatic get target() => inputs[0];

  bool isArrayConstructor() {
    // TODO(ngeoffray): This is not the right way to do the check,
    // nor the right place. We need to move it to a phase.
    return (element.isFactoryConstructor()
        && element.enclosingElement.name.slowToString() == 'List');
  }

  HType computeType() {
    if (isArrayConstructor()) {
      return HType.MUTABLE_ARRAY;
    }
    return HType.UNKNOWN;
  }

  bool get builtin() => isArrayConstructor();
  bool hasExpectedType() => isArrayConstructor();
}

class HInvokeSuper extends HInvokeStatic {
  HInvokeSuper(selector, inputs) : super(selector, inputs);
  toString() => 'invoke super: ${element.name}';
  accept(HVisitor visitor) => visitor.visitInvokeSuper(this);
}

class HInvokeInterceptor extends HInvokeStatic {
  final SourceString name;
  final bool getter;

  HInvokeInterceptor(Selector selector,
                     SourceString this.name,
                     bool this.getter,
                     List<HInstruction> inputs)
      : super(selector, inputs);
  toString() => 'invoke interceptor: ${element.name}';
  accept(HVisitor visitor) => visitor.visitInvokeInterceptor(this);

  String get builtinJsName() {
    if (getter
        && name == const SourceString('length')
        && inputs[1].isStringOrArray()) {
      return 'length';
    } else if (name == const SourceString('add')
               && inputs[1].isMutableArray()) {
      return 'push';
    } else if (name == const SourceString('removeLast')
               && inputs[1].isMutableArray()) {
      return 'pop';
    }
    return null;
  }

  HType computeType() {
    if (getter
        && name == const SourceString('length')
        && inputs[1].isStringOrArray()) {
      return HType.INTEGER;
    }
    return HType.UNKNOWN;
  }

  HType computeDesiredInputType(HInstruction input) {
    if (input == inputs[0]) return HType.UNKNOWN;
    if (input == inputs[1] && input.isStringOrArray()) {
      if (name == const SourceString('add')
          || name == const SourceString('removeLast')) {
        return HType.MUTABLE_ARRAY;
      }
    }
    return HType.UNKNOWN;
  }

  bool hasExpectedType() => builtinJsName != null;

  void prepareGvn() {
    if (builtinJsName == 'length') {
      clearAllSideEffects();
    } else {
      setAllSideEffects();
    }
  }

  int typeCode() => 4;
  bool typeEquals(other) => other is HInvokeInterceptor;
  bool dataEquals(HInvokeInterceptor other) {
    return builtinJsName == other.builtinJsName && name == other.name;
  }
}

class HFieldGet extends HInstruction {
  final Element element;
  HFieldGet(Element this.element, HInstruction receiver)
      : super(<HInstruction>[receiver]);
  HFieldGet.fromActivation(Element this.element) : super(<HInstruction>[]);

  HInstruction get receiver() => inputs.length == 1 ? inputs[0] : null;
  accept(HVisitor visitor) => visitor.visitFieldGet(this);
}

class HFieldSet extends HInstruction {
  final Element element;
  HFieldSet(Element this.element, HInstruction receiver, HInstruction value)
      : super(<HInstruction>[receiver, value]);
  HFieldSet.fromActivation(Element this.element, HInstruction value)
      : super(<HInstruction>[value]);

  HInstruction get receiver() => inputs.length == 2 ? inputs[0] : null;
  HInstruction get value() => inputs.length == 2 ? inputs[1] : inputs[0];
  accept(HVisitor visitor) => visitor.visitFieldSet(this);

  void prepareGvn() {
    // TODO(ngeoffray): implement more fine grain side effects.
    setAllSideEffects();
  }
}

class HForeign extends HInstruction {
  final DartString code;
  final DartString declaredType;
  HForeign(this.code, this.declaredType, List<HInstruction> inputs)
      : super(inputs);
  accept(HVisitor visitor) => visitor.visitForeign(this);

  HType computeType() {
    if (declaredType.slowToString() == 'bool') return HType.BOOLEAN;
    if (declaredType.slowToString() == 'int') return HType.INTEGER;
    if (declaredType.slowToString() == 'num') return HType.NUMBER;
    if (declaredType.slowToString() == 'String') return HType.STRING;
    return HType.UNKNOWN;
  }

  bool hasExpectedType() => true;
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
      : super(Selector.BINARY_OPERATOR, <HInstruction>[target, left, right]);

  HInstruction get left() => inputs[1];
  HInstruction get right() => inputs[2];

  HType computeInputsType() {
    HType leftType = left.type;
    HType rightType = right.type;
    if (leftType.isUnknown() || rightType.isUnknown()) {
      return HType.UNKNOWN;
    }
    return leftType.combine(rightType);
  }

  abstract BinaryOperation get operation();
}

class HBinaryArithmetic extends HInvokeBinary {
  HBinaryArithmetic(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);

  void prepareGvn() {
    // An arithmetic expression can take part in global value
    // numbering and do not have any side-effects if we know that all
    // inputs are numbers.
    if (builtin) {
      clearAllSideEffects();
      setUseGvn();
    } else {
      setAllSideEffects();
    }
  }

  bool get builtin() => left.isNumber() && right.isNumber();

  HType computeType() {
    HType inputsType = computeInputsType();
    if (inputsType.isKnown()) return inputsType;
    if (left.isNumber()) return HType.NUMBER;
    return HType.UNKNOWN;
  }

  HType computeDesiredInputType(HInstruction input) {
    // TODO(floitsch): we want the target to be a function.
    if (input == target) return HType.UNKNOWN;
    if (isNumber() || left.isNumber() || right.isNumber()) return HType.NUMBER;
    if (type.isUnknown()) return HType.NUMBER;
    return HType.UNKNOWN;
  }

  bool hasExpectedType() => left.isNumber() && right.isNumber();
  // TODO(1603): The class should be marked as abstract.
  abstract BinaryOperation get operation();
}

class HAdd extends HBinaryArithmetic {
  HAdd(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitAdd(this);

  bool get builtin() {
    return (left.isNumber() && right.isNumber())
            || (left.isString() && right.isString())
            || (left.isString() && right is HConstant);
  }

  HType computeType() {
    HType computedType = computeInputsType();
    if (computedType.isConflicting() && left.isString()) return HType.STRING;
    if (computedType.isKnown()) return computedType;
    if (left.isNumber()) return HType.NUMBER;
    return HType.UNKNOWN;
  }

  bool hasExpectedType() => builtin || type.isUnknown() || left.isString();

  HType computeDesiredInputType(HInstruction input) {
    // TODO(floitsch): we want the target to be a function.
    if (input == target) return HType.UNKNOWN;
    if (isString() || left.isString()) {
      return (input == left) ? HType.STRING : HType.UNKNOWN;
    }
    if (right.isString()) return HType.STRING;
    if (isNumber() || left.isNumber() || right.isNumber()) return HType.NUMBER;
    return HType.UNKNOWN;
  }

  AddOperation get operation() => const AddOperation();

  int typeCode() => 5;
  bool typeEquals(other) => other is HAdd;
  bool dataEquals(HInstruction other) => true;
}

class HDivide extends HBinaryArithmetic {
  HDivide(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitDivide(this);

  bool get builtin() => left.isNumber() && right.isNumber();

  HType computeType() {
    HType inputsType = computeInputsType();
    if (left.isNumber()) return HType.DOUBLE;
    return HType.UNKNOWN;
  }

  DivideOperation get operation() => const DivideOperation();
  int typeCode() => 6;
  bool typeEquals(other) => other is HDivide;
  bool dataEquals(HInstruction other) => true;
}

class HModulo extends HBinaryArithmetic {
  HModulo(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitModulo(this);

  ModuloOperation get operation() => const ModuloOperation();
  int typeCode() => 7;
  bool typeEquals(other) => other is HModulo;
  bool dataEquals(HInstruction other) => true;
}

class HMultiply extends HBinaryArithmetic {
  HMultiply(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitMultiply(this);

  MultiplyOperation get operation() => const MultiplyOperation();
  int typeCode() => 8;
  bool typeEquals(other) => other is HMultiply;
  bool dataEquals(HInstruction other) => true;
}

class HSubtract extends HBinaryArithmetic {
  HSubtract(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitSubtract(this);

  SubtractOperation get operation() => const SubtractOperation();
  int typeCode() => 9;
  bool typeEquals(other) => other is HSubtract;
  bool dataEquals(HInstruction other) => true;
}

class HTruncatingDivide extends HBinaryArithmetic {
  HTruncatingDivide(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitTruncatingDivide(this);

  TruncatingDivideOperation get operation()
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

  bool get builtin() => left.isInteger() && right.isInteger();

  HType computeType() {
    HType inputsType = computeInputsType();
    if (inputsType.isKnown()) return inputsType;
    if (left.isInteger()) return HType.INTEGER;
    return HType.UNKNOWN;
  }

  HType computeDesiredInputType(HInstruction input) {
    // TODO(floitsch): we want the target to be a function.
    if (input == target) return HType.UNKNOWN;
    return HType.INTEGER;
  }

  // TODO(floitsch): make class abstract instead of adding an abstract method.
  abstract accept(HVisitor visitor);
}

class HShiftLeft extends HBinaryBitOp {
  HShiftLeft(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitShiftLeft(this);

  ShiftLeftOperation get operation() => const ShiftLeftOperation();
  int typeCode() => 11;
  bool typeEquals(other) => other is HShiftLeft;
  bool dataEquals(HInstruction other) => true;
}

class HShiftRight extends HBinaryBitOp {
  HShiftRight(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitShiftRight(this);

  ShiftRightOperation get operation() => const ShiftRightOperation();
  int typeCode() => 12;
  bool typeEquals(other) => other is HShiftRight;
  bool dataEquals(HInstruction other) => true;
}

class HBitOr extends HBinaryBitOp {
  HBitOr(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitBitOr(this);

  BitOrOperation get operation() => const BitOrOperation();
  int typeCode() => 13;
  bool typeEquals(other) => other is HBitOr;
  bool dataEquals(HInstruction other) => true;
}

class HBitAnd extends HBinaryBitOp {
  HBitAnd(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitBitAnd(this);

  BitAndOperation get operation() => const BitAndOperation();
  int typeCode() => 14;
  bool typeEquals(other) => other is HBitAnd;
  bool dataEquals(HInstruction other) => true;
}

class HBitXor extends HBinaryBitOp {
  HBitXor(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitBitXor(this);

  BitXorOperation get operation() => const BitXorOperation();
  int typeCode() => 15;
  bool typeEquals(other) => other is HBitXor;
  bool dataEquals(HInstruction other) => true;
}

class HInvokeUnary extends HInvokeStatic {
  HInvokeUnary(HStatic target, HInstruction input)
      : super(Selector.UNARY_OPERATOR, <HInstruction>[target, input]);

  HInstruction get operand() => inputs[1];

  void prepareGvn() {
    // A unary arithmetic expression can take part in global value
    // numbering and does not have any side-effects if its input is a
    // number.
    if (builtin) {
      clearAllSideEffects();
      setUseGvn();
    } else {
      setAllSideEffects();
    }
  }

  bool get builtin() => operand.isNumber();

  HType computeType() {
    HType operandType = operand.type;
    if (!operandType.isUnknown()) return operandType;
    return HType.UNKNOWN;
  }

  HType computeDesiredInputType(HInstruction input) {
    // TODO(floitsch): we want the target to be a function.
    if (input == target) return HType.UNKNOWN;
    if (type.isUnknown() || type.isNumber()) return HType.NUMBER;
    return HType.UNKNOWN;
  }

  bool hasExpectedType() => builtin || type.isUnknown();

  abstract UnaryOperation get operation();
}

class HNegate extends HInvokeUnary {
  HNegate(HStatic target, HInstruction input) : super(target, input);
  accept(HVisitor visitor) => visitor.visitNegate(this);

  NegateOperation get operation() => const NegateOperation();
  int typeCode() => 16;
  bool typeEquals(other) => other is HNegate;
  bool dataEquals(HInstruction other) => true;
}

class HBitNot extends HInvokeUnary {
  HBitNot(HStatic target, HInstruction input) : super(target, input);
  accept(HVisitor visitor) => visitor.visitBitNot(this);

  bool get builtin() => operand.isInteger();

  HType computeType() {
    HType operandType = operand.type;
    if (!operandType.isUnknown()) return operandType;
    return HType.UNKNOWN;
  }

  HType computeDesiredInputType(HInstruction input) {
    // TODO(floitsch): we want the target to be a function.
    if (input == target) return HType.UNKNOWN;
    return HType.INTEGER;
  }

  BitNotOperation get operation() => const BitNotOperation();
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

class HBreak extends HGoto {
  final TargetElement target;
  final LabelElement label;
  HBreak(this.target) : label = null;
  HBreak.toLabel(LabelElement label) : label = label, target = label.target;
  toString() => (label !== null) ? 'break ${label.labelName}' : 'break';
  accept(HVisitor visitor) => visitor.visitBreak(this);
}

class HContinue extends HGoto {
  final TargetElement target;
  final LabelElement label;
  HContinue(this.target) : label = null;
  HContinue.toLabel(LabelElement label) : label = label, target = label.target;
  toString() => (label !== null) ? 'continue ${label.labelName}' : 'continue';
  accept(HVisitor visitor) => visitor.visitContinue(this);
}

class HTry extends HControlFlow {
  HParameterValue exception;
  HBasicBlock finallyBlock;
  HTry() : super(const <HInstruction>[]);
  toString() => 'try';
  accept(HVisitor visitor) => visitor.visitTry(this);
  HBasicBlock get joinBlock() => this.block.successors.last();
}

class HIf extends HConditionalBranch {
  bool hasElse;
  HIfBlockInformation blockInformation = null;
  HIf(HInstruction condition, this.hasElse) : super(<HInstruction>[condition]);
  toString() => 'if';
  accept(HVisitor visitor) => visitor.visitIf(this);

  HBasicBlock get thenBlock() {
    assert(block.dominatedBlocks[0] === block.successors[0]);
    return block.successors[0];
  }

  HBasicBlock get elseBlock() {
    if (hasElse) {
      assert(block.dominatedBlocks[1] === block.successors[1]);
      return block.successors[1];
    } else {
      return null;
    }
  }

  HBasicBlock get joinBlock() => blockInformation.joinBlock;
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
  HConstant.internal(this.constant, HType type) : super(<HInstruction>[]) {
    this.type = type;
  }

  void prepareGvn() {
    assert(!hasSideEffects());
  }

  toString() => 'literal: $constant';
  accept(HVisitor visitor) => visitor.visitConstant(this);
  HType computeType() => type;

  bool hasExpectedType() => true;

  bool isConstant() => true;
  bool isConstantBoolean() => constant.isBool();
  bool isConstantNull() => constant.isNull();
  bool isConstantNumber() => constant.isNum();
  bool isConstantString() => constant.isString();

  // Maybe avoid this if the literal is big?
  bool isCodeMotionInvariant() => true;
}

class HNot extends HInstruction {
  HNot(HInstruction value) : super(<HInstruction>[value]);
  void prepareGvn() {
    assert(!hasSideEffects());
    setUseGvn();
  }

  HType computeType() => HType.BOOLEAN;
  bool hasExpectedType() => true;
  HType computeDesiredInputType(HInstruction input) {
    return HType.BOOLEAN;
  }

  accept(HVisitor visitor) => visitor.visitNot(this);
  int typeCode() => 18;
  bool typeEquals(other) => other is HNot;
  bool dataEquals(HInstruction other) => true;
}

class HParameterValue extends HInstruction {
  final Element element;

  HParameterValue(this.element) : super(<HInstruction>[]);

  void prepareGvn() {
    assert(!hasSideEffects());
  }
  toString() => 'parameter ${element.name}';
  accept(HVisitor visitor) => visitor.visitParameterValue(this);
  bool isCodeMotionInvariant() => true;
}

class HThis extends HParameterValue {
  HThis() : super(null);
  toString() => 'this';
  accept(HVisitor visitor) => visitor.visitThis(this);
}

class HPhi extends HInstruction {
  final Element element;

  static final IS_NOT_LOGICAL_OPERATOR = 0;
  static final IS_AND = 1;
  static final IS_OR = 2;

  int logicalOperatorType = IS_NOT_LOGICAL_OPERATOR;

  // The order of the [inputs] must correspond to the order of the
  // predecessor-edges. That is if an input comes from the first predecessor
  // of the surrounding block, then the input must be the first in the [HPhi].
  HPhi(this.element, List<HInstruction> inputs) : super(inputs);
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
  HType computeInputsType() {
    bool seenUnknown = false;
    HType candidateType = inputs[0].type;
    for (int i = 1, length = inputs.length; i < length; i++) {
      HType inputType = inputs[i].type;
      if (inputType.isUnknown()) return HType.UNKNOWN;
      candidateType = candidateType.combine(inputType);
      if (candidateType.isConflicting()) return HType.CONFLICTING;
    }
    return candidateType;
  }

  HType computeType() {
    HType inputsType = computeInputsType();
    if (!inputsType.isUnknown()) return inputsType;
    return super.computeType();
  }

  HType computeDesiredInputType(HInstruction input) {
    if (type.isNumber()) return HType.NUMBER;
    if (type.isStringOrArray()) return HType.STRING_OR_ARRAY;
    return type;
  }

  bool hasExpectedType() {
    for (int i = 0; i < inputs.length; i++) {
      if (type.combine(inputs[i].type).isConflicting()) return false;
    }
    return true;
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
  HRelational(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right) {
    type = HType.BOOLEAN;
  }

  void prepareGvn() {
    // Relational expressions can take part in global value numbering
    // and do not have any side-effects if we know all the inputs are
    // numbers. This can be improved for at least equality.
    if (builtin) {
      clearAllSideEffects();
      setUseGvn();
    } else {
      setAllSideEffects();
    }
  }

  HType computeDesiredInputType(HInstruction input) {
    // TODO(floitsch): we want the target to be a function.
    if (input == target) return HType.UNKNOWN;
    // For all relational operations exept HEquals, we expect to only
    // get numbers.
    return HType.NUMBER;
  }

  bool get builtin() => left.isNumber() && right.isNumber();
  HType computeType() => HType.BOOLEAN;
  // A HRelational goes through the builtin operator or the top level
  // element. Therefore, it always has the expected type.
  bool hasExpectedType() => true;
  // TODO(1603): the class should be marked as abstract.
  abstract BinaryOperation get operation();
}

class HEquals extends HRelational {
  HEquals(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitEquals(this);

  bool get builtin() {
    if (left.isNumber() && right.isNumber()) return true;
    if (left is !HConstant) return false;
    HConstant leftConstant = left;
    // TODO(floitsch): we can do better if we know that the constant does not
    // have the equality operator overridden.
    return !leftConstant.constant.isConstructedObject();
  }

  HType computeType() => HType.BOOLEAN;

  HType computeDesiredInputType(HInstruction input) {
    // TODO(floitsch): we want the target to be a function.
    if (input == target) return HType.UNKNOWN;
    if (left.isNumber() || right.isNumber()) return HType.NUMBER;
    return HType.UNKNOWN;
  }

  EqualsOperation get operation() => const EqualsOperation();
  int typeCode() => 19;
  bool typeEquals(other) => other is HEquals;
  bool dataEquals(HInstruction other) => true;
}

class HIdentity extends HRelational {
  HIdentity(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitIdentity(this);

  bool get builtin() => true;
  HType computeType() => HType.BOOLEAN;
  bool hasExpectedType() => true;

  HType computeDesiredInputType(HInstruction input) => HType.UNKNOWN;

  IdentityOperation get operation() => const IdentityOperation();
  int typeCode() => 20;
  bool typeEquals(other) => other is HIdentity;
  bool dataEquals(HInstruction other) => true;
}

class HGreater extends HRelational {
  HGreater(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitGreater(this);

  GreaterOperation get operation() => const GreaterOperation();
  int typeCode() => 21;
  bool typeEquals(other) => other is HGreater;
  bool dataEquals(HInstruction other) => true;
}

class HGreaterEqual extends HRelational {
  HGreaterEqual(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitGreaterEqual(this);

  GreaterEqualOperation get operation() => const GreaterEqualOperation();
  int typeCode() => 22;
  bool typeEquals(other) => other is HGreaterEqual;
  bool dataEquals(HInstruction other) => true;
}

class HLess extends HRelational {
  HLess(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitLess(this);

  LessOperation get operation() => const LessOperation();
  int typeCode() => 23;
  bool typeEquals(other) => other is HLess;
  bool dataEquals(HInstruction other) => true;
}

class HLessEqual extends HRelational {
  HLessEqual(HStatic target, HInstruction left, HInstruction right)
      : super(target, left, right);
  accept(HVisitor visitor) => visitor.visitLessEqual(this);

  LessEqualOperation get operation() => const LessEqualOperation();
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
  Element element;
  HStatic(this.element) : super(<HInstruction>[]);

  void prepareGvn() {
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
}

class HLiteralList extends HInstruction {
  HLiteralList(inputs) : super(inputs);
  toString() => 'literal list';
  accept(HVisitor visitor) => visitor.visitLiteralList(this);
  HType computeType() => HType.MUTABLE_ARRAY;
  bool hasExpectedType() => true;

  void prepareGvn() {
    assert(!hasSideEffects());
  }
}

class HIndex extends HInvokeStatic {
  HIndex(HStatic target, HInstruction receiver, HInstruction index)
      : super(Selector.INDEX, <HInstruction>[target, receiver, index]);
  toString() => 'index operator';
  accept(HVisitor visitor) => visitor.visitIndex(this);

  void prepareGvn() {
    if (builtin) {
      clearAllSideEffects();
    } else {
      setAllSideEffects();
    }
  }

  HInstruction get receiver() => inputs[1];
  HInstruction get index() => inputs[2];

  HType computeDesiredInputType(HInstruction input) {
    // TODO(floitsch): we want the target to be a function.
    if (input == target) return HType.UNKNOWN;
    if (input == receiver) return HType.STRING_OR_ARRAY;
    return HType.UNKNOWN;
  }

  bool get builtin() => receiver.isStringOrArray();
  HType computeType() => HType.UNKNOWN;
  bool hasExpectedType() => false;
}

class HIndexAssign extends HInvokeStatic {
  HIndexAssign(HStatic target,
               HInstruction receiver,
               HInstruction index,
               HInstruction value)
      : super(Selector.INDEX_SET,
              <HInstruction>[target, receiver, index, value]);
  toString() => 'index assign operator';
  accept(HVisitor visitor) => visitor.visitIndexAssign(this);

  HInstruction get receiver() => inputs[1];
  HInstruction get index() => inputs[2];
  HInstruction get value() => inputs[3];

  HType computeDesiredInputType(HInstruction input) {
    // TODO(floitsch): we want the target to be a function.
    if (input == target) return HType.UNKNOWN;
    if (input == receiver) return HType.MUTABLE_ARRAY;
    return HType.UNKNOWN;
  }

  bool get builtin() => receiver.isMutableArray();
  HType computeType() => value.type;
  // This instruction does not yield a new value, so it always
  // has the expected type (void).
  bool hasExpectedType() => true;
}

class HIs extends HInstruction {
  final Type typeName;
  final bool nullOk;

  HIs(this.typeName, HInstruction expression, [nullOk = false])
    : this.nullOk = nullOk, super(<HInstruction>[expression]);

  HInstruction get expression() => inputs[0];

  HType computeType() => HType.BOOLEAN;
  bool hasExpectedType() => true;

  accept(HVisitor visitor) => visitor.visitIs(this);

  toString() => "$expression is $typeName";
}

class HIfBlockInformation {
  final HIf branch;
  final SubGraph thenGraph;
  final SubGraph elseGraph;
  final HBasicBlock joinBlock;
  HIfBlockInformation(this.branch,
                      this.thenGraph,
                      this.elseGraph,
                      this.joinBlock);
}
