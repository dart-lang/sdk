// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:native_compiler/back_end/locations.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/types.dart';
import 'package:cfg/ir/visitor.dart';

final class AnyCpuRegister implements Constraint {
  const AnyCpuRegister();

  @override
  RegisterClass get registerClass => RegisterClass.cpu;

  @override
  String toString() => 'reg';
}

final class AnyFpuRegister implements Constraint {
  const AnyFpuRegister();

  @override
  RegisterClass get registerClass => RegisterClass.fpu;

  @override
  String toString() => 'fpreg';
}

final class AnyLocation implements Constraint {
  @override
  final RegisterClass registerClass;

  const AnyLocation(this.registerClass);

  @override
  String toString() => 'any';
}

/// Register allocation constraints for locations of instruction inputs,
/// result and temporaries needed to generate code for the instruction.
///
/// TODO: encode constraints as int/Uint32List.
class InstructionConstraints {
  final Constraint? result;
  final List<Constraint?> inputs;
  final List<Constraint> temps;

  const InstructionConstraints(
    this.result,
    this.inputs, [
    this.temps = const [],
  ]);
}

const anyCpuRegister = AnyCpuRegister();
const anyFpuRegister = AnyFpuRegister();
const anyCpuLocation = AnyLocation(RegisterClass.cpu);
const anyFpuLocation = AnyLocation(RegisterClass.fpu);

RegisterClass registerClass(Definition def) => switch (def.type) {
  DoubleType() => RegisterClass.fpu,
  _ => RegisterClass.cpu,
};

Constraint anyRegister(Definition def) => switch (registerClass(def)) {
  RegisterClass.cpu => anyCpuRegister,
  RegisterClass.fpu => anyFpuRegister,
};

Constraint anyLocation(Definition def) => switch (registerClass(def)) {
  RegisterClass.cpu => anyCpuLocation,
  RegisterClass.fpu => anyFpuLocation,
};

Constraint? anyRegisterOrImmediate(Definition def) =>
    def is Constant ? null : anyRegister(def);

Constraint? anyLocationOrImmediate(Definition def) =>
    def is Constant ? null : anyLocation(def);

/// Base class to define register allocation contraints for
/// inputs/outputs/temporaries of the IR instructions.
abstract base class Constraints
    implements InstructionVisitor<InstructionConstraints?> {
  const Constraints();

  int getNumberOfRegisters();
  List<Register> getAllocatableRegisters();

  int getNumberOfFPRegisters();
  List<FPRegister> getAllocatableFPRegisters();

  InstructionConstraints? getConstraints(Instruction instr) =>
      instr.accept(this);

  @override
  InstructionConstraints? visitEntryBlock(EntryBlock instr) => null;

  @override
  InstructionConstraints? visitJoinBlock(JoinBlock instr) => null;

  @override
  InstructionConstraints? visitTargetBlock(TargetBlock instr) => null;

  @override
  InstructionConstraints? visitCatchBlock(CatchBlock instr) => null;

  @override
  InstructionConstraints? visitGoto(Goto instr) => null;

  @override
  InstructionConstraints? visitTryEntry(TryEntry instr) => null;

  @override
  InstructionConstraints? visitConstant(Constant instr) => null;

  @override
  InstructionConstraints? visitPhi(Phi instr) => InstructionConstraints(
    anyLocation(instr),
    List.generate(
      instr.inputCount,
      (int i) => anyLocationOrImmediate(instr.inputDefAt(i)),
    ),
  );

  @override
  InstructionConstraints? visitParallelMove(ParallelMove instr) => null;

  @override
  InstructionConstraints? visitAllocateListLiteral(AllocateListLiteral instr) =>
      throw 'Unexpected AllocateListLiteral (should be lowered)';

  @override
  InstructionConstraints? visitAllocateMapLiteral(AllocateMapLiteral instr) =>
      throw 'Unexpected AllocateMapLiteral (should be lowered)';

  @override
  InstructionConstraints? visitStringInterpolation(StringInterpolation instr) =>
      throw 'Unexpected StringInterpolation (should be lowered)';
}
