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
DECLARE_FLAG(bool, trace_optimized_ic_calls);

// Input parameters:
//   LR : return address.
//   SP : address of last argument in argument array.
//   SP + 8*R4 - 8 : address of first argument in argument array.
//   SP + 8*R4 : address of return value.
//   R5 : address of the runtime function to call.
//   R4 : number of arguments to the call.
void StubCode::GenerateCallToRuntimeStub(Assembler* assembler) {
  const intptr_t thread_offset = NativeArguments::thread_offset();
  const intptr_t argc_tag_offset = NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = NativeArguments::argv_offset();
  const intptr_t retval_offset = NativeArguments::retval_offset();

  __ SetPrologueOffset();
  __ Comment("CallToRuntimeStub");
  __ EnterStubFrame();

  // Save exit frame information to enable stack walking as we are about
  // to transition to Dart VM C++ code.
  __ StoreToOffset(FP, THR, Thread::top_exit_frame_info_offset());

#if defined(DEBUG)
  { Label ok;
    // Check that we are always entering from Dart code.
    __ LoadFromOffset(R8, THR, Thread::vm_tag_offset());
    __ CompareImmediate(R8, VMTag::kDartTagId);
    __ b(&ok, EQ);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the thread is executing VM code.
  __ StoreToOffset(R5, THR, Thread::vm_tag_offset());

  // Reserve space for arguments and align frame before entering C++ world.
  // NativeArguments are passed in registers.
  __ Comment("align stack");
  // Reserve space for arguments.
  ASSERT(sizeof(NativeArguments) == 4 * kWordSize);
  __ ReserveAlignedFrameSpace(sizeof(NativeArguments));

  // Pass NativeArguments structure by value and call runtime.
  // Registers R0, R1, R2, and R3 are used.

  ASSERT(thread_offset == 0 * kWordSize);
  // Set thread in NativeArgs.
  __ mov(R0, THR);

  // There are no runtime calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * kWordSize);
  __ mov(R1, R4);  // Set argc in NativeArguments.

  ASSERT(argv_offset == 2 * kWordSize);
  __ add(R2, ZR, Operand(R4, LSL, 3));
  __ add(R2, FP, Operand(R2));  // Compute argv.
  // Set argv in NativeArguments.
  __ AddImmediate(R2, R2, kParamEndSlotFromFp * kWordSize);

    ASSERT(retval_offset == 3 * kWordSize);
  __ AddImmediate(R3, R2, kWordSize);

  __ StoreToOffset(R0, SP, thread_offset);
  __ StoreToOffset(R1, SP, argc_tag_offset);
  __ StoreToOffset(R2, SP, argv_offset);
  __ StoreToOffset(R3, SP, retval_offset);
  __ mov(R0, SP);  // Pass the pointer to the NativeArguments.

  // We are entering runtime code, so the C stack pointer must be restored from
  // the stack limit to the top of the stack. We cache the stack limit address
  // in a callee-saved register.
  __ mov(R25, CSP);
  __ mov(CSP, SP);

  __ blr(R5);
  __ Comment("CallToRuntimeStub return");

  // Restore SP and CSP.
  __ mov(SP, CSP);
  __ mov(CSP, R25);

  // Retval is next to 1st argument.
  // Mark that the thread is executing Dart code.
  __ LoadImmediate(R2, VMTag::kDartTagId);
  __ StoreToOffset(R2, THR, Thread::vm_tag_offset());

  // Reset exit frame information in Isolate structure.
  __ StoreToOffset(ZR, THR, Thread::top_exit_frame_info_offset());

  __ LeaveStubFrame();
  __ ret();
}


// Print the stop message.
DEFINE_LEAF_RUNTIME_ENTRY(void, PrintStopMessage, 1, const char* message) {
  OS::Print("Stop message: %s\n", message);
}
END_LEAF_RUNTIME_ENTRY


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
  const intptr_t thread_offset = NativeArguments::thread_offset();
  const intptr_t argc_tag_offset = NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = NativeArguments::argv_offset();
  const intptr_t retval_offset = NativeArguments::retval_offset();

  __ EnterStubFrame();

  // Save exit frame information to enable stack walking as we are about
  // to transition to native code.
  __ StoreToOffset(FP, THR, Thread::top_exit_frame_info_offset());

#if defined(DEBUG)
  { Label ok;
    // Check that we are always entering from Dart code.
    __ LoadFromOffset(R6, THR, Thread::vm_tag_offset());
    __ CompareImmediate(R6, VMTag::kDartTagId);
    __ b(&ok, EQ);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the thread is executing native code.
  __ StoreToOffset(R5, THR, Thread::vm_tag_offset());

  // Reserve space for the native arguments structure passed on the stack (the
  // outgoing pointer parameter to the native arguments structure is passed in
  // R0) and align frame before entering the C++ world.
  __ ReserveAlignedFrameSpace(sizeof(NativeArguments));

  // Initialize NativeArguments structure and call native function.
  // Registers R0, R1, R2, and R3 are used.

  ASSERT(thread_offset == 0 * kWordSize);
  // Set thread in NativeArgs.
  __ mov(R0, THR);

  // There are no native calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * kWordSize);
  // Set argc in NativeArguments: R1 already contains argc.

  ASSERT(argv_offset == 2 * kWordSize);
  // Set argv in NativeArguments: R2 already contains argv.

  // Set retval in NativeArgs.
  ASSERT(retval_offset == 3 * kWordSize);
  __ AddImmediate(R3, FP, 2 * kWordSize);

  // Passing the structure by value as in runtime calls would require changing
  // Dart API for native functions.
  // For now, space is reserved on the stack and we pass a pointer to it.
  __ StoreToOffset(R0, SP, thread_offset);
  __ StoreToOffset(R1, SP, argc_tag_offset);
  __ StoreToOffset(R2, SP, argv_offset);
  __ StoreToOffset(R3, SP, retval_offset);
  __ mov(R0, SP);  // Pass the pointer to the NativeArguments.

  // We are entering runtime code, so the C stack pointer must be restored from
  // the stack limit to the top of the stack. We cache the stack limit address
  // in the Dart SP register, which is callee-saved in the C ABI.
  __ mov(R25, CSP);
  __ mov(CSP, SP);

  __ mov(R1, R5);  // Pass the function entrypoint to call.

  // Call native function invocation wrapper or redirection via simulator.
  __ ldr(LR, Address(THR, Thread::native_call_wrapper_entry_point_offset()));
  __ blr(LR);

  // Restore SP and CSP.
  __ mov(SP, CSP);
  __ mov(CSP, R25);

  // Mark that the thread is executing Dart code.
  __ LoadImmediate(R2, VMTag::kDartTagId);
  __ StoreToOffset(R2, THR, Thread::vm_tag_offset());

  // Reset exit frame information in Isolate structure.
  __ StoreToOffset(ZR, THR, Thread::top_exit_frame_info_offset());

  __ LeaveStubFrame();
  __ ret();
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

  // Save exit frame information to enable stack walking as we are about
  // to transition to native code.
  __ StoreToOffset(FP, THR, Thread::top_exit_frame_info_offset());

#if defined(DEBUG)
  { Label ok;
    // Check that we are always entering from Dart code.
    __ LoadFromOffset(R6, THR, Thread::vm_tag_offset());
    __ CompareImmediate(R6, VMTag::kDartTagId);
    __ b(&ok, EQ);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the thread is executing native code.
  __ StoreToOffset(R5, THR, Thread::vm_tag_offset());

  // Reserve space for the native arguments structure passed on the stack (the
  // outgoing pointer parameter to the native arguments structure is passed in
  // R0) and align frame before entering the C++ world.
  __ ReserveAlignedFrameSpace(sizeof(NativeArguments));

  // Initialize NativeArguments structure and call native function.
  // Registers R0, R1, R2, and R3 are used.

  ASSERT(thread_offset == 0 * kWordSize);
  // Set thread in NativeArgs.
  __ mov(R0, THR);

  // There are no native calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * kWordSize);
  // Set argc in NativeArguments: R1 already contains argc.

  ASSERT(argv_offset == 2 * kWordSize);
  // Set argv in NativeArguments: R2 already contains argv.

  // Set retval in NativeArgs.
  ASSERT(retval_offset == 3 * kWordSize);
  __ AddImmediate(R3, FP, 2 * kWordSize);

  // Passing the structure by value as in runtime calls would require changing
  // Dart API for native functions.
  // For now, space is reserved on the stack and we pass a pointer to it.
  __ StoreToOffset(R0, SP, thread_offset);
  __ StoreToOffset(R1, SP, argc_tag_offset);
  __ StoreToOffset(R2, SP, argv_offset);
  __ StoreToOffset(R3, SP, retval_offset);
  __ mov(R0, SP);  // Pass the pointer to the NativeArguments.

  // We are entering runtime code, so the C stack pointer must be restored from
  // the stack limit to the top of the stack. We cache the stack limit address
  // in the Dart SP register, which is callee-saved in the C ABI.
  __ mov(R25, CSP);
  __ mov(CSP, SP);

  // Call native function or redirection via simulator.
  __ blr(R5);

  // Restore SP and CSP.
  __ mov(SP, CSP);
  __ mov(CSP, R25);

  // Mark that the thread is executing Dart code.
  __ LoadImmediate(R2, VMTag::kDartTagId);
  __ StoreToOffset(R2, THR, Thread::vm_tag_offset());

  // Reset exit frame information in Isolate structure.
  __ StoreToOffset(ZR, THR, Thread::top_exit_frame_info_offset());

  __ LeaveStubFrame();
  __ ret();
}


// Input parameters:
//   R4: arguments descriptor array.
void StubCode::GenerateCallStaticFunctionStub(Assembler* assembler) {
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value and preserve arguments descriptor.
  __ Push(R4);
  __ Push(ZR);
  __ CallRuntime(kPatchStaticCallRuntimeEntry, 0);
  // Get Code object result and restore arguments descriptor array.
  __ Pop(CODE_REG);
  __ Pop(R4);
  // Remove the stub frame.
  __ LeaveStubFrame();
  // Jump to the dart function.
  __ LoadFieldFromOffset(R0, CODE_REG, Code::entry_point_offset());
  __ br(R0);
}


// Called from a static call only when an invalid code has been entered
// (invalid because its function was optimized or deoptimized).
// R4: arguments descriptor array.
void StubCode::GenerateFixCallersTargetStub(Assembler* assembler) {
  // Load code pointer to this stub from the thread:
  // The one that is passed in, is not correct - it points to the code object
  // that needs to be replaced.
  __ ldr(CODE_REG, Address(THR, Thread::fix_callers_target_code_offset()));
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value and preserve arguments descriptor.
  __ Push(R4);
  __ Push(ZR);
  __ CallRuntime(kFixCallersTargetRuntimeEntry, 0);
  // Get Code object result and restore arguments descriptor array.
  __ Pop(CODE_REG);
  __ Pop(R4);
  // Remove the stub frame.
  __ LeaveStubFrame();
  // Jump to the dart function.
  __ LoadFieldFromOffset(R0, CODE_REG, Code::entry_point_offset());
  __ br(R0);
}


// Called from object allocate instruction when the allocation stub has been
// disabled.
void StubCode::GenerateFixAllocationStubTargetStub(Assembler* assembler) {
  // Load code pointer to this stub from the thread:
  // The one that is passed in, is not correct - it points to the code object
  // that needs to be replaced.
  __ ldr(CODE_REG, Address(THR, Thread::fix_allocation_stub_code_offset()));
  __ EnterStubFrame();
  // Setup space on stack for return value.
  __ Push(ZR);
  __ CallRuntime(kFixAllocationStubTargetRuntimeEntry, 0);
  // Get Code object result.
  __ Pop(CODE_REG);
  // Remove the stub frame.
  __ LeaveStubFrame();
  // Jump to the dart function.
  __ LoadFieldFromOffset(R0, CODE_REG, Code::entry_point_offset());
  __ br(R0);
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
  __ add(R1, FP, Operand(R2, LSL, 2));
  __ AddImmediate(R1, R1, kParamEndSlotFromFp * kWordSize);
  __ AddImmediate(R3, R0, Array::data_offset() - kHeapObjectTag);
  // R1: address of first argument on stack.
  // R3: address of first argument in array.

  Label loop, loop_exit;
  __ CompareRegisters(R2, ZR);
  __ b(&loop_exit, LE);
  __ Bind(&loop);
  __ ldr(R7, Address(R1));
  __ AddImmediate(R1, R1, -kWordSize);
  __ AddImmediate(R3, R3, kWordSize);
  __ AddImmediateSetFlags(R2, R2, -Smi::RawValue(1));
  __ str(R7, Address(R3, -kWordSize));
  __ b(&loop, GE);
  __ Bind(&loop_exit);
}


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
// Stack after TagAndPushPP() below:
//   +------------------+
//   | Saved PP         | <- PP
//   +------------------+
//   | PC marker        | <- TOS
//   +------------------+
//   | Saved FP         | <- FP of stub
//   +------------------+
//   | return-address   |  (deoptimization point)
//   +------------------+
//   | Saved CODE_REG   |
//   +------------------+
//   | ...              | <- SP of optimized frame
//
// Parts of the code cannot GC, part of the code can GC.
static void GenerateDeoptimizationSequence(Assembler* assembler,
                                           DeoptStubKind kind) {
  // DeoptimizeCopyFrame expects a Dart frame, i.e. EnterDartFrame(0), but there
  // is no need to set the correct PC marker or load PP, since they get patched.
  __ EnterStubFrame();

  // The code in this frame may not cause GC. kDeoptimizeCopyFrameRuntimeEntry
  // and kDeoptimizeFillFrameRuntimeEntry are leaf runtime calls.
  const intptr_t saved_result_slot_from_fp =
      kFirstLocalSlotFromFp + 1 - (kNumberOfCpuRegisters - R0);
  const intptr_t saved_exception_slot_from_fp =
      kFirstLocalSlotFromFp + 1 - (kNumberOfCpuRegisters - R0);
  const intptr_t saved_stacktrace_slot_from_fp =
      kFirstLocalSlotFromFp + 1 - (kNumberOfCpuRegisters - R1);
  // Result in R0 is preserved as part of pushing all registers below.

  // Push registers in their enumeration order: lowest register number at
  // lowest address.
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; i--) {
    const Register r = static_cast<Register>(i);
    if (r == CODE_REG) {
      // Save the original value of CODE_REG pushed before invoking this stub
      // instead of the value used to call this stub.
      COMPILE_ASSERT(R25 > CODE_REG);
      __ ldr(R25, Address(FP, 2 * kWordSize));
      __ str(R25, Address(SP, -1 * kWordSize, Address::PreIndex));
    } else {
      __ str(r, Address(SP, -1 * kWordSize, Address::PreIndex));
    }
  }

  for (intptr_t reg_idx = kNumberOfVRegisters - 1; reg_idx >= 0; reg_idx--) {
    VRegister vreg = static_cast<VRegister>(reg_idx);
    __ PushQuad(vreg);
  }

  __ mov(R0, SP);  // Pass address of saved registers block.
  bool is_lazy = (kind == kLazyDeoptFromReturn) ||
                 (kind == kLazyDeoptFromThrow);
  __ LoadImmediate(R1, is_lazy ? 1 : 0);
  __ ReserveAlignedFrameSpace(0);
  __ CallRuntime(kDeoptimizeCopyFrameRuntimeEntry, 2);
  // Result (R0) is stack-size (FP - SP) in bytes.

  if (kind == kLazyDeoptFromReturn) {
    // Restore result into R1 temporarily.
    __ LoadFromOffset(R1, FP, saved_result_slot_from_fp * kWordSize);
  } else if (kind == kLazyDeoptFromThrow) {
    // Restore result into R1 temporarily.
    __ LoadFromOffset(R1, FP, saved_exception_slot_from_fp * kWordSize);
    __ LoadFromOffset(R2, FP, saved_stacktrace_slot_from_fp * kWordSize);
  }

  // There is a Dart Frame on the stack. We must restore PP and leave frame.
  __ RestoreCodePointer();
  __ LeaveStubFrame();
  __ sub(SP, FP, Operand(R0));

  // DeoptimizeFillFrame expects a Dart frame, i.e. EnterDartFrame(0), but there
  // is no need to set the correct PC marker or load PP, since they get patched.
  __ EnterStubFrame();

  if (kind == kLazyDeoptFromReturn) {
    __ Push(R1);  // Preserve result as first local.
  } else if (kind == kLazyDeoptFromThrow) {
    __ Push(R1);  // Preserve exception as first local.
    __ Push(R2);  // Preserve stacktrace as second local.
  }
  __ ReserveAlignedFrameSpace(0);
  __ mov(R0, FP);  // Pass last FP as parameter in R0.
  __ CallRuntime(kDeoptimizeFillFrameRuntimeEntry, 1);
  if (kind == kLazyDeoptFromReturn) {
    // Restore result into R1.
    __ LoadFromOffset(R1, FP, kFirstLocalSlotFromFp * kWordSize);
  } else if (kind == kLazyDeoptFromThrow) {
    // Restore result into R1.
    __ LoadFromOffset(R1, FP, kFirstLocalSlotFromFp * kWordSize);
    __ LoadFromOffset(R2, FP, (kFirstLocalSlotFromFp - 1) * kWordSize);
  }
  // Code above cannot cause GC.
  // There is a Dart Frame on the stack. We must restore PP and leave frame.
  __ RestoreCodePointer();
  __ LeaveStubFrame();

  // Frame is fully rewritten at this point and it is safe to perform a GC.
  // Materialize any objects that were deferred by FillFrame because they
  // require allocation.
  // Enter stub frame with loading PP. The caller's PP is not materialized yet.
  __ EnterStubFrame();
  if (kind == kLazyDeoptFromReturn) {
    __ Push(R1);  // Preserve result, it will be GC-d here.
  } else if (kind == kLazyDeoptFromThrow) {
    __ Push(R1);  // Preserve exception, it will be GC-d here.
    __ Push(R2);  // Preserve stacktrace, it will be GC-d here.
  }

  __ Push(ZR);  // Space for the result.
  __ CallRuntime(kDeoptimizeMaterializeRuntimeEntry, 0);
  // Result tells stub how many bytes to remove from the expression stack
  // of the bottom-most frame. They were used as materialization arguments.
  __ Pop(R2);
  __ SmiUntag(R2);
  if (kind == kLazyDeoptFromReturn) {
    __ Pop(R0);  // Restore result.
  } else if (kind == kLazyDeoptFromThrow) {
    __ Pop(R1);  // Restore stacktrace.
    __ Pop(R0);  // Restore exception.
  }
  __ LeaveStubFrame();
  // Remove materialization arguments.
  __ add(SP, SP, Operand(R2));
  __ ret();
}


// R0: result, must be preserved
void StubCode::GenerateDeoptimizeLazyFromReturnStub(Assembler* assembler) {
  // Push zap value instead of CODE_REG for lazy deopt.
  __ LoadImmediate(TMP, 0xf1f1f1f1);
  __ Push(TMP);
  // Return address for "call" to deopt stub.
  __ LoadImmediate(LR, 0xe1e1e1e1);
  __ ldr(CODE_REG, Address(THR, Thread::lazy_deopt_from_return_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kLazyDeoptFromReturn);
}


// R0: exception, must be preserved
// R1: stacktrace, must be preserved
void StubCode::GenerateDeoptimizeLazyFromThrowStub(Assembler* assembler) {
  // Push zap value instead of CODE_REG for lazy deopt.
  __ LoadImmediate(TMP, 0xf1f1f1f1);
  __ Push(TMP);
  // Return address for "call" to deopt stub.
  __ LoadImmediate(LR, 0xe1e1e1e1);
  __ ldr(CODE_REG, Address(THR, Thread::lazy_deopt_from_throw_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kLazyDeoptFromThrow);
}


void StubCode::GenerateDeoptimizeStub(Assembler* assembler) {
  GenerateDeoptimizationSequence(assembler, kEagerDeopt);
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
  __ LoadFieldFromOffset(R2, R4, ArgumentsDescriptor::count_offset());
  __ add(TMP, FP, Operand(R2, LSL, 2));  // R2 is Smi.
  __ LoadFromOffset(R6, TMP, kParamEndSlotFromFp * kWordSize);
  __ Push(ZR);  // Result slot.
  __ Push(R6);  // Receiver.
  __ Push(R5);  // ICData/MegamorphicCache.
  __ Push(R4);  // Arguments descriptor.
  // R2: Smi-tagged arguments array length.
  PushArgumentsArray(assembler);
  const intptr_t kNumArgs = 4;
  __ CallRuntime(kInvokeNoSuchMethodDispatcherRuntimeEntry, kNumArgs);
  __ Drop(4);
  __ Pop(R0);  // Return value.
  __ LeaveStubFrame();
  __ ret();
}


void StubCode::GenerateMegamorphicMissStub(Assembler* assembler) {
  __ EnterStubFrame();

  // Load the receiver.
  __ LoadFieldFromOffset(R2, R4, ArgumentsDescriptor::count_offset());
  __ add(TMP, FP, Operand(R2, LSL, 2));  // R2 is Smi.
  __ LoadFromOffset(R6, TMP, kParamEndSlotFromFp * kWordSize);

  // Preserve IC data and arguments descriptor.
  __ Push(R5);
  __ Push(R4);

  // Push space for the return value.
  // Push the receiver.
  // Push IC data object.
  // Push arguments descriptor array.
  __ Push(ZR);
  __ Push(R6);
  __ Push(R5);
  __ Push(R4);
  __ CallRuntime(kMegamorphicCacheMissHandlerRuntimeEntry, 3);
  // Remove arguments.
  __ Drop(3);
  __ Pop(R0);  // Get result into R0 (target function).

  // Restore IC data and arguments descriptor.
  __ Pop(R4);
  __ Pop(R5);

  __ RestoreCodePointer();
  __ LeaveStubFrame();

  if (!FLAG_lazy_dispatchers) {
    Label call_target_function;
    GenerateDispatcherCode(assembler, &call_target_function);
    __ Bind(&call_target_function);
  }

  // Tail-call to target function.
  __ LoadFieldFromOffset(CODE_REG, R0, Function::code_offset());
  __ LoadFieldFromOffset(R2, R0, Function::entry_point_offset());
  __ br(R2);
}


// Called for inline allocation of arrays.
// Input parameters:
//   LR: return address.
//   R2: array length as Smi.
//   R1: array element type (either NULL or an instantiated type).
// NOTE: R2 cannot be clobbered here as the caller relies on it being saved.
// The newly allocated object is returned in R0.
void StubCode::GenerateAllocateArrayStub(Assembler* assembler) {
  Label slow_case;
  // Compute the size to be allocated, it is based on the array length
  // and is computed as:
  // RoundedAllocationSize((array_length * kwordSize) + sizeof(RawArray)).
  // Assert that length is a Smi.
  __ tsti(R2, Immediate(kSmiTagMask));
  if (FLAG_use_slow_path) {
    __ b(&slow_case);
  } else {
    __ b(&slow_case, NE);
  }
  __ cmp(R2, Operand(0));
  __ b(&slow_case, LT);

  // Check for maximum allowed length.
  const intptr_t max_len =
      reinterpret_cast<intptr_t>(Smi::New(Array::kMaxElements));
  __ CompareImmediate(R2, max_len);
  __ b(&slow_case, GT);

  const intptr_t cid = kArrayCid;
  NOT_IN_PRODUCT(__ MaybeTraceAllocation(kArrayCid, R4, &slow_case));

  Heap::Space space = Heap::kNew;
  __ ldr(R8, Address(THR, Thread::heap_offset()));

  // Calculate and align allocation size.
  // Load new object start and calculate next object start.
  // R1: array element type.
  // R2: array length as Smi.
  // R8: heap.
  __ LoadFromOffset(R0, R8, Heap::TopOffset(space));
  intptr_t fixed_size = sizeof(RawArray) + kObjectAlignment - 1;
  __ LoadImmediate(R3, fixed_size);
  __ add(R3, R3, Operand(R2, LSL, 2));  // R2 is Smi.
  ASSERT(kSmiTagShift == 1);
  __ andi(R3, R3, Immediate(~(kObjectAlignment - 1)));
  // R0: potential new object start.
  // R3: object size in bytes.
  __ adds(R7, R3, Operand(R0));
  __ b(&slow_case, CS);  // Branch if unsigned overflow.

  // Check if the allocation fits into the remaining space.
  // R0: potential new object start.
  // R1: array element type.
  // R2: array length as Smi.
  // R3: array size.
  // R7: potential next object start.
  // R8: heap.
  __ LoadFromOffset(TMP, R8, Heap::EndOffset(space));
  __ CompareRegisters(R7, TMP);
  __ b(&slow_case, CS);  // Branch if unsigned higher or equal.

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  // R0: potential new object start.
  // R3: array size.
  // R7: potential next object start.
  // R8: heap.
  __ StoreToOffset(R7, R8, Heap::TopOffset(space));
  __ add(R0, R0, Operand(kHeapObjectTag));
  NOT_IN_PRODUCT(__ UpdateAllocationStatsWithSize(cid, R3, space));

  // R0: new object start as a tagged pointer.
  // R1: array element type.
  // R2: array length as Smi.
  // R3: array size.
  // R7: new object end address.

  // Store the type argument field.
  __ StoreIntoObjectOffsetNoBarrier(
      R0, Array::type_arguments_offset(), R1);

  // Set the length field.
  __ StoreIntoObjectOffsetNoBarrier(R0, Array::length_offset(), R2);

  // Calculate the size tag.
  // R0: new object start as a tagged pointer.
  // R2: array length as Smi.
  // R3: array size.
  // R7: new object end address.
  const intptr_t shift = RawObject::kSizeTagPos - kObjectAlignmentLog2;
  __ CompareImmediate(R3, RawObject::SizeTag::kMaxSizeTag);
  // If no size tag overflow, shift R1 left, else set R1 to zero.
  __ LslImmediate(TMP, R3, shift);
  __ csel(R1, TMP, R1, LS);
  __ csel(R1, ZR, R1, HI);

  // Get the class index and insert it into the tags.
  __ LoadImmediate(TMP, RawObject::ClassIdTag::encode(cid));
  __ orr(R1, R1, Operand(TMP));
  __ StoreFieldToOffset(R1, R0, Array::tags_offset());

  // Initialize all array elements to raw_null.
  // R0: new object start as a tagged pointer.
  // R7: new object end address.
  // R2: array length as Smi.
  __ AddImmediate(R1, R0, Array::data_offset() - kHeapObjectTag);
  // R1: iterator which initially points to the start of the variable
  // data area to be initialized.
  __ LoadObject(TMP, Object::null_object());
  Label loop, done;
  __ Bind(&loop);
  // TODO(cshapiro): StoreIntoObjectNoBarrier
  __ CompareRegisters(R1, R7);
  __ b(&done, CS);
  __ str(TMP, Address(R1));  // Store if unsigned lower.
  __ AddImmediate(R1, R1, kWordSize);
  __ b(&loop);  // Loop until R1 == R7.
  __ Bind(&done);

  // Done allocating and initializing the array.
  // R0: new object.
  // R2: array length as Smi (preserved for the caller.)
  __ ret();

  // Unable to allocate the array using the fast inline code, just call
  // into the runtime.
  __ Bind(&slow_case);
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value.
  // Push array length as Smi and element type.
  __ Push(ZR);
  __ Push(R2);
  __ Push(R1);
  __ CallRuntime(kAllocateArrayRuntimeEntry, 2);
  // Pop arguments; result is popped in IP.
  __ Pop(R1);
  __ Pop(R2);
  __ Pop(R0);
  __ LeaveStubFrame();
  __ ret();
}


// Called when invoking Dart code from C++ (VM code).
// Input parameters:
//   LR : points to return address.
//   R0 : code object of the Dart function to call.
//   R1 : arguments descriptor array.
//   R2 : arguments array.
//   R3 : current thread.
void StubCode::GenerateInvokeDartCodeStub(Assembler* assembler) {
  __ Comment("InvokeDartCodeStub");

  // Copy the C stack pointer (R31) into the stack pointer we'll actually use
  // to access the stack.
  __ SetupDartSP();
  __ EnterFrame(0);

  // Push code object to PC marker slot.
  __ ldr(TMP, Address(R3, Thread::invoke_dart_code_stub_offset()));
  __ Push(TMP);

  // Save the callee-saved registers.
  for (int i = kAbiFirstPreservedCpuReg; i <= kAbiLastPreservedCpuReg; i++) {
    const Register r = static_cast<Register>(i);
    // We use str instead of the Push macro because we will be pushing the PP
    // register when it is not holding a pool-pointer since we are coming from
    // C++ code.
    __ str(r, Address(SP, -1 * kWordSize, Address::PreIndex));
  }

  // Save the bottom 64-bits of callee-saved V registers.
  for (int i = kAbiFirstPreservedFpuReg; i <= kAbiLastPreservedFpuReg; i++) {
    const VRegister r = static_cast<VRegister>(i);
    __ PushDouble(r);
  }

  // Set up THR, which caches the current thread in Dart code.
  if (THR != R3) {
    __ mov(THR, R3);
  }

  // Save the current VMTag on the stack.
  __ LoadFromOffset(R4, THR, Thread::vm_tag_offset());
  __ Push(R4);

  // Mark that the thread is executing Dart code.
  __ LoadImmediate(R6, VMTag::kDartTagId);
  __ StoreToOffset(R6, THR, Thread::vm_tag_offset());

  // Save top resource and top exit frame info. Use R6 as a temporary register.
  // StackFrameIterator reads the top exit frame info saved in this frame.
  __ LoadFromOffset(R6, THR, Thread::top_resource_offset());
  __ StoreToOffset(ZR, THR, Thread::top_resource_offset());
  __ Push(R6);
  __ LoadFromOffset(R6, THR, Thread::top_exit_frame_info_offset());
  __ StoreToOffset(ZR, THR, Thread::top_exit_frame_info_offset());
  // kExitLinkSlotFromEntryFp must be kept in sync with the code below.
  ASSERT(kExitLinkSlotFromEntryFp == -22);
  __ Push(R6);

  // Load arguments descriptor array into R4, which is passed to Dart code.
  __ LoadFromOffset(R4, R1, VMHandles::kOffsetOfRawPtrInHandle);

  // Load number of arguments into S5.
  __ LoadFieldFromOffset(R5, R4, ArgumentsDescriptor::count_offset());
  __ SmiUntag(R5);

  // Compute address of 'arguments array' data area into R2.
  __ LoadFromOffset(R2, R2, VMHandles::kOffsetOfRawPtrInHandle);
  __ AddImmediate(R2, R2, Array::data_offset() - kHeapObjectTag);

  // Set up arguments for the Dart call.
  Label push_arguments;
  Label done_push_arguments;
  __ cmp(R5, Operand(0));
  __ b(&done_push_arguments, EQ);  // check if there are arguments.
  __ LoadImmediate(R1, 0);
  __ Bind(&push_arguments);
  __ ldr(R3, Address(R2));
  __ Push(R3);
  __ add(R1, R1, Operand(1));
  __ add(R2, R2, Operand(kWordSize));
  __ cmp(R1, Operand(R5));
  __ b(&push_arguments, LT);
  __ Bind(&done_push_arguments);

  // We now load the pool pointer(PP) with a GC safe value as we are about to
  // invoke dart code. We don't need a real object pool here.
  // Smi zero does not work because ARM64 assumes PP to be untagged.
  __ LoadObject(PP, Object::null_object());

  // Call the Dart code entrypoint.
  __ ldr(CODE_REG, Address(R0, VMHandles::kOffsetOfRawPtrInHandle));
  __ ldr(R0, FieldAddress(CODE_REG, Code::entry_point_offset()));
  __ blr(R0);  // R4 is the arguments descriptor array.
  __ Comment("InvokeDartCodeStub return");

  // Get rid of arguments pushed on the stack.
  __ AddImmediate(SP, FP, kExitLinkSlotFromEntryFp * kWordSize);

  // Restore the saved top exit frame info and top resource back into the
  // Isolate structure. Uses R6 as a temporary register for this.
  __ Pop(R6);
  __ StoreToOffset(R6, THR, Thread::top_exit_frame_info_offset());
  __ Pop(R6);
  __ StoreToOffset(R6, THR, Thread::top_resource_offset());

  // Restore the current VMTag from the stack.
  __ Pop(R4);
  __ StoreToOffset(R4, THR, Thread::vm_tag_offset());

  // Restore the bottom 64-bits of callee-saved V registers.
  for (int i = kAbiLastPreservedFpuReg; i >= kAbiFirstPreservedFpuReg; i--) {
    const VRegister r = static_cast<VRegister>(i);
    __ PopDouble(r);
  }

  // Restore C++ ABI callee-saved registers.
  for (int i = kAbiLastPreservedCpuReg; i >= kAbiFirstPreservedCpuReg; i--) {
    Register r = static_cast<Register>(i);
    // We use ldr instead of the Pop macro because we will be popping the PP
    // register when it is not holding a pool-pointer since we are returning to
    // C++ code. We also skip the dart stack pointer SP, since we are still
    // using it as the stack pointer.
    __ ldr(r, Address(SP, 1 * kWordSize, Address::PostIndex));
  }

  // Restore the frame pointer and C stack pointer and return.
  __ LeaveFrame();
  __ RestoreCSP();
  __ ret();
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
    __ add(R2, R2, Operand(R1, LSL, 3));
    ASSERT(kSmiTagShift == 1);
    __ andi(R2, R2, Immediate(~(kObjectAlignment - 1)));

    NOT_IN_PRODUCT(__ MaybeTraceAllocation(kContextCid, R4, &slow_case));
    // Now allocate the object.
    // R1: number of context variables.
    // R2: object size.
    const intptr_t cid = kContextCid;
    Heap::Space space = Heap::kNew;
    __ ldr(R5, Address(THR, Thread::heap_offset()));
    __ ldr(R0, Address(R5, Heap::TopOffset(space)));
    __ add(R3, R2, Operand(R0));
    // Check if the allocation fits into the remaining space.
    // R0: potential new object.
    // R1: number of context variables.
    // R2: object size.
    // R3: potential next object start.
    // R5: heap.
    __ ldr(TMP, Address(R5, Heap::EndOffset(space)));
    __ CompareRegisters(R3, TMP);
    if (FLAG_use_slow_path) {
      __ b(&slow_case);
    } else {
      __ b(&slow_case, CS);  // Branch if unsigned higher or equal.
    }

    // Successfully allocated the object, now update top to point to
    // next object start and initialize the object.
    // R0: new object.
    // R1: number of context variables.
    // R2: object size.
    // R3: next object start.
    // R5: heap.
    __ str(R3, Address(R5, Heap::TopOffset(space)));
    __ add(R0, R0, Operand(kHeapObjectTag));
    NOT_IN_PRODUCT(__ UpdateAllocationStatsWithSize(cid, R2, space));

    // Calculate the size tag.
    // R0: new object.
    // R1: number of context variables.
    // R2: object size.
    const intptr_t shift = RawObject::kSizeTagPos - kObjectAlignmentLog2;
    __ CompareImmediate(R2, RawObject::SizeTag::kMaxSizeTag);
    // If no size tag overflow, shift R2 left, else set R2 to zero.
    __ LslImmediate(TMP, R2, shift);
    __ csel(R2, TMP, R2, LS);
    __ csel(R2, ZR, R2, HI);

    // Get the class index and insert it into the tags.
    // R2: size and bit tags.
    __ LoadImmediate(TMP, RawObject::ClassIdTag::encode(cid));
    __ orr(R2, R2, Operand(TMP));
    __ StoreFieldToOffset(R2, R0, Context::tags_offset());

    // Setup up number of context variables field.
    // R0: new object.
    // R1: number of context variables as integer value (not object).
    __ StoreFieldToOffset(R1, R0, Context::num_variables_offset());

    // Setup the parent field.
    // R0: new object.
    // R1: number of context variables.
    __ LoadObject(R2, Object::null_object());
    __ StoreFieldToOffset(R2, R0, Context::parent_offset());

    // Initialize the context variables.
    // R0: new object.
    // R1: number of context variables.
    // R2: raw null.
    Label loop, done;
    __ AddImmediate(
        R3, R0, Context::variable_offset(0) - kHeapObjectTag);
    __ Bind(&loop);
    __ subs(R1, R1, Operand(1));
    __ b(&done, MI);
    __ str(R2, Address(R3, R1, UXTX, Address::Scaled));
    __ b(&loop, NE);  // Loop if R1 not zero.
    __ Bind(&done);

    // Done allocating and initializing the context.
    // R0: new object.
    __ ret();

    __ Bind(&slow_case);
  }
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value.
  __ SmiTag(R1);
  __ PushObject(Object::null_object());
  __ Push(R1);
  __ CallRuntime(kAllocateContextRuntimeEntry, 1);  // Allocate context.
  __ Drop(1);  // Pop number of context variables argument.
  __ Pop(R0);  // Pop the new context object.
  // R0: new object
  // Restore the frame pointer.
  __ LeaveStubFrame();
  __ ret();
}


// Helper stub to implement Assembler::StoreIntoObject.
// Input parameters:
//   R0: Address being stored
void StubCode::GenerateUpdateStoreBufferStub(Assembler* assembler) {
  Label add_to_buffer;
  // Check whether this object has already been remembered. Skip adding to the
  // store buffer if the object is in the store buffer already.
  __ LoadFieldFromOffset(TMP, R0, Object::tags_offset());
  __ tsti(TMP, Immediate(1 << RawObject::kRememberedBit));
  __ b(&add_to_buffer, EQ);
  __ ret();

  __ Bind(&add_to_buffer);
  // Save values being destroyed.
  __ Push(R1);
  __ Push(R2);
  __ Push(R3);

  // Atomically set the remembered bit of the object header.
  ASSERT(Object::tags_offset() == 0);
  __ sub(R3, R0, Operand(kHeapObjectTag));
  // R3: Untagged address of header word (ldxr/stxr do not support offsets).
  Label retry;
  __ Bind(&retry);
  __ ldxr(R2, R3);
  __ orri(R2, R2, Immediate(1 << RawObject::kRememberedBit));
  __ stxr(R1, R2, R3);
  __ cmp(R1, Operand(1));
  __ b(&retry, EQ);

  // Load the StoreBuffer block out of the thread. Then load top_ out of the
  // StoreBufferBlock and add the address to the pointers_.
  __ LoadFromOffset(R1, THR, Thread::store_buffer_block_offset());
  __ LoadFromOffset(R2, R1, StoreBufferBlock::top_offset(), kUnsignedWord);
  __ add(R3, R1, Operand(R2, LSL, 3));
  __ StoreToOffset(R0, R3, StoreBufferBlock::pointers_offset());

  // Increment top_ and check for overflow.
  // R2: top_.
  // R1: StoreBufferBlock.
  Label L;
  __ add(R2, R2, Operand(1));
  __ StoreToOffset(R2, R1, StoreBufferBlock::top_offset(), kUnsignedWord);
  __ CompareImmediate(R2, StoreBufferBlock::kSize);
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
  __ mov(R0, THR);
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
  Isolate* isolate = Isolate::Current();
  if (FLAG_inline_alloc && Heap::IsAllocatableInNewSpace(instance_size) &&
      !cls.TraceAllocation(isolate)) {
    Label slow_case;
    // Allocate the object and update top to point to
    // next object start and initialize the allocated object.
    // R1: instantiated type arguments (if is_cls_parameterized).
    Heap::Space space = Heap::kNew;
    __ ldr(R5, Address(THR, Thread::heap_offset()));
    __ ldr(R2, Address(R5, Heap::TopOffset(space)));
    __ AddImmediate(R3, R2, instance_size);
    // Check if the allocation fits into the remaining space.
    // R2: potential new object start.
    // R3: potential next object start.
    // R5: heap.
    __ ldr(TMP, Address(R5, Heap::EndOffset(space)));
    __ CompareRegisters(R3, TMP);
    if (FLAG_use_slow_path) {
      __ b(&slow_case);
    } else {
      __ b(&slow_case, CS);  // Unsigned higher or equal.
    }
    __ str(R3, Address(R5, Heap::TopOffset(space)));
    NOT_IN_PRODUCT(__ UpdateAllocationStats(cls.id(), space));

    // R2: new object start.
    // R3: next object start.
    // R1: new object type arguments (if is_cls_parameterized).
    // Set the tags.
    uword tags = 0;
    tags = RawObject::SizeTag::update(instance_size, tags);
    ASSERT(cls.id() != kIllegalCid);
    tags = RawObject::ClassIdTag::update(cls.id(), tags);
    __ LoadImmediate(R0, tags);
    __ StoreToOffset(R0, R2, Instance::tags_offset());

    // Initialize the remaining words of the object.
    __ LoadObject(R0, Object::null_object());

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
      __ AddImmediate(R4, R2, Instance::NextFieldOffset());
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
      __ AddImmediate(R4, R4, kWordSize);
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
  __ EnterStubFrame();  // Uses pool pointer to pass cls to runtime.
  __ Push(ZR);  // Result slot.
  __ PushObject(cls);  // Push class of object to be allocated.
  if (is_cls_parameterized) {
    // Push type arguments.
    __ Push(R1);
  } else {
    // Push null type arguments.
    __ PushObject(Object::null_object());
  }
  __ CallRuntime(kAllocateObjectRuntimeEntry, 2);  // Allocate object.
  __ Drop(2);  // Pop arguments.
  __ Pop(R0);  // Pop result (newly allocated object).
  // R0: new object
  // Restore the frame pointer.
  __ LeaveStubFrame();
  __ ret();
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
  __ LoadFieldFromOffset(R2, R4, ArgumentsDescriptor::count_offset());
  __ add(TMP, FP, Operand(R2, LSL, 2));  // R2 is Smi.
  __ LoadFromOffset(R6, TMP, kParamEndSlotFromFp * kWordSize);

  // Push space for the return value.
  // Push the receiver.
  // Push arguments descriptor array.
  __ Push(ZR);
  __ Push(R6);
  __ Push(R4);

  // R2: Smi-tagged arguments array length.
  PushArgumentsArray(assembler);

  const intptr_t kNumArgs = 3;
  __ CallRuntime(kInvokeClosureNoSuchMethodRuntimeEntry, kNumArgs);
  // noSuchMethod on closures always throws an error, so it will never return.
  __ brk(0);
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
    __ Push(R6);  // Preserve.
    __ Push(R5);  // Preserve.
    __ Push(ic_reg);  // Argument.
    __ Push(func_reg);  // Argument.
    __ CallRuntime(kTraceICCallRuntimeEntry, 2);
    __ Drop(2);  // Discard argument;
    __ Pop(R5);  // Restore.
    __ Pop(R6);  // Restore.
    __ LeaveStubFrame();
  }
  __ LoadFieldFromOffset(
      R7, func_reg, Function::usage_counter_offset(), kWord);
  __ add(R7, R7, Operand(1));
  __ StoreFieldToOffset(
      R7, func_reg, Function::usage_counter_offset(), kWord);
}


// Loads function into 'temp_reg'.
void StubCode::GenerateUsageCounterIncrement(Assembler* assembler,
                                             Register temp_reg) {
  if (FLAG_optimization_counter_threshold >= 0) {
    Register ic_reg = R5;
    Register func_reg = temp_reg;
    ASSERT(temp_reg == R6);
    __ Comment("Increment function counter");
    __ LoadFieldFromOffset(func_reg, ic_reg, ICData::owner_offset());
    __ LoadFieldFromOffset(
        R7, func_reg, Function::usage_counter_offset(), kWord);
    __ AddImmediate(R7, R7, 1);
    __ StoreFieldToOffset(
        R7, func_reg, Function::usage_counter_offset(), kWord);
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
  __ ldr(R0, Address(SP, + 0 * kWordSize));  // Right.
  __ ldr(R1, Address(SP, + 1 * kWordSize));  // Left.
  __ orr(TMP, R0, Operand(R1));
  __ tsti(TMP, Immediate(kSmiTagMask));
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
      __ CompareRegisters(R0, R1);
      __ LoadObject(R0, Bool::True());
      __ LoadObject(R1, Bool::False());
      __ csel(R0, R1, R0, NE);
      break;
    }
    default: UNIMPLEMENTED();
  }

  // R5: IC data object (preserved).
  __ LoadFieldFromOffset(R6, R5, ICData::ic_data_offset());
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
    const intptr_t count_offset = ICData::CountIndexFor(num_args) * kWordSize;
    // Update counter.
    __ LoadFromOffset(R1, R6, count_offset);
    __ adds(R1, R1, Operand(Smi::RawValue(1)));
    __ LoadImmediate(R2, Smi::RawValue(Smi::kMaxValue));
    __ csel(R1, R2, R1, VS);  // Overflow.
    __ StoreToOffset(R1, R6, count_offset);
  }

  __ ret();
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
    bool optimized) {
  ASSERT(num_args > 0);
#if defined(DEBUG)
  { Label ok;
    // Check that the IC data array has NumArgsTested() == num_args.
    // 'NumArgsTested' is stored in the least significant bits of 'state_bits'.
    __ LoadFromOffset(R6, R5, ICData::state_bits_offset() - kHeapObjectTag,
                      kUnsignedWord);
    ASSERT(ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ andi(R6, R6, Immediate(ICData::NumArgsTestedMask()));
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
    __ LoadFromOffset(
        R6, R6, Isolate::single_step_offset(), kUnsignedByte);
    __ CompareRegisters(R6, ZR);
    __ b(&stepping, NE);
    __ Bind(&done_stepping);
  }

  Label not_smi_or_overflow;
  if (kind != Token::kILLEGAL) {
    EmitFastSmiOp(assembler,
                  kind,
                  num_args,
                  &not_smi_or_overflow);
  }
  __ Bind(&not_smi_or_overflow);

  __ Comment("Extract ICData initial values and receiver cid");
  // Load arguments descriptor into R4.
  __ LoadFieldFromOffset(R4, R5, ICData::arguments_descriptor_offset());
  // Loop that checks if there is an IC data match.
  Label loop, update, test, found;
  // R5: IC data object (preserved).
  __ LoadFieldFromOffset(R6, R5, ICData::ic_data_offset());
  // R6: ic_data_array with check entries: classes and target functions.
  __ AddImmediate(R6, R6, Array::data_offset() - kHeapObjectTag);
  // R6: points directly to the first ic data array element.

  // Get the receiver's class ID (first read number of arguments from
  // arguments descriptor array and then access the receiver from the stack).
  __ LoadFieldFromOffset(R7, R4, ArgumentsDescriptor::count_offset());
  __ SmiUntag(R7);  // Untag so we can use the LSL 3 addressing mode.
  __ sub(R7, R7, Operand(1));

  // R0 <- [SP + (R7 << 3)]
  __ ldr(R0, Address(SP, R7, UXTX, Address::Scaled));
  __ LoadTaggedClassIdMayBeSmi(R0, R0);

  // R7: argument_count - 1 (untagged).
  // R0: receiver's class ID (smi).
  __ ldr(R1, Address(R6));  // First class id (smi) to check.
  __ b(&test);

  __ Comment("ICData loop");
  __ Bind(&loop);
  for (int i = 0; i < num_args; i++) {
    if (i > 0) {
      // If not the first, load the next argument's class ID.
      __ AddImmediate(R0, R7, -i);
      // R0 <- [SP + (R0 << 3)]
      __ ldr(R0, Address(SP, R0, UXTX, Address::Scaled));
      __ LoadTaggedClassIdMayBeSmi(R0, R0);
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
    __ LoadTaggedClassIdMayBeSmi(R0, R0);
  }

  const intptr_t entry_size = ICData::TestEntryLengthFor(num_args) * kWordSize;
  __ AddImmediate(R6, R6, entry_size);  // Next entry.
  __ ldr(R1, Address(R6));  // Next class ID.

  __ Bind(&test);
  __ CompareImmediate(R1, Smi::RawValue(kIllegalCid));  // Done?
  __ b(&loop, NE);

  __ Comment("IC miss");
  // Compute address of arguments.
  // R7: argument_count - 1 (untagged).
  // R7 <- SP + (R7 << 3)
  __ add(R7, SP, Operand(R7, UXTX, 3));  // R7 is Untagged.
  // R7: address of receiver.
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Preserve IC data object and arguments descriptor array and
  // setup space on stack for result (target code object).
  __ Push(R4);  // Preserve arguments descriptor array.
  __ Push(R5);  // Preserve IC Data.
  // Setup space on stack for the result (target code object).
  __ Push(ZR);
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
  __ RestoreCodePointer();
  __ LeaveStubFrame();
  Label call_target_function;
  if (!FLAG_lazy_dispatchers) {
    GenerateDispatcherCode(assembler, &call_target_function);
  } else {
    __ b(&call_target_function);
  }

  __ Bind(&found);
  __ Comment("Update caller's counter");
  // R6: pointer to an IC data check group.
  const intptr_t target_offset = ICData::TargetIndexFor(num_args) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(num_args) * kWordSize;
  __ LoadFromOffset(R0, R6, target_offset);

  if (FLAG_optimization_counter_threshold >= 0) {
    // Update counter.
    __ LoadFromOffset(R1, R6, count_offset);
    __ adds(R1, R1, Operand(Smi::RawValue(1)));
    __ LoadImmediate(R2, Smi::RawValue(Smi::kMaxValue));
    __ csel(R1, R2, R1, VS);  // Overflow.
    __ StoreToOffset(R1, R6, count_offset);
  }

  __ Comment("Call target");
  __ Bind(&call_target_function);
  // R0: target function.
  __ LoadFieldFromOffset(CODE_REG, R0, Function::code_offset());
  __ LoadFieldFromOffset(R2, R0, Function::entry_point_offset());
  __ br(R2);

  if (FLAG_support_debugger && !optimized) {
    __ Bind(&stepping);
    __ EnterStubFrame();
    __ Push(R5);  // Preserve IC data.
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ Pop(R5);
    __ RestoreCodePointer();
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
  GenerateNArgsCheckInlineCacheStub(assembler, 1,
      kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL);
}


void StubCode::GenerateTwoArgsCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
  GenerateNArgsCheckInlineCacheStub(assembler, 2,
      kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL);
}


void StubCode::GenerateSmiAddInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
  GenerateNArgsCheckInlineCacheStub(assembler, 2,
      kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kADD);
}


void StubCode::GenerateSmiSubInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
  GenerateNArgsCheckInlineCacheStub(assembler, 2,
      kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kSUB);
}


