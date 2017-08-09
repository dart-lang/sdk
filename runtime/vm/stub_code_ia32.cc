// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32) && !defined(DART_PRECOMPILED_RUNTIME)

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
#include "vm/tags.h"

#define __ assembler->

namespace dart {

DEFINE_FLAG(bool, inline_alloc, true, "Inline allocation of objects.");
DEFINE_FLAG(bool,
            use_slow_path,
            false,
            "Set to true for debugging & verifying the slow paths.");
DECLARE_FLAG(bool, trace_optimized_ic_calls);

#define INT32_SIZEOF(x) static_cast<int32_t>(sizeof(x))

// Input parameters:
//   ESP : points to return address.
//   ESP + 4 : address of last argument in argument array.
//   ESP + 4*EDX : address of first argument in argument array.
//   ESP + 4*EDX + 4 : address of return value.
//   ECX : address of the runtime function to call.
//   EDX : number of arguments to the call.
// Must preserve callee saved registers EDI and EBX.
void StubCode::GenerateCallToRuntimeStub(Assembler* assembler) {
  const intptr_t thread_offset = NativeArguments::thread_offset();
  const intptr_t argc_tag_offset = NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = NativeArguments::argv_offset();
  const intptr_t retval_offset = NativeArguments::retval_offset();

  __ EnterFrame(0);

  // Save exit frame information to enable stack walking as we are about
  // to transition to Dart VM C++ code.
  __ movl(Address(THR, Thread::top_exit_frame_info_offset()), EBP);

#if defined(DEBUG)
  {
    Label ok;
    // Check that we are always entering from Dart code.
    __ cmpl(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the thread is executing VM code.
  __ movl(Assembler::VMTagAddress(), ECX);

  // Reserve space for arguments and align frame before entering C++ world.
  __ AddImmediate(ESP, Immediate(-INT32_SIZEOF(NativeArguments)));
  if (OS::ActivationFrameAlignment() > 1) {
    __ andl(ESP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass NativeArguments structure by value and call runtime.
  __ movl(Address(ESP, thread_offset), THR);  // Set thread in NativeArgs.
  // There are no runtime calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  __ movl(Address(ESP, argc_tag_offset), EDX);  // Set argc in NativeArguments.
  // Compute argv.
  __ leal(EAX, Address(EBP, EDX, TIMES_4, kParamEndSlotFromFp * kWordSize));
  __ movl(Address(ESP, argv_offset), EAX);    // Set argv in NativeArguments.
  __ addl(EAX, Immediate(1 * kWordSize));     // Retval is next to 1st argument.
  __ movl(Address(ESP, retval_offset), EAX);  // Set retval in NativeArguments.
  __ call(ECX);

  __ movl(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));

  // Reset exit frame information in Isolate structure.
  __ movl(Address(THR, Thread::top_exit_frame_info_offset()), Immediate(0));

  __ LeaveFrame();
  __ ret();
}

// Input parameters:
//   ESP : points to return address.
//   EAX : stop message (const char*).
// Must preserve all registers, except EAX.
void StubCode::GeneratePrintStopMessageStub(Assembler* assembler) {
  __ EnterCallRuntimeFrame(1 * kWordSize);
  __ movl(Address(ESP, 0), EAX);
  __ CallRuntime(kPrintStopMessageRuntimeEntry, 1);
  __ LeaveCallRuntimeFrame();
  __ ret();
}

// Input parameters:
//   ESP : points to return address.
//   ESP + 4 : address of return value.
//   EAX : address of first argument in argument array.
//   ECX : address of the native function to call.
//   EDX : argc_tag including number of arguments and function kind.
static void GenerateCallNativeWithWrapperStub(Assembler* assembler,
                                              ExternalLabel* wrapper) {
  const intptr_t native_args_struct_offset =
      NativeEntry::kNumCallWrapperArguments * kWordSize;
  const intptr_t thread_offset =
      NativeArguments::thread_offset() + native_args_struct_offset;
  const intptr_t argc_tag_offset =
      NativeArguments::argc_tag_offset() + native_args_struct_offset;
  const intptr_t argv_offset =
      NativeArguments::argv_offset() + native_args_struct_offset;
  const intptr_t retval_offset =
      NativeArguments::retval_offset() + native_args_struct_offset;

  __ EnterFrame(0);

  // Save exit frame information to enable stack walking as we are about
  // to transition to dart VM code.
  __ movl(Address(THR, Thread::top_exit_frame_info_offset()), EBP);

#if defined(DEBUG)
  {
    Label ok;
    // Check that we are always entering from Dart code.
    __ cmpl(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the thread is executing native code.
  __ movl(Assembler::VMTagAddress(), ECX);

  // Reserve space for the native arguments structure, the outgoing parameters
  // (pointer to the native arguments structure, the C function entry point)
  // and align frame before entering the C++ world.
  __ AddImmediate(ESP,
                  Immediate(-INT32_SIZEOF(NativeArguments) - (2 * kWordSize)));
  if (OS::ActivationFrameAlignment() > 1) {
    __ andl(ESP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass NativeArguments structure by value and call native function.
  __ movl(Address(ESP, thread_offset), THR);    // Set thread in NativeArgs.
  __ movl(Address(ESP, argc_tag_offset), EDX);  // Set argc in NativeArguments.
  __ movl(Address(ESP, argv_offset), EAX);      // Set argv in NativeArguments.
  __ leal(EAX, Address(EBP, 2 * kWordSize));    // Compute return value addr.
  __ movl(Address(ESP, retval_offset), EAX);  // Set retval in NativeArguments.
  __ leal(EAX, Address(ESP, 2 * kWordSize));  // Pointer to the NativeArguments.
  __ movl(Address(ESP, 0), EAX);  // Pass the pointer to the NativeArguments.

  __ movl(Address(ESP, kWordSize), ECX);  // Function to call.
  __ call(wrapper);

  __ movl(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));

  // Reset exit frame information in Isolate structure.
  __ movl(Address(THR, Thread::top_exit_frame_info_offset()), Immediate(0));

  __ LeaveFrame();
  __ ret();
}

void StubCode::GenerateCallNoScopeNativeStub(Assembler* assembler) {
  ExternalLabel wrapper(NativeEntry::NoScopeNativeCallWrapperEntry());
  GenerateCallNativeWithWrapperStub(assembler, &wrapper);
}

void StubCode::GenerateCallAutoScopeNativeStub(Assembler* assembler) {
  ExternalLabel wrapper(NativeEntry::AutoScopeNativeCallWrapperEntry());
  GenerateCallNativeWithWrapperStub(assembler, &wrapper);
}

// Input parameters:
//   ESP : points to return address.
//   ESP + 4 : address of return value.
//   EAX : address of first argument in argument array.
//   ECX : address of the native function to call.
//   EDX : argc_tag including number of arguments and function kind.
void StubCode::GenerateCallBootstrapNativeStub(Assembler* assembler) {
  const intptr_t native_args_struct_offset = kWordSize;
  const intptr_t thread_offset =
      NativeArguments::thread_offset() + native_args_struct_offset;
  const intptr_t argc_tag_offset =
      NativeArguments::argc_tag_offset() + native_args_struct_offset;
  const intptr_t argv_offset =
      NativeArguments::argv_offset() + native_args_struct_offset;
  const intptr_t retval_offset =
      NativeArguments::retval_offset() + native_args_struct_offset;

  __ EnterFrame(0);

  // Save exit frame information to enable stack walking as we are about
  // to transition to dart VM code.
  __ movl(Address(THR, Thread::top_exit_frame_info_offset()), EBP);

#if defined(DEBUG)
  {
    Label ok;
    // Check that we are always entering from Dart code.
    __ cmpl(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the thread is executing native code.
  __ movl(Assembler::VMTagAddress(), ECX);

  // Reserve space for the native arguments structure, the outgoing parameter
  // (pointer to the native arguments structure) and align frame before
  // entering the C++ world.
  __ AddImmediate(ESP, Immediate(-INT32_SIZEOF(NativeArguments) - kWordSize));
  if (OS::ActivationFrameAlignment() > 1) {
    __ andl(ESP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass NativeArguments structure by value and call native function.
  __ movl(Address(ESP, thread_offset), THR);    // Set thread in NativeArgs.
  __ movl(Address(ESP, argc_tag_offset), EDX);  // Set argc in NativeArguments.
  __ movl(Address(ESP, argv_offset), EAX);      // Set argv in NativeArguments.
  __ leal(EAX, Address(EBP, 2 * kWordSize));    // Compute return value addr.
  __ movl(Address(ESP, retval_offset), EAX);  // Set retval in NativeArguments.
  __ leal(EAX, Address(ESP, kWordSize));      // Pointer to the NativeArguments.
  __ movl(Address(ESP, 0), EAX);  // Pass the pointer to the NativeArguments.
  __ call(ECX);

  __ movl(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));

  // Reset exit frame information in Isolate structure.
  __ movl(Address(THR, Thread::top_exit_frame_info_offset()), Immediate(0));

  __ LeaveFrame();
  __ ret();
}

// Input parameters:
//   EDX: arguments descriptor array.
void StubCode::GenerateCallStaticFunctionStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ pushl(EDX);           // Preserve arguments descriptor array.
  __ pushl(Immediate(0));  // Setup space on stack for return value.
  __ CallRuntime(kPatchStaticCallRuntimeEntry, 0);
  __ popl(EAX);  // Get Code object result.
  __ popl(EDX);  // Restore arguments descriptor array.
  // Remove the stub frame as we are about to jump to the dart function.
  __ LeaveFrame();

  __ movl(ECX, FieldAddress(EAX, Code::entry_point_offset()));
  __ jmp(ECX);
}

// Called from a static call only when an invalid code has been entered
// (invalid because its function was optimized or deoptimized).
// EDX: arguments descriptor array.
void StubCode::GenerateFixCallersTargetStub(Assembler* assembler) {
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ pushl(EDX);           // Preserve arguments descriptor array.
  __ pushl(Immediate(0));  // Setup space on stack for return value.
  __ CallRuntime(kFixCallersTargetRuntimeEntry, 0);
  __ popl(EAX);  // Get Code object.
  __ popl(EDX);  // Restore arguments descriptor array.
  __ movl(EAX, FieldAddress(EAX, Code::entry_point_offset()));
  __ LeaveFrame();
  __ jmp(EAX);
  __ int3();
}

// Called from object allocate instruction when the allocation stub has been
// disabled.
void StubCode::GenerateFixAllocationStubTargetStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ pushl(Immediate(0));  // Setup space on stack for return value.
  __ CallRuntime(kFixAllocationStubTargetRuntimeEntry, 0);
  __ popl(EAX);  // Get Code object.
  __ movl(EAX, FieldAddress(EAX, Code::entry_point_offset()));
  __ LeaveFrame();
  __ jmp(EAX);
  __ int3();
}

// Input parameters:
//   EDX: smi-tagged argument count, may be zero.
//   EBP[kParamEndSlotFromFp + 1]: last argument.
// Uses EAX, EBX, ECX, EDX, EDI.
static void PushArgumentsArray(Assembler* assembler) {
  // Allocate array to store arguments of caller.
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movl(ECX, raw_null);  // Null element type for raw Array.
  __ Call(*StubCode::AllocateArray_entry());
  __ SmiUntag(EDX);
  // EAX: newly allocated array.
  // EDX: length of the array (was preserved by the stub).
  __ pushl(EAX);  // Array is in EAX and on top of stack.
  __ leal(EBX, Address(EBP, EDX, TIMES_4, kParamEndSlotFromFp * kWordSize));
  __ leal(ECX, FieldAddress(EAX, Array::data_offset()));
  // EBX: address of first argument on stack.
  // ECX: address of first argument in array.
  Label loop, loop_condition;
  __ jmp(&loop_condition, Assembler::kNearJump);
  __ Bind(&loop);
  __ movl(EDI, Address(EBX, 0));
  // Generational barrier is needed, array is not necessarily in new space.
  __ StoreIntoObject(EAX, Address(ECX, 0), EDI);
  __ AddImmediate(ECX, Immediate(kWordSize));
  __ AddImmediate(EBX, Immediate(-kWordSize));
  __ Bind(&loop_condition);
  __ decl(EDX);
  __ j(POSITIVE, &loop, Assembler::kNearJump);
}

// Used by eager and lazy deoptimization. Preserve result in EAX if necessary.
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
// Stack after EnterDartFrame(0) below:
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
                                           DeoptStubKind kind) {
  // Leaf runtime function DeoptimizeCopyFrame expects a Dart frame.
  __ EnterDartFrame(0);
  // The code in this frame may not cause GC. kDeoptimizeCopyFrameRuntimeEntry
  // and kDeoptimizeFillFrameRuntimeEntry are leaf runtime calls.
  const intptr_t saved_result_slot_from_fp =
      kFirstLocalSlotFromFp + 1 - (kNumberOfCpuRegisters - EAX);
  const intptr_t saved_exception_slot_from_fp =
      kFirstLocalSlotFromFp + 1 - (kNumberOfCpuRegisters - EAX);
  const intptr_t saved_stacktrace_slot_from_fp =
      kFirstLocalSlotFromFp + 1 - (kNumberOfCpuRegisters - EDX);
  // Result in EAX is preserved as part of pushing all registers below.

  // Push registers in their enumeration order: lowest register number at
  // lowest address.
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; i--) {
    if (i == CODE_REG) {
      // Save the original value of CODE_REG pushed before invoking this stub
      // instead of the value used to call this stub.
      __ pushl(Address(EBP, 2 * kWordSize));
    } else {
      __ pushl(static_cast<Register>(i));
    }
  }
  __ subl(ESP, Immediate(kNumberOfXmmRegisters * kFpuRegisterSize));
  intptr_t offset = 0;
  for (intptr_t reg_idx = 0; reg_idx < kNumberOfXmmRegisters; ++reg_idx) {
    XmmRegister xmm_reg = static_cast<XmmRegister>(reg_idx);
    __ movups(Address(ESP, offset), xmm_reg);
    offset += kFpuRegisterSize;
  }

  __ movl(ECX, ESP);  // Preserve saved registers block.
  __ ReserveAlignedFrameSpace(2 * kWordSize);
  __ movl(Address(ESP, 0 * kWordSize), ECX);  // Start of register block.
  bool is_lazy =
      (kind == kLazyDeoptFromReturn) || (kind == kLazyDeoptFromThrow);
  __ movl(Address(ESP, 1 * kWordSize), Immediate(is_lazy ? 1 : 0));
  __ CallRuntime(kDeoptimizeCopyFrameRuntimeEntry, 2);
  // Result (EAX) is stack-size (FP - SP) in bytes.

  if (kind == kLazyDeoptFromReturn) {
    // Restore result into EBX temporarily.
    __ movl(EBX, Address(EBP, saved_result_slot_from_fp * kWordSize));
  } else if (kind == kLazyDeoptFromThrow) {
    // Restore result into EBX temporarily.
    __ movl(EBX, Address(EBP, saved_exception_slot_from_fp * kWordSize));
    __ movl(ECX, Address(EBP, saved_stacktrace_slot_from_fp * kWordSize));
  }

  __ LeaveFrame();
  __ popl(EDX);       // Preserve return address.
  __ movl(ESP, EBP);  // Discard optimized frame.
  __ subl(ESP, EAX);  // Reserve space for deoptimized frame.
  __ pushl(EDX);      // Restore return address.

  // Leaf runtime function DeoptimizeFillFrame expects a Dart frame.
  __ EnterDartFrame(0);
  if (kind == kLazyDeoptFromReturn) {
    __ pushl(EBX);  // Preserve result as first local.
  } else if (kind == kLazyDeoptFromThrow) {
    __ pushl(EBX);  // Preserve exception as first local.
    __ pushl(ECX);  // Preserve stacktrace as first local.
  }
  __ ReserveAlignedFrameSpace(1 * kWordSize);
  __ movl(Address(ESP, 0), EBP);  // Pass last FP as parameter on stack.
  __ CallRuntime(kDeoptimizeFillFrameRuntimeEntry, 1);
  if (kind == kLazyDeoptFromReturn) {
    // Restore result into EBX.
    __ movl(EBX, Address(EBP, kFirstLocalSlotFromFp * kWordSize));
  } else if (kind == kLazyDeoptFromThrow) {
    // Restore result into EBX.
    __ movl(EBX, Address(EBP, kFirstLocalSlotFromFp * kWordSize));
    __ movl(ECX, Address(EBP, (kFirstLocalSlotFromFp - 1) * kWordSize));
  }
  // Code above cannot cause GC.
  __ LeaveFrame();

  // Frame is fully rewritten at this point and it is safe to perform a GC.
  // Materialize any objects that were deferred by FillFrame because they
  // require allocation.
  __ EnterStubFrame();
  if (kind == kLazyDeoptFromReturn) {
    __ pushl(EBX);  // Preserve result, it will be GC-d here.
  } else if (kind == kLazyDeoptFromThrow) {
    __ pushl(EBX);  // Preserve exception, it will be GC-d here.
    __ pushl(ECX);  // Preserve stacktrace, it will be GC-d here.
  }
  __ pushl(Immediate(Smi::RawValue(0)));  // Space for the result.
  __ CallRuntime(kDeoptimizeMaterializeRuntimeEntry, 0);
  // Result tells stub how many bytes to remove from the expression stack
  // of the bottom-most frame. They were used as materialization arguments.
  __ popl(EBX);
  __ SmiUntag(EBX);
  if (kind == kLazyDeoptFromReturn) {
    __ popl(EAX);  // Restore result.
  } else if (kind == kLazyDeoptFromThrow) {
    __ popl(EDX);  // Restore exception.
    __ popl(EAX);  // Restore stacktrace.
  }
  __ LeaveFrame();

  __ popl(ECX);       // Pop return address.
  __ addl(ESP, EBX);  // Remove materialization arguments.
  __ pushl(ECX);      // Push return address.
  // The caller is responsible for emitting the return instruction.
}

// EAX: result, must be preserved
void StubCode::GenerateDeoptimizeLazyFromReturnStub(Assembler* assembler) {
  // Return address for "call" to deopt stub.
  __ pushl(Immediate(kZapReturnAddress));
  GenerateDeoptimizationSequence(assembler, kLazyDeoptFromReturn);
  __ ret();
}

// EAX: exception, must be preserved
// EDX: stacktrace, must be preserved
void StubCode::GenerateDeoptimizeLazyFromThrowStub(Assembler* assembler) {
  // Return address for "call" to deopt stub.
  __ pushl(Immediate(kZapReturnAddress));
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
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ cmpl(EAX, raw_null);
  __ j(NOT_EQUAL, call_target_function);
  __ EnterStubFrame();
  // Load the receiver.
  __ movl(EDI, FieldAddress(EDX, ArgumentsDescriptor::count_offset()));
  __ movl(EAX, Address(EBP, EDI, TIMES_HALF_WORD_SIZE,
                       kParamEndSlotFromFp * kWordSize));
  __ pushl(Immediate(0));  // Setup space on stack for result.
  __ pushl(EAX);           // Receiver.
  __ pushl(ECX);           // ICData/MegamorphicCache.
  __ pushl(EDX);           // Arguments descriptor array.

  // Adjust arguments count.
  __ cmpl(FieldAddress(EDX, ArgumentsDescriptor::type_args_len_offset()),
          Immediate(0));
  __ movl(EDX, EDI);
  Label args_count_ok;
  __ j(EQUAL, &args_count_ok, Assembler::kNearJump);
  __ addl(EDX, Immediate(Smi::RawValue(1)));  // Include the type arguments.
  __ Bind(&args_count_ok);

  // EDX: Smi-tagged arguments array length.
  PushArgumentsArray(assembler);
  const intptr_t kNumArgs = 4;
  __ CallRuntime(kInvokeNoSuchMethodDispatcherRuntimeEntry, kNumArgs);
  __ Drop(4);
  __ popl(EAX);  // Return value.
  __ LeaveFrame();
  __ ret();
}

void StubCode::GenerateMegamorphicMissStub(Assembler* assembler) {
  __ EnterStubFrame();
  // Load the receiver into EAX.  The argument count in the arguments
  // descriptor in EDX is a smi.
  __ movl(EAX, FieldAddress(EDX, ArgumentsDescriptor::count_offset()));
  // Two words (saved fp, stub's pc marker) in the stack above the return
  // address.
  __ movl(EAX, Address(ESP, EAX, TIMES_2, 2 * kWordSize));
  // Preserve IC data and arguments descriptor.
  __ pushl(ECX);
  __ pushl(EDX);

  __ pushl(Immediate(0));  // Space for the result of the runtime call.
  __ pushl(EAX);           // Pass receiver.
  __ pushl(ECX);           // Pass IC data.
  __ pushl(EDX);           // Pass arguments descriptor.
  __ CallRuntime(kMegamorphicCacheMissHandlerRuntimeEntry, 3);
  // Discard arguments.
  __ popl(EAX);
  __ popl(EAX);
  __ popl(EAX);
  __ popl(EAX);  // Return value from the runtime call (function).
  __ popl(EDX);  // Restore arguments descriptor.
  __ popl(ECX);  // Restore IC data.
  __ LeaveFrame();

  if (!FLAG_lazy_dispatchers) {
    Label call_target_function;
    GenerateDispatcherCode(assembler, &call_target_function);
    __ Bind(&call_target_function);
  }

  __ movl(EBX, FieldAddress(EAX, Function::entry_point_offset()));
  __ jmp(EBX);
}

// Called for inline allocation of arrays.
// Input parameters:
//   EDX : Array length as Smi (must be preserved).
//   ECX : array element type (either NULL or an instantiated type).
// Uses EAX, EBX, ECX, EDI  as temporary registers.
// The newly allocated object is returned in EAX.
void StubCode::GenerateAllocateArrayStub(Assembler* assembler) {
  Label slow_case;
  // Compute the size to be allocated, it is based on the array length
  // and is computed as:
  // RoundedAllocationSize((array_length * kwordSize) + sizeof(RawArray)).
  // Assert that length is a Smi.
  __ testl(EDX, Immediate(kSmiTagMask));

  if (FLAG_use_slow_path) {
    __ jmp(&slow_case);
  } else {
    __ j(NOT_ZERO, &slow_case);
  }
  __ cmpl(EDX, Immediate(0));
  __ j(LESS, &slow_case);

  // Check for maximum allowed length.
  const Immediate& max_len =
      Immediate(reinterpret_cast<int32_t>(Smi::New(Array::kMaxElements)));
  __ cmpl(EDX, max_len);
  __ j(GREATER, &slow_case);

  NOT_IN_PRODUCT(
      __ MaybeTraceAllocation(kArrayCid, EAX, &slow_case, Assembler::kFarJump));

  const intptr_t fixed_size_plus_alignment_padding =
      sizeof(RawArray) + kObjectAlignment - 1;
  // EDX is Smi.
  __ leal(EBX, Address(EDX, TIMES_2, fixed_size_plus_alignment_padding));
  ASSERT(kSmiTagShift == 1);
  __ andl(EBX, Immediate(-kObjectAlignment));

  // ECX: array element type.
  // EDX: array length as Smi.
  // EBX: allocation size.

  const intptr_t cid = kArrayCid;
  NOT_IN_PRODUCT(Heap::Space space = Heap::kNew);
  __ movl(EAX, Address(THR, Thread::top_offset()));
  __ addl(EBX, EAX);
  __ j(CARRY, &slow_case);

  // Check if the allocation fits into the remaining space.
  // EAX: potential new object start.
  // EBX: potential next object start.
  // ECX: array element type.
  // EDX: array length as Smi).
  __ cmpl(EBX, Address(THR, Thread::end_offset()));
  __ j(ABOVE_EQUAL, &slow_case);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  __ movl(Address(THR, Thread::top_offset()), EBX);
  __ subl(EBX, EAX);
  __ addl(EAX, Immediate(kHeapObjectTag));
  NOT_IN_PRODUCT(__ UpdateAllocationStatsWithSize(cid, EBX, EDI, space));

  // Initialize the tags.
  // EAX: new object start as a tagged pointer.
  // EBX: allocation size.
  // ECX: array element type.
  // EDX: array length as Smi.
  {
    Label size_tag_overflow, done;
    __ movl(EDI, EBX);
    __ cmpl(EDI, Immediate(RawObject::SizeTag::kMaxSizeTag));
    __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
    __ shll(EDI, Immediate(RawObject::kSizeTagPos - kObjectAlignmentLog2));
    __ jmp(&done, Assembler::kNearJump);

    __ Bind(&size_tag_overflow);
    __ movl(EDI, Immediate(0));
    __ Bind(&done);

    // Get the class index and insert it into the tags.
    __ orl(EDI, Immediate(RawObject::ClassIdTag::encode(cid)));
    __ movl(FieldAddress(EAX, Array::tags_offset()), EDI);  // Tags.
  }
  // EAX: new object start as a tagged pointer.
  // EBX: allocation size.
  // ECX: array element type.
  // EDX: Array length as Smi (preserved).
  // Store the type argument field.
  // No generational barrier needed, since we store into a new object.
  __ StoreIntoObjectNoBarrier(
      EAX, FieldAddress(EAX, Array::type_arguments_offset()), ECX);

  // Set the length field.
  __ StoreIntoObjectNoBarrier(EAX, FieldAddress(EAX, Array::length_offset()),
                              EDX);

  // Initialize all array elements to raw_null.
  // EAX: new object start as a tagged pointer.
  // EBX: allocation size.
  // EDI: iterator which initially points to the start of the variable
  // data area to be initialized.
  // ECX: array element type.
  // EDX: array length as Smi.
  __ leal(EBX, FieldAddress(EAX, EBX, TIMES_1, 0));
  __ leal(EDI, FieldAddress(EAX, sizeof(RawArray)));
  Label done;
  Label init_loop;
  __ Bind(&init_loop);
  __ cmpl(EDI, EBX);
  __ j(ABOVE_EQUAL, &done, Assembler::kNearJump);
  // No generational barrier needed, since we are storing null.
  __ StoreIntoObjectNoBarrier(EAX, Address(EDI, 0), Object::null_object());
  __ addl(EDI, Immediate(kWordSize));
  __ jmp(&init_loop, Assembler::kNearJump);
  __ Bind(&done);
  __ ret();  // returns the newly allocated object in EAX.

  // Unable to allocate the array using the fast inline code, just call
  // into the runtime.
  __ Bind(&slow_case);
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ pushl(Immediate(0));  // Setup space on stack for return value.
  __ pushl(EDX);           // Array length as Smi.
  __ pushl(ECX);           // Element type.
  __ CallRuntime(kAllocateArrayRuntimeEntry, 2);
  __ popl(EAX);  // Pop element type argument.
  __ popl(EDX);  // Pop array length argument (preserved).
  __ popl(EAX);  // Pop return value from return slot.
  __ LeaveFrame();
  __ ret();
}

// Called when invoking dart code from C++ (VM code).
// Input parameters:
//   ESP : points to return address.
//   ESP + 4 : code object of the dart function to call.
//   ESP + 8 : arguments descriptor array.
//   ESP + 12 : arguments array.
//   ESP + 16 : current thread.
// Uses EAX, EDX, ECX, EDI as temporary registers.
void StubCode::GenerateInvokeDartCodeStub(Assembler* assembler) {
  const intptr_t kTargetCodeOffset = 2 * kWordSize;
  const intptr_t kArgumentsDescOffset = 3 * kWordSize;
  const intptr_t kArgumentsOffset = 4 * kWordSize;
  const intptr_t kThreadOffset = 5 * kWordSize;

  // Save frame pointer coming in.
  __ EnterFrame(0);

  // Push code object to PC marker slot.
  __ movl(EAX, Address(EBP, kThreadOffset));
  __ pushl(Address(EAX, Thread::invoke_dart_code_stub_offset()));

  // Save C++ ABI callee-saved registers.
  __ pushl(EBX);
  __ pushl(ESI);
  __ pushl(EDI);

  // Set up THR, which caches the current thread in Dart code.
  __ movl(THR, EAX);

  // Save the current VMTag on the stack.
  __ movl(ECX, Assembler::VMTagAddress());
  __ pushl(ECX);

  // Mark that the thread is executing Dart code.
  __ movl(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));

  // Save top resource and top exit frame info. Use EDX as a temporary register.
  // StackFrameIterator reads the top exit frame info saved in this frame.
  __ movl(EDX, Address(THR, Thread::top_resource_offset()));
  __ pushl(EDX);
  __ movl(Address(THR, Thread::top_resource_offset()), Immediate(0));
  // The constant kExitLinkSlotFromEntryFp must be kept in sync with the
  // code below.
  ASSERT(kExitLinkSlotFromEntryFp == -7);
  __ movl(EDX, Address(THR, Thread::top_exit_frame_info_offset()));
  __ pushl(EDX);
  __ movl(Address(THR, Thread::top_exit_frame_info_offset()), Immediate(0));

  // Load arguments descriptor array into EDX.
  __ movl(EDX, Address(EBP, kArgumentsDescOffset));
  __ movl(EDX, Address(EDX, VMHandles::kOffsetOfRawPtrInHandle));

  // No need to check for type args, disallowed by DartEntry::InvokeFunction.
  // Load number of arguments into EBX.
  __ movl(EBX, FieldAddress(EDX, ArgumentsDescriptor::count_offset()));
  __ SmiUntag(EBX);

  // Set up arguments for the dart call.
  Label push_arguments;
  Label done_push_arguments;
  __ testl(EBX, EBX);  // check if there are arguments.
  __ j(ZERO, &done_push_arguments, Assembler::kNearJump);
  __ movl(EAX, Immediate(0));

  // Compute address of 'arguments array' data area into EDI.
  __ movl(EDI, Address(EBP, kArgumentsOffset));
  __ movl(EDI, Address(EDI, VMHandles::kOffsetOfRawPtrInHandle));
  __ leal(EDI, FieldAddress(EDI, Array::data_offset()));

  __ Bind(&push_arguments);
  __ movl(ECX, Address(EDI, EAX, TIMES_4, 0));
  __ pushl(ECX);
  __ incl(EAX);
  __ cmpl(EAX, EBX);
  __ j(LESS, &push_arguments, Assembler::kNearJump);
  __ Bind(&done_push_arguments);

  // Call the dart code entrypoint.
  __ movl(EAX, Address(EBP, kTargetCodeOffset));
  __ movl(EAX, Address(EAX, VMHandles::kOffsetOfRawPtrInHandle));
  __ call(FieldAddress(EAX, Code::entry_point_offset()));

  // Reread the arguments descriptor array to obtain the number of passed
  // arguments.
  __ movl(EDX, Address(EBP, kArgumentsDescOffset));
  __ movl(EDX, Address(EDX, VMHandles::kOffsetOfRawPtrInHandle));
  __ movl(EDX, FieldAddress(EDX, ArgumentsDescriptor::count_offset()));
  // Get rid of arguments pushed on the stack.
  __ leal(ESP, Address(ESP, EDX, TIMES_2, 0));  // EDX is a Smi.

  // Restore the saved top exit frame info and top resource back into the
  // Isolate structure.
  __ popl(Address(THR, Thread::top_exit_frame_info_offset()));
  __ popl(Address(THR, Thread::top_resource_offset()));

  // Restore the current VMTag from the stack.
  __ popl(Assembler::VMTagAddress());

  // Restore C++ ABI callee-saved registers.
  __ popl(EDI);
  __ popl(ESI);
  __ popl(EBX);

  // Restore the frame pointer.
  __ LeaveFrame();

  __ ret();
}

// Called for inline allocation of contexts.
// Input:
// EDX: number of context variables.
// Output:
// EAX: new allocated RawContext object.
// EBX and EDX are destroyed.
void StubCode::GenerateAllocateContextStub(Assembler* assembler) {
  if (FLAG_inline_alloc) {
    Label slow_case;
    // First compute the rounded instance size.
    // EDX: number of context variables.
    intptr_t fixed_size_plus_alignment_padding =
        (sizeof(RawContext) + kObjectAlignment - 1);
    __ leal(EBX, Address(EDX, TIMES_4, fixed_size_plus_alignment_padding));
    __ andl(EBX, Immediate(-kObjectAlignment));

    NOT_IN_PRODUCT(__ MaybeTraceAllocation(kContextCid, EAX, &slow_case,
                                           Assembler::kFarJump));

    // Now allocate the object.
    // EDX: number of context variables.
    const intptr_t cid = kContextCid;
    NOT_IN_PRODUCT(Heap::Space space = Heap::kNew);
    __ movl(EAX, Address(THR, Thread::top_offset()));
    __ addl(EBX, EAX);
    // Check if the allocation fits into the remaining space.
    // EAX: potential new object.
    // EBX: potential next object start.
    // EDX: number of context variables.
    __ cmpl(EBX, Address(THR, Thread::end_offset()));
    if (FLAG_use_slow_path) {
      __ jmp(&slow_case);
    } else {
#if defined(DEBUG)
      static const bool kJumpLength = Assembler::kFarJump;
#else
      static const bool kJumpLength = Assembler::kNearJump;
#endif  // DEBUG
      __ j(ABOVE_EQUAL, &slow_case, kJumpLength);
    }

    // Successfully allocated the object, now update top to point to
    // next object start and initialize the object.
    // EAX: new object.
    // EBX: next object start.
    // EDX: number of context variables.
    __ movl(Address(THR, Thread::top_offset()), EBX);
    // EBX: Size of allocation in bytes.
    __ subl(EBX, EAX);
    __ addl(EAX, Immediate(kHeapObjectTag));
    // Generate isolate-independent code to allow sharing between isolates.
    NOT_IN_PRODUCT(__ UpdateAllocationStatsWithSize(cid, EBX, EDI, space));

    // Calculate the size tag.
    // EAX: new object.
    // EDX: number of context variables.
    {
      Label size_tag_overflow, done;
      __ leal(EBX, Address(EDX, TIMES_4, fixed_size_plus_alignment_padding));
      __ andl(EBX, Immediate(-kObjectAlignment));
      __ cmpl(EBX, Immediate(RawObject::SizeTag::kMaxSizeTag));
      __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
      __ shll(EBX, Immediate(RawObject::kSizeTagPos - kObjectAlignmentLog2));
      __ jmp(&done);

      __ Bind(&size_tag_overflow);
      // Set overflow size tag value.
      __ movl(EBX, Immediate(0));

      __ Bind(&done);
      // EAX: new object.
      // EDX: number of context variables.
      // EBX: size and bit tags.
      __ orl(EBX, Immediate(RawObject::ClassIdTag::encode(cid)));
      __ movl(FieldAddress(EAX, Context::tags_offset()), EBX);  // Tags.
    }

    // Setup up number of context variables field.
    // EAX: new object.
    // EDX: number of context variables as integer value (not object).
    __ movl(FieldAddress(EAX, Context::num_variables_offset()), EDX);

    // Setup the parent field.
    // EAX: new object.
    // EDX: number of context variables.
    // No generational barrier needed, since we are storing null.
    __ StoreIntoObjectNoBarrier(EAX,
                                FieldAddress(EAX, Context::parent_offset()),
                                Object::null_object());

    // Initialize the context variables.
    // EAX: new object.
    // EDX: number of context variables.
    {
      Label loop, entry;
      __ leal(EBX, FieldAddress(EAX, Context::variable_offset(0)));

      __ jmp(&entry, Assembler::kNearJump);
      __ Bind(&loop);
      __ decl(EDX);
      // No generational barrier needed, since we are storing null.
      __ StoreIntoObjectNoBarrier(EAX, Address(EBX, EDX, TIMES_4, 0),
                                  Object::null_object());
      __ Bind(&entry);
      __ cmpl(EDX, Immediate(0));
      __ j(NOT_EQUAL, &loop, Assembler::kNearJump);
    }

    // Done allocating and initializing the context.
    // EAX: new object.
    __ ret();

    __ Bind(&slow_case);
  }
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ pushl(Immediate(0));  // Setup space on stack for return value.
  __ SmiTag(EDX);
  __ pushl(EDX);
  __ CallRuntime(kAllocateContextRuntimeEntry, 1);  // Allocate context.
  __ popl(EAX);  // Pop number of context variables argument.
  __ popl(EAX);  // Pop the new context object.
  // EAX: new object
  // Restore the frame pointer.
  __ LeaveFrame();
  __ ret();
}

// Helper stub to implement Assembler::StoreIntoObject.
// Input parameters:
//   EDX: Address being stored
void StubCode::GenerateUpdateStoreBufferStub(Assembler* assembler) {
  // Save values being destroyed.
  __ pushl(EAX);
  __ pushl(ECX);

  Label add_to_buffer;
  // Check whether this object has already been remembered. Skip adding to the
  // store buffer if the object is in the store buffer already.
  // Spilled: EAX, ECX
  // EDX: Address being stored
  Label reload;
  __ Bind(&reload);
  __ movl(EAX, FieldAddress(EDX, Object::tags_offset()));
  __ testl(EAX, Immediate(1 << RawObject::kRememberedBit));
  __ j(EQUAL, &add_to_buffer, Assembler::kNearJump);
  __ popl(ECX);
  __ popl(EAX);
  __ ret();

  // Update the tags that this object has been remembered.
  // EDX: Address being stored
  // EAX: Current tag value
  __ Bind(&add_to_buffer);
  __ movl(ECX, EAX);
  __ orl(ECX, Immediate(1 << RawObject::kRememberedBit));
  // Compare the tag word with EAX, update to ECX if unchanged.
  __ LockCmpxchgl(FieldAddress(EDX, Object::tags_offset()), ECX);
  __ j(NOT_EQUAL, &reload);

  // Load the StoreBuffer block out of the thread. Then load top_ out of the
  // StoreBufferBlock and add the address to the pointers_.
  // Spilled: EAX, ECX
  // EDX: Address being stored
  __ movl(EAX, Address(THR, Thread::store_buffer_block_offset()));
  __ movl(ECX, Address(EAX, StoreBufferBlock::top_offset()));
  __ movl(Address(EAX, ECX, TIMES_4, StoreBufferBlock::pointers_offset()), EDX);

  // Increment top_ and check for overflow.
  // Spilled: EAX, ECX
  // ECX: top_
  // EAX: StoreBufferBlock
  Label L;
  __ incl(ECX);
  __ movl(Address(EAX, StoreBufferBlock::top_offset()), ECX);
  __ cmpl(ECX, Immediate(StoreBufferBlock::kSize));
  // Restore values.
  // Spilled: EAX, ECX
  __ popl(ECX);
  __ popl(EAX);
  __ j(EQUAL, &L, Assembler::kNearJump);
  __ ret();

  // Handle overflow: Call the runtime leaf function.
  __ Bind(&L);
  // Setup frame, push callee-saved registers.

  __ EnterCallRuntimeFrame(1 * kWordSize);
  __ movl(Address(ESP, 0), THR);  // Push the thread as the only argument.
  __ CallRuntime(kStoreBufferBlockProcessRuntimeEntry, 1);
  // Restore callee-saved registers, tear down frame.
  __ LeaveCallRuntimeFrame();
  __ ret();
}

// Called for inline allocation of objects.
// Input parameters:
//   ESP + 4 : type arguments object (only if class is parameterized).
//   ESP : points to return address.
// Uses EAX, EBX, ECX, EDX, EDI as temporary registers.
// Returns patch_code_pc offset where patching code for disabling the stub
// has been generated (similar to regularly generated Dart code).
void StubCode::GenerateAllocationStubForClass(Assembler* assembler,
                                              const Class& cls) {
  const intptr_t kObjectTypeArgumentsOffset = 1 * kWordSize;
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
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
  if (is_cls_parameterized) {
    __ movl(EDX, Address(ESP, kObjectTypeArgumentsOffset));
    // EDX: instantiated type arguments.
  }
  Isolate* isolate = Isolate::Current();
  if (FLAG_inline_alloc && Heap::IsAllocatableInNewSpace(instance_size) &&
      !cls.TraceAllocation(isolate)) {
    Label slow_case;
    // Allocate the object and update top to point to
    // next object start and initialize the allocated object.
    // EDX: instantiated type arguments (if is_cls_parameterized).
    NOT_IN_PRODUCT(Heap::Space space = Heap::kNew);
    __ movl(EAX, Address(THR, Thread::top_offset()));
    __ leal(EBX, Address(EAX, instance_size));
    // Check if the allocation fits into the remaining space.
    // EAX: potential new object start.
    // EBX: potential next object start.
    __ cmpl(EBX, Address(THR, Thread::end_offset()));
    if (FLAG_use_slow_path) {
      __ jmp(&slow_case);
    } else {
      __ j(ABOVE_EQUAL, &slow_case);
    }
    __ movl(Address(THR, Thread::top_offset()), EBX);
    NOT_IN_PRODUCT(__ UpdateAllocationStats(cls.id(), ECX, space));

    // EAX: new object start (untagged).
    // EBX: next object start.
    // EDX: new object type arguments (if is_cls_parameterized).
    // Set the tags.
    uint32_t tags = 0;
    tags = RawObject::SizeTag::update(instance_size, tags);
    ASSERT(cls.id() != kIllegalCid);
    tags = RawObject::ClassIdTag::update(cls.id(), tags);
    __ movl(Address(EAX, Instance::tags_offset()), Immediate(tags));
    __ addl(EAX, Immediate(kHeapObjectTag));

    // Initialize the remaining words of the object.

    // EAX: new object (tagged).
    // EBX: next object start.
    // EDX: new object type arguments (if is_cls_parameterized).
    // First try inlining the initialization without a loop.
    if (instance_size < (kInlineInstanceSize * kWordSize)) {
      // Check if the object contains any non-header fields.
      // Small objects are initialized using a consecutive set of writes.
      for (intptr_t current_offset = Instance::NextFieldOffset();
           current_offset < instance_size; current_offset += kWordSize) {
        __ StoreIntoObjectNoBarrier(EAX, FieldAddress(EAX, current_offset),
                                    Object::null_object());
      }
    } else {
      __ leal(ECX, FieldAddress(EAX, Instance::NextFieldOffset()));
      // Loop until the whole object is initialized.
      // EAX: new object (tagged).
      // EBX: next object start.
      // ECX: next word to be initialized.
      // EDX: new object type arguments (if is_cls_parameterized).
      Label init_loop;
      Label done;
      __ Bind(&init_loop);
      __ cmpl(ECX, EBX);
      __ j(ABOVE_EQUAL, &done, Assembler::kNearJump);
      __ StoreIntoObjectNoBarrier(EAX, Address(ECX, 0), Object::null_object());
      __ addl(ECX, Immediate(kWordSize));
      __ jmp(&init_loop, Assembler::kNearJump);
      __ Bind(&done);
    }
    if (is_cls_parameterized) {
      // EAX: new object (tagged).
      // EDX: new object type arguments.
      // Set the type arguments in the new object.
      intptr_t offset = cls.type_arguments_field_offset();
      __ StoreIntoObjectNoBarrier(EAX, FieldAddress(EAX, offset), EDX);
    }
    // Done allocating and initializing the instance.
    // EAX: new object (tagged).
    __ ret();

    __ Bind(&slow_case);
  }
  // If is_cls_parameterized:
  // EDX: new object type arguments.
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ pushl(raw_null);  // Setup space on stack for return value.
  __ PushObject(cls);  // Push class of object to be allocated.
  if (is_cls_parameterized) {
    __ pushl(EDX);  // Push type arguments of object to be allocated.
  } else {
    __ pushl(raw_null);  // Push null type arguments.
  }
  __ CallRuntime(kAllocateObjectRuntimeEntry, 2);  // Allocate object.
  __ popl(EAX);  // Pop argument (type arguments of object).
  __ popl(EAX);  // Pop argument (class of object).
  __ popl(EAX);  // Pop result (newly allocated object).
  // EAX: new object
  // Restore the frame pointer.
  __ LeaveFrame();
  __ ret();
}

// Called for invoking "dynamic noSuchMethod(Invocation invocation)" function
// from the entry code of a dart function after an error in passed argument
// name or number is detected.
// Input parameters:
//   ESP : points to return address.
//   ESP + 4 : address of last argument.
//   EDX : arguments descriptor array.
// Uses EAX, EBX, EDI as temporary registers.
void StubCode::GenerateCallClosureNoSuchMethodStub(Assembler* assembler) {
  __ EnterStubFrame();

  // Load the receiver.
  __ movl(EDI, FieldAddress(EDX, ArgumentsDescriptor::count_offset()));
  __ movl(EAX, Address(EBP, EDI, TIMES_2, kParamEndSlotFromFp * kWordSize));

  __ pushl(Immediate(0));  // Setup space on stack for result from noSuchMethod.
  __ pushl(EAX);           // Receiver.
  __ pushl(EDX);           // Arguments descriptor array.

  // Adjust arguments count.
  __ cmpl(FieldAddress(EDX, ArgumentsDescriptor::type_args_len_offset()),
          Immediate(0));
  __ movl(EDX, EDI);
  Label args_count_ok;
  __ j(EQUAL, &args_count_ok, Assembler::kNearJump);
  __ addl(EDX, Immediate(Smi::RawValue(1)));  // Include the type arguments.
  __ Bind(&args_count_ok);

  // EDX: Smi-tagged arguments array length.
  PushArgumentsArray(assembler);

  const intptr_t kNumArgs = 3;
  __ CallRuntime(kInvokeClosureNoSuchMethodRuntimeEntry, kNumArgs);
  // noSuchMethod on closures always throws an error, so it will never return.
  __ int3();
}

// Cannot use function object from ICData as it may be the inlined
// function and not the top-scope function.
void StubCode::GenerateOptimizedUsageCounterIncrement(Assembler* assembler) {
  Register ic_reg = ECX;
  Register func_reg = EBX;
  if (FLAG_trace_optimized_ic_calls) {
    __ EnterStubFrame();
    __ pushl(func_reg);  // Preserve
    __ pushl(ic_reg);    // Preserve.
    __ pushl(ic_reg);    // Argument.
    __ pushl(func_reg);  // Argument.
    __ CallRuntime(kTraceICCallRuntimeEntry, 2);
    __ popl(EAX);       // Discard argument;
    __ popl(EAX);       // Discard argument;
    __ popl(ic_reg);    // Restore.
    __ popl(func_reg);  // Restore.
    __ LeaveFrame();
  }
  __ incl(FieldAddress(func_reg, Function::usage_counter_offset()));
}

// Loads function into 'temp_reg'.
void StubCode::GenerateUsageCounterIncrement(Assembler* assembler,
                                             Register temp_reg) {
  if (FLAG_optimization_counter_threshold >= 0) {
    Register ic_reg = ECX;
    Register func_reg = temp_reg;
    ASSERT(ic_reg != func_reg);
    __ Comment("Increment function counter");
    __ movl(func_reg, FieldAddress(ic_reg, ICData::owner_offset()));
    __ incl(FieldAddress(func_reg, Function::usage_counter_offset()));
  }
}

// Note: ECX must be preserved.
// Attempt a quick Smi operation for known operations ('kind'). The ICData
// must have been primed with a Smi/Smi check that will be used for counting
// the invocations.
static void EmitFastSmiOp(Assembler* assembler,
                          Token::Kind kind,
                          intptr_t num_args,
                          Label* not_smi_or_overflow) {
  __ Comment("Fast Smi op");
  ASSERT(num_args == 2);
  __ movl(EDI, Address(ESP, +1 * kWordSize));  // Right
  __ movl(EAX, Address(ESP, +2 * kWordSize));  // Left
  __ movl(EBX, EDI);
  __ orl(EBX, EAX);
  __ testl(EBX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, not_smi_or_overflow, Assembler::kNearJump);
  switch (kind) {
    case Token::kADD: {
      __ addl(EAX, EDI);
      __ j(OVERFLOW, not_smi_or_overflow, Assembler::kNearJump);
      break;
    }
    case Token::kSUB: {
      __ subl(EAX, EDI);
      __ j(OVERFLOW, not_smi_or_overflow, Assembler::kNearJump);
      break;
    }
    case Token::kMUL: {
      __ SmiUntag(EAX);
      __ imull(EAX, EDI);
      __ j(OVERFLOW, not_smi_or_overflow, Assembler::kNearJump);
      break;
    }
    case Token::kEQ: {
      Label done, is_true;
      __ cmpl(EAX, EDI);
      __ j(EQUAL, &is_true, Assembler::kNearJump);
      __ LoadObject(EAX, Bool::False());
      __ jmp(&done, Assembler::kNearJump);
      __ Bind(&is_true);
      __ LoadObject(EAX, Bool::True());
      __ Bind(&done);
      break;
    }
    default:
      UNIMPLEMENTED();
  }

  // ECX: IC data object.
  __ movl(EBX, FieldAddress(ECX, ICData::ic_data_offset()));
  // EBX: ic_data_array with check entries: classes and target functions.
  __ leal(EBX, FieldAddress(EBX, Array::data_offset()));
#if defined(DEBUG)
  // Check that first entry is for Smi/Smi.
  Label error, ok;
  const Immediate& imm_smi_cid =
      Immediate(reinterpret_cast<intptr_t>(Smi::New(kSmiCid)));
  __ cmpl(Address(EBX, 0 * kWordSize), imm_smi_cid);
  __ j(NOT_EQUAL, &error, Assembler::kNearJump);
  __ cmpl(Address(EBX, 1 * kWordSize), imm_smi_cid);
  __ j(EQUAL, &ok, Assembler::kNearJump);
  __ Bind(&error);
  __ Stop("Incorrect IC data");
  __ Bind(&ok);
#endif
  if (FLAG_optimization_counter_threshold >= 0) {
    const intptr_t count_offset = ICData::CountIndexFor(num_args) * kWordSize;
    // Update counter, ignore overflow.
    __ addl(Address(EBX, count_offset), Immediate(Smi::RawValue(1)));
  }
  __ ret();
}

// Generate inline cache check for 'num_args'.
//  ECX: Inline cache data object.
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
    __ movl(EBX, FieldAddress(ECX, ICData::state_bits_offset()));
    ASSERT(ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ andl(EBX, Immediate(ICData::NumArgsTestedMask()));
    __ cmpl(EBX, Immediate(num_args));
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Incorrect stub for IC data");
    __ Bind(&ok);
  }
#endif  // DEBUG

#if !defined(PRODUCT)
  Label stepping, done_stepping;
  if (!optimized) {
    __ Comment("Check single stepping");
    __ LoadIsolate(EAX);
    __ cmpb(Address(EAX, Isolate::single_step_offset()), Immediate(0));
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
  // ECX: IC data object (preserved).
  // Load arguments descriptor into EDX.
  __ movl(EDX, FieldAddress(ECX, ICData::arguments_descriptor_offset()));
  // Loop that checks if there is an IC data match.
  Label loop, found, miss;
  // ECX: IC data object (preserved).
  __ movl(EBX, FieldAddress(ECX, ICData::ic_data_offset()));
  // EBX: ic_data_array with check entries: classes and target functions.
  __ leal(EBX, FieldAddress(EBX, Array::data_offset()));
  // EBX: points directly to the first ic data array element.

  // Get argument descriptor into EAX.  In the 1-argument case this is the
  // last time we need the argument descriptor, and we reuse EAX for the
  // class IDs from the IC descriptor.  In the 2-argument case we preserve
  // the argument descriptor in EAX.
  __ movl(EAX, FieldAddress(EDX, ArgumentsDescriptor::count_offset()));
  if (num_args == 1) {
    // Load receiver into EDI.
    __ movl(EDI,
            Address(ESP, EAX, TIMES_2, 0));  // EAX (argument count) is Smi.
    __ LoadTaggedClassIdMayBeSmi(EAX, EDI);
    // EAX: receiver class ID as Smi.
  }

  __ Comment("ICData loop");

  // We unroll the generic one that is generated once more than the others.
  bool optimize = kind == Token::kILLEGAL;
  const intptr_t target_offset = ICData::TargetIndexFor(num_args) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(num_args) * kWordSize;
  const intptr_t entry_size = ICData::TestEntryLengthFor(num_args) * kWordSize;

  __ Bind(&loop);
  for (int unroll = optimize ? 4 : 2; unroll >= 0; unroll--) {
    Label update;
    if (num_args == 1) {
      __ movl(EDI, Address(EBX, 0));
      __ cmpl(EDI, EAX);                                    // Class id match?
      __ j(EQUAL, &found);                                  // Break.
      __ addl(EBX, Immediate(entry_size));                  // Next entry.
      __ cmpl(EDI, Immediate(Smi::RawValue(kIllegalCid)));  // Done?
    } else {
      ASSERT(num_args == 2);
      // Load receiver into EDI.
      __ movl(EDI, Address(ESP, EAX, TIMES_2, 0));
      __ LoadTaggedClassIdMayBeSmi(EDI, EDI);
      __ cmpl(EDI, Address(EBX, 0));  // Class id match?
      __ j(NOT_EQUAL, &update);       // Continue.

      // Load second argument into EDI.
      __ movl(EDI, Address(ESP, EAX, TIMES_2, -kWordSize));
      __ LoadTaggedClassIdMayBeSmi(EDI, EDI);
      __ cmpl(EDI, Address(EBX, kWordSize));  // Class id match?
      __ j(EQUAL, &found);                    // Break.

      __ Bind(&update);
      __ addl(EBX, Immediate(entry_size));  // Next entry.
      __ cmpl(Address(EBX, -entry_size),
              Immediate(Smi::RawValue(kIllegalCid)));  // Done?
    }

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
  __ movl(EAX, FieldAddress(EDX, ArgumentsDescriptor::count_offset()));
  __ leal(EAX, Address(ESP, EAX, TIMES_2, 0));  // EAX is Smi.
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ pushl(EDX);           // Preserve arguments descriptor array.
  __ pushl(ECX);           // Preserve IC data object.
  __ pushl(Immediate(0));  // Result slot.
  // Push call arguments.
  for (intptr_t i = 0; i < num_args; i++) {
    __ movl(EBX, Address(EAX, -kWordSize * i));
    __ pushl(EBX);
  }
  __ pushl(ECX);  // Pass IC data object.
  __ CallRuntime(handle_ic_miss, num_args + 1);
  // Remove the call arguments pushed earlier, including the IC data object.
  for (intptr_t i = 0; i < num_args + 1; i++) {
    __ popl(EAX);
  }
  __ popl(EAX);  // Pop returned function object into EAX.
  __ popl(ECX);  // Restore IC data array.
  __ popl(EDX);  // Restore arguments descriptor array.
  __ LeaveFrame();
  Label call_target_function;
  if (!FLAG_lazy_dispatchers) {
    GenerateDispatcherCode(assembler, &call_target_function);
  } else {
    __ jmp(&call_target_function);
  }

  __ Bind(&found);

  // EBX: Pointer to an IC data check group.
  if (FLAG_optimization_counter_threshold >= 0) {
    __ Comment("Update caller's counter");
    // Ignore overflow.
    __ addl(Address(EBX, count_offset), Immediate(Smi::RawValue(1)));
  }

  __ movl(EAX, Address(EBX, target_offset));
  __ Bind(&call_target_function);
  __ Comment("Call target");
  // EAX: Target function.
  __ movl(EBX, FieldAddress(EAX, Function::entry_point_offset()));
  __ jmp(EBX);

#if !defined(PRODUCT)
  if (!optimized) {
    __ Bind(&stepping);
    __ EnterStubFrame();
    __ pushl(ECX);
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ popl(ECX);
    __ LeaveFrame();
    __ jmp(&done_stepping);
  }
#endif
}

// Use inline cache data array to invoke the target or continue in inline
// cache miss handler. Stub for 1-argument check (receiver class).
//  ECX: Inline cache data object.
//  TOS(0): Return address.
// Inline cache data object structure:
// 0: function-name
// 1: N, number of arguments checked.
// 2 .. (length - 1): group of checks, each check containing:
//   - N classes.
//   - 1 target function.
void StubCode::GenerateOneArgCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, EBX);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL);
}

void StubCode::GenerateTwoArgsCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, EBX);
  GenerateNArgsCheckInlineCacheStub(assembler, 2,
                                    kInlineCacheMissHandlerTwoArgsRuntimeEntry,
                                    Token::kILLEGAL);
}

void StubCode::GenerateSmiAddInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, EBX);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kADD);
}

