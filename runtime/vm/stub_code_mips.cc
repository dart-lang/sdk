// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

#include "vm/assembler.h"
#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph_compiler.h"
#include "vm/heap.h"
#include "vm/instructions.h"
#include "vm/object_store.h"
#include "vm/runtime_entry.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/tags.h"

#define __ assembler->

namespace dart {

DEFINE_FLAG(bool, inline_alloc, true, "Inline allocation of objects.");
DEFINE_FLAG(bool,
            use_slow_path,
            false,
            "Set to true for debugging & verifying the slow paths.");
DECLARE_FLAG(bool, trace_optimized_ic_calls);

// Input parameters:
//   RA : return address.
//   SP : address of last argument in argument array.
//   SP + 4*S4 - 4 : address of first argument in argument array.
//   SP + 4*S4 : address of return value.
//   S5 : address of the runtime function to call.
//   S4 : number of arguments to the call.
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
  __ sw(FP, Address(THR, Thread::top_exit_frame_info_offset()));

#if defined(DEBUG)
  {
    Label ok;
    // Check that we are always entering from Dart code.
    __ lw(T0, Assembler::VMTagAddress());
    __ BranchEqual(T0, Immediate(VMTag::kDartTagId), &ok);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the thread is executing VM code.
  __ sw(S5, Assembler::VMTagAddress());

  // Reserve space for arguments and align frame before entering C++ world.
  // NativeArguments are passed in registers.
  ASSERT(sizeof(NativeArguments) == 4 * kWordSize);
  __ ReserveAlignedFrameSpace(4 * kWordSize);  // Reserve space for arguments.

  // Pass NativeArguments structure by value and call runtime.
  // Registers A0, A1, A2, and A3 are used.

  ASSERT(thread_offset == 0 * kWordSize);
  // Set thread in NativeArgs.
  __ mov(A0, THR);

  // There are no runtime calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * kWordSize);
  __ mov(A1, S4);  // Set argc in NativeArguments.

  ASSERT(argv_offset == 2 * kWordSize);
  __ sll(A2, S4, 2);
  __ addu(A2, FP, A2);  // Compute argv.
  // Set argv in NativeArguments.
  __ addiu(A2, A2, Immediate(kParamEndSlotFromFp * kWordSize));


  // Call runtime or redirection via simulator.
  // We defensively always jalr through T9 because it is sometimes required by
  // the MIPS ABI.
  __ mov(T9, S5);
  __ jalr(T9);

  ASSERT(retval_offset == 3 * kWordSize);
  // Retval is next to 1st argument.
  __ delay_slot()->addiu(A3, A2, Immediate(kWordSize));
  __ Comment("CallToRuntimeStub return");

  // Mark that the thread is executing Dart code.
  __ LoadImmediate(A2, VMTag::kDartTagId);
  __ sw(A2, Assembler::VMTagAddress());

  // Reset exit frame information in Isolate structure.
  __ sw(ZR, Address(THR, Thread::top_exit_frame_info_offset()));

  __ LeaveStubFrameAndReturn();
}


// Print the stop message.
DEFINE_LEAF_RUNTIME_ENTRY(void, PrintStopMessage, 1, const char* message) {
  OS::Print("Stop message: %s\n", message);
}
END_LEAF_RUNTIME_ENTRY


// Input parameters:
//   A0 : stop message (const char*).
// Must preserve all registers.
void StubCode::GeneratePrintStopMessageStub(Assembler* assembler) {
  __ EnterCallRuntimeFrame(0);
  // Call the runtime leaf function. A0 already contains the parameter.
  __ CallRuntime(kPrintStopMessageRuntimeEntry, 1);
  __ LeaveCallRuntimeFrame();
  __ Ret();
}


// Input parameters:
//   RA : return address.
//   SP : address of return value.
//   T5 : address of the native function to call.
//   A2 : address of first argument in argument array.
//   A1 : argc_tag including number of arguments and function kind.
static void GenerateCallNativeWithWrapperStub(Assembler* assembler,
                                              Address wrapper) {
  const intptr_t thread_offset = NativeArguments::thread_offset();
  const intptr_t argc_tag_offset = NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = NativeArguments::argv_offset();
  const intptr_t retval_offset = NativeArguments::retval_offset();

  __ SetPrologueOffset();
  __ Comment("CallNativeCFunctionStub");
  __ EnterStubFrame();

  // Save exit frame information to enable stack walking as we are about
  // to transition to native code.
  __ sw(FP, Address(THR, Thread::top_exit_frame_info_offset()));

#if defined(DEBUG)
  {
    Label ok;
    // Check that we are always entering from Dart code.
    __ lw(T0, Assembler::VMTagAddress());
    __ BranchEqual(T0, Immediate(VMTag::kDartTagId), &ok);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the thread is executing native code.
  __ sw(T5, Assembler::VMTagAddress());

  // Initialize NativeArguments structure and call native function.
  // Registers A0, A1, A2, and A3 are used.

  ASSERT(thread_offset == 0 * kWordSize);
  // Set thread in NativeArgs.
  __ mov(A0, THR);

  // There are no native calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * kWordSize);
  // Set argc in NativeArguments: A1 already contains argc.

  ASSERT(argv_offset == 2 * kWordSize);
  // Set argv in NativeArguments: A2 already contains argv.

  ASSERT(retval_offset == 3 * kWordSize);
  // Set retval in NativeArgs.
  __ addiu(A3, FP, Immediate(kCallerSpSlotFromFp * kWordSize));

  // Passing the structure by value as in runtime calls would require changing
  // Dart API for native functions.
  // For now, space is reserved on the stack and we pass a pointer to it.
  __ addiu(SP, SP, Immediate(-4 * kWordSize));
  __ sw(A3, Address(SP, 3 * kWordSize));
  __ sw(A2, Address(SP, 2 * kWordSize));
  __ sw(A1, Address(SP, 1 * kWordSize));
  __ sw(A0, Address(SP, 0 * kWordSize));
  __ mov(A0, SP);  // Pass the pointer to the NativeArguments.


  __ mov(A1, T5);                              // Pass the function entrypoint.
  __ ReserveAlignedFrameSpace(2 * kWordSize);  // Just passing A0, A1.

  // Call native wrapper function or redirection via simulator.
  __ lw(T9, wrapper);
  __ jalr(T9);
  __ Comment("CallNativeCFunctionStub return");

  // Mark that the thread is executing Dart code.
  __ LoadImmediate(A2, VMTag::kDartTagId);
  __ sw(A2, Assembler::VMTagAddress());

  // Reset exit frame information in Isolate structure.
  __ sw(ZR, Address(THR, Thread::top_exit_frame_info_offset()));

  __ LeaveStubFrameAndReturn();
}


void StubCode::GenerateCallNoScopeNativeStub(Assembler* assembler) {
  GenerateCallNativeWithWrapperStub(
      assembler,
      Address(THR, Thread::no_scope_native_wrapper_entry_point_offset()));
}


void StubCode::GenerateCallAutoScopeNativeStub(Assembler* assembler) {
  GenerateCallNativeWithWrapperStub(
      assembler,
      Address(THR, Thread::auto_scope_native_wrapper_entry_point_offset()));
}


// Input parameters:
//   RA : return address.
//   SP : address of return value.
//   T5 : address of the native function to call.
//   A2 : address of first argument in argument array.
//   A1 : argc_tag including number of arguments and function kind.
void StubCode::GenerateCallBootstrapNativeStub(Assembler* assembler) {
  const intptr_t thread_offset = NativeArguments::thread_offset();
  const intptr_t argc_tag_offset = NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = NativeArguments::argv_offset();
  const intptr_t retval_offset = NativeArguments::retval_offset();

  __ SetPrologueOffset();
  __ Comment("CallNativeCFunctionStub");
  __ EnterStubFrame();

  // Save exit frame information to enable stack walking as we are about
  // to transition to native code.
  __ sw(FP, Address(THR, Thread::top_exit_frame_info_offset()));

#if defined(DEBUG)
  {
    Label ok;
    // Check that we are always entering from Dart code.
    __ lw(T0, Assembler::VMTagAddress());
    __ BranchEqual(T0, Immediate(VMTag::kDartTagId), &ok);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the thread is executing native code.
  __ sw(T5, Assembler::VMTagAddress());

  // Initialize NativeArguments structure and call native function.
  // Registers A0, A1, A2, and A3 are used.

  ASSERT(thread_offset == 0 * kWordSize);
  // Set thread in NativeArgs.
  __ mov(A0, THR);

  // There are no native calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * kWordSize);
  // Set argc in NativeArguments: A1 already contains argc.

  ASSERT(argv_offset == 2 * kWordSize);
  // Set argv in NativeArguments: A2 already contains argv.

  ASSERT(retval_offset == 3 * kWordSize);
  // Set retval in NativeArgs.
  __ addiu(A3, FP, Immediate(kCallerSpSlotFromFp * kWordSize));

  // Passing the structure by value as in runtime calls would require changing
  // Dart API for native functions.
  // For now, space is reserved on the stack and we pass a pointer to it.
  __ addiu(SP, SP, Immediate(-4 * kWordSize));
  __ sw(A3, Address(SP, 3 * kWordSize));
  __ sw(A2, Address(SP, 2 * kWordSize));
  __ sw(A1, Address(SP, 1 * kWordSize));
  __ sw(A0, Address(SP, 0 * kWordSize));
  __ mov(A0, SP);  // Pass the pointer to the NativeArguments.

  __ ReserveAlignedFrameSpace(kWordSize);  // Just passing A0.

  // Call native function or redirection via simulator.

  // We defensively always jalr through T9 because it is sometimes required by
  // the MIPS ABI.
  __ mov(T9, T5);
  __ jalr(T9);
  __ Comment("CallNativeCFunctionStub return");

  // Mark that the thread is executing Dart code.
  __ LoadImmediate(A2, VMTag::kDartTagId);
  __ sw(A2, Assembler::VMTagAddress());

  // Reset exit frame information in Isolate structure.
  __ sw(ZR, Address(THR, Thread::top_exit_frame_info_offset()));

  __ LeaveStubFrameAndReturn();
}


// Input parameters:
//   S4: arguments descriptor array.
void StubCode::GenerateCallStaticFunctionStub(Assembler* assembler) {
  __ Comment("CallStaticFunctionStub");
  __ EnterStubFrame();
  // Setup space on stack for return value and preserve arguments descriptor.

  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(S4, Address(SP, 1 * kWordSize));
  __ sw(ZR, Address(SP, 0 * kWordSize));

  __ CallRuntime(kPatchStaticCallRuntimeEntry, 0);
  __ Comment("CallStaticFunctionStub return");

  // Get Code object result and restore arguments descriptor array.
  __ lw(CODE_REG, Address(SP, 0 * kWordSize));
  __ lw(S4, Address(SP, 1 * kWordSize));
  __ addiu(SP, SP, Immediate(2 * kWordSize));

  __ lw(T0, FieldAddress(CODE_REG, Code::entry_point_offset()));

  // Remove the stub frame as we are about to jump to the dart function.
  __ LeaveStubFrameAndReturn(T0);
}


// Called from a static call only when an invalid code has been entered
// (invalid because its function was optimized or deoptimized).
// S4: arguments descriptor array.
void StubCode::GenerateFixCallersTargetStub(Assembler* assembler) {
  // Load code pointer to this stub from the thread:
  // The one that is passed in, is not correct - it points to the code object
  // that needs to be replaced.
  __ lw(CODE_REG, Address(THR, Thread::fix_callers_target_code_offset()));
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value and preserve arguments descriptor.
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(S4, Address(SP, 1 * kWordSize));
  __ sw(ZR, Address(SP, 0 * kWordSize));
  __ CallRuntime(kFixCallersTargetRuntimeEntry, 0);
  // Get Code object result and restore arguments descriptor array.
  __ lw(CODE_REG, Address(SP, 0 * kWordSize));
  __ lw(S4, Address(SP, 1 * kWordSize));
  __ addiu(SP, SP, Immediate(2 * kWordSize));

  // Jump to the dart function.
  __ lw(T0, FieldAddress(CODE_REG, Code::entry_point_offset()));

  // Remove the stub frame.
  __ LeaveStubFrameAndReturn(T0);
}


// Called from object allocate instruction when the allocation stub has been
// disabled.
void StubCode::GenerateFixAllocationStubTargetStub(Assembler* assembler) {
  // Load code pointer to this stub from the thread:
  // The one that is passed in, is not correct - it points to the code object
  // that needs to be replaced.
  __ lw(CODE_REG, Address(THR, Thread::fix_allocation_stub_code_offset()));
  __ EnterStubFrame();
  // Setup space on stack for return value.
  __ addiu(SP, SP, Immediate(-1 * kWordSize));
  __ sw(ZR, Address(SP, 0 * kWordSize));
  __ CallRuntime(kFixAllocationStubTargetRuntimeEntry, 0);
  // Get Code object result.
  __ lw(CODE_REG, Address(SP, 0 * kWordSize));
  __ addiu(SP, SP, Immediate(1 * kWordSize));

  // Jump to the dart function.
  __ lw(T0, FieldAddress(CODE_REG, Code::entry_point_offset()));

  // Remove the stub frame.
  __ LeaveStubFrameAndReturn(T0);
}


// Input parameters:
//   A1: Smi-tagged argument count, may be zero.
//   FP[kParamEndSlotFromFp + 1]: Last argument.
static void PushArgumentsArray(Assembler* assembler) {
  __ Comment("PushArgumentsArray");
  // Allocate array to store arguments of caller.
  __ LoadObject(A0, Object::null_object());
  // A0: Null element type for raw Array.
  // A1: Smi-tagged argument count, may be zero.
  __ BranchLink(*StubCode::AllocateArray_entry());
  __ Comment("PushArgumentsArray return");
  // V0: newly allocated array.
  // A1: Smi-tagged argument count, may be zero (was preserved by the stub).
  __ Push(V0);  // Array is in V0 and on top of stack.
  __ sll(T1, A1, 1);
  __ addu(T1, FP, T1);
  __ AddImmediate(T1, kParamEndSlotFromFp * kWordSize);
  // T1: address of first argument on stack.
  // T2: address of first argument in array.

  Label loop, loop_exit;
  __ blez(A1, &loop_exit);
  __ delay_slot()->addiu(T2, V0,
                         Immediate(Array::data_offset() - kHeapObjectTag));
  __ Bind(&loop);
  __ lw(T3, Address(T1));
  __ addiu(A1, A1, Immediate(-Smi::RawValue(1)));
  __ addiu(T1, T1, Immediate(-kWordSize));
  __ addiu(T2, T2, Immediate(kWordSize));
  __ bgez(A1, &loop);
  __ delay_slot()->sw(T3, Address(T2, -kWordSize));
  __ Bind(&loop_exit);
}


// Used by eager and lazy deoptimization. Preserve result in V0 if necessary.
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
//   | Saved CODE_REG   |
//   +------------------+
//   | Saved FP         | <- FP of stub
//   +------------------+
//   | Saved LR         |  (deoptimization point)
//   +------------------+
//   | Saved CODE_REG   |
//   +------------------+
//   | ...              | <- SP of optimized frame
//
// Parts of the code cannot GC, part of the code can GC.
static void GenerateDeoptimizationSequence(Assembler* assembler,
                                           DeoptStubKind kind) {
  const intptr_t kPushedRegistersSize =
      kNumberOfCpuRegisters * kWordSize + kNumberOfFRegisters * kWordSize;

  __ SetPrologueOffset();
  __ Comment("GenerateDeoptimizationSequence");
  // DeoptimizeCopyFrame expects a Dart frame.
  __ EnterStubFrame(kPushedRegistersSize);

  // The code in this frame may not cause GC. kDeoptimizeCopyFrameRuntimeEntry
  // and kDeoptimizeFillFrameRuntimeEntry are leaf runtime calls.
  const intptr_t saved_result_slot_from_fp =
      kFirstLocalSlotFromFp + 1 - (kNumberOfCpuRegisters - V0);
  const intptr_t saved_exception_slot_from_fp =
      kFirstLocalSlotFromFp + 1 - (kNumberOfCpuRegisters - V0);
  const intptr_t saved_stacktrace_slot_from_fp =
      kFirstLocalSlotFromFp + 1 - (kNumberOfCpuRegisters - V1);
  // Result in V0 is preserved as part of pushing all registers below.

  // Push registers in their enumeration order: lowest register number at
  // lowest address.
  for (int i = 0; i < kNumberOfCpuRegisters; i++) {
    const int slot = kNumberOfCpuRegisters - i;
    Register reg = static_cast<Register>(i);
    if (reg == CODE_REG) {
      // Save the original value of CODE_REG pushed before invoking this stub
      // instead of the value used to call this stub.
      COMPILE_ASSERT(TMP < CODE_REG);  // Assert TMP is pushed first.
      __ lw(TMP, Address(FP, kCallerSpSlotFromFp * kWordSize));
      __ sw(TMP, Address(SP, kPushedRegistersSize - slot * kWordSize));
    } else {
      __ sw(reg, Address(SP, kPushedRegistersSize - slot * kWordSize));
    }
  }
  for (int i = 0; i < kNumberOfFRegisters; i++) {
    // These go below the CPU registers.
    const int slot = kNumberOfCpuRegisters + kNumberOfFRegisters - i;
    FRegister reg = static_cast<FRegister>(i);
    __ swc1(reg, Address(SP, kPushedRegistersSize - slot * kWordSize));
  }

  __ mov(A0, SP);  // Pass address of saved registers block.
  bool is_lazy =
      (kind == kLazyDeoptFromReturn) || (kind == kLazyDeoptFromThrow);
  __ LoadImmediate(A1, is_lazy ? 1 : 0);
  __ ReserveAlignedFrameSpace(1 * kWordSize);
  __ CallRuntime(kDeoptimizeCopyFrameRuntimeEntry, 2);
  // Result (V0) is stack-size (FP - SP) in bytes, incl. the return address.

  if (kind == kLazyDeoptFromReturn) {
    // Restore result into T1 temporarily.
    __ lw(T1, Address(FP, saved_result_slot_from_fp * kWordSize));
  } else if (kind == kLazyDeoptFromThrow) {
    // Restore result into T1 temporarily.
    __ lw(T1, Address(FP, saved_exception_slot_from_fp * kWordSize));
    __ lw(T2, Address(FP, saved_stacktrace_slot_from_fp * kWordSize));
  }

  __ RestoreCodePointer();
  __ LeaveDartFrame();
  __ subu(SP, FP, V0);

  // DeoptimizeFillFrame expects a Dart frame, i.e. EnterDartFrame(0), but there
  // is no need to set the correct PC marker or load PP, since they get patched.
  __ EnterStubFrame();

  __ mov(A0, FP);  // Get last FP address.
  if (kind == kLazyDeoptFromReturn) {
    __ Push(T1);  // Preserve result as first local.
  } else if (kind == kLazyDeoptFromThrow) {
    __ Push(T1);  // Preserve exception as first local.
    __ Push(T2);  // Preserve stacktrace as second local.
  }
  __ ReserveAlignedFrameSpace(1 * kWordSize);
  __ CallRuntime(kDeoptimizeFillFrameRuntimeEntry, 1);  // Pass last FP in A0.
  if (kind == kLazyDeoptFromReturn) {
    // Restore result into T1.
    __ lw(T1, Address(FP, kFirstLocalSlotFromFp * kWordSize));
  } else if (kind == kLazyDeoptFromThrow) {
    // Restore result into T1.
    __ lw(T1, Address(FP, kFirstLocalSlotFromFp * kWordSize));
    __ lw(T2, Address(FP, (kFirstLocalSlotFromFp - 1) * kWordSize));
  }
  // Code above cannot cause GC.
  __ RestoreCodePointer();
  __ LeaveStubFrame();

  // Frame is fully rewritten at this point and it is safe to perform a GC.
  // Materialize any objects that were deferred by FillFrame because they
  // require allocation.
  // Enter stub frame with loading PP. The caller's PP is not materialized yet.
  __ EnterStubFrame();
  if (kind == kLazyDeoptFromReturn) {
    __ Push(T1);  // Preserve result, it will be GC-d here.
  } else if (kind == kLazyDeoptFromThrow) {
    __ Push(T1);  // Preserve exception, it will be GC-d here.
    __ Push(T2);  // Preserve stacktrace, it will be GC-d here.
  }
  __ PushObject(Smi::ZoneHandle());  // Space for the result.
  __ CallRuntime(kDeoptimizeMaterializeRuntimeEntry, 0);
  // Result tells stub how many bytes to remove from the expression stack
  // of the bottom-most frame. They were used as materialization arguments.
  __ Pop(T1);
  if (kind == kLazyDeoptFromReturn) {
    __ Pop(V0);  // Restore result.
  } else if (kind == kLazyDeoptFromThrow) {
    __ Pop(V1);  // Restore stacktrace.
    __ Pop(V0);  // Restore exception.
  }
  __ LeaveStubFrame();
  // Remove materialization arguments.
  __ SmiUntag(T1);
  __ addu(SP, SP, T1);
  // The caller is responsible for emitting the return instruction.
}

// V0: result, must be preserved
void StubCode::GenerateDeoptimizeLazyFromReturnStub(Assembler* assembler) {
  // Push zap value instead of CODE_REG for lazy deopt.
  __ LoadImmediate(TMP, kZapCodeReg);
  __ Push(TMP);
  // Return address for "call" to deopt stub.
  __ LoadImmediate(RA, kZapReturnAddress);
  __ lw(CODE_REG, Address(THR, Thread::lazy_deopt_from_return_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kLazyDeoptFromReturn);
  __ Ret();
}


// V0: exception, must be preserved
// V1: stacktrace, must be preserved
void StubCode::GenerateDeoptimizeLazyFromThrowStub(Assembler* assembler) {
  // Push zap value instead of CODE_REG for lazy deopt.
  __ LoadImmediate(TMP, kZapCodeReg);
  __ Push(TMP);
  // Return address for "call" to deopt stub.
  __ LoadImmediate(RA, kZapReturnAddress);
  __ lw(CODE_REG, Address(THR, Thread::lazy_deopt_from_throw_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kLazyDeoptFromThrow);
  __ Ret();
}


void StubCode::GenerateDeoptimizeStub(Assembler* assembler) {
  GenerateDeoptimizationSequence(assembler, kEagerDeopt);
  __ Ret();
}


static void GenerateDispatcherCode(Assembler* assembler,
                                   Label* call_target_function) {
  __ Comment("NoSuchMethodDispatch");
  // When lazily generated invocation dispatchers are disabled, the
  // miss-handler may return null.
  __ BranchNotEqual(T0, Object::null_object(), call_target_function);
  __ EnterStubFrame();
  // Load the receiver.
  __ lw(A1, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
  __ sll(TMP, A1, 1);  // A1 is a Smi.
  __ addu(TMP, FP, TMP);
  __ lw(T6, Address(TMP, kParamEndSlotFromFp * kWordSize));

  // Push space for the return value.
  // Push the receiver.
  // Push ICData/MegamorphicCache object.
  // Push arguments descriptor array.
  // Push original arguments array.
  __ addiu(SP, SP, Immediate(-4 * kWordSize));
  __ sw(ZR, Address(SP, 3 * kWordSize));
  __ sw(T6, Address(SP, 2 * kWordSize));
  __ sw(S5, Address(SP, 1 * kWordSize));
  __ sw(S4, Address(SP, 0 * kWordSize));

  // Adjust arguments count.
  __ lw(TMP, FieldAddress(S4, ArgumentsDescriptor::type_args_len_offset()));
  Label args_count_ok;
  __ BranchEqual(TMP, Immediate(0), &args_count_ok);
  __ AddImmediate(A1, A1, Smi::RawValue(1));  // Include the type arguments.
  __ Bind(&args_count_ok);

  // A1: Smi-tagged arguments array length.
  PushArgumentsArray(assembler);
  const intptr_t kNumArgs = 4;
  __ CallRuntime(kInvokeNoSuchMethodDispatcherRuntimeEntry, kNumArgs);
  __ lw(V0, Address(SP, 4 * kWordSize));  // Return value.
  __ addiu(SP, SP, Immediate(5 * kWordSize));
  __ LeaveStubFrame();
  __ Ret();
}


void StubCode::GenerateMegamorphicMissStub(Assembler* assembler) {
  __ EnterStubFrame();

  // Load the receiver.
  __ lw(T2, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
  __ sll(T2, T2, 1);  // T2 is a Smi.
  __ addu(TMP, FP, T2);
  __ lw(T6, Address(TMP, kParamEndSlotFromFp * kWordSize));

  // Preserve IC data and arguments descriptor.
  __ addiu(SP, SP, Immediate(-6 * kWordSize));
  __ sw(S5, Address(SP, 5 * kWordSize));
  __ sw(S4, Address(SP, 4 * kWordSize));

  // Push space for the return value.
  // Push the receiver.
  // Push IC data object.
  // Push arguments descriptor array.
  __ sw(ZR, Address(SP, 3 * kWordSize));
  __ sw(T6, Address(SP, 2 * kWordSize));
  __ sw(S5, Address(SP, 1 * kWordSize));
  __ sw(S4, Address(SP, 0 * kWordSize));

  __ CallRuntime(kMegamorphicCacheMissHandlerRuntimeEntry, 3);

  __ lw(T0, Address(SP, 3 * kWordSize));  // Get result function.
  __ lw(S4, Address(SP, 4 * kWordSize));  // Restore argument descriptor.
  __ lw(S5, Address(SP, 5 * kWordSize));  // Restore IC data.
  __ addiu(SP, SP, Immediate(6 * kWordSize));

  __ RestoreCodePointer();
  __ LeaveStubFrame();

  if (!FLAG_lazy_dispatchers) {
    Label call_target_function;
    GenerateDispatcherCode(assembler, &call_target_function);
    __ Bind(&call_target_function);
  }

  __ lw(CODE_REG, FieldAddress(T0, Function::code_offset()));
  __ lw(T2, FieldAddress(T0, Function::entry_point_offset()));
  __ jr(T2);
}


// Called for inline allocation of arrays.
// Input parameters:
//   RA: return address.
//   A1: Array length as Smi (must be preserved).
//   A0: array element type (either NULL or an instantiated type).
// NOTE: A1 cannot be clobbered here as the caller relies on it being saved.
// The newly allocated object is returned in V0.
void StubCode::GenerateAllocateArrayStub(Assembler* assembler) {
  __ Comment("AllocateArrayStub");
  Label slow_case;
  // Compute the size to be allocated, it is based on the array length
  // and is computed as:
  // RoundedAllocationSize((array_length * kwordSize) + sizeof(RawArray)).
  __ mov(T3, A1);  // Array length.

  // Check that length is a positive Smi.
  __ andi(CMPRES1, T3, Immediate(kSmiTagMask));
  if (FLAG_use_slow_path) {
    __ b(&slow_case);
  } else {
    __ bne(CMPRES1, ZR, &slow_case);
  }
  __ bltz(T3, &slow_case);

  // Check for maximum allowed length.
  const intptr_t max_len =
      reinterpret_cast<int32_t>(Smi::New(Array::kMaxElements));
  __ BranchUnsignedGreater(T3, Immediate(max_len), &slow_case);

  const intptr_t cid = kArrayCid;
  NOT_IN_PRODUCT(__ MaybeTraceAllocation(kArrayCid, T4, &slow_case));

  const intptr_t fixed_size_plus_alignment_padding =
      sizeof(RawArray) + kObjectAlignment - 1;
  __ LoadImmediate(T2, fixed_size_plus_alignment_padding);
  __ sll(T3, T3, 1);  // T3 is  a Smi.
  __ addu(T2, T2, T3);
  ASSERT(kSmiTagShift == 1);
  __ LoadImmediate(T3, ~(kObjectAlignment - 1));
  __ and_(T2, T2, T3);

  // T2: Allocation size.

  Heap::Space space = Heap::kNew;
  __ lw(T3, Address(THR, Thread::heap_offset()));
  // Potential new object start.
  __ lw(T0, Address(T3, Heap::TopOffset(space)));

  __ addu(T1, T0, T2);                        // Potential next object start.
  __ BranchUnsignedLess(T1, T0, &slow_case);  // Branch on unsigned overflow.

  // Check if the allocation fits into the remaining space.
  // T0: potential new object start.
  // T1: potential next object start.
  // T2: allocation size.
  // T3: heap.
  __ lw(T4, Address(T3, Heap::EndOffset(space)));
  __ BranchUnsignedGreaterEqual(T1, T4, &slow_case);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  // T3: heap.
  __ sw(T1, Address(T3, Heap::TopOffset(space)));
  __ addiu(T0, T0, Immediate(kHeapObjectTag));
  NOT_IN_PRODUCT(__ UpdateAllocationStatsWithSize(cid, T2, T4, space));

  // Initialize the tags.
  // T0: new object start as a tagged pointer.
  // T1: new object end address.
  // T2: allocation size.
  {
    Label overflow, done;
    const intptr_t shift = RawObject::kSizeTagPos - kObjectAlignmentLog2;

    __ BranchUnsignedGreater(T2, Immediate(RawObject::SizeTag::kMaxSizeTag),
                             &overflow);
    __ b(&done);
    __ delay_slot()->sll(T2, T2, shift);
    __ Bind(&overflow);
    __ mov(T2, ZR);
    __ Bind(&done);

    // Get the class index and insert it into the tags.
    // T2: size and bit tags.
    __ LoadImmediate(TMP, RawObject::ClassIdTag::encode(cid));
    __ or_(T2, T2, TMP);
    __ sw(T2, FieldAddress(T0, Array::tags_offset()));  // Store tags.
  }

  // T0: new object start as a tagged pointer.
  // T1: new object end address.
  // Store the type argument field.
  __ StoreIntoObjectNoBarrier(
      T0, FieldAddress(T0, Array::type_arguments_offset()), A0);

  // Set the length field.
  __ StoreIntoObjectNoBarrier(T0, FieldAddress(T0, Array::length_offset()), A1);

  __ LoadObject(T7, Object::null_object());
  // Initialize all array elements to raw_null.
  // T0: new object start as a tagged pointer.
  // T1: new object end address.
  // T2: iterator which initially points to the start of the variable
  // data area to be initialized.
  // T7: null.
  __ AddImmediate(T2, T0, sizeof(RawArray) - kHeapObjectTag);

  Label done;
  Label init_loop;
  __ Bind(&init_loop);
  __ BranchUnsignedGreaterEqual(T2, T1, &done);
  __ sw(T7, Address(T2, 0));
  __ b(&init_loop);
  __ delay_slot()->addiu(T2, T2, Immediate(kWordSize));
  __ Bind(&done);

  __ Ret();  // Returns the newly allocated object in V0.
  __ delay_slot()->mov(V0, T0);

  // Unable to allocate the array using the fast inline code, just call
  // into the runtime.
  __ Bind(&slow_case);
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value.
  // Push array length as Smi and element type.
  __ addiu(SP, SP, Immediate(-3 * kWordSize));
  __ sw(ZR, Address(SP, 2 * kWordSize));
  __ sw(A1, Address(SP, 1 * kWordSize));
  __ sw(A0, Address(SP, 0 * kWordSize));
  __ CallRuntime(kAllocateArrayRuntimeEntry, 2);
  __ Comment("AllocateArrayStub return");
  // Pop arguments; result is popped in IP.
  __ lw(V0, Address(SP, 2 * kWordSize));
  __ lw(A1, Address(SP, 1 * kWordSize));
  __ lw(A0, Address(SP, 0 * kWordSize));
  __ addiu(SP, SP, Immediate(3 * kWordSize));

  __ LeaveStubFrameAndReturn();
}


// Called when invoking Dart code from C++ (VM code).
// Input parameters:
//   RA : points to return address.
//   A0 : code object of the Dart function to call.
//   A1 : arguments descriptor array.
//   A2 : arguments array.
//   A3 : current thread.
void StubCode::GenerateInvokeDartCodeStub(Assembler* assembler) {
  // Save frame pointer coming in.
  __ Comment("InvokeDartCodeStub");
  __ EnterFrame();

  // Push code object to PC marker slot.
  __ lw(TMP, Address(A3, Thread::invoke_dart_code_stub_offset()));
  __ Push(TMP);

  // Save new context and C++ ABI callee-saved registers.

  // The saved vm tag, top resource, and top exit frame info.
  const intptr_t kPreservedSlots = 3;
  const intptr_t kPreservedRegSpace =
      kWordSize *
      (kAbiPreservedCpuRegCount + kAbiPreservedFpuRegCount + kPreservedSlots);

  __ addiu(SP, SP, Immediate(-kPreservedRegSpace));
  for (int i = S0; i <= S7; i++) {
    Register r = static_cast<Register>(i);
    const intptr_t slot = i - S0 + kPreservedSlots;
    __ sw(r, Address(SP, slot * kWordSize));
  }

  for (intptr_t i = kAbiFirstPreservedFpuReg; i <= kAbiLastPreservedFpuReg;
       i++) {
    FRegister r = static_cast<FRegister>(i);
    const intptr_t slot = kAbiPreservedCpuRegCount + kPreservedSlots + i -
                          kAbiFirstPreservedFpuReg;
    __ swc1(r, Address(SP, slot * kWordSize));
  }

  // We now load the pool pointer(PP) with a GC safe value as we are about
  // to invoke dart code.
  __ LoadImmediate(PP, 0);

  // Set up THR, which caches the current thread in Dart code.
  if (THR != A3) {
    __ mov(THR, A3);
  }

  // Save the current VMTag on the stack.
  __ lw(T1, Assembler::VMTagAddress());
  __ sw(T1, Address(SP, 2 * kWordSize));

  // Mark that the thread is executing Dart code.
  __ LoadImmediate(T0, VMTag::kDartTagId);
  __ sw(T0, Assembler::VMTagAddress());

  // Save top resource and top exit frame info. Use T0 as a temporary register.
  // StackFrameIterator reads the top exit frame info saved in this frame.
  __ lw(T0, Address(THR, Thread::top_resource_offset()));
  __ sw(ZR, Address(THR, Thread::top_resource_offset()));
  __ sw(T0, Address(SP, 1 * kWordSize));
  __ lw(T0, Address(THR, Thread::top_exit_frame_info_offset()));
  __ sw(ZR, Address(THR, Thread::top_exit_frame_info_offset()));
  // kExitLinkSlotFromEntryFp must be kept in sync with the code below.
  ASSERT(kExitLinkSlotFromEntryFp == -24);
  __ sw(T0, Address(SP, 0 * kWordSize));

  // After the call, The stack pointer is restored to this location.
  // Pushed S0-7, F20-31, T0, T0, T1 = 23.

  // Load arguments descriptor array into S4, which is passed to Dart code.
  __ lw(S4, Address(A1, VMHandles::kOffsetOfRawPtrInHandle));

  // No need to check for type args, disallowed by DartEntry::InvokeFunction.
  // Load number of arguments into S5.
  __ lw(T1, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
  __ SmiUntag(T1);

  // Compute address of 'arguments array' data area into A2.
  __ lw(A2, Address(A2, VMHandles::kOffsetOfRawPtrInHandle));

  // Set up arguments for the Dart call.
  Label push_arguments;
  Label done_push_arguments;
  __ beq(T1, ZR, &done_push_arguments);  // check if there are arguments.
  __ delay_slot()->addiu(A2, A2,
                         Immediate(Array::data_offset() - kHeapObjectTag));
  __ mov(A1, ZR);
  __ Bind(&push_arguments);
  __ lw(A3, Address(A2));
  __ Push(A3);
  __ addiu(A1, A1, Immediate(1));
  __ BranchSignedLess(A1, T1, &push_arguments);
  __ delay_slot()->addiu(A2, A2, Immediate(kWordSize));

  __ Bind(&done_push_arguments);

  // Call the Dart code entrypoint.
  // We are calling into Dart code, here, so there is no need to call through
  // T9 to match the ABI.
  __ lw(CODE_REG, Address(A0, VMHandles::kOffsetOfRawPtrInHandle));
  __ lw(A0, FieldAddress(CODE_REG, Code::entry_point_offset()));
  __ jalr(A0);  // S4 is the arguments descriptor array.
  __ Comment("InvokeDartCodeStub return");

  // Get rid of arguments pushed on the stack.
  __ AddImmediate(SP, FP, kExitLinkSlotFromEntryFp * kWordSize);


  // Restore the current VMTag from the stack.
  __ lw(T1, Address(SP, 2 * kWordSize));
  __ sw(T1, Assembler::VMTagAddress());

  // Restore the saved top resource and top exit frame info back into the
  // Isolate structure. Uses T0 as a temporary register for this.
  __ lw(T0, Address(SP, 1 * kWordSize));
  __ sw(T0, Address(THR, Thread::top_resource_offset()));
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ sw(T0, Address(THR, Thread::top_exit_frame_info_offset()));

  // Restore C++ ABI callee-saved registers.
  for (int i = S0; i <= S7; i++) {
    Register r = static_cast<Register>(i);
    const intptr_t slot = i - S0 + kPreservedSlots;
    __ lw(r, Address(SP, slot * kWordSize));
  }

  for (intptr_t i = kAbiFirstPreservedFpuReg; i <= kAbiLastPreservedFpuReg;
       i++) {
    FRegister r = static_cast<FRegister>(i);
    const intptr_t slot = kAbiPreservedCpuRegCount + kPreservedSlots + i -
                          kAbiFirstPreservedFpuReg;
    __ lwc1(r, Address(SP, slot * kWordSize));
  }

  __ addiu(SP, SP, Immediate(kPreservedRegSpace));

  // Restore the frame pointer and return.
  __ LeaveFrameAndReturn();
}


// Called for inline allocation of contexts.
// Input:
//   T1: number of context variables.
// Output:
//   V0: new allocated RawContext object.
void StubCode::GenerateAllocateContextStub(Assembler* assembler) {
  __ Comment("AllocateContext");
  if (FLAG_inline_alloc) {
    Label slow_case;
    // First compute the rounded instance size.
    // T1: number of context variables.
    intptr_t fixed_size_plus_alignment_padding =
        sizeof(RawContext) + kObjectAlignment - 1;
    __ LoadImmediate(T2, fixed_size_plus_alignment_padding);
    __ sll(T0, T1, 2);
    __ addu(T2, T2, T0);
    ASSERT(kSmiTagShift == 1);
    __ LoadImmediate(T0, ~((kObjectAlignment)-1));
    __ and_(T2, T2, T0);

    NOT_IN_PRODUCT(__ MaybeTraceAllocation(kContextCid, T4, &slow_case));
    // Now allocate the object.
    // T1: number of context variables.
    // T2: object size.
    const intptr_t cid = kContextCid;
    Heap::Space space = Heap::kNew;
    __ lw(T5, Address(THR, Thread::heap_offset()));
    __ lw(V0, Address(T5, Heap::TopOffset(space)));
    __ addu(T3, T2, V0);

    // Check if the allocation fits into the remaining space.
    // V0: potential new object.
    // T1: number of context variables.
    // T2: object size.
    // T3: potential next object start.
    // T5: heap.
    __ lw(CMPRES1, Address(T5, Heap::EndOffset(space)));
    if (FLAG_use_slow_path) {
      __ b(&slow_case);
    } else {
      __ BranchUnsignedGreaterEqual(T3, CMPRES1, &slow_case);
    }

    // Successfully allocated the object, now update top to point to
    // next object start and initialize the object.
    // V0: new object.
    // T1: number of context variables.
    // T2: object size.
    // T3: next object start.
    // T5: heap.
    __ sw(T3, Address(T5, Heap::TopOffset(space)));
    __ addiu(V0, V0, Immediate(kHeapObjectTag));
    NOT_IN_PRODUCT(__ UpdateAllocationStatsWithSize(cid, T2, T5, space));

    // Calculate the size tag.
    // V0: new object.
    // T1: number of context variables.
    // T2: object size.
    const intptr_t shift = RawObject::kSizeTagPos - kObjectAlignmentLog2;
    __ LoadImmediate(TMP, RawObject::SizeTag::kMaxSizeTag);
    __ sltu(CMPRES1, TMP, T2);  // CMPRES1 = T2 > TMP ? 1 : 0.
    __ movn(T2, ZR, CMPRES1);   // T2 = CMPRES1 != 0 ? 0 : T2.
    __ sll(TMP, T2, shift);     // TMP = T2 << shift.
    __ movz(T2, TMP, CMPRES1);  // T2 = CMPRES1 == 0 ? TMP : T2.

    // Get the class index and insert it into the tags.
    // T2: size and bit tags.
    __ LoadImmediate(TMP, RawObject::ClassIdTag::encode(cid));
    __ or_(T2, T2, TMP);
    __ sw(T2, FieldAddress(V0, Context::tags_offset()));

    // Setup up number of context variables field.
    // V0: new object.
    // T1: number of context variables as integer value (not object).
    __ sw(T1, FieldAddress(V0, Context::num_variables_offset()));

    __ LoadObject(T7, Object::null_object());

    // Initialize the context variables.
    // V0: new object.
    // T1: number of context variables.
    Label loop, loop_exit;
    __ blez(T1, &loop_exit);
    // Setup the parent field.
    __ delay_slot()->sw(T7, FieldAddress(V0, Context::parent_offset()));
    __ AddImmediate(T3, V0, Context::variable_offset(0) - kHeapObjectTag);
    __ sll(T1, T1, 2);
    __ Bind(&loop);
    __ addiu(T1, T1, Immediate(-kWordSize));
    __ addu(T4, T3, T1);
    __ bgtz(T1, &loop);
    __ delay_slot()->sw(T7, Address(T4));
    __ Bind(&loop_exit);

    // Done allocating and initializing the context.
    // V0: new object.
    __ Ret();

    __ Bind(&slow_case);
  }
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value.
  __ SmiTag(T1);
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ LoadObject(TMP, Object::null_object());
  __ sw(TMP, Address(SP, 1 * kWordSize));  // Store null.
  __ sw(T1, Address(SP, 0 * kWordSize));
  __ CallRuntime(kAllocateContextRuntimeEntry, 1);  // Allocate context.
  __ lw(V0, Address(SP, 1 * kWordSize));            // Get the new context.
  __ addiu(SP, SP, Immediate(2 * kWordSize));       // Pop argument and return.

  // V0: new object
  // Restore the frame pointer.
  __ LeaveStubFrameAndReturn();
}


// Helper stub to implement Assembler::StoreIntoObject.
// Input parameters:
//   T0: Address (i.e. object) being stored into.
void StubCode::GenerateUpdateStoreBufferStub(Assembler* assembler) {
  // Save values being destroyed.
  __ Comment("UpdateStoreBufferStub");
  __ addiu(SP, SP, Immediate(-3 * kWordSize));
  __ sw(T3, Address(SP, 2 * kWordSize));
  __ sw(T2, Address(SP, 1 * kWordSize));
  __ sw(T1, Address(SP, 0 * kWordSize));

  Label add_to_buffer;
  // Check whether this object has already been remembered. Skip adding to the
  // store buffer if the object is in the store buffer already.
  // Spilled: T1, T2, T3.
  // T0: Address being stored.
  __ lw(T2, FieldAddress(T0, Object::tags_offset()));
  __ andi(CMPRES1, T2, Immediate(1 << RawObject::kRememberedBit));
  __ beq(CMPRES1, ZR, &add_to_buffer);
  __ lw(T1, Address(SP, 0 * kWordSize));
  __ lw(T2, Address(SP, 1 * kWordSize));
  __ lw(T3, Address(SP, 2 * kWordSize));
  __ addiu(SP, SP, Immediate(3 * kWordSize));
  __ Ret();

  __ Bind(&add_to_buffer);
  // Atomically set the remembered bit of the object header.
  Label retry;
  __ Bind(&retry);
  __ ll(T2, FieldAddress(T0, Object::tags_offset()));
  __ ori(T2, T2, Immediate(1 << RawObject::kRememberedBit));
  __ sc(T2, FieldAddress(T0, Object::tags_offset()));
  // T2 = 1 on success, 0 on failure.
  __ beq(T2, ZR, &retry);

  // Load the StoreBuffer block out of the thread. Then load top_ out of the
  // StoreBufferBlock and add the address to the pointers_.
  __ lw(T1, Address(THR, Thread::store_buffer_block_offset()));
  __ lw(T2, Address(T1, StoreBufferBlock::top_offset()));
  __ sll(T3, T2, 2);
  __ addu(T3, T1, T3);
  __ sw(T0, Address(T3, StoreBufferBlock::pointers_offset()));

  // Increment top_ and check for overflow.
  // T2: top_
  // T1: StoreBufferBlock
  Label L;
  __ addiu(T2, T2, Immediate(1));
  __ sw(T2, Address(T1, StoreBufferBlock::top_offset()));
  __ addiu(CMPRES1, T2, Immediate(-StoreBufferBlock::kSize));
  // Restore values.
  __ lw(T1, Address(SP, 0 * kWordSize));
  __ lw(T2, Address(SP, 1 * kWordSize));
  __ lw(T3, Address(SP, 2 * kWordSize));
  __ beq(CMPRES1, ZR, &L);
  __ delay_slot()->addiu(SP, SP, Immediate(3 * kWordSize));
  __ Ret();

  // Handle overflow: Call the runtime leaf function.
  __ Bind(&L);
  // Setup frame, push callee-saved registers.

  __ EnterCallRuntimeFrame(1 * kWordSize);
  __ mov(A0, THR);
  __ CallRuntime(kStoreBufferBlockProcessRuntimeEntry, 1);
  __ Comment("UpdateStoreBufferStub return");
  // Restore callee-saved registers, tear down frame.
  __ LeaveCallRuntimeFrame();
  __ Ret();
}


// Called for inline allocation of objects.
// Input parameters:
//   RA : return address.
//   SP + 0 : type arguments object (only if class is parameterized).
void StubCode::GenerateAllocationStubForClass(Assembler* assembler,
                                              const Class& cls) {
  __ Comment("AllocationStubForClass");
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
    __ lw(T1, Address(SP, 0 * kWordSize));
    // T1: type arguments.
  }
  Isolate* isolate = Isolate::Current();
  if (FLAG_inline_alloc && Heap::IsAllocatableInNewSpace(instance_size) &&
      !cls.TraceAllocation(isolate)) {
    Label slow_case;
    // Allocate the object and update top to point to
    // next object start and initialize the allocated object.
    // T1: instantiated type arguments (if is_cls_parameterized).
    Heap::Space space = Heap::kNew;
    __ lw(T5, Address(THR, Thread::heap_offset()));
    __ lw(T2, Address(T5, Heap::TopOffset(space)));
    __ LoadImmediate(T4, instance_size);
    __ addu(T3, T2, T4);
    // Check if the allocation fits into the remaining space.
    // T2: potential new object start.
    // T3: potential next object start.
    // T5: heap.
    __ lw(CMPRES1, Address(T5, Heap::EndOffset(space)));
    if (FLAG_use_slow_path) {
      __ b(&slow_case);
    } else {
      __ BranchUnsignedGreaterEqual(T3, CMPRES1, &slow_case);
    }
    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    __ sw(T3, Address(T5, Heap::TopOffset(space)));
    NOT_IN_PRODUCT(__ UpdateAllocationStats(cls.id(), T5, space));

    // T2: new object start.
    // T3: next object start.
    // T1: new object type arguments (if is_cls_parameterized).
    // Set the tags.
    uint32_t tags = 0;
    tags = RawObject::SizeTag::update(instance_size, tags);
    ASSERT(cls.id() != kIllegalCid);
    tags = RawObject::ClassIdTag::update(cls.id(), tags);
    __ LoadImmediate(T0, tags);
    __ sw(T0, Address(T2, Instance::tags_offset()));

    __ LoadObject(T7, Object::null_object());

    // Initialize the remaining words of the object.
    // T2: new object start.
    // T3: next object start.
    // T1: new object type arguments (if is_cls_parameterized).
    // First try inlining the initialization without a loop.
    if (instance_size < (kInlineInstanceSize * kWordSize)) {
      // Check if the object contains any non-header fields.
      // Small objects are initialized using a consecutive set of writes.
      for (intptr_t current_offset = Instance::NextFieldOffset();
           current_offset < instance_size; current_offset += kWordSize) {
        __ sw(T7, Address(T2, current_offset));
      }
    } else {
      __ addiu(T4, T2, Immediate(Instance::NextFieldOffset()));
      // Loop until the whole object is initialized.
      // T2: new object.
      // T3: next object start.
      // T4: next word to be initialized.
      // T1: new object type arguments (if is_cls_parameterized).
      Label loop, loop_exit;
      __ BranchUnsignedGreaterEqual(T4, T3, &loop_exit);
      __ Bind(&loop);
      __ addiu(T4, T4, Immediate(kWordSize));
      __ bne(T4, T3, &loop);
      __ delay_slot()->sw(T7, Address(T4, -kWordSize));
      __ Bind(&loop_exit);
    }
    if (is_cls_parameterized) {
      // T1: new object type arguments.
      // Set the type arguments in the new object.
      __ sw(T1, Address(T2, cls.type_arguments_field_offset()));
    }
    // Done allocating and initializing the instance.
    // T2: new object still missing its heap tag.
    __ Ret();
    __ delay_slot()->addiu(V0, T2, Immediate(kHeapObjectTag));

    __ Bind(&slow_case);
  }
  // If is_cls_parameterized:
  // T1: new object type arguments (instantiated or not).
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();  // Uses pool pointer to pass cls to runtime.
  __ LoadObject(TMP, cls);

  __ addiu(SP, SP, Immediate(-3 * kWordSize));
  // Space on stack for return value.
  __ LoadObject(T7, Object::null_object());
  __ sw(T7, Address(SP, 2 * kWordSize));
  __ sw(TMP, Address(SP, 1 * kWordSize));  // Class of object to be allocated.

  if (is_cls_parameterized) {
    // Push type arguments of object to be allocated and of instantiator.
    __ sw(T1, Address(SP, 0 * kWordSize));
  } else {
    // Push null type arguments.
    __ sw(T7, Address(SP, 0 * kWordSize));
  }
  __ CallRuntime(kAllocateObjectRuntimeEntry, 2);  // Allocate object.
  __ Comment("AllocationStubForClass return");
  // Pop result (newly allocated object).
  __ lw(V0, Address(SP, 2 * kWordSize));
  __ addiu(SP, SP, Immediate(3 * kWordSize));  // Pop arguments.
  // V0: new object
  // Restore the frame pointer and return.
  __ LeaveStubFrameAndReturn(RA);
}


// Called for invoking "dynamic noSuchMethod(Invocation invocation)" function
// from the entry code of a dart function after an error in passed argument
// name or number is detected.
// Input parameters:
//  RA : return address.
//  SP : address of last argument.
//  S4: arguments descriptor array.
void StubCode::GenerateCallClosureNoSuchMethodStub(Assembler* assembler) {
  __ EnterStubFrame();

  // Load the receiver.
  __ lw(A1, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
  __ sll(TMP, A1, 1);  // A1 is a Smi.
  __ addu(TMP, FP, TMP);
  __ lw(T6, Address(TMP, kParamEndSlotFromFp * kWordSize));

  // Push space for the return value.
  // Push the receiver.
  // Push arguments descriptor array.
  const intptr_t kNumArgs = 3;
  __ addiu(SP, SP, Immediate(-kNumArgs * kWordSize));
  __ sw(ZR, Address(SP, 2 * kWordSize));
  __ sw(T6, Address(SP, 1 * kWordSize));
  __ sw(S4, Address(SP, 0 * kWordSize));

  // Adjust arguments count.
  __ lw(TMP, FieldAddress(S4, ArgumentsDescriptor::type_args_len_offset()));
  Label args_count_ok;
  __ BranchEqual(TMP, Immediate(0), &args_count_ok);
  __ AddImmediate(A1, A1, Smi::RawValue(1));  // Include the type arguments.
  __ Bind(&args_count_ok);

  // A1: Smi-tagged arguments array length.
  PushArgumentsArray(assembler);

  __ CallRuntime(kInvokeClosureNoSuchMethodRuntimeEntry, kNumArgs);
  // noSuchMethod on closures always throws an error, so it will never return.
  __ break_(0);
}


//  T0: function object.
//  S5: inline cache data object.
// Cannot use function object from ICData as it may be the inlined
// function and not the top-scope function.
void StubCode::GenerateOptimizedUsageCounterIncrement(Assembler* assembler) {
  __ Comment("OptimizedUsageCounterIncrement");
  Register ic_reg = S5;
  Register func_reg = T0;
  if (FLAG_trace_optimized_ic_calls) {
    __ EnterStubFrame();
    __ addiu(SP, SP, Immediate(-4 * kWordSize));
    __ sw(T0, Address(SP, 3 * kWordSize));
    __ sw(S5, Address(SP, 2 * kWordSize));
    __ sw(ic_reg, Address(SP, 1 * kWordSize));    // Argument.
    __ sw(func_reg, Address(SP, 0 * kWordSize));  // Argument.
    __ CallRuntime(kTraceICCallRuntimeEntry, 2);
    __ lw(S5, Address(SP, 2 * kWordSize));
    __ lw(T0, Address(SP, 3 * kWordSize));
    __ addiu(SP, SP, Immediate(4 * kWordSize));  // Discard argument;
    __ LeaveStubFrame();
  }
  __ lw(T7, FieldAddress(func_reg, Function::usage_counter_offset()));
  __ addiu(T7, T7, Immediate(1));
  __ sw(T7, FieldAddress(func_reg, Function::usage_counter_offset()));
}


// Loads function into 'temp_reg'.
void StubCode::GenerateUsageCounterIncrement(Assembler* assembler,
                                             Register temp_reg) {
  if (FLAG_optimization_counter_threshold >= 0) {
    __ Comment("UsageCounterIncrement");
    Register ic_reg = S5;
    Register func_reg = temp_reg;
    ASSERT(temp_reg == T0);
    __ Comment("Increment function counter");
    __ lw(func_reg, FieldAddress(ic_reg, ICData::owner_offset()));
    __ lw(T1, FieldAddress(func_reg, Function::usage_counter_offset()));
    __ addiu(T1, T1, Immediate(1));
    __ sw(T1, FieldAddress(func_reg, Function::usage_counter_offset()));
  }
}


// Note: S5 must be preserved.
// Attempt a quick Smi operation for known operations ('kind'). The ICData
// must have been primed with a Smi/Smi check that will be used for counting
// the invocations.
static void EmitFastSmiOp(Assembler* assembler,
                          Token::Kind kind,
                          intptr_t num_args,
                          Label* not_smi_or_overflow) {
  __ Comment("Fast Smi op");
  ASSERT(num_args == 2);
  __ lw(T0, Address(SP, 0 * kWordSize));  // Left.
  __ lw(T1, Address(SP, 1 * kWordSize));  // Right.
  __ or_(CMPRES1, T0, T1);
  __ andi(CMPRES1, CMPRES1, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, not_smi_or_overflow);
  switch (kind) {
    case Token::kADD: {
      __ AdduDetectOverflow(V0, T1, T0, CMPRES1);  // Add.
      __ bltz(CMPRES1, not_smi_or_overflow);       // Fall through on overflow.
      break;
    }
    case Token::kSUB: {
      __ SubuDetectOverflow(V0, T1, T0, CMPRES1);  // Subtract.
      __ bltz(CMPRES1, not_smi_or_overflow);       // Fall through on overflow.
      break;
    }
    case Token::kEQ: {
      Label true_label, done;
      __ beq(T1, T0, &true_label);
      __ LoadObject(V0, Bool::False());
      __ b(&done);
      __ Bind(&true_label);
      __ LoadObject(V0, Bool::True());
      __ Bind(&done);
      break;
    }
    default:
      UNIMPLEMENTED();
  }
  // S5: IC data object (preserved).
  __ lw(T0, FieldAddress(S5, ICData::ic_data_offset()));
  // T0: ic_data_array with check entries: classes and target functions.
  __ AddImmediate(T0, Array::data_offset() - kHeapObjectTag);
// T0: points directly to the first ic data array element.
#if defined(DEBUG)
  // Check that first entry is for Smi/Smi.
  Label error, ok;
  const int32_t imm_smi_cid = reinterpret_cast<int32_t>(Smi::New(kSmiCid));
  __ lw(T4, Address(T0));
  __ BranchNotEqual(T4, Immediate(imm_smi_cid), &error);
  __ lw(T4, Address(T0, kWordSize));
  __ BranchEqual(T4, Immediate(imm_smi_cid), &ok);
  __ Bind(&error);
  __ Stop("Incorrect IC data");
  __ Bind(&ok);
#endif
  if (FLAG_optimization_counter_threshold >= 0) {
    // Update counter, ignore overflow.
    const intptr_t count_offset = ICData::CountIndexFor(num_args) * kWordSize;
    __ lw(T4, Address(T0, count_offset));
    __ AddImmediate(T4, T4, Smi::RawValue(1));
    __ sw(T4, Address(T0, count_offset));
  }

  __ Ret();
}


// Generate inline cache check for 'num_args'.
//  RA: return address
//  S5: Inline cache data object.
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
  __ Comment("NArgsCheckInlineCacheStub");
  ASSERT(num_args == 1 || num_args == 2);
#if defined(DEBUG)
  {
    Label ok;
    // Check that the IC data array has NumArgsTested() == num_args.
    // 'NumArgsTested' is stored in the least significant bits of 'state_bits'.
    __ lw(T0, FieldAddress(S5, ICData::state_bits_offset()));
    ASSERT(ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ andi(T0, T0, Immediate(ICData::NumArgsTestedMask()));
    __ BranchEqual(T0, Immediate(num_args), &ok);
    __ Stop("Incorrect stub for IC data");
    __ Bind(&ok);
  }
#endif  // DEBUG


  Label stepping, done_stepping;
  if (FLAG_support_debugger && !optimized) {
    __ Comment("Check single stepping");
    __ LoadIsolate(T0);
    __ lbu(T0, Address(T0, Isolate::single_step_offset()));
    __ BranchNotEqual(T0, Immediate(0), &stepping);
    __ Bind(&done_stepping);
  }

  Label not_smi_or_overflow;
  if (kind != Token::kILLEGAL) {
    EmitFastSmiOp(assembler, kind, num_args, &not_smi_or_overflow);
  }
  __ Bind(&not_smi_or_overflow);

  __ Comment("Extract ICData initial values and receiver cid");
  // Load argument descriptor into S4.
  __ lw(S4, FieldAddress(S5, ICData::arguments_descriptor_offset()));
  // Preserve return address, since RA is needed for subroutine call.
  __ mov(T2, RA);
  // Loop that checks if there is an IC data match.
  Label loop, found, miss;
  // S5: IC data object (preserved).
  __ lw(T0, FieldAddress(S5, ICData::ic_data_offset()));
  // T0: ic_data_array with check entries: classes and target functions.
  __ AddImmediate(T0, Array::data_offset() - kHeapObjectTag);
  // T0: points directly to the first ic data array element.

  // Get the receiver's class ID (first read number of arguments from
  // arguments descriptor array and then access the receiver from the stack).
  __ lw(T1, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
  __ sll(T5, T1, 1);  // T1 (argument_count - 1) is smi.
  __ addu(T5, T5, SP);
  __ lw(T3, Address(T5, -kWordSize));
  __ LoadTaggedClassIdMayBeSmi(T3, T3);

  if (num_args == 2) {
    __ lw(T5, Address(T5, -2 * kWordSize));
    __ LoadTaggedClassIdMayBeSmi(T5, T5);
  }

  const intptr_t entry_size = ICData::TestEntryLengthFor(num_args) * kWordSize;
  // T1: argument_count (smi).
  // T3: receiver's class ID (smi).
  // T5: first argument's class ID (smi).

  // We unroll the generic one that is generated once more than the others.
  const bool optimize = kind == Token::kILLEGAL;

  __ Comment("ICData loop");
  __ Bind(&loop);
  for (int unroll = optimize ? 4 : 2; unroll >= 0; unroll--) {
    __ lw(T4, Address(T0, 0));
    if (num_args == 1) {
      __ beq(T3, T4, &found);  // IC hit.
    } else {
      ASSERT(num_args == 2);
      Label update;
      __ bne(T3, T4, &update);  // Continue.
      __ lw(T4, Address(T0, kWordSize));
      __ beq(T5, T4, &found);  // IC hit.
      __ Bind(&update);
    }

    __ AddImmediate(T0, entry_size);  // Next entry.
    if (unroll == 0) {
      __ BranchNotEqual(T4, Immediate(Smi::RawValue(kIllegalCid)),
                        &loop);  // Done?
    } else {
      __ BranchEqual(T4, Immediate(Smi::RawValue(kIllegalCid)),
                     &miss);  // Done?
    }
  }

  __ Bind(&miss);
  __ Comment("IC miss");
  // Restore return address.
  __ mov(RA, T2);

  // Compute address of arguments (first read number of arguments from
  // arguments descriptor array and then compute address on the stack).
  // T1: argument_count (smi).
  __ addiu(T1, T1, Immediate(Smi::RawValue(-1)));
  __ sll(T1, T1, 1);  // T1 is Smi.
  __ addu(T1, SP, T1);
  // T1: address of receiver.
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Preserve IC data object and arguments descriptor array and
  // setup space on stack for result (target code object).
  int num_slots = num_args + 4;
  __ addiu(SP, SP, Immediate(-num_slots * kWordSize));
  __ sw(S5, Address(SP, (num_slots - 1) * kWordSize));
  __ sw(S4, Address(SP, (num_slots - 2) * kWordSize));
  __ sw(ZR, Address(SP, (num_slots - 3) * kWordSize));
  // Push call arguments.
  for (intptr_t i = 0; i < num_args; i++) {
    __ lw(TMP, Address(T1, -i * kWordSize));
    __ sw(TMP, Address(SP, (num_slots - i - 4) * kWordSize));
  }
  // Pass IC data object.
  __ sw(S5, Address(SP, (num_slots - num_args - 4) * kWordSize));
  __ CallRuntime(handle_ic_miss, num_args + 1);
  __ Comment("NArgsCheckInlineCacheStub return");
  // Pop returned function object into T3.
  // Restore arguments descriptor array and IC data array.
  __ lw(T3, Address(SP, (num_slots - 3) * kWordSize));
  __ lw(S4, Address(SP, (num_slots - 2) * kWordSize));
  __ lw(S5, Address(SP, (num_slots - 1) * kWordSize));
  // Remove the call arguments pushed earlier, including the IC data object
  // and the arguments descriptor array.
  __ addiu(SP, SP, Immediate(num_slots * kWordSize));
  __ RestoreCodePointer();
  __ LeaveStubFrame();

  Label call_target_function;
  if (!FLAG_lazy_dispatchers) {
    __ mov(T0, T3);
    GenerateDispatcherCode(assembler, &call_target_function);
  } else {
    __ b(&call_target_function);
  }

  __ Bind(&found);
  __ mov(RA, T2);  // Restore return address if found.
  __ Comment("Update caller's counter");
  // T0: Pointer to an IC data check group.
  const intptr_t target_offset = ICData::TargetIndexFor(num_args) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(num_args) * kWordSize;
  __ lw(T3, Address(T0, target_offset));

  if (FLAG_optimization_counter_threshold >= 0) {
    // Update counter, ignore overflow.
    __ lw(T4, Address(T0, count_offset));
    __ AddImmediate(T4, T4, Smi::RawValue(1));
    __ sw(T4, Address(T0, count_offset));
  }

  __ Comment("Call target");
  __ Bind(&call_target_function);
  // T0 <- T3: Target function.
  __ mov(T0, T3);
  Label is_compiled;
  __ lw(T4, FieldAddress(T0, Function::entry_point_offset()));
  __ lw(CODE_REG, FieldAddress(T0, Function::code_offset()));
  __ jr(T4);

  // Call single step callback in debugger.
  if (FLAG_support_debugger && !optimized) {
    __ Bind(&stepping);
    __ EnterStubFrame();
    __ addiu(SP, SP, Immediate(-2 * kWordSize));
    __ sw(S5, Address(SP, 1 * kWordSize));  // Preserve IC data.
    __ sw(RA, Address(SP, 0 * kWordSize));  // Return address.
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ lw(RA, Address(SP, 0 * kWordSize));
    __ lw(S5, Address(SP, 1 * kWordSize));
    __ addiu(SP, SP, Immediate(2 * kWordSize));
    __ RestoreCodePointer();
    __ LeaveStubFrame();
    __ b(&done_stepping);
  }
}


// Use inline cache data array to invoke the target or continue in inline
// cache miss handler. Stub for 1-argument check (receiver class).
//  RA: Return address.
//  S5: Inline cache data object.
// Inline cache data object structure:
// 0: function-name
// 1: N, number of arguments checked.
// 2 .. (length - 1): group of checks, each check containing:
//   - N classes.
//   - 1 target function.
void StubCode::GenerateOneArgCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, T0);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL);
}


void StubCode::GenerateTwoArgsCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, T0);
  GenerateNArgsCheckInlineCacheStub(assembler, 2,
                                    kInlineCacheMissHandlerTwoArgsRuntimeEntry,
                                    Token::kILLEGAL);
}


void StubCode::GenerateSmiAddInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, T0);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kADD);
}


void StubCode::GenerateSmiSubInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, T0);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kSUB);
}


