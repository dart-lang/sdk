// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/ir_to_text.dart';
import 'package:native_compiler/back_end/back_end_state.dart';
import 'package:native_compiler/back_end/constraints.dart';
import 'package:native_compiler/back_end/locations.dart';
import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/passes/pass.dart';

/// Validate results of register allocation.
///
/// Uses fixed-point forward data flow analysis.
final class RegisterAllocationChecker extends Pass {
  final BackEndState backEndState;
  final Constraints constraints;

  late final Set<Location> _allLocations = {};

  /// Block preorder number -> incoming state for a block.
  late final List<Map<Location, _Incoming>> _in;

  /// Block preorder number -> outgoing state for a block.
  late final List<Map<Location, _Value>> _out;

  RegisterAllocationChecker(this.backEndState, this.constraints)
    : super('RegisterAllocationChecker');

  @override
  void run() {
    errorContext.annotator = RegisterAllocationPrinter(
      backEndState,
      constraints,
    ).print;

    verifyConstraints();
    computeInOut();
    verifyInstructions();
  }

  /// Checks that register allocation results match
  /// register allocation constraints.
  ///
  /// Also, collect a set of all locations.
  void verifyConstraints() {
    final locs = backEndState.operandLocations;
    for (final block in graph.reversePostorder) {
      currentBlock = block;
      for (final instr in block) {
        currentInstruction = instr;
        final constr = constraints.getConstraints(instr);
        if (constr != null) {
          verifyConstraint(
            instr,
            constr.result,
            locs[OperandId.result(instr.id)]?.physicalLocation,
            'result',
          );
          for (var i = 0, n = constr.inputs.length; i < n; ++i) {
            verifyConstraint(
              instr,
              constr.inputs[i],
              locs[OperandId.input(instr.id, i)]?.physicalLocation,
              'input $i',
            );
          }
          for (var i = 0, n = constr.temps.length; i < n; ++i) {
            verifyConstraint(
              instr,
              constr.temps[i],
              locs[OperandId.temp(instr.id, i)]?.physicalLocation,
              'temp $i',
            );
          }
        }
        if (instr is ParallelMove) {
          for (final move in instr.moves) {
            switch (move) {
              case Move():
                _allLocations.add(move.from.physicalLocation);
                _allLocations.add(move.to.physicalLocation);
              case LoadConstant():
                _allLocations.add(move.to.physicalLocation);
            }
          }
        }
      }
    }
  }

  void verifyConstraint(
    Instruction instr,
    Constraint? con,
    Location? loc,
    String operand,
  ) {
    if (con == null) {
      return;
    }
    if (loc == null) {
      throw 'No location is allocated for $operand of ${IrToText.instruction(instr)} (required $con)';
    }
    _allLocations.add(loc);
    final bool match = switch (con) {
      PhysicalRegister() => con == loc,
      ParameterStackLocation() => con == loc,
      AnyCpuRegister() => loc is Register,
      AnyFpuRegister() => loc is FPRegister,
      AnyLocation() => true,
      _ =>
        throw 'Unexpected constraint $con for $operand of ${IrToText.instruction(instr)}',
    };
    if (!match) {
      throw 'Allocated location $loc for $operand of ${IrToText.instruction(instr)} does not match constraint $con';
    }
  }

  /// Compute input and output states for each block.
  void computeInOut() {
    final locs = backEndState.operandLocations;

    // Fill incoming states with placeholders.
    // Compute initial output states.
    _in = List.generate(graph.preorder.length, (_) => {});
    _out = List.generate(graph.preorder.length, (_) => {});
    for (final block in graph.reversePostorder) {
      currentBlock = block;
      final incoming = _in[block.preorderNumber];
      final out = _out[block.preorderNumber];
      for (final loc in _allLocations) {
        out[loc] = incoming[loc] = _Incoming(block, loc);
      }
      for (final instr in block) {
        currentInstruction = instr;
        if (instr is ParallelMove) {
          _handleParallelMove(instr, out);
        } else {
          final constr = constraints.getConstraints(instr);
          for (var i = 0, n = constr?.temps.length ?? 0; i < n; ++i) {
            final temp = locs[OperandId.temp(instr.id, i)]?.physicalLocation;
            if (temp != null) {
              out[temp] = _Garbage(instr);
            }
          }
          final result = locs[OperandId.result(instr.id)]?.physicalLocation;
          if (result != null) {
            out[result] = _Value.fromDef(instr as Definition);
          }
        }
      }
    }

    // Iterate until reaching fixed point.
    var changed = true;
    while (changed) {
      changed = false;

      for (final block in graph.reversePostorder) {
        currentBlock = block;
        if (_updateInState(block)) {
          changed = true;
        }
        if (_updateOutState(block)) {
          changed = true;
        }
      }
    }
  }

  bool _updateInState(Block block) {
    var updated = false;
    final incoming = _in[block.preorderNumber];
    for (final loc in _allLocations) {
      final box = incoming[loc]!;
      _Value? value;
      for (final pred in block.predecessors) {
        _Value predValue = _out[pred.preorderNumber][loc]!;
        if (predValue is _Incoming) {
          if (predValue.value == null) {
            // Not known yet, ignore.
            continue;
          }
          predValue = predValue.value!;
          assert(predValue is! _Incoming);
        }
        if (predValue is _Garbage) {
          value = predValue;
          break;
        }
        if (value == null) {
          value = predValue;
        } else if (value != predValue) {
          value = _Garbage(block);
        }
      }
      if (box.value != value) {
        box.value = value!;
        updated = true;
      }
    }
    return updated;
  }

