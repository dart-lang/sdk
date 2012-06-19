// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Instead of emitting each SSA instruction with a temporary variable
 * mark instructions that can be emitted at their use-site.
 * For example, in:
 *   t0 = 4;
 *   t1 = 3;
 *   t2 = add(t0, t1);
 * t0 and t1 would be marked and the resulting code would then be:
 *   t2 = add(4, 3);
 */
class SsaInstructionMerger extends HBaseVisitor {
  List<HInstruction> expectedInputs;
  Set<HInstruction> generateAtUseSite;

  SsaInstructionMerger(this.generateAtUseSite);

  void visitGraph(HGraph graph) {
    visitDominatorTree(graph);
  }

  void visitInstruction(HInstruction instruction) {
    // A code motion invariant instruction is dealt before visiting it.
    assert(!instruction.isCodeMotionInvariant());
    for (HInstruction input in instruction.inputs) {
      if (!generateAtUseSite.contains(input)
          && !input.isCodeMotionInvariant()
          && input.usedBy.length == 1
          && input is !HPhi) {
        expectedInputs.add(input);
      }
    }
  }

  // The codegen might use the input multiple times, so it must not be
  // set generate at use site.
  void visitIs(HIs instruction) {}

  // A check method must not have its input generate at use site,
  // because it's using it multiple times.
  void visitCheck(HCheck instruction) {}

  // A type guard should not generate its input at use site, otherwise
  // they would not be alive.
  void visitTypeGuard(HTypeGuard instruction) {}

  void visitTypeConversion(HTypeConversion instruction) {
    if (!instruction.isChecked()) {
      generateAtUseSite.add(instruction);
    } else if (instruction.isCheckedModeCheck()) {
      // Checked mode checks compile to code that only use their input
      // once, so we can safely visit them an try to merge the input.
      visitInstruction(instruction);
    }
  }

  void tryGenerateAtUseSite(HInstruction instruction) {
    if (instruction.isControlFlow()) return;
    generateAtUseSite.add(instruction);
  }

  bool isBlockSinglePredecessor(HBasicBlock block) {
    return block.successors.length === 1
        && block.successors[0].predecessors.length === 1;
  }

  void visitBasicBlock(HBasicBlock block) {
    // Compensate from not merging blocks: if the block is the
    // single predecessor of its single successor, let the successor
    // visit it.
    if (isBlockSinglePredecessor(block)) return;

    tryMergingExpressions(block);
  }

  void tryMergingExpressions(HBasicBlock block) {
    // Visit each instruction of the basic block in last-to-first order.
    // Keep a list of expected inputs of the current "expression" being
    // merged. If instructions occur in the expected order, they are
    // included in the expression.

    // The expectedInputs list holds non-trivial instructions that may
    // be generated at their use site, if they occur in the correct order.
    if (expectedInputs === null) expectedInputs = new List<HInstruction>();

    // Pop instructions from expectedInputs until instruction is found.
    // Return true if it is found, or false if not.
    bool findInInputsAndPopNonMatching(HInstruction instruction) {
      while (!expectedInputs.isEmpty()) {
        HInstruction nextInput = expectedInputs.removeLast();
        assert(!generateAtUseSite.contains(nextInput));
        assert(nextInput.usedBy.length == 1);
        if (nextInput === instruction) {
          return true;
        }
      }
      return false;
    }

    block.last.accept(this);
    for (HInstruction instruction = block.last.previous;
         instruction !== null;
         instruction = instruction.previous) {
      if (generateAtUseSite.contains(instruction)) {
        continue;
      }
      if (instruction.isCodeMotionInvariant()) {
        generateAtUseSite.add(instruction);
        continue;
      }
      // See if the current instruction is the next non-trivial
      // expected input.
      if (findInInputsAndPopNonMatching(instruction)) {
        tryGenerateAtUseSite(instruction);
      } else {
        assert(expectedInputs.isEmpty());
      }
      instruction.accept(this);
    }

    if (block.predecessors.length === 1
        && isBlockSinglePredecessor(block.predecessors[0])) {
      assert(block.phis.isEmpty());
      tryMergingExpressions(block.predecessors[0]);
    } else {
      expectedInputs = null;
    }
  }
}

/**
 *  Detect control flow arising from short-circuit logical and
 *  conditional operators, and prepare the program to be generated
 *  using these operators instead of nested ifs and boolean variables.
 */
class SsaConditionMerger extends HGraphVisitor {
  Set<HInstruction> generateAtUseSite;
  Set<HInstruction> controlFlowOperators;

  SsaConditionMerger(this.generateAtUseSite, this.controlFlowOperators);

