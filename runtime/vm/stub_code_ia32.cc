// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/code_generator.h"
#include "vm/compiler.h"
#include "vm/object_store.h"
#include "vm/pages.h"
#include "vm/resolver.h"
#include "vm/scavenger.h"
#include "vm/stub_code.h"


#define __ assembler->

namespace dart {

DEFINE_FLAG(bool, inline_alloc, true, "Inline allocation of objects.");
DEFINE_FLAG(bool, use_slow_path, false,
    "Set to true for debugging & verifying the slow paths.");
DECLARE_FLAG(int, optimization_counter_threshold);

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
  const intptr_t argc_offset = NativeArguments::argc_offset();
  const intptr_t argv_offset = NativeArguments::argv_offset();
  const intptr_t retval_offset = NativeArguments::retval_offset();

  __ EnterFrame(0);

  // Load current Isolate pointer from Context structure into EAX.
  __ movl(EAX, FieldAddress(CTX, Context::isolate_offset()));

  // Save exit frame information to enable stack walking as we are about
  // to transition to Dart VM C++ code.
  __ movl(Address(EAX, Isolate::top_exit_frame_info_offset()), ESP);

  // Save current Context pointer into Isolate structure.
  __ movl(Address(EAX, Isolate::top_context_offset()), CTX);

  // Cache Isolate pointer into CTX while executing runtime code.
  __ movl(CTX, EAX);

