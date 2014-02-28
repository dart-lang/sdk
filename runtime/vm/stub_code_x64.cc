// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

#include "vm/assembler.h"
#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph_compiler.h"
#include "vm/heap.h"
#include "vm/instructions.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/scavenger.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"


#define __ assembler->

namespace dart {

DEFINE_FLAG(bool, inline_alloc, true, "Inline allocation of objects.");
DEFINE_FLAG(bool, use_slow_path, false,
    "Set to true for debugging & verifying the slow paths.");
DECLARE_FLAG(bool, trace_optimized_ic_calls);
DECLARE_FLAG(int, optimization_counter_threshold);


// Input parameters:
//   RSP : points to return address.
//   RSP + 8 : address of last argument in argument array.
//   RSP + 8*R10 : address of first argument in argument array.
//   RSP + 8*R10 + 8 : address of return value.
//   RBX : address of the runtime function to call.
//   R10 : number of arguments to the call.
// Must preserve callee saved registers R12 and R13.
void StubCode::GenerateCallToRuntimeStub(Assembler* assembler) {
  ASSERT((R12 != CTX) && (R13 != CTX));
  const intptr_t isolate_offset = NativeArguments::isolate_offset();
  const intptr_t argc_tag_offset = NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = NativeArguments::argv_offset();
  const intptr_t retval_offset = NativeArguments::retval_offset();

  __ EnterFrame(0);

  // Load current Isolate pointer from Context structure into RAX.
  __ movq(RAX, FieldAddress(CTX, Context::isolate_offset()));

  // Save exit frame information to enable stack walking as we are about
  // to transition to Dart VM C++ code.
  __ movq(Address(RAX, Isolate::top_exit_frame_info_offset()), RSP);

  // Save current Context pointer into Isolate structure.
  __ movq(Address(RAX, Isolate::top_context_offset()), CTX);

  // Cache Isolate pointer into CTX while executing runtime code.
  __ movq(CTX, RAX);

  // Reserve space for arguments and align frame before entering C++ world.
  __ subq(RSP, Immediate(sizeof(NativeArguments)));
  if (OS::ActivationFrameAlignment() > 1) {
    __ andq(RSP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass NativeArguments structure by value and call runtime.
  __ movq(Address(RSP, isolate_offset), CTX);  // Set isolate in NativeArgs.
  // There are no runtime calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  __ movq(Address(RSP, argc_tag_offset), R10);  // Set argc in NativeArguments.
  __ leaq(RAX, Address(RBP, R10, TIMES_8, 1 * kWordSize));  // Compute argv.
  __ movq(Address(RSP, argv_offset), RAX);  // Set argv in NativeArguments.
  __ addq(RAX, Immediate(1 * kWordSize));  // Retval is next to 1st argument.
  __ movq(Address(RSP, retval_offset), RAX);  // Set retval in NativeArguments.
  __ call(RBX);

  // Reset exit frame information in Isolate structure.
  __ movq(Address(CTX, Isolate::top_exit_frame_info_offset()), Immediate(0));

  // Load Context pointer from Isolate structure into RBX.
  __ movq(RBX, Address(CTX, Isolate::top_context_offset()));

  // Reset Context pointer in Isolate structure.
  __ LoadObject(R12, Object::null_object(), PP);
  __ movq(Address(CTX, Isolate::top_context_offset()), R12);

  // Cache Context pointer into CTX while executing Dart code.
  __ movq(CTX, RBX);

  __ LeaveFrame();
  __ ret();
}


// Print the stop message.
DEFINE_LEAF_RUNTIME_ENTRY(void, PrintStopMessage, 1, const char* message) {
  OS::Print("Stop message: %s\n", message);
}
END_LEAF_RUNTIME_ENTRY


// Input parameters:
//   RSP : points to return address.
//   RDI : stop message (const char*).
// Must preserve all registers.
void StubCode::GeneratePrintStopMessageStub(Assembler* assembler) {
  __ EnterCallRuntimeFrame(0);
  // Call the runtime leaf function. RDI already contains the parameter.
  __ CallRuntime(kPrintStopMessageRuntimeEntry, 1);
  __ LeaveCallRuntimeFrame();
  __ ret();
}


// Input parameters:
//   RSP : points to return address.
//   RSP + 8 : address of return value.
//   RAX : address of first argument in argument array.
//   RBX : address of the native function to call.
//   R10 : argc_tag including number of arguments and function kind.
void StubCode::GenerateCallNativeCFunctionStub(Assembler* assembler) {
  const intptr_t native_args_struct_offset = 0;
  const intptr_t isolate_offset =
      NativeArguments::isolate_offset() + native_args_struct_offset;
  const intptr_t argc_tag_offset =
      NativeArguments::argc_tag_offset() + native_args_struct_offset;
  const intptr_t argv_offset =
      NativeArguments::argv_offset() + native_args_struct_offset;
  const intptr_t retval_offset =
      NativeArguments::retval_offset() + native_args_struct_offset;

  __ EnterFrame(0);

  // Load current Isolate pointer from Context structure into R8.
  __ movq(R8, FieldAddress(CTX, Context::isolate_offset()));

  // Save exit frame information to enable stack walking as we are about
  // to transition to native code.
  __ movq(Address(R8, Isolate::top_exit_frame_info_offset()), RSP);

  // Save current Context pointer into Isolate structure.
  __ movq(Address(R8, Isolate::top_context_offset()), CTX);

  // Cache Isolate pointer into CTX while executing native code.
  __ movq(CTX, R8);

  // Reserve space for the native arguments structure passed on the stack (the
  // outgoing pointer parameter to the native arguments structure is passed in
  // RDI) and align frame before entering the C++ world.
  __ subq(RSP, Immediate(sizeof(NativeArguments)));
  if (OS::ActivationFrameAlignment() > 1) {
    __ andq(RSP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass NativeArguments structure by value and call native function.
  __ movq(Address(RSP, isolate_offset), CTX);  // Set isolate in NativeArgs.
  __ movq(Address(RSP, argc_tag_offset), R10);  // Set argc in NativeArguments.
  __ movq(Address(RSP, argv_offset), RAX);  // Set argv in NativeArguments.
  __ leaq(RAX, Address(RBP, 2 * kWordSize));  // Compute return value addr.
  __ movq(Address(RSP, retval_offset), RAX);  // Set retval in NativeArguments.
  __ movq(RDI, RSP);  // Pass the pointer to the NativeArguments.

  // Call native function (setsup scope if not leaf function).
  Label leaf_call;
  Label done;
  __ testq(R10, Immediate(NativeArguments::AutoSetupScopeMask()));
  __ j(ZERO, &leaf_call);
  __ movq(RSI, RBX);  // Pass pointer to function entrypoint.
  __ call(&NativeEntry::NativeCallWrapperLabel());
  __ jmp(&done);
  __ Bind(&leaf_call);
  __ call(RBX);
  __ Bind(&done);

  // Reset exit frame information in Isolate structure.
  __ movq(Address(CTX, Isolate::top_exit_frame_info_offset()), Immediate(0));

  // Load Context pointer from Isolate structure into R8.
  __ movq(R8, Address(CTX, Isolate::top_context_offset()));

  // Reset Context pointer in Isolate structure.
  __ LoadObject(R12, Object::null_object(), PP);
  __ movq(Address(CTX, Isolate::top_context_offset()), R12);

  // Cache Context pointer into CTX while executing Dart code.
  __ movq(CTX, R8);

  __ LeaveFrame();
  __ ret();
}


// Input parameters:
//   RSP : points to return address.
//   RSP + 8 : address of return value.
//   RAX : address of first argument in argument array.
//   RBX : address of the native function to call.
//   R10 : argc_tag including number of arguments and function kind.
void StubCode::GenerateCallBootstrapCFunctionStub(Assembler* assembler) {
  const intptr_t native_args_struct_offset = 0;
  const intptr_t isolate_offset =
      NativeArguments::isolate_offset() + native_args_struct_offset;
  const intptr_t argc_tag_offset =
      NativeArguments::argc_tag_offset() + native_args_struct_offset;
  const intptr_t argv_offset =
      NativeArguments::argv_offset() + native_args_struct_offset;
  const intptr_t retval_offset =
      NativeArguments::retval_offset() + native_args_struct_offset;

  __ EnterFrame(0);

  // Load current Isolate pointer from Context structure into R8.
  __ movq(R8, FieldAddress(CTX, Context::isolate_offset()));

  // Save exit frame information to enable stack walking as we are about
  // to transition to native code.
  __ movq(Address(R8, Isolate::top_exit_frame_info_offset()), RSP);

  // Save current Context pointer into Isolate structure.
  __ movq(Address(R8, Isolate::top_context_offset()), CTX);

  // Cache Isolate pointer into CTX while executing native code.
  __ movq(CTX, R8);

  // Reserve space for the native arguments structure passed on the stack (the
  // outgoing pointer parameter to the native arguments structure is passed in
  // RDI) and align frame before entering the C++ world.
  __ subq(RSP, Immediate(sizeof(NativeArguments)));
  if (OS::ActivationFrameAlignment() > 1) {
    __ andq(RSP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass NativeArguments structure by value and call native function.
  __ movq(Address(RSP, isolate_offset), CTX);  // Set isolate in NativeArgs.
  __ movq(Address(RSP, argc_tag_offset), R10);  // Set argc in NativeArguments.
  __ movq(Address(RSP, argv_offset), RAX);  // Set argv in NativeArguments.
  __ leaq(RAX, Address(RBP, 2 * kWordSize));  // Compute return value addr.
  __ movq(Address(RSP, retval_offset), RAX);  // Set retval in NativeArguments.
  __ movq(RDI, RSP);  // Pass the pointer to the NativeArguments.
  __ call(RBX);

  // Reset exit frame information in Isolate structure.
  __ movq(Address(CTX, Isolate::top_exit_frame_info_offset()), Immediate(0));

  // Load Context pointer from Isolate structure into R8.
  __ movq(R8, Address(CTX, Isolate::top_context_offset()));

  // Reset Context pointer in Isolate structure.
  __ LoadObject(R12, Object::null_object(), PP);
  __ movq(Address(CTX, Isolate::top_context_offset()), R12);

  // Cache Context pointer into CTX while executing Dart code.
  __ movq(CTX, R8);

  __ LeaveFrame();
  __ ret();
}


// Input parameters:
//   R10: arguments descriptor array.
void StubCode::GenerateCallStaticFunctionStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ pushq(R10);  // Preserve arguments descriptor array.
  // Setup space on stack for return value.
  __ PushObject(Object::null_object(), PP);
  __ CallRuntime(kPatchStaticCallRuntimeEntry, 0);
  __ popq(RAX);  // Get Code object result.
  __ popq(R10);  // Restore arguments descriptor array.
  // Remove the stub frame as we are about to jump to the dart function.
  __ LeaveStubFrame();

  __ movq(RBX, FieldAddress(RAX, Code::instructions_offset()));
  __ addq(RBX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ jmp(RBX);
}


// Called from a static call only when an invalid code has been entered
// (invalid because its function was optimized or deoptimized).
// R10: arguments descriptor array.
void StubCode::GenerateFixCallersTargetStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ pushq(R10);  // Preserve arguments descriptor array.
  // Setup space on stack for return value.
  __ PushObject(Object::null_object(), PP);
  __ CallRuntime(kFixCallersTargetRuntimeEntry, 0);
  __ popq(RAX);  // Get Code object.
  __ popq(R10);  // Restore arguments descriptor array.
  __ movq(RAX, FieldAddress(RAX, Code::instructions_offset()));
  __ addq(RAX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ LeaveStubFrame();
  __ jmp(RAX);
  __ int3();
}


// Input parameters:
//   R10: smi-tagged argument count, may be zero.
//   RBP[kParamEndSlotFromFp + 1]: last argument.
static void PushArgumentsArray(Assembler* assembler) {
  __ LoadObject(R12, Object::null_object(), PP);
  // Allocate array to store arguments of caller.
  __ movq(RBX, R12);  // Null element type for raw Array.
  __ call(&StubCode::AllocateArrayLabel());
  __ SmiUntag(R10);
  // RAX: newly allocated array.
  // R10: length of the array (was preserved by the stub).
  __ pushq(RAX);  // Array is in RAX and on top of stack.
  __ leaq(R12, Address(RBP, R10, TIMES_8, kParamEndSlotFromFp * kWordSize));
  __ leaq(RBX, FieldAddress(RAX, Array::data_offset()));
  // R12: address of first argument on stack.
  // RBX: address of first argument in array.
  Label loop, loop_condition;
  __ jmp(&loop_condition, Assembler::kNearJump);
  __ Bind(&loop);
  __ movq(RAX, Address(R12, 0));
  __ movq(Address(RBX, 0), RAX);
  __ addq(RBX, Immediate(kWordSize));
  __ subq(R12, Immediate(kWordSize));
  __ Bind(&loop_condition);
  __ decq(R10);
  __ j(POSITIVE, &loop, Assembler::kNearJump);
}


// Input parameters:
//   RBX: ic-data.
//   R10: arguments descriptor array.
// Note: The receiver object is the first argument to the function being
//       called, the stub accesses the receiver from this location directly
//       when trying to resolve the call.
void StubCode::GenerateInstanceFunctionLookupStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ PushObject(Object::null_object(), PP);  // Space for the return value.

  // Push the receiver as an argument.  Load the smi-tagged argument
  // count into R13 to index the receiver in the stack.  There are
  // four words (null, stub's pc marker, saved pp, saved fp) above the return
  // address.
  __ movq(R13, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
  __ pushq(Address(RSP, R13, TIMES_4, (4 * kWordSize)));

  __ pushq(RBX);  // Pass IC data object.
  __ pushq(R10);  // Pass arguments descriptor array.

  // Pass the call's arguments array.
  __ movq(R10, R13);  // Smi-tagged arguments array length.
  PushArgumentsArray(assembler);

  __ CallRuntime(kInstanceFunctionLookupRuntimeEntry, 4);

  // Remove arguments.
  __ Drop(4);
  __ popq(RAX);  // Get result into RAX.
  __ LeaveStubFrame();
  __ ret();
}


DECLARE_LEAF_RUNTIME_ENTRY(intptr_t, DeoptimizeCopyFrame,
                           intptr_t deopt_reason,
                           uword saved_registers_address);

DECLARE_LEAF_RUNTIME_ENTRY(void, DeoptimizeFillFrame, uword last_fp);


// Used by eager and lazy deoptimization. Preserve result in RAX if necessary.
// This stub translates optimized frame into unoptimized frame. The optimized
// frame can contain values in registers and on stack, the unoptimized
// frame contains all values on stack.
// Deoptimization occurs in following steps:
// - Push all registers that can contain values.
// - Call C routine to copy the stack and saved registers into temporary buffer.
// - Adjust caller's frame to correct unoptimized frame size.
// - Fill the unoptimized frame.
// - Materialize objects that require allocation (e.g. Double instances).
// GC can occur only after frame is fully rewritten.
// Stack after EnterDartFrame(0, PP, kNoRegister) below:
//   +------------------+
//   | Saved PP         | <- PP
//   +------------------+
//   | PC marker        | <- TOS
//   +------------------+
//   | Saved FP         | <- FP of stub
//   +------------------+
//   | return-address   |  (deoptimization point)
//   +------------------+
//   | ...              | <- SP of optimized frame
//
// Parts of the code cannot GC, part of the code can GC.
static void GenerateDeoptimizationSequence(Assembler* assembler,
                                           bool preserve_result) {
  // DeoptimizeCopyFrame expects a Dart frame, i.e. EnterDartFrame(0), but there
  // is no need to set the correct PC marker or load PP, since they get patched.
  __ EnterFrame(0);
  __ pushq(Immediate(0));
  __ pushq(PP);

  // The code in this frame may not cause GC. kDeoptimizeCopyFrameRuntimeEntry
  // and kDeoptimizeFillFrameRuntimeEntry are leaf runtime calls.
  const intptr_t saved_result_slot_from_fp =
      kFirstLocalSlotFromFp + 1 - (kNumberOfCpuRegisters - RAX);
  // Result in RAX is preserved as part of pushing all registers below.

  // Push registers in their enumeration order: lowest register number at
  // lowest address.
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; i--) {
    __ pushq(static_cast<Register>(i));
  }
  __ subq(RSP, Immediate(kNumberOfXmmRegisters * kFpuRegisterSize));
  intptr_t offset = 0;
  for (intptr_t reg_idx = 0; reg_idx < kNumberOfXmmRegisters; ++reg_idx) {
    XmmRegister xmm_reg = static_cast<XmmRegister>(reg_idx);
    __ movups(Address(RSP, offset), xmm_reg);
    offset += kFpuRegisterSize;
  }

  __ movq(RDI, RSP);  // Pass address of saved registers block.
  __ ReserveAlignedFrameSpace(0);
  __ CallRuntime(kDeoptimizeCopyFrameRuntimeEntry, 1);
  // Result (RAX) is stack-size (FP - SP) in bytes.

  if (preserve_result) {
    // Restore result into RBX temporarily.
    __ movq(RBX, Address(RBP, saved_result_slot_from_fp * kWordSize));
  }

  // There is a Dart Frame on the stack. We must restore PP and leave frame.
  __ LeaveDartFrame();

  __ popq(RCX);   // Preserve return address.
  __ movq(RSP, RBP);  // Discard optimized frame.
  __ subq(RSP, RAX);  // Reserve space for deoptimized frame.
  __ pushq(RCX);  // Restore return address.

  // DeoptimizeFillFrame expects a Dart frame, i.e. EnterDartFrame(0), but there
  // is no need to set the correct PC marker or load PP, since they get patched.
  __ EnterFrame(0);
  __ pushq(Immediate(0));
  __ pushq(PP);

  if (preserve_result) {
    __ pushq(RBX);  // Preserve result as first local.
  }
  __ ReserveAlignedFrameSpace(0);
  __ movq(RDI, RBP);  // Pass last FP as parameter in RDI.
  __ CallRuntime(kDeoptimizeFillFrameRuntimeEntry, 1);
  if (preserve_result) {
    // Restore result into RBX.
    __ movq(RBX, Address(RBP, kFirstLocalSlotFromFp * kWordSize));
  }
  // Code above cannot cause GC.
  // There is a Dart Frame on the stack. We must restore PP and leave frame.
  __ LeaveDartFrame();

  // Frame is fully rewritten at this point and it is safe to perform a GC.
  // Materialize any objects that were deferred by FillFrame because they
  // require allocation.
  __ EnterStubFrame();
  if (preserve_result) {
    __ pushq(Immediate(0));  // Workaround for dropped stack slot during GC.
    __ pushq(RBX);  // Preserve result, it will be GC-d here.
  }
  __ pushq(Immediate(Smi::RawValue(0)));  // Space for the result.
  __ CallRuntime(kDeoptimizeMaterializeRuntimeEntry, 0);
  // Result tells stub how many bytes to remove from the expression stack
  // of the bottom-most frame. They were used as materialization arguments.
  __ popq(RBX);
  __ SmiUntag(RBX);
  if (preserve_result) {
    __ popq(RAX);  // Restore result.
    __ Drop(1);  // Workaround for dropped stack slot during GC.
  }
  __ LeaveStubFrame();

  __ popq(RCX);  // Pop return address.
  __ addq(RSP, RBX);  // Remove materialization arguments.
  __ pushq(RCX);  // Push return address.
  __ ret();
}


// TOS: return address + call-instruction-size (5 bytes).
// RAX: result, must be preserved
void StubCode::GenerateDeoptimizeLazyStub(Assembler* assembler) {
  // Correct return address to point just after the call that is being
  // deoptimized.
  __ popq(RBX);
  __ subq(RBX, Immediate(ShortCallPattern::InstructionLength()));
  __ pushq(RBX);
  GenerateDeoptimizationSequence(assembler, true);  // Preserve RAX.
}


void StubCode::GenerateDeoptimizeStub(Assembler* assembler) {
  GenerateDeoptimizationSequence(assembler, false);  // Don't preserve RAX.
}


void StubCode::GenerateMegamorphicMissStub(Assembler* assembler) {
  __ EnterStubFrame();
  // Load the receiver into RAX.  The argument count in the arguments
  // descriptor in R10 is a smi.
  __ movq(RAX, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
  // Three words (saved pp, saved fp, stub's pc marker)
  // in the stack above the return address.
  __ movq(RAX, Address(RSP, RAX, TIMES_4,
                       kSavedAboveReturnAddress * kWordSize));
  // Preserve IC data and arguments descriptor.
  __ pushq(RBX);
  __ pushq(R10);

  // Space for the result of the runtime call.
  __ PushObject(Object::null_object(), PP);
  __ pushq(RAX);  // Receiver.
  __ pushq(RBX);  // IC data.
  __ pushq(R10);  // Arguments descriptor.
  __ CallRuntime(kMegamorphicCacheMissHandlerRuntimeEntry, 3);
  // Discard arguments.
  __ popq(RAX);
  __ popq(RAX);
  __ popq(RAX);
  __ popq(RAX);  // Return value from the runtime call (instructions).
  __ popq(R10);  // Restore arguments descriptor.
  __ popq(RBX);  // Restore IC data.
  __ LeaveStubFrame();

  Label lookup;
  __ CompareObject(RAX, Object::null_object(), PP);
  __ j(EQUAL, &lookup, Assembler::kNearJump);
  __ addq(RAX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ jmp(RAX);

  __ Bind(&lookup);
  __ jmp(&StubCode::InstanceFunctionLookupLabel());
}


// Called for inline allocation of arrays.
// Input parameters:
//   R10 : Array length as Smi.
//   RBX : array element type (either NULL or an instantiated type).
// NOTE: R10 cannot be clobbered here as the caller relies on it being saved.
// The newly allocated object is returned in RAX.
void StubCode::GenerateAllocateArrayStub(Assembler* assembler) {
  Label slow_case;

  if (FLAG_inline_alloc) {
    // Compute the size to be allocated, it is based on the array length
    // and is computed as:
    // RoundedAllocationSize((array_length * kwordSize) + sizeof(RawArray)).
    // Assert that length is a Smi.
    __ testq(R10, Immediate(kSmiTagMask));
    if (FLAG_use_slow_path) {
      __ jmp(&slow_case);
    } else {
      __ j(NOT_ZERO, &slow_case);
    }
    __ movq(R13, FieldAddress(CTX, Context::isolate_offset()));
    __ movq(R13, Address(R13, Isolate::heap_offset()));
    __ movq(R13, Address(R13, Heap::new_space_offset()));

    // Calculate and align allocation size.
    // Load new object start and calculate next object start.
    // RBX: array element type.
    // R10: Array length as Smi.
    // R13: Points to new space object.
    __ movq(RAX, Address(R13, Scavenger::top_offset()));
    intptr_t fixed_size = sizeof(RawArray) + kObjectAlignment - 1;
    __ leaq(R12, Address(R10, TIMES_4, fixed_size));  // R10 is Smi.
    ASSERT(kSmiTagShift == 1);
    __ andq(R12, Immediate(-kObjectAlignment));
    __ leaq(R12, Address(RAX, R12, TIMES_1, 0));

    // Check if the allocation fits into the remaining space.
    // RAX: potential new object start.
    // R12: potential next object start.
    // RBX: array element type.
    // R10: Array length as Smi.
    // R13: Points to new space object.
    __ cmpq(R12, Address(R13, Scavenger::end_offset()));
    __ j(ABOVE_EQUAL, &slow_case);

    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    // RAX: potential new object start.
    // R12: potential next object start.
    // R13: Points to new space object.
    __ movq(Address(R13, Scavenger::top_offset()), R12);
    __ addq(RAX, Immediate(kHeapObjectTag));
    // R13: Size of allocation in bytes.
    __ movq(R13, R12);
    __ subq(R13, RAX);
    __ UpdateAllocationStatsWithSize(kArrayCid, R13);

    // RAX: new object start as a tagged pointer.
    // R12: new object end address.
    // RBX: array element type.
    // R10: Array length as Smi.

    // Store the type argument field.
    __ StoreIntoObjectNoBarrier(
        RAX, FieldAddress(RAX, Array::type_arguments_offset()), RBX);

    // Set the length field.
    __ StoreIntoObjectNoBarrier(
        RAX, FieldAddress(RAX, Array::length_offset()), R10);

    // Calculate the size tag.
    // RAX: new object start as a tagged pointer.
    // R12: new object end address.
    // R10: Array length as Smi.
    {
      Label size_tag_overflow, done;
      __ leaq(RBX, Address(R10, TIMES_4, fixed_size));  // R10 is Smi.
      ASSERT(kSmiTagShift == 1);
      __ andq(RBX, Immediate(-kObjectAlignment));
      __ cmpq(RBX, Immediate(RawObject::SizeTag::kMaxSizeTag));
      __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
      __ shlq(RBX, Immediate(RawObject::kSizeTagBit - kObjectAlignmentLog2));
      __ jmp(&done);

      __ Bind(&size_tag_overflow);
      __ movq(RBX, Immediate(0));
      __ Bind(&done);

      // Get the class index and insert it into the tags.
      __ orq(RBX, Immediate(RawObject::ClassIdTag::encode(kArrayCid)));
      __ movq(FieldAddress(RAX, Array::tags_offset()), RBX);
    }

    // Initialize all array elements to raw_null.
    // RAX: new object start as a tagged pointer.
    // R12: new object end address.
    // R10: Array length as Smi.
    __ leaq(RBX, FieldAddress(RAX, Array::data_offset()));
    // RBX: iterator which initially points to the start of the variable
    // data area to be initialized.
    __ LoadObject(R13, Object::null_object(), PP);
    Label done;
    Label init_loop;
    __ Bind(&init_loop);
    __ cmpq(RBX, R12);
    __ j(ABOVE_EQUAL, &done, Assembler::kNearJump);
    // TODO(cshapiro): StoreIntoObjectNoBarrier
    __ movq(Address(RBX, 0), R13);
    __ addq(RBX, Immediate(kWordSize));
    __ jmp(&init_loop, Assembler::kNearJump);
    __ Bind(&done);

    // Done allocating and initializing the array.
    // RAX: new object.
    // R10: Array length as Smi (preserved for the caller.)
    __ ret();
  }

  // Unable to allocate the array using the fast inline code, just call
  // into the runtime.
  __ Bind(&slow_case);
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value.
  __ PushObject(Object::null_object(), PP);
  __ pushq(R10);  // Array length as Smi.
  __ pushq(RBX);  // Element type.
  __ CallRuntime(kAllocateArrayRuntimeEntry, 2);
  __ popq(RAX);  // Pop element type argument.
  __ popq(R10);  // Pop array length argument.
  __ popq(RAX);  // Pop return value from return slot.
  __ LeaveStubFrame();
  __ ret();
}


// Input parameters:
//   R10: Arguments descriptor array.
// Note: The closure object is the first argument to the function being
//       called, the stub accesses the closure from this location directly
//       when trying to resolve the call.
void StubCode::GenerateCallClosureFunctionStub(Assembler* assembler) {
  // Load num_args.
  __ movq(RAX, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
  // Load closure object in R13.
  __ movq(R13, Address(RSP, RAX, TIMES_4, 0));  // RAX is a Smi.

  __ LoadObject(R12, Object::null_object(), PP);

  // Verify that R13 is a closure by checking its class.
  Label not_closure;
  __ cmpq(R13, R12);
  // Not a closure, but null object.
  __ j(EQUAL, &not_closure);
  __ testq(R13, Immediate(kSmiTagMask));
  __ j(ZERO, &not_closure);  // Not a closure, but a smi.
  // Verify that the class of the object is a closure class by checking that
  // class.signature_function() is not null.
  __ LoadClass(RAX, R13);
  __ movq(RAX, FieldAddress(RAX, Class::signature_function_offset()));
  __ cmpq(RAX, R12);
  // Actual class is not a closure class.
  __ j(EQUAL, &not_closure, Assembler::kNearJump);

  // RAX is just the signature function. Load the actual closure function.
  __ movq(RBX, FieldAddress(R13, Closure::function_offset()));

  // Load closure context in CTX; note that CTX has already been preserved.
  __ movq(CTX, FieldAddress(R13, Closure::context_offset()));

  // Load closure function code in RAX.
  __ movq(RAX, FieldAddress(RBX, Function::code_offset()));
  __ cmpq(RAX, R12);
  Label function_compiled;
  __ j(NOT_EQUAL, &function_compiled, Assembler::kNearJump);

  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();

  __ pushq(R10);  // Preserve arguments descriptor array.
  __ pushq(RBX);  // Preserve read-only function object argument.
  __ CallRuntime(kCompileFunctionRuntimeEntry, 1);
  __ popq(RBX);  // Restore read-only function object argument in RBX.
  __ popq(R10);  // Restore arguments descriptor array.
  // Restore RAX.
  __ movq(RAX, FieldAddress(RBX, Function::code_offset()));

  // Remove the stub frame as we are about to jump to the closure function.
  __ LeaveStubFrame();

  __ Bind(&function_compiled);
  // RAX: Code.
  // RBX: Function.
  // R10: Arguments descriptor array.

  __ movq(RBX, FieldAddress(RAX, Code::instructions_offset()));
  __ addq(RBX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ jmp(RBX);

  __ Bind(&not_closure);
  // Call runtime to attempt to resolve and invoke a call method on a
  // non-closure object, passing the non-closure object and its arguments array,
  // returning here.
  // If no call method exists, throw a NoSuchMethodError.
  // R13: non-closure object.
  // R10: arguments descriptor array.

  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for result from call.
  __ pushq(R12);
  __ pushq(R10);  // Arguments descriptor.
  // Load smi-tagged arguments array length, including the non-closure.
  __ movq(R10, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
  PushArgumentsArray(assembler);

  __ CallRuntime(kInvokeNonClosureRuntimeEntry, 2);

  // Remove arguments.
  __ Drop(2);
  __ popq(RAX);  // Get result into RAX.

  // Remove the stub frame as we are about to return.
  __ LeaveStubFrame();
  __ ret();
}


// Called when invoking Dart code from C++ (VM code).
// Input parameters:
//   RSP : points to return address.
//   RDI : entrypoint of the Dart function to call.
//   RSI : arguments descriptor array.
//   RDX : arguments array.
//   RCX : new context containing the current isolate pointer.
void StubCode::GenerateInvokeDartCodeStub(Assembler* assembler) {
  // Save frame pointer coming in.
  __ EnterFrame(0);

  // At this point, the stack looks like:
  // | saved RBP                                      | <-- RBP
  // | saved PC (return to DartEntry::InvokeFunction) |

  const intptr_t kInitialOffset = 1;
  // Save arguments descriptor array and new context.
  const intptr_t kArgumentsDescOffset = -(kInitialOffset) * kWordSize;
  __ pushq(RSI);
  const intptr_t kNewContextOffset = -(kInitialOffset + 1) * kWordSize;
  __ pushq(RCX);

  // Save C++ ABI callee-saved registers.
  __ pushq(RBX);
  __ pushq(R12);
  __ pushq(R13);
  __ pushq(R14);
  __ pushq(R15);

  // We now load the pool pointer(PP) as we are about to invoke dart code and we
  // could potentially invoke some intrinsic functions which need the PP to be
  // set up.
  __ LoadPoolPointer(PP);

  // If any additional (or fewer) values are pushed, the offsets in
  // kExitLinkSlotFromEntryFp and kSavedContextSlotFromEntryFp will need to be
  // changed.

  // The new Context structure contains a pointer to the current Isolate
  // structure. Cache the Context pointer in the CTX register so that it is
  // available in generated code and calls to Isolate::Current() need not be
  // done. The assumption is that this register will never be clobbered by
  // compiled or runtime stub code.

  // Cache the new Context pointer into CTX while executing Dart code.
  __ movq(CTX, Address(RCX, VMHandles::kOffsetOfRawPtrInHandle));

  // Load Isolate pointer from Context structure into R8.
  __ movq(R8, FieldAddress(CTX, Context::isolate_offset()));

  // Save the top exit frame info. Use RAX as a temporary register.
  // StackFrameIterator reads the top exit frame info saved in this frame.
  // The constant kExitLinkSlotFromEntryFp must be kept in sync with the
  // code below.
  ASSERT(kExitLinkSlotFromEntryFp == -8);
  __ movq(RAX, Address(R8, Isolate::top_exit_frame_info_offset()));
  __ pushq(RAX);
  __ movq(Address(R8, Isolate::top_exit_frame_info_offset()), Immediate(0));

  // Save the old Context pointer. Use RAX as a temporary register.
  // Note that VisitObjectPointers will find this saved Context pointer during
  // GC marking, since it traverses any information between SP and
  // FP - kExitLinkSlotFromEntryFp * kWordSize.
  // EntryFrame::SavedContext reads the context saved in this frame.
  // The constant kSavedContextSlotFromEntryFp must be kept in sync with
  // the code below.
  ASSERT(kSavedContextSlotFromEntryFp == -9);
  __ movq(RAX, Address(R8, Isolate::top_context_offset()));
  __ pushq(RAX);

  // Load arguments descriptor array into R10, which is passed to Dart code.
  __ movq(R10, Address(RSI, VMHandles::kOffsetOfRawPtrInHandle));

  // Load number of arguments into RBX.
  __ movq(RBX, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
  __ SmiUntag(RBX);

  // Compute address of 'arguments array' data area into RDX.
  __ movq(RDX, Address(RDX, VMHandles::kOffsetOfRawPtrInHandle));
  __ leaq(RDX, FieldAddress(RDX, Array::data_offset()));

  // Set up arguments for the Dart call.
  Label push_arguments;
  Label done_push_arguments;
  __ testq(RBX, RBX);  // check if there are arguments.
  __ j(ZERO, &done_push_arguments, Assembler::kNearJump);
  __ movq(RAX, Immediate(0));
  __ Bind(&push_arguments);
  __ movq(RCX, Address(RDX, RAX, TIMES_8, 0));  // RDX is start of arguments.
  __ pushq(RCX);
  __ incq(RAX);
  __ cmpq(RAX, RBX);
  __ j(LESS, &push_arguments, Assembler::kNearJump);
  __ Bind(&done_push_arguments);

  // Call the Dart code entrypoint.
  __ call(RDI);  // R10 is the arguments descriptor array.

  // Read the saved new Context pointer.
  __ movq(CTX, Address(RBP, kNewContextOffset));
  __ movq(CTX, Address(CTX, VMHandles::kOffsetOfRawPtrInHandle));

  // Read the saved arguments descriptor array to obtain the number of passed
  // arguments.
  __ movq(RSI, Address(RBP, kArgumentsDescOffset));
  __ movq(R10, Address(RSI, VMHandles::kOffsetOfRawPtrInHandle));
  __ movq(RDX, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
  // Get rid of arguments pushed on the stack.
  __ leaq(RSP, Address(RSP, RDX, TIMES_4, 0));  // RDX is a Smi.

  // Load Isolate pointer from Context structure into CTX. Drop Context.
  __ movq(CTX, FieldAddress(CTX, Context::isolate_offset()));

  // Restore the saved Context pointer into the Isolate structure.
  // Uses RCX as a temporary register for this.
  __ popq(RCX);
  __ movq(Address(CTX, Isolate::top_context_offset()), RCX);

  // Restore the saved top exit frame info back into the Isolate structure.
  // Uses RDX as a temporary register for this.
  __ popq(RDX);
  __ movq(Address(CTX, Isolate::top_exit_frame_info_offset()), RDX);

  // Restore C++ ABI callee-saved registers.
  __ popq(R15);
  __ popq(R14);
  __ popq(R13);
  __ popq(R12);
  __ popq(RBX);

  // Restore the frame pointer.
  __ LeaveFrame();

  __ ret();
}


// Called for inline allocation of contexts.
// Input:
// R10: number of context variables.
// Output:
// RAX: new allocated RawContext object.
void StubCode::GenerateAllocateContextStub(Assembler* assembler) {
  __ LoadObject(R12, Object::null_object(), PP);
  if (FLAG_inline_alloc) {
    const Class& context_class = Class::ZoneHandle(Object::context_class());
    Label slow_case;
    Heap* heap = Isolate::Current()->heap();
    // First compute the rounded instance size.
    // R10: number of context variables.
    intptr_t fixed_size = (sizeof(RawContext) + kObjectAlignment - 1);
    __ leaq(R13, Address(R10, TIMES_8, fixed_size));
    __ andq(R13, Immediate(-kObjectAlignment));

    // Now allocate the object.
    // R10: number of context variables.
    __ movq(RAX, Immediate(heap->TopAddress()));
    __ movq(RAX, Address(RAX, 0));
    __ addq(R13, RAX);
    // Check if the allocation fits into the remaining space.
    // RAX: potential new object.
    // R13: potential next object start.
    // R10: number of context variables.
    __ movq(RDI, Immediate(heap->EndAddress()));
    __ cmpq(R13, Address(RDI, 0));
    if (FLAG_use_slow_path) {
      __ jmp(&slow_case);
    } else {
      __ j(ABOVE_EQUAL, &slow_case);
    }

    // Successfully allocated the object, now update top to point to
    // next object start and initialize the object.
    // RAX: new object.
    // R13: next object start.
    // R10: number of context variables.
    __ movq(RDI, Immediate(heap->TopAddress()));
    __ movq(Address(RDI, 0), R13);
    __ addq(RAX, Immediate(kHeapObjectTag));
    // R13: Size of allocation in bytes.
    __ subq(R13, RAX);
    __ UpdateAllocationStatsWithSize(context_class.id(), R13);

    // Calculate the size tag.
    // RAX: new object.
    // R10: number of context variables.
    {
      Label size_tag_overflow, done;
      __ leaq(R13, Address(R10, TIMES_8, fixed_size));
      __ andq(R13, Immediate(-kObjectAlignment));
      __ cmpq(R13, Immediate(RawObject::SizeTag::kMaxSizeTag));
      __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
      __ shlq(R13, Immediate(RawObject::kSizeTagBit - kObjectAlignmentLog2));
      __ jmp(&done);

      __ Bind(&size_tag_overflow);
      // Set overflow size tag value.
      __ movq(R13, Immediate(0));

      __ Bind(&done);
      // RAX: new object.
      // R10: number of context variables.
      // R13: size and bit tags.
      __ orq(R13,
             Immediate(RawObject::ClassIdTag::encode(context_class.id())));
      __ movq(FieldAddress(RAX, Context::tags_offset()), R13);  // Tags.
    }

    // Setup up number of context variables field.
    // RAX: new object.
    // R10: number of context variables as integer value (not object).
    __ movq(FieldAddress(RAX, Context::num_variables_offset()), R10);

    // Setup isolate field.
    // Load Isolate pointer from Context structure into R13.
    // RAX: new object.
    // R10: number of context variables.
    __ movq(R13, FieldAddress(CTX, Context::isolate_offset()));
    // R13: Isolate, not an object.
    __ movq(FieldAddress(RAX, Context::isolate_offset()), R13);

    // Setup the parent field.
    // RAX: new object.
    // R10: number of context variables.
    __ movq(FieldAddress(RAX, Context::parent_offset()), R12);

    // Initialize the context variables.
    // RAX: new object.
    // R10: number of context variables.
    {
      Label loop, entry;
      __ leaq(R13, FieldAddress(RAX, Context::variable_offset(0)));

      __ jmp(&entry, Assembler::kNearJump);
      __ Bind(&loop);
      __ decq(R10);
      __ movq(Address(R13, R10, TIMES_8, 0), R12);
      __ Bind(&entry);
      __ cmpq(R10, Immediate(0));
      __ j(NOT_EQUAL, &loop, Assembler::kNearJump);
    }

    // Done allocating and initializing the context.
    // RAX: new object.
    __ ret();

    __ Bind(&slow_case);
  }
  // Create a stub frame.
  __ EnterStubFrame();
  __ pushq(R12);  // Setup space on stack for the return value.
  __ SmiTag(R10);
  __ pushq(R10);  // Push number of context variables.
  __ CallRuntime(kAllocateContextRuntimeEntry, 1);  // Allocate context.
  __ popq(RAX);  // Pop number of context variables argument.
  __ popq(RAX);  // Pop the new context object.
  // RAX: new object
  // Restore the frame pointer.
  __ LeaveStubFrame();
  __ ret();
}


DECLARE_LEAF_RUNTIME_ENTRY(void, StoreBufferBlockProcess, Isolate* isolate);

// Helper stub to implement Assembler::StoreIntoObject.
// Input parameters:
//   RAX: Address being stored
void StubCode::GenerateUpdateStoreBufferStub(Assembler* assembler) {
  // Save registers being destroyed.
  __ pushq(RDX);
  __ pushq(RCX);

  Label add_to_buffer;
  // Check whether this object has already been remembered. Skip adding to the
  // store buffer if the object is in the store buffer already.
  // Spilled: RDX, RCX
  // RAX: Address being stored
  __ movq(RCX, FieldAddress(RAX, Object::tags_offset()));
  __ testq(RCX, Immediate(1 << RawObject::kRememberedBit));
  __ j(EQUAL, &add_to_buffer, Assembler::kNearJump);
  __ popq(RCX);
  __ popq(RDX);
  __ ret();

  __ Bind(&add_to_buffer);
  __ orq(RCX, Immediate(1 << RawObject::kRememberedBit));
  __ movq(FieldAddress(RAX, Object::tags_offset()), RCX);

  // Load the isolate out of the context.
  // RAX: Address being stored
  __ movq(RDX, FieldAddress(CTX, Context::isolate_offset()));

  // Load the StoreBuffer block out of the isolate. Then load top_ out of the
  // StoreBufferBlock and add the address to the pointers_.
  // RAX: Address being stored
  // RDX: Isolate
  __ movq(RDX, Address(RDX, Isolate::store_buffer_offset()));
  __ movl(RCX, Address(RDX, StoreBufferBlock::top_offset()));
  __ movq(Address(RDX, RCX, TIMES_8, StoreBufferBlock::pointers_offset()), RAX);

  // Increment top_ and check for overflow.
  // RCX: top_
  // RDX: StoreBufferBlock
  Label L;
  __ incq(RCX);
  __ movl(Address(RDX, StoreBufferBlock::top_offset()), RCX);
  __ cmpl(RCX, Immediate(StoreBufferBlock::kSize));
  // Restore values.
  __ popq(RCX);
  __ popq(RDX);
  __ j(EQUAL, &L, Assembler::kNearJump);
  __ ret();

  // Handle overflow: Call the runtime leaf function.
  __ Bind(&L);
  // Setup frame, push callee-saved registers.
  __ EnterCallRuntimeFrame(0);
  __ movq(RDI, FieldAddress(CTX, Context::isolate_offset()));
  __ CallRuntime(kStoreBufferBlockProcessRuntimeEntry, 1);
  __ LeaveCallRuntimeFrame();
  __ ret();
}


// Called for inline allocation of objects.
// Input parameters:
//   RSP + 8 : type arguments object (only if class is parameterized).
//   RSP : points to return address.
void StubCode::GenerateAllocationStubForClass(Assembler* assembler,
                                              const Class& cls) {
  const intptr_t kObjectTypeArgumentsOffset = 1 * kWordSize;
  // The generated code is different if the class is parameterized.
  const bool is_cls_parameterized = cls.NumTypeArguments() > 0;
  ASSERT(!is_cls_parameterized ||
         (cls.type_arguments_field_offset() != Class::kNoTypeArguments));
  // kInlineInstanceSize is a constant used as a threshold for determining
  // when the object initialization should be done as a loop or as
  // straight line code.
  const int kInlineInstanceSize = 12;  // In words.
  const intptr_t instance_size = cls.instance_size();
  ASSERT(instance_size > 0);
  __ LoadObject(R12, Object::null_object(), PP);
  if (is_cls_parameterized) {
    __ movq(RDX, Address(RSP, kObjectTypeArgumentsOffset));
    // RDX: instantiated type arguments.
  }
  if (FLAG_inline_alloc && Heap::IsAllocatableInNewSpace(instance_size)) {
    Label slow_case;
    // Allocate the object and update top to point to
    // next object start and initialize the allocated object.
    // RDX: instantiated type arguments (if is_cls_parameterized).
    Heap* heap = Isolate::Current()->heap();
    __ movq(RCX, Immediate(heap->TopAddress()));
    __ movq(RAX, Address(RCX, 0));
    __ leaq(RBX, Address(RAX, instance_size));
    // Check if the allocation fits into the remaining space.
    // RAX: potential new object start.
    // RBX: potential next object start.
    // RCX: heap top address.
    __ movq(R13, Immediate(heap->EndAddress()));
    __ cmpq(RBX, Address(R13, 0));
    if (FLAG_use_slow_path) {
      __ jmp(&slow_case);
    } else {
      __ j(ABOVE_EQUAL, &slow_case);
    }
    __ movq(Address(RCX, 0), RBX);
    __ UpdateAllocationStats(cls.id());

    // RAX: new object start.
    // RBX: next object start.
    // RDX: new object type arguments (if is_cls_parameterized).
    // Set the tags.
    uword tags = 0;
    tags = RawObject::SizeTag::update(instance_size, tags);
    ASSERT(cls.id() != kIllegalCid);
    tags = RawObject::ClassIdTag::update(cls.id(), tags);
    __ movq(Address(RAX, Instance::tags_offset()), Immediate(tags));

    // Initialize the remaining words of the object.
    // RAX: new object start.
    // RBX: next object start.
    // RDX: new object type arguments (if is_cls_parameterized).
    // R12: raw null.
    // First try inlining the initialization without a loop.
    if (instance_size < (kInlineInstanceSize * kWordSize)) {
      // Check if the object contains any non-header fields.
      // Small objects are initialized using a consecutive set of writes.
      for (intptr_t current_offset = Instance::NextFieldOffset();
           current_offset < instance_size;
           current_offset += kWordSize) {
        __ movq(Address(RAX, current_offset), R12);
      }
    } else {
      __ leaq(RCX, Address(RAX, Instance::NextFieldOffset()));
      // Loop until the whole object is initialized.
      // RAX: new object.
      // RBX: next object start.
      // RCX: next word to be initialized.
      // RDX: new object type arguments (if is_cls_parameterized).
      Label init_loop;
      Label done;
      __ Bind(&init_loop);
      __ cmpq(RCX, RBX);
      __ j(ABOVE_EQUAL, &done, Assembler::kNearJump);
      __ movq(Address(RCX, 0), R12);
      __ addq(RCX, Immediate(kWordSize));
      __ jmp(&init_loop, Assembler::kNearJump);
      __ Bind(&done);
    }
    if (is_cls_parameterized) {
      // RDX: new object type arguments.
      // Set the type arguments in the new object.
      __ movq(Address(RAX, cls.type_arguments_field_offset()), RDX);
    }
    // Done allocating and initializing the instance.
    // RAX: new object.
    __ addq(RAX, Immediate(kHeapObjectTag));
    __ ret();

    __ Bind(&slow_case);
  }
  // If is_cls_parameterized:
  // RDX: new object type arguments.
  // Create a stub frame.
  __ EnterStubFrame(true);  // Uses PP to access class object.
  __ pushq(R12);  // Setup space on stack for return value.
  __ PushObject(cls, PP);  // Push class of object to be allocated.
  if (is_cls_parameterized) {
    __ pushq(RDX);  // Push type arguments of object to be allocated.
  } else {
    __ pushq(R12);  // Push null type arguments.
  }
  __ CallRuntime(kAllocateObjectRuntimeEntry, 2);  // Allocate object.
  __ popq(RAX);  // Pop argument (type arguments of object).
  __ popq(RAX);  // Pop argument (class of object).
  __ popq(RAX);  // Pop result (newly allocated object).
  // RAX: new object
  // Restore the frame pointer.
  __ LeaveStubFrame();
  __ ret();
}


// Called for invoking "dynamic noSuchMethod(Invocation invocation)" function
// from the entry code of a dart function after an error in passed argument
// name or number is detected.
// Input parameters:
//   RSP : points to return address.
//   RSP + 8 : address of last argument.
//   RBX : ic-data.
//   R10 : arguments descriptor array.
void StubCode::GenerateCallNoSuchMethodFunctionStub(Assembler* assembler) {
  __ EnterStubFrame();

  // Load the receiver.
  __ movq(R13, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
  __ movq(RAX, Address(RBP, R13, TIMES_4, kParamEndSlotFromFp * kWordSize));

  __ LoadObject(R12, Object::null_object(), PP);
  __ pushq(R12);  // Setup space on stack for result from noSuchMethod.
  __ pushq(RAX);  // Receiver.
  __ pushq(RBX);  // IC data array.
  __ pushq(R10);  // Arguments descriptor array.

  __ movq(R10, R13);  // Smi-tagged arguments array length.
  PushArgumentsArray(assembler);

  __ CallRuntime(kInvokeNoSuchMethodFunctionRuntimeEntry, 4);

  // Remove arguments.
  __ Drop(4);
  __ popq(RAX);  // Get result into RAX.

  // Remove the stub frame as we are about to return.
  __ LeaveStubFrame();
  __ ret();
}


// Cannot use function object from ICData as it may be the inlined
// function and not the top-scope function.
void StubCode::GenerateOptimizedUsageCounterIncrement(Assembler* assembler) {
  Register ic_reg = RBX;
  Register func_reg = RDI;
  if (FLAG_trace_optimized_ic_calls) {
    __ EnterStubFrame();
    __ pushq(func_reg);     // Preserve
    __ pushq(ic_reg);       // Preserve.
    __ pushq(ic_reg);       // Argument.
    __ pushq(func_reg);     // Argument.
    __ CallRuntime(kTraceICCallRuntimeEntry, 2);
    __ popq(RAX);          // Discard argument;
    __ popq(RAX);          // Discard argument;
    __ popq(ic_reg);       // Restore.
    __ popq(func_reg);     // Restore.
    __ LeaveStubFrame();
  }
  __ incq(FieldAddress(func_reg, Function::usage_counter_offset()));
}


// Loads function into 'temp_reg', preserves 'ic_reg'.
void StubCode::GenerateUsageCounterIncrement(Assembler* assembler,
                                             Register temp_reg) {
  Register ic_reg = RBX;
  Register func_reg = temp_reg;
  ASSERT(ic_reg != func_reg);
  __ movq(func_reg, FieldAddress(ic_reg, ICData::function_offset()));
  __ incq(FieldAddress(func_reg, Function::usage_counter_offset()));
}


// Generate inline cache check for 'num_args'.
//  RBX: Inline cache data object.
//  TOS(0): return address
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
    __ movq(RCX, FieldAddress(RBX, ICData::num_args_tested_offset()));
    __ cmpq(RCX, Immediate(num_args));
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Incorrect stub for IC data");
    __ Bind(&ok);
  }
#endif  // DEBUG

  // Check single stepping.
  Label not_stepping;
  __ movq(RAX, FieldAddress(CTX, Context::isolate_offset()));
  __ movzxb(RAX, Address(RAX, Isolate::single_step_offset()));
  __ cmpq(RAX, Immediate(0));
  __ j(EQUAL, &not_stepping, Assembler::kNearJump);
  __ EnterStubFrame();
  __ pushq(RBX);
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ popq(RBX);
  __ LeaveStubFrame();
  __ Bind(&not_stepping);

  // Load arguments descriptor into R10.
  __ movq(R10, FieldAddress(RBX, ICData::arguments_descriptor_offset()));
  // Loop that checks if there is an IC data match.
  Label loop, update, test, found, get_class_id_as_smi;
  // RBX: IC data object (preserved).
  __ movq(R12, FieldAddress(RBX, ICData::ic_data_offset()));
  // R12: ic_data_array with check entries: classes and target functions.
  __ leaq(R12, FieldAddress(R12, Array::data_offset()));
  // R12: points directly to the first ic data array element.

  // Get the receiver's class ID (first read number of arguments from
  // arguments descriptor array and then access the receiver from the stack).
  __ movq(RAX, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
  __ movq(RAX, Address(RSP, RAX, TIMES_4, 0));  // RAX (argument count) is Smi.
  __ call(&get_class_id_as_smi);
  // RAX: receiver's class ID as smi.
  __ movq(R13, Address(R12, 0));  // First class ID (Smi) to check.
  __ jmp(&test);

  __ Bind(&loop);
  for (int i = 0; i < num_args; i++) {
    if (i > 0) {
      // If not the first, load the next argument's class ID.
      __ movq(RAX, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
      __ movq(RAX, Address(RSP, RAX, TIMES_4, - i * kWordSize));
      __ call(&get_class_id_as_smi);
      // RAX: next argument class ID (smi).
      __ movq(R13, Address(R12, i * kWordSize));
      // R13: next class ID to check (smi).
    }
    __ cmpq(RAX, R13);  // Class id match?
    if (i < (num_args - 1)) {
      __ j(NOT_EQUAL, &update);  // Continue.
    } else {
      // Last check, all checks before matched.
      __ j(EQUAL, &found);  // Break.
    }
  }
  __ Bind(&update);
  // Reload receiver class ID.  It has not been destroyed when num_args == 1.
  if (num_args > 1) {
    __ movq(RAX, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
    __ movq(RAX, Address(RSP, RAX, TIMES_4, 0));
    __ call(&get_class_id_as_smi);
  }

  const intptr_t entry_size = ICData::TestEntryLengthFor(num_args) * kWordSize;
  __ addq(R12, Immediate(entry_size));  // Next entry.
  __ movq(R13, Address(R12, 0));  // Next class ID.

  __ Bind(&test);
  __ cmpq(R13, Immediate(Smi::RawValue(kIllegalCid)));  // Done?
  __ j(NOT_EQUAL, &loop, Assembler::kNearJump);

  // IC miss.
  __ LoadObject(R12, Object::null_object(), PP);
  // Compute address of arguments (first read number of arguments from
  // arguments descriptor array and then compute address on the stack).
  __ movq(RAX, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
  __ leaq(RAX, Address(RSP, RAX, TIMES_4, 0));  // RAX is Smi.
  __ EnterStubFrame();
  __ pushq(R10);  // Preserve arguments descriptor array.
  __ pushq(RBX);  // Preserve IC data object.
  __ pushq(R12);  // Setup space on stack for result (target code object).
  // Push call arguments.
  for (intptr_t i = 0; i < num_args; i++) {
    __ movq(RCX, Address(RAX, -kWordSize * i));
    __ pushq(RCX);
  }
  __ pushq(RBX);  // Pass IC data object.
  __ CallRuntime(handle_ic_miss, num_args + 1);
  // Remove the call arguments pushed earlier, including the IC data object.
  for (intptr_t i = 0; i < num_args + 1; i++) {
    __ popq(RAX);
  }
  __ popq(RAX);  // Pop returned code object into RAX (null if not found).
  __ popq(RBX);  // Restore IC data array.
  __ popq(R10);  // Restore arguments descriptor array.
  __ LeaveStubFrame();
  Label call_target_function;
  __ cmpq(RAX, R12);
  __ j(NOT_EQUAL, &call_target_function, Assembler::kNearJump);
  // NoSuchMethod or closure.
  // Mark IC call that it may be a closure call that does not collect
  // type feedback.
  __ movb(FieldAddress(RBX, ICData::is_closure_call_offset()), Immediate(1));
  __ jmp(&StubCode::InstanceFunctionLookupLabel());

  __ Bind(&found);
  // R12: Pointer to an IC data check group.
  const intptr_t target_offset = ICData::TargetIndexFor(num_args) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(num_args) * kWordSize;
  __ movq(RAX, Address(R12, target_offset));
  __ addq(Address(R12, count_offset), Immediate(Smi::RawValue(1)));
  __ j(NO_OVERFLOW, &call_target_function, Assembler::kNearJump);
  __ movq(Address(R12, count_offset),
          Immediate(Smi::RawValue(Smi::kMaxValue)));

  __ Bind(&call_target_function);
  // RAX: Target function.
  Label is_compiled;
  __ movq(RCX, FieldAddress(RAX, Function::code_offset()));
  if (FLAG_collect_code) {
    // If code might be GC'd, then RBX might be null. If it is, recompile.
    __ CompareObject(RCX, Object::null_object(), PP);
    __ j(NOT_EQUAL, &is_compiled, Assembler::kNearJump);
    __ EnterStubFrame();
    __ pushq(R10);  // Preserve arguments descriptor array.
    __ pushq(RBX);  // Preserve IC data object.
    __ pushq(RAX);  // Pass function.
    __ CallRuntime(kCompileFunctionRuntimeEntry, 1);
    __ popq(RAX);  // Restore function.
    __ popq(RBX);  // Restore IC data array.
    __ popq(R10);  // Restore arguments descriptor array.
    __ LeaveStubFrame();
    __ movq(RCX, FieldAddress(RAX, Function::code_offset()));
    __ Bind(&is_compiled);
  }
  __ movq(RAX, FieldAddress(RCX, Code::instructions_offset()));
  __ addq(RAX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ jmp(RAX);

  __ Bind(&get_class_id_as_smi);
  Label not_smi;
  // Test if Smi -> load Smi class for comparison.
  __ testq(RAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &not_smi, Assembler::kNearJump);
  __ movq(RAX, Immediate(Smi::RawValue(kSmiCid)));
  __ ret();

  __ Bind(&not_smi);
  __ LoadClassId(RAX, RAX);
  __ SmiTag(RAX);
  __ ret();
}


// Use inline cache data array to invoke the target or continue in inline
// cache miss handler. Stub for 1-argument check (receiver class).
//  RBX: Inline cache data object.
//  TOS(0): Return address.
// Inline cache data object structure:
// 0: function-name
// 1: N, number of arguments checked.
// 2 .. (length - 1): group of checks, each check containing:
//   - N classes.
//   - 1 target function.
void StubCode::GenerateOneArgCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, RCX);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kInlineCacheMissHandlerOneArgRuntimeEntry);
}


void StubCode::GenerateTwoArgsCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, RCX);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry);
}


void StubCode::GenerateThreeArgsCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, RCX);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 3, kInlineCacheMissHandlerThreeArgsRuntimeEntry);
}

// Use inline cache data array to invoke the target or continue in inline
// cache miss handler. Stub for 1-argument check (receiver class).
//  RDI: function which counter needs to be incremented.
//  RBX: Inline cache data object.
//  TOS(0): Return address.
// Inline cache data object structure:
// 0: function-name
// 1: N, number of arguments checked.
// 2 .. (length - 1): group of checks, each check containing:
//   - N classes.
//   - 1 target function.
void StubCode::GenerateOneArgOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateOptimizedUsageCounterIncrement(assembler);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kInlineCacheMissHandlerOneArgRuntimeEntry);
}


void StubCode::GenerateTwoArgsOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateOptimizedUsageCounterIncrement(assembler);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry);
}


void StubCode::GenerateThreeArgsOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateOptimizedUsageCounterIncrement(assembler);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 3, kInlineCacheMissHandlerThreeArgsRuntimeEntry);
}


// Do not count as no type feedback is collected.
void StubCode::GenerateClosureCallInlineCacheStub(Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kInlineCacheMissHandlerOneArgRuntimeEntry);
}


// Megamorphic call is currently implemented as IC call but through a stub
// that does not check/count function invocations.
void StubCode::GenerateMegamorphicCallStub(Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kInlineCacheMissHandlerOneArgRuntimeEntry);
}


