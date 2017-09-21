// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64) && !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_entry.h"
#include "vm/heap.h"
#include "vm/instructions.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/scavenger.h"
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
//   RSP : points to return address.
//   RSP + 8 : address of last argument in argument array.
//   RSP + 8*R10 : address of first argument in argument array.
//   RSP + 8*R10 + 8 : address of return value.
//   RBX : address of the runtime function to call.
//   R10 : number of arguments to the call.
// Must preserve callee saved registers R12 and R13.
void StubCode::GenerateCallToRuntimeStub(Assembler* assembler) {
  const intptr_t thread_offset = NativeArguments::thread_offset();
  const intptr_t argc_tag_offset = NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = NativeArguments::argv_offset();
  const intptr_t retval_offset = NativeArguments::retval_offset();

  __ EnterStubFrame();

  // Save exit frame information to enable stack walking as we are about
  // to transition to Dart VM C++ code.
  __ movq(Address(THR, Thread::top_exit_frame_info_offset()), RBP);

#if defined(DEBUG)
  {
    Label ok;
    // Check that we are always entering from Dart code.
    __ movq(RAX, Immediate(VMTag::kDartTagId));
    __ cmpq(RAX, Assembler::VMTagAddress());
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the thread is executing VM code.
  __ movq(Assembler::VMTagAddress(), RBX);

  // Reserve space for arguments and align frame before entering C++ world.
  __ subq(RSP, Immediate(sizeof(NativeArguments)));
  if (OS::ActivationFrameAlignment() > 1) {
    __ andq(RSP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass NativeArguments structure by value and call runtime.
  __ movq(Address(RSP, thread_offset), THR);  // Set thread in NativeArgs.
  // There are no runtime calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  __ movq(Address(RSP, argc_tag_offset), R10);  // Set argc in NativeArguments.
  // Compute argv.
  __ leaq(RAX, Address(RBP, R10, TIMES_8, kParamEndSlotFromFp * kWordSize));
  __ movq(Address(RSP, argv_offset), RAX);    // Set argv in NativeArguments.
  __ addq(RAX, Immediate(1 * kWordSize));     // Retval is next to 1st argument.
  __ movq(Address(RSP, retval_offset), RAX);  // Set retval in NativeArguments.
#if defined(_WIN64)
  ASSERT(sizeof(NativeArguments) > CallingConventions::kRegisterTransferLimit);
  __ movq(CallingConventions::kArg1Reg, RSP);
#endif
  __ CallCFunction(RBX);

  // Mark that the thread is executing Dart code.
  __ movq(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));

  // Reset exit frame information in Isolate structure.
  __ movq(Address(THR, Thread::top_exit_frame_info_offset()), Immediate(0));

  __ LeaveStubFrame();
  __ ret();
}

// Input parameters:
//   RSP : points to return address.
//   RDI : stop message (const char*).
// Must preserve all registers.
void StubCode::GeneratePrintStopMessageStub(Assembler* assembler) {
  __ EnterCallRuntimeFrame(0);
// Call the runtime leaf function. RDI already contains the parameter.
#if defined(_WIN64)
  __ movq(CallingConventions::kArg1Reg, RDI);
#endif
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
static void GenerateCallNativeWithWrapperStub(Assembler* assembler,
                                              Address wrapper_address) {
  const intptr_t native_args_struct_offset = 0;
  const intptr_t thread_offset =
      NativeArguments::thread_offset() + native_args_struct_offset;
  const intptr_t argc_tag_offset =
      NativeArguments::argc_tag_offset() + native_args_struct_offset;
  const intptr_t argv_offset =
      NativeArguments::argv_offset() + native_args_struct_offset;
  const intptr_t retval_offset =
      NativeArguments::retval_offset() + native_args_struct_offset;

  __ EnterStubFrame();

  // Save exit frame information to enable stack walking as we are about
  // to transition to native code.
  __ movq(Address(THR, Thread::top_exit_frame_info_offset()), RBP);

#if defined(DEBUG)
  {
    Label ok;
    // Check that we are always entering from Dart code.
    __ movq(R8, Immediate(VMTag::kDartTagId));
    __ cmpq(R8, Assembler::VMTagAddress());
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the thread is executing native code.
  __ movq(Assembler::VMTagAddress(), RBX);

  // Reserve space for the native arguments structure passed on the stack (the
  // outgoing pointer parameter to the native arguments structure is passed in
  // RDI) and align frame before entering the C++ world.
  __ subq(RSP, Immediate(sizeof(NativeArguments)));
  if (OS::ActivationFrameAlignment() > 1) {
    __ andq(RSP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass NativeArguments structure by value and call native function.
  __ movq(Address(RSP, thread_offset), THR);    // Set thread in NativeArgs.
  __ movq(Address(RSP, argc_tag_offset), R10);  // Set argc in NativeArguments.
  __ movq(Address(RSP, argv_offset), RAX);      // Set argv in NativeArguments.
  __ leaq(RAX, Address(RBP, 2 * kWordSize));    // Compute return value addr.
  __ movq(Address(RSP, retval_offset), RAX);  // Set retval in NativeArguments.

  // Pass the pointer to the NativeArguments.
  __ movq(CallingConventions::kArg1Reg, RSP);
  // Pass pointer to function entrypoint.
  __ movq(CallingConventions::kArg2Reg, RBX);

  __ movq(RAX, wrapper_address);
  __ CallCFunction(RAX);

  // Mark that the thread is executing Dart code.
  __ movq(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));

  // Reset exit frame information in Isolate structure.
  __ movq(Address(THR, Thread::top_exit_frame_info_offset()), Immediate(0));

  __ LeaveStubFrame();
  __ ret();
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
//   RSP : points to return address.
//   RSP + 8 : address of return value.
//   RAX : address of first argument in argument array.
//   RBX : address of the native function to call.
//   R10 : argc_tag including number of arguments and function kind.
void StubCode::GenerateCallBootstrapNativeStub(Assembler* assembler) {
  const intptr_t native_args_struct_offset = 0;
  const intptr_t thread_offset =
      NativeArguments::thread_offset() + native_args_struct_offset;
  const intptr_t argc_tag_offset =
      NativeArguments::argc_tag_offset() + native_args_struct_offset;
  const intptr_t argv_offset =
      NativeArguments::argv_offset() + native_args_struct_offset;
  const intptr_t retval_offset =
      NativeArguments::retval_offset() + native_args_struct_offset;

  __ EnterStubFrame();

  // Save exit frame information to enable stack walking as we are about
  // to transition to native code.
  __ movq(Address(THR, Thread::top_exit_frame_info_offset()), RBP);

#if defined(DEBUG)
  {
    Label ok;
    // Check that we are always entering from Dart code.
    __ movq(R8, Immediate(VMTag::kDartTagId));
    __ cmpq(R8, Assembler::VMTagAddress());
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the thread is executing native code.
  __ movq(Assembler::VMTagAddress(), RBX);

  // Reserve space for the native arguments structure passed on the stack (the
  // outgoing pointer parameter to the native arguments structure is passed in
  // RDI) and align frame before entering the C++ world.
  __ subq(RSP, Immediate(sizeof(NativeArguments)));
  if (OS::ActivationFrameAlignment() > 1) {
    __ andq(RSP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass NativeArguments structure by value and call native function.
  __ movq(Address(RSP, thread_offset), THR);    // Set thread in NativeArgs.
  __ movq(Address(RSP, argc_tag_offset), R10);  // Set argc in NativeArguments.
  __ movq(Address(RSP, argv_offset), RAX);      // Set argv in NativeArguments.
  __ leaq(RAX, Address(RBP, 2 * kWordSize));    // Compute return value addr.
  __ movq(Address(RSP, retval_offset), RAX);  // Set retval in NativeArguments.

  // Pass the pointer to the NativeArguments.
  __ movq(CallingConventions::kArg1Reg, RSP);
  __ CallCFunction(RBX);

  // Mark that the thread is executing Dart code.
  __ movq(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));

  // Reset exit frame information in Isolate structure.
  __ movq(Address(THR, Thread::top_exit_frame_info_offset()), Immediate(0));

  __ LeaveStubFrame();
  __ ret();
}

// Input parameters:
//   R10: arguments descriptor array.
void StubCode::GenerateCallStaticFunctionStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ pushq(R10);  // Preserve arguments descriptor array.
  // Setup space on stack for return value.
  __ pushq(Immediate(0));
  __ CallRuntime(kPatchStaticCallRuntimeEntry, 0);
  __ popq(CODE_REG);  // Get Code object result.
  __ popq(R10);       // Restore arguments descriptor array.
  // Remove the stub frame as we are about to jump to the dart function.
  __ LeaveStubFrame();

  __ movq(RBX, FieldAddress(CODE_REG, Code::entry_point_offset()));
  __ jmp(RBX);
}

// Called from a static call only when an invalid code has been entered
// (invalid because its function was optimized or deoptimized).
// R10: arguments descriptor array.
void StubCode::GenerateFixCallersTargetStub(Assembler* assembler) {
  // Load code pointer to this stub from the thread:
  // The one that is passed in, is not correct - it points to the code object
  // that needs to be replaced.
  __ movq(CODE_REG, Address(THR, Thread::fix_callers_target_code_offset()));
  __ EnterStubFrame();
  __ pushq(R10);  // Preserve arguments descriptor array.
  // Setup space on stack for return value.
  __ pushq(Immediate(0));
  __ CallRuntime(kFixCallersTargetRuntimeEntry, 0);
  __ popq(CODE_REG);  // Get Code object.
  __ popq(R10);       // Restore arguments descriptor array.
  __ movq(RAX, FieldAddress(CODE_REG, Code::entry_point_offset()));
  __ LeaveStubFrame();
  __ jmp(RAX);
  __ int3();
}

// Called from object allocate instruction when the allocation stub has been
// disabled.
void StubCode::GenerateFixAllocationStubTargetStub(Assembler* assembler) {
  // Load code pointer to this stub from the thread:
  // The one that is passed in, is not correct - it points to the code object
  // that needs to be replaced.
  __ movq(CODE_REG, Address(THR, Thread::fix_allocation_stub_code_offset()));
  __ EnterStubFrame();
  // Setup space on stack for return value.
  __ pushq(Immediate(0));
  __ CallRuntime(kFixAllocationStubTargetRuntimeEntry, 0);
  __ popq(CODE_REG);  // Get Code object.
  __ movq(RAX, FieldAddress(CODE_REG, Code::entry_point_offset()));
  __ LeaveStubFrame();
  __ jmp(RAX);
  __ int3();
}

// Input parameters:
//   R10: smi-tagged argument count, may be zero.
//   RBP[kParamEndSlotFromFp + 1]: last argument.
static void PushArgumentsArray(Assembler* assembler) {
  __ LoadObject(R12, Object::null_object());
  // Allocate array to store arguments of caller.
  __ movq(RBX, R12);  // Null element type for raw Array.
  __ Call(*StubCode::AllocateArray_entry());
  __ SmiUntag(R10);
  // RAX: newly allocated array.
  // R10: length of the array (was preserved by the stub).
  __ pushq(RAX);  // Array is in RAX and on top of stack.
  __ leaq(R12, Address(RBP, R10, TIMES_8, kParamEndSlotFromFp * kWordSize));
  __ leaq(RBX, FieldAddress(RAX, Array::data_offset()));
  // R12: address of first argument on stack.
  // RBX: address of first argument in array.
  Label loop, loop_condition;
#if defined(DEBUG)
  static const bool kJumpLength = Assembler::kFarJump;
#else
  static const bool kJumpLength = Assembler::kNearJump;
#endif  // DEBUG
  __ jmp(&loop_condition, kJumpLength);
  __ Bind(&loop);
  __ movq(RDI, Address(R12, 0));
  // Generational barrier is needed, array is not necessarily in new space.
  __ StoreIntoObject(RAX, Address(RBX, 0), RDI);
  __ addq(RBX, Immediate(kWordSize));
  __ subq(R12, Immediate(kWordSize));
  __ Bind(&loop_condition);
  __ decq(R10);
  __ j(POSITIVE, &loop, Assembler::kNearJump);
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
      kFirstLocalSlotFromFp + 1 - (kNumberOfCpuRegisters - RAX);
  const intptr_t saved_exception_slot_from_fp =
      kFirstLocalSlotFromFp + 1 - (kNumberOfCpuRegisters - RAX);
  const intptr_t saved_stacktrace_slot_from_fp =
      kFirstLocalSlotFromFp + 1 - (kNumberOfCpuRegisters - RDX);
  // Result in RAX is preserved as part of pushing all registers below.

  // Push registers in their enumeration order: lowest register number at
  // lowest address.
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; i--) {
    if (i == CODE_REG) {
      // Save the original value of CODE_REG pushed before invoking this stub
      // instead of the value used to call this stub.
      __ pushq(Address(RBP, 2 * kWordSize));
    } else {
      __ pushq(static_cast<Register>(i));
    }
  }
  __ subq(RSP, Immediate(kNumberOfXmmRegisters * kFpuRegisterSize));
  intptr_t offset = 0;
  for (intptr_t reg_idx = 0; reg_idx < kNumberOfXmmRegisters; ++reg_idx) {
    XmmRegister xmm_reg = static_cast<XmmRegister>(reg_idx);
    __ movups(Address(RSP, offset), xmm_reg);
    offset += kFpuRegisterSize;
  }

  // Pass address of saved registers block.
  __ movq(CallingConventions::kArg1Reg, RSP);
  bool is_lazy =
      (kind == kLazyDeoptFromReturn) || (kind == kLazyDeoptFromThrow);
  __ movq(CallingConventions::kArg2Reg, Immediate(is_lazy ? 1 : 0));
  __ ReserveAlignedFrameSpace(0);  // Ensure stack is aligned before the call.
  __ CallRuntime(kDeoptimizeCopyFrameRuntimeEntry, 2);
  // Result (RAX) is stack-size (FP - SP) in bytes.

  if (kind == kLazyDeoptFromReturn) {
    // Restore result into RBX temporarily.
    __ movq(RBX, Address(RBP, saved_result_slot_from_fp * kWordSize));
  } else if (kind == kLazyDeoptFromThrow) {
    // Restore result into RBX temporarily.
    __ movq(RBX, Address(RBP, saved_exception_slot_from_fp * kWordSize));
    __ movq(RDX, Address(RBP, saved_stacktrace_slot_from_fp * kWordSize));
  }

  // There is a Dart Frame on the stack. We must restore PP and leave frame.
  __ RestoreCodePointer();
  __ LeaveStubFrame();

  __ popq(RCX);       // Preserve return address.
  __ movq(RSP, RBP);  // Discard optimized frame.
  __ subq(RSP, RAX);  // Reserve space for deoptimized frame.
  __ pushq(RCX);      // Restore return address.

  // DeoptimizeFillFrame expects a Dart frame, i.e. EnterDartFrame(0), but there
  // is no need to set the correct PC marker or load PP, since they get patched.
  __ EnterStubFrame();

  if (kind == kLazyDeoptFromReturn) {
    __ pushq(RBX);  // Preserve result as first local.
  } else if (kind == kLazyDeoptFromThrow) {
    __ pushq(RBX);  // Preserve exception as first local.
    __ pushq(RDX);  // Preserve stacktrace as second local.
  }
  __ ReserveAlignedFrameSpace(0);
  // Pass last FP as a parameter.
  __ movq(CallingConventions::kArg1Reg, RBP);
  __ CallRuntime(kDeoptimizeFillFrameRuntimeEntry, 1);
  if (kind == kLazyDeoptFromReturn) {
    // Restore result into RBX.
    __ movq(RBX, Address(RBP, kFirstLocalSlotFromFp * kWordSize));
  } else if (kind == kLazyDeoptFromThrow) {
    // Restore exception into RBX.
    __ movq(RBX, Address(RBP, kFirstLocalSlotFromFp * kWordSize));
    // Restore stacktrace into RDX.
    __ movq(RDX, Address(RBP, (kFirstLocalSlotFromFp - 1) * kWordSize));
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
    __ pushq(RBX);  // Preserve result, it will be GC-d here.
  } else if (kind == kLazyDeoptFromThrow) {
    __ pushq(RBX);  // Preserve exception.
    __ pushq(RDX);  // Preserve stacktrace.
  }
  __ pushq(Immediate(Smi::RawValue(0)));  // Space for the result.
  __ CallRuntime(kDeoptimizeMaterializeRuntimeEntry, 0);
  // Result tells stub how many bytes to remove from the expression stack
  // of the bottom-most frame. They were used as materialization arguments.
  __ popq(RBX);
  __ SmiUntag(RBX);
  if (kind == kLazyDeoptFromReturn) {
    __ popq(RAX);  // Restore result.
  } else if (kind == kLazyDeoptFromThrow) {
    __ popq(RDX);  // Restore stacktrace.
    __ popq(RAX);  // Restore exception.
  }
  __ LeaveStubFrame();

  __ popq(RCX);       // Pop return address.
  __ addq(RSP, RBX);  // Remove materialization arguments.
  __ pushq(RCX);      // Push return address.
  // The caller is responsible for emitting the return instruction.
}

// RAX: result, must be preserved
void StubCode::GenerateDeoptimizeLazyFromReturnStub(Assembler* assembler) {
  // Push zap value instead of CODE_REG for lazy deopt.
  __ pushq(Immediate(kZapCodeReg));
  // Return address for "call" to deopt stub.
  __ pushq(Immediate(kZapReturnAddress));
  __ movq(CODE_REG, Address(THR, Thread::lazy_deopt_from_return_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kLazyDeoptFromReturn);
  __ ret();
}

// RAX: exception, must be preserved
// RDX: stacktrace, must be preserved
void StubCode::GenerateDeoptimizeLazyFromThrowStub(Assembler* assembler) {
  // Push zap value instead of CODE_REG for lazy deopt.
  __ pushq(Immediate(kZapCodeReg));
  // Return address for "call" to deopt stub.
  __ pushq(Immediate(kZapReturnAddress));
  __ movq(CODE_REG, Address(THR, Thread::lazy_deopt_from_throw_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kLazyDeoptFromThrow);
  __ ret();
}

void StubCode::GenerateDeoptimizeStub(Assembler* assembler) {
  GenerateDeoptimizationSequence(assembler, kEagerDeopt);
  __ ret();
}

static void GenerateDispatcherCode(Assembler* assembler,
                                   Label* call_target_function) {
  __ Comment("NoSuchMethodDispatch");
  // When lazily generated invocation dispatchers are disabled, the
  // miss-handler may return null.
  __ CompareObject(RAX, Object::null_object());
  __ j(NOT_EQUAL, call_target_function);
  __ EnterStubFrame();
  // Load the receiver.
  __ movq(RDI, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
  __ movq(RAX, Address(RBP, RDI, TIMES_HALF_WORD_SIZE,
                       kParamEndSlotFromFp * kWordSize));
  __ pushq(Immediate(0));  // Setup space on stack for result.
  __ pushq(RAX);           // Receiver.
  __ pushq(RBX);           // ICData/MegamorphicCache.
  __ pushq(R10);           // Arguments descriptor array.

  // Adjust arguments count.
  __ cmpq(FieldAddress(R10, ArgumentsDescriptor::type_args_len_offset()),
          Immediate(0));
  __ movq(R10, RDI);
  Label args_count_ok;
  __ j(EQUAL, &args_count_ok, Assembler::kNearJump);
  __ addq(R10, Immediate(Smi::RawValue(1)));  // Include the type arguments.
  __ Bind(&args_count_ok);

  // R10: Smi-tagged arguments array length.
  PushArgumentsArray(assembler);
  const intptr_t kNumArgs = 4;
  __ CallRuntime(kInvokeNoSuchMethodDispatcherRuntimeEntry, kNumArgs);
  __ Drop(4);
  __ popq(RAX);  // Return value.
  __ LeaveStubFrame();
  __ ret();
}

void StubCode::GenerateMegamorphicMissStub(Assembler* assembler) {
  __ EnterStubFrame();
  // Load the receiver into RAX.  The argument count in the arguments
  // descriptor in R10 is a smi.
  __ movq(RAX, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
  // Three words (saved pp, saved fp, stub's pc marker)
  // in the stack above the return address.
  __ movq(RAX,
          Address(RSP, RAX, TIMES_4, kSavedAboveReturnAddress * kWordSize));
  // Preserve IC data and arguments descriptor.
  __ pushq(RBX);
  __ pushq(R10);

  // Space for the result of the runtime call.
  __ pushq(Immediate(0));
  __ pushq(RAX);  // Receiver.
  __ pushq(RBX);  // IC data.
  __ pushq(R10);  // Arguments descriptor.
  __ CallRuntime(kMegamorphicCacheMissHandlerRuntimeEntry, 3);
  // Discard arguments.
  __ popq(RAX);
  __ popq(RAX);
  __ popq(RAX);
  __ popq(RAX);  // Return value from the runtime call (function).
  __ popq(R10);  // Restore arguments descriptor.
  __ popq(RBX);  // Restore IC data.
  __ RestoreCodePointer();
  __ LeaveStubFrame();
  if (!FLAG_lazy_dispatchers) {
    Label call_target_function;
    GenerateDispatcherCode(assembler, &call_target_function);
    __ Bind(&call_target_function);
  }
  __ movq(CODE_REG, FieldAddress(RAX, Function::code_offset()));
  __ movq(RCX, FieldAddress(RAX, Function::entry_point_offset()));
  __ jmp(RCX);
}

// Called for inline allocation of arrays.
// Input parameters:
//   R10 : Array length as Smi.
//   RBX : array element type (either NULL or an instantiated type).
// NOTE: R10 cannot be clobbered here as the caller relies on it being saved.
// The newly allocated object is returned in RAX.
void StubCode::GenerateAllocateArrayStub(Assembler* assembler) {
  Label slow_case;
  // Compute the size to be allocated, it is based on the array length
  // and is computed as:
  // RoundedAllocationSize((array_length * kwordSize) + sizeof(RawArray)).
  __ movq(RDI, R10);  // Array Length.
  // Check that length is a positive Smi.
  __ testq(RDI, Immediate(kSmiTagMask));
  if (FLAG_use_slow_path) {
    __ jmp(&slow_case);
  } else {
    __ j(NOT_ZERO, &slow_case);
  }
  __ cmpq(RDI, Immediate(0));
  __ j(LESS, &slow_case);
  // Check for maximum allowed length.
  const Immediate& max_len = Immediate(
      reinterpret_cast<int64_t>(Smi::New(Array::kMaxNewSpaceElements)));
  __ cmpq(RDI, max_len);
  __ j(GREATER, &slow_case);

  // Check for allocation tracing.
  NOT_IN_PRODUCT(
      __ MaybeTraceAllocation(kArrayCid, &slow_case, Assembler::kFarJump));

  const intptr_t fixed_size_plus_alignment_padding =
      sizeof(RawArray) + kObjectAlignment - 1;
  // RDI is a Smi.
  __ leaq(RDI, Address(RDI, TIMES_4, fixed_size_plus_alignment_padding));
  ASSERT(kSmiTagShift == 1);
  __ andq(RDI, Immediate(-kObjectAlignment));

  const intptr_t cid = kArrayCid;
  NOT_IN_PRODUCT(Heap::Space space = Heap::kNew);
  __ movq(RAX, Address(THR, Thread::top_offset()));

  // RDI: allocation size.
  __ movq(RCX, RAX);
  __ addq(RCX, RDI);
  __ j(CARRY, &slow_case);

  // Check if the allocation fits into the remaining space.
  // RAX: potential new object start.
  // RCX: potential next object start.
  // RDI: allocation size.
  __ cmpq(RCX, Address(THR, Thread::end_offset()));
  __ j(ABOVE_EQUAL, &slow_case);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  __ movq(Address(THR, Thread::top_offset()), RCX);
  __ addq(RAX, Immediate(kHeapObjectTag));
  NOT_IN_PRODUCT(__ UpdateAllocationStatsWithSize(cid, RDI, space));
  // Initialize the tags.
  // RAX: new object start as a tagged pointer.
  // RDI: allocation size.
  {
    Label size_tag_overflow, done;
    __ cmpq(RDI, Immediate(RawObject::SizeTag::kMaxSizeTag));
    __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
    __ shlq(RDI, Immediate(RawObject::kSizeTagPos - kObjectAlignmentLog2));
    __ jmp(&done, Assembler::kNearJump);

    __ Bind(&size_tag_overflow);
    __ movq(RDI, Immediate(0));
    __ Bind(&done);

    // Get the class index and insert it into the tags.
    __ orq(RDI, Immediate(RawObject::ClassIdTag::encode(cid)));
    __ movq(FieldAddress(RAX, Array::tags_offset()), RDI);  // Tags.
  }

  // RAX: new object start as a tagged pointer.
  // Store the type argument field.
  // No generational barrier needed, since we store into a new object.
  __ StoreIntoObjectNoBarrier(
      RAX, FieldAddress(RAX, Array::type_arguments_offset()), RBX);

  // Set the length field.
  __ StoreIntoObjectNoBarrier(RAX, FieldAddress(RAX, Array::length_offset()),
                              R10);

  // Initialize all array elements to raw_null.
  // RAX: new object start as a tagged pointer.
  // RCX: new object end address.
  // RDI: iterator which initially points to the start of the variable
  // data area to be initialized.
  __ LoadObject(R12, Object::null_object());
  __ leaq(RDI, FieldAddress(RAX, sizeof(RawArray)));
  Label done;
  Label init_loop;
  __ Bind(&init_loop);
  __ cmpq(RDI, RCX);
#if defined(DEBUG)
  static const bool kJumpLength = Assembler::kFarJump;
#else
  static const bool kJumpLength = Assembler::kNearJump;
#endif  // DEBUG
  __ j(ABOVE_EQUAL, &done, kJumpLength);
  // No generational barrier needed, since we are storing null.
  __ StoreIntoObjectNoBarrier(RAX, Address(RDI, 0), R12);
  __ addq(RDI, Immediate(kWordSize));
  __ jmp(&init_loop, kJumpLength);
  __ Bind(&done);
  __ ret();  // returns the newly allocated object in RAX.

  // Unable to allocate the array using the fast inline code, just call
  // into the runtime.
  __ Bind(&slow_case);
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value.
  __ pushq(Immediate(0));
  __ pushq(R10);  // Array length as Smi.
  __ pushq(RBX);  // Element type.
  __ CallRuntime(kAllocateArrayRuntimeEntry, 2);
  __ popq(RAX);  // Pop element type argument.
  __ popq(R10);  // Pop array length argument.
  __ popq(RAX);  // Pop return value from return slot.
  __ LeaveStubFrame();
  __ ret();
}

// Called when invoking Dart code from C++ (VM code).
// Input parameters:
//   RSP : points to return address.
//   RDI : target code
//   RSI : arguments descriptor array.
//   RDX : arguments array.
//   RCX : current thread.
void StubCode::GenerateInvokeDartCodeStub(Assembler* assembler) {
  // Save frame pointer coming in.
  __ EnterFrame(0);

  const Register kTargetCodeReg = CallingConventions::kArg1Reg;
  const Register kArgDescReg = CallingConventions::kArg2Reg;
  const Register kArgsReg = CallingConventions::kArg3Reg;
  const Register kThreadReg = CallingConventions::kArg4Reg;

  // Push code object to PC marker slot.
  __ pushq(Address(kThreadReg, Thread::invoke_dart_code_stub_offset()));

  // At this point, the stack looks like:
  // | stub code object
  // | saved RBP                                      | <-- RBP
  // | saved PC (return to DartEntry::InvokeFunction) |

  const intptr_t kInitialOffset = 2;
  // Save arguments descriptor array.
  const intptr_t kArgumentsDescOffset = -(kInitialOffset)*kWordSize;
  __ pushq(kArgDescReg);

  // Save C++ ABI callee-saved registers.
  __ PushRegisters(CallingConventions::kCalleeSaveCpuRegisters,
                   CallingConventions::kCalleeSaveXmmRegisters);

  // If any additional (or fewer) values are pushed, the offsets in
  // kExitLinkSlotFromEntryFp will need to be changed.

  // Set up THR, which caches the current thread in Dart code.
  if (THR != kThreadReg) {
    __ movq(THR, kThreadReg);
  }

  // Save the current VMTag on the stack.
  __ movq(RAX, Assembler::VMTagAddress());
  __ pushq(RAX);

  // Mark that the thread is executing Dart code.
  __ movq(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));

  // Save top resource and top exit frame info. Use RAX as a temporary register.
  // StackFrameIterator reads the top exit frame info saved in this frame.
  __ movq(RAX, Address(THR, Thread::top_resource_offset()));
  __ pushq(RAX);
  __ movq(Address(THR, Thread::top_resource_offset()), Immediate(0));
  __ movq(RAX, Address(THR, Thread::top_exit_frame_info_offset()));
  // The constant kExitLinkSlotFromEntryFp must be kept in sync with the
  // code below.
  __ pushq(RAX);
#if defined(DEBUG)
  {
    Label ok;
    __ leaq(RAX, Address(RBP, kExitLinkSlotFromEntryFp * kWordSize));
    __ cmpq(RAX, RSP);
    __ j(EQUAL, &ok);
    __ Stop("kExitLinkSlotFromEntryFp mismatch");
    __ Bind(&ok);
  }
#endif

  __ movq(Address(THR, Thread::top_exit_frame_info_offset()), Immediate(0));

  // Load arguments descriptor array into R10, which is passed to Dart code.
  __ movq(R10, Address(kArgDescReg, VMHandles::kOffsetOfRawPtrInHandle));

  // Push arguments. At this point we only need to preserve kTargetCodeReg.
  ASSERT(kTargetCodeReg != RDX);

  // No need to check for type args, disallowed by DartEntry::InvokeFunction.
  // Load number of arguments into RBX.
  __ movq(RBX, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
  __ SmiUntag(RBX);

  // Compute address of 'arguments array' data area into RDX.
  __ movq(RDX, Address(kArgsReg, VMHandles::kOffsetOfRawPtrInHandle));
  __ leaq(RDX, FieldAddress(RDX, Array::data_offset()));

  // Set up arguments for the Dart call.
  Label push_arguments;
  Label done_push_arguments;
  __ j(ZERO, &done_push_arguments, Assembler::kNearJump);
  __ movq(RAX, Immediate(0));
  __ Bind(&push_arguments);
  __ pushq(Address(RDX, RAX, TIMES_8, 0));
  __ incq(RAX);
  __ cmpq(RAX, RBX);
  __ j(LESS, &push_arguments, Assembler::kNearJump);
  __ Bind(&done_push_arguments);

  // Call the Dart code entrypoint.
  __ xorq(PP, PP);  // GC-safe value into PP.
  __ movq(CODE_REG,
          Address(kTargetCodeReg, VMHandles::kOffsetOfRawPtrInHandle));
  __ movq(kTargetCodeReg, FieldAddress(CODE_REG, Code::entry_point_offset()));
  __ call(kTargetCodeReg);  // R10 is the arguments descriptor array.

  // Read the saved arguments descriptor array to obtain the number of passed
  // arguments.
  __ movq(kArgDescReg, Address(RBP, kArgumentsDescOffset));
  __ movq(R10, Address(kArgDescReg, VMHandles::kOffsetOfRawPtrInHandle));
  __ movq(RDX, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
  // Get rid of arguments pushed on the stack.
  __ leaq(RSP, Address(RSP, RDX, TIMES_4, 0));  // RDX is a Smi.

  // Restore the saved top exit frame info and top resource back into the
  // Isolate structure.
  __ popq(Address(THR, Thread::top_exit_frame_info_offset()));
  __ popq(Address(THR, Thread::top_resource_offset()));

  // Restore the current VMTag from the stack.
  __ popq(Assembler::VMTagAddress());

  // Restore C++ ABI callee-saved registers.
  __ PopRegisters(CallingConventions::kCalleeSaveCpuRegisters,
                  CallingConventions::kCalleeSaveXmmRegisters);
  __ set_constant_pool_allowed(false);

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
  __ LoadObject(R9, Object::null_object());
  if (FLAG_inline_alloc) {
    Label slow_case;
    // First compute the rounded instance size.
    // R10: number of context variables.
    intptr_t fixed_size_plus_alignment_padding =
        (sizeof(RawContext) + kObjectAlignment - 1);
    __ leaq(R13, Address(R10, TIMES_8, fixed_size_plus_alignment_padding));
    __ andq(R13, Immediate(-kObjectAlignment));

    // Check for allocation tracing.
    NOT_IN_PRODUCT(
        __ MaybeTraceAllocation(kContextCid, &slow_case, Assembler::kFarJump));

    // Now allocate the object.
    // R10: number of context variables.
    const intptr_t cid = kContextCid;
    NOT_IN_PRODUCT(Heap::Space space = Heap::kNew);
    __ movq(RAX, Address(THR, Thread::top_offset()));
    __ addq(R13, RAX);
    // Check if the allocation fits into the remaining space.
    // RAX: potential new object.
    // R13: potential next object start.
    // R10: number of context variables.
    __ cmpq(R13, Address(THR, Thread::end_offset()));
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
    __ movq(Address(THR, Thread::top_offset()), R13);
    // R13: Size of allocation in bytes.
    __ subq(R13, RAX);
    __ addq(RAX, Immediate(kHeapObjectTag));
    // Generate isolate-independent code to allow sharing between isolates.
    NOT_IN_PRODUCT(__ UpdateAllocationStatsWithSize(cid, R13, space));

    // Calculate the size tag.
    // RAX: new object.
    // R10: number of context variables.
    {
      Label size_tag_overflow, done;
      __ leaq(R13, Address(R10, TIMES_8, fixed_size_plus_alignment_padding));
      __ andq(R13, Immediate(-kObjectAlignment));
      __ cmpq(R13, Immediate(RawObject::SizeTag::kMaxSizeTag));
      __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
      __ shlq(R13, Immediate(RawObject::kSizeTagPos - kObjectAlignmentLog2));
      __ jmp(&done);

      __ Bind(&size_tag_overflow);
      // Set overflow size tag value.
      __ movq(R13, Immediate(0));

      __ Bind(&done);
      // RAX: new object.
      // R10: number of context variables.
      // R13: size and bit tags.
      __ orq(R13, Immediate(RawObject::ClassIdTag::encode(cid)));
      __ movq(FieldAddress(RAX, Context::tags_offset()), R13);  // Tags.
    }

    // Setup up number of context variables field.
    // RAX: new object.
    // R10: number of context variables as integer value (not object).
    __ movq(FieldAddress(RAX, Context::num_variables_offset()), R10);

    // Setup the parent field.
    // RAX: new object.
    // R10: number of context variables.
    // No generational barrier needed, since we are storing null.
    __ StoreIntoObjectNoBarrier(
        RAX, FieldAddress(RAX, Context::parent_offset()), R9);

    // Initialize the context variables.
    // RAX: new object.
    // R10: number of context variables.
    {
      Label loop, entry;
      __ leaq(R13, FieldAddress(RAX, Context::variable_offset(0)));
#if defined(DEBUG)
      static const bool kJumpLength = Assembler::kFarJump;
#else
      static const bool kJumpLength = Assembler::kNearJump;
#endif  // DEBUG
      __ jmp(&entry, kJumpLength);
      __ Bind(&loop);
      __ decq(R10);
      // No generational barrier needed, since we are storing null.
      __ StoreIntoObjectNoBarrier(RAX, Address(R13, R10, TIMES_8, 0), R9);
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
  __ pushq(R9);  // Setup space on stack for the return value.
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

// Helper stub to implement Assembler::StoreIntoObject.
// Input parameters:
//   RDX: Address being stored
void StubCode::GenerateUpdateStoreBufferStub(Assembler* assembler) {
  // Save registers being destroyed.
  __ pushq(RAX);
  __ pushq(RCX);

  Label add_to_buffer;
  // Check whether this object has already been remembered. Skip adding to the
  // store buffer if the object is in the store buffer already.
  // Spilled: RAX, RCX
  // RDX: Address being stored
  Label reload;
  __ Bind(&reload);
  __ movl(RAX, FieldAddress(RDX, Object::tags_offset()));
  __ testl(RAX, Immediate(1 << RawObject::kRememberedBit));
  __ j(EQUAL, &add_to_buffer, Assembler::kNearJump);
  __ popq(RCX);
  __ popq(RAX);
  __ ret();

  // Update the tags that this object has been remembered.
  // Note that we use 32 bit operations here to match the size of the
  // background sweeper which is also manipulating this 32 bit word.
  // RDX: Address being stored
  // RAX: Current tag value
  __ Bind(&add_to_buffer);
  __ movl(RCX, RAX);
  __ orl(RCX, Immediate(1 << RawObject::kRememberedBit));
  // Compare the tag word with RAX, update to RCX if unchanged.
  __ LockCmpxchgl(FieldAddress(RDX, Object::tags_offset()), RCX);
  __ j(NOT_EQUAL, &reload);

  // Load the StoreBuffer block out of the thread. Then load top_ out of the
  // StoreBufferBlock and add the address to the pointers_.
  // RDX: Address being stored
  __ movq(RAX, Address(THR, Thread::store_buffer_block_offset()));
  __ movl(RCX, Address(RAX, StoreBufferBlock::top_offset()));
  __ movq(Address(RAX, RCX, TIMES_8, StoreBufferBlock::pointers_offset()), RDX);

  // Increment top_ and check for overflow.
  // RCX: top_
  // RAX: StoreBufferBlock
  Label L;
  __ incq(RCX);
  __ movl(Address(RAX, StoreBufferBlock::top_offset()), RCX);
  __ cmpl(RCX, Immediate(StoreBufferBlock::kSize));
  // Restore values.
  __ popq(RCX);
  __ popq(RAX);
  __ j(EQUAL, &L, Assembler::kNearJump);
  __ ret();

  // Handle overflow: Call the runtime leaf function.
  __ Bind(&L);
  // Setup frame, push callee-saved registers.
  __ EnterCallRuntimeFrame(0);
  __ movq(CallingConventions::kArg1Reg, THR);
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
  __ LoadObject(R9, Object::null_object());
  if (is_cls_parameterized) {
    __ movq(RDX, Address(RSP, kObjectTypeArgumentsOffset));
    // RDX: instantiated type arguments.
  }
  Isolate* isolate = Isolate::Current();
  if (FLAG_inline_alloc && Heap::IsAllocatableInNewSpace(instance_size) &&
      !cls.TraceAllocation(isolate)) {
    Label slow_case;
    // Allocate the object and update top to point to
    // next object start and initialize the allocated object.
    // RDX: instantiated type arguments (if is_cls_parameterized).
    NOT_IN_PRODUCT(Heap::Space space = Heap::kNew);
    __ movq(RAX, Address(THR, Thread::top_offset()));
    __ leaq(RBX, Address(RAX, instance_size));
    // Check if the allocation fits into the remaining space.
    // RAX: potential new object start.
    // RBX: potential next object start.
    __ cmpq(RBX, Address(THR, Thread::end_offset()));
    if (FLAG_use_slow_path) {
      __ jmp(&slow_case);
    } else {
      __ j(ABOVE_EQUAL, &slow_case);
    }
    __ movq(Address(THR, Thread::top_offset()), RBX);
    NOT_IN_PRODUCT(__ UpdateAllocationStats(cls.id(), space));

    // RAX: new object start (untagged).
    // RBX: next object start.
    // RDX: new object type arguments (if is_cls_parameterized).
    // Set the tags.
    uint32_t tags = 0;
    tags = RawObject::SizeTag::update(instance_size, tags);
    ASSERT(cls.id() != kIllegalCid);
    tags = RawObject::ClassIdTag::update(cls.id(), tags);
    // 64 bit store also zeros the identity hash field.
    __ movq(Address(RAX, Instance::tags_offset()), Immediate(tags));
    __ addq(RAX, Immediate(kHeapObjectTag));

    // Initialize the remaining words of the object.
    // RAX: new object (tagged).
    // RBX: next object start.
    // RDX: new object type arguments (if is_cls_parameterized).
    // R9: raw null.
    // First try inlining the initialization without a loop.
    if (instance_size < (kInlineInstanceSize * kWordSize)) {
      // Check if the object contains any non-header fields.
      // Small objects are initialized using a consecutive set of writes.
      for (intptr_t current_offset = Instance::NextFieldOffset();
           current_offset < instance_size; current_offset += kWordSize) {
        __ StoreIntoObjectNoBarrier(RAX, FieldAddress(RAX, current_offset), R9);
      }
    } else {
      __ leaq(RCX, FieldAddress(RAX, Instance::NextFieldOffset()));
      // Loop until the whole object is initialized.
      // RAX: new object (tagged).
      // RBX: next object start.
      // RCX: next word to be initialized.
      // RDX: new object type arguments (if is_cls_parameterized).
      Label init_loop;
      Label done;
      __ Bind(&init_loop);
      __ cmpq(RCX, RBX);
#if defined(DEBUG)
      static const bool kJumpLength = Assembler::kFarJump;
#else
      static const bool kJumpLength = Assembler::kNearJump;
#endif  // DEBUG
      __ j(ABOVE_EQUAL, &done, kJumpLength);
      __ StoreIntoObjectNoBarrier(RAX, Address(RCX, 0), R9);
      __ addq(RCX, Immediate(kWordSize));
      __ jmp(&init_loop, Assembler::kNearJump);
      __ Bind(&done);
    }
    if (is_cls_parameterized) {
      // RAX: new object (tagged).
      // RDX: new object type arguments.
      // Set the type arguments in the new object.
      intptr_t offset = cls.type_arguments_field_offset();
      __ StoreIntoObjectNoBarrier(RAX, FieldAddress(RAX, offset), RDX);
    }
    // Done allocating and initializing the instance.
    // RAX: new object (tagged).
    __ ret();

    __ Bind(&slow_case);
  }
  // If is_cls_parameterized:
  // RDX: new object type arguments.
  // Create a stub frame.
  __ EnterStubFrame();  // Uses PP to access class object.
  __ pushq(R9);         // Setup space on stack for return value.
  __ PushObject(cls);   // Push class of object to be allocated.
  if (is_cls_parameterized) {
    __ pushq(RDX);  // Push type arguments of object to be allocated.
  } else {
    __ pushq(R9);  // Push null type arguments.
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
//   R10 : arguments descriptor array.
void StubCode::GenerateCallClosureNoSuchMethodStub(Assembler* assembler) {
  __ EnterStubFrame();

  // Load the receiver.
  __ movq(R13, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
  __ movq(RAX, Address(RBP, R13, TIMES_4, kParamEndSlotFromFp * kWordSize));

  __ pushq(Immediate(0));  // Result slot.
  __ pushq(RAX);           // Receiver.
  __ pushq(R10);           // Arguments descriptor array.

  // Adjust arguments count.
  __ cmpq(FieldAddress(R10, ArgumentsDescriptor::type_args_len_offset()),
          Immediate(0));
  __ movq(R10, R13);
  Label args_count_ok;
  __ j(EQUAL, &args_count_ok, Assembler::kNearJump);
  __ addq(R10, Immediate(Smi::RawValue(1)));  // Include the type arguments.
  __ Bind(&args_count_ok);

  // R10: Smi-tagged arguments array length.
  PushArgumentsArray(assembler);

  const intptr_t kNumArgs = 3;
  __ CallRuntime(kInvokeClosureNoSuchMethodRuntimeEntry, kNumArgs);
  // noSuchMethod on closures always throws an error, so it will never return.
  __ int3();
}

// Cannot use function object from ICData as it may be the inlined
// function and not the top-scope function.
void StubCode::GenerateOptimizedUsageCounterIncrement(Assembler* assembler) {
  Register ic_reg = RBX;
  Register func_reg = RDI;
  if (FLAG_trace_optimized_ic_calls) {
    __ EnterStubFrame();
    __ pushq(func_reg);  // Preserve
    __ pushq(ic_reg);    // Preserve.
    __ pushq(ic_reg);    // Argument.
    __ pushq(func_reg);  // Argument.
    __ CallRuntime(kTraceICCallRuntimeEntry, 2);
    __ popq(RAX);       // Discard argument;
    __ popq(RAX);       // Discard argument;
    __ popq(ic_reg);    // Restore.
    __ popq(func_reg);  // Restore.
    __ LeaveStubFrame();
  }
  __ incl(FieldAddress(func_reg, Function::usage_counter_offset()));
}

// Loads function into 'temp_reg', preserves 'ic_reg'.
void StubCode::GenerateUsageCounterIncrement(Assembler* assembler,
                                             Register temp_reg) {
  if (FLAG_optimization_counter_threshold >= 0) {
    Register ic_reg = RBX;
    Register func_reg = temp_reg;
    ASSERT(ic_reg != func_reg);
    __ Comment("Increment function counter");
    __ movq(func_reg, FieldAddress(ic_reg, ICData::owner_offset()));
    __ incl(FieldAddress(func_reg, Function::usage_counter_offset()));
  }
}

// Note: RBX must be preserved.
// Attempt a quick Smi operation for known operations ('kind'). The ICData
// must have been primed with a Smi/Smi check that will be used for counting
// the invocations.
static void EmitFastSmiOp(Assembler* assembler,
                          Token::Kind kind,
                          intptr_t num_args,
                          Label* not_smi_or_overflow) {
  __ Comment("Fast Smi op");
  ASSERT(num_args == 2);
  __ movq(RCX, Address(RSP, +1 * kWordSize));  // Right
  __ movq(RAX, Address(RSP, +2 * kWordSize));  // Left.
  __ movq(R13, RCX);
  __ orq(R13, RAX);
  __ testq(R13, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, not_smi_or_overflow);
  switch (kind) {
    case Token::kADD: {
      __ addq(RAX, RCX);
      __ j(OVERFLOW, not_smi_or_overflow);
      break;
    }
    case Token::kSUB: {
      __ subq(RAX, RCX);
      __ j(OVERFLOW, not_smi_or_overflow);
      break;
    }
    case Token::kEQ: {
      Label done, is_true;
      __ cmpq(RAX, RCX);
      __ j(EQUAL, &is_true, Assembler::kNearJump);
      __ LoadObject(RAX, Bool::False());
      __ jmp(&done, Assembler::kNearJump);
      __ Bind(&is_true);
      __ LoadObject(RAX, Bool::True());
      __ Bind(&done);
      break;
    }
    default:
      UNIMPLEMENTED();
  }

  // RBX: IC data object (preserved).
  __ movq(R13, FieldAddress(RBX, ICData::ic_data_offset()));
  // R13: ic_data_array with check entries: classes and target functions.
  __ leaq(R13, FieldAddress(R13, Array::data_offset()));
// R13: points directly to the first ic data array element.
#if defined(DEBUG)
  // Check that first entry is for Smi/Smi.
  Label error, ok;
  const Immediate& imm_smi_cid =
      Immediate(reinterpret_cast<intptr_t>(Smi::New(kSmiCid)));
  __ cmpq(Address(R13, 0 * kWordSize), imm_smi_cid);
  __ j(NOT_EQUAL, &error, Assembler::kNearJump);
  __ cmpq(Address(R13, 1 * kWordSize), imm_smi_cid);
  __ j(EQUAL, &ok, Assembler::kNearJump);
  __ Bind(&error);
  __ Stop("Incorrect IC data");
  __ Bind(&ok);
#endif

  if (FLAG_optimization_counter_threshold >= 0) {
    const intptr_t count_offset = ICData::CountIndexFor(num_args) * kWordSize;
    // Update counter, ignore overflow.
    __ addq(Address(R13, count_offset), Immediate(Smi::RawValue(1)));
  }

  __ ret();
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
    const RuntimeEntry& handle_ic_miss,
    Token::Kind kind,
    bool optimized) {
  ASSERT(num_args == 1 || num_args == 2);
#if defined(DEBUG)
  {
    Label ok;
    // Check that the IC data array has NumArgsTested() == num_args.
    // 'NumArgsTested' is stored in the least significant bits of 'state_bits'.
    __ movl(RCX, FieldAddress(RBX, ICData::state_bits_offset()));
    ASSERT(ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ andq(RCX, Immediate(ICData::NumArgsTestedMask()));
    __ cmpq(RCX, Immediate(num_args));
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Incorrect stub for IC data");
    __ Bind(&ok);
  }
#endif  // DEBUG

#if !defined(PRODUCT)
  Label stepping, done_stepping;
  if (!optimized) {
    __ Comment("Check single stepping");
    __ LoadIsolate(RAX);
    __ cmpb(Address(RAX, Isolate::single_step_offset()), Immediate(0));
    __ j(NOT_EQUAL, &stepping);
    __ Bind(&done_stepping);
  }
#endif

  Label not_smi_or_overflow;
  if (kind != Token::kILLEGAL) {
    EmitFastSmiOp(assembler, kind, num_args, &not_smi_or_overflow);
  }
  __ Bind(&not_smi_or_overflow);

  __ Comment("Extract ICData initial values and receiver cid");
  // Load arguments descriptor into R10.
  __ movq(R10, FieldAddress(RBX, ICData::arguments_descriptor_offset()));
  // Loop that checks if there is an IC data match.
  Label loop, found, miss;
  // RBX: IC data object (preserved).
  __ movq(R13, FieldAddress(RBX, ICData::ic_data_offset()));
  // R13: ic_data_array with check entries: classes and target functions.
  __ leaq(R13, FieldAddress(R13, Array::data_offset()));
  // R13: points directly to the first ic data array element.

  // Get argument count as Smi into RCX.
  __ movq(RCX, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
  // Load first argument into R9.
  __ movq(R9, Address(RSP, RCX, TIMES_4, 0));
  __ LoadTaggedClassIdMayBeSmi(RAX, R9);
  // RAX: first argument class ID as Smi.
  if (num_args == 2) {
    // Load second argument into R9.
    __ movq(R9, Address(RSP, RCX, TIMES_4, -kWordSize));
    __ LoadTaggedClassIdMayBeSmi(RCX, R9);
    // RCX: second argument class ID (smi).
  }

  __ Comment("ICData loop");

  // We unroll the generic one that is generated once more than the others.
  const bool optimize = kind == Token::kILLEGAL;
  const intptr_t target_offset = ICData::TargetIndexFor(num_args) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(num_args) * kWordSize;

  __ Bind(&loop);
  for (int unroll = optimize ? 4 : 2; unroll >= 0; unroll--) {
    Label update;
    __ movq(R9, Address(R13, 0));
    __ cmpq(RAX, R9);  // Class id match?
    if (num_args == 2) {
      __ j(NOT_EQUAL, &update);  // Continue.
      __ movq(R9, Address(R13, kWordSize));
      // R9: next class ID to check (smi).
      __ cmpq(RCX, R9);  // Class id match?
    }
    __ j(EQUAL, &found);  // Break.

    __ Bind(&update);

    const intptr_t entry_size =
        ICData::TestEntryLengthFor(num_args) * kWordSize;
    __ addq(R13, Immediate(entry_size));  // Next entry.

    __ cmpq(R9, Immediate(Smi::RawValue(kIllegalCid)));  // Done?
    if (unroll == 0) {
      __ j(NOT_EQUAL, &loop);
    } else {
      __ j(EQUAL, &miss);
    }
  }

  __ Bind(&miss);
  __ Comment("IC miss");
  // Compute address of arguments (first read number of arguments from
  // arguments descriptor array and then compute address on the stack).
  __ movq(RAX, FieldAddress(R10, ArgumentsDescriptor::count_offset()));
  __ leaq(RAX, Address(RSP, RAX, TIMES_4, 0));  // RAX is Smi.
  __ EnterStubFrame();
  __ pushq(R10);           // Preserve arguments descriptor array.
  __ pushq(RBX);           // Preserve IC data object.
  __ pushq(Immediate(0));  // Result slot.
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
  __ popq(RAX);  // Pop returned function object into RAX.
  __ popq(RBX);  // Restore IC data array.
  __ popq(R10);  // Restore arguments descriptor array.
  __ RestoreCodePointer();
  __ LeaveStubFrame();
  Label call_target_function;
  if (!FLAG_lazy_dispatchers) {
    GenerateDispatcherCode(assembler, &call_target_function);
  } else {
    __ jmp(&call_target_function);
  }

  __ Bind(&found);
  // R13: Pointer to an IC data check group.
  __ movq(RAX, Address(R13, target_offset));

  if (FLAG_optimization_counter_threshold >= 0) {
    __ Comment("Update caller's counter");
    // Ignore overflow.
    __ addq(Address(R13, count_offset), Immediate(Smi::RawValue(1)));
  }

  __ Comment("Call target");
  __ Bind(&call_target_function);
  // RAX: Target function.
  __ movq(CODE_REG, FieldAddress(RAX, Function::code_offset()));
  __ movq(RCX, FieldAddress(RAX, Function::entry_point_offset()));
  __ jmp(RCX);

#if !defined(PRODUCT)
  if (!optimized) {
    __ Bind(&stepping);
    __ EnterStubFrame();
    __ pushq(RBX);
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ popq(RBX);
    __ RestoreCodePointer();
    __ LeaveStubFrame();
    __ jmp(&done_stepping);
  }
#endif
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
      assembler, 1, kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL);
}

void StubCode::GenerateTwoArgsCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, RCX);
  GenerateNArgsCheckInlineCacheStub(assembler, 2,
                                    kInlineCacheMissHandlerTwoArgsRuntimeEntry,
                                    Token::kILLEGAL);
}

void StubCode::GenerateSmiAddInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, RCX);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kADD);
}

void StubCode::GenerateSmiSubInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, RCX);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kSUB);
}

void StubCode::GenerateSmiEqualInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, RCX);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kEQ);
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
// RBX: ICData
void StubCode::GenerateZeroArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, RCX);
#if defined(DEBUG)
  {
    Label ok;
    // Check that the IC data array has NumArgsTested() == 0.
    // 'NumArgsTested' is stored in the least significant bits of 'state_bits'.
    __ movl(RCX, FieldAddress(RBX, ICData::state_bits_offset()));
    ASSERT(ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ andq(RCX, Immediate(ICData::NumArgsTestedMask()));
    __ cmpq(RCX, Immediate(0));
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Incorrect IC data for unoptimized static call");
    __ Bind(&ok);
  }
#endif  // DEBUG

#if !defined(PRODUCT)
  // Check single stepping.
  Label stepping, done_stepping;
  __ LoadIsolate(RAX);
  __ movzxb(RAX, Address(RAX, Isolate::single_step_offset()));
  __ cmpq(RAX, Immediate(0));
#if defined(DEBUG)
  static const bool kJumpLength = Assembler::kFarJump;
#else
  static const bool kJumpLength = Assembler::kNearJump;
#endif  // DEBUG
  __ j(NOT_EQUAL, &stepping, kJumpLength);
  __ Bind(&done_stepping);
#endif

  // RBX: IC data object (preserved).
  __ movq(R12, FieldAddress(RBX, ICData::ic_data_offset()));
  // R12: ic_data_array with entries: target functions and count.
  __ leaq(R12, FieldAddress(R12, Array::data_offset()));
  // R12: points directly to the first ic data array element.
  const intptr_t target_offset = ICData::TargetIndexFor(0) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(0) * kWordSize;

  if (FLAG_optimization_counter_threshold >= 0) {
    // Increment count for this call, ignore overflow.
    __ addq(Address(R12, count_offset), Immediate(Smi::RawValue(1)));
  }

  // Load arguments descriptor into R10.
  __ movq(R10, FieldAddress(RBX, ICData::arguments_descriptor_offset()));

  // Get function and call it, if possible.
  __ movq(RAX, Address(R12, target_offset));
  __ movq(CODE_REG, FieldAddress(RAX, Function::code_offset()));
  __ movq(RCX, FieldAddress(RAX, Function::entry_point_offset()));
  __ jmp(RCX);

#if !defined(PRODUCT)
  __ Bind(&stepping);
  __ EnterStubFrame();
  __ pushq(RBX);  // Preserve IC data object.
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ popq(RBX);
  __ RestoreCodePointer();
  __ LeaveStubFrame();
  __ jmp(&done_stepping, Assembler::kNearJump);
#endif
}

void StubCode::GenerateOneArgUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, RCX);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kStaticCallMissHandlerOneArgRuntimeEntry, Token::kILLEGAL);
}

void StubCode::GenerateTwoArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, RCX);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kStaticCallMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL);
}

// Stub for compiling a function and jumping to the compiled code.
// RCX: IC-Data (for methods).
// R10: Arguments descriptor.
// RAX: Function.
void StubCode::GenerateLazyCompileStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ pushq(R10);  // Preserve arguments descriptor array.
  __ pushq(RBX);  // Preserve IC data object.
  __ pushq(RAX);  // Pass function.
  __ CallRuntime(kCompileFunctionRuntimeEntry, 1);
  __ popq(RAX);  // Restore function.
  __ popq(RBX);  // Restore IC data array.
  __ popq(R10);  // Restore arguments descriptor array.
  __ LeaveStubFrame();

  __ movq(CODE_REG, FieldAddress(RAX, Function::code_offset()));
  __ movq(RAX, FieldAddress(RAX, Function::entry_point_offset()));
  __ jmp(RAX);
}

