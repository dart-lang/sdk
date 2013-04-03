// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM)

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
//   LR : return address.
//   SP : address of last argument in argument array.
//   SP + 4*R4 - 4 : address of first argument in argument array.
//   SP + 4*R4 : address of return value.
//   R5 : address of the runtime function to call.
//   R4 : number of arguments to the call.
void StubCode::GenerateCallToRuntimeStub(Assembler* assembler) {
  const intptr_t isolate_offset = NativeArguments::isolate_offset();
  const intptr_t argc_tag_offset = NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = NativeArguments::argv_offset();
  const intptr_t retval_offset = NativeArguments::retval_offset();

  __ EnterFrame((1 << FP) | (1 << LR), 0);

  // Load current Isolate pointer from Context structure into R0.
  __ ldr(R0, FieldAddress(CTX, Context::isolate_offset()));

  // Save exit frame information to enable stack walking as we are about
  // to transition to Dart VM C++ code.
  __ StoreToOffset(kStoreWord, SP, R0, Isolate::top_exit_frame_info_offset());

  // Save current Context pointer into Isolate structure.
  __ StoreToOffset(kStoreWord, CTX, R0, Isolate::top_context_offset());

  // Cache Isolate pointer into CTX while executing runtime code.
  __ mov(CTX, ShifterOperand(R0));

  // Reserve space for arguments and align frame before entering C++ world.
  // NativeArguments are passed in registers.
  ASSERT(sizeof(NativeArguments) == 4 * kWordSize);
  __ ReserveAlignedFrameSpace(0);

  // Pass NativeArguments structure by value and call runtime.
  // Registers R0, R1, R2, and R3 are used.

  ASSERT(isolate_offset == 0 * kWordSize);
  // Set isolate in NativeArgs: R0 already contains CTX.

  // There are no runtime calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * kWordSize);
  __ mov(R1, ShifterOperand(R4));  // Set argc in NativeArguments.

  ASSERT(argv_offset == 2 * kWordSize);
  __ add(R2, FP, ShifterOperand(R4, LSL, 2));  // Compute argv.
  __ AddImmediate(R2, kWordSize);  // Set argv in NativeArguments.

  ASSERT(retval_offset == 3 * kWordSize);
  __ add(R3, R2, ShifterOperand(kWordSize));  // Retval is next to 1st argument.

  // Call runtime or redirection via simulator.
  __ blx(R5);

  // Reset exit frame information in Isolate structure.
  __ LoadImmediate(R2, 0);
  __ StoreToOffset(kStoreWord, R2, CTX, Isolate::top_exit_frame_info_offset());

  // Load Context pointer from Isolate structure into R2.
  __ LoadFromOffset(kLoadWord, R2, CTX, Isolate::top_context_offset());

  // Reset Context pointer in Isolate structure.
  __ LoadImmediate(R3, reinterpret_cast<intptr_t>(Object::null()));
  __ StoreToOffset(kStoreWord, R3, CTX, Isolate::top_context_offset());

  // Cache Context pointer into CTX while executing Dart code.
  __ mov(CTX, ShifterOperand(R2));

  __ LeaveFrame((1 << FP) | (1 << LR));
  __ Ret();
}


// Print the stop message.
DEFINE_LEAF_RUNTIME_ENTRY(void, PrintStopMessage, const char* message) {
  OS::Print("Stop message: %s\n", message);
}
END_LEAF_RUNTIME_ENTRY