void StubCode::GenerateSmiEqualInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
  GenerateNArgsCheckInlineCacheStub(assembler, 2,
      kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kEQ);
}


void StubCode::GenerateOneArgOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateOptimizedUsageCounterIncrement(assembler);
  GenerateNArgsCheckInlineCacheStub(assembler, 1,
      kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      true /* optimized */);
}


void StubCode::GenerateTwoArgsOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateOptimizedUsageCounterIncrement(assembler);
  GenerateNArgsCheckInlineCacheStub(assembler, 2,
      kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      true /* optimized */);
}


void StubCode::GenerateZeroArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
#if defined(DEBUG)
  { Label ok;
    // Check that the IC data array has NumArgsTested() == 0.
    // 'NumArgsTested' is stored in the least significant bits of 'state_bits'.
    __ LoadFromOffset(R6, R5, ICData::state_bits_offset() - kHeapObjectTag,
                      kUnsignedWord);
    ASSERT(ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ andi(R6, R6, Immediate(ICData::NumArgsTestedMask()));
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
    __ LoadFromOffset(
        R6, R6, Isolate::single_step_offset(), kUnsignedByte);
    __ CompareImmediate(R6, 0);
    __ b(&stepping, NE);
    __ Bind(&done_stepping);
  }

  // R5: IC data object (preserved).
  __ LoadFieldFromOffset(R6, R5, ICData::ic_data_offset());
  // R6: ic_data_array with entries: target functions and count.
  __ AddImmediate(R6, R6, Array::data_offset() - kHeapObjectTag);
  // R6: points directly to the first ic data array element.
  const intptr_t target_offset = ICData::TargetIndexFor(0) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(0) * kWordSize;

  if (FLAG_optimization_counter_threshold >= 0) {
    // Increment count for this call.
    __ LoadFromOffset(R1, R6, count_offset);
    __ adds(R1, R1, Operand(Smi::RawValue(1)));
    __ LoadImmediate(R2, Smi::RawValue(Smi::kMaxValue));
    __ csel(R1, R2, R1, VS);  // Overflow.
    __ StoreToOffset(R1, R6, count_offset);
  }

  // Load arguments descriptor into R4.
  __ LoadFieldFromOffset(R4, R5, ICData::arguments_descriptor_offset());

  // Get function and call it, if possible.
  __ LoadFromOffset(R0, R6, target_offset);
  __ LoadFieldFromOffset(CODE_REG, R0, Function::code_offset());
  __ LoadFieldFromOffset(R2, R0, Function::entry_point_offset());
  __ br(R2);

  if (FLAG_support_debugger) {
    __ Bind(&stepping);
    __ EnterStubFrame();
    __ Push(R5);  // Preserve IC data.
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ Pop(R5);
    __ RestoreCodePointer();
    __ LeaveStubFrame();
    __ b(&done_stepping);
  }
}


