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

DEFINE_FLAG(bool, inline_alloc, true, "Inline allocation of objects.");
DEFINE_FLAG(bool, use_slow_path, false,
    "Set to true for debugging & verifying the slow paths.");

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
  __ mov(TMP, SP);  // Can't directly store SP.
  __ StoreToOffset(TMP, R0, Isolate::top_exit_frame_info_offset());

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


// Input parameters:
//   LR : return address.
//   SP : address of return value.
//   R5 : address of the native function to call.
//   R2 : address of first argument in argument array.
//   R1 : argc_tag including number of arguments and function kind.
void StubCode::GenerateCallNativeCFunctionStub(Assembler* assembler) {
  const intptr_t isolate_offset = NativeArguments::isolate_offset();
  const intptr_t argc_tag_offset = NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = NativeArguments::argv_offset();
  const intptr_t retval_offset = NativeArguments::retval_offset();

  __ EnterFrame(0);

  // Load current Isolate pointer from Context structure into R0.
  __ LoadFieldFromOffset(R0, CTX, Context::isolate_offset());

  // Save exit frame information to enable stack walking as we are about
  // to transition to native code.
  __ StoreToOffset(SP, R0, Isolate::top_exit_frame_info_offset());

  // Save current Context pointer into Isolate structure.
  __ StoreToOffset(CTX, R0, Isolate::top_context_offset());

  // Cache Isolate pointer into CTX while executing native code.
  __ mov(CTX, R0);

#if defined(DEBUG)
  { Label ok;
    // Check that we are always entering from Dart code.
    __ LoadFromOffset(R6, CTX, Isolate::vm_tag_offset());
    __ CompareImmediate(R6, VMTag::kScriptTagId, PP);
    __ b(&ok, EQ);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the isolate is executing Native code.
  __ StoreToOffset(R5, CTX, Isolate::vm_tag_offset());

  // Reserve space for the native arguments structure passed on the stack (the
  // outgoing pointer parameter to the native arguments structure is passed in
  // R0) and align frame before entering the C++ world.
  __ ReserveAlignedFrameSpace(sizeof(NativeArguments));

  // Initialize NativeArguments structure and call native function.
  // Registers R0, R1, R2, and R3 are used.

  ASSERT(isolate_offset == 0 * kWordSize);
  // Set isolate in NativeArgs: R0 already contains CTX.

  // There are no native calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * kWordSize);
  // Set argc in NativeArguments: R1 already contains argc.

  ASSERT(argv_offset == 2 * kWordSize);
  // Set argv in NativeArguments: R2 already contains argv.

  // Set retval in NativeArgs.
  ASSERT(retval_offset == 3 * kWordSize);
  __ AddImmediate(R3, FP, 2 * kWordSize, PP);

  // TODO(regis): Should we pass the structure by value as in runtime calls?
  // It would require changing Dart API for native functions.
  // For now, space is reserved on the stack and we pass a pointer to it.
  __ StoreToOffset(R0, SP, isolate_offset);
  __ StoreToOffset(R1, SP, argc_tag_offset);
  __ StoreToOffset(R2, SP, argv_offset);
  __ StoreToOffset(R3, SP, retval_offset);
  __ mov(R0, SP);  // Pass the pointer to the NativeArguments.

  // Call native function (setsup scope if not leaf function).
  Label leaf_call;
  Label done;
  __ TestImmediate(R1, NativeArguments::AutoSetupScopeMask(), PP);
  __ b(&leaf_call, EQ);

  __ mov(R1, R5);  // Pass the function entrypoint to call.
  // Call native function invocation wrapper or redirection via simulator.
#if defined(USING_SIMULATOR)
  uword entry = reinterpret_cast<uword>(NativeEntry::NativeCallWrapper);
  entry = Simulator::RedirectExternalReference(
      entry, Simulator::kNativeCall, NativeEntry::kNumCallWrapperArguments);
  __ LoadImmediate(R2, entry, PP);
  __ blr(R2);
#else
  __ BranchLink(&NativeEntry::NativeCallWrapperLabel());
#endif
  __ b(&done);

  __ Bind(&leaf_call);
  // Call native function or redirection via simulator.
  __ blr(R5);

  __ Bind(&done);

  // Mark that the isolate is executing Dart code.
  __ LoadImmediate(R2, VMTag::kScriptTagId, PP);
  __ StoreToOffset(R2, CTX, Isolate::vm_tag_offset());

  // Reset exit frame information in Isolate structure.
  __ LoadImmediate(R2, 0, PP);
  __ StoreToOffset(R2, CTX, Isolate::top_exit_frame_info_offset());

  // Load Context pointer from Isolate structure into R2.
  __ LoadFromOffset(R2, CTX, Isolate::top_context_offset());

  // Reset Context pointer in Isolate structure.
  __ LoadObject(R3, Object::null_object(), PP);
  __ StoreToOffset(R3, CTX, Isolate::top_context_offset());

  // Cache Context pointer into CTX while executing Dart code.
  __ mov(CTX, R2);

  __ LeaveFrame();
  __ ret();
}


// Input parameters:
//   LR : return address.
//   SP : address of return value.
//   R5 : address of the native function to call.
//   R2 : address of first argument in argument array.
//   R1 : argc_tag including number of arguments and function kind.
void StubCode::GenerateCallBootstrapCFunctionStub(Assembler* assembler) {
  const intptr_t isolate_offset = NativeArguments::isolate_offset();
  const intptr_t argc_tag_offset = NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = NativeArguments::argv_offset();
  const intptr_t retval_offset = NativeArguments::retval_offset();

  __ EnterFrame(0);

  // Load current Isolate pointer from Context structure into R0.
  __ LoadFieldFromOffset(R0, CTX, Context::isolate_offset());

  // Save exit frame information to enable stack walking as we are about
  // to transition to native code.
  __ mov(TMP, SP);  // Can't store SP directly, first copy to TMP.
  __ StoreToOffset(TMP, R0, Isolate::top_exit_frame_info_offset());

  // Save current Context pointer into Isolate structure.
  __ StoreToOffset(CTX, R0, Isolate::top_context_offset());

  // Cache Isolate pointer into CTX while executing native code.
  __ mov(CTX, R0);

#if defined(DEBUG)
  { Label ok;
    // Check that we are always entering from Dart code.
    __ LoadFromOffset(R6, CTX, Isolate::vm_tag_offset());
    __ CompareImmediate(R6, VMTag::kScriptTagId, PP);
    __ b(&ok, EQ);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the isolate is executing Native code.
  __ StoreToOffset(R5, CTX, Isolate::vm_tag_offset());

  // Reserve space for the native arguments structure passed on the stack (the
  // outgoing pointer parameter to the native arguments structure is passed in
  // R0) and align frame before entering the C++ world.
  __ ReserveAlignedFrameSpace(sizeof(NativeArguments));

  // Initialize NativeArguments structure and call native function.
  // Registers R0, R1, R2, and R3 are used.

  ASSERT(isolate_offset == 0 * kWordSize);
  // Set isolate in NativeArgs: R0 already contains CTX.

  // There are no native calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * kWordSize);
  // Set argc in NativeArguments: R1 already contains argc.

  ASSERT(argv_offset == 2 * kWordSize);
  // Set argv in NativeArguments: R2 already contains argv.

  // Set retval in NativeArgs.
  ASSERT(retval_offset == 3 * kWordSize);
  __ AddImmediate(R3, FP, 2 * kWordSize, PP);

  // TODO(regis): Should we pass the structure by value as in runtime calls?
  // It would require changing Dart API for native functions.
  // For now, space is reserved on the stack and we pass a pointer to it.
  __ StoreToOffset(R0, SP, isolate_offset);
  __ StoreToOffset(R1, SP, argc_tag_offset);
  __ StoreToOffset(R2, SP, argv_offset);
  __ StoreToOffset(R3, SP, retval_offset);
  __ mov(R0, SP);  // Pass the pointer to the NativeArguments.

  // Call native function or redirection via simulator.
  __ blr(R5);

  // Mark that the isolate is executing Dart code.
  __ LoadImmediate(R2, VMTag::kScriptTagId, PP);
  __ StoreToOffset(R2, CTX, Isolate::vm_tag_offset());

  // Reset exit frame information in Isolate structure.
  __ LoadImmediate(R2, 0, PP);
  __ StoreToOffset(R2, CTX, Isolate::top_exit_frame_info_offset());

  // Load Context pointer from Isolate structure into R2.
  __ LoadFromOffset(R2, CTX, Isolate::top_context_offset());

  // Reset Context pointer in Isolate structure.
  __ LoadObject(R3, Object::null_object(), PP);
  __ StoreToOffset(R3, CTX, Isolate::top_context_offset());

  // Cache Context pointer into CTX while executing Dart code.
  __ mov(CTX, R2);

  __ LeaveFrame();
  __ ret();
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


// Called for inline allocation of objects.
// Input parameters:
//   LR : return address.
//   SP + 0 : type arguments object (only if class is parameterized).
void StubCode::GenerateAllocationStubForClass(Assembler* assembler,
                                              const Class& cls) {
  // The generated code is different if the class is parameterized.
  const bool is_cls_parameterized = cls.NumTypeArguments() > 0;
  ASSERT(!is_cls_parameterized ||
         (cls.type_arguments_field_offset() != Class::kNoTypeArguments));
  // kInlineInstanceSize is a constant used as a threshold for determining
  // when the object initialization should be done as a loop or as
  // straight line code.
  const int kInlineInstanceSize = 12;
  const intptr_t instance_size = cls.instance_size();
  ASSERT(instance_size > 0);
  if (is_cls_parameterized) {
    __ ldr(R1, Address(SP));
    // R1: instantiated type arguments.
  }
  if (FLAG_inline_alloc && Heap::IsAllocatableInNewSpace(instance_size)) {
    Label slow_case;
    // Allocate the object and update top to point to
    // next object start and initialize the allocated object.
    // R1: instantiated type arguments (if is_cls_parameterized).
    Heap* heap = Isolate::Current()->heap();
    __ LoadImmediate(R5, heap->TopAddress(), PP);
    __ ldr(R2, Address(R5));
    __ AddImmediate(R3, R2, instance_size, PP);
    // Check if the allocation fits into the remaining space.
    // R2: potential new object start.
    // R3: potential next object start.
    __ LoadImmediate(TMP, heap->EndAddress(), PP);
    __ ldr(TMP, Address(TMP));
    __ CompareRegisters(R3, TMP);
    if (FLAG_use_slow_path) {
      __ b(&slow_case);
    } else {
      __ b(&slow_case, CS);  // Unsigned higher or equal.
    }
    __ str(R3, Address(R5));
    __ UpdateAllocationStats(cls.id(), R5);

    // R2: new object start.
    // R3: next object start.
    // R1: new object type arguments (if is_cls_parameterized).
    // Set the tags.
    uword tags = 0;
    tags = RawObject::SizeTag::update(instance_size, tags);
    ASSERT(cls.id() != kIllegalCid);
    tags = RawObject::ClassIdTag::update(cls.id(), tags);
    __ LoadImmediate(R0, tags, PP);
    __ StoreToOffset(R0, R2, Instance::tags_offset());

    // Initialize the remaining words of the object.
    __ LoadObject(R0, Object::null_object(), PP);

    // R0: raw null.
    // R2: new object start.
    // R3: next object start.
    // R1: new object type arguments (if is_cls_parameterized).
    // First try inlining the initialization without a loop.
    if (instance_size < (kInlineInstanceSize * kWordSize)) {
      // Check if the object contains any non-header fields.
      // Small objects are initialized using a consecutive set of writes.
      for (intptr_t current_offset = Instance::NextFieldOffset();
           current_offset < instance_size;
           current_offset += kWordSize) {
        __ StoreToOffset(R0, R2, current_offset);
      }
    } else {
      __ AddImmediate(R4, R2, Instance::NextFieldOffset(), PP);
      // Loop until the whole object is initialized.
      // R0: raw null.
      // R2: new object.
      // R3: next object start.
      // R4: next word to be initialized.
      // R1: new object type arguments (if is_cls_parameterized).
      Label init_loop;
      Label done;
      __ Bind(&init_loop);
      __ CompareRegisters(R4, R3);
      __ b(&done, CS);
      __ str(R0, Address(R4));
      __ AddImmediate(R4, R4, kWordSize, PP);
      __ b(&init_loop);
      __ Bind(&done);
    }
    if (is_cls_parameterized) {
      // R1: new object type arguments.
      // Set the type arguments in the new object.
      __ StoreToOffset(R1, R2, cls.type_arguments_field_offset());
    }
    // Done allocating and initializing the instance.
    // R2: new object still missing its heap tag.
    __ add(R0, R2, Operand(kHeapObjectTag));
    // R0: new object.
    __ ret();

    __ Bind(&slow_case);
  }
  // If is_cls_parameterized:
  // R1: new object type arguments.
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame(true);  // Uses pool pointer to pass cls to runtime.
  // Setup space on stack for return value.
  __ PushObject(Object::null_object(), PP);
  __ PushObject(cls, PP);  // Push class of object to be allocated.
  if (is_cls_parameterized) {
    // Push type arguments.
    __ Push(R1);
  } else {
    // Push null type arguments.
    __ Push(R2);
  }
  __ CallRuntime(kAllocateObjectRuntimeEntry, 2);  // Allocate object.
  __ Drop(2);  // Pop arguments.
  __ Pop(R0);  // Pop result (newly allocated object).
  // R0: new object
  // Restore the frame pointer.
  __ LeaveStubFrame();
  __ ret();
}


void StubCode::GenerateCallNoSuchMethodFunctionStub(Assembler* assembler) {
  __ Stop("GenerateCallNoSuchMethodFunctionStub");
}


void StubCode::GenerateOptimizedUsageCounterIncrement(Assembler* assembler) {
  __ Stop("GenerateOptimizedUsageCounterIncrement");
}


// Loads function into 'temp_reg'.
void StubCode::GenerateUsageCounterIncrement(Assembler* assembler,
                                             Register temp_reg) {
  Register ic_reg = R5;
  Register func_reg = temp_reg;
  ASSERT(temp_reg == R6);
  __ LoadFieldFromOffset(func_reg, ic_reg, ICData::function_offset());
  __ LoadFieldFromOffset(R7, func_reg, Function::usage_counter_offset());
  __ AddImmediate(R7, R7, 1, PP);
  __ StoreFieldToOffset(R7, func_reg, Function::usage_counter_offset());
}


// Generate inline cache check for 'num_args'.
//  LR: return address.
//  R5: inline cache data object.
// Control flow:
// - If receiver is null -> jump to IC miss.
// - If receiver is Smi -> load Smi class.
// - If receiver is not-Smi -> load receiver's class.
// - Check if 'num_args' (including receiver) match any IC data group.
// - Match found -> jump to target.
// - Match not found -> jump to IC miss.
void StubCode::GenerateNArgsCheckInlineCacheStub(
    Assembler* assembler,
    intptr_t num_args,
    const RuntimeEntry& handle_ic_miss) {
  ASSERT(num_args > 0);
#if defined(DEBUG)
  { Label ok;
    // Check that the IC data array has NumberOfArgumentsChecked() == num_args.
    // 'num_args_tested' is stored as an untagged int.
    __ LoadFieldFromOffset(R6, R5, ICData::num_args_tested_offset());
    __ CompareImmediate(R6, num_args, PP);
    __ b(&ok, EQ);
    __ Stop("Incorrect stub for IC data");
    __ Bind(&ok);
  }
#endif  // DEBUG

  // Check single stepping.
  Label not_stepping;
  __ LoadFieldFromOffset(R6, CTX, Context::isolate_offset());
  __ LoadFromOffset(R6, R6, Isolate::single_step_offset(), kUnsignedByte);
  __ CompareImmediate(R6, 0, PP);
  __ b(&not_stepping, EQ);
  __ EnterStubFrame();
  __ Push(R5);  // Preserve IC data.
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ Pop(R5);
  __ LeaveStubFrame();
  __ Bind(&not_stepping);

  // Load arguments descriptor into R4.
  __ LoadFieldFromOffset(R4, R5, ICData::arguments_descriptor_offset());
  // Loop that checks if there is an IC data match.
  Label loop, update, test, found, get_class_id_as_smi;
  // R5: IC data object (preserved).
  __ LoadFieldFromOffset(R6, R5, ICData::ic_data_offset());
  // R6: ic_data_array with check entries: classes and target functions.
  __ AddImmediate(R6, R6, Array::data_offset() - kHeapObjectTag, PP);
  // R6: points directly to the first ic data array element.

  // Get the receiver's class ID (first read number of arguments from
  // arguments descriptor array and then access the receiver from the stack).
  __ LoadFieldFromOffset(R7, R4, ArgumentsDescriptor::count_offset());
  __ SmiUntag(R7);  // Untag so we can use the LSL 3 addressing mode.
  __ sub(R7, R7, Operand(1));

  // R0 <- [SP + (R7 << 3)]
  __ ldr(R0, Address(SP, R7, UXTX, Address::Scaled));

  {
    // TODO(zra): Put this code in a subroutine call as with other architectures
    // when we have a bl(Label& l) instruction.
    // Instance in R0, return its class-id in R0 as Smi.
    // Test if Smi -> load Smi class for comparison.
    Label not_smi, done;
    __ tsti(R0, kSmiTagMask);
    __ b(&not_smi, NE);
    __ LoadImmediate(R0, Smi::RawValue(kSmiCid), PP);
    __ b(&done);

    __ Bind(&not_smi);
    __ LoadClassId(R0, R0);
    __ SmiTag(R0);
    __ Bind(&done);
  }

  // R7: argument_count - 1 (untagged).
  // R0: receiver's class ID (smi).
  __ ldr(R1, Address(R6));  // First class id (smi) to check.
  __ b(&test);

  __ Bind(&loop);
  for (int i = 0; i < num_args; i++) {
    if (i > 0) {
      // If not the first, load the next argument's class ID.
      __ AddImmediate(R0, R7, -i, PP);
      // R0 <- [SP + (R0 << 3)]
      __ ldr(R0, Address(SP, R0, UXTX, Address::Scaled));
      {
        // Instance in R0, return its class-id in R0 as Smi.
        // Test if Smi -> load Smi class for comparison.
        Label not_smi, done;
        __ tsti(R0, kSmiTagMask);
        __ b(&not_smi, NE);
        __ LoadImmediate(R0, Smi::RawValue(kSmiCid), PP);
        __ b(&done);

        __ Bind(&not_smi);
        __ LoadClassId(R0, R0);
        __ SmiTag(R0);
        __ Bind(&done);
      }
      // R0: next argument class ID (smi).
      __ LoadFromOffset(R1, R6, i * kWordSize);
      // R1: next class ID to check (smi).
    }
    __ CompareRegisters(R0, R1);  // Class id match?
    if (i < (num_args - 1)) {
      __ b(&update, NE);  // Continue.
    } else {
      // Last check, all checks before matched.
      __ b(&found, EQ);  // Break.
    }
  }
  __ Bind(&update);
  // Reload receiver class ID.  It has not been destroyed when num_args == 1.
  if (num_args > 1) {
    __ ldr(R0, Address(SP, R7, UXTX, Address::Scaled));
    {
      // Instance in R0, return its class-id in R0 as Smi.
      // Test if Smi -> load Smi class for comparison.
      Label not_smi, done;
      __ tsti(R0, kSmiTagMask);
      __ b(&not_smi, NE);
      __ LoadImmediate(R0, Smi::RawValue(kSmiCid), PP);
      __ b(&done);

      __ Bind(&not_smi);
      __ LoadClassId(R0, R0);
      __ SmiTag(R0);
      __ Bind(&done);
    }
  }

  const intptr_t entry_size = ICData::TestEntryLengthFor(num_args) * kWordSize;
  __ AddImmediate(R6, R6, entry_size, PP);  // Next entry.
  __ ldr(R1, Address(R6));  // Next class ID.

  __ Bind(&test);
  __ CompareImmediate(R1, Smi::RawValue(kIllegalCid), PP);  // Done?
  __ b(&loop, NE);

  // IC miss.
  // Compute address of arguments.
  // R7: argument_count - 1 (untagged).
  // R7 <- SP + (R7 << 3)
  __ add(R7, SP, Operand(R7, UXTX, 3));  // R7 is Untagged.
  // R7: address of receiver.
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ LoadObject(R0, Object::null_object(), PP);
  // Preserve IC data object and arguments descriptor array and
  // setup space on stack for result (target code object).
  __ Push(R4);  // Preserve arguments descriptor array.
  __ Push(R5);  // Preserve IC Data.
  __ Push(R0);  // Setup space on stack for the result (target code object).
  // Push call arguments.
  for (intptr_t i = 0; i < num_args; i++) {
    __ LoadFromOffset(TMP, R7, -i * kWordSize);
    __ Push(TMP);
  }
  // Pass IC data object.
  __ Push(R5);
  __ CallRuntime(handle_ic_miss, num_args + 1);
  // Remove the call arguments pushed earlier, including the IC data object.
  __ Drop(num_args + 1);
  // Pop returned function object into R0.
  // Restore arguments descriptor array and IC data array.
  __ Pop(R0);  // Pop returned function object into R0.
  __ Pop(R5);  // Restore IC Data.
  __ Pop(R4);  // Restore arguments descriptor array.
  __ LeaveStubFrame();
  Label call_target_function;
  __ b(&call_target_function);

  __ Bind(&found);
  // R6: pointer to an IC data check group.
  const intptr_t target_offset = ICData::TargetIndexFor(num_args) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(num_args) * kWordSize;
  __ LoadFromOffset(R0, R6, target_offset);
  __ LoadFromOffset(R1, R6, count_offset);
  __ adds(R1, R1, Operand(Smi::RawValue(1)));
  __ StoreToOffset(R1, R6, count_offset);
  __ b(&call_target_function, VC);  // No overflow.
  __ LoadImmediate(R1, Smi::RawValue(Smi::kMaxValue), PP);
  __ StoreToOffset(R1, R6, count_offset);

  __ Bind(&call_target_function);
  // R0: target function.
  __ LoadFieldFromOffset(R2, R0, Function::code_offset());
  __ LoadFieldFromOffset(R2, R2, Code::instructions_offset());
  __ AddImmediate(R2, R2, Instructions::HeaderSize() - kHeapObjectTag, PP);
  __ br(R2);
}


// Use inline cache data array to invoke the target or continue in inline
// cache miss handler. Stub for 1-argument check (receiver class).
//  LR: return address.
//  R5: inline cache data object.
// Inline cache data object structure:
// 0: function-name
// 1: N, number of arguments checked.
// 2 .. (length - 1): group of checks, each check containing:
//   - N classes.
//   - 1 target function.
void StubCode::GenerateOneArgCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kInlineCacheMissHandlerOneArgRuntimeEntry);
}


void StubCode::GenerateTwoArgsCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry);
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
  GenerateUsageCounterIncrement(assembler, R6);
