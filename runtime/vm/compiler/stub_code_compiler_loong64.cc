// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_LOONG64)

// For `AllocateObjectInstr::WillAllocateNewOrRemembered`
#include "vm/compiler/backend/il.h"

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/class_id.h"
#include "vm/code_entry_kind.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/stub_code_compiler.h"
#include "vm/ffi_callback_metadata.h"
#include "vm/static_type_exactness_state.h"
#include "vm/tags.h"

namespace dart {
namespace compiler {

#define __ assembler->

void StubCodeCompiler::EnsureIsNewOrRemembered() {
  Label done;
  __ AndImmediate(TMP, A0, target::Page::kPageMask);
  __ LoadFromOffset(TMP, TMP, target::Page::original_top_offset());
  __ CompareRegisters(A0, TMP);
  __ BranchIf(UNSIGNED_GREATER_EQUAL, &done);

  {
    LeafRuntimeScope rt(assembler, /*frame_size=*/0,
                        /*preserve_registers=*/false);
    __ MoveRegister(A1, THR);
    rt.Call(kEnsureRememberedAndMarkingDeferredRuntimeEntry,
            /*argument_count=*/2);
  }

  __ Bind(&done);
}

void StubCodeCompiler::GenerateAllocateArrayStub() {
  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    Label slow_case;

    __ BranchIfNotSmi(AllocateArrayABI::kLengthReg, &slow_case);

    const intptr_t max_len =
        target::ToRawSmi(target::Array::kMaxNewSpaceElements);
    __ CompareImmediate(AllocateArrayABI::kLengthReg, max_len, kObjectBytes);
    __ BranchIf(HI, &slow_case);

    NOT_IN_PRODUCT(__ MaybeTraceAllocation(kArrayCid, &slow_case, T4));

    __ Load(AllocateArrayABI::kResultReg,
            Address(THR, target::Thread::top_offset()));

    const intptr_t fixed_size_plus_alignment_padding =
        target::Array::header_size() +
        target::ObjectAlignment::kObjectAlignment - 1;
    __ slli_d(T3, AllocateArrayABI::kLengthReg,
              target::kCompressedWordSizeLog2 - kSmiTagSize);
    __ AddImmediate(T3, fixed_size_plus_alignment_padding);
    __ AndImmediate(T3, T3, ~(target::ObjectAlignment::kObjectAlignment - 1));

    __ add_d(T4, AllocateArrayABI::kResultReg, T3);
    __ bltu(T4, AllocateArrayABI::kResultReg, &slow_case);

    __ Load(TMP, Address(THR, target::Thread::end_offset()));
    __ bgeu(T4, TMP, &slow_case);
    __ CheckAllocationCanary(AllocateArrayABI::kResultReg);

    __ Store(T4, Address(THR, target::Thread::top_offset()));
    __ AddImmediate(AllocateArrayABI::kResultReg,
                    AllocateArrayABI::kResultReg, kHeapObjectTag);

    const intptr_t shift = target::UntaggedObject::kSizeTagPos -
                           target::ObjectAlignment::kObjectAlignmentLog2;
    __ LoadImmediate(T5, 0);
    __ CompareImmediate(T3, target::UntaggedObject::kSizeTagMaxSizeTag);
    Label zero_tag;
    __ BranchIf(UNSIGNED_GREATER, &zero_tag);
    __ slli_d(T5, T3, shift);
    __ Bind(&zero_tag);

    const uword tags =
        target::MakeTagWordForNewSpaceObject(kArrayCid, /*instance_size=*/0);
    __ OrImmediate(T5, T5, tags);
    __ InitializeHeader(T5, AllocateArrayABI::kResultReg);

    __ StoreCompressedIntoObjectOffsetNoBarrier(
        AllocateArrayABI::kResultReg, target::Array::type_arguments_offset(),
        AllocateArrayABI::kTypeArgumentsReg);
    __ StoreCompressedIntoObjectOffsetNoBarrier(AllocateArrayABI::kResultReg,
                                                target::Array::length_offset(),
                                                AllocateArrayABI::kLengthReg);

    __ AddImmediate(T3, AllocateArrayABI::kResultReg,
                    target::Array::data_offset() - kHeapObjectTag);

    Label loop;
    __ Bind(&loop);
    for (intptr_t offset = 0; offset < target::kObjectAlignment;
         offset += target::kCompressedWordSize) {
      __ StoreCompressedIntoObjectNoBarrier(AllocateArrayABI::kResultReg,
                                            Address(T3, offset), NULL_REG);
    }
    ASSERT(kAllocationRedZoneSize >= target::kObjectAlignment);
    __ AddImmediate(T3, target::kObjectAlignment);
    __ bltu(T3, T4, &loop);
    __ WriteAllocationCanary(T4);

    __ ret();

    __ Bind(&slow_case);
  }

  __ EnterStubFrame();
  __ AddImmediate(SP, SP, -3 * target::kWordSize);
  __ Store(ZR, Address(SP, 2 * target::kWordSize));
  __ Store(AllocateArrayABI::kLengthReg, Address(SP, 1 * target::kWordSize));
  __ Store(AllocateArrayABI::kTypeArgumentsReg,
           Address(SP, 0 * target::kWordSize));
  __ CallRuntime(kAllocateArrayRuntimeEntry, 2);

  ASSERT(AllocateArrayABI::kResultReg == A0);
  __ Load(AllocateArrayABI::kResultReg, Address(SP, 2 * target::kWordSize));
  EnsureIsNewOrRemembered();

  __ Load(AllocateArrayABI::kTypeArgumentsReg,
          Address(SP, 0 * target::kWordSize));
  __ Load(AllocateArrayABI::kLengthReg, Address(SP, 1 * target::kWordSize));
  __ Load(AllocateArrayABI::kResultReg, Address(SP, 2 * target::kWordSize));
  __ AddImmediate(SP, SP, 3 * target::kWordSize);
  __ LeaveStubFrame();
  __ ret();
}

// Input parameters:
//   S0: smi-tagged argument count, may be zero.
//   FP[target::frame_layout.param_end_from_fp + 1]: last argument.
static void PushArrayOfArguments(Assembler* assembler) {
  COMPILE_ASSERT(AllocateArrayABI::kLengthReg == S0);
  COMPILE_ASSERT(AllocateArrayABI::kTypeArgumentsReg == T1);

  __ LoadObject(T1, NullObject());
  __ JumpAndLink(StubCodeAllocateArray());
  __ PushRegister(A0);

  __ SmiUntag(S0);
  __ slli_d(T1, S0, target::kWordSizeLog2);
  __ add_d(T1, T1, FP);
  __ AddImmediate(T1,
                  target::frame_layout.param_end_from_fp * target::kWordSize);
  __ AddImmediate(T3, A0, target::Array::data_offset() - kHeapObjectTag);

  Label loop, loop_exit;
  __ Bind(&loop);
  __ beqz(S0, &loop_exit);
  __ Load(T6, Address(T1, 0));
  __ AddImmediate(T1, -target::kWordSize);
  __ StoreCompressedIntoObject(A0, Address(T3, 0), T6);
  __ AddImmediate(T3, target::kCompressedWordSize);
  __ AddImmediate(S0, -1);
  __ Jump(&loop);
  __ Bind(&loop_exit);
}

static void GenerateAllocateContextSpaceStub(Assembler* assembler,
                                             Label* slow_case) {
  intptr_t fixed_size_plus_alignment_padding =
      target::Context::header_size() +
      target::ObjectAlignment::kObjectAlignment - 1;
  __ slli_d(T4, T1, kCompressedWordSizeLog2);
  __ AddImmediate(T4, fixed_size_plus_alignment_padding);
  __ AndImmediate(T4, T4, ~(target::ObjectAlignment::kObjectAlignment - 1));

  NOT_IN_PRODUCT(__ MaybeTraceAllocation(kContextCid, slow_case, T6));

  __ Load(A0, Address(THR, target::Thread::top_offset()));
  __ add_d(T3, T4, A0);
  __ Load(TMP, Address(THR, target::Thread::end_offset()));
  __ CompareRegisters(T3, TMP);
  __ BranchIf(CS, slow_case);
  __ CheckAllocationCanary(A0);

  __ Store(T3, Address(THR, target::Thread::top_offset()));
  __ AddImmediate(A0, A0, kHeapObjectTag);

  const intptr_t shift = target::UntaggedObject::kSizeTagPos -
                         target::ObjectAlignment::kObjectAlignmentLog2;
  __ LoadImmediate(T3, 0);
  __ CompareImmediate(T4, target::UntaggedObject::kSizeTagMaxSizeTag);
  Label zero_tag;
  __ BranchIf(HI, &zero_tag);
  __ slli_d(T3, T4, shift);
  __ Bind(&zero_tag);

  const uword tags =
      target::MakeTagWordForNewSpaceObject(kContextCid, /*instance_size=*/0);
  __ OrImmediate(T3, T3, tags);
  __ InitializeHeader(T3, A0);
  __ StoreFieldToOffset(T1, A0, target::Context::num_variables_offset(),
                        kFourBytes);
}

void StubCodeCompiler::GenerateAllocateContextStub() {
  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    Label slow_case;

    GenerateAllocateContextSpaceStub(assembler, &slow_case);

    __ StoreCompressedIntoObjectOffset(A0, target::Context::parent_offset(),
                                       NULL_REG);

    __ AddImmediate(T3, A0,
                    target::Context::variable_offset(0) - kHeapObjectTag);
    Label loop, done;
    __ Bind(&loop);
    __ AddImmediate(T1, T1, -1);
    __ blt(T1, ZR, &done, Assembler::kNearJump);
    __ Store(NULL_REG, Address(T3, 0), kObjectBytes);
    __ AddImmediate(T3, T3, target::kCompressedWordSize);
    __ j(&loop, Assembler::kNearJump);
    __ Bind(&done);

    __ ret();

    __ Bind(&slow_case);
  }

  __ EnterStubFrame();
  __ SmiTag(T1);
  __ PushObject(NullObject());
  __ PushRegister(T1);
  __ CallRuntime(kAllocateContextRuntimeEntry, 1);
  __ Drop(1);
  __ PopRegister(A0);

  EnsureIsNewOrRemembered();

  __ LeaveStubFrame();
  __ ret();
}

void StubCodeCompiler::GenerateAllocateMintSharedWithFPURegsStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateAllocateMintSharedWithoutFPURegsStub() {
  assembler->Ret();
}

static void GenerateAllocateObjectHelper(Assembler* assembler,
                                         bool is_cls_parameterized) {
  const Register kTagsReg = AllocateObjectABI::kTagsReg;

  {
    Label slow_case;

#if !defined(PRODUCT)
    {
      const Register kCidRegister = T5;
      __ ExtractClassIdFromTags(kCidRegister, kTagsReg);
      __ MaybeTraceAllocation(kCidRegister, &slow_case, TMP);
    }
#endif

    const Register kNewTopReg = T3;

    {
      const Register kInstanceSizeReg = T4;
      const Register kEndReg = T5;

      __ ExtractInstanceSizeFromTags(kInstanceSizeReg, kTagsReg);
      __ Load(AllocateObjectABI::kResultReg,
              Address(THR, target::Thread::top_offset()));
      __ Load(kEndReg, Address(THR, target::Thread::end_offset()));
      __ add_d(kNewTopReg, AllocateObjectABI::kResultReg, kInstanceSizeReg);

      __ CompareRegisters(kNewTopReg, kEndReg);
      __ BranchIf(UNSIGNED_GREATER_EQUAL, &slow_case);
      __ CheckAllocationCanary(AllocateObjectABI::kResultReg);
      __ Store(kNewTopReg, Address(THR, target::Thread::top_offset()));
    }

    __ InitializeHeaderUntagged(kTagsReg, AllocateObjectABI::kResultReg);

    {
      const Register kFieldReg = T4;
      __ AddImmediate(kFieldReg, AllocateObjectABI::kResultReg,
                      target::Instance::first_field_offset());

      Label loop;
      __ Bind(&loop);
      for (intptr_t offset = 0; offset < target::kObjectAlignment;
           offset += target::kCompressedWordSize) {
        __ StoreCompressedIntoObjectNoBarrier(AllocateObjectABI::kResultReg,
                                              Address(kFieldReg, offset),
                                              NULL_REG);
      }
      ASSERT(kAllocationRedZoneSize >= target::kObjectAlignment);
      __ AddImmediate(kFieldReg, target::kObjectAlignment);
      __ bltu(kFieldReg, kNewTopReg, &loop, Assembler::kNearJump);
      __ WriteAllocationCanary(kNewTopReg);
    }

    __ AddImmediate(AllocateObjectABI::kResultReg,
                    AllocateObjectABI::kResultReg, kHeapObjectTag);

    if (is_cls_parameterized) {
      const Register kClsIdReg = T4;
      const Register kTypeOffsetReg = T5;

      __ ExtractClassIdFromTags(kClsIdReg, kTagsReg);
      __ LoadClassById(kTypeOffsetReg, kClsIdReg);
      __ Load(
          kTypeOffsetReg,
          FieldAddress(kTypeOffsetReg,
                       target::Class::
                           host_type_arguments_field_offset_in_words_offset()),
          kFourBytes);
      __ AddShifted(kTypeOffsetReg, AllocateObjectABI::kResultReg,
                    kTypeOffsetReg, target::kCompressedWordSizeLog2);
      __ StoreCompressedIntoObjectNoBarrier(
          AllocateObjectABI::kResultReg, FieldAddress(kTypeOffsetReg, 0),
          AllocateObjectABI::kTypeArgumentsReg);
    }

    __ ret();

    __ Bind(&slow_case);
  }

  if (!is_cls_parameterized) {
    __ MoveRegister(AllocateObjectABI::kTypeArgumentsReg, NULL_REG);
  }
  __ Load(TMP, Address(THR,
                       target::Thread::allocate_object_slow_entry_point_offset()));
  __ Jump(TMP);
}

