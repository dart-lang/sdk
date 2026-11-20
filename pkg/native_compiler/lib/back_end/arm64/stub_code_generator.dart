// Copyright (c) 2026 the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/functions.dart' show ArgumentsShape;
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

  void createSafepoint(int numObjectSlots) {
    assert((0 <= numObjectSlots) && (numObjectSlots <= _frameSizeInWords));
    final safepoint = _currentSafepoint = Safepoint();

    /// TODO: pass arguments on registers.
    safepoint.addLiveStackSlots(
      _frameSizeInWords - numObjectSlots,
      numObjectSlots,
      isObjectPointer: true,
    );
  }

  /// Generate code for calling core library Dart function
  /// cached in the ObjectStore.
  void callDartCoreLibraryFunction(
    int functionOffsetInObjectStore,
    int numObjectSlots, {
    bool usesArgsDesc = false,
  }) {
    _asm.loadIsolateGroup(tempReg);
    _asm.ldr(
      tempReg,
      _asm.address(tempReg, vmOffsets.IsolateGroup_object_store_offset),
    );
    _asm.ldr(functionReg, _asm.address(tempReg, functionOffsetInObjectStore));
    _asm.ldr(
      codeReg,
      _asm.fieldAddress(functionReg, vmOffsets.Function_code_offset),
    );
    if (!usesArgsDesc) {
      // Load a GC-safe value for the arguments descriptor (unused but tagged).
      _asm.loadImmediate(argumentsDescriptorReg, 0);
    }
    _asm.ldr(
      LR,
      _asm.fieldAddress(
        functionReg,
        vmOffsets.Function_entry_point_offset.first,
      ),
    );
    createSafepoint(numObjectSlots);
    _asm.blr(LR);
    addCallSiteMetadata(.dartCall);
    _currentSafepoint = null;
  }

  /// Helper to generate allocation of _SuspendState instance.
  /// Initializes tags, frame_capacity and frame_size.
  /// Other fields are not initialized.
  ///
  /// Input:
  ///   [frameSizeReg]: size of the frame payload in bytes.
  /// Output:
  ///   [resultReg]: allocated instance.
  /// Clobbers:
  ///   [scratch1Reg], [scratch2Reg], [scratch3Reg], [tempReg], [temp2Reg].
  void generateAllocateSuspendState(
    Register resultReg,
    Register frameSizeReg,
    Register scratch1Reg,
    Register scratch2Reg,
    Register scratch3Reg,
    Label slowPath,
  ) {
    final instanceSizeReg = scratch1Reg;
    final tagsReg = scratch2Reg;

    // Compute the rounded instance size.
    final fixedSizePlusAlignmentPadding =
        vmOffsets.SuspendState_HeaderSize + objectAlignment(wordSize) - 1;
    _asm.addImmediate(
      instanceSizeReg,
      frameSizeReg,
      fixedSizePlusAlignmentPadding,
    );
    _asm.andImmediate(
      instanceSizeReg,
      instanceSizeReg,
      -objectAlignment(wordSize),
    );

    // Combine tags and size.
    final log2alignment = log2objectAlignment(log2wordSize);
    _asm.cmpImmediate(
      instanceSizeReg,
      (1 << (vmOffsets.UntaggedObject_kSizeTagSize + log2alignment)),
    );
    _asm.lsl(
      tempReg,
      instanceSizeReg,
      vmOffsets.UntaggedObject_kSizeTagPos - log2alignment,
    );
    _asm.csel(tempReg, ZR, tempReg, .unsignedGreaterOrEqual);
    final tags = vmOffsets.computeNewObjectTags(
      ClassId.SuspendStateCid,
      0,
      log2wordSize,
    );
    _asm.orImmediate(tagsReg, tempReg, tags);

    _asm.inlineArrayAllocation(
      resultReg,
      tagsReg,
      instanceSizeReg,
      scratch3Reg,
      tempReg,
      slowPath,
      initializeFields: false,
    );

    // Use rounded object size to calculate and save frame capacity.
    _asm.subImmediate(
      tempReg,
      instanceSizeReg,
      vmOffsets.SuspendState_payload_offset,
    );
    _asm.str(
      tempReg,
      _asm.fieldAddress(
        resultReg,
        vmOffsets.SuspendState_frame_capacity_offset,
      ),
    );

    _asm.str(
      frameSizeReg,
      _asm.fieldAddress(resultReg, vmOffsets.SuspendState_frame_size_offset),
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
    createSafepoint(3);
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
      _asm.pairAddress(stackPointerReg, 4 * wordSize),
    );
    _asm.stp(
      nullReg, // Placeholder for the result of the call.
      nullReg, // Space for result (target function).
      _asm.pairAddress(stackPointerReg, 2 * wordSize),
    );
    _asm.stp(
      inlineCacheDataReg,
      receiverReg,
      _asm.pairAddress(stackPointerReg, 0),
    );

    // Make sure all slots are recorded as pointers in the stackmap.
    createSafepoint(6);
    _asm.callRuntime(RuntimeEntry.InlineCacheMissHandlerModAOT, 3);
    _currentSafepoint = null;

    // Restore preserved ICData and arguments descriptor.
    _asm.ldp(
      inlineCacheDataReg,
      argumentsDescriptorReg,
      _asm.pairAddress(stackPointerReg, 4 * wordSize),
    );
    // Load target function and the result of the call.
    _asm.ldp(
      tempReg,
      functionReg,
      _asm.pairAddress(stackPointerReg, 2 * wordSize),
    );

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
      _asm.pairAddress(stackPointerReg, 0),
    );

    createSafepoint(3);
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