// Input parameters:
//   R0 : stop message (const char*).
// Must preserve all registers.
void StubCode::GeneratePrintStopMessageStub(Assembler* assembler) {
  __ EnterCallRuntimeFrame(0);
  // Call the runtime leaf function. R0 already contains the parameter.
  __ CallRuntime(kPrintStopMessageRuntimeEntry);
  __ LeaveCallRuntimeFrame();
  __ Ret();
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

  __ EnterFrame((1 << FP) | (1 << LR), 0);

  // Load current Isolate pointer from Context structure into R0.
  __ ldr(R0, FieldAddress(CTX, Context::isolate_offset()));

  // Save exit frame information to enable stack walking as we are about
  // to transition to native code.
  __ StoreToOffset(kStoreWord, SP, R0, Isolate::top_exit_frame_info_offset());

  // Save current Context pointer into Isolate structure.
  __ StoreToOffset(kStoreWord, CTX, R0, Isolate::top_context_offset());

  // Cache Isolate pointer into CTX while executing native code.
  __ mov(CTX, ShifterOperand(R0));

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

  ASSERT(retval_offset == 3 * kWordSize);
  __ add(R3, FP, ShifterOperand(2 * kWordSize));  // Set retval in NativeArgs.

  // TODO(regis): Should we pass the structure by value as in runtime calls?
  // It would require changing Dart API for native functions.
  // For now, space is reserved on the stack and we pass a pointer to it.
  __ stm(IA, SP,  (1 << R0) | (1 << R1) | (1 << R2) | (1 << R3));
  __ mov(R0, ShifterOperand(SP));  // Pass the pointer to the NativeArguments.

  // Call native function or redirection via simulator.
  __ blx(R5);

  // Reset exit frame information in Isolate structure.
  __ LoadImmediate(R2, 0);
  __ StoreToOffset(kStoreWord, R2, CTX, Isolate::top_exit_frame_info_offset());

  // Load Context pointer from Isolate structure into R2.
  __ LoadFromOffset(kLoadWord, R2, CTX, Isolate::top_context_offset());

  // Reset Context pointer in Isolate structure.
  __ LoadImmediate(R3, reinterpret_cast<intptr_t>(Object::null()));
  __ StoreToOffset(kStoreWord, R3, CTX, Isolate::top_context_offset());

  // Cache Context pointer into CTX while executing Dart code.
  __ mov(CTX, ShifterOperand(R2));

  __ LeaveFrame((1 << FP) | (1 << LR));
  __ Ret();
}