// RBX: Contains an ICData.
// TOS(0): return address (Dart code).
void StubCode::GenerateICCallBreakpointStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ pushq(RBX);           // Preserve IC data.
  __ pushq(Immediate(0));  // Result slot.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ popq(CODE_REG);  // Original stub.
  __ popq(RBX);       // Restore IC data.
  __ LeaveStubFrame();

  __ movq(RAX, FieldAddress(CODE_REG, Code::entry_point_offset()));
  __ jmp(RAX);  // Jump to original stub.
}

//  TOS(0): return address (Dart code).
void StubCode::GenerateRuntimeCallBreakpointStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ pushq(Immediate(0));  // Result slot.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ popq(CODE_REG);  // Original stub.
  __ LeaveStubFrame();

  __ movq(RAX, FieldAddress(CODE_REG, Code::entry_point_offset()));
  __ jmp(RAX);  // Jump to original stub.
}

// Called only from unoptimized code.
void StubCode::GenerateDebugStepCheckStub(Assembler* assembler) {
  // Check single stepping.
  Label stepping, done_stepping;
  __ LoadIsolate(RAX);
  __ movzxb(RAX, Address(RAX, Isolate::single_step_offset()));
  __ cmpq(RAX, Immediate(0));
  __ j(NOT_EQUAL, &stepping, Assembler::kNearJump);
  __ Bind(&done_stepping);
  __ ret();

  __ Bind(&stepping);
  __ EnterStubFrame();
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ LeaveStubFrame();
  __ jmp(&done_stepping, Assembler::kNearJump);
}

