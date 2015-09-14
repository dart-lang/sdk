// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM)

#include "vm/assembler.h"
#include "vm/code_generator.h"
#include "vm/cpu.h"
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
DECLARE_FLAG(bool, trace_optimized_ic_calls);
DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(bool, support_debugger);
DECLARE_FLAG(bool, lazy_dispatchers);

// Input parameters:
//   LR : return address.
//   SP : address of last argument in argument array.
//   SP + 4*R4 - 4 : address of first argument in argument array.
//   SP + 4*R4 : address of return value.
//   R5 : address of the runtime function to call.
//   R4 : number of arguments to the call.
void StubCode::GenerateCallToRuntimeStub(Assembler* assembler) {
  const intptr_t thread_offset = NativeArguments::thread_offset();
  const intptr_t argc_tag_offset = NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = NativeArguments::argv_offset();
  const intptr_t retval_offset = NativeArguments::retval_offset();
  const intptr_t exitframe_last_param_slot_from_fp = 2;

  __ EnterStubFrame();

  COMPILE_ASSERT((kAbiPreservedCpuRegs & (1 << R9)) != 0);
  __ LoadIsolate(R9);

  // Save exit frame information to enable stack walking as we are about
  // to transition to Dart VM C++ code.
  __ StoreToOffset(kWord, FP, THR, Thread::top_exit_frame_info_offset());

#if defined(DEBUG)
  { Label ok;
    // Check that we are always entering from Dart code.
    __ LoadFromOffset(kWord, R6, R9, Isolate::vm_tag_offset());
    __ CompareImmediate(R6, VMTag::kDartTagId);
    __ b(&ok, EQ);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the isolate is executing VM code.
  __ StoreToOffset(kWord, R5, R9, Isolate::vm_tag_offset());

  // Reserve space for arguments and align frame before entering C++ world.
  // NativeArguments are passed in registers.
  ASSERT(sizeof(NativeArguments) == 4 * kWordSize);
  __ ReserveAlignedFrameSpace(0);

  // Pass NativeArguments structure by value and call runtime.
  // Registers R0, R1, R2, and R3 are used.

  ASSERT(thread_offset == 0 * kWordSize);
  // Set thread in NativeArgs.
  __ mov(R0, Operand(THR));

  // There are no runtime calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * kWordSize);
  __ mov(R1, Operand(R4));  // Set argc in NativeArguments.

  ASSERT(argv_offset == 2 * kWordSize);
  __ add(R2, FP, Operand(R4, LSL, 2));  // Compute argv.
  // Set argv in NativeArguments.
  __ AddImmediate(R2, exitframe_last_param_slot_from_fp * kWordSize);

  ASSERT(retval_offset == 3 * kWordSize);
  __ add(R3, R2, Operand(kWordSize));  // Retval is next to 1st argument.

  // Call runtime or redirection via simulator.
  __ blx(R5);

  // Mark that the isolate is executing Dart code.
  __ LoadImmediate(R2, VMTag::kDartTagId);
  __ StoreToOffset(kWord, R2, R9, Isolate::vm_tag_offset());

  // Reset exit frame information in Isolate structure.
  __ LoadImmediate(R2, 0);
  __ StoreToOffset(kWord, R2, THR, Thread::top_exit_frame_info_offset());

  __ LeaveStubFrame();
  __ Ret();
}


// Print the stop message.
DEFINE_LEAF_RUNTIME_ENTRY(void, PrintStopMessage, 1, const char* message) {
  OS::Print("Stop message: %s\n", message);
}
END_LEAF_RUNTIME_ENTRY


// Input parameters:
//   R0 : stop message (const char*).
// Must preserve all registers.
void StubCode::GeneratePrintStopMessageStub(Assembler* assembler) {
  __ EnterCallRuntimeFrame(0);
  // Call the runtime leaf function. R0 already contains the parameter.
  __ CallRuntime(kPrintStopMessageRuntimeEntry, 1);
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
  const intptr_t thread_offset = NativeArguments::thread_offset();
  const intptr_t argc_tag_offset = NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = NativeArguments::argv_offset();
  const intptr_t retval_offset = NativeArguments::retval_offset();

  __ EnterStubFrame();

  COMPILE_ASSERT((kAbiPreservedCpuRegs & (1 << R9)) != 0);
  __ LoadIsolate(R9);

  // Save exit frame information to enable stack walking as we are about
  // to transition to native code.
  __ StoreToOffset(kWord, FP, THR, Thread::top_exit_frame_info_offset());

#if defined(DEBUG)
  { Label ok;
    // Check that we are always entering from Dart code.
    __ LoadFromOffset(kWord, R6, R9, Isolate::vm_tag_offset());
    __ CompareImmediate(R6, VMTag::kDartTagId);
    __ b(&ok, EQ);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the isolate is executing Native code.
  __ StoreToOffset(kWord, R5, R9, Isolate::vm_tag_offset());

  // Reserve space for the native arguments structure passed on the stack (the
  // outgoing pointer parameter to the native arguments structure is passed in
  // R0) and align frame before entering the C++ world.
  __ ReserveAlignedFrameSpace(sizeof(NativeArguments));

  // Initialize NativeArguments structure and call native function.
  // Registers R0, R1, R2, and R3 are used.

  ASSERT(thread_offset == 0 * kWordSize);
  // Set thread in NativeArgs.
  __ mov(R0, Operand(THR));

  // There are no native calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * kWordSize);
  // Set argc in NativeArguments: R1 already contains argc.

  ASSERT(argv_offset == 2 * kWordSize);
  // Set argv in NativeArguments: R2 already contains argv.

  ASSERT(retval_offset == 3 * kWordSize);
  __ add(R3, FP, Operand(3 * kWordSize));  // Set retval in NativeArgs.

  // Passing the structure by value as in runtime calls would require changing
  // Dart API for native functions.
  // For now, space is reserved on the stack and we pass a pointer to it.
  __ stm(IA, SP,  (1 << R0) | (1 << R1) | (1 << R2) | (1 << R3));
  __ mov(R0, Operand(SP));  // Pass the pointer to the NativeArguments.

  __ mov(R1, Operand(R5));  // Pass the function entrypoint to call.
  // Call native function invocation wrapper or redirection via simulator.
#if defined(USING_SIMULATOR)
  uword entry = reinterpret_cast<uword>(NativeEntry::NativeCallWrapper);
  entry = Simulator::RedirectExternalReference(
      entry, Simulator::kNativeCall, NativeEntry::kNumCallWrapperArguments);
  __ LoadImmediate(R2, entry);
  __ blx(R2);
#else
  __ BranchLink(&NativeEntry::NativeCallWrapperLabel(), kNotPatchable);
#endif

  // Mark that the isolate is executing Dart code.
  __ LoadImmediate(R2, VMTag::kDartTagId);
  __ StoreToOffset(kWord, R2, R9, Isolate::vm_tag_offset());

  // Reset exit frame information in Isolate structure.
  __ LoadImmediate(R2, 0);
  __ StoreToOffset(kWord, R2, THR, Thread::top_exit_frame_info_offset());

  __ LeaveStubFrame();
  __ Ret();
}


// Input parameters:
//   LR : return address.
//   SP : address of return value.
//   R5 : address of the native function to call.
//   R2 : address of first argument in argument array.
//   R1 : argc_tag including number of arguments and function kind.
void StubCode::GenerateCallBootstrapCFunctionStub(Assembler* assembler) {
  const intptr_t thread_offset = NativeArguments::thread_offset();
  const intptr_t argc_tag_offset = NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = NativeArguments::argv_offset();
  const intptr_t retval_offset = NativeArguments::retval_offset();

  __ EnterStubFrame();

  COMPILE_ASSERT((kAbiPreservedCpuRegs & (1 << R9)) != 0);
  __ LoadIsolate(R9);

  // Save exit frame information to enable stack walking as we are about
  // to transition to native code.
  __ StoreToOffset(kWord, FP, THR, Thread::top_exit_frame_info_offset());

#if defined(DEBUG)
  { Label ok;
    // Check that we are always entering from Dart code.
    __ LoadFromOffset(kWord, R6, R9, Isolate::vm_tag_offset());
    __ CompareImmediate(R6, VMTag::kDartTagId);
    __ b(&ok, EQ);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the isolate is executing Native code.
  __ StoreToOffset(kWord, R5, R9, Isolate::vm_tag_offset());

  // Reserve space for the native arguments structure passed on the stack (the
  // outgoing pointer parameter to the native arguments structure is passed in
  // R0) and align frame before entering the C++ world.
  __ ReserveAlignedFrameSpace(sizeof(NativeArguments));

  // Initialize NativeArguments structure and call native function.
  // Registers R0, R1, R2, and R3 are used.

  ASSERT(thread_offset == 0 * kWordSize);
  // Set thread in NativeArgs.
  __ mov(R0, Operand(THR));

  // There are no native calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * kWordSize);
  // Set argc in NativeArguments: R1 already contains argc.

  ASSERT(argv_offset == 2 * kWordSize);
  // Set argv in NativeArguments: R2 already contains argv.

  ASSERT(retval_offset == 3 * kWordSize);
  __ add(R3, FP, Operand(3 * kWordSize));  // Set retval in NativeArgs.

  // Passing the structure by value as in runtime calls would require changing
  // Dart API for native functions.
  // For now, space is reserved on the stack and we pass a pointer to it.
  __ stm(IA, SP,  (1 << R0) | (1 << R1) | (1 << R2) | (1 << R3));
  __ mov(R0, Operand(SP));  // Pass the pointer to the NativeArguments.

  // Call native function or redirection via simulator.
  __ blx(R5);

  // Mark that the isolate is executing Dart code.
  __ LoadImmediate(R2, VMTag::kDartTagId);
  __ StoreToOffset(kWord, R2, R9, Isolate::vm_tag_offset());

  // Reset exit frame information in Isolate structure.
  __ LoadImmediate(R2, 0);
  __ StoreToOffset(kWord, R2, THR, Thread::top_exit_frame_info_offset());

  __ LeaveStubFrame();
  __ Ret();
}


// Input parameters:
//   R4: arguments descriptor array.
void StubCode::GenerateCallStaticFunctionStub(Assembler* assembler) {
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value and preserve arguments descriptor.
  __ LoadObject(R0, Object::null_object());
  __ PushList((1 << R0) | (1 << R4));
  __ CallRuntime(kPatchStaticCallRuntimeEntry, 0);
  // Get Code object result and restore arguments descriptor array.
  __ PopList((1 << R0) | (1 << R4));
  // Remove the stub frame.
  __ LeaveStubFrame();
  // Jump to the dart function.
  __ ldr(R0, FieldAddress(R0, Code::entry_point_offset()));
  __ bx(R0);
}


// Called from a static call only when an invalid code has been entered
// (invalid because its function was optimized or deoptimized).
// R4: arguments descriptor array.
void StubCode::GenerateFixCallersTargetStub(Assembler* assembler) {
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value and preserve arguments descriptor.
  __ LoadObject(R0, Object::null_object());
  __ PushList((1 << R0) | (1 << R4));
  __ CallRuntime(kFixCallersTargetRuntimeEntry, 0);
  // Get Code object result and restore arguments descriptor array.
  __ PopList((1 << R0) | (1 << R4));
  // Remove the stub frame.
  __ LeaveStubFrame();
  // Jump to the dart function.
  __ ldr(R0, FieldAddress(R0, Code::entry_point_offset()));
  __ bx(R0);
}


// Called from object allocate instruction when the allocation stub has been
// disabled.
void StubCode::GenerateFixAllocationStubTargetStub(Assembler* assembler) {
  __ EnterStubFrame();
  // Setup space on stack for return value.
  __ LoadObject(R0, Object::null_object());
  __ Push(R0);
  __ CallRuntime(kFixAllocationStubTargetRuntimeEntry, 0);
  // Get Code object result.
  __ Pop(R0);
  // Remove the stub frame.
  __ LeaveStubFrame();
  // Jump to the dart function.
  __ ldr(R0, FieldAddress(R0, Code::entry_point_offset()));
  __ bx(R0);
}


// Input parameters:
//   R2: smi-tagged argument count, may be zero.
//   FP[kParamEndSlotFromFp + 1]: last argument.
static void PushArgumentsArray(Assembler* assembler) {
  // Allocate array to store arguments of caller.
  __ LoadObject(R1, Object::null_object());
  // R1: null element type for raw Array.
  // R2: smi-tagged argument count, may be zero.
  __ BranchLink(*StubCode::AllocateArray_entry());
  // R0: newly allocated array.
  // R2: smi-tagged argument count, may be zero (was preserved by the stub).
  __ Push(R0);  // Array is in R0 and on top of stack.
  __ AddImmediate(R1, FP, kParamEndSlotFromFp * kWordSize);
  __ AddImmediate(R3, R0, Array::data_offset() - kHeapObjectTag);
  // Copy arguments from stack to array (starting at the end).
  // R1: address just beyond last argument on stack.
  // R3: address of first argument in array.
  Label enter;
  __ b(&enter);
  Label loop;
  __ Bind(&loop);
  __ ldr(IP, Address(R1, kWordSize, Address::PreIndex));
  __ InitializeFieldNoBarrier(R0, Address(R3, R2, LSL, 1), IP);
  __ Bind(&enter);
  __ subs(R2, R2, Operand(Smi::RawValue(1)));  // R2 is Smi.
  __ b(&loop, PL);
}


// Used by eager and lazy deoptimization. Preserve result in R0 if necessary.
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
// Stack after EnterFrame(...) below:
//   +------------------+
//   | Saved PP         | <- TOS
//   +------------------+
//   | Saved FP         | <- FP of stub
//   +------------------+
//   | Saved LR         |  (deoptimization point)
//   +------------------+
//   | PC marker        |
//   +------------------+
//   | ...              | <- SP of optimized frame
//
// Parts of the code cannot GC, part of the code can GC.
static void GenerateDeoptimizationSequence(Assembler* assembler,
                                           bool preserve_result) {
  // DeoptimizeCopyFrame expects a Dart frame, i.e. EnterDartFrame(0), but there
  // is no need to set the correct PC marker or load PP, since they get patched.

  // IP has the potentially live LR value. LR was clobbered by the call with
  // the return address, so move it into IP to set up the Dart frame.
  __ eor(IP, IP, Operand(LR));
  __ eor(LR, IP, Operand(LR));
  __ eor(IP, IP, Operand(LR));

  // Set up the frame manually. We can't use EnterFrame because we can't
  // clobber LR (or any other register) with 0, yet.
  __ sub(SP, SP, Operand(kWordSize));  // Make room for PC marker of 0.
  __ Push(IP);  // Push return address.
  __ Push(FP);
  __ mov(FP, Operand(SP));
  __ Push(PP);

  __ LoadPoolPointer();

  // Now that IP holding the return address has been written to the stack,
  // we can clobber it with 0 to write the null PC marker.
  __ mov(IP, Operand(0));
  __ str(IP, Address(SP, +3 * kWordSize));

  // The code in this frame may not cause GC. kDeoptimizeCopyFrameRuntimeEntry
  // and kDeoptimizeFillFrameRuntimeEntry are leaf runtime calls.
  const intptr_t saved_result_slot_from_fp =
      kFirstLocalSlotFromFp + 1 - (kNumberOfCpuRegisters - R0);
  // Result in R0 is preserved as part of pushing all registers below.

  // Push registers in their enumeration order: lowest register number at
  // lowest address.
  __ PushList(kAllCpuRegistersList);

  if (TargetCPUFeatures::vfp_supported()) {
    ASSERT(kFpuRegisterSize == 4 * kWordSize);
    if (kNumberOfDRegisters > 16) {
      __ vstmd(DB_W, SP, D16, kNumberOfDRegisters - 16);
      __ vstmd(DB_W, SP, D0, 16);
    } else {
      __ vstmd(DB_W, SP, D0, kNumberOfDRegisters);
    }
  } else {
    __ AddImmediate(SP, SP, -kNumberOfFpuRegisters * kFpuRegisterSize);
  }

  __ mov(R0, Operand(SP));  // Pass address of saved registers block.
  __ ReserveAlignedFrameSpace(0);
  __ CallRuntime(kDeoptimizeCopyFrameRuntimeEntry, 1);
  // Result (R0) is stack-size (FP - SP) in bytes.

  if (preserve_result) {
    // Restore result into R1 temporarily.
    __ ldr(R1, Address(FP, saved_result_slot_from_fp * kWordSize));
  }

  __ LeaveDartFrame();
  __ sub(SP, FP, Operand(R0));

  // DeoptimizeFillFrame expects a Dart frame, i.e. EnterDartFrame(0), but there
  // is no need to set the correct PC marker or load PP, since they get patched.
  __ EnterStubFrame();
  __ mov(R0, Operand(FP));  // Get last FP address.
  if (preserve_result) {
    __ Push(R1);  // Preserve result as first local.
  }
  __ ReserveAlignedFrameSpace(0);
  __ CallRuntime(kDeoptimizeFillFrameRuntimeEntry, 1);  // Pass last FP in R0.
  if (preserve_result) {
    // Restore result into R1.
    __ ldr(R1, Address(FP, kFirstLocalSlotFromFp * kWordSize));
  }
  // Code above cannot cause GC.
  __ LeaveStubFrame();

  // Frame is fully rewritten at this point and it is safe to perform a GC.
  // Materialize any objects that were deferred by FillFrame because they
  // require allocation.
  // Enter stub frame with loading PP. The caller's PP is not materialized yet.
  __ EnterStubFrame();
  if (preserve_result) {
    __ Push(R1);  // Preserve result, it will be GC-d here.
  }
  __ PushObject(Smi::ZoneHandle());  // Space for the result.
  __ CallRuntime(kDeoptimizeMaterializeRuntimeEntry, 0);
  // Result tells stub how many bytes to remove from the expression stack
  // of the bottom-most frame. They were used as materialization arguments.
  __ Pop(R1);
  if (preserve_result) {
    __ Pop(R0);  // Restore result.
  }
  __ LeaveStubFrame();
  // Remove materialization arguments.
  __ add(SP, SP, Operand(R1, ASR, kSmiTagSize));
  __ Ret();
}


void StubCode::GenerateDeoptimizeLazyStub(Assembler* assembler) {
  // Correct return address to point just after the call that is being
  // deoptimized.
  __ AddImmediate(LR, -CallPattern::LengthInBytes());
  GenerateDeoptimizationSequence(assembler, true);  // Preserve R0.
}


void StubCode::GenerateDeoptimizeStub(Assembler* assembler) {
  GenerateDeoptimizationSequence(assembler, false);  // Don't preserve R0.
}


static void GenerateDispatcherCode(Assembler* assembler,
                                   Label* call_target_function) {
  __ Comment("NoSuchMethodDispatch");
  // When lazily generated invocation dispatchers are disabled, the
  // miss-handler may return null.
  __ CompareObject(R0, Object::null_object());
  __ b(call_target_function, NE);
  __ EnterStubFrame();
  // Load the receiver.
  __ ldr(R2, FieldAddress(R4, ArgumentsDescriptor::count_offset()));
  __ add(IP, FP, Operand(R2, LSL, 1));  // R2 is Smi.
  __ ldr(R6, Address(IP, kParamEndSlotFromFp * kWordSize));
  __ PushObject(Object::null_object());
  __ Push(R6);
  __ Push(R5);
  __ Push(R4);
  // R2: Smi-tagged arguments array length.
  PushArgumentsArray(assembler);
  const intptr_t kNumArgs = 4;
  __ CallRuntime(kInvokeNoSuchMethodDispatcherRuntimeEntry, kNumArgs);
  __ Drop(4);
  __ Pop(R0);  // Return value.
  __ LeaveStubFrame();
  __ Ret();
}


void StubCode::GenerateMegamorphicMissStub(Assembler* assembler) {
  __ EnterStubFrame();

  // Load the receiver.
  __ ldr(R2, FieldAddress(R4, ArgumentsDescriptor::count_offset()));
  __ add(IP, FP, Operand(R2, LSL, 1));  // R2 is Smi.
  __ ldr(R6, Address(IP, kParamEndSlotFromFp * kWordSize));

  // Preserve IC data and arguments descriptor.
  __ PushList((1 << R4) | (1 << R5));

  // Push space for the return value.
  // Push the receiver.
  // Push IC data object.
  // Push arguments descriptor array.
  __ LoadObject(IP, Object::null_object());
  __ PushList((1 << R4) | (1 << R5) | (1 << R6) | (1 << IP));
  __ CallRuntime(kMegamorphicCacheMissHandlerRuntimeEntry, 3);
  // Remove arguments.
  __ Drop(3);
  __ Pop(R0);  // Get result into R0 (target function).

  // Restore IC data and arguments descriptor.
  __ PopList((1 << R4) | (1 << R5));

  __ LeaveStubFrame();

  if (!FLAG_lazy_dispatchers) {
    Label call_target_function;
    GenerateDispatcherCode(assembler, &call_target_function);
    __ Bind(&call_target_function);
  }

  // Tail-call to target function.
  __ ldr(R2, FieldAddress(R0, Function::entry_point_offset()));
  __ bx(R2);
}


// Called for inline allocation of arrays.
// Input parameters:
//   LR: return address.
//   R1: array element type (either NULL or an instantiated type).
//   R2: array length as Smi (must be preserved).
// The newly allocated object is returned in R0.
void StubCode::GenerateAllocateArrayStub(Assembler* assembler) {
  Label slow_case;
  // Compute the size to be allocated, it is based on the array length
  // and is computed as:
  // RoundedAllocationSize((array_length * kwordSize) + sizeof(RawArray)).
  __ MoveRegister(R3, R2);   // Array length.
  // Check that length is a positive Smi.
  __ tst(R3, Operand(kSmiTagMask));
  if (FLAG_use_slow_path) {
    __ b(&slow_case);
  } else {
    __ b(&slow_case, NE);
  }
  __ cmp(R3, Operand(0));
  __ b(&slow_case, LT);

  // Check for maximum allowed length.
  const intptr_t max_len =
      reinterpret_cast<int32_t>(Smi::New(Array::kMaxElements));
  __ CompareImmediate(R3, max_len);
  __ b(&slow_case, GT);

  const intptr_t cid = kArrayCid;
  __ MaybeTraceAllocation(cid, R4, &slow_case,
                          /* inline_isolate = */ false);

  const intptr_t fixed_size = sizeof(RawArray) + kObjectAlignment - 1;
  __ LoadImmediate(R9, fixed_size);
  __ add(R9, R9, Operand(R3, LSL, 1));  // R3 is  a Smi.
  ASSERT(kSmiTagShift == 1);
  __ bic(R9, R9, Operand(kObjectAlignment - 1));

  // R9: Allocation size.
  Heap::Space space = Heap::SpaceForAllocation(cid);
  __ LoadIsolate(R6);
  __ ldr(R6, Address(R6, Isolate::heap_offset()));
  // Potential new object start.
  __ ldr(R0, Address(R6, Heap::TopOffset(space)));
  __ adds(R7, R0, Operand(R9));  // Potential next object start.
  __ b(&slow_case, CS);  // Branch if unsigned overflow.

  // Check if the allocation fits into the remaining space.
  // R0: potential new object start.
  // R7: potential next object start.
  // R9: allocation size.
  __ ldr(R3, Address(R6, Heap::EndOffset(space)));
  __ cmp(R7, Operand(R3));
  __ b(&slow_case, CS);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  __ LoadAllocationStatsAddress(R3, cid, /* inline_isolate = */ false);
  __ str(R7, Address(R6, Heap::TopOffset(space)));
  __ add(R0, R0, Operand(kHeapObjectTag));

  // Initialize the tags.
  // R0: new object start as a tagged pointer.
  // R3: allocation stats address.
  // R7: new object end address.
  // R9: allocation size.
  {
    const intptr_t shift = RawObject::kSizeTagPos - kObjectAlignmentLog2;

    __ CompareImmediate(R9, RawObject::SizeTag::kMaxSizeTag);
    __ mov(R6, Operand(R9, LSL, shift), LS);
    __ mov(R6, Operand(0), HI);

    // Get the class index and insert it into the tags.
    // R6: size and bit tags.
    __ LoadImmediate(TMP, RawObject::ClassIdTag::encode(cid));
    __ orr(R6, R6, Operand(TMP));
    __ str(R6, FieldAddress(R0, Array::tags_offset()));  // Store tags.
  }

  // R0: new object start as a tagged pointer.
  // R7: new object end address.
  // Store the type argument field.
  __ InitializeFieldNoBarrier(R0,
                              FieldAddress(R0, Array::type_arguments_offset()),
                              R1);

  // Set the length field.
  __ InitializeFieldNoBarrier(R0,
                              FieldAddress(R0, Array::length_offset()),
                              R2);

  // Initialize all array elements to raw_null.
  // R0: new object start as a tagged pointer.
  // R3: allocation stats address.
  // R4, R5: null
  // R6: iterator which initially points to the start of the variable
  // data area to be initialized.
  // R7: new object end address.
  // R9: allocation size.

  __ LoadObject(R4, Object::null_object());
  __ mov(R5, Operand(R4));
  __ AddImmediate(R6, R0, sizeof(RawArray) - kHeapObjectTag);
  __ InitializeFieldsNoBarrier(R0, R6, R7, R4, R5);
  __ IncrementAllocationStatsWithSize(R3, R9, space);
  __ Ret();  // Returns the newly allocated object in R0.
  // Unable to allocate the array using the fast inline code, just call
  // into the runtime.
  __ Bind(&slow_case);

  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ LoadObject(IP, Object::null_object());
  // Setup space on stack for return value.
  // Push array length as Smi and element type.
  __ PushList((1 << R1) | (1 << R2) | (1 << IP));
  __ CallRuntime(kAllocateArrayRuntimeEntry, 2);
  // Pop arguments; result is popped in IP.
  __ PopList((1 << R1) | (1 << R2) | (1 << IP));  // R2 is restored.
  __ mov(R0, Operand(IP));
  __ LeaveStubFrame();
  __ Ret();
}


// Called when invoking Dart code from C++ (VM code).
// Input parameters:
//   LR : points to return address.
//   R0 : entrypoint of the Dart function to call.
//   R1 : arguments descriptor array.
//   R2 : arguments array.
//   R3 : current thread.
void StubCode::GenerateInvokeDartCodeStub(Assembler* assembler) {
  // Save frame pointer coming in.
  __ EnterFrame((1 << FP) | (1 << LR), 0);

  // Save new context and C++ ABI callee-saved registers.
  __ PushList(kAbiPreservedCpuRegs);

  const DRegister firstd = EvenDRegisterOf(kAbiFirstPreservedFpuReg);
  if (TargetCPUFeatures::vfp_supported()) {
    ASSERT(2 * kAbiPreservedFpuRegCount < 16);
    // Save FPU registers. 2 D registers per Q register.
    __ vstmd(DB_W, SP, firstd, 2 * kAbiPreservedFpuRegCount);
  } else {
    __ sub(SP, SP, Operand(kAbiPreservedFpuRegCount * kFpuRegisterSize));
  }

  // We now load the pool pointer(PP) as we are about to invoke dart code and we
  // could potentially invoke some intrinsic functions which need the PP to be
  // set up.
  __ LoadPoolPointer();

  // Set up THR, which caches the current thread in Dart code.
  if (THR != R3) {
    __ mov(THR, Operand(R3));
  }
  __ LoadIsolate(R9);

  // Save the current VMTag on the stack.
  __ LoadFromOffset(kWord, R5, R9, Isolate::vm_tag_offset());
  __ Push(R5);

  // Mark that the isolate is executing Dart code.
  __ LoadImmediate(R5, VMTag::kDartTagId);
  __ StoreToOffset(kWord, R5, R9, Isolate::vm_tag_offset());

  // Save top resource and top exit frame info. Use R4-6 as temporary registers.
  // StackFrameIterator reads the top exit frame info saved in this frame.
  __ LoadFromOffset(kWord, R5, THR, Thread::top_exit_frame_info_offset());
  __ LoadFromOffset(kWord, R4, THR, Thread::top_resource_offset());
  __ LoadImmediate(R6, 0);
  __ StoreToOffset(kWord, R6, THR, Thread::top_resource_offset());
  __ StoreToOffset(kWord, R6, THR, Thread::top_exit_frame_info_offset());

  // kExitLinkSlotFromEntryFp must be kept in sync with the code below.
  __ Push(R4);
  ASSERT(kExitLinkSlotFromEntryFp == -26);
  __ Push(R5);

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
  __ cmp(R1, Operand(R5));
  __ b(&push_arguments, LT);
  __ Bind(&done_push_arguments);

  // Call the Dart code entrypoint.
  __ blx(R0);  // R4 is the arguments descriptor array.

  // Get rid of arguments pushed on the stack.
  __ AddImmediate(SP, FP, kExitLinkSlotFromEntryFp * kWordSize);

  __ LoadIsolate(R9);
  // Restore the saved top exit frame info and top resource back into the
  // Isolate structure. Uses R5 as a temporary register for this.
  __ Pop(R5);
  __ StoreToOffset(kWord, R5, THR, Thread::top_exit_frame_info_offset());
  __ Pop(R5);
  __ StoreToOffset(kWord, R5, THR, Thread::top_resource_offset());

  // Restore the current VMTag from the stack.
  __ Pop(R4);
  __ StoreToOffset(kWord, R4, R9, Isolate::vm_tag_offset());

  // Restore C++ ABI callee-saved registers.
  if (TargetCPUFeatures::vfp_supported()) {
    // Restore FPU registers. 2 D registers per Q register.
    __ vldmd(IA_W, SP, firstd, 2 * kAbiPreservedFpuRegCount);
  } else {
    __ AddImmediate(SP, kAbiPreservedFpuRegCount * kFpuRegisterSize);
  }
  // Restore CPU registers.
  __ PopList(kAbiPreservedCpuRegs);
  __ set_constant_pool_allowed(false);

  // Restore the frame pointer and return.
  __ LeaveFrame((1 << FP) | (1 << LR));
  __ Ret();
}


// Called for inline allocation of contexts.
// Input:
//   R1: number of context variables.
// Output:
//   R0: new allocated RawContext object.
void StubCode::GenerateAllocateContextStub(Assembler* assembler) {
  if (FLAG_inline_alloc) {
    Label slow_case;
    // First compute the rounded instance size.
    // R1: number of context variables.
    intptr_t fixed_size = sizeof(RawContext) + kObjectAlignment - 1;
    __ LoadImmediate(R2, fixed_size);
    __ add(R2, R2, Operand(R1, LSL, 2));
    ASSERT(kSmiTagShift == 1);
    __ bic(R2, R2, Operand(kObjectAlignment - 1));

    __ MaybeTraceAllocation(kContextCid, R4, &slow_case,
                            /* inline_isolate = */ false);
    // Now allocate the object.
    // R1: number of context variables.
    // R2: object size.
    const intptr_t cid = kContextCid;
    Heap::Space space = Heap::SpaceForAllocation(cid);
    __ LoadIsolate(R5);
    __ ldr(R5, Address(R5, Isolate::heap_offset()));
    __ ldr(R0, Address(R5, Heap::TopOffset(space)));
    __ add(R3, R2, Operand(R0));
    // Check if the allocation fits into the remaining space.
    // R0: potential new object.
    // R1: number of context variables.
    // R2: object size.
    // R3: potential next object start.
    // R5: heap.
    __ ldr(IP, Address(R5, Heap::EndOffset(space)));
    __ cmp(R3, Operand(IP));
    if (FLAG_use_slow_path) {
      __ b(&slow_case);
    } else {
      __ b(&slow_case, CS);  // Branch if unsigned higher or equal.
    }

    // Successfully allocated the object, now update top to point to
    // next object start and initialize the object.
    // R0: new object start (untagged).
    // R1: number of context variables.
    // R2: object size.
    // R3: next object start.
    // R5: heap.
    __ LoadAllocationStatsAddress(R6, cid, /* inline_isolate = */ false);
    __ str(R3, Address(R5, Heap::TopOffset(space)));
    __ add(R0, R0, Operand(kHeapObjectTag));

    // Calculate the size tag.
    // R0: new object (tagged).
    // R1: number of context variables.
    // R2: object size.
    // R3: next object start.
    // R6: allocation stats address.
    const intptr_t shift = RawObject::kSizeTagPos - kObjectAlignmentLog2;
    __ CompareImmediate(R2, RawObject::SizeTag::kMaxSizeTag);
    // If no size tag overflow, shift R2 left, else set R2 to zero.
    __ mov(R5, Operand(R2, LSL, shift), LS);
    __ mov(R5, Operand(0), HI);

    // Get the class index and insert it into the tags.
    // R5: size and bit tags.
    __ LoadImmediate(IP, RawObject::ClassIdTag::encode(cid));
    __ orr(R5, R5, Operand(IP));
    __ str(R5, FieldAddress(R0, Context::tags_offset()));

    // Setup up number of context variables field.
    // R0: new object.
    // R1: number of context variables as integer value (not object).
    // R2: object size.
    // R3: next object start.
    // R6: allocation stats address.
    __ str(R1, FieldAddress(R0, Context::num_variables_offset()));

    // Setup the parent field.
    // R0: new object.
    // R1: number of context variables.
    // R2: object size.
    // R3: next object start.
    // R6: allocation stats address.
    __ LoadObject(R4, Object::null_object());
    __ InitializeFieldNoBarrier(R0, FieldAddress(R0, Context::parent_offset()),
                                R4);

    // Initialize the context variables.
    // R0: new object.
    // R1: number of context variables.
    // R2: object size.
    // R3: next object start.
    // R4, R5: raw null.
    // R6: allocation stats address.
    Label loop;
    __ AddImmediate(R7, R0, Context::variable_offset(0) - kHeapObjectTag);
    __ InitializeFieldsNoBarrier(R0, R7, R3, R4, R5);
    __ IncrementAllocationStatsWithSize(R6, R2, space);

    // Done allocating and initializing the context.
    // R0: new object.
    __ Ret();

    __ Bind(&slow_case);
  }
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value.
  __ LoadObject(R2, Object::null_object());
  __ SmiTag(R1);
  __ PushList((1 << R1) | (1 << R2));
  __ CallRuntime(kAllocateContextRuntimeEntry, 1);  // Allocate context.
  __ Drop(1);  // Pop number of context variables argument.
  __ Pop(R0);  // Pop the new context object.
  // R0: new object
  // Restore the frame pointer.
  __ LeaveStubFrame();
  __ Ret();
}


// Helper stub to implement Assembler::StoreIntoObject.
// Input parameters:
//   R0: address (i.e. object) being stored into.
void StubCode::GenerateUpdateStoreBufferStub(Assembler* assembler) {
  // Save values being destroyed.
  __ PushList((1 << R1) | (1 << R2) | (1 << R3));

  Label add_to_buffer;
  // Check whether this object has already been remembered. Skip adding to the
  // store buffer if the object is in the store buffer already.
  // Spilled: R1, R2, R3
  // R0: Address being stored
  __ ldr(R2, FieldAddress(R0, Object::tags_offset()));
  __ tst(R2, Operand(1 << RawObject::kRememberedBit));
  __ b(&add_to_buffer, EQ);
  __ PopList((1 << R1) | (1 << R2) | (1 << R3));
  __ Ret();

  __ Bind(&add_to_buffer);
  // R2: Header word.
  if (TargetCPUFeatures::arm_version() == ARMv5TE) {
    // TODO(21263): Implement 'swp' and use it below.
#if !defined(USING_SIMULATOR)
    ASSERT(OS::NumberOfAvailableProcessors() <= 1);
#endif
    __ orr(R2, R2, Operand(1 << RawObject::kRememberedBit));
    __ str(R2, FieldAddress(R0, Object::tags_offset()));
  } else {
    // Atomically set the remembered bit of the object header.
    ASSERT(Object::tags_offset() == 0);
    __ sub(R3, R0, Operand(kHeapObjectTag));
    // R3: Untagged address of header word (ldrex/strex do not support offsets).
    Label retry;
    __ Bind(&retry);
    __ ldrex(R2, R3);
    __ orr(R2, R2, Operand(1 << RawObject::kRememberedBit));
    __ strex(R1, R2, R3);
    __ cmp(R1, Operand(1));
    __ b(&retry, EQ);
  }

  // Load the StoreBuffer block out of the thread. Then load top_ out of the
  // StoreBufferBlock and add the address to the pointers_.
  __ ldr(R1, Address(THR, Thread::store_buffer_block_offset()));
  __ ldr(R2, Address(R1, StoreBufferBlock::top_offset()));
  __ add(R3, R1, Operand(R2, LSL, 2));
  __ str(R0, Address(R3, StoreBufferBlock::pointers_offset()));

  // Increment top_ and check for overflow.
  // R2: top_.
  // R1: StoreBufferBlock.
  Label L;
  __ add(R2, R2, Operand(1));
  __ str(R2, Address(R1, StoreBufferBlock::top_offset()));
  __ CompareImmediate(R2, StoreBufferBlock::kSize);
  // Restore values.
  __ PopList((1 << R1) | (1 << R2) | (1 << R3));
  __ b(&L, EQ);
  __ Ret();

  // Handle overflow: Call the runtime leaf function.
  __ Bind(&L);
  // Setup frame, push callee-saved registers.

  __ EnterCallRuntimeFrame(0 * kWordSize);
  __ mov(R0, Operand(THR));
  __ CallRuntime(kStoreBufferBlockProcessRuntimeEntry, 1);
  // Restore callee-saved registers, tear down frame.
  __ LeaveCallRuntimeFrame();
  __ Ret();
}


// Called for inline allocation of objects.
// Input parameters:
//   LR : return address.
//   SP + 0 : type arguments object (only if class is parameterized).
// Returns patch_code_pc offset where patching code for disabling the stub
// has been generated (similar to regularly generated Dart code).
void StubCode::GenerateAllocationStubForClass(
    Assembler* assembler, const Class& cls,
    uword* entry_patch_offset, uword* patch_code_pc_offset) {
  *entry_patch_offset = assembler->CodeSize();
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
  Isolate* isolate = Isolate::Current();
  if (FLAG_inline_alloc && Heap::IsAllocatableInNewSpace(instance_size) &&
      !cls.TraceAllocation(isolate)) {
    Label slow_case;
    // Allocate the object and update top to point to
    // next object start and initialize the allocated object.
    Heap::Space space = Heap::SpaceForAllocation(cls.id());
    __ ldr(R5, Address(THR, Thread::heap_offset()));
    __ ldr(R0, Address(R5, Heap::TopOffset(space)));
    __ AddImmediate(R1, R0, instance_size);
    // Check if the allocation fits into the remaining space.
    // R0: potential new object start.
    // R1: potential next object start.
    // R5: heap.
    __ ldr(IP, Address(R5, Heap::EndOffset(space)));
    __ cmp(R1, Operand(IP));
    if (FLAG_use_slow_path) {
      __ b(&slow_case);
    } else {
      __ b(&slow_case, CS);  // Unsigned higher or equal.
    }
    __ str(R1, Address(R5, Heap::TopOffset(space)));

    // Load the address of the allocation stats table. We split up the load
    // and the increment so that the dependent load is not too nearby.
    __ LoadAllocationStatsAddress(R5, cls.id(), /* inline_isolate = */ false);

    // R0: new object start.
    // R1: next object start.
    // R5: allocation stats table.
    // Set the tags.
    uword tags = 0;
    tags = RawObject::SizeTag::update(instance_size, tags);
    ASSERT(cls.id() != kIllegalCid);
    tags = RawObject::ClassIdTag::update(cls.id(), tags);
    __ LoadImmediate(R2, tags);
    __ str(R2, Address(R0, Instance::tags_offset()));
    __ add(R0, R0, Operand(kHeapObjectTag));

    // Initialize the remaining words of the object.
    __ LoadObject(R2, Object::null_object());

    // R2: raw null.
    // R0: new object (tagged).
    // R1: next object start.
    // R5: allocation stats table.
    // First try inlining the initialization without a loop.
    if (instance_size < (kInlineInstanceSize * kWordSize)) {
      // Small objects are initialized using a consecutive set of writes.
      intptr_t begin_offset = Instance::NextFieldOffset() - kHeapObjectTag;
      intptr_t end_offset = instance_size - kHeapObjectTag;
      // Save one move if less than two fields.
      if ((end_offset - begin_offset) >= (2 * kWordSize)) {
        __ mov(R3, Operand(R2));
      }
      __ InitializeFieldsNoBarrierUnrolled(R0, R0, begin_offset, end_offset,
                                           R2, R3);
    } else {
      // There are more than kInlineInstanceSize(12) fields
      __ add(R4, R0, Operand(Instance::NextFieldOffset() - kHeapObjectTag));
      __ mov(R3, Operand(R2));
      // Loop until the whole object is initialized.
      // R2: raw null.
      // R3: raw null.
      // R0: new object (tagged).
      // R1: next object start.
      // R4: next word to be initialized.
      // R5: allocation stats table.
      __ InitializeFieldsNoBarrier(R0, R4, R1, R2, R3);
    }
    if (is_cls_parameterized) {
      // Set the type arguments in the new object.
      __ ldr(R4, Address(SP, 0));
      FieldAddress type_args(R0, cls.type_arguments_field_offset());
      __ InitializeFieldNoBarrier(R0, type_args, R4);
    }

    // Done allocating and initializing the instance.
    // R0: new object (tagged).
    // R5: allocation stats table.

    // Update allocation stats.
    __ IncrementAllocationStats(R5, cls.id(), space);

    // R0: new object (tagged).
    __ Ret();

    __ Bind(&slow_case);
  }
  if (is_cls_parameterized) {
    // Load the type arguments.
    __ ldr(R4, Address(SP, 0));
  }
  // If is_cls_parameterized:
  // R4: new object type arguments.
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();  // Uses pool pointer to pass cls to runtime.
  __ LoadObject(R2, Object::null_object());
  __ Push(R2);  // Setup space on stack for return value.
  __ PushObject(cls);  // Push class of object to be allocated.
  if (is_cls_parameterized) {
    // Push type arguments.
    __ Push(R4);
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
  __ Ret();
  *patch_code_pc_offset = assembler->CodeSize();
  __ BranchPatchable(*StubCode::FixAllocationStubTarget_entry());
}


// Called for invoking "dynamic noSuchMethod(Invocation invocation)" function
// from the entry code of a dart function after an error in passed argument
// name or number is detected.
// Input parameters:
//  LR : return address.
//  SP : address of last argument.
//  R4: arguments descriptor array.
void StubCode::GenerateCallClosureNoSuchMethodStub(Assembler* assembler) {
  __ EnterStubFrame();

  // Load the receiver.
  __ ldr(R2, FieldAddress(R4, ArgumentsDescriptor::count_offset()));
  __ add(IP, FP, Operand(R2, LSL, 1));  // R2 is Smi.
  __ ldr(R6, Address(IP, kParamEndSlotFromFp * kWordSize));

  // Push space for the return value.
  // Push the receiver.
  // Push arguments descriptor array.
  __ LoadObject(IP, Object::null_object());
  __ PushList((1 << R4) | (1 << R6) | (1 << IP));

  // R2: Smi-tagged arguments array length.
  PushArgumentsArray(assembler);

  const intptr_t kNumArgs = 3;
  __ CallRuntime(kInvokeClosureNoSuchMethodRuntimeEntry, kNumArgs);
  // noSuchMethod on closures always throws an error, so it will never return.
  __ bkpt(0);
}


//  R6: function object.
//  R5: inline cache data object.
// Cannot use function object from ICData as it may be the inlined
// function and not the top-scope function.
void StubCode::GenerateOptimizedUsageCounterIncrement(Assembler* assembler) {
  Register ic_reg = R5;
  Register func_reg = R6;
  if (FLAG_trace_optimized_ic_calls) {
    __ EnterStubFrame();
    __ PushList((1 << R5) | (1 << R6));  // Preserve.
    __ Push(ic_reg);  // Argument.
    __ Push(func_reg);  // Argument.
    __ CallRuntime(kTraceICCallRuntimeEntry, 2);
    __ Drop(2);  // Discard argument;
    __ PopList((1 << R5) | (1 << R6));  // Restore.
    __ LeaveStubFrame();
  }
  __ ldr(R7, FieldAddress(func_reg, Function::usage_counter_offset()));
  __ add(R7, R7, Operand(1));
  __ str(R7, FieldAddress(func_reg, Function::usage_counter_offset()));
}


// Loads function into 'temp_reg'.
void StubCode::GenerateUsageCounterIncrement(Assembler* assembler,
                                             Register temp_reg) {
  if (FLAG_optimization_counter_threshold >= 0) {
    Register ic_reg = R5;
    Register func_reg = temp_reg;
    ASSERT(temp_reg == R6);
    __ Comment("Increment function counter");
    __ ldr(func_reg, FieldAddress(ic_reg, ICData::owner_offset()));
    __ ldr(R7, FieldAddress(func_reg, Function::usage_counter_offset()));
    __ add(R7, R7, Operand(1));
    __ str(R7, FieldAddress(func_reg, Function::usage_counter_offset()));
  }
}


// Note: R5 must be preserved.
// Attempt a quick Smi operation for known operations ('kind'). The ICData
// must have been primed with a Smi/Smi check that will be used for counting
// the invocations.
static void EmitFastSmiOp(Assembler* assembler,
                          Token::Kind kind,
                          intptr_t num_args,
                          Label* not_smi_or_overflow) {
  __ Comment("Fast Smi op");
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ ldr(R1, Address(SP, 1 * kWordSize));
  __ orr(TMP, R0, Operand(R1));
  __ tst(TMP, Operand(kSmiTagMask));
  __ b(not_smi_or_overflow, NE);
  switch (kind) {
    case Token::kADD: {
      __ adds(R0, R1, Operand(R0));  // Adds.
      __ b(not_smi_or_overflow, VS);  // Branch if overflow.
      break;
    }
    case Token::kSUB: {
      __ subs(R0, R1, Operand(R0));  // Subtract.
      __ b(not_smi_or_overflow, VS);  // Branch if overflow.
      break;
    }
    case Token::kEQ: {
      __ cmp(R0, Operand(R1));
      __ LoadObject(R0, Bool::True(), EQ);
      __ LoadObject(R0, Bool::False(), NE);
      break;
    }
    default: UNIMPLEMENTED();
  }
  // R5: IC data object (preserved).
  __ ldr(R6, FieldAddress(R5, ICData::ic_data_offset()));
  // R6: ic_data_array with check entries: classes and target functions.
  __ AddImmediate(R6, R6, Array::data_offset() - kHeapObjectTag);
  // R6: points directly to the first ic data array element.
#if defined(DEBUG)
  // Check that first entry is for Smi/Smi.
  Label error, ok;
  const intptr_t imm_smi_cid = reinterpret_cast<intptr_t>(Smi::New(kSmiCid));
  __ ldr(R1, Address(R6, 0));
  __ CompareImmediate(R1, imm_smi_cid);
  __ b(&error, NE);
  __ ldr(R1, Address(R6, kWordSize));
  __ CompareImmediate(R1, imm_smi_cid);
  __ b(&ok, EQ);
  __ Bind(&error);
  __ Stop("Incorrect IC data");
  __ Bind(&ok);
#endif
  if (FLAG_optimization_counter_threshold >= 0) {
    // Update counter.
    const intptr_t count_offset = ICData::CountIndexFor(num_args) * kWordSize;
    __ LoadFromOffset(kWord, R1, R6, count_offset);
    __ adds(R1, R1, Operand(Smi::RawValue(1)));
    __ LoadImmediate(R1, Smi::RawValue(Smi::kMaxValue), VS);  // Overflow.
    __ StoreIntoSmiField(Address(R6, count_offset), R1);
  }
  __ Ret();
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
    const RuntimeEntry& handle_ic_miss,
    Token::Kind kind,
    RangeCollectionMode range_collection_mode,
    bool optimized) {
  ASSERT(num_args > 0);
#if defined(DEBUG)
  { Label ok;
    // Check that the IC data array has NumArgsTested() == num_args.
    // 'NumArgsTested' is stored in the least significant bits of 'state_bits'.
    __ ldr(R6, FieldAddress(R5, ICData::state_bits_offset()));
    ASSERT(ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ and_(R6, R6, Operand(ICData::NumArgsTestedMask()));
    __ CompareImmediate(R6, num_args);
    __ b(&ok, EQ);
    __ Stop("Incorrect stub for IC data");
    __ Bind(&ok);
  }
#endif  // DEBUG

  Label stepping, done_stepping;
  if (FLAG_support_debugger && !optimized) {
    __ Comment("Check single stepping");
    __ LoadIsolate(R6);
    __ ldrb(R6, Address(R6, Isolate::single_step_offset()));
    __ CompareImmediate(R6, 0);
    __ b(&stepping, NE);
    __ Bind(&done_stepping);
  }

  __ Comment("Range feedback collection");
  Label not_smi_or_overflow;
  if (range_collection_mode == kCollectRanges) {
    ASSERT((num_args == 1) || (num_args == 2));
    if (num_args == 2) {
      __ ldr(R0, Address(SP, 1 * kWordSize));
      __ UpdateRangeFeedback(R0, 0, R5, R1, R4, &not_smi_or_overflow);
    }

    __ ldr(R0, Address(SP, 0 * kWordSize));
    __ UpdateRangeFeedback(R0, num_args - 1, R5, R1, R4, &not_smi_or_overflow);
  }
  if (kind != Token::kILLEGAL) {
    EmitFastSmiOp(assembler, kind, num_args, &not_smi_or_overflow);
  }
  __ Bind(&not_smi_or_overflow);

  __ Comment("Extract ICData initial values and receiver cid");
  // Load arguments descriptor into R4.
  __ ldr(R4, FieldAddress(R5, ICData::arguments_descriptor_offset()));
  // Loop that checks if there is an IC data match.
  Label loop, update, test, found;
  // R5: IC data object (preserved).
  __ ldr(R6, FieldAddress(R5, ICData::ic_data_offset()));
  // R6: ic_data_array with check entries: classes and target functions.
  __ AddImmediate(R6, R6, Array::data_offset() - kHeapObjectTag);
  // R6: points directly to the first ic data array element.

  // Get the receiver's class ID (first read number of arguments from
  // arguments descriptor array and then access the receiver from the stack).
  __ ldr(R7, FieldAddress(R4, ArgumentsDescriptor::count_offset()));
  __ sub(R7, R7, Operand(Smi::RawValue(1)));
  __ ldr(R0, Address(SP, R7, LSL, 1));  // R7 (argument_count - 1) is smi.
  __ LoadTaggedClassIdMayBeSmi(R0, R0);
  // R7: argument_count - 1 (smi).
  // R0: receiver's class ID (smi).
  __ ldr(R1, Address(R6, 0));  // First class id (smi) to check.
  __ b(&test);

  __ Comment("ICData loop");
  __ Bind(&loop);
  for (int i = 0; i < num_args; i++) {
    if (i > 0) {
      // If not the first, load the next argument's class ID.
      __ AddImmediate(R0, R7, Smi::RawValue(-i));
      __ ldr(R0, Address(SP, R0, LSL, 1));
      __ LoadTaggedClassIdMayBeSmi(R0, R0);
      // R0: next argument class ID (smi).
      __ LoadFromOffset(kWord, R1, R6, i * kWordSize);
      // R1: next class ID to check (smi).
    }
    __ cmp(R0, Operand(R1));  // Class id match?
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
    __ ldr(R0, Address(SP, R7, LSL, 1));
    __ LoadTaggedClassIdMayBeSmi(R0, R0);
  }

  const intptr_t entry_size = ICData::TestEntryLengthFor(num_args) * kWordSize;
  __ AddImmediate(R6, entry_size);  // Next entry.
  __ ldr(R1, Address(R6, 0));  // Next class ID.

  __ Bind(&test);
  __ CompareImmediate(R1, Smi::RawValue(kIllegalCid));  // Done?
  __ b(&loop, NE);

  __ Comment("IC miss");
  // Compute address of arguments.
  // R7: argument_count - 1 (smi).
  __ add(R7, SP, Operand(R7, LSL, 1));  // R7 is Smi.
  // R7: address of receiver.
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ LoadObject(R0, Object::null_object());
  // Preserve IC data object and arguments descriptor array and
  // setup space on stack for result (target code object).
  __ PushList((1 << R0) | (1 << R4) | (1 << R5));
  // Push call arguments.
  for (intptr_t i = 0; i < num_args; i++) {
    __ LoadFromOffset(kWord, IP, R7, -i * kWordSize);
    __ Push(IP);
  }
  // Pass IC data object.
  __ Push(R5);
  __ CallRuntime(handle_ic_miss, num_args + 1);
  // Remove the call arguments pushed earlier, including the IC data object.
  __ Drop(num_args + 1);
  // Pop returned function object into R0.
  // Restore arguments descriptor array and IC data array.
  __ PopList((1 << R0) | (1 << R4) | (1 << R5));
  __ LeaveStubFrame();
  Label call_target_function;
  if (!FLAG_lazy_dispatchers) {
    GenerateDispatcherCode(assembler, &call_target_function);
  } else {
    __ b(&call_target_function);
  }

  __ Bind(&found);
  // R6: pointer to an IC data check group.
  const intptr_t target_offset = ICData::TargetIndexFor(num_args) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(num_args) * kWordSize;
  __ LoadFromOffset(kWord, R0, R6, target_offset);

  if (FLAG_optimization_counter_threshold >= 0) {
    __ Comment("Update caller's counter");
    __ LoadFromOffset(kWord, R1, R6, count_offset);
    __ adds(R1, R1, Operand(Smi::RawValue(1)));
    __ LoadImmediate(R1, Smi::RawValue(Smi::kMaxValue), VS);  // Overflow.
    __ StoreIntoSmiField(Address(R6, count_offset), R1);
  }

  __ Comment("Call target");
  __ Bind(&call_target_function);
  // R0: target function.
  __ ldr(R2, FieldAddress(R0, Function::entry_point_offset()));
  if (range_collection_mode == kCollectRanges) {
    __ ldr(R1, Address(SP, 0 * kWordSize));
    if (num_args == 2) {
      __ ldr(R3, Address(SP, 1 * kWordSize));
    }
    __ EnterStubFrame();
    if (num_args == 2) {
      __ PushList((1 << R1) | (1 << R3) | (1 << R5));
    } else {
      __ PushList((1 << R1) | (1 << R5));
    }
    __ blx(R2);

    Label done;
    __ ldr(R5, Address(FP, kFirstLocalSlotFromFp * kWordSize));
    __ UpdateRangeFeedback(R0, 2, R5, R1, R4, &done);
    __ Bind(&done);
    __ LeaveStubFrame();
    __ Ret();
  } else {
    __ bx(R2);
  }

  if (FLAG_support_debugger && !optimized) {
    __ Bind(&stepping);
    __ EnterStubFrame();
    __ Push(R5);  // Preserve IC data.
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ Pop(R5);
    __ LeaveStubFrame();
    __ b(&done_stepping);
  }
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
  GenerateNArgsCheckInlineCacheStub(assembler,
      1,
      kInlineCacheMissHandlerOneArgRuntimeEntry,
      Token::kILLEGAL,
      kIgnoreRanges);
}


void StubCode::GenerateTwoArgsCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
  GenerateNArgsCheckInlineCacheStub(assembler,
      2,
      kInlineCacheMissHandlerTwoArgsRuntimeEntry,
      Token::kILLEGAL,
      kIgnoreRanges);
}


void StubCode::GenerateSmiAddInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
  GenerateNArgsCheckInlineCacheStub(assembler,
      2,
      kInlineCacheMissHandlerTwoArgsRuntimeEntry,
      Token::kADD,
      kCollectRanges);
}


void StubCode::GenerateSmiSubInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
  GenerateNArgsCheckInlineCacheStub(assembler, 2,
      kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kSUB,
      kCollectRanges);
}


void StubCode::GenerateSmiEqualInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
  GenerateNArgsCheckInlineCacheStub(assembler, 2,
      kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kEQ,
      kIgnoreRanges);
}


void StubCode::GenerateUnaryRangeCollectingInlineCacheStub(
    Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
  GenerateNArgsCheckInlineCacheStub(assembler, 1,
      kInlineCacheMissHandlerOneArgRuntimeEntry,
      Token::kILLEGAL,
      kCollectRanges);
}


void StubCode::GenerateBinaryRangeCollectingInlineCacheStub(
    Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
  GenerateNArgsCheckInlineCacheStub(assembler, 2,
      kInlineCacheMissHandlerTwoArgsRuntimeEntry,
      Token::kILLEGAL,
      kCollectRanges);
}


void StubCode::GenerateOneArgOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateOptimizedUsageCounterIncrement(assembler);
  GenerateNArgsCheckInlineCacheStub(assembler, 1,
      kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      kIgnoreRanges, true /* optimized */);
}


