// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/types.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:native_compiler/back_end/arm64/assembler.dart';
import 'package:native_compiler/back_end/arm64/stub_code_generator.dart';
import 'package:native_compiler/back_end/constraints.dart';
import 'package:native_compiler/back_end/locations.dart';
import 'package:native_compiler/back_end/safepoint.dart';
import 'package:native_compiler/back_end/stack_frame.dart';
import 'package:native_compiler/runtime/type_utils.dart';

/// Defines arm64 register allocation contraints for
/// inputs/outputs/temporaries of the IR instructions.
final class Arm64Constraints extends Constraints {
  // TODO: enable returning unboxed FP values on FP register.
  static const bool returnFPValuesOnFPRegister = false;

  final StackFrame stackFrame;

  late final allRegisters = <Constraint>[
    ...getAllocatableRegisters(),
    ...getAllocatableFPRegisters(),
  ];
  // TODO:add callee-save registers
  late final volatileRegisters = allRegisters;

  late final volatileRegistersExceptReturnReg = volatileRegistersExcept(
    returnReg,
  );
  late final volatileRegistersExceptFPReturnReg = volatileRegistersExcept(
    returnFPReg,
  );

  List<Constraint?>? _parameters;

  Arm64Constraints(this.stackFrame);

  @override
  int getNumberOfRegisters() => numberOfRegisters;

  @override
  List<Register> getAllocatableRegisters() => allocatableRegisters;

  @override
  int getNumberOfFPRegisters() => numberOfFPRegisters;

  @override
  List<FPRegister> getAllocatableFPRegisters() => allocatableFPRegisters;

  List<Constraint> volatileRegistersExcept(PhysicalRegister reg) => [
    for (final r in volatileRegisters)
      if (r != reg) r,
  ];

