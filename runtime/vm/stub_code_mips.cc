// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

#include "vm/assembler.h"
#include "vm/code_generator.h"
#include "vm/dart_entry.h"
#include "vm/instructions.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"

#define __ assembler->

namespace dart {

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
  __ addiu(SP, SP, Immediate(2 * kWordSize));
  __ Ret();
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
  __ LoadImmediate(A2, 0);
  __ sw(A2, Address(CTX, Isolate::top_exit_frame_info_offset()));

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
  __ addiu(SP, SP, Immediate(2 * kWordSize));
  __ Ret();
}


// Input parameters:
//   S4: arguments descriptor array.
void StubCode::GenerateCallStaticFunctionStub(Assembler* assembler) {
  __ EnterStubFrame();
  // Setup space on stack for return value and preserve arguments descriptor.
  __ LoadImmediate(V0, reinterpret_cast<intptr_t>(Object::null()));

  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(S4, Address(SP, 1 * kWordSize));
  __ sw(V0, Address(SP, 0 * kWordSize));

  __ CallRuntime(kPatchStaticCallRuntimeEntry);

  // Get Code object result and restore arguments descriptor array.
  __ lw(V0, Address(SP, 0 * kWordSize));
  __ lw(S4, Address(SP, 1 * kWordSize));
  __ addiu(SP, SP, Immediate(2 * kWordSize));

  // Remove the stub frame as we are about to jump to the dart function.
  __ LeaveStubFrame();

  __ lw(V0, FieldAddress(V0, Code::instructions_offset()));
  __ addiu(V0, V0, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ jr(V0);
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

  // Save the top exit frame info. Use R5 as a temporary register.
  // StackFrameIterator reads the top exit frame info saved in this frame.
  __ lw(S5, Address(T2, Isolate::top_exit_frame_info_offset()));
  __ LoadImmediate(T0, 0);
  __ sw(T0, Address(T2, Isolate::top_exit_frame_info_offset()));

  // Save the old Context pointer. Use S4 as a temporary register.
  // Note that VisitObjectPointers will find this saved Context pointer during
  // GC marking, since it traverses any information between SP and
  // FP - kExitLinkOffsetInEntryFrame.
  // EntryFrame::SavedContext reads the context saved in this frame.
  __ lw(S4, Address(T2, Isolate::top_context_offset()));

  // The constants kSavedContextOffsetInEntryFrame and
  // kExitLinkOffsetInEntryFrame must be kept in sync with the code below.
  __ sw(S5, Address(SP, 1 * kWordSize));
  __ sw(S4, Address(SP, 0 * kWordSize));

  // after the call, The stack pointer is restored to this location.
  // Pushed A3, S0-7, S4, S5 = 11.
  const intptr_t kSavedContextOffsetInEntryFrame = -11 * kWordSize;

  // Load arguments descriptor array into S4, which is passed to Dart code.
  __ lw(S4, Address(A1, VMHandles::kOffsetOfRawPtrInHandle));

  // Load number of arguments into S5.
  __ lw(S5, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
  __ SmiUntag(S5);

  // Compute address of 'arguments array' data area into A2.
  __ lw(A2, Address(A2, VMHandles::kOffsetOfRawPtrInHandle));
  __ addiu(A2, A2, Immediate(Array::data_offset() - kHeapObjectTag));

  // Set up arguments for the Dart call.
  Label push_arguments;
  Label done_push_arguments;

  __ beq(S5, ZR, &done_push_arguments);  // check if there are arguments.
  __ LoadImmediate(A1, 0);
  __ Bind(&push_arguments);
  __ lw(A3, Address(A2));
  __ Push(A3);
  __ addiu(A2, A2, Immediate(kWordSize));
  __ addiu(A1, A1, Immediate(1));
  __ subu(T0, A1, S5);
  __ bltz(T0, &push_arguments);

  __ Bind(&done_push_arguments);

  // Call the Dart code entrypoint.
  __ jalr(A0);  // S4 is the arguments descriptor array.

  // Read the saved new Context pointer.
  __ lw(CTX, Address(FP, kNewContextOffset));
  __ lw(CTX, Address(CTX, VMHandles::kOffsetOfRawPtrInHandle));

  // Get rid of arguments pushed on the stack.
  __ addiu(SP, FP, Immediate(kSavedContextOffsetInEntryFrame));

  // Load Isolate pointer from Context structure into CTX. Drop Context.
  __ lw(CTX, FieldAddress(CTX, Context::isolate_offset()));

  // Restore the saved Context pointer into the Isolate structure.
  // Uses S4 as a temporary register for this.
  // Restore the saved top exit frame info back into the Isolate structure.
  // Uses S5 as a temporary register for this.
  __ lw(S4, Address(SP, 0 * kWordSize));
  __ lw(S5, Address(SP, 1 * kWordSize));
  __ sw(S4, Address(CTX, Isolate::top_context_offset()));
  __ sw(S5, Address(CTX, Isolate::top_exit_frame_info_offset()));

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


void StubCode::GenerateUpdateStoreBufferStub(Assembler* assembler) {
  __ Unimplemented("UpdateStoreBuffer stub");
}


void StubCode::GenerateAllocationStubForClass(Assembler* assembler,
                                              const Class& cls) {
  __ Unimplemented("AllocateObject stub");
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


void StubCode::GenerateUsageCounterIncrement(Assembler* assembler,
                                             Register temp_reg) {
  __ Unimplemented("UsageCounterIncrement stub");
}


void StubCode::GenerateNArgsCheckInlineCacheStub(Assembler* assembler,
                                                 intptr_t num_args) {
  __ Unimplemented("NArgsCheckInlineCache stub");
}


void StubCode::GenerateOneArgCheckInlineCacheStub(Assembler* assembler) {
  __ Unimplemented("GenerateOneArgCheckInlineCacheStub stub");
}


void StubCode::GenerateTwoArgsCheckInlineCacheStub(Assembler* assembler) {
  __ Unimplemented("GenerateTwoArgsCheckInlineCacheStub stub");
}


void StubCode::GenerateThreeArgsCheckInlineCacheStub(Assembler* assembler) {
  __ Unimplemented("GenerateThreeArgsCheckInlineCacheStub stub");
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


void StubCode::GenerateSubtype1TestCacheStub(Assembler* assembler) {
  __ Unimplemented("Subtype1TestCache Stub");
}


void StubCode::GenerateSubtype2TestCacheStub(Assembler* assembler) {
  __ Unimplemented("Subtype2TestCache Stub");
}


void StubCode::GenerateSubtype3TestCacheStub(Assembler* assembler) {
  __ Unimplemented("Subtype3TestCache Stub");
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
  __ Unimplemented("EqualityWithNullArg stub");
}


void StubCode::GenerateOptimizeFunctionStub(Assembler* assembler) {
  __ Unimplemented("OptimizeFunction stub");
}


void StubCode::GenerateIdenticalWithNumberCheckStub(Assembler* assembler) {
  __ Unimplemented("IdenticalWithNumberCheck stub");
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
