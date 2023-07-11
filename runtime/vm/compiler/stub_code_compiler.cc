// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/runtime_api.h"
#include "vm/flags.h"
#include "vm/globals.h"

// For `StubCodeCompiler::GenerateAllocateUnhandledExceptionStub`
#include "vm/compiler/backend/il.h"

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/compiler/stub_code_compiler.h"

#include "vm/code_descriptors.h"
#include "vm/compiler/api/type_check_mode.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/locations.h"
#include "vm/stack_frame.h"

#define __ assembler->

namespace dart {
namespace compiler {

intptr_t StubCodeCompiler::WordOffsetFromFpToCpuRegister(
    Register cpu_register) {
  ASSERT(RegisterSet::Contains(kDartAvailableCpuRegs, cpu_register));

  intptr_t slots_from_fp = target::frame_layout.param_end_from_fp + 1;
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
    Register reg = static_cast<Register>(i);
    if (reg == cpu_register) break;
    if (RegisterSet::Contains(kDartAvailableCpuRegs, reg)) {
      slots_from_fp++;
    }
  }
  return slots_from_fp;
}

void StubCodeCompiler::GenerateInitStaticFieldStub() {
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make room for result.
  __ PushRegister(InitStaticFieldABI::kFieldReg);
  __ CallRuntime(kInitStaticFieldRuntimeEntry, /*argument_count=*/1);
  __ Drop(1);
  __ PopRegister(InitStaticFieldABI::kResultReg);
  __ LeaveStubFrame();
  __ Ret();
}

void StubCodeCompiler::GenerateInitLateStaticFieldStub(bool is_final) {
  const Register kResultReg = InitStaticFieldABI::kResultReg;
  const Register kFieldReg = InitStaticFieldABI::kFieldReg;
  const Register kAddressReg = InitLateStaticFieldInternalRegs::kAddressReg;
  const Register kScratchReg = InitLateStaticFieldInternalRegs::kScratchReg;

  __ EnterStubFrame();

  __ Comment("Calling initializer function");
  __ PushRegister(kFieldReg);
  __ LoadCompressedFieldFromOffset(
      FUNCTION_REG, kFieldReg, target::Field::initializer_function_offset());
  if (!FLAG_precompiled_mode) {
    __ LoadCompressedFieldFromOffset(CODE_REG, FUNCTION_REG,
                                     target::Function::code_offset());
    // Load a GC-safe value for the arguments descriptor (unused but tagged).
    __ LoadImmediate(ARGS_DESC_REG, 0);
  }
  __ Call(FieldAddress(FUNCTION_REG, target::Function::entry_point_offset()));
  __ MoveRegister(kResultReg, CallingConventions::kReturnReg);
  __ PopRegister(kFieldReg);
  __ LoadStaticFieldAddress(kAddressReg, kFieldReg, kScratchReg);

  Label throw_exception;
  if (is_final) {
    __ Comment("Checking that initializer did not set late final field");
    __ LoadFromOffset(kScratchReg, kAddressReg, 0);
    __ CompareObject(kScratchReg, SentinelObject());
    __ BranchIf(NOT_EQUAL, &throw_exception);
  }

  __ StoreToOffset(kResultReg, kAddressReg, 0);
  __ LeaveStubFrame();
  __ Ret();

  if (is_final) {
#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
    // We are jumping over LeaveStubFrame so restore LR state to match one
    // at the jump point.
    __ set_lr_state(compiler::LRState::OnEntry().EnterFrame());
#endif  // defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
    __ Bind(&throw_exception);
    __ PushObject(NullObject());  // Make room for (unused) result.
    __ PushRegister(kFieldReg);
    __ CallRuntime(kLateFieldAssignedDuringInitializationErrorRuntimeEntry,
                   /*argument_count=*/1);
    __ Breakpoint();
  }
}

void StubCodeCompiler::GenerateInitLateStaticFieldStub() {
  GenerateInitLateStaticFieldStub(/*is_final=*/false);
}

void StubCodeCompiler::GenerateInitLateFinalStaticFieldStub() {
  GenerateInitLateStaticFieldStub(/*is_final=*/true);
}

void StubCodeCompiler::GenerateInitInstanceFieldStub() {
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make room for result.
  __ PushRegistersInOrder(
      {InitInstanceFieldABI::kInstanceReg, InitInstanceFieldABI::kFieldReg});
  __ CallRuntime(kInitInstanceFieldRuntimeEntry, /*argument_count=*/2);
  __ Drop(2);
  __ PopRegister(InitInstanceFieldABI::kResultReg);
  __ LeaveStubFrame();
  __ Ret();
}

void StubCodeCompiler::GenerateInitLateInstanceFieldStub(bool is_final) {
  const Register kInstanceReg = InitInstanceFieldABI::kInstanceReg;
  const Register kFieldReg = InitInstanceFieldABI::kFieldReg;
  const Register kAddressReg = InitLateInstanceFieldInternalRegs::kAddressReg;
  const Register kScratchReg = InitLateInstanceFieldInternalRegs::kScratchReg;

  __ EnterStubFrame();
  // Save kFieldReg and kInstanceReg for later.
  // Call initializer function.
  __ PushRegistersInOrder({kFieldReg, kInstanceReg, kInstanceReg});

  static_assert(
      InitInstanceFieldABI::kResultReg == CallingConventions::kReturnReg,
      "Result is a return value from initializer");

  __ LoadCompressedFieldFromOffset(
      FUNCTION_REG, InitInstanceFieldABI::kFieldReg,
      target::Field::initializer_function_offset());
  if (!FLAG_precompiled_mode) {
    __ LoadCompressedFieldFromOffset(CODE_REG, FUNCTION_REG,
                                     target::Function::code_offset());
    // Load a GC-safe value for the arguments descriptor (unused but tagged).
    __ LoadImmediate(ARGS_DESC_REG, 0);
  }
  __ Call(FieldAddress(FUNCTION_REG, target::Function::entry_point_offset()));
  __ Drop(1);  // Drop argument.

  __ PopRegisterPair(kInstanceReg, kFieldReg);
  __ LoadCompressedFieldFromOffset(
      kScratchReg, kFieldReg, target::Field::host_offset_or_field_id_offset());
#if defined(DART_COMPRESSED_POINTERS)
  // TODO(compressed-pointers): Variant of LoadFieldAddressForRegOffset that
  // ignores upper bits?
  __ SmiUntag(kScratchReg);
  __ SmiTag(kScratchReg);
#endif
  __ LoadCompressedFieldAddressForRegOffset(kAddressReg, kInstanceReg,
                                            kScratchReg);

  Label throw_exception;
  if (is_final) {
    __ LoadCompressed(kScratchReg, Address(kAddressReg, 0));
    __ CompareObject(kScratchReg, SentinelObject());
    __ BranchIf(NOT_EQUAL, &throw_exception);
  }

#if defined(TARGET_ARCH_IA32)
  // On IA32 StoreIntoObject clobbers value register, so scratch
  // register is used in StoreIntoObject to preserve kResultReg.
  __ MoveRegister(kScratchReg, InitInstanceFieldABI::kResultReg);
  __ StoreIntoObject(kInstanceReg, Address(kAddressReg, 0), kScratchReg);
#else
  __ StoreCompressedIntoObject(kInstanceReg, Address(kAddressReg, 0),
                               InitInstanceFieldABI::kResultReg);
#endif  // defined(TARGET_ARCH_IA32)

  __ LeaveStubFrame();
  __ Ret();

  if (is_final) {
#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
    // We are jumping over LeaveStubFrame so restore LR state to match one
    // at the jump point.
    __ set_lr_state(compiler::LRState::OnEntry().EnterFrame());
#endif  // defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
    __ Bind(&throw_exception);
    __ PushObject(NullObject());  // Make room for (unused) result.
    __ PushRegister(kFieldReg);
    __ CallRuntime(kLateFieldAssignedDuringInitializationErrorRuntimeEntry,
                   /*argument_count=*/1);
    __ Breakpoint();
  }
}

void StubCodeCompiler::GenerateInitLateInstanceFieldStub() {
  GenerateInitLateInstanceFieldStub(/*is_final=*/false);
}

void StubCodeCompiler::GenerateInitLateFinalInstanceFieldStub() {
  GenerateInitLateInstanceFieldStub(/*is_final=*/true);
}

void StubCodeCompiler::GenerateThrowStub() {
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make room for (unused) result.
  __ PushRegister(ThrowABI::kExceptionReg);
  __ CallRuntime(kThrowRuntimeEntry, /*argument_count=*/1);
  __ Breakpoint();
}

void StubCodeCompiler::GenerateReThrowStub() {
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make room for (unused) result.
  __ PushRegistersInOrder(
      {ReThrowABI::kExceptionReg, ReThrowABI::kStackTraceReg});
  __ CallRuntime(kReThrowRuntimeEntry, /*argument_count=*/2);
  __ Breakpoint();
}

void StubCodeCompiler::GenerateAssertBooleanStub() {
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make room for (unused) result.
  __ PushRegister(AssertBooleanABI::kObjectReg);
  __ CallRuntime(kNonBoolTypeErrorRuntimeEntry, /*argument_count=*/1);
  __ Breakpoint();
}

void StubCodeCompiler::GenerateAssertSubtypeStub() {
  __ EnterStubFrame();
  __ PushRegistersInOrder({AssertSubtypeABI::kInstantiatorTypeArgumentsReg,
                           AssertSubtypeABI::kFunctionTypeArgumentsReg,
                           AssertSubtypeABI::kSubTypeReg,
                           AssertSubtypeABI::kSuperTypeReg,
                           AssertSubtypeABI::kDstNameReg});
  __ CallRuntime(kSubtypeCheckRuntimeEntry, /*argument_count=*/5);
  __ Drop(5);  // Drop unused result as well as arguments.
  __ LeaveStubFrame();
  __ Ret();
}

void StubCodeCompiler::GenerateAssertAssignableStub() {
#if !defined(TARGET_ARCH_IA32)
  __ Breakpoint();
#else
  __ EnterStubFrame();
  __ PushObject(Object::null_object());  // Make room for the result.
  __ pushl(Address(
      EBP, target::kWordSize * AssertAssignableStubABI::kInstanceSlotFromFp));
  __ pushl(Address(
      EBP, target::kWordSize * AssertAssignableStubABI::kDstTypeSlotFromFp));
  __ pushl(Address(
      EBP,
      target::kWordSize * AssertAssignableStubABI::kInstantiatorTAVSlotFromFp));
  __ pushl(Address(EBP, target::kWordSize *
                            AssertAssignableStubABI::kFunctionTAVSlotFromFp));
  __ PushRegistersInOrder({AssertAssignableStubABI::kDstNameReg,
                           AssertAssignableStubABI::kSubtypeTestReg});
  __ PushObject(Smi::ZoneHandle(Smi::New(kTypeCheckFromInline)));
  __ CallRuntime(kTypeCheckRuntimeEntry, /*argument_count=*/7);
  __ Drop(8);
  __ LeaveStubFrame();
  __ Ret();
#endif
}

// Instantiate type arguments from instantiator and function type args.
// Inputs:
// - InstantiationABI::kUninstantiatedTypeArgumentsReg: tav to instantiate
// - InstantiationABI::kInstantiatorTypeArgumentsReg: instantiator tav
// - InstantiationABI::kFunctionTypeArgumentsReg: function tav
// Outputs:
// - InstantiationABI::kResultTypeArgumentsReg: instantiated tav
// Clobbers:
// - InstantiationABI::kScratchReg
void StubCodeCompiler::GenerateInstantiateTypeArgumentsStub() {
  // We only need the offset of the current entry up until we either call
  // the runtime or until we retrieve the instantiated type arguments out of it
  // to put in the result register, so we use the result register to store it.
  const Register kEntryReg = InstantiationABI::kResultTypeArgumentsReg;

  // The registers that need spilling prior to traversing a hash-based cache.
  const RegisterSet saved_registers(InstantiateTAVInternalRegs::kSavedRegisters,
                                    /*fpu_register_mask=*/0);

  static_assert(((1 << InstantiationABI::kInstantiatorTypeArgumentsReg) &
                 InstantiateTAVInternalRegs::kSavedRegisters) == 0,
                "Must handle possibility of inst tav reg being spilled");
  static_assert(((1 << InstantiationABI::kFunctionTypeArgumentsReg) &
                 InstantiateTAVInternalRegs::kSavedRegisters) == 0,
                "Must handle possibility of function tav reg being spilled");

  // Takes labels for the cache hit/miss cases (to allow for restoring spilled
  // registers).
  auto check_entry = [&](compiler::Label* found, compiler::Label* not_found) {
    __ Comment("Check cache entry");
    // Use load-acquire to get the entry.
    static_assert(TypeArguments::Cache::kSentinelIndex ==
                      TypeArguments::Cache::kInstantiatorTypeArgsIndex,
                  "sentinel is not same index as instantiator type args");
    __ LoadAcquireCompressed(InstantiationABI::kScratchReg, kEntryReg,
                             TypeArguments::Cache::kInstantiatorTypeArgsIndex *
                                 target::kCompressedWordSize);
    // Test for an unoccupied entry by checking for the Smi sentinel.
    __ BranchIfSmi(InstantiationABI::kScratchReg, not_found);
    // Otherwise it must be occupied and contain TypeArguments objects.
    compiler::Label next;
    __ CompareRegisters(InstantiationABI::kScratchReg,
                        InstantiationABI::kInstantiatorTypeArgumentsReg);
    __ BranchIf(NOT_EQUAL, &next, compiler::Assembler::kNearJump);
    __ LoadCompressed(
        InstantiationABI::kScratchReg,
        compiler::Address(kEntryReg,
                          TypeArguments::Cache::kFunctionTypeArgsIndex *
                              target::kCompressedWordSize));
    __ CompareRegisters(InstantiationABI::kScratchReg,
                        InstantiationABI::kFunctionTypeArgumentsReg);
    __ BranchIf(EQUAL, found);
    __ Bind(&next);
  };

  // Lookup cache before calling runtime.
  __ LoadCompressed(
      InstantiationABI::kScratchReg,
      compiler::FieldAddress(InstantiationABI::kUninstantiatedTypeArgumentsReg,
                             target::TypeArguments::instantiations_offset()));
  // Go ahead and load the backing array data address into kEntryReg.
  __ LoadFieldAddressForOffset(kEntryReg, InstantiationABI::kScratchReg,
                               target::Array::data_offset());

  compiler::Label linear_cache_loop, hash_cache_search, cache_hit, call_runtime;

  // There is a maximum size for linear caches that is smaller than the size
  // of any hash-based cache, so we check the size of the backing array to
  // determine if this is a linear or hash-based cache.
  __ LoadFromSlot(InstantiationABI::kScratchReg, InstantiationABI::kScratchReg,
                  Slot::Array_length());
  __ CompareImmediate(
      InstantiationABI::kScratchReg,
      target::ToRawSmi(TypeArguments::Cache::kMaxLinearCacheSize));
#if defined(TARGET_ARCH_IA32)
  // We just don't have enough registers to do hash-based cache searching in a
  // way that doesn't overly complicate the generation code, so just go to
  // runtime.
  __ BranchIf(GREATER, &call_runtime);
#else
  __ BranchIf(GREATER, &hash_cache_search);
#endif

  __ Comment("Check linear cache");
  // Move kEntryReg to the start of the first entry.
  __ AddImmediate(kEntryReg, TypeArguments::Cache::kHeaderSize *
                                 target::kCompressedWordSize);
  __ Bind(&linear_cache_loop);
  check_entry(&cache_hit, &call_runtime);
  __ AddImmediate(kEntryReg, TypeArguments::Cache::kEntrySize *
                                 target::kCompressedWordSize);
  __ Jump(&linear_cache_loop, compiler::Assembler::kNearJump);

#if !defined(TARGET_ARCH_IA32)
  __ Bind(&hash_cache_search);
  __ Comment("Check hash-based cache");

  compiler::Label pop_before_success, pop_before_failure;
  if (!saved_registers.IsEmpty()) {
    __ Comment("Spills due to register pressure");
    __ PushRegisters(saved_registers);
  }

  __ Comment("Calculate address of first entry");
  __ AddImmediate(
      InstantiateTAVInternalRegs::kEntryStartReg, kEntryReg,
      TypeArguments::Cache::kHeaderSize * target::kCompressedWordSize);

  __ Comment("Calculate probe mask");
  __ LoadAcquireCompressed(
      InstantiationABI::kScratchReg, kEntryReg,
      TypeArguments::Cache::kMetadataIndex * target::kCompressedWordSize);
  __ LsrImmediate(
      InstantiationABI::kScratchReg,
      TypeArguments::Cache::EntryCountLog2Bits::shift() + kSmiTagShift);
  __ LoadImmediate(InstantiateTAVInternalRegs::kProbeMaskReg, 1);
  __ LslRegister(InstantiateTAVInternalRegs::kProbeMaskReg,
                 InstantiationABI::kScratchReg);
  __ AddImmediate(InstantiateTAVInternalRegs::kProbeMaskReg, -1);
  // Can use kEntryReg as scratch now until we're entering the loop.

  // Retrieve the hash from the TAV. If the retrieved hash is 0, jumps to
  // not_found, otherwise falls through.
  auto retrieve_hash = [&](Register dst, Register src) {
    Label is_not_null, done;
    __ CompareObject(src, NullObject());
    __ BranchIf(NOT_EQUAL, &is_not_null, compiler::Assembler::kNearJump);
    __ LoadImmediate(dst, TypeArguments::kAllDynamicHash);
    __ Jump(&done, compiler::Assembler::kNearJump);
    __ Bind(&is_not_null);
    __ LoadFromSlot(dst, src, Slot::TypeArguments_hash());
    __ SmiUntag(dst);
    // If the retrieved hash is 0, then it hasn't been computed yet.
    __ BranchIfZero(dst, &pop_before_failure);
    __ Bind(&done);
  };

  __ Comment("Calculate initial probe from type argument vector hashes");
  retrieve_hash(InstantiateTAVInternalRegs::kCurrentEntryIndexReg,
                InstantiationABI::kInstantiatorTypeArgumentsReg);
  retrieve_hash(InstantiationABI::kScratchReg,
                InstantiationABI::kFunctionTypeArgumentsReg);
  __ CombineHashes(InstantiateTAVInternalRegs::kCurrentEntryIndexReg,
                   InstantiationABI::kScratchReg);
  __ FinalizeHash(InstantiateTAVInternalRegs::kCurrentEntryIndexReg,
                  InstantiationABI::kScratchReg);
  // Use the probe mask to get a valid entry index.
  __ AndRegisters(InstantiateTAVInternalRegs::kCurrentEntryIndexReg,
                  InstantiateTAVInternalRegs::kProbeMaskReg);

  // Start off the probing distance at zero (will increment prior to use).
  __ LoadImmediate(InstantiateTAVInternalRegs::kProbeDistanceReg, 0);

  compiler::Label loop;
  __ Bind(&loop);
  __ Comment("Loop over hash cache entries");
  // Convert the current entry index into the entry address.
  __ MoveRegister(kEntryReg, InstantiateTAVInternalRegs::kCurrentEntryIndexReg);
  __ MulImmediate(kEntryReg, TypeArguments::Cache::kEntrySize *
                                 target::kCompressedWordSize);
  __ AddRegisters(kEntryReg, InstantiateTAVInternalRegs::kEntryStartReg);
  check_entry(&pop_before_success, &pop_before_failure);
  // Increment the probing distance and then add it to the current entry
  // index, then mask the result with the probe mask.
  __ AddImmediate(InstantiateTAVInternalRegs::kProbeDistanceReg, 1);
  __ AddRegisters(InstantiateTAVInternalRegs::kCurrentEntryIndexReg,
                  InstantiateTAVInternalRegs::kProbeDistanceReg);
  __ AndRegisters(InstantiateTAVInternalRegs::kCurrentEntryIndexReg,
                  InstantiateTAVInternalRegs::kProbeMaskReg);
  __ Jump(&loop);

  __ Bind(&pop_before_failure);
  if (!saved_registers.IsEmpty()) {
    __ Comment("Restore spilled registers on cache miss");
    __ PopRegisters(saved_registers);
  }
#endif

  // Instantiate non-null type arguments.
  // A runtime call to instantiate the type arguments is required.
  __ Bind(&call_runtime);
  __ Comment("Cache miss");
  __ EnterStubFrame();
#if !defined(DART_ASSEMBLER_HAS_NULL_REG)
  __ PushObject(Object::null_object());  // Make room for the result.
#endif
#if defined(TARGET_ARCH_ARM)
  static_assert((InstantiationABI::kUninstantiatedTypeArgumentsReg >
                 InstantiationABI::kInstantiatorTypeArgumentsReg) &&
                    (InstantiationABI::kInstantiatorTypeArgumentsReg >
                     InstantiationABI::kFunctionTypeArgumentsReg),
                "Should be ordered to push arguments with one instruction");
#endif
  __ PushRegistersInOrder({
#if defined(DART_ASSEMBLER_HAS_NULL_REG)
    NULL_REG,
#endif
        InstantiationABI::kUninstantiatedTypeArgumentsReg,
        InstantiationABI::kInstantiatorTypeArgumentsReg,
        InstantiationABI::kFunctionTypeArgumentsReg,
  });
  __ CallRuntime(kInstantiateTypeArgumentsRuntimeEntry, 3);
  __ Drop(3);  // Drop 2 type vectors, and uninstantiated type.
  __ PopRegister(InstantiationABI::kResultTypeArgumentsReg);
  __ LeaveStubFrame();
  __ Ret();

#if !defined(TARGET_ARCH_IA32)
  __ Bind(&pop_before_success);
  if (!saved_registers.IsEmpty()) {
    __ Comment("Restore spilled registers on cache hit");
    __ PopRegisters(saved_registers);
  }
#endif

  __ Bind(&cache_hit);
  __ Comment("Cache hit");
  __ LoadCompressed(
      InstantiationABI::kResultTypeArgumentsReg,
      compiler::Address(kEntryReg,
                        TypeArguments::Cache::kInstantiatedTypeArgsIndex *
                            target::kCompressedWordSize));
  __ Ret();
}

void StubCodeCompiler::
    GenerateInstantiateTypeArgumentsMayShareInstantiatorTAStub() {
  const Register kScratch1Reg = InstantiationABI::kResultTypeArgumentsReg;
  const Register kScratch2Reg = InstantiationABI::kScratchReg;
  // Return the instantiator type arguments if its nullability is compatible for
  // sharing, otherwise proceed to instantiation cache lookup.
  compiler::Label cache_lookup;
  __ LoadCompressedSmi(
      kScratch1Reg,
      compiler::FieldAddress(InstantiationABI::kUninstantiatedTypeArgumentsReg,
                             target::TypeArguments::nullability_offset()));
  __ LoadCompressedSmi(
      kScratch2Reg,
      compiler::FieldAddress(InstantiationABI::kInstantiatorTypeArgumentsReg,
                             target::TypeArguments::nullability_offset()));
  __ AndRegisters(kScratch2Reg, kScratch1Reg);
  __ CompareRegisters(kScratch2Reg, kScratch1Reg);
  __ BranchIf(NOT_EQUAL, &cache_lookup, compiler::Assembler::kNearJump);
  __ MoveRegister(InstantiationABI::kResultTypeArgumentsReg,
                  InstantiationABI::kInstantiatorTypeArgumentsReg);
  __ Ret();

  __ Bind(&cache_lookup);
  GenerateInstantiateTypeArgumentsStub();
}

void StubCodeCompiler::
    GenerateInstantiateTypeArgumentsMayShareFunctionTAStub() {
  const Register kScratch1Reg = InstantiationABI::kResultTypeArgumentsReg;
  const Register kScratch2Reg = InstantiationABI::kScratchReg;
  // Return the function type arguments if its nullability is compatible for
  // sharing, otherwise proceed to instantiation cache lookup.
  compiler::Label cache_lookup;
  __ LoadCompressedSmi(
      kScratch1Reg,
      compiler::FieldAddress(InstantiationABI::kUninstantiatedTypeArgumentsReg,
                             target::TypeArguments::nullability_offset()));
  __ LoadCompressedSmi(
      kScratch2Reg,
      compiler::FieldAddress(InstantiationABI::kFunctionTypeArgumentsReg,
                             target::TypeArguments::nullability_offset()));
  __ AndRegisters(kScratch2Reg, kScratch1Reg);
  __ CompareRegisters(kScratch2Reg, kScratch1Reg);
  __ BranchIf(NOT_EQUAL, &cache_lookup, compiler::Assembler::kNearJump);
  __ MoveRegister(InstantiationABI::kResultTypeArgumentsReg,
                  InstantiationABI::kFunctionTypeArgumentsReg);
  __ Ret();

  __ Bind(&cache_lookup);
  GenerateInstantiateTypeArgumentsStub();
}

static void BuildInstantiateTypeRuntimeCall(Assembler* assembler) {
  __ EnterStubFrame();
  __ PushObject(Object::null_object());
  __ PushRegistersInOrder({InstantiateTypeABI::kTypeReg,
                           InstantiateTypeABI::kInstantiatorTypeArgumentsReg,
                           InstantiateTypeABI::kFunctionTypeArgumentsReg});
  __ CallRuntime(kInstantiateTypeRuntimeEntry, /*argument_count=*/3);
  __ Drop(3);
  __ PopRegister(InstantiateTypeABI::kResultTypeReg);
  __ LeaveStubFrame();
  __ Ret();
}

static void BuildInstantiateTypeParameterStub(Assembler* assembler,
                                              Nullability nullability,
                                              bool is_function_parameter) {
  Label runtime_call, return_dynamic, type_parameter_value_is_not_type;

  if (is_function_parameter) {
    __ CompareObject(InstantiateTypeABI::kFunctionTypeArgumentsReg,
                     TypeArguments::null_object());
    __ BranchIf(EQUAL, &return_dynamic);
    __ LoadFieldFromOffset(
        InstantiateTypeABI::kResultTypeReg, InstantiateTypeABI::kTypeReg,
        target::TypeParameter::index_offset(), kUnsignedTwoBytes);
    __ LoadIndexedCompressed(InstantiateTypeABI::kResultTypeReg,
                             InstantiateTypeABI::kFunctionTypeArgumentsReg,
                             target::TypeArguments::types_offset(),
                             InstantiateTypeABI::kResultTypeReg);
  } else {
    __ CompareObject(InstantiateTypeABI::kInstantiatorTypeArgumentsReg,
                     TypeArguments::null_object());
    __ BranchIf(EQUAL, &return_dynamic);
    __ LoadFieldFromOffset(
        InstantiateTypeABI::kResultTypeReg, InstantiateTypeABI::kTypeReg,
        target::TypeParameter::index_offset(), kUnsignedTwoBytes);
    __ LoadIndexedCompressed(InstantiateTypeABI::kResultTypeReg,
                             InstantiateTypeABI::kInstantiatorTypeArgumentsReg,
                             target::TypeArguments::types_offset(),
                             InstantiateTypeABI::kResultTypeReg);
  }

  __ LoadClassId(InstantiateTypeABI::kScratchReg,
                 InstantiateTypeABI::kResultTypeReg);

  switch (nullability) {
    case Nullability::kNonNullable:
      __ Ret();
      break;
    case Nullability::kNullable:
      __ CompareAbstractTypeNullabilityWith(
          InstantiateTypeABI::kResultTypeReg,
          static_cast<int8_t>(Nullability::kNullable),
          InstantiateTypeABI::kScratchReg);
      __ BranchIf(NOT_EQUAL, &runtime_call);
      __ Ret();
      break;
    case Nullability::kLegacy:
      __ CompareAbstractTypeNullabilityWith(
          InstantiateTypeABI::kResultTypeReg,
          static_cast<int8_t>(Nullability::kNonNullable),
          InstantiateTypeABI::kScratchReg);
      __ BranchIf(EQUAL, &runtime_call);
      __ Ret();
  }

  // The TAV was null, so the value of the type parameter is "dynamic".
  __ Bind(&return_dynamic);
  __ LoadObject(InstantiateTypeABI::kResultTypeReg, Type::dynamic_type());
  __ Ret();

  __ Bind(&runtime_call);
  BuildInstantiateTypeRuntimeCall(assembler);
}

void StubCodeCompiler::
    GenerateInstantiateTypeNonNullableClassTypeParameterStub() {
  BuildInstantiateTypeParameterStub(assembler, Nullability::kNonNullable,
                                    /*is_function_parameter=*/false);
}

void StubCodeCompiler::GenerateInstantiateTypeNullableClassTypeParameterStub() {
  BuildInstantiateTypeParameterStub(assembler, Nullability::kNullable,
                                    /*is_function_parameter=*/false);
}

void StubCodeCompiler::GenerateInstantiateTypeLegacyClassTypeParameterStub() {
  BuildInstantiateTypeParameterStub(assembler, Nullability::kLegacy,
                                    /*is_function_parameter=*/false);
}

void StubCodeCompiler::
    GenerateInstantiateTypeNonNullableFunctionTypeParameterStub() {
  BuildInstantiateTypeParameterStub(assembler, Nullability::kNonNullable,
                                    /*is_function_parameter=*/true);
}

void StubCodeCompiler::
    GenerateInstantiateTypeNullableFunctionTypeParameterStub() {
  BuildInstantiateTypeParameterStub(assembler, Nullability::kNullable,
                                    /*is_function_parameter=*/true);
}

void StubCodeCompiler::
    GenerateInstantiateTypeLegacyFunctionTypeParameterStub() {
  BuildInstantiateTypeParameterStub(assembler, Nullability::kLegacy,
                                    /*is_function_parameter=*/true);
}

void StubCodeCompiler::GenerateInstantiateTypeStub() {
  BuildInstantiateTypeRuntimeCall(assembler);
}

void StubCodeCompiler::GenerateInstanceOfStub() {
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make room for the result.
  __ PushRegistersInOrder({TypeTestABI::kInstanceReg, TypeTestABI::kDstTypeReg,
                           TypeTestABI::kInstantiatorTypeArgumentsReg,
                           TypeTestABI::kFunctionTypeArgumentsReg,
                           TypeTestABI::kSubtypeTestCacheReg});
  __ CallRuntime(kInstanceofRuntimeEntry, /*argument_count=*/5);
  __ Drop(5);
  __ PopRegister(TypeTestABI::kInstanceOfResultReg);
  __ LeaveStubFrame();
  __ Ret();
}

// For use in GenerateTypeIsTopTypeForSubtyping and
// GenerateNullIsAssignableToType.
static void EnsureIsTypeOrFunctionTypeOrTypeParameter(Assembler* assembler,
                                                      Register type_reg,
                                                      Register scratch_reg) {
#if defined(DEBUG)
  compiler::Label is_type_param_or_type_or_function_type;
  __ LoadClassIdMayBeSmi(scratch_reg, type_reg);
  __ CompareImmediate(scratch_reg, kTypeParameterCid);
  __ BranchIf(EQUAL, &is_type_param_or_type_or_function_type,
              compiler::Assembler::kNearJump);
  __ CompareImmediate(scratch_reg, kTypeCid);
  __ BranchIf(EQUAL, &is_type_param_or_type_or_function_type,
              compiler::Assembler::kNearJump);
  __ CompareImmediate(scratch_reg, kFunctionTypeCid);
  __ BranchIf(EQUAL, &is_type_param_or_type_or_function_type,
              compiler::Assembler::kNearJump);
  __ Stop("not a type or function type or type parameter");
  __ Bind(&is_type_param_or_type_or_function_type);
#endif
}

// Version of AbstractType::IsTopTypeForSubtyping() used when the type is not
// known at compile time. Must be kept in sync.
//
// Inputs:
// - TypeTestABI::kDstTypeReg: Destination type.
//
// Non-preserved scratch registers:
// - TypeTestABI::kScratchReg (only on non-IA32 architectures)
//
// Outputs:
// - TypeTestABI::kSubtypeTestCacheReg: 0 if the value is guaranteed assignable,
//   non-zero otherwise.
//
// All registers other than outputs and non-preserved scratches are preserved.
static void GenerateTypeIsTopTypeForSubtyping(Assembler* assembler,
                                              bool null_safety) {
  // The only case where the original value of kSubtypeTestCacheReg is needed
  // after the stub call is on IA32, where it's currently preserved on the stack
  // before calling the stub (as it's also CODE_REG on that architecture), so we
  // both use it as a scratch and clobber it for the return value.
  const Register scratch1_reg = TypeTestABI::kSubtypeTestCacheReg;
  // We reuse the first scratch register as the output register because we're
  // always guaranteed to have a type in it (starting with kDstType), and all
  // non-Smi ObjectPtrs are non-zero values.
  const Register output_reg = scratch1_reg;
#if defined(TARGET_ARCH_IA32)
  // The remaining scratch registers are preserved and restored before exit on
  // IA32. Because  we have few registers to choose from (which are all used in
  // TypeTestABI), use specific TestTypeABI registers.
  const Register scratch2_reg = TypeTestABI::kFunctionTypeArgumentsReg;
  // Preserve non-output scratch registers.
  __ PushRegister(scratch2_reg);
#else
  const Register scratch2_reg = TypeTestABI::kScratchReg;
#endif
  static_assert(scratch1_reg != scratch2_reg,
                "both scratch registers are the same");

  compiler::Label check_top_type, is_top_type, done;
  // Initialize scratch1_reg with the type to check (which also sets the
  // output register to a non-zero value). scratch1_reg (and thus the output
  // register) will always have a type in it from here on out.
  __ MoveRegister(scratch1_reg, TypeTestABI::kDstTypeReg);
  __ Bind(&check_top_type);
  // scratch1_reg: Current type to check.
  EnsureIsTypeOrFunctionTypeOrTypeParameter(assembler, scratch1_reg,
                                            scratch2_reg);
  compiler::Label is_type_ref;
  __ CompareClassId(scratch1_reg, kTypeCid, scratch2_reg);
  // Type parameters can't be top types themselves, though a particular
  // instantiation may result in a top type.
  // Function types cannot be top types.
  __ BranchIf(NOT_EQUAL, &done);
  __ LoadTypeClassId(scratch2_reg, scratch1_reg);
  __ CompareImmediate(scratch2_reg, kDynamicCid);
  __ BranchIf(EQUAL, &is_top_type, compiler::Assembler::kNearJump);
  __ CompareImmediate(scratch2_reg, kVoidCid);
  __ BranchIf(EQUAL, &is_top_type, compiler::Assembler::kNearJump);
  compiler::Label unwrap_future_or;
  __ CompareImmediate(scratch2_reg, kFutureOrCid);
  __ BranchIf(EQUAL, &unwrap_future_or, compiler::Assembler::kNearJump);
  __ CompareImmediate(scratch2_reg, kInstanceCid);
  __ BranchIf(NOT_EQUAL, &done, compiler::Assembler::kNearJump);
  if (null_safety) {
    // Instance type isn't a top type if non-nullable in null safe mode.
    __ CompareAbstractTypeNullabilityWith(
        scratch1_reg, static_cast<int8_t>(Nullability::kNonNullable),
        scratch2_reg);
    __ BranchIf(EQUAL, &done, compiler::Assembler::kNearJump);
  }
  __ Bind(&is_top_type);
  __ LoadImmediate(output_reg, 0);
  __ Bind(&done);
#if defined(TARGET_ARCH_IA32)
  // Restore preserved scratch registers.
  __ PopRegister(scratch2_reg);
#endif
  __ Ret();
  // An uncommon case, so off the main trunk of the function.
  __ Bind(&unwrap_future_or);
  __ LoadCompressedField(
      scratch2_reg,
      compiler::FieldAddress(scratch1_reg,
                             compiler::target::Type::arguments_offset()));
  __ CompareObject(scratch2_reg, Object::null_object());
  // If the arguments are null, then unwrapping gives dynamic, a top type.
  __ BranchIf(EQUAL, &is_top_type, compiler::Assembler::kNearJump);
  __ LoadCompressedField(
      scratch1_reg,
      compiler::FieldAddress(
          scratch2_reg, compiler::target::TypeArguments::type_at_offset(0)));
  __ Jump(&check_top_type, compiler::Assembler::kNearJump);
}

void StubCodeCompiler::GenerateTypeIsTopTypeForSubtypingStub() {
  GenerateTypeIsTopTypeForSubtyping(assembler, /*null_safety=*/false);
}

void StubCodeCompiler::GenerateTypeIsTopTypeForSubtypingNullSafeStub() {
  GenerateTypeIsTopTypeForSubtyping(assembler, /*null_safety=*/true);
}

// Version of Instance::NullIsAssignableTo(other, inst_tav, fun_tav) used when
// the destination type was not known at compile time. Must be kept in sync.
//
// Inputs:
// - TypeTestABI::kInstanceReg: Object to check for assignability.
// - TypeTestABI::kDstTypeReg: Destination type.
// - TypeTestABI::kInstantiatorTypeArgumentsReg: Instantiator TAV.
// - TypeTestABI::kFunctionTypeArgumentsReg: Function TAV.
//
// Non-preserved non-output scratch registers:
// - TypeTestABI::kScratchReg (only on non-IA32 architectures)
//
// Outputs:
// - TypeTestABI::kSubtypeTestCacheReg: 0 if the value is guaranteed assignable,
//   non-zero otherwise.
//
// All registers other than outputs and non-preserved scratches are preserved.
static void GenerateNullIsAssignableToType(Assembler* assembler,
                                           bool null_safety) {
  // The only case where the original value of kSubtypeTestCacheReg is needed
  // after the stub call is on IA32, where it's currently preserved on the stack
  // before calling the stub (as it's also CODE_REG on that architecture), so we
  // both use it as a scratch to hold the current type to inspect and also
  // clobber it for the return value.
  const Register kCurrentTypeReg = TypeTestABI::kSubtypeTestCacheReg;
  // We reuse the first scratch register as the output register because we're
  // always guaranteed to have a type in it (starting with the contents of
  // kDstTypeReg), and all non-Smi ObjectPtrs are non-zero values.
  const Register kOutputReg = kCurrentTypeReg;
#if defined(TARGET_ARCH_IA32)
  // The remaining scratch registers are preserved and restored before exit on
  // IA32. Because  we have few registers to choose from (which are all used in
  // TypeTestABI), use specific TestTypeABI registers.
  const Register kScratchReg = TypeTestABI::kFunctionTypeArgumentsReg;
  // Preserve non-output scratch registers.
  __ PushRegister(kScratchReg);
#else
  const Register kScratchReg = TypeTestABI::kScratchReg;
#endif
  static_assert(kCurrentTypeReg != kScratchReg,
                "code assumes distinct scratch registers");

  compiler::Label is_assignable, done;
  // Initialize the first scratch register (and thus the output register) with
  // the destination type. We do this before the check to ensure the output
  // register has a non-zero value if !null_safety and kInstanceReg is not null.
  __ MoveRegister(kCurrentTypeReg, TypeTestABI::kDstTypeReg);
  __ CompareObject(TypeTestABI::kInstanceReg, Object::null_object());
  if (null_safety) {
    compiler::Label check_null_assignable;
    // Skip checking the type if not null.
    __ BranchIf(NOT_EQUAL, &done);
    __ Bind(&check_null_assignable);
    // scratch1_reg: Current type to check.
    EnsureIsTypeOrFunctionTypeOrTypeParameter(assembler, kCurrentTypeReg,
                                              kScratchReg);
    compiler::Label is_not_type;
    __ CompareClassId(kCurrentTypeReg, kTypeCid, kScratchReg);
    __ BranchIf(NOT_EQUAL, &is_not_type, compiler::Assembler::kNearJump);
    __ CompareAbstractTypeNullabilityWith(
        kCurrentTypeReg, static_cast<int8_t>(Nullability::kNonNullable),
        kScratchReg);
    __ BranchIf(NOT_EQUAL, &is_assignable);
    // FutureOr is a special case because it may have the non-nullable bit set,
    // but FutureOr<T> functions as the union of T and Future<T>, so it must be
    // unwrapped to see if T is nullable.
    __ LoadTypeClassId(kScratchReg, kCurrentTypeReg);
    __ CompareImmediate(kScratchReg, kFutureOrCid);
    __ BranchIf(NOT_EQUAL, &done);
    __ LoadCompressedField(
        kScratchReg,
        compiler::FieldAddress(kCurrentTypeReg,
                               compiler::target::Type::arguments_offset()));
    __ CompareObject(kScratchReg, Object::null_object());
    // If the arguments are null, then unwrapping gives the dynamic type,
    // which can take null.
    __ BranchIf(EQUAL, &is_assignable);
    __ LoadCompressedField(
        kCurrentTypeReg,
        compiler::FieldAddress(
            kScratchReg, compiler::target::TypeArguments::type_at_offset(0)));
    __ Jump(&check_null_assignable, compiler::Assembler::kNearJump);
    __ Bind(&is_not_type);
    // Null is assignable to a type parameter only if it is nullable or if the
    // instantiation is nullable.
    __ CompareAbstractTypeNullabilityWith(
        kCurrentTypeReg, static_cast<int8_t>(Nullability::kNonNullable),
        kScratchReg);
    __ BranchIf(NOT_EQUAL, &is_assignable);

    // Don't set kScratchReg in here as on IA32, that's the function TAV reg.
    auto handle_case = [&](Register tav) {
      // We can reuse kCurrentTypeReg to hold the index because we no longer
      // need the type parameter afterwards.
      auto const kIndexReg = kCurrentTypeReg;
      // If the TAV is null, resolving gives the (nullable) dynamic type.
      __ CompareObject(tav, NullObject());
      __ BranchIf(EQUAL, &is_assignable, Assembler::kNearJump);
      // Resolve the type parameter to its instantiated type and loop.
      __ LoadFieldFromOffset(kIndexReg, kCurrentTypeReg,
                             target::TypeParameter::index_offset(),
                             kUnsignedTwoBytes);
      __ LoadIndexedCompressed(kCurrentTypeReg, tav,
                               target::TypeArguments::types_offset(),
                               kIndexReg);
      __ Jump(&check_null_assignable);
    };

    Label function_type_param;
    __ LoadFromSlot(kScratchReg, TypeTestABI::kDstTypeReg,
                    Slot::AbstractType_flags());
    __ BranchIfBit(kScratchReg,
                   target::UntaggedTypeParameter::kIsFunctionTypeParameterBit,
                   NOT_ZERO, &function_type_param, Assembler::kNearJump);
    handle_case(TypeTestABI::kInstantiatorTypeArgumentsReg);
    __ Bind(&function_type_param);
#if defined(TARGET_ARCH_IA32)
    // Function TAV is on top of stack because we're using that register as
    // kScratchReg.
    __ LoadFromStack(TypeTestABI::kFunctionTypeArgumentsReg, 0);
#endif
    handle_case(TypeTestABI::kFunctionTypeArgumentsReg);
  } else {
    // Null in non-null-safe mode is always assignable.
    __ BranchIf(NOT_EQUAL, &done, compiler::Assembler::kNearJump);
  }
  __ Bind(&is_assignable);
  __ LoadImmediate(kOutputReg, 0);
  __ Bind(&done);
#if defined(TARGET_ARCH_IA32)
  // Restore preserved scratch registers.
  __ PopRegister(kScratchReg);
#endif
  __ Ret();
}

void StubCodeCompiler::GenerateNullIsAssignableToTypeStub() {
  GenerateNullIsAssignableToType(assembler, /*null_safety=*/false);
}

void StubCodeCompiler::GenerateNullIsAssignableToTypeNullSafeStub() {
  GenerateNullIsAssignableToType(assembler, /*null_safety=*/true);
}
#if !defined(TARGET_ARCH_IA32)
// The <X>TypeTestStubs are used to test whether a given value is of a given
// type. All variants have the same calling convention:
//
// Inputs (from TypeTestABI struct):
//   - kSubtypeTestCacheReg: RawSubtypeTestCache
//   - kInstanceReg: instance to test against.
//   - kInstantiatorTypeArgumentsReg : instantiator type arguments (if needed).
//   - kFunctionTypeArgumentsReg : function type arguments (if needed).
//
// See GenerateSubtypeNTestCacheStub for registers that may need saving by the
// caller.
//
// Output (from TypeTestABI struct):
//   - kResultReg: checked instance.
//
// Throws if the check is unsuccessful.
//
// Note of warning: The caller will not populate CODE_REG and we have therefore
// no access to the pool.
void StubCodeCompiler::GenerateDefaultTypeTestStub() {
  __ LoadFromOffset(CODE_REG, THR,
                    target::Thread::slow_type_test_stub_offset());
  __ Jump(FieldAddress(CODE_REG, target::Code::entry_point_offset()));
}

// Used instead of DefaultTypeTestStub when null is assignable.
void StubCodeCompiler::GenerateDefaultNullableTypeTestStub() {
  Label done;

  // Fast case for 'null'.
  __ CompareObject(TypeTestABI::kInstanceReg, NullObject());
  __ BranchIf(EQUAL, &done);

  __ LoadFromOffset(CODE_REG, THR,
                    target::Thread::slow_type_test_stub_offset());
  __ Jump(FieldAddress(CODE_REG, target::Code::entry_point_offset()));

  __ Bind(&done);
  __ Ret();
}

void StubCodeCompiler::GenerateTopTypeTypeTestStub() {
  __ Ret();
}

void StubCodeCompiler::GenerateUnreachableTypeTestStub() {
  __ Breakpoint();
}

static void BuildTypeParameterTypeTestStub(Assembler* assembler,
                                           bool allow_null) {
  Label done;

  if (allow_null) {
    __ CompareObject(TypeTestABI::kInstanceReg, NullObject());
    __ BranchIf(EQUAL, &done, Assembler::kNearJump);
  }

  auto handle_case = [&](Register tav) {
    // If the TAV is null, then resolving the type parameter gives the dynamic
    // type, which is a top type.
    __ CompareObject(tav, NullObject());
    __ BranchIf(EQUAL, &done, Assembler::kNearJump);
    // Resolve the type parameter to its instantiated type and tail call the
    // instantiated type's TTS.
    __ LoadFieldFromOffset(TypeTestABI::kScratchReg, TypeTestABI::kDstTypeReg,
                           target::TypeParameter::index_offset(),
                           kUnsignedTwoBytes);
    __ LoadIndexedCompressed(TypeTestABI::kScratchReg, tav,
                             target::TypeArguments::types_offset(),
                             TypeTestABI::kScratchReg);
    __ Jump(FieldAddress(
        TypeTestABI::kScratchReg,
        target::AbstractType::type_test_stub_entry_point_offset()));
  };

  Label function_type_param;
  __ LoadFromSlot(TypeTestABI::kScratchReg, TypeTestABI::kDstTypeReg,
                  Slot::AbstractType_flags());
  __ BranchIfBit(TypeTestABI::kScratchReg,
                 target::UntaggedTypeParameter::kIsFunctionTypeParameterBit,
                 NOT_ZERO, &function_type_param, Assembler::kNearJump);
  handle_case(TypeTestABI::kInstantiatorTypeArgumentsReg);
  __ Bind(&function_type_param);
  handle_case(TypeTestABI::kFunctionTypeArgumentsReg);
  __ Bind(&done);
  __ Ret();
}

void StubCodeCompiler::GenerateNullableTypeParameterTypeTestStub() {
  BuildTypeParameterTypeTestStub(assembler, /*allow_null=*/true);
}

void StubCodeCompiler::GenerateTypeParameterTypeTestStub() {
  BuildTypeParameterTypeTestStub(assembler, /*allow_null=*/false);
}

static void InvokeTypeCheckFromTypeTestStub(Assembler* assembler,
                                            TypeCheckMode mode) {
  __ PushObject(NullObject());  // Make room for result.
  __ PushRegistersInOrder({TypeTestABI::kInstanceReg, TypeTestABI::kDstTypeReg,
                           TypeTestABI::kInstantiatorTypeArgumentsReg,
                           TypeTestABI::kFunctionTypeArgumentsReg});
  __ PushObject(NullObject());
  __ PushRegister(TypeTestABI::kSubtypeTestCacheReg);
  __ PushImmediate(target::ToRawSmi(mode));
  __ CallRuntime(kTypeCheckRuntimeEntry, 7);
  __ Drop(1);  // mode
  __ PopRegister(TypeTestABI::kSubtypeTestCacheReg);
  __ Drop(1);  // dst_name
  __ PopRegister(TypeTestABI::kFunctionTypeArgumentsReg);
  __ PopRegister(TypeTestABI::kInstantiatorTypeArgumentsReg);
  __ PopRegister(TypeTestABI::kDstTypeReg);
  __ PopRegister(TypeTestABI::kInstanceReg);
  __ Drop(1);  // Discard return value.
}

void StubCodeCompiler::GenerateLazySpecializeTypeTestStub() {
  __ LoadFromOffset(CODE_REG, THR,
                    target::Thread::lazy_specialize_type_test_stub_offset());
  __ EnterStubFrame();
  InvokeTypeCheckFromTypeTestStub(assembler, kTypeCheckFromLazySpecializeStub);
  __ LeaveStubFrame();
  __ Ret();
}

// Used instead of LazySpecializeTypeTestStub when null is assignable.
void StubCodeCompiler::GenerateLazySpecializeNullableTypeTestStub() {
  Label done;

  __ CompareObject(TypeTestABI::kInstanceReg, NullObject());
  __ BranchIf(EQUAL, &done);

  __ LoadFromOffset(CODE_REG, THR,
                    target::Thread::lazy_specialize_type_test_stub_offset());
  __ EnterStubFrame();
  InvokeTypeCheckFromTypeTestStub(assembler, kTypeCheckFromLazySpecializeStub);
  __ LeaveStubFrame();

  __ Bind(&done);
  __ Ret();
}

void StubCodeCompiler::GenerateSlowTypeTestStub() {
  Label done, call_runtime;

  if (!FLAG_precompiled_mode) {
    __ LoadFromOffset(CODE_REG, THR,
                      target::Thread::slow_type_test_stub_offset());
  }
  __ EnterStubFrame();

  // If the subtype-cache is null, it needs to be lazily-created by the runtime.
  __ CompareObject(TypeTestABI::kSubtypeTestCacheReg, NullObject());
  __ BranchIf(EQUAL, &call_runtime);

  // Use the number of inputs used by the STC to determine which stub to call.
  Label call_2, call_3, call_4, call_6;
  __ Comment("Check number of STC inputs");
  __ LoadFromSlot(TypeTestABI::kScratchReg, TypeTestABI::kSubtypeTestCacheReg,
                  Slot::SubtypeTestCache_num_inputs());
  __ CompareImmediate(TypeTestABI::kScratchReg, 2);
  __ BranchIf(EQUAL, &call_2, Assembler::kNearJump);
  __ CompareImmediate(TypeTestABI::kScratchReg, 3);
  __ BranchIf(EQUAL, &call_3, Assembler::kNearJump);
  __ CompareImmediate(TypeTestABI::kScratchReg, 4);
  __ BranchIf(EQUAL, &call_4, Assembler::kNearJump);
  __ CompareImmediate(TypeTestABI::kScratchReg, 6);
  __ BranchIf(EQUAL, &call_6, Assembler::kNearJump);
  // Fall through to the all inputs case.

  {
    __ Comment("Call 7 input STC check");
    __ Call(StubCodeSubtype7TestCache());
    __ CompareObject(TypeTestABI::kSubtypeTestCacheResultReg,
                     CastHandle<Object>(TrueObject()));
    __ BranchIf(EQUAL, &done);  // Cache said: yes.
    __ Jump(&call_runtime, Assembler::kNearJump);
  }

  __ Bind(&call_6);
  {
    __ Comment("Call 6 input STC check");
    __ Call(StubCodeSubtype6TestCache());
    __ CompareObject(TypeTestABI::kSubtypeTestCacheResultReg,
                     CastHandle<Object>(TrueObject()));
    __ BranchIf(EQUAL, &done);  // Cache said: yes.
    __ Jump(&call_runtime, Assembler::kNearJump);
  }

  __ Bind(&call_4);
  {
    __ Comment("Call 4 input STC check");
    __ Call(StubCodeSubtype4TestCache());
    __ CompareObject(TypeTestABI::kSubtypeTestCacheResultReg,
                     CastHandle<Object>(TrueObject()));
    __ BranchIf(EQUAL, &done);  // Cache said: yes.
    __ Jump(&call_runtime, Assembler::kNearJump);
  }

  __ Bind(&call_3);
  {
    __ Comment("Call 3 input STC check");
    __ Call(StubCodeSubtype3TestCache());
    __ CompareObject(TypeTestABI::kSubtypeTestCacheResultReg,
                     CastHandle<Object>(TrueObject()));
    __ BranchIf(EQUAL, &done);  // Cache said: yes.
    __ Jump(&call_runtime, Assembler::kNearJump);
  }

  __ Bind(&call_2);
  {
    __ Comment("Call 2 input STC check");
    __ Call(StubCodeSubtype2TestCache());
    __ CompareObject(TypeTestABI::kSubtypeTestCacheResultReg,
                     CastHandle<Object>(TrueObject()));
    __ BranchIf(EQUAL, &done);  // Cache said: yes.
    // Fall through to runtime_call
  }

  __ Bind(&call_runtime);
  __ Comment("Call runtime");

  InvokeTypeCheckFromTypeTestStub(assembler, kTypeCheckFromSlowStub);

  __ Bind(&done);
  __ Comment("Done");
  __ LeaveStubFrame();
  __ Ret();
}
#else
// Type testing stubs are not implemented on IA32.
#define GENERATE_BREAKPOINT_STUB(Name)                                         \
  void StubCodeCompiler::Generate##Name##Stub() {                              \
    __ Breakpoint();                                                           \
  }

