// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

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

  __ SetPrologueOffset();
  __ TraceSimMsg("CallToRuntimeStub");
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(RA, Address(SP, 1 * kWordSize));
  __ sw(FP, Address(SP, 0 * kWordSize));
  __ mov(FP, SP);

  // Load current Isolate pointer from Context structure into A0.
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
  __ ReserveAlignedFrameSpace(4 * kWordSize);  // Reserve space for arguments.

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

  // Call runtime or redirection via simulator.
  __ jalr(S5);
  // Retval is next to 1st argument.
  __ delay_slot()->addiu(A3, A2, Immediate(kWordSize));
  __ TraceSimMsg("CallToRuntimeStub return");

  // Reset exit frame information in Isolate structure.
  __ sw(ZR, Address(CTX, Isolate::top_exit_frame_info_offset()));

  // Load Context pointer from Isolate structure into A2.
  __ lw(A2, Address(CTX, Isolate::top_context_offset()));

  // Load null.
  __ LoadImmediate(TMP, reinterpret_cast<intptr_t>(Object::null()));

  // Reset Context pointer in Isolate structure.
  __ sw(TMP, Address(CTX, Isolate::top_context_offset()));

  // Cache Context pointer into CTX while executing Dart code.
  __ mov(CTX, A2);

  __ mov(SP, FP);
  __ lw(RA, Address(SP, 1 * kWordSize));
  __ lw(FP, Address(SP, 0 * kWordSize));
  __ Ret();
  __ delay_slot()->addiu(SP, SP, Immediate(2 * kWordSize));
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
  __ CallRuntime(kPrintStopMessageRuntimeEntry);
  __ LeaveCallRuntimeFrame();
  __ Ret();
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

  __ SetPrologueOffset();
  __ TraceSimMsg("CallNativeCFunctionStub");
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

  // Initialize NativeArguments structure and call native function.
  // Registers A0, A1, A2, and A3 are used.

  ASSERT(isolate_offset == 0 * kWordSize);
  // Set isolate in NativeArgs: A0 already contains CTX.

  // There are no native calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * kWordSize);
  // Set argc in NativeArguments: A1 already contains argc.

  ASSERT(argv_offset == 2 * kWordSize);
  // Set argv in NativeArguments: A2 already contains argv.

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

  __ ReserveAlignedFrameSpace(kWordSize);  // Just passing A0.

  // Call native function or redirection via simulator.
  __ jalr(T5);
  __ TraceSimMsg("CallNativeCFunctionStub return");

  // Reset exit frame information in Isolate structure.
  __ sw(ZR, Address(CTX, Isolate::top_exit_frame_info_offset()));

  // Load Context pointer from Isolate structure into A2.
  __ lw(A2, Address(CTX, Isolate::top_context_offset()));

  // Load null.
  __ LoadImmediate(TMP, reinterpret_cast<intptr_t>(Object::null()));

  // Reset Context pointer in Isolate structure.
  __ sw(TMP, Address(CTX, Isolate::top_context_offset()));

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
  __ TraceSimMsg("CallStaticFunctionStub");
  __ EnterStubFrame();
  // Setup space on stack for return value and preserve arguments descriptor.

  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(S4, Address(SP, 1 * kWordSize));
  __ LoadImmediate(TMP, reinterpret_cast<intptr_t>(Object::null()));
  __ sw(TMP, Address(SP, 0 * kWordSize));

  __ CallRuntime(kPatchStaticCallRuntimeEntry);
  __ TraceSimMsg("CallStaticFunctionStub return");

  // Get Code object result and restore arguments descriptor array.
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ lw(S4, Address(SP, 1 * kWordSize));
  __ addiu(SP, SP, Immediate(2 * kWordSize));

  __ lw(T0, FieldAddress(T0, Code::instructions_offset()));
  __ AddImmediate(T0, Instructions::HeaderSize() - kHeapObjectTag);

  // Remove the stub frame as we are about to jump to the dart function.
  __ LeaveStubFrameAndReturn(T0);
}


// Called from a static call only when an invalid code has been entered
// (invalid because its function was optimized or deoptimized).
// S4: arguments descriptor array.
void StubCode::GenerateFixCallersTargetStub(Assembler* assembler) {
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ TraceSimMsg("FixCallersTarget");
  __ EnterStubFrame();
  // Setup space on stack for return value and preserve arguments descriptor.
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(S4, Address(SP, 1 * kWordSize));
  __ LoadImmediate(TMP, reinterpret_cast<intptr_t>(Object::null()));
  __ sw(TMP, Address(SP, 0 * kWordSize));
  __ CallRuntime(kFixCallersTargetRuntimeEntry);
  // Get Code object result and restore arguments descriptor array.
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ lw(S4, Address(SP, 1 * kWordSize));
  __ addiu(SP, SP, Immediate(2 * kWordSize));

  // Jump to the dart function.
  __ lw(T0, FieldAddress(T0, Code::instructions_offset()));
  __ AddImmediate(T0, T0, Instructions::HeaderSize() - kHeapObjectTag);

  // Remove the stub frame.
  __ LeaveStubFrameAndReturn(T0);
}


// Input parameters:
//   A1: Smi-tagged argument count, may be zero.
//   FP[kParamEndSlotFromFp + 1]: Last argument.
static void PushArgumentsArray(Assembler* assembler) {
  __ TraceSimMsg("PushArgumentsArray");
  // Allocate array to store arguments of caller.
  __ LoadImmediate(A0, reinterpret_cast<intptr_t>(Object::null()));
  // A0: Null element type for raw Array.
  // A1: Smi-tagged argument count, may be zero.
  __ BranchLink(&StubCode::AllocateArrayLabel());
  __ TraceSimMsg("PushArgumentsArray return");
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
  __ lw(TMP, Address(T1));
  __ addiu(A1, A1, Immediate(-Smi::RawValue(1)));
  __ addiu(T1, T1, Immediate(-kWordSize));
  __ addiu(T2, T2, Immediate(kWordSize));
  __ bgez(A1, &loop);
  __ delay_slot()->sw(TMP, Address(T2, -kWordSize));
  __ Bind(&loop_exit);
}