  List<Constraint> allRegistersExcept(
    Constraint? result,
    List<Constraint?> inputs,
  ) => [
    for (final r in allRegisters)
      if (r != result && !inputs.contains(r)) r,
  ];

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
      Safepoint(),
    );
  }

  // TODO: pass arguments on registers
  Constraint parameterConstraint(Parameter instr) {
    final paramIndex = instr.variable.index;
    final function = instr.graph.function;
    final numParams = function.numberOfParameters;
    assert(0 <= paramIndex && paramIndex < numParams);
    Constraint? paramConstraint = _parameters?[paramIndex];
    if (paramConstraint != null) {
      return paramConstraint;
    }
    if (function.hasOptionalPositionalParameters ||
        function.hasNamedParameters) {
      if (paramIndex < argumentRegisters.length) {
        paramConstraint = argumentRegisters[paramIndex];
      } else {
        paramConstraint = stackFrame.getParameterSlot(
          paramIndex,
          registerClass(instr),
        );
      }
    } else {
      paramConstraint = stackFrame.getParameterSlot(
        paramIndex,
        registerClass(instr),
      );
    }
    final parameters = (_parameters ??= List<Constraint?>.filled(
      numParams,
      null,
    ));
    parameters[paramIndex] = paramConstraint;
    return paramConstraint;
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
            ? [anyFpuRegister, anyFpuRegisterOrZero(instr.right)]
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
  InstructionConstraints? visitParameter(Parameter instr) {
    Constraint result;
    if (instr.isFunctionParameter) {
      result = parameterConstraint(instr);
    } else {
      final variable = instr.variable;
      if (variable.isExceptionVariable) {
        result = exceptionObjectReg;
      } else if (variable.isStackTraceVariable) {
        result = stackTraceObjectReg;
      } else {
        result = anyLocation(instr);
      }
    }
    return InstructionConstraints(result, const []);
  }

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
      InstructionConstraints(
        null,
        const [anyCpuRegister, anyCpuRegister],
        const [anyCpuRegister, anyCpuRegister],
        Safepoint(), // For write barrier slow path.
      );

  @override
  InstructionConstraints? visitLoadStaticField(LoadStaticField instr) =>
      (instr.checkInitialized && hasNonTrivialInitializer(instr.field.astField))
      ? InstructionConstraints(
          returnReg,
          const [],
          volatileRegistersExceptReturnReg,
          Safepoint(),
        )
      : const InstructionConstraints(anyCpuRegister, [], [
          anyCpuRegister,
          anyCpuRegister,
        ]);

  @override
  InstructionConstraints? visitStoreStaticField(StoreStaticField instr) =>
      const InstructionConstraints(
        null,
        [anyCpuRegister],
        [anyCpuRegister, anyCpuRegister],
      );

  @override
  InstructionConstraints? visitThrow(Throw instr) {
    final inputs = allocatableRegisters.take(instr.inputCount).toList();
    return InstructionConstraints(
      null,
      inputs,
      allRegistersExcept(null, inputs),
      Safepoint(),
    );
  }

  @override
  InstructionConstraints? visitNullCheck(NullCheck instr) =>
      InstructionConstraints(anyCpuRegister, [anyCpuRegister], [], Safepoint());

  @override
  InstructionConstraints? visitTypeCast(TypeCast instr) {
    final callsTypeTestingStub =
        instr.isChecked &&
        switch (instr.testedType) {
          ObjectType() ||
          NullType() ||
          IntType() ||
          DoubleType() ||
          BoolType() ||
          StringType() => false,
          _ => true,
        };
    if (callsTypeTestingStub) {
      final inputs = [
        TypeTestingStub.instanceReg,
        if (instr.inputCount > 1) ...const [
          TypeTestingStub.instantiatorTypeArgumentsReg,
          TypeTestingStub.functionTypeArgumentsReg,
        ],
      ];
      return InstructionConstraints(
        TypeTestingStub.instanceReg,
        inputs,
        // Type testing stub can call runtime without preserving registers.
        // TODO: save registers on slow path
        allRegistersExcept(TypeTestingStub.instanceReg, inputs),
        Safepoint(),
      );
    }
    return InstructionConstraints(
      anyCpuRegister,
      [
        anyCpuRegister,
        if (instr.inputCount > 1) ...[
          anyRegisterOrImmediate(instr.inputDefAt(1)),
          anyRegisterOrImmediate(instr.inputDefAt(2)),
        ],
      ],
      const [],
      Safepoint(),
    );
  }

  @override
  InstructionConstraints? visitTypeTest(TypeTest instr) {
    final callsSubtypeTestCacheStub = switch (instr.testedType) {
      ObjectType() ||
      NullType() ||
      IntType() ||
      DoubleType() ||
      BoolType() ||
      StringType() => false,
      _ => true,
    };
    if (callsSubtypeTestCacheStub) {
      final inputs = [
        TypeTestingStub.instanceReg,
        if (instr.inputCount > 1) ...const [
          TypeTestingStub.instantiatorTypeArgumentsReg,
          TypeTestingStub.functionTypeArgumentsReg,
        ],
      ];
      return InstructionConstraints(
        TypeTestingStub.subtypeTestCacheResultReg,
        inputs,
        // TODO: save registers on slow path
        allRegistersExcept(TypeTestingStub.subtypeTestCacheResultReg, inputs),
        Safepoint(),
      );
    }
    return InstructionConstraints(anyCpuRegister, [
      anyCpuRegister,
      if (instr.inputCount > 1) ...[
        anyRegisterOrImmediate(instr.inputDefAt(1)),
        anyRegisterOrImmediate(instr.inputDefAt(2)),
      ],
    ]);
  }

  @override
  InstructionConstraints? visitTypeArguments(TypeArguments instr) {
    final inputs = const [
      InstantiateTypeArgumentsStub.instantiatorTypeArgumentsReg,
      InstantiateTypeArgumentsStub.functionTypeArgumentsReg,
    ];
    return InstructionConstraints(
      InstantiateTypeArgumentsStub.resultTypeArgumentsReg,
      inputs,
      // TODO: save registers on slow ptah
      allRegistersExcept(
        InstantiateTypeArgumentsStub.resultTypeArgumentsReg,
        inputs,
      ),
      Safepoint(),
    );
  }

  @override
  InstructionConstraints? visitTypeLiteral(TypeLiteral instr) {
    final type = instr.uninstantiatedType;
    final callsRuntime =
        type is! ast.TypeParameterType || type.nullability == .nullable;
    if (callsRuntime) {
      final inputs = const [R1, R2];
      return InstructionConstraints(
        R0,
        inputs,
        allRegistersExcept(R0, inputs),
        Safepoint(),
      );
    }
    return const InstructionConstraints(anyCpuRegister, [
      anyCpuRegister,
      anyCpuRegister,
    ]);
  }

  @override
  InstructionConstraints? visitAllocateObject(AllocateObject instr) {
    final inputs = [
      if (instr.hasTypeArguments) AllocationStub.typeArgumentsReg,
    ];
    return InstructionConstraints(
      AllocationStub.resultReg,
      inputs,
      // TODO: save registers on slow path
      allRegistersExcept(AllocationStub.resultReg, inputs),
      Safepoint(),
    );
  }

  @override
  InstructionConstraints? visitAllocateClosure(AllocateClosure instr) =>
      InstructionConstraints(
        AllocationStub.resultReg,
        [],
        // TODO: save registers on slow path
        allRegistersExcept(AllocationStub.resultReg, []),
        Safepoint(),
      );

  @override
  InstructionConstraints? visitAllocateContext(AllocateContext instr) =>
      InstructionConstraints(
        AllocationStub.resultReg,
        [],
        // TODO: save registers on slow path
        allRegistersExcept(AllocationStub.resultReg, []),
        Safepoint(),
      );

  @override
  InstructionConstraints? visitAllocateList(AllocateList instr) {
    assert(instr.length is Constant);
    return InstructionConstraints(
      AllocationStub.resultReg,
      [null],
      // TODO: save registers on slow path
      allRegistersExcept(AllocationStub.resultReg, []),
      Safepoint(),
    );
  }

  @override
  InstructionConstraints? visitSetListElement(SetListElement instr) =>
      InstructionConstraints(
        null,
        [anyCpuRegister, anyRegisterOrImmediate(instr.index), anyCpuRegister],
        const [anyCpuRegister, anyCpuRegister],
        Safepoint(), // For write barrier.
      );

  @override
  InstructionConstraints? visitAllocateRecord(AllocateRecord instr) =>
      InstructionConstraints(
        AllocationStub.resultReg,
        [],
        // TODO: save registers on slow path
        allRegistersExcept(AllocationStub.resultReg, []),
        Safepoint(),
      );

  @override
  InstructionConstraints? visitBoxInt(BoxInt instr) => InstructionConstraints(
    anyCpuRegister,
    const [anyCpuRegister],
    const [anyCpuRegister, anyCpuRegister, anyCpuRegister],
    Safepoint(),
  );

  @override
  InstructionConstraints? visitBoxDouble(BoxDouble instr) =>
      InstructionConstraints(
        anyCpuRegister,
        const [anyFpuRegister],
        const [anyCpuRegister, anyCpuRegister, anyCpuRegister],
        Safepoint(),
      );

  @override
  InstructionConstraints? visitUnboxInt(UnboxInt instr) =>
      const InstructionConstraints(anyCpuRegister, [anyCpuRegister]);

  @override
  InstructionConstraints? visitUnboxDouble(UnboxDouble instr) =>
      const InstructionConstraints(anyFpuRegister, [anyCpuRegister]);

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

  @override
  InstructionConstraints? visitEnterSuspendableFunction(
    EnterSuspendableFunction instr,
  ) {
    final inputs = [InitSuspendableFunctionStub.typeArgsReg];
    return InstructionConstraints(
      null,
      inputs,
      allRegistersExcept(null, inputs),
      Safepoint(),
    );
  }

  @override
  InstructionConstraints? visitSuspend(Suspend instr) {
    final inputs = [
      SuspendStub.argumentReg,
      if (instr.op == .awaitWithTypeCheck) SuspendStub.typeArgsReg,
    ];
    return InstructionConstraints(
      returnReg,
      inputs,
      allRegistersExcept(returnReg, inputs),
      Safepoint(),
    );
  }
}
