// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

#include "vm/assembler.h"
#include "vm/code_generator.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph_compiler.h"
#include "vm/instructions.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"

#define __ assembler->

namespace dart {

DEFINE_FLAG(bool, inline_alloc, true, "Inline allocation of objects.");
DEFINE_FLAG(bool, use_slow_path, false,
    "Set to true for debugging & verifying the slow paths.");
DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(bool, trace_optimized_ic_calls);


// Input parameters:
//   RA : return address.
//   SP : address of last argument in argument array.
//   SP + 4*S4 - 4 : address of first argument in argument array.
//   SP + 4*S4 : address of return value.
//   S5 : address of the runtime function to call.
//   S4 : number of arguments to the call.
void StubCode::GenerateCallToRuntimeStub(Assembler* assembler) {
  const intptr_t isolate_offset = NativeArguments::isolate_offset();
  const intptr_t argc_tag_offset = NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = NativeArguments::argv_offset();
  const intptr_t retval_offset = NativeArguments::retval_offset();

  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(RA, Address(SP, 1 * kWordSize));
  __ sw(FP, Address(SP, 0 * kWordSize));
  __ mov(FP, SP);

  // Load current Isolate pointer from Context structure into R0.
  __ lw(A0, FieldAddress(CTX, Context::isolate_offset()));

  // Save exit frame information to enable stack walking as we are about
  // to transition to Dart VM C++ code.
  __ sw(SP, Address(A0, Isolate::top_exit_frame_info_offset()));

  // Save current Context pointer into Isolate structure.
  __ sw(CTX, Address(A0, Isolate::top_context_offset()));

  // Cache Isolate pointer into CTX while executing runtime code.
  __ mov(CTX, A0);

  // Reserve space for arguments and align frame before entering C++ world.
  // NativeArguments are passed in registers.
  ASSERT(sizeof(NativeArguments) == 4 * kWordSize);
  __ ReserveAlignedFrameSpace(0);

  // Pass NativeArguments structure by value and call runtime.
  // Registers A0, A1, A2, and A3 are used.

  ASSERT(isolate_offset == 0 * kWordSize);
  // Set isolate in NativeArgs: A0 already contains CTX.

  // There are no runtime calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * kWordSize);
  __ mov(A1, S4);  // Set argc in NativeArguments.

  ASSERT(argv_offset == 2 * kWordSize);
  __ sll(A2, S4, 2);
  __ addu(A2, FP, A2);  // Compute argv.
  __ addiu(A2, A2, Immediate(kWordSize));  // Set argv in NativeArguments.

  ASSERT(retval_offset == 3 * kWordSize);
  __ addiu(A3, A2, Immediate(kWordSize));  // Retval is next to 1st argument.

  // Call runtime or redirection via simulator.
  __ jalr(S5);

  // Reset exit frame information in Isolate structure.
  __ sw(ZR, Address(CTX, Isolate::top_exit_frame_info_offset()));

  // Load Context pointer from Isolate structure into A2.
  __ lw(A2, Address(CTX, Isolate::top_context_offset()));

  // Reset Context pointer in Isolate structure.
  __ LoadImmediate(A3, reinterpret_cast<intptr_t>(Object::null()));
  __ sw(A3, Address(CTX, Isolate::top_context_offset()));

  // Cache Context pointer into CTX while executing Dart code.
  __ mov(CTX, A2);

  __ mov(SP, FP);
  __ lw(RA, Address(SP, 1 * kWordSize));
  __ lw(FP, Address(SP, 0 * kWordSize));
  __ Ret();
  __ delay_slot()->addiu(SP, SP, Immediate(2 * kWordSize));
}


void StubCode::GeneratePrintStopMessageStub(Assembler* assembler) {
  __ Unimplemented("PrintStopMessage stub");
}


// Input parameters:
//   RA : return address.
//   SP : address of return value.
//   T5 : address of the native function to call.
//   A2 : address of first argument in argument array.
//   A1 : argc_tag including number of arguments and function kind.
void StubCode::GenerateCallNativeCFunctionStub(Assembler* assembler) {
  const intptr_t isolate_offset = NativeArguments::isolate_offset();
  const intptr_t argc_tag_offset = NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = NativeArguments::argv_offset();
  const intptr_t retval_offset = NativeArguments::retval_offset();

  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(RA, Address(SP, 1 * kWordSize));
  __ sw(FP, Address(SP, 0 * kWordSize));
  __ mov(FP, SP);

  // Load current Isolate pointer from Context structure into A0.
  __ lw(A0, FieldAddress(CTX, Context::isolate_offset()));

  // Save exit frame information to enable stack walking as we are about
  // to transition to native code.
  __ sw(SP, Address(A0, Isolate::top_exit_frame_info_offset()));

  // Save current Context pointer into Isolate structure.
  __ sw(CTX, Address(A0, Isolate::top_context_offset()));

  // Cache Isolate pointer into CTX while executing native code.
  __ mov(CTX, A0);

  // Reserve space for the native arguments structure passed on the stack (the
  // outgoing pointer parameter to the native arguments structure is passed in
  // R0) and align frame before entering the C++ world.
  __ ReserveAlignedFrameSpace(sizeof(NativeArguments));

  // Initialize NativeArguments structure and call native function.
  // Registers A0, A1, A2, and A3 are used.

  ASSERT(isolate_offset == 0 * kWordSize);
  // Set isolate in NativeArgs: A0 already contains CTX.

  // There are no native calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * kWordSize);
  // Set argc in NativeArguments: T1 already contains argc.

  ASSERT(argv_offset == 2 * kWordSize);
  // Set argv in NativeArguments: T2 already contains argv.

  ASSERT(retval_offset == 3 * kWordSize);
  __ addiu(A3, FP, Immediate(2 * kWordSize));  // Set retval in NativeArgs.

  // TODO(regis): Should we pass the structure by value as in runtime calls?
  // It would require changing Dart API for native functions.
  // For now, space is reserved on the stack and we pass a pointer to it.
  __ addiu(SP, SP, Immediate(-4 * kWordSize));
  __ sw(A3, Address(SP, 3 * kWordSize));
  __ sw(A2, Address(SP, 2 * kWordSize));
  __ sw(A1, Address(SP, 1 * kWordSize));
  __ sw(A0, Address(SP, 0 * kWordSize));

  __ mov(A0, SP);  // Pass the pointer to the NativeArguments.

  // Call native function or redirection via simulator.
  __ jalr(T5);

  // Reset exit frame information in Isolate structure.
  __ sw(ZR, Address(CTX, Isolate::top_exit_frame_info_offset()));

  // Load Context pointer from Isolate structure into R2.
  __ lw(A2, Address(CTX, Isolate::top_context_offset()));

  // Reset Context pointer in Isolate structure.
  __ LoadImmediate(A3, reinterpret_cast<intptr_t>(Object::null()));
  __ sw(A3, Address(CTX, Isolate::top_context_offset()));

  // Cache Context pointer into CTX while executing Dart code.
  __ mov(CTX, A2);

  __ mov(SP, FP);
  __ lw(RA, Address(SP, 1 * kWordSize));
  __ lw(FP, Address(SP, 0 * kWordSize));
  __ Ret();
  __ delay_slot()->addiu(SP, SP, Immediate(2 * kWordSize));
}


// Input parameters:
//   S4: arguments descriptor array.
void StubCode::GenerateCallStaticFunctionStub(Assembler* assembler) {
  __ EnterStubFrame();
  // Setup space on stack for return value and preserve arguments descriptor.
  __ LoadImmediate(T0, reinterpret_cast<intptr_t>(Object::null()));

  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(S4, Address(SP, 1 * kWordSize));
  __ sw(T0, Address(SP, 0 * kWordSize));

  __ CallRuntime(kPatchStaticCallRuntimeEntry);

  // Get Code object result and restore arguments descriptor array.
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ lw(S4, Address(SP, 1 * kWordSize));
  __ addiu(SP, SP, Immediate(2 * kWordSize));

  // Remove the stub frame as we are about to jump to the dart function.
  __ LeaveStubFrame();

  __ lw(T0, FieldAddress(T0, Code::instructions_offset()));
  __ AddImmediate(T0, Instructions::HeaderSize() - kHeapObjectTag);
  __ jr(T0);
}


void StubCode::GenerateFixCallersTargetStub(Assembler* assembler) {
  __ Unimplemented("FixCallersTarget stub");
}


void StubCode::GenerateInstanceFunctionLookupStub(Assembler* assembler) {
  __ Unimplemented("InstanceFunctionLookup stub");
}


void StubCode::GenerateDeoptimizeLazyStub(Assembler* assembler) {
  __ Unimplemented("DeoptimizeLazy stub");
}


void StubCode::GenerateDeoptimizeStub(Assembler* assembler) {
  __ Unimplemented("Deoptimize stub");
}


void StubCode::GenerateMegamorphicMissStub(Assembler* assembler) {
  __ Unimplemented("MegamorphicMiss stub");
}


void StubCode::GenerateAllocateArrayStub(Assembler* assembler) {
  __ Unimplemented("AllocateArray stub");
}


void StubCode::GenerateCallClosureFunctionStub(Assembler* assembler) {
  __ Unimplemented("CallClosureFunction stub");
}


// Called when invoking Dart code from C++ (VM code).
// Input parameters:
//   RA : points to return address.
//   A0 : entrypoint of the Dart function to call.
//   A1 : arguments descriptor array.
//   A2 : arguments array.
//   A3 : new context containing the current isolate pointer.
void StubCode::GenerateInvokeDartCodeStub(Assembler* assembler) {
  // Save frame pointer coming in.
  __ EnterStubFrame();

  // Save new context and C++ ABI callee-saved registers.
  const intptr_t kNewContextOffset =
      -(1 + kAbiPreservedCpuRegCount) * kWordSize;

  __ addiu(SP, SP, Immediate(-(3 + kAbiPreservedCpuRegCount) * kWordSize));
  for (int i = S0; i <= S7; i++) {
    Register r = static_cast<Register>(i);
    __ sw(r, Address(SP, (i - S0 + 3) * kWordSize));
  }
  __ sw(A3, Address(SP, 2 * kWordSize));

  // The new Context structure contains a pointer to the current Isolate
  // structure. Cache the Context pointer in the CTX register so that it is
  // available in generated code and calls to Isolate::Current() need not be
  // done. The assumption is that this register will never be clobbered by
  // compiled or runtime stub code.

  // Cache the new Context pointer into CTX while executing Dart code.
  __ lw(CTX, Address(A3, VMHandles::kOffsetOfRawPtrInHandle));

  // Load Isolate pointer from Context structure into temporary register R8.
  __ lw(T2, FieldAddress(CTX, Context::isolate_offset()));

  // Save the top exit frame info. Use T0 as a temporary register.
  // StackFrameIterator reads the top exit frame info saved in this frame.
  __ lw(T0, Address(T2, Isolate::top_exit_frame_info_offset()));
  __ sw(ZR, Address(T2, Isolate::top_exit_frame_info_offset()));

  // Save the old Context pointer. Use T1 as a temporary register.
  // Note that VisitObjectPointers will find this saved Context pointer during
  // GC marking, since it traverses any information between SP and
  // FP - kExitLinkOffsetInEntryFrame.
  // EntryFrame::SavedContext reads the context saved in this frame.
  __ lw(T1, Address(T2, Isolate::top_context_offset()));

  // The constants kSavedContextOffsetInEntryFrame and
  // kExitLinkOffsetInEntryFrame must be kept in sync with the code below.
  __ sw(T0, Address(SP, 1 * kWordSize));
  __ sw(T1, Address(SP, 0 * kWordSize));

  // after the call, The stack pointer is restored to this location.
  // Pushed A3, S0-7, S4, S5 = 11.
  const intptr_t kSavedContextOffsetInEntryFrame = -11 * kWordSize;

  // Load arguments descriptor array into S4, which is passed to Dart code.
  __ lw(S4, Address(A1, VMHandles::kOffsetOfRawPtrInHandle));

  // Load number of arguments into S5.
  __ lw(T1, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
  __ SmiUntag(T1);

  // Compute address of 'arguments array' data area into A2.
  __ lw(A2, Address(A2, VMHandles::kOffsetOfRawPtrInHandle));
  __ AddImmediate(A2, Array::data_offset() - kHeapObjectTag);

  // Set up arguments for the Dart call.
  Label push_arguments;
  Label done_push_arguments;
  __ beq(T1, ZR, &done_push_arguments);  // check if there are arguments.
  __ mov(A1, ZR);
  __ Bind(&push_arguments);
  __ lw(A3, Address(A2));
  __ Push(A3);
  __ addiu(A1, A1, Immediate(1));
  __ BranchLess(A1, T1, &push_arguments);
  __ delay_slot()->addiu(A2, A2, Immediate(kWordSize));

  __ Bind(&done_push_arguments);

  // Call the Dart code entrypoint.
  __ jalr(A0);  // S4 is the arguments descriptor array.

  // Read the saved new Context pointer.
  __ lw(CTX, Address(FP, kNewContextOffset));
  __ lw(CTX, Address(CTX, VMHandles::kOffsetOfRawPtrInHandle));

  // Get rid of arguments pushed on the stack.
  __ AddImmediate(SP, FP, kSavedContextOffsetInEntryFrame);

  // Load Isolate pointer from Context structure into CTX. Drop Context.
  __ lw(CTX, FieldAddress(CTX, Context::isolate_offset()));

  // Restore the saved Context pointer into the Isolate structure.
  // Uses T1 as a temporary register for this.
  // Restore the saved top exit frame info back into the Isolate structure.
  // Uses T0 as a temporary register for this.
  __ lw(T1, Address(SP, 0 * kWordSize));
  __ lw(T0, Address(SP, 1 * kWordSize));
  __ sw(T1, Address(CTX, Isolate::top_context_offset()));
  __ sw(T0, Address(CTX, Isolate::top_exit_frame_info_offset()));

  // Restore C++ ABI callee-saved registers.
  for (int i = S0; i <= S7; i++) {
    Register r = static_cast<Register>(i);
    __ lw(r, Address(SP, (i - S0 + 3) * kWordSize));
  }
  __ lw(A3, Address(SP));
  __ addiu(SP, SP, Immediate((3 + kAbiPreservedCpuRegCount) * kWordSize));

  // Restore the frame pointer and return.
  __ LeaveStubFrame();
  __ Ret();
}


void StubCode::GenerateAllocateContextStub(Assembler* assembler) {
  __ Unimplemented("AllocateContext stub");
}


DECLARE_LEAF_RUNTIME_ENTRY(void, StoreBufferBlockProcess, Isolate* isolate);


// Helper stub to implement Assembler::StoreIntoObject.
// Input parameters:
//   T0: Address (i.e. object) being stored into.
void StubCode::GenerateUpdateStoreBufferStub(Assembler* assembler) {
  // Save values being destroyed.
  __ addiu(SP, SP, Immediate(-3 * kWordSize));
  __ sw(T3, Address(SP, 2 * kWordSize));
  __ sw(T2, Address(SP, 1 * kWordSize));
  __ sw(T1, Address(SP, 0 * kWordSize));

  // Load the isolate out of the context.
  // Spilled: T1, T2, T3.
  // T0: Address being stored.
  __ lw(T1, FieldAddress(CTX, Context::isolate_offset()));

  // Load top_ out of the StoreBufferBlock and add the address to the pointers_.
  // T1: Isolate.
  intptr_t store_buffer_offset = Isolate::store_buffer_block_offset();
  __ lw(T2, Address(T1, store_buffer_offset + StoreBufferBlock::top_offset()));
  __ sll(T3, T2, 1);
  __ addu(T3, T1, T3);
  __ sw(T0,
        Address(T3, store_buffer_offset + StoreBufferBlock::pointers_offset()));

  // Increment top_ and check for overflow.
  // T2: top_
  // T1: Isolate
  Label L;
  __ AddImmediate(T2, 1);
  __ sw(T2, Address(T1, store_buffer_offset + StoreBufferBlock::top_offset()));
  __ addiu(CMPRES, T2, Immediate(-StoreBufferBlock::kSize));
  // Restore values.
  __ lw(T1, Address(SP, 0 * kWordSize));
  __ lw(T2, Address(SP, 1 * kWordSize));
  __ lw(T3, Address(SP, 2 * kWordSize));
  __ beq(CMPRES, ZR, &L);
  __ delay_slot()->addiu(SP, SP, Immediate(3 * kWordSize));
  __ Ret();

  // Handle overflow: Call the runtime leaf function.
  __ Bind(&L);
  // Setup frame, push callee-saved registers.

  __ EnterCallRuntimeFrame(0 * kWordSize);
  __ lw(T0, FieldAddress(CTX, Context::isolate_offset()));
  __ CallRuntime(kStoreBufferBlockProcessRuntimeEntry);
  // Restore callee-saved registers, tear down frame.
  __ LeaveCallRuntimeFrame();
  __ Ret();
}


// Called for inline allocation of objects.
// Input parameters:
//   RA : return address.
//   SP + 4 : type arguments object (only if class is parameterized).
//   SP + 0 : type arguments of instantiator (only if class is parameterized).
void StubCode::GenerateAllocationStubForClass(Assembler* assembler,
                                              const Class& cls) {
  // The generated code is different if the class is parameterized.
  const bool is_cls_parameterized =
      cls.type_arguments_field_offset() != Class::kNoTypeArguments;
  // kInlineInstanceSize is a constant used as a threshold for determining
  // when the object initialization should be done as a loop or as
  // straight line code.
  const int kInlineInstanceSize = 12;
  const intptr_t instance_size = cls.instance_size();
  ASSERT(instance_size > 0);
  const intptr_t type_args_size = InstantiatedTypeArguments::InstanceSize();
  if (FLAG_inline_alloc &&
      PageSpace::IsPageAllocatableSize(instance_size + type_args_size)) {
    Label slow_case;
    Heap* heap = Isolate::Current()->heap();
    __ LoadImmediate(T5, heap->TopAddress());
    __ lw(T2, Address(T5));
    __ LoadImmediate(T4, instance_size);
    __ addu(T3, T2, T4);
    if (is_cls_parameterized) {
      Label no_instantiator;
      __ lw(T1, Address(SP, 1 * kWordSize));
      __ lw(T0, Address(SP, 0 * kWordSize));
      // A new InstantiatedTypeArguments object only needs to be allocated if
      // the instantiator is provided (not kNoInstantiator, but may be null).
      __ BranchEqual(T0, Smi::RawValue(StubCode::kNoInstantiator),
                     &no_instantiator);
      __ delay_slot()->mov(T4, T3);
      __ AddImmediate(T3, type_args_size);
      __ Bind(&no_instantiator);
      // T4: potential new object end and, if T4 != T3, potential new
      // InstantiatedTypeArguments object start.
    }
    // Check if the allocation fits into the remaining space.
    // T2: potential new object start.
    // T3: potential next object start.
    if (FLAG_use_slow_path) {
      __ b(&slow_case);
    } else {
      __ BranchGreaterEqual(T3, heap->EndAddress(), &slow_case);
    }

    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    __ sw(T3, Address(T5));

    if (is_cls_parameterized) {
      // Initialize the type arguments field in the object.
      // T2: new object start.
      // T4: potential new object end and, if T4 != T3, potential new
      // InstantiatedTypeArguments object start.
      // T3: next object start.
      Label type_arguments_ready;
      __ beq(T4, T3, &type_arguments_ready);
      // Initialize InstantiatedTypeArguments object at T4.
      __ sw(T1, Address(T4,
          InstantiatedTypeArguments::uninstantiated_type_arguments_offset()));
      __ sw(T0, Address(T4,
          InstantiatedTypeArguments::instantiator_type_arguments_offset()));
      const Class& ita_cls =
          Class::ZoneHandle(Object::instantiated_type_arguments_class());
      // Set the tags.
      uword tags = 0;
      tags = RawObject::SizeTag::update(type_args_size, tags);
      tags = RawObject::ClassIdTag::update(ita_cls.id(), tags);
      __ LoadImmediate(T0, tags);
      __ sw(T0, Address(T4, Instance::tags_offset()));
      // Set the new InstantiatedTypeArguments object (T4) as the type
      // arguments (T1) of the new object (T2).
      __ addiu(T1, T4, Immediate(kHeapObjectTag));
      // Set T3 to new object end.
      __ mov(T3, T4);
      __ Bind(&type_arguments_ready);
      // T2: new object.
      // T1: new object type arguments.
    }

    // T2: new object start.
    // T3: next object start.
    // T1: new object type arguments (if is_cls_parameterized).
    // Set the tags.
    uword tags = 0;
    tags = RawObject::SizeTag::update(instance_size, tags);
    ASSERT(cls.id() != kIllegalCid);
    tags = RawObject::ClassIdTag::update(cls.id(), tags);
    __ LoadImmediate(T0, tags);
    __ sw(T0, Address(T2, Instance::tags_offset()));

    // Initialize the remaining words of the object.
    __ LoadImmediate(T0, reinterpret_cast<intptr_t>(Object::null()));

    // T0: raw null.
    // T2: new object start.
    // T3: next object start.
    // T1: new object type arguments (if is_cls_parameterized).
    // First try inlining the initialization without a loop.
    if (instance_size < (kInlineInstanceSize * kWordSize)) {
      // Check if the object contains any non-header fields.
      // Small objects are initialized using a consecutive set of writes.
      for (intptr_t current_offset = sizeof(RawObject);
           current_offset < instance_size;
           current_offset += kWordSize) {
        __ sw(T0, Address(T2, current_offset));
      }
    } else {
      __ addiu(T4, T2, Immediate(sizeof(RawObject)));
      // Loop until the whole object is initialized.
      // T0: raw null.
      // T2: new object.
      // T3: next object start.
      // T4: next word to be initialized.
      // T1: new object type arguments (if is_cls_parameterized).
      Label init_loop;
      Label done;
      __ Bind(&init_loop);
      __ BranchGreaterEqual(T4, T3, &done);  // Done if T4 >= T3.
      __ sw(T0, Address(T4));
      __ AddImmediate(T4, kWordSize);
      __ b(&init_loop);
      __ Bind(&done);
    }
    if (is_cls_parameterized) {
      // R1: new object type arguments.
      // Set the type arguments in the new object.
      __ sw(T1, Address(T2, cls.type_arguments_field_offset()));
    }
    // Done allocating and initializing the instance.
    // R2: new object still missing its heap tag.
    __ Ret();
    __ delay_slot()->addiu(V0, T2, Immediate(kHeapObjectTag));

    __ Bind(&slow_case);
  }
  if (is_cls_parameterized) {
    __ lw(T1, Address(SP, 1 * kWordSize));
    __ lw(T0, Address(SP, 0 * kWordSize));
  }
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame(true);  // Uses pool pointer to pass cls to runtime.
  __ LoadImmediate(T2, reinterpret_cast<intptr_t>(Object::null()));
  __ Push(T2);  // Setup space on stack for return value.
  __ PushObject(cls);  // Push class of object to be allocated.
  if (is_cls_parameterized) {
    // Push type arguments of object to be allocated and of instantiator.
    __ addiu(SP, SP, Immediate(-2 * kWordSize));
    __ sw(T1, Address(SP, 1 * kWordSize));
    __ sw(T0, Address(SP, 0 * kWordSize));
  } else {
    // Push null type arguments and kNoInstantiator.
    __ LoadImmediate(T1, Smi::RawValue(StubCode::kNoInstantiator));
    __ addiu(SP, SP, Immediate(-2 * kWordSize));
    __ sw(T2, Address(SP, 1 * kWordSize));
    __ sw(T1, Address(SP, 0 * kWordSize));
  }
  __ CallRuntime(kAllocateObjectRuntimeEntry);  // Allocate object.
  __ Drop(3);  // Pop arguments.
  __ Pop(V0);  // Pop result (newly allocated object).
  // V0: new object
  // Restore the frame pointer.
  __ LeaveStubFrame(true);
  __ Ret();
}


void StubCode::GenerateAllocationStubForClosure(Assembler* assembler,
                                                const Function& func) {
  __ Unimplemented("AllocateClosure stub");
}


void StubCode::GenerateCallNoSuchMethodFunctionStub(Assembler* assembler) {
  __ Unimplemented("CallNoSuchMethodFunction stub");
}


void StubCode::GenerateOptimizedUsageCounterIncrement(Assembler* assembler) {
  __ Unimplemented("OptimizedUsageCounterIncrement stub");
}


// Loads function into 'temp_reg'.
void StubCode::GenerateUsageCounterIncrement(Assembler* assembler,
                                             Register temp_reg) {
  Register ic_reg = S5;
  Register func_reg = temp_reg;
  ASSERT(temp_reg == T0);
  __ lw(func_reg, FieldAddress(ic_reg, ICData::function_offset()));
  __ lw(T1, FieldAddress(func_reg, Function::usage_counter_offset()));
  Label is_hot;
  if (FlowGraphCompiler::CanOptimize()) {
    ASSERT(FLAG_optimization_counter_threshold > 1);
    // The usage_counter is always less than FLAG_optimization_counter_threshold
    // except when the function gets optimized.
    __ BranchEqual(T1, FLAG_optimization_counter_threshold, &is_hot);
    // As long as VM has no OSR do not optimize in the middle of the function
    // but only at exit so that we have collected all type feedback before
    // optimizing.
  }
  __ addiu(T1, T1, Immediate(1));
  __ sw(T1, FieldAddress(func_reg, Function::usage_counter_offset()));
  __ Bind(&is_hot);
}


// Generate inline cache check for 'num_args'.
//  AR: return address
//  S5: Inline cache data object.
//  S4: Arguments descriptor array.
// Control flow:
// - If receiver is null -> jump to IC miss.
// - If receiver is Smi -> load Smi class.
// - If receiver is not-Smi -> load receiver's class.
// - Check if 'num_args' (including receiver) match any IC data group.
// - Match found -> jump to target.
// - Match not found -> jump to IC miss.
void StubCode::GenerateNArgsCheckInlineCacheStub(Assembler* assembler,
                                                 intptr_t num_args) {
  ASSERT(num_args > 0);
#if defined(DEBUG)
  { Label ok;
    // Check that the IC data array has NumberOfArgumentsChecked() == num_args.
    // 'num_args_tested' is stored as an untagged int.
    __ lw(T0, FieldAddress(S5, ICData::num_args_tested_offset()));
    __ BranchEqual(T0, num_args, &ok);
    __ Stop("Incorrect stub for IC data");
    __ Bind(&ok);
  }
#endif  // DEBUG

  // Preserve return address, since LR is needed for subroutine call.
  __ mov(T2, RA);
  // Loop that checks if there is an IC data match.
  Label loop, update, test, found, get_class_id_as_smi;
  // S5: IC data object (preserved).
  __ lw(T0, FieldAddress(S5, ICData::ic_data_offset()));
  // T0: ic_data_array with check entries: classes and target functions.
  __ AddImmediate(T0, Array::data_offset() - kHeapObjectTag);
  // T0: points directly to the first ic data array element.

  // Get the receiver's class ID (first read number of arguments from
  // arguments descriptor array and then access the receiver from the stack).
  __ lw(T1, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
  __ AddImmediate(T1, -Smi::RawValue(1));
  __ sll(T3, T1, 1);  // T1 (argument_count - 1) is smi.
  __ addu(T3, T3, SP);
  __ bal(&get_class_id_as_smi);
  __ delay_slot()->lw(T3, Address(T3));
  // T1: argument_count - 1 (smi).
  // T3: receiver's class ID (smi).
  __ b(&test);
  __ delay_slot()->lw(T4, Address(T0));  // First class id (smi) to check.

  __ Bind(&loop);
  for (int i = 0; i < num_args; i++) {
    if (i > 0) {
      // If not the first, load the next argument's class ID.
      __ LoadImmediate(T3, Smi::RawValue(-i));
      __ addu(T3, T1, T3);
      __ sll(T3, T3, 1);
      __ addu(T3, SP, T3);
      __ bal(&get_class_id_as_smi);
      __ delay_slot()->lw(T3, Address(T3));
      // T3: next argument class ID (smi).
      __ lw(T4, Address(T0, i * kWordSize));
      // T4: next class ID to check (smi).
    }
    if (i < (num_args - 1)) {
      __ bne(T3, T4, &update);  // Continue.
    } else {
      // Last check, all checks before matched.
      Label skip;
      __ bne(T3, T4, &skip);
      __ b(&found);  // Break.
      __ delay_slot()->mov(RA, T2);  // Restore return address if found.
      __ Bind(&skip);
    }
  }
  __ Bind(&update);
  // Reload receiver class ID.  It has not been destroyed when num_args == 1.
  if (num_args > 1) {
    __ sll(T3, T1, 1);
    __ addu(T3, SP, T3);
    __ bal(&get_class_id_as_smi);
    __ delay_slot()->lw(T3, Address(T3));
  }

  const intptr_t entry_size = ICData::TestEntryLengthFor(num_args) * kWordSize;
  __ AddImmediate(T0, entry_size);  // Next entry.
  __ lw(T4, Address(T0));  // Next class ID.

  __ Bind(&test);
  __ BranchNotEqual(T4, Smi::RawValue(kIllegalCid), &loop);  // Done?

  // IC miss.
  // Restore return address.
  __ mov(RA, T2);

  // Compute address of arguments (first read number of arguments from
  // arguments descriptor array and then compute address on the stack).
  // T1: argument_count - 1 (smi).
  __ sll(T1, T1, 1);
  __ addu(T1, SP, T1);  // T1 is Smi.
  // T1: address of receiver.
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ LoadImmediate(T3, reinterpret_cast<intptr_t>(Object::null()));
  // Preserve IC data object and arguments descriptor array and
  // setup space on stack for result (target code object).
  __ addiu(SP, SP, Immediate(-3 * kWordSize));
  __ sw(S5, Address(SP, 2 * kWordSize));
  __ sw(S4, Address(SP, 1 * kWordSize));
  __ sw(T3, Address(SP, 0 * kWordSize));
  // Push call arguments.
  for (intptr_t i = 0; i < num_args; i++) {
    __ lw(TMP, Address(T1, -i * kWordSize));
    __ Push(TMP);
  }
  // Pass IC data object and arguments descriptor array.
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(S5, Address(SP, 1 * kWordSize));
  __ sw(S4, Address(SP, 0 * kWordSize));

  if (num_args == 1) {
    __ CallRuntime(kInlineCacheMissHandlerOneArgRuntimeEntry);
  } else if (num_args == 2) {
    __ CallRuntime(kInlineCacheMissHandlerTwoArgsRuntimeEntry);
  } else if (num_args == 3) {
    __ CallRuntime(kInlineCacheMissHandlerThreeArgsRuntimeEntry);
  } else {
    UNIMPLEMENTED();
  }
  // Remove the call arguments pushed earlier, including the IC data object
  // and the arguments descriptor array.
  __ Drop(num_args + 2);
  // Pop returned code object into T3 (null if not found).
  // Restore arguments descriptor array and IC data array.
  __ lw(T3, Address(SP, 0 * kWordSize));
  __ lw(S4, Address(SP, 1 * kWordSize));
  __ lw(S5, Address(SP, 2 * kWordSize));
  __ addiu(SP, SP, Immediate(3 * kWordSize));
  __ LeaveStubFrame();
  Label call_target_function;
  __ BranchNotEqual(T3, reinterpret_cast<intptr_t>(Object::null()),
                    &call_target_function);
  // NoSuchMethod or closure.
  // Mark IC call that it may be a closure call that does not collect
  // type feedback.
  __ LoadImmediate(TMP2, 1);
  __ Branch(&StubCode::InstanceFunctionLookupLabel());
  __ delay_slot()->sb(TMP2, FieldAddress(S5, ICData::is_closure_call_offset()));

  __ Bind(&found);
  // T0: Pointer to an IC data check group.
  const intptr_t target_offset = ICData::TargetIndexFor(num_args) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(num_args) * kWordSize;
  __ lw(T3, Address(T0, target_offset));
  __ lw(T4, Address(T0, count_offset));

  __ AddImmediateDetectOverflow(T4, T4, Smi::RawValue(1), T5);

  __ bgez(T5, &call_target_function);  // No overflow.
  __ delay_slot()->sw(T4, Address(T0, count_offset));

  __ LoadImmediate(T1, Smi::RawValue(Smi::kMaxValue));
  __ sw(T1, Address(T0, count_offset));

  __ Bind(&call_target_function);
  // T0: Target function.
  __ lw(T3, FieldAddress(T3, Function::code_offset()));
  __ lw(T3, FieldAddress(T3, Code::instructions_offset()));
  __ AddImmediate(T3, Instructions::HeaderSize() - kHeapObjectTag);
  __ jr(T3);

  // Instance in T3, return its class-id in T3 as Smi.
  __ Bind(&get_class_id_as_smi);
  Label not_smi;
  // Test if Smi -> load Smi class for comparison.
  __ andi(TMP1, T3, Immediate(kSmiTagMask));
  __ bne(TMP1, ZR, &not_smi);
  __ LoadImmediate(T3, Smi::RawValue(kSmiCid));
  __ jr(RA);

  __ Bind(&not_smi);
  __ LoadClassId(T3, T3);
  __ SmiTag(T3);
  __ jr(RA);
}


// Use inline cache data array to invoke the target or continue in inline
// cache miss handler. Stub for 1-argument check (receiver class).
//  RA: Return address.
//  S5: Inline cache data object.
//  S4: Arguments descriptor array.
// Inline cache data object structure:
// 0: function-name
// 1: N, number of arguments checked.
// 2 .. (length - 1): group of checks, each check containing:
//   - N classes.
//   - 1 target function.
void StubCode::GenerateOneArgCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, T0);
  GenerateNArgsCheckInlineCacheStub(assembler, 1);
}


void StubCode::GenerateTwoArgsCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, T0);
  GenerateNArgsCheckInlineCacheStub(assembler, 2);
}