#if defined(DEBUG)
  { Label ok;
    // Check that the IC data array has NumberOfArgumentsChecked() == 0.
    // 'num_args_tested' is stored as an untagged int.
    __ LoadFieldFromOffset(R6, R5, ICData::num_args_tested_offset());
    __ CompareImmediate(R6, 0, PP);
    __ b(&ok, EQ);
    __ Stop("Incorrect IC data for unoptimized static call");
    __ Bind(&ok);
  }
#endif  // DEBUG

  // Check single stepping.
  Label not_stepping;
  __ LoadFieldFromOffset(R6, CTX, Context::isolate_offset());
  __ LoadFromOffset(R6, R6, Isolate::single_step_offset(), kUnsignedByte);
  __ CompareImmediate(R6, 0, PP);
  __ b(&not_stepping, EQ);
  __ EnterStubFrame();
  __ Push(R5);  // Preserve IC data.
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ Pop(R5);
  __ LeaveStubFrame();
  __ Bind(&not_stepping);

  // R5: IC data object (preserved).
  __ LoadFieldFromOffset(R6, R5, ICData::ic_data_offset());
  // R6: ic_data_array with entries: target functions and count.
  __ AddImmediate(R6, R6, Array::data_offset() - kHeapObjectTag, PP);
  // R6: points directly to the first ic data array element.
  const intptr_t target_offset = ICData::TargetIndexFor(0) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(0) * kWordSize;

  // Increment count for this call.
  Label increment_done;
  __ LoadFromOffset(R1, R6, count_offset);
  __ adds(R1, R1, Operand(Smi::RawValue(1)));
  __ StoreToOffset(R1, R6, count_offset);
  __ b(&increment_done, VC);  // No overflow.
  __ LoadImmediate(R1, Smi::RawValue(Smi::kMaxValue), PP);
  __ StoreToOffset(R1, R6, count_offset);
  __ Bind(&increment_done);

  // Load arguments descriptor into R4.
  __ LoadFieldFromOffset(R4, R5, ICData::arguments_descriptor_offset());

  // Get function and call it, if possible.
  __ LoadFromOffset(R0, R6, target_offset);
  __ LoadFieldFromOffset(R2, R0, Function::code_offset());

  // R0: function.
  // R2: target code.
  __ LoadFieldFromOffset(R2, R2, Code::instructions_offset());
  __ AddImmediate(R2, R2, Instructions::HeaderSize() - kHeapObjectTag, PP);
  __ br(R2);
}