  // Reserve space for arguments and align frame before entering C++ world.
  __ AddImmediate(ESP, Immediate(-sizeof(NativeArguments)));
  if (OS::ActivationFrameAlignment() > 0) {
    __ andl(ESP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass NativeArguments structure by value and call runtime.
  __ movl(Address(ESP, isolate_offset), CTX);  // Set isolate in NativeArgs.
  __ movl(Address(ESP, argc_offset), EDX);  // Set argc in NativeArguments.
  __ leal(EAX, Address(EBP, EDX, TIMES_4, 1 * kWordSize));  // Compute argv.
  __ movl(Address(ESP, argv_offset), EAX);  // Set argv in NativeArguments.
  __ addl(EAX, Immediate(1 * kWordSize));  // Retval is next to 1st argument.
  __ movl(Address(ESP, retval_offset), EAX);  // Set retval in NativeArguments.
  __ call(ECX);

  // Reset exit frame information in Isolate structure.
  __ movl(Address(CTX, Isolate::top_exit_frame_info_offset()), Immediate(0));

  // Load Context pointer from Isolate structure into ECX.
  __ movl(ECX, Address(CTX, Isolate::top_context_offset()));

  // Reset Context pointer in Isolate structure.
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movl(Address(CTX, Isolate::top_context_offset()), raw_null);

  // Cache Context pointer into CTX while executing Dart code.
  __ movl(CTX, ECX);

  __ LeaveFrame();
  __ ret();
}


// Print the stop message.
static void PrintStopMessage(const char* message) {
  OS::Print("Stop message: %s\n", message);
}


// Input parameters:
//   ESP : points to return address.
//   EAX : stop message (const char*).
// Must preserve all registers, except EAX.
void StubCode::GeneratePrintStopMessageStub(Assembler* assembler) {
  // Preserve caller-saved registers.
  __ pushl(ECX);
  __ pushl(EDX);

  __ EnterFrame(0);

  // Reserve space for the native argument and align frame before entering
  // the C++ world.
  __ AddImmediate(ESP, Immediate(-sizeof(kWordSize)));
  if (OS::ActivationFrameAlignment() > 0) {
    __ andl(ESP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass argument and call native function.
  __ movl(Address(ESP, 0), EAX);
  __ movl(EAX, Immediate(reinterpret_cast<uword>(&PrintStopMessage)));
  __ call(EAX);
  __ popl(EAX);

  __ LeaveFrame();

  // Restore caller-saved registers.
  __ popl(EDX);
  __ popl(ECX);

  __ ret();
}


// Input parameters:
//   ESP : points to return address.
//   ESP + 4 : address of return value.
//   EAX : address of first argument in argument array.
//   EAX - 4*EDX + 4 : address of last argument in argument array.
//   ECX : address of the native function to call.
//   EDX : number of arguments to the call.
// Uses EDI.
void StubCode::GenerateCallNativeCFunctionStub(Assembler* assembler) {
  const intptr_t native_args_struct_offset = kWordSize;
  const intptr_t isolate_offset =
      NativeArguments::isolate_offset() + native_args_struct_offset;
  const intptr_t argc_offset =
      NativeArguments::argc_offset() + native_args_struct_offset;
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

  // Save current Context pointer into Isolate structure.
  __ movl(Address(EDI, Isolate::top_context_offset()), CTX);

  // Cache Isolate pointer into CTX while executing native code.
  __ movl(CTX, EDI);

  // Reserve space for the native arguments structure, the outgoing parameter
  // (pointer to the native arguments structure) and align frame before
  // entering the C++ world.
  __ AddImmediate(ESP, Immediate(-sizeof(NativeArguments) - kWordSize));
  if (OS::ActivationFrameAlignment() > 0) {
    __ andl(ESP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass NativeArguments structure by value and call native function.
  __ movl(Address(ESP, isolate_offset), CTX);  // Set isolate in NativeArgs.
  __ movl(Address(ESP, argc_offset), EDX);  // Set argc in NativeArguments.
  __ movl(Address(ESP, argv_offset), EAX);  // Set argv in NativeArguments.
  __ leal(EAX, Address(EBP, 2 * kWordSize));  // Compute return value addr.
  __ movl(Address(ESP, retval_offset), EAX);  // Set retval in NativeArguments.
  __ leal(EAX, Address(ESP, kWordSize));  // Pointer to the NativeArguments.
  __ movl(Address(ESP, 0), EAX);  // Pass the pointer to the NativeArguments.
  __ call(ECX);

  // Reset exit frame information in Isolate structure.
  __ movl(Address(CTX, Isolate::top_exit_frame_info_offset()), Immediate(0));

  // Load Context pointer from Isolate structure into EDI.
  __ movl(EDI, Address(CTX, Isolate::top_context_offset()));

  // Reset Context pointer in Isolate structure.
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movl(Address(CTX, Isolate::top_context_offset()), raw_null);

  // Cache Context pointer into CTX while executing Dart code.
  __ movl(CTX, EDI);

  __ LeaveFrame();
  __ ret();
}


// Input parameters:
//   ECX: function object.
//   EDX: arguments descriptor array (num_args is first Smi element).
void StubCode::GenerateCallStaticFunctionStub(Assembler* assembler) {
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));

  __ movl(EAX, FieldAddress(ECX, Function::code_offset()));
  __ cmpl(EAX, raw_null);
  Label function_compiled;
  __ j(NOT_EQUAL, &function_compiled, Assembler::kNearJump);

  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterFrame(0);

  __ pushl(EDX);  // Preserve arguments descriptor array.
  __ pushl(ECX);
  __ CallRuntime(kCompileFunctionRuntimeEntry);
  __ popl(ECX);  // Restore read-only function object argument in ECX.
  __ popl(EDX);  // Restore arguments descriptor array.
  // Restore EAX.
  __ movl(EAX, FieldAddress(ECX, Function::code_offset()));

  // Remove the stub frame as we are about to jump to the dart function.
  __ LeaveFrame();

  __ Bind(&function_compiled);
  // Patch caller.
  __ EnterFrame(0);

  __ pushl(EDX);  // Preserve arguments descriptor array.
  __ pushl(ECX);  // Preserve function object.
  __ CallRuntime(kPatchStaticCallRuntimeEntry);
  __ popl(ECX);  // Restore function object argument in ECX.
  __ popl(EDX);  // Restore arguments descriptor array.
  // Remove the stub frame as we are about to jump to the dart function.
  __ LeaveFrame();
  __ movl(EAX, FieldAddress(ECX, Function::code_offset()));

  __ movl(ECX, FieldAddress(EAX, Code::instructions_offset()));
  __ addl(ECX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ jmp(ECX);
}


// Called from a static call only when an invalid code has been entered
// (invalid because its function was optimized or deoptimized).
// ECX: function object.
// EDX: arguments descriptor array (num_args is first Smi element).
void StubCode::GenerateFixCallersTargetStub(Assembler* assembler) {
  __ EnterFrame(0);
  __ pushl(EDX);  // Preserve arguments descriptor array.
  __ pushl(ECX);  // Preserve target function.
  __ pushl(ECX);  // Target function.
  __ CallRuntime(kFixCallersTargetRuntimeEntry);
  __ popl(EAX);  // discard argument.
  __ popl(EAX);  // Restore function.
  __ popl(EDX);  // Restore arguments descriptor array.
  __ movl(EAX, FieldAddress(EAX, Function::code_offset()));
  __ movl(EAX, FieldAddress(EAX, Code::instructions_offset()));
  __ addl(EAX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ LeaveFrame();
  __ jmp(EAX);
  __ int3();
}


// Lookup for [function-name, arg count] in 'functions_map_'.
// Input parameters (to be treated as read only, unless calling to target!):
//   ECX: ic-data.
//   EDX: arguments descriptor array (num_args is first Smi element).
//   Stack: return address, arguments.
// If the lookup succeeds we jump to the target method from here, otherwise
// we continue in code generated by the caller of 'MegamorphicLookup'.
static void MegamorphicLookup(Assembler* assembler) {
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label class_in_eax, smi_receiver, null_receiver, not_found;
  // Total number of args is the first Smi in args descriptor array (EDX).
  __ movl(EAX, FieldAddress(EDX, Array::data_offset()));
  __ movl(EAX, Address(ESP, EAX, TIMES_2, 0));  // Get receiver. EAX is a Smi.
  // TODO(srdjan): Remove the special casing below for null receiver, once
  // NullClass is implemented.
  __ cmpl(EAX, raw_null);
  // Use Object class if receiver is null.
  __ j(EQUAL, &null_receiver, Assembler::kNearJump);
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(ZERO, &smi_receiver, Assembler::kNearJump);
  __ movl(EAX, FieldAddress(EAX, Object::class_offset()));
  __ jmp(&class_in_eax, Assembler::kNearJump);
  __ Bind(&smi_receiver);
  // For Smis we need to get the class from the isolate.
  // Load current Isolate pointer from Context structure into EAX.
  __ movl(EAX, FieldAddress(CTX, Context::isolate_offset()));
  __ movl(EAX, Address(EAX, Isolate::object_store_offset()));
  __ movl(EAX, Address(EAX, ObjectStore::smi_class_offset()));
  __ jmp(&class_in_eax, Assembler::kNearJump);
  __ Bind(&null_receiver);
  __ movl(EAX, FieldAddress(CTX, Context::isolate_offset()));
  __ movl(EAX, Address(EAX, Isolate::object_store_offset()));
  __ movl(EAX, Address(EAX, ObjectStore::object_class_offset()));

  __ Bind(&class_in_eax);
  // Class is in EAX.

  Label loop, next_iteration;
  // Get functions_cache, since it is allocated lazily it maybe null.
  __ movl(EAX, FieldAddress(EAX, Class::functions_cache_offset()));
  // Iterate and search for identical name.
  __ leal(EBX, FieldAddress(EAX, Array::data_offset()));

  // EBX is  pointing into content of functions_map_ array.
  __ Bind(&loop);
  __ movl(EDI, Address(EBX, FunctionsCache::kFunctionName * kWordSize));

  __ cmpl(EDI, raw_null);
  __ j(EQUAL, &not_found, Assembler::kNearJump);

  __ cmpl(EDI, FieldAddress(ECX, ICData::target_name_offset()));
  __ j(NOT_EQUAL, &next_iteration, Assembler::kNearJump);

  // Name found, check total argument count and named argument count.
  __ movl(EAX, FieldAddress(EDX, Array::data_offset()));
  // EAX is total argument count as Smi.
  __ movl(EDI, Address(EBX, FunctionsCache::kArgCount * kWordSize));
  __ cmpl(EAX, EDI);  // Compare total argument counts.
  __ j(NOT_EQUAL, &next_iteration, Assembler::kNearJump);
  __ subl(EAX, FieldAddress(EDX, Array::data_offset() + kWordSize));
  // EAX is named argument count as Smi.
  __ movl(EDI, Address(EBX, FunctionsCache::kNamedArgCount * kWordSize));
  __ cmpl(EAX, EDI);  // Compare named argument counts.
  __ j(NOT_EQUAL, &next_iteration, Assembler::kNearJump);

  // Argument count matches, jump to target.
  // EDX: arguments descriptor array.
  __ movl(ECX, Address(EBX, FunctionsCache::kFunction * kWordSize));
  __ movl(ECX, FieldAddress(ECX, Function::code_offset()));
  __ movl(ECX, FieldAddress(ECX, Code::instructions_offset()));
  __ addl(ECX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ jmp(ECX);

  __ Bind(&next_iteration);
  __ AddImmediate(EBX, Immediate(FunctionsCache::kNumEntries * kWordSize));
  __ jmp(&loop, Assembler::kNearJump);

  __ Bind(&not_found);
}


// Input parameters:
//   EDI: argument count, may be zero.
// Uses EAX, EBX, ECX, EDX.
static void PushArgumentsArray(Assembler* assembler, intptr_t arg_offset) {
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));

  // Allocate array to store arguments of caller.
  __ movl(EDX, EDI);  // Arguments array length.
  __ SmiTag(EDX);  // Convert to Smi.
  __ movl(ECX, raw_null);  // Null element type for raw Array.
  __ call(&StubCode::AllocateArrayLabel());
  __ SmiUntag(EDX);
  // EAX: newly allocated array.
  // EDX: length of the array (was preserved by the stub).
  __ pushl(EAX);  // Array is in EAX and on top of stack.
  __ leal(EBX, Address(ESP, EDX, TIMES_4, arg_offset));  // Addr of first arg.
  __ leal(ECX, FieldAddress(EAX, Array::data_offset()));
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


// Input parameters:
//   ECX: ic-data.
//   EDX: arguments descriptor array (num_args is first Smi element).
// Note: The receiver object is the first argument to the function being
//       called, the stub accesses the receiver from this location directly
//       when trying to resolve the call.
// Uses EDI.
void StubCode::GenerateMegamorphicLookupStub(Assembler* assembler) {
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));

  MegamorphicLookup(assembler);
  // Lookup in function_table_ failed, resolve, compile and enter function
  // into function_table_.

  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterFrame(0);

  // Preserve values across call to resolving.
  // Stack at this point:
  // TOS + 0: Saved EBP of previous frame. <== EBP
  // TOS + 1: Dart code return address
  // TOS + 2: Last argument of caller.
  // ....
  // Total number of args is the first Smi in args descriptor array (EDX).
  __ movl(EAX, FieldAddress(EDX, Array::data_offset()));
  __ movl(EAX, Address(ESP, EAX, TIMES_2, kWordSize));  // Get receiver.
  __ pushl(EDX);  // Preserve arguments descriptor array.
  __ pushl(EAX);  // Preserve receiver.
  __ pushl(ECX);  // Preserve ic-data.
  // First resolve the function to get the function object.

  __ pushl(raw_null);  // Setup space on stack for return value.
  __ pushl(EAX);  // Push receiver.
  __ CallRuntime(kResolveCompileInstanceFunctionRuntimeEntry);
  __ popl(EAX);  // Remove receiver pushed earlier.
  __ popl(ECX);  // Pop returned code object into ECX.
  // Pop preserved values
  __ popl(EDX);  // Restore ic-data.
  __ popl(EAX);  // Restore receiver.
  __ popl(EDI);  // Restore arguments descriptor array.

  __ cmpl(ECX, raw_null);
  Label check_implicit_closure;
  __ j(EQUAL, &check_implicit_closure, Assembler::kNearJump);

  // Remove the stub frame as we are about to jump to the dart function.
  __ LeaveFrame();

  __ movl(EDX, EDI);
  __ movl(ECX, FieldAddress(ECX, Code::instructions_offset()));
  __ addl(ECX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ jmp(ECX);

  __ Bind(&check_implicit_closure);
  // EAX: receiver.
  // EDX: ic-data.
  // ECX: raw_null.
  // EDI: arguments descriptor array.
  // The target function was not found.
  // First check to see if this is a getter function and we are
  // trying to create a closure of an instance function.
  // Push values that need to be preserved across runtime call.
  __ pushl(EAX);  // Preserve receiver.
  __ pushl(EDX);  // Preserve ic-data.
  __ pushl(EDI);  // Preserve arguments descriptor array.

  __ pushl(raw_null);  // Setup space on stack for return value.
  __ pushl(EAX);  // Push receiver.
  __ pushl(EDX);  // Ic-data.
  __ CallRuntime(kResolveImplicitClosureFunctionRuntimeEntry);
  __ popl(EAX);
  __ popl(EAX);
  __ popl(ECX);  // Get return value into ECX, might be Closure object.

  // Pop preserved values.
  __ popl(EDI);  // Restore arguments descriptor array.
  __ popl(EDX);  // Restore ic-data.
  __ popl(EAX);  // Restore receiver.

  __ cmpl(ECX, raw_null);
  Label check_implicit_closure_through_getter;
  __ j(EQUAL, &check_implicit_closure_through_getter, Assembler::kNearJump);

  __ movl(EAX, ECX);  // Return value is the closure object.
  // Remove the stub frame as we are about return.
  __ LeaveFrame();
  __ ret();

  __ Bind(&check_implicit_closure_through_getter);
  // EAX: receiver.
  // EDX: ic-data.
  // ECX: raw_null.
  // EDI: arguments descriptor array.
  // This is not the case of an instance so invoke the getter of the
  // same name and see if we get a closure back which we are then
  // supposed to invoke.
  // Push values that need to be preserved across runtime call.
  __ pushl(EAX);  // Preserve receiver.
  __ pushl(EDX);  // Preserve ic-data.
  __ pushl(EDI);  // Preserve arguments descriptor array.

  __ pushl(raw_null);  // Setup space on stack for return value.
  __ pushl(EAX);  // Push receiver.
  __ pushl(EDX);  // Ic-data.
  __ CallRuntime(kResolveImplicitClosureThroughGetterRuntimeEntry);
  __ popl(EDX);  // Pop argument.
  __ popl(EAX);  // Pop argument.
  __ popl(ECX);  // get return value into ECX, might be Closure object.

  // Pop preserved values.
  __ popl(EDI);  // Restore arguments descriptor array.
  __ popl(EDX);  // Restore ic-data.
  __ popl(EAX);  // Restore receiver.

  __ cmpl(ECX, raw_null);
  Label function_not_found;
  __ j(EQUAL, &function_not_found, Assembler::kNearJump);

  // ECX: Closure object.
  // EDI: Arguments descriptor array.
  __ pushl(raw_null);  // Setup space on stack for result from invoking Closure.
  __ pushl(ECX);  // Closure object.
  __ pushl(EDI);  // Arguments descriptor.
  __ movl(EDI, FieldAddress(EDI, Array::data_offset()));
  __ SmiUntag(EDI);
  __ subl(EDI, Immediate(1));  // Arguments array length, minus the receiver.
  PushArgumentsArray(assembler, (kWordSize * 5));
  // Stack layout explaining "(kWordSize * 5)" offset.
  // TOS + 0: Argument array.
  // TOS + 1: Arguments descriptor array.
  // TOS + 2: Closure object.
  // TOS + 3: Place for result from closure function.
  // TOS + 4: Saved EBP of previous frame. <== EBP
  // TOS + 5: Dart code return address
  // TOS + 6: Last argument of caller.
  // ....

  __ CallRuntime(kInvokeImplicitClosureFunctionRuntimeEntry);
  // Remove arguments.
  __ popl(EAX);
  __ popl(EAX);
  __ popl(EAX);
  __ popl(EAX);  // Get result into EAX.

  // Remove the stub frame as we are about to return.
  __ LeaveFrame();
  __ ret();

  __ Bind(&function_not_found);
  // The target function was not found, so invoke method
  // "void noSuchMethod(function_name, args_array)".
  //   EAX: receiver.
  //   EDX: ic-data.
  //   ECX: raw_null.
  //   EDI: argument descriptor array.

  __ pushl(raw_null);  // Setup space on stack for result from noSuchMethod.
  __ pushl(EAX);  // Receiver.
  __ pushl(EDX);  // IC-data.
  __ pushl(EDI);  // Argument descriptor array.
  __ movl(EDI, FieldAddress(EDI, Array::data_offset()));
  __ SmiUntag(EDI);
  __ subl(EDI, Immediate(1));  // Arguments array length, minus the receiver.
  // See stack layout below explaining "wordSize * 6" offset.
  PushArgumentsArray(assembler, (kWordSize * 6));

  // Stack:
  // TOS + 0: Argument array.
  // TOS + 1: Argument descriptor array.
  // TOS + 2: IC-data.
  // TOS + 3: Receiver.
  // TOS + 4: Place for result from noSuchMethod.
  // TOS + 5: Saved EBP of previous frame. <== EBP
  // TOS + 6: Dart code return address
  // TOS + 7: Last argument of caller.
  // ....

  __ CallRuntime(kInvokeNoSuchMethodFunctionRuntimeEntry);
  // Remove arguments.
  __ popl(EAX);
  __ popl(EAX);
  __ popl(EAX);
  __ popl(EAX);
  __ popl(EAX);  // Get result into EAX.

  // Remove the stub frame as we are about to return.
  __ LeaveFrame();
  __ ret();
}


void StubCode::GenerateDeoptimizeStub(Assembler* assembler) {
  __ EnterFrame(0);
  // EAX: deoptimization reason id.
  // Stack at this point:
  // TOS + 0: Saved EBP of function frame that will be deoptimized. <== EBP
  // TOS + 1: Deoptimization point (return address), will be patched.
  // TOS + 2: top-of-stack at deoptimization point (all arguments on stack).
  __ pushl(EAX);
  __ CallRuntime(kDeoptimizeRuntimeEntry);
  __ popl(EAX);
  __ LeaveFrame();
  __ ret();
}


// Called for inline allocation of arrays.
// Input parameters:
//   EDX : Array length as Smi.
//   ECX : array element type (either NULL or an instantiated type).
// Uses EAX, EBX, ECX, EDI  as temporary registers.
// NOTE: EDX cannot be clobbered here as the caller relies on it being saved.
// The newly allocated object is returned in EAX.
void StubCode::GenerateAllocateArrayStub(Assembler* assembler) {
  Label slow_case;
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));

  if (FLAG_inline_alloc) {
    // Compute the size to be allocated, it is based on the array length
    // and it computed as:
    // RoundedAllocationSize((array_length * kwordSize) + sizeof(RawArray)).
    // Assert that length is a Smi.
    __ testl(EDX, Immediate(kSmiTagSize));
    if (FLAG_use_slow_path) {
      __ jmp(&slow_case);
    } else {
      __ j(NOT_ZERO, &slow_case, Assembler::kNearJump);
    }
    __ movl(EDI, FieldAddress(CTX, Context::isolate_offset()));
    __ movl(EDI, Address(EDI, Isolate::heap_offset()));
    __ movl(EDI, Address(EDI, Heap::new_space_offset()));

    // Calculate and align allocation size.
    // Load new object start and calculate next object start.
    // ECX: array element type.
    // EDX: Array length as Smi.
    // EDI: Points to new space object.
    __ movl(EAX, Address(EDI, Scavenger::top_offset()));
    intptr_t fixed_size = sizeof(RawArray) + kObjectAlignment - 1;
    __ leal(EBX, Address(EDX, TIMES_2, fixed_size));  // EDX is Smi.
    ASSERT(kSmiTagShift == 1);
    __ andl(EBX, Immediate(-kObjectAlignment));
    __ leal(EBX, Address(EAX, EBX, TIMES_1, 0));

    // Check if the allocation fits into the remaining space.
    // EAX: potential new object start.
    // EBX: potential next object start.
    // ECX: array element type.
    // EDX: Array length as Smi.
    // EDI: Points to new space object.
    __ cmpl(EBX, Address(EDI, Scavenger::end_offset()));
    __ j(ABOVE_EQUAL, &slow_case, Assembler::kNearJump);

    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    // EAX: potential new object start.
    // EBX: potential next object start.
    // EDX: Array length as Smi.
    // EDI: Points to new space object.
    __ movl(Address(EDI, Scavenger::top_offset()), EBX);
    __ addl(EAX, Immediate(kHeapObjectTag));

    // EAX: new object start as a tagged pointer.
    // EBX: new object end address.
    // ECX: array element type.
    // EDX: Array length as Smi.

    // Store the type argument field.
    __ StoreIntoObject(EAX,
                       FieldAddress(EAX, Array::type_arguments_offset()),
                       ECX);

    // Set the length field.
    __ StoreIntoObject(EAX,
                       FieldAddress(EAX, Array::length_offset()),
                       EDX);

    // EAX: new object start as a tagged pointer.
    // EBX: new object end address.
    // EDX: Array length as Smi.
    // Store class value for array.
    __ movl(ECX, FieldAddress(CTX, Context::isolate_offset()));
    __ movl(ECX, Address(ECX, Isolate::object_store_offset()));
    __ movl(ECX, Address(ECX, ObjectStore::array_class_offset()));
    __ StoreIntoObject(EAX,
                       FieldAddress(EAX, Array::class_offset()),
                       ECX);
    // Calculate the size tag.
    // EAX: new object start as a tagged pointer.
    // EBX: new object end address.
    // EDX: Array length as Smi.
    {
      Label size_tag_overflow, done;
      __ leal(ECX, Address(EDX, TIMES_2, fixed_size));  // EDX is Smi.
      ASSERT(kSmiTagShift == 1);
      __ andl(ECX, Immediate(-kObjectAlignment));
      __ cmpl(ECX, Immediate(RawObject::SizeTag::kMaxSizeTag));
      __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
      __ shll(ECX, Immediate(RawObject::kSizeTagBit - kObjectAlignmentLog2));
      __ jmp(&done);

      __ Bind(&size_tag_overflow);
      __ movl(ECX, Immediate(0));
      __ Bind(&done);

      // Get the class index and insert it into the tags.
      __ orl(ECX, Immediate(RawObject::ClassTag::encode(kArray)));
      __ movl(FieldAddress(EAX, Array::tags_offset()), ECX);
    }

    // Initialize all array elements to raw_null.
    // EAX: new object start as a tagged pointer.
    // EBX: new object end address.
    // EDX: Array length as Smi.
    __ leal(ECX, FieldAddress(EAX, Array::data_offset()));
    // ECX: iterator which initially points to the start of the variable
    // data area to be initialized.
    Label done;
    Label init_loop;
    __ Bind(&init_loop);
    __ cmpl(ECX, EBX);
    __ j(ABOVE_EQUAL, &done, Assembler::kNearJump);
    __ movl(Address(ECX, 0), raw_null);
    __ addl(ECX, Immediate(kWordSize));
    __ jmp(&init_loop, Assembler::kNearJump);
    __ Bind(&done);

    // Done allocating and initializing the array.
    // EAX: new object.
    // EDX: Array length as Smi (preserved for the caller.)
    __ ret();
  }

  // Unable to allocate the array using the fast inline code, just call
  // into the runtime.
  __ Bind(&slow_case);
  __ EnterFrame(0);
  __ pushl(raw_null);  // Setup space on stack for return value.
  __ pushl(EDX);  // Array length as Smi.
  __ pushl(ECX);  // Element type.
  __ CallRuntime(kAllocateArrayRuntimeEntry);
  __ popl(EAX);  // Pop element type argument.
  __ popl(EDX);  // Pop array length argument.
  __ popl(EAX);  // Pop return value from return slot.
  __ LeaveFrame();
  __ ret();
}


// Input parameters:
//   EDX: Arguments descriptor array (num_args is first Smi element, closure
//        object is not included in num_args).
// Note: The closure object is pushed before the first argument to the function
//       being called, the stub accesses the closure from this location directly
//       when setting up the context and resolving the entry point.
// Uses EDI.
void StubCode::GenerateCallClosureFunctionStub(Assembler* assembler) {
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));

  // Total number of args is the first Smi in args descriptor array (EDX).
  __ movl(EAX, FieldAddress(EDX, Array::data_offset()));  // Load num_args.
  // Load closure object in EDI.
  __ movl(EDI, Address(ESP, EAX, TIMES_2, kWordSize));  // EAX is a Smi.

  // Verify that EDI is a closure by checking its class.
  Label not_closure;
  __ cmpl(EDI, raw_null);
  // Not a closure, but null object.
  __ j(EQUAL, &not_closure, Assembler::kNearJump);
  __ testl(EDI, Immediate(kSmiTagMask));
  __ j(ZERO, &not_closure, Assembler::kNearJump);  // Not a closure, but a smi.
  // Verify that the class of the object is a closure class by checking that
  // class.signature_function() is not null.
  __ movl(EAX, FieldAddress(EDI, Object::class_offset()));
  __ movl(EAX, FieldAddress(EAX, Class::signature_function_offset()));
  __ cmpl(EAX, raw_null);
  // Actual class is not a closure class.
  __ j(EQUAL, &not_closure, Assembler::kNearJump);

  // EAX is just the signature function. Load the actual closure function.
  __ movl(ECX, FieldAddress(EDI, Closure::function_offset()));

  // Load closure context in CTX; note that CTX has already been preserved.
  __ movl(CTX, FieldAddress(EDI, Closure::context_offset()));

  // Load closure function code in EAX.
  __ movl(EAX, FieldAddress(ECX, Function::code_offset()));
  __ cmpl(EAX, raw_null);
  Label function_compiled;
  __ j(NOT_EQUAL, &function_compiled, Assembler::kNearJump);

  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterFrame(0);

  __ pushl(EDX);  // Preserve arguments descriptor array.
  __ pushl(ECX);
  __ CallRuntime(kCompileFunctionRuntimeEntry);
  __ popl(ECX);  // Restore read-only function object argument in ECX.
  __ popl(EDX);  // Restore arguments descriptor array.
  // Restore EAX.
  __ movl(EAX, FieldAddress(ECX, Function::code_offset()));

  // Remove the stub frame as we are about to jump to the closure function.
  __ LeaveFrame();

  __ Bind(&function_compiled);
  // EAX: Code.
  // ECX: Function.
  // EDX: Arguments descriptor array (num_args is first Smi element).

  __ movl(ECX, FieldAddress(EAX, Code::instructions_offset()));
  __ addl(ECX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ jmp(ECX);

  __ Bind(&not_closure);
  // Call runtime to report that a closure call was attempted on a non-closure
  // object, passing the non-closure object and its arguments array.
  // EDI: non-closure object.
  // EDX: arguments descriptor array (num_args is first Smi element, closure
  //      object is not included in num_args).

  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterFrame(0);

  __ pushl(raw_null);  // Setup space on stack for result from error reporting.
  __ pushl(EDI);  // Non-closure object.
    // Total number of args is the first Smi in args descriptor array (EDX).
  __ movl(EDI, FieldAddress(EDX, Array::data_offset()));  // Load num_args.
  __ SmiUntag(EDI);
  // See stack layout below explaining "wordSize * 4" offset.
  PushArgumentsArray(assembler, (kWordSize * 4));

  // Stack:
  // TOS + 0: Argument array.
  // TOS + 1: Non-closure object.
  // TOS + 2: Place for result from reporting the error.
  // TOS + 3: Saved EBP of previous frame. <== EBP
  // TOS + 4: Dart code return address
  // TOS + 5: Last argument of caller.
  // ....
  __ CallRuntime(kReportObjectNotClosureRuntimeEntry);
  __ Stop("runtime call throws an exception");
}


// Called when invoking dart code from C++ (VM code).
// Input parameters:
//   ESP : points to return address.
//   ESP + 4 : entrypoint of the dart function to call.
//   ESP + 8 : arguments descriptor array.
//   ESP + 12 : pointer to the argument array.
//   ESP + 16 : new context containing the current isolate pointer.
// Uses EAX, EDX, ECX, EDI as temporary registers.
void StubCode::GenerateInvokeDartCodeStub(Assembler* assembler) {
  const int kEntryPointOffset = 2 * kWordSize;
  const int kArgumentsDescOffset = 3 * kWordSize;
  const int kArgumentsOffset = 4 * kWordSize;
  const int kNewContextOffset = 5 * kWordSize;

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

  // Save the top exit frame info. Use EDX as a temporary register.
  __ movl(EDX, Address(EDI, Isolate::top_exit_frame_info_offset()));
  __ pushl(EDX);
  __ movl(Address(EDI, Isolate::top_exit_frame_info_offset()), Immediate(0));

  // StackFrameIterator reads the top exit frame info saved in this frame.
  // The constant kExitLinkOffsetInEntryFrame must be kept in sync with the
  // code above.

  // Save the old Context pointer. Use ECX as a temporary register.
  // Note that VisitObjectPointers will find this saved Context pointer during
  // GC marking, since it traverses any information between SP and
  // FP - kExitLinkOffsetInEntryFrame.
  __ movl(ECX, Address(EDI, Isolate::top_context_offset()));
  __ pushl(ECX);

  // Load arguments descriptor array into EDX.
  __ movl(EDX, Address(EBP, kArgumentsDescOffset));
  __ movl(EDX, Address(EDX, VMHandles::kOffsetOfRawPtrInHandle));

  // Load number of arguments into EBX.
  __ movl(EBX, FieldAddress(EDX, Array::data_offset()));
  __ SmiUntag(EBX);

  // Set up arguments for the dart call.
  Label push_arguments;
  Label done_push_arguments;
  __ testl(EBX, EBX);  // check if there are arguments.
  __ j(ZERO, &done_push_arguments, Assembler::kNearJump);
  __ movl(EAX, Immediate(0));
  __ movl(EDI, Address(EBP, kArgumentsOffset));  // start of arguments.
  __ Bind(&push_arguments);
  __ movl(ECX, Address(EDI, EAX, TIMES_4, 0));
  __ movl(ECX, Address(ECX, VMHandles::kOffsetOfRawPtrInHandle));
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
  // arguments, which is the first element of the array, a Smi.
  __ movl(EDX, Address(EBP, kArgumentsDescOffset));
  __ movl(EDX, Address(EDX, VMHandles::kOffsetOfRawPtrInHandle));
  __ movl(EDX, FieldAddress(EDX, Array::data_offset()));
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
  const Immediate raw_null =
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

    // Initialize the class field in the context object.
    // EAX: new object.
    // EDX: number of context variables.
    __ LoadObject(EBX, context_class);  // Load up class field of context.
    __ StoreIntoObject(EAX,
                       FieldAddress(EAX, Context::class_offset()),
                       EBX);
    // Calculate the size tag.
    // EAX: new object.
    // EDX: number of context variables.
    {
      Label size_tag_overflow, done;
      __ leal(EBX, Address(EDX, TIMES_4, fixed_size));
      __ andl(EBX, Immediate(-kObjectAlignment));
      __ cmpl(EBX, Immediate(RawObject::SizeTag::kMaxSizeTag));
      __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
      __ shll(EBX, Immediate(RawObject::kSizeTagBit - kObjectAlignmentLog2));
      __ jmp(&done);

      __ Bind(&size_tag_overflow);
      // Set overflow size tag value.
      __ movl(EBX, Immediate(0));

      __ Bind(&done);
      // EAX: new object.
      // EDX: number of context variables.
      // EBX: size and bit tags.
      __ orl(EBX,
             Immediate(RawObject::ClassTag::encode(context_class.index())));
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

    const Immediate raw_null =
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
  // Create a stub frame.
  __ EnterFrame(0);
  __ pushl(raw_null);  // Setup space on stack for return value.
  __ SmiTag(EDX);
  __ pushl(EDX);
  __ CallRuntime(kAllocateContextRuntimeEntry);  // Allocate context.
  __ popl(EAX);  // Pop number of context variables argument.
  __ popl(EAX);  // Pop the new context object.
  // EAX: new object
  // Restore the frame pointer.
  __ LeaveFrame();
  __ ret();
}


// Called for inline allocation of objects.
// Input parameters:
//   ESP + 8 : type arguments object (only if class is parameterized).
//   ESP + 4 : type arguments of instantiator (only if class is parameterized).
//   ESP : points to return address.
// Uses EAX, EBX, ECX, EDX, EDI as temporary registers.
void StubCode::GenerateAllocationStubForClass(Assembler* assembler,
                                              const Class& cls) {
  const intptr_t kObjectTypeArgumentsOffset = 2 * kWordSize;
  const intptr_t kInstantiatorTypeArgumentsOffset = 1 * kWordSize;
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  // The generated code is different if the class is parameterized.
  const bool is_cls_parameterized =
      cls.type_arguments_instance_field_offset() != Class::kNoTypeArguments;
  // kInlineInstanceSize is a constant used as a threshold for determining
  // when the object initialization should be done as a loop or as
  // straight line code.
  const int kInlineInstanceSize = 12;
  const intptr_t instance_size = cls.instance_size();
  ASSERT(instance_size > 0);
  const intptr_t type_args_size = InstantiatedTypeArguments::InstanceSize();
  if (FLAG_inline_alloc &&
      PageSpace::IsPageAllocatableSize(instance_size + type_args_size)) {
    Label slow_case;
    Heap* heap = Isolate::Current()->heap();
    __ movl(EAX, Address::Absolute(heap->TopAddress()));
    __ leal(EBX, Address(EAX, instance_size));
    if (is_cls_parameterized) {
      __ movl(ECX, EBX);
      // A new InstantiatedTypeArguments object only needs to be allocated if
      // the instantiator is provided (not kNoInstantiator, but may be null).
      Label no_instantiator;
      __ cmpl(Address(ESP, kInstantiatorTypeArgumentsOffset),
              Immediate(Smi::RawValue(StubCode::kNoInstantiator)));
      __ j(EQUAL, &no_instantiator, Assembler::kNearJump);
      __ addl(EBX, Immediate(type_args_size));
      __ Bind(&no_instantiator);
      // ECX: potential new object end and, if ECX != EBX, potential new
      // InstantiatedTypeArguments object start.
    }
    // Check if the allocation fits into the remaining space.
    // EAX: potential new object start.
    // EBX: potential next object start.
    __ cmpl(EBX, Address::Absolute(heap->EndAddress()));
    if (FLAG_use_slow_path) {
      __ jmp(&slow_case);
    } else {
      __ j(ABOVE_EQUAL, &slow_case, Assembler::kNearJump);
    }

    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    __ movl(Address::Absolute(heap->TopAddress()), EBX);

    if (is_cls_parameterized) {
      // Initialize the type arguments field in the object.
      // EAX: new object start.
      // ECX: potential new object end and, if ECX != EBX, potential new
      // InstantiatedTypeArguments object start.
      // EBX: next object start.
      Label type_arguments_ready;
      __ movl(EDI, Address(ESP, kObjectTypeArgumentsOffset));
      __ cmpl(ECX, EBX);
      __ j(EQUAL, &type_arguments_ready, Assembler::kNearJump);
      // Initialize InstantiatedTypeArguments object at ECX.
      __ movl(Address(ECX,
          InstantiatedTypeArguments::uninstantiated_type_arguments_offset()),
              EDI);
      __ movl(EDX, Address(ESP, kInstantiatorTypeArgumentsOffset));
      __ movl(Address(ECX,
          InstantiatedTypeArguments::instantiator_type_arguments_offset()),
              EDX);
      const Class& ita_cls =
          Class::ZoneHandle(Object::instantiated_type_arguments_class());
      __ LoadObject(EDX, ita_cls);
      __ movl(Address(ECX, Instance::class_offset()), EDX);  // Set its class.
      // Set the tags.
      uword tags = 0;
      tags = RawObject::SizeTag::update(type_args_size, tags);
      tags = RawObject::ClassTag::update(ita_cls.index(), tags);
      __ movl(Address(ECX, Instance::tags_offset()), Immediate(tags));
      // Set the new InstantiatedTypeArguments object (ECX) as the type
      // arguments (EDI) of the new object (EAX).
      __ movl(EDI, ECX);
      __ addl(EDI, Immediate(kHeapObjectTag));
      // Set EBX to new object end.
      __ movl(EBX, ECX);
      __ Bind(&type_arguments_ready);
      // EAX: new object.
      // EDI: new object type arguments.
    }

    // Initialize the class field in the object.
    // EAX: new object start.
    // EBX: next object start.
    // EDI: new object type arguments (if is_cls_parameterized).
    __ LoadObject(EDX, cls);  // Load class of object to be allocated.
    __ movl(Address(EAX, Instance::class_offset()), EDX);
    // Set the tags.
    uword tags = 0;
    tags = RawObject::SizeTag::update(instance_size, tags);
    ASSERT(cls.index() != kIllegalObjectKind);
    tags = RawObject::ClassTag::update(cls.index(), tags);
    __ movl(Address(EAX, Instance::tags_offset()), Immediate(tags));

    // Initialize the remaining words of the object.
    const Immediate raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));

    // EAX: new object start.
    // EBX: next object start.
    // EDX: class of the object to be allocated.
    // First try inlining the initialization without a loop.
    if (instance_size < (kInlineInstanceSize * kWordSize) &&
        cls.num_native_fields() == 0) {
      // Check if the object contains any non-header fields.
      // Small objects are initialized using a consecutive set of writes.
      for (intptr_t current_offset = sizeof(RawObject);
           current_offset < instance_size;
           current_offset += kWordSize) {
        __ movl(Address(EAX, current_offset), raw_null);
      }
    } else {
      __ leal(ECX, Address(EAX, sizeof(RawObject)));
      // Loop until the whole object is initialized.
      Label init_loop;
      if (cls.num_native_fields() > 0) {
        // Initialize native fields.
        // EAX: new object.
        // EBX: next object start.
        // EDX: class of the object to be allocated.
        // ECX: next word to be initialized.
        intptr_t offset = Class::num_native_fields_offset() - kHeapObjectTag;
        __ movl(EDX, Address(EDX, offset));
        __ leal(EDX, Address(EAX, EDX, TIMES_4, sizeof(RawObject)));

        // EDX: start of dart fields.
        // ECX: next word to be initialized.
        Label init_native_loop;
        __ Bind(&init_native_loop);
        __ cmpl(ECX, EDX);
        __ j(ABOVE_EQUAL, &init_loop, Assembler::kNearJump);
        __ movl(Address(ECX, 0), Immediate(0));
        __ addl(ECX, Immediate(kWordSize));
        __ jmp(&init_native_loop, Assembler::kNearJump);
      }
      // Now initialize the dart fields.
      // EAX: new object.
      // EBX: next object start.
      // ECX: next word to be initialized.
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
      // EDI: new object type arguments.
      // Set the type arguments in the new object.
      __ movl(Address(EAX, cls.type_arguments_instance_field_offset()), EDI);
    }
    // Done allocating and initializing the instance.
    // EAX: new object.
    __ addl(EAX, Immediate(kHeapObjectTag));
    __ ret();

    __ Bind(&slow_case);
  }
  if (is_cls_parameterized) {
    __ movl(EAX, Address(ESP, kObjectTypeArgumentsOffset));
    __ movl(EDX, Address(ESP, kInstantiatorTypeArgumentsOffset));
  }
  // Create a stub frame.
  __ EnterFrame(0);
  __ pushl(raw_null);  // Setup space on stack for return value.
  __ PushObject(cls);  // Push class of object to be allocated.
  if (is_cls_parameterized) {
    __ pushl(EAX);  // Push type arguments of object to be allocated.
    __ pushl(EDX);  // Push type arguments of instantiator.
  } else {
    __ pushl(raw_null);  // Push null type arguments.
    __ pushl(Immediate(Smi::RawValue(StubCode::kNoInstantiator)));
  }
  __ CallRuntime(kAllocateObjectRuntimeEntry);  // Allocate object.
  __ popl(EAX);  // Pop argument (instantiator).
  __ popl(EAX);  // Pop argument (type arguments of object).
  __ popl(EAX);  // Pop argument (class of object).
  __ popl(EAX);  // Pop result (newly allocated object).
  // EAX: new object
  // Restore the frame pointer.
  __ LeaveFrame();
  __ ret();
}


// Called for inline allocation of closures.
// Input parameters:
//   If the signature class is not parameterized, the receiver, if any, will be
//   at ESP + 4 instead of ESP + 8, since no type arguments are passed.
//   ESP + 8 (or ESP + 4): receiver (only if implicit instance closure).
//   ESP + 4 : type arguments object (only if signature class is parameterized).
//   ESP : points to return address.
// Uses EAX, EBX, ECX, EDX as temporary registers.
void StubCode::GenerateAllocationStubForClosure(Assembler* assembler,
                                                const Function& func) {
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  ASSERT(func.IsClosureFunction());
  const bool is_implicit_static_closure =
      func.IsImplicitStaticClosureFunction();
  const bool is_implicit_instance_closure =
      func.IsImplicitInstanceClosureFunction();
  const Class& cls = Class::ZoneHandle(func.signature_class());
  const bool has_type_arguments = cls.HasTypeArguments();
  const intptr_t kTypeArgumentsOffset = 1 * kWordSize;
  const intptr_t kReceiverOffset = (has_type_arguments ? 2 : 1) * kWordSize;
  const intptr_t closure_size = Closure::InstanceSize();
  const intptr_t context_size = Context::InstanceSize(1);  // Captured receiver.
  if (FLAG_inline_alloc &&
      PageSpace::IsPageAllocatableSize(closure_size + context_size)) {
    Label slow_case;
    Heap* heap = Isolate::Current()->heap();
    __ movl(EAX, Address::Absolute(heap->TopAddress()));
    __ leal(EBX, Address(EAX, closure_size));
    if (is_implicit_instance_closure) {
      __ movl(ECX, EBX);  // ECX: new context address.
      __ addl(EBX, Immediate(context_size));
    }
    // Check if the allocation fits into the remaining space.
    // EAX: potential new closure object.
    // ECX: potential new context object (only if is_implicit_closure).
    // EBX: potential next object start.
    __ cmpl(EBX, Address::Absolute(heap->EndAddress()));
    if (FLAG_use_slow_path) {
      __ jmp(&slow_case);
    } else {
      __ j(ABOVE_EQUAL, &slow_case, Assembler::kNearJump);
    }

    // Successfully allocated the object, now update top to point to
    // next object start and initialize the object.
    __ movl(Address::Absolute(heap->TopAddress()), EBX);

    // Initialize the class field in the object.
    // EAX: new closure object.
    // ECX: new context object (only if is_implicit_closure).
    __ LoadObject(EDX, cls);  // Load signature class of closure.
    __ movl(Address(EAX, Closure::class_offset()), EDX);
    // Set the tags.
    uword tags = 0;
    tags = RawObject::SizeTag::update(closure_size, tags);
    tags = RawObject::ClassTag::update(cls.index(), tags);
    __ movl(Address(EAX, Closure::tags_offset()), Immediate(tags));

    // Initialize the function field in the object.
    // EAX: new closure object.
    // ECX: new context object (only if is_implicit_closure).
    // EBX: next object start.
    __ LoadObject(EDX, func);  // Load function of closure to be allocated.
    __ movl(Address(EAX, Closure::function_offset()), EDX);

    // Setup the context for this closure.
    if (is_implicit_static_closure) {
      ObjectStore* object_store = Isolate::Current()->object_store();
      ASSERT(object_store != NULL);
      const Context& empty_context =
          Context::ZoneHandle(object_store->empty_context());
      __ LoadObject(EDX, empty_context);
      __ movl(Address(EAX, Closure::context_offset()), EDX);
    } else if (is_implicit_instance_closure) {
      // Initialize the new context capturing the receiver.

      // Set the class field to the Context class.
      const Class& context_class = Class::ZoneHandle(Object::context_class());
      __ LoadObject(EBX, context_class);
      __ movl(Address(ECX, Context::class_offset()), EBX);
      // Set the tags.
      uword tags = 0;
      tags = RawObject::SizeTag::update(context_size, tags);
      tags = RawObject::ClassTag::update(context_class.index(), tags);
      __ movl(Address(ECX, Context::tags_offset()), Immediate(tags));

      // Set number of variables field to 1 (for captured receiver).
      __ movl(Address(ECX, Context::num_variables_offset()), Immediate(1));

      // Set isolate field to isolate of current context.
      __ movl(EDX, FieldAddress(CTX, Context::isolate_offset()));
      __ movl(Address(ECX, Context::isolate_offset()), EDX);

      // Set the parent field to null.
      __ movl(Address(ECX, Context::parent_offset()), raw_null);

      // Initialize the context variable to the receiver.
      __ movl(EDX, Address(ESP, kReceiverOffset));
      __ movl(Address(ECX, Context::variable_offset(0)), EDX);

      // Set the newly allocated context in the newly allocated closure.
      __ addl(ECX, Immediate(kHeapObjectTag));
      __ movl(Address(EAX, Closure::context_offset()), ECX);
    } else {
      __ movl(Address(EAX, Closure::context_offset()), CTX);
    }

    // Set the type arguments field in the newly allocated closure.
    if (has_type_arguments) {
      ASSERT(!is_implicit_static_closure);
      // Use the passed-in type arguments.
      __ movl(EDX, Address(ESP, kTypeArgumentsOffset));
      __ movl(Address(EAX, Closure::type_arguments_offset()), EDX);
    } else {
      // Set to null.
      __ movl(Address(EAX, Closure::type_arguments_offset()), raw_null);
    }

    __ movl(Address(EAX, Closure::smrck_offset()), raw_null);

    // Done allocating and initializing the instance.
    // EAX: new object.
    __ addl(EAX, Immediate(kHeapObjectTag));
    __ ret();

    __ Bind(&slow_case);
  }
  if (has_type_arguments) {
    __ movl(ECX, Address(ESP, kTypeArgumentsOffset));
  }
  if (is_implicit_instance_closure) {
    __ movl(EAX, Address(ESP, kReceiverOffset));
  }
  // Create a stub frame.
  __ EnterFrame(0);
  __ pushl(raw_null);  // Setup space on stack for return value.
  __ PushObject(func);
  if (is_implicit_static_closure) {
    __ CallRuntime(kAllocateImplicitStaticClosureRuntimeEntry);
  } else {
    if (is_implicit_instance_closure) {
      __ pushl(EAX);  // Receiver.
    }
    if (has_type_arguments) {
      __ pushl(ECX);  // Push type arguments of closure to be allocated.
    } else {
      __ pushl(raw_null);  // Push null type arguments.
    }
    if (is_implicit_instance_closure) {
      __ CallRuntime(kAllocateImplicitInstanceClosureRuntimeEntry);
      __ popl(EAX);  // Pop argument (type arguments of object).
      __ popl(EAX);  // Pop receiver.
    } else {
      ASSERT(func.IsNonImplicitClosureFunction());
      __ CallRuntime(kAllocateClosureRuntimeEntry);
      __ popl(EAX);  // Pop argument (type arguments of object).
    }
  }
  __ popl(EAX);  // Pop function object.
  __ popl(EAX);
  // EAX: new object
  // Restore the frame pointer.
  __ LeaveFrame();
  __ ret();
}


// Called for invoking noSuchMethod function from the entry code of a dart
// function after an error in passed named arguments is detected.
// Input parameters:
//   EBP : points to previous frame pointer.
//   EBP + 4 : points to return address.
//   EBP + 8 : address of last argument (arg n-1).
//   EBP + 8 + 4*(n-1) : address of first argument (arg 0).
//   ECX : ic-data.
//   EDX : arguments descriptor array.
// Uses EAX, EBX, EDI as temporary registers.
void StubCode::GenerateCallNoSuchMethodFunctionStub(Assembler* assembler) {
  // The target function was not found, so invoke method
  // "void noSuchMethod(function_name, Array arguments)".
  // TODO(regis): For now, we simply pass the actual arguments, both positional
  // and named, as the argument array. This is not correct if out-of-order
  // named arguments were passed.
  // The signature of the "noSuchMethod" method has to change from
  // noSuchMethod(String name, Array arguments) to something like
  // noSuchMethod(InvocationMirror call).
  // Also, the class NoSuchMethodException has to be modified accordingly.
  // Total number of args is the first Smi in args descriptor array (EDX).
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movl(EDI, FieldAddress(EDX, Array::data_offset()));
  __ SmiUntag(EDI);
  __ movl(EAX, Address(EBP, EDI, TIMES_4, kWordSize));  // Get receiver.

  __ EnterFrame(0);
  __ pushl(raw_null);  // Setup space on stack for result from noSuchMethod.
  __ pushl(EAX);  // Receiver.
  __ pushl(ECX);  // IC data array.
  __ pushl(EDX);  // Arguments descriptor array.
  __ subl(EDI, Immediate(1));  // Arguments array length, minus the receiver.
  // See stack layout below explaining "wordSize * 8" offset.
  PushArgumentsArray(assembler, (kWordSize * 8));

  // Stack:
  // TOS + 0: Argument array.
  // TOS + 1: Arguments descriptor array.
  // TOS + 2: Ic-data.
  // TOS + 3: Receiver.
  // TOS + 4: Place for result from noSuchMethod.
  // TOS + 5: Saved EBP of previous frame. <== EBP
  // TOS + 6: Dart callee (or stub) code return address
  // TOS + 7: Saved EBP of dart caller frame.
  // TOS + 8: Dart caller code return address
  // TOS + 9: Last argument of caller.
  // ....
  __ CallRuntime(kInvokeNoSuchMethodFunctionRuntimeEntry);
  // Remove arguments.
  __ popl(EAX);
  __ popl(EAX);
  __ popl(EAX);
  __ popl(EAX);
  __ popl(EAX);  // Get result into EAX.

  // Remove the stub frame as we are about to return.
  __ LeaveFrame();
  __ ret();
}



// Generate inline cache check for 'num_args'.
//  ECX: Inline cache data object.
//  EDX: Arguments descriptor array.
//  TOS(0): return address
// Control flow:
// - If receiver is null -> jump to IC miss.
// - If receiver is Smi -> load Smi class.
// - If receiver is not-Smi -> load receiver's class.
// - Check if 'num_args' (including receiver) match any IC data group.
// - Match found -> jump to target.
// - Match not found -> jump to IC miss.
void StubCode::GenerateNArgsCheckInlineCacheStub(Assembler* assembler,
                                                 intptr_t num_args) {
  __ movl(EBX, FieldAddress(ECX, ICData::function_offset()));
  __ incl(FieldAddress(EBX, Function::usage_counter_offset()));
  if (CodeGenerator::CanOptimize()) {
    __ cmpl(FieldAddress(EBX, Function::usage_counter_offset()),
        Immediate(FLAG_optimization_counter_threshold));
    Label not_yet_hot;
    __ j(LESS_EQUAL, &not_yet_hot);
    __ EnterFrame(0);
    __ pushl(ECX);  // Preserve inline cache data object.
    __ pushl(EDX);  // Preserve arguments array.
    __ pushl(EBX);  // Argument for runtime: function object.
    __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry);
    __ popl(EBX);  // Remove argument.
    __ popl(EDX);  // Restore arguments array.
    __ popl(ECX);  // Restore inline cache data object.
    __ LeaveFrame();
    __ Bind(&not_yet_hot);
  }

