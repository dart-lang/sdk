// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/assembler.h"
#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph_compiler.h"
#include "vm/instructions.h"
#include "vm/heap.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/scavenger.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/tags.h"


#define __ assembler->

namespace dart {

DEFINE_FLAG(bool, inline_alloc, true, "Inline allocation of objects.");
DEFINE_FLAG(bool, use_slow_path, false,
    "Set to true for debugging & verifying the slow paths.");
DECLARE_FLAG(bool, trace_optimized_ic_calls);
DEFINE_FLAG(bool, verify_incoming_contexts, false, "");

DECLARE_FLAG(bool, enable_debugger);

// Input parameters:
//   ESP : points to return address.
//   ESP + 4 : address of last argument in argument array.
//   ESP + 4*EDX : address of first argument in argument array.
//   ESP + 4*EDX + 4 : address of return value.
//   ECX : address of the runtime function to call.
//   EDX : number of arguments to the call.
// Must preserve callee saved registers EDI and EBX.
void StubCode::GenerateCallToRuntimeStub(Assembler* assembler) {
  const intptr_t isolate_offset = NativeArguments::isolate_offset();
  const intptr_t argc_tag_offset = NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = NativeArguments::argv_offset();
  const intptr_t retval_offset = NativeArguments::retval_offset();

  __ EnterFrame(0);

  // Load current Isolate pointer from Context structure into EAX.
  __ movl(EAX, FieldAddress(CTX, Context::isolate_offset()));

  // Save exit frame information to enable stack walking as we are about
  // to transition to Dart VM C++ code.
  __ movl(Address(EAX, Isolate::top_exit_frame_info_offset()), ESP);

#if defined(DEBUG)
  if (FLAG_verify_incoming_contexts) {
    Label ok;
    // Check that the isolate's saved ctx is null.
    const Immediate& raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ cmpl(Address(EAX, Isolate::top_context_offset()), raw_null);
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Found non-null incoming top context: call to runtime stub");
    __ Bind(&ok);
  }
#endif

  // Save current Context pointer into Isolate structure.
  __ movl(Address(EAX, Isolate::top_context_offset()), CTX);

  // Cache Isolate pointer into CTX while executing runtime code.
  __ movl(CTX, EAX);

#if defined(DEBUG)
  { Label ok;
    // Check that we are always entering from Dart code.
    __ movl(EAX, Address(CTX, Isolate::vm_tag_offset()));
    __ cmpl(EAX, Immediate(VMTag::kScriptTagId));
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the isolate is executing VM code.
  __ movl(Address(CTX, Isolate::vm_tag_offset()), ECX);

  // Reserve space for arguments and align frame before entering C++ world.
  __ AddImmediate(ESP, Immediate(-sizeof(NativeArguments)));
  if (OS::ActivationFrameAlignment() > 1) {
    __ andl(ESP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass NativeArguments structure by value and call runtime.
  __ movl(Address(ESP, isolate_offset), CTX);  // Set isolate in NativeArgs.
  // There are no runtime calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  __ movl(Address(ESP, argc_tag_offset), EDX);  // Set argc in NativeArguments.
  __ leal(EAX, Address(EBP, EDX, TIMES_4, 1 * kWordSize));  // Compute argv.
  __ movl(Address(ESP, argv_offset), EAX);  // Set argv in NativeArguments.
  __ addl(EAX, Immediate(1 * kWordSize));  // Retval is next to 1st argument.
  __ movl(Address(ESP, retval_offset), EAX);  // Set retval in NativeArguments.
  __ call(ECX);

  // Mark that the isolate is executing Dart code.
  __ movl(Address(CTX, Isolate::vm_tag_offset()),
          Immediate(VMTag::kScriptTagId));

  // Reset exit frame information in Isolate structure.
  __ movl(Address(CTX, Isolate::top_exit_frame_info_offset()), Immediate(0));

  // Load Context pointer from Isolate structure into ECX.
  __ movl(ECX, Address(CTX, Isolate::top_context_offset()));

  // Reset Context pointer in Isolate structure.
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movl(Address(CTX, Isolate::top_context_offset()), raw_null);

  // Cache Context pointer into CTX while executing Dart code.
  __ movl(CTX, ECX);

  __ LeaveFrame();
  __ ret();
}


// Print the stop message.
DEFINE_LEAF_RUNTIME_ENTRY(void, PrintStopMessage, 1, const char* message) {
  OS::Print("Stop message: %s\n", message);
}
END_LEAF_RUNTIME_ENTRY


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
// Uses EDI.
void StubCode::GenerateCallNativeCFunctionStub(Assembler* assembler) {
  const intptr_t native_args_struct_offset =
      NativeEntry::kNumCallWrapperArguments * kWordSize;
  const intptr_t isolate_offset =
      NativeArguments::isolate_offset() + native_args_struct_offset;
  const intptr_t argc_tag_offset =
      NativeArguments::argc_tag_offset() + native_args_struct_offset;
  const intptr_t argv_offset =
      NativeArguments::argv_offset() + native_args_struct_offset;
  const intptr_t retval_offset =
      NativeArguments::retval_offset() + native_args_struct_offset;

  __ EnterFrame(0);

  // Load current Isolate pointer from Context structure into EDI.
  __ movl(EDI, FieldAddress(CTX, Context::isolate_offset()));

  // Save exit frame information to enable stack walking as we are about
  // to transition to dart VM code.
  __ movl(Address(EDI, Isolate::top_exit_frame_info_offset()), ESP);

#if defined(DEBUG)
  if (FLAG_verify_incoming_contexts) {
    Label ok;
    // Check that the isolate's saved ctx is null.
    const Immediate& raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ cmpl(Address(EDI, Isolate::top_context_offset()), raw_null);
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Found non-null incoming top context: "
            "call to native c function stub");
    __ Bind(&ok);
  }
#endif

  // Save current Context pointer into Isolate structure.
  __ movl(Address(EDI, Isolate::top_context_offset()), CTX);

  // Cache Isolate pointer into CTX while executing native code.
  __ movl(CTX, EDI);

#if defined(DEBUG)
  { Label ok;
    // Check that we are always entering from Dart code.
    __ movl(EDI, Address(CTX, Isolate::vm_tag_offset()));
    __ cmpl(EDI, Immediate(VMTag::kScriptTagId));
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the isolate is executing Native code.
  __ movl(Address(CTX, Isolate::vm_tag_offset()), ECX);

  // Reserve space for the native arguments structure, the outgoing parameters
  // (pointer to the native arguments structure, the C function entry point)
  // and align frame before entering the C++ world.
  __ AddImmediate(ESP, Immediate(-sizeof(NativeArguments) - (2 * kWordSize)));
  if (OS::ActivationFrameAlignment() > 1) {
    __ andl(ESP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass NativeArguments structure by value and call native function.
  __ movl(Address(ESP, isolate_offset), CTX);  // Set isolate in NativeArgs.
  __ movl(Address(ESP, argc_tag_offset), EDX);  // Set argc in NativeArguments.
  __ movl(Address(ESP, argv_offset), EAX);  // Set argv in NativeArguments.
  __ leal(EAX, Address(EBP, 2 * kWordSize));  // Compute return value addr.
  __ movl(Address(ESP, retval_offset), EAX);  // Set retval in NativeArguments.
  __ leal(EAX, Address(ESP, 2 * kWordSize));  // Pointer to the NativeArguments.
  __ movl(Address(ESP, 0), EAX);  // Pass the pointer to the NativeArguments.

  // Call native function (setsup scope if not leaf function).
  Label leaf_call;
  Label done;
  __ testl(EDX, Immediate(NativeArguments::AutoSetupScopeMask()));
  __ j(ZERO, &leaf_call, Assembler::kNearJump);
  __ movl(Address(ESP, kWordSize), ECX);  // Function to call.
  __ call(&NativeEntry::NativeCallWrapperLabel());
  __ jmp(&done);
  __ Bind(&leaf_call);
  __ call(ECX);
  __ Bind(&done);

  // Mark that the isolate is executing Dart code.
  __ movl(Address(CTX, Isolate::vm_tag_offset()),
          Immediate(VMTag::kScriptTagId));

  // Reset exit frame information in Isolate structure.
  __ movl(Address(CTX, Isolate::top_exit_frame_info_offset()), Immediate(0));

  // Load Context pointer from Isolate structure into EDI.
  __ movl(EDI, Address(CTX, Isolate::top_context_offset()));

  // Reset Context pointer in Isolate structure.
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movl(Address(CTX, Isolate::top_context_offset()), raw_null);

  // Cache Context pointer into CTX while executing Dart code.
  __ movl(CTX, EDI);

  __ LeaveFrame();
  __ ret();
}


// Input parameters:
//   ESP : points to return address.
//   ESP + 4 : address of return value.
//   EAX : address of first argument in argument array.
//   ECX : address of the native function to call.
//   EDX : argc_tag including number of arguments and function kind.
// Uses EDI.
void StubCode::GenerateCallBootstrapCFunctionStub(Assembler* assembler) {
  const intptr_t native_args_struct_offset = kWordSize;
  const intptr_t isolate_offset =
      NativeArguments::isolate_offset() + native_args_struct_offset;
  const intptr_t argc_tag_offset =
      NativeArguments::argc_tag_offset() + native_args_struct_offset;
  const intptr_t argv_offset =
      NativeArguments::argv_offset() + native_args_struct_offset;
  const intptr_t retval_offset =
      NativeArguments::retval_offset() + native_args_struct_offset;

  __ EnterFrame(0);

  // Load current Isolate pointer from Context structure into EDI.
  __ movl(EDI, FieldAddress(CTX, Context::isolate_offset()));

  // Save exit frame information to enable stack walking as we are about
  // to transition to dart VM code.
  __ movl(Address(EDI, Isolate::top_exit_frame_info_offset()), ESP);

#if defined(DEBUG)
  if (FLAG_verify_incoming_contexts) {
    Label ok;
    // Check that the isolate's saved ctx is null.
    const Immediate& raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ cmpl(Address(EDI, Isolate::top_context_offset()), raw_null);
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Found non-null incoming top context: "
            "call to bootstrap c function stub");
    __ Bind(&ok);
  }
#endif

  // Save current Context pointer into Isolate structure.
  __ movl(Address(EDI, Isolate::top_context_offset()), CTX);

  // Cache Isolate pointer into CTX while executing native code.
  __ movl(CTX, EDI);

#if defined(DEBUG)
  { Label ok;
    // Check that we are always entering from Dart code.
    __ movl(EDI, Address(CTX, Isolate::vm_tag_offset()));
    __ cmpl(EDI, Immediate(VMTag::kScriptTagId));
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the isolate is executing Native code.
  __ movl(Address(CTX, Isolate::vm_tag_offset()), ECX);

  // Reserve space for the native arguments structure, the outgoing parameter
  // (pointer to the native arguments structure) and align frame before
  // entering the C++ world.
  __ AddImmediate(ESP, Immediate(-sizeof(NativeArguments) - kWordSize));
  if (OS::ActivationFrameAlignment() > 1) {
    __ andl(ESP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass NativeArguments structure by value and call native function.
  __ movl(Address(ESP, isolate_offset), CTX);  // Set isolate in NativeArgs.
  __ movl(Address(ESP, argc_tag_offset), EDX);  // Set argc in NativeArguments.
  __ movl(Address(ESP, argv_offset), EAX);  // Set argv in NativeArguments.
  __ leal(EAX, Address(EBP, 2 * kWordSize));  // Compute return value addr.
  __ movl(Address(ESP, retval_offset), EAX);  // Set retval in NativeArguments.
  __ leal(EAX, Address(ESP, kWordSize));  // Pointer to the NativeArguments.
  __ movl(Address(ESP, 0), EAX);  // Pass the pointer to the NativeArguments.
  __ call(ECX);

  // Mark that the isolate is executing Dart code.
  __ movl(Address(CTX, Isolate::vm_tag_offset()),
          Immediate(VMTag::kScriptTagId));

  // Reset exit frame information in Isolate structure.
  __ movl(Address(CTX, Isolate::top_exit_frame_info_offset()), Immediate(0));

  // Load Context pointer from Isolate structure into EDI.
  __ movl(EDI, Address(CTX, Isolate::top_context_offset()));

  // Reset Context pointer in Isolate structure.
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movl(Address(CTX, Isolate::top_context_offset()), raw_null);

  // Cache Context pointer into CTX while executing Dart code.
  __ movl(CTX, EDI);

  __ LeaveFrame();
  __ ret();
}


// Input parameters:
//   EDX: arguments descriptor array.
void StubCode::GenerateCallStaticFunctionStub(Assembler* assembler) {
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ EnterStubFrame();
  __ pushl(EDX);  // Preserve arguments descriptor array.
  __ pushl(raw_null);  // Setup space on stack for return value.
  __ CallRuntime(kPatchStaticCallRuntimeEntry, 0);
  __ popl(EAX);  // Get Code object result.
  __ popl(EDX);  // Restore arguments descriptor array.
  // Remove the stub frame as we are about to jump to the dart function.
  __ LeaveFrame();

  __ movl(ECX, FieldAddress(EAX, Code::instructions_offset()));
  __ addl(ECX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ jmp(ECX);
}


// Called from a static call only when an invalid code has been entered
// (invalid because its function was optimized or deoptimized).
// EDX: arguments descriptor array.
void StubCode::GenerateFixCallersTargetStub(Assembler* assembler) {
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ pushl(EDX);  // Preserve arguments descriptor array.
  __ pushl(raw_null);  // Setup space on stack for return value.
  __ CallRuntime(kFixCallersTargetRuntimeEntry, 0);
  __ popl(EAX);  // Get Code object.
  __ popl(EDX);  // Restore arguments descriptor array.
  __ movl(EAX, FieldAddress(EAX, Code::instructions_offset()));
  __ addl(EAX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ LeaveFrame();
  __ jmp(EAX);
  __ int3();
}


// Input parameters:
//   EDX: smi-tagged argument count, may be zero.
//   EBP[kParamEndSlotFromFp + 1]: last argument.
// Uses EAX, EBX, ECX, EDX.
static void PushArgumentsArray(Assembler* assembler) {
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));

  // Allocate array to store arguments of caller.
  __ movl(ECX, raw_null);  // Null element type for raw Array.
  __ call(&StubCode::AllocateArrayLabel());
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
  __ movl(EAX, Address(EBX, 0));
  __ movl(Address(ECX, 0), EAX);
  __ AddImmediate(ECX, Immediate(kWordSize));
  __ AddImmediate(EBX, Immediate(-kWordSize));
  __ Bind(&loop_condition);
  __ decl(EDX);
  __ j(POSITIVE, &loop, Assembler::kNearJump);
}


DECLARE_LEAF_RUNTIME_ENTRY(intptr_t, DeoptimizeCopyFrame,
                           intptr_t deopt_reason,
                           uword saved_registers_address);

DECLARE_LEAF_RUNTIME_ENTRY(void, DeoptimizeFillFrame, uword last_fp);


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
                                           bool preserve_result) {
  // Leaf runtime function DeoptimizeCopyFrame expects a Dart frame.
  __ EnterDartFrame(0);
  // The code in this frame may not cause GC. kDeoptimizeCopyFrameRuntimeEntry
  // and kDeoptimizeFillFrameRuntimeEntry are leaf runtime calls.
  const intptr_t saved_result_slot_from_fp =
      kFirstLocalSlotFromFp + 1 - (kNumberOfCpuRegisters - EAX);
  // Result in EAX is preserved as part of pushing all registers below.

  // Push registers in their enumeration order: lowest register number at
  // lowest address.
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; i--) {
    __ pushl(static_cast<Register>(i));
  }
  __ subl(ESP, Immediate(kNumberOfXmmRegisters * kFpuRegisterSize));
  intptr_t offset = 0;
  for (intptr_t reg_idx = 0; reg_idx < kNumberOfXmmRegisters; ++reg_idx) {
    XmmRegister xmm_reg = static_cast<XmmRegister>(reg_idx);
    __ movups(Address(ESP, offset), xmm_reg);
    offset += kFpuRegisterSize;
  }

  __ movl(ECX, ESP);  // Preserve saved registers block.
  __ ReserveAlignedFrameSpace(1 * kWordSize);
  __ movl(Address(ESP, 0), ECX);  // Start of register block.
  __ CallRuntime(kDeoptimizeCopyFrameRuntimeEntry, 1);
  // Result (EAX) is stack-size (FP - SP) in bytes.

  if (preserve_result) {
    // Restore result into EBX temporarily.
    __ movl(EBX, Address(EBP, saved_result_slot_from_fp * kWordSize));
  }

  __ LeaveFrame();
  __ popl(EDX);  // Preserve return address.
  __ movl(ESP, EBP);  // Discard optimized frame.
  __ subl(ESP, EAX);  // Reserve space for deoptimized frame.
  __ pushl(EDX);  // Restore return address.

  // Leaf runtime function DeoptimizeFillFrame expects a Dart frame.
  __ EnterDartFrame(0);
  if (preserve_result) {
    __ pushl(EBX);  // Preserve result as first local.
  }
  __ ReserveAlignedFrameSpace(1 * kWordSize);
  __ movl(Address(ESP, 0), EBP);  // Pass last FP as parameter on stack.
  __ CallRuntime(kDeoptimizeFillFrameRuntimeEntry, 1);
  if (preserve_result) {
    // Restore result into EBX.
    __ movl(EBX, Address(EBP, kFirstLocalSlotFromFp * kWordSize));
  }
  // Code above cannot cause GC.
  __ LeaveFrame();

  // Frame is fully rewritten at this point and it is safe to perform a GC.
  // Materialize any objects that were deferred by FillFrame because they
  // require allocation.
  __ EnterStubFrame();
  if (preserve_result) {
    __ pushl(EBX);  // Preserve result, it will be GC-d here.
  }
  __ pushl(Immediate(Smi::RawValue(0)));  // Space for the result.
  __ CallRuntime(kDeoptimizeMaterializeRuntimeEntry, 0);
  // Result tells stub how many bytes to remove from the expression stack
  // of the bottom-most frame. They were used as materialization arguments.
  __ popl(EBX);
  __ SmiUntag(EBX);
  if (preserve_result) {
    __ popl(EAX);  // Restore result.
  }
  __ LeaveFrame();

  __ popl(ECX);  // Pop return address.
  __ addl(ESP, EBX);  // Remove materialization arguments.
  __ pushl(ECX);  // Push return address.
  __ ret();
}


// TOS: return address + call-instruction-size (5 bytes).
// EAX: result, must be preserved
void StubCode::GenerateDeoptimizeLazyStub(Assembler* assembler) {
  // Correct return address to point just after the call that is being
  // deoptimized.
  __ popl(EBX);
  __ subl(EBX, Immediate(CallPattern::InstructionLength()));
  __ pushl(EBX);
  GenerateDeoptimizationSequence(assembler, true);  // Preserve EAX.
}


void StubCode::GenerateDeoptimizeStub(Assembler* assembler) {
  GenerateDeoptimizationSequence(assembler, false);  // Don't preserve EAX.
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

  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Instructions::null()));
  __ pushl(raw_null);  // Space for the result of the runtime call.
  __ pushl(EAX);  // Pass receiver.
  __ pushl(ECX);  // Pass IC data.
  __ pushl(EDX);  // Pass arguments descriptor.
  __ CallRuntime(kMegamorphicCacheMissHandlerRuntimeEntry, 3);
  // Discard arguments.
  __ popl(EAX);
  __ popl(EAX);
  __ popl(EAX);
  __ popl(EAX);  // Return value from the runtime call (function).
  __ popl(EDX);  // Restore arguments descriptor.
  __ popl(ECX);  // Restore IC data.
  __ LeaveFrame();

  __ movl(EBX, FieldAddress(EAX, Function::instructions_offset()));
  __ addl(EBX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
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
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));

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
  __ j(LESS,  &slow_case);

  // Check for maximum allowed length.
  const Immediate& max_len =
      Immediate(reinterpret_cast<int32_t>(Smi::New(Array::kMaxElements)));
  __ cmpl(EDX, max_len);
  __ j(GREATER, &slow_case);

  const intptr_t fixed_size = sizeof(RawArray) + kObjectAlignment - 1;
  __ leal(EDI, Address(EDX, TIMES_2, fixed_size));  // EDX is Smi.
  ASSERT(kSmiTagShift == 1);
  __ andl(EDI, Immediate(-kObjectAlignment));

  // ECX: array element type.
  // EDX: array length as Smi.
  // EDI: allocation size.

  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

  __ movl(EAX, Address::Absolute(heap->TopAddress()));
  __ movl(EBX, EAX);

  // EDI: allocation size.
  __ addl(EBX, EDI);
  __ j(CARRY, &slow_case);

  // Check if the allocation fits into the remaining space.
  // EAX: potential new object start.
  // EBX: potential next object start.
  // EDI: allocation size.
  // ECX: array element type.
  // EDX: array length as Smi).
  __ cmpl(EBX, Address::Absolute(heap->EndAddress()));
  __ j(ABOVE_EQUAL, &slow_case);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  __ movl(Address::Absolute(heap->TopAddress()), EBX);
  __ addl(EAX, Immediate(kHeapObjectTag));
  __ UpdateAllocationStatsWithSize(kArrayCid, EDI, kNoRegister);

  // Initialize the tags.
  // EAX: new object start as a tagged pointer.
  // EBX: new object end address.
  // EDI: allocation size.
  // ECX: array element type.
  // EDX: array length as Smi.
  {
    Label size_tag_overflow, done;
    __ cmpl(EDI, Immediate(RawObject::SizeTag::kMaxSizeTag));
    __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
    __ shll(EDI, Immediate(RawObject::kSizeTagPos - kObjectAlignmentLog2));
    __ jmp(&done, Assembler::kNearJump);

    __ Bind(&size_tag_overflow);
    __ movl(EDI, Immediate(0));
    __ Bind(&done);

    // Get the class index and insert it into the tags.
    const Class& cls = Class::Handle(isolate->object_store()->array_class());
    __ orl(EDI, Immediate(RawObject::ClassIdTag::encode(cls.id())));
    __ movl(FieldAddress(EAX, Array::tags_offset()), EDI);  // Tags.
  }
  // EAX: new object start as a tagged pointer.
  // EBX: new object end address.
  // ECX: array element type.
  // EDX: Array length as Smi (preserved).
  // Store the type argument field.
  __ StoreIntoObjectNoBarrier(EAX,
                              FieldAddress(EAX, Array::type_arguments_offset()),
                              ECX);

  // Set the length field.
  __ StoreIntoObjectNoBarrier(EAX,
                              FieldAddress(EAX, Array::length_offset()),
                              EDX);

  // Initialize all array elements to raw_null.
  // EAX: new object start as a tagged pointer.
  // EBX: new object end address.
  // EDI: iterator which initially points to the start of the variable
  // data area to be initialized.
  // ECX: array element type.
  // EDX: array length as Smi.
  __ leal(EDI, FieldAddress(EAX, sizeof(RawArray)));
  Label done;
  Label init_loop;
  __ Bind(&init_loop);
  __ cmpl(EDI, EBX);
  __ j(ABOVE_EQUAL, &done, Assembler::kNearJump);
  __ movl(Address(EDI, 0), raw_null);
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
  __ pushl(raw_null);  // Setup space on stack for return value.
  __ pushl(EDX);  // Array length as Smi.
  __ pushl(ECX);  // Element type.
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
//   ESP + 4 : entrypoint of the dart function to call.
//   ESP + 8 : arguments descriptor array.
//   ESP + 12 : arguments array.
//   ESP + 16 : new context containing the current isolate pointer.
// Uses EAX, EDX, ECX, EDI as temporary registers.
void StubCode::GenerateInvokeDartCodeStub(Assembler* assembler) {
  const intptr_t kEntryPointOffset = 2 * kWordSize;
  const intptr_t kArgumentsDescOffset = 3 * kWordSize;
  const intptr_t kArgumentsOffset = 4 * kWordSize;
  const intptr_t kNewContextOffset = 5 * kWordSize;

  // Save frame pointer coming in.
  __ EnterFrame(0);

  // Save C++ ABI callee-saved registers.
  __ pushl(EBX);
  __ pushl(ESI);
  __ pushl(EDI);

  // The new Context structure contains a pointer to the current Isolate
  // structure. Cache the Context pointer in the CTX register so that it is
  // available in generated code and calls to Isolate::Current() need not be
  // done. The assumption is that this register will never be clobbered by
  // compiled or runtime stub code.

  // Cache the new Context pointer into CTX while executing dart code.
  __ movl(CTX, Address(EBP, kNewContextOffset));
  __ movl(CTX, Address(CTX, VMHandles::kOffsetOfRawPtrInHandle));

  // Load Isolate pointer from Context structure into EDI.
  __ movl(EDI, FieldAddress(CTX, Context::isolate_offset()));

  // Save the current VMTag on the stack.
  ASSERT(kSavedVMTagSlotFromEntryFp == -4);
  __ movl(ECX, Address(EDI, Isolate::vm_tag_offset()));
  __ pushl(ECX);

  // Mark that the isolate is executing Dart code.
  __ movl(Address(EDI, Isolate::vm_tag_offset()),
          Immediate(VMTag::kScriptTagId));

  // Save the top exit frame info. Use EDX as a temporary register.
  // StackFrameIterator reads the top exit frame info saved in this frame.
  // The constant kExitLinkSlotFromEntryFp must be kept in sync with the
  // code below.
  ASSERT(kExitLinkSlotFromEntryFp == -5);
  __ movl(EDX, Address(EDI, Isolate::top_exit_frame_info_offset()));
  __ pushl(EDX);
  __ movl(Address(EDI, Isolate::top_exit_frame_info_offset()), Immediate(0));

  // Save the old Context pointer. Use ECX as a temporary register.
  // Note that VisitObjectPointers will find this saved Context pointer during
  // GC marking, since it traverses any information between SP and
  // FP - kExitLinkSlotFromEntryFp.
  // EntryFrame::SavedContext reads the context saved in this frame.
  // The constant kSavedContextSlotFromEntryFp must be kept in sync with
  // the code below.
  ASSERT(kSavedContextSlotFromEntryFp == -6);
  __ movl(ECX, Address(EDI, Isolate::top_context_offset()));
  __ pushl(ECX);

  // TODO(turnidge): This code should probably be emitted all the time
  // on all architectures but I am leaving it under DEBUG/flag for
  // now.
#if defined(DEBUG)
  if (FLAG_verify_incoming_contexts) {
    // Clear Context pointer in Isolate structure.
    const Immediate& raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ movl(Address(EDI, Isolate::top_context_offset()), raw_null);
  }
#endif

  // Load arguments descriptor array into EDX.
  __ movl(EDX, Address(EBP, kArgumentsDescOffset));
  __ movl(EDX, Address(EDX, VMHandles::kOffsetOfRawPtrInHandle));

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
  __ call(Address(EBP, kEntryPointOffset));

  // Reread the Context pointer.
  __ movl(CTX, Address(EBP, kNewContextOffset));
  __ movl(CTX, Address(CTX, VMHandles::kOffsetOfRawPtrInHandle));

  // Reread the arguments descriptor array to obtain the number of passed
  // arguments.
  __ movl(EDX, Address(EBP, kArgumentsDescOffset));
  __ movl(EDX, Address(EDX, VMHandles::kOffsetOfRawPtrInHandle));
  __ movl(EDX, FieldAddress(EDX, ArgumentsDescriptor::count_offset()));
  // Get rid of arguments pushed on the stack.
  __ leal(ESP, Address(ESP, EDX, TIMES_2, 0));  // EDX is a Smi.

  // Load Isolate pointer from Context structure into CTX. Drop Context.
  __ movl(CTX, FieldAddress(CTX, Context::isolate_offset()));

  // Restore the saved Context pointer into the Isolate structure.
  // Uses ECX as a temporary register for this.
  __ popl(ECX);
  __ movl(Address(CTX, Isolate::top_context_offset()), ECX);

  // Restore the saved top exit frame info back into the Isolate structure.
  // Uses EDX as a temporary register for this.
  __ popl(EDX);
  __ movl(Address(CTX, Isolate::top_exit_frame_info_offset()), EDX);

  // Restore the current VMTag from the stack.
  __ popl(ECX);
  __ movl(Address(CTX, Isolate::vm_tag_offset()), ECX);

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
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  if (FLAG_inline_alloc) {
    const Class& context_class = Class::ZoneHandle(Object::context_class());
    Label slow_case;
    Heap* heap = Isolate::Current()->heap();
    // First compute the rounded instance size.
    // EDX: number of context variables.
    intptr_t fixed_size = (sizeof(RawContext) + kObjectAlignment - 1);
    __ leal(EBX, Address(EDX, TIMES_4, fixed_size));
    __ andl(EBX, Immediate(-kObjectAlignment));

    // Now allocate the object.
    // EDX: number of context variables.
    __ movl(EAX, Address::Absolute(heap->TopAddress()));
    __ addl(EBX, EAX);
    // Check if the allocation fits into the remaining space.
    // EAX: potential new object.
    // EBX: potential next object start.
    // EDX: number of context variables.
    __ cmpl(EBX, Address::Absolute(heap->EndAddress()));
    if (FLAG_use_slow_path) {
      __ jmp(&slow_case);
    } else {
      __ j(ABOVE_EQUAL, &slow_case, Assembler::kNearJump);
    }

    // Successfully allocated the object, now update top to point to
    // next object start and initialize the object.
    // EAX: new object.
    // EBX: next object start.
    // EDX: number of context variables.
    __ movl(Address::Absolute(heap->TopAddress()), EBX);
    __ addl(EAX, Immediate(kHeapObjectTag));
    // EBX: Size of allocation in bytes.
    __ subl(EBX, EAX);
    __ UpdateAllocationStatsWithSize(context_class.id(), EBX, kNoRegister);

    // Calculate the size tag.
    // EAX: new object.
    // EDX: number of context variables.
    {
      Label size_tag_overflow, done;
      __ leal(EBX, Address(EDX, TIMES_4, fixed_size));
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
      __ orl(EBX,
             Immediate(RawObject::ClassIdTag::encode(context_class.id())));
      __ movl(FieldAddress(EAX, Context::tags_offset()), EBX);  // Tags.
    }

    // Setup up number of context variables field.
    // EAX: new object.
    // EDX: number of context variables as integer value (not object).
    __ movl(FieldAddress(EAX, Context::num_variables_offset()), EDX);

    // Setup isolate field.
    // Load Isolate pointer from Context structure into EBX.
    // EAX: new object.
    // EDX: number of context variables.
    __ movl(EBX, FieldAddress(CTX, Context::isolate_offset()));
    // EBX: Isolate, not an object.
    __ movl(FieldAddress(EAX, Context::isolate_offset()), EBX);

    const Immediate& raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    // Setup the parent field.
    // EAX: new object.
    // EDX: number of context variables.
    __ movl(FieldAddress(EAX, Context::parent_offset()), raw_null);

    // Initialize the context variables.
    // EAX: new object.
    // EDX: number of context variables.
    {
      Label loop, entry;
      __ leal(EBX, FieldAddress(EAX, Context::variable_offset(0)));

      __ jmp(&entry, Assembler::kNearJump);
      __ Bind(&loop);
      __ decl(EDX);
      __ movl(Address(EBX, EDX, TIMES_4, 0), raw_null);
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
  __ pushl(raw_null);  // Setup space on stack for return value.
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

DECLARE_LEAF_RUNTIME_ENTRY(void, StoreBufferBlockProcess, Isolate* isolate);

// Helper stub to implement Assembler::StoreIntoObject.
// Input parameters:
//   EAX: Address being stored
void StubCode::GenerateUpdateStoreBufferStub(Assembler* assembler) {
  // Save values being destroyed.
  __ pushl(EDX);
  __ pushl(ECX);

  Label add_to_buffer;
  // Check whether this object has already been remembered. Skip adding to the
  // store buffer if the object is in the store buffer already.
  // Spilled: EDX, ECX
  // EAX: Address being stored
  __ movl(ECX, FieldAddress(EAX, Object::tags_offset()));
  __ testl(ECX, Immediate(1 << RawObject::kRememberedBit));
  __ j(EQUAL, &add_to_buffer, Assembler::kNearJump);
  __ popl(ECX);
  __ popl(EDX);
  __ ret();

  __ Bind(&add_to_buffer);
  __ orl(ECX, Immediate(1 << RawObject::kRememberedBit));
  __ movl(FieldAddress(EAX, Object::tags_offset()), ECX);

  // Load the isolate out of the context.
  // Spilled: EDX, ECX
  // EAX: Address being stored
  __ movl(EDX, FieldAddress(CTX, Context::isolate_offset()));

  // Load the StoreBuffer block out of the isolate. Then load top_ out of the
  // StoreBufferBlock and add the address to the pointers_.
  // Spilled: EDX, ECX
  // EAX: Address being stored
  // EDX: Isolate
  __ movl(EDX, Address(EDX, Isolate::store_buffer_offset()));
  __ movl(ECX, Address(EDX, StoreBufferBlock::top_offset()));
  __ movl(Address(EDX, ECX, TIMES_4, StoreBufferBlock::pointers_offset()), EAX);

  // Increment top_ and check for overflow.
  // Spilled: EDX, ECX
  // ECX: top_
  // EDX: StoreBufferBlock
  Label L;
  __ incl(ECX);
  __ movl(Address(EDX, StoreBufferBlock::top_offset()), ECX);
  __ cmpl(ECX, Immediate(StoreBufferBlock::kSize));
  // Restore values.
  // Spilled: EDX, ECX
  __ popl(ECX);
  __ popl(EDX);
  __ j(EQUAL, &L, Assembler::kNearJump);
  __ ret();

  // Handle overflow: Call the runtime leaf function.
  __ Bind(&L);
  // Setup frame, push callee-saved registers.

  __ EnterCallRuntimeFrame(1 * kWordSize);
  __ movl(EAX, FieldAddress(CTX, Context::isolate_offset()));
  __ movl(Address(ESP, 0), EAX);  // Push the isolate as the only argument.
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
  if (FLAG_inline_alloc && Heap::IsAllocatableInNewSpace(instance_size)) {
    Label slow_case;
    // Allocate the object and update top to point to
    // next object start and initialize the allocated object.
    // EDX: instantiated type arguments (if is_cls_parameterized).
    Heap* heap = Isolate::Current()->heap();
    __ movl(EAX, Address::Absolute(heap->TopAddress()));
    __ leal(EBX, Address(EAX, instance_size));
    // Check if the allocation fits into the remaining space.
    // EAX: potential new object start.
    // EBX: potential next object start.
    __ cmpl(EBX, Address::Absolute(heap->EndAddress()));
    if (FLAG_use_slow_path) {
      __ jmp(&slow_case);
    } else {
      __ j(ABOVE_EQUAL, &slow_case);
    }
    __ movl(Address::Absolute(heap->TopAddress()), EBX);
    __ UpdateAllocationStats(cls.id(), ECX);

    // EAX: new object start.
    // EBX: next object start.
    // EDX: new object type arguments (if is_cls_parameterized).
    // Set the tags.
    uword tags = 0;
    tags = RawObject::SizeTag::update(instance_size, tags);
    ASSERT(cls.id() != kIllegalCid);
    tags = RawObject::ClassIdTag::update(cls.id(), tags);
    __ movl(Address(EAX, Instance::tags_offset()), Immediate(tags));

    // Initialize the remaining words of the object.
    const Immediate& raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));

    // EAX: new object start.
    // EBX: next object start.
    // EDX: new object type arguments (if is_cls_parameterized).
    // First try inlining the initialization without a loop.
    if (instance_size < (kInlineInstanceSize * kWordSize)) {
      // Check if the object contains any non-header fields.
      // Small objects are initialized using a consecutive set of writes.
      for (intptr_t current_offset = Instance::NextFieldOffset();
           current_offset < instance_size;
           current_offset += kWordSize) {
        __ movl(Address(EAX, current_offset), raw_null);
      }
    } else {
      __ leal(ECX, Address(EAX, Instance::NextFieldOffset()));
      // Loop until the whole object is initialized.
      // EAX: new object.
      // EBX: next object start.
      // ECX: next word to be initialized.
      // EDX: new object type arguments (if is_cls_parameterized).
      Label init_loop;
      Label done;
      __ Bind(&init_loop);
      __ cmpl(ECX, EBX);
      __ j(ABOVE_EQUAL, &done, Assembler::kNearJump);
      __ movl(Address(ECX, 0), raw_null);
      __ addl(ECX, Immediate(kWordSize));
      __ jmp(&init_loop, Assembler::kNearJump);
      __ Bind(&done);
    }
    if (is_cls_parameterized) {
      // EDX: new object type arguments.
      // Set the type arguments in the new object.
      __ movl(Address(EAX, cls.type_arguments_field_offset()), EDX);
    }
    // Done allocating and initializing the instance.
    // EAX: new object.
    __ addl(EAX, Immediate(kHeapObjectTag));
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
//   ECX : ic-data.
//   EDX : arguments descriptor array.
// Uses EAX, EBX, EDI as temporary registers.
void StubCode::GenerateCallNoSuchMethodFunctionStub(Assembler* assembler) {
  __ EnterStubFrame();

  // Load the receiver.
  __ movl(EDI, FieldAddress(EDX, ArgumentsDescriptor::count_offset()));
  __ movl(EAX, Address(EBP, EDI, TIMES_2, kParamEndSlotFromFp * kWordSize));

  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ pushl(raw_null);  // Setup space on stack for result from noSuchMethod.
  __ pushl(EAX);  // Receiver.
  __ pushl(ECX);  // IC data array.
  __ pushl(EDX);  // Arguments descriptor array.

  __ movl(EDX, EDI);
  // EDX: Smi-tagged arguments array length.
  PushArgumentsArray(assembler);

  __ CallRuntime(kInvokeNoSuchMethodFunctionRuntimeEntry, 4);

  // Remove arguments.
  __ Drop(4);
  __ popl(EAX);  // Get result into EAX.

  // Remove the stub frame as we are about to return.
  __ LeaveFrame();
  __ ret();
}


// Cannot use function object from ICData as it may be the inlined
// function and not the top-scope function.
void StubCode::GenerateOptimizedUsageCounterIncrement(Assembler* assembler) {
  Register ic_reg = ECX;
  Register func_reg = EDI;
  if (FLAG_trace_optimized_ic_calls) {
    __ EnterStubFrame();
    __ pushl(func_reg);     // Preserve
    __ pushl(ic_reg);       // Preserve.
    __ pushl(ic_reg);       // Argument.
    __ pushl(func_reg);     // Argument.
    __ CallRuntime(kTraceICCallRuntimeEntry, 2);
    __ popl(EAX);          // Discard argument;
    __ popl(EAX);          // Discard argument;
    __ popl(ic_reg);       // Restore.
    __ popl(func_reg);     // Restore.
    __ LeaveFrame();
  }
  __ incl(FieldAddress(func_reg, Function::usage_counter_offset()));
}


// Loads function into 'temp_reg'.
void StubCode::GenerateUsageCounterIncrement(Assembler* assembler,
                                             Register temp_reg) {
  Register ic_reg = ECX;
  Register func_reg = temp_reg;
  ASSERT(ic_reg != func_reg);
  __ movl(func_reg, FieldAddress(ic_reg, ICData::owner_offset()));
  __ incl(FieldAddress(func_reg, Function::usage_counter_offset()));
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
    const RuntimeEntry& handle_ic_miss) {
  ASSERT(num_args > 0);
#if defined(DEBUG)
  { Label ok;
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

  if (FLAG_enable_debugger) {
    // Check single stepping.
    Label not_stepping;
    __ movl(EAX, FieldAddress(CTX, Context::isolate_offset()));
    __ movzxb(EAX, Address(EAX, Isolate::single_step_offset()));
    __ cmpl(EAX, Immediate(0));
    __ j(EQUAL, &not_stepping, Assembler::kNearJump);

    __ EnterStubFrame();
    __ pushl(ECX);
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ popl(ECX);
    __ LeaveFrame();
    __ Bind(&not_stepping);
  }

  // ECX: IC data object (preserved).
  // Load arguments descriptor into EDX.
  __ movl(EDX, FieldAddress(ECX, ICData::arguments_descriptor_offset()));
  // Loop that checks if there is an IC data match.
  Label loop, update, test, found;
  // ECX: IC data object (preserved).
  __ movl(EBX, FieldAddress(ECX, ICData::ic_data_offset()));
  // EBX: ic_data_array with check entries: classes and target functions.
  __ leal(EBX, FieldAddress(EBX, Array::data_offset()));
  // EBX: points directly to the first ic data array element.

  // Get the receiver's class ID (first read number of arguments from
  // arguments descriptor array and then access the receiver from the stack).
  __ movl(EAX, FieldAddress(EDX, ArgumentsDescriptor::count_offset()));
  __ movl(EAX, Address(ESP, EAX, TIMES_2, 0));  // EAX (argument_count) is smi.
  __ LoadTaggedClassIdMayBeSmi(EAX, EAX);

  // EAX: receiver's class ID (smi).
  __ movl(EDI, Address(EBX, 0));  // First class id (smi) to check.
  __ jmp(&test);

  __ Bind(&loop);
  for (int i = 0; i < num_args; i++) {
    if (i > 0) {
      // If not the first, load the next argument's class ID.
      __ movl(EAX, FieldAddress(EDX, ArgumentsDescriptor::count_offset()));
      __ movl(EAX, Address(ESP, EAX, TIMES_2, - i * kWordSize));
      __ LoadTaggedClassIdMayBeSmi(EAX, EAX);

      // EAX: next argument class ID (smi).
      __ movl(EDI, Address(EBX, i * kWordSize));
      // EDI: next class ID to check (smi).
    }
    __ cmpl(EAX, EDI);  // Class id match?
    if (i < (num_args - 1)) {
      __ j(NOT_EQUAL, &update);  // Continue.
    } else {
      // Last check, all checks before matched.
      __ j(EQUAL, &found, Assembler::kNearJump);  // Break.
    }
  }
  __ Bind(&update);
  // Reload receiver class ID.  It has not been destroyed when num_args == 1.
  if (num_args > 1) {
    __ movl(EAX, FieldAddress(EDX, ArgumentsDescriptor::count_offset()));
    __ movl(EAX, Address(ESP, EAX, TIMES_2, 0));
    __ LoadTaggedClassIdMayBeSmi(EAX, EAX);
  }

  const intptr_t entry_size = ICData::TestEntryLengthFor(num_args) * kWordSize;
  __ addl(EBX, Immediate(entry_size));  // Next entry.
  __ movl(EDI, Address(EBX, 0));  // Next class ID.

  __ Bind(&test);
  __ cmpl(EDI, Immediate(Smi::RawValue(kIllegalCid)));  // Done?
  __ j(NOT_EQUAL, &loop, Assembler::kNearJump);

  // IC miss.
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  // Compute address of arguments (first read number of arguments from
  // arguments descriptor array and then compute address on the stack).
  __ movl(EAX, FieldAddress(EDX, ArgumentsDescriptor::count_offset()));
  __ leal(EAX, Address(ESP, EAX, TIMES_2, 0));  // EAX is Smi.
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ pushl(EDX);  // Preserve arguments descriptor array.
  __ pushl(ECX);  // Preserve IC data object.
  __ pushl(raw_null);  // Setup space on stack for result (target code object).
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
  __ jmp(&call_target_function);

  __ Bind(&found);
  // EBX: Pointer to an IC data check group.
  const intptr_t target_offset = ICData::TargetIndexFor(num_args) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(num_args) * kWordSize;
  __ movl(EAX, Address(EBX, target_offset));
  __ addl(Address(EBX, count_offset), Immediate(Smi::RawValue(1)));
  __ j(NO_OVERFLOW, &call_target_function, Assembler::kNearJump);
  __ movl(Address(EBX, count_offset),
          Immediate(Smi::RawValue(Smi::kMaxValue)));

  __ Bind(&call_target_function);
  // EAX: Target function.
  __ movl(EBX, FieldAddress(EAX, Function::instructions_offset()));
  __ addl(EBX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ jmp(EBX);
  __ int3();
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
      assembler, 1, kInlineCacheMissHandlerOneArgRuntimeEntry);
}


void StubCode::GenerateTwoArgsCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, EBX);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry);
}


void StubCode::GenerateThreeArgsCheckInlineCacheStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, EBX);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 3, kInlineCacheMissHandlerThreeArgsRuntimeEntry);
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


// Intermediary stub between a static call and its target. ICData contains
// the target function and the call count.
// ECX: ICData
void StubCode::GenerateZeroArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, EBX);

#if defined(DEBUG)
  { Label ok;
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
  if (FLAG_enable_debugger) {
    // Check single stepping.
    Label not_stepping;
    __ movl(EAX, FieldAddress(CTX, Context::isolate_offset()));
    __ movzxb(EAX, Address(EAX, Isolate::single_step_offset()));
    __ cmpl(EAX, Immediate(0));
    __ j(EQUAL, &not_stepping, Assembler::kNearJump);

    __ EnterStubFrame();
    __ pushl(ECX);
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ popl(ECX);
    __ LeaveFrame();
    __ Bind(&not_stepping);
  }

  // ECX: IC data object (preserved).
  __ movl(EBX, FieldAddress(ECX, ICData::ic_data_offset()));
  // EBX: ic_data_array with entries: target functions and count.
  __ leal(EBX, FieldAddress(EBX, Array::data_offset()));
  // EBX: points directly to the first ic data array element.
  const intptr_t target_offset = ICData::TargetIndexFor(0) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(0) * kWordSize;

  // Increment count for this call.
  Label increment_done;
  __ addl(Address(EBX, count_offset), Immediate(Smi::RawValue(1)));
  __ j(NO_OVERFLOW, &increment_done, Assembler::kNearJump);
  __ movl(Address(EBX, count_offset), Immediate(Smi::RawValue(Smi::kMaxValue)));
  __ Bind(&increment_done);

  // Load arguments descriptor into EDX.
  __ movl(EDX, FieldAddress(ECX, ICData::arguments_descriptor_offset()));

  // Get function and call it, if possible.
  __ movl(EAX, Address(EBX, target_offset));
  __ movl(EBX, FieldAddress(EAX, Function::instructions_offset()));

  // EBX: Target instructions.
  __ addl(EBX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ jmp(EBX);
}


void StubCode::GenerateTwoArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, EBX);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kStaticCallMissHandlerTwoArgsRuntimeEntry);
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