void StubCode::GenerateSmiSubInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, EBX);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kSUB);
}

void StubCode::GenerateSmiEqualInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, EBX);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kEQ);
}

// Use inline cache data array to invoke the target or continue in inline
// cache miss handler. Stub for 1-argument check (receiver class).
//  EDI: function which counter needs to be incremented.
//  ECX: Inline cache data object.
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
// ECX: ICData
void StubCode::GenerateZeroArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, EBX);

#if defined(DEBUG)
  {
    Label ok;
    // Check that the IC data array has NumArgsTested() == num_args.
    // 'NumArgsTested' is stored in the least significant bits of 'state_bits'.
    __ movl(EBX, FieldAddress(ECX, ICData::state_bits_offset()));
    ASSERT(ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ andl(EBX, Immediate(ICData::NumArgsTestedMask()));
    __ cmpl(EBX, Immediate(0));
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Incorrect IC data for unoptimized static call");
    __ Bind(&ok);
  }
#endif  // DEBUG

#if !defined(PRODUCT)
  // Check single stepping.
  Label stepping, done_stepping;
  __ LoadIsolate(EAX);
  __ cmpb(Address(EAX, Isolate::single_step_offset()), Immediate(0));
  __ j(NOT_EQUAL, &stepping, Assembler::kNearJump);
  __ Bind(&done_stepping);
#endif

  // ECX: IC data object (preserved).
  __ movl(EBX, FieldAddress(ECX, ICData::ic_data_offset()));
  // EBX: ic_data_array with entries: target functions and count.
  __ leal(EBX, FieldAddress(EBX, Array::data_offset()));
  // EBX: points directly to the first ic data array element.
  const intptr_t target_offset = ICData::TargetIndexFor(0) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(0) * kWordSize;

  if (FLAG_optimization_counter_threshold >= 0) {
    // Increment count for this call, ignore overflow.
    __ addl(Address(EBX, count_offset), Immediate(Smi::RawValue(1)));
  }

  // Load arguments descriptor into EDX.
  __ movl(EDX, FieldAddress(ECX, ICData::arguments_descriptor_offset()));

  // Get function and call it, if possible.
  __ movl(EAX, Address(EBX, target_offset));
  __ movl(EBX, FieldAddress(EAX, Function::entry_point_offset()));
  __ jmp(EBX);

#if !defined(PRODUCT)
  __ Bind(&stepping);
  __ EnterStubFrame();
  __ pushl(ECX);
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ popl(ECX);
  __ LeaveFrame();
  __ jmp(&done_stepping, Assembler::kNearJump);
#endif
}

