// Copyright (c) 2026 the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:native_compiler/back_end/arm64/assembler.dart';
import 'package:native_compiler/back_end/arm64/stub_code_generator.dart';
import 'package:native_compiler/back_end/asm_intrinsics.dart';
import 'package:native_compiler/back_end/assembler.dart';
import 'package:native_compiler/runtime/vm_defs.dart';

/// Registry of functions implemented in arm64 assembly language.
final class Arm64AsmIntrinsics(
  super.functionRegistry,
  super.vmOffsets,
  super.objectLayout,
) extends AsmIntrinsics {
  Arm64Assembler? _assembler;

  Arm64Assembler get _asm => _assembler!;

  @override
  void setAssembler(Assembler? asm) {
    _assembler = asm as Arm64Assembler?;
  }

  /// Generate code for _SuspendState._resume.
  @override
  bool generateSuspendStateResume() {
    // TODO: replace tail call with actual implementation.
    _asm.ldr(
      codeReg,
      _asm.address(threadReg, vmOffsets.Thread_resume_stub_offset),
    );
    _asm.ldr(
      tempReg,
      _asm.fieldAddress(codeReg, vmOffsets.Code_entry_point_offset.first),
    );
    _asm.br(tempReg);
    return true;
  }

  /// Generate code for _SuspendState._clone.
  @override
  bool generateSuspendStateClone() {
    // TODO: replace tail call with actual implementation.
    _asm.ldr(CloneSuspendStateStub.sourceReg, _asm.address(stackPointerReg, 0));
    _asm.mov(tempReg, poolPointerReg);
    _asm.ldr(
      poolPointerReg,
      _asm.fieldAddress(codeReg, vmOffsets.Code_object_pool_offset),
    );
    _asm.sub(poolPointerReg, poolPointerReg, Immediate(heapObjectTag));
    _asm.loadFromPool(codeReg, StubCode.CloneSuspendState);
    _asm.mov(poolPointerReg, tempReg);
    _asm.ldr(
      tempReg,
      _asm.fieldAddress(codeReg, vmOffsets.Code_entry_point_offset.first),
    );
    _asm.br(tempReg);
    return true;
  }

  /// Generate code for dart:core::_getHash (Object.hashCode / identityHashCode).
  ///
  /// Keep in sync with Instance::IdentityHashCode.
  /// Note int and double never reach here because they override _identityHashCode.
  /// Special cases are also not needed for null or bool because they were pre-set
  /// during VM isolate finalization.
  @override
  bool generateObjectHashCode() {
    final notYetComputed = Label();
    final objectReg = R0;
    _asm.ldr(objectReg, _asm.address(stackPointerReg, 0));

    assert(vmOffsets.UntaggedObject_kHashTagPos % 8 == 0);
    assert(vmOffsets.UntaggedObject_kHashTagPos + 32 == wordSize * 8);
    _asm.ldr(
      R4,
      _asm.fieldAddress(
        objectReg,
        vmOffsets.Object_tags_offset +
            (vmOffsets.UntaggedObject_kHashTagPos ~/ 8),
      ),
      OperandSize.u32,
    );
    _asm.cbz(R4, notYetComputed);
    _asm.smiTag(returnReg, R4);
    _asm.ret();

    _asm.bind(notYetComputed);
    _asm.ldr(R1, _asm.address(threadReg, vmOffsets.Thread_random_offset));
    _asm.andImmediate(R2, R1, 0xffffffff); // state_lo
    _asm.lsr(R3, R1, 32); // state_hi
    _asm.loadImmediate(R1, 0xffffda61); // A
    _asm.mul(R1, R1, R2);
    _asm.add(R1, R1, R3); // new_state = (A * state_lo) + state_hi
    _asm.str(R1, _asm.address(threadReg, vmOffsets.Thread_random_offset));
    _asm.andImmediate(R1, R1, 0x3fffffff);
    _asm.cbz(R1, notYetComputed);

    _asm.sub(objectReg, objectReg, Immediate(heapObjectTag));
    _asm.lsl(R3, R1, vmOffsets.UntaggedObject_kHashTagPos);

    final retry = Label();
    final alreadySet = Label();
    _asm.bind(retry);
    _asm.ldxr(R2, objectReg);
    _asm.lsr(R4, R2, vmOffsets.UntaggedObject_kHashTagPos);
    _asm.cbnz(R4, alreadySet);
    _asm.orr(R2, R2, R3);
    _asm.stxr(R4, R2, objectReg);
    _asm.cbnz(R4, retry);
    // Fall-through with R1 containing new hash value (untagged).
    _asm.smiTag(returnReg, R1);
    _asm.ret();
    _asm.bind(alreadySet);
    _asm.clrex();
    _asm.smiTag(returnReg, R4);
    _asm.ret();
    return true;
  }
}