  __ movl(EAX, FieldAddress(EAX, Function::instructions_offset()));
  __ addl(EAX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ jmp(EAX);
}


// EDX, ECX: May contain arguments to runtime stub.
void StubCode::GenerateBreakpointRuntimeStub(Assembler* assembler) {
  __ EnterStubFrame();
  // Save runtime args.
  __ pushl(ECX);
  __ pushl(EDX);
  // Room for result. Debugger stub returns address of the
  // unpatched runtime stub.
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ pushl(raw_null);  // Room for result.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ popl(EAX);  // Address of original stub.
  __ popl(EDX);  // Restore arguments.
  __ popl(ECX);
  __ LeaveFrame();
  __ jmp(EAX);   // Jump to original stub.
}


// Called only from unoptimized code.
void StubCode::GenerateDebugStepCheckStub(Assembler* assembler) {
  if (FLAG_enable_debugger) {
    // Check single stepping.
    Label not_stepping;
    __ movl(EAX, FieldAddress(CTX, Context::isolate_offset()));
    __ movzxb(EAX, Address(EAX, Isolate::single_step_offset()));
    __ cmpl(EAX, Immediate(0));
    __ j(EQUAL, &not_stepping, Assembler::kNearJump);

    __ EnterStubFrame();
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ LeaveFrame();
    __ Bind(&not_stepping);
  }
  __ ret();
}


// Used to check class and type arguments. Arguments passed on stack:
// TOS + 0: return address.
// TOS + 1: instantiator type arguments (can be NULL).
// TOS + 2: instance.
// TOS + 3: SubtypeTestCache.
// Result in ECX: null -> not found, otherwise result (true or false).
static void GenerateSubtypeNTestCacheStub(Assembler* assembler, int n) {
  ASSERT((1 <= n) && (n <= 3));
  const intptr_t kInstantiatorTypeArgumentsInBytes = 1 * kWordSize;
  const intptr_t kInstanceOffsetInBytes = 2 * kWordSize;
  const intptr_t kCacheOffsetInBytes = 3 * kWordSize;
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movl(EAX, Address(ESP, kInstanceOffsetInBytes));
  if (n > 1) {
    // Get instance type arguments.
    __ LoadClass(ECX, EAX, EBX);
    // Compute instance type arguments into EBX.
    Label has_no_type_arguments;
    __ movl(EBX, raw_null);
    __ movl(EDI, FieldAddress(ECX,
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
  // EBX: instance type arguments.
  __ SmiTag(ECX);
  __ Bind(&loop);
  __ movl(EDI, Address(EDX, kWordSize * SubtypeTestCache::kInstanceClassId));
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
// TOS + 1: instantiator type arguments or NULL.
// TOS + 2: instance.
// TOS + 3: cache array.
// Result in ECX: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype1TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 1);
}


// Used to check class and type arguments. Arguments passed on stack:
// TOS + 0: return address.
// TOS + 1: instantiator type arguments or NULL.
// TOS + 2: instance.
// TOS + 3: cache array.
// Result in ECX: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype2TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 2);
}


// Used to check class and type arguments. Arguments passed on stack:
// TOS + 0: return address.
// TOS + 1: instantiator type arguments.
// TOS + 2: instance.
// TOS + 3: cache array.
// Result in ECX: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype3TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 3);
}


// Return the current stack pointer address, used to do stack alignment checks.
// TOS + 0: return address
// Result in EAX.
void StubCode::GenerateGetStackPointerStub(Assembler* assembler) {
  __ leal(EAX, Address(ESP, kWordSize));
  __ ret();
}


// Jump to the exception or error handler.
// TOS + 0: return address
// TOS + 1: program_counter
// TOS + 2: stack_pointer
// TOS + 3: frame_pointer
// TOS + 4: exception object
// TOS + 5: stacktrace object
// No Result.
void StubCode::GenerateJumpToExceptionHandlerStub(Assembler* assembler) {
  ASSERT(kExceptionObjectReg == EAX);
  ASSERT(kStackTraceObjectReg == EDX);
  __ movl(kStackTraceObjectReg, Address(ESP, 5 * kWordSize));
  __ movl(kExceptionObjectReg, Address(ESP, 4 * kWordSize));
  __ movl(EBP, Address(ESP, 3 * kWordSize));  // Load target frame_pointer.
  __ movl(EBX, Address(ESP, 1 * kWordSize));  // Load target PC into EBX.
  __ movl(ESP, Address(ESP, 2 * kWordSize));  // Load target stack_pointer.
  __ jmp(EBX);  // Jump to the exception handler code.
}


// Calls to the runtime to optimize the given function.
// EDI: function to be reoptimized.
// EDX: argument descriptor (preserved).
void StubCode::GenerateOptimizeFunctionStub(Assembler* assembler) {
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ EnterStubFrame();
  __ pushl(EDX);
  __ pushl(raw_null);  // Setup space on stack for return value.
  __ pushl(EDI);
  __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry, 1);
  __ popl(EAX);  // Discard argument.
  __ popl(EAX);  // Get Code object
  __ popl(EDX);  // Restore argument descriptor.
  __ movl(EAX, FieldAddress(EAX, Code::instructions_offset()));
  __ addl(EAX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ LeaveFrame();
  __ jmp(EAX);
  __ int3();
}


DECLARE_LEAF_RUNTIME_ENTRY(intptr_t,
                           BigintCompare,
                           RawBigint* left,
                           RawBigint* right);


// Does identical check (object references are equal or not equal) with special
// checks for boxed numbers.
// Return ZF set.
// Note: A Mint cannot contain a value that would fit in Smi, a Bigint
// cannot contain a value that fits in Mint or Smi.
void StubCode::GenerateIdenticalWithNumberCheckStub(Assembler* assembler,
                                                    const Register left,
                                                    const Register right,
                                                    const Register temp,
                                                    const Register unused) {
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
  if (FLAG_enable_debugger) {
    // Check single stepping.
    Label not_stepping;
    __ movl(EAX, FieldAddress(CTX, Context::isolate_offset()));
    __ movzxb(EAX, Address(EAX, Isolate::single_step_offset()));
    __ cmpl(EAX, Immediate(0));
    __ j(EQUAL, &not_stepping, Assembler::kNearJump);

    __ EnterStubFrame();
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ LeaveFrame();
    __ Bind(&not_stepping);
  }

  const Register left = EAX;
  const Register right = EDX;
  const Register temp = ECX;
  __ movl(left, Address(ESP, 2 * kWordSize));
  __ movl(right, Address(ESP, 1 * kWordSize));
  GenerateIdenticalWithNumberCheckStub(assembler, left, right, temp);
  __ ret();
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

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