void StubCode::GenerateSmiEqualInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, T0);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kEQ);
}


void StubCode::GenerateOneArgOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateOptimizedUsageCounterIncrement(assembler);
  GenerateNArgsCheckInlineCacheStub(assembler, 1,
                                    kInlineCacheMissHandlerOneArgRuntimeEntry,
                                    Token::kILLEGAL, true /* optimized */);
}


void StubCode::GenerateTwoArgsOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateOptimizedUsageCounterIncrement(assembler);
  GenerateNArgsCheckInlineCacheStub(assembler, 2,
                                    kInlineCacheMissHandlerTwoArgsRuntimeEntry,
                                    Token::kILLEGAL, true /* optimized */);
}


// Intermediary stub between a static call and its target. ICData contains
// the target function and the call count.
// S5: ICData
void StubCode::GenerateZeroArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, T0);
  __ Comment("UnoptimizedStaticCallStub");
#if defined(DEBUG)
  {
    Label ok;
    // Check that the IC data array has NumArgsTested() == 0.
    // 'NumArgsTested' is stored in the least significant bits of 'state_bits'.
    __ lw(T0, FieldAddress(S5, ICData::state_bits_offset()));
    ASSERT(ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ andi(T0, T0, Immediate(ICData::NumArgsTestedMask()));
    __ beq(T0, ZR, &ok);
    __ Stop("Incorrect IC data for unoptimized static call");
    __ Bind(&ok);
  }
#endif  // DEBUG

  // Check single stepping.
  Label stepping, done_stepping;
  if (FLAG_support_debugger) {
    __ LoadIsolate(T0);
    __ lbu(T0, Address(T0, Isolate::single_step_offset()));
    __ BranchNotEqual(T0, Immediate(0), &stepping);
    __ Bind(&done_stepping);
  }

  // S5: IC data object (preserved).
  __ lw(T0, FieldAddress(S5, ICData::ic_data_offset()));
  // T0: ic_data_array with entries: target functions and count.
  __ AddImmediate(T0, Array::data_offset() - kHeapObjectTag);
  // T0: points directly to the first ic data array element.
  const intptr_t target_offset = ICData::TargetIndexFor(0) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(0) * kWordSize;

  if (FLAG_optimization_counter_threshold >= 0) {
    // Increment count for this call, ignore overflow.
    __ lw(T4, Address(T0, count_offset));
    __ AddImmediate(T4, T4, Smi::RawValue(1));
    __ sw(T4, Address(T0, count_offset));
  }

  // Load arguments descriptor into S4.
  __ lw(S4, FieldAddress(S5, ICData::arguments_descriptor_offset()));

  // Get function and call it, if possible.
  __ lw(T0, Address(T0, target_offset));
  __ lw(CODE_REG, FieldAddress(T0, Function::code_offset()));
  __ lw(T4, FieldAddress(T0, Function::entry_point_offset()));
  __ jr(T4);

  // Call single step callback in debugger.
  if (FLAG_support_debugger) {
    __ Bind(&stepping);
    __ EnterStubFrame();
    __ addiu(SP, SP, Immediate(-2 * kWordSize));
    __ sw(S5, Address(SP, 1 * kWordSize));  // Preserve IC data.
    __ sw(RA, Address(SP, 0 * kWordSize));  // Return address.
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ lw(RA, Address(SP, 0 * kWordSize));
    __ lw(S5, Address(SP, 1 * kWordSize));
    __ addiu(SP, SP, Immediate(2 * kWordSize));
    __ RestoreCodePointer();
    __ LeaveStubFrame();
    __ b(&done_stepping);
  }
}


