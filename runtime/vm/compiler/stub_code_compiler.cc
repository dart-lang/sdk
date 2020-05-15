// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/runtime_api.h"
#include "vm/globals.h"

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/compiler/stub_code_compiler.h"

#include "vm/compiler/assembler/assembler.h"

#define __ assembler->

namespace dart {

namespace compiler {

void StubCodeCompiler::GenerateInitStaticFieldStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make room for (unused) result.
  __ PushRegister(InitStaticFieldABI::kFieldReg);
  __ CallRuntime(kInitStaticFieldRuntimeEntry, /*argument_count=*/1);
  __ Drop(2);
  __ LeaveStubFrame();
  __ Ret();
}

void StubCodeCompiler::GenerateInitInstanceFieldStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make room for (unused) result.
  __ PushRegister(InitInstanceFieldABI::kInstanceReg);
  __ PushRegister(InitInstanceFieldABI::kFieldReg);
  __ CallRuntime(kInitInstanceFieldRuntimeEntry, /*argument_count=*/2);
  __ Drop(3);
  __ LeaveStubFrame();
  __ Ret();
}

void StubCodeCompiler::GenerateInitLateInstanceFieldStub(Assembler* assembler,
                                                         bool is_final) {
  __ EnterStubFrame();
  // Save for later.
  __ PushRegisterPair(InitInstanceFieldABI::kInstanceReg,
                      InitInstanceFieldABI::kFieldReg);

  // Call initializer function.
  __ PushRegister(InitInstanceFieldABI::kInstanceReg);

  const Register kFunctionReg = InitLateInstanceFieldInternalRegs::kFunctionReg;
  const Register kInitializerResultReg =
      InitLateInstanceFieldInternalRegs::kInitializerResultReg;
  const Register kInstanceReg = InitLateInstanceFieldInternalRegs::kInstanceReg;
  const Register kFieldReg = InitLateInstanceFieldInternalRegs::kFieldReg;
  const Register kAddressReg = InitLateInstanceFieldInternalRegs::kAddressReg;
  const Register kScratchReg = InitLateInstanceFieldInternalRegs::kScratchReg;

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

  __ StoreIntoObject(kInstanceReg, Address(kAddressReg, 0),
                     kInitializerResultReg);

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

}  // namespace compiler

}  // namespace dart