final class InitSuspendableFunctionStub extends Arm64StubCodeGenerator {
  static const Register typeArgsReg = R0;

  final int initFunctionOffsetInObjectStore;

  InitSuspendableFunctionStub(
    super.vmOffsets,
    super.objectLayout,
    this.initFunctionOffsetInObjectStore,
  );

  @override
  void _generate() {
    enterStubFrame();
    _asm.loadFromPool(
      argumentsDescriptorReg,
      const ArgumentsShape(1, 0, const []),
    );
    _frameSizeInWords = 2;
    _asm.pushPair(typeArgsReg, ZR);
    callDartCoreLibraryFunction(
      initFunctionOffsetInObjectStore,
      1,
      usesArgsDesc: true,
    );
    leaveStubFrame();

    // Set :suspend_state in the caller frame.
    _asm.str(
      returnReg,
      _asm.address(FP, Arm64StackFrame.suspendStateOffsetFromFP),
    );
    _asm.ret();
  }
}

final class SuspendStub extends Arm64StubCodeGenerator {
  static const Register argumentReg = R0;
  static const Register typeArgsReg = R1; // Can be the same as scratch1Reg
  static const Register scratch1Reg = R1;
  static const Register frameSizeReg = R2;
  static const Register suspendStateReg = R3;
  static const Register functionDataReg = R4;
  static const Register srcFrameReg = R5;
  static const Register dstFrameReg = R6;
  static const Register scratch2Reg = R7;
  static const Register scratch3Reg = R8;

  static const bool generateVerificationCode = true; // TODO: turn to a flag.

  final bool callSuspendFunction;
  final bool passTypeArguments;
  final int? suspendFunctionOffsetInObjectStore;

  SuspendStub(
    super.vmOffsets,
    super.objectLayout, {
    required this.callSuspendFunction,
    required this.passTypeArguments,
    this.suspendFunctionOffsetInObjectStore,
  }) : assert(
         !callSuspendFunction || suspendFunctionOffsetInObjectStore != null,
       );