void StubCode::GenerateOneArgUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, T0);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kStaticCallMissHandlerOneArgRuntimeEntry, Token::kILLEGAL);
}


void StubCode::GenerateTwoArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, T0);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kStaticCallMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL);
}


// Stub for compiling a function and jumping to the compiled code.
// S5: IC-Data (for methods).
// S4: Arguments descriptor.
// T0: Function.
void StubCode::GenerateLazyCompileStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ addiu(SP, SP, Immediate(-3 * kWordSize));
  __ sw(S5, Address(SP, 2 * kWordSize));  // Preserve IC data object.
  __ sw(S4, Address(SP, 1 * kWordSize));  // Preserve args descriptor array.
  __ sw(T0, Address(SP, 0 * kWordSize));  // Pass function.
  __ CallRuntime(kCompileFunctionRuntimeEntry, 1);
  __ lw(T0, Address(SP, 0 * kWordSize));  // Restore function.
  __ lw(S4, Address(SP, 1 * kWordSize));  // Restore args descriptor array.
  __ lw(S5, Address(SP, 2 * kWordSize));  // Restore IC data array.
  __ addiu(SP, SP, Immediate(3 * kWordSize));
  __ LeaveStubFrame();

  __ lw(CODE_REG, FieldAddress(T0, Function::code_offset()));
  __ lw(T2, FieldAddress(T0, Function::entry_point_offset()));
  __ jr(T2);
}


