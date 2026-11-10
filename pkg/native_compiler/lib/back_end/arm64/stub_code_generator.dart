// Copyright (c) 2026 the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/utils/misc.dart';
import 'package:kernel/ast.dart' as ast show Class;
import 'package:native_compiler/back_end/arm64/assembler.dart';
import 'package:native_compiler/back_end/arm64/stack_frame.dart';
import 'package:native_compiler/back_end/assembler.dart';
import 'package:native_compiler/back_end/code.dart';
import 'package:native_compiler/back_end/code_metadata.dart';
import 'package:native_compiler/back_end/locations.dart';
import 'package:native_compiler/back_end/stub_code_generator.dart';
import 'package:native_compiler/back_end/safepoint.dart';
import 'package:native_compiler/runtime/object_layout.dart';
import 'package:native_compiler/runtime/type_utils.dart';
import 'package:native_compiler/runtime/vm_defs.dart';

abstract base class Arm64StubCodeGenerator implements StubCodeGenerator {
  late final Arm64Assembler _asm;
  int _frameSizeInWords = 0;
  Safepoint? _currentSafepoint;
  CompressedStackMaps? _compressedStackMaps;

  VMOffsets get vmOffsets => _asm.vmOffsets;
  ObjectLayout get objectLayout => _asm.objectLayout;
  int get compressedWordSize => objectLayout.compressedWordSize;

  Arm64StubCodeGenerator(VMOffsets vmOffsets, ObjectLayout objectLayout) {
    _asm = Arm64Assembler(vmOffsets, addCallSiteMetadata, objectLayout);
  }

  void _generate();

  void enterStubFrame() {
    _asm.enterDartFrame();
  }

  void leaveStubFrame() {
    _asm.leaveDartFrame();
  }

  @override
  Code generate(String name) {
    _generate();
    return Code(
      name,
      null,
      _asm.bytes,
      _asm.objectPool,
      null,
      null,
      null,
      null,
      _compressedStackMaps,
    );
  }

  void addCallSiteMetadata(CallSiteKind kind) {
    final safepoint = _currentSafepoint;
    if (safepoint != null) {
      (_compressedStackMaps ??= CompressedStackMaps()).add(
        _asm.currentPcOffset,
        safepoint,
        _frameSizeInWords,
      );
    }
  }

  void createSafepointForRuntimeCall(int numSlots) {
    assert((0 <= numSlots) && (numSlots <= _frameSizeInWords));
    final safepoint = _currentSafepoint = Safepoint();

    /// TODO: pass arguments on registers.
    safepoint.addLiveStackSlots(
      _frameSizeInWords - numSlots,
      numSlots,
      isObjectPointer: true,
    );
  }
}

final class AllocationStub extends Arm64StubCodeGenerator {
  static const Register resultReg = R0;
  static const Register typeArgumentsReg = R1;
  static const Register tagsReg = R2;
  static const Register lengthReg = R5;

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

    // Space for result and padding.
    _asm.pushPair(nullReg, ZR);
    // Class and type arguments.
    _asm.pushPair(typeArgumentsReg, scratch1Reg);

    _frameSizeInWords = 4;
    createSafepointForRuntimeCall(3);
    _asm.callRuntime(RuntimeEntry.AllocateObject, 2);
    _currentSafepoint = null;

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
  final bool isArray;

  WriteBarrierStub(
    super.vmOffsets,
    super.objectLayout,
    this._objectReg,
    this._valueReg,
    this.isArray,
  );

  @override
  void _generate() {
    _asm.push(LR);
    _asm.pushPair(objectReg, valueReg);

    // Parallel move (_objectReg, _valueReg) -> (objectReg, valueReg).
    if (objectReg == _valueReg) {
      if (valueReg == _objectReg) {
        _asm.mov(tempReg, _valueReg);
        _asm.mov(objectReg, _objectReg);
        _asm.mov(valueReg, tempReg);
      } else {
        _asm.mov(valueReg, _valueReg);
        _asm.mov(objectReg, _objectReg);
      }
    } else {
      if (objectReg != _objectReg) {
        _asm.mov(objectReg, _objectReg);
      }
      if (valueReg != _valueReg) {
        _asm.mov(valueReg, _valueReg);
      }
    }

    _asm.ldr(
      tempReg,
      _asm.address(
        threadReg,
        isArray
            ? vmOffsets.Thread_array_write_barrier_entry_point_offset
            : vmOffsets.Thread_write_barrier_entry_point_offset,
      ),
    );
    _asm.blr(tempReg);

    _asm.popPair(objectReg, valueReg);
    _asm.pop(LR);
    _asm.ret();
  }
}

final class DynamicCallStub extends Arm64StubCodeGenerator {
  static const Register receiverReg = R0;

  DynamicCallStub(super.vmOffsets, super.objectLayout);