VM_TYPE_TESTING_STUB_CODE_LIST(GENERATE_BREAKPOINT_STUB)

#undef GENERATE_BREAKPOINT_STUB
#endif  // !defined(TARGET_ARCH_IA32)

// Called for inline allocation of closure.
// Input (preserved):
//   AllocateClosureABI::kFunctionReg: closure function.
// Output:
//   AllocateClosureABI::kResultReg: new allocated Closure object.
// Clobbered:
//   AllocateClosureABI::kScratchReg
void StubCodeCompiler::GenerateAllocateClosureStub() {
  const intptr_t instance_size =
      target::RoundedAllocationSize(target::Closure::InstanceSize());
  __ EnsureHasClassIdInDEBUG(kFunctionCid, AllocateClosureABI::kFunctionReg,
                             AllocateClosureABI::kScratchReg);
  __ EnsureHasClassIdInDEBUG(kContextCid, AllocateClosureABI::kContextReg,
                             AllocateClosureABI::kScratchReg,
                             /*can_be_null=*/true);
  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    Label slow_case;
    __ Comment("Inline allocation of uninitialized closure");
#if defined(DEBUG)
    // Need to account for the debug checks added by StoreToSlotNoBarrier.
    const auto distance = Assembler::kFarJump;
#else
    const auto distance = Assembler::kNearJump;
#endif
    __ TryAllocateObject(kClosureCid, instance_size, &slow_case, distance,
                         AllocateClosureABI::kResultReg,
                         AllocateClosureABI::kScratchReg);

    __ Comment("Inline initialization of allocated closure");
    // Put null in the scratch register for initializing most boxed fields.
    // We initialize the fields in offset order below.
    // Since the TryAllocateObject above did not go to the slow path, we're
    // guaranteed an object in new space here, and thus no barriers are needed.
    __ LoadObject(AllocateClosureABI::kScratchReg, NullObject());
    __ StoreToSlotNoBarrier(AllocateClosureABI::kScratchReg,
                            AllocateClosureABI::kResultReg,
                            Slot::Closure_instantiator_type_arguments());
    __ StoreToSlotNoBarrier(AllocateClosureABI::kScratchReg,
                            AllocateClosureABI::kResultReg,
                            Slot::Closure_function_type_arguments());
    __ StoreToSlotNoBarrier(AllocateClosureABI::kScratchReg,
                            AllocateClosureABI::kResultReg,
                            Slot::Closure_delayed_type_arguments());
    __ StoreToSlotNoBarrier(AllocateClosureABI::kFunctionReg,
                            AllocateClosureABI::kResultReg,
                            Slot::Closure_function());
    __ StoreToSlotNoBarrier(AllocateClosureABI::kContextReg,
                            AllocateClosureABI::kResultReg,
                            Slot::Closure_context());
    __ StoreToSlotNoBarrier(AllocateClosureABI::kScratchReg,
                            AllocateClosureABI::kResultReg,
                            Slot::Closure_hash());
#if defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)
    if (FLAG_precompiled_mode) {
      // Set the closure entry point in precompiled mode, either to the function
      // entry point in bare instructions mode or to 0 otherwise (to catch
      // misuse). This overwrites the scratch register, but there are no more
      // boxed fields.
      __ LoadFromSlot(AllocateClosureABI::kScratchReg,
                      AllocateClosureABI::kFunctionReg,
                      Slot::Function_entry_point());
      __ StoreToSlotNoBarrier(AllocateClosureABI::kScratchReg,
                              AllocateClosureABI::kResultReg,
                              Slot::Closure_entry_point());
    }
#endif

    // AllocateClosureABI::kResultReg: new object.
    __ Ret();

    __ Bind(&slow_case);
  }

  __ Comment("Closure allocation via runtime");
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Space on the stack for the return value.
  __ PushRegistersInOrder(
      {AllocateClosureABI::kFunctionReg, AllocateClosureABI::kContextReg});
  __ CallRuntime(kAllocateClosureRuntimeEntry, 2);
  __ PopRegister(AllocateClosureABI::kContextReg);
  __ PopRegister(AllocateClosureABI::kFunctionReg);
  __ PopRegister(AllocateClosureABI::kResultReg);
  ASSERT(target::WillAllocateNewOrRememberedObject(instance_size));
  EnsureIsNewOrRemembered(/*preserve_registers=*/false);
  __ LeaveStubFrame();

  // AllocateClosureABI::kResultReg: new object
  __ Ret();
}