// S5: Contains an ICData.
void StubCode::GenerateICCallBreakpointStub(Assembler* assembler) {
  __ Comment("ICCallBreakpoint stub");
  __ EnterStubFrame();
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(S5, Address(SP, 1 * kWordSize));
  __ sw(ZR, Address(SP, 0 * kWordSize));

  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);

  __ lw(S5, Address(SP, 1 * kWordSize));
  __ lw(CODE_REG, Address(SP, 0 * kWordSize));
  __ addiu(SP, SP, Immediate(2 * kWordSize));
  __ LeaveStubFrame();
  __ lw(T0, FieldAddress(CODE_REG, Code::entry_point_offset()));
  __ jr(T0);
}


void StubCode::GenerateRuntimeCallBreakpointStub(Assembler* assembler) {
  __ Comment("RuntimeCallBreakpoint stub");
  __ EnterStubFrame();
  __ addiu(SP, SP, Immediate(-1 * kWordSize));
  __ sw(ZR, Address(SP, 0 * kWordSize));

  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);

  __ lw(CODE_REG, Address(SP, 0 * kWordSize));
  __ addiu(SP, SP, Immediate(3 * kWordSize));
  __ LeaveStubFrame();
  __ lw(T0, FieldAddress(CODE_REG, Code::entry_point_offset()));
  __ jr(T0);
}