// Input parameters:
//   S5: ic-data.
//   S4: arguments descriptor array.
// Note: The receiver object is the first argument to the function being
//       called, the stub accesses the receiver from this location directly
//       when trying to resolve the call.
void StubCode::GenerateInstanceFunctionLookupStub(Assembler* assembler) {
  __ TraceSimMsg("InstanceFunctionLookupStub");
  __ EnterStubFrame();

  // Load the receiver.
  __ lw(A1, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
  __ sll(TMP1, A1, 1);  // A1 is Smi.
  __ addu(TMP1, FP, TMP1);
  __ lw(T1, Address(TMP1, kParamEndSlotFromFp * kWordSize));

  // Push space for the return value.
  // Push the receiver.
  // Push TMP1 data object.
  // Push arguments descriptor array.
  __ addiu(SP, SP, Immediate(-4 * kWordSize));
  __ LoadImmediate(TMP, reinterpret_cast<intptr_t>(Object::null()));
  __ sw(TMP, Address(SP, 3 * kWordSize));
  __ sw(T1, Address(SP, 2 * kWordSize));
  __ sw(S5, Address(SP, 1 * kWordSize));
  __ sw(S4, Address(SP, 0 * kWordSize));

  // A1: Smi-tagged arguments array length.
  PushArgumentsArray(assembler);
  __ TraceSimMsg("InstanceFunctionLookupStub return");

  __ CallRuntime(kInstanceFunctionLookupRuntimeEntry);

  __ lw(V0, Address(SP, 4 * kWordSize));  // Get result into V0.
  __ addiu(SP, SP, Immediate(5 * kWordSize));    // Remove arguments.

  __ LeaveStubFrameAndReturn();
}


DECLARE_LEAF_RUNTIME_ENTRY(intptr_t, DeoptimizeCopyFrame,
                           intptr_t deopt_reason,
                           uword saved_registers_address);

DECLARE_LEAF_RUNTIME_ENTRY(void, DeoptimizeFillFrame, uword last_fp);


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
  const intptr_t kPushedRegistersSize =
      kNumberOfCpuRegisters * kWordSize +
      4 * kWordSize +  // PP, FP, RA, PC marker.
      kNumberOfFRegisters * kWordSize;

  __ SetPrologueOffset();
  __ TraceSimMsg("GenerateDeoptimizationSequence");
  // DeoptimizeCopyFrame expects a Dart frame, i.e. EnterDartFrame(0), but there
  // is no need to set the correct PC marker or load PP, since they get patched.
  __ addiu(SP, SP, Immediate(-kPushedRegistersSize * kWordSize));
  __ sw(ZR, Address(SP, kPushedRegistersSize - 1 * kWordSize));
  __ sw(RA, Address(SP, kPushedRegistersSize - 2 * kWordSize));
  __ sw(FP, Address(SP, kPushedRegistersSize - 3 * kWordSize));
  __ sw(PP, Address(SP, kPushedRegistersSize - 4 * kWordSize));
  __ addiu(FP, SP, Immediate(kPushedRegistersSize - 3 * kWordSize));

  // The code in this frame may not cause GC. kDeoptimizeCopyFrameRuntimeEntry
  // and kDeoptimizeFillFrameRuntimeEntry are leaf runtime calls.
  const intptr_t saved_result_slot_from_fp =
      kFirstLocalSlotFromFp + 1 - (kNumberOfCpuRegisters - V0);
  // Result in V0 is preserved as part of pushing all registers below.

  // TODO(regis): Should we align the stack before pushing the fpu registers?
  // If we do, saved_result_slot_from_fp is not constant anymore.

  // Push registers in their enumeration order: lowest register number at
  // lowest address.
  for (int i = 0; i < kNumberOfCpuRegisters; i++) {
    const int slot = 4 + kNumberOfCpuRegisters - i;
    Register reg = static_cast<Register>(i);
    __ sw(reg, Address(SP, kPushedRegistersSize - slot * kWordSize));
  }
  for (int i = 0; i < kNumberOfFRegisters; i++) {
    // These go below the CPU registers.
    const int slot = 4 + kNumberOfCpuRegisters + kNumberOfFRegisters - i;
    FRegister reg = static_cast<FRegister>(i);
    __ swc1(reg, Address(SP, kPushedRegistersSize - slot * kWordSize));
  }

  __ mov(A0, SP);  // Pass address of saved registers block.
  __ ReserveAlignedFrameSpace(1 * kWordSize);
  __ CallRuntime(kDeoptimizeCopyFrameRuntimeEntry);
  // Result (V0) is stack-size (FP - SP) in bytes, incl. the return address.

  if (preserve_result) {
    // Restore result into T1 temporarily.
    __ lw(T1, Address(FP, saved_result_slot_from_fp * kWordSize));
  }

  __ addiu(SP, FP, Immediate(-kWordSize));
  __ lw(RA, Address(SP, 2 * kWordSize));
  __ lw(FP, Address(SP, 1 * kWordSize));
  __ lw(PP, Address(SP, 0 * kWordSize));
  __ subu(SP, FP, V0);

  // DeoptimizeFillFrame expects a Dart frame, i.e. EnterDartFrame(0), but there
  // is no need to set the correct PC marker or load PP, since they get patched.
  __ addiu(SP, SP, Immediate(-4 * kWordSize));
  __ sw(ZR, Address(SP, 3 * kWordSize));
  __ sw(RA, Address(SP, 2 * kWordSize));
  __ sw(FP, Address(SP, 1 * kWordSize));
  __ sw(PP, Address(SP, 0 * kWordSize));
  __ addiu(FP, SP, Immediate(kWordSize));

  __ mov(A0, FP);  // Get last FP address.
  if (preserve_result) {
    __ Push(T1);  // Preserve result as first local.
  }
  __ ReserveAlignedFrameSpace(1 * kWordSize);
  __ CallRuntime(kDeoptimizeFillFrameRuntimeEntry);  // Pass last FP in A0.
  if (preserve_result) {
    // Restore result into T1.
    __ lw(T1, Address(FP, kFirstLocalSlotFromFp * kWordSize));
  }
  // Code above cannot cause GC.
  __ addiu(SP, FP, Immediate(-kWordSize));
  __ lw(RA, Address(SP, 2 * kWordSize));
  __ lw(FP, Address(SP, 1 * kWordSize));
  __ lw(PP, Address(SP, 0 * kWordSize));
  __ addiu(SP, SP, Immediate(4 * kWordSize));

  // Frame is fully rewritten at this point and it is safe to perform a GC.
  // Materialize any objects that were deferred by FillFrame because they
  // require allocation.
  __ EnterStubFrame();
  if (preserve_result) {
    __ Push(T1);  // Preserve result, it will be GC-d here.
  }
  __ PushObject(Smi::ZoneHandle());  // Space for the result.
  __ CallRuntime(kDeoptimizeMaterializeRuntimeEntry);
  // Result tells stub how many bytes to remove from the expression stack
  // of the bottom-most frame. They were used as materialization arguments.
  __ Pop(T1);
  if (preserve_result) {
    __ Pop(V0);  // Restore result.
  }
  __ LeaveStubFrame();
  // Remove materialization arguments.
  __ SmiUntag(T1);
  __ addu(SP, SP, T1);
  __ Ret();
}


void StubCode::GenerateDeoptimizeLazyStub(Assembler* assembler) {
  // Correct return address to point just after the call that is being
  // deoptimized.
  __ AddImmediate(RA, -CallPattern::kFixedLengthInBytes);
  GenerateDeoptimizationSequence(assembler, true);  // Preserve V0.
}


void StubCode::GenerateDeoptimizeStub(Assembler* assembler) {
  GenerateDeoptimizationSequence(assembler, false);  // Don't preserve V0.
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
  __ LoadImmediate(TMP, reinterpret_cast<intptr_t>(Object::null()));
  __ sw(TMP, Address(SP, 3 * kWordSize));
  __ sw(T6, Address(SP, 2 * kWordSize));
  __ sw(S5, Address(SP, 1 * kWordSize));
  __ sw(S4, Address(SP, 0 * kWordSize));

  __ CallRuntime(kMegamorphicCacheMissHandlerRuntimeEntry);

  __ lw(T0, Address(SP, 3 * kWordSize));  // Get result.
  __ lw(S4, Address(SP, 4 * kWordSize));  // Restore argument descriptor.
  __ lw(S5, Address(SP, 5 * kWordSize));  // Restore IC data.
  __ addiu(SP, SP, Immediate(6 * kWordSize));

  __ LeaveStubFrame();

  Label nonnull;
  __ BranchNotEqual(T0, reinterpret_cast<int32_t>(Object::null()), &nonnull);
  __ Branch(&StubCode::InstanceFunctionLookupLabel());
  __ Bind(&nonnull);
  __ AddImmediate(T0, Instructions::HeaderSize() - kHeapObjectTag);
  __ jr(T0);
}


// Called for inline allocation of arrays.
// Input parameters:
//   RA: return address.
//   A1: Array length as Smi.
//   A0: array element type (either NULL or an instantiated type).
// NOTE: A1 cannot be clobbered here as the caller relies on it being saved.
// The newly allocated object is returned in V0.
void StubCode::GenerateAllocateArrayStub(Assembler* assembler) {
  __ TraceSimMsg("AllocateArrayStub");
  Label slow_case;
  if (FLAG_inline_alloc) {
    // Compute the size to be allocated, it is based on the array length
    // and is computed as:
    // RoundedAllocationSize((array_length * kwordSize) + sizeof(RawArray)).
    // Assert that length is a Smi.
    __ andi(CMPRES, A1, Immediate(kSmiTagMask));
    if (FLAG_use_slow_path) {
      __ b(&slow_case);
    } else {
      __ bne(CMPRES, ZR, &slow_case);
    }
    __ lw(T0, FieldAddress(CTX, Context::isolate_offset()));
    __ lw(T0, Address(T0, Isolate::heap_offset()));
    __ lw(T0, Address(T0, Heap::new_space_offset()));

    // Calculate and align allocation size.
    // Load new object start and calculate next object start.
    // A0: array element type.
    // A1: Array length as Smi.
    // T0: Points to new space object.
    __ lw(V0, Address(T0, Scavenger::top_offset()));
    intptr_t fixed_size = sizeof(RawArray) + kObjectAlignment - 1;
    __ LoadImmediate(T3, fixed_size);
    __ sll(TMP1, A1, 1);  // A1 is Smi.
    __ addu(T3, T3, TMP1);
    ASSERT(kSmiTagShift == 1);
    __ LoadImmediate(TMP1, ~(kObjectAlignment - 1));
    __ and_(T3, T3, TMP1);
    __ addu(T2, T3, V0);

    // Check if the allocation fits into the remaining space.
    // V0: potential new object start.
    // A0: array element type.
    // A1: array length as Smi.
    // T0: points to new space object.
    // T2: potential next object start.
    // T3: array size.
    __ lw(TMP1, Address(T0, Scavenger::end_offset()));
    __ BranchUnsignedGreaterEqual(T2, TMP1, &slow_case);

    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    // V0: potential new object start.
    // T2: potential next object start.
    // T0: Points to new space object.
    __ sw(T2, Address(T0, Scavenger::top_offset()));
    __ addiu(V0, V0, Immediate(kHeapObjectTag));

    // V0: new object start as a tagged pointer.
    // A0: array element type.
    // A1: Array length as Smi.
    // T2: new object end address.

    // Store the type argument field.
    __ StoreIntoObjectNoBarrier(
        V0,
        FieldAddress(V0, Array::type_arguments_offset()),
        A0);

    // Set the length field.
    __ StoreIntoObjectNoBarrier(
        V0,
        FieldAddress(V0, Array::length_offset()),
        A1);

    // Calculate the size tag.
    // V0: new object start as a tagged pointer.
    // A1: Array length as Smi.
    // T2: new object end address.
    // T3: array size.
    const intptr_t shift = RawObject::kSizeTagBit - kObjectAlignmentLog2;
    // If no size tag overflow, shift T3 left, else set T3 to zero.
    __ LoadImmediate(T4, RawObject::SizeTag::kMaxSizeTag);
    __ sltu(CMPRES, T4, T3);  // CMPRES = T4 < T3 ? 1 : 0
    __ sll(TMP1, T3, shift);  // TMP1 = T3 << shift;
    __ movz(T3, TMP1, CMPRES);  // T3 = T4 >= T3 ? 0 : T3
    __ movn(T3, ZR, CMPRES);  // T3 = T4 < T3 ? TMP1 : T3

    // Get the class index and insert it into the tags.
    __ LoadImmediate(TMP1, RawObject::ClassIdTag::encode(kArrayCid));
    __ or_(T3, T3, TMP1);
    __ sw(T3, FieldAddress(V0, Array::tags_offset()));

    // Initialize all array elements to raw_null.
    // V0: new object start as a tagged pointer.
    // T2: new object end address.
    // A1: Array length as Smi.
    __ AddImmediate(T3, V0, Array::data_offset() - kHeapObjectTag);
    // T3: iterator which initially points to the start of the variable
    // data area to be initialized.

    __ LoadImmediate(T7, reinterpret_cast<intptr_t>(Object::null()));
    Label loop, loop_exit;
    __ BranchUnsignedGreaterEqual(T3, T2, &loop_exit);
    __ Bind(&loop);
    __ addiu(T3, T3, Immediate(kWordSize));
    __ bne(T3, T2, &loop);
    __ delay_slot()->sw(T7, Address(T3, -kWordSize));
    __ Bind(&loop_exit);

    // Done allocating and initializing the array.
    // V0: new object.
    // A1: Array length as Smi (preserved for the caller.)
    __ Ret();
  }

  // Unable to allocate the array using the fast inline code, just call
  // into the runtime.
  __ Bind(&slow_case);
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value.
  // Push array length as Smi and element type.
  __ addiu(SP, SP, Immediate(-3 * kWordSize));
  __ LoadImmediate(TMP, reinterpret_cast<intptr_t>(Object::null()));
  __ sw(TMP, Address(SP, 2 * kWordSize));
  __ sw(A1, Address(SP, 1 * kWordSize));
  __ sw(A0, Address(SP, 0 * kWordSize));
  __ CallRuntime(kAllocateArrayRuntimeEntry);
  __ TraceSimMsg("AllocateArrayStub return");
  // Pop arguments; result is popped in IP.
  __ lw(V0, Address(SP, 2 * kWordSize));
  __ lw(A1, Address(SP, 1 * kWordSize));
  __ lw(A0, Address(SP, 0 * kWordSize));
  __ addiu(SP, SP, Immediate(3 * kWordSize));

  __ LeaveStubFrameAndReturn();
}