// Generates allocation stub for _GrowableList class.
// This stub exists solely for performance reasons: default allocation
// stub is slower as it doesn't use specialized inline allocation.
void StubCodeCompiler::GenerateAllocateGrowableArrayStub() {
#if defined(TARGET_ARCH_IA32)
  // This stub is not used on IA32 because IA32 version of
  // StubCodeCompiler::GenerateAllocationStubForClass uses inline
  // allocation. Also, AllocateObjectSlow stub is not generated on IA32.
  __ Breakpoint();
#else
  const intptr_t instance_size = target::RoundedAllocationSize(
      target::GrowableObjectArray::InstanceSize());

  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    Label slow_case;
    __ Comment("Inline allocation of GrowableList");
    __ TryAllocateObject(kGrowableObjectArrayCid, instance_size, &slow_case,
                         Assembler::kNearJump, AllocateObjectABI::kResultReg,
                         /*temp_reg=*/AllocateObjectABI::kTagsReg);
    __ StoreIntoObjectNoBarrier(
        AllocateObjectABI::kResultReg,
        FieldAddress(AllocateObjectABI::kResultReg,
                     target::GrowableObjectArray::type_arguments_offset()),
        AllocateObjectABI::kTypeArgumentsReg);

    __ Ret();
    __ Bind(&slow_case);
  }

  const uword tags = target::MakeTagWordForNewSpaceObject(
      kGrowableObjectArrayCid, instance_size);
  __ LoadImmediate(AllocateObjectABI::kTagsReg, tags);
  __ Jump(
      Address(THR, target::Thread::allocate_object_slow_entry_point_offset()));