void StubCode::GenerateOneArgUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, EBX);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kStaticCallMissHandlerOneArgRuntimeEntry, Token::kILLEGAL);
}

void StubCode::GenerateTwoArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, EBX);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kStaticCallMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL);
}

// Stub for compiling a function and jumping to the compiled code.
// ECX: IC-Data (for methods).
// EDX: Arguments descriptor.
// EAX: Function.
void StubCode::GenerateLazyCompileStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ pushl(EDX);  // Preserve arguments descriptor array.
  __ pushl(ECX);  // Preserve IC data object.
  __ pushl(EAX);  // Pass function.
  __ CallRuntime(kCompileFunctionRuntimeEntry, 1);
  __ popl(EAX);  // Restore function.
  __ popl(ECX);  // Restore IC data array.
  __ popl(EDX);  // Restore arguments descriptor array.
  __ LeaveFrame();

  __ movl(EAX, FieldAddress(EAX, Function::entry_point_offset()));
  __ jmp(EAX);
}

// ECX: Contains an ICData.
void StubCode::GenerateICCallBreakpointStub(Assembler* assembler) {
  __ EnterStubFrame();
  // Save IC data.
  __ pushl(ECX);
  // Room for result. Debugger stub returns address of the
  // unpatched runtime stub.
  __ pushl(Immediate(0));  // Room for result.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ popl(EAX);  // Code of original stub.
  __ popl(ECX);  // Restore IC data.
  __ LeaveFrame();
  // Jump to original stub.
  __ movl(EAX, FieldAddress(EAX, Code::entry_point_offset()));
  __ jmp(EAX);
}

