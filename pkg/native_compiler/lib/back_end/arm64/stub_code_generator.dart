// Copyright (c) 2026 the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:kernel/ast.dart' as ast show Class;
import 'package:native_compiler/back_end/arm64/assembler.dart';
import 'package:native_compiler/back_end/assembler.dart';
import 'package:native_compiler/back_end/locations.dart';
import 'package:native_compiler/back_end/stub_code_generator.dart';
import 'package:native_compiler/runtime/object_layout.dart';
import 'package:native_compiler/runtime/type_utils.dart';
import 'package:native_compiler/runtime/vm_defs.dart';

abstract base class Arm64StubCodeGenerator implements StubCodeGenerator {
  final Arm64Assembler _asm;

  Arm64StubCodeGenerator(VMOffsets vmOffsets, ObjectLayout objectLayout)
    : _asm = Arm64Assembler(vmOffsets, null, objectLayout);

  void _generate();

  void enterStubFrame() {
    _asm.enterDartFrame();
  }

  void leaveStubFrame() {
    _asm.leaveDartFrame();
  }

  @override
  Assembler generate() {
    _generate();
    return _asm;
  }
}

final class AllocationStub extends Arm64StubCodeGenerator {
  static const Register resultReg = R0;
  static const Register typeArgumentsReg = R1;
  static const Register tagsReg = R2;

  static const Register scratch1Reg = R3;
  static const Register scratch2Reg = R4;

  final ast.Class cls;

  AllocationStub(super.vmOffsets, super.objectLayout, this.cls);

  @override
  void _generate() {
    enterStubFrame();

    if (cls.typeParameters.isEmpty) {
      final typeArgs = hasInstantiatorTypeArguments(cls)
          ? getInstantiatorTypeArguments(cls, [])
          : null;
      if (typeArgs == null) {
        _asm.mov(typeArgumentsReg, nullReg);
      } else {
        _asm.loadConstant(
          typeArgumentsReg,
          ConstantValue(TypeArgumentsConstant(typeArgs)),
        );
      }
    }

    _generateRuntimeCall();

    leaveStubFrame();
    _asm.ret();
  }

  void _generateRuntimeCall() {
    _asm.loadFromPool(scratch1Reg, cls);

    // Space for result.
    _asm.push(nullReg);
    // Class and type arguments.
    _asm.pushPair(typeArgumentsReg, scratch1Reg);
    _asm.callRuntime(RuntimeEntry.AllocateObject, 2);

    _asm.ldr(resultReg, _asm.address(stackPointerReg, 2 * wordSize));

    // TODO: EnsureIsNewOrRemembered after write barrier elimination is implemented.
  }
}

final class WriteBarrierStub extends Arm64StubCodeGenerator {
  static const Register objectReg = R1;
  static const Register valueReg = R0;
  static const Register slotReg = R25;

  final Register _objectReg;
  final Register _valueReg;

  WriteBarrierStub(
    super.vmOffsets,
    super.objectLayout,
    this._objectReg,
    this._valueReg,
  );

  @override
  void _generate() {
    _asm.push(LR);
    _asm.pushPair(objectReg, valueReg);

    if (_objectReg != objectReg) {
      _asm.mov(objectReg, _objectReg);
    }
    if (_valueReg != valueReg) {
      _asm.mov(valueReg, _valueReg);
    }

    _asm.ldr(
      tempReg,
      _asm.address(
        threadReg,
        _asm.vmOffsets.Thread_write_barrier_entry_point_offset,
      ),
    );
    _asm.blr(tempReg);

    _asm.popPair(objectReg, valueReg);
    _asm.pop(LR);
    _asm.ret();
  }
}

final class TypeTestingStub {
  static const Register instanceReg = R0;
  static const Register dstTypeReg = R8;
  static const Register instantiatorTypeArgumentsReg = R2;
  static const Register functionTypeArgumentsReg = R1;
  static const Register subtypeTestCacheReg = R3;
  static const Register scratchReg = R4;
  static const Register subtypeTestCacheResultReg = R7;
  static const Register entryPointReg = R9;
}

final class InstantiateTypeArgumentsStub {
  static const Register uninstantiatedTypeArgumentsReg = R3;
  static const Register instantiatorTypeArgumentsReg = R2;
  static const Register functionTypeArgumentsReg = R1;
  static const Register resultTypeArgumentsReg = R0;
  static const Register scratchReg = R8;
}

final class InitSuspendableFunctionStub {
  static const Register typeArgsReg = R0;
}

final class SuspendStub {
  static const Register argumentReg = R0;
  static const Register typeArgsReg = R1;
}

final class Arm64StubFactory extends StubFactory {
  final VMOffsets vmOffsets;
  final ObjectLayout objectLayout;
  Arm64StubFactory(
    this.vmOffsets,
    this.objectLayout,
    super.consumeGeneratedCode,
  );

  @override
  StubCodeGenerator allocationStubGenerator(ast.Class cls) =>
      AllocationStub(vmOffsets, objectLayout, cls);

  @override
  StubCodeGenerator writeBarrierStubGenerator(
    Register objectReg,
    Register valueReg,
  ) => WriteBarrierStub(vmOffsets, objectLayout, objectReg, valueReg);
}