  ASSERT(num_args > 0);
  // Get receiver (first read number of arguments from argument descriptor array
  // and then access the receiver from the stack).
  __ movl(EAX, FieldAddress(EDX, Array::data_offset()));
  __ movl(EAX, Address(ESP, EAX, TIMES_2, 0));  // EAX (argument_count) is Smi.

  Label get_class, ic_miss;
  __ call(&get_class);
  // EAX: receiver's class
  // ECX: IC data array.

#if defined(DEBUG)
  { Label ok;
    // Check that the IC data array has NumberOfArgumentsChecked() == num_args.
    // 'num_args_tested' is stored as an untagged int.
    __ movl(EBX, FieldAddress(ECX, ICData::num_args_tested_offset()));
    __ cmpl(EBX, Immediate(num_args));
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Incorrect stub for IC data");
    __ Bind(&ok);
  }
#endif  // DEBUG

  // Loop that checks if there is an IC data match.
  // EAX: receiver's class.
  // ECX: IC data object (preserved).
  __ movl(EBX, FieldAddress(ECX, ICData::ic_data_offset()));
  // EBX: ic_data_array with check entries: classes and target functions.
  __ leal(EBX, FieldAddress(EBX, Array::data_offset()));
  // EBX: points directly to the first ic data array element.
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label loop, found;
  if (num_args == 1) {
    __ Bind(&loop);
    __ movl(EDI, Address(EBX, 0));  // Get class to check.
    __ cmpl(EAX, EDI);  // Match?
    __ j(EQUAL, &found, Assembler::kNearJump);
    __ addl(EBX, Immediate(kWordSize * 2));  // Next element (class + target).
    __ cmpl(EDI, raw_null);   // Done?
    __ j(NOT_EQUAL, &loop, Assembler::kNearJump);
  } else if (num_args == 2) {
    // EDI: class to check.
    Label no_match;
    __ Bind(&loop);
    // Get class from IC data to check.
    __ movl(EDI, Address(EBX, 0));
    // Get receiver using argument descriptor in EDX.
    __ movl(EAX, FieldAddress(EDX, Array::data_offset()));
    __ movl(EAX, Address(ESP, EAX, TIMES_2, 0));  // EAX (arg. count) is Smi.
    __ call(&get_class);
    __ cmpl(EAX, EDI);  // Match?
    __ j(NOT_EQUAL, &no_match, Assembler::kNearJump);
    // Check second class/argument.
    // Get class from IC data to check.
    __ movl(EDI, Address(EBX, kWordSize));
    // Get next argument.
    __ movl(EAX, FieldAddress(EDX, Array::data_offset()));
    __ movl(EAX, Address(ESP, EAX, TIMES_2, -kWordSize));
    // EAX (argument count) is Smi.
    __ call(&get_class);
    __ cmpl(EAX, EDI);  // Match?
    __ j(EQUAL, &found, Assembler::kNearJump);
    __ Bind(&no_match);
    // Each test entry has (1 + num_args) array elements.
    __ addl(EBX, Immediate(kWordSize * (1 + num_args)));  // Next element.
    __ cmpl(EDI, raw_null);   // Done?
    __ j(NOT_EQUAL, &loop, Assembler::kNearJump);
  }