  @override
  void _generate() {
    final scratchRegs = Set.of(allocatableRegisters).difference(const {
      inlineCacheDataReg,
      argumentsDescriptorReg,
      receiverReg,
      codeReg,
    }).toList();
    final classIdReg = scratchRegs[0];
    final entryReg = scratchRegs[1];

    // TODO: do we need to bump Function::usage_counter for code coverage?
    // TODO: do we need to check for single stepping?
    // TODO: compressed pointers

    _asm.loadClassId(classIdReg, receiverReg, canBeSmi: true, asTagged: true);
    _asm.ldr(
      entryReg,
      _asm.fieldAddress(inlineCacheDataReg, vmOffsets.ICData_entries_offset),
    );

    // Look for matching class ID in ICData.

    final loop = Label();
    final found = Label();

    _asm.bind(loop);
    _asm.ldr(tempReg, _asm.fieldAddress(entryReg, vmOffsets.Array_data_offset));
    _asm.cmp(tempReg, classIdReg);
    _asm.b(found, .equal);

    assert(ClassId.IllegalCid.index == 0);
    _asm.add(
      entryReg,
      entryReg,
      Immediate(vmOffsets.getICDataEntryLength() * compressedWordSize),
    );
    _asm.cbnz(tempReg, loop);

    // ICData entry is not found, call runtime to resolve and cache target function.

    enterStubFrame();

    _frameSizeInWords = 6;
    _asm.subImmediate(
      stackPointerReg,
      stackPointerReg,
      _frameSizeInWords * wordSize,
    );

    // Save ICData and arguments descriptor.
    _asm.stp(
      inlineCacheDataReg,
      argumentsDescriptorReg,
      _asm.address(stackPointerReg, 4 * wordSize),
    );
    _asm.stp(
      nullReg, // Placeholder for the result of the call.
      nullReg, // Space for result (target function).
      _asm.address(stackPointerReg, 2 * wordSize),
    );
    _asm.stp(inlineCacheDataReg, receiverReg, _asm.address(stackPointerReg, 0));

    // Make sure all slots are recorded as pointers in the stackmap.
    createSafepointForRuntimeCall(6);
    _asm.callRuntime(RuntimeEntry.InlineCacheMissHandlerModAOT, 3);
    _currentSafepoint = null;

    // Restore preserved ICData and arguments descriptor.
    _asm.ldp(
      inlineCacheDataReg,
      argumentsDescriptorReg,
      _asm.address(stackPointerReg, 4 * wordSize),
    );
    // Load target function and the result of the call.
    _asm.ldp(tempReg, functionReg, _asm.address(stackPointerReg, 2 * wordSize));

    leaveStubFrame();

    final callFunction = Label();
    _asm.cmp(functionReg, nullReg);
    _asm.b(callFunction, .notEqual);

    _asm.mov(returnReg, tempReg);
    _asm.ret();

    _asm.bind(found);
    _asm.ldr(
      functionReg,
      _asm.fieldAddress(
        entryReg,
        vmOffsets.Array_data_offset +
            vmOffsets.getICDataTargetIndex() * compressedWordSize,
      ),
    );

    _asm.bind(callFunction);
    _asm.ldr(
      codeReg,
      _asm.fieldAddress(functionReg, vmOffsets.Function_code_offset),
    );
    _asm.ldr(
      tempReg,
      _asm.fieldAddress(
        functionReg,
        vmOffsets.Function_entry_point_offset.first,
      ),
    );
    _asm.br(tempReg);
  }
}

final class DynamicInvocationForwarderStub extends Arm64StubCodeGenerator {
  DynamicInvocationForwarderStub(super.vmOffsets, super.objectLayout);

  @override
  void _generate() {
    enterStubFrame();

    _frameSizeInWords = 4;
    _asm.subImmediate(
      stackPointerReg,
      stackPointerReg,
      _frameSizeInWords * wordSize,
    );

    // Space for result (target function).
    _asm.str(nullReg, _asm.address(stackPointerReg, 2 * wordSize));

    _asm.stp(
      argumentsDescriptorReg,
      functionReg,
      _asm.address(stackPointerReg, 0),
    );

    createSafepointForRuntimeCall(3);
    _asm.callRuntime(RuntimeEntry.DynamicInvocationForwarderModAOT, 2);
    _currentSafepoint = null;

    _asm.ldr(argumentsDescriptorReg, _asm.address(stackPointerReg, 0));
    _asm.ldr(functionReg, _asm.address(stackPointerReg, 2 * wordSize));

    leaveStubFrame();

    _asm.ldr(
      codeReg,
      _asm.fieldAddress(functionReg, vmOffsets.Function_code_offset),
    );
    _asm.ldr(
      tempReg,
      _asm.fieldAddress(
        functionReg,
        vmOffsets.Function_entry_point_offset.first,
      ),
    );
    _asm.br(tempReg);
  }
}

/// Called when invoking Dart code from C++ (VM code) or from bytecode.
/// Input parameters:
///   LR : points to return address.
///   R0 : target code.
///   R1 : arguments descriptor array.
///   R2 : arguments array (if [!fromBytecode]) or address of the first argument
///        (if [fromBytecode]).
///   R3 : current thread.
final class InvokeDartCodeStub extends Arm64StubCodeGenerator {
  static const codeParamReg = R0;
  static const argumentsDescriptorParamReg = R1;
  static const argumentsParamReg = R2;
  static const threadParamReg = R3;
  // R4 is reserved for [argumentsDescriptorReg].
  static const scratch1Reg = R5;
  static const scratch2Reg = R6;
  static const argCountReg = R7;
  static const argumentsDestReg = R8;

