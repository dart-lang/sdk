// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/runtime_api.h"
#include "vm/globals.h"

// For `StubCodeCompiler::GenerateAllocateUnhandledExceptionStub`
#include "vm/compiler/backend/il.h"

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/compiler/stub_code_compiler.h"

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
    if (FLAG_enable_interpreter) {
      // InterpretCall stub needs arguments descriptor for all function calls.
      __ LoadObject(ARGS_DESC_REG,
                    CastHandle<Object>(OneArgArgumentsDescriptor()));
    } else {
      // Load a GC-safe value for the arguments descriptor (unused but tagged).
      __ LoadImmediate(ARGS_DESC_REG, 0);
    }
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
    __ Bind(&throw_exception);
    __ PushObject(NullObject());  // Make room for (unused) result.
    __ PushRegister(kFieldReg);
    __ CallRuntime(kLateInitializationErrorRuntimeEntry,
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
  __ PopRegister(TypeTestABI::kResultReg);
  __ LeaveStubFrame();
  __ Ret();
}

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

}  // namespace compiler

}  // namespace dart