#endif  // defined(TARGET_ARCH_IA32)
}

void StubCodeCompiler::GenerateAllocateRecordStub() {
  const Register result_reg = AllocateRecordABI::kResultReg;
  const Register shape_reg = AllocateRecordABI::kShapeReg;
  const Register temp_reg = AllocateRecordABI::kTemp1Reg;
  const Register new_top_reg = AllocateRecordABI::kTemp2Reg;

  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    Label slow_case;

    // Check for allocation tracing.
    NOT_IN_PRODUCT(__ MaybeTraceAllocation(kRecordCid, &slow_case, temp_reg));

    // Extract number of fields from the shape.
    __ AndImmediate(
        temp_reg, shape_reg,
        compiler::target::RecordShape::kNumFieldsMask << kSmiTagShift);

    // Compute the rounded instance size.
    const intptr_t fixed_size_plus_alignment_padding =
        (target::Record::field_offset(0) +
         target::ObjectAlignment::kObjectAlignment - 1);
    __ AddScaled(temp_reg, temp_reg, TIMES_COMPRESSED_HALF_WORD_SIZE,
                 fixed_size_plus_alignment_padding);
    __ AndImmediate(temp_reg, -target::ObjectAlignment::kObjectAlignment);

    // Now allocate the object.
    __ LoadFromOffset(result_reg, Address(THR, target::Thread::top_offset()));
    __ MoveRegister(new_top_reg, temp_reg);
    __ AddRegisters(new_top_reg, result_reg);
    // Check if the allocation fits into the remaining space.
    __ CompareWithMemoryValue(new_top_reg,
                              Address(THR, target::Thread::end_offset()));
    __ BranchIf(UNSIGNED_GREATER_EQUAL, &slow_case);

    // Successfully allocated the object, now update top to point to
    // next object start and initialize the object.
    __ StoreToOffset(new_top_reg, Address(THR, target::Thread::top_offset()));
    __ AddImmediate(result_reg, kHeapObjectTag);

    // Calculate the size tag.
    {
      Label size_tag_overflow, done;
      __ CompareImmediate(temp_reg, target::UntaggedObject::kSizeTagMaxSizeTag);
      __ BranchIf(UNSIGNED_GREATER, &size_tag_overflow, Assembler::kNearJump);
      __ LslImmediate(temp_reg,
                      target::UntaggedObject::kTagBitsSizeTagPos -
                          target::ObjectAlignment::kObjectAlignmentLog2);
      __ Jump(&done, Assembler::kNearJump);

      __ Bind(&size_tag_overflow);
      // Set overflow size tag value.
      __ LoadImmediate(temp_reg, 0);

      __ Bind(&done);
      uword tags = target::MakeTagWordForNewSpaceObject(kRecordCid, 0);
      __ OrImmediate(temp_reg, tags);
      __ StoreToOffset(
          temp_reg,
          FieldAddress(result_reg, target::Object::tags_offset()));  // Tags.
    }

    __ StoreCompressedIntoObjectNoBarrier(
        result_reg, FieldAddress(result_reg, target::Record::shape_offset()),
        shape_reg);

    // Initialize the remaining words of the object.
    {
      const Register field_reg = shape_reg;
#if defined(TARGET_ARCH_ARM64) || defined(TARGET_ARCH_RISCV32) ||              \
    defined(TARGET_ARCH_RISCV64)
      const Register null_reg = NULL_REG;
#else
      const Register null_reg = temp_reg;
      __ LoadObject(null_reg, NullObject());
#endif

      Label loop, done;
      __ AddImmediate(field_reg, result_reg, target::Record::field_offset(0));
      __ CompareRegisters(field_reg, new_top_reg);
      __ BranchIf(UNSIGNED_GREATER_EQUAL, &done, Assembler::kNearJump);

      __ Bind(&loop);
      for (intptr_t offset = 0; offset < target::kObjectAlignment;
           offset += target::kCompressedWordSize) {
        __ StoreCompressedIntoObjectNoBarrier(
            result_reg, FieldAddress(field_reg, offset), null_reg);
      }
      // Safe to only check every kObjectAlignment bytes instead of each word.
      ASSERT(kAllocationRedZoneSize >= target::kObjectAlignment);
      __ AddImmediate(field_reg, target::kObjectAlignment);
      __ CompareRegisters(field_reg, new_top_reg);
      __ BranchIf(UNSIGNED_LESS, &loop, Assembler::kNearJump);
      __ Bind(&done);
    }

    __ Ret();

    __ Bind(&slow_case);
  }

  __ EnterStubFrame();
  __ PushObject(NullObject());  // Space on the stack for the return value.
  __ PushRegister(shape_reg);
  __ CallRuntime(kAllocateRecordRuntimeEntry, 1);
  __ Drop(1);
  __ PopRegister(AllocateRecordABI::kResultReg);

  EnsureIsNewOrRemembered(/*preserve_registers=*/false);
  __ LeaveStubFrame();
  __ Ret();
}

void StubCodeCompiler::GenerateAllocateSmallRecordStub(intptr_t num_fields,
                                                       bool has_named_fields) {
  ASSERT(num_fields == 2 || num_fields == 3);
  const Register result_reg = AllocateSmallRecordABI::kResultReg;
  const Register shape_reg = AllocateSmallRecordABI::kShapeReg;
  const Register value0_reg = AllocateSmallRecordABI::kValue0Reg;
  const Register value1_reg = AllocateSmallRecordABI::kValue1Reg;
  const Register value2_reg = AllocateSmallRecordABI::kValue2Reg;
  const Register temp_reg = AllocateSmallRecordABI::kTempReg;
  Label slow_case;

  if ((num_fields > 2) && (value2_reg == kNoRegister)) {
    // Not implemented.
    __ Breakpoint();
    return;
  }

#if defined(DEBUG)
  // Need to account for the debug checks added by
  // StoreCompressedIntoObjectNoBarrier.
  const auto distance = Assembler::kFarJump;
#else
  const auto distance = Assembler::kNearJump;
#endif
  __ TryAllocateObject(kRecordCid, target::Record::InstanceSize(num_fields),
                       &slow_case, distance, result_reg, temp_reg);

  if (!has_named_fields) {
    __ LoadImmediate(
        shape_reg, Smi::RawValue(RecordShape::ForUnnamed(num_fields).AsInt()));
  }
  __ StoreCompressedIntoObjectNoBarrier(
      result_reg, FieldAddress(result_reg, target::Record::shape_offset()),
      shape_reg);

  __ StoreCompressedIntoObjectNoBarrier(
      result_reg, FieldAddress(result_reg, target::Record::field_offset(0)),
      value0_reg);

  __ StoreCompressedIntoObjectNoBarrier(
      result_reg, FieldAddress(result_reg, target::Record::field_offset(1)),
      value1_reg);

  if (num_fields > 2) {
    __ StoreCompressedIntoObjectNoBarrier(
        result_reg, FieldAddress(result_reg, target::Record::field_offset(2)),
        value2_reg);
  }

  __ Ret();

  __ Bind(&slow_case);

  __ EnterStubFrame();
  __ PushObject(NullObject());  // Space on the stack for the return value.
  if (has_named_fields) {
    __ PushRegister(shape_reg);
  } else {
    __ PushImmediate(
        Smi::RawValue(RecordShape::ForUnnamed(num_fields).AsInt()));
  }
  __ PushRegistersInOrder({value0_reg, value1_reg});
  if (num_fields > 2) {
    __ PushRegister(value2_reg);
  } else {
    __ PushObject(NullObject());
  }
  __ CallRuntime(kAllocateSmallRecordRuntimeEntry, 4);
  __ Drop(4);
  __ PopRegister(result_reg);

  EnsureIsNewOrRemembered(/*preserve_registers=*/false);
  __ LeaveStubFrame();
  __ Ret();
}

void StubCodeCompiler::GenerateAllocateRecord2Stub() {
  GenerateAllocateSmallRecordStub(2, /*has_named_fields=*/false);
}

void StubCodeCompiler::GenerateAllocateRecord2NamedStub() {
  GenerateAllocateSmallRecordStub(2, /*has_named_fields=*/true);
}

void StubCodeCompiler::GenerateAllocateRecord3Stub() {
  GenerateAllocateSmallRecordStub(3, /*has_named_fields=*/false);
}

void StubCodeCompiler::GenerateAllocateRecord3NamedStub() {
  GenerateAllocateSmallRecordStub(3, /*has_named_fields=*/true);
}

// The UnhandledException class lives in the VM isolate, so it cannot cache
// an allocation stub for itself. Instead, we cache it in the stub code list.
void StubCodeCompiler::GenerateAllocateUnhandledExceptionStub() {
  Thread* thread = Thread::Current();
  auto class_table = thread->isolate_group()->class_table();
  ASSERT(class_table->HasValidClassAt(kUnhandledExceptionCid));
  const auto& cls = Class::ZoneHandle(thread->zone(),
                                      class_table->At(kUnhandledExceptionCid));
  ASSERT(!cls.IsNull());

  GenerateAllocationStubForClass(nullptr, cls, Code::Handle(Code::null()),
                                 Code::Handle(Code::null()));
}

#define TYPED_DATA_ALLOCATION_STUB(clazz)                                      \
  void StubCodeCompiler::GenerateAllocate##clazz##Stub() {                     \
    GenerateAllocateTypedDataArrayStub(kTypedData##clazz##Cid);                \
  }
CLASS_LIST_TYPED_DATA(TYPED_DATA_ALLOCATION_STUB)
#undef TYPED_DATA_ALLOCATION_STUB

void StubCodeCompiler::GenerateLateInitializationError(bool with_fpu_regs) {
  auto perform_runtime_call = [&]() {
    __ PushRegister(LateInitializationErrorABI::kFieldReg);
    __ CallRuntime(kLateFieldNotInitializedErrorRuntimeEntry,
                   /*argument_count=*/1);
  };
  GenerateSharedStubGeneric(
      /*save_fpu_registers=*/with_fpu_regs,
      with_fpu_regs
          ? target::Thread::
                late_initialization_error_shared_with_fpu_regs_stub_offset()
          : target::Thread::
                late_initialization_error_shared_without_fpu_regs_stub_offset(),
      /*allow_return=*/false, perform_runtime_call);
}

void StubCodeCompiler::
    GenerateLateInitializationErrorSharedWithoutFPURegsStub() {
  GenerateLateInitializationError(/*with_fpu_regs=*/false);
}

void StubCodeCompiler::GenerateLateInitializationErrorSharedWithFPURegsStub() {
  GenerateLateInitializationError(/*with_fpu_regs=*/true);
}