void StubCode::GenerateTwoArgsOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateOptimizedUsageCounterIncrement(assembler);
  GenerateNArgsCheckInlineCacheStub(assembler, 2,
      kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kIgnoreRanges, true /* optimized */);
}


// Intermediary stub between a static call and its target. ICData contains
// the target function and the call count.
// R5: ICData
void StubCode::GenerateZeroArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
#if defined(DEBUG)
  { Label ok;
    // Check that the IC data array has NumArgsTested() == 0.
    // 'NumArgsTested' is stored in the least significant bits of 'state_bits'.
    __ ldr(R6, FieldAddress(R5, ICData::state_bits_offset()));
    ASSERT(ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ and_(R6, R6, Operand(ICData::NumArgsTestedMask()));
    __ CompareImmediate(R6, 0);
    __ b(&ok, EQ);
    __ Stop("Incorrect IC data for unoptimized static call");
    __ Bind(&ok);
  }
#endif  // DEBUG

  // Check single stepping.
  Label stepping, done_stepping;
  if (FLAG_support_debugger) {
    __ LoadIsolate(R6);
    __ ldrb(R6, Address(R6, Isolate::single_step_offset()));
    __ CompareImmediate(R6, 0);
    __ b(&stepping, NE);
    __ Bind(&done_stepping);
  }

  // R5: IC data object (preserved).
  __ ldr(R6, FieldAddress(R5, ICData::ic_data_offset()));
  // R6: ic_data_array with entries: target functions and count.
  __ AddImmediate(R6, R6, Array::data_offset() - kHeapObjectTag);
  // R6: points directly to the first ic data array element.
  const intptr_t target_offset = ICData::TargetIndexFor(0) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(0) * kWordSize;

  if (FLAG_optimization_counter_threshold >= 0) {
    // Increment count for this call.
    __ LoadFromOffset(kWord, R1, R6, count_offset);
    __ adds(R1, R1, Operand(Smi::RawValue(1)));
    __ LoadImmediate(R1, Smi::RawValue(Smi::kMaxValue), VS);  // Overflow.
    __ StoreIntoSmiField(Address(R6, count_offset), R1);
  }

  // Load arguments descriptor into R4.
  __ ldr(R4, FieldAddress(R5, ICData::arguments_descriptor_offset()));

  // Get function and call it, if possible.
  __ LoadFromOffset(kWord, R0, R6, target_offset);
  __ ldr(R2, FieldAddress(R0, Function::entry_point_offset()));
  __ bx(R2);

  if (FLAG_support_debugger) {
    __ Bind(&stepping);
    __ EnterStubFrame();
    __ Push(R5);  // Preserve IC data.
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ Pop(R5);
    __ LeaveStubFrame();
    __ b(&done_stepping);
  }
}


