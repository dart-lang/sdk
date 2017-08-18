// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart' show CapturedLoopScope;
import '../elements/jumps.dart';
import '../io/source_information.dart';
import '../tree/tree.dart' as ast;

import 'builder.dart';
import 'builder_kernel.dart';
import 'graph_builder.dart';
import 'jump_handler.dart';
import 'locals_handler.dart';
import 'nodes.dart';

/// Builds the SSA graph for loop nodes.
abstract class LoopHandler<T> {
  final GraphBuilder builder;

  LoopHandler(this.builder);

  /// Builds a graph for the given [loop] node.
  ///
  /// For while loops, [initialize] and [update] are null.
  /// The [condition] function must return a boolean result.
  /// None of the functions must leave anything on the stack.
  void handleLoop(
      T loop,
      CapturedLoopScope loopClosureInfo,
      JumpTarget jumpTarget,
      void initialize(),
      HInstruction condition(),
      void update(),
      void body()) {
    // Generate:
    //  <initializer>
    //  loop-entry:
    //    if (!<condition>) goto loop-exit;
    //    <body>
    //    <updates>
    //    goto loop-entry;
    //  loop-exit:

    builder.localsHandler.startLoop(loopClosureInfo);

    // The initializer.
    SubExpression initializerGraph = null;
    HBasicBlock startBlock;
    if (initialize != null) {
      HBasicBlock initializerBlock = builder.openNewBlock();
      startBlock = initializerBlock;
      initialize();
      assert(!builder.isAborted());
      initializerGraph = new SubExpression(initializerBlock, builder.current);
    }

    builder.loopDepth++;
    JumpHandler jumpHandler = beginLoopHeader(loop, jumpTarget);
    HLoopInformation loopInfo = builder.current.loopInformation;
    HBasicBlock conditionBlock = builder.current;
    if (startBlock == null) startBlock = conditionBlock;

    HInstruction conditionInstruction = condition();
    HBasicBlock conditionEndBlock =
        builder.close(new HLoopBranch(conditionInstruction));
    SubExpression conditionExpression =
        new SubExpression(conditionBlock, conditionEndBlock);

    // Save the values of the local variables at the end of the condition
    // block.  These are the values that will flow to the loop exit if the
    // condition fails.
    LocalsHandler savedLocals = new LocalsHandler.from(builder.localsHandler);

    // The body.
    HBasicBlock beginBodyBlock = builder.addNewBlock();
    conditionEndBlock.addSuccessor(beginBodyBlock);
    builder.open(beginBodyBlock);

    builder.localsHandler.enterLoopBody(loopClosureInfo);
    body();

    SubGraph bodyGraph = new SubGraph(beginBodyBlock, builder.lastOpenedBlock);
    HBasicBlock bodyBlock = builder.current;
    if (builder.current != null) builder.close(new HGoto());

    SubExpression updateGraph;

    bool loopIsDegenerate = !jumpHandler.hasAnyContinue() && bodyBlock == null;
    if (!loopIsDegenerate) {
      // Update.
      // We create an update block, even when we are in a while loop. There the
      // update block is the jump-target for continue statements. We could avoid
      // the creation if there is no continue, but for now we always create it.
      HBasicBlock updateBlock = builder.addNewBlock();

      List<LocalsHandler> continueHandlers = <LocalsHandler>[];
      jumpHandler
          .forEachContinue((HContinue instruction, LocalsHandler locals) {
        instruction.block.addSuccessor(updateBlock);
        continueHandlers.add(locals);
      });

      if (bodyBlock != null) {
        continueHandlers.add(builder.localsHandler);
        bodyBlock.addSuccessor(updateBlock);
      }

      builder.open(updateBlock);
      builder.localsHandler =
          continueHandlers[0].mergeMultiple(continueHandlers, updateBlock);

      List<LabelDefinition> labels = jumpHandler.labels;
      if (labels.isNotEmpty) {
        beginBodyBlock.setBlockFlow(
            new HLabeledBlockInformation(
                new HSubGraphBlockInformation(bodyGraph), jumpHandler.labels,
                isContinue: true),
            updateBlock);
      } else if (jumpTarget != null && jumpTarget.isContinueTarget) {
        beginBodyBlock.setBlockFlow(
            new HLabeledBlockInformation.implicit(
                new HSubGraphBlockInformation(bodyGraph), jumpTarget,
                isContinue: true),
            updateBlock);
      }

      builder.localsHandler.enterLoopUpdates(loopClosureInfo);

      update();

      HBasicBlock updateEndBlock = builder.close(new HGoto());
      // The back-edge completing the cycle.
      updateEndBlock.addSuccessor(conditionBlock);
      updateGraph = new SubExpression(updateBlock, updateEndBlock);

      // Avoid a critical edge from the condition to the loop-exit body.
      HBasicBlock conditionExitBlock = builder.addNewBlock();
      builder.open(conditionExitBlock);
      builder.close(new HGoto());
      conditionEndBlock.addSuccessor(conditionExitBlock);

      endLoop(conditionBlock, conditionExitBlock, jumpHandler, savedLocals);

      conditionBlock.postProcessLoopHeader();
      HLoopBlockInformation info = new HLoopBlockInformation(
          loopKind(loop),
          builder.wrapExpressionGraph(initializerGraph),
          builder.wrapExpressionGraph(conditionExpression),
          builder.wrapStatementGraph(bodyGraph),
          builder.wrapExpressionGraph(updateGraph),
          conditionBlock.loopInformation.target,
          conditionBlock.loopInformation.labels,
          loopSourceInformation(loop));

      startBlock.setBlockFlow(info, builder.current);
      loopInfo.loopBlockInformation = info;
    } else {
      // The body of the for/while loop always aborts, so there is no back edge.
      // We turn the code into:
      // if (condition) {
      //   body;
      // } else {
      //   // We always create an empty else block to avoid critical edges.
      // }
      //
      // If there is any break in the body, we attach a synthetic
      // label to the if.
      HBasicBlock elseBlock = builder.addNewBlock();
      builder.open(elseBlock);
      builder.close(new HGoto());
      // Pass the elseBlock as the branchBlock, because that's the block we go
      // to just before leaving the 'loop'.
      endLoop(conditionBlock, elseBlock, jumpHandler, savedLocals);

      SubGraph elseGraph = new SubGraph(elseBlock, elseBlock);
      // Remove the loop information attached to the header.
      conditionBlock.loopInformation = null;

      // Remove the [HLoopBranch] instruction and replace it with
      // [HIf].
      HInstruction condition = conditionEndBlock.last.inputs[0];
      conditionEndBlock.addAtExit(new HIf(condition));
      conditionEndBlock.addSuccessor(elseBlock);
      conditionEndBlock.remove(conditionEndBlock.last);
      HIfBlockInformation info = new HIfBlockInformation(
          builder.wrapExpressionGraph(conditionExpression),
          builder.wrapStatementGraph(bodyGraph),
          builder.wrapStatementGraph(elseGraph));

      conditionEndBlock.setBlockFlow(info, builder.current);
      HIf ifBlock = conditionEndBlock.last;
      ifBlock.blockInformation = conditionEndBlock.blockFlow;

      // If the body has any break, attach a synthesized label to the
      // if block.
      if (jumpHandler.hasAnyBreak()) {
        LabelDefinition label =
            jumpTarget.addLabel(null, 'loop', isBreakTarget: true);
        SubGraph labelGraph = new SubGraph(conditionBlock, builder.current);
        HLabeledBlockInformation labelInfo = new HLabeledBlockInformation(
            new HSubGraphBlockInformation(labelGraph),
            <LabelDefinition>[label]);

        conditionBlock.setBlockFlow(labelInfo, builder.current);

        jumpHandler.forEachBreak((HBreak breakInstruction, _) {
          HBasicBlock block = breakInstruction.block;
          block.addAtExit(new HBreak.toLabel(label));
          block.remove(breakInstruction);
        });
      }
    }
    jumpHandler.close();
    builder.loopDepth--;
  }