  void visitGraph(HGraph graph) {
    visitPostDominatorTree(graph);
  }

  /**
   * Check if a block has at least one statement other than
   * [instruction].
   */
  bool hasAnyStatement(HBasicBlock block, HInstruction instruction) {
    // If [instruction] is not in [block], then if the block is not
    // empty, we know there will be a statement to emit.
    if (instruction.block !== block) return block.last !== block.first;

    // If [instruction] is not the last instruction of the block
    // before the control flow instruction, or the last instruction,
    // then we will have to emit a statement for that last instruction.
    if (instruction != block.last
        && instruction !== block.last.previous) return true;

    // If one of the instructions in the block until [instruction] is
    // not generated at use site, then we will have to emit a
    // statement for it.
    // TODO(ngeoffray): we could generate a comma separated
    // list of expressions.
    for (HInstruction temp = block.first;
         temp !== instruction;
         temp = temp.next) {
      if (!generateAtUseSite.contains(temp)) return true;
    }

    return false;
  }

  bool isSafeToGenerateAtUseSite(HInstruction user, HInstruction input) {
    // A [HForeign] instruction uses operators and if we generate
    // [input] at use site, the precedence might be wrong.
    if (user is HForeign) return false;
    // A [HCheck] instruction with control flow uses its input
    // multiple times, so we avoid generating it at use site.
    if (user is HCheck && user.isControlFlow()) return false;
    // A [HIs] instruction uses its input multiple times, so we
    // avoid generating it at use site.
    if (user is HIs) return false;
    return true;
  }

  void visitBasicBlock(HBasicBlock block) {
    if (block.last is !HIf) return;
    HIf startIf = block.last;
    HBasicBlock end = startIf.joinBlock;

    // We check that the structure is the following:
    //         If
    //       /    \
    //      /      \
    //   1 expr    goto
    //    goto     /
    //      \     /
    //       \   /
    // phi(expr, true|false)
    if (end == null) return;
    if (end.phis.isEmpty()) return;
    if (end.phis.first !== end.phis.last) return;
    HBasicBlock elseBlock = startIf.elseBlock;

    if (end.predecessors[1] !== elseBlock) return;
    HPhi phi = end.phis.first;
    HInstruction thenInput = phi.inputs[0];
    HInstruction elseInput = phi.inputs[1];

    if (hasAnyStatement(elseBlock, elseInput)) return;
    assert(elseBlock.successors.length == 1);
    assert(end.predecessors.length == 2);

    HBasicBlock thenBlock = startIf.thenBlock;
    // Skip trivial goto blocks.
    while (thenBlock.successors[0] != end && thenBlock.first is HGoto) {
      thenBlock = thenBlock.successors[0];
    }
    
    // If the [thenBlock] is already a control flow operation, and does not
    // have any statement and its join block is [end], we can emit a
    // sequence of control flow operation.
    if (controlFlowOperators.contains(thenBlock.last)) {
      HIf otherIf = thenBlock.last;
      if (otherIf.joinBlock !== end) return;
      if (hasAnyStatement(thenBlock, otherIf)) return;
    } else {
      if (end.predecessors[0] !== thenBlock) return;
      if (hasAnyStatement(thenBlock, thenInput)) return;
      assert(thenBlock.successors.length == 1);
    }
     
    // From now on, we have recognized a control flow operation built from
    // the builder. Mark the if instruction as such.
    controlFlowOperators.add(startIf);

    // If the operation is only used by the first instruction
    // of its block and is safe to be generated at use sute, mark it
    // so.
    if (phi.usedBy.length == 1
        && phi.usedBy[0] === phi.block.first
        && isSafeToGenerateAtUseSite(phi.usedBy[0], phi)) {
      generateAtUseSite.add(phi);
    }

    if (elseInput.block === elseBlock) {
      assert(elseInput.usedBy.length == 1);
      generateAtUseSite.add(elseInput);
    }

    // If [thenInput] is defined in the first predecessor, then it is only used
    // by [phi] and can be generated at use site.
    if (thenInput.block === end.predecessors[0]) {
      assert(thenInput.usedBy.length == 1);
      generateAtUseSite.add(thenInput);
    }
  }
}