// Input parameters:
//   RA: return address.
//   SP: address of last argument.
//   S4: Arguments descriptor array.
// Return: V0.
// Note: The closure object is the first argument to the function being
//       called, the stub accesses the closure from this location directly
//       when trying to resolve the call.
void StubCode::GenerateCallClosureFunctionStub(Assembler* assembler) {
  // Load num_args.
  __ TraceSimMsg("GenerateCallClosureFunctionStub");
  __ lw(T0, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
  __ LoadImmediate(TMP1, Smi::RawValue(1));
  __ subu(T0, T0, TMP1);

  // Load closure object in T1.
  __ sll(T1, T0, 1);  // T0 (num_args - 1) is a Smi.
  __ addu(T1, SP, T1);
  __ lw(T1, Address(T1));

  // Verify that T1 is a closure by checking its class.
  Label not_closure;

  __ LoadImmediate(T7, reinterpret_cast<intptr_t>(Object::null()));

  // See if it is not a closure, but null object.
  __ beq(T1, T7, &not_closure);

  __ andi(CMPRES, T1, Immediate(kSmiTagMask));
  __ beq(CMPRES, ZR, &not_closure);  // Not a closure, but a smi.

  // Verify that the class of the object is a closure class by checking that
  // class.signature_function() is not null.
  __ LoadClass(T0, T1);
  __ lw(T0, FieldAddress(T0, Class::signature_function_offset()));

  // See if actual class is not a closure class.
  __ beq(T0, T7, &not_closure);

  // T0 is just the signature function. Load the actual closure function.
  __ lw(T2, FieldAddress(T1, Closure::function_offset()));

  // Load closure context in CTX; note that CTX has already been preserved.
  __ lw(CTX, FieldAddress(T1, Closure::context_offset()));

  Label function_compiled;
  // Load closure function code in T0.
  __ lw(T0, FieldAddress(T2, Function::code_offset()));
  __ bne(T0, T7, &function_compiled);

  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();

  // Preserve arguments descriptor array and read-only function object argument.
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(S4, Address(SP, 1 * kWordSize));
  __ sw(T2, Address(SP, 0 * kWordSize));
  __ CallRuntime(kCompileFunctionRuntimeEntry);
  __ TraceSimMsg("GenerateCallClosureFunctionStub return");
  // Restore arguments descriptor array and read-only function object argument.
  __ lw(T2, Address(SP, 0 * kWordSize));
  __ lw(S4, Address(SP, 1 * kWordSize));
  __ addiu(SP, SP, Immediate(2 * kWordSize));
  // Restore T0.
  __ lw(T0, FieldAddress(T2, Function::code_offset()));

  // Remove the stub frame as we are about to jump to the closure function.
  __ LeaveStubFrame();

  __ Bind(&function_compiled);
  // T0: Code.
  // S4: Arguments descriptor array.
  __ lw(T0, FieldAddress(T0, Code::instructions_offset()));
  __ AddImmediate(T0, Instructions::HeaderSize() - kHeapObjectTag);
  __ jr(T0);

  __ Bind(&not_closure);
  // Call runtime to attempt to resolve and invoke a call method on a
  // non-closure object, passing the non-closure object and its arguments array,
  // returning here.
  // If no call method exists, throw a NoSuchMethodError.
  // T1: non-closure object.
  // S4: arguments descriptor array.

  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();

  // Setup space on stack for result from error reporting.
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  // Arguments descriptor and raw null.
  __ sw(T7, Address(SP, 1 * kWordSize));
  __ sw(S4, Address(SP, 0 * kWordSize));

  // Load smi-tagged arguments array length, including the non-closure.
  __ lw(A1, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
  PushArgumentsArray(assembler);

  // Stack:
  // TOS + 0: Argument array.
  // TOS + 1: Arguments descriptor array.
  // TOS + 2: Place for result from the call.
  // TOS + 3: Saved FP of previous frame.
  // TOS + 4: Dart code return address.
  // TOS + 5: PC marker (0 for stub).
  // TOS + 6: Last argument of caller.
  // ....
  __ CallRuntime(kInvokeNonClosureRuntimeEntry);
  __ lw(V0, Address(SP, 2 * kWordSize));  // Get result into V0.
  __ addiu(SP, SP, Immediate(3 * kWordSize));  // Remove arguments.

  // Remove the stub frame as we are about to return.
  __ LeaveStubFrameAndReturn();
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
  __ TraceSimMsg("InvokeDartCodeStub");
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
  // FP - kExitLinkSlotFromEntryFp.
  // EntryFrame::SavedContext reads the context saved in this frame.
  __ lw(T1, Address(T2, Isolate::top_context_offset()));

  // The constants kSavedContextSlotFromEntryFp and
  // kExitLinkSlotFromEntryFp must be kept in sync with the code below.
  ASSERT(kExitLinkSlotFromEntryFp == -10);
  ASSERT(kSavedContextSlotFromEntryFp == -11);
  __ sw(T0, Address(SP, 1 * kWordSize));
  __ sw(T1, Address(SP, 0 * kWordSize));

  // After the call, The stack pointer is restored to this location.
  // Pushed A3, S0-7, T0, T1 = 11.

  // Load arguments descriptor array into S4, which is passed to Dart code.
  __ lw(S4, Address(A1, VMHandles::kOffsetOfRawPtrInHandle));

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
  __ jalr(A0);  // S4 is the arguments descriptor array.
  __ TraceSimMsg("InvokeDartCodeStub return");

  // Read the saved new Context pointer.
  __ lw(CTX, Address(FP, kNewContextOffset));
  __ lw(CTX, Address(CTX, VMHandles::kOffsetOfRawPtrInHandle));

  // Get rid of arguments pushed on the stack.
  __ AddImmediate(SP, FP, kSavedContextSlotFromEntryFp * kWordSize);

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
  __ lw(A3, Address(SP, 2 * kWordSize));
  __ addiu(SP, SP, Immediate((3 + kAbiPreservedCpuRegCount) * kWordSize));

  // Restore the frame pointer and return.
  __ LeaveStubFrameAndReturn();
}


// Called for inline allocation of contexts.
// Input:
//   T1: number of context variables.
// Output:
//   V0: new allocated RawContext object.
void StubCode::GenerateAllocateContextStub(Assembler* assembler) {
  __ TraceSimMsg("AllocateContext");
  if (FLAG_inline_alloc) {
    const Class& context_class = Class::ZoneHandle(Object::context_class());
    Label slow_case;
    Heap* heap = Isolate::Current()->heap();
    // First compute the rounded instance size.
    // T1: number of context variables.
    intptr_t fixed_size = sizeof(RawContext) + kObjectAlignment - 1;
    __ LoadImmediate(T2, fixed_size);
    __ sll(T0, T1, 2);
    __ addu(T2, T2, T0);
    ASSERT(kSmiTagShift == 1);
    __ LoadImmediate(T0, ~((kObjectAlignment) - 1));
    __ and_(T2, T2, T0);

    // Now allocate the object.
    // T1: number of context variables.
    // T2: object size.
    __ LoadImmediate(T5, heap->TopAddress());
    __ lw(V0, Address(T5, 0));
    __ addu(T3, T2, V0);

    // Check if the allocation fits into the remaining space.
    // V0: potential new object.
    // T1: number of context variables.
    // T2: object size.
    // T3: potential next object start.
    __ LoadImmediate(TMP1, heap->EndAddress());
    __ lw(TMP1, Address(TMP1, 0));
    if (FLAG_use_slow_path) {
      __ b(&slow_case);
    } else {
      __ BranchUnsignedGreaterEqual(T3, TMP1, &slow_case);
    }

    // Successfully allocated the object, now update top to point to
    // next object start and initialize the object.
    // V0: new object.
    // T1: number of context variables.
    // T2: object size.
    // T3: next object start.
    __ sw(T3, Address(T5, 0));
    __ addiu(V0, V0, Immediate(kHeapObjectTag));

    // Calculate the size tag.
    // V0: new object.
    // T1: number of context variables.
    // T2: object size.
    const intptr_t shift = RawObject::kSizeTagBit - kObjectAlignmentLog2;
    __ LoadImmediate(TMP1, RawObject::SizeTag::kMaxSizeTag);
    __ sltu(CMPRES, TMP1, T2);  // CMPRES = T2 > TMP1 ? 1 : 0.
    __ movn(T2, ZR, CMPRES);  // T2 = CMPRES != 0 ? 0 : T2.
    __ sll(TMP1, T2, shift);  // TMP1 = T2 << shift.
    __ movz(T2, TMP1, CMPRES);  // T2 = CMPRES == 0 ? TMP1 : T2.

    // Get the class index and insert it into the tags.
    // T2: size and bit tags.
    __ LoadImmediate(TMP1, RawObject::ClassIdTag::encode(context_class.id()));
    __ or_(T2, T2, TMP1);
    __ sw(T2, FieldAddress(V0, Context::tags_offset()));

    // Setup up number of context variables field.
    // V0: new object.
    // T1: number of context variables as integer value (not object).
    __ sw(T1, FieldAddress(V0, Context::num_variables_offset()));

    // Setup isolate field.
    // Load Isolate pointer from Context structure into R2.
    // V0: new object.
    // T1: number of context variables.
    __ lw(T2, FieldAddress(CTX, Context::isolate_offset()));
    // T2: isolate, not an object.
    __ sw(T2, FieldAddress(V0, Context::isolate_offset()));

    __ LoadImmediate(T7, reinterpret_cast<intptr_t>(Object::null()));

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
    __ addu(TMP1, T3, T1);
    __ bgtz(T1, &loop);
    __ delay_slot()->sw(T7, Address(TMP1));
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
  __ LoadImmediate(TMP, reinterpret_cast<intptr_t>(Object::null()));
  __ sw(TMP, Address(SP, 1 * kWordSize));  // Store null.
  __ sw(T1, Address(SP, 0 * kWordSize));
  __ CallRuntime(kAllocateContextRuntimeEntry);  // Allocate context.
  __ lw(V0, Address(SP, 1 * kWordSize));  // Get the new context.
  __ addiu(SP, SP, Immediate(2 * kWordSize));  // Pop argument and return.

  // V0: new object
  // Restore the frame pointer.
  __ LeaveStubFrameAndReturn();
}


DECLARE_LEAF_RUNTIME_ENTRY(void, StoreBufferBlockProcess, Isolate* isolate);


// Helper stub to implement Assembler::StoreIntoObject.
// Input parameters:
//   T0: Address (i.e. object) being stored into.
void StubCode::GenerateUpdateStoreBufferStub(Assembler* assembler) {
  // Save values being destroyed.
  __ TraceSimMsg("UpdateStoreBufferStub");
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
  __ andi(CMPRES, T2, Immediate(1 << RawObject::kRememberedBit));
  __ beq(CMPRES, ZR, &add_to_buffer);
  __ lw(T1, Address(SP, 0 * kWordSize));
  __ lw(T2, Address(SP, 1 * kWordSize));
  __ lw(T3, Address(SP, 2 * kWordSize));
  __ addiu(SP, SP, Immediate(3 * kWordSize));
  __ Ret();

  __ Bind(&add_to_buffer);
  __ ori(T2, T2, Immediate(1 << RawObject::kRememberedBit));
  __ sw(T2, FieldAddress(T0, Object::tags_offset()));

  // Load the isolate out of the context.
  // Spilled: T1, T2, T3.
  // T0: Address being stored.
  __ lw(T1, FieldAddress(CTX, Context::isolate_offset()));

  // Load the StoreBuffer block out of the isolate. Then load top_ out of the
  // StoreBufferBlock and add the address to the pointers_.
  // T1: Isolate.
  __ lw(T1, Address(T1, Isolate::store_buffer_offset()));
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

  __ EnterCallRuntimeFrame(1 * kWordSize);
  __ lw(A0, FieldAddress(CTX, Context::isolate_offset()));
  __ CallRuntime(kStoreBufferBlockProcessRuntimeEntry);
  __ TraceSimMsg("UpdateStoreBufferStub return");
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
  __ TraceSimMsg("AllocationStubForClass");
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
      Heap::IsAllocatableInNewSpace(instance_size + type_args_size)) {
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
    __ LoadImmediate(TMP1, heap->EndAddress());
    __ lw(TMP1, Address(TMP1));
    if (FLAG_use_slow_path) {
      __ b(&slow_case);
    } else {
      __ BranchUnsignedGreaterEqual(T3, TMP1, &slow_case);
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

    __ LoadImmediate(T7, reinterpret_cast<intptr_t>(Object::null()));

    // Initialize the remaining words of the object.
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
        __ sw(T7, Address(T2, current_offset));
      }
    } else {
      __ addiu(T4, T2, Immediate(sizeof(RawObject)));
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
      // R1: new object type arguments.
      // Set the type arguments in the new object.
      __ sw(T1, Address(T2, cls.type_arguments_field_offset()));
    }
    // Done allocating and initializing the instance.
    // T2: new object still missing its heap tag.
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
  __ LoadObject(TMP1, cls);

  __ addiu(SP, SP, Immediate(-4 * kWordSize));
  // Space on stack for return value.
  __ LoadImmediate(T7, reinterpret_cast<intptr_t>(Object::null()));
  __ sw(T7, Address(SP, 3 * kWordSize));
  __ sw(TMP1, Address(SP, 2 * kWordSize));  // Class of object to be allocated.

  if (is_cls_parameterized) {
    // Push type arguments of object to be allocated and of instantiator.
    __ sw(T1, Address(SP, 1 * kWordSize));
    __ sw(T0, Address(SP, 0 * kWordSize));
  } else {
    // Push null type arguments and kNoInstantiator.
    __ LoadImmediate(T1, Smi::RawValue(StubCode::kNoInstantiator));
    __ sw(T7, Address(SP, 1 * kWordSize));
    __ sw(T1, Address(SP, 0 * kWordSize));
  }
  __ CallRuntime(kAllocateObjectRuntimeEntry);  // Allocate object.
  __ TraceSimMsg("AllocationStubForClass return");
  // Pop result (newly allocated object).
  __ lw(V0, Address(SP, 3 * kWordSize));
  __ addiu(SP, SP, Immediate(4 * kWordSize));  // Pop arguments.
  // V0: new object
  // Restore the frame pointer and return.
  __ LeaveStubFrameAndReturn(RA, true);
}


// Called for inline allocation of closures.
// Input parameters:
//   RA: return address.
//   SP + 4 : receiver (null if not an implicit instance closure).
//   SP + 0 : type arguments object (null if class is no parameterized).
void StubCode::GenerateAllocationStubForClosure(Assembler* assembler,
                                                const Function& func) {
  ASSERT(func.IsClosureFunction());
  const bool is_implicit_static_closure =
      func.IsImplicitStaticClosureFunction();
  const bool is_implicit_instance_closure =
      func.IsImplicitInstanceClosureFunction();
  const Class& cls = Class::ZoneHandle(func.signature_class());
  const bool has_type_arguments = cls.HasTypeArguments();

  __ TraceSimMsg("AllocationStubForClosure");
  __ EnterStubFrame(true);  // Uses pool pointer to refer to function.
  const intptr_t kTypeArgumentsFPOffset = 3 * kWordSize;
  const intptr_t kReceiverFPOffset = 4 * kWordSize;
  const intptr_t closure_size = Closure::InstanceSize();
  const intptr_t context_size = Context::InstanceSize(1);  // Captured receiver.
  if (FLAG_inline_alloc &&
      Heap::IsAllocatableInNewSpace(closure_size + context_size)) {
    Label slow_case;
    Heap* heap = Isolate::Current()->heap();
    __ LoadImmediate(T5, heap->TopAddress());
    __ lw(T2, Address(T5));
    __ AddImmediate(T3, T2, closure_size);
    if (is_implicit_instance_closure) {
      __ mov(T4, T3);  // T4: new context address.
      __ AddImmediate(T3, context_size);
    }
    // Check if the allocation fits into the remaining space.
    // T2: potential new closure object.
    // T3: address of top of heap.
    // T4: potential new context object (only if is_implicit_closure).
    __ LoadImmediate(TMP1, heap->EndAddress());
    __ lw(TMP1, Address(TMP1));
    if (FLAG_use_slow_path) {
      __ b(&slow_case);
    } else {
      __ BranchUnsignedGreaterEqual(T3, TMP1, &slow_case);
    }

    // Successfully allocated the object, now update top to point to
    // next object start and initialize the object.
    __ sw(T3, Address(T5));

    // T2: new closure object.
    // T4: new context object (only if is_implicit_closure).
    // Set the tags.
    uword tags = 0;
    tags = RawObject::SizeTag::update(closure_size, tags);
    tags = RawObject::ClassIdTag::update(cls.id(), tags);
    __ LoadImmediate(T0, tags);
    __ sw(T0, Address(T2, Instance::tags_offset()));

    // Initialize the function field in the object.
    // T2: new closure object.
    // T4: new context object (only if is_implicit_closure).
    __ LoadObject(T0, func);  // Load function of closure to be allocated.
    __ sw(T0, Address(T2, Closure::function_offset()));

    // Setup the context for this closure.
    if (is_implicit_static_closure) {
      ObjectStore* object_store = Isolate::Current()->object_store();
      ASSERT(object_store != NULL);
      const Context& empty_context =
          Context::ZoneHandle(object_store->empty_context());
      __ LoadObject(T0, empty_context);
      __ sw(T0, Address(T0, Closure::context_offset()));
    } else if (is_implicit_instance_closure) {
      // Initialize the new context capturing the receiver.
      const Class& context_class = Class::ZoneHandle(Object::context_class());
      // Set the tags.
      uword tags = 0;
      tags = RawObject::SizeTag::update(context_size, tags);
      tags = RawObject::ClassIdTag::update(context_class.id(), tags);
      __ LoadImmediate(T0, tags);
      __ sw(T0, Address(T4, Context::tags_offset()));

      // Set number of variables field to 1 (for captured receiver).
      __ LoadImmediate(T0, 1);
      __ sw(T0, Address(T4, Context::num_variables_offset()));

      // Set isolate field to isolate of current context.
      __ lw(T0, FieldAddress(CTX, Context::isolate_offset()));
      __ sw(T0, Address(T4, Context::isolate_offset()));

      // Set the parent to null.
      __ LoadImmediate(TMP, reinterpret_cast<intptr_t>(Object::null()));
      __ sw(TMP, Address(T4, Context::parent_offset()));

      // Initialize the context variable to the receiver.
      __ lw(T0, Address(FP, kReceiverFPOffset));
      __ sw(T0, Address(T4, Context::variable_offset(0)));

      // Set the newly allocated context in the newly allocated closure.
      __ AddImmediate(T1, T4, kHeapObjectTag);
      __ sw(T1, Address(T2, Closure::context_offset()));
    } else {
      __ sw(CTX, Address(T2, Closure::context_offset()));
    }

    // Set the type arguments field in the newly allocated closure.
    __ lw(T0, Address(FP, kTypeArgumentsFPOffset));
    __ sw(T0, Address(T2, Closure::type_arguments_offset()));

    // Done allocating and initializing the instance.
    // V0: new object.
    __ addiu(V0, T2, Immediate(kHeapObjectTag));

    __ LeaveStubFrameAndReturn(RA, true);

    __ Bind(&slow_case);
  }

  // If it's an implicit static closure we need 2 stack slots. Otherwise,
  // If it's an implicit instance closure we need 4 stack slots, o/w only 3.
  int num_slots = 2;
  if (!is_implicit_static_closure) {
    num_slots = is_implicit_instance_closure ? 4 : 3;
  }
  __ addiu(SP, SP, Immediate(-num_slots * kWordSize));
  // Setup space on stack for return value.
  __ LoadImmediate(T7, reinterpret_cast<intptr_t>(Object::null()));
  __ sw(T7, Address(SP, (num_slots - 1) * kWordSize));
  __ LoadObject(TMP1, func);
  __ sw(TMP1, Address(SP, (num_slots - 2) * kWordSize));
  if (is_implicit_static_closure) {
    __ CallRuntime(kAllocateImplicitStaticClosureRuntimeEntry);
    __ TraceSimMsg("AllocationStubForClosure return");
  } else {
    __ mov(T2, T7);
    if (is_implicit_instance_closure) {
      __ lw(T1, Address(FP, kReceiverFPOffset));
      __ sw(T1, Address(SP, (num_slots - 3) * kWordSize));  // Receiver.
    }
    if (has_type_arguments) {
      __ lw(T2, Address(FP, kTypeArgumentsFPOffset));
    }
    __ sw(T2, Address(SP, 0 * kWordSize));

    if (is_implicit_instance_closure) {
      __ CallRuntime(kAllocateImplicitInstanceClosureRuntimeEntry);
      __ TraceSimMsg("AllocationStubForClosure return");
    } else {
      ASSERT(func.IsNonImplicitClosureFunction());
      __ CallRuntime(kAllocateClosureRuntimeEntry);
      __ TraceSimMsg("AllocationStubForClosure return");
    }
  }
  __ lw(V0, Address(SP, (num_slots - 1) * kWordSize));  // Pop function object.
  __ addiu(SP, SP, Immediate(num_slots * kWordSize));

  // V0: new object
  // Restore the frame pointer.
  __ LeaveStubFrameAndReturn(RA, true);
}


// Called for invoking "dynamic noSuchMethod(Invocation invocation)" function
// from the entry code of a dart function after an error in passed argument
// name or number is detected.
// Input parameters:
//  RA : return address.
//  SP : address of last argument.
//  S5: inline cache data object.
//  S4: arguments descriptor array.
void StubCode::GenerateCallNoSuchMethodFunctionStub(Assembler* assembler) {
  __ EnterStubFrame();

  // Load the receiver.
  __ lw(A1, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
  __ sll(TMP, A1, 1);  // A1 is a Smi.
  __ addu(TMP, FP, TMP);
  __ lw(T6, Address(TMP, kParamEndSlotFromFp * kWordSize));

  // Push space for the return value.
  // Push the receiver.
  // Push IC data object.
  // Push arguments descriptor array.
  __ addiu(SP, SP, Immediate(-4 * kWordSize));
  __ LoadImmediate(TMP, reinterpret_cast<intptr_t>(Object::null()));
  __ sw(TMP, Address(SP, 3 * kWordSize));
  __ sw(T6, Address(SP, 2 * kWordSize));
  __ sw(S5, Address(SP, 1 * kWordSize));
  __ sw(S4, Address(SP, 0 * kWordSize));

  // A1: Smi-tagged arguments array length.
  PushArgumentsArray(assembler);

  __ CallRuntime(kInvokeNoSuchMethodFunctionRuntimeEntry);

  __ lw(V0, Address(SP, 4 * kWordSize));  // Get result into V0.
  __ LeaveStubFrameAndReturn();
}


//  T0: function object.
//  S5: inline cache data object.
// Cannot use function object from ICData as it may be the inlined
// function and not the top-scope function.
void StubCode::GenerateOptimizedUsageCounterIncrement(Assembler* assembler) {
  __ TraceSimMsg("OptimizedUsageCounterIncrement");
  Register ic_reg = S5;
  Register func_reg = T0;
  if (FLAG_trace_optimized_ic_calls) {
    __ EnterStubFrame();
    __ addiu(SP, SP, Immediate(-4 * kWordSize));
    __ sw(T0, Address(SP, 3 * kWordSize));
    __ sw(S5, Address(SP, 2 * kWordSize));
    __ sw(ic_reg, Address(SP, 1 * kWordSize));  // Argument.
    __ sw(func_reg, Address(SP, 0 * kWordSize));  // Argument.
    __ CallRuntime(kTraceICCallRuntimeEntry);
    __ lw(S5, Address(SP, 2 * kWordSize));
    __ lw(T0, Address(SP, 3 * kWordSize));
    __ addiu(SP, SP, Immediate(4 * kWordSize));  // Discard argument;
    __ LeaveStubFrame();
  }
  __ lw(T7, FieldAddress(func_reg, Function::usage_counter_offset()));
  Label is_hot;
  if (FlowGraphCompiler::CanOptimize()) {
    ASSERT(FLAG_optimization_counter_threshold > 1);
    __ BranchSignedGreaterEqual(T7, FLAG_optimization_counter_threshold,
                                &is_hot);
    // As long as VM has no OSR do not optimize in the middle of the function
    // but only at exit so that we have collected all type feedback before
    // optimizing.
  }
  __ addiu(T7, T7, Immediate(1));
  __ sw(T7, FieldAddress(func_reg, Function::usage_counter_offset()));
  __ Bind(&is_hot);
}


// Loads function into 'temp_reg'.
void StubCode::GenerateUsageCounterIncrement(Assembler* assembler,
                                             Register temp_reg) {
  __ TraceSimMsg("UsageCounterIncrement");
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
//  RA: return address
//  S5: Inline cache data object.
// Control flow:
// - If receiver is null -> jump to IC miss.
// - If receiver is Smi -> load Smi class.
// - If receiver is not-Smi -> load receiver's class.
// - Check if 'num_args' (including receiver) match any IC data group.
// - Match found -> jump to target.
// - Match not found -> jump to IC miss.
void StubCode::GenerateNArgsCheckInlineCacheStub(Assembler* assembler,
                                                 intptr_t num_args) {
  __ TraceSimMsg("NArgsCheckInlineCacheStub");
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


  // Check single stepping.
  Label not_stepping;
  __ lw(T0, FieldAddress(CTX, Context::isolate_offset()));
  __ lbu(T0, Address(T0, Isolate::single_step_offset()));
  __ BranchEqual(T0, 0, &not_stepping);
  // Call single step callback in debugger.
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(S5, Address(SP, 1 * kWordSize));  // Preserve IC data.
  __ sw(RA, Address(SP, 0 * kWordSize));  // Return address.
  __ CallRuntime(kSingleStepHandlerRuntimeEntry);
  __ lw(RA, Address(SP, 0 * kWordSize));
  __ lw(S5, Address(SP, 1 * kWordSize));
  __ addiu(SP, SP, Immediate(2 * kWordSize));
  __ Bind(&not_stepping);

  // Load argument descriptor into S4.
  __ lw(S4, FieldAddress(S5, ICData::arguments_descriptor_offset()));
  // Preserve return address, since RA is needed for subroutine call.
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
  __ LoadImmediate(TMP1, Smi::RawValue(1));
  __ subu(T1, T1, TMP1);
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
    __ addu(T3, T3, SP);
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
  __ sll(T1, T1, 1);  // T1 is Smi.
  __ addu(T1, SP, T1);
  // T1: address of receiver.
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Preserve IC data object and arguments descriptor array and
  // setup space on stack for result (target code object).
  int num_slots = num_args + 5;
  __ addiu(SP, SP, Immediate(-num_slots * kWordSize));
  __ sw(S5, Address(SP, (num_slots - 1) * kWordSize));
  __ sw(S4, Address(SP, (num_slots - 2) * kWordSize));
  __ LoadImmediate(TMP, reinterpret_cast<intptr_t>(Object::null()));
  __ sw(TMP, Address(SP, (num_slots - 3) * kWordSize));
  // Push call arguments.
  for (intptr_t i = 0; i < num_args; i++) {
    __ lw(TMP1, Address(T1, -i * kWordSize));
    __ sw(TMP1, Address(SP, (num_slots - i - 4) * kWordSize));
  }
  // Pass IC data object and arguments descriptor array.
  __ sw(S5, Address(SP, (num_slots - num_args - 4) * kWordSize));
  __ sw(S4, Address(SP, (num_slots - num_args - 5) * kWordSize));

  if (num_args == 1) {
    __ CallRuntime(kInlineCacheMissHandlerOneArgRuntimeEntry);
  } else if (num_args == 2) {
    __ CallRuntime(kInlineCacheMissHandlerTwoArgsRuntimeEntry);
  } else if (num_args == 3) {
    __ CallRuntime(kInlineCacheMissHandlerThreeArgsRuntimeEntry);
  } else {
    UNIMPLEMENTED();
  }
  __ TraceSimMsg("NArgsCheckInlineCacheStub return");
  // Pop returned code object into T3 (null if not found).
  // Restore arguments descriptor array and IC data array.
  __ lw(T3, Address(SP, (num_slots - 3) * kWordSize));
  __ lw(S4, Address(SP, (num_slots - 2) * kWordSize));
  __ lw(S5, Address(SP, (num_slots - 1) * kWordSize));
  // Remove the call arguments pushed earlier, including the IC data object
  // and the arguments descriptor array.
  __ addiu(SP, SP, Immediate(num_slots * kWordSize));
  __ LeaveStubFrame();
  Label call_target_function;
  __ BranchNotEqual(T3, reinterpret_cast<int32_t>(Object::null()),
                    &call_target_function);

  // NoSuchMethod or closure.
  // Mark IC call that it may be a closure call that does not collect
  // type feedback.
  __ LoadImmediate(TMP1, 1);
  __ Branch(&StubCode::InstanceFunctionLookupLabel());
  __ delay_slot()->sb(TMP1, FieldAddress(S5, ICData::is_closure_call_offset()));

  __ Bind(&found);
  // T0: Pointer to an IC data check group.
  const intptr_t target_offset = ICData::TargetIndexFor(num_args) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(num_args) * kWordSize;
  __ lw(T3, Address(T0, target_offset));
  __ lw(T4, Address(T0, count_offset));

  __ AddImmediateDetectOverflow(T4, T4, Smi::RawValue(1), T5, T6);

  __ bgez(T5, &call_target_function);  // No overflow.
  __ delay_slot()->sw(T4, Address(T0, count_offset));

  __ LoadImmediate(T1, Smi::RawValue(Smi::kMaxValue));
  __ sw(T1, Address(T0, count_offset));

  __ Bind(&call_target_function);
  // T3: Target function.
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
  __ jr(RA);
  __ delay_slot()->addiu(T3, ZR, Immediate(Smi::RawValue(kSmiCid)));

  __ Bind(&not_smi);
  __ LoadClassId(T3, T3);
  __ jr(RA);
  __ delay_slot()->SmiTag(T3);
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


// Intermediary stub between a static call and its target. ICData contains
// the target function and the call count.
// S5: ICData
void StubCode::GenerateUnoptimizedStaticCallStub(Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, T0);
  __ TraceSimMsg("UnoptimizedStaticCallStub");
#if defined(DEBUG)
  { Label ok;
    // Check that the IC data array has NumberOfArgumentsChecked() == 0.
    // 'num_args_tested' is stored as an untagged int.
    __ lw(T0, FieldAddress(S5, ICData::num_args_tested_offset()));
    __ beq(T0, ZR, &ok);
    __ Stop("Incorrect IC data for unoptimized static call");
    __ Bind(&ok);
  }
#endif  // DEBUG

  // Check single stepping.
  Label not_stepping;
  __ lw(T0, FieldAddress(CTX, Context::isolate_offset()));
  __ lbu(T0, Address(T0, Isolate::single_step_offset()));
  __ BranchEqual(T0, 0, &not_stepping);
  // Call single step callback in debugger.
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(S5, Address(SP, 1 * kWordSize));  // Preserve IC data.
  __ sw(RA, Address(SP, 0 * kWordSize));  // Return address.
  __ CallRuntime(kSingleStepHandlerRuntimeEntry);
  __ lw(RA, Address(SP, 0 * kWordSize));
  __ lw(S5, Address(SP, 1 * kWordSize));
  __ addiu(SP, SP, Immediate(2 * kWordSize));
  __ Bind(&not_stepping);


  // S5: IC data object (preserved).
  __ lw(T0, FieldAddress(S5, ICData::ic_data_offset()));
  // T0: ic_data_array with entries: target functions and count.
  __ AddImmediate(T0, Array::data_offset() - kHeapObjectTag);
  // T0: points directly to the first ic data array element.
  const intptr_t target_offset = ICData::TargetIndexFor(0) * kWordSize;
  const intptr_t count_offset = ICData::CountIndexFor(0) * kWordSize;

  // Increment count for this call.
  Label increment_done;
  __ lw(T4, Address(T0, count_offset));
  __ AddImmediateDetectOverflow(T4, T4, Smi::RawValue(1), T5, T6);
  __ bgez(T5, &increment_done);  // No overflow.
  __ delay_slot()->sw(T4, Address(T0, count_offset));

  __ LoadImmediate(T1, Smi::RawValue(Smi::kMaxValue));
  __ sw(T1, Address(T0, count_offset));

  __ Bind(&increment_done);

  Label target_is_compiled;
  // Get function and call it, if possible.
  __ lw(T3, Address(T0, target_offset));
  __ lw(T4, FieldAddress(T3, Function::code_offset()));
  __ LoadImmediate(TMP, reinterpret_cast<intptr_t>(Object::null()));
  __ bne(T4, TMP, &target_is_compiled);

  __ EnterStubFrame();
  // Preserve target function and IC data object.
  // Two preserved registers, one argument (function) => 3 slots.
  __ addiu(SP, SP, Immediate(-3 * kWordSize));
  __ sw(S5, Address(SP, 2 * kWordSize));  // Preserve IC data.
  __ sw(T3, Address(SP, 1 * kWordSize));  // Preserve function.
  __ sw(T3, Address(SP, 0 * kWordSize));  // Function argument.
  __ CallRuntime(kCompileFunctionRuntimeEntry);
  __ lw(T3, Address(SP, 1 * kWordSize));  // Restore function.
  __ lw(S5, Address(SP, 2 * kWordSize));  // Restore IC data.
  __ addiu(SP, SP, Immediate(3 * kWordSize));
  // T3: target function.
  __ lw(T4, FieldAddress(T3, Function::code_offset()));
  __ LeaveStubFrame();

  __ Bind(&target_is_compiled);
  // T4: target code.
  __ lw(T3, FieldAddress(T4, Code::instructions_offset()));
  __ AddImmediate(T3, Instructions::HeaderSize() - kHeapObjectTag);
  __ jr(T3);
  // Load arguments descriptor into S4.
  __ delay_slot()->
      lw(S4,  FieldAddress(S5, ICData::arguments_descriptor_offset()));
}


void StubCode::GenerateBreakpointRuntimeStub(Assembler* assembler) {
  __ Unimplemented("BreakpointRuntime stub");
}


//  RA: return address (Dart code).
//  S5: IC data (unoptimized static call).
void StubCode::GenerateBreakpointStaticStub(Assembler* assembler) {
  __ TraceSimMsg("BreakpointStaticStub");
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Preserve arguments descriptor and make room for result.
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(S5, Address(SP, 1 * kWordSize));
  __ LoadImmediate(TMP, reinterpret_cast<intptr_t>(Object::null()));
  __ sw(TMP, Address(SP, 0 * kWordSize));
  __ CallRuntime(kBreakpointStaticHandlerRuntimeEntry);
  // Pop code object result and restore arguments descriptor.
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ lw(S5, Address(SP, 1 * kWordSize));
  __ addiu(SP, SP, Immediate(2 * kWordSize));
  __ LeaveStubFrame();

  // Now call the static function. The breakpoint handler function
  // ensures that the call target is compiled.
  __ lw(T0, FieldAddress(T0, Code::instructions_offset()));
  __ AddImmediate(T0, Instructions::HeaderSize() - kHeapObjectTag);
  // Load arguments descriptor into S4.
  __ lw(S4, FieldAddress(S5, ICData::arguments_descriptor_offset()));
  __ jr(T0);
}


//  V0: return value.
void StubCode::GenerateBreakpointReturnStub(Assembler* assembler) {
  __ TraceSimMsg("BreakpoingReturnStub");
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ Push(V0);
  __ CallRuntime(kBreakpointReturnHandlerRuntimeEntry);
  __ Pop(V0);
  __ LeaveStubFrame();

  // Instead of returning to the patched Dart function, emulate the
  // smashed return code pattern and return to the function's caller.
  __ LeaveDartFrameAndReturn();
}


//  RA: return address (Dart code).
//  S5: Inline cache data array.
void StubCode::GenerateBreakpointDynamicStub(Assembler* assembler) {
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ TraceSimMsg("BreakpointDynamicStub");
  __ EnterStubFrame();
  __ Push(S5);
  __ CallRuntime(kBreakpointDynamicHandlerRuntimeEntry);
  __ Pop(S5);
  __ LeaveStubFrame();

  // Find out which dispatch stub to call.
  __ lw(TMP1, FieldAddress(S5, ICData::num_args_tested_offset()));

  Label one_arg, two_args, three_args;
  __ BranchEqual(TMP1, 1, &one_arg);
  __ BranchEqual(TMP1, 2, &two_args);
  __ BranchEqual(TMP1, 3, &three_args);
  __ Stop("Unsupported number of arguments tested.");

  __ Bind(&one_arg);
  __ Branch(&StubCode::OneArgCheckInlineCacheLabel());
  __ Bind(&two_args);
  __ Branch(&StubCode::TwoArgsCheckInlineCacheLabel());
  __ Bind(&three_args);
  __ Branch(&StubCode::ThreeArgsCheckInlineCacheLabel());
  __ break_(0);
}


// Used to check class and type arguments. Arguments passed in registers:
// RA: return address.
// A0: instance (must be preserved).
// A1: instantiator type arguments or NULL.
// A2: cache array.
// Result in V0: null -> not found, otherwise result (true or false).
static void GenerateSubtypeNTestCacheStub(Assembler* assembler, int n) {
  __ TraceSimMsg("SubtypeNTestCacheStub");
  ASSERT((1 <= n) && (n <= 3));
  if (n > 1) {
    // Get instance type arguments.
    __ LoadClass(T0, A0);
    // Compute instance type arguments into R4.
    Label has_no_type_arguments;
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

  __ LoadImmediate(T7, reinterpret_cast<intptr_t>(Object::null()));

  Label loop, found, not_found, next_iteration;
  // T0: instance class id.
  // T1: instance type arguments.
  // T2: Entry start.
  // T7: null.
  __ SmiTag(T0);
  __ Bind(&loop);
  __ lw(T3, Address(T2, kWordSize * SubtypeTestCache::kInstanceClassId));
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
      __ beq(T3, A1, &found);
    }
  }
  __ Bind(&next_iteration);
  __ b(&loop);
  __ delay_slot()->addiu(T2, T2,
      Immediate(kWordSize * SubtypeTestCache::kTestEntryLength));
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
// A1: instantiator type arguments or NULL.
// A2: cache array.
// Result in V0: null -> not found, otherwise result (true or false).
void StubCode::GenerateSubtype1TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 1);
}


// Used to check class and type arguments. Arguments passed in registers:
// RA: return address.
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
  __ Ret();
  __ delay_slot()->mov(V0, SP);
}


// Jump to the exception or error handler.
// RA: return address.
// A0: program_counter.
// A1: stack_pointer.
// A2: frame_pointer.
// A3: error object.
// SP: address of stacktrace object.
// Does not return.
void StubCode::GenerateJumpToExceptionHandlerStub(Assembler* assembler) {
  ASSERT(kExceptionObjectReg == V0);
  ASSERT(kStackTraceObjectReg == V1);
  __ mov(V0, A3);  // Exception object.
  __ lw(V1, Address(SP, 0));  // StackTrace object.
  __ mov(FP, A2);  // Frame_pointer.
  __ jr(A0);  // Jump to the exception handler code.
  __ delay_slot()->mov(SP, A1);  // Stack pointer.
}


// Implements equality operator when one of the arguments is null
// (identity check) and updates ICData if necessary.
// RA: return address.
// A1: left argument.
// A0: right argument.
// T0: ICData.
// V0: result.
// TODO(srdjan): Move to VM stubs once Boolean objects become VM objects.
void StubCode::GenerateEqualityWithNullArgStub(Assembler* assembler) {
  __ TraceSimMsg("EqualityWithNullArgStub");
  __ Comment("EqualityWithNullArgStub");
  __ EnterStubFrame();
  static const intptr_t kNumArgsTested = 2;
#if defined(DEBUG)
  { Label ok;
    __ lw(TMP1, FieldAddress(T0, ICData::num_args_tested_offset()));
    __ BranchEqual(TMP1, kNumArgsTested, &ok);
    __ Stop("Incorrect ICData for equality");
    __ Bind(&ok);
  }
#endif  // DEBUG
  // Check IC data, update if needed.
  // T0: IC data object (preserved).
  __ lw(T6, FieldAddress(T0, ICData::ic_data_offset()));
  // T6: ic_data_array with check entries: classes and target functions.
  __ AddImmediate(T6, Array::data_offset() - kHeapObjectTag);
  // T6: points directly to the first ic data array element.

  Label get_class_id_as_smi, no_match, loop, found;
  __ Bind(&loop);
  // Check left.
  __ bal(&get_class_id_as_smi);
  __ delay_slot()->mov(T2, A1);
  __ lw(T3, Address(T6, 0 * kWordSize));
  __ bne(T2, T3, &no_match);  // Class id match?

  // Check right.
  __ bal(&get_class_id_as_smi);
  __ delay_slot()->mov(T2, A0);
  __ lw(T3, Address(T6, 1 * kWordSize));
  __ beq(T2, T3, &found);  // Class id match?
  __ Bind(&no_match);
  // Next check group.
  intptr_t entry_bytes = kWordSize * ICData::TestEntryLengthFor(kNumArgsTested);
  if (Utils::IsInt(kImmBits, entry_bytes)) {
    __ BranchNotEqual(T3, Smi::RawValue(kIllegalCid), &loop);  // Done?
    __ delay_slot()->addiu(T6, T6, Immediate(entry_bytes));
  } else {
    __ AddImmediate(T6, entry_bytes);
    __ BranchNotEqual(T3, Smi::RawValue(kIllegalCid), &loop);  // Done?
  }

  Label update_ic_data;
  __ b(&update_ic_data);

  __ Bind(&found);
  const intptr_t count_offset =
      ICData::CountIndexFor(kNumArgsTested) * kWordSize;
  Label no_overflow;
  __ lw(T1, Address(T6, count_offset));
  __ AddImmediateDetectOverflow(T1, T1, Smi::RawValue(1), CMPRES, T6);
  __ bgez(CMPRES, &no_overflow);
  __ LoadImmediate(TMP1, Smi::RawValue(Smi::kMaxValue));
  __ sw(TMP1, Address(T6, count_offset));  // If overflow.
  __ Bind(&no_overflow);

  Label compute_result;
  __ Bind(&compute_result);
  __ LoadObject(T4, Bool::True());
  __ LoadObject(T5, Bool::False());
  __ subu(CMPRES, A0, A1);
  __ movz(V0, T4, CMPRES);
  __ movn(V0, T5, CMPRES);
  __ LeaveStubFrameAndReturn();

  __ Bind(&get_class_id_as_smi);
  // Test if Smi -> load Smi class for comparison.
  Label not_smi;
  __ andi(CMPRES, T2, Immediate(kSmiTagMask));
  __ bne(CMPRES, ZR, &not_smi);
  __ jr(RA);
  __ delay_slot()->addiu(T2, ZR, Immediate(Smi::RawValue(kSmiCid)));
  __ Bind(&not_smi);
  __ LoadClassId(T2, T2);
  __ jr(RA);
  __ delay_slot()->SmiTag(T2);

  __ Bind(&update_ic_data);
  // T0: ICData
  __ addiu(SP, SP, Immediate(-4 * kWordSize));
  __ sw(A1, Address(SP, 3 * kWordSize));
  __ sw(A0, Address(SP, 2 * kWordSize));
  __ LoadObject(TMP1, Symbols::EqualOperator());  // Target's name.
  __ sw(TMP1, Address(SP, 1 * kWordSize));
  __ sw(T0, Address(SP, 0 * kWordSize));  // ICData.
  __ CallRuntime(kUpdateICDataTwoArgsRuntimeEntry);
  __ lw(A0, Address(SP, 2 * kWordSize));
  __ lw(A1, Address(SP, 3 * kWordSize));
  __ b(&compute_result);
  __ delay_slot()->addiu(SP, SP, Immediate(4 * kWordSize));
}


// Calls to the runtime to optimize the given function.
// T0: function to be reoptimized.
// S4: argument descriptor (preserved).
void StubCode::GenerateOptimizeFunctionStub(Assembler* assembler) {
  __ TraceSimMsg("OptimizeFunctionStub");
  __ EnterStubFrame();
  __ addiu(SP, SP, Immediate(-3 * kWordSize));
  __ sw(S4, Address(SP, 2 * kWordSize));
  // Setup space on stack for return value.
  __ LoadImmediate(TMP, reinterpret_cast<intptr_t>(Object::null()));
  __ sw(TMP, Address(SP, 1 * kWordSize));
  __ sw(T0, Address(SP, 0 * kWordSize));
  __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry);
  __ TraceSimMsg("OptimizeFunctionStub return");
  __ lw(T0, Address(SP, 1 * kWordSize));  // Get Code object
  __ lw(S4, Address(SP, 2 * kWordSize));  // Restore argument descriptor.
  __ addiu(SP, SP, Immediate(3 * kWordSize));  // Discard argument.

  __ lw(T0, FieldAddress(T0, Code::instructions_offset()));
  __ AddImmediate(T0, Instructions::HeaderSize() - kHeapObjectTag);
  __ LeaveStubFrameAndReturn(T0);
  __ break_(0);
}