void StubCode::GenerateOneArgUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kStaticCallMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      kIgnoreRanges);
}


void StubCode::GenerateTwoArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
  GenerateNArgsCheckInlineCacheStub(assembler, 2,
      kStaticCallMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kIgnoreRanges);
}


// Stub for compiling a function and jumping to the compiled code.
// R5: IC-Data (for methods).
// R4: Arguments descriptor.
// R0: Function.
void StubCode::GenerateLazyCompileStub(Assembler* assembler) {
  // Preserve arg desc. and IC data object.
  __ EnterStubFrame();
  __ PushList((1 << R4) | (1 << R5));
  __ Push(R0);  // Pass function.
  __ CallRuntime(kCompileFunctionRuntimeEntry, 1);
  __ Pop(R0);  // Restore argument.
  __ PopList((1 << R4) | (1 << R5));  // Restore arg desc. and IC data.
  __ LeaveStubFrame();

  __ ldr(R2, FieldAddress(R0, Function::entry_point_offset()));
  __ bx(R2);
}


// R5: Contains an ICData.
void StubCode::GenerateICCallBreakpointStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ LoadObject(R0, Object::null_object());
  // Preserve arguments descriptor and make room for result.
  __ PushList((1 << R0) | (1 << R5));
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ PopList((1 << R0) | (1 << R5));
  __ LeaveStubFrame();
  __ bx(R0);
}