void StubCodeCompiler::GenerateAllocateObjectParameterizedStub() {
  GenerateAllocateObjectHelper(assembler, /*is_cls_parameterized=*/true);
}

void StubCodeCompiler::GenerateAllocateObjectSlowStub() {
  if (!FLAG_precompiled_mode) {
    __ Load(CODE_REG, Address(THR,
                              target::Thread::call_to_runtime_stub_offset()));
  }

  __ EnterStubFrame();

  __ ExtractClassIdFromTags(AllocateObjectABI::kTagsReg,
                            AllocateObjectABI::kTagsReg);
  __ LoadClassById(A0, AllocateObjectABI::kTagsReg);

  __ AddImmediate(SP, SP, -3 * target::kWordSize);
  __ Store(ZR, Address(SP, 2 * target::kWordSize));
  __ Store(A0, Address(SP, 1 * target::kWordSize));
  __ Store(AllocateObjectABI::kTypeArgumentsReg,
           Address(SP, 0 * target::kWordSize));
  __ CallRuntime(kAllocateObjectRuntimeEntry, 2);
  __ Load(AllocateObjectABI::kResultReg, Address(SP, 2 * target::kWordSize));
  __ AddImmediate(SP, SP, 3 * target::kWordSize);

  EnsureIsNewOrRemembered();

  __ LeaveStubFrame();
  __ ret();
}

void StubCodeCompiler::GenerateAllocateObjectStub() {
  GenerateAllocateObjectHelper(assembler, /*is_cls_parameterized=*/false);
}

COMPILE_ASSERT(kWriteBarrierObjectReg == A0);
COMPILE_ASSERT(kWriteBarrierValueReg == A1);
COMPILE_ASSERT(kWriteBarrierSlotReg == A6);
static void GenerateWriteBarrierStubHelper(Assembler* assembler, bool cards) {
  constexpr Register kTopReg = T5;
  RegisterSet spill_set((1 << T3) | (1 << T4) | (1 << kTopReg), 0);

  Label skip_marking;
  __ Load(TMP, FieldAddress(A1, target::Object::tags_offset()),
          kUnsignedByte);
  __ Load(TMP2, Address(THR, target::Thread::write_barrier_mask_offset()),
          kUnsignedByte);
  __ and_(TMP, TMP, TMP2);
  __ andi(TMP, TMP, target::UntaggedObject::kIncrementalBarrierMask);
  __ beqz(TMP, &skip_marking);

  {
    Label is_new, done;
    __ PushRegisters(spill_set);
    __ AddImmediate(T3, A1, target::Object::tags_offset() - kHeapObjectTag);
    __ LoadImmediate(T4, ~(1 << target::UntaggedObject::kNotMarkedBit));
    __ amoand_db_d(TMP2, T4, Address(T3, 0));
    __ andi(TMP2, TMP2, 1 << target::UntaggedObject::kNotMarkedBit);
    __ beqz(TMP2, &done);

    __ andi(TMP2, A1, 1 << target::ObjectAlignment::kNewObjectBitPosition);
    __ bnez(TMP2, &is_new);

    auto mark_stack_push = [&](intptr_t offset, const RuntimeEntry& entry) {
      __ Load(T4, Address(THR, offset));
      __ Load(kTopReg, Address(T4, target::MarkingStackBlock::top_offset()),
              kFourBytes);
      __ slli_d(T3, kTopReg, target::kWordSizeLog2);
      __ add_d(T3, T4, T3);
      __ Store(A1, Address(T3, target::MarkingStackBlock::pointers_offset()));
      __ AddImmediate(kTopReg, kTopReg, 1);
      __ Store(kTopReg, Address(T4, target::MarkingStackBlock::top_offset()),
               kFourBytes);
      __ CompareImmediate(kTopReg, target::MarkingStackBlock::kSize);
      __ BranchIf(NE, &done);

      {
        LeafRuntimeScope rt(assembler, /*frame_size=*/0,
                            /*preserve_registers=*/true);
        __ MoveRegister(A0, THR);
        rt.Call(entry, /*argument_count=*/1);
      }
    };

    mark_stack_push(target::Thread::old_marking_stack_block_offset(),
                    kOldMarkingStackBlockProcessRuntimeEntry);
    __ j(&done);

    __ Bind(&is_new);
    mark_stack_push(target::Thread::new_marking_stack_block_offset(),
                    kNewMarkingStackBlockProcessRuntimeEntry);

    __ Bind(&done);
    __ PopRegisters(spill_set);
  }

  Label add_to_remembered_set, remember_card;
  __ Bind(&skip_marking);
  __ Load(TMP, FieldAddress(A0, target::Object::tags_offset()),
          kUnsignedByte);
  __ Load(TMP2, FieldAddress(A1, target::Object::tags_offset()),
          kUnsignedByte);
  __ srli_d(TMP, TMP, target::UntaggedObject::kBarrierOverlapShift);
  __ and_(TMP, TMP2, TMP);
  __ andi(TMP, TMP, target::UntaggedObject::kGenerationalBarrierMask);
  __ bnez(TMP, &add_to_remembered_set);
  __ ret();

  __ Bind(&add_to_remembered_set);
  if (cards) {
    __ Load(TMP2, FieldAddress(A0, target::Object::tags_offset()),
            kUnsignedByte);
    __ andi(TMP2, TMP2, 1 << target::UntaggedObject::kCardRememberedBit);
    __ bnez(TMP2, &remember_card);
  } else {
#if defined(DEBUG)
    Label ok;
    __ Load(TMP2, FieldAddress(A0, target::Object::tags_offset()),
            kUnsignedByte);
    __ andi(TMP2, TMP2, 1 << target::UntaggedObject::kCardRememberedBit);
    __ beqz(TMP2, &ok, Assembler::kNearJump);
    __ Stop("Wrong barrier!");
    __ Bind(&ok);
#endif
  }
  {
    Label done;
    __ PushRegisters(spill_set);
    __ AddImmediate(T3, A0, target::Object::tags_offset() - kHeapObjectTag);
    __ LoadImmediate(T4, ~(1 << target::UntaggedObject::kOldAndNotRememberedBit));
    __ amoand_db_d(TMP2, T4, Address(T3, 0));
    __ andi(TMP2, TMP2, 1 << target::UntaggedObject::kOldAndNotRememberedBit);
    __ beqz(TMP2, &done);

    __ Load(T4, Address(THR, target::Thread::store_buffer_block_offset()));
    __ Load(kTopReg, Address(T4, target::StoreBufferBlock::top_offset()),
            kFourBytes);
    __ slli_d(T3, kTopReg, target::kWordSizeLog2);
    __ add_d(T3, T4, T3);
    __ Store(A0, Address(T3, target::StoreBufferBlock::pointers_offset()));
    __ AddImmediate(kTopReg, kTopReg, 1);
    __ Store(kTopReg, Address(T4, target::StoreBufferBlock::top_offset()),
             kFourBytes);
    __ CompareImmediate(kTopReg, target::StoreBufferBlock::kSize);
    __ BranchIf(NE, &done);

    {
      LeafRuntimeScope rt(assembler, /*frame_size=*/0,
                          /*preserve_registers=*/true);
      __ MoveRegister(A0, THR);
      rt.Call(kStoreBufferBlockProcessRuntimeEntry, /*argument_count=*/1);
    }

    __ Bind(&done);
    __ PopRegisters(spill_set);
    __ ret();
  }

  if (cards) {
    __ Bind(&remember_card);
    __ AndImmediate(TMP, A0, target::Page::kPageMask);
    __ Load(TMP2, Address(TMP, target::Page::card_table_offset()));

    __ sub_d(A6, A6, TMP);
    __ srli_d(A6, A6, target::Page::kBytesPerCardLog2);
    __ LoadImmediate(TMP, 1);
    __ sll_d(TMP, TMP, A6);
    __ srli_d(A6, A6, target::kBitsPerWordLog2);
    __ slli_d(A6, A6, target::kWordSizeLog2);
    __ add_d(TMP2, TMP2, A6);
    __ amoor_db_d(ZR, TMP, Address(TMP2, 0));
    __ ret();
  }
}

void StubCodeCompiler::GenerateArrayWriteBarrierStub() {
  GenerateWriteBarrierStubHelper(assembler, true);
}