void StubCode::GenerateRuntimeCallBreakpointStub(Assembler* assembler) {
  __ EnterStubFrame();
  // Room for result. Debugger stub returns address of the
  // unpatched runtime stub.
  __ pushl(Immediate(0));  // Room for result.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ popl(EAX);  // Code of the original stub
  __ LeaveFrame();
  // Jump to original stub.
  __ movl(EAX, FieldAddress(EAX, Code::entry_point_offset()));
  __ jmp(EAX);
}

// Called only from unoptimized code.
void StubCode::GenerateDebugStepCheckStub(Assembler* assembler) {
  // Check single stepping.
  Label stepping, done_stepping;
  __ LoadIsolate(EAX);
  __ movzxb(EAX, Address(EAX, Isolate::single_step_offset()));
  __ cmpl(EAX, Immediate(0));
  __ j(NOT_EQUAL, &stepping, Assembler::kNearJump);
  __ Bind(&done_stepping);
  __ ret();

  __ Bind(&stepping);
  __ EnterStubFrame();
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ LeaveFrame();
  __ jmp(&done_stepping, Assembler::kNearJump);
}

// Used to check class and type arguments. Arguments passed on stack:
// TOS + 0: return address.
// TOS + 1: function type arguments (only if n == 4, can be raw_null).
// TOS + 2: instantiator type arguments (only if n == 4, can be raw_null).
// TOS + 3: instance.
// TOS + 4: SubtypeTestCache.
// Result in ECX: null -> not found, otherwise result (true or false).
static void GenerateSubtypeNTestCacheStub(Assembler* assembler, int n) {
  ASSERT((n == 1) || (n == 2) || (n == 4));
  const intptr_t kFunctionTypeArgumentsInBytes = 1 * kWordSize;
  const intptr_t kInstantiatorTypeArgumentsInBytes = 2 * kWordSize;
  const intptr_t kInstanceOffsetInBytes = 3 * kWordSize;
  const intptr_t kCacheOffsetInBytes = 4 * kWordSize;
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movl(EAX, Address(ESP, kInstanceOffsetInBytes));
  if (n > 1) {
    __ LoadClass(ECX, EAX, EBX);
    // Compute instance type arguments into EBX.
    Label has_no_type_arguments;
    __ movl(EBX, raw_null);
    __ movl(EDI,
            FieldAddress(ECX,
                         Class::type_arguments_field_offset_in_words_offset()));
    __ cmpl(EDI, Immediate(Class::kNoTypeArguments));
    __ j(EQUAL, &has_no_type_arguments, Assembler::kNearJump);
    __ movl(EBX, FieldAddress(EAX, EDI, TIMES_4, 0));
    __ Bind(&has_no_type_arguments);
  }
  __ LoadClassId(ECX, EAX);
  // EAX: instance, ECX: instance class id.
  // EBX: instance type arguments (null if none), used only if n > 1.
  __ movl(EDX, Address(ESP, kCacheOffsetInBytes));
  // EDX: SubtypeTestCache.
  __ movl(EDX, FieldAddress(EDX, SubtypeTestCache::cache_offset()));
  __ addl(EDX, Immediate(Array::data_offset() - kHeapObjectTag));

  Label loop, found, not_found, next_iteration;
  // EDX: Entry start.
  // ECX: instance class id.
  // EBX: instance type arguments (still null if closure).
  __ SmiTag(ECX);
  __ cmpl(ECX, Immediate(Smi::RawValue(kClosureCid)));
  __ j(NOT_EQUAL, &loop, Assembler::kNearJump);
  __ movl(EBX, FieldAddress(EAX, Closure::function_type_arguments_offset()));
  __ cmpl(EBX, raw_null);  // Cache cannot be used for generic closures.
  __ j(NOT_EQUAL, &not_found, Assembler::kNearJump);
  __ movl(EBX,
          FieldAddress(EAX, Closure::instantiator_type_arguments_offset()));
  __ movl(ECX, FieldAddress(EAX, Closure::function_offset()));
  // ECX: instance class id as Smi or function.
  __ Bind(&loop);
  __ movl(EDI, Address(EDX, kWordSize *
                                SubtypeTestCache::kInstanceClassIdOrFunction));
  __ cmpl(EDI, raw_null);
  __ j(EQUAL, &not_found, Assembler::kNearJump);
  __ cmpl(EDI, ECX);
  if (n == 1) {
    __ j(EQUAL, &found, Assembler::kNearJump);
  } else {
    __ j(NOT_EQUAL, &next_iteration, Assembler::kNearJump);
    __ movl(EDI,
            Address(EDX, kWordSize * SubtypeTestCache::kInstanceTypeArguments));
    __ cmpl(EDI, EBX);
    if (n == 2) {
      __ j(EQUAL, &found, Assembler::kNearJump);
    } else {
      __ j(NOT_EQUAL, &next_iteration, Assembler::kNearJump);
      __ movl(EDI,
              Address(EDX, kWordSize *
                               SubtypeTestCache::kInstantiatorTypeArguments));
      __ cmpl(EDI, Address(ESP, kInstantiatorTypeArgumentsInBytes));
      __ j(NOT_EQUAL, &next_iteration, Assembler::kNearJump);
      __ movl(EDI, Address(EDX, kWordSize *
                                    SubtypeTestCache::kFunctionTypeArguments));
      __ cmpl(EDI, Address(ESP, kFunctionTypeArgumentsInBytes));
      __ j(EQUAL, &found, Assembler::kNearJump);
    }
  }
  __ Bind(&next_iteration);
  __ addl(EDX, Immediate(kWordSize * SubtypeTestCache::kTestEntryLength));
  __ jmp(&loop, Assembler::kNearJump);
  // Fall through to not found.
  __ Bind(&not_found);
  __ movl(ECX, raw_null);
  __ ret();

  __ Bind(&found);
  __ movl(ECX, Address(EDX, kWordSize * SubtypeTestCache::kTestResult));
  __ ret();
}