// Input parameters:
//   R4: arguments descriptor array.
void StubCode::GenerateCallStaticFunctionStub(Assembler* assembler) {
  __ EnterStubFrame();
  // Setup space on stack for return value and preserve arguments descriptor.
  __ LoadImmediate(R0, reinterpret_cast<intptr_t>(Object::null()));
  __ PushList((1 << R0) | (1 << R4));
  __ CallRuntime(kPatchStaticCallRuntimeEntry);
  // Get Code object result and restore arguments descriptor array.
  __ PopList((1 << R0) | (1 << R4));
  // Remove the stub frame as we are about to jump to the dart function.
  __ LeaveStubFrame();

  __ ldr(R0, FieldAddress(R0, Code::instructions_offset()));
  __ AddImmediate(R0, R0, Instructions::HeaderSize() - kHeapObjectTag);
  __ bx(R0);
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
//   LR : points to return address.
//   R0 : entrypoint of the Dart function to call.
//   R1 : arguments descriptor array.
//   R2 : arguments array.
//   R3 : new context containing the current isolate pointer.
void StubCode::GenerateInvokeDartCodeStub(Assembler* assembler) {
  // Save frame pointer coming in.
  __ EnterStubFrame();

  // Save new context and C++ ABI callee-saved registers.
  const intptr_t kNewContextOffset =
      -(1 + kAbiPreservedCpuRegCount) * kWordSize;
  __ PushList((1 << R3) | kAbiPreservedCpuRegs);

  // The new Context structure contains a pointer to the current Isolate
  // structure. Cache the Context pointer in the CTX register so that it is
  // available in generated code and calls to Isolate::Current() need not be
  // done. The assumption is that this register will never be clobbered by
  // compiled or runtime stub code.

  // Cache the new Context pointer into CTX while executing Dart code.
  __ ldr(CTX, Address(R3, VMHandles::kOffsetOfRawPtrInHandle));

  // Load Isolate pointer from Context structure into temporary register R8.
  __ ldr(R8, FieldAddress(CTX, Context::isolate_offset()));

  // Save the top exit frame info. Use R5 as a temporary register.
  // StackFrameIterator reads the top exit frame info saved in this frame.
  __ LoadFromOffset(kLoadWord, R5, R8, Isolate::top_exit_frame_info_offset());
  __ LoadImmediate(R6, 0);
  __ StoreToOffset(kStoreWord, R6, R8, Isolate::top_exit_frame_info_offset());

  // Save the old Context pointer. Use R4 as a temporary register.
  // Note that VisitObjectPointers will find this saved Context pointer during
  // GC marking, since it traverses any information between SP and
  // FP - kExitLinkOffsetInEntryFrame.
  // EntryFrame::SavedContext reads the context saved in this frame.
  __ LoadFromOffset(kLoadWord, R4, R8, Isolate::top_context_offset());

  // The constants kSavedContextOffsetInEntryFrame and
  // kExitLinkOffsetInEntryFrame must be kept in sync with the code below.
  __ PushList((1 << R4) | (1 << R5));

  // The stack pointer is restore after the call to this location.
  const intptr_t kSavedContextOffsetInEntryFrame = -10 * kWordSize;

  // Load arguments descriptor array into R4, which is passed to Dart code.
  __ ldr(R4, Address(R1, VMHandles::kOffsetOfRawPtrInHandle));

  // Load number of arguments into R5.
  __ ldr(R5, FieldAddress(R4, ArgumentsDescriptor::count_offset()));
  __ SmiUntag(R5);

  // Compute address of 'arguments array' data area into R2.
  __ ldr(R2, Address(R2, VMHandles::kOffsetOfRawPtrInHandle));
  __ AddImmediate(R2, R2, Array::data_offset() - kHeapObjectTag);

  // Set up arguments for the Dart call.
  Label push_arguments;
  Label done_push_arguments;
  __ CompareImmediate(R5, 0);  // check if there are arguments.
  __ b(&done_push_arguments, EQ);
  __ LoadImmediate(R1, 0);
  __ Bind(&push_arguments);
  __ ldr(R3, Address(R2));
  __ Push(R3);
  __ AddImmediate(R2, kWordSize);
  __ AddImmediate(R1, 1);
  __ cmp(R1, ShifterOperand(R5));
  __ b(&push_arguments, LT);
  __ Bind(&done_push_arguments);

  // Call the Dart code entrypoint.
  __ blx(R0);  // R4 is the arguments descriptor array.

  // Read the saved new Context pointer.
  __ ldr(CTX, Address(FP, kNewContextOffset));
  __ ldr(CTX, Address(CTX, VMHandles::kOffsetOfRawPtrInHandle));

  // Get rid of arguments pushed on the stack.
  __ AddImmediate(SP, FP, kSavedContextOffsetInEntryFrame);

  // Load Isolate pointer from Context structure into CTX. Drop Context.
  __ ldr(CTX, FieldAddress(CTX, Context::isolate_offset()));

  // Restore the saved Context pointer into the Isolate structure.
  // Uses R4 as a temporary register for this.
  // Restore the saved top exit frame info back into the Isolate structure.
  // Uses R5 as a temporary register for this.
  __ PopList((1 << R4) | (1 << R5));
  __ StoreToOffset(kStoreWord, R4, CTX, Isolate::top_context_offset());
  __ StoreToOffset(kStoreWord, R5, CTX, Isolate::top_exit_frame_info_offset());

  // Restore C++ ABI callee-saved registers.
  __ PopList((1 << R3) | kAbiPreservedCpuRegs);  // Ignore restored R3.

  // Restore the frame pointer and return.
  __ LeaveStubFrame();
  __ Ret();
}


void StubCode::GenerateAllocateContextStub(Assembler* assembler) {
  __ Unimplemented("AllocateContext stub");
}


void StubCode::GenerateUpdateStoreBufferStub(Assembler* assembler) {
  __ Unimplemented("UpdateStoreBuffer stub");
}


// Called for inline allocation of objects.
// Input parameters:
//   LR : return address.
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
    __ LoadImmediate(R5, heap->TopAddress());
    __ ldr(R2, Address(R5, 0));
    __ AddImmediate(R3, R2, instance_size);
    if (is_cls_parameterized) {
      __ ldm(IA, SP, (1 << R0) | (1 << R1));
      __ mov(R4, ShifterOperand(R3));
      // A new InstantiatedTypeArguments object only needs to be allocated if
      // the instantiator is provided (not kNoInstantiator, but may be null).
      __ CompareImmediate(R0, Smi::RawValue(StubCode::kNoInstantiator));
      __ AddImmediate(R3, type_args_size, NE);
      // R4: potential new object end and, if R4 != R3, potential new
      // InstantiatedTypeArguments object start.
    }
    // Check if the allocation fits into the remaining space.
    // R2: potential new object start.
    // R3: potential next object start.
    if (FLAG_use_slow_path) {
      __ b(&slow_case);
    } else {
      __ LoadImmediate(IP, heap->EndAddress());
      __ cmp(R3, ShifterOperand(IP));
      __ b(&slow_case, CS);  // Branch if unsigned higher or equal.
    }

    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    __ str(R3, Address(R5, 0));

    if (is_cls_parameterized) {
      // Initialize the type arguments field in the object.
      // R2: new object start.
      // R4: potential new object end and, if R4 != R3, potential new
      // InstantiatedTypeArguments object start.
      // R3: next object start.
      Label type_arguments_ready;
      __ cmp(R4, ShifterOperand(R3));
      __ b(&type_arguments_ready, EQ);
      // Initialize InstantiatedTypeArguments object at R4.
      __ str(R1, Address(R4,
          InstantiatedTypeArguments::uninstantiated_type_arguments_offset()));
      __ str(R0, Address(R4,
          InstantiatedTypeArguments::instantiator_type_arguments_offset()));
      const Class& ita_cls =
          Class::ZoneHandle(Object::instantiated_type_arguments_class());
      // Set the tags.
      uword tags = 0;
      tags = RawObject::SizeTag::update(type_args_size, tags);
      tags = RawObject::ClassIdTag::update(ita_cls.id(), tags);
      __ LoadImmediate(R0, tags);
      __ str(R0, Address(R4, Instance::tags_offset()));
      // Set the new InstantiatedTypeArguments object (R4) as the type
      // arguments (R1) of the new object (R2).
      __ add(R1, R4, ShifterOperand(kHeapObjectTag));
      // Set R3 to new object end.
      __ mov(R3, ShifterOperand(R4));
      __ Bind(&type_arguments_ready);
      // R2: new object.
      // R1: new object type arguments.
    }

    // R2: new object start.
    // R3: next object start.
    // R1: new object type arguments (if is_cls_parameterized).
    // Set the tags.
    uword tags = 0;
    tags = RawObject::SizeTag::update(instance_size, tags);
    ASSERT(cls.id() != kIllegalCid);
    tags = RawObject::ClassIdTag::update(cls.id(), tags);
    __ LoadImmediate(R0, tags);
    __ str(R0, Address(R2, Instance::tags_offset()));

    // Initialize the remaining words of the object.
    __ LoadImmediate(R0, reinterpret_cast<intptr_t>(Object::null()));

    // R0: raw null.
    // R2: new object start.
    // R3: next object start.
    // R1: new object type arguments (if is_cls_parameterized).
    // First try inlining the initialization without a loop.
    if (instance_size < (kInlineInstanceSize * kWordSize)) {
      // Check if the object contains any non-header fields.
      // Small objects are initialized using a consecutive set of writes.
      for (intptr_t current_offset = sizeof(RawObject);
           current_offset < instance_size;
           current_offset += kWordSize) {
        __ StoreToOffset(kStoreWord, R0, R2, current_offset);
      }
    } else {
      __ add(R4, R2, ShifterOperand(sizeof(RawObject)));
      // Loop until the whole object is initialized.
      // R0: raw null.
      // R2: new object.
      // R3: next object start.
      // R4: next word to be initialized.
      // R1: new object type arguments (if is_cls_parameterized).
      Label init_loop;
      Label done;
      __ Bind(&init_loop);
      __ cmp(R4, ShifterOperand(R3));
      __ b(&done, CS);
      __ str(R0, Address(R4, 0));
      __ AddImmediate(R4, kWordSize);
      __ b(&init_loop);
      __ Bind(&done);
    }
    if (is_cls_parameterized) {
      // R1: new object type arguments.
      // Set the type arguments in the new object.
      __ StoreToOffset(kStoreWord, R1, R2, cls.type_arguments_field_offset());
    }
    // Done allocating and initializing the instance.
    // R2: new object still missing its heap tag.
    __ add(R0, R2, ShifterOperand(kHeapObjectTag));
    __ Ret();

    __ Bind(&slow_case);
  }
  if (is_cls_parameterized) {
    __ ldm(IA, SP, (1 << R0) | (1 << R1));
  }
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame(true);  // Uses pool pointer to pass cls to runtime.
  __ LoadImmediate(R2, reinterpret_cast<intptr_t>(Object::null()));
  __ Push(R2);  // Setup space on stack for return value.
  __ PushObject(cls);  // Push class of object to be allocated.
  if (is_cls_parameterized) {
    // Push type arguments of object to be allocated and of instantiator.
    __ PushList((1 << R0) | (1 << R1));
  } else {
    // Push null type arguments and kNoInstantiator.
    __ LoadImmediate(R1, Smi::RawValue(StubCode::kNoInstantiator));
    __ PushList((1 << R1) | (1 << R2));
  }
  __ CallRuntime(kAllocateObjectRuntimeEntry);  // Allocate object.
  __ Drop(3);  // Pop arguments.
  __ Pop(R0);  // Pop result (newly allocated object).
  // R0: new object
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
  Register ic_reg = R5;
  Register func_reg = temp_reg;
  ASSERT(temp_reg == R6);
  __ ldr(func_reg, FieldAddress(ic_reg, ICData::function_offset()));
  __ ldr(R7, FieldAddress(func_reg, Function::usage_counter_offset()));
  Label is_hot;
  if (FlowGraphCompiler::CanOptimize()) {
    ASSERT(FLAG_optimization_counter_threshold > 1);
    // The usage_counter is always less than FLAG_optimization_counter_threshold
    // except when the function gets optimized.
    __ CompareImmediate(R7, FLAG_optimization_counter_threshold);
    __ b(&is_hot, EQ);
    // As long as VM has no OSR do not optimize in the middle of the function
    // but only at exit so that we have collected all type feedback before
    // optimizing.
  }
  __ add(R7, R7, ShifterOperand(1));
  __ str(R7, FieldAddress(func_reg, Function::usage_counter_offset()));
  __ Bind(&is_hot);
}