// Input parameters:
//   RA : return address.
//   SP : address of return value.
//   T5 : address of the native function to call.
//   T6 : address of first argument in argument array.
//   T1 : argc_tag including number of arguments and function kind.
static void GenerateCallNativeWithWrapperStub(Assembler* assembler,
                                              Address wrapper) {
  const intptr_t thread_offset = target::NativeArguments::thread_offset();
  const intptr_t argc_tag_offset = target::NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = target::NativeArguments::argv_offset();
  const intptr_t retval_offset = target::NativeArguments::retval_offset();

  __ EnterStubFrame();

  __ StoreToOffset(FP, THR, target::Thread::top_exit_frame_info_offset());

  __ LoadImmediate(TMP, target::Thread::exit_through_runtime_call());
  __ StoreToOffset(TMP, THR, target::Thread::exit_through_ffi_offset());

#if defined(DEBUG)
  {
    Label ok;
    __ LoadFromOffset(TMP, THR, target::Thread::vm_tag_offset());
    __ CompareImmediate(TMP, VMTag::kDartTagId);
    __ BranchIf(EQ, &ok);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  __ StoreToOffset(T5, THR, target::Thread::vm_tag_offset());

  ASSERT(target::NativeArguments::StructSize() == 4 * target::kWordSize);
  __ ReserveAlignedFrameSpace(target::NativeArguments::StructSize());

  ASSERT(thread_offset == 0 * target::kWordSize);
  ASSERT(argc_tag_offset == 1 * target::kWordSize);
  ASSERT(argv_offset == 2 * target::kWordSize);
  ASSERT(retval_offset == 3 * target::kWordSize);
  __ AddImmediate(T3, FP,
                  (target::frame_layout.param_end_from_fp + 1) *
                      target::kWordSize);

  __ StoreToOffset(THR, SP, thread_offset);
  __ StoreToOffset(T1, SP, argc_tag_offset);
  __ StoreToOffset(T6, SP, argv_offset);
  __ StoreToOffset(T3, SP, retval_offset);
  __ MoveRegister(A0, SP);
  __ MoveRegister(A1, T5);

  ASSERT(IsAbiPreservedRegister(THR));
  __ Call(wrapper);

  __ RestorePinnedRegisters();

  __ LoadImmediate(TMP, VMTag::kDartTagId);
  __ StoreToOffset(TMP, THR, target::Thread::vm_tag_offset());
  __ StoreToOffset(ZR, THR, target::Thread::exit_through_ffi_offset());
  __ StoreToOffset(ZR, THR, target::Thread::top_exit_frame_info_offset());

  if (FLAG_precompiled_mode) {
    __ SetupGlobalPoolAndDispatchTable();
  }

  __ LeaveStubFrame();
  __ ret();
}

void StubCodeCompiler::GenerateCallAutoScopeNativeStub() {
  GenerateCallNativeWithWrapperStub(
      assembler,
      Address(THR,
              target::Thread::auto_scope_native_wrapper_entry_point_offset()));
}

void StubCodeCompiler::GenerateCallBootstrapNativeStub() {
  GenerateCallNativeWithWrapperStub(
      assembler,
      Address(THR,
              target::Thread::bootstrap_native_wrapper_entry_point_offset()));
}

void StubCodeCompiler::GenerateCallClosureNoSuchMethodStub() {
  __ EnterStubFrame();

  __ LoadCompressedSmiFieldFromOffset(
      S0, S4, target::ArgumentsDescriptor::size_offset());
  __ AddShifted(TMP, FP, S0, target::kWordSizeLog2 - kSmiTagSize);
  __ LoadFromOffset(A0, TMP,
                    target::frame_layout.param_end_from_fp * target::kWordSize);

  __ LoadCompressedFieldFromOffset(TMP, A0, target::Closure::function_offset());

  __ PushRegistersInOrder({ZR, A0, TMP, S4});

  __ LoadCompressedSmiFieldFromOffset(
      T3, S4, target::ArgumentsDescriptor::type_args_len_offset());
  Label args_count_ok;
  __ beqz(T3, &args_count_ok, Assembler::kNearJump);
  __ AddImmediate(S0, target::ToRawSmi(1));
  __ Bind(&args_count_ok);

  PushArrayOfArguments(assembler);

  const intptr_t kNumArgs = 4;
  __ CallRuntime(kNoSuchMethodFromPrologueRuntimeEntry, kNumArgs);
  __ Breakpoint();
}

void StubCodeCompiler::GenerateCallNativeThroughSafepointStub() {
  COMPILE_ASSERT(IsAbiPreservedRegister(CALLEE_SAVED_TEMP));
  __ MoveRegister(CALLEE_SAVED_TEMP, RA);
  __ LoadImmediate(T1, target::Thread::exit_through_ffi());
  __ TransitionGeneratedToNative(T0, FPREG, T1,
                                 /*enter_safepoint=*/true);

#if defined(DEBUG)
  __ AndImmediate(TMP, SP, OS::ActivationFrameAlignment() - 1);
  Label aligned;
  __ beq(TMP, ZR, &aligned, Assembler::kNearJump);
  __ Breakpoint();
  __ Bind(&aligned);
#endif

  __ MoveRegister(A3, T3);
  __ MoveRegister(A4, T4);
  __ MoveRegister(A5, T5);
  __ Call(T0);

  __ TransitionNativeToGenerated(T1, /*exit_safepoint=*/true);
  __ jr(CALLEE_SAVED_TEMP);
}

void StubCodeCompiler::GenerateCallNoScopeNativeStub() {
  GenerateCallNativeWithWrapperStub(
      assembler,
      Address(THR,
              target::Thread::no_scope_native_wrapper_entry_point_offset()));
}

void StubCodeCompiler::GenerateCallStaticFunctionStub() {
  __ EnterStubFrame();
  __ PushRegistersInOrder({ARGS_DESC_REG, ZR});
  __ CallRuntime(kPatchStaticCallRuntimeEntry, 0);
  __ PopRegister(CODE_REG);
  __ PopRegister(ARGS_DESC_REG);
  __ LeaveStubFrame();

  __ LoadFieldFromOffset(TMP, CODE_REG, target::Code::entry_point_offset());
  __ Jump(TMP);
}

void StubCodeCompiler::GenerateCallToRuntimeStub() {
  const intptr_t thread_offset = target::NativeArguments::thread_offset();
  const intptr_t argc_tag_offset = target::NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = target::NativeArguments::argv_offset();
  const intptr_t retval_offset = target::NativeArguments::retval_offset();

  __ Load(CODE_REG, Address(THR, target::Thread::call_to_runtime_stub_offset()));
  __ SetPrologueOffset();
  __ EnterStubFrame();

  __ StoreToOffset(FP, THR, target::Thread::top_exit_frame_info_offset());

  __ LoadImmediate(TMP, target::Thread::exit_through_runtime_call());
  __ StoreToOffset(TMP, THR, target::Thread::exit_through_ffi_offset());

#if defined(DEBUG)
  {
    Label ok;
    __ LoadFromOffset(TMP, THR, target::Thread::vm_tag_offset());
    __ CompareImmediate(TMP, VMTag::kDartTagId);
    __ BranchIf(EQ, &ok);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  __ StoreToOffset(T5, THR, target::Thread::vm_tag_offset());

  ASSERT(target::NativeArguments::StructSize() == 4 * target::kWordSize);
  __ ReserveAlignedFrameSpace(target::NativeArguments::StructSize());

  ASSERT(thread_offset == 0 * target::kWordSize);
  ASSERT(argc_tag_offset == 1 * target::kWordSize);
  ASSERT(argv_offset == 2 * target::kWordSize);
  ASSERT(retval_offset == 3 * target::kWordSize);

  __ slli_d(T6, T4, target::kWordSizeLog2);
  __ add_d(T6, FP, T6);
  __ AddImmediate(T6,
                  target::frame_layout.param_end_from_fp * target::kWordSize);
  __ AddImmediate(T3, T6, target::kWordSize);

  __ StoreToOffset(THR, SP, thread_offset);
  __ StoreToOffset(T4, SP, argc_tag_offset);
  __ StoreToOffset(T6, SP, argv_offset);
  __ StoreToOffset(T3, SP, retval_offset);
  __ MoveRegister(A0, SP);

  ASSERT(IsAbiPreservedRegister(THR));
  __ Call(T5);

  __ RestorePinnedRegisters();

  __ LoadImmediate(TMP, VMTag::kDartTagId);
  __ StoreToOffset(TMP, THR, target::Thread::vm_tag_offset());
  __ StoreToOffset(ZR, THR, target::Thread::exit_through_ffi_offset());
  __ StoreToOffset(ZR, THR, target::Thread::top_exit_frame_info_offset());

  if (FLAG_precompiled_mode) {
    __ SetupGlobalPoolAndDispatchTable();
  }

  __ LeaveStubFrame();

  __ LoadImmediate(A0, 0);
  __ ret();
}

void StubCodeCompiler::GenerateCloneContextStub() {
  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    Label slow_case;

    __ Load(T1, FieldAddress(T5, target::Context::num_variables_offset()),
            kFourBytes);

    GenerateAllocateContextSpaceStub(assembler, &slow_case);

    __ LoadCompressed(T3, FieldAddress(T5, target::Context::parent_offset()));
    __ StoreCompressedIntoObjectNoBarrier(
        A0, FieldAddress(A0, target::Context::parent_offset()), T3);

    Label loop, done;
    __ AddImmediate(T3, A0,
                    target::Context::variable_offset(0) - kHeapObjectTag);
    __ AddImmediate(T4, T5,
                    target::Context::variable_offset(0) - kHeapObjectTag);
    __ Bind(&loop);
    __ AddImmediate(T1, -1);
    __ blt(T1, ZR, &done, Assembler::kNearJump);
    __ LoadCompressed(T5, Address(T4, 0));
    __ AddImmediate(T4, target::kCompressedWordSize);
    __ StoreCompressedIntoObjectNoBarrier(A0, Address(T3, 0), T5);
    __ AddImmediate(T3, target::kCompressedWordSize);
    __ j(&loop, Assembler::kNearJump);
    __ Bind(&done);

    __ ret();

    __ Bind(&slow_case);
  }

  __ EnterStubFrame();
  __ PushObject(NullObject());
  __ PushRegister(T5);
  __ CallRuntime(kCloneContextRuntimeEntry, 1);
  __ Drop(1);
  __ PopRegister(A0);

  EnsureIsNewOrRemembered();

  __ LeaveStubFrame();
  __ ret();
}

void StubCodeCompiler::GenerateDebugStepCheckStub() {
  assembler->Ret();
}

// On entry to the deoptimization sequence:
//   RA points to the deoptimization point.
//   CODE_REG has the deoptimize stub Code object.
//   The original optimized CODE_REG value is stored on top of the optimized
//   frame by the caller of this helper.
static void GenerateDeoptimizationSequence(Assembler* assembler,
                                           DeoptStubKind kind) {
  // DeoptimizeCopyFrame expects a Dart frame. The PC marker and PP do not need
  // to be correct here because the runtime patches them while rewriting frames.
  __ EnterStubFrame();

  const intptr_t saved_result_slot_from_fp =
      target::frame_layout.first_local_from_fp + 1 -
      (kNumberOfCpuRegisters - A0);
  const intptr_t saved_exception_slot_from_fp =
      target::frame_layout.first_local_from_fp + 1 -
      (kNumberOfCpuRegisters - A0);
  const intptr_t saved_stacktrace_slot_from_fp =
      target::frame_layout.first_local_from_fp + 1 -
      (kNumberOfCpuRegisters - A1);

  __ AddImmediate(SP, SP, -kNumberOfCpuRegisters * target::kWordSize);
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; i--) {
    const Register reg = static_cast<Register>(i);
    if (reg == CODE_REG) {
      COMPILE_ASSERT(TMP > CODE_REG);
      __ Load(TMP, Address(FP, 0 * target::kWordSize));
      __ Store(TMP, Address(SP, i * target::kWordSize));
    } else {
      __ Store(reg, Address(SP, i * target::kWordSize));
    }
  }

  __ AddImmediate(SP, SP, -kNumberOfFpuRegisters * kFpuRegisterSize);
  for (intptr_t i = kNumberOfFpuRegisters - 1; i >= 0; i--) {
    const FRegister reg = static_cast<FRegister>(i);
    __ StoreD(reg, Address(SP, i * kFpuRegisterSize));
  }

  {
    __ MoveRegister(A0, SP);
    LeafRuntimeScope rt(assembler, /*frame_size=*/0,
                        /*preserve_registers=*/false);
    const bool is_lazy =
        (kind == kLazyDeoptFromReturn) || (kind == kLazyDeoptFromThrow);
    __ LoadImmediate(A1, is_lazy ? 1 : 0);
    rt.Call(kDeoptimizeCopyFrameRuntimeEntry, 2);
  }

  if (kind == kLazyDeoptFromReturn) {
    __ LoadFromOffset(T1, FP, saved_result_slot_from_fp * target::kWordSize);
  } else if (kind == kLazyDeoptFromThrow) {
    __ LoadFromOffset(T1, FP, saved_exception_slot_from_fp * target::kWordSize);
    __ LoadFromOffset(T3, FP,
                      saved_stacktrace_slot_from_fp * target::kWordSize);
  }

  __ RestoreCodePointer();
  __ LeaveStubFrame();
  __ sub_d(SP, FP, A0);

  __ EnterStubFrame();

  if (kind == kLazyDeoptFromReturn) {
    __ PushRegister(T1);
  } else if (kind == kLazyDeoptFromThrow) {
    __ PushRegistersInOrder({T1, T3});
  }

  {
    __ MoveRegister(A0, FP);
    LeafRuntimeScope rt(assembler, /*frame_size=*/0,
                        /*preserve_registers=*/false);
    rt.Call(kDeoptimizeFillFrameRuntimeEntry, 1);
  }

  if (FLAG_target_thread_sanitizer) {
    __ MoveRegister(CALLEE_SAVED_TEMP, A0);
    __ TsanFuncExit(/*preserve_registers=*/false);
    Label loop;
    __ Bind(&loop);
    __ LoadImmediate(A0, 42);
    __ TsanFuncEntry(/*preserve_registers=*/false);
    __ AddImmediate(CALLEE_SAVED_TEMP, CALLEE_SAVED_TEMP, -1);
    __ bnez(CALLEE_SAVED_TEMP, &loop, Assembler::kNearJump);
  }

  if (kind == kLazyDeoptFromReturn) {
    __ LoadFromOffset(
        T1, FP, target::frame_layout.first_local_from_fp * target::kWordSize);
  } else if (kind == kLazyDeoptFromThrow) {
    __ LoadFromOffset(
        T1, FP, target::frame_layout.first_local_from_fp * target::kWordSize);
    __ LoadFromOffset(
        T3, FP,
        (target::frame_layout.first_local_from_fp - 1) * target::kWordSize);
  }

  __ RestoreCodePointer();
  __ LeaveStubFrame();

  // Frame rewriting is complete; materialize deferred objects in a GC-safe
  // stub frame. T4 holds the byte count to remove afterwards.
  __ EnterStubFrame();
  if (kind == kLazyDeoptFromReturn) {
    __ PushRegister(T1);
  } else if (kind == kLazyDeoptFromThrow) {
    __ PushRegister(CODE_REG);
    __ PushRegistersInOrder({T1, T3});
  }

  __ PushRegister(ZR);
  __ CallRuntime(kDeoptimizeMaterializeRuntimeEntry, 0);
  __ PopRegister(T4);
  __ SmiUntag(T4);

  if (kind == kLazyDeoptFromReturn) {
    __ PopRegister(A0);
  } else if (kind == kLazyDeoptFromThrow) {
    __ PopRegister(A1);
    __ PopRegister(A0);
    __ PopRegister(CODE_REG);
  }
  __ LeaveStubFrame();
  __ add_d(SP, SP, T4);

  if (kind == kLazyDeoptFromThrow) {
    __ EnterStubFrame();
    __ PushRegister(ZR);
    __ PushRegister(A0);
    __ PushRegister(A1);
    __ PushImmediate(target::ToRawSmi(1));
    __ CallRuntime(kReThrowRuntimeEntry, 3);
    __ LeaveStubFrame();
  }
}