// Used to check class and type arguments. Arguments passed on stack:
// TOS + 0: return address.
// TOS + 1: raw_null.
// TOS + 2: raw_null.
// TOS + 3: instance.
// TOS + 4: SubtypeTestCache.
// Result in ECX: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype1TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 1);
}

// Used to check class and type arguments. Arguments passed on stack:
// TOS + 0: return address.
// TOS + 1: raw_null.
// TOS + 2: raw_null.
// TOS + 3: instance.
// TOS + 4: SubtypeTestCache.
// Result in ECX: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype2TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 2);
}

// Used to check class and type arguments. Arguments passed on stack:
// TOS + 0: return address.
// TOS + 1: function type arguments (can be raw_null).
// TOS + 2: instantiator type arguments (can be raw_null).
// TOS + 3: instance.
// TOS + 4: SubtypeTestCache.
// Result in ECX: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype4TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 4);
}

// Return the current stack pointer address, used to do stack alignment checks.
// TOS + 0: return address
// Result in EAX.
void StubCode::GenerateGetCStackPointerStub(Assembler* assembler) {
  __ leal(EAX, Address(ESP, kWordSize));
  __ ret();
}

// Jump to a frame on the call stack.
// TOS + 0: return address
// TOS + 1: program_counter
// TOS + 2: stack_pointer
// TOS + 3: frame_pointer
// TOS + 4: thread
// No Result.
void StubCode::GenerateJumpToFrameStub(Assembler* assembler) {
  __ movl(THR, Address(ESP, 4 * kWordSize));  // Load target thread.
  __ movl(EBP, Address(ESP, 3 * kWordSize));  // Load target frame_pointer.
  __ movl(EBX, Address(ESP, 1 * kWordSize));  // Load target PC into EBX.
  __ movl(ESP, Address(ESP, 2 * kWordSize));  // Load target stack_pointer.
  // Set tag.
  __ movl(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));
  // Clear top exit frame.
  __ movl(Address(THR, Thread::top_exit_frame_info_offset()), Immediate(0));
  __ jmp(EBX);  // Jump to the exception handler code.
}

