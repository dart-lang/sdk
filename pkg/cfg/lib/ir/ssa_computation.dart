// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/dominators.dart';
import 'package:cfg/ir/flow_graph.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/liveness_analysis.dart';
import 'package:cfg/passes/pass.dart';
import 'package:cfg/utils/bit_vector.dart';

/// Converts [FlowGraph] to SSA form.
///
/// Remove [LoadLocal] and [StoreLocal] instructions.
/// Insert [Phi] instructions to [JoinBlock] and
/// [Parameter] instructions to [CatchBlock] in order to resolve data flow.
///
/// Data flow into catch block [Parameter]s is represented by
/// [ExceptionalInput] instructions which are inserted at the beginning
/// of try blocks and at assignments to local variables inside try blocks.
final class SSAComputation extends Pass {
  SSAComputation() : super('SSAComputation');

  @override
  void run() {
    assert(!graph.inSSAForm);

    final dominanceFrontier = computeDominanceFrontier(
      graph,
      includeExceptionHandlers: true,
    );

    final liveness = LocalVariableLivenessAnalysis(graph);
    liveness.analyze();

    insertPhis(liveness, dominanceFrontier);

    rename(liveness);

    graph.invalidateInstructionNumbering();
    graph.inSSAForm = true;
  }

  void insertPhis(
    LocalVariableLivenessAnalysis liveness,
    List<BitVector> dominanceFrontier,
  ) {
    final numBlocks = graph.preorder.length;

    // For each block, the highest variable index that has a phi in that block.
    // Used to avoid inserting multiple phis for the same variable.
    final hasAlready = List<int>.filled(numBlocks, -1);

    // For each block, the highest variable index for which the
    // block went on the worklist. Used to avoid adding the same block to
    //  the worklist more than once for the same variable.
    final work = List<int>.filled(numBlocks, -1);

    // Worklist of blocks to process.
    final workList = <Block>[];

    for (
      var variableIndex = 0;
      variableIndex < graph.localVariables.length;
      ++variableIndex
    ) {
      for (final block in graph.preorder) {
        if (liveness.kill(block)[variableIndex] &&
            liveness.liveOut(block)[variableIndex]) {
          work[block.preorderNumber] = variableIndex;
          workList.add(block);
        }
      }
      while (workList.isNotEmpty) {
        final current = workList.removeLast();
        for (final blockIndex
            in dominanceFrontier[current.preorderNumber].elements) {
          if (hasAlready[blockIndex] < variableIndex) {
            final block = graph.preorder[blockIndex];
            if (liveness.liveIn(block)[variableIndex]) {
              final variable = graph.localVariables[variableIndex];
              switch (block) {
                case JoinBlock():
                  Phi(
                    graph,
                    block.sourcePosition,
                    variable,
                    inputCount: block.predecessors.length,
                  ).insertAfter(block, addInputsToUseLists: false);
                case CatchBlock():
                  Parameter(
                    graph,
                    block.sourcePosition,
                    variable,
                  ).insertAfter(block);
                default:
                  throw 'unexpected block in the dominance frontier: $block';
              }
            }
            hasAlready[blockIndex] = variableIndex;
            if (work[blockIndex] < variableIndex) {
              work[blockIndex] = variableIndex;
              workList.add(block);
            }
          }
        }
      }
    }
  }

  void rename(LocalVariableLivenessAnalysis liveness) {
    final workList = <(Block, List<Definition?>)>[];
    workList.add((
      graph.entryBlock,
      List<Definition?>.filled(graph.localVariables.length, null),
    ));
    while (workList.isNotEmpty) {
      final (block, variableValues) = workList.removeLast();
      for (
        var variableIndex = 0;
        variableIndex < graph.localVariables.length;
        ++variableIndex
      ) {
        if (!liveness.liveIn(block)[variableIndex]) {
          variableValues[variableIndex] = null;
        }
      }
      // Save values of variables incoming into the try block
      // for the exception handler.
      if (_isTryBody(block)) {
        Instruction insertionPoint = block;
        for (final instr in block.exceptionHandler!) {
          if (instr is! Parameter) break;
          if (instr.hasExceptionalInputs) {
            final ei = ExceptionalInput(
              graph,
              block.sourcePosition,
              instr.variable,
              variableValues[instr.variable.index] ??
                  graph.getConstant(ConstantValue(UndefinedConstant())),
            );
            ei.insertAfter(insertionPoint);
            insertionPoint = ei;
          }
        }
      }
      // Computed lazily on the first assignment in the block.
      late final trackedVariables = _computeTrackedVariables(block);
      for (final instr in block) {
        switch (instr) {
          case Parameter():
            variableValues[instr.variable.index] = instr;
          case Phi():
            variableValues[instr.variable.index] = instr;
          case StoreLocal():
            final variableIndex = instr.variable.index;
            variableValues[variableIndex] = instr.value;
            if (trackedVariables != null && trackedVariables[variableIndex]) {
              // Save new value of the variable for the exception handler.
              ExceptionalInput(
                graph,
                instr.sourcePosition,
                instr.variable,
                instr.value,
              ).insertBefore(instr);
            }
            instr.removeFromGraph();
          case LoadLocal():
            instr.replaceUsesWith(
              variableValues[instr.variable.index] ??
                  graph.getConstant(ConstantValue(UndefinedConstant())),
            );
            instr.removeFromGraph();
        }
      }
      // JoinBlock can be the only successor for a block (edge-split form).
      if (block.successors.length == 1) {
        final successor = block.successors.single;
        if (successor is JoinBlock) {
          final predecessorIndex = successor.predecessors.indexOf(block);
          assert(predecessorIndex >= 0);
          for (final phi in successor.phis) {
            phi.setInputAt(
              predecessorIndex,
              variableValues[phi.variable.index] ??
                  graph.getConstant(ConstantValue(UndefinedConstant())),
            );
            phi.addInputToUseList(predecessorIndex);
          }
        }
      }
      final dominated = block.dominatedBlocks;
      if (dominated.isNotEmpty) {
        for (var i = dominated.length - 1; i > 0; --i) {
          workList.add((dominated[i], List<Definition?>.of(variableValues)));
        }
        workList.add((dominated.first, variableValues));
      }
    }
  }

  /// Returns true if [block] is the first block of a try body.
  bool _isTryBody(Block block) {
    if (block is! TargetBlock) return false;
    final last = block.predecessors.single.lastInstruction;
    return last is TryEntry && last.tryBody == block;
  }

  /// Variables with [Parameter]s in the exception handler of [block] or
  /// any of its outer exception handlers.
  BitVector? _computeTrackedVariables(Block block) {
    BitVector? tracked;
    for (
      var handler = block.exceptionHandler;
      handler != null;
      handler = handler.exceptionHandler
    ) {
      for (final instr in handler) {
        if (instr is! Parameter) break;
        if (instr.hasExceptionalInputs) {
          tracked ??= BitVector(graph.localVariables.length);
          tracked.add(instr.variable.index);
        }
      }
    }
    return tracked;
  }
}