void StubCode::GenerateThreeArgsCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, T0);
  GenerateNArgsCheckInlineCacheStub(assembler, 3);
}


void StubCode::GenerateOneArgOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateOptimizedUsageCounterIncrement(assembler);
  GenerateNArgsCheckInlineCacheStub(assembler, 1);
}


void StubCode::GenerateTwoArgsOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateOptimizedUsageCounterIncrement(assembler);
  GenerateNArgsCheckInlineCacheStub(assembler, 2);
}


void StubCode::GenerateThreeArgsOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateOptimizedUsageCounterIncrement(assembler);
  GenerateNArgsCheckInlineCacheStub(assembler, 3);
}


void StubCode::GenerateClosureCallInlineCacheStub(Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(assembler, 1);
}


void StubCode::GenerateMegamorphicCallStub(Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(assembler, 1);
}


void StubCode::GenerateBreakpointStaticStub(Assembler* assembler) {
  __ Unimplemented("BreakpointStatic stub");
}


void StubCode::GenerateBreakpointReturnStub(Assembler* assembler) {
  __ Unimplemented("BreakpointReturn stub");
}


void StubCode::GenerateBreakpointDynamicStub(Assembler* assembler) {
  __ Unimplemented("BreakpointDynamic stub");
}


// Used to check class and type arguments. Arguments passed in registers:
// RA: return address.
// A0: instance (must be preserved).
// A1: instantiator type arguments or NULL.
// A2: cache array.
// Result in V0: null -> not found, otherwise result (true or false).
static void GenerateSubtypeNTestCacheStub(Assembler* assembler, int n) {
  ASSERT((1 <= n) && (n <= 3));
  if (n > 1) {
    // Get instance type arguments.
    __ LoadClass(T0, A0);
    // Compute instance type arguments into R4.
    Label has_no_type_arguments;
    __ LoadImmediate(T1, reinterpret_cast<intptr_t>(Object::null()));
    __ lw(T2, FieldAddress(T0,
        Class::type_arguments_field_offset_in_words_offset()));
    __ BranchEqual(T2, Class::kNoTypeArguments, &has_no_type_arguments);
    __ sll(T2, T2, 2);
    __ addu(T2, A0, T2);  // T2 <- A0 + T2 * 4
    __ lw(T1, FieldAddress(T2, 0));
    __ Bind(&has_no_type_arguments);
  }
  __ LoadClassId(T0, A0);
  // A0: instance.
  // A1: instantiator type arguments or NULL.
  // A2: SubtypeTestCache.
  // T0: instance class id.
  // T1: instance type arguments (null if none), used only if n > 1.
  __ lw(T2, FieldAddress(A2, SubtypeTestCache::cache_offset()));
  __ AddImmediate(T2, Array::data_offset() - kHeapObjectTag);

  Label loop, found, not_found, next_iteration;
  // T0: instance class id.
  // T1: instance type arguments.
  // T2: Entry start.
  __ SmiTag(T0);
  __ Bind(&loop);
  __ lw(T3, Address(T2, kWordSize * SubtypeTestCache::kInstanceClassId));
  __ BranchEqual(T3, reinterpret_cast<intptr_t>(Object::null()), &not_found);

  if (n == 1) {
    __ BranchEqual(T3, T0, &found);
  } else {
    __ BranchNotEqual(T3, T0, &next_iteration);
    __ lw(T3,
          Address(T2, kWordSize * SubtypeTestCache::kInstanceTypeArguments));
    if (n == 2) {
      __ BranchEqual(T3, T1, &found);
    } else {
      __ BranchNotEqual(T3, T1, &next_iteration);
      __ lw(T3, Address(T2, kWordSize *
                        SubtypeTestCache::kInstantiatorTypeArguments));
      __ BranchEqual(T3, A1, &found);
    }
  }
  __ Bind(&next_iteration);
  __ AddImmediate(T2, kWordSize * SubtypeTestCache::kTestEntryLength);
  __ b(&loop);
  // Fall through to not found.
  __ Bind(&not_found);
  __ LoadImmediate(V0, reinterpret_cast<intptr_t>(Object::null()));
  __ Ret();

  __ Bind(&found);
  __ Ret();
  __ delay_slot()->lw(V0,
                      Address(T2, kWordSize * SubtypeTestCache::kTestResult));
}