// Run an exception handler.  Execution comes from JumpToFrame stub.
//
// The arguments are stored in the Thread object.
// No result.
void StubCode::GenerateRunExceptionHandlerStub(Assembler* assembler) {
  ASSERT(kExceptionObjectReg == EAX);
  ASSERT(kStackTraceObjectReg == EDX);
  __ movl(EBX, Address(THR, Thread::resume_pc_offset()));

  // Load the exception from the current thread.
  Address exception_addr(THR, Thread::active_exception_offset());
  __ movl(kExceptionObjectReg, exception_addr);
  __ movl(exception_addr, Immediate(0));

  // Load the stacktrace from the current thread.
  Address stacktrace_addr(THR, Thread::active_stacktrace_offset());
  __ movl(kStackTraceObjectReg, stacktrace_addr);
  __ movl(stacktrace_addr, Immediate(0));

  __ jmp(EBX);  // Jump to continuation point.
}

// Deoptimize a frame on the call stack before rewinding.
// The arguments are stored in the Thread object.
// No result.
void StubCode::GenerateDeoptForRewindStub(Assembler* assembler) {
  // Push the deopt pc.
  __ pushl(Address(THR, Thread::resume_pc_offset()));
  GenerateDeoptimizationSequence(assembler, kEagerDeopt);

  // After we have deoptimized, jump to the correct frame.
  __ EnterStubFrame();
  __ CallRuntime(kRewindPostDeoptRuntimeEntry, 0);
  __ LeaveFrame();
  __ int3();
}