// Generate inline cache check for 'num_args'.
//  LR: return address
//  R5: Inline cache data object.
//  R4: Arguments descriptor array.
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
    __ ldr(R6, FieldAddress(R5, ICData::num_args_tested_offset()));
    __ CompareImmediate(R6, num_args);
    __ b(&ok, EQ);
    __ Stop("Incorrect stub for IC data");
    __ Bind(&ok);
  }
#endif  // DEBUG

  // Preserve return address, since LR is needed for subroutine call.
  __ mov(R8, ShifterOperand(LR));
  // Loop that checks if there is an IC data match.
  Label loop, update, test, found, get_class_id_as_smi;
  // R5: IC data object (preserved).
  __ ldr(R6, FieldAddress(R5, ICData::ic_data_offset()));
  // R6: ic_data_array with check entries: classes and target functions.
  __ AddImmediate(R6, R6, Array::data_offset() - kHeapObjectTag);
  // R6: points directly to the first ic data array element.

  // Get the receiver's class ID (first read number of arguments from
  // arguments descriptor array and then access the receiver from the stack).
  __ ldr(R7, FieldAddress(R4, ArgumentsDescriptor::count_offset()));
  __ sub(R7, R7, ShifterOperand(Smi::RawValue(1)));
  __ ldr(R0, Address(SP, R7, LSL, 1));  // R7 (argument_count - 1) is smi.
  __ bl(&get_class_id_as_smi);
  // R7: argument_count - 1 (smi).
  // R0: receiver's class ID (smi).
  __ ldr(R1, Address(R6, 0));  // First class id (smi) to check.
  __ b(&test);

  __ Bind(&loop);
  for (int i = 0; i < num_args; i++) {
    if (i > 0) {
      // If not the first, load the next argument's class ID.
      __ AddImmediate(R0, R7, Smi::RawValue(-i));
      __ ldr(R0, Address(SP, R0, LSL, 1));
      __ bl(&get_class_id_as_smi);
      // R0: next argument class ID (smi).
      __ LoadFromOffset(kLoadWord, R1, R6, i * kWordSize);
      // R1: next class ID to check (smi).
    }
    __ cmp(R0, ShifterOperand(R1));  // Class id match?
    if (i < (num_args - 1)) {
      __ b(&update, NE);  // Continue.
    } else {
      // Last check, all checks before matched.
      __ mov(LR, ShifterOperand(R8), EQ);  // Restore return address if found.
      __ b(&found, EQ);  // Break.
    }
  }
  __ Bind(&update);
  // Reload receiver class ID.  It has not been destroyed when num_args == 1.
  if (num_args > 1) {
    __ ldr(R0, Address(SP, R7, LSL, 1));
    __ bl(&get_class_id_as_smi);
  }

  const intptr_t entry_size = ICData::TestEntryLengthFor(num_args) * kWordSize;
  __ AddImmediate(R6, entry_size);  // Next entry.
  __ ldr(R1, Address(R6, 0));  // Next class ID.

  __ Bind(&test);
  __ CompareImmediate(R1, Smi::RawValue(kIllegalCid));  // Done?
  __ b(&loop, NE);

  // IC miss.
  // Restore return address.
  __ mov(LR, ShifterOperand(R8));

  // Compute address of arguments (first read number of arguments from
  // arguments descriptor array and then compute address on the stack).
  // R7: argument_count - 1 (smi).
  __ add(R7, SP, ShifterOperand(R7, LSL, 1));  // R7 is Smi.
  // R7: address of receiver.
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ LoadImmediate(R0, reinterpret_cast<intptr_t>(Object::null()));
  // Preserve IC data object and arguments descriptor array and
  // setup space on stack for result (target code object).
  __ PushList((1 << R0) | (1 << R4) | (1 << R5));
  // Push call arguments.
  for (intptr_t i = 0; i < num_args; i++) {
    __ LoadFromOffset(kLoadWord, IP, R7, -i * kWordSize);
    __ Push(IP);
  }
  // Pass IC data object and arguments descriptor array.
  __ PushList((1 << R4) | (1 << R5));

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
  // Pop returned code object into R0 (null if not found).
  // Restore arguments descriptor array and IC data array.
  __ PopList((1 << R0) | (1 << R4) | (1 << R5));
  __ LeaveStubFrame();
  Label call_target_function;
  __ CompareImmediate(R0, reinterpret_cast<intptr_t>(Object::null()));
  __ b(&call_target_function, NE);
  // NoSuchMethod or closure.
  // Mark IC call that it may be a closure call that does not collect
  // type feedback.
  __ mov(IP, ShifterOperand(1));
  __ strb(IP, FieldAddress(R5, ICData::is_closure_call_offset()));
  __ Branch(&StubCode::InstanceFunctionLookupLabel());

  __ Bind(&found);
  // R6: Pointer to an IC data check group.
  const intptr_t target_offset = ICData::TargetIndexFor(num_args) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(num_args) * kWordSize;
  __ LoadFromOffset(kLoadWord, R0, R6, target_offset);
  __ LoadFromOffset(kLoadWord, R1, R6, count_offset);
  __ adds(R1, R1, ShifterOperand(Smi::RawValue(1)));
  __ StoreToOffset(kStoreWord, R1, R6, count_offset);
  __ b(&call_target_function, VC);  // No overflow.
  __ LoadImmediate(R1, Smi::RawValue(Smi::kMaxValue));
  __ StoreToOffset(kStoreWord, R1, R6, count_offset);

  __ Bind(&call_target_function);
  // R0: Target function.
  __ ldr(R0, FieldAddress(R0, Function::code_offset()));
  __ ldr(R0, FieldAddress(R0, Code::instructions_offset()));
  __ AddImmediate(R0, Instructions::HeaderSize() - kHeapObjectTag);
  __ bx(R0);

  // Instance in R0, return its class-id in R0 as Smi.
  __ Bind(&get_class_id_as_smi);
  Label not_smi;
  // Test if Smi -> load Smi class for comparison.
  __ tst(R0, ShifterOperand(kSmiTagMask));
  __ mov(R0, ShifterOperand(Smi::RawValue(kSmiCid)), EQ);
  __ bx(LR, EQ);
  __ LoadClassId(R0, R0);
  __ SmiTag(R0);
  __ bx(LR);
}