// Used to check class and type arguments. Arguments passed on stack:
// TOS + 0: return address.
// TOS + 1: function type arguments (only if n == 4, can be raw_null).
// TOS + 2: instantiator type arguments (only if n == 4, can be raw_null).
// TOS + 3: instance.
// TOS + 4: SubtypeTestCache.
// Result in RCX: null -> not found, otherwise result (true or false).
static void GenerateSubtypeNTestCacheStub(Assembler* assembler, int n) {
  ASSERT((n == 1) || (n == 2) || (n == 4));
  const intptr_t kFunctionTypeArgumentsInBytes = 1 * kWordSize;
  const intptr_t kInstantiatorTypeArgumentsInBytes = 2 * kWordSize;
  const intptr_t kInstanceOffsetInBytes = 3 * kWordSize;
  const intptr_t kCacheOffsetInBytes = 4 * kWordSize;
  __ movq(RAX, Address(RSP, kInstanceOffsetInBytes));
  __ LoadObject(R9, Object::null_object());
  if (n > 1) {
    __ LoadClass(R10, RAX);
    // Compute instance type arguments into R13.
    Label has_no_type_arguments;
    __ movq(R13, R9);
    __ movl(RDI,
            FieldAddress(R10,
                         Class::type_arguments_field_offset_in_words_offset()));
    __ cmpl(RDI, Immediate(Class::kNoTypeArguments));
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
  // R13: instance type arguments (still null if closure).
  Label loop, found, not_found, next_iteration;
  __ SmiTag(R10);
  __ cmpq(R10, Immediate(Smi::RawValue(kClosureCid)));
  __ j(NOT_EQUAL, &loop, Assembler::kNearJump);
  __ movq(R13, FieldAddress(RAX, Closure::function_type_arguments_offset()));
  __ cmpq(R13, R9);  // Cache cannot be used for generic closures.
  __ j(NOT_EQUAL, &not_found, Assembler::kNearJump);
  __ movq(R13,
          FieldAddress(RAX, Closure::instantiator_type_arguments_offset()));
  __ movq(R10, FieldAddress(RAX, Closure::function_offset()));
  // R10: instance class id as Smi or function.
  __ Bind(&loop);
  __ movq(RDI, Address(RDX, kWordSize *
                                SubtypeTestCache::kInstanceClassIdOrFunction));
  __ cmpq(RDI, R9);
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
              Address(RDX, kWordSize *
                               SubtypeTestCache::kInstantiatorTypeArguments));
      __ cmpq(RDI, Address(RSP, kInstantiatorTypeArgumentsInBytes));
      __ j(NOT_EQUAL, &next_iteration, Assembler::kNearJump);
      __ movq(RDI, Address(RDX, kWordSize *
                                    SubtypeTestCache::kFunctionTypeArguments));
      __ cmpq(RDI, Address(RSP, kFunctionTypeArgumentsInBytes));
      __ j(EQUAL, &found, Assembler::kNearJump);
    }
  }

  __ Bind(&next_iteration);
  __ addq(RDX, Immediate(kWordSize * SubtypeTestCache::kTestEntryLength));
  __ jmp(&loop, Assembler::kNearJump);
  // Fall through to not found.
  __ Bind(&not_found);
  __ movq(RCX, R9);
  __ ret();

  __ Bind(&found);
  __ movq(RCX, Address(RDX, kWordSize * SubtypeTestCache::kTestResult));
  __ ret();
}