// Precedence information for JavaScript operators.
class JSPrecedence {
   // Used as precedence for something that's not even an expression.
  static final int STATEMENT_PRECEDENCE      = 0;
  // Precedences of JS operators.
  static final int EXPRESSION_PRECEDENCE     = 1;
  static final int ASSIGNMENT_PRECEDENCE     = 2;
  static final int CONDITIONAL_PRECEDENCE    = 3;
  static final int LOGICAL_OR_PRECEDENCE     = 4;
  static final int LOGICAL_AND_PRECEDENCE    = 5;
  static final int BITWISE_OR_PRECEDENCE     = 6;
  static final int BITWISE_XOR_PRECEDENCE    = 7;
  static final int BITWISE_AND_PRECEDENCE    = 8;
  static final int EQUALITY_PRECEDENCE       = 9;
  static final int RELATIONAL_PRECEDENCE     = 10;
  static final int SHIFT_PRECEDENCE          = 11;
  static final int ADDITIVE_PRECEDENCE       = 12;
  static final int MULTIPLICATIVE_PRECEDENCE = 13;
  static final int PREFIX_PRECEDENCE         = 14;
  static final int POSTFIX_PRECEDENCE        = 15;
  static final int CALL_PRECEDENCE           = 16;
  // We never use "new MemberExpression" without arguments, so we can
  // combine CallExpression and MemberExpression without ambiguity.
  static final int MEMBER_PRECEDENCE         = CALL_PRECEDENCE;
  static final int PRIMARY_PRECEDENCE        = 17;

  // The operators that an occur in HBinaryOp.
  static final Map<String, JSBinaryOperatorPrecedence> binary = const {
    "||" : const JSBinaryOperatorPrecedence(LOGICAL_OR_PRECEDENCE,
                                            LOGICAL_AND_PRECEDENCE),
    "&&" : const JSBinaryOperatorPrecedence(LOGICAL_AND_PRECEDENCE,
                                            BITWISE_OR_PRECEDENCE),
    "|" : const JSBinaryOperatorPrecedence(BITWISE_OR_PRECEDENCE,
                                           BITWISE_XOR_PRECEDENCE),
    "^" : const JSBinaryOperatorPrecedence(BITWISE_XOR_PRECEDENCE,
                                           BITWISE_AND_PRECEDENCE),
    "&" : const JSBinaryOperatorPrecedence(BITWISE_AND_PRECEDENCE,
                                           EQUALITY_PRECEDENCE),
    "==" : const JSBinaryOperatorPrecedence(EQUALITY_PRECEDENCE,
                                            RELATIONAL_PRECEDENCE),
    "!=" : const JSBinaryOperatorPrecedence(EQUALITY_PRECEDENCE,
                                            RELATIONAL_PRECEDENCE),
    "===" : const JSBinaryOperatorPrecedence(EQUALITY_PRECEDENCE,
                                             RELATIONAL_PRECEDENCE),
    "!==" : const JSBinaryOperatorPrecedence(EQUALITY_PRECEDENCE,
                                             RELATIONAL_PRECEDENCE),
    "<" : const JSBinaryOperatorPrecedence(RELATIONAL_PRECEDENCE,
                                           SHIFT_PRECEDENCE),
    ">" : const JSBinaryOperatorPrecedence(RELATIONAL_PRECEDENCE,
                                           SHIFT_PRECEDENCE),
    "<=" : const JSBinaryOperatorPrecedence(RELATIONAL_PRECEDENCE,
                                            SHIFT_PRECEDENCE),
    ">=" : const JSBinaryOperatorPrecedence(RELATIONAL_PRECEDENCE,
                                            SHIFT_PRECEDENCE),
    "<<" : const JSBinaryOperatorPrecedence(SHIFT_PRECEDENCE,
                                            ADDITIVE_PRECEDENCE),
    ">>" : const JSBinaryOperatorPrecedence(SHIFT_PRECEDENCE,
                                            ADDITIVE_PRECEDENCE),
    ">>>" : const JSBinaryOperatorPrecedence(SHIFT_PRECEDENCE,
                                             ADDITIVE_PRECEDENCE),
    "+" : const JSBinaryOperatorPrecedence(ADDITIVE_PRECEDENCE,
                                           MULTIPLICATIVE_PRECEDENCE),
    "-" : const JSBinaryOperatorPrecedence(ADDITIVE_PRECEDENCE,
                                           MULTIPLICATIVE_PRECEDENCE),
    "*" : const JSBinaryOperatorPrecedence(MULTIPLICATIVE_PRECEDENCE,
                                           PREFIX_PRECEDENCE),
    "/" : const JSBinaryOperatorPrecedence(MULTIPLICATIVE_PRECEDENCE,
                                           PREFIX_PRECEDENCE),
    "%" : const JSBinaryOperatorPrecedence(MULTIPLICATIVE_PRECEDENCE,
                                           PREFIX_PRECEDENCE),
  };
}

class JSBinaryOperatorPrecedence {
  final int left;
  final int right;
  const JSBinaryOperatorPrecedence(this.left, this.right);
  // All binary operators (excluding assignment) are left associative.
  int get precedence() => left;
}