DECLARE_LEAF_RUNTIME_ENTRY(intptr_t,
                           BigintCompare,
                           RawBigint* left,
                           RawBigint* right);


// Does identical check (object references are equal or not equal) with special
// checks for boxed numbers.
// Returns: CMPRES is zero if equal, non-zero otherwise.
// Note: A Mint cannot contain a value that would fit in Smi, a Bigint
// cannot contain a value that fits in Mint or Smi.
void StubCode::GenerateIdenticalWithNumberCheckStub(Assembler* assembler,
                                                    const Register left,
                                                    const Register right,
                                                    const Register temp1,
                                                    const Register temp2) {
  __ TraceSimMsg("IdenticalWithNumberCheckStub");
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
  __ subu(CMPRES, temp1, temp2);
  __ bne(CMPRES, ZR, &done);

  // Double values bitwise compare.
  __ lw(temp1, FieldAddress(left, Double::value_offset() + 0 * kWordSize));
  __ lw(temp2, FieldAddress(right, Double::value_offset() + 0 * kWordSize));
  __ subu(CMPRES, temp1, temp2);
  __ bne(CMPRES, ZR, &done);
  __ lw(temp1, FieldAddress(left, Double::value_offset() + 1 * kWordSize));
  __ lw(temp2, FieldAddress(right, Double::value_offset() + 1 * kWordSize));
  __ b(&done);
  __ delay_slot()->subu(CMPRES, temp1, temp2);

  __ Bind(&check_mint);
  __ LoadImmediate(temp1, kMintCid);
  __ LoadClassId(temp2, left);
  __ bne(temp1, temp2, &check_bigint);
  __ LoadClassId(temp2, right);
  __ subu(CMPRES, temp1, temp2);
  __ bne(CMPRES, ZR, &done);

  __ lw(temp1, FieldAddress(left, Mint::value_offset() + 0 * kWordSize));
  __ lw(temp2, FieldAddress(right, Mint::value_offset() + 0 * kWordSize));
  __ subu(CMPRES, temp1, temp2);
  __ bne(CMPRES, ZR, &done);
  __ lw(temp1, FieldAddress(left, Mint::value_offset() + 1 * kWordSize));
  __ lw(temp2, FieldAddress(right, Mint::value_offset() + 1 * kWordSize));
  __ b(&done);
  __ delay_slot()->subu(CMPRES, temp1, temp2);

  __ Bind(&check_bigint);
  __ LoadImmediate(temp1, kBigintCid);
  __ LoadClassId(temp2, left);
  __ bne(temp1, temp2, &reference_compare);
  __ LoadClassId(temp2, right);
  __ subu(CMPRES, temp1, temp2);
  __ bne(CMPRES, ZR, &done);

  __ EnterStubFrame();
  __ ReserveAlignedFrameSpace(2 * kWordSize);
  __ sw(left, Address(SP, 1 * kWordSize));
  __ sw(right, Address(SP, 0 * kWordSize));
  __ mov(A0, left);
  __ mov(A1, right);
  __ CallRuntime(kBigintCompareRuntimeEntry);
  __ TraceSimMsg("IdenticalWithNumberCheckStub return");
  // Result in V0, 0 means equal.
  __ LeaveStubFrame();
  __ b(&done);
  __ delay_slot()->mov(CMPRES, V0);

  __ Bind(&reference_compare);
  __ subu(CMPRES, left, right);
  __ Bind(&done);
  // A branch or test after this comparison will check CMPRES == TMP1.
  __ mov(TMP1, ZR);
}


