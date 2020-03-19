// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#if defined(TARGET_ARCH_X64)

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
    __ movq(static_cast<Register>(i), compiler::Immediate(0x10 + 2 * i));
    sum += 0x10 + 2 * i;
  }

  // Load the arguments into the right TTS calling convention registers.
  __ movq(TypeTestABI::kInstanceReg,
          compiler::Address(
              RBP, (kCallerSpSlotFromFp + 3) * compiler::target::kWordSize));
  __ movq(TypeTestABI::kInstantiatorTypeArgumentsReg,
          compiler::Address(
              RBP, (kCallerSpSlotFromFp + 2) * compiler::target::kWordSize));
  __ movq(TypeTestABI::kFunctionTypeArgumentsReg,
          compiler::Address(
              RBP, (kCallerSpSlotFromFp + 1) * compiler::target::kWordSize));
  __ movq(TypeTestABI::kDstTypeReg,
          compiler::Address(
              RBP, (kCallerSpSlotFromFp + 0) * compiler::target::kWordSize));

  const intptr_t sub_type_cache_index = __ object_pool_builder().AddObject(
      Object::null_object(), compiler::ObjectPoolBuilderEntry::kPatchable);
  const intptr_t sub_type_cache_offset =
      ObjectPool::element_offset(sub_type_cache_index) - kHeapObjectTag;
  const intptr_t dst_name_index = __ object_pool_builder().AddObject(
      Symbols::OptimizedOut(), compiler::ObjectPoolBuilderEntry::kPatchable);
  ASSERT((sub_type_cache_index + 1) == dst_name_index);
  ASSERT(__ constant_pool_allowed());

  // Call the TTS.
  __ movq(TypeTestABI::kSubtypeTestCacheReg,
          compiler::Address(PP, sub_type_cache_offset));
  __ call(compiler::FieldAddress(
      TypeTestABI::kDstTypeReg,
      AbstractType::type_test_stub_entry_point_offset()));

  // We have the guarantee that TTS preserve all registers except for one
  // scratch register atm (if the TTS handles the type test successfully).
  //
  // Let the test know whether TTS abi registers were preserved.
  compiler::Label abi_regs_modified, store_abi_regs_modified_bool;
  __ cmpq(TypeTestABI::kInstanceReg,
          compiler::Address(
              RBP, (kCallerSpSlotFromFp + 3) * compiler::target::kWordSize));
  __ BranchIf(NOT_EQUAL, &abi_regs_modified);
  __ cmpq(TypeTestABI::kInstantiatorTypeArgumentsReg,
          compiler::Address(
              RBP, (kCallerSpSlotFromFp + 2) * compiler::target::kWordSize));
  __ BranchIf(NOT_EQUAL, &abi_regs_modified);
  __ cmpq(TypeTestABI::kFunctionTypeArgumentsReg,
          compiler::Address(
              RBP, (kCallerSpSlotFromFp + 1) * compiler::target::kWordSize));
  __ BranchIf(NOT_EQUAL, &abi_regs_modified);
  __ cmpq(TypeTestABI::kDstTypeReg,
          compiler::Address(
              RBP, (kCallerSpSlotFromFp + 0) * compiler::target::kWordSize));
  __ BranchIf(NOT_EQUAL, &abi_regs_modified);
  __ movq(RAX, compiler::Address(THR, Thread::bool_false_offset()));
  __ jmp(&store_abi_regs_modified_bool);
  __ Bind(&abi_regs_modified);
  __ movq(RAX, compiler::Address(THR, Thread::bool_true_offset()));
  __ Bind(&store_abi_regs_modified_bool);
  __ movq(TMP, compiler::Address(RBP, (kCallerSpSlotFromFp + 5) *
                                          compiler::target::kWordSize));
  __ movq(compiler::FieldAddress(TMP, Array::element_offset(0)), RAX);

  // Let the test know whether the non-TTS abi registers were preserved.
  compiler::Label rest_regs_modified, store_rest_regs_modified_bool;
  __ movq(TMP, compiler::Immediate(0));
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
    if (((1 << i) & kDartAvailableCpuRegs) == 0) continue;
    if (((1 << i) & TypeTestABI::kAbiRegisters) != 0) continue;
    if (((1 << i) & TTSInternalRegs::kInternalRegisters) != 0) continue;
    __ addq(TMP, static_cast<Register>(i));
  }
  __ cmpq(TMP, compiler::Immediate(sum));
  __ BranchIf(NOT_EQUAL, &rest_regs_modified);
  __ movq(RAX, compiler::Address(THR, Thread::bool_false_offset()));
  __ jmp(&store_rest_regs_modified_bool);
  __ Bind(&rest_regs_modified);
  __ movq(RAX, compiler::Address(THR, Thread::bool_true_offset()));
  __ Bind(&store_rest_regs_modified_bool);
  __ movq(TMP, compiler::Address(RBP, (kCallerSpSlotFromFp + 4) *
                                          compiler::target::kWordSize));
  __ movq(compiler::FieldAddress(TMP, Array::element_offset(0)), RAX);

  __ LoadObject(RAX, Object::null_object());
  __ LeaveDartFrame();
  __ Ret();
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_X64)