  /// Fixed size of the entry frame.
  ///
  /// Layout of the entry frame (stack grows down):
  /// ```
  ///        -------------------------------------------------------------+
  ///        [saved LR]                                                   |
  /// FP ->  [saved FP]                                                   |
  ///        -------------------------------------------------------------+
  ///        [Code]                                                       |
  ///        [saved CPU and FPU registers (10 + 8 slots) ]                | Fixed frame
  ///        [saved Thread.vm_tag ]                                       | (entryFrameFixedSize words)
  ///        [saved Thread.top_resource ]                                 |
  ///        [saved Thread.exit_through_ffi ]                             |
  ///        [saved Thread.top_exit_frame_info ]                          |
  ///        -------------------------------------------------------------+
  ///        [zero padding (if needed)]                                   |
  ///        [arguments]                                                  |
  ///        -------------------------------------------------------------+
  ///        (callee frame)
  /// ```
  /// Keep in sync with code of this stub and kExitLinkSlotFromEntryFp VM constant.
  static const int entryFrameFixedSize = 23;

  final bool fromBytecode;

  InvokeDartCodeStub(
    super.vmOffsets,
    super.objectLayout, {
    required this.fromBytecode,
  });

  int _saveAbiCalleeSaveRegisters(int offsetFromFp) {
    assert(abiCalleeSaveRegisters.length.isEven);
    for (var i = 0; i < abiCalleeSaveRegisters.length; i += 2) {
      offsetFromFp += 2;
      _asm.stp(
        abiCalleeSaveRegisters[i + 1],
        abiCalleeSaveRegisters[i],
        RegOffsetAddress(FP, -offsetFromFp * wordSize),
      );
    }
    assert(abiCalleeSaveFPRegisters.length.isEven);
    for (var i = 0; i < abiCalleeSaveFPRegisters.length; i += 2) {
      offsetFromFp += 2;
      _asm.fstp(
        abiCalleeSaveFPRegisters[i + 1],
        abiCalleeSaveFPRegisters[i],
        RegOffsetAddress(FP, -offsetFromFp * wordSize),
      );
    }
    return offsetFromFp;
  }

  int _restoreAbiCalleeSaveRegisters(int offsetFromFp) {
    assert(abiCalleeSaveFPRegisters.length.isEven);
    for (var i = abiCalleeSaveFPRegisters.length - 2; i >= 0; i -= 2) {
      _asm.fldp(
        abiCalleeSaveFPRegisters[i + 1],
        abiCalleeSaveFPRegisters[i],
        RegOffsetAddress(FP, -offsetFromFp * wordSize),
      );
      offsetFromFp -= 2;
    }
    assert(abiCalleeSaveRegisters.length.isEven);
    for (var i = abiCalleeSaveRegisters.length - 2; i >= 0; i -= 2) {
      _asm.ldp(
        abiCalleeSaveRegisters[i + 1],
        abiCalleeSaveRegisters[i],
        RegOffsetAddress(FP, -offsetFromFp * wordSize),
      );
      offsetFromFp -= 2;
    }
    return offsetFromFp;
  }

  /// Refresh pinned registers (write barrier mask, null, etc).
  void _restorePinnedRegisters() {
    if (threadReg != threadParamReg) {
      _asm.mov(threadReg, threadParamReg);
    }
    _asm.ldr(
      heapBitsReg,
      _asm.address(threadReg, vmOffsets.Thread_write_barrier_mask_offset),
    );
    _asm.lsl(heapBitsReg, heapBitsReg, 32);
    _asm.ldr(
      nullReg,
      _asm.address(threadReg, vmOffsets.Thread_object_null_offset),
    );
    // TODO: compressed pointers.
  }

  /// Save vm_tag, top_resource, exit_through_ffi and top_exit_frame_info.
  int _saveThreadFields(int offsetFromFp) {
    _asm.ldr(
      scratch1Reg,
      _asm.address(threadReg, vmOffsets.Thread_vm_tag_offset),
    );
    _asm.ldr(
      scratch2Reg,
      _asm.address(threadReg, vmOffsets.Thread_top_resource_offset),
    );
    _asm.str(ZR, _asm.address(threadReg, vmOffsets.Thread_top_resource_offset));
    offsetFromFp += 2;
    _asm.stp(
      scratch2Reg,
      scratch1Reg,
      RegOffsetAddress(FP, -offsetFromFp * wordSize),
    );

    _asm.ldr(
      scratch1Reg,
      _asm.address(threadReg, vmOffsets.Thread_exit_through_ffi_offset),
    );
    _asm.str(
      ZR,
      _asm.address(threadReg, vmOffsets.Thread_exit_through_ffi_offset),
    );
    _asm.ldr(
      scratch2Reg,
      _asm.address(threadReg, vmOffsets.Thread_top_exit_frame_info_offset),
    );
    _asm.str(
      ZR,
      _asm.address(threadReg, vmOffsets.Thread_top_exit_frame_info_offset),
    );
    offsetFromFp += 2;
    _asm.stp(
      scratch2Reg,
      scratch1Reg,
      RegOffsetAddress(FP, -offsetFromFp * wordSize),
    );
    return offsetFromFp;
  }

