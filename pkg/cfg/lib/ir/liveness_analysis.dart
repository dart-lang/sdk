// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/flow_graph.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/utils/bit_vector.dart';

/// Base class for calculation of liveness of abstract variables.
abstract base class LivenessAnalysis {
  final FlowGraph graph;
  final int numVariables;
  final List<BitVector> _liveIn;
  final List<BitVector> _liveOut;
  final List<BitVector> _kill;

  LivenessAnalysis(this.graph, this.numVariables)
    : _liveIn = List.generate(
        graph.preorder.length,
        (_) => BitVector(numVariables),
      ),
      _liveOut = List.generate(
        graph.preorder.length,
        (_) => BitVector(numVariables),
      ),
      _kill = List.generate(
        graph.preorder.length,
        (_) => BitVector(numVariables),
      );

  /// Variables which are live when entering [block],
  /// including variables used by its exception handler.
  BitVector liveIn(Block block) => _liveIn[block.preorderNumber];

  /// Variables which are live when leaving [block],
  /// including leaving through an implicit exceptional control flow.
  BitVector liveOut(Block block) => _liveOut[block.preorderNumber];

  /// Variables which are assigned in [block] before used.
  BitVector kill(Block block) => _kill[block.preorderNumber];

  /// Compute [liveIn], [liveOut] and [kill] for all blocks.
  void analyze() {
    computeInitialSets();
    iterate();
  }

  /// Compute [kill] sets and initial [liveIn] sets which include
  /// variables used in a block before assigned.
  void computeInitialSets();

  /// Compute [liveIn] and [liveOut] sets using [kill] and initial [liveIn].
  void iterate() {
    bool changed;
    do {
      changed = false;
      for (final block in graph.postorder) {
        if (_updateLiveOut(block) || block.exceptionHandler != null) {
          if (_updateLiveIn(block)) {
            changed = true;
          }
        }
      }
    } while (changed);
  }

  /// Update [liveOut] for [block] using the following rule:
  /// liveOut(block) = Union(liveIn(succ) for all successors, liveIn(exceptionHandler)).
  bool _updateLiveOut(Block block) {
    var changed = false;
    final live = liveOut(block);
    for (final succ in block.successors) {
      if (live.addAll(liveIn(succ))) {
        changed = true;
      }
    }
    final exceptionHandler = block.exceptionHandler;
    if (exceptionHandler != null) {
      if (live.addAll(liveIn(exceptionHandler))) {
        changed = true;
      }
    }
    return changed;
  }

  /// Update [liveIn] for [block] using the following rule:
  /// liveIn(block) = Union(liveIn(block), liveOut(block) - kill(block), liveIn(exceptionHandler))
  bool _updateLiveIn(Block block) {
    var changed = false;
    final live = liveIn(block);
    if (live.addSubtraction(liveOut(block), kill(block))) {
      changed = true;
    }
    final exceptionHandler = block.exceptionHandler;
    if (exceptionHandler != null) {
      if (live.addAll(liveIn(exceptionHandler))) {
        changed = true;
      }
    }
    return changed;
  }
}

/// Calculates liveness of local variables
/// before flow graph is converted to SSA form.
final class LocalVariableLivenessAnalysis extends LivenessAnalysis {
  LocalVariableLivenessAnalysis(FlowGraph graph)
    : super(graph, graph.localVariables.length);

  @override
  void computeInitialSets() {
    for (final block in graph.postorder) {
      final kill = this.kill(block);
      final liveIn = this.liveIn(block);

      for (final instr in block.reversed) {
        switch (instr) {
          case LoadLocal():
            liveIn.add(instr.variable.index);

          case StoreLocal():
            final variableIndex = instr.variable.index;
            kill.add(variableIndex);
            liveIn.remove(variableIndex);

          case _:
        }
      }
    }
  }
}

/// Calculates liveness of SSA values.
///
/// Phi instructions are handled specially: their
/// inputs are live-out in the corresponding predecessor,
/// but they are not live-in in the JoinBlock.
final class SSALivenessAnalysis extends LivenessAnalysis {
  SSALivenessAnalysis(FlowGraph graph)
    : super(graph, graph.instructions.length);

  @override
  void computeInitialSets() {
    for (final block in graph.postorder) {
      final kill = this.kill(block);
      final liveIn = this.liveIn(block);
      final liveOut = this.liveOut(block);

      // Inputs of Phis from successor JoinBlock are
      // "used" at the end of the current block.
      if (block.successors.length == 1) {
        final succ = block.successors.single;
        if (succ is JoinBlock) {
          final predIndex = succ.predecessors.indexOf(block);
          assert(predIndex >= 0);
          for (final phi in succ.phis) {
            final inputId = phi.inputDefAt(predIndex).id;
            liveIn.add(inputId);
            liveOut.add(inputId);
          }
        }
      }

      for (final instr in block.reversed) {
        if (instr is Definition) {
          kill.add(instr.id);
          liveIn.remove(instr.id);
        }
        if (instr is! Phi) {
          for (var i = 0, n = instr.inputCount; i < n; ++i) {
            liveIn.add(instr.inputDefAt(i).id);
          }
          // TODO(alexmarkov): also account for implicit uses.
        }
      }
    }
  }
}