void StubCodeCompiler::GenerateNullErrorSharedWithoutFPURegsStub() {
  GenerateSharedStub(
      /*save_fpu_registers=*/false, &kNullErrorRuntimeEntry,
      target::Thread::null_error_shared_without_fpu_regs_stub_offset(),
      /*allow_return=*/false);
}

void StubCodeCompiler::GenerateNullErrorSharedWithFPURegsStub() {
  GenerateSharedStub(
      /*save_fpu_registers=*/true, &kNullErrorRuntimeEntry,
      target::Thread::null_error_shared_with_fpu_regs_stub_offset(),
      /*allow_return=*/false);
}

void StubCodeCompiler::GenerateNullArgErrorSharedWithoutFPURegsStub() {
  GenerateSharedStub(
      /*save_fpu_registers=*/false, &kArgumentNullErrorRuntimeEntry,
      target::Thread::null_arg_error_shared_without_fpu_regs_stub_offset(),
      /*allow_return=*/false);
}

void StubCodeCompiler::GenerateNullArgErrorSharedWithFPURegsStub() {
  GenerateSharedStub(
      /*save_fpu_registers=*/true, &kArgumentNullErrorRuntimeEntry,
      target::Thread::null_arg_error_shared_with_fpu_regs_stub_offset(),
      /*allow_return=*/false);
}

void StubCodeCompiler::GenerateNullCastErrorSharedWithoutFPURegsStub() {
  GenerateSharedStub(
      /*save_fpu_registers=*/false, &kNullCastErrorRuntimeEntry,
      target::Thread::null_cast_error_shared_without_fpu_regs_stub_offset(),
      /*allow_return=*/false);
}

void StubCodeCompiler::GenerateNullCastErrorSharedWithFPURegsStub() {
  GenerateSharedStub(
      /*save_fpu_registers=*/true, &kNullCastErrorRuntimeEntry,
      target::Thread::null_cast_error_shared_with_fpu_regs_stub_offset(),
      /*allow_return=*/false);
}

void StubCodeCompiler::GenerateStackOverflowSharedWithoutFPURegsStub() {
  GenerateSharedStub(
      /*save_fpu_registers=*/false, &kInterruptOrStackOverflowRuntimeEntry,
      target::Thread::stack_overflow_shared_without_fpu_regs_stub_offset(),
      /*allow_return=*/true);
}

void StubCodeCompiler::GenerateStackOverflowSharedWithFPURegsStub() {
  GenerateSharedStub(
      /*save_fpu_registers=*/true, &kInterruptOrStackOverflowRuntimeEntry,
      target::Thread::stack_overflow_shared_with_fpu_regs_stub_offset(),
      /*allow_return=*/true);
}

void StubCodeCompiler::GenerateRangeErrorSharedWithoutFPURegsStub() {
  GenerateRangeError(/*with_fpu_regs=*/false);
}

void StubCodeCompiler::GenerateRangeErrorSharedWithFPURegsStub() {
  GenerateRangeError(/*with_fpu_regs=*/true);
}

void StubCodeCompiler::GenerateWriteErrorSharedWithoutFPURegsStub() {
  GenerateWriteError(/*with_fpu_regs=*/false);
}

void StubCodeCompiler::GenerateWriteErrorSharedWithFPURegsStub() {
  GenerateWriteError(/*with_fpu_regs=*/true);
}

void StubCodeCompiler::GenerateFrameAwaitingMaterializationStub() {
  __ Breakpoint();  // Marker stub.
}

void StubCodeCompiler::GenerateAsynchronousGapMarkerStub() {
  __ Breakpoint();  // Marker stub.
}

void StubCodeCompiler::GenerateUnknownDartCodeStub() {
  // Enter frame to include caller into the backtrace.
  __ EnterStubFrame();
  __ Breakpoint();  // Marker stub.
}

void StubCodeCompiler::GenerateNotLoadedStub() {
  __ EnterStubFrame();
  __ CallRuntime(kNotLoadedRuntimeEntry, 0);
  __ Breakpoint();
}

#define EMIT_BOX_ALLOCATION(Name)                                              \
  void StubCodeCompiler::GenerateAllocate##Name##Stub() {                      \
    Label call_runtime;                                                        \
    if (!FLAG_use_slow_path && FLAG_inline_alloc) {                            \
      __ TryAllocate(compiler::Name##Class(), &call_runtime,                   \
                     Assembler::kNearJump, AllocateBoxABI::kResultReg,         \
                     AllocateBoxABI::kTempReg);                                \
      __ Ret();                                                                \
    }                                                                          \
    __ Bind(&call_runtime);                                                    \
    __ EnterStubFrame();                                                       \
    __ PushObject(NullObject()); /* Make room for result. */                   \
    __ CallRuntime(kAllocate##Name##RuntimeEntry, 0);                          \
    __ PopRegister(AllocateBoxABI::kResultReg);                                \
    __ LeaveStubFrame();                                                       \
    __ Ret();                                                                  \
  }

EMIT_BOX_ALLOCATION(Mint)
EMIT_BOX_ALLOCATION(Double)
EMIT_BOX_ALLOCATION(Float32x4)
EMIT_BOX_ALLOCATION(Float64x2)
EMIT_BOX_ALLOCATION(Int32x4)

#undef EMIT_BOX_ALLOCATION

static void GenerateBoxFpuValueStub(Assembler* assembler,
                                    const dart::Class& cls,
                                    const RuntimeEntry& runtime_entry,
                                    void (Assembler::*store_value)(FpuRegister,
                                                                   Register,
                                                                   int32_t)) {
  Label call_runtime;
  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    __ TryAllocate(cls, &call_runtime, compiler::Assembler::kFarJump,
                   BoxDoubleStubABI::kResultReg, BoxDoubleStubABI::kTempReg);
    (assembler->*store_value)(
        BoxDoubleStubABI::kValueReg, BoxDoubleStubABI::kResultReg,
        compiler::target::Double::value_offset() - kHeapObjectTag);
    __ Ret();
  }
  __ Bind(&call_runtime);
  __ EnterStubFrame();
  __ PushObject(NullObject()); /* Make room for result. */
  (assembler->*store_value)(BoxDoubleStubABI::kValueReg, THR,
                            target::Thread::unboxed_runtime_arg_offset());
  __ CallRuntime(runtime_entry, 0);
  __ PopRegister(BoxDoubleStubABI::kResultReg);
  __ LeaveStubFrame();
  __ Ret();
}

void StubCodeCompiler::GenerateBoxDoubleStub() {
  GenerateBoxFpuValueStub(assembler, compiler::DoubleClass(),
                          kBoxDoubleRuntimeEntry,
                          &Assembler::StoreUnboxedDouble);
}

void StubCodeCompiler::GenerateBoxFloat32x4Stub() {
#if !defined(TARGET_ARCH_RISCV32) && !defined(TARGET_ARCH_RISCV64)
  GenerateBoxFpuValueStub(assembler, compiler::Float32x4Class(),
                          kBoxFloat32x4RuntimeEntry,
                          &Assembler::StoreUnboxedSimd128);
#else
  __ Stop("Not supported on RISC-V.");
#endif
}

void StubCodeCompiler::GenerateBoxFloat64x2Stub() {
#if !defined(TARGET_ARCH_RISCV32) && !defined(TARGET_ARCH_RISCV64)
  GenerateBoxFpuValueStub(assembler, compiler::Float64x2Class(),
                          kBoxFloat64x2RuntimeEntry,
                          &Assembler::StoreUnboxedSimd128);
#else
  __ Stop("Not supported on RISC-V.");
#endif
}

void StubCodeCompiler::GenerateDoubleToIntegerStub() {
  __ EnterStubFrame();
  __ StoreUnboxedDouble(DoubleToIntegerStubABI::kInputReg, THR,
                        target::Thread::unboxed_runtime_arg_offset());
  __ PushObject(NullObject()); /* Make room for result. */
  __ PushRegister(DoubleToIntegerStubABI::kRecognizedKindReg);
  __ CallRuntime(kDoubleToIntegerRuntimeEntry, 1);
  __ Drop(1);
  __ PopRegister(DoubleToIntegerStubABI::kResultReg);
  __ LeaveStubFrame();
  __ Ret();
}

static intptr_t SuspendStateFpOffset() {
  return compiler::target::frame_layout.FrameSlotForVariableIndex(
             SuspendState::kSuspendStateVarIndex) *
         compiler::target::kWordSize;
}

static void CallDartCoreLibraryFunction(
    Assembler* assembler,
    intptr_t entry_point_offset_in_thread,
    intptr_t function_offset_in_object_store,
    bool uses_args_desc = false) {
  if (FLAG_precompiled_mode) {
    __ Call(Address(THR, entry_point_offset_in_thread));
  } else {
    __ LoadIsolateGroup(FUNCTION_REG);
    __ LoadFromOffset(
        FUNCTION_REG,
        Address(FUNCTION_REG, target::IsolateGroup::object_store_offset()));
    __ LoadFromOffset(FUNCTION_REG,
                      Address(FUNCTION_REG, function_offset_in_object_store));
    __ LoadCompressedFieldFromOffset(CODE_REG, FUNCTION_REG,
                                     target::Function::code_offset());
    if (!uses_args_desc) {
      // Load a GC-safe value for the arguments descriptor (unused but tagged).
      __ LoadImmediate(ARGS_DESC_REG, 0);
    }
    __ Call(FieldAddress(FUNCTION_REG, target::Function::entry_point_offset()));
  }
}

// Helper to generate allocation of _SuspendState instance.
// Initializes tags, frame_capacity and frame_size.
// Other fields are not initialized.
//
// Input:
//   frame_size_reg: size of the frame payload in bytes.
// Output:
//   result_reg: allocated instance.
// Clobbers:
//   result_reg, temp_reg.
static void GenerateAllocateSuspendState(Assembler* assembler,
                                         Label* slow_case,
                                         Register result_reg,
                                         Register frame_size_reg,
                                         Register temp_reg) {
  if (FLAG_use_slow_path || !FLAG_inline_alloc) {
    __ Jump(slow_case);
    return;
  }

  // Check for allocation tracing.
  NOT_IN_PRODUCT(
      __ MaybeTraceAllocation(kSuspendStateCid, slow_case, temp_reg));

  // Compute the rounded instance size.
  const intptr_t fixed_size_plus_alignment_padding =
      (target::SuspendState::HeaderSize() +
       target::SuspendState::FrameSizeGrowthGap() * target::kWordSize +
       target::ObjectAlignment::kObjectAlignment - 1);
  __ AddImmediate(temp_reg, frame_size_reg, fixed_size_plus_alignment_padding);
  __ AndImmediate(temp_reg, -target::ObjectAlignment::kObjectAlignment);

  // Now allocate the object.
  __ LoadFromOffset(result_reg, Address(THR, target::Thread::top_offset()));
  __ AddRegisters(temp_reg, result_reg);
  // Check if the allocation fits into the remaining space.
  __ CompareWithMemoryValue(temp_reg,
                            Address(THR, target::Thread::end_offset()));
  __ BranchIf(UNSIGNED_GREATER_EQUAL, slow_case);

  // Successfully allocated the object, now update top to point to
  // next object start and initialize the object.
  __ StoreToOffset(temp_reg, Address(THR, target::Thread::top_offset()));
  __ SubRegisters(temp_reg, result_reg);
  __ AddImmediate(result_reg, kHeapObjectTag);

  if (!FLAG_precompiled_mode) {
    // Use rounded object size to calculate and save frame capacity.
    __ AddImmediate(temp_reg, temp_reg,
                    -target::SuspendState::payload_offset());
    __ StoreToOffset(
        temp_reg, FieldAddress(result_reg,
                               target::SuspendState::frame_capacity_offset()));
    // Restore rounded object size.
    __ AddImmediate(temp_reg, temp_reg, target::SuspendState::payload_offset());
  }

  // Calculate the size tag.
  {
    Label size_tag_overflow, done;
    __ CompareImmediate(temp_reg, target::UntaggedObject::kSizeTagMaxSizeTag);
    __ BranchIf(UNSIGNED_GREATER, &size_tag_overflow, Assembler::kNearJump);
    __ LslImmediate(temp_reg,
                    target::UntaggedObject::kTagBitsSizeTagPos -
                        target::ObjectAlignment::kObjectAlignmentLog2);
    __ Jump(&done, Assembler::kNearJump);

    __ Bind(&size_tag_overflow);
    // Set overflow size tag value.
    __ LoadImmediate(temp_reg, 0);

    __ Bind(&done);
    uword tags = target::MakeTagWordForNewSpaceObject(kSuspendStateCid, 0);
    __ OrImmediate(temp_reg, tags);
    __ StoreToOffset(
        temp_reg,
        FieldAddress(result_reg, target::Object::tags_offset()));  // Tags.
  }

  __ StoreToOffset(
      frame_size_reg,
      FieldAddress(result_reg, target::SuspendState::frame_size_offset()));
}