// Called only from unoptimized code. All relevant registers have been saved.
// RA: return address.
void StubCode::GenerateDebugStepCheckStub(Assembler* assembler) {
  // Check single stepping.
  Label stepping, done_stepping;
  __ LoadIsolate(T0);
  __ lbu(T0, Address(T0, Isolate::single_step_offset()));
  __ BranchNotEqual(T0, Immediate(0), &stepping);
  __ Bind(&done_stepping);

  __ Ret();

  // Call single step callback in debugger.
  __ Bind(&stepping);
  __ EnterStubFrame();
  __ addiu(SP, SP, Immediate(-1 * kWordSize));
  __ sw(RA, Address(SP, 0 * kWordSize));  // Return address.
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ lw(RA, Address(SP, 0 * kWordSize));
  __ addiu(SP, SP, Immediate(1 * kWordSize));
  __ LeaveStubFrame();
  __ b(&done_stepping);
}


// Used to check class and type arguments. Arguments passed in registers:
// RA: return address.
// A0: instance (must be preserved).
// A1: instantiator type arguments (only if n == 4, can be raw_null).
// A2: function type arguments (only if n == 4, can be raw_null).
// A3: SubtypeTestCache.
// Result in V0: null -> not found, otherwise result (true or false).
static void GenerateSubtypeNTestCacheStub(Assembler* assembler, int n) {
  __ Comment("SubtypeNTestCacheStub");
  ASSERT((n == 1) || (n == 2) || (n == 4));
  if (n > 1) {
    __ LoadClass(T0, A0);
    // Compute instance type arguments into T1.
    Label has_no_type_arguments;
    __ LoadObject(T1, Object::null_object());
    __ lw(T2, FieldAddress(
                  T0, Class::type_arguments_field_offset_in_words_offset()));
    __ BranchEqual(T2, Immediate(Class::kNoTypeArguments),
                   &has_no_type_arguments);
    __ sll(T2, T2, 2);
    __ addu(T2, A0, T2);  // T2 <- A0 + T2 * 4
    __ lw(T1, FieldAddress(T2, 0));
    __ Bind(&has_no_type_arguments);
  }
  __ LoadClassId(T0, A0);
  // A0: instance.
  // A1: instantiator type arguments (only if n == 4, can be raw_null).
  // A2: function type arguments (only if n == 4, can be raw_null).
  // A3: SubtypeTestCache.
  // T0: instance class id.
  // T1: instance type arguments (null if none), used only if n > 1.
  __ lw(T2, FieldAddress(A3, SubtypeTestCache::cache_offset()));
  __ AddImmediate(T2, Array::data_offset() - kHeapObjectTag);

  __ LoadObject(T7, Object::null_object());
  Label loop, found, not_found, next_iteration;
  // T0: instance class id.
  // T1: instance type arguments (still null if closure).
  // T2: Entry start.
  // T7: null.
  __ SmiTag(T0);
  __ BranchNotEqual(T0, Immediate(Smi::RawValue(kClosureCid)), &loop);
  __ lw(T1, FieldAddress(A0, Closure::function_type_arguments_offset()));
  __ bne(T1, T7, &not_found);  // Cache cannot be used for generic closures.
  __ lw(T1, FieldAddress(A0, Closure::instantiator_type_arguments_offset()));
  __ lw(T0, FieldAddress(A0, Closure::function_offset()));
  // T0: instance class id as Smi or function.
  __ Bind(&loop);
  __ lw(T3,
        Address(T2, kWordSize * SubtypeTestCache::kInstanceClassIdOrFunction));
  __ beq(T3, T7, &not_found);
  if (n == 1) {
    __ beq(T3, T0, &found);
  } else {
    __ bne(T3, T0, &next_iteration);
    __ lw(T3,
          Address(T2, kWordSize * SubtypeTestCache::kInstanceTypeArguments));
    if (n == 2) {
      __ beq(T3, T1, &found);
    } else {
      __ bne(T3, T1, &next_iteration);
      __ lw(T3, Address(T2, kWordSize *
                                SubtypeTestCache::kInstantiatorTypeArguments));
      __ bne(T3, A1, &next_iteration);
      __ lw(T3,
            Address(T2, kWordSize * SubtypeTestCache::kFunctionTypeArguments));
      __ beq(T3, A2, &found);
    }
  }
  __ Bind(&next_iteration);
  __ b(&loop);
  __ delay_slot()->addiu(
      T2, T2, Immediate(kWordSize * SubtypeTestCache::kTestEntryLength));
  // Fall through to not found.
  __ Bind(&not_found);
  __ Ret();
  __ delay_slot()->mov(V0, T7);

  __ Bind(&found);
  __ Ret();
  __ delay_slot()->lw(V0,
                      Address(T2, kWordSize * SubtypeTestCache::kTestResult));
}