void StubCodeCompiler::GenerateDeoptForRewindStub() {
  // Push zap value instead of CODE_REG.
  __ LoadImmediate(TMP, kZapCodeReg);
  __ PushRegister(TMP);

  // Load the deopt pc into RA.
  __ LoadFromOffset(RA, THR, target::Thread::resume_pc_offset());
  GenerateDeoptimizationSequence(assembler, kEagerDeopt);

  // After we have deoptimized, jump to the correct frame.
  __ EnterStubFrame();
  __ CallRuntime(kRewindPostDeoptRuntimeEntry, 0);
  __ LeaveStubFrame();
  __ Breakpoint();
}

void StubCodeCompiler::GenerateDeoptimizeLazyFromReturnStub() {
  // Push zap value instead of CODE_REG for lazy deopt.
  __ LoadImmediate(TMP, kZapCodeReg);
  __ PushRegister(TMP);
  // Return address for "call" to deopt stub.
  __ LoadImmediate(RA, kZapReturnAddress);
  __ Load(CODE_REG,
          Address(THR, target::Thread::lazy_deopt_from_return_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kLazyDeoptFromReturn);
  __ ret();
}

void StubCodeCompiler::GenerateDeoptimizeLazyFromThrowStub() {
  // Push zap value instead of CODE_REG for lazy deopt.
  __ LoadImmediate(TMP, kZapCodeReg);
  __ PushRegister(TMP);
  // Return address for "call" to deopt stub.
  __ LoadImmediate(RA, kZapReturnAddress);
  __ Load(CODE_REG,
          Address(THR, target::Thread::lazy_deopt_from_throw_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kLazyDeoptFromThrow);
  __ ret();
}

void StubCodeCompiler::GenerateDeoptimizeStub() {
  __ PushRegister(CODE_REG);
  __ Load(CODE_REG, Address(THR, target::Thread::deoptimize_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kEagerDeopt);
  __ ret();
}

void StubCodeCompiler::GenerateDispatchTableNullErrorStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateEnterSafepointStub() {
  RegisterSet all_registers;
  all_registers.AddAllGeneralRegisters();

  __ PushRegisters(all_registers);
  __ EnterFrame(0);
  __ ReserveAlignedFrameSpace(0);

  __ Load(TMP, Address(THR, kEnterSafepointRuntimeEntry.OffsetFromThread()));
  __ Call(TMP);

  __ LeaveFrame();
  __ PopRegisters(all_registers);
  __ ret();
}

void StubCodeCompiler::GenerateExitSafepointStub() {
  RegisterSet all_registers;
  all_registers.AddAllGeneralRegisters();

  __ PushRegisters(all_registers);
  __ EnterFrame(0);
  __ ReserveAlignedFrameSpace(0);

  __ VerifyNotInGenerated(TMP);
  __ Load(TMP, Address(THR, kExitSafepointRuntimeEntry.OffsetFromThread()));
  __ Call(TMP);

  __ LeaveFrame();
  __ PopRegisters(all_registers);
  __ ret();
}

void StubCodeCompiler::GenerateLoadFfiCallbackMetadataRuntimeFunction(
    uword function_index,
    Register dst) {
  const intptr_t code_size = __ CodeSize();
  __ pcaddu12i(dst, 0);
  __ AddImmediate(dst, -code_size);
  __ AndImmediate(dst, FfiCallbackMetadata::kPageMask);
  __ LoadFromOffset(dst, dst,
                    FfiCallbackMetadata::RuntimeFunctionOffset(function_index));
}

static const RegisterSet kArgumentRegisterSet(
    CallingConventions::kArgumentRegisters,
    CallingConventions::kFpuArgumentRegisters);
static const RegisterSet kReturnRegisterSet(
    (1 << CallingConventions::kReturnReg) |
        (1 << CallingConventions::kSecondReturnReg),
    (1 << CallingConventions::kReturnFpuReg) |
        (1 << CallingConventions::kSecondReturnFpuReg));

void StubCodeCompiler::GenerateFfiCallbackTrampolineStub() {
  Label body;

  COMPILE_ASSERT(!IsCalleeSavedRegister(T1) && !IsArgumentRegister(T1));
  for (intptr_t i = 0; i < FfiCallbackMetadata::NumCallbackTrampolinesPerPage();
       ++i) {
    __ pcaddu12i(T1, 0);
    __ j(&body);
  }

  ASSERT_EQUAL(__ CodeSize(),
               FfiCallbackMetadata::kNativeCallbackTrampolineSize *
                   FfiCallbackMetadata::NumCallbackTrampolinesPerPage());

  const intptr_t shared_stub_start = __ CodeSize();

  __ Bind(&body);

  COMPILE_ASSERT(FfiCallbackMetadata::kNativeCallbackTrampolineStackDelta == 4);
  __ AddImmediate(SP, SP, -4 * target::kWordSize);
  __ Store(RA, Address(SP, 3 * target::kWordSize));
  __ Store(FP, Address(SP, 2 * target::kWordSize));
  __ Store(THR, Address(SP, 1 * target::kWordSize));
  __ Store(S2, Address(SP, 0 * target::kWordSize));
  __ AddImmediate(FP, SP, 4 * target::kWordSize);
  COMPILE_ASSERT(!IsArgumentRegister(THR));

  {
    __ PushRegistersAligned(kArgumentRegisterSet, 3 * target::kWordSize);
    __ MoveRegister(A0, T1);
    __ MoveRegister(A1, SP);

    GenerateLoadFfiCallbackMetadataRuntimeFunction(
        FfiCallbackMetadata::kGetFfiCallbackMetadata, T1);
    __ Call(T1);

    __ MoveRegister(THR, A0);
    __ Load(T4, Address(SP, 0 * target::kWordSize));  // entry_point
    __ Load(T3, Address(SP, 1 * target::kWordSize));  // is_tail
    __ Load(S2, Address(SP, 2 * target::kWordSize));  // epilogue

    __ PopRegistersAligned(kArgumentRegisterSet, 3 * target::kWordSize);
  }

  Label tail;
  __ bne(T3, ZR, &tail, Assembler::kNearJump);

  {
    __ Call(T4);
    __ PushRegistersAligned(kReturnRegisterSet, 0);
    __ MoveRegister(A0, THR);
    __ Call(S2);
    if (FLAG_target_memory_sanitizer) {
      __ Call(A0);
    }
    __ PopRegistersAligned(kReturnRegisterSet, 0);
    __ Load(S2, Address(SP, 0 * target::kWordSize));
    __ Load(THR, Address(SP, 1 * target::kWordSize));
    __ Load(FP, Address(SP, 2 * target::kWordSize));
    __ Load(RA, Address(SP, 3 * target::kWordSize));
    __ AddImmediate(SP, SP, 4 * target::kWordSize);
    __ ret();
  }

  {
    __ Bind(&tail);
    __ Call(T4);
    __ MoveRegister(A0, THR);
    __ MoveRegister(A1, S2);
    __ Load(S2, Address(SP, 0 * target::kWordSize));
    __ Load(THR, Address(SP, 1 * target::kWordSize));
    __ Load(FP, Address(SP, 2 * target::kWordSize));
    __ Load(RA, Address(SP, 3 * target::kWordSize));
    __ AddImmediate(SP, SP, 4 * target::kWordSize);
    __ jr(A1);
    __ Breakpoint();
  }

  ASSERT_LESS_OR_EQUAL(__ CodeSize() - shared_stub_start,
                       FfiCallbackMetadata::kNativeCallbackSharedStubSize);
  ASSERT_LESS_OR_EQUAL(__ CodeSize(), FfiCallbackMetadata::kPageSize);

#if defined(DEBUG)
  while (__ CodeSize() < FfiCallbackMetadata::kPageSize) {
    __ Breakpoint();
  }
#endif
}

void StubCodeCompiler::GenerateFfiCallTrampolineStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateFixAllocationStubTargetStub() {
  __ Load(CODE_REG,
          Address(THR, target::Thread::fix_allocation_stub_code_offset()));
  __ EnterStubFrame();
  __ PushRegister(ZR);
  __ CallRuntime(kFixAllocationStubTargetRuntimeEntry, 0);
  __ PopRegister(CODE_REG);
  __ LeaveStubFrame();
  __ LoadFieldFromOffset(TMP, CODE_REG, target::Code::entry_point_offset());
  __ jr(TMP);
}

void StubCodeCompiler::GenerateFixCallersTargetStub() {
  Label monomorphic;
  __ BranchOnMonomorphicCheckedEntryJIT(&monomorphic);

  __ Load(CODE_REG,
          Address(THR, target::Thread::fix_callers_target_code_offset()));
  __ EnterStubFrame();
  __ PushRegistersInOrder({ARGS_DESC_REG, ZR});
  __ CallRuntime(kFixCallersTargetRuntimeEntry, 0);
  __ PopRegister(CODE_REG);
  __ PopRegister(ARGS_DESC_REG);
  __ LeaveStubFrame();
  __ LoadFieldFromOffset(TMP, CODE_REG, target::Code::entry_point_offset());
  __ jr(TMP);

  __ Bind(&monomorphic);
  __ Load(CODE_REG,
          Address(THR, target::Thread::fix_callers_target_code_offset()));
  __ EnterStubFrame();
  __ PushRegistersInOrder({ZR, A0, IC_DATA_REG});
  __ CallRuntime(kFixCallersTargetMonomorphicRuntimeEntry, 2);
  __ PopRegister(IC_DATA_REG);
  __ PopRegister(A0);
  __ PopRegister(CODE_REG);
  __ LeaveStubFrame();
  __ LoadFieldFromOffset(
      TMP, CODE_REG,
      target::Code::entry_point_offset(CodeEntryKind::kMonomorphic));
  __ jr(TMP);
}

void StubCodeCompiler::GenerateFixParameterizedAllocationStubTargetStub() {
  __ Load(CODE_REG,
          Address(THR, target::Thread::fix_allocation_stub_code_offset()));
  __ EnterStubFrame();
  __ PushRegister(AllocateObjectABI::kTypeArgumentsReg);
  __ PushRegister(ZR);
  __ CallRuntime(kFixAllocationStubTargetRuntimeEntry, 0);
  __ PopRegister(CODE_REG);
  __ PopRegister(AllocateObjectABI::kTypeArgumentsReg);
  __ LeaveStubFrame();
  __ LoadFieldFromOffset(TMP, CODE_REG, target::Code::entry_point_offset());
  __ jr(TMP);
}

void StubCodeCompiler::GenerateICCallBreakpointStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateICCallThroughCodeStub() {
  Label loop, found, miss;
  __ Load(T1, FieldAddress(IC_DATA_REG, target::ICData::entries_offset()));
  __ Load(ARGS_DESC_REG,
          FieldAddress(IC_DATA_REG,
                       target::CallSiteData::arguments_descriptor_offset()));
  __ AddImmediate(T1, T1, target::Array::data_offset() - kHeapObjectTag);
  __ LoadTaggedClassIdMayBeSmi(A1, A0);

  __ Bind(&loop);
  __ LoadCompressedSmi(T8, Address(T1, 0));
  __ beq(A1, T8, &found, Assembler::kNearJump);
  __ CompareImmediate(T8, target::ToRawSmi(kIllegalCid));
  __ BranchIf(EQ, &miss, Assembler::kNearJump);

  const intptr_t entry_length =
      target::ICData::TestEntryLengthFor(1, /*exactness_check=*/false) *
      target::kCompressedWordSize;
  __ AddImmediate(T1, T1, entry_length);
  __ j(&loop, Assembler::kNearJump);

  __ Bind(&found);
  if (FLAG_precompiled_mode) {
    const intptr_t entry_offset =
        target::ICData::EntryPointIndexFor(1) * target::kCompressedWordSize;
    __ LoadCompressed(FUNCTION_REG, Address(T1, entry_offset));
    __ Load(A1, FieldAddress(FUNCTION_REG,
                             target::Function::entry_point_offset()));
  } else {
    const intptr_t code_offset =
        target::ICData::CodeIndexFor(1) * target::kCompressedWordSize;
    __ LoadCompressed(CODE_REG, Address(T1, code_offset));
    __ Load(A1, FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  }
  __ jr(A1);

  __ Bind(&miss);
  __ Load(A1, Address(THR, target::Thread::switchable_call_miss_entry_offset()));
  __ jr(A1);
}

void StubCodeCompiler::GenerateInterpretCallStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateInvokeDartCodeFromBytecodeStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateInvokeDartCodeStub() {
  __ EnterFrame(1 * target::kWordSize);

  __ Load(TMP2, Address(A3, target::Thread::invoke_dart_code_stub_offset()));
  __ Store(TMP2, Address(SP, 0 * target::kWordSize));

  __ PushNativeCalleeSavedRegisters();

  if (THR != A3) {
    __ MoveRegister(THR, A3);
  }
  __ RestorePinnedRegisters();

  __ AddImmediate(SP, SP, -4 * target::kWordSize);
  __ Load(TMP, Address(THR, target::Thread::vm_tag_offset()));
  __ Store(TMP, Address(SP, 3 * target::kWordSize));
  __ Load(TMP, Address(THR, target::Thread::top_resource_offset()));
  __ Store(ZR, Address(THR, target::Thread::top_resource_offset()));
  __ Store(TMP, Address(SP, 2 * target::kWordSize));
  __ Load(TMP, Address(THR, target::Thread::exit_through_ffi_offset()));
  __ Store(ZR, Address(THR, target::Thread::exit_through_ffi_offset()));
  __ Store(TMP, Address(SP, 1 * target::kWordSize));
  __ Load(TMP, Address(THR, target::Thread::top_exit_frame_info_offset()));
  __ Store(ZR, Address(THR, target::Thread::top_exit_frame_info_offset()));
  __ Store(TMP, Address(SP, 0 * target::kWordSize));
  ASSERT_EQUAL(target::frame_layout.exit_link_slot_from_entry_fp, -25);
  __ EmitEntryFrameVerification();

  __ LoadImmediate(TMP, VMTag::kDartTagId);
  __ StoreToOffset(TMP, THR, target::Thread::vm_tag_offset());

  __ MoveRegister(ARGS_DESC_REG, A1);

  __ LoadFieldFromOffset(T5, ARGS_DESC_REG,
                         target::ArgumentsDescriptor::count_offset());
  __ LoadFieldFromOffset(T3, ARGS_DESC_REG,
                         target::ArgumentsDescriptor::type_args_len_offset());
  __ SmiUntag(T5);
  Label no_type_args, type_args_done;
  __ BranchIfZero(T3, &no_type_args, Assembler::kNearJump);
  __ LoadImmediate(T3, 1);
  __ j(&type_args_done, Assembler::kNearJump);
  __ Bind(&no_type_args);
  __ LoadImmediate(T3, 0);
  __ Bind(&type_args_done);
  __ add_d(T5, T5, T3);

  // The third C ABI argument arrives in A2, which is also CODE_REG on Loong64.
  // Keep the arguments array in an ordinary temporary before CODE_REG is filled
  // with the target Code object below.
  __ MoveRegister(T1, A2);
  __ AddImmediate(T1, T1, target::Array::data_offset() - kHeapObjectTag);

  Label push_arguments;
  Label done_push_arguments;
  __ BranchIfZero(T5, &done_push_arguments, Assembler::kNearJump);
  __ LoadImmediate(T4, 0);
  __ Bind(&push_arguments);
  __ Load(T3, Address(T1, 0));
  __ PushRegister(T3);
  __ AddImmediate(T4, T4, 1);
  __ AddImmediate(T1, T1, target::kWordSize);
  __ blt(T4, T5, &push_arguments, Assembler::kNearJump);
  __ Bind(&done_push_arguments);

  if (FLAG_precompiled_mode) {
    __ SetupGlobalPoolAndDispatchTable();
    __ MoveRegister(CODE_REG, ZR);
  } else {
    __ LoadImmediate(PP, 1);
    __ MoveRegister(CODE_REG, A0);
    __ Load(A0, FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  }

  __ Call(A0);

  __ AddImmediate(
      SP, FP,
      target::frame_layout.exit_link_slot_from_entry_fp * target::kWordSize);

  __ Load(TMP, Address(SP, 0 * target::kWordSize));
  __ Store(TMP, Address(THR, target::Thread::top_exit_frame_info_offset()));
  __ Load(TMP, Address(SP, 1 * target::kWordSize));
  __ Store(TMP, Address(THR, target::Thread::exit_through_ffi_offset()));
  __ Load(TMP, Address(SP, 2 * target::kWordSize));
  __ Store(TMP, Address(THR, target::Thread::top_resource_offset()));
  __ Load(TMP, Address(SP, 3 * target::kWordSize));
  __ Store(TMP, Address(THR, target::Thread::vm_tag_offset()));
  __ AddImmediate(SP, SP, 4 * target::kWordSize);

  __ PopNativeCalleeSavedRegisters();
  __ LeaveFrame();
  __ ret();
}

void StubCodeCompiler::GenerateJumpToFrameStub() {
  ASSERT(kExceptionObjectReg == A0);
  ASSERT(kStackTraceObjectReg == A1);
  __ MoveRegister(THR, A3);
  if (FLAG_target_thread_sanitizer) {
    Label again, done;
    __ Load(CALLEE_SAVED_TEMP,
            Address(THR, target::Thread::top_exit_frame_info_offset()));
    __ Load(CALLEE_SAVED_TEMP,
            Address(CALLEE_SAVED_TEMP,
                    target::frame_layout.saved_caller_fp_from_fp *
                        target::kWordSize));
    __ Bind(&again);
    __ beq(CALLEE_SAVED_TEMP, A2, &done, Assembler::kNearJump);
    __ TsanFuncExit();
    __ Load(CALLEE_SAVED_TEMP,
            Address(CALLEE_SAVED_TEMP,
                    target::frame_layout.saved_caller_fp_from_fp *
                        target::kWordSize));
    __ j(&again, Assembler::kNearJump);
    __ Bind(&done);
  }

  __ MoveRegister(CALLEE_SAVED_TEMP, A0);
  __ MoveRegister(SP, A1);
  __ MoveRegister(FP, A2);

#if defined(DART_TARGET_OS_FUCHSIA) || defined(DART_TARGET_OS_ANDROID)
  __ Load(TP, Address(THR, target::Thread::saved_shadow_call_stack_offset()));
#elif defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

  __ RestorePinnedRegisters();
  __ LoadImmediate(TMP, VMTag::kDartTagId);
  __ StoreToOffset(TMP, THR, target::Thread::vm_tag_offset());
  __ StoreToOffset(ZR, THR, target::Thread::top_exit_frame_info_offset());
  __ RestoreCodePointer();
  if (FLAG_precompiled_mode) {
    __ SetupGlobalPoolAndDispatchTable();
  } else {
    __ LoadPoolPointer();
  }
  __ Jump(CALLEE_SAVED_TEMP);
}

void StubCodeCompiler::GenerateLazyCompileStub() {
  __ EnterStubFrame();
  __ PushRegistersInOrder({ARGS_DESC_REG, FUNCTION_REG});
  __ CallRuntime(kCompileFunctionRuntimeEntry, 1);
  __ PopRegister(FUNCTION_REG);
  __ PopRegister(ARGS_DESC_REG);
  __ LeaveStubFrame();

  __ LoadCompressedFieldFromOffset(CODE_REG, FUNCTION_REG,
                                   target::Function::code_offset());
  __ LoadFieldFromOffset(TMP, FUNCTION_REG,
                         target::Function::entry_point_offset());
  __ Jump(TMP);
}

void StubCodeCompiler::GenerateMegamorphicCallStub() {
  Label smi_case;
  __ BranchIfSmi(A0, &smi_case);

  __ LoadClassId(T5, A0);

  Label cid_loaded;
  __ Bind(&cid_loaded);
  __ Load(T1, FieldAddress(IC_DATA_REG, target::MegamorphicCache::mask_offset()));
  __ Load(T8,
          FieldAddress(IC_DATA_REG, target::MegamorphicCache::buckets_offset()));

  __ SmiTag(T5);

  ASSERT(target::MegamorphicCache::kSpreadFactor == 7);
  __ slli_d(T3, T5, 3);
  __ sub_d(T3, T3, T5);

  Label loop;
  __ Bind(&loop);
  __ and_(T3, T3, T1);

  const intptr_t base = target::Array::data_offset();
  __ AddShifted(TMP, T8, T3, kCompressedWordSizeLog2);
  __ LoadCompressedSmiFieldFromOffset(T4, TMP, base);

  Label probe_failed;
  __ bne(T4, T5, &probe_failed, Assembler::kNearJump);

  __ LoadCompressed(FUNCTION_REG,
                    FieldAddress(TMP, base + target::kCompressedWordSize));
  __ Load(A1, FieldAddress(FUNCTION_REG, target::Function::entry_point_offset()));
  __ Load(ARGS_DESC_REG,
          FieldAddress(IC_DATA_REG,
                       target::CallSiteData::arguments_descriptor_offset()));
  if (!FLAG_precompiled_mode) {
    __ LoadCompressed(
        CODE_REG, FieldAddress(FUNCTION_REG, target::Function::code_offset()));
  }
  __ jr(A1);

  __ Bind(&probe_failed);
  ASSERT(kIllegalCid == 0);
  Label miss;
  __ beqz(T4, &miss, Assembler::kNearJump);

  __ AddImmediate(T3, target::ToRawSmi(1));
  __ j(&loop, Assembler::kNearJump);

  __ Bind(&smi_case);
  __ LoadImmediate(T5, kSmiCid);
  __ j(&cid_loaded, Assembler::kNearJump);

  __ Bind(&miss);
  GenerateSwitchableCallMissStub();
}

void StubCodeCompiler::GenerateMonomorphicSmiableCheckStub() {
  Label miss;
  __ LoadClassIdMayBeSmi(T1, A0);

  __ Load(T8, FieldAddress(IC_DATA_REG,
                           target::MonomorphicSmiableCall::expected_cid_offset()));
  __ Load(TMP, FieldAddress(IC_DATA_REG,
                            target::MonomorphicSmiableCall::entrypoint_offset()));
  __ bne(T1, T8, &miss);
  __ jr(TMP);

  __ Bind(&miss);
  __ Load(TMP, Address(THR, target::Thread::switchable_call_miss_entry_offset()));
  __ jr(TMP);
}

static void GenerateRecordEntryPoint(Assembler* assembler) {
  Label done;
  __ LoadImmediate(T6, target::Function::entry_point_offset() - kHeapObjectTag);
  __ j(&done, Assembler::kNearJump);
  __ BindUncheckedEntryPoint();
  __ LoadImmediate(
      T6, target::Function::entry_point_offset(CodeEntryKind::kUnchecked) -
              kHeapObjectTag);
  __ Bind(&done);
}

static void GenerateNoSuchMethodDispatcherBody(Assembler* assembler) {
  __ EnterStubFrame();

  __ Load(ARGS_DESC_REG,
          FieldAddress(IC_DATA_REG,
                       target::CallSiteData::arguments_descriptor_offset()));

  __ LoadCompressedSmiFieldFromOffset(
      S0, ARGS_DESC_REG, target::ArgumentsDescriptor::size_offset());
  __ AddShifted(TMP, FP, S0, target::kWordSizeLog2 - 1);
  __ LoadFromOffset(A0, TMP,
                    target::frame_layout.param_end_from_fp * target::kWordSize);

  __ PushRegistersInOrder({ZR, A0, IC_DATA_REG, ARGS_DESC_REG});

  __ LoadCompressedSmiFieldFromOffset(
      T3, ARGS_DESC_REG, target::ArgumentsDescriptor::type_args_len_offset());
  Label args_count_ok;
  __ beqz(T3, &args_count_ok, Assembler::kNearJump);
  __ AddImmediate(S0, S0, target::ToRawSmi(1));
  __ Bind(&args_count_ok);

  PushArrayOfArguments(assembler);
  constexpr intptr_t kNumArgs = 4;
  __ CallRuntime(kNoSuchMethodFromCallStubRuntimeEntry, kNumArgs);
  __ Drop(4);
  __ PopRegister(A0);
  __ LeaveStubFrame();
  __ ret();
}

static void GenerateDispatcherCode(Assembler* assembler,
                                   Label* call_target_function) {
  __ bne(FUNCTION_REG, NULL_REG, call_target_function);
  GenerateNoSuchMethodDispatcherBody(assembler);
}

void StubCodeCompiler::GenerateOptimizedUsageCounterIncrement() {
  if (FLAG_precompiled_mode) {
    __ Breakpoint();
    return;
  }
  __ LoadFieldFromOffset(TMP, A6, target::Function::usage_counter_offset(),
                         kFourBytes);
  __ AddImmediate(TMP, TMP, 1);
  __ StoreFieldToOffset(TMP, A6, target::Function::usage_counter_offset(),
                        kFourBytes);
}

void StubCodeCompiler::GenerateUsageCounterIncrement(Register func_reg) {
  if (FLAG_precompiled_mode) {
    __ Breakpoint();
    return;
  }
  if (FLAG_optimization_counter_threshold >= 0) {
    __ LoadFieldFromOffset(func_reg, IC_DATA_REG,
                           target::ICData::owner_offset());
    __ LoadFieldFromOffset(
        A1, func_reg, target::Function::usage_counter_offset(), kFourBytes);
    __ AddImmediate(A1, A1, 1);
    __ StoreFieldToOffset(A1, func_reg,
                          target::Function::usage_counter_offset(), kFourBytes);
  }
}

static void EmitFastSmiOp(Assembler* assembler,
                          Token::Kind kind,
                          intptr_t num_args,
                          Label* not_smi_or_overflow) {
  __ LoadFromOffset(A0, SP, 1 * target::kWordSize);
  __ LoadFromOffset(A1, SP, 0 * target::kWordSize);
  __ or_(TMP2, A0, A1);
  __ andi(TMP2, TMP2, kSmiTagMask);
  __ bnez(TMP2, not_smi_or_overflow, Assembler::kNearJump);

  switch (kind) {
    case Token::kADD:
      __ AddBranchOverflow(A0, A0, A1, not_smi_or_overflow);
      break;
    case Token::kLT: {
      Label load_true, done;
      __ blt(A0, A1, &load_true, Assembler::kNearJump);
      __ LoadObject(A0, CastHandle<Object>(FalseObject()));
      __ j(&done, Assembler::kNearJump);
      __ Bind(&load_true);
      __ LoadObject(A0, CastHandle<Object>(TrueObject()));
      __ Bind(&done);
      break;
    }
    case Token::kEQ: {
      Label load_true, done;
      __ beq(A0, A1, &load_true, Assembler::kNearJump);
      __ LoadObject(A0, CastHandle<Object>(FalseObject()));
      __ j(&done, Assembler::kNearJump);
      __ Bind(&load_true);
      __ LoadObject(A0, CastHandle<Object>(TrueObject()));
      __ Bind(&done);
      break;
    }
    default:
      UNIMPLEMENTED();
  }

  __ LoadFieldFromOffset(A6, IC_DATA_REG, target::ICData::entries_offset());
  __ AddImmediate(A6, A6, target::Array::data_offset() - kHeapObjectTag);

#if defined(DEBUG)
  Label error, ok;
  const intptr_t imm_smi_cid = target::ToRawSmi(kSmiCid);
  __ LoadCompressedSmiFromOffset(TMP, A6, 0);
  __ CompareImmediate(TMP, imm_smi_cid);
  __ BranchIf(NE, &error, Assembler::kNearJump);
  __ LoadCompressedSmiFromOffset(TMP, A6, target::kCompressedWordSize);
  __ CompareImmediate(TMP, imm_smi_cid);
  __ BranchIf(EQ, &ok, Assembler::kNearJump);
  __ Bind(&error);
  __ Stop("Incorrect IC data");
  __ Bind(&ok);
#endif

  if (FLAG_optimization_counter_threshold >= 0) {
    const intptr_t count_offset =
        target::ICData::CountIndexFor(num_args) * target::kCompressedWordSize;
    __ LoadCompressedSmiFromOffset(A1, A6, count_offset);
    __ AddImmediate(A1, A1, target::ToRawSmi(1));
    __ StoreToOffset(A1, A6, count_offset);
  }

  __ ret();
}

void StubCodeCompiler::GenerateNArgsCheckInlineCacheStub(
    intptr_t num_args,
    const RuntimeEntry& handle_ic_miss,
    Token::Kind kind,
    Optimized optimized,
    CallType type,
    Exactness exactness) {
  const bool save_entry_point = kind == Token::kILLEGAL;
  if (FLAG_precompiled_mode) {
    __ Breakpoint();
    return;
  }

  if (save_entry_point) {
    GenerateRecordEntryPoint(assembler);
  }

  if (optimized == kOptimized) {
    GenerateOptimizedUsageCounterIncrement();
  } else {
    GenerateUsageCounterIncrement(T0);
  }

  ASSERT(num_args == 1 || num_args == 2);
#if defined(DEBUG)
  {
    Label ok;
    __ LoadFromOffset(TMP, IC_DATA_REG,
                      target::ICData::state_bits_offset() - kHeapObjectTag,
                      kUnsignedFourBytes);
    ASSERT(target::ICData::NumArgsTestedShift() == 0);
    __ andi(TMP, TMP, target::ICData::NumArgsTestedMask());
    __ CompareImmediate(TMP, num_args);
    __ BranchIf(EQ, &ok, Assembler::kNearJump);
    __ Stop("Incorrect stub for IC data");
    __ Bind(&ok);
  }
#endif

#if !defined(PRODUCT)
  Label stepping, done_stepping;
  if (optimized == kUnoptimized) {
    __ LoadFromOffset(TMP, THR, target::Thread::single_step_offset(),
                      kUnsignedByte);
    __ bnez(TMP, &stepping, Assembler::kNearJump);
    __ Bind(&done_stepping);
  }
#endif

  Label not_smi_or_overflow;
  if (kind != Token::kILLEGAL) {
    EmitFastSmiOp(assembler, kind, num_args, &not_smi_or_overflow);
  }
  __ Bind(&not_smi_or_overflow);

  __ LoadFieldFromOffset(A1, IC_DATA_REG, target::ICData::entries_offset());
  __ AddImmediate(A1, A1, target::Array::data_offset() - kHeapObjectTag);

  if (type == kInstanceCall) {
    __ LoadTaggedClassIdMayBeSmi(T1, A0);
    __ LoadFieldFromOffset(ARGS_DESC_REG, IC_DATA_REG,
                           target::CallSiteData::arguments_descriptor_offset());
    if (num_args == 2) {
      __ LoadCompressedSmiFieldFromOffset(
          A7, ARGS_DESC_REG, target::ArgumentsDescriptor::count_offset());
      __ slli_d(A7, A7, target::kWordSizeLog2 - kSmiTagSize);
      __ add_d(A7, SP, A7);
      __ LoadFromOffset(A6, A7, -2 * target::kWordSize);
      __ LoadTaggedClassIdMayBeSmi(T8, A6);
    }
  } else {
    __ LoadFieldFromOffset(ARGS_DESC_REG, IC_DATA_REG,
                           target::CallSiteData::arguments_descriptor_offset());
    __ LoadCompressedSmiFieldFromOffset(
        A7, ARGS_DESC_REG, target::ArgumentsDescriptor::count_offset());
    __ slli_d(A7, A7, target::kWordSizeLog2 - kSmiTagSize);
    __ add_d(A7, A7, SP);
    __ LoadFromOffset(A6, A7, -target::kWordSize);
    __ LoadTaggedClassIdMayBeSmi(T1, A6);
    if (num_args == 2) {
      __ LoadFromOffset(A6, A7, -2 * target::kWordSize);
      __ LoadTaggedClassIdMayBeSmi(T8, A6);
    }
  }

  const bool optimize = kind == Token::kILLEGAL;

  Label loop, found, miss;
  __ Bind(&loop);
  for (int unroll = optimize ? 4 : 2; unroll >= 0; unroll--) {
    Label update;

    __ LoadCompressedSmiFromOffset(A7, A1, 0);
    if (num_args == 1) {
      __ beq(A7, T1, &found, Assembler::kNearJump);
    } else {
      __ bne(A7, T1, &update, Assembler::kNearJump);
      __ LoadCompressedSmiFromOffset(A7, A1, target::kCompressedWordSize);
      __ beq(A7, T8, &found, Assembler::kNearJump);
    }
    __ Bind(&update);

    const intptr_t entry_size = target::ICData::TestEntryLengthFor(
                                    num_args, exactness == kCheckExactness) *
                                target::kCompressedWordSize;
    __ AddImmediate(A1, A1, entry_size);

    __ CompareImmediate(A7, target::ToRawSmi(kIllegalCid));
    if (unroll == 0) {
      __ BranchIf(NE, &loop, Assembler::kNearJump);
    } else {
      __ BranchIf(EQ, &miss, Assembler::kNearJump);
    }
  }

  __ Bind(&miss);
  __ LoadCompressedSmiFieldFromOffset(
      A7, ARGS_DESC_REG, target::ArgumentsDescriptor::count_offset());
  __ slli_d(A7, A7, target::kWordSizeLog2 - kSmiTagSize);
  __ add_d(A7, A7, SP);
  __ AddImmediate(A7, A7, -target::kWordSize);

  __ EnterStubFrame();
  __ PushRegistersInOrder({ARGS_DESC_REG, IC_DATA_REG});
  if (save_entry_point) {
    __ SmiTag(T6);
    __ PushRegister(T6);
  }
  __ PushRegister(ZR);
  for (intptr_t i = 0; i < num_args; i++) {
    __ LoadFromOffset(TMP, A7, -target::kWordSize * i);
    __ PushRegister(TMP);
  }
  __ PushRegister(IC_DATA_REG);
  __ CallRuntime(handle_ic_miss, num_args + 1);
  __ Drop(num_args + 1);
  __ PopRegister(FUNCTION_REG);
  if (save_entry_point) {
    __ PopRegister(T6);
    __ SmiUntag(T6);
  }
  __ PopRegister(IC_DATA_REG);
  __ PopRegister(ARGS_DESC_REG);
  __ RestoreCodePointer();
  __ LeaveStubFrame();

  Label call_target_function;
  if (FLAG_precompiled_mode) {
    GenerateDispatcherCode(assembler, &call_target_function);
  } else {
    __ j(&call_target_function, Assembler::kNearJump);
  }

  __ Bind(&found);
  const intptr_t target_offset =
      target::ICData::TargetIndexFor(num_args) * target::kCompressedWordSize;
  const intptr_t count_offset =
      target::ICData::CountIndexFor(num_args) * target::kCompressedWordSize;
  const intptr_t exactness_offset =
      target::ICData::ExactnessIndexFor(num_args) * target::kCompressedWordSize;

  Label call_target_function_through_unchecked_entry;
  if (exactness == kCheckExactness) {
    Label exactness_ok;
    ASSERT(num_args == 1);
    __ LoadCompressedSmi(T1, Address(A1, exactness_offset));
    __ LoadImmediate(
        TMP, target::ToRawSmi(
                 StaticTypeExactnessState::HasExactSuperType().Encode()));
    __ blt(T1, TMP, &exactness_ok, Assembler::kNearJump);
    __ beq(T1, TMP, &call_target_function_through_unchecked_entry,
           Assembler::kNearJump);

    __ LoadCompressed(
        T8, FieldAddress(IC_DATA_REG,
                         target::ICData::receivers_static_type_offset()));
    __ LoadCompressed(T8, FieldAddress(T8, target::Type::arguments_offset()));
    __ LoadIndexedPayload(TMP, A0, 0, T1, TIMES_COMPRESSED_HALF_WORD_SIZE,
                          kObjectBytes);
    __ beq(T8, TMP, &call_target_function_through_unchecked_entry,
           Assembler::kNearJump);

    __ LoadImmediate(
        TMP, target::ToRawSmi(StaticTypeExactnessState::NotExact().Encode()));
    __ StoreToOffset(TMP, A1, exactness_offset, kObjectBytes);
    __ Bind(&exactness_ok);
  }

  __ LoadCompressedFromOffset(FUNCTION_REG, A1, target_offset);

  if (FLAG_optimization_counter_threshold >= 0) {
    __ LoadCompressedSmiFromOffset(TMP, A1, count_offset);
    __ AddImmediate(TMP, TMP, target::ToRawSmi(1));
    __ StoreToOffset(TMP, A1, count_offset, kObjectBytes);
  }

  __ Bind(&call_target_function);
  __ LoadCompressedFieldFromOffset(CODE_REG, FUNCTION_REG,
                                   target::Function::code_offset());
  if (save_entry_point) {
    __ add_d(A7, FUNCTION_REG, T6);
    __ Load(A7, Address(A7, 0));
  } else {
    __ LoadFieldFromOffset(A7, FUNCTION_REG,
                           target::Function::entry_point_offset());
  }
  __ jr(A7);

  if (exactness == kCheckExactness) {
    __ Bind(&call_target_function_through_unchecked_entry);
    if (FLAG_optimization_counter_threshold >= 0) {
      __ LoadCompressedSmiFromOffset(TMP, A1, count_offset);
      __ AddImmediate(TMP, TMP, target::ToRawSmi(1));
      __ StoreToOffset(TMP, A1, count_offset, kObjectBytes);
    }
    __ LoadCompressedFromOffset(FUNCTION_REG, A1, target_offset);
    __ LoadCompressedFieldFromOffset(CODE_REG, FUNCTION_REG,
                                     target::Function::code_offset());
    __ LoadFieldFromOffset(
        A7, FUNCTION_REG,
        target::Function::entry_point_offset(CodeEntryKind::kUnchecked));
    __ jr(A7);
  }

#if !defined(PRODUCT)
  if (optimized == kUnoptimized) {
    __ Bind(&stepping);
    __ EnterStubFrame();
    if (type == kInstanceCall) {
      __ PushRegister(A0);
    }
    if (save_entry_point) {
      __ SmiTag(T6);
      __ PushRegister(T6);
    }
    __ PushRegister(IC_DATA_REG);
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ PopRegister(IC_DATA_REG);
    if (save_entry_point) {
      __ PopRegister(T6);
      __ SmiUntag(T6);
    }
    if (type == kInstanceCall) {
      __ PopRegister(A0);
    }
    __ RestoreCodePointer();
    __ LeaveStubFrame();
    __ j(&done_stepping, Assembler::kNearJump);
  }
#endif
}

void StubCodeCompiler::GenerateNoSuchMethodDispatcherStub() {
  GenerateNoSuchMethodDispatcherBody(assembler);
}

void StubCodeCompiler::GenerateOneArgCheckInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      1, kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

void StubCodeCompiler::GenerateOneArgCheckInlineCacheWithExactnessCheckStub() {
  GenerateNArgsCheckInlineCacheStub(
      1, kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kInstanceCall, kCheckExactness);
}

void StubCodeCompiler::GenerateOneArgOptimizedCheckInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      1, kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      kOptimized, kInstanceCall, kIgnoreExactness);
}

void StubCodeCompiler::GenerateOneArgOptimizedCheckInlineCacheWithExactnessCheckStub() {
  GenerateNArgsCheckInlineCacheStub(
      1, kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      kOptimized, kInstanceCall, kCheckExactness);
}

void StubCodeCompiler::GenerateOneArgUnoptimizedStaticCallStub() {
  GenerateUsageCounterIncrement(T0);
  GenerateNArgsCheckInlineCacheStub(1, kStaticCallMissHandlerOneArgRuntimeEntry,
                                    Token::kILLEGAL, kUnoptimized, kStaticCall,
                                    kIgnoreExactness);
}

static void GenerateIdenticalWithNumberCheckStub(Assembler* assembler,
                                                 const Register left,
                                                 const Register right) {
  Label reference_compare, check_mint, done;
  // If either argument is a Smi, reference comparison is enough. A Mint cannot
  // contain a value that would fit in a Smi.
  __ BranchIfSmi(left, &reference_compare, Assembler::kNearJump);
  __ BranchIfSmi(right, &reference_compare, Assembler::kNearJump);

  __ CompareClassId(left, kDoubleCid, /*scratch=*/TMP);
  __ BranchIf(NOT_EQUAL, &check_mint, Assembler::kNearJump);
  __ CompareClassId(right, kDoubleCid, /*scratch=*/TMP);
  __ BranchIf(NOT_EQUAL, &reference_compare, Assembler::kNearJump);

  __ Load(T0, FieldAddress(left, target::Double::value_offset()));
  __ Load(T1, FieldAddress(right, target::Double::value_offset()));
  __ xor_(TMP, T0, T1);
  __ j(&done, Assembler::kNearJump);

  __ Bind(&check_mint);
  __ CompareClassId(left, kMintCid, /*scratch=*/TMP);
  __ BranchIf(NOT_EQUAL, &reference_compare, Assembler::kNearJump);
  __ CompareClassId(right, kMintCid, /*scratch=*/TMP);
  __ BranchIf(NOT_EQUAL, &reference_compare, Assembler::kNearJump);

  __ Load(T0, FieldAddress(left, target::Mint::value_offset()));
  __ Load(T1, FieldAddress(right, target::Mint::value_offset()));
  __ xor_(TMP, T0, T1);
  __ j(&done, Assembler::kNearJump);

  __ Bind(&reference_compare);
  __ xor_(TMP, left, right);
  __ Bind(&done);
}

void StubCodeCompiler::GenerateOptimizedIdenticalWithNumberCheckStub() {
  const Register left = A0;
  const Register right = A1;
  __ LoadFromOffset(left, SP, 1 * target::kWordSize);
  __ LoadFromOffset(right, SP, 0 * target::kWordSize);
  GenerateIdenticalWithNumberCheckStub(assembler, left, right);
  __ ret();
}

void StubCodeCompiler::GenerateOptimizeFunctionStub() {
  __ LoadFromOffset(CODE_REG, THR, target::Thread::optimize_stub_offset());
  __ EnterStubFrame();

  __ AddImmediate(SP, SP, -3 * target::kWordSize);
  __ Store(ARGS_DESC_REG, Address(SP, 2 * target::kWordSize));
  __ Store(ZR, Address(SP, 1 * target::kWordSize));
  __ Store(A0, Address(SP, 0 * target::kWordSize));
  __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry, 1);
  __ Load(FUNCTION_REG, Address(SP, 1 * target::kWordSize));
  __ Load(ARGS_DESC_REG, Address(SP, 2 * target::kWordSize));
  __ AddImmediate(SP, SP, 3 * target::kWordSize);

  __ LoadCompressedFieldFromOffset(CODE_REG, FUNCTION_REG,
                                   target::Function::code_offset());
  __ LoadFieldFromOffset(A1, FUNCTION_REG,
                         target::Function::entry_point_offset());
  __ LeaveStubFrame();
  __ jr(A1);
  __ Breakpoint();
}

static void GenerateRunExceptionHandler(Assembler* assembler,
                                        bool unbox_exception) {
  ASSERT(kExceptionObjectReg == A0);
  __ LoadFromOffset(A0, THR, target::Thread::active_exception_offset());
  __ StoreToOffset(NULL_REG, THR, target::Thread::active_exception_offset());
  if (unbox_exception) {
    Label not_smi, done;
    __ BranchIfNotSmi(A0, &not_smi, Assembler::kNearJump);
    __ SmiUntag(A0);
    __ j(&done, Assembler::kNearJump);
    __ Bind(&not_smi);
    __ Load(A0, FieldAddress(A0, target::Mint::value_offset()));
    __ Bind(&done);
  }

  ASSERT(kStackTraceObjectReg == A1);
  __ LoadFromOffset(A1, THR, target::Thread::active_stacktrace_offset());
  __ StoreToOffset(NULL_REG, THR, target::Thread::active_stacktrace_offset());

  __ LoadFromOffset(RA, THR, target::Thread::resume_pc_offset());
  __ ret();
}

void StubCodeCompiler::GenerateRunExceptionHandlerStub() {
  GenerateRunExceptionHandler(assembler, false);
}

void StubCodeCompiler::GenerateRunExceptionHandlerUnboxStub() {
  GenerateRunExceptionHandler(assembler, true);
}

void StubCodeCompiler::GenerateRuntimeCallBreakpointStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateSingleTargetCallStub() {
  Label miss;
  __ LoadClassIdMayBeSmi(A1, A0);
  __ Load(T8,
          FieldAddress(IC_DATA_REG,
                       target::SingleTargetCache::lower_limit_offset()),
          kUnsignedTwoBytes);
  __ Load(T3,
          FieldAddress(IC_DATA_REG,
                       target::SingleTargetCache::upper_limit_offset()),
          kUnsignedTwoBytes);

  __ blt(A1, T8, &miss);
  __ blt(T3, A1, &miss);

  __ Load(TMP, FieldAddress(IC_DATA_REG,
                            target::SingleTargetCache::entry_point_offset()));
  __ Load(CODE_REG,
          FieldAddress(IC_DATA_REG, target::SingleTargetCache::target_offset()));
  __ jr(TMP);

  __ Bind(&miss);
  __ EnterStubFrame();
  __ PushRegistersInOrder({A0, ZR, ZR, A0});
  __ CallRuntime(kSwitchableCallMissRuntimeEntry, 2);
  __ Drop(1);
  __ PopRegister(CODE_REG);
  __ PopRegister(IC_DATA_REG);

  __ PopRegister(A0);
  __ LeaveStubFrame();

  __ Load(TMP,
          FieldAddress(CODE_REG, target::Code::entry_point_offset(
                                     CodeEntryKind::kMonomorphic)));
  __ jr(TMP);
}

void StubCodeCompiler::GenerateSmiAddInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kADD, kUnoptimized,
      kInstanceCall, kIgnoreExactness);
}