  @override
  void _generate() {
    final allocSlowPath = Label();
    final allocDone = Label();
    final initDone = Label();
    final rememberObject = Label();
    final callDart = Label();

    _asm.ldr(
      suspendStateReg,
      _asm.address(FP, Arm64StackFrame.suspendStateOffsetFromFP),
    );

    _asm.sub(frameSizeReg, FP, stackPointerReg);

    enterStubFrame();

    if (passTypeArguments) {
      _frameSizeInWords += 2;
      _asm.pushPair(typeArgsReg, ZR);
    }

    _asm.loadClassId(tempReg, suspendStateReg, canBeSmi: false);
    _asm.cmpImmediate(tempReg, ClassId.SuspendStateCid.index);

    if (generateVerificationCode) {
      final allocSuspendState = Label();
      _asm.b(allocSuspendState, .notEqual);

      _asm.ldr(
        tempReg,
        _asm.fieldAddress(
          suspendStateReg,
          vmOffsets.SuspendState_frame_size_offset,
        ),
      );
      _asm.cmp(frameSizeReg, tempReg);
      _asm.b(initDone, .equal);

      _asm.unimplemented('SuspendState frame size mismatch');

      _asm.bind(allocSuspendState);
    } else {
      _asm.b(initDone, .equal);
    }

    // Allocate SuspendState.
    _asm.mov(functionDataReg, suspendStateReg);

    generateAllocateSuspendState(
      suspendStateReg,
      frameSizeReg,
      scratch1Reg,
      scratch2Reg,
      scratch3Reg,
      allocSlowPath,
    );

    // TODO: compressed pointers
    _asm.str(
      functionDataReg,
      _asm.fieldAddress(
        suspendStateReg,
        vmOffsets.SuspendState_function_data_offset,
      ),
    );
    _asm.str(
      nullReg,
      _asm.fieldAddress(
        suspendStateReg,
        vmOffsets.SuspendState_then_callback_offset,
      ),
    );
    _asm.str(
      nullReg,
      _asm.fieldAddress(
        suspendStateReg,
        vmOffsets.SuspendState_error_callback_offset,
      ),
    );

    _asm.bind(allocDone);

    // Save SuspendState to frame.
    _asm.ldr(
      tempReg,
      _asm.address(FP, Arm64StackFrame.savedCallerFpOffsetFromFP),
    );
    _asm.str(
      suspendStateReg,
      _asm.address(tempReg, Arm64StackFrame.suspendStateOffsetFromFP),
    );

    _asm.bind(initDone);
    // Copy frame to SuspendState.
    const callerSpOffsetFromFp = Arm64StackFrame.lastParameterOffsetFromFP;
    _asm.addImmediate(srcFrameReg, FP, callerSpOffsetFromFp);
    _asm.addImmediate(
      dstFrameReg,
      suspendStateReg,
      vmOffsets.SuspendState_payload_offset - heapObjectTag,
    );
    _asm.copyMemoryWords(srcFrameReg, dstFrameReg, frameSizeReg, tempReg);

    _asm.ldr(
      tempReg,
      _asm.address(FP, Arm64StackFrame.savedCallerPcOffsetFromFP),
    );
    _asm.str(
      tempReg,
      _asm.fieldAddress(suspendStateReg, vmOffsets.SuspendState_pc_offset),
    );

    if (callSuspendFunction) {
      // Push arguments for suspend Dart function early to preserve them
      // across write barrier.
      _frameSizeInWords += 2;
      _asm.pushPair(argumentReg, suspendStateReg);
    }

    // Write barrier.
    _asm.branchIfRemembered(suspendStateReg, rememberObject, tempReg);

    _asm.bind(callDart);
    if (callSuspendFunction) {
      // Call suspend Dart function.
      if (passTypeArguments) {
        _asm.loadFromPool(
          argumentsDescriptorReg,
          const ArgumentsShape(1, 2, const []),
        );
      }
      callDartCoreLibraryFunction(
        suspendFunctionOffsetInObjectStore!,
        2 + (passTypeArguments ? 1 : 0),
        usesArgsDesc: passTypeArguments,
      );
    } else {
      // SuspendStub returns either the result of Dart callback,
      // or SuspendStub argument (if Dart callback is not used).
      // The latter is used by yield/yield* in sync* functions
      // to indicate that iteration should be continued.
      if (returnReg != argumentReg) {
        _asm.mov(returnReg, argumentReg);
      }
    }

    leaveStubFrame();
    _asm.leaveDartFrame();
    _asm.ret();

    // SuspendState Allocation slow case.
    _asm.bind(allocSlowPath);

    _frameSizeInWords = 6 + (passTypeArguments ? 2 : 0);
    _asm.subImmediate(stackPointerReg, stackPointerReg, 6 * wordSize);
    // Save argument and frame size.
    _asm.stp(
      frameSizeReg, // Untagged but aligned, so GC would treat it as a Smi.
      argumentReg,
      _asm.pairAddress(stackPointerReg, 4 * wordSize),
    );
    _asm.stp(
      nullReg, // Space for return value.
      nullReg, // Padding.
      _asm.pairAddress(stackPointerReg, 2 * wordSize),
    );
    _asm.smiTag(frameSizeReg);
    _asm.stp(
      functionDataReg,
      frameSizeReg,
      _asm.pairAddress(stackPointerReg, 0),
    );
    createSafepoint(6 + (passTypeArguments ? 1 : 0));
    _asm.callRuntime(RuntimeEntry.AllocateSuspendState, 2);
    _currentSafepoint = null;
    _asm.ldr(suspendStateReg, _asm.address(stackPointerReg, 2 * wordSize));
    _asm.ldp(
      frameSizeReg,
      argumentReg,
      _asm.pairAddress(stackPointerReg, 4 * wordSize),
    );
    _asm.addImmediate(
      stackPointerReg,
      stackPointerReg,
      6 * wordSize,
    ); // Drop arguments.
    _asm.b(allocDone);

    // Old gen SuspendState slow case.
    _asm.bind(rememberObject);
    if (!callSuspendFunction) {
      // Save argumentReg which contains the return value
      // if suspend function is not called.
      _asm.pushPair(argumentReg, ZR);
    }
    _asm.mov(R0, suspendStateReg);
    _asm.mov(R1, threadReg);
    _asm.callLeafRuntime(LeafRuntimeEntry.EnsureRememberedAndMarkingDeferred);
    if (!callSuspendFunction) {
      _asm.popPair(argumentReg, ZR);
    }
    _asm.b(callDart);
  }
}