void StubCodeCompiler::GenerateSuspendStub(
    bool call_suspend_function,
    bool pass_type_arguments,
    intptr_t suspend_entry_point_offset_in_thread,
    intptr_t suspend_function_offset_in_object_store) {
  const Register kArgument = SuspendStubABI::kArgumentReg;
  const Register kTypeArgs = SuspendStubABI::kTypeArgsReg;
  const Register kTemp = SuspendStubABI::kTempReg;
  const Register kFrameSize = SuspendStubABI::kFrameSizeReg;
  const Register kSuspendState = SuspendStubABI::kSuspendStateReg;
  const Register kFunctionData = SuspendStubABI::kFunctionDataReg;
  const Register kSrcFrame = SuspendStubABI::kSrcFrameReg;
  const Register kDstFrame = SuspendStubABI::kDstFrameReg;
  Label alloc_slow_case, alloc_done, init_done, resize_suspend_state,
      old_gen_object, call_dart;

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
  SPILLS_LR_TO_FRAME({});  // Simulate entering the caller (Dart) frame.
#endif

  __ LoadFromOffset(kSuspendState, Address(FPREG, SuspendStateFpOffset()));

  __ AddImmediate(
      kFrameSize, FPREG,
      -target::frame_layout.last_param_from_entry_sp * target::kWordSize);
  __ SubRegisters(kFrameSize, SPREG);

  __ EnterStubFrame();

  if (pass_type_arguments) {
    __ PushRegister(kTypeArgs);
  }

  __ CompareClassId(kSuspendState, kSuspendStateCid, kTemp);

  if (FLAG_precompiled_mode) {
    __ BranchIf(EQUAL, &init_done);
  } else {
    Label alloc_suspend_state;
    __ BranchIf(NOT_EQUAL, &alloc_suspend_state);

    __ CompareWithMemoryValue(
        kFrameSize,
        FieldAddress(kSuspendState,
                     target::SuspendState::frame_capacity_offset()));
    __ BranchIf(UNSIGNED_GREATER, &resize_suspend_state);

    __ StoreToOffset(
        kFrameSize,
        FieldAddress(kSuspendState, target::SuspendState::frame_size_offset()));
    __ Jump(&init_done);

    __ Bind(&alloc_suspend_state);
  }

  __ Comment("Allocate SuspendState");
  __ MoveRegister(kFunctionData, kSuspendState);

  GenerateAllocateSuspendState(assembler, &alloc_slow_case, kSuspendState,
                               kFrameSize, kTemp);

  __ StoreCompressedIntoObjectNoBarrier(
      kSuspendState,
      FieldAddress(kSuspendState, target::SuspendState::function_data_offset()),
      kFunctionData);

  {
#if defined(TARGET_ARCH_ARM64) || defined(TARGET_ARCH_RISCV32) ||              \
    defined(TARGET_ARCH_RISCV64)
    const Register kNullReg = NULL_REG;
#else
    const Register kNullReg = kTemp;
    __ LoadObject(kNullReg, NullObject());
#endif
    __ StoreCompressedIntoObjectNoBarrier(
        kSuspendState,
        FieldAddress(kSuspendState,
                     target::SuspendState::then_callback_offset()),
        kNullReg);
    __ StoreCompressedIntoObjectNoBarrier(
        kSuspendState,
        FieldAddress(kSuspendState,
                     target::SuspendState::error_callback_offset()),
        kNullReg);
  }

  __ Bind(&alloc_done);

  __ Comment("Save SuspendState to frame");
  __ LoadFromOffset(
      kTemp, Address(FPREG, kSavedCallerFpSlotFromFp * target::kWordSize));
  __ StoreToOffset(kSuspendState, Address(kTemp, SuspendStateFpOffset()));

  __ Bind(&init_done);
  __ Comment("Copy frame to SuspendState");

#ifdef DEBUG
  {
    // Verify that SuspendState.frame_size == kFrameSize.
    Label okay;
    __ LoadFromOffset(
        kTemp,
        FieldAddress(kSuspendState, target::SuspendState::frame_size_offset()));
    __ CompareRegisters(kTemp, kFrameSize);
    __ BranchIf(EQUAL, &okay);
    __ Breakpoint();
    __ Bind(&okay);
  }
#endif

  __ LoadFromOffset(
      kTemp, Address(FPREG, kSavedCallerPcSlotFromFp * target::kWordSize));
  __ StoreToOffset(
      kTemp, FieldAddress(kSuspendState, target::SuspendState::pc_offset()));

  if (kSrcFrame == THR) {
    __ PushRegister(THR);
  }
  __ AddImmediate(kSrcFrame, FPREG, kCallerSpSlotFromFp * target::kWordSize);
  __ AddImmediate(kDstFrame, kSuspendState,
                  target::SuspendState::payload_offset() - kHeapObjectTag);
  __ CopyMemoryWords(kSrcFrame, kDstFrame, kFrameSize, kTemp);
  if (kSrcFrame == THR) {
    __ PopRegister(THR);
  }

#ifdef DEBUG
  {
    // Verify that kSuspendState matches :suspend_state in the copied stack
    // frame.
    Label okay;
    __ LoadFromOffset(
        kTemp,
        FieldAddress(kSuspendState, target::SuspendState::frame_size_offset()));
    __ AddRegisters(kTemp, kSuspendState);
    __ LoadFromOffset(
        kTemp, FieldAddress(kTemp, target::SuspendState::payload_offset() +
                                       SuspendStateFpOffset()));
    __ CompareRegisters(kTemp, kSuspendState);
    __ BranchIf(EQUAL, &okay);
    __ Breakpoint();
    __ Bind(&okay);
  }
#endif

  if (call_suspend_function) {
    // Push arguments for suspend Dart function early to preserve them
    // across write barrier.
    __ PushRegistersInOrder({kSuspendState, kArgument});
  }

  // Write barrier.
  __ BranchIfBit(kSuspendState, target::ObjectAlignment::kNewObjectBitPosition,
                 ZERO, &old_gen_object);

  __ Bind(&call_dart);
  if (call_suspend_function) {
    __ Comment("Call suspend Dart function");
    if (pass_type_arguments) {
      __ LoadObject(ARGS_DESC_REG,
                    ArgumentsDescriptorBoxed(/*type_args_len=*/1,
                                             /*num_arguments=*/2));
    }
    CallDartCoreLibraryFunction(assembler, suspend_entry_point_offset_in_thread,
                                suspend_function_offset_in_object_store,
                                /*uses_args_desc=*/pass_type_arguments);
  } else {
    // SuspendStub returns either the result of Dart callback,
    // or SuspendStub argument (if Dart callback is not used).
    // The latter is used by yield/yield* in sync* functions
    // to indicate that iteration should be continued.
    __ MoveRegister(CallingConventions::kReturnReg, kArgument);
  }

  __ LeaveStubFrame();

#if !defined(TARGET_ARCH_X64) && !defined(TARGET_ARCH_IA32)
  // Drop caller frame on all architectures except x86 (X64/IA32) which
  // needs to maintain call/return balance to avoid performance regressions.
  __ LeaveDartFrame();
#elif defined(TARGET_ARCH_X64)
  // Restore PP in JIT mode on x64 as epilogue following SuspendStub call
  // will only unwind frame and return.
  if (!FLAG_precompiled_mode) {
    __ LoadFromOffset(
        PP, Address(FPREG, target::frame_layout.saved_caller_pp_from_fp *
                               target::kWordSize));
  }
#endif
  __ Ret();

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
  // Slow path is executed with Dart and stub frames still on the stack.
  SPILLS_LR_TO_FRAME({});
  SPILLS_LR_TO_FRAME({});
#endif
  __ Bind(&alloc_slow_case);
  __ Comment("SuspendState Allocation slow case");
  // Save argument and frame size.
  __ PushRegistersInOrder({kArgument, kFrameSize});
  __ PushObject(NullObject());  // Make space on stack for the return value.
  __ SmiTag(kFrameSize);
  // Pass frame size and function data to runtime entry.
  __ PushRegistersInOrder({kFrameSize, kFunctionData});
  __ CallRuntime(kAllocateSuspendStateRuntimeEntry, 2);
  __ Drop(2);                     // Drop arguments
  __ PopRegister(kSuspendState);  // Get result.
  __ PopRegister(kFrameSize);     // Restore frame size.
  __ PopRegister(kArgument);      // Restore argument.
  __ Jump(&alloc_done);

  __ Bind(&resize_suspend_state);
  __ Comment("Resize SuspendState");
  // Save argument and frame size.
  __ PushRegistersInOrder({kArgument, kFrameSize});
  __ PushObject(NullObject());  // Make space on stack for the return value.
  __ SmiTag(kFrameSize);
  // Pass frame size and old suspend state to runtime entry.
  __ PushRegistersInOrder({kFrameSize, kSuspendState});
  // It's okay to call runtime for resizing SuspendState objects
  // as it can only happen in the unoptimized code if expression
  // stack grows between suspends, or once after OSR transition.
  __ CallRuntime(kAllocateSuspendStateRuntimeEntry, 2);
  __ Drop(2);                     // Drop arguments
  __ PopRegister(kSuspendState);  // Get result.
  __ PopRegister(kFrameSize);     // Restore frame size.
  __ PopRegister(kArgument);      // Restore argument.
  __ Jump(&alloc_done);

  __ Bind(&old_gen_object);
  __ Comment("Old gen SuspendState slow case");
  if (!call_suspend_function) {
    // Save kArgument which contains the return value
    // if suspend function is not called.
    __ PushRegister(kArgument);
  }
  {
#if defined(TARGET_ARCH_IA32)
    LeafRuntimeScope rt(assembler, /*frame_size=*/2 * target::kWordSize,
                        /*preserve_registers=*/false);
    __ movl(Address(ESP, 1 * target::kWordSize), THR);
    __ movl(Address(ESP, 0 * target::kWordSize), kSuspendState);
#else
    LeafRuntimeScope rt(assembler, /*frame_size=*/0,
                        /*preserve_registers=*/false);
    __ MoveRegister(CallingConventions::ArgumentRegisters[0], kSuspendState);
    __ MoveRegister(CallingConventions::ArgumentRegisters[1], THR);
#endif
    rt.Call(kEnsureRememberedAndMarkingDeferredRuntimeEntry, 2);
  }
  if (!call_suspend_function) {
    __ PopRegister(kArgument);
  }
  __ Jump(&call_dart);
}

void StubCodeCompiler::GenerateAwaitStub() {
  GenerateSuspendStub(
      /*call_suspend_function=*/true,
      /*pass_type_arguments=*/false,
      target::Thread::suspend_state_await_entry_point_offset(),
      target::ObjectStore::suspend_state_await_offset());
}

void StubCodeCompiler::GenerateAwaitWithTypeCheckStub() {
  GenerateSuspendStub(

      /*call_suspend_function=*/true,
      /*pass_type_arguments=*/true,
      target::Thread::suspend_state_await_with_type_check_entry_point_offset(),
      target::ObjectStore::suspend_state_await_with_type_check_offset());
}

void StubCodeCompiler::GenerateYieldAsyncStarStub() {
  GenerateSuspendStub(

      /*call_suspend_function=*/true,
      /*pass_type_arguments=*/false,
      target::Thread::suspend_state_yield_async_star_entry_point_offset(),
      target::ObjectStore::suspend_state_yield_async_star_offset());
}

void StubCodeCompiler::GenerateSuspendSyncStarAtStartStub() {
  GenerateSuspendStub(

      /*call_suspend_function=*/true,
      /*pass_type_arguments=*/false,
      target::Thread::
          suspend_state_suspend_sync_star_at_start_entry_point_offset(),
      target::ObjectStore::suspend_state_suspend_sync_star_at_start_offset());
}

void StubCodeCompiler::GenerateSuspendSyncStarAtYieldStub() {
  GenerateSuspendStub(
      /*call_suspend_function=*/false,
      /*pass_type_arguments=*/false, -1, -1);
}

void StubCodeCompiler::GenerateInitSuspendableFunctionStub(
    intptr_t init_entry_point_offset_in_thread,
    intptr_t init_function_offset_in_object_store) {
  const Register kTypeArgs = InitSuspendableFunctionStubABI::kTypeArgsReg;

  __ EnterStubFrame();
  __ LoadObject(ARGS_DESC_REG, ArgumentsDescriptorBoxed(/*type_args_len=*/1,
                                                        /*num_arguments=*/0));
  __ PushRegister(kTypeArgs);
  CallDartCoreLibraryFunction(assembler, init_entry_point_offset_in_thread,
                              init_function_offset_in_object_store,
                              /*uses_args_desc=*/true);
  __ LeaveStubFrame();

  // Set :suspend_state in the caller frame.
  __ StoreToOffset(CallingConventions::kReturnReg,
                   Address(FPREG, SuspendStateFpOffset()));
  __ Ret();
}

void StubCodeCompiler::GenerateInitAsyncStub() {
  GenerateInitSuspendableFunctionStub(
      target::Thread::suspend_state_init_async_entry_point_offset(),
      target::ObjectStore::suspend_state_init_async_offset());
}

void StubCodeCompiler::GenerateInitAsyncStarStub() {
  GenerateInitSuspendableFunctionStub(
      target::Thread::suspend_state_init_async_star_entry_point_offset(),
      target::ObjectStore::suspend_state_init_async_star_offset());
}

void StubCodeCompiler::GenerateInitSyncStarStub() {
  GenerateInitSuspendableFunctionStub(
      target::Thread::suspend_state_init_sync_star_entry_point_offset(),
      target::ObjectStore::suspend_state_init_sync_star_offset());
}

void StubCodeCompiler::GenerateResumeStub() {
  const Register kSuspendState = ResumeStubABI::kSuspendStateReg;
  const Register kTemp = ResumeStubABI::kTempReg;
  const Register kFrameSize = ResumeStubABI::kFrameSizeReg;
  const Register kSrcFrame = ResumeStubABI::kSrcFrameReg;
  const Register kDstFrame = ResumeStubABI::kDstFrameReg;
  const Register kResumePc = ResumeStubABI::kResumePcReg;
  const Register kException = ResumeStubABI::kExceptionReg;
  const Register kStackTrace = ResumeStubABI::kStackTraceReg;
  Label call_runtime;

  // Top of the stack on entry:
  // ... [SuspendState] [value] [exception] [stackTrace] [ReturnAddress]

  __ EnterDartFrame(0);

  const intptr_t param_offset =
      target::frame_layout.param_end_from_fp * target::kWordSize;
  __ LoadFromOffset(kSuspendState,
                    Address(FPREG, param_offset + 4 * target::kWordSize));
#ifdef DEBUG
  {
    Label okay;
    __ CompareClassId(kSuspendState, kSuspendStateCid, kTemp);
    __ BranchIf(EQUAL, &okay);
    __ Breakpoint();
    __ Bind(&okay);
  }
  {
    Label okay;
    __ LoadFromOffset(
        kTemp, FieldAddress(kSuspendState, target::SuspendState::pc_offset()));
    __ CompareImmediate(kTemp, 0);
    __ BranchIf(NOT_EQUAL, &okay);
    __ Breakpoint();
    __ Bind(&okay);
  }
#endif

  __ LoadFromOffset(
      kFrameSize,
      FieldAddress(kSuspendState, target::SuspendState::frame_size_offset()));
#ifdef DEBUG
  {
    Label okay;
    __ MoveRegister(kTemp, kFrameSize);
    __ AddRegisters(kTemp, kSuspendState);
    __ LoadFromOffset(
        kTemp, FieldAddress(kTemp, target::SuspendState::payload_offset() +
                                       SuspendStateFpOffset()));
    __ CompareRegisters(kTemp, kSuspendState);
    __ BranchIf(EQUAL, &okay);
    __ Breakpoint();
    __ Bind(&okay);
  }
#endif
  if (!FLAG_precompiled_mode) {
    // Copy Code object (part of the fixed frame which is not copied below)
    // and restore pool pointer.
    __ MoveRegister(kTemp, kSuspendState);
    __ AddRegisters(kTemp, kFrameSize);
    __ LoadFromOffset(
        CODE_REG,
        Address(kTemp,
                target::SuspendState::payload_offset() - kHeapObjectTag +
                    target::frame_layout.code_from_fp * target::kWordSize));
    __ StoreToOffset(
        CODE_REG,
        Address(FPREG, target::frame_layout.code_from_fp * target::kWordSize));
#if !defined(TARGET_ARCH_IA32)
    __ LoadPoolPointer(PP);
#endif
  }
  // Do not copy fixed frame between the first local and FP.
  __ AddImmediate(kFrameSize, (target::frame_layout.first_local_from_fp + 1) *
                                  target::kWordSize);
  __ SubRegisters(SPREG, kFrameSize);

  __ Comment("Copy frame from SuspendState");
  intptr_t num_saved_regs = 0;
  if (kSrcFrame == THR) {
    __ PushRegister(THR);
    ++num_saved_regs;
  }
  if (kDstFrame == CODE_REG) {
    __ PushRegister(CODE_REG);
    ++num_saved_regs;
  }
  __ AddImmediate(kSrcFrame, kSuspendState,
                  target::SuspendState::payload_offset() - kHeapObjectTag);
  __ AddImmediate(kDstFrame, SPREG, num_saved_regs * target::kWordSize);
  __ CopyMemoryWords(kSrcFrame, kDstFrame, kFrameSize, kTemp);
  if (kDstFrame == CODE_REG) {
    __ PopRegister(CODE_REG);
  }
  if (kSrcFrame == THR) {
    __ PopRegister(THR);
  }

  __ Comment("Transfer control");

  __ LoadFromOffset(kResumePc, FieldAddress(kSuspendState,
                                            target::SuspendState::pc_offset()));
  __ StoreZero(FieldAddress(kSuspendState, target::SuspendState::pc_offset()),
               kTemp);

#if defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_IA32)
  // Adjust resume PC to skip extra epilogue generated on x86
  // right after the call to suspend stub in order to maintain
  // call/return balance.
  __ AddImmediate(kResumePc, SuspendStubABI::kResumePcDistance);
#endif

  static_assert((kException != CODE_REG) && (kException != PP),
                "should not interfere");
  __ LoadFromOffset(kException,
                    Address(FPREG, param_offset + 2 * target::kWordSize));
  __ CompareObject(kException, NullObject());
  __ BranchIf(NOT_EQUAL, &call_runtime);

  if (!FLAG_precompiled_mode) {
    // Check if Code is disabled.
    __ LoadFromOffset(
        kTemp, FieldAddress(CODE_REG, target::Code::instructions_offset()));
    __ CompareWithMemoryValue(
        kTemp,
        FieldAddress(CODE_REG, target::Code::active_instructions_offset()));
    __ BranchIf(NOT_EQUAL, &call_runtime);

#if !defined(PRODUCT)
    // Check if there is a breakpoint at resumption.
    __ LoadIsolate(kTemp);
    __ LoadFromOffset(
        kTemp,
        Address(kTemp, target::Isolate::has_resumption_breakpoints_offset()),
        kUnsignedByte);
    __ CompareImmediate(kTemp, 0);
    __ BranchIf(NOT_EQUAL, &call_runtime);
#endif
  }

  __ LoadFromOffset(CallingConventions::kReturnReg,
                    Address(FPREG, param_offset + 3 * target::kWordSize));

  __ Jump(kResumePc);

  __ Comment("Call runtime to throw exception or deopt");
  __ Bind(&call_runtime);

  __ LoadFromOffset(kStackTrace,
                    Address(FPREG, param_offset + 1 * target::kWordSize));
  static_assert((kStackTrace != CODE_REG) && (kStackTrace != PP),
                "should not interfere");

  // Set return address as if suspended Dart function called
  // stub with kResumePc as a return address.
  __ SetReturnAddress(kResumePc);

  if (!FLAG_precompiled_mode) {
    __ LoadFromOffset(CODE_REG, THR, target::Thread::resume_stub_offset());
  }
#if !defined(TARGET_ARCH_IA32)
  __ set_constant_pool_allowed(false);
#endif
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make room for (unused) result.
  __ PushRegistersInOrder({kException, kStackTrace});
  __ CallRuntime(kResumeFrameRuntimeEntry, /*argument_count=*/2);

  if (FLAG_precompiled_mode) {
    __ Breakpoint();
  } else {
    __ LeaveStubFrame();
    __ LoadFromOffset(CallingConventions::kReturnReg,
                      Address(FPREG, param_offset + 3 * target::kWordSize));
    // Lazy deoptimize.
    __ Ret();
  }
}

void StubCodeCompiler::GenerateReturnStub(
    intptr_t return_entry_point_offset_in_thread,
    intptr_t return_function_offset_in_object_store,
    intptr_t return_stub_offset_in_thread) {
  const Register kSuspendState = ReturnStubABI::kSuspendStateReg;

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
  SPILLS_LR_TO_FRAME({});  // Simulate entering the caller (Dart) frame.
#endif

  __ LoadFromOffset(kSuspendState, Address(FPREG, SuspendStateFpOffset()));
#ifdef DEBUG
  {
    Label okay;
    __ CompareObject(kSuspendState, NullObject());
    __ BranchIf(NOT_EQUAL, &okay);
    __ Breakpoint();
    __ Bind(&okay);
  }
#endif
  __ LeaveDartFrame();
  if (!FLAG_precompiled_mode) {
    __ LoadFromOffset(CODE_REG, THR, return_stub_offset_in_thread);
  }
  __ EnterStubFrame();
  __ PushRegistersInOrder({kSuspendState, CallingConventions::kReturnReg});
  CallDartCoreLibraryFunction(assembler, return_entry_point_offset_in_thread,
                              return_function_offset_in_object_store);
  __ LeaveStubFrame();
  __ Ret();
}

void StubCodeCompiler::GenerateReturnAsyncStub() {
  GenerateReturnStub(
      target::Thread::suspend_state_return_async_entry_point_offset(),
      target::ObjectStore::suspend_state_return_async_offset(),
      target::Thread::return_async_stub_offset());
}

void StubCodeCompiler::GenerateReturnAsyncNotFutureStub() {
  GenerateReturnStub(
      target::Thread::
          suspend_state_return_async_not_future_entry_point_offset(),
      target::ObjectStore::suspend_state_return_async_not_future_offset(),
      target::Thread::return_async_not_future_stub_offset());
}