  __ Bind(&ic_miss);
  // Compute address of arguments (first read number of arguments from argument
  // descriptor array and then compute address on the stack).
  __ movl(EAX, FieldAddress(EDX, Array::data_offset()));
  __ leal(EAX, Address(ESP, EAX, TIMES_2, 0));  // EAX is Smi.
  __ EnterFrame(0);
  __ pushl(EDX);  // Preserve arguments array.
  __ pushl(ECX);  // Preserve IC data array
  __ pushl(raw_null);  // Setup space on stack for result (target code object).
  // Push call arguments.
  for (intptr_t i = 0; i < num_args; i++) {
    __ movl(EDX, Address(EAX, -kWordSize * i));
    __ pushl(EDX);
  }
  if (num_args == 1) {
    __ CallRuntime(kInlineCacheMissHandlerOneArgRuntimeEntry);
  } else if (num_args == 2) {
    __ CallRuntime(kInlineCacheMissHandlerTwoArgsRuntimeEntry);
  } else {
    UNIMPLEMENTED();
  }
  // Remove call arguments pushed earlier.
  for (intptr_t i = 0; i < num_args; i++) {
    __ popl(EAX);
  }
  __ popl(EAX);  // Pop returned code object into EAX (null if not found).
  __ popl(ECX);  // Restore IC data array.
  __ popl(EDX);  // Restore arguments array.
  __ LeaveFrame();
  Label call_target_function;
  __ cmpl(EAX, raw_null);
  __ j(NOT_EQUAL, &call_target_function, Assembler::kNearJump);
  // NoSuchMethod or closure.
  __ jmp(&StubCode::MegamorphicLookupLabel());