// Used to check class and type arguments. Arguments passed in registers:
// RA: return address.
// A0: instance (must be preserved).
// A1: unused.
// A2: unused.
// A3: SubtypeTestCache.
// Result in V0: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype1TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 1);
}


// Used to check class and type arguments. Arguments passed in registers:
// RA: return address.
// A0: instance (must be preserved).
// A1: unused.
// A2: unused.
// A3: SubtypeTestCache.
// Result in V0: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype2TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 2);
}


// Used to check class and type arguments. Arguments passed in registers:
// RA: return address.
// A0: instance (must be preserved).
// A1: instantiator type arguments (can be raw_null).
// A2: function type arguments (can be raw_null).
// A3: SubtypeTestCache.
// Result in V0: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype4TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 4);
}


// Return the current stack pointer address, used to stack alignment
// checks.
void StubCode::GenerateGetCStackPointerStub(Assembler* assembler) {
  __ Ret();
  __ delay_slot()->mov(V0, SP);
}


// Jump to the exception or error handler.
// RA: return address.
// A0: program_counter.
// A1: stack_pointer.
// A2: frame_pointer.
// A3: thread.
// Does not return.
void StubCode::GenerateJumpToFrameStub(Assembler* assembler) {
  ASSERT(kExceptionObjectReg == V0);
  ASSERT(kStackTraceObjectReg == V1);
  __ mov(FP, A2);   // Frame_pointer.
  __ mov(THR, A3);  // Thread.
  // Set tag.
  __ LoadImmediate(A2, VMTag::kDartTagId);
  __ sw(A2, Assembler::VMTagAddress());
  // Clear top exit frame.
  __ sw(ZR, Address(THR, Thread::top_exit_frame_info_offset()));
  // Restore pool pointer.
  __ RestoreCodePointer();
  __ LoadPoolPointer();
  __ jr(A0);                     // Jump to the program counter.
  __ delay_slot()->mov(SP, A1);  // Stack pointer.
}