  /// Restore vm_tag, top_resource, exit_through_ffi and top_exit_frame_info.
  int _restoreThreadFields(int offsetFromFp) {
    _asm.ldp(
      scratch2Reg,
      scratch1Reg,
      RegOffsetAddress(FP, -offsetFromFp * wordSize),
    );
    offsetFromFp -= 2;
    _asm.str(
      scratch2Reg,
      _asm.address(threadReg, vmOffsets.Thread_top_exit_frame_info_offset),
    );
    _asm.str(
      scratch1Reg,
      _asm.address(threadReg, vmOffsets.Thread_exit_through_ffi_offset),
    );

    _asm.ldp(
      scratch2Reg,
      scratch1Reg,
      RegOffsetAddress(FP, -offsetFromFp * wordSize),
    );
    offsetFromFp -= 2;
    _asm.str(
      scratch2Reg,
      _asm.address(threadReg, vmOffsets.Thread_top_resource_offset),
    );
    _asm.str(
      scratch1Reg,
      _asm.address(threadReg, vmOffsets.Thread_vm_tag_offset),
    );
    return offsetFromFp;
  }

  @override
  void _generate() {
    // Copy the C stack pointer (SP/R31) into the stack pointer we'll actually
    // use to access the stack (stackPointerReg/R15) and set the C stack pointer
    // to near the stack limit, loaded from the Thread held in R3, to prevent
    // signal handlers from over-writing Dart frames.
    _asm.mov(stackPointerReg, SP);
    _asm.ldr(
      tempReg,
      _asm.address(threadParamReg, vmOffsets.Thread_saved_stack_limit_offset),
    );
    // Thread::saved_stack_limit_ is OSThread::overflow_stack_limit(), which is
    // OSThread::stack_limit() with some headroom. Set CSP a bit below this value
    // so that signal handlers won't stomp on the stack of Dart code that pushs a
    // bit past overflow_stack_limit before its next overflow check. (We build
    // frames before doing an overflow check.)
    _asm.subImmediate(SP, tempReg, 4096);

    _asm.pushPair(FP, LR);
    _asm.mov(FP, stackPointerReg);

    // Load number of arguments and adjust count for type arguments.
    // TODO: compressed pointers.
    _asm.ldr(
      argCountReg,
      _asm.fieldAddress(
        argumentsDescriptorParamReg,
        vmOffsets.ArgumentsDescriptor_count_offset,
      ),
    );
    _asm.ldr(
      scratch1Reg,
      _asm.fieldAddress(
        argumentsDescriptorParamReg,
        vmOffsets.ArgumentsDescriptor_type_args_len_offset,
      ),
    );
    _asm.smiUntag(argCountReg);
    // Include the type arguments.
    _asm.cmp(scratch1Reg, Immediate(0));
    // argCount <- (typeArgsLen == 0) ? argCount : argCount + 1
    _asm.csinc(argCountReg, argCountReg, argCountReg, .equal);

    // Allocate entry frame.
    const int frameSizeAlignment = Arm64StackFrame.frameSizeAlignmentInSlots;
    _asm.add(
      scratch1Reg,
      argCountReg,
      Immediate(entryFrameFixedSize + frameSizeAlignment - 1),
    );
    _asm.and(scratch1Reg, scratch1Reg, Immediate(~(frameSizeAlignment - 1)));
    _asm.sub(
      stackPointerReg,
      stackPointerReg,
      ShiftedRegOperand(scratch1Reg, .LSL, log2wordSize),
    );

    // Fill entry frame.
    var offsetFromFp = 0;

    // Set up PC marker slot.
    _asm.ldr(
      tempReg,
      _asm.address(
        threadParamReg,
        fromBytecode
            ? vmOffsets.Thread_invoke_dart_code_from_bytecode_stub_offset
            : vmOffsets.Thread_invoke_dart_code_stub_offset,
      ),
    );
    ++offsetFromFp;
    _asm.str(tempReg, RegOffsetAddress(FP, -offsetFromFp * wordSize));

    offsetFromFp = _saveAbiCalleeSaveRegisters(offsetFromFp);

    _restorePinnedRegisters();

    offsetFromFp = _saveThreadFields(offsetFromFp);

    assert(offsetFromFp == entryFrameFixedSize);

    // Store GC-safe zero padding.
    assert(
      roundUp(entryFrameFixedSize, frameSizeAlignment) ==
          entryFrameFixedSize + 1,
    );
    ++offsetFromFp;
    _asm.str(ZR, RegOffsetAddress(FP, -offsetFromFp * wordSize));

    // Mark that the thread is executing Dart code. Do this after initializing the
    // exit link for the profiler.
    _asm.loadImmediate(scratch1Reg, vmOffsets.VMTag_kDartTagId);
    _asm.str(
      scratch1Reg,
      _asm.address(threadReg, vmOffsets.Thread_vm_tag_offset),
    );

    // Load arguments descriptor array into R4, which is passed to Dart code.
    _asm.mov(argumentsDescriptorReg, argumentsDescriptorParamReg);

    _asm.add(
      argumentsDestReg,
      stackPointerReg,
      ShiftedRegOperand(argCountReg, .LSL, log2wordSize),
    );

    if (!fromBytecode) {
      // Compute address of 'arguments array' data area into [argumentsParamReg].
      _asm.addImmediate(
        argumentsParamReg,
        argumentsParamReg,
        vmOffsets.Array_data_offset - heapObjectTag,
      );
    }

    // Copy arguments.
    final done = Label();
    final loop = Label();
    _asm.cbz(argCountReg, done);
    _asm.bind(loop);
    // TODO: compressed pointers
    _asm.ldr(
      scratch1Reg,
      WritebackRegOffsetAddress(
        argumentsParamReg,
        fromBytecode ? wordSize : compressedWordSize,
        isPostIndexed: true,
      ),
    );
    _asm.str(
      scratch1Reg,
      WritebackRegOffsetAddress(
        argumentsDestReg,
        -wordSize,
        isPostIndexed: false,
      ),
    );
    _asm.subImmediate(argCountReg, argCountReg, 1);
    _asm.cbnz(argCountReg, loop);
    _asm.bind(done);

    // We now load the pool pointer(PP) with a GC safe value as we are about to
    // invoke dart code. We don't need a real object pool here.
    // Smi zero does not work because ARM64 assumes PP to be untagged.
    _asm.mov(poolPointerReg, nullReg);
    _asm.mov(codeReg, codeParamReg);
    _asm.ldr(
      LR,
      _asm.fieldAddress(codeReg, vmOffsets.Code_entry_point_offset.first),
    );

    // Call the Dart code entrypoint.
    _asm.blr(LR);

    offsetFromFp = _restoreThreadFields(entryFrameFixedSize);
    offsetFromFp = _restoreAbiCalleeSaveRegisters(offsetFromFp);
    --offsetFromFp; // Drop PC marker slot.
    assert(offsetFromFp == 0);

    // Restore the frame pointer and C stack pointer and return.
    _asm.mov(stackPointerReg, FP);
    _asm.popPair(FP, LR);
    _asm.mov(SP, stackPointerReg);
    _asm.ret();
  }
}

