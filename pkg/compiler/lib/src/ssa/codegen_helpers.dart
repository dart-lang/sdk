// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

/**
 * Replaces some instructions with specialized versions to make codegen easier.
 * Caches codegen information on nodes.
 */
class SsaInstructionSelection extends HBaseVisitor {
  final Compiler compiler;
  HGraph graph;

  SsaInstructionSelection(this.compiler);

  JavaScriptBackend get backend => compiler.backend;

  void visitGraph(HGraph graph) {
    this.graph = graph;
    visitDominatorTree(graph);
  }

  visitBasicBlock(HBasicBlock block) {
    HInstruction instruction = block.first;
    while (instruction != null) {
      HInstruction next = instruction.next;
      HInstruction replacement = instruction.accept(this);
      if (replacement != instruction && replacement != null) {
        block.rewrite(instruction, replacement);

        // If the replacement instruction does not know its source element, use
        // the source element of the instruction.
        if (replacement.sourceElement == null) {
          replacement.sourceElement = instruction.sourceElement;
        }
        if (replacement.sourcePosition == null) {
          replacement.sourcePosition = instruction.sourcePosition;
        }
        if (!replacement.isInBasicBlock()) {
          // The constant folding can return an instruction that is already
          // part of the graph (like an input), so we only add the replacement
          // if necessary.
          block.addAfter(instruction, replacement);
          // Visit the replacement as the next instruction in case it can also
          // be constant folded away.
          next = replacement;
        }
        block.remove(instruction);
      }
      instruction = next;
    }
  }

  HInstruction visitInstruction(HInstruction node) {
    return node;
  }

  HInstruction visitIs(HIs node) {
    if (node.kind == HIs.RAW_CHECK) {
      HInstruction interceptor = node.interceptor;
      if (interceptor != null) {
        return new HIsViaInterceptor(node.typeExpression, interceptor,
                                     backend.boolType);
      }
    }
    return node;
  }

  HInstruction visitIdentity(HIdentity node) {
    node.singleComparisonOp = simpleOp(node.left, node.right);
    return node;
  }

  String simpleOp(HInstruction left, HInstruction right) {
    // Returns the single identity comparison (== or ===) or null if a more
    // complex expression is required.
    TypeMask leftType = left.instructionType;
    TypeMask rightType = right.instructionType;
    if (leftType.isNullable && rightType.isNullable) {
      if (left.isConstantNull() ||
          right.isConstantNull() ||
          (left.isPrimitive(compiler) &&
           leftType == rightType)) {
        return '==';
      }
      return null;
    }
    return '===';
  }

  HInstruction visitInvokeDynamic(HInvokeDynamic node) {
    if (node.isInterceptedCall) {
      // Calls of the form
      //
      //     a.foo$1(a, x)
      //
      // where the interceptor calling convention is used come from recognizing
      // that 'a' is a 'self-interceptor'.  If the selector matches only methods
      // that ignore the explicit receiver parameter, replace occurences of the
      // receiver argument with a dummy receiver '0':
      //
      //     a.foo$1(a, x)   --->   a.foo$1(0, x)
      //
      // This often reduces the number of references to 'a' to one, allowing 'a'
      // to be generated at use to avoid a temporary, e.g.
      //
      //     t1 = b.get$thing();
      //     t1.foo$1(t1, x)
      // --->
      //     b.get$thing().foo$1(0, x)
      //
      Selector selector = node.selector;
      if (backend.isInterceptedSelector(selector) &&
          !backend.isInterceptedMixinSelector(selector)) {
        HInstruction interceptor = node.inputs[0];
        HInstruction receiverArgument = node.inputs[1];

        if (interceptor.nonCheck() == receiverArgument.nonCheck()) {
          // TODO(15933): Make automatically generated property extraction
          // closures work with the dummy receiver optimization.
          if (!selector.isGetter) {
            ConstantValue constant = new DummyConstantValue(
                receiverArgument.instructionType);
            HConstant dummy = graph.addConstant(constant, compiler);
            receiverArgument.usedBy.remove(node);
            node.inputs[1] = dummy;
            dummy.usedBy.add(node);
          }
        }
      }
    }

    return node;
  }