void StubCodeCompiler::GenerateSmiEqualInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kEQ, kUnoptimized,
      kInstanceCall, kIgnoreExactness);
}

void StubCodeCompiler::GenerateSmiLessInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kLT, kUnoptimized,
      kInstanceCall, kIgnoreExactness);
}

void StubCodeCompiler::GenerateSwitchableCallMissStub() {
  __ Load(CODE_REG,
          Address(THR, target::Thread::switchable_call_miss_stub_offset()));
  __ EnterStubFrame();
  __ PushRegistersInOrder({A0, ZR, ZR, A0});
  __ CallRuntime(kSwitchableCallMissRuntimeEntry, 2);
  __ Drop(1);
  __ PopRegister(CODE_REG);
  __ PopRegister(IC_DATA_REG);

  __ PopRegister(A0);
  __ LeaveStubFrame();

  __ Load(TMP, FieldAddress(CODE_REG, target::Code::entry_point_offset(
                                          CodeEntryKind::kNormal)));
  __ jr(TMP);
}

void StubCodeCompiler::GenerateTwoArgsCheckInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

void StubCodeCompiler::GenerateTwoArgsOptimizedCheckInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kOptimized, kInstanceCall, kIgnoreExactness);
}

void StubCodeCompiler::GenerateTwoArgsUnoptimizedStaticCallStub() {
  GenerateUsageCounterIncrement(T0);
  GenerateNArgsCheckInlineCacheStub(
      2, kStaticCallMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kStaticCall, kIgnoreExactness);
}