void StubCode::GenerateRuntimeCallBreakpointStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ LoadObject(R0, Object::null_object());
  // Make room for result.
  __ PushList((1 << R0));
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ PopList((1 << R0));
  __ LeaveStubFrame();
  __ bx(R0);
}


// Called only from unoptimized code. All relevant registers have been saved.
void StubCode::GenerateDebugStepCheckStub(
    Assembler* assembler) {
  // Check single stepping.
  Label stepping, done_stepping;
  __ LoadIsolate(R1);
  __ ldrb(R1, Address(R1, Isolate::single_step_offset()));
  __ CompareImmediate(R1, 0);
  __ b(&stepping, NE);
  __ Bind(&done_stepping);
  __ Ret();

  __ Bind(&stepping);
  __ EnterStubFrame();
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ LeaveStubFrame();
  __ b(&done_stepping);
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
    __ LoadObject(R4, Object::null_object());
    __ ldr(R5, FieldAddress(R3,
        Class::type_arguments_field_offset_in_words_offset()));
    __ CompareImmediate(R5, Class::kNoTypeArguments);
    __ b(&has_no_type_arguments, EQ);
    __ add(R5, R0, Operand(R5, LSL, 2));
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
  // R2: entry start.
  // R3: instance class id.
  // R4: instance type arguments.
  __ SmiTag(R3);
  __ Bind(&loop);
  __ ldr(R5, Address(R2, kWordSize * SubtypeTestCache::kInstanceClassId));
  __ CompareObject(R5, Object::null_object());
  __ b(&not_found, EQ);
  __ cmp(R5, Operand(R3));
  if (n == 1) {
    __ b(&found, EQ);
  } else {
    __ b(&next_iteration, NE);
    __ ldr(R5,
           Address(R2, kWordSize * SubtypeTestCache::kInstanceTypeArguments));
    __ cmp(R5, Operand(R4));
    if (n == 2) {
      __ b(&found, EQ);
    } else {
      __ b(&next_iteration, NE);
      __ ldr(R5, Address(R2, kWordSize *
                             SubtypeTestCache::kInstantiatorTypeArguments));
      __ cmp(R5, Operand(R1));
      __ b(&found, EQ);
    }
  }
  __ Bind(&next_iteration);
  __ AddImmediate(R2, kWordSize * SubtypeTestCache::kTestEntryLength);
  __ b(&loop);
  // Fall through to not found.
  __ Bind(&not_found);
  __ LoadObject(R1, Object::null_object());
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


// Return the current stack pointer address, used to do stack alignment checks.
void StubCode::GenerateGetStackPointerStub(Assembler* assembler) {
  __ mov(R0, Operand(SP));
  __ Ret();
}


// Jump to the exception or error handler.
// LR: return address.
// R0: program_counter.
// R1: stack_pointer.
// R2: frame_pointer.
// R3: error object.
// SP + 0: address of stacktrace object.
// SP + 4: thread.
// Does not return.
void StubCode::GenerateJumpToExceptionHandlerStub(Assembler* assembler) {
  ASSERT(kExceptionObjectReg == R0);
  ASSERT(kStackTraceObjectReg == R1);
  __ mov(IP, Operand(R1));  // Copy Stack pointer into IP.
  __ mov(LR, Operand(R0));  // Program counter.
  __ mov(R0, Operand(R3));  // Exception object.
  __ ldr(R1, Address(SP, 0));  // StackTrace object.
  __ ldr(THR, Address(SP, 4));  // Thread.
  __ mov(FP, Operand(R2));  // Frame_pointer.
  __ mov(SP, Operand(IP));  // Set Stack pointer.
  __ LoadIsolate(R3);
  // Set the tag.
  __ LoadImmediate(R2, VMTag::kDartTagId);
  __ StoreToOffset(kWord, R2, R3, Isolate::vm_tag_offset());
  // Clear top exit frame.
  __ LoadImmediate(R2, 0);
  __ StoreToOffset(kWord, R2, THR, Thread::top_exit_frame_info_offset());
  __ bx(LR);  // Jump to the exception handler code.
}


// Calls to the runtime to optimize the given function.
// R6: function to be reoptimized.
// R4: argument descriptor (preserved).
void StubCode::GenerateOptimizeFunctionStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ Push(R4);
  __ LoadObject(IP, Object::null_object());
  __ Push(IP);  // Setup space on stack for return value.
  __ Push(R6);
  __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry, 1);
  __ Pop(R0);  // Discard argument.
  __ Pop(R0);  // Get Code object
  __ Pop(R4);  // Restore argument descriptor.
  __ ldr(R0, FieldAddress(R0, Code::entry_point_offset()));
  __ LeaveStubFrame();
  __ bx(R0);
  __ bkpt(0);
}


