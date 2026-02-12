// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:native_compiler/back_end/arm64/assembler.dart';
import 'package:native_compiler/back_end/arm64/stub_code_generator.dart';
import 'package:native_compiler/back_end/constraints.dart';
import 'package:native_compiler/back_end/locations.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/types.dart';

/// Defines arm64 register allocation contraints for
/// inputs/outputs/temporaries of the IR instructions.
final class Arm64Constraints extends Constraints {
  // TODO: enable returning unboxed FP values on FP register.
  static const bool returnFPValuesOnFPRegister = false;

  late final volatileRegisters = <Constraint>[
    ...getAllocatableRegisters(),
    ...getAllocatableFPRegisters(),
  ];

  late final volatileRegistersExceptReturnReg = volatileRegisters
      .where((r) => r != returnReg)
      .toList();
  late final volatileRegistersExceptFPReturnReg = volatileRegisters
      .where((r) => r != returnFPReg)
      .toList();

  List<Constraint?>? _parameters;

  Arm64Constraints();

  @override
  int getNumberOfRegisters() => numberOfRegisters;

  @override
  List<Register> getAllocatableRegisters() => allocatableRegisters;

  @override
  int getNumberOfFPRegisters() => numberOfFPRegisters;

  @override
  List<FPRegister> getAllocatableFPRegisters() => allocatableFPRegisters;

  // TODO: pass arguments on registers
  // TODO: add callee-save registers
  InstructionConstraints callConstraints(CallInstruction instr) {
    final resultReg = (returnFPValuesOnFPRegister && instr.type is DoubleType)
        ? returnFPReg
        : returnReg;
    return InstructionConstraints(
      resultReg,
      List<Constraint?>.generate(
        instr.inputCount,
        (int i) => anyLocationOrImmediate(instr.inputDefAt(i)),
      ),
      (resultReg == returnFPReg)
          ? volatileRegistersExceptFPReturnReg
          : volatileRegistersExceptReturnReg,
    );
  }

  // TODO: pass arguments on registers
  Constraint parameterConstraint(Parameter instr) {
    final paramIndex = instr.variable.index;
    final numParams = instr.graph.function.numberOfParameters;
    assert(0 <= paramIndex && paramIndex < numParams);
    final parameters = (_parameters ??= List<Constraint?>.filled(
      numParams,
      null,
    ));
    return parameters[paramIndex] ??= ParameterStackLocation(
      paramIndex,
      registerClass(instr),
    );
  }

  @override
  InstructionConstraints? visitBranch(Branch instr) =>
      const InstructionConstraints(null, [anyCpuRegister]);

  @override
  InstructionConstraints? visitCompareAndBranch(CompareAndBranch instr) =>
      InstructionConstraints(
        null,
        instr.op.isDoubleComparison
            ? const [anyFpuRegister, anyFpuRegister]
            : [anyCpuRegister, anyRegisterOrImmediate(instr.right)],
      );

  @override
  InstructionConstraints? visitComparison(Comparison instr) =>
      InstructionConstraints(
        anyCpuRegister,
        instr.op.isDoubleComparison
            ? const [anyFpuRegister, anyFpuRegister]
            : [anyCpuRegister, anyRegisterOrImmediate(instr.right)],
      );

  @override
  InstructionConstraints? visitReturn(Return instr) =>
      InstructionConstraints(null, [
        (returnFPValuesOnFPRegister &&
                instr.graph.function.returnType is DoubleType)
            ? returnFPReg
            : returnReg,
      ]);

  @override
  InstructionConstraints? visitDirectCall(DirectCall instr) =>
      callConstraints(instr);

  @override
  InstructionConstraints? visitInterfaceCall(InterfaceCall instr) =>
      callConstraints(instr);

  @override
  InstructionConstraints? visitClosureCall(ClosureCall instr) =>
      callConstraints(instr);

  @override
  InstructionConstraints? visitDynamicCall(DynamicCall instr) =>
      callConstraints(instr);

  @override
  InstructionConstraints? visitParameter(Parameter instr) =>
      InstructionConstraints(
        instr.isFunctionParameter
            ? parameterConstraint(instr)
            : anyLocation(instr),
        const [],
      );

  @override
  InstructionConstraints? visitLoadLocal(LoadLocal instr) =>
      throw 'Unexpected LoadLocal';

  @override
  InstructionConstraints? visitStoreLocal(StoreLocal instr) =>
      throw 'Unexpected StoreLocal';

  @override
  InstructionConstraints? visitLoadInstanceField(LoadInstanceField instr) =>
      const InstructionConstraints(anyCpuRegister, [anyCpuRegister]);

  @override
  InstructionConstraints? visitStoreInstanceField(StoreInstanceField instr) =>
      const InstructionConstraints(
        null,
        [anyCpuRegister, anyCpuRegister],
        [anyCpuRegister, anyCpuRegister],
      );