void StubCode::GenerateTwoArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  __ Stop("GenerateTwoArgsUnoptimizedStaticCallStub");
}


// Stub for compiling a function and jumping to the compiled code.
// R5: IC-Data (for methods).
// R4: Arguments descriptor.
// R0: Function.
void StubCode::GenerateLazyCompileStub(Assembler* assembler) {
  // Preserve arg desc. and IC data object.
  __ EnterStubFrame();
  __ Push(R5);  // Save IC Data.
  __ Push(R4);  // Save arg. desc.
  __ Push(R0);  // Pass function.
  __ CallRuntime(kCompileFunctionRuntimeEntry, 1);
  __ Pop(R0);  // Restore argument.
  __ Pop(R4);  // Restore arg desc.
  __ Pop(R5);  // Restore IC Data.
  __ LeaveStubFrame();

  __ LoadFieldFromOffset(R2, R0, Function::code_offset());
  __ LoadFieldFromOffset(R2, R2, Code::instructions_offset());
  __ AddImmediate(R2, R2, Instructions::HeaderSize() - kHeapObjectTag, PP);
  __ br(R2);
}


void StubCode::GenerateBreakpointRuntimeStub(Assembler* assembler) {
  __ Stop("GenerateBreakpointRuntimeStub");
}


// Called only from unoptimized code. All relevant registers have been saved.
void StubCode::GenerateDebugStepCheckStub(
    Assembler* assembler) {
  // Check single stepping.
  Label not_stepping;
  __ LoadFieldFromOffset(R1, CTX, Context::isolate_offset());
  __ LoadFromOffset(R1, R1, Isolate::single_step_offset(), kUnsignedByte);
  __ CompareImmediate(R1, 0, PP);
  __ b(&not_stepping, EQ);
  __ EnterStubFrame();
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ LeaveStubFrame();
  __ Bind(&not_stepping);
  __ ret();
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


DECLARE_LEAF_RUNTIME_ENTRY(intptr_t,
                           BigintCompare,
                           RawBigint* left,
                           RawBigint* right);


// Does identical check (object references are equal or not equal) with special
// checks for boxed numbers.
// Left and right are pushed on stack.
// Return Zero condition flag set if equal.
// Note: A Mint cannot contain a value that would fit in Smi, a Bigint
// cannot contain a value that fits in Mint or Smi.
void StubCode::GenerateIdenticalWithNumberCheckStub(Assembler* assembler,
                                                    const Register left,
                                                    const Register right,
                                                    const Register unused1,
                                                    const Register unused2) {
  Label reference_compare, done, check_mint, check_bigint;
  // If any of the arguments is Smi do reference compare.
  __ tsti(left, kSmiTagMask);
  __ b(&reference_compare, EQ);
  __ tsti(right, kSmiTagMask);
  __ b(&reference_compare, EQ);

  // Value compare for two doubles.
  __ CompareClassId(left, kDoubleCid);
  __ b(&check_mint, NE);
  __ CompareClassId(right, kDoubleCid);
  __ b(&done, NE);

  // Double values bitwise compare.
  __ LoadFieldFromOffset(left, left, Double::value_offset());
  __ LoadFieldFromOffset(right, right, Double::value_offset());
  __ CompareRegisters(left, right);
  __ b(&done);

  __ Bind(&check_mint);
  __ CompareClassId(left, kMintCid);
  __ b(&check_bigint, NE);
  __ CompareClassId(right, kMintCid);
  __ b(&done, NE);
  __ LoadFieldFromOffset(left, left, Mint::value_offset());
  __ LoadFieldFromOffset(right, right, Mint::value_offset());
  __ b(&done);

  __ Bind(&check_bigint);
  __ CompareClassId(left, kBigintCid);
  __ b(&reference_compare, NE);
  __ CompareClassId(right, kBigintCid);
  __ b(&done, NE);
  __ EnterFrame(0);
  __ ReserveAlignedFrameSpace(2 * kWordSize);
  __ StoreToOffset(left, SP, 0 * kWordSize);
  __ StoreToOffset(right, SP, 1 * kWordSize);
  __ CallRuntime(kBigintCompareRuntimeEntry, 2);
  // Result in R0, 0 means equal.
  __ LeaveFrame();
  __ cmp(R0, Operand(0));
  __ b(&done);

  __ Bind(&reference_compare);
  __ CompareRegisters(left, right);
  __ Bind(&done);
}


// Called only from unoptimized code. All relevant registers have been saved.
// LR: return address.
// SP + 4: left operand.
// SP + 0: right operand.
// Return Zero condition flag set if equal.
void StubCode::GenerateUnoptimizedIdenticalWithNumberCheckStub(
    Assembler* assembler) {
  // Check single stepping.
  Label not_stepping;
  __ LoadFieldFromOffset(R1, CTX, Context::isolate_offset());
  __ LoadFromOffset(R1, R1, Isolate::single_step_offset(), kUnsignedByte);
  __ CompareImmediate(R1, 0, PP);
  __ b(&not_stepping, EQ);
  __ EnterStubFrame();
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ LeaveStubFrame();
  __ Bind(&not_stepping);

  const Register left = R1;
  const Register right = R0;
  __ LoadFromOffset(left, SP, 1 * kWordSize);
  __ LoadFromOffset(right, SP, 0 * kWordSize);
  GenerateIdenticalWithNumberCheckStub(assembler, left, right);
  __ ret();
}


void StubCode::GenerateOptimizedIdenticalWithNumberCheckStub(
    Assembler* assembler) {
  __ Stop("GenerateOptimizedIdenticalWithNumberCheckStub");
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