void StubCodeCompiler::GenerateUnoptimizedIdenticalWithNumberCheckStub() {
#if !defined(PRODUCT)
  Label stepping, done_stepping;
  __ LoadFromOffset(TMP, THR, target::Thread::single_step_offset(),
                    kUnsignedByte);
  __ bnez(TMP, &stepping, Assembler::kNearJump);
  __ Bind(&done_stepping);
#endif

  const Register left = A0;
  const Register right = A1;
  __ LoadFromOffset(left, SP, 1 * target::kWordSize);
  __ LoadFromOffset(right, SP, 0 * target::kWordSize);
  GenerateIdenticalWithNumberCheckStub(assembler, left, right);
  __ ret();

#if !defined(PRODUCT)
  __ Bind(&stepping);
  __ EnterStubFrame();
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ RestoreCodePointer();
  __ LeaveStubFrame();
  __ j(&done_stepping, Assembler::kNearJump);
#endif
}

void StubCodeCompiler::GenerateUnoptStaticCallBreakpointStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateWriteBarrierStub() {
  GenerateWriteBarrierStubHelper(assembler, false);
}

void StubCodeCompiler::GenerateWriteBarrierWrappersStub() {
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
    if ((kDartAvailableCpuRegs & (static_cast<RegList>(1) << i)) == 0) {
      continue;
    }

    Register reg = static_cast<Register>(i);
    const intptr_t start = __ CodeSize();
    __ AddImmediate(SP, SP, -3 * target::kWordSize);
    __ Store(RA, Address(SP, 2 * target::kWordSize));
    __ Store(TMP, Address(SP, 1 * target::kWordSize));
    __ Store(kWriteBarrierObjectReg, Address(SP, 0 * target::kWordSize));
    __ addi_d(kWriteBarrierObjectReg, reg, 0);
    __ Call(Address(THR, target::Thread::write_barrier_entry_point_offset()));
    __ Load(kWriteBarrierObjectReg, Address(SP, 0 * target::kWordSize));
    __ Load(TMP, Address(SP, 1 * target::kWordSize));
    __ Load(RA, Address(SP, 2 * target::kWordSize));
    __ AddImmediate(SP, SP, 3 * target::kWordSize);
    __ jr(TMP);
    const intptr_t end = __ CodeSize();
    ASSERT_EQUAL(end - start, kStoreBufferWrapperSize);
  }
}