  /// Creates a new loop-header block. The previous [current] block
  /// is closed with an [HGoto] and replaced by the newly created block.
  /// Also notifies the locals handler that we're entering a loop.
  JumpHandler beginLoopHeader(T node, JumpTarget jumpTarget) {
    assert(!builder.isAborted());
    HBasicBlock previousBlock = builder.close(new HGoto());

    JumpHandler jumpHandler =
        createJumpHandler(node, jumpTarget, isLoopJump: true);
    HBasicBlock loopEntry = builder.graph
        .addNewLoopHeaderBlock(jumpHandler.target, jumpHandler.labels);
    previousBlock.addSuccessor(loopEntry);
    builder.open(loopEntry);

    builder.localsHandler.beginLoopHeader(loopEntry);
    return jumpHandler;
  }

  /// Ends the loop.
  ///
  /// It does this by:
  /// - creating a new block and adding it as successor to the [branchExitBlock]
  ///   and any blocks that end in break.
  /// - opening the new block (setting as [current]).
  /// - notifying the locals handler that we're exiting a loop.
  ///
  /// [savedLocals] are the locals from the end of the loop condition.
  ///
  /// [branchExitBlock] is the exit (branching) block of the condition.
  /// Generally this is not the top of the loop, since this would lead to
  /// critical edges. It is null for degenerate do-while loops that have no back
  /// edge because they abort (throw/return/break in the body and have no
  /// continues).
  void endLoop(HBasicBlock loopEntry, HBasicBlock branchExitBlock,
      JumpHandler jumpHandler, LocalsHandler savedLocals) {
    HBasicBlock loopExitBlock = builder.addNewBlock();

    List<LocalsHandler> breakHandlers = <LocalsHandler>[];
    // Collect data for the successors and the phis at each break.
    jumpHandler.forEachBreak((HBreak breakInstruction, LocalsHandler locals) {
      breakInstruction.block.addSuccessor(loopExitBlock);
      breakHandlers.add(locals);
    });

    // The exit block is a successor of the loop condition if it is reached.
    // We don't add the successor in the case of a while/for loop that aborts
    // because the caller of endLoop will be wiring up a special empty else
    // block instead.
    if (branchExitBlock != null) {
      branchExitBlock.addSuccessor(loopExitBlock);
    }
    // Update the phis at the loop entry with the current values of locals.
    builder.localsHandler.endLoop(loopEntry);

    // Start generating code for the exit block.
    builder.open(loopExitBlock);

    // Create a new localsHandler for the loopExitBlock with the correct phis.
    if (!breakHandlers.isEmpty) {
      if (branchExitBlock != null) {
        // Add the values of the locals at the end of the condition block to
        // the phis.  These are the values that flow to the exit if the
        // condition fails.
        breakHandlers.add(savedLocals);
      }
      builder.localsHandler =
          savedLocals.mergeMultiple(breakHandlers, loopExitBlock);
    } else {
      builder.localsHandler = savedLocals;
    }
  }