final class ResumeStub extends Arm64StubCodeGenerator {
  static const Register suspendStateReg = R2;
  static const Register scratchReg = R0;
  // Registers for the frame copying (the 1st part).
  static const Register frameSizeReg = R1;
  static const Register srcFrameReg = R3;
  static const Register dstFrameReg = R4;
  // Registers for control transfer
  // (the 2nd part, can reuse registers from the 1st part).
  static const Register resumePcReg = R1;
  static const Register exceptionReg = R3;
  static const Register stackTraceReg = R4;

  ResumeStub(super.vmOffsets, super.objectLayout);

  @override
  void _generate() {
    final callRuntime = Label();

    // Top of the stack on entry:
    // ... [SuspendState] [value] [exception] [stackTrace]

    _asm.enterDartFrame();

    const int paramOffset = Arm64StackFrame.lastParameterOffsetFromFP;
    _asm.ldr(suspendStateReg, _asm.address(FP, paramOffset + 3 * wordSize));

    _asm.ldr(
      frameSizeReg,
      _asm.fieldAddress(
        suspendStateReg,
        vmOffsets.SuspendState_frame_size_offset,
      ),
    );

    // Copy Code object (part of the fixed frame which is not copied below)
    // and restore pool pointer.
    _asm.add(tempReg, suspendStateReg, frameSizeReg);
    _asm.ldr(
      codeReg,
      _asm.address(
        tempReg,
        vmOffsets.SuspendState_payload_offset -
            heapObjectTag +
            Arm64StackFrame.codeOffsetFromFP,
      ),
    );
    _asm.str(codeReg, _asm.address(FP, Arm64StackFrame.codeOffsetFromFP));
    _asm.loadPoolPointer();

    // Do not copy fixed frame between the first local and FP.
    _asm.addImmediate(
      frameSizeReg,
      frameSizeReg,
      Arm64StackFrame.firstSlotOffsetFromFP + wordSize,
    );
    _asm.sub(stackPointerReg, stackPointerReg, frameSizeReg);

    // Copy frame from SuspendState.
    _asm.addImmediate(
      srcFrameReg,
      suspendStateReg,
      vmOffsets.SuspendState_payload_offset - heapObjectTag,
    );
    _asm.mov(dstFrameReg, stackPointerReg);
    _asm.copyMemoryWords(srcFrameReg, dstFrameReg, frameSizeReg, tempReg);

    // Transfer control.
    _asm.ldr(
      resumePcReg,
      _asm.fieldAddress(suspendStateReg, vmOffsets.SuspendState_pc_offset),
    );
    _asm.str(
      ZR,
      _asm.fieldAddress(suspendStateReg, vmOffsets.SuspendState_pc_offset),
    );

    assert((exceptionReg != codeReg) && (exceptionReg != poolPointerReg));
    _asm.ldr(exceptionReg, _asm.address(FP, paramOffset + 1 * wordSize));
    _asm.cmp(exceptionReg, nullReg);
    _asm.b(callRuntime, .notEqual);

    // Check if Code is disabled.
    _asm.ldr(
      scratchReg,
      _asm.fieldAddress(codeReg, vmOffsets.Code_instructions_offset),
    );
    _asm.ldr(
      tempReg,
      _asm.fieldAddress(codeReg, vmOffsets.Code_active_instructions_offset),
    );
    _asm.cmp(scratchReg, tempReg);
    _asm.b(callRuntime, .notEqual);

    // TODO: check if there is a breakpoint at resumption.

    _asm.ldr(returnReg, _asm.address(FP, paramOffset + 2 * wordSize));
    _asm.br(resumePcReg);

    // Call runtime to throw exception or deopt.
    _asm.bind(callRuntime);

    _asm.ldr(stackTraceReg, _asm.address(FP, paramOffset + 0 * wordSize));
    assert((stackTraceReg != codeReg) && (stackTraceReg != poolPointerReg));

    final resumeInterpreter = Label();
    _asm.ldr(
      tempReg,
      _asm.address(
        threadReg,
        vmOffsets.Thread_resume_interpreter_adjusted_entry_point_offset,
      ),
    );
    _asm.cmp(resumePcReg, tempReg);
    _asm.b(resumeInterpreter, .equal);

    // Set return address as if suspended Dart function called
    // stub with resumePcReg as a return address.
    _asm.mov(LR, resumePcReg);

    _asm.ldr(
      codeReg,
      _asm.address(threadReg, vmOffsets.Thread_resume_stub_offset),
    );
    enterStubFrame();
    _frameSizeInWords = 4;
    _asm.subImmediate(stackPointerReg, stackPointerReg, 4 * wordSize);
    _asm.stp(
      nullReg,
      ZR,
      _asm.pairAddress(stackPointerReg, 2 * wordSize),
    ); // Space for result.
    _asm.stp(stackTraceReg, exceptionReg, _asm.pairAddress(stackPointerReg, 0));
    createSafepoint(3);
    _asm.callRuntime(RuntimeEntry.ResumeFrame, 2);
    _currentSafepoint = null;
    leaveStubFrame();
    _asm.ldr(returnReg, _asm.address(FP, paramOffset + 2 * wordSize));
    // Lazy deoptimize.
    _asm.ret();

    // Resume interpreter.
    _asm.bind(resumeInterpreter);
    _frameSizeInWords = 4;
    _asm.subImmediate(stackPointerReg, stackPointerReg, 4 * wordSize);
    // Load the value to pass to the resumed bytecode.
    _asm.ldr(tempReg, _asm.address(FP, paramOffset + 2 * wordSize));
    // Value, space for result.
    _asm.stp(tempReg, nullReg, _asm.pairAddress(stackPointerReg, 2 * wordSize));
    _asm.stp(stackTraceReg, exceptionReg, _asm.pairAddress(stackPointerReg, 0));
    // This safepoint is unused as frame has a different Code object.
    // TODO: figure out how to align this with ResumeInterpreter stub.
    createSafepoint(4);
    _asm.callRuntime(RuntimeEntry.ResumeInterpreter, 3);
    _currentSafepoint = null;
    _asm.ldr(returnReg, _asm.address(stackPointerReg, 3 * wordSize));
    _asm.leaveDartFrame();
    _asm.ret();
  }
}

