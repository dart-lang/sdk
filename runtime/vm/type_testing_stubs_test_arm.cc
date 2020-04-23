// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#if defined(TARGET_ARCH_ARM)

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/runtime_api.h"
#include "vm/constants.h"
#include "vm/object.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

#define __ assembler->

namespace dart {

void GenerateInvokeTTSStub(compiler::Assembler* assembler) {
  __ EnterDartFrame(0);

  intptr_t sum = 0;
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
    if (((1 << i) & kDartAvailableCpuRegs) == 0) continue;
    if (((1 << i) & TypeTestABI::kAbiRegisters) != 0) continue;
    if (((1 << i) & TTSInternalRegs::kInternalRegisters) != 0) continue;
    __ LoadImmediate(static_cast<Register>(i), 0x10 + 2 * i);
    sum += 0x10 + 2 * i;
  }

  // Load the arguments into the right TTS calling convention registers.
  __ ldr(TypeTestABI::kInstanceReg,
         compiler::Address(
             FP, (kCallerSpSlotFromFp + 3) * compiler::target::kWordSize));
  __ ldr(TypeTestABI::kInstantiatorTypeArgumentsReg,
         compiler::Address(
             FP, (kCallerSpSlotFromFp + 2) * compiler::target::kWordSize));
  __ ldr(TypeTestABI::kFunctionTypeArgumentsReg,
         compiler::Address(
             FP, (kCallerSpSlotFromFp + 1) * compiler::target::kWordSize));
  __ ldr(TypeTestABI::kDstTypeReg,
         compiler::Address(
             FP, (kCallerSpSlotFromFp + 0) * compiler::target::kWordSize));

  const intptr_t sub_type_cache_index = __ object_pool_builder().AddObject(
      Object::null_object(), compiler::ObjectPoolBuilderEntry::kPatchable);
  const intptr_t sub_type_cache_offset =
      ObjectPool::element_offset(sub_type_cache_index) - kHeapObjectTag;
  const intptr_t dst_name_index = __ object_pool_builder().AddObject(
      Symbols::OptimizedOut(), compiler::ObjectPoolBuilderEntry::kPatchable);
  ASSERT((sub_type_cache_index + 1) == dst_name_index);
  ASSERT(__ constant_pool_allowed());

  // Call the TTS.
  __ ldr(R9, compiler::FieldAddress(
                 TypeTestABI::kDstTypeReg,
                 AbstractType::type_test_stub_entry_point_offset()));
  __ ldr(TypeTestABI::kSubtypeTestCacheReg,
         compiler::Address(PP, sub_type_cache_offset));
  __ blx(R9);

  // We have the guarantee that TTS preserve all registers except for one
  // scratch register atm (if the TTS handles the type test successfully).
  //
  // Let the test know whether TTS abi registers were preserved.
  compiler::Label abi_regs_modified, store_abi_regs_modified_bool;
  __ CompareWithMemoryValue(
      TypeTestABI::kInstanceReg,
      compiler::Address(
          FP, (kCallerSpSlotFromFp + 3) * compiler::target::kWordSize));
  __ BranchIf(NOT_EQUAL, &abi_regs_modified);
  __ CompareWithMemoryValue(
      TypeTestABI::kInstantiatorTypeArgumentsReg,
      compiler::Address(
          FP, (kCallerSpSlotFromFp + 2) * compiler::target::kWordSize));
  __ BranchIf(NOT_EQUAL, &abi_regs_modified);
  __ CompareWithMemoryValue(
      TypeTestABI::kFunctionTypeArgumentsReg,
      compiler::Address(
          FP, (kCallerSpSlotFromFp + 1) * compiler::target::kWordSize));
  __ BranchIf(NOT_EQUAL, &abi_regs_modified);
  __ CompareWithMemoryValue(
      TypeTestABI::kDstTypeReg,
      compiler::Address(
          FP, (kCallerSpSlotFromFp + 0) * compiler::target::kWordSize));
  __ BranchIf(NOT_EQUAL, &abi_regs_modified);
  __ ldr(R0, compiler::Address(THR, Thread::bool_false_offset()));
  __ b(&store_abi_regs_modified_bool);
  __ Bind(&abi_regs_modified);
  __ ldr(R0, compiler::Address(THR, Thread::bool_true_offset()));
  __ Bind(&store_abi_regs_modified_bool);
  __ ldr(TMP, compiler::Address(
                  FP, (kCallerSpSlotFromFp + 5) * compiler::target::kWordSize));
  __ str(R0, compiler::FieldAddress(TMP, Array::element_offset(0)));

  // Let the test know whether the non-TTS abi registers were preserved.
  compiler::Label rest_regs_modified, store_rest_regs_modified_bool;
  __ mov(TMP, compiler::Operand(0));
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
    if (((1 << i) & kDartAvailableCpuRegs) == 0) continue;
    if (((1 << i) & TypeTestABI::kAbiRegisters) != 0) continue;
    if (((1 << i) & TTSInternalRegs::kInternalRegisters) != 0) continue;
    __ add(TMP, TMP, compiler::Operand(static_cast<Register>(i)));
  }
  __ cmp(TMP, compiler::Operand(sum));
  __ BranchIf(NOT_EQUAL, &rest_regs_modified);
  __ ldr(R0, compiler::Address(THR, Thread::bool_false_offset()));
  __ b(&store_rest_regs_modified_bool);
  __ Bind(&rest_regs_modified);
  __ ldr(R0, compiler::Address(THR, Thread::bool_true_offset()));
  __ Bind(&store_rest_regs_modified_bool);
  __ ldr(TMP, compiler::Address(
                  FP, (kCallerSpSlotFromFp + 4) * compiler::target::kWordSize));
  __ str(R0, compiler::FieldAddress(TMP, Array::element_offset(0)));

  __ LoadObject(R0, Object::null_object());
  __ LeaveDartFrameAndReturn();
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM)