// Used to check class and type arguments. Arguments passed on stack:
// TOS + 0: return address.
// TOS + 1: raw_null.
// TOS + 2: raw_null.
// TOS + 3: instance.
// TOS + 4: SubtypeTestCache.
// Result in RCX: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype1TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 1);
}

// Used to check class and type arguments. Arguments passed on stack:
// TOS + 0: return address.
// TOS + 1: raw_null.
// TOS + 2: raw_null.
// TOS + 3: instance.
// TOS + 4: SubtypeTestCache.
// Result in RCX: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype2TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 2);
}

// Used to check class and type arguments. Arguments passed on stack:
// TOS + 0: return address.
// TOS + 1: function type arguments (can be raw_null).
// TOS + 2: instantiator type arguments (can be raw_null).
// TOS + 3: instance.
// TOS + 4: SubtypeTestCache.
// Result in RCX: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype4TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 4);
}

// Return the current stack pointer address, used to stack alignment
// checks.
// TOS + 0: return address
// Result in RAX.
void StubCode::GenerateGetCStackPointerStub(Assembler* assembler) {
  __ leaq(RAX, Address(RSP, kWordSize));
  __ ret();
}

// Jump to a frame on the call stack.
// TOS + 0: return address
// Arg1: program counter
// Arg2: stack pointer
// Arg3: frame_pointer
// Arg4: thread
// No Result.
void StubCode::GenerateJumpToFrameStub(Assembler* assembler) {
  __ movq(THR, CallingConventions::kArg4Reg);
  __ movq(RBP, CallingConventions::kArg3Reg);
  __ movq(RSP, CallingConventions::kArg2Reg);
  // Set the tag.
  __ movq(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));
  // Clear top exit frame.
  __ movq(Address(THR, Thread::top_exit_frame_info_offset()), Immediate(0));
  // Restore the pool pointer.
  __ RestoreCodePointer();
  __ LoadPoolPointer(PP);
  __ jmp(CallingConventions::kArg1Reg);  // Jump to program counter.
}

