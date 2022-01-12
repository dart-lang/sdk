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

#include "vm/compiler/api/type_check_mode.h"
#include "vm/compiler/assembler/assembler.h"

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

void StubCodeCompiler::GenerateInitStaticFieldStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make room for result.
  __ PushRegister(InitStaticFieldABI::kFieldReg);
  __ CallRuntime(kInitStaticFieldRuntimeEntry, /*argument_count=*/1);
  __ Drop(1);
  __ PopRegister(InitStaticFieldABI::kResultReg);
  __ LeaveStubFrame();
  __ Ret();
}

void StubCodeCompiler::GenerateInitLateStaticFieldStub(Assembler* assembler,
                                                       bool is_final) {
  const Register kResultReg = InitStaticFieldABI::kResultReg;
  const Register kFunctionReg = InitLateStaticFieldInternalRegs::kFunctionReg;
  const Register kFieldReg = InitStaticFieldABI::kFieldReg;
  const Register kAddressReg = InitLateStaticFieldInternalRegs::kAddressReg;
  const Register kScratchReg = InitLateStaticFieldInternalRegs::kScratchReg;

  __ EnterStubFrame();

  __ Comment("Calling initializer function");
  __ PushRegister(kFieldReg);
  __ LoadCompressedFieldFromOffset(
      kFunctionReg, kFieldReg, target::Field::initializer_function_offset());
  if (!FLAG_precompiled_mode) {
    __ LoadCompressedFieldFromOffset(CODE_REG, kFunctionReg,
                                     target::Function::code_offset());
    // Load a GC-safe value for the arguments descriptor (unused but tagged).
    __ LoadImmediate(ARGS_DESC_REG, 0);
  }
  __ Call(FieldAddress(kFunctionReg, target::Function::entry_point_offset()));
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

void StubCodeCompiler::GenerateInitLateStaticFieldStub(Assembler* assembler) {
  GenerateInitLateStaticFieldStub(assembler, /*is_final=*/false);
}

void StubCodeCompiler::GenerateInitLateFinalStaticFieldStub(
    Assembler* assembler) {
  GenerateInitLateStaticFieldStub(assembler, /*is_final=*/true);
}

void StubCodeCompiler::GenerateInitInstanceFieldStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make room for result.
  __ PushRegister(InitInstanceFieldABI::kInstanceReg);
  __ PushRegister(InitInstanceFieldABI::kFieldReg);
  __ CallRuntime(kInitInstanceFieldRuntimeEntry, /*argument_count=*/2);
  __ Drop(2);
  __ PopRegister(InitInstanceFieldABI::kResultReg);
  __ LeaveStubFrame();
  __ Ret();
}

void StubCodeCompiler::GenerateInitLateInstanceFieldStub(Assembler* assembler,
                                                         bool is_final) {
  const Register kFunctionReg = InitLateInstanceFieldInternalRegs::kFunctionReg;
  const Register kInstanceReg = InitInstanceFieldABI::kInstanceReg;
  const Register kFieldReg = InitInstanceFieldABI::kFieldReg;
  const Register kAddressReg = InitLateInstanceFieldInternalRegs::kAddressReg;
  const Register kScratchReg = InitLateInstanceFieldInternalRegs::kScratchReg;

  __ EnterStubFrame();
  // Save for later.
  __ PushRegisterPair(kInstanceReg, kFieldReg);

  // Call initializer function.
  __ PushRegister(kInstanceReg);

  static_assert(
      InitInstanceFieldABI::kResultReg == CallingConventions::kReturnReg,
      "Result is a return value from initializer");

  __ LoadCompressedFieldFromOffset(
      kFunctionReg, InitInstanceFieldABI::kFieldReg,
      target::Field::initializer_function_offset());
  if (!FLAG_precompiled_mode) {
    __ LoadCompressedFieldFromOffset(CODE_REG, kFunctionReg,
                                     target::Function::code_offset());
    // Load a GC-safe value for the arguments descriptor (unused but tagged).
    __ LoadImmediate(ARGS_DESC_REG, 0);
  }
  __ Call(FieldAddress(kFunctionReg, target::Function::entry_point_offset()));
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

void StubCodeCompiler::GenerateInitLateInstanceFieldStub(Assembler* assembler) {
  GenerateInitLateInstanceFieldStub(assembler, /*is_final=*/false);
}

void StubCodeCompiler::GenerateInitLateFinalInstanceFieldStub(
    Assembler* assembler) {
  GenerateInitLateInstanceFieldStub(assembler, /*is_final=*/true);
}

void StubCodeCompiler::GenerateThrowStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make room for (unused) result.
  __ PushRegister(ThrowABI::kExceptionReg);
  __ CallRuntime(kThrowRuntimeEntry, /*argument_count=*/1);
  __ Breakpoint();
}