void StubCode::GenerateOneArgUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kStaticCallMissHandlerOneArgRuntimeEntry, Token::kILLEGAL);
}


void StubCode::GenerateTwoArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, R6);
  GenerateNArgsCheckInlineCacheStub(assembler, 2,
      kStaticCallMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL);
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

  __ LoadFieldFromOffset(CODE_REG, R0, Function::code_offset());
  __ LoadFieldFromOffset(R2, R0, Function::entry_point_offset());
  __ br(R2);
}


// R5: Contains an ICData.
void StubCode::GenerateICCallBreakpointStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ Push(R5);
  __ Push(ZR);  // Space for result.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ Pop(CODE_REG);
  __ Pop(R5);
  __ LeaveStubFrame();
  __ LoadFieldFromOffset(R0, CODE_REG, Code::entry_point_offset());
  __ br(R0);
}


void StubCode::GenerateRuntimeCallBreakpointStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ Push(ZR);  // Space for result.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ Pop(CODE_REG);
  __ LeaveStubFrame();
  __ LoadFieldFromOffset(R0, CODE_REG, Code::entry_point_offset());
  __ br(R0);
}

// Called only from unoptimized code. All relevant registers have been saved.
void StubCode::GenerateDebugStepCheckStub(
    Assembler* assembler) {
  // Check single stepping.
  Label stepping, done_stepping;
  __ LoadIsolate(R1);
  __ LoadFromOffset(
      R1, R1, Isolate::single_step_offset(), kUnsignedByte);
  __ CompareImmediate(R1, 0);
  __ b(&stepping, NE);
  __ Bind(&done_stepping);

  __ ret();

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
    __ LoadClass(R3, R0);
    // Compute instance type arguments into R4.
    Label has_no_type_arguments;
    __ LoadObject(R4, Object::null_object());
    __ LoadFieldFromOffset(R5, R3,
        Class::type_arguments_field_offset_in_words_offset(), kWord);
    __ CompareImmediate(R5, Class::kNoTypeArguments);
    __ b(&has_no_type_arguments, EQ);
    __ add(R5, R0, Operand(R5, LSL, 3));
    __ LoadFieldFromOffset(R4, R5, 0);
    __ Bind(&has_no_type_arguments);
  }
  __ LoadClassId(R3, R0);
  // R0: instance.
  // R1: instantiator type arguments or NULL.
  // R2: SubtypeTestCache.
  // R3: instance class id.
  // R4: instance type arguments (null if none), used only if n > 1.
  __ LoadFieldFromOffset(R2, R2, SubtypeTestCache::cache_offset());
  __ AddImmediate(R2, R2, Array::data_offset() - kHeapObjectTag);

  Label loop, found, not_found, next_iteration;
  // R2: entry start.
  // R3: instance class id.
  // R4: instance type arguments.
  __ SmiTag(R3);
  __ CompareImmediate(R3, Smi::RawValue(kClosureCid));
  __ b(&loop, NE);
  __ LoadFieldFromOffset(R3, R0, Closure::function_offset());
  // R3: instance class id as Smi or function.
  __ Bind(&loop);
  __ LoadFromOffset(
      R5, R2, kWordSize * SubtypeTestCache::kInstanceClassIdOrFunction);
  __ CompareObject(R5, Object::null_object());
  __ b(&not_found, EQ);
  __ CompareRegisters(R5, R3);
  if (n == 1) {
    __ b(&found, EQ);
  } else {
    __ b(&next_iteration, NE);
    __ LoadFromOffset(
        R5, R2, kWordSize * SubtypeTestCache::kInstanceTypeArguments);
    __ CompareRegisters(R5, R4);
    if (n == 2) {
      __ b(&found, EQ);
    } else {
      __ b(&next_iteration, NE);
      __ LoadFromOffset(R5, R2,
          kWordSize * SubtypeTestCache::kInstantiatorTypeArguments);
      __ CompareRegisters(R5, R1);
      __ b(&found, EQ);
    }
  }
  __ Bind(&next_iteration);
  __ AddImmediate(
      R2, R2, kWordSize * SubtypeTestCache::kTestEntryLength);
  __ b(&loop);
  // Fall through to not found.
  __ Bind(&not_found);
  __ LoadObject(R1, Object::null_object());
  __ ret();

  __ Bind(&found);
  __ LoadFromOffset(R1, R2, kWordSize * SubtypeTestCache::kTestResult);
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


