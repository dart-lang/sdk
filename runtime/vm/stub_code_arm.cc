// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM)

#include "vm/assembler.h"
#include "vm/code_generator.h"
#include "vm/dart_entry.h"
#include "vm/instructions.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"

#define __ assembler->

namespace dart {

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
  {
    // TODO(regis): Add assembler macro for {Load,Store}BasedOffset with no
    // restriction on the offset.
    const intptr_t offset = Isolate::top_exit_frame_info_offset();
    const int32_t offset12_hi = offset & ~kOffset12Mask;  // signed
    const uint32_t offset12_lo = offset & kOffset12Mask;  // unsigned
    __ AddImmediate(IP, R0, offset12_hi);
    __ str(SP, Address(IP, offset12_lo));
  }

  // Save current Context pointer into Isolate structure.
  {
    // TODO(regis): Add assembler macro for {Load,Store}BasedOffset with no
    // restriction on the offset.
    const intptr_t offset = Isolate::top_context_offset();
    const int32_t offset12_hi = offset & ~kOffset12Mask;  // signed
    const uint32_t offset12_lo = offset & kOffset12Mask;  // unsigned
    __ AddImmediate(IP, R0, offset12_hi);
    __ str(CTX, Address(IP, offset12_lo));
  }

  // Cache Isolate pointer into CTX while executing runtime code.
  __ mov(CTX, ShifterOperand(R0));

  // Reserve space for arguments and align frame before entering C++ world.
  // NativeArguments are passed in registers.
  ASSERT(sizeof(NativeArguments) == 4 * kWordSize);
  __ ReserveAlignedFrameSpace(0);

  // Pass NativeArguments structure by value and call runtime.
  // Registers R0, R1, R2, and R3 are used.

  ASSERT(isolate_offset == 0 * kWordSize);
  __ mov(R0, ShifterOperand(CTX));  // Set isolate in NativeArgs.

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
  {
    // TODO(regis): Add assembler macro for {Load,Store}BasedOffset with no
    // restriction on the offset.
    const intptr_t offset = Isolate::top_exit_frame_info_offset();
    const int32_t offset12_hi = offset & ~kOffset12Mask;  // signed
    const uint32_t offset12_lo = offset & kOffset12Mask;  // unsigned
    __ AddImmediate(IP, CTX, offset12_hi);
    __ str(R2, Address(IP, offset12_lo));
  }

  // Load Context pointer from Isolate structure into R2.
  {
    // TODO(regis): Add assembler macro for {Load,Store}BasedOffset with no
    // restriction on the offset.
    const intptr_t offset = Isolate::top_context_offset();
    const int32_t offset12_hi = offset & ~kOffset12Mask;  // signed
    const uint32_t offset12_lo = offset & kOffset12Mask;  // unsigned
    __ AddImmediate(IP, CTX, offset12_hi);
    __ ldr(R2, Address(IP, offset12_lo));
  }

  // Reset Context pointer in Isolate structure.
  __ LoadImmediate(R3, reinterpret_cast<intptr_t>(Object::null()));
  {
    // TODO(regis): Add assembler macro for {Load,Store}BasedOffset with no
    // restriction on the offset.
    const intptr_t offset = Isolate::top_context_offset();
    const int32_t offset12_hi = offset & ~kOffset12Mask;  // signed
    const uint32_t offset12_lo = offset & kOffset12Mask;  // unsigned
    __ AddImmediate(IP, CTX, offset12_hi);
    __ str(R3, Address(IP, offset12_lo));
  }

  // Cache Context pointer into CTX while executing Dart code.
  __ mov(CTX, ShifterOperand(R2));

  __ LeaveFrame((1 << FP) | (1 << LR));
  __ Ret();
}


void StubCode::GeneratePrintStopMessageStub(Assembler* assembler) {
  __ Unimplemented("PrintStopMessage stub");
}


void StubCode::GenerateCallNativeCFunctionStub(Assembler* assembler) {
  __ Unimplemented("CallNativeCFunction stub");
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
  {
    // TODO(regis): Add assembler macro for {Load,Store}BasedOffset with no
    // restriction on the offset.
    const intptr_t offset = Isolate::top_exit_frame_info_offset();
    const int32_t offset12_hi = offset & ~kOffset12Mask;  // signed
    const uint32_t offset12_lo = offset & kOffset12Mask;  // unsigned
    __ AddImmediate(R7, R8, offset12_hi);
    __ ldr(R5, Address(R7, offset12_lo));
    __ LoadImmediate(R6, 0);
    __ str(R6, Address(R7, offset12_lo));
  }

  // Save the old Context pointer. Use R4 as a temporary register.
  // Note that VisitObjectPointers will find this saved Context pointer during
  // GC marking, since it traverses any information between SP and
  // FP - kExitLinkOffsetInEntryFrame.
  // EntryFrame::SavedContext reads the context saved in this frame.
  {
    const intptr_t offset = Isolate::top_context_offset();
    const int32_t offset12_hi = offset & ~kOffset12Mask;  // signed
    const uint32_t offset12_lo = offset & kOffset12Mask;  // unsigned
    __ AddImmediate(R7, R8, offset12_hi);
    __ ldr(R4, Address(R7, offset12_lo));
  }

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
  {
    const intptr_t offset = Isolate::top_context_offset();
    const int32_t offset12_hi = offset & ~kOffset12Mask;  // signed
    const uint32_t offset12_lo = offset & kOffset12Mask;  // unsigned
    __ AddImmediate(R7, CTX, offset12_hi);
    __ str(R4, Address(R7, offset12_lo));
  }
  {
    const intptr_t offset = Isolate::top_exit_frame_info_offset();
    const int32_t offset12_hi = offset & ~kOffset12Mask;  // signed
    const uint32_t offset12_lo = offset & kOffset12Mask;  // unsigned
    __ AddImmediate(R7, CTX, offset12_hi);
    __ str(R5, Address(R7, offset12_lo));
  }

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

#endif  // defined TARGET_ARCH_ARM