void StubCodeCompiler::GenerateZeroArgsUnoptimizedStaticCallStub() {
  GenerateRecordEntryPoint(assembler);
  GenerateUsageCounterIncrement(T0);

#if defined(DEBUG)
  {
    Label ok;
    __ LoadFromOffset(TMP, IC_DATA_REG,
                      target::ICData::state_bits_offset() - kHeapObjectTag,
                      kUnsignedFourBytes);
    ASSERT(target::ICData::NumArgsTestedShift() == 0);
    __ andi(TMP, TMP, target::ICData::NumArgsTestedMask());
    __ CompareImmediate(TMP, 0);
    __ BranchIf(EQ, &ok);
    __ Stop("Incorrect IC data for unoptimized static call");
    __ Bind(&ok);
  }
#endif

#if !defined(PRODUCT)
  Label stepping, done_stepping;
  __ LoadFromOffset(TMP, THR, target::Thread::single_step_offset(),
                    kUnsignedByte);
  __ BranchIfNotZero(TMP, &stepping, Assembler::kNearJump);
  __ Bind(&done_stepping);
#endif

  __ LoadFieldFromOffset(A0, IC_DATA_REG, target::ICData::entries_offset());
  __ AddImmediate(A0, A0, target::Array::data_offset() - kHeapObjectTag);

  const intptr_t target_offset =
      target::ICData::TargetIndexFor(0) * target::kCompressedWordSize;
  const intptr_t count_offset =
      target::ICData::CountIndexFor(0) * target::kCompressedWordSize;

  if (FLAG_optimization_counter_threshold >= 0) {
    __ LoadCompressedSmiFromOffset(TMP, A0, count_offset);
    __ AddImmediate(TMP, TMP, target::ToRawSmi(1));
    __ StoreToOffset(TMP, A0, count_offset);
  }

  __ LoadFieldFromOffset(ARGS_DESC_REG, IC_DATA_REG,
                         target::CallSiteData::arguments_descriptor_offset());

  __ LoadCompressedFromOffset(FUNCTION_REG, A0, target_offset);
  __ LoadCompressedFieldFromOffset(CODE_REG, FUNCTION_REG,
                                   target::Function::code_offset());
  __ add_d(A0, FUNCTION_REG, T6);
  __ Load(TMP, Address(A0, 0));
  __ Jump(TMP);

#if !defined(PRODUCT)
  __ Bind(&stepping);
  __ EnterStubFrame();
  __ PushRegister(IC_DATA_REG);
  __ SmiTag(T6);
  __ PushRegister(T6);
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ PopRegister(T6);
  __ SmiUntag(T6);
  __ PopRegister(IC_DATA_REG);
  __ RestoreCodePointer();
  __ LeaveStubFrame();
  __ j(&done_stepping, Assembler::kNearJump);
#endif
}

