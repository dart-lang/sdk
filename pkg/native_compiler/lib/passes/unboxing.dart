// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/types.dart';
import 'package:cfg/passes/pass.dart';
import 'package:cfg/utils/bit_vector.dart';

/// Insert boxing and unboxing instructions to make sure
/// IR instructions take expected representation of their inputs.
final class Unboxing extends Pass {
  late final BitVector _unboxedPhis = BitVector(graph.instructions.length);

  Unboxing() : super('Unboxing');

  @override
  void run() {
    _markUnboxedPhis();

    var changed = false;
    for (final block in graph.reversePostorder) {
      currentBlock = block;
      for (final instr in block) {
        currentInstruction = instr;
        for (int i = 0, n = instr.inputCount; i < n; ++i) {
          final input = instr.inputDefAt(i);
          final isDefUnboxed = hasUnboxedResult(input);
          final isInputUnboxed = hasUnboxedInput(instr, i);
          if (isDefUnboxed != isInputUnboxed) {
            _convertInput(instr, i, input, isDefUnboxed);
            changed = true;
          }
        }
      }
    }
    if (changed) {
      graph.invalidateInstructionNumbering();
    }
  }

  /// Returns true if [instr] takes unboxed value as [inputIndex]-th input.
  bool hasUnboxedInput(Instruction instr, int inputIndex) {
    return switch (instr) {
      Phi() => _unboxedPhis[instr.id],
      Comparison() => instr.op.isIntComparison || instr.op.isDoubleComparison,
      CompareAndBranch() =>
        instr.op.isIntComparison || instr.op.isDoubleComparison,
      BinaryIntOp() ||
      UnaryIntOp() ||
      BinaryDoubleOp() ||
      UnaryDoubleOp() ||
      Box() => true,
      StoreField() => false, // TODO: unboxed fields,
      CallInstruction() => false, // TODO: support unboxed parameters.
      Return() => false, // TODO: support unboxed return values.
      _ => false,
    };
  }

  /// Returns true if result of [instr] is an unboxed value.
  bool hasUnboxedResult(Definition instr) {
    return switch (instr) {
      Phi() => _unboxedPhis[instr.id],
      BinaryIntOp() ||
      UnaryIntOp() ||
      BinaryDoubleOp() ||
      UnaryDoubleOp() ||
      Unbox() => true,
      LoadField() => false, // TODO: unboxed fields,
      Parameter() => false, // TODO: support unboxed parameters.
      CallInstruction() => false, // TODO: support unboxed return values.
      _ => false,
    };
  }

  /// Select representation for phis which can be unboxed.
  /// Phi is marked as unboxed if it takes at least one unboxed input.
  void _markUnboxedPhis() {
    for (final block in graph.reversePostorder) {
      if (block is! JoinBlock) {
        continue;
      }
      currentBlock = block;
      for (final phi in block.phis) {
        currentInstruction = phi;
        if (!_canBeUnboxed(phi)) {
          continue;
        }
        if (_findUnboxedInput(phi)) {
          _unboxedPhis[phi.id] = true;
        }
      }
    }
  }

  bool _canBeUnboxed(Phi instr) {
    final type = instr.type;
    return type is IntType || type is DoubleType;
  }

  /// Find at least one unboxed input while transitively traversing phis.
  bool _findUnboxedInput(Phi instr) {
    final visited = {instr};
    final workList = [instr];
    while (workList.isNotEmpty) {
      instr = workList.removeLast();
      for (int i = 0, n = instr.inputCount; i < n; ++i) {
        final input = instr.inputDefAt(i);
        if (input == instr) {
          continue;
        }
        if (hasUnboxedResult(input)) {
          return true;
        }
        if (input is Phi && _canBeUnboxed(input)) {
          if (visited.add(input)) {
            workList.add(input);
          }
        }
      }
    }
    return false;
  }

  void _convertInput(
    Instruction instr,
    int inputIndex,
    Definition def,
    bool isDefUnboxed,
  ) {
    final type = def.type;
    Definition replacement;
    if (def is Constant) {
      assert(!isDefUnboxed);
      replacement = graph.getConstant(
        ConstantValue(switch (type) {
          IntType() => UnboxedIntConstant(def.value.intValue),
          DoubleType() => UnboxedDoubleConstant(def.value.doubleValue),
          _ => throw 'Unexpected unboxed type $type',
        }),
      );
    } else {
      final insertionPoint = (instr is Phi)
          ? instr.block!.predecessors[inputIndex].lastInstruction
          : instr;
      replacement = isDefUnboxed
          ? switch (type) {
              IntType() => BoxInt(graph, insertionPoint.sourcePosition, def),
              DoubleType() => BoxDouble(
                graph,
                insertionPoint.sourcePosition,
                def,
              ),
              _ => throw 'Unexpected unboxed type $type',
            }
          : switch (type) {
              IntType() => UnboxInt(graph, insertionPoint.sourcePosition, def),
              DoubleType() => UnboxDouble(
                graph,
                insertionPoint.sourcePosition,
                def,
              ),
              _ => throw 'Unexpected unboxed type $type',
            };
      replacement.insertBefore(insertionPoint);
    }
    instr.replaceInputAt(inputIndex, replacement);
  }
}