// Run an exception handler.  Execution comes from JumpToFrame stub.
//
// The arguments are stored in the Thread object.
// No result.
void StubCode::GenerateRunExceptionHandlerStub(Assembler* assembler) {
  ASSERT(kExceptionObjectReg == RAX);
  ASSERT(kStackTraceObjectReg == RDX);
  __ movq(CallingConventions::kArg1Reg,
          Address(THR, Thread::resume_pc_offset()));

  // Load the exception from the current thread.
  Address exception_addr(THR, Thread::active_exception_offset());
  __ movq(kExceptionObjectReg, exception_addr);
  __ movq(exception_addr, Immediate(0));

  // Load the stacktrace from the current thread.
  Address stacktrace_addr(THR, Thread::active_stacktrace_offset());
  __ movq(kStackTraceObjectReg, stacktrace_addr);
  __ movq(stacktrace_addr, Immediate(0));

  __ jmp(CallingConventions::kArg1Reg);  // Jump to continuation point.
}

// Deoptimize a frame on the call stack before rewinding.
// The arguments are stored in the Thread object.
// No result.
void StubCode::GenerateDeoptForRewindStub(Assembler* assembler) {
  // Push zap value instead of CODE_REG.
  __ pushq(Immediate(kZapCodeReg));

  // Push the deopt pc.
  __ pushq(Address(THR, Thread::resume_pc_offset()));
  GenerateDeoptimizationSequence(assembler, kEagerDeopt);

  // After we have deoptimized, jump to the correct frame.
  __ EnterStubFrame();
  __ CallRuntime(kRewindPostDeoptRuntimeEntry, 0);
  __ LeaveStubFrame();
  __ int3();
}