// Intermediary stub between a static call and its target. ICData contains
// the target function and the call count.
// RBX: ICData
void StubCode::GenerateZeroArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, RCX);
#if defined(DEBUG)
  { Label ok;
    // Check that the IC data array has NumberOfArgumentsChecked() == 0.
    // 'num_args_tested' is stored as an untagged int.
    __ movq(RCX, FieldAddress(RBX, ICData::num_args_tested_offset()));
    __ cmpq(RCX, Immediate(0));
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Incorrect IC data for unoptimized static call");
    __ Bind(&ok);
  }
#endif  // DEBUG

  // Check single stepping.
  Label not_stepping;
  __ movq(RAX, FieldAddress(CTX, Context::isolate_offset()));
  __ movzxb(RAX, Address(RAX, Isolate::single_step_offset()));
  __ cmpq(RAX, Immediate(0));
  __ j(EQUAL, &not_stepping, Assembler::kNearJump);
  __ EnterStubFrame();
  __ pushq(RBX);  // Preserve IC data object.
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ popq(RBX);
  __ LeaveStubFrame();
  __ Bind(&not_stepping);

  // RBX: IC data object (preserved).
  __ movq(R12, FieldAddress(RBX, ICData::ic_data_offset()));
  // R12: ic_data_array with entries: target functions and count.
  __ leaq(R12, FieldAddress(R12, Array::data_offset()));
  // R12: points directly to the first ic data array element.
  const intptr_t target_offset = ICData::TargetIndexFor(0) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(0) * kWordSize;

  // Increment count for this call.
  Label increment_done;
  __ addq(Address(R12, count_offset), Immediate(Smi::RawValue(1)));
  __ j(NO_OVERFLOW, &increment_done, Assembler::kNearJump);
  __ movq(Address(R12, count_offset),
          Immediate(Smi::RawValue(Smi::kMaxValue)));
  __ Bind(&increment_done);

  Label target_is_compiled;
  // Get function and call it, if possible.
  __ movq(R13, Address(R12, target_offset));
  __ movq(RAX, FieldAddress(R13, Function::code_offset()));
  __ LoadObject(R12, Object::null_object(), PP);
  __ cmpq(RAX, R12);
  __ j(NOT_EQUAL, &target_is_compiled, Assembler::kNearJump);

  __ EnterStubFrame();
  __ pushq(R13);  // Preserve target function.
  __ pushq(RBX);  // Preserve IC data object.
  __ pushq(R13);  // Pass function.
  __ CallRuntime(kCompileFunctionRuntimeEntry, 1);
  __ popq(RAX);  // Discard argument.
  __ popq(RBX);  // Restore IC data object.
  __ popq(R13);  // Restore target function.
  __ LeaveStubFrame();
  __ movq(RAX, FieldAddress(R13, Function::code_offset()));

  __ Bind(&target_is_compiled);
  // RAX: Target code.
  __ movq(RAX, FieldAddress(RAX, Code::instructions_offset()));
  __ addq(RAX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  // Load arguments descriptor into R10.
  __ movq(R10, FieldAddress(RBX, ICData::arguments_descriptor_offset()));
  __ jmp(RAX);
}