final class SubtypeTestCacheStub extends Arm64StubCodeGenerator {
  static const Register instanceReg = R0;
  static const Register dstTypeReg = R8;
  static const Register instantiatorTypeArgumentsReg = R2;
  static const Register functionTypeArgumentsReg = R1;
  static const Register subtypeTestCacheReg = R3;
  static const Register scratchReg = R4;
  static const Register subtypeTestCacheResultReg = R7;
  static const Register entryPointReg = R9;
  static const Register instanceDelayedFunctionTypeArgumentsReg = R10;

  static const Register instanceCidOrSignatureReg = R6;
  static const Register instanceInstantiatorTypeArgumentsReg = R5;
  static const Register instanceParentFunctionTypeArgumentsReg = R9;
  static const Register cacheEntriesEndReg = R11;
  static const Register cacheContentsSizeReg = R12;
  static const Register probeDistanceReg = R13;

  final int numInputs;
  SubtypeTestCacheStub(super.vmOffsets, super.objectLayout, this.numInputs);

  void _generateSubtypeTestCacheLoopBody(
    Register cacheEntryReg,
    Label found,
    Label notFound,
    Label nextIteration,
  ) {
    // TODO: compressed pointers

    final inputRegs = [
      instanceCidOrSignatureReg,
      instanceInstantiatorTypeArgumentsReg,
      instantiatorTypeArgumentsReg,
      functionTypeArgumentsReg,
      instanceParentFunctionTypeArgumentsReg,
      instanceDelayedFunctionTypeArgumentsReg,
      dstTypeReg,
    ];
    final elemIndex = [
      vmOffsets.SubtypeTestCache_kInstanceCidOrSignature,
      vmOffsets.SubtypeTestCache_kInstanceTypeArguments,
      vmOffsets.SubtypeTestCache_kInstantiatorTypeArguments,
      vmOffsets.SubtypeTestCache_kFunctionTypeArguments,
      vmOffsets.SubtypeTestCache_kInstanceParentFunctionTypeArguments,
      vmOffsets.SubtypeTestCache_kInstanceDelayedFunctionTypeArguments,
      vmOffsets.SubtypeTestCache_kDestinationType,
    ];
    assert(inputRegs.length == elemIndex.length);

    for (var i = 1; i <= numInputs; i++) {
      if (i == 1) {
        _asm.loadAcquire(
          scratchReg,
          cacheEntryReg,
          vmOffsets.SubtypeTestCache_kInstanceCidOrSignature *
              compressedWordSize,
        );
        _asm.cmp(scratchReg, nullReg);
        _asm.b(notFound, .equal);
      } else {
        _asm.ldr(
          scratchReg,
          _asm.address(cacheEntryReg, elemIndex[i - 1] * compressedWordSize),
        );
      }
      _asm.cmp(scratchReg, inputRegs[i - 1]);
      if (i == numInputs) {
        _asm.b(found, .equal);
      } else {
        _asm.b(nextIteration, .notEqual);
      }
    }
  }

