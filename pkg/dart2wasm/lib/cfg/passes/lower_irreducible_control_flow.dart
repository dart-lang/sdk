// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/local_variable.dart';
import 'package:cfg/ir/types.dart';
import 'package:cfg/passes/pass.dart';
import 'package:cfg/utils/bit_vector.dart';

import '../scc.dart';
import '../utils.dart';

/// Lowers irreducible (multi-entry) loops into single-header reducible loops.
///
/// Rather than duplicating code via node splitting (as suggested in the
/// "Beyond Relooper" paper), this pass routes all edges in a multi entry loop
/// via a new block, similar to [0] or [1].
///
/// For each multi-entry loop, all incoming edges of its entries are
/// routed through a new dispatch [JoinBlock] that forwards each incoming edge's
/// live state ([Phi] inputs, or [UndefinedConstant] for other entries' state)
/// and branches on an entry-index [Phi] to the target entry. This leaves us
/// with a single loop header (the new dispatch block) where all loop back edges
/// branch to.
///
/// [0] https://github.com/llvm/llvm-project/blob/main/llvm/lib/Transforms/Utils/FixIrreducible.cpp
/// [1] https://github.com/llvm/llvm-project/blob/main/llvm/lib/Target/WebAssembly/WebAssemblyFixIrreducibleControlFlow.cpp
final class LowerIrreducibleControlFlow extends Pass {
  LowerIrreducibleControlFlow() : super('LowerIrreducibleControlFlow');

  @override
  void run() {
    assert(graph.inSSAForm);
    if (graph.isReducible) return;

    final multiEntryLoops = _collectMultiEntryLoops();
    assert(multiEntryLoops.isNotEmpty);
    for (final loopEntries in multiEntryLoops) {
      _addDispatch(loopEntries);
    }
    graph.discoverBlocks();
    assert(graph.inSSAForm);
    assert(graph.isReducible);
  }

  List<List<JoinBlock>> _collectMultiEntryLoops() {
    final multiEntryLoops = <List<JoinBlock>>[];
    final worklist = <List<Block>>[graph.preorder];
    while (worklist.isNotEmpty) {
      for (final scc in findNonTrivialSccs(worklist.removeLast())) {
        final inScc = BitVector(graph.preorder.length);
        for (final block in scc) {
          inScc.add(block.preorderNumber);
        }
        // We found a loop. Split the loop's blocks into
        //   * `entries`: Blocks that also have predecessors outside the loop
        //   * `innerBlocks`: Blocks that only have predecessors inside the loop
        final entries = <JoinBlock>[];
        final innerBlocks = <Block>[];
        for (final block in scc) {
          if (block.predecessors.any((p) => !inScc[p.preorderNumber])) {
            // Has predecessors both inside and outside the loop (>= 2 total).
            entries.add(block as JoinBlock);
          } else {
            innerBlocks.add(block);
          }
        }
        assert(entries.isNotEmpty);
        if (entries.length > 1) {
          // No loop entry dominates another.
          assert(
            entries.every(
              (e1) => entries.every((e2) => e1 == e2 || !e1.isDominatedBy(e2)),
            ),
          );
          multiEntryLoops.add(entries);
        }
        if (innerBlocks.length > 1) worklist.add(innerBlocks);
      }
    }
    return multiEntryLoops;
  }

  /// Routes all incoming edges of [loopEntries] through a new dispatch header.
  ///
  /// Moving only [loopEntries]'s [Phi]s into `dispatch` preserves SSA dominance
  /// everywhere else without inserting additional [Phi]s:
  /// - Any block outside the loop that dominated a block inside the loop also
  ///   dominates the dispatch block
  /// - Any block inside the loop that dominated a block still dominates it
  ///   after inserting the dispatch block
  void _addDispatch(List<JoinBlock> loopEntries) {
    assert(loopEntries.length > 1);
    final firstEntry = loopEntries.first;
    final pos = firstEntry.sourcePosition;
    final exceptionHandler = firstEntry.exceptionHandler;
    if (!loopEntries.every((e) => e.exceptionHandler == exceptionHandler)) {
      throw StateError(
        'Irreducible loop entries have mismatched exception handlers '
        'in ${graph.function}',
      );
    }

    final dispatch = JoinBlock(graph, pos)..exceptionHandler = exceptionHandler;

    final inputCount = loopEntries.fold(0, (n, e) => n + e.predecessors.length);
    final label = Phi(
      graph,
      pos,
      _declareLabelVariable(),
      inputCount: inputCount,
    );
    int k = 0;
    for (int i = 0; i < loopEntries.length; ++i) {
      final id = graph.getConstant(ConstantValue.fromInt(i));
      for (int j = 0; j < loopEntries[i].predecessors.length; ++j) {
        label.setInputAt(k++, id);
      }
    }
    dispatch.appendInstruction(label);

    _mergeEntryPhis(dispatch, loopEntries, inputCount);

    for (final entry in loopEntries) {
      for (final pred in entry.predecessors) {
        // We maintain edge-split form, so predecessors of joins (like our loop
        // entry blocks) are always `Goto`s and not branches.
        assert(pred.lastInstruction is Goto && pred.successors.single == entry);
        // Make the block that used to jump into the loop instead jump to the
        // new loop header dispatch block.
        pred.successors[0] = dispatch;
        dispatch.predecessors.add(pred);
      }
      // All previous blocks that targeted the loop entry now target the
      // dispatch block, so the loop entry block has no predecessors now.
      entry.predecessors.clear();
    }

    _emitDispatchTree(dispatch, loopEntries, label, 0, loopEntries.length);
  }