final class ReturnStub extends Arm64StubCodeGenerator {
  static const Register suspendStateReg = R2;

  final int returnFunctionOffsetInObjectStore;

  ReturnStub(
    super.vmOffsets,
    super.objectLayout,
    this.returnFunctionOffsetInObjectStore,
  );

  @override
  void _generate() {
    _asm.ldr(
      suspendStateReg,
      _asm.address(FP, Arm64StackFrame.suspendStateOffsetFromFP),
    );
    _asm.leaveDartFrame();
    // Code object of the stub is already loaded to codeReg in jumpStub.
    enterStubFrame();
    _frameSizeInWords = 2;
    _asm.pushPair(returnReg, suspendStateReg);
    callDartCoreLibraryFunction(returnFunctionOffsetInObjectStore, 2);
    leaveStubFrame();
    _asm.ret();
  }
}

final class AsyncExceptionHandlerStub extends Arm64StubCodeGenerator {
  static const Register suspendStateReg = R2;

  AsyncExceptionHandlerStub(super.vmOffsets, super.objectLayout);

  @override
  void _generate() {
    assert(suspendStateReg != exceptionObjectReg);
    assert(suspendStateReg != stackTraceObjectReg);
    final rethrowException = Label();

    _asm.ldr(
      suspendStateReg,
      _asm.address(FP, Arm64StackFrame.suspendStateOffsetFromFP),
    );

    // Check if suspend_state is initialized. Otherwise
    // exception was thrown from the prologue code and
    // should be synchronously propagated.
    _asm.cmp(suspendStateReg, nullReg);
    _asm.b(rethrowException, .equal);

    _asm.leaveDartFrame();
    _asm.ldr(
      codeReg,
      _asm.address(
        threadReg,
        vmOffsets.Thread_async_exception_handler_stub_offset,
      ),
    );
    enterStubFrame();
    _frameSizeInWords = 4;
    _asm.subImmediate(stackPointerReg, stackPointerReg, 4 * wordSize);
    _asm.stp(
      suspendStateReg,
      ZR,
      _asm.pairAddress(stackPointerReg, 2 * wordSize),
    );
    _asm.stp(
      stackTraceObjectReg,
      exceptionObjectReg,
      _asm.pairAddress(stackPointerReg, 0),
    );
    callDartCoreLibraryFunction(
      vmOffsets.ObjectStore_suspend_state_handle_exception_offset,
      3,
    );
    leaveStubFrame();
    _asm.ret();

    // Rethrow exception.
    _asm.bind(rethrowException);
    _asm.leaveDartFrame();
    _asm.ldr(
      codeReg,
      _asm.address(
        threadReg,
        vmOffsets.Thread_async_exception_handler_stub_offset,
      ),
    );
    enterStubFrame();
    _frameSizeInWords = 4;
    _asm.subImmediate(stackPointerReg, stackPointerReg, 4 * wordSize);
    // Exception object, space for result.
    _asm.stp(
      exceptionObjectReg,
      nullReg,
      _asm.pairAddress(stackPointerReg, 2 * wordSize),
    );
    // Do not bypass debugger (Smi 0), stack trace object.
    _asm.stp(ZR, stackTraceObjectReg, _asm.pairAddress(stackPointerReg, 0));
    createSafepoint(4);
    _asm.callRuntime(RuntimeEntry.ReThrow, 3);
    _currentSafepoint = null;
    _asm.breakpoint();
  }
}