  void _generateLinearSearch(
    Register cacheEntryReg,
    Label found,
    Label notFound,
  ) {
    _asm.addImmediate(
      cacheEntryReg,
      cacheEntryReg,
      vmOffsets.Array_data_offset - heapObjectTag,
    );

    final loop = Label();
    final nextIteration = Label();
    _asm.bind(loop);

    _generateSubtypeTestCacheLoopBody(
      cacheEntryReg,
      found,
      notFound,
      nextIteration,
    );

    // Next iteration
    _asm.bind(nextIteration);
    _asm.addImmediate(
      cacheEntryReg,
      cacheEntryReg,
      compressedWordSize * vmOffsets.SubtypeTestCache_kTestEntryLength,
    );

    _asm.b(loop);
  }

  void getAbstractTypeHash(Register dst, Register src, Label notFound) {
    _asm.ldr(dst, _asm.fieldAddress(src, vmOffsets.AbstractType_hash_offset));
    _asm.smiUntag(dst);
    // Hash of 0 means the hash hasn't been computed yet and we need to go to runtime.
    _asm.cbz(dst, notFound);
  }

  void getTypeArgumentsHash(Register dst, Register src, Label notFound) {
    final done = Label();
    _asm.loadImmediate(dst, vmOffsets.TypeArguments_kAllDynamicHash);
    _asm.cmp(src, nullReg);
    _asm.b(done, .equal);
    _asm.ldr(dst, _asm.fieldAddress(src, vmOffsets.TypeArguments_hash_offset));
    _asm.smiUntag(dst);
    _asm.cbz(dst, notFound);
    _asm.bind(done);
  }

  void _generateHashSearch(
    Register cacheEntryReg,
    Register tableLengthReg,
    Label found,
    Label notFound,
  ) {
    // TODO: compressed pointers

    // Since the test entry size is a power of 2, we can use lsr to divide.
    final testEntryLengthLog2 = log2OfPowerOf2(
      vmOffsets.SubtypeTestCache_kTestEntryLength,
    );

    // Before we finish calculating the initial probe entry, we'll need the
    // starting cache entry and the number of entries. We'll store these in
    // [cacheContentsSizeReg] and [probeDistanceReg], respectively.

    final startingEntryReg = cacheContentsSizeReg; // alias for convenience

    // Hash cache traversal
    // Calculating number of entries
    // The array length is a Smi so it needs to be untagged.
    _asm.smiUntag(scratchReg, tableLengthReg);
    final entriesCountReg = probeDistanceReg; // alias for convenience
    _asm.lsr(entriesCountReg, scratchReg, testEntryLengthLog2);

    // Calculating starting entry address
    _asm.addImmediate(
      cacheEntryReg,
      cacheEntryReg,
      vmOffsets.Array_data_offset - heapObjectTag,
    );
    _asm.mov(startingEntryReg, cacheEntryReg);

    // Calculating end of entries address
    _asm.add(
      cacheEntriesEndReg,
      cacheEntryReg,
      ShiftedRegOperand(
        entriesCountReg,
        .LSL,
        testEntryLengthLog2 + log2wordSize,
      ),
    );

    // Hash the entry inputs
    {
      final done = Label();
      // Assume a Smi tagged instance cid to avoid a branch in the common case.
      _asm.mov(cacheEntryReg, instanceCidOrSignatureReg);
      _asm.smiUntag(cacheEntryReg);
      _asm.branchIfSmi(instanceCidOrSignatureReg, done);
      getAbstractTypeHash(cacheEntryReg, instanceCidOrSignatureReg, notFound);
      _asm.bind(done);
    }
    if (numInputs >= 7) {
      getAbstractTypeHash(scratchReg, dstTypeReg, notFound);
      _asm.combineHashes(cacheEntryReg, scratchReg);
    }
    if (numInputs >= 6) {
      getTypeArgumentsHash(
        scratchReg,
        instanceDelayedFunctionTypeArgumentsReg,
        notFound,
      );
      _asm.combineHashes(cacheEntryReg, scratchReg);
    }
    if (numInputs >= 5) {
      getTypeArgumentsHash(
        scratchReg,
        instanceParentFunctionTypeArgumentsReg,
        notFound,
      );
      _asm.combineHashes(cacheEntryReg, scratchReg);
    }
    if (numInputs >= 4) {
      getTypeArgumentsHash(scratchReg, functionTypeArgumentsReg, notFound);
      _asm.combineHashes(cacheEntryReg, scratchReg);
    }
    if (numInputs >= 3) {
      getTypeArgumentsHash(scratchReg, instantiatorTypeArgumentsReg, notFound);
      _asm.combineHashes(cacheEntryReg, scratchReg);
    }
    if (numInputs >= 2) {
      getTypeArgumentsHash(
        scratchReg,
        instanceInstantiatorTypeArgumentsReg,
        notFound,
      );
      _asm.combineHashes(cacheEntryReg, scratchReg);
    }
    _asm.finalizeHash(32, cacheEntryReg);

    // This requires the number of entries in a hash cache to be a power of 2.
    // Converting hash to probe entry index
    // The entry count is not needed after this point; create the mask in place.
    final countMaskReg = entriesCountReg; // alias for convenience
    _asm.addImmediate(countMaskReg, countMaskReg, -1);
    _asm.and(cacheEntryReg, cacheEntryReg, countMaskReg);
    // Now set the register to the initial probe distance in words.
    _asm.loadImmediate(
      probeDistanceReg,
      compressedWordSize * vmOffsets.SubtypeTestCache_kTestEntryLength,
    );

    // Now cacheEntryReg is the starting probe entry index.
    // Converting probe entry index to probe entry address
    _asm.add(
      cacheEntryReg,
      startingEntryReg,
      ShiftedRegOperand(
        cacheEntryReg,
        .LSL,
        testEntryLengthLog2 + log2wordSize,
      ),
    );

    // Now set the register to the negated size of the cache contents in words.
    final cacheNegatedSizeReg = startingEntryReg; // alias for convenience
    _asm.sub(cacheNegatedSizeReg, startingEntryReg, cacheEntriesEndReg);

    final loop = Label();
    final nextIteration = Label();
    _asm.bind(loop);

    _generateSubtypeTestCacheLoopBody(
      cacheEntryReg,
      found,
      notFound,
      nextIteration,
    );

    _asm.bind(nextIteration);
    // Move to next entry
    {
      _asm.add(cacheEntryReg, cacheEntryReg, probeDistanceReg);
      // Adjust probe distance
      _asm.addImmediate(
        probeDistanceReg,
        probeDistanceReg,
        compressedWordSize * vmOffsets.SubtypeTestCache_kTestEntryLength,
      );
    }
    // Check for leaving array
    // Make sure we haven't run off the array.
    _asm.cmp(cacheEntryReg, cacheEntriesEndReg);
    _asm.b(loop, .less);
    // Wrap around to start of entries
    // Add the negated size of the cache contents.
    _asm.add(cacheEntryReg, cacheEntryReg, cacheNegatedSizeReg);
    _asm.b(loop);
  }