void StubCodeCompiler::GenerateReThrowStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make room for (unused) result.
  __ PushRegister(ReThrowABI::kExceptionReg);
  __ PushRegister(ReThrowABI::kStackTraceReg);
  __ CallRuntime(kReThrowRuntimeEntry, /*argument_count=*/2);
  __ Breakpoint();
}

void StubCodeCompiler::GenerateAssertBooleanStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make room for (unused) result.
  __ PushRegister(AssertBooleanABI::kObjectReg);
  __ CallRuntime(kNonBoolTypeErrorRuntimeEntry, /*argument_count=*/1);
  __ Breakpoint();
}

void StubCodeCompiler::GenerateAssertSubtypeStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ PushRegister(AssertSubtypeABI::kInstantiatorTypeArgumentsReg);
  __ PushRegister(AssertSubtypeABI::kFunctionTypeArgumentsReg);
  __ PushRegister(AssertSubtypeABI::kSubTypeReg);
  __ PushRegister(AssertSubtypeABI::kSuperTypeReg);
  __ PushRegister(AssertSubtypeABI::kDstNameReg);
  __ CallRuntime(kSubtypeCheckRuntimeEntry, /*argument_count=*/5);
  __ Drop(5);  // Drop unused result as well as arguments.
  __ LeaveStubFrame();
  __ Ret();
}

void StubCodeCompiler::GenerateAssertAssignableStub(Assembler* assembler) {
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
  __ PushRegister(AssertAssignableStubABI::kDstNameReg);
  __ PushRegister(AssertAssignableStubABI::kSubtypeTestReg);
  __ PushObject(Smi::ZoneHandle(Smi::New(kTypeCheckFromInline)));
  __ CallRuntime(kTypeCheckRuntimeEntry, /*argument_count=*/7);
  __ Drop(8);
  __ LeaveStubFrame();
  __ Ret();
#endif
}

void StubCodeCompiler::GenerateInstantiateTypeStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ PushObject(Object::null_object());
  __ PushRegister(InstantiateTypeABI::kTypeReg);
  __ PushRegister(InstantiateTypeABI::kInstantiatorTypeArgumentsReg);
  __ PushRegister(InstantiateTypeABI::kFunctionTypeArgumentsReg);
  __ CallRuntime(kInstantiateTypeRuntimeEntry, /*argument_count=*/3);
  __ Drop(3);
  __ PopRegister(InstantiateTypeABI::kResultTypeReg);
  __ LeaveStubFrame();
  __ Ret();
}

void StubCodeCompiler::GenerateInstanceOfStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make room for the result.
  __ PushRegister(TypeTestABI::kInstanceReg);
  __ PushRegister(TypeTestABI::kDstTypeReg);
  __ PushRegister(TypeTestABI::kInstantiatorTypeArgumentsReg);
  __ PushRegister(TypeTestABI::kFunctionTypeArgumentsReg);
  __ PushRegister(TypeTestABI::kSubtypeTestCacheReg);
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
  // Type references show up in F-bounded polymorphism, which is limited
  // to classes. Thus, TypeRefs only appear in places like class type
  // arguments or the bounds of uninstantiated class type parameters.
  //
  // Since this stub is currently used only by the dynamic versions of
  // AssertSubtype and AssertAssignable, where kDstType is either the bound of
  // a function type parameter or the type of a function parameter
  // (respectively), we should never see a TypeRef here. This check is here
  // in case this changes and we need to update this stub.
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
    __ CompareTypeNullabilityWith(
        scratch1_reg, static_cast<int8_t>(Nullability::kNonNullable));
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

void StubCodeCompiler::GenerateTypeIsTopTypeForSubtypingStub(
    Assembler* assembler) {
  GenerateTypeIsTopTypeForSubtyping(assembler,
                                    /*null_safety=*/false);
}