void StubCode::GenerateTwoArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, RCX);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kStaticCallMissHandlerTwoArgsRuntimeEntry);
}


// Stub for calling the CompileFunction runtime call.
// RCX: IC-Data.
// RDX: Arguments descriptor.
// RAX: Function.
void StubCode::GenerateCompileFunctionRuntimeCallStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ pushq(RDX);  // Preserve arguments descriptor array.
  __ pushq(RCX);  // Preserve IC data object.
  __ pushq(RAX);  // Pass function.
  __ CallRuntime(kCompileFunctionRuntimeEntry, 1);
  __ popq(RAX);  // Restore function.
  __ popq(RCX);  // Restore IC data array.
  __ popq(RDX);  // Restore arguments descriptor array.
  __ LeaveStubFrame();
  __ ret();
}


//  RBX, R10: May contain arguments to runtime stub.
//  TOS(0): return address (Dart code).
void StubCode::GenerateBreakpointRuntimeStub(Assembler* assembler) {
  __ EnterStubFrame();
  // Preserve runtime args.
  __ pushq(RBX);
  __ pushq(R10);
  // Room for result. Debugger stub returns address of the
  // unpatched runtime stub.
  __ LoadObject(R12, Object::null_object(), PP);
  __ pushq(R12);  // Room for result.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ popq(RAX);  // Address of original.
  __ popq(R10);  // Restore arguments.
  __ popq(RBX);
  __ LeaveStubFrame();
  __ jmp(RAX);   // Jump to original stub.
}


