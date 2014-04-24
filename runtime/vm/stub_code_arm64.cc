// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM64)

#include "vm/assembler.h"
#include "vm/code_generator.h"
#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph_compiler.h"
#include "vm/heap.h"
#include "vm/instructions.h"
#include "vm/object_store.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/tags.h"

#define __ assembler->

namespace dart {

// Input parameters:
//   LR : return address.
//   SP : address of last argument in argument array.
//   SP + 8*R4 - 8 : address of first argument in argument array.
//   SP + 8*R4 : address of return value.
//   R5 : address of the runtime function to call.
//   R4 : number of arguments to the call.
void StubCode::GenerateCallToRuntimeStub(Assembler* assembler) {
  const intptr_t isolate_offset = NativeArguments::isolate_offset();
  const intptr_t argc_tag_offset = NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = NativeArguments::argv_offset();
  const intptr_t retval_offset = NativeArguments::retval_offset();
  const intptr_t exitframe_last_param_slot_from_fp = 1;

  __ SetPrologueOffset();
  __ Comment("CallToRuntimeStub");
  __ EnterFrame(0);

  // Load current Isolate pointer from Context structure into A0.
  __ LoadFieldFromOffset(R0, CTX, Context::isolate_offset());

  // Save exit frame information to enable stack walking as we are about
  // to transition to Dart VM C++ code.
  __ StoreToOffset(SP, R0, Isolate::top_exit_frame_info_offset());

  // Save current Context pointer into Isolate structure.
  __ StoreToOffset(CTX, R0, Isolate::top_context_offset());

  // Cache Isolate pointer into CTX while executing runtime code.
  __ mov(CTX, R0);

#if defined(DEBUG)
  { Label ok;
    // Check that we are always entering from Dart code.
    __ LoadFromOffset(R8, R0, Isolate::vm_tag_offset());
    __ CompareImmediate(R8, VMTag::kScriptTagId, kNoRegister);
    __ b(&ok, EQ);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the isolate is executing VM code.
  __ StoreToOffset(R5, R0, Isolate::vm_tag_offset());

  // Reserve space for arguments and align frame before entering C++ world.
  // NativeArguments are passed in registers.
  __ Comment("align stack");
  ASSERT(sizeof(NativeArguments) == 4 * kWordSize);
  __ ReserveAlignedFrameSpace(4 * kWordSize);  // Reserve space for arguments.

  // Pass NativeArguments structure by value and call runtime.
  // Registers R0, R1, R2, and R3 are used.

  ASSERT(isolate_offset == 0 * kWordSize);
  // Set isolate in NativeArgs: R0 already contains CTX.

  // There are no runtime calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * kWordSize);
  __ mov(R1, R4);  // Set argc in NativeArguments.

  ASSERT(argv_offset == 2 * kWordSize);
  __ add(R2, ZR, Operand(R4, LSL, 3));
  __ add(R2, FP, Operand(R2));  // Compute argv.
  // Set argv in NativeArguments.
  __ AddImmediate(R2, R2, exitframe_last_param_slot_from_fp * kWordSize,
                  kNoRegister);

    ASSERT(retval_offset == 3 * kWordSize);
  __ AddImmediate(R3, R2, kWordSize, kNoRegister);

  // TODO(zra): Check that the ABI allows calling through this register.
  __ blr(R5);

  // Retval is next to 1st argument.
  __ Comment("CallToRuntimeStub return");

  // Mark that the isolate is executing Dart code.
  __ LoadImmediate(R2, VMTag::kScriptTagId, kNoRegister);
  __ StoreToOffset(R2, CTX, Isolate::vm_tag_offset());

  // Reset exit frame information in Isolate structure.
  __ StoreToOffset(ZR, CTX, Isolate::top_exit_frame_info_offset());

  // Load Context pointer from Isolate structure into A2.
  __ LoadFromOffset(R2, CTX, Isolate::top_context_offset());

  // Load null.
  __ LoadObject(TMP, Object::null_object(), PP);

  // Reset Context pointer in Isolate structure.
  __ StoreToOffset(TMP, CTX, Isolate::top_context_offset());

  // Cache Context pointer into CTX while executing Dart code.
  __ mov(CTX, R2);

  __ LeaveFrame();
  __ ret();
}


void StubCode::GeneratePrintStopMessageStub(Assembler* assembler) {
  __ Stop("GeneratePrintStopMessageStub");
}


void StubCode::GenerateCallNativeCFunctionStub(Assembler* assembler) {
  __ Stop("GenerateCallNativeCFunctionStub");
}


void StubCode::GenerateCallBootstrapCFunctionStub(Assembler* assembler) {
  __ Stop("GenerateCallBootstrapCFunctionStub");
}


void StubCode::GenerateCallStaticFunctionStub(Assembler* assembler) {
  __ Stop("GenerateCallStaticFunctionStub");
}


void StubCode::GenerateFixCallersTargetStub(Assembler* assembler) {
  __ Stop("GenerateFixCallersTargetStub");
}


void StubCode::GenerateDeoptimizeLazyStub(Assembler* assembler) {
  __ Stop("GenerateDeoptimizeLazyStub");
}


void StubCode::GenerateDeoptimizeStub(Assembler* assembler) {
  __ Stop("GenerateDeoptimizeStub");
}


void StubCode::GenerateMegamorphicMissStub(Assembler* assembler) {
  __ Stop("GenerateMegamorphicMissStub");
}


void StubCode::GenerateAllocateArrayStub(Assembler* assembler) {
  __ Stop("GenerateAllocateArrayStub");
}


// Called when invoking Dart code from C++ (VM code).
// Input parameters:
//   LR : points to return address.
//   R0 : entrypoint of the Dart function to call.
//   R1 : arguments descriptor array.
//   R2 : arguments array.
//   R3 : new context containing the current isolate pointer.
void StubCode::GenerateInvokeDartCodeStub(Assembler* assembler) {
  __ Comment("InvokeDartCodeStub");
  __ EnterFrame(0);

  // The new context, saved vm tag, the top exit frame, and the old context.
  // const intptr_t kPreservedContextSlots = 4;
  const intptr_t kNewContextOffsetFromFp =
      -(1 + kAbiPreservedCpuRegCount) * kWordSize;
  // const intptr_t kPreservedRegSpace =
  //     kWordSize * (kAbiPreservedCpuRegCount + kPreservedContextSlots);

  // Save the callee-saved registers.
  for (int i = R19; i <= R28; i++) {
    const Register r = static_cast<Register>(i);
    // We use str instead of the Push macro because we will be pushing the PP
    // register when it is not holding a pool-pointer since we are coming from
    // C++ code.
    __ str(r, Address(SP, -1 * kWordSize, Address::PreIndex));
  }

  // TODO(zra): Save the bottom 64-bits of callee-saved floating point
  // registers.

  // Push new context.
  __ Push(R3);

  // We now load the pool pointer(PP) as we are about to invoke dart code and we
  // could potentially invoke some intrinsic functions which need the PP to be
  // set up.
  __ LoadPoolPointer(PP);

  // The new Context structure contains a pointer to the current Isolate
  // structure. Cache the Context pointer in the CTX register so that it is
  // available in generated code and calls to Isolate::Current() need not be
  // done. The assumption is that this register will never be clobbered by
  // compiled or runtime stub code.

  // Cache the new Context pointer into CTX while executing Dart code.
  __ LoadFromOffset(CTX, R3, VMHandles::kOffsetOfRawPtrInHandle);

  // Load Isolate pointer from Context structure into temporary register R4.
  __ LoadFieldFromOffset(R5, CTX, Context::isolate_offset());

  // Save the current VMTag on the stack.
  ASSERT(kSavedVMTagSlotFromEntryFp == -12);
  __ LoadFromOffset(R4, R5, Isolate::vm_tag_offset());
  __ Push(R4);

  // Mark that the isolate is executing Dart code.
  __ LoadImmediate(R6, VMTag::kScriptTagId, PP);
  __ StoreToOffset(R6, R5, Isolate::vm_tag_offset());

  // Save the top exit frame info. Use R6 as a temporary register.
  // StackFrameIterator reads the top exit frame info saved in this frame.
  __ LoadFromOffset(R6, R5, Isolate::top_exit_frame_info_offset());
  __ StoreToOffset(ZR, R5, Isolate::top_exit_frame_info_offset());

  // Save the old Context pointer. Use R4 as a temporary register.
  // Note that VisitObjectPointers will find this saved Context pointer during
  // GC marking, since it traverses any information between SP and
  // FP - kExitLinkSlotFromEntryFp.
  // EntryFrame::SavedContext reads the context saved in this frame.
  __ LoadFromOffset(R4, R5, Isolate::top_context_offset());

  // The constants kSavedContextSlotFromEntryFp and
  // kExitLinkSlotFromEntryFp must be kept in sync with the code below.
  ASSERT(kExitLinkSlotFromEntryFp == -13);
  ASSERT(kSavedContextSlotFromEntryFp == -14);
  __ Push(R6);
  __ Push(R4);

  // Load arguments descriptor array into R4, which is passed to Dart code.
  __ LoadFromOffset(R4, R1, VMHandles::kOffsetOfRawPtrInHandle);

  // Load number of arguments into S5.
  __ LoadFieldFromOffset(R5, R4, ArgumentsDescriptor::count_offset());
  __ SmiUntag(R5);

  // Compute address of 'arguments array' data area into R2.
  __ LoadFromOffset(R2, R2, VMHandles::kOffsetOfRawPtrInHandle);
  __ AddImmediate(R2, R2, Array::data_offset() - kHeapObjectTag, PP);

  // Set up arguments for the Dart call.
  Label push_arguments;
  Label done_push_arguments;
  __ cmp(R5, Operand(0));
  __ b(&done_push_arguments, EQ);  // check if there are arguments.
  __ LoadImmediate(R1, 0, PP);
  __ Bind(&push_arguments);
  __ ldr(R3, Address(R2));
  __ Push(R3);
  __ add(R1, R1, Operand(1));
  __ add(R2, R2, Operand(kWordSize));
  __ cmp(R1, Operand(R5));
  __ b(&push_arguments, LT);
  __ Bind(&done_push_arguments);

  // Call the Dart code entrypoint.
  __ blr(R0);  // R4 is the arguments descriptor array.
  __ Comment("InvokeDartCodeStub return");

  // Read the saved new Context pointer.
  __ LoadFromOffset(CTX, FP, kNewContextOffsetFromFp);
  __ LoadFromOffset(CTX, CTX, VMHandles::kOffsetOfRawPtrInHandle);

  // Get rid of arguments pushed on the stack.
  __ AddImmediate(SP, FP, kSavedContextSlotFromEntryFp * kWordSize, PP);

  // Load Isolate pointer from Context structure into CTX. Drop Context.
  __ LoadFieldFromOffset(CTX, CTX, Context::isolate_offset());

  // Restore the current VMTag from the stack.
  __ ldr(R4, Address(SP, 2 * kWordSize));
  __ StoreToOffset(R4, CTX, Isolate::vm_tag_offset());

  // Restore the saved Context pointer into the Isolate structure.
  // Uses R4 as a temporary register for this.
  // Restore the saved top exit frame info back into the Isolate structure.
  // Uses R6 as a temporary register for this.
  __ Pop(R4);
  __ Pop(R6);
  __ StoreToOffset(R4, CTX, Isolate::top_context_offset());
  __ StoreToOffset(R6, CTX, Isolate::top_exit_frame_info_offset());

  __ Pop(R3);
  __ Pop(R4);

  // Restore C++ ABI callee-saved registers.
  for (int i = R28; i >= R19; i--) {
    Register r = static_cast<Register>(i);
    // We use ldr instead of the Pop macro because we will be popping the PP
    // register when it is not holding a pool-pointer since we are returning to
    // C++ code.
    __ ldr(r, Address(SP, 1 * kWordSize, Address::PostIndex));
  }

  // TODO(zra): Restore callee-saved fpu registers.

  // Restore the frame pointer and return.
  __ LeaveFrame();
  __ ret();
}


void StubCode::GenerateAllocateContextStub(Assembler* assembler) {
  __ Stop("GenerateAllocateContextStub");
}


DECLARE_LEAF_RUNTIME_ENTRY(void, StoreBufferBlockProcess, Isolate* isolate);

// Helper stub to implement Assembler::StoreIntoObject.
// Input parameters:
//   R0: Address being stored
void StubCode::GenerateUpdateStoreBufferStub(Assembler* assembler) {
  Label add_to_buffer;
  // Check whether this object has already been remembered. Skip adding to the
  // store buffer if the object is in the store buffer already.
  __ LoadFieldFromOffset(TMP, R0, Object::tags_offset());
  __ tsti(TMP, 1 << RawObject::kRememberedBit);
  __ b(&add_to_buffer, EQ);
  __ ret();

  __ Bind(&add_to_buffer);
  // Save values being destroyed.
  __ Push(R1);
  __ Push(R2);
  __ Push(R3);

  __ orri(R2, TMP, 1 << RawObject::kRememberedBit);
  __ StoreFieldToOffset(R2, R0, Object::tags_offset());

  // Load the isolate out of the context.
  // Spilled: R1, R2, R3.
  // R0: address being stored.
  __ LoadFieldFromOffset(R1, CTX, Context::isolate_offset());

  // Load the StoreBuffer block out of the isolate. Then load top_ out of the
  // StoreBufferBlock and add the address to the pointers_.
  // R1: isolate.
  __ LoadFromOffset(R1, R1, Isolate::store_buffer_offset());
  __ LoadFromOffset(R2, R1, StoreBufferBlock::top_offset());
  __ add(R3, R1, Operand(R2, LSL, 3));
  __ StoreToOffset(R0, R3, StoreBufferBlock::pointers_offset());

  // Increment top_ and check for overflow.
  // R2: top_.
  // R1: StoreBufferBlock.
  Label L;
  __ add(R2, R2, Operand(1));
  __ StoreToOffset(R2, R1, StoreBufferBlock::top_offset());
  __ CompareImmediate(R2, StoreBufferBlock::kSize, PP);
  // Restore values.
  __ Pop(R3);
  __ Pop(R2);
  __ Pop(R1);
  __ b(&L, EQ);
  __ ret();

  // Handle overflow: Call the runtime leaf function.
  __ Bind(&L);
  // Setup frame, push callee-saved registers.

  __ EnterCallRuntimeFrame(0 * kWordSize);
  __ LoadFieldFromOffset(R0, CTX, Context::isolate_offset());
  __ CallRuntime(kStoreBufferBlockProcessRuntimeEntry, 1);
  // Restore callee-saved registers, tear down frame.
  __ LeaveCallRuntimeFrame();
  __ ret();
}


void StubCode::GenerateAllocationStubForClass(Assembler* assembler,
                                              const Class& cls) {
  __ Stop("GenerateAllocationStubForClass");
}


void StubCode::GenerateCallNoSuchMethodFunctionStub(Assembler* assembler) {
  __ Stop("GenerateCallNoSuchMethodFunctionStub");
}


void StubCode::GenerateOptimizedUsageCounterIncrement(Assembler* assembler) {
  __ Stop("GenerateOptimizedUsageCounterIncrement");
}


void StubCode::GenerateUsageCounterIncrement(Assembler* assembler,
                                             Register temp_reg) {
  __ Stop("GenerateUsageCounterIncrement");
}


void StubCode::GenerateNArgsCheckInlineCacheStub(
    Assembler* assembler,
    intptr_t num_args,
    const RuntimeEntry& handle_ic_miss) {
  __ Stop("GenerateNArgsCheckInlineCacheStub");
}


void StubCode::GenerateOneArgCheckInlineCacheStub(Assembler* assembler) {
  __ Stop("GenerateOneArgCheckInlineCacheStub");
}


void StubCode::GenerateTwoArgsCheckInlineCacheStub(Assembler* assembler) {
  __ Stop("GenerateTwoArgsCheckInlineCacheStub");
}


void StubCode::GenerateThreeArgsCheckInlineCacheStub(Assembler* assembler) {
  __ Stop("GenerateThreeArgsCheckInlineCacheStub");
}


void StubCode::GenerateOneArgOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  __ Stop("GenerateOneArgOptimizedCheckInlineCacheStub");
}


void StubCode::GenerateTwoArgsOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  __ Stop("GenerateTwoArgsOptimizedCheckInlineCacheStub");
}