// Used to check class and type arguments. Arguments passed in registers:
// RA: return address.
// A0: instance (must be preserved).
// A1: instantiator type arguments or NULL.
// A2: cache array.
// Result in V0: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype1TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 1);
}


// Used to check class and type arguments. Arguments passed in registers:
// LR: return address.
// A0: instance (must be preserved).
// A1: instantiator type arguments or NULL.
// A2: cache array.
// Result in V0: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype2TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 2);
}


// Used to check class and type arguments. Arguments passed in registers:
// RA: return address.
// A0: instance (must be preserved).
// A1: instantiator type arguments or NULL.
// A2: cache array.
// Result in V0: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype3TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 3);
}


// Return the current stack pointer address, used to stack alignment
// checks.
void StubCode::GenerateGetStackPointerStub(Assembler* assembler) {
  __ Unimplemented("GetStackPointer Stub");
}


// Jump to the exception handler.
// No Result.
void StubCode::GenerateJumpToExceptionHandlerStub(Assembler* assembler) {
  __ Unimplemented("JumpToExceptionHandler Stub");
}


// Jump to the error handler.
// No Result.
void StubCode::GenerateJumpToErrorHandlerStub(Assembler* assembler) {
  __ Unimplemented("JumpToErrorHandler Stub");
}