final class CloneSuspendStateStub extends Arm64StubCodeGenerator {
  static const Register sourceReg = R0;
  static const Register destinationReg = R1;
  static const Register scratch1Reg = R2;
  static const Register frameSizeReg = R3;
  static const Register srcFrameReg = R4;
  static const Register dstFrameReg = R5;
  static const Register scratch2Reg = R6;
  static const Register scratch3Reg = R7;

  CloneSuspendStateStub(super.vmOffsets, super.objectLayout);

  @override
  void _generate() {
    final allocSlowPath = Label();

    _asm.ldr(
      frameSizeReg,
      _asm.fieldAddress(sourceReg, vmOffsets.SuspendState_frame_size_offset),
    );

    generateAllocateSuspendState(
      destinationReg,
      frameSizeReg,
      scratch1Reg,
      scratch2Reg,
      scratch3Reg,
      allocSlowPath,
    );

    // Copy pc.
    _asm.ldr(
      tempReg,
      _asm.fieldAddress(sourceReg, vmOffsets.SuspendState_pc_offset),
    );
    _asm.str(
      tempReg,
      _asm.fieldAddress(destinationReg, vmOffsets.SuspendState_pc_offset),
    );

    // TODO: compressed pointers

    // Copy function_data.
    _asm.ldr(
      tempReg,
      _asm.fieldAddress(sourceReg, vmOffsets.SuspendState_function_data_offset),
    );
    _asm.str(
      tempReg,
      _asm.fieldAddress(
        destinationReg,
        vmOffsets.SuspendState_function_data_offset,
      ),
    );

    // Copy then_callback.
    _asm.ldr(
      tempReg,
      _asm.fieldAddress(sourceReg, vmOffsets.SuspendState_then_callback_offset),
    );
    _asm.str(
      tempReg,
      _asm.fieldAddress(
        destinationReg,
        vmOffsets.SuspendState_then_callback_offset,
      ),
    );

    // Copy error_callback.
    _asm.ldr(
      tempReg,
      _asm.fieldAddress(
        sourceReg,
        vmOffsets.SuspendState_error_callback_offset,
      ),
    );
    _asm.str(
      tempReg,
      _asm.fieldAddress(
        destinationReg,
        vmOffsets.SuspendState_error_callback_offset,
      ),
    );

    // Copy payload frame.
    final offset = vmOffsets.SuspendState_payload_offset - heapObjectTag;
    _asm.addImmediate(srcFrameReg, sourceReg, offset);
    _asm.addImmediate(dstFrameReg, destinationReg, offset);
    _asm.copyMemoryWords(srcFrameReg, dstFrameReg, frameSizeReg, tempReg);

    // Update value of :suspend_state variable in the copied frame
    // for the new SuspendState.
    _asm.ldr(
      tempReg,
      _asm.fieldAddress(
        destinationReg,
        vmOffsets.SuspendState_frame_size_offset,
      ),
    );
    _asm.add(tempReg, tempReg, destinationReg);
    _asm.str(
      destinationReg,
      _asm.fieldAddress(
        tempReg,
        vmOffsets.SuspendState_payload_offset +
            Arm64StackFrame.suspendStateOffsetFromFP,
      ),
    );

    _asm.mov(returnReg, destinationReg);
    _asm.ret();

    // CloneSuspendState slow case.
    _asm.bind(allocSlowPath);
    enterStubFrame();
    _frameSizeInWords = 2;
    _asm.pushPair(
      sourceReg,
      nullReg, // Space for result.
    );
    createSafepoint(2);
    _asm.callRuntime(RuntimeEntry.CloneSuspendState, 1);
    _currentSafepoint = null;
    _asm.ldr(returnReg, _asm.address(stackPointerReg, 1 * wordSize));
    leaveStubFrame();
    _asm.ret();
  }
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