// Called only from unoptimized code.
void StubCode::GenerateDebugStepCheckStub(Assembler* assembler) {
  // Check single stepping.
  Label not_stepping;
  __ movq(RAX, FieldAddress(CTX, Context::isolate_offset()));
  __ movzxb(RAX, Address(RAX, Isolate::single_step_offset()));
  __ cmpq(RAX, Immediate(0));
  __ j(EQUAL, &not_stepping, Assembler::kNearJump);

  __ EnterStubFrame();
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ LeaveStubFrame();
  __ Bind(&not_stepping);
  __ ret();
}


// Used to check class and type arguments. Arguments passed on stack:
// TOS + 0: return address.
// TOS + 1: instantiator type arguments (can be NULL).
// TOS + 2: instance.
// TOS + 3: SubtypeTestCache.
// Result in RCX: null -> not found, otherwise result (true or false).
static void GenerateSubtypeNTestCacheStub(Assembler* assembler, int n) {
  ASSERT((1 <= n) && (n <= 3));
  const intptr_t kInstantiatorTypeArgumentsInBytes = 1 * kWordSize;
  const intptr_t kInstanceOffsetInBytes = 2 * kWordSize;
  const intptr_t kCacheOffsetInBytes = 3 * kWordSize;
  __ movq(RAX, Address(RSP, kInstanceOffsetInBytes));
  __ LoadObject(R12, Object::null_object(), PP);
  if (n > 1) {
    __ LoadClass(R10, RAX);
    // Compute instance type arguments into R13.
    Label has_no_type_arguments;
    __ movq(R13, R12);
    __ movq(RDI, FieldAddress(R10,
        Class::type_arguments_field_offset_in_words_offset()));
    __ cmpq(RDI, Immediate(Class::kNoTypeArguments));
    __ j(EQUAL, &has_no_type_arguments, Assembler::kNearJump);
    __ movq(R13, FieldAddress(RAX, RDI, TIMES_8, 0));
    __ Bind(&has_no_type_arguments);
  }
  __ LoadClassId(R10, RAX);
  // RAX: instance, R10: instance class id.
  // R13: instance type arguments or null, used only if n > 1.
  __ movq(RDX, Address(RSP, kCacheOffsetInBytes));
  // RDX: SubtypeTestCache.
  __ movq(RDX, FieldAddress(RDX, SubtypeTestCache::cache_offset()));
  __ addq(RDX, Immediate(Array::data_offset() - kHeapObjectTag));
  // RDX: Entry start.
  // R10: instance class id.
  // R13: instance type arguments.
  Label loop, found, not_found, next_iteration;
  __ SmiTag(R10);
  __ Bind(&loop);
  __ movq(RDI, Address(RDX, kWordSize * SubtypeTestCache::kInstanceClassId));
  __ cmpq(RDI, R12);
  __ j(EQUAL, &not_found, Assembler::kNearJump);
  __ cmpq(RDI, R10);
  if (n == 1) {
    __ j(EQUAL, &found, Assembler::kNearJump);
  } else {
    __ j(NOT_EQUAL, &next_iteration, Assembler::kNearJump);
    __ movq(RDI,
        Address(RDX, kWordSize * SubtypeTestCache::kInstanceTypeArguments));
    __ cmpq(RDI, R13);
    if (n == 2) {
      __ j(EQUAL, &found, Assembler::kNearJump);
    } else {
      __ j(NOT_EQUAL, &next_iteration, Assembler::kNearJump);
      __ movq(RDI,
          Address(RDX,
                  kWordSize * SubtypeTestCache::kInstantiatorTypeArguments));
      __ cmpq(RDI, Address(RSP, kInstantiatorTypeArgumentsInBytes));
      __ j(EQUAL, &found, Assembler::kNearJump);
    }
  }

  __ Bind(&next_iteration);
  __ addq(RDX, Immediate(kWordSize * SubtypeTestCache::kTestEntryLength));
  __ jmp(&loop, Assembler::kNearJump);
  // Fall through to not found.
  __ Bind(&not_found);
  __ movq(RCX, R12);
  __ ret();

  __ Bind(&found);
  __ movq(RCX, Address(RDX, kWordSize * SubtypeTestCache::kTestResult));
  __ ret();
}