  HInstruction visitFieldSet(HFieldSet setter) {
    // Pattern match
    //     t1 = x.f; t2 = t1 + 1; x.f = t2; use(t2)   -->  ++x.f
    //     t1 = x.f; t2 = t1 op y; x.f = t2; use(t2)  -->  x.f op= y
    //     t1 = x.f; t2 = t1 + 1; x.f = t2; use(t1)   -->  x.f++
    HBasicBlock block = setter.block;
    HInstruction op = setter.value;
    HInstruction receiver = setter.receiver;

    bool isMatchingRead(HInstruction candidate) {
      if (candidate is HFieldGet) {
        if (candidate.element != setter.element) return false;
        if (candidate.receiver != setter.receiver) return false;
        // Recognize only three instructions in sequence in the same block.  This
        // could be broadened to allow non-interfering interleaved instructions.
        if (op.block != block) return false;
        if (candidate.block != block) return false;
        if (setter.previous != op) return false;
        if (op.previous != candidate) return false;
        return true;
      }
      return false;
    }

    HInstruction noMatchingRead() {
      // If we have other HFieldSet optimizations, they go here.
      return null;
    }

    HInstruction replaceOp(HInstruction replacement, HInstruction getter) {
      block.addBefore(setter, replacement);
      block.remove(setter);
      block.rewrite(op, replacement);
      block.remove(op);
      block.remove(getter);
      return null;
    }

    HInstruction plusOrMinus(String assignOp, String incrementOp) {
      HInvokeBinary binary = op;
      HInstruction left = binary.left;
      HInstruction right = binary.right;
      if (isMatchingRead(left)) {
        if (left.usedBy.length == 1) {
          if (right is HConstant && right.constant.isOne) {
            HInstruction rmw = new HReadModifyWrite.preOp(
                setter.element, incrementOp, receiver, op.instructionType);
            return replaceOp(rmw, left);
          } else {
            HInstruction rmw = new HReadModifyWrite.assignOp(
                setter.element,
                assignOp,
                receiver, right, op.instructionType);
            return replaceOp(rmw, left);
          }
        } else if (op.usedBy.length == 1 &&
                   right is HConstant &&
                   right.constant.isOne) {
          HInstruction rmw = new HReadModifyWrite.postOp(
              setter.element, incrementOp, receiver, op.instructionType);
          block.addAfter(left, rmw);
          block.remove(setter);
          block.remove(op);
          block.rewrite(left, rmw);
          block.remove(left);
          return null;
        }
      }
      return noMatchingRead();
    }

    HInstruction simple(String assignOp,
                        HInstruction left, HInstruction right) {
      if (isMatchingRead(left)) {
        if (left.usedBy.length == 1) {
          HInstruction rmw = new HReadModifyWrite.assignOp(
              setter.element,
              assignOp,
              receiver, right, op.instructionType);
          return replaceOp(rmw, left);
        }
      }
      return noMatchingRead();
    }

    HInstruction simpleBinary(String assignOp) {
      HInvokeBinary binary = op;
      return simple(assignOp, binary.left, binary.right);
    }

    HInstruction bitop(String assignOp) {
      // HBitAnd, HBitOr etc. are more difficult because HBitAnd(a.x, y)
      // sometimes needs to be forced to unsigned: a.x = (a.x & y) >>> 0.
      if (op.isUInt31(compiler)) return simpleBinary(assignOp);
      return noMatchingRead();
    }

    if (op is HAdd) return plusOrMinus('+', '++');
    if (op is HSubtract) return plusOrMinus('-', '--');

    if (op is HStringConcat) return simple('+', op.left, op.right);

    if (op is HMultiply) return simpleBinary('*');
    if (op is HDivide) return simpleBinary('/');

    if (op is HBitAnd) return bitop('&');
    if (op is HBitOr) return bitop('|');
    if (op is HBitXor) return bitop('^');

    return noMatchingRead();
  }
}