  @override
  StubCodeGenerator awaitStubGenerator() => SuspendStub(
    vmOffsets,
    objectLayout,
    callSuspendFunction: true,
    passTypeArguments: false,
    suspendFunctionOffsetInObjectStore:
        vmOffsets.ObjectStore_suspend_state_await_offset,
  );

  @override
  StubCodeGenerator awaitWithTypeCheckStubGenerator() => SuspendStub(
    vmOffsets,
    objectLayout,
    callSuspendFunction: true,
    passTypeArguments: true,
    suspendFunctionOffsetInObjectStore:
        vmOffsets.ObjectStore_suspend_state_await_with_type_check_offset,
  );

  @override
  StubCodeGenerator yieldAsyncStarStubGenerator() => SuspendStub(
    vmOffsets,
    objectLayout,
    callSuspendFunction: true,
    passTypeArguments: false,
    suspendFunctionOffsetInObjectStore:
        vmOffsets.ObjectStore_suspend_state_yield_async_star_offset,
  );

  @override
  StubCodeGenerator suspendSyncStarAtStartStubGenerator() => SuspendStub(
    vmOffsets,
    objectLayout,
    callSuspendFunction: true,
    passTypeArguments: false,
    suspendFunctionOffsetInObjectStore:
        vmOffsets.ObjectStore_suspend_state_suspend_sync_star_at_start_offset,
  );