void StubCode::GenerateEqualityWithNullArgStub(Assembler* assembler) {
  __ Unimplemented("EqualityWithNullArg Stub");
}


// Calls to the runtime to optimize the given function.
// T0: function to be reoptimized.
// S4: argument descriptor (preserved).
void StubCode::GenerateOptimizeFunctionStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ Push(S4);
  __ LoadImmediate(TMP, reinterpret_cast<intptr_t>(Object::null()));
  __ Push(TMP);  // Setup space on stack for return value.
  __ Push(T0);
  __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry);
  __ Pop(T0);  // Discard argument.
  __ Pop(T0);  // Get Code object
  __ Pop(S4);  // Restore argument descriptor.
  __ lw(T0, FieldAddress(T0, Code::instructions_offset()));
  __ AddImmediate(T0, Instructions::HeaderSize() - kHeapObjectTag);
  __ LeaveStubFrame();
  __ jr(T0);
  __ break_(0);
}


DECLARE_LEAF_RUNTIME_ENTRY(intptr_t,
                           BigintCompare,
                           RawBigint* left,
                           RawBigint* right);


// Does identical check (object references are equal or not equal) with special
// checks for boxed numbers.
// LR: return address.
// SP + 4: left operand.
// SP + 0: right operand.
// Return: CMPRES is zero if equal, non-zero otherwise.
// Note: A Mint cannot contain a value that would fit in Smi, a Bigint
// cannot contain a value that fits in Mint or Smi.
void StubCode::GenerateIdenticalWithNumberCheckStub(Assembler* assembler) {
  const Register ret = CMPRES;
  const Register temp1 = TMP1;
  const Register temp2 = TMP2;
  const Register left = T1;
  const Register right = T0;
  // Preserve left, right and temp.
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(T1, Address(SP, 1 * kWordSize));
  __ sw(T0, Address(SP, 0 * kWordSize));
  // TOS + 4: left argument.
  // TOS + 3: right argument.
  // TOS + 1: saved left
  // TOS + 0: saved right
  __ lw(left, Address(SP, 3 * kWordSize));
  __ lw(right, Address(SP, 2 * kWordSize));
  Label reference_compare, done, check_mint, check_bigint;
  // If any of the arguments is Smi do reference compare.
  __ andi(temp1, left, Immediate(kSmiTagMask));
  __ beq(temp1, ZR, &reference_compare);
  __ andi(temp1, right, Immediate(kSmiTagMask));
  __ beq(temp1, ZR, &reference_compare);

  // Value compare for two doubles.
  __ LoadImmediate(temp1, kDoubleCid);
  __ LoadClassId(temp2, left);
  __ bne(temp1, temp2, &check_mint);
  __ LoadClassId(temp2, right);
  __ subu(ret, temp1, temp2);
  __ bne(ret, ZR, &done);

  // Double values bitwise compare.
  __ lw(temp1, FieldAddress(left, Double::value_offset() + 0 * kWordSize));
  __ lw(temp1, FieldAddress(right, Double::value_offset() + 0 * kWordSize));
  __ subu(ret, temp1, temp2);
  __ bne(ret, ZR, &done);
  __ lw(temp1, FieldAddress(left, Double::value_offset() + 1 * kWordSize));
  __ lw(temp2, FieldAddress(right, Double::value_offset() + 1 * kWordSize));
  __ b(&done);
  __ delay_slot()->subu(ret, temp1, temp2);

  __ Bind(&check_mint);
  __ LoadImmediate(temp1, kMintCid);
  __ LoadClassId(temp2, left);
  __ bne(temp1, temp2, &check_bigint);
  __ LoadClassId(temp2, right);
  __ subu(ret, temp1, temp2);
  __ bne(ret, ZR, &done);

  __ lw(temp1, FieldAddress(left, Mint::value_offset() + 0 * kWordSize));
  __ lw(temp2, FieldAddress(right, Mint::value_offset() + 0 * kWordSize));
  __ subu(ret, temp1, temp2);
  __ bne(ret, ZR, &done);
  __ lw(temp1, FieldAddress(left, Mint::value_offset() + 1 * kWordSize));
  __ lw(temp2, FieldAddress(right, Mint::value_offset() + 1 * kWordSize));
  __ b(&done);
  __ delay_slot()->subu(ret, temp1, temp2);

  __ Bind(&check_bigint);
  __ LoadImmediate(temp1, kBigintCid);
  __ LoadClassId(temp2, left);
  __ bne(temp1, temp2, &reference_compare);
  __ LoadClassId(temp2, right);
  __ subu(ret, temp1, temp2);
  __ bne(ret, ZR, &done);

  __ EnterStubFrame(0);
  __ ReserveAlignedFrameSpace(2 * kWordSize);
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(T1, Address(SP, 1 * kWordSize));
  __ sw(T0, Address(SP, 0 * kWordSize));
  __ CallRuntime(kBigintCompareRuntimeEntry);
  // Result in V0, 0 means equal.
  __ LeaveStubFrame();
  __ b(&done);
  __ delay_slot()->mov(CMPRES, V0);

  __ Bind(&reference_compare);
  __ subu(ret, left, right);
  __ Bind(&done);
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ lw(T1, Address(SP, 1 * kWordSize));
  __ Ret();
  __ delay_slot()->addiu(SP, SP, Immediate(2 * kWordSize));
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