void StubCodeCompiler::GenerateTypeIsTopTypeForSubtypingNullSafeStub(
    Assembler* assembler) {
  GenerateTypeIsTopTypeForSubtyping(assembler,
                                    /*null_safety=*/true);
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
    __ CompareTypeNullabilityWith(
        kCurrentTypeReg, static_cast<int8_t>(Nullability::kNonNullable));
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
    __ LoadFieldFromOffset(
        kScratchReg, kCurrentTypeReg,
        compiler::target::TypeParameter::nullability_offset(), kByte);
    __ CompareImmediate(kScratchReg,
                        static_cast<int8_t>(Nullability::kNonNullable));
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
                             kUnsignedByte);
      __ LoadIndexedCompressed(kCurrentTypeReg, tav,
                               target::TypeArguments::types_offset(),
                               kIndexReg);
      __ Jump(&check_null_assignable);
    };

    Label function_type_param;
    __ LoadFieldFromOffset(
        kScratchReg, kCurrentTypeReg,
        target::TypeParameter::parameterized_class_id_offset(),
        kUnsignedTwoBytes);
    __ CompareImmediate(kScratchReg, kFunctionCid);
    __ BranchIf(EQUAL, &function_type_param, Assembler::kNearJump);
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

void StubCodeCompiler::GenerateNullIsAssignableToTypeStub(
    Assembler* assembler) {
  GenerateNullIsAssignableToType(assembler,
                                 /*null_safety=*/false);
}

void StubCodeCompiler::GenerateNullIsAssignableToTypeNullSafeStub(
    Assembler* assembler) {
  GenerateNullIsAssignableToType(assembler,
                                 /*null_safety=*/true);
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
void StubCodeCompiler::GenerateDefaultTypeTestStub(Assembler* assembler) {
  __ LoadFromOffset(CODE_REG, THR,
                    target::Thread::slow_type_test_stub_offset());
  __ Jump(FieldAddress(CODE_REG, target::Code::entry_point_offset()));
}

// Used instead of DefaultTypeTestStub when null is assignable.
void StubCodeCompiler::GenerateDefaultNullableTypeTestStub(
    Assembler* assembler) {
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

void StubCodeCompiler::GenerateTopTypeTypeTestStub(Assembler* assembler) {
  __ Ret();
}

void StubCodeCompiler::GenerateUnreachableTypeTestStub(Assembler* assembler) {
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
                           kUnsignedByte);
    __ LoadIndexedCompressed(TypeTestABI::kScratchReg, tav,
                             target::TypeArguments::types_offset(),
                             TypeTestABI::kScratchReg);
    __ Jump(FieldAddress(
        TypeTestABI::kScratchReg,
        target::AbstractType::type_test_stub_entry_point_offset()));
  };

  Label function_type_param;
  __ LoadFieldFromOffset(TypeTestABI::kScratchReg, TypeTestABI::kDstTypeReg,
                         target::TypeParameter::parameterized_class_id_offset(),
                         kUnsignedTwoBytes);
  __ CompareImmediate(TypeTestABI::kScratchReg, kFunctionCid);
  __ BranchIf(EQUAL, &function_type_param, Assembler::kNearJump);
  handle_case(TypeTestABI::kInstantiatorTypeArgumentsReg);
  __ Bind(&function_type_param);
  handle_case(TypeTestABI::kFunctionTypeArgumentsReg);
  __ Bind(&done);
  __ Ret();
}

void StubCodeCompiler::GenerateNullableTypeParameterTypeTestStub(
    Assembler* assembler) {
  BuildTypeParameterTypeTestStub(assembler, /*allow_null=*/true);
}

void StubCodeCompiler::GenerateTypeParameterTypeTestStub(Assembler* assembler) {
  BuildTypeParameterTypeTestStub(assembler, /*allow_null=*/false);
}