  @override
  StubCodeGenerator suspendSyncStarAtYieldStubGenerator() => SuspendStub(
    vmOffsets,
    objectLayout,
    callSuspendFunction: false,
    passTypeArguments: false,
  );

  @override
  StubCodeGenerator initAsyncStubGenerator() => InitSuspendableFunctionStub(
    vmOffsets,
    objectLayout,
    vmOffsets.ObjectStore_suspend_state_init_async_offset,
  );

  @override
  StubCodeGenerator initAsyncStarStubGenerator() => InitSuspendableFunctionStub(
    vmOffsets,
    objectLayout,
    vmOffsets.ObjectStore_suspend_state_init_async_star_offset,
  );

  @override
  StubCodeGenerator initSyncStarStubGenerator() => InitSuspendableFunctionStub(
    vmOffsets,
    objectLayout,
    vmOffsets.ObjectStore_suspend_state_init_sync_star_offset,
  );

  @override
  StubCodeGenerator resumeStubGenerator() =>
      ResumeStub(vmOffsets, objectLayout);

  @override
  StubCodeGenerator returnAsyncStubGenerator() => ReturnStub(
    vmOffsets,
    objectLayout,
    vmOffsets.ObjectStore_suspend_state_return_async_offset,
  );

  @override
  StubCodeGenerator returnAsyncNotFutureStubGenerator() => ReturnStub(
    vmOffsets,
    objectLayout,
    vmOffsets.ObjectStore_suspend_state_return_async_not_future_offset,
  );

  @override
  StubCodeGenerator returnAsyncStarStubGenerator() => ReturnStub(
    vmOffsets,
    objectLayout,
    vmOffsets.ObjectStore_suspend_state_return_async_star_offset,
  );

  @override
  StubCodeGenerator asyncExceptionHandlerStubGenerator() =>
      AsyncExceptionHandlerStub(vmOffsets, objectLayout);

  @override
  StubCodeGenerator cloneSuspendStateStubGenerator() =>
      CloneSuspendStateStub(vmOffsets, objectLayout);
}