// Used to check class and type arguments. Arguments passed in registers:
// LR: return address.
// R0: instance (must be preserved).
// R1: instantiator type arguments or NULL.
// R2: cache array.
// Result in R1: null -> not found, otherwise result (true or false).
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


void StubCode::GenerateGetStackPointerStub(Assembler* assembler) {
  __ mov(R0, SP);
  __ ret();
}


// Jump to the exception or error handler.
// LR: return address.
// R0: program_counter.
// R1: stack_pointer.
// R2: frame_pointer.
// R3: error object.
// R4: address of stacktrace object.
// R5: thread.
// Does not return.
void StubCode::GenerateJumpToExceptionHandlerStub(Assembler* assembler) {
  ASSERT(kExceptionObjectReg == R0);
  ASSERT(kStackTraceObjectReg == R1);
  __ mov(LR, R0);  // Program counter.
  __ mov(SP, R1);  // Stack pointer.
  __ mov(FP, R2);  // Frame_pointer.
  __ mov(R0, R3);  // Exception object.
  __ mov(R1, R4);  // StackTrace object.
  __ mov(THR, R5);
  // Set the tag.
  __ LoadImmediate(R2, VMTag::kDartTagId);
  __ StoreToOffset(R2, THR, Thread::vm_tag_offset());
  // Clear top exit frame.
  __ StoreToOffset(ZR, THR, Thread::top_exit_frame_info_offset());
  // Restore the pool pointer.
  __ RestoreCodePointer();
  __ LoadPoolPointer();
  __ ret();  // Jump to the exception handler code.
}