void StubCodeCompiler::GenerateReturnAsyncStarStub() {
  GenerateReturnStub(
      target::Thread::suspend_state_return_async_star_entry_point_offset(),
      target::ObjectStore::suspend_state_return_async_star_offset(),
      target::Thread::return_async_star_stub_offset());
}

void StubCodeCompiler::GenerateAsyncExceptionHandlerStub() {
  const Register kSuspendState = AsyncExceptionHandlerStubABI::kSuspendStateReg;
  ASSERT(kSuspendState != kExceptionObjectReg);
  ASSERT(kSuspendState != kStackTraceObjectReg);
  Label rethrow_exception;

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
  SPILLS_LR_TO_FRAME({});  // Simulate entering the caller (Dart) frame.
#endif

  __ LoadFromOffset(kSuspendState, Address(FPREG, SuspendStateFpOffset()));

  // Check if suspend_state is initialized. Otherwise
  // exception was thrown from the prologue code and
  // should be synchronously propagated.
  __ CompareObject(kSuspendState, NullObject());
  __ BranchIf(EQUAL, &rethrow_exception);

  __ LeaveDartFrame();
  if (!FLAG_precompiled_mode) {
    __ LoadFromOffset(CODE_REG, THR,
                      target::Thread::async_exception_handler_stub_offset());
  }
  __ EnterStubFrame();
  __ PushRegistersInOrder(
      {kSuspendState, kExceptionObjectReg, kStackTraceObjectReg});
  CallDartCoreLibraryFunction(
      assembler,
      target::Thread::suspend_state_handle_exception_entry_point_offset(),
      target::ObjectStore::suspend_state_handle_exception_offset());
  __ LeaveStubFrame();
  __ Ret();

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
  // Rethrow case is used when Dart frame is still on the stack.
  SPILLS_LR_TO_FRAME({});
#endif
  __ Comment("Rethrow exception");
  __ Bind(&rethrow_exception);
  __ LeaveDartFrame();
  if (!FLAG_precompiled_mode) {
    __ LoadFromOffset(CODE_REG, THR,
                      target::Thread::async_exception_handler_stub_offset());
  }
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make room for (unused) result.
  __ PushRegistersInOrder({kExceptionObjectReg, kStackTraceObjectReg});
  __ CallRuntime(kReThrowRuntimeEntry, /*argument_count=*/2);
  __ Breakpoint();
}

void StubCodeCompiler::GenerateCloneSuspendStateStub() {
  const Register kSource = CloneSuspendStateStubABI::kSourceReg;
  const Register kDestination = CloneSuspendStateStubABI::kDestinationReg;
  const Register kTemp = CloneSuspendStateStubABI::kTempReg;
  const Register kFrameSize = CloneSuspendStateStubABI::kFrameSizeReg;
  const Register kSrcFrame = CloneSuspendStateStubABI::kSrcFrameReg;
  const Register kDstFrame = CloneSuspendStateStubABI::kDstFrameReg;
  Label alloc_slow_case;

#ifdef DEBUG
  {
    // Can only clone _SuspendState objects with copied frames.
    Label okay;
    __ LoadFromOffset(kTemp,
                      FieldAddress(kSource, target::SuspendState::pc_offset()));
    __ CompareImmediate(kTemp, 0);
    __ BranchIf(NOT_EQUAL, &okay);
    __ Breakpoint();
    __ Bind(&okay);
  }
#endif

  __ LoadFromOffset(
      kFrameSize,
      FieldAddress(kSource, target::SuspendState::frame_size_offset()));

  GenerateAllocateSuspendState(assembler, &alloc_slow_case, kDestination,
                               kFrameSize, kTemp);

  // Copy pc.
  __ LoadFromOffset(kTemp,
                    FieldAddress(kSource, target::SuspendState::pc_offset()));
  __ StoreToOffset(
      kTemp, FieldAddress(kDestination, target::SuspendState::pc_offset()));

  // Copy function_data.
  __ LoadCompressedFieldFromOffset(
      kTemp, kSource, target::SuspendState::function_data_offset());
  __ StoreCompressedIntoObjectNoBarrier(
      kDestination,
      FieldAddress(kDestination, target::SuspendState::function_data_offset()),
      kTemp);

  // Copy then_callback.
  __ LoadCompressedFieldFromOffset(
      kTemp, kSource, target::SuspendState::then_callback_offset());
  __ StoreCompressedIntoObjectNoBarrier(
      kDestination,
      FieldAddress(kDestination, target::SuspendState::then_callback_offset()),
      kTemp);

  // Copy error_callback.
  __ LoadCompressedFieldFromOffset(
      kTemp, kSource, target::SuspendState::error_callback_offset());
  __ StoreCompressedIntoObjectNoBarrier(
      kDestination,
      FieldAddress(kDestination, target::SuspendState::error_callback_offset()),
      kTemp);

  // Copy payload frame.
  if (kSrcFrame == THR) {
    __ PushRegister(THR);
  }
  const uword offset = target::SuspendState::payload_offset() - kHeapObjectTag;
  __ AddImmediate(kSrcFrame, kSource, offset);
  __ AddImmediate(kDstFrame, kDestination, offset);
  __ CopyMemoryWords(kSrcFrame, kDstFrame, kFrameSize, kTemp);
  if (kSrcFrame == THR) {
    __ PopRegister(THR);
  }

  // Update value of :suspend_state variable in the copied frame
  // for the new SuspendState.
  __ LoadFromOffset(
      kTemp,
      FieldAddress(kDestination, target::SuspendState::frame_size_offset()));
  __ AddRegisters(kTemp, kDestination);
  __ StoreToOffset(kDestination,
                   FieldAddress(kTemp, target::SuspendState::payload_offset() +
                                           SuspendStateFpOffset()));

  __ MoveRegister(CallingConventions::kReturnReg, kDestination);
  __ Ret();

  __ Bind(&alloc_slow_case);
  __ Comment("CloneSuspendState slow case");
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make space on stack for the return value.
  __ PushRegister(kSource);
  __ CallRuntime(kCloneSuspendStateRuntimeEntry, 1);
  __ Drop(1);                                      // Drop argument
  __ PopRegister(CallingConventions::kReturnReg);  // Get result.
  __ LeaveStubFrame();
  __ Ret();
}

void StubCodeCompiler::GenerateFfiAsyncCallbackSendStub() {
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make space on stack for the return value.
  __ PushRegister(FfiAsyncCallbackSendStubABI::kArgsReg);
  __ CallRuntime(kFfiAsyncCallbackSendRuntimeEntry, 1);
  __ Drop(1);                                      // Drop argument.
  __ PopRegister(CallingConventions::kReturnReg);  // Get result.
  __ LeaveStubFrame();
  __ Ret();
}

void StubCodeCompiler::InsertBSSRelocation(BSS::Relocation reloc) {
  ASSERT(pc_descriptors_list_ != nullptr);
  const intptr_t pc_offset = assembler->InsertAlignedRelocation(reloc);
  pc_descriptors_list_->AddDescriptor(
      UntaggedPcDescriptors::kBSSRelocation, pc_offset,
      /*deopt_id=*/DeoptId::kNone,
      /*root_pos=*/TokenPosition::kNoSource,
      /*try_index=*/-1,
      /*yield_index=*/UntaggedPcDescriptors::kInvalidYieldIndex);
}

#if !defined(TARGET_ARCH_IA32)
static void GenerateSubtypeTestCacheLoopBody(Assembler* assembler,
                                             int n,
                                             Register null_reg,
                                             Register cache_entry_reg,
                                             Register instance_cid_or_sig_reg,
                                             Register instance_type_args_reg,
                                             Register parent_fun_type_args_reg,
                                             Register delayed_type_args_reg,
                                             Label* found,
                                             Label* not_found,
                                             Label* next_iteration) {
  __ Comment("Loop");
  // LoadAcquireCompressed assumes the loaded value is a heap object and
  // extends it with the heap bits if compressed. However, the entry may be
  // a Smi.
  //
  // Instead, just use LoadAcquire to load the lower bits when compressed and
  // only compare the low bits of the loaded value using CompareObjectRegisters.
  __ LoadAcquire(TypeTestABI::kScratchReg, cache_entry_reg,
                 target::kCompressedWordSize *
                     target::SubtypeTestCache::kInstanceCidOrSignature,
                 kObjectBytes);
  __ CompareObjectRegisters(TypeTestABI::kScratchReg, null_reg);
  __ BranchIf(EQUAL, not_found, Assembler::kNearJump);
  __ CompareObjectRegisters(TypeTestABI::kScratchReg, instance_cid_or_sig_reg);
  if (n == 1) {
    __ BranchIf(EQUAL, found, Assembler::kNearJump);
    return;
  }

  __ BranchIf(NOT_EQUAL, next_iteration, Assembler::kNearJump);
  __ CompareWithMemoryValue(
      instance_type_args_reg,
      Address(cache_entry_reg,
              target::kCompressedWordSize *
                  target::SubtypeTestCache::kInstanceTypeArguments),
      kObjectBytes);
  if (n == 2) {
    __ BranchIf(EQUAL, found, Assembler::kNearJump);
    return;
  }

  __ BranchIf(NOT_EQUAL, next_iteration, Assembler::kNearJump);
  __ CompareWithMemoryValue(
      TypeTestABI::kInstantiatorTypeArgumentsReg,
      Address(cache_entry_reg,
              target::kCompressedWordSize *
                  target::SubtypeTestCache::kInstantiatorTypeArguments),
      kObjectBytes);
  if (n == 3) {
    __ BranchIf(EQUAL, found, Assembler::kNearJump);
    return;
  }

  __ BranchIf(NOT_EQUAL, next_iteration, Assembler::kNearJump);
  __ CompareWithMemoryValue(
      TypeTestABI::kFunctionTypeArgumentsReg,
      Address(cache_entry_reg,
              target::kCompressedWordSize *
                  target::SubtypeTestCache::kFunctionTypeArguments),
      kObjectBytes);
  if (n == 4) {
    __ BranchIf(EQUAL, found, Assembler::kNearJump);
    return;
  }

  __ BranchIf(NOT_EQUAL, next_iteration, Assembler::kNearJump);
  __ CompareWithMemoryValue(
      parent_fun_type_args_reg,
      Address(
          cache_entry_reg,
          target::kCompressedWordSize *
              target::SubtypeTestCache::kInstanceParentFunctionTypeArguments),
      kObjectBytes);
  if (n == 5) {
    __ BranchIf(EQUAL, found, Assembler::kNearJump);
    return;
  }

  __ BranchIf(NOT_EQUAL, next_iteration, Assembler::kNearJump);
  __ CompareWithMemoryValue(
      delayed_type_args_reg,
      Address(
          cache_entry_reg,
          target::kCompressedWordSize *
              target::SubtypeTestCache::kInstanceDelayedFunctionTypeArguments),
      kObjectBytes);
  if (n == 6) {
    __ BranchIf(EQUAL, found, Assembler::kNearJump);
    return;
  }

  __ BranchIf(NOT_EQUAL, next_iteration, Assembler::kNearJump);
  __ CompareWithMemoryValue(
      TypeTestABI::kDstTypeReg,
      Address(cache_entry_reg, target::kCompressedWordSize *
                                   target::SubtypeTestCache::kDestinationType),
      kObjectBytes);
  __ BranchIf(EQUAL, found, Assembler::kNearJump);
}

// An object that uses RAII to load from and store to the stack when
// appropriate, allowing the code within that scope to act as if the given
// register is always provided. Either the Register value stored at [reg] must
// be a valid register (not kNoRegister) or [depth] must be a valid stack depth
// (not StackRegisterScope::kNoDepth).
//
// When the Register value stored at [reg] is a valid register, this scope
// generates no assembly and does not change the value stored at [reg].
//
// When [depth] is a valid stack depth, this scope object performs the
// following actions:
//
// On construction:
// * Generates assembly to load the value on the stack at [depth] into [alt].
// * Sets the Register value pointed to by [reg] to [alt].
//
// On destruction:
// * Generates assembly to store the value of [alt] into the stack at [depth].
// * Resets the Register value pointed to by [reg] to kNoRegister.
class StackRegisterScope : ValueObject {
 public:
  StackRegisterScope(Assembler* assembler,
                     Register* reg,
                     intptr_t depth,
                     Register alt = TMP)
      : assembler(assembler), reg_(reg), depth_(depth), alt_(alt) {
    if (depth_ != kNoDepth) {
      ASSERT(depth_ >= 0);
      ASSERT(*reg_ == kNoRegister);
      ASSERT(alt_ != kNoRegister);
      __ LoadFromStack(alt_, depth_);
      *reg_ = alt_;
    } else {
      ASSERT(*reg_ != kNoRegister);
    }
  }

  ~StackRegisterScope() {
    if (depth_ != kNoDepth) {
      __ StoreToStack(alt_, depth_);
      *reg_ = kNoRegister;
    }
  }

  static constexpr intptr_t kNoDepth = kIntptrMin;

 private:
  Assembler* const assembler;
  Register* const reg_;
  const intptr_t depth_;
  const Register alt_;
};