// Called only from unoptimized code. All relevant registers have been saved.
// RA: return address.
// SP + 4: left operand.
// SP + 0: right operand.
// Returns: CMPRES is zero if equal, non-zero otherwise.
void StubCode::GenerateUnoptimizedIdenticalWithNumberCheckStub(
    Assembler* assembler) {
  // Check single stepping.
  Label not_stepping;
  __ lw(T0, FieldAddress(CTX, Context::isolate_offset()));
  __ lbu(T0, Address(T0, Isolate::single_step_offset()));
  __ BranchEqual(T0, 0, &not_stepping);
  // Call single step callback in debugger.
  __ addiu(SP, SP, Immediate(-1 * kWordSize));
  __ sw(RA, Address(SP, 0 * kWordSize));  // Return address.
  __ CallRuntime(kSingleStepHandlerRuntimeEntry);
  __ lw(RA, Address(SP, 0 * kWordSize));
  __ addiu(SP, SP, Immediate(1 * kWordSize));
  __ Bind(&not_stepping);

  const Register temp1 = T2;
  const Register temp2 = T3;
  const Register left = T1;
  const Register right = T0;
  // Preserve left, right.
  __ lw(left, Address(SP, 1 * kWordSize));
  __ lw(right, Address(SP, 0 * kWordSize));
  GenerateIdenticalWithNumberCheckStub(assembler, left, right, temp1, temp2);
  __ Ret();
}