// Use inline cache data array to invoke the target or continue in inline
// cache miss handler. Stub for 1-argument check (receiver class).
//  LR: Return address.
//  R5: Inline cache data object.
//  R4: Arguments descriptor array.
// Inline cache data object structure:
// 0: function-name
// 1: N, number of arguments checked.
// 2 .. (length - 1): group of checks, each check containing:
//   - N classes.
//   - 1 target function.
void StubCode::GenerateOneArgCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
  GenerateNArgsCheckInlineCacheStub(assembler, 1);
}


void StubCode::GenerateTwoArgsCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
  GenerateNArgsCheckInlineCacheStub(assembler, 2);
}


void StubCode::GenerateThreeArgsCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
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
// LR: return address.
// R0: instance (must be preserved).
// R1: instantiator type arguments or NULL.
// R2: cache array.
// Result in R1: null -> not found, otherwise result (true or false).
static void GenerateSubtypeNTestCacheStub(Assembler* assembler, int n) {
  ASSERT((1 <= n) && (n <= 3));
  if (n > 1) {
    // Get instance type arguments.
    __ LoadClass(R3, R0, R4);
    // Compute instance type arguments into R4.
    Label has_no_type_arguments;
    __ LoadImmediate(R4, reinterpret_cast<intptr_t>(Object::null()));
    __ ldr(R5, FieldAddress(R3,
        Class::type_arguments_field_offset_in_words_offset()));
    __ CompareImmediate(R5, Class::kNoTypeArguments);
    __ b(&has_no_type_arguments, EQ);
    __ add(R5, R0, ShifterOperand(R5, LSL, 2));
    __ ldr(R4, FieldAddress(R5, 0));
    __ Bind(&has_no_type_arguments);
  }
  __ LoadClassId(R3, R0);
  // R0: instance.
  // R1: instantiator type arguments or NULL.
  // R2: SubtypeTestCache.
  // R3: instance class id.
  // R4: instance type arguments (null if none), used only if n > 1.
  __ ldr(R2, FieldAddress(R2, SubtypeTestCache::cache_offset()));
  __ AddImmediate(R2, Array::data_offset() - kHeapObjectTag);

  Label loop, found, not_found, next_iteration;
  // R2: Entry start.
  // R3: instance class id.
  // R4: instance type arguments.
  __ SmiTag(R3);
  __ Bind(&loop);
  __ ldr(R5, Address(R2, kWordSize * SubtypeTestCache::kInstanceClassId));
  __ CompareImmediate(R5, reinterpret_cast<intptr_t>(Object::null()));
  __ b(&not_found, EQ);
  __ cmp(R5, ShifterOperand(R3));
  if (n == 1) {
    __ b(&found, EQ);
  } else {
    __ b(&next_iteration, NE);
    __ ldr(R5,
           Address(R2, kWordSize * SubtypeTestCache::kInstanceTypeArguments));
    __ cmp(R5, ShifterOperand(R4));
    if (n == 2) {
      __ b(&found, EQ);
    } else {
      __ b(&next_iteration, NE);
      __ ldr(R5, Address(R2, kWordSize *
                             SubtypeTestCache::kInstantiatorTypeArguments));
      __ cmp(R5, ShifterOperand(R1));
      __ b(&found, EQ);
    }
  }
  __ Bind(&next_iteration);
  __ AddImmediate(R2, kWordSize * SubtypeTestCache::kTestEntryLength);
  __ b(&loop);
  // Fall through to not found.
  __ Bind(&not_found);
  __ LoadImmediate(R1, reinterpret_cast<intptr_t>(Object::null()));
  __ Ret();

  __ Bind(&found);
  __ ldr(R1, Address(R2, kWordSize * SubtypeTestCache::kTestResult));
  __ Ret();
}