  bool _updateOutState(Block block) {
    var updated = false;
    final out = _out[block.preorderNumber];
    for (final loc in _allLocations) {
      final outValue = out[loc]!;
      if (outValue is _Incoming) {
        final inValue = outValue.value;
        if (inValue != null) {
          out[loc] = inValue;
          updated = true;
        }
      }
    }
    return updated;
  }

  void _handleParallelMove(ParallelMove instr, Map<Location, _Value> state) {
    final newOut = <Location, _Value>{};
    for (final move in instr.moves) {
      switch (move) {
        case Move():
          final srcLoc = move.from.physicalLocation;
          final dstLoc = move.to.physicalLocation;
          final srcValue = state[srcLoc];
          if (srcValue != null) {
            if (srcValue is _Garbage) {
              throw 'Instruction ${IrToText.instruction(instr)} reads from ${srcLoc} which contains $srcValue';
            }
            newOut[dstLoc] = srcValue;
          } else {
            throw 'Instruction ${IrToText.instruction(instr)} reads from ${srcLoc} which has no value';
          }
        case LoadConstant():
          newOut[move.to.physicalLocation] = _Const(move.value);
      }
    }
    state.addAll(newOut);
  }

  void verifyInstructions() {
    final locs = backEndState.operandLocations;

    for (final block in graph.reversePostorder) {
      currentBlock = block;
      final incoming = _in[block.preorderNumber];
      final state = {
        for (final loc in _allLocations)
          loc: incoming[loc]!.value ?? _Garbage(block),
      };
      for (final instr in block) {
        currentInstruction = instr;
        if (instr is ParallelMove) {
          _handleParallelMove(instr, state);
        } else {
          final constr = constraints.getConstraints(instr);
          final result = locs[OperandId.result(instr.id)]?.physicalLocation;
          if (instr is Phi) {
            for (var i = 0, n = instr.inputCount; i < n; ++i) {
              verifyInput(
                instr,
                i,
                result!,
                _out[block.predecessors[i].preorderNumber][result],
              );
            }
          } else {
            for (var i = 0, n = instr.inputCount; i < n; ++i) {
              final loc = locs[OperandId.input(instr.id, i)]?.physicalLocation;
              if (loc != null) {
                verifyInput(instr, i, loc, state[loc]);
              }
            }
          }
          for (var i = 0, n = constr?.temps.length ?? 0; i < n; ++i) {
            final temp = locs[OperandId.temp(instr.id, i)]?.physicalLocation;
            if (temp != null) {
              state[temp] = _Garbage(instr);
            }
          }
          if (result != null) {
            state[result] = _Value.fromDef(instr as Definition);
          }
        }
      }
    }
  }

  void verifyInput(Instruction instr, int i, Location loc, _Value? value) {
    final input = _Value.fromDef(instr.inputDefAt(i));
    if (input != value) {
      throw 'Instruction ${IrToText.instruction(instr)} input $i expects $input in $loc, but got $value';
    }
  }
}

/// Abstract value computed in the program.
sealed class _Value {
  _Value();

  factory _Value.fromDef(Definition def) =>
      (def is Constant) ? _Const(def.value) : _Result(def);
}

/// Value representing a result of the [Definition].
final class _Result extends _Value {
  final Definition def;
  _Result(this.def) : assert(def is! Constant);

  @override
  bool operator ==(Object other) => other is _Result && def == other.def;

  @override
  int get hashCode => def.id.hashCode;

  @override
  String toString() => 'value ${IrToText.reference(def)}';
}

/// Value representing a constant.
final class _Const extends _Value {
  final ConstantValue value;
  _Const(this.value);

  @override
  bool operator ==(Object other) => other is _Const && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'constant $value';
}

/// Invalid value, clobbered in the given [Instruction].
final class _Garbage extends _Value {
  final Instruction clobber;
  _Garbage(this.clobber);

  @override
  bool operator ==(Object other) =>
      other is _Garbage && clobber == other.clobber;

  @override
  int get hashCode => clobber.id.hashCode;

  @override
  String toString() => clobber is Block
      ? 'garbage at ${IrToText.reference(clobber)}'
      : 'garbage clobbered by ${IrToText.instruction(clobber)}';
}

/// Incoming value into the block.
final class _Incoming extends _Value {
  final Block block;
  final Location loc;
  _Value? value;

  _Incoming(this.block, this.loc);

  @override
  String toString() => 'incoming $loc at ${IrToText.reference(block)} entry';
}

/// Prints results of the register allocation.
/// Can be used as [IrToText.annotator] or [ErrorContext.annotator].
class RegisterAllocationPrinter {
  final BackEndState backEndState;
  final Constraints constraints;

  RegisterAllocationPrinter(this.backEndState, this.constraints);

  String? print(Instruction instr) {
    final constr = constraints.getConstraints(instr);
    if (constr == null) {
      return '';
    }
    final buf = StringBuffer();
    final locs = backEndState.operandLocations;
    buf.write('  # RA: ');
    final result = locs[OperandId.result(instr.id)]?.physicalLocation;
    if (result != null) {
      buf.write('$result <- ');
    }
    buf.write('(');
    for (var i = 0, n = instr.inputCount; i < n; ++i) {
      if (i != 0) {
        buf.write(', ');
      }
      buf.write(locs[OperandId.input(instr.id, i)]?.physicalLocation ?? '-');
    }
    buf.write(')');
    if (constr.temps.isNotEmpty) {
      buf.write(
        ' temps: ${[for (var i = 0, n = constr.temps.length; i < n; ++i) locs[OperandId.temp(instr.id, i)]?.physicalLocation]}',
      );
    }
    return buf.toString();
  }
}