static int GetScaleFactor(intptr_t size) {
  switch (size) {
    case 1:
      return 0;
    case 2:
      return 1;
    case 4:
      return 2;
    case 8:
      return 3;
    case 16:
      return 4;
  }
  UNREACHABLE();
  return -1;
}

void StubCodeCompiler::GenerateAllocateTypedDataArrayStub(intptr_t cid) {
  const intptr_t element_size = TypedDataElementSizeInBytes(cid);
  const intptr_t max_len = TypedDataMaxNewSpaceElements(cid);
  const intptr_t scale_shift = GetScaleFactor(element_size);

  COMPILE_ASSERT(AllocateTypedDataArrayABI::kLengthReg == S0);
  COMPILE_ASSERT(AllocateTypedDataArrayABI::kResultReg == A0);

  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    Label call_runtime;
    NOT_IN_PRODUCT(__ MaybeTraceAllocation(cid, &call_runtime, T3));
    __ MoveRegister(T3, AllocateTypedDataArrayABI::kLengthReg);

    __ BranchIfNotSmi(T3, &call_runtime);
    __ SmiUntag(T3);
    __ CompareImmediate(T3, max_len, kObjectBytes);
    __ BranchIf(UNSIGNED_GREATER, &call_runtime);

    if (scale_shift != 0) {
      __ slli_d(T3, T3, scale_shift);
    }
    const intptr_t fixed_size_plus_alignment_padding =
        target::TypedData::HeaderSize() +
        target::ObjectAlignment::kObjectAlignment - 1;
    __ AddImmediate(T3, fixed_size_plus_alignment_padding);
    __ AndImmediate(T3, T3, ~(target::ObjectAlignment::kObjectAlignment - 1));

    __ Load(A0, Address(THR, target::Thread::top_offset()));
    __ add_d(T4, A0, T3);
    __ bltu(T4, A0, &call_runtime);

    __ Load(TMP, Address(THR, target::Thread::end_offset()));
    __ bgeu(T4, TMP, &call_runtime);
    __ CheckAllocationCanary(A0);

    __ Store(T4, Address(THR, target::Thread::top_offset()));
    __ AddImmediate(A0, A0, kHeapObjectTag);

    __ LoadImmediate(T5, 0);
    __ CompareImmediate(T3, target::UntaggedObject::kSizeTagMaxSizeTag);
    Label zero_tags;
    __ BranchIf(HI, &zero_tags);
    __ slli_d(T5, T3,
              target::UntaggedObject::kSizeTagPos -
                  target::ObjectAlignment::kObjectAlignmentLog2);
    __ Bind(&zero_tags);

    const uword tags =
        target::MakeTagWordForNewSpaceObject(cid, /*instance_size=*/0);
    __ OrImmediate(T5, T5, tags);
    __ InitializeHeader(T5, A0);

    __ MoveRegister(T3, AllocateTypedDataArrayABI::kLengthReg);
    __ StoreCompressedIntoObjectNoBarrier(
        A0, FieldAddress(A0, target::TypedDataBase::length_offset()), T3);

    __ AddImmediate(T3, A0, target::TypedData::HeaderSize() - kHeapObjectTag);
    __ StoreInternalPointer(
        A0, FieldAddress(A0, target::PointerBase::data_offset()), T3);

    Label loop;
    __ Bind(&loop);
    for (intptr_t offset = 0; offset < target::kObjectAlignment;
         offset += target::kWordSize) {
      __ Store(ZR, Address(T3, offset));
    }
    ASSERT(kAllocationRedZoneSize >= target::ObjectAlignment::kObjectAlignment);
    __ AddImmediate(T3, T3, target::ObjectAlignment::kObjectAlignment);
    __ bltu(T3, T4, &loop);
    __ WriteAllocationCanary(T4);

    __ ret();

    __ Bind(&call_runtime);
  }

  __ EnterStubFrame();
  __ PushRegister(ZR);                                     // Result slot.
  __ PushImmediate(target::ToRawSmi(cid));                 // Cid.
  __ PushRegister(AllocateTypedDataArrayABI::kLengthReg);  // Array length.
  __ CallRuntime(kAllocateTypedDataRuntimeEntry, 2);
  __ Drop(2);
  __ PopRegister(AllocateTypedDataArrayABI::kResultReg);
  __ LeaveStubFrame();
  __ ret();
}

void StubCodeCompiler::GenerateAllocationStubForClass(
    UnresolvedPcRelativeCalls* unresolved_calls,
    const Class& cls,
    const dart::Code& allocate_object,
    const dart::Code& allocate_object_parameterized) {
  classid_t cls_id = target::Class::GetId(cls);
  ASSERT(cls_id != kIllegalCid);

  const bool is_cls_parameterized = target::Class::NumTypeArguments(cls) > 0;
  ASSERT(!is_cls_parameterized || target::Class::TypeArgumentsFieldOffset(
                                      cls) != target::Class::kNoTypeArguments);

  const intptr_t instance_size = target::Class::GetInstanceSize(cls);
  ASSERT(instance_size > 0);

  const uword tags =
      target::MakeTagWordForNewSpaceObject(cls_id, instance_size);
  const Register kTagsReg = AllocateObjectABI::kTagsReg;
  ASSERT(kTagsReg != AllocateObjectABI::kTypeArgumentsReg);
  __ LoadImmediate(kTagsReg, tags);

  if (!FLAG_use_slow_path && FLAG_inline_alloc &&
      !target::Class::TraceAllocation(cls) &&
      target::SizeFitsInSizeTag(instance_size)) {
    RELEASE_ASSERT(AllocateObjectInstr::WillAllocateNewOrRemembered(cls));
    RELEASE_ASSERT(target::Heap::IsAllocatableInNewSpace(instance_size));

    if (is_cls_parameterized) {
      if (!IsSameObject(NullObject(),
                        CastHandle<Object>(allocate_object_parameterized))) {
        __ GenerateUnRelocatedPcRelativeTailCall();
        unresolved_calls->Add(new UnresolvedPcRelativeCall(
            __ CodeSize(), allocate_object_parameterized,
            /*is_tail_call=*/true));
      } else {
        __ Load(TMP,
                Address(THR,
                        target::Thread::
                            allocate_object_parameterized_entry_point_offset()));
        __ Jump(TMP);
      }
    } else {
      if (!IsSameObject(NullObject(), CastHandle<Object>(allocate_object))) {
        __ GenerateUnRelocatedPcRelativeTailCall();
        unresolved_calls->Add(new UnresolvedPcRelativeCall(
            __ CodeSize(), allocate_object, /*is_tail_call=*/true));
      } else {
        __ Load(TMP, Address(THR,
                             target::Thread::
                                 allocate_object_entry_point_offset()));
        __ Jump(TMP);
      }
    }
  } else {
    if (!is_cls_parameterized) {
      __ LoadObject(AllocateObjectABI::kTypeArgumentsReg, NullObject());
    }
    __ Load(TMP, Address(THR,
                         target::Thread::
                             allocate_object_slow_entry_point_offset()));
    __ Jump(TMP);
  }
}

void StubCodeCompiler::GenerateRangeError(bool) {
  assembler->Ret();
}

void StubCodeCompiler::GenerateWriteError(bool) {
  assembler->Ret();
}

void StubCodeCompiler::GenerateSharedStubGeneric(bool,
                                                 intptr_t,
                                                 bool,
                                                 std::function<void()>) {
  assembler->Ret();
}

void StubCodeCompiler::GenerateSharedStub(bool,
                                          const RuntimeEntry*,
                                          intptr_t,
                                          bool,
                                          bool) {
  assembler->Ret();
}

void StubCodeCompiler::GenerateSubtypeNTestCacheStub(Assembler* assembler,
                                                     int n) {
  ASSERT(n >= 1);
  ASSERT(n <= SubtypeTestCache::kMaxInputs);
  ASSERT(n != 5);

  const Register kCacheArrayReg = TypeTestABI::kSubtypeTestCacheResultReg;

  GenerateSubtypeTestCacheSearch(
      assembler, n, NULL_REG, kCacheArrayReg,
      STCInternalRegs::kInstanceCidOrSignatureReg,
      STCInternalRegs::kInstanceInstantiatorTypeArgumentsReg,
      STCInternalRegs::kInstanceParentFunctionTypeArgumentsReg,
      STCInternalRegs::kInstanceDelayedFunctionTypeArgumentsReg,
      STCInternalRegs::kCacheEntriesEndReg,
      STCInternalRegs::kCacheContentsSizeReg,
      STCInternalRegs::kProbeDistanceReg,
      [&](Assembler* assembler, int n) {
        __ LoadCompressed(
            TypeTestABI::kSubtypeTestCacheResultReg,
            Address(kCacheArrayReg, target::kCompressedWordSize *
                                        target::SubtypeTestCache::kTestResult));
        __ Ret();
      },
      [&](Assembler* assembler, int n) {
        __ MoveRegister(TypeTestABI::kSubtypeTestCacheResultReg, NULL_REG);
        __ Ret();
      });
}

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_LOONG64)