// Run an exception handler.  Execution comes from JumpToFrame
// stub or from the simulator.
//
// The arguments are stored in the Thread object.
// Does not return.
void StubCode::GenerateRunExceptionHandlerStub(Assembler* assembler) {
  __ lw(A0, Address(THR, Thread::resume_pc_offset()));
  __ LoadImmediate(A2, 0);

  // Load the exception from the current thread.
  Address exception_addr(THR, Thread::active_exception_offset());
  __ lw(V0, exception_addr);
  __ sw(A2, exception_addr);

  // Load the stacktrace from the current thread.
  Address stacktrace_addr(THR, Thread::active_stacktrace_offset());
  __ lw(V1, stacktrace_addr);

  __ jr(A0);  // Jump to continuation point.
  __ delay_slot()->sw(A2, stacktrace_addr);
}


// Deoptimize a frame on the call stack before rewinding.
// The arguments are stored in the Thread object.
// No result.
void StubCode::GenerateDeoptForRewindStub(Assembler* assembler) {
  // Push zap value instead of CODE_REG.
  __ LoadImmediate(TMP, kZapCodeReg);
  __ Push(TMP);

  // Load the deopt pc into RA.
  __ lw(RA, Address(THR, Thread::resume_pc_offset()));
  GenerateDeoptimizationSequence(assembler, kEagerDeopt);

  // After we have deoptimized, jump to the correct frame.
  __ EnterStubFrame();
  __ CallRuntime(kRewindPostDeoptRuntimeEntry, 0);
  __ LeaveStubFrame();
  __ break_(0);
}


// Calls to the runtime to optimize the given function.
// T0: function to be reoptimized.
// S4: argument descriptor (preserved).
void StubCode::GenerateOptimizeFunctionStub(Assembler* assembler) {
  __ Comment("OptimizeFunctionStub");
  __ EnterStubFrame();
  __ addiu(SP, SP, Immediate(-3 * kWordSize));
  __ sw(S4, Address(SP, 2 * kWordSize));
  // Setup space on stack for return value.
  __ sw(ZR, Address(SP, 1 * kWordSize));
  __ sw(T0, Address(SP, 0 * kWordSize));
  __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry, 1);
  __ Comment("OptimizeFunctionStub return");
  __ lw(T0, Address(SP, 1 * kWordSize));       // Get Function object
  __ lw(S4, Address(SP, 2 * kWordSize));       // Restore argument descriptor.
  __ addiu(SP, SP, Immediate(3 * kWordSize));  // Discard argument.

  __ lw(CODE_REG, FieldAddress(T0, Function::code_offset()));
  __ lw(T1, FieldAddress(T0, Function::entry_point_offset()));
  __ LeaveStubFrameAndReturn(T1);
  __ break_(0);
}


// Does identical check (object references are equal or not equal) with special
// checks for boxed numbers.
// Returns: CMPRES1 is zero if equal, non-zero otherwise.
// Note: A Mint cannot contain a value that would fit in Smi, a Bigint
// cannot contain a value that fits in Mint or Smi.
static void GenerateIdenticalWithNumberCheckStub(Assembler* assembler,
                                                 const Register left,
                                                 const Register right,
                                                 const Register temp1,
                                                 const Register temp2) {
  __ Comment("IdenticalWithNumberCheckStub");
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
  __ subu(CMPRES1, temp1, temp2);
  __ bne(CMPRES1, ZR, &done);

  // Double values bitwise compare.
  __ lw(temp1, FieldAddress(left, Double::value_offset() + 0 * kWordSize));
  __ lw(temp2, FieldAddress(right, Double::value_offset() + 0 * kWordSize));
  __ subu(CMPRES1, temp1, temp2);
  __ bne(CMPRES1, ZR, &done);
  __ lw(temp1, FieldAddress(left, Double::value_offset() + 1 * kWordSize));
  __ lw(temp2, FieldAddress(right, Double::value_offset() + 1 * kWordSize));
  __ b(&done);
  __ delay_slot()->subu(CMPRES1, temp1, temp2);

  __ Bind(&check_mint);
  __ LoadImmediate(temp1, kMintCid);
  __ LoadClassId(temp2, left);
  __ bne(temp1, temp2, &check_bigint);
  __ LoadClassId(temp2, right);
  __ subu(CMPRES1, temp1, temp2);
  __ bne(CMPRES1, ZR, &done);

  __ lw(temp1, FieldAddress(left, Mint::value_offset() + 0 * kWordSize));
  __ lw(temp2, FieldAddress(right, Mint::value_offset() + 0 * kWordSize));
  __ subu(CMPRES1, temp1, temp2);
  __ bne(CMPRES1, ZR, &done);
  __ lw(temp1, FieldAddress(left, Mint::value_offset() + 1 * kWordSize));
  __ lw(temp2, FieldAddress(right, Mint::value_offset() + 1 * kWordSize));
  __ b(&done);
  __ delay_slot()->subu(CMPRES1, temp1, temp2);

  __ Bind(&check_bigint);
  __ LoadImmediate(temp1, kBigintCid);
  __ LoadClassId(temp2, left);
  __ bne(temp1, temp2, &reference_compare);
  __ LoadClassId(temp2, right);
  __ subu(CMPRES1, temp1, temp2);
  __ bne(CMPRES1, ZR, &done);

  __ EnterStubFrame();
  __ ReserveAlignedFrameSpace(2 * kWordSize);
  __ sw(left, Address(SP, 1 * kWordSize));
  __ sw(right, Address(SP, 0 * kWordSize));
  __ mov(A0, left);
  __ mov(A1, right);
  __ CallRuntime(kBigintCompareRuntimeEntry, 2);
  __ Comment("IdenticalWithNumberCheckStub return");
  // Result in V0, 0 means equal.
  __ LeaveStubFrame();
  __ b(&done);
  __ delay_slot()->mov(CMPRES1, V0);

  __ Bind(&reference_compare);
  __ subu(CMPRES1, left, right);
  __ Bind(&done);
  // A branch or test after this comparison will check CMPRES1 == ZR.
}