// Calls to the runtime to optimize the given function.
// EBX: function to be reoptimized.
// EDX: argument descriptor (preserved).
void StubCode::GenerateOptimizeFunctionStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ pushl(EDX);
  __ pushl(Immediate(0));  // Setup space on stack for return value.
  __ pushl(EBX);
  __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry, 1);
  __ popl(EAX);  // Discard argument.
  __ popl(EAX);  // Get Function object
  __ popl(EDX);  // Restore argument descriptor.
  __ LeaveFrame();
  __ movl(CODE_REG, FieldAddress(EAX, Function::code_offset()));
  __ movl(EAX, FieldAddress(EAX, Function::entry_point_offset()));
  __ jmp(EAX);
  __ int3();
}

// Does identical check (object references are equal or not equal) with special
// checks for boxed numbers.
// Return ZF set.
// Note: A Mint cannot contain a value that would fit in Smi, a Bigint
// cannot contain a value that fits in Mint or Smi.
static void GenerateIdenticalWithNumberCheckStub(Assembler* assembler,
                                                 const Register left,
                                                 const Register right,
                                                 const Register temp) {
  Label reference_compare, done, check_mint, check_bigint;
  // If any of the arguments is Smi do reference compare.
  __ testl(left, Immediate(kSmiTagMask));
  __ j(ZERO, &reference_compare, Assembler::kNearJump);
  __ testl(right, Immediate(kSmiTagMask));
  __ j(ZERO, &reference_compare, Assembler::kNearJump);

  // Value compare for two doubles.
  __ CompareClassId(left, kDoubleCid, temp);
  __ j(NOT_EQUAL, &check_mint, Assembler::kNearJump);
  __ CompareClassId(right, kDoubleCid, temp);
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);

  // Double values bitwise compare.
  __ movl(temp, FieldAddress(left, Double::value_offset() + 0 * kWordSize));
  __ cmpl(temp, FieldAddress(right, Double::value_offset() + 0 * kWordSize));
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  __ movl(temp, FieldAddress(left, Double::value_offset() + 1 * kWordSize));
  __ cmpl(temp, FieldAddress(right, Double::value_offset() + 1 * kWordSize));
  __ jmp(&done, Assembler::kNearJump);

  __ Bind(&check_mint);
  __ CompareClassId(left, kMintCid, temp);
  __ j(NOT_EQUAL, &check_bigint, Assembler::kNearJump);
  __ CompareClassId(right, kMintCid, temp);
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  __ movl(temp, FieldAddress(left, Mint::value_offset() + 0 * kWordSize));
  __ cmpl(temp, FieldAddress(right, Mint::value_offset() + 0 * kWordSize));
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  __ movl(temp, FieldAddress(left, Mint::value_offset() + 1 * kWordSize));
  __ cmpl(temp, FieldAddress(right, Mint::value_offset() + 1 * kWordSize));
  __ jmp(&done, Assembler::kNearJump);

  __ Bind(&check_bigint);
  __ CompareClassId(left, kBigintCid, temp);
  __ j(NOT_EQUAL, &reference_compare, Assembler::kNearJump);
  __ CompareClassId(right, kBigintCid, temp);
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  __ EnterFrame(0);
  __ ReserveAlignedFrameSpace(2 * kWordSize);
  __ movl(Address(ESP, 1 * kWordSize), left);
  __ movl(Address(ESP, 0 * kWordSize), right);
  __ CallRuntime(kBigintCompareRuntimeEntry, 2);
  // Result in EAX, 0 means equal.
  __ LeaveFrame();
  __ cmpl(EAX, Immediate(0));
  __ jmp(&done);

  __ Bind(&reference_compare);
  __ cmpl(left, right);
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
  __ LoadIsolate(EAX);
  __ movzxb(EAX, Address(EAX, Isolate::single_step_offset()));
  __ cmpl(EAX, Immediate(0));
  __ j(NOT_EQUAL, &stepping);
  __ Bind(&done_stepping);