// Used to check class and type arguments. Arguments passed in registers:
// LR: return address.
// R0: instance (must be preserved).
// R1: instantiator type arguments or NULL.
// R2: cache array.
// Result in R1: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype1TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 1);
}


// Used to check class and type arguments. Arguments passed in registers:
// LR: return address.
// R0: instance (must be preserved).
// R1: instantiator type arguments or NULL.
// R2: cache array.
// Result in R1: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype2TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 2);
}


// Used to check class and type arguments. Arguments passed in registers:
// LR: return address.
// R0: instance (must be preserved).
// R1: instantiator type arguments or NULL.
// R2: cache array.
// Result in R1: null -> not found, otherwise result (true or false).
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


void StubCode::GenerateOptimizeFunctionStub(Assembler* assembler) {
  __ Unimplemented("OptimizeFunction stub");
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
// Return Zero condition flag set if equal.
// Note: A Mint cannot contain a value that would fit in Smi, a Bigint
// cannot contain a value that fits in Mint or Smi.
void StubCode::GenerateIdenticalWithNumberCheckStub(Assembler* assembler) {
  const Register temp = R2;
  const Register left = R1;
  const Register right = R0;
  // Preserve left, right and temp.
  __ PushList((1 << R0) | (1 << R1) | (1 << R2));
  // TOS + 4: left argument.
  // TOS + 3: right argument.
  // TOS + 2: saved temp
  // TOS + 1: saved left
  // TOS + 0: saved right
  __ ldr(left, Address(SP, 4 * kWordSize));
  __ ldr(right, Address(SP, 3 * kWordSize));
  Label reference_compare, done, check_mint, check_bigint;
  // If any of the arguments is Smi do reference compare.
  __ tst(left, ShifterOperand(kSmiTagMask));
  __ b(&reference_compare, EQ);
  __ tst(right, ShifterOperand(kSmiTagMask));
  __ b(&reference_compare, EQ);

  // Value compare for two doubles.
  __ CompareClassId(left, kDoubleCid, temp);
  __ b(&check_mint, NE);
  __ CompareClassId(right, kDoubleCid, temp);
  __ b(&done, NE);

  // Double values bitwise compare.
  __ ldr(temp, FieldAddress(left, Double::value_offset() + 0 * kWordSize));
  __ ldr(IP, FieldAddress(right, Double::value_offset() + 0 * kWordSize));
  __ cmp(temp, ShifterOperand(IP));
  __ b(&done, NE);
  __ ldr(temp, FieldAddress(left, Double::value_offset() + 1 * kWordSize));
  __ ldr(IP, FieldAddress(right, Double::value_offset() + 1 * kWordSize));
  __ cmp(temp, ShifterOperand(IP));
  __ b(&done);

  __ Bind(&check_mint);
  __ CompareClassId(left, kMintCid, temp);
  __ b(&check_bigint, NE);
  __ CompareClassId(right, kMintCid, temp);
  __ b(&done, NE);
  __ ldr(temp, FieldAddress(left, Mint::value_offset() + 0 * kWordSize));
  __ ldr(IP, FieldAddress(right, Mint::value_offset() + 0 * kWordSize));
  __ cmp(temp, ShifterOperand(IP));
  __ b(&done, NE);
  __ ldr(temp, FieldAddress(left, Mint::value_offset() + 1 * kWordSize));
  __ ldr(IP, FieldAddress(right, Mint::value_offset() + 1 * kWordSize));
  __ cmp(temp, ShifterOperand(IP));
  __ b(&done);

  __ Bind(&check_bigint);
  __ CompareClassId(left, kBigintCid, temp);
  __ b(&reference_compare, NE);
  __ CompareClassId(right, kBigintCid, temp);
  __ b(&done, NE);
  __ EnterStubFrame(0);
  __ ReserveAlignedFrameSpace(2 * kWordSize);
  __ stm(IA, SP,  (1 << R0) | (1 << R1));
  __ CallRuntime(kBigintCompareRuntimeEntry);
  // Result in R0, 0 means equal.
  __ LeaveStubFrame();
  __ cmp(R0, ShifterOperand(0));
  __ b(&done);

  __ Bind(&reference_compare);
  __ cmp(left, ShifterOperand(right));
  __ Bind(&done);
  __ PopList((1 << R0) | (1 << R1) | (1 << R2));
  __ Ret();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