// Used to check class and type arguments. Arguments passed on stack:
// TOS + 0: return address.
// TOS + 1: instantiator type arguments or NULL.
// TOS + 2: instance.
// TOS + 3: cache array.
// Result in RCX: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype1TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 1);
}


// Used to check class and type arguments. Arguments passed on stack:
// TOS + 0: return address.
// TOS + 1: instantiator type arguments or NULL.
// TOS + 2: instance.
// TOS + 3: cache array.
// Result in RCX: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype2TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 2);
}


// Used to check class and type arguments. Arguments passed on stack:
// TOS + 0: return address.
// TOS + 1: instantiator type arguments.
// TOS + 2: instance.
// TOS + 3: cache array.
// Result in RCX: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype3TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 3);
}


// Return the current stack pointer address, used to stack alignment
// checks.
// TOS + 0: return address
// Result in RAX.
void StubCode::GenerateGetStackPointerStub(Assembler* assembler) {
  __ leaq(RAX, Address(RSP, kWordSize));
  __ ret();
}


// Jump to the exception or error handler.
// TOS + 0: return address
// RDI: program counter
// RSI: stack pointer
// RDX: frame_pointer
// RCX: exception object
// R8: stacktrace object
// No Result.
void StubCode::GenerateJumpToExceptionHandlerStub(Assembler* assembler) {
  ASSERT(kExceptionObjectReg == RAX);
  ASSERT(kStackTraceObjectReg == RDX);
  __ movq(RBP, RDX);  // target frame pointer.
  __ movq(kStackTraceObjectReg, R8);  // stacktrace object.
  __ movq(kExceptionObjectReg, RCX);  // exception object.
  __ movq(RSP, RSI);   // target stack_pointer.
  __ jmp(RDI);  // Jump to the exception handler code.
}


