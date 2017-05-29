// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../io/source_information.dart';

import 'graph_builder.dart';
import 'locals_handler.dart';
import 'nodes.dart';

class SsaBranch {
  final SsaBranchBuilder branchBuilder;
  final HBasicBlock block;
  LocalsHandler startLocals;
  LocalsHandler exitLocals;
  SubGraph graph;

  SsaBranch(this.branchBuilder) : block = new HBasicBlock();
}

class SsaBranchBuilder {
  final GraphBuilder builder;
  final Spannable diagnosticNode;

  SsaBranchBuilder(this.builder, [this.diagnosticNode]);

  void checkNotAborted() {
    if (builder.isAborted()) {
      throw new SpannableAssertionFailure(
          diagnosticNode, "aborted control flow");
    }
  }

  void buildCondition(
      void visitCondition(),
      SsaBranch conditionBranch,
      SsaBranch thenBranch,
      SsaBranch elseBranch,
      SourceInformation sourceInformation) {
    startBranch(conditionBranch);
    visitCondition();
    checkNotAborted();
    assert(identical(builder.current, builder.lastOpenedBlock));
    HInstruction conditionValue = builder.popBoolified();
    HIf branch = new HIf(conditionValue)..sourceInformation = sourceInformation;
    HBasicBlock conditionExitBlock = builder.current;
    builder.close(branch);
    conditionBranch.exitLocals = builder.localsHandler;
    conditionExitBlock.addSuccessor(thenBranch.block);
    conditionExitBlock.addSuccessor(elseBranch.block);
    bool conditionBranchLocalsCanBeReused =
        mergeLocals(conditionBranch, thenBranch, mayReuseFromLocals: true);
    mergeLocals(conditionBranch, elseBranch,
        mayReuseFromLocals: conditionBranchLocalsCanBeReused);

    conditionBranch.graph =
        new SubExpression(conditionBranch.block, conditionExitBlock);
  }

  /**
   * Returns true if the locals of the [fromBranch] may be reused. A [:true:]
   * return value implies that [mayReuseFromLocals] was set to [:true:].
   */
  bool mergeLocals(SsaBranch fromBranch, SsaBranch toBranch,
      {bool mayReuseFromLocals}) {
    LocalsHandler fromLocals = fromBranch.exitLocals;
    if (toBranch.startLocals == null) {
      if (mayReuseFromLocals) {
        toBranch.startLocals = fromLocals;
        return false;
      } else {
        toBranch.startLocals = new LocalsHandler.from(fromLocals);
        return true;
      }
    } else {
      toBranch.startLocals.mergeWith(fromLocals, toBranch.block);
      return true;
    }
  }

  void startBranch(SsaBranch branch) {
    builder.graph.addBlock(branch.block);
    builder.localsHandler = branch.startLocals;
    builder.open(branch.block);
  }

  HInstruction buildBranch(SsaBranch branch, void visitBranch(),
      SsaBranch joinBranch, bool isExpression) {
    startBranch(branch);
    visitBranch();
    branch.graph = new SubGraph(branch.block, builder.lastOpenedBlock);
    branch.exitLocals = builder.localsHandler;
    if (!builder.isAborted()) {
      builder.goto(builder.current, joinBranch.block);
      mergeLocals(branch, joinBranch, mayReuseFromLocals: true);
    }
    if (isExpression) {
      checkNotAborted();
      return builder.pop();
    }
    return null;
  }

  handleIf(void visitCondition(), void visitThen(), void visitElse(),
      {SourceInformation sourceInformation}) {
    if (visitElse == null) {
      // Make sure to have an else part to avoid a critical edge. A
      // critical edge is an edge that connects a block with multiple
      // successors to a block with multiple predecessors. We avoid
      // such edges because they prevent inserting copies during code
      // generation of phi instructions.
      visitElse = () {};
    }

    _handleDiamondBranch(visitCondition, visitThen, visitElse,
        isExpression: false, sourceInformation: sourceInformation);
  }