  @override
  InstructionConstraints? visitLoadStaticField(LoadStaticField instr) =>
      InstructionConstraints(
        instr.field.type is DoubleType ? anyFpuRegister : anyCpuRegister,
        const [],
      );

  @override
  InstructionConstraints? visitStoreStaticField(StoreStaticField instr) =>
      InstructionConstraints(null, [
        instr.field.type is DoubleType ? anyFpuRegister : anyCpuRegister,
      ]);

  @override
  InstructionConstraints? visitThrow(Throw instr) => InstructionConstraints(
    null,
    [anyCpuRegister, if (instr.inputCount == 2) anyCpuRegister],
  );

  @override
  InstructionConstraints? visitNullCheck(NullCheck instr) =>
      const InstructionConstraints(anyCpuRegister, [anyCpuRegister]);

  @override
  InstructionConstraints? visitTypeParameters(TypeParameters instr) =>
      InstructionConstraints(anyCpuRegister, [
        if (instr.inputCount == 1) anyCpuRegister,
      ]);

  @override
  InstructionConstraints? visitTypeCast(TypeCast instr) =>
      InstructionConstraints(anyCpuRegister, [
        anyCpuRegister,
        if (instr.inputCount == 2) anyCpuRegister,
      ]);

  @override
  InstructionConstraints? visitTypeTest(TypeTest instr) =>
      InstructionConstraints(anyCpuRegister, [
        anyCpuRegister,
        if (instr.inputCount == 2) anyCpuRegister,
      ]);

  @override
  InstructionConstraints? visitTypeArguments(TypeArguments instr) =>
      const InstructionConstraints(anyCpuRegister, [anyCpuRegister]);

  @override
  InstructionConstraints? visitTypeLiteral(TypeLiteral instr) =>
      const InstructionConstraints(anyCpuRegister, [anyCpuRegister]);

  @override
  InstructionConstraints? visitAllocateObject(AllocateObject instr) =>
      InstructionConstraints(
        AllocationStub.resultReg,
        [if (instr.hasTypeArguments) AllocationStub.typeArgumentsReg],
        [
          if (!instr.hasTypeArguments) AllocationStub.typeArgumentsReg,
          AllocationStub.tagsReg,
          AllocationStub.scratch1Reg,
          AllocationStub.scratch2Reg,
        ],
      );

  @override
  InstructionConstraints? visitAllocateClosure(AllocateClosure instr) =>
      InstructionConstraints(
        anyCpuRegister,
        List.generate(
          instr.inputCount,
          (int i) => anyLocationOrImmediate(instr.inputDefAt(i)),
        ),
      );

  @override
  InstructionConstraints? visitAllocateList(AllocateList instr) =>
      const InstructionConstraints(anyCpuRegister, [anyCpuRegister]);

  @override
  InstructionConstraints? visitSetListElement(SetListElement instr) =>
      const InstructionConstraints(null, [
        anyCpuRegister,
        anyCpuRegister,
        anyCpuRegister,
      ]);

  @override
  InstructionConstraints? visitBinaryIntOp(BinaryIntOp instr) =>
      InstructionConstraints(anyCpuRegister, [
        anyCpuRegister,
        anyRegisterOrImmediate(instr.right),
      ]);

  @override
  InstructionConstraints? visitUnaryIntOp(UnaryIntOp instr) =>
      switch (instr.op) {
        UnaryIntOpcode.toDouble => const InstructionConstraints(
          anyFpuRegister,
          [anyCpuRegister],
        ),
        _ => const InstructionConstraints(anyCpuRegister, [anyCpuRegister]),
      };

  @override
  InstructionConstraints? visitBinaryDoubleOp(BinaryDoubleOp instr) =>
      switch (instr.op) {
        BinaryDoubleOpcode.truncatingDiv => const InstructionConstraints(
          anyCpuRegister,
          [anyFpuRegister, anyFpuRegister],
        ),
        _ => const InstructionConstraints(anyFpuRegister, [
          anyFpuRegister,
          anyFpuRegister,
        ]),
      };

  @override
  InstructionConstraints? visitUnaryDoubleOp(UnaryDoubleOp instr) =>
      switch (instr.op) {
        UnaryDoubleOpcode.round ||
        UnaryDoubleOpcode.floor ||
        UnaryDoubleOpcode.ceil ||
        UnaryDoubleOpcode.truncate => const InstructionConstraints(
          anyCpuRegister,
          [anyFpuRegister],
        ),
        _ => const InstructionConstraints(anyFpuRegister, [anyFpuRegister]),
      };

  @override
  InstructionConstraints? visitUnaryBoolOp(UnaryBoolOp instr) =>
      const InstructionConstraints(anyCpuRegister, [anyCpuRegister]);
}