void StubCode::GenerateThreeArgsOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  __ Stop("GenerateThreeArgsOptimizedCheckInlineCacheStub");
}


void StubCode::GenerateClosureCallInlineCacheStub(Assembler* assembler) {
  __ Stop("GenerateClosureCallInlineCacheStub");
}


void StubCode::GenerateMegamorphicCallStub(Assembler* assembler) {
  __ Stop("GenerateMegamorphicCallStub");
}


void StubCode::GenerateZeroArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  __ Stop("GenerateZeroArgsUnoptimizedStaticCallStub");
}


void StubCode::GenerateTwoArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  __ Stop("GenerateTwoArgsUnoptimizedStaticCallStub");
}


void StubCode::GenerateLazyCompileStub(Assembler* assembler) {
  __ Stop("GenerateLazyCompileStub");
}


void StubCode::GenerateBreakpointRuntimeStub(Assembler* assembler) {
  __ Stop("GenerateBreakpointRuntimeStub");
}


void StubCode::GenerateDebugStepCheckStub(Assembler* assembler) {
  __ Stop("GenerateDebugStepCheckStub");
}


void StubCode::GenerateSubtype1TestCacheStub(Assembler* assembler) {
  __ Stop("GenerateSubtype1TestCacheStub");
}


void StubCode::GenerateSubtype2TestCacheStub(Assembler* assembler) {
  __ Stop("GenerateSubtype2TestCacheStub");
}


void StubCode::GenerateSubtype3TestCacheStub(Assembler* assembler) {
  __ Stop("GenerateSubtype3TestCacheStub");
}


void StubCode::GenerateGetStackPointerStub(Assembler* assembler) {
  __ Stop("GenerateGetStackPointerStub");
}


void StubCode::GenerateJumpToExceptionHandlerStub(Assembler* assembler) {
  __ Stop("GenerateJumpToExceptionHandlerStub");
}


void StubCode::GenerateOptimizeFunctionStub(Assembler* assembler) {
  __ Stop("GenerateOptimizeFunctionStub");
}


void StubCode::GenerateIdenticalWithNumberCheckStub(Assembler* assembler,
                                                    const Register left,
                                                    const Register right,
                                                    const Register temp,
                                                    const Register unused) {
  __ Stop("GenerateIdenticalWithNumberCheckStub");
}


void StubCode::GenerateUnoptimizedIdenticalWithNumberCheckStub(
    Assembler* assembler) {
  __ Stop("GenerateUnoptimizedIdenticalWithNumberCheckStub");
}


void StubCode::GenerateOptimizedIdenticalWithNumberCheckStub(
    Assembler* assembler) {
  __ Stop("GenerateOptimizedIdenticalWithNumberCheckStub");
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