  @override
  void _generate() {
    // TODO: compressed pointers
    _asm.push(LR);

    {
      final continueWithSearch = Label();
      _asm.ldr(
        scratchReg,
        _asm.fieldAddress(
          subtypeTestCacheReg,
          vmOffsets.SubtypeTestCache_num_inputs_offset,
        ),
        OperandSize.u32,
      );
      _asm.cmpImmediate(scratchReg, numInputs);
      _asm.b(continueWithSearch, .equal);
      _asm.unimplemented('Unexpected subtype cache number of inputs');
      _asm.bind(continueWithSearch);
    }
    const cacheArrayReg = subtypeTestCacheResultReg;
    const cacheEntryReg = cacheArrayReg;

    _asm.loadAcquire(
      cacheEntryReg,
      subtypeTestCacheReg,
      vmOffsets.SubtypeTestCache_cache_offset - heapObjectTag,
    );

    // If the type is fully instantiated, then it can be determined at compile
    // time whether Smi is a subtype of the type or not. Thus, this code should
    // never be called with a Smi instance.
    _asm.loadClassId(
      instanceCidOrSignatureReg,
      instanceReg,
      canBeSmi: numInputs >= 3,
    );

    _asm.cmpImmediate(instanceCidOrSignatureReg, ClassId.ClosureCid.index);
    final nonClosure = Label();
    _asm.b(nonClosure, .notEqual);

    // Closure handling
    _asm.ldr(
      instanceCidOrSignatureReg,
      _asm.fieldAddress(instanceReg, vmOffsets.Closure_function_offset),
    );
    _asm.ldr(
      instanceCidOrSignatureReg,
      _asm.fieldAddress(
        instanceCidOrSignatureReg,
        vmOffsets.Function_signature_offset,
      ),
    );

    final initialized = Label();

    if (numInputs >= 2) {
      _asm.ldr(
        scratchReg,
        _asm.fieldAddress(
          instanceReg,
          vmOffsets.Closure_length_and_flags_offset,
        ),
      );
      {
        // TODO: VerifySmi only in debug mode
        final isSmi = Label();
        _asm.branchIfSmi(scratchReg, isSmi);
        _asm.unimplemented('Smi is expected');
        _asm.bind(isSmi);
      }

      final loadFunctionTypeArguments = Label();
      _asm.mov(instanceInstantiatorTypeArgumentsReg, nullReg);
      _asm.tbz(
        scratchReg,
        vmOffsets.UntaggedClosure_kHasInstantiatorTypeArgumentsBit + smiShift,
        (numInputs >= 5 ? loadFunctionTypeArguments : initialized),
      );
      _asm.ubfx(
        instanceInstantiatorTypeArgumentsReg,
        scratchReg,
        vmOffsets.UntaggedClosure_kInstantiatorTypeArgumentsIndexBitsPos +
            smiShift,
        vmOffsets.UntaggedClosure_kInstantiatorTypeArgumentsIndexBitsSize,
      );

      _asm.loadIndexed(
        instanceInstantiatorTypeArgumentsReg,
        instanceReg,
        instanceInstantiatorTypeArgumentsReg,
        vmOffsets.Closure_elementOffset(0) - heapObjectTag,
      );

      if (numInputs >= 5) {
        _asm.bind(loadFunctionTypeArguments);

        final loadDelayedFunctionTypeArguments = Label();
        _asm.mov(instanceParentFunctionTypeArgumentsReg, nullReg);
        _asm.tbz(
          scratchReg,
          vmOffsets.UntaggedClosure_kHasFunctionTypeArgumentsBit + smiShift,
          (numInputs >= 6 ? loadDelayedFunctionTypeArguments : initialized),
        );
        _asm.ubfx(
          instanceParentFunctionTypeArgumentsReg,
          scratchReg,
          vmOffsets.UntaggedClosure_kFunctionTypeArgumentsIndexBitsPos +
              smiShift,
          vmOffsets.UntaggedClosure_kFunctionTypeArgumentsIndexBitsSize,
        );
        _asm.loadIndexed(
          instanceParentFunctionTypeArgumentsReg,
          instanceReg,
          instanceParentFunctionTypeArgumentsReg,
          vmOffsets.Closure_elementOffset(0) - heapObjectTag,
        );

        if (numInputs >= 6) {
          _asm.bind(loadDelayedFunctionTypeArguments);

          _asm.mov(instanceDelayedFunctionTypeArgumentsReg, nullReg);
          _asm.tbz(
            scratchReg,
            vmOffsets.UntaggedClosure_kHasDelayedTypeArgumentsBit + smiShift,
            initialized,
          );
          _asm.ldr(
            instanceDelayedFunctionTypeArgumentsReg,
            _asm.fieldAddress(
              instanceReg,
              vmOffsets.Closure_elementOffset(
                vmOffsets.UntaggedClosure_kDelayedTypeArgumentsIndex,
              ),
            ),
          );
        }
      }
      _asm.b(initialized);
    }

    _asm.bind(nonClosure);
    if (numInputs >= 2) {
      _asm.loadClassById(scratchReg, instanceCidOrSignatureReg);
      _asm.mov(instanceInstantiatorTypeArgumentsReg, nullReg);
      _asm.ldr(
        scratchReg,
        _asm.fieldAddress(
          scratchReg,
          vmOffsets.Class_host_type_arguments_field_offset_in_words_offset,
        ),
        OperandSize.u32,
      );
      _asm.cmpImmediate(
        scratchReg,
        vmOffsets.Class_kNoTypeArguments,
        OperandSize.s32,
      );
      final hasNoTypeArgument = Label();
      _asm.b(hasNoTypeArgument, .equal);

      _asm.add(
        instanceInstantiatorTypeArgumentsReg,
        instanceReg,
        ShiftedRegOperand(scratchReg, .LSL, log2wordSize),
      );
      _asm.ldr(
        instanceInstantiatorTypeArgumentsReg,
        _asm.address(instanceInstantiatorTypeArgumentsReg, -heapObjectTag),
      );

      _asm.bind(hasNoTypeArgument);

      if (numInputs >= 5) {
        _asm.mov(instanceParentFunctionTypeArgumentsReg, nullReg);
        if (numInputs >= 6) {
          _asm.mov(instanceDelayedFunctionTypeArgumentsReg, nullReg);
        }
      }
    }
    _asm.smiTag(instanceCidOrSignatureReg);
    _asm.bind(initialized);

    _asm.ldr(
      scratchReg,
      _asm.fieldAddress(cacheEntryReg, vmOffsets.Array_length_offset),
    );
    _asm.cmpImmediate(
      scratchReg,
      vmOffsets.SubtypeTestCache_kMaxLinearCacheSize << smiShift,
    );
    final isHash = Label();
    _asm.b(isHash, .greater);

    final notFound = Label();
    final found = Label();
    _generateLinearSearch(cacheEntryReg, found, notFound);
    _asm.bind(found);
    _asm.ldr(
      subtypeTestCacheResultReg,
      _asm.address(
        cacheArrayReg,
        compressedWordSize * vmOffsets.SubtypeTestCache_kTestResult,
      ),
    );
    _asm.pop(LR);
    _asm.ret();

    _asm.bind(notFound);
    _asm.mov(subtypeTestCacheResultReg, nullReg);
    _asm.pop(LR);
    _asm.ret();

    _asm.bind(isHash);
    _generateHashSearch(cacheEntryReg, scratchReg, found, notFound);
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
  static const Register instanceDelayedFunctionTypeArgumentsReg = R10;
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

final class CloneSuspendStateStub {
  static const Register sourceReg = R0;
}

final class CallBootstrapNativeStub {
  static const Register argcTagReg = R1;
  static const Register firstArgPointerReg = R2;
  static const Register nativeFunctionReg = R5;
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
    bool isArray,
  ) => WriteBarrierStub(vmOffsets, objectLayout, objectReg, valueReg, isArray);

  @override
  StubCodeGenerator dynamicCallStubGenerator() =>
      DynamicCallStub(vmOffsets, objectLayout);

  @override
  StubCodeGenerator dynamicInvocationForwarderStubGenerator() =>
      DynamicInvocationForwarderStub(vmOffsets, objectLayout);

  @override
  StubCodeGenerator invokeDartCodeStubGenerator() =>
      InvokeDartCodeStub(vmOffsets, objectLayout, fromBytecode: false);

  @override
  StubCodeGenerator invokeDartCodeFromBytecodeStubGenerator() =>
      InvokeDartCodeStub(vmOffsets, objectLayout, fromBytecode: true);

  @override
  StubCodeGenerator subtypeTestCacheStubGenerator(int n) =>
      SubtypeTestCacheStub(vmOffsets, objectLayout, n);
}
