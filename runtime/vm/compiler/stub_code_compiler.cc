// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/runtime_api.h"
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

  // Skip FP + saved PC.
  intptr_t slots_from_fp = 2;
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

  __ LoadField(kFunctionReg,
               FieldAddress(InitInstanceFieldABI::kFieldReg,
                            target::Field::initializer_function_offset()));
  if (!FLAG_precompiled_mode || !FLAG_use_bare_instructions) {
    __ LoadField(CODE_REG,
                 FieldAddress(kFunctionReg, target::Function::code_offset()));
    // Load a GC-safe value for the arguments descriptor (unused but tagged).
    __ LoadImmediate(ARGS_DESC_REG, 0);
  }
  __ Call(FieldAddress(kFunctionReg, target::Function::entry_point_offset()));
  __ Drop(1);  // Drop argument.

  __ PopRegisterPair(kInstanceReg, kFieldReg);
  __ LoadField(
      kScratchReg,
      FieldAddress(kFieldReg, target::Field::host_offset_or_field_id_offset()));
  __ LoadFieldAddressForRegOffset(kAddressReg, kInstanceReg, kScratchReg);

  Label throw_exception;
  if (is_final) {
    __ LoadMemoryValue(kScratchReg, kAddressReg, 0);
    __ CompareObject(kScratchReg, SentinelObject());
    __ BranchIf(NOT_EQUAL, &throw_exception);
  }

#if defined(TARGET_ARCH_IA32)
  // On IA32 StoreIntoObject clobbers value register, so scratch
  // register is used in StoreIntoObject to preserve kResultReg.
  __ MoveRegister(kScratchReg, InitInstanceFieldABI::kResultReg);
  __ StoreIntoObject(kInstanceReg, Address(kAddressReg, 0), kScratchReg);
