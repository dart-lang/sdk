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

    _asm.ldr(
      R4,
      _asm.fieldAddress(objectReg, vmOffsets.Object_hash_offset),
      .u32,
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

  /// Generate code for dart:core::_OneByteString.hashCode.
  @override
  bool generateOneByteStringHashCode() {
    final notYetComputed = Label();
    final loop = Label();
    final done = Label();
    final stringReg = R0;
    final lengthReg = R1;
    final dataReg = R2;
    final endReg = R3;
    final hashReg = R4;
    final charReg = R5;
    _asm.ldr(stringReg, _asm.address(stackPointerReg, 0));

    _asm.ldr(
      hashReg,
      _asm.fieldAddress(stringReg, vmOffsets.Object_hash_offset),
      .u32,
    );
    _asm.cbz(hashReg, notYetComputed);
    _asm.smiTag(returnReg, hashReg);
    _asm.ret();

    _asm.bind(notYetComputed);
    _asm.ldr(
      lengthReg,
      _asm.fieldAddress(stringReg, vmOffsets.String_length_offset),
    );
    _asm.cbz(lengthReg, done);

    _asm.addImmediate(
      dataReg,
      stringReg,
      vmOffsets.OneByteString_data_offset - heapObjectTag,
    );
    _asm.add(endReg, dataReg, ShiftedRegOperand(lengthReg, .LSR, smiShift));

    _asm.bind(loop);
    _asm.ldr(charReg, RegOffsetAddress(dataReg, 0), .u8);
    _asm.add(dataReg, dataReg, Immediate(1));
    _asm.combineHashes(hashReg, charReg);
    _asm.cmp(dataReg, endReg);
    _asm.branchIf(Condition.notEqual, loop);

    _asm.bind(done);
    _asm.finalizeHash(vmOffsets.Object_kHashBits, hashReg);

    _asm.sub(stringReg, stringReg, Immediate(heapObjectTag));
    _asm.lsl(hashReg, hashReg, vmOffsets.UntaggedObject_kHashTagPos);

    final retry = Label();
    _asm.bind(retry);
    _asm.ldxr(R2, stringReg);
    _asm.orr(R2, R2, hashReg);
    _asm.stxr(R3, R2, stringReg);
    _asm.cbnz(R3, retry);

    _asm.lsr(hashReg, hashReg, vmOffsets.UntaggedObject_kHashTagPos);
    _asm.smiTag(returnReg, hashReg);
    _asm.ret();
    return true;
  }

  /// Generate code for dart:core::Object.runtimeType.
  @override
  bool generateObjectRuntimeType() {
    final fallback = Label();
    final useDeclarationType = Label();
    final notDouble = Label();
    final notInteger = Label();
    final notString = Label();

    _asm.ldr(R0, _asm.address(stackPointerReg, 0));
    _asm.loadClassIdMayBeSmi(R1, R0);

    _asm.cmpImmediate(R1, ClassId.ClosureCid.index);
    _asm.b(fallback, .equal); // Instance is a closure.

    _asm.cmpImmediate(R1, ClassId.RecordCid.index);
    _asm.b(fallback, .equal); // Instance is a record.

    _asm.cmpImmediate(R1, ClassId.values.length);
    _asm.b(useDeclarationType, .unsignedGreater);

    _asm.loadIsolateGroup(R2);
    _asm.ldr(R2, _asm.address(R2, vmOffsets.IsolateGroup_object_store_offset));

    _asm.cmpImmediate(R1, ClassId.DoubleCid.index);
    _asm.b(notDouble, .notEqual);
    _asm.ldr(
      returnReg,
      _asm.address(R2, vmOffsets.ObjectStore_double_type_offset),
    );
    _asm.ret();

    _asm.bind(notDouble);
    assert(ClassId.MintCid.index == ClassId.SmiCid.index + 1);
    _asm.subImmediate(R3, R1, ClassId.SmiCid.index);
    _asm.cmpImmediate(R3, 1);
    _asm.b(notInteger, .unsignedGreater);
    _asm.ldr(
      returnReg,
      _asm.address(R2, vmOffsets.ObjectStore_int_type_offset),
    );
    _asm.ret();

    _asm.bind(notInteger);
    assert(
      ClassId.TwoByteStringCid.index == ClassId.OneByteStringCid.index + 1,
    );
    _asm.subImmediate(R3, R1, ClassId.OneByteStringCid.index);
    _asm.cmpImmediate(R3, 1);
    _asm.b(notString, .unsignedGreater);
    _asm.ldr(
      returnReg,
      _asm.address(R2, vmOffsets.ObjectStore_string_type_offset),
    );
    _asm.ret();

    _asm.bind(notString);
    assert(ClassId.FunctionTypeCid.index == ClassId.TypeCid.index + 1);
    assert(ClassId.RecordTypeCid.index == ClassId.TypeCid.index + 2);
    _asm.subImmediate(R3, R1, ClassId.TypeCid.index);
    _asm.cmpImmediate(R3, 2);
    _asm.b(useDeclarationType, .unsignedGreater);
    _asm.ldr(
      returnReg,
      _asm.address(R2, vmOffsets.ObjectStore_type_type_offset),
    );
    _asm.ret();

    _asm.bind(useDeclarationType);
    _asm.loadClassById(R2, R1);
    _asm.ldr(
      R3,
      _asm.fieldAddress(R2, vmOffsets.Class_num_type_arguments_offset),
      .u16,
    );
    _asm.cbnz(R3, fallback);

    _asm.ldr(
      returnReg,
      _asm.fieldAddress(R2, vmOffsets.Class_declaration_type_offset),
    );
    _asm.cmp(returnReg, nullReg);
    _asm.b(fallback, .equal);
    _asm.ret();

    _asm.bind(fallback);
    // Generate native method body.
    return false;
  }
}