  __ Bind(&found);
  // EBX: Pointer to an IC data check group (classes + target)
  __ movl(EAX, Address(EBX, kWordSize * num_args));  // Target function.

  __ Bind(&call_target_function);
  // EAX: Target function.
  __ movl(EAX, FieldAddress(EAX, Function::code_offset()));
  __ movl(EAX, FieldAddress(EAX, Code::instructions_offset()));
  __ addl(EAX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ jmp(EAX);

  __ Bind(&get_class);
  Label not_smi;
  // Test if Smi -> load Smi class for comparison.
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &not_smi, Assembler::kNearJump);
  const Class& smi_class =
      Class::ZoneHandle(Isolate::Current()->object_store()->smi_class());
  __ LoadObject(EAX, smi_class);
  __ ret();

  __ Bind(&not_smi);
  __ movl(EAX, FieldAddress(EAX, Object::class_offset()));
  __ ret();
}


// Use inline cache data array to invoke the target or continue in inline
// cache miss handler. Stub for 1-argument check (receiver class).
//  ECX: Inline cache data array
//  EDX: Arguments array
//  TOS(0): return address
// Inline cache data array structure:
// 0: function-name
// 1: N, number of arguments checked.
// 2 .. (length - 1): group of checks, each check containing:
//   - N classes.
//   - 1 target function.
void StubCode::GenerateOneArgCheckInlineCacheStub(Assembler* assembler) {
  return GenerateNArgsCheckInlineCacheStub(assembler, 1);
}