#else
  __ StoreIntoObject(kInstanceReg, Address(kAddressReg, 0),
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
static void EnsureIsTypeOrTypeParameter(Assembler* assembler,
                                        Register type_reg,
                                        Register scratch_reg) {
#if defined(DEBUG)
  compiler::Label is_type_param_or_type;
  __ LoadClassIdMayBeSmi(scratch_reg, type_reg);
  __ CompareImmediate(scratch_reg, kTypeParameterCid);
  __ BranchIf(EQUAL, &is_type_param_or_type, compiler::Assembler::kNearJump);
  __ CompareImmediate(scratch_reg, kTypeCid);
  __ BranchIf(EQUAL, &is_type_param_or_type, compiler::Assembler::kNearJump);
  // Type references show up in F-bounded polymorphism, which is limited
  // to classes. Thus, TypeRefs only appear in places like class type
  // arguments or the bounds of uninstantiated class type parameters.
  //
  // Since this stub is currently used only by the dynamic versions of
  // AssertSubtype and AssertAssignable, where kDstType is either the bound of
  // a function type parameter or the type of a function parameter
  // (respectively), we should never see a TypeRef here. This check is here
  // in case this changes and we need to update this stub.
  __ Stop("not a type or type parameter");
  __ Bind(&is_type_param_or_type);
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
  EnsureIsTypeOrTypeParameter(assembler, scratch1_reg, scratch2_reg);
  compiler::Label is_type_ref;
  __ CompareClassId(scratch1_reg, kTypeParameterCid, scratch2_reg);
  // Type parameters can't be top types themselves, though a particular
  // instantiation may result in a top type.
  __ BranchIf(EQUAL, &done);
  __ LoadField(
      scratch2_reg,
      compiler::FieldAddress(scratch1_reg,
                             compiler::target::Type::type_class_id_offset()));
  __ SmiUntag(scratch2_reg);
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
  __ LoadField(scratch2_reg,
               compiler::FieldAddress(
                   scratch1_reg, compiler::target::Type::arguments_offset()));
  __ CompareObject(scratch2_reg, Object::null_object());
  // If the arguments are null, then unwrapping gives dynamic, a top type.
  __ BranchIf(EQUAL, &is_top_type, compiler::Assembler::kNearJump);
  __ LoadField(
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

// Version of Instance::NullIsAssignableTo() used when the destination type is
// not known at compile time. Must be kept in sync.
//
// Inputs:
// - TypeTestABI::kInstanceReg: Object to check for assignability.
// - TypeTestABI::kDstTypeReg: Destination type.
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
                "code assumes distinct scratch registers");

  compiler::Label is_assignable, done;
  // Initialize the first scratch register (and thus the output register) with
  // the destination type. We do this before the check to ensure the output
  // register has a non-zero value if !null_safety and kInstanceReg is not null.
  __ MoveRegister(scratch1_reg, TypeTestABI::kDstTypeReg);
  __ CompareObject(TypeTestABI::kInstanceReg, Object::null_object());
  if (null_safety) {
    compiler::Label check_null_assignable;
    // Skip checking the type if not null.
    __ BranchIf(NOT_EQUAL, &done, compiler::Assembler::kNearJump);
    __ Bind(&check_null_assignable);
    // scratch1_reg: Current type to check.
    EnsureIsTypeOrTypeParameter(assembler, scratch1_reg, scratch2_reg);
    compiler::Label is_not_type;
    __ CompareClassId(scratch1_reg, kTypeCid, scratch2_reg);
    __ BranchIf(NOT_EQUAL, &is_not_type, compiler::Assembler::kNearJump);
    __ CompareTypeNullabilityWith(
        scratch1_reg, static_cast<int8_t>(Nullability::kNonNullable));
    __ BranchIf(NOT_EQUAL, &is_assignable, compiler::Assembler::kNearJump);
    // FutureOr is a special case because it may have the non-nullable bit set,
    // but FutureOr<T> functions as the union of T and Future<T>, so it must be
    // unwrapped to see if T is nullable.
    __ LoadField(
        scratch2_reg,
        compiler::FieldAddress(scratch1_reg,
                               compiler::target::Type::type_class_id_offset()));
    __ SmiUntag(scratch2_reg);
    __ CompareImmediate(scratch2_reg, kFutureOrCid);
    __ BranchIf(NOT_EQUAL, &done, compiler::Assembler::kNearJump);
    __ LoadField(scratch2_reg,
                 compiler::FieldAddress(
                     scratch1_reg, compiler::target::Type::arguments_offset()));
    __ CompareObject(scratch2_reg, Object::null_object());
    // If the arguments are null, then unwrapping gives the dynamic type,
    // which can take null.
    __ BranchIf(EQUAL, &is_assignable, compiler::Assembler::kNearJump);
    __ LoadField(
        scratch1_reg,
        compiler::FieldAddress(
            scratch2_reg, compiler::target::TypeArguments::type_at_offset(0)));
    __ Jump(&check_null_assignable, compiler::Assembler::kNearJump);
    __ Bind(&is_not_type);
    // Null is assignable to a type parameter only if it is nullable.
    __ LoadFieldFromOffset(
        scratch2_reg, scratch1_reg,
        compiler::target::TypeParameter::nullability_offset(), kByte);
    __ CompareImmediate(scratch2_reg,
                        static_cast<int8_t>(Nullability::kNonNullable));
    __ BranchIf(EQUAL, &done, compiler::Assembler::kNearJump);
  } else {
    // Null in non-null-safe mode is always assignable.
    __ BranchIf(NOT_EQUAL, &done, compiler::Assembler::kNearJump);
  }
  __ Bind(&is_assignable);
  __ LoadImmediate(output_reg, 0);
  __ Bind(&done);
#if defined(TARGET_ARCH_IA32)
  // Restore preserved scratch registers.
  __ PopRegister(scratch2_reg);
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
                           target::TypeParameter::index_offset(), kTwoBytes);
    __ LoadIndexedPayload(TypeTestABI::kScratchReg, tav,
                          target::TypeArguments::types_offset(),
                          TypeTestABI::kScratchReg, TIMES_WORD_SIZE);
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

  if (!(FLAG_precompiled_mode && FLAG_use_bare_instructions)) {
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
      target::AbstractTypeLayout::kTypeStateFinalizedInstantiated);
  __ BranchIf(NOT_EQUAL, &is_complex_case, Assembler::kNearJump);

  // Check whether this [Type] is a function type.
  __ LoadFieldFromOffset(TypeTestABI::kScratchReg, TypeTestABI::kDstTypeReg,
                         target::Type::signature_offset());
  __ CompareObject(TypeTestABI::kScratchReg, NullObject());
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

// The UnhandledException class lives in the VM isolate, so it cannot cache
// an allocation stub for itself. Instead, we cache it in the stub code list.
void StubCodeCompiler::GenerateAllocateUnhandledExceptionStub(
    Assembler* assembler) {
  Thread* thread = Thread::Current();
  auto class_table = thread->isolate()->class_table();
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

}  // namespace compiler

}  // namespace dart
