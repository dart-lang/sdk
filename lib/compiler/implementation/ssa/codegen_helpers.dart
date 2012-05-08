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

  bool usedOnlyByPhis(instruction) {
    for (HInstruction user in instruction.usedBy) {
      if (user is! HPhi) return false;
    }
    return true;
  }

  void visitInstruction(HInstruction instruction) {
    // A code motion invariant instruction is dealt before visiting it.
    assert(!instruction.isCodeMotionInvariant());
    for (HInstruction input in instruction.inputs) {
      if (!generateAtUseSite.contains(input)
          && !input.isCodeMotionInvariant()
          && input.usedBy.length == 1
          && input is! HPhi) {
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
    if (!instruction.checked) generateAtUseSite.add(instruction);
    visitInstruction(instruction);
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

    for (HBasicBlock successor in block.successors) {
      // Only add the input of the first phi. Making inputs of
      // later phis generate-at-use-site would make them move
      // accross the assignment of the first phi, and we need
      // more analysis before we can do that.
      HPhi phi = successor.phis.first;
      if (phi != null) {
        int index = successor.predecessors.indexOf(block);
        HInstruction input = phi.inputs[index];
        if (!generateAtUseSite.contains(input)
            && !input.isCodeMotionInvariant()
            && input.usedBy.length == 1
            && input is! HPhi) {
          expectedInputs.add(input);
        }
        break;
      }
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
 *  Detect control flow arising from short-circuit logical operators, and
 *  prepare the program to be generated using these operators instead of
 *  nested ifs and boolean variables.
 */
class SsaConditionMerger extends HGraphVisitor {
  Set<HInstruction> generateAtUseSite;
  Map<HPhi, String> logicalOperations;

  SsaConditionMerger(this.generateAtUseSite, this.logicalOperations);

  void visitGraph(HGraph graph) {
    visitDominatorTree(graph);
  }

  /**
   * Returns true if the given instruction is an expression that uses up all
   * instructions up to the given [limit].
   *
   * That is, all instructions starting after the [limit] block (at the branch
   * leading to the [instruction]) down to the given [instruction] can be
   * generated at use-site.
   */
  bool isExpression(HInstruction instruction, HBasicBlock limit) {
    HBasicBlock block = instruction.block;
    if (instruction is HPhi) {
      if (!logicalOperations.containsKey(instruction)) {
        return false;
      }
    } else {
      while (instruction.previous != null) {
        instruction = instruction.previous;
        if (!generateAtUseSite.contains(instruction)) {
          return false;
        }
      }
      // Now [instruction] is the first instruction of the block
      // (aka [block.first]). If there are also a phi, check the current
      // [instruction] normally and make [instruction] be the phi.
      if (!block.phis.isEmpty()) {
        if (!generateAtUseSite.contains(instruction)) {
          return false;
        }
        instruction = block.phis.last;
        if (block.phis.first !== instruction) {
          // If there is more than one phi, don't try to undestand it.
          return false;
        }
        if (!logicalOperations.containsKey(instruction)) {
          return false;
        }
      }
    }
    if (instruction is HPhi) {
      assert(logicalOperations.containsKey(instruction));
      return isExpression(instruction.inputs[0], limit);
    }
    if (block.predecessors.length !== 1) {
      return false;
    }
    HBasicBlock previousBlock = block.predecessors[0];
    if (previousBlock === limit) return true;
    if (previousBlock.successors.length !== 1 ||
        previousBlock.last is! HGoto) {
      return false;
    }
    return isExpression(previousBlock.last, limit);
  }

  void replaceWithLogicalOperator(HPhi phi, String type) {
    if (canGenerateAtUseSite(phi)) generateAtUseSite.add(phi);
    logicalOperations[phi] = type;
    // If the phi corresponds to logical control flow, mark the
    // control-flow instructions as generate-at-use-site.
    generateAtUseSite.add(phi.block.predecessors[0].last);
    generateAtUseSite.add(phi.block.predecessors[1].last);
    // If the first input is only used as branch condition and result, it too
    // can be generate-at-use-site.
    if (phi.inputs[0].usedBy.length == 2) {
      generateAtUseSite.add(phi.inputs[0]);
    }
    if (phi.inputs[1].usedBy.length == 1) {
      generateAtUseSite.add(phi.inputs[1]);
    }
  }

  bool canGenerateAtUseSite(HPhi phi) {
    if (phi.usedBy.length != 1) {
      return false;
    }
    assert(phi.next == null);
    HInstruction use = phi.usedBy[0];

    HInstruction current = phi.block.first;
    while (current != use) {
      // Check that every instruction between the start of the block and the
      // use of the phi (i.e., every instruction between the phi and the use)
      // is itself generated at use site. That means that the phi can be
      // moved to its use site without crossing any other code, because those
      // instructions (if any) are moved too.
      if (current is! HControlFlow && !generateAtUseSite.contains(current)) {
        return false;
      }
      if (current.next != null) {
        current = current.next;
      } else if (current is HPhi) {
        current = current.block.first;
      } else {
        assert(current is HControlFlow);
        if (current is !HGoto) {
          return false;
        }
        HBasicBlock nextBlock = current.block.successors[0];
        if (!nextBlock.phis.isEmpty()) {
          current = nextBlock.phis.first;
        } else {
          current = nextBlock.first;
        }
      }
    }
    return true;
  }

  HInstruction previousInstruction(HInstruction instruction) {
    if (instruction.previous != null) return instruction.previous;
    HBasicBlock block = instruction.block;
    if (instruction is! HPhi) {
      if (block.phis.last != null) return block.phis.last;
    }
    if (block.predecessors.length == 1) {
      HBasicBlock previousBlock = block.predecessors[0];
      if (previousBlock.last is HGoto) {
        assert(previousBlock.successors.length == 1);
        assert(previousBlock.successors[0] === block);
        return previousInstruction(previousBlock.last);
      }
    }
    return null;
  }

  void detectLogicControlFlow(HPhi phi) {
    // Check for the most common pattern for a short-circuit logic operation:
    //   B0 b0 = ...; if (b0) goto B1 else B2 (or: if (!b0) goto B2 else B1)
    //   |\
    //   | B1 b1 = ...; goto B2
    //   |/
    //   B2 b2 = phi(b0,b1); if(b2) ...
    // TODO(lrn): Also recognize ?:-flow?
    if (phi.inputs.length != 2) return;
    HInstruction first = phi.inputs[0];
    HBasicBlock firstBlock = phi.block.predecessors[0];
    HInstruction second = phi.inputs[1];
    HBasicBlock secondBlock = phi.block.predecessors[1];
    // Check second input of phi being an expression followed by a goto.
    if (second.usedBy.length != 1) return;
    HInstruction secondNext =
        (second is HPhi) ? secondBlock.first : second.next;
    if (secondNext != secondBlock.last) return;
    if (secondBlock.last is !HGoto) return;
    if (secondBlock.successors[0] != phi.block) return;
    if (!isExpression(second, firstBlock)) return;
    // Check first input of phi being followed by a (possibly negated)
    // conditional branch based on the same value.
    if (firstBlock != phi.block.dominator) return;
    if (firstBlock.last is! HIf) return;
    if (firstBlock.successors[1] != phi.block) return;
    HIf firstBranch = firstBlock.last;
    HInstruction condition = firstBranch.inputs[0];
    if (condition === first) {
      replaceWithLogicalOperator(phi, "&&");
    } else if (condition is HNot &&
               condition.inputs[0] == first) {
      replaceWithLogicalOperator(phi, "||");
      // If the negation is only used by this logical operation, or only by
      // logical operators in general, it won't need to be generated.
      if (!generateAtUseSite.contains(condition)) {
        for (HInstruction user in condition.usedBy) {
          if (user is! HIf || !generateAtUseSite.contains(user)) {
            return;
          }
        }
        generateAtUseSite.add(condition);
      }
    }
    return;
  }

  void visitBasicBlock(HBasicBlock block) {
    if (!block.phis.isEmpty() &&
        block.phis.first === block.phis.last) {
      detectLogicControlFlow(block.phis.first);
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

class PhiEquivalator {
  final Equivalence<HPhi> equivalence;
  final Map<HPhi, String> logicalOperations;
  PhiEquivalator(this.equivalence, this.logicalOperations);

  void analyzeGraph(HGraph graph) {
    graph.blocks.forEach(analyzeBlock);
  }

  void analyzeBlock(HBasicBlock block) {
    for (HPhi phi = block.phis.first; phi !== null; phi = phi.next) {
      if (!logicalOperations.containsKey(phi) &&
          phi.usedBy.length == 1 &&
          phi.usedBy[0] is HPhi &&
          phi.block.id < phi.usedBy[0].block.id) {
        equivalence.makeEquivalent(phi, phi.usedBy[0]);
      }
    }
  }
}


/**
 * Try to figure out which phis can be represented by the same temporary
 * variable, to avoid creating a new variable for each phi.
 */
class Equivalence<T extends Hashable> {
  // Represent equivalence classes of HPhi nodes as a forest of trees,
  // where each tree is one equivalence class, and the root is the
  // canonical representative for the equivalence class.
  // Implement the forest by having each phi point to its parent in the tree,
  // transitively linking it to the root, which itself doesn't have a parent.
  final Map<T,T> representative;

  Equivalence() : representative = new Map<T,T>();

  T makeEquivalent(T a, T b) {
    T root1 = getRepresentative(a);
    T root2 = getRepresentative(b);
    if (root1 !== root2) {
      // Merge the trees for the two classes into one.
      representative[root1] = root2;
    }
  }

  /**
   * Get the canonical representative for an equivalence class of phis.
   */
  T getRepresentative(T element) {
    T parent = representative[element];
    if (parent === null) {
      // This is the root of a tree (a previously unseen node is considered
      // the root of its own tree).
      return element;
    }
    // Shorten the path for all the elements on the way to the root,
    // improving the performance of future lookups.
    T root = getRepresentative(parent);
    if (root !== parent) representative[element] = root;
    return root;
  }

  bool areEquivalent(T a, T b) {
    return getRepresentative(a) === getRepresentative(b);
  }
}
