// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:cfg/ir/flow_graph.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/passes/pass.dart';
import 'package:cfg/passes/simplification.dart';
import 'package:cfg/utils/misc.dart';

/// Dominator-based value numbering.
///
/// Can be optionally combined with simplification pass.
///
/// The algorithm is described in
/// Briggs, P.; Cooper, Keith D.; Simpson, L. Taylor (1997). "Value Numbering"
/// (https://www.cs.tufts.edu/~nr/cs257/archive/keith-cooper/value-numbering.pdf).
final class ValueNumbering extends Pass {
  final Simplification? simplification;

  ValueNumbering({this.simplification}) : super('ValueNumbering');

  @override
  void initialize(ErrorContext errorContext, FlowGraph graph) {
    super.initialize(errorContext, graph);
    simplification?.initialize(errorContext, graph);
  }

  @override
  void run() {
    final workList = <(Block, ValueNumberingMap)>[];
    workList.add((graph.entryBlock, _createMap()));

    while (workList.isNotEmpty) {
      final (block, map) = workList.removeLast();
      currentBlock = block;

      for (var instr in block) {
        currentInstruction = instr;
        // Apply simplification first.
        // It can return the same instruction, previously seen
        // instruction or a new instruction.
        final simplification = this.simplification;
        if (simplification != null) {
          instr = simplification.simplify(instr);
        }
        if (!instr.isIdempotent) {
          continue;
        }
        final replacement = map[instr];
        if (replacement == null) {
          assert(instr.block == block);
          map[instr] = instr;
        } else if (replacement != instr) {
          assert(replacement.isIdempotent);
          if (instr is Definition) {
            instr.replaceUsesWith(replacement as Definition);
          }
          instr.removeFromGraph();
        }
      }

      for (int i = 0, n = block.dominatedBlocks.length; i < n; ++i) {
        // Reuse map for the last dominated block.
        var newMap = map;
        if (i != n - 1) {
          newMap = _createMap();
          newMap.addAll(map);
        }
        workList.add((block.dominatedBlocks[i], newMap));
      }
    }

    graph.invalidateInstructionNumbering();
  }
}

/// Maps idempotent instructions to their first occurrence.
///
/// Unordered [HashMap] is used as these maps are not iterated
/// (only looked up and copied).
typedef ValueNumberingMap = HashMap<Instruction, Instruction>;

ValueNumberingMap _createMap() => ValueNumberingMap(
  equals: _instructionEquals,
  hashCode: _instructionHashCode,
);

bool _instructionEquals(Instruction a, Instruction b) {
  assert(a.isIdempotent);
  assert(b.isIdempotent);
  if (a.runtimeType != b.runtimeType) {
    return false;
  }
  if (a.inputCount != b.inputCount) {
    return false;
  }
  for (int i = 0, n = a.inputCount; i < n; ++i) {
    if (a.inputDefAt(i) != b.inputDefAt(i)) {
      return false;
    }
  }
  return a.attributesEqual(b);
}

int _instructionHashCode(Instruction instr) {
  assert(instr.isIdempotent);
  var hash = instr.runtimeType.hashCode;
  for (int i = 0, n = instr.inputCount; i < n; ++i) {
    hash = combineHash(hash, instr.inputDefAt(i).id);
  }
  return finalizeHash(hash);
}
