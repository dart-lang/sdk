// Copyright (c) 2026 the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/utils/misc.dart';
import 'package:kernel/ast.dart' as ast show Class;
import 'package:native_compiler/back_end/arm64/assembler.dart';
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

  VMOffsets get vmOffsets => _asm.vmOffsets;
  ObjectLayout get objectLayout => _asm.objectLayout;
  int get compressedWordSize => objectLayout.compressedWordSize;

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

    if (numInputs >= 3) {
      _asm.loadClassIdMayBeSmi(instanceCidOrSignatureReg, instanceReg);
    } else {
      // If the type is fully instantiated, then it can be determined at compile
      // time whether Smi is a subtype of the type or not. Thus, this code should
      // never be called with a Smi instance.
      _asm.loadClassId(instanceCidOrSignatureReg, instanceReg);
    }

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
        _asm.tbz(scratchReg, smiBit, isSmi);
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
  ) => WriteBarrierStub(vmOffsets, objectLayout, objectReg, valueReg);

  @override
  StubCodeGenerator subtypeTestCacheStubGenerator(int n) =>
      SubtypeTestCacheStub(vmOffsets, objectLayout, n);
}