  handleConditional(void visitCondition(), void visitThen(), void visitElse()) {
    assert(visitElse != null);
    _handleDiamondBranch(visitCondition, visitThen, visitElse,
        isExpression: true);
  }

  handleIfNull(void left(), void right()) {
    // x ?? y is transformed into: x == null ? y : x
    HInstruction leftExpression;
    handleConditional(() {
      left();
      leftExpression = builder.pop();
      builder.pushCheckNull(leftExpression);
    }, right, () => builder.stack.add(leftExpression));
  }

  /// Creates the graph for '&&' or '||' operators.
  ///
  /// x && y is transformed into:
  ///
  ///     t0 = boolify(x);
  ///     if (t0) {
  ///       t1 = boolify(y);
  ///     }
  ///     result = phi(t1, false);
  ///
  /// x || y is transformed into:
  ///
  ///     t0 = boolify(x);
  ///     if (not(t0)) {
  ///       t1 = boolify(y);
  ///     }
  ///     result = phi(t1, true);
  void handleLogicalBinary(void left(), void right(), {bool isAnd}) {
    HInstruction boolifiedLeft;
    HInstruction boolifiedRight;

    void visitCondition() {
      left();
      boolifiedLeft = builder.popBoolified();
      builder.stack.add(boolifiedLeft);
      if (!isAnd) {
        builder.push(new HNot(builder.pop(), builder.commonMasks.boolType));
      }
    }

    void visitThen() {
      right();
      boolifiedRight = builder.popBoolified();
    }

    handleIf(visitCondition, visitThen, null);
    HConstant notIsAnd =
        builder.graph.addConstantBool(!isAnd, builder.closedWorld);
    HPhi result = new HPhi.manyInputs(
        null,
        <HInstruction>[boolifiedRight, notIsAnd],
        builder.commonMasks.dynamicType);
    builder.current.addPhi(result);
    builder.stack.add(result);
  }

  void _handleDiamondBranch(
      void visitCondition(), void visitThen(), void visitElse(),
      {bool isExpression, SourceInformation sourceInformation}) {
    SsaBranch conditionBranch = new SsaBranch(this);
    SsaBranch thenBranch = new SsaBranch(this);
    SsaBranch elseBranch = new SsaBranch(this);
    SsaBranch joinBranch = new SsaBranch(this);

    conditionBranch.startLocals = builder.localsHandler;
    builder.goto(builder.current, conditionBranch.block);

    buildCondition(visitCondition, conditionBranch, thenBranch, elseBranch,
        sourceInformation);
    HInstruction thenValue =
        buildBranch(thenBranch, visitThen, joinBranch, isExpression);
    HInstruction elseValue =
        buildBranch(elseBranch, visitElse, joinBranch, isExpression);

    if (isExpression) {
      assert(thenValue != null && elseValue != null);
      HPhi phi = new HPhi.manyInputs(null, <HInstruction>[thenValue, elseValue],
          builder.commonMasks.dynamicType);
      joinBranch.block.addPhi(phi);
      builder.stack.add(phi);
    }

    HBasicBlock joinBlock;
    // If at least one branch did not abort, open the joinBranch.
    if (!joinBranch.block.predecessors.isEmpty) {
      startBranch(joinBranch);
      joinBlock = joinBranch.block;
    }

    HIfBlockInformation info = new HIfBlockInformation(
        new HSubExpressionBlockInformation(conditionBranch.graph),
        new HSubGraphBlockInformation(thenBranch.graph),
        new HSubGraphBlockInformation(elseBranch.graph));

    HBasicBlock conditionStartBlock = conditionBranch.block;
    conditionStartBlock.setBlockFlow(info, joinBlock);
    SubGraph conditionGraph = conditionBranch.graph;
    HIf branch = conditionGraph.end.last;
    assert(branch is HIf);
    branch.blockInformation = conditionStartBlock.blockFlow;
  }
}