#endif

  const Register left = EAX;
  const Register right = EDX;
  const Register temp = ECX;
  __ movl(left, Address(ESP, 2 * kWordSize));
  __ movl(right, Address(ESP, 1 * kWordSize));
  GenerateIdenticalWithNumberCheckStub(assembler, left, right, temp);
  __ ret();

#if !defined(PRODUCT)
  __ Bind(&stepping);
  __ EnterStubFrame();
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ LeaveFrame();
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
  const Register left = EAX;
  const Register right = EDX;
  const Register temp = ECX;
  __ movl(left, Address(ESP, 2 * kWordSize));
  __ movl(right, Address(ESP, 1 * kWordSize));
  GenerateIdenticalWithNumberCheckStub(assembler, left, right, temp);
  __ ret();
}

// Called from megamorphic calls.
//  EBX: receiver
//  ECX: MegamorphicCache (preserved)
// Passed to target:
//  EBX: target entry point
//  EDX: argument descriptor
void StubCode::GenerateMegamorphicCallStub(Assembler* assembler) {
  // Jump if receiver is a smi.
  Label smi_case;
  // Check if object (in tmp) is a Smi.
  __ testl(EBX, Immediate(kSmiTagMask));
  // Jump out of line for smi case.
  __ j(ZERO, &smi_case, Assembler::kNearJump);

  // Loads the cid of the instance.
  __ LoadClassId(EAX, EBX);

  Label cid_loaded;
  __ Bind(&cid_loaded);
  __ movl(EBX, FieldAddress(ECX, MegamorphicCache::mask_offset()));
  __ movl(EDI, FieldAddress(ECX, MegamorphicCache::buckets_offset()));
  // EDI: cache buckets array.
  // EBX: mask.

  // Tag cid as a smi.
  __ addl(EAX, EAX);

  // Compute the table index.
  ASSERT(MegamorphicCache::kSpreadFactor == 7);
  // Use leal and subl multiply with 7 == 8 - 1.
  __ leal(EDX, Address(EAX, TIMES_8, 0));
  __ subl(EDX, EAX);

  Label loop;
  __ Bind(&loop);
  __ andl(EDX, EBX);

  const intptr_t base = Array::data_offset();
  Label probe_failed;
  // EDX is smi tagged, but table entries are two words, so TIMES_4.
  __ cmpl(EAX, FieldAddress(EDI, EDX, TIMES_4, base));
  __ j(NOT_EQUAL, &probe_failed, Assembler::kNearJump);

  Label load_target;
  __ Bind(&load_target);
  // Call the target found in the cache.  For a class id match, this is a
  // proper target for the given name and arguments descriptor.  If the
  // illegal class id was found, the target is a cache miss handler that can
  // be invoked as a normal Dart function.
  __ movl(EAX, FieldAddress(EDI, EDX, TIMES_4, base + kWordSize));
  __ movl(EDX,
          FieldAddress(ECX, MegamorphicCache::arguments_descriptor_offset()));
  __ movl(EBX, FieldAddress(EAX, Function::entry_point_offset()));
  __ ret();

  __ Bind(&probe_failed);
  // Probe failed, check if it is a miss.
  __ cmpl(FieldAddress(EDI, EDX, TIMES_4, base), Immediate(kIllegalCid));
  __ j(ZERO, &load_target, Assembler::kNearJump);

  // Try next entry in the table.
  __ AddImmediate(EDX, Immediate(Smi::RawValue(1)));
  __ jmp(&loop);

  // Load cid for the Smi case.
  __ Bind(&smi_case);
  __ movl(EAX, Immediate(kSmiCid));
  __ jmp(&cid_loaded);
}

// Called from switchable IC calls.
//  EBX: receiver
//  ECX: ICData (preserved)
// Passed to target:
//  EDX: arguments descriptor
void StubCode::GenerateICCallThroughFunctionStub(Assembler* assembler) {
  __ int3();
}

void StubCode::GenerateICCallThroughCodeStub(Assembler* assembler) {
  __ int3();
}

void StubCode::GenerateUnlinkedCallStub(Assembler* assembler) {
  __ int3();
}

void StubCode::GenerateSingleTargetCallStub(Assembler* assembler) {
  __ int3();
}

void StubCode::GenerateMonomorphicMissStub(Assembler* assembler) {
  __ int3();
}

void StubCode::GenerateFrameAwaitingMaterializationStub(Assembler* assembler) {
  __ int3();
}

void StubCode::GenerateAsynchronousGapMarkerStub(Assembler* assembler) {
  __ int3();
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_IA32) && !defined(DART_PRECOMPILED_RUNTIME)