// Does identical check (object references are equal or not equal) with special
// checks for boxed numbers.
// LR: return address.
// Return Zero condition flag set if equal.
// Note: A Mint cannot contain a value that would fit in Smi, a Bigint
// cannot contain a value that fits in Mint or Smi.
static void GenerateIdenticalWithNumberCheckStub(Assembler* assembler,
                                                 const Register left,
                                                 const Register right,
                                                 const Register temp) {
  Label reference_compare, done, check_mint, check_bigint;
  // If any of the arguments is Smi do reference compare.
  __ tst(left, Operand(kSmiTagMask));
  __ b(&reference_compare, EQ);
  __ tst(right, Operand(kSmiTagMask));
  __ b(&reference_compare, EQ);

  // Value compare for two doubles.
  __ CompareClassId(left, kDoubleCid, temp);
  __ b(&check_mint, NE);
  __ CompareClassId(right, kDoubleCid, temp);
  __ b(&done, NE);

  // Double values bitwise compare.
  __ ldr(temp, FieldAddress(left, Double::value_offset() + 0 * kWordSize));
  __ ldr(IP, FieldAddress(right, Double::value_offset() + 0 * kWordSize));
  __ cmp(temp, Operand(IP));
  __ b(&done, NE);
  __ ldr(temp, FieldAddress(left, Double::value_offset() + 1 * kWordSize));
  __ ldr(IP, FieldAddress(right, Double::value_offset() + 1 * kWordSize));
  __ cmp(temp, Operand(IP));
  __ b(&done);

  __ Bind(&check_mint);
  __ CompareClassId(left, kMintCid, temp);
  __ b(&check_bigint, NE);
  __ CompareClassId(right, kMintCid, temp);
  __ b(&done, NE);
  __ ldr(temp, FieldAddress(left, Mint::value_offset() + 0 * kWordSize));
  __ ldr(IP, FieldAddress(right, Mint::value_offset() + 0 * kWordSize));
  __ cmp(temp, Operand(IP));
  __ b(&done, NE);
  __ ldr(temp, FieldAddress(left, Mint::value_offset() + 1 * kWordSize));
  __ ldr(IP, FieldAddress(right, Mint::value_offset() + 1 * kWordSize));
  __ cmp(temp, Operand(IP));
  __ b(&done);

  __ Bind(&check_bigint);
  __ CompareClassId(left, kBigintCid, temp);
  __ b(&reference_compare, NE);
  __ CompareClassId(right, kBigintCid, temp);
  __ b(&done, NE);
  __ EnterStubFrame();
  __ ReserveAlignedFrameSpace(2 * kWordSize);
  __ stm(IA, SP,  (1 << R0) | (1 << R1));
  __ CallRuntime(kBigintCompareRuntimeEntry, 2);
  // Result in R0, 0 means equal.
  __ LeaveStubFrame();
  __ cmp(R0, Operand(0));
  __ b(&done);

  __ Bind(&reference_compare);
  __ cmp(left, Operand(right));
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
  Label stepping, done_stepping;
  if (FLAG_support_debugger) {
    __ LoadIsolate(R1);
    __ ldrb(R1, Address(R1, Isolate::single_step_offset()));
    __ CompareImmediate(R1, 0);
    __ b(&stepping, NE);
    __ Bind(&done_stepping);
  }

  const Register temp = R2;
  const Register left = R1;
  const Register right = R0;
  __ ldr(left, Address(SP, 1 * kWordSize));
  __ ldr(right, Address(SP, 0 * kWordSize));
  GenerateIdenticalWithNumberCheckStub(assembler, left, right, temp);
  __ Ret();

  if (FLAG_support_debugger) {
    __ Bind(&stepping);
    __ EnterStubFrame();
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ LeaveStubFrame();
    __ b(&done_stepping);
  }
}