// Calls to the runtime to optimize the given function.
// R6: function to be re-optimized.
// R4: argument descriptor (preserved).
void StubCode::GenerateOptimizeFunctionStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ Push(R4);
  // Setup space on stack for the return value.
  __ Push(ZR);
  __ Push(R6);
  __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry, 1);
  __ Pop(R0);  // Discard argument.
  __ Pop(R0);  // Get Function object
  __ Pop(R4);  // Restore argument descriptor.
  __ LoadFieldFromOffset(CODE_REG, R0, Function::code_offset());
  __ LoadFieldFromOffset(R1, R0, Function::entry_point_offset());
  __ LeaveStubFrame();
  __ br(R1);
  __ brk(0);
}


// Does identical check (object references are equal or not equal) with special
// checks for boxed numbers.
// Left and right are pushed on stack.
// Return Zero condition flag set if equal.
// Note: A Mint cannot contain a value that would fit in Smi, a Bigint
// cannot contain a value that fits in Mint or Smi.
static void GenerateIdenticalWithNumberCheckStub(Assembler* assembler,
                                                 const Register left,
                                                 const Register right) {
  Label reference_compare, done, check_mint, check_bigint;
  // If any of the arguments is Smi do reference compare.
  __ tsti(left, Immediate(kSmiTagMask));
  __ b(&reference_compare, EQ);
  __ tsti(right, Immediate(kSmiTagMask));
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
  __ EnterStubFrame();
  __ ReserveAlignedFrameSpace(2 * kWordSize);
  __ StoreToOffset(left, SP, 0 * kWordSize);
  __ StoreToOffset(right, SP, 1 * kWordSize);
  __ CallRuntime(kBigintCompareRuntimeEntry, 2);
  // Result in R0, 0 means equal.
  __ LeaveStubFrame();
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
  Label stepping, done_stepping;
  if (FLAG_support_debugger) {
    __ LoadIsolate(R1);
    __ LoadFromOffset(R1, R1, Isolate::single_step_offset(), kUnsignedByte);
    __ CompareImmediate(R1, 0);
    __ b(&stepping, NE);
    __ Bind(&done_stepping);
  }

  const Register left = R1;
  const Register right = R0;
  __ LoadFromOffset(left, SP, 1 * kWordSize);
  __ LoadFromOffset(right, SP, 0 * kWordSize);
  GenerateIdenticalWithNumberCheckStub(assembler, left, right);
  __ ret();

  if (FLAG_support_debugger) {
    __ Bind(&stepping);
    __ EnterStubFrame();
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ RestoreCodePointer();
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
  const Register left = R1;
  const Register right = R0;
  __ LoadFromOffset(left, SP, 1 * kWordSize);
  __ LoadFromOffset(right, SP, 0 * kWordSize);
  GenerateIdenticalWithNumberCheckStub(assembler, left, right);
  __ ret();
}


// Called from megamorphic calls.
//  R0: receiver
//  R5: MegamorphicCache (preserved)
// Passed to target:
//  CODE_REG: target Code
//  R4: arguments descriptor
void StubCode::GenerateMegamorphicCallStub(Assembler* assembler) {
  __ NoMonomorphicCheckedEntry();

  // Jump if receiver is a smi.
  Label smi_case;
  __ TestImmediate(R0, kSmiTagMask);
  __ b(&smi_case, EQ);

  // Loads the cid of the object.
  __ LoadClassId(R0, R0);

  Label cid_loaded;
  __ Bind(&cid_loaded);
  __ ldr(R2, FieldAddress(R5, MegamorphicCache::buckets_offset()));
  __ ldr(R1, FieldAddress(R5, MegamorphicCache::mask_offset()));
  // R2: cache buckets array.
  // R1: mask.

  // Make the cid into a smi.
  __ SmiTag(R0);
  // R0: class ID of the receiver (smi).

  // Compute the table index.
  ASSERT(MegamorphicCache::kSpreadFactor == 7);
  // Use lsl and sub to multiply with 7 == 8 - 1.
  __ LslImmediate(R3, R0, 3);
  __ sub(R3, R3, Operand(R0));
  // R3: probe.
  Label loop;
  __ Bind(&loop);
  __ and_(R3, R3, Operand(R1));

  const intptr_t base = Array::data_offset();
  // R3 is smi tagged, but table entries are 16 bytes, so LSL 3.
  __ add(TMP, R2, Operand(R3, LSL, 3));
  __ ldr(R6, FieldAddress(TMP, base));
  Label probe_failed;
  __ CompareRegisters(R6, R0);
  __ b(&probe_failed, NE);

  Label load_target;
  __ Bind(&load_target);
  // Call the target found in the cache.  For a class id match, this is a
  // proper target for the given name and arguments descriptor.  If the
  // illegal class id was found, the target is a cache miss handler that can
  // be invoked as a normal Dart function.
  __ ldr(R0, FieldAddress(TMP, base + kWordSize));
  __ ldr(R4, FieldAddress(R5, MegamorphicCache::arguments_descriptor_offset()));
  __ ldr(R1, FieldAddress(R0, Function::entry_point_offset()));
  __ ldr(CODE_REG, FieldAddress(R0, Function::code_offset()));
  __ br(R1);

  // Probe failed, check if it is a miss.
  __ Bind(&probe_failed);
  ASSERT(kIllegalCid == 0);
  __ tst(R6, Operand(R6));
  __ b(&load_target, EQ);  // branch if miss.

  // Try next extry in the table.
  __ AddImmediate(R3, R3, Smi::RawValue(1));
  __ b(&loop);

  // Load cid for the Smi case.
  __ Bind(&smi_case);
  __ LoadImmediate(R0, kSmiCid);
  __ b(&cid_loaded);
}


// Called from switchable IC calls.
//  R0: receiver
//  R5: ICData (preserved)
// Passed to target:
//  CODE_REG: target Code object
//  R4: arguments descriptor
void StubCode::GenerateICCallThroughFunctionStub(Assembler* assembler) {
  __ NoMonomorphicCheckedEntry();

  Label loop, found, miss;
  __ ldr(R4, FieldAddress(R5, ICData::arguments_descriptor_offset()));
  __ ldr(R8, FieldAddress(R5, ICData::ic_data_offset()));
  __ AddImmediate(R8, R8, Array::data_offset() - kHeapObjectTag);
  // R8: first IC entry
  __ LoadTaggedClassIdMayBeSmi(R1, R0);
  // R1: receiver cid as Smi

  __ Bind(&loop);
  __ ldr(R2, Address(R8, 0));
  __ cmp(R1, Operand(R2));
  __ b(&found, EQ);
  __ CompareImmediate(R2, Smi::RawValue(kIllegalCid));
  __ b(&miss, EQ);

  const intptr_t entry_length = ICData::TestEntryLengthFor(1) * kWordSize;
  __ AddImmediate(R8, R8, entry_length);  // Next entry.
  __ b(&loop);

  __ Bind(&found);
  const intptr_t target_offset = ICData::TargetIndexFor(1) * kWordSize;
  __ ldr(R0, Address(R8, target_offset));
  __ ldr(R1, FieldAddress(R0, Function::entry_point_offset()));
  __ ldr(CODE_REG, FieldAddress(R0, Function::code_offset()));
  __ br(R1);

  __ Bind(&miss);
  __ LoadIsolate(R2);
  __ ldr(CODE_REG, Address(R2, Isolate::ic_miss_code_offset()));
  __ ldr(R1, FieldAddress(CODE_REG, Code::entry_point_offset()));
  __ br(R1);
}


void StubCode::GenerateICCallThroughCodeStub(Assembler* assembler) {
  __ NoMonomorphicCheckedEntry();

  Label loop, found, miss;
  __ ldr(R4, FieldAddress(R5, ICData::arguments_descriptor_offset()));
  __ ldr(R8, FieldAddress(R5, ICData::ic_data_offset()));
  __ AddImmediate(R8, R8, Array::data_offset() - kHeapObjectTag);
  // R8: first IC entry
  __ LoadTaggedClassIdMayBeSmi(R1, R0);
  // R1: receiver cid as Smi

  __ Bind(&loop);
  __ ldr(R2, Address(R8, 0));
  __ cmp(R1, Operand(R2));
  __ b(&found, EQ);
  __ CompareImmediate(R2, Smi::RawValue(kIllegalCid));
  __ b(&miss, EQ);

  const intptr_t entry_length = ICData::TestEntryLengthFor(1) * kWordSize;
  __ AddImmediate(R8, R8, entry_length);  // Next entry.
  __ b(&loop);

  __ Bind(&found);
  const intptr_t code_offset = ICData::CodeIndexFor(1) * kWordSize;
  const intptr_t entry_offset = ICData::EntryPointIndexFor(1) * kWordSize;
  __ ldr(R1, Address(R8, entry_offset));
  __ ldr(CODE_REG, Address(R8, code_offset));
  __ br(R1);

  __ Bind(&miss);
  __ LoadIsolate(R2);
  __ ldr(CODE_REG, Address(R2, Isolate::ic_miss_code_offset()));
  __ ldr(R1, FieldAddress(CODE_REG, Code::entry_point_offset()));
  __ br(R1);
}


// Called from switchable IC calls.
//  R0: receiver
//  R5: SingleTargetCache
void StubCode::GenerateUnlinkedCallStub(Assembler* assembler) {
  __ NoMonomorphicCheckedEntry();

  __ EnterStubFrame();
  __ Push(R0);  // Preserve receiver.

  __ Push(ZR);  // Result slot.
  __ Push(R0);  // Arg0: Receiver
  __ Push(R5);  // Arg1: UnlinkedCall
  __ CallRuntime(kUnlinkedCallRuntimeEntry, 2);
  __ Drop(2);
  __ Pop(R5);  // result = IC

  __ Pop(R0);  // Restore receiver.
  __ LeaveStubFrame();

  __ ldr(CODE_REG, Address(THR, Thread::ic_lookup_through_code_stub_offset()));
  __ ldr(R1, FieldAddress(CODE_REG, Code::checked_entry_point_offset()));
  __ br(R1);
}


// Called from switchable IC calls.
//  R0: receiver
//  R5: SingleTargetCache
// Passed to target:
//  CODE_REG: target Code object
void StubCode::GenerateSingleTargetCallStub(Assembler* assembler) {
  __ NoMonomorphicCheckedEntry();

  Label miss;

  __ LoadClassIdMayBeSmi(R1, R0);
  __ ldr(R2, FieldAddress(R5, SingleTargetCache::lower_limit_offset()),
         kUnsignedWord);
  __ ldr(R3, FieldAddress(R5, SingleTargetCache::upper_limit_offset()),
         kUnsignedWord);

  __ cmp(R1, Operand(R2));
  __ b(&miss, LT);
  __ cmp(R1, Operand(R3));
  __ b(&miss, GT);

  __ ldr(R1, FieldAddress(R5, SingleTargetCache::entry_point_offset()));
  __ ldr(CODE_REG, FieldAddress(R5, SingleTargetCache::target_offset()));
  __ br(R1);

  __ Bind(&miss);
  __ EnterStubFrame();
  __ Push(R0);  // Preserve receiver.

  __ Push(ZR);  // Result slot.
  __ Push(R0);  // Arg0: Receiver
  __ CallRuntime(kSingleTargetMissRuntimeEntry, 1);
  __ Drop(1);
  __ Pop(R5);  // result = IC

  __ Pop(R0);  // Restore receiver.
  __ LeaveStubFrame();

  __ ldr(CODE_REG, Address(THR, Thread::ic_lookup_through_code_stub_offset()));
  __ ldr(R1, FieldAddress(CODE_REG, Code::checked_entry_point_offset()));
  __ br(R1);
}


// Called from the monomorphic checked entry.
//  R0: receiver
void StubCode::GenerateMonomorphicMissStub(Assembler* assembler) {
  __ ldr(CODE_REG, Address(THR, Thread::monomorphic_miss_stub_offset()));
  __ EnterStubFrame();
  __ Push(R0);  // Preserve receiver.

  __ Push(ZR);  // Result slot.
  __ Push(R0);  // Arg0: Receiver
  __ CallRuntime(kMonomorphicMissRuntimeEntry, 1);
  __ Drop(1);
  __ Pop(R5);  // result = IC

  __ Pop(R0);  // Restore receiver.
  __ LeaveStubFrame();

  __ ldr(CODE_REG, Address(THR, Thread::ic_lookup_through_code_stub_offset()));
  __ ldr(R1, FieldAddress(CODE_REG, Code::checked_entry_point_offset()));
  __ br(R1);
}


void StubCode::GenerateFrameAwaitingMaterializationStub(Assembler* assembler) {
  __ brk(0);
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
