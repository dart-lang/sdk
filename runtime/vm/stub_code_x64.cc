// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

#include "vm/native_entry.h"
#include "vm/stub_code.h"

#define __ assembler->

namespace dart {

// Input parameters:
//   RSP : points to return address.
//   RSP + 8 : address of last argument in argument array.
//   RSP + 8*R10 : address of first argument in argument array.
//   RSP + 8*R10 + 8 : address of return value.
//   RBX : address of the runtime function to call.
//   R10 : number of arguments to the call.
static void GenerateCallRuntimeStub(Assembler* assembler) {
  const intptr_t isolate_offset = NativeArguments::isolate_offset();
  const intptr_t argc_offset = NativeArguments::argc_offset();
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
  __ AddImmediate(RSP, Immediate(-sizeof(NativeArguments)));
  if (OS::ActivationFrameAlignment() > 0) {
    __ andq(RSP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass NativeArguments structure by value and call runtime.
  __ movq(Address(RSP, isolate_offset), CTX);  // Set isolate in NativeArgs.
  __ movq(Address(RSP, argc_offset), R10);  // Set argc in NativeArguments.
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
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movq(Address(CTX, Isolate::top_context_offset()), raw_null);

  // Cache Context pointer into CTX while executing Dart code.
  __ movq(CTX, RBX);

  __ LeaveFrame();
  __ ret();
}


// Input parameters:
//   RSP : points to return address.
//   RSP + 8 : address of last argument in argument array.
//   RSP + 8*R10 : address of first argument in argument array.
//   RSP + 8*R10 + 8 : address of return value.
//   RBX : address of the runtime function to call.
//   R10 : number of arguments to the call.
void StubCode::GenerateDartCallToRuntimeStub(Assembler* assembler) {
  GenerateCallRuntimeStub(assembler);
}


// Input parameters:
//   RSP : points to return address.
//   RSP + 8 : address of last argument in argument array.
//   RSP + 8*R10 : address of first argument in argument array.
//   RSP + 8*R10 + 8 : address of return value.
//   RBX : address of the runtime function to call.
//   R10 : number of arguments to the call.
void StubCode::GenerateStubCallToRuntimeStub(Assembler* assembler) {
  GenerateCallRuntimeStub(assembler);
}


// Input parameters:
//   RSP : points to return address.
//   RSP + 8 : address of return value.
//   RAX : address of first argument in argument array.
//   RAX - 8*R10 + 8 : address of last argument in argument array.
//   RBX : address of the native function to call.
//   R10 : number of arguments to the call.
void StubCode::GenerateCallNativeCFunctionStub(Assembler* assembler) {
  const intptr_t native_args_struct_offset = 0;
  const intptr_t isolate_offset =
      NativeArguments::isolate_offset() + native_args_struct_offset;
  const intptr_t argc_offset =
      NativeArguments::argc_offset() + native_args_struct_offset;
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
  __ AddImmediate(RSP, Immediate(-sizeof(NativeArguments)));
  if (OS::ActivationFrameAlignment() > 0) {
    __ andq(RSP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass NativeArguments structure by value and call native function.
  __ movq(Address(RSP, isolate_offset), CTX);  // Set isolate in NativeArgs.
  __ movq(Address(RSP, argc_offset), R10);  // Set argc in NativeArguments.
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
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movq(Address(CTX, Isolate::top_context_offset()), raw_null);

  // Cache Context pointer into CTX while executing Dart code.
  __ movq(CTX, R8);

  __ LeaveFrame();
  __ ret();
}


void StubCode::GenerateCallStaticFunctionStub(Assembler* assembler) {
  __ Unimplemented("CallStaticFunction stub");
}


void StubCode::GenerateStackOverflowStub(Assembler* assembler) {
  __ Unimplemented("StackOverflow stub");
}


void StubCode::GenerateOptimizeInvokedFunctionStub(Assembler* assembler) {
  __ Unimplemented("OptimizeInvokedFunction stub");
}


void StubCode::GenerateFixCallersTargetStub(Assembler* assembler) {
  __ Unimplemented("FixCallersTarget stub");
}


void StubCode::GenerateMegamorphicLookupStub(Assembler* assembler) {
  __ Unimplemented("MegamorphicLookup stub");
}


void StubCode::GenerateDeoptimizeStub(Assembler* assembler) {
  __ Unimplemented("Deoptimize stub");
}


void StubCode::GenerateAllocateArrayStub(Assembler* assembler) {
  __ Unimplemented("AllocateArray stub");
}


void StubCode::GenerateCallClosureFunctionStub(Assembler* assembler) {
  __ Unimplemented("CallClosureFunction stub");
}


// Called when invoking Dart code from C++ (VM code).
// Input parameters:
//   RSP : points to return address.
//   RDI : entrypoint of the Dart function to call.
//   RSI : arguments descriptor array.
//   RDX : pointer to the argument array.
//   RCX : new context containing the current isolate pointer.
void StubCode::GenerateInvokeDartCodeStub(Assembler* assembler) {
  // Save frame pointer coming in.
  __ EnterFrame(0);

  // Save arguments descriptor array and new context.
  const intptr_t kArgumentsDescOffset = -1 * kWordSize;
  __ pushq(RSI);
  const intptr_t kNewContextOffset = -2 * kWordSize;
  __ pushq(RCX);

  // Save C++ ABI callee-saved registers.
  __ pushq(RBX);
  __ pushq(R12);
  __ pushq(R13);
  __ pushq(R14);
  __ pushq(R15);

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
  __ movq(RAX, Address(R8, Isolate::top_exit_frame_info_offset()));
  __ pushq(RAX);
  __ movq(Address(R8, Isolate::top_exit_frame_info_offset()), Immediate(0));

  // StackFrameIterator reads the top exit frame info saved in this frame.
  // The constant kExitLinkOffsetInEntryFrame must be kept in sync with the
  // code above: kExitLinkOffsetInEntryFrame = -8 * kWordSize.

  // Save the old Context pointer. Use RAX as a temporary register.
  // Note that VisitObjectPointers will find this saved Context pointer during
  // GC marking, since it traverses any information between SP and
  // FP - kExitLinkOffsetInEntryFrame.
  __ movq(RAX, Address(R8, Isolate::top_context_offset()));
  __ pushq(RAX);

  // Load arguments descriptor array into R10, which is passed to Dart code.
  __ movq(R10, Address(RSI, VMHandles::kOffsetOfRawPtrInHandle));

  // Load number of arguments into RBX.
  __ movq(RBX, FieldAddress(R10, Array::data_offset()));
  __ SmiUntag(RBX);

  // Set up arguments for the Dart call.
  Label push_arguments;
  Label done_push_arguments;
  __ testq(RBX, RBX);  // check if there are arguments.
  __ j(ZERO, &done_push_arguments, Assembler::kNearJump);
  __ movq(RAX, Immediate(0));
  __ Bind(&push_arguments);
  __ movq(RCX, Address(RDX, RAX, TIMES_8, 0));  // RDX is start of arguments.
  __ movq(RCX, Address(RCX, VMHandles::kOffsetOfRawPtrInHandle));
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
  // arguments, which is the first element of the array, a Smi.
  __ movq(RSI, Address(RBP, kArgumentsDescOffset));
  __ movq(R10, Address(RSI, VMHandles::kOffsetOfRawPtrInHandle));
  __ movq(RDX, FieldAddress(R10, Array::data_offset()));
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


void StubCode::GenerateAllocateContextStub(Assembler* assembler) {
  __ Unimplemented("AllocateContext stub");
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


void StubCode::GenerateInlineCacheStub(Assembler* assembler) {
  __ Unimplemented("InlineCache stub");
}


void StubCode::GenerateBreakpointStaticStub(Assembler* assembler) {
  __ Unimplemented("BreakpointStatic stub");
}


void StubCode::GenerateBreakpointDynamicStub(Assembler* assembler) {
  __ Unimplemented("BreakpointDynamic stub");
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