// Calls to the runtime to optimize the given function.
// RDI: function to be reoptimized.
// R10: argument descriptor (preserved).
void StubCode::GenerateOptimizeFunctionStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ LoadObject(R12, Object::null_object(), PP);
  __ pushq(R10);
  __ pushq(R12);  // Setup space on stack for return value.
  __ pushq(RDI);
  __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry, 1);
  __ popq(RAX);  // Disard argument.
  __ popq(RAX);  // Get Code object.
  __ popq(R10);  // Restore argument descriptor.
  __ movq(RAX, FieldAddress(RAX, Code::instructions_offset()));
  __ addq(RAX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ LeaveStubFrame();
  __ jmp(RAX);
  __ int3();
}


DECLARE_LEAF_RUNTIME_ENTRY(intptr_t,
                           BigintCompare,
                           RawBigint* left,
                           RawBigint* right);


// Does identical check (object references are equal or not equal) with special
// checks for boxed numbers.
// Left and right are pushed on stack.
// Return ZF set.
// Note: A Mint cannot contain a value that would fit in Smi, a Bigint
// cannot contain a value that fits in Mint or Smi.
void StubCode::GenerateIdenticalWithNumberCheckStub(Assembler* assembler,
                                                    const Register left,
                                                    const Register right,
                                                    const Register unused1,
                                                    const Register unused2) {
  Label reference_compare, done, check_mint, check_bigint;
  // If any of the arguments is Smi do reference compare.
  __ testq(left, Immediate(kSmiTagMask));
  __ j(ZERO, &reference_compare);
  __ testq(right, Immediate(kSmiTagMask));
  __ j(ZERO, &reference_compare);

  // Value compare for two doubles.
  __ CompareClassId(left, kDoubleCid);
  __ j(NOT_EQUAL, &check_mint, Assembler::kNearJump);
  __ CompareClassId(right, kDoubleCid);
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);

  // Double values bitwise compare.
  __ movq(left, FieldAddress(left, Double::value_offset()));
  __ cmpq(left, FieldAddress(right, Double::value_offset()));
  __ jmp(&done, Assembler::kNearJump);

  __ Bind(&check_mint);
  __ CompareClassId(left, kMintCid);
  __ j(NOT_EQUAL, &check_bigint, Assembler::kNearJump);
  __ CompareClassId(right, kMintCid);
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  __ movq(left, FieldAddress(left, Mint::value_offset()));
  __ cmpq(left, FieldAddress(right, Mint::value_offset()));
  __ jmp(&done, Assembler::kNearJump);

  __ Bind(&check_bigint);
  __ CompareClassId(left, kBigintCid);
  __ j(NOT_EQUAL, &reference_compare, Assembler::kNearJump);
  __ CompareClassId(right, kBigintCid);
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  __ EnterFrame(0);
  __ ReserveAlignedFrameSpace(0);
  __ movq(RDI, left);
  __ movq(RSI, right);
  __ CallRuntime(kBigintCompareRuntimeEntry, 2);
  // Result in RAX, 0 means equal.
  __ LeaveFrame();
  __ cmpq(RAX, Immediate(0));
  __ jmp(&done);

  __ Bind(&reference_compare);
  __ cmpq(left, right);
  __ Bind(&done);
}