// Same inputs as StubCodeCompiler::GenerateSubtypeTestCacheSearch with
// the following additional requirements:
// - catch_entry_reg: the address of the backing array for the cache.
// - TypeTestABI::kScratchReg: the Smi value of the length field for the
//   backing array in cache_entry_reg
//
// Also expects that all the STC entry input registers have been filled.
static void GenerateSubtypeTestCacheHashSearch(
    Assembler* assembler,
    int n,
    Register null_reg,
    Register cache_entry_reg,
    Register instance_cid_or_sig_reg,
    Register instance_type_args_reg,
    Register parent_fun_type_args_reg,
    Register delayed_type_args_reg,
    Register cache_entry_end_reg,
    Register cache_contents_size_reg,
    Register probe_distance_reg,
    const StubCodeCompiler::STCSearchExitGenerator& gen_found,
    const StubCodeCompiler::STCSearchExitGenerator& gen_not_found) {
  // Since the test entry size is a power of 2, we can use shr to divide.
  const intptr_t kTestEntryLengthLog2 =
      Utils::ShiftForPowerOfTwo(target::SubtypeTestCache::kTestEntryLength);

  // Before we finish calculating the initial probe entry, we'll need the
  // starting cache entry and the number of entries. We'll store these in
  // [cache_contents_size_reg] and [probe_distance_reg] (or their equivalent
  // stack slots), respectively.
  __ Comment("Hash cache traversal");
  __ Comment("Calculating number of entries");
  // The array length is a Smi so it needs to be untagged.
  __ SmiUntag(TypeTestABI::kScratchReg);
  __ LsrImmediate(TypeTestABI::kScratchReg, kTestEntryLengthLog2);
  if (probe_distance_reg != kNoRegister) {
    __ MoveRegister(probe_distance_reg, TypeTestABI::kScratchReg);
  } else {
    __ PushRegister(TypeTestABI::kScratchReg);
  }

  __ Comment("Calculating starting entry address");
  __ AddImmediate(cache_entry_reg,
                  target::Array::data_offset() - kHeapObjectTag);
  if (cache_contents_size_reg != kNoRegister) {
    __ MoveRegister(cache_contents_size_reg, cache_entry_reg);
  } else {
    __ PushRegister(cache_entry_reg);
  }

  __ Comment("Calculating end of entries address");
  __ LslImmediate(TypeTestABI::kScratchReg,
                  kTestEntryLengthLog2 + target::kCompressedWordSizeLog2);
  __ AddRegisters(TypeTestABI::kScratchReg, cache_entry_reg);
  if (cache_entry_end_reg != kNoRegister) {
    __ MoveRegister(cache_entry_end_reg, TypeTestABI::kScratchReg);
  } else {
    __ PushRegister(TypeTestABI::kScratchReg);
  }

  // At this point, the stack is in the following order, if the corresponding
  // value doesn't have a register assignment:
  // <number of total entries in cache array>
  // <cache array entries start>
  // <cache array entries end>
  // --------- top of stack
  //
  // and after calculating the initial entry, we'll replace them as follows:
  // <probe distance>
  // <-cache array contents size> (note this is _negative_)
  // <cache array entries end>
  // ---------- top of stack
  //
  // So name them according to their later use.
  intptr_t kProbeDistanceDepth = StackRegisterScope::kNoDepth;
  intptr_t kHashStackElements = 0;
  if (probe_distance_reg == kNoRegister) {
    kProbeDistanceDepth = 0;
    kHashStackElements++;
  }
  intptr_t kCacheContentsSizeDepth = StackRegisterScope::kNoDepth;
  if (cache_contents_size_reg == kNoRegister) {
    kProbeDistanceDepth++;
    kHashStackElements++;
    kCacheContentsSizeDepth = 0;
  }
  intptr_t kCacheArrayEndDepth = StackRegisterScope::kNoDepth;
  if (cache_entry_end_reg == kNoRegister) {
    kProbeDistanceDepth++;
    kCacheContentsSizeDepth++;
    kHashStackElements++;
    kCacheArrayEndDepth = 0;
  }

  // After this point, any exits should go through one of these two labels,
  // which will pop the extra stack elements pushed above.
  Label found, not_found;

  // When retrieving hashes from objects below, note that a hash of 0 means
  // the hash hasn't been computed yet and we need to go to runtime.
  auto get_abstract_type_hash = [&](Register dst, Register src,
                                    const char* name) {
    ASSERT(dst != kNoRegister);
    ASSERT(src != kNoRegister);
    __ Comment("Loading %s type hash", name);
    __ LoadFromSlot(dst, src, Slot::AbstractType_hash());
    __ SmiUntag(dst);
    __ CompareImmediate(dst, 0);
    __ BranchIf(EQUAL, &not_found);
  };
  auto get_type_arguments_hash = [&](Register dst, Register src,
                                     const char* name) {
    ASSERT(dst != kNoRegister);
    ASSERT(src != kNoRegister);
    Label done;
    __ Comment("Loading %s type arguments hash", name);
    // Preload the hash value for TypeArguments::null() so control can jump
    // to done if null.
    __ LoadImmediate(dst, TypeArguments::kAllDynamicHash);
    __ CompareRegisters(src, null_reg);
    __ BranchIf(EQUAL, &done, Assembler::kNearJump);
    __ LoadFromSlot(dst, src, Slot::TypeArguments_hash());
    __ SmiUntag(dst);
    __ CompareImmediate(dst, 0);
    __ BranchIf(EQUAL, &not_found);
    __ Bind(&done);
  };

  __ Comment("Hash the entry inputs");
  {
    Label done;
    // Assume a Smi tagged instance cid to avoid a branch in the common case.
    __ MoveRegister(cache_entry_reg, instance_cid_or_sig_reg);
    __ SmiUntag(cache_entry_reg);
    __ BranchIfSmi(instance_cid_or_sig_reg, &done, Assembler::kNearJump);
    get_abstract_type_hash(cache_entry_reg, instance_cid_or_sig_reg,
                           "closure signature");
    __ Bind(&done);
  }
  if (n >= 7) {
    get_abstract_type_hash(TypeTestABI::kScratchReg, TypeTestABI::kDstTypeReg,
                           "destination");
    __ CombineHashes(cache_entry_reg, TypeTestABI::kScratchReg);
  }
  if (n >= 6) {
    get_type_arguments_hash(TypeTestABI::kScratchReg, delayed_type_args_reg,
                            "delayed");
    __ CombineHashes(cache_entry_reg, TypeTestABI::kScratchReg);
  }
  if (n >= 5) {
    get_type_arguments_hash(TypeTestABI::kScratchReg, parent_fun_type_args_reg,
                            "parent function");
    __ CombineHashes(cache_entry_reg, TypeTestABI::kScratchReg);
  }
  if (n >= 4) {
    get_type_arguments_hash(TypeTestABI::kScratchReg,
                            TypeTestABI::kFunctionTypeArgumentsReg, "function");
    __ CombineHashes(cache_entry_reg, TypeTestABI::kScratchReg);
  }
  if (n >= 3) {
    get_type_arguments_hash(TypeTestABI::kScratchReg,
                            TypeTestABI::kInstantiatorTypeArgumentsReg,
                            "instantiator");
    __ CombineHashes(cache_entry_reg, TypeTestABI::kScratchReg);
  }
  if (n >= 2) {
    get_type_arguments_hash(TypeTestABI::kScratchReg, instance_type_args_reg,
                            "instance");
    __ CombineHashes(cache_entry_reg, TypeTestABI::kScratchReg);
  }
  __ FinalizeHash(cache_entry_reg);

  // This requires the number of entries in a hash cache to be a power of 2.
  __ Comment("Converting hash to probe entry index");
  {
    StackRegisterScope scope(assembler, &probe_distance_reg,
                             kProbeDistanceDepth, TypeTestABI::kScratchReg);
    // The entry count is not needed after this point; create the mask in place.
    __ AddImmediate(probe_distance_reg, -1);
    __ AndRegisters(cache_entry_reg, probe_distance_reg);
    // Now set the register to the initial probe distance in words.
    __ Comment("Set initial probe distance");
    __ LoadImmediate(probe_distance_reg,
                     target::kCompressedWordSize *
                         target::SubtypeTestCache::kTestEntryLength);
  }

  // Now cache_entry_reg is the starting probe entry index.
  __ Comment("Converting probe entry index to probe entry address");
  {
    StackRegisterScope scope(assembler, &cache_contents_size_reg,
                             kCacheContentsSizeDepth, TypeTestABI::kScratchReg);
    __ LslImmediate(cache_entry_reg,
                    kTestEntryLengthLog2 + target::kCompressedWordSizeLog2);
    __ AddRegisters(cache_entry_reg, cache_contents_size_reg);
    // Now set the register to the negated size of the cache contents in words.
    __ Comment("Set negated cache contents size");
    if (cache_entry_end_reg != kNoRegister) {
      __ SubRegisters(cache_contents_size_reg, cache_entry_end_reg);
    } else {
      __ LoadFromStack(TMP, kCacheArrayEndDepth);
      __ SubRegisters(cache_contents_size_reg, TMP);
    }
  }

  Label loop, next_iteration;
  __ Bind(&loop);
  GenerateSubtypeTestCacheLoopBody(
      assembler, n, null_reg, cache_entry_reg, instance_cid_or_sig_reg,
      instance_type_args_reg, parent_fun_type_args_reg, delayed_type_args_reg,
      &found, &not_found, &next_iteration);
  __ Bind(&next_iteration);
  __ Comment("Move to next entry");
  {
    StackRegisterScope scope(assembler, &probe_distance_reg,
                             kProbeDistanceDepth, TypeTestABI::kScratchReg);
    __ AddRegisters(cache_entry_reg, probe_distance_reg);
    __ Comment("Adjust probe distance");
    __ AddImmediate(probe_distance_reg,
                    target::kCompressedWordSize *
                        target::SubtypeTestCache::kTestEntryLength);
  }
  __ Comment("Check for leaving array");
  // Make sure we haven't run off the array.
  if (cache_entry_end_reg != kNoRegister) {
    __ CompareRegisters(cache_entry_reg, cache_entry_end_reg);
  } else {
    __ CompareToStack(cache_entry_reg, kCacheArrayEndDepth);
  }
  __ BranchIf(LESS, &loop, Assembler::kNearJump);
  __ Comment("Wrap around to start of entries");
  // Add the negated size of the cache contents.
  if (cache_contents_size_reg != kNoRegister) {
    __ AddRegisters(cache_entry_reg, cache_contents_size_reg);
  } else {
    __ LoadFromStack(TypeTestABI::kScratchReg, kCacheContentsSizeDepth);
    __ AddRegisters(cache_entry_reg, TypeTestABI::kScratchReg);
  }
  __ Jump(&loop, Assembler::kNearJump);

  __ Bind(&found);
  __ Comment("Hash found");
  __ Drop(kHashStackElements);
  gen_found(assembler, n);
  __ Bind(&not_found);
  __ Comment("Hash not found");
  __ Drop(kHashStackElements);
  gen_not_found(assembler, n);
}

// Same inputs as StubCodeCompiler::GenerateSubtypeTestCacheSearch with
// the following additional requirement:
// - catch_entry_reg: the address of the backing array for the cache.
//
// Also expects that all the STC entry input registers have been filled.
static void GenerateSubtypeTestCacheLinearSearch(
    Assembler* assembler,
    int n,
    Register null_reg,
    Register cache_entry_reg,
    Register instance_cid_or_sig_reg,
    Register instance_type_args_reg,
    Register parent_fun_type_args_reg,
    Register delayed_type_args_reg,
    const StubCodeCompiler::STCSearchExitGenerator& gen_found,
    const StubCodeCompiler::STCSearchExitGenerator& gen_not_found) {
  __ Comment("Linear cache traversal");
  __ AddImmediate(cache_entry_reg,
                  target::Array::data_offset() - kHeapObjectTag);

  Label found, not_found, loop, next_iteration;
  __ Bind(&loop);
  GenerateSubtypeTestCacheLoopBody(
      assembler, n, null_reg, cache_entry_reg, instance_cid_or_sig_reg,
      instance_type_args_reg, parent_fun_type_args_reg, delayed_type_args_reg,
      &found, &not_found, &next_iteration);
  __ Bind(&next_iteration);
  __ Comment("Next iteration");
  __ AddImmediate(
      cache_entry_reg,
      target::kCompressedWordSize * target::SubtypeTestCache::kTestEntryLength);
  __ Jump(&loop, Assembler::kNearJump);

  __ Bind(&found);
  __ Comment("Linear found");
  gen_found(assembler, n);
  __ Bind(&not_found);
  __ Comment("Linear not found");
  gen_not_found(assembler, n);
}

void StubCodeCompiler::GenerateSubtypeTestCacheSearch(
    Assembler* assembler,
    int n,
    Register null_reg,
    Register cache_entry_reg,
    Register instance_cid_or_sig_reg,
    Register instance_type_args_reg,
    Register parent_fun_type_args_reg,
    Register delayed_type_args_reg,
    Register cache_entry_end_reg,
    Register cache_contents_size_reg,
    Register probe_distance_reg,
    const StubCodeCompiler::STCSearchExitGenerator& gen_found,
    const StubCodeCompiler::STCSearchExitGenerator& gen_not_found) {
#if defined(DEBUG)
  RegisterSet input_regs;
  ASSERT(null_reg != kNoRegister);
  input_regs.AddRegister(null_reg);
  ASSERT(cache_entry_reg != kNoRegister);
  ASSERT(!input_regs.ContainsRegister(cache_entry_reg));
  input_regs.AddRegister(cache_entry_reg);
  ASSERT(instance_cid_or_sig_reg != kNoRegister);
  ASSERT(!input_regs.ContainsRegister(instance_cid_or_sig_reg));
  input_regs.AddRegister(instance_cid_or_sig_reg);
  if (n >= 2) {
    ASSERT(instance_type_args_reg != kNoRegister);
    ASSERT(!input_regs.ContainsRegister(instance_type_args_reg));
    input_regs.AddRegister(instance_type_args_reg);
  }
  if (n >= 5) {
    ASSERT(parent_fun_type_args_reg != kNoRegister);
    ASSERT(!input_regs.ContainsRegister(parent_fun_type_args_reg));
    input_regs.AddRegister(parent_fun_type_args_reg);
  }
  ASSERT(!input_regs.ContainsRegister(TypeTestABI::kInstanceReg));
  if (n >= 6) {
    ASSERT(delayed_type_args_reg != kNoRegister);
    ASSERT(!input_regs.ContainsRegister(delayed_type_args_reg));
    input_regs.AddRegister(delayed_type_args_reg);
  }
  if (cache_entry_end_reg != kNoRegister) {
    ASSERT(!input_regs.ContainsRegister(cache_entry_end_reg));
    input_regs.AddRegister(cache_entry_end_reg);
  }
  if (cache_contents_size_reg != kNoRegister) {
    ASSERT(!input_regs.ContainsRegister(cache_contents_size_reg));
    input_regs.AddRegister(cache_contents_size_reg);
  }
  if (probe_distance_reg != kNoRegister) {
    ASSERT(!input_regs.ContainsRegister(probe_distance_reg));
    input_regs.AddRegister(probe_distance_reg);
  }
  // We can allow the use of the registers below only if we're not expecting
  // them as an inspected input.
  if (n >= 3) {
    ASSERT(!input_regs.ContainsRegister(
        TypeTestABI::kInstantiatorTypeArgumentsReg));
  }
  if (n >= 4) {
    ASSERT(
        !input_regs.ContainsRegister(TypeTestABI::kFunctionTypeArgumentsReg));
  }
  if (n >= 7) {
    ASSERT(!input_regs.ContainsRegister(TypeTestABI::kDstTypeReg));
  }
  // We use this as a scratch, so it has to be distinct from the others.
  ASSERT(!input_regs.ContainsRegister(TypeTestABI::kScratchReg));

  // Verify the STC we received has exactly as many inputs as this stub expects.
  Label search_stc;
  __ LoadFromSlot(TypeTestABI::kScratchReg, TypeTestABI::kSubtypeTestCacheReg,
                  Slot::SubtypeTestCache_num_inputs());
  __ CompareImmediate(TypeTestABI::kScratchReg, n);
  __ BranchIf(EQUAL, &search_stc, Assembler::kNearJump);
  __ Breakpoint();
  __ Bind(&search_stc);
#endif

  __ LoadAcquireCompressed(
      cache_entry_reg, TypeTestABI::kSubtypeTestCacheReg,
      target::SubtypeTestCache::cache_offset() - kHeapObjectTag);

  // Fill in all the STC input registers.
  Label initialized, not_closure;
  if (n >= 3) {
    __ LoadClassIdMayBeSmi(instance_cid_or_sig_reg, TypeTestABI::kInstanceReg);
  } else {
    // If the type is fully instantiated, then it can be determined at compile
    // time whether Smi is a subtype of the type or not. Thus, this code should
    // never be called with a Smi instance.
    __ LoadClassId(instance_cid_or_sig_reg, TypeTestABI::kInstanceReg);
  }
  __ CompareImmediate(instance_cid_or_sig_reg, kClosureCid);
  __ BranchIf(NOT_EQUAL, &not_closure, Assembler::kNearJump);

  // Closure handling.
  {
    __ Comment("Closure");
    __ LoadCompressed(instance_cid_or_sig_reg,
                      FieldAddress(TypeTestABI::kInstanceReg,
                                   target::Closure::function_offset()));
    __ LoadCompressed(instance_cid_or_sig_reg,
                      FieldAddress(instance_cid_or_sig_reg,
                                   target::Function::signature_offset()));
    if (n >= 2) {
      __ LoadCompressed(
          instance_type_args_reg,
          FieldAddress(TypeTestABI::kInstanceReg,
                       target::Closure::instantiator_type_arguments_offset()));
    }
    if (n >= 5) {
      __ LoadCompressed(
          parent_fun_type_args_reg,
          FieldAddress(TypeTestABI::kInstanceReg,
                       target::Closure::function_type_arguments_offset()));
    }
    if (n >= 6) {
      __ LoadCompressed(
          delayed_type_args_reg,
          FieldAddress(TypeTestABI::kInstanceReg,
                       target::Closure::delayed_type_arguments_offset()));
    }

    __ Jump(&initialized, Assembler::kNearJump);
  }

  // Non-Closure handling.
  {
    __ Comment("Non-Closure");
    __ Bind(&not_closure);
    if (n >= 2) {
      Label has_no_type_arguments;
      __ LoadClassById(TypeTestABI::kScratchReg, instance_cid_or_sig_reg);
      __ MoveRegister(instance_type_args_reg, null_reg);
      __ LoadFieldFromOffset(
          TypeTestABI::kScratchReg, TypeTestABI::kScratchReg,
          target::Class::host_type_arguments_field_offset_in_words_offset(),
          kFourBytes);
      __ CompareImmediate(TypeTestABI::kScratchReg,
                          target::Class::kNoTypeArguments, kFourBytes);
      __ BranchIf(EQUAL, &has_no_type_arguments, Assembler::kNearJump);
      __ LoadIndexedCompressed(instance_type_args_reg,
                               TypeTestABI::kInstanceReg, 0,
                               TypeTestABI::kScratchReg);
      __ Bind(&has_no_type_arguments);
      __ Comment("No type arguments");
    }
    __ SmiTag(instance_cid_or_sig_reg);
    if (n >= 5) {
      __ MoveRegister(parent_fun_type_args_reg, null_reg);
    }
    if (n >= 6) {
      __ MoveRegister(delayed_type_args_reg, null_reg);
    }
  }

  __ Bind(&initialized);
  // There is a maximum size for linear caches that is smaller than the size
  // of any hash-based cache, so we check the size of the backing array to
  // determine if this is a linear or hash-based cache.
  //
  // We load it into TypeTestABI::kScratchReg as the hash search code expects
  // it there.
  Label is_hash;
  __ LoadFromSlot(TypeTestABI::kScratchReg, cache_entry_reg,
                  Slot::Array_length());
  __ CompareImmediate(TypeTestABI::kScratchReg,
                      target::ToRawSmi(SubtypeTestCache::kMaxLinearCacheSize));
  __ BranchIf(GREATER, &is_hash);

  GenerateSubtypeTestCacheLinearSearch(
      assembler, n, null_reg, cache_entry_reg, instance_cid_or_sig_reg,
      instance_type_args_reg, parent_fun_type_args_reg, delayed_type_args_reg,
      gen_found, gen_not_found);

  __ Bind(&is_hash);
  GenerateSubtypeTestCacheHashSearch(
      assembler, n, null_reg, cache_entry_reg, instance_cid_or_sig_reg,
      instance_type_args_reg, parent_fun_type_args_reg, delayed_type_args_reg,
      cache_entry_end_reg, cache_contents_size_reg, probe_distance_reg,
      gen_found, gen_not_found);
}
#endif

// See comment on [GenerateSubtypeNTestCacheStub].
void StubCodeCompiler::GenerateSubtype1TestCacheStub() {
  GenerateSubtypeNTestCacheStub(assembler, 1);
}

// See comment on [GenerateSubtypeNTestCacheStub].
void StubCodeCompiler::GenerateSubtype2TestCacheStub() {
  GenerateSubtypeNTestCacheStub(assembler, 2);
}

// See comment on [GenerateSubtypeNTestCacheStub].
void StubCodeCompiler::GenerateSubtype3TestCacheStub() {
  GenerateSubtypeNTestCacheStub(assembler, 3);
}

// See comment on [GenerateSubtypeNTestCacheStub].
void StubCodeCompiler::GenerateSubtype4TestCacheStub() {
  GenerateSubtypeNTestCacheStub(assembler, 4);
}

// See comment on [GenerateSubtypeNTestCacheStub].
void StubCodeCompiler::GenerateSubtype6TestCacheStub() {
  GenerateSubtypeNTestCacheStub(assembler, 6);
}

// See comment on [GenerateSubtypeNTestCacheStub].
void StubCodeCompiler::GenerateSubtype7TestCacheStub() {
  GenerateSubtypeNTestCacheStub(assembler, 7);
}

}  // namespace compiler

}  // namespace dart