  /// Moves the incoming live state of [loopEntries] into [dispatch].
  ///
  /// Conceptually, each incoming edge to [dispatch] passes the live state for
  /// its target entry and [UndefinedConstant] for the live state of all other
  /// entries, and [dispatch] passes that state along to the entry it branches
  /// to.
  ///
  /// Because no loop entry dominates another, their dominated subtrees - and
  /// therefore the live ranges of their [Phi]s at [dispatch] - are disjoint.
  ///
  /// Coalescing [Phi]s from different entries that share a [LocalVariable]
  /// (and thus type) into one [Phi] in [dispatch] is purely an optimization to
  /// avoid emitting separate [Phi]s per entry.
  void _mergeEntryPhis(
    JoinBlock dispatch,
    List<JoinBlock> loopEntries,
    int inputCount,
  ) {
    final phisByVariable = <LocalVariable, List<Phi?>>{};
    for (int i = 0; i < loopEntries.length; ++i) {
      final loopEntry = loopEntries[i];
      for (final phi in loopEntry.phis) {
        final entryPhis = phisByVariable[phi.variable] ??= List.filled(
          loopEntries.length,
          null,
        );
        assert(entryPhis[i] == null);
        entryPhis[i] = phi;
      }
    }

    Constant? undefined;
    for (final MapEntry(:key, :value) in phisByVariable.entries) {
      final merged = Phi(
        graph,
        value.nonNulls.first.sourcePosition,
        key,
        inputCount: inputCount,
      );
      int k = 0;
      for (int i = 0; i < loopEntries.length; ++i) {
        final phi = value[i];
        final predCount = loopEntries[i].predecessors.length;
        for (int j = 0; j < predCount; ++j) {
          merged.setInputAt(
            k++,
            phi != null
                ? phi.inputDefAt(j)
                : (undefined ??= graph.getConstant(
                    ConstantValue(UndefinedConstant()),
                  )),
          );
        }
      }
      assert(k == inputCount);
      dispatch.lastInstruction.appendInstruction(merged);
      for (final phi in value.nonNulls) {
        phi.replaceUsesWith(merged);
        phi.removeFromGraph();
      }
    }
  }

  void _emitDispatchTree(
    Block block,
    List<JoinBlock> loopEntries,
    Phi label,
    int from,
    int toExclusive,
  ) {
    assert(toExclusive - from >= 1);
    assert(block.successors.isEmpty);
    if (toExclusive - from == 1) {
      final entry = loopEntries[from];
      block.lastInstruction.appendInstruction(
        Goto(graph, entry.sourcePosition),
      );
      block.successors.add(entry);
      assert(entry.predecessors.isEmpty);
      entry.predecessors.add(block);
      return;
    }
    final pos = block.sourcePosition;
    final mid = (from + toExclusive) >>> 1;
    final left = TargetBlock(graph, loopEntries[from].sourcePosition)
      ..exceptionHandler = block.exceptionHandler
      ..predecessors.add(block);
    final right = TargetBlock(graph, loopEntries[mid].sourcePosition)
      ..exceptionHandler = block.exceptionHandler
      ..predecessors.add(block);
    final cond = Comparison(
      graph,
      pos,
      ComparisonOpcode.intLess,
      label,
      graph.getConstant(ConstantValue.fromInt(mid)),
    );
    block.lastInstruction.appendInstruction(cond);
    block.lastInstruction.appendInstruction(Branch(graph, pos, cond));
    block.successors
      ..add(left)
      ..add(right);
    _emitDispatchTree(left, loopEntries, label, from, mid);
    _emitDispatchTree(right, loopEntries, label, mid, toExclusive);
  }

  LocalVariable _declareLabelVariable() {
    final variable = LocalVariable(
      '#dispatch',
      null,
      graph.localVariables.length,
      const IntType(),
      false,
    );
    graph.localVariables.add(variable);
    return variable;
  }
}