// Called from otpimzied code only. Must preserve any registers that are
// destroyed.
// SP + 4: left operand.
// SP + 0: right operand.
// Returns: CMPRES is zero if equal, non-zero otherwise.
void StubCode::GenerateOptimizedIdenticalWithNumberCheckStub(
    Assembler* assembler) {
  const Register temp1 = T2;
  const Register temp2 = T3;
  const Register left = T1;
  const Register right = T0;
  // Preserve left, right.
  __ addiu(SP, SP, Immediate(-4 * kWordSize));
  __ sw(temp1, Address(SP, 3 * kWordSize));
  __ sw(temp2, Address(SP, 2 * kWordSize));
  __ sw(left, Address(SP, 1 * kWordSize));
  __ sw(right, Address(SP, 0 * kWordSize));
  __ lw(left, Address(SP, 5 * kWordSize));
  __ lw(right, Address(SP, 4 * kWordSize));
  GenerateIdenticalWithNumberCheckStub(assembler, left, right, temp1, temp2);
  __ lw(right, Address(SP, 0 * kWordSize));
  __ lw(left, Address(SP, 1 * kWordSize));
  __ lw(temp2, Address(SP, 2 * kWordSize));
  __ lw(temp1, Address(SP, 3 * kWordSize));
  __ Ret();
  __ delay_slot()->addiu(SP, SP, Immediate(4 * kWordSize));
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