  /// Determine what kind of loop [node] represents.
  ///
  /// The result is one of the kinds defined in [HLoopBlockInformation].
  int loopKind(T node);

  /// Returns the source information for the loop [node].
  SourceInformation loopSourceInformation(T node);

  /// Creates a [JumpHandler] for a statement. The node must be a jump
  /// target. If there are no breaks or continues targeting the statement,
  /// a special "null handler" is returned.
  ///
  /// [isLoopJump] is [:true:] when the jump handler is for a loop. This is used
  /// to distinguish the synthesized loop created for a switch statement with
  /// continue statements from simple switch statements.
  JumpHandler createJumpHandler(T node, JumpTarget jumpTarget,
      {bool isLoopJump});
}

/// A loop handler for the builder that just uses AST nodes directly.
class SsaLoopHandler extends LoopHandler<ast.Node> {
  final SsaAstGraphBuilder builder;

  SsaLoopHandler(SsaAstGraphBuilder builder)
      : this.builder = builder,
        super(builder);

  @override
  int loopKind(ast.Node node) => node.accept(const _SsaLoopTypeVisitor());

  @override
  SourceInformation loopSourceInformation(ast.Node node) =>
      builder.sourceInformationBuilder.buildLoop(node);

  @override
  JumpHandler createJumpHandler(ast.Node node, JumpTarget jumpTarget,
          {bool isLoopJump}) =>
      builder.createJumpHandler(node, jumpTarget, isLoopJump: isLoopJump);
}

class _SsaLoopTypeVisitor extends ast.Visitor {
  const _SsaLoopTypeVisitor();
  int visitNode(ast.Node node) => HLoopBlockInformation.NOT_A_LOOP;
  int visitWhile(ast.While node) => HLoopBlockInformation.WHILE_LOOP;
  int visitFor(ast.For node) => HLoopBlockInformation.FOR_LOOP;
  int visitDoWhile(ast.DoWhile node) => HLoopBlockInformation.DO_WHILE_LOOP;
  int visitAsyncForIn(ast.AsyncForIn node) => HLoopBlockInformation.FOR_IN_LOOP;
  int visitSyncForIn(ast.SyncForIn node) => HLoopBlockInformation.FOR_IN_LOOP;
  int visitSwitchStatement(ast.SwitchStatement node) =>
      HLoopBlockInformation.SWITCH_CONTINUE_LOOP;
}

// TODO(het): Since kernel simplifies loop breaks and continues, we should
// rewrite the loop handler from scratch to account for the simplified structure
class KernelLoopHandler extends LoopHandler<ir.TreeNode> {
  final KernelSsaGraphBuilder builder;

  KernelLoopHandler(KernelSsaGraphBuilder builder)
      : this.builder = builder,
        super(builder);

  @override
  JumpHandler createJumpHandler(ir.TreeNode node, JumpTarget jumpTarget,
          {bool isLoopJump}) =>
      builder.createJumpHandler(node, jumpTarget, isLoopJump: isLoopJump);

  @override
  int loopKind(ir.TreeNode node) => node.accept(new _KernelLoopTypeVisitor());

  // TODO(het): return the actual source information
  @override
  SourceInformation loopSourceInformation(ir.TreeNode node) => null;
}

class _KernelLoopTypeVisitor extends ir.Visitor<int> {
  @override
  int defaultNode(ir.Node node) => HLoopBlockInformation.NOT_A_LOOP;

  @override
  int visitWhileStatement(ir.WhileStatement node) =>
      HLoopBlockInformation.WHILE_LOOP;

  @override
  int visitForStatement(ir.ForStatement node) => HLoopBlockInformation.FOR_LOOP;

  @override
  int visitDoStatement(ir.DoStatement node) =>
      HLoopBlockInformation.DO_WHILE_LOOP;

  @override
  int visitForInStatement(ir.ForInStatement node) =>
      HLoopBlockInformation.FOR_IN_LOOP;

  @override
  int visitSwitchStatement(ir.SwitchStatement node) =>
      HLoopBlockInformation.SWITCH_CONTINUE_LOOP;
}