// Called only from unoptimized code. All relevant registers have been saved.
// RA: return address.
// SP + 4: left operand.
// SP + 0: right operand.
// Returns: CMPRES1 is zero if equal, non-zero otherwise.
void StubCode::GenerateUnoptimizedIdenticalWithNumberCheckStub(
    Assembler* assembler) {
  // Check single stepping.
  Label stepping, done_stepping;
  if (FLAG_support_debugger) {
    __ LoadIsolate(T0);
    __ lbu(T0, Address(T0, Isolate::single_step_offset()));
    __ BranchNotEqual(T0, Immediate(0), &stepping);
    __ Bind(&done_stepping);
  }

  const Register temp1 = T2;
  const Register temp2 = T3;
  const Register left = T1;
  const Register right = T0;
  __ lw(left, Address(SP, 1 * kWordSize));
  __ lw(right, Address(SP, 0 * kWordSize));
  GenerateIdenticalWithNumberCheckStub(assembler, left, right, temp1, temp2);
  __ Ret();

  // Call single step callback in debugger.
  if (FLAG_support_debugger) {
    __ Bind(&stepping);
    __ EnterStubFrame();
    __ addiu(SP, SP, Immediate(-1 * kWordSize));
    __ sw(RA, Address(SP, 0 * kWordSize));  // Return address.
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ lw(RA, Address(SP, 0 * kWordSize));
    __ addiu(SP, SP, Immediate(1 * kWordSize));
    __ RestoreCodePointer();
    __ LeaveStubFrame();
    __ b(&done_stepping);
  }
}


// Called from optimized code only.
// SP + 4: left operand.
// SP + 0: right operand.
// Returns: CMPRES1 is zero if equal, non-zero otherwise.
void StubCode::GenerateOptimizedIdenticalWithNumberCheckStub(
    Assembler* assembler) {
  const Register temp1 = T2;
  const Register temp2 = T3;
  const Register left = T1;
  const Register right = T0;
  __ lw(left, Address(SP, 1 * kWordSize));
  __ lw(right, Address(SP, 0 * kWordSize));
  GenerateIdenticalWithNumberCheckStub(assembler, left, right, temp1, temp2);
  __ Ret();
}


// Called from megamorphic calls.
//  T0: receiver
//  S5: MegamorphicCache (preserved)
// Passed to target:
//  CODE_REG: target Code object
//  S4: arguments descriptor
void StubCode::GenerateMegamorphicCallStub(Assembler* assembler) {
  __ LoadTaggedClassIdMayBeSmi(T0, T0);
  // T0: class ID of the receiver (smi).
  __ lw(S4, FieldAddress(S5, MegamorphicCache::arguments_descriptor_offset()));
  __ lw(T2, FieldAddress(S5, MegamorphicCache::buckets_offset()));
  __ lw(T1, FieldAddress(S5, MegamorphicCache::mask_offset()));
  // T2: cache buckets array.
  // T1: mask.
  __ LoadImmediate(TMP, MegamorphicCache::kSpreadFactor);
  __ mult(TMP, T0);
  __ mflo(T3);
  // T3: probe.

  Label loop, update, call_target_function;
  __ b(&loop);

  __ Bind(&update);
  __ addiu(T3, T3, Immediate(Smi::RawValue(1)));
  __ Bind(&loop);
  __ and_(T3, T3, T1);
  const intptr_t base = Array::data_offset();
  // T3 is smi tagged, but table entries are two words, so LSL 2.
  __ sll(TMP, T3, 2);
  __ addu(TMP, T2, TMP);
  __ lw(T4, FieldAddress(TMP, base));

  ASSERT(kIllegalCid == 0);
  __ beq(T4, ZR, &call_target_function);
  __ bne(T4, T0, &update);

  __ Bind(&call_target_function);
  // Call the target found in the cache.  For a class id match, this is a
  // proper target for the given name and arguments descriptor.  If the
  // illegal class id was found, the target is a cache miss handler that can
  // be invoked as a normal Dart function.
  __ sll(T1, T3, 2);
  __ addu(T1, T2, T1);
  __ lw(T0, FieldAddress(T1, base + kWordSize));

  __ lw(T1, FieldAddress(T0, Function::entry_point_offset()));
  __ lw(CODE_REG, FieldAddress(T0, Function::code_offset()));
  __ jr(T1);
}


// Called from switchable IC calls.
//  T0: receiver
//  S5: ICData (preserved)
// Passed to target:
//  CODE_REG: target Code object
//  S4: arguments descriptor
void StubCode::GenerateICCallThroughFunctionStub(Assembler* assembler) {
  Label loop, found, miss;
  __ lw(T6, FieldAddress(S5, ICData::ic_data_offset()));
  __ lw(S4, FieldAddress(S5, ICData::arguments_descriptor_offset()));
  __ AddImmediate(T6, T6, Array::data_offset() - kHeapObjectTag);
  // T6: first IC entry.
  __ LoadTaggedClassIdMayBeSmi(T1, T0);
  // T1: receiver cid as Smi

  __ Bind(&loop);
  __ lw(T2, Address(T6, 0));
  __ beq(T1, T2, &found);
  ASSERT(Smi::RawValue(kIllegalCid) == 0);
  __ beq(T2, ZR, &miss);

  const intptr_t entry_length = ICData::TestEntryLengthFor(1) * kWordSize;
  __ AddImmediate(T6, entry_length);  // Next entry.
  __ b(&loop);

  __ Bind(&found);
  const intptr_t target_offset = ICData::TargetIndexFor(1) * kWordSize;
  __ lw(T0, Address(T6, target_offset));
  __ lw(T1, FieldAddress(T0, Function::entry_point_offset()));
  __ lw(CODE_REG, FieldAddress(T0, Function::code_offset()));
  __ jr(T1);

  __ Bind(&miss);
  __ LoadIsolate(T2);
  __ lw(CODE_REG, Address(T2, Isolate::ic_miss_code_offset()));
  __ lw(T1, FieldAddress(CODE_REG, Code::entry_point_offset()));
  __ jr(T1);
}


void StubCode::GenerateICCallThroughCodeStub(Assembler* assembler) {
  Label loop, found, miss;
  __ lw(T6, FieldAddress(S5, ICData::ic_data_offset()));
  __ lw(S4, FieldAddress(S5, ICData::arguments_descriptor_offset()));
  __ AddImmediate(T6, T6, Array::data_offset() - kHeapObjectTag);
  // T6: first IC entry.
  __ LoadTaggedClassIdMayBeSmi(T1, T0);
  // T1: receiver cid as Smi

  __ Bind(&loop);
  __ lw(T2, Address(T6, 0));
  __ beq(T1, T2, &found);
  ASSERT(Smi::RawValue(kIllegalCid) == 0);
  __ beq(T2, ZR, &miss);

  const intptr_t entry_length = ICData::TestEntryLengthFor(1) * kWordSize;
  __ AddImmediate(T6, entry_length);  // Next entry.
  __ b(&loop);

  __ Bind(&found);
  const intptr_t code_offset = ICData::CodeIndexFor(1) * kWordSize;
  const intptr_t entry_offset = ICData::EntryPointIndexFor(1) * kWordSize;
  __ lw(T1, Address(T6, entry_offset));
  __ lw(CODE_REG, Address(T6, code_offset));
  __ jr(T1);

  __ Bind(&miss);
  __ LoadIsolate(T2);
  __ lw(CODE_REG, Address(T2, Isolate::ic_miss_code_offset()));
  __ lw(T1, FieldAddress(CODE_REG, Code::entry_point_offset()));
  __ jr(T1);
}


// Called from switchable IC calls.
//  T0: receiver
//  S5: SingleTargetCache
void StubCode::GenerateUnlinkedCallStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ Push(T0);  // Preserve receiver.

  __ Push(ZR);  // Result slot.
  __ Push(T0);  // Arg0: Receiver
  __ Push(S5);  // Arg1: UnlinkedCall
  __ CallRuntime(kUnlinkedCallRuntimeEntry, 2);
  __ Drop(2);
  __ Pop(S5);  // result = IC

  __ Pop(T0);  // Restore receiver.
  __ LeaveStubFrame();

  __ lw(CODE_REG, Address(THR, Thread::ic_lookup_through_code_stub_offset()));
  __ lw(T1, FieldAddress(CODE_REG, Code::checked_entry_point_offset()));
  __ jr(T1);
}


// Called from switchable IC calls.
//  T0: receiver
//  S5: SingleTargetCache
// Passed to target:
//  CODE_REG: target Code object
void StubCode::GenerateSingleTargetCallStub(Assembler* assembler) {
  Label miss;
  __ LoadClassIdMayBeSmi(T1, T0);
  __ lhu(T2, FieldAddress(S5, SingleTargetCache::lower_limit_offset()));
  __ lhu(T3, FieldAddress(S5, SingleTargetCache::upper_limit_offset()));

  __ BranchUnsignedLess(T1, T2, &miss);
  __ BranchUnsignedGreater(T1, T3, &miss);

  __ lw(T1, FieldAddress(S5, SingleTargetCache::entry_point_offset()));
  __ lw(CODE_REG, FieldAddress(S5, SingleTargetCache::target_offset()));
  __ jr(T1);

  __ Bind(&miss);
  __ EnterStubFrame();
  __ Push(T0);  // Preserve receiver.

  __ Push(ZR);  // Result slot.
  __ Push(T0);  // Arg0: Receiver
  __ CallRuntime(kSingleTargetMissRuntimeEntry, 1);
  __ Drop(1);
  __ Pop(S5);  // result = IC

  __ Pop(T0);  // Restore receiver.
  __ LeaveStubFrame();

  __ lw(CODE_REG, Address(THR, Thread::ic_lookup_through_code_stub_offset()));
  __ lw(T1, FieldAddress(CODE_REG, Code::checked_entry_point_offset()));
  __ jr(T1);
}


// Called from the monomorphic checked entry.
//  T0: receiver
void StubCode::GenerateMonomorphicMissStub(Assembler* assembler) {
  __ lw(CODE_REG, Address(THR, Thread::monomorphic_miss_stub_offset()));
  __ EnterStubFrame();
  __ Push(T0);  // Preserve receiver.

  __ Push(ZR);  // Result slot.
  __ Push(T0);  // Arg0: Receiver
  __ CallRuntime(kMonomorphicMissRuntimeEntry, 1);
  __ Drop(1);
  __ Pop(S5);  // result = IC

  __ Pop(T0);  // Restore receiver.
  __ LeaveStubFrame();

  __ lw(CODE_REG, Address(THR, Thread::ic_lookup_through_code_stub_offset()));
  __ lw(T1, FieldAddress(CODE_REG, Code::checked_entry_point_offset()));
  __ jr(T1);
}


void StubCode::GenerateFrameAwaitingMaterializationStub(Assembler* assembler) {
  __ break_(0);
}


void StubCode::GenerateAsynchronousGapMarkerStub(Assembler* assembler) {
  __ break_(0);
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