// Called only from unoptimized code. All relevant registers have been saved.
// TOS + 0: return address
// TOS + 1: right argument.
// TOS + 2: left argument.
// Returns ZF set.
void StubCode::GenerateUnoptimizedIdenticalWithNumberCheckStub(
    Assembler* assembler) {
  // Check single stepping.
  Label not_stepping;
  __ movq(RAX, FieldAddress(CTX, Context::isolate_offset()));
  __ movzxb(RAX, Address(RAX, Isolate::single_step_offset()));
  __ cmpq(RAX, Immediate(0));
  __ j(EQUAL, &not_stepping, Assembler::kNearJump);
  __ EnterStubFrame();
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ LeaveStubFrame();
  __ Bind(&not_stepping);

  const Register left = RAX;
  const Register right = RDX;

  __ movq(left, Address(RSP, 2 * kWordSize));
  __ movq(right, Address(RSP, 1 * kWordSize));
  GenerateIdenticalWithNumberCheckStub(assembler, left, right);
  __ ret();
}


// Called from optimized code only.
// TOS + 0: return address
// TOS + 1: right argument.
// TOS + 2: left argument.
// Returns ZF set.
void StubCode::GenerateOptimizedIdenticalWithNumberCheckStub(
    Assembler* assembler) {
  const Register left = RAX;
  const Register right = RDX;

  __ movq(left, Address(RSP, 2 * kWordSize));
  __ movq(right, Address(RSP, 1 * kWordSize));
  GenerateIdenticalWithNumberCheckStub(assembler, left, right);
  __ ret();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
