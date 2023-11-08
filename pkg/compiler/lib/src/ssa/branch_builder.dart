// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../inferrer/abstract_value_domain.dart';
import '../io/source_information.dart';

import 'builder.dart';
import 'locals_handler.dart';
import 'nodes.dart';

class SsaBranch {
  final SsaBranchBuilder branchBuilder;
  final HBasicBlock block;
  LocalsHandler? startLocals;
  LocalsHandler? exitLocals;
  SubGraph? graph;

  SsaBranch(this.branchBuilder) : block = HBasicBlock();
}

class SsaBranchBuilder {
  final KernelSsaGraphBuilder builder;
  final Spannable? diagnosticNode;

  SsaBranchBuilder(this.builder, [this.diagnosticNode]);

  AbstractValueDomain get _abstractValueDomain =>
      builder.closedWorld.abstractValueDomain;

  void checkNotAborted() {
    if (builder.isAborted()) {
      failedAt(diagnosticNode!, "aborted control flow");
    }
  }

  void buildCondition(
      void visitCondition(),
      SsaBranch conditionBranch,
      SsaBranch thenBranch,
      SsaBranch elseBranch,
      SourceInformation? sourceInformation) {
    startBranch(conditionBranch);
    visitCondition();
    checkNotAborted();
    assert(identical(builder.current, builder.lastOpenedBlock));
    HInstruction conditionValue = builder.popBoolified();
    HIf branch = HIf(conditionValue)..sourceInformation = sourceInformation;
    HBasicBlock conditionExitBlock = builder.current!;
    builder.close(branch);
    conditionBranch.exitLocals = builder.localsHandler;
    conditionExitBlock.addSuccessor(thenBranch.block);
    conditionExitBlock.addSuccessor(elseBranch.block);
    bool conditionBranchLocalsCanBeReused =
        mergeLocals(conditionBranch, thenBranch, mayReuseFromLocals: true);
    mergeLocals(conditionBranch, elseBranch,
        mayReuseFromLocals: conditionBranchLocalsCanBeReused);

    conditionBranch.graph =
        SubExpression(conditionBranch.block, conditionExitBlock);
  }

  /// Returns true if the locals of the [fromBranch] may be reused. A [:true:]
  /// return value implies that [mayReuseFromLocals] was set to [:true:].
  bool mergeLocals(SsaBranch fromBranch, SsaBranch toBranch,
      {required bool mayReuseFromLocals}) {
    LocalsHandler fromLocals = fromBranch.exitLocals!;
    if (toBranch.startLocals == null) {
      if (mayReuseFromLocals) {
        toBranch.startLocals = fromLocals;
        return false;
      } else {
        toBranch.startLocals = LocalsHandler.from(fromLocals);
        return true;
      }
    } else {
      toBranch.startLocals!.mergeWith(fromLocals, toBranch.block);
      return true;
    }
  }

  void startBranch(SsaBranch branch) {
    builder.graph.addBlock(branch.block);
    builder.localsHandler = branch.startLocals!;
    builder.open(branch.block);
  }

  HInstruction? buildBranch(SsaBranch branch, void visitBranch(),
      SsaBranch joinBranch, bool isExpression) {
    startBranch(branch);
    visitBranch();
    branch.graph = SubGraph(branch.block, builder.lastOpenedBlock);
    branch.exitLocals = builder.localsHandler;
    if (!builder.isAborted()) {
      builder.goto(builder.current!, joinBranch.block);
      mergeLocals(branch, joinBranch, mayReuseFromLocals: true);
    }
    if (isExpression) {
      checkNotAborted();
      return builder.pop();
    }
    return null;
  }

  handleIf(void visitCondition(), void visitThen(), void visitElse()?,
      {SourceInformation? sourceInformation}) {
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
    _handleDiamondBranch(visitCondition, visitThen, visitElse,
        isExpression: true);
  }

  handleIfNull(void left(), void right()) {
    // x ?? y is transformed into: x == null ? y : x
    late final HInstruction leftExpression;
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
  void handleLogicalBinary(
      void left(), void right(), SourceInformation? sourceInformation,
      {required bool isAnd}) {
    late HInstruction boolifiedLeft;
    late HInstruction boolifiedRight;

    void visitCondition() {
      left();
      boolifiedLeft = builder.popBoolified();
      builder.stack.add(boolifiedLeft);
      if (!isAnd) {
        builder.push(HNot(builder.pop(), _abstractValueDomain.boolType)
          ..sourceInformation = sourceInformation);
      }
    }

    void visitThen() {
      right();
      boolifiedRight = builder.popBoolified();
    }

    handleIf(visitCondition, visitThen, null,
        sourceInformation: sourceInformation);
    HConstant notIsAnd =
        builder.graph.addConstantBool(!isAnd, builder.closedWorld);
    HPhi result = HPhi.manyInputs(
        null, [boolifiedRight, notIsAnd], _abstractValueDomain.dynamicType)
      ..sourceInformation = sourceInformation;
    builder.current!.addPhi(result);
    builder.stack.add(result);
  }

  void _handleDiamondBranch(
      void visitCondition(), void visitThen(), void visitElse(),
      {required bool isExpression, SourceInformation? sourceInformation}) {
    SsaBranch conditionBranch = SsaBranch(this);
    SsaBranch thenBranch = SsaBranch(this);
    SsaBranch elseBranch = SsaBranch(this);
    SsaBranch joinBranch = SsaBranch(this);

    conditionBranch.startLocals = builder.localsHandler;
    builder.goto(builder.current!, conditionBranch.block);

    buildCondition(visitCondition, conditionBranch, thenBranch, elseBranch,
        sourceInformation);
    final thenValue =
        buildBranch(thenBranch, visitThen, joinBranch, isExpression);
    final elseValue =
        buildBranch(elseBranch, visitElse, joinBranch, isExpression);

    if (isExpression) {
      HPhi phi = HPhi.manyInputs(
          null, [thenValue!, elseValue!], _abstractValueDomain.dynamicType);
      joinBranch.block.addPhi(phi);
      builder.stack.add(phi);
    }

    HBasicBlock? joinBlock;
    // If at least one branch did not abort, open the joinBranch.
    if (!joinBranch.block.predecessors.isEmpty) {
      startBranch(joinBranch);
      joinBlock = joinBranch.block;
    }

    HIfBlockInformation info = HIfBlockInformation(
        HSubExpressionBlockInformation(conditionBranch.graph as SubExpression?),
        HSubGraphBlockInformation(thenBranch.graph),
        HSubGraphBlockInformation(elseBranch.graph));

    HBasicBlock conditionStartBlock = conditionBranch.block;
    conditionStartBlock.setBlockFlow(info, joinBlock);
    final conditionGraph = conditionBranch.graph!;
    final branch = conditionGraph.end.last as HIf;
    branch.blockInformation = conditionStartBlock.blockFlow;
  }
}