// Calls to the runtime to optimize the given function.
// RDI: function to be reoptimized.
// R10: argument descriptor (preserved).
void StubCode::GenerateOptimizeFunctionStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ pushq(R10);           // Preserve args descriptor.
  __ pushq(Immediate(0));  // Result slot.
  __ pushq(RDI);           // Arg0: function to optimize
  __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry, 1);
  __ popq(RAX);  // Discard argument.
  __ popq(RAX);  // Get Code object.
  __ popq(R10);  // Restore argument descriptor.
  __ LeaveStubFrame();
  __ movq(CODE_REG, FieldAddress(RAX, Function::code_offset()));
  __ movq(RCX, FieldAddress(RAX, Function::entry_point_offset()));
  __ jmp(RCX);
  __ int3();
}

// Does identical check (object references are equal or not equal) with special
// checks for boxed numbers.
// Left and right are pushed on stack.
// Return ZF set.
// Note: A Mint cannot contain a value that would fit in Smi, a Bigint
// cannot contain a value that fits in Mint or Smi.
static void GenerateIdenticalWithNumberCheckStub(Assembler* assembler,
                                                 const Register left,
                                                 const Register right) {
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
  __ j(NOT_EQUAL, &done, Assembler::kFarJump);

  // Double values bitwise compare.
  __ movq(left, FieldAddress(left, Double::value_offset()));
  __ cmpq(left, FieldAddress(right, Double::value_offset()));
  __ jmp(&done, Assembler::kFarJump);

  __ Bind(&check_mint);
  __ CompareClassId(left, kMintCid);
  __ j(NOT_EQUAL, &check_bigint, Assembler::kNearJump);
  __ CompareClassId(right, kMintCid);
  __ j(NOT_EQUAL, &done, Assembler::kFarJump);
  __ movq(left, FieldAddress(left, Mint::value_offset()));
  __ cmpq(left, FieldAddress(right, Mint::value_offset()));
  __ jmp(&done, Assembler::kFarJump);

  __ Bind(&check_bigint);
  __ CompareClassId(left, kBigintCid);
  __ j(NOT_EQUAL, &reference_compare, Assembler::kFarJump);
  __ CompareClassId(right, kBigintCid);
  __ j(NOT_EQUAL, &done, Assembler::kFarJump);
  __ EnterStubFrame();
  __ ReserveAlignedFrameSpace(0);
  __ movq(CallingConventions::kArg1Reg, left);
  __ movq(CallingConventions::kArg2Reg, right);
  __ CallRuntime(kBigintCompareRuntimeEntry, 2);
  // Result in RAX, 0 means equal.
  __ LeaveStubFrame();
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
#if !defined(PRODUCT)
  // Check single stepping.
  Label stepping, done_stepping;
  __ LoadIsolate(RAX);
  __ movzxb(RAX, Address(RAX, Isolate::single_step_offset()));
  __ cmpq(RAX, Immediate(0));
  __ j(NOT_EQUAL, &stepping);
  __ Bind(&done_stepping);
#endif

  const Register left = RAX;
  const Register right = RDX;

  __ movq(left, Address(RSP, 2 * kWordSize));
  __ movq(right, Address(RSP, 1 * kWordSize));
  GenerateIdenticalWithNumberCheckStub(assembler, left, right);
  __ ret();

#if !defined(PRODUCT)
  __ Bind(&stepping);
  __ EnterStubFrame();
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ RestoreCodePointer();
  __ LeaveStubFrame();
  __ jmp(&done_stepping);
#endif
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

// Called from megamorphic calls.
//  RDI: receiver
//  RBX: MegamorphicCache (preserved)
// Passed to target:
//  CODE_REG: target Code
//  R10: arguments descriptor
void StubCode::GenerateMegamorphicCallStub(Assembler* assembler) {
  // Jump if receiver is a smi.
  Label smi_case;
  __ testq(RDI, Immediate(kSmiTagMask));
  // Jump out of line for smi case.
  __ j(ZERO, &smi_case, Assembler::kNearJump);

  // Loads the cid of the object.
  __ LoadClassId(RAX, RDI);

  Label cid_loaded;
  __ Bind(&cid_loaded);
  __ movq(R9, FieldAddress(RBX, MegamorphicCache::mask_offset()));
  __ movq(RDI, FieldAddress(RBX, MegamorphicCache::buckets_offset()));
  // R9: mask as a smi.
  // RDI: cache buckets array.

  // Tag cid as a smi.
  __ addq(RAX, RAX);

  // Compute the table index.
  ASSERT(MegamorphicCache::kSpreadFactor == 7);
  // Use leaq and subq multiply with 7 == 8 - 1.
  __ leaq(RCX, Address(RAX, TIMES_8, 0));
  __ subq(RCX, RAX);

  Label loop;
  __ Bind(&loop);
  __ andq(RCX, R9);

  const intptr_t base = Array::data_offset();
  // RCX is smi tagged, but table entries are two words, so TIMES_8.
  Label probe_failed;
  __ cmpq(RAX, FieldAddress(RDI, RCX, TIMES_8, base));
  __ j(NOT_EQUAL, &probe_failed, Assembler::kNearJump);

  Label load_target;
  __ Bind(&load_target);
  // Call the target found in the cache.  For a class id match, this is a
  // proper target for the given name and arguments descriptor.  If the
  // illegal class id was found, the target is a cache miss handler that can
  // be invoked as a normal Dart function.
  __ movq(RAX, FieldAddress(RDI, RCX, TIMES_8, base + kWordSize));
  __ movq(R10,
          FieldAddress(RBX, MegamorphicCache::arguments_descriptor_offset()));
  __ movq(RCX, FieldAddress(RAX, Function::entry_point_offset()));
  __ movq(CODE_REG, FieldAddress(RAX, Function::code_offset()));
  __ jmp(RCX);

  // Probe failed, check if it is a miss.
  __ Bind(&probe_failed);
  __ cmpq(FieldAddress(RDI, RCX, TIMES_8, base),
          Immediate(Smi::RawValue(kIllegalCid)));
  __ j(ZERO, &load_target, Assembler::kNearJump);

  // Try next entry in the table.
  __ AddImmediate(RCX, Immediate(Smi::RawValue(1)));
  __ jmp(&loop);

  // Load cid for the Smi case.
  __ Bind(&smi_case);
  __ movq(RAX, Immediate(kSmiCid));
  __ jmp(&cid_loaded);
}

// Called from switchable IC calls.
//  RDI: receiver
//  RBX: ICData (preserved)
// Passed to target:
//  CODE_REG: target Code object
//  R10: arguments descriptor
void StubCode::GenerateICCallThroughFunctionStub(Assembler* assembler) {
  Label loop, found, miss;
  __ movq(R13, FieldAddress(RBX, ICData::ic_data_offset()));
  __ movq(R10, FieldAddress(RBX, ICData::arguments_descriptor_offset()));
  __ leaq(R13, FieldAddress(R13, Array::data_offset()));
  // R13: first IC entry
  __ LoadTaggedClassIdMayBeSmi(RAX, RDI);
  // RAX: receiver cid as Smi

  __ Bind(&loop);
  __ movq(R9, Address(R13, 0));
  __ cmpq(RAX, R9);
  __ j(EQUAL, &found, Assembler::kNearJump);

  ASSERT(Smi::RawValue(kIllegalCid) == 0);
  __ testq(R9, R9);
  __ j(ZERO, &miss, Assembler::kNearJump);

  const intptr_t entry_length = ICData::TestEntryLengthFor(1) * kWordSize;
  __ addq(R13, Immediate(entry_length));  // Next entry.
  __ jmp(&loop);

  __ Bind(&found);
  const intptr_t target_offset = ICData::TargetIndexFor(1) * kWordSize;
  __ movq(RAX, Address(R13, target_offset));
  __ movq(RCX, FieldAddress(RAX, Function::entry_point_offset()));
  __ movq(CODE_REG, FieldAddress(RAX, Function::code_offset()));
  __ jmp(RCX);

  __ Bind(&miss);
  __ LoadIsolate(RAX);
  __ movq(CODE_REG, Address(RAX, Isolate::ic_miss_code_offset()));
  __ movq(RCX, FieldAddress(CODE_REG, Code::entry_point_offset()));
  __ jmp(RCX);
}

void StubCode::GenerateICCallThroughCodeStub(Assembler* assembler) {
  Label loop, found, miss;
  __ movq(R13, FieldAddress(RBX, ICData::ic_data_offset()));
  __ movq(R10, FieldAddress(RBX, ICData::arguments_descriptor_offset()));
  __ leaq(R13, FieldAddress(R13, Array::data_offset()));
  // R13: first IC entry
  __ LoadTaggedClassIdMayBeSmi(RAX, RDI);
  // RAX: receiver cid as Smi

  __ Bind(&loop);
  __ movq(R9, Address(R13, 0));
  __ cmpq(RAX, R9);
  __ j(EQUAL, &found, Assembler::kNearJump);

  ASSERT(Smi::RawValue(kIllegalCid) == 0);
  __ testq(R9, R9);
  __ j(ZERO, &miss, Assembler::kNearJump);

  const intptr_t entry_length = ICData::TestEntryLengthFor(1) * kWordSize;
  __ addq(R13, Immediate(entry_length));  // Next entry.
  __ jmp(&loop);

  __ Bind(&found);
  const intptr_t code_offset = ICData::CodeIndexFor(1) * kWordSize;
  const intptr_t entry_offset = ICData::EntryPointIndexFor(1) * kWordSize;
  __ movq(RCX, Address(R13, entry_offset));
  __ movq(CODE_REG, Address(R13, code_offset));
  __ jmp(RCX);

  __ Bind(&miss);
  __ LoadIsolate(RAX);
  __ movq(CODE_REG, Address(RAX, Isolate::ic_miss_code_offset()));
  __ movq(RCX, FieldAddress(CODE_REG, Code::entry_point_offset()));
  __ jmp(RCX);
}

//  RDI: receiver
//  RBX: UnlinkedCall
void StubCode::GenerateUnlinkedCallStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ pushq(RDI);  // Preserve receiver.

  __ pushq(Immediate(0));  // Result slot.
  __ pushq(RDI);           // Arg0: Receiver
  __ pushq(RBX);           // Arg1: UnlinkedCall
  __ CallRuntime(kUnlinkedCallRuntimeEntry, 2);
  __ popq(RBX);
  __ popq(RBX);
  __ popq(RBX);  // result = IC

  __ popq(RDI);  // Restore receiver.
  __ LeaveStubFrame();

  __ movq(CODE_REG, Address(THR, Thread::ic_lookup_through_code_stub_offset()));
  __ movq(RCX, FieldAddress(CODE_REG, Code::checked_entry_point_offset()));
  __ jmp(RCX);
}