/**
 * Remove [HTypeKnown] instructions from the graph, to make codegen
 * analysis easier.
 */
class SsaTypeKnownRemover extends HBaseVisitor {

  void visitGraph(HGraph graph) {
    visitDominatorTree(graph);
  }

  void visitBasicBlock(HBasicBlock block) {
    HInstruction instruction = block.first;
    while (instruction != null) {
      HInstruction next = instruction.next;
      instruction.accept(this);
      instruction = next;
    }
  }

  void visitTypeKnown(HTypeKnown instruction) {
    instruction.block.rewrite(instruction, instruction.checkedInput);
    instruction.block.remove(instruction);
  }
}

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
  final Compiler compiler;
  /**
   * List of [HInstruction] that the instruction merger expects in
   * order when visiting the inputs of an instruction.
   */
  List<HInstruction> expectedInputs;
  /**
   * Set of pure [HInstruction] that the instruction merger expects to
   * find. The order of pure instructions do not matter, as they will
   * not be affected by side effects.
   */
  Set<HInstruction> pureInputs;
  Set<HInstruction> generateAtUseSite;

  void markAsGenerateAtUseSite(HInstruction instruction) {
    assert(!instruction.isJsStatement());
    generateAtUseSite.add(instruction);
  }

  SsaInstructionMerger(this.generateAtUseSite, this.compiler);

  void visitGraph(HGraph graph) {
    visitDominatorTree(graph);
  }

  void analyzeInputs(HInstruction user, int start) {
    List<HInstruction> inputs = user.inputs;
    for (int i = start; i < inputs.length; i++) {
      HInstruction input = inputs[i];
      if (!generateAtUseSite.contains(input)
          && !input.isCodeMotionInvariant()
          && input.usedBy.length == 1
          && input is !HPhi
          && input is !HLocalValue
          && !input.isJsStatement()) {
        if (input.isPure()) {
          // Only consider a pure input if it is in the same loop.
          // Otherwise, we might move GVN'ed instruction back into the
          // loop.
          if (user.hasSameLoopHeaderAs(input)) {
            // Move it closer to [user], so that instructions in
            // between do not prevent making it generate at use site.
            input.moveBefore(user);
            pureInputs.add(input);
            // Previous computations done on [input] are now invalid
            // because we moved [input] to another place. So all
            // non code motion invariant instructions need
            // to be removed from the [generateAtUseSite] set.
            input.inputs.forEach((instruction) {
              if (!instruction.isCodeMotionInvariant()) {
                generateAtUseSite.remove(instruction);
              }
            });
            // Visit the pure input now so that the expected inputs
            // are after the expected inputs of [user].
            input.accept(this);
          }
        } else {
          expectedInputs.add(input);
        }
      }
    }
  }

  void visitInstruction(HInstruction instruction) {
    // A code motion invariant instruction is dealt before visiting it.
    assert(!instruction.isCodeMotionInvariant());
    analyzeInputs(instruction, 0);
  }

  // The codegen might use the input multiple times, so it must not be
  // set generate at use site.
  void visitIs(HIs instruction) {}

  // A bounds check method must not have its first input generated at use site,
  // because it's using it twice.
  void visitBoundsCheck(HBoundsCheck instruction) {
    analyzeInputs(instruction, 1);
  }

  // An identity operation must only have its inputs generated at use site if
  // does not require an expression with multiple uses (because of null /
  // undefined).
  void visitIdentity(HIdentity instruction) {
    if (instruction.singleComparisonOp != null) {
      super.visitIdentity(instruction);
    }
    // Do nothing.
  }

  void visitTypeConversion(HTypeConversion instruction) {
    if (!instruction.isArgumentTypeCheck
        && !instruction.isReceiverTypeCheck) {
      assert(instruction.isCheckedModeCheck || instruction.isCastTypeCheck);
      // Checked mode checks and cast checks compile to code that
      // only use their input once, so we can safely visit them
      // and try to merge the input.
      visitInstruction(instruction);
    }
  }

  void visitTypeKnown(HTypeKnown instruction) {
    // [HTypeKnown] instructions are removed before code generation.
    assert(false);
  }

  void tryGenerateAtUseSite(HInstruction instruction) {
    if (instruction.isControlFlow()) return;
    markAsGenerateAtUseSite(instruction);
  }

  bool isBlockSinglePredecessor(HBasicBlock block) {
    return block.successors.length == 1
        && block.successors[0].predecessors.length == 1;
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
    if (expectedInputs == null) expectedInputs = new List<HInstruction>();
    if (pureInputs == null) pureInputs = new Set<HInstruction>();

    // Pop instructions from expectedInputs until instruction is found.
    // Return true if it is found, or false if not.
    bool findInInputsAndPopNonMatching(HInstruction instruction) {
      assert(!instruction.isPure());
      while (!expectedInputs.isEmpty) {
        HInstruction nextInput = expectedInputs.removeLast();
        assert(!generateAtUseSite.contains(nextInput));
        assert(nextInput.usedBy.length == 1);
        if (identical(nextInput, instruction)) {
          return true;
        }
      }
      return false;
    }

    block.last.accept(this);
    for (HInstruction instruction = block.last.previous;
         instruction != null;
         instruction = instruction.previous) {
      if (generateAtUseSite.contains(instruction)) {
        continue;
      }
      if (instruction.isCodeMotionInvariant()) {
        markAsGenerateAtUseSite(instruction);
        continue;
      }
      if (instruction.isPure()) {
        if (pureInputs.contains(instruction)) {
          tryGenerateAtUseSite(instruction);
        } else {
          // If the input is not in the [pureInputs] set, it has not
          // been visited or should not be generated at use-site. The most
          // likely reason for the latter, is that the instruction is used
          // in more than one location.
          // We must either clear the expectedInputs, or move the pure
          // instruction's inputs in front of the existing ones.
          // Example:
          //   t1 = foo();  // side-effect.
          //   t2 = bar();  // side-effect.
          //   t3 = pure(t2);    // used more than once.
          //   f(t1, t3);   // expected inputs of 'f': t1.
          //   use(t3);
          //
          // If we don't clear the expected inputs we end up in a situation
          // where pure pushes "t2" on top of "t1" leading to:
          //   t3 = pure(bar());
          //   f(foo(), t3);
          //   use(t3);
          //
          // If we clear the expected-inputs list we have the correct
          // output:
          //   t1 = foo();
          //   t3 = pure(bar());
          //   f(t1, t3);
          //   use(t3);
          //
          // Clearing is, however, not optimal.
          // Example:
          //   t1 = foo();  // t1 is now used by `pure`.
          //   t2 = bar();  // t2 is now used by `f`.
          //   t3 = pure(t1);
          //   f(t2, t3);
          //   use(t3);
          //
          // If we clear the expected-inputs we can't generate-at-use any of
          // the instructions.
          //
          // The optimal solution is to move the inputs of 'pure' in
          // front of the expectedInputs list. This makes sense, since we
          // push expected-inputs from left-to right, and the `pure` function
          // invocation is "more left" (i.e. before) the first argument of `f`.
          // With that approach we end up with:
          //   t3 = pure(foo();
          //   f(bar(), t3);
          //   use(t3);
          //
          int oldLength = expectedInputs.length;
          instruction.accept(this);
          if (oldLength != 0 && oldLength != expectedInputs.length) {
            // Move the pure instruction's inputs to the front.
            List<HInstruction> newInputs = expectedInputs.sublist(oldLength);
            int newCount = newInputs.length;
            expectedInputs.setRange(
                newCount, newCount + oldLength, expectedInputs);
            expectedInputs.setRange(0, newCount, newInputs);
          }
        }
      } else {
        if (findInInputsAndPopNonMatching(instruction)) {
          // The current instruction is the next non-trivial
          // expected input.
          tryGenerateAtUseSite(instruction);
        } else {
          assert(expectedInputs.isEmpty);
        }
        instruction.accept(this);
      }
    }

    if (block.predecessors.length == 1
        && isBlockSinglePredecessor(block.predecessors[0])) {
      assert(block.phis.isEmpty);
      tryMergingExpressions(block.predecessors[0]);
    } else {
      expectedInputs = null;
      pureInputs = null;
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

  void markAsGenerateAtUseSite(HInstruction instruction) {
    assert(!instruction.isJsStatement());
    generateAtUseSite.add(instruction);
  }

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
    if (!identical(instruction.block, block)) return !identical(block.last, block.first);

    // If [instruction] is not the last instruction of the block
    // before the control flow instruction, or the last instruction,
    // then we will have to emit a statement for that last instruction.
    if (instruction != block.last
        && !identical(instruction, block.last.previous)) return true;

    // If one of the instructions in the block until [instruction] is
    // not generated at use site, then we will have to emit a
    // statement for it.
    // TODO(ngeoffray): we could generate a comma separated
    // list of expressions.
    for (HInstruction temp = block.first;
         !identical(temp, instruction);
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
    //
    // and the same for nested nodes:
    //
    //            If
    //          /    \
    //         /      \
    //      1 expr1    \
    //       If         \
    //      /  \         \
    //     /    \         goto
    //  1 expr2            |
    //    goto    goto     |
    //      \     /        |
    //       \   /         |
    //   phi1(expr2, true|false)
    //          \          |
    //           \         |
    //             phi(phi1, true|false)

    if (end == null) return;
    if (end.phis.isEmpty) return;
    if (!identical(end.phis.first, end.phis.last)) return;
    HBasicBlock elseBlock = startIf.elseBlock;

    if (!identical(end.predecessors[1], elseBlock)) return;
    HPhi phi = end.phis.first;
    HInstruction thenInput = phi.inputs[0];
    HInstruction elseInput = phi.inputs[1];
    if (thenInput.isJsStatement() || elseInput.isJsStatement()) return;

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
      if (!identical(otherIf.joinBlock, end)) {
        // This could be a join block that just feeds into our join block.
        HBasicBlock otherJoin = otherIf.joinBlock;
        if (otherJoin.first != otherJoin.last) return;
        if (otherJoin.successors.length != 1) return;
        if (otherJoin.successors[0] != end) return;
        if (otherJoin.phis.isEmpty) return;
        if (!identical(otherJoin.phis.first, otherJoin.phis.last)) return;
        HPhi otherPhi = otherJoin.phis.first;
        if (thenInput != otherPhi) return;
        if (elseInput != otherPhi.inputs[1]) return;
      }
      if (hasAnyStatement(thenBlock, otherIf)) return;
    } else {
      if (!identical(end.predecessors[0], thenBlock)) return;
      if (hasAnyStatement(thenBlock, thenInput)) return;
      assert(thenBlock.successors.length == 1);
    }

    // From now on, we have recognized a control flow operation built from
    // the builder. Mark the if instruction as such.
    controlFlowOperators.add(startIf);

    // Find the next non-HGoto instruction following the phi.
    HInstruction nextInstruction = phi.block.first;
    while (nextInstruction is HGoto) {
      nextInstruction = nextInstruction.block.successors[0].first;
    }

    // If the operation is only used by the first instruction
    // of its block and is safe to be generated at use site, mark it
    // so.
    if (phi.usedBy.length == 1
        && phi.usedBy[0] == nextInstruction
        && isSafeToGenerateAtUseSite(phi.usedBy[0], phi)) {
      markAsGenerateAtUseSite(phi);
    }

    if (identical(elseInput.block, elseBlock)) {
      assert(elseInput.usedBy.length == 1);
      markAsGenerateAtUseSite(elseInput);
    }

    // If [thenInput] is defined in the first predecessor, then it is only used
    // by [phi] and can be generated at use site.
    if (identical(thenInput.block, end.predecessors[0])) {
      assert(thenInput.usedBy.length == 1);
      markAsGenerateAtUseSite(thenInput);
    }
  }
}