void StubCode::GenerateTwoArgsCheckInlineCacheStub(Assembler* assembler) {
  return GenerateNArgsCheckInlineCacheStub(assembler, 2);
}

//  ECX: Function object.
//  EDX: Arguments array.
//  TOS(0): return address (Dart code).
void StubCode::GenerateBreakpointStaticStub(Assembler* assembler) {
  __ EnterFrame(0);
  __ pushl(EDX);
  __ pushl(ECX);
  __ CallRuntime(kBreakpointStaticHandlerRuntimeEntry);
  __ popl(ECX);
  __ popl(EDX);
  __ LeaveFrame();

  // Now call the static function. The breakpoint handler function
  // ensures that the call target is compiled.
  __ movl(EAX, FieldAddress(ECX, Function::code_offset()));
  __ movl(ECX, FieldAddress(EAX, Code::instructions_offset()));
  __ addl(ECX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ jmp(ECX);
}


//  TOS(0): return address (Dart code).
void StubCode::GenerateBreakpointReturnStub(Assembler* assembler) {
  __ EnterFrame(0);
  __ pushl(EAX);
  __ CallRuntime(kBreakpointReturnHandlerRuntimeEntry);
  __ popl(EAX);
  __ LeaveFrame();

  // Instead of returning to the patched Dart function, emulate the
  // smashed return code pattern and return to the function's caller.
  __ popl(ECX);  // Discard return address to patched dart code.
  // Execute function epilog code that was smashed in the Dart code.
  __ LeaveFrame();
  __ ret();
}


//  ECX: Inline cache data array.
//  EDX: Arguments array.
//  TOS(0): return address (Dart code).
void StubCode::GenerateBreakpointDynamicStub(Assembler* assembler) {
  __ EnterFrame(0);
  __ pushl(ECX);
  __ pushl(EDX);
  __ CallRuntime(kBreakpointDynamicHandlerRuntimeEntry);
  __ popl(EDX);
  __ popl(ECX);
  __ LeaveFrame();

  // Find out which dispatch stub to call.
  Label ic_cache_one_arg;
  __ movl(EBX, FieldAddress(ECX, ICData::num_args_tested_offset()));
  __ cmpl(EBX, Immediate(1));
  __ j(EQUAL, &ic_cache_one_arg, Assembler::kNearJump);
  __ jmp(&StubCode::TwoArgsCheckInlineCacheLabel());
  __ Bind(&ic_cache_one_arg);
  __ jmp(&StubCode::OneArgCheckInlineCacheLabel());
}


// Check if an instance class is a subtype of class/interface using simple
// superchain and interface array traversal. Does not take type parameters into
// account.
// Cannot handle Smi instances (must be tested beforehand).
// EAX: instance (to be preserved).
// ECX: class to test.
// EDX: class/interface to test against (is class of instance a subtype of it).
//      (preserved).
// Result in EBX: 1 is subtype, 0 maybe not.
// Destroys EBX, EDI, ECX.
void StubCode::GenerateIsRawSubTypeStub(Assembler* assembler) {
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label test_class, not_found, found;

  __ movzxb(EBX, FieldAddress(EDX, Class::is_interface_offset()));
  // Check if we are comparing against class or interface.
  __ cmpl(EBX, Immediate(0));
  __ j(EQUAL, &test_class, Assembler::kNearJump);

  // Get interfaces array from instance class.
  __ movl(EBX, FieldAddress(ECX, Class::interfaces_offset()));
  __ cmpl(EBX, raw_null);
  __ j(EQUAL, &not_found, Assembler::kNearJump);
  __ movl(EDI, FieldAddress(EBX, Array::length_offset()));
  // EDI: array index.
  // EBX: interface array.
  // EDX: interface searched
  Label array_loop;
  __ Bind(&array_loop);
  __ subl(EDI, Immediate(Smi::RawValue(1)));
  __ j(LESS, &not_found, Assembler::kNearJump);
  // EDI is Smi therefore TIMES_2 instead of TIMES_4.
  // Get type from array.
  __ movl(ECX, FieldAddress(EBX, EDI, TIMES_2, Array::data_offset()));
  __ movl(ECX, FieldAddress(ECX, Type::type_class_offset()));
  __ cmpl(ECX, EDX);
  __ j(EQUAL, &found, Assembler::kNearJump);
  __ jmp(&array_loop, Assembler::kNearJump);

  __ Bind(&not_found);
  __ xorl(EBX, EBX);
  __ ret();

  __ Bind(&found);
  __ movl(EBX, Immediate(1));
  __ ret();

  __ Bind(&test_class);
  // EDX: test class.
  __ cmpl(ECX, EDX);
  __ j(EQUAL, &found, Assembler::kNearJump);

  // Check superclasses using a loop (faster than runtime call).
  Label super_loop;
  __ Bind(&super_loop);
  // ECX: class -> super.
  __ movl(ECX, FieldAddress(ECX, Class::super_type_offset()));
  // The supertype of Object is a null object.
  __ cmpl(ECX, raw_null);
  __ j(EQUAL, &not_found, Assembler::kNearJump);
  __ movl(ECX, FieldAddress(ECX, Type::type_class_offset()));
  __ cmpl(EDX, ECX);
  __ j(NOT_EQUAL, &super_loop, Assembler::kNearJump);
  __ jmp(&found, Assembler::kNearJump);
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
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label not_found;
  __ movl(EAX, Address(ESP, kInstanceOffsetInBytes));
  __ movl(ECX, FieldAddress(EAX, Object::class_offset()));
  // EAX: instance, ECX: instance-class.
  // Get instance type arguments
  if (n > 1) {
    // Compute instance type arguments into EBX.
    Label has_no_type_arguments;
    __ movl(EBX, raw_null);
    __ movl(EDI, FieldAddress(ECX,
        Class::type_arguments_instance_field_offset_offset()));
    __ cmpl(EDI, Immediate(Class::kNoTypeArguments));
    __ j(EQUAL, &has_no_type_arguments, Assembler::kNearJump);
    __ movl(EBX, FieldAddress(EAX, EDI, TIMES_1, 0));
    __ Bind(&has_no_type_arguments);
  }
  // EBX: instance type arguments (null if none).
  __ movl(EDX, Address(ESP, kCacheOffsetInBytes));
  // EDX: SubtypeTestCache.
  __ movl(EDX, FieldAddress(EDX, SubtypeTestCache::cache_offset()));
  __ addl(EDX, Immediate(Array::data_offset() - kHeapObjectTag));

  Label loop, found, next_iteration;
  // EDX: Entry start.
  // ECX: instance class.
  // EBX: instance type arguments
  __ Bind(&loop);
  __ movl(EDI, Address(EDX, kWordSize * SubtypeTestCache::kInstanceClass));
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

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