static void InvokeTypeCheckFromTypeTestStub(Assembler* assembler,
                                            TypeCheckMode mode) {
  __ PushObject(NullObject());  // Make room for result.
  __ PushRegister(TypeTestABI::kInstanceReg);
  __ PushRegister(TypeTestABI::kDstTypeReg);
  __ PushRegister(TypeTestABI::kInstantiatorTypeArgumentsReg);
  __ PushRegister(TypeTestABI::kFunctionTypeArgumentsReg);
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

void StubCodeCompiler::GenerateLazySpecializeTypeTestStub(
    Assembler* assembler) {
  __ LoadFromOffset(CODE_REG, THR,
                    target::Thread::lazy_specialize_type_test_stub_offset());
  __ EnterStubFrame();
  InvokeTypeCheckFromTypeTestStub(assembler, kTypeCheckFromLazySpecializeStub);
  __ LeaveStubFrame();
  __ Ret();
}

// Used instead of LazySpecializeTypeTestStub when null is assignable.
void StubCodeCompiler::GenerateLazySpecializeNullableTypeTestStub(
    Assembler* assembler) {
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

void StubCodeCompiler::GenerateSlowTypeTestStub(Assembler* assembler) {
  Label done, call_runtime;

  if (!FLAG_precompiled_mode) {
    __ LoadFromOffset(CODE_REG, THR,
                      target::Thread::slow_type_test_stub_offset());
  }
  __ EnterStubFrame();

  // If the subtype-cache is null, it needs to be lazily-created by the runtime.
  __ CompareObject(TypeTestABI::kSubtypeTestCacheReg, NullObject());
  __ BranchIf(EQUAL, &call_runtime, Assembler::kNearJump);

  // If this is not a [Type] object, we'll go to the runtime.
  Label is_simple_case, is_complex_case;
  __ LoadClassId(TypeTestABI::kScratchReg, TypeTestABI::kDstTypeReg);
  __ CompareImmediate(TypeTestABI::kScratchReg, kTypeCid);
  __ BranchIf(NOT_EQUAL, &is_complex_case, Assembler::kNearJump);

  // Check whether this [Type] is instantiated/uninstantiated.
  __ LoadFieldFromOffset(TypeTestABI::kScratchReg, TypeTestABI::kDstTypeReg,
                         target::Type::type_state_offset(), kByte);
  __ CompareImmediate(
      TypeTestABI::kScratchReg,
      target::UntaggedAbstractType::kTypeStateFinalizedInstantiated);
  __ BranchIf(NOT_EQUAL, &is_complex_case, Assembler::kNearJump);

  // This [Type] could be a FutureOr. Subtype2TestCache does not support Smi.
  __ BranchIfSmi(TypeTestABI::kInstanceReg, &is_complex_case);

  // Fall through to &is_simple_case

  const RegisterSet caller_saved_registers(
      TypeTestABI::kSubtypeTestCacheStubCallerSavedRegisters);

  __ Bind(&is_simple_case);
  {
    __ PushRegisters(caller_saved_registers);
    __ Call(StubCodeSubtype3TestCache());
    __ CompareObject(TypeTestABI::kSubtypeTestCacheResultReg,
                     CastHandle<Object>(TrueObject()));
    __ PopRegisters(caller_saved_registers);
    __ BranchIf(EQUAL, &done);  // Cache said: yes.
    __ Jump(&call_runtime, Assembler::kNearJump);
  }

  __ Bind(&is_complex_case);
  {
    __ PushRegisters(caller_saved_registers);
    __ Call(StubCodeSubtype7TestCache());
    __ CompareObject(TypeTestABI::kSubtypeTestCacheResultReg,
                     CastHandle<Object>(TrueObject()));
    __ PopRegisters(caller_saved_registers);
    __ BranchIf(EQUAL, &done);  // Cache said: yes.
    // Fall through to runtime_call
  }

  __ Bind(&call_runtime);

  InvokeTypeCheckFromTypeTestStub(assembler, kTypeCheckFromSlowStub);

  __ Bind(&done);
  __ LeaveStubFrame();
  __ Ret();
}
#else
// Type testing stubs are not implemented on IA32.
#define GENERATE_BREAKPOINT_STUB(Name)                                         \
  void StubCodeCompiler::Generate##Name##Stub(Assembler* assembler) {          \
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
void StubCodeCompiler::GenerateAllocateClosureStub(Assembler* assembler) {
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
  __ PushRegister(AllocateClosureABI::kFunctionReg);
  __ PushRegister(AllocateClosureABI::kContextReg);
  __ CallRuntime(kAllocateClosureRuntimeEntry, 2);
  __ PopRegister(AllocateClosureABI::kContextReg);
  __ PopRegister(AllocateClosureABI::kFunctionReg);
  __ PopRegister(AllocateClosureABI::kResultReg);
  ASSERT(target::WillAllocateNewOrRememberedObject(instance_size));
  EnsureIsNewOrRemembered(assembler, /*preserve_registers=*/false);
  __ LeaveStubFrame();

  // AllocateClosureABI::kResultReg: new object
  __ Ret();
}

// The UnhandledException class lives in the VM isolate, so it cannot cache
// an allocation stub for itself. Instead, we cache it in the stub code list.
void StubCodeCompiler::GenerateAllocateUnhandledExceptionStub(
    Assembler* assembler) {
  Thread* thread = Thread::Current();
  auto class_table = thread->isolate_group()->class_table();
  ASSERT(class_table->HasValidClassAt(kUnhandledExceptionCid));
  const auto& cls = Class::ZoneHandle(thread->zone(),
                                      class_table->At(kUnhandledExceptionCid));
  ASSERT(!cls.IsNull());

  GenerateAllocationStubForClass(assembler, nullptr, cls,
                                 Code::Handle(Code::null()),
                                 Code::Handle(Code::null()));
}

#define TYPED_DATA_ALLOCATION_STUB(clazz)                                      \
  void StubCodeCompiler::GenerateAllocate##clazz##Stub(Assembler* assembler) { \
    GenerateAllocateTypedDataArrayStub(assembler, kTypedData##clazz##Cid);     \
  }
CLASS_LIST_TYPED_DATA(TYPED_DATA_ALLOCATION_STUB)
#undef TYPED_DATA_ALLOCATION_STUB

void StubCodeCompiler::GenerateLateInitializationError(Assembler* assembler,
                                                       bool with_fpu_regs) {
  auto perform_runtime_call = [&]() {
    __ PushRegister(LateInitializationErrorABI::kFieldReg);
    __ CallRuntime(kLateFieldNotInitializedErrorRuntimeEntry,
                   /*argument_count=*/1);
  };
  GenerateSharedStubGeneric(
      assembler, /*save_fpu_registers=*/with_fpu_regs,
      with_fpu_regs
          ? target::Thread::
                late_initialization_error_shared_with_fpu_regs_stub_offset()
          : target::Thread::
                late_initialization_error_shared_without_fpu_regs_stub_offset(),
      /*allow_return=*/false, perform_runtime_call);
}

void StubCodeCompiler::GenerateLateInitializationErrorSharedWithoutFPURegsStub(
    Assembler* assembler) {
  GenerateLateInitializationError(assembler, /*with_fpu_regs=*/false);
}

void StubCodeCompiler::GenerateLateInitializationErrorSharedWithFPURegsStub(
    Assembler* assembler) {
  GenerateLateInitializationError(assembler, /*with_fpu_regs=*/true);
}

void StubCodeCompiler::GenerateNullErrorSharedWithoutFPURegsStub(
    Assembler* assembler) {
  GenerateSharedStub(
      assembler, /*save_fpu_registers=*/false, &kNullErrorRuntimeEntry,
      target::Thread::null_error_shared_without_fpu_regs_stub_offset(),
      /*allow_return=*/false);
}

void StubCodeCompiler::GenerateNullErrorSharedWithFPURegsStub(
    Assembler* assembler) {
  GenerateSharedStub(
      assembler, /*save_fpu_registers=*/true, &kNullErrorRuntimeEntry,
      target::Thread::null_error_shared_with_fpu_regs_stub_offset(),
      /*allow_return=*/false);
}

void StubCodeCompiler::GenerateNullArgErrorSharedWithoutFPURegsStub(
    Assembler* assembler) {
  GenerateSharedStub(
      assembler, /*save_fpu_registers=*/false, &kArgumentNullErrorRuntimeEntry,
      target::Thread::null_arg_error_shared_without_fpu_regs_stub_offset(),
      /*allow_return=*/false);
}

void StubCodeCompiler::GenerateNullArgErrorSharedWithFPURegsStub(
    Assembler* assembler) {
  GenerateSharedStub(
      assembler, /*save_fpu_registers=*/true, &kArgumentNullErrorRuntimeEntry,
      target::Thread::null_arg_error_shared_with_fpu_regs_stub_offset(),
      /*allow_return=*/false);
}

void StubCodeCompiler::GenerateNullCastErrorSharedWithoutFPURegsStub(
    Assembler* assembler) {
  GenerateSharedStub(
      assembler, /*save_fpu_registers=*/false, &kNullCastErrorRuntimeEntry,
      target::Thread::null_cast_error_shared_without_fpu_regs_stub_offset(),
      /*allow_return=*/false);
}

void StubCodeCompiler::GenerateNullCastErrorSharedWithFPURegsStub(
    Assembler* assembler) {
  GenerateSharedStub(
      assembler, /*save_fpu_registers=*/true, &kNullCastErrorRuntimeEntry,
      target::Thread::null_cast_error_shared_with_fpu_regs_stub_offset(),
      /*allow_return=*/false);
}

void StubCodeCompiler::GenerateStackOverflowSharedWithoutFPURegsStub(
    Assembler* assembler) {
  GenerateSharedStub(
      assembler, /*save_fpu_registers=*/false, &kStackOverflowRuntimeEntry,
      target::Thread::stack_overflow_shared_without_fpu_regs_stub_offset(),
      /*allow_return=*/true);
}

void StubCodeCompiler::GenerateStackOverflowSharedWithFPURegsStub(
    Assembler* assembler) {
  GenerateSharedStub(
      assembler, /*save_fpu_registers=*/true, &kStackOverflowRuntimeEntry,
      target::Thread::stack_overflow_shared_with_fpu_regs_stub_offset(),
      /*allow_return=*/true);
}

void StubCodeCompiler::GenerateRangeErrorSharedWithoutFPURegsStub(
    Assembler* assembler) {
  GenerateRangeError(assembler, /*with_fpu_regs=*/false);
}

void StubCodeCompiler::GenerateRangeErrorSharedWithFPURegsStub(
    Assembler* assembler) {
  GenerateRangeError(assembler, /*with_fpu_regs=*/true);
}

void StubCodeCompiler::GenerateFrameAwaitingMaterializationStub(
    Assembler* assembler) {
  __ Breakpoint();  // Marker stub.
}

void StubCodeCompiler::GenerateAsynchronousGapMarkerStub(Assembler* assembler) {
  __ Breakpoint();  // Marker stub.
}

void StubCodeCompiler::GenerateUnknownDartCodeStub(Assembler* assembler) {
  // Enter frame to include caller into the backtrace.
  __ EnterStubFrame();
  __ Breakpoint();  // Marker stub.
}

void StubCodeCompiler::GenerateNotLoadedStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ CallRuntime(kNotLoadedRuntimeEntry, 0);
  __ Breakpoint();
}

#define EMIT_BOX_ALLOCATION(Name)                                              \
  void StubCodeCompiler::GenerateAllocate##Name##Stub(Assembler* assembler) {  \
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

void StubCodeCompiler::GenerateBoxDoubleStub(Assembler* assembler) {
  Label call_runtime;
  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    __ TryAllocate(compiler::DoubleClass(), &call_runtime,
                   compiler::Assembler::kFarJump, BoxDoubleStubABI::kResultReg,
                   BoxDoubleStubABI::kTempReg);
    __ StoreUnboxedDouble(
        BoxDoubleStubABI::kValueReg, BoxDoubleStubABI::kResultReg,
        compiler::target::Double::value_offset() - kHeapObjectTag);
    __ Ret();
  }
  __ Bind(&call_runtime);
  __ EnterStubFrame();
  __ PushObject(NullObject()); /* Make room for result. */
  __ StoreUnboxedDouble(BoxDoubleStubABI::kValueReg, THR,
                        target::Thread::unboxed_double_runtime_arg_offset());
  __ CallRuntime(kBoxDoubleRuntimeEntry, 0);
  __ PopRegister(BoxDoubleStubABI::kResultReg);
  __ LeaveStubFrame();
  __ Ret();
}

void StubCodeCompiler::GenerateDoubleToIntegerStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ StoreUnboxedDouble(DoubleToIntegerStubABI::kInputReg, THR,
                        target::Thread::unboxed_double_runtime_arg_offset());
  __ PushObject(NullObject()); /* Make room for result. */
  __ PushRegister(DoubleToIntegerStubABI::kRecognizedKindReg);
  __ CallRuntime(kDoubleToIntegerRuntimeEntry, 1);
  __ Drop(1);
  __ PopRegister(DoubleToIntegerStubABI::kResultReg);
  __ LeaveStubFrame();
  __ Ret();
}

}  // namespace compiler

}  // namespace dart