// Called from switchable IC calls.
//  RDI: receiver
//  RBX: SingleTargetCache
// Passed to target::
//  CODE_REG: target Code object
void StubCode::GenerateSingleTargetCallStub(Assembler* assembler) {
  Label miss;
  __ LoadClassIdMayBeSmi(RAX, RDI);
  __ movzxw(R9, FieldAddress(RBX, SingleTargetCache::lower_limit_offset()));
  __ movzxw(R10, FieldAddress(RBX, SingleTargetCache::upper_limit_offset()));
  __ cmpq(RAX, R9);
  __ j(LESS, &miss, Assembler::kNearJump);
  __ cmpq(RAX, R10);
  __ j(GREATER, &miss, Assembler::kNearJump);
  __ movq(RCX, FieldAddress(RBX, SingleTargetCache::entry_point_offset()));
  __ movq(CODE_REG, FieldAddress(RBX, SingleTargetCache::target_offset()));
  __ jmp(RCX);

  __ Bind(&miss);
  __ EnterStubFrame();
  __ pushq(RDI);  // Preserve receiver.

  __ pushq(Immediate(0));  // Result slot.
  __ pushq(RDI);           // Arg0: Receiver
  __ CallRuntime(kSingleTargetMissRuntimeEntry, 1);
  __ popq(RBX);
  __ popq(RBX);  // result = IC

  __ popq(RDI);  // Restore receiver.
  __ LeaveStubFrame();

  __ movq(CODE_REG, Address(THR, Thread::ic_lookup_through_code_stub_offset()));
  __ movq(RCX, FieldAddress(CODE_REG, Code::checked_entry_point_offset()));
  __ jmp(RCX);
}

// Called from the monomorphic checked entry.
//  RDI: receiver
void StubCode::GenerateMonomorphicMissStub(Assembler* assembler) {
  __ movq(CODE_REG, Address(THR, Thread::monomorphic_miss_stub_offset()));
  __ EnterStubFrame();
  __ pushq(RDI);  // Preserve receiver.

  __ pushq(Immediate(0));  // Result slot.
  __ pushq(RDI);           // Arg0: Receiver
  __ CallRuntime(kMonomorphicMissRuntimeEntry, 1);
  __ popq(RBX);
  __ popq(RBX);  // result = IC

  __ popq(RDI);  // Restore receiver.
  __ LeaveStubFrame();

  __ movq(CODE_REG, Address(THR, Thread::ic_lookup_through_code_stub_offset()));
  __ movq(RCX, FieldAddress(CODE_REG, Code::checked_entry_point_offset()));
  __ jmp(RCX);
}

void StubCode::GenerateFrameAwaitingMaterializationStub(Assembler* assembler) {
  __ int3();
}

void StubCode::GenerateAsynchronousGapMarkerStub(Assembler* assembler) {
  __ int3();
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_X64) && !defined(DART_PRECOMPILED_RUNTIME)
