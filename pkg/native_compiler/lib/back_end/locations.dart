// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart' show ConstantValue;
import 'package:cfg/ir/instructions.dart' show MoveOp;

/// A generic operand of a machine instruction.
abstract interface class Operand {}

/// Kind of physical register.
enum RegisterClass {
  /// General-purpose registers.
  cpu,

  /// Floating-point / SIMD registers.
  fpu,
}

/// Register allocation constraint for one input/output/temporary
/// location used by an IR instruction.
abstract interface class Constraint {
  RegisterClass get registerClass;
}

/// Location of an IR instruction input, output or temporary.
abstract interface class Location {
  Location get physicalLocation;
}

abstract base class PhysicalRegister implements Constraint, Location, Operand {
  const PhysicalRegister();
  int get index;

  @override
  Location get physicalLocation => this;
}

/// General-purpose register.
final class Register extends PhysicalRegister {
  final int index;
  final String name;
  const Register(this.index, this.name);

  @override
  RegisterClass get registerClass => RegisterClass.cpu;

  @override
  String toString() => name;
}

const Register invalidReg = Register(-1, 'INVALID');

/// Floating-point register.
final class FPRegister extends PhysicalRegister {
  final int index;
  final String name;
  const FPRegister(this.index, this.name);

  @override
  RegisterClass get registerClass => RegisterClass.fpu;

  @override
  String toString() => name;
}

const FPRegister invalidFPReg = FPRegister(-1, 'INVALID');

/// Base class for all stack locations.
sealed class StackLocation implements Location {
  const StackLocation();

  @override
  Location get physicalLocation => this;
}

/// Spill slot.
final class SpillSlot extends StackLocation {
  /// Index of the spill slot (0, 1, ...).
  final int index;

  const SpillSlot(this.index);

  @override
  String toString() => 'stack[$index]';
}

/// Constraint and location for the parameter passed on the stack.
final class ParameterStackLocation extends StackLocation implements Constraint {
  /// Parameter index (0, 1, ..., function.numberOfParameters-1).
  final int paramIndex;

  @override
  final RegisterClass registerClass;

  const ParameterStackLocation(this.paramIndex, this.registerClass);

  @override
  String toString() => 'param[$paramIndex]';
}

/// Location which can be allocated by register allocator.
final class VirtualLocation implements Location {
  /// Physical location.
  Location? location;

  @override
  Location get physicalLocation => location!;

  @override
  String toString() => 'vloc${location != null ? ':$location' : ''}';
}

extension type const OperandId._(int _raw) {
  static const int instructionIdMask = 0xffffffff;
  static const int operandIdexShift = 32;

  OperandId.result(int instructionId) : _raw = instructionId;
  OperandId.input(int instructionId, int inputIndex)
    : _raw = instructionId | ((inputIndex + 1) << operandIdexShift);
  OperandId.temp(int instructionId, int tempIndex)
    : _raw = instructionId | ((-tempIndex - 1) << operandIdexShift);

  int get instructionId => _raw & instructionIdMask;
  int get operandIndex => _raw >> operandIdexShift;

  bool get isResult => operandIndex == 0;
  bool get isInput => operandIndex > 0;
  bool get isTemp => operandIndex < 0;

  int get inputIndex {
    assert(isInput);
    return operandIndex - 1;
  }

  int get tempIndex {
    assert(isTemp);
    return -operandIndex - 1;
  }
}

/// Locations of instruction inputs, result and
/// temporaries needed to generate code for the instruction.
///
/// TODO: encode locations as int/Uint32List.
class Locations {
  Location? result;
  List<Location?> inputs;
  List<Location?> temps;

  Locations(int numInputs, int numTemps)
    : inputs = List<Location?>.filled(numInputs, null),
      temps = List<Location?>.filled(numTemps, null);

  void setOperandLocation(OperandId operandId, Location loc) {
    if (operandId.isResult) {
      result = loc;
    } else if (operandId.isInput) {
      inputs[operandId.inputIndex] = loc;
    } else {
      temps[operandId.tempIndex] = loc;
    }
  }
}

/// Location->location move, part of ParallelMove instruction.
final class Move extends MoveOp {
  Location from;
  Location to;
  Move(this.from, this.to);

  @override
  String toString() => '$from -> $to';
}

/// Constant->location move, part of ParallelMove instruction.
final class LoadConstant extends MoveOp {
  ConstantValue value;
  Location to;
  LoadConstant(this.value, this.to);

  @override
  String toString() => '$value -> $to';
}
