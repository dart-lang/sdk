// Copyright (c) 2026 the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:kernel/ast.dart' as ast show Class;
import 'package:native_compiler/back_end/arm64/assembler.dart';
import 'package:native_compiler/back_end/assembler.dart';
import 'package:native_compiler/back_end/locations.dart';
import 'package:native_compiler/back_end/stub_code_generator.dart';
import 'package:native_compiler/runtime/type_utils.dart';
import 'package:native_compiler/runtime/vm_defs.dart';

abstract base class Arm64StubCodeGenerator implements StubCodeGenerator {
  final Arm64Assembler _asm;

  Arm64StubCodeGenerator(VMOffsets vmOffsets)
    : _asm = Arm64Assembler(vmOffsets);

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

  AllocationStub(super.vmOffsets, this.cls);

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
  final Register objectReg;
  final Register valueReg;

  WriteBarrierStub(super.vmOffsets, this.objectReg, this.valueReg);

  @override
  void _generate() {
    enterStubFrame();

    _asm.unimplemented('WriteBarrierStub');

    leaveStubFrame();
    _asm.ret();
  }
}

final class Arm64StubFactory extends StubFactory {
  final VMOffsets vmOffsets;
  Arm64StubFactory(this.vmOffsets, super.consumeGeneratedCode);

  @override
  StubCodeGenerator allocationStubGenerator(ast.Class cls) =>
      AllocationStub(vmOffsets, cls);

  @override
  StubCodeGenerator writeBarrierStubGenerator(
    Register objectReg,
    Register valueReg,
  ) => WriteBarrierStub(vmOffsets, objectReg, valueReg);
}