// Called from optimized code only.
// LR: return address.
// SP + 4: left operand.
// SP + 0: right operand.
// Return Zero condition flag set if equal.
void StubCode::GenerateOptimizedIdenticalWithNumberCheckStub(
    Assembler* assembler) {
  const Register temp = R2;
  const Register left = R1;
  const Register right = R0;
  __ ldr(left, Address(SP, 1 * kWordSize));
  __ ldr(right, Address(SP, 0 * kWordSize));
  GenerateIdenticalWithNumberCheckStub(assembler, left, right, temp);
  __ Ret();
}


void StubCode::EmitMegamorphicLookup(
    Assembler* assembler, Register receiver, Register cache, Register target) {
  ASSERT((cache != R0) && (cache != R2));
  __ LoadTaggedClassIdMayBeSmi(R0, receiver);
  // R0: class ID of the receiver (smi).
  __ ldr(R2, FieldAddress(cache, MegamorphicCache::buckets_offset()));
  __ ldr(R1, FieldAddress(R1, MegamorphicCache::mask_offset()));
  // R2: cache buckets array.
  // R1: mask.
  __ mov(R3, Operand(R0));

  Label loop, update, call_target_function;
  __ b(&loop);

  __ Bind(&update);
  __ add(R3, R3, Operand(Smi::RawValue(1)));
  __ Bind(&loop);
  __ and_(R3, R3, Operand(R1));
  const intptr_t base = Array::data_offset();
  // R3 is smi tagged, but table entries are two words, so LSL 2.
  __ add(IP, R2, Operand(R3, LSL, 2));
  __ ldr(R4, FieldAddress(IP, base));

  ASSERT(kIllegalCid == 0);
  __ tst(R4, Operand(R4));
  __ b(&call_target_function, EQ);
  __ cmp(R4, Operand(R0));
  __ b(&update, NE);

  __ Bind(&call_target_function);
  // Call the target found in the cache.  For a class id match, this is a
  // proper target for the given name and arguments descriptor.  If the
  // illegal class id was found, the target is a cache miss handler that can
  // be invoked as a normal Dart function.
  __ add(IP, R2, Operand(R3, LSL, 2));
  __ ldr(R0, FieldAddress(IP, base + kWordSize));
  __ ldr(target, FieldAddress(R0, Function::entry_point_offset()));
}


// Called from megamorphic calls.
//  R0: receiver.
//  R1: lookup cache.
// Result:
//  R1: entry point.
void StubCode::GenerateMegamorphicLookupStub(Assembler* assembler) {
  EmitMegamorphicLookup(assembler, R0, R1, R1);
  __ Ret();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
